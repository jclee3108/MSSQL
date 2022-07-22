IF OBJECT_ID('hencom_SPUDelvItemAnalysisQuery') IS NOT NULL 
    DROP PROC hencom_SPUDelvItemAnalysisQuery
GO 

-- v2017.04.24 

/************************************************************  
  설  명 - 데이터-구매매입분석_hencom : 조회  
  작성일 - 20151124  
  작성자 - 영림원  
 ************************************************************/  
 CREATE PROC dbo.hencom_SPUDelvItemAnalysisQuery                 
  @xmlDocument   NVARCHAR(MAX) ,              
  @xmlFlags      INT  = 0,              
  @ServiceSeq    INT  = 0,              
  @WorkingTag    NVARCHAR(10)= '',                    
  @CompanySeq    INT  = 1,              
  @LanguageSeq   INT  = 1,              
  @UserSeq       INT  = 0,              
  @PgmSeq        INT  = 0           
       
 AS          
    
     DECLARE @docHandle        INT,  
             @YMFrom           NCHAR(8) ,  
             @YMTo             NCHAR(8) ,  
             @UMItemClassLSeq  INT ,  
             @UMItemClassMSeq  INT ,  
             @UMItemClassSSeq  INT ,  
             @DeptSeq          INT ,
             @ItemName         NVARCHAR(200) ,  
             @CustName         NVARCHAR(200) ,  
             @DeliCustName     NVARCHAR(200) ,
             @CompanyNo       NVARCHAR(100) 
    
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
   
     SELECT  @DeptSeq          = DeptSeq           ,
             @YMFrom           = YMFrom            ,  
             @YMTo             = YMTo              ,  
             @UMItemClassLSeq  = UMItemClassLSeq   ,  
             @UMItemClassMSeq  = UMItemClassMSeq   ,  
             @UMItemClassSSeq  = UMItemClassSSeq   ,
             @CustName           = CustName,
             @DeliCustName       = DeliCustName,
             @ItemName           = ItemName
  
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
     WITH (  DeptSeq           INT ,   
             YMFrom            NCHAR(8) ,  
             YMTo              NCHAR(8) ,  
             UMItemClassLSeq   INT ,  
             UMItemClassMSeq   INT ,  
             UMItemClassSSeq   INT ,  
             CustName        NVARCHAR(200),
             DeliCustName    NVARCHAR(200),
             ItemName        NVARCHAR(200)
          )
    
  /*0나누기 에러 경고 처리*/          
     SET ANSI_WARNINGS OFF          
     SET ARITHIGNORE ON          
     SET ARITHABORT OFF          

