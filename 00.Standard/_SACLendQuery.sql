
IF OBJECT_ID('_SACLendQuery') IS NOT NULL 
    DROP PROC _SACLendQuery 
GO 

-- v2013.12.19 

-- 대여금등록(조회) by이재천
CREATE PROC _SACLendQuery                
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
    
AS        
    
	DECLARE @docHandle  INT,
		    @LendSeq    INT  
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

	SELECT  @LendSeq = LendSeq 
    
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
    
	  WITH (LendSeq     INT )
    
	SELECT A.LendSeq, 
	       A.BizUnit, 
	       B.BizUnitName, 
	       A.SMLendType, 
	       C.MinorName AS SMLendTypeName, 
	       A.UMLendKind, 
	       D.MinorName AS UMLendKindName, 
	       A.LendNo, 
	       A.AccSeq, 
	       E.AccName, 
	       A.LendDate, 
	       A.ExpireDate, 
	       A.Amt, 
	       A.CustSeq, 
	       F.CustName, 
	       A.EmpSeq, 
	       G.EmpName, 
	       A.Remark
	       
      FROM _TACLend AS A 
      LEFT OUTER JOIN _TDABizUnit AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDASMinor  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMLendType ) 
      LEFT OUTER JOIN _TDAUMinor  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMLendKind ) 
      LEFT OUTER JOIN _TDAAccount AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TDACust    AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAEmp     AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.EmpSeq = A.EmpSeq ) 
	 WHERE A.CompanySeq = @CompanySeq
       AND A.LendSeq = @LendSeq 

	SELECT A.LendSeq, 
	       A.Serl, 
	       A.FrDate, 
	       A.RepayCnt, 
	       A.ToDate, 
	       A.SMRepayType, 
	       A.RepayTerm, 
	       A.DeferYear, 
	       A.DeferMonth, 
	       A.OddTime, 
	       A.OddUnitAmt, 
	       A.Remark, 
	       B.MinorName AS SMrepayTypeName 
	       
      FROM _TACLendRePayOpt AS A  
      LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SMRepayType ) 
      
	 WHERE  A.CompanySeq = @CompanySeq
       AND A.LendSeq = @LendSeq 
           
	SELECT A.LendSeq, 
           A.Serl, 
           A.SMCalcMethod, 
           B.MinorName AS SMCalcMethodName, 
           A.SMInterestPayWay, 
           C.MinorName AS SMInterestPayWayName, 
           A.FrDate, 
           A.ToDate, 
           A.InterestRate, 
           A.InterestTerm AS SMInterestTerm, 
           A.DayQty, 
           A.PayCnt, 
           A.SMRateType, 
           A.Spread, 
           A.IntDayCountType, 
           E.MinorName AS IntDayCountTypeName
           
      FROM _TACLendInterestOpt AS A 
      LEFT OUTER JOIN _TDASMinor AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.SMCalcMethod ) 
      LEFT OUTER JOIN _TDASMinor AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.SMInterestPayWay ) 
      LEFT OUTER JOIN _TDASMinor AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.SMRateType ) 
      LEFT OUTER JOIN _TDASMinor AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.IntDayCountType ) 
      
	 WHERE A.CompanySeq = @CompanySeq 
       AND A.LendSeq = @LendSeq 

    SELECT A.LendSeq, 
           A.Serl, 
           A.PayCnt, 
           A.PayDate, 
           A.FrDate, 
           A.ToDate, 
           A.TotAmt, 
           A.PayAmt, 
           A.PayIntAmt, 
           A.Remark
      
      FROM _TACLendPlan AS A
     WHERE A.CompanySeq = @CompanySeq
       AND A.LendSeq = @LendSeq 

    SELECT A.LendSeq, 
           A.Serl, 
           A.SuretyName, 
           A.SuretyAmt, 
           A.SuretyDate, 
           A.ExpireDate, 
           A.Remark 
      
      FROM _TACLendSurety AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.LendSeq = @LendSeq

    RETURN
GO
exec _SACLendQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <LendSeq>44</LendSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=9646,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=11392