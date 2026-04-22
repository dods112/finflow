<?php

namespace App\Http\Controllers;

use App\Models\Transaction;
use App\Models\Budget;
use App\Models\Category;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    public function index()
    {
        $user = Auth::user();
        $now  = now();

        // Total balance across all accounts
        $totalBalance = $user->accounts()->sum('balance');

        // This month income/expense
        $monthlyIncome  = Transaction::forUser($user->id)->thisMonth()->where('type', 'income')->sum('amount');
        $monthlyExpense = Transaction::forUser($user->id)->thisMonth()->where('type', 'expense')->sum('amount');

        // Recent transactions (last 10)
        $recentTransactions = Transaction::forUser($user->id)
            ->with(['category', 'account'])
            ->orderByDesc('date')
            ->orderByDesc('id')
            ->limit(10)
            ->get();

        // Budget overview
        $budgets = Budget::where('user_id', $user->id)
            ->where('month', $now->month)
            ->where('year', $now->year)
            ->with('category')
            ->get();

        // Spending by category (this month) for chart
        $spendingByCategory = Transaction::forUser($user->id)
            ->thisMonth()
            ->where('type', 'expense')
            ->with('category')
            ->select('category_id', DB::raw('SUM(amount) as total'))
            ->groupBy('category_id')
            ->get()
            ->map(fn($t) => [
                'name'   => $t->category->name ?? 'Unknown',
                'icon'   => $t->category->icon ?? '💰',
                'color'  => $t->category->color ?? '#6366f1',
                'total'  => $t->total,
            ]);

        // Daily spending last 7 days for sparkline
        $dailySpending = Transaction::forUser($user->id)
            ->where('type', 'expense')
            ->whereBetween('date', [now()->subDays(6), now()])
            ->select(DB::raw('DATE(date) as day'), DB::raw('SUM(amount) as total'))
            ->groupBy('day')
            ->orderBy('day')
            ->pluck('total', 'day');

        $accounts = $user->accounts()->orderByDesc('is_default')->get();

        // AI Insight (cached or latest)
        $latestInsight = $user->chatLogs()
            ->where('message', 'LIKE', '%auto_insight%')
            ->latest('created_at')
            ->first();

        return view('dashboard.index', compact(
            'user', 'totalBalance', 'monthlyIncome', 'monthlyExpense',
            'recentTransactions', 'budgets', 'spendingByCategory',
            'dailySpending', 'accounts', 'latestInsight'
        ));
    }
}