"""
Synthetic retail data generator for Snowflake RetailIQ workshop.
Generates: stores, products, customers, orders, customer_reviews, support_tickets
"""

import os
import random
import math
from datetime import datetime, timedelta, date

import numpy as np
import pandas as pd
from faker import Faker

# ── Reproducibility ────────────────────────────────────────────────────────────
SEED = 42
random.seed(SEED)
np.random.seed(SEED)

fake_it = Faker("it_IT")
fake_en = Faker("en_GB")
fake_it.seed_instance(SEED)
fake_en.seed_instance(SEED)

OUTPUT_DIR = os.path.dirname(os.path.abspath(__file__))

# ── City / Region mapping ───────────────────────────────────────────────────────
CITY_REGION = {
    "Milano":           "Lombardia",
    "Roma":             "Lazio",
    "Firenze":          "Toscana",
    "Torino":           "Piemonte",
    "Napoli":           "Campania",
    "Bologna":          "Emilia-Romagna",
    "Venezia":          "Veneto",
    "Genova":           "Liguria",
    "Palermo":          "Sicilia",
    "Catania":          "Sicilia",
    "Bari":             "Puglia",
    "Verona":           "Veneto",
    "Padova":           "Veneto",
    "Trieste":          "Friuli-Venezia Giulia",
    "Trento":           "Trentino-Alto Adige",
    "Cagliari":         "Sardegna",
    "Perugia":          "Umbria",
    "Ancona":           "Marche",
    "Lecce":            "Puglia",
    "Reggio Calabria":  "Calabria",
}

CITIES = list(CITY_REGION.keys())

# Population-based weights for customer city distribution
CITY_WEIGHTS = [
    0.14, 0.14, 0.07, 0.08, 0.10, 0.06, 0.04, 0.04,
    0.05, 0.04, 0.04, 0.04, 0.04, 0.03, 0.02, 0.02,
    0.02, 0.02, 0.02, 0.02,
]

# Neighbourhood-style tags for store name suffixes
STORE_TAGS = {
    "Milano":          ["Duomo", "Navigli", "Brera", "Porta Nuova", "Centrale"],
    "Roma":            ["Termini", "Colosseo", "Prati", "Trastevere", "EUR"],
    "Firenze":         ["Duomo", "Oltrarno", "Santa Croce", "Pitti"],
    "Torino":          ["Centro", "Lingotto", "Porta Susa", "Crocetta"],
    "Napoli":          ["Centro Storico", "Mergellina", "Vomero", "Chiaia"],
    "Bologna":         ["Centro", "Fiera", "Zanardi", "Santo Stefano"],
    "Venezia":         ["Mestre", "Lido", "Cannaregio", "Dorsoduro"],
    "Genova":          ["Porto Antico", "Sampierdarena", "Sestri", "Marassi"],
    "Palermo":         ["Centro", "Mondello", "Ballarò", "Noce"],
    "Catania":         ["Centro", "Ognina", "San Giovanni", "Librino"],
    "Bari":            ["Murattiano", "Japigia", "Carbonara", "Poggiofranco"],
    "Verona":          ["Arena", "Veronetta", "Borgo Trento", "Golosine"],
    "Padova":          ["Centro", "Arcella", "Portello", "Prato della Valle"],
    "Trieste":         ["Centro", "Muggia", "Opicina", "Borgo Teresiano"],
    "Trento":          ["Centro", "Gardolo", "Mattarello", "Povo"],
    "Cagliari":        ["Marina", "Castello", "Villanova", "Stampace"],
    "Perugia":         ["Centro", "Fontivegge", "Monteluce", "Ferro di Cavallo"],
    "Ancona":          ["Centro", "Piano San Lazzaro", "Torrette", "Montacuto"],
    "Lecce":           ["Centro Storico", "Rudiae", "Salesiani", "Stadio"],
    "Reggio Calabria": ["Centro", "Sbarre", "Archi", "Gebbione"],
}

