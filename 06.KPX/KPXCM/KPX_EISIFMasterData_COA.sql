
IF OBJECT_ID('KPX_EISIFMasterData_COA') IS NOT NULL 
    DROP PROC KPX_EISIFMasterData_COA 
go 


 CREATE  PROC [dbo].[KPX_EISIFMasterData_COA]
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,    
     @WorkingTag     NVARCHAR(10)= '',    
     
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
 AS           
     DECLARE   @docHandle  INT,      
               @YYMM    NCHAR(6),
      @Below1Month  NCHAR(8),
      @Below2Month  NCHAR(8),
      @Below3Month  NCHAR(8),
      @Below1MonthCard NCHAR(8),
      @Below2MonthCard NCHAR(8),
      @Below3MonthCard NCHAR(8),
      @SQL    NVARCHAR(4000)
  
  
     CREATE TABLE  #TEISProc (WorkingTag NCHAR(1) NULL)    
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TEISProc'   
     IF @@ERROR <> 0 RETURN    
    
     SELECT   @YYMM    = ISNULL(YYMM,'')
    ,@Below1Month  = ISNULL(Below1Month,'')
    ,@Below2Month  = ISNULL(Below2Month,'')
    ,@Below3Month  = ISNULL(Below3Month,'')
    ,@Below1MonthCard = ISNULL(Below1MonthCard,'')
    ,@Below2MonthCard = ISNULL(Below2MonthCard,'')
    ,@Below3MonthCard = ISNULL(Below3MonthCard,'')
       FROM  #TEISProc   
  
     --SELECT @Below1Month,@Below2Month,@Below3Month,@Below1MonthCard,@Below2MonthCard,@Below3MonthCard
  
     DECLARE @StkYM NCHAR(6)-- 물류시작월
     EXEC @StkYM = dbo._SCOMEnvR @CompanySeq, 1006, @UserSeq, @@PROCID 
  

    /* 거래처정보 업데이트 */
    DELETE FROM ODS_KPX_HDSLIB_CUSTPF_COA WHERE CompanySeq = @CompanySeq  -- 기존자료 삭제
    DELETE FROM ODS_KPXGC_HDSLIB_CUSTPF    -- 기존자료 삭제(그린케미칼)
    
    
    INSERT INTO ODS_KPX_HDSLIB_CUSTPF_COA 
    SELECT @CompanySeq,
        LEFT(CustNo,6),       --LEFT 사용이유 : 연동테이블이므로 사용자 실수로 인하여 자리수가 Over 될시 오류방지
        LEFT(FullName,40),
        0,
        CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
      FROM _TDACust
     WhERE CompanySeq=@CompanySeq
    
    IF @CompanySeq =1 
    BEGIN
        INSERT INTO ODS_KPXGC_HDSLIB_CUSTPF
        SELECT CDCO,NMCO,SORTID,DTTMUP FROM ODS_KPX_HDSLIB_CUSTPF_COA WHERE CompanySeq=1
    END
    
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736002
    INSERT INTO KPX_EISIFProcStaus_COA
    SELECT @CompanySeq,@YYMM,1010736002,'1','',@UserSeq,GETDATE()
  
  /* 용도정보 업데이트 */
    DELETE FROM  ODS_KPX_HDSLIB_USMTPF_COA WHERE CompanySeq=@CompanySeq
   
    IF @CompanySeq =1 
    BEGIN
        DELETE FROM  ODS_KPXGC_HDSLIB_USMTPF 
    END
    
    
    INSERT INTO  ODS_KPX_HDSLIB_USMTPF_COA
    SELECT   @CompanySeq
     ,B.ValueText -- (경영보고)품목구분코드
     ,C.ValueText -- (경영보고)용도코드
     ,D.ValueText -- (경영보고)품목구분명
     ,E.ValueText -- (경영보고)용도명
     ,A.MinorSort
     ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
    FROM _TDAUMinor A LEFT OUTER JOIN _TDAUMinorValue B WITH(NOLOCK)
            ON A.CompanySeq=B.CompanySeq
           AND A.MinorSeq=B.MinorSeq
           AND B.Serl =1000001
         LEFT OUTER JOIN _TDAUMinorValue C WITH(NOLOCK)
            ON A.CompanySeq=C.CompanySeq
           AND A.MinorSeq=C.MinorSeq
           AND C.Serl =1000002
         LEFT OUTER JOIN _TDAUMinorValue D WITH(NOLOCK)
            ON A.CompanySeq=D.CompanySeq
           AND A.MinorSeq=D.MinorSeq
           AND D.Serl =1000003
         LEFT OUTER JOIN _TDAUMinorValue E WITH(NOLOCK)
            ON A.CompanySeq=E.CompanySeq
           AND A.MinorSeq=E.MinorSeq
           AND E.Serl =1000004
     WHERE A.CompanySeq=@CompanySeq
    AND A.MajorSeq=1010704 
    
    IF @CompanySeq =1 
    BEGIN
       INSERT INTO ODS_KPXGC_HDSLIB_USMTPF
        SELECT CDITEM,CDUS,NMITEM,NMUS,SORTID,DTTMUP FROM ODS_KPX_HDSLIB_USMTPF_COA WHERE CompanySeq=1
    END
    
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736003
       INSERT INTO KPX_EISIFProcStaus_COA
      SELECT @CompanySeq,@YYMM,1010736003,'1','',@UserSeq,GETDATE()
  
    
  
    /* 재무상태표계정 업데이트 */
     DELETE FROM ODS_KPX_HDSLIB_BSMTPF_COA WHERE CompanySeq=@CompanySeq  -- 기존자료 삭제
    IF @CompanySeq =1 
    BEGIN
        DELETE FROM  ODS_KPXGC_HDSLIB_BSMTPF 
    END
  
    INSERT INTO ODS_KPX_HDSLIB_BSMTPF_COA
    SELECT @CompanySeq
      ,CDAC
      ,CDACHG
      ,NMAC
      ,SORTID
      ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
    FROM KPX_TEISAcc_COA
      WHERE CompanySeq=@CompanySeq
        AND KindSeq=1010735001
     ORDER BY SORTID
  
    
    IF @CompanySeq = 1
    BEGIN
        INSERT INTO ODS_KPXGC_HDSLIB_BSMTPF
        SELECT CDAC,CDACHG,NMAC,SORTID,DTTMUP  FROM ODS_KPX_HDSLIB_BSMTPF_COA WHERE CompanySeq = 1
    END
    
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736004
    INSERT INTO KPX_EISIFProcStaus_COA
    SELECT @CompanySeq,@YYMM,1010736004,'1','',@UserSeq,GETDATE()
  
    
  --/* 제조원가명세서계정 업데이트 */
  
 -- DELETE FROM ODS_KPX_HDSLIB_MCMTPF_COA WHERE CompanySeq=@CompanySeq  -- 기존자료 삭제
  -- IF @CompanySeq =1 
 --   BEGIN
 --   DELETE FROM  ODS_KPXGC_HDSLIB_MCMTPF
 --   END
 --   ELSE IF @CompanySeq =2 
 --      BEGIN
 --   DELETE FROM  ODS_KPXCM_HDSLIB_MCMTPF
 --   END
 --   ELSE IF @CompanySeq =3 
 --      BEGIN
 --   DELETE FROM  ODS_KPXLS_HDSLIB_MCMTPF
 --   END
 --   ELSE IF @CompanySeq =4 
 --      BEGIN
 --   DELETE FROM  ODS_KPXHD_HDSLIB_MCMTPF
 --   END
  -- INSERT INTO ODS_KPX_HDSLIB_MCMTPF_COA
 --      SELECT @CompanySeq 
 --     ,CDAC
 --     ,CDACHG
 --     ,NMAC
 --     ,SORTID
 --     ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
 --   FROM KPX_TEISAcc_COA
 --     WHERE CompanySeq=@CompanySeq
 --       --AND KindSeq=1010735002
 --      AND KindSeq=1010735003
 --    ORDER BY SORTID
     
    
 --     IF @CompanySeq =1
 --   BEGIN
 --      INSERT INTO ODS_KPXGC_HDSLIB_MCMTPF
 --       SELECT CDAC,CDACHG,NMAC,SORTID,DTTMUP  FROM ODS_KPX_HDSLIB_MCMTPF_COA WHERE CompanySeq=1
 --   END
 --   ELSE IF @CompanySeq = 2 
 --      BEGIN
 --    INSERT INTO ODS_KPXCM_HDSLIB_MCMTPF
 --       SELECT CDAC,CDACHG,NMAC,SORTID,DTTMUP  FROM ODS_KPX_HDSLIB_MCMTPF_COA WHERE CompanySeq=2
  --   END
  --   ELSE IF @CompanySeq = 3
 --      BEGIN
 --    INSERT INTO ODS_KPXLS_HDSLIB_MCMTPF
 --       SELECT CDAC,CDACHG,NMAC,SORTID,DTTMUP  FROM ODS_KPX_HDSLIB_MCMTPF_COA WHERE CompanySeq=3
  --   END
 --   ELSE IF @CompanySeq = 4
 --      BEGIN
 --    INSERT INTO ODS_KPXHD_HDSLIB_MCMTPF
 --       SELECT CDAC,CDACHG,NMAC,SORTID,DTTMUP  FROM ODS_KPX_HDSLIB_MCMTPF_COA WHERE CompanySeq=4
  --   END
    
    
    
 --   DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736005
 --      INSERT INTO KPX_EISIFProcStaus_COA
 --     SELECT @CompanySeq,@YYMM,1010736005,'1','',@UserSeq,GETDATE()
  
 /* 손익계산서계정 업데이트 */
    DELETE FROM ODS_KPX_HDSLIB_PLMTPF_COA WHERE CompanySeq=@CompanySeq  -- 기존자료 삭제
    
    IF @CompanySeq =1 
    BEGIN
        DELETE FROM  ODS_KPXGC_HDSLIB_PLMTPF
    END
    
    INSERT INTO ODS_KPX_HDSLIB_PLMTPF_COA
    SELECT @CompanySeq 
      ,CDAC
      ,CDACHG
      ,NMAC
      ,SORTID
      ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
      FROM KPX_TEISAcc_COA
      WHERE CompanySeq=@CompanySeq
        AND KindSeq=1010735003
     ORDER BY SORTID
       
    IF @CompanySeq =1
    BEGIN
        INSERT INTO ODS_KPXGC_HDSLIB_PLMTPF
        SELECT CDAC,CDACHG,NMAC,SORTID,DTTMUP  FROM ODS_KPX_HDSLIB_PLMTPF_COA WHERE CompanySeq=1
    END
    
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736006
    INSERT INTO KPX_EISIFProcStaus_COA
    SELECT @CompanySeq,@YYMM,1010736006,'1','',@UserSeq,GETDATE()
   
  /************************************************************************************************************************
 ************************************************************************************************************************/
  
    
 /* 외상매출금 업데이트 */
     DELETE FROM ODS_KPX_HDSLIB_ARAMPF_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM
   
    IF @CompanySeq =1 
    BEGIN
        DELETE FROM ODS_KPXGC_HDSLIB_ARAMPF WHERE  YYMM=@YYMM
    END
    
    INSERT INTO ODS_KPX_HDSLIB_ARAMPF_COA ( CompanySeq, YYMM, CDWG, CDCO, IDSA, GUBN, NMCO, NMWG, NMSA, AMSL, AMAR, DTTMUP ) 
    SELECT @CompanySeq
         ,@YYMM
         ,0 
     ,AA.CDCO
     ,AA.IDSA
     ,AA.GUBN
     ,AA.NMCO
     ,'' 
     ,AA.NMSA
     ,SUM(ISNULL(SALE,0)) AS AMSL
     ,SUM(ISNULL(TOT_SALE,0))- SUM(ISNULL(TOT_RECV,0)) AS AMAR
     ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
       FROM 
     (
       SELECT LEFT(CustNo,6) AS CDCO
        ,M.ValueText   AS IDSA--시스템코드인 수출구분의 추가정보인 '(경영보고)판매구분코드' -> IDSA
        ,CASE WHEN ISNULL(DF.MngValText,'False')='True' THEN 'Y' ELSE 'N' END   AS GUBN       --거래처등록의 추가정보인 '(경영보고)합계표시' -> GUBN : Y 또는 N으로 변환해서 생성
        ,LEFT(CST.FullName,40)   AS NMCO
        ,M2.ValueText     AS NMSA
        ,B.DomAmt+B.DomVAT     AS SALE
        ,0        AS TOT_SALE
        ,0        AS TOT_RECV
         FROM _TSLSales A LEFT OUTER JOIN _TSLSalesItem B WITH(NOLOCK)
               ON A.CompanySeq=B.CompanySeq
              AND A.SalesSeq=B.SalesSeq
                JOIN _TDACust CST WITH(NOLOCK)
               ON A.CompanySeq=CST.CompanySeq
              AND A.CustSeq=CST.CustSeq
           LEFT OUTER JOIN _TDASMinorValue M WITH(NOLOCK)
               ON A.CompanySeq=M.CompanySeq
              AND A.SMExpKind=M.MinorSeq
              AND M.Serl=1000001
           LEFT OUTER JOIN _TDASMinorValue M2 WITH(NOLOCK)
               ON A.CompanySeq=M2.CompanySeq
              AND A.SMExpKind=M2.MinorSeq
              AND M2.Serl=1000002
           LEFT OUTER JOIN _TDACustUserDefine DF WITH(NOLOCK)
               ON A.CompanySeq=DF.CompanySeq
              AND A.CustSeq=DF.CustSeq
              AND DF.MngSerl=1000001
        WHERE A.CompanySeq=@CompanySeq
       AND A.SalesDate BETWEEN @YYMM+'01' AND  @YYMM+'31'
         UNION ALL
           SELECT LEFT(CustNo,6) AS CDCO
        ,M.ValueText   AS IDSA--시스템코드인 수출구분의 추가정보인 '(경영보고)판매구분코드' -> IDSA
        ,CASE WHEN ISNULL(DF.MngValText,'False')='True' THEN 'Y' ELSE 'N' END   AS GUBN       --거래처등록의 추가정보인 '(경영보고)합계표시' -> GUBN : Y 또는 N으로 변환해서 생성
        ,CST.FullName AS NMCO
        ,M2.ValueText AS NMSA
        ,0       AS SALE
        ,B.DomAmt + B.DomVat  AS TOT_SALE
        ,0       AS TOT_RECV
         FROM _TSLSales A LEFT OUTER JOIN _TSLSalesItem B WITH(NOLOCK)
               ON A.CompanySeq=B.CompanySeq
              AND A.SalesSeq=B.SalesSeq
                JOIN _TDACust CST WITH(NOLOCK)
               ON A.CompanySeq=CST.CompanySeq
              AND A.CustSeq=CST.CustSeq
           LEFT OUTER JOIN _TDASMinorValue M WITH(NOLOCK)
               ON A.CompanySeq=M.CompanySeq
              AND A.SMExpKind=M.MinorSeq
              AND M.Serl=1000001
           LEFT OUTER JOIN _TDASMinorValue M2 WITH(NOLOCK)
               ON A.CompanySeq=M2.CompanySeq
              AND A.SMExpKind=M2.MinorSeq
              AND M2.Serl=1000002
           LEFT OUTER JOIN _TDACustUserDefine DF WITH(NOLOCK)
               ON A.CompanySeq=DF.CompanySeq
              AND A.CustSeq=DF.CustSeq
              AND DF.MngSerl=1000001
        WHERE A.CompanySeq=@CompanySeq
       AND A.SalesDate BETWEEN @StkYM+'01' AND  @YYMM+'31'  
         UNION ALL
           SELECT LEFT(CustNo,6) AS CDCO
        , CASE WHEN(A.CurrSeq)= 16 THEN '1' ELSE '2' END  AS IDSA--시스템코드인 수출구분의 추가정보인 '(경영보고)판매구분코드' -> IDSA
        ,CASE WHEN ISNULL(DF.MngValText,'False')='True' THEN 'Y' ELSE 'N' END   AS GUBN       --거래처등록의 추가정보인 '(경영보고)합계표시' -> GUBN : Y 또는 N으로 변환해서 생성
        ,CST.FullName AS NMCO
        ,CASE WHEN(A.CurrSeq)= 16 THEN '내수' ELSE '직수출' END   AS NMSA
        ,0       AS SALE
        ,A.DomAmt+A.DomVAt    AS TOT_SALE
        ,0       AS TOT_RECV
         FROM _TSLCreditSum A JOIN _TDACust CST WITH(NOLOCK)
               ON A.CompanySeq=CST.CompanySeq
              AND A.CustSeq=CST.CustSeq
           LEFT OUTER JOIN _TDACustUserDefine DF WITH(NOLOCK)
               ON A.CompanySeq=DF.CompanySeq
              AND A.CustSeq=DF.CustSeq
              AND DF.MngSerl=1000001
        WHERE A.CompanySeq=@CompanySeq
       AND A.SumYM = @StkYM
       AND A.SumType=0
        UNION ALL
        SELECT LEFT(CustNo,6) AS CDCO
       ,M.ValueText   AS IDSA--시스템코드인 수출구분의 추가정보인 '(경영보고)판매구분코드' -> IDSA
       ,CASE WHEN ISNULL(DF.MngValText,'False')='True' THEN 'Y' ELSE 'N' END   AS GUBN       --거래처등록의 추가정보인 '(경영보고)합계표시' -> GUBN : Y 또는 N으로 변환해서 생성
       ,CST.FullName AS NMCO
       ,M2.ValueText AS NMSA
       ,0     AS SALE
       ,0     AS TOT_SALE 
       ,SMDrOrCr * B.DomAmt     AS TOT_RECV
       
      FROM _TSLReceipt A LEFT OUTER JOIN _TSLReceiptDesc B WITH(NOLOCK)
              ON A.CompanySeq=B.CompanySeq
             AND A.ReceiptSeq=B.ReceiptSeq
             JOIN _TDACust CST WITH(NOLOCK)
              ON A.CompanySeq=CST.CompanySeq
             AND A.CustSeq=CST.CustSeq
          LEFT OUTER JOIN _TDASMinorValue M WITH(NOLOCK)
              ON A.CompanySeq=M.CompanySeq
             AND A.SMExpKind=M.MinorSeq
             AND M.Serl=1000001
          LEFT OUTER JOIN _TDASMinorValue M2 WITH(NOLOCK)
              ON A.CompanySeq=M2.CompanySeq
             AND A.SMExpKind=M2.MinorSeq
             AND M2.Serl=1000002
          LEFT OUTER JOIN _TDACustUserDefine DF WITH(NOLOCK)
              ON A.CompanySeq=DF.CompanySeq
             AND A.CustSeq=DF.CustSeq
             AND DF.MngSerl=1000001
     WHERE A.CompanySeq=@CompanySeq
       AND A.ReceiptDate BETWEEN @StkYM +'01' AND  @YYMM+'31'   
      )AA
     GROUP BY   AA.CDCO
         ,AA.IDSA
         ,AA.GUBN
         ,AA.NMCO
         ,AA.NMSA            
  
    IF @CompanySeq =1 
    BEGIN
        INSERT INTO ODS_KPXGC_HDSLIB_ARAMPF
        SELECT YYMM,CDCO,IDSA,GUBN,NMCO,NMSA,AMSL,AMAR,DTTMUP FROM ODS_KPX_HDSLIB_ARAMPF_COA WHERE CompanySeq=1 AND YYMM=@YYMM
    END
    
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736008
    INSERT INTO KPX_EISIFProcStaus_COA
    SELECT @CompanySeq,@YYMM,1010736008,'1','',@UserSeq,GETDATE()
  
  
  
  
         
 /* 제품해외매출액 업데이트 */
    DELETE FROM ODS_KPX_HDSLIB_FRAMPF_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM
    
    IF @CompanySeq =1 
    BEGIN
    DELETE FROM ODS_KPXGC_HDSLIB_FRAMPF WHERE  YYMM=@YYMM
    END
    
    
    INSERT INTO ODS_KPX_HDSLIB_FRAMPF_COA 
    SELECT   @CompanySeq
      ,@YYMM
      ,AA.CDCS
      ,AA.NMCS
      ,SUM(ISNULL(AA.AMT,0)) AS AMT
      ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
           FROM 
     (
          SELECT        
        M.ValueText   AS CDCS
       ,M2.ValueText  AS NMCS
       ,B.DomAmt+B.DomVat   AS AMT       
     FROM _TSLSales A LEFT OUTER JOIN _TSLSalesItem B WITH(NOLOCK)
               ON A.CompanySeq=B.CompanySeq
              AND A.SalesSeq=B.SalesSeq
           LEFT OUTER JOIN _TDAItemClass  AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND B.ItemSeq = C.ItemSeq AND C.UMajorItemClass IN (2001,2004) ) 
           LEFT OUTER JOIN _TDAUMinor      AS H WITH(NOLOCK) ON ( A.CompanySeq = H.CompanySeq AND H.MajorSeq = LEFT( C.UMItemClass, 4 ) AND C.UMItemClass = H.MinorSeq ) 
           LEFT OUTER JOIN _TDAUMinorValue  AS K WITH(NOLOCK) ON  ( H.CompanySeq = K.CompanySeq AND K.MajorSeq IN (2001,2004) AND H.MinorSeq = K.MinorSeq AND K.Serl IN (1001,2001) ) 
           LEFT OUTER JOIN _TDAUMinorValue  AS L WITH(NOLOCK) ON ( K.CompanySeq = L.CompanySeq AND L.MajorSeq IN (2002,2005) AND K.ValueSeq = L.MinorSeq AND L.Serl = 2001 )  
           LEFT OUTER JOIN _TDAUMinorValue AS M WITH(NOLOCK)
               ON A.CompanySeq=M.CompanySeq
              AND L.ValueSeq=M.MinorSeq
              AND M.Serl=1000004
           LEFT OUTER JOIN _TDAUMinorValue AS M2 WITH(NOLOCK)
               ON A.CompanySeq=M2.CompanySeq
              AND L.ValueSeq=M2.MinorSeq
              AND M2.Serl=1000005
          
        WHERE A.CompanySeq=@CompanySeq
       AND A.SalesDate BETWEEN @YYMM+'01' AND  @YYMM+'31' 
       AND A.SMExpKind<>8009001
        UNION ALL               -- 20150323 추가
         SELECT '10' AS CDCS
         ,'EOA사업부문' AS NMCS
         ,ISNULL(DomAmt,0)+ISNULL(DomVAT,0) AS AMT
        FROM _TSLSales A LEFT OUTER JOIN _TSLSalesItem B WITH(NOLOCK)
                ON A.CompanySeq=B.CompanySeq
               AND A.SalesSeq=B.SalesSeq
            LEFT OUTER JOIN _TDAItem  ITM WITH(NOLOCK)
                ON A.CompanySeq = ITM.CompanySeq
               AND B.ItemSeq    = ITM.ItemSeq
          WHERE A.CompanySeq=@CompanySeq
        AND A.SalesDate BETWEEN @YYMM+'01' AND @YYMM+'31'
        AND A.SMExpKind<>8009001
        AND ITM.AssetSeq IN (4,7)   
  
     )AA 
    WHERE AA.CDCS IS NOT NULL
    GROUP BY   AA.CDCS
           ,AA.NMCS
    
    
     IF @CompanySeq =1 
    BEGIN
       INSERT INTO ODS_KPXGC_HDSLIB_FRAMPF
        SELECT YYMM,CDCS,NMCS,AMT,DTTMUP FROM ODS_KPX_HDSLIB_FRAMPF_COA WHERE CompanySeq=1 AND YYMM=@YYMM
    END
    
  
  
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736009
       INSERT INTO KPX_EISIFProcStaus_COA
      SELECT @CompanySeq,@YYMM,1010736009,'1','',@UserSeq,GETDATE()
  
   
    
 /* 수금미수금 업데이트 */
     
   SELECT * INTO #TMP 
   FROM  
     (
      SELECT @YYMM AS YYMM
         ,CDWG  AS CDWG
         ,NMWG  AS NMWG
         ,SUM(ISNULL(AMIN,0)) AS AMIN
         ,SUM(ISNULL(SALE,0))-SUM(ISNULL(RECV,0))  AS AMJAN
        FROM 
         ( 
        SELECT  M.ValueText   AS  CDWG
         ,M2.ValueText  AS  NMWG
         ,SMDrOrCr * B.DomAmt      AS  AMIN
         ,0      AS  SALE
         ,0      AS  RECV
        FROM _TSLReceipt A LEFT OUTER JOIN _TSLReceiptDesc B WITH(NOLOCK)
                ON A.CompanySeq=B.CompanySeq
               AND A.ReceiptSeq=B.ReceiptSeq
               LEFT OUTER JOIN (  SELECT  ValueSeq AS BizUnit,MinorSeq
                  FROM _TDAUMinorValue
                    WHERE CompanySeq=@CompanySeq 
                  AND MajorSeq=1010555
                  AND Serl=1000002
                 )AA
                ON A.CompanySeq=@CompanySeq
                  AND A.BizUnit=AA.BizUnit
            LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                ON A.CompanySeq=M.CompanySeq
               AND AA.MinorSeq=M.MinorSeq
               AND M.Serl=1000003
            LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                ON A.CompanySeq=M2.CompanySeq
               AND AA.MinorSeq=M2.MinorSeq
               AND M2.Serl=1000004
       WHERE A.CompanySeq=@CompanySeq
         AND A.ReceiptDate BETWEEN @YYMM+'01' AND  @YYMM+'31'    
       UNION ALL
        SELECT 
          M.ValueText    AS  CDWG
         ,M2.ValueText    AS  NMWG
         ,0       AS  AMIN
         ,B.DomAmt+B.DomVat AS  SALE
         ,0       AS  RECV
        FROM _TSLSales A LEFT OUTER JOIN _TSLSalesItem B WITH(NOLOCK)
                ON A.CompanySeq=B.CompanySeq
               AND A.SalesSeq=B.SalesSeq
               LEFT OUTER JOIN (  SELECT  ValueSeq AS BizUnit,MinorSeq
                  FROM _TDAUMinorValue
                    WHERE CompanySeq=@CompanySeq 
                  AND MajorSeq=1010555
                  AND Serl=1000002
                 )AA
                ON A.CompanySeq=@CompanySeq
                  AND A.BizUnit=AA.BizUnit
            LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                ON A.CompanySeq=M.CompanySeq
               AND AA.MinorSeq=M.MinorSeq
               AND M.Serl=1000003
            LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                ON A.CompanySeq=M2.CompanySeq
               AND AA.MinorSeq=M2.MinorSeq
               AND M2.Serl=1000004
       WHERE A.CompanySeq=@CompanySeq
         AND A.SalesDate BETWEEN @StkYM+'01' AND  @YYMM+'31'  
       UNION ALL
             SELECT  M.ValueText    AS  CDWG
           ,M2.ValueText    AS  NMWG
          ,0       AS  AMIN
          ,A.DomAmt     AS  SALE
          ,0       AS  RECV
           FROM _TSLCreditSum A  LEFT OUTER JOIN (  SELECT  ValueSeq AS BizUnit,MinorSeq
                    FROM _TDAUMinorValue
                   WHERE CompanySeq=@CompanySeq 
                     AND MajorSeq=1010555
                     AND Serl=1000002
                   ) AS AA
                  ON A.CompanySeq=@CompanySeq
                    AND A.BizUnit=AA.BizUnit
               LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                   ON A.CompanySeq=M.CompanySeq
                  AND AA.MinorSeq=M.MinorSeq
                  AND M.Serl=1000003
              LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                  ON A.CompanySeq=M2.CompanySeq
                 AND AA.MinorSeq=M2.MinorSeq
                 AND M2.Serl=1000004
          WHERE A.CompanySeq=@CompanySeq
         AND A.SumYM = @StkYM
         AND A.SumType=0
       UNION ALL 
        SELECT  M.ValueText   AS  CDWG
         ,M2.ValueText  AS  NMWG
         ,0      AS  AMIN
         ,0      AS  SALE
         ,SMDrOrCr * B.DomAmt    AS  RECV
        FROM _TSLReceipt A LEFT OUTER JOIN _TSLReceiptDesc B WITH(NOLOCK)
                ON A.CompanySeq=B.CompanySeq
               AND A.ReceiptSeq=B.ReceiptSeq
               LEFT OUTER JOIN (  SELECT  ValueSeq AS BizUnit,MinorSeq
                  FROM _TDAUMinorValue
                    WHERE CompanySeq=@CompanySeq
                  AND MajorSeq=1010555
                  AND Serl=1000002
                 )AA
                ON A.CompanySeq=@CompanySeq
                  AND A.BizUnit=AA.BizUnit
            LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                ON A.CompanySeq=M.CompanySeq
               AND AA.MinorSeq=M.MinorSeq
               AND M.Serl=1000003
            LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                ON A.CompanySeq=M2.CompanySeq
               AND AA.MinorSeq=M2.MinorSeq
               AND M2.Serl=1000004
       WHERE A.CompanySeq=@CompanySeq
         AND A.ReceiptDate BETWEEN @StkYM+'01' AND  @YYMM+'31'    
        ) AS BB
      GROUP BY CDWG
        ,NMWG 
    )AS CC  
    
    DELETE FROM ODS_KPX_HDSLIB_INAMPF_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM
    
    IF @CompanySeq =1 
    BEGIN
        DELETE FROM ODS_KPXGC_HDSLIB_INAMPF WHERE  YYMM=@YYMM
    END
    
    
    INSERT INTO ODS_KPX_HDSLIB_INAMPF_COA
    SELECT @CompanySeq 
            ,*
              ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
          FROM #TMP
        UNION ALL
        SELECT @CompanySeq 
       ,YYMM
       ,'90'
       ,'전체'
       ,SUM(ISNULL(AMIN,0))
       ,SUM(ISNULL(AMJAN,0))
       ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
         FROM #TMP
        GROUP BY YYMM
    
   IF @CompanySeq =1 
    BEGIN
        INSERT INTO ODS_KPXGC_HDSLIB_INAMPF
        SELECT YYMM,CDWG,NMWG,AMIN,AMJAN,DTTMUP FROM ODS_KPX_HDSLIB_INAMPF_COA WHERE CompanySeq=1 AND YYMM=@YYMM
    END
    
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736010
    INSERT INTO KPX_EISIFProcStaus_COA
    SELECT @CompanySeq,@YYMM,1010736010,'1','',@UserSeq,GETDATE()
  
    /* 받을어음 받을카드 업데이트 */
     
    DECLARE @NextYYMM NCHAR(6)
    
    
    SELECT @NextYYMM=CONVERT(NCHAR(6),DATEADD(MM,1,@YYMM+'01'),112)
  
    DELETE FROM ODS_KPX_HDSLIB_NRAMPF_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM
      
    IF @CompanySeq =1 
    BEGIN
        DELETE FROM ODS_KPXGC_HDSLIB_NRAMPF WHERE  YYMM=@YYMM
    END
    
     INSERT INTO ODS_KPX_HDSLIB_NRAMPF_COA ( CompanySeq, YYMM, CDWG, CDCO, NMWG, NMCO, AM01, AM02, AM03, AMGT, DTTMUP ) 
    SELECT   @CompanySeq
      ,@YYMM
      ,0 
      ,BB.CDCO
      ,'' 
      ,BB.NMCO
      ,SUM(ISNULL(BB.AM01,0)) AS AM01
      ,SUM(ISNULL(BB.AM02,0)) AS AM02
      ,SUM(ISNULL(BB.AM03,0)) AS AM03
      ,SUM(ISNULL(BB.AMGT,0)) AS AMGT
      ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
           FROM 
     (
    
          SELECT        
        LEFT(CST.CustNo,6)     AS CDCO       --LEFT 사용이유 : 연동테이블이므로 사용자 실수로 인하여 자리수가 Over 될시 오류방지
             ,LEFT(CST.FullName,40)  AS NMCO
       ,CASE WHEN AA.DueDate<= @Below1Month THEN BillAmt ELSE 0 END AS AM01
       ,CASE WHEN AA.DueDate >   @Below1Month AND DueDate<= @Below2Month THEN BillAmt ELSE 0 END AS AM02 
       ,CASE WHEN AA.DueDate >   @Below2Month AND DueDate<= @Below3Month THEN BillAmt ELSE 0 END AS AM03 
       ,CASE WHEN AA.DueDate >   @Below3Month         THEN BillAmt ELSE 0 END AS AMGT    
     FROM (     
              SELECT A.CustSeq
             ,A.DueDate
             ,ISNULL(A.BillAmt,0)- CASE WHEN C.AccDate< =@YYMM+'31' THEN (ISNULL(B.OffAmt,0)) ELSE 0 END   AS BillAmt  -- 잔액금액
           --,ISNULL(A.BillAmt,0)  AS BillAmt       -- 발생금액
         FROM _TACBill A LEFT OUTER JOIN _TACBillOff B WITH(NOLOCK)
                 ON A.CompanySeq = B.CompanySeq
                AND A.BillSeq    = B.BillSeq 
             LEFT OUTER JOIN _TACSlipRow C WITH(NOLOCK)
                 ON A.CompanySeq = C.CompanySeq
                AND B.OffSlipSeq = C.SlipSeq
                AND (C.AccDate <= @YYMM+'31')
              LEFT OUTER JOIN _TACSlipRow D WITH(NOLOCK)
                 ON A.CompanySeq = D.CompanySeq
                AND A.SlipSeq = D.SlipSeq
  
        WHERE A.CompanySeq=@CompanySeq
          AND A.SMPayOrRev = 4034002
          AND A.AccSeq IN( 
            SELECT ValueSeq
              FROM _TDAUMinor A LEFT OUTER JOIN _TDAUMinorValue B WITH(NOLOCK)
                     ON A.CompanySeq=B.CompanySeq
                    AND A.MinorSeq=B.MinorSeq
                    AND B.Serl=1000001
              WHERE A.CompanySeq=@CompanySeq
             AND A.MajorSeq=1010712
             AND A.MinorSort=1
              )
                            AND A.DrawDate <=@YYMM+'31'
         AND (A.SlipSeq = 0 OR D.AccDate <=@YYMM+'31')
       
         ) AA  LEFT OUTER JOIN _TDACust CST
            ON CST.CompanySeq=@CompanySeq
              AND AA.CustSeq=CST.CustSeq
  
                UNION ALL
  
        SELECT    LEFT(CST.CustNo,6)     AS CDCO       --LEFT 사용이유 : 연동테이블이므로 사용자 실수로 인하여 자리수가 Over 될시 오류방지
             ,LEFT(CST.FullName,40)  AS NMCO
       ,CASE WHEN AA.DueDate <= @Below1MonthCard THEN BillAmt ELSE 0 END AS AM01
       ,CASE WHEN AA.DueDate >   @Below1MonthCard AND DueDate<= @Below2MonthCard THEN BillAmt ELSE 0 END AS AM02 
       ,CASE WHEN AA.DueDate >   @Below2MonthCard AND DueDate<= @Below3MonthCard THEN BillAmt ELSE 0 END AS AM03 
       ,CASE WHEN AA.DueDate >   @Below3MonthCard         THEN BillAmt ELSE 0 END AS AMGT    
     FROM (    SELECT A.CustSeq
          ,A.DueDate
          ,ISNULL(A.BillAmt,0)- CASE WHEN C.AccDate< =@YYMM+'31' THEN (ISNULL(B.OffAmt,0)) ELSE 0 END   AS BillAmt  -- 잔액금액
           --,ISNULL(A.BillAmt,0)  AS BillAmt       -- 발생금액
         FROM _TACBill A LEFT OUTER JOIN _TACBillOff B WITH(NOLOCK)
                 ON A.CompanySeq = B.CompanySeq
                AND A.BillSeq    = B.BillSeq 
             LEFT OUTER JOIN _TACSlipRow C WITH(NOLOCK)
                 ON A.CompanySeq = C.CompanySeq
                AND B.OffSlipSeq = C.SlipSeq
                AND (C.AccDate <= @YYMM+'31')
              LEFT OUTER JOIN _TACSlipRow D WITH(NOLOCK)
                 ON A.CompanySeq = D.CompanySeq
                AND A.SlipSeq = D.SlipSeq
  
        WHERE A.CompanySeq=@CompanySeq
          AND A.SMPayOrRev = 4034002
          AND A.AccSeq IN( 
            SELECT ValueSeq
              FROM _TDAUMinor A LEFT OUTER JOIN _TDAUMinorValue B WITH(NOLOCK)
                     ON A.CompanySeq=B.CompanySeq
                    AND A.MinorSeq=B.MinorSeq
                    AND B.Serl=1000001
              WHERE A.CompanySeq=@CompanySeq
             AND A.MajorSeq=1010712
             AND A.MinorSort=2
              )
                            AND A.DrawDate <=@YYMM+'31'
         AND (A.SlipSeq = 0 OR D.AccDate <=@YYMM+'31')
       
         ) AA  LEFT OUTER JOIN _TDACust CST
            ON CST.CompanySeq=@CompanySeq
              AND AA.CustSeq=CST.CustSeq
     
    )BB 
    GROUP BY   BB.CDCO
        ,BB.NMCO
     HAVING   SUM(ISNULL(BB.AM01,0)) <>0 OR
       SUM(ISNULL(BB.AM02,0)) <>0 OR
       SUM(ISNULL(BB.AM03,0)) <>0 OR 
       SUM(ISNULL(BB.AMGT,0)) <>0 
   
    
    IF @CompanySeq =1 
    BEGIN
       INSERT INTO ODS_KPXGC_HDSLIB_NRAMPF
        SELECT YYMM,CDCO,NMCO,AM01,AM02,AM03,AMGT,DTTMUP FROM ODS_KPX_HDSLIB_NRAMPF_COA WHERE CompanySeq=1 AND YYMM=@YYMM
    END
    
  
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736011
    INSERT INTO KPX_EISIFProcStaus_COA
    SELECT @CompanySeq,@YYMM,1010736011,'1','',@UserSeq,GETDATE()
  
  
  
    /* 생산판매재고 업데이트 */
      
    DELETE FROM  ODS_KPX_HDSLIB_MFSLPF_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM
      
    IF @CompanySeq =1 
    BEGIN
        DELETE FROM ODS_KPXGC_HDSLIB_MFSLPF WHERE  YYMM=@YYMM
    END
    
    CREATE TABLE #TMPData (
        ItemNo    NVARCHAR(100)
       ,ItemName   NVARCHAR(100)
       ,Spec    NVARCHAR(100)    
       ,AssetName   NVARCHAR(100)
       ,PreQty    DECIMAL(19,5)
       ,PreAmt    DECIMAL(19,5)
       ,ProdQty   DECIMAL(19,5) 
       ,ProdAmt   DECIMAL(19,5)
       ,BuyQty    DECIMAL(19,5)
       ,BuyAmt    DECIMAL(19,5)
       ,MvInQty   DECIMAL(19,5)
       ,MvInAmt   DECIMAL(19,5)
       ,EtcInQty   DECIMAL(19,5)
       ,EtcInAmt   DECIMAL(19,5)
       ,ExchangeInQty  DECIMAL(19,5)
       ,ExchangeInAmt  DECIMAL(19,5)
       ,SalesQty   DECIMAL(19,5)
       ,SalesAmt   DECIMAL(19,5)
       ,InputQty   DECIMAL(19,5)
       ,InputAmt   DECIMAL(19,5)
       ,MvOutQty   DECIMAL(19,5)
       ,MvOutAmt   DECIMAL(19,5)
       ,EtcOutQty   DECIMAL(19,5)
       ,EtcOutAmt   DECIMAL(19,5)
       ,ExchangeOutQty  DECIMAL(19,5)
       ,ExchangeOutAmt  DECIMAL(19,5)
       ,InQty    DECIMAL(19,5)
       ,OutAmt    DECIMAL(19,5)
       ,InAmt    DECIMAL(19,5)
       ,StockQty   DECIMAL(19,5)
       ,OutQty    DECIMAL(19,5)
       ,StockAmt   DECIMAL(19,5)
       ,StockQty2   DECIMAL(19,5)
       ,StockAmt2   DECIMAL(19,5)
       ,DiffQty   DECIMAL(19,5)
       ,DiffAmt   DECIMAL(19,5)
       ,UnitName   NVARCHAR(100)
       ,ItemSeq   INT
       ,CostUnitName  NVARCHAR(100)
       ,CostYMFr   NCHAR(8)
       ,CostYMTo   NCHAR(8)
       ,CostUnitKind  INT
       ,ItemKindName  NVARCHAR(100)
       ,UMItemClassSSeq INT
       ,UMItemClassMSeq INT
       ,UMItemClassLSeq INT
       ,UMItemClassSName NVARCHAR(100)
       ,UMItemClassMName NVARCHAR(100)
       ,UMItemClassLName NVARCHAR(100)
       ,Price    DECIMAL(19,5)
        )
      CREATE TABLE #ResultData(
            UMItemClassMSeq INT
           ,QTIW   DECIMAL(19,5)
           ,QTIN   DECIMAL(19,5)
           ,QTSL   DECIMAL(19,5)
           ,QTWR   DECIMAL(19,5)
           ,AMIW   DECIMAL(19,5)
           ,AMIN   DECIMAL(19,5)
           ,AMSL   DECIMAL(19,5)
           ,AMWR   DECIMAL(19,5)
          )
  
      SELECT @SQL=''
     SELECT @SQL='_SESMZStockMonthlyAmt  @xmlDocument=N'''+'<ROOT>'
     SELECT @SQL=@SQL+'<DataBlock1>'+CHAR(10)
     SELECT @SQL=@SQL+'<WorkingTag>A</WorkingTag>'+CHAR(10)
     SELECT @SQL=@SQL+'<IDX_NO>1</IDX_NO>'+CHAR(10)
     SELECT @SQL=@SQL+'<Status>0</Status>'+CHAR(10)
     SELECT @SQL=@SQL+'<DataSeq>1</DataSeq>'+CHAR(10)
     SELECT @SQL=@SQL+'<Selected>1</Selected>'+CHAR(10)
     SELECT @SQL=@SQL+'<TABLE_NAME>DataBlock1</TABLE_NAME>'+CHAR(10)
     SELECT @SQL=@SQL+'<IsChangedMst>0</IsChangedMst>'+CHAR(10)
     SELECT @SQL=@SQL+'<SMCostMng>5512001</SMCostMng>'+CHAR(10)
     SELECT @SQL=@SQL+'<PlanYear></PlanYear>'+CHAR(10)
     SELECT @SQL=@SQL+'<RptUnit></RptUnit>'+CHAR(10)
     SELECT @SQL=@SQL+'<IsAssetType>0</IsAssetType>'+CHAR(10)
     SELECT @SQL=@SQL+'<CostUnit>0</CostUnit>'+CHAR(10)
     SELECT @SQL=@SQL+'<CostUnitName></CostUnitName>'+CHAR(10)
     SELECT @SQL=@SQL+'<CostYMFr>'+CONVERT(NVARCHAR(60),ISNULL(@YYMM,0))+'</CostYMFr>'+CHAR(10)
     SELECT @SQL=@SQL+'<CostYMTo>'+CONVERT(NVARCHAR(60),ISNULL(@YYMM,0))+'</CostYMTo>'+CHAR(10)
     SELECT @SQL=@SQL+'<AppPriceKind>5533001</AppPriceKind>'+CHAR(10)
     SELECT @SQL=@SQL+'<AssetSeq></AssetSeq>'+CHAR(10)
     SELECT @SQL=@SQL+'<AssetName></AssetName>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemSeq></ItemSeq>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemName></ItemName>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemNo></ItemNo>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemClassKind></ItemClassKind>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemClassKindName></ItemClassKindName>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemClassSeq></ItemClassSeq>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemClassName></ItemClassName>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemKind>G</ItemKind>'+CHAR(10)
     SELECT @SQL=@SQL+'</DataBlock1>'
     SELECT @SQL=@SQL+'</ROOT>'''
    SELECT @SQL=@SQL+',@xmlFlags=2,@ServiceSeq=3132,@WorkingTag=N'+''''''
     SELECT @SQL=@SQL+',@CompanySeq='+CONVERT(NVARCHAR(60),@CompanySeq)
     SELECT @SQL=@SQL+',@LanguageSeq=1,@UserSeq=1,@PgmSeq=5810'
      INSERT INTO #TMPData
         EXEC(@SQL)
  
  
     SELECT @SQL=''
     SELECT @SQL='_SESMZStockMonthlyAmt  @xmlDocument=N'''+'<ROOT>'
     SELECT @SQL=@SQL+'<DataBlock1>'+CHAR(10)
     SELECT @SQL=@SQL+'<WorkingTag>A</WorkingTag>'+CHAR(10)
     SELECT @SQL=@SQL+'<IDX_NO>1</IDX_NO>'+CHAR(10)
     SELECT @SQL=@SQL+'<Status>0</Status>'+CHAR(10)
     SELECT @SQL=@SQL+'<DataSeq>1</DataSeq>'+CHAR(10)
     SELECT @SQL=@SQL+'<Selected>1</Selected>'+CHAR(10)
     SELECT @SQL=@SQL+'<TABLE_NAME>DataBlock1</TABLE_NAME>'+CHAR(10)
     SELECT @SQL=@SQL+'<IsChangedMst>0</IsChangedMst>'+CHAR(10)
     SELECT @SQL=@SQL+'<SMCostMng>5512001</SMCostMng>'+CHAR(10)
     SELECT @SQL=@SQL+'<PlanYear></PlanYear>'+CHAR(10)
     SELECT @SQL=@SQL+'<RptUnit></RptUnit>'+CHAR(10)
     SELECT @SQL=@SQL+'<IsAssetType>0</IsAssetType>'+CHAR(10)
     SELECT @SQL=@SQL+'<CostUnit>0</CostUnit>'+CHAR(10)
     SELECT @SQL=@SQL+'<CostUnitName></CostUnitName>'+CHAR(10)
     SELECT @SQL=@SQL+'<CostYMFr>'+CONVERT(NVARCHAR(60),ISNULL(@YYMM,0))+'</CostYMFr>'+CHAR(10)
     SELECT @SQL=@SQL+'<CostYMTo>'+CONVERT(NVARCHAR(60),ISNULL(@YYMM,0))+'</CostYMTo>'+CHAR(10)
     SELECT @SQL=@SQL+'<AppPriceKind>5533001</AppPriceKind>'+CHAR(10)
     SELECT @SQL=@SQL+'<AssetSeq></AssetSeq>'+CHAR(10)
     SELECT @SQL=@SQL+'<AssetName></AssetName>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemSeq></ItemSeq>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemName></ItemName>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemNo></ItemNo>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemClassKind></ItemClassKind>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemClassKindName></ItemClassKindName>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemClassSeq></ItemClassSeq>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemClassName></ItemClassName>'+CHAR(10)
     SELECT @SQL=@SQL+'<ItemKind>F</ItemKind>'+CHAR(10)
     SELECT @SQL=@SQL+'</DataBlock1>'
     SELECT @SQL=@SQL+'</ROOT>'''
     SELECT @SQL=@SQL+',@xmlFlags=2,@ServiceSeq=3132,@WorkingTag=N'+''''''
     SELECT @SQL=@SQL+',@CompanySeq='+CONVERT(NVARCHAR(60),@CompanySeq)
     SELECT @SQL=@SQL+',@LanguageSeq=1,@UserSeq=1,@PgmSeq=5810'
      INSERT INTO #TMPData
         EXEC(@SQL)
    
  
   --1) 년월 -> YYMM
  --2) 품목중분류의 추가정보인 '(경영보고)품목구분코드' -> CDITEM
  --3) 품목중분류의 소분류명 -> NMITEM
  --4) 기초수량 -> QTIW
  --5) 생산수량 -> QTIN
  --6) 판매수량 -> QTSL
  --7) 자가소비수량 -> QTWR
  --4) 기초금액 -> AMIW
  --5) 생산금액 -> AMIN
  --6) 판매금액 -> AMSL
  --7) 자가소비금액 -> AMWR
  --8) DTTMUP -> 처리일시
  
  
  
     INSERT INTO #ResultData(UMItemClassMSeq,QTIW,QTIN,AMIW,AMIN)
        SELECT A.UMItemClassMSeq,A.PreQty,A.ProdQty,A.PreAmt AS PreAmt,A.ProdAmt
          FROM #TMPData A LEFT OUTER JOIN _TDAItem B WITH(NOLOCK)
               ON B.CompanySeq=@CompanySeq
                 AND A.ItemSeq=B.ItemSeq
         WHERE B.AssetSeq IN(1,2) 
     
      INSERT INTO #ResultData(UMItemClassMSeq,QTIW,QTIN,AMIW,AMIN)
        SELECT A.UMItemClassMSeq,A.PreQty,A.BuyQty,A.PreAmt AS PreAmt,A.BuyAmt
          FROM #TMPData A LEFT OUTER JOIN _TDAItem B WITH(NOLOCK)
               ON B.CompanySeq=@CompanySeq
                 AND A.ItemSeq=B.ItemSeq
         WHERE B.AssetSeq IN(3) -- 상품 생산수량은 = 구매수량 , 생산금액 = 구매금액
         
  
     INSERT INTO #ResultData(UMItemClassMSeq,QTSL,AMSL)
     SELECT MV.ValueSeq AS UMItemClassMSeq ,SUM(ISNULL(STDQty,0)) AS Qty,SUM(DomAmt) AS Amt
       FROM _TSLSales A LEFT OUTER JOIN _TSLSalesItem B WITH(NOLOCK)
             ON A.CompanySeq=B.CompanySeq
               AND A.SalesSeq=B.SalesSeq
            LEFT OUTER JOIN _TDAItem ITM  WITH(NOLOCK)
             ON A.CompanySeq=ITM.CompanySeq
               AND B.ItemSeq=ITM.ItemSeq   
            LEFT OUTER JOIN _TDAItemClass  AS IC WITH(NOLOCK) 
             ON ( A.CompanySeq = IC.CompanySeq AND B.ItemSeq = IC.ItemSeq AND IC.UMajorItemClass IN (2001,2004) ) 
            LEFT OUTER JOIN _TDAUMinor      AS M WITH(NOLOCK) ON ( A.CompanySeq = M.CompanySeq AND M.MajorSeq = LEFT( IC.UMItemClass, 4 ) AND IC.UMItemClass = M.MinorSeq ) 
            LEFT OUTER JOIN _TDAUMinorValue AS MV WITH(NOLOCK) ON ( A.CompanySeq = MV.CompanySeq AND MV.MajorSeq IN (2001,2004) AND M.MinorSeq = MV.MinorSeq AND MV.Serl IN (1001,2001) ) 
     WHERE A.CompanySeq=@CompanySeq
       AND A.SalesDate BETWEEN @YYMM+'01' AND  @YYMM+'31'
       AND ITM.AssetSeq IN(1,2,3)
      GROUP BY MV.ValueSeq
      INSERT INTO #ResultData(UMItemClassMSeq,QTWR,AMWR)
         SELECT 
        CI.ItemClassMSeq       AS UMItemClassMSeq
       ,SUM(ISNULL(A.Qty,0))      AS Qty
       ,SUM(ISNULL(A.Amt,0))      AS Amt
        FROM _TESMCProdFMatInput A LEFT OUTER JOIN _TDAItem B WITH(NOLOCK)
                 ON A.CompanySeq=B.CompanySeq
                AND A.MatItemSeq=B.ItemSeq
              JOIN _TESMDCostKey CK WITH(NOLOCK)
                ON A.CompanySeq=CK.CompanySeq
               AND A.CostKeySeq=CK.CostKeySeq
               AND CK.SMCostMng  = 5512001
            LEFT OUTER JOIN _TDAItem ITM WITH(NOLOCK)
                ON A.CompanySeq=ITM.CompanySeq
               AND A.MatItemSeq=ITM.ItemSeq
            LEFT OUTER JOIN _TDAAccount AC WITH(NOLOCK) 
                ON A.CompanySeq=AC.CompanySeq
               AND A.MatAccSeq=AC.AccSeq
            LEFT OUTER JOIN _TDAItemAsset AT WITH(NOLOCK)
                ON A.CompanySeq=AT.CompanySeq
               AND B.AssetSeq=AT.AssetSeq
            LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq,0) AS CI
                ON A.CompanySeq=@CompanySeq
               AND A.ItemSeq=CI.ItemSeq
      WHERE A.CompanySeq=@CompanySeq
     AND CK.CostYM=@YYMM
     AND B.AssetSeq IN(1,2)
     AND CI.ItemClassMSeq IN(SELECT MinorSeq FROM _TDAUMinorValue WHERE CompanySeq=@CompanySeq AND MajorSeq=2002 AND Serl='2003' AND ValueText='I' )
      GROUP BY  CI.ItemClassMSeq
     
  
        INSERT INTO #ResultData(UMItemClassMSeq,QTWR,AMWR)
       SELECT UMItemClassMSeq,InPutQty,InPutAmt 
        FROM #TMPData
       WHERE UMItemClassMSeq IN(SELECT MinorSeq FROM _TDAUMinorValue WHERE CompanySeq=@CompanySeq AND MajorSeq=2002 AND Serl='2003' AND ValueText='O')    
  
  
  
  
  
    
  
      INSERT INTO ODS_KPX_HDSLIB_MFSLPF_COA
       SELECT   @CompanySeq
         ,@YYMM 
               ,MV.ValueText
         ,M.MinorName
         ,SUM(ISNULL(A.QTIW,0)) AS QTIW
         ,SUM(ISNULL(A.QTIN,0)) AS QTIN
         ,SUM(ISNULL(A.QTSL,0)) AS QTSL
         ,SUM(ISNULL(A.QTWR,0)) AS QTWR
         ,SUM(ISNULL(A.AMIW,0)) AS AMIW
         ,SUM(ISNULL(A.AMIN,0)) AS AMIN
         ,SUM(ISNULL(A.AMSL,0)) AS AMSL
         ,SUM(ISNULL(A.AMWR,0))AS AMWR
         ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
     FROM #ResultData A LEFT OUTER JOIN _TDAUMinorValue MV WITH(NOLOCK)
             ON MV.CompanySeq=@CompanySeq
               AND A.UMItemClassMSeq=MV.MinorSeq
               AND MV.Serl=2002
            LEFT OUTER JOIN _TDAUMInor M WITH(NOLOCK)
             ON M.CompanySeq=@CompanySeq
               AND A.UMItemClassMSeq=M.MinorSeq
       WHERE MV.ValueText<>'99'
       GROUP BY  MV.ValueText
          ,M.MinorName
       ORDER BY MV.ValueText
  
  
  
  
   UPDATE A 
      SET QTWR=ISNULL(QTWR,0)+EctOutQty
      ,AMWR=ISNULL(AMWR,0)+EtcOutAmt
     FROM ODS_KPX_HDSLIB_MFSLPF_COA A LEFT OUTER JOIN (SELECT MV.ValueText AS CDITEM ,UMItemClassMSeq,SUM(ISNULL(EtcOutQty,0)) AS EctOutQty,SUM(ISNULL(EtcOutAmt,0)) AS EtcOutAmt
                FROM #TMPData A  LEFT OUTER JOIN _TDAUMinorValue MV WITH(NOLOCK)
                         ON MV.CompanySeq=@CompanySeq
                       AND A.UMItemClassMSeq=MV.MinorSeq
                       AND MV.Serl=2002
                  GROUP BY MV.ValueText,UMItemClassMSeq
                )B ON A.CDITEM=B.CDITEM 
     WHERE A.YYMM=@YYMM
  
  
     UPDATE C
     SET QTSL = QTSL+ISNULL(( SELECT SUM(B.StdQty)   
       FROM _TSLSales A LEFT OUTER JOIN _TSLSalesItem B WITH(NOLOCK)
                ON A.CompanySeq=B.CompanySeq
               AND A.SalesSeq=B.SalesSeq
            LEFT OUTER JOIN _TDAItem  ITM WITH(NOLOCK)
                ON A.CompanySeq = ITM.CompanySeq
               AND B.ItemSeq    = ITM.ItemSeq
          WHERE A.CompanySeq=@CompanySeq
        AND A.SalesDate BETWEEN @YYMM+'01' AND @YYMM+'31'
        AND ITM.AssetSeq IN (4,7) 
        ),0)
       ,AMSL = AMSL+ISNULL(( SELECT SUM(B.DomAmt)   
       FROM _TSLSales A LEFT OUTER JOIN _TSLSalesItem B WITH(NOLOCK)
                ON A.CompanySeq=B.CompanySeq
               AND A.SalesSeq=B.SalesSeq
            LEFT OUTER JOIN _TDAItem  ITM WITH(NOLOCK)
                ON A.CompanySeq = ITM.CompanySeq
               AND B.ItemSeq    = ITM.ItemSeq
          WHERE A.CompanySeq=@CompanySeq
        AND A.SalesDate BETWEEN @YYMM+'01' AND @YYMM+'31'
        AND ITM.AssetSeq IN (4,7) 
        ),0)
     FROM ODS_KPX_HDSLIB_MFSLPF_COA C
   WHERE C.YYMM=@YYMM
     AND C.CDITEM='13'
  
    
    IF @CompanySeq =1 
    BEGIN
        INSERT INTO ODS_KPXGC_HDSLIB_MFSLPF
        SELECT YYMM,CDITEM,NMITEM,QTIW,QTIN,QTSL,QTWR,AMIW,AMIN,AMSL,AMWR,DTTMUP FROM ODS_KPX_HDSLIB_MFSLPF_COA WHERE CompanySeq=1 AND YYMM=@YYMM
    END
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736012
       INSERT INTO KPX_EISIFProcStaus_COA
      SELECT @CompanySeq,@YYMM,1010736012,'1','',@UserSeq,GETDATE()
  
  /* 용도별판매 업데이트 */
  
    DELETE FROM  ODS_KPX_HDSLIB_USAMPF_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM
    IF @CompanySeq =1 
    BEGIN
        DELETE FROM ODS_KPXGC_HDSLIB_USAMPF WHERE  YYMM=@YYMM
    END

  
    INSERT INTO ODS_KPX_HDSLIB_USAMPF_COA
    SELECT   @CompanySeq
       ,@YYMM
       ,M.ValueText
       ,M2.ValueText
       ,M4.MinorName
       ,M5.MinorName
       ,SUM(ISNULL(B.STDQty,0))
       ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
       FROM _TSLSales A LEFT OUTER JOIN _TSLSalesItem B WITH(NOLOCK)
             ON A.CompanySeq=B.CompanySeq
            AND A.SalesSeq=B.SalesSeq
         LEFT OUTER JOIN _TDAItemUserDefine UD WITH(NOLOCK)
             ON A.CompanySeq = UD.CompanySeq
            AND B.ItemSeq=UD.ItemSeq
            AND UD.MngSerl=1000011
         LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
             ON A.CompanySeq=M.CompanySeq
            AND UD.MngValSeq=M.MinorSeq
            AND M.Serl=1000001
         LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
             ON A.CompanySeq=M2.CompanySeq
            AND UD.MngValSeq=M2.MinorSeq
            AND M2.Serl=1000002
         LEFT OUTER JOIN _TDAUMinorValue M3 WITH(NOLOCK)
             ON A.CompanySeq=M3.CompanySeq
            AND M3.MajorSeq=2002
            AND M3.Serl=2002
            AND M.ValueText=M3.ValueText
         LEFT OUTER JOIN _TDAUMinor M4 WITH(NOLOCK)
             ON A.CompanySeq=M4.CompanySeq
            AND M3.MinorSeq=M4.MinorSeq
          LEFT OUTER JOIN _TDAUMinor M5 WITH(NOLOCK)
             ON A.CompanySeq=M5.CompanySeq
            AND M.MinorSeq=M5.MinorSeq
    WHERE A.CompanySeq=@CompanySeq
      AND A.SalesDate BETWEEN @YYMM+'01' AND  @YYMM+'31' 
      AND M.ValueText IS NOT NULL
      GROUP BY M.ValueText,M2.ValueText,M4.MinorName,M5.MinorName
    
    IF @CompanySeq =1 
    BEGIN
        INSERT INTO ODS_KPXGC_HDSLIB_USAMPF
        SELECT YYMM,CDITEM,CDUS,NMITEM,NMUS,QTSL,DTTMUP FROM ODS_KPX_HDSLIB_USAMPF_COA WHERE CompanySeq=1 AND YYMM=@YYMM
    END
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736013
    INSERT INTO KPX_EISIFProcStaus_COA
    SELECT @CompanySeq,@YYMM,1010736013,'1','',@UserSeq,GETDATE() 
  
    /* 매출집계표 업데이트 */
    
    
    DELETE FROM  ODS_KPX_HDSLIB_SLTTPF_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM
    IF @CompanySeq =1 
    BEGIN
        DELETE FROM ODS_KPXGC_HDSLIB_SLTTPF WHERE  YYMM=@YYMM
    END
    
    CREATE TABLE #TmpSalesSum
    (
        GUBN NVARCHAR(60)
        ,ISDA NVARCHAR(60)
        ,NMBN NVARCHAR(60)
        ,NMSA NVARCHAR(60)
        ,QTSL DECIMAL(19,5)
        ,AMSL DECIMAL(19,5)
        ,VAT  DECIMAL(19,5)
        ,TAX  DECIMAL(19,5)
    )
    
  
  
       INSERT INTO #TmpSalesSum
       SELECT BB.GUBN
         ,BB.ISDA
         ,BB.NMBN
         ,BB.NMSA
        ,SUM(ISNULL(QTSL,0)) AS QTSL
        ,SUM(ISNULL(AMSL,0)) AS AMSL
        ,SUM(ISNULL(VAT,0))  AS VAT
        ,SUM(ISNULL(TAX,0))  AS TAX
      FROM 
         (SELECT  AA.ValueText     AS GUBN 
       ,AA.ValueText2     AS ISDA 
       ,AA.MinorName     AS NMBN 
       ,AA.ValueText3     AS NMSA
       ,ISNULL(SI.STDQty,0)   AS QTSL
       ,ISNULL(SI.DomAmt,0)   AS AMSL
       ,ISNULL(SI.DomVAT,0)   AS VAT
       ,0        AS TAX 
        FROM  _TSLSales SM  LEFT OUTER JOIN _TSLSalesItem SI WITH(NOLOCK)
              ON SI.CompanySeq = @CompanySeq
              AND SM.SalesSeq=SI.SalesSeq
           LEFT OUTER JOIN _TDAItemClass AS IC WITH(NOLOCK) 
              ON (IC.CompanySeq = @CompanySeq AND SI.ItemSeq = IC.ItemSeq AND IC.UMajorItemClass IN (2001,2004) ) 
           LEFT OUTER JOIN _TDAUMinor AS MQ WITH(NOLOCK) ON ( MQ.CompanySeq = @CompanySeq AND MQ.MajorSeq = LEFT( IC.UMItemClass, 4 ) AND IC.UMItemClass = MQ.MinorSeq ) 
           LEFT OUTER JOIN _TDAUMinorValue AS MV WITH(NOLOCK) ON ( MV.CompanySeq = @CompanySeq AND MV.MajorSeq IN (2001,2004) AND MQ.MinorSeq = MV.MinorSeq AND MV.Serl IN (1001,2001) ) 
           LEFT OUTER JOIN _TDASMinorValue B WITH(NOLOCK)
               ON SM.CompanySeq = B.CompanySeq
              AND SM.SMExpKind=B.MinorSeq
              AND B.Serl=1000001
           LEFT OUTER JOIN 
               ( SELECT A.MinorName ,A.MinorSeq,M.ValueText ValueText ,M2.ValueSeq AS ValueSeq ,M3.ValueText AS ValueText2,M4.ValueText AS ValueText3
                FROM _TDAUMinor A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                        ON A.CompanySeq=M.CompanySeq
                        AND A.MinorSeq=M.MinorSeq
                        AND M.Serl=1000001
                     LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                        ON A.CompanySeq=M2.CompanySeq
                        AND A.MinorSeq=M2.MinorSeq
                        AND M2.Serl=1000002
                     LEFT OUTER JOIN _TDAUMinorValue M3 WITH(NOLOCK)
                        ON A.CompanySeq=M3.CompanySeq
                        AND A.MinorSeq=M3.MinorSeq
                        AND M3.Serl=1000003
                     LEFT OUTER JOIN _TDAUMinorValue M4 WITH(NOLOCK)
                        ON A.CompanySeq=M4.CompanySeq
                        AND A.MinorSeq=M4.MinorSeq
                        AND M4.Serl=1000004
                WHERE A.CompanySeq=@CompanySeq
                 AND A.MajorSeq=1010705
                 AND M3.ValueText<>'9'
                ) AA ON B.ValueText=AA.ValueText2
                 AND MV.ValueSeq=AA.ValueSeq
           LEFT OUTER JOIN _TDAItem ITM WITH(NOLOCK)
               ON SM.CompanySeq=ITM.CompanySeq
              AND SI.ItemSeq=ITM.ItemSeq
       WHERE SM.CompanySeq=@CompanySeq
      AND SM.SalesDate BETWEEN @YYMM+'01' AND  @YYMM+'31'  
      AND AA.MinorName IS NOT NULL
      UNION ALL
         SELECT 'G' AS GUBN
         ,'1' AS IDSA
         ,'EOA상품' AS NMBN
         ,'내수'    AS NMSA 
         ,ISNULL(B.STDQty,0) AS QTSL
         ,ISNULL(B.DomAmt,0) AS AMSL
         ,ISNULL(B.DomVAT,0) AS VAT
         ,0 AS TAX
        FROM _TSLSales A LEFT OUTER JOIN _TSLSalesItem B WITH(NOLOCK)
                ON A.CompanySeq=B.CompanySeq
               AND A.SalesSeq=B.SalesSeq
            LEFT OUTER JOIN _TDAItem  ITM WITH(NOLOCK)
                ON A.CompanySeq = ITM.CompanySeq
               AND B.ItemSeq    = ITM.ItemSeq
          WHERE A.CompanySeq=@CompanySeq
        AND A.SalesDate BETWEEN @YYMM+'01' AND @YYMM+'31'
        AND ITM.AssetSeq IN (4,7) 
        ) BB
       GROUP BY BB.GUBN
            ,BB.ISDA
            ,BB.NMBN
            ,BB.NMSA  
  
    
  
        INSERT INTO  ODS_KPX_HDSLIB_SLTTPF_COA
    SELECT   
       @CompanySeq
      ,@YYMM
      ,AA.GUBN
      ,AA.ISDA
      ,AA.NMBN
      ,AA.NMSA
      ,AA.QTSL
      ,AA.AMSL
      ,AA.VAT
      ,AA.TAX 
      ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
          FROM 
     (
     SELECT   GUBN
       ,ISDA
       ,NMBN
       ,NMSA
       ,QTSL
       ,AMSL
       ,VAT
       ,TAX
      FROM #TmpSalesSum
     UNION ALL
     SELECT   GUBN
       ,9
       ,NMBN
       ,'합계'
       ,SUM(QTSL)
       ,SUM(AMSL)
       ,SUM(VAT)
       ,SUM(TAX)
      FROM #TmpSalesSum
      GROUP BY GUBN,NMBN
     ) AA
     ORDER BY GUBN,ISDA
  
    IF @CompanySeq =1 
    BEGIN
       INSERT INTO ODS_KPXGC_HDSLIB_SLTTPF
        SELECT YYMM,GUBN,IDSA,NMBN,NMSA,QTSL,AMSL,VAT,TAX,DTTMUP FROM ODS_KPX_HDSLIB_SLTTPF_COA WHERE CompanySeq=1 AND YYMM=@YYMM
    END
    
        
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736014
       INSERT INTO KPX_EISIFProcStaus_COA
      SELECT @CompanySeq,@YYMM,1010736014,'1','',@UserSeq,GETDATE() 
  
 /* 재무상태표 업데이트 */
   DELETE FROM  ODS_KPX_HDSLIB_BSAMPF_COA WHERE CompanySeq = @CompanySeq AND YYMM=@YYMM 
  
  
    IF @CompanySeq =1 
    BEGIN
        DELETE FROM ODS_KPXGC_HDSLIB_BSAMPF WHERE  YYMM=@YYMM
    END
    
    
  
   CREATE TABLE #tmpFinancialStatement
     (
         RowNum      INT IDENTITY(0, 1)
     )
      ALTER TABLE #tmpFinancialStatement ADD ThisTermItemAmt       DECIMAL(19, 5)  -- 당기항목금액
     ALTER TABLE #tmpFinancialStatement ADD ThisTermAmt           DECIMAL(19, 5)  -- 당기금액
     ALTER TABLE #tmpFinancialStatement ADD PrevTermItemAmt       DECIMAL(19, 5)  -- 전기항목금액
     ALTER TABLE #tmpFinancialStatement ADD PrevTermAmt           DECIMAL(19, 5)  -- 전기금액
     ALTER TABLE #tmpFinancialStatement ADD PrevChildAmt          DECIMAL(19, 5)  -- 하위금액
     ALTER TABLE #tmpFinancialStatement ADD ThisChildAmt          DECIMAL(19, 5)  -- 하위금액
     ALTER TABLE #tmpFinancialStatement ADD ThisReplaceFormula    NVARCHAR(1000)   -- 당기금액
     ALTER TABLE #tmpFinancialStatement ADD PrevReplaceFormula    NVARCHAR(1000)   -- 당기금액
    
      EXEC _SCOMFSFormInit @CompanySeq, 2, 1, '#tmpFinancialStatement'
     EXEC _SCOMFSFormMakeRawData @CompanySeq, 2, 0, 0, @YYMM, @YYMM, '', '','' , '#tmpFinancialStatement','1', '0', '0', 0
  EXEC _SCOMFSFormCalc @CompanySeq, 2, '#tmpFinancialStatement', 1
   
  
 --select * from #tmpFinancialStatement
  --where FSItemSeq IN
 --(
 --110
 --,872
 --,748
 --,870
 -- )
  
  -- return
  
      SELECT ISNULL(CDACHG,'')AS CDACHG,
         ISNULL(CDAC,'') AS CDAC, 
      --ISNULL(DRBalAmt,0)+ISNULL(CrBalAmt,0) AS Amt
            --(ISNULL(DRBalAmt,0)+ISNULL(CrBalAmt,0)) AS Amt
      CASE WHEN B.Calc ='-' THEN -1 * (ISNULL(DRBalAmt,0)+ISNULL(CrBalAmt,0)) ELSE (ISNULL(DRBalAmt,0)+ISNULL(CrBalAmt,0))  END AS Amt--,C.SMDrOrCr AS SMDrOrCr
    INTO #TMPResult 
    FROM KPX_TEISAcc_COA A LEFT OUTER JOIN KPX_TEISAccSub_COA B WITH(NOLOCK)
            ON A.CompanySeq=B.CompanySeq
           AND A.Seq=B.Seq
        LEFT OUTER JOIN #tmpFinancialStatement C WITH(NOLOCK)
            ON B.AccSeq=C.FSItemSeq
   WHERE A.CompanySeq = @CompanySeq   
     AND KindSeq=1010735001
     --AND CDAC='23020000'
      --AND IsLast='1'
 --    AND C.FsItemSeq IN
 --    (
 -- 74
 --,73
 --,77
 --,76
 --,80
 --,79
 --,471
 --,84
 --,473
 --,86
 --,475
 --,82
 --)
  
  
  
  --  SELECT CDACHG,CDAC,SUM(Amt) AS Amt
  --    INTO #TMPResultData
  --    FROM #TMPResult 
  --WHERE CDACHG<>''
  --  GROUP BY CDACHG,CDAC
   
  
 --  INSERT INTO 
    
  ----  CompanySeq
 ----YYMM
 ----CDAC
 ----NMAC
 ----AMT
 ----DTTMUP
  
    
    CREATE TABLE #TMPACData  
        (
         CDACHG NVARCHAR(30)
           ,CDAC NVARCHAR(30)
           ,Amt  DECIMAL(19,5)
         )
      CREATE TABLE #TMPACData2 
         (
         CDACHG NVARCHAR(30)
           ,CDAC NVARCHAR(30)
           ,Amt  DECIMAL(19,5)
         )
  
     CREATE TABLE #TMPACData3
         (
         CDACHG NVARCHAR(30)
           ,CDAC NVARCHAR(30)
           ,Amt  DECIMAL(19,5)
         )
  
    
     CREATE TABLE #TMPACData4
         (
         CDACHG NVARCHAR(30)
           ,CDAC NVARCHAR(30)
           ,Amt  DECIMAL(19,5)
         )
  
     INSERT INTO #TMPACData
           SELECT ISNULL((SELECT MAX(CDACHG)  FROM KPX_TEISAcc_COA WHERE CDAC=A.CDACHG),'')  AS CDACHG, A.CDACHG AS CDAC,SUM(ISNULL(A.Amt,0))
       FROM #TMPResult A
               GROUP BY A.CDACHG
    --  HAVING (SELECT MAX(CDACHG)  FROM KPX_TEISAcc WHERE CDAC=A.CDACHG)<>''
  
    INSERT INTO #TMPACData2
           SELECT ISNULL((SELECT MAX(CDACHG)  FROM KPX_TEISAcc_COA WHERE CDAC=A.CDACHG),'')  AS CDACHG , A.CDACHG AS CDAC,SUM(ISNULL(A.Amt,0))
       FROM #TMPACData A
               GROUP BY A.CDACHG
  
    INSERT INTO #TMPACData3
           SELECT ISNULL((SELECT MAX(CDACHG)  FROM KPX_TEISAcc_COA WHERE CDAC=A.CDACHG),'') AS CDACHG, A.CDACHG AS CDAC ,SUM(ISNULL(A.Amt,0))
       FROM #TMPACData2 A
               GROUP BY A.CDACHG
     
    INSERT INTO #TMPACData4
           SELECT ISNULL((SELECT MAX(CDACHG)  FROM KPX_TEISAcc_COA WHERE CDAC=A.CDACHG),'') AS CDACHG, A.CDACHG AS CDAC ,SUM(ISNULL(A.Amt,0))
       FROM #TMPACData3 A
               GROUP BY A.CDACHG
    
   
    INSERT INTO ODS_KPX_HDSLIB_BSAMPF_COA ( CompanySeq, YYMM, CDAC, CDWG, NMAC, NMWG, AMT, DTTMUP ) 
    SELECT  @CompanySeq
       ,@YYMM
       ,A.CDAC
       ,0
       ,A.NMAC
       ,'' 
       ,CASE WHEN Dummy1 = '-' THEN -1 * ISNULL(Amt,0) ELSE ISNULL(Amt,0) END  AS Amt
       ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
      FROM KPX_TEISAcc_COA A JOIN 
            (
              SELECT AA.CDAC,SUM(ISNULL(Amt,0)) AS Amt
               FROM  
              ( 
               SELECT CDACHG,CDAC,Amt FROM #TmpResult WHERE CDAC<>''
               UNION ALL
               SELECT CDACHG,CDAC,Amt FROM #TMPACData WHERE CDAC<>''
               UNION ALL
               SELECT CDACHG,CDAC,Amt FROM #TMPACData2 WHERE CDAC<>''
               UNION ALL
               SELECT CDACHG,CDAC,Amt FROM #TMPACData3 WHERE CDAC<>''
               UNION ALL
               SELECT CDACHG,CDAC,Amt FROM #TMPACData4 WHERE CDAC<>''
              )AA
              GROUP BY AA.CDAC
             ) BB ON A.CompanySeq=@CompanySeq
                 AND A.CDAC=BB.CDAC
   
    
    
     
     DECLARE @Dummy1 DECIMAL(19,5)
     DECLARE @Dummy2 DECIMAL(19,5)
     DECLARE @Dummy3 DECIMAL(19,5)
     DECLARE @Dummy4 DECIMAL(19,5)
      SELECT @Dummy1=0,@Dummy2=0,@Dummy3=0,@Dummy4=0
     
          --  자산합계
      SELECT @Dummy1=ISNULL(Amt,0)
       FROM ODS_KPX_HDSLIB_BSAMPF_COA
      WHERE  CompanySeq=@CompanySeq
        AND CDAC='10000000'
        AND YYMM=@YYMM
        
      -- 부채합계
      SELECT @Dummy2=ISNULL(Amt,0)
       FROM ODS_KPX_HDSLIB_BSAMPF_COA
      WHERE  CompanySeq=@CompanySeq
       AND CDAC='20000000'
       AND YYMM=@YYMM
        
     
     -- 자본합계
      SELECT @Dummy3=ISNULL(Amt,0)
       FROM ODS_KPX_HDSLIB_BSAMPF_COA
      WHERE  CompanySeq=@CompanySeq
       AND CDAC='30000000'
       AND YYMM=@YYMM
     
     SELECT @Dummy4=SUM(ISNULL(Amt,0))
       FROM ODS_KPX_HDSLIB_BSAMPF_COA
      WHERE  CompanySeq=@CompanySeq
       AND CDAC BETWEEN '31010000' AND '31039999'
       AND YYMM=@YYMM
  
    -- 이익잉여금
       UPDATE ODS_KPX_HDSLIB_BSAMPF_COA
         SET AMT=@Dummy1 - @Dummy2 - @Dummy4
       WHERE CompanySeq=@CompanySeq
      AND CDAC='31040000'
         AND YYMM=@YYMM
  
    -- 자본 & 자본총계
       UPDATE ODS_KPX_HDSLIB_BSAMPF_COA
         SET AMT=@Dummy4+(SELECT AMT FROM ODS_KPX_HDSLIB_BSAMPF_COA WHERE CompanySeq = @CompanySeq AND YYMM=@YYMM AND CDAC='31040000')
       WHERE CompanySeq=@CompanySeq
      AND CDAC IN('31000000','40000000') 
         AND YYMM=@YYMM
      
  
  
      --UPDATE ODS_KPX_HDSLIB_BSAMPF_COA
      --   SET AMT=@Dummy1 - @Dummy2 + @Dummy3
      -- WHERE CompanySeq=@CompanySeq
      --AND CDAC='3502100'  
      --AND YYMM=@YYMM
           
     
     
  
             -- 자본합계
       UPDATE ODS_KPX_HDSLIB_BSAMPF_COA
         SET AMT=AMT+(@Dummy1 - @Dummy2 - @Dummy3)
       WHERE CompanySeq=@CompanySeq
      AND CDAC='30000000' 
      AND YYMM=@YYMM
  
           -- 자본총계 = 자본합계
       UPDATE ODS_KPX_HDSLIB_BSAMPF_COA
         SET AMT=(SELECT AMT FROM ODS_KPX_HDSLIB_BSAMPF_COA WHERE CompanySeq = @CompanySeq AND YYMM=@YYMM AND CDAC='30000000')
       WHERE CompanySeq=@CompanySeq
      AND CDAC='40000000' 
      AND YYMM=@YYMM
  
  
  
        UPDATE ODS_KPX_HDSLIB_BSAMPF_COA
         SET AMT= (SELECT SUM(ISNULL(AMT,0)) FROM ODS_KPXGC_HDSLIB_BSAMPF WHERE CDAC IN('2000000','3000000') AND YYMM=@YYMM  ) 
       WHERE CDAC='3999999'
      AND CompanySeq = @CompanySeq
      AND YYMM=@YYMM 
    
    
    IF @CompanySeq =1 
    BEGIN
       INSERT INTO ODS_KPXGC_HDSLIB_BSAMPF
        SELECT  YYMM,CDAC,NMAC,AMT,DTTMUP FROM ODS_KPX_HDSLIB_BSAMPF_COA WHERE CompanySeq=1 AND YYMM=@YYMM
    END
    
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736015
       INSERT INTO KPX_EISIFProcStaus_COA
      SELECT @CompanySeq,@YYMM,1010736015,'1','',@UserSeq,GETDATE() 
  
    
  /* 재조원가명세서 업데이트 */
   /*******************************************
    
      DELETE FROM   ODS_KPX_HDSLIB_MCAMPF_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM 
  
     IF @CompanySeq =1 
      BEGIN
      DELETE FROM ODS_KPXGC_HDSLIB_MCAMPF_COA WHERE  YYMM=@YYMM
      END
      ELSE IF @CompanySeq =2 
      BEGIN
      DELETE FROM ODS_KPXCM_HDSLIB_MCAMPF_COA WHERE  YYMM=@YYMM
      END
      ELSE IF @CompanySeq =3 
      BEGIN
      DELETE FROM ODS_KPXLS_HDSLIB_MCAMPF_COA WHERE  YYMM=@YYMM
      END
      ELSE IF @CompanySeq =4 
      BEGIN
      DELETE FROM ODS_KPXHD_HDSLIB_MCAMPF_COA WHERE  YYMM=@YYMM
      END
  
  
        CREATE TABLE #ProdCost(
             CDCS NVARCHAR(30)
            ,CDAC NVARCHAR(30)
            ,NMCS NVARCHAR(30)
            ,NMAC NVARCHAR(30)
            ,AMT  DECIMAL(19,5)
             )
  
  
   --   SELECT * FROM ODS_KPX_HDSLIB_MFSLPF_COA
  
  --select * from ODS_KPX_HDSLIB_MCAMPF_COA
   --select * from ODS_KPX_HDSLIB_MFSLPF_COA
  
     -- CREATE TABLE #TBase -- 경영보고용-조직코드담는 테이블(해당 코드의 데이터가 없을시 0의 값이 넣기위함. 
    -- (
    --     CDCS NVARCHAR(30)
    -- ,NMCS NVARCHAR(30)
    -- ) 
           
  
    --INSERT INTO #TBase
    --    SELECT B.ValueText,C.ValueText
    --      FROM _TDAUMinor A LEFT OUTER JOIN _TDAUMinorValue B 
    --          ON A.CompanySeq = B.CompanySeq
    --            AND A.MinorSeq = B.MinorSeq
    --            AND B.Serl = 1000004
    --         LEFT OUTER JOIN _TDAUMinorValue C 
    --          ON A.CompanySeq = C.CompanySeq
    --            AND A.MinorSeq = C.MinorSeq
    --            AND C.Serl = 1000005
    --    WHERE A.CompanySeq = @CompanySeq
    --      AND A.MajorSeq = 2003
    --   AND B.ValueText<>'90'
  
    --    SELECT * FROM #TBase
      -- 생산수량
     INSERT INTO #ProdCost  
      SELECT M3.ValueText AS CDCS
         ,'010000'     AS CDAC
         ,M4.ValueText AS NMCS
         ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='010000' AND KindSeq=1010735003) AS NMAC
         ,SUM(QTIN)-SUM(QTWR)    AS AMT
        FROM ODS_KPX_HDSLIB_MFSLPF_COA A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                  ON A.CompanySeq = M.CompanySeq
                    AND A.CDITEM     = M.ValueText
                    AND M.MajorSeq = 2002
                    AND M.Serl = 2002
                 LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                  ON A.CompanySeq = M2.CompanySeq
                    AND M.MinorSeq = M2.MinorSeq
                    AND M2.Serl = 2001
                 LEFT OUTER JOIN _TDAUMinorValue M3 WITH(NOLOCK)
                  ON A.CompanySeq = M3.CompanySeq
                    AND M2.ValueSeq = M3.MinorSeq
                    AND M3.MajorSeq = 2003
                    AND M3.Serl = 1000004
                 LEFT OUTER JOIN _TDAUMinorValue M4 WITH(NOLOCK)
                  ON A.CompanySeq = M4.CompanySeq
                    AND M2.ValueSeq = M4.MinorSeq
                    AND M4.MajorSeq = 2003
                    AND M4.Serl = 1000005
        WHERE A.CompanySeq=@CompanySeq
          AND A.YYMM=@YYMM
          AND A.NMITEM LIKE '%제품%'
       GROUP BY M3.ValueText,M4.ValueText
     -- 생산금액
     
       INSERT INTO #ProdCost      
       SELECT CC.CDCS,
        CC.CDAC,
        CC.NMCS,
        CC.NMAC,
        D.AMT*CC.AMT AS AMT
                 FROM 
  
      (  SELECT BB.CDCS,
        '020000' AS CDAC,
        BB.NMCS,
        (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='020000' AND KindSeq=1010735003) AS NMAC,
        ISNULL((SUM(A.AMSL)+SUM(A.VAT))/SUM(A.QTSL),0) AS AMT
         FROM ODS_KPX_HDSLIB_SLTTPF_COA A LEFT OUTER JOIN ( SELECT M.ValueText AS GUBN ,M5.ValueText AS CDCS ,M6.ValueText AS NMCS
                    FROM _TDAUMinor A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                              ON A.CompanySeq=M.CompanySeq
                             AND A.MinorSeq = M.MinorSeq
                             AND M.Serl=1000001
                            JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                              ON A.CompanySeq=M2.CompanySeq
                             AND A.MinorSeq = M2.MinorSeq
                             AND M2.Serl=1000002
                            JOIN _TDAUMinorValue M3 WITH(NOLOCK)
                              ON A.CompanySeq=M3.CompanySeq
                             AND A.MinorSeq = M3.MinorSeq
                             AND M3.Serl=1000003
                             AND M3.ValueText='1'
                            JOIN _TDAUMinorValue M4 WITH(NOLOCK)
                              ON A.CompanySeq = M4.CompanySeq
                             AND M2.ValueSeq = M4.MinorSeq
                             AND M4.MajorSeq = 2002
                             AND M4.Serl = 2001
                            JOIN _TDAUMinorValue M5 WITH(NOLOCK)
                              ON A.CompanySeq = M5.CompanySeq
                             AND M4.ValueSeq = M5.MinorSeq
                             AND M5.MajorSeq = 2003
                             AND M5.Serl = 1000004
                            JOIN _TDAUMinorValue M6 WITH(NOLOCK)
                              ON A.CompanySeq = M6.CompanySeq
                             AND M4.ValueSeq = M6.MinorSeq
                             AND M6.MajorSeq = 2003
                             AND M6.Serl = 1000005
                     WHERE A.CompanySeq =@CompanySeq 
                      AND A.MajorSeq=1010705
                      AND M5.ValueText<>'90'
                      )BB ON A.CompanySeq=@CompanySeq
                      AND A.GUBN=BB.GUBN
               
      WHERE A.CompanySeq=@CompanySeq
          AND A.YYMM=@YYMM
          AND A.NMBN LIKE '%제품%'
      GROUP BY BB.CDCS,BB.NMCS
      ) CC LEFT OUTER JOIN #ProdCost D WITH(NOLOCK)
            ON CC.CDCS = D.CDCS
                -- 제품 국내
      INSERT INTO #ProdCost  
      SELECT E.CDCS,
       '030100' AS CDAC,
       E.NMCS,
       (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='030100' AND KindSeq=1010735003) AS NMAC, 
       ISNULL(E.AMT,0) - ISNULL(F.AMT,0) AS AMT 
     FROM
               ( SELECT BB.CDCS,
        BB.NMCS,
        ISNULL((SUM(A.AMSL)+SUM(A.VAT)),0) AS AMT
         FROM ODS_KPX_HDSLIB_SLTTPF_COA A LEFT OUTER JOIN ( SELECT M.ValueText AS GUBN ,M5.ValueText AS CDCS ,M6.ValueText AS NMCS
                    FROM _TDAUMinor A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                              ON A.CompanySeq=M.CompanySeq
                             AND A.MinorSeq = M.MinorSeq
                             AND M.Serl=1000001
                            JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                              ON A.CompanySeq=M2.CompanySeq
                             AND A.MinorSeq = M2.MinorSeq
                             AND M2.Serl=1000002
                            JOIN _TDAUMinorValue M3 WITH(NOLOCK)
                              ON A.CompanySeq=M3.CompanySeq
                             AND A.MinorSeq = M3.MinorSeq
                             AND M3.Serl=1000003
                             AND M3.ValueText='1'
                            JOIN _TDAUMinorValue M4 WITH(NOLOCK)
                              ON A.CompanySeq = M4.CompanySeq
                             AND M2.ValueSeq = M4.MinorSeq
                             AND M4.MajorSeq = 2002
                             AND M4.Serl = 2001
                            JOIN _TDAUMinorValue M5 WITH(NOLOCK)
                              ON A.CompanySeq = M5.CompanySeq
                             AND M4.ValueSeq = M5.MinorSeq
                             AND M5.MajorSeq = 2003
                             AND M5.Serl = 1000004
                            JOIN _TDAUMinorValue M6 WITH(NOLOCK)
                              ON A.CompanySeq = M6.CompanySeq
                             AND M4.ValueSeq = M6.MinorSeq
                             AND M6.MajorSeq = 2003
                             AND M6.Serl = 1000005
                     WHERE A.CompanySeq =@CompanySeq 
                      AND A.MajorSeq=1010705
                      AND M5.ValueText<>'90'
                      )BB ON A.CompanySeq=@CompanySeq
                      AND A.GUBN=BB.GUBN
        WHERE A.CompanySeq=@CompanySeq
          AND A.YYMM=@YYMM
          AND A.NMBN LIKE '%제품%'
      GROUP BY BB.CDCS,BB.NMCS
       ) E LEFT OUTER JOIN ODS_KPX_HDSLIB_FRAMPF_COA F 
            ON F.CompanySeq=@CompanySeq
           AND E.CDCS=F.CDCS
           AND F.YYMM=@YYMM
    -- 제품해외      
    INSERT INTO #ProdCost 
           SELECT CDCS,
        '030200' AS CDAC,
         NMCS,
         (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='030200' AND KindSeq=1010735003) AS NMAC, 
         AMT AS AMT 
          FROM ODS_KPX_HDSLIB_FRAMPF_COA 
      WHERE CompanySeq = @CompanySeq
        AND YYMM=@YYMM
    
      -- 상품매출
        INSERT INTO #ProdCost
         SELECT BB.CDCS,
             '030300' AS CDAC,
       BB.NMCS,
       (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='030300' AND KindSeq=1010735003) AS NMAC, 
       ISNULL((SUM(A.AMSL)+SUM(A.VAT)),0) AS AMT
     FROM ODS_KPX_HDSLIB_SLTTPF_COA A LEFT OUTER JOIN ( SELECT M.ValueText AS GUBN ,M5.ValueText AS CDCS ,M6.ValueText AS NMCS
                  FROM _TDAUMinor A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                          ON A.CompanySeq=M.CompanySeq
                          AND A.MinorSeq = M.MinorSeq
                          AND M.Serl=1000001
                          JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                          ON A.CompanySeq=M2.CompanySeq
                          AND A.MinorSeq = M2.MinorSeq
                          AND M2.Serl=1000002
                          JOIN _TDAUMinorValue M3 WITH(NOLOCK)
                          ON A.CompanySeq=M3.CompanySeq
                          AND A.MinorSeq = M3.MinorSeq
                          AND M3.Serl=1000003
                          AND M3.ValueText='1'
                          JOIN _TDAUMinorValue M4 WITH(NOLOCK)
                          ON A.CompanySeq = M4.CompanySeq
                          AND M2.ValueSeq = M4.MinorSeq
                          AND M4.MajorSeq = 2002
                          AND M4.Serl = 2001
                          JOIN _TDAUMinorValue M5 WITH(NOLOCK)
                          ON A.CompanySeq = M5.CompanySeq
                          AND M4.ValueSeq = M5.MinorSeq
                          AND M5.MajorSeq = 2003
                          AND M5.Serl = 1000004
                          JOIN _TDAUMinorValue M6 WITH(NOLOCK)
                          ON A.CompanySeq = M6.CompanySeq
                          AND M4.ValueSeq = M6.MinorSeq
                          AND M6.MajorSeq = 2003
                          AND M6.Serl = 1000005
                   WHERE A.CompanySeq =@CompanySeq 
                  AND A.MajorSeq=1010705
                  AND M5.ValueText<>'90'
                 )BB ON A.CompanySeq=@CompanySeq
                  AND A.GUBN=BB.GUBN
        WHERE A.CompanySeq=@CompanySeq
          AND A.YYMM=@YYMM
          AND A.NMBN LIKE '%상품%'
      GROUP BY BB.CDCS,BB.NMCS
  
  
  
  
  
  
                   -- [품목별재료비투입조회] 화면에서 품목대분류별 '원부료'투입금액 
       -- 해당화면에는 품목소분류별별로 나오기 때문에 품목대분류로 다시 집계해야하고, 재고자산분류가 '원부료'인 것만 금액 집계해야함.
        -- 재료비
        INSERT INTO #ProdCost   
       SELECT M.ValueText        AS CDCS
         ,'040200'        AS CDAC
         ,M2.ValueText    AS NMCS
         ,AC.NMAC     AS NMAC
         ,SUM(ISNULL(Amt,0)) AS AMT
        FROM _TESMCProdFMatInput A LEFT OUTER JOIN _TDAItem ITM WITH(NOLOCK)
                  ON A.CompanySeq=ITM.CompanySeq
                  AND A.MatItemSeq=ITM.ItemSeq
                  --AND ITM.AssetSeq=4
               LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq,0) B
                  ON A.CompanySeq=@CompanySeq
                  AND A.ItemSeq=B.ItemSeq
               LEFT OUTER JOIN _TESMDCostKey CK WITH(NOLOCK)
                  ON A.CompanySeq=CK.CompanySeq
                  AND A.CostKeySeq=CK.CostKeySeq
                  AND CK.SMCostMng=5512001
               LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                  ON A.CompanySeq=M.CompanySeq
                  AND B.ItemClassLSeq=M.MinorSeq
                  AND M.Serl=1000004
               LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                  ON A.CompanySeq=M2.CompanySeq
                  AND B.ItemClassLSeq=M2.MinorSeq
                  AND M2.Serl=1000005
               LEFT OUTER JOIN KPX_TEISAcc_COA AC WITH(NOLOCK)
                  ON A.CompanySeq=AC.CompanySeq
                  AND AC.CDAC='040200'
                  AND AC.KindSeq=1010735003
               LEFT OUTER JOIN _TDAItemAsset AT WITH(NOLOCK)
                  ON A.CompanySeq = AT.CompanySeq
                  AND ITM.AssetSeq = AT.AssetSeq
        WHERE A.CompanySeq=@CompanySeq
        AND CK.CostYM=@YYMM
        AND M.ValueText<>'90'
        AND AT.SMAssetGrp=6008006
       GROUP BY M.ValueText ,M2.ValueText,AC.NMAC
  
      -- (경영보고)통합COA계정등록의 마스터에 관리회계계정 맵핑된 데이터 집계
     INSERT INTO #ProdCost
     SELECT 
         M.ValueText       AS CDCS
        ,A.CDAC        AS CDAC
        ,M2.ValueText       AS NMCS
        ,A.NMAC        AS NMAC
        ,SUM(ISNULL(CR.InPutCost,0)) AS AMT 
       -- ,SUM(ISNULL(CR.ProcCost,0)) AS AMT 
       FROM KPX_TEISAcc_COA A LEFT OUTER JOIN KPX_TEISAccSub_COA B WITH(NOLOCK)
               ON A.CompanySeq=B.CompanySeq
              AND A.Seq=B.Seq 
           LEFT OUTER JOIN _TESMCProdFGoodCostResult CR WITH(NOLOCK)
               ON A.CompanySeq=CR.CompanySeq
              AND B.AccSeq=CR.CostAccSeq
           LEFT OUTER JOIN _TESMDCostKey CK WITH(NOLOCK)
               ON A.CompanySeq=CK.CompanySeq
              AND CR.CostKeySeq=CK.CostKeySeq
              AND CK.SMCostMng=5512001
           LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq,0) F
               ON A.CompanySeq=@CompanySeq
              AND CR.ItemSeq=F.ItemSeq
           LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                   ON A.CompanySeq=M.CompanySeq
                  AND F.ItemClassLSeq=M.MinorSeq
                  AND M.Serl=1000004
           LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                   ON A.CompanySeq=M2.CompanySeq
                  AND F.ItemClassLSeq=M2.MinorSeq
                  AND M2.Serl=1000005
      WHERE A.CompanySeq=@CompanySeq
        AND A.KindSeq=1010735003
        --AND A.CDAC BETWEEN '7300100' AND '7300900' 
        AND CK.CostYM=@YYMM
        AND M.ValueText<>'90'
      
       GROUP BY M.ValueText ,A.CDAC,M2.ValueText,A.NMAC
  
     INSERT INTO #ProdCost
    SELECT CDCS
       ,'7300000'
       ,A.NMCS
       ,(SELECT NMAC FROM KPX_TEISAcc WHERE CompanySeq=@CompanySeq AND CDAC='7300000' AND KindSeq=1010735003)
       ,SUM(A.AMT)
      FROM #ProdCost A  
     WHERE A.CDAC BETWEEN '7300100' AND '7300900' 
     GROUP BY A.CDCS,A.NMCS
  
   INSERT INTO #ProdCost
    SELECT 
           M.ValueText       AS CDCS
       ,A.CDAC        AS CDAC
       ,M2.ValueText       AS NMCS
       ,A.NMAC        AS NMAC
       ,SUM(ISNULL(CR.InPutCost,0)) AS AMT 
     --  ,SUM(ISNULL(CR.ProcCost,0)) AS AMT 
      FROM KPX_TEISAcc_COA A LEFT OUTER JOIN KPX_TEISAccSub_COA B WITH(NOLOCK)
              ON A.CompanySeq=B.CompanySeq
             AND A.Seq=B.Seq 
          LEFT OUTER JOIN _TESMCProdFGoodCostResult CR WITH(NOLOCK)
              ON A.CompanySeq=CR.CompanySeq
             AND B.AccSeq=CR.CostAccSeq
          LEFT OUTER JOIN _TESMDCostKey CK WITH(NOLOCK)
              ON A.CompanySeq=CK.CompanySeq
             AND CR.CostKeySeq=CK.CostKeySeq
             AND CK.SMCostMng=5512001
          LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq,0) F
              ON A.CompanySeq=@CompanySeq
             AND CR.ItemSeq=F.ItemSeq
          LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                  ON A.CompanySeq=M.CompanySeq
                 AND F.ItemClassLSeq=M.MinorSeq
                 AND  M.Serl=1000004
          LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                  ON A.CompanySeq=M2.CompanySeq
                 AND F.ItemClassLSeq=M2.MinorSeq
                 AND M2.Serl=1000005
     WHERE A.CompanySeq=@CompanySeq
       AND A.KindSeq=1010735003
       AND A.CDAC BETWEEN '7500100' AND '7504700' 
       AND CK.CostYM=@YYMM
        AND M.ValueText<>'90'
      
            GROUP BY M.ValueText ,A.CDAC,M2.ValueText,A.NMAC
  
     INSERT INTO #ProdCost
    SELECT CDCS
       ,'7500000'
       ,A.NMCS
       ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='7500000' AND KindSeq=1010735003)
       ,SUM(A.AMT)
      FROM #ProdCost A 
     WHERE A.CDAC BETWEEN '7500100' AND '7504700' 
     GROUP BY A.CDCS,A.NMCS
  
            -- 7900000 당기총제조비용, 7930000 합 계, 7990000 당기제품제조원가 모두 동일함(7100000 재료비 + 7300000 노무비 + 7500000 경비)
     INSERT INTO #ProdCost
     SELECT CDCS
        ,'7900000'
        ,A.NMCS
        ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='7900000' AND KindSeq=1010735003)
        ,SUM(A.AMT)
      FROM #ProdCost A  
     WHERE A.CDAC  IN('7100000','7300000','7500000')
     GROUP BY A.CDCS,A.NMCS  
      INSERT INTO #ProdCost
     SELECT CDCS
        ,'7930000'
        ,A.NMCS
        ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='7930000' AND KindSeq=1010735003)
        ,SUM(A.AMT)
      FROM #ProdCost A  
     WHERE A.CDAC  IN('7100000','7300000','7500000')
     GROUP BY A.CDCS,A.NMCS  
     INSERT INTO #ProdCost
     SELECT CDCS
        ,'7990000'
        ,A.NMCS
        ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='7990000' AND KindSeq=1010735003)
        ,SUM(A.AMT)
      FROM #ProdCost A  
     WHERE A.CDAC  IN('7100000','7300000','7500000')
     GROUP BY A.CDCS,A.NMCS  
  
  
     INSERT INTO ODS_KPX_HDSLIB_MCAMPF_COA
        SELECT  @CompanySeq
      ,@YYMM
      ,AA.CDCS
      ,A.CDAC
      ,AA.NMCS
      ,A.NMAC
      ,ISNULL(B.AMT,0) AS AMT
      ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
        FROM KPX_TEISAcc_COA A  CROSS JOIN (SELECT MV.ValueText AS CDCS, MV2.ValueText AS NMCS 
               FROM _TDAUMinor M LEFT OUTER JOIN _TDAUMinorValue MV WITH(NOLOCK)
                      ON M.CompanySeq=MV.CompanySeq
                        AND M.MinorSeq=MV.MinorSeq
                        AND MV.Serl=1000004
                     LEFT OUTER JOIN _TDAUMinorValue MV2 WITH(NOLOCK)
                      ON M.CompanySeq=MV2.CompanySeq
                        AND M.MinorSeq=MV2.MinorSeq
                        AND MV2.Serl=1000005
              WHERE M.CompanySeq=@CompanySeq 
                AND M.MajorSeq=2003
                ) AA
         LEFT OUTER JOIN #ProdCost B WITH(NOLOCK)
             ON A.CompanySeq=@CompanySeq
            AND A.CDAC=B.CDAC 
            AND AA.CDCS=B.CDCS
        WHERE A.CompanySeq=@CompanySeq
         AND AA.CDCS<>'90' 
         AND A.KindSeq=1010735003
      ORDER BY AA.CDCS,A.CDAC,A.SORTID
   
    
    IF @CompanySeq =1 
    BEGIN
       INSERT INTO ODS_KPXGC_HDSLIB_BSAMPF_COA
        SELECT  YYMM,CDAC,NMAC,AMT,DTTMUP FROM ODS_KPX_HDSLIB_MCAMPF_COA WHERE CompanySeq=1 AND YYMM=@YYMM
    END
    ELSE IF @CompanySeq = 2 
       BEGIN
     INSERT INTO ODS_KPXCM_HDSLIB_BSAMPF_COA
         SELECT  YYMM,CDAC,NMAC,AMT,DTTMUP FROM ODS_KPX_HDSLIB_MCAMPF_COA WHERE CompanySeq=2 AND YYMM=@YYMM
     END
     ELSE IF @CompanySeq = 3
       BEGIN
     INSERT INTO ODS_KPXLS_HDSLIB_BSAMPF_COA
         SELECT  YYMM,CDAC,NMAC,AMT,DTTMUP FROM ODS_KPX_HDSLIB_MCAMPF_COA WHERE CompanySeq=3 AND YYMM=@YYMM
     END
    ELSE IF @CompanySeq = 4
       BEGIN
     INSERT INTO ODS_KPXHD_HDSLIB_BSAMPF_COA
         SELECT  YYMM,CDAC,NMAC,AMT,DTTMUP FROM ODS_KPX_HDSLIB_MCAMPF_COA WHERE CompanySeq=4 AND YYMM=@YYMM
     END  
  
     DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736015
       INSERT INTO KPX_EISIFProcStaus_COA
      SELECT @CompanySeq,@YYMM,1010736015,'1','',@UserSeq,GETDATE() 
  
       
 *****************************************************************************************************************/
    /* 손익계산서 업데이트 */
    DELETE FROM ODS_KPX_HDSLIB_PLAMPF_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM 
    
    IF @CompanySeq =1 
    BEGIN
        DELETE FROM ODS_KPXGC_HDSLIB_PLAMPF WHERE  YYMM=@YYMM
    END
    
    CREATE TABLE #PLAMPF(
          CDCS NVARCHAR(30)
         ,CDAC NVARCHAR(30)
         ,NMCS NVARCHAR(30)
         ,NMAC NVARCHAR(30)
         ,AMT  DECIMAL(19,5)
                 )
  
      CREATE TABLE #TBase -- 경영보고용-조직코드담는 테이블(해당 코드의 데이터가 없을시 0의 값이 넣기위함. 
     (
         CDCS NVARCHAR(30)
     ,NMCS NVARCHAR(30)
     ) 
           
  
    INSERT INTO #TBase
        SELECT B.ValueText,C.ValueText
          FROM _TDAUMinor A LEFT OUTER JOIN _TDAUMinorValue B 
              ON A.CompanySeq = B.CompanySeq
                AND A.MinorSeq = B.MinorSeq
                AND B.Serl = 1000004
             LEFT OUTER JOIN _TDAUMinorValue C 
              ON A.CompanySeq = C.CompanySeq
                AND A.MinorSeq = C.MinorSeq
                AND C.Serl = 1000005
        WHERE A.CompanySeq = @CompanySeq
          AND A.MajorSeq = 2003
       AND B.ValueText<>'90'
  
  
     -- 생산수량
     INSERT INTO #PLAMPF  
      SELECT M3.ValueText AS CDCS
         ,'010000'     AS CDAC
         ,M4.ValueText AS NMCS
         ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='010000' AND KindSeq=1010735003) AS NMAC
         ,SUM(QTIN)-SUM(QTWR)    AS AMT
        FROM ODS_KPX_HDSLIB_MFSLPF_COA A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                  ON A.CompanySeq = M.CompanySeq
                    AND A.CDITEM     = M.ValueText
                    AND M.MajorSeq = 2002
                    AND M.Serl = 2002
                 LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                  ON A.CompanySeq = M2.CompanySeq
                    AND M.MinorSeq = M2.MinorSeq
                    AND M2.Serl = 2001
                 LEFT OUTER JOIN _TDAUMinorValue M3 WITH(NOLOCK)
                  ON A.CompanySeq = M3.CompanySeq
                    AND M2.ValueSeq = M3.MinorSeq
                    AND M3.MajorSeq = 2003
                    AND M3.Serl = 1000004
                 LEFT OUTER JOIN _TDAUMinorValue M4 WITH(NOLOCK)
                  ON A.CompanySeq = M4.CompanySeq
                    AND M2.ValueSeq = M4.MinorSeq
                    AND M4.MajorSeq = 2003
                    AND M4.Serl = 1000005
        WHERE A.CompanySeq=@CompanySeq
          AND A.YYMM=@YYMM
          AND A.NMITEM LIKE '%제품%'
       GROUP BY M3.ValueText,M4.ValueText
  
     -- 생산금액
     
  
  
         INSERT INTO #PLAMPF      
       SELECT CC.CDCS,
        CC.CDAC,
        CC.NMCS,
        CC.NMAC,
        D.AMT*CC.AMT AS AMT
                 FROM 
  
      (  SELECT BB.CDCS,
        '020000' AS CDAC,
        BB.NMCS,
        (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='020000' AND KindSeq=1010735003) AS NMAC,
        --ISNULL((SUM(A.AMSL)+SUM(A.VAT))/SUM(A.QTSL),0) AS AMT
        ISNULL((SUM(A.AMSL))/SUM(A.QTSL),0) AS AMT
         FROM ODS_KPX_HDSLIB_SLTTPF_COA A LEFT OUTER JOIN ( SELECT M.ValueText AS GUBN ,M5.ValueText AS CDCS ,M6.ValueText AS NMCS
                    FROM _TDAUMinor A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                              ON A.CompanySeq=M.CompanySeq
                             AND A.MinorSeq = M.MinorSeq
                             AND M.Serl=1000001
                            JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                              ON A.CompanySeq=M2.CompanySeq
                             AND A.MinorSeq = M2.MinorSeq
                             AND M2.Serl=1000002
                            JOIN _TDAUMinorValue M3 WITH(NOLOCK)
                              ON A.CompanySeq=M3.CompanySeq
                             AND A.MinorSeq = M3.MinorSeq
                             AND M3.Serl=1000003
                             AND M3.ValueText='1'
                            JOIN _TDAUMinorValue M4 WITH(NOLOCK)
                              ON A.CompanySeq = M4.CompanySeq
                             AND M2.ValueSeq = M4.MinorSeq
                             AND M4.MajorSeq = 2002
                             AND M4.Serl = 2001
                            JOIN _TDAUMinorValue M5 WITH(NOLOCK)
                              ON A.CompanySeq = M5.CompanySeq
                             AND M4.ValueSeq = M5.MinorSeq
                             AND M5.MajorSeq = 2003
                             AND M5.Serl = 1000004
                            JOIN _TDAUMinorValue M6 WITH(NOLOCK)
                              ON A.CompanySeq = M6.CompanySeq
                             AND M4.ValueSeq = M6.MinorSeq
                             AND M6.MajorSeq = 2003
                             AND M6.Serl = 1000005
                     WHERE A.CompanySeq =@CompanySeq 
                      AND A.MajorSeq=1010705
                      AND M5.ValueText<>'90'
                      )BB ON A.CompanySeq=@CompanySeq
                      AND A.GUBN=BB.GUBN
               
      WHERE A.CompanySeq=@CompanySeq
          AND A.YYMM=@YYMM
       AND A.IDSA<>'9'
          AND A.NMBN LIKE '%제품%'
      GROUP BY BB.CDCS,BB.NMCS
      ) CC LEFT OUTER JOIN #PLAMPF D WITH(NOLOCK)
            ON CC.CDCS = D.CDCS
  
  
  
  
               -- 제품 국내
      INSERT INTO #PLAMPF  
      SELECT E.CDCS,
       '030100' AS CDAC,
       E.NMCS,
       (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='030100' AND KindSeq=1010735003) AS NMAC, 
       ISNULL(E.AMT,0)  - ISNULL(F.AMT,0) AS AMT 
     FROM
               ( SELECT BB.CDCS,
        BB.NMCS,
        --ISNULL((SUM(A.AMSL)+SUM(A.VAT)),0) AS AMT
        ISNULL(SUM(A.AMSL),0) AS AMT
         FROM ODS_KPX_HDSLIB_SLTTPF_COA A LEFT OUTER JOIN ( SELECT M.ValueText AS GUBN ,M5.ValueText AS CDCS ,M6.ValueText AS NMCS
                    FROM _TDAUMinor A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                              ON A.CompanySeq=M.CompanySeq
                             AND A.MinorSeq = M.MinorSeq
                             AND M.Serl=1000001
                            JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                              ON A.CompanySeq=M2.CompanySeq
                             AND A.MinorSeq = M2.MinorSeq
                             AND M2.Serl=1000002
                            JOIN _TDAUMinorValue M3 WITH(NOLOCK)
                              ON A.CompanySeq=M3.CompanySeq
                             AND A.MinorSeq = M3.MinorSeq
                             AND M3.Serl=1000003
                             AND M3.ValueText='1'
                            JOIN _TDAUMinorValue M4 WITH(NOLOCK)
                              ON A.CompanySeq = M4.CompanySeq
                             AND M2.ValueSeq = M4.MinorSeq
                             AND M4.MajorSeq = 2002
                             AND M4.Serl = 2001
                            JOIN _TDAUMinorValue M5 WITH(NOLOCK)
                              ON A.CompanySeq = M5.CompanySeq
                             AND M4.ValueSeq = M5.MinorSeq
                             AND M5.MajorSeq = 2003
                             AND M5.Serl = 1000004
                            JOIN _TDAUMinorValue M6 WITH(NOLOCK)
                              ON A.CompanySeq = M6.CompanySeq
                             AND M4.ValueSeq = M6.MinorSeq
                             AND M6.MajorSeq = 2003
                             AND M6.Serl = 1000005
                     WHERE A.CompanySeq =@CompanySeq 
                      AND A.MajorSeq=1010705
                      AND M5.ValueText<>'90'
                      )BB ON A.CompanySeq=@CompanySeq
                      AND A.GUBN=BB.GUBN
        WHERE A.CompanySeq=@CompanySeq
          AND A.YYMM=@YYMM
       AND A.IDSA<>'9'
          AND A.NMBN LIKE '%제품%'
      GROUP BY BB.CDCS,BB.NMCS
       ) E LEFT OUTER JOIN ODS_KPX_HDSLIB_FRAMPF_COA F 
            ON F.CompanySeq=@CompanySeq
           AND E.CDCS=F.CDCS
           AND F.YYMM=@YYMM
    
    
  
     
    
    -- 제품해외      
    INSERT INTO #PLAMPF 
           SELECT CDCS,
        '030200' AS CDAC,
         NMCS,
         (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='030200' AND KindSeq=1010735003) AS NMAC, 
         AMT AS AMT 
          FROM ODS_KPX_HDSLIB_FRAMPF_COA 
      WHERE CompanySeq = @CompanySeq
        AND YYMM=@YYMM
    
      -- 상품매출
        INSERT INTO #PLAMPF
         SELECT BB.CDCS,
             '030300' AS CDAC,
       BB.NMCS,
       (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='030300' AND KindSeq=1010735003) AS NMAC,
       --ISNULL((SUM(A.AMSL)+SUM(A.VAT)),0) AS AMT 
       ISNULL(SUM(A.AMSL),0) AS AMT
     FROM ODS_KPX_HDSLIB_SLTTPF_COA A LEFT OUTER JOIN ( SELECT M.ValueText AS GUBN ,M5.ValueText AS CDCS ,M6.ValueText AS NMCS
                  FROM _TDAUMinor A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                            ON A.CompanySeq=M.CompanySeq
                           AND A.MinorSeq = M.MinorSeq
                           AND M.Serl=1000001
                          JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                            ON A.CompanySeq=M2.CompanySeq
                           AND A.MinorSeq = M2.MinorSeq
                           AND M2.Serl=1000002
                          JOIN _TDAUMinorValue M3 WITH(NOLOCK)
                            ON A.CompanySeq=M3.CompanySeq
                           AND A.MinorSeq = M3.MinorSeq
                           AND M3.Serl=1000003
                           AND M3.ValueText='1'
                          JOIN _TDAUMinorValue M4 WITH(NOLOCK)
                            ON A.CompanySeq = M4.CompanySeq
                           AND M2.ValueSeq = M4.MinorSeq
                           AND M4.MajorSeq = 2002
                           AND M4.Serl = 2001
                          JOIN _TDAUMinorValue M5 WITH(NOLOCK)
                            ON A.CompanySeq = M5.CompanySeq
                           AND M4.ValueSeq = M5.MinorSeq
                           AND M5.MajorSeq = 2003
                           AND M5.Serl = 1000004
                          JOIN _TDAUMinorValue M6 WITH(NOLOCK)
                            ON A.CompanySeq = M6.CompanySeq
                           AND M4.ValueSeq = M6.MinorSeq
                           AND M6.MajorSeq = 2003
                           AND M6.Serl = 1000005
                   WHERE A.CompanySeq =@CompanySeq 
                  AND A.MajorSeq=1010705
                  AND M5.ValueText<>'90'
                 )BB ON A.CompanySeq=@CompanySeq
                  AND A.GUBN=BB.GUBN
        WHERE A.CompanySeq=@CompanySeq
          AND A.YYMM=@YYMM
       AND A.IDSA<>'9'
          AND A.NMBN LIKE '%상품%'
      GROUP BY BB.CDCS,BB.NMCS
  
  
  
  
  
    ---- 4110000 제품매출, 4130000 상품매출          
    ---- [세금계산서품목조회]화면 및 [수출매출품목조회]화면의 '실적부서'와 연결된 활동센터를 사용자정의코드 '(경영보고)매출집계활동센터_KPX'의 '조직코드'별로 집계          
    ---- 매출계정별로 제품매출과 상품매출을 분리시켜 집계          
    ---- 금액은 부가세를 제외한 '원화판매금액'          
  
  
  
  
  
  
  
            ---- 4100000 매출액(하위 계정들의 합계 '4110000','4130000' ) 
     -- 매출액
     INSERT INTO #PLAMPF
    SELECT CDCS
       ,'030000'
       ,A.NMCS
       ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='030000' AND KindSeq=1010735003)
       ,SUM(A.AMT)
      FROM #PLAMPF A  
     WHERE A.CDAC BETWEEN '030100' AND '030999'
     GROUP BY A.CDCS,A.NMCS
  
  
       CREATE TABLE #TMPFSData (
        ItemNo    NVARCHAR(100)
       ,ItemName   NVARCHAR(100)
       ,Spec    NVARCHAR(100)    
       ,AssetName   NVARCHAR(100)
       ,PreQty    DECIMAL(19,5)
       ,PreAmt    DECIMAL(19,5)
       ,ProdQty   DECIMAL(19,5) 
       ,ProdAmt   DECIMAL(19,5)
       ,BuyQty    DECIMAL(19,5)
       ,BuyAmt    DECIMAL(19,5)
       ,MvInQty   DECIMAL(19,5)
       ,MvInAmt   DECIMAL(19,5)
       ,EtcInQty   DECIMAL(19,5)
       ,EtcInAmt   DECIMAL(19,5)
       ,ExchangeInQty  DECIMAL(19,5)
       ,ExchangeInAmt  DECIMAL(19,5)
       ,SalesQty   DECIMAL(19,5)
       ,SalesAmt   DECIMAL(19,5)
       ,InputQty   DECIMAL(19,5)
       ,InputAmt   DECIMAL(19,5)
       ,MvOutQty   DECIMAL(19,5)
       ,MvOutAmt   DECIMAL(19,5)
       ,EtcOutQty   DECIMAL(19,5)
       ,EtcOutAmt   DECIMAL(19,5)
       ,ExchangeOutQty  DECIMAL(19,5)
       ,ExchangeOutAmt  DECIMAL(19,5)
       ,InQty    DECIMAL(19,5)
       ,OutAmt    DECIMAL(19,5)
       ,InAmt    DECIMAL(19,5)
       ,StockQty   DECIMAL(19,5)
       ,OutQty    DECIMAL(19,5)
       ,StockAmt   DECIMAL(19,5)
       ,StockQty2   DECIMAL(19,5)
       ,StockAmt2   DECIMAL(19,5)
       ,DiffQty   DECIMAL(19,5)
       ,DiffAmt   DECIMAL(19,5)
       ,UnitName   NVARCHAR(100)
       ,ItemSeq   INT
       ,CostUnitName  NVARCHAR(100)
       ,CostYMFr   NCHAR(8)
       ,CostYMTo   NCHAR(8)
       ,CostUnitKind  INT
       ,ItemKindName  NVARCHAR(100)
       ,UMItemClassSSeq INT
       ,UMItemClassMSeq INT
       ,UMItemClassLSeq INT
       ,UMItemClassSName NVARCHAR(100)
       ,UMItemClassMName NVARCHAR(100)
       ,UMItemClassLName NVARCHAR(100)
       ,Price    DECIMAL(19,5)
        )
      CREATE TABLE #TMPFSData2 (     -- 자재 정보를 받기위한 Temp Table
        ItemNo    NVARCHAR(100)
       ,ItemName   NVARCHAR(100)
       ,Spec    NVARCHAR(100)    
       ,AssetName   NVARCHAR(100)
       ,PreQty    DECIMAL(19,5)
       ,PreAmt    DECIMAL(19,5)
       ,ProdQty   DECIMAL(19,5) 
       ,ProdAmt   DECIMAL(19,5)
       ,BuyQty    DECIMAL(19,5)
       ,BuyAmt    DECIMAL(19,5)
       ,MvInQty   DECIMAL(19,5)
       ,MvInAmt   DECIMAL(19,5)
       ,EtcInQty   DECIMAL(19,5)
       ,EtcInAmt   DECIMAL(19,5)
       ,ExchangeInQty  DECIMAL(19,5)
       ,ExchangeInAmt  DECIMAL(19,5)
       ,SalesQty   DECIMAL(19,5)
       ,SalesAmt   DECIMAL(19,5)
       ,InputQty   DECIMAL(19,5)
       ,InputAmt   DECIMAL(19,5)
       ,MvOutQty   DECIMAL(19,5)
       ,MvOutAmt   DECIMAL(19,5)
       ,EtcOutQty   DECIMAL(19,5)
       ,EtcOutAmt   DECIMAL(19,5)
       ,ExchangeOutQty  DECIMAL(19,5)
       ,ExchangeOutAmt  DECIMAL(19,5)
       ,InQty    DECIMAL(19,5)
       ,OutAmt    DECIMAL(19,5)
       ,InAmt    DECIMAL(19,5)
       ,StockQty   DECIMAL(19,5)
       ,OutQty    DECIMAL(19,5)
       ,StockAmt   DECIMAL(19,5)
       ,StockQty2   DECIMAL(19,5)
       ,StockAmt2   DECIMAL(19,5)
       ,DiffQty   DECIMAL(19,5)
       ,DiffAmt   DECIMAL(19,5)
       ,UnitName   NVARCHAR(100)
       ,ItemSeq   INT
       ,CostUnitName  NVARCHAR(100)
       ,CostYMFr   NCHAR(8)
       ,CostYMTo   NCHAR(8)
       ,CostUnitKind  INT
       ,ItemKindName  NVARCHAR(100)
       ,UMItemClassSSeq INT
       ,UMItemClassMSeq INT
       ,UMItemClassLSeq INT
       ,UMItemClassSName NVARCHAR(100)
       ,UMItemClassMName NVARCHAR(100)
       ,UMItemClassLName NVARCHAR(100)
       ,Price    DECIMAL(19,5)
        )
      
     
     
     
     
     
     
     
     
     
       SELECT @SQL=''
       SELECT @SQL='_SESMZStockMonthlyAmt  @xmlDocument=N'''+'<ROOT>'
       SELECT @SQL=@SQL+'<DataBlock1>'+CHAR(10)
       SELECT @SQL=@SQL+'<WorkingTag>A</WorkingTag>'+CHAR(10)
       SELECT @SQL=@SQL+'<IDX_NO>1</IDX_NO>'+CHAR(10)
       SELECT @SQL=@SQL+'<Status>0</Status>'+CHAR(10)
       SELECT @SQL=@SQL+'<DataSeq>1</DataSeq>'+CHAR(10)
       SELECT @SQL=@SQL+'<Selected>1</Selected>'+CHAR(10)
       SELECT @SQL=@SQL+'<TABLE_NAME>DataBlock1</TABLE_NAME>'+CHAR(10)
       SELECT @SQL=@SQL+'<IsChangedMst>0</IsChangedMst>'+CHAR(10)
       SELECT @SQL=@SQL+'<SMCostMng>5512001</SMCostMng>'+CHAR(10)
       SELECT @SQL=@SQL+'<PlanYear></PlanYear>'+CHAR(10)
       SELECT @SQL=@SQL+'<RptUnit></RptUnit>'+CHAR(10)
       SELECT @SQL=@SQL+'<IsAssetType>0</IsAssetType>'+CHAR(10)
       SELECT @SQL=@SQL+'<CostUnit>0</CostUnit>'+CHAR(10)
       SELECT @SQL=@SQL+'<CostUnitName></CostUnitName>'+CHAR(10)
       SELECT @SQL=@SQL+'<CostYMFr>'+CONVERT(NVARCHAR(60),ISNULL(@YYMM,0))+'</CostYMFr>'+CHAR(10)
       SELECT @SQL=@SQL+'<CostYMTo>'+CONVERT(NVARCHAR(60),ISNULL(@YYMM,0))+'</CostYMTo>'+CHAR(10)
       SELECT @SQL=@SQL+'<AppPriceKind>5533001</AppPriceKind>'+CHAR(10)
       SELECT @SQL=@SQL+'<AssetSeq></AssetSeq>'+CHAR(10)
       SELECT @SQL=@SQL+'<AssetName></AssetName>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemSeq></ItemSeq>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemName></ItemName>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemNo></ItemNo>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemClassKind></ItemClassKind>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemClassKindName></ItemClassKindName>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemClassSeq></ItemClassSeq>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemClassName></ItemClassName>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemKind>F</ItemKind>'+CHAR(10)
       SELECT @SQL=@SQL+'</DataBlock1>'
       SELECT @SQL=@SQL+'</ROOT>'''
       SELECT @SQL=@SQL+',@xmlFlags=2,@ServiceSeq=3132,@WorkingTag=N'+''''''
       SELECT @SQL=@SQL+',@CompanySeq='+CONVERT(NVARCHAR(60),@CompanySeq)
       SELECT @SQL=@SQL+',@LanguageSeq=1,@UserSeq=1,@PgmSeq=5810'
      INSERT INTO #TMPFSData
         EXEC(@SQL)
           -- 4310100 기초제품재고액, 4310300 당기제품제조원가, 4310500 기말제품재고액, 4310700 타계정대체액
      --INSERT INTO #PLAMPF
     -- SELECT M.ValueText  AS CDCS
     --    ,'4310100'    AS CDAC
     --    ,M2.ValueText AS NMCS
     --    ,(SELECT NMAC FROM KPX_TEISAcc WHERE CompanySeq=@CompanySeq AND CDAC='4310100' AND KindSeq=1010735003)
     --    ,SUM(ISNULL(A.PreAmt,0))
     --   FROM #TMPFSData A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
     --          ON M.CompanySeq = @CompanySeq
     --         AND A.UMItemClassLSeq=M.MinorSeq
     --         AND M.Serl=1000004
     --      LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
     --          ON M2.CompanySeq = @CompanySeq
     --         AND A.UMItemClassLSeq=M2.MinorSeq
     --         AND M2.Serl=1000005
     -- GROUP BY M.ValueText,M2.ValueText 
     -- UNION ALL
     -- SELECT M.ValueText  AS CDCS
     --   ,'4310300'    AS CDAC
     --   ,M2.ValueText AS NMCS
     --   ,(SELECT NMAC FROM KPX_TEISAcc WHERE CompanySeq=@CompanySeq AND CDAC='4310300' AND KindSeq=1010735003)
     --   ,SUM(ISNULL(A.ProdAmt,0))
     -- FROM #TMPFSData A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
     --          ON M.CompanySeq = @CompanySeq
     --         AND A.UMItemClassLSeq=M.MinorSeq
     --         AND M.Serl=1000004
     --      LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
     --          ON M2.CompanySeq = @CompanySeq
     --         AND A.UMItemClassLSeq=M2.MinorSeq
     --         AND M2.Serl=1000005
     --      LEFT OUTER JOIN _TDAItem ITM WITH(NOLOCK)
     --          ON ITM.CompanySeq=@CompanySeq
     --         AND A.ItemSeq=ITM.ItemSeq
     -- WHERE ITM.AssetSeq=1
     -- GROUP BY M.ValueText,M2.ValueText
     -- UNION ALL
     -- SELECT M.ValueText  AS CDCS
     --   ,'4310500'    AS CDAC
     --   ,M2.ValueText AS NMCS
     --   ,(SELECT NMAC FROM KPX_TEISAcc WHERE CompanySeq=@CompanySeq AND CDAC='4310500' AND KindSeq=1010735003)
     --   ,SUM(ISNULL(A.StockAmt,0))
     -- FROM #TMPFSData A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
     --          ON M.CompanySeq = @CompanySeq
     --         AND A.UMItemClassLSeq=M.MinorSeq
     --         AND M.Serl=1000004
     --      LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
     --          ON M2.CompanySeq = @CompanySeq
     --         AND A.UMItemClassLSeq=M2.MinorSeq
     --         AND M2.Serl=1000005
     -- GROUP BY M.ValueText,M2.ValueText
     -- UNION ALL
     -- SELECT M.ValueText  AS CDCS
     --   ,'4310700'    AS CDAC
     --   ,M2.ValueText AS NMCS
     --   ,(SELECT NMAC FROM KPX_TEISAcc WHERE CompanySeq=@CompanySeq AND CDAC='4310700' AND KindSeq=1010735003)
     --   ,SUM(ISNULL(A.EtcOutAmt,0))
     --  FROM #TMPFSData A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
     --         ON M.CompanySeq = @CompanySeq
     --           AND A.UMItemClassLSeq=M.MinorSeq
     --           AND M.Serl=1000004
     --        LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
     --         ON M2.CompanySeq = @CompanySeq
     --           AND A.UMItemClassLSeq=M2.MinorSeq
     --           AND M2.Serl=1000005
     -- GROUP BY M.ValueText,M2.ValueText
      --  4330100 기초상품재고액, 4330300 당기상품매입액, 4330310 타계정대체입, 4330500 기말상품재고액, 4330700 타계정대체액 
  
  
  
  
  
  
       SELECT @SQL=''
       SELECT @SQL='_SESMZStockMonthlyAmt  @xmlDocument=N'''+'<ROOT>'
       SELECT @SQL=@SQL+'<DataBlock1>'+CHAR(10)
       SELECT @SQL=@SQL+'<WorkingTag>A</WorkingTag>'+CHAR(10)
       SELECT @SQL=@SQL+'<IDX_NO>1</IDX_NO>'+CHAR(10)
       SELECT @SQL=@SQL+'<Status>0</Status>'+CHAR(10)
       SELECT @SQL=@SQL+'<DataSeq>1</DataSeq>'+CHAR(10)
       SELECT @SQL=@SQL+'<Selected>1</Selected>'+CHAR(10)
       SELECT @SQL=@SQL+'<TABLE_NAME>DataBlock1</TABLE_NAME>'+CHAR(10)
       SELECT @SQL=@SQL+'<IsChangedMst>0</IsChangedMst>'+CHAR(10)
       SELECT @SQL=@SQL+'<SMCostMng>5512001</SMCostMng>'+CHAR(10)
       SELECT @SQL=@SQL+'<PlanYear></PlanYear>'+CHAR(10)
       SELECT @SQL=@SQL+'<RptUnit></RptUnit>'+CHAR(10)
       SELECT @SQL=@SQL+'<IsAssetType>0</IsAssetType>'+CHAR(10)
       SELECT @SQL=@SQL+'<CostUnit>0</CostUnit>'+CHAR(10)
       SELECT @SQL=@SQL+'<CostUnitName></CostUnitName>'+CHAR(10)
       SELECT @SQL=@SQL+'<CostYMFr>'+CONVERT(NVARCHAR(60),ISNULL(@YYMM,0))+'</CostYMFr>'+CHAR(10)
       SELECT @SQL=@SQL+'<CostYMTo>'+CONVERT(NVARCHAR(60),ISNULL(@YYMM,0))+'</CostYMTo>'+CHAR(10)
       SELECT @SQL=@SQL+'<AppPriceKind>5533001</AppPriceKind>'+CHAR(10)
       SELECT @SQL=@SQL+'<AssetSeq></AssetSeq>'+CHAR(10)
       SELECT @SQL=@SQL+'<AssetName></AssetName>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemSeq></ItemSeq>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemName></ItemName>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemNo></ItemNo>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemClassKind></ItemClassKind>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemClassKindName></ItemClassKindName>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemClassSeq></ItemClassSeq>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemClassName></ItemClassName>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemKind>G</ItemKind>'+CHAR(10)
       SELECT @SQL=@SQL+'</DataBlock1>'
       SELECT @SQL=@SQL+'</ROOT>'''
       SELECT @SQL=@SQL+',@xmlFlags=2,@ServiceSeq=3132,@WorkingTag=N'+''''''
       SELECT @SQL=@SQL+',@CompanySeq='+CONVERT(NVARCHAR(60),@CompanySeq)
       SELECT @SQL=@SQL+',@LanguageSeq=1,@UserSeq=1,@PgmSeq=5810'
      INSERT INTO #TMPFSData
         EXEC(@SQL)
     
         -- 재고증감차
        INSERT INTO #PLAMPF
      SELECT M.ValueText  AS CDCS
            ,'040100'     AS CDAC
         ,M2.ValueText AS NMCS
         ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='040100' AND KindSeq=1010735003) AS NMAC
         ,SUM(ISNULL(A.PreAmt,0))-SUM(ISNULL(A.StockAmt,0))+SUM(ISNULL(A.EtcInAmt,0))-SUM(ISNULL(A.EtcOutAmt,0))
        FROM #TMPFSData A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
               ON M.CompanySeq = @CompanySeq
              AND A.UMItemClassLSeq=M.MinorSeq
              AND M.Serl=1000004
           LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
               ON M2.CompanySeq = @CompanySeq
              AND A.UMItemClassLSeq=M2.MinorSeq
              AND M2.Serl=1000005
      WHERE M.ValueText<>'90'
      GROUP BY M.ValueText,M2.ValueText 
  
  
        SELECT @SQL=''
       SELECT @SQL='_SESMZStockMonthlyAmt  @xmlDocument=N'''+'<ROOT>'
       SELECT @SQL=@SQL+'<DataBlock1>'+CHAR(10)
       SELECT @SQL=@SQL+'<WorkingTag>A</WorkingTag>'+CHAR(10)
       SELECT @SQL=@SQL+'<IDX_NO>1</IDX_NO>'+CHAR(10)
       SELECT @SQL=@SQL+'<Status>0</Status>'+CHAR(10)
       SELECT @SQL=@SQL+'<DataSeq>1</DataSeq>'+CHAR(10)
       SELECT @SQL=@SQL+'<Selected>1</Selected>'+CHAR(10)
       SELECT @SQL=@SQL+'<TABLE_NAME>DataBlock1</TABLE_NAME>'+CHAR(10)
       SELECT @SQL=@SQL+'<IsChangedMst>0</IsChangedMst>'+CHAR(10)
       SELECT @SQL=@SQL+'<SMCostMng>5512001</SMCostMng>'+CHAR(10)
       SELECT @SQL=@SQL+'<PlanYear></PlanYear>'+CHAR(10)
       SELECT @SQL=@SQL+'<RptUnit></RptUnit>'+CHAR(10)
       SELECT @SQL=@SQL+'<IsAssetType>0</IsAssetType>'+CHAR(10)
       SELECT @SQL=@SQL+'<CostUnit>0</CostUnit>'+CHAR(10)
       SELECT @SQL=@SQL+'<CostUnitName></CostUnitName>'+CHAR(10)
       SELECT @SQL=@SQL+'<CostYMFr>'+CONVERT(NVARCHAR(60),ISNULL(@YYMM,0))+'</CostYMFr>'+CHAR(10)
       SELECT @SQL=@SQL+'<CostYMTo>'+CONVERT(NVARCHAR(60),ISNULL(@YYMM,0))+'</CostYMTo>'+CHAR(10)
       SELECT @SQL=@SQL+'<AppPriceKind>5533001</AppPriceKind>'+CHAR(10)
       SELECT @SQL=@SQL+'<AssetSeq></AssetSeq>'+CHAR(10)
       SELECT @SQL=@SQL+'<AssetName></AssetName>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemSeq></ItemSeq>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemName></ItemName>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemNo></ItemNo>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemClassKind></ItemClassKind>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemClassKindName></ItemClassKindName>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemClassSeq></ItemClassSeq>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemClassName></ItemClassName>'+CHAR(10)
       SELECT @SQL=@SQL+'<ItemKind>M</ItemKind>'+CHAR(10)
       SELECT @SQL=@SQL+'</DataBlock1>'
       SELECT @SQL=@SQL+'</ROOT>'''
       SELECT @SQL=@SQL+',@xmlFlags=2,@ServiceSeq=3132,@WorkingTag=N'+''''''
       SELECT @SQL=@SQL+',@CompanySeq='+CONVERT(NVARCHAR(60),@CompanySeq)
       SELECT @SQL=@SQL+',@LanguageSeq=1,@UserSeq=1,@PgmSeq=5810'
  
     INSERT INTO #TMPFSData2
            EXEC(@SQL)
  
  
    
  
  
  
     --SELECT M.ValueText  AS CDCS
     --    ,M2.ValueText AS NMCS
     --    ,SUM(ISNULL(A.PreAmt,0))
     --   FROM #TMPFSData A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
     --          ON M.CompanySeq = @CompanySeq
     --         AND A.UMItemClassLSeq=M.MinorSeq
     --         AND M.Serl=1000004
     --      LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
     --          ON M2.CompanySeq = @CompanySeq
     --         AND A.UMItemClassLSeq=M2.MinorSeq
     --         AND M2.Serl=1000005
     -- GROUP BY M.ValueText,M2.ValueText 
  
  
  
  
  
  
  
  
     --INSERT INTO #PLAMPF
     -- SELECT M.ValueText  AS CDCS
     --    ,'4330100'    AS CDAC
     --    ,M2.ValueText AS NMCS
     --    ,(SELECT NMAC FROM KPX_TEISAcc WHERE CompanySeq=@CompanySeq AND CDAC='4330100' AND KindSeq=1010735003)
     --    ,SUM(ISNULL(A.PreAmt,0))
     --   FROM #TMPFSData A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
     --          ON M.CompanySeq = @CompanySeq
     --         AND A.UMItemClassLSeq=M.MinorSeq
     --         AND M.Serl=1000004
     --      LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
     --          ON M2.CompanySeq = @CompanySeq
     --         AND A.UMItemClassLSeq=M2.MinorSeq
     --         AND M2.Serl=1000005
     -- GROUP BY M.ValueText,M2.ValueText 
     -- UNION ALL
     -- SELECT M.ValueText  AS CDCS
     --   ,'4330300'    AS CDAC
     --   ,M2.ValueText AS NMCS
     --   ,(SELECT NMAC FROM KPX_TEISAcc WHERE CompanySeq=@CompanySeq AND CDAC='4330300' AND KindSeq=1010735003)
     --   ,SUM(ISNULL(A.BuyAmt,0))
     -- FROM #TMPFSData A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
     --          ON M.CompanySeq = @CompanySeq
     --         AND A.UMItemClassLSeq=M.MinorSeq
     --         AND M.Serl=1000004
     --      LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
     --          ON M2.CompanySeq = @CompanySeq
     --         AND A.UMItemClassLSeq=M2.MinorSeq
     --         AND M2.Serl=1000005
     -- GROUP BY M.ValueText,M2.ValueText
     -- UNION ALL
     -- SELECT M.ValueText  AS CDCS
     --   ,'4330310'    AS CDAC
     --   ,M2.ValueText AS NMCS
     --   ,(SELECT NMAC FROM KPX_TEISAcc WHERE CompanySeq=@CompanySeq AND CDAC='4330310' AND KindSeq=1010735003)
     --   ,SUM(ISNULL(A.EtcInAmt,0))
     -- FROM #TMPFSData A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
     --          ON M.CompanySeq = @CompanySeq
     --         AND A.UMItemClassLSeq=M.MinorSeq
     --         AND M.Serl=1000004
     --      LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
     --          ON M2.CompanySeq = @CompanySeq
     --         AND A.UMItemClassLSeq=M2.MinorSeq
     --         AND M2.Serl=1000005
     -- GROUP BY M.ValueText,M2.ValueText
     -- UNION ALL
     -- SELECT M.ValueText  AS CDCS
     --   ,'4330500'    AS CDAC
     --   ,M2.ValueText AS NMCS
     --   ,(SELECT NMAC FROM KPX_TEISAcc WHERE CompanySeq=@CompanySeq AND CDAC='4330500' AND KindSeq=1010735003)
     --   ,SUM(ISNULL(A.StockAmt,0))
     --  FROM #TMPFSData A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
     --         ON M.CompanySeq = @CompanySeq
     --           AND A.UMItemClassLSeq=M.MinorSeq
     --           AND M.Serl=1000004
     --        LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
     --         ON M2.CompanySeq = @CompanySeq
     --           AND A.UMItemClassLSeq=M2.MinorSeq
     --           AND M2.Serl=1000005
     -- GROUP BY M.ValueText,M2.ValueText
     -- UNION ALL
     -- SELECT M.ValueText  AS CDCS
     --   ,'4330700'    AS CDAC
     --   ,M2.ValueText AS NMCS
     --   ,(SELECT NMAC FROM KPX_TEISAcc WHERE CompanySeq=@CompanySeq AND CDAC='4330700' AND KindSeq=1010735003)
     --   ,SUM(ISNULL(A.EtcOutAmt,0))
     --  FROM #TMPFSData A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
     --         ON M.CompanySeq = @CompanySeq
     --           AND A.UMItemClassLSeq=M.MinorSeq
     --           AND M.Serl=1000004
     --        LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
     --         ON M2.CompanySeq = @CompanySeq
     --           AND A.UMItemClassLSeq=M2.MinorSeq
     --           AND M2.Serl=1000005
     -- GROUP BY M.ValueText,M2.ValueText 
  
  
    UPDATE #PLAMPF  -- 자재재고금액 상세조회의 판매원가를 품목대분류 EOA(10)하여 금액을 더함. 
       SET  AMT= AMT+(SELECT SUM(SalesAmt) FROM #TMPFSData2)
      WHERE CDAC='040100'
        AND CDCS='10'
  
  
     --     재료비 = 재료비(원가) - 관세등환급액(손익)
      INSERT INTO #PLAMPF
     SELECT CC.CDCS
        ,'040200' AS CDAC
        ,CC.NMCS  AS NMCS
        ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='040200' AND KindSeq=1010735003) AS NMAC
        ,SUM(AMT) AS AMT
      FROM 
       (
       SELECT M.ValueText        AS CDCS
       ,M2.ValueText    AS NMCS
       ,SUM(ISNULL(Amt,0)) AS AMT
      FROM _TESMCProdFMatInput A LEFT OUTER JOIN _TDAItem ITM WITH(NOLOCK)
                ON A.CompanySeq=ITM.CompanySeq
                AND A.MatItemSeq=ITM.ItemSeq
                --AND ITM.AssetSeq=4
             LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq,0) B
                ON A.CompanySeq=@CompanySeq
                AND A.ItemSeq=B.ItemSeq
             LEFT OUTER JOIN _TESMDCostKey CK WITH(NOLOCK)
                ON A.CompanySeq=CK.CompanySeq
                AND A.CostKeySeq=CK.CostKeySeq
                AND CK.SMCostMng=5512001
             LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                ON A.CompanySeq=M.CompanySeq
                AND B.ItemClassLSeq=M.MinorSeq
                AND M.Serl=1000004
             LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                ON A.CompanySeq=M2.CompanySeq
                AND B.ItemClassLSeq=M2.MinorSeq
                AND M2.Serl=1000005
             LEFT OUTER JOIN _TDAItemAsset AT WITH(NOLOCK)
                ON A.CompanySeq = AT.CompanySeq
                AND ITM.AssetSeq = AT.AssetSeq
      WHERE A.CompanySeq=@CompanySeq
      AND CK.CostYM=@YYMM
      AND M.ValueText<>'90'
      AND AT.SMAssetGrp=6008006
     GROUP BY M.ValueText ,M2.ValueText
     UNION ALL
     SELECT    CDCS 
        ,NMCS
        ,SUM(AMT) AS AMT
      FROM
       (
        SELECT 
            CASE WHEN ISNULL(R.AccUnit,0) =1 THEN '10' ELSE AA.CDCS END AS CDCS
           ,AA.NMCS           AS NMCS
           ,CASE WHEN B.Calc = '-' THEN -1 * ISNULL(R.CrAmt,0) ELSE ISNULL(R.CrAmt,0) END AS AMT
          FROM KPX_TEISAcc_COA A LEFT OUTER JOIN KPX_TEISAccSub_COA B WITH(NOLOCK)
                  ON A.CompanySeq=B.CompanySeq
                 AND A.Seq=B.Seq 
              LEFT OUTER JOIN _TESMBAccount AC WITH(NOLOCK)
                  ON A.CompanySeq=AC.CompanySeq
                 AND B.AccSeq=AC.CostAccSeq
              LEFT OUTER JOIN _TACSlipRow R WITH(NOLOCK)
                  ON A.CompanySeq=R.CompanySeq
                 AND AC.AccSeq=R.AccSeq
               LEFT OUTER JOIN (SELECT M.CompanySeq,Biz.AccUnit AS AccUnit ,MV2.ValueText AS CDCS ,MV3.ValueText AS NMCS
                  FROM _TDAUMinor M LEFT OUTER JOIN _TDAUMinorValue MV WITH(NOLOCK)
                            ON M.CompanySeq=MV.CompanySeq
                           AND M.MinorSeq=MV.MinorSeq
                           AND MV.Serl=1000001
                        LEFT OUTER JOIN _TDAUMinorValue MV2 WITH(NOLOCK)
                            ON M.CompanySeq=MV2.CompanySeq
                           AND M.MinorSeq=MV2.MinorSeq
                           AND MV2.Serl=1000004
                        LEFT OUTER JOIN _TDAUMinorValue MV3 WITH(NOLOCK)
                           ON M.CompanySeq=MV3.CompanySeq
                           AND M.MinorSeq=MV3.MinorSeq
                           AND MV3.Serl=1000005
                        LEFT OUTER JOIN _TDABizUnit Biz WITH(NOLOCK)
                            ON M.CompanySeq=Biz.CompanySeq
                           AND MV.ValueSeq=Biz.BizUnit
                   WHERE M.CompanySeq=@CompanySeq
                     AND M.MajorSeq =2003
                  )AA ON A.CompanySeq = AA.CompanySeq 
                     AND R.AccUnit=AA.AccUNit
           
         WHERE A.CompanySeq=@CompanySeq
           AND R.AccDate BETWEEN @YYMM+'01' AND @YYMM+'31'
           AND A.CDAC='040200' 
       )BB 
      GROUP BY  CDCS
         ,NMCS
      ) CC   
      GROUP BY CC.CDCS,CC.NMCS
  
  
  
    SELECT T.CDCS
     ,T.CDAC
     ,T.NMCS
     ,T.NMAC
     ,SUM(AMT) AS AMT
      
     INTO #TESMResult
     FROM 
        (
         SELECT 
           M.ValueText       AS CDCS
          ,A.CDAC        AS CDAC
          ,M2.ValueText       AS NMCS
          ,A.NMAC        AS NMAC
          ,CASE WHEN B.Calc = '-' THEN -1*ISNULL(CR.InPutCost,0) ELSE  ISNULL(CR.InPutCost,0)  END AS AMT 
         FROM KPX_TEISAcc_COA A LEFT OUTER JOIN KPX_TEISAccSub_COA B WITH(NOLOCK)
                 ON A.CompanySeq=B.CompanySeq
                AND A.Seq=B.Seq 
             LEFT OUTER JOIN _TESMCProdFGoodCostResult CR WITH(NOLOCK)
                 ON A.CompanySeq=CR.CompanySeq
                AND B.AccSeq=CR.CostAccSeq
             LEFT OUTER JOIN _TESMDCostKey CK WITH(NOLOCK)
                 ON A.CompanySeq=CK.CompanySeq
                AND CR.CostKeySeq=CK.CostKeySeq
                AND CK.SMCostMng=5512001
             LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq,0) F
                 ON A.CompanySeq=@CompanySeq
                AND CR.ItemSeq=F.ItemSeq
             LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
                     ON A.CompanySeq=M.CompanySeq
                    AND F.ItemClassLSeq=M.MinorSeq
                    AND M.Serl=1000004
             LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
                     ON A.CompanySeq=M2.CompanySeq
                    AND F.ItemClassLSeq=M2.MinorSeq
                    AND M2.Serl=1000005
        WHERE A.CompanySeq=@CompanySeq
          AND A.KindSeq=1010735003
          AND CK.CostYM=@YYMM
          AND M.ValueText<>'90'
       
      UNION ALL
        SELECT 
           AA.CDCS 
          ,A.CDAC        AS CDAC
          ,AA.NMCS       AS NMCS
          ,A.NMAC        AS NMAC
          ,CASE WHEN B.Calc = '-' THEN -1 * ISNULL(AC.Amt,0)  ELSE  ISNULL(AC.Amt,0) END       AS AMT
         FROM KPX_TEISAcc_COA A LEFT OUTER JOIN KPX_TEISAccSub_COA B WITH(NOLOCK)
                 ON A.CompanySeq=B.CompanySeq
                 AND A.Seq=B.Seq 
              LEFT OUTER JOIN _TESMCprofDirCCtrTgtAmt AC WITH(NOLOCK)
                 ON A.CompanySeq=AC.CompanySeq
                 AND B.AccSeq=AC.CostAccSeq
              LEFT OUTER JOIN _TESMDCostKey CK WITH(NOLOCK)
                 ON A.CompanySeq=CK.CompanySeq
                AND AC.CostKeySeq=CK.CostKeySeq
                AND CK.SMCostMng=5512001
              LEFT OUTER JOIN (SELECT M.CompanySeq,MV.ValueSeq AS CCtrSeq ,MV2.ValueText AS CDCS ,MV3.ValueText AS NMCS
                  FROM _TDAUMinor M LEFT OUTER JOIN _TDAUMinorValue MV WITH(NOLOCK)
                          ON M.CompanySeq=MV.CompanySeq
                          AND M.MinorSeq=MV.MinorSeq
                          AND MV.Serl=1000001
                       LEFT OUTER JOIN _TDAUMinorValue MV2 WITH(NOLOCK)
                          ON M.CompanySeq=MV2.CompanySeq
                          AND M.MinorSeq=MV2.MinorSeq
                          AND MV2.Serl=1000002
                       LEFT OUTER JOIN _TDAUMinorValue MV3 WITH(NOLOCK)
                          ON M.CompanySeq=MV3.CompanySeq
                          AND M.MinorSeq=MV3.MinorSeq
                          AND MV3.Serl=1000003
                   WHERE M.CompanySeq=@CompanySeq
                   AND M.MajorSeq =1010748
                  )AA ON A.CompanySeq = AA.CompanySeq 
                   AND AC.SendCCtrSeq=CCtrSeq
                 
           
         WHERE A.CompanySeq=@CompanySeq
         AND CK.CostYM = @YYMM
       ) T
     GROUP BY T.CDCS
      ,T.CDAC
      ,T.NMCS
      ,T.NMAC
  
   
    INSERT INTO #PLAMPF
          SELECT * FROM #TESMResult
  
  
      --  상품매입 = 당기상품매입액+타계정대체입-관세등급환급액(손익)
        INSERT INTO #PLAMPF
     SELECT T.CDCS    AS CDCS
         ,'040900' AS CDAC
         ,T.NMCS   AS NMCS
         ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='040900' AND KindSeq=1010735003) AS NMAC
         ,SUM(AMT) AS AMT
     FROM 
     ( 
      SELECT M.ValueText  AS CDCS
         ,M2.ValueText AS NMCS
         ,SUM(ISNULL(A.BuyAmt,0))+SUM(ISNULL(A.EtcInAmt,0)) AS AMT
        FROM #TMPFSData A LEFT OUTER JOIN _TDAUMinorValue M WITH(NOLOCK)
               ON M.CompanySeq = @CompanySeq
              AND A.UMItemClassLSeq=M.MinorSeq
              AND M.Serl=1000004
           LEFT OUTER JOIN _TDAUMinorValue M2 WITH(NOLOCK)
               ON M2.CompanySeq = @CompanySeq
              AND A.UMItemClassLSeq=M2.MinorSeq
              AND M2.Serl=1000005
      WHERE M.ValueText<>'90'
        AND A.AssetName LIKE '%상품%'
      GROUP BY M.ValueText,M2.ValueText 
     UNION ALL
              SELECT    CDCS 
        ,NMCS
        ,SUM(AMT) AS AMT
      FROM
       (
        SELECT 
            CASE WHEN ISNULL(R.AccUnit,0) =1 THEN '10' ELSE AA.CDCS END AS CDCS
           ,AA.NMCS           AS NMCS
           ,CASE WHEN B.Calc = '-' THEN -1 * ISNULL(R.CrAmt,0) ELSE ISNULL(R.CrAmt,0) END AS AMT
          FROM KPX_TEISAcc_COA A LEFT OUTER JOIN KPX_TEISAccSub_COA B WITH(NOLOCK)
                  ON A.CompanySeq=B.CompanySeq
                 AND A.Seq=B.Seq 
              LEFT OUTER JOIN _TESMBAccount AC WITH(NOLOCK)
                  ON A.CompanySeq=AC.CompanySeq
                 AND B.AccSeq=AC.CostAccSeq
              LEFT OUTER JOIN _TACSlipRow R WITH(NOLOCK)
                  ON A.CompanySeq=R.CompanySeq
                 AND AC.AccSeq=R.AccSeq
              LEFT OUTER JOIN (SELECT M.CompanySeq,Biz.AccUnit AS AccUnit ,MV2.ValueText AS CDCS ,MV3.ValueText AS NMCS
                  FROM _TDAUMinor M LEFT OUTER JOIN _TDAUMinorValue MV WITH(NOLOCK)
                            ON M.CompanySeq=MV.CompanySeq
                           AND M.MinorSeq=MV.MinorSeq
                           AND MV.Serl=1000001
                        LEFT OUTER JOIN _TDAUMinorValue MV2 WITH(NOLOCK)
                            ON M.CompanySeq=MV2.CompanySeq
                           AND M.MinorSeq=MV2.MinorSeq
                           AND MV2.Serl=1000004
                        LEFT OUTER JOIN _TDAUMinorValue MV3 WITH(NOLOCK)
                            ON M.CompanySeq=MV3.CompanySeq
                           AND M.MinorSeq=MV3.MinorSeq
                           AND MV3.Serl=1000005
                        LEFT OUTER JOIN _TDABizUnit Biz WITH(NOLOCK)
                            ON M.CompanySeq=Biz.CompanySeq
                           AND MV.ValueSeq=Biz.BizUnit
                   WHERE M.CompanySeq=@CompanySeq
                     AND M.MajorSeq =2003
                  )AA ON A.CompanySeq = AA.CompanySeq 
                     AND R.AccUnit=AA.AccUNit
           
         WHERE A.CompanySeq=@CompanySeq
           AND R.AccDate BETWEEN @YYMM+'01' AND @YYMM+'31'
           AND A.CDAC='040200' 
       )BB 
    GROUP BY  CDCS
         ,NMCS
     ) T
     GROUP BY  T.CDCS 
        ,T.NMCS
      -- 변동비
     INSERT INTO #PLAMPF
    SELECT CDCS
       ,'040000'
       ,A.NMCS
       ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='040000' AND KindSeq=1010735003)
       ,SUM(A.AMT)
      FROM #PLAMPF A  
     WHERE A.CDAC BETWEEN '040100' AND '040999'
     GROUP BY A.CDCS,A.NMCS
  
        -- 한계이익
        INSERT INTO #PLAMPF
        SELECT A.CDCS
      ,'050000' AS CDAC 
      ,A.NMCS
      ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='050000' AND KindSeq=1010735003) AS NMAC
      ,ISNULL(B.AMT,0)-ISNULL(C.AMT,0) AS AMT
       FROM #TBase A LEFT OUTER JOIN (SELECT CDCS,AMT
             FROM #PLAMPF
            WHERE CDAC='030000'
             )  B ON A.CDCS = B.CDCS
       LEFT OUTER JOIN (SELECT CDCS,AMT
             FROM #PLAMPF
            WHERE CDAC='040000'
             ) C ON A.CDCS = C.CDCS
      
  
    -- 노무비
     INSERT INTO #PLAMPF
    SELECT CDCS
       ,'060100'
       ,A.NMCS
       ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='060100' AND KindSeq=1010735003)
       ,SUM(A.AMT)
      FROM #PLAMPF A  
     WHERE A.CDAC BETWEEN '060101' AND '060199'
     GROUP BY A.CDCS,A.NMCS
  
      -- 인건비
     INSERT INTO #PLAMPF
    SELECT CDCS
       ,'060200'
       ,A.NMCS
       ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='060200' AND KindSeq=1010735003)
       ,SUM(A.AMT)
      FROM #PLAMPF A  
     WHERE A.CDAC BETWEEN '060201' AND '060299'
     GROUP BY A.CDCS,A.NMCS
  
   
   -- 고정비
   
    
     INSERT INTO #PLAMPF 
    SELECT CDCS
       ,'060000'
       ,A.NMCS
       ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='060000' AND KindSeq=1010735003)
       ,SUM(A.AMT)
      FROM #PLAMPF A  LEFT OUTER JOIN KPX_TEISAcc_COA B 
              ON B.CompanySeq=@CompanySeq
             AND A.CDAC=B.CDAC
             AND B.KindSeq=1010735003
     WHERE (B.CDACHG ='060000') 
     GROUP BY A.CDCS,A.NMCS 
       -- 영업이익
        INSERT INTO #PLAMPF
       SELECT A.CDCS
        ,'070000' AS CDAC 
        ,A.NMCS
        ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='070000' AND KindSeq=1010735003) AS NMAC
        ,ISNULL(B.AMT,0)-ISNULL(C.AMT,0) AS AMT
      FROM #TBase A LEFT OUTER JOIN (SELECT CDCS,AMT
               FROM #PLAMPF
              WHERE CDAC='050000'
               )  B ON A.CDCS = B.CDCS
         LEFT OUTER JOIN (SELECT CDCS,AMT
               FROM #PLAMPF
              WHERE CDAC='060000'
               ) C ON A.CDCS = C.CDCS
  
      -- 영업외수익
     INSERT INTO #PLAMPF
    SELECT CDCS
       ,'080000'
       ,A.NMCS
       ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='080000' AND KindSeq=1010735003)
       ,SUM(A.AMT)
      FROM #PLAMPF A  
     WHERE A.CDAC BETWEEN '080100' AND '080999'
     GROUP BY A.CDCS,A.NMCS 
  
   -- 영업외비용
     INSERT INTO #PLAMPF
    SELECT CDCS
       ,'090000'
       ,A.NMCS
       ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='090000' AND KindSeq=1010735003)
       ,SUM(A.AMT)
      FROM #PLAMPF A  
     WHERE A.CDAC BETWEEN '090100' AND '090999'
     GROUP BY A.CDCS,A.NMCS
  
   -- 세전이익
        INSERT INTO #PLAMPF
       SELECT A.CDCS
        ,'100000' AS CDAC 
        ,A.NMCS
        ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='100000' AND KindSeq=1010735003) AS NMAC
        ,(ISNULL(B.AMT,0)+ISNULL(C.AMT,0)) - ISNULL(D.AMT,0) AS AMT
      FROM #TBase A LEFT OUTER JOIN (SELECT CDCS,AMT
               FROM #PLAMPF
              WHERE CDAC='070000'
               )  B ON A.CDCS = B.CDCS
         LEFT OUTER JOIN (SELECT CDCS,AMT
               FROM #PLAMPF
              WHERE CDAC='080000'
               ) C ON A.CDCS = C.CDCS
           LEFT OUTER JOIN (SELECT CDCS,AMT
               FROM #PLAMPF
              WHERE CDAC='090000'
               ) D ON A.CDCS = D.CDCS
  
  
     DECLARE @CompanyRate  DECIMAL(19,5) -- 법인세율
        ,@ResRate      DECIMAL(19,5) -- 주민세율
  
    
     SELECT  @CompanyRate = ISNULL(B.ValueText,0),
     @ResRate     = ISNULL(C.ValueText,0)
      FROM _TDAUMinorValue A LEFT OUTER JOIN _TDAUMinorValue B WITH(NOLOCK)
            ON A.CompanySeq = B.CompanySeq
           AND A.MinorSeq=B.MinorSeq
           AND B.Serl=1000002
        LEFT OUTER JOIN _TDAUMinorValue C WITH(NOLOCK)
            ON A.CompanySeq = C.CompanySeq
           AND A.MinorSeq=C.MinorSeq
           AND C.Serl=1000003          
  WHERE A.CompanySeq=@CompanySeq
    AND A.MajorSeq=1010690
    AND A.Serl=1000001
    AND A.ValueText=LEFT(@YYMM,4)
  
    -- 법인세비용
     INSERT INTO #PLAMPF
    SELECT CDCS
       ,'110000'
       ,A.NMCS
       ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='110000' AND KindSeq=1010735003)
       ,(ISNULL(A.AMT,0)*@CompanyRate)+(ISNULL(A.AMT,0)*@CompanyRate)*@ResRate    -- ((세전이익*법인세율)+(세전이익*법인세율))*주민세율
      FROM #PLAMPF A  
     WHERE A.CDAC = '100000'
    -- 당기순이익
     INSERT INTO #PLAMPF
       SELECT A.CDCS
        ,'120000' AS CDAC 
        ,A.NMCS
        ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='120000' AND KindSeq=1010735003) AS NMAC
        ,(ISNULL(B.AMT,0)-ISNULL(C.AMT,0)) AS AMT
      FROM #TBase A LEFT OUTER JOIN (SELECT CDCS,AMT
               FROM #PLAMPF
              WHERE CDAC='100000'
               )  B ON A.CDCS = B.CDCS
         LEFT OUTER JOIN (SELECT CDCS,AMT
               FROM #PLAMPF
              WHERE CDAC='110000'
               ) C ON A.CDCS = C.CDCS
        
   
      INSERT INTO ODS_KPX_HDSLIB_PLAMPF_COA
        SELECT  @CompanySeq
      ,@YYMM
      ,AA.CDCS
      ,A.CDAC
      ,AA.NMCS
      ,A.NMAC
      ,ISNULL(B.AMT,0) AS AMT
      ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
        FROM KPX_TEISAcc_COA A  CROSS JOIN (SELECT MV.ValueText AS CDCS, MV2.ValueText AS NMCS 
                   FROM _TDAUMinor M LEFT OUTER JOIN _TDAUMinorValue MV WITH(NOLOCK)
                          ON M.CompanySeq=MV.CompanySeq
                            AND M.MinorSeq=MV.MinorSeq
                            AND MV.Serl=1000004
                         LEFT OUTER JOIN _TDAUMinorValue MV2 WITH(NOLOCK)
                          ON M.CompanySeq=MV2.CompanySeq
                            AND M.MinorSeq=MV2.MinorSeq
                            AND MV2.Serl=1000005
              WHERE M.CompanySeq=@CompanySeq 
                AND M.MajorSeq=2003
                ) AA
         LEFT OUTER JOIN #PLAMPF B WITH(NOLOCK)
             ON A.CompanySeq=@CompanySeq
            AND A.CDAC=B.CDAC 
            AND AA.CDCS=B.CDCS
        WHERE A.CompanySeq=@CompanySeq
         AND AA.CDCS<>'90' 
         AND A.KindSeq=1010735003
      ORDER BY AA.CDCS,A.CDAC,A.SORTID
    
    IF @CompanySeq =1 
    BEGIN
        INSERT INTO ODS_KPXGC_HDSLIB_PLAMPF
        SELECT YYMM,CDCS,CDAC,NMCS,NMAC,AMT,DTTMUP FROM ODS_KPX_HDSLIB_PLAMPF_COA WHERE CompanySeq=1 AND YYMM=@YYMM
    END
    
  
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq=1010736017
    INSERT INTO KPX_EISIFProcStaus_COA
    SELECT @CompanySeq,@YYMM,1010736017,'1','',@UserSeq,GETDATE() 
         
    --RETURN
    /* 마감정보 업데이트 */
    DECLARE @CNT INT
    SELECT @CNT=CNT FROM ODS_KPX_HDSLIB_HCLCKPF_COA WHERE CompanySeq = @CompanySeq AND YYMM=@YYMM
    
    IF ISNULL(@CNT,0)=0
        SET @CNT=1
    ELSE 
        SET @CNT=@CNT+1
        DELETE FROM ODS_KPX_HDSLIB_HCLCKPF_COA WHERE CompanySeq = @CompanySeq AND YYMM=@YYMM
      
    IF @CompanySeq =1 
    BEGIN
        DELETE FROM ODS_KPXGC_HDSLIB_HCLCKPF WHERE  YYMM=@YYMM
    END
    
     INSERT INTO ODS_KPX_HDSLIB_HCLCKPF_COA
         SELECT @CompanySeq
      ,@YYMM
      ,@CNT 
      ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
  
   
    IF @CompanySeq =1 
    BEGIN
        INSERT INTO ODS_KPXGC_HDSLIB_HCLCKPF
        SELECT YYMM,CNT,DTTMUP FROM ODS_KPX_HDSLIB_HCLCKPF_COA WHERE CompanySeq=1 AND YYMM=@YYMM
    END
    
     SELECT CNT AS ProcCount,LEFT(DTTMUP,4)+'-'+SUBSTRING(DTTMUP,5,2)+'-'+SUBSTRING(DTTMUP,7,2)+' '+SUBSTRING(DTTMUP,9,2)+':'+SUBSTRING(DTTMUP,12,2)+':'+SUBSTRING(DTTMUP,13,2)  AS ProcDateTime 
      FROM ODS_KPX_HDSLIB_HCLCKPF_COA WHERE CompanySeq = @CompanySeq AND YYMM=@YYMM
  return
  go 
  begin tran 
  exec KPX_EISIFMasterData_COA @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <YYMM>201505</YYMM>
    <ProcCount>0</ProcCount>
    <ProcDateTime />
    <Below1MonthCard>20150430</Below1MonthCard>
    <Below2MonthCard>20150531</Below2MonthCard>
    <Below3MonthCard>20150630</Below3MonthCard>
    <Below1Month>20150430</Below1Month>
    <Below2Month>20150531</Below2Month>
    <Below3Month>20150630</Below3Month>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027957,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1024786
rollback 