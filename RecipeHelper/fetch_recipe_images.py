#!/usr/bin/env python3
"""
fetch_recipe_images.py — скачивает уникальные картинки для всех 150 рецептов.

Стратегия:
  1) Wikipedia REST API (/page/summary) — главное фото статьи о блюде
  2) Wikipedia MediaWiki search API — если точного заголовка нет
  3) TheMealDB search.php — fallback
  4) Валидация: content-type image/*, size ≥ 15 КБ
  5) Дедупликация по MD5 — один и тот же URL не уйдёт двум рецептам подряд
  6) Backup предыдущих картинок в .image_backup/

Использование:
  python3 fetch_recipe_images.py --dry-run            # посмотреть план, ничего не трогать
  python3 fetch_recipe_images.py --apply              # реально скачать
  python3 fetch_recipe_images.py --apply --only 5,14,19 # только конкретные ID
  python3 fetch_recipe_images.py --apply --force      # перезаписать даже уникальные

Запускать из корня репозитория: .../RecipeHelper/
"""

import argparse
import hashlib
import json
import os
import re
import shutil
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime

ASSETS_PATH = "RecipeHelper/Resources/Assets.xcassets"
JSON_PATH   = "RecipeHelper/Resources/recipes.json"
BACKUP_DIR  = ".image_backup"
REPORT_PATH = "image_report.txt"

UA = "RecipeHelperBot/1.0 (educational project; contact: student@university.edu)"

