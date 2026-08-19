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
        Schema::table('lab_tests', function (Blueprint $table) {
            if (!Schema::hasColumn('lab_tests', 'description_ar')) {
                $table->text('description_ar')->nullable()->after('description');
            }
            if (!Schema::hasColumn('lab_tests', 'description_en')) {
                $table->text('description_en')->nullable()->after('description_ar');
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('lab_tests', function (Blueprint $table) {
            if (Schema::hasColumn('lab_tests', 'description_ar')) {
                $table->dropColumn('description_ar');
            }
            if (Schema::hasColumn('lab_tests', 'description_en')) {
                $table->dropColumn('description_en');
            }
        });
    }
};
