<?php

namespace App\Support;

/**
 * Every gate the admin dashboard checks, plus the default set each staff role
 * gets. A user row may override this with its own `permissions` JSON column.
 */
class Permissions
{
    public const MANAGE_CONTENT   = 'manage_content';    // banners, articles, notifications
    public const MANAGE_PROVIDERS = 'manage_providers';  // doctors, nurses, labs, pharmacies, x-rays
    public const MANAGE_ORDERS    = 'manage_orders';     // orders, appointments
    public const MANAGE_USERS     = 'manage_users';      // block/unblock patients
    public const MANAGE_REVIEWS   = 'manage_reviews';    // hide/delete reviews
    public const MANAGE_CATEGORIES = 'manage_categories';
    public const VIEW_PAYMENTS    = 'view_payments';
    public const MANAGE_STAFF     = 'manage_staff';      // create staff, change permissions
    public const VIEW_LOGS        = 'view_logs';

    public const ALL = [
        self::MANAGE_CONTENT,
        self::MANAGE_PROVIDERS,
        self::MANAGE_ORDERS,
        self::MANAGE_USERS,
        self::MANAGE_REVIEWS,
        self::MANAGE_CATEGORIES,
        self::VIEW_PAYMENTS,
        self::MANAGE_STAFF,
        self::VIEW_LOGS,
    ];

    /** Kurdish labels, for the permission checkboxes in the admin app. */
    public const LABELS = [
        self::MANAGE_CONTENT    => 'ناوەڕۆک (بانەر، فریاگوزاری، ئاگاداری)',
        self::MANAGE_PROVIDERS  => 'پێشکەشکاران (پزیشک، پەرستار، تاقیگە، دەرمانخانە)',
        self::MANAGE_ORDERS     => 'داواکاری و نۆرەکان',
        self::MANAGE_USERS      => 'بەکارهێنەران (بلۆک/کردنەوە)',
        self::MANAGE_REVIEWS    => 'هەڵسەنگاندن و کۆمێنتەکان',
        self::MANAGE_CATEGORIES => 'کەتەگۆرییەکان',
        self::VIEW_PAYMENTS     => 'مامەڵە و داهات',
        self::MANAGE_STAFF      => 'ستاف و دەسەڵاتەکان',
        self::VIEW_LOGS         => 'تۆماری چالاکی',
    ];

    /**
     * Roles that may sign in to the admin dashboard, and what each may touch
     * before any per-user override.
     */
    public const ROLE_DEFAULTS = [
        // Full control, including creating other staff. Cannot be restricted.
        'admin' => self::ALL,

        // Day-to-day operations: content, orders, providers — but never staff,
        // payments, or the audit log.
        'staff' => [
            self::MANAGE_CONTENT,
            self::MANAGE_PROVIDERS,
            self::MANAGE_ORDERS,
        ],

        // Community safety only.
        'moderator' => [
            self::MANAGE_REVIEWS,
            self::MANAGE_USERS,
            self::MANAGE_CONTENT,
        ],
    ];

    public const STAFF_ROLES = ['admin', 'staff', 'moderator'];

    public const ROLE_LABELS = [
        'admin'     => 'ئەدمینی سەرەکی',
        'staff'     => 'ستاف',
        'moderator' => 'چاودێری ناوەڕۆک',
    ];

    public static function defaultsFor(?string $role): array
    {
        return self::ROLE_DEFAULTS[$role] ?? [];
    }
}
