  
IF OBJECT_ID('hncom_SPRAdjWithHoldListCheck') IS NOT NULL   
    DROP PROC hncom_SPRAdjWithHoldListCheck  
GO  
  
-- v2017.02.08
      
-- 원천세신고목록-체크 by 이재천  
CREATE PROC hncom_SPRAdjWithHoldListCheck  
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
      
    CREATE TABLE #hncom_TAdjWithHoldList( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hncom_TAdjWithHoldList'   
    IF @@ERROR <> 0 RETURN     
    
    DECLARE @MaxSeq INT 

    SELECT @MaxSeq = (SELECT MAX(AdjSeq) FROM hncom_TAdjWithHoldList)

    UPDATE A
       SET AdjSeq = ISNULL(@MaxSeq,0) + A.DataSeq 
      FROM #hncom_TAdjWithHoldList AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
    
    SELECT * FROM #hncom_TAdjWithHoldList 
      
    RETURN  
    GO
begin tran
exec hncom_SPRAdjWithHoldListCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpName />
    <EmpCnt>1</EmpCnt>
    <TotAmt>1</TotAmt>
    <TaxEmpCnt>1</TaxEmpCnt>
    <TaxAmt>1</TaxAmt>
    <TaxShortageAmt>1</TaxShortageAmt>
    <IncomeTaxAmt>1</IncomeTaxAmt>
    <ResidentTaxAmt>1</ResidentTaxAmt>
    <RuralTaxAmt>1</RuralTaxAmt>
    <AdjSeq />
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <BizSeq>1</BizSeq>
    <StdYM>201702</StdYM>
    <EndDateFr>20170108</EndDateFr>
    <EndDateTo>20170208</EndDateTo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1511151,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1032789
rollback 