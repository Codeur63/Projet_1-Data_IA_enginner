"""Test pour l'inspection de dataset, on vérifie que les fonctions d'inspection retournent les résultats attendus
et que les cas limites sont gérés correctement.

    Args:
        df (pd.DataFrame): Le DataFrame à inspecter.

    Returns:
        dict: Un dictionnaire contenant les résultats de l'inspection, incluant :
            - n_rows (int): Nombre de lignes dans le DataFrame.
            - n_cols (int): Nombre de colonnes dans le DataFrame.
            - dtypes (dict): Types de données de chaque colonne.
            - missing_counts (dict): Nombre de valeurs manquantes par colonne.
            - missing_percentages (dict): Pourcentage de valeurs manquantes par colonne.
            - columns_with_missing (list): Liste des colonnes contenant des valeurs manquantes.
            - duplicate_count (int): Nombre de lignes dupliquées.
            - duplicate_percentage (float): Pourcentage de lignes dupliquées.

    Raises:
        ValueError: Si l'entrée n'est pas un DataFrame pandas.

    Returns:
        ce qu'on attends du test et si les valeurs sont bonnes ou pas

"""

import pytest
import pandas as pd

from nexacommerce.inspection import inspect_dataset


# Tests pour la fonction d'inspection avec les résultats attendus et les cas limites
def test_inspect_dataset_returns_expected_keys():
    # DataFrame d'exemple pour les tests
    df = pd.DataFrame(
        {
            "fruits": ["pasteque", "pomme", "avocat", "Banane"],
            "prix": [300, 425, 500, 600],
        }
    )

    # Inspection du dataset
    report = inspect_dataset(df)

    # Vérification que le rapport contient les clés attendues
    expected_keys = {
        "n_rows",
        "n_cols",
        "dtypes",
        "missing_counts",
        "missing_percentages",
        "columns_with_missing",
        "duplicate_count",
        "duplicate_percentage",
    }

    # Vérification des clés attendues dans le rapport
    assert expected_keys.issubset(report.keys())


# Test pour vérifier qu'il gère bien les dataFrames vidents
def test_inspect_dataset_empty_dataframe():
    # DataFrame vide
    df = pd.DataFrame()
    report = inspect_dataset(df)

    with pytest.raises(
        ValueError,
        match="The DataFrame is empty. Please provide a non-empty DataFrame for inspection.",
    ):
        report


# Test pour vérifier les données manquantes
def test_inspect_dataset_detects_missing_values():
    df = pd.DataFrame({"a": [1, None], "b": [3, 4]})
    report = inspect_dataset(df)

    assert report["missing_counts"]["a"] == 1
    assert "a" in report["columns_with_missing"]


# Test pour vérifier la détection des doublons
def test_inspect_dataset_detects_duplicates():
    df = pd.DataFrame({"a": [1, 1], "b": [2, 2]})
    report = inspect_dataset(df)

    assert report["duplicate_count"] == 1


# Test pour vérifier le pourcentage de doublons et le nombre de lignes
def test_inspect_dataset_handles_empty_dataframe():
    df = pd.DataFrame(columns=["a", "b"])
    report = inspect_dataset(df)

    assert report["n_rows"] == 0
    assert report["duplicate_percentage"] == 0.0
