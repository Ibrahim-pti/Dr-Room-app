<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    private array $tables = ['doctor_reviews', 'lab_reviews', 'nurse_reviews', 'pharmacy_reviews'];

    public function up(): void
    {
        foreach ($this->tables as $name) {
            if (!Schema::hasTable($name) || Schema::hasColumn($name, 'is_hidden')) {
                continue;
            }

            Schema::table($name, function (Blueprint $table) {
                // Hidden reviews stay in the table so the trail is not lost,
                // but drop out of the public listings and rating averages.
                $table->boolean('is_hidden')->default(false)->after('comment');
                $table->string('hidden_reason')->nullable()->after('is_hidden');
                $table->timestamp('hidden_at')->nullable()->after('hidden_reason');
            });
        }
    }

    public function down(): void
    {
        foreach ($this->tables as $name) {
            if (!Schema::hasTable($name) || !Schema::hasColumn($name, 'is_hidden')) {
                continue;
            }
            Schema::table($name, fn (Blueprint $t) => $t->dropColumn(['is_hidden', 'hidden_reason', 'hidden_at']));
        }
    }
};
