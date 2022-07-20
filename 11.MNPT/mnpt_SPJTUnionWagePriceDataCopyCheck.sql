  
IF OBJECT_ID('mnpt_SPJTUnionWagePriceDataCopyCheck') IS NOT NULL   
    DROP PROC mnpt_SPJTUnionWagePriceDataCopyCheck  
GO  
    
-- v2017.09.28
  
-- 노조노임단가입력-최근자료복사체크 by 이재천
CREATE PROC mnpt_SPJTUnionWagePriceDataCopyCheck
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS       
    
    -- 체크1, 최근자료가 존재하지 않습니다.
    DECLARE @MaxStdDate NCHAR(8) 

    SELECT @MaxStdDate = MAX(B.StdDate) 
      FROM #BIZ_OUT_DataBlock1          AS A 
      JOIN mnpt_TPJTUnionWagePrice      AS B ON ( B.CompanySeq = @CompanySeq AND B.StdDate < A.StdDate ) 
     WHERE A.Status = 0 
    
    IF @MaxStdDate IS NULL OR @MaxStdDate = '' 
    BEGIN 
        UPDATE A
           SET Result = '최근자료가 존재하지 않습니다.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #BIZ_OUT_DataBlock1 AS A 
    END 
    -- 체크1, END 
    
    RETURN  
 

 GO 

