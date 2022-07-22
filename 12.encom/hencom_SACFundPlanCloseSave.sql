  
IF OBJECT_ID('hencom_SACFundPlanCloseSave') IS NOT NULL   
    DROP PROC hencom_SACFundPlanCloseSave  
GO  
    
-- v2017.07.10
  
-- 자금계획마감-저장 by 이재천   
CREATE PROC hencom_SACFundPlanCloseSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #hencom_TACFundPlanClose (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TACFundPlanClose'   
    IF @@ERROR <> 0 RETURN    
    

    INSERT INTO hencom_TACFundPlanClose 
    ( 
        CompanySeq, StdDate, Check1, Check2, Check3, 
        Check4, LastUserSeq, LastDateTime, PgmSeq 
    ) 
    SELECT @CompanySeq, A.StdDate, '0', '0', '0', 
           '0', @UserSeq, GETDATE(), @PgmSeq 
      FROM #hencom_TACFundPlanClose AS A 
     WHERE NOT EXISTS (SELECT 1 FROM hencom_TACFundPlanClose WHERE CompanySeq = @CompanySeq AND StdDate = A.StdDate) 

     
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('hencom_TACFundPlanClose')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'hencom_TACFundPlanClose'    , -- 테이블명        
                  '#hencom_TACFundPlanClose'    , -- 임시 테이블명        
                  'StdDate'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    

    UPDATE A
       SET Check1       = B.Check1, 
           Check2       = B.Check2, 
           Check3       = B.Check3, 
           Check4       = B.Check4, 
           LastUserSeq  = @UserSeq, 
           LastDateTime = GETDATE(), 
           PgmSeq       = @PgmSeq 
      FROM hencom_TACFundPlanClose  AS A 
      JOIN #hencom_TACFundPlanClose AS B ON ( B.StdDate = A.StdDate ) 
     WHERE A.CompanySeq = @CompanySeq 
    
    UPDATE A
       SET CloseTime = CONVERT(NVARCHAR(200),B.LastDateTime,120) 
      FROM #hencom_TACFundPlanClose AS A 
      JOIN hencom_TACFundPlanClose  AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate = A.StdDate ) 
    
    SELECT * FROM #hencom_TACFundPlanClose   
  
    RETURN  
    GO
begin tran 
exec hencom_SACFundPlanCloseSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <StdDate>20170707</StdDate>
    <Check1>1</Check1>
    <Check2>0</Check2>
    <Check3>0</Check3>
    <Check4>0</Check4>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512598,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033922
rollback 