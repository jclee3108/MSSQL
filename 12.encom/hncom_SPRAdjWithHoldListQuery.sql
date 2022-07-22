     
IF OBJECT_ID('hncom_SPRAdjWithHoldListQuery') IS NOT NULL       
    DROP PROC hncom_SPRAdjWithHoldListQuery      
GO      
      
-- v2017.02.08
      
-- 원천세신고목록-조회 by 이재천  
CREATE PROC hncom_SPRAdjWithHoldListQuery      
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
            @StdYM      NCHAR(6), 
            @EndDateFr  NCHAR(8), 
            @EndDateTo  NCHAR(8), 
            @BizSeq     INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYM      = ISNULL( StdYM     , '' ),  
           @EndDateFr  = ISNULL( EndDateFr , '' ),  
           @EndDateTo  = ISNULL( EndDateTo , '' ),  
           @BizSeq     = ISNULL( BizSeq    , 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
              StdYM      NCHAR(6),
              EndDateFr  NCHAR(8),
              EndDateTo  NCHAR(8),
              BizSeq     INT 
           )    
    
    -- SS1
    SELECT B.MinorName AS UMTypeName, 
           A.UMTypeSeq, 
           A.EmpName, 
           A.EmpCnt, 
           A.TotAmt, 
           A.TaxEmpCnt, 
           A.TaxAmt, 
           A.TaxShortageAmt, 
           A.IncomeTaxAmt, 
           A.ResidentTaxAmt, 
           A.RuralTaxAmt,
           A.AdjSeq
      FROM hncom_TAdjWithHoldList   AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMTypeSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.IsSum = '0' -- 화면에서 저장한 데이터 
       AND A.StdYM = @StdYM 
       AND A.BizSeq = @BizSeq 
     ORDER BY B.MinorSort
    
    -- SS2 
    SELECT B.MinorName AS UMTypeName, 
           A.UMTypeSeq, 
           A.EmpName, 
           A.EmpCnt, 
           A.TotAmt, 
           A.TaxEmpCnt, 
           A.TaxAmt, 
           A.TaxShortageAmt, 
           A.IncomeTaxAmt, 
           A.ResidentTaxAmt, 
           A.RuralTaxAmt,
           A.AdjSeq
      FROM hncom_TAdjWithHoldList   AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMTypeSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.IsSum = '1' -- HRM 집계한 데이터 
       AND A.StdYM = @StdYM 
       AND A.BizSeq = @BizSeq 
     ORDER BY B.MinorSort
      
    RETURN  
GO
exec hncom_SPRAdjWithHoldListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BizSeq>1</BizSeq>
    <BizName>한라엔컴</BizName>
    <StdYM>201702</StdYM>
    <EndDateFr>20170108</EndDateFr>
    <EndDateTo>20170208</EndDateTo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511151,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032789
