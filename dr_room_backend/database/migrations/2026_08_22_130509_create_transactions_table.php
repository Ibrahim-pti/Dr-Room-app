<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->string('reference')->unique();          // txn_xxx shown to the user
            $table->string('intent_id')->nullable()->index();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();

            $table->decimal('amount', 12, 2);
            $table->string('currency', 8)->default('IQD');
            $table->string('status')->default('pending');    // pending | completed | failed | refunded
            $table->string('method')->default('cash');       // cash | card | wallet | fib | fastpay
            $table->string('description')->nullable();

            // What was paid for, e.g. App\Models\Order #12 or an Appointment.
            $table->string('payable_type')->nullable();
            $table->unsignedBigInteger('payable_id')->nullable();

            $table->json('meta')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->timestamps();

            $table->index(['payable_type', 'payable_id']);
            $table->index(['status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};
