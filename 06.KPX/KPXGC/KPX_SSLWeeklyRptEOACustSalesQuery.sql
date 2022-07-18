  
IF OBJECT_ID('KPX_SSLWeeklyRptEOACustSalesQuery') IS NOT NULL   
    DROP PROC KPX_SSLWeeklyRptEOACustSalesQuery  
GO  
  
-- v2015.03.30  
  
-- (주간회의)EOA-거래선별판매현황-조회 by 이재천   
CREATE PROC KPX_SSLWeeklyRptEOACustSalesQuery  
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
            @StdDate    INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @SampleSeq   = ISNULL( @StdDate, '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (  
            StdDate  NCHAR(8)
           )    
    
    -- 최종조회   
    SELECT *   
      FROM _TSLInvocie AS A 
      JOIN _TSLInvoiceItem AS B ON ( B.CompanySeq = @CompanySeq AND B.InvoiceSeq = A.InvoiceSeq ) 
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS C ON ( C.ItemSeq = B.ItemSeq ) 
    
    
     WHERE A.CompanySeq = @CompanySeq  
       AND A.InvoiceDate BETWEEN LEFT(@StdDate,6) + '01' AND @StdDate 
       AND C.ItemClassLSeq = 2003001
       
    
    RETURN  
    
    


select * from _TDAUMinor where companyseq =1 and majorseq = 1010872


select * From _TDAUMinorValue where companyseq =1 and majorseq = 1010872 and serl = 1000001 order by minorseq 
select * From _TDAUMinorValue where companyseq =1 and majorseq = 1010872 and serl = 1000002order by minorseq 