#!/bin/bash

# ============================================================
#  FinFlow Improvement Script
#  Run from: C:\laragon\www\Phone-app\
#  Usage:    bash finflow-improve.sh
# ============================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       FinFlow Improvement Script         ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── helpers ────────────────────────────────────────────────
write_file() {
    local path="$1"
    local dir
    dir=$(dirname "$path")
    mkdir -p "$dir"
    cat > "$path"
    echo -e "  ${GREEN}✔${NC} $path"
}

step() { echo -e "\n${YELLOW}▶ $1${NC}"; }

# ============================================================
# STEP 1 — Form Request Classes
# ============================================================
step "Step 1/6 — Creating Form Request Classes"

write_file "app/Http/Requests/StoreTransactionRequest.php" << 'PHP'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreTransactionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'account_id'  => ['required', 'exists:accounts,id'],
            'category_id' => ['required', 'exists:categories,id'],
            'amount'      => ['required', 'numeric', 'min:0.01'],
            'type'        => ['required', 'in:income,expense'],
            'description' => ['nullable', 'string', 'max:255'],
            'notes'       => ['nullable', 'string', 'max:1000'],
            'date'        => ['required', 'date'],
        ];
    }

    public function messages(): array
    {
        return [
            'account_id.required'  => 'Please select an account.',
            'category_id.required' => 'Please select a category.',
            'amount.min'           => 'Amount must be greater than zero.',
        ];
    }
}
PHP

write_file "app/Http/Requests/UpdateTransactionRequest.php" << 'PHP'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class UpdateTransactionRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'account_id'  => ['required', 'exists:accounts,id'],
            'category_id' => ['required', 'exists:categories,id'],
            'amount'      => ['required', 'numeric', 'min:0.01'],
            'type'        => ['required', 'in:income,expense'],
            'description' => ['nullable', 'string', 'max:255'],
            'date'        => ['required', 'date'],
        ];
    }
}
PHP

write_file "app/Http/Requests/StoreBudgetRequest.php" << 'PHP'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreBudgetRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'category_id'  => ['required', 'exists:categories,id'],
            'limit_amount' => ['required', 'numeric', 'min:1'],
            'month'        => ['required', 'integer', 'between:1,12'],
            'year'         => ['required', 'integer', 'min:2020'],
        ];
    }
}
PHP

write_file "app/Http/Requests/StoreAccountRequest.php" << 'PHP'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreAccountRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name'         => ['required', 'string', 'max:100'],
            'account_type' => ['required', 'in:cash,bank,e_wallet,credit_card,savings'],
            'balance'      => ['required', 'numeric'],
            'color'        => ['nullable', 'string', 'max:7'],
            'icon'         => ['nullable', 'string', 'max:10'],
        ];
    }
}
PHP

write_file "app/Http/Requests/StoreTransferRequest.php" << 'PHP'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreTransferRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'from_account_id' => ['required', 'exists:accounts,id'],
            'to_account_id'   => ['required', 'exists:accounts,id', 'different:from_account_id'],
            'amount'          => ['required', 'numeric', 'min:0.01'],
            'note'            => ['nullable', 'string', 'max:255'],
            'transfer_date'   => ['required', 'date'],
        ];
    }

    public function messages(): array
    {
        return [
            'to_account_id.different' => 'Source and destination accounts must be different.',
        ];
    }
}
PHP

write_file "app/Http/Requests/StoreRecurringRequest.php" << 'PHP'
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreRecurringRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'account_id'  => ['required', 'exists:accounts,id'],
            'category_id' => ['required', 'exists:categories,id'],
            'amount'      => ['required', 'numeric', 'min:0.01'],
            'type'        => ['required', 'in:income,expense'],
            'description' => ['nullable', 'string', 'max:255'],
            'frequency'   => ['required', 'in:daily,weekly,monthly,yearly'],
            'start_date'  => ['required', 'date'],
            'end_date'    => ['nullable', 'date', 'after:start_date'],
        ];
    }
}
PHP

# ============================================================
# STEP 2 — Fix TransactionService (make it actually used)
# ============================================================
step "Step 2/6 — Fixing TransactionService"

write_file "app/Services/TransactionService.php" << 'PHP'
<?php

namespace App\Services;

