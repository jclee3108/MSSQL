if object_id('KPX_TPDSFCProdPackOrderItemCust') is null

begin 
CREATE TABLE KPX_TPDSFCProdPackOrderItemCust
(
    CompanySeq		INT 	 NOT NULL, 
    PackOrderSeq		INT 	 NOT NULL, 
    PackOrderSerl		INT 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    OutDate		NCHAR(8) 	 NOT NULL, 
    ReOutDate		NCHAR(8) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL

)
create unique clustered index idx_KPX_TPDSFCProdPackOrderItemCust on KPX_TPDSFCProdPackOrderItemCust(CompanySeq,PackOrderSeq,PackOrderSerl) 
end 


if object_id('KPX_TPDSFCProdPackOrderItemCustLog') is null

begin 

CREATE TABLE KPX_TPDSFCProdPackOrderItemCustLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PackOrderSeq		INT 	 NOT NULL, 
    PackOrderSerl		INT 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    OutDate		NCHAR(8) 	 NOT NULL, 
    ReOutDate		NCHAR(8) 	 NOT NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
end 