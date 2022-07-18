  
IF OBJECT_ID('KPXGC_SPDSFCProdPackOrderItemSave') IS NOT NULL   
    DROP PROC KPXGC_SPDSFCProdPackOrderItemSave  
GO  
  
-- v2015.08.18  
  
-- 포장작업지시입력(공정)-품목 저장 by 이재천  
CREATE PROC KPXGC_SPDSFCProdPackOrderItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPX_TPDSFCProdPackOrderItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TPDSFCProdPackOrderItem'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TPDSFCProdPackOrderItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPX_TPDSFCProdPackOrderItem'    , -- 테이블명        
                  '#KPX_TPDSFCProdPackOrderItem'    , -- 임시 테이블명        
                  'PackOrderSeq,PackOrderSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDSFCProdPackOrderItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #KPX_TPDSFCProdPackOrderItem AS A   
          JOIN KPX_TPDSFCProdPackOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND A.PackOrderSeq = B.PackOrderSeq AND A.PackOrderSerl = B.PackOrderSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDSFCProdPackOrderItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.ItemSeq         = A.ItemSeq        ,  
               B.UnitSeq         = A.UnitSeq        ,  
               B.OrderQty        = A.OrderQty       ,  
               B.LotNo           = A.LotNo          ,  
               B.UMDMMarking     = A.UMDMMarking    ,  
               B.OutLotNo        = A.OutLotNo       ,  
               B.PackOnDate      = A.PackOnDate     ,  
               B.PackReOnDate    = A.PackReOnDate   ,  
               B.Remark          = A.Remark         ,  
               B.SubItemSeq      = A.SubItemSeq     ,  
               B.SubUnitSeq      = A.SubUnitSeq     ,  
               B.SubQty          = A.SubQty         ,  
               B.NonMarking      = A.NonMarking     ,  
               B.PopInfo         = A.PopInfo        ,  
               B.IsStop          = A.IsStop         ,  
               B.LastUserSeq     = @UserSeq         ,  
               B.LastDateTime    = GETDATE()        ,  
               B.PackingQty      = A.PackingQty     ,  
               B.QCLotNo         = A.QCLotNo        ,  
               B.PackingLocation = A.PackingLocation,  
               B.PackingDate     = A.PackingDate    ,  
               B.TankSeq         = A.TankSeq        ,  
               B.CustSeq         = A.CustSeq        ,  
               B.SameName        = A.SameName       , 
               B.OutWHSeq        = A.OutWHSeq       , 
               B.InWHSeq         = A.InWHSeq        , 
               B.SubOutWHSeq     = A.SubOutWHSeq    , 
               B.IsReUse         = A.IsReUse        , 
               B.IsBase          = A.IsBase         , 
               B.PackUnitSeq     = A.PackUnitSeq    
          FROM #KPX_TPDSFCProdPackOrderItem AS A   
          JOIN KPX_TPDSFCProdPackOrderItem AS B ON ( B.CompanySeq = @CompanySeq AND A.PackOrderSeq = B.PackOrderSeq AND A.PackOrderSerl = B.PackOrderSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    
    DECLARE @WorkCenterSeq  INT 
    SELECT @WorkCenterSeq = (SELECT EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 12 AND EnvSerl = 1) 
    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TPDSFCProdPackOrderItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPX_TPDSFCProdPackOrderItem  
        (   
            CompanySeq, PackOrderSeq, PackOrderSerl, ItemSeq, UnitSeq, 
            OrderQty, LotNo, UMDMMarking, OutLotNo, PackOnDate, 
            PackReOnDate, Remark, SubItemSeq, SubUnitSeq, SubQty, 
            NonMarking, PopInfo, IsStop, WorkCenterSeq, LastUserSeq, 
            LastDateTime, PackingQty, QCLotNo, PackingLocation, PackingDate, 
            IsPurchase, PurchaseRemark, TankSeq, CustSeq, SameName,
            OutWHSeq, InWHSeq, SubOutWHSeq, IsReUse, IsBase, 
            SourceSeq, SourceSerl, PackUnitSeq
        )   
        SELECT @CompanySeq, A.PackOrderSeq, A.PackOrderSerl, A.ItemSeq, A.UnitSeq, 
               A.OrderQty, A.LotNo, A.UMDMMarking, A.OutLotNo, A.PackOnDate, 
               A.PackReOnDate, A.Remark, A.SubItemSeq, A.SubUnitSeq, A.SubQty, 
               A.NonMarking, A.PopInfo, A.IsStop, ISNULL(@WorkCenterSeq,0), @UserSeq, 
               GETDATE(), A.PackingQty, A.QCLotNo, A.PackingLocation, A.PackingDate, 
               '0', '', A.TankSeq, A.CustSeq, A.SameName, 
               A.OutWHSeq, A.InWHSeq, A.SubOutWHSeq, A.IsReUse, A.IsBase, 
               A.SourceSeq, A.SourceSerl, A.PackUnitSeq
          FROM #KPX_TPDSFCProdPackOrderItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPX_TPDSFCProdPackOrderItem   
      
    RETURN  
GO 

BEGIN TRAN 
exec KPXGC_SPDSFCProdPackOrderItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <BrandName>234234</BrandName>
    <CustName />
    <CustSeq>0</CustSeq>
    <GHS>342342</GHS>
    <HamBa />
    <InWHName>대황상사</InWHName>
    <InWHSeq>2</InWHSeq>
    <IsBase>0</IsBase>
    <IsCS>0</IsCS>
    <IsReUse>0</IsReUse>
    <IsStop>0</IsStop>
    <ItemName>@Cathode내부개발</ItemName>
    <ItemNo>DYC001Yong</ItemNo>
    <ItemSeq>13489</ItemSeq>
    <LotNo />
    <NonMarking>무마킹</NonMarking>
    <OrderQty>1.00000</OrderQty>
    <OutLotNo>출하LotNo</OutLotNo>
    <OutWHName>케이비엠d</OutWHName>
    <OutWHSeq>1</OutWHSeq>
    <PackingDate>20150811</PackingDate>
    <PackingLocation>포장장소</PackingLocation>
    <PackingQty>0.00000</PackingQty>
    <PackOnDate xml:space="preserve">        </PackOnDate>
    <PackOrderSeq>159</PackOrderSeq>
    <PackOrderSerl>1</PackOrderSerl>
    <PackReOnDate xml:space="preserve">        </PackReOnDate>
    <PackUnitName>Kg</PackUnitName>
    <PackUnitSeq>2</PackUnitSeq>
    <PopInfo />
    <QCLotNo>검사LotNo</QCLotNo>
    <Remark>비고</Remark>
    <SameName />
    <SourceSeq>0</SourceSeq>
    <SourceSerl>0</SourceSerl>
    <SubItemName>초코렛용기</SubItemName>
    <SubItemNo />
    <SubItemSeq>1051292</SubItemSeq>
    <SubOutWHName>가람그룹외주창고</SubOutWHName>
    <SubOutWHSeq>3</SubOutWHSeq>
    <SubQty>0.00000</SubQty>
    <SubSpec />
    <SubUnitName>Kg</SubUnitName>
    <SubUnitSeq>2</SubUnitSeq>
    <TankName>탱크</TankName>
    <TankSeq>2</TankSeq>
    <UMDMMarking>1010344001</UMDMMarking>
    <UMDMMarkingName>표기</UMDMMarkingName>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <WorkOrderNo />
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031473,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026201
rollback 