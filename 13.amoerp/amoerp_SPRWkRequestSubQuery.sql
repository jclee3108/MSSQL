
IF OBJECT_ID('amoerp_SPRWkRequestSubQuery')IS NOT NULL 
    DROP PROC amoerp_SPRWkRequestSubQuery
GO 
    
-- v2013.10.31 

-- 근태청구원_amoerp(서브조회) by이재천
CREATE PROC amoerp_SPRWkRequestSubQuery                
    @xmlDocument    NVARCHAR(MAX) , 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    DECLARE @docHandle  INT, 
            @ReqSeq     INT

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

    SELECT @ReqSeq = ISNULL(ReqSeq,0) 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      
      WITH (ReqSeq  INT)
    
    SELECT A.ReqSeq, 
           A.DeptSeq AS DeptSeqS, 
           A.EmpSeq AS EmpSeqS, 
           A.WkItemSeq, 
           A.ReqDate, 
           A.SDate, 
           A.STime, 
           A.EDate, 
           A.ETime, 
           A.Remark, 
           B.EmpName AS EmpNameS, 
           C.DeptName AS DeptNameS 
           
      FROM amoerp_TPRWkRequest AS A WITH(NOLOCK) 
      LEFT OUTER JOIN _TDAEmp  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
      
     WHERE A.CompanySeq = @CompanySeq
       AND @ReqSeq = A.ReqSeq 
    
    RETURN
GO
exec amoerp_SPRWkRequestSubQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <ReqSeq>1</ReqSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1018965,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016043