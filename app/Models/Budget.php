<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

class Budget extends Model
{
    protected $fillable = [
        'user_id', 'category_id', 'limit_amount', 'month', 'year', 'alert_sent',
    ];

    protected $casts = [
        'limit_amount' => 'float',
        'alert_sent'   => 'boolean',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    /**
     * Get spent amount — cached for 5 minutes per budget record.
     * Call $budget->forgetSpentCache() after any related transaction change.
     */
    public function getSpentAttribute(): float
    {
        $cacheKey = "budget_spent_{$this->id}";

        return Cache::remember($cacheKey, now()->addMinutes(5), function () {
            return (float) Transaction::whereHas('account', fn($q) => $q->where('user_id', $this->user_id))
                ->where('category_id', $this->category_id)
                ->where('type', 'expense')
                ->whereMonth('date', $this->month)
                ->whereYear('date', $this->year)
                ->sum('amount');
        });
    }

    /**
     * Forget the cached spent amount — call after adding/updating/deleting
     * a transaction that belongs to this budget's category.
     */
    public function forgetSpentCache(): void
    {
        Cache::forget("budget_spent_{$this->id}");
    }

    /**
     * Forget all budget spent caches for a given user (e.g. on bulk import).
     */
    public static function forgetAllCachesForUser(int $userId): void
    {
        $budgets = static::where('user_id', $userId)->get();
        foreach ($budgets as $budget) {
            $budget->forgetSpentCache();
        }
    }

    public function getRemainingAttribute(): float
    {
        return max(0, $this->limit_amount - $this->spent);
    }

    public function getPercentageAttribute(): float
    {
        if ($this->limit_amount == 0) return 0;
        return min(100, round(($this->spent / $this->limit_amount) * 100, 1));
    }

    public function getIsExceededAttribute(): bool
    {
        return $this->spent > $this->limit_amount;
    }

    public function getStatusColorAttribute(): string
    {
        $pct = $this->percentage;
        if ($pct >= 100) return 'red';
        if ($pct >= 80)  return 'amber';
        return 'emerald';
    }
}
