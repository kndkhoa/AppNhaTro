/*
    --HoaTT ACB201410039 28/10/2014
    --Muc dich : chay 1 lan duy nhat
      -- Quet bang acct
        -- Neu tai khoan co minor nam trong bang TTTK_LINHHOAT
        -- thi insert 1 dong tuong lai trong bang acctmiaccthist
        -- cho ky dao han that tuong lai
  */
DECLARE
  TYPE CURTYP IS REF CURSOR;
  CUR_DATA CURTYP;

  OSI_GENERAL_ERROR EXCEPTION;
  NEXT_LOOP EXCEPTION;
  AICT_GENERAL_ERROR EXCEPTION;
  LVSBATCHACTVMSG      VARCHAR2(200);
  LVSBATCHORACLEMSG    QUEAPPLERROR.BATCHORACLEMSG%TYPE;
  LCSDEBUGPROCCD       VARCHAR2(4) := 'TTTK';
  LVNACTVSTEP          NUMBER;
  LVNACCTNBR           NUMBER;
  LVDCONTRACTDATE      DATE;
  LVNTERM              NUMBER;
  LVSMINOR_NEW         VARCHAR2(4);
  LVDNGAYDAOHAN        DATE;
  LVNDEFAULTTERMDAYS   NUMBER;
  LVDDATEMAT           DATE;
  LVDDATEMAT_NEW       DATE;
  LVSRENEWALYN         VARCHAR2(1);
  LVSMIACCTTYPCD       VARCHAR2(4);
  LVSMAJOR             VARCHAR2(4);
  LVDPOSTDATE          DATE;
  LVSPOSTDATE          VARCHAR2(10);
  LVSCARRYOVERDATE     VARCHAR2(10);
  LVCCDATYN            VARCHAR2(1);
  LVDCURRDATE          DATE;
  LVNDEFAULTMONTH      NUMBER;
  LVNDEFAULTMONTH_TEMP NUMBER;
  N                    NUMBER;

