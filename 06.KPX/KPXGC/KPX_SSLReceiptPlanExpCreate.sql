
IF OBJECT_ID('KPX_SSLReceiptPlanExpCreate') IS NOT NULL
    DROP PROC KPX_SSLReceiptPlanExpCreate
GO 

-- v2014.12.19 
        
-- 채권수금계획(수출)(수금계획생성) by이재천      
CREATE PROC KPX_SSLReceiptPlanExpCreate        
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT = 0,        
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0        
AS   
      
    DECLARE @docHandle  INT,        
            -- 조회조건         
            @PlanYM     NVARCHAR(6)  
        
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument         
            
    SELECT @PlanYM = ISNULL( PlanYM, '' )   
               
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )             
        
      WITH (PlanYM NVARCHAR(6))          
    
    SELECT A.BizUnit, 
           A.CustSeq,    
           A.CurrSeq,     
           MAX(A.CustNo) AS CustNo, 
           MAX(A.CustName) AS CustName,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM = LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS ReceiptDomAmt,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,1,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS ReceiptDomAmt1,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,2,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS ReceiptDomAmt2,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,3,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS ReceiptDomAmt3,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,4,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS ReceiptDomAmt4,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,5,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS ReceiptDomAmt5,   
             
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM = LEFT(A.ReceiptDate,6) THEN A.RemCurAmt ELSE 0 END,0)) AS ReceiptAmt,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,1,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemCurAmt ELSE 0 END,0)) AS ReceiptAmt1,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,2,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemCurAmt ELSE 0 END,0)) AS ReceiptAmt2,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,3,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemCurAmt ELSE 0 END,0)) AS ReceiptAmt3,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,4,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemCurAmt ELSE 0 END,0)) AS ReceiptAmt4,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,5,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemCurAmt ELSE 0 END,0)) AS ReceiptAmt5,   
             
           SUM(ISNULL(CASE WHEN A.SMCustStatus <> 2004001 THEN A.RemDomAmt ELSE 0 END,0)) AS BadBondDomAmt, -- 불량채권(원화)  
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM > LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS LongBondDomAmt, -- 장기채권(원화)  
           SUM(ISNULL(CASE WHEN A.SMCustStatus <> 2004001 THEN A.RemCurAmt ELSE 0 END,0)) AS BadBondAmt, -- 불량채권(원화)  
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM > LEFT(A.ReceiptDate,6) THEN A.RemCurAmt ELSE 0 END,0)) AS LongBondAmt -- 장기채권  
      
      INTO #TEMP     
      FROM KPX_fnSLReceiptPlanDom(@CompanySeq, 0, 8918002) AS A     
     GROUP BY A.CustSeq, A.CurrSeq, A.BizUnit
      HAVING SUM(ISNULL(CASE WHEN A.SMCustStatus <> 2004001 THEN A.RemDomAmt ELSE 0 END,0)) <> 0     
        OR SUM(ISNULL(CASE WHEN A.SMCustStatus <> 2004001 THEN A.RemCurAmt ELSE 0 END,0)) <> 0     
        OR SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM > LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) <> 0     
        OR SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM > LEFT(A.ReceiptDate,6) THEN A.RemCurAmt ELSE 0 END,0)) <> 0    
        OR SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM <= LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) <> 0     
        OR SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM <= LEFT(A.ReceiptDate,6) THEN A.RemCurAmt ELSE 0 END,0)) <> 0     
    
    -- 최종조회  
    SELECT MAX(D.BizUnitName) AS BizUnitName, -- 사업부문    
           A.BizUnit AS BizUnit,   
           MAX(A.CustName) AS CustName, -- 거래처    
           MAX(A.CustNo) AS CustNo, 
           A.CustSeq, -- 거래처코드   
           A.CurrSeq, -- 통화코드   
           MAX(C.CurrName) AS CurrName, -- 통화  
             
           --외화  
           SUM(A.ReceiptAmt) AS ReceiptAmt,  
           SUM(A.ReceiptAmt1) AS ReceiptAmt1,  
           SUM(A.ReceiptAmt2) AS ReceiptAmt2,  
           SUM(A.ReceiptAmt3) AS ReceiptAmt3,  
           SUM(A.ReceiptAmt4) AS ReceiptAmt4,  
           SUM(A.ReceiptAmt5) AS ReceiptAmt5,  
           SUM(A.BadBondAmt) AS BadBondAmt,   
           SUM(A.LongBondAmt) AS LongBondAmt,   
           SUM(A.ReceiptAmt) + SUM(A.ReceiptAmt1) + SUM(A.ReceiptAmt2) + SUM(A.ReceiptAmt3) + SUM(A.ReceiptAmt4) +   
           SUM(A.ReceiptAmt5) + SUM(A.BadBondAmt) + SUM(A.LongBondAmt) AS SumAmt,    
             
           -- 원화  
           SUM(A.ReceiptDomAmt) AS ReceiptDomAmt,  
           SUM(A.ReceiptDomAmt1) AS ReceiptDomAmt1,  
           SUM(A.ReceiptDomAmt2) AS ReceiptDomAmt2,  
           SUM(A.ReceiptDomAmt3) AS ReceiptDomAmt3,  
           SUM(A.ReceiptDomAmt4) AS ReceiptDomAmt4,  
           SUM(A.ReceiptDomAmt5) AS ReceiptDomAmt5,  
           SUM(A.BadBondDomAmt) AS BadBondDomAmt,   
           SUM(A.LongBondDomAmt) AS LongBondDomAmt,   
           SUM(A.ReceiptDomAmt) + SUM(A.ReceiptDomAmt1) + SUM(A.ReceiptDomAmt2) + SUM(A.ReceiptDomAmt3) + SUM(A.ReceiptDomAmt4) +   
           SUM(A.ReceiptDomAmt5) + SUM(A.BadBondDomAmt) + SUM(A.LongBondDomAmt) AS SumDomAmt,   
           CASE WHEN ISNULL(MAX(D.BizUnitName),'') = '' THEN 2 ELSE 1 END AS Sort   
          
      FROM #TEMP AS A     
      LEFT OUTER JOIN _TDACurr  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CurrSeq = A.CurrSeq )   
      LEFT OUTER JOIN _TDABizUnit  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.BizUnit = A.BizUnit )   
     GROUP BY A.BizUnit , A.CustSeq, A.CurrSeq  
     ORDER BY Sort, BizUnitName, CustName, CurrSeq   
    
    RETURN   
GO 
exec KPX_SSLReceiptPlanExpCreate @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026951,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021451