IF OBJECT_ID('KPXCM_SPUDelvInQuantityAdjustQuery') IS NOT NULL 
    DROP PROC KPXCM_SPUDelvInQuantityAdjustQuery
GO 

-- v2015.10.08 

-- 케미칼용 개발 by 이재천 
/************************************************************  
 설  명 - 데이터-입고량조정등록 : Query  
 작성일 - 20141215  
 작성자 - 오정환  
 수정자 -   
************************************************************/  
  
CREATE PROC KPXCM_SPUDelvInQuantityAdjustQuery                  
    @xmlDocument   NVARCHAR(MAX) ,              
    @xmlFlags      INT = 0,              
    @ServiceSeq    INT = 0,              
    @WorkingTag    NVARCHAR(10)= '',                    
    @CompanySeq    INT = 1,              
    @LanguageSeq   INT = 1,              
    @UserSeq       INT = 0,              
    @PgmSeq        INT = 0         
  
AS          
      
    DECLARE @docHandle      INT,  
            @AdjustSeq      INT
   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT @AdjustSeq = ISNULL(AdjustSeq,0)
               
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (
            AdjustSeq   INT
           )  
  
  
  
    SELECT C.BizUnit,  
           Z.BizUnitName,  
           C.CustSeq,  
           S.CustName,  
           B.WHSeq,  
           W.WHName,  
           E.EmpName        AS EmpName,  
           D.DeptName       AS DeptName,  
           I.ItemName,  
           I.ItemNo,  
           I.Spec,  
           B.ItemSeq,  
           C.DelvInNo,   
           C.DelvInDate,      
           C.EmpSeq         AS DelvEmpSeq,  
           N.EmpName        AS DelvEmpName,   
           B.UnitSeq,  
           U.UnitName,  
           B.Price,  
           A.OldQty         AS OldQty,  
           A.AdjustDate     AS ChgDate,  
           A.Qty            AS Qty,  
           ISNULL(A.OldQty,0) - ISNULL(A.Qty,0)     AS DiffQty,  
           B.DelvCustSeq,  
           B.STDUnitSeq,  
           T.UnitName           AS STDUnitName,  
           B.STDUnitQty     AS STDQty,  
           B.LotNo,  
           B.Remark,  
           A.AdjustSeq,  
           A.DelvInSeq,  
           A.DelvInSerl,  
           A.EmpSeq,  
           A.DeptSeq  
    
      FROM KPX_TPUDelvInQuantityAdjust AS A JOIN _TPUDelvInItem     AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq  
                                                                                     AND B.DelvInSeq = A.DelvInSeq  
                                                                                     AND B.DelvInSerl = A.DelvInSerl  
                                            JOIN _TPUDelvIN         AS C WITH(NOLOCK) ON C.CompanySeq = A.CompanySeq  
                                                                                     AND C.DelvInSeq = A.DelvInSeq  
                                 LEFT OUTER JOIN _TDAEmp            AS E WITH(NOLOCK) ON E.CompanySeq = A.CompanySeq  
                                                                                     AND E.EmpSeq = A.EmpSeq  
                                 LEFT OUTER JOIN _TDADept           AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq  
                                                                                     AND D.DeptSeq = A.DeptSeq  
                                 LEFT OUTER JOIN _TDAItem           AS I WITH(NOLOCK) ON I.CompanySeq = B.CompanySeq  
                                                                                     AND I.ItemSeq = B.ItemSeq  
                                 LEFT OUTER JOIN _TDABizUnit        AS Z WITH(NOLOCK) ON Z.CompanySeq = C.CompanySeq  
                                                                                     AND Z.BizUnit = C.BizUnit  
                                 LEFT OUTER JOIN _TDACust           AS S WITH(NOLOCK) ON S.CompanySeq = C.CompanySeq  
                                                                                     AND S.CustSeq = C.CustSeq  
                                 LEFT OUTER JOIN _TDAWH             AS W WITH(NOLOCK) ON W.CompanySeq = B.CompanySeq  
                                                                                     AND W.WHSeq = B.WHSeq  
                                   LEFT OUTER JOIN _TDAEmp            AS N WITH(NOLOCK) ON N.CompanySeq = C.CompanySeq  
                                                                                     AND N.EmpSeq = C.EmpSeq  
                                 LEFT OUTER JOIN _TDAUnit           AS U WITH(NOLOCK) ON U.CompanySeq = B.CompanySeq  
                                                                                     AND U.UnitSeq = B.UnitSeq  
                                 LEFT OUTER JOIN _TDAUnit           AS T WITH(NOLOCK) ON T.CompanySeq = B.CompanySeq  
                                                                                     AND T.UnitSeq = B.STDUnitSeq  
                                                      
              
     WHERE A.CompanySeq = @CompanySeq  
       AND A.AdjustSeq = @AdjustSeq
      
RETURN  
--  GO
--  begin tran 
--  exec KPX_SPUDelvInQuantityAdjustQuery @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag>A</WorkingTag>
--    <IDX_NO>1</IDX_NO>
--    <Status>0</Status>
--    <DataSeq>1</DataSeq>
--    <Selected>1</Selected>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--    <IsChangedMst>0</IsChangedMst>
--    <AdjustSeq>0</AdjustSeq>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1032473,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026919

--rollback 