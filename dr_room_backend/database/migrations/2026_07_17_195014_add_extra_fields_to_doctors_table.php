<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('doctors', function (Blueprint $table) {
            $table->decimal('rating', 3, 1)->default(0)->after('bio');
            $table->unsignedInteger('total_reviews')->default(0)->after('rating');
            $table->decimal('consultation_fee', 8, 2)->nullable()->after('total_reviews');
            $table->unsignedInteger('experience_years')->nullable()->after('consultation_fee');
            $table->string('phone')->nullable()->after('experience_years');
            $table->json('available_days')->nullable()->after('phone');
        });
    }

    public function down(): void
    {
        Schema::table('doctors', function (Blueprint $table) {
            $table->dropColumn(['rating', 'total_reviews', 'consultation_fee', 'experience_years', 'phone', 'available_days']);
        });
    }
};
