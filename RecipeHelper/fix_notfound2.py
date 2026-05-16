import json, os, urllib.request, urllib.parse, time

ASSETS_PATH = "RecipeHelper/Resources/Assets.xcassets"
JSON_PATH   = "RecipeHelper/Resources/recipes.json"

SEARCH = {
    "2":  "Pizza",
    "3":  "Risotto",
    "5":  "Dessert",
    "7":  "Fish",
    "8":  "Pie",
    "10": "Burger",
    "13": "Stir Fry",
    "19": "Korean Beef",
    "20": "Tikka",
    "22": "Spinach Paneer",
    "26": "Burrito",
    "28": "Quiche",
    "29": "Pancake",
    "39": "Soup",
    "42": "Lentil",
    "43": "Salad",
    "44": "Salad",
    "45": "Chocolate Cake",
    "48": "Chocolate",
    "52": "Curry",
    "53": "Burger",
    "57": "Chicken Salad",
    "60": "Fajita",
    "61": "Pasta Pesto",
    "63": "Pasta",
    "66": "Taco",
    "67": "Chili",
    "68": "Pork",
    "69": "Fried Chicken",
    "70": "Pho",
    "71": "Falafel",
    "73": "Japanese Soup",
    "77": "Chicken Parmesan",
    "81": "Pasta Garlic",
    "82": "Pasta",
    "83": "Toast",
    "85": "Pasta",
    "86": "Chicken",
    "87": "Cornmeal",
    "88": "Chicken Lemon",
    "89": "Beef Roast",
    "91": "Meat Pie",
    "93": "Cheese Toast",
    "94": "Tikka",
    "95": "Spinach Potato",
    "96": "Potato Cauliflower",
    "97": "Chicken Cream",
    "98": "Flatbread",
    "99": "Pastry",
    "100": "Rice Bowl",
    "101": "Tortilla",
    "103": "Chips",
    "106": "Seafood Stew",
    "110": "Potato Soup",
    "111": "Salmon",
    "112": "Curry",
    "115": "Thai Curry",
    "116": "Grain",
    "117": "Lamb",
    "119": "Pork Roast",
    "121": "Seafood",
    "126": "Kimchi",
    "127": "Korean Rice",
    "129": "Indonesian Rice",
    "130": "Peanut Salad",
    "133": "Meatballs",
    "134": "Parsley Salad",
    "136": "Pasta",
    "138": "Soup",
    "139": "Shakshuka",
    "141": "Japanese Pancake",
    "142": "Chickpea",
    "143": "Lamb",
    "144": "Eggplant",
    "145": "Corn Soup",
    "147": "Spinach Pie",
    "148": "Meatballs",
    "150": "Vegetable",
    "110": "Soup",
    "35": "Spanish Omelette",
    "24": "Mexican",
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

# Only fix recipes that still have http URLs (not asset names)
success = 0
for recipe in recipes:
    rid = recipe["id"]
    if rid not in SEARCH:
        continue
    # Skip if already has asset name
    if recipe.get("imageURL", "").startswith("recipe_"):
        continue

    name = "recipe_" + rid
    imageset = os.path.join(ASSETS_PATH, name + ".imageset")
    img_file = os.path.join(imageset, "image.jpg")
    os.makedirs(imageset, exist_ok=True)

    img_url = search_mealdb(SEARCH[rid])
    time.sleep(0.2)

    if img_url:
        try:
            download(img_url, img_file)
            with open(os.path.join(imageset, "Contents.json"), "w") as f:
                f.write('{"images":[{"filename":"image.jpg","idiom":"universal","scale":"1x"}],"info":{"author":"xcode","version":1}}')
            recipe["imageURL"] = name
            success += 1
            print("ok: " + recipe["title"])
        except:
            print("fail: " + recipe["title"])
    else:
        print("not found: " + recipe["title"])

with open(JSON_PATH, "w") as f:
    json.dump(recipes, f, ensure_ascii=False, indent=2)

print("\nFixed: " + str(success))
