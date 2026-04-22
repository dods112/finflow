<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Transaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'account_id', 'category_id', 'amount', 'type',
        'description', 'notes', 'date', 'receipt_image',
    ];

    protected $casts = [
        'amount' => 'float',
        'date'   => 'date',
    ];

    public function account()
    {
        return $this->belongsTo(Account::class);
    }

    public function category()
    {
        return $this->belongsTo(Category::class);
    }

    public function getSignedAmountAttribute(): float
    {
        return $this->type === 'income' ? $this->amount : -$this->amount;
    }

    public function getFormattedAmountAttribute(): string
    {
        $sign = $this->type === 'income' ? '+' : '-';
        return $sign . number_format($this->amount, 2);
    }

    public function scopeForUser($query, $userId)
    {
        return $query->whereHas('account', fn($q) => $q->where('user_id', $userId));
    }

    public function scopeThisMonth($query)
    {
        return $query->whereMonth('date', now()->month)
                     ->whereYear('date', now()->year);
    }

    public function scopeThisWeek($query)
    {
        return $query->whereBetween('date', [now()->startOfWeek(), now()->endOfWeek()]);
    }
}