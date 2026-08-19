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
            if (!Schema::hasColumn('labs', 'opening_hours')) {
                $table->string('opening_hours')->nullable()->default('08:00 AM - 10:00 PM');
            }
            if (!Schema::hasColumn('labs', 'youtube_url')) {
                $table->string('youtube_url')->nullable();
            }
            if (!Schema::hasColumn('labs', 'discount')) {
                $table->integer('discount')->nullable();
            }
        });

        Schema::table('lab_tests', function (Blueprint $table) {
            if (!Schema::hasColumn('lab_tests', 'discount')) {
                $table->integer('discount')->nullable();
            }
            if (!Schema::hasColumn('lab_tests', 'name_en')) {
                $table->string('name_en')->nullable();
            }
            if (!Schema::hasColumn('lab_tests', 'name_ar')) {
                $table->string('name_ar')->nullable();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('labs', function (Blueprint $table) {
            $cols = [];
            if (Schema::hasColumn('labs', 'opening_hours')) $cols[] = 'opening_hours';
            if (Schema::hasColumn('labs', 'youtube_url')) $cols[] = 'youtube_url';
            if (Schema::hasColumn('labs', 'discount')) $cols[] = 'discount';
            if (!empty($cols)) $table->dropColumn($cols);
        });

        Schema::table('lab_tests', function (Blueprint $table) {
            $cols = [];
            if (Schema::hasColumn('lab_tests', 'discount')) $cols[] = 'discount';
            if (Schema::hasColumn('lab_tests', 'name_en')) $cols[] = 'name_en';
            if (Schema::hasColumn('lab_tests', 'name_ar')) $cols[] = 'name_ar';
            if (!empty($cols)) $table->dropColumn($cols);
        });
    }
};
