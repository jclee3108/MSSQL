IF OBJECT_ID('KPXCM_SPDProdProcReset') IS NOT NULL 
    DROP PROC KPXCM_SPDProdProcReset
GO 

-- v2016.03.07 
-- 제품별생산소요등록-차수증가 by 전경만
create PROC KPXCM_SPDProdProcReset
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
            @ItemSeq        INT,
            @ItemBomRev     NCHAR(2),
            @MaxRev     NCHAR(2),
            @PatternRev NCHAR(2)

    CREATE TABLE #ProdProcGetRev (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#ProdProcGetRev'
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    SELECT @ItemSeq         = ISNULL(ItemSeq, 0),
           @PatternRev      = ISNULL(PatternRev, '')
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ItemSeq         INT,
			PatternRev      NCHAR(2) 
            --ItemBomRev      NCHAR(2)
           )    
    
    SELECT @MaxRev = MAX(PatternRev)
      FROM KPX_TPDProdProc 
     WHERE CompanySeq = @CompanySeq AND ItemSeq = @ItemSeq
    
    
    delete from KPX_TPDProdProcItem
	 where CompanySeq = @CompanySeq
	   and ItemSeq = @ItemSeq
	   and PatternRev = @PatternRev


    SELECT * FROM #ProdProcGetRev AS A
RETURN

exec KPX_SPDProdProcGetRev @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemSeq>1</ItemSeq>
    <ItemName>테스트1</ItemName>
    <ItemNo>2000001</ItemNo>
    <Spec>Genuine-2000001</Spec>
    <AssetSeq>2</AssetSeq>
    <AssetName>제품</AssetName>
    <ItemBOMRev>02</ItemBOMRev>
    <PatternRev />
    <ProdQty>0</ProdQty>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027562,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=24223,@PgmSeq=1023043
GO


