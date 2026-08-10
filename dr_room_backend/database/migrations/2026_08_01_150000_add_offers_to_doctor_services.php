<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('doctor_services', function (Blueprint $table) {
            // The pre-discount price. When set and higher than `price`, the app
            // shows it struck through and works out the percentage itself.
            $table->decimal('old_price', 8, 2)->nullable()->after('price');
            $table->date('discount_until')->nullable()->after('old_price');
            $table->boolean('is_active')->default(true)->after('discount_until');
        });
    }

    public function down(): void
    {
        Schema::table('doctor_services', function (Blueprint $table) {
            $table->dropColumn(['old_price', 'discount_until', 'is_active']);
        });
    }
};
