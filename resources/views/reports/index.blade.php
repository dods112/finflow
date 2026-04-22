@extends('layouts.app')

@section('title', 'Monthly Report — ' . \Carbon\Carbon::create($year, $month, 1)->format('F Y'))

@section('content')
<div class="min-h-screen bg-gray-950 pb-28">

    {{-- Header --}}
    <div class="sticky top-0 z-30 bg-gray-950/90 backdrop-blur border-b border-gray-800 px-4 py-4">
        <div class="flex items-center justify-between">
            <div>
                <h1 class="text-lg font-bold text-white">Monthly Report</h1>
                <p class="text-xs text-gray-400">{{ \Carbon\Carbon::create($year, $month, 1)->format('F Y') }}</p>
            </div>
            {{-- Month Selector --}}
            <form method="GET" action="{{ route('reports.index') }}" id="month-form">
                <input type="hidden" name="year"  id="input-year"  value="{{ $year }}">
                <input type="hidden" name="month" id="input-month" value="{{ $month }}">
                <select onchange="
                    var parts = this.value.split('-');
                    document.getElementById('input-year').value  = parts[0];
                    document.getElementById('input-month').value = parts[1];
                    document.getElementById('month-form').submit();
                "
                class="bg-gray-800 border border-gray-700 text-white text-sm rounded-xl px-3 py-2 focus:outline-none focus:ring-2 focus:ring-indigo-500">
                    @foreach($availableMonths as $m)
                    <option value="{{ $m['year'] }}-{{ str_pad($m['month'], 2, '0', STR_PAD_LEFT) }}"
                        {{ $m['year'] == $year && $m['month'] == $month ? 'selected' : '' }}>
                        {{ $m['label'] }}
                    </option>
                    @endforeach
                </select>
            </form>
        </div>
    </div>

    <div class="px-4 py-4 space-y-5">

        {{-- Summary Cards --}}
        <div class="grid grid-cols-3 gap-3">
            <div class="bg-gray-900 rounded-2xl border border-gray-800 p-3 text-center">
                <p class="text-xs text-gray-500 mb-1">Income</p>
                <p class="text-base font-bold text-green-400">{{ number_format($totalIncome, 0) }}</p>
                <p class="text-xs text-gray-600">{{ auth()->user()->currency ?? 'PHP' }}</p>
            </div>
            <div class="bg-gray-900 rounded-2xl border border-gray-800 p-3 text-center">
                <p class="text-xs text-gray-500 mb-1">Expenses</p>
                <p class="text-base font-bold text-red-400">{{ number_format($totalExpenses, 0) }}</p>
                <p class="text-xs text-gray-600">{{ auth()->user()->currency ?? 'PHP' }}</p>
            </div>
            <div class="bg-gray-900 rounded-2xl border border-gray-800 p-3 text-center">
                <p class="text-xs text-gray-500 mb-1">Saved</p>
                <p class="text-base font-bold {{ $netSavings >= 0 ? 'text-indigo-400' : 'text-red-400' }}">
                    {{ number_format(abs($netSavings), 0) }}
                </p>
                <p class="text-xs text-gray-600">{{ $netSavings >= 0 ? 'surplus' : 'deficit' }}</p>
            </div>
        </div>

        {{-- Savings Rate Bar --}}
        @if($totalIncome > 0)
        <div class="bg-gray-900 rounded-2xl border border-gray-800 p-4">
            @php $savingsRate = max(0, min(100, ($netSavings / $totalIncome) * 100)); @endphp
            <div class="flex justify-between items-center mb-2">
                <p class="text-sm font-semibold text-white">Savings Rate</p>
                <p class="text-sm font-bold {{ $savingsRate >= 20 ? 'text-green-400' : ($savingsRate >= 10 ? 'text-yellow-400' : 'text-red-400') }}">
                    {{ number_format($savingsRate, 1) }}%
                </p>
            </div>
            <div class="h-2.5 bg-gray-800 rounded-full overflow-hidden">
                <div class="h-full rounded-full transition-all duration-700
                    {{ $savingsRate >= 20 ? 'bg-green-500' : ($savingsRate >= 10 ? 'bg-yellow-500' : 'bg-red-500') }}"
                    style="width: {{ $savingsRate }}%"></div>
            </div>
            <p class="text-xs text-gray-600 mt-1.5">
                @if($savingsRate >= 20) Great job! You saved more than 20% this month.
                @elseif($savingsRate >= 10) Decent — aim for 20%+ next month.
                @elseif($savingsRate > 0) Try to save at least 10% of income.
                @else You spent more than you earned this month.
                @endif
            </p>
        </div>
        @endif

        {{-- Daily Spending Chart --}}
        <div class="bg-gray-900 rounded-2xl border border-gray-800 p-4">
            <p class="text-sm font-semibold text-white mb-4">Daily Spending Trend</p>
            <div class="relative h-32">
                <canvas id="dailyChart"></canvas>
            </div>
        </div>

        {{-- Spending by Category --}}
        @if($spendingByCategory->isNotEmpty())
        <div class="bg-gray-900 rounded-2xl border border-gray-800 p-4">
            <p class="text-sm font-semibold text-white mb-4">Spending by Category</p>
            <div class="space-y-3">
                @foreach($spendingByCategory as $item)
                @php $pct = $totalExpenses > 0 ? ($item->total / $totalExpenses) * 100 : 0; @endphp
                <div>
                    <div class="flex justify-between items-center mb-1">
                        <p class="text-sm text-gray-300">{{ $item->category }}</p>
                        <div class="text-right">
                            <p class="text-sm font-semibold text-white">
                                {{ auth()->user()->currency ?? 'PHP' }} {{ number_format($item->total, 2) }}
                            </p>
                            <p class="text-xs text-gray-500">{{ number_format($pct, 1) }}%</p>
                        </div>
                    </div>
                    <div class="h-1.5 bg-gray-800 rounded-full overflow-hidden">
                        <div class="h-full bg-indigo-500 rounded-full" style="width: {{ $pct }}%"></div>
                    </div>
                </div>
                @endforeach
            </div>
        </div>
        @endif

        {{-- Income by Category --}}
        @if($incomeByCategory->isNotEmpty())
        <div class="bg-gray-900 rounded-2xl border border-gray-800 p-4">
            <p class="text-sm font-semibold text-white mb-4">Income by Category</p>
            <div class="space-y-3">
                @foreach($incomeByCategory as $item)
                @php $pct = $totalIncome > 0 ? ($item->total / $totalIncome) * 100 : 0; @endphp
                <div>
                    <div class="flex justify-between items-center mb-1">
                        <p class="text-sm text-gray-300">{{ $item->category }}</p>
                        <div class="text-right">
                            <p class="text-sm font-semibold text-white">
                                {{ auth()->user()->currency ?? 'PHP' }} {{ number_format($item->total, 2) }}
                            </p>
                            <p class="text-xs text-gray-500">{{ number_format($pct, 1) }}%</p>
                        </div>
                    </div>
                    <div class="h-1.5 bg-gray-800 rounded-full overflow-hidden">
                        <div class="h-full bg-green-500 rounded-full" style="width: {{ $pct }}%"></div>
                    </div>
                </div>
                @endforeach
            </div>
        </div>
        @endif

        {{-- Budget Performance --}}
        @if($budgets->isNotEmpty())
        <div class="bg-gray-900 rounded-2xl border border-gray-800 p-4">
            <p class="text-sm font-semibold text-white mb-4">Budget Performance</p>
            <div class="space-y-3">
                @foreach($budgets as $budget)
                <div>
                    <div class="flex justify-between items-center mb-1">
                        <p class="text-sm text-gray-300">{{ $budget->category->name }}</p>
                        <p class="text-xs {{ $budget->exceeded ? 'text-red-400' : 'text-gray-400' }}">
                            {{ auth()->user()->currency ?? 'PHP' }} {{ number_format($budget->spent, 2) }}
                            / {{ number_format($budget->amount, 2) }}
                        </p>
                    </div>
                    <div class="h-1.5 bg-gray-800 rounded-full overflow-hidden">
                        <div class="h-full rounded-full {{ $budget->exceeded ? 'bg-red-500' : 'bg-indigo-500' }}"
                            style="width: {{ $budget->percentage }}%"></div>
                    </div>
                    @if($budget->exceeded)
                    <p class="text-xs text-red-400 mt-0.5">
                        Over by {{ auth()->user()->currency ?? 'PHP' }} {{ number_format($budget->spent - $budget->amount, 2) }}
                    </p>
                    @endif
                </div>
                @endforeach
            </div>
        </div>
        @endif

        {{-- Top 5 Expenses --}}
        @if($topExpenses->isNotEmpty())
        <div class="bg-gray-900 rounded-2xl border border-gray-800 p-4">
            <p class="text-sm font-semibold text-white mb-4">Top 5 Expenses</p>
            <div class="space-y-3">
                @foreach($topExpenses as $i => $tx)
                <div class="flex items-center gap-3">
                    <div class="w-6 h-6 rounded-full bg-gray-800 flex items-center justify-center text-xs font-bold text-gray-400">
                        {{ $i + 1 }}
                    </div>
                    <div class="flex-1 min-w-0">
                        <p class="text-sm text-white truncate">{{ $tx->description }}</p>
                        {{-- Use 'date' column, not 'transaction_date' --}}
                        <p class="text-xs text-gray-500">
                            {{ $tx->category->name ?? '—' }}
                            · {{ \Carbon\Carbon::parse($tx->date)->format('M d') }}
                        </p>
                    </div>
                    <p class="text-sm font-semibold text-red-400 shrink-0">
                        {{ auth()->user()->currency ?? 'PHP' }} {{ number_format($tx->amount, 2) }}
                    </p>
                </div>
                @endforeach
            </div>
        </div>
        @endif

        {{-- Transfers Summary --}}
        @if($transfersCount > 0)
        <div class="bg-gray-900 rounded-2xl border border-gray-800 p-4 flex items-center gap-4">
            <div class="w-10 h-10 bg-indigo-600/20 rounded-full flex items-center justify-center shrink-0">
                <svg class="w-5 h-5 text-indigo-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4"/>
                </svg>
            </div>
            <div>
                <p class="text-sm font-semibold text-white">
                    {{ $transfersCount }} Transfer{{ $transfersCount > 1 ? 's' : '' }} this month
                </p>
                <p class="text-xs text-gray-400">
                    Total moved: {{ auth()->user()->currency ?? 'PHP' }} {{ number_format($transfersTotal, 2) }}
                </p>
            </div>
        </div>
        @endif

        {{-- Empty State --}}
        @if($totalIncome == 0 && $totalExpenses == 0)
        <div class="bg-gray-900 rounded-2xl border border-gray-800 p-10 text-center">
            <div class="w-12 h-12 bg-gray-800 rounded-full flex items-center justify-center mx-auto mb-3">
                <svg class="w-6 h-6 text-gray-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2"
                        d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
                </svg>
            </div>
            <p class="text-gray-400 text-sm font-medium">No data for this month</p>
            <p class="text-gray-600 text-xs mt-1">Add transactions to see your report</p>
        </div>
        @endif

    </div>
