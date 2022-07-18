
IF OBJECT_ID('KPX_SLGInOutDailyItemSubQuery') IS NOT NULL 
    DROP PROC KPX_SLGInOutDailyItemSubQuery
GO 

-- v2014.12.05 

-- 사이트테이블로 변경 by이재천
    

/*************************************************************************************************        
      Ver.20131021
   설  명 - 일일입출고품목 조회    
  작성일 - 2008.10 : CREATED BY 정수환    
 *************************************************************************************************/        
 CREATE PROCEDURE KPX_SLGInOutDailyItemSubQuery      
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,    
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
 AS           
     DECLARE   @docHandle   INT,        
               @InOutSeq    INT,
               @InOutSerl   INT,
               @DataKind    INT, @InOutType INT
     
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
     
     SELECT  @InOutSeq  = ISNULL(InOutSeq,0),
             @InOutSerl = ISNULL(InOutSerl,0),
             @DataKind  = ISNULL(DataKind,0),
             @InOutType = ISNULL(InOutType,0)
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock3', @xmlFlags)         
     WITH (  InOutSeq   INT,
             InOutSerl  INT,
             DataKind   INT,
             InOutType  INT)
   
 --     SELECT  @InOutType = InOutType
 --       FROM  KPX_TPUMatOutEtcOut
 --      WHERE  CompanySeq = @CompanySeq
 --        AND  InOutSeq   = @InOutSeq
 --        AND  IsBatch <> '1'
  
  
     -- Get Main Table Datas
     CREATE TABLE #TEMPKPX_TPUMatOutEtcOutItemSub
     (
         CompanySeq          INT,
         InOutType           INT,
         InOutSeq            INT,
         InOutSerl           INT,
         DataKind            INT,
         InOutDataSerl       INT,
         ItemSeq             INT,
         InOutRemark         NVARCHAR(200),
         CCtrSeq             INT,
         DVPlaceSeq          INT,
         InWHSeq             INT,
         OutWHSeq            INT,
         UnitSeq             INT,
         Qty                 DECIMAL(19,5),
         STDQty              DECIMAL(19,5),
         Amt                 DECIMAL(19,5),
         EtcOutAmt           DECIMAL(19,5),
         EtcOutVAT           DECIMAL(19,5),
         InOutKind           INT,
         InOutDetailKind     INT,
         LotNo               NVARCHAR(30),
         SerialNo            NVARCHAR(30)
     )
      INSERT INTO #TEMPKPX_TPUMatOutEtcOutItemSub
     (
         CompanySeq,
         InOutType,
         InOutSeq,
         InOutSerl,
         DataKind,
         InOutDataSerl,
         ItemSeq,
         InOutRemark,
         CCtrSeq,
         DVPlaceSeq,
         InWHSeq,
         OutWHSeq,
         UnitSeq,
         Qty,
         STDQty,
         Amt,
         EtcOutAmt,
         EtcOutVAT,
         InOutKind,
         InOutDetailKind,
         LotNo,
         SerialNo
     )
     SELECT CompanySeq,
            InOutType,
            InOutSeq,
            InOutSerl,
            DataKind,
            InOutDataSerl,
            ItemSeq,
            InOutRemark,
            CCtrSeq,
            DVPlaceSeq,
            InWHSeq,
            OutWHSeq,
            UnitSeq,
            Qty,
            STDQty,
            Amt,
            EtcOutAmt,
            EtcOutVAT,
            InOutKind,
            InOutDetailKind,
            LotNo,
            SerialNo
       FROM KPX_TPUMatOutEtcOutItemSub WITH(NOLOCK)
      WHERE CompanySeq = @CompanySeq
        AND InOutType = @InOutType
        AND InOutSeq = @InOutSeq
  
  
     -- Result Query
     SELECT Mst.InOutType,
            Mst.InOutSeq,
            Mst.InOutSerl,
            Mst.DataKind,
            Mst.InOutDataSerl,
            Mst.ItemSeq,
            Mst.InOutRemark,
            Mst.CCtrSeq,
            Mst.DVPlaceSeq,
            Mst.InWHSeq,
            Mst.OutWHSeq,
            Mst.UnitSeq,
            Mst.Qty,
            Mst.STDQty,
            Mst.Amt,
            Mst.EtcOutAmt,
            Mst.EtcOutVAT,
            Mst.InOutKind,
            Mst.InOutDetailKind,
            Mst.LotNo,
            Mst.SerialNo,
             Item.ItemName,
            Item.ItemNo,
            Item.Spec,
            CCtr.CCtrName,
            DVPlc.DVPlaceName,
            InWH.WHName AS InWHName,
            OutWH.WHName AS OutWHName,
            Unit.UnitName,
            StdUnit.UnitName AS STDUnitName,
            IOKind.MinorName AS InOutKindName,
            IODtlKind.MinorName AS InOutDetailKindName
       FROM #TEMPKPX_TPUMatOutEtcOutItemSub AS Mst
            LEFT OUTER JOIN _TDAItem AS Item WITH(NOLOCK) ON Item.CompanySeq = Mst.CompanySeq AND Item.ItemSeq = Mst.ItemSeq
            LEFT OUTER JOIN _TDACCtr AS CCtr WITH(NOLOCK) ON CCtr.CompanySeq = Mst.CompanySeq AND CCtr.CCtrSeq = Mst.CCtrSeq
            LEFT OUTER JOIN _TSLDeliveryCust AS DVPlc WITH(NOLOCK) ON DVPlc.CompanySeq = Mst.CompanySeq AND DVPlc.DVPlaceSeq = Mst.DVPlaceSeq
            LEFT OUTER JOIN _TDAWH AS InWH WITH(NOLOCK) ON InWH.CompanySeq = Mst.CompanySeq AND InWH.WHSeq = Mst.InWHSeq
            LEFT OUTER JOIN _TDAWH AS OutWH WITH(NOLOCK) ON OutWH.CompanySeq = Mst.CompanySeq AND OutWH.WHSeq = Mst.OutWHSeq
            LEFT OUTER JOIN _TDAUnit AS Unit WITH(NOLOCK) ON Unit.CompanySeq = Mst.CompanySeq AND Unit.UnitSeq = Mst.UnitSeq
            LEFT OUTER JOIN _TDAUnit AS StdUnit WITH(NOLOCK) ON StdUnit.CompanySeq = Mst.CompanySeq AND StdUnit.UnitSeq = Item.UnitSeq
            LEFT OUTER JOIN _TDASMinor AS IOKind WITH(NOLOCK) ON IOKind.CompanySeq = Mst.CompanySeq AND IOKind.MinorSeq = Mst.InOutKind
            LEFT OUTER JOIN _TDAUMinor AS IODtlKind WITH(NOLOCK) ON IODtlKind.CompanySeq = Mst.CompanySeq AND IODtlKind.MinorSeq = Mst.InOutDetailKind
      WHERE (@InOutSerl = 0 OR Mst.InOutSerl = @InOutSerl)
        AND (@DataKind = 0 OR Mst.DataKind = @DataKind)
   ORDER BY Mst.InOutSerl
  
  
  /*
     SELECT  A.InOutSeq AS InOutSeq,
             A.InOutSerl AS InOutSerl,
             A.DataKind AS DataKind,
             A.InOutDataSerl AS InOutDataSerl,
             A.ItemSeq AS ItemSeq,
             B.ItemName AS ItemName,
             B.ItemNo AS ItemNo,
             B.Spec   AS Spec,
             A.InOutRemark AS InOutRemark,
             A.CCtrSeq AS CCtrSeq,
             IsNull((SELECT  CCtrName 
                       FROM _TDACCtr WITH(NOLOCK) 
                      WHERE  CompanySeq = A.CompanySeq 
                        AND  CCtrSeq    = A.CCtrSeq), '') AS CCtrName,
             A.DVPlaceSeq AS DVPlaceSeq,
             IsNull((SELECT  DVPlaceName 
                       FROM _TSLDeliveryCust WITH(NOLOCK) 
                      WHERE  CompanySeq = A.CompanySeq 
                        AND  DVPlaceSeq    = A.DVPlaceSeq), '') AS DVPlaceName,
             A.InWHSeq AS InWHSeq,
             IsNull((SELECT  WHName 
                       FROM _TDAWH WITH(NOLOCK) 
                      WHERE  CompanySeq = A.CompanySeq 
                        AND  WHSeq    = A.InWHSeq), '') AS InWHName,
             A.OutWHSeq AS OutWHSeq,
             IsNull((SELECT  WHName 
                       FROM _TDAWH WITH(NOLOCK) 
                      WHERE  CompanySeq = A.CompanySeq 
                        AND  WHSeq    = A.OutWHSeq), '') AS OutWHName,
             A.UnitSeq AS UnitSeq,
             IsNull((SELECT  UnitName 
                       FROM _TDAUnit WITH(NOLOCK) 
                      WHERE  CompanySeq = A.CompanySeq 
                        AND  UnitSeq    = A.UnitSeq), '') AS UnitName,
             A.Qty AS Qty,
             IsNull((SELECT  UnitName 
                       FROM _TDAUnit WITH(NOLOCK) 
                      WHERE  CompanySeq = B.CompanySeq 
                        AND  UnitSeq    = B.UnitSeq), '') AS STDUnitName,
             A.STDQty AS STDQty,
             A.Amt AS Amt,
             A.EtcOutAmt AS EtcOutAmt,
             A.EtcOutVAT AS EtcOutVAT,
             A.InOutKind AS InOutKind,
             IsNull((SELECT  MinorName 
                       FROM _TDASMinor WITH(NOLOCK) 
                      WHERE  CompanySeq = A.CompanySeq 
                        AND  MinorSeq    = A.InOutKind), '') AS InOutKindName,
             A.InOutDetailKind AS InOutDetailKind,
             IsNull((SELECT  MinorName 
                       FROM _TDAUMinor WITH(NOLOCK) 
                      WHERE  CompanySeq = A.CompanySeq 
                        AND  MinorSeq    = A.InOutDetailKind), '') AS InOutDetailKindName,
             A.LotNo AS LotNo,
             A.SerialNo AS SerialNo
      FROM KPX_TPUMatOutEtcOutItemSub AS A WITH (NOLOCK)  
            LEFT OUTER JOIN _TDAItem AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                       AND A.ItemSeq    = B.ItemSeq
     WHERE A.CompanySeq  = @CompanySeq  
       AND A.InOutType    = @InOutType
       AND A.InOutSeq    = @InOutSeq
       AND (@InOutSerl = 0 OR A.InOutSerl   = @InOutSerl)
       AND (@DataKind  = 0 OR A.DataKind    = @DataKind)
     ORDER BY A.InOutSerl
  */
  
  
 RETURN