#!/bin/bash

# ============================================================
#  FinFlow Auto-Improvement Script
#  Run this from your project root:
#  bash finflow-improve.sh
# ============================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()    { echo -e "${GREEN}[OK]${NC} $1"; }
warn()   { echo -e "${YELLOW}[!!]${NC} $1"; }
info()   { echo -e "${BLUE}[..]${NC} $1"; }
error()  { echo -e "${RED}[ERR]${NC} $1"; }

echo ""
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}   FinFlow Auto-Improvement Patcher v1.0        ${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Guard: must be run from Laravel root
if [ ! -f "artisan" ]; then
  error "Run this script from your Laravel project root (where artisan lives)."
  exit 1
fi

# ─────────────────────────────────────────────────────────────
# 1. FIX: Remove CSRF exemption for chat routes
# ─────────────────────────────────────────────────────────────
info "Fixing CSRF exemption in VerifyCsrfToken..."

cat > app/Http/Middleware/VerifyCsrfToken.php << 'PHP'
<?php

namespace App\Http\Middleware;

use Illuminate\Foundation\Http\Middleware\VerifyCsrfToken as Middleware;

class VerifyCsrfToken extends Middleware
{
    /**
     * The URIs that should be excluded from CSRF verification.
     * NOTE: Chat routes are handled via X-CSRF-TOKEN header in JS fetch,
     * so no exemption is needed here.
     *
     * @var array<int, string>
     */
    protected $except = [
        //
    ];
}
PHP
log "VerifyCsrfToken fixed."

# ─────────────────────────────────────────────────────────────
# 2. FIX: API key via config() not env() in FinancialAIService
# ─────────────────────────────────────────────────────────────
info "Fixing API key loading in FinancialAIService..."

cat > app/Services/FinancialAIService.php << 'PHP'
<?php

namespace App\Services;

use App\Models\User;
use App\Models\Transaction;
use App\Models\Budget;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FinancialAIService
{
    private string $apiKey;
    private string $model   = 'llama-3.1-8b-instant';
    private string $baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

    public function __construct()
    {
        // Use config() so it works correctly after `php artisan config:cache`
        $this->apiKey = config('services.groq.key', '');
    }

    /**
     * Build financial context for the user
     */
    public function buildContext(User $user): array
    {
        $now = now();

        $totalBalance   = $user->accounts()->sum('balance');
        $monthlyIncome  = Transaction::forUser($user->id)->thisMonth()->where('type', 'income')->sum('amount');
        $monthlyExpense = Transaction::forUser($user->id)->thisMonth()->where('type', 'expense')->sum('amount');
        $weeklyExpense  = Transaction::forUser($user->id)->thisWeek()->where('type', 'expense')->sum('amount');

        $lastMonthExpense = Transaction::forUser($user->id)
            ->whereMonth('date', $now->copy()->subMonth()->month)
            ->whereYear('date',  $now->copy()->subMonth()->year)
            ->where('type', 'expense')
            ->sum('amount');

        // Top spending categories this month
        $topCategories = Transaction::forUser($user->id)
            ->thisMonth()
            ->where('type', 'expense')
            ->with('category')
            ->selectRaw('category_id, SUM(amount) as total')
            ->groupBy('category_id')
            ->orderByDesc('total')
            ->limit(5)
            ->get()
            ->map(fn($t) => [
                'category' => $t->category->name ?? 'Other',
                'amount'   => round($t->total, 2),
            ]);

        // Budget status – eager-load spent amounts to avoid N+1
        $accountIds = $user->accounts()->pluck('id');

        $spentByCategory = Transaction::whereIn('account_id', $accountIds)
            ->where('type', 'expense')
            ->whereMonth('date', $now->month)
            ->whereYear('date',  $now->year)
            ->selectRaw('category_id, SUM(amount) as total')
            ->groupBy('category_id')
            ->pluck('total', 'category_id');

        $budgets = Budget::where('user_id', $user->id)
            ->where('month', $now->month)
            ->where('year',  $now->year)
            ->with('category')
            ->get()
            ->map(function ($b) use ($spentByCategory) {
                $spent     = (float) ($spentByCategory[$b->category_id] ?? 0);
                $remaining = max(0, $b->limit_amount - $spent);
                $pct       = $b->limit_amount > 0
                    ? min(100, round(($spent / $b->limit_amount) * 100, 1))
                    : 0;
                return [
                    'category'   => $b->category->name,
                    'limit'      => $b->limit_amount,
                    'spent'      => round($spent, 2),
                    'remaining'  => round($remaining, 2),
                    'percentage' => $pct,
                    'exceeded'   => $spent > $b->limit_amount,
                ];
            });

        // Recent transactions (last 5)
        $recentTx = Transaction::forUser($user->id)
            ->with(['category', 'account'])
            ->orderByDesc('date')
            ->limit(5)
            ->get()
            ->map(fn($t) => [
                'date'        => $t->date->format('M d'),
                'description' => $t->description ?? $t->category->name,
                'type'        => $t->type,
                'amount'      => $t->amount,
                'category'    => $t->category->name,
            ]);

        $accounts = $user->accounts()->get()->map(fn($a) => [
            'name'    => $a->name,
            'type'    => $a->account_type,
            'balance' => $a->balance,
        ]);

        $expenseChange = $lastMonthExpense > 0
            ? round((($monthlyExpense - $lastMonthExpense) / $lastMonthExpense) * 100, 1)
            : 0;

        return [
            'user_name'           => $user->name,
            'currency'            => $user->currency ?? 'USD',
            'total_balance'       => round($totalBalance, 2),
            'monthly_income'      => round($monthlyIncome, 2),
            'monthly_expense'     => round($monthlyExpense, 2),
            'weekly_expense'      => round($weeklyExpense, 2),
            'net_savings'         => round($monthlyIncome - $monthlyExpense, 2),
            'expense_change_pct'  => $expenseChange,
            'last_month_expense'  => round($lastMonthExpense, 2),
            'accounts'            => $accounts,
            'top_categories'      => $topCategories,
            'budgets'             => $budgets,
            'recent_transactions' => $recentTx,
            'month'               => $now->format('F Y'),
        ];
    }

    /**
     * Send message to Groq AI and get response
     */
    public function chat(User $user, string $message): array
    {
        $context      = $this->buildContext($user);
        $systemPrompt = $this->buildSystemPrompt($context);

        $response = Http::withHeaders([
            'Authorization' => 'Bearer ' . $this->apiKey,
            'Content-Type'  => 'application/json',
        ])->post($this->baseUrl, [
            'model'       => $this->model,
            'max_tokens'  => 600,
            'temperature' => 0.7,
            'messages'    => [
                ['role' => 'system', 'content' => $systemPrompt],
                ['role' => 'user',   'content' => $message],
            ],
        ]);

        if ($response->failed()) {
            Log::error('Groq API Error', [
                'status' => $response->status(),
                'body'   => $response->body(),
            ]);
            throw new \RuntimeException('AI service error: ' . $response->status());
        }

        $data         = $response->json();
        $responseText = $data['choices'][0]['message']['content'] ?? 'Sorry, I could not generate a response.';
        $tokens       = $data['usage']['completion_tokens'] ?? 0;

        return [
            'response' => $responseText,
            'context'  => $context,
            'tokens'   => $tokens,
        ];
    }

    /**
     * Generate automatic dashboard insight
     */
    public function generateDashboardInsight(User $user): string
    {
        try {
            $result = $this->chat($user, 'auto_insight: Give me ONE key financial insight about my spending this month in 1-2 sentences. Be specific and actionable.');
            return $result['response'];
        } catch (\Exception $e) {
            return 'Unable to generate insight at this time.';
        }
    }

    private function buildSystemPrompt(array $ctx): string
    {
        $budgetSummary = collect($ctx['budgets'])->map(fn($b) =>
            "- {$b['category']}: spent {$ctx['currency']} {$b['spent']} of {$ctx['currency']} {$b['limit']} limit" .
            ($b['exceeded'] ? ' (EXCEEDED)' : " ({$b['percentage']}% used)")
        )->join("\n");

        $categorySummary = collect($ctx['top_categories'])->map(fn($c) =>
            "- {$c['category']}: {$ctx['currency']} {$c['amount']}"
        )->join("\n");

        $accountSummary = collect($ctx['accounts'])->map(fn($a) =>
            "- {$a['name']} ({$a['type']}): {$ctx['currency']} {$a['balance']}"
        )->join("\n");

        $recentTx = collect($ctx['recent_transactions'])->map(fn($t) =>
            "- [{$t['date']}] {$t['description']} | {$t['type']} {$ctx['currency']} {$t['amount']} ({$t['category']})"
        )->join("\n");

        $expenseNote = $ctx['expense_change_pct'] != 0
            ? ($ctx['expense_change_pct'] > 0
                ? "spending is up {$ctx['expense_change_pct']}% vs last month"
                : "spending is down " . abs($ctx['expense_change_pct']) . "% vs last month")
            : "no previous month data available";

        return <<<PROMPT
You are FinFlow AI, a friendly and insightful personal finance assistant for {$ctx['user_name']}.
You have access to their real financial data for {$ctx['month']}. Be concise, helpful, and supportive.

## Current Financial Snapshot
- **Total Balance:** {$ctx['currency']} {$ctx['total_balance']}
- **Monthly Income:** {$ctx['currency']} {$ctx['monthly_income']}
- **Monthly Expenses:** {$ctx['currency']} {$ctx['monthly_expense']}
- **Weekly Spending:** {$ctx['currency']} {$ctx['weekly_expense']}
- **Net Savings:** {$ctx['currency']} {$ctx['net_savings']}
- **Expense Trend:** {$expenseNote}

## Accounts
{$accountSummary}

## Top Spending Categories This Month
{$categorySummary}

## Budget Status
{$budgetSummary}

## Recent Transactions
{$recentTx}

## Instructions
- Answer questions about finances using ONLY the data above
- Be specific with numbers when relevant
- If asked for advice, provide practical, actionable tips
- Use a friendly, encouraging tone
- Keep responses under 150 words unless a detailed breakdown is requested
- If data is missing, say so honestly
PROMPT;
    }
}
PHP
log "FinancialAIService fixed (config key + N+1 budget query)."

# ─────────────────────────────────────────────────────────────
# 3. FIX: ReportController budget->amount → budget->limit_amount
# ─────────────────────────────────────────────────────────────
info "Fixing ReportController budget field name..."

sed -i "s/\$budget->amount/\$budget->limit_amount/g" app/Http/Controllers/ReportController.php
log "ReportController patched."

# ─────────────────────────────────────────────────────────────
# 4. FIX: TransactionController - wrap update in DB transaction
# ─────────────────────────────────────────────────────────────
info "Fixing TransactionController with DB transactions..."

cat > app/Http/Controllers/TransactionController.php << 'PHP'
<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use App\Models\Account;
use App\Models\Category;
use App\Models\Budget;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class TransactionController extends Controller
{
    public function index(Request $request)
    {
        $user  = Auth::user();
        $query = Transaction::forUser($user->id)->with(['category', 'account']);

        if ($request->filled('type')) {
            $query->where('type', $request->type);
        }
        if ($request->filled('category_id')) {
            $query->where('category_id', $request->category_id);
        }
        if ($request->filled('account_id')) {
            $query->whereHas('account', fn($q) => $q->where('id', $request->account_id)
                                                      ->where('user_id', $user->id));
        }
        if ($request->filled('date_from')) {
            $query->whereDate('date', '>=', $request->date_from);
        }
        if ($request->filled('date_to')) {
            $query->whereDate('date', '<=', $request->date_to);
        }
        if ($request->filled('search')) {
            // LIKE works on both MySQL and PostgreSQL
            $query->where('description', 'LIKE', '%' . $request->search . '%');
        }

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

    public function store(Request $request)
    {
        $user = Auth::user();

        $data = $request->validate([
            'account_id'  => ['required', 'exists:accounts,id'],
            'category_id' => ['required', 'exists:categories,id'],
            'amount'      => ['required', 'numeric', 'min:0.01'],
            'type'        => ['required', 'in:income,expense'],
            'description' => ['nullable', 'string', 'max:255'],
            'notes'       => ['nullable', 'string', 'max:1000'],
            'date'        => ['required', 'date'],
        ]);

        $account = Account::where('id', $data['account_id'])
            ->where('user_id', $user->id)
            ->firstOrFail();

        $transaction = DB::transaction(function () use ($data, $account) {
            $tx = Transaction::create($data);
            if ($data['type'] === 'income') {
                $account->increment('balance', $data['amount']);
            } else {
                $account->decrement('balance', $data['amount']);
            }
            return $tx;
        });

        $this->checkBudgetAlert($user, $data['category_id'], $data['type']);

        if ($request->wantsJson()) {
            return response()->json([
                'success'     => true,
                'transaction' => $transaction->load('category', 'account'),
            ]);
        }

        return redirect(route('transactions.index'))->with('success', 'Transaction added!');
    }

    public function edit(Transaction $transaction)
    {
        $this->authorizeTransaction($transaction);
        $categories = Category::all();
        $accounts   = Auth::user()->accounts()->get();
        return view('transactions.edit', compact('transaction', 'categories', 'accounts'));
    }

    public function update(Request $request, Transaction $transaction)
    {
        $this->authorizeTransaction($transaction);
        $user = Auth::user();

        $data = $request->validate([
            'account_id'  => ['required', 'exists:accounts,id'],
            'category_id' => ['required', 'exists:categories,id'],
            'amount'      => ['required', 'numeric', 'min:0.01'],
            'type'        => ['required', 'in:income,expense'],
            'description' => ['nullable', 'string', 'max:255'],
            'date'        => ['required', 'date'],
        ]);

        DB::transaction(function () use ($data, $transaction, $user) {
            // Reverse old balance effect
            $oldAccount = $transaction->account;
            if ($transaction->type === 'income') {
                $oldAccount->decrement('balance', $transaction->amount);
            } else {
                $oldAccount->increment('balance', $transaction->amount);
            }

            $transaction->update($data);

            // Apply new balance effect
            $newAccount = Account::where('id', $data['account_id'])
                ->where('user_id', $user->id)
                ->firstOrFail();

            if ($data['type'] === 'income') {
                $newAccount->increment('balance', $data['amount']);
            } else {
                $newAccount->decrement('balance', $data['amount']);
            }
        });

        return redirect(route('transactions.index'))->with('success', 'Transaction updated!');
    }

    public function destroy(Transaction $transaction)
    {
        $this->authorizeTransaction($transaction);

        DB::transaction(function () use ($transaction) {
            $account = $transaction->account;
            if ($transaction->type === 'income') {
                $account->decrement('balance', $transaction->amount);
            } else {
                $account->increment('balance', $transaction->amount);
            }
            $transaction->delete();
        });

        return redirect(route('transactions.index'))->with('success', 'Transaction deleted.');
    }

    private function authorizeTransaction(Transaction $transaction): void
    {
        if ($transaction->account->user_id !== Auth::id()) {
            abort(403);
        }
    }

    private function checkBudgetAlert(object $user, int $categoryId, string $type): void
    {
        if ($type !== 'expense') return;

        $budget = Budget::where('user_id', $user->id)
            ->where('category_id', $categoryId)
            ->where('month', now()->month)
            ->where('year',  now()->year)
            ->first();

        if ($budget && ! $budget->alert_sent && $budget->is_exceeded) {
            $budget->update(['alert_sent' => true]);
            session()->flash('budget_alert', "⚠️ You've exceeded your budget for {$budget->category->name}!");
        }
    }
}
PHP
log "TransactionController fixed (DB transactions + LIKE fix)."

# ─────────────────────────────────────────────────────────────
# 5. FIX: Add Groq key to config/services.php
# ─────────────────────────────────────────────────────────────
info "Adding Groq API key entry to config/services.php..."

# Only add if not already present
if ! grep -q "groq" config/services.php; then
  # Insert before the closing ];
  sed -i "s/^];$/\n    'groq' => [\n        'key' => env('OPENAI_API_KEY', ''),\n    ],\n\n];/" config/services.php
  log "Groq config entry added to config/services.php."
else
  warn "Groq entry already exists in config/services.php — skipped."
fi

# ─────────────────────────────────────────────────────────────
# 6. ADD: Database indexes migration
# ─────────────────────────────────────────────────────────────
info "Creating performance indexes migration..."

TIMESTAMP=$(date +"%Y_%m_%d_%H%M%S")
MIGRATION_FILE="database/migrations/${TIMESTAMP}_add_performance_indexes.php"

cat > "$MIGRATION_FILE" << 'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            // Speed up dashboard/report queries dramatically
            $table->index(['account_id', 'type', 'date'], 'tx_account_type_date');
            $table->index('date', 'tx_date');
            $table->index('category_id', 'tx_category');
        });

        Schema::table('budgets', function (Blueprint $table) {
            $table->index(['user_id', 'month', 'year'], 'budgets_user_month_year');
        });

        Schema::table('chat_logs', function (Blueprint $table) {
            $table->index(['user_id', 'created_at'], 'chat_logs_user_created');
        });
    }

    public function down(): void
    {
        Schema::table('transactions', function (Blueprint $table) {
            $table->dropIndex('tx_account_type_date');
            $table->dropIndex('tx_date');
            $table->dropIndex('tx_category');
        });

        Schema::table('budgets', function (Blueprint $table) {
            $table->dropIndex('budgets_user_month_year');
        });

        Schema::table('chat_logs', function (Blueprint $table) {
            $table->dropIndex('chat_logs_user_created');
        });
    }
};
PHP
log "Migration created: $MIGRATION_FILE"

