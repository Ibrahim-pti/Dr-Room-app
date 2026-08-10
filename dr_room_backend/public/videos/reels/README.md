# Emergency Reels — ڤیدیۆکان

ئەم فۆڵدەرە بۆ ڤیدیۆی خۆماڵیی بەشی ریلزە.

`EmergencyReelController` بۆ هەر ریلێک سەیری ئەم فۆڵدەرە دەکات. ئەگەر فایلەکە لێرە بوو،
لینکی خۆماڵی دەگەڕێنێتەوە؛ ئەگەر نەبوو، لینکی Pexels (fallback) بەکاردەهێنێت.

## ناوی فایلەکان

| id | ناوی فایل                     | بابەت                        |
|----|-------------------------------|------------------------------|
| 1  | `cpr-chest-compressions.mp4`  | CPR — پەستانی سنگ            |
| 2  | `cpr-bag-valve-mask.mp4`      | CPR — بە ماسکی هەوا          |
| 3  | `rescue-breathing.mp4`        | هەناسەدانی فریاگوزاری        |
| 4  | `wound-bandaging.mp4`         | پێچانەوەی برین               |
| 5  | `cpr-mannequin.mp4`           | CPR لەسەر مانیکێن            |
| 6  | `first-aid-class.mp4`         | پۆلی فێرکاری فریاگوزاری      |
| 7  | `human-dummy-practice.mp4`    | ڕاهێنان لەسەر دەمی           |

## زیادکردنی ڤیدیۆی Vecteezy

Vecteezy ڕێگە بە hotlink ناداتەوە — لینکی لاپەڕەی گەڕان (`vecteezy.com/free-videos/...`)
فایلی ڤیدیۆ نییە و لینکی CDN ـیشیان جێگیر نییە. کەواتە:

1. لە [vecteezy.com/free-videos/first-aid-training](https://www.vecteezy.com/free-videos/first-aid-training) ڤیدیۆکە دابەزێنە (Free License).
2. فایلەکە بگۆڕە بۆ یەکێک لە ناوەکانی سەرەوە و بیخە ناو ئەم فۆڵدەرە.
3. لە `EmergencyReelController::CATALOG` خانەی `attribution` بگۆڕە بۆ ناوی داهێنەری Vecteezy —
   مۆڵەتی خۆڕایی Vecteezy ئەمە داوا دەکات.
4. `APP_URL` لە `.env` دەبێت ئەو ناونیشانە بێت کە مۆبایلەکە دەیبینێت (نەک `localhost`)،
   چونکە `asset()` لەسەری بنیات دەنرێت.

## ئامۆژگاری

- بۆ ریلز، ڤیدیۆی ستوونی (9:16) باشترە — زۆربەی ڤیدیۆی ستۆک ئاسۆییە.
- فایلی 1080p و کەمتر لە ~10MB بکە، بۆ ئەوەی خێرا بار ببێت.
- فایلەکان لە git تۆمار مەکە ئەگەر گەورەن؛ لە جیاتی ئەوە بیانخە سەر CDN.
