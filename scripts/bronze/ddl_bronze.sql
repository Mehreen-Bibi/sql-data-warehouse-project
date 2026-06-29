/*
 ============================================================================
   DDL Script: CREATE BRONZE TABLES
   ============================================================================
   Purpose  : Define raw staging tables in the 'bronze' schema.
              These tables mirror the source CSV structure exactly —
              no transformation or data type enforcement beyond basic types.
              Tables are dropped and recreated to allow schema evolution.
   ============================================================================ 
*/

-- ----------------------------------------------------------------------------
-- bronze.crm_cust_info  |  Source: CRM – Customer Master Data
-- ----------------------------------------------------------------------------
IF OBJECT_ID('bronze.crm_cust_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_cust_info;
GO
CREATE TABLE bronze.crm_cust_info (
    cst_id             INT,            -- Unique customer identifier
    cst_key            NVARCHAR(50),   -- Natural key from source CRM
    cst_firstname      NVARCHAR(50),
    cst_lastname       NVARCHAR(50),
    cst_marital_status NVARCHAR(50),   -- Raw value (e.g. 'S', 'M')
    cst_gndr           NVARCHAR(50),   -- Raw value (e.g. 'F', 'M')
    cst_create_date    DATE
);
GO

-- ----------------------------------------------------------------------------
-- bronze.crm_prd_info  |  Source: CRM – Product Master Data
-- ----------------------------------------------------------------------------
IF OBJECT_ID('bronze.crm_prd_info', 'U') IS NOT NULL
    DROP TABLE bronze.crm_prd_info;
GO
CREATE TABLE bronze.crm_prd_info (
    prd_id       INT,
    prd_key      NVARCHAR(50),   -- Encodes both category ID and product key
    prd_nm       NVARCHAR(50),
    prd_cost     INT,
    prd_line     NVARCHAR(50),   -- Raw value (e.g. 'M', 'R', 'S', 'T')
    prd_start_dt DATETIME,
    prd_end_dt   DATETIME
);
GO

-- ----------------------------------------------------------------------------
-- bronze.crm_sales_details  |  Source: CRM – Transactional Sales Data
-- ----------------------------------------------------------------------------
IF OBJECT_ID('bronze.crm_sales_details', 'U') IS NOT NULL
    DROP TABLE bronze.crm_sales_details;
GO
CREATE TABLE bronze.crm_sales_details (
    sls_ord_num   NVARCHAR(50),
    sls_prd_key   NVARCHAR(50),
    sls_cust_id   INT,
    sls_order_dt  INT,    -- Stored as integer YYYYMMDD in source
    sls_ship_dt   INT,    -- Stored as integer YYYYMMDD in source
    sls_due_dt    INT,    -- Stored as integer YYYYMMDD in source
    sls_sales     INT,
    sls_quantity  INT,
    sls_price     INT
);
GO

-- ----------------------------------------------------------------------------
-- bronze.erp_cust_az12  |  Source: ERP – Customer Demographics
-- ----------------------------------------------------------------------------
IF OBJECT_ID('bronze.erp_cust_az12', 'U') IS NOT NULL
    DROP TABLE bronze.erp_cust_az12;
GO
CREATE TABLE bronze.erp_cust_az12 (
    cid   NVARCHAR(50),   -- May contain 'NAS' prefix to be stripped in Silver
    bdate DATE,
    gen   NVARCHAR(50)    -- Raw gender value (e.g. 'F', 'Female', 'M', 'Male')
);
GO

-- ----------------------------------------------------------------------------
-- bronze.erp_loc_a101  |  Source: ERP – Customer Location Data
-- ----------------------------------------------------------------------------
IF OBJECT_ID('bronze.erp_loc_a101', 'U') IS NOT NULL
    DROP TABLE bronze.erp_loc_a101;
GO
CREATE TABLE bronze.erp_loc_a101 (
    cid   NVARCHAR(50),   -- May contain dashes to be stripped in Silver
    cntry NVARCHAR(50)    -- Raw country code (e.g. 'US', 'USA', 'DE')
);
GO

-- ----------------------------------------------------------------------------
-- bronze.erp_px_cat_g1v2  |  Source: ERP – Product Category Reference
-- ----------------------------------------------------------------------------
IF OBJECT_ID('bronze.erp_px_cat_g1v2', 'U') IS NOT NULL
    DROP TABLE bronze.erp_px_cat_g1v2;
GO
CREATE TABLE bronze.erp_px_cat_g1v2 (
    id          NVARCHAR(50),
    cat         NVARCHAR(50),
    subcat      NVARCHAR(50),
    maintenance NVARCHAR(50)
);
GO
