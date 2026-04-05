-- Analyse du plan d'excution des pour au moins 2 requêtes

EXPLAIN
SELECT
    o.order_id,
    o.customer_id,
    o.order_date,
    o.total_amount_xaf,
    o.city
FROM orders o
LEFT JOIN customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

-- Index recommandés pour accélérer la jointure sur orders et customer
-- un right join ou left join
CREATE INDEX idx_orders_customer_id ON orders(customer_id);
CREATE INDEX idx_customers_customer_id ON customers(customer_id);

-- Commentaire :
"""
    La requete repose sur les jointures entre cusstomer_id de orders et
    customer_id et la table customer. les index suivant visent à réduire
    le temps de rechercher et éviter le scans complet sur les gros données.
"""



EXPLAIN
SELECT
	cr.name 	AS livreur,
	cr.city,
	COUNT(o.order_id)	AS nb_livraisons,
	RANK() OVER (	PARTITION BY cr.city
	-- un classement par ville
	ORDER BY COUNT(o.order_id) DESC
	-- du plus actif au moins actif
	) 	AS rang_dans_ville,
	DENSE_RANK() OVER (
	ORDER BY COUNT(o.order_id) DESC
	-- classement global
	)	AS rang_global
FROM couriers AS cr
INNER JOIN orders AS o ON cr.courier_id = o.courier_id
WHERE o.status = 'livré'
AND cr.is_active = 1
GROUP BY cr.courier_id, cr.name, cr.city
ORDER BY cr.city, rang_dans_ville;

-- Index recommandés pour accélére les filtres et agrégations
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_courier_id ON orders(courier_id);
CREATE INDEX idx_courier_courier_id ON courier(courier_id);
CREATE INDEX idx_orders_city ON orders(city);

-- Commentaire :
"""
    La requete repose sur une jointure entre les id du courier
    de la table order et de la table courier ainsi que les filtres
    sur status dans la table orders. Les index suivant ont pour but de
    faciliter la recherche sur les status et les courier_id.
"""


EXPLAIN
SELECT *
FROM v_order_kpis2
ORDER BY order_month, city;

-- Index recommandés pour accélére les recherches
CREATE INDEX idx_orders_status ON orders(status);
CREATE INDEX idx_orders_clean_status ON orders_clean(order_date_clean);

-- Commentaire :
"""
    La requete repose sur la recherche de status ainsi que les
    date de la table orders_clean que nous avont créer plus haut
    qui ont pour but de bien filtre les montants et status. Les index
    suivant ont pour but de reduire le temps de recherche pour les
    date et les status.
"""
