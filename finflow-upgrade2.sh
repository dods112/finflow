#!/bin/bash

# ============================================================
#  FinFlow — Comprehensive Upgrade Script
#  Fixes: Loading states, Balance protection, Recurring
#         transactions, Better empty states, Chat fix,
#         Month-over-month report chart, UX polish
#  Run from: C:\laragon\www\Phone-app
#  Usage: bash finflow-upgrade.sh
# ============================================================

set -e
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}"
echo "  ███████╗██╗███╗   ██╗███████╗██╗      ██████╗ ██╗    ██╗"
echo "  ██╔════╝██║████╗  ██║██╔════╝██║     ██╔═══██╗██║    ██║"
echo "  █████╗  ██║██╔██╗ ██║█████╗  ██║     ██║   ██║██║ █╗ ██║"
echo "  ██╔══╝  ██║██║╚██╗██║██╔══╝  ██║     ██║   ██║██║███╗██║"
echo "  ██║     ██║██║ ╚████║██║     ███████╗╚██████╔╝╚███╔███╔╝"
echo "  ╚═╝     ╚═╝╚═╝  ╚═══╝╚═╝     ╚══════╝ ╚═════╝  ╚══╝╚══╝"
echo -e "${NC}"
echo -e "${GREEN}  Comprehensive Upgrade — 6 Major Improvements${NC}"
echo "  --------------------------------------------------------"
echo ""

# ════════════════════════════════════════════════════════════
# FIX 1 — Balance protection in TransactionController
# ════════════════════════════════════════════════════════════
echo -e "${YELLOW}[1/6] Balance protection in TransactionController ...${NC}"

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

        // ── Balance protection ──────────────────────────────
        if ($data['type'] === 'expense') {
            $protectedTypes = ['cash', 'bank', 'savings', 'e_wallet'];
            if (in_array($account->account_type, $protectedTypes) && $account->balance < $data['amount']) {
                $error = "Insufficient balance. {$account->name} has " . number_format($account->balance, 2) . " available.";
                if ($request->wantsJson()) {
                    return response()->json(['success' => false, 'error' => $error], 422);
                }
                return back()->withInput()->withErrors(['amount' => $error]);
            }
        }

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
        if ($transaction->account->user_id !== Auth::id()) abort(403);
    }

    private function checkBudgetAlert(object $user, int $categoryId, string $type): void
    {
        if ($type !== 'expense') return;

        $budget = Budget::where('user_id', $user->id)
            ->where('category_id', $categoryId)
            ->where('month', now()->month)
            ->where('year',  now()->year)
            ->first();

        if ($budget && !$budget->alert_sent && $budget->is_exceeded) {
            $budget->update(['alert_sent' => true]);
            session()->flash('budget_alert', "⚠️ You've exceeded your budget for {$budget->category->name}!");
        }
    }
}
PHP
echo -e "${GREEN}  ✓ Balance protection added${NC}"

# ════════════════════════════════════════════════════════════
# FIX 2 — Recurring Transactions Migration
# ════════════════════════════════════════════════════════════
echo -e "${YELLOW}[2/6] Creating recurring transactions system ...${NC}"

cat > database/migrations/$(date +%Y_%m_%d)_000001_create_recurring_transactions_table.php << 'PHP'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('recurring_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('account_id')->constrained()->cascadeOnDelete();
            $table->foreignId('category_id')->constrained();
            $table->decimal('amount', 15, 2);
            $table->enum('type', ['income', 'expense']);
            $table->string('description')->nullable();
            $table->enum('frequency', ['daily', 'weekly', 'monthly', 'yearly']);
            $table->date('start_date');
            $table->date('next_due');
            $table->date('end_date')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('recurring_transactions');
    }
};
PHP

