  
IF OBJECT_ID('KPX_SSLMonthSalesPlanDlgCheck') IS NOT NULL   
    DROP PROC KPX_SSLMonthSalesPlanDlgCheck  
GO  
  
-- v2014.11.14  
  
-- 월간판매계획입력Dlg-체크 by 이재천   
CREATE PROC KPX_SSLMonthSalesPlanDlgCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
    
    CREATE TABLE #KPX_TSLMonthSalesPlanRev( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TSLMonthSalesPlanRev'   
    IF @@ERROR <> 0 RETURN     
    
    -- 체크 1, 전 차수의 데이터가 존재하지 않습니다.
    IF NOT EXISTS ( SELECT 1
                     FROM #KPX_TSLMonthSalesPlanRev AS A 
                     JOIN KPX_TSLMonthSalesPlan     AS B ON ( B.CompanySeq = @CompanySeq 
                                                          AND B.BizUnit = A.BizUnit 
                                                          AND B.PlanYM = A.PlanYM 
                                                          AND B.PlanRev = RIGHT('0' + CONVERT(NVARCHAR(2),CONVERT(INT,A.PlanRev)-1),2) ) 
                  )
       AND (SELECT PlanRev FROM #KPX_TSLMonthSalesPlanRev) <> '01'
    BEGIN
        UPDATE A
           SET Result = '전 차수의 데이터가 존재하지 않습니다.', 
               Status = 1234, 
               MessageType = 1234
          FROM #KPX_TSLMonthSalesPlanRev AS A 
    END                   
    -- 체크 1, END 

    
    SELECT * FROM #KPX_TSLMonthSalesPlanRev   
      
    RETURN  
GO
exec KPX_SSLMonthSalesPlanDlgCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BizUnitName>이상정-본사</BizUnitName>
    <PlanYM>201411</PlanYM>
    <PlanRev>12</PlanRev>
    <BizUnit>2</BizUnit>
    <IsApply>0</IsApply>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025833,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021712