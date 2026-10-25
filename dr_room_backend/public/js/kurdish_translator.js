/**
 * Badini Kurdish Transliteration Helper
 * Converts Hawar (Latin) Kurmanji to Kurdish-Arabic (Badini) script.
 */
window.latinToKurdishBadini = function(text) {
    if (!text || typeof text !== 'string') return '';
    const dict = {
        'testker': 'تێستکەر', 'tester': 'تێستەر', 'cejd': 'جەددە', 'jeddah': 'جەددە',
        'taqîgeh': 'تاقیگەهـ', 'taqigeh': 'تاقیگەهـ', 'laboratuar': 'تاقیگەهـ',
        'nexweşxane': 'نەخۆشخانە', 'nexwesxane': 'نەخۆشخانە', 'dermanxane': 'دەرمانخانە',
        'nojdar': 'نوژدار', 'bijîşk': 'نوژدار', 'bijisk': 'نوژدار',
        'navnîşan': 'ناڤنیشان', 'navnisan': 'ناڤنیشان', 'nav': 'ناڤ',
        'pispor': 'پسبۆر', 'pişkinîn': 'پشکنین', 'piskinin': 'پشکنین',
        'xizmetguzarî': 'خزمەتگوزاری', 'daxwazî': 'داخوازی', 'pakêj': 'پاکێج',
        'erbil': 'هەولێر', 'hewlêr': 'هەولێر', 'duhok': 'دهۆک', 'dihok': 'دهۆک',
        'sulaymaniyah': 'سلێمانی', 'kirkuk': 'کەرکووک', 'halabja': 'هەڵەبجە'
    };
    if (!/[a-zA-ZçÇêÊîÎşŞûÛ]/.test(text)) return text;
    return text.replace(/\b[a-zA-ZçÇêÊîÎşŞûÛ]+\b/g, function(w) {
        const lower = w.toLowerCase();
        if (dict[lower]) return dict[lower];
        let res = '';
        for (let i = 0; i < w.length; i++) {
            const ch = w[i].toLowerCase();
            const next = i + 1 < w.length ? w[i+1].toLowerCase() : '';
            const isStart = (i === 0);
            if (ch === 'x' && next === 'w') { res += 'خو'; i++; continue; }
            if (ch === 'l' && next === 'l') { res += 'ڵ'; i++; continue; }
            if (ch === 'r' && next === 'r') { res += 'ڕ'; i++; continue; }
            if (ch === 's' && next === 'h') { res += 'ش'; i++; continue; }
            if (ch === 'c' && next === 'h') { res += 'چ'; i++; continue; }
            switch (ch) {
                case 'a': res += isStart ? 'ئا' : 'ا'; break;
                case 'b': res += 'ب'; break;
                case 'c': res += 'ج'; break;
                case 'ç': res += 'چ'; break;
                case 'd': res += 'د'; break;
                case 'e': res += isStart ? 'ئە' : 'ە'; break;
                case 'ê': res += isStart ? 'ئێ' : 'ێ'; break;
                case 'f': res += 'ف'; break;
                case 'g': res += 'گ'; break;
                case 'h': res += 'هـ'; break;
                case 'i': if (isStart) res += 'ئـ'; break;
                case 'î': res += isStart ? 'ئی' : 'ی'; break;
                case 'j': res += 'ژ'; break;
                case 'k': res += 'ک'; break;
                case 'l': res += 'ل'; break;
                case 'm': res += 'م'; break;
                case 'n': res += 'ن'; break;
                case 'o': res += isStart ? 'ئۆ' : 'ۆ'; break;
                case 'p': res += 'پ'; break;
                case 'q': res += 'ق'; break;
                case 'r': res += 'ر'; break;
                case 's': res += 'س'; break;
                case 'ş': res += 'ش'; break;
                case 't': res += 'ت'; break;
                case 'u': res += isStart ? 'ئو' : 'و'; break;
                case 'û': res += isStart ? 'ئوو' : 'وو'; break;
                case 'v': res += 'ڤ'; break;
                case 'w': res += 'و'; break;
                case 'x': res += 'خ'; break;
                case 'y': res += 'ی'; break;
                case 'z': res += 'ز'; break;
                default: res += ch; break;
            }
        }
        return res;
    });
};
