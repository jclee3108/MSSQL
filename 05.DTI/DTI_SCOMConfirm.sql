
IF OBJECT_ID('DTI_SCOMConfirm') IS NOT NULL 
    DROP PROC DTI_SCOMConfirm
GO

-- v2014.01.09 

-- 수주_DTI(확정처리) by이재천
CREATE PROC dbo.DTI_SCOMConfirm
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
            @OrderSerl  INT, 
            @Confirm    NCHAR(1), 
            @OrderSeq   INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @OrderSerl = ISNULL(OrderSerl,0), 
           @Confirm  = ISNULL(Confirm,'0'), 
           @OrderSeq = ISNULL(OrderSeq,0)
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (OrderSerl   INT, 
            Confirm     NCHAR(1), 
            OrderSeq    INT 
           ) 
    IF EXISTS (SELECT 1 
                 FROM _TSLOrder AS A 
                 JOIN _TSLOrderItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OrderSeq = A.OrderSeq ) 
                 JOIN DTI_TSLContractMngItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ContractSeq = CONVERT(INT,Dummy6) AND C.ContractSerl = CONVERT(INT,Dummy7) ) 
                WHERE A.CompanySeq = @CompanySeq 
                  AND A.OrderSeq = @OrderSeq 
              )
    BEGIN 
        IF @Confirm = '0'
        BEGIN 
            DELETE A
              FROM _TCOMSourceDaily AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.FromTableSeq = 19 
               AND A.ToTableSeq = 11 
               AND A.FromSeq = @OrderSeq  
        END 
        ELSE 
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM _TCOMSourceDaily WHERE CompanySeq = @CompanySeq AND FromTableSeq = 19 AND ToTableSeq = 11 AND FromSeq = @OrderSeq) 
            BEGIN 
                INSERT INTO _TCOMSourceDaily (  
                                                CompanySeq, ToTableSeq, ToSeq, ToSerl, ToSubSerl,   
                                                FromTableSeq, FromSeq, FromSerl, FromSubSerl, ToQty,   
                                                ToSTDQty, ToAmt, ToVAT, FromQty, FromSTDQty,   
                                                FromAmt, FromVAT, ADD_DEL, PrevFromTableSeq, LastUserSeq,   
                                                LastDateTime  
                                             )  
                SELECT @CompanySeq, 11, D.ApproReqSeq, D.ApproReqSerl, 0,   
                       19, B.OrderSeq, B.OrderSerl, 0, D.Qty,   
                       D.StdUnitQty, D.CurAmt, D.CurVAT, B.Qty, B.STDQty,   
                       B.CurAmt, B.CurVAT, 1, 0, @UserSeq,   
                       GETDATE()  
                  FROM _TSLOrderItem AS B 
                  JOIN DTI_TSLContractMngItem AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ContractSeq = CONVERT(INT,B.Dummy6) AND C.ContractSerl = CONVERT(INT,B.Dummy7) )   
                  JOIN _TPUORDApprovalReqItem AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND CONVERT(INT,Memo3) = C.ContractSeq AND CONVERT(INT,Memo4) = C.ContractSerl ) 
                 WHERE B.CompanySeq = @CompanySeq 
                   AND B.OrderSeq = @OrderSeq 
            END
        
        END 
    END
    RETURN    
GO
begin tran 
exec DTI_SCOMConfirm @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <Confirm>1</Confirm>
    <OrderSeq>1000537</OrderSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1016041,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1001652
rollback 