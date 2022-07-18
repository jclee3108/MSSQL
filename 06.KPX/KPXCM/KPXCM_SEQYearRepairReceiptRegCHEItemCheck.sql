  
IF OBJECT_ID('KPXCM_SEQYearRepairReceiptRegCHEItemCheck') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReceiptRegCHEItemCheck  
GO  
  
-- v2015.07.15  
  
-- 연차보수접수등록-디테일체크 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReceiptRegCHEItemCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
    
    CREATE TABLE #KPXCM_TEQYearRepairReceiptRegItemCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TEQYearRepairReceiptRegItemCHE'   
    IF @@ERROR <> 0 RETURN 
    
    -----------------------------------------------------------------------
    -- 체크1, 요청,접수일자가 통제되어 있습니다. (신규등록) 
    -----------------------------------------------------------------------
    UPDATE A
       SET Result = '요청,접수일자가 통제되어 있습니다. (신규등록) ', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TEQYearRepairReceiptRegItemCHE    AS A 
      JOIN KPXCM_TEQYearRepairReqRegItemCHE         AS B ON ( B.CompanySeq = @CompanySeq AND B.ReqSeq = A.ReqSeq AND B.ReqSerl = A.ReqSerl ) 
      JOIN KPXCM_TEQYearRepairReqRegCHE             AS C ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = B.ReqSeq ) 
      JOIN KPXCM_TEQYearRepairPeriodCHE             AS D ON ( D.CompanySeq = @CompanySeq AND D.RepairSeq = C.RepairSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
       AND D.ReceiptCfmyn = '1' 
       AND A.ReceiptRegDate BETWEEN D.ReceiptFrDate AND D.ReceiptToDate
    -----------------------------------------------------------------------
    -- 체크1, END
    -----------------------------------------------------------------------
    
    ------------------------------------------------------------------------------
    -- 체크2, 진행된 데이터는 수정,삭제 할 수 없습니다. 
    ------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '진행된 데이터는 수정,삭제 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TEQYearRepairReceiptRegItemCHE AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U','D' ) 
       AND EXISTS (SELECT 1 FROM KPXCM_TEQYearRepairResultRegItemCHE WHERE CompanySeq = @CompanySeq AND ReceiptRegSeq = A.ReceiptRegSeq AND ReceiptRegSerl = A.ReceiptRegSerl ) 
    ------------------------------------------------------------------------------
    -- 체크2, END 
    ------------------------------------------------------------------------------
    
    ------------------------------------------------------------------------------
    -- 체크3, 진행상태가 보류,회송일 경우 보류회송사유는 필수입니다.
    ------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '진행상태가 보류,회송일 경우 보류회송사유는 필수입니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TEQYearRepairReceiptRegItemCHE AS A 
      LEFT OUTER JOIN _TDAUMinorValue            AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.ProgType AND B.Serl = 1000007 ) 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'A','U' ) 
       AND ISNULL(B.ValueText,'0') = '1' 
       AND A.RtnReason = '' 
    ------------------------------------------------------------------------------
    -- 체크3, END 
    ------------------------------------------------------------------------------
    
    UPDATE A 
       SET ReceiptRegSerl = DataSeq 
      FROM #KPXCM_TEQYearRepairReceiptRegItemCHE AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
    
    SELECT * FROM #KPXCM_TEQYearRepairReceiptRegItemCHE 
    
    RETURN  
GO 

