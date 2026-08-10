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
        Schema::table('labs', function (Blueprint $table) {
            $table->text('about_us_en')->nullable();
            $table->text('about_us_ar')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('labs', function (Blueprint $table) {
            $table->dropColumn([
                'license_number',
                'about_us',
                'home_sample_collection',
                'equipment_level',
                'about_us_en',
                'about_us_ar',
            ]);
        });
    }
};
