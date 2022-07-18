  
IF OBJECT_ID('KPXCM_SEQYearRepairPeriodRegCHECheck') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairPeriodRegCHECheck  
GO  
  
-- v2015.07.13  
  
-- 연차보수기간등록-체크 by 이재천   
CREATE PROC KPXCM_SEQYearRepairPeriodRegCHECheck  
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
      
    CREATE TABLE #KPXCM_TEQYearRepairPeriodCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQYearRepairPeriodCHE'   
    IF @@ERROR <> 0 RETURN     
    
    ------------------------------------------------------------------------------
    -- 체크1, 진행된 데이터는 수정,삭제 할 수 없습니다. 
    ------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '진행된 데이터는 수정,삭제 할 수 없습니다.', 
           Status = 1234, 
           MessageType = 1234 
      FROM #KPXCM_TEQYearRepairPeriodCHE AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag IN ( 'U','D' ) 
       AND EXISTS (SELECT 1 FROM KPXCM_TEQYearRepairReqRegCHE WHERE CompanySeq = @CompanySeq AND RepairSeq = A.RepairSeq ) 
    ------------------------------------------------------------------------------
    -- 체크1, END 
    ------------------------------------------------------------------------------
    
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXCM_TEQYearRepairPeriodCHE WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TEQYearRepairPeriodCHE', 'RepairSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPXCM_TEQYearRepairPeriodCHE  
           SET RepairSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPXCM_TEQYearRepairPeriodCHE   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXCM_TEQYearRepairPeriodCHE  
     WHERE Status = 0  
       AND ( RepairSeq = 0 OR RepairSeq IS NULL )  
    
    SELECT * FROM #KPXCM_TEQYearRepairPeriodCHE   
      
    RETURN  
GO
begin tran 

exec KPXCM_SEQYearRepairPeriodRegCHECheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <RepairYear>2015</RepairYear>
    <Amd>3</Amd>
    <RepairName>124124</RepairName>
    <RepairFrDate>20150701</RepairFrDate>
    <RepairToDate>20150731</RepairToDate>
    <ReceiptFrDate>20150701</ReceiptFrDate>
    <ReceiptToDate>20150731</ReceiptToDate>
    <RepairCfmYn>0</RepairCfmYn>
    <ReceiptCfmyn>0</ReceiptCfmyn>
    <Remark>134234</Remark>
    <FactUnit>1</FactUnit>
    <FactUnitName>아산공장</FactUnitName>
    <EmpSeq>2028</EmpSeq>
    <EmpName>이재천</EmpName>
    <DeptSeq>1300</DeptSeq>
    <DeptName>사업개발팀2</DeptName>
    <RepairSeq>4</RepairSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030822,@WorkingTag=N'D',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025712

rollback 