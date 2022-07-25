
IF OBJECT_ID('amoerp_SLGInOutDailyItemQuery') IS NOT NULL 
    DROP PROC amoerp_SLGInOutDailyItemQuery
GO 

-- v2013.11.20 

-- ��Ź���ǰ����ȸ_amoerp by����õ    
 CREATE PROCEDURE amoerp_SLGInOutDailyItemQuery      
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,    
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
 AS 
    
     DECLARE @docHandle   INT,        
             @InOutSeq    INT, 
             @InOutType   INT
     
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
     
     SELECT  @InOutSeq  = ISNULL(InOutSeq,0),
             @InOutType = ISNULL(InOutType,0) 
             
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)         
     WITH (  InOutSeq   INT,
             InOutType  INT)          
    
     SELECT  A.InOutSeq AS InOutSeq,
             A.InOutSerl AS InOutSerl,
             A.InOutType AS InOutType,
             A.ItemSeq AS ItemSeq,
             B.ItemName AS ItemName,
             B.ItemNo AS ItemNo,
             B.Spec AS Spec,
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
             CONVERT(DECIMAL(19,5),Case A.Qty WHEN 0 THEN 0 ELSE A.Amt / A.Qty END) AS Price,
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
             A.SerialNo AS SerialNo,
             A.IsStockSales AS IsStockSales,
             A.OriUnitSeq AS OriUnitSeq,
             IsNull((SELECT  UnitName 
                       FROM _TDAUnit WITH(NOLOCK) 
                      WHERE  CompanySeq = A.CompanySeq 
    AND  UnitSeq    = A.OriUnitSeq), '') AS OriUnitName,
             A.OriItemSeq AS OriItemSeq,
             IsNull(C.ItemName, '') AS OriItemName,
             IsNull(C.ItemNo, '') AS OriItemNo,
             IsNull(C.Spec, '') AS OriSpec,
             A.OriQty AS OriQty,
             A.OriSTDQty AS OriSTDQty,
             A.OriLotNo AS OriLotNo,
             ISNULL((SELECT  UnitName
                       FROM _TDAUnit WITH (NOLOCK)
                      WHERE CompanySeq = @CompanySeq
                        AND UnitSeq    = B.UnitSeq), '') AS STDUnitName,
             ISNULL((SELECT  UnitName
                       FROM _TDAUnit WITH (NOLOCK)
                      WHERE CompanySeq = @CompanySeq
                        AND UnitSeq    = C.UnitSeq), '') AS OriSTDUnitName,
             ISNULL((SELECT IsQtyChange FROM _TDAItemStock WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ItemSeq), '') AS IsQtyChange,
             ISNULL(D.PJTName, '')            AS PJTName,            -- ������Ʈ��           -- 2012.06.24 ������ �߰�
             ISNULL(D.PJTNo, '')              AS PJTNo,              -- ������Ʈ��ȣ         -- 2012.06.24 ������ �߰�
             ISNULL(A.PJTSeq, 0)              AS PJTSeq,             -- ������Ʈ�ڵ�         -- 2012.06.24 ������ �߰�
             ISNULL(CASE ISNULL(E.CustItemName, '')    
                    WHEN '' THEN (SELECT CI.CustItemName FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = Z.CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)     
                            ELSE ISNULL(E.CustItemName, '') END, '')  AS CustItemName,     -- �ŷ�óǰ��    
             ISNULL(CASE ISNULL(E.CustItemNo, '')     
                    WHEN '' THEN (SELECT CI.CustItemNo   FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = Z.CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)     
                            ELSE ISNULL(E.CustItemNo, '') END, '')        AS CustItemNo,   -- �ŷ�óǰ��    
             ISNULL(CASE ISNULL(E.CustItemSpec, '')     
                    WHEN '' THEN (SELECT CI.CustItemSpec FROM _TSLCustItem AS CI WHERE CI.CompanySeq = @CompanySeq AND CI.CustSeq = Z.CustSeq AND A.ItemSeq = CI.ItemSeq AND CI.UnitSeq = 0)     
                            ELSE ISNULL(E.CustItemSpec, '') END, '')  AS CustItemSpec,      -- �ŷ�óǰ��԰�  
            A.ProgFromSeq AS FromSeq, 
            A.ProgFromSerl AS FromSerl, 
            A.ProgFromSubSerl AS FromSubSerl, 
            A.ProgFromTableSeq AS FromTableSeq
      INTO #TempResult
      FROM amoerp_TLGInOutDailyItemMerge AS A WITH (NOLOCK) 
      JOIN _TLGInOUtDaily AS Z WITH(NOLOCK) ON A.CompanySeq = Z.CompanySeq 
                                           AND A.InOutType  = Z.InOutType
                                           AND A.InOutSeq   = Z.InOutSeq
      LEFT OUTER JOIN _TDAItem AS B WITH (NOLOCK) ON A.CompanySeq = B.CompanySeq
                                                 AND A.ItemSeq    = B.ItemSeq
      LEFT OUTER JOIN _TDAItem AS C WITH (NOLOCK) ON A.CompanySeq = C.CompanySeq
                                                 AND A.OriItemSeq    = C.ItemSeq
      LEFT OUTER JOIN _TPJTProject AS D WITH(NOLOCK) ON A.PJTSeq     = D.PJTSeq            -- 2012.06.24 ������ �߰�
                                                    AND A.CompanySeq = D.CompanySeq
      LEFT OUTER JOIN _TSLCustItem  AS E WITH(NOLOCK) ON E.CompanySeq = @CompanySeq    
                                                     AND A.ItemSeq    = E.ItemSeq    
                                                     AND E.CustSeq    = Z.CustSeq    
                                                     AND A.UnitSeq    = E.UnitSeq       
     WHERE A.CompanySeq  = @CompanySeq  
       AND A.InOutSeq    = @InOutSeq 
       AND A.InOutType   = @InOutType
     ORDER BY A.InOutSerl
     
      UPDATE #TempResult
        SET InWHSeq        = (CASE WHEN ISNULL(B.InWHSeq,0) = 0 THEN A.InWHSeq ELSE ISNULL(B.InWHSeq,0) END),
            InWHName       = (CASE WHEN ISNULL(B.InWHSeq,0) = 0 THEN A.InWHName ELSE ISNULL((SELECT ISNULL(WHName,'') FROM _TDAWH WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND WHSeq = B.InWHSeq),'') END)
       FROM #TempResult AS A
            JOIN (SELECT X.InOutSeq, MAX(CASE WHEN ISNULL(Y.InWHSeq,0) = 0 THEN Z.InWHSeq ELSE Y.InWHSeq END) AS InWHSeq
                    FROM #TempResult AS  X
                         JOIN amoerp_TLGInOutDailyItemMerge AS Z WITH (NOLOCK) ON Z.CompanySeq = @CompanySeq
                                                                   AND X.InOutType  = Z.InOutType
                                                                   AND X.InOutSeq   = Z.InOutSeq
                         LEFT OUTER JOIN _TLGInOutDailyItemSub AS Y WITH (NOLOCK) ON Y.CompanySeq = @CompanySeq
                                                                                 AND Z.InOutType  = Y.InOutType
                                                                                 AND Z.InOutSeq   = Y.InOutSeq
                                                                                 AND Z.InOutSerl  = Y.InOutSerl
                                                                                 AND Y.InOutKind  IN (8023008, 8023012)
                    GROUP BY X.InOutSeq) AS B ON A.InOutSeq  = B.InOutSeq
   
     SELECT * FROM #TempResult
      
 RETURN
 GO
 exec amoerp_SLGInOutDailyItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <InOutSeq>1001285</InOutSeq>
    <InOutType>50</InOutType>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019447,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016426