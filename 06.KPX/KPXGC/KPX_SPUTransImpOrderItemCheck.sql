  
IF OBJECT_ID('KPX_SPUTransImpOrderItemCheck') IS NOT NULL   
    DROP PROC KPX_SPUTransImpOrderItemCheck  
GO  
  
-- v2014.11.28  
  
-- 수입운송지시- 품목 체크 by 이재천   
CREATE PROC KPX_SPUTransImpOrderItemCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250), 
            @Serl           INT  
    
    CREATE TABLE #KPX_TPUTransImpOrderItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TPUTransImpOrderItem'   
    IF @@ERROR <> 0 RETURN     
    
    
    -- 순번 따기
    SELECT @Serl = MAX(TransImpSerl) 
      FROM KPX_TPUTransImpOrderItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.TransImpSeq = (SELECT TOP 1 TransImpSeq FROM #KPX_TPUTransImpOrderItem WHERE WorkingTag = 'A')
    
    UPDATE A 
       SET TransImpSerl = ISNULL(@Serl,0) + DataSeq 
      FROM #KPX_TPUTransImpOrderItem AS A 
     WHERE A.Status = 0 
       AND A.WorkingTag = 'A' 
    
    SELECT * FROM #KPX_TPUTransImpOrderItem   
      
    RETURN  
GO 
BEGIN TRAN 
exec KPX_SPUTransImpOrderItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <TransImpSeq>1</TransImpSeq>
    <TransImpSerl>0</TransImpSerl>
    <Spec />
    <Price>0</Price>
    <Qty>0</Qty>
    <UMPacking>0</UMPacking>
    <CurAmt>0</CurAmt>
    <DomPrice>0</DomPrice>
    <DomAmt>0</DomAmt>
    <TransDate>20141111</TransDate>
    <Remark />
    <STDQty>0</STDQty>
    <LotNo />
    <BLSeq />
    <BLSerl />
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <TransImpSeq>1</TransImpSeq>
    <TransImpSerl>0</TransImpSerl>
    <Spec />
    <Price>0</Price>
    <Qty>0</Qty>
    <UMPacking>0</UMPacking>
    <CurAmt>0</CurAmt>
    <DomPrice>0</DomPrice>
    <DomAmt>0</DomAmt>
    <TransDate>20141111</TransDate>
    <Remark />
    <STDQty>0</STDQty>
    <LotNo />
    <BLSeq />
    <BLSerl />
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026300,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021338
rollback 