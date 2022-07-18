  
IF OBJECT_ID('costel_SSLDelvContractRevSave') IS NOT NULL   
    DROP PROC costel_SSLDelvContractRevSave
GO  
  
-- v2013.09.05  
  
-- 납품계약등록_costel(차수등록) by이재천  
CREATE PROC costel_SSLDelvContractRevSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #costel_TSLDelvContractRev (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#costel_TSLDelvContractRev' 
    IF @@ERROR <> 0 RETURN    
    
    CREATE TABLE #costel_TSLDelvContractItemRev (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#costel_TSLDelvContractItemRev'   
    IF @@ERROR <> 0 RETURN 
    --select * from #costel_TSLDelvContractRev
    --select * from costel_TSLDelvContract 
    
    -- INSERT  
        INSERT INTO costel_TSLDelvContractRev  
        (   
            CompanySeq, ContractSeq, ContractRev, PJTName, PJTNo, 
            BizUnit, CustSeq, BKCustSeq,ContractDate, RegDate, 
            SalesEmpSeq, SalesDeptSeq, ContractDateFr, ContractDateTo, SMExpKind, 
            BizEmpSeq, BizDeptSeq, MHOpenDate, CurrSeq, ExRate, 
            Remark, IsCfm, CfmDate, IsStop, StopDate, 
            LastUserSeq, LastDateTime 
        )   
        SELECT @CompanySeq, B.ContractSeq, B.ContractRev, B.PJTName, B.PJTNo, 
               B.BizUnit, B.CustSeq, B.BKCustSeq, B.ContractDate, B.RegDate, 
               B.SalesEmpSeq, B.SalesDeptSeq, B.ContractDateFr, B.ContractDateTo, B.SMExpKind, 
               B.BizEmpSeq, B.BizDeptSeq, B.MHOpenDate, B.CurrSeq, B.ExRate, 
               B.Remark, B.IsCfm, B.CfmDate, B.IsStop, B.StopDate, 
               @UserSeq, GETDATE()
          FROM #costel_TSLDelvContractRev AS A
          LEFT OUTER JOIN costel_TSLDelvContract AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq )      
         WHERE A.Status = 0
        IF @@ERROR <> 0 RETURN  
        
        UPDATE A
           SET ContractRev = B.ContractRev
          FROM #costel_TSLDelvContractRev AS A 
          JOIN costel_TSLDelvContract     AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
         WHERE A.Status = 0
        --DELETE 
        DELETE B
          FROM #costel_TSLDelvContractRev AS A
          JOIN costel_TSLDelvContract     AS B ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
         WHERE A.Status = 0 
         
        DECLARE @MaxRev INT
        SELECT @MaxRev = (
                         SELECT MAX(B.ContractRev) 
                           FROM #costel_TSLDelvContractRev AS A 
                           JOIN costel_TSLDelvContractRev  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
                         )
        
        INSERT INTO costel_TSLDelvContract  
        (   
            CompanySeq, ContractSeq, ContractRev, PJTName, PJTNo, 
            BizUnit, CustSeq, BKCustSeq, ContractDate, RegDate, 
            SalesEmpSeq, SalesDeptSeq, ContractDateFr, ContractDateTo, SMExpKind, 
            BizEmpSeq, BizDeptSeq, MHOpenDate, CurrSeq, ExRate, 
            Remark, IsCfm, CfmDate, IsStop, StopDate, 
            LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.ContractSeq, @MaxRev + 1, A.PJTName, A.PJTNo, 
                A.BizUnit, A.CustSeq, A.BKCustSeq, A.ContractDate, A.RegDate, 
                A.SalesEmpSeq, A.SalesDeptSeq, A.ContractDateFr, A.ContractDateTo, A.SMExpKind, 
                A.BizEmpSeq, A.BizDeptSeq, A.MHOpenDate, A.CurrSeq, A.ExRate, 
                A.Remark, NULL, NULL, NULL, NULL, 
                @UserSeq, GETDATE() 
        
          FROM #costel_TSLDelvContractRev AS A   
          
        IF @@ERROR <> 0 RETURN  
        
    UPDATE A 
       SET ContractRev = @MaxRev + 1
      FROM #costel_TSLDelvContractRev AS A 


--select * from #costel_TSLDelvContractItemRev

    -- INSERT  
  
        INSERT INTO costel_TSLDelvContractItemRev  
        (   
            CompanySeq, ContractSeq, ContractSerl, ContractRev, DelvExpectDate, 
            ChgDelvExpectDate, ItemSeq, UnitSeq, DelvQty, DelvPrice, 
            DelvCurAmt, DelvCurVAT, SalesExpectDate, Remark, ChangeReason, 
            CollectExpectDate, LastUserSeq, LastDateTime 
        )   
        
        SELECT @CompanySeq, A.ContractSeq, A.ContractSerl, C.ContractRev - 1 , A.DelvExpectDate, 
               A.ChangeDeliveyDate, A.ItemSeq, A.UnitSeq, A.DelvQty, A.DelvPrice, 
               A.DelvAmt, A.DelvVatAmt, A.SalesExpectDate, A.Remark, A.ChangeReason, 
               A.ExpReceiptDate, @UserSeq, GETDATE()
          FROM #costel_TSLDelvContractItemRev AS A  
          JOIN costel_TSLDelvContractItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq AND B.ContractSerl = A.ContractSerl ) 
          JOIN costel_TSLDelvContract     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ContractSeq = B.ContractSeq ) 
        
        IF @@ERROR <> 0 RETURN  
    
        --DELETE 
        DELETE B
          FROM #costel_TSLDelvContractItemRev AS A
          JOIN costel_TSLDelvContractItem     AS B ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
          
        UPDATE A
           SET ContractRev = B.ContractRev
          FROM #costel_TSLDelvContractItemRev AS A 
          JOIN costel_TSLDelvContract         AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 

        DECLARE @MaxRevTemp INT
        SELECT @MaxRevTEmp = (
                              SELECT MAX(B.ContractRev) 
                                FROM #costel_TSLDelvContractItemRev AS A 
                                JOIN costel_TSLDelvContractItemRev  AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
                             )
    
        INSERT INTO costel_TSLDelvContractItem  
        (   
            CompanySeq, ContractSeq, ContractSerl, DelvExpectDate, ChgDelvExpectDate,
            ItemSeq, UnitSeq, DelvQty, DelvPrice, DelvCurAmt,
            DelvCurVAT, SalesExpectDate, Remark, ChangeReason, CollectExpectDate, 
            LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, A.ContractSeq, A.ContractSerl, A.DelvExpectDate, A.ChangeDeliveyDate,
               A.ItemSeq, A.UnitSeq, A.DelvQty, A.DelvPrice, A.DelvAmt,
               A.DelvVatAmt, A.SalesExpectDate, A.Remark, A.ChangeReason, A.ExpReceiptDate, 
               @UserSeq, GETDATE()
          FROM #costel_TSLDelvContractItemRev AS A   
        
        IF @@ERROR <> 0 RETURN  
    
        
    SELECT * FROM #costel_TSLDelvContractRev
    SELECT * FROM #costel_TSLDelvContractItemRev   
    
    RETURN 
    
GO
begin tran
exec costel_SSLDelvContractRevSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Sel>0</Sel>
    <ContractSerl>1</ContractSerl>
    <ContractSeq>21</ContractSeq>
    <DelvExpectDate>20130912</DelvExpectDate>
    <ChangeDeliveyDate>20130913</ChangeDeliveyDate>
    <ItemName>(명)PSAM(예산)</ItemName>
    <ItemNo>(번호)PSAM(예산)</ItemNo>
    <Spec />
    <UnitName>hr</UnitName>
    <DelvQty>14</DelvQty>
    <DelvPrice>120</DelvPrice>
    <DelvAmt>1680</DelvAmt>
    <DelvVatAmt>168</DelvVatAmt>
    <SumDelvAmt>1848</SumDelvAmt>
    <SalesExpectDate>20130917</SalesExpectDate>
    <Remark>test</Remark>
    <ChangeReason>test</ChangeReason>
    <ExpReceiptDate>20130919</ExpReceiptDate>
    <ItemSeq>22236</ItemSeq>
    <UnitSeq>1022</UnitSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
  <DataBlock1>
    <WorkingTag>R</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ContractRev>0</ContractRev>
    <VATRate>10</VATRate>
    <PJTAmt>1848</PJTAmt>
    <CfmDate />
    <SMStatusSeq>7027001</SMStatusSeq>
    <SMStatusName>작성</SMStatusName>
    <BizEmpSeq>235</BizEmpSeq>
    <BizEmpName>cuong          </BizEmpName>
    <BizDeptSeq>1621</BizDeptSeq>
    <BizDeptName>ABC</BizDeptName>
    <MHOpenDate>20130914</MHOpenDate>
    <ContractSeq>21</ContractSeq>
    <BKCustSeq>38177</BKCustSeq>
    <BKCustName>(복지)삼동소년촌</BKCustName>
    <PJTName>test111</PJTName>
    <PJTNo>test222</PJTNo>
    <ContractDateFr>20130912</ContractDateFr>
    <ContractDateTo>20130913</ContractDateTo>
    <BizUnit>1</BizUnit>
    <BizUnitName>당진사업장</BizUnitName>
    <CustSeq>38177</CustSeq>
    <CustName>(복지)삼동소년촌</CustName>
    <SalesEmpSeq>2028</SalesEmpSeq>
    <SalesEmpName>이재천</SalesEmpName>
    <SalesDeptSeq>147</SalesDeptSeq>
    <SalesDeptName>사업개발팀</SalesDeptName>
    <SMExpKind>8009001</SMExpKind>
    <SMExpKindName>내수</SMExpKindName>
    <IsCfm>0</IsCfm>
    <CurrSeq>1</CurrSeq>
    <CurrName>KRW</CurrName>
    <ExRate>1</ExRate>
    <Remark>test1111111</Remark>
    <RegDate>20130906</RegDate>
    <ContractDate>20130906</ContractDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017531,@WorkingTag=N'R',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1014985
rollback tran