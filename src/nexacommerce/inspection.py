import pandas as pd


def inspect_dataset(df: pd.DataFrame) -> dict:
    """
    Analyse un DataFrame et retourne un rapport structuré.

    Le rapport contient :
    - dimensions du dataset
    - types des colonnes
    - nombre et pourcentage de valeurs manquantes
    - nombre et pourcentage de lignes dupliquées

    Complexité algorithmique de la détection des doublons :
    pandas.DataFrame.duplicated() repose en pratique sur des mécanismes
    de hachage pour identifier les répétitions. En moyenne, cela conduit
    à une complexité proche de O(n), avec n le nombre de lignes,
    ce qui est bien plus efficace qu'une comparaison paire à paire en O(n²).
    """

    row_count, col_count = df.shape

    dtypes = dict(
        map(lambda column: (column, str(df[column].dtype)), df.columns)
    )  # noqa: E501

    missing_counts = df.isna().sum().to_dict()
    missing_percentages = {
        column: round((count / row_count) * 100, 2) if row_count > 0 else 0.0
        for column, count in missing_counts.items()
    }

    duplicate_count = int(df.duplicated().sum())
    duplicate_percentage = (
        round((duplicate_count / row_count) * 100, 2) if row_count > 0 else 0.0
    )

    columns_with_missing = list(
        filter(lambda column: missing_counts[column] > 0, df.columns)
    )

    return {
        "n_rows": row_count,
        "n_cols": col_count,
        "dtypes": dtypes,
        "missing_counts": missing_counts,
        "missing_percentages": missing_percentages,
        "columns_with_missing": columns_with_missing,
        "duplicate_count": duplicate_count,
        "duplicate_percentage": duplicate_percentage,
    }
