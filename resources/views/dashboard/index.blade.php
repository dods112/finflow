@extends('layouts.app')
@section('title', 'Dashboard')

@section('content')
<div class="pb-28 lg:pb-8">

    {{-- HERO --}}
    <div class="relative bg-gray-900 border-b border-gray-800 px-4 sm:px-6 lg:px-8 pt-10 lg:pt-8 pb-8 overflow-hidden">
        <div class="absolute top-0 right-0 w-48 h-48 bg-indigo-600/10 rounded-full blur-3xl pointer-events-none -translate-y-1/2 translate-x-1/4"></div>
        <div class="absolute bottom-0 left-0 w-32 h-32 bg-purple-600/10 rounded-full blur-2xl pointer-events-none"></div>

        <div class="relative flex items-center justify-between mb-6">
            <div>
                <p class="text-gray-600 text-xs uppercase tracking-widest">{{ now()->format('l, M d') }}</p>
                <h1 class="text-white text-lg font-semibold mt-0.5">Hi, {{ auth()->user()->name }} 👋</h1>
            </div>
            <a href="{{ route('profile.index') }}"
               class="w-10 h-10 rounded-2xl bg-indigo-600 flex items-center justify-center text-white font-bold text-sm shadow-lg shadow-indigo-600/30">
                {{ strtoupper(substr(auth()->user()->name, 0, 2)) }}
            </a>
        </div>

        <div class="relative mb-2">
            <p class="text-gray-600 text-xs uppercase tracking-widest mb-1">Total Balance</p>
            <h2 class="text-3xl sm:text-4xl font-bold text-white font-mono tracking-tight">
                {{ auth()->user()->currency }} {{ number_format($totalBalance, 2) }}
            </h2>
        </div>

        @if(count($dailySpending) > 0)
        <div class="relative h-10 mb-4">
            <canvas id="sparklineChart"></canvas>
        </div>
        @endif

        <div class="relative flex gap-3 mt-4">
            <div class="flex-1 bg-gray-800/80 rounded-2xl px-4 py-3 border border-gray-700/50">
                <div class="flex items-center gap-1.5 mb-1">
                    <div class="w-2 h-2 rounded-full bg-emerald-400"></div>
                    <p class="text-gray-500 text-[10px] uppercase tracking-wide">Income</p>
                </div>
                <p class="text-emerald-400 font-bold text-sm font-mono">+ {{ number_format($monthlyIncome, 2) }}</p>
            </div>
            <div class="flex-1 bg-gray-800/80 rounded-2xl px-4 py-3 border border-gray-700/50">
                <div class="flex items-center gap-1.5 mb-1">
                    <div class="w-2 h-2 rounded-full bg-red-400"></div>
                    <p class="text-gray-500 text-[10px] uppercase tracking-wide">Expenses</p>
                </div>
                <p class="text-red-400 font-bold text-sm font-mono">- {{ number_format($monthlyExpense, 2) }}</p>
            </div>
        </div>
    </div>

    <div class="px-4 sm:px-6 lg:px-8 pt-4 space-y-4">

        {{-- Desktop: 2-col grid for cards --}}
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">

            {{-- AI Insight --}}
            <div class="bg-gray-900 rounded-2xl p-4 border border-indigo-500/20 card-hover">
                <div class="flex items-start gap-3">
                    <div class="w-8 h-8 rounded-lg bg-indigo-600 flex items-center justify-center flex-shrink-0 mt-0.5">
                        <svg class="w-4 h-4 text-white" fill="none" stroke="currentColor" stroke-width="2" viewBox="0 0 24 24">
                            <path stroke-linecap="round" stroke-linejoin="round" d="M9.663 17h4.673M12 3v1m6.364 1.636l-.707.707M21 12h-1M4 12H3m3.343-5.657l-.707-.707m2.828 9.9a5 5 0 117.072 0l-.548.547A3.374 3.374 0 0014 18.469V19a2 2 0 11-4 0v-.531c0-.895-.356-1.754-.988-2.386l-.548-.547z"/>
                        </svg>
                    </div>
                    <div class="flex-1">
                        <p class="text-indigo-400 text-[10px] font-semibold uppercase tracking-widest mb-1">AI Insight</p>
                        @php $net = $monthlyIncome - $monthlyExpense; $sr = $monthlyIncome > 0 ? round(($net / $monthlyIncome) * 100) : 0; @endphp
                        <p class="text-gray-400 text-sm leading-relaxed">
                            @if($monthlyExpense == 0) Add your first transaction to get personalized insights.
                            @elseif($monthlyExpense > $monthlyIncome && $monthlyIncome > 0) ⚠️ You're spending more than you earn this month.
                            @elseif($sr > 20) 🎉 You're saving {{ $sr }}% of your income this month. Great work!
                            @else Net savings: {{ auth()->user()->currency }} {{ number_format($net, 2) }} — {{ $sr }}% savings rate.
                            @endif
                        </p>
                    </div>
                    <a href="{{ route('chat.index') }}" class="text-indigo-400 text-xs shrink-0 hover:text-indigo-300 transition">Ask AI →</a>
                </div>
            </div>

            {{-- Spending Donut --}}
            @if($spendingByCategory->count() > 0)
            <div class="bg-gray-900 rounded-2xl p-4 border border-gray-800">
                <p class="text-gray-600 text-[10px] font-semibold uppercase tracking-widest mb-4">Spending This Month</p>
                <div class="flex items-center gap-4">
                    <div class="w-28 h-28 flex-shrink-0 relative">
                        <canvas id="donutChart"></canvas>
                        <div class="absolute inset-0 flex items-center justify-center">
                            <div class="text-center">
                                <p class="text-white font-bold text-xs font-mono">{{ number_format($monthlyExpense, 0) }}</p>
                                <p class="text-gray-600 text-[9px]">total</p>
                            </div>
                        </div>
                    </div>
                    <div class="flex-1 space-y-2">
                        @foreach($spendingByCategory->take(4) as $cat)
                        <div class="flex items-center justify-between gap-2">
                            <div class="flex items-center gap-2 min-w-0">
                                <div class="w-2 h-2 rounded-full flex-shrink-0" style="background-color:{{ $cat['color'] }}"></div>
                                <span class="text-xs text-gray-500 truncate">{{ $cat['name'] }}</span>
                            </div>
                            <span class="text-xs font-mono text-gray-300 flex-shrink-0">{{ number_format($cat['total'], 0) }}</span>
                        </div>
                        @endforeach
                    </div>
                </div>
            </div>
            @endif
        </div>

        {{-- Accounts --}}
        @if($accounts->count() > 0)
        <div>
            <div class="flex items-center justify-between mb-2 px-1">
                <p class="text-gray-600 text-[10px] font-semibold uppercase tracking-widest">Accounts</p>
                <a href="{{ route('accounts.index') }}" class="text-indigo-400 text-xs">Manage →</a>
            </div>
            <div class="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
                @foreach($accounts as $account)
                <div class="bg-gray-900 rounded-2xl p-4 border border-gray-800 card-hover relative overflow-hidden">
                    <div class="absolute top-0 right-0 w-16 h-16 rounded-full opacity-10" style="background-color:{{ $account->color }};transform:translate(30%,-30%)"></div>
                    <div class="w-8 h-8 rounded-xl mb-3 flex items-center justify-center" style="background-color:{{ $account->color }}22">
                        <div class="w-3 h-3 rounded-full" style="background-color:{{ $account->color }}"></div>
                    </div>
                    <p class="text-gray-600 text-[10px] uppercase tracking-wide">{{ $account->type_label }}</p>
                    <p class="text-white font-bold text-base font-mono mt-0.5">{{ number_format($account->balance, 2) }}</p>
                    <p class="text-gray-600 text-xs mt-1 truncate">{{ $account->name }}</p>
                </div>
                @endforeach
            </div>
        </div>
        @endif

        {{-- Desktop 2-col: Budgets + Recent Transactions --}}
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-4">

            {{-- Budgets --}}
            @if($budgets->count() > 0)
            <div class="bg-gray-900 rounded-2xl p-4 border border-gray-800">
                <div class="flex items-center justify-between mb-4">
                    <p class="text-gray-600 text-[10px] font-semibold uppercase tracking-widest">Budgets</p>
                    <a href="{{ route('budgets.index') }}" class="text-indigo-400 text-xs">See all →</a>
                </div>
                <div class="space-y-3">
                    @foreach($budgets->take(4) as $budget)
                    @php
                        $pct   = $budget->percentage;
                        $color = $budget->status_color;
                        $bar   = match($color) { 'red' => 'bg-red-500', 'amber' => 'bg-amber-500', default => 'bg-emerald-500' };
                        $txt   = match($color) { 'red' => 'text-red-400', 'amber' => 'text-amber-400', default => 'text-emerald-400' };
                    @endphp
                    <div>
                        <div class="flex items-center justify-between mb-1.5">
                            <span class="text-sm text-gray-300">{{ $budget->category->name }}</span>
                            <span class="text-xs font-mono {{ $txt }}">{{ $pct }}%</span>
                        </div>
                        <div class="h-1.5 bg-gray-800 rounded-full overflow-hidden">
                            <div class="{{ $bar }} h-full rounded-full progress-bar" style="width:{{ $pct }}%"></div>
                        </div>
                        <div class="flex justify-between mt-1">
                            <span class="text-[10px] text-gray-700">{{ number_format($budget->spent, 0) }} spent</span>
                            <span class="text-[10px] text-gray-700">{{ number_format($budget->limit_amount, 0) }} limit</span>
                        </div>
                    </div>
                    @endforeach
                </div>
            </div>
            @endif

            {{-- Recent Transactions --}}
            <div class="bg-gray-900 rounded-2xl p-4 border border-gray-800">
                <div class="flex items-center justify-between mb-4">
                    <p class="text-gray-600 text-[10px] font-semibold uppercase tracking-widest">Recent Transactions</p>
                    <a href="{{ route('transactions.index') }}" class="text-indigo-400 text-xs">See all →</a>
                </div>
                @if($recentTransactions->count() === 0)
                <div class="text-center py-8">
                    <p class="text-gray-700 text-sm mb-1">No transactions yet</p>
                    <a href="{{ route('transactions.create') }}" class="text-indigo-400 text-xs">Add your first one →</a>
                </div>
                @else
                <div class="space-y-3">
                    @foreach($recentTransactions as $tx)
                    <div class="flex items-center gap-3">
                        <div class="w-9 h-9 rounded-xl flex items-center justify-center flex-shrink-0"
                             style="background-color:{{ ($tx->category->color ?? '#6366f1') }}18">
                            <div class="w-3 h-3 rounded-full" style="background-color:{{ $tx->category->color ?? '#6366f1' }}"></div>
                        </div>
                        <div class="flex-1 min-w-0">
                            <p class="text-sm text-gray-200 truncate font-medium">{{ $tx->description ?: $tx->category->name }}</p>
                            <p class="text-xs text-gray-600">{{ $tx->date->format('M d') }} · {{ $tx->account->name }}</p>
                        </div>
                        <span class="font-mono font-bold text-sm {{ $tx->type === 'income' ? 'text-emerald-400' : 'text-red-400' }}">
                            {{ $tx->formatted_amount }}
                        </span>
                    </div>
                    @endforeach
                </div>
                @endif
            </div>

        </div>
    </div>