# ---------------------------------------------------------------------------
# Ручные overrides — для блюд, у которых Wikipedia-заголовок не совпадает
# с названием в recipes.json или первый автоматический поиск промахивается.
# Можно задавать список: сначала пробуется первый, потом второй и т.д.
# ---------------------------------------------------------------------------
WIKI_OVERRIDES = {
    "1":  ["Carbonara"],
    "2":  ["Pizza Margherita", "Neapolitan pizza"],
    "3":  ["Mushroom risotto", "Risotto"],
    "4":  ["Bolognese sauce", "Ragù alla bolognese"],
    "5":  ["Tiramisu"],
    "6":  ["Beef bourguignon", "Stew"],
    "7":  ["Fish and chips"],
    "8":  ["Shepherd's pie"],
    "9":  ["Pork ribs", "Barbecue"],
    "10": ["Hamburger", "Cheeseburger"],
    "11": ["Macaroni and cheese"],
    "12": ["Pancake"],
    "13": ["Stir frying", "Chicken stir fry"],
    "14": ["Fried rice"],
    "15": ["Sweet and sour pork"],
    "16": ["Ramen"],
    "17": ["Pad thai"],
    "18": ["Green curry"],
    "19": ["Bulgogi"],
    "20": ["Chicken tikka masala"],
    "21": ["Dal makhani", "Dal"],
    "22": ["Palak paneer"],
    "23": ["Biryani"],
    "24": ["Taco"],
    "25": ["Guacamole"],
    "26": ["Burrito"],
    "27": ["French onion soup"],
    "28": ["Quiche Lorraine"],
    "29": ["Crêpe"],
    "30": ["Beef bourguignon"],
    "31": ["Greek salad"],
    "32": ["Moussaka"],
    "33": ["Hummus"],
    "34": ["Paella"],
    "35": ["Spanish omelette"],
    "36": ["Full breakfast"],
    "37": ["Eggs Benedict"],
    "38": ["Avocado toast"],
    "39": ["Minestrone"],
    "40": ["Tomato soup"],
    "41": ["Pea soup"],
    "42": ["Lentil soup"],
    "43": ["Caesar salad"],
    "44": ["Salade niçoise"],
    "45": ["Chocolate fondant", "Molten chocolate cake"],
    "46": ["Apple crumble"],
    "47": ["Cheesecake"],
    "48": ["Chocolate brownie"],
    "49": ["Salmon as food", "Grilled salmon"],
    "50": ["Linguine", "Prawn linguine"],
    "51": ["Fish taco"],
    "52": ["Vegetable curry", "Curry"],
    "53": ["Veggie burger"],
    "54": ["Risotto"],
    "55": ["Shakshouka"],
    "56": ["Falafel"],
    "57": ["Caesar salad"],
    "58": ["Chicken soup"],
    "59": ["Butter chicken"],
    "60": ["Fajita"],
    "61": ["Pesto", "Trofie al pesto"],
    "62": ["Lasagne"],
    "63": ["Amatriciana sauce", "Bucatini all'amatriciana"],
    "64": ["Lamb chop", "Rack of lamb"],
    "65": ["Tagine"],
    "66": ["Taco"],
    "67": ["Chili con carne"],
    "68": ["Pulled pork"],
    "69": ["Korean fried chicken"],
    "70": ["Phở"],
    "71": ["Falafel", "Wrap (food)"],
    "72": ["Teriyaki"],
    "73": ["Miso soup"],
    "74": ["Sushi"],
    "75": ["Jiaozi", "Gyōza"],
    "76": ["Beef Wellington"],
    "77": ["Chicken parmesan"],
    "78": ["Rendang"],
    "79": ["Borscht"],
    "80": ["Pierogi"],
    "81": ["Spaghetti aglio e olio"],
    "82": ["Gnocchi"],
    "83": ["Bruschetta"],
    "84": ["Ossobuco"],
    "85": ["Cacio e pepe"],
    "86": ["Chicken Marsala"],
    "87": ["Polenta"],
    "88": ["Piccata", "Chicken piccata"],
    "89": ["Roast beef"],
    "90": ["Bangers and mash"],
    "91": ["Cottage pie"],
    "92": ["Sticky toffee pudding"],
    "93": ["Welsh rarebit"],
    "94": ["Chicken tikka"],
    "95": ["Saag aloo", "Saag"],
    "96": ["Aloo gobi"],
    "97": ["Korma"],
    "98": ["Naan"],
    "99": ["Samosa"],
    "100":["Burrito bowl", "Burrito"],
    "101":["Quesadilla"],
    "102":["Enchilada"],
    "103":["Nachos"],
    "104":["Churro"],
    "105":["Gazpacho"],
    "106":["Bouillabaisse"],
    "107":["Ratatouille"],
    "108":["Croissant"],
    "109":["Coq au vin"],
    "110":["Vichyssoise"],
    "111":["Miso-glazed salmon", "Salmon as food"],
    "112":["Katsu curry", "Tonkatsu"],
    "113":["Yakitori"],
    "114":["Tom yum"],
    "115":["Massaman curry"],
    "116":["Pilaf"],
    "117":["İskender kebap"],
    "118":["Baklava"],
    "119":["Pork belly"],
    "120":["Toad in the hole"],
    "121":["Ceviche"],
    "122":["Empanada"],
    "123":["Jerk chicken"],
    "124":["Poutine"],
    "125":["Butter tart"],
    "126":["Kimchi fried rice"],
    "127":["Bibimbap"],
    "128":["Laksa"],
    "129":["Nasi goreng"],
    "130":["Gado-gado"],
    "131":["Phở"],
    "132":["Bánh mì"],
    "133":["Kofta", "Kafta"],
    "134":["Tabbouleh"],
    "135":["Shawarma"],
    "136":["Cannelloni"],
    "137":["Clam chowder"],
    "138":["Lobster bisque", "Bisque (food)"],
    "139":["Shakshouka"],
    "140":["Momo (food)"],
    "141":["Okonomiyaki"],
    "142":["Chana masala"],
    "143":["Rogan josh"],
    "144":["Baba ghanoush"],
    "145":["Corn chowder", "Chowder"],
    "146":["Moussaka"],
    "147":["Spanakopita"],
    "148":["Kofta"],
    "149":["Kedgeree"],
    "150":["Tart (food)", "Quiche"],
}

# ---------------------------------------------------------------------------
# Утилиты сети
# ---------------------------------------------------------------------------

def _get(url, timeout=15):
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
    return urllib.request.urlopen(req, timeout=timeout)

def http_json(url):
    try:
        with _get(url) as r:
            return json.loads(r.read().decode("utf-8", errors="replace"))
    except Exception:
        return None

def http_bytes(url):
    try:
        with _get(url, timeout=25) as r:
            ctype = r.headers.get("Content-Type", "")
            data = r.read()
            return data, ctype
    except Exception:
        return None, ""

# ---------------------------------------------------------------------------
# Поиск изображений
# ---------------------------------------------------------------------------

def wiki_summary_image(title):
    """Wikipedia REST /page/summary — возвращает URL оригинального изображения."""
    t = urllib.parse.quote(title.replace(" ", "_"), safe="")
    data = http_json(f"https://en.wikipedia.org/api/rest_v1/page/summary/{t}")
    if not data:
        return None
    orig = (data.get("originalimage") or {}).get("source")
    if orig:
        return orig
    thumb = (data.get("thumbnail") or {}).get("source")
    if thumb:
        # нормализуем thumb → originalimage (убираем /thumb/.../NNNpx-)
        return re.sub(r"/thumb(/.+?)/\d+px-[^/]+$", r"\1", thumb)
    return None

