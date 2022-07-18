if object_id('KPX_TARBizTripCostCardCfm') is null
begin 
CREATE TABLE KPX_TARBizTripCostCardCfm
(
    CompanySeq		INT 	 NOT NULL, 
    BizTripSeq		INT 	 NOT NULL, 
    CARD_CD		NCHAR(24) 	 NOT NULL, 
    APPR_DATE		NCHAR(8) 	 NOT NULL, 
    APPR_SEQ		INT 	 NOT NULL, 
    APPR_No		NVARCHAR(20) 	 NOT NULL, 
    CANCEL_YN   NCHAR(1)    NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL

)
create unique clustered index idx_KPX_TARBizTripCostCardCfm on KPX_TARBizTripCostCardCfm(CompanySeq,BizTripSeq,CARD_CD,APPR_DATE,APPR_SEQ,APPR_No) 
end 


if object_id('KPX_TARBizTripCostCardCfmLog') is null
begin 
CREATE TABLE KPX_TARBizTripCostCardCfmLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    BizTripSeq		INT 	 NOT NULL, 
    CARD_CD		NCHAR(24) 	 NOT NULL, 
    APPR_DATE		NCHAR(8) 	 NOT NULL, 
    APPR_SEQ		INT 	 NOT NULL, 
    APPR_No		NVARCHAR(20) 	 NOT NULL, 
    CANCEL_YN   NCHAR(1)    NOT NULL, 
    LastUserSeq		INT 	 NOT NULL, 
    LastDateTime		DATETIME 	 NOT NULL
)
end 


