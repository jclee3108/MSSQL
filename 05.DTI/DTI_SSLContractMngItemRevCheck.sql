
IF OBJECT_ID('DTI_SSLContractMngItemRevCheck') IS NOT NULL 
    DROP PROC DTI_SSLContractMngItemRevCheck
GO 

-- v2013.12.24 

-- 계약관리등록이력등록_DTI(품목체크) by이재천
CREATE PROC DTI_SSLContractMngItemRevCheck
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    DECLARE @MessageType INT,
            @Status      INT,
            @Results     NVARCHAR(250)
    
    CREATE TABLE #DTI_TSLContractMngItemRev (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLContractMngItemRev'

    SELECT * 
      INTO #DTI_TSLContractMngItemRev_Sub
      FROM #DTI_TSLContractMngItemRev 
      
    DELETE A
      FROM #DTI_TSLContractMngItemRev_Sub AS A 
     WHERE A.WorkingTag <> 'U'
    
    -- 체크1, 매입이 진행 된 데이터가 포함 되어 AMD등록을 할 수 없습니다.   
    IF EXISTS(SELECT 1
                FROM #DTI_TSLContractMngItemRev_Sub AS A 
                JOIN _TPUORDApprovalReqItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq 
                                                               AND CONVERT(INT,B.Memo3) = A.ContractSeq 
                                                               AND CONVERT(INT,B.Memo4) = A.ContractSerl
                                                                 ) 
             )
    BEGIN
        UPDATE A 
           SET Result = N'매입이 진행 된 데이터가 포함 되어 AMD등록을 할 수 없습니다.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #DTI_TSLContractMngItemRev AS A 
         WHERE A.Status = 0 
    END
    -- 체크1, END 
    
    -- 체크2, 매입이 진행 된 데이터가 포함 되어 AMD등록을 할 수 없습니다.
    IF EXISTS(SELECT 1
                FROM #DTI_TSLContractMngItemRev_Sub AS A 
                JOIN _TSLOrderItem          AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq 
                                                               AND CONVERT(INT,B.Dummy6) = A.ContractSeq
                                                               AND CONVERT(INT,B.Dummy7) = A.ContractSerl 
                                                                 ) 
             )
    BEGIN
        UPDATE A 
           SET Result = N'매입이 진행 된 데이터가 포함 되어 AMD등록을 할 수 없습니다.', 
               Status = 1234, 
               MessageType = 1234 
          FROM #DTI_TSLContractMngItemRev AS A 
         WHERE A.Status = 0 
    END
    -- 체크2, END 
    
    SELECT * FROM #DTI_TSLContractMngItemRev 
    
    RETURN    
GO
exec DTI_SSLContractMngItemRevCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemName>상품1_이재천</ItemName>
    <ItemNo>상품1_이재천</ItemNo>
    <Spec />
    <Qty>100</Qty>
    <IsStock>0</IsStock>
    <PurYM>201312</PurYM>
    <PurPrice>200</PurPrice>
    <PurAmt>20000</PurAmt>
    <PurChk>1</PurChk>
    <SalesYM>201312</SalesYM>
    <SalesPrice>300</SalesPrice>
    <SalesAmt>30000</SalesAmt>
    <SalesChk>0</SalesChk>
    <Remark />
    <GPPrice>10000</GPPrice>
    <GPRate>33</GPRate>
    <LotNo />
    <ContractSeq>1000067</ContractSeq>
    <ContractSerl>1</ContractSerl>
    <ItemSeq>27255</ItemSeq>
    <ContractRev>0</ContractRev>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemName>상품2_이재천</ItemName>
    <ItemNo>상품2_이재천</ItemNo>
    <Spec />
    <Qty>100</Qty>
    <IsStock>0</IsStock>
    <PurYM>201312</PurYM>
    <PurPrice>200</PurPrice>
    <PurAmt>20000</PurAmt>
    <PurChk>0</PurChk>
    <SalesYM>201312</SalesYM>
    <SalesPrice>300</SalesPrice>
    <SalesAmt>30000</SalesAmt>
    <SalesChk>0</SalesChk>
    <Remark />
    <GPPrice>10000</GPPrice>
    <GPRate>33</GPRate>
    <LotNo />
    <ContractSeq>1000067</ContractSeq>
    <ContractSerl>2</ContractSerl>
    <ItemSeq>27261</ItemSeq>
    <ContractRev>0</ContractRev>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemName>상품3_이재천</ItemName>
    <ItemNo>상품3_이재천</ItemNo>
    <Spec />
    <Qty>100</Qty>
    <IsStock>0</IsStock>
    <PurYM>201312</PurYM>
    <PurPrice>300</PurPrice>
    <PurAmt>30000</PurAmt>
    <PurChk>0</PurChk>
    <SalesYM>201312</SalesYM>
    <SalesPrice>400</SalesPrice>
    <SalesAmt>40000</SalesAmt>
    <SalesChk>0</SalesChk>
    <Remark />
    <GPPrice>10000</GPPrice>
    <GPRate>25</GPRate>
    <LotNo />
    <ContractSeq>1000067</ContractSeq>
    <ContractSerl>3</ContractSerl>
    <ItemSeq>27262</ItemSeq>
    <ContractRev>0</ContractRev>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemName />
    <ItemNo />
    <Spec />
    <Qty>0</Qty>
    <IsStock>0</IsStock>
    <PurYM />
    <PurPrice>0</PurPrice>
    <PurAmt>0</PurAmt>
    <PurChk>0</PurChk>
    <SalesYM />
    <SalesPrice>0</SalesPrice>
    <SalesAmt>0</SalesAmt>
    <SalesChk>0</SalesChk>
    <Remark />
    <GPPrice>0</GPPrice>
    <GPRate>0</GPRate>
    <LotNo />
    <ContractSeq>1000067</ContractSeq>
    <ContractSerl>0</ContractSerl>
    <ItemSeq>0</ItemSeq>
    <ContractRev>0</ContractRev>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>5</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemName />
    <ItemNo />
    <Spec />
    <Qty>0</Qty>
    <IsStock>0</IsStock>
    <PurYM />
    <PurPrice>0</PurPrice>
    <PurAmt>0</PurAmt>
    <PurChk>0</PurChk>
    <SalesYM />
    <SalesPrice>0</SalesPrice>
    <SalesAmt>0</SalesAmt>
    <SalesChk>0</SalesChk>
    <Remark />
    <GPPrice>0</GPPrice>
    <GPRate>0</GPRate>
    <LotNo />
    <ContractSeq>1000067</ContractSeq>
    <ContractSerl>0</ContractSerl>
    <ItemSeq>0</ItemSeq>
    <ContractRev>0</ContractRev>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015903,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013760