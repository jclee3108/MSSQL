
IF OBJECT_ID('KPXCM_SSEChemicalsListCheckCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEChemicalsListCheckCHE
GO 

-- v2015.06.22 

-- 사이트로 개발 by이재천 

/************************************************************
  설  명 - 데이터-화학물질품목관리_capro : 체크
  작성일 - 20110602
  작성자 - 박헌기
 ************************************************************/
 CREATE PROC dbo.KPXCM_SSEChemicalsListCheckCHE
  @xmlDocument    NVARCHAR(MAX),  
  @xmlFlags       INT     = 0,  
  @ServiceSeq     INT     = 0,  
  @WorkingTag     NVARCHAR(10)= '',  
  @CompanySeq     INT     = 2,  
  @LanguageSeq    INT     = 1,  
  @UserSeq        INT     = 0,  
  @PgmSeq         INT     = 0 
  AS   
   DECLARE @MessageType        INT,
          @Status             INT,
          @Count              INT,
          @Seq                INT,
          @Results            NVARCHAR(250)
    
    CREATE TABLE #KPXCM_TSEChemicalsListCHE (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TSEChemicalsListCHE'
   
  -----------------------------
  ---- 필수입력 체크
  -----------------------------
  
  -----------------------------
  ---- 중복여부 체크
  -----------------------------  
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                           @Status      OUTPUT,  
                           @Results     OUTPUT,  
                           6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)  
                           @LanguageSeq       ,   
                           0,''
     UPDATE #KPXCM_TSEChemicalsListCHE
        SET Result        = @Results,
            MessageType   = @MessageType,
            Status        = @Status
       FROM #KPXCM_TSEChemicalsListCHE AS A JOIN ( SELECT S.ItemSeq, S.Content
                                              FROM (
                                                    SELECT A1.ItemSeq, A1.Content
                                                      FROM #KPXCM_TSEChemicalsListCHE AS A1  
                                                     WHERE A1.WorkingTag IN ('A', 'U')
                                                       AND A1.Status = 0
                                                    UNION ALL
                                                    SELECT A1.ItemSeq, A1.Content
                                                      FROM KPXCM_TSEChemicalsListCHE AS A1 WITH(NOLOCK)
                                                     WHERE A1.CompanySeq = @CompanySeq
                                                       AND A1.ChmcSeq NOT IN (SELECT ChmcSeq 
                                                                                FROM #KPXCM_TSEChemicalsListCHE
                                                                               WHERE WorkingTag IN ('U', 'D')
                                                                                 AND Status = 0)
                                                   ) AS S
                                             GROUP BY S.ItemSeq, S.Content
                                             HAVING COUNT(1) > 1
                                           ) AS B ON A.ItemSeq   = B.ItemSeq
                                                 AND A.Content = B.Content
  
 -- guide : 그 외 '키 생성', '진행여부 체크', '마감여부 체크', '확정여부 체크' 등의 체크로직을 넣습니다.
      -------------------------------------------  
     -- INSERT 번호부여(맨 마지막 처리)  
     -------------------------------------------  
     SELECT @Count = COUNT(1) FROM #KPXCM_TSEChemicalsListCHE WHERE WorkingTag = 'A' --@Count값수정(AND Status = 0 제외)
     IF @Count > 0  
     BEGIN    
        -- 키값생성코드부분 시작    
         EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TSEChemicalsListCHE', 'ChmcSeq', @Count  
         -- Temp Talbe 에 생성된 키값 UPDATE  
         UPDATE #KPXCM_TSEChemicalsListCHE 
            SET ChmcSeq = @Seq + DataSeq
          WHERE WorkingTag = 'A'  
            AND Status = 0
     END    
   SELECT * FROM #KPXCM_TSEChemicalsListCHE 
  
 RETURN