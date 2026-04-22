<?php

namespace App\Services;

use App\Models\Account;
use App\Models\Budget;
use App\Models\Transaction;
use App\Notifications\BudgetExceededNotification;
use Illuminate\Support\Facades\DB;

class TransactionService
{
    /**
     * Create a transaction and adjust the account balance atomically.
     */
    public function create(array $data, Account $account): Transaction
    {
        return DB::transaction(function () use ($data, $account) {
            if ($data['type'] === 'expense') {
                $protectedTypes = ['cash', 'bank', 'savings', 'e_wallet'];
                if (in_array($account->account_type, $protectedTypes) && $account->balance < $data['amount']) {
                    throw new \RuntimeException(
                        "Insufficient balance. {$account->name} has " .
                        number_format($account->balance, 2) . " available."
                    );
                }
            }

            $tx = Transaction::create($data);
            $this->applyBalance($account, $data['type'], $data['amount'], 'add');
            $this->bustBudgetCache($account->user_id, $data['category_id']);
            return $tx;
        });
    }

    /**
     * Update a transaction, reversing the old balance effect and applying the new one.
     */
    public function update(Transaction $transaction, array $data, Account $newAccount): void
    {
        DB::transaction(function () use ($transaction, $data, $newAccount) {
            $oldUserId     = $transaction->account->user_id;
            $oldCategoryId = $transaction->category_id;

            $this->applyBalance($transaction->account, $transaction->type, $transaction->amount, 'reverse');
            $transaction->update($data);
            $this->applyBalance($newAccount, $data['type'], $data['amount'], 'add');

            $this->bustBudgetCache($oldUserId, $oldCategoryId);
            $this->bustBudgetCache($newAccount->user_id, $data['category_id']);
        });
    }

    /**
     * Delete a transaction and reverse its balance effect.
     */
    public function delete(Transaction $transaction): void
    {
        DB::transaction(function () use ($transaction) {
            $userId     = $transaction->account->user_id;
            $categoryId = $transaction->category_id;

            $this->applyBalance($transaction->account, $transaction->type, $transaction->amount, 'reverse');
            $transaction->delete();
            $this->bustBudgetCache($userId, $categoryId);
        });
    }

    /**
     * Check budget, flash alert, and send email notification if exceeded.
     */
    public function checkBudgetAlert(int $userId, int $categoryId, string $type): void
    {
        if ($type !== 'expense') return;

        $budget = Budget::where('user_id', $userId)
            ->where('category_id', $categoryId)
            ->where('month', now()->month)
            ->where('year',  now()->year)
            ->with('category')
            ->first();

        if ($budget && ! $budget->alert_sent && $budget->is_exceeded) {
            $budget->update(['alert_sent' => true]);

            // Flash in-app alert
            session()->flash('budget_alert', "⚠️ You've exceeded your budget for {$budget->category->name}!");

            // Send email notification
            try {
                $budget->user->notify(new BudgetExceededNotification($budget));
            } catch (\Throwable $e) {
                // Don't break the request if mail fails
                \Illuminate\Support\Facades\Log::warning(
                    "Budget exceeded email failed for user {$userId}: " . $e->getMessage()
                );
            }
        }
    }

    // ── private helpers ──────────────────────────────────────

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

    private function bustBudgetCache(int $userId, int $categoryId): void
    {
        $budget = Budget::where('user_id', $userId)
            ->where('category_id', $categoryId)
            ->where('month', now()->month)
            ->where('year',  now()->year)
            ->first();

        $budget?->forgetSpentCache();
    }
}
