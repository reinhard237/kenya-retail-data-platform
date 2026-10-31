#!/usr/bin/env python3
"""
Synthetic Kenyan retail data generator

Produces 5 related CSV tables:
  stores (40), products (300), customers (5,000), promotions (12),
  transactions (one row per invoice line, default 250,000)

Built-in patterns (so EDA / stats / ML have something real to find):
  * seasonality: December peak, month-end payday spike, weekend lift, slow growth
  * promotions lift traffic and quantity on the promoted category
  * M-Pesa and loyalty customers buy bigger baskets
  * ~35% of customers churn (stop buying) at some point
  * prices rise ~6% a year
Deliberate dirt (for the cleaning milestone): duplicates, mixed date formats,
blank values, county-name variants, outlier quantities/prices, returns.

Usage:  python generate_data.py [--lines 250000] [--out data] [--seed 42]
"""
import argparse
import os

import numpy as np
import pandas as pd

START = pd.Timestamp("2022-01-01")
END = pd.Timestamp("2025-09-30")

# county: (customer weight, n_stores, lat, lon, towns)
COUNTIES = {
    "Nairobi": (28, 11, -1.286, 36.817, ["Westlands", "Kilimani", "Kasarani", "Embakasi", "Langata", "Karen",
                                         "Ruaraka", "Donholm", "Parklands", "South B", "Eastleigh", "Githurai"]),
    "Mombasa": (10, 4, -4.043, 39.668, ["Nyali", "Bamburi", "Likoni", "Mvita", "Changamwe", "Kisauni"]),
    "Kisumu": (6, 3, -0.091, 34.768, ["Milimani", "Kondele", "Mamboleo", "Dunga"]),
    "Nakuru": (7, 3, -0.303, 36.080, ["Nakuru Town", "Naivasha", "Gilgil", "Njoro"]),
    "Uasin Gishu": (6, 3, 0.514, 35.270, ["Eldoret CBD", "Langas", "Kapsoya"]),
    "Kiambu": (9, 3, -1.031, 36.831, ["Thika", "Ruiru", "Juja", "Kikuyu"]),
    "Machakos": (5, 2, -1.517, 37.263, ["Machakos Town", "Athi River", "Mlolongo"]),
    "Kajiado": (4, 2, -1.852, 36.777, ["Kitengela", "Ngong", "Rongai", "Kajiado Town"]),
    "Nyeri": (3, 2, -0.420, 36.951, ["Nyeri Town", "Karatina", "Othaya"]),
    "Meru": (3, 2, 0.047, 37.649, ["Meru Town", "Maua", "Nkubu"]),
    "Kakamega": (3, 1, 0.283, 34.752, ["Kakamega Town", "Mumias"]),
    "Kisii": (3, 1, -0.677, 34.780, ["Kisii Town", "Ogembo"]),
    "Kilifi": (3, 1, -3.630, 39.850, ["Malindi", "Kilifi Town"]),
    "Embu": (2, 1, -0.531, 37.457, ["Embu Town", "Runyenjes"]),
    "Garissa": (2, 1, -0.453, 39.646, ["Garissa Town", "Bulla Pesa"]),
}
ABBR = {"Nairobi": "Nrb", "Mombasa": "Msa", "Uasin Gishu": "U. Gishu", "Nakuru": "Nkr"}

MALE = ["Brian", "Kevin", "Dennis", "Peter", "John", "James", "Samuel", "David", "Joseph", "Collins", "Victor",
        "Eric", "Felix", "Kelvin", "Moses", "Daniel", "Paul", "Festus", "Allan", "Ian", "Mohamed", "Abdi",
        "Hassan", "Ali"]
FEMALE = ["Faith", "Mercy", "Grace", "Mary", "Jane", "Esther", "Lucy", "Joyce", "Purity", "Caroline", "Sharon",
          "Beatrice", "Winnie", "Naomi", "Ruth", "Agnes", "Linet", "Cynthia", "Hellen", "Fatuma", "Amina",
          "Halima", "Zainab", "Brenda"]
SURNAMES = ["Otieno", "Wanjiku", "Kamau", "Njoroge", "Mwangi", "Kiprop", "Kiplagat", "Chebet", "Cheruiyot",
            "Odhiambo", "Achieng", "Ochieng", "Mutua", "Muthoni", "Wafula", "Nyambura", "Kariuki", "Maina",
            "Omondi", "Atieno", "Mohamed", "Hussein", "Abdi", "Barasa", "Njeri", "Kimani", "Wekesa", "Mutiso",
            "Langat", "Rotich", "Koech", "Ndung'u", "Gitau", "Karanja", "Ouma", "Mburu", "Naliaka", "Wambui",
            "Nyongesa"]
