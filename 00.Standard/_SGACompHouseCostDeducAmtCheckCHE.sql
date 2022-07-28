
IF OBJECT_ID('_SGACompHouseCostDeducAmtCheckCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostDeducAmtCheckCHE
GO 

/*********************************************************************************************************************    
    화면명 : 사택료급상여반영 - 반영체크  
    작성일 : 2011.05.13 전경만  
********************************************************************************************************************/  
CREATE PROCEDURE _SGACompHouseCostDeducAmtCheckCHE
    @xmlDocument NVARCHAR(MAX)   ,  
    @xmlFlags    INT = 0         ,  
    @ServiceSeq  INT = 0         ,  
    @WorkingTag  NVARCHAR(10)= '',    
    @CompanySeq  INT = 1         ,  
    @LanguageSeq INT = 1         ,  
    @UserSeq     INT = 0         ,  
    @PgmSeq      INT = 0  
  
AS  
  
    -- 사용할 변수를 선언한다.  
    DECLARE @Count       INT,  
            @Seq         INT,  
            @MessageType INT,  
            @Status      INT,  
            @Results     NVARCHAR(250),  
            @MaxSeq   INT,  
            @BegDate  NCHAR(8),  
            @EndDate  NCHAR(8),  
            @BizUnit  INT,  
            @BaseDate  NCHAR(8),  
            @Work   NVARCHAR(10)  
  
  
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #GAHouseCost (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#GAHouseCost'       
  
  
 SELECT @BegDate =  BegDate FROM #GAHouseCost  
 SELECT @EndDate =  EndDate FROM #GAHouseCost  
    IF @@ERROR <> 0 RETURN  
  
  
    SELECT @BaseDate = BaseDate FROM #GAHouseCost  
/*  
 --기존 데이터 존재여부 확인 후 반영처리 WorkingTag 수정  
 UPDATE #GAHouseCost  
    SET WorkingTag = 'U'  
   FROM #GAHouseCost AS A  
     JOIN _TPRBasEmpAmt AS B ON B.CompanySeq = @CompanySeq  
                       AND B.EmpSeq = A.EmpSeq  
                       AND B.PbSeq = A.PbSeq   
                       AND B.ItemSeq = A.ItemSeq   
                       AND B.BegDate = A.BegDate  
                       AND B.EndDate = A.EndDate  
            
   
    SELECT @Work = WorkingTag FROM #GAHouseCost  
  
 CREATE TABLE #BasEmpAmt(DataSeq INT IDENTITY(1,1), HouseSeq INT, EmpSeq INT, PbSeq INT, ItemSeq INT, PaySeq INT,   
       PuSeq INT, BegDate NCHAR(8), EndDate NCHAR(8), Amt DECIMAL(19,5), WorkingTag NCHAR(1), Status INT)  
 INSERT INTO #BasEmpAmt  
   SELECT MAX(HouseSeq), EmpSeq, PbSeq,  ItemSeq, ISNULL(PaySeq, 0),  PuSeq, @BegDate, @EndDate,  SUM(TotalAmt), @Work, 0  
     FROM #GAHouseCost   
    GROUP BY  EmpSeq, PbSeq, PuSeq, ItemSeq, PaySeq  
   
 ALTER TABLE #BasEmpAmt ADD Result NVARCHAR(MAX)  
 ALTER TABLE #BasEmpAmt ADD MessageType NVARCHAR(MAX)  
  
   
  
 --=============================================  
 --개인별설정(항목별) 체크사항  
   
    --=====================================================================================================================  
    -- 중복된 데이터    
    --=====================================================================================================================  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          6                  , -- 중복된 @1 @2가(이) 입력되었습니다. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                          @LanguageSeq       ,   
                          0,'일자구간 '   -- SELECT * FROM _TCADictionary WHERE Word like '%급여작업군%'  
  
    UPDATE #BasEmpAmt  
       SET Result        = REPLACE(@Results,'@2', A.BegDate),  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #BasEmpAmt AS A JOIN ( SELECT S.EmpSeq, S.PbSeq, S.ItemSeq, S.PaySeq  
                                     FROM (  
                                           SELECT A1.EmpSeq, A1.PbSeq, A1.ItemSeq, A1.PaySeq  
                                             FROM #BasEmpAmt AS A1  
                                                  INNER JOIN _TPRBasEmpAmt AS A2 WITH(NOLOCK) ON A1.EmpSeq = A2.EmpSeq   
                                                                                AND A1.PbSeq = A2.PbSeq   
                                                                                  AND A1.ItemSeq = A2.ItemSeq   
                                                                                AND A2.CompanySeq = @CompanySeq  
                                                                                AND (  (A1.BegDate BETWEEN A2.BegDate AND A2.EndDate)   --종료포함                      OR (A1.EndDate BETWEEN A2.BegDate AND A2.EndDate)   -- 시작포함                                                                                     OR (A2.BegDate >= A1.BegDate AND A2.EndDate <= A1.EndDate)   -- 전체포함                                                                                     )  
                                            WHERE A1.WorkingTag = 'A'  
                                              AND A1.Status = 0  
                                           UNION ALL  
                                           SELECT A1.EmpSeq, A1.PbSeq, A1.ItemSeq, A1.PaySeq  
                                             FROM #BasEmpAmt AS A1  
                                                  INNER JOIN _TPRBasEmpAmt AS A2 WITH(NOLOCK) ON A1.EmpSeq = A2.EmpSeq   
                                                                                AND A1.PbSeq = A2.PbSeq   
                                                                                AND A1.ItemSeq = A2.ItemSeq   
                                                                                AND A1.PaySeq <> A2.Seq  
                                                                                AND A2.CompanySeq = @CompanySeq  
                                                                                AND (  (A1.BegDate BETWEEN A2.BegDate AND A2.EndDate)   -- 종료포함                                                                                     OR (A1.EndDate BETWEEN A2.BegDate AND A2.EndDate)   -- 시작포함                                                                                     OR (A2.BegDate >= A1.BegDate AND A2.EndDate <= A1.EndDate)   -- 전체포함                                                                                     )  
                                            WHERE A1.WorkingTag = 'U'  
                                              AND A1.Status = 0  
                                           UNION ALL  
                                           SELECT A1.EmpSeq, A1.PbSeq, A1.ItemSeq, A1.PaySeq  
                                             FROM #BasEmpAmt AS A1  
                                                  INNER JOIN #BasEmpAmt AS A2 WITH(NOLOCK) ON A1.EmpSeq = A2.EmpSeq   
                                                                                AND A1.PbSeq = A2.PbSeq   
                                                                                AND A1.ItemSeq = A2.ItemSeq   
                                                                                AND A1.DataSeq <> A2.DataSeq  
                                                                                AND (  (A1.BegDate BETWEEN A2.BegDate AND A2.EndDate)   -- 종료포함                                                                                     OR (A1.EndDate BETWEEN A2.BegDate AND A2.EndDate)   -- 시작포함                                                                                     OR (A2.BegDate >= A1.BegDate AND A2.EndDate <= A1.EndDate)   -- 전체포함                                                                                     )  
                                            WHERE A1.WorkingTag = 'A'  
                                              AND A1.Status = 0  
                                           UNION ALL  
                                           SELECT A1.EmpSeq, A1.PbSeq, A1.ItemSeq, A1.PaySeq  
                                             FROM #BasEmpAmt AS A1  
                                                  INNER JOIN #BasEmpAmt AS A2 WITH(NOLOCK) ON A1.EmpSeq = A2.EmpSeq   
                                                                                AND A1.PbSeq = A2.PbSeq   
                                                                                  AND A1.ItemSeq = A2.ItemSeq   
                                                                                AND A1.PaySeq <> A2.PaySeq  
                                                                                AND (  (A1.BegDate BETWEEN A2.BegDate AND A2.EndDate)   -- 종료포함                                                                                     OR (A1.EndDate BETWEEN A2.BegDate AND A2.EndDate)   -- 시작포함                      OR (A2.BegDate >= A1.BegDate AND A2.EndDate <= A1.EndDate)   -- 전체포함                                                                                     )  
                                             WHERE A1.WorkingTag = 'U'  
                                              AND A1.Status = 0  
                                          ) AS S  
                                  ) AS B ON (A.EmpSeq = B.EmpSeq AND A.PbSeq = B.PbSeq AND A.ItemSeq = B.ItemSeq AND A.PaySeq = B.PaySeq)  
  
    --=====================================================================================================================  
    -- 필수입력오류    
    --=====================================================================================================================  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1                  , -- @1을(를) 입력하세요. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)  
                          @LanguageSeq       ,   
                          0,'사원'   -- SELECT * FROM _TCADictionary WHERE Word like '%급여작업군%'  
  
    UPDATE #BasEmpAmt  
       SET Result        = @Results,  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #BasEmpAmt AS A JOIN ( SELECT S.EmpSeq, S.PbSeq, S.ItemSeq, S.PaySeq  
                                         FROM (  
                                               SELECT A1.EmpSeq, A1.PbSeq, A1.ItemSeq, A1.PaySeq  
                                                 FROM #BasEmpAmt AS A1  
                                                WHERE A1.WorkingTag IN ('A','U','D')  
                                                  AND A1.Status = 0  
                                                  AND IsNull(A1.EmpSeq, 0) = 0  
                                              ) AS S  
                                    GROUP BY S.EmpSeq, S.PbSeq, S.ItemSeq, S.PaySeq  
                                  ) AS B ON (A.EmpSeq = B.EmpSeq AND A.PbSeq = B.PbSeq AND A.ItemSeq = B.ItemSeq AND A.PaySeq = B.PaySeq)  
  
  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1                  , -- @1을(를) 입력하세요. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)  
                          @LanguageSeq       ,   
                          0,'급상여구분'   -- SELECT * FROM _TCADictionary WHERE Word like '%급여작업군%'  
    UPDATE #BasEmpAmt  
       SET Result        = @Results,  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #BasEmpAmt AS A JOIN ( SELECT S.EmpSeq, S.PbSeq, S.ItemSeq, S.PaySeq  
                                         FROM (  
                                               SELECT A1.EmpSeq, A1.PbSeq, A1.ItemSeq, A1.PaySeq  
                                                 FROM #BasEmpAmt AS A1  
                                                WHERE A1.WorkingTag IN ('A','U','D')  
                                                  AND A1.Status = 0  
                                                  AND IsNull(A1.PbSeq, 0) = 0  
                                              ) AS S  
                                    GROUP BY S.EmpSeq, S.PbSeq, S.ItemSeq, S.PaySeq  
                                  ) AS B ON (A.EmpSeq = B.EmpSeq AND A.PbSeq = B.PbSeq AND A.ItemSeq = B.ItemSeq AND A.PaySeq = B.PaySeq)  
  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                            @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1                  , -- @1을(를) 입력하세요. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)  
                          @LanguageSeq       ,   
                          0,'급여항목'   -- SELECT * FROM _TCADictionary WHERE Word like '%급여작업군%'  
  
    UPDATE #BasEmpAmt  
       SET Result        = @Results,  
           MessageType   = @MessageType,  
         Status        = @Status  
      FROM #BasEmpAmt AS A JOIN ( SELECT S.EmpSeq, S.PbSeq, S.ItemSeq, S.PaySeq  
                                         FROM (  
                                               SELECT A1.EmpSeq, A1.PbSeq, A1.ItemSeq, A1.PaySeq  
                                                 FROM #BasEmpAmt AS A1  
                                                WHERE A1.WorkingTag IN ('A','U','D')  
                                                  AND A1.Status = 0  
                                                  AND IsNull(A1.ItemSeq, 0) = 0  
                                              ) AS S  
                                    GROUP BY S.EmpSeq, S.PbSeq, S.ItemSeq, S.PaySeq  
                                  ) AS B ON (A.EmpSeq = B.EmpSeq AND A.PbSeq = B.PbSeq AND A.ItemSeq = B.ItemSeq AND A.PaySeq = B.PaySeq)  
  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1                  , -- @1을(를) 입력하세요. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)  
                          @LanguageSeq       ,   
                          0,'시작일'   -- SELECT * FROM _TCADictionary WHERE Word like '%급여작업군%'  
  
    UPDATE #BasEmpAmt  
       SET Result        = @Results,  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #BasEmpAmt AS A JOIN ( SELECT S.EmpSeq, S.PbSeq, S.ItemSeq, S.PaySeq  
                                         FROM (  
                                               SELECT A1.EmpSeq, A1.PbSeq, A1.ItemSeq, A1.PaySeq  
                                                 FROM #BasEmpAmt AS A1  
                                                WHERE A1.WorkingTag IN ('A','U','D')  
                                                  AND A1.Status = 0  
                                                  AND IsNull(A1.BegDate, '') = ''  
                                              ) AS S  
                                    GROUP BY S.EmpSeq, S.PbSeq, S.ItemSeq, S.PaySeq  
                                  ) AS B ON (A.EmpSeq = B.EmpSeq AND A.PbSeq = B.PbSeq AND A.ItemSeq = B.ItemSeq AND A.PaySeq = B.PaySeq)  
  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1                  , -- @1을(를) 입력하세요. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1)  
                          @LanguageSeq       ,   
                          0,'종료일'   -- SELECT * FROM _TCADictionary WHERE Word like '%급여작업군%'  
  
    UPDATE #BasEmpAmt  
       SET Result        = @Results,  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #BasEmpAmt AS A JOIN ( SELECT S.EmpSeq, S.PbSeq, S.ItemSeq, S.PaySeq  
                                         FROM (  
                                               SELECT A1.EmpSeq, A1.PbSeq, A1.ItemSeq, A1.PaySeq  
                                                 FROM #BasEmpAmt AS A1  
                                                WHERE A1.WorkingTag IN ('A','U','D')  
                                                  AND A1.Status = 0  
                                                  AND IsNull(A1.EndDate, '') = ''  
                                              ) AS S  
                                    GROUP BY S.EmpSeq, S.PbSeq, S.ItemSeq, S.PaySeq  
                                    ) AS B ON (A.EmpSeq = B.EmpSeq AND A.PbSeq = B.PbSeq AND A.ItemSeq = B.ItemSeq AND A.PaySeq = B.PaySeq)  
  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          31                 , -- @1이 @2 보다 커야 합니다. (SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 31)  
                          @LanguageSeq       ,   
                          232,'종료일',  -- SELECT * FROM _TCADictionary WHERE Word like '%종료일%'  
                          191,'시작일'   -- SELECT * FROM _TCADictionary WHERE Word like '%시작일%'  
    UPDATE #BasEmpAmt  
       SET Result        = @Results,  
           MessageType   = @MessageType,  
           Status        = @Status  
      FROM #BasEmpAmt AS A   
     WHERE A.WorkingTag IN ('A','U')  
       AND A.Status = 0  
       AND A.BegDate > A.EndDate  
  
*/  
 --기존 데이터 존재여부 확인 후 반영처리 WorkingTag 수정(삭제시 변경 하지 않는다.)  
 IF NOT EXISTS (SELECT 1 FROM #GAHouseCost WHERE WorkingTag = 'D')  
     BEGIN  
         UPDATE #GAHouseCost  
            SET WorkingTag = 'U'  
           FROM #GAHouseCost AS A  
             WHERE ISNULL(A.Seq,0) <> 0   
  END         
    ------------------------------------------  
    -- INSERT번호 부여     ------------------------------------------  
      
    SELECT @Count = COUNT(1) FROM #GAHouseCost WHERE WorkingTag = 'A' --AND WHERE WorkingTag = 'A' --@Count값수정(AND Status = 0 제외) )    
    IF @Count > 0    
    BEGIN  
        -- 키값생성코드부분 시작        
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TPRBasEmpAmt', 'Seq', @Count      
        -- Temp Talbe 에 생성된 키값 UPDATE      
        UPDATE #GAHouseCost      
           SET Seq   = @Seq + DataSeq                  
         WHERE WorkingTag = 'A'      
           AND Status = 0    
    END     
  
/*          
    -- 가장 큰 일련번호를 받아온다.  
    SELECT @MaxSeq = ISNULL(MAX(Seq), 0) FROM _TPRBasEmpAmt WHERE CompanySeq = @CompanySeq   
  
  
  
    -- 입력된 데이터의 수 만큼 데이터의 수 만큼 일련번호를 생성하여 가장 큰 일련번호(@MaxSeq)후로 생성하여 준다.  
    SELECT DataSeq                                        AS IDX_NO,  
           (ROW_NUMBER() OVER(ORDER BY DataSeq)) + @MaxSeq AS MaxSeq  
      INTO #GAHouseCost_Max  
      FROM #BasEmpAmt AS A  
     WHERE (A.WorkingTag = 'A' )  
  
    UPDATE #BasEmpAmt   
       SET PaySeq = B.MaxSeq  
      FROM #BasEmpAmt AS A, #GAHouseCost_Max AS B  
     WHERE (A.WorkingTag = 'A' AND A.Status = 0)  
       AND  A.DataSeq     = B.IDX_NO  
   
 --DELETE #GAHouseCost  
   
  
 UPDATE A  
    SET A.MessageType = B.MessageType,  
     A.Status = B.Status,  
     A.Result = B.Result,  
     A.PaySeq = B.PaySeq  
   FROM #GAHouseCost AS A  
     JOIN #BasEmpAmt AS B ON A.HouseSeq = B.HouseSeq  
          AND A.PbSeq = B.PbSeq  
          AND A.EmpSeq = B.EmpSeq  
          AND A.ItemSeq = B.ItemSeq  
          AND A.PuSeq = B.PuSeq  
    --==============================================================================  
*/  
 --IF EXISTS (SELECT 1 FROM #GAHouseCost WHERE WorkingTag = 'A' AND Status = 0)  
 --BEGIN  
 --SELECT B.WorkingTag, B.DataSeq AS IDX_NO, B.DataSeq, A.Selected, B.MessageType, B.Status,  
 --    B.Result, A.Row_IDX, B.PbSeq, B.ItemSeq, B.PaySeq, B.PuSeq, B.BegDate, B.EndDate, B.Amt,  
 --    B.EmpSeq, B.HouseSeq, A.IsPay, A.BaseDate, B.ClubSeq  
 --  FROM #GAHouseCost AS A  
 --    LEFT OUTER JOIN #BasEmpAmt AS B ON 1=1  
 --END  
 --ELSE BEGIN  
  SELECT * FROM #GAHouseCost  
 --END    
RETURN  

_SCMServiceHistoryWorkCheck