<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nurse_schedules', function (Blueprint $table) {
            $table->id();
            $table->foreignId('nurse_id')->constrained('nurses')->cascadeOnDelete();
            $table->string('day_of_week'); // Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday
            $table->time('start_time')->default('08:00:00');
            $table->time('end_time')->default('20:00:00');
            $table->boolean('is_available')->default(true);
            $table->integer('max_daily_visits')->default(6);
            $table->timestamps();

            $table->unique(['nurse_id', 'day_of_week']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nurse_schedules');
    }
};
