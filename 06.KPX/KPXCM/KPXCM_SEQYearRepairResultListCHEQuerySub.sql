  
IF OBJECT_ID('KPXCM_SEQYearRepairResultListCHEQuerySub') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairResultListCHEQuerySub  
GO  
  
-- v2015.07.18  
  
-- 연차보수실적조회-Item조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairResultListCHEQuerySub  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @ResultSeq  INT,  
            @ResultSerl INT, 
            @WONo       NVARCHAR(100)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ResultSeq   = ISNULL( ResultSeq, 0 ),  
           @ResultSerl  = ISNULL( ResultSerl, 0 ),  
           @WONo        = ISNULL( WONo, '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ResultSeq   INT,  
            ResultSerl  INT, 
            WONo        NVARCHAR(100) 
           )    
    
    -- 최종조회   
    SELECT A.ResultSeq, 
           A.ResultSerl, 
           A.ResultSubSerl, 
           A.DivSeq, 
           E.MinorName AS DivName, 
           A.EmpSeq, 
           CASE WHEN A.DivSeq = 20117001 THEN B.EmpName ELSE C.CustName END AS EmpName, 
           A.WorkOperSerl, 
           D.MinorName AS WorkOperSerlName, 
           A.ManHour,
           A.OTManHour 
      FROM KPXCM_TEQYearRepairRltManHourCHE AS A 
      LEFT OUTER JOIN _TDAEmp               AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDACust              AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.WorkOperSerl ) 
      LEFT OUTER JOIN _TDAUMinor            AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.DivSeq ) 
     WHERE ( A.CompanySeq = @CompanySeq ) 
       AND ( A.ResultSeq = @ResultSeq )   
       AND ( A.ResultSerl = @ResultSerl ) 
    
    
    SELECT D.ItemName, D.ItemNo, D.Spec, C.STDQty AS Qty, A.WONo 
      FROM KPXCM_TEQYearRepairReqRegItemCHE AS A 
      JOIN KPX_TLGInOutDailyAdd             AS B ON ( B.CompanySeq = @CompanySeq AND B.WOReqSeq = A.ReqSeq AND B.WOReqSerl = A.ReqSerl AND B.Kind = 2 ) 
      LEFT OUTER JOIN _TLGInOutDailyItem    AS C ON ( C.CompanySeq = @CompanySeq AND C.InOutType = B.InOutType AND C.InOutSeq = B.InOutSeq )
      LEFT OUTER JOIN _TDAItem              AS D ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = C.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WONo = @WONo 
    
    RETURN  
GO
exec KPXCM_SEQYearRepairResultListCHEQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <WONo>YP-150720-004</WONo>
    <ResultSeq>8</ResultSeq>
    <ResultSerl>1</ResultSerl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030938,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025807