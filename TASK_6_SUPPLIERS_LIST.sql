--------------------------------------------------------------------------------------------------------------------------------------------
--
-- Author      : Prithiviraj Seegolam
-- Date        : 22 Oct 2020
-- Version     : 1.0
-- Description : Function to provide the list of all suppliers with their respective number of orders and total amount ordered from them 
--               between the period of 01 January 2017 and 31 August 2017.
--
--------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION FUNC_SUPPLIERS_LIST
RETURN SYS_REFCURSOR
AS
my_cursor SYS_REFCURSOR;
BEGIN
   OPEN my_cursor FOR 
   SELECT
    SUPP.SUPP_NAME,
    (SUPP.CONTACT_FNAME || ' ' || SUPP.CONTACT_LNAME) CONTACT_NAME,
    SUPP.TEL_NUM,
    SUPP.MOB_NUM,
    COUNT(TRA.ORDER_REF) ORDERS,
    SUM(TRA.TOTAL_AMT) TOTAL_AMT
    FROM XXBCM_SUPPLIERS_TBL SUPP,
    XXBCM_TRANSACTIONS_TBL TRA
    WHERE TRA.SUPP_NAME = SUPP.SUPP_NAME
    AND TRA.ORDER_DATE BETWEEN TO_DATE('01/01/2017', 'DD/MM/YYYY') AND TO_DATE('31/08/2017', 'DD/MM/YYYY')
    GROUP BY
    SUPP.SUPP_NAME,
    SUPP.CONTACT_FNAME || ' ' || SUPP.CONTACT_LNAME,
    SUPP.TEL_NUM,
    SUPP.MOB_NUM;
   RETURN my_cursor;
END FUNC_SUPPLIERS_LIST;
/




----------------------
-- EXECUTION
----------------------

DECLARE
    mycursor SYS_REFCURSOR;
    TYPE myrectype IS RECORD
    (
		SUPP_NAME VARCHAR2(200),
		CONTACT_NAME VARCHAR2(200),
		TEL_NUM VARCHAR2(7),
		MOB_NUM VARCHAR2(8),
		ORDERS INT,
		TOTAL_AMT NUMERIC(18,2)
	);
	r myrectype;
	V_TEL_NUM VARCHAR2(10);
	V_MOB_NUM VARCHAR2(10);
BEGIN
    mycursor := FUNC_SUPPLIERS_LIST();
    LOOP
        FETCH mycursor INTO r;
        EXIT WHEN mycursor%NOTFOUND;
		IF r.TEL_NUM IS NULL THEN
			V_TEL_NUM := 'NA';
		ELSE
			V_TEL_NUM := SUBSTR(r.TEL_NUM, 1, 3) || '-' || SUBSTR(r.TEL_NUM, 4);
		END IF;
		IF r.MOB_NUM IS NULL THEN
			V_MOB_NUM := 'NA';
		ELSE
			V_MOB_NUM := SUBSTR(r.MOB_NUM, 1, 4) || '-' || SUBSTR(r.MOB_NUM, 5);
		END IF;
        DBMS_OUTPUT.PUT_LINE('Supplier Name : ' || r.SUPP_NAME);
        DBMS_OUTPUT.PUT_LINE('Supplier Contact Name : ' || r.CONTACT_NAME);
        DBMS_OUTPUT.PUT_LINE('Supplier Contact No.1 : ' || V_TEL_NUM);
		DBMS_OUTPUT.PUT_LINE('Supplier Contact No.2 : ' || V_MOB_NUM);
		DBMS_OUTPUT.PUT_LINE('Total Orders : ' || TO_CHAR(r.ORDERS));
        DBMS_OUTPUT.PUT_LINE('Order Total Amount : ' || TO_CHAR(r.TOTAL_AMT,'99G999G990D99'));
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('-------------------------------------');
    END LOOP;
    CLOSE mycursor;
END;
/