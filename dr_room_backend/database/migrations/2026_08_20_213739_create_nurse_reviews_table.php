<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('nurse_reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('nurse_id')->constrained()->onDelete('cascade');
            $table->foreignId('patient_id')->constrained('users')->onDelete('cascade');
            $table->unsignedTinyInteger('rating'); // 1..5
            $table->text('comment')->nullable();
            $table->timestamps();

            // One review per patient per nurse — editing replaces the old one.
            $table->unique(['nurse_id', 'patient_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('nurse_reviews');
    }
};