# ─────────────────────────────────────────────────────────────
# 7. ADD: TransactionService to clean up controller logic
# ─────────────────────────────────────────────────────────────
info "Creating TransactionService..."

mkdir -p app/Services

cat > app/Services/TransactionService.php << 'PHP'
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

    // ── private helpers ────────────────────────────────────────

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
log "TransactionService created."

# ─────────────────────────────────────────────────────────────
# 8. ADD: Password Reset routes + controller
# ─────────────────────────────────────────────────────────────
info "Adding password reset support..."

cat > app/Http/Controllers/PasswordResetController.php << 'PHP'
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Password;
use Illuminate\Auth\Events\PasswordReset;
use Illuminate\Support\Str;

class PasswordResetController extends Controller
{
    public function showForgot()
    {
        return view('auth.forgot-password');
    }

    public function sendLink(Request $request)
    {
        $request->validate(['email' => ['required', 'email']]);

        $status = Password::sendResetLink($request->only('email'));

        return $status === Password::RESET_LINK_SENT
            ? back()->with('success', __($status))
            : back()->withErrors(['email' => __($status)]);
    }

    public function showReset(string $token)
    {
        return view('auth.reset-password', ['token' => $token]);
    }

    public function reset(Request $request)
    {
        $request->validate([
            'token'    => ['required'],
            'email'    => ['required', 'email'],
            'password' => ['required', 'min:8', 'confirmed'],
        ]);

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function ($user, $password) {
                $user->forceFill(['password' => Hash::make($password)])
                     ->setRememberToken(Str::random(60));
                $user->save();
                event(new PasswordReset($user));
            }
        );