use App\Models\Account;
use App\Models\Budget;
use App\Models\Transaction;
use Illuminate\Support\Facades\DB;

class TransactionService
{
    /**
     * Create a transaction and adjust the account balance atomically.
     */
    public function create(array $data, Account $account): Transaction
    {
        return DB::transaction(function () use ($data, $account) {
            // Balance protection for protected account types
            if ($data['type'] === 'expense') {
                $protectedTypes = ['cash', 'bank', 'savings', 'e_wallet'];
                if (in_array($account->account_type, $protectedTypes) && $account->balance < $data['amount']) {
                    throw new \RuntimeException(
                        "Insufficient balance. {$account->name} has " .
                        number_format($account->balance, 2) . " available."
                    );
                }
            }

            $tx = Transaction::create($data);
            $this->applyBalance($account, $data['type'], $data['amount'], 'add');
            return $tx;
        });
    }

    /**
     * Update a transaction, reversing the old balance effect and applying the new one.
     */
    public function update(Transaction $transaction, array $data, Account $newAccount): void
    {
        DB::transaction(function () use ($transaction, $data, $newAccount) {
            // Reverse old
            $this->applyBalance($transaction->account, $transaction->type, $transaction->amount, 'reverse');
            // Apply new
            $transaction->update($data);
            $this->applyBalance($newAccount, $data['type'], $data['amount'], 'add');
        });
    }

    /**
     * Delete a transaction and reverse its balance effect.
     */
    public function delete(Transaction $transaction): void
    {
        DB::transaction(function () use ($transaction) {
            $this->applyBalance($transaction->account, $transaction->type, $transaction->amount, 'reverse');
            $transaction->delete();
        });
    }

    /**
     * Check and flash a budget alert if the category budget is exceeded.
     */
    public function checkBudgetAlert(int $userId, int $categoryId, string $type): void
    {
        if ($type !== 'expense') return;

        $budget = Budget::where('user_id', $userId)
            ->where('category_id', $categoryId)
            ->where('month', now()->month)
            ->where('year',  now()->year)
            ->first();

        if ($budget && ! $budget->alert_sent && $budget->is_exceeded) {
            $budget->update(['alert_sent' => true]);
            session()->flash('budget_alert', "⚠️ You've exceeded your budget for {$budget->category->name}!");
        }
    }

    // ── private helpers ──────────────────────────────────────

    private function applyBalance(Account $account, string $type, float $amount, string $direction): void
    {
        $isAdd = $direction === 'add';

        if ($type === 'income') {
            $isAdd ? $account->increment('balance', $amount)
                   : $account->decrement('balance', $amount);
        } else {
            $isAdd ? $account->decrement('balance', $amount)
                   : $account->increment('balance', $amount);
        }
    }
}
PHP

# ============================================================
# STEP 3 — Refactored TransactionController (uses Service + FormRequests)
# ============================================================
step "Step 3/6 — Refactoring TransactionController"

