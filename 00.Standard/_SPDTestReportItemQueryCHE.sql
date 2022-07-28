
IF OBJECT_ID('_SPDTestReportItemQueryCHE') IS NOT NULL 
    DROP PROC _SPDTestReportItemQueryCHE 
GO 

/************************************************************  
 ��  �� - ������-���輺�����м��׸�Method������ : ��ȸ  
 �ۼ��� - 20120718  
 �ۼ��� - ������  
************************************************************/  
CREATE PROC dbo._SPDTestReportItemQueryCHE                  
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
            @ItemSeq        INT ,  
            @ItemCode       INT  
   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT  @ItemSeq     = ISNULL(ItemSeq ,0)      ,  
            @ItemCode    = ISNULL(ItemCode,0)    
   FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
   WITH (ItemSeq      INT,  
            ItemCode     INT)  
    
    SELECT A.Seq          ,   
           A.ItemSeq      ,   
           B.ItemName  AS ItemName     ,   
           A.ItemCode     ,       
           C.MinorName AS ItemCodeName ,   
           A.Remark         
      FROM _TPDTestReportItem  AS A WITH (NOLOCK)   
           LEFT OUTER JOIN _TDAItem AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                      AND A.ItemSeq    = B.ItemSeq  
           LEFT OUTER JOIN _TDAUMinor AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq  
                                                        AND A.ItemCode   = C.MinorSeq  
     WHERE A.CompanySeq = @CompanySeq  
       AND (@ItemSeq  = 0 OR A.ItemSeq    = @ItemSeq  )     
       AND (@ItemCode = 0 OR A.ItemCode   = @ItemCode )  
    
    RETURN  