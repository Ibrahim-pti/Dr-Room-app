<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasTable('drivers')) {
            return;
        }

        Schema::table('drivers', function (Blueprint $table) {
            if (!Schema::hasColumn('drivers', 'applicant_role')) {
                $table->string('applicant_role', 40)->default('phlebotomist')->after('user_id');
            }
            if (!Schema::hasColumn('drivers', 'gender')) {
                $table->string('gender', 20)->nullable()->after('city');
            }
            if (!Schema::hasColumn('drivers', 'education_level')) {
                $table->string('education_level', 80)->nullable()->after('gender');
            }
            if (!Schema::hasColumn('drivers', 'experience_years')) {
                $table->unsignedInteger('experience_years')->nullable()->after('education_level');
            }
            if (!Schema::hasColumn('drivers', 'clinical_skills')) {
                $table->json('clinical_skills')->nullable()->after('experience_years');
            }
            if (!Schema::hasColumn('drivers', 'service_areas')) {
                $table->string('service_areas', 255)->nullable()->after('clinical_skills');
            }
            if (!Schema::hasColumn('drivers', 'availability_shift')) {
                $table->string('availability_shift', 40)->nullable()->after('service_areas');
            }
            if (!Schema::hasColumn('drivers', 'work_days')) {
                $table->string('work_days', 40)->nullable()->after('availability_shift');
            }
            if (!Schema::hasColumn('drivers', 'willing_to_travel')) {
                $table->boolean('willing_to_travel')->default(true)->after('work_days');
            }
            if (!Schema::hasColumn('drivers', 'has_private_car')) {
                $table->boolean('has_private_car')->default(false)->after('willing_to_travel');
            }
            if (!Schema::hasColumn('drivers', 'id_document_path')) {
                $table->string('id_document_path')->nullable()->after('has_private_car');
            }
            if (!Schema::hasColumn('drivers', 'certificate_path')) {
                $table->string('certificate_path')->nullable()->after('id_document_path');
            }
            if (!Schema::hasColumn('drivers', 'license_path')) {
                $table->string('license_path')->nullable()->after('certificate_path');
            }
            if (!Schema::hasColumn('drivers', 'cv_path')) {
                $table->string('cv_path')->nullable()->after('license_path');
            }
        });
    }

    public function down(): void
    {
        if (!Schema::hasTable('drivers')) {
            return;
        }

        $cols = [
            'applicant_role',
            'gender',
            'education_level',
            'experience_years',
            'clinical_skills',
            'service_areas',
            'availability_shift',
            'work_days',
            'willing_to_travel',
            'has_private_car',
            'id_document_path',
            'certificate_path',
            'license_path',
            'cv_path',
        ];

        Schema::table('drivers', function (Blueprint $table) use ($cols) {
            foreach ($cols as $col) {
                if (Schema::hasColumn('drivers', $col)) {
                    $table->dropColumn($col);
                }
            }
        });
    }
};
