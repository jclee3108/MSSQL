    
IF OBJECT_ID('yw_SLGASProcPlanQury') IS NOT NULL
    DROP PROC yw_SLGASProcPlanQury
GO

-- v2013.07.17

-- AS처리방안_YW(조회) by이재천
CREATE PROC yw_SLGASProcPlanQury                
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    DECLARE @docHandle              INT,
		    @ImsiEmp                INT ,
            @RootEmp                INT ,
            @UMResponsTypeName      NVARCHAR(200) ,
            @ASRegDateTo            NCHAR(8) ,
            @CustName               NVARCHAR(100) ,
            @UMASMClass             INT ,
            @UMBadMKindName         NVARCHAR(200) ,
            @ASRegDateFr            NCHAR(8) ,
            @CustItemName           NVARCHAR(100) ,
            @ItemNo                 NVARCHAR(100) ,
            @ResponsDept            NVARCHAR(100) ,
            @SMLocalType            INT ,
            @UMBadTypeName          NVARCHAR(200) ,
            @UMIsEndName            NVARCHAR(200) ,
            @ASRegNo                NVARCHAR(20) ,
            @ItemName               NVARCHAR(200) ,
            @ResponsProc            NVARCHAR(100) ,
            @UMLastDecision         INT ,
            @UMLotMagnitude         INT ,
            @UMProbleSemiItemName   NVARCHAR(200) ,
            @UMProbleSubItemName    NVARCHAR(200) ,
            @UMBadMagnitude         INT,
            @UMMkind                INT ,
            @OrderItemNo            NVARCHAR(100) ,
            @ProcDept               INT ,
            @UMBadLKindName         NVARCHAR(200) ,
            @UMMtypeName            NVARCHAR(200)  
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

	SELECT @ImsiEmp                = ImsiEmp ,
           @RootEmp                = RootEmp ,
           @UMResponsTypeName      = UMResponsTypeName ,
           @ASRegDateTo            = ASRegDateTo ,
           @CustName               = CustName ,
           @UMASMClass             = UMASMClass ,
           @UMBadMKindName         = UMBadMKindName ,
           @ASRegDateFr            = ASRegDateFr ,
           @CustItemName           = CustItemName ,
           @ItemNo                 = ItemNo ,
           @ResponsDept            = ResponsDept ,
           @SMLocalType            = SMLocalType ,
           @UMBadTypeName          = UMBadTypeName ,
           @UMIsEndName            = UMIsEndName ,
           @ASRegNo                = ASRegNo ,
           @ItemName               = ItemName ,
           @ResponsProc            = ResponsProc ,
           @UMLastDecision         = UMLastDecision ,
           @UMLotMagnitude         = UMLotMagnitude ,
           @UMProbleSemiItemName   = UMProbleSemiItemName ,
           @UMProbleSubItemName    = UMProbleSubItemName ,
           @UMBadMagnitude         = UMBadMagnitude ,
           @UMMkind                = UMMkind ,
           @OrderItemNo            = OrderItemNo ,
           @ProcDept               = ProcDept ,
           @UMBadLKindName         = UMBadLKindName ,
           @UMMtypeName            = UMMtypeName 
           
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (
            ImsiEmp                 INT ,
            RootEmp                 INT ,
            UMResponsTypeName       NVARCHAR(200) ,
            ASRegDateTo             NCHAR(8) ,
            CustName                NVARCHAR(100) ,
            UMASMClass              INT ,
            UMBadMKindName          NVARCHAR(200) ,
            ASRegDateFr             NCHAR(8) ,
            CustItemName            NVARCHAR(100) ,
            ItemNo                  NVARCHAR(100) ,
            ResponsDept             NVARCHAR(100) ,
            SMLocalType             INT ,
            UMBadTypeName           NVARCHAR(200) ,
            UMIsEndName             NVARCHAR(200) ,
            ASRegNo                 NVARCHAR(20) ,
            ItemName                NVARCHAR(200) ,
            ResponsProc             NVARCHAR(100) ,
            UMLastDecision          INT ,
            UMLotMagnitude          INT ,
            UMProbleSemiItemName    NVARCHAR(200) ,
            UMProbleSubItemName     NVARCHAR(200) ,
            UMBadMagnitude          INT ,
            UMMkind                 INT ,
            OrderItemNo             NVARCHAR(100) ,
            ProcDept                INT ,
            UMBadLKindName          NVARCHAR(200) ,
            UMMtypeName             NVARCHAR(200)
           )
    
    SELECT A.ASRegSeq , -- AS접수코드
           B.EndDate , -- 종결일자
           B.ImsiEmp , -- 임시담당
           B.RootEmp , -- 근본담당
           B.RootProc , -- 근본대책
           A.UMFindKind , -- 발견시점코드
           F.MinorName AS UMFindKindName , -- 발견시점
           B.UMIsEnd , -- 종결여부코드
           G.MinorName AS UMIsEndName , -- 종결여부
           B.UMResponsType , -- 귀책구분코드
           H.MinorName AS UMResponsTypeName , -- 귀책구분
           E.CustItemName , -- 업체품명
           B.ResponsDept , -- 귀책부서
           A.SMLocalType , -- 지역구분코드
           I.MinorName AS SMLocalTypeName , -- 지역구분
           B.UMBadType , -- 불량구분코드
           J.MinorName AS UMBadTypeName , -- 불량구분
           B.UMLastDecision , -- 최종판단코드
           K.MinorName AS UMLastDecisionName , -- 최종판단
           B.UMProbleSemiItem , -- 문제부품코드
           L.MinorName AS UMProbleSemiItemName , -- 문제부품
           A.ASRegDate , -- 접수일자
           C.CustName , -- 고객사명
           A.CustSeq , -- 고객사코드
           A.UMASMClass , -- AS중분류코드
           M.MinorName AS UMASMClassName , -- AS중분류
           B.UMBadMagnitude , -- 결점심각도코드
           N.MinorName AS UMBadMagnitudeName ,  -- 결점심각도
           B.UMBadMKind , -- 불량유형(중)코드
           O.MinorName AS UMBadMKindName , -- 불량유형(중)
           A.ASState , -- 현상
           A.BadRate , -- 불량율
           A.OutDate , -- 출고일자
           B.ProbleCause , -- 발생원인
           B.UMMkind , -- 4M분류코드
           P.MinorName AS UMMkindName , -- 4M분류
           A.ASRegNo , -- AS접수번호
           A.CustRemark , -- 고객요구사항
           A.IsStop ,  -- 중단
           B.RootDate , -- 근본기한
           A.TargetQty , -- 대상수량
           B.UMLotMagnitude , -- Lot심각도코드
           Q.MinorName AS UMLotMagnitudeName , -- Lot심각도
           B.UMProbleSubItem , -- 문제반제품코드
           R.MinorName AS UMProbleSubItemName , -- 문제반제품
           B.ImsiProc , -- 임시조치
           D.ItemName , -- 제품명
           D.ItemNo ,  -- 제품번호
           B.ProcDept , -- 처리부서코드
           W.DeptName AS ProcDeptName , -- 처리부서
           B.ResponsProc , -- 귀책공정
           B.ImsiDate , -- 임시기한
           S.EmpName AS ImsiEmpName , -- 임시담당
           T.EmpName AS RootEmpName , -- 근본담당
           X.CfmCode AS Confirm , -- 확정
           A.CustEmpName , -- 고객사담당자
           A.ItemSeq , -- 제품코드
           A.OrderItemNo , -- 주문관리번호
           B.UMBadLKind , -- 불량유형(대)코드
           U.MinorName AS UMBadLKindName , -- 불량유형(대)
           B.UMMtype , -- 4M내용코드
           V.MinorName AS UMMtypeName -- 4M내용
    
      FROM YW_TLGASReg        AS A WITH (NOLOCK) 
      LEFT OUTER JOIN YW_TLGASProcPlan AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ASRegSeq = A.ASRegSeq ) 
      LEFT OUTER JOIN _TDACust     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAItem     AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TSLCustItem AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.CustSeq AND E.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUMinor   AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.MinorSeq = A.UMFindKind ) 
      LEFT OUTER JOIN _TDAUMinor   AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = B.UMIsEnd ) 
      LEFT OUTER JOIN _TDAUMinor   AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = B.UMResponsType ) 
      LEFT OUTER JOIN _TDASMinor   AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = A.SMLocalType ) 
      LEFT OUTER JOIN _TDAUMinor   AS J WITH(NOLOCK) ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = B.UMBadType ) 
      LEFT OUTER JOIN _TDAUMinor   AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = B.UMLastDecision ) 
      LEFT OUTER JOIN _TDAUMinor   AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = B.UMProbleSemiItem ) 
      LEFT OUTER JOIN _TDAUMinor   AS M WITH(NOLOCK) ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = A.UMASMClass ) 
      LEFT OUTER JOIN _TDAUMinor   AS N WITH(NOLOCK) ON ( N.CompanySeq = @CompanySeq AND N.MinorSeq = B.UMBadMagnitude ) 
      LEFT OUTER JOIN _TDAUMinor   AS O WITH(NOLOCK) ON ( O.CompanySeq = @CompanySeq AND O.MinorSeq = B.UMBadMKind ) 
      LEFT OUTER JOIN _TDAUMinor   AS P WITH(NOLOCK) ON ( P.CompanySeq = @CompanySeq AND P.MinorSeq = B.UMMkind ) 
      LEFT OUTER JOIN _TDAUMinor   AS Q WITH(NOLOCK) ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = B.UMLotMagnitude ) 
      LEFT OUTER JOIN _TDAUMinor   AS R WITH(NOLOCK) ON ( R.CompanySeq = @CompanySeq AND R.MinorSeq = B.UMProbleSubItem ) 
      LEFT OUTER JOIN _TDAEmp      AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND S.EmpSeq = B.ImsiEmp ) 
      LEFT OUTER JOIN _TDAEmp      AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND T.EmpSeq = B.RootEmp ) 
      LEFT OUTER JOIN _TDAUMinor   AS U WITH(NOLOCK) ON ( U.CompanySeq = @CompanySeq AND U.MinorSeq = B.UMBadLKind ) 
      LEFT OUTER JOIN _TDAUMinor   AS V WITH(NOLOCK) ON ( V.CompanySeq = @CompanySeq AND V.MinorSeq = B.UMMtype ) 
      LEFT OUTER JOIN _TDADept     AS W WITH(NOLOCK) ON ( W.CompanySeq = @CompanySeq AND W.DeptSeq = B.ProcDept ) 
      LEFT OUTER JOIN YW_TLGASReg_Confirm AS X WITH(NOLOCK) ON ( X.CompanySeq = @CompanySeq AND X.CfmSeq = A.ASRegSeq ) 
      
     WHERE A.CompanySeq = @CompanySeq
       AND A.ASRegDate BETWEEN @ASRegDateFr AND @ASRegDateTo
       AND (@SMLocalType = 0 OR A.SMLocalType = @SMLocalType)
       AND (@UMASMClass = 0 OR A.UMASMClass = @UMASMClass)
       AND (@OrderItemNo = '' OR A.OrderItemNo LIKE @OrderItemNo + '%')          
       AND (@CustName = '' OR C.CustName LIKE @CustName + '%')
       AND (@CustItemName = '' OR E.CustItemName LIKE @CustItemName + '%') 
       AND (@ItemNo = '' OR D.ItemNo LIKE @ItemNo + '%')               
       AND (@ItemName = '' OR D.ItemName LIKE @ItemName + '%')
       AND (@UMLastDecision = 0 OR B.UMLastDecision = @UMLastDecision)
       AND (@UMLotMagnitude = 0 OR B.UMLotMagnitude = @UMLotMagnitude)
       AND (@UMBadMagnitude = 0 OR B.UMBadMagnitude = @UMBadMagnitude)
       AND (@ASRegNo = '' OR A.ASRegNo = @ASRegNo) 
       AND (@UMMkind = 0 OR B.UMMkind = @UMMkind) 
       AND (@UMMtypeName = '' OR V.MinorName LIKE @UMMtypeName + '%') 
       AND (@UMProbleSubItemName = '' OR R.MinorName LIKE @UMProbleSubItemName + '%') 
       AND (@UMProbleSemiItemName = '' OR L.MinorName LIKE @UMProbleSemiItemName + '%') 
       AND (@UMBadLKindName = '' OR U.MinorName LIKE @UMBadLKindName + '%') 
       AND (@UMBadMKindName = '' OR O.MinorName LIKE @UMBadMKindName + '%') 
       AND (@UMBadTypeName = '' OR J.MinorName LIKE @UMBadTypeName + '%') 
       AND (@ResponsProc = '' OR B.ResponsProc LIKE @ResponsProc + '%') 
       AND (@ResponsDept = '' OR B.ResponsDept LIKE @ResponsDept + '%') 
       AND (@ProcDept = 0 OR B.ProcDept = @ProcDept) 
       AND (@ImsiEmp = 0 OR B.ImsiEmp = @ImsiEmp) 
       AND (@RootEmp = 0 OR B.RootEmp = @RootEmp) 
       AND (@UMIsEndName = '' OR G.MinorName LIKE @UMIsEndName + '%') 
       AND (@UMResponsTypeName = '' OR H.MinorName LIKE @UMResponsTypeName + '%') 
       AND X.CfmCode = '1'

    RETURN
GO
exec yw_SLGASProcPlanQury @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ASRegDateFr>20130701</ASRegDateFr>
    <ASRegDateTo>20130717</ASRegDateTo>
    <SMLocalType />
    <UMASMClass />
    <OrderItemNo />
    <CustName />
    <CustItemName />
    <ItemNo />
    <ItemName />
    <UMLastDecision />
    <UMLotMagnitude />
    <UMBadMagnitude />
    <ASRegNo />
    <UMMkind />
    <UMMtypeName />
    <UMProbleSubItemName />
    <UMProbleSemiItemName />
    <UMBadLKindName />
    <UMBadMKindName />
    <UMResponsTypeName />
    <ResponsProc />
    <ResponsDept />
    <ProcDept />
    <ImsiEmp />
    <RootEmp />
    <UMIsEndName />
    <UMBadTypeName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016629,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014197