</div>
@endsection

@push('scripts')
@if($spendingByCategory->count() > 0)
<script>
const ctx = document.getElementById('donutChart')?.getContext('2d');
if (ctx) {
    new Chart(ctx, {
        type: 'doughnut',
        data: {
            labels: {!! json_encode($spendingByCategory->pluck('name')) !!},
            datasets: [{ data: {!! json_encode($spendingByCategory->pluck('total')) !!}, backgroundColor: {!! json_encode($spendingByCategory->pluck('color')) !!}, borderWidth: 0, hoverOffset: 4 }]
        },
        options: { cutout: '75%', plugins: { legend: { display: false }, tooltip: { enabled: false } }, animation: { animateRotate: true, duration: 900 } }
    });
}
</script>
@endif
@if(count($dailySpending) > 0)
<script>
const spCtx = document.getElementById('sparklineChart')?.getContext('2d');
if (spCtx) {
    const grad = spCtx.createLinearGradient(0, 0, 0, 40);
    grad.addColorStop(0, 'rgba(99,102,241,0.4)');
    grad.addColorStop(1, 'rgba(99,102,241,0)');
    new Chart(spCtx, {
        type: 'line',
        data: { labels: {!! json_encode(array_keys($dailySpending->toArray())) !!}, datasets: [{ data: {!! json_encode(array_values($dailySpending->toArray())) !!}, borderColor: '#6366f1', backgroundColor: grad, borderWidth: 1.5, fill: true, tension: 0.4, pointRadius: 0 }] },
        options: { responsive: true, maintainAspectRatio: false, plugins: { legend: { display: false }, tooltip: { enabled: false } }, scales: { x: { display: false }, y: { display: false, beginAtZero: true } }, animation: { duration: 800 } }
    });
}
</script>
@endif
@endpush
