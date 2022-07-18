IF OBJECT_ID('KPXLS_SQCCOAPrintQuerySub') IS NOT NULL 
    DROP PROC KPXLS_SQCCOAPrintQuerySub
GO 

-- v2015.12.08 
  
-- 시험성적서발행(COA)- SS1 조회 by 이재천   
CREATE PROC KPXLS_SQCCOAPrintQuerySub
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @docHandle      INT,  
            -- 조회조건       
            @ItemSeq        INT, 
            @LotNo          NVARCHAR(100), 
            @QCType         INT,
            @SMSourceType	INT,
            @CustSeq        INT,
			@BaseDate		NCHAR(8)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ItemSeq = ISNULL( ItemSeq, 0 ),  
           @LotNo   = ISNULL( LotNo, '' ), 
           @QCType  = ISNULL( QCType, 0 ),
           @SMSourceType = ISNULL(SMSourceType,0),
           @CustSeq     = ISNULL(CustSeq, 0)
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ItemSeq			INT, 
            LotNo			NVARCHAR(100), 
            QCType			INT,
            SMSourceType	INT,
            CustSeq         INT
           )
	SELECT @BaseDate = CONVERT(NCHAR(8), GETDATE(), 112)
    
    SELECT CASE WHEN ISNULL(A.QCType ,0) = 0 THEN B.QCType ELSE A.QCType END AS QCType,
           A.ItemSeq,
           A.LotNo,
           C.OutTestItemName, 
           D.QAAnalysisTypeName AS AnalysisName, 
           MAX(B.QCSerl) AS QcSerl,
           A.QcSeq
      INTO #Result	 
      FROM KPX_TQCTestResult                   AS A
      LEFT OUTER JOIN KPX_TQCTestResultItem				    AS B ON ( B.CompanySeq = @CompanySeq 
																AND B.QCSeq = A.QCSeq AND (B.SMTestResult <>'6035004' OR IsSpecial = '1')
																    )
				 JOIN( SELECT AA.CompanySeq,AA.LotNo,AA.ItemSeq ,BB.TestItemSeq, BB.QAAnalysisType, BB.QCUnit, BB.QCType, MAX(AA.ReqSeq) AS ReqSeq
						FROM KPX_TQCTestResult AS AA
						LEFT OUTER JOIN KPX_TQCTestResultItem AS BB WITH(NOLOCK) ON AA.CompanySeq = BB.CompanySeq
																			    AND AA.QCSeq	  = BB.QCSeq AND (BB.SMTestResult <> '6035004' OR IsSpecial = '1')
						GROUP BY AA.CompanySeq, AA.LotNo, AA.ItemSeq, BB.TestItemSeq, BB.QAAnalysisType, BB.QCUnit, BB.QCType
					 ) B1 ON A.CompanySeq     = B1.CompanySeq
						 AND A.LotNo		  = B1.LotNo
						 AND A.ItemSeq		  = B1.ItemSeq  
						 AND B.TestItemSeq    = B1.TestItemSeq
						 AND B.QAAnalysisType = B1.QAAnalysisType
						 AND B.QCUnit		  = B1.QCUnit
						 AND B.QCType		  = B1.QCType
						 AND A.ReqSeq	  = B1.ReqSeq
      LEFT OUTER JOIN KPX_TQCQATestItems                    AS C ON ( C.CompanySeq = @CompanySeq AND C.TestItemSeq = B.TestItemSeq ) 
      LEFT OUTER JOIN KPX_TQCQAAnalysisType                 AS D ON ( D.CompanySeq = @CompanySeq AND D.QAAnalysisType = B.QAAnalysisType ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCUnit                AS E ON ( E.CompanySeq = @CompanySeq AND E.QCUnit = B.QCUnit ) 
	  JOIN KPX_TQCQAQualityAssuranceSpec         AS G ON ( G.CompanySeq = @CompanySeq 
                                                                  AND G.ItemSeq = A.ItemSeq 
                                                                  AND G.QCType = CASE WHEN ISNULL(A.QCType ,0) = 0 THEN B.QCType ELSE A.QCType END
                                                                  AND G.TestItemSeq = B.TestItemSeq 
                                                                  AND G.QAAnalysisType = D.QAAnalysisType
                                                                  AND G.QCUnit = E.QCUnit 
                                                                  AND G.IsProd = '1' 
                                                                  AND G.CustSeq = @CustSeq
																  AND @BaseDate BETWEEN G.SDate AND G.EDate
      )
      LEFT OUTER JOIN KPX_TQCQAProcessQCType				AS H ON ( A.CompanySeq = H.CompanySeq
      															 AND  A.QCtype	   = H.QCType)
     
     WHERE A.CompanySeq = @CompanySeq
     --AND   B.SMSourceType IN (1000522001, 1000522002)
     AND   A.ItemSeq	= @ItemSeq
     AND   A.LotNo		= @LotNo
     AND   CASE WHEN ISNULL(A.QCType,0) = 0 THEN B.QCType
                ELSE A.QCType END 		= @QCType
     GROUP BY   CASE WHEN ISNULL(A.QCType ,0) = 0 THEN B.QCType ELSE A.QCType END ,
            A.ItemSeq,
            A.LotNo,
            C.OutTestItemName, 
            D.QAAnalysisTypeName,
            A.QcSeq            
    
    SELECT CASE WHEN ISNULL(A.QCType ,0) = 0 THEN B.QCType ELSE A.QCType END AS QCType,
           A.ItemSeq,
           A.LotNo,
           C.InTestItemName, 
           C.OutTestItemName, 
           D.QAAnalysisTypeName AS AnalysisName, 
           G.LowerLimit, 
           G.UpperLimit, 
           E.QCUnitName, 
           B.TestValue, 
           H.Remark AS Remark ,
           
           G.Remark AS Remark2, --20150311 검사데이터비고에서 보증규격비고로 변경
           '1' AS KindSeq,
		   B.SMSourceType,
		   CONVERT(NCHAR(8),J.CfmDateTime,112) AS TestResultDate
		   ,B.QCSeq
		   ,B.QCSerl
		   ,A.LastDateTime
		   ,M.CreateDate
		   ,I.ValiDate AS ReTestDate
		   ,C.TestItemGroupName 
      FROM KPX_TQCTestResult                   AS A
                 JOIN #Result                            AS RE ON A.CompanySeq = @CompanySeq AND A.QcSeq = RE.QcSeq
      LEFT OUTER JOIN KPX_TQCTestResultItem        AS B ON ( B.CompanySeq = @CompanySeq 
                                                         AND B.QCSeq = A.QCSeq AND (B.SMTestResult <>'6035004' OR IsSpecial = '1')
                                                         AND B.QCSerl = RE.QCSerl 
                                                           )
                 JOIN( SELECT AA.CompanySeq,AA.LotNo,AA.ItemSeq ,BB.TestItemSeq, BB.QAAnalysisType, BB.QCUnit, BB.QCType, MAX(AA.ReqSeq) AS ReqSeq
						FROM KPX_TQCTestResult AS AA
						LEFT OUTER JOIN KPX_TQCTestResultItem AS BB WITH(NOLOCK) ON AA.CompanySeq = BB.CompanySeq
																			    AND AA.QCSeq	  = BB.QCSeq AND (BB.SMTestResult <> '6035004' OR IsSpecial = '1')
						GROUP BY AA.CompanySeq, AA.LotNo, AA.ItemSeq, BB.TestItemSeq, BB.QAAnalysisType, BB.QCUnit, BB.QCType
					 ) B1 ON A.CompanySeq     = B1.CompanySeq
						 AND A.LotNo		  = B1.LotNo
						 AND A.ItemSeq		  = B1.ItemSeq  
						 AND B.TestItemSeq    = B1.TestItemSeq
						 AND B.QAAnalysisType = B1.QAAnalysisType
						 AND B.QCUnit		  = B1.QCUnit
						 AND B.QCType		  = B1.QCType
						 AND A.ReqSeq	  = B1.ReqSeq
      LEFT OUTER JOIN KPX_TQCQATestItems                    AS C ON ( C.CompanySeq = @CompanySeq AND C.TestItemSeq = B.TestItemSeq ) 
      LEFT OUTER JOIN KPX_TQCQAAnalysisType                 AS D ON ( D.CompanySeq = @CompanySeq AND D.QAAnalysisType = B.QAAnalysisType ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCUnit                AS E ON ( E.CompanySeq = @CompanySeq AND E.QCUnit = B.QCUnit ) 
	  JOIN KPX_TQCQAQualityAssuranceSpec         AS G ON ( G.CompanySeq = @CompanySeq 
                                                                  AND G.ItemSeq = A.ItemSeq 
                                                                  AND G.QCType = CASE WHEN ISNULL(A.QCType ,0) = 0 THEN B.QCType ELSE A.QCType END
                                                                  AND G.TestItemSeq = B.TestItemSeq 
                                                                  AND G.QAAnalysisType = D.QAAnalysisType
                                                                  AND G.QCUnit = E.QCUnit 
                                                                  AND G.IsProd = '1' 
                                                                  AND G.CustSeq = @CustSeq
																  AND @BaseDate BETWEEN G.SDate AND G.EDate
      )
      LEFT OUTER JOIN KPX_TQCQAProcessQCType				AS H ON ( A.CompanySeq = H.CompanySeq
      															 AND  A.QCtype	   = H.QCType)
      LEFT OUTER JOIN _TLGLotMaster                         AS I ON ( I.CompanySeq = @CompanySeq AND I.LotNo = @LotNo AND I.ItemSeq = @ItemSeq ) 
      LEFT OUTER JOIN KPXLS_TQCTestResultAdd                AS J ON ( J.CompanySeq = @CompanySeq AND J.QCSeq = A.QCSeq ) 
      LEFT OUTER JOIN KPXLS_TQCRequestItem                  AS K ON ( K.CompanySeq = @CompanySeq AND K.ReqSeq = A.ReqSeq AND K.ReqSerl = A.ReqSerl ) 
      LEFT OUTER JOIN KPXLS_TQCRequestItemAdd_PDB           AS M ON ( M.CompanySeq = @CompanySeq AND M.ReqSeq = K.ReqSeq AND M.ReqSerl = K.ReqSerl ) 
     
     WHERE A.CompanySeq = @CompanySeq
       AND A.ItemSeq	= @ItemSeq
       AND A.LotNo		= @LotNo
       AND CASE WHEN ISNULL(A.QCType,0) = 0 THEN B.QCType
                ELSE A.QCType END 		= @QCType
     ORDER BY G.Sort, G.Serl 
    
    RETURN  
    
GO


