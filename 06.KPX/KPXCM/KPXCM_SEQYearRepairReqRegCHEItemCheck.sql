  
IF OBJECT_ID('KPXCM_SEQYearRepairReqRegCHEItemCheck') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReqRegCHEItemCheck  
GO  
  
-- v2015.07.14  
  
-- 연차보수요청등록-디테일체크 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReqRegCHEItemCheck  
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
    
    CREATE TABLE #KPXCM_TEQYearRepairReqRegItemCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TEQYearRepairReqRegItemCHE'   
    IF @@ERROR <> 0 RETURN     
    
    ------------------------------------------------------------------------------
    -- 체크1, 진행된 데이터는 수정,삭제 할 수 없습니다. 
    ------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '진행된 데이터는 수정,삭제 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TEQYearRepairReqRegItemCHE AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U','D' ) 
       AND EXISTS (SELECT 1 FROM KPXCM_TEQYearRepairReceiptRegItemCHE WHERE CompanySeq = @CompanySeq AND ReqSeq = A.ReqSeq AND ReqSerl = A.ReqSerl ) 
    ------------------------------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------------------------------
    
    DECLARE @Serl INT 
    
    SELECT @Serl = ISNULL(MAX(ReqSerl),0)
      FROM KPXCM_TEQYearRepairReqRegItemCHE AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ReqSeq = (SELECT TOP 1 ReqSeq FROM #KPXCM_TEQYearRepairReqRegItemCHE) 
    
    UPDATE A 
       SET ReqSerl = @Serl + A.DataSeq 
      FROM #KPXCM_TEQYearRepairReqRegItemCHE AS A 
      WHERE A.Status = 0 
        AND A.WorkingTag = 'A'
    
    UPDATE A 
       SET WONo = ISNULL(D.ValueText,'') + ISNULL(C.ValueText,'') + '-' + RIGHT(A.ReqDate,6) + '-' + RIGHT('000' + CONVERT(NVARCHAR(100),ReqSerl),3)
      FROM #KPXCM_TEQYearRepairReqRegItemCHE    AS A 
      LEFT OUTER JOIN _TDAUMinorValue           AS B ON ( B.CompanySeq = @CompanySeq AND B.MajorSeq = 1011352 AND B.Serl = 1000001 AND B.ValueSeq = A.FactUnit ) 
      LEFT OUTER JOIN _TDAUMinorValue           AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MinorSeq AND C.Serl = 1000002 ) 
      LEFT OUTER JOIN _TDAUMinorValue           AS D ON ( D.CompanySeq = @CompanySeq 
                                                      AND D.MinorSeq = (CASE WHEN @PgmSeq = 1025722 THEN 1011353002 ELSE 1011353001 END) 
                                                      AND D.Serl = 1000001 
                                                        ) 
    
    SELECT * FROM #KPXCM_TEQYearRepairReqRegItemCHE   
    
    RETURN  
GO
begin tran 
exec KPXCM_SEQYearRepairReqRegCHEItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ToolName>성형기</ToolName>
    <ToolNo>사출 성형기8</ToolNo>
    <ToolSeq>8</ToolSeq>
    <WorkOperName>기타</WorkOperName>
    <WorkOperSeq>20106006</WorkOperSeq>
    <WorkGubnName>구분1</WorkGubnName>
    <WorkGubn>1011335001</WorkGubn>
    <WorkContents>45</WorkContents>
    <ProgTypeName>요청</ProgTypeName>
    <ProgType>0</ProgType>
    <WONo>YP-150720-004</WONo>
    <ReqSeq>10</ReqSeq>
    <ReqSerl>4</ReqSerl>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <FactUnit>1</FactUnit>
    <ReqDate>20150720</ReqDate>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030838,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025722
rollback 