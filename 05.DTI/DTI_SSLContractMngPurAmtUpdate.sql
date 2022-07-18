
IF OBJECT_ID('DTI_SSLContractMngPurAmtUpdate') IS NOT NULL 
    DROP PROC DTI_SSLContractMngPurAmtUpdate
GO

-- v2014.01.22 

-- 계약관리현황_DTI(매출금액업데이트) by이재천
CREATE PROC DTI_SSLContractMngPurAmtUpdate
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
    
    CREATE TABLE #DTI_TSLContractMng (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TSLContractMng'
    
    -- 계약건의 품의데이터 담기
    SELECT ROW_NUMBER() OVER (ORDER BY D.ApproReqSeq, D.ApproReqSerl) AS IDX_NO, 
           D.ApproReqSeq, 
           D.ApproReqSerl, 
           C.ContractSeq, 
           C.ContractSerl 
      INTO #TPUORDApprovalReqItem
      FROM #DTI_TSLContractMng      AS A 
      JOIN DTI_TSLContractMng       AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ContractSeq = A.ContractSeq ) 
      JOIN DTI_TSLContractMngItem   AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ContractSeq = B.ContractSeq ) 
      JOIN _TPUORDApprovalReqItem   AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND CONVERT(INT,Memo3) = C.ContractSeq AND CONVERT(INT,Memo4) = C.ContractSerl ) 
    
    -- 진행 테이블
    CREATE TABLE #TMP_ProgressTable 
    (
        IDOrder   INT, 
        TableName NVARCHAR(100)
    ) 
    INSERT INTO #TMP_ProgressTable (IDOrder, TableName) 
    SELECT 1, '_TUIImpDelvItem'   -- 데이터 찾을 테이블

    CREATE TABLE #TCOMProgressTracking
            (IDX_NO  INT,  
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)) 
 
    EXEC _SCOMProgressTracking 
            @CompanySeq = @CompanySeq, 
            @TableName = '_TPUORDApprovalReqItem',    -- 기준이 되는 테이블
            @TempTableName = '#TPUORDApprovalReqItem',  -- 기준이 되는 템프테이블
            @TempSeqColumnName = 'ApproReqSeq',  -- 템프테이블의 Seq
            @TempSerlColumnName = 'ApproReqSerl',  -- 템프테이블의 Serl
            @TempSubSerlColumnName = ''  

    SELECT A.ApproReqSeq, A.ApproReqSerl, A.ContractSeq, A.ContractSerl, C.DomAmt, C.Price 
      INTO #TUIImpDelvItem
      FROM #TPUORDApprovalReqItem AS A 
      JOIN #TCOMProgressTracking  AS B              ON ( B.IDX_NO = A.IDX_NO ) 
      JOIN _TUIImpDelvItem        AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.DelvSeq = B.Seq AND C.DelvSerl = B.Serl ) 
      
    IF NOT EXISTS (SELECT 1 
                     FROM #DTI_TSLContractMng AS A 
                     JOIN DTI_TSLContractMngItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ContractSeq = B.ContractSeq ) 
                     JOIN _TSLOrderItem          AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND CONVERT(INT,Dummy6) = B.ContractSeq AND CONVERT(INT,Dummy7) = B.ContractSerl ) 
                  )
    BEGIN 
        UPDATE A
           SET PurPrice = B.Price,
               PurAmt = B.DomAmt
          FROM DTI_TSLContractMngItem AS A 
          JOIN #TUIImpDelvItem        AS B ON ( B.ContractSeq = A.ContractSeq AND B.ContractSerl = A.ContractSerl ) 
    END
    
    RETURN 
GO
begin tran 
exec DTI_SSLContractMngPurAmtUpdate @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ContractSeq>1000122</ContractSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1015902,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1013761
select * from DTI_TSLContractMngItem where companyseq = 1 and contractseq = 1000122
rollback