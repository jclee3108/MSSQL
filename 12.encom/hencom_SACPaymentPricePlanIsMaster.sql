 
IF OBJECT_ID('hencom_SACPaymentPricePlanIsMaster') IS NOT NULL   
    DROP PROC hencom_SACPaymentPricePlanIsMaster  
GO  

-- v2017.07.06
  
-- 정기분대금지급계획-조회 by 이재천
CREATE PROC hencom_SACPaymentPricePlanIsMaster  
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

    -- 로그인 사용자부서 
    SELECT B.DeptSeq 
      INTO #UserDept
      FROM _TCAUser AS A 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS B ON ( B.EmpSeq = A.EmpSeq )
     WHERE CompanySeq = @CompanySeq 
       AND UserSeq = @UserSeq
    
    -- 마스터권한부서
    SELECT A.ValueSeq AS DeptSeq 
      INTO #MasterDept
      FROM _TDAUMinorValue  AS A 
      JOIN _TDAUMinor       AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq )
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1015395
       AND A.Serl = 1000001 
       AND B.IsUse = '1'

    IF EXISTS (SELECT 1 FROM #UserDept WHERE DeptSeq IN ( SELECT DeptSeq FROM #MasterDept )) 
    BEGIN
        SELECT '1' AS IsMaster
    END 
    ELSE 
    BEGIN 
        SELECT '0' AS IsMaster
    END 
      
    RETURN  
    GO
exec hencom_SACPaymentPricePlanIsMaster @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1512352,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033717