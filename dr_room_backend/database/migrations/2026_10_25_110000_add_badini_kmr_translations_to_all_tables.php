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
        // 1. Users
        if (Schema::hasTable('users')) {
            Schema::table('users', function (Blueprint $table) {
                if (!Schema::hasColumn('users', 'name_kmr')) {
                    $table->string('name_kmr')->nullable()->after('name_ar');
                }
            });
        }

        // 2. Labs
        if (Schema::hasTable('labs')) {
            Schema::table('labs', function (Blueprint $table) {
                if (!Schema::hasColumn('labs', 'location_kmr')) {
                    $table->string('location_kmr')->nullable()->after('location_ar');
                }
                if (!Schema::hasColumn('labs', 'about_us_kmr')) {
                    $table->text('about_us_kmr')->nullable()->after('about_us_ar');
                }
            });
        }

        // 3. Lab Tests
        if (Schema::hasTable('lab_tests')) {
            Schema::table('lab_tests', function (Blueprint $table) {
                if (!Schema::hasColumn('lab_tests', 'name_kmr')) {
                    $table->string('name_kmr')->nullable()->after('name_ar');
                }
                if (!Schema::hasColumn('lab_tests', 'description_kmr')) {
                    $table->text('description_kmr')->nullable();
                }
            });
        }

        // 4. Lab Packages
        if (Schema::hasTable('lab_packages')) {
            Schema::table('lab_packages', function (Blueprint $table) {
                if (!Schema::hasColumn('lab_packages', 'name_kmr')) {
                    $table->string('name_kmr')->nullable()->after('name_ar');
                }
                if (!Schema::hasColumn('lab_packages', 'description_kmr')) {
                    $table->text('description_kmr')->nullable();
                }
            });
        }

        // 5. Doctors
        if (Schema::hasTable('doctors')) {
            Schema::table('doctors', function (Blueprint $table) {
                if (!Schema::hasColumn('doctors', 'specialty_kmr')) {
                    $table->string('specialty_kmr')->nullable()->after('specialty_ar');
                }
                if (!Schema::hasColumn('doctors', 'clinic_name_kmr')) {
                    $table->string('clinic_name_kmr')->nullable()->after('clinic_name_ar');
                }
                if (!Schema::hasColumn('doctors', 'address_kmr')) {
                    $table->string('address_kmr')->nullable()->after('address_ar');
                }
                if (!Schema::hasColumn('doctors', 'bio_kmr')) {
                    $table->text('bio_kmr')->nullable()->after('bio_ar');
                }
            });
        }

        // 6. Doctor Services
        if (Schema::hasTable('doctor_services')) {
            Schema::table('doctor_services', function (Blueprint $table) {
                if (!Schema::hasColumn('doctor_services', 'name_kmr')) {
                    $table->string('name_kmr')->nullable()->after('name_ar');
                }
                if (!Schema::hasColumn('doctor_services', 'description_kmr')) {
                    $table->text('description_kmr')->nullable();
                }
            });
        }

        // 7. Pharmacies
        if (Schema::hasTable('pharmacies')) {
            Schema::table('pharmacies', function (Blueprint $table) {
                if (!Schema::hasColumn('pharmacies', 'location_kmr')) {
                    $table->string('location_kmr')->nullable()->after('location_ar');
                }
                if (!Schema::hasColumn('pharmacies', 'bio_kmr')) {
                    $table->text('bio_kmr')->nullable()->after('bio_ar');
                }
            });
        }

        // 8. Medications
        if (Schema::hasTable('medications')) {
            Schema::table('medications', function (Blueprint $table) {
                if (!Schema::hasColumn('medications', 'name_kmr')) {
                    $table->string('name_kmr')->nullable()->after('name_ar');
                }
                if (!Schema::hasColumn('medications', 'description_kmr')) {
                    $table->text('description_kmr')->nullable();
                }
            });
        }

        // 9. Nurses
        if (Schema::hasTable('nurses')) {
            Schema::table('nurses', function (Blueprint $table) {
                if (!Schema::hasColumn('nurses', 'specialty_kmr')) {
                    $table->string('specialty_kmr')->nullable()->after('specialty_ar');
                }
                if (!Schema::hasColumn('nurses', 'address_kmr')) {
                    $table->string('address_kmr')->nullable()->after('address_ar');
                }
                if (!Schema::hasColumn('nurses', 'bio_kmr')) {
                    $table->text('bio_kmr')->nullable()->after('bio_ar');
                }
            });
        }

        // 10. Service Categories
        if (Schema::hasTable('service_categories')) {
            Schema::table('service_categories', function (Blueprint $table) {
                if (!Schema::hasColumn('service_categories', 'name_kmr')) {
                    $table->string('name_kmr')->nullable()->after('name_ar');
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Reversible if needed
    }
};
