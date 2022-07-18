  
IF OBJECT_ID('KPXCM_SHREduRstWithCostCheck') IS NOT NULL   
    DROP PROC KPXCM_SHREduRstWithCostCheck  
GO  
  
-- v2016.06.13  
  
-- 교육결과등록-체크 by 이재천   
CREATE PROC KPXCM_SHREduRstWithCostCheck  
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
      
    CREATE TABLE #KPXCM_THREduPersRst( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_THREduPersRst'   
    IF @@ERROR <> 0 RETURN     
    
    -- 중복여부 체크 :   
    --EXEC dbo._SCOMMessage @MessageType OUTPUT,  
    --                      @Status      OUTPUT,  
    --                      @Results     OUTPUT,  
    --                      6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
    --                      @LanguageSeq       ,  
    --                      3542, '값1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%값%'  
    --                      --3543, '값2'  
      
    --UPDATE #KPXCM_THREduPersRst  
    --   SET Result       = REPLACE( @Results, '@2', B.SampleName ), -- 혹은 @Results,  
    --       MessageType  = @MessageType,  
    --       Status       = @Status  
    --  FROM #KPXCM_THREduPersRst AS A   
    --  JOIN (SELECT S.SampleName  
    --          FROM (SELECT A1.SampleName  
    --                  FROM #KPXCM_THREduPersRst AS A1  
    --                 WHERE A1.WorkingTag IN ('A', 'U')  
    --                   AND A1.Status = 0  
                                              
    --                UNION ALL  
                                             
    --                SELECT A1.SampleName  
    --                  FROM KPXCM_THREduPersRst AS A1  
    --                 WHERE A1.CompanySeq = @CompanySeq   
    --                   AND NOT EXISTS (SELECT 1 FROM #KPXCM_THREduPersRst   
    --                                           WHERE WorkingTag IN ('U','D')   
    --                                             AND Status = 0   
    --                                             AND RstSeq = A1.RstSeq  
    --                                  )  
    --               ) AS S  
    --         GROUP BY S.SampleName  
    --        HAVING COUNT(1) > 1  
    --       ) AS B ON ( A.SampleName = B.SampleName )  
    -- WHERE A.WorkingTag IN ('A', 'U')  
    --   AND A.Status = 0  
    
    -- 코드 따기 :           
    DECLARE @Count  INT,  
            @Seq    INT   
      
    SELECT @Count = COUNT(1) FROM #KPXCM_THREduPersRst WHERE WorkingTag = 'A' AND Status = 0  
      
    IF @Count > 0  
    BEGIN  
        -- 키값생성코드부분 시작  
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_THREduPersRst', 'RstSeq', @Count  
          
        -- Temp Talbe 에 생성된 키값 UPDATE  
        UPDATE #KPXCM_THREduPersRst  
           SET RstSeq = @Seq + DataSeq
         WHERE WorkingTag = 'A'  
           AND Status = 0  
      
    END -- end if   
    
    
    -- 번호 따기 : 
    
    SELECT  A.IDX_NO, LEFT(RegDate,6) AS RegDate, ROW_NUMBER() OVER ( PARTITION BY LEFT(RegDate,6) ORDER BY LEFT(RegDate,6) ) AS RstNo 
      INTO #RegNo 
      FROM #KPXCM_THREduPersRst AS A 
     WHERE A.WorkingTag = 'A'  
       AND A.Status = 0  
    
    SELECT LEFT(RegDate,6) AS RegDate, MAX(CONVERT(INT,RIGHT(A.RstNo,4))) AS MaxRstNo 
      INTO #MaxRegNo 
      FROM KPXCM_THREduPersRst AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 FROM #RegNo WHERE RegDate = LEFT(RegDate,6))
     GROUP BY LEFT(RegDate,6) 
    
    UPDATE A 
       SET RstNo = ISNULL(C.MaxRstNo,0) + A.RstNo
      FROM #RegNo                   AS A 
      LEFT OUTER JOIN #MaxRegNo     AS C ON ( C.RegDate = A.RegDate ) 
    
    UPDATE A
       SET RstNo = B.RegDate + RIGHT('0000' + CONVERT(NVARCHAR(10),B.RstNo),4)
      FROM #KPXCM_THREduPersRst AS A 
      JOIN #RegNo    AS B ON ( B.IDX_NO = A.IDX_NO ) 
    -- 번호 따기, END 
    
    
    -- 내부코드 0값 일 때 에러처리   
    EXEC dbo._SCOMMessage @MessageType OUTPUT,      
                          @Status      OUTPUT,      
                          @Results     OUTPUT,      
                          1055               , -- 처리작업중에러가발생했습니다. 다시처리하십시요!(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1055)  
                          @LanguageSeq         
      
    UPDATE #KPXCM_THREduPersRst   
       SET Result        = @Results,      
           MessageType   = @MessageType,      
           Status        = @Status      
      FROM #KPXCM_THREduPersRst  
     WHERE Status = 0  
       AND ( RstSeq = 0 OR RstSeq IS NULL )  
      
    SELECT * FROM #KPXCM_THREduPersRst   
      
    RETURN  
