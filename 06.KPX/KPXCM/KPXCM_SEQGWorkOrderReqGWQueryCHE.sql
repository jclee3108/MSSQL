IF OBJECT_ID('KPXCM_SEQGWorkOrderReqGWQueryCHE') IS NOT NULL 
    DROP PROC KPXCM_SEQGWorkOrderReqGWQueryCHE
GO 

-- v2015.06.29 

-- 작업요청내역등록(일반) - 그룹웨어 by 이재천 
CREATE PROC KPXCM_SEQGWorkOrderReqGWQueryCHE
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT             = 0,
    @ServiceSeq     INT             = 0,
    @WorkingTag     NVARCHAR(10)    = '',
    @CompanySeq     INT             = 1,
    @LanguageSeq    INT             = 1,
    @UserSeq        INT             = 0,
    @PgmSeq         INT             = 0
AS
      
    DECLARE @docHandle      INT,
            @WOReqSeq     INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
    
    SELECT @WOReqSeq = ISNULL(WOReqSeq,0) 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      
      WITH  (WOReqSeq INT )
    
    SELECT A.WOReqSeq     , 
           A.ReqDate      , 
           A.DeptSeq      , 
           F.DeptName     , 
           A.EmpSeq       , 
           E.EmpName      , 
           A.WorkType     , 
           A.ReqCloseDate , 
           A.WorkContents , 
           A.WONo         , 
           A.FileSeq      , 
           B.FactUnitName AS AccUnitName  , 
           B.AccUnitSeq, 
           
           CASE WHEN C.ToolNo = '' THEN D.ToolName ELSE C.ToolNo END AS ToolName, 
           CASE WHEN C.ToolNo = '' THEN D.ToolNo ELSE '' END AS ToolNo, 
           
           REPLACE(REPLACE ( REPLACE ( REPLACE ( (SELECT FileName 
                                            FROM KPXERPCommon.DBO._TCAAttachFileData 
                                           WHERE AttachFileSeq = A.FileSeq 
                                          FOR XML AUTO, ELEMENTS
                                         ),'</FileName></KPXERPCommon.DBO._TCAAttachFileData><KPXERPCommon.DBO._TCAAttachFileData><FileName>','!@test!@'
                                       ), '<KPXERPCommon.DBO._TCAAttachFileData><FileName>',''
                             ), '</FileName></KPXERPCommon.DBO._TCAAttachFileData>', ''
                   ) ,'!@test!@', NCHAR(13))AS RealFileName -- 첨부자료
    
           
      FROM _TEQWorkOrderReqMasterCHE                AS A WITH (NOLOCK)
      OUTER APPLY ( SELECT TOP 1 Y.FactUnitName, Z.PdAccUnitSeq AS AccUnitSeq
                      FROM _TEQWorkOrderReqItemCHE AS Z 
                      LEFT OUTER JOIN _TDAFactUnit AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.FactUnit = Z.PdAccUnitSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.WOReqSeq = A.WOReqSeq 
                  ) AS B 
      LEFT OUTER JOIN _TEQWorkOrderReqItemCHE       AS C WITH(NOLOCK) ON ( C.CompanySeq = A.CompanySeq AND C.WOReqSeq = A.WOReqSeq ) 
      LEFT OUTER JOIN _TPDTool                      AS D WITH(NOLOCK) ON ( D.CompanySeq = C.CompanySeq AND D.ToolSeq = C.ToolSeq ) 
      LEFT OUTER JOIN _TDAEmp                       AS E WITH(NOLOCK) ON ( E.CompanySeq = A.CompanySeq AND E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                      AS F WITH(NOLOCK) ON ( F.CompanySeq = A.CompanySeq AND F.DeptSeq = A.DeptSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND A.WOReqSeq   = @WOReqSeq 
    
    RETURN
GO 
exec KPXCM_SEQGWorkOrderReqGWQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <WOReqSeq>1</WOReqSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10111,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=100146