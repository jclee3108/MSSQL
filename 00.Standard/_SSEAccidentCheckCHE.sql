
IF OBJECT_ID('_SSEAccidentCheckCHE') IS NOT NULL 
    DROP PROC _SSEAccidentCheckCHE
GO 

-- v2015.01.28 
/************************************************************  
  ��  �� - ������-������ : üũ  
  �ۼ��� - 20110324  
  �ۼ��� - õ���  
 ************************************************************/  
 CREATE PROC _SSEAccidentCheckCHE  
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,    
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
  AS  
     DECLARE @Count       INT,  
             @Seq         INT,  
             @Date        NCHAR(8),  
             @MaxNo       NVARCHAR(20),  
             @MessageType INT,  
             @Status      INT,  
             @Results     NVARCHAR(250)  
    
     -- ���� ����Ÿ ��� ����  
     CREATE TABLE #_TSEAccidentCHE (WorkingTag NCHAR(1) NULL)   
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TSEAccidentCHE'  
     IF @@ERROR <> 0 RETURN   
    
      -------------------------------  
     -- ��������� ȭ�� CHECK  
     -------------------------------  
     IF @PgmSeq = 100521    
     BEGIN  
         -------------------------------------------------  
         -- ��������Ͻ� �߻����� ������ ���� ���� Ȯ��  
         -------------------------------------------------  
         UPDATE A  
            SET Result        = '�߻����� �ڷᰡ ������ ����������� �� �� �����ϴ�.',  
                MessageType   = 99999,  
                Status        = 99999  
           FROM #_TSEAccidentCHE AS A  
                LEFT OUTER JOIN _TSEAccidentCHE AS B ON B.CompanySeq   = @CompanySeq  
                                                      AND A.AccidentSeq  = B.AccidentSeq  
                                                      AND B.AccidentSerl = '1'  
          WHERE A.WorkingTag = 'A'  
            AND A.Status = 0  
            AND A.AccidentSerl = '2'  
            AND ISNULL(B.AccidentSeq,0) = 0 
     END  
      -------------------------------  
     -- ���߻������� ȭ�� CHECK  
     -------------------------------  
     ELSE IF @PgmSeq = 100098   -- ��Ű��ȭ �Ǿ ����  1004455 -->100098  
     BEGIN  
         -------------------------------------------  
         -- ������� ��� �Ǿ����� ���� �ȵǰ�  
         -------------------------------------------  
         EXEC dbo._SCOMMessage @MessageType OUTPUT,    
                               @Status      OUTPUT,    
                               @Results     OUTPUT,    
                               8                  , -- ����� ���� �־� ����/���� �� �� �����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageDefault like '%����%')    
                               @LanguageSeq       ,     
                               0, ''  
          UPDATE A  
            SET Result        = @Results,  
                MessageType   = @MessageType,    
                Status        = @Status  
           FROM #_TSEAccidentCHE AS A  
                JOIN _TSEAccidentCHE AS B ON B.CompanySeq   = @CompanySeq  
                                           AND A.AccidentSeq  = B.AccidentSeq  
                                           AND B.AccidentSerl = '2'  
          WHERE A.WorkingTag = 'D'  
            AND A.Status = 0  
    
         -------------------------------------------  
         -- INSERT ��ȣ�ο�(�� ������ ó��)    
         -------------------------------------------    
         SELECT @Count = COUNT(1) FROM #_TSEAccidentCHE WHERE WorkingTag = 'A'  
           
         IF @Count > 0  
         BEGIN  
             SELECT @Date = ISNULL(MAX(AccidentDate), CONVERT(NCHAR(8), GETDATE(), 112))    
               FROM #_TSEAccidentCHE  
              WHERE WorkingTag = 'A'   
                AND Status = 0  
              -- Ű�������ڵ�κ� ����      
             EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TSEAccidentCHE', 'AccidentSeq', @Count  
               
             -- Temp Table�� ������ Ű�� UPDATE  
             UPDATE #_TSEAccidentCHE  
                SET AccidentSeq = @Seq + DataSeq  
              WHERE WorkingTag = 'A'    
                AND Status = 0  
    
             -- ��ȣ�����ڵ�κ� ����      
  
     EXEC dbo._SCOMCreateNo 'SITE', '_TSEAccidentCHE', @CompanySeq, '', @Date, @MaxNo OUTPUT  
         -- Temp Talbe �� ������ Ű�� UPDATE    
             UPDATE #_TSEAccidentCHE    
                SET AccidentNo = @MaxNo  
              WHERE WorkingTag = 'A'  
                AND Status = 0  
         END  
     END  
      SELECT * FROM #_TSEAccidentCHE  
  RETURN  
  