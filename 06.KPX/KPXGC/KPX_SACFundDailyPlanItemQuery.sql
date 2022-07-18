  
IF OBJECT_ID('KPX_SACFundDailyPlanItemQuery') IS NOT NULL   
    DROP PROC KPX_SACFundDailyPlanItemQuery  
GO  
  
-- v2014.12.23  
  
-- 일자금계획입력(자금일보)-SS2 조회 by 이재천   
CREATE PROC KPX_SACFundDailyPlanItemQuery  
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
            @FundDate   NCHAR(8)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @FundDate  = ISNULL( FundDate, '' )  
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (
            FundDate   NCHAR(8)
           )    
    
    SELECT A.Sort,
           A.Summary, 
           A.ExRate, 
           A.CurAmt, 
           A.DomAmt, 
           A.Remark1, 
           A.Remark2, 
           A.SlipSeq, 
           E.BankAccName, 
           G.BankName, 
           G.BankSeq, 
           E.BankAccNo, 
           F.CurrName, 
           B.CurrSeq, 
           H.AccName, 
           B.AccSeq, 
           C.SlipMstID, 
           C.AccDate, 
           B.Summary AS SlipSummary, 
           A.IsReplace, 
           
           A.PlanInSeq
    
      FROM KPX_TACFundDailyPlanIn       AS A 
      LEFT OUTER JOIN _TACSlipRow       AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipSeq = A.SlipSeq ) 
      LEFT OUTER JOIN _TACSlip          AS C ON ( C.CompanySeq = @CompanySeq AND C.SlipMstSeq = B.SlipMstSeq ) 
      LEFT OUTER JOIN _TACSlipRem       AS D ON ( D.CompanySeq = @CompanySeq AND D.SlipSeq = A.SlipSeq AND D.RemSeq = 9046 ) 
      LEFT OUTER JOIN _TDABankAcc       AS E ON ( E.CompanySeq = @CompanySeq AND E.BankAccSeq = D.RemValSeq ) 
      LEFT OUTER JOIN _TDACurr          AS F ON ( F.CompanySeq = @CompanySeq AND F.CurrSeq = B.CurrSeq ) 
      LEFT OUTER JOIN _TDABank          AS G ON ( G.CompanySeq = @CompanySeq AND G.BankSeq = E.BankSeq ) 
      LEFT OUTER JOIN _TDAAccount       AS H ON ( H.CompanySeq = @CompanySeq AND H.AccSeq = B.AccSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.FundDate = @FundDate 
     ORDER BY A.Sort 

RETURN 
GO 
exec KPX_SACFundDailyPlanItemQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <FundDate>20141223</FundDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027052,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021333