<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Ensure MIME type guessing works even if PHP ext-fileinfo is missing on the server
        try {
            if (class_exists(\Symfony\Component\Mime\MimeTypes::class)) {
                \Symfony\Component\Mime\MimeTypes::getDefault()->registerGuesser(new \App\Support\FallbackMimeGuesser());
            }
        } catch (\Throwable $e) {
            // Silently ignore if guesser registration cannot be performed
        }
    }
}
