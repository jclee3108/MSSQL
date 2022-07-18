  
IF OBJECT_ID('KPXCM_SEQYearRepairResultRegCHESave') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairResultRegCHESave  
GO  
  
-- v2015.07.17  
  
-- 연차보수실적등록-저장 by 이재천   
CREATE PROC KPXCM_SEQYearRepairResultRegCHESave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPXCM_TEQYearRepairResultRegCHE (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQYearRepairResultRegCHE'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQYearRepairResultRegCHE')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQYearRepairResultRegCHE'    , -- 테이블명        
                  '#KPXCM_TEQYearRepairResultRegCHE'    , -- 임시 테이블명        
                  'ResultSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairResultRegCHE WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.ResultDate     = A.ResultDate,  
               B.EmpSeq         = A.EmpSeq,  
               B.DeptSeq        = A.DeptSeq,  
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
          FROM #KPXCM_TEQYearRepairResultRegCHE AS A   
          JOIN KPXCM_TEQYearRepairResultRegCHE AS B ON ( B.CompanySeq = @CompanySeq AND A.ResultSeq = B.ResultSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairResultRegCHE WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXCM_TEQYearRepairResultRegCHE  
        (   
            CompanySeq, ResultSeq, ResultDate, EmpSeq, DeptSeq, 
            LastUserSeq, LastDateTime, PgmSeq 
        )   
        SELECT @CompanySeq, ResultSeq, ResultDate, EmpSeq, DeptSeq, 
               @UserSeq, GETDATE(), @PgmSeq 
          FROM #KPXCM_TEQYearRepairResultRegCHE AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
    
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #KPXCM_TEQYearRepairResultRegCHE   
    
    RETURN  
GO
begin tran 

exec KPXCM_SEQYearRepairResultRegCHESave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <DeptName>사업개발팀2</DeptName>
    <DeptSeq>1300</DeptSeq>
    <EmpName>이재천</EmpName>
    <EmpSeq>2028</EmpSeq>
    <ResultDate>20150717</ResultDate>
    <ResultSeq>1</ResultSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030930,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025775

select * from KPXCM_TEQYearRepairResultRegCHE 

rollback 