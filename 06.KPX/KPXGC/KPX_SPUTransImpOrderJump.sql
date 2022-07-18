  
IF OBJECT_ID('KPX_SPUTransImpOrderJump') IS NOT NULL   
    DROP PROC KPX_SPUTransImpOrderJump  
GO  
  
-- v2014.11.28  
  
-- 수입운송지시-점프 by 이재천   
CREATE PROC KPX_SPUTransImpOrderJump  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    CREATE TABLE #TUIImpBLItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TUIImpBLItem'   
    IF @@ERROR <> 0 RETURN    
    
    
    SELECT B.BizUnit, 
           C.BizUnitName, 
           B.SMImpKind, 
           D.MinorName AS SMImpKind, 
           B.CustSeq, 
           E.CustName, 
           E.CustNo, 
           B.CurrSeq, 
           F.CurrName, 
           B.ExRate, 
           B.UMPriceTerms, 
           G.MinorName AS UMPriceTermsName, 
           B.UMPayment1, 
           H.MinorName AS UMPayment1Name
           
      FROM (SELECT TOP 1 BLSeq FROM #TUIImpBLItem ) AS A 
      LEFT OUTER JOIN _TUIImpBL                     AS B ON ( B.CompanySeq = @CompanySeq AND B.BLSeq = A.BLSeq ) 
      LEFT OUTER JOIN _TDABizUnit                   AS C ON ( C.CompanySeq = @CompanySeq AND C.BizUnit = B.BizUnit ) 
      LEFT OUTER JOIN _TDASMinor                    AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = B.SMImpKind ) 
      LEFT OUTER JOIN _TDACust                      AS E ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN _TDACurr                      AS F ON ( F.CompanySeq = @CompanySeq AND F.CurrSeq = B.CurrSeq ) 
      LEFT OUTER JOIN _TDAUMinor                    AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = B.UMPriceTerms ) 
      LEFT OUTER JOIN _TDAUMinor                    AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = B.UMPayment1 )
    
    
    SELECT A.ItemSeq, 
           B.ItemName, 
           B.ItemNo, 
           B.Spec, 
           A.UnitSeq, 
           C.UnitName, 
           A.Price, 
           A.Qty, 
           A.CurAmt, 
           A.DomAmt, 
           --A.UMPacking, -- 포장구분 
           --D.MinorName AS UMPackingName, 
           --A.ShipDate AS TransDate, 
           A.MakerSeq, 
           E.CustName AS Maker, 
           A.STDQty, 
           A.LotNo, 
           A.STDUnitSeq, 
           F.UnitName AS STDUnitName, 
           A.BLSeq, 
           A.BLSerl
      FROM #TUIImpBLItem AS Z 
      LEFT OUTER JOIN _TUIImpBLItem AS A ON ( A.CompanySeq = @CompanySeq AND A.BLSeq = Z.BLSeq AND A.BLSerl = Z.BLSerl ) 
      LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit      AS C ON ( C.CompanySeq = @CompanySeq AND C.UnitSeq = A.UnitSeq ) 
      LEFT OUTER JOIN _TDACust      AS E ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.MakerSeq ) 
      LEFT OUTER JOIN _TDAUnit      AS F ON ( F.CompanySeq = @CompanySeq AND F.UnitSeq = A.StdUnitSeq ) 
    
    RETURN 
GO
exec KPX_SPUTransImpOrderJump @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BLSeq>1000090</BLSeq>
    <BLSerl>1</BLSerl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BLSeq>1000093</BLSeq>
    <BLSerl>1</BLSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BLSeq>1000095</BLSeq>
    <BLSerl>1</BLSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BLSeq>1000098</BLSeq>
    <BLSerl>1</BLSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>10</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BLSeq>1000099</BLSeq>
    <BLSerl>2</BLSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>11</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BLSeq>1000100</BLSeq>
    <BLSerl>1</BLSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>12</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <BLSeq>1000101</BLSeq>
    <BLSerl>1</BLSerl>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026300,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1335