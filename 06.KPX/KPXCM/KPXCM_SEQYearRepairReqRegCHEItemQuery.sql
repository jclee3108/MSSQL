  
IF OBJECT_ID('KPXCM_SEQYearRepairReqRegCHEItemQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReqRegCHEItemQuery  
GO  
  
-- v2015.07.14  
  
-- 연차보수요청등록-디테일조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReqRegCHEItemQuery  
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
            @ReqSeq     INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ReqSeq   = ISNULL( ReqSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (ReqSeq   INT)    
    
    -- 최종조회   
    SELECT A.ToolSeq, 
           B.ToolName, 
           B.ToolNo, 
           A.WorkOperSeq, 
           C.MinorName AS WorkOperName, 
           A.WorkGubn, 
           D.MinorName AS WorkGubnName, 
           A.ProgType, 
           E.MinorName AS ProgTypeName, 
           A.WorkContents, 
           A.ReqSeq, 
           A.ReqSerl, 
           A.WONo
           
      FROM KPXCM_TEQYearRepairReqRegItemCHE     AS A 
      LEFT OUTER JOIN _TPDTool                  AS B ON ( B.CompanySeq = @CompanySeq AND B.ToolSeq = A.ToolSeq ) 
      LEFT OUTER JOIN _TDAUMinor                AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.WorkOperSeq ) 
      LEFT OUTER JOIN _TDAUMinor                AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.WorkGubn ) 
      LEFT OUTER JOIN _TDAUMinor                AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.ProgType ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.ReqSeq = @ReqSeq 
      
    RETURN  
GO 
exec KPXCM_SEQYearRepairReqRegCHEItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <ReqSeq>3</ReqSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030838,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025722