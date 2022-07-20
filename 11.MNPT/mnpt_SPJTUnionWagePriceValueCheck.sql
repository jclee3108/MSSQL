  
IF OBJECT_ID('mnpt_SPJTUnionWagePriceValueCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTUnionWagePriceValueCheck  
GO  
    
-- v2017.09.19
  
-- 노조노임단가입력-Value체크 by 이재천
CREATE PROC mnpt_SPJTUnionWagePriceValueCheck      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    
    RETURN  
  
  
 