# Projet_1-Data_IA_enginner
This project is an exercise designed to put you in the shoes of a Data and AI Engineer at a city-based delivery company called Nexacommerce. In this exercise, your aim will be to work as a Junior Data Engineer at this company, structuring their database, cleaning the data and making it usable – in short, transforming operational chaos into a credible basis for decision-making by answering the business’s four key questions: how many active customers are there?  What is the actual delay rate? Which cities and time slots perform best?  And which products are generating revenue that poses a problem for sales?


## 📋 Table des Matières

- [Contexte](#-contexte)
- [Three of Projet](#-three-of-projet)
- [Require](#-require)
- [Installation ](#-installation)
- [Data](#-data)
- [Using](#-using)
- [Tests](#-tests)
- [Résultats Clés](#-résultats-clés)
---

## 🎯 Contexte

**NexaCommerce Cameroun** is a start-up founded in 2021 specialising in e-commerce and local delivery in Douala, Yaoundé and Bafoussam. Between 2022 and 2024, order volume grew by **+211%** — leaving behind a significant technical legacy: scattered data, inconsistent formats, massive amounts of duplicate data, and no reliable metrics.

Ce projet pose les **fondations data** de NexaCommerce en 4 semaines :

| Semaine | Objectif | Livrable |
|---|---|---|
| S1 | python environement and inspect data | repository Git  | Three of projet
| S2 | Audit SQL  | Script SQL + vue `v_order_kpis` | sql
| S3 | Analyse performance statistical | Notebook  | Notebook statistics
| S4 | EDA completly | Notebook  | Notebook EDA_rapport_final + Plotly + searbon + matplotlib figure

---

## 🗂 Three of Projet

```
nexacommerce-data/
│
├── 📄 README.md                        # This file
├── 📄 pyproject.toml                   # Poetry Deps
├── 📄 .pre-commit-config.yaml          # Black + Flake8
├── 📄 .gitignore
├── 📄 .env.example                     # Template variables d'environnement
├── 📄 .flake8                          # Double lint or linter
├── 📄 .pre-commit-config.yaml          # build before commit
├── 📄 .dockerignore
│
├── 📁 data/                            # Dataset
│   ├── orders.csv
│   ├── customers.csv
│   ├── order_items.csv
│   └── couriers.csv
│   └── reports/                         # Data clean
│       │--- orders.csv                  # 12500 commandes
│       │--- customers.csv               # 2149 customers
│       │--- couriers.csv                # 49 couriers
│       │--- order_items.csv             #+30000 order_items
│       │--- audit_deduplication.csv     # Customers verification
├── 📁 src/
│   │---nexacommerce
│       ├── __init__.py
│       ├── config.py                       # HardCoding
│       ├── data_loader.py                  # CSV
│       ├── inspector.py                    # Audit dataFrame
│
├── 📁 sql/
│   ├── audit_qualité.sql               # Audit qualité
│   ├── window_fonction.sql             # fenêtrage,
│   ├── vue_order.sql                   # Vue v_order_kpis
│   ├── CA.sql                          # CTE
│   └── dedup_customers.sql             # Déduplication customers
│
├── 📁 notebooks/
│   ├── statitcs.ipynb                  # Exploration
│   └── EDA_rapport_Final.ipynb         # Image for final report
│
├── 📁 tests/
│   ├── __init__.py
│   ├── test_data_loader.py
│   ├── test_inspector.py
│
├── 📁 reports/                         # Figures
│
│
└── DockerFile                          # Docker
```

---

## ⚙️ Require

| Outil | Version minimale | Vérification |
|---|---|---|
| Python | 3.11+ | `python --version` |
| Poetry | 1.7+ | `poetry --version` |
| MySQL | 8.0+ | `mysql --version` |

> **Note** : MySQL as required for script SQL (Semaine 2).
> Notebooks Python with use at (Semaines 1, 3, 4) .

---

## 🚀 Installation

### 1. Take the reporisitory

```bash
git clone https://github.com/codeur63/nexacommerce-data.git
cd nexacommerce-data
```

### 2. Install Poetry and dependancy

```bash
# Installer Poetry si nécessaire
curl -sSL https://install.python-poetry.org | python3 -

# Installer toutes les dépendances
poetry install

# Activer l'environnement virtuel
poetry shell
```

### 3. Config environement

When you extract data with BD or upload data we use :
```bash
# Copier le template
cp .env.example .env

# Éditer avec vos paramètres MySQL
nano .env
```

Contenu de `.env` :
```env
DB_HOST=localhost
DB_PORT=3306
DB_NAME=nexacommerce
DB_USER=root
DB_PASSWORD=your_password
DB_URL=mysql+pymysql://root:your_password@localhost:3306/nexacommerce
```

### 4. Config & install pre-commit

```bash
pre-commit install
pre-commit run --all-files   # Vérification initiale
```


### 5. Vérifier l'installation

```bash
# Lancer les tests
poetry run pytest tests/ -v --cov=src --cov-report=term-missing

# Résultat attendu : toutes les tests PASSED, coverage > 60 %
```

---

## 📊 Data

| Fichier | Lignes | Colonnes | Description |
|---|---|---|---|
| `orders.csv` | 12 500 | 12 | Commandes 2022–2025 avec impuretés documentées |
| `customers.csv` | 2 380 | 7 | Clients avec ~280 doublons identifiés |
| `order_items.csv` | ~31 000 | 8 | Détail produits par commande |
| `couriers.csv` | 47 | 8 | Livreurs partenaires |

---

###  Audit

| Référence | Colonne | Problème | Ampleur |
|---|---|---|---|
| P1 | `order_date` | 6 formats | ~12 % no parse |
| P2 | `status` | 17 variation | 100 %  |
| P3 | `city` | 14 variation | 100 %  |
| P4 | `customers.phone` | 6 formats, ~230 double | ~12 % double |
| P5 | `total_amount_xaf` | Negative amount + NULL | ~5 % aberrants |
| P6 | `product_category` | ~15 % NULL, 30+ variantes | ~15 % NULL |
| P8 | `customer_id` (FK) | Orphan take | ~3 % |
| p9 | `order_items` | if group total_amount for order_id the amount is much different with total_amount_xaf on table orders

> ⚠️ **don't modify a file into  `data/`.**
> All transformation will be applicate in the notebook for details.

---

## 💻 Using

### Python Pipeline

```python
from src.data_loader import DataLoader
from src.inspector import inspect_dataset
from src.cleaner import clean_orders, clean_customers

# Load
loader = DataLoader()
orders, customers = loader.load("orders"), loader.load("customers")

# Inspection
rapport = inspect_dataset(orders, name="orders")
print(rapport)

# Cleaning
orders_clean    = clean_orders(orders)
customers_clean = clean_customers(customers)
```

### Notebooks Jupyter

When we use notebook take :

```bash
# Lancer JupyterLab
poetry run jupyter lab

copy token ex:(http://localhost:8888/lab?token=35b31ca78a301bcefc7177b1086ce98e6ee23315683efb74) and paste to your navigator


```

---

## 🧪 Tests

```bash
# Tous les tests avec couverture
poetry run pytest tests/ -v --cov=src --cov-report=term-missing

# Un module spécifique
poetry run pytest tests/test_data_loader.py -v

# Rapport HTML de couverture
poetry run pytest --cov=src --cov-report=html
open htmlcov/index.html
```

### Tests use

| Fichier | Tests | Ce qui est couvert |
|---|---|---|
| `test_data_loader.py` | 5 | Load, génerator, class, encapsulation function |
| `test_inspector.py` | 4 | inspection dataFrame |

---



## 📈 Key result


| Indicateur | Valeur | Source |
|---|---|---|
| Commandes valides analysées | 12 500 | `notebooks/EDA_rapport_final.ipynb` |
| CA total | 393,7 M XAF | `notebooks/EDA_rapport_final.ipynb` |
| Panier moyen | 33 048 XAF | `notebooks/EDA_rapport_final.ipynb` |
| Cancelled percent | 22,4 % | `notebooks/EDA_rapport_final.ipynb` |
| Delivered Percent | 64,7 % | `notebooks/EDA_rapport_final.ipynb` |
| Delay moyen | 66 min | `notebooks/EDA_rapport_final.ipynb` |
| Unique customers | 2 100 | `sql/audit_qualité.sql` |
| Double customers when delete | 232 | `sql/audit_qualité.sql` |
| Update 2022 → 2024 | +211 % | `notebooks/EDA_rapport_final.ipynb` |
| Yaoundé vs Douala (délai) | +23 % — p = 10⁻²⁸ | `notebooks/statistics.ipynb` |

---

## 📁 File left (.gitignore)

```gitignore
# Environnement
.env
.venv/
__pycache__/
*.pyc
.pytest_cache/
htmlcov/

# Données (ne jamais versionner les données brutes)
data/raw/
data/clean/

# Jupyter
.ipynb_checkpoints/
*.ipynb_checkpoints

# IDE
.vscode/
.idea/

# OS
.DS_Store
Thumbs.db
```
