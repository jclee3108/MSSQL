IF OBJECT_ID('hencom_SSLSalesEmpChangeSave') IS NOT NULL 
    DROP PROC hencom_SSLSalesEmpChangeSave
GO 

-- v2017.04.17 
/************************************************************
    Ver.20140925
  설  명 - 월기준거래처영업담당자변경 : 저장  
  작성일 - 20100309  
  작성자 - 최영규  
 ************************************************************/  
 CREATE PROCEDURE dbo.hencom_SSLSalesEmpChangeSave  
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

    

    /*
     UPDATE _TSLInvoice SET  
             EmpSeq  = B.NowSalesEmpSeq,  
             DeptSeq = B.NowDeptSeq  
       FROM _TSLInvoice AS A  
            INNER JOIN #TEMP_TABLE AS B  
                    ON B.StdSeq      = A.InvoiceSeq  
                   AND B.SalesBizSeq = 8062003   -- 거래명세서  
      WHERE A.CompanySeq  = @CompanySeq  
     IF @@ERROR <> 0 RETURN  

    
  CREATE TABLE #TMP_SalesSeq  
  ( SalesSeq INT, SalesSerl INT, InvoiceSeq INT, ADD_DEL INT)  
    
  INSERT  #TMP_SalesSeq  
  SELECT  A.ToSeq, A.ToSerl, A.FromSeq, 1  
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
                              
  UPDATE  _TSLSalesItem SET  
             EmpSeq  = C.NowSalesEmpSeq,  
             DeptSeq = C.NowDeptSeq  
       FROM _TSLSalesItem AS A  
            JOIN (SELECT  SalesSeq, SalesSerl, InvoiceSeq  
                    FROM  #TMP_SalesSeq  
                  GROUP BY SalesSeq, SalesSerl, InvoiceSeq  
                  HAVING SUM(ADD_DEL) > 0) B ON A.SalesSeq = B.SalesSeq AND A.SalesSerl = B.SalesSerl  
            INNER JOIN #TEMP_TABLE AS C  
                    ON C.StdSeq      = B.InvoiceSeq  
                   AND C.SalesBizSeq = 8062003   -- 거래명세서  
      WHERE A.CompanySeq  = @CompanySeq  
     IF @@ERROR <> 0 RETURN  
    
     UPDATE _TSLSales SET  
             EmpSeq  = B.NowSalesEmpSeq,  
             DeptSeq = B.NowDeptSeq  
       FROM _TSLSales AS A  
            INNER JOIN #TEMP_TABLE AS B  
                    ON B.StdSeq      = A.SalesSeq  
                   AND B.SalesBizSeq = 8062004   -- 매출  
      WHERE A.CompanySeq  = @CompanySeq  
     IF @@ERROR <> 0 RETURN  
     DELETE FROM #TMP_SalesSeq  
    
    
                                
     UPDATE  _TSLSalesItem SET  
             EmpSeq  = C.NowSalesEmpSeq,  
             DeptSeq = C.NowDeptSeq  
       FROM _TSLSalesItem AS A  
            LEFT OUTER JOIN (SELECT  SalesSeq, SalesSerl, InvoiceSeq  
                               FROM  #TMP_SalesSeq  
                              GROUP BY SalesSeq, SalesSerl, InvoiceSeq  
                             HAVING SUM(ADD_DEL) > 0) B ON A.SalesSeq = B.SalesSeq AND A.SalesSerl = B.SalesSerl  
            INNER JOIN #TEMP_TABLE AS C  
                    ON C.StdSeq      = A.SalesSeq  
                   AND C.SalesBizSeq = 8062004  -- 매출  
      WHERE ISNULL(B.SalesSeq, 0) = 0
        AND A.CompanySeq  = @CompanySeq 
       
     IF @@ERROR <> 0 RETURN  
	 */
     UPDATE _TSLBill SET  
             EmpSeq  = B.NowSalesEmpSeq
       FROM _TSLBill AS A  
            INNER JOIN #TEMP_TABLE AS B  
                    ON B.StdSeq      = A.BillSeq  
                   AND B.SalesBizSeq = 8062005   -- 세금계산서  
      WHERE A.CompanySeq  = @CompanySeq  
     IF @@ERROR <> 0 RETURN  
    
     UPDATE _TSLReceipt SET  
             EmpSeq  = B.NowSalesEmpSeq
       FROM _TSLReceipt AS A  
            INNER JOIN #TEMP_TABLE AS B  
                    ON B.StdSeq      = A.ReceiptSeq  
                   AND B.SalesBizSeq = 8062006   -- 입금  
      WHERE A.CompanySeq  = @CompanySeq  
     IF @@ERROR <> 0 RETURN  
    

	 DECLARE @StkYM NCHAR(6), @SumYM NCHAR(6)

     EXEC @StkYM = dbo._SCOMEnvR @CompanySeq, 1006, @UserSeq, @@PROCID    


     CREATE TABLE #StdYM 
     (
        IDX_NO  INT IDENTITY, 
        StdYM   NCHAR(6)
     )

     INSERT INTO #StdYM (StdYM)
     SELECT LEFT(StdDate,6) AS StdYM
       FROM #TEMP_TABLE 
      GROUP BY LEFT(StdDate,6) 
      ORDER BY StdYM
    
    DECLARE @Cnt INT 

    SELECT @Cnt = 1 

    WHILE ( @Cnt <= ISNULL((SELECT MAX(IDX_NO) FROM #StdYM),0) )
    BEGIN
        
        SELECT @SumYM = StdYM
          FROM #StdYM 
         WHERE IDX_NO = @Cnt 
        
        IF ISNULL(@SumYM,'') >= ISNULL(@StkYM,'')
        BEGIN
            EXEC _SSLBillReSum @CompanySeq, @SumYM  
		    EXEC _SSLReceiptReSum @CompanySeq, @SumYM  
        END

        SELECT @Cnt = @Cnt + 1 

    END 

	update #TEMP_TABLE
	   set empseq = nowsalesempseq, 
	       empname = nowsalesempname,
		   empno = ( select Empid from _tdaemp where companyseq = @CompanySeq and empseq = nowsalesempseq ) 
     SELECT * FROM #TEMP_TABLE  
RETURN
go
begin tran 
exec hencom_SSLSalesEmpChangeSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <StdNo>2015122500001</StdNo>
    <StdDate>20151225</StdDate>
    <BizUnit>1</BizUnit>
    <BizUnitName>레미콘</BizUnitName>
    <CustSeq>3147</CustSeq>
    <CustName>한라</CustName>
    <BizNo>215-81-40656</BizNo>
    <PersonId />
    <PJTSeq>10</PJTSeq>
    <PJTName>테스트프로젝트_파주</PJTName>
    <ItemSeq>3079</ItemSeq>
    <ItemName>00-060-00_파주사업소</ItemName>
    <StdAmt>5225000</StdAmt>
    <EmpSeq>0</EmpSeq>
    <EmpName />
    <EmpNo />
    <StdSeq>16</StdSeq>
    <NowSalesEmpName />
    <NowSalesEmpNo />
    <NowSalesEmpSeq>0</NowSalesEmpSeq>
    <SalesBizSeq>8062005</SalesBizSeq>
    <StdSerl>0</StdSerl>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <StdNo>2015120400003</StdNo>
    <StdDate>20151204</StdDate>
    <BizUnit>1</BizUnit>
    <BizUnitName>레미콘</BizUnitName>
    <CustSeq>997</CustSeq>
    <CustName>금호산업(주)</CustName>
    <BizNo>104-81-31309</BizNo>
    <PersonId />
    <PJTSeq>147</PJTSeq>
    <PJTName>야동동</PJTName>
    <ItemSeq>3091</ItemSeq>
    <ItemName>25-21-120_파주사업소</ItemName>
    <StdAmt>10908</StdAmt>
    <EmpSeq>0</EmpSeq>
    <EmpName />
    <EmpNo />
    <StdSeq>122</StdSeq>
    <NowSalesEmpName />
    <NowSalesEmpNo />
    <NowSalesEmpSeq>0</NowSalesEmpSeq>
    <SalesBizSeq>8062005</SalesBizSeq>
    <StdSerl>0</StdSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <StdNo>2015120200001</StdNo>
    <StdDate>20151202</StdDate>
    <BizUnit>1</BizUnit>
    <BizUnitName>레미콘</BizUnitName>
    <CustSeq>997</CustSeq>
    <CustName>금호산업(주)</CustName>
    <BizNo>104-81-31309</BizNo>
    <PersonId />
    <PJTSeq>402</PJTSeq>
    <PJTName>육군문산관사BTL</PJTName>
    <ItemSeq>3111</ItemSeq>
    <ItemName>25-24-150_파주사업소</ItemName>
    <StdAmt>32118</StdAmt>
    <EmpSeq>0</EmpSeq>
    <EmpName />
    <EmpNo />
    <StdSeq>123</StdSeq>
    <NowSalesEmpName />
    <NowSalesEmpNo />
    <NowSalesEmpSeq>0</NowSalesEmpSeq>
    <SalesBizSeq>8062005</SalesBizSeq>
    <StdSerl>0</StdSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>4</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <StdNo>2015120700001</StdNo>
    <StdDate>20151207</StdDate>
    <BizUnit>1</BizUnit>
    <BizUnitName>레미콘</BizUnitName>
    <CustSeq>70853</CustSeq>
    <CustName>(구)부산식당</CustName>
    <BizNo>621-18-05864</BizNo>
    <PersonId />
    <PJTSeq>3</PJTSeq>
    <PJTName>옥계사업소_테스트</PJTName>
    <ItemSeq>21</ItemSeq>
    <ItemName>00-060-00_군산사업소</ItemName>
    <StdAmt>55000</StdAmt>
    <EmpSeq>0</EmpSeq>
    <EmpName />
    <EmpNo />
    <StdSeq>127</StdSeq>
    <NowSalesEmpName />
    <NowSalesEmpNo />
    <NowSalesEmpSeq>0</NowSalesEmpSeq>
    <SalesBizSeq>8062005</SalesBizSeq>
    <StdSerl>0</StdSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>5</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <StdNo>2016012500001</StdNo>
    <StdDate>20160125</StdDate>
    <BizUnit>1</BizUnit>
    <BizUnitName>레미콘</BizUnitName>
    <CustSeq>2759</CustSeq>
    <CustName>성지건설산업</CustName>
    <BizNo>141-81-38053</BizNo>
    <PersonId />
    <PJTSeq>392</PJTSeq>
    <PJTName>파주하수관거정비임대형민자사업</PJTName>
    <ItemSeq>577</ItemSeq>
    <ItemName>00-060-00_동여주사업소</ItemName>
    <StdAmt>2200000</StdAmt>
    <EmpSeq>0</EmpSeq>
    <EmpName />
    <EmpNo />
    <StdSeq>169</StdSeq>
    <NowSalesEmpName />
    <NowSalesEmpNo />
    <NowSalesEmpSeq>0</NowSalesEmpSeq>
    <SalesBizSeq>8062005</SalesBizSeq>
    <StdSerl>0</StdSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>6</IDX_NO>
    <DataSeq>6</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <StdNo>2016030200003</StdNo>
    <StdDate>20160302</StdDate>
    <BizUnit>1</BizUnit>
    <BizUnitName>레미콘</BizUnitName>
    <CustSeq>996</CustSeq>
    <CustName>지에스건설(주)</CustName>
    <BizNo>104-81-18121</BizNo>
    <PersonId />
    <PJTSeq>13688</PJTSeq>
    <PJTName>P10C project</PJTName>
    <ItemSeq>3067</ItemSeq>
    <ItemName>25-50-180_파주사업소</ItemName>
    <StdAmt>7532800</StdAmt>
    <EmpSeq>1</EmpSeq>
    <EmpName>영림원</EmpName>
    <EmpNo>11111111</EmpNo>
    <StdSeq>194</StdSeq>
    <NowSalesEmpName />
    <NowSalesEmpNo />
    <NowSalesEmpSeq>0</NowSalesEmpSeq>
    <SalesBizSeq>8062005</SalesBizSeq>
    <StdSerl>0</StdSerl>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>7</IDX_NO>
    <DataSeq>7</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <StdNo>2016030200004</StdNo>
    <StdDate>20160302</StdDate>
    <BizUnit>1</BizUnit>
    <BizUnitName>레미콘</BizUnitName>
    <CustSeq>996</CustSeq>
    <CustName>지에스건설(주)</CustName>
    <BizNo>104-81-18121</BizNo>
    <PersonId />
    <PJTSeq>13688</PJTSeq>
    <PJTName>P10C project</PJTName>
    <ItemSeq>3067</ItemSeq>
    <ItemName>25-50-180_파주사업소</ItemName>
    <StdAmt>7532800</StdAmt>
    <EmpSeq>1</EmpSeq>
    <EmpName>영림원</EmpName>
    <EmpNo>11111111</EmpNo>
    <StdSeq>195</StdSeq>
    <NowSalesEmpName />
    <NowSalesEmpNo />
    <NowSalesEmpSeq>0</NowSalesEmpSeq>
    <SalesBizSeq>8062005</SalesBizSeq>
    <StdSerl>0</StdSerl>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1038018,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031042
rollback 