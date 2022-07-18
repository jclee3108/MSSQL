
if object_id('KPX_TEQCheckItem') is null 
begin 
CREATE TABLE KPX_TEQCheckItem
(
    CompanySeq		INT 	 NOT NULL, 
    ToolSeq		INT 	 NOT NULL, 
    UMCheckTerm		INT 	 NOT NULL, 
    CheckKind		NVARCHAR(100) 	 NULL, 
    CheckItem		NVARCHAR(100) 	 NULL, 
    SMInputType		INT 	 NULL, 
    CodeHelpConst   INT NULL, 
    CodeHelpParams  NVARCHAR(100) NULL, 
    Mask            NVARCHAR(100) NULL , 
    Remark		NVARCHAR(1000) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)
create unique clustered index idx_KPX_TEQCheckItem on KPX_TEQCheckItem(CompanySeq,ToolSeq,UMCheckTerm) 
end 


if object_id('KPX_TEQCheckItemLog') is null 
begin 
CREATE TABLE KPX_TEQCheckItemLog
(
    LogSeq		INT IDENTITY(1,1) NOT NULL, 
    LogUserSeq		INT NOT NULL, 
    LogDateTime		DATETIME NOT NULL, 
    LogType		NCHAR(1) NOT NULL, 
    LogPgmSeq		INT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    ToolSeq		INT 	 NOT NULL, 
    UMCheckTerm		INT 	 NOT NULL, 
    CheckKind		NVARCHAR(100) 	 NULL, 
    CheckItem		NVARCHAR(100) 	 NULL, 
    SMInputType		INT 	 NULL, 
    CodeHelpConst   INT NULL, 
    CodeHelpParams  NVARCHAR(100) NULL, 
    Mask            NVARCHAR(100) NULL, 
    Remark		NVARCHAR(1000) 	 NULL, 
    LastUserSeq		INT 	 NULL, 
    LastDateTime		DATETIME 	 NULL
)

end 