</div>

{{-- Chart.js via CDN --}}
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<script>
document.addEventListener('DOMContentLoaded', function () {
    const dailyData = @json(array_values($dailyData));
    const labels    = @json(array_keys($dailyData));

    const ctx = document.getElementById('dailyChart').getContext('2d');

    const gradient = ctx.createLinearGradient(0, 0, 0, 128);
    gradient.addColorStop(0, 'rgba(99, 102, 241, 0.3)');
    gradient.addColorStop(1, 'rgba(99, 102, 241, 0)');

    new Chart(ctx, {
        type: 'line',
        data: {
            labels: labels,
            datasets: [{
                label: 'Spending',
                data: dailyData,
                borderColor: '#6366f1',
                backgroundColor: gradient,
                borderWidth: 2,
                fill: true,
                tension: 0.4,
                pointRadius: 0,
                pointHoverRadius: 4,
                pointHoverBackgroundColor: '#6366f1',
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            plugins: {
                legend: { display: false },
                tooltip: {
                    backgroundColor: '#1f2937',
                    borderColor: '#374151',
                    borderWidth: 1,
                    titleColor: '#9ca3af',
                    bodyColor: '#f9fafb',
                    callbacks: {
                        title: (items) => 'Day ' + items[0].label,
                        label: (item) => ' {{ auth()->user()->currency ?? "PHP" }} ' + item.raw.toFixed(2),
                    }
                }
            },
            scales: {
                x: {
                    grid: { color: 'rgba(55,65,81,0.5)' },
                    ticks: { color: '#6b7280', font: { size: 10 }, maxTicksLimit: 8 },
                },
                y: {
                    grid: { color: 'rgba(55,65,81,0.5)' },
                    ticks: { color: '#6b7280', font: { size: 10 }, maxTicksLimit: 5 },
                    beginAtZero: true,
                }
            }
        }
    });
});
</script>
@endsection