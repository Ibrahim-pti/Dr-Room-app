<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('recruitment_options', 'role_scope')) {
            Schema::table('recruitment_options', function (Blueprint $table) {
                $table->string('role_scope', 30)->default('all')->after('type')->index();
            });
        }

        // Backfill seeded defaults to appropriate tracks
        $phlebotomistEdu = ['diploma_lab', 'bsc_lab'];
        $nurseEdu = ['diploma_nursing', 'bsc_nursing', 'high_school_course'];

        $phlebotomistSkills = ['venipuncture', 'pediatric_draw', 'cold_chain'];
        $nurseSkills = ['cannula_iv', 'injections', 'wound_care', 'vital_signs', 'pharma_handling'];

        DB::table('recruitment_options')
            ->where('type', 'education')
            ->whereIn('option_key', $phlebotomistEdu)
            ->update(['role_scope' => 'phlebotomist']);

        DB::table('recruitment_options')
            ->where('type', 'education')
            ->whereIn('option_key', $nurseEdu)
            ->update(['role_scope' => 'mobile_nurse']);

        DB::table('recruitment_options')
            ->where('type', 'skill')
            ->whereIn('option_key', $phlebotomistSkills)
            ->update(['role_scope' => 'phlebotomist']);

        DB::table('recruitment_options')
            ->where('type', 'skill')
            ->whereIn('option_key', $nurseSkills)
            ->update(['role_scope' => 'mobile_nurse']);
    }

    public function down(): void
    {
        if (Schema::hasColumn('recruitment_options', 'role_scope')) {
            Schema::table('recruitment_options', function (Blueprint $table) {
                $table->dropColumn('role_scope');
            });
        }
    }
};
