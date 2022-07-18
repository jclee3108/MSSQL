
IF OBJECT_ID('DTI_SSLBillConsignSetCustMail') IS NOT NULL 
    DROP PROC DTI_SSLBillConsignSetCustMail
GO

-- v2014.06.24 

-- 위수탁세금계산서입력_DTI(공급받는자이메일) by이재천 
CREATE PROC DTI_SSLBillConsignSetCustMail                
    @xmlDocument    NVARCHAR(MAX) , 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS 
    
    DECLARE @docHandle  INT,
            @CustSeq    INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @CustSeq = ISNULL(CustSeq,0) 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (CustSeq INT )
    
    SELECT TOP 1 EMail AS CustMail 
      FROM _TSIEDIIEBillCustEmpInfo 
     WHERE CompanySeq = @CompanySeq 
       AND CustSeq = @CustSeq 
     ORDER BY IsStd DESC
    
    RETURN

