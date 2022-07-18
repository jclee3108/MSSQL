
IF OBJECT_ID('KPX_SLGInOutDailyQuery') IS NOT NULL 
    DROP PROC KPX_SLGInOutDailyQuery
GO 

-- v2014.12.05

-- 사이트테이블로 변경 by이재천 
/*************************************************************************************************            
 설  명 - 일일입출고Master 조회        
 작성일 - 2008.10 : CREATED BY 정수환        
 수정일 - 2011.07.14 by 김철웅    
  1) CompleteDate가 빈값일때 현재일자를 return해 주기     
*************************************************************************************************/            
CREATE PROCEDURE KPX_SLGInOutDailyQuery          
    @xmlDocument    NVARCHAR(MAX),        
    @xmlFlags       INT = 0,        
    @ServiceSeq     INT = 0,        
    @WorkingTag     NVARCHAR(10)= '',        
        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0        
AS               
    DECLARE   @docHandle   INT,            
              @InOutSeq    INT,    
              @InOutType   INT    
        
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument              
        
    SELECT  @InOutSeq  = ISNULL(InOutSeq,0),    
            @InOutType = ISNULL(InOutType,0)    
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)             
    WITH (  InOutSeq   INT,    
            InOutType  INT)              
      
    SELECT  A.InOutSeq          AS InOutSeq,      
            A.BizUnit           AS BizUnit,      
            IsNull((SELECT  BizUnitName     
                      FROM _TDABizUnit     
                     WHERE  CompanySeq = A.CompanySeq     
                       AND  BizUnit    = A.BizUnit), '') AS BizUnitName,    
            A.InOutNo           AS InOutNo,      
            A.FactUnit          AS FactUnit,      
            IsNull((SELECT  FactUnitName     
                      FROM _TDAFactUnit WITH(NOLOCK)    
                     WHERE  CompanySeq = A.CompanySeq     
                       AND  FactUnit   = A.FactUnit), '') AS FactUnitName,      
            A.ReqBizUnit        AS ReqBizUnit,    
            IsNull((SELECT  BizUnitName     
                      FROM _TDABizUnit WITH(NOLOCK)    
                     WHERE  CompanySeq = A.CompanySeq     
                       AND  BizUnit    = A.ReqBizUnit), '') AS ReqBizUnitName,    
            A.DeptSeq           AS DeptSeq,    
            IsNull((SELECT  DeptName     
                      FROM _TDADept WITH(NOLOCK)     
                     WHERE  CompanySeq = A.CompanySeq     
                       AND  DeptSeq    = A.DeptSeq), '') AS DeptName,    
            A.EmpSeq            AS EmpSeq,    
            IsNull((SELECT  EmpName     
                      FROM _TDAEmp WITH(NOLOCK)     
                     WHERE  CompanySeq = A.CompanySeq     
                       AND  EmpSeq    = A.EmpSeq), '') AS EmpName,    
            A.InOutDate         AS InOutDate,    
            A.WCSeq             AS WCSeq,    
            IsNull((SELECT  WorkCenterName     
                      FROM _TPDBaseWorkCenter WITH(NOLOCK)     
                     WHERE  CompanySeq = A.CompanySeq     
                       AND  WorkCenterSeq    = A.WCSeq), '') AS WCName,    
            A.ProcSeq           AS ProcSeq,    
            IsNull((SELECT  MinorName     
                      FROM _TDAUMinor WITH(NOLOCK)     
                     WHERE  CompanySeq = A.CompanySeq     
                       AND  MinorSeq    = A.ProcSeq), '') AS ProcName,    
            A.CustSeq           AS CustSeq,    
            IsNull((SELECT  CustName     
                      FROM _TDACust WITH(NOLOCK)     
                     WHERE  CompanySeq = A.CompanySeq     
                       AND  CustSeq    = A.CustSeq), '') AS CustName,    
            A.OutWHSeq          AS OutWHSeq,    
            IsNull((SELECT  WHName     
                      FROM _TDAWH WITH(NOLOCK)     
                     WHERE  CompanySeq = A.CompanySeq     
                       AND  WHSeq    = A.OutWHSeq), '') AS OutWHName,    
            A.InWHSeq           AS InWHSeq,    
            IsNull((SELECT  WHName     
                      FROM _TDAWH WITH(NOLOCK)     
                       WHERE  CompanySeq = A.CompanySeq     
                       AND  WHSeq    = A.InWHSeq), '') AS InWHName,    
            A.DVPlaceSeq        AS DVPlaceSeq,    
              IsNull((SELECT  DVPlaceName     
                      FROM _TSLDeliveryCust WITH(NOLOCK)     
                     WHERE  CompanySeq = A.CompanySeq     
                       AND  DVPlaceSeq    = A.DVPlaceSeq), '') AS DVPlaceName,    
            A.IsTrans           AS IsTrans,    
            A.IsCompleted       AS IsCompleted,    
            A.CompleteDeptSeq   AS CompleteDeptSeq,    
            IsNull((SELECT  DeptName     
                      FROM _TDADept WITH(NOLOCK)     
                     WHERE  CompanySeq = A.CompanySeq     
                       AND  DeptSeq    = A.CompleteDeptSeq), '') AS CompleteDeptName,    
            A.CompleteEmpSeq    AS CompleteEmpSeq,    
            IsNull((SELECT  EmpName     
                      FROM _TDAEmp WITH(NOLOCK)     
                     WHERE  CompanySeq = A.CompanySeq     
                       AND  EmpSeq    = A.CompleteEmpSeq), '') AS CompleteEmpName,    
            CASE WHEN ISNULL(A.CompleteDate,'')= '' THEN CONVERT(NCHAR(8), getdate(), 112) ELSE A.CompleteDate END AS CompleteDate,    
            --CASE WHEN ISNULL(A.CompleteDate,'')= '' THEN CONVERT(NCHAR(8), A.LastDateTime, 112) ELSE A.CompleteDate END AS CompleteDate,    
            --A.CompleteDate      AS CompleteDate,    
            A.InOutType         AS InOutType,    
            A.InOutDetailType   AS InOutDetailType,    
            A.Remark            AS Remark,    
            A.Memo              AS Memo,    
            A.UseDeptSeq        AS UseDeptSeq,    
            IsNull((SELECT  DeptName     
                      FROM _TDADept WITH(NOLOCK)     
                     WHERE  CompanySeq = A.CompanySeq     
                       AND  DeptSeq    = A.UseDeptSeq), '') AS UseDeptName, 
            A.WOReqSeq, 
            B.WONo AS WONo 
                
    
     FROM KPX_TPUMatOutEtcOut AS A WITH (NOLOCK)    
     LEFT OUTER JOIN _TEQWorkOrderReqMasterCHE AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.WOReqSeq = A.WOReqSeq ) 
    WHERE A.CompanySeq  = @CompanySeq      
      AND A.InOutType   = @InOutType    
      AND A.InOutSeq    = @InOutSeq    
      --AND A.IsBatch <> '1'      
    
    RETURN 