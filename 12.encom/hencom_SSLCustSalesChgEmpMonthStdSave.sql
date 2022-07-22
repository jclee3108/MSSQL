IF OBJECT_ID('hencom_SSLCustSalesChgEmpMonthStdSave') IS NOT NULL 
    DROP PROC hencom_SSLCustSalesChgEmpMonthStdSave
GO 

-- v2017.06.30 
/************************************************************
    Ver.20140925
    설  명 - 월기준거래처영업담당자변경 : 저장  
    작성일 - 20100309  
    작성자 - 최영규  
************************************************************/  
CREATE PROCEDURE dbo.hencom_SSLCustSalesChgEmpMonthStdSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT     = 0,  
    @ServiceSeq     INT     = 0,  
    @WorkingTag     NVARCHAR(10) = '',  
    @CompanySeq     INT     = 1,  
    @LanguageSeq    INT     = 1,  
    @UserSeq        INT     = 0,  
    @PgmSeq         INT     = 0  
AS  
    CREATE TABLE #TEMP_TABLE(WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TEMP_TABLE'  
    IF @@ERROR <> 0 RETURN  
   

    -- 체크1, 부서의 회계단위가 다릅니다.
    UPDATE A
       SET Result = '부서의 회계단위가 다릅니다.', 
           Status = 1234, 
           MessageType = 1234
      FROM #TEMP_TABLE AS A 
      LEFT OUTER JOIN _TDADept AS B ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.NowDeptSeq ) 
      LEFT OUTER JOIN _TDADept AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
     WHERE B.AccUnit <> C.AccUnit 
    -- 체크1, END 

    IF EXISTS (SELECT 1 FROM #TEMP_TABLE WHERE Status <> 0) 
    BEGIN 
        SELECT * FROM #TEMP_TABLE 
        RETURN 
    END 
    
    UPDATE _TSLInvoice 
       SET EmpSeq  = B.NowSalesEmpSeq,  
           DeptSeq = B.NowDeptSeq  
      FROM _TSLInvoice AS A  
      INNER JOIN #TEMP_TABLE AS B ON B.StdSeq = A.InvoiceSeq AND B.SalesBizSeq = 8062003 -- 거래명세서  
     WHERE A.CompanySeq  = @CompanySeq  
    
    IF @@ERROR <> 0 RETURN  
    
    CREATE TABLE #TMP_SalesSeq  
    ( SalesSeq INT, SalesSerl INT, InvoiceSeq INT, ADD_DEL INT)  
    
    INSERT #TMP_SalesSeq  
    SELECT A.ToSeq, A.ToSerl, A.FromSeq, 1  
      FROM  _TCOMSource A  
      JOIN #TEMP_TABLE B ON A.CompanySeq = @CompanySeq
                        AND A.FromTableSeq = 18 AND A.ToTableSeq = 20  
                        AND A.FromSeq = B.StdSeq  
                        AND B.SalesBizSeq = 8062003  
    UNION All  
    SELECT  A.ToSeq, A.ToSerl, A.FromSeq, A.ADD_DEL  
      FROM  _TCOMSourceDaily A  
      JOIN #TEMP_TABLE B ON A.CompanySeq = @CompanySeq
                        AND A.FromTableSeq = 18 AND A.ToTableSeq = 20  
                        AND A.FromSeq = B.StdSeq  
                        AND B.SalesBizSeq = 8062003
    UNION All
    SELECT  A.ToSeq, A.ToSerl, A.FromSeq, 1  
      FROM  _TCOMSource A  
      JOIN #TEMP_TABLE B ON A.CompanySeq = @CompanySeq
                        AND A.FromTableSeq = 55 AND A.ToTableSeq = 20  
                        AND A.FromSeq = B.StdSeq  
                        AND B.SalesBizSeq = 8062003  
    UNION All  
    SELECT  A.ToSeq, A.ToSerl, A.FromSeq, A.ADD_DEL  
      FROM  _TCOMSourceDaily A  
      JOIN #TEMP_TABLE B ON A.CompanySeq = @CompanySeq
                        AND A.FromTableSeq = 55 AND A.ToTableSeq = 20  
                        AND A.FromSeq = B.StdSeq  
                        AND B.SalesBizSeq = 8062003
    UNION All
    SELECT  A.ToSeq, A.ToSerl, A.FromSeq, 1  
      FROM  _TCOMSource A  
      JOIN #TEMP_TABLE B ON A.CompanySeq = @CompanySeq
                        AND A.FromTableSeq = 40 AND A.ToTableSeq = 20  
                        AND A.FromSeq = B.StdSeq  
                        AND B.SalesBizSeq = 8062003  
    UNION All  
    SELECT  A.ToSeq, A.ToSerl, A.FromSeq, A.ADD_DEL  
      FROM  _TCOMSourceDaily A  
      JOIN #TEMP_TABLE B ON A.CompanySeq = @CompanySeq
                        AND A.FromTableSeq = 40 AND A.ToTableSeq = 20  
                        AND A.FromSeq = B.StdSeq  
                        AND B.SalesBizSeq = 8062003
    UNION All
    SELECT  A.ToSeq, A.ToSerl, A.FromSeq, 1  
      FROM  _TCOMSource A  
      JOIN #TEMP_TABLE B ON A.CompanySeq = @CompanySeq
                        AND A.FromTableSeq = 39 AND A.ToTableSeq = 20  
                        AND A.FromSeq = B.StdSeq  
                        AND B.SalesBizSeq = 8062003  
    UNION All  
    SELECT  A.ToSeq, A.ToSerl, A.FromSeq, A.ADD_DEL  
      FROM  _TCOMSourceDaily A  
      JOIN #TEMP_TABLE B ON A.CompanySeq = @CompanySeq
                        AND A.FromTableSeq = 39 AND A.ToTableSeq = 20  
                        AND A.FromSeq = B.StdSeq  
                        AND B.SalesBizSeq = 8062003
    UNION All
    SELECT  A.ToSeq, A.ToSerl, A.FromSeq, 1  
      FROM  _TCOMSource A  
      JOIN #TEMP_TABLE B ON A.CompanySeq = @CompanySeq
                        AND A.FromTableSeq = 17 AND A.ToTableSeq = 20  
                        AND A.FromSeq = B.StdSeq  
                        AND B.SalesBizSeq = 8062003  
    UNION All  
    SELECT  A.ToSeq, A.ToSerl, A.FromSeq, A.ADD_DEL  
      FROM  _TCOMSourceDaily A  
      JOIN #TEMP_TABLE B ON A.CompanySeq = @CompanySeq
                        AND A.FromTableSeq = 17 AND A.ToTableSeq = 20  
                        AND A.FromSeq = B.StdSeq  
                        AND B.SalesBizSeq = 8062003  
                              
    
    UPDATE  _TSLSalesItem 
       SET EmpSeq  = C.NowSalesEmpSeq,  
           DeptSeq = C.NowDeptSeq  
      FROM _TSLSalesItem AS A  
      JOIN (SELECT  SalesSeq, SalesSerl, InvoiceSeq  
              FROM  #TMP_SalesSeq  
             GROUP BY SalesSeq, SalesSerl, InvoiceSeq  
             HAVING SUM(ADD_DEL) > 0
            ) B ON A.SalesSeq = B.SalesSeq AND A.SalesSerl = B.SalesSerl  
      INNER JOIN #TEMP_TABLE AS C ON C.StdSeq = B.InvoiceSeq AND C.SalesBizSeq = 8062003 -- 거래명세서  
     WHERE A.CompanySeq  = @CompanySeq  
    
    IF @@ERROR <> 0 RETURN  
    
    UPDATE _TSLSales 
       SET EmpSeq  = B.NowSalesEmpSeq,  
           DeptSeq = B.NowDeptSeq  
      FROM _TSLSales AS A  
      INNER JOIN #TEMP_TABLE AS B ON B.StdSeq = A.SalesSeq AND B.SalesBizSeq = 8062004 -- 매출  
     WHERE A.CompanySeq  = @CompanySeq  
    
    IF @@ERROR <> 0 RETURN  
    
    DELETE FROM #TMP_SalesSeq  
    
    INSERT #TMP_SalesSeq  
    SELECT A.ToSeq, A.ToSerl, A.FromSeq, 1  
      FROM  _TCOMSource A  
      JOIN #TEMP_TABLE B ON A.CompanySeq = @CompanySeq
                        AND A.FromTableSeq = 18 AND A.ToTableSeq = 20  
                        AND A.ToSeq = B.StdSeq  
                        AND B.SalesBizSeq = 8062004
    UNION All  
    SELECT A.ToSeq, A.ToSerl, A.FromSeq, A.ADD_DEL  
      FROM _TCOMSourceDaily A  
      JOIN #TEMP_TABLE B ON A.CompanySeq = @CompanySeq
                        AND A.FromTableSeq = 18 AND A.ToTableSeq = 20  
                        AND A.ToSeq = B.StdSeq  
                        AND B.SalesBizSeq = 8062004 
    
    UPDATE  _TSLSalesItem 
       SET EmpSeq  = C.NowSalesEmpSeq,  
           DeptSeq = C.NowDeptSeq  
      FROM _TSLSalesItem AS A  
      LEFT OUTER JOIN (SELECT  SalesSeq, SalesSerl, InvoiceSeq  
                         FROM  #TMP_SalesSeq  
                        GROUP BY SalesSeq, SalesSerl, InvoiceSeq  
                       HAVING SUM(ADD_DEL) > 0
                      ) B ON A.SalesSeq = B.SalesSeq AND A.SalesSerl = B.SalesSerl  
      INNER JOIN #TEMP_TABLE AS C ON C.StdSeq = A.SalesSeq  AND C.SalesBizSeq = 8062004  -- 매출  
     WHERE ISNULL(B.SalesSeq, 0) = 0
      AND A.CompanySeq  = @CompanySeq 
    
    IF @@ERROR <> 0 RETURN  
    
    UPDATE _TSLBill 
       SET EmpSeq  = B.NowSalesEmpSeq,  
           DeptSeq = B.NowDeptSeq  
      FROM _TSLBill AS A  
      INNER JOIN #TEMP_TABLE AS B ON B.StdSeq = A.BillSeq AND B.SalesBizSeq = 8062005   -- 세금계산서  
     WHERE A.CompanySeq  = @CompanySeq  
    
    IF @@ERROR <> 0 RETURN  
    
    UPDATE _TSLReceipt 
       SET EmpSeq  = B.NowSalesEmpSeq,  
           DeptSeq = B.NowDeptSeq  
      FROM _TSLReceipt AS A  
      INNER JOIN #TEMP_TABLE AS B ON B.StdSeq = A.ReceiptSeq AND B.SalesBizSeq = 8062006   -- 입금  
     WHERE A.CompanySeq  = @CompanySeq  
    
    IF @@ERROR <> 0 RETURN  
    
    UPDATE A
       SET EmpSeq = A.NowSalesEmpSeq, 
           DeptSeq = A.NowDeptSeq, 
           EmpName = B.EmpName, 
           DeptName = C.DeptName
      FROM #TEMP_TABLE AS A 
      LEFT OUTER JOIN _TDAEmp   AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.NowSalesEmpSeq ) 
      LEFT OUTER JOIN _TDADept  AS C ON ( C.CompanySeq = @CompanySEq AND C.DeptSEq = A.NowDeptSeq ) 
    
    SELECT * FROM #TEMP_TABLE 
    
    RETURN
