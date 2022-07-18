IF OBJECT_ID('KPXCM_SPDProdProcQuery') IS NOT NULL 
    DROP PROC KPXCM_SPDProdProcQuery
GO 

-- v2016.03.07 
-- 제품별생산소요등록-조회 by 전경만
CREATE PROC KPXCM_SPDProdProcQuery
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
            @ItemName       NVARCHAR(100),
            @ItemNo         NVARCHAR(100),
			@ItemSeq        INT, 
			@UseYn          NCHAR(1) 
           
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ItemName        = ISNULL(ItemName, ''),
           @ItemNo          = ISNULL(ItemNo, ''),
		   @ItemSeq         = ISNULL(ItemSeq,0), 
		   @UseYn           = ISNULL(UseYn, '0') 

    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ItemName        NVARCHAR(100),
            ItemNo          NVARCHAR(100),
			ItemSeq         INT, 
			UseYn           NCHAR(1) 
           )    
    
    SELECT A.ItemSeq,
           I.ItemName,
           I.ItemNo,
           I.Spec,
           I.AssetSeq,
           T.AssetName,
           A.ItemBOMRev,
           A.PatternRev,
           A.ProdQty,
		   ISNULL(A.UseYn,'0') AS UseYn, 
		   A.PatternName
      FROM KPX_TPDProdProc AS A
           LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = A.CompanySeq
                                                     AND I.ItemSeq = A.ItemSeq
           LEFT OUTER JOIN (SELECT ItemSeq
                              FROM _TPDBOM 
                             WHERE CompanySeq = @CompanySeq
                             GROUP BY ItemSeq) AS B ON B.ItemSeq = A.ItemSeq
                                                               --AND B.ItemBomRev = A.ItemBOMRev
           LEFT OUTER JOIN _TDAItemAsset AS T WITH(NOLOCK) ON T.CompanySeq = I.CompanySeq
                                                          AND T.AssetSeq = I.AssetSeq
     WHERE A.CompanySeq = @CompanySeq
  --     AND (@ItemName = '' OR I.ItemName LIKE '%'+@ItemName+'%')
       and (@ItemSeq = 0 or A.ItemSeq = @ItemSeq)
       AND (@ItemNo = '' OR RTRIM(LTRIM(I.ItemNo)) LIKE @ItemNo+'%')  
       AND (@UseYn = '0' OR (@UseYn = '1' AND ISNULL(A.UseYn,'0') = '0'))

     UNION 
    SELECT A.ItemSeq,
           I.ItemName,
           I.ItemNo,
           I.Spec,
           I.AssetSeq,
           T.AssetName,
           A.ItemBOMRev,
           '' PatternRev,
           0  ProdQty,
		   '0' UseYn,
		   '' PatternName
      FROM (SELECT ItemSeq, ItemBOMRev AS ItemBOMRev
              FROM _TPDBOM 
             WHERE CompanySeq = @CompanySeq
             GROUP BY ItemSeq, ItemBOMRev) AS A
           LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq
                                                     AND I.ItemSeq = A.ItemSeq
           LEFT OUTER JOIN _TDAItemAsset AS T WITH(NOLOCK) ON T.CompanySeq = I.CompanySeq
                                                          AND T.AssetSeq = I.AssetSeq
           LEFT OUTER JOIN KPX_TPDProdProc AS P WITH(NOLOCK) ON P.CompanySeq = @CompanySeq
                                                            AND P.ItemSeq =  A.ItemSeq
                                                            AND P.ItemBOMRev = A.ItemBOMRev
      WHERE   (@ItemSeq = 0 or A.ItemSeq = @ItemSeq )
	
       AND (@ItemNo = '' OR RTRIM(LTRIM(I.ItemNo)) LIKE @ItemNo+'%')  
       AND ISNULL(P.CompanySeq,0) = 0
    
RETURN

GO


exec KPXCM_SPDProdProcQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ItemSeq>1001148</ItemSeq>
    <ItemName>세호-본체</ItemName>
    <ItemNo>     -00010-1</ItemNo>
    <UseYn>1</UseYn>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1035598,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1029315