begin tran 
exec KPXCM_SEQYearRepairReceiptRegCHEItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FactUnitName>아산공장</FactUnitName>
    <FactUnit>1</FactUnit>
    <RepairYear>2015</RepairYear>
    <Amd>4</Amd>
    <ReqDate>20150801</ReqDate>
    <ReceiptFrDate>20150701</ReceiptFrDate>
    <ReceiptToDate>20150731</ReceiptToDate>
    <RepairFrDate>20150801</RepairFrDate>
    <RepairToDate>20150830</RepairToDate>
    <EmpName>이재천</EmpName>
    <EmpSeq>2028</EmpSeq>
    <DeptName>사업개발팀2</DeptName>
    <DeptSeq>1300</DeptSeq>
    <ToolName>성형기</ToolName>
    <ToolNo>사출 성형기5</ToolNo>
    <ToolSeq>5</ToolSeq>
    <WorkOperName>전기</WorkOperName>
    <WorkOperSeq>20106004</WorkOperSeq>
    <WorkGubnName>구분2</WorkGubnName>
    <WorkGubn>1011335002</WorkGubn>
    <WorkContents>1</WorkContents>
    <ProgTypeName>접수</ProgTypeName>
    <ProgType>20109002</ProgType>
    <RtnReason />
    <WONo>YP-150801-001</WONo>
    <ReqSeq>11</ReqSeq>
    <ReqSerl>1</ReqSerl>
    <ReceiptRegSeq>11</ReceiptRegSeq>
    <ReceiptRegSerl>0</ReceiptRegSerl>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <ReceiptRegDate>20150721</ReceiptRegDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FactUnitName>아산공장</FactUnitName>
    <FactUnit>1</FactUnit>
    <RepairYear>2015</RepairYear>
    <Amd>4</Amd>
    <ReqDate>20150801</ReqDate>
    <ReceiptFrDate>20150701</ReceiptFrDate>
    <ReceiptToDate>20150731</ReceiptToDate>
    <RepairFrDate>20150801</RepairFrDate>
    <RepairToDate>20150830</RepairToDate>
    <EmpName>이재천</EmpName>
    <EmpSeq>2028</EmpSeq>
    <DeptName>사업개발팀2</DeptName>
    <DeptSeq>1300</DeptSeq>
    <ToolName>성형기</ToolName>
    <ToolNo>사출 성형기622</ToolNo>
    <ToolSeq>6</ToolSeq>
    <WorkOperName>계장</WorkOperName>
    <WorkOperSeq>20106005</WorkOperSeq>
    <WorkGubnName>구분2</WorkGubnName>
    <WorkGubn>1011335002</WorkGubn>
    <WorkContents>2</WorkContents>
    <ProgTypeName>접수</ProgTypeName>
    <ProgType>20109002</ProgType>
    <RtnReason />
    <WONo>YP-150801-002</WONo>
    <ReqSeq>11</ReqSeq>
    <ReqSerl>2</ReqSerl>
    <ReceiptRegSeq>11</ReceiptRegSeq>
    <ReceiptRegSerl>0</ReceiptRegSerl>
    <ReceiptRegDate>20150721</ReceiptRegDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FactUnitName>아산공장</FactUnitName>
    <FactUnit>1</FactUnit>
    <RepairYear>2015</RepairYear>
    <Amd>4</Amd>
    <ReqDate>20150801</ReqDate>
    <ReceiptFrDate>20150701</ReceiptFrDate>
    <ReceiptToDate>20150731</ReceiptToDate>
    <RepairFrDate>20150801</RepairFrDate>
    <RepairToDate>20150830</RepairToDate>
    <EmpName>이재천</EmpName>
    <EmpSeq>2028</EmpSeq>
    <DeptName>사업개발팀2</DeptName>
    <DeptSeq>1300</DeptSeq>
    <ToolName>성형기</ToolName>
    <ToolNo>사출 성형기8</ToolNo>
    <ToolSeq>8</ToolSeq>
    <WorkOperName>배관</WorkOperName>
    <WorkOperSeq>20106003</WorkOperSeq>
    <WorkGubnName>구분1</WorkGubnName>
    <WorkGubn>1011335001</WorkGubn>
    <WorkContents>3</WorkContents>
    <ProgTypeName>접수</ProgTypeName>
    <ProgType>20109002</ProgType>
    <RtnReason />
    <WONo>YP-150801-003</WONo>
    <ReqSeq>11</ReqSeq>
    <ReqSerl>3</ReqSerl>
    <ReceiptRegSeq>11</ReceiptRegSeq>
    <ReceiptRegSerl>0</ReceiptRegSerl>
    <ReceiptRegDate>20150721</ReceiptRegDate>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030864,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025743
rollback 