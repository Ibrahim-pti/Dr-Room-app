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
        Schema::table('doctors', function (Blueprint $table) {
            $table->text('bio_en')->nullable();
            $table->text('bio_ar')->nullable();
            $table->string('specialty_en')->nullable();
            $table->string('specialty_ar')->nullable();
        });

        Schema::table('nurses', function (Blueprint $table) {
            $table->text('bio_en')->nullable();
            $table->text('bio_ar')->nullable();
            $table->string('specialty_en')->nullable();
            $table->string('specialty_ar')->nullable();
        });

        Schema::table('pharmacies', function (Blueprint $table) {
            $table->text('bio_en')->nullable();
            $table->text('bio_ar')->nullable();
            $table->string('location_en')->nullable();
            $table->string('location_ar')->nullable();
        });

        Schema::table('labs', function (Blueprint $table) {
            $table->text('bio_en')->nullable();
            $table->text('bio_ar')->nullable();
            $table->string('location_en')->nullable();
            $table->string('location_ar')->nullable();
        });

        Schema::table('x_rays', function (Blueprint $table) {
            $table->text('bio_en')->nullable();
            $table->text('bio_ar')->nullable();
            $table->string('location_en')->nullable();
            $table->string('location_ar')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('doctors', function (Blueprint $table) {
            $table->dropColumn(['bio_en', 'bio_ar', 'specialty_en', 'specialty_ar']);
        });

        Schema::table('nurses', function (Blueprint $table) {
            $table->dropColumn(['bio_en', 'bio_ar', 'specialty_en', 'specialty_ar']);
        });

        Schema::table('pharmacies', function (Blueprint $table) {
            $table->dropColumn(['bio_en', 'bio_ar', 'location_en', 'location_ar']);
        });

        Schema::table('labs', function (Blueprint $table) {
            $table->dropColumn(['bio_en', 'bio_ar', 'location_en', 'location_ar']);
        });

        Schema::table('x_rays', function (Blueprint $table) {
            $table->dropColumn(['bio_en', 'bio_ar', 'location_en', 'location_ar']);
        });
    }
};
