<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Coupon extends Model
{
    use HasFactory;

    protected $fillable = [
        'code',
        'title',
        'description',
        'discount_type',
        'discount_value',
        'min_order_amount',
        'max_discount_amount',
        'usage_limit',
        'used_count',
        'starts_at',
        'expires_at',
        'is_active',
    ];

    protected $casts = [
        'discount_value' => 'decimal:2',
        'min_order_amount' => 'decimal:2',
        'max_discount_amount' => 'decimal:2',
        'usage_limit' => 'integer',
        'used_count' => 'integer',
        'starts_at' => 'datetime',
        'expires_at' => 'datetime',
        'is_active' => 'boolean',
    ];

    public function isValidFor(float $orderAmount): array
    {
        if (!$this->is_active) {
            return ['valid' => false, 'message' => 'کۆدەکە چالاک نییە'];
        }

        if ($this->starts_at && $this->starts_at->isFuture()) {
            return ['valid' => false, 'message' => 'کاتی بەکارهێنانی ئەم کۆدە هێشتا دەستی پێنەکردووە'];
        }

        if ($this->expires_at && $this->expires_at->isPast()) {
            return ['valid' => false, 'message' => 'بەرواری ئەم کۆدە بەسەرچووە'];
        }

        if ($this->usage_limit !== null && $this->used_count >= $this->usage_limit) {
            return ['valid' => false, 'message' => 'ژمارەی ڕێگەپێدراوی بەکارهێنانی ئەم کۆدە تەواو بووە'];
        }

        if ($orderAmount < $this->min_order_amount) {
            return [
                'valid' => false,
                'message' => 'کەمترین بڕی داواکاری بۆ ئەم کۆدە بریتییە لە ' . number_format($this->min_order_amount) . ' دینار'
            ];
        }

        // Calculate discount
        $discount = 0.0;
        if ($this->discount_type === 'percentage') {
            $discount = ($orderAmount * $this->discount_value) / 100.0;
            if ($this->max_discount_amount !== null && $discount > $this->max_discount_amount) {
                $discount = (float) $this->max_discount_amount;
            }
        } else {
            $discount = (float) $this->discount_value;
        }

        if ($discount > $orderAmount) {
            $discount = $orderAmount;
        }

        return [
            'valid' => true,
            'discount' => round($discount, 2),
            'final_amount' => round(max(0, $orderAmount - $discount), 2),
        ];
    }
}

