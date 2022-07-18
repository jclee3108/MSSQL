
if object_id('KPX_TPUMatOutEtcOutItemSub') is null
begin 
CREATE TABLE KPX_TPUMatOutEtcOutItemSub 
(   
CompanySeq int NOT NULL,    
InOutType int NOT NULL,    
InOutSeq int NOT NULL,   
InOutSerl int NOT NULL,    
DataKind int NOT NULL,   
InOutDataSerl int NOT NULL,    
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
LastUserSeq int NULL   ,   
LastDateTime datetime NULL   ,    
PgmSeq int NULL  
)
CREATE UNIQUE CLUSTERED INDEX IDXTempKPX_TPUMatOutEtcOutItemSub on KPX_TPUMatOutEtcOutItemSub(CompanySeq, InOutType, InOutSeq, InOutSerl, DataKind, InOutDataSerl)
end 

if object_id('KPX_TPUMatOutEtcOutItemSubLog') is null
begin
CREATE TABLE KPX_TPUMatOutEtcOutItemSubLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,   
    LogType nchar(1) NOT NULL,   
    CompanySeq int NOT NULL,    
    InOutType int NOT NULL,    
    InOutSeq int NOT NULL,    
    InOutSerl int NOT NULL,   
    DataKind int NOT NULL,    
    InOutDataSerl int NOT NULL,   
    ItemSeq int NOT NULL,    
    InOutRemark nvarchar(200) NOT NULL,   
    CCtrSeq int NOT NULL,   
    DVPlaceSeq int NOT NULL,    
    InWHSeq int NOT NULL,    
    OutWHSeq int NOT NULL,    
    UnitSeq int NOT NULL,    
    Qty decimal(19,5) NOT NULL,   
    STDQty decimal(19,5) NOT NULL,    
    Amt decimal(19,5) NOT NULL,    
    EtcOutAmt decimal(19,5) NOT NULL,   
    EtcOutVAT decimal(19,5) NOT NULL,    
    InOutKind int NOT NULL,    
    InOutDetailKind int NOT NULL,   
    LotNo nvarchar(30) NOT NULL,   
    SerialNo nvarchar(30) NOT NULL, 
    LastUserSeq int NULL   , 
    LastDateTime datetime NULL   ,  
    LogPgmSeq int NULL   ,  
    PgmSeq int NULL   
) 
CREATE UNIQUE CLUSTERED INDEX TPKKPX_TPUMatOutEtcOutItemSubLog on KPX_TPUMatOutEtcOutItemSubLog(LogSeq)
end 