# ── Category / Subcategory / Product template data ────────────────────────────
CATEGORY_DATA = {
    "Electronics": {
        "weight": 0.25,
        "subcategories": ["Smartphones", "Laptops", "Audio", "Wearables", "Gaming", "Tablets", "Cameras"],
        "product_templates": [
            "Premium Wireless Headphones", "Smart Watch Pro", "Wireless Earbuds Ultra",
            "Portable Bluetooth Speaker", "4K Action Camera", "Gaming Headset RGB",
            "Noise Cancelling Headphones", "Smart Fitness Tracker", "Wireless Charging Pad",
            "Mechanical Gaming Keyboard", "Ergonomic Wireless Mouse", "USB-C Hub 7-in-1",
            "Portable Power Bank 20000mAh", "Smart Home Hub", "LED Ring Light Kit",
            "Webcam HD 1080p", "Digital Drawing Tablet", "Curved Gaming Monitor 27\"",
            "True Wireless Earphones", "Smart Speaker Voice Control",
            "Laptop Stand Adjustable", "External SSD 1TB", "Mini Projector Portable",
            "Smartphone Gimbal Stabilizer", "VR Headset Standalone",
            "Retro Gaming Console Mini", "Smart Doorbell Camera", "Robot Vacuum Pro",
            "Air Quality Monitor Smart", "Portable Translator Device",
            "Foldable Keyboard Bluetooth", "Solar Power Bank 10000mAh",
            "RGB LED Light Strip 5m", "Smart Plug WiFi Compatible",
            "Mechanical Pencil Digital", "Desktop Microphone Studio",
            "Multi-Port Fast Charger 65W", "Car Phone Mount Magnetic",
            "Dash Camera 4K Dual Lens", "Gaming Controller Wireless",
            "Laptop Cooling Pad RGB", "Smart Scale Body Composition",
            "Digital Photo Frame WiFi", "Neckband Sports Earphones",
            "Handheld Game Console Retro", "Smart Bulb RGB Dimmable",
            "Tablet Stand Adjustable 360", "Cable Management Kit",
            "Screen Cleaning Kit Pro", "Anti-Blue Light Glasses Gaming",
        ],
        "cost_range": (30, 500),
        "premium_cost_range": (150, 1200),
    },
    "Clothing & Apparel": {
        "weight": 0.30,
        "subcategories": ["Men's", "Women's", "Kids'", "Accessories", "Footwear", "Sportswear"],
        "product_templates": [
            "Classic Slim Fit Chinos", "Relaxed Linen Shirt", "Premium Cotton T-Shirt",
            "Merino Wool Sweater", "Waterproof Hiking Jacket", "Casual Denim Jacket",
            "Floral Wrap Dress", "High-Waist Yoga Pants", "Oversized Knit Jumper",
            "Sustainable Bamboo Socks Set", "Leather Belt Classic Brown",
            "Canvas Tote Bag Everyday", "Wide-Brim Sun Hat", "Knitted Beanie Unisex",
            "Silk Blouse Elegant", "Tailored Blazer Modern Fit",
            "Thermal Underwear Set", "Compression Running Socks",
            "Padded Winter Puffer Jacket", "Gym Shorts Quick-Dry",
            "Kids Dinosaur Print Hoodie", "Girls Tutu Skirt Rainbow",
            "Boys Cargo Trousers Fleece", "School Uniform Bundle",
            "Leather Gloves Driving Style", "Patterned Silk Scarf",
            "Recycled Fabric Backpack", "Genuine Leather Wallet Slim",
            "Polarised Sunglasses Unisex", "Baseball Cap Embroidered",
            "Ankle Boots Chelsea Style", "Minimalist Leather Sneakers",
            "Platform Sandals Summer", "Waterproof Trail Running Shoes",
            "Lightweight Slip-On Loafers", "Memory Foam Insoles",
            "Formal Oxford Shoes Classic", "Rain Boots Rubber Printed",
            "Dance Shoes Suede Sole", "Hiking Boots Gore-Tex",
        ],
        "cost_range": (8, 120),
        "premium_cost_range": (60, 400),
    },
    "Food & Beverage": {
        "weight": 0.20,
        "subcategories": ["Coffee & Tea", "Snacks & Confectionery", "Organic & Health", "Wine & Spirits", "Gourmet"],
        "product_templates": [
            "Single Origin Espresso Beans 500g", "Matcha Green Tea Premium Grade",
            "Organic Herbal Infusion Box 40", "Cold Brew Coffee Concentrate",
            "Artisan Dark Chocolate 85% Cacao", "Mixed Nuts Gift Box Premium",
            "Gourmet Truffle Salt 100g", "Extra Virgin Olive Oil DOP 500ml",
            "Raw Wildflower Honey 400g", "Organic Quinoa 1kg",
            "Freeze-Dried Fruit Mix 200g", "Protein Energy Bars Box 12",
            "Sparkling Water Flavoured 6-Pack", "Kombucha Ginger Lemon 330ml",
            "Oat Milk Barista Edition 1L", "Collagen Protein Powder Vanilla",
            "Vegan Protein Shake Chocolate", "Superfood Granola Blueberry",
            "Almond Butter Crunchy 340g", "Plant-Based Jerky Smoky BBQ",
            "Specialty Balsamic Vinegar Aged", "Sea Salt Caramel Popcorn 150g",
            "Pesto Artigianale Classico 180g", "Dried Porcini Mushrooms 50g",
            "Organic Chia Seeds 500g", "Cacao Nibs Raw Organic 200g",
            "Elderflower Cordial 500ml", "Craft Ginger Beer 4-Pack",
            "Green Smoothie Powder Blend", "Artisan Coffee Capsules 20-Pack",
        ],
        "cost_range": (3, 40),
        "premium_cost_range": (15, 120),
    },
    "Home & Garden": {
        "weight": 0.15,
        "subcategories": ["Kitchen", "Decor", "Garden Tools", "Bedding & Bath", "Storage & Organisation"],
        "product_templates": [
            "Cast Iron Skillet 26cm", "Bamboo Cutting Board Set",
            "Stainless Steel Water Bottle 1L", "Glass Meal Prep Containers 5-Pack",
            "Scented Soy Candle Vanilla Cedar", "Macramé Wall Hanging Large",
            "Ceramic Planter Set 3-Piece", "LED Fairy Lights Warm White 10m",
            "Indoor Plant Pot Terracotta", "Succulent Grow Kit Complete",
            "Vertical Garden Wall Planter", "Ergonomic Garden Kneeler Pad",
            "Stainless Pruning Shears Pro", "Watering Can Copper Finish 5L",
            "Egyptian Cotton Bath Towel Set", "Weighted Blanket 6kg",
            "Memory Foam Pillow Contour", "Linen Duvet Cover King",
            "Floating Shelves Set of 3", "Wicker Storage Basket Large",
            "Under-Bed Storage Boxes 2-Pack", "Stackable Kitchen Organiser",
            "Herb Garden Seed Kit 8 Varieties", "Beeswax Wrap Reusable 3-Pack",
            "French Press Coffee Maker 1L", "Ceramic Pour-Over Coffee Set",
            "Silicone Cooking Utensil Set", "Bamboo Kitchen Roll Holder",
            "Digital Kitchen Scale 5kg", "Mortar and Pestle Granite",
        ],
        "cost_range": (5, 80),
        "premium_cost_range": (40, 250),
    },
    "Sports & Outdoors": {
        "weight": 0.10,
        "subcategories": ["Fitness Equipment", "Outdoor Adventure", "Cycling", "Swimming", "Team Sports"],
        "product_templates": [
            "Adjustable Resistance Bands Set", "Neoprene Dumbbell Pair 5kg",
            "Yoga Mat Non-Slip Eco Cork", "Jump Rope Weighted Professional",
            "Foam Roller Deep Tissue Massage", "Pull-Up Bar Doorway No-Screw",
            "Gym Gloves Weight Lifting Pro", "Ab Wheel Roller with Knee Pad",
            "Suspension Trainer Full Body", "Kettlebell Cast Iron 12kg",
            "Trekking Pole Pair Collapsible", "Hydration Backpack 2L Bladder",
            "Camping Hammock Ultralight", "Waterproof Dry Bag 20L",
            "Folding Camping Chair Compact", "Sleeping Bag -10°C Mummy",
            "Headlamp LED 350 Lumens", "Multi-Tool Pocket Knife 14-in-1",
            "Road Bike Helmet MIPS Certified", "Cycling Gloves Touchscreen",
            "Bike Phone Mount Waterproof", "Inner Tube 700x28c Presta",
            "Swimming Goggles Anti-Fog UV", "Swim Cap Silicone Competition",
            "Water Polo Ball Size 4", "Football Training Cones 20-Pack",
            "Basketball Pump Digital Gauge", "Tennis Overgrip Pack of 3",
            "Badminton Shuttlecocks Feather 6-Pack", "Skipping Rope Speed Ball",
        ],
        "cost_range": (8, 150),
        "premium_cost_range": (50, 400),
    },
}

