  
IF OBJECT_ID('KPXCM_SEQYearRepairReqRegCHESave') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReqRegCHESave  
GO  
  
-- v2015.07.14  
  
-- 연차보수요청등록-저장 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReqRegCHESave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPXCM_TEQYearRepairReqRegCHE (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQYearRepairReqRegCHE'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQYearRepairReqRegCHE')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQYearRepairReqRegCHE'    , -- 테이블명        
                  '#KPXCM_TEQYearRepairReqRegCHE'    , -- 임시 테이블명        
                  'ReqSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairReqRegCHE WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.RepairSeq = A.RepairSeq, 
               B.ReqDate = A.ReqDate, 
               B.DeptSeq = A.DeptSeq, 
               B.EmpSeq = A.EmpSeq, 
               B.LastUserSeq = @UserSeq, 
               B.LastDateTime = GETDATE(), 
               B.PgmSeq = @PgmSeq 
          FROM #KPXCM_TEQYearRepairReqRegCHE AS A   
          JOIN KPXCM_TEQYearRepairReqRegCHE AS B ON ( B.CompanySeq = @CompanySeq AND A.ReqSeq = B.ReqSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
    
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    --select *from #KPXCM_TEQYearRepairReqRegCHE 
    
    --return 
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairReqRegCHE WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXCM_TEQYearRepairReqRegCHE  
        (   
            CompanySeq, ReqSeq, RepairSeq, ReqDate, EmpSeq, 
            DeptSeq, LastUserSeq, LastDateTime, PgmSeq  
        )   
        SELECT @CompanySeq, A.ReqSeq, A.RepairSeq, A.ReqDate, A.EmpSeq, 
               A.DeptSeq, @UserSeq, GETDATE(), @PgmSeq     
          FROM #KPXCM_TEQYearRepairReqRegCHE AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
        
    END 
    
    --UPDATE A 
    --   SET ReceiptFrDate = B.ReceiptFrDate, 
    --       ReceiptToDate = B.ReceiptToDate, 
    --       RepairFrDate = B.RepairFrDate, 
    --       RepairToDate = B.RepairToDate
    --  FROM #KPXCM_TEQYearRepairReqRegCHE AS A 
    --  JOIN KPXCM_TEQYearRepairPeriodCHE  AS B ON ( B.CompanySeq = @CompanySeq AND B.RepairSeq = A.RepairSeq ) 
    
    
    SELECT * FROM #KPXCM_TEQYearRepairReqRegCHE   
      
    RETURN  
Go
begin tran
exec KPXCM_SEQYearRepairReqRegCHESave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <Amd>2</Amd>
    <AmdSeq>2</AmdSeq>
    <DeptName>사업개발팀2</DeptName>
    <DeptSeq>1300</DeptSeq>
    <EmpName>이재천</EmpName>
    <EmpSeq>2028</EmpSeq>
    <FactUnit>1</FactUnit>
    <FactUnitName>아산공장</FactUnitName>
    <ReceiptFrDate xml:space="preserve">        </ReceiptFrDate>
    <ReceiptToDate xml:space="preserve">        </ReceiptToDate>
    <RepairFrDate xml:space="preserve">        </RepairFrDate>
    <RepairSeq>3</RepairSeq>
    <RepairToDate xml:space="preserve">        </RepairToDate>
    <RepairYear>2015</RepairYear>
    <RepairYearSeq>2015</RepairYearSeq>
    <ReqDate>20150714</ReqDate>
    <ReqSeq>5</ReqSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030838,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025722

--select * from KPXCM_TEQYearRepairReqRegCHE 
rollback 