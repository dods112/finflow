@extends('layouts.app')
@section('title', 'Budgets')

@section('content')
<div class="max-w-lg mx-auto">

    <div class="px-5 pt-12 pb-4">
        <div class="flex items-center justify-between mb-1">
            <h1 class="text-lg font-bold text-white">Budgets</h1>
            <button onclick="document.getElementById('addBudgetModal').classList.remove('hidden')"
                    class="w-8 h-8 rounded-full bg-indigo-600 text-white flex items-center justify-center hover:bg-indigo-500 transition">
                <svg class="w-4 h-4" fill="none" stroke="currentColor" stroke-width="2.5" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M12 4v16m8-8H4"/>
                </svg>
            </button>
        </div>
        <form method="GET" class="flex gap-2 mt-3">
            <select name="month" onchange="this.form.submit()"
                    class="bg-gray-800 border border-gray-700 rounded-xl px-3 py-2 text-sm outline-none text-white">
                @foreach(range(1, 12) as $m)
                <option value="{{ $m }}" {{ $month == $m ? 'selected' : '' }}>
                    {{ date('F', mktime(0,0,0,$m,1)) }}
                </option>
                @endforeach
            </select>
            <select name="year" onchange="this.form.submit()"
                    class="bg-gray-800 border border-gray-700 rounded-xl px-3 py-2 text-sm outline-none text-white">
                @foreach(range(now()->year - 1, now()->year + 1) as $y)
                <option value="{{ $y }}" {{ $year == $y ? 'selected' : '' }}>{{ $y }}</option>
                @endforeach
            </select>
        </form>
    </div>

    <div class="px-4 space-y-3 pb-8">

        {{-- Summary --}}
        @if($totalBudgeted > 0)
        <div class="bg-gray-900 rounded-2xl p-5 border border-gray-800">
            <p class="text-gray-600 text-[10px] uppercase tracking-widest mb-3">Monthly Overview</p>
            <div class="flex justify-between mb-3">
                <div>
                    <p class="text-gray-600 text-xs mb-0.5">Spent</p>
                    <p class="text-xl font-bold text-white font-mono">{{ number_format($totalSpent, 2) }}</p>
                </div>
                <div class="text-right">
                    <p class="text-gray-600 text-xs mb-0.5">Budgeted</p>
                    <p class="text-xl font-bold text-white font-mono">{{ number_format($totalBudgeted, 2) }}</p>
                </div>
            </div>
            @php $overallPct = $totalBudgeted > 0 ? min(100, round(($totalSpent / $totalBudgeted) * 100)) : 0; @endphp
            <div class="h-1.5 bg-gray-800 rounded-full">
                <div class="h-full rounded-full bg-indigo-500 progress-bar" style="width: {{ $overallPct }}%"></div>
            </div>
            <p class="text-gray-700 text-xs mt-2">{{ $overallPct }}% used</p>
        </div>
        @endif

        {{-- Budget List --}}
        @if($budgets->count() === 0)
        <div class="text-center py-12">
            <div class="w-12 h-12 rounded-2xl bg-gray-800 flex items-center justify-center mx-auto mb-3">
                <svg class="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" stroke-width="1.5" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" d="M11 3.055A9.001 9.001 0 1020.945 13H11V3.055z"/>
                </svg>
            </div>
            <p class="text-gray-600 text-sm mb-2">No budgets set for this month</p>
            <button onclick="document.getElementById('addBudgetModal').classList.remove('hidden')"
                    class="text-indigo-400 text-sm">Set a budget</button>
        </div>
        @else
        @foreach($budgets as $budget)
        @php
            $pct      = $budget->percentage;
            $color    = $budget->status_color;
            $barColor = match($color) { 'red' => 'bg-red-500', 'amber' => 'bg-amber-500', default => 'bg-emerald-500' };
            $txtColor = match($color) { 'red' => 'text-red-400', 'amber' => 'text-amber-400', default => 'text-emerald-400' };
        @endphp
        <div class="bg-gray-900 rounded-2xl p-4 border border-gray-800">
            <div class="flex items-center justify-between mb-3">
                <div class="flex items-center gap-3">
                    <div class="w-9 h-9 rounded-xl bg-gray-800 flex items-center justify-center">
                        <div class="w-2.5 h-2.5 rounded-full" style="background-color: {{ $budget->category->color }}"></div>
                    </div>
                    <div>
                        <p class="font-semibold text-white text-sm">{{ $budget->category->name }}</p>
                        <p class="text-xs text-gray-600">{{ auth()->user()->currency }} {{ number_format($budget->remaining, 2) }} remaining</p>
                    </div>
                </div>
                <div class="flex items-center gap-3">
                    <span class="{{ $txtColor }} font-bold text-sm font-mono">{{ $pct }}%</span>
                    <form method="POST" action="{{ route('budgets.destroy', $budget) }}"
                          onsubmit="return confirm('Remove this budget?')">
                        @csrf @method('DELETE')
                        <button type="submit" class="text-gray-700 hover:text-red-400 transition">
                            <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                            </svg>
                        </button>
                    </form>
                </div>
            </div>
            <div class="h-1.5 bg-gray-800 rounded-full overflow-hidden">
                <div class="{{ $barColor }} h-full rounded-full progress-bar" style="width: {{ $pct }}%"></div>
            </div>
            <div class="flex justify-between mt-2">
                <span class="text-xs text-gray-700">Spent: <span class="font-mono text-gray-500">{{ number_format($budget->spent, 2) }}</span></span>
                <span class="text-xs text-gray-700">Limit: <span class="font-mono text-gray-500">{{ number_format($budget->limit_amount, 2) }}</span></span>
            </div>
            @if($budget->is_exceeded)
            <p class="mt-2 text-red-400 text-xs font-medium">
                Over budget by {{ auth()->user()->currency }} {{ number_format($budget->spent - $budget->limit_amount, 2) }}
            </p>
            @endif
        </div>
        @endforeach
        @endif

    </div>
