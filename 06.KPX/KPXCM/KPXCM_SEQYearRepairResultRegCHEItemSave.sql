  
IF OBJECT_ID('KPXCM_SEQYearRepairResultRegCHEItemSave') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairResultRegCHEItemSave  
GO  
  
-- v2015.07.17  
  
-- 연차보수실적등록-디테일저장 by 이재천   
CREATE PROC KPXCM_SEQYearRepairResultRegCHEItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPXCM_TEQYearRepairResultRegItemCHE (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TEQYearRepairResultRegItemCHE'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQYearRepairResultRegItemCHE')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TEQYearRepairResultRegItemCHE'    , -- 테이블명        
                  '#KPXCM_TEQYearRepairResultRegItemCHE'    , -- 임시 테이블명        
                  'ResultSeq,ResultSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairResultRegItemCHE WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #KPXCM_TEQYearRepairResultRegItemCHE AS A   
          JOIN KPXCM_TEQYearRepairResultRegItemCHE AS B ON ( B.CompanySeq = @CompanySeq AND A.ResultSeq = B.ResultSeq AND A.ResultSerl = B.ResultSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
        
        
        IF NOT EXISTS (
                        SELECT 1 
                          FROM KPXCM_TEQYearRepairResultRegItemCHE AS A 
                         WHERE A.CompanySeq = @CompanySeq 
                           AND A.ResultSeq IN ( SELECT TOP 1 ResultSeq FROM #KPXCM_TEQYearRepairResultRegItemCHE ) 
                      )
        BEGIN
            
            CREATE TABLE #Log 
            (
                IDX_NO          INT IDENTITY, 
                WorkingTag      NVARCHAR(1), 
                Status          INT, 
                ResultSeq       INT, 
                
            )
            INSERT INTO #Log (WorkingTag, Status, ResultSeq) 
            SELECT TOP 1 A.WorkingTag, A.Status, ResultSeq 
              FROM #KPXCM_TEQYearRepairResultRegItemCHE AS A 
             WHERE A.WorkingTag = 'D' 
               AND A.Status = 0 
               
            -- Master 로그   
            SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQYearRepairResultRegCHE')    
              
            EXEC _SCOMLog @CompanySeq   ,        
                          @UserSeq      ,        
                          'KPXCM_TEQYearRepairResultRegCHE'    , -- 테이블명        
                          '#Log'    , -- 임시 테이블명        
                          'ResultSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                          @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
            
            DELETE B
              FROM #KPXCM_TEQYearRepairResultRegItemCHE    AS A 
              JOIN KPXCM_TEQYearRepairResultRegCHE         AS B ON ( B.CompanySeq = @CompanySeq AND B.ResultSeq = A.ResultSeq ) 
             WHERE A.WorkingTag = 'D' 
               AND A.Status = 0 
        END 
        
        CREATE TABLE #LogSub
        (
            IDX_NO          INT IDENTITY, 
            WorkingTag      NVARCHAR(1), 
            Status          INT, 
            ResultSeq       INT, 
            ResultSerl      INT, 
            ResultSubSerl   INT
        )
        INSERT INTO #LogSub (WorkingTag, Status, ResultSeq, ResultSerl, ResultSubSerl) 
        SELECT A.WorkingTag, A.Status, A.ResultSeq, A.ResultSerl, B.ResultSubSerl 
          FROM #KPXCM_TEQYearRepairResultRegItemCHE AS A 
          JOIN KPXCM_TEQYearRepairRltManHourCHE     AS B ON ( B.CompanySeq = @CompanySeq AND B.ResultSeq = A.ResultSeq AND B.ResultSerl = A.ResultSerl ) 
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0 
    
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TEQYearRepairRltManHourCHE')    
          
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPXCM_TEQYearRepairRltManHourCHE'    , -- 테이블명        
                      '#LogSub'    , -- 임시 테이블명        
                      'ResultSeq,ResultSerl,ResultSubSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
        DELETE B
          FROM #KPXCM_TEQYearRepairResultRegItemCHE     AS A 
          JOIN KPXCM_TEQYearRepairRltManHourCHE         AS B ON ( B.CompanySeq = @CompanySeq AND B.ResultSeq = A.ResultSeq AND B.ResultSerl = A.ResultSerl ) 
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0 
    
    END   
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairResultRegItemCHE WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.ProgType       = A.ProgType,  
               B.UMProtectKind  = A.ProtectKind,  
               B.UMWorkReason   = A.WorkReason,  
               B.UMPreProtect   = A.PreProtect,  
               B.Remark         = A.Remark,  
               B.FileSeq        = A.FileSeq,  
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq    
          FROM #KPXCM_TEQYearRepairResultRegItemCHE AS A   
          JOIN KPXCM_TEQYearRepairResultRegItemCHE AS B ON ( B.CompanySeq = @CompanySeq AND A.ResultSeq = B.ResultSeq AND A.ResultSerl = B.ResultSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TEQYearRepairResultRegItemCHE WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXCM_TEQYearRepairResultRegItemCHE  
        (   
            CompanySeq, ResultSeq, ResultSerl, ReceiptRegSeq, ReceiptRegSerl, 
            ProgType, UMProtectKind, UMWorkReason, UMPreProtect, Remark, 
            FileSeq, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, ResultSeq, ResultSerl, ReceiptRegSeq, ReceiptRegSerl, 
               ProgType, ProtectKind, WorkReason, PreProtect, Remark, 
               FileSeq, @UserSeq, GETDATE(), @PgmSeq
          FROM #KPXCM_TEQYearRepairResultRegItemCHE AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
    
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #KPXCM_TEQYearRepairResultRegItemCHE   
    
    RETURN  
GO
begin tran 
exec KPXCM_SEQYearRepairResultRegCHEItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <Amd>3</Amd>
    <FactUnit>1</FactUnit>
    <FactUnitName>아산공장</FactUnitName>
    <PreProtect>0</PreProtect>
    <PreProtectName />
    <ProgType>20109002</ProgType>
    <ProgTypeName>접수</ProgTypeName>
    <ProtectKind>1011343001</ProtectKind>
    <ProtectKindName>설비보전구분1</ProtectKindName>
    <ProtectLevelName>100</ProtectLevelName>
    <ReceiptDate>20150720</ReceiptDate>
    <ReceiptDeptName>사업개발팀2</ReceiptDeptName>
    <ReceiptEmpName>이재천</ReceiptEmpName>
    <Remark />
    <RepairFrDate>20150701</RepairFrDate>
    <RepairToDate>20150731</RepairToDate>
    <RepairYear>2015</RepairYear>
    <ReqDate>20150720</ReqDate>
    <ReqDeptName>사업개발팀2</ReqDeptName>
    <ReqEmpName>이재천</ReqEmpName>
    <ToolKindName>14544</ToolKindName>
    <ToolName>가공3호기sssss</ToolName>
    <ToolNo>가공3호기ssssss</ToolNo>
    <ToolSeq>3</ToolSeq>
    <WONo>YP-150720-001</WONo>
    <WorkContents>1</WorkContents>
    <WorkGubn>1011335001</WorkGubn>
    <WorkGubnName>구분1</WorkGubnName>
    <WorkOperName>전기</WorkOperName>
    <WorkOperSeq>20106004</WorkOperSeq>
    <WorkReason>1011344001</WorkReason>
    <WorkReasonName>설비작업사유1</WorkReasonName>
    <ResultSeq>9</ResultSeq>
    <ResultSerl>1</ResultSerl>
    <ReceiptRegSeq>10</ReceiptRegSeq>
    <ReceiptRegSerl>1</ReceiptRegSerl>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <Amd>3</Amd>
    <FactUnit>1</FactUnit>
    <FactUnitName>아산공장</FactUnitName>
    <PreProtect>0</PreProtect>
    <PreProtectName />
    <ProgType>20109002</ProgType>
    <ProgTypeName>접수</ProgTypeName>
    <ProtectKind>1011343003</ProtectKind>
    <ProtectKindName>설비보전구분3</ProtectKindName>
    <ProtectLevelName>1</ProtectLevelName>
    <ReceiptDate>20150720</ReceiptDate>
    <ReceiptDeptName>사업개발팀2</ReceiptDeptName>
    <ReceiptEmpName>이재천</ReceiptEmpName>
    <Remark />
    <RepairFrDate>20150701</RepairFrDate>
    <RepairToDate>20150731</RepairToDate>
    <RepairYear>2015</RepairYear>
    <ReqDate>20150720</ReqDate>
    <ReqDeptName>사업개발팀2</ReqDeptName>
    <ReqEmpName>이재천</ReqEmpName>
    <ToolKindName>1</ToolKindName>
    <ToolName>성형기</ToolName>
    <ToolNo>사출 성형기622</ToolNo>
    <ToolSeq>6</ToolSeq>
    <WONo>YP-150720-002</WONo>
    <WorkContents>2</WorkContents>
    <WorkGubn>1011335001</WorkGubn>
    <WorkGubnName>구분1</WorkGubnName>
    <WorkOperName>배관</WorkOperName>
    <WorkOperSeq>20106003</WorkOperSeq>
    <WorkReason>1011344001</WorkReason>
    <WorkReasonName>설비작업사유1</WorkReasonName>
    <ResultSeq>9</ResultSeq>
    <ResultSerl>2</ResultSerl>
    <ReceiptRegSeq>10</ReceiptRegSeq>
    <ReceiptRegSerl>2</ReceiptRegSerl>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030930,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025775
rollback 