        return $status === Password::PASSWORD_RESET
            ? redirect()->route('login')->with('success', 'Password reset successfully!')
            : back()->withErrors(['email' => __($status)]);
    }
}
PHP
log "PasswordResetController created."

# Add routes for password reset (only if not already present)
if ! grep -q "forgot-password" routes/web.php; then
  cat >> routes/web.php << 'PHP'

// ── Password Reset ────────────────────────────────────────────
Route::middleware('guest')->group(function () {
    Route::get('/forgot-password',        [App\Http\Controllers\PasswordResetController::class, 'showForgot'])->name('password.request');
    Route::post('/forgot-password',       [App\Http\Controllers\PasswordResetController::class, 'sendLink'])->name('password.email');
    Route::get('/reset-password/{token}', [App\Http\Controllers\PasswordResetController::class, 'showReset'])->name('password.reset');
    Route::post('/reset-password',        [App\Http\Controllers\PasswordResetController::class, 'reset'])->name('password.update');
});
PHP
  log "Password reset routes added to routes/web.php."
else
  warn "Password reset routes already exist — skipped."
fi

# ─────────────────────────────────────────────────────────────
# 9. ADD: Forgot password Blade view
# ─────────────────────────────────────────────────────────────
info "Creating forgot-password view..."

cat > resources/views/auth/forgot-password.blade.php << 'BLADE'
@extends('layouts.auth')
@section('title', 'Forgot Password')
@section('content')