</div>

{{-- ADD BUDGET MODAL --}}
<div id="addBudgetModal" class="hidden fixed inset-0 z-50 flex items-end justify-center">
    <div class="absolute inset-0 bg-black/70 backdrop-blur-sm"
         onclick="document.getElementById('addBudgetModal').classList.add('hidden')"></div>
    <div class="relative bg-gray-900 border border-gray-800 rounded-t-2xl w-full max-w-lg p-6 slide-up">
        <h3 class="font-bold text-white text-lg mb-5">Set Budget</h3>
        <form method="POST" action="{{ route('budgets.store') }}" class="space-y-4">
            @csrf
            <input type="hidden" name="month" value="{{ $month }}">
            <input type="hidden" name="year"  value="{{ $year }}">
            <div>
                <label class="block text-xs text-gray-600 mb-1.5 uppercase tracking-wide">Category</label>
                <select name="category_id" required
                        class="w-full bg-gray-800 border border-gray-700 rounded-xl px-4 py-3 text-sm outline-none text-white">
                    @foreach($categories as $cat)
                    <option value="{{ $cat->id }}">{{ $cat->name }}</option>
                    @endforeach
                </select>
            </div>
            <div>
                <label class="block text-xs text-gray-600 mb-1.5 uppercase tracking-wide">Monthly Limit</label>
                <div class="relative">
                    <span class="absolute left-4 top-1/2 -translate-y-1/2 text-gray-600 text-sm">{{ auth()->user()->currency }}</span>
                    <input type="number" name="limit_amount" step="0.01" min="1" required placeholder="0.00"
                           class="w-full bg-gray-800 border border-gray-700 rounded-xl pl-14 pr-4 py-3 text-sm outline-none text-white placeholder-gray-700"/>
                </div>
            </div>
            <div class="flex gap-3 pt-1">
                <button type="button"
                        onclick="document.getElementById('addBudgetModal').classList.add('hidden')"
                        class="flex-1 bg-gray-800 border border-gray-700 text-gray-400 font-semibold py-3.5 rounded-xl">
                    Cancel
                </button>
                <button type="submit" class="flex-1 bg-indigo-600 hover:bg-indigo-500 text-white font-semibold py-3.5 rounded-xl transition">
                    Save Budget
                </button>
            </div>
        </form>
    </div>
</div>

@endsection