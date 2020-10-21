--------------------------------------------------------------------------------------------------------------------------------------------
--
-- Author      : Prithiviraj Seegolam
-- Date        : 22 Oct 2020
-- Version     : 1.0
-- Description : Function to provide the THIRD (3rd) highest Order Total Amount from the list.
--
--------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION FUNC_THIRD_HIGHEST_ORDER
RETURN SYS_REFCURSOR
AS
my_cursor SYS_REFCURSOR;
BEGIN
   OPEN my_cursor FOR 
   SELECT
	ORDER_REF,
	ORDER_DATE,
	SUPP_NAME,
	TOTAL_AMT,
	ORDER_STATUS,
	(SELECT  listagg(INV_REF, ', ') within GROUP (ORDER BY INV_REF) AS INV_REFS
	 FROM (SELECT DISTINCT  INV_REF
			FROM XXBCM_TRANSACTIONS_TBL
			WHERE ORDER_REF LIKE (SELECT ORDER_REF || '%'
									FROM (SELECT TR2.*, ROWNUM rnum FROM
																	(SELECT * FROM XXBCM_TRANSACTIONS_TBL ORDER BY TOTAL_AMT DESC) TR2
																	WHERE ROWNUM <= 3 )
									WHERE rnum >= 3)
			AND INV_REF IS NOT NULL
	ORDER BY INV_REF)) INVOICES
	FROM (SELECT TR2.*, ROWNUM rnum FROM
									(SELECT * FROM XXBCM_TRANSACTIONS_TBL ORDER BY TOTAL_AMT DESC) TR2
									WHERE ROWNUM <= 3 )
	WHERE rnum >= 3;
   RETURN my_cursor;
END FUNC_THIRD_HIGHEST_ORDER;
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
		INVOICES VARCHAR2(200)
	);
	r myrectype;
BEGIN
    mycursor := FUNC_THIRD_HIGHEST_ORDER();
    LOOP
        FETCH mycursor INTO r;
        EXIT WHEN mycursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('Order Reference : ' || TO_NUMBER(REPLACE(r.ORDER_REF, 'PO', '')));
        DBMS_OUTPUT.PUT_LINE('Order Date : ' || TO_CHAR(r.ORDER_DATE, 'FMMonth DD, YYYY'));
        DBMS_OUTPUT.PUT_LINE('Supplier Name : ' || UPPER(r.SUPP_NAME));
        DBMS_OUTPUT.PUT_LINE('Order Total Amount : ' || TO_CHAR(r.TOTAL_AMT,'99G999G990D99'));
        DBMS_OUTPUT.PUT_LINE('Order Status : ' || r.ORDER_STATUS);
        DBMS_OUTPUT.PUT_LINE('Invoice References : ' || r.INVOICES);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('-------------------------------------');
    END LOOP;
    CLOSE mycursor;
END;
/