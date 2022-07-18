  
IF OBJECT_ID('KPX_SACEvalProfitItemMasterINIT') IS NOT NULL   
    DROP PROC KPX_SACEvalProfitItemMasterINIT  
GO  
  
-- v2014.12.30 
  
-- 평가손익상품마스터-INIT by 이재천   
CREATE PROC KPX_SACEvalProfitItemMasterINIT  
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
    

    DECLARE @EnvValue INT 
    SELECT @EnvValue = (SELECT EnvValue FROM KPX_TCOMenvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 15 AND EnvSerl = 1)
    
    
    CREATE TABLE #Date 
    (
        StdDate     NCHAR(8), 
        dw          INT 
    )
    INSERT INTO #Date ( StdDate, Dw ) 
    SELECT CONVERT(NCHAR(8), GETDATE(),112), DATEPART(DW, GETDATE())
    UNION ALL 
    SELECT CONVERT(NCHAR(8), DATEADD(DAY, 1, GETDATE()),112), DATEPART(DW, DATEADD(DAY, 1, GETDATE()))
    UNION ALL 
    SELECT CONVERT(NCHAR(8), DATEADD(DAY, 2, GETDATE()),112), DATEPART(DW, DATEADD(DAY, 2, GETDATE()))
    UNION ALL 
    SELECT CONVERT(NCHAR(8), DATEADD(DAY, 3, GETDATE()),112), DATEPART(DW, DATEADD(DAY, 3, GETDATE()))
    UNION ALL 
    SELECT CONVERT(NCHAR(8), DATEADD(DAY, 4, GETDATE()),112), DATEPART(DW, DATEADD(DAY, 4, GETDATE()))
    UNION ALL 
    SELECT CONVERT(NCHAR(8), DATEADD(DAY, 5, GETDATE()),112), DATEPART(DW, DATEADD(DAY, 5, GETDATE()))
    UNION ALL 
    SELECT CONVERT(NCHAR(8), DATEADD(DAY, 6, GETDATE()),112), DATEPART(DW, DATEADD(DAY, 6, GETDATE()))

    SELECT StdDate 
      FROM #Date 
     WHERE dw = CASE WHEN (SELECT MinorValue FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = @EnvValue) = 1 THEN 2 
                     WHEN (SELECT MinorValue FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = @EnvValue) = 2 THEN 3 
                     WHEN (SELECT MinorValue FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = @EnvValue) = 3 THEN 4 
                     WHEN (SELECT MinorValue FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = @EnvValue) = 4 THEN 5 
                     WHEN (SELECT MinorValue FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = @EnvValue) = 5 THEN 6 
                     WHEN (SELECT MinorValue FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = @EnvValue) = 6 THEN 7 
                     WHEN (SELECT MinorValue FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = @EnvValue) = 7 THEN 1 
                     END 
    
    RETURN  
GO 
exec KPX_SACEvalProfitItemMasterINIT @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1026966,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020380