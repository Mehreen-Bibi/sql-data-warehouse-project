/*
============================================================================
CREATE DATABASE & SCHEMA SETUP
============================================================================
Purpose  : Create the DataWarehouse database and its three schemas.
WARNING  : This drops and recreates the entire DataWarehouse database.
            ALL existing data will be permanently lost.
            Ensure backups exist before running this section.
============================================================================
*/

USE master;
GO

-- Drop the existing DataWarehouse database (if present) and recreate it cleanly
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
	
    ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE DataWarehouse;

END;
GO

CREATE DATABASE DataWarehouse;
GO

USE DataWarehouse;
GO

-- Create the three Medallion Architecture schemas
CREATE SCHEMA bronze; -- Raw data ingested directly from source systems
GO
	
CREATE SCHEMA silver; -- Cleansed, transformed, and enriched data
GO
	
CREATE SCHEMA gold;   -- Business-ready views (Star Schema for analytics)
GO
