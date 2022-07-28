

IF OBJECT_ID('_SEQWorkAcceptDCheckCHE') IS NOT NULL 
    DROP PROC _SEQWorkAcceptDCheckCHE
GO 

-- v2015.09.02 
/*********************************************************************************************************************  
     화면명 : 작업접수등록(일반) - D처리
     작성일 : 2011.05.03 전경만
 ********************************************************************************************************************/ 
 CREATE PROCEDURE [dbo].[_SEQWorkAcceptDCheckCHE]    
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,-- 서비스등록한것 Seq가 넘어온다.  
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
    
    
    -- 체크1, 미등록설비와 설비를 같이 넣을 수 없습니다. 
    
    UPDATE A
       SET Result = '미등록설비와 설비를 같이 넣을 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #WorkOrder AS A 
     WHERE A.ToolSeq <> 0 AND A.NonCodeToolNo <> '' 
       AND A.Status = 0 
    
    -- 체크1, END 
    
    
    -- 체크2, 설비가 누락되었습니다. 
    
    UPDATE A
       SET Result = '설비가 누락되었습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #WorkOrder AS A 
     WHERE A.ToolSeq = 0 AND A.NonCodeToolNo = '' 
       AND A.Status = 0 
    
    -- 체크2, END 
   
   --  --사택순번, 유형자산, 수리일자 체크
   --  EXEC dbo._SCOMMessage @MessageType OUTPUT,
   --                        @Status      OUTPUT,
   --                        @Results     OUTPUT,
   --                        6               , --중복된 @1 @2가(이) 입력되었습니다. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
   --                        @LanguageSeq       ,
   --                        0,'일자의 '   -- SELECT * FROM _TCADictionary WHERE Word like '%%'
   --  UPDATE A
   --     SET Result       = REPLACE(@Results,'@2','유형자산'),
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
     -- INSERT 번호부여(맨 마지막 처리)  
     -------------------------------------------  
     --SELECT @Count = COUNT(1) FROM #WorkOrder WHERE WorkingTag = 'A' --AND Status = 0  
     --IF @Count > 0  
     --BEGIN    
     --    -- 키값생성코드부분 시작    
     --    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TEQWorkOrderReceiptMasterCHE', 'ReceiptSeq', @Count  
     --    -- Temp Talbe 에 생성된 키값 UPDATE  
     --    UPDATE #WorkOrder  
     --       SET ReceiptSeq = @Seq + DataSeq  
     --     WHERE WorkingTag = 'A'  
     --       AND Status = 0  
   
     --    -- 번호생성코드부분 시작    
     --    EXEC dbo._SCOMCreateNo 'SITE', '_TEQWorkOrderReceiptMasterCHE', @CompanySeq, 0, @BaseDate, @MaxNo OUTPUT  
     --    -- Temp Talbe 에 생성된 키값 UPDATE  
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
    <PdAccUnitName>고도화사업부</PdAccUnitName>
    <PdAccUnitSeq>114</PdAccUnitSeq>
    <ToolNo />
    <ToolName />
    <ToolSeq>0</ToolSeq>
    <SectionSeq>0</SectionSeq>
    <SectionCode />
    <NonCodeToolNo>ㅇㅀㅇㅎㄴㅇ</NonCodeToolNo>
    <WorkOperName>정비기획</WorkOperName>
    <WorkOperSeq>20106006</WorkOperSeq>
    <WorkOperSerlName />
    <WorkOperSerl>0</WorkOperSerl>
    <AddType>0</AddType>
    <ReceiptSeq>22</ReceiptSeq>
    <WOReqSeq>26</WOReqSeq>
    <WOReqSerl>1</WOReqSerl>
    <ReqDate>20150629</ReqDate>
    <DeptName>마음부서</DeptName>
    <DeptSeq>102</DeptSeq>
    <EmpSeq>2301</EmpSeq>
    <EmpName>YLW</EmpName>
    <WorkTypeName>일반정비작업</WorkTypeName>
    <WorkType>20104005</WorkType>
    <ReqCloseDate>20150629</ReqCloseDate>
    <WorkContents>ㅁㄶㅁㄶ</WorkContents>
    <WONo>15-G-00013 </WONo>
    <FileSeq>0</FileSeq>
    <ProgType>20109002</ProgType>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=10102,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100150
rollback 