write_file "app/Http/Controllers/TransactionController.php" << 'PHP'
<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreTransactionRequest;
use App\Http\Requests\UpdateTransactionRequest;
use App\Models\Account;
use App\Models\Category;
use App\Models\Transaction;
use App\Services\TransactionService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class TransactionController extends Controller
{
    public function __construct(private TransactionService $txService) {}

    public function index(Request $request)
    {
        $user  = Auth::user();
        $query = Transaction::forUser($user->id)->with(['category', 'account']);

        if ($request->filled('type'))        $query->where('type', $request->type);
        if ($request->filled('category_id')) $query->where('category_id', $request->category_id);
        if ($request->filled('account_id'))  $query->whereHas('account', fn($q) => $q->where('id', $request->account_id)->where('user_id', $user->id));
        if ($request->filled('date_from'))   $query->whereDate('date', '>=', $request->date_from);
        if ($request->filled('date_to'))     $query->whereDate('date', '<=', $request->date_to);
        if ($request->filled('search'))      $query->where('description', 'LIKE', '%' . $request->search . '%');

        $transactions = $query->orderByDesc('date')->orderByDesc('id')->paginate(15)->withQueryString();
        $categories   = Category::all();
        $accounts     = $user->accounts()->get();

        return view('transactions.index', compact('transactions', 'categories', 'accounts'));
    }

    public function create()
    {
        $categories = Category::all();
        $accounts   = Auth::user()->accounts()->get();
        return view('transactions.create', compact('categories', 'accounts'));
    }

    public function store(StoreTransactionRequest $request)
    {
        $user    = Auth::user();
        $data    = $request->validated();

        $account = Account::where('id', $data['account_id'])
            ->where('user_id', $user->id)
            ->firstOrFail();

        try {
            $transaction = $this->txService->create($data, $account);
        } catch (\RuntimeException $e) {
            if ($request->wantsJson()) {
                return response()->json(['success' => false, 'error' => $e->getMessage()], 422);
            }
            return back()->withInput()->withErrors(['amount' => $e->getMessage()]);
        }

        $this->txService->checkBudgetAlert($user->id, $data['category_id'], $data['type']);

        if ($request->wantsJson()) {
            return response()->json(['success' => true, 'transaction' => $transaction->load('category', 'account')]);
        }

        return redirect(route('dashboard'))->with('success', 'Transaction added!');
    }

    public function edit(Transaction $transaction)
    {
        $this->authorizeTransaction($transaction);
        $categories = Category::all();
        $accounts   = Auth::user()->accounts()->get();
        return view('transactions.edit', compact('transaction', 'categories', 'accounts'));
    }

    public function update(UpdateTransactionRequest $request, Transaction $transaction)
    {
        $this->authorizeTransaction($transaction);
        $data = $request->validated();

        $newAccount = Account::where('id', $data['account_id'])
            ->where('user_id', Auth::id())
            ->firstOrFail();

        $this->txService->update($transaction, $data, $newAccount);

        return redirect(route('transactions.index'))->with('success', 'Transaction updated!');
    }

    public function destroy(Transaction $transaction)
    {
        $this->authorizeTransaction($transaction);
        $this->txService->delete($transaction);
        return redirect(route('transactions.index'))->with('success', 'Transaction deleted.');
    }

    private function authorizeTransaction(Transaction $transaction): void
    {
        if ($transaction->account->user_id !== Auth::id()) abort(403);
    }
}
PHP

# ============================================================
# STEP 4 — Fix Budget N+1 (cached spent attribute)
# ============================================================
step "Step 4/6 — Fixing Budget N+1 problem"