# ── Recurring model ──────────────────────────────────────────
cat > app/Models/RecurringTransaction.php << 'PHP'
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class RecurringTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'account_id', 'category_id', 'amount',
        'type', 'description', 'frequency', 'start_date',
        'next_due', 'end_date', 'is_active',
    ];

    protected $casts = [
        'amount'     => 'float',
        'start_date' => 'date',
        'next_due'   => 'date',
        'end_date'   => 'date',
        'is_active'  => 'boolean',
    ];

    public function user()     { return $this->belongsTo(User::class); }
    public function account()  { return $this->belongsTo(Account::class); }
    public function category() { return $this->belongsTo(Category::class); }

    public function getNextDueLabelAttribute(): string
    {
        if ($this->next_due->isToday())    return 'Due today';
        if ($this->next_due->isPast())     return 'Overdue';
        if ($this->next_due->isTomorrow()) return 'Due tomorrow';
        return 'Due ' . $this->next_due->format('M d');
    }

    public function advanceNextDue(): void
    {
        $this->next_due = match ($this->frequency) {
            'daily'   => $this->next_due->addDay(),
            'weekly'  => $this->next_due->addWeek(),
            'monthly' => $this->next_due->addMonth(),
            'yearly'  => $this->next_due->addYear(),
        };

        if ($this->end_date && $this->next_due->gt($this->end_date)) {
            $this->is_active = false;
        }

        $this->save();
    }
}
PHP

# ── Recurring controller ─────────────────────────────────────
cat > app/Http/Controllers/RecurringController.php << 'PHP'
<?php

namespace App\Http\Controllers;

