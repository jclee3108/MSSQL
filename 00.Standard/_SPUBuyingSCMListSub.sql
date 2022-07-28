
IF OBJECT_ID('_SPUBuyingSCMListSub')IS NOT NULL 
    DROP PROC _SPUBuyingSCMListSub
GO

-- v2013.10.22 

-- 구매SCM정산조회(협력사)_Sheet2조회 by이재천
CREATE PROC _SPUBuyingSCMListSub                
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
            @DelvInSeq INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @DelvInSeq = ISNULL(DelvInSeq,0) 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
    
      WITH (DelvInSeq INT) 
    
    
    CREATE TABLE #TMP_SourceTable 
        (IDOrder   INT, 
         TableName NVARCHAR(100))  
         
    CREATE TABLE #TCOMSourceTracking 
       (IDX_NO  INT, 
        IDOrder  INT, 
        Seq      INT, 
        Serl     INT, 
        SubSerl  INT, 
        Qty      DECIMAL(19,5), 
        StdQty   DECIMAL(19,5), 
        Amt      DECIMAL(19,5), 
        VAT      DECIMAL(19,5)) 
            
    IF @PgmSeq = 11309
    BEGIN
        SELECT ROW_NUMBER()OVER(ORDER BY B.DelvInSeq, B.DelvInSerl) AS IDX_NO, 
               B.DelvInSeq, 
               B.DelvInSerl, 
               B.ItemSeq,  
               B.UnitSeq, 
               B.LOTNo,
               B.WhSeq 
        
          INTO #TPUDelvIn
          FROM _TPUDelvIn                AS A WITH (NOLOCK) 
          LEFT OUTER JOIN _TPUDelvInItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DelvInSeq = A.DelvInSeq ) 
	     WHERE A.CompanySeq = @CompanySeq
           AND A.DelvInSeq = @DelvInSeq
    
        INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
             SELECT 1, '_TPUDelvItem' -- 찾을 데이터의 테이블 
        UNION ALL 
             SELECT 2, '_TPUORDPOItem'
    
        EXEC _SCOMSourceTracking 
             @CompanySeq = @CompanySeq, 
             @TableName = '_TPUDelvInItem',  -- 기준 테이블
             @TempTableName = '#TPUDelvIn',  -- 기준템프테이블
             @TempSeqColumnName = 'DelvInSeq',  -- 템프테이블 Seq
             @TempSerlColumnName = 'DelvInSerl',  -- 템프테이블 Serl
             @TempSubSerlColumnName = '' 
        
        SELECT A.ItemSeq, 
               D.ItemName, 
               D.ItemNo, 
               D.Spec, 
               A.UnitSeq, 
               E.UnitName, 
               ISNULL(Z.Qty,0) AS DelvQty, 
               ISNULL(X.Qty,0) AS POQty, 
               ISNULL(F.Qty,0) AS DelvInQty, 
               ISNULL(F.CurAmt,0) AS InCurAmt, 
               ISNULL(F.CurVAT,0) AS InCurVAT, 
               ISNULL(F.CurAmt,0) + ISNULL(F.CurVAT,0) AS InTotCurAmt, 
               ISNULL(F.DomAmt,0) AS InDomAmt, 
               ISNULL(F.DomVAT,0) AS InDomVAT, 
               ISNULL(F.DomAmt,0) + ISNULL(F.DomVAT,0) AS InTotDomAmt, 
               A.WHSeq AS InWHSeq, 
               G.WHName AS InWHName, 
               CASE WHEN ISNULL(F.SlipSeq,0) = 0 THEN 0 ELSE 1 END AS IsSlip, 
               F.Price AS InPrice, 
               A.LotNo
        
          FROM #TPUDelvIn                     AS A 
          LEFT OUTER JOIN #TCOMSourceTracking AS B              ON ( B.IDX_NO = A.IDX_NO AND B.IDOrder = 1 ) 
          LEFT OUTER JOIN _TPUDelvItem        AS Z WITH(NOLOCK) ON ( Z.CompanySeq = @CompanySeq AND Z.DelvSeq = B.Seq AND Z.DelvSerl = B.Serl ) 
          LEFT OUTER JOIN #TCOMSourceTracking AS C              ON ( C.IDX_NO = A.IDX_NO AND C.IDOrder = 2 ) 
          LEFT OUTER JOIN _TPUORDPOItem       AS X WITH(NOLOCK) ON ( X.CompanySeq = @CompanySeq AND X.POSeq = C.Seq AND X.POSerl = C.Serl )
          LEFT OUTER JOIN _TDAItem            AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN _TDAUnit            AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.UnitSeq = A.UnitSeq ) 
          LEFT OUTER JOIN _TPUBuyingAcc       AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.SourceSeq = A.DelvInSeq AND F.SourceSerl = A.DelvInSerl ) 
          LEFT OUTER JOIN _TDAWH              AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.WHSeq = A.WHSeq ) 
         WHERE F.SourceType = 1
    END
    ELSE
    BEGIN
        SELECT ROW_NUMBER()OVER(ORDER BY B.OSPDelvInSeq, B.OSPDelvInSerl) AS IDX_NO, 
               B.OSPDelvInSeq, 
               B.OSPDelvInSerl, 
               B.ItemSeq,  
               B.UnitSeq, 
               B.RealLotNo, 
               B.WhSeq 
        
          INTO #TPDOSPDelvIn
          FROM _TPDOSPDelvIn                AS A WITH (NOLOCK) 
          LEFT OUTER JOIN _TPDOSPDelvInItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OSPDelvInSeq = A.OSPDelvInSeq ) 
	     WHERE A.CompanySeq = @CompanySeq
           AND A.OSPDelvInSeq = @DelvInSeq
    
        INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
             SELECT 1, '_TPDOSPDelvItem' -- 찾을 데이터의 테이블 
        UNION ALL 
             SELECT 2, '_TPDOSPPOItem'
    
        EXEC _SCOMSourceTracking 
             @CompanySeq = @CompanySeq, 
             @TableName = '_TPDOSPDelvInItem',  -- 기준 테이블
             @TempTableName = '#TPDOSPDelvIn',  -- 기준템프테이블
             @TempSeqColumnName = 'OSPDelvInSeq',  -- 템프테이블 Seq
             @TempSerlColumnName = 'OSPDelvInSerl',  -- 템프테이블 Serl
             @TempSubSerlColumnName = '' 
        
        SELECT A.ItemSeq, 
               D.ItemName, 
               D.ItemNo, 
               D.Spec, 
               A.UnitSeq, 
               E.UnitName, 
               ISNULL(Z.Qty,0) AS DelvQty, 
               ISNULL(X.Qty,0) AS POQty, 
               ISNULL(F.Qty,0) AS DelvInQty, 
               ISNULL(F.CurAmt,0) AS InCurAmt, 
               ISNULL(F.CurVAT,0) AS InCurVAT, 
               ISNULL(F.CurAmt,0) + ISNULL(F.CurVAT,0) AS InTotCurAmt, 
               ISNULL(F.DomAmt,0) AS InDomAmt, 
               ISNULL(F.DomVAT,0) AS InDomVAT, 
               ISNULL(F.DomAmt,0) + ISNULL(F.DomVAT,0) AS InTotDomAmt, 
               A.WHSeq AS InWHSeq, 
               G.WHName AS InWHName, 
               CASE WHEN ISNULL(F.SlipSeq,0) = 0 THEN 0 ELSE 1 END AS IsSlip, 
               F.Price AS InPrice, 
               A.RealLotNo AS LotNo
        
          FROM #TPDOSPDelvIn                  AS A 
          LEFT OUTER JOIN #TCOMSourceTracking AS B              ON ( B.IDX_NO = A.IDX_NO AND B.IDOrder = 1 ) 
          LEFT OUTER JOIN _TPDOSPDelvItem     AS Z WITH(NOLOCK) ON ( Z.CompanySeq = @CompanySeq AND Z.OSPDelvSeq = B.Seq AND Z.OSPDelvSerl = B.Serl ) 
          LEFT OUTER JOIN #TCOMSourceTracking AS C              ON ( C.IDX_NO = A.IDX_NO AND C.IDOrder = 2 ) 
          LEFT OUTER JOIN _TPDOSPPOItem       AS X WITH(NOLOCK) ON ( X.CompanySeq = @CompanySeq AND X.OSPPOSeq = C.Seq AND X.OSPPOSerl = C.Serl )
          LEFT OUTER JOIN _TDAItem            AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
          LEFT OUTER JOIN _TDAUnit            AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.UnitSeq = A.UnitSeq ) 
          LEFT OUTER JOIN _TPUBuyingAcc       AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.SourceSeq = A.OSPDelvInSeq AND F.SourceSerl = A.OSPDelvInSerl ) 
          LEFT OUTER JOIN _TDAWH              AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.WHSeq = A.WHSeq ) 
         WHERE F.SourceType = 2
         
    END
    
    RETURN
GO
exec _SPUBuyingSCMListSub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>10</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <DelvInSeq>305971</DelvInSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=9568,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=11316

