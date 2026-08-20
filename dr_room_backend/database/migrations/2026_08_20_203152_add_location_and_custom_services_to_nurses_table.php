<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('nurses', function (Blueprint $table) {
            $table->string('address')->nullable()->after('city');
            $table->string('address_en')->nullable()->after('address');
            $table->string('address_ar')->nullable()->after('address_en');
            $table->decimal('latitude', 10, 7)->nullable()->after('address_ar');
            $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
            $table->json('custom_services')->nullable()->after('offered_services');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('nurses', function (Blueprint $table) {
            $table->dropColumn([
                'address',
                'address_en',
                'address_ar',
                'latitude',
                'longitude',
                'custom_services',
            ]);
        });
    }
};
