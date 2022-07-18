
IF OBJECT_ID('KPXCM_SEQToolWorkListCHEQuery') IS NOT NULL 
    DROP PROC KPXCM_SEQToolWorkListCHEQuery
GO 

-- v2015.08.18 

-- 설비이력조회-조회 by 이재천 
CREATE PROC KPXCM_SEQToolWorkListCHEQuery                
    @xmlDocument   NVARCHAR(MAX) ,            
    @xmlFlags      INT = 0,            
    @ServiceSeq    INT = 0,            
    @WorkingTag    NVARCHAR(10)= '',                  
    @CompanySeq    INT = 1,            
    @LanguageSeq   INT = 1,            
    @UserSeq       INT = 0,            
    @PgmSeq        INT = 0       
AS 
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle          INT,
            @WorkType           INT ,
            @AccUnitSeq         INT ,
            @WorkOperSeq        INT ,
            @ToolName           NVARCHAR(30) ,
            @EmpSeq             INT ,
            @QryFrDate          NCHAR(8) ,
            @QryToDate          NCHAR(8) ,
            @PackageYN          NCHAR(1) ,
			@ToolNo				NVARCHAR(50) 
 
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

    SELECT @WorkType           = ISNULL(WorkType      ,  0)    ,
           @AccUnitSeq         = ISNULL(AccUnitSeq    ,  0)    ,
           @WorkOperSeq        = ISNULL(WorkOperSeq   ,  0)    ,
           @ToolName           = ISNULL(ToolName      , '')    ,
           @EmpSeq             = ISNULL(EmpSeq        ,  0)    ,
           @QryFrDate          = ISNULL(QryFrDate     , '')    ,
           @QryToDate          = ISNULL(QryToDate     , '')    ,
           @PackageYN          = ISNULL(PackageYN     , '0')   ,
		   @ToolNo			   = ISNULL(ToolNo		  , '') 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (
            WorkType         INT ,
            AccUnitSeq       INT ,
            WorkOperSeq      INT ,
            ToolName         NVARCHAR(30) ,
            EmpSeq           INT ,
            QryFrDate        NCHAR(8) ,
            QryToDate        NCHAR(8) ,
            PackageYN        NCHAR(1) ,
			ToolNo			 NVARCHAR(50)
           )
    
    

    --IF @WorkType = 0                -- 전체
    --BEGIN

    ---작업실적등록(일반)
    SELECT 6028001                          AS WorkType         ,
           '작업실적등록(일반)'             AS WorkTypeName     ,
           ISNULL(D.FactUnitName,'')        AS AccUnitName      ,
           B.PdAccUnitSeq                   AS AccUnitSeq       ,
           -- C.ToolNo                         AS ToolNo           ,
           CASE WHEN @PackageYN = '0' THEN C.ToolName ELSE C3.ToolName END AS ToolName         ,
           CASE WHEN @PackageYN = '0' THEN C.ToolNo   ELSE C3.ToolNo   END AS ToolNo         ,
           B.ToolSeq                        AS ToolSeq          ,
           K.CCtrName                       AS ActCenterName    ,
           C1.MngValSeq                     AS CCtrSeq          ,
           ISNULL(G.MinorName,'')           AS WorkOperName     ,
           I.DeptName                       AS ReqDeptName      ,
           H.DeptSeq                        AS ReqDeptSeq       ,
           J.EmpName                        AS ReqEmpName       ,
           H.EmpSeq                         AS ReqEmpSeq        ,
           H.WorkName                       AS WorkName         ,
           H.ReqDate                        AS ReqDate          ,
           H.WONo                           AS WONo             ,
           H.ReqCloseDate                   AS ReqCloseDate     ,
           F.WorkContents                   AS WorkContents		,
           F.EmpSeq							AS EmpSeq			,
           L.EmpName						AS EmpName			,
           F.ReceiptDate					AS QryDate			
           -- F.FileSeq						AS FileSeq	
      FROM  _TEQWorkOrderReceiptItemCHE AS A 
                 JOIN _TEQWorkOrderReceiptMasterCHE     AS F ON A.CompanySeq = F.CompanySeq AND A.ReceiptSeq = F.ReceiptSeq 
      LEFT OUTER JOIN _TEQWorkOrderReqItemCHE           AS B ON A.CompanySeq = B.CompanySeq AND A.WOReqSeq = B.WOReqSeq AND A.WOReqSerl = B.WOReqSerl
      LEFT OUTER JOIN _TEQWorkOrderReqMasterCHE         AS H ON B.CompanySeq = H.CompanySeq AND B.WOReqSeq = H.WOReqSeq
      LEFT OUTER JOIN _TPDTool                          AS C ON B.CompanySeq = C.CompanySeq AND B.ToolSeq = C.ToolSeq
      LEFT OUTER JOIN _TPDToolUserDefine                 AS C1 ON C.CompanySeq = C1.CompanySeq AND C.ToolSeq = C1.ToolSeq AND C1.MngSerl = 1000002
      LEFT OUTER JOIN _TPDTool						    AS C3 ON C1.CompanySeq = C3.CompanySeq AND C1.MngValSeq = C3.ToolSeq
      LEFT OUTER JOIN _TDAFactUnit                      AS D ON B.CompanySeq = D.CompanySeq AND B.PdAccUnitSeq = D.FactUnit    -- 생산사업장
      LEFT OUTER JOIN _TDAUMinor                        AS G ON B.CompanySeq = G.CompanySeq AND B.WorkOperSeq = G.MinorSeq    -- 작업수행과
      LEFT OUTER JOIN _TDADept                          AS I ON H.CompanySeq = I.CompanySeq AND H.DeptSeq = I.DeptSeq
      LEFT OUTER JOIN _TDAEmp                           AS J ON H.CompanySeq = J.CompanySeq AND H.EmpSeq = J.EmpSeq
      LEFT OUTER JOIN _TDACCtr                          AS K ON C1.CompanySeq = K.CompanySeq AND C1.MngValSeq = K.CCtrSeq
      LEFT OUTER JOIN _TDAEmp							AS L ON F.CompanySeq = L.CompanySeq AND F.EmpSeq = L.EmpSeq
         WHERE 1=1
           AND F.ReceiptDate BETWEEN @QryFrDate AND @QryToDate
           AND (@AccUnitSeq     =  0 OR B.PdAccUnitSeq  = @AccUnitSeq)
           AND (@WorkOperSeq    =  0 OR B.WorkOperSeq   = @WorkOperSeq)
           AND (@EmpSeq         =  0 OR F.EmpSeq        = @EmpSeq)
           AND (@ToolName       = '' OR CASE WHEN @PackageYN='0' THEN C.ToolName ELSE C3.ToolName END    LIKE @ToolName + '%')
		   AND (@ToolNo         = '' OR CASE WHEN @PackageYN='0' THEN C.ToolNo   ELSE C3.ToolNo   END    LIKE @ToolName + '%')
    
    UNION ALL
	--작업실적등록(연차보수)(연차보수실적등록)
    SELECT 6028002 AS WorkType, 
           (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 6028002) AS WorkTypeName, 
           K.FactUnitName AS AccUnitName, 
           F.FactUnit AS AccUnitSeq, 
           F.ToolName AS ToolName, 
           F.ToolNo AS ToolNo, 
           C.ToolSeq, 
           '' AS ActCenterName, 
           0 AS CCtrSeq, 
           G.MinorName AS WorkOperName, 
           J.DeptName AS ReqDeptName, 
           D.DeptSeq AS ReqDeptSeq, 
           I.EmpName AS ReqEmpName, 
           D.EmpSeq AS ReqEmpSeq, 
           '' AS WorkName, 
           D.ReqDate,
           C.WONo, 
           '' AS ReqCloseDate, 
           C.WorkContents, 
           A.EmpSeq AS ReceiptEmpSeq, 
           M.EmpName AS ReceiptEmpName, 
           '' AS QtyDate 
      
      FROM KPXCM_TEQYearRepairResultRegItemCHE              AS Z 
                 JOIN KPXCM_TEQYearRepairResultRegCHE       AS X ON ( X.CompanySeq = @CompanySeq AND X.ResultSeq = Z.ResultSeq ) 
                 JOIN KPXCM_TEQYearRepairReceiptRegCHE      AS A ON ( A.CompanySeq = @CompanySeq AND A.ReceiptRegSeq = Z.ReceiptRegSeq ) 
                 JOIN KPXCM_TEQYearRepairReceiptRegItemCHE  AS B ON ( B.CompanySeq = @CompanySeq AND B.ReceiptRegSeq = Z.ReceiptRegSeq AND B.ReceiptRegSerl = Z.ReceiptRegSerl ) 
      LEFT OUTER JOIN KPXCM_TEQYearRepairReqRegItemCHE      AS C ON ( C.CompanySeq = @CompanySeq AND C.ReqSeq = B.ReqSeq AND C.ReqSerl = B.ReqSerl ) 
      LEFT OUTER JOIN KPXCM_TEQYearRepairReqRegCHE          AS D ON ( D.CompanySeq = @CompanySeq AND D.ReqSeq = C.ReqSeq ) 
      LEFT OUTER JOIN KPXCM_TEQYearRepairPeriodCHE          AS E ON ( E.CompanySeq = @CompanySeq AND E.RepairSeq = D.RepairSeq ) 
      LEFT OUTER JOIN _TPDTool                              AS F ON ( F.CompanySeq = @CompanySeq AND F.ToolSeq = C.ToolSeq ) 
      LEFT OUTER JOIN _TDAUMinor                            AS G ON ( G.CompanySeq = @CompanySeq AND G.MinorSeq = C.WorkOperSeq ) 
      LEFT OUTER JOIN _TDAEmp                               AS I ON ( I.CompanySeq = @CompanySeq AND I.EmpSeq = D.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                              AS J ON ( J.CompanySeq = @CompanySeq AND J.DeptSeq = D.DeptSeq ) 
      LEFT OUTER JOIN _TDAFactUnit                          AS K ON ( K.CompanySeq = @CompanySeq AND K.FactUnit = E.FactUnit ) 
      LEFT OUTER JOIN _TDAEmp                               AS M ON ( M.CompanySeq = @CompanySeq AND M.EmpSeq = A.EmpSeq ) 
     WHERE Z.CompanySeq = @CompanySeq 
       AND ( D.ReqDate BETWEEN @QryFrDate AND @QryToDate ) 
       AND ( @ToolName = '' OR F.ToolName LIKE @ToolName + '%' ) 
       AND ( @ToolNo = '' OR F.ToolNo LIKE @ToolNo + '%' ) 
       AND ( @AccUnitSeq = 0  OR F.FactUnit = @AccUnitSeq ) 
       AND ( @WorkOperSeq = 0 OR C.WorkOperSeq = @WorkOperSeq )
       AND ( @EmpSeq = 0 OR A.EmpSeq = @EmpSeq )
    
    
    
/*

	UNION ALL
   --설비검교정내역등록
	SELECT 6028003					       AS WorkType		,
		  (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq=@CompanySeq AND MinorSeq=6028003) AS WorkTypeName,
		  ISNULL(C.FactUnitName,'')        AS AccUnitName,
		  B.FactUnit				       AS AccUnitSeq,
		  CASE WHEN @PackageYN='0' THEN B.ToolName ELSE B2.ToolName END AS ToolName,
		  CASE WHEN @PackageYN='0' THEN B.ToolNo   ELSE B2.ToolName END AS ToolNo,
		  B.ToolSeq					       AS ToolSeq,
		  ''                               AS ActCenterName    ,
          0                                AS CCtrSeq          ,
          ''				               AS WorkOperName     ,
          ''                               AS ReqDeptName      ,
          0                                AS ReqDeptSeq       ,
          ''							   AS ReqEmpName       ,
          0                                AS ReqEmpSeq        ,
          ''							   AS WorkName         ,
          ''                               AS ReqDate          ,
          ''	                           AS WONo             ,
          ''			                   AS ReqCloseDate     ,
          A.WkContent			           AS WorkContents		,
          0								   AS EmpSeq			,
          ''							   AS EmpName			,
          A.CorrectDate					   AS QryDate			
		  --F.FileSeq						AS FileSeq	
	FROM _TEQExamCorrectEditCHE              AS A
	LEFT OUTER JOIN _TPDTool                 AS B  ON A.CompanySeq = B.CompanySeq 
								             	  AND A.ToolSeq	  = B.ToolSeq
	LEFT OUTER JOIN _TPDToolUserDefine       AS B1 ON B.CompanySeq   = B1.CompanySeq 
                                                  AND B.ToolSeq      = B1.ToolSeq 
                                                  AND B1.MngSerl     = 1000002
	LEFT OUTER JOIN _TPDTool				 AS B2 ON B1.CompanySeq	= B2.CompanySeq
											 	  AND B1.MngValSeq	= B2.ToolSeq
	LEFT OUTER JOIN _TDAFactUnit             AS C ON B.CompanySeq = C.CompanySeq
												 AND B.FactUnit	  = C.FactUnit
	WHERE 1=1
	AND A.CompanySeq = @CompanySeq
	AND (A.CorrectDate BETWEEN @QryFrDate AND @QryToDate)
	AND (@ToolName       = '' OR CASE WHEN @PackageYN='0' THEN B.ToolName ELSE B2.ToolName END    LIKE @ToolName + '%')
	AND (@ToolNo         = '' OR CASE WHEN @PackageYN='0' THEN B.ToolNo   ELSE B2.ToolNo   END    LIKE @ToolName + '%')
	AND (@AccUnitSeq     = 0  OR B.FactUnit = @AccUnitSeq)
	AND (@WorkOperSeq    =  0 )
    AND (@EmpSeq         =  0 )
	
	UNION ALL

	SELECT 6028004					       AS WorkType		,
	  (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq=@CompanySeq AND MinorSeq=6028004) AS WorkTypeName,
	  ISNULL(C.FactUnitName,'')        AS AccUnitName,
	  B.FactUnit				       AS AccUnitSeq,
	  CASE WHEN @PackageYN='0' THEN B.ToolName ELSE B2.ToolName END AS ToolName,
	  CASE WHEN @PackageYN='0' THEN B.ToolNo   ELSE B2.ToolName END AS ToolNo,
	  B.ToolSeq					       AS ToolSeq,
	  ''                               AS ActCenterName    ,
      0                                AS CCtrSeq          ,
      ''				               AS WorkOperName     ,
      ''                               AS ReqDeptName      ,
      0                                AS ReqDeptSeq       ,
      ''							   AS ReqEmpName       ,
      0                                AS ReqEmpSeq        ,
      ''							   AS WorkName         ,
      ''                               AS ReqDate          ,
      ''	                           AS WONo             ,
      ''			                   AS ReqCloseDate     ,
      A.Remark  			           AS WorkContents		,
      0								   AS EmpSeq			,
      ''							   AS EmpName			,
      A.CheckDate					   AS QryDate			
	  --F.FileSeq						AS FileSeq	
	FROM KPX_TEQCheckReport AS A
	LEFT OUTER JOIN _TPDTool AS B ON A.CompanySeq = B.CompanySeq
								 AND A.ToolSeq	  = B.ToolSeq
	LEFT OUTER JOIN _TPDToolUserDefine       AS B1 ON B.CompanySeq   = B1.CompanySeq 
                                                  AND B.ToolSeq      = B1.ToolSeq 
                                                  AND B1.MngSerl     = 1000002
	LEFT OUTER JOIN _TPDTool				 AS B2 ON B1.CompanySeq	= B2.CompanySeq
											 	  AND B1.MngValSeq	= B2.ToolSeq
	LEFT OUTER JOIN _TDAFactUnit             AS C ON B.CompanySeq = C.CompanySeq
												 AND B.FactUnit	  = C.FactUnit

     WHERE 1=1
      AND A.CompanySeq = @CompanySeq
      AND (A.CheckDate BETWEEN @QryFrDate AND @QryToDate)
      AND (@ToolName       = '' OR CASE WHEN @PackageYN='0' THEN B.ToolName ELSE B2.ToolName END    LIKE @ToolName + '%')
      AND (@ToolNo         = '' OR CASE WHEN @PackageYN='0' THEN B.ToolNo   ELSE B2.ToolNo   END    LIKE @ToolName + '%')
      AND (@AccUnitSeq     = 0  OR B.FactUnit = @AccUnitSeq)
      AND (@WorkOperSeq    =  0 )
      AND (@EmpSeq         =  0 )

    */
    
    RETURN

go 
exec KPXCM_SEQToolWorkListCHEQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <AccUnitSeq>3</AccUnitSeq>
    <QryFrDate>20150101</QryFrDate>
    <QryToDate>20150818</QryToDate>
    <EmpSeq />
    <PackageYN>0</PackageYN>
    <WorkOperSeq />
    <WorkType />
    <ToolName />
    <ToolNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026691,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1021376