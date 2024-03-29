

IF OBJECT_ID('_SEQWorkAcceptDCheckCHE') IS NOT NULL 
    DROP PROC _SEQWorkAcceptDCheckCHE
GO 

-- v2015.09.02 
/*********************************************************************************************************************  
     鉢檎誤 : 拙穣羨呪去系(析鋼) - D坦軒
     拙失析 : 2011.05.03 穿井幻
 ********************************************************************************************************************/ 
 CREATE PROCEDURE [dbo].[_SEQWorkAcceptDCheckCHE]    
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,-- 辞搾什去系廃依 Seq亜 角嬢紳陥.  
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
    
    
    -- 端滴1, 耕去系竺搾人 竺搾研 旭戚 隔聖 呪 蒸柔艦陥. 
    
    UPDATE A
       SET Result = '耕去系竺搾人 竺搾研 旭戚 隔聖 呪 蒸柔艦陥.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #WorkOrder AS A 
     WHERE A.ToolSeq <> 0 AND A.NonCodeToolNo <> '' 
       AND A.Status = 0 
    
    -- 端滴1, END 
    
    
    -- 端滴2, 竺搾亜 刊喰鞠醸柔艦陥. 
    
    UPDATE A
       SET Result = '竺搾亜 刊喰鞠醸柔艦陥.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #WorkOrder AS A 
     WHERE A.ToolSeq = 0 AND A.NonCodeToolNo = '' 
       AND A.Status = 0 
    
    -- 端滴2, END 
   
   --  --紫澱授腰, 政莫切至, 呪軒析切 端滴
   --  EXEC dbo._SCOMMessage @MessageType OUTPUT,
   --                        @Status      OUTPUT,
   --                        @Results     OUTPUT,
   --                        6               , --掻差吉 @1 @2亜(戚) 脊径鞠醸柔艦陥. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
   --                        @LanguageSeq       ,
   --                        0,'析切税 '   -- SELECT * FROM _TCADictionary WHERE Word like '%%'
   --  UPDATE A
   --     SET Result       = REPLACE(@Results,'@2','政莫切至'),
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
     -- INSERT 腰硲採食(固 原走厳 坦軒)  
     -------------------------------------------  
     --SELECT @Count = COUNT(1) FROM #WorkOrder WHERE WorkingTag = 'A' --AND Status = 0  
     --IF @Count > 0  
     --BEGIN    
     --    -- 徹葵持失坪球採歳 獣拙    
     --    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TEQWorkOrderReceiptMasterCHE', 'ReceiptSeq', @Count  
     --    -- Temp Talbe 拭 持失吉 徹葵 UPDATE  
     --    UPDATE #WorkOrder  
     --       SET ReceiptSeq = @Seq + DataSeq  
     --     WHERE WorkingTag = 'A'  
     --       AND Status = 0  
   
     --    -- 腰硲持失坪球採歳 獣拙    
     --    EXEC dbo._SCOMCreateNo 'SITE', '_TEQWorkOrderReceiptMasterCHE', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT  
     --    -- Temp Talbe 拭 持失吉 徹葵 UPDATE  
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
    <PdAccUnitName>壱亀鉢紫穣採</PdAccUnitName>
    <PdAccUnitSeq>114</PdAccUnitSeq>
    <ToolNo />
    <ToolName />
    <ToolSeq>0</ToolSeq>
    <SectionSeq>0</SectionSeq>
    <SectionCode />
    <NonCodeToolNo>しぐしぞいし</NonCodeToolNo>
    <WorkOperName>舛搾奄塙</WorkOperName>
    <WorkOperSeq>20106006</WorkOperSeq>
    <WorkOperSerlName />
    <WorkOperSerl>0</WorkOperSerl>
    <AddType>0</AddType>
    <ReceiptSeq>22</ReceiptSeq>
    <WOReqSeq>26</WOReqSeq>
    <WOReqSerl>1</WOReqSerl>
    <ReqDate>20150629</ReqDate>
    <DeptName>原製採辞</DeptName>
    <DeptSeq>102</DeptSeq>
    <EmpSeq>2301</EmpSeq>
    <EmpName>YLW</EmpName>
    <WorkTypeName>析鋼舛搾拙穣</WorkTypeName>
    <WorkType>20104005</WorkType>
    <ReqCloseDate>20150629</ReqCloseDate>
    <WorkContents>けうけう</WorkContents>
    <WONo>15-G-00013 </WONo>
    <FileSeq>0</FileSeq>
    <ProgType>20109002</ProgType>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=10102,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100150
rollback 