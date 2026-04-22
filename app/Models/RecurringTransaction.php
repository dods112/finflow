<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class RecurringTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'account_id', 'category_id', 'amount',
        'type', 'description', 'frequency', 'start_date',
        'next_due', 'end_date', 'is_active',
    ];

    protected $casts = [
        'amount'     => 'float',
        'start_date' => 'date',
        'next_due'   => 'date',
        'end_date'   => 'date',
        'is_active'  => 'boolean',
    ];

    public function user()     { return $this->belongsTo(User::class); }
    public function account()  { return $this->belongsTo(Account::class); }
    public function category() { return $this->belongsTo(Category::class); }

    public function getNextDueLabelAttribute(): string
    {
        if ($this->next_due->isToday())    return 'Due today';
        if ($this->next_due->isPast())     return 'Overdue';
        if ($this->next_due->isTomorrow()) return 'Due tomorrow';
        return 'Due ' . $this->next_due->format('M d');
    }

    public function advanceNextDue(): void
    {
        $this->next_due = match ($this->frequency) {
            'daily'   => $this->next_due->addDay(),
            'weekly'  => $this->next_due->addWeek(),
            'monthly' => $this->next_due->addMonth(),
            'yearly'  => $this->next_due->addYear(),
        };

        if ($this->end_date && $this->next_due->gt($this->end_date)) {
            $this->is_active = false;
        }

        $this->save();
    }
}