def wiki_search_image(query):
    """Поиск по Wikipedia: находим страницу + оригинальное изображение."""
    url = (
        "https://en.wikipedia.org/w/api.php?"
        "action=query&format=json&generator=search&prop=pageimages"
        "&piprop=original&pilimit=5&gsrlimit=5&gsrsearch=" + urllib.parse.quote(query)
    )
    data = http_json(url)
    if not data:
        return None
    pages = (data.get("query") or {}).get("pages") or {}
    # берём самую релевантную страницу с картинкой
    candidates = sorted(pages.values(), key=lambda p: p.get("index", 99))
    for p in candidates:
        img = (p.get("original") or {}).get("source")
        if img:
            return img
    return None

def mealdb_image(query):
    """TheMealDB: точный поиск блюда по названию."""
    url = "https://www.themealdb.com/api/json/v1/1/search.php?s=" + urllib.parse.quote(query)
    data = http_json(url)
    if not data:
        return None
    meals = data.get("meals") or []
    if meals:
        return meals[0].get("strMealThumb")
    return None

def collect_candidates(recipe):
    """Собираем упорядоченный список URL-кандидатов для рецепта."""
    rid = recipe["id"]
    title = recipe["title"]
    urls = []

    # 1) Ручные overrides через Wikipedia
    for t in WIKI_OVERRIDES.get(rid, []):
        u = wiki_summary_image(t)
        if u:
            urls.append(("wiki:" + t, u))
        time.sleep(0.15)

    # 2) Wikipedia по точному названию рецепта
    u = wiki_summary_image(title)
    if u:
        urls.append(("wiki:" + title, u))
    time.sleep(0.15)

    # 3) Wikipedia search по «title cuisine food»
    q = f"{title} {recipe.get('cuisine','')} food".strip()
    u = wiki_search_image(q)
    if u:
        urls.append(("wiki-search:" + q, u))
    time.sleep(0.15)

    # 4) TheMealDB
    u = mealdb_image(title)
    if u:
        urls.append(("mealdb:" + title, u))
    time.sleep(0.15)

    # dedupe сохраняя порядок
    seen = set()
    uniq = []
    for src, u in urls:
        if u not in seen:
            seen.add(u)
            uniq.append((src, u))
    return uniq

# ---------------------------------------------------------------------------
# Валидация и сохранение
# ---------------------------------------------------------------------------

MAGIC = {
    b"\xff\xd8\xff": ".jpg",
    b"\x89PNG\r\n\x1a\n": ".png",
    b"RIFF": ".webp",   # WebP: RIFF....WEBP
    b"GIF87a": ".gif",
    b"GIF89a": ".gif",
}

def detect_ext(data):
    for sig, ext in MAGIC.items():
        if data.startswith(sig):
            if ext == ".webp" and b"WEBP" not in data[:16]:
                continue
            return ext
    return None

def validate_image(data, ctype):
    if not data or len(data) < 15_000:
        return False, f"too small ({len(data) if data else 0} bytes)"
    if ctype and not ctype.startswith("image/"):
        return False, f"not image ({ctype})"
    if detect_ext(data) is None:
        return False, "unknown format"
    return True, "ok"

def md5(data):
    return hashlib.md5(data).hexdigest()

def load_existing_hashes():
    """Считаем md5 всех уже лежащих картинок, чтобы не дублировать."""
    hashes = {}
    for i in range(1, 151):
        for ext in (".jpg", ".png", ".webp", ".gif"):
            p = os.path.join(ASSETS_PATH, f"recipe_{i}.imageset", f"image{ext}")
            if os.path.exists(p):
                with open(p, "rb") as f:
                    hashes[str(i)] = md5(f.read())
                break
    return hashes

def backup_existing(rid):
    imageset = os.path.join(ASSETS_PATH, f"recipe_{rid}.imageset")
    if not os.path.isdir(imageset):
        return
    os.makedirs(BACKUP_DIR, exist_ok=True)
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    for fn in os.listdir(imageset):
        if fn.startswith("image."):
            shutil.copy2(os.path.join(imageset, fn),
                         os.path.join(BACKUP_DIR, f"recipe_{rid}_{ts}_{fn}"))

