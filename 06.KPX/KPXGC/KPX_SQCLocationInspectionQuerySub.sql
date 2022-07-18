  
IF OBJECT_ID('KPX_SQCLocationInspectionQuerySub') IS NOT NULL   
    DROP PROC KPX_SQCLocationInspectionQuerySub  
GO  
  
-- v2014.12.04  
  
-- 공정검사위치등록-Item조회 by 이재천   
CREATE PROC KPX_SQCLocationInspectionQuerySub  
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
            @PlantSeq   INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PlantSeq   = ISNULL( PlantSeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (PlantSeq   INT)    
    
    -- 최종조회   
    SELECT A.PlantSeq, 
           A.LocationSeq, 
           A.LocationName, 
           A.Sort, 
           A.Remark, 
           A.IsUse,           
           A.RegEmpSeq AS RegEmpSeq, 
           B.EmpName AS RegEmpName, -- 최초등록자 
           CONVERT(NCHAR(8),A.RegDateTime,112) AS RegDateTime, -- 최초등록일
           CASE WHEN A.RegDateTime = A.LastDateTime THEN 0 ELSE C.EmpSeq END AS LastUserSeq, 
           CASE WHEN A.RegDateTime = A.LastDateTime THEN '' ELSE D.EmpName END AS LastUserName, 
           CASE WHEN A.RegDateTime = A.LastDateTime THEN CONVERT(NCHAR(8),'') ELSE CONVERT(NCHAR(8),A.LastDateTime,112) END AS LastDateTime 
    
      FROM KPX_TQCPlantLocation AS A 
      LEFT OUTER JOIN _TDAEmp   AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.RegEmpSeq ) 
      LEFT OUTER JOIN _TCAUser  AS C ON ( C.CompanySeq = @CompanySeq AND C.UserSeq = A.LastUserSeq ) 
      LEFT OUTER JOIN _TDAEmp   AS D ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = C.EmpSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.PlantSeq = @PlantSeq 
    
    RETURN  
GO 
exec KPX_SQCLocationInspectionQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <PlantSeq>8</PlantSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026462,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022168