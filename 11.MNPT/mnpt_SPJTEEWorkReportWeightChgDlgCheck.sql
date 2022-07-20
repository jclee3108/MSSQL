     
IF OBJECT_ID('mnpt_SPJTEEWorkReportWeightChgDlgCheck') IS NOT NULL       
    DROP PROC mnpt_SPJTEEWorkReportWeightChgDlgCheck      
GO      
      
-- v2018.02.12
      
-- 작업물량변경-체크 by 이재천 
CREATE PROC mnpt_SPJTEEWorkReportWeightChgDlgCheck  
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
        
    RETURN  
