
IF OBJECT_ID('_SPDTestReportItemDetailQueryCHE') IS NOT NULL 
    DROP PROC _SPDTestReportItemDetailQueryCHE 
GO 

/************************************************************  
 설  명 - 데이터-시험성적서분석항목Method리스트 : 조회  
 작성일 - 20120718  
 작성자 - 마스터  
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