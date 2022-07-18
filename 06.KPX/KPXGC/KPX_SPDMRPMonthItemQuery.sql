  
IF OBJECT_ID('KPX_SPDMRPMonthItemQuery') IS NOT NULL   
    DROP PROC KPX_SPDMRPMonthItemQuery  
GO  
  
-- v2014.12.16 
  
-- 월별자재소요계산-조회 by 이재천   
CREATE PROC KPX_SPDMRPMonthItemQuery  
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
            @MRPMonthSeq    INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @MRPMonthSeq = ISNULL( MRPMonthSeq, 0 )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (MRPMonthSeq   INT)    
    
    -- 최종조회   
    SELECT A.MRPMonthSeq, 
           A.MRPMonth, 
           A.ItemSeq, 
           A.CalcType AS KindSeq, 
           A.UnitSeq, 
           A.Qty AS Value
      INTO #BaseData 
      FROM KPX_TPDMRPMonthItem AS A 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.MRPMonthSeq = @MRPMonthSeq )   

    
    CREATE TABLE #Title
    (
        ColIdx     INT IDENTITY(0, 1), 
        Title      NVARCHAR(100), 
        TitleSeq   INT
    )
    INSERT INTO #Title ( Title, TitleSeq ) 
    SELECT DISTINCT STUFF(MRPMonth,5,0,'-'), MRPMonth
      FROM #BaseData 
     ORDER BY MRPMonth 
    
    SELECT * FROM #Title 
    
    CREATE TABLE #FixCol
    (
         RowIdx     INT IDENTITY(0, 1), 
         ItemSeq    INT, 
         Total      DECIMAL(19,5), 
         Kind       INT 
    )
    INSERT INTO #FixCol (ItemSeq, Total, Kind)
    SELECT ItemSeq, SUM(Value), KindSeq 
      FROM #BaseData 
     GROUP BY ItemSeq, KindSeq 
    
    SELECT C.ItemName, 
           A.ItemSeq, 
           C.ItemNo, 
           C.Spec, 
           D.UnitSeq, 
           D.UnitName,  
           B.LeadTime AS DelvTerm, 
           B.MinQty AS MinPurQty, 
           B.CustSeq, 
           E.CustName, 
           F.AssetName, 
           F.AssetSeq, 
           G.ItemClassSSeq AS ItemClassSeq, 
           G.ItemClasSName AS ItemClassName, 
           A.Kind AS KindSeq, 
           CASE WHEN A.Kind = 1 THEN '현재고' 
                WHEN A.Kind = 2 THEN '소요량' 
                WHEN A.Kind = 3 THEN '부족량' 
                ELSE ''
                END AS KindName, 
           A.Total, 
           H.SMPurKind  AS SMInOutTypePur, 
           I.MinorName AS SMInOutTypePurName 
           
      FROM #FixCol AS A 
      LEFT OUTER JOIN _TPUBASEBuyPriceItem AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.IsPrice = '1' )
      LEFT OUTER JOIN _TDAItem             AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit             AS D ON ( D.CompanySeq = @CompanySeq AND D.UnitSeq = C.UnitSeq ) 
      LEFT OUTER JOIN _TDACust             AS E ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = B.CustSeq ) 
      LEFT OUTER JOIN _TDAItemAsset        AS F ON ( F.CompanySeq = @CompanySeq AND F.AssetSeq = C.AssetSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS G ON ( G.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemPurchase     AS H ON ( H.CompanySeq = @CompanySeq AND H.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDASMinor           AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = H.SMPurKind ) 
     ORDER BY A.ItemSeq, A.Kind 
    
    -- 가변행 
    CREATE TABLE #Value
    (
         ItemSeq        INT, 
         YM             NCHAR(6), 
         Value          DECIMAL(19,5), 
         Kind           INT  
    )
    
    INSERT INTO #Value ( ItemSeq, YM, Value, Kind ) 
    SELECT ItemSeq, MRPMonth, Value, KindSeq 
      FROM #BaseData 
    
    SELECT B.RowIdx, A.ColIdx, C.Value AS Result
      FROM #Value AS C
      JOIN #Title AS A ON ( A.TitleSeq = C.YM ) 
      JOIN #FixCol AS B ON ( B.ItemSeq = C.ItemSeq AND B.Kind = C.Kind ) 
     ORDER BY A.ColIdx, B.RowIdx
    
    
    RETURN  
GO 

exec KPX_SPDMRPMonthItemQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <MRPMonthSeq>61</MRPMonthSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026771,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021414