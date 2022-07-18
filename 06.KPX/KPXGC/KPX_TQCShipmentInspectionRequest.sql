if object_id('KPX_TQCShipmentInspectionRequest') is null
begin 
CREATE TABLE KPX_TQCShipmentInspectionRequest
(
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq		INT 	 NOT NULL, 
    ReqDate		NCHAR(8) 	 NOT NULL, 
    ReqNo		NVARCHAR(100) 	 NOT NULL, 
    QCType		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    LotNo		NVARCHAR(100) 	 NOT NULL, 
    Qty		DECIMAL(19,5) 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    CustSeq		INT 	 NULL, 
    EmpSeq		INT 	 NULL, 
    DeptSeq		INT 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    IsStop		NCHAR(1) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TQCShipmentInspectionRequest on KPX_TQCShipmentInspectionRequest(CompanySeq,ReqSeq) 
end 

if object_id('KPX_TQCShipmentInspectionRequestLog') is null
begin 
CREATE TABLE KPX_TQCShipmentInspectionRequestLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReqSeq		INT 	 NOT NULL, 
    ReqDate		NCHAR(8) 	 NOT NULL, 
    ReqNo		NVARCHAR(100) 	 NOT NULL, 
    QCType		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    LotNo		NVARCHAR(100) 	 NOT NULL, 
    Qty		DECIMAL(19,5) 	 NOT NULL, 
    UnitSeq		INT 	 NOT NULL, 
    CustSeq		INT 	 NULL, 
    EmpSeq		INT 	 NULL, 
    DeptSeq		INT 	 NULL, 
    Remark		NVARCHAR(2000) 	 NULL, 
    IsStop		NCHAR(1) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 