<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Account extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'name', 'account_type', 'balance',
        'currency', 'color', 'icon', 'is_default',
    ];

    protected $casts = [
        'balance' => 'float',
        'is_default' => 'boolean',
    ];

    const TYPES = [
        'cash'        => ['label' => 'Cash',        'icon' => '💵'],
        'bank'        => ['label' => 'Bank Account', 'icon' => '🏦'],
        'e_wallet'    => ['label' => 'E-Wallet',     'icon' => '📱'],
        'credit_card' => ['label' => 'Credit Card',  'icon' => '💳'],
        'savings'     => ['label' => 'Savings',      'icon' => '🏧'],
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function transactions()
    {
        return $this->hasMany(Transaction::class);
    }

    public function getTypeIconAttribute(): string
    {
        return self::TYPES[$this->account_type]['icon'] ?? '💰';
    }

    public function getTypeLabelAttribute(): string
    {
        return self::TYPES[$this->account_type]['label'] ?? 'Account';
    }
}