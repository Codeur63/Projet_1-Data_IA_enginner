from pathlib import Path
import pandas as pd
from typing import Generator


class CSVLoader:
    """Classe pour Charge un fichier CSV et le convertir en DataFrame pandas.

    Args:
        filepath (str | Path): Chemin vers le fichier CSV à charger.

    Returns:
        pd.DataFrame: Un DataFrame contenant les données du fichier CSV.

    Raises:
        FileNotFoundError: Si le fichier spécifié n'existe pas.
        RuntimeError: Si une erreur survient lors de la lecture du fichier ou si le fichier

    Méthodes:
        - load() return un DataFrame et l'encodage utilisé
        - iter_batches() return un génerateur par pas de batch sur le DataFrame

    Ici c'est la classe pour le chargement de fichier CSV,
    elle prend en entrée le chemin du fichier et retourne un DataFrame pandas.
    Dans un premier temps on verifier l'existance du fichier,
    puis on standardise les colonnes, et pour les fichiers assez grand
    nous retournons un generateur qui vas la dataFrame par pas de 1000.
    """

    # Initialisation de la classe (constructeur) recoit un fichier ne text ou un objet Path et le convertit en objet Path
    def __init__(self, filepath: str | Path):
        self.filepath = Path(filepath)

    # Fonction de chargement de fichier CSV
    def load(self, low_memory=False, enc: str = "utf-8") -> pd.DataFrame:

        #   Verification de l'existance du fichier
        if not self.filepath.exists():
            raise FileNotFoundError(f"File are not found: {self.filepath}")

        # Verifier que le fichier a une extension CSV
        allowed_exts = {".csv", ".txt"}
        if self.filepath.suffix.lower() not in allowed_exts:
            raise ValueError(f"Unsupported file extension: {self.filepath.suffix}")

        separators = [",", ";", "|"]  # Liste des séparateurs courants
        dataframe = None

        for sep in separators:
            try:
                # Lecture du fichier CSV avec l'encodage contenue dans encodings
                dataframe = pd.read_csv(
                    self.filepath,
                    encoding=enc,
                    sep=sep,
                    on_bad_lines="error",
                    low_memory=low_memory,
                )

                if len(dataframe.columns) < 2:
                    raise ValueError("The columns is not enough to be a CSV file ")
                break

            # CSV Mal formaté
            except pd.errors.ParserError as e:
                raise RuntimeError(
                    f"Error occurred while parsing {self.filepath}: {e}"
                ) from e

                # Erreur d'encodage, on continue avec le prochain encodage
            except UnicodeDecodeError:
                continue

                # Erreur inattendue, on la remonte
            except Exception as e:
                raise RuntimeError(
                    f"Error occurred while reading {self.filepath}: {e}"
                ) from e

        # Verifier si la dataframe à été chargée avec succès
        if dataframe is None:
            raise RuntimeError(
                f"Unable to read the file {self.filepath} with encodings."
            )

        # Standardisation des noms de colonnes et suppresion des espaces avec tout en minuscules
        dataframe.columns = [column.strip().lower() for column in dataframe.columns]

        return dataframe

    # Generateur par pas de 1000
    def iter_batches(
        self, filepath: str | Path, pas: int = 1000, encoding="utf-8"
    ) -> Generator[pd.DataFrame, None, None]:

        # Charger le dataFrame avec la fonction plus haut
        dataframe = self.load(encoding=encoding)

        # Faire une iteration par pas de 1000 sur longueur de la dataFrame - 1
        for i in range(0, len(dataframe), pas):
            # Recupere les valeurs dans un intervalle de 1000 les affiches et mémoirise
            yield dataframe.iloc[i : i + pas]
