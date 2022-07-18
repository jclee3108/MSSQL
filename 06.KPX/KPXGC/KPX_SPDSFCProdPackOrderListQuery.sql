  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderListQuery') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderListQuery  
GO  
  
-- v2014.11.26  
  
-- 포장작업지시조회-조회 by 이재천   
CREATE PROC KPX_SPDSFCProdPackOrderListQuery  
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
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @FactUnit       INT,  
            @PackDateFr     NCHAR(8), 
            @PackDateTo     NCHAR(8), 
            @OrderNo        NVARCHAR(100), 
            @UMProgType     INT, 
            @ItemSeq        INT, 
            @ProgSeq        INT

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit   = ISNULL(FactUnit  ,0),
           @PackDateFr = ISNULL(PackDateFr,''),
           @PackDateTo = ISNULL(PackDateTo,''),
           @OrderNo    = ISNULL(OrderNo   ,''),
           @UMProgType = ISNULL(UMProgType,0),
           @ItemSeq    = ISNULL(ItemSeq   ,0),
           @ProgSeq    = ISNULL(ProgSeq   ,0)
    
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit       INT,  
            PackDateFr     NCHAR(8), 
            PackDateTo     NCHAR(8), 
            OrderNo        NVARCHAR(100),
            UMProgType     INT, 
            ItemSeq        INT, 
            ProgSeq        INT
           )    
    
    IF @PackDateTo = '' SELECT @PackDateTo = '99991231'
    
    -- 최종조회   
    SELECT B.IsStop, 
           C.CfmCode AS IsCfm, 
           A.FactUnit, 
           D.FactUnitName, 
           A.PackDate, 
           A.OrderNo, 
           E.WHName AS OutWHName, 
           A.OutWHSeq AS OutWHSeq, 
           F.WHName AS InWHName, 
           A.InWHSeq, 
           G.MinorName AS UMProgTypeName, 
           A.UMProgType, -- 원천구분
           H.ItemName, 
           H.ItemNo, 
           H.Spec, 
           B.ItemSeq, 
           I.UnitName, 
           B.UnitSeq, 
           B.OrderQty, 
           B.LotNo, 
           J.MinorName AS UMDMMarkingName, 
           B.UMDMMarking, 
           B.OutLotNo, 
           B.PackOnDate, 
           B.PackReOnDate, 
           B.Remark, 
           K.ItemName AS SubItemName, 
           K.ItemNo AS SubItemNo, 
           K.Spec AS SubSpec, 
           B.SubItemSeq, 
           L.UnitName AS SubUnitName, 
           B.SubUnitSeq, 
           B.SubQty, 
           B.NonMarking, 
           B.PopInfo, 
           A.PackOrderSeq, 
           B.PackOrderSerl
      FROM KPX_TPDSFCProdPackOrder                      AS A 
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrderItem       AS B ON ( B.CompanySeq = @CompanySeq AND B.PackOrderSeq = A.PackOrderSeq ) 
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrder_Confirm   AS C ON ( C.CompanySeq = @CompanySeq AND C.CfmSeq = A.PackOrderSeq ) 
      LEFT OUTER JOIN _TDAFactUnit                      AS D ON ( D.CompanySeq = @CompanySeq AND D.FactUnit = A.FactUnit ) 
      LEFT OUTER JOIN _TDAWH                            AS E ON ( E.CompanySeq = @CompanySeq AND E.WHSeq = A.OutWHSeq ) 
      LEFT OUTER JOIN _TDAWH                            AS F ON ( F.CompanySeq = @CompanySeq AND F.WHSeq = A.InWHSeq ) 
      LEFT OUTER JOIN _TDAUMinor                        AS G ON ( G.CompanySeq = @CompanySEq AND G.MinorSeq = A.UMProgType ) 
      LEFT OUTER JOIN _TDAItem                          AS H ON ( H.CompanySeq = @CompanySeq AND H.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit                          AS I ON ( I.CompanySeq = @CompanySeq AND I.UnitSeq = B.UnitSeq ) 
      LEFT OUTER JOIN _TDAUMinor                        AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = B.UMDMMarking ) 
      LEFT OUTER JOIN _TDAItem                          AS K ON ( K.CompanySeq = @CompanySeq AND K.ItemSeq = B.SubItemSeq ) 
      LEFT OUTER JOIN _TDAUnit                          AS L ON ( L.CompanySeq = @CompanySeq AND L.UnitSeq = B.SubUnitSeq ) 
      
     WHERE A.CompanySeq = @CompanySeq 
       AND (@FactUnit = 0 OR A.FactUnit = @FactUnit) 
       AND (A.PackDate BETWEEN @PackDateFr AND @PackDateTo) 
       AND (@OrderNo = '' OR A.OrderNo LIKE @OrderNo + '%') 
       AND (@UMProgType = 0 OR A.UMProgType = @UMProgType) 
       AND (@ItemSeq = 0 OR B.ItemSeq = @ItemSeq) 
    
    RETURN  
    
    
