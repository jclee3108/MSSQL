  
IF OBJECT_ID('KPXCM_SEQYearRepairPeriodRegCHEQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairPeriodRegCHEQuery  
GO  
  
-- v2015.07.13  
  
-- 연차보수기간등록-조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairPeriodRegCHEQuery  
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
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @RepairSeq  INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @RepairSeq   = ISNULL( RepairSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH ( RepairSeq   INT )    
    
    -- 최종조회   
    SELECT A.RepairSeq, 
           A.RepairYear, 
           A.FactUnit, 
           D.FactUnitName, 
           A.Amd, 
           A.EmpSeq, 
           B.EmpName, 
           A.DeptSeq, 
           C.DeptName, 
           A.RepairName, 
           A.RepairFrDate, 
           A.RepairToDate, 
           A.ReceiptFrDate, 
           A.ReceiptToDate, 
           A.RepairCfmYn, 
           A.ReceiptCfmyn, 
           A.Remark 
      FROM KPXCM_TEQYearRepairPeriodCHE AS A  
      LEFT OUTER JOIN _TDAEmp           AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept          AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAFactUnit      AS D ON ( D.CompanySeq = @CompanySeq AND D.FactUnit = A.FactUnit ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.RepairSeq = @RepairSeq )   
    
    RETURN  