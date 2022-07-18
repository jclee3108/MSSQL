IF OBJECT_ID('KPXCM_SPDBOMBatchQuery') IS NOT NULL 
    DROP PROC KPXCM_SPDBOMBatchQuery
GO 

-- v2015.09.16 

/*************************************************************************************************    
 FORM NAME           -       FrmPDBOMBatch  
 DESCRIPTION         -     배합비   
 CREAE DATE          -       2008.05.30      CREATE BY: 김현  
 LAST UPDATE  DATE   -       2008.09.06         UPDATE BY: 김현  
        2009. 09.08 UPDATE BY 송경애  
      :: 대표배합비, BOM차수 , 공정흐름유형 추가  
*************************************************************************************************/    
CREATE PROCEDURE KPXCM_SPDBOMBatchQuery    
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
            @FactUnit  INT,  
            @ItemSeq   INT,  
            @BatchSize DECIMAL(19, 5),  
            @BatchSeq  INT   
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument        
  
    SELECT  @ItemSeq      = ISNULL(ItemSeq, 0)  ,  
            @BatchSize    = ISNULL(BatchSize, 0),  
            @BatchSeq     = ISNULL(BatchSeq, 0)        
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
    WITH (  ItemSeq        INT,  
            BatchSize      DECIMAL(19,5),  
            BatchSeq       INT    )  
      
    SELECT A.BatchSeq, A.FactUnit , A.BatchNo  , A.BatchName  , A.ItemSeq  ,  
           B.ItemNo  , A.BatchSize, A.BatchName, A.ProdUnitSeq, A.IsUse    ,  
           A.Remark  , B.ItemName , A.DateFr   , A.DateTo     , C.UnitName AS ProdUnitName   
         , A.IsDefault        
   , A.BOMRev   AS BOMRev  -- BOM차수   
   , A.ProcTypeSeq AS ProcTypeSeq -- 공정흐름유형코드   
   , D.ProcTypeName AS ProcTypeName -- 공정흐름유형명                   
      FROM KPXCM_TPDBOMBatch AS A WITH(NOLOCK)   
           LEFT OUTER JOIN _TDAItem  AS B ON A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq  
           LEFT OUTER JOIN _TDAUnit  AS C ON A.CompanySeq = C.CompanySeq AND A.ProdUnitSeq = C.UnitSeq  
     LEFT OUTER JOIN _TPDProcType AS D ON A.CompanySeq = D.CompanySeq AND A.ProcTypeSeq = D.ProcTypeSeq  
     WHERE A.CompanySeq = @CompanySeq  
--        AND A.ItemSeq    = @ItemSeq  
--        AND A.BatchSize  = @BatchSize  
       AND A.BatchSeq = @BatchSeq  
RETURN    
go
exec KPXCM_SPDBOMBatchQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BatchSeq>9</BatchSeq>
    <FactUnit>5</FactUnit>
    <ItemSeq>1274</ItemSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032083,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026594