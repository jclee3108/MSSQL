  
IF OBJECT_ID('KPXCM_SARBizTripCostItemSave') IS NOT NULL   
    DROP PROC KPXCM_SARBizTripCostItemSave  
GO  
  
-- v2015.09.02  
  
-- 국내출장 신청-디테일 저장 by 이재천   
CREATE PROC KPXCM_SARBizTripCostItemSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #KPXCM_TARBizTripCostItem (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock2', '#KPXCM_TARBizTripCostItem'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TARBizTripCostItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TARBizTripCostItem'    , -- 테이블명        
                  '#KPXCM_TARBizTripCostItem'    , -- 임시 테이블명        
                  'BizTripSeq,BizTripSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TARBizTripCostItem WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        DELETE B   
          FROM #KPXCM_TARBizTripCostItem AS A   
          JOIN KPXCM_TARBizTripCostItem AS B ON ( B.CompanySeq = @CompanySeq AND A.BizTripSeq = B.BizTripSeq AND A.BizTripSerl = B.BizTripSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        
        IF @@ERROR <> 0  RETURN  
        
        
        --IF NOT EXISTS (
        --                SELECT 1 
        --                  FROM KPXCM_TARBizTripCostItem AS A 
        --                 WHERE A.CompanySeq = @CompanySeq 
        --                   AND A.BizTripSeq IN ( SELECT TOP 1 BizTripSeq FROM #KPXCM_TARBizTripCostItem ) 
        --              )
        --BEGIN
            
        --    CREATE TABLE #Log 
        --    (
        --        IDX_NO          INT IDENTITY, 
        --        WorkingTag      NVARCHAR(1), 
        --        Status          INT, 
        --        BizTripSeq      INT, 
                
        --    )
        --    INSERT INTO #Log (WorkingTag, Status, BizTripSeq) 
        --    SELECT TOP 1 A.WorkingTag, A.Status, BizTripSeq 
        --      FROM #KPXCM_TARBizTripCostItem AS A 
        --     WHERE A.WorkingTag = 'D' 
        --       AND A.Status = 0 
               
        --    -- Master 로그   
        --    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TARBizTripCost')    
              
        --    EXEC _SCOMLog @CompanySeq   ,        
        --                  @UserSeq      ,        
        --                  'KPXCM_TARBizTripCost'    , -- 테이블명        
        --                  '#Log'    , -- 임시 테이블명        
        --                  'BizTripSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
        --                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
            
        --    DELETE B
        --      FROM #KPXCM_TARBizTripCostItem    AS A 
        --      JOIN KPXCM_TARBizTripCost         AS B ON ( B.CompanySeq = @CompanySeq AND B.BizTripSeq = A.BizTripSeq ) 
        --     WHERE A.WorkingTag = 'D' 
        --       AND A.Status = 0 
        --END 
    END   
    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TARBizTripCostItem WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.UMTripKind      = A.UMTripKind    ,  
               B.UMOilKind       = A.UMOilKind     ,  
               B.AllKm           = A.AllKm         ,  
               B.Price           = A.Price         ,  
               B.Mileage         = A.Mileage       ,  
               B.Amt             = A.Amt           ,  
               B.Remark          = A.Remark        ,  
               B.LastUserSeq     = @userSeq        ,  
               B.LastDateTime    = GETDATE()       , 
               B.PgmSeq          = @PgmSeq 
          FROM #KPXCM_TARBizTripCostItem AS A   
          JOIN KPXCM_TARBizTripCostItem AS B ON ( B.CompanySeq = @CompanySeq AND A.BizTripSeq = B.BizTripSeq AND A.BizTripSerl = B.BizTripSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TARBizTripCostItem WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO KPXCM_TARBizTripCostItem  
        (   
            CompanySeq, BizTripSeq, BizTripSerl, UMTripKind, UMOilKind, 
            AllKm, Price, Mileage, Amt, Remark, 
            LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, A.BizTripSeq, A.BizTripSerl, A.UMTripKind, A.UMOilKind, 
               A.AllKm, A.Price, A.Mileage, A.Amt, A.Remark, 
               @UserSeq, GETDATE(), @PgmSeq   
          FROM #KPXCM_TARBizTripCostItem AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END     
      
    SELECT * FROM #KPXCM_TARBizTripCostItem   
      
    RETURN  
go 
begin tran 
exec KPXCM_SARBizTripCostItemSave @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AllKm>123.00000</AllKm>
    <Amt>23423.00000</Amt>
    <BizTripSeq>1</BizTripSeq>
    <BizTripSerl>1</BizTripSerl>
    <Mileage>23.00000</Mileage>
    <Price>234.00000</Price>
    <Remark>234</Remark>
    <UMOilKind>4024003</UMOilKind>
    <UMOilKindName>LPG</UMOilKindName>
    <UMTripKind>1011518001</UMTripKind>
    <UMTripKindName>일당</UMTripKindName>
  </DataBlock2>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Selected>0</Selected>
    <Status>0</Status>
    <AllKm>14.00000</AllKm>
    <Amt>234.00000</Amt>
    <BizTripSeq>1</BizTripSeq>
    <BizTripSerl>2</BizTripSerl>
    <Mileage>234.00000</Mileage>
    <Price>134.00000</Price>
    <Remark>4234</Remark>
    <UMOilKind>4024002</UMOilKind>
    <UMOilKindName>경유</UMOilKindName>
    <UMTripKind>1011518002</UMTripKind>
    <UMTripKindName>유류대</UMTripKindName>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031819,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026397 
select * from KPXCM_TARBizTripCostItem 
rollback 