-- Utilisez les CTEs (Common Table Expressions) pour calculer le chiffre d'affaires
-- mensuel par ville sur les 12 derniers mois.



"""
    Faire une CTE pour nettoyer les données
    de la table orders en convertissant les dates au format_date,
    ensuite faire une autre CTE pour calculer le chiffre d'affaires
    mensuel par ville sur les 12 derniers mois en filtrant les commandes livrées
    et dont le montant total est supérieur à zéro
    enfin affiche nous la ville, le mois de la commande,
    et le chiffre d'affaires mensuel
"""


--- solution 1 avec pour but de cast les chaines de caractères
WITH cleaned_orders AS (
    SELECT
        order_id,
        customer_id,
        city,
        total_amount_xaf,
        status as statut,
        COALESCE(
            -- Format "DD Month YYYY" (ex. 01 March 2024)
            CASE WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{2} [A-Za-z]+ [0-9]{4}$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%d %M %Y') END,
            -- Format "DD-MM-YYYY" (ex. 01-01-2024)
            CASE WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%d-%m-%Y') END,
            -- Format "DD/MM/YYYY HH:MM" (ex. 01/01/2024 06:39)
            CASE WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%d/%m/%Y %H:%i') END,
            -- Format "DD/MM/YYYY HH:MM:SS" (ex. 01/01/2024 06:39:10)
            CASE WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}:[0-9]{2}$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%d/%m/%Y %H:%i:%s') END,
            -- Format "YYYY-MM-DD" (ISO date)
            CASE WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%Y-%m-%d') END,
            -- Format "YYYY-MM-DD HH:MM" (ISO datetime without seconds)
            CASE WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%Y-%m-%d %H:%i') END,
            -- Format "YYYY-MM-DD HH:MM:SS" (ISO datetime)
            CASE WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}[ T][0-9]{2}:[0-9]{2}:[0-9]{2}$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%Y-%m-%d %H:%i:%s') END,
            -- Format "DD Month YYYY HH:MM" (e.g. "01 March 2024 06:39")
            CASE WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{2} [A-Za-z]+ [0-9]{4} [0-9]{2}:[0-9]{2}(:[0-9]{2})?$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%d %M %Y %H:%i') END,
            -- Format "DD-MM-YYYY" (ex. 02/25/2025)
            CASE WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{4}$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%M/%C/%Y') END,
            CASE WHEN CAST(order_date AS CHAR) LIKE '__/__/____' THEN STR_TO_DATE(CAST(order_date AS CHAR), '%d/%m/%Y') END,
            CASE WHEN CAST(order_date AS CHAR) LIKE '__-__-____' THEN STR_TO_DATE(CAST(order_date AS CHAR), '%d/%m/%Y') END,
            CASE WHEN CAST(order_date AS CHAR) LIKE '____/__/__' THEN STR_TO_DATE(CAST(order_date AS CHAR), '%Y/%m/%d') END,
            CASE WHEN CAST(order_date AS CHAR) LIKE '____-__-__' THEN STR_TO_DATE(CAST(order_date AS CHAR), '%Y/%m/%d') END,
            CASE WHEN CAST(order_date AS CHAR) LIKE '__/__/____' THEN STR_TO_DATE(order_date, '%m/%d/%Y')  END,
            CASE WHEN CAST(order_date AS CHAR) LIKE '__-__-____' THEN STR_TO_DATE(order_date, '%m-%d-%Y')END
            ) AS order_date_clean
    FROM orders
    where total_amount_xaf >0
), CA_12_months AS (
    SELECT
        city,
        DATE_FORMAT(order_date_clean, '%Y-%m') as order_month,
        SUM(total_amount_xaf) as Ca_month
    FROM cleaned_orders
    WHERE order_date_clean IS NOT NULL AND
        statut = 'livré' AND
        order_date_clean >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
    GROUP BY city, order_month
)
SELECT
    city,
    order_month,
    Ca_month
FROM CA_12_months
ORDER BY order_month, city;




-- Solution 2 avec juste l'utilisation des dates mal enregistrées
WITH cleaned_orders AS (
    SELECT
        order_id,
        customer_id,
        city,
        total_amount_xaf,
        status,
        CASE
            WHEN order_date LIKE '__/__/____'
                THEN STR_TO_DATE(order_date, '%d/%m/%Y')
            WHEN order_date LIKE '____-__-__'
                THEN STR_TO_DATE(order_date, '%Y-%m-%d')
            ELSE NULL
        END AS parsed_order_date
    FROM orders
),
monthly_revenue AS (
    SELECT
        city,
        DATE_FORMAT(parsed_order_date, '%Y-%m') AS order_month,
        SUM(total_amount_xaf) AS revenue_xaf
    FROM cleaned_orders
    WHERE parsed_order_date IS NOT NULL
      AND parsed_order_date >= DATE_SUB(CURDATE(), INTERVAL 12 MONTH)
      AND total_amount_xaf > 0
      AND status = 'livré'
    GROUP BY city, order_month
)

SELECT
    city,
    order_month,
    revenue_xaf
FROM monthly_revenue
ORDER BY order_month, city;


-- Solution 3 utilisation d'une table order_clean

