  
IF OBJECT_ID('KPXHD_SFAFundChargeClaimINIT') IS NOT NULL   
    DROP PROC KPXHD_SFAFundChargeClaimINIT  
GO  
  
-- v2016.02.03 
  
-- 자금운용대행수수료청구내역입력-INIT by 이재천 
CREATE PROC KPXHD_SFAFundChargeClaimINIT  
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
            -- 조회조건   
            @StdYM      NCHAR(6), 
            @StdRate    INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYM   = ISNULL( StdYM, '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (StdYM   INT)    
      
    -- 최종조회   
    
    
    
    SELECT @StdRate = CONVERT(INT,REPLACE(MinorName,'%','')) 

      FROM _TDAUMinor                   AS A 
      LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
      LEFT OUTER JOIN _TDAUMinorValue   AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.MinorSeq AND C.Serl = 1000002 ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.Majorseq = 1012352 
       AND @StdYM BETWEEN LEFT(B.ValueText,6) AND LEFT(C.ValueText,6) 
    
    
    SELECT ISNULL(@StdRate,10) AS StdRate, 
           STUFF(CONVERT(NCHAR(6),DATEADD(MONTH, -1, @StdYM + '01'),112),5,0,'-') + '-26' 
           + ' ~ ' + 
           STUFF(@StdYM,5,0,'-') + '-25' AS FromTo 
    
    
    
    
    RETURN  
    GO 
exec KPXHD_SFAFundChargeClaimINIT @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <StdYM>201605</StdYM>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1034645,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1028674