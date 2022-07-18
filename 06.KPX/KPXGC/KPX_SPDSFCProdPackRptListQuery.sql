  
IF OBJECT_ID('KPX_SPDSFCProdPackRptListQuery') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackRptListQuery  
GO  
  
-- v2014.11.26  
  
-- 포장작업실적조회-조회 by 이재천   
CREATE PROC KPX_SPDSFCProdPackRptListQuery  
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
            @LotNo          NVARCHAR(100), 
            @UMProgType     INT, 
            @OutWHSeq       INT, 
            @InWHSeq        INT, 
            @ItemName       NVARCHAR(100), 
            @ItemNo         NVARCHAR(100) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @FactUnit   = ISNULL( FactUnit  ,0), 
           @PackDateFr = ISNULL( PackDateFr,''), 
           @PackDateTo = ISNULL( PackDateTo,''), 
           @LotNo      = ISNULL( LotNo     ,''), 
           @UMProgType = ISNULL( UMProgType,0), 
           @OutWHSeq   = ISNULL( OutWHSeq  ,0), 
           @InWHSeq    = ISNULL( InWHSeq   ,0), 
           @ItemName   = ISNULL( ItemName  ,''), 
           @ItemNo     = ISNULL( ItemNo    ,'')
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            FactUnit       INT, 
            PackDateFr     NCHAR(8), 
            PackDateTo     NCHAR(8), 
            LotNo          NVARCHAR(100),
            UMProgType     INT, 
            OutWHSeq       INT, 
            InWHSeq        INT, 
            ItemName       NVARCHAR(100),
            ItemNo         NVARCHAR(100) 
           )
    
    -- 최종조회   
    SELECT A.FactUnit, 
           C.FactUnitName, 
           A.PackDate, 
           A.ReportNo, 
           D.WHName AS OutWHName, 
           A.OutWHSeq, 
           E.WHName AS InWHName, 
           A.InWHSeq, 
           H.WHName AS SubOutWHName, 
           A.DrumOutWHSeq AS SubOutWHSeq , 
           A.UMProgType, -- 원천구분
           I.MinorName AS UMProgTypeName, 
           J.ItemName, 
           J.ItemNo, 
           J.Spec, 
           B.UnitSeq, 
           K.UnitName, 
           B.Qty, 
           B.LotNo, 
           F.UMDMMarking, 
           L.MinorName AS UMDMMarkingName, 
           B.OutLotNo, 
           F.PackOnDate, 
           F.PackReOnDate, 
           B.Remark, 
           B.HambaQty AS Hamba,
           B.SubItemSeq, 
           M.ItemName AS SubItemName, 
           M.ItemNo AS SubItemNo, 
           M.Spec AS SubSpec, 
           B.SubUnitSeq, 
           N.UnitName AS SubUnitName, 
           B.SubQty, 
           F.NonMarking, 
           A.PackReportSeq, 
           B.PackReportSerl, 
           F.PackOrderSeq, 
           F.PackOrderSerl
    
      FROM KPX_TPDSFCProdPackReport AS A  
      LEFT OUTER JOIN KPX_TPDSFCProdPackReportItem  AS B ON ( B.CompanySeq = @CompanySeq AND B.PackReportSeq = A.PackReportSeq ) 
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrderItem   AS F ON ( F.CompanySeq = @CompanySeq AND F.PackOrderSeq = B.PackOrderSeq AND F.PackOrderSerl = B.PackOrderSerl ) 
      LEFT OUTER JOIN _TDAFactUnit              AS C ON ( C.CompanySeq = @CompanySeq AND C.FactUnit = A.FactUnit ) 
      LEFT OUTER JOIN _TDAWH                    AS D ON ( D.CompanySeq = @CompanySeq AND D.WHSeq = A.OutWHSeq ) 
      LEFT OUTER JOIN _TDAWH                    AS E ON ( E.CompanySeq = @CompanySeq AND E.WHSeq = A.InWHSeq ) 
      LEFT OUTER JOIN _TDAWH                    AS H ON ( H.CompanySeq = @CompanySeq AND H.WHSeq = A.DrumOutWHSeq ) 
      LEFT OUTER JOIN _TDAUMinor                AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = A.UMProgType ) 
      LEFT OUTER JOIN _TDAItem                  AS J ON ( J.CompanySeq = @CompanySeq AND J.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit                  AS K ON ( K.CompanySeq = @CompanySeq AND K.UnitSeq = B.UnitSeq ) 
      LEFT OUTER JOIN _TDAUminor                AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = F.UMDMMarking )
      LEFT OUTER JOIN _TDAItem                  AS M ON ( M.CompanySeq = @CompanySeq AND M.ItemSeq = B.SubItemSeq ) 
      LEFT OUTER JOIN _TDAUnit                  AS N ON ( N.CompanySeq = @CompanySeq AND N.UnitSeq = B.SubUnitSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.PackDate BETWEEN @PackDateFr AND @PackDateTo 
       AND (@FactUnit = 0 OR A.FactUnit = @FactUnit)
       AND (@LotNo = '' OR B.LotNo LIKE @LotNo + '%')
       AND (@UMProgType = 0 OR A.UMProgType = @UMProgType) 
       AND (@OutWHSeq = 0 OR A.OutWHSeq = @OutWHSeq) 
       AND (@InWHSeq = 0 OR A.InWHSeq = @InWHSeq) 
       AND (@ItemName = '' OR J.ItemName LIKE @ItemName + '%')
       AND (@ItemNo = '' OR J.ItemNo LIKE @ItemNo + '%') 
    
    RETURN  
GO 
exec KPX_SPDSFCProdPackRptListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <PackDateTo>20141128</PackDateTo>
    <ItemName />
    <ItemNo />
    <FactUnit />
    <PackDateFr>20141101</PackDateFr>
    <LotNo />
    <UMProgType />
    <OutWHSeq />
    <InWHSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026222,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021352