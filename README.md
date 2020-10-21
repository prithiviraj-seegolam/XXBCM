# XXBCM Assessment #

## Steps to follow for Data Migration: ##
1. Execute the **DB_PREREQUISITE.sql** which will create the **XXBCM_ORDER_MGT** table and insert all the raw data

2. Execute the **TABLES.sql** which will create the below tables:
    * **XXBCM_ORDER_MGT_STG** : Staging table which will contain all the cleaned data
    * **XXBCM_SUPPLIERS_TBL** : Table containing all the data related to suppliers
    * **XXBCM_TRANSACTIONS_TBL**: Table containing all the data related to transactions (orders & invoices)

3. Compile the package **PKG_XXBCM_ORDER_MGT** from the file **PKG_XXBCM_ORDER_MGT.sql**

4. Execute the below procedures to perform the migration of data :
    * **PROC_XXBCM_STAGING**: Clean the raw data and insert the cleaned data in the staging table
    * **PROC_MIGRATE_SUPPLIERS**: Retrieves data from staging table, format the data (if necessary) and insert data into **XXBCM_SUPPLIERS_TBL** table
    * **PROC_MIGRATE_TRANSACTIONS**: Retrieves data from staging table, format the data (if necessary) and insert data into **XXBCM_TRANSACTIONS_TBL** table


## Tasks: ##
* **TASK_4_SUMMARY_ORDERS.sql** : Upon execution, a summary of Orders with their corresponding list of distinct invoices and their total amount to be able to reconcile his orders and payments will be displayed

* **TASK_5_THIRD_HIGHEST_ORDER.sql** : Upon execution, will return details for the THIRD (3rd) highest Order Total Amount from the list

* **TASK_6_SUPPLIERS_LIST.sql**: Upon execution will list all suppliers with their respective number of orders and total amount ordered from them between the period of 01 January 2017 and 31 August 2017
