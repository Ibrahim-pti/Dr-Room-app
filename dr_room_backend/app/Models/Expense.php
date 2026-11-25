<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Expense extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'category',
        'amount',
        'currency',
        'expense_date',
        'notes',
        'receipt_path',
        'created_by',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'expense_date' => 'date:Y-m-d',
    ];

    protected $appends = ['receipt_url'];

    public function getReceiptUrlAttribute(): ?string
    {
        if (empty($this->receipt_path)) {
            return null;
        }

        $path = trim((string) $this->receipt_path);
        if (str_starts_with($path, 'http://') || str_starts_with($path, 'https://')) {
            return $path;
        }

        return asset('storage/' . ltrim($path, '/'));
    }

    public function creator()
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
