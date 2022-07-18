  
IF OBJECT_ID('KPX_SPRWKEmpOTGroupAppQuery') IS NOT NULL   
    DROP PROC KPX_SPRWKEmpOTGroupAppQuery  
GO  
  
-- v2014.12.17  
  
-- OT일괄신청-조회 by 이재천   
CREATE PROC KPX_SPRWKEmpOTGroupAppQuery  
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
            @GroupAppSeq    INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @GroupAppSeq   = ISNULL( GroupAppSeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (GroupAppSeq   INT)    
    
    -- 최종조회   
    SELECT A.BaseDate, 
           A.GroupAppNo, 
           A.GroupAppSeq 
      FROM KPX_TPRWKEmpOTGroupApp AS A 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.GroupAppSeq = @GroupAppSeq 
      
    RETURN  
GO 
exec KPX_SPRWKEmpOTGroupAppQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <GroupAppSeq>1</GroupAppSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026866,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022469