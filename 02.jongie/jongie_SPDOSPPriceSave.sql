  
IF OBJECT_ID('jongie_SPDOSPPriceSave') IS NOT NULL   
    DROP PROC jongie_SPDOSPPriceSave  
GO  
  
-- v2013.09.24 
  
-- 대표외주거래처단가일괄적용_jongie by이재천   
CREATE PROC jongie_SPDOSPPriceSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    DECLARE @Status   INT, 
            @Result   NVARCHAR(200), 
            @EnvSeq8  INT, 
            @EnvSeq9  INT, 
            @EnvName8 NVARCHAR(100)
    
    SELECT @Status = 0  
    SELECT @Result = '' 
    SELECT @EnvSeq8 = EnvValue FROM jongie_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8 AND EnvSerl = 1 -- 대표외주거래처
    SELECT @EnvSeq9 = EnvValue FROM jongie_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 9 AND EnvSerl = 1 -- 거래처종류
    SELECT @EnvName8 = CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = @EnvSeq8 -- 대표외주거래처명

    -- 체크2, 대표외주거래처(OOO)의 단가가 등록되어 있지 않습니다.
    IF NOT EXISTS (SELECT 1 FROM _TPDOSPPriceItem WHERE CompanySeq = @CompanySeq AND CustSeq = @EnvSeq8)
    BEGIN 
        SELECT @Status = 2
        SELECT @Result = N'대표외주거래처('+RTRIM(@EnvName8)+')의 단가가 등록되어 있지 않습니다.'
    END
    -- 체크2, END
    
    -- 체크3, 추가개발Mapping정보의 대표외주거래처가 외주계약등록 외주처에 존재하지 않습니다.
    IF NOT EXISTS (SELECT 1 FROM _TPDOSPPrice WHERE CompanySeq = @CompanySeq AND CustSeq = @EnvSeq8)
    BEGIN 
        SELECT @Status = 3
        SELECT @Result = N'추가개발Mapping정보의 대표외주거래처가 외주계약등록 외주처에 존재하지 않습니다.'
    END
    -- 체크3, END
    
    -- 체크1, 추가개발Mapping정보에 대표외주거래처를 설정하세요.
    IF (SELECT EnvValue FROM jongie_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8 AND EnvSerl = 1) = 0 
    OR (SELECT EnvValue FROM jongie_TCOMEnv WHERE CompanySeq = @CompanySeq AND EnvSeq = 8 AND EnvSerl = 1) = '' 
    BEGIN 
        SELECT @Status = 1
        SELECT @Result = N'추가개발Mapping정보에 대표외주거래처를 설정하세요.'
    END
    -- 체크1, END 

    -- 조건에 만족하는 외주처 담기
    SELECT A.CustSeq, @Status AS Status, @Result AS Result
      INTO #TPDOSPPrice
      FROM _TPDOSPPrice AS A
      JOIN _TDACustKind AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq AND B.UMCustKind = @EnvSeq9 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (SELECT COUNT(1) FROM _TDACustKind WHERE CompanySeq = @CompanySeq AND A.CustSeq = CustSeq GROUP BY CustSeq) = 1 
       AND A.CustSeq <> @EnvSeq8 
       
    -- 대표외주거래처 단가 데이터 담기
    SELECT CompanySeq , FactUnit , CustSeq      , ItemSeq  , Serl      , 
           ItemBomRev , ProcRev  , AssySeq      , CurrSeq  , OSPType   , 
           PriceType  , Price    , ProcPrice    , MatPrice , StartDate ,
           EndDate    , ProcSeq  , PriceUnitSeq , Remark   , IsStop    ,
           StopRemark , StopDate , StopEmpSeq 
      INTO #TPDOSPPriceItem
      FROM _TPDOSPPriceItem 
     WHERE CompanySeq = @CompanySeq AND CustSeq = @EnvSeq8 
    
    -- 조건에 만족하는 외주처의 단가 데이터 지우기
    DELETE B
      FROM #TPDOSPPrice     AS A 
      JOIN _TPDOSPPriceItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq ) 
     WHERE A.Status = 0 
    
    -- 대표외주거래처 데이터를 조건에 만족하는 외주거래처에 같은 값 넣어주기(단가정보)
    INSERT INTO _TPDOSPPriceItem(
                                 CompanySeq   , FactUnit , CustSeq      , ItemSeq  , Serl        , 
                                 ItemBomRev   , ProcRev  , AssySeq      , CurrSeq  , OSPType     , 
                                 PriceType    , Price    , ProcPrice    , MatPrice , StartDate   , 
                                 EndDate      , ProcSeq  , PriceUnitSeq , Remark   , LastUserSeq , 
                                 LastDateTime , IsStop   , StopRemark   , StopDate , StopEmpSeq
                                )
    SELECT @CompanySeq  , B.FactUnit , A.CustSeq      , B.itemSeq  , B.Serl       , 
           B.ItemBomRev , B.ProcRev  , B.AssySeq      , B.CurrSeq  , B.OSPType    , 
           B.PriceType  , B.Price    , B.ProcPrice    , B.MatPrice , B.StartDate  , 
           B.EndDate    , B.ProcSeq  , B.PriceUnitSeq , B.Remark   , @UserSeq     , 
           GETDATE()    , B.IsStop   , B.StopRemark   , B.StopDate , B.StopEmpSeq
      FROM #TPDOSPPrice AS A 
      JOIN #TPDOSPPriceItem AS B WITH(NOLOCK) ON ( 1 = 1 )
     WHERE A.Status = 0 
     ORDER BY A.CustSeq

    -- 대표외주거래처 소요자재정보 담기
    SELECT CompanySeq  , FactUnit  , CustSeq          , GoodItemSeq        , Serl         , 
           SubSerl     , ItemSeq   , UnitSeq          , Qty                , StdUnitSeq   , 
           StdUnitQty  , Remark    , NeedQtyNumerator , NeedQtyDenominator , SMDelvType   , 
           OutLossRate , QtyPerOne , IsDirect         , LastUserSeq        , LastDateTime , 
           IsSale      , Price 
      INTO #TPDOSPPriceSubItem
      FROM _TPDOSPPriceSubItem 
     WHERE CompanySeq = @CompanySeq AND CustSeq = @EnvSeq8 
    
    -- 조건에 만족하는 외주처의 소요자재정보 지우기
    DELETE B
      FROM #TPDOSPPrice        AS A 
      JOIN _TPDOSPPriceSubItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq ) 
     WHERE A.Status = 0 
    
    -- 대표외주거래처 데이터를 조건에 만족하는 외주거래처에 같은 값 넣어주기(소요자재정보)
    INSERT INTO _TPDOSPPriceSubItem(
                                    CompanySeq  , FactUnit  , CustSeq          , GoodItemSeq        , Serl         , 
                                    SubSerl     , ItemSeq   , UnitSeq          , Qty                , StdUnitSeq   , 
                                    StdUnitQty  , Remark    , NeedQtyNumerator , NeedQtyDenominator , SMDelvType   , 
                                    OutLossRate , QtyPerOne , IsDirect         , LastUserSeq        , LastDateTime ,
                                    IsSale      , Price                                
                                   )
    SELECT @CompanySeq   , B.FactUnit  , A.CustSeq          , B.GoodItemSeq        , B.Serl       , 
           B.SubSerl     , B.ItemSeq   , B.UnitSeq          , B.Qty                , B.StdUnitSeq , 
           B.StdUnitQty  , B.Remark    , B.NeedQtyNumerator , B.NeedQtyDenominator , B.SMDelvType , 
           B.OutLossRate , B.QtyPerOne , B.IsDirect         , @UserSeq             , GETDATE()    ,
           B.IsSale      , B.Price  
      FROM #TPDOSPPrice        AS A 
      JOIN #TPDOSPPriceSubItem AS B WITH(NOLOCK) ON ( 1 = 1 )
     WHERE A.Status = 0 
     ORDER BY A.CustSeq
    
    SELECT @Status AS Status, @Result AS Result

    RETURN  

GO

BEGIN TRAN
exec jongie_SPDOSPPriceSave @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1017952,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1088
ROLLBACK TRAN 
