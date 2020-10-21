--------------------------------------------------------------------------------------------------------------------------------------------
--
-- Author      : Prithiviraj Seegolam
-- Date        : 22 Oct 2020
-- Version     : 1.0
-- Description : Package to clean and migrate data from XXBCM_ORDER_MGT to XXBCM_SUPPLIERS_TBL and XXBCM_TRANSACTIONS_TBL tables.
--               Procedure PROC_XXBCM_STAGING => Cleans the data from the table XXBCM_ORDER_MGT and inserts them into XXBCM_ORDER_MGT_STG
--                                               table.
--
--               Procedure PROC_MIGRATE_SUPPLIERS => Retrieves suppliers related data from XXBCM_ORDER_MGT_STG table, formats the data 
--                                                   and inserts them into XXBCM_SUPPLIERS_TBL table.
--
--               Procedure PROC_MIGRATE_TRANSACTIONS => Retrieves transactions related data from XXBCM_ORDER_MGT_STG table, formats the
--                                                      data and inserts them into XXBCM_TRANSACTIONS_TBL table.
--
--------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PACKAGE PKG_XXBCM_ORDER_MGT AS
	PROCEDURE PROC_XXBCM_STAGING;
	PROCEDURE PROC_MIGRATE_SUPPLIERS;
	PROCEDURE PROC_MIGRATE_TRANSACTIONS;
END PKG_XXBCM_ORDER_MGT;
/


