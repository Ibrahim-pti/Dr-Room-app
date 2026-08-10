<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('role')->default('patient')->after('password');
            $table->string('status')->default('approved')->after('role');
        });

        // Migrate data based on existing columns
        DB::table('users')->where('is_admin', true)->update(['role' => 'admin']);
        DB::table('users')->where('is_doctor', true)->update(['role' => 'doctor']);
        DB::table('users')->where('is_nurse', true)->update(['role' => 'nurse']);
        DB::table('users')->where('is_blocked', true)->update(['status' => 'blocked']);

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['is_admin', 'is_doctor', 'is_nurse', 'is_blocked']);
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('is_admin')->default(false);
            $table->boolean('is_doctor')->default(false);
            $table->boolean('is_nurse')->default(false);
            $table->boolean('is_blocked')->default(false);
        });

        DB::table('users')->where('role', 'admin')->update(['is_admin' => true]);
        DB::table('users')->where('role', 'doctor')->update(['is_doctor' => true]);
        DB::table('users')->where('role', 'nurse')->update(['is_nurse' => true]);
        DB::table('users')->where('status', 'blocked')->update(['is_blocked' => true]);

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['role', 'status']);
        });
    }
};
