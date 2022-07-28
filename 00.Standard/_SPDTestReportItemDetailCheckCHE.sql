
IF OBJECT_ID('_SPDTestReportItemDetailCheckCHE') IS NOT NULL
    DROP PROC _SPDTestReportItemDetailCheckCHE
GO 

/************************************************************  
 ��  �� - ������-���輺�����м��׸�Method����Ʈ : üũ  
 �ۼ��� - 20120718  
 �ۼ��� - ������  
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
    -- ���� üũ  
    -------------------------------------------       
    UPDATE #TPDTestReportItemDetail      
       SET Result        = '������ ������ �����ϴ�. ���� �� �� �����ϴ�.',  
           MessageType   = 99999,                      
           Status        = 99999    
      FROM #TPDTestReportItemDetail AS A  
     WHERE A.WorkingTag IN ('A','U')    
       AND ISNULL(A.Seq,0) = 0  
       AND A.Status        = 0          
       
    UPDATE #TPDTestReportItemDetail      
       SET Result        = '���븶�������� ��������Ϻ��� ���� �� �� �����ϴ�.',  
           MessageType   = 99999,                      
           Status        = 99999    
      FROM #TPDTestReportItemDetail AS A  
     WHERE A.WorkingTag IN ('A','U')    
       AND A.ApplyFrDate > A.ApplyToDate  
       AND A.Status     = 0  
      
    UPDATE #TPDTestReportItemDetail      
       SET Result        = '���������� ����, ���� �� �� �ֽ��ϴ�.',  
           MessageType   = 99999,                      
           Status        = 99999    
      FROM #TPDTestReportItemDetail AS A  
           JOIN _TPDTestReportItemDetail AS B ON A.Seq = B.Seq  
                                                  AND A.Serl= B.Serl  
     WHERE ISNULL(B.LastYn,0) = '0'  
       AND A.WorkingTag IN ('U','D')    
       AND A.Status     = 0  
         
    UPDATE #TPDTestReportItemDetail      
       SET Result        = '������������ �������� ���ų� ������ �� �����ϴ�.',  
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
    -- INSERT ��ȣ�ο�(�� ������ ó��)    
    -------------------------------------------    
    SELECT @Count = COUNT(1)   
      FROM #TPDTestReportItemDetail  
     WHERE WorkingTag = 'A'   
       AND Status = 0      
       
    IF @Count > 0  
    BEGIN      
        -- Ű�������ڵ�κ� ����      
        SELECT @Seq = ISNULL((SELECT MAX(A.Serl)  
                                FROM _TPDTestReportItemDetail AS A    
                               WHERE A.CompanySeq = @CompanySeq  
                                 AND A.Seq IN (SELECT Seq  
                                                 FROM #TPDTestReportItemDetail  
                                                WHERE Seq = A.Seq)), 0)  
        -- Temp Table�� ������ Ű�� UPDATE    
        UPDATE #TPDTestReportItemDetail  
           SET Serl = @Seq + DataSeq  
          FROM #TPDTestReportItemDetail  
         WHERE WorkingTag = 'A'  
           AND Status = 0    
    END      
  
 SELECT * FROM #TPDTestReportItemDetail   
  
  RETURN      
     