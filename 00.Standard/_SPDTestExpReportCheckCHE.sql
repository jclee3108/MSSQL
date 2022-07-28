
IF OBJECT_ID('_SPDTestExpReportCheckCHE') IS NOT NULL 
    DROP PROC _SPDTestExpReportCheckCHE
GO 
    
/************************************************************  
 설  명 - 데이터-시험성적서등록(영업) : 체크  
 작성일 - 20110922  
 작성자 - 박헌기  
************************************************************/  
CREATE PROC dbo._SPDTestExpReportCheckCHE
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
   @Seq            INT  
     
         
    CREATE TABLE #TPDTestExpReport (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDTestExpReport'  
    IF @@ERROR <> 0 RETURN    
    
    CREATE TABLE #TPDTestExpReportList (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TPDTestExpReportList'  
    IF @@ERROR <> 0 RETURN    
  
    -------------------------------------------    
    -- 'A','U'변경   
    -------------------------------------------        
    UPDATE #TPDTestExpReport  
       SET WorkingTag =  'A'  
      FROM #TPDTestExpReport     AS A  
     WHERE NOT EXISTS (SELECT 'X'  
                         FROM _TPDTestExpReport AS L1  
                        WHERE L1.CompanySeq    = @CompanySeq  
                          AND L1.TestReportSeq = A.TestReportSeq)  
       AND WorkingTag = 'U'  
       AND Status     = 0  
         
    -- guide : 그 외 '키 생성', '진행여부 체크', '마감여부 체크', '확정여부 체크' 등의 체크로직을 넣습니다.  
  
    -------------------------------------------    
    -- INSERT 번호부여(맨 마지막 처리)    
    -------------------------------------------    
    SELECT @Count = COUNT(1) FROM #TPDTestExpReport WHERE WorkingTag = 'A' --@Count값수정(AND Status = 0 제외)  
    IF @Count > 0    
    BEGIN      
       -- 키값생성코드부분 시작      
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TPDTestExpReport', 'TestReportSeq', @Count  
        -- Temp Talbe 에 생성된 키값 UPDATE    
        UPDATE #TPDTestExpReport  
           SET TestReportSeq = @Seq + 1  
         WHERE WorkingTag = 'A'    
           AND Status = 0  
             
    END     
  
    UPDATE #TPDTestExpReportList  
       SET TestReportSeq = (SELECT DISTINCT H1.TestReportSeq  
                              FROM #TPDTestExpReport AS H1  
                             WHERE Status = 0)  
      FROM #TPDTestExpReportList AS A  
     WHERE WorkingTag = 'A'    
       AND Status = 0  
  
    SELECT @Count = COUNT(1)  
      FROM #TPDTestExpReportList   
     WHERE WorkingTag = 'A'   
       AND Status = 0  
  
    IF @Count > 0    
    BEGIN      
      
        -- 키값생성코드부분 시작      
        SELECT @Seq = ISNULL((SELECT MAX(A.TestReportSerl)  
                                FROM _TPDTestExpReportList AS A    
                               WHERE A.CompanySeq = @CompanySeq  
                                 AND A.TestReportSeq IN (SELECT TestReportSeq  
                                                           FROM #TPDTestExpReportList  
                                                          WHERE TestReportSeq = A.TestReportSeq)), 0)  
     
        -- Temp Table에 생성된 키값 UPDATE    
        UPDATE #TPDTestExpReportList   
           SET TestReportSerl = @Seq + DataSeq  
          FROM #TPDTestExpReportList  
         WHERE WorkingTag = 'A'  
           AND Status = 0    
  
  
    END    
  
 SELECT * FROM #TPDTestExpReport   
 SELECT * FROM #TPDTestExpReportList  
    
  RETURN     