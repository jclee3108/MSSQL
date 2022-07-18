
IF OBJECT_ID('yw_SPDSFCWorkStartListQuery') IS NOT NULL 
    DROP PROC yw_SPDSFCWorkStartListQuery
GO 

-- v2014.02.14 

-- 공정개시현황_YW(조회) by이재천
CREATE PROC dbo.yw_SPDSFCWorkStartListQuery                
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    DECLARE @docHandle          INT, 
            @WorkOrderNo        NVARCHAR(200), 
            @WorkStartDateFr    NCHAR(8), 
            @EmpSeq             INT, 
            @WorkStartDateTo    NCHAR(8), 
            @WorkCenterName     NVARCHAR(200) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @WorkOrderNo     = ISNULL(WorkOrderNo,'')        ,
           @WorkStartDateFr = ISNULL(WorkStartDateFr,'')    ,
           @EmpSeq          = ISNULL(EmpSeq,0)              ,
           @WorkStartDateTo = ISNULL(WorkStartDateTo,'')    ,
           @WorkCenterName  = ISNULL(WorkCenterName,'')     
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags) 
    
      WITH (
            WorkOrderNo     NVARCHAR(200), 
            WorkStartDateFr NCHAR(8), 
            EmpSeq          INT, 
            WorkStartDateTo NCHAR(8), 
            WorkCenterName  NVARCHAR(200) 
           )
    
    IF @WorkStartDateTo = '' SELECT @WorkStartDateTo = '99991231'
    
    SELECT D.WorkCenterName, 
           A.WorkCenterSeq, 
           LEFT(A.StartTime,8) AS WorkDate, 
           B.EmpName, 
           A.EmpSeq, 
           A.StartTime AS WorkStartTime, 
           A.EndTime AS WorkEndTime, 
           A.WorkOrderSeq, 
           A.WorkOrderSerl, 
           A.Serl, 
           C.WorkOrderNo 
    
      FROM YW_TPDSFCWorkStart            AS A 
      LEFT OUTER JOIN _TDAEmp            AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TPDSFCWorkOrder   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.WorkOrderSeq = A.WorkOrderSeq AND C.WorkOrderSerl = A.WorkOrderSerl ) 
      LEFT OUTER JOIN _TPDBaseWorkCenter AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkCenterSeq = A.WorkCenterSeq ) 
    
     WHERE A.CompanySeq = @CompanySeq
       AND ( @WorkOrderNo = '' OR C.WorkOrderNo LIKE @WorkOrderNo + '%' ) 
       AND LEFT(A.StartTime,8) BETWEEN @WorkStartDateFr AND @WorkStartDateTo
       AND ( @EmpSeq = 0 OR A.EmpSeq = @EmpSeq ) 
       AND ( @WorkCenterName = '' OR D.WorkCenterName LIKE @WorkCenterName + '%' )
    
    RETURN
    