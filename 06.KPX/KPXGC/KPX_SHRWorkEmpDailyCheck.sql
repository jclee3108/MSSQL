  
IF OBJECT_ID('KPX_SHRWorkEmpDailyCheck') IS NOT NULL   
    DROP PROC KPX_SHRWorkEmpDailyCheck  
GO  
  
-- v2014.12.23  
  
-- 지역별근무인원등록-체크 by 이재천   
CREATE PROC KPX_SHRWorkEmpDailyCheck  
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
    
    CREATE TABLE #KPX_THRWorkEmpDaily( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_THRWorkEmpDaily'   
    IF @@ERROR <> 0 RETURN     
    
    -- 중복여부 체크 :   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          0
      
    UPDATE #KPX_THRWorkEmpDaily  
       SET Result       = @Results,  
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #KPX_THRWorkEmpDaily AS A   
      JOIN (SELECT S.EmpSeq, S.WorkDate, S.UMWorkCenterSeq  
              FROM (SELECT A1.EmpSeq, A1.WorkDate, A1.UMWorkCenterSeq 
                      FROM #KPX_THRWorkEmpDaily AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.EmpSeq, A1.WorkDate, A1.UMWorkCenterSeq 
                      FROM KPX_THRWorkEmpDaily AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #KPX_THRWorkEmpDaily   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND Serl = A1.Serl
                                      )  
                   ) AS S  
             GROUP BY S.EmpSeq, S.WorkDate, S.UMWorkCenterSeq  
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.EmpSeq = B.EmpSeq AND A.WorkDate = B.WorkDate AND A.UMWorkCenterSeq = B.UMWorkCenterSeq )  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
    
      --  번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPX_THRWorkEmpDaily WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPX_THRWorkEmpDaily', 'Serl', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPX_THRWorkEmpDaily  
           SET Serl = @Seq + DataSeq     
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPX_THRWorkEmpDaily   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPX_THRWorkEmpDaily  
     WHERE Status = 0  
       AND ( Serl = 0 OR Serl IS NULL )  
       AND WorkingTag <> 'D'
      
    SELECT * FROM #KPX_THRWorkEmpDaily   
      
    RETURN  
GO 
exec KPX_SHRWorkEmpDailyCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpName>이지은</EmpName>
    <EmpSeq>2029</EmpSeq>
    <DeptName>개발2팀</DeptName>
    <Serl>25</Serl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <WorkDate>20141223</WorkDate>
    <UMWorkCenterSeq>1010550001</UMWorkCenterSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027065,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022596