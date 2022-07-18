  
IF OBJECT_ID('KPXLS_SQCInQCIResultIsCfm') IS NOT NULL   
    DROP PROC KPXLS_SQCInQCIResultIsCfm  
GO  
  
-- v2015.12.17 
  
-- (검사품)수입검사등록 - 검사승인 by 이재천 
CREATE PROC KPXLS_SQCInQCIResultIsCfm  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @QCSeq      INT, 
            @IsCfm      NCHAR(1) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @QCSeq   = ISNULL( QCSeq, 0 ), 
           @IsCfm   = ISNULL( IsCfm, '0' ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            QCSeq   INT, 
            IsCfm   NCHAR(1) 
           )    
    
    UPDATE A 
       SET IsCfm = CASE WHEN @IsCfm = '0' THEN '1' ELSE '0' END, 
           CfmEmpSeq = CASE WHEN @IsCfm = '0' THEN (SELECT EmpSeq FROM _TCAUser WHERE UserSeq = @UserSeq) ELSE 0 END, 
           CfmDateTime = CASE WHEN @IsCfm = '0' THEN GETDATE() ELSE NULL END 
      FROM KPXLS_TQCTestResultAdd AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.QCSeq = @QCSeq 
    
    
    SELECT A.CfmEmpSeq, B.EmpName AS CfmEmpName, A.IsCfm, CASE WHEN IsCfm = '1' THEN A.CfmDateTime ELSE '' END AS CfmDate 
      FROM KPXLS_TQCTestResultAdd   AS A 
      LEFT OUTER JOIN _TDAEmp       AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.CfmEmpSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.QCSeq = @QCSeq 
    
    
    RETURN 
go
begin tran 
exec KPXLS_SQCInQCIResultIsCfm @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <IsCfm>0</IsCfm>
    <QCSeq>188</QCSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033819,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027993
rollback