GO
begin tran 
exec KPXCM_SHREduRstWithCostCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <RstSeq>0</RstSeq>
    <RegDate>20160603</RegDate>
    <RstNo />
    <EmpSeq>1440</EmpSeq>
    <EmpName>정현묵</EmpName>
    <EmpID>0049</EmpID>
    <DeptSeq>1497</DeptSeq>
    <DeptName>공공사업팀</DeptName>
    <PosSeq>55</PosSeq>
    <PosName>개발자(중급)</PosName>
    <UMJpSeq>3052019</UMJpSeq>
    <UMJpName>4급사원</UMJpName>
    <UMEduGrpTypeName>법정교육</UMEduGrpTypeName>
    <UMEduGrpType>3908001</UMEduGrpType>
    <EduClassName />
    <EduClassSeq />
    <EduCourseName>test1</EduCourseName>
    <EduTypeName>세미나</EduTypeName>
    <EduTypeSeq>6</EduTypeSeq>
    <EtcCourseName />
    <SMInOutTypeName>사외</SMInOutTypeName>
    <SMInOutType>1012002</SMInOutType>
    <EduBegDate>20160602</EduBegDate>
    <EduEndDate>20160604</EduEndDate>
    <EduDd>0</EduDd>
    <EduTm>4</EduTm>
    <EduPoint>0</EduPoint>
    <IsEI>1</IsEI>
    <SMComplateName>수료</SMComplateName>
    <SMComplate>1000273001</SMComplate>
    <RstCost>33</RstCost>
    <ReturnAmt>44</ReturnAmt>
    <RstSummary />
    <RstRem>34</RstRem>
    <UMEduCost>1011069002</UMEduCost>
    <UMEduCostName>법인카드</UMEduCostName>
    <UMEduReport>1011070002</UMEduReport>
    <UMEduReportName>미제출</UMEduReportName>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <RstSeq>0</RstSeq>
    <RegDate>20160604</RegDate>
    <RstNo />
    <EmpSeq>1440</EmpSeq>
    <EmpName>정현묵</EmpName>
    <EmpID>0049</EmpID>
    <DeptSeq>1497</DeptSeq>
    <DeptName>공공사업팀</DeptName>
    <PosSeq>55</PosSeq>
    <PosName>개발자(중급)</PosName>
    <UMJpSeq>3052019</UMJpSeq>
    <UMJpName>4급사원</UMJpName>
    <UMEduGrpTypeName>법정교육</UMEduGrpTypeName>
    <UMEduGrpType>3908001</UMEduGrpType>
    <EduClassName />
    <EduClassSeq />
    <EduCourseName>test1</EduCourseName>
    <EduTypeName>세미나</EduTypeName>
    <EduTypeSeq>6</EduTypeSeq>
    <EtcCourseName />
    <SMInOutTypeName>사외</SMInOutTypeName>
    <SMInOutType>1012002</SMInOutType>
    <EduBegDate>20160602</EduBegDate>
    <EduEndDate>20160604</EduEndDate>
    <EduDd>0</EduDd>
    <EduTm>4</EduTm>
    <EduPoint>0</EduPoint>
    <IsEI>0</IsEI>
    <SMComplateName>수료</SMComplateName>
    <SMComplate>1000273001</SMComplate>
    <RstCost>33</RstCost>
    <ReturnAmt>44</ReturnAmt>
    <RstSummary />
    <RstRem>34</RstRem>
    <UMEduCost>1011069002</UMEduCost>
    <UMEduCostName>법인카드</UMEduCostName>
    <UMEduReport>1011070002</UMEduReport>
    <UMEduReportName>미제출</UMEduReportName>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <RstSeq>0</RstSeq>
    <RegDate>20160701</RegDate>
    <RstNo />
    <EmpSeq>1440</EmpSeq>
    <EmpName>정현묵</EmpName>
    <EmpID>0049</EmpID>
    <DeptSeq>1497</DeptSeq>
    <DeptName>공공사업팀</DeptName>
    <PosSeq>55</PosSeq>
    <PosName>개발자(중급)</PosName>
    <UMJpSeq>3052019</UMJpSeq>
    <UMJpName>4급사원</UMJpName>
    <UMEduGrpTypeName>법정교육</UMEduGrpTypeName>
    <UMEduGrpType>3908001</UMEduGrpType>
    <EduClassName />
    <EduClassSeq />
    <EduCourseName>test1</EduCourseName>
    <EduTypeName>세미나</EduTypeName>
    <EduTypeSeq>6</EduTypeSeq>
    <EtcCourseName />
    <SMInOutTypeName>사외</SMInOutTypeName>
    <SMInOutType>1012002</SMInOutType>
    <EduBegDate>20160602</EduBegDate>
    <EduEndDate>20160604</EduEndDate>
    <EduDd>0</EduDd>
    <EduTm>4</EduTm>
    <EduPoint>0</EduPoint>
    <IsEI>0</IsEI>
    <SMComplateName>수료</SMComplateName>
    <SMComplate>1000273001</SMComplate>
    <RstCost>33</RstCost>
    <ReturnAmt>44</ReturnAmt>
    <RstSummary />
    <RstRem>34</RstRem>
    <UMEduCost>1011069002</UMEduCost>
    <UMEduCostName>법인카드</UMEduCostName>
    <UMEduReport>1011070002</UMEduReport>
    <UMEduReportName>미제출</UMEduReportName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037426,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030642
rollback 