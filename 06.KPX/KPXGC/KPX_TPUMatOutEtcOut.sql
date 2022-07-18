
if object_id('KPX_TPUMatOutEtcOut') is null
begin 
CREATE TABLE KPX_TPUMatOutEtcOut 
(   
    CompanySeq int NOT NULL,    
    InOutType int NOT NULL,    
    InOutSeq int NOT NULL,    
    BizUnit int NOT NULL,   
    InOutNo nvarchar(30) NULL   ,   
    FactUnit int NOT NULL,   
    ReqBizUnit int NOT NULL,   
    DeptSeq int NOT NULL,    
    EmpSeq int NOT NULL,    
    InOutDate nchar(8) NOT NULL,   
    WCSeq int NOT NULL,    
    ProcSeq int NOT NULL,    
    CustSeq int NOT NULL,   
    OutWHSeq int NOT NULL,    
    InWHSeq int NOT NULL,    
    DVPlaceSeq int NOT NULL,    
    IsTrans nchar(1) NOT NULL,   
    IsCompleted nchar(1) NOT NULL,   
    CompleteDeptSeq int NOT NULL,   
    CompleteEmpSeq int NOT NULL,    
    CompleteDate nchar(8) NOT NULL,  
    InOutDetailType int NOT NULL, 
    Remark nvarchar(1000) NULL   ,   
    Memo nvarchar(1000) NULL   ,   
    WOReqSeq    INT NOT NULL, 
    IsBatch nchar(1) NULL   ,   
    LastUserSeq int NULL   , 
    LastDateTime datetime NULL   ,  
    UseDeptSeq int NULL   ,   
    PgmSeq int NULL   
) 
CREATE UNIQUE CLUSTERED INDEX IDXTempKPX_TPUMatOutEtcOut on KPX_TPUMatOutEtcOut(CompanySeq, InOutType, InOutSeq)
end 


if object_id('KPX_TPUMatOutEtcOutLog') is null
begin
CREATE TABLE KPX_TPUMatOutEtcOutLog 
(   
    LogSeq int identity NOT NULL,    
    LogUserSeq int NOT NULL,    
    LogDateTime datetime NOT NULL,   
    LogType nchar(1) NOT NULL,   
    CompanySeq int NOT NULL,  
    InOutType int NOT NULL,    
    InOutSeq int NOT NULL,    
    BizUnit int NOT NULL,   
    InOutNo nvarchar(30) NULL   ,    
    FactUnit int NOT NULL,    
    ReqBizUnit int NOT NULL,   
    DeptSeq int NOT NULL,    
    EmpSeq int NOT NULL,    
    InOutDate nchar(8) NOT NULL,   
    WCSeq int NOT NULL,   
    ProcSeq int NOT NULL,    
    CustSeq int NOT NULL,    
    OutWHSeq int NOT NULL,    
    InWHSeq int NOT NULL,    
    DVPlaceSeq int NOT NULL,   
    IsTrans nchar(1) NOT NULL,    
    IsCompleted nchar(1) NOT NULL,  
    CompleteDeptSeq int NOT NULL,   
    CompleteEmpSeq int NOT NULL,  
    CompleteDate nchar(8) NOT NULL,   
    InOutDetailType int NOT NULL,   
    Remark nvarchar(1000) NULL   ,   
    Memo nvarchar(1000) NULL   ,  
    WOReqSeq    INT NOT NULL, 
    IsBatch nchar(1) NULL   ,   
    LastUserSeq int NULL   ,    
    LastDateTime datetime NULL   ,  
    UseDeptSeq int NULL   ,    
    LogPgmSeq int NULL   ,    
    PgmSeq int NULL   
) 
CREATE UNIQUE CLUSTERED INDEX TPKKPX_TPUMatOutEtcOutLog on KPX_TPUMatOutEtcOutLog(LogSeq)
end 