BEGIN
  -- lay ngay postdate

  BEGIN
    SELECT TRIM(B.BANKOPTIONVALUE)
      INTO LVSPOSTDATE
      FROM BANKOPTION B
     WHERE B.BANKOPTIONCD = 'PDAT';
  
    SELECT TRIM(B.BANKOPTIONVALUE), B.BANKOPTIONONYN
      INTO LVSCARRYOVERDATE, LVCCDATYN
      FROM BANKOPTION B
     WHERE B.BANKOPTIONCD = 'CDAT';
  
    IF (LVCCDATYN = 'Y') THEN
      LVDCURRDATE := TO_DATE(LVSCARRYOVERDATE, 'yyyy-MM-dd');
    ELSE
      LVDCURRDATE := TO_DATE(LVSPOSTDATE, 'yyyy-MM-dd');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      RAISE OSI_GENERAL_ERROR;
  END;

  LVDPOSTDATE := TO_DATE(TO_CHAR(LVDCURRDATE, 'MM/dd/yyyy'), 'MM/dd/yyyy');

  -- Quet bang acct
  OPEN CUR_DATA FOR
    SELECT A.ACCTNBR,
           A.CONTRACTDATE,
           B.TERM,
           B.MICHANGECD,
           A.MJACCTTYPCD,
           A.CURRMIACCTTYPCD,
           A.DATEMAT
      FROM ACCT A,
           (SELECT 'TD' MJACCTTYPCD,
                   'KC80' MIACCTTYPCD,
                   24 TERM,
                   'K101' MICHANGECD
              FROM DUAL
            UNION
            SELECT 'TD' MJACCTTYPCD,
                   'KC81' MIACCTTYPCD,
                   24 TERM,
                   'K201' MICHANGECD
              FROM DUAL
            UNION
            SELECT 'TD' MJACCTTYPCD,
                   'KC82' MIACCTTYPCD,
                   24 TERM,
                   'K301' MICHANGECD
              FROM DUAL
            UNION
            SELECT 'TD' MJACCTTYPCD,
                   'KC83' MIACCTTYPCD,
                   24 TERM,
                   'K602' MICHANGECD
              FROM DUAL
            UNION
            SELECT 'TD' MJACCTTYPCD,
                   'KC84' MIACCTTYPCD,
                   24 TERM,
                   'K102' MICHANGECD
              FROM DUAL
            UNION
            SELECT 'TD' MJACCTTYPCD,
                   'KC85' MIACCTTYPCD,
                   24 TERM,
                   'K202' MICHANGECD
              FROM DUAL
            UNION
            SELECT 'TD' MJACCTTYPCD,
                   'KC86' MIACCTTYPCD,
                   24 TERM,
                   'K302' MICHANGECD
              FROM DUAL
            UNION
            SELECT 'TD' MJACCTTYPCD,
                   'KC87' MIACCTTYPCD,
                   24 TERM,
                   'K604' MICHANGECD
              FROM DUAL
            
            ) B
     WHERE A.MJACCTTYPCD = B.MJACCTTYPCD
       AND A.CURRMIACCTTYPCD = B.MIACCTTYPCD
       AND A.CURRACCTSTATCD = 'ACT'
     ORDER BY A.ACCTNBR;
  LOOP
    FETCH CUR_DATA
      INTO LVNACCTNBR,
           LVDCONTRACTDATE,
           LVNTERM,
           LVSMINOR_NEW,
           LVSMAJOR,
           LVSMIACCTTYPCD,
           LVDDATEMAT;
    EXIT WHEN CUR_DATA%NOTFOUND;
    BEGIN
    
      -- lay ky han quyen chon tren san pham hien tai
    
      BEGIN
        LVNDEFAULTMONTH := NULL;
        SELECT ROUND(A.DEFAULTTERMDAYS / 30)
          INTO LVNDEFAULTMONTH
          FROM MJMIACCTTYP A
         WHERE A.MJACCTTYPCD = LVSMAJOR
           AND A.MIACCTTYPCD = LVSMIACCTTYPCD;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE NEXT_LOOP;
      END;
    
      -- ngay dao han that cua san pham
      LVDNGAYDAOHAN := NULL;
      -- lap 1 vong trong de xu ly tinh trang ngay 28-29/2  
      N                    := 1;
      LVNDEFAULTMONTH_TEMP := LVNDEFAULTMONTH;
      WHILE LVNDEFAULTMONTH_TEMP <= LVNTERM LOOP
        IF N = 1 THEN
          LVDNGAYDAOHAN := ADD_MONTHS(LVDCONTRACTDATE, LVNDEFAULTMONTH);
        ELSE
          LVDNGAYDAOHAN := ADD_MONTHS(LVDNGAYDAOHAN, LVNDEFAULTMONTH);
        END IF;
        N                    := N + 1;
        LVNDEFAULTMONTH_TEMP := LVNDEFAULTMONTH_TEMP + LVNDEFAULTMONTH;
      END LOOP;
    
      -- neu ngay dao han nho hon ngay hien tai
      WHILE LVDNGAYDAOHAN <= LVDPOSTDATE LOOP
      
        -- lap 1 vong trong de xu ly tinh trang ngay 28-29/2        
        LVNDEFAULTMONTH_TEMP := LVNDEFAULTMONTH;
        WHILE LVNDEFAULTMONTH_TEMP <= LVNTERM LOOP
          LVDNGAYDAOHAN        := ADD_MONTHS(LVDNGAYDAOHAN, LVNDEFAULTMONTH);
          LVNDEFAULTMONTH_TEMP := LVNDEFAULTMONTH_TEMP + LVNDEFAULTMONTH;
        END LOOP;
      END LOOP;
    
      -- lay ky han tren sp moi
    
      BEGIN
        LVNDEFAULTTERMDAYS := NULL;
        SELECT A.DEFAULTTERMDAYS
          INTO LVNDEFAULTTERMDAYS
          FROM MJMIACCTTYP A
         WHERE A.MJACCTTYPCD = LVSMAJOR
           AND A.MIACCTTYPCD = LVSMINOR_NEW;
      
        -- tinh ngay datemat moi
      
        LVDDATEMAT_NEW     := NULL;
        LVNDEFAULTTERMDAYS := LVNDEFAULTTERMDAYS / 30;
        LVDDATEMAT_NEW     := ADD_MONTHS(LVDNGAYDAOHAN, LVNDEFAULTTERMDAYS);
      EXCEPTION
        WHEN OTHERS THEN
          RAISE NEXT_LOOP;
      END;
    
      BEGIN
        LVSRENEWALYN := NULL;
        SELECT AC.RENEWALYN
          INTO LVSRENEWALYN
          FROM ACCTMIACCTHIST AC
         WHERE AC.ACCTNBR = LVNACCTNBR
           AND AC.EFFDATE = (SELECT MAX(ACC.EFFDATE)
                               FROM ACCTMIACCTHIST ACC
                              WHERE ACC.ACCTNBR = AC.ACCTNBR);
      EXCEPTION
        WHEN OTHERS THEN
          RAISE NEXT_LOOP;
      END;
    
      -- insert 1 dong tuong lai trong bang acctmiaccthist
      -- tinh lvdDatemat cho tuong lai
      BEGIN
      
        INSERT INTO ACCTMIACCTHIST
          (ACCTNBR,
           EFFDATE,
           INACTIVEDATE,
           MJACCTTYPCD,
           MIACCTTYPCD,
           STARTDATE,
           RENEWALYN)
        VALUES
          (LVNACCTNBR,
           LVDNGAYDAOHAN,
           LVDDATEMAT_NEW,
           LVSMAJOR,
           LVSMINOR_NEW,
           LVDNGAYDAOHAN,
           LVSRENEWALYN);
      
        COMMIT;
      
      EXCEPTION
        WHEN OTHERS THEN
          ROLLBACK;
          RAISE NEXT_LOOP;
      END;
    
    EXCEPTION
      WHEN NEXT_LOOP THEN
        NULL;
      WHEN OTHERS THEN
        NULL;
    END;
  
  END LOOP; --cur_Data

END;
/
