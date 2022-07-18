
if OBJECT_ID('KPX_TPUDelvItem_IF') is null
begin 
CREATE TABLE KPX_TPUDelvItem_IF
(
    Serl		INT identity not null, 
    GRNO		NVARCHAR(10) 	 NOT NULL, 
    STATUS		NCHAR(1) 	 NOT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PONo		NVARCHAR(100) 	 NOT NULL, 
    DelvDate		NCHAR(8) 	 NOT NULL, 
    ItemNo		NVARCHAR(100) 	 NOT NULL, 
    POSeq		INT 	 NULL, 
    DeptSeq		INT 	 NULL, 
    AccSeq		NVARCHAR(12) 	 NULL, 
    ItemName		NVARCHAR(100) 	 NULL, 
    ItemSeq		INT 	 NULL, 
    POQty		DECIMAL(19,5) 	 NOT NULL, 
    DelvQty		DECIMAL(19,5) 	 NOT NULL, 
    Price		DECIMAL(19,5) 	 NOT NULL, 
    PODate		NCHAR(8) 	 NOT NULL, 
    CustName		NVARCHAR(100) 	 NOT NULL, 
    CustSeq		INT 	 NULL, 
    EmpName		NVARCHAR(100) 	 NOT NULL, 
    EmpID		NVARCHAR(100) 	 NOT NULL, 
    EmpSeq		INT 	 NULL, 
    ORY_GR_ID		NVARCHAR(10) 	 NULL, 
    UserID		NVARCHAR(100) 	 NULL, 
    RegDate		DATETIME 	 NOT NULL, 
    ProcYN		NCHAR(1) 	 NOT NULL, 
    ProcDate		DATETIME 	 NULL, 
    DelvSeq		INT 	 NULL, 
    IsExpendable		NCHAR(1) 	 NULL, 
    IsErr		NCHAR(1) 	 NULL, 
    ErrorMessage		NVARCHAR(200) 	 NULL, 
CONSTRAINT PKKPX_TPUDelvItem_IF PRIMARY KEY CLUSTERED (Serl ASC)
)
end 
