  
IF OBJECT_ID('KPX_SHREduRstListQuery') IS NOT NULL   
    DROP PROC KPX_SHREduRstListQuery  
GO  
  
-- v2015.04.14  
  
-- 교육이수현황-조회 by 이재천   
CREATE PROC KPX_SHREduRstListQuery  
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
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @StdYearFr      NCHAR(8), 
            @StdYearTo      NCHAR(8), 
            @UMEduGrpType   INT, 
            @EduClassSeq    INT, 
            @DeptSeq        INT, 
            @EmpSeq         INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYearFr        = ISNULL( StdYearFr   , '' ),  
           @StdYearTo        = ISNULL( StdYearTo   , '' ),  
           @UMEduGrpType     = ISNULL( UMEduGrpType, 0 ),  
           @EduClassSeq      = ISNULL( EduClassSeq , 0 ),  
           @DeptSeq          = ISNULL( DeptSeq     , 0 ),  
           @EmpSeq           = ISNULL( EmpSeq      , 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            StdYearFr      NCHAR(8),
            StdYearTo      NCHAR(8),
            UMEduGrpType   INT, 
            EduClassSeq    INT, 
            DeptSeq        INT, 
            EmpSeq         INT
          )    
    
    CREATE TABLE #PlanTable 
    (
        PlanKindName        NVARCHAR(100), 
        ExpectBegDate       NCHAR(8), 
        ExpectEndDate       NCHAR(8), 
        EmpName             NVARCHAR(100), 
        DeptName            NVARCHAR(100), 
        EmpID               NVARCHAR(100), 
        EduCourseName       NVARCHAR(100), 
        EduCenterName       NVARCHAR(100), 
        EmpSeq              INT, 
        EduCourseSeq        INT 
        
    )
    -- 계획데이터 
    INSERT INTO #PlanTable 
    (
        PlanKindName   ,        ExpectBegDate  ,        ExpectEndDate  ,        EmpName        ,        DeptName       ,
        EmpID          ,        EduCourseName  ,        EduCenterName  ,        EmpSeq         ,        EduCourseSeq    
    )
    SELECT B.MinorName, A.ExpectBegDate, A.ExpectEndDate, C.EmpName, C.DeptName, 
           C.EmpID, D.EduCourseName, H.MinorName, A.EmpSeq, A.EduCourseSeq
      FROM KPX_THREduPersPlanSheet      AS A
      LEFT OUTER JOIN _TDAUMinor        AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.PlanKindSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS C ON ( C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _THREduCourse     AS D ON ( D.CompanySeq = @CompanySeq AND D.EduCourseSeq = A.EduCourseSeq ) 
      LEFT OUTER JOIN _fnHREduClass(@CompanySeq) AS E ON ( E.EduClassSeq = D.EduClassSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.EduCenterSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND LEFT(A.ExpectBegDate,4) BETWEEN @StdYearFr AND @StdYearTo 
       AND ( @UMEduGrpType = 0 OR D.UMEduGrpType = @UMEduGrpType ) 
       AND ( @EduClassSeq = 0 OR E.EduClassSeq = @EduClassSeq ) 
       AND ( @DeptSeq = 0 OR C.DeptSeq = @DeptSeq ) 
       AND ( @EmpSeq = 0 OR C.EmpSeq = @EmpSeq ) 
    
    
    -- 결과 데이터 
    CREATE TABLE #ResultTable 
    (
        EmpSeq          INT, 
        EduCourseSeq   INT, 
        EduBegDate      NCHAR(8), 
        SMInOutTypeName NVARCHAR(100), 
        EduEndDate      NCHAR(8), 
        EduTm           DECIMAL(19,5), 
        IsEI            NCHAR(1), 
        SMComplateName  NVARCHAR(100), 
        RstCost         DECIMAL(19,5), 
        ReturnAmt       DECIMAL(19,5), 
        RstRem          NVARCHAR(200)
    )
    
    
    
    DECLARE @UMCostItem INT 
    
    -- 대표학습비용 가져오기    
    SELECT TOP 1 @UMCostItem =  MinorSeq    
      FROM _TDAUMinorValue    
     WHERE CompanySeq = @CompanySeq    
       AND MajorSeq = 3906    
       AND Serl = 1002    
       AND ValueText = 1 
    
    INSERT INTO #ResultTable 
    ( 
        EmpSeq, EduCourseSeq, EduBegDate, SMInOutTypeName, EduEndDate, 
        EduTm, IsEI, SMComplateName, RstCost, ReturnAmt, 
        RstRem
    )
    SELECT ISNULL(A.EmpSeq       ,  0) AS EmpSeq       ,
           ISNULL(A.EduCourseSeq ,  0) AS EduCourseSeq ,     --학습과정코드    ,    
           ISNULL(A.EduBegDate   , '') AS EduBegDate   , --등록시작일      ,    
           ISNULL((SELECT MinorName FROM _TDASMinor WHERE CompanySeq = A.CompanySeq AND MinorSeq = A.SMInOutType)  , '') AS SMInOutTypeName,      -- 사내외구분    
           ISNULL(A.EduEndDate   , '') AS EduEndDate   , -- 등록종료일
           ISNULL(A.EduTm        ,  0) AS EduTm        , -- 학습시간 
           K.IsEI,   
           L.MinorName AS SMComplateName, 
           ISNULL(B.RstCost      ,  0) AS RstCost      ,  -- 비용 
           ISNULL(B.ReturnAmt    ,  0) AS ReturnAmt    , -- 환급비용 
           ISNULL(A.RstRem       , '') AS RstRem  -- 비고 
      FROM _THREduPersRst                    AS A 
      LEFT OUTER JOIN _THREduPersRstCost     AS B ON ( B.CompanySeq = @CompanySeq AND A.RstSeq = B.RstSeq AND B.UMCostItem = @UMCostItem ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS C ON ( C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN KPX_THREduRstWithCost  AS K ON ( K.CompanySeq = @CompanySeq AND K.RstSeq = A.RstSeq )   
      LEFT OUTER JOIN _TDASMinor             AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = K.SMComplate )   
      LEFT OUTER JOIN _THREduCourse          AS D ON ( D.CompanySeq = @CompanySeq AND D.EduCourseSeq = A.EduCourseSeq ) 
      LEFT OUTER JOIN _fnHREduClass(@CompanySeq) AS E ON ( E.EduClassSeq = D.EduClassSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEFT(A.EduBegDate,4) BETWEEN @StdYearFr AND @StdYearTo 
       AND ( @UMEduGrpType = 0 OR D.UMEduGrpType = @UMEduGrpType ) 
       AND ( @EduClassSeq = 0 OR E.EduClassSeq = @EduClassSeq ) 
       AND ( @DeptSeq = 0 OR C.DeptSeq = @DeptSeq ) 
       AND ( @EmpSeq = 0 OR C.EmpSeq = @EmpSeq ) 
    
    -- 최종조회 
    SELECT A.PlanKindName, A.ExpectBegDate, A.ExpectEndDate, A.DeptName, A.EmpID, 
           A.EduCourseName, A.EduCenterName, B.EduBegDate, B.SMInOutTypeName, B.EduEndDate,
           B.EduTm, B.IsEI, B.SMComplateName, B.RstCost, B.ReturnAmt, 
           B.RstRem , A.EmpName, A.EduCourseSeq
      FROM #PlanTable AS A 
      LEFT OUTER JOIN #ResultTable AS B ON ( B.EmpSeq = A.EmpSeq AND B.EduBegDate = A.ExpectBegDate AND B.EduCourseSeq = A.EduCourseSeq ) 
    
    
    RETURN  
GO 

exec KPX_SHREduRstListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <StdYearTo>2015</StdYearTo>
    <StdYearFr>2015</StdYearFr>
    <UMEduGrpType />
    <EduClassSeq />
    <DeptSeq />
    <EmpSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1029098,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1024269 