  
IF OBJECT_ID('KPXCM_SEQYearRepairReceiptRegCHESave') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReceiptRegCHESave
GO  
  
-- v2015.07.15  
  
-- 연차보수접수등록-저장 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReceiptRegCHESave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPXCM_TEQYearRepairReceiptRegCHE (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQYearRepairReceiptRegCHE'   
    IF @@ERROR <> 0 RETURN    
      
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQYearRepairReceiptRegCHE')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQYearRepairReceiptRegCHE'    , -- 테이블명        
                  '#KPXCM_TEQYearRepairReceiptRegCHE'    , -- 임시 테이블명        
                  'ReceiptRegSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairReceiptRegCHE WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.ReceiptRegDate = A.ReceiptRegDate, 
               B.EmpSeq = A.EmpSeq, 
               B.DeptSeq = A.DeptSeq, 
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq    
          FROM #KPXCM_TEQYearRepairReceiptRegCHE AS A   
          JOIN KPXCM_TEQYearRepairReceiptRegCHE  AS B ON ( B.CompanySeq = @CompanySeq AND A.ReceiptRegSeq = B.ReceiptRegSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairReceiptRegCHE WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXCM_TEQYearRepairReceiptRegCHE  
        (   
            CompanySeq, ReceiptRegSeq, ReceiptRegDate, EmpSeq, DeptSeq, 
            LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, ReceiptRegSeq, ReceiptRegDate, EmpSeq, DeptSeq, 
               @UserSeq, GETDATE(), @PgmSeq   
          FROM #KPXCM_TEQYearRepairReceiptRegCHE AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #KPXCM_TEQYearRepairReceiptRegCHE   
      
    RETURN  
GO
begin tran 
exec KPXCM_SEQYearRepairReceiptRegCHESave @xmlDocument=N'<ROOT>
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
    <ReceiptRegDate>20150715</ReceiptRegDate>
    <ReceiptRegSeq>1</ReceiptRegSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030864,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025743

--select * from KPXCM_TEQYearRepairReceiptRegCHE 
rollback 