go
begin tran 
exec hencom_SSLCustSalesChgEmpMonthStdSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <StdNo>2015120800001</StdNo>
    <StdDate>20151208</StdDate>
    <BizUnit>1</BizUnit>
    <BizUnitName>레미콘</BizUnitName>
    <CustSeq>978</CustSeq>
    <CustName>현대엔지니어링(주)</CustName>
    <CustNo />
    <StdAmt>5000000</StdAmt>
    <EmpSeq>293</EmpSeq>
    <EmpName>강민기</EmpName>
    <DeptName>군산사업소</DeptName>
    <DeptSeq>27</DeptSeq>
    <StdSeq>51</StdSeq>
    <SalesBizSeq>8062006</SalesBizSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <NowDeptSeq>27</NowDeptSeq>
    <NowSalesEmpSeq>293</NowSalesEmpSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <StdNo>2015122000001</StdNo>
    <StdDate>20151220</StdDate>
    <BizUnit>1</BizUnit>
    <BizUnitName>레미콘</BizUnitName>
    <CustSeq>5976</CustSeq>
    <CustName>(주)포스코건설</CustName>
    <CustNo />
    <StdAmt>58000</StdAmt>
    <EmpSeq>293</EmpSeq>
    <EmpName>강민기</EmpName>
    <DeptName>군산사업소</DeptName>
    <DeptSeq>27</DeptSeq>
    <StdSeq>76</StdSeq>
    <SalesBizSeq>8062006</SalesBizSeq>
    <NowDeptSeq>27</NowDeptSeq>
    <NowSalesEmpSeq>293</NowSalesEmpSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1512553,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1033869
rollback 