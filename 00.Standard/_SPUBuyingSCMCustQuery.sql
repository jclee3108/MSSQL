
IF OBJECT_ID('_SPUBuyingSCMCustQuery') IS NOT NULL
    DROP PROC _SPUBuyingSCMCustQuery 
GO

-- v2013.10.22 

-- 구매SCM정산조회(협력사)_(거래처조회) by이재천
CREATE PROCEDURE _SPUBuyingSCMCustQuery 
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS      
    
    SET NOCOUNT ON          
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED          
       
    DECLARE @docHandle        INT  
    SELECT (CASE WHEN A.UserType = 1002 THEN ISNULL(B.CustSeq, 0) ELSE 0 END) AS CustSeq, 
           (CASE WHEN A.UserType = 1002 THEN ISNULL(B.CustName, '') ELSE '' END) AS CustName 
      FROM _TCAUser            AS A WITH(NOLOCK)    
      LEFT OUTER JOIN _TDACust AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.CustSeq = B.CustSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.UserSeq = @UserSeq 
    
    RETURN
