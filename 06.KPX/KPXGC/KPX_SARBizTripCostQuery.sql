  
IF OBJECT_ID('KPX_SARBizTripCostQuery') IS NOT NULL   
    DROP PROC KPX_SARBizTripCostQuery
GO  
  
-- v2015.01.08  
  
-- 출장비지출품의서-조회 by 이재천   
CREATE PROC KPX_SARBizTripCostQuery  
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
            @BizTripSeq INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizTripSeq   = ISNULL( BizTripSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (BizTripSeq   INT)    
    
    -- 최종조회   
    SELECT A.*, 
           B.EmpName, 
           C.MinorName AS SMTripKindName, 
           D.CCtrName, 
           E.MinorName AS UMCostTypeName, 
           D.UMCostType, 
           F.CostName, 
           F.AccSeq, 
           F.OppAccSeq, 
           G.AccName, 
           H.AccName AS OppAccName, 
           I.SlipMstSeq, 
           I.SlipMstID, 
           J.SlipUnitName, 
           K.DeptName, 
           K.UMJPName, 
           ISNULL(A.TransCost,0) + ISNULL(A.Dailycost,0) + ISNULL(A.LodgeCost,0) + ISNULL(A.EctCost,0) AS SumCost
           
      FROM KPX_TARBizTripCost       AS A 
      LEFT OUTER JOIN _TDAEmp       AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDASMinor    AS C ON ( C.CompanySeq = @CompanySeq AND C.minorSeq = A.SMTripKind ) 
      LEFT OUTER JOIN _TDACCtr      AS D ON ( D.CompanySeq = @CompanySeq AND D.CCtrSeq = A.CCtrSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = D.UMCostType ) 
      LEFT OUTER JOIN _TARCostAcc   AS F ON ( F.CompanySeq = @CompanySeq AND F.CostSeq = A.CostSeq AND F.SMKindSeq = 4503001 ) 
      LEFT OUTER JOIN _TDAAccount   AS G ON ( G.CompanySeq = @CompanySeq AND G.AccSeq = F.AccSeq ) 
      LEFT OUTER JOIN _TDAAccount   AS H ON ( H.CompanySeq = @CompanySeq AND H.AccSeq = F.OppAccSeq ) 
      LEFT OUTER JOIN _TACSlip      AS I ON ( I.CompanySeq = @CompanySeq AND I.SlipMstSeq = A.SlipMstSeq ) 
      LEFT OUTER JOIN _TACSlipUnit  AS J ON ( J.CompanySeq = @CompanySeq AND J.SlipUnit = A.SlipUnit ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS K ON ( K.EmpSeq = A.EmpSeq ) 
      
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.BizTripSeq = @BizTripSeq )  
      
    RETURN  
GO 
exec KPX_SARBizTripCostQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BizTripSeq>1</BizTripSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1027319,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022816