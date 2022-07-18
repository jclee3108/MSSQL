  
IF OBJECT_ID('KPX_SEIS_DEBT_STATUSQuery') IS NOT NULL   
    DROP PROC KPX_SEIS_DEBT_STATUSQuery  
GO  
  
-- v2014.11.24  
  
-- (경영정보)매입채무-조회 by 이재천   
CREATE PROC KPX_SEIS_DEBT_STATUSQuery  
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
            @PlanYM     INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PlanYM   = ISNULL( PlanYM, 0 ) 
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (PlanYM   INT)    
    
    
    IF EXISTS (SELECT 1 FROM KPX_TEIS_DEBT_STATUS WHERE CompanySeq = @CompanySeq AND PlanYM = @PlanYM ) 
    BEGIN -- 데이터가 존재할 때 
        
        SELECT D.MinorName AS UMDEBTItemKindName, 
               C.ValueSeq AS UMDEBTItemKind, 
               A.UMDEBTItem, 
               B.MinorName AS UMDEBTItemName, 
               A.ActPlusAmt, 
               A.ActMinusAmt, 
               A.PlanRestAmt, 
               A.PlanPlusAmt, 
               A.PlanMinusAmt, 
               E.ValueText AS IsSum, 
               '1' IsExists
          FROM KPX_TEIS_DEBT_STATUS         AS A 
          LEFT OUTER JOIN _TDAUMinor        AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMDEBTItem ) 
          LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.MinorSeq AND C.Serl = 1000001 ) 
          LEFT OUTER JOIN _TDAUMinor        AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = C.ValueSeq ) 
          LEFT OUTER JOIN _TDAUMinorValue   AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = B.MinorSeq AND E.Serl = 1000002 ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.PlanYM = @PlanYM 
         ORDER BY B.MinorSort, D.MinorSort 
    
    END 
    ELSE
    BEGIN
        
        SELECT C.MinorName AS UMDEBTItemKindName, 
               B.ValueSeq AS UMDEBTItemKind, 
               A.MinorSeq AS UMDEBTItem, 
               A.MinorName AS UMDEBTItemName, 
               D.ValueText AS IsSum,  
               '0' IsExists
          FROM _TDAUMinor                   AS A 
          LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
          LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.ValueSeq ) 
          LEFT OUTER JOIN _TDAUMinorValue   AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.MinorSeq AND D.Serl = 1000002 ) 
         WHERE A.CompanySeq = @CompanySeq 
           AND A.MajorSeq = 1010326 
           AND A.IsUse = '1'
         ORDER BY A.MinorSort, C.MinorSort
    
    END 
    
    RETURN  
    
GO 
exec KPX_SEIS_DEBT_STATUSQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PlanYM>201411</PlanYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026113,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021903