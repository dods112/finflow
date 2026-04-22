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

    public function user()
    {
        return $this->belongsTo(User::class);
    }
}