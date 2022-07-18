  
IF OBJECT_ID('KPX_SPUTransImpOrderItemSave') IS NOT NULL   
    DROP PROC KPX_SPUTransImpOrderItemSave  
GO  
  
-- v2014.11.28 
  
-- 수입운송지시- 품목 저장 by 이재천   
CREATE PROC KPX_SPUTransImpOrderItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #KPX_TPUTransImpOrderItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TPUTransImpOrderItem'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
    
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPUTransImpOrderItem')    
    
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPUTransImpOrderItem'    , -- 테이블명        
                  '#KPX_TPUTransImpOrderItem'    , -- 임시 테이블명        
                  'TransImpSeq,TransImpSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPUTransImpOrderItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #KPX_TPUTransImpOrderItem AS A   
          JOIN KPX_TPUTransImpOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND A.TransImpSeq = B.TransImpSeq AND A.TransImpSerl = B.TransImpSerl ) 
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPUTransImpOrderItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.ItemSeq      = A.ItemSeq    ,
               B.UnitSeq      = A.UnitSeq    ,
               B.Qty          = A.Qty        ,
               B.Price        = A.Price      ,
               B.CurAmt       = A.CurAmt     ,
               B.DomAmt       = A.DomAmt     ,
               B.MakerSeq     = A.MakerSeq   ,
               B.Remark       = A.Remark     ,
               B.STDUnitSeq   = A.STDUnitSeq ,
               B.STDQty       = A.STDQty      ,      
               B.LotNo        = A.LotNo      ,
               B.UMPacking    = A.UMPacking   ,  
               B.TransDate    = A.TransDate  ,
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE()
        
          FROM #KPX_TPUTransImpOrderItem AS A   
          JOIN KPX_TPUTransImpOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND A.TransImpSeq = B.TransImpSeq AND A.TransImpSerl = B.TransImpSerl ) 
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
        
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPUTransImpOrderItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        
        INSERT INTO KPX_TPUTransImpOrderItem  
        (   
            CompanySeq,TransImpSeq,TransImpSerl,ItemSeq,UnitSeq,
            Qty,Price,CurAmt,DomAmt,MakerSeq,
            Remark,STDUnitSeq,STDQty,LotNo,UMPacking,
            TransDate,BLSeq,BLSerl,LastUserSeq,LastDateTime
        )   
        SELECT @CompanySeq, A.TransImpSeq, A.TransImpSerl, A.ItemSeq, A.UnitSeq,
               A.Qty, A.Price, A.CurAmt, A.DomAmt, A.MakerSeq,
               A.Remark, A.STDUnitSeq, A.STDQty, A.LotNo, A.UMPacking,
               A.TransDate, A.BLSeq, A.BLSerl, @UserSeq, GETDATE()
               
          FROM #KPX_TPUTransImpOrderItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
    
    SELECT * FROM #KPX_TPUTransImpOrderItem   
      
    RETURN  
GO 
begin tran 
exec KPX_SPUTransImpOrderItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BLSeq>0</BLSeq>
    <BLSerl>0</BLSerl>
    <CurAmt>392.00000</CurAmt>
    <DomAmt>392.00000</DomAmt>
    <DomPrice>56.00000</DomPrice>
    <ItemSeq>1001446</ItemSeq>
    <LotNo />
    <MakerSeq>0</MakerSeq>
    <Price>56.00000</Price>
    <Qty>7.00000</Qty>
    <Remark />
    <Spec />
    <STDQty>7.00000</STDQty>
    <TransDate>20141111</TransDate>
    <TransImpSeq>3</TransImpSeq>
    <TransImpSerl>3</TransImpSerl>
    <UMPacking>0</UMPacking>
    <UnitSeq>2</UnitSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026300,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021338

select * From KPX_TPUTransImpOrderItem
rollback 