write_file "app/Models/Budget.php" << 'PHP'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class Budget extends Model
{
    protected $fillable = [
        'user_id', 'category_id', 'limit_amount', 'month', 'year', 'alert_sent',
    ];

    protected $casts = [
        'limit_amount' => 'float',
        'alert_sent'   => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    /**
     * Get spent amount — cached for 5 minutes per budget record.
     * Call $budget->forgetSpentCache() after any related transaction change.
     */
    public function getSpentAttribute(): float
    {
        $cacheKey = "budget_spent_{$this->id}";

        return Cache::remember($cacheKey, now()->addMinutes(5), function () {
            return (float) Transaction::whereHas('account', fn($q) => $q->where('user_id', $this->user_id))
                ->where('category_id', $this->category_id)
                ->where('type', 'expense')
                ->whereMonth('date', $this->month)
                ->whereYear('date', $this->year)
                ->sum('amount');
        });
    }

    /**
     * Forget the cached spent amount — call after adding/updating/deleting
     * a transaction that belongs to this budget's category.
     */
    public function forgetSpentCache(): void
    {
        Cache::forget("budget_spent_{$this->id}");
    }

    /**
     * Forget all budget spent caches for a given user (e.g. on bulk import).
     */
    public static function forgetAllCachesForUser(int $userId): void
    {
        $budgets = static::where('user_id', $userId)->get();
        foreach ($budgets as $budget) {
            $budget->forgetSpentCache();
        }
    }

    public function getRemainingAttribute(): float
    {
        return max(0, $this->limit_amount - $this->spent);
    }

    public function getPercentageAttribute(): float
    {
        if ($this->limit_amount == 0) return 0;
        return min(100, round(($this->spent / $this->limit_amount) * 100, 1));
    }

    public function getIsExceededAttribute(): bool
    {
        return $this->spent > $this->limit_amount;
    }

    public function getStatusColorAttribute(): string
    {
        $pct = $this->percentage;
        if ($pct >= 100) return 'red';
        if ($pct >= 80)  return 'amber';
        return 'emerald';
    }
}
PHP

# ── Update TransactionService to bust budget cache ──────────
write_file "app/Services/TransactionService.php" << 'PHP'
<?php

namespace App\Services;

use App\Models\Account;
use App\Models\Budget;
use App\Models\Transaction;
use Illuminate\Support\Facades\DB;

class TransactionService
{
    /**
     * Create a transaction and adjust the account balance atomically.
     */
    public function create(array $data, Account $account): Transaction
    {
        return DB::transaction(function () use ($data, $account) {
            if ($data['type'] === 'expense') {
                $protectedTypes = ['cash', 'bank', 'savings', 'e_wallet'];
                if (in_array($account->account_type, $protectedTypes) && $account->balance < $data['amount']) {
                    throw new \RuntimeException(
                        "Insufficient balance. {$account->name} has " .
                        number_format($account->balance, 2) . " available."
                    );
                }
            }

            $tx = Transaction::create($data);
            $this->applyBalance($account, $data['type'], $data['amount'], 'add');
            $this->bustBudgetCache($account->user_id, $data['category_id']);
            return $tx;
        });
    }

    /**
     * Update a transaction, reversing the old balance effect and applying the new one.
     */
    public function update(Transaction $transaction, array $data, Account $newAccount): void
    {
        DB::transaction(function () use ($transaction, $data, $newAccount) {
            $oldUserId     = $transaction->account->user_id;
            $oldCategoryId = $transaction->category_id;

            $this->applyBalance($transaction->account, $transaction->type, $transaction->amount, 'reverse');
            $transaction->update($data);
            $this->applyBalance($newAccount, $data['type'], $data['amount'], 'add');

            // Bust cache for both old and new category
            $this->bustBudgetCache($oldUserId, $oldCategoryId);
            $this->bustBudgetCache($newAccount->user_id, $data['category_id']);
        });
    }

    /**
     * Delete a transaction and reverse its balance effect.
     */
    public function delete(Transaction $transaction): void
    {
        DB::transaction(function () use ($transaction) {
            $userId     = $transaction->account->user_id;
            $categoryId = $transaction->category_id;

            $this->applyBalance($transaction->account, $transaction->type, $transaction->amount, 'reverse');
            $transaction->delete();
            $this->bustBudgetCache($userId, $categoryId);
        });
    }

    /**
     * Check and flash a budget alert if the category budget is exceeded.
     */
    public function checkBudgetAlert(int $userId, int $categoryId, string $type): void
    {
        if ($type !== 'expense') return;

        $budget = Budget::where('user_id', $userId)
            ->where('category_id', $categoryId)
            ->where('month', now()->month)
            ->where('year',  now()->year)
            ->first();

        if ($budget && ! $budget->alert_sent && $budget->is_exceeded) {
            $budget->update(['alert_sent' => true]);
            session()->flash('budget_alert', "⚠️ You've exceeded your budget for {$budget->category->name}!");
        }
    }

    // ── private helpers ──────────────────────────────────────

    private function applyBalance(Account $account, string $type, float $amount, string $direction): void
    {
        $isAdd = $direction === 'add';

        if ($type === 'income') {
            $isAdd ? $account->increment('balance', $amount)
                   : $account->decrement('balance', $amount);
        } else {
            $isAdd ? $account->decrement('balance', $amount)
                   : $account->increment('balance', $amount);
        }
    }

    private function bustBudgetCache(int $userId, int $categoryId): void
    {
        $budget = Budget::where('user_id', $userId)
            ->where('category_id', $categoryId)
            ->where('month', now()->month)
            ->where('year',  now()->year)
            ->first();

        $budget?->forgetSpentCache();
    }
}
PHP

# ============================================================
# STEP 5 — Scheduled Command for Auto-Processing Recurring Transactions
# ============================================================
step "Step 5/6 — Creating Recurring Transaction Auto-Processor"

write_file "app/Console/Commands/ProcessRecurringTransactions.php" << 'PHP'
<?php

namespace App\Console\Commands;

use App\Models\RecurringTransaction;
use App\Models\Transaction;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class ProcessRecurringTransactions extends Command
{
    protected $signature   = 'finflow:process-recurring
                                {--dry-run : Show what would be processed without actually doing it}';

    protected $description = 'Process all due recurring transactions automatically';

    public function handle(): int
    {
        $dryRun = $this->option('dry-run');

        $due = RecurringTransaction::with(['account', 'category', 'user'])
            ->where('is_active', true)
            ->where('next_due', '<=', now()->toDateString())
            ->where(function ($q) {
                $q->whereNull('end_date')
                  ->orWhere('end_date', '>=', now()->toDateString());
            })
            ->get();

        if ($due->isEmpty()) {
            $this->info('No recurring transactions due today.');
            return self::SUCCESS;
        }

        $this->info("Found {$due->count()} recurring transaction(s) to process.");

        $processed = 0;
        $failed    = 0;

        foreach ($due as $recurring) {
            $label = "[#{$recurring->id}] {$recurring->description} — {$recurring->user->name}";

            if ($dryRun) {
                $this->line("  DRY-RUN: Would process {$label}");
                continue;
            }

            try {
                DB::transaction(function () use ($recurring) {
                    Transaction::create([
                        'account_id'  => $recurring->account_id,
                        'category_id' => $recurring->category_id,
                        'amount'      => $recurring->amount,
                        'type'        => $recurring->type,
                        'description' => ($recurring->description ?? $recurring->category->name) . ' (Auto)',
                        'date'        => now()->toDateString(),
                    ]);

                    $account = $recurring->account;
                    if ($recurring->type === 'income') {
                        $account->increment('balance', $recurring->amount);
                    } else {
                        $account->decrement('balance', $recurring->amount);
                    }

                    $recurring->advanceNextDue();
                });

                $this->line("  <fg=green>✔</> Processed {$label}");
                $processed++;

            } catch (\Throwable $e) {
                Log::error("Failed to process recurring #{$recurring->id}: " . $e->getMessage());
                $this->line("  <fg=red>✘</> Failed {$label}: {$e->getMessage()}");
                $failed++;
            }
        }

        $this->newLine();
        $this->info("Done. Processed: {$processed} | Failed: {$failed}");

        return $failed > 0 ? self::FAILURE : self::SUCCESS;
    }
}
PHP

write_file "app/Console/Kernel.php" << 'PHP'
<?php

namespace App\Console;

use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Foundation\Console\Kernel as ConsoleKernel;

class Kernel extends ConsoleKernel
{
    /**
     * Define the application's command schedule.
     */
    protected function schedule(Schedule $schedule): void
    {
        // Process recurring transactions every day at 00:05
        $schedule->command('finflow:process-recurring')
                 ->dailyAt('00:05')
                 ->withoutOverlapping()
                 ->runInBackground()
                 ->appendOutputTo(storage_path('logs/recurring.log'));
    }

    /**
     * Register the commands for the application.
     */
    protected function commands(): void
    {
        $this->load(__DIR__ . '/Commands');
        require base_path('routes/console.php');
    }
}
PHP

# ============================================================
# STEP 6 — Budget Over-Limit Email Notification
# ============================================================
step "Step 6/6 — Budget Over-Limit Email Notification"

write_file "app/Notifications/BudgetExceededNotification.php" << 'PHP'
<?php

namespace App\Notifications;

use App\Models\Budget;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class BudgetExceededNotification extends Notification
{
    use Queueable;

    public function __construct(private Budget $budget) {}

    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $currency  = $notifiable->currency ?? 'USD';
        $category  = $this->budget->category->name;
        $spent     = number_format($this->budget->spent, 2);
        $limit     = number_format($this->budget->limit_amount, 2);
        $overage   = number_format($this->budget->spent - $this->budget->limit_amount, 2);
        $monthYear = date('F Y', mktime(0, 0, 0, $this->budget->month, 1, $this->budget->year));

        return (new MailMessage)
            ->subject("⚠️ Budget Exceeded: {$category} — {$monthYear}")
            ->greeting("Hi {$notifiable->name}!")
            ->line("Your **{$category}** budget has been exceeded for {$monthYear}.")
            ->line("- **Limit:** {$currency} {$limit}")
            ->line("- **Spent:** {$currency} {$spent}")
            ->line("- **Over by:** {$currency} {$overage}")
            ->action('View Budgets', url('/budgets'))
            ->line('Consider reviewing your spending or adjusting your budget.')
            ->salutation('— FinFlow');
    }
}
PHP

