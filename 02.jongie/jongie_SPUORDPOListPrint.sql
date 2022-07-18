
IF OBJECT_ID('jongie_SPUORDPOListPrint')IS NOT NULL 
    DROP PROC jongie_SPUORDPOListPrint
GO

-- v2013.11.01 

-- 발주서관리대장_jongie(출력) by이재천
CREATE PROC jongie_SPUORDPOListPrint                
    @xmlDocument    NVARCHAR(MAX) , 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    CREATE TABLE #TPUORDPOItem (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUORDPOItem'     
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
           B.Remark1 
           
      FROM #TPUORDPOItem            AS A
      LEFT OUTER JOIN _TPUORDPOItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.POSeq = A.POSeq AND B.POSerl = A.POSerl ) 
      LEFT OUTER JOIN _TPUORDPO     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.POSeq = A.POSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = C.EmpSeq ) 
      LEFT OUTER JOIN _TDADept      AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = C.DeptSeq ) 
      LEFT OUTER JOIN _TDACust      AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = C.CustSeq ) 
      LEFT OUTER JOIN _TDAItem      AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = B.ItemSeq ) 
      
    
    RETURN

GO
exec jongie_SPUORDPOListPrint @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>10</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <POSeq>38518811</POSeq>
    <POSerl>1</POSerl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>11</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <POSeq>38518811</POSeq>
    <POSerl>2</POSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>12</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <POSeq>38518810</POSeq>
    <POSerl>3</POSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>13</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <POSeq>38518810</POSeq>
    <POSerl>4</POSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>14</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <POSeq>38518813</POSeq>
    <POSerl>1</POSerl>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019057,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1133