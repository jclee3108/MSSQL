  
IF OBJECT_ID('KPX_SACFundDailyPlanInQuerySub') IS NOT NULL   
    DROP PROC KPX_SACFundDailyPlanInQuerySub  
GO  
  
-- v2014.12.23  
  
-- 일자금계획입력(자금일보)-입금내역 조회 by 이재천   
CREATE PROC KPX_SACFundDailyPlanInQuerySub  
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
           A.DrAmt AS CurAmt, 
           A.DrForAmt AS DomAmt, 
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
       AND A.DrAmt <> 0 
       AND (@InOutKind = 0 OR @InOutKind = 1010540001)
    

      
    RETURN  
GO 
