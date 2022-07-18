  
IF OBJECT_ID('KPX_SHREduRstUploadCheck') IS NOT NULL   
    DROP PROC KPX_SHREduRstUploadCheck  
GO  
  
-- v2014.11.19  
  
-- 교육결과Upload-체크 by 이재천   
CREATE PROC KPX_SHREduRstUploadCheck  
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
      
    CREATE TABLE #THREduPersRst( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#THREduPersRst'   
    IF @@ERROR <> 0 RETURN     
    
    UPDATE A 
       SET EduCourseSeq = B.EduCourseSeq
      FROM #THREduPersRst AS A 
      JOIN _THREduCourse  AS B ON ( B.CompanySeq = @CompanySeq AND B.EduCourseName = A.EduCourseName ) 
     WHERE A.WorkingTag = 'A'
       AND A.Status = 0
    
    ---------------------------------------------------------
    -- 기존에 없는 학습과정명 등록 
    ---------------------------------------------------------
    DECLARE @MaxSeq INT 
    
    CREATE TABLE #THREduCourse
    (
        DataSeq         INT IDENTITY, 
        OriDataSeq      INT, 
        EduCourseSeq    INT, 
        EduCourseName   NVARCHAR(200), 
    )
    INSERT INTO #THREduCourse ( OriDataSeq, EduCourseSeq, EduCourseName ) 
    SELECT DataSeq, EduCourseSeq, EduCourseName
      FROM #THREduPersRst AS A 
     WHERE A.EduCourseSeq IS NULL 
       AND A.WorkingTag = 'A'
       AND A.Status = 0
    
    SELECT @MaxSeq = ISNULL(Max(EduCourseSeq), 0)    -- 가장 큰 학습과정코드를 받아온다.
      FROM _THREduCourse                            -- 학습과정 테이블에서
     WHERE CompanySeq = @CompanySeq
  
     UPDATE A
        SET EduCourseSeq = @MaxSeq + DataSeq    -- 가장 큰 학습과정코드에 입력된 만큼을 더하여 갱신한다.
       FROM #THREduCourse AS A
    
    INSERT INTO _THREduCourse 
    (
        CompanySeq, EduCourseSeq, EduCourseName, EduClassSeq, SMEduCourseType, 
        EduRem, LastUserSeq, LastDateTime, UMEduGrpType, IsUse, 
        EtcCourseYN
    )
    SELECT @CompanySeq, EduCourseSeq, EduCourseName, 0, 0, 
           '', @UserSeq, GETDATE(), 0, '0', 
           NULL
      FROM #THREduCourse AS A 
    
    ---------------------------------------------------------
    -- 기존에 없는 학습과정명 등록, END 
    ---------------------------------------------------------
    
    -- Input값에 새로생성한 학습과정 코드 업데이트 
    UPDATE A
       SET EduCourseSeq = B.EduCourseSeq
      FROM #THREduPersRst AS A 
      JOIN #THREduCourse  AS B ON ( B.OriDataSeq = A.DataSeq ) 
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0 
    
    -- 사원코드, 부서코드를 사원ID로 찾기 
    UPDATE A
       SET A.EmpSeq = B.EmpSeq, 
           A.DeptSeq = B.DeptSeq 
      FROM #THREduPersRst AS A 
      JOIN _fnAdmEmpOrd(@CompanySeq, '') AS B ON ( B.EmpID = A.EmpID ) 
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0 
    
    -- 학습형태 및 수료결과 코드 찾기 
    UPDATE A
       SET A.EduTypeSeq = ISNULL(B.EduTypeSeq,0), 
           A.SMComplate = CASE WHEN A.ComplateName = '미수료' THEN 1000273002 WHEN A.ComplateName = '수료' THEN 1000273001 ELSE 0 END, 
           A.IsEI = CASE WHEN A.EI = '적용' THEN '1' ELSE '0' END 
      FROM #THREduPersRst AS A 
      JOIN _THREduCourse  AS B ON ( B.CompanySeq = @CompanySeq AND B.EduCourseSeq = A.EduCourseSeq ) 
     WHERE A.WorkingTag = 'A' 
       AND A.Status = 0 
    
    
    -- 번호+코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT, 
            @MaxNo  INT
      
    SELECT @Count = COUNT(1) FROM #THREduPersRst WHERE WorkingTag = 'A' AND Status = 0  
    IF @Count > 0  
    BEGIN  
        
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_THREduPersRst', 'RstSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #THREduPersRst  
           SET RstSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END 
    
    
    SELECT @MaxNo = CONVERT(INT,MAX(RIGHT(RstNo,4)))
      FROM _THREduPersRst 
     WHERE CompanySeq = @CompanySeq 
       AND LEFT(RstNo,6) = CONVERT(NCHAR(6),GETDATE(),112)
    
    UPDATE A 
       SET RstNo = RIGHT('000' + CONVERT(NVARCHAR(20),@MaxNo + DataSeq ),4) 
      FROM #THREduPersRst AS A 
     WHERE WorkingTag = 'A'  
       AND Status = 0  
    
    
    -------------------------------------------------------
    -- 체크, 해당 ID의 사원이 없습니다. 
    -------------------------------------------------------
    UPDATE A 
       SET Result = '해당 ID의 사원이 없습니다. ( ID : ' + EmpID + ' )', 
           Status = 1234, 
           MessageType = 1234 
      FROM #THREduPersRst AS A 
     WHERE ISNULL(EmpSeq,0) = 0 
       AND Status = 0 
       AND A.WorkingTag = 'A' 
    -------------------------------------------------------
    -- 체크, END 
    -------------------------------------------------------
    
    -------------------------------------------------------
    -- 체크, 해당 ID의 수료결과가 반영되지 않았습니다.
    -------------------------------------------------------
    UPDATE A 
       SET Result = '해당 ID의 수료결과가 반영되지 않았습니다. ( ID : ' + EmpID + ' )', 
           Status = 1234, 
           MessageType = 1234 
      FROM #THREduPersRst AS A 
     WHERE ISNULL(SMComplate,0) = 0 
       AND Status = 0 
       AND A.WorkingTag = 'A' 
    -------------------------------------------------------
    -- 체크, END 
    -------------------------------------------------------
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #THREduPersRst   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #THREduPersRst  
     WHERE Status = 0  
       AND ( RstSeq = 0 OR RstSeq IS NULL )  
      
    SELECT * FROM #THREduPersRst   
      
    RETURN  
