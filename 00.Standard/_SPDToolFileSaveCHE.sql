
IF OBJECT_ID('_SPDToolFileSaveCHE') IS NOT NULL 
    DROP PROC _SPDToolFileSaveCHE
GO 

/************************************************************  
 ��  �� - ������ ÷������  
 �ۼ��� - 2009�� 11�� 18��   
 �ۼ��� - ������  
 ************************************************************/  
 CREATE PROC dbo._SPDToolFileSaveCHE  
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,    
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
  AS      
    
     DECLARE @ProcSeq    INT,  
             @InputDate  NCHAR(8)  
      -- ���� ����Ÿ ��� ����  
     CREATE TABLE #TPDToolDetailFile (WorkingTag NCHAR(1) NULL)    
     EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock7', '#TPDToolDetailFile'       
     IF @@ERROR <> 0 RETURN      
    
     -- �۾����� ���߱�: DELETE -> UPDATE -> INSERT  
      -- DELETE      
     IF EXISTS (SELECT TOP 1 1 FROM #TPDToolDetailFile WHERE WorkingTag = 'D' AND Status = 0)    
     BEGIN    
         DELETE _TPDToolDetailFile  
           FROM _TPDToolDetailFile   AS A   
             JOIN #TPDToolDetailFile AS B ON A.ToolSeq = B.ToolSeq  
          WHERE B.WorkingTag = 'D'   
            AND B.Status = 0  
            AND A.CompanySeq  = @CompanySeq  
         IF @@ERROR <> 0  RETURN  
      END    
    
    
     UPDATE _TPDToolDetailFile  
        SET  FileSerl            = B.FileSeq                 ,  
             LastUserSeq         = @UserSeq                  ,  
             LastDateTime        = GETDATE()  
       FROM _TPDToolDetailFile   AS A   
         JOIN #TPDToolDetailFile AS B ON A.ToolSeq = B.ToolSeq  
      WHERE B.Status = 0      
        AND A.CompanySeq  = @CompanySeq    
     IF @@ERROR <> 0  RETURN  
    
    
    
      INSERT INTO _TPDToolDetailFile   
                (CompanySeq,ToolSeq,FileSerl,AttachFileName,SMAttachFileKind,AttachFileSeq,Remark,LastUserSeq,LastDateTime)  
         SELECT  @CompanySeq,ToolSeq,FileSeq,'',0,0,'',  
                 @UserSeq           ,GETDATE()    
           FROM #TPDToolDetailFile AS A     
          WHERE A.WorkingTag IN ('A','U')  
            AND A.Status = 0      
            AND NOT EXISTS(SELECT 1 FROM _TPDToolDetailFile WHERE CompanySeq = @CompanySeq AND ToolSeq = A.ToolSeq AND FileSerl = A.FileSeq)  
     IF @@ERROR <> 0 RETURN  
    
     SELECT * FROM #TPDToolDetailFile     
     RETURN      
 /*******************************************************************************************************************/  