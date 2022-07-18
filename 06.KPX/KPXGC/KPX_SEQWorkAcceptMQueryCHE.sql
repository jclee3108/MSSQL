IF OBJECT_ID('KPX_SEQWorkAcceptMQueryCHE') IS NOT NULL
    DROP PROC KPX_SEQWorkAcceptMQueryCHE
GO 

-- v2015.03.26 

-- 작업접수조회(일반)-출력물 by 이재천 
CREATE PROC KPX_SEQWorkAcceptMQueryCHE
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
    
    CREATE TABLE #TEQWorkOrderReceiptMasterCHE( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TEQWorkOrderReceiptMasterCHE'   
    IF @@ERROR <> 0 RETURN     
    
    SELECT A.ReceiptSeq,  
           E.DeptName,  
           D.DeptSeq,  
           D.WorkContents AS WorkContents,  
           C.WONo, 
           B.ToolSeq,  
           I.ToolName AS ToolName,   
           I.ToolNo AS ToolNo 
      FROM #TEQWorkOrderReceiptMasterCHE            AS M 
      LEFT OUTER JOIN _TEQWorkOrderReceiptItemCHE   AS A ON ( A.CompanySeq = @CompanySeq AND A.ReceiptSeq = M.ReceiptSeq ) 
      LEFT OUTER JOIN _TEQWorkOrderReqItemCHE       AS B ON A.CompanySeq = B.CompanySeq AND A.WOReqSeq = B.WOReqSeq AND A.WOReqSerl = B.WOReqSerl  
      LEFT OUTER JOIN _TEQWorkOrderReqMasterCHE     AS C ON B.CompanySeq = C.CompanySeq AND B.WOReqSeq = C.WOReqSeq  
      LEFT OUTER JOIN _TEQWorkOrderReceiptMasterCHE AS D ON A.CompanySeq = D.CompanySeq AND A.ReceiptSeq = D.ReceiptSeq  
      LEFT OUTER JOIN _TDADept                      AS E ON D.CompanySeq = E.CompanySeq AND D.DeptSeq = E.DeptSeq  
      LEFT OUTER JOIN _TPDTool                      AS I ON B.CompanySeq = I.CompanySeq AND B.ToolSeq = I.ToolSeq  
    
    RETURN
GO 
--exec KPX_SEQWorkAcceptMQueryCHE @xmlDocument=N'<ROOT>
--  <DataBlock1>
--    <WorkingTag />
--    <IDX_NO>1</IDX_NO>
--    <DataSeq>1</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <ReceiptSeq>68</ReceiptSeq>
--    <TABLE_NAME>DataBlock1</TABLE_NAME>
--  </DataBlock1>
--  <DataBlock1>
--    <WorkingTag />
--    <IDX_NO>2</IDX_NO>
--    <DataSeq>2</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <ReceiptSeq>72</ReceiptSeq>
--  </DataBlock1>
--  <DataBlock1>
--    <WorkingTag />
--    <IDX_NO>3</IDX_NO>
--    <DataSeq>3</DataSeq>
--    <Status>0</Status>
--    <Selected>0</Selected>
--    <ReceiptSeq>73</ReceiptSeq>
--  </DataBlock1>
--</ROOT>',@xmlFlags=2,@ServiceSeq=1028737,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=100152