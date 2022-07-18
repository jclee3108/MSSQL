if object_id('KPX_TPUMatOutEtcOutItem_Source') is null
begin 
CREATE TABLE KPX_TPUMatOutEtcOutItem_Source 
(   
    CompanySeq int NOT NULL,    
    ToSeq int NOT NULL,   
    ToSerl int NOT NULL,    
    ToSubSerl int NOT NULL,   
    FromTableSeq int NOT NULL,    
    FromSeq int NOT NULL,   
    FromSerl int NOT NULL,   
    FromSubSerl int NOT NULL,   
    ToQty decimal(19,5) NOT NULL,   
    ToSTDQty decimal(19,5) NOT NULL,  
    ToAmt decimal(19,5) NOT NULL,    
    ToVAT decimal(19,5) NOT NULL, 
    FromQty decimal(19,5) NOT NULL,    
    FromSTDQty decimal(19,5) NOT NULL,  
    FromAmt decimal(19,5) NOT NULL,   
    FromVAT decimal(19,5) NOT NULL
) 
CREATE CLUSTERED INDEX IDX_Clustered on KPX_TPUMatOutEtcOutItem_Source(CompanySeq, ToSeq, ToSerl, ToSubSerl)
end 