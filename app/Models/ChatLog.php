<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class ChatLog extends Model
{
    public $timestamps = false;

    protected $fillable = [
        'user_id', 'message', 'response', 'context', 'tokens_used',
    ];

    protected $casts = [
    'context'    => 'array',
    'created_at' => 'datetime',
];

protected function context(): \Illuminate\Database\Eloquent\Casts\Attribute
{
    return \Illuminate\Database\Eloquent\Casts\Attribute::make(
        get: fn ($value) => $value ? json_decode($value, true) : null,
        set: fn ($value) => $value ? json_encode($value) : null,
    );
}

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}