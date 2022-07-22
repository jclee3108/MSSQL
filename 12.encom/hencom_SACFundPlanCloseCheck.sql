  
IF OBJECT_ID('hencom_SACFundPlanCloseCheck') IS NOT NULL   
    DROP PROC hencom_SACFundPlanCloseCheck  
GO  
    
-- v2017.07.10
  
-- 자금계획마감-체크 by 이재천 
CREATE PROC hencom_SACFundPlanCloseCheck  
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
      
    CREATE TABLE #hencom_TACFundPlanClose( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACFundPlanClose'   
    IF @@ERROR <> 0 RETURN     
    
    -- 체크1, 정기분대금지급계획이 존재하지 않습니다. 다시 조회 후 처리하시기바립니다.
    UPDATE A
       SET Result = '정기분대금지급계획이 존재하지 않습니다. 다시 조회 후 처리하시기바립니다.', 
           Status = 1234, 
           MessageType = 1234
      FROM #hencom_TACFundPlanClose AS A 
     WHERE NOT EXISTS (SELECT 1 FROM hencom_TACPaymentPricePlan WHERE CompanySeq = @CompanySeq AND StdDate = A.StdDate ) 
       AND A.Check1 = '1' 
    -- 체크1, END 

    -- 체크2, 자금이체계획내역이 존재하지 않습니다. 다시 조회 후 처리하시기바립니다.
    UPDATE A
       SET Result = '자금이체계획내역이 존재하지 않습니다. 다시 조회 후 처리하시기바립니다.', 
           Status = 1234, 
           MessageType = 1234
      FROM #hencom_TACFundPlanClose AS A 
     WHERE NOT EXISTS (SELECT 1 FROM hencom_TACFundSendPlan WHERE CompanySeq = @CompanySeq AND StdDate = A.StdDate ) 
       AND A.Check2 = '1' 
    -- 체크2, END 

    -- 체크3, 도급비지급내역이 존재하지 않습니다. 다시 조회 후 처리하시기바립니다.
    UPDATE A
       SET Result = '도급비지급내역이 존재하지 않습니다. 다시 조회 후 처리하시기바립니다.', 
           Status = 1234, 
           MessageType = 1234
      FROM #hencom_TACFundPlanClose AS A 
     WHERE NOT EXISTS (SELECT 1 FROM hencom_TACSubContrAmtList WHERE CompanySeq = @CompanySeq AND StdDate = A.StdDate ) 
       AND A.Check3 = '1' 
    -- 체크3, END 

    -- 체크4, 전도금내역이 존재하지 않습니다. 다시 조회 후 처리하시기바립니다.
    UPDATE A
       SET Result = '전도금내역이 존재하지 않습니다. 다시 조회 후 처리하시기바립니다.', 
           Status = 1234, 
           MessageType = 1234
      FROM #hencom_TACFundPlanClose AS A 
     WHERE NOT EXISTS (SELECT 1 FROM hencom_TACSendAmtList WHERE CompanySeq = @CompanySeq AND StdDate = A.StdDate ) 
       AND A.Check4 = '1' 
    -- 체크4, END 

    SELECT * FROM #hencom_TACFundPlanClose   
      
    RETURN  
    GO
begin tran 
exec hencom_SACFundPlanCloseCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <StdDate>20170710</StdDate>
    <Check1>1</Check1>
    <Check2>0</Check2>
    <Check3>0</Check3>
    <Check4>0</Check4>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512598,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033922
rollback 