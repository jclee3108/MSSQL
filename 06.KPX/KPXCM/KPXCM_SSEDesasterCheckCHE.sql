
IF OBJECT_ID('KPXCM_SSEDesasterCheckCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEDesasterCheckCHE
GO 

-- v2015.06.08 

-- 사이트화면으로 Copy by이재천 
/************************************************************  
  설  명 - 데이터-상해관리_capro : 체크  
  작성일 - 20110324  
  작성자 - 박헌기  
 ************************************************************/  
 CREATE PROC dbo.KPXCM_SSEDesasterCheckCHE  
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
    
     CREATE TABLE #KPXCM_TSEDesasterCHE (WorkingTag NCHAR(1) NULL)  
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TSEDesasterCHE'  
     
  -----------------------------  
  ---- 수정을 등록으로   
  -----------------------------  
     UPDATE #KPXCM_TSEDesasterCHE  
        SET WorkingTag = 'A'  
       FROM #KPXCM_TSEDesasterCHE AS A  
      WHERE NOT EXISTS (SELECT 'X'  
                          FROM KPXCM_TSEDesasterCHE AS L1  
                         WHERE L1.CompanySeq = @CompanySeq
                           AND A.AccidentSeq = L1.AccidentSeq)  
    
   
  -- guide : 그 외 '키 생성', '진행여부 체크', '마감여부 체크', '확정여부 체크' 등의 체크로직을 넣습니다.  
      -------------------------------------------  
     -- INSERT 번호부여(맨 마지막 처리)  
     -------------------------------------------  
     SELECT @Count = COUNT(1) FROM #KPXCM_TSEDesasterCHE WHERE WorkingTag = 'A' --@Count값수정(AND Status = 0 제외)
     IF @Count > 0  
     BEGIN      
        -- 키값생성코드부분 시작      
         EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, 'KPXCM_TSEDesasterCHE', 'InjurySeq', @Count    
         -- Temp Talbe 에 생성된 키값 UPDATE    
         UPDATE #KPXCM_TSEDesasterCHE   
            SET InjurySeq = @Seq + DataSeq  
          WHERE WorkingTag = 'A'    
            AND Status = 0  
     END      
   
  SELECT * FROM #KPXCM_TSEDesasterCHE  
    
 RETURN