/* 법인관리의 법인등록번호로 한라엔컴과 대한산업을 구분함.
한라엔컴(1411110002605)은 품목자산분류가 원자재만 조회. 
대한산업( )은 모두 조회.*/

    SELECT @CompanyNo = CompanyNo FROM _TCACompany
    
    SELECT 
           x.CustSeq, 
           x.DeptSeq,
           x.ProdDistrictSeq, 
           x.DeliCustSeq,
           x.SalesCustSeq,
           x.ItemSeq, 
           x.StartDate,
           x.IsStop,
           x.UMPayMethod,
           x.DeliUMPayMethod,
           CASE WHEN (SELECT MAX(StartDate)   
                        FROM hencom_TPUBASEBuyPriceItem   
                       WHERE X.CompanySeq = CompanySeq   
                         AND X.CustSeq = CustSeq 
                         AND X.DeptSeq = DeptSeq   
                         AND X.ProdDistrictSeq = ProdDistrictSeq 
                         AND ISNULL(X.DeliCustSeq, 0) = ISNULL(DeliCustSeq, 0)
                         AND ISNULL(X.SalesCustSeq, 0) = ISNULL(SalesCustSeq, 0)
                         AND X.ItemSeq = ItemSeq) = X.StartDate THEN '99991231'  
           ELSE
           (SELECT CONVERT(NCHAR(8),DATEADD(D, -1, MIN(StartDate)),112) 
              FROM hencom_TPUBASEBuyPriceItem
             WHERE X.CompanySeq = CompanySeq
               AND X.CustSeq = CustSeq 
               AND X.DeptSeq = DeptSeq 
               AND X.ProdDistrictSeq = ProdDistrictSeq 
               AND X.ItemSeq = ItemSeq 
               AND ISNULL(X.DeliCustSeq, 0) = ISNULL(DeliCustSeq, 0)
               AND ISNULL(X.SalesCustSeq, 0) = ISNULL(SalesCustSeq, 0)
               AND X.StartDate < StartDate) END AS EndDate,        -- 적용종료일
           CASE WHEN X.StartDate = (SELECT TOP 1 StartDate 
                                      FROM hencom_TPUBASEBuyPriceItem WITH(NOLOCK)
                                     WHERE CompanySeq = X.CompanySeq
                                       AND ItemSeq = X.ItemSeq
                                       AND CustSeq = X.CustSeq
                                       AND DeptSeq = X.DeptSeq
                                       AND ProdDistrictSeq = X.ProdDistrictSeq
                                       AND ISNULL(DeliCustSeq, 0) = ISNULL(X.DeliCustSeq, 0)
                                       AND ISNULL(SalesCustSeq, 0) = ISNULL(X.SalesCustSeq, 0)
                                     ORDER BY StartDate DESC ) THEN '1' END AS IsLast     -- 최종여부
      INTO #hencom_TPUBASEBuyPriceItem 
      FROM hencom_TPUBASEBuyPriceItem AS X 
     WHERE X.CompanySeq = @CompanySeq

     SELECT  A.DeptSeq,  
             A.CustSeq,  
             B.ItemSeq,  
             B.UnitSeq,  
             C.ProdDistrictSeq, --산지  
             C.DeliCustSeq, --운송처  
             L.ValueSeq          AS ItemClassLSeq,  -- 품목대분류    
             K.ValueSeq          AS ItemClassMSeq,  -- 품목중분류  
             IC.UMItemClass      AS ItemClassSSeq, -- 품목소분류    
             BBP.UMPayMethod ,--매입처결제조건  
             BBP.DeliUMPayMethod , --운송처결제조건  
             SUM(ISNULL(Qty,0))  AS Qty ,  
             SUM(ISNULL(C.PuAmt,0)) AS PuAmt , --매입금액  
             SUM(ISNULL(C.PuVat,0)) AS PuVat , --매입부가세  
             SUM(ISNULL(C.PuAmt,0)) AS PuTotAmt , --합계금액  
             SUM(ISNULL(C.DeliChargeAmt,0)) AS DeliChargeAmt , --운반비  
             SUM(ISNULL(C.DeliChargeVat,0)) AS DeliChargeVat , --운송비부가세  
 --            SUM(ISNULL(C.DeliChargeAmt,0)) AS DeliTotAmt --운송비합계  
 --            SUM(ISNULL(C.DeliChargeAmt,0)) + SUM(ISNULL(C.DeliChargeVat,0)) AS DeliTotAmt --운송비합계  
             T.PuPrice AS PuPrice, --실품대
             T.DeliChargePrice AS DeliPrice --운송비
     INTO #TMPData  
     FROM _TPUDelv AS A  
     LEFT OUTER JOIN _TPUDelvItem AS B ON B.CompanySeq = A.CompanySeq AND B.DelvSeq = A.DelvSeq  
     LEFT OUTER JOIN hencom_TPUDelvItemAdd AS C ON C.CompanySeq = B.CompanySeq AND C.DelvSeq = B.DelvSeq AND C.DelvSerl = B.DelvSerl  
     LEFT OUTER JOIN _TDAItemClass  AS IC WITH(NOLOCK) ON IC.CompanySeq = B.CompanySeq   
      AND IC.ItemSeq = B.ItemSeq   
                                           AND IC.UMajorItemClass IN (2001,2004)  
     LEFT OUTER JOIN _TDAUMinor  AS H WITH(NOLOCK) ON H.CompanySeq = IC.CompanySeq  
                               AND H.MajorSeq = LEFT( IC.UMItemClass, 4 )   
                                                 AND H.MinorSeq = IC.UMItemClass  
     LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON K.CompanySeq = H.CompanySeq   
                                                     AND K.MajorSeq IN (2001,2004)   
                                               AND K.MinorSeq = H.MinorSeq  
                                                     AND K.Serl IN (1001,2001)  
     LEFT OUTER JOIN _TDAUMinorValue AS L WITH(NOLOCK) ON L.CompanySeq  = K.CompanySeq  
                                                     AND L.MajorSeq IN (2002,2005)   
                                                     AND L.MinorSeq = K.ValueSeq  
                                                     AND L.Serl = 2001   
     LEFT OUTER JOIN hencom_TPUDelvItemAdd AS T ON ( T.CompanySeq = @CompanySeq AND T.DelvSeq = B.DelvSeq AND T.DelvSerl = B.DelvSerl )
     LEFT OUTER JOIN #hencom_TPUBASEBuyPriceItem AS BBP ON BBP.CustSeq = A.CustSeq    
                                                       AND BBP.DeptSeq = A.DeptSeq    
                                                       AND BBP.ProdDistrictSeq = C.ProdDistrictSeq    
                                                       AND ISNULL(BBP.DeliCustSeq, 0) = ISNULL(C.DeliCustSeq, 0)    
                                                       AND ISNULL(BBP.SalesCustSeq, 0) = ISNULL(C.SalesCustSeq, 0)    
                                                       AND BBP.ItemSeq = B.ItemSeq    
                                                       AND (A.DelvDate BETWEEN BBP.StartDate AND BBP.EndDate)   
     LEFT OUTER JOIN _TDACust AS CT ON CT.CompanySeq = @CompanySeq AND CT.CustSeq = A.CustSeq
     LEFT OUTER JOIN _TDACust AS DLCust ON DLCust.CompanySeq = @CompanySeq AND DLCust.CustSeq = C.DeliCustSeq
     LEFT OUTER JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = B.ItemSeq
     WHERE A.CompanySeq = @CompanySeq   
     AND (@UMItemClassLSeq = 0 OR L.ValueSeq = @UMItemClassLSeq )  
     AND (@UMItemClassMSeq = 0 OR K.ValueSeq  = @UMItemClassMSeq )   
     AND (@UMItemClassSSeq = 0 OR IC.UMItemClass  = @UMItemClassSSeq )        
     AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq   )        
 --    AND (@ItemSeq = 0 OR B.ItemSeq  = @ItemSeq  )      
     AND (@CustName = '' OR CT.CustName LIKE @CustName + '%' )  
     AND (@DeliCustName = '' OR DLCust.CustName LIKE @DeliCustName + '%' )  
     AND (@ItemName = '' OR I.ItemName LIKE @ItemName + '%' )    
     AND A.DelvDate BETWEEN CASE WHEN @YMFrom = '' THEN A.DelvDate ELSE @YMFrom END   
                                 AND CASE WHEN @YMTo = '' THEN A.DelvDate ELSE @YMTo END  
     AND ((@CompanyNo = '1411110002605' AND I.AssetSeq = 6) OR @CompanyNo <> '1411110002605') --한라엔컴은 품목자산분류: 원자재만 조회
     GROUP BY A.DeptSeq,A.CustSeq,B.ItemSeq,B.UnitSeq,C.ProdDistrictSeq, C.DeliCustSeq,L.ValueSeq , K.ValueSeq ,IC.UMItemClass ,BBP.UMPayMethod, BBP.DeliUMPayMethod ,T.PuPrice ,T.DeliChargePrice     
   
   
 --  select * from #TMPData return
     SELECT  0 AS Sort,  
             M.DeptSeq,  
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq) AS DeptName ,  
             M.CustSeq,  
             C.CustName AS CustName ,  
             M.ItemSeq,  
             I.ItemName AS ItemName,  
             I.ItemNo AS ItemNo ,  
             M.UnitSeq,  
             (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = @CompanySeq AND UnitSeq = M.UnitSeq ) AS UnitName ,  
             M.ProdDistrictSeq, --산지  
             (SELECT ProdDistirct FROM hencom_TPUPurchaseArea WHERE CompanySeq = @CompanySeq AND ProdDistrictSeq = M.ProdDistrictSeq) AS Location , --산지
			 M.DeliCustSeq, --운송처  
  (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = M.DeliCustSeq ) AS DeliCustName , --운송처명              
             M.ItemClassLSeq,  -- 품목대분류    
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = M.ItemClassLSeq ) AS UMItemClassLName ,  
             M.ItemClassMSeq,  -- 품목중분류  
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = M.ItemClassMSeq ) AS UMItemClassMName ,  
             M.ItemClassSSeq, -- 품목소분류    
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = M.ItemClassSSeq ) AS UMItemClassSName ,  
             M.UMPayMethod ,--매입처결제조건  
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = M.UMPayMethod ) AS UMPayMethodName , --매입처결제조건  
             M.DeliUMPayMethod,  
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = M.DeliUMPayMethod ) AS DeliUMPayMethodName ,--운송사결제조건  
             M.Qty ,  
             M.PuAmt , --매입금액  
             M.PuVat , --매입부가세  
             M.PuTotAmt , --합계금액  
             M.PuPrice   AS PuPrice, --실품대
             M.DeliPrice AS DeliPrice , --운송비 
             ISNULL(M.PuPrice,0) + ISNULL(M.DeliPrice,0)     AS TotPrice, --단가계(실품대+운송비)
             M.DeliChargeAmt             AS DeliTotAmt , --운송비합계(부가세제외)
             M.PuAmt + M.DeliChargeAmt   AS TotAmt --합계금액  
     INTO #TMPRowData  
     FROM #TMPData AS M  
     LEFT OUTER JOIN _TDACust AS C ON C.CompanySeq = @CompanySeq AND C.CustSeq = M.CustSeq  
     LEFT OUTER JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = M.ItemSeq  
     ORDER BY M.DeptSeq  
   
     SELECT *   
     INTO #TMPResult
     FROM #TMPRowData  
     
     UNION ALL  
     
     SELECT  1 AS Sort,  
             M.DeptSeq,  
              (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = M.DeptSeq) AS DeptName ,  
             0 AS CustSeq,  
             '' AS CustName ,  
             0 AS ItemSeq,  
             '' AS ItemName,  
             '' AS ItemNo ,  
             0 AS UnitSeq,  
             '' AS UnitName ,  
             0 AS ProdDistrictSeq, --산지  
             '' AS Location, --산지  
             0 AS DeliCustSeq, --운송처  
             '' AS DeliCustName, --운송처명              
             0 AS ItemClassLSeq,  -- 품목대분류    
             '소계' AS UMItemClassLName ,  
             0 AS ItemClassMSeq,  -- 품목중분류  
            '' AS UMItemClassMName ,  
             0 AS ItemClassSSeq, -- 품목소분류    
             '' AS UMItemClassSName ,  
             0 AS UMPayMethod ,--매입처결제조건  
             '' AS UMPayMethodName , --매입처결제조건  
             0 AS DeliUMPayMethod,  
            '' AS DeliUMPayMethodName ,--운송사결제조건  
             SUM(ISNULL(M.Qty,0))        AS Qty ,  
             SUM(ISNULL(M.PuAmt,0))      AS PuAmt, --매입금액  
             SUM(ISNULL(M.PuVat,0))      AS PuVat, --매입부가세  
             SUM(ISNULL(M.PuTotAmt,0))   AS PuTotAmt , --합계금액  
             SUM(ISNULL(M.PuPrice,0))    AS PuPrice, --실품대
             SUM(ISNULL(M.DeliPrice,0))  AS DeliPrice , --운송비 
             SUM(M.TotPrice)               AS TotPrice, --단가계(실품대+운송비)
             SUM(ISNULL(M.DeliTotAmt,0)) AS DeliTotAmt , --운송비합계(부가세제외) 
             SUM(ISNULL(M.TotAmt,0))     AS TotAmt --합계금액 from #TMPRowData  
     FROM #TMPRowData AS M  
     GROUP BY M.DeptSeq
   
     SELECT * FROM #TMPResult  
     ORDER BY DeptSeq,Sort  

RETURN
go
exec hencom_SPUDelvItemAnalysisQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <YMFrom>20170301</YMFrom>
    <YMTo>20170424</YMTo>
    <DeptSeq>28</DeptSeq>
    <ItemName />
    <CustName />
    <UMItemClassLSeq />
    <UMItemClassMSeq />
    <UMItemClassSSeq>2004005</UMItemClassSSeq>
    <DeliCustName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033340,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027619