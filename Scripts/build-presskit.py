#!/usr/bin/env python3
"""Build the two static presskit pages and a downloadable media archive."""
from pathlib import Path
from html import escape
import zipfile

root = Path(__file__).resolve().parent.parent
site = root / ('presskit' if (root / 'presskit').exists() else 'docs')
repo = 'https://github.com/mickyyang-1407/utuvo-drop'
base = 'https://mickyyang-1407.github.io/utuvo-drop/'

copy = {
 'en': {
  'lang':'en', 'title':'UTUVO Drop — A little cat. A place for your files.',
  'description':'A tiny macOS file shelf with a cat at the edge of your screen. Drop files in, see what it is holding, and drag them out. MIT open source.',
  'skip':'Skip to content', 'meet':'Meet Drop', 'press':'Press kit', 'other':'繁體中文',
  'eyebrow':'A SMALL MAC APP. A VERY GOOD CAT.', 'heading':'A little cat.<br>A place for<br><em>your files.</em>',
  'intro':'Give your files a little place to wait. Drop keeps them handy until you are ready to take them somewhere else.',
  'source':'Explore the source', 'see':'Meet your new helper', 'note':'macOS 14+ · Apple Silicon · MIT open source',
  'specs':[('SMALL BY NATURE','Native AppKit'),('YOURS TO MAKE','MIT licensed'),('STAYS WITH YOU','Local files, no network')],
  'inside':'HOW IT WORKS', 'insideTitle':'One small cat.<br>Three little moments.',
  'insideIntro':'A temporary place for files gathered from different folders. Your originals stay where they are. The cat just remembers how to find them.',
  'screenAlt':'UTUVO Drop in light mode: a cat with a thought bubble listing three sample files, their folders and sizes.',
  'darkAlt':'UTUVO Drop in dark mode: a warm charcoal thought bubble listing three sample files above the cat.',
  'caption':'Actual app screenshot · Sample files · Current interface labels are in Traditional Chinese.',
  'light':'Light', 'dark':'Dark', 'lightLabel':'Switch page and app screenshot to light appearance', 'darkLabel':'Switch page and app screenshot to dark appearance',
  'steps':[('A tail at the edge.','Most of the time, your helper stays tucked away. Bring files to its tail and it comes out to meet them.'),('A mouthful of files.','Drop one file or a handful. The cat opens its mouth, swallows the icons and grows a little rounder.'),('A thought worth opening.','After a drop, the thought bubble opens with your files. Drag a row or the whole cat to an app that accepts file drops.')],
  'workflowNote':'A completed copy handoff clears those references from the shelf. Cancel a drag and they stay. Original files are never moved or deleted.',
  'pressEyebrow':'FOR STORIES, POSTS & LITTLE INTRODUCTIONS', 'pressTitle':'Everything you need<br>to meet the cat.',
  'pressIntro':'A ready-to-use press pack: campaign artwork, actual interface screenshots, the app icon and short descriptions in English and Traditional Chinese.',
  'download':'Download press kit', 'downloadNote':'PNG artwork + screenshots + bilingual fact sheet',
  'assets':[('Campaign artwork','Full-resolution PNG · Brand illustration'),('App screenshots','Light appearance · Original PNG'),('Product fact sheet','English + Traditional Chinese · Markdown')],
  'factsTitle':'The useful details', 'aboutTitle':'In a few words',
  'facts':[('Product','UTUVO Drop'),('Made by','UTUVO'),('Category','Temporary file shelf / desktop pet'),('Platform','macOS 14+ · Apple Silicon'),('License','MIT'),('Availability','Source available · Build locally')],
  'about':'UTUVO Drop turns a temporary file shelf into a small desktop companion. A cream-orange cat peeks out from the edge of the screen, collects file references and shows them in a thought bubble. When it is time to move on, drag individual files or the whole cat to your next app.',
  'about2':'Built with Swift and AppKit, without third-party runtime packages, accounts, analytics or network access. It is a little experiment in making an ordinary desktop task feel friendlier.',
  'faqTitle':'A few practical<br>things to know.',
  'faq':[('Does the cat move or copy my originals?','No. Adding a file stores its local URL in memory. Removing it from Drop only removes that reference. A receiving app may copy or import the file when you drag it there.'),('Will it remember my files after quitting?','No. This is a temporary shelf. Its list is cleared when Drop quits or restarts. Your original files remain in their folders.'),('Can I download a ready-to-run app?','This release provides source code and build instructions. The local build uses an ad-hoc signature; a Developer ID-signed, notarized installer is not currently provided.'),('When does the cat come out?','When files reach the visible tail area, or when you click the tail. It does not watch every drag across your Mac. Missing or unreadable file references are marked in the list and cannot be dragged out.')],
  'closingTitle':'A small idea, out in the open.', 'closingIntro':'Read the code, make your own changes, or help this little cat get better.',
  'closingButton':'Find Drop on GitHub', 'footer':'A small macOS experiment by UTUVO', 'issues':'Issues & feedback', 'build':'Build instructions',
 },
 'zh-Hant': {
  'lang':'zh-Hant', 'title':'UTUVO Drop — 檔案先交給牠，等你來帶走。',
  'description':'螢幕邊緣的一隻小貓，也是你的 macOS 檔案暫放架。拖進去、看看牠收了什麼，再一起帶走。MIT 開源。',
  'skip':'跳到主要內容', 'meet':'認識小貓', 'press':'媒體素材', 'other':'English',
  'eyebrow':'A SMALL MAC APP. A VERY GOOD CAT.', 'heading':'檔案先交給牠。<br><em>等你來帶走。</em>',
  'intro':'還沒決定要放去哪裡的檔案，先給小貓保管。等你準備好，再一起帶去下一個地方。',
  'source':'看看原始碼', 'see':'認識這位小幫手', 'note':'macOS 14+ · Apple Silicon · MIT 開源',
  'specs':[('SMALL BY NATURE','原生 AppKit'),('YOURS TO MAKE','MIT 開源授權'),('STAYS WITH YOU','檔案留本機，不連網')],
  'inside':'HOW IT WORKS', 'insideTitle':'一隻小貓，<br>三個小動作。',
  'insideIntro':'把不同資料夾裡的檔案，先收在同一個地方。原始檔案都留在原處，小貓只是記住它們在哪裡。',
  'screenAlt':'UTUVO Drop 淺色實際畫面：貓咪頭上的思考泡泡列出三份示範檔案、來源資料夾與大小。',
  'darkAlt':'UTUVO Drop 深色實際畫面：貓咪上方的暖灰思考泡泡列出三份示範檔案。',
  'caption':'實際 App 截圖 · 示範檔案 · 目前介面以繁體中文顯示。',
  'light':'淺色', 'dark':'深色', 'lightLabel':'切換頁面與 App 截圖為淺色外觀', 'darkLabel':'切換頁面與 App 截圖為深色外觀',
  'steps':[('先露出一截尾巴。','平常牠躲在螢幕邊緣，輕輕搖尾巴。把檔案拖過去，牠就會跑出來迎接。'),('啊——吃進去了。','一份或好幾份都可以。小貓會張嘴吃下檔案圖示，肚子也跟著鼓起來。'),('心裡惦記著你的檔案。','吃完後，思考泡泡自動打開。看看牠收了什麼，再拖出單一檔案，或拉著貓咪整批帶走。')],
  'workflowNote':'接收端回報複製成功，才從暫放架移除這次交出的參照；取消拖曳就繼續保留。原始檔案不會被移動或刪除。',
  'pressEyebrow':'FOR STORIES, POSTS & LITTLE INTRODUCTIONS', 'pressTitle':'把這隻小貓，<br>介紹給大家。',
  'pressIntro':'整理好的媒體素材包：主視覺、真實介面截圖、App 圖示，以及中英文產品介紹，下載就能使用。',
  'download':'下載媒體素材包', 'downloadNote':'PNG 主視覺＋介面截圖＋中英文產品資料',
  'assets':[('宣傳主視覺','原尺寸 PNG · 品牌插畫'),('App 實際截圖','淺色介面 · 原始 PNG'),('產品資料與介紹','繁體中文＋English · Markdown')],
  'factsTitle':'產品小檔案', 'aboutTitle':'幾句話認識 Drop',
  'facts':[('名稱','UTUVO Drop'),('製作','UTUVO'),('類型','檔案暫放架／桌面小寵物'),('平台','macOS 14+ · Apple Silicon'),('授權','MIT'),('目前版本','原始碼已公開，可自行編譯')],
  'about':'UTUVO Drop 把檔案暫放架變成了一位桌面小夥伴。奶油橘色的小貓會從螢幕邊緣探出頭，幫你收好檔案參照，再把清單放進頭上的思考泡泡。要繼續工作時，可以逐一拖出，或拉著貓咪一次帶走。',
  'about2':'使用 Swift 與 AppKit 製作，沒有第三方執行套件，不需要帳號、沒有追蹤分析，也不連網。這是一個讓日常桌面操作多一點親切感的小實驗。',
  'faqTitle':'使用前，<br>你可能想知道。',
  'faq':[('牠會搬動或複製我的原始檔嗎？','不會。放進小貓只是在記憶體中記住檔案位置，從 Drop 移除也只會拿掉參照。拖給其他 App 時，接收的 App 可能會複製或匯入檔案。'),('重新開啟後，檔案清單還會在嗎？','不會。Drop 是臨時暫放架，離開或重開 App 就會清空清單。你的原始檔案仍然留在原來的資料夾。'),('有可以直接安裝的版本嗎？','目前提供原始碼與編譯方式。本機編譯採用 ad-hoc 簽章，尚未提供 Developer ID 簽署及 Apple 公證的安裝包。'),('小貓什麼時候會跑出來？','把檔案拖到看得見的尾巴旁，或直接點尾巴，牠就會出來。Drop 不會監看整個 Mac 上的拖曳。找不到或無法讀取的檔案會在清單標記，並阻止拖出。')],
  'closingTitle':'小小的想法，開放一起做。', 'closingIntro':'看看程式碼，改成自己喜歡的樣子，或幫這隻小貓變得更好。',
  'closingButton':'到 GitHub 找小貓', 'footer':'UTUVO 的一個 macOS 小實驗', 'issues':'問題與建議', 'build':'編譯方式',
 }
}

