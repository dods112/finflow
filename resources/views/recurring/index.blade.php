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
