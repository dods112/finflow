<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class User extends Authenticatable
{
    use HasFactory, Notifiable;

    protected $fillable = [
        'name', 'email', 'password', 'avatar',
        'currency', 'timezone', 'dark_mode',
    ];

    protected $hidden = ['password', 'remember_token'];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
        'dark_mode' => 'boolean',
    ];

    public function accounts()
    {
        return $this->hasMany(Account::class);
    }

    public function budgets()
    {
        return $this->hasMany(Budget::class);
    }

    public function chatLogs()
    {
        return $this->hasMany(ChatLog::class);
    }

    public function transactions()
    {
        return $this->hasManyThrough(Transaction::class, Account::class);
    }

    public function getTotalBalanceAttribute(): float
    {
        return $this->accounts()->sum('balance');
    }

    public function getDefaultAccountAttribute()
    {
        return $this->accounts()->where('is_default', true)->first()
            ?? $this->accounts()->first();
    }
}