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
        Schema::table('nurse_appointments', function (Blueprint $table) {
            $table->string('address')->nullable();
            $table->string('phone')->nullable();
            $table->decimal('latitude', 10, 8)->nullable();
            $table->decimal('longitude', 11, 8)->nullable();
            $table->json('services')->nullable(); // Store the array of services like ['injection', 'cannula']
            
            // If the patient can request without a specific nurse, nurse_id might need to be nullable.
            // But since it's already foreignId, we will change it to nullable if needed.
            // Let's make nurse_id nullable in case they just request the clinic generally.
        });
        
        // Make nurse_id nullable
        Schema::table('nurse_appointments', function (Blueprint $table) {
            $table->unsignedBigInteger('nurse_id')->nullable()->change();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('nurse_appointments', function (Blueprint $table) {
            $table->dropColumn(['address', 'phone', 'latitude', 'longitude', 'services']);
        });
        
        Schema::table('nurse_appointments', function (Blueprint $table) {
            $table->unsignedBigInteger('nurse_id')->nullable(false)->change();
        });
    }
};
