if object_id('hye_TSLOilSalesIsClose') is null

begin 
CREATE TABLE hye_TSLOilSalesIsClose
(
    CompanySeq		INT 	        NOT NULL, 
    BizUnit         INT             NOT NULL, 
    StdYMDate       NVARCHAR(8)     NOT NULL, 
    io_type         NVARCHAR(10)    NULL, 
    IsClose         NCHAR(1)        NOT NULL, 
    CloseDate       NCHAR(8)        NOT NULL, 
    LastUserSeq     INT             NOT NULL, 
    LastDateTime    DATETIME        NOT NULL, 
    PgmSeq          INT             NULL 
)
create unique clustered index idx_hye_TSLOilSalesIsClose on hye_TSLOilSalesIsClose(CompanySeq,BizUnit,StdYMDate,io_type) 
end 


if object_id('hye_TSLOilSalesIsCloseLog') is null
begin 
CREATE TABLE hye_TSLOilSalesIsCloseLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BizUnit         INT         NOT NULL, 
    StdYMDate       NVARCHAR(8) NOT NULL, 
    io_type         NVARCHAR(10)    NULL, 
    IsClose         NCHAR(1)    NULL, 
    CloseDate       NCHAR(8)    NULL, 
    LastUserSeq     INT         NOT NULL, 
    LastDateTime    DATETIME    NOT NULL, 
    PgmSeq          INT         NULL 
)
end




