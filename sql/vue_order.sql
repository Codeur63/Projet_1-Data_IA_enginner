"""
    Création de la vue order qui centralisation
    le taux de livraison à temps, le panier moyen et le taux d'annulsation
    par ville et par mois

"""

"""
    De la table order recuperer les id, montant, ville, status et les dates normalisées
"""


CREATE OR REPLACE VIEW v_order_kpis2 AS
WITH cleaned_orders AS (
    SELECT
        order_date_clean,
        status_normalise AS statut,
        city_normalise AS city,
        total_amount_xaf
    FROM orders_clean
    WHERE order_date_clean IS NOT NULL
)
SELECT
    city,
    DATE_FORMAT(order_date_clean, '%Y-%m') AS order_month,
    COUNT(*) AS total_commande,
    -- nombre de commandes livrées à temps
    SUM(CASE WHEN statut = 'livré' THEN 1 ELSE 0 END) AS total_livré,
    -- nombre de commandes en retard
    SUM(CASE WHEN statut = 'en_retard' THEN 1 ELSE 0 END) AS total_retard,
    -- nombre de commandes annulées
    SUM(CASE WHEN statut = 'annulé' THEN 1 ELSE 0 END) AS total_annulé,
    -- montant total des commandes  au cours du mois
    SUM(total_amount_xaf) as total_amount_month,
    -- taux de livraison à temps = livré / (livré + en_retard)
    ROUND(
        SUM(CASE WHEN statut = 'livré' THEN 1 ELSE 0 END)
        / NULLIF(
            SUM(CASE WHEN statut IN ('livré', 'en_retard') THEN 1 ELSE 0 END),
            0
        ),
        4
    ) AS pct_livré,
    -- panier moyen sur les commandes réalisées
    ROUND(
        AVG(
            CASE
                WHEN statut IN ('livré', 'en_retard') AND total_amount_xaf > 0
                THEN total_amount_xaf
                ELSE NULL
            END
        ),
        2
    ) AS panier_moyen_comande,
    -- taux d'annulation = annulé / total
    ROUND(
        SUM(CASE WHEN statut = 'annulé' THEN 1 ELSE 0 END)
        / NULLIF(COUNT(*), 0),
        4
    ) AS pct_annulé
FROM cleaned_orders
GROUP BY
    city,
    DATE_FORMAT(order_date_clean, '%Y-%m');


SELECT *
FROM v_order_kpis2
ORDER BY order_month, city;
