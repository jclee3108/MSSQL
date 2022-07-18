  
IF OBJECT_ID('KPX_SHRWorkEmpDailySave') IS NOT NULL   
    DROP PROC KPX_SHRWorkEmpDailySave  
GO  
  
-- v2014.12.23  
  
-- 지역별근무인원등록-저장 by 이재천   
CREATE PROC KPX_SHRWorkEmpDailySave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_THRWorkEmpDaily (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWorkEmpDaily'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THRWorkEmpDaily')    
    
    IF @WorkingTag = 'Del' 
    BEGIN 
        EXEC _SCOMLog @CompanySeq   ,        
              @UserSeq      ,        
              'KPX_THRWorkEmpDaily'    , -- 테이블명        
              '#KPX_THRWorkEmpDaily'    , -- 임시 테이블명        
              'WorkDate,UMWorkCenterSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
              @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    END 
    ELSE 
    BEGIN 
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_THRWorkEmpDaily'    , -- 테이블명        
                      '#KPX_THRWorkEmpDaily'    , -- 임시 테이블명        
                      'Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    END 
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWorkEmpDaily WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        IF @WorkingTag = 'Del' 
        BEGIN 
            
            DELETE B   
              FROM #KPX_THRWorkEmpDaily AS A   
              JOIN KPX_THRWorkEmpDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkDate = A.WorkDate AND B.UMWorkCenterSeq = A.UMWorkCenterSeq )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        END 
        ELSE 
        BEGIN 
            
            DELETE B   
              FROM #KPX_THRWorkEmpDaily AS A   
              JOIN KPX_THRWorkEmpDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.Serl = A.Serl )   
             WHERE A.WorkingTag = 'D'   
               AND A.Status = 0   
              
            IF @@ERROR <> 0  RETURN  
        END 
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWorkEmpDaily WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.EmpSeq = A.EmpSeq,  
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()  
        
          FROM #KPX_THRWorkEmpDaily AS A   
          JOIN KPX_THRWorkEmpDaily AS B ON ( B.CompanySeq = @CompanySeq AND B.Serl = A.Serl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWorkEmpDaily WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO KPX_THRWorkEmpDaily  
        (   
            CompanySeq,Serl,WorkDate,UMWorkCenterSeq,EmpSeq,  
            LastUserSeq,LastDateTime   
        )   
        SELECT @CompanySeq,A.Serl,A.WorkDate,A.UMWorkCenterSeq,A.EmpSeq,  
               @UserSeq,GETDATE()   
          FROM #KPX_THRWorkEmpDaily AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_THRWorkEmpDaily   
      
    RETURN  
go
begin tran 
exec KPX_SHRWorkEmpDailySave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <DeptName />
    <EmpName>가서울</EmpName>
    <EmpSeq>1373</EmpSeq>
    <Serl>11</Serl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <DeptName />
    <EmpName>가월급</EmpName>
    <EmpSeq>1368</EmpSeq>
    <Serl>12</Serl>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027065,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022596
rollback 