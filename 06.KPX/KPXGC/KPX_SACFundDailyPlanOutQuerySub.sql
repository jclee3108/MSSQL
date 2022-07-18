  
IF OBJECT_ID('KPX_SACFundDailyPlanOutQuerySub') IS NOT NULL   
    DROP PROC KPX_SACFundDailyPlanOutQuerySub  
GO  
  
-- v2014.12.23  
  
-- 일자금계획입력(자금일보)-출금내역 조회 by 이재천   
CREATE PROC KPX_SACFundDailyPlanOutQuerySub  
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
            @FundDate   NCHAR(8), 
            @InOutKind  INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FundDate  = ISNULL( FundDate, '' ),  
           @InOutKind = ISNULL( InOutKind, 0 )  
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FundDate   NCHAR(8), 
            InOutKind  INT  
           )    
    
    CREATE TABLE #AccSeq 
    ( 
        AccSeq  INT, 
        AccName NVARCHAR(100) 
    ) 
    
    INSERT INTO #AccSeq ( AccSeq, AccName ) 
    SELECT B.ValueSeq, C.AccName
      FROM _TDAUMinor AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAAccount       AS C ON ( C.CompanySeq = @CompanySeq AND C.AccSeq = B.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1010524
    
    SELECT E.BankAccName, 
           G.BankName, 
           G.BankSeq, 
           E.BankAccNo, 
           F.CurrName, 
           A.CurrSeq, 
           A.ExRate, 
           A.CrAmt AS CurAmt, 
           A.CrForAmt AS DomAmt, 
           B.AccName, 
           A.AccSeq, 
           C.SlipMstID, 
           C.AccDate, 
           A.Summary AS SlipSummary, 
           A.SlipSeq 
           
      FROM _TACSlipRow              AS A 
      JOIN #AccSeq                  AS B ON ( B.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TACSlip      AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipMstSeq = A.SlipMstSeq ) 
      LEFT OUTER JOIN _TACSlipRem   AS D ON ( D.CompanySeq = @CompanySeq AND D.SlipSeq = A.SlipSeq AND RemSeq = 9046 ) 
      LEFT OUTER JOIN _TDABankAcc   AS E ON ( E.CompanySeq = @CompanySeq AND E.BankAccSeq = D.RemValSeq ) 
      LEFT OUTER JOIN _TDACurr      AS F ON ( F.CompanySeq = @CompanySeq AND F.CurrSeq = A.CurrSeq ) 
      LEFT OUTER JOIN _TDABank      AS G ON ( G.CompanySeq = @CompanySeq AND G.BankSeq = E.BankSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.AccDate = @FundDate 
       AND A.CrAmt <> 0 
       AND (@InOutKind = 0 OR @InOutKind = 1010540002)
    

      
    RETURN  
GO 
exec KPX_SACFundDailyPlanOutQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <FundDate>20141223</FundDate>
    <InOutKind />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027052,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021333