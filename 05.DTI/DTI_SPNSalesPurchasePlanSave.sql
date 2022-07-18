
IF OBJECT_ID('DTI_SPNSalesPurchasePlanSave') IS NOT NULL 
    DROP PROC DTI_SPNSalesPurchasePlanSave 
GO

-- v2014.03.28 

-- [경영계획]판매구매계획입력_DTI(저장) by이재천 
CREATE PROC DTI_SPNSalesPurchasePlanSave
    @xmlDocument    NVARCHAR(MAX), 
    @xmlFlags       INT = 0, 
    @ServiceSeq     INT = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT = 1, 
    @LanguageSeq    INT = 1, 
    @UserSeq        INT = 0, 
    @PgmSeq         INT = 0 
AS    
    
    CREATE TABLE #DTI_TPNSalesPurchasePlan (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#DTI_TPNSalesPurchasePlan'     
    IF @@ERROR <> 0 RETURN  
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('DTI_TPNSalesPurchasePlan')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'DTI_TPNSalesPurchasePlan'    , -- 테이블명        
                  '#DTI_TPNSalesPurchasePlan'    , -- 임시 테이블명        
                  'CostKeySeq,Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #DTI_TPNSalesPurchasePlan WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN 
        IF @WorkingTag = 'Del'
        BEGIN
            DECLARE @Cnt            INT, 
                    @CostYM         NCHAR(6), 
                    @SMCostMng      INT, 
                    @CostMngAmdSeq  INT, 
                    @PlanYear       NCHAR(4), 
                    @CostKeySeq     INT 
            
            SELECT @PlanYear = (SELECT PlanYear FROM #DTI_TPNSalesPurchasePlan)
            SELECT @SMCostMng = (SELECT SMCostMng FROM #DTI_TPNSalesPurchasePlan)
            SELECT @CostMngAmdSeq = (SELECT PlanKeySeq FROM #DTI_TPNSalesPurchasePlan)
            
            CREATE TABLE #Cost 
            (
                CostKeySeq  INT, 
                BizUnit     INT, 
                PlanType    INT, 
                EmpSeq      INT, 
                DeptSeq     INT 
            )
            
            SELECT @Cnt = 1
            
            WHILE ( @Cnt < 13 )
            BEGIN
                SELECT @CostYM = @PlanYear + RIGHT('00'+CAST(@Cnt AS NVARCHAR),2) 
        
        -- CostKeySeq 가져오기.  
            EXEC @CostKeySeq = dbo._SESMDCostKeySeq @CompanySeq, @CostYM, 0, @SMCostMng, @CostMngAmdSeq, @PlanYear, @PgmSeq 
            
            INSERT INTO #Cost (CostKeySeq, BizUnit, PlanType, EmpSeq, DeptSeq)
            SELECT @CostKeySeq, BizUnit, PlanType, EmpSeq, DeptSeq
              FROM #DTI_TPNSalesPurchasePlan 
             WHERE WorkingTag = 'D' 
               AND Status = 0    
            
            SELECT @Cnt = @Cnt + 1 
            END 

        DELETE B
          FROM #Cost AS A 
          JOIN DTI_TPNSalesPurchasePlan AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit AND B.PlanType = A.PlanType AND B.EmpSeq = A.EmpSeq AND B.DeptSeq = A.DeptSeq AND A.CostKeySeq = B.CostKeySeq ) 
        END
        ELSE 
        BEGIN
        DELETE B
          FROM #DTI_TPNSalesPurchasePlan    AS A 
          JOIN DTI_TPNSalesPurchasePlan     AS B ON ( B.CompanySeq = @CompanySeq AND B.CostKeySeq = A.CostKeySeq AND B.Serl = A.Serl ) 
         WHERE A.WorkingTag = 'D' 
           AND A.Status = 0    
         END
        
        IF @@ERROR <> 0  RETURN
    END  
    
    -- UPDATE    
    IF EXISTS (SELECT 1 FROM #DTI_TPNSalesPurchasePlan WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
        UPDATE DTI_TPNSalesPurchasePlan
           SET PlanAmt = A.Results 
          FROM #DTI_TPNSalesPurchasePlan    AS A 
          JOIN DTI_TPNSalesPurchasePlan     AS B ON ( B.CompanySeq = @CompanySeq AND B.CostKeySeq = A.CostKeySeq AND B.Serl = A.Serl ) 
         WHERE A.WorkingTag = 'U' 
           AND A.Status = 0    
        
        IF @@ERROR <> 0  RETURN
    END  

    -- INSERT
    IF EXISTS (SELECT 1 FROM #DTI_TPNSalesPurchasePlan WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO DTI_TPNSalesPurchasePlan 
        (
             CompanySeq     ,CostKeySeq ,Serl       ,BizUnit        ,PlanType       ,
             EmpSeq         ,DeptSeq    ,ItemSeq    ,PlanAmt        ,LastUserSeq    ,
             LastDateTime   ,PgmSeq
        ) 
        SELECT @CompanySeq  ,A.CostKeySeq   ,A.Serl     ,A.BizUnit     ,A.PlanType     , 
               A.EmpSeq     ,A.DeptSeq      ,A.ItemSeq  ,A.Results      ,@UserSeq       , 
               GETDATE()    ,@PgmSeq 
          FROM #DTI_TPNSalesPurchasePlan AS A 
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0    
        
        IF @@ERROR <> 0 RETURN 
    END   
    
    SELECT * FROM #DTI_TPNSalesPurchasePlan 
    
    RETURN    
    GO
begin tran
exec DTI_SPNSalesPurchasePlanSave @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <PlanKeySeq>547</PlanKeySeq>
    <PlanType>1</PlanType>
    <EmpSeq>2028</EmpSeq>
    <DeptSeq>147</DeptSeq>
    <BizUnit>1</BizUnit>
    <SMCostMng>5512002</SMCostMng>
    <PlanYear>2014</PlanYear>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1021944,@WorkingTag=N'Del',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1018429
select * from DTI_TPNSalesPurchasePlan where empseq = 2028
rollback  