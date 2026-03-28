from pathlib import Path
import pandas as pd


class CSVLoader:
    """
    Ici c'est la classe pour le chargement de fichier CSV,
    elle prend en entrée le chemin du fichier et retourne un DataFrame pandas.
    Dans un premier temps on verifier l'existance du fichier,
    puis on standardise les colonnes
    """

    # Initialisation de la classe avec le chemin du fichier CSV
    def __init__(self, filepath: str | Path):
        self.filepath = Path(filepath)

    # Fonction de chargement de fichier CSV
    def load(self) -> pd.DataFrame:

        #   Verification de l'existance dufichier
        if not self.filepath.exists():
            raise FileNotFoundError(f"File are not found: {self.filepath}")

        # Gerer les encodages differents
        encodings = ("utf-8", "latin-1", "iso-8859-1")
        dataframe = None

        for encoding in encodings:
            try:
                dataframe = pd.read_csv(self.filepath, encoding=encoding)
                break
            except UnicodeDecodeError:
                continue
            except Exception as exc:
                raise RuntimeError(
                    f"Error occurred while reading {self.filepath}: {exc}"
                ) from exc

        if dataframe is None:
            raise RuntimeError(
                f"Unable to read the file {self.filepath} with encodings."
            )

        dataframe.columns = [
            column.strip().lower() for column in dataframe.columns
        ]  # noqa: E501

        return dataframe
