
if object_id('KPX_TPUDelvInItem_IF') is null 
begin 
CREATE TABLE KPX_TPUDelvInItem_IF
(
    Serl		INT identity 	 NOT NULL, 
    GRNO		NVARCHAR(10) 	 NOT NULL, 
    STATUS		NCHAR(1) 	 NOT NULL, 
    CompanySeq		INT 	 NOT NULL, 
    PONo		NVARCHAR(100) 	 NOT NULL, 
    DelvDate		NCHAR(8) 	 NOT NULL, 
    ItemNo		NVARCHAR(100) 	 NOT NULL, 
    POSeq		INT 	 NULL, 
    DeptSeq		INT 	 NULL, 
    AccSeq		NVARCHAR(12) 	 NULL, 
    ItemName		NVARCHAR(100) 	 NOT NULL, 
    ItemSeq		INT 	 NULL, 
    POQty		DECIMAL(19,5) 	 NOT NULL, 
    DelvQty		DECIMAL(19,5) 	 NOT NULL, 
    Price		DECIMAL(19,5) 	 NOT NULL, 
    PODate		NCHAR(8) 	 NOT NULL, 
    CustName		NVARCHAR(100) 	 NOT NULL, 
    EmpName		NVARCHAR(100) 	 NOT NULL, 
    EmpID		NVARCHAR(100) 	 NOT NULL, 
    ORY_GR_ID		NVARCHAR(10) 	 NOT NULL, 
CONSTRAINT PKKPX_TPUDelvInItem_IF PRIMARY KEY CLUSTERED (Serl ASC)
)
end 