  
IF OBJECT_ID('KPXCM_SEQYearRepairReceiptRegCHEItemSave') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReceiptRegCHEItemSave
GO  
  
-- v2015.07.15  
  
-- 연차보수접수등록-디테일저장 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReceiptRegCHEItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPXCM_TEQYearRepairReceiptRegItemCHE (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TEQYearRepairReceiptRegItemCHE'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQYearRepairReceiptRegItemCHE')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQYearRepairReceiptRegItemCHE'    , -- 테이블명        
                  '#KPXCM_TEQYearRepairReceiptRegItemCHE'    , -- 임시 테이블명        
                  'ReceiptRegSeq,ReceiptRegSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairReceiptRegItemCHE WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #KPXCM_TEQYearRepairReceiptRegItemCHE AS A   
          JOIN KPXCM_TEQYearRepairReceiptRegItemCHE AS B ON ( B.CompanySeq = @CompanySeq AND A.ReceiptRegSeq = B.ReceiptRegSeq AND A.ReceiptRegSerl = B.ReceiptRegSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
        
        
        IF NOT EXISTS (
                        SELECT 1 
                          FROM KPXCM_TEQYearRepairReceiptRegItemCHE AS A 
                         WHERE A.CompanySeq = @CompanySeq 
                           AND A.ReceiptRegSeq IN ( SELECT TOP 1 ReceiptRegSeq FROM #KPXCM_TEQYearRepairReceiptRegItemCHE ) 
                      )
        BEGIN
            
            CREATE TABLE #Log 
            (
                IDX_NO          INT IDENTITY, 
                WorkingTag      NVARCHAR(1), 
                Status          INT, 
                ReceiptRegSeq   INT, 
                
            )
            INSERT INTO #Log (WorkingTag, Status, ReceiptRegSeq) 
            SELECT TOP 1 A.WorkingTag, A.Status, ReceiptRegSeq 
              FROM #KPXCM_TEQYearRepairReceiptRegItemCHE AS A 
             WHERE A.WorkingTag = 'D' 
               AND A.Status = 0 
               
            -- Master 로그   
            SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQYearRepairReceiptRegCHE')    
              
            EXEC _SCOMLog @CompanySeq   ,        
                          @UserSeq      ,        
                          'KPXCM_TEQYearRepairReceiptRegCHE'    , -- 테이블명        
                          '#Log'    , -- 임시 테이블명        
                          'ReceiptRegSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                          @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
            
            DELETE B
              FROM #KPXCM_TEQYearRepairReceiptRegItemCHE    AS A 
              JOIN KPXCM_TEQYearRepairReceiptRegCHE         AS B ON ( B.CompanySeq = @CompanySeq AND B.ReceiptRegSeq = A.ReceiptRegSeq ) 
             WHERE A.WorkingTag = 'D' 
               AND A.Status = 0 
        END 
    END   
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairReceiptRegItemCHE WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.ProgType       = A.ProgType, 
               B.RtnReason      = A.RtnReason, 
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
          FROM #KPXCM_TEQYearRepairReceiptRegItemCHE AS A   
          JOIN KPXCM_TEQYearRepairReceiptRegItemCHE  AS B ON ( B.CompanySeq = @CompanySeq AND A.ReceiptRegSeq = B.ReceiptRegSeq AND A.ReceiptRegSerl = B.ReceiptRegSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
    
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairReceiptRegItemCHE WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXCM_TEQYearRepairReceiptRegItemCHE  
        (   
            CompanySeq, ReceiptRegSeq, ReceiptRegSerl, ReqSeq, ReqSerl, 
            ProgType, RtnReason, LastUserSeq, LastDateTime, 
            PgmSeq
        )   
        SELECT @CompanySeq, ReceiptRegSeq, ReceiptRegSerl, ReqSeq, ReqSerl, 
               ProgType, RtnReason, @UserSeq, GETDATE(), 
               @PgmSeq
          FROM #KPXCM_TEQYearRepairReceiptRegItemCHE AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #KPXCM_TEQYearRepairReceiptRegItemCHE   
      
    RETURN  
Go
begin tran
exec KPXCM_SEQYearRepairReceiptRegCHEItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <Amd>3</Amd>
    <DeptName>사업개발팀2</DeptName>
    <DeptSeq>1300</DeptSeq>
    <EmpName>이재천</EmpName>
    <EmpSeq>2028</EmpSeq>
    <FactUnit>1</FactUnit>
    <FactUnitName>아산공장</FactUnitName>
    <ProgType>20109001</ProgType>
    <ProgTypeName>접수</ProgTypeName>
    <ReceiptFrDate>20150701</ReceiptFrDate>
    <ReceiptRegSeq>8</ReceiptRegSeq>
    <ReceiptRegSerl>1</ReceiptRegSerl>
    <ReceiptToDate>20150731</ReceiptToDate>
    <RepairFrDate>20150701</RepairFrDate>
    <RepairToDate>20150731</RepairToDate>
    <RepairYear>2015</RepairYear>
    <ReqDate>20150720</ReqDate>
    <ReqSeq>10</ReqSeq>
    <ReqSerl>1</ReqSerl>
    <RtnReason />
    <ToolName>가공3호기sssss</ToolName>
    <ToolNo>가공3호기ssssss</ToolNo>
    <ToolSeq>3</ToolSeq>
    <WONo>YP-150720-001</WONo>
    <WorkContents>1</WorkContents>
    <WorkGubn>1011335001</WorkGubn>
    <WorkGubnName>구분1</WorkGubnName>
    <WorkOperName>전기</WorkOperName>
    <WorkOperSeq>20106004</WorkOperSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <Amd>3</Amd>
    <DeptName>사업개발팀2</DeptName>
    <DeptSeq>1300</DeptSeq>
    <EmpName>이재천</EmpName>
    <EmpSeq>2028</EmpSeq>
    <FactUnit>1</FactUnit>
    <FactUnitName>아산공장</FactUnitName>
    <ProgType>20109001</ProgType>
    <ProgTypeName>접수</ProgTypeName>
    <ReceiptFrDate>20150701</ReceiptFrDate>
    <ReceiptRegSeq>8</ReceiptRegSeq>
    <ReceiptRegSerl>2</ReceiptRegSerl>
    <ReceiptToDate>20150731</ReceiptToDate>
    <RepairFrDate>20150701</RepairFrDate>
    <RepairToDate>20150731</RepairToDate>
    <RepairYear>2015</RepairYear>
    <ReqDate>20150720</ReqDate>
    <ReqSeq>10</ReqSeq>
    <ReqSerl>2</ReqSerl>
    <RtnReason />
    <ToolName>성형기</ToolName>
    <ToolNo>사출 성형기622</ToolNo>
    <ToolSeq>6</ToolSeq>
    <WONo>YP-150720-002</WONo>
    <WorkContents>2</WorkContents>
    <WorkGubn>1011335001</WorkGubn>
    <WorkGubnName>구분1</WorkGubnName>
    <WorkOperName>배관</WorkOperName>
    <WorkOperSeq>20106003</WorkOperSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030864,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025743
--select * from KPXCM_TEQYearRepairReceiptRegItemCHE 
--select * from KPXCM_TEQYearRepairReceiptRegItemCHELog
rollback 