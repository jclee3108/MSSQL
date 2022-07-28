
IF OBJECT_ID('_SSEBracerIndividualManageCheckCHE') IS NOT NULL 
    DROP PROC _SSEBracerIndividualManageCheckCHE
GO 

-- v2015.07.29 

/************************************************************
  설  명 - 데이터-개인보호구지급 Check :  
  작성일 - 2011.03.28
  작성자 - 김수용
 ************************************************************/
 CREATE PROC [dbo].[_SSEBracerIndividualManageCheckCHE]
  @xmlDocument    NVARCHAR(MAX),  
  @xmlFlags       INT     = 0,  
  @ServiceSeq     INT     = 0,  
  @WorkingTag     NVARCHAR(10)= '',  
  @CompanySeq     INT     = 1,  
  @LanguageSeq    INT     = 1,  
  @UserSeq        INT     = 0,  
  @PgmSeq         INT     = 0  
  AS   
   DECLARE @MessageType     INT,
           @Status          INT,
           @Results         NVARCHAR(250),
           @Count           INT,
           @Seq             INT,
           @GWStatus        INT
      
    CREATE TABLE #_TSEBracerCHE (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TSEBracerCHE'
   
 --/****************************************************************************************************************************************/
 --/****************************************************************************************************************************************/
    
    
  --/****************************************************************************************************************************************/
 --/****************************************************************************************************************************************/
    
         -- 마스터의 사원변경시 오류처리
        EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status      OUTPUT,
                               @Results     OUTPUT,
                               1014                  , -- 등록되지 않은 자료를 변경하려 합니다. 조회 후 작업하십시오.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 1014)
                               @LanguageSeq       , 
                               0,'보호구 개인지급'   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'
         UPDATE #_TSEBracerCHE
                SET Result        = @Results,
                    MessageType   = @MessageType,
                    Status        = @Status
               FROM #_TSEBracerCHE 
              WHERE 1 = 1
                AND WorkingTag = 'U'
                AND EmpSeq <> EmpSeqOld 
    
