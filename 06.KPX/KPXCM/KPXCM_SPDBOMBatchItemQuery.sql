
IF OBJECT_ID('KPXCM_SPDBOMBatchItemQuery') IS NOT NULL 
    DROP PROC KPXCM_SPDBOMBatchItemQuery
GO 

-- v2015.09.16 

/*************************************************************************************************  
 FORM NAME           -       FrmPDBOMBatch  
 DESCRIPTION         -     배합비 디테일조회  
 CREAE DATE          -       2008.05.30      CREATE BY: 김현  
 LAST UPDATE  DATE   -       2008.06.11         UPDATE BY: 김현  
                             2009.09.09         UPDATE BY 송경애  
                           :: 공정, Overage, 평균함량, 조달구분 추가  
                             2009.09.16         UPDATE BY 송경애  
                           :: 품목자산분류 추가  
                             2009.09.17         UPDATE BY 송경애  
                           :: 품목자산분류명 추가  
                             2011.04.30         UPDATE BY 김일주  
                           :: 정렬순서, 적용시작일, 적용종료일 추가  
*************************************************************************************************/  
CREATE PROCEDURE KPXCM_SPDBOMBatchItemQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    DECLARE @docHandle INT,  
            @BatchSeq  INT  
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
    SELECT  @BatchSeq      = BatchSeq  
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
    WITH (  BatchSeq        INT)  
  
    SELECT A.BatchSeq    , A.Serl            , A.ItemSeq           , B.ItemName, B.ItemNo,  
           B.Spec        , C.UnitName        , B.UnitSeq           ,  
           (SELECT UnitName FROM _TDAUnit WHERE CompanySeq = A.CompanySeq AND UnitSeq = A.InputUnitSeq) AS InputUnitName,  
           A.InputUnitSeq, A.NeedQtyNumerator, A.NeedQtyDenominator, A.Remark  
   , A.ProcSeq    AS ProcSeq     -- 공정코드  
   , D.ProcName   AS ProcName     -- 공정명  
         , A.Overage    AS Overage      -- Overage(%)  
         , A.AvgContent AS AvgContent   -- 평균함량(%)  
         , A.SMDelvType AS SMDelvType   -- 조달구분  
         , B.AssetSeq   AS AssetSeq     -- 품목자산분류  
         , E.AssetName  AS AssetName    -- 품목자산분류명  
         , A.SortOrder                  -- 정렬순서  
         , A.DateFr                     -- 적용시작일  
         , A.DateTo                     -- 적용종료일  
      FROM KPXCM_TPDBOMBatchItem AS A WITH(NOLOCK)  
           LEFT OUTER JOIN _TDAItem AS B ON A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq  
           LEFT OUTER JOIN _TDAUnit AS C ON B.CompanySeq = C.CompanySeq AND B.UnitSeq = C.UnitSeq  
           LEFT OUTER JOIN _TPDBaseProcess AS D ON A.CompanySeq = D.CompanySeq AND A.ProcSeq = D.ProcSeq  
           LEFT OUTER JOIN _TDAItemAsset    AS E ON A.CompanySeq = E.CompanySeq AND B.AssetSeq = E.AssetSeq  
  
     WHERE A.CompanySeq = @CompanySeq  
       AND A.BatchSeq   = @BatchSeq  
     ORDER BY A.SortOrder, A.Serl  
  
  
RETURN  
/*****************************************************************************/  