
IF OBJECT_ID('KPX_SEQGWorkOrderReqCHEGWQuery') IS NOT NULL 
    DROP PROC KPX_SEQGWorkOrderReqCHEGWQuery
GO 

-- v2014.12.11 

-- 작업요청서 GW 조회SP by이재천 
 CREATE PROC KPX_SEQGWorkOrderReqCHEGWQuery
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle      INT,
             @WOReqSeq     INT 
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
    
    SELECT  @WOReqSeq     = WOReqSeq      
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH  (WOReqSeq      INT )
    
    SELECT A.WOReqSeq     , 
           A.ReqDate      , 
           A.DeptSeq      , 
           B.DeptName     , -- 요청부서 
           A.EmpSeq       , 
           C.EmpName      , 
           A.WorkType     , 
           A.ReqCloseDate , 
           A.WorkContents , -- 작업내용 
           A.WONo         , -- WONo
           A.FileSeq      , 
           D.ToolSeq, 
           D.ToolName, -- 설비명 
           D.ToolNo -- 설비번호 
      FROM _TEQWorkOrderReqMasterCHE AS A 
      LEFT OUTER JOIN _TDADept       AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp        AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq ) 
      OUTER APPLY (SELECT TOP 1 Z.ToolSeq, Y.ToolName, Y.ToolNo
                     FROM _TEQWorkOrderReqItemCHE AS Z 
                     LEFT OUTER JOIN _TPDTool     AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.ToolSeq = Z.ToolSeq )  
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.WOReqSeq = A.WOReqSeq 
                  ) AS D
     WHERE A.CompanySeq = @CompanySeq
       AND A.WOReqSeq   = @WOReqSeq 
    
    RETURN