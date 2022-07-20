     
IF OBJECT_ID('mnpt_SPJTEERentToolContractItemQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTEERentToolContractItemQuery 
GO      
      
-- v2017.11.21
      
-- 외부장비임차계약입력-SS2조회 by 이재천
CREATE PROC mnpt_SPJTEERentToolContractItemQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @ContractSeq     INT 
      
    SELECT @ContractSeq   = ISNULL( ContractSeq, 0 )
      FROM #BIZ_IN_DataBlock1    
    
    SELECT A.ContractSeq, 
           A.ContractSerl, 
           A.UMRentKind, 
           C.MinorName AS UMRentKindName, 
           A.RentToolSeq, 
           A.TextRentToolName, 
           B.EquipmentSName AS RentToolName, 
           A.UMRentType, 
           D.MinorName AS UMRentTypeName, 
           A.Qty, 
           A.Price, 
           A.Amt, 
           A.PJTSeq, 
           E.PJTName, 
           A.Remark
      FROM mnpt_TPJTEERentToolContractItem  AS A 
      LEFT OUTER JOIN mnpt_TPDEquipment     AS B ON ( B.CompanySeq = @CompanySeq AND B.EquipmentSeq = A.RentToolSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMRentKind ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMRentType ) 
      LEFT OUTER JOIN _TPJTProject          AS E ON ( E.CompanySeq = @CompanySeq AND E.PJTSeq = A.PJTSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ContractSeq = @ContractSeq 
    
    RETURN     
    