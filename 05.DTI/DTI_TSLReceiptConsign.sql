if object_id('DTI_TSLReceiptConsign') is null 
begin
--drop table DTI_TSLReceiptConsign
    CREATE TABLE DTI_TSLReceiptConsign
    (
        CompanySeq		INT 	 NOT NULL, 
        ReceiptSeq		INT 	 NOT NULL, 
        ReceiptNo		NVARCHAR(50) 	 NOT NULL, 
        ReceiptDate		NCHAR(8) 	 NOT NULL, 
        EmpSeq		INT 	 NOT NULL, 
        DeptSeq		INT 	 NOT NULL, 
        CustSeq		INT 	 NOT NULL, 
        CurrSeq		INT 	 NOT NULL, 
        ExRate		DECIMAL(19,5) 	 NOT NULL, 
        SlipSeq		INT 	 NOT NULL, 
        OppAccSeq		INT 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )
    create unique clustered index idx_DTI_TSLReceiptConsign on DTI_TSLReceiptConsign(CompanySeq, ReceiptSeq)
end

if object_id('DTI_TSLReceiptConsignLog') is null 
begin
--Drop table DTI_TSLReceiptConsignLog
CREATE TABLE DTI_TSLReceiptConsignLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReceiptSeq		INT 	 NOT NULL, 
    ReceiptNo		NVARCHAR(50) 	 NOT NULL, 
    ReceiptDate		NCHAR(8) 	 NOT NULL, 
    EmpSeq		INT 	 NOT NULL, 
    DeptSeq		INT 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    CurrSeq		INT 	 NOT NULL, 
    ExRate		DECIMAL(19,5) 	 NOT NULL, 
    SlipSeq		INT 	 NOT NULL, 
    OppAccSeq		INT 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end


if object_id('DTI_TSLReceiptConsignDesc') is null 
begin
--Drop table DTI_TSLReceiptConsignDesc
CREATE TABLE DTI_TSLReceiptConsignDesc
(
    CompanySeq		INT 	 NOT NULL, 
    ReceiptSeq		INT 	 NOT NULL, 
    ReceiptSerl		INT 	 NOT NULL, 
    UMReceiptKind		INT 	 NOT NULL, 
    SMDrOrCr		INT 	 NOT NULL, 
    CurAmt		DECIMAL(19,5) 	 NOT NULL, 
    DomAmt		DECIMAL(19,5) 	 NOT NULL, 
    BankSeq		INT 	 NOT NULL, 
    BankAccSeq		INT 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    Remark		NVARCHAR(1000) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL 
) 
create unique clustered index idx_DTI_TSLReceiptConsignDesc on DTI_TSLReceiptConsignDesc(CompanySeq,ReceiptSeq,ReceiptSerl)
end

if object_id('DTI_TSLReceiptConsignDescLog') is null 
begin
--Drop table DTI_TSLReceiptConsignDescLog
CREATE TABLE DTI_TSLReceiptConsignDescLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReceiptSeq		INT 	 NOT NULL, 
    ReceiptSerl		INT 	 NOT NULL, 
    UMReceiptKind		INT 	 NOT NULL, 
    SMDrOrCr		INT 	 NOT NULL, 
    CurAmt		DECIMAL(19,5) 	 NOT NULL, 
    DomAmt		DECIMAL(19,5) 	 NOT NULL, 
    BankSeq		INT 	 NOT NULL, 
    BankAccSeq		INT 	 NOT NULL, 
    CustSeq		INT 	 NOT NULL, 
    Remark		NVARCHAR(1000) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end

if object_id('DTI_TSLReceiptConsignBill') is null
begin
--Drop table DTI_TSLReceiptConsignBill
CREATE TABLE DTI_TSLReceiptConsignBill
(
    CompanySeq		INT 	 NOT NULL, 
    ReceiptSeq		INT 	 NOT NULL, 
    BillSeq		INT 	 NOT NULL, 
    CurAmt		DECIMAL(19,5) 	 NOT NULL, 
    DomAmt		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
create unique clustered index idx_DTI_TSLReceiptConsignBill on DTI_TSLReceiptConsignBill(CompanySeq,ReceiptSeq,BillSeq)
end 


if object_id('DTI_TSLReceiptConsignBillLog') is null 
begin
--Drop table DTI_TSLReceiptConsignBillLog
CREATE TABLE DTI_TSLReceiptConsignBillLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ReceiptSeq		INT 	 NOT NULL, 
    BillSeq		INT 	 NOT NULL, 
    CurAmt		DECIMAL(19,5) 	 NOT NULL, 
    DomAmt		DECIMAL(19,5) 	 NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL, 
    PgmSeq		INT 	 NOT NULL
)
end