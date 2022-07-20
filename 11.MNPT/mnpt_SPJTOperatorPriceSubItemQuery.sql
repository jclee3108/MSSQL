     
IF OBJECT_ID('mnpt_SPJTOperatorPriceSubItemQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTOperatorPriceSubItemQuery      
GO      
      
-- v2017.09.19
      
-- 운전원노임단가입력-SS3조회 by 이재천  
CREATE PROC mnpt_SPJTOperatorPriceSubItemQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @StdSeq  INT, 
            @StdSerl INT  
      
    SELECT @StdSeq   = ISNULL( StdSeq, 0 ), 
           @StdSerl  = ISNULL( StdSerl, 0 )
      FROM #BIZ_IN_DataBlock2    
    
    
    -- 최종조회
    SELECT A.StdSeq            , 
           A.StdSerl           , 
           A.StdSubSerl        , 
           A.PJTTypeSeq        , -- 화태코드 
           B.PJTTypeName       , -- 화태 
           A.UnDayPrice        , -- 노조일대 
           A.UnHalfPrice       , -- 노조반일
           A.UnMonthPrice      , -- 노조월대
           A.DailyDayPrice     , -- 일용일대 
           A.DailyHalfPrice    , -- 일용반일
           A.DailyMonthPrice   , -- 일용월대 
           A.OSDayPrice        , -- OS일대 
           A.OSHalfPrice       , -- OS반일 
           A.OSMonthPrice      , -- OS월대 
           A.EtcDayPrice       , -- 기타일대 
           A.EtcHalfPrice      , -- 기타반일 
           A.EtcMonthPrice       -- 기타월대 

      FROM mnpt_TPJTOperatorPriceSubItem    AS A  
      LEFT OUTER JOIN _TPJTType             AS B ON ( B.CompanySeq = @CompanySeq AND B.PJTTypeSeq = A.PJTTypeSeq ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND A.StdSeq = @StdSeq 
       AND A.StdSerl = @StdSerl 
    
    RETURN     
    