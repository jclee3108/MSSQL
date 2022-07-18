IF OBJECT_ID('KPXCM_EISIFMasterData_COA') IS NOT NULL 
    DROP PROC KPXCM_EISIFMasterData_COA
GO 

-- v2015.06.18 
 
-- 자동화정보 생성_COA by박상준   수정 : 이재천
CREATE PROC KPXCM_EISIFMasterData_COA
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS           
    DECLARE @docHandle          INT,      
            @YYMM               NCHAR(6),
            @Below1Month        NCHAR(8),
            @Below2Month        NCHAR(8),
            @Below3Month        NCHAR(8),
            @Below1MonthCard    NCHAR(8),
            @Below2MonthCard    NCHAR(8),
            @Below3MonthCard    NCHAR(8),
            @SQL                NVARCHAR(4000)
    
    CREATE TABLE  #TEISProc (WorkingTag NCHAR(1) NULL)    
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TEISProc'   
     IF @@ERROR <> 0 RETURN    
    
    SELECT @YYMM    = ISNULL(YYMM,'')
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
  
    INSERT INTO ODS_KPX_HDSLIB_CUSTPF_COA ( CompanySeq, CDCO, NMCO, SORTID, DTTMUP ) 
    SELECT @CompanySeq,
           LEFT(CustNo,6),       --LEFT 사용이유 : 연동테이블이므로 사용자 실수로 인하여 자리수가 Over 될시 오류방지
           LEFT(FullName,20),
           0,
           CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
      FROM _TDACust
     WHERE CompanySeq = @CompanySeq
    
    IF @CompanySeq = 2
    BEGIN
        DELETE FROM ODS_KPXCM_HDSLIB_CUSTPF    -- 기존자료 삭제(케미칼)
         
        INSERT INTO ODS_KPXCM_HDSLIB_CUSTPF ( CDCO, NMCO, SORTID, DTTMUP ) 
        SELECT CDCO,NMCO,SORTID,DTTMUP FROM ODS_KPX_HDSLIB_CUSTPF_COA WHERE CompanySeq = 2
    END
    
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM AND ProcItemSeq = 1010736002
    INSERT INTO KPX_EISIFProcStaus_COA ( CompanySeq, YYMM, ProcItemSeq, ProcYn, ErrRemark, LastUserSeq, LastDateTime )
    SELECT @CompanySeq, @YYMM, 1010736002, '1', '', @UserSeq, GETDATE()
    
    
    
    /* 용도정보 업데이트 */
    DELETE FROM ODS_KPX_HDSLIB_USMTPF_COA WHERE CompanySeq = @CompanySeq
     
    IF @CompanySeq = 2 
    BEGIN
        DELETE FROM  ODS_KPXCM_HDSLIB_USMTPF
    END
    
    
    INSERT INTO ODS_KPX_HDSLIB_USMTPF_COA ( CompanySeq, CDITEM, CDUS, NMITEM, NMUS, SORTID, DTTMUP )     
    SELECT @CompanySeq,             
           C.ValueText, -- (경영보고)사업부문코드 
           D.ValueText, -- (경영보고)용도코드            
           E.MinorName, -- (경영보고)사업부문명            
           A.MinorName, -- (경영보고)용도명                      
           A.MinorSort,            
           CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2)        
      FROM _TDAUMinor AS A        
      LEFT OUTER JOIN _TDAUMinorValue AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND C.MinorSeq = B.ValueSeq AND C.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue AS D WITH(NOLOCK) ON ( A.CompanySeq = D.CompanySeq AND D.MinorSeq = A.MinorSeq AND D.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinor      AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = C.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq     
       AND A.MajorSeq = 1010253
     
    IF @CompanySeq = 2 
    BEGIN   
        INSERT INTO ODS_KPXCM_HDSLIB_USMTPF ( CDITEM, CDUS, NMITEM, NMUS, SORTID, DTTMUP )
        SELECT CDITEM, CDUS, NMITEM, NMUS, SORTID, DTTMUP FROM ODS_KPX_HDSLIB_USMTPF_COA WHERE CompanySeq = 2
    END
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM AND ProcItemSeq = 1010736003
    INSERT INTO KPX_EISIFProcStaus_COA ( CompanySeq, YYMM, ProcItemSeq, ProcYn, ErrRemark, LastUserSeq, LastDateTime )
    SELECT @CompanySeq, @YYMM, 1010736003, '1', '', @UserSeq, GETDATE()
    
    
    /* 재무상태표계정 업데이트 */
    DELETE FROM ODS_KPX_HDSLIB_BSMTPF_COA WHERE CompanySeq = @CompanySeq  -- 기존자료 삭제
     
    IF @CompanySeq = 2 
    BEGIN
        DELETE FROM ODS_KPXCM_HDSLIB_BSMTPF
    END
    
    INSERT INTO ODS_KPX_HDSLIB_BSMTPF_COA ( CompanySeq, CDAC, CDACHG, NMAC, SORTID, DTTMUP )
    SELECT @CompanySeq, CDAC, CDACHG, NMAC, SORTID, 
            CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
      FROM KPX_TEISAcc_COA
     WHERE CompanySeq = @CompanySeq
       AND KindSeq = 1010735001
     ORDER BY SORTID
    
    IF @CompanySeq = 2 
    BEGIN
        INSERT INTO ODS_KPXCM_HDSLIB_BSMTPF ( CDAC, CDACHG, NMAC, SORTID, DTTMUP )
        SELECT CDAC, CDACHG, NMAC, SORTID, DTTMUP FROM ODS_KPX_HDSLIB_BSMTPF_COA WHERE CompanySeq = 2
    END
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq = @CompanySeq AND YYMM=@YYMM AND ProcItemSeq = 1010736004
    INSERT INTO KPX_EISIFProcStaus_COA ( CompanySeq, YYMM, ProcItemSeq, ProcYn, ErrRemark, LastUserSeq, LastDateTime )
    SELECT @CompanySeq, @YYMM, 1010736004, '1', '', @UserSeq, GETDATE()
    
    
    
    
    /* 손익계산서계정 업데이트 */
    DELETE FROM ODS_KPX_HDSLIB_PLMTPF_COA WHERE CompanySeq = @CompanySeq  -- 기존자료 삭제
    
    IF @CompanySeq = 2 
    BEGIN
        DELETE FROM  ODS_KPXCM_HDSLIB_PLMTPF
    END
    
    
    INSERT INTO ODS_KPX_HDSLIB_PLMTPF_COA 
    (
        CompanySeq, CDAC, CDACHG, NMAC, SORTID, 
        DTTMUP
    )
    SELECT @CompanySeq 
          ,CDAC
          ,CDACHG
          ,NMAC
          ,SORTID

          ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
      FROM KPX_TEISAcc_COA
     WHERE CompanySeq = @CompanySeq
       AND KindSeq = 1010735003
     ORDER BY SORTID
    
    
    IF @CompanySeq = 2 
    BEGIN
        INSERT INTO ODS_KPXCM_HDSLIB_PLMTPF ( CDAC, CDACHG, NMAC, SORTID, DTTMUP )
        SELECT CDAC, CDACHG, NMAC, SORTID, DTTMUP FROM ODS_KPX_HDSLIB_PLMTPF_COA WHERE CompanySeq = 2
    END
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM AND ProcItemSeq = 1010736006
    INSERT INTO KPX_EISIFProcStaus_COA ( CompanySeq, YYMM, ProcItemSeq, ProcYn, ErrRemark,  LastUserSeq, LastDateTime )
    SELECT @CompanySeq, @YYMM, 1010736006, '1', '', @UserSeq, GETDATE()
    
    
 /************************************************************************************************************************
 ************************************************************************************************************************/
    
    /* 외상매출금 업데이트 */
    DELETE FROM ODS_KPX_HDSLIB_ARAMPF_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM
     
    IF @CompanySeq = 2 
    BEGIN
        DELETE FROM ODS_KPXCM_HDSLIB_ARAMPF WHERE YYMM = @YYMM
    END
    
    INSERT INTO ODS_KPX_HDSLIB_ARAMPF_COA
    (
        CompanySeq, YYMM, CDWG, CDCO, IDSA, 
        GUBN, NMCO, NMWG, NMSA, AMSL, 
        AMAR, DTTMUP
    )
    SELECT @CompanySeq
           ,@YYMM
           ,AA.CDWG
           ,AA.CDCO
           ,AA.IDSA
           ,AA.GUBN
           ,AA.NMCO
           ,AA.NMWG
           ,AA.NMSA
           ,SUM(ISNULL(SALE,0)) AS AMSL
           ,SUM(ISNULL(TOT_SALE,0))- SUM(ISNULL(TOT_RECV,0)) AS AMAR
           ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
      FROM (
               SELECT P.ValueText AS CDWG
                      ,LEFT(CustNo,6) AS CDCO
                      ,M.ValueText   AS IDSA--시스템코드인 수출구분의 추가정보인 '(경영보고)판매구분코드' -> IDSA
                      ,CASE WHEN ISNULL(DF.MngValText,'False')='True' THEN 'Y' ELSE 'N' END   AS GUBN       --거래처등록의 추가정보인 '(경영보고)합계표시' -> GUBN : Y 또는 N으로 변환해서 생성
                      ,LEFT(CST.FullName,40)   AS NMCO
                      ,Q.MinorName AS NMWG 
                      ,M2.ValueText     AS NMSA
                      ,B.DomAmt+B.DomVAT     AS SALE
                      ,0        AS TOT_SALE
                      ,0        AS TOT_RECV
                 FROM _TSLSales                     AS A 
                 LEFT OUTER JOIN _TSLSalesItem      AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.SalesSeq = B.SalesSeq
                            JOIN _TDACust           AS CST WITH(NOLOCK) ON A.CompanySeq = CST.CompanySeq AND A.CustSeq = CST.CustSeq
                 LEFT OUTER JOIN _TDASMinorValue    AS M WITH(NOLOCK) ON A.CompanySeq = M.CompanySeq AND A.SMExpKind = M.MinorSeq AND M.Serl = 1000001
                 LEFT OUTER JOIN _TDASMinorValue    AS M2 WITH(NOLOCK) ON A.CompanySeq = M2.CompanySeq AND A.SMExpKind = M2.MinorSeq AND M2.Serl = 1000002
                 LEFT OUTER JOIN _TDACustUserDefine  AS DF WITH(NOLOCK) ON A.CompanySeq = DF.CompanySeq AND A.CustSeq = DF.CustSeq AND DF.MngSerl = 1000001
                 LEFT OUTER JOIN _TDAUMinorValue    AS O WITH(NOLOCK) ON ( O.CompanySeq = A.CompanySeq AND A.BizUnit = O.ValueSeq AND O.MajorSEq = 1011113 AND O.Serl = 1000003 ) 
                 LEFT OUTER JOIN _TDAUMinorValue    AS P WITH(NOLOCK) ON ( P.CompanySeq = O.CompanySeq AND P.MinorSeq = O.MinorSeq AND P.Serl = 1000001 ) 
                 LEFT OUTER JOIN _TDAUMinor         AS Q WITH(NOLOCK) ON ( Q.CompanySeq = P.CompanySeq AND Q.MinorSeq = P.MinorSeq ) 
                WHERE A.CompanySeq = @CompanySeq
                  AND A.SalesDate BETWEEN @YYMM + '01' AND  @YYMM + '31'
               
               UNION ALL
               
               SELECT P.ValueText AS CDWG
                      ,LEFT(CustNo,6) AS CDCO
                      ,M.ValueText   AS IDSA--시스템코드인 수출구분의 추가정보인 '(경영보고)판매구분코드' -> IDSA
                      ,CASE WHEN ISNULL(DF.MngValText,'False')='True' THEN 'Y' ELSE 'N' END   AS GUBN       --거래처등록의 추가정보인 '(경영보고)합계표시' -> GUBN : Y 또는 N으로 변환해서 생성
                      ,CST.FullName AS NMCO
                      ,Q.MinorName AS NMWG
                      ,M2.ValueText AS NMSA
                      ,0       AS SALE
                      ,B.DomAmt + B.DomVat  AS TOT_SALE
                      ,0       AS TOT_RECV
                 FROM _TSLSales                     AS A 
                 LEFT OUTER JOIN _TSLSalesItem      AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.SalesSeq = B.SalesSeq
                            JOIN _TDACust           AS CST WITH(NOLOCK) ON A.CompanySeq = CST.CompanySeq AND A.CustSeq = CST.CustSeq
                 LEFT OUTER JOIN _TDASMinorValue    AS M WITH(NOLOCK) ON A.CompanySeq = M.CompanySeq AND A.SMExpKind = M.MinorSeq AND M.Serl = 1000001
                 LEFT OUTER JOIN _TDASMinorValue    AS M2 WITH(NOLOCK) ON A.CompanySeq = M2.CompanySeq AND A.SMExpKind = M2.MinorSeq AND M2.Serl = 1000002
                 LEFT OUTER JOIN _TDACustUserDefine  AS DF WITH(NOLOCK) ON A.CompanySeq = DF.CompanySeq AND A.CustSeq = DF.CustSeq AND DF.MngSerl = 1000001
                 LEFT OUTER JOIN _TDAUMinorValue    AS O WITH(NOLOCK) ON ( O.CompanySeq = A.CompanySeq AND A.BizUnit = O.ValueSeq AND O.MajorSEq = 1011113 AND O.Serl = 1000003 ) 
                 LEFT OUTER JOIN _TDAUMinorValue    AS P WITH(NOLOCK) ON ( P.CompanySeq = O.CompanySeq AND P.MinorSeq = O.MinorSeq AND P.Serl = 1000001 ) 
                 LEFT OUTER JOIN _TDAUMinor         AS Q WITH(NOLOCK) ON ( Q.CompanySeq = P.CompanySeq AND Q.MinorSeq = P.MinorSeq ) 
                WHERE A.CompanySeq = @CompanySeq
                  AND A.SalesDate BETWEEN @StkYM + '01' AND @YYMM + '31'  
               
               UNION ALL
                
               SELECT P.ValueText AS CDWG
                      ,LEFT(CustNo,6) AS CDCO
                      ,CASE WHEN(A.CurrSeq)= 16 THEN '1' ELSE '2' END  AS IDSA--시스템코드인 수출구분의 추가정보인 '(경영보고)판매구분코드' -> IDSA
                      ,CASE WHEN ISNULL(DF.MngValText,'False')='True' THEN 'Y' ELSE 'N' END   AS GUBN       --거래처등록의 추가정보인 '(경영보고)합계표시' -> GUBN : Y 또는 N으로 변환해서 생성
                      ,CST.FullName AS NMCO
                      ,Q.MinorName AS NMWG
                      ,CASE WHEN(A.CurrSeq)= 16 THEN '내수' ELSE '직수출' END   AS NMSA
                      ,0       AS SALE
                      ,A.DomAmt+A.DomVAt    AS TOT_SALE
                      ,0       AS TOT_RECV
                 FROM _TSLCreditSum                 AS A 
                            JOIN _TDACust           AS CST WITH(NOLOCK) ON A.CompanySeq = CST.CompanySeq AND A.CustSeq = CST.CustSeq
                 LEFT OUTER JOIN _TDACustUserDefine  AS DF WITH(NOLOCK) ON A.CompanySeq = DF.CompanySeq AND A.CustSeq = DF.CustSeq AND DF.MngSerl = 1000001
                 LEFT OUTER JOIN _TDAUMinorValue    AS O WITH(NOLOCK) ON ( O.CompanySeq = A.CompanySeq AND A.BizUnit = O.ValueSeq AND O.MajorSEq = 1011113 AND O.Serl = 1000003 ) 
                 LEFT OUTER JOIN _TDAUMinorValue    AS P WITH(NOLOCK) ON ( P.CompanySeq = O.CompanySeq AND P.MinorSeq = O.MinorSeq AND P.Serl = 1000001 ) 
                 LEFT OUTER JOIN _TDAUMinor         AS Q WITH(NOLOCK) ON ( Q.CompanySeq = P.CompanySeq AND Q.MinorSeq = P.MinorSeq ) 
                WHERE A.CompanySeq = @CompanySeq
                  AND A.SumYM = @StkYM
                  AND A.SumType = 0
               
               UNION ALL
                
               SELECT P.ValueText AS CDWG
                      ,LEFT(CustNo,6) AS CDCO
                      ,M.ValueText   AS IDSA--시스템코드인 수출구분의 추가정보인 '(경영보고)판매구분코드' -> IDSA
                      ,CASE WHEN ISNULL(DF.MngValText,'False')='True' THEN 'Y' ELSE 'N' END   AS GUBN       --거래처등록의 추가정보인 '(경영보고)합계표시' -> GUBN : Y 또는 N으로 변환해서 생성
                      ,CST.FullName AS NMCO
                      ,Q.MinorName AS NMWG
                      ,M2.ValueText AS NMSA
                      ,0     AS SALE
                      ,0     AS TOT_SALE 
                      ,SMDrOrCr * B.DomAmt     AS TOT_RECV
                 FROM _TSLReceipt                   AS A 
                 LEFT OUTER JOIN _TSLReceiptDesc    AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.ReceiptSeq = B.ReceiptSeq
                            JOIN _TDACust           AS CST WITH(NOLOCK) ON A.CompanySeq = CST.CompanySeq AND A.CustSeq = CST.CustSeq
                 LEFT OUTER JOIN _TDASMinorValue    AS M WITH(NOLOCK) ON A.CompanySeq = M.CompanySeq AND A.SMExpKind = M.MinorSeq AND M.Serl = 1000001
                 LEFT OUTER JOIN _TDASMinorValue    AS M2 WITH(NOLOCK) ON A.CompanySeq = M2.CompanySeq AND A.SMExpKind = M2.MinorSeq AND M2.Serl = 1000002
                 LEFT OUTER JOIN _TDACustUserDefine  AS DF WITH(NOLOCK) ON A.CompanySeq = DF.CompanySeq AND A.CustSeq = DF.CustSeq AND DF.MngSerl = 1000001
                 LEFT OUTER JOIN _TDAUMinorValue    AS O WITH(NOLOCK) ON ( O.CompanySeq = A.CompanySeq AND A.BizUnit = O.ValueSeq AND O.MajorSEq = 1011113 AND O.Serl = 1000003 ) 
                 LEFT OUTER JOIN _TDAUMinorValue    AS P WITH(NOLOCK) ON ( P.CompanySeq = O.CompanySeq AND P.MinorSeq = O.MinorSeq AND P.Serl = 1000001 ) 
                 LEFT OUTER JOIN _TDAUMinor         AS Q WITH(NOLOCK) ON ( Q.CompanySeq = P.CompanySeq AND Q.MinorSeq = P.MinorSeq ) 
                WHERE A.CompanySeq = @CompanySeq
                  AND A.ReceiptDate BETWEEN @StkYM +'01' AND  @YYMM+'31'   
           ) AS AA
     GROUP BY AA.CDWG, AA.CDCO, AA.IDSA, AA.GUBN, AA.NMCO, AA.NMWG, AA.NMSA 
    
    
    IF @CompanySeq = 2 
    BEGIN
        INSERT INTO ODS_KPXCM_HDSLIB_ARAMPF ( YYMM, CDWG, CDCO, IDSA, GUBN, NMCO, NMWG, NMSA, AMSL, AMAR, DTTMUP ) 
        SELECT YYMM, CDWG, CDCO, IDSA, GUBN, NMCO, NMWG, NMSA, AMSL, AMAR, DTTMUP FROM ODS_KPX_HDSLIB_ARAMPF_COA WHERE CompanySeq = 2 AND YYMM = @YYMM
    END
    
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM AND ProcItemSeq = 1010736008
    
    INSERT INTO KPX_EISIFProcStaus_COA ( CompanySeq, YYMM, ProcItemSeq, ProcYn, ErrRemark, LastUserSeq, LastDateTime ) 
    SELECT @CompanySeq,@YYMM,1010736008,'1','',@UserSeq,GETDATE()
    
    

         
    /* 제품해외매출액 업데이트 */
    DELETE FROM ODS_KPX_HDSLIB_FRAMPF_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM 
    
    IF @CompanySeq = 2 
    BEGIN
        DELETE FROM ODS_KPXCM_HDSLIB_FRAMPF WHERE YYMM = @YYMM
    END
    
    INSERT INTO ODS_KPX_HDSLIB_FRAMPF_COA ( CompanySeq, YYMM, CDCS, NMCS, AMT, DTTMUP )
    SELECT @CompanySeq
           ,@YYMM    
           ,AA.CDCS
           ,AA.NMCS
           ,SUM(ISNULL(AA.AMT,0)) AS AMT
           ,CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
      FROM (
                SELECT P.ValueText AS CDCS, 
                       Q.MinorName AS NMCS, 
                       B.DomAmt + B.DomVat   AS AMT       
                  FROM _TSLSales                        AS A 
                  LEFT OUTER JOIN _TSLSalesItem         AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.SalesSeq = B.SalesSeq 
                  LEFT OUTER JOIN _TDAUMinorValue       AS O WITH(NOLOCK) ON ( O.CompanySeq = A.CompanySeq AND A.BizUnit = O.ValueSeq AND O.MajorSEq = 1011113 AND O.Serl = 1000003 ) 
                  LEFT OUTER JOIN _TDAUMinorValue       AS P WITH(NOLOCK) ON ( P.CompanySeq = O.CompanySeq AND P.MinorSeq = O.MinorSeq AND P.Serl = 1000001 ) 
                  LEFT OUTER JOIN _TDAUMinor            AS Q WITH(NOLOCK) ON ( Q.CompanySeq = P.CompanySeq AND Q.MinorSeq = P.MinorSeq ) 
                 WHERE A.CompanySeq = @CompanySeq
                   AND A.SalesDate BETWEEN @YYMM+'01' AND  @YYMM+'31' 
                   AND A.SMExpKind <> 8009001
                
                --UNION ALL               -- 20150323 추가
            
                --SELECT '10' AS CDCS
                --       ,'EOA사업부문' AS NMCS
                --       ,ISNULL(DomAmt,0)+ISNULL(DomVAT,0) AS AMT
                --  FROM _TSLSales                        AS A 
                --  LEFT OUTER JOIN _TSLSalesItem         AS B WITH(NOLOCK) ON A.CompanySeq=B.CompanySeq AND A.SalesSeq=B.SalesSeq
                --  LEFT OUTER JOIN _TDAItem              AS ITM WITH(NOLOCK) ON A.CompanySeq = ITM.CompanySeq AND B.ItemSeq = ITM.ItemSeq
                -- WHERE A.CompanySeq = @CompanySeq
                --   AND A.SalesDate BETWEEN @YYMM+'01' AND @YYMM+'31'
                --   AND A.SMExpKind <> 8009001
                --   AND ITM.AssetSeq IN (4,7)   
  
           ) AS AA 
     WHERE AA.CDCS IS NOT NULL
     GROUP BY AA.CDCS, AA.NMCS
    
    IF @CompanySeq = 2 
    BEGIN
        INSERT INTO ODS_KPXCM_HDSLIB_FRAMPF ( YYMM, CDCS, NMCS, AMT, DTTMUP ) 
        SELECT YYMM, CDCS, NMCS, AMT, DTTMUP FROM ODS_KPX_HDSLIB_FRAMPF_COA WHERE CompanySeq = 2 AND YYMM = @YYMM
    END
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM AND ProcItemSeq = 1010736009
    INSERT INTO KPX_EISIFProcStaus_COA 
    ( 
        CompanySeq, YYMM, ProcItemSeq, ProcYn, ErrRemark, 
        LastUserSeq, LastDateTime 
    ) 
    SELECT @CompanySeq,@YYMM,1010736009,'1','',@UserSeq,GETDATE()
    
    
    
    /* 수금미수금 업데이트 */
    SELECT * 
      INTO #TMP 
      FROM (
                SELECT @YYMM AS YYMM
                       ,CDWG  AS CDWG
                       ,NMWG  AS NMWG
                       ,SUM(ISNULL(AMIN,0)) AS AMIN
                       ,SUM(ISNULL(SALE,0))-SUM(ISNULL(RECV,0))  AS AMJAN
                  FROM ( 
                            SELECT D.ValueText   AS  CDWG
                                   ,E.MinorName AS  NMWG
                                   ,SMDrOrCr * B.DomAmt      AS  AMIN
                                   ,0      AS  SALE
                                   ,0      AS  RECV
                              FROM _TSLReceipt                      AS A 
                              LEFT OUTER JOIN _TSLReceiptDesc       AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.ReceiptSeq = B.ReceiptSeq 
                              LEFT OUTER JOIN _TDAUMinorValue       AS C WITH(NOLOCK) ON ( C.CompanySeq = A.CompanySeq AND C.ValueSeq = A.BizUnit AND C.MajorSeq = 1011113 AND C.Serl = 1000003 ) 
                              LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = C.CompanySeq AND D.MinorSeq = C.MinorSeq AND D.Serl = 1000001 ) 
                              LEFT OUTER JOIN _TDAUMinor            AS E WITH(NOLOCK) ON ( E.CompanySeq = D.CompanySeq AND E.MinorSeq = D.MinorSeq ) 
                             WHERE A.CompanySeq = @CompanySeq
                               AND A.ReceiptDate BETWEEN @YYMM+'01' AND  @YYMM+'31'    
                            
                            UNION ALL
                                    
                            SELECT D.ValueText   AS  CDWG
                                   ,E.MinorName AS  NMWG 
                                   ,0       AS  AMIN
                                   ,B.DomAmt+B.DomVat AS  SALE
                                   ,0       AS  RECV
                              FROM _TSLSales                        AS A 
                              LEFT OUTER JOIN _TSLSalesItem         AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.SalesSeq = B.SalesSeq 
                              LEFT OUTER JOIN _TDAUMinorValue       AS C WITH(NOLOCK) ON ( C.CompanySeq = A.CompanySeq AND C.ValueSeq = A.BizUnit AND C.MajorSeq = 1011113 AND C.Serl = 1000003 ) 
                              LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = C.CompanySeq AND D.MinorSeq = C.MinorSeq AND D.Serl = 1000001 ) 
                              LEFT OUTER JOIN _TDAUMinor            AS E WITH(NOLOCK) ON ( E.CompanySeq = D.CompanySeq AND E.MinorSeq = D.MinorSeq ) 
                             WHERE A.CompanySeq=@CompanySeq
                               AND A.SalesDate BETWEEN @StkYM+'01' AND  @YYMM+'31'  
                            
                            UNION ALL
                                            
                            SELECT D.ValueText   AS  CDWG
                                   ,E.MinorName AS  NMWG 
                                   ,0       AS  AMIN
                                   ,A.DomAmt     AS  SALE
                                   ,0       AS  RECV
                              FROM _TSLCreditSum                    AS A  
                              LEFT OUTER JOIN _TDAUMinorValue       AS C WITH(NOLOCK) ON ( C.CompanySeq = A.CompanySeq AND C.ValueSeq = A.BizUnit AND C.MajorSeq = 1011113 AND C.Serl = 1000003 ) 
                              LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = C.CompanySeq AND D.MinorSeq = C.MinorSeq AND D.Serl = 1000001 ) 
                              LEFT OUTER JOIN _TDAUMinor            AS E WITH(NOLOCK) ON ( E.CompanySeq = D.CompanySeq AND E.MinorSeq = D.MinorSeq ) 
                             WHERE A.CompanySeq = @CompanySeq
                               AND A.SumYM = @StkYM
                               AND A.SumType = 0
                            
                            UNION ALL 
                        
                            SELECT D.ValueText   AS  CDWG
                                   ,E.MinorName AS  NMWG
                                   ,0      AS  AMIN
                                   ,0      AS  SALE
                                   ,SMDrOrCr * B.DomAmt    AS  RECV
                              FROM _TSLReceipt                      AS A 
                              LEFT OUTER JOIN _TSLReceiptDesc       AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.ReceiptSeq = B.ReceiptSeq
                              LEFT OUTER JOIN _TDAUMinorValue       AS C WITH(NOLOCK) ON ( C.CompanySeq = A.CompanySeq AND C.ValueSeq = A.BizUnit AND C.MajorSeq = 1011113 AND C.Serl = 1000003 ) 
                              LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = C.CompanySeq AND D.MinorSeq = C.MinorSeq AND D.Serl = 1000001 ) 
                              LEFT OUTER JOIN _TDAUMinor            AS E WITH(NOLOCK) ON ( E.CompanySeq = D.CompanySeq AND E.MinorSeq = D.MinorSeq ) 
                             WHERE A.CompanySeq = @CompanySeq
                               AND A.ReceiptDate BETWEEN @StkYM+'01' AND  @YYMM+'31'    
                       ) AS BB
                 GROUP BY CDWG, NMWG 
           ) AS CC  
    
    DELETE FROM ODS_KPX_HDSLIB_INAMPF_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM
    
    IF @CompanySeq = 2 
    BEGIN
        DELETE FROM ODS_KPXCM_HDSLIB_INAMPF WHERE YYMM = @YYMM
    END
    
    INSERT INTO ODS_KPX_HDSLIB_INAMPF_COA ( CompanySeq, YYMM, CDWG, NMWG, AMIN, AMJAN, DTTMUP ) 
    SELECT @CompanySeq, YYMM, CDWG, NMWG, AMIN, AMJAN, 
           CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
      FROM #TMP
    
    UNION ALL
    
    SELECT @CompanySeq ,YYMM ,'90' ,'전체' ,SUM(ISNULL(AMIN,0)) ,SUM(ISNULL(AMJAN,0)), 
           CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
      FROM #TMP
     GROUP BY YYMM
    
    
    IF @CompanySeq = 2 
    BEGIN
        INSERT INTO ODS_KPXCM_HDSLIB_INAMPF ( YYMM, CDWG, NMWG, AMIN, AMJAN, DTTMUP ) 
        SELECT YYMM, CDWG, NMWG, AMIN, AMJAN, DTTMUP FROM ODS_KPX_HDSLIB_INAMPF_COA WHERE CompanySeq = 2 AND YYMM = @YYMM
    END
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq = 1010736010
    INSERT INTO KPX_EISIFProcStaus_COA ( CompanySeq, YYMM, ProcItemSeq, ProcYn, ErrRemark, LastUserSeq, LastDateTime )
    SELECT @CompanySeq,@YYMM,1010736010,'1','', @UserSeq,GETDATE()
    
    
    

    /* 받을어음 받을카드 업데이트 */
     
    DECLARE @NextYYMM NCHAR(6)
    
    
    SELECT @NextYYMM = CONVERT(NCHAR(6),DATEADD(MM,1,@YYMM+'01'),112)
  
    DELETE FROM ODS_KPX_HDSLIB_NRAMPF_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM
    IF @CompanySeq = 2 
    BEGIN
        DELETE FROM ODS_KPXCM_HDSLIB_NRAMPF WHERE  YYMM=@YYMM
    END
    
    
    INSERT INTO ODS_KPX_HDSLIB_NRAMPF_COA 
    (
        CompanySeq, YYMM, CDWG, CDCO, NMWG, 
        NMCO, AM01, AM02, AM03, AMGT, 
        DTTMUP
    )
    SELECT @CompanySeq, @YYMM, BB.CDWG, BB.CDCO, BB.NMWG, 
           BB.NMCO, 
           SUM(ISNULL(BB.AM01,0)) AS AM01, 
           SUM(ISNULL(BB.AM02,0)) AS AM02, 
           SUM(ISNULL(BB.AM03,0)) AS AM03, 
           SUM(ISNULL(BB.AMGT,0)) AS AMGT, 
           
           CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
      FROM (
                SELECT LEFT(CST.CustNo,6)     AS CDCO       --LEFT 사용이유 : 연동테이블이므로 사용자 실수로 인하여 자리수가 Over 될시 오류방지
                       ,LEFT(CST.FullName,40)  AS NMCO
                       ,CASE WHEN AA.DueDate<= @Below1Month THEN BillAmt ELSE 0 END AS AM01
                       ,CASE WHEN AA.DueDate > @Below1Month AND DueDate<= @Below2Month THEN BillAmt ELSE 0 END AS AM02 
                       ,CASE WHEN AA.DueDate > @Below2Month AND DueDate<= @Below3Month THEN BillAmt ELSE 0 END AS AM03 
                       ,CASE WHEN AA.DueDate > @Below3Month THEN BillAmt ELSE 0 END AS AMGT
                       ,AA.CDWG
                       ,AA.NMWG
                  FROM (     
                            SELECT A.CustSeq
                                   ,A.DueDate
                                   ,ISNULL(A.BillAmt,0) - CASE WHEN C.AccDate< =@YYMM+'31' THEN (ISNULL(B.OffAmt,0)) ELSE 0 END AS BillAmt  -- 잔액금액
                                   --,ISNULL(A.BillAmt,0)  AS BillAmt       -- 발생금액
                                   ,G.ValueText AS CDWG
                                   ,H.MinorName AS NMWG
                              FROM _TACBill                     AS A 
                              LEFT OUTER JOIN _TACBillOff       AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.BillSeq = B.BillSeq 
                              LEFT OUTER JOIN _TACSlipRow       AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND B.OffSlipSeq = C.SlipSeq AND (C.AccDate <= @YYMM+'31')
                              LEFT OUTER JOIN _TACSlipRow       AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.SlipSeq = D.SlipSeq
                              LEFT OUTER JOIN _TDABizUnit       AS E WITH(NOLOCK) ON ( E.CompanySeq = A.CompanySeq AND E.AccUnit = A.AccUnit ) 
                              LEFT OUTER JOIN _TDAUMinorValue   AS F WITH(NOLOCK) ON ( F.CompanySeq = E.CompanySeq AND F.ValueSeq = E.BizUnit AND F.MajorSeq = 1011113 AND F.Serl = 1000003 ) 
                              LEFT OUTER JOIN _TDAUMinorValue   AS G WITH(NOLOCK) ON ( G.CompanySeq = F.CompanySeq AND G.MinorSeq = F.MinorSeq AND G.Serl = 1000001 ) 
                              LEFT OUTER JOIN _TDAUMinor        AS H WITH(NOLOCK) ON ( H.CompanySeq = G.CompanySeq AND H.MinorSeq = G.MinorSeq ) 
                             WHERE A.CompanySeq = @CompanySeq
                               AND A.SMPayOrRev = 4034002
                               AND A.AccSeq IN ( 
                                                SELECT ValueSeq
                                                  FROM _TDAUMinor                       AS A 
                                                  LEFT OUTER JOIN _TDAUMinorValue       AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.MinorSeq = B.MinorSeq AND B.Serl = 1000001 
                                                 WHERE A.CompanySeq = @CompanySeq
                                                   AND A.MajorSeq = 1010712
                                                   AND A.MinorSort = 1
                                               )
                               AND A.DrawDate <= @YYMM+'31'
                               AND (A.SlipSeq = 0 OR D.AccDate <=@YYMM+'31')
                       ) AS AA  
                  LEFT OUTER JOIN _TDACust AS CST WITH(NOLOCK) ON CST.CompanySeq = @CompanySeq AND AA.CustSeq = CST.CustSeq
  
                UNION ALL
    
                SELECT LEFT(CST.CustNo,6)     AS CDCO       --LEFT 사용이유 : 연동테이블이므로 사용자 실수로 인하여 자리수가 Over 될시 오류방지
                       ,LEFT(CST.FullName,40)  AS NMCO
                       ,CASE WHEN AA.DueDate <= @Below1MonthCard THEN BillAmt ELSE 0 END AS AM01
                       ,CASE WHEN AA.DueDate >   @Below1MonthCard AND DueDate<= @Below2MonthCard THEN BillAmt ELSE 0 END AS AM02 
                       ,CASE WHEN AA.DueDate >   @Below2MonthCard AND DueDate<= @Below3MonthCard THEN BillAmt ELSE 0 END AS AM03 
                       ,CASE WHEN AA.DueDate >   @Below3MonthCard THEN BillAmt ELSE 0 END AS AMGT
                       ,AA.CDWG 
                       ,AA.NMWG    
                  FROM (
                            SELECT A.CustSeq
                                   ,A.DueDate
                                   ,ISNULL(A.BillAmt,0)- CASE WHEN C.AccDate< =@YYMM+'31' THEN (ISNULL(B.OffAmt,0)) ELSE 0 END   AS BillAmt  -- 잔액금액
                                   --,ISNULL(A.BillAmt,0)  AS BillAmt       -- 발생금액
                                   ,G.ValueText AS CDWG
                                   ,H.MinorName AS NMWG
                              FROM _TACBill                     AS A 
                              LEFT OUTER JOIN _TACBillOff       AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.BillSeq = B.BillSeq 
                              LEFT OUTER JOIN _TACSlipRow       AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND B.OffSlipSeq = C.SlipSeq AND (C.AccDate <= @YYMM+'31')
                              LEFT OUTER JOIN _TACSlipRow       AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq AND A.SlipSeq = D.SlipSeq
                              LEFT OUTER JOIN _TDABizUnit       AS E WITH(NOLOCK) ON ( E.CompanySeq = A.CompanySeq AND E.AccUnit = A.AccUnit ) 
                              LEFT OUTER JOIN _TDAUMinorValue   AS F WITH(NOLOCK) ON ( F.CompanySeq = E.CompanySeq AND F.ValueSeq = E.BizUnit AND F.MajorSeq = 1011113 AND F.Serl = 1000003 ) 
                              LEFT OUTER JOIN _TDAUMinorValue   AS G WITH(NOLOCK) ON ( G.CompanySeq = F.CompanySeq AND G.MinorSeq = F.MinorSeq AND G.Serl = 1000001 ) 
                              LEFT OUTER JOIN _TDAUMinor        AS H WITH(NOLOCK) ON ( H.CompanySeq = G.CompanySeq AND H.MinorSeq = G.MinorSeq ) 
                             WHERE A.CompanySeq = @CompanySeq
                               AND A.SMPayOrRev = 4034002
                               AND A.AccSeq IN ( 
                                                SELECT ValueSeq
                                                  FROM _TDAUMinor                   AS A 
                                                  LEFT OUTER JOIN _TDAUMinorValue   AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.MinorSeq = B.MinorSeq AND B.Serl = 1000001
                                                 WHERE A.CompanySeq = @CompanySeq
                                                   AND A.MajorSeq = 1010712
                                                   AND A.MinorSort = 2
                                               )
                               AND A.DrawDate <= @YYMM+'31'
                               AND (A.SlipSeq = 0 OR D.AccDate <=@YYMM+'31')
                       ) AS AA  
                  LEFT OUTER JOIN _TDACust AS CST WITH(NOLOCK) ON CST.CompanySeq = @CompanySeq AND AA.CustSeq = CST.CustSeq
           ) AS BB 
     GROUP BY BB.CDCO, BB.NMCO, BB.CDWG, BB.NMWG  
     HAVING SUM(ISNULL(BB.AM01,0)) <> 0 
         OR SUM(ISNULL(BB.AM02,0)) <> 0 
         OR SUM(ISNULL(BB.AM03,0)) <> 0 
         OR SUM(ISNULL(BB.AMGT,0)) <> 0 
    
    IF @CompanySeq = 2 
    BEGIN
        INSERT INTO ODS_KPXCM_HDSLIB_NRAMPF ( YYMM, CDWG, CDCO, NMWG, NMCO, AM01, AM02, AM03, AMGT, DTTMUP ) 
        SELECT YYMM, CDWG, CDCO, NMWG, NMCO, AM01, AM02, AM03, AMGT, DTTMUP FROM ODS_KPX_HDSLIB_NRAMPF_COA WHERE CompanySeq = 2 AND YYMM = @YYMM
    END
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq = 1010736011
    INSERT INTO KPX_EISIFProcStaus_COA ( CompanySeq, YYMM, ProcItemSeq, ProcYn, ErrRemark, LastUserSeq, LastDateTime ) 
    SELECT @CompanySeq,@YYMM,1010736011,'1','',@UserSeq,GETDATE()
    
    
  /* 생산판매재고 업데이트 */
    
    DECLARE @CostUnit   INT, 
            @Cnt        INT, 
            @AccUnit    INT  
    
    CREATE TABLE #AccUnit 
    (
        IDX_NO      INT IDENTITY, 
        AccUnit     INT 
    )
    
    INSERT INTO #AccUnit ( AccUnit )
    SELECT DISTINCT AccUnit 
      FROM _TDABizUnit 
     WHERE CompanySeq = @CompanySeq  
     
    
    DELETE FROM  ODS_KPX_HDSLIB_MFSLPF_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM
      
    IF @CompanySeq = 2 
    BEGIN
        DELETE FROM ODS_KPXCM_HDSLIB_MFSLPF WHERE  YYMM = @YYMM
    END
    
    
    CREATE TABLE #TMPData 
    (
        CostUnit        INT, 
        ItemKind        NVARCHAR(10), 
        PreAmt          DECIMAL(19,5), 
        EtcOutAmt       DECIMAL(19,5), 
        StockAmt        DECIMAL(19,5), 
        BuyQty          DECIMAL(19,5), 
        BuyAmt          DECIMAL(19,5), 
        EtcInAmt        DECIMAL(19,5), 
        PreQty          DECIMAL(19,5), 
        ProdQty         DECIMAL(19,5), 
        ProdAmt         DECIMAL(19,5), 
        InPutQty        DECIMAL(19,5), 
        InPutAmt        DECIMAL(19,5) 
    )
    
    CREATE TABLE #ResultData 
    (
        CDITEM          NVARCHAR(30), 
        QTIW            DECIMAL(19,5), 
        QTIN            DECIMAL(19,5), 
        QTSL            DECIMAL(19,5), 
        QTWR            DECIMAL(19,5), 
        AMIW            DECIMAL(19,5), 
        AMIN            DECIMAL(19,5), 
        AMSL            DECIMAL(19,5), 
        AMWR            DECIMAL(19,5), 
    )
    
    SELECT @Cnt = 1 
    
    WHILE ( 1 = 1 ) 
    BEGIN
        
        SELECT @CostUnit = (SELECT AccUnit FROM #AccUnit WHERE IDX_NO = @Cnt)
        
        SELECT @SQL=''
        SELECT @SQL='KPXCM_SESMZStockMonthlyAmt  @xmlDocument=N'''+'<ROOT>'
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
        SELECT @SQL=@SQL+'<CostUnit>' + CONVERT(NVARCHAR(60),@CostUnit) + '</CostUnit>'+CHAR(10)
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
        SELECT @SQL='KPXCM_SESMZStockMonthlyAmt  @xmlDocument=N'''+'<ROOT>'
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
        SELECT @SQL=@SQL+'<CostUnit>' + CONVERT(NVARCHAR(60),@CostUnit) + '</CostUnit>'+CHAR(10)
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
    
        
        IF @Cnt = (SELECT MAX(IDX_NO) FROM #AccUnit) 
        BEGIN
            BREAK
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
    END 
    
    
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
    
    
    --select * from #TMPData 
    
    --return 
    
    INSERT INTO #ResultData( CDITEM, QTIW, QTIN, AMIW, AMIN )
    SELECT D.ValueText, A.PreQty, CASE WHEN A.ItemKind = 'F' THEN A.ProdQty ELSE A.BuyQty END, A.PreAmt, CASE WHEN A.ItemKind = 'F' THEN A.ProdAmt ELSE A.BuyAmt END 
      FROM #TMPData AS A 
      LEFT OUTER JOIN _TDABizUnit     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.AccUnit = A.CostUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MajorSeq = 1010556 AND C.Serl = 1000003 AND C.ValueSeq = B.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.MinorSeq AND D.Serl = 1000001 ) 
    
    
    
    INSERT INTO #ResultData( CDITEM, QTSL, AMSL )
    SELECT D.ValueText, SUM(ISNULL(B.STDQty,0)) AS Qty, SUM(B.DomAmt) AS Amt
      FROM _TSLSales                        AS A 
      LEFT OUTER JOIN _TSLSalesItem         AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.SalesSeq = B.SalesSeq
      LEFT OUTER JOIN _TDAUMinorValue       AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MajorSeq = 1010556 AND C.Serl = 1000003 AND C.ValueSeq = A.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.MinorSeq AND D.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAItem              AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemAsset         AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.AssetSeq = E.AssetSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND LEFT(A.SalesDate,6) = @YYMM 
       AND F.SMAssetGrp IN ( 6008001, 6008002, 6008004, 6008006, 6008007 ) 
     GROUP BY D.ValueText
    
    INSERT INTO #ResultData( CDITEM, QTWR, AMWR )
    SELECT H.ValueText, 
           SUM(ISNULL(A.Qty,0))      AS Qty, 
           SUM(ISNULL(A.Amt,0))      AS Amt
      FROM _TESMCProdFMatInput                  AS A 
      LEFT OUTER JOIN _TDAItem                  AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.MatItemSeq = B.ItemSeq
                 JOIN _TESMDCostKey             AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq AND C.CostKeySeq = A.CostKeySeq AND C.SMCostMng = 5512001 
      LEFT OUTER JOIN _TDAItemAsset             AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.AssetSeq = B.AssetSeq ) 
      LEFT OUTER JOIN _TDABizUnit               AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.AccUnit = A.CostUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue           AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.MajorSeq = 1010556 AND G.Serl = 1000003 AND G.ValueSeq = F.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue           AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = G.MinorSeq AND H.Serl = 1000001 ) 
     WHERE A.CompanySeq = @CompanySeq
       AND C.CostYM = @YYMM
       AND D.SMAssetGrp IN ( 6008002, 6008004 )
     GROUP BY H.ValueText 
    

    INSERT INTO ODS_KPX_HDSLIB_MFSLPF_COA
    (
        CompanySeq, YYMM, CDITEM, NMITEM, QTIW, 
        QTIN, QTSL, QTWR, AMIW, AMIN, 
        AMSL, AMWR, DTTMUP
    )
    SELECT @CompanySeq
          ,@YYMM 
          ,A.CDITEM
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
      FROM #ResultData                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue    AS MV WITH(NOLOCK) ON MV.CompanySeq = @CompanySeq AND MV.MajorSeq = 1010556 AND A.CDITEM = MV.ValueText AND MV.Serl = 1000001 
      LEFT OUTER JOIN _TDAUMinor         AS M WITH(NOLOCK) ON M.CompanySeq = @CompanySeq AND MV.MinorSeq = M.MinorSeq
     GROUP BY A.CDITEM, M.MinorName
     ORDER BY A.CDITEM
    
    
    IF @CompanySeq = 2 
    BEGIN
        INSERT INTO ODS_KPXCM_HDSLIB_MFSLPF 
        ( 
            YYMM, CDITEM, NMITEM, QTIW, QTIN, 
            QTSL, QTWR, AMIW, AMIN, AMSL, 
            AMWR, DTTMUP 
        ) 
        SELECT YYMM,CDITEM,NMITEM,QTIW,QTIN,QTSL,QTWR,AMIW,AMIN,AMSL,AMWR,DTTMUP 
          FROM ODS_KPX_HDSLIB_MFSLPF_COA 
         WHERE CompanySeq = 2 
           AND YYMM = @YYMM
    END
    
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq = 1010736012
    INSERT INTO KPX_EISIFProcStaus_COA
    SELECT @CompanySeq,@YYMM,1010736012,'1','',@UserSeq,GETDATE()
    
    
    
    /* 용도별판매 업데이트 */
    
    DELETE FROM ODS_KPX_HDSLIB_USAMPF_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM
    
    IF @CompanySeq = 2 
    BEGIN
        DELETE FROM ODS_KPXCM_HDSLIB_USAMPF WHERE YYMM = @YYMM
    END
    
    
    CREATE TABLE #TSLSales
    (
        IDX_NO      INT IDENTITY, 
        SalesSeq    INT, 
        SalesSerl   INT, 
        BizUnit     INT, 
        Qty         DECIMAL(19,5)  
    )
    
    INSERT INTO #TSLSales ( SalesSeq, SalesSerl, BizUnit, Qty ) 
    SELECT A.SalesSeq, B.SalesSerl, A.BizUnit, B.STDQty 
      FROM _TSLSales AS A 
      LEFT OUTER JOIN _TSLSalesItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.SalesSeq = B.SalesSeq 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.SalesDate,6) = @YYMM 
    
    
    CREATE TABLE #TMP_SourceTable 
    (
        IDOrder   INT, 
        TableName NVARCHAR(100)
    )  
    
    INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
    SELECT 1, '_TSLInvoiceItem'   -- 찾을 데이터의 테이블

    CREATE TABLE #TCOMSourceTracking 
    (
        IDX_NO  INT, 
        IDOrder  INT, 
        Seq      INT, 
        Serl     INT, 
        SubSerl  INT, 
        Qty      DECIMAL(19,5), 
        StdQty   DECIMAL(19,5), 
        Amt      DECIMAL(19,5), 
        VAT      DECIMAL(19,5)
    ) 
          
    EXEC _SCOMSourceTracking 
        @CompanySeq = @CompanySeq, 
        @TableName = '_TSLSalesItem',  -- 기준 테이블
        @TempTableName = '#TSLSales',  -- 기준템프테이블
        @TempSeqColumnName = 'SalesSeq',  -- 템프테이블 Seq
        @TempSerlColumnName = 'SalesSerl',  -- 템프테이블 Serl
        @TempSubSerlColumnName = '' 

    
    
    INSERT INTO ODS_KPX_HDSLIB_USAMPF_COA ( CompanySeq, YYMM, CDITEM, CDUS, NMITEM, NMUS, QTSL, DTTMUP ) 
    SELECT @CompanySeq, 
           @YYMM, 
           E.ValueText AS CDITEM, 
           G.ValueText AS CDUS, 
           F.MinorName AS NMITEM, 
           H.MinorName AS NMUS, 
           SUM(A.Qty) AS QTSL, 
           CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2)        
      FROM #TSLSales AS A 
      LEFT OUTER JOIN #TCOMSourceTracking AS B ON ( B.IDX_NO = A.IDX_NO ) 
      LEFT OUTER JOIN KPX_TSLInvoiceItemAdd AS C ON ( C.CompanySeq = @CompanySeq AND C.InvoiceSeq = B.Seq AND C.InvoiceSerl = B.Serl ) 
      LEFT OUTER JOIN _TDAUMinor            AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = C.UMUseType ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = H.MinorSeq AND D.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = D.ValueSeq ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = F.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = H.MinorSeq AND G.Serl = 1000002 ) 
     GROUP BY E.ValueText, G.ValueText, F.MinorName, H.MinorName
    
    
    IF @CompanySeq = 2 
    BEGIN
        INSERT INTO ODS_KPXCM_HDSLIB_USAMPF ( YYMM, CDITEM, CDUS, NMITEM, NMUS, QTSL, DTTMUP )
        SELECT YYMM, CDITEM, CDUS, NMITEM, NMUS, QTSL, DTTMUP FROM ODS_KPX_HDSLIB_USAMPF_COA WHERE CompanySeq = 2 AND YYMM = @YYMM
    END
    
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM AND ProcItemSeq = 1010736013
    INSERT INTO KPX_EISIFProcStaus_COA
    SELECT @CompanySeq,@YYMM,1010736013,'1','',@UserSeq,GETDATE() 
    
    
    
    
    /* 매출집계표 업데이트 */
    
    
    DELETE FROM  ODS_KPX_HDSLIB_SLTTPF_COA WHERE CompanySeq=@CompanySeq AND YYMM=@YYMM
    
    IF @CompanySeq = 2 
    BEGIN
        DELETE FROM ODS_KPXCM_HDSLIB_SLTTPF WHERE YYMM = @YYMM
    END
    
    CREATE TABLE #TmpSalesSum
    (
        GUBN NVARCHAR(60), 
        ISDA NVARCHAR(60), 
        NMBN NVARCHAR(60), 
        NMSA NVARCHAR(60), 
        QTSL DECIMAL(19,5), 
        AMSL DECIMAL(19,5), 
        VAT  DECIMAL(19,5), 
        TAX  DECIMAL(19,5) 
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
      FROM (
                SELECT AA.ValueText     AS GUBN 
                      ,AA.ValueText2     AS ISDA 
                      ,AA.MinorName     AS NMBN 
                      ,AA.ValueText3     AS NMSA
                      ,ISNULL(SI.STDQty,0)   AS QTSL
                      ,ISNULL(SI.DomAmt,0)   AS AMSL
                      ,ISNULL(SI.DomVAT,0)   AS VAT
                      ,0        AS TAX 
                  FROM _TSLSales                    AS SM  
                  LEFT OUTER JOIN _TSLSalesItem     AS SI WITH(NOLOCK) ON SI.CompanySeq = @CompanySeq AND SM.SalesSeq = SI.SalesSeq
                  LEFT OUTER JOIN _TDAItemClass     AS IC WITH(NOLOCK) ON ( IC.CompanySeq = @CompanySeq AND SI.ItemSeq = IC.ItemSeq AND IC.UMajorItemClass IN (2001,2004) ) 
                  LEFT OUTER JOIN _TDAUMinor        AS MQ WITH(NOLOCK) ON ( MQ.CompanySeq = @CompanySeq AND MQ.MajorSeq = LEFT( IC.UMItemClass, 4 ) AND IC.UMItemClass = MQ.MinorSeq ) 
                  LEFT OUTER JOIN _TDAUMinorValue   AS MV WITH(NOLOCK) ON ( MV.CompanySeq = @CompanySeq AND MV.MajorSeq IN (2001,2004) AND MQ.MinorSeq = MV.MinorSeq AND MV.Serl IN (1001,2001) ) 
                  LEFT OUTER JOIN _TDASMinorValue   AS B WITH(NOLOCK) ON SM.CompanySeq = B.CompanySeq AND SM.SMExpKind = B.MinorSeq AND B.Serl = 1000001
                  LEFT OUTER JOIN ( 
                                    SELECT A.MinorName ,A.MinorSeq,M.ValueText ValueText ,M2.ValueSeq AS ValueSeq ,M3.ValueText AS ValueText2,M4.ValueText AS ValueText3
                                      FROM _TDAUMinor                   AS A 
                                      LEFT OUTER JOIN _TDAUMinorValue   AS M WITH(NOLOCK) ON A.CompanySeq = M.CompanySeq AND A.MinorSeq=M.MinorSeq AND M.Serl = 1000001
                                      LEFT OUTER JOIN _TDAUMinorValue   AS M2 WITH(NOLOCK) ON A.CompanySeq = M2.CompanySeq AND A.MinorSeq=M2.MinorSeq AND M2.Serl = 1000002
                                      LEFT OUTER JOIN _TDAUMinorValue   AS M3 WITH(NOLOCK) ON A.CompanySeq = M3.CompanySeq AND A.MinorSeq=M3.MinorSeq AND M3.Serl = 1000003
                                      LEFT OUTER JOIN _TDAUMinorValue   AS M4 WITH(NOLOCK) ON A.CompanySeq = M4.CompanySeq AND A.MinorSeq=M4.MinorSeq AND M4.Serl = 1000004
                                     WHERE A.CompanySeq = @CompanySeq
                                       AND A.MajorSeq = 1010705
                                       AND M3.ValueText <> '9'
                                  ) AS AA ON B.ValueText = AA.ValueText2 AND MV.ValueSeq = AA.ValueSeq
                  LEFT OUTER JOIN _TDAItem          AS ITM WITH(NOLOCK) ON SM.CompanySeq = ITM.CompanySeq AND SI.ItemSeq = ITM.ItemSeq 
                 WHERE SM.CompanySeq=@CompanySeq
                   AND SM.SalesDate BETWEEN @YYMM+'01' AND  @YYMM+'31'  
                   AND AA.MinorName IS NOT NULL
                
                --UNION ALL
                
                --SELECT 'G' AS GUBN
                --      ,'1' AS IDSA
                --      ,'EOA상품' AS NMBN
                --      ,'내수'    AS NMSA 
                --      ,ISNULL(B.STDQty,0) AS QTSL
                --      ,ISNULL(B.DomAmt,0) AS AMSL
                --      ,ISNULL(B.DomVAT,0) AS VAT
                --      ,0 AS TAX
                --  FROM _TSLSales                    AS A 
                --  LEFT OUTER JOIN _TSLSalesItem     AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.SalesSeq = B.SalesSeq
                --  LEFT OUTER JOIN _TDAItem          AS ITM WITH(NOLOCK) ON A.CompanySeq = ITM.CompanySeq AND B.ItemSeq = ITM.ItemSeq
                -- WHERE A.CompanySeq = @CompanySeq
                --   AND A.SalesDate BETWEEN @YYMM+'01' AND @YYMM+'31'
                --   AND ITM.AssetSeq IN (4,7) 
           ) AS BB
     GROUP BY BB.GUBN, BB.ISDA, BB.NMBN, BB.NMSA  
          
  
  
    INSERT INTO ODS_KPX_HDSLIB_SLTTPF_COA 
    (
        CompanySeq, YYMM, GUBN, IDSA, NMBN, 
        NMSA, QTSL, AMSL, VAT, TAX, 
        DTTMUP
    )
    SELECT @CompanySeq, @YYMM, AA.GUBN, AA.ISDA, AA.NMBN, 
           AA.NMSA, AA.QTSL, AA.AMSL, AA.VAT, AA.TAX, 
           CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
      FROM  (
                SELECT GUBN,
                       ISDA,
                       NMBN,
                       NMSA,
                       QTSL,
                       AMSL,
                       VAT,
                       TAX
                  FROM #TmpSalesSum
                
                UNION ALL
                
                SELECT GUBN, 
                       9,
                       NMBN,
                       '합계',
                       SUM(QTSL),
                       SUM(AMSL),
                       SUM(VAT),
                       SUM(TAX)
                  FROM #TmpSalesSum
                 GROUP BY GUBN,NMBN
            ) AS  AA
     ORDER BY GUBN, ISDA
    
    IF @CompanySeq = 2 
    BEGIN
        INSERT INTO ODS_KPXCM_HDSLIB_SLTTPF ( YYMM, GUBN, IDSA, NMBN, NMSA, QTSL, AMSL, VAT, TAX, DTTMUP ) 
        SELECT YYMM, GUBN, IDSA, NMBN, NMSA, QTSL, AMSL, VAT, TAX, DTTMUP FROM ODS_KPX_HDSLIB_SLTTPF_COA WHERE CompanySeq = 2 AND YYMM = @YYMM
    END
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM AND ProcItemSeq = 1010736014
    INSERT INTO KPX_EISIFProcStaus_COA ( CompanySeq, YYMM, ProcItemSeq, ProcYn, ErrRemark, LastUserSeq, LastDateTime ) 
    SELECT @CompanySeq,@YYMM,1010736014,'1','',@UserSeq,GETDATE() 
    
    
    
    /* 판매장려금 */
    DELETE FROM ODS_KPX_HDSLIB_DESLPF_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM 
    
    IF @CompanySeq = 2 
    BEGIN
        DELETE FROM ODS_KPXCM_HDSLIB_DESLPF WHERE  YYMM = @YYMM
    END
    
    INSERT INTO ODS_KPX_HDSLIB_DESLPF_COA ( CompanySeq, YYMM, AMSL, DTTMUP ) 
    SELECT @CompanySeq, 
           LEFT(A.AccDate,6), 
           SUM(B.DrAmt), 
           CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2)  
      FROM _TACSlip         AS A 
      JOIN _TACSlipRow      AS B ON ( B.CompanySeq = @CompanySeq AND A.SlipMstSeq = A.SlipMstSeq AND B.AccSeq IN (SELECT ValueSeq FROM _TDAUMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 1011164) )
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY LEFT(A.AccDate,6) 
    
    
    IF @CompanySeq = 2 
    BEGIN
        INSERT INTO ODS_KPXCM_HDSLIB_DESLPF ( YYMM, AMSL, DTTMUP ) 
        SELECT YYMM, AMSL, DTTMUP FROM ODS_KPX_HDSLIB_DESLPF_COA WHERE CompanySeq = 2 AND YYMM = @YYMM
    END
    
    

    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM AND ProcItemSeq = 1010736015
    INSERT INTO KPX_EISIFProcStaus_COA ( CompanySeq, YYMM, ProcItemSeq, ProcYn, ErrRemark, LastUserSeq, LastDateTime ) 
    SELECT @CompanySeq,@YYMM,1010736015,'1','',@UserSeq,GETDATE() 
    
    
    
    /* 재무상태표 업데이트 */
    DELETE FROM  ODS_KPX_HDSLIB_BSAMPF_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM 
    
    
    IF @CompanySeq = 2 
    BEGIN
        DELETE FROM ODS_KPXCM_HDSLIB_BSAMPF WHERE  YYMM = @YYMM
    END
    

    CREATE TABLE #tmpFinancialStatement_Sub
    (
        AccUnit INT, 
        RowNum  INT 
    )
    
    ALTER TABLE #tmpFinancialStatement_Sub ADD ThisTermItemAmt       DECIMAL(19, 5)  -- 당기항목금액
    ALTER TABLE #tmpFinancialStatement_Sub ADD ThisTermAmt           DECIMAL(19, 5)  -- 당기금액
    ALTER TABLE #tmpFinancialStatement_Sub ADD PrevTermItemAmt       DECIMAL(19, 5)  -- 전기항목금액
    ALTER TABLE #tmpFinancialStatement_Sub ADD PrevTermAmt           DECIMAL(19, 5)  -- 전기금액
    ALTER TABLE #tmpFinancialStatement_Sub ADD PrevChildAmt          DECIMAL(19, 5)  -- 하위금액
    ALTER TABLE #tmpFinancialStatement_Sub ADD ThisChildAmt          DECIMAL(19, 5)  -- 하위금액
    ALTER TABLE #tmpFinancialStatement_Sub ADD ThisReplaceFormula    NVARCHAR(1000)   -- 당기금액
    ALTER TABLE #tmpFinancialStatement_Sub ADD PrevReplaceFormula    NVARCHAR(1000)   -- 당기금액
        
    EXEC _SCOMFSFormInit @CompanySeq, 2, 1, '#tmpFinancialStatement_Sub'     
    
    TRUNCATE TABLE #tmpFinancialStatement_Sub 
    
    

    
    --select * From #AccUnit 
    
    
    
    SELECT @Cnt = 1 
    
    WHILE ( 1 = 1 )
    BEGIN
        SELECT @AccUnit = AccUnit 
          FROM #AccUnit 
         WHERE IDX_NO = @Cnt 
    
        CREATE TABLE #tmpFinancialStatement
        (
            RowNum INT IDENTITY(0, 1)
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
        EXEC _SCOMFSFormMakeRawData @CompanySeq, 2, 0, @AccUnit, @YYMM, @YYMM, '', '','' , '#tmpFinancialStatement','1', '0', '0', 0  
        EXEC _SCOMFSFormCalc @CompanySeq, 2, '#tmpFinancialStatement', 1    
    

        INSERT INTO #tmpFinancialStatement_Sub
        SELECT @AccUnit, * 
          FROM #tmpFinancialStatement 
            
        DROP TABLE #tmpFinancialStatement 
        
        IF @Cnt = (SELECT MAX(IDX_NO) FROM #AccUnit) 
        BEGIN
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END   
    
    END 
    
    
    SELECT ISNULL(CDACHG,'')AS CDACHG,
	       ISNULL(CDAC,'') AS CDAC, 
	       ISNULL(G.ValueText,'') AS CDWG,
	       ISNULL(H.MinorName,'') AS NMWG, 
		   --ISNULL(DRBalAmt,0)+ISNULL(CrBalAmt,0) AS Amt
           --(ISNULL(DRBalAmt,0)+ISNULL(CrBalAmt,0)) AS Amt
		   CASE WHEN B.Calc ='-' THEN -1 * (ISNULL(DRBalAmt,0)+ISNULL(CrBalAmt,0)) ELSE (ISNULL(DRBalAmt,0)+ISNULL(CrBalAmt,0))  END AS Amt--,C.SMDrOrCr AS SMDrOrCr
	  INTO #TMPResult 
	  FROM KPX_TEISAcc_COA                          AS A 
      LEFT OUTER JOIN KPX_TEISAccSub_COA            AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.Seq = B.Seq
      LEFT OUTER JOIN #tmpFinancialStatement_Sub    AS C WITH(NOLOCK) ON B.AccSeq = C.FSItemSeq 
      LEFT OUTER JOIN _TDABizUnit                   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.AccUnit = C.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue               AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MajorSeq = 1011113 AND F.Serl = 1000003 AND F.ValueSeq = D.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue               AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = F.MinorSeq AND G.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor                    AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = G.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq   
	   AND KindSeq = 1010735001
    
    
    --select * from #TMPResult 
    
    
    --return 
    
    
	   --AND CDAC='23020000'

	   --AND IsLast='1'
--	   AND C.FsItemSeq IN
--	   (
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
    
    
    --select * from #TMPResult 
    
    --return 
  
    CREATE TABLE #TMPACData  
    (
        CDACHG  NVARCHAR(30), 
        CDAC    NVARCHAR(30), 
        CDWG    NVARCHAR(30), 
        NMWG    NVARCHAR(30), 
        Amt     DECIMAL(19,5)
    )
    
    CREATE TABLE #TMPACData2 
    (
        CDACHG  NVARCHAR(30), 
        CDAC    NVARCHAR(30), 
        CDWG    NVARCHAR(30), 
        NMWG    NVARCHAR(30), 
        Amt     DECIMAL(19,5)
    )
  
    CREATE TABLE #TMPACData3
    (
        CDACHG  NVARCHAR(30), 
        CDAC    NVARCHAR(30), 
        CDWG    NVARCHAR(30), 
        NMWG    NVARCHAR(30), 
        Amt     DECIMAL(19,5)
    )
    
    CREATE TABLE #TMPACData4
    (
        CDACHG  NVARCHAR(30), 
        CDAC    NVARCHAR(30), 
        CDWG    NVARCHAR(30), 
        NMWG    NVARCHAR(30), 
        Amt     DECIMAL(19,5)
    )
    

    INSERT INTO #TMPACData ( CDACHG, CDAC, CDWG, NMWG, Amt ) 
    SELECT ISNULL((SELECT MAX(CDACHG)  FROM KPX_TEISAcc_COA WHERE CDAC = A.CDACHG),'')  AS CDACHG, 
           A.CDACHG AS CDAC,
           A.CDWG, 
           A.NMWG, 
           SUM(ISNULL(A.Amt,0))
      FROM #TMPResult A
     GROUP BY A.CDACHG, CDWG, NMWG 
    --  HAVING (SELECT MAX(CDACHG)  FROM KPX_TEISAcc WHERE CDAC=A.CDACHG)<>''
    --select * from #TMPACData 
    
    

    INSERT INTO #TMPACData2 ( CDACHG, CDAC, CDWG, NMWG, Amt ) 
    SELECT ISNULL((SELECT MAX(CDACHG)  FROM KPX_TEISAcc_COA WHERE CDAC = A.CDACHG),'')  AS CDACHG , 
           A.CDACHG AS CDAC,
           A.CDWG, 
           A.NMWG, 
           SUM(ISNULL(A.Amt,0))
      FROM #TMPACData A
     GROUP BY A.CDACHG, CDWG, NMWG 
  
    INSERT INTO #TMPACData3 ( CDACHG, CDAC, CDWG, NMWG, Amt ) 
    SELECT ISNULL((SELECT MAX(CDACHG)  FROM KPX_TEISAcc_COA WHERE CDAC=A.CDACHG),'') AS CDACHG,
           A.CDACHG AS CDAC ,
           A.CDWG, 
           A.NMWG, 
           SUM(ISNULL(A.Amt,0))
      FROM #TMPACData2 A
     GROUP BY A.CDACHG, CDWG, NMWG 
     
    INSERT INTO #TMPACData4 ( CDACHG, CDAC, CDWG, NMWG, Amt ) 
    SELECT ISNULL((SELECT MAX(CDACHG)  FROM KPX_TEISAcc_COA WHERE CDAC=A.CDACHG),'') AS CDACHG, 
           A.CDACHG AS CDAC ,
           A.CDWG, 
           A.NMWG, 
           SUM(ISNULL(A.Amt,0))
      FROM #TMPACData3 A
     GROUP BY A.CDACHG, CDWG, NMWG 
   
    INSERT INTO ODS_KPX_HDSLIB_BSAMPF_COA ( CompanySeq, YYMM, CDAC, CDWG, NMAC, NMWG, AMT, DTTMUP ) 
    SELECT @CompanySeq, 
           @YYMM, 
           A.CDAC, 
           BB.CDWG, 
           A.NMAC, 
           BB.NMWG, 
           CASE WHEN Dummy1 = '-' THEN -1 * ISNULL(Amt,0) ELSE ISNULL(Amt,0) END  AS Amt, 
           CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2)
      FROM KPX_TEISAcc_COA A 
      JOIN  (
                SELECT AA.CDAC, AA.CDWG, AA.NMWG ,SUM(ISNULL(Amt,0)) AS Amt
                  FROM ( 
                           SELECT CDACHG, CDAC, CDWG, NMWG, Amt FROM #TmpResult WHERE CDAC <> ''
                           UNION ALL
                           SELECT CDACHG, CDAC, CDWG, NMWG, Amt FROM #TMPACData WHERE CDAC <> ''
                           UNION ALL
                           SELECT CDACHG, CDAC, CDWG, NMWG, Amt FROM #TMPACData2 WHERE CDAC <> ''
                           UNION ALL
                           SELECT CDACHG, CDAC, CDWG, NMWG, Amt FROM #TMPACData3 WHERE CDAC <> ''
                           UNION ALL
                           SELECT CDACHG, CDAC, CDWG, NMWG, Amt FROM #TMPACData4 WHERE CDAC <> ''
                       ) AS AA
                 GROUP BY AA.CDAC, AA.CDWG, AA.NMWG
            ) AS BB ON A.CompanySeq = @CompanySeq AND A.CDAC = BB.CDAC
    
    
    
    CREATE TABLE #Dummy1 
    (
        CDWG        NVARCHAR(30), 
        Amt         DECIMAL(19,5) 
    )
    
    CREATE TABLE #Dummy2 
    (
        CDWG        NVARCHAR(30), 
        Amt         DECIMAL(19,5) 
    )
    
    CREATE TABLE #Dummy3  
    (
        CDWG        NVARCHAR(30), 
        Amt         DECIMAL(19,5) 
    )
    
    CREATE TABLE #Dummy4  
    (
        CDWG        NVARCHAR(30), 
        Amt         DECIMAL(19,5) 
    )
    
    
    --  자산합계
    INSERT INTO #Dummy1 ( CDWG, Amt ) 
    SELECT CDWG, ISNULL(Amt,0)
      FROM ODS_KPX_HDSLIB_BSAMPF_COA
     WHERE  CompanySeq = @CompanySeq
       AND CDAC = '10000000'
       AND YYMM = @YYMM
    
    -- 부채합계
    INSERT INTO #Dummy2 ( CDWG, Amt ) 
    SELECT CDWG, ISNULL(Amt,0)
     FROM ODS_KPX_HDSLIB_BSAMPF_COA
    WHERE  CompanySeq = @CompanySeq
      AND CDAC = '20000000'
      AND YYMM = @YYMM
        
     
     -- 자본합계
    INSERT INTO #Dummy3 ( CDWG, Amt ) 
    SELECT CDWG, ISNULL(Amt,0)
       FROM ODS_KPX_HDSLIB_BSAMPF_COA
      WHERE  CompanySeq=@CompanySeq
       AND CDAC = '30000000'
       AND YYMM = @YYMM
     
    INSERT INTO #Dummy4 ( CDWG, Amt ) 
    SELECT CDWG, ISNULL(Amt,0)
       FROM ODS_KPX_HDSLIB_BSAMPF_COA
      WHERE  CompanySeq = @CompanySeq
       AND CDAC BETWEEN '31010000' AND '31039999'
       AND YYMM = @YYMM

    -- 이익잉여금
    UPDATE A 
       SET AMT = B.Amt - C.Amt - D.Amt 
      FROM ODS_KPX_HDSLIB_BSAMPF_COA    AS A 
      JOIN #Dummy1 AS B ON ( B.CDWG = A.CDWG ) 
      JOIN #Dummy2 AS C ON ( C.CDWG = A.CDWG ) 
      JOIN #Dummy4 AS D ON ( D.CDWG = A.CDWG ) 
     WHERE A.CompanySeq = @CompanySeq
      AND A.CDAC = '31040000'
      AND A.YYMM = @YYMM
    
    -- 자본 & 자본총계
    UPDATE A 
       SET AMT = D.Amt + ISNULL((SELECT AMT FROM ODS_KPX_HDSLIB_BSAMPF_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM AND CDAC = '31040000' AND CDWG = A.CDWG),0)
      FROM ODS_KPX_HDSLIB_BSAMPF_COA AS A 
      JOIN #Dummy4 AS D ON ( D.CDWG = A.CDWG ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.CDAC IN ('31000000','40000000') 
       AND A.YYMM = @YYMM
    
    
    -- 자본합계
    UPDATE A 
       SET AMT= A.AMT + ( B.Amt - C.Amt - D.Amt )
      FROM ODS_KPX_HDSLIB_BSAMPF_COA AS A 
      JOIN #Dummy1 AS B ON ( B.CDWG = A.CDWG ) 
      JOIN #Dummy2 AS C ON ( C.CDWG = A.CDWG ) 
      JOIN #Dummy3 AS D ON ( D.CDWG = A.CDWG ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.CDAC = '30000000' 
       AND A.YYMM = @YYMM
  
    -- 자본총계 = 자본합계
    UPDATE A
       SET AMT = (SELECT AMT FROM ODS_KPX_HDSLIB_BSAMPF_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM AND CDAC = '30000000' AND CDWG = A.CDWG)
      FROM ODS_KPX_HDSLIB_BSAMPF_COA AS A 
     WHERE A.CompanySeq = @CompanySeq
       AND A.CDAC = '40000000' 
       AND A.YYMM = @YYMM
  
  
  
    UPDATE A
       SET AMT = (SELECT SUM(ISNULL(AMT,0)) FROM ODS_KPX_HDSLIB_BSAMPF_COA WHERE CDAC IN('2000000','3000000') AND YYMM = @YYMM AND CDWG = A.CDWG) 
      FROM ODS_KPX_HDSLIB_BSAMPF_COA AS A 
     WHERE A.CDAC = '3999999'
       AND A.CompanySeq = @CompanySeq
       AND A.YYMM = @YYMM 
    
    
    IF @CompanySeq = 2 
    BEGIN
        INSERT INTO ODS_KPXCM_HDSLIB_BSAMPF ( YYMM, CDAC, CDWG, NMAC, NMWG, AMT, DTTMUP ) 
        SELECT YYMM, CDAC, CDWG, NMAC, NMWG, AMT, DTTMUP FROM ODS_KPX_HDSLIB_BSAMPF_COA WHERE CompanySeq = 2 AND YYMM = @YYMM
    END
    
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM AND ProcItemSeq = 1010736017
    INSERT INTO KPX_EISIFProcStaus_COA ( CompanySeq, YYMM, ProcItemSeq, ProcYn, ErrRemark, LastUserSeq, LastDateTime ) 
    SELECT @CompanySeq,@YYMM,1010736017,'1','',@UserSeq,GETDATE() 
    
    
    /* 손익계산서 업데이트 */
    DELETE FROM ODS_KPX_HDSLIB_PLAMPF_COA WHERE CompanySeq=@CompanySeq AND YYMM = @YYMM 
    
    IF @CompanySeq = 2 
    BEGIN
        DELETE FROM ODS_KPXCM_HDSLIB_PLAMPF WHERE YYMM = @YYMM
    END
    
    CREATE TABLE #PLAMPF
    (
        CDCS    NVARCHAR(30),
        CDAC    NVARCHAR(30),
        NMCS    NVARCHAR(30),
        NMAC    NVARCHAR(30),
        AMT     DECIMAL(19,5)
    )
    
    CREATE TABLE #TBase -- 경영보고용-조직코드담는 테이블(해당 코드의 데이터가 없을시 0의 값이 넣기위함. 
    (
        CDCS NVARCHAR(30), 
        NMCS NVARCHAR(30)
    ) 
    
    INSERT INTO #TBase ( CDCS, NMCS ) 
    SELECT B.ValueText, A.MinorName 
      FROM _TDAUMinor                       AS A 
      LEFT OUTER JOIN _TDAUMinorValue       AS B ON A.CompanySeq = B.CompanySeq AND A.MinorSeq = B.MinorSeq AND B.Serl = 1000001
     WHERE A.CompanySeq = @CompanySeq
       AND A.MajorSeq = 1011113
    
    -- 생산수량
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT ) 
    SELECT A.CDITEM AS CDCS, 
           '010000'     AS CDAC, 
           A.NMITEM AS NMCS, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '010000' AND KindSeq = 1010735003) AS NMAC, 
           SUM(A.QTIN) - SUM(A.QTWR)        AS AMT
      FROM ODS_KPXCM_HDSLIB_MFSLPF AS A 
     WHERE A.YYMM = @YYMM
     GROUP BY A.CDITEM, A.NMITEM 
    
    
    -- 생산금액
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )      
    SELECT A.CDITEM AS CDCS, 
           '020000'     AS CDAC, 
           A.NMITEM AS NMCS, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '020000' AND KindSeq = 1010735003) AS NMAC,
           SUM(A.AMIN) - SUM(A.AMWR)        AS AMT
      FROM ODS_KPXCM_HDSLIB_MFSLPF AS A 
     WHERE A.YYMM = @YYMM 
     GROUP BY A.CDITEM, A.NMITEM  
    
    
    -- 제품 국내
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )      
    SELECT A.CDCS, 
           '030100', 
           A.NMCS, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '030100' AND KindSeq = 1010735003) AS NMAC,
           A.AMT 
      FROM ODS_KPXCM_HDSLIB_FRAMPF AS A 
     WHERE A.YYMM = @YYMM 
    
    
    -- 제품해외      
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT CDCS,
           '030200' AS CDAC,
           NMCS,
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC = '030200' AND KindSeq=1010735003) AS NMAC, 
           AMT AS AMT 
      FROM ODS_KPXCM_HDSLIB_FRAMPF 
     WHERE YYMM = @YYMM
    
    
    
    
    -- 상품매출
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '030300', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '030300' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.CrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq 
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '030300' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
    
    
    
    --select * from _TDAUMinorValue  where companyseq = 2 and majorseq = 1011113 
    
    -- 판매장려금 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '030500', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '030500' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip                     AS A 
      JOIN _TACSlipRow                  AS B ON ( B.CompanySeq = @CompanySeq 
                                              AND A.SlipMstSeq = A.SlipMstSeq 
                                              AND B.AccSeq IN (SELECT ValueSeq FROM _TDAUMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 1011164) 
                                                )
      LEFT OUTER JOIN _TDABizUnit       AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor        AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
    
    
    -- 매출액 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT CDCS
           ,'030000'
           ,A.NMCS
		   ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC = '030000' AND KindSeq = 1010735003)
           ,SUM(A.AMT)
      FROM #PLAMPF A  
     WHERE A.CDAC BETWEEN '030100' AND '030999'
     GROUP BY A.CDCS,A.NMCS
    
    
    
    ---- 4110000 제품매출, 4130000 상품매출          
    ---- [세금계산서품목조회]화면 및 [수출매출품목조회]화면의 '실적부서'와 연결된 활동센터를 사용자정의코드 '(경영보고)매출집계활동센터_KPX'의 '조직코드'별로 집계          
    ---- 매출계정별로 제품매출과 상품매출을 분리시켜 집계          
    ---- 금액은 부가세를 제외한 '원화판매금액'          
  
    

    CREATE TABLE #TMPFSData 
    (
        CostUnit        INT, 
        ItemKind        NVARCHAR(10), 
        PreAmt          DECIMAL(19,5), 
        EtcOutAmt       DECIMAL(19,5), 
        StockAmt        DECIMAL(19,5), 
        BuyQty          DECIMAL(19,5), 
        BuyAmt          DECIMAL(19,5), 
        EtcInAmt        DECIMAL(19,5), 
        PreQty          DECIMAL(19,5), 
        ProdQty         DECIMAL(19,5), 
        ProdAmt         DECIMAL(19,5), 
        InPutQty        DECIMAL(19,5), 
        InPutAmt        DECIMAL(19,5) 
    )
    
    
    
    
    SELECT @Cnt = 1 
    
    WHILE ( 1 = 1 ) 
    BEGIN
        
        SELECT @CostUnit = (SELECT AccUnit FROM #AccUnit WHERE IDX_NO = @Cnt) 
        
        SELECT @SQL=''
        SELECT @SQL='KPXCM_SESMZStockMonthlyAmt  @xmlDocument=N'''+'<ROOT>'
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
        SELECT @SQL=@SQL+'<CostUnit>'+CONVERT(NVARCHAR(60),@CostUnit)+'</CostUnit>'+CHAR(10)
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
        
        
        
        SELECT @SQL=''
        SELECT @SQL='KPXCM_SESMZStockMonthlyAmt  @xmlDocument=N'''+'<ROOT>'
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
        SELECT @SQL=@SQL+'<CostUnit>'+CONVERT(NVARCHAR(60),@CostUnit)+'</CostUnit>'+CHAR(10)
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
    
    
        IF @Cnt = (SELECT MAX(IDX_NO) FROM #AccUnit) 
        BEGIN
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
    END 
    
    
    
    -- 재고증감차
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT ) 
    SELECT E.ValueText, 
           '040100', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '040100' AND KindSeq = 1010735003) AS NMAC, 
           SUM(A.PreAmt) - SUM(A.StockAmt) - SUM(A.EtcOutAmt)
      FROM #TMPFSData                   AS A 
      LEFT OUTER JOIN _TDABizUnit       AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = A.CostUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor        AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     GROUP BY E.ValueText, F.MinorName
    
    
    
    
    -- 재료비 = 재료비(원가) - 관세등환급액(손익)
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT CC.CDCS
           ,'040200' AS CDAC
           ,CC.NMCS  AS NMCS
           ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '040200' AND KindSeq = 1010735003) AS NMAC
           ,SUM(AMT) AS AMT
      FROM (
                SELECT E.ValueText AS CDCS, 
                       F.MinorName AS NMCS, 
                       SUM(ISNULL(Amt,0)) AS AMT
                  FROM _TESMCProdFMatInput          AS A 
                  LEFT OUTER JOIN _TDAItem          AS ITM WITH(NOLOCK) ON A.CompanySeq = ITM.CompanySeq AND A.MatItemSeq = ITM.ItemSeq 
                  LEFT OUTER JOIN _TDABizUnit       AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = A.CostUnit ) 
                  LEFT OUTER JOIN _TDAUMinorValue   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
                  LEFT OUTER JOIN _TDAUMinorValue   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
                  LEFT OUTER JOIN _TDAUMinor        AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
                  LEFT OUTER JOIN _TDAItemAsset     AS AT WITH(NOLOCK) ON A.CompanySeq = AT.CompanySeq AND ITM.AssetSeq = AT.AssetSeq 
                  LEFT OUTER JOIN _TESMDCostKey     AS CK WITH(NOLOCK) ON ( CK.CompanySeq = @CompanySeq AND CK.CostKeySeq = A.CostKeySeq ) 
                 WHERE A.CompanySeq = @CompanySeq
                   AND CK.CostYM = @YYMM
                   AND AT.SMAssetGrp = 6008006
                 GROUP BY E.ValueText, F.MinorName 
                
                UNION ALL
                
                SELECT E.ValueText AS CDCS, 
                       F.MinorName AS NMCS, 
                       SUM(ISNULL(B.CrAmt,0)) * (-1) AS AMT
                  FROM _TACSlip             AS A 
                             JOIN _TACSlipRow       AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq AND B.SlipMstSeq = A.SlipMstSeq AND B.AccSeq = 4200110 ) 
                  LEFT OUTER JOIN _TDABizUnit       AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = A.AccUnit ) 
                  LEFT OUTER JOIN _TDAUMinorValue   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
                  LEFT OUTER JOIN _TDAUMinorValue   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
                  LEFT OUTER JOIN _TDAUMinor        AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
                 WHERE A.CompanySeq = @CompanySeq
                   AND LEFT(A.AccDate,6) = @YYMM 
                 GROUP BY E.ValueText, F.MinorName 
            ) AS CC   
     GROUP BY CC.CDCS, CC.NMCS 
    
    
    -- 전력용수비 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '040300', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '040300' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '040300' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 연료증기비 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '040400', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '040400' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '040400' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 포장비 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '040500', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '040500' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '040500' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 연구개발비 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '040600', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '040600' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '040600' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
    
    
    -- 기타  
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '040700', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '040700' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '040700' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 운반비  
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '040800', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '040800' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '040800' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
    
    
    
    -- 상품매입 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT CC.CDCS
           ,'040900' AS CDAC
           ,CC.NMCS  AS NMCS
           ,(SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '040900' AND KindSeq = 1010735003) AS NMAC
           ,SUM(AMT) AS AMT
      FROM (
                SELECT E.ValueText AS CDCS, 
                       F.MinorName AS NMCS, 
                       SUM(ISNULL(A.BuyAmt,0)) + SUM(ISNULL(A.EtcInAmt,0)) AS AMT
                  FROM #TMPFSData                   AS A 
                  LEFT OUTER JOIN _TDABizUnit       AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = A.CostUnit ) 
                  LEFT OUTER JOIN _TDAUMinorValue   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
                  LEFT OUTER JOIN _TDAUMinorValue   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
                  LEFT OUTER JOIN _TDAUMinor        AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
                 GROUP BY E.ValueText, F.MinorName 
                
                UNION ALL
                
                SELECT E.ValueText AS CDCS, 
                       F.MinorName AS NMCS, 
                       SUM(ISNULL(B.CrAmt,0)) * (-1) AS AMT
                  FROM _TACSlip             AS A 
                             JOIN _TACSlipRow       AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq AND B.SlipMstSeq = A.SlipMstSeq AND B.AccSeq = 4200210 ) 
                  LEFT OUTER JOIN _TDABizUnit       AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = A.AccUnit ) 
                  LEFT OUTER JOIN _TDAUMinorValue   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
                  LEFT OUTER JOIN _TDAUMinorValue   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
                  LEFT OUTER JOIN _TDAUMinor        AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
                 WHERE A.CompanySeq = @CompanySeq
                   AND LEFT(A.AccDate,6) = @YYMM 
                 GROUP BY E.ValueText, F.MinorName 
            ) AS CC   
     GROUP BY CC.CDCS, CC.NMCS 
    
    

    -- 변동비
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT CDCS, 
           '040000', 
           A.NMCS, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='040000' AND KindSeq=1010735003), 
           SUM(A.AMT)
      FROM #PLAMPF A  
     WHERE A.CDAC BETWEEN '040100' AND '040999'
     GROUP BY A.CDCS,A.NMCS
    
    
    
    -- 한계이익
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT A.CDCS, 
           '050000' AS CDAC , 
           A.NMCS, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='050000' AND KindSeq=1010735003) AS NMAC, 
           ISNULL(B.AMT,0)-ISNULL(C.AMT,0) AS AMT
      FROM #TBase AS A 
      LEFT OUTER JOIN (
                        SELECT CDCS, AMT
                          FROM #PLAMPF
                         WHERE CDAC='030000'
                      ) AS B ON A.CDCS = B.CDCS
      LEFT OUTER JOIN (
                        SELECT CDCS, AMT
                          FROM #PLAMPF
                         WHERE CDAC='040000'
                      ) AS C ON A.CDCS = C.CDCS
    
    
    
    
    
    -- 급여(노무비)
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '060101', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060101' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '060101' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 퇴직급여(노무비)
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '060102', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060102' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '060102' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 복리후생비(노무비)
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '060103', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060103' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '060103' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 

    -- 노무비
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT A.CDCS, 
           '060100', 
           A.NMCS, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='060100' AND KindSeq=1010735003), 
           SUM(A.AMT)
      FROM #PLAMPF AS A 
     WHERE A.CDAC BETWEEN '060101' AND '060199'
     GROUP BY A.CDCS, A.NMCS
    
    
    
    -- 급여(인건비) 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '060201', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060201' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '060201' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 퇴직급여(인건비) 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '060202', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060202' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '060202' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 복리후생비(인건비) 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '060203', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060203' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '060203' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
    
    
    -- 인건비
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT A.CDCS, 
           '060200', 
           A.NMCS, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060200' AND KindSeq=1010735003), 
           SUM(A.AMT)
      FROM #PLAMPF AS A 
     WHERE A.CDAC BETWEEN '060201' AND '060299'
     GROUP BY A.CDCS, A.NMCS
    
    -- 감가상각비
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '060300', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060300' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '060300' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 수선비
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '060400', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060400' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '060400' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 지급수수료
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '060500', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060500' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '060500' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 소모품비
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '060600', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060600' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '060600' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 세금과공과 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '060700', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060700' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '060700' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 임차료 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '060800', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060800' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '060800' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 접대비 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '060900', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060900' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '060900' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 기타 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '061000', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '061000' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '061000' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 용역비 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '061100', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '061100' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '061100' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 보험료 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '061200', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '061200' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '061200' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 무형감가상각비 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '061300', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '061300' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '061300' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
    
    
    -- 도서교육비 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '061600', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '061600' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '061600' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
    
    
    -- 연구개발비  
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '061700', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '061700' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '061700' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 대손상각비   
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '061800', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '061800' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '061800' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    
    -- 고정비 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT CDCS, 
           '060000', 
           A.NMCS, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '060000' AND KindSeq = 1010735003), 
           SUM(A.AMT)
      FROM #PLAMPF AS A  
      LEFT OUTER JOIN KPX_TEISAcc_COA AS B ON B.CompanySeq = @CompanySeq AND A.CDAC = B.CDAC AND B.KindSeq = 1010735003
     WHERE (B.CDACHG ='060000') 
     GROUP BY A.CDCS,A.NMCS 
    
    -- 영업이익 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT A.CDCS, 
           '070000' AS CDAC , 
           A.NMCS, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='070000' AND KindSeq=1010735003) AS NMAC, 
           ISNULL(B.AMT,0)-ISNULL(C.AMT,0) AS AMT
      FROM #TBase AS A 
      LEFT OUTER JOIN (
                        SELECT CDCS, AMT
                          FROM #PLAMPF
                         WHERE CDAC='050000'
                      ) AS B ON A.CDCS = B.CDCS
      LEFT OUTER JOIN (
                        SELECT CDCS, AMT
                          FROM #PLAMPF
                         WHERE CDAC='060000'
                      ) AS C ON A.CDCS = C.CDCS
    
    
    
    -- 이자수익 
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '080100', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '080100' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '080100' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 외환차익  
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '080200', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '080200' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '080200' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 기타  
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '080300', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '080300' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '080300' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
    

  
    -- 영업외수익
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT CDCS, 
           '080000', 
           A.NMCS, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC = '080000' AND KindSeq = 1010735003), 
           SUM(A.AMT)
      FROM #PLAMPF A  
     WHERE A.CDAC BETWEEN '080100' AND '080999'
     GROUP BY A.CDCS,A.NMCS 
    
    
    
    -- 이자비용  
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '090100', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '090100' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '090100' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
     
    -- 외환차손   
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '090200', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '090200' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '090200' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
     
    -- 기타   
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '090300', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '090300' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '090300' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 내부차입이자    
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '090400', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '090400' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '090400' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
     
    -- 금융수수료     
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT )  
    SELECT E.ValueText, 
           '090700', 
           F.MinorName, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '090700' AND KindSeq = 1010735003) AS NMAC, 
           SUM(B.DrAmt) 
      FROM _TACSlip     AS A 
      JOIN _TACSlipRow  AS B WITH(NOLOCK) ON ( B.CompanySeq = A.CompanySeq 
                                           AND B.SlipMstSeq = A.SlipMstSeq 
                                           AND B.AccSeq IN ( 
                                                             SELECT DISTINCT C.AccSeq 
                                                               FROM KPX_TEISAcc_COA          AS A 
                                                               JOIN KPX_TEISAccSub_COA       AS B ON ( B.CompanySeq = A.CompanySeq AND B.Seq = A.Seq ) 
                                                               LEFT OUTER JOIN _TESMBAccount AS C ON ( C.CompanySeq = B.CompanySeq AND B.AccSeq = C.CostAccSeq ) 
                                                              WHERE A.CompanySeq = @CompanySeq  
                                                                AND A.KindSeq = 1010735003 
                                                                AND A.CDAC = '090700' 
                                                           )
                                             ) 
      LEFT OUTER JOIN _TDABizUnit           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = B.AccUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MajorSeq = 1011113 AND D.Serl = 1000003 AND D.ValueSeq = C.BizUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue       AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.MinorSeq AND E.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinor            AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = E.MinorSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) = @YYMM 
     GROUP BY E.ValueText, F.MinorName 
    
    -- 영업외비용
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT ) 
    SELECT CDCS, 
           '090000', 
           A.NMCS, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='090000' AND KindSeq=1010735003), 
           SUM(A.AMT)
      FROM #PLAMPF AS A  
     WHERE A.CDAC BETWEEN '090100' AND '090999'
     GROUP BY A.CDCS, A.NMCS
    
    
    
    -- 세전이익
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT ) 
    SELECT A.CDCS, 
           '100000' AS CDAC, 
           A.NMCS, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq=@CompanySeq AND CDAC='100000' AND KindSeq=1010735003) AS NMAC, 
           (ISNULL(B.AMT,0) + ISNULL(C.AMT,0)) - ISNULL(D.AMT,0) AS AMT
      FROM #TBase AS A 
      LEFT OUTER JOIN (
                        SELECT CDCS, AMT
                          FROM #PLAMPF
                         WHERE CDAC = '070000'
                      )  B ON A.CDCS = B.CDCS
      LEFT OUTER JOIN (
                        SELECT CDCS,AMT
                          FROM #PLAMPF
                         WHERE CDAC = '080000'
                      ) AS C ON A.CDCS = C.CDCS
      LEFT OUTER JOIN (
                        SELECT CDCS,AMT
                          FROM #PLAMPF
                         WHERE CDAC = '090000'
                      ) AS D ON A.CDCS = D.CDCS
    
    
    DECLARE @CompanyRate    DECIMAL(19,5), -- 법인세율
            @ResRate        DECIMAL(19,5) -- 주민세율
    
    SELECT @CompanyRate = ISNULL(B.ValueText,0),
           @ResRate     = ISNULL(C.ValueText,0)
      FROM _TDAUMinorValue              AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.MinorSeq = B.MinorSeq AND B.Serl = 1000002
      LEFT OUTER JOIN _TDAUMinorValue   AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq AND A.MinorSeq=C.MinorSeq AND C.Serl = 1000003          
     WHERE A.CompanySeq = @CompanySeq
       AND A.MajorSeq = 1010690
       AND A.Serl = 1000001
       AND A.ValueText = LEFT(@YYMM,4)
    
    
    

    -- 법인세비용
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT ) 
    SELECT A.CDCS, 
           '110000', 
           A.NMCS, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '110000' AND KindSeq = 1010735003), 
           (ISNULL(A.AMT,0) * @CompanyRate) + (ISNULL(A.AMT,0) * @CompanyRate) * @ResRate    -- ((세전이익*법인세율)+(세전이익*법인세율))*주민세율
      FROM #PLAMPF AS A  
     WHERE A.CDAC = '100000'
     
     

    -- 당기순이익
    INSERT INTO #PLAMPF ( CDCS, CDAC, NMCS, NMAC, AMT ) 
    SELECT A.CDCS, 
           '120000' AS CDAC, 
           A.NMCS, 
           (SELECT NMAC FROM KPX_TEISAcc_COA WHERE CompanySeq = @CompanySeq AND CDAC = '120000' AND KindSeq = 1010735003) AS NMAC, 
           (ISNULL(B.AMT,0) - ISNULL(C.AMT,0)) AS AMT
      FROM #TBase AS A 
      LEFT OUTER JOIN (
                        SELECT CDCS, AMT
                          FROM #PLAMPF
                         WHERE CDAC = '100000'
                      ) AS B ON A.CDCS = B.CDCS
      LEFT OUTER JOIN (
                        SELECT CDCS,AMT
                          FROM #PLAMPF
                         WHERE CDAC = '110000'
                      ) AS C ON A.CDCS = C.CDCS
        
    
    
    INSERT INTO ODS_KPX_HDSLIB_PLAMPF_COA ( CompanySeq, YYMM, CDCS, CDAC, NMCS, NMAC, AMT, DTTMUP )
    SELECT @CompanySeq, 
           @YYMM, 
           AA.CDCS, 
           A.CDAC, 
           AA.NMCS, 
           A.NMAC, 
           ISNULL(B.AMT,0) AS AMT, 
           CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
      FROM KPX_TEISAcc_COA AS  A  
      CROSS JOIN (
                    SELECT MV.ValueText AS CDCS, 
                           M.MinorName AS NMCS 
                      FROM _TDAUMinor AS M 
                      LEFT OUTER JOIN _TDAUMinorValue MV WITH(NOLOCK) ON M.CompanySeq = MV.CompanySeq AND M.MinorSeq = MV.MinorSeq AND MV.Serl = 1000001
                     WHERE M.CompanySeq = @CompanySeq 
                       AND M.MajorSeq = 1011113
                 ) AS  AA
      LEFT OUTER JOIN #PLAMPF AS B WITH(NOLOCK) ON A.CompanySeq = @CompanySeq AND A.CDAC = B.CDAC AND AA.CDCS = B.CDCS
     WHERE A.CompanySeq = @CompanySeq
       AND A.KindSeq = 1010735003
     ORDER BY AA.CDCS, A.CDAC, A.SORTID
   
    IF @CompanySeq = 2 
    BEGIN
        INSERT INTO ODS_KPXCM_HDSLIB_PLAMPF
        SELECT YYMM,CDCS,CDAC,NMCS,NMAC,AMT,DTTMUP FROM ODS_KPX_HDSLIB_PLAMPF_COA WHERE CompanySeq=2 AND YYMM=@YYMM
    END
    
    
    DELETE FROM KPX_EISIFProcStaus_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM AND ProcItemSeq = 1010736017
    INSERT INTO KPX_EISIFProcStaus_COA ( CompanySeq, YYMM, ProcItemSeq, ProcYn, ErrRemark, LastUserSeq, LastDateTime ) 
    SELECT @CompanySeq,@YYMM,1010736018,'1','',@UserSeq,GETDATE() 
    
    
      --RETURN
    /* 마감정보 업데이트 */
    DECLARE @Count INT
    SELECT @Count = CNT FROM ODS_KPX_HDSLIB_HCLCKPF_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM
    
    IF ISNULL(@Count, 0) = 0
    SET @Count = 1
    ELSE 
        
        SET @Count = @Count + 1
        DELETE FROM ODS_KPX_HDSLIB_HCLCKPF_COA WHERE CompanySeq = @CompanySeq AND YYMM = @YYMM
      
    IF @CompanySeq = 2 
    BEGIN
        DELETE FROM ODS_KPXCM_HDSLIB_HCLCKPF WHERE  YYMM = @YYMM
    END
    
    
    INSERT INTO ODS_KPX_HDSLIB_HCLCKPF_COA ( CompanySeq, YYMM, CNT, DTTMUP ) 
    SELECT @CompanySeq, 
           @YYMM, 
           @CNT, 
           CONVERT(NCHAR(8),GETDATE(),112)+LEFT(CONVERT(NVARCHAR(30),GETDATE(),114),2)+ SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),4,2)+SUBSTRING(CONVERT(NVARCHAR(30),GETDATE(),114),7,2) 
    
    IF @CompanySeq = 2 
    BEGIN
        INSERT INTO ODS_KPXCM_HDSLIB_HCLCKPF ( YYMM, CNT, DTTMUP ) 
        SELECT YYMM, CNT, DTTMUP FROM ODS_KPX_HDSLIB_HCLCKPF_COA WHERE CompanySeq = 2 AND YYMM = @YYMM
    END
    
    
    SELECT CNT AS ProcCount, LEFT(DTTMUP,4)+'-'+SUBSTRING(DTTMUP,5,2)+'-'+SUBSTRING(DTTMUP,7,2)+' '+SUBSTRING(DTTMUP,9,2)+':'+SUBSTRING(DTTMUP,11,2)+':'+SUBSTRING(DTTMUP,13,2)  AS ProcDateTime 
      FROM ODS_KPX_HDSLIB_HCLCKPF_COA 
     WHERE CompanySeq = @CompanySeq 
       AND YYMM = @YYMM

    RETURN 
  go
  begin tran 
  exec KPXCM_EISIFMasterData_COA @xmlDocument=N'<ROOT>
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
</ROOT>',@xmlFlags=2,@ServiceSeq=1027957,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1024786
rollback 