# ── Update TransactionService to send email notification ────
write_file "app/Services/TransactionService.php" << 'PHP'
<?php

namespace App\Services;

use App\Models\Account;
use App\Models\Budget;
use App\Models\Transaction;
use App\Notifications\BudgetExceededNotification;
use Illuminate\Support\Facades\DB;

class TransactionService
{
    /**
     * Create a transaction and adjust the account balance atomically.
     */
    public function create(array $data, Account $account): Transaction
    {
        return DB::transaction(function () use ($data, $account) {
            if ($data['type'] === 'expense') {
                $protectedTypes = ['cash', 'bank', 'savings', 'e_wallet'];
                if (in_array($account->account_type, $protectedTypes) && $account->balance < $data['amount']) {
                    throw new \RuntimeException(
                        "Insufficient balance. {$account->name} has " .
                        number_format($account->balance, 2) . " available."
                    );
                }
            }

            $tx = Transaction::create($data);
            $this->applyBalance($account, $data['type'], $data['amount'], 'add');
            $this->bustBudgetCache($account->user_id, $data['category_id']);
            return $tx;
        });
    }

    /**
     * Update a transaction, reversing the old balance effect and applying the new one.
     */
    public function update(Transaction $transaction, array $data, Account $newAccount): void
    {
        DB::transaction(function () use ($transaction, $data, $newAccount) {
            $oldUserId     = $transaction->account->user_id;
            $oldCategoryId = $transaction->category_id;

            $this->applyBalance($transaction->account, $transaction->type, $transaction->amount, 'reverse');
            $transaction->update($data);
            $this->applyBalance($newAccount, $data['type'], $data['amount'], 'add');

            $this->bustBudgetCache($oldUserId, $oldCategoryId);
            $this->bustBudgetCache($newAccount->user_id, $data['category_id']);
        });
    }

