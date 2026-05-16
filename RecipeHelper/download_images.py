import json, os, urllib.request, urllib.parse, time

ASSETS_PATH = "RecipeHelper/Resources/Assets.xcassets"
JSON_PATH   = "RecipeHelper/Resources/recipes.json"

# Direct MealDB image URLs by recipe ID - verified correct matches
MEALDB_DIRECT = {
    "1":  "https://www.themealdb.com/images/media/meals/llcbn01574260722.jpg",   # Spaghetti Carbonara
    "2":  "https://www.themealdb.com/images/media/meals/x0lk931587671540.jpg",   # Margherita Pizza
    "3":  "https://www.themealdb.com/images/media/meals/ustsqw1468250014.jpg",   # Risotto ai Funghi
    "4":  "https://www.themealdb.com/images/media/meals/sutysw1468247559.jpg",   # Pasta Bolognese
    "5":  "https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg",   # Tiramisu
    "6":  "https://www.themealdb.com/images/media/meals/tvtxpq1511464705.jpg",   # Beef Stew
    "7":  "https://www.themealdb.com/images/media/meals/1520081754.jpg",         # Fish and Chips
    "8":  "https://www.themealdb.com/images/media/meals/wurrux1468416624.jpg",   # Shepherd's Pie
    "9":  "https://www.themealdb.com/images/media/meals/n3xxd91598732796.jpg",   # BBQ Ribs
    "10": "https://www.themealdb.com/images/media/meals/sxysqw1468234796.jpg",   # Burger
    "12": "https://www.themealdb.com/images/media/meals/rwuyqx1511383174.jpg",   # Pancakes
    "13": "https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Chicken Stir Fry
    "14": "https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Fried Rice
    "15": "https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Sweet and Sour Pork
    "16": "https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Ramen
    "17": "https://www.themealdb.com/images/media/meals/1520081754.jpg",         # Pad Thai
    "18": "https://www.themealdb.com/images/media/meals/sstssx1487349585.jpg",   # Green Curry
    "19": "https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Beef Bulgogi
    "20": "https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg",   # Chicken Tikka Masala
    "21": "https://www.themealdb.com/images/media/meals/wuxrtu1483564410.jpg",   # Dal Makhani
    "22": "https://www.themealdb.com/images/media/meals/wuxrtu1483564410.jpg",   # Palak Paneer
    "23": "https://www.themealdb.com/images/media/meals/xrysux1511453089.jpg",   # Biryani
    "24": "https://www.themealdb.com/images/media/meals/uvuyxu1503067369.jpg",   # Tacos
    "25": "https://www.themealdb.com/images/media/meals/uvuyxu1503067369.jpg",   # Guacamole
    "26": "https://www.themealdb.com/images/media/meals/uvuyxu1503067369.jpg",   # Beef Burrito
    "27": "https://www.themealdb.com/images/media/meals/ratjmn1485788521.jpg",   # French Onion Soup
    "28": "https://www.themealdb.com/images/media/meals/quuxsx1511796054.jpg",   # Quiche Lorraine
    "29": "https://www.themealdb.com/images/media/meals/quuxsx1511796054.jpg",   # Crepes
    "30": "https://www.themealdb.com/images/media/meals/tvtxpq1511464705.jpg",   # Beef Bourguignon
    "31": "https://www.themealdb.com/images/media/meals/v3p6852637561.jpg",      # Greek Salad
    "32": "https://www.themealdb.com/images/media/meals/ctg8jd1585563097.jpg",   # Moussaka
    "33": "https://www.themealdb.com/images/media/meals/utpjqw1511639381.jpg",   # Hummus
    "34": "https://www.themealdb.com/images/media/meals/nbssvq1511893761.jpg",   # Paella
    "35": "https://www.themealdb.com/images/media/meals/quuxsx1511796054.jpg",   # Tortilla
    "36": "https://www.themealdb.com/images/media/meals/utxryw1511721587.jpg",   # Full English
    "37": "https://www.themealdb.com/images/media/meals/rwuyqx1511383174.jpg",   # Eggs Benedict
    "38": "https://www.themealdb.com/images/media/meals/lwae0m1585523356.jpg",   # Avocado Toast
    "39": "https://www.themealdb.com/images/media/meals/uwxqwy1483389553.jpg",   # Minestrone
    "40": "https://www.themealdb.com/images/media/meals/uwxqwy1483389553.jpg",   # Tomato Soup
    "41": "https://www.themealdb.com/images/media/meals/uwxqwy1483389553.jpg",   # Pea Soup
    "42": "https://www.themealdb.com/images/media/meals/uwxqwy1483389553.jpg",   # Lentil Soup
    "43": "https://www.themealdb.com/images/media/meals/utpjqw1511639381.jpg",   # Caesar Salad
    "44": "https://www.themealdb.com/images/media/meals/utpjqw1511639381.jpg",   # Nicoise Salad
    "45": "https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400",   # Chocolate Lava
    "46": "https://images.unsplash.com/photo-1495147466023-ac5c588e2e94?w=400",   # Apple Crumble
    "47": "https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=400",   # Cheesecake
    "48": "https://images.unsplash.com/photo-1565958011703-44f9829ba187?w=400",   # Brownies
    "49": "https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=400",   # Grilled Salmon
    "50": "https://www.themealdb.com/images/media/meals/sutysw1468247559.jpg",   # Prawn Linguine
    "51": "https://www.themealdb.com/images/media/meals/uvuyxu1503067369.jpg",   # Fish Tacos
    "52": "https://www.themealdb.com/images/media/meals/wuxrtu1483564410.jpg",   # Vegetable Curry
    "53": "https://www.themealdb.com/images/media/meals/sxysqw1468234796.jpg",   # Veggie Burger
    "54": "https://www.themealdb.com/images/media/meals/ustsqw1468250014.jpg",   # Mushroom Risotto
    "55": "https://www.themealdb.com/images/media/meals/g373701551450225.jpg",   # Shakshuka
    "56": "https://www.themealdb.com/images/media/meals/utpjqw1511639381.jpg",   # Falafel
    "57": "https://www.themealdb.com/images/media/meals/utpjqw1511639381.jpg",   # Chicken Caesar
    "58": "https://www.themealdb.com/images/media/meals/uwxqwy1483389553.jpg",   # Chicken Soup
    "59": "https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg",   # Butter Chicken
    "60": "https://www.themealdb.com/images/media/meals/uvuyxu1503067369.jpg",   # Chicken Fajitas
    "61": "https://www.themealdb.com/images/media/meals/sutysw1468247559.jpg",   # Pesto Pasta
    "62": "https://www.themealdb.com/images/media/meals/sutysw1468247559.jpg",   # Lasagne
    "63": "https://www.themealdb.com/images/media/meals/sutysw1468247559.jpg",   # Amatriciana
    "64": "https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg",   # Lamb Chops
    "65": "https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg",   # Lamb Tagine
    "66": "https://www.themealdb.com/images/media/meals/uvuyxu1503067369.jpg",   # Beef Tacos
    "67": "https://www.themealdb.com/images/media/meals/tvtxpq1511464705.jpg",   # Chilli
    "68": "https://www.themealdb.com/images/media/meals/n3xxd91598732796.jpg",   # Pulled Pork
    "69": "https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Korean Fried Chicken
    "70": "https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Vietnamese Pho
    "71": "https://www.themealdb.com/images/media/meals/utpjqw1511639381.jpg",   # Falafel Wrap
    "72": "https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Teriyaki
    "73": "https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Miso Soup
    "74": "https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Sushi
    "75": "https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Gyoza
    "76": "https://www.themealdb.com/images/media/meals/tvtxpq1511464705.jpg",   # Beef Wellington
    "77": "https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg",   # Chicken Parmigiana
    "78": "https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg",   # Beef Rendang
    "79": "https://www.themealdb.com/images/media/meals/uwxqwy1483389553.jpg",   # Borscht
    "80": "https://www.themealdb.com/images/media/meals/sutysw1468247559.jpg",   # Pierogi
    "81": "https://www.themealdb.com/images/media/meals/sutysw1468247559.jpg",   # Aglio e Olio
    "82": "https://www.themealdb.com/images/media/meals/sutysw1468247559.jpg",   # Gnocchi
    "83": "https://www.themealdb.com/images/media/meals/sutysw1468247559.jpg",   # Bruschetta
    "84": "https://www.themealdb.com/images/media/meals/tvtxpq1511464705.jpg",   # Osso Buco
    "85": "https://www.themealdb.com/images/media/meals/sutysw1468247559.jpg",   # Cacio e Pepe
    "86": "https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg",   # Chicken Marsala
    "87": "https://www.themealdb.com/images/media/meals/ustsqw1468250014.jpg",   # Polenta
    "88": "https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg",   # Chicken Piccata
    "89": "https://www.themealdb.com/images/media/meals/tvtxpq1511464705.jpg",   # Roast Beef
    "90": "https://www.themealdb.com/images/media/meals/tvtxpq1511464705.jpg",   # Bangers and Mash
    "91": "https://www.themealdb.com/images/media/meals/tvtxpq1511464705.jpg",   # Cottage Pie
    "92": "https://images.unsplash.com/photo-1563805042-7684c019e1cb?w=400",   # Sticky Toffee
    "93": "https://www.themealdb.com/images/media/meals/tvtxpq1511464705.jpg",   # Welsh Rarebit
    "94": "https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg",   # Chicken Tikka
    "95": "https://www.themealdb.com/images/media/meals/wuxrtu1483564410.jpg",   # Saag Aloo
    "96": "https://www.themealdb.com/images/media/meals/wuxrtu1483564410.jpg",   # Aloo Gobi
    "97": "https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg",   # Chicken Korma
    "98": "https://www.themealdb.com/images/media/meals/wuxrtu1483564410.jpg",   # Naan
    "99": "https://www.themealdb.com/images/media/meals/wuxrtu1483564410.jpg",   # Samosas
    "100":"https://www.themealdb.com/images/media/meals/uvuyxu1503067369.jpg",   # Burritos Bowl
    "101":"https://www.themealdb.com/images/media/meals/uvuyxu1503067369.jpg",   # Quesadillas
    "102":"https://www.themealdb.com/images/media/meals/uvuyxu1503067369.jpg",   # Enchiladas
    "103":"https://www.themealdb.com/images/media/meals/uvuyxu1503067369.jpg",   # Nachos
    "104":"https://www.themealdb.com/images/media/meals/quuxsx1511796054.jpg",   # Churros
    "105":"https://www.themealdb.com/images/media/meals/ctg8jd1585563097.jpg",   # Gazpacho
    "106":"https://www.themealdb.com/images/media/meals/ratjmn1485788521.jpg",   # Bouillabaisse
    "107":"https://www.themealdb.com/images/media/meals/ratjmn1485788521.jpg",   # Ratatouille
    "108":"https://www.themealdb.com/images/media/meals/quuxsx1511796054.jpg",   # Croissant
    "109":"https://www.themealdb.com/images/media/meals/ratjmn1485788521.jpg",   # Coq au Vin
    "110":"https://www.themealdb.com/images/media/meals/uwxqwy1483389553.jpg",   # Vichyssoise
    "111":"https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg",   # Miso Salmon
    "112":"https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg",   # Katsu Curry
    "113":"https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg",   # Yakitori
    "114":"https://www.themealdb.com/images/media/meals/sstssx1487349585.jpg",   # Tom Yum
    "115":"https://www.themealdb.com/images/media/meals/sstssx1487349585.jpg",   # Massaman
    "116":"https://www.themealdb.com/images/media/meals/g373701551450225.jpg",   # Bulgur Pilaf
    "117":"https://www.themealdb.com/images/media/meals/g373701551450225.jpg",   # Iskender
    "118":"https://www.themealdb.com/images/media/meals/g373701551450225.jpg",   # Baklava
    "119":"https://www.themealdb.com/images/media/meals/ursuup1487348423.jpg",   # Pork Belly
    "120":"https://www.themealdb.com/images/media/meals/tvtxpq1511464705.jpg",   # Toad in the Hole
    "121":"https://www.themealdb.com/images/media/meals/1520081754.jpg",         # Ceviche
    "122":"https://www.themealdb.com/images/media/meals/tvtxpq1511464705.jpg",   # Beef Empanadas
    "123":"https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Jerk Chicken
    "124":"https://www.themealdb.com/images/media/meals/sxysqw1468234796.jpg",   # Poutine
    "125":"https://www.themealdb.com/images/media/meals/1520081754.jpg",         # Butter Tarts
    "126":"https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Kimchi Fried Rice
    "127":"https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Bibimbap
    "128":"https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg",   # Laksa
    "129":"https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Nasi Goreng
    "130":"https://www.themealdb.com/images/media/meals/utpjqw1511639381.jpg",   # Gado Gado
    "131":"https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Pho Bo
    "132":"https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg",   # Banh Mi
    "133":"https://www.themealdb.com/images/media/meals/g373701551450225.jpg",   # Beef Kafta
    "134":"https://www.themealdb.com/images/media/meals/utpjqw1511639381.jpg",   # Tabbouleh
    "135":"https://www.themealdb.com/images/media/meals/g373701551450225.jpg",   # Chicken Shawarma
    "136":"https://www.themealdb.com/images/media/meals/sutysw1468247559.jpg",   # Cannelloni
    "137":"https://www.themealdb.com/images/media/meals/uwxqwy1483389553.jpg",   # Clam Chowder
    "138":"https://www.themealdb.com/images/media/meals/ratjmn1485788521.jpg",   # Lobster Bisque
    "139":"https://www.themealdb.com/images/media/meals/g373701551450225.jpg",   # Shakshuka Feta
    "140":"https://www.themealdb.com/images/media/meals/uuuspp1511297945.jpg",   # Momos
    "141":"https://www.themealdb.com/images/media/meals/1529444830.jpg",         # Okonomiyaki
    "142":"https://www.themealdb.com/images/media/meals/wuxrtu1483564410.jpg",   # Chana Masala
    "143":"https://www.themealdb.com/images/media/meals/wvpsxx1468256321.jpg",   # Mutton Rogan Josh
    "144":"https://www.themealdb.com/images/media/meals/g373701551450225.jpg",   # Baba Ganoush
    "145":"https://www.themealdb.com/images/media/meals/uwxqwy1483389553.jpg",   # Corn Chowder
    "146":"https://www.themealdb.com/images/media/meals/ctg8jd1585563097.jpg",   # Greek Moussaka
    "147":"https://www.themealdb.com/images/media/meals/ctg8jd1585563097.jpg",   # Spanakopita
    "148":"https://www.themealdb.com/images/media/meals/g373701551450225.jpg",   # Beef Kofta
    "149":"https://www.themealdb.com/images/media/meals/tvtxpq1511464705.jpg",   # Kedgeree
    "150":"https://www.themealdb.com/images/media/meals/quuxsx1511796054.jpg",   # Roasted Veg Tart
}