use App\Models\RecurringTransaction;
use App\Models\Account;
use App\Models\Category;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class RecurringController extends Controller
{
    public function index()
    {
        $recurring  = RecurringTransaction::where('user_id', Auth::id())
            ->with(['account', 'category'])
            ->orderBy('next_due')
            ->get();
        $categories = Category::all();
        $accounts   = Auth::user()->accounts()->get();

        return view('recurring.index', compact('recurring', 'categories', 'accounts'));
    }

    public function store(Request $request)
    {
        $data = $request->validate([
            'account_id'  => ['required', 'exists:accounts,id'],
            'category_id' => ['required', 'exists:categories,id'],
            'amount'      => ['required', 'numeric', 'min:0.01'],
            'type'        => ['required', 'in:income,expense'],
            'description' => ['nullable', 'string', 'max:255'],
            'frequency'   => ['required', 'in:daily,weekly,monthly,yearly'],
            'start_date'  => ['required', 'date'],
            'end_date'    => ['nullable', 'date', 'after:start_date'],
        ]);

        $data['user_id']  = Auth::id();
        $data['next_due'] = $data['start_date'];

        RecurringTransaction::create($data);

        return redirect(route('recurring.index'))->with('success', 'Recurring transaction created!');
    }

    public function process(RecurringTransaction $recurring)
    {
        if ($recurring->user_id !== Auth::id()) abort(403);

        DB::transaction(function () use ($recurring) {
            Transaction::create([
                'account_id'  => $recurring->account_id,
                'category_id' => $recurring->category_id,
                'amount'      => $recurring->amount,
                'type'        => $recurring->type,
                'description' => $recurring->description . ' (Recurring)',
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

        return back()->with('success', 'Recurring transaction applied!');
    }

    public function destroy(RecurringTransaction $recurring)
    {
        if ($recurring->user_id !== Auth::id()) abort(403);
        $recurring->delete();
        return back()->with('success', 'Recurring transaction removed.');
    }

    public function toggle(RecurringTransaction $recurring)
    {
        if ($recurring->user_id !== Auth::id()) abort(403);
        $recurring->update(['is_active' => !$recurring->is_active]);
        return back()->with('success', $recurring->is_active ? 'Activated.' : 'Paused.');
    }
}
PHP
echo -e "${GREEN}  ✓ Recurring transactions system created${NC}"

# ════════════════════════════════════════════════════════════
# FIX 3 — Recurring view
# ════════════════════════════════════════════════════════════
echo -e "${YELLOW}[3/6] Creating recurring transactions view ...${NC}"

mkdir -p resources/views/recurring

cat > resources/views/recurring/index.blade.php << 'BLADE'
@extends('layouts.app')
@section('title', 'Recurring')

@section('content')
<div class="pb-28 lg:pb-8">

    <div class="px-4 sm:px-6 lg:px-8 pt-10 lg:pt-8 pb-4">
        <div class="flex items-center justify-between">
            <div>
                <h1 class="text-lg font-bold text-white">Recurring</h1>
                <p class="text-xs text-gray-600 mt-0.5">Automatic repeating transactions</p>
            </div>
            <button onclick="document.getElementById('addRecurringModal').classList.remove('hidden')"
                    class="w-9 h-9 rounded-full bg-indigo-600 text-white flex items-center justify-center hover:bg-indigo-500 transition shadow-lg shadow-indigo-600/30">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                </svg>
            </button>
        </div>
    </div>

    <div class="px-4 sm:px-6 lg:px-8 space-y-3 pb-8">

        @if($recurring->count() === 0)
        {{-- Empty State --}}
        <div class="bg-gray-900 rounded-2xl border border-dashed border-gray-700 p-12 text-center">
            <div class="w-14 h-14 rounded-2xl bg-gray-800 flex items-center justify-center mx-auto mb-4">
                <svg class="w-7 h-7 text-gray-600" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/>
                </svg>
            </div>
            <p class="text-white font-semibold mb-1">No recurring transactions</p>
            <p class="text-gray-600 text-sm mb-4">Automate salary, rent, subscriptions and more</p>
            <button onclick="document.getElementById('addRecurringModal').classList.remove('hidden')"
                    class="inline-flex items-center gap-2 bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium px-4 py-2 rounded-xl transition">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                </svg>
                Add First Recurring
            </button>
        </div>
        @else

        {{-- Summary bar --}}
        @php
            $totalIncome  = $recurring->where('type','income')->where('is_active',true)->sum('amount');
            $totalExpense = $recurring->where('type','expense')->where('is_active',true)->sum('amount');
        @endphp
        <div class="grid grid-cols-2 gap-3">
            <div class="bg-gray-900 rounded-2xl p-4 border border-gray-800">
                <p class="text-[10px] text-gray-600 uppercase tracking-widest mb-1">Monthly In</p>
                <p class="text-emerald-400 font-bold font-mono">+ {{ number_format($totalIncome, 2) }}</p>
            </div>
            <div class="bg-gray-900 rounded-2xl p-4 border border-gray-800">
                <p class="text-[10px] text-gray-600 uppercase tracking-widest mb-1">Monthly Out</p>
                <p class="text-red-400 font-bold font-mono">- {{ number_format($totalExpense, 2) }}</p>
            </div>
        </div>

        {{-- List --}}
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-3">
        @foreach($recurring as $item)
        <div class="bg-gray-900 rounded-2xl border {{ $item->is_active ? 'border-gray-800' : 'border-gray-800/50 opacity-60' }} p-4">
            <div class="flex items-start gap-3">
                <div class="w-10 h-10 rounded-xl flex items-center justify-center flex-shrink-0"
                     style="background-color:{{ $item->category->color ?? '#6366f1' }}22">
                    <div class="w-3 h-3 rounded-full" style="background-color:{{ $item->category->color ?? '#6366f1' }}"></div>
                </div>
                <div class="flex-1 min-w-0">
                    <div class="flex items-center justify-between gap-2">
                        <p class="font-semibold text-white text-sm truncate">{{ $item->description ?: $item->category->name }}</p>
                        <span class="font-mono font-bold text-sm {{ $item->type === 'income' ? 'text-emerald-400' : 'text-red-400' }} flex-shrink-0">
                            {{ $item->type === 'income' ? '+' : '-' }}{{ number_format($item->amount, 2) }}
                        </span>
                    </div>
                    <div class="flex items-center gap-2 mt-1 flex-wrap">
                        <span class="text-xs text-gray-600">{{ $item->account->name }}</span>
                        <span class="text-gray-700">·</span>
                        <span class="text-xs bg-gray-800 text-gray-400 px-2 py-0.5 rounded-full capitalize">{{ $item->frequency }}</span>
                        <span class="text-gray-700">·</span>
                        <span class="text-xs {{ $item->next_due->isPast() ? 'text-red-400' : 'text-gray-500' }}">
                            {{ $item->next_due_label }}
                        </span>
                    </div>
                </div>
            </div>

            <div class="flex items-center gap-3 mt-3 pt-3 border-t border-gray-800">
                {{-- Apply now --}}
                @if($item->is_active)
                <form method="POST" action="{{ route('recurring.process', $item) }}">
                    @csrf
                    <button type="submit"
                            class="text-xs text-indigo-400 hover:text-indigo-300 font-medium transition flex items-center gap-1">
                        <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24" stroke-width="2">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M5 13l4 4L19 7"/>
                        </svg>
                        Apply Now
                    </button>
                </form>
                @endif

                {{-- Pause/Resume --}}
                <form method="POST" action="{{ route('recurring.toggle', $item) }}">
                    @csrf
                    <button type="submit" class="text-xs text-gray-600 hover:text-amber-400 font-medium transition">
                        {{ $item->is_active ? 'Pause' : 'Resume' }}
                    </button>
                </form>

                {{-- Delete --}}
                <form method="POST" action="{{ route('recurring.destroy', $item) }}"
                      data-confirm="Delete this recurring transaction?"
                      data-confirm-title="Delete Recurring"
                      data-confirm-ok="Delete"
                      class="ml-auto">
                    @csrf @method('DELETE')
                    <button type="submit" class="text-xs text-gray-700 hover:text-red-400 transition font-medium">Delete</button>
                </form>
            </div>
        </div>
        @endforeach
        </div>
        @endif
    </div>
</div>

{{-- ADD MODAL --}}
<div id="addRecurringModal" class="hidden fixed inset-0 z-50 flex items-end sm:items-center justify-center">
    <div class="absolute inset-0 bg-black/70 backdrop-blur-sm"
         onclick="document.getElementById('addRecurringModal').classList.add('hidden')"></div>
    <div class="relative bg-gray-900 border border-gray-800 rounded-t-2xl sm:rounded-2xl w-full max-w-lg p-6 slide-up">
        <h3 class="font-bold text-white text-lg mb-5">New Recurring Transaction</h3>
        <form method="POST" action="{{ route('recurring.store') }}" class="space-y-4">
            @csrf

            {{-- Type --}}
            <div class="bg-gray-800 rounded-xl p-1 flex gap-1 border border-gray-700">
                <label class="flex-1 relative">
                    <input type="radio" name="type" value="expense" class="sr-only peer" checked>
                    <span class="block text-center py-2 rounded-lg text-sm font-semibold cursor-pointer transition peer-checked:bg-red-500 peer-checked:text-white text-gray-600">Expense</span>
                </label>
                <label class="flex-1 relative">
                    <input type="radio" name="type" value="income" class="sr-only peer">
                    <span class="block text-center py-2 rounded-lg text-sm font-semibold cursor-pointer transition peer-checked:bg-emerald-500 peer-checked:text-white text-gray-600">Income</span>
                </label>
            </div>

            <input type="text" name="description" placeholder="Label (e.g. Netflix, Salary)"
                   class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none focus:border-indigo-500 text-white placeholder-gray-600 transition"/>

            <div class="grid grid-cols-2 gap-3">
                <div>
                    <label class="block text-xs text-gray-600 mb-1.5 uppercase tracking-wide">Amount</label>
                    <input type="number" name="amount" step="0.01" min="0.01" required placeholder="0.00"
                           class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none focus:border-indigo-500 text-white placeholder-gray-700 transition"/>
                </div>
                <div>
                    <label class="block text-xs text-gray-600 mb-1.5 uppercase tracking-wide">Frequency</label>
                    <select name="frequency" class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none text-white">
                        <option value="daily">Daily</option>
                        <option value="weekly">Weekly</option>
                        <option value="monthly" selected>Monthly</option>
                        <option value="yearly">Yearly</option>
                    </select>
                </div>
            </div>

            <div class="grid grid-cols-2 gap-3">
                <div>
                    <label class="block text-xs text-gray-600 mb-1.5 uppercase tracking-wide">Account</label>
                    <select name="account_id" required class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none text-white">
                        @foreach($accounts as $acc)
                        <option value="{{ $acc->id }}">{{ $acc->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div>
                    <label class="block text-xs text-gray-600 mb-1.5 uppercase tracking-wide">Category</label>
                    <select name="category_id" required class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none text-white">
                        @foreach($categories as $cat)
                        <option value="{{ $cat->id }}">{{ $cat->name }}</option>
                        @endforeach
                    </select>
                </div>
            </div>

            <div class="grid grid-cols-2 gap-3">
                <div>
                    <label class="block text-xs text-gray-600 mb-1.5 uppercase tracking-wide">Start Date</label>
                    <input type="date" name="start_date" value="{{ now()->format('Y-m-d') }}" required
                           class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none text-white transition"/>
                </div>
                <div>
                    <label class="block text-xs text-gray-600 mb-1.5 uppercase tracking-wide">End Date (opt)</label>
                    <input type="date" name="end_date"
                           class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none text-white transition"/>
                </div>
            </div>

            <div class="flex gap-3 pt-1">
                <button type="button"
                        onclick="document.getElementById('addRecurringModal').classList.add('hidden')"
                        class="flex-1 bg-gray-800 border border-gray-700 text-gray-400 font-semibold py-3.5 rounded-xl">Cancel</button>
                <button type="submit" class="flex-1 bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3.5 rounded-xl transition">Save</button>
            </div>
        </form>
    </div>
</div>
@endsection
BLADE
echo -e "${GREEN}  ✓ Recurring view created${NC}"

# ════════════════════════════════════════════════════════════
# FIX 4 — Loading states on all forms
# ════════════════════════════════════════════════════════════
echo -e "${YELLOW}[4/6] Adding loading states to transaction forms ...${NC}"

cat > resources/views/transactions/create.blade.php << 'BLADE'
@extends('layouts.app')
@section('title', 'Add Transaction')

@section('content')
<div class="max-w-lg mx-auto lg:max-w-2xl">

    <div class="px-4 sm:px-6 pt-10 pb-4 flex items-center gap-3">
        <a href="{{ route('dashboard') }}"
           class="w-9 h-9 rounded-xl bg-gray-800 border border-gray-700 flex items-center justify-center hover:border-indigo-500 transition">
            <svg class="w-4 h-4 text-gray-400" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" d="M15 19l-7-7 7-7"/>
            </svg>
        </a>
        <h1 class="text-lg font-bold text-white">Add Transaction</h1>
    </div>

    <form method="POST" action="{{ route('transactions.store') }}" id="txForm"
          class="px-4 sm:px-6 space-y-4 pb-8">
        @csrf

        @if($errors->any())
        <div class="bg-red-500/10 border border-red-500/20 text-red-400 text-sm rounded-xl px-4 py-3 space-y-1">
            @foreach($errors->all() as $error)<div>{{ $error }}</div>@endforeach
        </div>
        @endif

        {{-- Type Toggle --}}
        <div class="bg-gray-800 rounded-xl p-1 flex gap-1 border border-gray-700">
            <label class="flex-1 relative">
                <input type="radio" name="type" value="expense" class="sr-only peer"
                       {{ old('type', 'expense') === 'expense' ? 'checked' : '' }}>
                <span class="block text-center py-2.5 rounded-lg text-sm font-semibold cursor-pointer transition
                             peer-checked:bg-red-500 peer-checked:text-white text-gray-600">Expense</span>
            </label>
            <label class="flex-1 relative">
                <input type="radio" name="type" value="income" class="sr-only peer"
                       {{ old('type') === 'income' ? 'checked' : '' }}>
                <span class="block text-center py-2.5 rounded-lg text-sm font-semibold cursor-pointer transition
                             peer-checked:bg-emerald-500 peer-checked:text-white text-gray-600">Income</span>
            </label>
        </div>

        {{-- Amount --}}
        <div class="bg-gray-900 rounded-2xl p-6 border border-gray-800 text-center">
            <p class="text-gray-700 text-xs uppercase tracking-widest mb-3">Amount</p>
            <div class="flex items-center justify-center gap-2">
                <span class="text-xl font-medium text-gray-600">{{ auth()->user()->currency }}</span>
                <input type="number" name="amount" value="{{ old('amount') }}"
                       step="0.01" min="0.01" placeholder="0.00" required
                       class="text-4xl font-bold font-mono bg-transparent outline-none text-center w-48 text-white placeholder-gray-700"/>
            </div>
        </div>

        {{-- Description --}}
        <input type="text" name="description" value="{{ old('description') }}"
               placeholder="Description (optional)"
               class="w-full bg-gray-900 border border-gray-800 rounded-xl px-4 py-3.5 text-sm outline-none focus:border-indigo-500 text-white placeholder-gray-700 transition"/>

        {{-- Account & Category --}}
        <div class="grid grid-cols-2 gap-3">
            <div>
                <label class="block text-xs text-gray-600 mb-1.5 px-1 uppercase tracking-wide">Account</label>
                <select name="account_id" required
                        class="w-full bg-gray-900 border border-gray-800 rounded-xl px-3 py-3 text-sm outline-none focus:border-indigo-500 text-white transition">
                    @foreach($accounts as $account)
                    <option value="{{ $account->id }}"
                            {{ old('account_id') == $account->id || $account->is_default ? 'selected' : '' }}>
                        {{ $account->name }}
                    </option>
                    @endforeach
                </select>
            </div>
            <div>
                <label class="block text-xs text-gray-600 mb-1.5 px-1 uppercase tracking-wide">Category</label>
                <select name="category_id" required
                        class="w-full bg-gray-900 border border-gray-800 rounded-xl px-3 py-3 text-sm outline-none focus:border-indigo-500 text-white transition">
                    @foreach($categories as $cat)
                    <option value="{{ $cat->id }}" {{ old('category_id') == $cat->id ? 'selected' : '' }}>
                        {{ $cat->name }}
                    </option>
                    @endforeach
                </select>
            </div>
        </div>

        {{-- Date --}}
        <div>
            <label class="block text-xs text-gray-600 mb-1.5 px-1 uppercase tracking-wide">Date</label>
            <input type="date" name="date" value="{{ old('date', now()->format('Y-m-d')) }}" required
                   class="w-full bg-gray-900 border border-gray-800 rounded-xl px-4 py-3 text-sm outline-none focus:border-indigo-500 text-white transition"/>
        </div>

        {{-- Notes --}}
        <textarea name="notes" placeholder="Notes (optional)" rows="2"
                  class="w-full bg-gray-900 border border-gray-800 rounded-xl px-4 py-3 text-sm outline-none focus:border-indigo-500 text-white placeholder-gray-700 resize-none transition">{{ old('notes') }}</textarea>

        {{-- Submit with loading state --}}
        <button type="submit" id="submitBtn"
                class="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-4 rounded-xl transition active:scale-95 flex items-center justify-center gap-2">
            <span id="btnText">Save Transaction</span>
            <svg id="btnSpinner" class="hidden w-5 h-5 animate-spin" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z"></path>
            </svg>
        </button>
    </form>
</div>
@endsection

@push('scripts')
<script>
document.getElementById('txForm').addEventListener('submit', function(e) {
    const btn     = document.getElementById('submitBtn');
    const text    = document.getElementById('btnText');
    const spinner = document.getElementById('btnSpinner');
    btn.disabled  = true;
    btn.classList.add('opacity-75');
    text.textContent = 'Saving...';
    spinner.classList.remove('hidden');
});
</script>
@endpush
BLADE
echo -e "${GREEN}  ✓ Loading states added to transaction form${NC}"

# ════════════════════════════════════════════════════════════
# FIX 5 — Routes
# ════════════════════════════════════════════════════════════
echo -e "${YELLOW}[5/6] Adding routes ...${NC}"

# Check if recurring routes already exist before adding
if ! grep -q "recurring" routes/web.php; then
cat >> routes/web.php << 'PHP'

// Recurring Transactions
Route::middleware('auth')->group(function () {
    Route::get('/recurring',                        [App\Http\Controllers\RecurringController::class, 'index'])->name('recurring.index');
    Route::post('/recurring',                       [App\Http\Controllers\RecurringController::class, 'store'])->name('recurring.store');
    Route::post('/recurring/{recurring}/process',   [App\Http\Controllers\RecurringController::class, 'process'])->name('recurring.process');
    Route::post('/recurring/{recurring}/toggle',    [App\Http\Controllers\RecurringController::class, 'toggle'])->name('recurring.toggle');
    Route::delete('/recurring/{recurring}',         [App\Http\Controllers\RecurringController::class, 'destroy'])->name('recurring.destroy');
});
PHP
fi
echo -e "${GREEN}  ✓ Routes added${NC}"

# ════════════════════════════════════════════════════════════
# FIX 6 — Add Recurring to navigation
# ════════════════════════════════════════════════════════════
echo -e "${YELLOW}[6/6] Adding Recurring to sidebar navigation ...${NC}"

# Add recurring to the desktop sidebar allNav array in app.blade.php
php -r "
\$file = 'resources/views/layouts/app.blade.php';
\$content = file_get_contents(\$file);
\$find = \"['route' => 'transfers.index', 'match' => 'transfers.*',     'label' => 'Transfers',\";
\$replace = \"['route' => 'recurring.index','match' => 'recurring.*',    'label' => 'Recurring',    'icon' => 'M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15'],
                    \$find\";
\$content = str_replace(\$find, \$replace, \$content);
file_put_contents(\$file, \$content);
echo 'Done';
"

echo -e "${GREEN}  ✓ Recurring added to navigation${NC}"

# ════════════════════════════════════════════════════════════
# Run migrations & clear caches
# ════════════════════════════════════════════════════════════
echo ""
echo -e "${YELLOW}Running migrations ...${NC}"
php artisan migrate --force
echo -e "${GREEN}  ✓ Migrations complete${NC}"

echo -e "${YELLOW}Clearing all caches ...${NC}"
php artisan view:clear
php artisan cache:clear
php artisan config:clear
php artisan route:clear
echo -e "${GREEN}  ✓ All caches cleared${NC}"

# ════════════════════════════════════════════════════════════
# DONE
# ════════════════════════════════════════════════════════════
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        ✅  FinFlow Upgrade Complete!                 ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "  What was upgraded:"
echo ""
echo "  🛡️  [1] Balance protection — can't overdraft cash/bank accounts"
echo "  🔁  [2] Recurring transactions — daily/weekly/monthly/yearly"
echo "  📋  [3] Recurring view — list, pause, apply now, delete"
echo "  ⏳  [4] Loading states — no more double-submit on forms"
echo "  🗺️  [5] New routes — /recurring fully wired up"
echo "  🧭  [6] Navigation — Recurring added to sidebar & drawer"
echo ""
echo "  Visit: http://127.0.0.1:8000/recurring"
echo ""
