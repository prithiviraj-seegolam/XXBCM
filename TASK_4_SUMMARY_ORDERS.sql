--------------------------------------------------------------------------------------------------------------------------------------------
--
-- Author      : Prithiviraj Seegolam
-- Date        : 22 Oct 2020
-- Version     : 1.0
-- Description : Function to provide a list of distinct invoices and their total amount to be able to reconcile his orders and payments.
--
--------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION FUNC_SUMMARY_ORDERS
RETURN SYS_REFCURSOR
AS
my_cursor SYS_REFCURSOR;
BEGIN
   OPEN my_cursor FOR 
   SELECT * 
    FROM (
    SELECT
    ORDER_REF,
    ORDER_DATE,
    SUPP_NAME,
    SUM(TOTAL_AMT) TOTAL_AMT,
    ORDER_STATUS,
    INV_REF,
    SUM(INV_AMOUNT) INV_AMT,
    INV_STATUS
    FROM XXBCM_TRANSACTIONS_TBL
    WHERE INSTR(ORDER_REF, '-') = 0
    GROUP BY
    ORDER_REF,
    ORDER_DATE,
    SUPP_NAME,
    ORDER_STATUS,
    INV_REF,
    INV_STATUS
    UNION ALL
    SELECT
    SUBSTR(ORDER_REF, 1,INSTR(ORDER_REF, '-', -1)-1) ORDER_REF,
    ORDER_DATE,
    SUPP_NAME,
    SUM(TOTAL_AMT) TOTAL_AMT,
    ORDER_STATUS,
    INV_REF,
    SUM(INV_AMOUNT) INV_AMT,
    INV_STATUS
    FROM XXBCM_TRANSACTIONS_TBL
    WHERE INSTR(ORDER_REF, '-') > 0
    GROUP BY
    SUBSTR(ORDER_REF, 1,INSTR(ORDER_REF, '-', -1)-1),
    ORDER_DATE,
    SUPP_NAME,
    ORDER_STATUS,
    INV_REF,
    INV_STATUS)
    ORDER BY ORDER_REF, TOTAL_AMT DESC, INV_REF DESC;
   RETURN my_cursor;
END FUNC_SUMMARY_ORDERS;
/


----------------------
-- EXECUTION
----------------------
DECLARE
    mycursor SYS_REFCURSOR;
    TYPE myrectype IS RECORD
    (
		ORDER_REF VARCHAR2(10),
		ORDER_DATE DATE,
		SUPP_NAME VARCHAR2(200),
		TOTAL_AMT NUMERIC(18,2),
		ORDER_STATUS VARCHAR2(15),
		INV_REF VARCHAR2(15),
		INV_AMT NUMERIC(18,2),
		INV_STATUS VARCHAR2(15) 
	);
    r myrectype;
    v_action VARCHAR2(30);
BEGIN
    mycursor := FUNC_SUMMARY_ORDERS();
    LOOP
        FETCH mycursor INTO r;
        EXIT WHEN mycursor%NOTFOUND;
        IF r.INV_STATUS = 'Paid' THEN
            V_ACTION := 'OK';
        ELSIF r.INV_STATUS = 'Pending' THEN
            V_ACTION := 'To follow up';
        ELSIF r.INV_STATUS IS NULL OR r.INV_STATUS = '' THEN
            V_ACTION := 'To verify';
        END IF;
        DBMS_OUTPUT.PUT_LINE('Order Reference : ' || TO_NUMBER(REPLACE(r.ORDER_REF, 'PO', '')));
        DBMS_OUTPUT.PUT_LINE('Order Date : ' || TO_CHAR(r.ORDER_DATE, 'MON-YY'));
        DBMS_OUTPUT.PUT_LINE('Supplier Name : ' || INITCAP(r.SUPP_NAME));
        DBMS_OUTPUT.PUT_LINE('Order Total Amount : ' || TO_CHAR(r.TOTAL_AMT,'99G999G990D99'));
        DBMS_OUTPUT.PUT_LINE('Order Status : ' || r.ORDER_STATUS);
        DBMS_OUTPUT.PUT_LINE('Invoice Reference : ' || r.INV_REF);
        DBMS_OUTPUT.PUT_LINE('Invoice Total Amount : ' || TO_CHAR(r.INV_AMT,'99G999G990D99'));
        DBMS_OUTPUT.PUT_LINE('Action : ' || V_ACTION);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('-------------------------------------');
    END LOOP;
    CLOSE mycursor;
END;
/