<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * One weekly working-hours table for every kind of field staff
 * (nurse, lab, driver), keyed by users.id. Orders get a scheduled_at so a
 * booked slot can be counted against the provider's capacity.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('provider_schedules')) {
            Schema::create('provider_schedules', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
                $table->string('provider_type', 20); // nurse | lab | driver
                $table->string('day_of_week');        // Sunday … Saturday
                $table->time('start_time')->default('08:00:00');
                $table->time('end_time')->default('20:00:00');
                $table->boolean('is_available')->default(true);
                $table->unsignedSmallInteger('slot_minutes')->default(60);
                $table->unsignedSmallInteger('slot_capacity')->default(1);
                $table->unsignedSmallInteger('max_daily_orders')->default(6);
                $table->timestamps();

                $table->unique(['user_id', 'day_of_week']);
                $table->index(['provider_type', 'day_of_week']);
            });
        }

        if (!Schema::hasColumn('orders', 'scheduled_at')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->dateTime('scheduled_at')->nullable()->after('status');
                $table->index('scheduled_at');
            });
        }

        // Carry over existing nurse schedules.
        if (Schema::hasTable('nurse_schedules')) {
            $rows = DB::table('nurse_schedules')
                ->join('nurses', 'nurses.id', '=', 'nurse_schedules.nurse_id')
                ->whereNotNull('nurses.user_id')
                ->select('nurses.user_id', 'nurse_schedules.*')
                ->get();

            foreach ($rows as $r) {
                DB::table('provider_schedules')->updateOrInsert(
                    ['user_id' => $r->user_id, 'day_of_week' => $r->day_of_week],
                    [
                        'provider_type' => 'nurse',
                        'start_time' => $r->start_time,
                        'end_time' => $r->end_time,
                        'is_available' => $r->is_available,
                        'slot_minutes' => 60,
                        'slot_capacity' => 1,
                        'max_daily_orders' => $r->max_daily_visits ?? 6,
                        'created_at' => now(),
                        'updated_at' => now(),
                    ]
                );
            }
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('orders', 'scheduled_at')) {
            Schema::table('orders', function (Blueprint $table) {
                $table->dropIndex(['scheduled_at']);
                $table->dropColumn('scheduled_at');
            });
        }
        Schema::dropIfExists('provider_schedules');
    }
};
