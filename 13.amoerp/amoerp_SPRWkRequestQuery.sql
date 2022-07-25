
IF OBJECT_ID('amoerp_SPRWkRequestQuery')IS NOT NULL 
    DROP PROC amoerp_SPRWkRequestQuery
GO 
    
-- v2013.10.31 

-- 근태청구원_amoerp(조회) by이재천
CREATE PROC amoerp_SPRWkRequestQuery                
    @xmlDocument    NVARCHAR(MAX) , 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    DECLARE @docHandle      INT, 
            @ReqDateFr      NVARCHAR(8), 
            @ReqDateTo      NVARCHAR(8), 
            @DeptSeqQ       INT, 
            @EmpSeqQ        INT, 
            @WkItemSeq      INT, 
            @ProgStatusSeq  INT 

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

    SELECT @ReqDateFr     = ISNULL(ReqDateFr,''), 
           @ReqDateTo     = ISNULL(ReqDateTo,''), 
           @DeptSeqQ      = ISNULL(DeptSeqQ,0), 
           @EmpSeqQ       = ISNULL(EmpSeqQ,0), 
           @WkItemSeq     = ISNULL(WkItemSeq,0), 
           @ProgStatusSeq = ISNULL(ProgStatusSeq,0) 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      
      WITH (
            ReqDateFr      NVARCHAR(8),
            ReqDateTo      NVARCHAR(8),
            DeptSeqQ       INT, 
            EmpSeqQ        INT, 
            WkItemSeq      INT, 
            ProgStatusSeq  INT 
           )
    
    IF @ReqDateTo = '' SELECT @ReqDateTo = '99991231'
    
    DECLARE @Value NVARCHAR(100) 
    SELECT @Value = MinorValue FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = @ProgStatusSeq 
    
    SELECT B.DeptName, 
           F.MinorSeq AS ProgStatusSeq, 
           F.MinorName AS ProgStatusName, 
           A.WkItemSeq, 
           A.ReqSeq, 
           A.ReqDate, 
           D.WkItemName, 
           C.EmpName, 
           A.EmpSeq, 
           STUFF(STUFF(A.SDate,5,0,'-'),8,0,'-') + ' ' + STUFF(A.STime,3,0,':') + ' ~ ' + 
           STUFF(STUFF(A.EDate,5,0,'-'),8,0,'-') + ' ' + STUFF(A.ETime,3,0,':') AS DateFrTo, 
           A.DeptSeq, 
           A.Remark 
           
      FROM amoerp_TPRWkRequest   AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDADept   AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp    AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TPRWkItem AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WkItemSeq = A.WkItemSeq ) 
      LEFT OUTER JOIN amoerp_TPRWkRequest_Confirm AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CfmSeq = A.ReqSeq ) 
      LEFT OUTER JOIN _TDASMinor AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND MajorSeq = 1037 AND MinorValue = E.CfmCode ) 
      
     WHERE A.CompanySeq = @CompanySeq
       AND (A.ReqDate BETWEEN @ReqDateFr AND @ReqDateTo) 
       AND (@DeptSeqQ = 0 OR A.DeptSeq = @DeptSeqQ) 
       AND (@EmpSeqQ = 0 OR A.EmpSeq = @EmpSeqQ) 
       AND (@WkItemSeq = 0 OR A.WkItemSeq = @WkItemSeq) 
       AND (@ProgStatusSeq = 0 OR E.CfmCode = @Value)
    
    RETURN
GO