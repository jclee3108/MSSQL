
IF OBJECT_ID('jongie_SPDOSPPriceCustQuery') IS NOT NULL
    DROP PROC jongie_SPDOSPPriceCustQuery 

GO

-- v2013.09.24 

-- 대표외주거래처단가일괄적용_jongie(대표외주처조회) by이재천
CREATE PROC jongie_SPDOSPPriceCustQuery                
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
	
	SELECT RTRIM(CustName) AS CustName  
      FROM _TDACust 
	 WHERE CompanySeq = @CompanySeq 
	   AND CustSeq = (SELECT EnvValue FROM jongie_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8 AND EnvSerl = 1)
           
    RETURN
GO
exec jongie_SPDOSPPriceCustQuery @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1017952,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1088