SUPPLIERS = ["Savannah Distributors", "Rift Valley Wholesalers", "Lakeside Traders", "Coastal Supplies Ltd",
             "Mt. Kenya Distributors", "Jambo Wholesale", "Highlands Trading Co", "Safari Provisions"]

# category -> list of (item, brands, sizes, (cost_lo, cost_hi), perishable)
CATALOG = {
    "Food Staples": [
        ("Maize Flour", ["Jogoo", "Soko", "Pembe", "Dola"], ["1kg", "2kg", "5kg"], (70, 130), False),
        ("Wheat Flour", ["Exe", "Ajab", "Pembe"], ["1kg", "2kg"], (90, 150), False),
        ("Rice", ["Pishori", "Mwea", "Basmati"], ["1kg", "2kg", "5kg"], (120, 260), False),
        ("Sugar", ["Mumias", "Kabras", "Sony"], ["1kg", "2kg"], (130, 170), False),
        ("Cooking Oil", ["Elianto", "Fresh Fry", "Rina", "Golden Fry"], ["500ml", "1L", "3L"], (170, 330), False),
        ("Spaghetti", ["Santa Lucia", "Tropical Heat", "Jambo"], ["400g", "500g"], (60, 120), False),
        ("Bread", ["Broadways", "Supaloaf", "Festive"], ["400g", "800g"], (55, 100), True),
        ("Tea Leaves", ["Ketepa", "Tetley", "Kericho Gold"], ["100g", "250g", "500g"], (60, 220), False),
    ],
    "Dairy": [
        ("Fresh Milk", ["Brookside", "Tuzo", "Daima", "Fresha"], ["500ml", "1L"], (50, 120), True),
        ("UHT Milk", ["Brookside", "Tuzo", "Lato"], ["500ml", "1L"], (60, 130), False),
        ("Yoghurt", ["Brookside", "Daima", "Tuzo"], ["250ml", "500ml"], (50, 140), True),
        ("Butter", ["Prestige", "Brookside"], ["250g", "500g"], (150, 320), True),
        ("Cheese", ["Brookside", "Happy Cow"], ["200g", "400g"], (250, 520), True),
        ("Ghee", ["Brookside", "Tuzo"], ["250g", "500g"], (280, 480), False),
        ("Mala", ["Brookside", "Tuzo", "Daima", "Githunguri"], ["250ml", "500ml", "1L"], (50, 150), True),
        ("Evaporated Milk", ["Peak", "Nunu"], ["170g", "410g"], (70, 190), False),
        ("Cream", ["Brookside", "Tuzo"], ["250ml", "500ml"], (120, 300), True),
    ],
    "Beverages": [
        ("Soda", ["Coca-Cola", "Fanta", "Sprite", "Pepsi", "Stoney"], ["300ml", "500ml", "2L"], (35, 120), False),
        ("Juice", ["Minute Maid", "Delmonte", "Afia", "Pick n Peel"], ["500ml", "1L"], (70, 190), False),
        ("Bottled Water", ["Dasani", "Keringet", "Aquamist"], ["500ml", "1L", "5L"], (25, 150), False),
        ("Energy Drink", ["Red Bull", "Monster", "Predator"], ["250ml", "500ml"], (90, 250), False),
        ("Instant Coffee", ["Nescafe", "Dormans", "Kenco"], ["50g", "100g", "200g"], (150, 520), False),
        ("Drinking Chocolate", ["Cadbury", "Nestle"], ["200g", "400g"], (180, 480), False),
    ],
    "Household": [
        ("Laundry Detergent", ["Omo", "Ariel", "Sunlight", "Toss"], ["500g", "1kg", "2kg"], (90, 520), False),
        ("Dish Soap", ["Sunlight", "Vim", "Joy"], ["500ml", "1L"], (80, 230), False),
        ("Toilet Paper", ["Rosy", "Softcare", "Kleenex"], ["4 rolls", "10 rolls"], (90, 380), False),
        ("Bleach", ["Jik", "Harpic", "Domestos"], ["500ml", "1L"], (90, 250), False),
        ("Laundry Bar Soap", ["Kleesoft", "Menengai", "Sunlight"], ["800g", "1kg"], (80, 190), False),
        ("Air Freshener", ["Glade", "Air Wick"], ["300ml", "500ml"], (180, 420), False),
        ("Matches", ["Chui", "Kibo"], ["Single", "Pack of 10"], (5, 40), False),
        ("Aluminium Foil", ["Diamond", "Kenpoly"], ["5m", "10m"], (110, 260), False),
        ("Sponges and Scourers", ["Scotch-Brite", "Vileda"], ["Single", "Pack of 3"], (40, 160), False),
        ("Insecticide", ["Doom", "Raid", "Baygon"], ["300ml", "600ml"], (220, 520), False),
    ],
    "Personal Care": [
        ("Bar Soap", ["Geisha", "Lux", "Dettol", "Dove"], ["100g", "175g"], (40, 140), False),
        ("Toothpaste", ["Colgate", "Close-up", "Aquafresh"], ["75ml", "100ml", "140ml"], (90, 260), False),
        ("Body Lotion", ["Vaseline", "Nivea", "Jergens"], ["200ml", "400ml"], (180, 540), False),
        ("Shampoo", ["Dove", "Sunsilk", "Head and Shoulders", "Pantene"], ["200ml", "400ml"], (160, 520), False),
        ("Sanitary Pads", ["Always", "Softcare", "Kotex"], ["8 pads", "16 pads"], (70, 240), False),
        ("Deodorant", ["Nivea", "Rexona", "Axe"], ["50ml", "150ml"], (190, 430), False),
        ("Razor Blades", ["Gillette", "Bic"], ["Pack of 2", "Pack of 5"], (60, 420), False),
        ("Toothbrush", ["Colgate", "Oral-B", "Aquafresh"], ["Single", "Pack of 2"], (50, 220), False),
        ("Baby Diapers", ["Pampers", "Huggies"], ["S", "M", "L"], (600, 1400), False),
    ],
    "Snacks": [
        ("Biscuits", ["Britannia", "Oreo", "Krackles", "Tiffy"], ["100g", "200g", "400g"], (30, 180), False),
        ("Crisps", ["Pringles", "Lays", "Zesta"], ["40g", "100g", "165g"], (40, 320), False),
        ("Chocolate Bar", ["Cadbury", "Snickers", "Kit Kat"], ["50g", "100g"], (50, 200), False),
        ("Sweets", ["Alpenliebe", "Mentos", "Halls"], ["Single", "Bag"], (10, 150), False),
        ("Groundnuts", ["House Brand", "Nutri"], ["100g", "250g", "500g"], (40, 260), False),
        ("Popcorn", ["Act II", "House Brand"], ["50g", "100g"], (30, 120), False),
        ("Cake Slices", ["Mayfair", "Festive"], ["Single", "Pack of 6"], (20, 260), True),
        ("Wafers", ["Cadbury", "Britannia", "Krackles"], ["Single", "Pack"], (15, 120), False),
    ],
}
CAT_WEIGHT = {"Food Staples": 3.0, "Dairy": 2.0, "Beverages": 2.0, "Household": 1.3, "Personal Care": 1.0,
              "Snacks": 1.5}

