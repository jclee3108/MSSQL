  
IF OBJECT_ID('KPX_SSLMonthSalesPlanQuery') IS NOT NULL   
    DROP PROC KPX_SSLMonthSalesPlanQuery  
GO  
  
-- v2014.11.14  
  
-- 월간판매계획입력-조회 by 이재천   
CREATE PROC KPX_SSLMonthSalesPlanQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle       INT,  
            -- 조회조건   
            @BizUnit         INT,  
            @PlanYM          NCHAR(6), 
            @PlanRev         NCHAR(2), 
            @UMCustClass     INT, -- 유통구조 
            @CustSeq         INT, 
            @ItemSClass      INT, 
            @ItemName        NVARCHAR(100), 
            @ItemNo          NVARCHAR(100) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @BizUnit         = ISNULL( BizUnit, 0 ),
           @PlanYM          = ISNULL( PlanYM, '' ), 
           @PlanRev         = ISNULL( PlanRev, '' ), 
           @UMCustClass     = ISNULL( UMCustClass, 0 ), 
           @CustSeq         = ISNULL( CustSeq, 0 ), 
           @ItemSClass      = ISNULL( ItemSClass, 0 ), 
           @ItemName        = ISNULL( ItemName, '' ), 
           @ItemNo          = ISNULL( ItemNo, '' ) 
                               
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BizUnit         INT,  
            PlanYM          NCHAR(6), 
            PlanRev         NCHAR(2), 
            UMCustClass     INT, 
            CustSeq         INT, 
            ItemSClass      INT, 
            ItemName        NVARCHAR(100),
            ItemNo          NVARCHAR(100) 
           ) 
    
    IF @WorkingTag = 'Copy'
    BEGIN
        
        DECLARE @TableColumns NVARCHAR(4000)    
        
        SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TSLMonthSalesPlan')    
        
        SELECT DISTINCT 1 AS IDX_NO, 
               'D' AS WorkingTag, 
               0 AS Status, 
               A.BizUnit, 
               A.PlanYM, 
               A.PlanRev
          INTO #Rev_Log
          FROM KPX_TSLMonthSalesPlan AS A
         WHERE CompanySeq = @CompanySeq 
           AND BizUnit = @BizUnit 
           AND PlanYM = @PlanYM 
           AND PlanRev = @PlanRev
        
        
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'KPX_TSLMonthSalesPlan'    , -- 테이블명        
                      '#Rev_Log'    , -- 임시 테이블명        
                      'BizUnit,PlanYM,PlanRev'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명 

        DELETE A
          FROM KPX_TSLMonthSalesPlan AS A
         WHERE CompanySeq = @CompanySeq 
           AND BizUnit = @BizUnit 
           AND PlanYM = @PlanYM 
           AND PlanRev = @PlanRev
    
        SELECT @PlanRev = RIGHT('0' + CONVERT(NVARCHAR(2),CONVERT(INT,@PlanRev) - 1 ),2)
    END 
    
    -- 최종조회   
    SELECT A.EmpSeq, 
           B.EmpName, 
           L.UMCustClass AS UMCustClass, 
           C.MinorName AS UMCustClassName, 
           A.CustSeq, 
           D.CustName, 
           D.CustNo, 
           K.DVPlaceName, 
           A.DVPlaceSeq, 
           E.ItemClassSSeq AS ItemClassSeq, 
           E.ItemClasSName AS ItemClassName, 
           E.ItemClassMSeq AS ItemClassMSeq, 
           E.ItemClasMName AS ItemClassMName, 
           E.ItemClassLSeq AS ItemClassLSeq, 
           E.ItemClasLName AS ItemClassLName, 
           H.ItemName, 
           H.ItemNo, 
           A.ItemSeq, 
           H.Spec, 
           A.CurrSeq, 
           I.CurrName, 
           A.Price, 
           H.UnitSeq AS STDUnitSeq, 
           J.UnitName AS STDUnitName, 
           A.PlanQty, 
           A.PlanCurAmt AS PlanAmt, 
           A.PlanKorAmt AS PlanDomAmt, 
           A.CustSeq AS CustSeqOld, 
           A.ItemSeq AS ItemSeqOld, 
           H.UnitSeq AS STDUnitSeqOld, 
           A.Remark 
      FROM KPX_TSLMonthSalesPlan        AS A 
      LEFT OUTER JOIN _TDAEmp           AS B ON ( B.CompanySeq = A.CompanySeq AND A.EmpSeq = B.EmpSeq ) 
      LEFT OUTER JOIN _TDACustClass     AS L ON ( L.CompanySeq = A.CompanySeq AND L.CustSeq = A.CustSeq AND L.UMajorCustClass = 8004 ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = A.CompanySeq AND L.UMCustClass = C.MinorSeq ) 
      LEFT OUTER JOIN _TDACust          AS D ON ( D.CompanySeq = A.CompanySeq AND A.CustSeq = D.CustSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS E ON ( E.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItem          AS H ON ( H.CompanySeq = A.CompanySeq AND A.ItemSeq = H.ItemSeq )  
      LEFT OUTER JOIN _TDACurr          AS I ON ( I.CompanySeq = A.CompanySeq AND A.CurrSeq = I.CurrSeq ) 
      LEFT OUTER JOIN _TDAUnit          AS J ON ( J.CompanySeq = A.CompanySeq AND H.UnitSeq = J.UnitSeq ) 
      LEFT OUTER JOIN _TSLDeliveryCust  AS K ON ( K.CompanySeq = A.CompanySeq AND K.DVPlaceSeq = A.DVPlaceSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.BizUnit = @BizUnit )
       AND ( A.PlanRev = @PlanRev ) 
       AND ( A.PlanYM = @PlanYM ) 
       AND ( @UMCustClass = 0 OR L.UMCustClass = @UMCustClass ) 
       AND ( @CustSeq = 0 OR A.CustSeq = @CustSeq ) 
       AND ( @ItemSclass = 0 OR E.ItemClassSSeq = @ItemSclass ) 
       AND ( @ItemName = '' OR H.ItemName LIKE @ItemName + '%' ) 
       AND ( @ItemNo = '' OR H.ItemNo LIKE @ItemNo + '%' ) 
    RETURN  
GO 
begin tran 
exec KPX_SSLMonthSalesPlanQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>Copy</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <PlanRev>10</PlanRev>
    <BizUnit>2</BizUnit>
    <PlanYM>201411</PlanYM>
    <UMCustClass />
    <CustSeq />
    <ItemName />
    <ItemNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025841,@WorkingTag=N'Copy',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021320
rollback 