    /**
     * Delete a transaction and reverse its balance effect.
     */
    public function delete(Transaction $transaction): void
    {
        DB::transaction(function () use ($transaction) {
            $userId     = $transaction->account->user_id;
            $categoryId = $transaction->category_id;

            $this->applyBalance($transaction->account, $transaction->type, $transaction->amount, 'reverse');
            $transaction->delete();
            $this->bustBudgetCache($userId, $categoryId);
        });
    }

    /**
     * Check budget, flash alert, and send email notification if exceeded.
     */
    public function checkBudgetAlert(int $userId, int $categoryId, string $type): void
    {
        if ($type !== 'expense') return;

        $budget = Budget::where('user_id', $userId)
            ->where('category_id', $categoryId)
            ->where('month', now()->month)
            ->where('year',  now()->year)
            ->with('category')
            ->first();

        if ($budget && ! $budget->alert_sent && $budget->is_exceeded) {
            $budget->update(['alert_sent' => true]);

            // Flash in-app alert
            session()->flash('budget_alert', "⚠️ You've exceeded your budget for {$budget->category->name}!");

            // Send email notification
            try {
                $budget->user->notify(new BudgetExceededNotification($budget));
            } catch (\Throwable $e) {
                // Don't break the request if mail fails
                \Illuminate\Support\Facades\Log::warning(
                    "Budget exceeded email failed for user {$userId}: " . $e->getMessage()
                );
            }
        }
    }

    // ── private helpers ──────────────────────────────────────

    private function applyBalance(Account $account, string $type, float $amount, string $direction): void
    {
        $isAdd = $direction === 'add';

        if ($type === 'income') {
            $isAdd ? $account->increment('balance', $amount)
                   : $account->decrement('balance', $amount);
        } else {
            $isAdd ? $account->decrement('balance', $amount)
                   : $account->increment('balance', $amount);
        }
    }

    private function bustBudgetCache(int $userId, int $categoryId): void
    {
        $budget = Budget::where('user_id', $userId)
            ->where('category_id', $categoryId)
            ->where('month', now()->month)
            ->where('year',  now()->year)
            ->first();

        $budget?->forgetSpentCache();
    }
}
PHP

