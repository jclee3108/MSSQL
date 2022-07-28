
IF OBJECT_ID('_SEQYearRepairReceiptSaveCHE') IS NOT NULL 
    DROP PROC _SEQYearRepairReceiptSaveCHE
GO 

-- v2014.12.03 

/************************************************************
  ��  �� - ������-���������۾���û : ����
  �ۼ��� - 20110704
  �ۼ��� - �����
 ************************************************************/
 CREATE PROC [dbo].[_SEQYearRepairReceiptSaveCHE]
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
     
     CREATE TABLE #capro_TEQYearRepairReceipt (WorkingTag NCHAR(1) NULL)
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#capro_TEQYearRepairReceipt'
     IF @@ERROR <> 0 RETURN
    
      -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)
     EXEC _SCOMLog  @CompanySeq   ,
                    @UserSeq      ,
                    '_TEQYearRepairMngCHE', -- �����̺��
                    '#capro_TEQYearRepairReceipt', -- �������̺��
                    'ReqSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.
                    'CompanySeq, ReqSeq, RepairYear, Amd, ReqDate, FactUnit, SectionSeq, ToolSeq, WorkOperSeq, WorkGubn, 
                     WorkContents, ProgType, RtnReason, WONo, DeptSeq, EmpSeq, Remark, LastDateTime, LastUserSeq, UMKeepKind'
    
  --   IF @PgmSeq = 1006508
  --   BEGIN
  -- -- DELETE
  -- IF EXISTS (SELECT TOP 1 1 FROM #capro_TEQYearRepairReq WHERE WorkingTag = 'D' AND Status = 0)
  -- BEGIN
  --  DELETE _TEQYearRepairMngCHE
  --    FROM _TEQYearRepairMngCHE A
  --      JOIN #capro_TEQYearRepairReq B ON ( A.ReqSeq     = B.ReqSeq ) 
  --   WHERE 1 = 1
  --     AND A.CompanySeq  = @CompanySeq
  --     AND B.WorkingTag = 'D'
  --     AND B.Status = 0
   --   IF @@ERROR <> 0  RETURN
  -- END
   -- -- UPDATE
  -- IF EXISTS (SELECT 1 FROM #capro_TEQYearRepairReq WHERE WorkingTag = 'U' AND Status = 0)
  -- BEGIN
  --  UPDATE _TEQYearRepairMngCHE
  --     SET 
  --    RepairYear      = B.RepairYear      ,
  --    Amd             = B.Amd             ,
  --    ReqDate         = B.ReqDate         ,
  --    FactUnit        = B.FactUnit        ,
  --    SectionSeq      = B.SectionSeq      ,
  --    ToolSeq         = B.ToolSeq         ,
  --    WorkOperSeq     = B.WorkOperSeq     ,
  --    WorkGubn        = B.WorkGubn        ,
  --    WorkContents    = B.WorkContents    ,
  --    ProgType        = B.ProgType        ,
  --    RtnReason       = B.RtnReason       ,
  --    LastDateTime    = GETDATE()         ,
  --    LastUserSeq     = @UserSeq
  --    FROM _TEQYearRepairMngCHE AS A
  --      JOIN #capro_TEQYearRepairReq AS B ON ( A.ReqSeq     = B.ReqSeq ) 
  --   WHERE 1 = 1
  --     AND A.CompanySeq = @CompanySeq
  --     AND B.WorkingTag = 'U'
  --     AND B.Status = 0
   --  IF @@ERROR <> 0  RETURN
  -- END
   -- -- INSERT
  -- IF EXISTS (SELECT 1 FROM #capro_TEQYearRepairReq WHERE WorkingTag = 'A' AND Status = 0)
  -- BEGIN
  --  INSERT INTO _TEQYearRepairMngCHE (
  --           CompanySeq      ,ReqSeq         ,RepairYear     ,Amd            ,ReqDate    ,
  --           FactUnit        ,SectionSeq     ,ToolSeq        ,WorkOperSeq    ,WorkGubn   ,
  --           WorkContents    ,ProgType       ,RtnReason      ,WONo           ,DeptSeq    ,
  --           EmpSeq          ,Remark         ,LastDateTime    ,LastUserSeq
  --           )
  --   SELECT 
  --      @CompanySeq     ,ReqSeq         ,RepairYear           ,Amd            ,ReqDate    ,
  --      FactUnit        ,SectionSeq     ,ISNULL(ToolSeq,0)    ,WorkOperSeq    ,WorkGubn   ,
  --      WorkContents    ,ProgType       ,RtnReason            ,''             ,DeptSeq    ,
  --      EmpSeq          ,''             ,GETDATE()            , @UserSeq      
   --     FROM #capro_TEQYearRepairReq AS A
  --    WHERE 1 = 1
  --      AND A.WorkingTag = 'A'
  --      AND A.Status = 0
   --  IF @@ERROR <> 0 RETURN
  -- END    
  --   END
  --   ELSE 
  --BEGIN
   -- UPDATE
   IF EXISTS (SELECT 1 FROM #capro_TEQYearRepairReceipt WHERE WorkingTag = 'U' AND Status = 0)
   BEGIN
    UPDATE _TEQYearRepairMngCHE
       SET 
      ProgType        = B.ProgType        ,
      RtnReason       = B.RtnReason       ,
      UMKeepKind      = B.UMKeepKind      , 
      LastDateTime    = GETDATE()         ,
      LastUserSeq     = @UserSeq
      FROM _TEQYearRepairMngCHE AS A
        JOIN #capro_TEQYearRepairReceipt AS B ON ( A.ReqSeq     = B.ReqSeq ) 
     WHERE 1 = 1
       AND A.CompanySeq = @CompanySeq
       AND B.WorkingTag = 'U'
       AND B.Status = 0
     IF @@ERROR <> 0  RETURN
   END
     --END
    
      SELECT * FROM #capro_TEQYearRepairReceipt 
    
      RETURN
GO 
begin tran 
exec _SEQYearRepairReceiptSaveCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ReqSeq>2</ReqSeq>
    <RepairYear>2014</RepairYear>
    <Amd>1</Amd>
    <ReqDate>20140612</ReqDate>
    <FactUnitName>�����������</FactUnitName>
    <FactUnit>112</FactUnit>
    <SectionCode>11</SectionCode>
    <SectionSeq>1</SectionSeq>
    <ToolName>�����-÷�����ϼ���Test2</ToolName>
    <ToolNo>test002</ToolNo>
    <ToolSeq>1006</ToolSeq>
    <WorkOperName>���</WorkOperName>
    <WorkOperSeq>20106001</WorkOperSeq>
    <WorkGubnName>0</WorkGubnName>
    <WorkContents>�۾������׽�Ʈ</WorkContents>
    <ProgTypeName>����</ProgTypeName>
    <ProgType>20109003</ProgType>
    <RtnReason />
    <WONo>20140612  </WONo>
    <DeptName>��������</DeptName>
    <DeptSeq>6</DeptSeq>
    <EmpName>�����</EmpName>
    <EmpSeq>2022</EmpSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10324,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100201
rollback 