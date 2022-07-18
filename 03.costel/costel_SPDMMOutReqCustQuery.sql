
IF OBJECT_ID('costel_SPDMMOutReqCustQuery') IS NOT NULL
    DROP PROC costel_SPDMMOutReqCustQuery 
GO

-- v2013.09.24 

-- 외주자재출고요청입력_costel(외주거래처조회) by이재천
CREATE PROCEDURE costel_SPDMMOutReqCustQuery 
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
           (CASE WHEN A.UserType = 1002 THEN ISNULL(B.CustName, '') ELSE '' END) AS CustName, 
           C.WorkCenterName AS WorkCenter, 
           C.WorkCenterSeq 
      FROM _TCAUser            AS A WITH(NOLOCK)    
      LEFT OUTER JOIN _TDACust AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN _TPDBaseWorkCenter AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = B.CustSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.UserSeq = @UserSeq 
RETURN
GO
exec costel_SPDMMOutReqCustQuery @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1017998,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1015380
