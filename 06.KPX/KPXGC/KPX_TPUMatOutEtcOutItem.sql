

if object_id('KPX_TPUMatOutEtcOutItem') is null
begin 
CREATE TABLE KPX_TPUMatOutEtcOutItem 
(   
    CompanySeq int NOT NULL,    
    InOutType int NOT NULL,    
    InOutSeq int NOT NULL,    
    InOutSerl int NOT NULL,    
    ItemSeq int NOT NULL,    
    InOutRemark nvarchar(200) NULL   ,    
    CCtrSeq int NULL   ,    
    DVPlaceSeq int NULL   ,   
    InWHSeq int NULL   ,   
    OutWHSeq int NULL   ,  
    UnitSeq int NULL   ,  
    Qty decimal(19,5) NULL   ,   
    STDQty decimal(19,5) NULL   ,    
    Amt decimal(19,5) NULL   ,  
    EtcOutAmt decimal(19,5) NULL   ,  
    EtcOutVAT decimal(19,5) NULL   ,  
    InOutKind int NULL   ,   
    InOutDetailKind int NULL   ,  
    LotNo nvarchar(30) NULL   ,    
    SerialNo nvarchar(30) NULL   ,    
    IsStockSales nchar(1) NULL   ,  
    OriUnitSeq int NULL   ,   
    OriItemSeq int NULL   ,    
    OriQty decimal(19,5) NULL   ,    
    OriSTDQty decimal(19,5) NULL   ,   
    LastUserSeq int NULL   ,  
    LastDateTime datetime NULL   ,   
    PJTSeq int NULL   ,  
    OriLotNo nvarchar(30) NULL   ,  
    ProgFromSeq int NULL   ,   
    ProgFromSerl int NULL   ,   
    ProgFromSubSerl int NULL   ,  
    ProgFromTableSeq int NULL   ,  
    PgmSeq int NULL   ,  
    Dummy1 nvarchar(100) NULL   ,  
    Dummy6 decimal(19,5) NULL   
) 
CREATE UNIQUE CLUSTERED INDEX IDXTempKPX_TPUMatOutEtcOutItem on KPX_TPUMatOutEtcOutItem(CompanySeq, InOutType, InOutSeq, InOutSerl)

end 


if object_id('KPX_TPUMatOutEtcOutItemLog') is null
begin

CREATE TABLE KPX_TPUMatOutEtcOutItemLog 
(   
    LogSeq int identity NOT NULL,   
    LogUserSeq int NOT NULL,  
    LogDateTime datetime NOT NULL,    
    LogType nchar(1) NOT NULL,    
    CompanySeq int NOT NULL,   
    InOutType int NOT NULL,   
    InOutSeq int NOT NULL,    
    InOutSerl int NOT NULL,    
    ItemSeq int NULL   ,   
    InOutRemark nvarchar(200) NULL   ,  
    CCtrSeq int NULL   ,    
    DVPlaceSeq int NULL   ,   
    InWHSeq int NULL   ,    
    OutWHSeq int NULL   ,   
    UnitSeq int NULL   ,   
    Qty decimal(19,5) NULL   ,   
    STDQty decimal(19,5) NULL   ,   
    Amt decimal(19,5) NULL   ,   
    EtcOutAmt decimal(19,5) NULL   ,  
    EtcOutVAT decimal(19,5) NULL   ,   
    InOutKind int NULL   ,   
    InOutDetailKind int NULL   ,   
    LotNo nvarchar(30) NULL   ,    
    SerialNo nvarchar(30) NULL   ,    
    IsStockSales nchar(1) NULL   ,   
    OriUnitSeq int NULL   ,    
    OriItemSeq int NULL   ,    
    OriQty decimal(19,5) NULL   ,   
    OriSTDQty decimal(19,5) NULL   ,   
    LastUserSeq int NULL   ,   
    LastDateTime datetime NULL   ,   
    PJTSeq int NULL   ,   
    OriLotNo nvarchar(30) NULL   ,  
    LogPgmSeq int NULL   ,    
    ProgFromSeq int NULL   ,    
    ProgFromSerl int NULL   ,   
    ProgFromSubSerl int NULL   ,    
    ProgFromTableSeq int NULL   ,   
    PgmSeq int NULL   ,   
    Dummy1 nvarchar(100) NULL   ,  
    Dummy6 decimal(19,5) NULL  
) 

CREATE UNIQUE CLUSTERED INDEX TPKKPX_TPUMatOutEtcOutItemLog on KPX_TPUMatOutEtcOutItemLog(LogSeq)
end 

