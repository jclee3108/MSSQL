
IF OBJECT_ID('amoerp_SSLExpInvoiceItemPONoQuery') IS NOT NULL 
    DROP PROC amoerp_SSLExpInvoiceItemPONoQuery
GO 

-- v2014.01.07 

-- 거래명세서입력(JUMPIN PONo조회)_amoerp by이재천
CREATE PROC dbo.amoerp_SSLExpInvoiceItemPONoQuery                
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    CREATE TABLE #TSLDVReqItem (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#TSLDVReqItem'     
    IF @@ERROR <> 0 RETURN  
    
    CREATE TABLE #TMP_SourceTable 
        (IDOrder   INT, 
         TableName NVARCHAR(100))  
    
    INSERT INTO #TMP_SourceTable (IDOrder, TableName) 
        SELECT 1, '_TSLOrderItem'   -- 찾을 데이터의 테이블
    
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
             @TableName = '_TSLDVReqItem',  -- 기준 테이블
             @TempTableName = '#TSLDVReqItem',  -- 기준템프테이블
             @TempSeqColumnName = 'FromSeq',  -- 템프테이블 Seq
             @TempSerlColumnName = 'FromSerl',  -- 템프테이블 Serl
             @TempSubSerlColumnName = '' 

    SELECT A.WorkingTag, A.IDX_NO, A.DataSeq, A.Selected, A.Status, A.FromSeq, A.FromSerl, C.PONo
      FROM #TSLDVReqItem AS A 
      JOIN #TCOMSourceTracking AS B ON ( B.IDX_NO = A.IDX_NO ) 
      JOIN _TSLOrder           AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.OrderSeq = B.Seq ) 
    
    RETURN
GO
exec amoerp_SSLExpInvoiceItemPONoQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FromSeq>1000233</FromSeq>
    <FromSerl>1</FromSerl>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <FromSeq>1000233</FromSeq>
    <FromSerl>2</FromSerl>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017825,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016355