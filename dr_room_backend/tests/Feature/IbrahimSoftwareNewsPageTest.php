<?php

namespace Tests\Feature;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class IbrahimSoftwareNewsPageTest extends TestCase
{
    use RefreshDatabase;

    public function test_news_ibrahim_software_page_is_publicly_accessible_without_auth(): void
    {
        $response = $this->get('/news/ibrahim-software');

        $response->assertStatus(200);
        $response->assertSee('Platform Digital Infrastructure &amp; Software Engineering by IBRAHIM SOFTWARE', false);
        $response->assertSee(
            'The core web architecture, backend systems, and cloud infrastructure of this platform are engineered and maintained by IBRAHIM SOFTWARE (Registration No. 2123 / 2026), a registered software engineering company headquartered in Erbil, Kurdistan Region, Iraq, founded by Ibrahim Ismail Ahmed.',
            false
        );
        $response->assertSee('پەرەپێدانی ژێرخانی دیجیتاڵی و سیستمی ئەلیکترۆنی لەلایەن کۆمپانیای IBRAHIM SOFTWARE', false);
        $response->assertSee(
            'سیستمی تەکنیکی و ژێرخانی نەرمەکاڵای ئەم پلاتفۆرمە لەلایەن کۆمپانیای IBRAHIM SOFTWARE (کۆمپانیای تۆمارکراوی بواری ئەندازیاریی نەرمەکاڵا لە هەولێر - مۆڵەتی فەرمیی ژمارە 2123 / 2026) و بە سەرپەرشتیی ئەندازیاری نەرمەکاڵا ئیبراهیم ئیسماعیل ئەحمەد دیزاین و پەرەی پێدراوە.',
            false
        );
    }

    public function test_news_page_contains_dofollow_link_seo_meta_og_tags_and_json_ld(): void
    {
        $response = $this->get('/news/ibrahim-software');

        $response->assertStatus(200);
        $html = $response->getContent();

        $this->assertStringContainsString('<meta name="robots" content="index, follow">', $html);
        $this->assertStringContainsString('<meta name="description"', $html);
        $this->assertStringContainsString('<meta property="og:type" content="article">', $html);
        $this->assertStringContainsString('<meta property="og:title"', $html);
        $this->assertStringContainsString('<meta property="og:description"', $html);
        $this->assertStringContainsString('<meta property="og:url"', $html);

        $this->assertStringContainsString('<script type="application/ld+json">', $html);
        $this->assertStringContainsString('"@type": "Organization"', $html);
        $this->assertStringContainsString('"@type": "Article"', $html);
        $this->assertStringContainsString('https://ibrahimsoftware.online', $html);
        $this->assertStringContainsString('2123 / 2026', $html);
        $this->assertStringContainsString('Ibrahim Ismail Ahmed', $html);

        $this->assertMatchesRegularExpression('/<a\s+href="https:\/\/ibrahimsoftware\.online"[^>]*>/i', $html);
        $this->assertStringNotContainsString('nofollow', $html);
    }

    public function test_public_landing_and_login_pages_link_to_engineering_news_page(): void
    {
        foreach (['/', '/staff', '/staff/login', '/delivery'] as $uri) {
            $response = $this->get($uri);
            $response->assertStatus(200);
            $response->assertSee('/news/ibrahim-software', false);
            $response->assertSee('Platform Engineering: IBRAHIM SOFTWARE', false);
        }
    }

    public function test_robots_and_sitemap_include_news_page(): void
    {
        $robots = file_get_contents(public_path('robots.txt'));
        $this->assertStringContainsString('Allow: /news/ibrahim-software', $robots);
        $this->assertStringContainsString('Sitemap: https://sys.shaqamonline.org/sitemap.xml', $robots);

        $sitemap = file_get_contents(public_path('sitemap.xml'));
        $this->assertStringContainsString('https://sys.shaqamonline.org/news/ibrahim-software', $sitemap);
    }
}
