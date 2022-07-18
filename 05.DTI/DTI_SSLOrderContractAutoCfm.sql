
IF OBJECT_ID('DTI_SSLOrderContractAutoCfm') IS NOT NULL 
    DROP PROC DTI_SSLOrderContractAutoCfm
GO 

-- v2013.12.27 

-- 수주_DTI(자동확정)_DTI by이재천
CREATE PROC DTI_SSLOrderContractAutoCfm
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS   
    
    CREATE TABLE #TSLOrder_Confirm (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TSLOrder_Confirm'     
    IF @@ERROR <> 0 RETURN  
    --return 
    SELECT DISTINCT OrderSeq, Dummy6 
      INTO #TSLOrder_Confirm_Sub
      FROM #TSLOrder_Confirm
    
    -- 계약관련 데이터 일 경우 자동확정 
    IF (SELECT ISNULL(Dummy6,'') FROM #TSLOrder_Confirm_Sub) <> ''
    BEGIN 
        UPDATE B
           SET IsAuto = '1', 
               CfmCode = '1', 
               CfmDate = CONVERT(NVARCHAR(8),GETDATE(),112), 
               CfmEmpSeq = @UserSeq
          FROM #TSLOrder_Confirm_Sub AS A  
          JOIN _TSLOrder_Confirm AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.OrderSeq ) 
    END
    
    -- 수주예상GP정보 Data자동생성 
    INSERT INTO DTI_TSLOrderPuPrice ( CompanySeq, OrderSeq, OrderSerl, StdPuPrice, PuPrice, 
                                      LastUserSeq, LastDateTime ) 
    SELECT @CompanySeq, A.OrderSeq, A.OrderSerl, 0, B.PurPrice, 
           @UserSeq, GETDATE()
      FROM #TSLOrder_Confirm AS A 
      JOIN DTI_TSLContractMngItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = CONVERT(INT,Dummy6) AND B.ContractSerl = CONVERT(INT,Dummy7) ) 
      
    -- 수주연결정보 및 수주품목조회 시 Lot번호조회 데이터 저장 
    SELECT A.LotNo, A.ItemSeq, A.OrderSeq, A.OrderSerl, B.OrderAllocSerl, CONVERT(INT,Dummy6) AS Dummy6, CONVERT(INT,Dummy7) AS Dummy7
      INTO #TSLOrder_Confirm_Delv
      FROM #TSLOrder_Confirm AS A 
      JOIN DTI_TLGLotOrderConnect AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq 
                                                     AND B.OrderSeq = A.OrderSeq 
                                                     AND B.OrderSerl = A.OrderSerl 
                                                     AND B.LotNo = A.LotNo 
                                                     AND B.ItemSeq = A.ItemSeq 
                                                       )
    
    IF NOT EXISTS (SELECT 1 FROM #TSLOrder_Confirm_Delv)
    BEGIN
        
        INSERT INTO DTI_TLGLotOrderConnect (CompanySeq, LotNo, ItemSeq, OrderSeq, OrderSerl, 
                                            OrderAllocSerl, LotQty, LastUserSeq, LastDateTime)
        SELECT @CompanySeq, ISNULL(A.LotNo,''), A.ItemSeq, A.OrderSeq, A.OrderSerl, 
               B.OrderAllocSerl + 1, D.Qty, @UserSeq, GETDATE()
          FROM #TSLOrder_Confirm AS A 
          JOIN (SELECT A.LotNo, A.ItemSeq, A.OrderSeq, A.OrderSerl, ISNULL(MAX(B.OrderAllocSerl),0) AS OrderAllocSerl
                  FROM #TSLOrder_Confirm AS A 
                  LEFT OUTER JOIN DTI_TLGLotOrderConnect AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq 
                                                                            AND B.LotNo = A.LotNo 
                                                                            AND B.ItemSeq = A.ItemSeq 
                                                                            AND B.OrderSeq = A.OrderSeq 
                                                                            AND B.OrderSerl = A.OrderSerl 
                                                                              )
                 GROUP BY A.LotNo, A.ItemSeq, A.OrderSeq, A.OrderSerl 
               ) AS B ON ( ISNULL(B.LotNo,'') = ISNULL(A.LotNo,'') AND B.ItemSeq = A.ItemSeq AND B.OrderSeq = A.OrderSeq AND B.OrderSerl = A.OrderSerl ) 
          JOIN DTI_TSLContractMngItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ContractSeq = A.Dummy6 AND C.ContractSerl = A.Dummy7 ) 
          JOIN _TPUDelvItem           AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND CONVERT(INT,D.Memo3) = C.ContractSeq AND CONVERT(INT,D.Memo4) = C.ContractSerl ) 
    
    END 
    
    RETURN 
GO
begin tran
exec DTI_SSLOrderContractAutoCfm @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemSeq>27375</ItemSeq>
    <OrderSerl>1</OrderSerl>
    <Dummy1 />
    <Dummy2 />
    <Dummy3 />
    <Dummy4 />
    <Dummy5 />
    <Dummy6>1000063</Dummy6>
    <Dummy7>1</Dummy7>
    <Dummy8 />
    <Dummy9 />
    <Dummy10 />
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <OrderSeq>1000501</OrderSeq>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemSeq>27367</ItemSeq>
    <OrderSerl>2</OrderSerl>
    <Dummy1 />
    <Dummy2 />
    <Dummy3 />
    <Dummy4 />
    <Dummy5 />
    <Dummy6>1000063</Dummy6>
    <Dummy7>2</Dummy7>
    <Dummy8 />
    <Dummy9 />
    <Dummy10 />
    <OrderSeq>1000501</OrderSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016041,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1001696

rollback 
--select * from DTI_TLGLotOrderConnect where companyseq = 1 and orderseq = 1000502




--select * from _TPUDelv where companyseq = 1 and delvno = '201312280005'
--select * from _TPUDelvItem where companyseq = 1 and DelvSeq = 1000479