CREATE OR REPLACE PACKAGE BODY PKG_XXBCM_ORDER_MGT AS
	PROCEDURE PROC_XXBCM_STAGING IS
			CURSOR CUR_XXBCM_DATA IS
			SELECT *
			FROM XXBCM_ORDER_MGT
			ORDER BY ORDER_REF;
			R_DATA CUR_XXBCM_DATA%ROWTYPE;
			TEMP_ORDR_AMT VARCHAR2(50);
			TEMP_INV_AMT VARCHAR2(50);
		BEGIN
			OPEN CUR_XXBCM_DATA;
			LOOP
				FETCH CUR_XXBCM_DATA INTO R_DATA;
				EXIT WHEN CUR_XXBCM_DATA%NOTFOUND;
				IF INSTR(R_DATA.ORDER_LINE_AMOUNT, 'I') > 0 THEN
					IF INSTR(R_DATA.INVOICE_AMOUNT, 'I') > 0 THEN
						TEMP_ORDR_AMT := R_DATA.ORDER_TOTAL_AMOUNT;
						TEMP_INV_AMT := R_DATA.ORDER_TOTAL_AMOUNT;
					ELSE
						TEMP_ORDR_AMT := R_DATA.INVOICE_AMOUNT;
						TEMP_INV_AMT := R_DATA.INVOICE_AMOUNT;
					END IF;
				ELSE
					TEMP_ORDR_AMT := R_DATA.ORDER_LINE_AMOUNT;
					TEMP_INV_AMT := R_DATA.INVOICE_AMOUNT;
				END IF;
				INSERT INTO XXBCM_ORDER_MGT_STG (
					ORDER_REF
					,ORDER_DATE
					,SUPPLIER_NAME
					,SUPP_CONTACT_NAME
					,SUPP_ADDRESS
					,SUPP_CONTACT_NUMBER
					,SUPP_EMAIL
					,ORDER_TOTAL_AMOUNT
					,ORDER_DESCRIPTION
					,ORDER_STATUS
					,ORDER_LINE_AMOUNT
					,INVOICE_REFERENCE
					,INVOICE_DATE
					,INVOICE_STATUS
					,INVOICE_HOLD_REASON
					,INVOICE_AMOUNT
					,INVOICE_DESCRIPTION
					)
				VALUES (
					R_DATA.ORDER_REF             
					, R_DATA.ORDER_DATE             
					, R_DATA.SUPPLIER_NAME         
					, R_DATA.SUPP_CONTACT_NAME     
					, R_DATA.SUPP_ADDRESS          
					, REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(R_DATA.SUPP_CONTACT_NUMBER , 'I', '1') , 'S', '5') , 'o', '0') , '.', '') , ' ', '')
					, R_DATA.SUPP_EMAIL              
					, REPLACE(REPLACE(REPLACE(R_DATA.ORDER_TOTAL_AMOUNT, 'S', '5'), 'o', '0') , ',', '')
					, R_DATA.ORDER_DESCRIPTION      
					, R_DATA.ORDER_STATUS          
					, REPLACE(REPLACE(REPLACE(TEMP_ORDR_AMT, 'S', '5'), 'o', '0') , ',', '')
					, R_DATA.INVOICE_REFERENCE      
					, R_DATA.INVOICE_DATE     
					, R_DATA.INVOICE_STATUS          
					, R_DATA.INVOICE_HOLD_REASON    
					, REPLACE(REPLACE(REPLACE(TEMP_INV_AMT, 'S', '5'), 'o', '0') , ',', '')
					, R_DATA.INVOICE_DESCRIPTION
				);
			END LOOP;
			CLOSE CUR_XXBCM_DATA;
			COMMIT;
	END PROC_XXBCM_STAGING;
	
	PROCEDURE PROC_MIGRATE_SUPPLIERS IS
			CURSOR CUR_SUPPLIERS_DATA IS
			SELECT DISTINCT
			SUPPLIER_NAME
			,SUPP_CONTACT_NAME
			,SUPP_ADDRESS
			,SUPP_CONTACT_NUMBER
			,SUPP_EMAIL
			FROM XXBCM_ORDER_MGT_STG;
			R_SUPPLIERS CUR_SUPPLIERS_DATA%ROWTYPE;
			TEMP_NUM1 VARCHAR2(8);
			TEMP_NUM2 VARCHAR2(8);
			V_TEL_NUM VARCHAR2(7);
			V_MOB_NUM VARCHAR2(8);
			V_STREET VARCHAR2(100);
			V_CITY VARCHAR2(100);
			V_COUNTRY VARCHAR2(100);
			V_FNAME VARCHAR2(100);
			V_LNAME VARCHAR2(100);
		BEGIN
			OPEN CUR_SUPPLIERS_DATA;
			LOOP
				FETCH CUR_SUPPLIERS_DATA INTO R_SUPPLIERS;
				EXIT WHEN CUR_SUPPLIERS_DATA%NOTFOUND;
				IF INSTR(R_SUPPLIERS.SUPP_CONTACT_NUMBER, ',') > 0 THEN
					TEMP_NUM1 := SUBSTR(R_SUPPLIERS.SUPP_CONTACT_NUMBER,1,INSTR(R_SUPPLIERS.SUPP_CONTACT_NUMBER, ',', -1)-1);
					TEMP_NUM2 := SUBSTR(R_SUPPLIERS.SUPP_CONTACT_NUMBER, INSTR(R_SUPPLIERS.SUPP_CONTACT_NUMBER, ',', -1)+1);
					IF LENGTH(TEMP_NUM1) = 7 THEN
						V_TEL_NUM := TEMP_NUM1;
					ELSIF LENGTH(TEMP_NUM1) = 8 THEN
						V_MOB_NUM := TEMP_NUM1;
					END IF;
					IF LENGTH(TEMP_NUM2) = 7 THEN
						V_TEL_NUM := TEMP_NUM2;
					ELSIF LENGTH(TEMP_NUM2) = 8 THEN
						V_MOB_NUM := TEMP_NUM2;
					END IF;
				ELSE
					IF LENGTH(R_SUPPLIERS.SUPP_CONTACT_NUMBER) = 7 THEN
						V_TEL_NUM := R_SUPPLIERS.SUPP_CONTACT_NUMBER;
					ELSIF LENGTH(R_SUPPLIERS.SUPP_CONTACT_NUMBER) = 8 THEN
						V_MOB_NUM := R_SUPPLIERS.SUPP_CONTACT_NUMBER;
					END IF;
				END IF;
				IF SUBSTR(R_SUPPLIERS.SUPP_ADDRESS,INSTR(R_SUPPLIERS.SUPP_ADDRESS, ',', -1)+2) = 'Mauritius' THEN
					V_STREET := SUBSTR(R_SUPPLIERS.SUPP_ADDRESS,1,INSTR(SUBSTR(R_SUPPLIERS.SUPP_ADDRESS,1,INSTR(R_SUPPLIERS.SUPP_ADDRESS, ',', -1)-1), ',', -1)-1);
					V_CITY := SUBSTR(SUBSTR(R_SUPPLIERS.SUPP_ADDRESS,1,INSTR(R_SUPPLIERS.SUPP_ADDRESS, ',', -1)-1),INSTR(SUBSTR(R_SUPPLIERS.SUPP_ADDRESS,1,INSTR(R_SUPPLIERS.SUPP_ADDRESS, ',', -1)-1), ',', -1)+2);
					V_COUNTRY := SUBSTR(R_SUPPLIERS.SUPP_ADDRESS,INSTR(R_SUPPLIERS.SUPP_ADDRESS, ',', -1)+2);
				ELSE
					V_STREET := SUBSTR(R_SUPPLIERS.SUPP_ADDRESS,1,INSTR(R_SUPPLIERS.SUPP_ADDRESS, ',', -1)-1);
					V_CITY := SUBSTR(R_SUPPLIERS.SUPP_ADDRESS,INSTR(R_SUPPLIERS.SUPP_ADDRESS, ',', -1)+2);
					V_COUNTRY := 'Mauritius';
				END IF;
				V_FNAME := SUBSTR(R_SUPPLIERS.SUPP_CONTACT_NAME,1,INSTR(R_SUPPLIERS.SUPP_CONTACT_NAME, ' ',1)-1 );
				V_LNAME := SUBSTR(R_SUPPLIERS.SUPP_CONTACT_NAME,INSTR(R_SUPPLIERS.SUPP_CONTACT_NAME, ' ', -1)+1);
				INSERT INTO XXBCM_SUPPLIERS_TBL (
					SUPP_NAME,
					CONTACT_FNAME,
					CONTACT_LNAME,
					STREET,
					CITY,
					COUNTRY,
					TEL_NUM,
					MOB_NUM,
					EMAIL
					) VALUES (
					R_SUPPLIERS.SUPPLIER_NAME,
					V_FNAME,
					V_LNAME,
					V_STREET,
					V_CITY,
					V_COUNTRY,
					V_TEL_NUM,
					V_MOB_NUM,
					R_SUPPLIERS.SUPP_EMAIL
				);
			END LOOP;
			CLOSE CUR_SUPPLIERS_DATA;
			COMMIT;
	END PROC_MIGRATE_SUPPLIERS;
	
	PROCEDURE PROC_MIGRATE_TRANSACTIONS IS
			CURSOR CUR_TRANSACTIONS_DATA IS
			SELECT
			ORDER_REF, 
			ORDER_DATE, 
			ORDER_TOTAL_AMOUNT, 
			ORDER_DESCRIPTION, 
			ORDER_STATUS, 
			ORDER_LINE_AMOUNT, 
			INVOICE_REFERENCE, 
			INVOICE_DATE, 
			INVOICE_STATUS, 
			INVOICE_HOLD_REASON, 
			INVOICE_AMOUNT, 
			INVOICE_DESCRIPTION,
			SUPPLIER_NAME
			FROM XXBCM_ORDER_MGT_STG;
			R_TRANSACTIONS CUR_TRANSACTIONS_DATA%ROWTYPE;
			V_ORDER_DATE DATE;
			V_ORDER_TOTAL_AMT NUMBER(18);
			V_ORDER_LINE_AMT NUMBER(18);
			V_ORDER_REF VARCHAR(25);
			V_ORDER_DESCRIPTION VARCHAR2(300);
			V_ORDER_STATUS VARCHAR2(25);
			V_INV_DATE DATE;
			V_INV_AMT NUMBER(18);
			V_INV_REF VARCHAR(25);
			V_INV_DESCRIPTION VARCHAR2(300);
			V_INV_STATUS VARCHAR2(25);
			V_INV_HOLD_REASON VARCHAR2(200);
			V_SUPPLIER_NAME VARCHAR2(200);
		BEGIN
			OPEN CUR_TRANSACTIONS_DATA;
			LOOP
				FETCH CUR_TRANSACTIONS_DATA INTO R_TRANSACTIONS;
				EXIT WHEN CUR_TRANSACTIONS_DATA%NOTFOUND; 
				IF LENGTH(R_TRANSACTIONS.ORDER_DATE) = 11 THEN
					V_ORDER_DATE := TO_DATE(R_TRANSACTIONS.ORDER_DATE, 'DD-MON-YYYY');
				ELSIF LENGTH(R_TRANSACTIONS.ORDER_DATE) = 10 THEN
					V_ORDER_DATE := TO_DATE(R_TRANSACTIONS.ORDER_DATE, 'DD-MM-YYYY');
				END IF;
				IF R_TRANSACTIONS.ORDER_TOTAL_AMOUNT IS NOT NULL THEN
					V_ORDER_TOTAL_AMT := TO_NUMBER(R_TRANSACTIONS.ORDER_TOTAL_AMOUNT);
				ELSE
					V_ORDER_TOTAL_AMT := 0;
				END IF;
				IF R_TRANSACTIONS.ORDER_LINE_AMOUNT IS NOT NULL THEN
					V_ORDER_LINE_AMT := TO_NUMBER(R_TRANSACTIONS.ORDER_LINE_AMOUNT);
				ELSE
					V_ORDER_LINE_AMT := 0;
				END IF;
				V_ORDER_REF := R_TRANSACTIONS.ORDER_REF;
				V_ORDER_DESCRIPTION := R_TRANSACTIONS.ORDER_DESCRIPTION;
				V_ORDER_STATUS := R_TRANSACTIONS.ORDER_STATUS;
				V_SUPPLIER_NAME := R_TRANSACTIONS.SUPPLIER_NAME;
				IF LENGTH(R_TRANSACTIONS.INVOICE_DATE) = 11 THEN
					V_INV_DATE := TO_DATE(R_TRANSACTIONS.INVOICE_DATE, 'DD-MON-YYYY');
				ELSIF LENGTH(R_TRANSACTIONS.INVOICE_DATE) = 10 THEN
					V_INV_DATE := TO_DATE(R_TRANSACTIONS.INVOICE_DATE, 'DD-MM-YYYY');
				END IF;
				IF R_TRANSACTIONS.INVOICE_AMOUNT IS NOT NULL THEN
					V_INV_AMT := TO_NUMBER(R_TRANSACTIONS.INVOICE_AMOUNT);
				ELSE 
					V_INV_AMT := 0;
				END IF;
				V_INV_REF := R_TRANSACTIONS.INVOICE_REFERENCE;
				V_INV_DESCRIPTION := R_TRANSACTIONS.INVOICE_DESCRIPTION;
				V_INV_STATUS := R_TRANSACTIONS.INVOICE_STATUS;
				V_INV_HOLD_REASON := R_TRANSACTIONS.INVOICE_HOLD_REASON;
				V_SUPPLIER_NAME := R_TRANSACTIONS.SUPPLIER_NAME;
				INSERT INTO XXBCM_TRANSACTIONS_TBL (
					ORDER_REF,
					ORDER_DATE,
					TOTAL_AMT,
					ORDER_DESCRIPTION,
					ORDER_STATUS,
					LINE_AMT,
					INV_REF,
					INV_DATE,
					INV_STATUS,
					INV_HOLD_REASON,
					INV_AMOUNT,
					INV_DESCRIPTION,
					SUPP_NAME
					) VALUES (
					V_ORDER_REF             
					, V_ORDER_DATE     
					, V_ORDER_TOTAL_AMT 
					, V_ORDER_DESCRIPTION 
					, V_ORDER_STATUS         
					, V_ORDER_LINE_AMT 
					, V_INV_REF
					, V_INV_DATE
					, V_INV_STATUS
					, V_INV_HOLD_REASON
					, V_INV_AMT
					, V_INV_DESCRIPTION
					, V_SUPPLIER_NAME);
			END LOOP;
			CLOSE CUR_TRANSACTIONS_DATA;
			COMMIT;
	END PROC_MIGRATE_TRANSACTIONS;
END PKG_XXBCM_ORDER_MGT;
/