GO 
begin tran 
exec KPX_SHREduRstUploadCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20000103</EmpID>
    <DeptName>영업관리팀</DeptName>
    <EduCourseName>마케팅관리 통합</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>미수료</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test</Remark>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20000201</EmpID>
    <DeptName>생산2팀</DeptName>
    <EduCourseName>마케팅포지셔닝전략</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>미수료</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20000202</EmpID>
    <DeptName>기술연구소</DeptName>
    <EduCourseName>매출채권관리실무</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>수료</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20000801</EmpID>
    <DeptName>생산4팀</DeptName>
    <EduCourseName>매출채권관리업무</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>미수료</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20001101</EmpID>
    <DeptName>생산관리팀</DeptName>
    <EduCourseName>문제해결과 의사결정</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>미수료</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20001102</EmpID>
    <DeptName>솔루션영업1팀(test)</DeptName>
    <EduCourseName>물류 양성자 과정_AB</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>수료</ComplateName>
    <ReturnAmt>1112</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010201</EmpID>
    <DeptName>생산2팀</DeptName>
    <EduCourseName>법인세 신고실무</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>미수료</ComplateName>
    <ReturnAmt>35153</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>8</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010202</EmpID>
    <DeptName>생산2팀</DeptName>
    <EduCourseName>비즈니스예절교육</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>수료</ComplateName>
    <ReturnAmt>513</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>9</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010401</EmpID>
    <DeptName>국내영업1팀</DeptName>
    <EduCourseName>상담면담기법향상실무</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>미수료</ComplateName>
    <ReturnAmt>213</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>10</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010502</EmpID>
    <DeptName>기술연구소</DeptName>
    <EduCourseName>생산 양성자 과정_AB</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>수료</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>11</IDX_NO>
    <DataSeq>11</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010503</EmpID>
    <DeptName>생산1팀(안산_2)</DeptName>
    <EduCourseName>생산계획 및 통제실무</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>미수료</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>12</IDX_NO>
    <DataSeq>12</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010802</EmpID>
    <DeptName>관리팀</DeptName>
    <EduCourseName>생산원가의 이해와 원가절감</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>미수료</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark>test11</Remark>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>13</IDX_NO>
    <DataSeq>13</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010901</EmpID>
    <DeptName>생산1팀</DeptName>
    <EduCourseName>생산테스트</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>수료</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark />
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>14</IDX_NO>
    <DataSeq>14</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>20010902</EmpID>
    <DeptName>생산5팀</DeptName>
    <EduCourseName>설비관리(TPM)종합</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>미수료</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark />
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>15</IDX_NO>
    <DataSeq>15</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <EmpID>12334</EmpID>
    <DeptName>생산4팀</DeptName>
    <EduCourseName>test123354435</EduCourseName>
    <EduBegDate>20141112</EduBegDate>
    <EduEndDate>20141112</EduEndDate>
    <ComplateName>수료</ComplateName>
    <ReturnAmt>0</ReturnAmt>
    <Remark />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025970,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021807
rollback