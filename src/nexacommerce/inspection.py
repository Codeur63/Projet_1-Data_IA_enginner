"""
Analyse un DataFrame et retourne un rapport structuré.

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

    Cette fonction inspecte un DataFrame pandas pour fournir un rapport détaillé :
        - sur sa structure,
        - les types de données,
        - les valeurs manquantes,
        - les doublons.

La complexité algorithimique de la détection des doublons de la fonction
inlcue des Operations élémentaires qui sont le parcours de éléments de
la DataFrame ainsi que la comparaison. Mais les methode .duplicated() s'appuie
sur du hashing et alors dans le pire des quand nous pouvons avoir O(n)
"""

import pandas as pd


# Fonction qui prends un dataFrame et retourne un dictionnaire
def inspect_dataset(df: pd.DataFrame) -> pd.DataFrame:

    # Validation de l'entrée
    if not isinstance(df, pd.DataFrame):
        raise ValueError("Input must be a pandas DataFrame.")

    # Gestion du cas d'un dataFrame vide
    if df.empty:
        raise ValueError(
            "The DataFrame is empty. Please provide a non-empty DataFrame for inspection."
        )

    # Recuperer les dimensions du dataFrame
    row_count, col_count = df.shape

    # Obtenir les types de données de chaque colonne
    dtypes = df.dtypes.astype(str).to_dict()

    # Compte les valeurs manquantes par colonne
    missing_counts = df.isna().sum().to_dict()

    # Donne le pourcentage de valeurs manquantes par colonne
    missing_percentages = {
        column: round((count / row_count) * 100, 2) if row_count > 0 else 0.0
        for column, count in missing_counts.items()
    }

    # Compte les doublons dans le dataFrame
    duplicate_count = int(df.duplicated().sum())

    # Donne le pourcentage de doublons dans le dataFrame
    duplicate_percentage = (
        round((duplicate_count / row_count) * 100, 2) if row_count > 0 else 0.0
    )

    # Filtre les colonnes qui ont des valeurs manquantes et les met dans une liste
    columns_with_missing = list(
        filter(lambda column: missing_counts[column] > 0, df.columns)
    )

    # Resultat dans un dataFrame
    result_dict = {
        "rows": row_count,
        "cols": col_count,
        "dtypes": dtypes,
        "missing_counts": missing_counts,
        "missing_percentages": missing_percentages,
        "columns_with_missing": columns_with_missing,
        "duplicate_count": duplicate_count,
        "duplicate_percentage": duplicate_percentage,
        "unique": df.nunique().to_dict(),
        "not_null": df.notnull().sum().to_dict(),
    }

    resultat = (
        pd.DataFrame.from_dict(result_dict, orient="index", columns=["Value"])
        .reset_index()
        .rename(columns={"index": "Mesure"})
    )

    return resultat


# df.dtypes.astype(str).to_dict().
