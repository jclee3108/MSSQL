  
IF OBJECT_ID('mnpt_SPJTWorkPlanIsCfm') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkPlanIsCfm  
GO  
    
-- v2017.09.14
  
-- 작업계획입력-승인 by 이재천
CREATE PROC mnpt_SPJTWorkPlanIsCfm
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    
    UPDATE A
       SET IsCfm = CASE WHEN B.IsCfm = '0' THEN '1' ELSE '0' END 
      FROM mnpt_TPJTWorkPlan    AS A 
      JOIN #BIZ_OUT_DataBlock1  AS B ON ( B.WorkDate = A.WorkDate ) 
     WHERE A.CompanySeq = @CompanySeq 

    UPDATE A
       SET IsCfm = CASE WHEN IsCfm = '0' THEN '1' ELSE '0' END 
      FROM #BIZ_OUT_DataBlock1 AS A 

    RETURN  
 
 go
