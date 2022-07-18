
IF OBJECT_ID('jongie_SPDOSPPOListPrint') IS NOT NULL 
    DROP PROC jongie_SPDOSPPOListPrint 
GO

-- v2013.11.13 
  
-- 외주발주서관리대장_jongie(출력) by이재천  
CREATE PROC jongie_SPDOSPPOListPrint                  
    @xmlDocument    NVARCHAR(MAX),   
    @xmlFlags       INT = 0,   
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',   
    @CompanySeq     INT = 1,   
    @LanguageSeq    INT = 1,   
    @UserSeq        INT = 0,   
    @PgmSeq         INT = 0   
AS   
      
    CREATE TABLE #TPDOSPPOItem (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDOSPPOItem'       
    IF @@ERROR <> 0 RETURN    
      
    SELECT CONVERT(NVARCHAR(8),GETDATE(),112) AS Present,   
           E.DeptName,   
           D.EmpName,   
           F.CustName,   
           G.ItemName,   
           G.Spec,   
           ISNULL(B.Qty,0) AS Qty,   
           ISNULL(B.Price,0) AS Price,   
           ISNULL(B.CurAmt,0) AS CurAmt,   
           ISNULL(B.CurAmt,0) + ISNULL(B.CurVAT,0) AS TotCurAmt,   
           ISNULL(B.Price,0) + CASE WHEN ISNULL(B.Qty,0) = 0 THEN 0 ELSE ISNULL(B.CurVAT,0) / ISNULL(B.Qty,0) END AS TotPrice,   
           C.PODate,   
           B.DelvDate AS DelvReqDate,   
           B.Remark AS Remark1   
             
      FROM #TPDOSPPOItem            AS A  
      LEFT OUTER JOIN _TPDOSPPOItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OSPPOSeq = A.OSPPOSeq AND B.OSPPOSerl = A.OSPPOSerl )   
      LEFT OUTER JOIN _TPDOSPPO     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.OSPPOSeq = A.OSPPOSeq )   
      LEFT OUTER JOIN _TDAEmp       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = C.EmpSeq )   
      LEFT OUTER JOIN _TDADept      AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = C.DeptSeq )   
      LEFT OUTER JOIN _TDACust      AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = C.CustSeq )   
      LEFT OUTER JOIN _TDAItem      AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = B.ItemSeq )   
     ORDER BY E.DeptName, D.EmpName  
      
    RETURN  
  