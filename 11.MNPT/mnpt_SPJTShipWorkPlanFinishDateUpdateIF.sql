     
IF OBJECT_ID('mnpt_SPJTShipWorkPlanFinishDateUpdateIF') IS NOT NULL       
    DROP PROC mnpt_SPJTShipWorkPlanFinishDateUpdateIF
GO      
      
-- v2017.12.06
      
-- 본선작업계획완료입력-운영정보시스템 전송 by 이재천  
CREATE PROC mnpt_SPJTShipWorkPlanFinishDateUpdateIF      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    
    IF DB_NAME() = 'MNPT'
    BEGIN 
        EXEC mnpt_SPJTShipDetailUpdate @CompanySeq
    END 

    RETURN     
