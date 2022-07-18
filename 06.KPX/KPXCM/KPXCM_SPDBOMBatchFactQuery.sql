IF OBJECT_ID('KPXCM_SPDBOMBatchFactQuery') IS NOT NULL 
    DROP PROC KPXCM_SPDBOMBatchFactQuery
GO 

-- v2015.09.16 
/*************************************************************************************************  
  FORM NAME           -       FrmPDBOMBatchFact
  DESCRIPTION         -     사업장별 배합비 조회
  CREAE DATE          -       2008.09.02      CREATE BY: 김현
  LAST UPDATE  DATE   -       2008.09.02         UPDATE BY: 김현
                              2009.09.21         UPDATE BY: 송경애
                           :: 조회조건 - 공정흐름유형, 품번 추가, 시트컬럼 - 공정흐름유형, BOM차수 추가
 *************************************************************************************************/  
 CREATE PROCEDURE KPXCM_SPDBOMBatchFactQuery  
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT = 0,
     @ServiceSeq     INT = 0,
     @WorkingTag     NVARCHAR(10)= '',
     @CompanySeq     INT = 1,
     @LanguageSeq    INT = 1,
     @UserSeq        INT = 0,
     @PgmSeq         INT = 0
  
 AS       
     DECLARE @docHandle  INT          ,
             @ItemName   NVARCHAR(400),
             @BatchName  NVARCHAR(100),
             @BatchNo    NVARCHAR(12),
             @FactUnit   INT,
             @ProcTypeSeq    INT,         -- 공정흐름유형코드
             @ItemNo     NVARCHAR(100)    -- 품번
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument      
      SELECT  @ItemName      = ItemName , 
             @BatchName     = BatchName,
             @BatchNo       = BatchNo  ,
             @FactUnit      = FactUnit ,
             @ProcTypeSeq   = ProcTypeSeq,
             @ItemNo        = ItemNo 
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
     WITH (  ItemName        NVARCHAR(400),
             BatchName       NVARCHAR(100),
             BatchNo         NVARCHAR(12) ,
             FactUnit        INT          ,
             ProcTypeSeq     INT          ,
             ItemNo          NVARCHAR(100)   )
      SELECT A.BatchSeq, A.FactUnit , A.BatchNo  , A.BatchName  , A.ItemSeq  ,
            B.ItemNo  , A.BatchSize, A.BatchName, A.ProdUnitSeq, A.IsUse    ,
            A.Remark  , B.ItemName , A.DateFr   , A.DateTo     , A.IsDefault
          , A.BOMRev  , A.ProcTypeSeq, C.ProcTypeName 
       FROM KPXCM_TPDBOMBatch AS A WITH(NOLOCK) 
            LEFT OUTER JOIN _TDAItem AS B ON A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq
            LEFT OUTER JOIN _TPDProcType AS C ON A.CompanySeq = C.CompanySeq AND A.ProcTypeSeq = C.ProcTypeSeq
      WHERE A.CompanySeq = @CompanySeq
        AND (@ItemName  = ''    OR B.ItemName  LIKE @ItemName  + '%')
        AND (@BatchName = ''    OR A.BatchName LIKE @BatchName + '%')
        AND (@BatchNo   = ''    OR A.BatchNo   LIKE @BatchNo   + '%')
        AND (@FactUnit  = 0     OR A.FactUnit  = @FactUnit)
        AND (@ProcTypeSeq  = 0  OR A.ProcTypeSeq  = @ProcTypeSeq)
        AND (@ItemNo    = ''    OR B.ItemNo    LIKE @ItemNo + '%')
  RETURN  
 /**************************************************************************************************/