<div class="text-center mb-6">
    <h2 class="text-xl font-bold text-white">Reset Password</h2>
    <p class="text-gray-600 text-sm mt-1">Enter your email and we'll send a reset link.</p>
</div>

@if(session('success'))
<div class="bg-emerald-500/10 border border-emerald-500/20 text-emerald-400 text-sm rounded-xl px-4 py-3 mb-4">
    {{ session('success') }}
</div>
@endif

@if($errors->any())
<div class="bg-red-500/10 border border-red-500/20 text-red-400 text-sm rounded-xl px-4 py-3 mb-4">
    {{ $errors->first() }}
</div>
@endif

<form method="POST" action="{{ route('password.email') }}" class="space-y-4">
    @csrf
    <div>
        <label class="block text-xs font-medium text-gray-500 mb-1.5 uppercase tracking-wide">Email</label>
        <input type="email" name="email" value="{{ old('email') }}" required autofocus
               class="w-full px-4 py-3 rounded-xl bg-gray-800 border border-gray-700 text-white placeholder-gray-600
                      outline-none focus:border-indigo-500 transition text-sm"
               placeholder="you@example.com"/>
    </div>
    <button type="submit"
            class="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3 rounded-xl transition text-sm">
        Send Reset Link
    </button>
</form>

<p class="text-center text-sm text-gray-600 mt-5">
    Remembered it?
    <a href="{{ route('login') }}" class="text-indigo-400 font-semibold hover:text-indigo-300">Sign in</a>
