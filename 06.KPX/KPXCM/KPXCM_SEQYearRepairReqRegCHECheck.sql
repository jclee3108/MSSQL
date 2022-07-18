  
IF OBJECT_ID('KPXCM_SEQYearRepairReqRegCHECheck') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReqRegCHECheck  
GO  
  
-- v2015.07.14  
  
-- 연차보수요청등록-체크 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReqRegCHECheck  
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
    
    CREATE TABLE #KPXCM_TEQYearRepairReqRegCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQYearRepairReqRegCHE'   
    IF @@ERROR <> 0 RETURN     
    
    -- 연차보수년도내부코드 업데이트 
    UPDATE B
       SET RepairSeq = A.RepairSeq
      FROM KPXCM_TEQYearRepairPeriodCHE AS A 
      JOIN #KPXCM_TEQYearRepairReqRegCHE AS B ON ( B.RepairYear = A.RepairYear AND B.FactUnit = A.FactUnit AND B.Amd = A.Amd ) 
     WHERE A.CompanySeq = @CompanySeq 
    
    
    -----------------------------------------------------------------------
    -- 체크1, 요청,접수일자가 통제되어 있습니다. (신규등록) 
    -----------------------------------------------------------------------
    UPDATE A
       SET Result = '요청,접수일자가 통제되어 있습니다. (신규등록) ', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TEQYearRepairReqRegCHE AS A 
      JOIN KPXCM_TEQYearRepairPeriodCHE  AS B ON ( B.CompanySeq = @CompanySeq AND B.RepairSeq = A.RepairSeq ) 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
       AND B.ReceiptCfmyn = '1' 
       AND A.ReqDate BETWEEN B.ReceiptFrDate AND B.ReceiptToDate
    -----------------------------------------------------------------------
    -- 체크1, END
    -----------------------------------------------------------------------
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXCM_TEQYearRepairReqRegCHE WHERE WorkingTag = 'A' AND Status = 0  
    
    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TEQYearRepairReqRegCHE', 'ReqSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPXCM_TEQYearRepairReqRegCHE  
           SET ReqSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPXCM_TEQYearRepairReqRegCHE   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXCM_TEQYearRepairReqRegCHE  
     WHERE Status = 0  
       AND ( ReqSeq = 0 OR ReqSeq IS NULL )  
      
    SELECT * FROM #KPXCM_TEQYearRepairReqRegCHE   
    
    RETURN  
GO 
begin tran 
exec KPXCM_SEQYearRepairReqRegCHECheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <RepairYearSeq>2015</RepairYearSeq>
    <RepairYear>2015</RepairYear>
    <AmdSeq>4</AmdSeq>
    <Amd>4</Amd>
    <ReqDate>20150721</ReqDate>
    <FactUnit>1</FactUnit>
    <FactUnitName>아산공장</FactUnitName>
    <RepairToDate>20150830</RepairToDate>
    <DeptSeq>1300</DeptSeq>
    <DeptName>사업개발팀2</DeptName>
    <EmpSeq>2028</EmpSeq>
    <EmpName>이재천</EmpName>
    <RepairFrDate>20150801</RepairFrDate>
    <ReceiptFrDate>20150701</ReceiptFrDate>
    <ReceiptToDate>20150731</ReceiptToDate>
    <ReqSeq>0</ReqSeq>
    <RepairSeq>0</RepairSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030838,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025722

rollback 