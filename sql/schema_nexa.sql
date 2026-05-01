-- ============================================================
--  NexaCommerce Cameroun – Schéma de Base de Données
--  Fichier : schema_nexa.sql
--  Version : 1.4 (export Février 2025)
--  Auteur  : Équipe Technique NexaCommerce
--  Note    : Schéma de la base de données transactionnelle MySQL
--            utilisée en production depuis Mars 2021.
--            Ce fichier contient : DDL, contraintes, index,
--            données de référence et exemples de requêtes.
-- ============================================================

-- ============================================================
-- 0. CONFIGURATION
-- ============================================================
SET NAMES utf8mb4;
SET time_zone = '+01:00';
SET foreign_key_checks = 0;
SET sql_mode = 'STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- ============================================================
-- 1. CRÉATION DE LA BASE
-- ============================================================
CREATE DATABASE IF NOT EXISTS nexacommerce
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE nexacommerce;


-- ============================================================
-- 2. TABLE : customers
--    Clients enregistrés sur la plateforme NexaCommerce
-- ============================================================
DROP TABLE IF EXISTS customers;
CREATE TABLE customers (
    customer_id   VARCHAR(20)   NOT NULL,
    name          VARCHAR(150)  DEFAULT NULL,
    phone         VARCHAR(30)   DEFAULT NULL,
    registration_date DATE      DEFAULT NULL,
    city          VARCHAR(50)   DEFAULT NULL,
    quartier      VARCHAR(80)   DEFAULT NULL,
    loyalty_score DECIMAL(6,1)  DEFAULT NULL   COMMENT 'Score 0-100. Valeurs > 100 = anomalie à corriger.',

    PRIMARY KEY (customer_id),
    INDEX idx_customers_city (city),
    INDEX idx_customers_phone (phone),
    INDEX idx_customers_reg_date (registration_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Table clients. Contient des doublons connus (même personne, customer_id différent). À nettoyer.';


-- ============================================================
-- 3. TABLE : couriers
--    Livreurs partenaires de NexaCommerce
-- ============================================================
DROP TABLE IF EXISTS couriers;
CREATE TABLE couriers (
    courier_id    INT           NOT NULL AUTO_INCREMENT,
    name          VARCHAR(150)  NOT NULL,
    phone         VARCHAR(30)   DEFAULT NULL,
    city          VARCHAR(50)   DEFAULT NULL,
    vehicle_type  ENUM('Moto','Vélo','Voiture','Tricycle') DEFAULT 'Moto',
    join_date     DATE          DEFAULT NULL,
    is_active     TINYINT(1)    DEFAULT 1       COMMENT '1 = actif, 0 = inactif',
    rating        DECIMAL(3,1)  DEFAULT NULL     COMMENT 'Note moyenne sur 5 donnée par les clients',

    PRIMARY KEY (courier_id),
    INDEX idx_couriers_city (city),
    INDEX idx_couriers_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 4. TABLE : products
--    Catalogue produits référencés sur la plateforme
-- ============================================================
DROP TABLE IF EXISTS products;
CREATE TABLE products (
    product_id      INT           NOT NULL AUTO_INCREMENT,
    product_name    VARCHAR(200)  NOT NULL,
    product_category VARCHAR(50)  DEFAULT NULL,
    base_price_xaf  DECIMAL(12,0) DEFAULT NULL,
    is_available    TINYINT(1)    DEFAULT 1,
    created_at      DATETIME      DEFAULT CURRENT_TIMESTAMP,

    PRIMARY KEY (product_id),
    INDEX idx_products_category (product_category),
    INDEX idx_products_available (is_available)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 5. TABLE : orders
--    Commandes passées sur la plateforme
--    ATTENTION : la colonne order_date est stockée en VARCHAR
--    pour compatibilité historique avec l'ancien système.
--    Les formats sont hétérogènes. À normaliser en DATETIME.
-- ============================================================
DROP TABLE IF EXISTS orders;
CREATE TABLE orders (
    order_id            INT           NOT NULL,
    customer_id         VARCHAR(20)   DEFAULT NULL   COMMENT 'FK non enforced — des orphelins existent',
    order_date          VARCHAR(30)   DEFAULT NULL   COMMENT 'Formats hétérogènes : DD/MM/YYYY, YYYY-MM-DD, etc.',
    delivery_time_min   DECIMAL(8,1)  DEFAULT NULL   COMMENT 'Durée livraison en minutes. NULL si non terminé.',
    status              VARCHAR(30)   DEFAULT NULL   COMMENT 'Valeurs non normalisées : livré/Livré/LIVRE/en_retard/...',
    total_amount_xaf    DECIMAL(14,0) DEFAULT NULL   COMMENT 'Montant XAF. Valeurs négatives = anomalies.',
    city                VARCHAR(50)   DEFAULT NULL,
    quartier            VARCHAR(80)   DEFAULT NULL,
    product_category    VARCHAR(50)   DEFAULT NULL   COMMENT '~15% NULL. Casse et orthographe variables.',
    courier_id          INT           DEFAULT NULL,
    order_hour          TINYINT       DEFAULT NULL,
    order_day_of_week   VARCHAR(15)   DEFAULT NULL,

    PRIMARY KEY (order_id),
    INDEX idx_orders_customer (customer_id),
    INDEX idx_orders_city (city),
    INDEX idx_orders_status (status),
    INDEX idx_orders_courier (courier_id),
    INDEX idx_orders_date (order_date(10))

    -- NOTE : Pas de FK sur customer_id intentionnellement (legacy).
    -- Des commandes existent sans client correspondant dans customers.
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='Table principale des commandes. Nombreuses impuretés à corriger avant analyse.';


-- ============================================================
-- 6. TABLE : order_items
--    Détail des produits par commande
-- ============================================================
DROP TABLE IF EXISTS order_items;
CREATE TABLE order_items (
    item_id             INT           NOT NULL AUTO_INCREMENT,
    order_id            INT           NOT NULL,
    product_id          INT           DEFAULT NULL,
    product_name        VARCHAR(200)  DEFAULT NULL,
    product_category    VARCHAR(50)   DEFAULT NULL,
    quantity            INT           DEFAULT 1,
    unit_price_xaf      DECIMAL(12,0) DEFAULT NULL,
    line_total_xaf      DECIMAL(14,0) DEFAULT NULL,

    PRIMARY KEY (item_id),
    INDEX idx_items_order (order_id),
    INDEX idx_items_product (product_id),
    CONSTRAINT fk_items_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 7. TABLE : complaints
--    Plaintes clients (collectées manuellement via WhatsApp)
--    Table peu fiable, incomplète, usage interne uniquement.
-- ============================================================
DROP TABLE IF EXISTS complaints;
CREATE TABLE complaints (
    complaint_id    INT           NOT NULL AUTO_INCREMENT,
    order_id        INT           DEFAULT NULL,
    customer_id     VARCHAR(20)   DEFAULT NULL,
    complaint_date  DATE          DEFAULT NULL,
    complaint_type  VARCHAR(50)   DEFAULT NULL   COMMENT 'retard / produit_manquant / erreur_produit / livreur / qualité',
    description     TEXT          DEFAULT NULL,
    resolved        TINYINT(1)    DEFAULT 0,
    resolved_at     DATE          DEFAULT NULL,

    PRIMARY KEY (complaint_id),
    INDEX idx_complaints_order (order_id),
    INDEX idx_complaints_date (complaint_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- ============================================================
-- 8. DONNÉES DE RÉFÉRENCE : products
-- ============================================================

INSERT INTO products (product_id, product_name, product_category, base_price_xaf, is_available) VALUES
(101, 'Riz Uncle Ben''s 5kg', 'Épicerie', 3500, 1),
(102, 'Huile palme 1L', 'Épicerie', 1200, 1),
(103, 'Farine de blé 1kg', 'Épicerie', 800, 1),
(104, 'Sucre cristallisé 1kg', 'Épicerie', 650, 1),
(105, 'Sel iodé 500g', 'Épicerie', 250, 1),
(106, 'Lait Neslac 400g', 'Épicerie', 4200, 1),
(107, 'Pâtes alimentaires 500g', 'Épicerie', 750, 1),
(108, 'Tomate concentrée 400g', 'Épicerie', 900, 1),
(109, 'Sardines en boîte 200g', 'Épicerie', 1100, 1),
(110, 'Cube Maggi x10', 'Épicerie', 500, 1),
(201, 'Eau minérale 1.5L', 'Boissons', 400, 1),
(202, 'Coca-Cola 1.5L', 'Boissons', 800, 1),
(203, 'Bière Castel 65cl', 'Boissons', 700, 1),
(204, 'Jus Tampico 1L', 'Boissons', 1200, 1),
(205, 'Eau Supermont 10L', 'Boissons', 2500, 1),
(206, 'Nescafé 200g', 'Boissons', 3800, 1),
(301, 'Tomates fraîches 1kg', 'Produits frais', 600, 1),
(302, 'Oignons 1kg', 'Produits frais', 500, 1),
(303, 'Poulet entier 1kg', 'Produits frais', 4500, 1),
(304, 'Poisson Capitaine 1kg', 'Produits frais', 3500, 1),
(305, 'Plantains régime', 'Produits frais', 1500, 1),
(306, 'Légumes verts 500g', 'Produits frais', 400, 1),
(401, 'Paracétamol 500mg x16', 'Pharmacie', 1500, 1),
(402, 'Moustiquaire imprégnée', 'Pharmacie', 8500, 1),
(403, 'Préservatifs x3', 'Pharmacie', 1200, 1),
(404, 'Thermomètre digital', 'Pharmacie', 12000, 1),
(405, 'Sulfate de Zinc 20mg', 'Pharmacie', 3500, 1),
(501, 'Poulet DG portion', 'Restauration', 3500, 1),
(502, 'Ndolé haricot', 'Restauration', 2500, 1),
(503, 'Pizza Marguerita', 'Restauration', 6000, 1),
(504, 'Burger Classic', 'Restauration', 4500, 1),
(505, 'Jollof Rice portion', 'Restauration', 2000, 1),
(506, 'Eru + Water fufu', 'Restauration', 3000, 1),
(507, 'Spaghetti bolognaise', 'Restauration', 2800, 1),
(601, 'Câble USB-C 1m', 'Électronique', 2500, 1),
(602, 'Chargeur 20W', 'Électronique', 8500, 1),
(603, 'Écouteurs sans fil', 'Électronique', 25000, 1),
(604, 'Batterie externe 10000mAh', 'Électronique', 18000, 1),
(605, 'Coque téléphone', 'Électronique', 3500, 1),
(701, 'Crème Nivea 200ml', 'Cosmétiques', 3200, 1),
(702, 'Gel douche Dove 250ml', 'Cosmétiques', 2800, 1),
(703, 'Shampooing Pantene 400ml', 'Cosmétiques', 4500, 1),
(704, 'Déodorant Axe 150ml', 'Cosmétiques', 3500, 1),
(801, 'Savon Omo 400g', 'Hygiène', 800, 1),
(802, 'Lessive Ariel 1kg', 'Hygiène', 4500, 1),
(803, 'Brosse à dents', 'Hygiène', 1500, 1),
(804, 'Papier toilette x6', 'Hygiène', 2000, 1),
(901, 'T-shirt basique M', 'Vêtements', 5000, 1),
(902, 'Pagnes 6 yards', 'Vêtements', 18000, 1),
(903, 'Chaussures sport 42', 'Vêtements', 35000, 1),
(1001, 'Stylos x10', 'Papeterie', 1200, 1),
(1002, 'Cahier 100 pages', 'Papeterie', 800, 1),
(1003, 'Ramette A4 500 feuilles', 'Papeterie', 5000, 1);


-- ============================================================
-- 9. PROCÉDURES UTILES (exemples fournis pour prise en main)
-- ============================================================

-- Exemple 1 : Compter les commandes orphelines (sans client)
-- SELECT COUNT(*) AS orphan_orders
-- FROM orders o
-- LEFT JOIN customers c ON o.customer_id = c.customer_id
-- WHERE c.customer_id IS NULL;

-- Exemple 2 : Top 5 livreurs par nombre de commandes livrées
-- SELECT c.courier_id, c.name, COUNT(*) AS total_delivered
-- FROM couriers c
-- JOIN orders o ON c.courier_id = o.courier_id
-- WHERE o.status LIKE '%livr%'
-- GROUP BY c.courier_id, c.name
-- ORDER BY total_delivered DESC
-- LIMIT 5;

-- Exemple 3 : Chiffre d'affaires par ville (NOTE : status non normalisé !)
-- SELECT city, SUM(total_amount_xaf) AS ca_total
-- FROM orders
-- WHERE total_amount_xaf > 0
-- GROUP BY city;
-- ATTENTION : city contient 'Douala', 'douala', 'DOUALA' — résultats faussés !
-- Il faut normaliser avec TRIM(LOWER(city)) avant agrégation.

-- Exemple 4 : Identifier les doublons clients par téléphone
-- SELECT phone, COUNT(*) AS nb
-- FROM customers
-- WHERE phone IS NOT NULL
-- GROUP BY phone
-- HAVING COUNT(*) > 1
-- ORDER BY nb DESC;
-- NOTE : cette requête est insuffisante car les formats de téléphone varient.
-- Un vrai dédoublonnage nécessite normalisation préalable des formats.

-- Exemple 5 : Vue proposée (à construire par l'étudiant)
-- CREATE OR REPLACE VIEW v_order_kpis AS
-- SELECT ... -- À COMPLÉTER (Mission Semaine 2)


-- ============================================================
-- 10. NOTES POUR L'ÉTUDIANT
-- ============================================================
--
-- PROBLÈMES CONNUS À CORRIGER :
--
-- [P1] orders.order_date : VARCHAR avec formats hétérogènes.
--      Exemple : '14/03/2023 10:30', '2023-03-14 10:30:00', '14-03-2023'
--      → À convertir en DATETIME normalisée.
--
-- [P2] orders.status : Valeurs non normalisées.
--      Valeurs observées : 'livré','Livré','LIVRE','livre','livré ',
--                          'en_retard','En_retard','en retard','retard',
--                          'annulé','Annulé','ANNULE','en_cours','En_cours'
--      → Mapper vers : {delivered, late, cancelled, in_progress}
--
-- [P3] orders.city & customers.city : Casse variable.
--      Exemple : 'Douala','douala','DOUALA','Douala '
--      → TRIM(LOWER(city)) avant agrégation.
--
-- [P4] customers : Doublons.
--      ~280 clients ont des entrées dupliquées avec customer_id différent
--      mais même numéro de téléphone (formats différents).
--      → Normaliser les téléphones, puis dédoublonner.
--
-- [P5] orders.total_amount_xaf : Valeurs négatives (~2%) et NULL (~3%).
--      → Filtrer/traiter avant calcul du CA.
--
-- [P6] orders.product_category : ~15% NULL, orthographe variable.
--      → Normaliser et imputer si possible via order_items.
--
-- [P7] customers.loyalty_score : Valeurs > 100 (~4%) = outliers.
--      → Identifier et traiter (cap à 100 ou suppression).
--
-- [P8] orders sans correspondance dans customers (~3%).
--      → Ces commandes existent mais le client est introuvable.
--      Décider : inclure ou exclure des analyses de fidélisation.
--
-- ============================================================
-- FIN DU FICHIER schema_nexa.sql
-- ============================================================
