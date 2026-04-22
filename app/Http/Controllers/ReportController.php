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
