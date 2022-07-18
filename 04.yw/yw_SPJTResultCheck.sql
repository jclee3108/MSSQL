  
IF OBJECT_ID('yw_SPJTResultCheck') IS NOT NULL   
    DROP PROC yw_SPJTResultCheck  
GO  
  
-- v2014.07.02  
  
-- 프로젝트실적입력_YW(체크) by 이재천   
CREATE PROC yw_SPJTResultCheck  
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
      
    CREATE TABLE #yw_TPJTWBSResult( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#yw_TPJTWBSResult'   
    IF @@ERROR <> 0 RETURN     
    
    DELETE A 
      FROM #yw_TPJTWBSResult AS A 
     WHERE ISNULL(A.BegDate,'') = '' 
       AND ISNULL(A.EndDate,'') = '' 
       AND ISNULL(A.ChgDate,'') = '' 
       AND ISNULL(A.Results,'') = '' 
       AND ISNULL(FileSeq,0) = 0 
    
    --------------------------------------------------------------------------------------------------------------------------
    -- 체크0, 데이터유무체크: UPDATE, DELETE시 데이터 존해하지 않으면 에러처리  
    --------------------------------------------------------------------------------------------------------------------------
    IF NOT EXISTS ( SELECT 1   
                      FROM #yw_TPJTWBSResult AS A   
                      JOIN yw_TPJTWBSResult AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.PJTSeq = B.PJTSeq AND A.UMWBSSeq = A.UMWBSSeq ) 
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0   
                  )  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- 자료가등록되어있지않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
          
        UPDATE #yw_TPJTWBSResult  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   
    --------------------------------------------------------------------------------------------------------------------------
    -- 체크0 END 
    --------------------------------------------------------------------------------------------------------------------------
    
    --------------------------------------------------------------------------------------------------------------------------
    -- 체크1, 해당 WBS가 시작되지 않아 종료, 조정할 수 없습니다. 
    --------------------------------------------------------------------------------------------------------------------------
    UPDATE A 
       SET Result = '해당 WBS가 시작되지 않아 종료, 조정할 수 없습니다.', 
           MessageType = 1234, 
           Status = 1234
      FROM #yw_TPJTWBSResult AS A 
     WHERE A.WorkingTag IN ('A','U')
      AND A.Status = 0 
       AND ((ISNULL(A.BegDate,'') = '' AND ISNULL(A.ChgDate,'') <> '') OR (ISNULL(A.BegDate,'') = '' AND ISNULL(A.EndDate,'') <> '' ))
    --------------------------------------------------------------------------------------------------------------------------
    -- 체크1, END 
    --------------------------------------------------------------------------------------------------------------------------
    
    --------------------------------------------------------------------------------------------------------------------------
    -- 체크2, 전 WBS가 종료되지 않아 시작을 할 수 없습니다. 
    --------------------------------------------------------------------------------------------------------------------------
    
    CREATE TABLE #TEMP 
    (
        UMWBSSeq    INT, 
        BegDate     NCHAR(8), 
        EndDate     NCHAR(8), 
        Original    INT 
    )
    INSERT INTO #TEMP (UMWBSSeq, BegDate, EndDate, Original) 
    SELECT A.UMWBSSeq, A.BegDate, A.EndDate, 1 
      FROM yw_TPJTWBSResult AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.PJTSeq = (SELECT TOP 1 PJTSeq FROM #yw_TPJTWBSResult) 
       AND A.UMWBSSeq NOT IN (SELECT UMWBSSeq FROM #yw_TPJTWBSResult)
    
    UNION ALL 
    
    SELECT A.UMWBSSeq, A.BegDate, A.EndDate, 2 
      FROM #yw_TPJTWBSResult AS A 
    
    
    UPDATE #yw_TPJTWBSResult 
       SET Result = '전 WBS가 종료되지 않아 시작을 할 수 없습니다.', 
           MessageType = 1234, 
           Status = 1234
      FROM #TEMP AS A 
     WHERE A.UMWBSSeq <> (SELECT MAX(UMWBSSeq) FROM #yw_TPJTWBSResult) 
       AND A.UMWBSSeq = (SELECT MAX(UMWBSSeq) FROM #TEMP WHERE UMWBSSeq <> (SELECT MAX(UMWBSSeq) FROM #yw_TPJTWBSResult) ) 
       AND ISNULL(A.EndDate,'') = '' 
    
    --------------------------------------------------------------------------------------------------------------------------
    -- 체크2, END 
    --------------------------------------------------------------------------------------------------------------------------
    
    --------------------------------------------------------------------------------------------------------------------------
    -- 체크3, 종료,조정일이 시작일보다 빠를 수 없습니다. 
    --------------------------------------------------------------------------------------------------------------------------
    UPDATE A 
        SET Result = '종료,조정일이 시작일보다 빠를 수 없습니다.', 
            MessageType = 1234, 
            Status = 1234
      FROM #yw_TPJTWBSResult AS A 
     WHERE A.WorkingTag IN ('A','U')
       AND A.Status = 0 
       AND ((BegDate > ChgDate AND ISNULL(ChgDate,'') <> '') OR (BegDate > EndDate AND ISNULL(EndDate,'') <> ''))
    --------------------------------------------------------------------------------------------------------------------------
    -- 체크3, END 
    --------------------------------------------------------------------------------------------------------------------------
    
    --------------------------------------------------------------------------------------------------------------------------
    -- 체크4, 전 WBS 종료일보다 빠를 수 없습니다. 
    --------------------------------------------------------------------------------------------------------------------------
    
    IF (SELECT BegDate 
          FROM #TEMP 
         WHERE UMWBSSeq = (SELECT MAX(UMWBSSeq) FROM #TEMP) -- 저장하는 데이터 
        ) <=  (SELECT EndDate 
                FROM #TEMP 
               WHERE UMWBSSeq <> (SELECT MAX(UMWBSSeq) FROM #TEMP) 
                 AND UMWBSSeq = ( SELECT MAX(UMWBSSeq) 
                                    FROM #TEMP 
                                   WHERE UMWBSSeq <> (SELECT MAX(UMWBSSeq) FROM #TEMP) 
                                ) 
             )
    BEGIN
    --select 1 
        UPDATE #yw_TPJTWBSResult 
            SET Result = '시작일이 전단계 WBS 종료일보다 커야 됩니다.', 
                MessageType = 1234, 
                Status = 1234 
           FROM #yw_TPJTWBSResult 
          WHERE WorkingTag IN ('A','U') 
            AND Status = 0 
    END 
    
    --------------------------------------------------------------------------------------------------------------------------
    -- 체크4, END 
    --------------------------------------------------------------------------------------------------------------------------
    
    --------------------------------------------------------------------------------------------------------------------------
    -- 체크5, 다음 WBS 시작일이 등록되면 해당 WBS 수정할 수 없습니다. 
    --------------------------------------------------------------------------------------------------------------------------
    
    UPDATE A
        SET Result = '다음 WBS 시작일이 등록되면 해당 WBS 수정,삭제 할 수 없습니다.', 
            MessageType = 1234, 
            Status = 1234 
      FROM #yw_TPJTWBSResult AS A 
     WHERE A.UMWBSSeq NOT IN (SELECT MAX(UMWBSSeq) FROM #TEMP) 
       AND A.WorkingTag IN ( 'U', 'D' ) 
       AND A.Status = 0 
    
    --------------------------------------------------------------------------------------------------------------------------
    -- 체크5, END 
    --------------------------------------------------------------------------------------------------------------------------    
    
    -- 메시지 출력을 위한 업데이트 
    IF EXISTS (SELECT 1 FROM #yw_TPJTWBSResult WHERE Status <> 0)
    BEGIN 
        UPDATE #yw_TPJTWBSResult
           SET Result = (SELECT TOP 1 Result FROM #yw_TPJTWBSResult WHERE ISNULL(Result,'') <> ''), 
               MessageType = 1234, 
               Status = 1234 
         WHERE ISNULL(Result,'') = '' 
    END 
    
    SELECT * FROM #yw_TPJTWBSResult   
      
    RETURN  
GO
exec yw_SPJTResultCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>1</Serl>
    <UMWBSSeq>1009757001</UMWBSSeq>
    <TargetDate>19000102</TargetDate>
    <BegDate>20140701</BegDate>
    <EndDate>20140703</EndDate>
    <ChgDate />
    <Results />
    <FileSeq>46387</FileSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>4</Serl>
    <UMWBSSeq>1009757004</UMWBSSeq>
    <TargetDate>19000111</TargetDate>
    <BegDate />
    <EndDate />
    <ChgDate />
    <Results />
    <FileSeq>0</FileSeq>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>5</Serl>
    <UMWBSSeq>1009757005</UMWBSSeq>
    <TargetDate>19000111</TargetDate>
    <BegDate />
    <EndDate />
    <ChgDate />
    <Results />
    <FileSeq>0</FileSeq>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>6</Serl>
    <UMWBSSeq>1009757006</UMWBSSeq>
    <TargetDate>19000111</TargetDate>
    <BegDate />
    <EndDate />
    <ChgDate />
    <Results />
    <FileSeq>0</FileSeq>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>7</Serl>
    <UMWBSSeq>1009757007</UMWBSSeq>
    <TargetDate>19000111</TargetDate>
    <BegDate />
    <EndDate />
    <ChgDate />
    <Results />
    <FileSeq>0</FileSeq>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>8</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>8</Serl>
    <UMWBSSeq>1009757008</UMWBSSeq>
    <TargetDate>19000111</TargetDate>
    <BegDate />
    <EndDate />
    <ChgDate />
    <Results />
    <FileSeq>0</FileSeq>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>9</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>9</Serl>
    <UMWBSSeq>1009757009</UMWBSSeq>
    <TargetDate>19000111</TargetDate>
    <BegDate />
    <EndDate />
    <ChgDate />
    <Results />
    <FileSeq>0</FileSeq>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Serl>10</Serl>
    <UMWBSSeq>1009757010</UMWBSSeq>
    <TargetDate>19000111</TargetDate>
    <BegDate />
    <EndDate />
    <ChgDate />
    <Results />
    <FileSeq>0</FileSeq>
    <PJTSeq>1</PJTSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1023453,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019685