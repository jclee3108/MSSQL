   
IF OBJECT_ID('hye_SSLCustCreditQuerySub') IS NOT NULL     
    DROP PROC hye_SSLCustCreditQuerySub    
GO    
    
-- v2016.08.29 
    
-- 거래처별여신한도등록_hye-Sub조회 by 이재천 
CREATE PROC hye_SSLCustCreditQuerySub    
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
            @CustSeq    INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
        
    SELECT @CustSeq   = ISNULL( CustSeq, 0 )
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )         
      WITH (CustSeq   INT)      
    
    -- 최종조회     
    SELECT A.CustSeq, 
           A.LimitSerl, 
           A.UMLimitKind, 
           B.MinorName AS UMLimitKindName, 
           A.SrtDate, 
           A.EndDate, 
           A.Remark, 
           A.LimitAmt, 
           A.CustSeq, 
           C.CfmCode AS IsCfm 
      FROM hye_TDACustLimitInfo                     AS A 
      LEFT OUTER JOIN _TDAUMinor                    AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMLimitKind )   
      LEFT OUTER JOIN hye_TDACustLimitInfo_Confirm   AS C ON ( C.CompanySeq = @CompanySeq AND C.CfmSeq = A.CustSeq AND C.CfmSerl = A.LimitSerl ) 
     WHERE A.CompanySeq = @CompanySeq    
       AND ( A.CustSeq = @CustSeq )     
    
    RETURN   
    go
exec hye_SSLCustCreditQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <CustSeq>8</CustSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730094,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730020