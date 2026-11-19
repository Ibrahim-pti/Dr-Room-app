<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('feedback_surveys', function (Blueprint $table) {
            $table->id();
            $table->string('title');
            $table->string('title_kmr')->nullable();
            $table->string('title_ar')->nullable();
            $table->string('title_en')->nullable();

            $table->string('rating_question');
            $table->string('rating_question_kmr')->nullable();
            $table->string('rating_question_ar')->nullable();
            $table->string('rating_question_en')->nullable();

            $table->string('suggestion_question');
            $table->string('suggestion_question_kmr')->nullable();
            $table->string('suggestion_question_ar')->nullable();
            $table->string('suggestion_question_en')->nullable();

            $table->boolean('is_active')->default(true);
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
        });

        Schema::create('feedback_responses', function (Blueprint $table) {
            $table->id();
            $table->foreignId('survey_id')->constrained('feedback_surveys')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained('users')->cascadeOnDelete();
            $table->unsignedTinyInteger('rating');
            $table->string('is_satisfied', 20)->nullable(); // satisfied | neutral | unsatisfied
            $table->text('suggestion')->nullable();
            $table->string('locale', 10)->nullable();
            $table->timestamps();

            $table->unique(['survey_id', 'user_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('feedback_responses');
        Schema::dropIfExists('feedback_surveys');
    }
};
