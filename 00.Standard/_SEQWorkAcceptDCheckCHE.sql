

IF OBJECT_ID('_SEQWorkAcceptDCheckCHE') IS NOT NULL 
    DROP PROC _SEQWorkAcceptDCheckCHE
GO 

-- v2015.09.02 
/*********************************************************************************************************************  
     ȭ��� : �۾��������(�Ϲ�) - Dó��
     �ۼ��� : 2011.05.03 ���游
 ********************************************************************************************************************/ 
 CREATE PROCEDURE [dbo].[_SEQWorkAcceptDCheckCHE]    
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,-- ���񽺵���Ѱ� Seq�� �Ѿ�´�.  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS         
     DECLARE @docHandle      INT,    
             @MessageType    INT,
       @Status         INT,
       @Count          INT,
       @Seq            INT,
       @Results        NVARCHAR(250),
       @MaxSerl  INT,
       @BaseDate  NCHAR(8),
       @MaxNo   NVARCHAR(100)
     
     CREATE TABLE #WorkOrder (WorkingTag NCHAR(1) NULL)
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#WorkOrder'
     IF @@ERROR <> 0 RETURN
    
    
    -- üũ1, �̵�ϼ���� ���� ���� ���� �� �����ϴ�. 
    
    UPDATE A
       SET Result = '�̵�ϼ���� ���� ���� ���� �� �����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #WorkOrder AS A 
     WHERE A.ToolSeq <> 0 AND A.NonCodeToolNo <> '' 
       AND A.Status = 0 
    
    -- üũ1, END 
    
    
    -- üũ2, ���� �����Ǿ����ϴ�. 
    
    UPDATE A
       SET Result = '���� �����Ǿ����ϴ�.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #WorkOrder AS A 
     WHERE A.ToolSeq = 0 AND A.NonCodeToolNo = '' 
       AND A.Status = 0 
    
    -- üũ2, END 
   
   --  --���ü���, �����ڻ�, �������� üũ
   --  EXEC dbo._SCOMMessage @MessageType OUTPUT,
   --                        @Status      OUTPUT,
   --                        @Results     OUTPUT,
   --                        6               , --�ߺ��� @1 @2��(��) �ԷµǾ����ϴ�. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
   --                        @LanguageSeq       ,
   --                        0,'������ '   -- SELECT * FROM _TCADictionary WHERE Word like '%%'
   --  UPDATE A
   --     SET Result       = REPLACE(@Results,'@2','�����ڻ�'),
   --         MessageType  = @MessageType,
   --         Status       = @Status
   --    FROM #AssetRepair AS A
   --   JOIN _TGAAssetRepairCHE AS B ON B.CompanySeq = @CompanySeq
   --            AND A.HouseSeq   = B.HouseSeq
   --            AND A.AssetSeq   = B.AssetSeq
   --            AND A.RepairDate = B.RepairDate
   --WHERE A.WorkingTag <> 'D'
   --  AND A.Status = 0
  --SELECT @BaseDate = ReceiptDate FROM #WorkOrder
  
  --IF @BaseDate = '' OR @BaseDate IS NULL
  -- SELECT @BaseDate = CONVERT(NCHAR(8),GETDATE(),112)
   -------------------------------------------  
     -- INSERT ��ȣ�ο�(�� ������ ó��)  
     -------------------------------------------  
     --SELECT @Count = COUNT(1) FROM #WorkOrder WHERE WorkingTag = 'A' --AND Status = 0  
     --IF @Count > 0  
     --BEGIN    
     --    -- Ű�������ڵ�κ� ����    
     --    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TEQWorkOrderReceiptMasterCHE', 'ReceiptSeq', @Count  
     --    -- Temp Talbe �� ������ Ű�� UPDATE  
     --    UPDATE #WorkOrder  
     --       SET ReceiptSeq = @Seq + DataSeq  
     --     WHERE WorkingTag = 'A'  
     --       AND Status = 0  
   
     --    -- ��ȣ�����ڵ�κ� ����    
     --    EXEC dbo._SCOMCreateNo 'SITE', '_TEQWorkOrderReceiptMasterCHE', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT  
     --    -- Temp Talbe �� ������ Ű�� UPDATE  
     --    UPDATE #WorkOrder  
     --       SET ReceiptNo = @MaxNo  
     --     WHERE WorkingTag = 'A'  
     --       AND Status = 0  
     --END 
  
  SELECT * FROM #WorkOrder
 RETURN
 go 
 begin tran 
exec _SEQWorkAcceptDCheckCHE @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <PdAccUnitName>��ȭ�����</PdAccUnitName>
    <PdAccUnitSeq>114</PdAccUnitSeq>
    <ToolNo />
    <ToolName />
    <ToolSeq>0</ToolSeq>
    <SectionSeq>0</SectionSeq>
    <SectionCode />
    <NonCodeToolNo>������������</NonCodeToolNo>
    <WorkOperName>�����ȹ</WorkOperName>
    <WorkOperSeq>20106006</WorkOperSeq>
    <WorkOperSerlName />
    <WorkOperSerl>0</WorkOperSerl>
    <AddType>0</AddType>
    <ReceiptSeq>22</ReceiptSeq>
    <WOReqSeq>26</WOReqSeq>
    <WOReqSerl>1</WOReqSerl>
    <ReqDate>20150629</ReqDate>
    <DeptName>�����μ�</DeptName>
    <DeptSeq>102</DeptSeq>
    <EmpSeq>2301</EmpSeq>
    <EmpName>YLW</EmpName>
    <WorkTypeName>�Ϲ������۾�</WorkTypeName>
    <WorkType>20104005</WorkType>
    <ReqCloseDate>20150629</ReqCloseDate>
    <WorkContents>��������</WorkContents>
    <WONo>15-G-00013 </WONo>
    <FileSeq>0</FileSeq>
    <ProgType>20109002</ProgType>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=10102,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100150
rollback 