/*
============================================================================
DDL Scripts:  GOLD VIEWS (STAR SCHEMA)
============================================================================
Purpose  : Create business-ready views in the 'gold' schema implementing
           a Star Schema suitable for BI tools and analytics queries.

Model:
    gold.dim_customers   – Customer dimension (SCD Type 0, current snapshot)
    gold.dim_products    – Product dimension  (current products only)
    gold.fact_sales      – Sales fact table   (grain: one row per order line)

Design notes:
    • Surrogate keys (customer_key, product_key) are generated via ROW_NUMBER()
    • CRM is the master system for gender; ERP is the fallback
    • Historical product records (prd_end_dt IS NOT NULL) are excluded from
      dim_products to keep the dimension current
============================================================================
*/

-- ----------------------------------------------------------------------------
-- gold.dim_customers  |  Customer Dimension
-- ----------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
	DROP VIEW gold.dim_customers;
GO

CREATE VIEW gold.dim_customers AS
/*
    Combines CRM customer master data with ERP demographics (birthdate, gender)
    and ERP location data (country).  CRM is the master source for gender;
    ERP gen value is used only when CRM reports 'n/a'.
*/
SELECT
	ROW_NUMBER() OVER(ORDER BY ci.cst_key) AS customer_key,  -- Surrogate key
	ci.cst_id                              AS customer_id,   -- Source system ID
	ci.cst_key                             AS customer_number,
	ci.cst_firstname                       AS first_name,
	ci.cst_lastname                        AS last_name,
	la.cntry                               AS country,
	ci.cst_marital_status                  AS marital_status,
	CASE
		WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr -- CRM is the Master for gender Info
		ELSE COALESCE(ca.gen, 'n/a')
	END                                    AS gender,
	ca.bdate                               AS birthdate,
	ci.cst_create_date                     AS create_date
FROM silver.crm_cust_info ci
LEFT JOIN silver.erp_cust_az12 ca
	ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
	ON ci.cst_key = la.cid;
GO

-- ----------------------------------------------------------------------------
-- gold.dim_products  |  Product Dimension (current records only)
-- ----------------------------------------------------------------------------
IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
	DROP VIEW gold.dim_products;
GO

CREATE VIEW gold.dim_products AS
/*
    Joins CRM product master with ERP category reference to produce a fully
    described product dimension.  Only current (active) products are included —
    historical versions where prd_end_dt IS NOT NULL are excluded.
*/
SELECT 
	ROW_NUMBER() OVER(ORDER BY pn.prd_start_dt, pn.prd_key) AS product_key, -- Surrogate key
	pn.prd_id                                               AS product_id,
	pn.prd_key                                              AS product_number,
	pn.prd_nm                                               AS product_name,
	pn.cat_id                                               AS category_id,
	pc.cat                                                  AS category,
	pc.subcat                                               AS subcategory,
	pc.maintenance,
	pn.prd_cost                                             AS cost,
	pn.prd_line                                             AS product_line,
	pn.prd_start_dt	                                        AS start_date
FROM silver.crm_prd_info pn
LEFT JOIN silver.erp_px_cat_g1v2 pc
	ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL; -- Exclude historical/superseded product versions
GO

-- ----------------------------------------------------------------------------
-- gold.fact_sales  |  Sales Fact Table
-- ----------------------------------------------------------------------------
IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
	DROP VIEW gold.fact_sales;
GO

CREATE VIEW gold.fact_sales AS
/*
    Grain    : One row per order line item.
    Measures : sales_amount, quantity, price.
    Keys     : Surrogate keys resolved by joining to dim_customers and dim_products.
*/
SELECT 
	sls_ord_num  AS order_number, -- FK → gold.dim_products
	pr.product_key,               -- FK → gold.dim_customers
	cu.customer_key,
	sls_order_dt AS order_date,
	sls_ship_dt  AS shipping_date,
	sls_due_dt   AS due_date,
	sls_sales    AS sales_amount,
	sls_quantity AS quantity,
	sls_price    AS price
FROM silver.crm_sales_details sd
LEFT JOIN gold.dim_products pr
	ON sd.sls_prd_key = pr.product_number
LEFT JOIN gold.dim_customers cu
	ON sd.sls_cust_id = cu.customer_id;
GO
