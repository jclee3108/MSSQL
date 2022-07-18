    
IF OBJECT_ID('yw_SLGASProcPlanJumpQuery') IS NOT NULL
    DROP PROC yw_SLGASProcPlanJumpQuery
GO

-- v2013.07.17

-- AS처리방안_YW(점프조회) by이재천
CREATE PROC yw_SLGASProcPlanJumpQuery                
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    DECLARE @docHandle   INT,
		    @ASRegSeq    INT,
            @Status      INT,    
            @Results     NVARCHAR(250), 
            @MessageType INT
 
    CREATE TABLE #YW_TLGASProcPlan (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#YW_TLGASProcPlan'       
    IF @@ERROR <> 0 RETURN    

    -- 데이터유무체크
    IF EXISTS ( SELECT 1   
                  FROM #YW_TLGASProcPlan AS A   
                  LEFT OUTER JOIN YW_TLGASProcPlan AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ASRegSeq = B.ASRegSeq ) 
                 WHERE B.ASRegSeq IS NULL   
                  )  
    BEGIN               
        
        UPDATE A  
           SET Result       = 'AS처리방안 데이터가 존재하지않습니다.',  
               MessageType  = @MessageType,  
               Status       = 123412  
          FROM #YW_TLGASProcPlan AS A
          LEFT OUTER JOIN YW_TLGASProcPlan AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ASRegSeq = B.ASRegSeq )
         WHERE B.ASRegSeq IS NULL
    END   

    SELECT Z.WorkingTag,
           Z.IDX_NO,
           Z.DataSeq,
           Z.Selected,
           Z.MessageType,
           Z.Status,
           Z.Result,
           A.ASRegSeq , -- AS접수코드
           A.ASRegNo , -- AS접수번호
           A.ASRegDate , -- 접수일자 
           I.MinorName AS SMLocalTypeName , -- 지역구분
           A.SMLocalType, 
           M.MinorName AS UMASMClassName , -- AS중분류
           A.UMASMClass, 
           A.OrderItemNo , -- 주문관리번호
           C.CustName , -- 고객사명
           E.CustItemName , -- 업체품명
           D.ItemName , -- 제품명
           D.ItemNo ,  -- 제품번호
           H.MinorName AS UMResponsTypeName , -- 귀책구분
           B.UMResponsType ,
           B.ResponsProc , -- 귀책공정
           B.ResponsDept , -- 귀책부서
           W.DeptName AS ProcDeptName, -- 처리부서
           B.ProcDept , 
           A.TargetQty , -- 대상수량
           S.EmpName AS ImsiEmpName , -- 임시담당
           T.EmpName AS RootEmpName , -- 근본담당
           B.ImsiProc  -- 임시조치
      
      FROM #YW_TLGASProcPlan AS Z 
      LEFT OUTER JOIN YW_TLGASReg      AS A WITH (NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.ASRegSeq = Z.ASRegSeq ) 
      LEFT OUTER JOIN YW_TLGASProcPlan AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ASRegSeq = A.ASRegSeq ) 
      LEFT OUTER JOIN _TDACust     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAItem     AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TSLCustItem AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.CustSeq AND E.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUMinor   AS H WITH(NOLOCK) ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = B.UMResponsType ) 
      LEFT OUTER JOIN _TDASMinor   AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = A.SMLocalType ) 
      LEFT OUTER JOIN _TDAUMinor   AS M WITH(NOLOCK) ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = A.UMASMClass )  
      LEFT OUTER JOIN _TDAEmp      AS S WITH(NOLOCK) ON ( S.CompanySeq = @CompanySeq AND S.EmpSeq = B.ImsiEmp ) 
      LEFT OUTER JOIN _TDAEmp      AS T WITH(NOLOCK) ON ( T.CompanySeq = @CompanySeq AND T.EmpSeq = B.RootEmp ) 
      LEFT OUTER JOIN _TDADept     AS W WITH(NOLOCK) ON ( W.CompanySeq = @CompanySeq AND W.DeptSeq = B.ProcDept ) 
      
    RETURN
GO
exec yw_SLGASProcPlanJumpQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ASRegSeq>49</ASRegSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016629,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014197