PROMOS = [  # id, name, start, end, discount %, category
    ("PR01", "Back-to-School", "2022-01-03", "2022-01-14", 10, "Household"),
    ("PR02", "Black Friday", "2022-11-21", "2022-11-27", 25, "All"),
    ("PR03", "Back-to-School", "2023-01-02", "2023-01-13", 12, "Household"),
    ("PR04", "Easter Offer", "2023-04-03", "2023-04-10", 10, "Food Staples"),
    ("PR05", "Mid-Year Sale", "2023-07-03", "2023-07-14", 15, "Personal Care"),
    ("PR06", "Black Friday", "2023-11-20", "2023-11-26", 30, "All"),
    ("PR07", "Back-to-School", "2024-01-02", "2024-01-13", 12, "Snacks"),
    ("PR08", "Easter Offer", "2024-03-25", "2024-04-01", 10, "Dairy"),
    ("PR09", "Month-End Mega", "2024-08-26", "2024-08-31", 8, "Beverages"),
    ("PR10", "Black Friday", "2024-11-25", "2024-12-01", 25, "All"),
    ("PR11", "Easter Offer", "2025-04-14", "2025-04-21", 10, "Food Staples"),
    ("PR12", "Mid-Year Sale", "2025-07-07", "2025-07-18", 15, "Beverages"),
]
PAY = ["M-Pesa", "Cash", "Card", "Airtel Money"]
PAYP = [0.55, 0.30, 0.10, 0.05]
CHANNELS = ["In-store", "Online", "Pickup"]


