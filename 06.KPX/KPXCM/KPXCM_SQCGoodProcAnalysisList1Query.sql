IF OBJECT_ID('KPXCM_SQCGoodProcAnalysisList1Query') IS NOT NULL 
    DROP PROC KPXCM_SQCGoodProcAnalysisList1Query
GO 

/************************************************************
 설  명 - 데이터-제품공정분석표(1)_KPXCM : 조회
 작성일 - 20150820
 작성자 - 박상준
 수정자 - 20151021
************************************************************/

CREATE PROC KPXCM_SQCGoodProcAnalysisList1Query
    @xmlDocument   NVARCHAR(MAX) ,
    @xmlFlags      INT = 0,
    @ServiceSeq    INT = 0,
    @WorkingTag    NVARCHAR(10)= '',
    @CompanySeq    INT = 1,
    @LanguageSeq   INT = 1,
    @UserSeq       INT = 0,
    @PgmSeq        INT = 0

AS

    DECLARE @docHandle      INT,
            @ItemNo           NVARCHAR(100) ,
            @LotNo            NVARCHAR(100) ,
            @BizUnitName      NVARCHAR(100) ,
            @QCType           INT ,
            @TestDateTo       NCHAR(8) ,
            @TestItemSeq      INT ,
            @BizUnit          INT ,
            @TestDateFr       NCHAR(8) ,
            @QCTypeName       NVARCHAR(100) ,
            @TestItemName     NVARCHAR(100) ,
            @ItemSeq          INT ,
            @ItemName         NVARCHAR(100)

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument

    SELECT @ItemNo           = ItemNo            ,
            @LotNo            = LotNo             ,
            @BizUnitName      = BizUnitName       ,
            @QCType           = QCType            ,
            @TestDateTo       = TestDateTo        ,
            @TestItemSeq      = TestItemSeq       ,
            @BizUnit          = BizUnit           ,
            @TestDateFr       = TestDateFr        ,
            @QCTypeName       = QCTypeName        ,
            @TestItemName     = TestItemName      ,
            @ItemSeq          = ItemSeq           ,
            @ItemName         = ItemName
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (ItemNo            NVARCHAR(100) ,
            LotNo             NVARCHAR(100) ,
            BizUnitName       NVARCHAR(100) ,
            QCType            INT ,
            TestDateTo        NCHAR(8) ,
            TestItemSeq       INT ,
            BizUnit           INT ,
            TestDateFr        NCHAR(8) ,
            QCTypeName        NVARCHAR(100) ,
            TestItemName      NVARCHAR(100) ,
            ItemSeq           INT ,
            ItemName          NVARCHAR(100) )



    SELECT
            ROW_NUMBER() OVER(PARTITION BY AA.ItemSeq, B.ItemName, AA.LotNo,  A.QCType, A.TestItemSeq ORDER BY AA.ItemSeq, B.ItemName, AA.LotNo, A.TestDate, A.QCType, C.Sort, A.LastDateTime,A.QCSeq, A.QCSerl ) AS TestCnt
           ,ISNULL(A.QCSeq              , 0)        AS QCSeq
           ,ISNULL(A.QCSerl             , 0)        AS QCSerl
           ,ISNULL(A3.ItemSeq           , 0)        AS ItemSeq
           ,ISNULL(B.ItemName           ,'')        AS ItemName
           ,ISNULL(B.ItemNo             ,'')        AS ItemNo
           --,ISNULL(AA.LotNo             ,'')        AS LotNo
           ,CASE WHEN ISNULL(H.WorkCond3,'')='' THEN ISNULL(AA.LotNo ,'') ELSE ISNULL(H.WorkCond3,'') END       AS LotNo
           ,ISNULL(A.TestDate           ,'')        AS TestDate
           ,ISNULL(A.TestItemSeq        , 0)        AS TestItemSeq
           ,ISNULL(C.InTestItemName     ,'')        AS InTestItemName
           ,ISNULL(A.TestValue          ,'')        AS TestValue
           ,ISNULL(J.SMInPutType        , 0)        AS SMInPutType
           ,ISNULL(CASE WHEN ISNULL(A.QCType,0) = 0 THEN AA.QCType ELSE A.QCType END,0)      AS QCType
           ,ISNULL(D.QCTypeName         ,'')        AS QCTypeName
           ,ISNULL(A.Remark             ,'')        AS Remark
           ,ISNULL(A.SMTestResult       , 0)        AS SMTestResult
           ,ISNULL(F.MinorName          ,'')        AS SMTestResultName
           ,ISNULL(E.MinorName          ,'')        AS UMTestGroupName
           ,ISNULL(CASE WHEN J.SMInputType = 1018002 THEN J.UpperLimit
                        WHEN J.SMInputType = 1018001 AND J.LowerLimit != '' AND J.UpperLimit  =''  THEN J.LowerLimit
                        WHEN J.SMInputType = 1018001 AND J.LowerLimit  = '' AND J.UpperLimit !=''  THEN J.UpperLimit+'Max'
                        WHEN J.SMInputType = 1018001 AND J.LowerLimit != '' AND J.UpperLimit !=''  THEN J.LowerLimit+'~'+J.UpperLimit END,'') AS TestSpec
           ,ISNULL(C.Sort               , 0)        AS Sort
           ,ISNULL(A.LastDateTime       ,'')        AS LastDateTime
           ,ISNULL(CONVERT(NCHAR(8),A.RegDate,112),'') AS RegDate
           ,ISNULL(A.RegEmpSeq          , 0)        AS RegEmpSeq
           ,ISNULL(G.EmpName            ,'')        AS RegEmpName
           ,SUBSTRING(CONVERT(NCHAR(5),A.RegDate,108),1,2)+SUBSTRING(CONVERT(NCHAR(5),A.RegDate,108),4,2) AS RegTime
           ,ISNULL(AA.QCSpeRemark       ,'')        AS QCSpeRemark

      INTO #Result
      FROM KPX_TQCTestResultItem AS A
           LEFT OUTER JOIN KPX_TQCTestResult     AS AA WITH(NOLOCK) ON A.CompanySeq     = AA.CompanySeq
                                                                   AND A.QCSeq          = AA.QCSeq
           LEFT OUTER JOIN KPX_TQCTestRequest    AS A2 WITH(NOLOCK) ON AA.CompanySeq    = A2.CompanySeq
                                                                   AND AA.ReqSeq        = A2.ReqSeq
           OUTER APPLY (
                        SELECT MAX(ItemSeq) AS ItemSeq 
                            FROM KPX_TQCTestRequestItem
                            WHERE CompanySeq = @CompanySeq 
                            AND ReqSeq = A2.ReqSeq 
                       ) AS A3
           LEFT OUTER JOIN _TDAItem              AS B  WITH(NOLOCK) ON B.CompanySeq     = @CompanySeq
                                                                   AND B.ItemSEq        = A3.ItemSeq
           LEFT OUTER JOIN KPX_TQCQASpec         AS J WITH(NOLOCK)  ON A.CompanySeq     = J.CompanySeq
                                                                   AND J.QCType         = CASE WHEN ISNULL(A.QCType,0) = 0 THEN AA.QCType ELSE A.QCType END
                                                                   AND A.QAAnalysisType = J.QAAnalysisType
                                                                   AND A.TestItemSeq    = J.TestItemSeq
                                                                   AND A.QCUnit         = J.QCUnit
                                                                   AND AA.ItemSeq       = J.ItemSeq
                                                                   AND A2.ReqDate       BETWEEN J.SDate AND J.EDate
           LEFT OUTER JOIN KPX_TQCQATestItems     AS C WITH(NOLOCK) ON C.CompanySeq     = A.CompanySeq
                                                                   AND C.TestItemSeq    = A.TestItemSeq
           LEFT OUTER JOIN KPX_TQCQAProcessQCType AS D WITH(NOLOCK) ON D.CompanySeq     = A.CompanySeq
                                                                   AND D.QCType         = CASE WHEN ISNULL(A.QCType,0) = 0 THEN AA.QCType ELSE A.QCType END
           LEFT OUTER JOIN _TDAUMinor      AS E WITH(NOLOCK) ON  E.CompanySeq = A.CompanySeq
                                                            AND  E.MinorSeq   = A.UMTestGroup
           LEFT OUTER JOIN _TDASMinor      AS F WITH(NOLOCK) ON  F.CompanySeq = A.CompanySeq
                                                            AND  F.MinorSeq   = A.SMTestResult
           LEFT OUTER JOIN _TDAEmp         AS G WITH(NOLOCK) ON A.CompanySeq  = G.CompanySeq    
                                                            AND A.RegEmpSeq   = G.EmpSeq    
           LEFT OUTER JOIN _TPDSFCWorkOrder     AS H WITH(NOLOCK)ON H.CompanySeq    = @CompanySeq
                                                                AND H.WorkOrderSeq  = A.SourceSeq
                                                                AND H.WorkOrderSerl = A.SourceSerl
                                                                AND A.SMSourceType  = 1000522004
    WHERE A.CompanySeq  = @CompanySeq
      AND (ISNULL(@ItemSeq,0) = 0 OR A3.ItemSeq   = @ItemSeq)
      AND (ISNULL(@LotNo,'') = '' OR  AA.LotNo  LIKE @LotNo+'%')
      AND (ISNULL(@QCType,0) = 0 OR (CASE WHEN ISNULL(A.QCType,0) = 0 THEN AA.QCType ELSE A.QCType END)   = @QcType)
      AND (A.TestDate BETWEEN @TestDateFr AND @TestDateTo)
      AND (ISNULL(@TestItemSeq,0) = 0 OR  A.TestItemSeq = @TestItemSeq)
      AND (ISNULL(@BizUnit,0) = 0 OR A2.BizUnit = @BizUnit)



    SELECT  A.*
           ,TestCnt         AS TestCnt2
           ,A.ItemSeq       AS ItemSeq2
           ,A.LotNo         AS LotNo2
           ,@TestDateFr     AS TestDateFr
           ,@TestDateTo     AS TestDateTo
           ,CONVERT(NCHAR(8),GETDATE(),112)     AS PrintDate

           ,@UserSeq        AS LoginUserSeq
           ,(SELECT UserName FROM _TCAUser  WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq)      AS LoginUserName
           ,(SELECT UserID FROM _TCAUser  WHERE CompanySeq = @CompanySeq AND UserSeq = @UserSeq)      AS LoginUserID
    FROM #Result AS A
    ORDER BY A.ItemNo, A.LotNo, A.QCType,A.Sort, A.TestCnt, A.TestItemSeq, A.TestDate, A.LastDateTime

RETURN

GO


exec KPXCM_SQCGoodProcAnalysisList1Query @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BizUnit>1</BizUnit>
    <BizUnitName>우레탄부문</BizUnitName>
    <TestDateFr>20160801</TestDateFr>
    <TestDateTo>20160909</TestDateTo>
    <ItemSeq>298</ItemSeq>
    <ItemName>KONIX FA-717G</ItemName>
    <ItemNo>1113017179</ItemNo>
    <LotNo>1608T221</LotNo>
    <QCType />
    <QCTypeName />
    <TestItemSeq />
    <InTestItemName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031501,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1026231