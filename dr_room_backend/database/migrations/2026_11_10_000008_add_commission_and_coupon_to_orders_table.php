<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->string('coupon_code')->nullable()->after('total_price');
            $table->decimal('discount_amount', 10, 2)->default(0)->after('coupon_code');
            $table->decimal('commission_rate', 5, 2)->default(0)->after('discount_amount');
            $table->decimal('commission_amount', 10, 2)->default(0)->after('commission_rate');
            $table->decimal('provider_net_amount', 10, 2)->default(0)->after('commission_amount');
            $table->integer('loyalty_points_earned')->default(0)->after('provider_net_amount');
            $table->integer('loyalty_points_spent')->default(0)->after('loyalty_points_earned');
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            $table->dropColumn([
                'coupon_code',
                'discount_amount',
                'commission_rate',
                'commission_amount',
                'provider_net_amount',
                'loyalty_points_earned',
                'loyalty_points_spent',
            ]);
        });
    }
};

