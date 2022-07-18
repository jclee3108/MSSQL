  
IF OBJECT_ID('KPXCM_SARBizTripCostItemQuery') IS NOT NULL   
    DROP PROC KPXCM_SARBizTripCostItemQuery  
GO  
  
-- v2015.09.02  
  
-- 국내출장 신청-디테일 조회 by 이재천   
CREATE PROC KPXCM_SARBizTripCostItemQuery  
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
            @BizTripSeq     INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizTripSeq = ISNULL( BizTripSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (BizTripSeq   INT)    
    
    -- 최종조회   
    SELECT A.BizTripSeq, 
           A.BizTripSerl, 
           A.UMTripKind, 
           B.MinorName AS UMTripKindName, 
           A.UMOilKind, 
           C.MinorName AS UMOilKindName, 
           A.AllKm, 
           A.Price,
           A.Mileage,
           A.Amt, 
           A.Remark
           
      FROM KPXCM_TARBizTripCostItem     AS A 
      LEFT OUTER JOIN _TDAUMinor        AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMTripKind ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMOilKind ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.BizTripSeq = @BizTripSeq ) 
      
    RETURN  
GO
exec KPXCM_SARBizTripCostItemQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BizTripSeq>1</BizTripSeq>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031819,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026397