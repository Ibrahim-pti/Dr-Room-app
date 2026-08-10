<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('doctor_schedules', function (Blueprint $table) {
            // How long one appointment takes. Was a hard-coded 30 in the app.
            $table->unsignedSmallInteger('slot_minutes')->default(30)->after('end_time');
        });
    }

    public function down(): void
    {
        Schema::table('doctor_schedules', function (Blueprint $table) {
            $table->dropColumn('slot_minutes');
        });
    }
};
