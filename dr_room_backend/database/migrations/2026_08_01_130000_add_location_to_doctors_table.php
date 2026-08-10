<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('doctors', function (Blueprint $table) {
            $table->string('clinic_name')->nullable()->after('phone');
            $table->string('address')->nullable()->after('clinic_name');
            $table->decimal('latitude', 10, 7)->nullable()->after('address');
            $table->decimal('longitude', 10, 7)->nullable()->after('latitude');
        });

        // The profile form has always written the phone to `users`; copy it
        // across so the column the API actually exposes stops being empty.
        DB::table('doctors')->whereNull('phone')->update([
            'phone' => DB::raw('(SELECT users.phone FROM users WHERE users.id = doctors.user_id)'),
        ]);
    }

    public function down(): void
    {
        Schema::table('doctors', function (Blueprint $table) {
            $table->dropColumn(['clinic_name', 'address', 'latitude', 'longitude']);
        });
    }
};
