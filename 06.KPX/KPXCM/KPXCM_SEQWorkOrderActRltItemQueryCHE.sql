
IF OBJECT_ID('KPXCM_SEQWorkOrderActRltItemQueryCHE') IS NOT NULL 
    DROP PROC KPXCM_SEQWorkOrderActRltItemQueryCHE
GO 

-- v2015.07.23 

-- KPXCM 용으로 개발 by이재천 
/************************************************************
  설  명 - 데이터-작업실적Item : 실적조회D
  작성일 - 20110516
  작성자 - 신용식
 ************************************************************/
CREATE PROC KPXCM_SEQWorkOrderActRltItemQueryCHE
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
            @ReceiptSeq      INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
    
    SELECT @ReceiptSeq = ISNULL(ReceiptSeq,0) 
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)
      WITH  (ReceiptSeq        INT )
    
    SELECT A.ReceiptSeq      , 
           A.WOReqSeq        ,
           A.WOReqSerl       ,
           ISNULL(E.MinorName,'') AS RecProgTypeName , 
           F.ProgType AS RecProgType     , 
           B.PdAccUnitSeq    , 
           ISNULL(D.FactUnitName,'')  AS PdAccUnitName   , 
           B.ToolSeq        , 
           C.ToolName       , 
           B.WorkOperSeq    , 
           B.SectionSeq     , 
           '' AS SectionCode      , 
           C.ToolNo         , 
           ISNULL(G.MinorName,'') AS WorkOperName,
           B.ToolNo NonCodeToolNo   , 
           '' AS ActCenterSeq    , 
           '' AS ActCenterName, 
           H.Remark, 
           H.FileSeq, 
           H.ProtectKind, 
           I.MinorName AS ProtectKindName, 
           H.WorkReason, 
           J.Minorname AS WorkReasonName, 
           H.PreProtect, 
           K.MinorName AS PreProtectName, 
           O.MngValText AS ToolKindName,  -- 설비구분 
           Q.MinorName AS ProtectLevelName -- 설비보전등급
           
      FROM  _TEQWorkOrderReceiptItemCHE                 AS A 
                 JOIN _TEQWorkOrderReceiptMasterCHE     AS F ON A.CompanySeq = F.CompanySeq AND A.ReceiptSeq = F.ReceiptSeq 
                 JOIN _TEQWorkOrderReqItemCHE           AS B ON A.CompanySeq = B.CompanySeq AND A.WOReqSeq = B.WOReqSeq AND A.WOReqSerl = B.WOReqSerl
      LEFT OUTER JOIN _TPDTool                          AS C ON B.CompanySeq = C.CompanySeq AND B.ToolSeq = C.ToolSeq    -- 설비
      LEFT OUTER JOIN _TDAFactUnit                      AS D ON B.CompanySeq = D.CompanySeq AND B.PdAccUnitSeq = D.FactUnit -- 생산사업장
      LEFT OUTER JOIN _TDAUMinor                        AS E ON F.CompanySeq = E.CompanySeq AND F.ProgType = E.MinorSeq    -- 접수진행상태    
      LEFT OUTER JOIN _TDAUMinor                        AS G ON B.CompanySeq  = G.CompanySeq AND B.WorkOperSeq = G.MinorSeq    -- 작업수행과
      LEFT OUTER JOIN KPXCM_TEQWorkOrderActRltToolInfo  AS H ON ( H.CompanySeq = @CompanySeq AND H.ReceiptSeq = A.ReceiptSeq AND H.WOReqSeq = A.WOReqSeq AND H.WOReqSerl = A.WOReqSerl ) 
      LEFT OUTER JOIN _TDAUMinor                        AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = H.ProtectKind ) 
      LEFT OUTER JOIN _TDAUMinor                        AS J ON ( J.CompanySeq = @CompanySeq AND J.MinorSeq = H.WorkReason ) 
      LEFT OUTER JOIN _TDAUMinor                        AS K ON ( K.CompanySeq = @CompanySeq AND K.MinorSeq = H.PreProtect ) 
      LEFT OUTER JOIN _TPDToolUserDefine                 AS O ON ( O.CompanySeq = @CompanySeq AND O.ToolSeq = B.ToolSeq AND O.MngSerl = 1000001 )
      LEFT OUTER JOIN _TPDToolUserDefine                 AS P ON ( P.CompanySeq = @CompanySeq AND P.ToolSeq = B.ToolSeq AND P.MngSerl = 1000002 )
      LEFT OUTER JOIN _TDAUMinor                        AS Q ON ( Q.CompanySeq = @CompanySeq AND Q.MinorSeq = P.MngValSeq ) 
     WHERE  A.CompanySeq  = @CompanySeq
       AND  A.ReceiptSeq  = @ReceiptSeq      
    
    RETURN