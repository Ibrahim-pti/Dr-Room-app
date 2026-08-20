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
        Schema::table('nurses', function (Blueprint $table) {
            $table->json('offered_services')->nullable(); // e.g. ['injection','cannula','dressing','checkup']
            $table->boolean('is_available')->default(true);
            $table->decimal('fee', 8, 2)->nullable(); // base fee
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('nurses', function (Blueprint $table) {
            $table->dropColumn(['offered_services', 'is_available', 'fee']);
        });
    }
};
