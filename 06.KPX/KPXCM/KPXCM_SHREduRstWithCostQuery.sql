  
IF OBJECT_ID('KPXCM_SHREduRstWithCostQuery') IS NOT NULL   
    DROP PROC KPXCM_SHREduRstWithCostQuery  
GO  
  
-- v2016.06.13  
  
-- 교육결과등록-조회 by 이재천   
CREATE PROC KPXCM_SHREduRstWithCostQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @DeptSeq        INT, 
            @EmpSeq         INT, 
            @EduDateTo      NCHAR(8), 
            @EduDateFr      NCHAR(8), 
            @RegEndDate     NCHAR(8), 
            @RegBegDate     NCHAR(8), 
            @EduCourseName  NVARCHAR(200), 
            @EduTypeSeq     INT

                  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DeptSeq        = ISNULL( DeptSeq        , 0 ), 
           @EmpSeq         = ISNULL( EmpSeq         , 0 ), 
           @EduDateTo      = ISNULL( EduDateTo      , '' ), 
           @EduDateFr      = ISNULL( EduDateFr      , '' ), 
           @RegEndDate     = ISNULL( RegEndDate     , '' ), 
           @RegBegDate     = ISNULL( RegBegDate     , '' ), 
           @EduCourseName  = ISNULL( EduCourseName  , '' ), 
           @EduTypeSeq     = ISNULL( EduTypeSeq     , 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            DeptSeq         INT,  
            EmpSeq          INT, 
            EduDateTo       NCHAR(8), 
            EduDateFr       NCHAR(8), 
            RegEndDate      NCHAR(8), 
            RegBegDate      NCHAR(8), 
            EduCourseName   NVARCHAR(200),
            EduTypeSeq      INT 
           )    
    
    IF @RegEndDate = '' SELECT @RegEndDate = '99991231'
    
    SELECT ISNULL(A.RstSeq       ,  0) AS RstSeq       , ISNULL(A.RstNo        , '') AS RstNo        ,    -- 학습결과코드    , 학습결과번호    ,  
           ISNULL(A.EmpSeq       ,  0) AS EmpSeq       , ISNULL(D.EmpName      , '') AS EmpName      ,    -- 사원코드        , 사원            ,  
           ISNULL(D.EmpID        , '') AS EmpID        , ISNULL(D.DeptSeq      ,  0) AS DeptSeq      ,    -- 사번            , 부서코드        ,  
           ISNULL(D.DeptName     , '') AS DeptName     , ISNULL(D.UMJpSeq      ,  0) AS UMJpSeq      ,    -- 부서            , 직위코드        ,  
           ISNULL(D.UMJpName     , '') AS UMJpName     , ISNULL(D.PosSeq       ,  0) AS PosSeq       ,    -- 직위            , 포지션코드      ,  
           ISNULL(D.PosName      , '') AS PosName      , ISNULL(A.EduClassSeq  ,  0) AS EduClassSeq  ,    -- 포지션          , 학습분류코드    ,  
           ISNULL(F.EduClassName , '') AS EduClassName , ISNULL(A.UMEduGrpType ,  0) AS UMEduGrpType ,    -- 학습분류        , 학습구분코드    ,  
           ISNULL(A.EtcCourseName, '') AS EtcCourseName, -- 기타학습과정명  
           ISNULL(A.EduCourseName, '') AS EduCourseName, ISNULL(A.EduBegDate   , '') AS EduBegDate   ,    -- 학습과정명      , 등록시작일      ,  
           ISNULL(A.EduEndDate   , '') AS EduEndDate   , ISNULL(A.EduDd        ,  0) AS EduDd        ,    -- 등록종료일      , 학습일수        ,  
           ISNULL(A.EduTm        ,  0) AS EduTm        , ISNULL(A.RegDate      , '') AS RegDate      ,    -- 학습시간        , 등록일          ,  
           ISNULL(C.CfmCode      , '') AS IsEnd        , ISNULL(A.EduTypeSeq   ,  0) AS EduTypeSeq   ,    -- 평가확정여부    , 학습형태코드    ,  
           ISNULL((SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.UMEduGrpType) , '') AS UMEduGrpTypeName ,    -- 학습구분,  
           ISNULL(H.EduTypeName  , '') AS EduTypeName  ,    -- 학습형태  
           ISNULL(A.SMInOutType  ,  0) AS SMInOutType  ,    -- 사내외구분코드  , 환급비용  
           ISNULL((SELECT MinorName FROM _TDASMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.SMInOutType)  , '') AS SMInOutTypeName,      -- 사내외구분  
           '3204001'                   AS EduRstType   , I.MinorName                 AS EduRstTypeName,   -- 결과구분-일반  
           ISNULL(A.EduPoint     ,  0) AS EduPoint      ,  -- 인정학점  
           ISNULL(A.RstSummary   , '') AS RstSummary    , ISNULL(A.RstRem       , '') AS RstRem,          -- 내용요약        , 비고  
           A.IsEI, 
           A.UMEduReport, 
           J.MinorName AS UMEduReportName, 
           A.UMEduCost, 
           K.MinorName AS UMEduCostName, 
           A.SMComplate, 
           L.MinorName AS SMComplateName, 
           A.RstCost, 
           A.ReturnAmt 
  
  
                                            -- 대상자 정보(사원, 부서 등)를 가져오기 위한 조인  
      FROM KPXCM_THREduPersRst AS A         JOIN _fnAdmEmpOrd(@CompanySeq, '')     AS D ON A.CompanySeq = @CompanySeq  
                                                                                       AND A.EmpSeq     = D.EmpSeq  
                                            -- 학습분류명을 가져오기 위한 조인  
                                            LEFT OUTER JOIN _fnHREduClass(@CompanySeq)  AS F ON A.CompanySeq  =@CompanySeq  
                                                                                            AND A.EduClassSeq = F.EduClassSeq    -- 학습분류코드가 같은부분  
                                            -- 확정여부를 가져오기 위한 조인  
                                            LEFT OUTER JOIN _THREduPersRst_Confirm   AS C ON A.CompanySeq = C.CompanySeq  
                                                                                        AND A.RstSeq     = C.CfmSeq   
                                            -- 학습형태를 가져오기 위한 조인  
                                            LEFT OUTER JOIN _THREduType             AS H ON A.CompanySeq = H.CompanySeq   
                                                                                        AND A.EduTypeSeq = H.EduTypeSeq  
                                            -- 결과구분  
                                            LEFT OUTER JOIN _TDAUMinor              AS I ON A.CompanySeq = I.CompanySeq   
                                                                                        AND I.MinorSeq ='3204001'  
                                            LEFT OUTER JOIN _TDAUMinor              AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = A.UMEduReport ) 
                                            LEFT OUTER JOIN _TDAUMinor              AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = A.UMEduCost ) 
                                            LEFT OUTER JOIN _TDASMinor              AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = A.SMComplate ) 

  
  
     WHERE  A.CompanySeq        = @CompanySeq  
       AND (@EduCourseName = '' OR ISNULL(A.EduCourseName, '') LIKE @EduCourseName + '%') 
       AND (@EduTypeSeq = 0 OR A.EduTypeSeq = @EduTypeSeq)
       AND (D.DeptSeq           = @DeptSeq          OR @DeptSeq         =  0)       -- 받아온 부서코드와  
       AND (D.EmpSeq            = @EmpSeq           OR @EmpSeq          =  0)       -- 받아온 사원코드와  
       AND (A.RegDate BETWEEN @RegBegDate AND @RegEndDate)       -- 받아온 일자 사이에 있는 조건  
       AND (A.EduBegDate BETWEEN @EduDateFr AND @EduDateTo)
       
    RETURN  
    go
    exec KPXCM_SHREduRstWithCostQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <RegBegDate>20160601</RegBegDate>
    <RegEndDate />
    <EduDateFr>20160601</EduDateFr>
    <EduDateTo>20160613</EduDateTo>
    <EduCourseName />
    <DeptSeq />
    <EmpSeq />
    <EduTypeSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037426,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030642