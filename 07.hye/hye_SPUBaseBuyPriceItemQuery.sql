 
IF OBJECT_ID('hye_SPUBaseBuyPriceItemQuery') IS NOT NULL   
    DROP PROC hye_SPUBaseBuyPriceItemQuery  
GO  
  
-- v2016.12.16
  
-- 구매단가등록-조회 by 이재천
CREATE PROC hye_SPUBaseBuyPriceItemQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신

    DECLARE @docHandle      INT,  
            -- 조회조건   
            @SrtDate        NCHAR(8), 
            @EndDate        NCHAR(8), 
            @IsLast         NCHAR(1), 
            @UMDVGroupSeq   INT, 
            @UMItemClassL   INT,
            @UMItemClassM   INT,
            @UMItemClassS   INT,
            @ItemSeq        INT

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @SrtDate         = ISNULL( SrtDate     , '' ), 
           @EndDate         = ISNULL( EndDate     , '' ), 
           @IsLast          = ISNULL( IsLast      , '0' ), 
           @UMDVGroupSeq    = ISNULL( UMDVGroupSeq, 0 ), 
           @UMItemClassL    = ISNULL( UMItemClassL, 0 ), 
           @UMItemClassM    = ISNULL( UMItemClassM, 0 ), 
           @UMItemClassS    = ISNULL( UMItemClassS, 0 ), 
           @ItemSeq         = ISNULL( ItemSeq     , 0 )

      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
              SrtDate        NCHAR(8),
              EndDate        NCHAR(8),
              IsLast         NCHAR(1),
              UMDVGroupSeq   INT, 
              UMItemClassL   INT,
              UMItemClassM   INT,
              UMItemClassS   INT,
              ItemSeq        INT
           )    
    
    IF @EndDate = '' SELECT @EndDate = '99991231'



    SELECT A.PriceSeq, 
           A.ItemSeq, 
           C.ItemName, 
           C.ItemNo, 
           C.Spec, 
           D.UnitName, 
           A.UnitSeq, 
           E.CurrName, 
           A.CurrSeq, 
           F.MinorName AS UMDVGroup, 
           A.UMDVGroupSeq, 
           A.SrtDate, 
           A.EndDate, 
           A.YSSPrice,
           A.DelvPrice,
           A.StdPrice,
           A.SalesPrice, 
           A.ChgPrice, 
           A.IsChg, 
           A.Summary, 
           A.Remark,
           B.ItemClasSName AS UMItemClassSName, 
           B.ItemClasMName AS UMItemClassMName, 
           B.ItemClasLName AS UMItemClassLName

      FROM hye_TPUBaseBuyPriceItem      AS A 
      LEFT OUTER JOIN _VDAGetItemClass  AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItem          AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit          AS D ON ( D.CompanySeq = @CompanySeq AND D.UnitSeq = A.UnitSeq ) 
      LEFT OUTER JOIN _TDACurr          AS E ON ( E.CompanySeq = @CompanySeq AND E.CurrSeq = A.CurrSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS F ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMDVGroupSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (( @IsLast = '1' AND A.EndDate = '99991231' ) OR ( @IsLast = '0' ))
       AND (@UMDVGroupSeq = 0 OR A.UMDVGroupSeq = @UMDVGroupSeq)
       AND (@ItemSeq = 0 OR A.ItemSeq = @ItemSeq)
       AND (@UMItemClassS = 0 OR B.ItemClassSSeq = @UMItemClassS)
       AND (@UMItemClassM = 0 OR B.ItemClassMSeq = @UMItemClassM)
       AND (@UMItemClassL = 0 OR B.ItemClassLSeq = @UMItemClassL)
       AND ((A.SrtDate BETWEEN @SrtDate AND @EndDate) OR (A.EndDate BETWEEN @SrtDate AND @EndDate))
     ORDER BY A.ItemSeq, UnitSeq, CurrSeq, UMDVGroupSeq, SrtDate 
      


    RETURN  
    GO
    exec hye_SPUBaseBuyPriceItemQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <UMDVGroupSeq>1013554001</UMDVGroupSeq>
    <UMItemClassL />
    <UMItemClassM />
    <UMItemClassS />
    <SrtDate />
    <EndDate />
    <ItemSeq />
    <IsLast>0</IsLast>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730168,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730058