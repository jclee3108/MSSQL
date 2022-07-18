  
IF OBJECT_ID('KPXCM_SPDShutDownSave') IS NOT NULL   
    DROP PROC KPXCM_SPDShutDownSave  
GO  
  
-- v2016.04.21  
  
-- SHUT-DOWN일정등록(우레탄)-저장 by 이재천   
CREATE PROC KPXCM_SPDShutDownSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_TPDShutDown (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDShutDown'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TPDShutDown')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TPDShutDown'    , -- 테이블명        
                  '#KPXCM_TPDShutDown'    , -- 임시 테이블명        
                  'SDSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDShutDown WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPXCM_TPDShutDown AS A   
          JOIN KPXCM_TPDShutDown AS B ON ( B.CompanySeq = @CompanySeq AND B.SDSeq = A.SDSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDShutDown WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.FactUnit = A.FactUnit,  
               B.SrtDate = A.SrtDate,  
               B.EndDate = A.EndDate,  
               B.SrtTimeSeq = A.SrtTimeSeq,  
               B.EndTimeSeq = A.EndTimeSeq,  
               B.Remark = A.Remark,  
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
                 
          FROM #KPXCM_TPDShutDown AS A   
          JOIN KPXCM_TPDShutDown AS B ON ( B.CompanySeq = @CompanySeq AND B.SDSeq = A.SDSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDShutDown WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPXCM_TPDShutDown  
        (   
            CompanySeq,SDSeq,FactUnit,SrtDate,EndDate,  
            SrtTimeSeq,EndTimeSeq,Remark,LastUserSeq,LastDateTime,  
            PgmSeq   
        )   
        SELECT @CompanySeq,A.SDSeq,A.FactUnit,A.SrtDate,A.EndDate,  
               A.SrtTimeSeq,A.EndTimeSeq,A.Remark,@UserSeq,GETDATE(),  
               @PgmSeq   
          FROM #KPXCM_TPDShutDown AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
      SELECT * FROM #KPXCM_TPDShutDown   
      
    RETURN  
    go
    begin tran
    exec KPXCM_SPDShutDownSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <EmdTimeSeq>1012820002</EmdTimeSeq>
    <EndDate>20160422</EndDate>
    <EndTime>15:00</EndTime>
    <FactUnit>1</FactUnit>
    <Remark>Test</Remark>
    <SDSeq>2</SDSeq>
    <SrtDate>20160421</SrtDate>
    <SrtTime>07:00</SrtTime>
    <SrtTimeSeq>1012820001</SrtTimeSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1036643,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030021
rollback 