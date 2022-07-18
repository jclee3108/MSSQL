  
IF OBJECT_ID('KPXCM_SARBizTripCostOilAmt') IS NOT NULL   
    DROP PROC KPXCM_SARBizTripCostOilAmt  
GO  
  
-- v2015.09.02  
  
-- 국내출장 신청-일당금계산 by 이재천   
CREATE PROC KPXCM_SARBizTripCostOilAmt  
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
            @UMOilKind  INT, 
            @AllKm      DECIMAL(19,5)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @UMOilKind   = ISNULL( UMOilKind, 0 ), 
           @AllKm       = ISNULL( AllKm, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (
            UMOilKind   INT, 
            AllKm       DECIMAL(19,5) 
           )    
    
    -- 최종조회   
    SELECT A.BaseMileage AS Mileage, 
           A.LiterPrice AS Price, 
           CASE WHEN ISNULL(A.BaseMileage,0) = 0 THEN 0 ELSE (@AllKm / A.BaseMileage) * A.LiterPrice END AS Amt, 
           CONVERT(NVARCHAR(100),CONVERT(INT,@AllKm)) + 'Km ( ' + CONVERT(NVARCHAR(100),CONVERT(INT,A.BaseMileage)) + 'Km 당 ' + CONVERT(NVARCHAR(100),CONVERT(INT,A.LiterPrice)) + '원 기준 )' AS Remark 
      FROM _TAROilItem  AS A
     WHERE A.CompanySeq = @CompanySeq 
       AND A.UMOilType = @UMOilKind 
       AND CONVERT(NCHAR(8),GETDATE(),112) BETWEEN A.BegDate AND A.EndDate 
    
    RETURN  
GO 
exec KPXCM_SARBizTripCostOilAmt @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMTripKind>1011518002</UMTripKind>
    <UMOilKind>4024002</UMOilKind>
    <AllKm>0</AllKm>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031819,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026397
