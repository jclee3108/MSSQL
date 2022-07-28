
IF OBJECT_ID('_SPDTestReportItemDetailSaveCHE') IS NOT NULL 
    DROP PROC _SPDTestReportItemDetailSaveCHE
GO 

/************************************************************  
 ��  �� - ������-���輺�����м��׸�Method����Ʈ : ����  
 �ۼ��� - 20120718  
 �ۼ��� - ������  
************************************************************/  
CREATE PROC dbo._SPDTestReportItemDetailSaveCHE  
 @xmlDocument    NVARCHAR(MAX),    
 @xmlFlags       INT     = 0,    
 @ServiceSeq     INT     = 0,    
 @WorkingTag     NVARCHAR(10)= '',    
 @CompanySeq     INT     = 1,    
 @LanguageSeq    INT     = 1,    
 @UserSeq        INT     = 0,    
 @PgmSeq         INT     = 0    
  
AS     
   
 CREATE TABLE #TPDTestReportItemDetail (WorkingTag NCHAR(1) NULL)    
 EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDTestReportItemDetail'       
 IF @@ERROR <> 0 RETURN    
       
  
 -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)  
 EXEC _SCOMLog  @CompanySeq   ,  
          @UserSeq      ,  
          '_TPDTestReportItemDetail', -- �����̺��  
          '#TPDTestReportItemDetail', -- �������̺��  
          'Seq           ,Serl          ' , -- Ű�� �������� ���� , �� �����Ѵ�.   
          'CompanySeq  ,Seq         ,Serl        ,Method       ,  
                    ApplyFrDate ,ApplyToDate ,LastYn      , LastUserSeq ,LastDateTime'  
  
  
 -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT  
  
 -- DELETE      
 IF EXISTS (SELECT TOP 1 1 FROM #TPDTestReportItemDetail WHERE WorkingTag = 'D' AND Status = 0)    
 BEGIN     
   DELETE _TPDTestReportItemDetail  
     FROM #TPDTestReportItemDetail A   
       JOIN _TPDTestReportItemDetail B ON ( A.Seq           = B.Seq )   
                         AND ( A.Serl          = B.Serl )   
                           
    WHERE B.CompanySeq  = @CompanySeq  
      AND A.WorkingTag = 'D'   
      AND A.Status = 0      
    IF @@ERROR <> 0  RETURN  
      
         -- �������� ��ü  
         UPDATE _TPDTestReportItemDetail  
            SET LastYn      = '1' ,  
                ApplyToDate = '99991231'  
              FROM _TPDTestReportItemDetail AS A  
                   JOIN #TPDTestReportItemDetail AS B ON A.Seq = B.Seq  
             WHERE A.CompanySeq = @CompanySeq  
               AND A.Serl = (SELECT MAX(Serl)  
                               FROM _TPDTestReportItemDetail L1  
                              WHERE L1.CompanySeq = A.CompanySeq  
                                AND L1.Seq        = A.Seq)  
               AND B.WorkingTag = 'D'  
               AND B.Status = 0      
            IF @@ERROR <> 0 RETURN         
      
      
 END    
  
  
 -- UPDATE      
 IF EXISTS (SELECT 1 FROM #TPDTestReportItemDetail WHERE WorkingTag = 'U' AND Status = 0)    
 BEGIN  
   UPDATE _TPDTestReportItemDetail  
      SET Method       = A.Method       ,  
                   ApplyFrDate  = A.ApplyFrDate  ,  
                   ApplyToDate  = A.ApplyToDate  ,  
                   LastUserSeq  = @UserSeq       ,  
                   LastDateTime = GETDATE()  
     FROM #TPDTestReportItemDetail AS A   
          JOIN _TPDTestReportItemDetail AS B ON ( A.Seq           = B.Seq )   
                                                          AND ( A.Serl          = B.Serl )   
    WHERE B.CompanySeq = @CompanySeq  
      AND A.WorkingTag = 'U'   
      AND A.Status = 0      
   IF @@ERROR <> 0  RETURN  
     
         -- ���븶������ ����  
         UPDATE _TPDTestReportItemDetail  
            SET ApplyToDate = CONVERT(NVARCHAR(8),DATEADD(DD,-1,B.ApplyFrDate), 112)  
              FROM _TPDTestReportItemDetail AS A  
                   JOIN #TPDTestReportItemDetail AS B ON A.Seq = B.Seq  
             WHERE A.CompanySeq = @CompanySeq  
               AND A.Serl = (SELECT MAX(Serl)  
                               FROM _TPDTestReportItemDetail L1  
                              WHERE L1.CompanySeq = A.CompanySeq  
                                AND L1.Seq        = A.Seq  
                                AND L1.LastYn     = '0')  
               AND B.WorkingTag = 'U'  
               AND B.Status = 0      
            IF @@ERROR <> 0 RETURN          
       
 END    
  
 -- INSERT  
 IF EXISTS (SELECT 1 FROM #TPDTestReportItemDetail WHERE WorkingTag = 'A' AND Status = 0)    
 BEGIN    
         -- �������� ��ü  
         UPDATE _TPDTestReportItemDetail  
            SET LastYn = '0'  ,  
                ApplyToDate = CONVERT(NVARCHAR(8),DATEADD(DD,-1,B.ApplyFrDate), 112)  
              FROM _TPDTestReportItemDetail AS A  
                   JOIN #TPDTestReportItemDetail AS B ON A.Seq = B.Seq  
             WHERE A.CompanySeq = @CompanySeq  
               AND A.LastYn = '1'  
               AND B.WorkingTag = 'A'  
               AND B.Status = 0      
            IF @@ERROR <> 0 RETURN     
  
   INSERT INTO _TPDTestReportItemDetail   
              ( CompanySeq  ,Seq         ,Serl        ,Method      ,  
                         ApplyFrDate ,ApplyToDate ,LastYn      ,LastUserSeq ,LastDateTime)   
         SELECT @CompanySeq ,Seq         ,Serl        ,Method      ,  
                         ApplyFrDate ,ApplyToDate ,'1'         ,@UserSeq    ,GETDATE()  
                    FROM #TPDTestReportItemDetail AS A     
          WHERE A.WorkingTag = 'A'   
            AND A.Status = 0      
   IF @@ERROR <> 0 RETURN  
       
 END     
  
 SELECT * FROM #TPDTestReportItemDetail   
RETURN      
     