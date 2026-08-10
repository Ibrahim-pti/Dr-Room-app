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
        Schema::table('users', function (Blueprint $table) {
            $table->string('name_en')->nullable()->after('name');
            $table->string('name_ar')->nullable()->after('name_en');
        });

        Schema::table('doctors', function (Blueprint $table) {
            $table->string('clinic_name_en')->nullable()->after('clinic_name');
            $table->string('clinic_name_ar')->nullable()->after('clinic_name_en');
            $table->string('address_en')->nullable()->after('address');
            $table->string('address_ar')->nullable()->after('address_en');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['name_en', 'name_ar']);
        });

        Schema::table('doctors', function (Blueprint $table) {
            $table->dropColumn(['clinic_name_en', 'clinic_name_ar', 'address_en', 'address_ar']);
        });
    }
};
