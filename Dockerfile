# 1. Image de base légère
FROM python:3.11-slim

# 2. Configuration de l'environnement pour éviter les fichiers .pyc et activer l'affichage direct
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1

# 3. Installation des dépendances système nécessaires (pour Kaleido et Poetry)
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 4. Installation de Poetry
ENV POETRY_HOME="/opt/poetry"
RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="$POETRY_HOME/bin:$PATH"

# 5. Dossier de travail
WORKDIR /app

# 6. Copie uniquement les fichiers de configuration de Poetry
# Cela permet de mettre en cache l'installation des librairies
COPY pyproject.toml poetry.lock* ./

# 7. Configuration de Poetry : Ne pas créer de virtualenv dans le conteneur
# (Le conteneur est déjà un environnement isolé)
RUN poetry config virtualenvs.create false \
    && poetry install --no-interaction --no-ansi --no-root

# 8. Copie du reste du projet
COPY . .

# 9. Lancement du script (ajuste le nom si besoin)
CMD ["python", "main.py"]

# docker run -v "$(pwd):/app" nexa-analytics
