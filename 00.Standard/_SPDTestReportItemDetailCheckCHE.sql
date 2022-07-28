
IF OBJECT_ID('_SPDTestReportItemDetailCheckCHE') IS NOT NULL
    DROP PROC _SPDTestReportItemDetailCheckCHE
GO 

/************************************************************  
 설  명 - 데이터-시험성적서분석항목Method리스트 : 체크  
 작성일 - 20120718  
 작성자 - 마스터  
************************************************************/  
CREATE PROC dbo._SPDTestReportItemDetailCheckCHE  
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
         
    CREATE TABLE #TPDTestReportItemDetail (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDTestReportItemDetail'  
   
    UPDATE #TPDTestReportItemDetail      
       SET ApplyToDate = '99991231'  
      FROM #TPDTestReportItemDetail AS A  
     WHERE A.WorkingTag = 'A'  
       AND A.Status     = 0          
    
    -------------------------------------------    
    -- 오류 체크  
    -------------------------------------------       
    UPDATE #TPDTestReportItemDetail      
       SET Result        = '마스터 정보가 없습니다. 저장 할 수 없습니다.',  
           MessageType   = 99999,                      
           Status        = 99999    
      FROM #TPDTestReportItemDetail AS A  
     WHERE A.WorkingTag IN ('A','U')    
       AND ISNULL(A.Seq,0) = 0  
       AND A.Status        = 0          
       
    UPDATE #TPDTestReportItemDetail      
       SET Result        = '적용마지막일이 적용시작일보다 이전 일 수 없습니다.',  
           MessageType   = 99999,                      
           Status        = 99999    
      FROM #TPDTestReportItemDetail AS A  
     WHERE A.WorkingTag IN ('A','U')    
       AND A.ApplyFrDate > A.ApplyToDate  
       AND A.Status     = 0  
      
    UPDATE #TPDTestReportItemDetail      
       SET Result        = '최종정보만 수정, 삭제 할 수 있습니다.',  
           MessageType   = 99999,                      
           Status        = 99999    
      FROM #TPDTestReportItemDetail AS A  
           JOIN _TPDTestReportItemDetail AS B ON A.Seq = B.Seq  
                                                  AND A.Serl= B.Serl  
     WHERE ISNULL(B.LastYn,0) = '0'  
       AND A.WorkingTag IN ('U','D')    
       AND A.Status     = 0  
         
    UPDATE #TPDTestReportItemDetail      
       SET Result        = '최종정보보다 시작일이 같거나 이전일 수 없습니다.',  
           MessageType   = 99999,                      
           Status        = 99999    
      FROM #TPDTestReportItemDetail AS A  
           JOIN _TPDTestReportItemDetail AS B ON A.Seq    = B.Seq  
                                                  AND B.LastYn = '1'  
     WHERE B.CompanySeq  = @CompanySeq  
       AND A.ApplyFrDate <= B.ApplyFrDate  
       AND A.WorkingTag  IN ('A','U')    
       AND A.Status      = 0  
    -------------------------------------------    
    -- INSERT 번호부여(맨 마지막 처리)    
    -------------------------------------------    
    SELECT @Count = COUNT(1)   
      FROM #TPDTestReportItemDetail  
     WHERE WorkingTag = 'A'   
       AND Status = 0      
       
    IF @Count > 0  
    BEGIN      
        -- 키값생성코드부분 시작      
        SELECT @Seq = ISNULL((SELECT MAX(A.Serl)  
                                FROM _TPDTestReportItemDetail AS A    
                               WHERE A.CompanySeq = @CompanySeq  
                                 AND A.Seq IN (SELECT Seq  
                                                 FROM #TPDTestReportItemDetail  
                                                WHERE Seq = A.Seq)), 0)  
        -- Temp Table에 생성된 키값 UPDATE    
        UPDATE #TPDTestReportItemDetail  
           SET Serl = @Seq + DataSeq  
          FROM #TPDTestReportItemDetail  
         WHERE WorkingTag = 'A'  
           AND Status = 0    
    END      
  
 SELECT * FROM #TPDTestReportItemDetail   
  
  RETURN      
     