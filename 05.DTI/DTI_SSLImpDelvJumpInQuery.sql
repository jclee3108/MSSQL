
IF OBJECT_ID('DTI_SSLImpDelvJumpInQuery') IS NOT NULL 
    DROP PROC DTI_SSLImpDelvJumpInQuery
GO 

-- v2014.02.04 

-- 수입입고입력_DIT(JUMPInLotNo조회) by이재천
CREATE PROC dbo.DTI_SSLImpDelvJumpInQuery                
    @xmlDocument    NVARCHAR(MAX) ,            
    @xmlFlags       INT = 0,            
    @ServiceSeq     INT = 0,            
    @WorkingTag     NVARCHAR(10)= '',                  
    @CompanySeq     INT = 1,            
    @LanguageSeq    INT = 1,            
    @UserSeq        INT = 0,            
    @PgmSeq         INT = 0       
AS        
    
    CREATE TABLE #TEMP (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TEMP'     
    IF @@ERROR <> 0 RETURN  

    SELECT ROW_NUMBER() OVER(ORDER BY B.BLSeq, B.BLSerl) AS IDX_NO, B.BLSeq, B.BLSerl 
      INTO #TUIImpBLItem
      FROM #TEMP         AS A 
      JOIN _TUIImpBLItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.BLSeq = A.FromSeq AND B.BLSerl = A.FromSerl ) 
    
    CREATE TABLE #TMP_SourceTable 
            (IDOrder   INT, 
             TableName NVARCHAR(100))  
    
    INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
         SELECT 1, '_TPUORDApprovalReqItem'   -- 찾을 데이터의 테이블
    
    CREATE TABLE #TCOMSourceTracking 
            (IDX_NO  INT, 
            IDOrder  INT, 
            Seq      INT, 
            Serl     INT, 
            SubSerl  INT, 
            Qty      DECIMAL(19,5), 
            StdQty   DECIMAL(19,5), 
            Amt      DECIMAL(19,5), 
            VAT      DECIMAL(19,5)) 
          
    EXEC _SCOMSourceTracking 
             @CompanySeq = @CompanySeq, 
             @TableName = '_TUIImpBLItem',  -- 기준 테이블
             @TempTableName = '#TUIImpBLItem',  -- 기준템프테이블
             @TempSeqColumnName = 'BLSeq',  -- 템프테이블 Seq
             @TempSerlColumnName = 'BLSerl',  -- 템프테이블 Serl
             @TempSubSerlColumnName = '' 
    
    SELECT E.WHSeq, F.WHName
      FROM #TUIImpBLItem AS A 
      JOIN #TCOMSourceTracking AS B ON ( B.IDX_NO = A.IDX_NO ) 
      JOIN _TPUORDApprovalReqItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ApproReqSeq = B.Seq AND C.ApproReqSerl = B.Serl ) 
      JOIN DTI_TSLContractMngItem AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ContractSeq = CONVERT(INT,C.Memo3) AND D.ContractSerl = CONVERT(INT,C.Memo4) ) 
      JOIN DTI_TSLContractMng     AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ContractSeq = D.ContractSeq )  
      LEFT OUTER JOIN _TDAWH      AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.WHSeq = E.WHSeq ) 
    
    RETURN
GO
exec DTI_SSLImpDelvJumpInQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FromSeq>1000098</FromSeq>
    <FromSerl>1</FromSerl>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1020897,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1001635


