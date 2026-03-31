"""
seed_news.py — Populate the Firestore `news/` collection with sample articles.

Usage:
    pip install firebase-admin
    python3 scripts/seed_news.py

Credentials: place your service-account JSON in the same directory as this
script, or set the GOOGLE_APPLICATION_CREDENTIALS environment variable.
"""

import os
import sys
from datetime import datetime, timezone
import firebase_admin
from firebase_admin import credentials, firestore

# ---------------------------------------------------------------------------
# Auth
# ---------------------------------------------------------------------------

_SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
_DEFAULT_KEY = os.path.join(_SCRIPT_DIR, "serviceAccountKey.json")
_KEY_PATH = os.environ.get("GOOGLE_APPLICATION_CREDENTIALS", _DEFAULT_KEY)

if not os.path.exists(_KEY_PATH):
    print(f"[error] Service-account key not found at: {_KEY_PATH}")
    print("        Copy your Firebase service-account JSON there, or set")
    print("        GOOGLE_APPLICATION_CREDENTIALS to its path.")
    sys.exit(1)

cred = credentials.Certificate(_KEY_PATH)
firebase_admin.initialize_app(cred)
db = firestore.client()

# ---------------------------------------------------------------------------
# Sample news articles
# ---------------------------------------------------------------------------

def ts(year: int, month: int, day: int):
    return datetime(year, month, day, tzinfo=timezone.utc)

NEWS_ITEMS = [
    {
        "title": "Introducing HOYA iD MySelf — Personalised Progressive Lenses",
        "body": (
            "HOYA's new iD MySelf progressive lens uses binocular eye-model "
            "technology to calculate a unique lens design for each individual. "
            "By measuring both eyes together rather than separately, iD MySelf "
            "delivers up to 40 % wider visual fields and significantly reduced "
            "peripheral distortion. Available exclusively through authorised "
            "HOYA optician partners from April 2026."
        ),
        "category": "product",
        "publishedAt": ts(2026, 3, 20),
        "imageUrl": None,
    },
    {
        "title": "SEIKO Superclear 3.0 Anti-Reflective Coating Now Available",
        "body": (
            "The updated Superclear 3.0 coating reduces surface reflections by "
            "a further 15 % compared to the previous generation, and adds an "
            "improved water-repellent layer that resists smudges and fingerprints "
            "for longer. The coating is now standard on all SEIKO single-vision "
            "and progressive lens orders placed through your partner optician."
        ),
        "category": "product",
        "publishedAt": ts(2026, 3, 10),
        "imageUrl": None,
    },
    {
        "title": "Spring Checkup Reminder — Book Your Annual Eye Examination",
        "body": (
            "Regular eye examinations are the best way to catch changes in your "
            "vision early. Optometrists recommend a full check every 12 months "
            "for contact lens wearers and every 24 months for spectacle users. "
            "Open the app, tap 'Find Optician', and book your nearest SEIKO "
            "partner store — many offer extended hours through April and May."
        ),
        "category": "service",
        "publishedAt": ts(2026, 3, 1),
        "imageUrl": None,
    },
    {
        "title": "5 Tips for Caring for Your Progressive Lenses",
        "body": (
            "1. Always rinse lenses under lukewarm water before wiping — dry "
            "wiping scratches coatings. "
            "2. Use the microfibre cloth provided by your optician; paper tissues "
            "leave fine scratches. "
            "3. Store glasses in a hard case when not in use. "
            "4. Avoid leaving glasses on a car dashboard — heat above 60 °C "
            "can warp frames and delaminate coatings. "
            "5. Have your lenses professionally cleaned and your frame adjusted "
            "at least once a year."
        ),
        "category": "care",
        "publishedAt": ts(2026, 2, 15),
        "imageUrl": None,
    },
    {
        "title": "SEIKO Optician Partner Programme — Spring 2026 Offer",
        "body": (
            "SEIKO is extending an exclusive spring offer to all registered app "
            "users: present your digital lens passport at any participating SEIKO "
            "partner store and receive 10 % off your next lens order. The offer "
            "runs from 1 April to 31 May 2026 and cannot be combined with other "
            "promotions. Find your nearest participating store using the "
            "'Find Optician' feature in the app."
        ),
        "category": "offer",
        "publishedAt": ts(2026, 2, 1),
        "imageUrl": None,
    },
]

# ---------------------------------------------------------------------------
# Write to Firestore
# ---------------------------------------------------------------------------

collection = db.collection("news")

print(f"Seeding {len(NEWS_ITEMS)} news items into `news/` collection...")
for item in NEWS_ITEMS:
    _ref = collection.add(item)
    print(f"  ✓ {item['title'][:60]}")

print("\nDone. Verify in Firebase Console → Firestore → news/")
