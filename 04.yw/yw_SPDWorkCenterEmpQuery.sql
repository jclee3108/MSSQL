  
IF OBJECT_ID('yw_SPDWorkCenterEmpQuery') IS NOT NULL   
    DROP PROC yw_SPDWorkCenterEmpQuery
GO 
    
-- v2013.07.19  
  
-- 워크센터별작업자등록_YW(조회) by이재천   
CREATE PROC yw_SPDWorkCenterEmpQuery
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    DECLARE @docHandle      INT, 
            @WorkCenterName NVARCHAR(200) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @WorkCenterName = ISNULL( WorkCenterName, '' ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (WorkCenterName NVARCHAR(200))    
      
    -- 최종조회   
    SELECT WorkCenterSeq, WorkCenterName 
      FROM _TPDBaseWorkCenter AS A WITH(NOLOCK)   
     WHERE A.CompanySeq = @CompanySeq  
       AND (@WorkCenterName = '' OR A.WorkCenterName LIKE @WorkCenterName + '%')
      
    RETURN 
Go
exec yw_SPDWorkCenterEmpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <WorkCenterName>가공</WorkCenterName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016735,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014291