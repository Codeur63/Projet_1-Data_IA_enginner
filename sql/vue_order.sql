"""
    Création de la vue order qui centralisation
    le taux de livraison à temps, le panier moyen et le taux d'annulsation
    par ville et par mois

"""

"""
    De la table order recuperer les id, montant, ville, status, les dates normalisées ainsi que les montants
    qu'on mettras dans un table temporaire, puis de cette table temporaire, nous allons
    extraire les villes, les dates en mois, compters les montants, les status livŕe,en_retard,annulé
    et les moyennes, ce qui nous permert de creer notre vue v_order_kpi2.

    puis nous affichons le tout.
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
    count(statut = 'livré') AS total_livré,
    count(statut = 'en_retard') AS total_retard,
    count(statut = 'annulé') AS total_annulé,
    sum(total_amount_xaf) as total_amount_month,
    ROUND(
        SUM(CASE WHEN statut = 'livré' THEN 1 ELSE 0 END)
        / NULLIF(
            SUM(CASE WHEN statut IN ('livré', 'en_retard') THEN 1 ELSE 0 END),
            0
        ),
        4
    ) AS pct_livré,

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

    ROUND(
        count(statut = 'annulé')
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