-- 중복여부 체크 :   
       EXEC dbo._SCOMMessage @MessageType OUTPUT,
                               @Status    OUTPUT,
                               @Results   OUTPUT,
                               6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                               @LanguageSeq       , 
                               0,'보호구 개인지급'   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'
      
    UPDATE #_TSEBracerCHE  
       SET Result       = REPLACE(@Results,'@2', Left(A.GiveDate,4)+'-' +SUBSTRING(A.GiveDate,5,2)+'-' + RIGHT(A.GiveDate,2)+' '+ (LTRIM(RTRIM(C.MinorName)) + ' '+ LTRIM(RTRIM(D.MinorName)) + ' ' + RTRIM(LTRIM(E.MinorName))  ) ),
           MessageType  = @MessageType,  
           Status       = @Status  
      FROM #_TSEBracerCHE AS A   
      JOIN (SELECT S.GiveDate, S.BrKind, S.BrType, S.BrSize, S.EmpSeq
              FROM (SELECT A1.GiveDate, A1.BrKind, A1.BrType, A1.BrSize, A1.EmpSeq
                      FROM #_TSEBracerCHE AS A1  
                     WHERE A1.WorkingTag IN ('A', 'U')  
                       AND A1.Status = 0  
                                              
                    UNION ALL  
                                             
                    SELECT A1.GiveDate, A1.BrKind, A1.BrType, A1.BrSize, A1.EmpSeq  
                      FROM _TSEBracerCHE AS A1  
                     WHERE A1.CompanySeq = @CompanySeq   
                       AND NOT EXISTS (SELECT 1 FROM #_TSEBracerCHE   
                                               WHERE WorkingTag IN ('U','D')   
                                                 AND Status = 0   
                                                 AND BracerSeq = A1.BracerSeq  
                                      )  
                   ) AS S  
             GROUP BY S.GiveDate, S.BrKind, S.BrType, S.BrSize, S.EmpSeq
            HAVING COUNT(1) > 1  
           ) AS B ON ( A.GiveDate = B.GiveDate AND A.BrKind = B.BrKind AND A.BrType = B.BrType AND A.BrSize = B.BrSize AND A.EmpSeq = B.EmpSeq )  
      LEFT OUTER JOIN _TDAUMinor AS C
                   ON 1 = 1
                  AND C.CompanySeq = @CompanySeq 
                  AND A.BrKind = C.MinorSeq       
      LEFT OUTER JOIN _TDAUMinor AS D
                   ON 1 = 1
                  AND D.CompanySeq = @CompanySeq 
                  AND A.BrType = D.MinorSeq       
      LEFT OUTER JOIN _TDAUMinor AS E
                   ON 1 = 1
                  AND E.CompanySeq = @CompanySeq 
              AND A.BrSize = E.MinorSeq  
     WHERE A.WorkingTag IN ('A', 'U')  
       AND A.Status = 0  
  
  
  ---- 중복체크
       --EXEC dbo._SCOMMessage @MessageType OUTPUT,
       --                        @Status    OUTPUT,
       --                        @Results   OUTPUT,
       --                        6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
       --                        @LanguageSeq       , 
       --                        0,'보호구 개인지급'   -- SELECT * FROM _TCADictionary WHERE Word like '%구매카드번호%'
  --       UPDATE #_TSEBracerCHE
  --          SET Result        = REPLACE(@Results,'@2', Left(A.GiveDate,4)+'-' +SUBSTRING(A.GiveDate,5,2)+'-' + RIGHT(A.GiveDate,2)+' '+ (LTRIM(RTRIM(C.MinorName)) + ' '+ LTRIM(RTRIM(D.MinorName)) + ' ' + RTRIM(LTRIM(E.MinorName))  ) ),
  --              MessageType   = @MessageType,
  --              Status        = @Status
  --         FROM #_TSEBracerCHE AS A JOIN ( SELECT S.EmpSeq,S.BrKind,S.BrType,S.GiveDate
  --                                                      FROM (SELECT A1.EmpSeq,A1.BrKind,A1.BrType,A1.GiveDate
  --                                                              FROM #_TSEBracerCHE AS A1
  --                                                             WHERE 1 = 1
  --                                                               AND A1.WorkingTag IN ('A', 'U')
  --                                                               AND A1.Status = 0                                                             
  --                                                     --TEMP에 등록인 정보가 원래 테이블에 존재
  --                                                             UNION ALL
  --                                                            SELECT A1.EmpSeq,A1.BrKind,A1.BrType,A1.GiveDate
  --                                                              FROM _TSEBracerCHE AS A1 WITH(NOLOCK)
  --                                                                   JOIN #_TSEBracerCHE AS A2 
  --                                                                     ON  1 = 1
  --                                                                    AND A1.EmpSeq    = A2.EmpSeq
  --                                                                    AND A1.BrKind    = A2.BrKind
  --                                                                    AND A1.BrType    = A2.BrType
  --                                                                    AND A1.GiveDate  = A2.GiveDate
  --                                                             WHERE 1 = 1
  --                                                               AND A1.CompanySeq = @CompanySeq
  --                                                               AND A2.WorkingTag = 'A'
  --                                                               AND A2.Status = 0
  --                                                             UNION ALL
  --                                                             --TEMP에 등록인 정보가 원래 테이블에 존재
  --                                                            SELECT A2.EmpSeq,A2.BrKind,A2.BrType,A2.GiveDate
  --                                                              FROM _TSEBracerCHE AS A1 WITH(NOLOCK)
  --                                                                   JOIN #_TSEBracerCHE AS A2 
  --                                                                     ON 1 = 1
  --                                                                    AND A1.BracerSeq = A2.BracerSeq
  --                                                                    AND ((A1.EmpSeq    <> A2.EmpSeq) OR
  --                                                                         (A1.BrKind    <> A2.BrKind) OR
  --                                                                         (A1.BrType    <> A2.BrType) OR 
  --                                                                         (A1.GiveDate  <> A2.GiveDate))
  --                                                                   JOIN _TSEBracerCHE  AS A3 
  --                                                                     ON 1 = 1
  --                                                                    AND A2.EmpSeq   = A3.EmpSeq
  --                                                                    AND A2.BrKind   = A3.BrKind
  --                                                                    AND A2.BrType   = A3.BrType
  --                                                                    AND A2.GiveDate = A3.GiveDate
                                                              
  --                                                            WHERE 1 = 1
  --                                                              AND A1.CompanySeq = @CompanySeq
  --                                                              AND A2.WorkingTag = 'U'
  --                                                              AND A2.Status = 0 ) AS S
  --                                           GROUP BY S.EmpSeq,S.BrKind,S.BrType,S.GiveDate
  --                                          HAVING COUNT(1) > 1) AS B 
  --                                              ON 1 = 1
  --                                             AND A.EmpSeq   = B.EmpSeq
  --                                             AND A.BrKind   = B.BrKind
  --                                             AND A.BrType   = B.BrType
  --                                             AND A.GiveDate = B.GiveDate
  --    LEFT OUTER JOIN _TDAUMinor AS C
  --                 ON 1 = 1
  --                AND C.CompanySeq = @CompanySeq 
  --                AND A.BrKind = C.MinorSeq       
  --    LEFT OUTER JOIN _TDAUMinor AS D
  --                 ON 1 = 1
  --                AND D.CompanySeq = @CompanySeq 
  --                AND A.BrType = D.MinorSeq       
  --    LEFT OUTER JOIN _TDAUMinor AS E
  --                 ON 1 = 1
  --                AND E.CompanySeq = @CompanySeq 
  --            AND A.BrSize = E.MinorSeq       
                  
   
   
 --/****************************************************************************************************************************************/
 --/****************************************************************************************************************************************/
 --/****************************************************************************************************************************************/
 --/****************************************************************************************************************************************/
  -- ---- guide : 그 외 '키 생성', '진행여부 체크', '마감여부 체크', '확정여부 체크' 등의 체크로직을 넣습니다.
      -------------------------------------------  
     -- INSERT 번호부여(맨 마지막 처리)  
     -------------------------------------------  
     SELECT @Count = COUNT(1) FROM #_TSEBracerCHE WHERE WorkingTag = 'A' --@Count값수정(AND Status = 0 제외)
     IF @Count > 0  
     BEGIN    
        -- 키값생성코드부분 시작    
         EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TSEBracerCHE', 'BracerSeq', @Count  
         -- Temp Talbe 에 생성된 키값 UPDATE  
         UPDATE #_TSEBracerCHE
            SET BracerSeq = @Seq + DataSeq
          WHERE WorkingTag = 'A'  
            AND Status = 0  
  
   
     END   
  SELECT * FROM #_TSEBracerCHE
 RETURN
 GO
 begin tran 
 exec _SSEBracerIndividualManageCheckCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BracerSeq>0</BracerSeq>
    <GiveDate>20150701</GiveDate>
    <BrKind>20057003</BrKind>
    <BrType>20058007</BrType>
    <BrSize>0</BrSize>
    <GiveCnt>1</GiveCnt>
    <Remark />
    <EmpSeqOld>0</EmpSeqOld>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <EmpSeq>2255</EmpSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10000,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100113
rollback 