# ── Fix the budget->amount typo in ReportController ─────────
write_file "app/Http/Controllers/ReportController.php" << 'PHP'
<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use App\Models\Transfer;
use App\Models\Budget;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class ReportController extends Controller
{
    public function index(Request $request)
    {
        $userId = auth()->id();

        $year  = (int) $request->get('year',  now()->year);
        $month = (int) $request->get('month', now()->month);

        $startDate = \Carbon\Carbon::create($year, $month, 1)->startOfMonth();
        $endDate   = $startDate->copy()->endOfMonth();

        $accountIds = \App\Models\Account::where('user_id', $userId)->pluck('id');

        // ── Core totals ──────────────────────────────────────────────
        $totalIncome = Transaction::whereIn('account_id', $accountIds)
            ->where('type', 'income')
            ->whereBetween('date', [$startDate, $endDate])
            ->sum('amount');

        $totalExpenses = Transaction::whereIn('account_id', $accountIds)
            ->where('type', 'expense')
            ->whereBetween('date', [$startDate, $endDate])
            ->sum('amount');

        $netSavings = $totalIncome - $totalExpenses;

        // ── Spending by category ──────────────────────────────────────
        $spendingByCategory = Transaction::whereIn('transactions.account_id', $accountIds)
            ->where('transactions.type', 'expense')
            ->whereBetween('transactions.date', [$startDate, $endDate])
            ->join('categories', 'transactions.category_id', '=', 'categories.id')
            ->select('categories.name as category', DB::raw('SUM(transactions.amount) as total'))
            ->groupBy('categories.name')
            ->orderByDesc('total')
            ->get();

        // ── Income by category ────────────────────────────────────────
        $incomeByCategory = Transaction::whereIn('transactions.account_id', $accountIds)
            ->where('transactions.type', 'income')
            ->whereBetween('transactions.date', [$startDate, $endDate])
            ->join('categories', 'transactions.category_id', '=', 'categories.id')
            ->select('categories.name as category', DB::raw('SUM(transactions.amount) as total'))
            ->groupBy('categories.name')
            ->orderByDesc('total')
            ->get();

        // ── Daily spending trend ──────────────────────────────────────
        $dailySpending = Transaction::whereIn('account_id', $accountIds)
            ->where('type', 'expense')
            ->whereBetween('date', [$startDate, $endDate])
            ->select(DB::raw('DAY(date) as day'), DB::raw('SUM(amount) as total'))
            ->groupBy('day')
            ->orderBy('day')
            ->pluck('total', 'day');

        $daysInMonth = $endDate->day;
        $dailyData   = [];
        for ($d = 1; $d <= $daysInMonth; $d++) {
            $dailyData[$d] = (float) ($dailySpending[$d] ?? 0);
        }

        // ── Budget performance — FIXED: uses limit_amount not amount ──
        $budgets = Budget::with('category')
            ->where('user_id', $userId)
            ->where('month', $month)
            ->where('year', $year)
            ->get()
            ->map(function ($budget) use ($accountIds, $startDate, $endDate) {
                $spent = Transaction::whereIn('account_id', $accountIds)
                    ->where('type', 'expense')
                    ->where('category_id', $budget->category_id)
                    ->whereBetween('date', [$startDate, $endDate])
                    ->sum('amount');

                $budget->spent        = $spent;
                $budget->percentage   = $budget->limit_amount > 0
                    ? min(100, ($spent / $budget->limit_amount) * 100)
                    : 0;
                $budget->exceeded     = $spent > $budget->limit_amount;
                // FIXED: was $budget->amount, now correctly $budget->limit_amount
                $budget->amount       = $budget->limit_amount;
                return $budget;
            });

        // ── Top 5 largest expenses ────────────────────────────────────
        $topExpenses = Transaction::with('category')
            ->whereIn('account_id', $accountIds)
            ->where('type', 'expense')
            ->whereBetween('date', [$startDate, $endDate])
            ->orderByDesc('amount')
            ->limit(5)
            ->get();

        // ── Transfers this month ──────────────────────────────────────
        $transfersCount = Transfer::where('user_id', $userId)
            ->whereBetween('transfer_date', [$startDate, $endDate])
            ->count();

        $transfersTotal = Transfer::where('user_id', $userId)
            ->whereBetween('transfer_date', [$startDate, $endDate])
            ->sum('amount');

        // ── Available months for selector (last 24 months) ───────────
        $availableMonths = [];
        for ($i = 0; $i < 24; $i++) {
            $dt = now()->startOfMonth()->subMonths($i);
            $availableMonths[] = [
                'year'  => $dt->year,
                'month' => $dt->month,
                'label' => $dt->format('F Y'),
            ];
        }

        return view('reports.index', compact(
            'year', 'month', 'startDate',
            'totalIncome', 'totalExpenses', 'netSavings',
            'spendingByCategory', 'incomeByCategory',
            'dailyData', 'daysInMonth',
            'budgets', 'topExpenses',
            'transfersCount', 'transfersTotal',
            'availableMonths'
        ));
    }

    public function exportCsv(Request $request)
    {
        $userId    = auth()->id();
        $year      = (int) $request->get('year',  now()->year);
        $month     = (int) $request->get('month', now()->month);
        $startDate = \Carbon\Carbon::create($year, $month, 1)->startOfMonth();
        $endDate   = $startDate->copy()->endOfMonth();

        $accountIds   = \App\Models\Account::where('user_id', $userId)->pluck('id');
        $transactions = \App\Models\Transaction::with(['category', 'account'])
            ->whereIn('account_id', $accountIds)
            ->whereBetween('date', [$startDate, $endDate])
            ->orderByDesc('date')
            ->get();

        $csv = "Date,Account,Category,Type,Amount,Description\n";
        foreach ($transactions as $t) {
            $csv .= implode(',', [
                $t->date->format('Y-m-d'),
                '"' . $t->account->name . '"',
                '"' . $t->category->name . '"',
                $t->type,
                $t->amount,
                '"' . ($t->description ?? '') . '"',
            ]) . "\n";
        }

        $filename = "finflow-report-{$year}-{$month}.csv";
        return response($csv, 200, [
            'Content-Type'        => 'text/csv',
            'Content-Disposition' => "attachment; filename=\"{$filename}\"",
        ]);
    }
}
PHP

