
IF OBJECT_ID('_SPDTestReportItemCheckCHE') IS NOT NULL 
    DROP PROC _SPDTestReportItemCheckCHE
GO 

/************************************************************  
 ��  �� - ������-���輺�����м��׸�Method������ : üũ  
 �ۼ��� - 20120718  
 �ۼ��� - ������  
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
                           6                  , -- �ߺ��� @1 @2��(��) �ԷµǾ����ϴ�.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 6)    
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
    -- INSERT ��ȣ�ο�(�� ������ ó��)    
    -------------------------------------------    
    -- �ڵ尪 ����  
    SELECT @Count = COUNT(1) FROM #TPDTestReportItem WHERE WorkingTag = 'A' --@Count������(AND Status = 0 ����)  
    IF @Count > 0    
    BEGIN      
   
       -- Ű�������ڵ�κ� ����      
        EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TPDTestReportItem', 'Seq', @Count    
        -- Temp Talbe �� ������ Ű�� UPDATE    
        UPDATE #TPDTestReportItem  
           SET Seq = @Seq + DataSeq  
         WHERE WorkingTag = 'A'    
           AND Status = 0    
    
    END       
    
    
    SELECT * FROM #TPDTestReportItem   
   
    RETURN      
     