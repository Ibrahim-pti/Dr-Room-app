<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Transaction extends Model
{
    protected $guarded = [];

    protected $casts = [
        'amount'  => 'decimal:2',
        'meta'    => 'array',
        'paid_at' => 'datetime',
    ];

    public const STATUS_LABELS = [
        'pending'   => 'چاوەڕوان',
        'completed' => 'سەرکەوتوو',
        'failed'    => 'شکستخواردوو',
        'refunded'  => 'گەڕێندراوە',
    ];

    public const METHOD_LABELS = [
        'cash'    => 'کاش',
        'card'    => 'کارت',
        'wallet'  => 'جزدان',
        'fib'     => 'FIB',
        'fastpay' => 'FastPay',
    ];

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function payable()
    {
        return $this->morphTo();
    }

    public function scopeCompleted($query)
    {
        return $query->where('status', 'completed');
    }
}
