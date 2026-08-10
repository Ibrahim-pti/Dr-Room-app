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
        Schema::table('users', function (Blueprint $table) {
            $table->boolean('is_blocked')->default(false)->after('is_doctor');
        });

        Schema::table('doctors', function (Blueprint $table) {
            $table->boolean('is_approved')->default(false)->after('bio');
        });

        Schema::table('nurses', function (Blueprint $table) {
            $table->foreignId('user_id')->nullable()->constrained()->onDelete('cascade')->after('id');
            $table->string('specialty')->nullable()->after('user_id');
            $table->string('image_path')->nullable()->after('specialty');
            $table->text('bio')->nullable()->after('image_path');
            $table->string('phone')->nullable()->after('bio');
            $table->boolean('is_approved')->default(false)->after('phone');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('is_blocked');
        });

        Schema::table('doctors', function (Blueprint $table) {
            $table->dropColumn('is_approved');
        });

        Schema::table('nurses', function (Blueprint $table) {
            $table->dropForeign(['user_id']);
            $table->dropColumn(['user_id', 'specialty', 'image_path', 'bio', 'phone', 'is_approved']);
        });
    }
};
