  
IF OBJECT_ID('KPX_SSETieDisasterTakeCHESave') IS NOT NULL   
    DROP PROC KPX_SSETieDisasterTakeCHESave  
GO  
  
-- v2014.12.26  
  
-- 무재해운동-저장 by 이재천   
CREATE PROC KPX_SSETieDisasterTakeCHESave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TSETieDisasterTake (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TSETieDisasterTake'   
    IF @@ERROR <> 0 RETURN    
    
    IF NOT EXISTS (SELECT 1 FROM KPX_TSETieDisasterTake WHERE CompanySeq = @CompanySeq AND YYMM = (SELECT YYMM FROM #KPX_TSETieDisasterTake))
    BEGIN
        UPDATE A 
           SET WorkingTag = 'A' 
          FROM #KPX_TSETieDisasterTake AS A 
    END 
      
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSETieDisasterTake')    

    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TSETieDisasterTake'    , -- 테이블명        
                  '#KPX_TSETieDisasterTake'    , -- 임시 테이블명        
                  'YYMM'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명 
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TSETieDisasterTake WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        
        UPDATE B   
           SET B.YYWorkSUM = A.YearWorkHour, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE() 
               
          FROM #KPX_TSETieDisasterTake AS A   
          JOIN KPX_TSETieDisasterTake AS B ON ( B.CompanySeq = @CompanySeq AND B.YYMM = A.YYMM )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0 
          
        IF @@ERROR <> 0  RETURN  
        
        UPDATE B   
           SET B.DisasterCount = A.DisasterCount, 
               B.NonWkCount = A.NonWkCount, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE() 
          FROM #KPX_TSETieDisasterTake AS A   
          JOIN KPX_TSETieDisasterTake AS B ON ( B.CompanySeq = @CompanySeq AND LEFT(B.YYMM,4) = LEFT(A.YYMM,4) )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0 
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TSETieDisasterTake WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        
        INSERT INTO KPX_TSETieDisasterTake  
        (   
            CompanySeq, YYMM, DisasterCount, NonWkCount, YYWorkSUM, 
            LastUserSeq, LastDateTime   
        )   
        SELECT @CompanySeq, A.YYMM, A.DisasterCount, A.NonWkCount, A.YearWorkHour, 
               @UserSeq, GETDATE()   
          FROM #KPX_TSETieDisasterTake AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    SELECT * FROM #KPX_TSETieDisasterTake   
    
    RETURN  
GO 
begin tran 

exec KPX_SSETieDisasterTakeCHESave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <DisasterCount>0.00000</DisasterCount>
    <NonWkCount>0.00000</NonWkCount>
    <Result1>0.00000</Result1>
    <Result2>0.00000</Result2>
    <YearWorkHour>24.00000</YearWorkHour>
    <YearWorkHour2>24.00000</YearWorkHour2>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027117,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021464

rollback 