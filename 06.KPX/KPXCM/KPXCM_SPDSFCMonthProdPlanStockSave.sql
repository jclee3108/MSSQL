  
IF OBJECT_ID('KPXCM_SPDSFCMonthProdPlanStockSave') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCMonthProdPlanStockSave  
GO  
  
-- v2015.10.20  
  
-- 월생산계획-저장 by 이재천   
CREATE PROC KPXCM_SPDSFCMonthProdPlanStockSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS    
      
    CREATE TABLE #KPXCM_TPDSFCMonthProdPlanStock (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TPDSFCMonthProdPlanStock'   
    IF @@ERROR <> 0 RETURN    
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPXCM_TPDSFCMonthProdPlanStock')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'KPXCM_TPDSFCMonthProdPlanStock'    , -- 테이블명        
                  '#KPXCM_TPDSFCMonthProdPlanStock'    , -- 임시 테이블명        
                  'PlanSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    --IF @WorkingTag = 'Cfm'
    --BEGIN 
    --    UPDATE A 
    --       SET WorkingTag = 'A'
    --      FROM #KPXCM_TPDSFCMonthProdPlanStock AS A 
    --END 
    
    
    -- 작업순서 : DELETE -> UPDATE -> INSERT  
      
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDSFCMonthProdPlanStock WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #KPXCM_TPDSFCMonthProdPlanStock AS A   
          JOIN KPXCM_TPDSFCMonthProdPlanStock AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanSeq = A.PlanSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
          
        DELETE B   
          FROM #KPXCM_TPDSFCMonthProdPlanStock     AS A   
          JOIN KPXCM_TPDSFCMonthProdPlanStockItem AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanSeq = A.PlanSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
        
        DELETE B   
          FROM #KPXCM_TPDSFCMonthProdPlanStock     AS A   
          JOIN KPXCM_TPDSFCMonthProdPlanStock_Confirm AS B ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.PlanSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDSFCMonthProdPlanStock WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.FactUnit = A.FactUnit,  
               B.PlanYM = A.PlanYM,  
               B.EmpSeq = A.EmpSeq,  
               B.DeptSeq = A.DeptSeq,  
               B.LastUserSeq  = @UserSeq,  
               B.LastDateTime = GETDATE(),  
               B.PgmSeq       = @PgmSeq, 
               B.RptProdSalesQty1 = A.RptProdSalesQty1, 
               B.RptProdSalesQty2 = A.RptProdSalesQty2, 
               B.RptSelfQty1 = A.RptSelfQty1, 
               B.RptSelfQty2 =  A.RptSelfQty2, 
               B.RptSalesQty1 = A.RptSalesQty1, 
               B.RptSalesQty2 = A.RptSalesQty2
    
          FROM #KPXCM_TPDSFCMonthProdPlanStock AS A   
          JOIN KPXCM_TPDSFCMonthProdPlanStock AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanSeq = A.PlanSeq AND B.PlanYMSub = A.PlanYM )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0 
        
        IF @@ERROR <> 0  RETURN  
          
    END    
      
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #KPXCM_TPDSFCMonthProdPlanStock WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        
        IF @WorkingTag = 'Cfm' 
        BEGIN 
            DELETE B
              FROM #KPXCM_TPDSFCMonthProdPlanStock AS A 
              JOIN KPXCM_TPDSFCMonthProdPlanStock  AS B ON ( B.CompanySeq = @CompanySeq AND B.PlanSeq = A.PlanSeq )
             WHERE A.WorkingTag = 'A' 
               AND A.Status = 0 
        END 
        
        INSERT INTO KPXCM_TPDSFCMonthProdPlanStock  
        (   
            CompanySeq,PlanSeq,PlanNo,FactUnit,PlanYM,
            EmpSeq,DeptSeq,IsStockCfm,LastUserSeq,LastDateTime,
            PgmSeq, RptProdSalesQty1, RptProdSalesQty2, RptSelfQty1, RptSelfQty2, 
            RptSalesQty1, RptSalesQty2, IsCfm, PlanYMSub
        )   
        SELECT @CompanySeq,A.PlanSeq,A.PlanNo,A.FactUnit,A.PlanYM, -- Month
               A.EmpSeq,A.DeptSeq,
               CASE WHEN @WorkingTag = 'Cfm' THEN (CASE WHEN A.IsStockCfm = '1' THEN '0' ELSE '1' END) ELSE A.IsStockCfm END, 
               @UserSeq,GETDATE(),
               
               @PgmSeq, A.RptProdSalesQty1, A.RptProdSalesQty2, A.RptSelfQty1, A.RptSelfQty2, 
               A.RptSalesQty1, A.RptSalesQty2, '0', A.PlanYM 
          FROM #KPXCM_TPDSFCMonthProdPlanStock AS A   
         WHERE A.WorkingTag = 'A'   
             AND A.Status = 0    
        
        UNION ALL -- Month + 1 
        
        SELECT @CompanySeq,A.PlanSeq,A.PlanNo,A.FactUnit,A.PlanYM,
               A.EmpSeq,A.DeptSeq,
               CASE WHEN @WorkingTag = 'Cfm' THEN (CASE WHEN A.IsStockCfm = '1' THEN '0' ELSE '1' END) ELSE A.IsStockCfm END, 
               @UserSeq,GETDATE(),
               
               @PgmSeq, A.RptProdSalesQty1, A.RptProdSalesQty2, A.RptSelfQty1, A.RptSelfQty2, 
               A.RptSalesQty1, A.RptSalesQty2, '0', CONVERT(NCHAR(6),DATEADD(MM,1,A.PlanYM + '01'),112)
          FROM #KPXCM_TPDSFCMonthProdPlanStock AS A   
         WHERE A.WorkingTag = 'A'   
             AND A.Status = 0    
        
        UNION ALL -- Month + 2 
        
        SELECT @CompanySeq,A.PlanSeq, A.PlanNo, A.FactUnit, A.PlanYM,
               A.EmpSeq,A.DeptSeq,
               CASE WHEN @WorkingTag = 'Cfm' THEN (CASE WHEN A.IsStockCfm = '1' THEN '0' ELSE '1' END) ELSE A.IsStockCfm END, 
               @UserSeq,GETDATE(),
               
               @PgmSeq, A.RptProdSalesQty1, A.RptProdSalesQty2, A.RptSelfQty1, A.RptSelfQty2, 
               A.RptSalesQty1, A.RptSalesQty2, '0', CONVERT(NCHAR(6),DATEADD(MM,2,A.PlanYM + '01'),112)
          FROM #KPXCM_TPDSFCMonthProdPlanStock AS A   
         WHERE A.WorkingTag = 'A'   
             AND A.Status = 0    
        
        IF @@ERROR <> 0 RETURN  
        
        IF @WorkingTag = 'SS' 
        BEGIN 
            INSERT INTO KPXCM_TPDSFCMonthProdPlanStock_Confirm 
            ( 
                CompanySeq, CfmSeq, CfmSerl, CfmSubSerl, CfmSecuSeq, 
                IsAuto, CfmCode, CfmDate, CfmEmpSeq, UMCfmReason, 
                CfmReason, LastDateTime 
            )
            SELECT @CompanySeq, A.PlanSeq, 0, 0, 1001811, 
                   '0', 0, '', 0, 0, 
                   '', GETDATE()
              FROM #KPXCM_TPDSFCMonthProdPlanStock AS A 
             WHERE A.WorkingTag = 'A' 
               AND A.Status = 0 
        END 
        
        
    END     
    
    SELECT * FROM #KPXCM_TPDSFCMonthProdPlanStock   
      
    RETURN  
GO
begin tran 
exec KPXCM_SPDSFCMonthProdPlanStockSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <DeptName>사업개발팀2</DeptName>
    <DeptSeq>1300</DeptSeq>
    <EmpName>이재천</EmpName>
    <EmpSeq>2028</EmpSeq>
    <FactUnit>0</FactUnit>
    <FactUnitName />
    <PlanSeq>8</PlanSeq>
    <PlanYM>201511</PlanYM>
    <IsStockCfm>0</IsStockCfm>
    <PlanNo>2015110006</PlanNo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032672,@WorkingTag=N'SS',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027069
--select * from KPXCM_TPDSFCMonthProdPlanStock where planseq = 8  
--select * from KPXCM_TPDSFCMonthProdPlanStock_Confirm where cfmseq = 8 
rollback 


--select * from KPXCM_TPDSFCMonthProdPlanStock
--select * from KPXCM_TPDSFCMonthProdPlanStock_Confirm 


