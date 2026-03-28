"""
Dans le projet il ne doit pas avoir des valeurs en dur (HARDCODING)
dans le code, alors on utilise des fichiers de configuration pour prevenir
les erreurs de duplication,
les chemins ecrits en dur,
et pour faciliter la maintenance du code.

Centralisation des Chemins
"""

from pathlib import Path

BASE_DIR = Path(__file__).resolve().parents[2]
DATA_DIR = BASE_DIR / "data"

ORDERS_FILE = DATA_DIR / "orders.csv"
CUSTOMERS_FILE = DATA_DIR / "customers.csv"
ORDER_ITEMS_FILE = DATA_DIR / "order_items.csv"
COURIERS_FILE = DATA_DIR / "couriers.csv"