BRANDS = [
    "TechNova", "UrbanStyle", "GreenLeaf", "SportPeak", "CasaVerde",
    "NordLight", "PrimaCasa", "VeloForce", "AquaFlow", "SoloPro",
    "AlpinaGear", "BellaModa", "CraftBrew", "DolceVita", "EcoRoots",
    "FioreDesign", "GustoBono", "HighTrail", "ItalCore", "JoviStyle",
    "KombuLife", "LunaFit", "MilanEdge", "NaturaPura", "OrthoFlex",
    "PureBlend", "QuantumFit", "RomaClassic", "StudioVerde", "TuscanyHome",
]

# ── Review template pools ──────────────────────────────────────────────────────
REVIEW_TEMPLATES = {
    "Positive": {
        "Electronics": [
            "The battery life exceeded my expectations.",
            "Setup was surprisingly easy and everything worked right out of the box.",
            "The display quality is outstanding — colours are vivid and sharp.",
            "Sound quality is crystal clear, even at high volumes.",
            "Build quality feels solid and premium for the price.",
            "Connects instantly via Bluetooth and holds the connection perfectly.",
            "The touch sensitivity is very responsive.",
            "Much lighter than I expected which is great for daily use.",
            "The companion app is intuitive and feature-rich.",
            "Charging speed is impressive — full charge in under an hour.",
            "Great value for money compared to other brands.",
            "Works seamlessly with all my other devices.",
            "The noise cancellation is genuinely impressive.",
            "Image quality blew me away — so sharp and detailed.",
            "Really pleased with how ergonomic the design is.",
        ],
        "Clothing & Apparel": [
            "Perfect fit — I ordered my usual size and it was spot on.",
            "The fabric quality feels premium for the price.",
            "Colours are exactly as shown in the photos.",
            "I've already ordered the same item in another colour.",
            "Washes well and hasn't shrunk or faded at all.",
            "Very comfortable to wear all day long.",
            "The stitching is neat and everything looks well-made.",
            "Compliments every time I wear this.",
            "Lightweight yet surprisingly warm — ideal for layering.",
            "The zip and buttons feel sturdy, not cheap at all.",
            "Great range of sizes available.",
            "Love the sustainable materials used.",
        ],
        "Food & Beverage": [
            "The flavour is absolutely delicious — rich and well-balanced.",
            "Freshness is evident from the moment you open the packaging.",
            "A staple in my kitchen now — I buy this regularly.",
            "My family loved it, even the picky eaters.",
            "Packaging is eco-friendly and keeps everything fresh.",
            "The aroma is wonderful — fills the whole kitchen.",
            "Perfect balance of sweet and savoury.",
            "Really high quality ingredients — you can taste the difference.",
            "Great price for such a premium product.",
            "I've tried many similar products and this is by far the best.",
        ],
        "Home & Garden": [
            "Exactly what I needed for organising my space.",
            "Assembly was straightforward and took about 15 minutes.",
            "Looks even better in person than in the photos.",
            "Sturdy construction — feels like it will last for years.",
            "The design complements my home decor perfectly.",
            "My plants are thriving since I started using this.",
            "Very easy to clean and maintain.",
            "The size is perfect — fits exactly as I hoped.",
            "Great gift idea — my friend was thrilled with it.",
            "Really well thought-out design with attention to detail.",
        ],
        "Sports & Outdoors": [
            "Really helped improve my training sessions.",
            "Comfortable to wear even during long workouts.",
            "Durable construction — this is clearly built to last.",
            "Lightweight and easy to pack for travel.",
            "Performance matches or beats much more expensive alternatives.",
            "My recovery time has noticeably improved since using this.",
            "Grip and traction are excellent on all surfaces.",
            "Adjustable settings make it suitable for all fitness levels.",
            "Waterproofing works perfectly — stayed dry in heavy rain.",
            "Perfect for both beginners and more advanced athletes.",
        ],
        "General": [
            "Delivery was faster than expected — arrived the next day.",
            "Very well packaged — no damage at all.",
            "Customer service was helpful when I had a question.",
            "Would definitely recommend to friends and family.",
            "Five stars without hesitation.",
            "Exactly as described — no surprises.",
            "Great seller — fast shipping and good communication.",
            "This is now my go-to brand for this type of product.",
            "Highly satisfied with my purchase.",
            "Will definitely be ordering again.",
        ],
    },
    "Neutral": {
        "General": [
            "The product is decent for the price.",
            "Delivery was on time but the packaging could be better.",
            "It does what it says but nothing more.",
            "Average quality — neither impressed nor disappointed.",
            "Took a little longer than expected to arrive.",
            "Instructions could be clearer.",
            "The colour is slightly different from the photos.",
            "Works fine but feels a bit plasticky.",
            "It gets the job done, but I've seen better.",
            "OK product overall — a few minor issues but nothing major.",
            "Not bad for the price — sets realistic expectations.",
            "I'm on the fence — might try a different brand next time.",
            "Some features are good, others are a bit disappointing.",
            "Functional but lacks the premium feel I expected.",
            "Acceptable quality — meets the basic requirements.",
            "Mixed feelings about this one — pros and cons.",
            "The size runs slightly larger than expected.",
            "Setup took longer than it should have.",
            "Customer service response was slow but eventually helpful.",
            "Would consider repurchasing if the price drops.",
        ],
    },
    "Negative": {
        "Electronics": [
            "Stopped working after just two weeks — very disappointing.",
            "Customer service was unhelpful when I tried to get a replacement.",
            "The battery drains incredibly quickly — barely lasts a few hours.",
            "Connection keeps dropping — really frustrating to use.",
            "The build quality is very poor — feels like it will break easily.",
            "Screen has dead pixels that appeared within days.",
            "The app crashes constantly and has never worked properly.",
            "Sound quality is terrible — tinny and distorted at any volume.",
            "Arrived with the wrong accessories — not as advertised.",
            "Overheats within 30 minutes of use.",
        ],
        "Clothing & Apparel": [
            "Shrank significantly after the first wash despite following care instructions.",
            "The colour faded after just two washes.",
            "Stitching came undone within a week of wearing.",
            "The sizing is completely off — nothing like the size guide suggested.",
            "The material is itchy and uncomfortable against the skin.",
            "Looked nothing like the photos — very misleading listing.",
            "The zip broke after just three uses.",
            "Buttons fell off almost immediately.",
            "Strong chemical smell that doesn't wash out.",
            "Fabric is much thinner than it looks online.",
        ],
        "Food & Beverage": [
            "The product arrived with only two weeks until expiry — unacceptable.",
            "Packaging was damaged and the contents had spilled.",
            "The taste was nothing like described — completely different flavour profile.",
            "Found a foreign object inside the packaging — extremely concerning.",
            "Clearly not fresh — the product was already stale when it arrived.",
            "Misleading ingredients list — contains allergens not clearly stated.",
            "The portion size is much smaller than implied by the packaging.",
        ],
        "Home & Garden": [
            "Broke on first use — very poor quality materials.",
            "Instructions were completely wrong — steps were missing.",
            "Significant parts were missing from the box.",
            "Rust appeared within two weeks despite normal indoor use.",
            "The measurements listed were completely inaccurate.",
            "Scratched my floor during assembly.",
            "The colour looks nothing like the website images.",
        ],
        "Sports & Outdoors": [
            "Gave me blisters on the first use — poor design.",
            "The strap snapped during a light workout.",
            "Waterproofing failed completely in light rain.",
            "Much heavier than listed — impractical for trail use.",
            "The grip wore down after just a few sessions.",
        ],
        "Delivery": [
            "The item arrived damaged — the packaging was completely crushed.",
            "It took over 10 days to arrive, which is unacceptable.",
            "Still waiting for a resolution from customer services.",
            "Was left on the doorstep without any notification.",
            "The wrong item was delivered and returning it has been a nightmare.",
            "Tracking showed delivered but I never received anything.",
            "Delivery driver left it with a neighbour without asking.",
            "Package was left outside in the rain.",
        ],
    },
}

