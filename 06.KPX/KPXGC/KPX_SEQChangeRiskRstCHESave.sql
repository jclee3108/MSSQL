  
IF OBJECT_ID('KPX_SEQChangeRiskRstCHESave') IS NOT NULL   
    DROP PROC KPX_SEQChangeRiskRstCHESave  
GO  
  
-- v2014.12.12  
  
-- 변경위험성평가등록-저장 by 이재천   
CREATE PROC KPX_SEQChangeRiskRstCHESave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPX_TEQChangeRiskRstCHE (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TEQChangeRiskRstCHE'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TEQChangeRiskRstCHE')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TEQChangeRiskRstCHE'    , -- 테이블명        
                  '#KPX_TEQChangeRiskRstCHE'    , -- 임시 테이블명        
                  'RiskRstSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQChangeRiskRstCHE WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPX_TEQChangeRiskRstCHE AS A   
          JOIN KPX_TEQChangeRiskRstCHE AS B ON ( B.CompanySeq = @CompanySeq AND B.RiskRstSeq = A.RiskRstSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQChangeRiskRstCHE WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.RiskRstDate = A.RiskRstDate,  
               B.UMMaterialChange = A.UMMaterialChange,  
               B.UMFlashPoint = A.UMFlashPoint,  
               B.UMPPM = A.UMPPM,  
               B.UMMg = A.UMMg,  
               B.UMHeat = A.UMHeat,  
               B.UMDriveUp = A.UMDriveUp,  
               B.UMDriveDown = A.UMDriveDown,  
               B.UMDrivePress = A.UMDrivePress,  
               B.IsProdUp = A.IsProdUp,  
               B.IsChangeProd = A.IsChangeProd,  
               B.IsFlare = A.IsFlare,  
               B.UMChangeLevel = A.UMChangeLevel,  
               B.Remark = A.Remark,  
               B.FileSeq = A.FileSeq,  
               B.ChangeRequestSeq = A.ChangeRequestSeq,  
                 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
        
          FROM #KPX_TEQChangeRiskRstCHE AS A   
          JOIN KPX_TEQChangeRiskRstCHE AS B ON ( B.CompanySeq = @CompanySeq AND B.RiskRstSeq = A.RiskRstSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
      IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TEQChangeRiskRstCHE WHERE WorkingTag = 'A' AND Status  = 0 )    
    BEGIN    
          
        INSERT INTO KPX_TEQChangeRiskRstCHE  
        (   
            CompanySeq,RiskRstSeq,RiskRstDate,UMMaterialChange,UMFlashPoint,  
            UMPPM,UMMg,UMHeat,UMDriveUp,UMDriveDown,  
            UMDrivePress,IsProdUp,IsChangeProd,IsFlare,UMChangeLevel,  
            Remark,FileSeq,ChangeRequestSeq,LastUserSeq,LastDateTime  
               
        )   
        SELECT @CompanySeq,A.RiskRstSeq,A.RiskRstDate,A.UMMaterialChange,A.UMFlashPoint,  
               A.UMPPM,A.UMMg,A.UMHeat,A.UMDriveUp,A.UMDriveDown,  
               A.UMDrivePress,A.IsProdUp,A.IsChangeProd,A.IsFlare,A.UMChangeLevel,  
               A.Remark,A.FileSeq,A.ChangeRequestSeq,@UserSeq,GETDATE()  
                  
          FROM #KPX_TEQChangeRiskRstCHE AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TEQChangeRiskRstCHE   
      
    RETURN  
GO 
begin tran 

exec KPX_SEQChangeRiskRstCHESave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <IsChangeProd>1</IsChangeProd>
    <IsFlare>1</IsFlare>
    <IsProdUp>1</IsProdUp>
    <Remark>eeee</Remark>
    <RiskRstDate>20141212</RiskRstDate>
    <UMChangeLevel>1010470002</UMChangeLevel>
    <UMDriveDown>1010468001</UMDriveDown>
    <UMDrivePress>1010469001</UMDrivePress>
    <UMDriveUp>1010467001</UMDriveUp>
    <UMFlashPoint>1010463001</UMFlashPoint>
    <UMHeat>1010466001</UMHeat>
    <UMMaterialChange>1010462001</UMMaterialChange>
    <UMMg>1010465001</UMMg>
    <UMPPM>1010464001</UMPPM>
    <RiskRstSeq>1</RiskRstSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026700,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022351

rollback     