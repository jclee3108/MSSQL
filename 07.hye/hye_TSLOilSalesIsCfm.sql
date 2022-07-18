if object_id('hye_TSLOilSalesIsCfm') is null

begin 
CREATE TABLE hye_TSLOilSalesIsCfm
(
    CompanySeq		INT 	        NOT NULL, 
    BizUnit         INT             NOT NULL, 
    StdYMDate       NVARCHAR(8)     NOT NULL, 
    IsCfm           NCHAR(1)        NOT NULL, 
    CfmDate         NCHAR(8)        NOT NULL, 
    --IsClose         NCHAR(1)        NULL, 
    --CloseDate       NCHAR(8)        NULL, 
    --io_type         NVARCHAR(10)    NULL, 
    LastUserSeq     INT             NOT NULL, 
    LastDateTime    DATETIME        NOT NULL, 
    PgmSeq          INT             NULL 
)
create unique clustered index idx_hye_TSLOilSalesIsCfm on hye_TSLOilSalesIsCfm(CompanySeq,BizUnit,StdYMDate) 
end 


if object_id('hye_TSLOilSalesIsCfmLog') is null
begin 
CREATE TABLE hye_TSLOilSalesIsCfmLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BizUnit         INT         NOT NULL, 
    StdYMDate       NVARCHAR(8) NOT NULL, 
    IsCfm           NCHAR(1)    NOT NULL, 
    CfmDate         NCHAR(8)    NOT NULL, 
    --IsClose         NCHAR(1)    NULL, 
    --CloseDate       NCHAR(8)    NULL, 
    --io_type         NVARCHAR(10)    NULL, 
    LastUserSeq     INT         NOT NULL, 
    LastDateTime    DATETIME    NOT NULL, 
    PgmSeq          INT         NULL 
)
end



