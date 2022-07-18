  
IF OBJECT_ID('KPX_SEQChangeFinalExReport_INIT') IS NOT NULL   
    DROP PROC KPX_SEQChangeFinalExReport_INIT  
GO  
  
-- v2014.02.05  
  
-- 변경조치결과등록 - 초기셋팅 by 이재천
CREATE PROC KPX_SEQChangeFinalExReport_INIT  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    IF EXISTS (SELECT 1
                 FROM _TCAUser 
                WHERE CompanySeq = @CompanySeq 
                  AND UserSeq = @Userseq 
                  AND EmpSeq IN ( SELECT EmpSeq FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 28 )
               ) 
    BEGIN 
    
        SELECT '1' IsCfm 
    
    END 
    ELSE
    BEGIN
        
        SELECT '0' IsCfm
        
    END 
    
    RETURN  
GO
