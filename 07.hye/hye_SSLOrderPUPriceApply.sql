IF OBJECT_ID('hye_SSLOrderPUPriceApply') IS NOT NULL   
    DROP PROC hye_SSLOrderPUPriceApply  
GO  
  
-- v2016.12.23
  
-- 주문등록_hye-매입단가적용 by 이재천 
CREATE PROC hye_SSLOrderPUPriceApply  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
    
    CREATE TABLE #PUPrice (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#PUPrice'   
    IF @@ERROR <> 0 RETURN    
    

    CREATE TABLE #TPUSheetData_Result
    (      
        IDX_NO          INT, 
        CustSeq         INT, 
        CustName        NVARCHAR(100), 
        MakerSeq        INT, 
        MakerName       NVARCHAR(100), 
        SMImpType       INT, 
        SMImpTypeName   NVARCHAR(100), 
        SMInOutType     INT, 
        SMInOutTypeName NVARCHAR(100), 
        CurrSeq         INT, 
        CurrName        NVARCHAR(100), 
        Price           DECIMAl(19,5), 
        STDUnitQty      DECIMAl(19,5), 
        StdConvQty      DECIMAl(19,5), 
        MinQty          DECIMAl(19,5), 
        StepQty         DECIMAl(19,5), 
        SMQcType        INT, 
        SMQcTypeName    NVARCHAR(100), 
        WHSeq           INT,  
        WHName          NVARCHAR(100), 
        ExRate          DECIMAL(19,5), 
        AssetSeq        INT, 
        LeadTime        DECIMAL(19,5), 
        PUUnitSeq       INT, 
        UnitSeq         INT, 
        PUUnitName      NVARCHAR(100), 
        UnitName        NVARCHAR(100), 
        ReqUnitSeq      INT
    )      
    

    DECLARE @XmlData NVARCHAR(MAX) 

    SELECT @XmlData = CONVERT(NVARCHAR(MAX),(              
                                                SELECT WorkingTag, 
                                                       IDX_NO, 
                                                       DataSeq, 
                                                       Status, 
                                                       BizUnit, 
                                                       DelvPrice AS Price, 
                                                       STDUnitSeq, 
                                                       ItemSeq, 
                                                       UnitSeq, 
                                                       UMDVGroupSeq AS Memo2, 
                                                       PUCustSeq AS CustSeq, 
                                                       CurrSeq, 
                                                       'Delivery' AS PUType, 
                                                       OrderDate AS Date 
                                                  FROM #PUPrice              
                                                  FOR XML RAW ('DataBlock1'), ROOT('ROOT'), ELEMENTS              
                                        ))        

    INSERT INTO #TPUSheetData_Result
    exec hye_SPUBaseGetPrice 
        @xmlDocument = @XmlData,
        @xmlFlags = 2,
        @ServiceSeq = 77730170,
        @WorkingTag = N'',
        @CompanySeq = @CompanySeq,
        @LanguageSeq = @LanguageSeq,
        @UserSeq = @UserSeq,
        @PgmSeq = @PgmSeq 
    
    
    UPDATE A
       SET DelvPrice = B.Price 
      FROM #PUPrice AS A 
      JOIN #TPUSheetData_Result AS B ON ( B.IDX_NO = A.IDX_NO ) 
    
    SELECT * FROM #PUPrice 
    
    RETURN  
GO
begin tran 
exec hye_SSLOrderPUPriceApply @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsDirect>1</IsDirect>
    <PUCustSeq>40</PUCustSeq>
    <DelvPrice>0</DelvPrice>
    <UMDVGroupSeq>1013554001</UMDVGroupSeq>
    <UnitSeq>1</UnitSeq>
    <STDUnitSeq>1</STDUnitSeq>
    <ItemSeq>226</ItemSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <CurrSeq>1</CurrSeq>
    <BizUnit>1</BizUnit>
    <OrderDate>20161223</OrderDate>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <IsDirect>1</IsDirect>
    <PUCustSeq>39</PUCustSeq>
    <DelvPrice>0</DelvPrice>
    <UMDVGroupSeq>1013554002</UMDVGroupSeq>
    <UnitSeq>1</UnitSeq>
    <STDUnitSeq>1</STDUnitSeq>
    <ItemSeq>226</ItemSeq>
    <CurrSeq>1</CurrSeq>
    <BizUnit>1</BizUnit>
    <OrderDate>20161223</OrderDate>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730075,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730006
rollback 