REGION_MENTIONS = [
    "Picked it up at the {city} store and the staff was very helpful.",
    "Bought this at the {city} branch — great in-store experience.",
    "The team at the {region} store were really knowledgeable.",
    "Fast delivery to {city} — arrived the next day.",
    "Ordered online and collected from the {city} location — very smooth.",
    "The {city} staff recommended this and they were absolutely right.",
]

# ── Support ticket template pools ──────────────────────────────────────────────
TICKET_TEMPLATES = {
    "Delivery Issue": [
        "My order {order_id} was supposed to arrive {days} days ago but I still haven't received it. The tracking number shows it's stuck in transit.",
        "I placed order {order_id} over a week ago and the status hasn't updated since it left the warehouse. Can someone look into this urgently?",
        "The tracking for {order_id} shows delivered but I was home all day and nothing arrived. My neighbour also confirms no package was left.",
        "My delivery for {order_id} was left outside in the rain and the contents are damaged. I need a replacement or refund.",
        "I received a notification that {order_id} was out for delivery but it never arrived. This is the second time this has happened.",
        "Order {order_id} shows a delivery attempt was made but no card was left and I was home. Please reschedule the delivery or issue a refund.",
        "The estimated delivery for {order_id} was {days} days ago. I've contacted the courier but they keep redirecting me to you.",
        "I urgently need order {order_id} for an event this weekend. Can you expedite shipping or arrange a same-day pickup?",
    ],
    "Product Quality": [
        "The item I received for order {order_id} doesn't match the description on the website. The colour is different and the build quality is much worse than expected.",
        "I purchased {order_id} and the product stopped working after just {days} days. This is completely unacceptable for the price I paid.",
        "My order {order_id} arrived with visible damage — it looks like it was dropped or mishandled during shipping.",
        "The product in order {order_id} is clearly a different model from what was advertised. The specifications are different.",
        "I've noticed a strong chemical smell from the item in order {order_id} that doesn't go away even after airing it out for several days.",
        "The sizing for order {order_id} is wildly inaccurate compared to your size guide. The item is at least two sizes smaller than stated.",
        "Order {order_id} was missing several components that are listed as included. Can you send the missing parts or process a refund?",
        "The item in order {order_id} broke on first use. The quality control on this product seems very poor.",
    ],
    "Returns & Refunds": [
        "I'd like to return my purchase from order {order_id} as it doesn't fit. I've been trying to get a prepaid return label for {days} days but haven't heard back.",
        "I changed my mind about order {order_id} and would like to return it within the 30-day window. Please advise on the return procedure.",
        "My return for order {order_id} was received by you {days} days ago according to the tracking, but I haven't received my refund yet.",
        "I returned the item from {order_id} in perfect condition with original packaging but received a reduced refund without any explanation.",
        "I need to exchange the item in order {order_id} for a different size. The current one is too small.",
        "I was charged a return fee for order {order_id} but your website clearly states returns are free within 30 days. Please refund this charge.",
        "I've been waiting {days} days for my refund for order {order_id}. My bank says there's no pending transaction from you.",
        "The return portal isn't accepting my order number {order_id}. I've tried multiple times. Please process this manually.",
    ],
    "Billing": [
        "I was charged twice for order {order_id}. Please check the transaction and process the duplicate charge refund immediately.",
        "I have a promotional discount code that wasn't applied to my order {order_id}. Please apply the discount retroactively.",
        "I was charged for order {order_id} but the payment should have been declined as I cancelled the order before it was processed.",
        "My loyalty points were not applied to order {order_id} despite being displayed in my cart at checkout.",
        "I see an unauthorised charge on my account from {days} days ago that doesn't correspond to any order I placed.",
        "The VAT receipt for order {order_id} shows the wrong amount. I need a corrected invoice for my business expense claim.",
        "I was not informed of the additional shipping charge applied to {order_id}. The total was higher than shown at checkout.",
        "Please update my payment method on file — my card ending in XXXX has expired.",
    ],
    "Technical Support": [
        "I can't log in to my account. I've tried resetting the password multiple times but the reset email never arrives.",
        "Your mobile app keeps crashing when I try to view my order history. I've reinstalled it twice and the problem persists.",
        "The website won't let me complete checkout. Every time I click confirm I get an error message.",
        "I'm unable to track my order {order_id} — the tracking page just shows a spinning loader.",
        "My loyalty account shows zero points but I have several completed orders. The points seem to have disappeared.",
        "I've been trying to cancel order {order_id} through the app but the cancel button is greyed out. Please cancel it manually.",
        "I'm not receiving any order confirmation emails despite my email address being correct in my account settings.",
        "The website shows my last address is incorrect and I can't update it before my next delivery.",
    ],
}


