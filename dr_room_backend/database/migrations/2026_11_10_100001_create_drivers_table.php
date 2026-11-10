<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('drivers')) {
            Schema::create('drivers', function (Blueprint $table) {
                $table->id();
                $table->foreignId('user_id')->unique()->constrained('users')->onDelete('cascade');
                $table->string('city')->default('هەولێر');
                $table->string('vehicle_type')->default('motorcycle'); // motorcycle, car, refrigerated_van
                $table->string('plate_number')->nullable();
                $table->string('service_scope')->default('both'); // pharmacy, lab_sample, both
                $table->string('duty_status')->default('offline'); // offline, available, busy
                $table->decimal('current_lat', 10, 7)->nullable();
                $table->decimal('current_lng', 10, 7)->nullable();
                $table->timestamp('last_location_at')->nullable();
                $table->unsignedInteger('completed_deliveries')->default(0);
                $table->decimal('total_earnings', 12, 2)->default(0);
                $table->decimal('rating', 3, 2)->default(5.00);
                $table->text('notes')->nullable();
                $table->timestamps();
            });
        }
    }

    public function down(): void
    {
        Schema::dropIfExists('drivers');
    }
};