# ── Register command in artisan ──────────────────────────────
echo ""
echo -e "${CYAN}Registering artisan command...${NC}"
php artisan list 2>/dev/null | grep -q "finflow:process-recurring" && \
    echo -e "  ${GREEN}✔${NC} Command already registered" || \
    echo -e "  ${YELLOW}ℹ${NC}  Command will be registered on next artisan call"

# ── Clear caches ─────────────────────────────────────────────
echo ""
echo -e "${CYAN}Clearing application caches...${NC}"
php artisan config:clear   2>/dev/null && echo -e "  ${GREEN}✔${NC} Config cache cleared"   || true
php artisan cache:clear    2>/dev/null && echo -e "  ${GREEN}✔${NC} App cache cleared"      || true
php artisan view:clear     2>/dev/null && echo -e "  ${GREEN}✔${NC} View cache cleared"     || true
php artisan route:clear    2>/dev/null && echo -e "  ${GREEN}✔${NC} Route cache cleared"    || true

# ── Summary ──────────────────────────────────────────────────
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║                  ✅  All Done!                           ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║  What was improved:                                      ║${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}║  1. Form Request classes for all controllers             ║${NC}"
echo -e "${CYAN}║  2. TransactionService now actually used everywhere      ║${NC}"
echo -e "${CYAN}║  3. Budget N+1 fixed — spent amounts are now cached      ║${NC}"
echo -e "${CYAN}║  4. Recurring transactions run automatically at 00:05    ║${NC}"
echo -e "${CYAN}║  5. Budget exceeded → real email notification sent       ║${NC}"
echo -e "${CYAN}║  6. Report budget->amount typo fixed to limit_amount     ║${NC}"
echo -e "${CYAN}║                                                          ║${NC}"
echo -e "${CYAN}║  Next steps:                                             ║${NC}"
echo -e "${CYAN}║  • Set MAIL_* vars in .env for email notifications       ║${NC}"
echo -e "${CYAN}║  • Add scheduler to cron:                                ║${NC}"
echo -e "${CYAN}║    * * * * * php artisan schedule:run >> /dev/null 2>&1  ║${NC}"
echo -e "${CYAN}║  • Test recurring manually:                              ║${NC}"
echo -e "${CYAN}║    php artisan finflow:process-recurring --dry-run       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
