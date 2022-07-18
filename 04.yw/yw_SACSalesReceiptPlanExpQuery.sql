  
IF OBJECT_ID('yw_SACSalesReceiptPlanExpQuery') IS NOT NULL   
    DROP PROC yw_SACSalesReceiptPlanExpQuery  
GO  
  
-- v2013.12.16 
  
-- 채권수금계획(수출)_yw(조회) by이재천   
CREATE PROC yw_SACSalesReceiptPlanExpQuery  
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
            @PlanYM     NVARCHAR(6), 
            @DeptSeq    INT, 
            @CurrSeq    INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PlanYM   = ISNULL( PlanYM, '' ),  
           @DeptSeq  = ISNULL( DeptSeq, 0 ), 
           @CurrSeq = ISNULL( CurrSeq, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            PlanYM     NVARCHAR(6), 
            DeptSeq    INT, 
            CurrSeq    INT 
           )
      
    -- 최종조회   
    SELECT A.PlanYM, 
           A.Serl, 
           A.DeptSeq, 
           A.CustSeq, 
           B.DeptName, 
           D.CustName,
           A.CurrSeq, 
           E.CurrName, -- 통화
           -- 외화
           ISNULL(A.PlanAmt,0) AS PlanAmt, 
           ISNULL(A.ReceiptAmt,0) AS ReceiptAmt, 
           ISNULL(A.ReceiptAmt1,0) AS ReceiptAmt1, 
           ISNULL(A.ReceiptAmt2,0) AS ReceiptAmt2, 
           ISNULL(A.ReceiptAmt3,0) AS ReceiptAmt3, 
           ISNULL(A.ReceiptAmt4,0) AS ReceiptAmt4, 
           ISNULL(A.ReceiptAmt5,0) AS ReceiptAmt5, 
           ISNULL(A.ReceiptAmt6,0) AS ReceiptAmt6, 
           ISNULL(A.LongBondAmt,0) AS LongBondAmt, 
           ISNULL(A.BadBondAmt,0) AS BadBondAmt, 
           ISNULL(A.PlanAmt,0) + ISNULL(A.ReceiptAmt,0) + ISNULL(A.ReceiptAmt1,0) + ISNULL(A.ReceiptAmt2,0) + ISNULL(A.ReceiptAmt3,0) + 
           ISNULL(A.ReceiptAmt4,0) + ISNULL(A.ReceiptAmt5,0) + ISNULL(A.ReceiptAmt6,0) + ISNULL(A.LongBondAmt,0) + ISNULL(A.BadBondAmt,0) AS SumAmt, 
           
           -- 원화
           ISNULL(A.PlanDomAmt,0) AS PlanDomAmt, 
           ISNULL(A.ReceiptDomAmt,0) AS ReceiptDomAmt, 
           ISNULL(A.ReceiptDomAmt1,0) AS ReceiptDomAmt1, 
           ISNULL(A.ReceiptDomAmt2,0) AS ReceiptDomAmt2, 
           ISNULL(A.ReceiptDomAmt3,0) AS ReceiptDomAmt3, 
           ISNULL(A.ReceiptDomAmt4,0) AS ReceiptDomAmt4, 
           ISNULL(A.ReceiptDomAmt5,0) AS ReceiptDomAmt5, 
           ISNULL(A.ReceiptDomAmt6,0) AS ReceiptDomAmt6, 
           ISNULL(A.LongBondDomAmt,0) AS LongBondDomAmt, 
           ISNULL(A.BadBondDomAmt,0) AS BadBondDomAmt, 
           ISNULL(A.PlanDomAmt,0) + ISNULL(A.ReceiptDomAmt,0) + ISNULL(A.ReceiptDomAmt1,0) + ISNULL(A.ReceiptDomAmt2,0) + ISNULL(A.ReceiptDomAmt3,0) + 
           ISNULL(A.ReceiptDomAmt4,0) + ISNULL(A.ReceiptDomAmt5,0) + ISNULL(A.ReceiptDomAmt6,0) + ISNULL(A.LongBondDomAmt,0) + ISNULL(A.BadBondDomAmt,0) AS SumDomAmt
           
      FROM yw_TACSalesReceiptPlan   AS A WITH(NOLOCK)
      LEFT OUTER JOIN _TDADept      AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDASMinor    AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMInType ) 
      LEFT OUTER JOIN _TDACust      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDACurr      AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CurrSeq = A.CurrSeq ) 
    
     WHERE A.CompanySeq = @CompanySeq  
       AND @PlanYM = A.PlanYM 
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)   
       AND (@CurrSeq = 0 OR A.CurrSeq = @CurrSeq) 
       AND A.PlanType = '2'
     ORDER BY DeptName, CustName, CurrSeq
      
    RETURN  
GO
exec yw_SACSalesReceiptPlanExpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <PlanYM>201312</PlanYM>
    <DeptSeq />
    <SMInType />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019843,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016756