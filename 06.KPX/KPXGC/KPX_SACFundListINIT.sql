  
IF OBJECT_ID('KPX_SACFundListINIT') IS NOT NULL   
    DROP PROC KPX_SACFundListINIT  
GO  
  
-- v2014.12.29  
  
-- 상품운용현황-INIT by 이재천   
CREATE PROC KPX_SACFundListINIT  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    
    SELECT TOP 1 
           A.MinorSeq AS UMHelpCom, 
           A.MinorName AS UMHelpComName, 
           CASE WHEN @CompanySeq IN ( 1,2,3 ) THEN '1' 
                ELSE '0' 
                END AS DISKind 
      FROM _TDAUMinor AS A 
      JOIN _TDAUMinorValue AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 AND B.ValueText = CONVERT(NVARCHAR(10),@CompanySeq) ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1010494
       AND A.IsUse = '1' 
    
    
    RETURN 
GO 

exec KPX_SACFundListINIT @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1027152,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021337