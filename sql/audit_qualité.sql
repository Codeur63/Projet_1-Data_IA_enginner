-- Commande Orphelines sans client
SELECT
    o.order_id as Id_Order,
    o.customer_id as Id_Customer,
    c.name as nom_client,
    o.total_amount_xaf as Montant,
    o.city as Ville,
    o.order_date as Date_Commande
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

------------------------------------------
-- Commande Orphelines sans client
"""
    De la table orders,
    faire une jointure à gauche (LEFT JOIN) avec la table customers
    en utilisant la colonnne customer_id comme clé de jointure
    et filtre sur les customers_id qui sont null
    ensuite affiche nous l'id de la commande et du customer
    ainsi que son montant, sa ville et la date de commande
"""


-- Les montants négatifs ou nuls
SELECT
    o.product_category as Categorie,
    o.total_amount_xaf as Montant,
    o.status as État_Commande,
    o.order_date as Date_Commande,
    CASE
        WHEN o.total_amount_xaf < 0 THEN 'Négatif'
        ELSE 'Nul'
    END as Anomalie
FROM orders o
WHERE o.total_amount_xaf <= 0;

"""
    De la table orders,
    filtre les commandes dont le montant total est inférieur ou égal à zéro
    ensuite affiche nous la catégorie du produit,
    le montant, l'état de la commande et la date de commande
    ainsi que le type d'anomalie (négatif ou nul)
"""



-- Les doublons dans la table customers avec nom du client et ID client
SELECT
    c.customer_id as Id_Customer,
    c.name as nom_client,
    COUNT(*) as Nombre_doublons
FROM customers c
GROUP BY c.customer_id, c.name
HAVING COUNT(*) > 1;

"""
   De la table customers,
   regroupe les customers par leur ID et nom,
   ensuite filtre les groupes qui sont présent plus d'une fois
   et affiche nous l'id du client, son nom et le nombre de fois qu'il est
   présent dans la table
"""


-- les doublons dans la table customers avec numéro de téléphone
SELECT
    c.name as nom_client,
    c.phone as numero_telephone,
    count(*) as Nombre_de_fois
FROM customers c
GROUP BY c.name, c.phone
HAVING count(*) > 1;

"""
    De la table customers,
    regroupe les customers par leur nom et numéro de téléphone,
    ensuite filtre les groupes qui sont présent plus d'une fois
    et affiche nous le nom du client, son numéro de téléphone et le nombre de fois qu'il est
    présent dans la table
"""

-- Affichier les clients qui ont le meme numero de telephone
SELECT c1.customer_id, c1.name,  c1.phone
FROM customers c1
WHERE c1.phone IN (
    SELECT c2.phone
    FROM customers c2
    GROUP BY c2.phone
    HAVING COUNT(*) > 1 and count(distinct c2.name) > 1
)
ORDER BY c1.phone, c1.name;

"""
    De la table customers,
    filtre les clients de la table customers
    dont le numéro de téléphone est présent plus d'une fois
    et le nombre de nom distinct supérieur à 1
    affiche moi alors l'id du client, son nom et son numéro de téléphone
    ensuite trie les résultats par numéro de téléphone et nom du client
"""

-- 1C-3. Doublons métier sur téléphone normalisé
-- Objectif : rapprocher 6XXXXXXXX, +2376XXXXXXXX, 237-6XXXXXXXX, etc.
WITH normalized_customers AS (
    SELECT
        customer_id,
        name,
        phone,
        city,
        quartier,
        loyalty_score,
        CASE
            WHEN phone IS NULL OR TRIM(phone) = '' THEN NULL
            ELSE
                CASE
                    WHEN REGEXP_REPLACE(phone, '[^0-9]', '') REGEXP '^2376[0-9]{8}$'
                        THEN REGEXP_REPLACE(phone, '[^0-9]', '')
                    WHEN REGEXP_REPLACE(phone, '[^0-9]', '') REGEXP '^6[0-9]{8}$'
                        THEN CONCAT('237', REGEXP_REPLACE(phone, '[^0-9]', ''))
                    ELSE REGEXP_REPLACE(phone, '[^0-9]', '')
                END
        END AS normalized_phone
    FROM customers
)
SELECT
    normalized_phone,
    COUNT(*) AS duplicate_count
FROM normalized_customers
WHERE normalized_phone IS NOT NULL
GROUP BY normalized_phone
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, normalized_phone;