def make_stores(rng):
    rows, sid = [], 1
    lo, hi = pd.Timestamp("2012-01-01"), pd.Timestamp("2021-12-31")
    for county, (_, ns, lat, lon, towns) in COUNTIES.items():
        for t in rng.choice(towns, size=ns, replace=False):
            typ = rng.choice(["Supermarket", "Mini-mart", "Kiosk"], p=[0.35, 0.45, 0.20])
            a_lo, a_hi = {"Supermarket": (400, 1500), "Mini-mart": (120, 400), "Kiosk": (40, 120)}[typ]
            if rng.random() < 0.75:
                od = lo + pd.Timedelta(days=int(rng.integers(0, (hi - lo).days + 1)))
            else:  # a few stores open during the analysis window
                od = pd.Timestamp("2022-03-01") + pd.Timedelta(days=int(rng.integers(0, 480)))
            rows.append(dict(
                store_id=f"ST{sid:03d}", store_name=f"{t} {typ}", county=county, town=t, store_type=typ,
                opening_date=od, floor_area_sqm=int(rng.integers(a_lo, a_hi)),
                latitude=round(lat + rng.normal(0, 0.05), 6), longitude=round(lon + rng.normal(0, 0.05), 6),
                manager_name=f"{rng.choice(MALE + FEMALE)} {rng.choice(SURNAMES)}"))
            sid += 1
    return pd.DataFrame(rows)


def make_products(rng):
    pool = []
    for cat, items in CATALOG.items():
        combos = []
        for item, brands, sizes, (clo, chi), per in items:
            for b in brands:
                base = rng.uniform(clo, chi)
                for i, s in enumerate(sizes):
                    mult = [1.0, 1.9, 3.4][i] if len(sizes) == 3 else [1.0, 1.9][i]
                    cost = round(base * mult, 2)
                    price = round(cost * rng.uniform(1.15, 1.45))
                    combos.append(dict(product_name=f"{b} {item} {s}", category=cat, subcategory=item,
                                       brand=b, unit_cost_kes=cost, unit_price_kes=float(price),
                                       supplier=rng.choice(SUPPLIERS), is_perishable="Yes" if per else "No"))
        pool.append(combos)
    chosen, left = [], []
    for combos in pool:
        idx = rng.permutation(len(combos))
        chosen += [combos[i] for i in idx[:50]]
        left += [combos[i] for i in idx[50:]]
    need = 300 - len(chosen)
    if need > 0:
        chosen += [left[i] for i in rng.permutation(len(left))[:need]]
    chosen = chosen[:300]
    df = pd.DataFrame(chosen).sample(frac=1, random_state=int(rng.integers(0, 10**6))).reset_index(drop=True)
    df.insert(0, "product_id", [f"P{i + 1:03d}" for i in range(len(df))])
    return df


