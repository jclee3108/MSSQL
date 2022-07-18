  
IF OBJECT_ID('DTI_SESMCSlipAdjQuery') IS NOT NULL   
    DROP PROC DTI_SESMCSlipAdjQuery  
GO  
  
-- v2013.12.18  
  
-- 관리회계전표작성_DTI(조회) by이재천   
CREATE PROC DTI_SESMCSlipAdjQuery  
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
            @CostUnit   INT, 
            @AccSeq     INT, 
            @CostYMTo   NCHAR(6), 
            @CostYMFr   NCHAR(6) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @CostUnit    = ISNULL( CostUnit, 0 ),  
           @AccSeq      = ISNULL( AccSeq, 0 ), 
           @CostYMTo    = ISNULL( CostYMTo, '' ),  
           @CostYMFr    = ISNULL( CostYMFr, '' )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH ( 
                CostUnit   INT, 
                AccSeq     INT, 
                CostYMTo   NCHAR(6),
                CostYMFr   NCHAR(6) 
           )    
      
    -- 최종조회   
    SELECT A.CostYM, 
           A.Serl, 
           A.AccSeq, 
           C.AccName, 
           A.UMCostType, 
           D.MinorName AS UMCostTypeName,  
           A.CCtrSeq, 
           B.CCtrName, 
           A.DrAmt, 
           A.CrAmt, 
           A.Summary, 
           A.OrgSlipSeq AS SlipSeq, 
           E.SlipID AS SlipNo, 
           CASE WHEN E.DrAmt <> 0 THEN E.DrAmt ELSE E.CrAmt END AS SlipAmt 
           
           
      FROM DTI_TESMCSlipAdj         AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDACCtr      AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CCtrSeq = A.CCtrSeq ) 
      LEFT OUTER JOIN _TDAAccount   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMCostType ) 
      LEFT OUTER JOIN _TACSlipRow   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.SlipSeq = A.OrgSlipSeq ) 
    
     WHERE A.CompanySeq = @CompanySeq  
       AND @CostUnit = A.CostUnit 
       AND (@AccSeq = 0 OR  A.AccSeq = @AccSeq) 
       AND A.CostYM BETWEEN @CostYMFR AND @CostYMTo

    RETURN  
GO
exec DTI_SESMCSlipAdjQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <CostYMFr>201301</CostYMFr>
    <AccSeq />
    <CostYMTo>201312</CostYMTo>
    <CostUnit>1</CostUnit>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019994,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016860


--select * from _TDAUMinor where companyseq = 1 and minorseq = 4001001