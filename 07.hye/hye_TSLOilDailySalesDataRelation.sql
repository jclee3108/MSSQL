if object_id('hye_TSLOilDailySalesDataRelation') is null

begin 
--drop table hye_TSLOilDailySalesDataRelation
CREATE TABLE hye_TSLOilDailySalesDataRelation
(
    CompanySeq		INT 	 NOT NULL, 
    div_code		INT 	 NOT NULL, 
    process_date    NCHAR(8) NOT NULL, 
    erp_BizUnit     INT      NOT NULL,
    date_type       NVARCHAR(10) NOT NULL, 
    InvoiceSeq      INT 	 NOT NULL, 
    SalesSeq        INT 	 NOT NULL, 
    BillSeq         INT      NOT NULL, 
    MaxReceiptSeq   INT      NOT NULL,  
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime	DATETIME NOT NULL, 
    PgmSeq          INT      NULL 
)
create unique clustered index idx_hye_TSLOilDailySalesDataRelation on hye_TSLOilDailySalesDataRelation(CompanySeq,div_code,process_date) 
end 

if object_id('hye_TSLOilDailySalesDataRelationReceipt') is null

begin 
--drop table hye_TSLOilDailySalesDataRelation
CREATE TABLE hye_TSLOilDailySalesDataRelationReceipt
(
    CompanySeq		INT 	 NOT NULL, 
    MaxReceiptSeq   INT      NOT NULL,  
    ReceiptSeq      INT      NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime	DATETIME NOT NULL, 
    PgmSeq          INT      NULL 
)
create unique clustered index idx_hye_TSLOilDailySalesDataRelationReceipt on hye_TSLOilDailySalesDataRelationReceipt(CompanySeq,MaxReceiptSeq,ReceiptSeq) 
end 







