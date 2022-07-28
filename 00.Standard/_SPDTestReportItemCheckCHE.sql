
IF OBJECT_ID('_SPDTestReportItemCheckCHE') IS NOT NULL 
    DROP PROC _SPDTestReportItemCheckCHE
GO 

/************************************************************  
 설  명 - 데이터-시험성적서분석항목Method마스터 : 체크  
 작성일 - 20120718  
 작성자 - 마스터  
************************************************************/  
CREATE PROC dbo._SPDTestReportItemCheckCHE
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
   @Status    INT,  
   @Results   NVARCHAR(250),  
   @Count              INT,  
   @Seq                INT  
         
    CREATE TABLE #TPDTestReportItem (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDTestReportItem'  
    
     EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                           @Status      OUTPUT,    
                           @Results     OUTPUT,    
                           6                  , -- 중복된 @1 @2가(이) 입력되었습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
                           @LanguageSeq       ,     
                           0,''  
     UPDATE #TPDTestReportItem  
        SET Result        = @Results,  
            MessageType   = @MessageType,  
            Status        = @Status  
       FROM #TPDTestReportItem AS A   
            JOIN ( SELECT S.ItemSeq, S.ItemCode  
                     FROM (SELECT A1.ItemSeq, A1.ItemCode  
                             FROM #TPDTestReportItem AS A1    
                            WHERE A1.WorkingTag IN ('A', 'U')  
                              AND A1.Status = 0  
                            UNION ALL  
                           SELECT A1.ItemSeq, A1.ItemCode  
                             FROM _TPDTestReportItem AS A1 WITH(NOLOCK)  
                            WHERE A1.CompanySeq = @CompanySeq  
                              AND NOT EXISTS (SELECT 'X'  
                                                FROM #TPDTestReportItem L1  
                                               WHERE L1.WorkingTag IN ('U', 'D')  
                                                 AND L1.Seq = A1.Seq  
                                                 AND Status = 0)  
                          ) AS S  
                    GROUP BY S.ItemSeq, S.ItemCode  
                   HAVING COUNT(1) > 1  
            ) AS B ON A.ItemSeq     = B.ItemSeq  
                  AND A.ItemCode    = B.ItemCode  
  
      
      
    -------------------------------------------    
    -- INSERT 번호부여(맨 마지막 처리)    
    -------------------------------------------    
    -- 코드값 생성  
    SELECT @Count = COUNT(1) FROM #TPDTestReportItem WHERE WorkingTag = 'A' --@Count값수정(AND Status = 0 제외)  
    IF @Count > 0    
    BEGIN      
   
       -- 키값생성코드부분 시작      
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TPDTestReportItem', 'Seq', @Count    
        -- Temp Talbe 에 생성된 키값 UPDATE    
        UPDATE #TPDTestReportItem  
           SET Seq = @Seq + DataSeq  
         WHERE WorkingTag = 'A'    
           AND Status = 0    
    
    END       
    
    
    SELECT * FROM #TPDTestReportItem   
   
    RETURN      
     