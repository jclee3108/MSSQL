
IF OBJECT_ID('KPX_SSLReceiptPlanDomCreate') IS NOT NULL 
    DROP PROC KPX_SSLReceiptPlanDomCreate
GO 

-- v2014.12.19 
        
-- 채권수금계획(내수) (수금계획생성) by이재천      
CREATE PROC KPX_SSLReceiptPlanDomCreate        
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT = 0,        
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0        
AS   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,        
            -- 조회조건         
            @PlanYM     NVARCHAR(6)  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument         
    
    SELECT @PlanYM = ISNULL( PlanYM, '' )   
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )             
        
      WITH (PlanYM NVARCHAR(6))           
    
    SELECT A.SMReceiptKind,  
           A.CustSeq,   
           A.BizUnit, 
           MAX(A.CustName) AS CustName,   
           MAX(A.CustNo) AS CustNo, 
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM = LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS ReceiptAmt,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,1,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS ReceiptAmt1,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,2,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS ReceiptAmt2,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,3,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS ReceiptAmt3,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,4,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS ReceiptAmt4,   
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,5,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS ReceiptAmt5,   
           --SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND CONVERT(NVARCHAR(6),DATEADD(MONTH,6,@PlanYM +'01'),112) = LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS ReceiptAmt6,   
             
           SUM(ISNULL(CASE WHEN A.SMCustStatus <> 2004001 THEN A.RemDomAmt ELSE 0 END,0)) AS BadBondAmt, -- 불량채권  
           SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM > LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) AS LongBondAmt -- 장기채권  
      
      INTO #TEMP     
      FROM KPX_fnSLReceiptPlanDom(@CompanySeq, 0, 8918001) AS A  
     GROUP BY A.CustSeq, A.SMReceiptKind, A.BizUnit  
    HAVING SUM(ISNULL(CASE WHEN A.SMCustStatus <> 2004001 THEN A.RemDomAmt ELSE 0 END,0)) <> 0     
        OR SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM > LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) <> 0     
        OR SUM(ISNULL(CASE WHEN A.SMCustStatus = 2004001 AND @PlanYM <= LEFT(A.ReceiptDate,6) THEN A.RemDomAmt ELSE 0 END,0)) <> 0     
    
    
    SELECT MAX(C.BizUnitName) AS BizUnitName, -- 사업부문
           A.BizUnit, 
           MAX(A.CustName) AS CustName, -- 거래처    
           MAX(A.CustNo) AS Custo, -- 거래처번호 
           A.CustSeq, -- 거래처코드   
           A.SMReceiptKind AS SMInType,   
           MAX(B.MinorName) AS SMInTypeName, -- 입금구분  
           SUM(A.ReceiptAmt) AS ReceiptAmt,  
           SUM(A.ReceiptAmt1) AS ReceiptAmt1,  
           SUM(A.ReceiptAmt2) AS ReceiptAmt2,  
           SUM(A.ReceiptAmt3) AS ReceiptAmt3,  
           SUM(A.ReceiptAmt4) AS ReceiptAmt4,  
           SUM(A.ReceiptAmt5) AS ReceiptAmt5,  
           --SUM(A.ReceiptAmt6) AS ReceiptAmt6,   
           SUM(A.BadBondAmt) AS BadBondAmt,   
           SUM(A.LongBondAmt) AS LongBondAmt,   
           SUM(A.ReceiptAmt) + SUM(A.ReceiptAmt1) + SUM(A.ReceiptAmt2) + SUM(A.ReceiptAmt3) + SUM(A.ReceiptAmt4) +   
           SUM(A.ReceiptAmt5) + SUM(A.BadBondAmt) + SUM(A.LongBondAmt) AS SumAmt,   
           CASE WHEN ISNULL(MAX(C.BizUnitName),'') = '' THEN 2 ELSE 1 END Sort   
      
      FROM #TEMP AS A   
      LEFT OUTER JOIN _TDASMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SMReceiptKind )   
      LEFT OUTER JOIN _TDABizUnit   AS C ON ( C.CompanySeq = @CompanySeq AND C.BizUnit = A.BizUnit ) 
     GROUP BY A.BizUnit, A.CustSeq, A.SMReceiptKind  
     ORDER BY Sort, BizUnitName, CustName, SMInType   
    
    RETURN 
GO 
exec KPX_SSLReceiptPlanDomCreate @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PlanYM>201407</PlanYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026940,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021450




--select DISTINCT CustSeq, BillDate From _TSLBill where companyseq = 1 and left(billdate,6) = '201407'

--select * From _TSLSales where companyseq = 1 