# ─────────────────────────────────────────────────────────────────────────────
# Helper utilities
# ─────────────────────────────────────────────────────────────────────────────

def fmt_id(prefix: str, n: int, width: int) -> str:
    return f"{prefix}{str(n).zfill(width)}"


def random_date(start: date, end: date, rng: np.random.Generator | None = None) -> date:
    delta = (end - start).days
    offset = (rng.integers(0, delta + 1) if rng else random.randint(0, delta))
    return start + timedelta(days=int(offset))


def seasonality_weight(d: date) -> float:
    """Higher weight in Nov-Dec, lower in Jan-Feb."""
    month = d.month
    weights = {1: 0.6, 2: 0.5, 3: 0.7, 4: 0.8, 5: 0.9, 6: 0.85,
               7: 0.85, 8: 0.7, 9: 0.85, 10: 1.0, 11: 1.5, 12: 2.0}
    return weights.get(month, 1.0)


def weighted_random_date(start: date, end: date, n: int) -> list[date]:
    """Sample n dates between start and end with seasonality weighting."""
    all_days = [start + timedelta(days=i) for i in range((end - start).days + 1)]
    weights = np.array([seasonality_weight(d) for d in all_days], dtype=float)
    weights /= weights.sum()
    chosen_indices = np.random.choice(len(all_days), size=n, p=weights)
    return [all_days[i] for i in chosen_indices]


def signup_date_weighted(n: int) -> list[date]:
    """More signups in recent years."""
    start = date(2018, 1, 1)
    end = date(2024, 6, 30)
    total_days = (end - start).days + 1
    all_days = [start + timedelta(days=i) for i in range(total_days)]
    # Linear growth from year 2018 to 2024
    weights = np.array([(d - start).days + 1 for d in all_days], dtype=float)
    weights /= weights.sum()
    chosen = np.random.choice(len(all_days), size=n, p=weights)
    return [all_days[i] for i in chosen]


def safe_text(s: str) -> str:
    """Ensure text is CSV-safe (remove embedded newlines)."""
    return str(s).replace("\n", " ").replace("\r", " ").strip()


def file_stats(path: str, n_rows: int) -> tuple[str, int, str]:
    size_bytes = os.path.getsize(path)
    if size_bytes < 1024:
        size_str = f"{size_bytes} B"
    elif size_bytes < 1024 ** 2:
        size_str = f"{size_bytes / 1024:.1f} KB"
    else:
        size_str = f"{size_bytes / 1024 ** 2:.1f} MB"
    return os.path.basename(path), n_rows, size_str


# ─────────────────────────────────────────────────────────────────────────────
# 1. STORES
# ─────────────────────────────────────────────────────────────────────────────

def generate_stores() -> pd.DataFrame:
    print("Generating stores.csv ...")
    n = 50
    store_types = np.random.choice(
        ["Standard", "Flagship", "Express", "Pop-Up"],
        size=n,
        p=[0.60, 0.20, 0.15, 0.05],
    )

    records = []
    city_cycle = list(CITIES) * 3  # enough to cover 50 stores
    random.shuffle(city_cycle)

    for i in range(n):
        store_id = fmt_id("STR_", i + 1, 3)
        city = city_cycle[i]
        region = CITY_REGION[city]
        tags = STORE_TAGS.get(city, ["Centro"])
        tag = random.choice(tags)
        store_name = f"RetailIQ {city} {tag}"
        store_type = store_types[i]
        opening_year = random.randint(2010, 2023)
        emp_ranges = {
            "Flagship": (40, 80),
            "Standard": (15, 35),
            "Express": (5, 15),
            "Pop-Up": (3, 8),
        }
        lo, hi = emp_ranges[store_type]
        employee_count = random.randint(lo, hi)

        records.append({
            "store_id": store_id,
            "store_name": store_name,
            "city": city,
            "region": region,
            "store_type": store_type,
            "opening_year": opening_year,
            "employee_count": employee_count,
        })

    df = pd.DataFrame(records)
    path = os.path.join(OUTPUT_DIR, "stores.csv")
    df.to_csv(path, index=False)
    print(f"  -> {len(df)} rows written.")
    return df


# ─────────────────────────────────────────────────────────────────────────────
# 2. PRODUCTS
# ─────────────────────────────────────────────────────────────────────────────

