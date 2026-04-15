-- Afficher les commandes sans clients
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
WHERE o.total_amount_xaf <= 0;    ~588

"""
    De la table orders,
    filtre les commandes dont le montant total est inférieur ou égal à zéro
    ensuite affiche nous la catégorie du produit,
    le montant, l'état de la commande et la date de commande
    ainsi que le type d'anomalie (négatif ou nul)
"""
-- Nombre de delivery_time_min à null
select count(*) from orders where delivery_time_min=''; ~1893


-- les doublons dans la table customers avec numéro de téléphone
SELECT
    c.name as nom_client,
    c.phone as numero_telephone,
    count(*) as Nombre_de_fois
FROM customers c
GROUP BY c.name, c.phone
HAVING count(*) > 1; resultat : ~55

"""
    De la table customers,
    regroupe les customers par leur nom et numéro de téléphone,
    ensuite filtre les groupes qui sont présent plus d'une fois
    et affiche nous le nom du client, son numéro de téléphone et le nombre de fois qu'il est
    présent dans la table
"""


-- Doublons dans la table customers avec les loyalty score

SELECT c.name, GROUP_CONCAT(DISTINCT c.loyalty_score ORDER BY c.loyalty_score) AS scores
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.name
HAVING COUNT(DISTINCT c.loyalty_score) > 1; Resultat : 142

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

--  Doublons métier sur téléphone normalisé
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


-- Identifier les doublons client par loyalty_Score.
SELECT c.name, GROUP_CONCAT(distinct c.loyalty_score ORDER BY c.loyalty_score SEPARATOR ' | ') AS scores
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.name
HAVING COUNT(DISTINCT c.loyalty_score) > 1;


-- Client avec des loyaly score inférieur ou égal à 0
select count(*) from customers where loyalty_score<=0 ;


-- Correlation entre le loyalty et le nombre de commande du client
select c.* , o.status,oi.order_id,o.order_date
from customers c
inner JOIN orders o
on c.customer_id = o.customer_id
inner join order_items oi
on o.order_id = oi.order_id
where c.loyalty_score < 10 ;


-- Comparer si le total_amount dans order_items vaut le meme pour orders
select oi.order_id,
sum(oi.line_total_xaf) as Total,
o.total_amount_xaf as comparaison_total
from order_items oi
inner join orders o
on o.order_id = oi.order_id
group by oi.order_id ;


-- Afficher l'order_id pour le line_total_xaf et total_amount_xaf cohérent
SELECT
  oi.order_id,
  SUM(oi.line_total_xaf) AS total,
  o.total_amount_xaf AS comparaison_total
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
GROUP BY oi.order_id, o.total_amount_xaf
HAVING SUM(oi.line_total_xaf) = o.total_amount_xaf;


-- Etablir une corrélation entre les clients qui ont passé le plus grand nombre de commande et les montants (client actif, client inacif)
select o.customer_id , count(o.order_id ), c.name, c.loyalty_score, sum(o.total_amount_xaf)
from orders o
inner join customers c
on c.customer_id = o.customer_id
where o.status not in ('annulé', 'en_cours')
group by o.customer_id
order by count(o.order_id) desc;


-- Nombre de montant négatif
select count(total_amount_xaf)
from orders
where total_amount_xaf<0;

-- Différence de montant avec la table orders et order_items
SELECT
  o.order_id,
  o.total_amount_xaf,
  COALESCE(t.total_amount_order_item, 0) AS total_amount_order_item,
  o.total_amount_xaf - COALESCE(t.total_amount_order_item, 0) AS difference
FROM orders o
LEFT JOIN (
  SELECT order_id, SUM(line_total_xaf * quantity) AS total_amount_order_item
  FROM order_items
  GROUP BY order_id
) t USING (order_id)
WHERE COALESCE(o.total_amount_xaf, 0) <> COALESCE(t.total_amount_order_item, 0)
ORDER BY ABS(o.total_amount_xaf - COALESCE(t.total_amount_order_item, 0)) DESC;
