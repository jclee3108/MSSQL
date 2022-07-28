
IF OBJECT_ID('_SPDTestExpReportCheckCHE') IS NOT NULL 
    DROP PROC _SPDTestExpReportCheckCHE
GO 
    
/************************************************************  
 ��  �� - ������-���輺�������(����) : üũ  
 �ۼ��� - 20110922  
 �ۼ��� - �����  
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
    -- 'A','U'����   
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
         
    -- guide : �� �� 'Ű ����', '���࿩�� üũ', '�������� üũ', 'Ȯ������ üũ' ���� üũ������ �ֽ��ϴ�.  
  
    -------------------------------------------    
    -- INSERT ��ȣ�ο�(�� ������ ó��)    
    -------------------------------------------    
    SELECT @Count = COUNT(1) FROM #TPDTestExpReport WHERE WorkingTag = 'A' --@Count������(AND Status = 0 ����)  
    IF @Count > 0    
    BEGIN      
       -- Ű�������ڵ�κ� ����      
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TPDTestExpReport', 'TestReportSeq', @Count  
        -- Temp Talbe �� ������ Ű�� UPDATE    
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
      
        -- Ű�������ڵ�κ� ����      
        SELECT @Seq = ISNULL((SELECT MAX(A.TestReportSerl)  
                                FROM _TPDTestExpReportList AS A    
                               WHERE A.CompanySeq = @CompanySeq  
                                 AND A.TestReportSeq IN (SELECT TestReportSeq  
                                                           FROM #TPDTestExpReportList  
                                                          WHERE TestReportSeq = A.TestReportSeq)), 0)  
     
        -- Temp Table�� ������ Ű�� UPDATE    
        UPDATE #TPDTestExpReportList   
           SET TestReportSerl = @Seq + DataSeq  
          FROM #TPDTestExpReportList  
         WHERE WorkingTag = 'A'  
           AND Status = 0    
  
  
    END    
  
 SELECT * FROM #TPDTestExpReport   
 SELECT * FROM #TPDTestExpReportList  
    
  RETURN     