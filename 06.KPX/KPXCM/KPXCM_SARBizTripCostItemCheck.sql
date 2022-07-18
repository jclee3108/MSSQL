  
IF OBJECT_ID('KPXCM_SARBizTripCostItemCheck') IS NOT NULL   
    DROP PROC KPXCM_SARBizTripCostItemCheck  
GO  
  
-- v2015.09.02  
  
-- 국내출장 신청-디테일 체크 by 이재천   
CREATE PROC KPXCM_SARBizTripCostItemCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #KPXCM_TARBizTripCostItem( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TARBizTripCostItem'   
    IF @@ERROR <> 0 RETURN     
    
    -- Serl 따기 
    DECLARE @Serl INT 
    
    SELECT @Serl = ISNULL(MAX(BizTripSerl),0)
      FROM KPXCM_TARBizTripCostItem AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.BizTripSeq = (SELECT TOP 1 BizTripSeq FROM #KPXCM_TARBizTripCostItem) 
    
    UPDATE A 
       SET BizTripSerl = @Serl + A.DataSeq 
      FROM #KPXCM_TARBizTripCostItem AS A 
      WHERE A.Status = 0 
        AND A.WorkingTag = 'A'
    
      
    SELECT * FROM #KPXCM_TARBizTripCostItem   
      
    RETURN  
Go 
begin tran 
exec KPXCM_SARBizTripCostItemCheck @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMTripKindName>일당</UMTripKindName>
    <UMTripKind>1011518001</UMTripKind>
    <UMOilKindName>휘발유</UMOilKindName>
    <UMOilKind>4024001</UMOilKind>
    <AllKm>2</AllKm>
    <Price>3</Price>
    <Mileage>4</Mileage>
    <Amt>123</Amt>
    <Remark>123</Remark>
    <BizTripSeq>1</BizTripSeq>
    <BizTripSerl>0</BizTripSerl>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <UMTripKindName>유류대</UMTripKindName>
    <UMTripKind>1011518002</UMTripKind>
    <UMOilKindName>경유</UMOilKindName>
    <UMOilKind>4024002</UMOilKind>
    <AllKm>123</AllKm>
    <Price>14</Price>
    <Mileage>234</Mileage>
    <Amt>25</Amt>
    <Remark>345</Remark>
    <BizTripSeq>1</BizTripSeq>
    <BizTripSerl>0</BizTripSerl>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031819,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026397


rollback 