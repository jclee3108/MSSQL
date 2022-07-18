  
IF OBJECT_ID('KPXCM_SEQRegInspectCheck') IS NOT NULL   
    DROP PROC KPXCM_SEQRegInspectCheck  
GO  
  
-- v2015.07.01  
  
-- 정기검사설비등록-체크 by 이재천   
CREATE PROC KPXCM_SEQRegInspectCheck  
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
      
    CREATE TABLE #KPXCM_TEQRegInspect( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TEQRegInspect'   
    IF @@ERROR <> 0 RETURN     

    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0, ''
      
    UPDATE #KPXCM_TEQRegInspect  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPXCM_TEQRegInspect AS A   
      JOIN (SELECT S.ToolSeq, S.UMQCSeq, S.UMQCCycle
              FROM (SELECT A1.ToolSeq, A1.UMQCSeq, A1.UMQCCycle  
                      FROM #KPXCM_TEQRegInspect AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.ToolSeq, A1.UMQCSeq, A1.UMQCCycle
                      FROM KPXCM_TEQRegInspect AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPXCM_TEQRegInspect   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND RegInspectSeq = A1.RegInspectSeq  
                                      )  
                   ) AS S  
             GROUP BY S.ToolSeq, S.UMQCSeq, S.UMQCCycle  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.ToolSeq = B.ToolSeq AND A.UMQCSeq = B.UMQCSeq AND A.UMQCCycle = B.UMQCCycle )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXCM_TEQRegInspect WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TEQRegInspect', 'RegInspectSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPXCM_TEQRegInspect  
           SET RegInspectSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPXCM_TEQRegInspect   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXCM_TEQRegInspect  
     WHERE Status = 0  
       AND ( RegInspectSeq = 0 OR RegInspectSeq IS NULL )  
      
    SELECT * FROM #KPXCM_TEQRegInspect   
      
    RETURN  
GO 
begin tran 
exec KPXCM_SEQRegInspectCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ToolName>가공4호기</ToolName>
    <ToolNo>가공4호기</ToolNo>
    <FactUnitName />
    <ToolSeq>4</ToolSeq>
    <UMQCName>검사명1</UMQCName>
    <UMQCSeq>1011261001</UMQCSeq>
    <UMQCCompanyName />
    <UMQCCompany>0</UMQCCompany>
    <UMLicenseName />
    <UMLicense>0</UMLicense>
    <EmpName />
    <EmpSeq>0</EmpSeq>
    <UMQCCycleName>일</UMQCCycleName>
    <UMQCCycle>1011264001</UMQCCycle>
    <LastQCDate>20150711</LastQCDate>
    <Spec />
    <QCNo />
    <RegInspectSeq>0</RegInspectSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ToolName>가공4호기</ToolName>
    <ToolNo>가공4호기</ToolNo>
    <FactUnitName />
    <ToolSeq>4</ToolSeq>
    <UMQCName>검사명1</UMQCName>
    <UMQCSeq>1011261001</UMQCSeq>
    <UMQCCompanyName />
    <UMQCCompany>0</UMQCCompany>
    <UMLicenseName />
    <UMLicense>0</UMLicense>
    <EmpName />
    <EmpSeq>0</EmpSeq>
    <UMQCCycleName>일</UMQCCycleName>
    <UMQCCycle>1011264001</UMQCCycle>
    <LastQCDate>20150712</LastQCDate>
    <Spec />
    <QCNo />
    <RegInspectSeq>0</RegInspectSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030603,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025532
rollback 