  
IF OBJECT_ID('KPX_SSLDelvItemPriceQuerySub') IS NOT NULL   
    DROP PROC KPX_SSLDelvItemPriceQuerySub  
GO  
  
-- v2014.11.12  
  
-- 거래처별납품처단가등록-Item조회 by 이재천   
CREATE PROC KPX_SSLDelvItemPriceQuerySub  
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
            @BizUnit    INT,  
            @CustSeq    INT, 
            @DVPlaceSeq INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizUnit     = ISNULL( BizUnit, 0 ),  
           @CustSeq     = ISNULL( CustSeq, '' ),
           @DVPlaceSeq  = ISNULL( DVPlaceSeq, 0 ) 
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            BizUnit    INT,
            CustSeq    INT,  
            DVPlaceSeq INT     
           )
    
    -- 최종조회   
    SELECT B.CfmCode AS IsCfm, 
           C.ItemName, 
           C.ItemNo, 
           C.Spec, 
           A.ItemSeq, 
           D.UnitName, 
           A.UnitSeq, 
           E.CurrName, 
           A.CurrSeq, 
           A.SDate, 
           A.EDate, 
           A.DrumPrice, 
           A.TankPrice, 
           A.BoxPrice, 
           A.Remark, 
           A.DVItemPriceSeq 
      FROM KPX_TSLDelvItemPrice         AS A 
      LEFT OUTER JOIN KPX_TSLDelvItemPrice_Confirm AS B ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.DVItemPriceSeq ) 
      LEFT OUTER JOIN _TDAItem          AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit          AS D ON ( D.CompanySeq = @CompanySeq AND D.UnitSeq = A.UnitSeq ) 
      LEFT OUTER JOIN _TDACurr          AS E ON ( E.CompanySeq = @CompanySeq AND E.CurrSeq = A.CurrSeq ) 
      LEFT OUTER JOIN _TDACustClass     AS F ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = A.CustSeq AND F.UMajorCustClass = 8004 ) 
      LEFT OUTER JOIN _TDAUMinor        AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = F.UMCustClass ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = G.MinorSeq AND H.Serl = 1001 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND @CustSeq = A.CustSeq 
       AND @BizUnit = H.ValueSeq 
       AND @DVPlaceSeq = A.DVPlaceSeq 
       
    
    
    RETURN  
GO 
EXEC KPX_SSLDelvItemPriceQuerySub @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <BizUnit>2</BizUnit>
    <CustSeq>12358</CustSeq>
    <DVPlaceSeq>1</DVPlaceSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1025779, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 50322, @PgmSeq = 1021314
