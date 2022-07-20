  
IF OBJECT_ID('mnpt_SACEEBgtAdjAmtUnit') IS NOT NULL   
    DROP PROC mnpt_SACEEBgtAdjAmtUnit  
GO  
    
-- v2017.12.18
  
-- 경비예산입력-금액단위 by 이재천   
CREATE PROC mnpt_SACEEBgtAdjAmtUnit      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    SELECT EnvValue AS AmtUnit
      FROM mnpt_TCOMEnv AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.EnvSeq = 36
     
    RETURN    
go