for locale, c in copy.items():
    zh = locale != 'en'
    prefix = '../' if zh else ''
    url = base + ('zh-Hant/' if zh else '')
    other = '../' if zh else 'zh-Hant/'
    img = prefix + 'assets/'
    media = prefix + 'media/'
    e = escape
    specs = ''.join(f'<div><span>{e(a)}</span><strong>{e(b)}</strong></div>' for a,b in c['specs'])
    steps = ''.join(f'<li><span class="step-num">0{i+1}</span><div><h3>{e(a)}</h3><p>{e(b)}</p></div></li>' for i,(a,b) in enumerate(c['steps']))
    facts = ''.join(f'<tr><th scope="row">{e(a)}</th><td>{e(b)}</td></tr>' for a,b in c['facts'])
    faq = ''.join(f'<details><summary>{e(a)}</summary><p>{e(b)}</p></details>' for a,b in c['faq'])
    asset_links = [('hero.png',f'<img class="asset-preview" src="{img}hero-640.webp" alt="" width="76" height="63" loading="lazy">'),('drop-light.png',f'<img class="asset-preview ui" src="{img}drop-light.webp" alt="" width="76" height="63" loading="lazy">'),('FACT-SHEET.md','<span class="file-symbol" aria-hidden="true">TXT</span>')]
    assets = ''.join(f'<li><a href="{media}{link}" download>{picture}<span><strong>{e(title)}</strong><small>{e(meta)}</small></span><span class="asset-arrow" aria-hidden="true">↓</span></a></li>' for (link,picture),(title,meta) in zip(asset_links,c['assets']))
    html = f'''<!doctype html>
<html lang="{c['lang']}" data-theme="light">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>{e(c['title'])}</title><meta name="description" content="{e(c['description'])}">
<meta property="og:title" content="{e(c['title'])}"><meta property="og:description" content="{e(c['description'])}"><meta property="og:type" content="website"><meta property="og:url" content="{url}"><meta property="og:image" content="{base}assets/social.jpg"><meta name="twitter:card" content="summary_large_image">
<link rel="canonical" href="{url}"><link rel="alternate" hreflang="en" href="{base}"><link rel="alternate" hreflang="zh-Hant" href="{base}zh-Hant/"><link rel="alternate" hreflang="x-default" href="{base}">
<link rel="icon" type="image/png" href="{img}favicon.png"><link rel="stylesheet" href="{img}style.css"><script src="{img}site.js" defer></script></head>
<body class="{'zh' if zh else 'en'}"><a class="skip" href="#main">{e(c['skip'])}</a>
<div class="wrap"><nav class="nav" aria-label="{'主要導覽' if zh else 'Main navigation'}"><a class="brand" href="{url}">UTUVO<span>/</span>DROP</a><div class="nav-links"><a class="desktop-link" href="#meet">{e(c['meet'])}</a><a href="#press">{e(c['press'])}</a><button class="theme-toggle" type="button" data-light="{c['light']}" data-dark="{c['dark']}" data-light-label="{c['lightLabel']}" data-dark-label="{c['darkLabel']}">{c['dark']}</button><a href="{other}" lang="{'en' if zh else 'zh-Hant'}">{e(c['other'])}</a></div></nav>
<main id="main"><section class="hero" aria-labelledby="headline"><picture class="hero-art"><img src="{img}hero-1280.webp" srcset="{img}hero-640.webp 640w, {img}hero-1280.webp 1280w, {img}hero-1672.webp 1672w" sizes="(max-width:700px) 540px, (max-width:1296px) 94vw, 1200px" alt="{'奶油橘色的 Drop 小貓抱著一份紙張，身旁放著小資料夾；品牌插畫。' if zh else 'Brand illustration of the cream-orange Drop cat holding a paper document beside a small folder.'}" width="1672" height="941" fetchpriority="high"></picture><div class="hero-copy"><div class="eyebrow">{c['eyebrow']}</div><h1 id="headline">{c['heading']}</h1><p class="intro">{e(c['intro'])}</p><div class="actions"><a class="button" href="{repo}">{e(c['source'])} <span aria-hidden="true">↗</span></a><a class="text-link" href="#meet">{e(c['see'])} ↓</a></div><p class="hero-note">{e(c['note'])}</p></div></section>
<div class="specs">{specs}</div>
<section class="section" id="meet"><div class="section-heading"><div><div class="eyebrow">{c['inside']}</div><h2>{c['insideTitle']}</h2></div><p>{e(c['insideIntro'])}</p></div><div class="workflow"><figure class="app-figure"><div class="app-stage"><img data-app-screenshot src="{img}drop-light.webp" data-light="{img}drop-light.webp" data-dark="{img}drop-dark.webp" data-light-alt="{e(c['screenAlt'])}" data-dark-alt="{e(c['darkAlt'])}" alt="{e(c['screenAlt'])}" width="680" height="1068" loading="lazy"></div><div class="modes" role="group" aria-label="{'外觀' if zh else 'Appearance'}"><button type="button" data-mode="light" aria-pressed="true">{c['light']}</button><button type="button" data-mode="dark" aria-pressed="false">{c['dark']}</button></div><figcaption>{e(c['caption'])}</figcaption></figure><div><ol class="steps">{steps}</ol><p class="aside-note">{e(c['workflowNote'])}</p></div></div></section>
<section class="section" id="press"><div class="press"><div class="press-copy"><div class="eyebrow">{c['pressEyebrow']}</div><h2>{c['pressTitle']}</h2><p>{e(c['pressIntro'])}</p><a class="button" href="{prefix}UTUVO-Drop-Press-Kit.zip" download>{e(c['download'])} <span aria-hidden="true">↓</span></a><p class="aside-note">{e(c['downloadNote'])}</p></div><ul class="asset-list">{assets}</ul></div><div class="facts"><div><h3>{c['factsTitle']}</h3><table class="fact-table"><tbody>{facts}</tbody></table></div><div><h3>{c['aboutTitle']}</h3><p class="about-copy">{e(c['about'])}</p><p class="about-copy">{e(c['about2'])}</p></div></div></section>
<section class="section faq"><h2>{c['faqTitle']}</h2><div>{faq}</div></section>
<section class="closing"><div><h2>{c['closingTitle']}</h2><p>{e(c['closingIntro'])}</p></div><a class="button" href="{repo}">{c['closingButton']} <span aria-hidden="true">↗</span></a></section></main>
<footer class="footer"><span>© 2026 UTUVO · {e(c['footer'])}</span><div><a href="{repo}/blob/main/LICENSE">MIT</a><a href="{repo}/blob/main/docs/DEVELOPMENT.md">{c['build']}</a><a href="{repo}/issues">{c['issues']}</a></div></footer></div></body></html>'''
    out = site / ('zh-Hant/index.html' if zh else 'index.html')
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(html)

