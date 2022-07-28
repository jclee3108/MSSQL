
IF OBJECT_ID('_SPDToolFileQueryCHE') IS NOT NULL 
    DROP PROC _SPDToolFileQueryCHE
GO 

/************************************************************  
 ��  �� - ������ ÷������  
 �ۼ��� - 2009�� 11�� 18��   
 �ۼ��� - ������  
 ************************************************************/  
 CREATE PROC dbo._SPDToolFileQueryCHE
     @xmlDocument    NVARCHAR(MAX) ,              
     @xmlFlags       INT = 0,              
     @ServiceSeq     INT = 0,              
     @WorkingTag     NVARCHAR(10)= '',                    
     @CompanySeq     INT = 1,              
     @LanguageSeq    INT = 1,              
     @UserSeq        INT = 0,              
     @PgmSeq         INT = 0                 
                   
 AS          
        
      DECLARE @docHandle      INT,  
             @ToolSeq        INT  
                     
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
         
      SELECT  @ToolSeq        = ISNULL(ToolSeq        ,0)  
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock7', @xmlFlags)  
       WITH (ToolSeq         INT)  
    
     SELECT   A.ToolSeq  
             ,A.FileSerl AS FileSeq  
       FROM _TPDToolDetailFile   AS A WITH(NOLOCK)  
      WHERE CompanySeq = @CompanySeq  
        AND A.ToolSeq  = @ToolSeq   
    
 RETURN  
 /***************************************************************************************************************/  