CREATE TABLE IF NOT EXISTS orders_clean (
	order_id	INT	NOT NULL,
	customer_id	VARCHAR(20)	NOT NULL,
	courier_id	INT	NULL,
	order_date_clean	DATETIME	NULL,	-- date normalisée
	status_normalise	ENUM('livré','en_retard','annulé','en_cours') NULL,
	city_normalise	ENUM('douala','yaoundé','bafoussam')	NULL,
	total_amount_xaf	DECIMAL(14,2) NULL,
	delivery_time_min DECIMAL(8,1)	NULL,
	cleaned_at	DATETIME	DEFAULT CURRENT_TIMESTAMP,

	PRIMARY KEY (order_id),
	INDEX idx_customer	(customer_id),
	INDEX idx_date	(order_date_clean),
	INDEX idx_city_status (city_normalise, status_normalise)
)
ENGINE = InnoDB
COMMENT = 'Table des commandes nettoyées et normalisées';

INSERT INTO orders_clean (
    order_id,
    customer_id,
    courier_id,
    order_date_clean,
    status_normalise,
    city_normalise,
    total_amount_xaf,
    delivery_time_min,
    cleaned_at
)
SELECT
    order_id,
    customer_id,
    courier_id,
    COALESCE(
        -- Format texte : 04 January 2024
        CASE
            WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{2} [A-Za-z]+ [0-9]{4}$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%d %M %Y')
        END,
        -- Format : 01-02-2024
        CASE
            WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{2}-[0-9]{2}-[0-9]{4}$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%d-%m-%Y')
        END,
        -- Format : 2024-02-01 14:30:00
        CASE
            WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%Y-%m-%d %H:%i:%s')
        END,
        -- Format : 2024-02-01
        CASE
            WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{4}-[0-9]{2}-[0-9]{2}$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%Y-%m-%d')
        END,
        -- Format : 2024/02/01 14:30
        CASE
            WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2} [0-9]{2}:[0-9]{2}$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%Y/%m/%d %H:%i')
        END,
        -- Format : 2024/02/01
        CASE
            WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{4}/[0-9]{2}/[0-9]{2}$'
            THEN STR_TO_DATE(CAST(order_date AS CHAR), '%Y/%m/%d')
        END,
        -- Format avec slash + heure : 01/02/2024 14:30 ou 02/24/2025 14:30
        CASE
            WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4} [0-9]{2}:[0-9]{2}$'
            THEN
                CASE
                    -- si le deuxième bloc > 12, on suppose MM/DD/YYYY HH:MM
                    WHEN CAST(
                        SUBSTRING_INDEX(
                            SUBSTRING_INDEX(CAST(order_date AS CHAR), '/', 2),
                            '/',
                            -1
                        ) AS UNSIGNED
                    ) > 12
                    THEN STR_TO_DATE(CAST(order_date AS CHAR), '%m/%d/%Y %H:%i')
                    -- sinon DD/MM/YYYY HH:MM
                    ELSE STR_TO_DATE(CAST(order_date AS CHAR), '%d/%m/%Y %H:%i')
                END
        END,
        -- Format avec slash sans heure : 01/02/2024 ou 02/24/2025
        CASE
            WHEN CAST(order_date AS CHAR) REGEXP '^[0-9]{2}/[0-9]{2}/[0-9]{4}$'
            THEN
                CASE
                    -- si le deuxième bloc > 12, on suppose MM/DD/YYYY
                    WHEN CAST(
                        SUBSTRING_INDEX(
                            SUBSTRING_INDEX(CAST(order_date AS CHAR), '/', 2),
                            '/',
                            -1
                        ) AS UNSIGNED
                    ) > 12
                    THEN STR_TO_DATE(CAST(order_date AS CHAR), '%m/%d/%Y')
                    -- sinon DD/MM/YYYY
                    ELSE STR_TO_DATE(CAST(order_date AS CHAR), '%d/%m/%Y')
                END
        END
    ) AS order_date_clean,
    CASE
        WHEN LOWER(TRIM(status)) IN ('livré', 'livre') THEN 'livré'
        WHEN LOWER(TRIM(status)) IN ('en_retard', 'en retard', 'retard') THEN 'en_retard'
        WHEN LOWER(TRIM(status)) IN ('annulé', 'annule') THEN 'annulé'
        WHEN LOWER(TRIM(status)) IN ('en_cours', 'en cours') THEN 'en_cours'
        ELSE 'inconnu'
    END AS status_normalise,
    CASE
        WHEN LOWER(TRIM(city)) LIKE '%douala%' THEN 'douala'
        WHEN LOWER(TRIM(city)) LIKE '%yaounde%' OR LOWER(TRIM(city)) LIKE '%yaoundé%' THEN 'yaoundé'
        WHEN LOWER(TRIM(city)) LIKE '%bafoussam%' THEN 'bafoussam'
        ELSE 'inconnu'
    END AS city_normalise,
    CASE
        WHEN total_amount_xaf IS NULL THEN NULL
        ELSE ABS(total_amount_xaf)
    END AS total_amount_xaf,
    delivery_time_min,
    CURRENT_TIMESTAMP AS cleaned_at
FROM orders;

WITH max_date AS (
	SELECT MAX(order_date_clean) AS max_order_date FROM orders_clean
), CA_12_months AS (
	SELECT oc.city_normalise AS ville,
		DATE_FORMAT(oc.order_date_clean, '%Y-%m') AS mois,
		SUM(oc.total_amount_xaf) AS Chiffre_affaire
	FROM orders_clean oc CROSS JOIN max_date md
	WHERE oc.order_date_clean IS NOT NULL
		AND oc.status_normalise = 'livré'
		AND oc.order_date_clean >= DATE_SUB(DATE_FORMAT(md.max_order_date, '%Y-%m-01'), INTERVAL 12 MONTH)
	GROUP BY ville, mois
	)
	SELECT ville, mois, Chiffre_affaire
	FROM CA_12_months
	ORDER BY mois DESC;
