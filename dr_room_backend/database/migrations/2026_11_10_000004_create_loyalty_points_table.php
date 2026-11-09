<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('users', 'loyalty_points')) {
            Schema::table('users', function (Blueprint $table) {
                $table->integer('loyalty_points')->default(0)->after('status');
            });
        }

        Schema::create('loyalty_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->integer('points'); // positive for earned, negative for redeemed
            $table->string('type')->default('earned_order'); // earned_order, redeemed_coupon, bonus, admin_adjustment
            $table->string('description')->nullable();
            $table->foreignId('order_id')->nullable()->constrained('orders')->nullOnDelete();
            $table->timestamps();

            $table->index(['user_id', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('loyalty_transactions');
        if (Schema::hasColumn('users', 'loyalty_points')) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropColumn('loyalty_points');
            });
        }
    }
};

