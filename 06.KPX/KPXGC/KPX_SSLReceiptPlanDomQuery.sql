
IF OBJECT_ID('KPX_SSLReceiptPlanDomQuery') IS NOT NULL
    DROP PROC KPX_SSLReceiptPlanDomQuery
GO 

-- v2014.12.19    
    
-- 채권수금계획(내수)-조회 by 이재천     
CREATE PROC KPX_SSLReceiptPlanDomQuery  
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
            @PlanYM     NVARCHAR(6),   
            @BizUnit    INT,   
            @SMInType   INT   
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
    
    SELECT @PlanYM   = ISNULL( PlanYM, '' ),    
           @BizUnit  = ISNULL( BizUnit, 0 ),   
           @SMInType = ISNULL( SMInType, 0 )   
        
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (  
            PlanYM     NVARCHAR(6),   
            BizUnit    INT,   
            SMInType   INT   
           )  
    
    -- 최종조회     
    SELECT A.PlanYM,   
           A.Serl,   
           A.BizUnit,   
           A.CustSeq,   
           B.BizUnitName,   
           D.CustName,   
           D.CustNo, 
           C.MinorName AS SMInTypeName,   
           A.SMInType,   
           ISNULL(A.PlanDomAmt,0) AS PlanAmt,   
           ISNULL(A.ReceiptDomAmt,0) AS ReceiptAmt,   
           ISNULL(A.ReceiptDomAmt1,0) AS ReceiptAmt1,   
           ISNULL(A.ReceiptDomAmt2,0) AS ReceiptAmt2,   
           ISNULL(A.ReceiptDomAmt3,0) AS ReceiptAmt3,   
           ISNULL(A.ReceiptDomAmt4,0) AS ReceiptAmt4,   
           ISNULL(A.ReceiptDomAmt5,0) AS ReceiptAmt5,   
           ISNULL(A.LongBondDomAmt,0) AS LongBondAmt,   
           ISNULL(A.BadBondDomAmt,0) AS BadBondAmt,   
           ISNULL(A.PlanDomAmt,0) + ISNULL(A.ReceiptDomAmt,0) + ISNULL(A.ReceiptDomAmt1,0) + ISNULL(A.ReceiptDomAmt2,0) + ISNULL(A.ReceiptDomAmt3,0) +   
           ISNULL(A.ReceiptDomAmt4,0) + ISNULL(A.ReceiptDomAmt5,0) + ISNULL(A.LongBondDomAmt,0) + ISNULL(A.BadBondDomAmt,0) AS SumAmt,   
           CASE WHEN ISNULL(B.BizUnitName,'') = '' THEN 2 ELSE 1 END AS Sort   
             
      FROM KPX_TLReceiptPlanDom     AS A   
      LEFT OUTER JOIN _TDABizUnit   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit )   
      LEFT OUTER JOIN _TDASMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMInType )   
      LEFT OUTER JOIN _TDACust      AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq )   
     WHERE A.CompanySeq = @CompanySeq    
       AND @PlanYM = A.PlanYM   
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit )   
       AND (@SMInType = 0 OR A.SMInType = @SMInType)   
       AND A.PlanType = '1'  
     ORDER BY Sort, BizUnitName, CustName, SMInType  
      
    RETURN    