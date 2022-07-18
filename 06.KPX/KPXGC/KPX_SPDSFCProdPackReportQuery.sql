  
IF OBJECT_ID('KPX_SPDSFCProdPackReportQuery') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackReportQuery  
GO  
  
-- v2014.11.27  
  
-- 포장작업실적입력-조회 by 이재천   
CREATE PROC KPX_SPDSFCProdPackReportQuery  
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
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @PackReportSeq  INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PackReportSeq   = ISNULL( PackReportSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (PackReportSeq   INT)    
    
    -- 최종조회 (마스터)  
    SELECT A.PackReportSeq, 
           A.FactUnit, 
           B.FactUnitName, 
           A.PackDate, 
           A.ReportNo, 
           A.UMProgType, 
           C.MinorName AS UMProgTypeName, 
           A.OutWHSeq, 
           D.WHName AS OutWHName, 
           A.InWHSeq, 
           E.WHName AS INWHName, 
           A.DrumOutWHSeq AS SubOutWHSeq, 
           F.WHName AS SubOutWHName
           
      FROM KPX_TPDSFCProdPackReport     AS A  
      LEFT OUTER JOIN _TDAFactUnit      AS B ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = A.FactUnit ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMProgType ) 
      LEFT OUTER JOIN _TDAWH            AS D ON ( D.CompanySeq = @CompanySeq AND D.WHSeq = A.OutWHSeq ) 
      LEFT OUTER JOIN _TDAWH            AS E ON ( E.CompanySeq = @CompanySeq AND E.WHSeq = A.InWHSeq ) 
      LEFT OUTER JOIN _TDAWH            AS F ON ( F.CompanySeq = @CompanySeq AND F.WHSeq = A.DrumOutWHSeq )  
     WHERE A.CompanySeq = @CompanySeq  
       AND A.PackReportSeq = @PackReportSeq 
    
    -- 최종조회 (SS1)
    SELECT A.PackReportSeq,
           A.PackReportSerl,
           A.ItemSeq,
           B.ItemName, 
           B.ItemNo, 
           B.Spec,
           A.UnitSeq, 
           C.UnitName, 
           A.Qty, 
           A.LotNo, 
           A.OutLotNo, 
           A.Remark,  
           A.SubItemSeq, 
           D.ItemName AS SubItemName, 
           D.ItemNo AS SubItemNo, 
           D.Spec AS SubSpec, 
           A.SubUnitSeq, 
           E.UnitName AS SubUnitName, 
           A.SubQty, 
           A.HambaQty AS Hamba, 
           A.PackOrderSeq, 
           A.PackOrderSerl
    
      FROM KPX_TPDSFCProdPackReportItem AS A 
      LEFT OUTER JOIN _TDAItem          AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit          AS C ON ( C.CompanySeq = @CompanySeq AND C.UnitSeq = A.UnitSeq ) 
      LEFT OUTER JOIN _TDAItem          AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.SubItemSeq ) 
      LEFT OUTER JOIN _TDAUnit          AS E ON ( E.CompanySeq = @CompanySeq AND E.UnitSeq = A.SubUnitSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.PackReportSeq = @PackReportSeq 
    
    RETURN  