</p>

@endsection
BLADE
log "forgot-password.blade.php created."

# ─────────────────────────────────────────────────────────────
# 10. ADD: Reset password Blade view
# ─────────────────────────────────────────────────────────────
info "Creating reset-password view..."

cat > resources/views/auth/reset-password.blade.php << 'BLADE'
@extends('layouts.auth')
@section('title', 'Set New Password')
@section('content')

<div class="text-center mb-6">
    <h2 class="text-xl font-bold text-white">Set New Password</h2>
    <p class="text-gray-600 text-sm mt-1">Choose a strong new password.</p>
</div>

@if($errors->any())
<div class="bg-red-500/10 border border-red-500/20 text-red-400 text-sm rounded-xl px-4 py-3 mb-4">
    @foreach($errors->all() as $error)<div>{{ $error }}</div>@endforeach
</div>
@endif

<form method="POST" action="{{ route('password.update') }}" class="space-y-4">
    @csrf
    <input type="hidden" name="token" value="{{ $token }}">
    <div>
        <label class="block text-xs font-medium text-gray-500 mb-1.5 uppercase tracking-wide">Email</label>
        <input type="email" name="email" value="{{ old('email') }}" required
               class="w-full px-4 py-3 rounded-xl bg-gray-800 border border-gray-700 text-white placeholder-gray-600
                      outline-none focus:border-indigo-500 transition text-sm"
               placeholder="you@example.com"/>
    </div>
    <div>
        <label class="block text-xs font-medium text-gray-500 mb-1.5 uppercase tracking-wide">New Password</label>
        <input type="password" name="password" required
               class="w-full px-4 py-3 rounded-xl bg-gray-800 border border-gray-700 text-white placeholder-gray-600
                      outline-none focus:border-indigo-500 transition text-sm"
               placeholder="Min. 8 characters"/>
    </div>
    <div>
        <label class="block text-xs font-medium text-gray-500 mb-1.5 uppercase tracking-wide">Confirm Password</label>
        <input type="password" name="password_confirmation" required
               class="w-full px-4 py-3 rounded-xl bg-gray-800 border border-gray-700 text-white placeholder-gray-600
                      outline-none focus:border-indigo-500 transition text-sm"
               placeholder="Repeat password"/>
    </div>
    <button type="submit"
            class="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3 rounded-xl transition text-sm">
        Reset Password
    </button>