def generate_products() -> pd.DataFrame:
    print("Generating products.csv ...")
    n = 200
    categories = list(CATEGORY_DATA.keys())
    cat_weights = [CATEGORY_DATA[c]["weight"] for c in categories]

    chosen_cats = np.random.choice(categories, size=n, p=cat_weights)
    is_premium = np.random.choice([True, False], size=n, p=[0.20, 0.80])

    records = []
    for i in range(n):
        product_id = fmt_id("PRD_", i + 1, 3)
        cat = chosen_cats[i]
        cat_info = CATEGORY_DATA[cat]
        subcat = random.choice(cat_info["subcategories"])
        premium = bool(is_premium[i])

        cost_range = cat_info["premium_cost_range"] if premium else cat_info["cost_range"]
        unit_cost = round(random.uniform(*cost_range), 2)

        # Multiplier: 1.4–1.8 standard, 1.9–2.5 premium
        multiplier = random.uniform(1.9, 2.5) if premium else random.uniform(1.4, 1.8)
        list_price = round(unit_cost * multiplier, 2)

        # Pick product name from template pool, deduplicate with index suffix if needed
        base_name = random.choice(cat_info["product_templates"])
        # Add minor variation to avoid exact duplicates
        suffixes = ["", " v2", " Plus", " Pro", " Lite", " Elite", " Classic", " Mini"]
        product_name = base_name + random.choice(suffixes)

        brand = random.choice(BRANDS)

        records.append({
            "product_id": product_id,
            "category": cat,
            "subcategory": subcat,
            "product_name": product_name,
            "brand": brand,
            "unit_cost": unit_cost,
            "list_price": list_price,
            "is_premium": premium,
        })

    df = pd.DataFrame(records)
    path = os.path.join(OUTPUT_DIR, "products.csv")
    df.to_csv(path, index=False)
    print(f"  -> {len(df)} rows written.")
    return df


# ─────────────────────────────────────────────────────────────────────────────
# 3. CUSTOMERS
# ─────────────────────────────────────────────────────────────────────────────

def generate_customers() -> pd.DataFrame:
    print("Generating customers.csv ...")
    n = 5000
    use_italian = np.random.choice([True, False], size=n, p=[0.70, 0.30])

    cw = np.array(CITY_WEIGHTS, dtype=float)
    cw /= cw.sum()
    cities_chosen = np.random.choice(CITIES, size=n, p=cw)
    tiers = np.random.choice(
        ["Bronze", "Silver", "Gold", "Platinum"],
        size=n,
        p=[0.50, 0.30, 0.15, 0.05],
    )
    age_groups = np.random.choice(
        ["18-25", "26-35", "36-50", "50+"],
        size=n,
        p=[0.15, 0.30, 0.35, 0.20],
    )
    signup_dates = signup_date_weighted(n)

    records = []
    for i in range(n):
        customer_id = fmt_id("CUST_", i + 1, 5)
        if use_italian[i]:
            first = fake_it.first_name()
            last = fake_it.last_name()
        else:
            first = fake_en.first_name()
            last = fake_en.last_name()

        first_clean = first.lower().replace(" ", "").replace("'", "")
        last_clean = last.lower().replace(" ", "").replace("'", "")
        domains = ["gmail.com", "yahoo.it", "hotmail.it", "libero.it",
                   "outlook.com", "icloud.com", "email.it", "virgilio.it"]
        email = f"{first_clean}.{last_clean}{random.randint(1, 99)}@{random.choice(domains)}"

        city = cities_chosen[i]
        region = CITY_REGION[city]
        records.append({
            "customer_id": customer_id,
            "first_name": first,
            "last_name": last,
            "email": email,
            "city": city,
            "region": region,
            "country": "Italy",
            "signup_date": signup_dates[i].strftime("%Y-%m-%d"),
            "loyalty_tier": tiers[i],
            "age_group": age_groups[i],
        })

    df = pd.DataFrame(records)
    path = os.path.join(OUTPUT_DIR, "customers.csv")
    df.to_csv(path, index=False)
    print(f"  -> {len(df)} rows written.")
    return df


# ─────────────────────────────────────────────────────────────────────────────
# 4. ORDERS
# ─────────────────────────────────────────────────────────────────────────────

def generate_orders(
    stores_df: pd.DataFrame,
    products_df: pd.DataFrame,
    customers_df: pd.DataFrame,
) -> pd.DataFrame:
    print("Generating orders.csv ...")
    n = 50_000

    customer_ids = customers_df["customer_id"].tolist()
    product_ids = products_df["product_id"].tolist()
    store_ids = stores_df["store_id"].tolist() + ["ONLINE"]  # ONLINE for online orders

    # Build product price lookup
    price_map = dict(zip(products_df["product_id"], products_df["list_price"]))

    # Weighted dates with seasonality
    start_date = date(2022, 1, 1)
    end_date = date(2024, 12, 31)
    order_dates = weighted_random_date(start_date, end_date, n)

    channels = np.random.choice(
        ["In-Store", "Online", "Mobile App"],
        size=n,
        p=[0.45, 0.40, 0.15],
    )
    statuses = np.random.choice(
        ["Completed", "Returned", "Cancelled", "Pending"],
        size=n,
        p=[0.80, 0.10, 0.07, 0.03],
    )

    records = []
    for i in range(n):
        order_id = fmt_id("ORD_", i + 1, 6)
        cust_id = random.choice(customer_ids)
        prod_id = random.choice(product_ids)

        channel = channels[i]
        status = statuses[i]

        # Store: In-Store picks a real store; Online/App may pick ONLINE
        if channel == "In-Store":
            store_id = random.choice(stores_df["store_id"].tolist())
        else:
            # 70% ONLINE bucket, 30% pick a real store (click & collect)
            if random.random() < 0.70:
                store_id = "ONLINE"
            else:
                store_id = random.choice(stores_df["store_id"].tolist())

        order_date = order_dates[i]

        # Quantity
        if random.random() < 0.80:
            quantity = random.randint(1, 2)
        else:
            quantity = random.randint(3, 5)

        # Price variation ±5%
        base_price = price_map[prod_id]
        unit_price = round(base_price * random.uniform(0.95, 1.05), 2)

        # Discount
        disc_draw = random.random()
        if disc_draw < 0.60:
            discount_pct = 0.0
        elif disc_draw < 0.85:
            discount_pct = round(random.uniform(0.05, 0.10), 2)
        else:
            discount_pct = round(random.uniform(0.15, 0.25), 2)

        total_amount = round(quantity * unit_price * (1 - discount_pct), 2)

        return_flag = status == "Returned"

        # Shipping
        if channel == "In-Store":
            shipping_days = 0
        else:
            shipping_days = random.randint(1, 7)

        records.append({
            "order_id": order_id,
            "customer_id": cust_id,
            "product_id": prod_id,
            "store_id": store_id,
            "order_date": order_date.strftime("%Y-%m-%d"),
            "quantity": quantity,
            "unit_price": unit_price,
            "discount_pct": discount_pct,
            "total_amount": total_amount,
            "channel": channel,
            "status": status,
            "return_flag": return_flag,
            "shipping_days": shipping_days,
        })

    df = pd.DataFrame(records)
    path = os.path.join(OUTPUT_DIR, "orders.csv")
    df.to_csv(path, index=False)
    print(f"  -> {len(df)} rows written.")
    return df


