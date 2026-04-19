"""Tests pour le module data_loader.py

Args:
    Aucun argument requis pour les tests.
    fichiers CSV

Returns:
    Les tests vérifient que le chargement de fichiers CSV fonctionne correctement,
    que les erreurs sont levées

On vérifie que le chargement de fichiers CSV fonctionne correctement, avec
différentes possibilité

"""

import pytest
import pandas as pd
from pathlib import Path

from nexacommerce.data_loader import DataLoader


# Validation sur fichier CSV (Test comportement normal)
def test_load_valid_csv(tmp_path):
    file_path = tmp_path / "sample.csv"
    file_path.write_text("Colonne A,Colonne B\n1,2\n3,4", encoding="utf-8")

    loader = DataLoader(file_path)
    df = loader.load()

    assert isinstance(df, pd.DataFrame)

    # Fichier avec les bonnes dimensions
    assert df.shape == (2, 2)


# Validation sur fichier CSV d'orders (Test de structuration)
def test_load_file_order(tmp_path):

    # Utilisation du fichier orders.csv pour tester le chargement de données réelles
    project_root = Path(__file__).parent.parent
    file_path = project_root / "data" / "orders.csv"

    # Chargement du fichier CSV
    loader = DataLoader(file_path)
    df = loader.load()

    # Vérification que la dataFrame est chargée
    assert isinstance(df, pd.DataFrame)
    # Vérification que la dataFrame a le nombre de lignes et de colonnes attendues
    assert df.shape == (12500, 12)


# Test pour la non lecture des encodages
def test_unable_to_read_with_encodings(monkeypatch, tmp_path):
    file_path = tmp_path / "file.csv"
    file_path.write_text("a,b\n1,2\n", encoding="utf-8")

    # Simuler UnicodeDecodeError pour toutes les tentatives de pd.read_csv
    def fake_read_csv(*args, **kwargs):
        raise UnicodeDecodeError("utf-8", b"", 0, 1, "invalid start byte")

    monkeypatch.setattr(pd, "read_csv", fake_read_csv)

    loader = DataLoader(file_path)

    with pytest.raises(
        RuntimeError, match=f"Unable to read the file {file_path} with encodings."
    ):
        loader.load()

    # Simuler pd.errors.ParseError
    def fake_read_csv_parser(*args, **kwargs):
        raise pd.errors.ParserError("simulated parser error")

    monkeypatch.setattr(pd, "read_csv", fake_read_csv_parser)

    loader = DataLoader(file_path)
    with pytest.raises(
        RuntimeError,
        match=f"Error occurred while parsing {file_path}: simulated parser error",
    ):
        loader.load()


# Test pour vérifier les données manquantes (Test de cas d'erreur)
def test_load_file_empty_csv(tmp_path):
    # Création d'un fichier CSV vide
    file_path = tmp_path / "empty.csv"
    file_path.write_text("", encoding="utf-8")

    loader = DataLoader(file_path)

    with pytest.raises(RuntimeError):
        loader.load()


# Validation sur fichier CSV avec du texte non structuré  (Test de cas d'erreur)
def test_load_file_none_csv(tmp_path):
    # Création d'un fichier CSV avec du texte non structuré
    file_path = tmp_path / "non_csv.txt"

    file_content = """ That is not a file with extension .txt as been structured"""

    file_path.write_text(file_content)

    loader = DataLoader(file_path)

    with pytest.raises((pd.errors.ParserError, RuntimeError, ValueError)):
        loader.load()


# Validation sur un fichier non .csv ou .txt (Test de cas d'erreur)
def test_load_file_extension(tmp_path):
    # Création d'un fichier avec une extension non supportée
    file_path = tmp_path / "data.json"
    file_path.write_text('{"key": "value"}', encoding="utf-8")

    loader = DataLoader(file_path)

    with pytest.raises(ValueError):
        loader.load()


# Validation sur fichier CSV avec du texte structuré (Test de strucuturation)
def test_load_file_structured_text_csv(tmp_path):

    # Creation du fichier text structuré et ecrire dans le fichier
    file_path = tmp_path / "text.txt"

    file_content = """id,customer_id,total,date
                1,101,150.50,2026-01-01
                2,102,89.00,2026-01-02
                3,101,250.75,2026-01-03
                """
    file_path.write_text(file_content, encoding="utf-8")

    # Chargement du fichier txt
    loader = DataLoader(file_path)
    df = loader.load()

    # Verification des attentes du fichier Text structuré
    assert isinstance(df, pd.DataFrame)
    assert df.shape == (3, 4)
    assert list(df.columns) == ["id", "customer_id", "total", "date"]
    assert df["id"].tolist() == [1, 2, 3]
    assert df["total"].sum() == 490.25
    assert df["customer_id"].dtype == "int64"


# Validation sur fichier CSV manquant (Test de cas d'erreur)
def test_load_missing_file_raises_error():
    loader = DataLoader("file.csv")

    # Vérification que le chargement d'un fichier manquant lève une erreur FileNotFoundError
    with pytest.raises(FileNotFoundError):
        loader.load()


# Validation sur fichier CSV avec encodage différent (Test de transformation)
def test_columns_are_normalized(tmp_path):

    # Création de fichier sample.csv avec eçriture + encodage utf-8
    file_path = tmp_path / "sample.csv"
    file_path.write_text(
        " id , Name, Surname, profeSSION \n1 , Annette, JeaNette, EnseiGnante\n",
        encoding="utf-8",
    )

    # Chargement du fichier CSV
    loader = DataLoader(file_path)
    df = loader.load()

    # Vérification des colonnes
    assert list(df.columns) == ["id", "name", "surname", "profession"]
