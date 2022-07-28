
IF OBJECT_ID('_SPDTestReportItemDetailQueryCHE') IS NOT NULL 
    DROP PROC _SPDTestReportItemDetailQueryCHE 
GO 

/************************************************************  
 ��  �� - ������-���輺�����м��׸�Method����Ʈ : ��ȸ  
 �ۼ��� - 20120718  
 �ۼ��� - ������  
************************************************************/  
CREATE PROC dbo._SPDTestReportItemDetailQueryCHE                  
 @xmlDocument    NVARCHAR(MAX) ,              
 @xmlFlags     INT  = 0,              
 @ServiceSeq     INT  = 0,              
 @WorkingTag     NVARCHAR(10)= '',                    
 @CompanySeq     INT  = 1,              
 @LanguageSeq INT  = 1,              
 @UserSeq     INT  = 0,              
 @PgmSeq         INT  = 0           
      
AS          
   
 DECLARE @docHandle      INT,  
      @Seq            INT    
   
 EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
 SELECT  @Seq         = Seq            
   FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
   WITH (Seq          INT )  
   
 SELECT  Seq         ,   
         Serl        ,   
         Method      ,   
         ApplyFrDate ,   
         ApplyToDate ,  
         ISNULL(LastYn,0) AS LastYn  
      FROM _TPDTestReportItemDetail AS A WITH (NOLOCK)   
  WHERE  A.CompanySeq = @CompanySeq  
       AND  A.Seq        = @Seq           
  
    
  
RETURN  