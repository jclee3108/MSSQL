  
IF OBJECT_ID('yw_SPDSFCWorkStartCheck') IS NOT NULL 
    DROP PROC yw_SPDSFCWorkStartCheck 
GO 
  
-- v2013.08.01 
  
-- 공정개시입력(현장)_YW(체크) by이재천
CREATE PROC yw_SPDSFCWorkStartCheck  
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
      
    CREATE TABLE #YW_TPDSFCWorkStart( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TPDSFCWorkStart'   
    IF @@ERROR <> 0 RETURN     
    
    -- 삭제 로그남기기위한 데이터 INSERT
    
    INSERT INTO #YW_TPDSFCWorkStart
    (
        WorkingTag, Status, EmpSeqOld, Serl, WorkCenterSeq, WorkOrderSeq
    )    
    SELECT B.WorkingTag, B.Status, A.EmpSeq, A.Serl, B.WorkCenterSeq, B.WorkOrderSeq
      FROM YW_TPDSFCWorkStart AS A
      JOIN #YW_TPDSFCWorkStart AS B ON ( B.WorkCenterSeq = A.WorkCenterSeq AND B.WorkOrderSeq = A.WorkOrderSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND @WorkingTag = 'Delete'
    
    DELETE FROM #YW_TPDSFCWorkStart WHERE @WorkingTag = 'Delete' AND EmpSeqOld IS NULL
    
    -- 데이터유무체크: UPDATE, DELETE시 데이터 존해하지 않으면 에러처리  
    
    IF NOT EXISTS ( SELECT 1   
                      FROM #YW_TPDSFCWorkStart AS A   
                      JOIN YW_TPDSFCWorkStart AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.WorkCenterSeq = B.WorkCenterSeq AND A.EmpSeqOld = B.EmpSeq )  
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0   
                  )  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- 자료가등록되어있지않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
    
        UPDATE #YW_TPDSFCWorkStart  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   
    
    -- 체크 1, 중복된 값이 입력되었습니다. 
    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%중복%')  
                          @LanguageSeq       ,  
                          3542, '값1'--,  -- SELECT * FROM _TCADictionary WHERE Word like '%값%'  
                          --3543, '값2'  
    
    UPDATE #YW_TPDSFCWorkStart 
       SET Result       = @Results, 
           MessageType  = @MessageType, 
           Status       = @Status 
      FROM #YW_TPDSFCWorkStart AS A 
      JOIN (SELECT S.WorkCenterSeq, S.EmpSeq 
              FROM (SELECT A1.WorkCenterSeq, A1.EmpSeq 
                      FROM #YW_TPDSFCWorkStart AS A1 
                     WHERE A1.WorkingTag IN ('A', 'U') 
                       AND A1.Status = 0 
    
                    UNION ALL 
    
                    SELECT A1.WorkCenterSeq, A1.EmpSeq 
                      FROM YW_TPDSFCWorkStart AS A1 
                     WHERE A1.CompanySeq = @CompanySeq 
                       AND NOT EXISTS (SELECT 1 FROM #YW_TPDSFCWorkStart 
                                               WHERE WorkingTag IN ('U','D') 
                                                 AND Status = 0 
                                                 AND WorkCenterSeq = A1.WorkCenterSeq 
                                                 AND EmpSeq = A1.EmpSeq 
                                      ) 
                   ) AS S 
             GROUP BY S.WorkCenterSeq, S.EmpSeq 
            HAVING COUNT(1) > 1 
           ) AS B ON ( A.WorkCenterSeq = B.WorkCenterSeq AND A.EmpSeq = B.EmpSeq ) 
     WHERE A.WorkingTag IN ('A', 'U') 
       AND A.Status = 0 
    
    -- 체크1, END 
    
    -- 체크2, 투입시작이 입력 된 후로는 작업자를 수정 할 수 없습니다. 
    
    UPDATE #YW_TPDSFCWorkStart 
       SET Result       = '투입시작이 입력 된 후로는 작업자를 수정 할 수 없습니다.', 
           MessageType  = @MessageType, 
           Status       = 51315 
      FROM #YW_TPDSFCWorkStart AS A 
     WHERE WorkingTag = 'U' 
       AND Status = 0 
       AND A.StartTime <> '' 
       AND A.EmpSeq <> A.EmpSeqOld 
    
    -- 체크2, END 
    
    -- 체크3, 투입시작을 하지 않았습니다. 
    
    IF @WorkingTag = 'EndTime' 
    BEGIN 
        UPDATE #YW_TPDSFCWorkStart 
           SET Result       = '투입시작을 하지 않았습니다.', 
               MessageType  = @MessageType, 
               Status       = 324523423 
          FROM #YW_TPDSFCWorkStart AS A 
         WHERE WorkingTag = 'A' 
           AND Status = 0 
           AND A.StartTime = '' 
    END 
    
    -- 체크3, END 
    
    -- 체크4, 이미 투입종료가 완료되었습니다. 
    
    IF @WorkingTag = 'EndTime' 
    BEGIN 
        UPDATE #YW_TPDSFCWorkStart 
           SET Result       = '이미 투입종료가 완료되었습니다.', 
               MessageType  = @MessageType, 
               Status       = 324523423 
          FROM #YW_TPDSFCWorkStart AS A 
         WHERE WorkingTag = 'U' 
           AND Status = 0 
           AND A.EndTime <> '' 
    END 
    
    -- 체크4, END 
    

    -- 시리얼 채번하기 
    IF @WorkingTag = 'StartTime' 
    BEGIN 
        -- 번호+코드 따기 
        DECLARE @Count  INT, 
                @Serl   INT 
                
        -- 투입종료가 하나라도 되지 않았을 경우 MAX값 으로 셋팅
        IF EXISTS (SELECT TOP 1 A.EndTime 
                      FROM YW_TPDSFCWorkStart AS A
                      JOIN #YW_TPDSFCWorkStart AS B WITH(NOLOCK) ON ( B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
                     WHERE A.CompanySeq = @CompanySeq 
                       AND A.EndTime = '' 
                  )
        BEGIN
            UPDATE B
               SET B.Serl = A.Serl
              FROM YW_TPDSFCWorkStart AS A
              JOIN #YW_TPDSFCWorkStart AS B WITH(NOLOCK) ON ( B.WorkOrderSeq = A.WorkOrderSeq AND B.WorkCenterSeq = A.WorkCenterSeq ) 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.EndTime = '' 
               AND WorkingTag = 'A' 
               AND Status = 0 
        END
        
        -- 모두 투입종료가 되었을 경우 채번
        ELSE
        BEGIN             
            SELECT @Count = COUNT(1) FROM #YW_TPDSFCWorkStart WHERE WorkingTag = 'A' AND Status = 0 
        
            IF @Count > 0 
            BEGIN 
                -- 키값생성코드부분 시작 
                EXEC @Serl = dbo._SCOMCreateSeq @CompanySeq, 'YW_TPDSFCWorkStart', 'Serl', 1 
        
                -- Temp Talbe 에 생성된 키값 UPDATE 
                UPDATE #YW_TPDSFCWorkStart 
                   SET Serl = @Serl + 1 
                 WHERE WorkingTag = 'A' 
                   AND Status = 0 
            END
        END
    END 
    
    SELECT * FROM #YW_TPDSFCWorkStart 
    
    RETURN  
GO

exec yw_SPDSFCWorkStartCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Sel>0</Sel>
    <EmpName>강성민</EmpName>
    <EmpSeq>2017</EmpSeq>
    <StartTime />
    <EndTime />
    <EmpSeqOld>0</EmpSeqOld>
    <Serl>0</Serl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <WorkCenterSeq>2</WorkCenterSeq>
    <WorkOrderSeq>131292</WorkOrderSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016755,@WorkingTag=N'StartTime',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014297