
IF OBJECT_ID('DTI_SSLContractMngItemRevSave') IS NOT NULL 
    DROP PROC DTI_SSLContractMngItemRevSave
GO 

-- v2013.12.24 

-- 계약관리등록이력등록_DTI(품목저장) by이재천
CREATE PROC DTI_SSLContractMngItemRevSave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0
AS   
    
    CREATE TABLE #DTI_TSLContractMngItemRev (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLContractMngItemRev'     
    IF @@ERROR <> 0 RETURN  
    
    DECLARE @ContractRev INT
    
    SELECT @ContractRev = (SELECT MAX(B.ContractRev) 
                            FROM #DTI_TSLContractMngItemRev AS A
                            JOIN DTI_TSLContractMngItem     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq )
                          ) 
    
    INSERT INTO DTI_TSLContractMngItemRev ( 
                                            CompanySeq, ContractSeq, ContractSerl ,ContractRev ,ItemSeq, 
                                            Qty, IsStock ,PurYM ,PurPrice ,PurAmt, SalesYM, 
                                            SalesPrice, SalesAmt, Remark, LastUserSeq, LastDateTime
                                          ) 
    SELECT @CompanySeq, A.ContractSeq, A.ContractSerl, A.ContractRev, A.ItemSeq, 
           A.Qty, A.IsStock, A.PurYM, A.PurPrice, A.PurAmt, A.SalesYM, 
           A.SalesPrice, A.SalesAmt, A.Remark, @UserSeq, GETDATE()
      FROM #DTI_TSLContractMngItemRev   AS B
      JOIN DTI_TSLContractMngItem       AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq AND A.ContractSerl = B.ContractSerl ) 
    
    IF @@ERROR <> 0  RETURN
    
    DELETE B
      FROM #DTI_TSLContractMngItemRev AS A
      JOIN DTI_TSLContractMngItem     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) --AND B.ContractSeq = A.ContractSeq ) 
      
    IF @@ERROR <> 0  RETURN

    INSERT INTO DTI_TSLContractMngItem ( 
                                        CompanySeq, ContractSeq, ContractSerl, ContractRev, ItemSeq, 
                                        Qty, IsStock, PurYM, PurPrice, PurAmt, 
                                        SalesYM, SalesPrice, SalesAmt, Remark, LastUserSeq, 
                                        LastDateTime
                                       ) 
    SELECT @CompanySeq, ContractSeq, ContractSerl, @ContractRev + 1, ItemSeq, 
           Qty, IsStock, PurYM, PurPrice, PurAmt, 
           SalesYM, SalesPrice, SalesAmt, Remark, @UserSeq, 
           GETDATE()
      FROM #DTI_TSLContractMngItemRev AS A 
    
    IF @@ERROR <> 0  RETURN
    
    SELECT * FROM #DTI_TSLContractMngItemRev 
    
    RETURN    
GO
begin tran 
exec DTI_SSLContractMngItemRevSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ContractSeq>1000033</ContractSeq>
    <ContractSerl>1</ContractSerl>
    <ItemSeq>27255</ItemSeq>
    <ItemName>상품1_이재천</ItemName>
    <ItemNo>상품1_이재천</ItemNo>
    <Spec />
    <Qty>100.00000</Qty>
    <PurYM>201312</PurYM>
    <PurPrice>2000.00000</PurPrice>
    <PurAmt>200000.00000</PurAmt>
    <PurChk>0</PurChk>
    <SalesYM>201312</SalesYM>
    <SalesPrice>3000.00000</SalesPrice>
    <SalesAmt>300000.00000</SalesAmt>
    <SalesChk>0</SalesChk>
    <GPPrice>100000.00000</GPPrice>
    <GPRate>33.00</GPRate>
    <LotNo />
    <Remark />
    <IsStock>0</IsStock>
    <ContractRev>5</ContractRev>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag xml:space="preserve"> </WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ContractSeq>1000033</ContractSeq>
    <ContractSerl>2</ContractSerl>
    <ItemSeq>27261</ItemSeq>
    <ItemName>상품2_이재천</ItemName>
    <ItemNo>상품2_이재천</ItemNo>
    <Spec />
    <Qty>200.00000</Qty>
    <PurYM>201312</PurYM>
    <PurPrice>2000.00000</PurPrice>
    <PurAmt>400000.00000</PurAmt>
    <PurChk>0</PurChk>
    <SalesYM>201312</SalesYM>
    <SalesPrice>21323123.00000</SalesPrice>
    <SalesAmt>4264624600.00000</SalesAmt>
    <SalesChk>0</SalesChk>
    <GPPrice>4264224600.00000</GPPrice>
    <GPRate>99.00</GPRate>
    <LotNo />
    <Remark />
    <IsStock>0</IsStock>
    <ContractRev>5</ContractRev>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <ContractSeq>1000033</ContractSeq>
    <ContractSerl>3</ContractSerl>
    <ItemSeq>27262</ItemSeq>
    <ItemName>상품3_이재천</ItemName>
    <ItemNo>상품3_이재천</ItemNo>
    <Spec />
    <Qty>300.00000</Qty>
    <PurYM>201312</PurYM>
    <PurPrice>50000.00000</PurPrice>
    <PurAmt>15000000.00000</PurAmt>
    <PurChk>0</PurChk>
    <SalesYM>201312</SalesYM>
    <SalesPrice>50000.00000</SalesPrice>
    <SalesAmt>15000000.00000</SalesAmt>
    <SalesChk>0</SalesChk>
    <GPPrice>0.00000</GPPrice>
    <GPRate>0.00</GPRate>
    <LotNo />
    <Remark />
    <IsStock>0</IsStock>
    <ContractRev>5</ContractRev>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015903,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013760
select * from DTI_TSLContractMngItem where companyseq = 1 and contractseq = 1000033 
select * from DTI_TSLContractMngItemRev where companyseq = 1 and contractseq = 1000033 
rollback 