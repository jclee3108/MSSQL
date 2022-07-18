
IF OBJECT_ID('KPX_SDAUMinorCheck') IS NOT NULL 
    DROP PROC KPX_SDAUMinorCheck
GO 

-- v2014.12.01 

-- by이재천
/***********************************************************
  설  명 - 사용자정의기타코드(소분류) 체크
  작성일 - 2008.7.30 :
  작성자 - CREATEd by 신국철
  수정일 - 
 ************************************************************/
  -- SP파라미터들
 CREATE PROCEDURE KPX_SDAUMinorCheck
     @xmlDocument NVARCHAR(MAX)   ,    -- : 화면의 정보를 XML문서로 전달
     @xmlFlags    INT = 0         ,    -- : 해당 XML문서의 Type
     @ServiceSeq  INT = 0         ,    -- : 서비스 번호
     @WorkingTag  NVARCHAR(10)= '',    -- : WorkingTag
     @CompanySeq  INT = 1         ,    -- : 회사 번호
     @LanguageSeq INT = 1         ,    -- : 언어 번호
     @UserSeq     INT = 0         ,    -- : 사용자 번호
     @PgmSeq      INT = 0              -- : 프로그램 번호
  AS
      -- 사용할 변수를 선언한다.
     DECLARE @Count       INT,
             @Seq         INT,
             @MessageType INT,
             @Status      INT,
             @Results     NVARCHAR(250)
  
  
      -- 서비스 마스터 등록 생성
     CREATE TABLE #TDAUMinor (WorkingTag NCHAR(1) NULL)
      -- 임시 테이블에 지정된 컬럼을 추가하고, XML문서로부터의 값을 INSERT한다.
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TDAUMinor'
      IF @@ERROR <> 0
     BEGIN
         RETURN    -- 에러가 발생하면 리턴
     END
  
  
   
     -------------------------------------------  
     -- INSERT 번호부여(맨 마지막 처리)  
     -------------------------------------------  
     SELECT @Count = COUNT(DISTINCT RowNum) FROM #TDAUMinor WHERE (WorkingTag = 'A' AND Status = 0)
      IF(@Count > 0)
     BEGIN
  
     --1)현재 Minor에서 숫자를 더한것이 999번을 넘는지 확인한다
      DECLARE @ChkSeq     INT,
             @MaxMinorSeq INT,
             @CurrSeq    INT,
             @PreCntSeq  INT,
             @NewCntSeq  INT,
             @MaxSeq     INT,
             @MajorLen   INT,
             @MinorLen  INT
              
      SELECT @ChkSeq     = CONVERT(INT,RIGHT('9999999999',len(max(MinorSeq)) - Len(MajorSeq))),
             @MaxMinorSeq= CONVERT(INT, RIGHT(max(minorseq),len(max(MinorSeq)) - Len(MajorSeq)) + @Count),
             @CurrSeq    = max(minorseq),
             @MajorLen   = LEN(MajorSeq),
             @MinorLen   = LEN(MAX(MinorSeq) - LEN(MajorSeq))
       FROM _TDAUMInor A
      WHERE A.CompanySeq = @CompanySeq
        AND EXISTS (SELECT *
                     FROM #TDAUMinor
                    WHERE MajorSeq = A.MajorSeq
                  )
             group by majorseq
             
     IF @ChkSeq < @MaxMinorSeq
     BEGIN
         --넘을 경우 이전 번호대와 현재 번호대를 확인한다.
        --1)기존번호대 사용
           IF @MajorLen+4 >10 
          BEGIN
             --키 자리수 초과  이상 등록 불가능
             -------------------------------------------
             EXEC dbo._SCOMMessage @MessageType OUTPUT,
                                   @Status      OUTPUT,
                                   @Results     OUTPUT,
                                   1028                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)
                                   @LanguageSeq       , 
                                   0,''   -- SELECT * FROM _TCADictionary WHERE Word like '%활동센터%'
             UPDATE #TDAUMinor
                SET Result        = @Results,  
                    MessageType   = @MessageType,  
                    Status        = @Status   
             WHERE (WorkingTag = 'A' AND Status = 0)
             
          END
        
             UPDATE #TDAUMinor
                SET MinorSeq = ISNULL(@CurrSeq, A.MajorSeq * 1000) + (SELECT COUNT(*)
                                                                    FROM (SELECT DISTINCT RowNum
                                                                            FROM #TDAUMinor
                                                                           WHERE (WorkingTag = 'A' AND Status = 0)
                                                                         ) AS X
                                                                   WHERE X.RowNum <= A.RowNum
                      
                                                                 )
               FROM #TDAUMinor AS A
              WHERE (A.WorkingTag =  'A' AND A.Status = 0)
              SELECT @MaxSeq = (SELECT MAX(MinorSeq)
                              FROM _TDAUMinor AS A  
                             WHERE A.CompanySeq = @CompanySeq  
                               AND EXISTS (SELECT *
                                             FROM #TDAUMinor
                                            WHERE MajorSeq *10 = A.MajorSeq
                                          )
                           )
  
             UPDATE #TDAUMinor
                SET MinorSeq = ISNULL(@MaxSeq, A.MajorSeq * 10000) + (SELECT COUNT(*)
                                                                    FROM (SELECT DISTINCT RowNum
                                                                            FROM #TDAUMinor
                                                                           WHERE (WorkingTag = 'A' AND Status = 0)
                                                                             AND MinorSeq  > MajorSeq *1000 + @ChkSeq
                                                                         ) AS X
                                                                   WHERE X.RowNum <= A.RowNum
                                                                    
                                                                 )
               FROM #TDAUMinor AS A
             WHERE (A.MinorSeq  > A.MajorSeq *1000 + @ChkSeq)
              AND (A.WorkingTag = 'A' AND A.Status = 0)
  
         --2)새로운 번호대 사용
     END 
     ELSE
     BEGIN
          --2)넘지않는경우 이전과 동일  
             IF @MinorLen - @MajorLen > 3
             BEGIN
              
                 SELECT @Seq = (SELECT MAX(MinorSeq)
                                  FROM _TDAUMinor AS A  
                                 WHERE A.CompanySeq = @CompanySeq  
                                   AND EXISTS (SELECT *
                                                 FROM #TDAUMinor
                                                WHERE MajorSeq * 10 = A.MajorSeq 
                                              )
                               )
                  SELECT @MaxSeq = (SELECT MAX(MinorSeq)
                                  FROM _TDAUMinor AS A  
                                 WHERE A.CompanySeq = @CompanySeq  
                                   AND EXISTS (SELECT *
                                                 FROM #TDAUMinor
                                                WHERE MajorSeq = A.MajorSeq 
                                              )
                               )
                  IF ISNULL(@MaxSeq,0) > ISNULL(@Seq,0)
                  SELECT @Seq = @MaxSeq
                    
                  UPDATE #TDAUMinor
                    SET MinorSeq = ISNULL(@Seq, A.MajorSeq * 10000) + (SELECT COUNT(*)
                                                                        FROM (SELECT DISTINCT RowNum
                                                                                FROM #TDAUMinor
                                                                               WHERE (WorkingTag = 'A' AND Status = 0)
                                                                             ) AS X
                                                                       WHERE X.RowNum <= A.RowNum
                                                                     )
                   FROM #TDAUMinor AS A
                   WHERE (A.WorkingTag = 'A' AND A.Status = 0)
                  
             END  
             ELSE
             BEGIN
                 SELECT @Seq = (SELECT MAX(MinorSeq)
                                  FROM _TDAUMinor AS A  
                                 WHERE A.CompanySeq = @CompanySeq  
                                   AND EXISTS (SELECT *
                                                 FROM #TDAUMinor
                                                WHERE MajorSeq = A.MajorSeq
                                              )
                               )
  
                 UPDATE #TDAUMinor
                    SET MinorSeq = ISNULL(@Seq, A.MajorSeq * 1000) + (SELECT COUNT(*)
                                                                        FROM (SELECT DISTINCT RowNum
                                                                                FROM #TDAUMinor
                                                                               WHERE (WorkingTag = 'A' AND Status = 0)
                                                                             ) AS X
                                                                       WHERE X.RowNum <= A.RowNum
                                                                     )
                   FROM #TDAUMinor AS A
                  WHERE (A.WorkingTag = 'A' AND A.Status = 0)
             END
       
     END
       
  
  --         UPDATE #TDAUMinor  
 --            SET MinorSeq = @Seq + DataSeq  
 --          WHERE WorkingTag = 'A'  
 --            AND Status = 0
      END
  
  
      SELECT * FROM #TDAUMinor    -- Output
  RETURN