def make_customers(rng, stores, n=5000):
    names = list(COUNTIES)
    cw = np.array([COUNTIES[c][0] for c in names], float)
    county = rng.choice(names, size=n, p=cw / cw.sum())
    gender = rng.choice(["Male", "Female"], size=n)
    first = np.array([rng.choice(MALE) if g == "Male" else rng.choice(FEMALE) for g in gender])
    last = rng.choice(SURNAMES, size=n)
    b0, b1 = pd.Timestamp("2019-01-01"), pd.Timestamp("2021-12-31")
    c0, c1 = pd.Timestamp("2022-01-01"), pd.Timestamp("2025-06-30")
    early = rng.random(n) < 0.60
    signup = np.where(
        early,
        (b0 + pd.to_timedelta(rng.integers(0, (b1 - b0).days + 1, n), unit="D")).values,
        (c0 + pd.to_timedelta(rng.integers(0, (c1 - c0).days + 1, n), unit="D")).values)
    signup = pd.to_datetime(signup)
    d0, d1 = pd.Timestamp("1950-01-01"), pd.Timestamp("2006-12-31")
    dob = d0 + pd.to_timedelta(rng.integers(0, (d1 - d0).days + 1, n), unit="D")
    national = np.where(rng.random(n) < 0.8, "7", "1")
    digits = [f"{int(x):08d}" for x in rng.integers(0, 10**8, n)]
    phone = [f"+254{a}{d}" for a, d in zip(national, digits)]
    dom = rng.choice(["gmail.com", "yahoo.com", "outlook.com", "hotmail.com"], size=n, p=[0.6, 0.15, 0.15, 0.1])
    email = [f"{f.lower()}.{l.lower().replace(chr(39), '')}{int(k)}@{d}"
             for f, l, k, d in zip(first, last, rng.integers(1, 99, n), dom)]
    df = pd.DataFrame(dict(
        customer_id=[f"C{i + 1:04d}" for i in range(n)], first_name=first, last_name=last, gender=gender,
        date_of_birth=dob, phone=phone, email=email, county=county, signup_date=signup,
        preferred_payment=rng.choice(PAY, size=n, p=PAYP),
        loyalty_member=rng.choice(["Yes", "No"], size=n, p=[0.35, 0.65])))
    return df


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--lines", type=int, default=250000)
    ap.add_argument("--out", default="data")
    ap.add_argument("--seed", type=int, default=42)
    a = ap.parse_args()
    rng = np.random.default_rng(a.seed)
    os.makedirs(a.out, exist_ok=True)

    stores = make_stores(rng)
    products = make_products(rng)
    customers = make_customers(rng, stores)
    promos = pd.DataFrame(PROMOS, columns=["promo_id", "promo_name", "start_date", "end_date", "discount_pct",
                                           "category_targeted"])
    promos["start_date"] = pd.to_datetime(promos["start_date"])
    promos["end_date"] = pd.to_datetime(promos["end_date"])

    n_c, n_s, n_p = len(customers), len(stores), len(products)

    # ---- hidden customer behaviour (drives the patterns; not exported) ----
    loyalty = (customers.loyalty_member == "Yes").values
    activity = rng.gamma(0.9, 1.0, n_c) + 0.02
    activity = activity * np.where(loyalty, 1.3, 1.0)
    pact = activity / activity.sum()
    signup_day = (customers.signup_date - START).dt.days.values
    churn_day = np.full(n_c, 10**6)
    flag = rng.random(n_c) < 0.35
    lo = np.maximum(signup_day + 60, (pd.Timestamp("2023-01-01") - START).days)
    hi = (pd.Timestamp("2025-03-31") - START).days
    ok = flag & (lo < hi)
    churn_day[ok] = [int(rng.integers(l, hi)) for l in lo[ok]]
    pref = customers.preferred_payment.map({p: i for i, p in enumerate(PAY)}).values
    st_by_county = {c: np.where(stores.county.values == c)[0] for c in COUNTIES}
    home_store = np.array([rng.choice(st_by_county[c]) for c in customers.county])
    stype_w = stores.store_type.map({"Supermarket": 3.0, "Mini-mart": 1.5, "Kiosk": 0.6}).values
    ps = stype_w * rng.lognormal(0, 0.3, n_s)
    ps = ps / ps.sum()
    open_day = (stores.opening_date - START).dt.days.values
    early_stores = np.where(open_day <= 0)[0]

    # ---- day weights: seasonality, payday, weekend, growth, promo uplift ----
    days = pd.date_range(START, END)
    n_days = len(days)
    month_m = np.array([1.05, 0.92, 0.95, 1.0, 0.97, 0.95, 1.0, 1.02, 0.98, 1.0, 1.10, 1.45])
    w = month_m[days.month - 1]
    w = w * np.where(days.day >= 25, 1.25, np.where(days.day <= 3, 1.10, 1.0))
    w = w * np.array([1.0, 1.0, 1.0, 1.0, 1.10, 1.25, 1.10])[days.dayofweek]
    w = w * (1 + 0.008 * np.arange(n_days) / 30.4)
    for _, p in promos.iterrows():
        m = (days >= p.start_date) & (days <= p.end_date)
        w = np.where(m, w * (1 + p.discount_pct / 100 * 1.5), w)
    pday = w / w.sum()

    # ---- invoices ----
    n_inv = int(a.lines / 2.0)
    inv_day = rng.choice(n_days, size=n_inv, p=pday)
    walkin = rng.random(n_inv) < 0.04
    cust = rng.choice(n_c, size=n_inv, p=pact)
    for _ in range(60):
        bad = ~walkin & ((signup_day[cust] > inv_day) | (churn_day[cust] < inv_day))
        if not bad.any():
            break
        cust[bad] = rng.choice(n_c, size=int(bad.sum()), p=pact)
    bad = ~walkin & ((signup_day[cust] > inv_day) | (churn_day[cust] < inv_day))
    walkin |= bad
    cust = np.where(walkin, -1, cust)
    cc = np.maximum(cust, 0)

    store = np.where(walkin | (rng.random(n_inv) > 0.8), rng.choice(n_s, n_inv, p=ps), home_store[cc])
    nop = open_day[store] > inv_day
    store[nop] = rng.choice(early_stores, size=int(nop.sum()))

    pay = np.where(walkin, rng.choice(4, n_inv, p=[0.35, 0.50, 0.10, 0.05]),
                   np.where(rng.random(n_inv) < 0.85, pref[cc], rng.choice(4, n_inv, p=PAYP)))
    chan = rng.choice(3, n_inv, p=[0.80, 0.12, 0.08])
    pay = np.where((chan == 1) & (pay == 1), 0, pay)  # no cash for online orders
    lam = 1.4 + 0.5 * (pay == 0) + 0.2 * (pay == 2) + 0.3 * (~walkin & loyalty[cc])
    nl = 1 + rng.poisson(lam)

    cum = np.cumsum(nl)
    assert cum[-1] >= a.lines, "increase n_inv"
    k = int(np.searchsorted(cum, a.lines)) + 1
    nl = nl[:k].copy()
    nl[-1] -= int(cum[k - 1] - a.lines)
    inv_day, cust, store, pay, chan = inv_day[:k], cust[:k], store[:k], pay[:k], chan[:k]
    order = np.argsort(inv_day, kind="stable")
    inv_day, cust, store, pay, chan, nl = (x[order] for x in (inv_day, cust, store, pay, chan, nl))
    inv_no = np.array([f"INV{100001 + i}" for i in range(k)])

    # ---- lines ----
    idx = np.repeat(np.arange(k), nl)
    L = len(idx)
    ldays = inv_day[idx]
    ldate = START + pd.to_timedelta(ldays, unit="D")
    cat_codes = products.category.values
    pw = products.category.map(CAT_WEIGHT).values * rng.lognormal(0, 0.8, n_p)
    prod = rng.choice(n_p, size=L, p=pw / pw.sum())
    cat = cat_codes[prod]
    price = np.round(products.unit_price_kes.values[prod] * (1 + 0.06 * ldays / 365.25))

    promo_idx = np.full(L, -1)
    disc = np.zeros(L)
    for j, p in promos.iterrows():
        m = (ldate >= p.start_date) & (ldate <= p.end_date) & ((cat == p.category_targeted) | (p.category_targeted == "All"))
        promo_idx[m] = j
        disc[m] = p.discount_pct
    adhoc = (promo_idx < 0) & (rng.random(L) < 0.03)
    disc[adhoc] = rng.choice([5, 10], size=int(adhoc.sum()))

    qty = 1 + rng.poisson(0.7, L) + (cat == "Food Staples") * rng.poisson(0.8, L)
    qty = np.where(promo_idx >= 0, np.round(qty * 1.25), qty)
    qty = np.clip(qty, 1, 12).astype(int)
    ret = rng.random(L) < 0.005
    qty[ret] = -rng.integers(1, 4, int(ret.sum()))
    big = (rng.random(L) < 0.001) & (qty > 0)
    qty[big] = rng.integers(100, 500, int(big.sum()))
    price = np.where(rng.random(L) < 0.0005, price * 10, price)
    total = np.round(qty * price * (1 - disc / 100), 2)

    cust_ids = customers.customer_id.values
    tx = pd.DataFrame(dict(
        transaction_id=np.arange(1, L + 1), invoice_no=inv_no[idx], transaction_date=ldate,
        store_id=stores.store_id.values[store[idx]],
        customer_id=np.where(cust[idx] >= 0, cust_ids[np.maximum(cust[idx], 0)], None),
        product_id=products.product_id.values[prod], quantity=qty, unit_price_kes=price,
        discount_pct=disc.astype(int),
        promo_id=np.where(promo_idx >= 0, promos.promo_id.values[np.maximum(promo_idx, 0)], None),
        payment_method=np.array(PAY)[pay[idx]], line_total_kes=total, channel=np.array(CHANNELS)[chan[idx]]))

    # ---- integrity checks on the CLEAN data ----
    assert len(tx) == a.lines
    assert tx.store_id.isin(stores.store_id).all() and tx.product_id.isin(products.product_id).all()
    assert tx.customer_id.dropna().isin(customers.customer_id).all()
    assert tx.promo_id.dropna().isin(promos.promo_id).all()
    clean_tx = tx.copy()

    # ---- inject dirt (this is what gets exported) ----
    n = len(tx)
    ds = tx.transaction_date.dt.strftime("%Y-%m-%d").astype(object)
    alt = rng.random(n) < 0.05
    ds[alt] = tx.transaction_date.dt.strftime("%d/%m/%Y")[alt]
    ds[rng.random(n) < 0.015] = None
    tx["transaction_date"] = ds
    dups = tx.sample(frac=0.01, random_state=int(rng.integers(0, 10**6)))
    tx = pd.concat([tx, dups]).sort_index(kind="stable")

    cu = customers.copy()
    ci = np.where(rng.random(n_c) < 0.06)[0]
    cty = cu.county.values.astype(object)
    for i in ci:
        c, t = cty[i], rng.integers(0, 4)
        cty[i] = c.lower() if t == 0 else c.upper() if t == 1 else c + " " if t == 2 else ABBR.get(c, c.lower())
    cu["county"] = cty
    cu["gender"] = cu.gender.where(rng.random(n_c) >= 0.03, None)
    cu["email"] = cu.email.where(rng.random(n_c) >= 0.10, None)
    ph = cu.phone.where(rng.random(n_c) >= 0.03, None)
    loc = rng.random(n_c) < 0.10
    ph = ph.where(~(loc & ph.notna()), "0" + ph.str[4:])
    cu["phone"] = ph
    dobs = cu.date_of_birth.dt.strftime("%Y-%m-%d").astype(object)
    dobs[rng.random(n_c) < 0.02] = None
    dobs[rng.random(n_c) < 0.002] = "1900-01-01"
    cu["date_of_birth"] = dobs
    cu["signup_date"] = cu.signup_date.dt.strftime("%Y-%m-%d")
    cdup = cu.sample(frac=0.003, random_state=int(rng.integers(0, 10**6)))
    cu = pd.concat([cu, cdup]).sort_values("customer_id", kind="stable")

    st = stores.copy()
    st["opening_date"] = st.opening_date.dt.strftime("%Y-%m-%d")
    pr = promos.copy()
    pr["start_date"] = pr.start_date.dt.strftime("%Y-%m-%d")
    pr["end_date"] = pr.end_date.dt.strftime("%Y-%m-%d")

    for name, df in [("stores", st), ("products", products), ("customers", cu), ("promotions", pr),
                     ("transactions", tx)]:
        df.to_csv(os.path.join(a.out, f"{name}.csv"), index=False)
        print(f"{name}.csv: {len(df):,} rows x {df.shape[1]} cols")

    # ---- sanity report on the clean data (not exported) ----
    clean_tx["d"] = pd.to_datetime(clean_tx.transaction_date)
    daily = clean_tx.groupby("d").line_total_kes.sum()
    print("\nSanity report (clean data)")
    print("date range:", clean_tx.d.min().date(), "to", clean_tx.d.max().date())
    mon = daily.groupby(daily.index.month).mean()
    print("avg daily revenue Dec / Feb: %.2f" % (mon[12] / mon[2]))
    promo_days = set()
    for _, p in promos.iterrows():
        promo_days |= set(pd.date_range(p.start_date, p.end_date))
    isp = daily.index.isin(list(promo_days))
    print("avg daily revenue promo vs non-promo days (KES): %.0f vs %.0f" % (daily[isp].mean(), daily[~isp].mean()))
    inv = clean_tx.groupby("invoice_no").agg(pay=("payment_method", "first"), v=("line_total_kes", "sum"))
    print("avg invoice value by payment method:\n", inv.groupby("pay").v.mean().round(0).to_string())
    last = clean_tx.dropna(subset=["customer_id"]).groupby("customer_id").d.max()
    print("customers with a purchase:", len(last), "| no purchase in last 90 days: %.0f%%"
          % (100 * (last < END - pd.Timedelta(days=90)).mean()))


if __name__ == "__main__":
    main()
