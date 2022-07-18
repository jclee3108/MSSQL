  
IF OBJECT_ID('KPXCM_SEQYearRepairResultRegCHESubQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairResultRegCHESubQuery  
GO  
  
-- v2015.07.17  
  
-- 연차보수실적등록-Sub조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairResultRegCHESubQuery  
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
            @ResultSeq  INT, 
            @ResultSerl INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ResultSeq   = ISNULL( ResultSeq, 0 ), 
           @ResultSerl  = ISNULL( ResultSerl, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (
            ResultSeq   INT, 
            ResultSerl  INT 
            )    
    
    -- 최종조회   
    SELECT A.ResultSeq, 
           A.ResultSerl, 
           A.ResultSubSerl, 
           A.DivSeq, 
           E.MinorName AS DivName, 
           A.EmpSeq, 
           CASE WHEN A.DivSeq = 20117001 THEN B.EmpName ELSE C.CustName END AS EmpName, 
           A.WorkOperSerl, 
           D.MinorName AS WorkOperSerlName, 
           A.ManHour,
           A.OTManHour 
           
      FROM KPXCM_TEQYearRepairRltManHourCHE AS A 
      LEFT OUTER JOIN _TDAEmp               AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDACust              AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.WorkOperSerl ) 
      LEFT OUTER JOIN _TDAUMinor            AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.DivSeq ) 
      
     WHERE ( A.CompanySeq = @CompanySeq ) 
       AND ( A.ResultSeq = @ResultSeq )   
       AND ( A.ResultSerl = @ResultSerl ) 
      
    RETURN  
GO 
exec KPXCM_SEQYearRepairResultRegCHESubQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>4</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ResultSeq>4</ResultSeq>
    <ResultSerl>4</ResultSerl>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030930,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025775