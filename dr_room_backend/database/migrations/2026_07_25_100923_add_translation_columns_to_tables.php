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
        Schema::table('articles', function (Blueprint $table) {
            $table->string('title_en')->nullable();
            $table->string('title_ar')->nullable();
            $table->longText('content_en')->nullable();
            $table->longText('content_ar')->nullable();
        });

        Schema::table('app_notifications', function (Blueprint $table) {
            $table->string('title_en')->nullable();
            $table->string('title_ar')->nullable();
            $table->text('message_en')->nullable();
            $table->text('message_ar')->nullable();
        });

        Schema::table('banners', function (Blueprint $table) {
            $table->string('title_en')->nullable();
            $table->string('title_ar')->nullable();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('tables', function (Blueprint $table) {
            //
        });
    }
};
