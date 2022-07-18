IF OBJECT_ID('KPXCM_SQCProcessInspectionListQuery') IS NOT NULL 
    DROP PROC KPXCM_SQCProcessInspectionListQuery
GO 

-- v2016.05.09 

-- KPXCM용 by이재천 
/************************************************************
 설  명 - 데이터-공정검사조회(배치식)_KPX : 조회
 작성일 - 20141224
 작성자 - 박상준
 수정자 - 
************************************************************/
CREATE PROC KPXCM_SQCProcessInspectionListQuery
    @xmlDocument   NVARCHAR(MAX) ,            
    @xmlFlags      INT = 0,            
    @ServiceSeq    INT = 0,            
    @WorkingTag    NVARCHAR(10)= '',                  
    @CompanySeq    INT = 1,            
    @LanguageSeq   INT = 1,            
    @UserSeq       INT = 0,            
    @PgmSeq        INT = 0       

AS        
    
    DECLARE @docHandle			INT,
            @TestDateFr         NCHAR(8),
            @TestDateTo         NCHAR(8),
            @ReqDateFr          NCHAR(8),
            @ReqDateTo          NCHAR(8),
            @ItemName           NVARCHAR(100),
            @ItemNo             NVARCHAR(100),
            @LotNo              NVARCHAR(100),
            @RegiDateFr         NCHAR(8),
            @RegiDateTo         NCHAR(8)

 
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

    SELECT  @TestDateFr         = ISNULL(TestDateFr , ''),
            @TestDateTo         = ISNULL(TestDateTo , ''),
            @ReqDateFr          = ISNULL(ReqDateFr  , ''),
            @ReqDateTo          = ISNULL(ReqDateTo  , ''),
            @ItemName           = ISNULL(ItemName   , ''),
            @ItemNo             = ISNULL(ItemNo     , ''),
            @LotNo              = ISNULL(LotNo      , ''),
            @RegiDateFr         = ISNULL(@RegiDateFr, ''),
            @RegiDateTo         = ISNULL(@RegiDateTo, '')
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (
            TestDateFr          NCHAR(8),
            TestDateTo          NCHAR(8),
            ReqDateFr           NCHAR(8),
            ReqDateTo           NCHAR(8),
            ItemName            NVARCHAR(100),
            ItemNo              NVARCHAR(100),
            LotNo               NVARCHAR(100),
            RegiDateFr          NCHAR(8),
            RegiDateTo          NCHAR(8)
           )
    
    IF @TestDateFr ='' BEGIN SELECT @TestDateFr='19900101' END
    IF @TestDateTo ='' BEGIN SELECT @TestDateTo='99991230' END
    IF @ReqDateFr ='' BEGIN SELECT @ReqDateFr='19900101' END
    IF @ReqDateTo ='' BEGIN SELECT @ReqDateTo='99991230' END
    IF @RegiDateFr ='' BEGIN SELECT @RegiDateFr='19900101' END
    IF @RegiDateTo ='' BEGIN SELECT @RegiDateTo='99991230' END


	 -- Mapping정보에서 포장작업지시, 출하검사의뢰에 사용할 가상 워크센터 가져온다.
    DECLARE @WorkCenterSeq1   INT,
            @WorkCenterSeq2   INT,
            @WorkCenterName1   NVARCHAR(100),
            @WorkCenterName2   NVARCHAR(100)

    -- 포장작업지시
    SELECT @WorkCenterSeq1 = EnvValue
      FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq =12 AND EnvSerl = 1

    SELECT @WorkCenterName1  = WorkCenterName
      FROM _TPDBaseWorkCenter
     WHERE 1=1
       AND CompanySeq = @CompanySeq
       AND WorkCenterSeq = @WorkCenterSeq1

    -- 출하검사의뢰
    SELECT @WorkCenterSeq2 = EnvValue
      FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq =14 AND EnvSerl = 1

    SELECT @WorkCenterName2  = WorkCenterName
      FROM _TPDBaseWorkCenter
     WHERE 1=1
       AND CompanySeq = @CompanySeq
       AND WorkCenterSeq = @WorkCenterSeq2

    
    SELECT  DISTINCT 
            B.SMSourceType
	        ,M.MinorName AS SMSourceTypeName
            ,A.QCSeq
            --,B.QCSerl
            ,A.QCNo
            ,A.ItemSeq
            ,H.ItemName
            ,H.ItemNo
            ,A.LotNo
			,Q.ReqDate
			,CASE WHEN R.SMSourceType = 1000522006 THEN @WorkCenterSeq1
                  WHEN R.SMSourceType = 1000522005 THEN @WorkCenterSeq2
                  ELSE V.WorkCenterSeq
            END AS WorkCenterSeq
           ,CASE WHEN R.SMSourceType = 1000522006 THEN @WorkCenterName1
                 WHEN R.SMSourceType = 1000522005 THEN @WorkCenterName2
                 ELSE W.WorkCenterName
           END AS WorkCenterName, 
           A.QCNo AS QCNO, 
           Q.ReqNo 
      FROM KPX_TQCTestResult AS A LEFT OUTER JOIN KPX_TQCTestResultItem AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq
		    											                                 AND A.QCSeq		= B.QCSeq
                                  LEFT OUTER JOIN _TDAItem              AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq
													                                     AND A.ItemSeq	 = H.ItemSeq
                                  LEFT OUTER JOIN _TDASMinor            AS M WITH(NOLOCK) ON B.CompanySeq = M.CompanySeq
			                          										             AND B.SMSourceType	 = M.MinorSeq
                                  LEFT OUTER JOIN KPX_TQCTestRequest    AS Q WITH(NOLOCK) ON Q.CompanySeq = A.CompanySeq
                                                                                         AND Q.ReqSeq = A.ReqSeq
								  LEFT OUTER JOIN KPX_TQCTestRequestItem AS R WITH(NOLOCK) ON A.CompanySeq = R.CompanySeq
																						 AND  A.ReqSeq	   = R.ReqSeq
								  LEFT OUTER JOIN _TPDSFCWorkOrder        AS V WITH(NOLOCK) ON R.CompanySeq   = V.CompanySeq
																						   AND R.SourceSeq    = V.WorkOrderSeq
                                                                                           AND R.SMSourceType = 1000522004
								  LEFT OUTER JOIN _TPDBaseWorkCenter      AS W WITH(NOLOCK) ON W.CompanySeq   = @CompanySeq
																						   AND W.WorkCenterSeq = V.WorkCenterSeq
												
     WHERE A.CompanySeq = @CompanySeq
       --AND (B.TestDate BETWEEN @TestDateFr AND @TestDateTo)
       AND (Q.ReqDate BETWEEN @ReqDateFr AND @ReqDateTo)
       --AND (CONVERT(NCHAR(8), B.RegDate, 112) BETWEEN @RegiDateFr AND @RegiDateTo)
       AND (H.ItemName LIKE @ItemName+'%')
       AND (H.ItemNo	LIKE @ItemNo  +'%')
       AND (A.LotNo	LIKE @LotNo   +'%')
       AND M.MinorSeq IN (SELECT MinorSeq FROM _TDASMinorValue WHERE CompanySeq = @CompanySeq AND MajorSeq = 1000522 AND Serl = 1000002 AND ValueText = '1')  
  --GROUP BY B.SMSourceType
	 --     ,M.MinorName
  --        ,A.QCSeq
  --        ,A.QCNo
  --        ,A.ItemSeq
  --        ,H.ItemName
  --        ,H.ItemNo
  --        ,A.LotNo
		--  ,Q.ReqDate
		--  ,CASE WHEN R.SMSourceType = 1000522006 THEN @WorkCenterSeq1
  --                WHEN R.SMSourceType = 1000522005 THEN @WorkCenterSeq2
  --                ELSE V.WorkCenterSeq
  --          END 
		--  ,CASE WHEN R.SMSourceType = 1000522006 THEN @WorkCenterName1
  --               WHEN R.SMSourceType = 1000522005 THEN @WorkCenterName2
  --               ELSE W.WorkCenterName
  --       END , 
  --       A.QCNo, 
  --       Q.ReqNo 
  





RETURN

GO


