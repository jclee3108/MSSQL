  
IF OBJECT_ID('KPX_SHRWelMediItemSave') IS NOT NULL   
    DROP PROC KPX_SHRWelMediItemSave  
GO  
  
-- v2014.12.02  
  
-- 의료비신청- 품목 저장 by 이재천   
CREATE PROC KPX_SHRWelMediItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    CREATE TABLE #KPX_THRWelMediItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_THRWelMediItem'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_THRWelMediItem')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_THRWelMediItem'    , -- 테이블명        
                  '#KPX_THRWelMediItem'    , -- 임시 테이블명        
                  'WelMediSeq,WelMediSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명 
    
    -- DELETE 
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelMediItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN 
        
        DELETE B   
          FROM #KPX_THRWelMediItem AS A   
          JOIN KPX_THRWelMediItem AS B ON ( B.CompanySeq = @CompanySeq AND A.WelMediSeq = B.WelMediSeq AND A.WelMediSerl = B.WelMediSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
    END 
    
    
    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelMediItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN 
        
        UPDATE B   
           SET B.FamilyName = A.FamilyName,  
               B.UMRelSeq = A.UMRelSeq,   
               B.MedicalName = A.MedicalName, 
               B.BegDate = A.BegDate,  
               B.EndDate = A.EndDate,   
               B.MediAmt = A.MediAmt, 
               B.NonPayAmt   = A.NonPayAmt,
               B.LastUserSeq = @UserSeq, 
               B.LastDateTime = GETDATE() 
          FROM #KPX_THRWelMediItem AS A   
          JOIN KPX_THRWelMediItem AS B ON ( B.CompanySeq = @CompanySeq AND A.WelMediSeq = B.WelMediSeq AND A.WelMediSerl = B.WelMediSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_THRWelMediItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_THRWelMediItem  
        (   
            CompanySeq,WelMediSeq,WelMediSerl,FamilyName,UMRelSeq,
            MedicalName,BegDate,EndDate,MediAmt,NonPayAmt,
            LastUserSeq,LastDateTime
        )   
        SELECT @CompanySeq, A.WelMediSeq, A.WelMediSerl, A.FamilyName, A.UMRelSeq,
               A.MedicalName, A.BegDate, A.EndDate, A.MediAmt, A.NonPayAmt,
               @UserSeq, GETDATE()
          FROM #KPX_THRWelMediItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_THRWelMediItem   
      
    RETURN  
go
 begin tran 
 exec KPX_SHRWelMediItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BegDate>20141201</BegDate>
    <EndDate>20141201</EndDate>
    <FamilyName>143124</FamilyName>
    <HEmpAmt>9900.00000</HEmpAmt>
    <MediAmt>10000.00000</MediAmt>
    <MedicalName>11</MedicalName>
    <NonPayAmt>100.00000</NonPayAmt>
    <UMRelName>부</UMRelName>
    <UMRelSeq>1010450001</UMRelSeq>
    <WelMediSeq>28</WelMediSeq>
    <WelMediSerl>2</WelMediSerl>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BegDate>20141211</BegDate>
    <EndDate>20141211</EndDate>
    <FamilyName>1231</FamilyName>
    <HEmpAmt>9900.00000</HEmpAmt>
    <MediAmt>10000.00000</MediAmt>
    <MedicalName>11</MedicalName>
    <NonPayAmt>100.00000</NonPayAmt>
    <UMRelName>부</UMRelName>
    <UMRelSeq>1010450001</UMRelSeq>
    <WelMediSeq>28</WelMediSeq>
    <WelMediSerl>3</WelMediSerl>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026386,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022105

--select *From KPX_THRWelMediItem 
--select *From KPX_THRWelMediItemLog 
rollback 