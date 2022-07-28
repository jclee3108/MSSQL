
IF OBJECT_ID('_SPUBuyingSCMList')IS NOT NULL 
    DROP PROC _SPUBuyingSCMList
GO

-- v2013.10.22 

-- 구매SCM정산조회(협력사) by이재천
CREATE PROC _SPUBuyingSCMList                
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
            @DelvDateFr     NVARCHAR(8), 
            @DelvDateTo     NVARCHAR(8), 
            @DelvNo         NVARCHAR(100), 
            @DelvDeptSeq    INT, 
            @DelvEmpSeq     INT, 
            @CustSeq        INT, 
            @PONo           NVARCHAR(50) 
    
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
	SELECT @DelvDateFr  = ISNULL(DelvDateFr,''), 
	       @DelvDateTo  = ISNULL(DelvDateTo,''), 
	       @DelvNo      = ISNULL(DelvNo,''), 
	       @DelvDeptSeq = ISNULL(DelvDeptSeq,0), 
	       @DelvEmpSeq  = ISNULL(DelvEmpSeq,0), 
	       @CustSeq     = ISNULL(CustSeq,0), 
	       @PONo        = ISNULL(PONo,'')
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  
      WITH (
            DelvDateFr     NVARCHAR(8), 
            DelvDateTo     NVARCHAR(8), 
            DelvNo         NVARCHAR(100),
            DelvDeptSeq    INT, 
            DelvEmpSeq     INT, 
            CustSeq        INT, 
            PONo           NVARCHAR(50) 
            )
    
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
            
    CREATE TABLE #TMP_ProgressTable 
            (IDOrder   INT, 
             TableName NVARCHAR(100)) 
            
    CREATE TABLE #TCOMProgressTracking
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
        
        SELECT ROW_NUMBER()OVER(ORDER BY B.DelvSeq, B.DelvSerl) AS IDX_NO, 
               B.DelvSeq, 
               B.DelvSerl, 
               A.CustSeq, 
               A.DelvDate, 
               A.DelvNo, 
               A.DeptSeq, 
               A.EmpSeq 
        
          INTO #TPUDelv
          FROM _TPUDelv                AS A WITH (NOLOCK) 
          LEFT OUTER JOIN _TPUDelvItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
	     WHERE A.CompanySeq = @CompanySeq
           AND A.DelvDate BETWEEN @DelvDateFr AND @DelvDateTo
           AND (@DelvNo = '' OR A.DelvNo LIKE @DelvNo + '%')
           AND (@DelvDeptSeq = 0 OR A.DeptSeq = @DelvDeptSeq)
           AND (@DelvEmpSeq = 0 OR A.EmpSeq = @DelvEmpSeq) 
           AND (@CustSeq = 0 OR A.CustSeq = @CustSeq) 
    
        INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
             SELECT 1, '_TPUORDPOItem'   -- 찾을 데이터의 테이블 
    
        EXEC _SCOMSourceTracking 
             @CompanySeq = @CompanySeq, 
             @TableName = '_TPUDelvItem',  -- 기준 테이블
             @TempTableName = '#TPUDelv',  -- 기준템프테이블
             @TempSeqColumnName = 'DelvSeq',  -- 템프테이블 Seq
             @TempSerlColumnName = 'DelvSerl',  -- 템프테이블 Serl
             @TempSubSerlColumnName = '' 
    
        INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
             SELECT 1, '_TPUDelvInItem'   -- 데이터 찾을 테이블
    
        EXEC _SCOMProgressTracking 
            @CompanySeq = @CompanySeq, 
            @TableName = '_TPUDelvItem',    -- 기준이 되는 테이블
            @TempTableName = '#TPUDelv',  -- 기준이 되는 템프테이블
            @TempSeqColumnName = 'DelvSeq',  -- 템프테이블의 Seq
            @TempSerlColumnName = 'DelvSerl',  -- 템프테이블의 Serl
            @TempSubSerlColumnName = ''  
        
        SELECT MAX(H.CustName) AS CustName, 
               MAX(A.CustSeq) AS CustSeq, 
               MAX(D.PODate) AS PODate, 
               MAX(D.PONo) AS PONo, 
               MAX(A.DelvDate) AS DelvDate, 
               MAX(A.DelvNo) AS DelvNo, 
               MAX(I.DeptName) AS DelvDeptName, 
               MAX(A.DeptSeq) AS DelvDeptSeq, 
               MAX(J.EmpName) AS DelvEmpName, 
               MAX(A.EmpSeq) AS DelvEmpSeq, 
               MAX(G.DelvInDate) AS DelvInDate, 
               MAX(G.DelvInNo) AS DelvInNo, 
               G.DelvInSeq, 
               SUM(ISNULL(K.CurAmt,0)) AS CurAmt, 
               SUM(ISNULL(K.CurVAT,0)) AS CurVAT, 
               SUM(ISNULL(K.CurAmt,0)) + SUM(ISNULL(K.CurVAT,0)) AS TotCurAmt, 
               SUM(ISNULL(K.DomAmt,0)) AS DomAmt, 
               SUM(ISNULL(K.DomVAT,0)) AS DomVAT, 
               SUM(ISNULL(K.DomAmt,0)) + SUM(ISNULL(K.DomVAT,0)) AS TotDomAmt 
        
          FROM #TPUDelv AS A 
          LEFT OUTER JOIN #TCOMSourceTracking   AS B ON ( A.IDX_NO = B.IDX_NO ) 
          LEFT OUTER JOIN _TPUORDPO             AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.POSeq = B.Seq ) 
          LEFT OUTER JOIN #TCOMProgressTracking AS E ON ( E.IDX_NO = A.IDX_NO ) 
          LEFT OUTER JOIN _TPUDelvIn            AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.DelvInSeq = E.Seq ) 
          LEFT OUTER JOIN _TPUDelvInItem        AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.DelvInSeq = E.Seq AND F.DelvInSerl = E.Serl ) 
          LEFT OUTER JOIN _TDACust              AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.CustSeq = A.CustSeq ) 
          LEFT OUTER JOIN _TDADept              AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.DeptSeq = A.DeptSeq ) 
          LEFT OUTER JOIN _TDAEmp               AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.EmpSeq = A.EmpSeq ) 
          LEFT OUTER JOIN _TPUBuyingAcc         AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.SourceSeq = F.DelvInSeq AND K.SourceSerl = F.DelvInSerl ) 
          
         WHERE (@PONo = '' OR D.PONo LIKE @PONo + '%') 
           AND K.SourceType = 1
         GROUP BY G.DelvInSeq
         ORDER BY G.DelvInSeq
    END
    ELSE
    BEGIN
        SELECT ROW_NUMBER()OVER(ORDER BY B.OSPDelvSeq, B.OSPDelvSerl) AS IDX_NO, 
               B.OSPDelvSeq, 
               B.OSPDelvSerl, 
               A.CustSeq, 
               A.OSPDelvDate, 
               A.OSPDelvNo, 
               A.DeptSeq, 
               A.EmpSeq 
        
          INTO #TPDOSPDelv
          FROM _TPDOSPDelv                AS A WITH (NOLOCK) 
          LEFT OUTER JOIN _TPDOSPDelvItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OSPDelvSeq = A.OSPDelvSeq ) 
	     WHERE A.CompanySeq = @CompanySeq
           AND A.OSPDelvDate BETWEEN @DelvDateFr AND @DelvDateTo
           AND (@DelvNo = '' OR A.OSPDelvNo LIKE @DelvNo + '%')
           AND (@DelvDeptSeq = 0 OR A.DeptSeq = @DelvDeptSeq)
           AND (@DelvEmpSeq = 0 OR A.EmpSeq = @DelvEmpSeq) 
           AND (@CustSeq = 0 OR A.CustSeq = @CustSeq) 
    
        INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
             SELECT 1, '_TPDOSPPOItem'   -- 찾을 데이터의 테이블  
    
        EXEC _SCOMSourceTracking 
             @CompanySeq = @CompanySeq, 
             @TableName = '_TPDOSPDelvItem',  -- 기준 테이블
             @TempTableName = '#TPDOSPDelv',  -- 기준템프테이블
             @TempSeqColumnName = 'OSPDelvSeq',  -- 템프테이블 Seq
             @TempSerlColumnName = 'OSPDelvSerl',  -- 템프테이블 Serl
             @TempSubSerlColumnName = '' 
    
        INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
             SELECT 1, '_TPDOSPDelvInItem'   -- 데이터 찾을 테이블
    
        EXEC _SCOMProgressTracking 
            @CompanySeq = @CompanySeq, 
            @TableName = '_TPDOSPDelvItem',    -- 기준이 되는 테이블
            @TempTableName = '#TPDOSPDelv',  -- 기준이 되는 템프테이블
            @TempSeqColumnName = 'OSPDelvSeq',  -- 템프테이블의 Seq
            @TempSerlColumnName = 'OSPDelvSerl',  -- 템프테이블의 Serl
            @TempSubSerlColumnName = ''  
    
        SELECT MAX(H.CustName) AS CustName, 
               MAX(A.CustSeq) AS CustSeq, 
               MAX(D.PODate) AS PODate, 
               MAX(D.OSPPONo) AS PONo, 
               MAX(A.OSPDelvDate) AS DelvDate, 
               MAX(A.OSPDelvNo) AS DelvNo, 
               MAX(I.DeptName) AS DelvDeptName, 
               MAX(A.DeptSeq) AS DelvDeptSeq, 
               MAX(J.EmpName) AS DelvEmpName, 
               MAX(A.EmpSeq) AS DelvEmpSeq, 
               MAX(G.OSPDelvInDate) AS DelvInDate, 
               MAX(G.OSPDelvInNo) AS DelvInNo, 
               G.OSPDelvInSeq AS DelvInSeq, 
               SUM(ISNULL(K.CurAmt,0)) AS CurAmt, 
               SUM(ISNULL(K.CurVAT,0)) AS CurVAT, 
               SUM(ISNULL(K.CurAmt,0)) + SUM(ISNULL(K.CurVAT,0)) AS TotCurAmt, 
               SUM(ISNULL(K.DomAmt,0)) AS DomAmt, 
               SUM(ISNULL(K.DomVAT,0)) AS DomVAT, 
               SUM(ISNULL(K.DomAmt,0)) + SUM(ISNULL(K.DomVAT,0)) AS TotDomAmt                
        
          FROM #TPDOSPDelv AS A 
          LEFT OUTER JOIN #TCOMSourceTracking   AS B ON ( A.IDX_NO = B.IDX_NO ) 
          LEFT OUTER JOIN _TPDOSPPO             AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.OSPPOSeq = B.Seq ) 
          LEFT OUTER JOIN #TCOMProgressTracking AS E ON ( E.IDX_NO = A.IDX_NO ) 
          LEFT OUTER JOIN _TPDOSPDelvIn            AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.OSPDelvInSeq = E.Seq ) 
          LEFT OUTER JOIN _TPDOSPDelvInItem        AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.OSPDelvInSeq = E.Seq AND F.OSPDelvInSerl = E.Serl ) 
          LEFT OUTER JOIN _TDACust              AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.CustSeq = A.CustSeq ) 
          LEFT OUTER JOIN _TDADept              AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.DeptSeq = A.DeptSeq ) 
          LEFT OUTER JOIN _TDAEmp               AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.EmpSeq = A.EmpSeq ) 
          LEFT OUTER JOIN _TPUBuyingAcc         AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.SourceSeq = F.OSPDelvInSeq AND K.SourceSerl = F.OSPDelvInSerl ) 
          
         WHERE (@PONo = '' OR D.OSPPONo LIKE @PONo + '%') 
           AND K.SourceType = 2 
         GROUP BY G.OSPDelvInSeq
         ORDER BY G.OSPDelvInSeq
    
    END
    
    RETURN
GO
exec _SPUBuyingSCMList @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DelvDateFr>20130101</DelvDateFr>
    <DelvDateTo>20131022</DelvDateTo>
    <DelvNo />
    <DelvDeptSeq />
    <DelvDeptName />
    <DelvEmpSeq />
    <DelvEmpName />
    <CustName />
    <CustSeq />
    <PONo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=9568,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=11316