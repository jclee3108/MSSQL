  
IF OBJECT_ID('KPXCM_SEQYearRepairReceiptRegCHEQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReceiptRegCHEQuery  
GO  
  
-- v2015.07.15  
  
-- 연차보수접수등록-조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReceiptRegCHEQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @ReceiptRegSeq  INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ReceiptRegSeq   = ISNULL( ReceiptRegSeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (ReceiptRegSeq   INT)    
      
    -- 최종조회   
    SELECT A.ReceiptRegSeq, 
           A.EmpSeq, 
           A.DeptSeq, 
           B.EmpName, 
           C.DeptName, 
           A.ReceiptRegDate 
      FROM KPXCM_TEQYearRepairReceiptRegCHE AS A 
      LEFT OUTER JOIN _TDAEmp               AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept              AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
     WHERE ( A.CompanySeq = @CompanySeq ) 
       AND ( A.ReceiptRegSeq = @ReceiptRegSeq ) 
    RETURN  