-- Implémentez des fonctions de fenêtrage (RANK, LAG) pour identifier les livreurs dont le temps de
-- livraison moyen s'est dégradé sur les 3 derniers mois.


-- WITH delivery_courier AS (
-- SELECT
--     c.courier_id,
--     c.name as courier_name,
--     o.order_id,
--     o.order_date,
--     o.status,
--     TIMESTAMPDIFF(MINUTE, STR_TO_DATE(o.order_date, '%d/%m/%Y'), CURDATE()) as delivery_time_minutes
--     FROM orders o
--     INNER JOIN couriers c ON o.courier_id = c.courier_id
--     WHERE o.status = 'livré'
-- ),
-- select
--     courier_id,
--     courier_name,
--     order_date,
--     delivery_time_minutes,
--     RANK() OVER (PARTITION BY courier_id ORDER BY order_date DESC) as delivery_rank,
--     LAG(delivery_time_minutes) OVER (PARTITION BY courier_id ORDER BY order_date DESC) as previous_delivery_time
--     from delivery_courier



WITH cleaned_orders AS (
    SELECT
        oc.order_id,
        oc.courier_id,
        c.name as name,
        oc.delivery_time_min,
        oc.status_normalise as status,
        oc.total_amount_xaf as total_amount,
        oc.order_date_clean
    FROM orders_clean oc
    inner join couriers c
    on c.courier_id = oc.courier_id
), max_date as (
	select
		max(order_date_clean) as date_max
	from orders_clean
),
courier_monthly AS (
    SELECT
        courier_id,
        name,
        DATE_FORMAT(order_date_clean, '%Y-%m') AS order_month,
        AVG(delivery_time_min) AS temps_moyen_livraison
    FROM cleaned_orders CROSS JOIN max_date md
    WHERE order_date_clean IS NOT NULL
      AND order_date_clean >= DATE_SUB(DATE_FORMAT(md.date_max, '%Y-%m-01'), INTERVAL 3 MONTH)
      AND delivery_time_min IS NOT NULL
      AND status IN ('livré', 'en_retard')
    GROUP BY courier_id, DATE_FORMAT(order_date_clean, '%Y-%m')
),
courier_lag AS (
    SELECT
        courier_id,
        name,
        order_month,
        temps_moyen_livraison,
        LAG(temps_moyen_livraison) OVER (
            PARTITION BY courier_id
            ORDER BY order_month
        ) AS temps_moyen_livraison_passé
    FROM courier_monthly
),
courier_degradation AS (
    SELECT
        courier_id,
        name,
        order_month,
        temps_moyen_livraison,
        temps_moyen_livraison_passé,
        temps_moyen_livraison - temps_moyen_livraison_passé AS temps_degrader
    FROM courier_lag
    WHERE temps_moyen_livraison_passé IS NOT NULL
)
SELECT
    courier_id,
    name,
    order_month,
    temps_moyen_livraison,
    temps_moyen_livraison_passé,
    temps_degrader,
    RANK() OVER (
        PARTITION BY order_month
        ORDER BY temps_degrader DESC
    ) AS degradation_rank
FROM courier_degradation
WHERE temps_degrader > 0
ORDER BY order_month, degradation_rank, courier_id;


-- Rank des livreurs de l'entreprise

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
