  
IF OBJECT_ID('KPXGC_SPDSFCProdPackOrderItemCheck') IS NOT NULL   
    DROP PROC KPXGC_SPDSFCProdPackOrderItemCheck  
GO  
  
-- v2015.08.18  
  
-- 포장작업지시입력(공정)-품목체크 by 이재천  
CREATE PROC KPXGC_SPDSFCProdPackOrderItemCheck  
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
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #KPX_TPDSFCProdPackOrderItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPX_TPDSFCProdPackOrderItem'   
    IF @@ERROR <> 0 RETURN     
    
    -- 데이터유무체크: UPDATE, DELETE시 데이터 존해하지 않으면 에러처리  
    IF NOT EXISTS ( SELECT 1   
                      FROM #KPX_TPDSFCProdPackOrderItem AS A   
                      JOIN KPX_TPDSFCProdPackOrderItem AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.PackOrderSeq = B.PackOrderSeq AND A.PackOrderSerl = B.PackOrderSerl )  
                     WHERE A.WorkingTag IN ( 'U', 'D' )  
                       AND Status = 0   
                  )  
    BEGIN  
        EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                              @Status      OUTPUT,  
                              @Results     OUTPUT,  
                              7                  , -- 자료가등록되어있지않습니다.(SELECT * FROM _TCAMessageLanguage WHERE MessageSeq = 7)  
                              @LanguageSeq               
          
        UPDATE #KPX_TPDSFCProdPackOrderItem  
           SET Result       = @Results,  
               MessageType  = @MessageType,  
               Status       = @Status  
         WHERE WorkingTag IN ( 'U', 'D' )  
           AND Status = 0   
    END   
    
    -- 체크1, 확정 된 데이터는 삭제 할 수 없습니다. 
    UPDATE A 
       SET Result       = ' 확정 된 데이터는 삭제 할 수 없습니다.',  
           MessageType  = 1234,  
           Status       = 1234 
      FROM #KPX_TPDSFCProdPackOrderItem AS A 
      LEFT OUTER JOIN KPX_TPDSFCProdPackOrder_Confirm AS B ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.PackOrderSeq ) 
     WHERE B.CfmCode = '1'  
       AND A.Status = 0 
       AND A.WorkingTag = 'D' 
    
    -- 순번 따기 :           
    DECLARE @Serl           INT, 
            @PackOrderSeq   INT 
    
    SELECT @PackOrderSeq = (SELECT TOP 1 PackOrderSeq FROM #KPX_TPDSFCProdPackOrderItem WHERE Status = 0 AND WorkingTag = 'A')
       --    -- 키값생성코드부분 시작  
    SELECT @Serl = ISNULL((SELECT MAX( PackOrderSerl ) FROM KPX_TPDSFCProdPackOrderItem AS A WHERE CompanySeq = @CompanySeq AND PackOrderSeq = @PackOrderSeq),0)
    
    -- Temp Talbe 에 생성된 순번 업데이트 
        UPDATE #KPX_TPDSFCProdPackOrderItem  
           SET PackOrderSerl = @Serl + DataSeq  
         WHERE WorkingTag = 'A'  
           AND Status = 0  
    
    SELECT * FROM #KPX_TPDSFCProdPackOrderItem   
      
    RETURN  
GO 
begin tran 
exec KPXGC_SPDSFCProdPackOrderItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsStop>0</IsStop>
    <ItemName>@asdfasdfasdf</ItemName>
    <ItemNo>DYC001Yong</ItemNo>
    <ItemSeq>14527</ItemSeq>
    <UnitName>Kg</UnitName>
    <UnitSeq>2</UnitSeq>
    <WorkOrderNo />
    <SourceSeq>0</SourceSeq>
    <SourceSerl>0</SourceSerl>
    <CustSeq>0</CustSeq>
    <CustName />
    <SameName />
    <OrderQty>1</OrderQty>
    <PackUnitName>Kg</PackUnitName>
    <PackUnitSeq>2</PackUnitSeq>
    <LotNo />
    <IsBase>0</IsBase>
    <UMDMMarkingName />
    <UMDMMarking>0</UMDMMarking>
    <OutLotNo>3</OutLotNo>
    <QCLotNo>4</QCLotNo>
    <PackingDate>20150802</PackingDate>
    <PackOnDate />
    <IsReUse>0</IsReUse>
    <PackReOnDate />
    <Remark />
    <HamBa />
    <BrandName />
    <GHS />
    <SubItemName>초코렛용기</SubItemName>
    <SubItemNo />
    <SubSpec />
    <SubUnitName>Kg</SubUnitName>
    <SubItemSeq>1051292</SubItemSeq>
    <SubUnitSeq>2</SubUnitSeq>
    <PackingQty>0</PackingQty>
    <PackingLocation />
    <SubQty>0</SubQty>
    <NonMarking />
    <PopInfo />
    <PackOrderSeq>157</PackOrderSeq>
    <PackOrderSerl>0</PackOrderSerl>
    <TankName />
    <TankSeq>0</TankSeq>
    <OutWHSeq>0</OutWHSeq>
    <OutWHName />
    <InWHSeq>0</InWHSeq>
    <InWHName />
    <SubOutWHSeq>0</SubOutWHSeq>
    <SubOutWHName />
    <IsCS>0</IsCS>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031473,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026201
rollback 