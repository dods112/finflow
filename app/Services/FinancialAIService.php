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
