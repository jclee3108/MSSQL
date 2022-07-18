
IF OBJECT_ID('costel_SPDQCDelvItemResultPrint') IS NOT NULL 
    DROP PROC costel_SPDQCDelvItemResultPrint 
GO

-- v2013.12.13 
     
 -- 수입검사성적서_costel(출력물) by이재천   
 CREATE PROC costel_SPDQCDelvItemResultPrint 
     @xmlDocument    NVARCHAR(MAX),    
     @xmlFlags       INT = 0,    
     @ServiceSeq     INT = 0,     
     @WorkingTag     NVARCHAR(10)= '',    
     @CompanySeq     INT = 1,    
     @LanguageSeq    INT = 1,    
     @UserSeq        INT = 0,    
     @PgmSeq         INT = 0    
 AS     
     CREATE TABLE #TPDQCTestReport( WorkingTag NCHAR(1) NULL )      
     EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDQCTestReport'     
     IF @@ERROR <> 0 RETURN  
       
     SET NOCOUNT ON              
     SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
       
     CREATE TABLE #Temp      
     (       
         IDX_NO     INT IDENTITY,      
         Seq        INT         ,  
         Serl       INT         ,  
         ItemSeq    INT         ,  
         DelvNo     NVARCHAR(20)   
     )   
       
     INSERT INTO #Temp(Seq , Serl, ItemSeq, DelvNo)                    
     SELECT DelvSeq, DelvSerl, ItemSeq, DelvNo  
       FROM #TPDQCTestReport  
       
         
     CREATE TABLE #TMP_SOURCETABLE  
     (  
         IDOrder     INT,  
         TableName   NVARCHAR(100)  
     )            
         
     CREATE TABLE #TCOMSourceTracking  
     (  
         IDX_NO      INT,  
         IDOrder     INT,  
         Seq         INT,  
         Serl        INT,  
         SubSerl     INT,  
         Qty         DECIMAL(19,5),  
         STDQty      DECIMAL(19,5),  
         Amt         DECIMAL(19,5),  
         VAT         DECIMAL(19,5)  
     )  
       
     CREATE TABLE #TMP_PROGRESSTABLE    
     (    
         IDOrder     INT,     
         TABLENAME   NVARCHAR(100)    
     )        
          
     CREATE TABLE #TCOMProgressTracking    
     (    
         IDX_NO      INT,     
         IDOrder     INT,     
         Seq         INT,    
         Serl        INT,     
         SubSerl     INT,    
         Qty         DECIMAL(19, 5),     
         StdQty      DECIMAL(19,5) ,     
         Amt         DECIMAL(19, 5),    
         VAT         DECIMAL(19,5)    
     )          
       
     CREATE TABLE #Result  
     (  
         IDX_NO              INT IDENTITY(1,1),  
         UMItemClassName     NVARCHAR(100) ,  
         ItemName            NVARCHAR(100) ,  
         Spec                NVARCHAR(100) ,  
         DelvCustName        NVARCHAR(100) ,  
         OrderQty            DECIMAL(19,5) ,  
         OrderPrice          DECIMAL(19,5) ,  
         OrderAmt            DECIMAL(19,5) ,  
         DelvInQty           DECIMAL(19,5) ,  
         DelvInPrice         DECIMAL(19,5) ,  
         DelvInAmt           DECIMAL(19,5) ,  
         DelvDate            NVARCHAR(8)   ,  
         PODate              NVARCHAR(8)   ,  
         OrderEmpName        NVARCHAR(100) ,  
         DelvInDate          NVARCHAR(8)   ,  
         SMPayTypeName       NVARCHAR(100) ,  
         DelvNo              NVARCHAR(30)  ,  
         TestEndDate         NVARCHAR(8)   ,  
         TestEmpName         NVARCHAR(100) ,  
         SMTestResultName    NVARCHAR(100) ,  
         UnitName            NVARCHAR(100) ,  
         Remark              NVARCHAR(1000),  
         ItemSeq             INT           ,  
         QCSeq               INT           ,  
         UMItemClass         INT           , 
         SMAQLLevelName      NVARCHAR(100) , 
         SMAQLPointName      NVARCHAR(100) , 
         AQLAcValue          DECIMAL(19,5) , 
         AQLReValue          DECIMAL(19,5) , 
         LotNo               NVARCHAR(100) ,  
         RealSampleQty       DECIMAL(19,5) , 
         BadSampleQty        DECIMAL(19,5) , 
         ItemNo              NVARCHAR(100) , 
         SMTestMethod        INT, 
         SMTestResult        INT 
     )  
       
     CREATE TABLE #QCTest  
     (  
         IDX_NO              INT           ,  
         UMQCTitleName       NVARCHAR(100) ,  
         TargetLevel         NVARCHAR(100) , 
         TestValue           NVARCHAR(100) , 
         TestingCond         NVARCHAR(100) , 
         SampleNo            NVARCHAR(100) , 
         UMQCTitleSeq        INT, 
     )  
       
       
     --  외주검사의뢰조회  
     IF @WorkingTag = 'OSP'  
     BEGIN        
         -- 외주납품 -> 외주발주  
         INSERT #TMP_SOURCETABLE( IDOrder, TableName )      
         SELECT 1, '_TPDOSPPOItem'    --_TCOMProgTable  
             
         EXEC _SCOMSourceTracking @CompanySeq, '_TPDOSPDelvItem', '#Temp', 'Seq', 'Serl', ''  
           
         INSERT INTO #Result  
         (  
             UMItemClassName     , ItemName            , Spec                , DelvCustName        , OrderQty            ,  
             OrderPrice          , OrderAmt            , DelvInQty           , DelvInPrice         , DelvInAmt           ,  
             DelvDate            , PODate              , OrderEmpName        , DelvInDate          , SMPayTypeName       ,  
             DelvNo              , TestEndDate         , TestEmpName         , UnitName            , Remark              ,  
             SMTestResultName    , ItemSeq             , QCSeq               , UMItemClass         , SMAQLLevelName      , 
             SMAQLPointName      , AQLAcValue          , AQLReValue          , LotNo               , RealSampleQty       , 
             BadSampleQty        , ItemNo              , SMTestMethod        , SMTestResult
         )  
         SELECT ISNULL(G.MinorName,'') AS UMItemClassName,  
                E.ItemName,  
                E.Spec,  
                I.CustName AS DelvCustName,  
                B.Qty AS OrderQty,  
                  
                J.Price AS OrderPrice,  
                J.CurAmt AS OrderAmt,  
                C.Qty AS DelvInQty,  
                C.Price AS DelvInPrice,  
                C.CurAmt AS DelvInAmt,  
                  
                J.DelvDate,  
                K.PODate,  
                L.EmpName AS OrderEmpName,  
                H.OSPDelvDate AS DelvInDate,  
                '' AS SMPayTypeName,  
                  
                A.DelvNo,  
                D.TestEndDate,  
                O.EmpName AS TestEmpName,  
                S.MinorName AS SMTestResultName,  
                U.UnitName,  
                  
                D.Memo1 AS Remark,  
                A.ItemSeq,  
                D.QCSeq,  
                G.MinorSeq,  
                V.MinorName AS SMAQLLevelName, 
                
                M.MinorName AS SMAQLPointName, 
                D.AQLAcValue, 
                D.AQLReValue, 
                C.LotNo,
                D.RealSampleQty, 
                
                D.BadSampleQty, 
                E.ItemNo, 
                D.SMTestMethod, 
                D.SMTestResult   
                 
           FROM #Temp AS A  
           LEFT OUTER JOIN #TCOMSourceTracking   AS B ON ( B.IDX_NO = A.IDX_NO AND B.IDOrder = 1 )  
           LEFT OUTER JOIN _TPDOSPDelvItem       AS C ON ( C.CompanySeq = @CompanySeq AND C.OSPDelvSeq = A.Seq AND C.OSPDelvSerl = A.Serl )  
           LEFT OUTER JOIN _TPDQCTestReport      AS D ON ( D.SourceType = '2' AND D.SourceSeq = A.Seq AND D.SourceSerl = A.Serl )  
           LEFT OUTER JOIN _TDAItem              AS E ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.ItemSeq )  
           LEFT OUTER JOIN _TDAItemClass         AS F ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = E.ItemSeq AND F.UMajorItemClass IN ( 2001, 2004 ) )  
           LEFT OUTER JOIN _TDAUMinor            AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = F.UMItemClass )  
           JOIN _TPDOSPDelv                      AS H ON ( H.CompanySeq = @CompanySeq AND H.OSPDelvSeq = A.Seq )  
           LEFT OUTER JOIN _TDACust              AS I ON ( I.CompanySeq = @CompanySeq AND I.CustSeq = H.CustSeq )  
           LEFT OUTER JOIN _TPDOSPPOItem         AS J ON ( J.CompanySeq = @CompanySeq AND J.OSPPOSeq = B.Seq AND J.OSPPOSerl = B.Serl )  
           LEFT OUTER JOIN _TPDOSPPO             AS K ON ( K.CompanySeq = @CompanySeq AND K.OSPPOSeq = B.Seq )  
           LEFT OUTER JOIN _TDAEmp               AS L ON ( L.CompanySeq = @CompanySeq AND L.EmpSeq = K.EmpSeq )  
           LEFT OUTER JOIN _TDAEmp               AS O ON ( O.CompanySeq = @CompanySeq AND O.EmpSeq = D.EmpSeq )  
           LEFT OUTER JOIN _TDASMinor            AS S ON ( S.CompanySeq = @CompanySeq AND S.MinorSeq = D.SMTestResult )  
           LEFT OUTER JOIN _TDAUnit              AS U ON ( U.CompanySeq = @CompanySeq AND U.UnitSeq = E.UnitSeq )  
           LEFT OUTER JOIN _TDASMinor            AS V ON ( V.CompanySeq = @CompanySeq AND V.MinorSeq = D.SMAQLLevel ) 
           LEFT OUTER JOIN _TDASMinor            AS M ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = D.AQLPoint ) 
          ORDER BY A.IDX_NO, A.ItemSeq  
        
        -- 등록된 검사항목  
        INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond, SampleNo, UMQCTitleSeq )  
        SELECT A.IDX_NO, Q.MinorName, R.TagetLevel, P.TestValue, R.TestingCond, P.SampleNo, Q.MinorSeq
          FROM #Result              AS A  
          JOIN _TPDQCTestReportSub  AS P ON ( P.CompanySeq = @CompanySeq AND P.QCSeq = A.QCSeq )  
          JOIN _TDAUMinor           AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = P.UMQCTitleSeq )   
          LEFT OUTER JOIN _TPDQAItemQcTitle    AS R ON ( R.CompanySeq = @CompanySeq AND R.UMQCTitleSeq = P.UMQCTitleSeq AND R.ItemSeq = A.ItemSeq AND R.SMQcKind = 6018002 )  
        
        -- 품목별 검사항목  
        INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond )  
        SELECT A.IDX_NO, C.MinorName, B.TagetLevel, '', B.TestingCond
          FROM #Result           AS A  
          LEFT OUTER JOIN _TPDQAItemQcTitle AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.SMQcKind = 6018002 )  
          JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.UMQCTitleSeq )  
         WHERE A.IDX_NO NOT IN ( SELECT DISTINCT ISNULL(IDX_NO,0) FROM #QCTest )  
          
          
        -- 품목소분류별 검사항목    
        INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond )  
        SELECT A.IDX_NO, C.MinorName, B.TargetLevel, '', B.TestingCondition
          FROM #Result               AS A  
          JOIN _TPDQAItemClassQCSub  AS B ON ( B.CompanySeq = @CompanySeq AND B.UMItemClass = A.UMItemClass AND B.IsPurQc = '1' )  
          LEFT OUTER JOIN _TDAUMinor AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.QCTitleSeq )  
         WHERE A.IDX_NO NOT IN ( SELECT DISTINCT ISNULL(IDX_NO,0) FROM #QCTest )  
          
          
        -- 품목중분류별 검사항목    
        INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond )  
        SELECT A.IDX_NO, C.MinorName, B.TargetLevel, '', B.TestingCondition
          FROM #Result               AS A  
          JOIN _TDAUMinorValue       AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMItemClass AND D.Serl = (CASE WHEN LEFT(UMItemClass,4) = 2001 THEN 1001 ELSE 2001 END) ) -- 중  
          JOIN _TPDQAItemClassQCSub  AS B ON ( B.CompanySeq = @CompanySeq AND B.UMItemClass = D.ValueSeq AND B.IsPurQc = '1' )  
          LEFT OUTER JOIN _TDAUMinor AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.QCTitleSeq )  
         WHERE A.IDX_NO NOT IN ( SELECT DISTINCT ISNULL(IDX_NO,0) FROM #QCTest )  
           
         
        -- 품목대분류별 검사항목    
        INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond )  
        SELECT A.IDX_NO, C.MinorName, B.TargetLevel, '', B.TestingCondition
          FROM #Result              AS A  
          JOIN _TDAUMinorValue      AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMItemClass AND D.Serl = (CASE WHEN LEFT(UMItemClass,4) = 2001 THEN 1001 ELSE 2001 END) ) -- 중  
          JOIN _TDAUMinorValue      AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.ValueSeq    AND E.Serl = 2001 ) -- 대  
          JOIN _TPDQAItemClassQCSub AS B ON ( B.CompanySeq = @CompanySeq AND B.UMItemClass = E.ValueSeq AND B.IsPurQc = '1' )  
          JOIN _TDAUMinor           AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.QCTitleSeq )  
         WHERE A.IDX_NO NOT IN ( SELECT DISTINCT ISNULL(IDX_NO,0) FROM #QCTest ) 
          
     END  
     -- 수입품검사의뢰조회, 수입품검사입력  
     ELSE IF @WorkingTag = 'BL'  
     BEGIN  
         -- 수입BL -> 구매발주(수입Order)  
         INSERT #TMP_SOURCETABLE( IDOrder, TableName )      
         SELECT 1, '_TPUORDPOItem'    --_TCOMProgTable  
             
         EXEC _SCOMSourceTracking @CompanySeq, '_TUIImpBLItem', '#Temp', 'Seq', 'Serl', ''  
           
         INSERT INTO #Result  
         (  
             UMItemClassName     , ItemName            , Spec                , DelvCustName        , OrderQty            ,  
             OrderPrice          , OrderAmt            , DelvInQty           , DelvInPrice         , DelvInAmt           ,  
             DelvDate            , PODate              , OrderEmpName        , DelvInDate          , SMPayTypeName       ,  
             DelvNo              , TestEndDate         , TestEmpName         , UnitName            , Remark              ,  
             SMTestResultName    , ItemSeq             , QCSeq               , UMItemClass         , SMAQLLevelName      , 
             SMAQLPointName      , AQLAcValue          , AQLReValue          , LotNo               , RealSampleQty       , 
             BadSampleQty        , ItemNo              , SMTestMethod        , SMTestResult 
         )  
         SELECT ISNULL(G.MinorName,'') AS UMItemClassName,  
                E.ItemName,  
                E.Spec,  
                I.CustName  AS DelvCustName,  
                B.Qty       AS OrderQty,  
                  
                J.Price     AS OrderPrice,  
                B.Amt       AS OrderAmt,  
                C.Qty       AS DelvInQty,  
                C.Price     AS DelvInPrice,  
                C.CurAmt    AS DelvInAmt,  
                  
                J.DelvDate,  
                K.PODate,  
                L.EmpName AS OrderEmpName,  
                H.BLDate AS DelvInDate,  
                N.MinorName AS SMPayTypeName,  
                  
                A.DelvNo,  
                D.TestEndDate,  
                O.EmpName AS TestEmpName,  
                U.UnitName,  
                D.Memo1 AS Remark,  
                  
                S.MinorName AS SMTestResultName,  
                A.ItemSeq,  
                D.QCSeq,  
                G.MinorSeq,  
                V.MinorName AS SMAQLLevelName, 
                
                M.MinorName AS SMAQLPointName, 
                D.AQLAcValue, 
                D.AQLReValue, 
                C.LotNo,
                D.RealSampleQty, 
                
                D.BadSampleQty, 
                E.ItemNo, 
                D.SMTestMethod, 
                D.SMTestResult 
                  
           FROM #Temp AS A  
           LEFT OUTER JOIN #TCOMSourceTracking   AS B ON ( B.IDX_NO = A.IDX_NO AND B.IDOrder = 1 )  
           LEFT OUTER JOIN _TUIImpBLItem         AS C ON ( C.CompanySeq = @CompanySeq AND C.BLSeq = A.Seq AND C.BLSerl = A.Serl )  
           LEFT OUTER JOIN _TPDQCTestReport      AS D ON ( D.SourceType = '10' AND D.SourceSeq = A.Seq AND D.SourceSerl = A.Serl )  
           LEFT OUTER JOIN _TDAItem              AS E ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.ItemSeq )  
           LEFT OUTER JOIN _TDAItemClass         AS F ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = E.ItemSeq AND F.UMajorItemClass IN ( 2001, 2004 ) )  
           LEFT OUTER JOIN _TDAUMinor            AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = F.UMItemClass )  
           JOIN _TUIImpBL                        AS H ON ( H.CompanySeq = @CompanySeq AND H.BLSeq = A.Seq )  
           LEFT OUTER JOIN _TDACust              AS I ON ( I.CompanySeq = @CompanySeq AND I.CustSeq = H.CustSeq )  
           LEFT OUTER JOIN _TPUORDPOItem         AS J ON ( J.CompanySeq = @CompanySeq AND J.POSeq = B.Seq AND J.POSerl = B.Serl )  
           LEFT OUTER JOIN _TPUORDPO             AS K ON ( K.CompanySeq = @CompanySeq AND K.POSeq = B.Seq )  
           LEFT OUTER JOIN _TDAEmp               AS L ON ( L.CompanySeq = @CompanySeq AND L.EmpSeq = K.EmpSeq )  
           LEFT OUTER JOIN _TDAUMinor            AS N ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = J.SMPayType )  
           LEFT OUTER JOIN _TDAEmp               AS O ON ( O.CompanySeq = @CompanySeq AND O.EmpSeq = D.EmpSeq )  
           LEFT OUTER JOIN _TDASMinor             AS S ON ( S.CompanySeq = @CompanySeq AND S.MinorSeq = D.SMTestResult )  
           LEFT OUTER JOIN _TDAUnit              AS U ON ( U.CompanySeq = @CompanySeq AND U.UnitSeq = E.UnitSeq ) 
           LEFT OUTER JOIN _TDASMinor            AS V ON ( V.CompanySeq = @CompanySeq AND V.MinorSeq = D.SMAQLLevel ) 
           LEFT OUTER JOIN _TDASMinor            AS M ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = D.AQLPoint )  
          ORDER BY A.IDX_NO, A.ItemSeq  
         
         -- 등록된 검사항목  
         INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond, SampleNo, UMQCTitleSeq )  
         SELECT A.IDX_NO, Q.MinorName, R.TagetLevel, P.TestValue, R.TestingCond, P.SampleNo, Q.MinorSeq
           FROM #Result              AS A  
           JOIN _TPDQCTestReportSub  AS P ON ( P.CompanySeq = @CompanySeq AND P.QCSeq = A.QCSeq )  
           JOIN _TDAUMinor           AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = P.UMQCTitleSeq )   
           LEFT OUTER JOIN _TPDQAItemQcTitle    AS R ON ( R.CompanySeq = @CompanySeq AND R.UMQCTitleSeq = P.UMQCTitleSeq AND R.ItemSeq = A.ItemSeq AND R.SMQcKind = 6018002 )  
         
         -- 품목별 검사항목  
         INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond )  
         SELECT A.IDX_NO, C.MinorName, B.TagetLevel, '', B.TestingCond
           FROM #Result           AS A  
           LEFT OUTER JOIN _TPDQAItemQcTitle AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.SMQcKind = 6018002 )  
           JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.UMQCTitleSeq )  
          WHERE A.IDX_NO NOT IN ( SELECT DISTINCT ISNULL(IDX_NO,0) FROM #QCTest )  
         
         -- 품목소분류별 검사항목    
         INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond )  
         SELECT A.IDX_NO, C.MinorName, B.TargetLevel, '', B.TestingCondition
           FROM #Result               AS A  
           JOIN _TPDQAItemClassQCSub  AS B ON ( B.CompanySeq = @CompanySeq AND B.UMItemClass = A.UMItemClass AND B.IsPurQc = '1' )  
           LEFT OUTER JOIN _TDAUMinor AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.QCTitleSeq )  
          WHERE A.IDX_NO NOT IN ( SELECT DISTINCT ISNULL(IDX_NO,0) FROM #QCTest )  
         
         -- 품목중분류별 검사항목    
         INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond )  
         SELECT A.IDX_NO, C.MinorName, B.TargetLevel, '', B.TestingCondition
           FROM #Result               AS A  
           JOIN _TDAUMinorValue       AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMItemClass AND D.Serl = (CASE WHEN LEFT(UMItemClass,4) = 2001 THEN 1001 ELSE 2001 END) ) -- 중  
           JOIN _TPDQAItemClassQCSub  AS B ON ( B.CompanySeq = @CompanySeq AND B.UMItemClass = D.ValueSeq AND B.IsPurQc = '1' )  
           LEFT OUTER JOIN _TDAUMinor AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.QCTitleSeq )  
          WHERE A.IDX_NO NOT IN ( SELECT DISTINCT ISNULL(IDX_NO,0) FROM #QCTest )  
         
         
         -- 품목대분류별 검사항목    
         INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond )  
         SELECT A.IDX_NO, C.MinorName, B.TargetLevel, '', B.TestingCondition
           FROM #Result              AS A  
           JOIN _TDAUMinorValue      AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMItemClass AND D.Serl = (CASE WHEN LEFT(UMItemClass,4) = 2001 THEN 1001 ELSE 2001 END) ) -- 중  
           JOIN _TDAUMinorValue      AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.ValueSeq    AND E.Serl = 2001 ) -- 대  
           JOIN _TPDQAItemClassQCSub AS B ON ( B.CompanySeq = @CompanySeq AND B.UMItemClass = E.ValueSeq AND B.IsPurQc = '1' )  
           JOIN _TDAUMinor           AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.QCTitleSeq )  
          WHERE A.IDX_NO NOT IN ( SELECT DISTINCT ISNULL(IDX_NO,0) FROM #QCTest ) 
     
     END  
     -- 구매검사의뢰조회,구매검사입력  
     ELSE  
     BEGIN  
         -- 구매납품 -> 구매발주  
      INSERT #TMP_SOURCETABLE( IDOrder, TableName )      
         SELECT 1, '_TPUORDPOItem'    --_TCOMProgTable  
             
         EXEC _SCOMSourceTracking @CompanySeq, '_TPUDelvItem', '#Temp', 'Seq', 'Serl', ''  
           
         INSERT INTO #Result  
         (  
             UMItemClassName     , ItemName            , Spec                , DelvCustName        , OrderQty            ,  
             OrderPrice          , OrderAmt            , DelvInQty           , DelvInPrice         , DelvInAmt           ,  
             DelvDate            , PODate              , OrderEmpName        , DelvInDate          , SMPayTypeName       ,  
             DelvNo              , TestEndDate         , TestEmpName         , UnitName            , Remark              ,  
             SMTestResultName    , ItemSeq             , QCSeq               , UMItemClass         , SMAQLLevelName      , 
             SMAQLPointName      , AQLAcValue          , AQLReValue          , LotNo               , RealSampleQty       , 
             BadSampleQty        , ItemNo              , SMTestMethod        , SMTestResult 
         )  
         SELECT ISNULL(G.MinorName,'') AS UMItemClassName,  
                E.ItemName,  
                E.Spec,  
                I.CustName  AS DelvCustName,  
                B.Qty       AS OrderQty,  
                  
                J.Price     AS OrderPrice,  
                B.Amt       AS OrderAmt,  
                C.Qty       AS DelvInQty,  
                C.Price     AS DelvInPrice,  
                C.CurAmt    AS DelvInAmt,  
                  
                J.DelvDate,  
                K.PODate,  
                L.EmpName AS OrderEmpName,  
                H.DelvDate AS DelvInDate,  
                N.MinorName AS SMPayTypeName,  
                  
                A.DelvNo,  
                D.TestEndDate,  
                O.EmpName AS TestEmpName,  
                U.UnitName,  
                D.Memo1 AS Remark,  
                  
                S.MinorName AS SMTestResultName,  
                A.ItemSeq,  
                D.QCSeq,  
                G.MinorSeq, 
                V.MinorName AS SMAQLLevelName, 
         
                M.MinorName AS SMAQLPointName, 
                D.AQLAcValue, 
                D.AQLReValue, 
                C.LotNo,
                D.RealSampleQty, 
                
                D.BadSampleQty, 
                E.ItemNo, 
                D.SMTestMethod, 
                D.SMTestResult 
         
           FROM #Temp AS A  
           LEFT OUTER JOIN #TCOMSourceTracking   AS B ON ( B.IDX_NO = A.IDX_NO AND B.IDOrder = 1 )  
           LEFT OUTER JOIN _TPUDelvItem           AS C ON ( C.CompanySeq = @CompanySeq AND C.DelvSeq = A.Seq AND C.DelvSerl = A.Serl )  
           LEFT OUTER JOIN _TPDQCTestReport      AS D ON ( D.SourceType = '1' AND D.SourceSeq = A.Seq AND D.SourceSerl = A.Serl )  
           LEFT OUTER JOIN _TDAItem              AS E ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.ItemSeq )  
           LEFT OUTER JOIN _TDAItemClass         AS F ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = E.ItemSeq AND F.UMajorItemClass IN ( 2001, 2004 ) )  
           LEFT OUTER JOIN _TDAUMinor            AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = F.UMItemClass )  
           JOIN _TPUDelv                         AS H ON ( H.CompanySeq = @CompanySeq AND H.DelvSeq = A.Seq )  
           LEFT OUTER JOIN _TDACust              AS I ON ( I.CompanySeq = @CompanySeq AND I.CustSeq = H.CustSeq )  
           LEFT OUTER JOIN _TPUORDPOItem         AS J ON ( J.CompanySeq = @CompanySeq AND J.POSeq = B.Seq AND J.POSerl = B.Serl )  
           LEFT OUTER JOIN _TPUORDPO             AS K ON ( K.CompanySeq = @CompanySeq AND K.POSeq = B.Seq )  
           LEFT OUTER JOIN _TDAEmp               AS L ON ( L.CompanySeq = @CompanySeq AND L.EmpSeq = K.EmpSeq )  
           LEFT OUTER JOIN _TDAUMinor            AS N ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = J.SMPayType )  
           LEFT OUTER JOIN _TDAEmp               AS O ON ( O.CompanySeq = @CompanySeq AND O.EmpSeq = D.EmpSeq )  
           LEFT OUTER JOIN _TDASMinor            AS S ON ( S.CompanySeq = @CompanySeq AND S.MinorSeq = D.SMTestResult )  
           LEFT OUTER JOIN _TDAUnit              AS U ON ( U.CompanySeq = @CompanySeq AND U.UnitSeq = E.UnitSeq )  
           LEFT OUTER JOIN _TDASMinor            AS V ON ( V.CompanySeq = @CompanySeq AND V.MinorSeq = D.SMAQLLevel ) 
           LEFT OUTER JOIN _TDASMinor            AS M ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = D.AQLPoint ) 
          ORDER BY A.IDX_NO, A.ItemSeq  
          -- 등록된 검사항목  
         INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond, SampleNo, UMQCTitleSeq  )  
         SELECT A.IDX_NO, Q.MinorName, R.TagetLevel, P.TestValue, R.TestingCond, P.SampleNo, Q.MinorSeq
           FROM #Result              AS A  
           JOIN _TPDQCTestReportSub  AS P ON ( P.CompanySeq = @CompanySeq AND P.QCSeq = A.QCSeq )  
           JOIN _TDAUMinor           AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = P.UMQCTitleSeq )   
           LEFT OUTER JOIN _TPDQAItemQcTitle    AS R ON ( R.CompanySeq = @CompanySeq AND R.UMQCTitleSeq = P.UMQCTitleSeq AND R.ItemSeq = A.ItemSeq AND R.SMQcKind = 6018002 )  
         
         -- 품목별 검사항목  
         INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond )  
         SELECT A.IDX_NO, C.MinorName, B.TagetLevel, '', B.TestingCond
           FROM #Result           AS A  
           LEFT OUTER JOIN _TPDQAItemQcTitle AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq AND B.SMQcKind = 6018002 )  
           JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.UMQCTitleSeq )  
          WHERE A.IDX_NO NOT IN ( SELECT DISTINCT ISNULL(IDX_NO,0) FROM #QCTest )  
         
         -- 품목소분류별 검사항목    
         INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond )  
         SELECT A.IDX_NO, C.MinorName, B.TargetLevel, '', B.TestingCondition
           FROM #Result               AS A  
           JOIN _TPDQAItemClassQCSub  AS B ON ( B.CompanySeq = @CompanySeq AND B.UMItemClass = A.UMItemClass AND B.IsPurQc = '1' )  
           LEFT OUTER JOIN _TDAUMinor AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.QCTitleSeq )  
          WHERE A.IDX_NO NOT IN ( SELECT DISTINCT ISNULL(IDX_NO,0) FROM #QCTest )  
         
         -- 품목중분류별 검사항목    
         INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond )  
         SELECT A.IDX_NO, C.MinorName, B.TargetLevel, '', B.TestingCondition
           FROM #Result               AS A  
           JOIN _TDAUMinorValue       AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMItemClass AND D.Serl = (CASE WHEN LEFT(UMItemClass,4) = 2001 THEN 1001 ELSE 2001 END) ) -- 중  
           JOIN _TPDQAItemClassQCSub  AS B ON ( B.CompanySeq = @CompanySeq AND B.UMItemClass = D.ValueSeq AND B.IsPurQc = '1' )  
           LEFT OUTER JOIN _TDAUMinor AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.QCTitleSeq )  
          WHERE A.IDX_NO NOT IN ( SELECT DISTINCT ISNULL(IDX_NO,0) FROM #QCTest )  
         
         -- 품목대분류별 검사항목    
         INSERT INTO #QCTest ( IDX_NO, UMQCTitleName, TargetLevel, TestValue, TestingCond )  
         SELECT A.IDX_NO, C.MinorName, B.TargetLevel, '', B.TestingCondition
           FROM #Result              AS A  
           JOIN _TDAUMinorValue      AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMItemClass AND D.Serl = (CASE WHEN LEFT(UMItemClass,4) = 2001 THEN 1001 ELSE 2001 END) ) -- 중  
           JOIN _TDAUMinorValue      AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.ValueSeq    AND E.Serl = 2001 ) -- 대  
           JOIN _TPDQAItemClassQCSub AS B ON ( B.CompanySeq = @CompanySeq AND B.UMItemClass = E.ValueSeq AND B.IsPurQc = '1' )  
           JOIN _TDAUMinor           AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.QCTitleSeq )  
          WHERE A.IDX_NO NOT IN ( SELECT DISTINCT ISNULL(IDX_NO,0) FROM #QCTest )  
     
     END 
     
     SELECT A.UMItemClassName , A.ItemName        ,  A.Spec            , A.DelvCustName    , A.OrderQty        ,   
            A.OrderPrice      , A.OrderAmt        , A.DelvInQty       , A.DelvInPrice     , A.DelvInAmt       ,   
            A.DelvDate        , A.PODate          , A.OrderEmpName    , A.DelvInDate      , A.SMPayTypeName   ,  
            A.DelvNo          , A.TestEndDate     , A.TestEmpName     , B.UMQCTitleName   , B.TargetLevel     ,  
            A.SMTestResultName, A.UnitName        , A.Remark          , B.TestingCond     , B.TestValue       , 
            A.SMAQLLevelName  , A.SMAQLPointName  , A.AQLAcValue      , A.AQLReValue      , A.LotNo           ,
            A.RealSampleQty   , A.BadSampleQty    , B.SampleNo        , A.ItemNo          , SMTestMethod      , 
            ROW_NUMBER() OVER (PARTITION BY B.UMQcTitleName ORDER BY B.SampleNo) AS SampleNoSort, SMTestResult, 
            CASE WHEN ROW_NUMBER() OVER (PARTITION BY B.UMQcTitleName ORDER BY B.SampleNo) = 1 THEN TestValue ELSE '' END AS x1, 
            CASE WHEN ROW_NUMBER() OVER (PARTITION BY B.UMQcTitleName ORDER BY B.SampleNo) = 2 THEN TestValue ELSE '' END AS x2, 
            CASE WHEN ROW_NUMBER() OVER (PARTITION BY B.UMQcTitleName ORDER BY B.SampleNo) = 3 THEN TestValue ELSE '' END AS x3, 
            CASE WHEN ROW_NUMBER() OVER (PARTITION BY B.UMQcTitleName ORDER BY B.SampleNo) = 4 THEN TestValue ELSE '' END AS x4, 
            CASE WHEN ROW_NUMBER() OVER (PARTITION BY B.UMQcTitleName ORDER BY B.SampleNo) >= 5 THEN (SELECT TestValue 
                                                                                                       FROM #QCTest 
                                                                                                      WHERE IDX_NO = A.IDX_NO 
                                                                                                        AND UMQCTitleSeq = B.UMQCTitleSeq
                                                                                                        AND SampleNo = (SELECT MAX(SampleNo) 
                                                                                                                          FROM #QCTest
                                                                                                                         WHERE IDX_NO = A.IDX_NO 
                                                                                                                           AND UMQCTitleSeq = B.UMQCTitleSeq
                                                                                                                       )
                                                                                                     ) ELSE '' END AS xn  
       INTO #TMP_Result
       FROM #Result AS A  
       LEFT OUTER JOIN #QCTest AS B ON ( B.IDX_NO = A.IDX_NO )  
      ORDER BY A.IDX_NO  
      
     SELECT UMItemClassName , ItemName        , Spec            , DelvCustName    , OrderQty        , 
            OrderPrice      , OrderAmt        , DelvInQty       , DelvInPrice     , DelvInAmt       , 
            DelvDate        , PODate          , OrderEmpName    , DelvInDate      , SMPayTypeName   , 
            DelvNo          , TestEndDate     , TestEmpName     , UMQCTitleName   , TargetLevel     , 
            SMTestResultName, UnitName        , Remark          , TestingCond     , MAX(TestValue) AS TestValue , 
            SMAQLLevelName  , SMAQLPointName  , AQLAcValue      , AQLReValue      , LotNo           ,
            RealSampleQty   , BadSampleQty    , MAX(SampleNo) AS SampleNo, ItemNo , SMTestMethod    ,
            MAX(SampleNoSort) AS SampleNoSort , SMTestResult , 
            MAX(x1) AS x1,MAX(x2) AS x2, MAX(x3) AS x3,MAX(x4) AS x4, MAX(xn) AS xn
       FROM #TMP_Result 
      GROUP BY UMItemClassName , ItemName        , Spec            , DelvCustName    , OrderQty        , 
                OrderPrice      , OrderAmt        , DelvInQty       , DelvInPrice     , DelvInAmt       , 
                DelvDate        , PODate          , OrderEmpName    , DelvInDate      , SMPayTypeName   , 
                DelvNo          , TestEndDate     , TestEmpName     ,  UMQCTitleName, TargetLevel     , 
                SMTestResultName, UnitName        , Remark          , TestingCond     , 
                SMAQLLevelName  , SMAQLPointName  , AQLAcValue      , AQLReValue      , LotNo           ,
                RealSampleQty   , BadSampleQty    , ItemNo          , SMTestMethod    , SMTestResult 
      
     RETURN
    GO
exec costel_SPDQCDelvItemResultPrint @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <DelvNo>201303130002</DelvNo>
    <DelvSerl>1</DelvSerl>
    <ItemSeq>26487</ItemSeq>
    <DelvSeq>133378</DelvSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019860,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1057
