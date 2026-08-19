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
            if (!Schema::hasColumn('labs', 'about_us')) {
                $table->text('about_us')->nullable();
            }
            if (!Schema::hasColumn('labs', 'home_sample_collection')) {
                $table->boolean('home_sample_collection')->default(false);
            }
            if (!Schema::hasColumn('labs', 'license_number')) {
                $table->string('license_number')->nullable();
            }
            if (!Schema::hasColumn('labs', 'equipment_level')) {
                $table->string('equipment_level')->nullable();
            }
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('labs', function (Blueprint $table) {
            $columnsToDrop = [];
            if (Schema::hasColumn('labs', 'about_us')) $columnsToDrop[] = 'about_us';
            if (Schema::hasColumn('labs', 'home_sample_collection')) $columnsToDrop[] = 'home_sample_collection';
            if (Schema::hasColumn('labs', 'license_number')) $columnsToDrop[] = 'license_number';
            if (Schema::hasColumn('labs', 'equipment_level')) $columnsToDrop[] = 'equipment_level';
            
            if (!empty($columnsToDrop)) {
                $table->dropColumn($columnsToDrop);
            }
        });
    }
};