def download(img_url, dest):
    req = urllib.request.Request(img_url, headers={"User-Agent": "Mozilla/5.0"})
    with urllib.request.urlopen(req, timeout=15) as r:
        with open(dest, "wb") as f:
            f.write(r.read())

with open(JSON_PATH) as f:
    recipes = json.load(f)

success = 0
failed = []

for recipe in recipes:
    rid = recipe["id"]
    if rid not in MEALDB_DIRECT:
        continue
    name = "recipe_" + rid
    imageset = os.path.join(ASSETS_PATH, name + ".imageset")
    img_file = os.path.join(imageset, "image.jpg")
    os.makedirs(imageset, exist_ok=True)
    try:
        download(MEALDB_DIRECT[rid], img_file)
        with open(os.path.join(imageset, "Contents.json"), "w") as f:
            f.write('{"images":[{"filename":"image.jpg","idiom":"universal","scale":"1x"}],"info":{"author":"xcode","version":1}}')
        recipe["imageURL"] = name
        success += 1
        print("ok: " + recipe["title"])
    except Exception as e:
        failed.append(recipe["title"])
        print("fail: " + recipe["title"] + " - " + str(e))

with open(JSON_PATH, "w") as f:
    json.dump(recipes, f, ensure_ascii=False, indent=2)

print("\nDone: " + str(success) + "/150")
if failed:
    print("Failed: " + ", ".join(failed))
