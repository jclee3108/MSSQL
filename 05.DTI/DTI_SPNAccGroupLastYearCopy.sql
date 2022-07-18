
IF OBJECT_ID('DTI_SPNAccGroupLastYearCopy') IS NOT NULL 
    DROP PROC DTI_SPNAccGroupLastYearCopy
GO 

-- v2014.02.17 

-- 계정과목집계_DTI(전년데이터복사) by이재천
CREATE PROC dbo.DTI_SPNAccGroupLastYearCopy                
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS        
    
    DECLARE @docHandle  INT,
            @STDYear    NCHAR(4), 
            @LastYear   NCHAR(4)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @STDYear = ISNULL(STDYear,'') 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (STDYear NCHAR(4) )
    
    SELECT @LastYear = CONVERT(NCHAR(4),DATEADD(YEAR,-1,@STDyear + '0101'),112)
    
    DELETE FROM DTI_TPNCostItem WHERE CompanySeq = @CompanySeq AND STDYear = @STDYear
    
    INSERT INTO DTI_TPNCostItem (CompanySeq, CostKind, AccSeq, CostName, LastUserSeq, LastDateTime, CostName2, SMGPItem, IsAccPrt, Sort, STDYear, CostNameSort)
    SELECT @CompanySeq, CostKind, AccSeq, CostName, @UserSeq, GETDATE(), CostName2, SMGPItem, IsAccPrt, Sort, @STDYear, CostNameSort
      FROM DTI_TPNCostItem 
     WHERE CompanySeq = @CompanySeq 
       AND STDYear = @LastYear
    
    RETURN
go
exec DTI_SPNAccGroupLastYearCopy @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <STDYear>2015</STDYear>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1006456,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1005944