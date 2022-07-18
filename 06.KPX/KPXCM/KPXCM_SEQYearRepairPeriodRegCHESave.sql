  
IF OBJECT_ID('KPXCM_SEQYearRepairPeriodRegCHESave') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairPeriodRegCHESave  
GO  
  
-- v2015.07.13  
  
-- 연차보수기간등록-저장 by 이재천   
CREATE PROC KPXCM_SEQYearRepairPeriodRegCHESave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPXCM_TEQYearRepairPeriodCHE (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQYearRepairPeriodCHE'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQYearRepairPeriodCHE')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQYearRepairPeriodCHE'    , -- 테이블명        
                  '#KPXCM_TEQYearRepairPeriodCHE'    , -- 임시 테이블명        
                  'RepairSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairPeriodCHE WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        DELETE B   
          FROM #KPXCM_TEQYearRepairPeriodCHE AS A   
          JOIN KPXCM_TEQYearRepairPeriodCHE  AS B ON ( B.CompanySeq = @CompanySeq AND A.RepairSeq = B.RepairSeq ) 
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairPeriodCHE WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.DeptSeq        = A.DeptSeq, 
               B.EmpSeq         = A.EmpSeq, 
               B.RepairName     = A.RepairName     ,  
               B.RepairFrDate   = A.RepairFrDate     ,  
               B.RepairToDate   = A.RepairToDate     ,  
               B.ReceiptFrDate  = A.ReceiptFrDate     ,  
               B.ReceiptToDate  = A.ReceiptToDate     ,  
               B.RepairCfmYn    = A.RepairCfmYn     ,  
               B.ReceiptCfmyn   = A.ReceiptCfmyn     ,  
               B.Remark         = A.Remark     ,  
               B.LastDateTime     = GETDATE(), 
               B.LastUserSeq     = @UserSeq
          FROM #KPXCM_TEQYearRepairPeriodCHE AS A   
          JOIN KPXCM_TEQYearRepairPeriodCHE  AS B ON ( B.CompanySeq = @CompanySeq AND A.RepairSeq = B.RepairSeq ) 
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairPeriodCHE WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXCM_TEQYearRepairPeriodCHE  
        (   
            CompanySeq, RepairSeq, RepairYear, FactUnit, Amd, 
            EmpSeq, DeptSeq, RepairName, RepairFrDate, RepairToDate, 
            ReceiptFrDate, ReceiptToDate, RepairCfmYn, ReceiptCfmyn, Remark, 
            LastDateTime, LastUserSeq
        )   
        SELECT @CompanySeq, RepairSeq, RepairYear, FactUnit, Amd + 1, 
               EmpSeq, DeptSeq, RepairName, RepairFrDate, RepairToDate, 
               ReceiptFrDate, ReceiptToDate, RepairCfmYn, ReceiptCfmyn, Remark, 
               GETDATE(), @UserSeq 
          FROM #KPXCM_TEQYearRepairPeriodCHE AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    UPDATE A 
       SET Amd = Amd + 1 
      FROM #KPXCM_TEQYearRepairPeriodCHE AS A 
    
    SELECT * FROM #KPXCM_TEQYearRepairPeriodCHE   
    
    RETURN  
GO
begin tran 
exec KPXCM_SEQYearRepairPeriodRegCHESave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <RepairYear>2015</RepairYear>
    <Amd>4</Amd>
    <RepairName>3434</RepairName>
    <RepairFrDate>20150701</RepairFrDate>
    <RepairToDate>20150731</RepairToDate>
    <ReceiptFrDate>20150701</ReceiptFrDate>
    <ReceiptToDate>20150731</ReceiptToDate>
    <RepairCfmYn>0</RepairCfmYn>
    <ReceiptCfmyn>0</ReceiptCfmyn>
    <Remark>3434</Remark>
    <FactUnit>1</FactUnit>
    <FactUnitName>아산공장</FactUnitName>
    <RepairSeq>5</RepairSeq>
    <EmpName>이재천</EmpName>
    <EmpSeq>2028</EmpSeq>
    <DeptName>사업개발팀2</DeptName>
    <DeptSeq>1300</DeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030822,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025712

rollback 


