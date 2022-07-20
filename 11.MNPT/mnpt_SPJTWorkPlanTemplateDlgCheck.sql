  
IF OBJECT_ID('mnpt_SPJTWorkPlanTemplateDlgCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkPlanTemplateDlgCheck  
GO  
    
-- v2017.09.18
  
-- 작업계획템플릿-체크 by 이재천
CREATE PROC mnpt_SPJTWorkPlanTemplateDlgCheck      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
    
    
    -- 체크1, 이미 템플릿 추가 된 내역입니다.
    UPDATE A
       SET Result = '이미 템플릿 추가 된 내역입니다.', 
           MessageType = 1234, 
           Status = 1234 
      FROM #BIZ_OUT_DataBlock1  AS A 
      JOIN mnpt_TPJTWorkPlan    AS B ON ( B.CompanySeq = @CompanySeq AND B.WorkPlanSeq = A.WorkPlanSeq ) 
     WHERE A.Status = 0 
       AND @WorkingTag = 'U' 
       AND B.IsTemplate = '1' 
    -- 체크1, End 

    -- 체크2, 샘플이 선택되지 않았습니다.
    UPDATE A
       SET Result = '샘플이 선택되지 않았습니다.', 
           MessageType = 1234, 
           Status = 1234 
      FROM #BIZ_OUT_DataBlock1  AS A 
     WHERE A.Status = 0 
       AND @WorkingTag = 'U' 
       AND ISNULL(A.WorkPlanSeq,0) = 0 
    -- 체크2, End 

    RETURN  
  Go

  