facts = '''# UTUVO Drop — Press fact sheet

Product: UTUVO Drop
Creator: UTUVO
Category: macOS temporary file shelf / desktop pet
Platform: macOS 14 or later; Apple Silicon build
Technology: Swift / AppKit; no third-party runtime dependencies
License: MIT
Availability: Source code available. Build locally; no signed/notarized installer is provided.
Repository: https://github.com/mickyyang-1407/utuvo-drop
Presskit: https://mickyyang-1407.github.io/utuvo-drop/
Feedback: https://github.com/mickyyang-1407/utuvo-drop/issues

## Short description / English

A little cat. A place for your files. UTUVO Drop is a tiny macOS file shelf that keeps file references in a cat's thought bubble until you are ready to drag them to your next app.

## Product description / English

UTUVO Drop turns a temporary file shelf into a small desktop companion. A cream-orange cat hides at the screen edge with a gently wagging tail. Bring files to the tail and it comes out to collect them. Its belly grows, and a thought bubble opens to show the file names, source folders and sizes. Drag one row or the whole cat to an app that accepts file drops. Originals remain in place; a successful copy handoff clears the corresponding references from Drop. The list exists in memory and is cleared when the app quits.

## 簡短介紹 / 繁體中文

檔案先交給牠，等你來帶走。UTUVO Drop 是一個 macOS 檔案暫放架：小貓幫你記住檔案位置，收進頭上的思考泡泡，等你準備好再拖去下一個 App。

## 產品介紹 / 繁體中文

UTUVO Drop 把檔案暫放架變成了一位桌面小夥伴。奶油橘色的小貓平常躲在螢幕邊緣搖尾巴，檔案拖近時就跑出來迎接。吃進檔案後，肚子會鼓起，思考泡泡也會自動展開，列出檔名、來源資料夾與大小。你可以逐一拖出，或拉著貓咪一次帶走。原始檔案留在原處；接收端回報複製成功後，Drop 才清掉這次交出的參照。清單只存在記憶體裡，離開 App 就會清空。

## Practical notes

- Interface labels currently use Traditional Chinese.
- No accounts, analytics, network access or global drag monitoring.
- File URLs only; text snippets and web links are not shelf items.
- macOS and filesystem permissions still apply. Missing/unreadable references cannot be dragged out.
- The receiver determines whether to copy or import a dragged file.
- The local app uses an ad-hoc signature. No Developer ID or notarization claim is made.

## Media notes

- hero.png is a brand illustration, not an application screenshot.
- drop-light.png and drop-dark.png are actual app screenshots with synthetic sample files.
- drop-idle.png, drop-eating.png and drop-cat.png show actual native app states.
- app-icon.png is the bundled app icon.
- No user files, desktop content or customer data appear in this pack.
- Please identify the product as UTUVO Drop and link to the repository or presskit. See the repository MIT license and NOTICE.md for source and artwork notes.
'''
(site/'media/FACT-SHEET.md').write_text(facts)
(site/'.nojekyll').touch()
(site/'robots.txt').write_text(f'User-agent: *\nAllow: /\nSitemap: {base}sitemap.xml\n')
(site/'sitemap.xml').write_text(f'<?xml version="1.0" encoding="UTF-8"?><urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"><url><loc>{base}</loc></url><url><loc>{base}zh-Hant/</loc></url></urlset>\n')
required = ['hero.png','drop-light.png','drop-dark.png','drop-idle.png','drop-eating.png','drop-cat.png','app-icon.png','FACT-SHEET.md','ARTWORK.md']
if all((site/'media'/name).is_file() for name in required):
    with zipfile.ZipFile(site/'UTUVO-Drop-Press-Kit.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for name in required:
            archive.write(site/'media'/name, 'UTUVO-Drop-Press-Kit/'+name)
    print('Built English / Traditional Chinese pages and press archive.')
else:
    print('Built pages. Press archive awaits final hero artwork.')
