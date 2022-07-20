if object_id('mnpt_TPJTEEExcelUploadMapping') is null
begin 

    CREATE TABLE mnpt_TPJTEEExcelUploadMapping
    (
        CompanySeq		INT 	 NOT NULL, 
        MappingSeq		INT 	 NOT NULL, 
        PJTSeq		INT 	 NOT NULL, 
        TextPJTType		NVARCHAR(200) 	 NOT NULL, 
        ItemSeq		INT 	 NOT NULL, 
        TextItemKind		NVARCHAR(200) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL, 
    CONSTRAINT PKmnpt_TPJTEEExcelUploadMapping PRIMARY KEY CLUSTERED (CompanySeq ASC, MappingSeq ASC)

    )
end 


if object_id('mnpt_TPJTEEExcelUploadMappingLog') is null
begin 
    CREATE TABLE mnpt_TPJTEEExcelUploadMappingLog
    (
        LogSeq		INT IDENTITY(1,1) NOT NULL, 
        LogUserSeq		INT NOT NULL, 
        LogDateTime		DATETIME NOT NULL, 
        LogType		NCHAR(1) NOT NULL, 
        LogPgmSeq		INT NULL, 
        CompanySeq		INT 	 NOT NULL, 
        MappingSeq		INT 	 NOT NULL, 
        PJTSeq		INT 	 NOT NULL, 
        TextPJTType		NVARCHAR(200) 	 NOT NULL, 
        ItemSeq		INT 	 NOT NULL, 
        TextItemKind		NVARCHAR(200) 	 NOT NULL, 
        Remark		NVARCHAR(2000) 	 NOT NULL, 
        FirstUserSeq		INT 	 NOT NULL, 
        FirstDateTime		DATETIME 	 NOT NULL, 
        LastUserSeq		INT 	 NOT NULL, 
        LastDateTime		DATETIME 	 NOT NULL, 
        PgmSeq		INT 	 NOT NULL
    )

    CREATE UNIQUE CLUSTERED INDEX IDXTempmnpt_TPJTEEExcelUploadMappingLog ON mnpt_TPJTEEExcelUploadMappingLog (LogSeq)
end 