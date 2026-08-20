<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('nurses', function (Blueprint $table) {
            $table->decimal('rating', 3, 1)->default(0)->after('experience_years');
            $table->unsignedInteger('total_reviews')->default(0)->after('rating');
        });
    }

    public function down(): void
    {
        Schema::table('nurses', function (Blueprint $table) {
            $table->dropColumn(['rating', 'total_reviews']);
        });
    }
};
