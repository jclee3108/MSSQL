
IF OBJECT_ID('costel_SPDPDWHCustQuery') IS NOT NULL
    DROP PROC costel_SPDPDWHCustQuery 
GO

-- v2013.10.04 

-- 외주처별재고조회_costel(외주거래처조회) by이재천
CREATE PROCEDURE costel_SPDPDWHCustQuery 
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
    SELECT (CASE WHEN A.UserType = 1002 THEN ISNULL(B.CustSeq, 0) ELSE 0 END) AS WHCustSeq, 
           (CASE WHEN A.UserType = 1002 THEN ISNULL(B.CustName, '') ELSE '' END) AS WHCustName, 
           C.WHName, 
           C.WHSeq  
      FROM _TCAUser            AS A WITH(NOLOCK)    
      LEFT OUTER JOIN _TDACust AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN _TDAWH AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CommissionCustSeq = A.CustSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.UserSeq = @UserSeq 
    
    RETURN
GO
exec costel_SPDPDWHCustQuery @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1018368,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1015619