def save_image(rid, data, ext):
    imageset = os.path.join(ASSETS_PATH, f"recipe_{rid}.imageset")
    os.makedirs(imageset, exist_ok=True)
    # чистим старые image.* (могли быть .jpg, теперь .png и т.п.)
    for fn in list(os.listdir(imageset)):
        if fn.startswith("image.") and fn != f"image{ext}":
            os.remove(os.path.join(imageset, fn))
    # пишем картинку
    with open(os.path.join(imageset, f"image{ext}"), "wb") as f:
        f.write(data)
    # Contents.json — тот же формат, что был у остальных imageset
    contents = {
        "images": [{"filename": f"image{ext}", "idiom": "universal", "scale": "1x"}],
        "info": {"author": "xcode", "version": 1},
    }
    with open(os.path.join(imageset, "Contents.json"), "w") as f:
        json.dump(contents, f)

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="реально скачивать (по умолчанию dry-run)")
    ap.add_argument("--dry-run", action="store_true", help="только план, без скачивания (default)")
    ap.add_argument("--only", default="", help="список ID через запятую, напр. 5,14,19")
    ap.add_argument("--force", action="store_true", help="перезаписать даже уже уникальные картинки")
    args = ap.parse_args()

    apply = args.apply and not args.dry_run

    if not os.path.exists(JSON_PATH):
        sys.exit(f"Не вижу {JSON_PATH}. Запускай из корня репозитория RecipeHelper/")

    with open(JSON_PATH, encoding="utf-8") as f:
        recipes = json.load(f)

    only = {s.strip() for s in args.only.split(",") if s.strip()}

    # Если не --force: пропускаем рецепты, у которых картинка и так уникальна
    existing = load_existing_hashes()
    hash_count = {}
    for h in existing.values():
        hash_count[h] = hash_count.get(h, 0) + 1
    duplicates = {rid for rid, h in existing.items() if hash_count.get(h, 0) > 1}

    report_lines = []
    used_hashes = {h for rid, h in existing.items() if hash_count.get(h) == 1}  # уже занятые уникальные
    success, failed, skipped = 0, [], 0

    for recipe in recipes:
        rid   = recipe["id"]
        title = recipe["title"]

        if only and rid not in only:
            continue
        if not args.force and rid not in duplicates and rid in existing:
            skipped += 1
            report_lines.append(f"[SKIP] {rid:>3} {title}  (картинка уже уникальна)")
            continue

        print(f"[{rid:>3}] {title} …", flush=True)
        cands = collect_candidates(recipe)
        if not cands:
            print(f"    ✗ кандидатов не нашлось")
            failed.append((rid, title, "no candidates"))
            report_lines.append(f"[FAIL] {rid:>3} {title}  — источники ничего не дали")
            continue

        chosen = None
        reason = ""
        for source, url in cands:
            data, ctype = http_bytes(url)
            ok, why = validate_image(data, ctype)
            if not ok:
                print(f"    - {source}: {why}")
                continue
            h = md5(data)
            if h in used_hashes:
                print(f"    - {source}: дубликат уже использованной картинки")
                continue
            chosen = (source, url, data, ctype, h)
            reason = why
            break

        if not chosen:
            failed.append((rid, title, "no valid candidate"))
            report_lines.append(f"[FAIL] {rid:>3} {title}  — все кандидаты отсеяны")
            continue

        source, url, data, ctype, h = chosen
        ext = detect_ext(data) or ".jpg"
        print(f"    ✓ {source}  ({len(data)//1024} KB, {ext})")
        report_lines.append(f"[ OK ] {rid:>3} {title}  ← {source}  ({len(data)//1024} KB {ext})")

        if apply:
            backup_existing(rid)
            save_image(rid, data, ext)
            recipe["imageURL"] = f"recipe_{rid}"
        used_hashes.add(h)
        success += 1

    if apply:
        with open(JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(recipes, f, ensure_ascii=False, indent=2)

    # Итоги
    summary = [
        "=" * 60,
        f"Режим: {'APPLY (записано на диск)' if apply else 'DRY-RUN (ничего не менялось)'}",
        f"Обработано:  {success + len(failed)}",
        f"Успешно:     {success}",
        f"Не удалось:  {len(failed)}",
        f"Пропущено:   {skipped}",
        "",
    ]
    if failed:
        summary.append("Не нашли картинку для:")
        for rid, title, why in failed:
            summary.append(f"  - {rid:>3} {title}  ({why})")
    print("\n".join(summary))
    with open(REPORT_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(report_lines + [""] + summary))
    print(f"\nОтчёт записан: {REPORT_PATH}")
    if apply:
        print(f"Резервные копии старых картинок: {BACKUP_DIR}/")

if __name__ == "__main__":
    main()
