<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
<style>
    body { font-family: DejaVu Sans, sans-serif; font-size: 11px; color: #1a1a2e; margin: 0; padding: 20px; }
    h1 { font-size: 20px; color: #4f46e5; margin-bottom: 4px; }
    .meta { color: #888; font-size: 10px; margin-bottom: 20px; }
    .summary { background: #f5f5ff; border-radius: 8px; padding: 12px 16px; margin-bottom: 20px; }
    .summary table { width: 100%; border-collapse: collapse; }
    .summary td { padding: 4px 8px; font-size: 11px; }
    table.transactions { width: 100%; border-collapse: collapse; }
    table.transactions th { background: #4f46e5; color: white; padding: 8px 10px; text-align: left; font-size: 10px; }
    table.transactions td { padding: 7px 10px; border-bottom: 1px solid #f0f0f0; font-size: 10px; }
    table.transactions tr:nth-child(even) td { background: #f9f9ff; }
    .income { color: #059669; font-weight: bold; }
    .expense { color: #dc2626; font-weight: bold; }
    .label { color: #6b7280; }
</style>
</head>
<body>
<h1>FinFlow Report</h1>
<p class="meta">{{ $user->name }} &middot; {{ $user->email }} &middot; Generated {{ now()->format('M d, Y H:i') }}</p>

<div class="summary">
    <table>
        <tr>
            <td class="label">Total Income:</td>
            <td class="income">{{ $user->currency }} {{ number_format($totalIncome, 2) }}</td>
            <td class="label">Total Expenses:</td>
            <td class="expense">{{ $user->currency }} {{ number_format($totalExpense, 2) }}</td>
            <td class="label">Net Savings:</td>
            <td style="font-weight:bold">{{ $user->currency }} {{ number_format($totalIncome - $totalExpense, 2) }}</td>
        </tr>
    </table>
</div>

<table class="transactions">
    <thead>
        <tr>
            <th>Date</th>
            <th>Description</th>
            <th>Category</th>
            <th>Account</th>
            <th>Type</th>
            <th>Amount</th>
        </tr>
    </thead>
    <tbody>
        @foreach($transactions as $t)
        <tr>
            <td>{{ $t->date->format('M d, Y') }}</td>
            <td>{{ $t->description ?: '—' }}</td>
            <td>{{ $t->category->name }}</td>
            <td>{{ $t->account->name }}</td>
            <td class="{{ $t->type }}">{{ ucfirst($t->type) }}</td>
            <td class="{{ $t->type }}">{{ $t->formatted_amount }}</td>
        </tr>
        @endforeach
    </tbody>
</table>
</body>
</html>