# ─────────────────────────────────────────────────────────────────────────────
# 5. CUSTOMER REVIEWS
# ─────────────────────────────────────────────────────────────────────────────

def build_review_text(sentiment: str, category: str, city: str, region: str) -> str:
    """Compose a 2-4 sentence review from template pools."""
    cat_pool_pos = REVIEW_TEMPLATES["Positive"].get(category, [])
    cat_pool_neg = REVIEW_TEMPLATES["Negative"].get(category, [])
    general_pos = REVIEW_TEMPLATES["Positive"]["General"]
    neutral_pool = REVIEW_TEMPLATES["Neutral"]["General"]
    delivery_neg = REVIEW_TEMPLATES["Negative"]["Delivery"]

    if sentiment == "Positive":
        pool = cat_pool_pos + general_pos
        n_sentences = random.randint(2, 4)
        sentences = random.sample(pool, min(n_sentences, len(pool)))
        # Occasionally add region mention
        if random.random() < 0.15:
            tmpl = random.choice(REGION_MENTIONS)
            sentences.insert(0, tmpl.format(city=city, region=region))
    elif sentiment == "Neutral":
        pool = neutral_pool + cat_pool_pos[:3] + cat_pool_neg[:2]
        n_sentences = random.randint(2, 3)
        sentences = random.sample(pool, min(n_sentences, len(pool)))
    else:  # Negative
        pool = cat_pool_neg + delivery_neg
        if not pool:
            pool = delivery_neg
        n_sentences = random.randint(2, 4)
        sentences = random.sample(pool, min(n_sentences, len(pool)))

    return safe_text(" ".join(sentences))


def generate_reviews(
    orders_df: pd.DataFrame,
    products_df: pd.DataFrame,
    stores_df: pd.DataFrame,
) -> pd.DataFrame:
    print("Generating customer_reviews.csv ...")
    n = 15_000

    # Only completed orders can have reviews
    completed = orders_df[orders_df["status"] == "Completed"].copy()
    sampled = completed.sample(n=n, replace=True, random_state=SEED).reset_index(drop=True)

    # Build lookups
    prod_map = products_df.set_index("product_id")[["product_name", "category"]].to_dict("index")
    store_map = stores_df.set_index("store_id")["region"].to_dict()
    store_map["ONLINE"] = "Online"

    # Ratings with sentiment correlation
    sentiment_choices = np.random.choice(
        ["Positive", "Neutral", "Negative"],
        size=n,
        p=[0.65, 0.20, 0.15],
    )

    records = []
    for i in range(n):
        review_id = fmt_id("REV_", i + 1, 6)
        row = sampled.iloc[i]

        prod_id = row["product_id"]
        product_name = prod_map[prod_id]["product_name"]
        category = prod_map[prod_id]["category"]

        store_id = row["store_id"]
        store_region = store_map.get(store_id, "Online")

        # City for region mentions — derive from store or default to Roma
        city_for_review = "Roma"
        if store_id != "ONLINE":
            store_row = stores_df[stores_df["store_id"] == store_id]
            if not store_row.empty:
                city_for_review = store_row.iloc[0]["city"]

        sentiment = sentiment_choices[i]
        if sentiment == "Positive":
            rating = random.choices([4, 5], weights=[0.35, 0.65])[0]
        elif sentiment == "Neutral":
            rating = 3
        else:
            rating = random.choices([1, 2], weights=[0.45, 0.55])[0]

        order_date = datetime.strptime(row["order_date"], "%Y-%m-%d").date()
        review_date = order_date + timedelta(days=random.randint(2, 30))

        review_text = build_review_text(sentiment, category, city_for_review, store_region)
        verified = random.random() < 0.90

        records.append({
            "review_id": review_id,
            "order_id": row["order_id"],
            "customer_id": row["customer_id"],
            "product_id": prod_id,
            "product_name": product_name,
            "category": category,
            "store_region": store_region,
            "rating": rating,
            "sentiment_label": sentiment,
            "review_date": review_date.strftime("%Y-%m-%d"),
            "review_text": review_text,
            "verified_purchase": verified,
        })

    df = pd.DataFrame(records)
    path = os.path.join(OUTPUT_DIR, "customer_reviews.csv")
    df.to_csv(path, index=False, quoting=1)  # QUOTE_ALL for text safety
    print(f"  -> {len(df)} rows written.")
    return df


# ─────────────────────────────────────────────────────────────────────────────
# 6. SUPPORT TICKETS
# ─────────────────────────────────────────────────────────────────────────────

def build_ticket_text(category: str, order_id: str | None) -> str:
    """Compose a support ticket from template pools."""
    templates = TICKET_TEMPLATES.get(category, TICKET_TEMPLATES["Delivery Issue"])
    days = random.randint(3, 14)
    tmpl = random.choice(templates)
    text = tmpl.format(
        order_id=order_id or "ORD_XXXXXX",
        days=days,
    )
    # Optionally append a follow-up sentence
    follow_ups = [
        " Please resolve this as soon as possible.",
        " I would appreciate a prompt response.",
        " This is quite urgent as I need it for a gift.",
        " I have been a loyal customer for years and this is very disappointing.",
        " I have all receipts and documentation ready to send.",
        " I am happy to provide any additional details you need.",
    ]
    if random.random() < 0.6:
        text += random.choice(follow_ups)
    return safe_text(text)