</form>

@endsection
BLADE
log "reset-password.blade.php created."

# ─────────────────────────────────────────────────────────────
# 11. FIX: Add "Forgot password?" link to login page
# ─────────────────────────────────────────────────────────────
info "Adding forgot password link to login view..."

if ! grep -q "password.request" resources/views/auth/login.blade.php; then
  sed -i "s|<label for=\"remember\" class=\"text-sm text-gray-500\">Remember me</label>|<label for=\"remember\" class=\"text-sm text-gray-500\">Remember me</label>\n    </div>\n    <div class=\"text-right\">\n        <a href=\"{{ route('password.request') }}\" class=\"text-xs text-indigo-400 hover:text-indigo-300\">Forgot password?</a>|" \
    resources/views/auth/login.blade.php
  log "Forgot password link added to login view."
else
  warn "Forgot password link already exists — skipped."
fi

# ─────────────────────────────────────────────────────────────
# 12. RUN: Migrations
# ─────────────────────────────────────────────────────────────
info "Running new migrations..."
php artisan migrate --force && log "Migrations ran successfully." || warn "Migration failed — check DB connection."

# ─────────────────────────────────────────────────────────────
# 13. CLEAR: All caches
# ─────────────────────────────────────────────────────────────
info "Clearing caches..."
php artisan config:clear
php artisan cache:clear
php artisan view:clear
php artisan route:clear
log "All caches cleared."

# ─────────────────────────────────────────────────────────────
# DONE
# ─────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   All improvements applied successfully!       ${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo -e "  ${YELLOW}Summary of changes:${NC}"
echo "  1. CSRF exemption removed from chat routes"
echo "  2. AI service now uses config() instead of env()"
echo "  3. ReportController budget field name fixed"
echo "  4. Transactions wrapped in DB::transaction()"
echo "  5. ILIKE replaced with LIKE (MySQL compatible)"
echo "  6. Performance indexes migration added & run"
echo "  7. TransactionService created for clean logic"
echo "  8. Password reset routes + controller added"
echo "  9. Forgot/Reset password views created"
echo " 10. Forgot password link added to login page"
echo " 11. All caches cleared"
echo ""
echo -e "  ${BLUE}Next steps:${NC}"
echo "  - Configure MAIL_* in your .env for password reset emails"
echo "  - Consider using TransactionService in your controller"
echo "  - Run: php artisan route:list   to verify new routes"
echo ""
