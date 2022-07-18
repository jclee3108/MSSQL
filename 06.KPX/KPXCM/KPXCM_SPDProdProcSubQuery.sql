IF OBJECT_ID('KPXCM_SPDProdProcSubQuery') IS NOT NULL 
    DROP PROC KPXCM_SPDProdProcSubQuery
GO 

-- v2016.03.07 
-- 제품별생산소요등록-상세조회 by 전경만
CREATE PROC KPXCM_SPDProdProcSubQuery
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
            @ItemBOMRev     NCHAR(2),
            @PatternRev     NCHAR(2)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ItemSeq         = ISNULL(ItemSeq, 0),
           @ItemBOMRev      = ISNULL(ItemBOMRev, ''),
           @PatternRev      = ISNULL(PatternRev, '')
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ItemSeq        INT,
            ItemBOMRev     NCHAR(2),
            PatternRev     NCHAR(2)
           )   

    IF EXISTS (SELECT 1 FROM KPX_TPDProdProcItem WHERE CompanySeq = @CompanySeq AND ItemSeq = @ItemSeq AND PatternRev = @PatternRev)
    BEGIN
    SELECT A.ItemSeq,
               A.PatternRev,
               @ItemBOMRev      AS ItemBOMRev,
               A.SubItemSeq,
               I.ItemName       AS SubItemName,
               I.ItemNo         AS SubItemNo,
               I.Spec           AS SubItemSpec,
               I.AssetSeq       AS AssetSeq,
               T.AssetName      AS AssetName,
               B.UnitSeq        AS UnitSeq,
               U.UnitName       AS UnitName,
               A.PatternQty,
               CASE WHEN ISNULL(B.NeedQtyDenominator,0) <> 0 THEN  ISNULL(B.NeedQtyNumerator,0) / ISNULL(B.NeedQtyDenominator,0)
                    ELSE 0 END  AS NeedQty,
               '1'              AS IsSave,
               A.ProdQty        AS ProdQty,
			   A.SortNum        ,
			   A.Serl           AS Serl,
			   A.BomSerl,
			   A.RowNum, 
			   CASE WHEN ISNULL(B.NeedQtyDenominator,0) <> 0 THEN  ISNULL(B.NeedQtyNumerator,0) / ISNULL(B.NeedQtyDenominator,0)
                    ELSE 0 END * ISNULL(A.ProdQty,0) AS PatternCalQty, -- 지시량(계산) : 총소요량 * 배율 
               (CASE WHEN ISNULL(B.NeedQtyDenominator,0) <> 0 THEN  ISNULL(B.NeedQtyNumerator,0) / ISNULL(B.NeedQtyDenominator,0)
                     ELSE 0 END * ISNULL(A.ProdQty,0)) - ISNULL(A.PatternQty,0) AS DiffQty -- 검산 : 지시량(계산) - 지시량(입력) 
               
			   

          FROM KPX_TPDProdProcItem AS A
               JOIN KPX_TPDProdProc AS P WITH(NOLOCK) ON P.CompanySeq = A.CompanySeq
                                                     AND P.ItemSeq = A.ItemSeq
                                                     AND P.PatternRev = A.PatternRev
               LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq
                                                         AND I.ItemSeq = A.SubItemSeq
               LEFT OUTER JOIN _TDAItemAsset AS T WITH(NOLOCK) ON T.CompanySeq = I.CompanySeq
                                                              AND T.AssetSeq = I.AssetSeq
               LEFT OUTER JOIN _TPDBOM AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq
                                                        AND B.ItemSeq = A.ItemSeq
                                                        AND B.ItemBOMRev = @ItemBOMRev
                                                        AND B.SubItemSeq = A.SubItemSeq
														And A.BomSerl = B.Serl
               LEFT OUTER JOIN _TDAUnit AS U WITH(NOLOCK) ON U.CompanySeq = B.CompanySeq
                                                         AND U.UnitSeq = B.UnitSeq
         WHERE A.CompanySeq = @CompanySeq
           AND A.ItemSeq = @ItemSeq
           AND A.PatternRev = @PatternRev
	  order by A.Serl,A.SubItemSeq,A.SortNum,A.PatternQty
    END
    ELSE BEGIN
        SELECT A.ItemSeq,
               @PatternRev          AS PatternRev,
               A.ItemBOMRev         AS ItemBOMRev,
               A.SubItemSeq         AS SubItemSeq,
               I.ItemName       AS SubItemName,
               I.ItemNo         AS SubItemNo,
               I.Spec           AS SubItemSpec,
               I.AssetSeq       AS AssetSeq,
               T.AssetName      AS AssetName,
               A.UnitSeq        AS UnitSeq,
               U.UnitName       AS UnitName,
               CASE WHEN ISNULL(A.NeedQtyDenominator,0) <> 0 THEN  ISNULL(A.NeedQtyNumerator,0) / ISNULL(A.NeedQtyDenominator,0)
                    ELSE 0 END  AS NeedQty,
               '0'              AS IsSave,
			   Row_Number() over(PARTITION BY A.ItemSeq,A.SubItemSeq Order by A.ItemSeq,A.SubItemSeq,A.Serl) AS SortNum,
			   A.Serl  AS BomSerl
          FROM _TPDBOM AS A
               LEFT OUTER JOIN _TDAItem AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq
                                                         AND I.ItemSeq = A.SubItemSeq
               LEFT OUTER JOIN _TDAItemAsset AS T WITH(NOLOCK) ON T.CompanySeq = I.CompanySeq
                                                              AND T.AssetSeq = I.AssetSeq
               LEFT OUTER JOIN _TDAUnit AS U WITH(NOLOCK) ON U.CompanySeq = A.CompanySeq
                                                         AND U.UnitSeq = A.UnitSeq
         WHERE A.CompanySeq = @CompanySeq
           AND A.ItemSeq = @ItemSeq
           AND A.ItemBOMRev = @ItemBOMRev
       order by A.Serl,A.ItemSeq,A.SubItemSeq
    END
      --select @ItemBOMRev
RETURN

GO


exec KPXCM_SPDProdProcSubQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <ItemSeq>1001148</ItemSeq>
    <ItemBOMRev>00</ItemBOMRev>
    <PatternRev>08</PatternRev>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027562,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1029315