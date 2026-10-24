<?php

namespace App\Support;

use Symfony\Component\Mime\MimeTypeGuesserInterface;

class FallbackMimeGuesser implements MimeTypeGuesserInterface
{
    public function isGuesserSupported(): bool
    {
        return true;
    }

    public function guessMimeType(string $path): ?string
    {
        return static::guessMime($path);
    }

    public static function guessMime(string $path): ?string
    {
        if (!is_file($path) || !is_readable($path)) {
            return static::guessByExtension($path);
        }

        $header = @file_get_contents($path, false, null, 0, 32);
        if ($header !== false && strlen($header) >= 4) {
            $fromBuffer = static::guessMimeFromBuffer($header);
            if ($fromBuffer !== 'application/octet-stream') {
                return $fromBuffer;
            }
        }

        // Check for SVG
        $lead = @file_get_contents($path, false, null, 0, 512);
        if ($lead !== false && (stripos($lead, '<svg') !== false || (stripos($lead, '<?xml') !== false && stripos($lead, '<svg') !== false))) {
            return 'image/svg+xml';
        }

        return static::guessByExtension($path);
    }

    public static function guessMimeFromBuffer(string $buffer): string
    {
        if (strlen($buffer) >= 4) {
            // JPEG: FF D8 FF
            if (str_starts_with($buffer, "\xFF\xD8\xFF")) {
                return 'image/jpeg';
            }
            // PNG: 89 50 4E 47 0D 0A 1A 0A
            if (str_starts_with($buffer, "\x89PNG\x0D\x0A\x1A\x0A")) {
                return 'image/png';
            }
            // GIF: GIF87a / GIF89a
            if (str_starts_with($buffer, 'GIF87a') || str_starts_with($buffer, 'GIF89a')) {
                return 'image/gif';
            }
            // WEBP: RIFF....WEBP
            if (str_starts_with($buffer, 'RIFF') && substr($buffer, 8, 4) === 'WEBP') {
                return 'image/webp';
            }
            // PDF: %PDF
            if (str_starts_with($buffer, '%PDF')) {
                return 'application/pdf';
            }
            // ZIP / Office docs: PK\x03\x04
            if (str_starts_with($buffer, "PK\x03\x04")) {
                return 'application/zip';
            }
        }

        if (stripos(substr($buffer, 0, 512), '<svg') !== false) {
            return 'image/svg+xml';
        }

        return 'application/octet-stream';
    }

    public static function guessByExtension(string $path): string
    {
        $ext = strtolower(pathinfo($path, PATHINFO_EXTENSION));
        $map = [
            'jpg'  => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'png'  => 'image/png',
            'gif'  => 'image/gif',
            'webp' => 'image/webp',
            'svg'  => 'image/svg+xml',
            'ico'  => 'image/x-icon',
            'bmp'  => 'image/bmp',
            'pdf'  => 'application/pdf',
            'mp4'  => 'video/mp4',
            'mov'  => 'video/quicktime',
            'mp3'  => 'audio/mpeg',
            'csv'  => 'text/csv',
            'txt'  => 'text/plain',
            'json' => 'application/json',
            'zip'  => 'application/zip',
            'doc'  => 'application/msword',
            'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'xls'  => 'application/vnd.ms-excel',
            'xlsx' => 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ];

        return $map[$ext] ?? 'application/octet-stream';
    }
}
