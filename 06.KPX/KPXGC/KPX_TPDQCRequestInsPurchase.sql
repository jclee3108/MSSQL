if object_id('KPX_TPDQCRequestInsPurchase') is null 
begin 
CREATE TABLE KPX_TPDQCRequestInsPurchase
(
    CompanySeq		INT 	 NOT NULL, 
    PurQCReqSeq		INT 	 NOT NULL, 
    PurQCReqNo		NVARCHAR(100) 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    UMImpType		INT 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    DelvDate		NCHAR(8) 	 NOT NULL, 
    DelvNo		NVARCHAR(100) 	 NOT NULL, 
    QCReqDate		NCHAR(8) 	 NOT NULL, 
    QCReqEmpSeq		INT 	 NOT NULL, 
    QCReqDeptSeq		INT 	 NOT NULL, 
    LotNo		NVARCHAR(100) 	 NOT NULL, 
    ReqQty		DECIMAL(19,5) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NOT NULL, 
    DelvSeq     INT             NOT NULL, 
    DelvSerl    INT             NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL 
)
create unique clustered index idx_KPX_TPDQCRequestInsPurchase on KPX_TPDQCRequestInsPurchase(CompanySeq,PurQCReqSeq) 
end 

if object_id('KPX_TPDQCRequestInsPurchaseLog') is null
begin 
CREATE TABLE KPX_TPDQCRequestInsPurchaseLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PurQCReqSeq		INT 	 NOT NULL, 
    PurQCReqNo		NVARCHAR(100) 	 NOT NULL, 
    BizUnit		INT 	 NOT NULL, 
    UMImpType		INT 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    ItemSeq		INT 	 NOT NULL, 
    DelvDate		NCHAR(8) 	 NOT NULL, 
    DelvNo		NVARCHAR(100) 	 NOT NULL, 
    QCReqDate		NCHAR(8) 	 NOT NULL, 
    QCReqEmpSeq		INT 	 NOT NULL, 
    QCReqDeptSeq		INT 	 NOT NULL, 
    LotNo		NVARCHAR(100) 	 NOT NULL, 
    ReqQty		DECIMAL(19,5) 	 NOT NULL, 
    Remark		NVARCHAR(2000) 	 NOT NULL, 
    DelvSeq     INT             NOT NULL, 
    DelvSerl    INT             NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 


