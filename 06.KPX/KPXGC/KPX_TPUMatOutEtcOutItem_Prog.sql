
if object_id('KPX_TPUMatOutEtcOutItem_Prog') is null
begin 

CREATE TABLE KPX_TPUMatOutEtcOutItem_Prog 
(   
    CompanySeq int NOT NULL,    
    FromSeq int NOT NULL,    
    FromSerl int NOT NULL,    
    FromSubSerl int NOT NULL,    
    ToTableSeq int NOT NULL,    
    ToSeq int NOT NULL,    
    ToSerl int NOT NULL,    
    ToSubSerl int NOT NULL,    
    FromQty decimal(19,5) NOT NULL,    
    FromSTDQty decimal(19,5) NOT NULL,    
    FromAmt decimal(19,5) NOT NULL,    
    FromVAT decimal(19,5) NOT NULL,    
    ToQty decimal(19,5) NOT NULL,    
    ToSTDQty decimal(19,5) NOT NULL,    
    ToAmt decimal(19,5) NOT NULL,    
    ToVAT decimal(19,5) NOT NULL,    
    IsNext int NOT NULL,    
    PrevFromTableSeq int NOT NULL
) 
CREATE CLUSTERED INDEX IDX_Clustered on KPX_TPUMatOutEtcOutItem_Prog(CompanySeq, FromSeq, FromSerl, FromSubSerl)
CREATE UNIQUE INDEX IDX_Unique on KPX_TPUMatOutEtcOutItem_Prog(CompanySeq, FromSeq, FromSerl, FromSubSerl, ToTableSeq, ToSeq, ToSerl, ToSubSerl)
end 