def generate_support_tickets(orders_df: pd.DataFrame) -> pd.DataFrame:
    print("Generating support_tickets.csv ...")
    n = 8_000

    # Priority pool: returned/cancelled orders more likely to have tickets
    problem_orders = orders_df[orders_df["status"].isin(["Returned", "Cancelled"])].copy()
    other_orders = orders_df[orders_df["status"].isin(["Completed", "Pending"])].copy()

    # 60% from problem orders, 40% random
    n_problem = min(int(n * 0.60), len(problem_orders))
    n_random = n - n_problem

    sampled_problem = problem_orders.sample(
        n=n_problem, replace=True, random_state=SEED
    ).reset_index(drop=True)
    sampled_random = other_orders.sample(
        n=n_random, replace=True, random_state=SEED + 1
    ).reset_index(drop=True)
    sampled = pd.concat([sampled_problem, sampled_random]).reset_index(drop=True)
    sampled = sampled.sample(frac=1, random_state=SEED).reset_index(drop=True)

    categories = np.random.choice(
        ["Delivery Issue", "Product Quality", "Returns & Refunds", "Billing", "Technical Support"],
        size=n,
        p=[0.30, 0.25, 0.20, 0.15, 0.10],
    )
    priorities = np.random.choice(
        ["Low", "Medium", "High", "Critical"],
        size=n,
        p=[0.40, 0.35, 0.20, 0.05],
    )
    statuses = np.random.choice(
        ["Resolved", "Closed", "In Progress", "Open"],
        size=n,
        p=[0.65, 0.20, 0.10, 0.05],
    )

    start_ts = datetime(2022, 1, 1)
    end_ts = datetime(2024, 12, 31)
    total_seconds = int((end_ts - start_ts).total_seconds())

    records = []
    for i in range(n):
        ticket_id = fmt_id("TKT_", i + 1, 6)
        row = sampled.iloc[i]
        category = categories[i]
        priority = priorities[i]
        status = statuses[i]

        # created_at: random within 2022-2024, after order date
        order_dt = datetime.strptime(row["order_date"], "%Y-%m-%d")
        offset_min = max(0, int((order_dt - start_ts).total_seconds()))
        created_at = start_ts + timedelta(seconds=random.randint(offset_min, total_seconds))

        # resolved_at
        if status in ("Open", "In Progress"):
            resolved_at = None
        else:
            resolution_map = {
                "Resolved": (2, 48),
                "Closed": (24, 120),
            }
            lo, hi = resolution_map.get(status, (2, 72))
            resolution_hours = random.randint(lo, hi)
            resolved_at = (created_at + timedelta(hours=resolution_hours)).strftime(
                "%Y-%m-%dT%H:%M:%S"
            )

        ticket_text = build_ticket_text(category, row["order_id"])

        records.append({
            "ticket_id": ticket_id,
            "customer_id": row["customer_id"],
            "order_id": row["order_id"],
            "category": category,
            "priority": priority,
            "status": status,
            "created_at": created_at.strftime("%Y-%m-%dT%H:%M:%S"),
            "resolved_at": resolved_at,
            "ticket_text": ticket_text,
        })

    df = pd.DataFrame(records)
    path = os.path.join(OUTPUT_DIR, "support_tickets.csv")
    df.to_csv(path, index=False, quoting=1)
    print(f"  -> {len(df)} rows written.")
    return df


# ─────────────────────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────────────────────

def main():
    print("=" * 60)
    print("RetailIQ Synthetic Data Generator")
    print(f"Output directory: {OUTPUT_DIR}")
    print("=" * 60)

    stores_df = generate_stores()
    products_df = generate_products()
    customers_df = generate_customers()
    orders_df = generate_orders(stores_df, products_df, customers_df)
    reviews_df = generate_reviews(orders_df, products_df, stores_df)
    tickets_df = generate_support_tickets(orders_df)

    # ── Verification stats ─────────────────────────────────────────────────────
    print("\n" + "=" * 60)
    print("VERIFICATION STATS")
    print("=" * 60)

    # FK integrity
    valid_custs = set(customers_df["customer_id"])
    valid_prods = set(products_df["product_id"])
    valid_stores = set(stores_df["store_id"]) | {"ONLINE"}

    bad_custs = (~orders_df["customer_id"].isin(valid_custs)).sum()
    bad_prods = (~orders_df["product_id"].isin(valid_prods)).sum()
    bad_stores = (~orders_df["store_id"].isin(valid_stores)).sum()
    print(f"Orders FK violations — customer_id: {bad_custs}, product_id: {bad_prods}, store_id: {bad_stores}")

    # Order status distribution
    print("\nOrder status distribution:")
    print(orders_df["status"].value_counts().to_string())

    # Review rating distribution
    print("\nReview rating distribution:")
    print(reviews_df["rating"].value_counts().sort_index().to_string())

    # Ticket category distribution
    print("\nTicket category distribution:")
    print(tickets_df["category"].value_counts().to_string())

    # ── Summary table ──────────────────────────────────────────────────────────
    print("\n" + "=" * 60)
    print("GENERATED FILES SUMMARY")
    print("=" * 60)
    files = [
        ("stores.csv", len(stores_df)),
        ("products.csv", len(products_df)),
        ("customers.csv", len(customers_df)),
        ("orders.csv", len(orders_df)),
        ("customer_reviews.csv", len(reviews_df)),
        ("support_tickets.csv", len(tickets_df)),
    ]
    print(f"{'File':<30} {'Rows':>8}  {'Size':>10}")
    print("-" * 52)
    for fname, nrows in files:
        fpath = os.path.join(OUTPUT_DIR, fname)
        _, _, size_str = file_stats(fpath, nrows)
        print(f"{fname:<30} {nrows:>8,}  {size_str:>10}")
    print("=" * 60)
    print("Done.")


if __name__ == "__main__":
    main()
