IF OBJECT_ID('KPXCM_SLGInOutReqGWQuery') IS NOT NULL 
    DROP PROC KPXCM_SLGInOutReqGWQuery
GO 

-- v2015.07.07 

-- 기타출고요청-GW조회 by이재천 
CREATE PROCEDURE KPXCM_SLGInOutReqGWQuery    
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
 AS         
    DECLARE @docHandle        INT,      
            @ReqSeq           INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument        
    
    SELECT @ReqSeq = ISNULL(ReqSeq,0)
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
      WITH (  
            ReqSeq INT
           ) 
    
    SELECT ROW_NUMBER() OVER(ORDER BY A.ReqSeq) AS Num, 
           A.ReqSeq      AS ReqSeq,
           C.BizUnitName, 
           A.BizUnit, 
           D.WHName AS OutWHName, 
           A.OutWHSeq AS OutWHSeq, 
           A.ReqNo, 
           A.ReqDate, 
           A.DeptSeq, 
           E.DeptName, 
           A.EmpSeq, 
           F.EmpName, 
           A.Remark, 
           
           B.ItemSeq, 
           G.ItemNo, 
           G.ItemName, 
           G.Spec, 
           B.UnitSeq, 
           H.UnitName,
           I.MinorName AS InOutReqKindName, 
           B.InOutReqDetailKind, 
           B.Remark AS SubRemark, 
           B.Qty 
      FROM _TLGInOutReq                 AS A 
                 JOIN _TLGInOutReqItem  AS B ON ( B.CompanySeq = A.CompanySeq AND B.ReqSeq = A.ReqSeq ) 
      LEFT OUTER JOIN _TDABizUnit       AS C ON ( C.CompanySeq = A.CompanySeq AND C.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDAWH            AS D ON ( D.CompanySeq = A.CompanySeq AND D.WHSeq = A.OutWHSeq ) 
      LEFT OUTER JOIN _TDADept          AS E ON ( E.CompanySeq = A.CompanySeq AND E.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp           AS F ON ( F.CompanySeq = A.CompanySeq AND F.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAItem          AS G ON ( G.CompanySeq = B.CompanySeq AND G.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit          AS H ON ( H.CompanySeq = B.CompanySeq AND H.UnitSeq = B.UnitSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS I ON ( I.CompanySeq = B.CompanySeq AND I.MinorSeq = B.InOutReqDetailKind ) 
    
     WHERE A.CompanySeq = @CompanySeq
       AND A.ReqSeq = @ReqSeq 
    
    RETURN
GO

EXEC _SCOMGroupWarePrint 2, 1, 1, 1358, 'EtcOutReq_CM', '6', ''