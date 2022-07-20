     
IF OBJECT_ID('mnpt_SPJTUnionWagePriceQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTUnionWagePriceQuery      
GO      
      
-- v2017.09.28
      
-- 노조노임단가입력-SS1조회 by 이재천
CREATE PROC mnpt_SPJTUnionWagePriceQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @FrStdDate  NCHAR(8), 
            @ToStdDate  NCHAR(8) 
      
    SELECT @FrStdDate   = ISNULL( FrStdDate, '' ),   
           @ToStdDate   = ISNULL( ToStdDate, '' )   
      FROM #BIZ_IN_DataBlock1    
    
    IF @ToStdDate = '' SELECT @ToStdDate = '99991231'
    
    -- 최종조회
    SELECT A.StdSeq, A.StdDate, A.Remark
      FROM mnpt_TPJTUnionWagePrice AS A   
     WHERE A.CompanySeq = @CompanySeq   
       AND A.StdDate BETWEEN @FrStdDate AND @ToStdDate 
     ORDER BY A.StdDate DESC 
    
    RETURN     