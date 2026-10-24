<?php

/**
 * Polyfill for PHP ext-fileinfo when the extension is not installed/enabled.
 *
 * Provides:
 * - FILEINFO_* constants
 * - finfo class
 * - finfo_* procedural functions
 * - mime_content_type function
 */

if (!defined('FILEINFO_NONE')) {
    define('FILEINFO_NONE', 0);
}
if (!defined('FILEINFO_SYMLINK')) {
    define('FILEINFO_SYMLINK', 2);
}
if (!defined('FILEINFO_MIME')) {
    define('FILEINFO_MIME', 1040);
}
if (!defined('FILEINFO_MIME_TYPE')) {
    define('FILEINFO_MIME_TYPE', 16);
}
if (!defined('FILEINFO_MIME_ENCODING')) {
    define('FILEINFO_MIME_ENCODING', 1024);
}
if (!defined('FILEINFO_DEVICES')) {
    define('FILEINFO_DEVICES', 8);
}
if (!defined('FILEINFO_CONTINUE')) {
    define('FILEINFO_CONTINUE', 32);
}
if (!defined('FILEINFO_PRESERVE_ATIME')) {
    define('FILEINFO_PRESERVE_ATIME', 128);
}
if (!defined('FILEINFO_RAW')) {
    define('FILEINFO_RAW', 256);
}
if (!defined('FILEINFO_EXTENSION')) {
    define('FILEINFO_EXTENSION', 2097152);
}

if (!class_exists('finfo', false)) {
    class finfo
    {
        private int $flags;
        private ?string $magicFile;

        public function __construct(int $flags = FILEINFO_NONE, ?string $magicFile = null)
        {
            $this->flags = $flags;
            $this->magicFile = $magicFile;
        }

        public function set_flags(int $flags): bool
        {
            $this->flags = $flags;
            return true;
        }

        public function file(string $filename, int $flags = FILEINFO_NONE, $context = null): string|false
        {
            return \App\Support\FallbackMimeGuesser::guessMime($filename) ?? 'application/octet-stream';
        }

        public function buffer(string $string, int $flags = FILEINFO_NONE, $context = null): string|false
        {
            return \App\Support\FallbackMimeGuesser::guessMimeFromBuffer($string);
        }
    }
}

if (!function_exists('finfo_open')) {
    function finfo_open(int $flags = FILEINFO_NONE, ?string $magicFile = null)
    {
        return new finfo($flags, $magicFile);
    }
}

if (!function_exists('finfo_file')) {
    function finfo_file($finfo, string $filename, int $flags = FILEINFO_NONE, $context = null)
    {
        if ($finfo instanceof finfo) {
            return $finfo->file($filename, $flags, $context);
        }
        return false;
    }
}

if (!function_exists('finfo_buffer')) {
    function finfo_buffer($finfo, string $string, int $flags = FILEINFO_NONE, $context = null)
    {
        if ($finfo instanceof finfo) {
            return $finfo->buffer($string, $flags, $context);
        }
        return false;
    }
}

if (!function_exists('finfo_close')) {
    function finfo_close($finfo): bool
    {
        return true;
    }
}

if (!function_exists('finfo_set_flags')) {
    function finfo_set_flags($finfo, int $flags): bool
    {
        if ($finfo instanceof finfo) {
            return $finfo->set_flags($flags);
        }
        return false;
    }
}

if (!function_exists('mime_content_type')) {
    function mime_content_type(string $filename)
    {
        return \App\Support\FallbackMimeGuesser::guessMime($filename);
    }
}
