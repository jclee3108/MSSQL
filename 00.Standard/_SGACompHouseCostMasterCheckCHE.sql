
IF OBJECT_ID('_SGACompHouseCostMasterCheckCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostMasterCheckCHE
GO 

/************************************************************    
 설  명 - 데이터-사택료항목정의정보 : 체크    
 작성일 - 2011.03.15    
 작성자 - 박헌기    
************************************************************/    
CREATE PROC _SGACompHouseCostMasterCheckCHE 
 @xmlDocument    NVARCHAR(MAX),      
 @xmlFlags       INT     = 0,      
 @ServiceSeq     INT     = 0,      
 @WorkingTag     NVARCHAR(10)= '',      
 @CompanySeq     INT     = 1,      
 @LanguageSeq    INT     = 1,      
 @UserSeq        INT     = 0,      
 @PgmSeq         INT     = 0      
    
AS       
    
    DECLARE @MessageType INT,    
            @Status   INT,    
            @Results  NVARCHAR(250),    
            @Count          INT,    
            @Seq            INT,    
            @GWStatus       INT    
         
    CREATE TABLE #TGACompHouseCostMaster (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TGACompHouseCostMaster'    
      
    -----------------------------    
    ---- 시작일,종료일 체크    
    -----------------------------      
    UPDATE #TGACompHouseCostMaster    
       SET ApplyToDate = '999912'    
     WHERE ISNULL(ApplyToDate,'') = ''    
     
    
    SELECT @Results ='차량임시출입정보 신청자와 로긴사용자가 틀립니다.'    
        
    UPDATE #TGACompHouseCostMaster          
       SET Result        = '적용종료월을 적용시작월이후 기간으로 입력하십시오.',           
           MessageType   = 99999,           
           Status        = 99999    
     WHERE ApplyFrDate   > ApplyToDate    
       AND Status        = 0    
       AND WorkingTag IN ('A','U')            
    
    -------------------------------    
    ------ 중복여부 체크    
    -------------------------------      
    ---- guide : 그 외 '키 생성', '진행여부 체크', '마감여부 체크', '확정여부 체크' 등의 체크로직을 넣습니다.    
    
    EXEC dbo._SCOMMessage  @MessageType OUTPUT,      
                           @Status      OUTPUT,      
                           @Results     OUTPUT,      
                           6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)      
                           @LanguageSeq       ,       
                           0,'사택항목명'        
     UPDATE #TGACompHouseCostMaster      
        SET Result        = REPLACE(@Results,'@2',RTRIM(C.MinorName)+'의 '+RTRIM(D.MinorName)),    
            MessageType   = @MessageType,      
            Status        = @Status    
       FROM #TGACompHouseCostMaster AS A     
            JOIN ( SELECT S.HouseClass, S.CostType    
                     FROM (--TEMP에 등록,수정된 정보     
                           SELECT A1.HouseClass, A1.CostType    
                             FROM #TGACompHouseCostMaster AS A1      
                            WHERE A1.WorkingTag IN ('A','U')      
                              AND A1.Status = 0    
                           UNION ALL    
                           --TEMP에 등록인 정보가 원래 테이블에 존재    
                           SELECT A1.HouseClass, A1.CostType    
                             FROM _TGACompHouseCostMaster AS A1 WITH(NOLOCK)    
                                  JOIN #TGACompHouseCostMaster AS A2 ON A1.HouseClass = A2.HouseClass    
                                                                          AND A1.CostType   = A2.CostType    
                            WHERE A1.CompanySeq = @CompanySeq    
                              AND A2.WorkingTag = 'A'    
                              AND A2.Status = 0    
                           UNION ALL    
                           --TEMP에 등록인 정보가 원래 테이블에 존재    
                           SELECT A2.HouseClass, A2.CostType    
                             FROM _TGACompHouseCostMaster AS A1 WITH(NOLOCK)    
                                  JOIN #TGACompHouseCostMaster AS A2 ON A1.CostSeq    = A2.CostSeq    
                                                                          AND ((A1.HouseClass <> A2.HouseClass)    
        OR (A1.CostType   <> A2.CostType))    
                                  JOIN _TGACompHouseCostMaster AS A3 ON A2.HouseClass = A3.HouseClass    
                                                                         AND A2.CostType   = A3.CostType    
                            WHERE A1.CompanySeq = @CompanySeq    
                              AND A2.WorkingTag = 'U'    
                              AND A2.Status = 0    
                          ) AS S    
                    GROUP BY S.HouseClass, S.CostType    
                    HAVING COUNT(1) > 1    
                 ) AS B ON A.HouseClass = B.HouseClass    
                       AND A.CostType   = B.CostType     
             LEFT OUTER JOIN _TDAUMinor AS C WITH(NOLOCK) ON @CompanySeq   = C.CompanySeq    
                                                         AND A.HouseClass    = C.MinorSeq    
             LEFT OUTER JOIN _TDAUMinor AS D WITH(NOLOCK) ON @CompanySeq     = D.CompanySeq    
                                                         AND A.CostType      = D.MinorSeq    
  
  
    -------------------------------------------    
    -- INSERT 번호부여(맨 마지막 처리)    
    -------------------------------------------    
    SELECT @Count = COUNT(1) FROM #TGACompHouseCostMaster WHERE WorkingTag = 'A' --@Count값수정(AND Status = 0 제외)  
    IF @Count > 0        
    BEGIN        
        -- 키값생성코드부분 시작        
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TGACompHouseCostMaster', 'CostSeq', @Count      
        -- Temp Talbe 에 생성된 키값 UPDATE      
        UPDATE #TGACompHouseCostMaster    
           SET CostSeq    = @Seq + DataSeq    
         WHERE WorkingTag = 'A'      
           AND Status = 0    
    END    
        
 SELECT * FROM #TGACompHouseCostMaster    
RETURN        