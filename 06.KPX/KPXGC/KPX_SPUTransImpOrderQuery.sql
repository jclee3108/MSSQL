  
IF OBJECT_ID('KPX_SPUTransImpOrderQuery') IS NOT NULL   
    DROP PROC KPX_SPUTransImpOrderQuery  
GO  
  
-- v2014.11.28  
  
-- 수입운송지시-조회 by 이재천   
CREATE PROC KPX_SPUTransImpOrderQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @TransImpSeq    INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @TransImpSeq   = ISNULL( TransImpSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (TransImpSeq   INT)    
      
    -- 최종조회(마스터) 
    SELECT A.TransImpSeq, 
           A.TransImpNo, 
           A.BizUnit, 
           B.BizUnitName, 
           A.SMImpKind, 
           C.MinorName AS SMImpKind, 
           A.DeptSeq, 
           D.DeptName, 
           A.EmpSeq, 
           E.EmpName, 
           A.CurrSeq, 
           F.CurrName, 
           A.ContQty, 
           A.CarNo, 
           A.Remark, 
           A.UMCountry, 
           G.MinorName AS UMCountryName, 
           A.UMPrice, 
           H.MinorName AS UMPriceName, 
           A.UMTrans, 
           I.MinorName AS UMTransName, 
           A.UMCont, 
           J.MinorName AS UMContName, 
           A.UMPort, 
           K.MinorName AS UMPortName,
           A.UMPayGet, 
           L.MinorName AS UMPayGetName, 
           A.UMPayment1, 
           M.MinorName AS UMPayment1Name, 
           A.UMPriceTerms, 
           N.MinorName AS UMPriceTermsName, 
           A.CustSeq, 
           O.CustName, 
           O.CustNo
    
      FROM KPX_TPUTransImpOrder         AS A 
      LEFT OUTER JOIN _TDABizUnit       AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDASMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMImpKind ) 
      LEFT OUTER JOIN _TDADept          AS D ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp           AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDACurr          AS F ON ( F.CompanySeq = @CompanySeq AND F.CurrSeq = A.CurrSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = A.UMCountry ) 
      LEFT OUTER JOIN _TDAUMinor        AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.UMPrice ) 
      LEFT OUTER JOIN _TDAUMinor        AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = A.UMTrans ) 
      LEFT OUTER JOIN _TDAUMinor        AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = A.UMCont ) 
      LEFT OUTER JOIN _TDAUMinor        AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = A.UMPort ) 
      LEFT OUTER JOIN _TDAUMinor        AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = A.UMPayGet ) 
      LEFT OUTER JOIN _TDAUMinor        AS M ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = A.UMPayment1 ) 
      LEFT OUTER JOIN _TDAUMinor        AS N ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = A.UMPriceTerms ) 
      LEFT OUTER JOIN _TDACust          AS O ON ( O.CompanySeq = @CompanySeq AND O.CustSeq = A.CustSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.TransImpSeq = @TransImpSeq 
       
    -- 최종조회(SS1) 
    SELECT A.TransImpSeq, 
           A.TransImpSerl, 
           A.ItemSeq, 
           B.ItemName, 
           B.ItemNo, 
           B.Spec, 
           A.UnitSeq, 
           C.UnitName, 
           A.Price, 
           A.Qty, 
           A.CurAmt, 
           A.DomAmt, 
           A.UMPacking, -- 포장구분 
           D.MinorName AS UMPackingName, 
           A.TransDate, 
           A.MakerSeq, 
           E.CustName AS Maker, 
           A.STDQty, 
           A.LotNo, 
           A.STDUnitSeq, 
           F.UnitName AS STDUnitName, 
           A.BLSeq, 
           A.BLSerl
           
      FROM KPX_TPUTransImpOrderItem AS A 
      LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit      AS C ON ( C.CompanySeq = @CompanySeq AND C.UnitSeq = A.UnitSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMPacking ) 
      LEFT OUTER JOIN _TDACust      AS E ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.MakerSeq ) 
      LEFT OUTER JOIN _TDAUnit      AS F ON ( F.CompanySeq = @CompanySeq AND F.UnitSeq = A.StdUnitSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.TransImpSeq = @TransImpSeq 
    
    RETURN  
GO
exec KPX_SPUTransImpOrderQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <TransImpSeq>1</TransImpSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026300,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021338
