import json, os, urllib.request, urllib.parse, time

ASSETS_PATH = "RecipeHelper/Resources/Assets.xcassets"
JSON_PATH   = "RecipeHelper/Resources/recipes.json"

# Alternative MealDB search terms for not-found recipes
SEARCH_ALTERNATIVES = {
    "1":  "Spaghetti alla Carbonara",
    "2":  "Pizza Margherita",
    "3":  "Mushroom Risotto",
    "4":  "Spaghetti Bolognese",
    "5":  "Tiramisu",
    "7":  "Fish Chips",
    "8":  "Shepards Pie",
    "9":  "Poutine",
    "10": "Hamburgers",
    "13": "Chicken Stir-Fry",
    "19": "Bulgogi Beef",
    "20": "Tikka Masala",
    "21": "Dal fry",
    "22": "Saag Paneer",
    "25": "Avocado Salad",
    "26": "Burrito",
    "28": "Quiche",
    "29": "Crepes Suzette",
    "38": "Avocado",
    "39": "Italian Minestrone",
    "41": "Pea Soup",
    "42": "Lentil Soup",
    "43": "Caesar salad",
    "44": "Salad Nicoise",
    "45": "Chocolate Fondant",
    "46": "Crumble",
    "48": "Brownies",
    "49": "Salmon",
    "52": "Vegetarian Curry",
    "53": "Veggie Sausage Roll",
    "54": "Risotto",
    "57": "Caesar Salad",
    "59": "Chicken",
    "60": "Fajitas",
    "61": "Pesto",
    "63": "Pasta",
    "66": "Tacos",
    "67": "Chilli",
    "68": "Pork",
    "69": "Fried Chicken",
    "70": "Pho",
    "71": "Wrap",
    "73": "Miso",
    "74": "Sushi",
    "75": "Dumplings",
    "77": "Chicken Parmesan",
    "81": "Spaghetti Garlic",
    "82": "Gnocchi",
    "83": "Bruschetta",
    "85": "Pasta Cheese",
    "86": "Chicken Marsala",
    "87": "Polenta",
    "88": "Chicken Piccata",
    "89": "Roast Beef",
    "90": "Sausages",
    "91": "Cottage Pie",
    "93": "Welsh Rarebit",
    "94": "Chicken Tikka",
    "95": "Saag",
    "96": "Aloo Gobi",
    "97": "Korma",
    "98": "Naan",
    "99": "Samosa",
    "100": "Burrito Bowl",
    "101": "Quesadilla",
    "102": "Enchilada",
    "103": "Nachos",
    "106": "Fish Stew",
    "110": "Leek Potato Soup",
    "111": "Salmon Teriyaki",
    "112": "Chicken Katsu",
    "113": "Chicken Skewers",
    "115": "Massaman",
    "116": "Pilaf",
    "117": "Kebab",
    "119": "Pork Belly",
    "121": "Ceviche",
    "124": "Poutine",
    "125": "Tarts",
    "131": "Pho",
    "132": "Sandwich",
    "134": "Tabbouleh",
    "135": "Shawarma",
    "136": "Cannelloni",
    "137": "Chowder",
    "138": "Bisque",
    "140": "Dumplings",
    "142": "Chickpea Curry",
    "143": "Lamb Curry",
    "145": "Corn Soup",
    "146": "Moussaka",
    "149": "Kedgeree",
    "150": "Vegetable Tart",
}

def search_mealdb(query):
    url = "https://www.themealdb.com/api/json/v1/1/search.php?s=" + urllib.parse.quote(query)
    try:
        req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=8) as r:
            data = json.loads(r.read())
        meals = data.get("meals")
        if meals:
            return meals[0].get("strMealThumb")
    except:
        pass
    return None

def download(img_url, dest):
    req = urllib.request.Request(img_url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=15) as r:
        with open(dest, "wb") as f:
            f.write(r.read())

with open(JSON_PATH) as f:
    recipes = json.load(f)

success = 0
still_missing = []

for recipe in recipes:
    rid = recipe["id"]
    if rid not in SEARCH_ALTERNATIVES:
        continue

    name = "recipe_" + rid
    imageset = os.path.join(ASSETS_PATH, name + ".imageset")
    img_file = os.path.join(imageset, "image.jpg")
    os.makedirs(imageset, exist_ok=True)

    img_url = search_mealdb(SEARCH_ALTERNATIVES[rid])
    time.sleep(0.2)

    if img_url:
        try:
            download(img_url, img_file)
            with open(os.path.join(imageset, "Contents.json"), "w") as f:
                f.write('{"images":[{"filename":"image.jpg","idiom":"universal","scale":"1x"}],"info":{"author":"xcode","version":1}}')
            recipe["imageURL"] = name
            success += 1
            print("ok: " + recipe["title"])
        except Exception as e:
            still_missing.append(recipe["title"])
            print("fail: " + recipe["title"])
    else:
        still_missing.append(recipe["title"])
        print("not found: " + recipe["title"])

with open(JSON_PATH, "w") as f:
    json.dump(recipes, f, ensure_ascii=False, indent=2)

print("\nFixed: " + str(success))
if still_missing:
    print("Still missing: " + ", ".join(still_missing))
