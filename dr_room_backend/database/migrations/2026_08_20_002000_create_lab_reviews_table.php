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
        // Add views_count, rating, and total_reviews to labs table if missing
        Schema::table('labs', function (Blueprint $table) {
            if (!Schema::hasColumn('labs', 'views_count')) {
                $table->unsignedBigInteger('views_count')->default(0)->after('is_approved');
            }
            if (!Schema::hasColumn('labs', 'total_reviews')) {
                $table->unsignedInteger('total_reviews')->default(0)->after('rating');
            }
        });

        // Create lab_reviews table
        if (!Schema::hasTable('lab_reviews')) {
            Schema::create('lab_reviews', function (Blueprint $table) {
                $table->id();
                $table->foreignId('lab_id')->constrained('labs')->cascadeOnDelete();
                $table->foreignId('patient_id')->constrained('users')->cascadeOnDelete();
                $table->unsignedTinyInteger('rating'); // 1-5
                $table->text('comment')->nullable();
                $table->timestamps();

                $table->unique(['lab_id', 'patient_id']);
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('lab_reviews');

        Schema::table('labs', function (Blueprint $table) {
            if (Schema::hasColumn('labs', 'views_count')) {
                $table->dropColumn('views_count');
            }
            if (Schema::hasColumn('labs', 'total_reviews')) {
                $table->dropColumn('total_reviews');
            }
        });
    }
};
