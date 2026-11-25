<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (!Schema::hasColumn('orders', 'service_fee')) {
                $table->decimal('service_fee', 10, 2)->default(0)->after('extra_fee');
            }
        });

        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'gender')) {
                $table->string('gender', 20)->nullable()->after('profile_image');
            }
            if (!Schema::hasColumn('users', 'dob')) {
                $table->string('dob', 40)->nullable()->after('gender');
            }
            if (!Schema::hasColumn('users', 'blood_type')) {
                $table->string('blood_type', 10)->nullable()->after('dob');
            }
        });
    }

    public function down(): void
    {
        Schema::table('orders', function (Blueprint $table) {
            if (Schema::hasColumn('orders', 'service_fee')) {
                $table->dropColumn('service_fee');
            }
        });

        Schema::table('users', function (Blueprint $table) {
            foreach (['blood_type', 'dob', 'gender'] as $col) {
                if (Schema::hasColumn('users', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};
