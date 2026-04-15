# AUDIT COMPLETE SUR LES TABLES

Àprés avoir créer une `base de données` et les `tables` dédiée à notre projet nous avons par la suite charger les fichiers csv de l'entreprise dans les différentes table requise à cette effet. Par ailleurs pour vérifier les tables, la qualité du jeu de données afin de faire un nettoyage optimal, nous avons obtez pour un audit complete du jeux de données de ceux ci décolle plusieurs constat.

## Table Order

### Constat 1
La table orders retrouver 17 variantes de status, 14 variantes de ville, en retrouve les temps de livraison à 0, des montants négatfis, des dates avec différents formats et delivery_time_min qui sont null.

#### Solution
- Pour la table orders il faudrais s'assurer à normaliser les status par :
`delivered, late, cancelled, in_progress`, les pour les villes faudrais les normalisés LOWER(TRIM(VILLE)) pour le sql, et en python nous allons `city.strip().lower()`.
- Les montants négatifs nous allons mettre tout les montants négatif en valeur absolue
- Les dates nous allons devoir idenitifier toutes les formats et parsed les dates.
- mettre un temps moyen de livraison dans les delivery time inférieur à 0.
- Calculer les outliers


### Constat 2
La table orders à une violation 2NF, notament sur la colonne product_category.

#### Solution
- Supprimer la colonne product_category de la table order.


## Table Order_items

### Constat 1
Dans cette table nous constatons également une violation de normalisation 2NF, notament avec les colonnes product_name,Product_category qui ne dependent pas de la clé primaire et uniquement de la clé primaire.

#### Solution
Deux choix distincte s'oppose à nous:
-  Supprimer les tables product_name et product_category.
- Ou bien garder les colonnes pour l'optimisaton des recherches.


## Table customers
### Constat 1
- Dans cette table on revoie différent format de numéro de téléphone
- Les villes ne sont pas normaliser
- On trouve des loyalty_score à 0 et supérieur à 100

#### Solution
- Normaliser les villes
- Normaliser les numéros de téléphone
- Normaliser les loyalty_score entre 0 et 100

## Table courier
### Constat 1
Nous constatons dans cette table les numero de telephone n'ont pas le bon format,

### Solution
- Normaliser les numéros de telephone.

## Constat général
### Table orders
- Nous remarquons que les line_total_xaf additionner entre elle et regrouper par order_id, ils ne correspondent au toal_amount_xaf des orders_id de la table orders
- Nous trouvons les clients sans commande dans la table orders

#### Reflexion
- Nous devons savoir si nous pouvons inclure ou les exclures dans notre analyse exploratoire.

### Table order_items
- Nous avons pour constat que les unit_price_xaf ne sont pas les memes pour les base_price_xaf de la table product
- Nous remarquons tout aussi que les prix des produits sont éléves par rapport au base_line_xaf de la table products

#### Reflexion
- Nous pouvons nous dire qu'il y a eu des promotions pour des produit, mais nous remarquons aussi que des fois le prix est élévé et ne sont pas les memes.
- Nous pouvons mettre ça sur le prix de livraison mais le soucis c'est qu'il n'est pas uniforme que faire ?

### Table customers
- Nous remarquons que nous avons également des clients qui ont 12 commandes et qui sont livrés 12 fois mais qui ont des loyalty_score à 0. Le loyalty_score depends de quoi ou sur quel base?
