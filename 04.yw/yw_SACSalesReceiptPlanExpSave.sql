
IF OBJECT_ID('yw_SACSalesReceiptPlanExpSave') IS NOT NULL   
    DROP PROC yw_SACSalesReceiptPlanExpSave  
GO  
  
-- v2013.12.16 
  
-- 채권수금계획(수출)_yw-저장 by 이재천   
CREATE PROC yw_SACSalesReceiptPlanExpSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #yw_TACSalesReceiptPlan (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#yw_TACSalesReceiptPlan'   
    IF @@ERROR <> 0 RETURN    
      --select * from #yw_TACSalesReceiptPlan
      --select @WorkingTag
      --return 
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('yw_TACSalesReceiptPlan')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'yw_TACSalesReceiptPlan'    , -- 테이블명        
                  '#yw_TACSalesReceiptPlan'    , -- 임시 테이블명        
                  'PlanYM,Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    --yw_TACSalesReceiptPlanlog
    -- 작업순서 : DELETE -> UPDATE -> INSERT  
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #yw_TACSalesReceiptPlan WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN 
        IF @WorkingTag = 'SheetDel'
        BEGIN
        DELETE B   
          FROM #yw_TACSalesReceiptPlan AS A   
          JOIN yw_TACSalesReceiptPlan AS B ON ( B.CompanySeq = @CompanySeq AND A.PlanYM = B.PlanYM AND A.Serl = B.Serl AND B.PlanType = '2' )    
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        END
        ELSE
        BEGIN 
        DELETE B   
          FROM #yw_TACSalesReceiptPlan AS A   
          JOIN yw_TACSalesReceiptPlan AS B ON ( B.CompanySeq = @CompanySeq AND A.PlanYM = B.PlanYM AND B.PlanType = '2' )    
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
        END
        
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #yw_TACSalesReceiptPlan WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
        UPDATE B   
           SET B.DeptSeq        = A.DeptSeq, 
               B.CustSeq        = A.CustSeq, 
               B.CurrSeq        = A.CurrSeq, 
               B.PlanAmt        = A.PlanAmt, 
               B.ReceiptAmt     = A.ReceiptAmt, 
               B.ReceiptAmt1    = A.ReceiptAmt1, 
               B.ReceiptAmt2    = A.ReceiptAmt2, 
               B.ReceiptAmt3    = A.ReceiptAmt3, 
               B.ReceiptAmt4    = A.ReceiptAmt4, 
               B.ReceiptAmt5    = A.ReceiptAmt5, 
               B.ReceiptAmt6    = A.ReceiptAmt6, 
               B.LongBondAmt    = A.LongBondAmt, 
               B.BadBondAmt     = A.BadBondAmt, 
               B.PlanDomAmt     = A.PlanDomAmt, 
               B.ReceiptDomAmt  = A.ReceiptDomAmt, 
               B.ReceiptDomAmt1 = A.ReceiptDomAmt1, 
               B.ReceiptDomAmt2 = A.ReceiptDomAmt2, 
               B.ReceiptDomAmt3 = A.ReceiptDomAmt3, 
               B.ReceiptDomAmt4 = A.ReceiptDomAmt4, 
               B.ReceiptDomAmt5 = A.ReceiptDomAmt5, 
               B.ReceiptDomAmt6 = A.ReceiptDomAmt6, 
               B.LongBondDomAmt = A.LongBondDomAmt, 
               B.BadBondDomAmt  = A.BadBondDomAmt, 
               B.LastUserSeq    = @UserSeq, 
               B.LastDateTime   = GETDATE(), 
               B.PgmSeq         = @PgmSeq 
          FROM #yw_TACSalesReceiptPlan AS A   
          JOIN yw_TACSalesReceiptPlan AS B ON ( B.CompanySeq = @CompanySeq AND A.PlanYM = B.PlanYM AND A.Serl = B.Serl AND B.PlanType = '2' )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    

    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #yw_TACSalesReceiptPlan WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
        INSERT INTO yw_TACSalesReceiptPlan  
        (   
            CompanySeq, PlanYM, PlanType, Serl, DeptSeq, 
            CustSeq, CurrSeq, SMInType, PlanAmt, ReceiptAmt, 
            ReceiptAmt1, ReceiptAmt2, ReceiptAmt3, ReceiptAmt4, ReceiptAmt5, 
            ReceiptAmt6, LongBondAmt, BadBondAmt, PlanDomAmt, ReceiptDomAmt, 
            ReceiptDomAmt1, ReceiptDomAmt2, ReceiptDomAmt3, ReceiptDomAmt4, ReceiptDomAmt5, 
            ReceiptDomAmt6, LongBondDomAmt, BadBondDomAmt, LastUserSeq, LastDateTime, 
            PgmSeq  
        )   
        SELECT @CompanySeq , A.PlanYM, 2, A.Serl, A.DeptSeq, 
               A.CustSeq, A.CurrSeq, 0, A.PlanAmt, A.ReceiptAmt, 
               A.ReceiptAmt1, A.ReceiptAmt2, A.ReceiptAmt3, A.ReceiptAmt4, A.ReceiptAmt5, 
               A.ReceiptAmt6, A.LongBondAmt, A.BadBondAmt, A.PlanDomAmt, A.ReceiptDomAmt, 
               A.ReceiptDomAmt1, A.ReceiptDomAmt2, A.ReceiptDomAmt3, A.ReceiptDomAmt4, A.ReceiptDomAmt5, 
               A.ReceiptDomAmt6, A.LongBondDomAmt, A.BadBondDomAmt, @UserSeq, GETDATE(), 
               @PgmSeq 
          FROM #yw_TACSalesReceiptPlan AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0 RETURN  
    
    END 
        
    UPDATE A 
       SET SumAmt = ISNULL(A.PlanAmt,0) + ISNULL(A.ReceiptAmt,0) + ISNULL(A.ReceiptAmt1,0) + ISNULL(A.ReceiptAmt2,0) + ISNULL(A.ReceiptAmt3,0) + 
                    ISNULL(A.ReceiptAmt4,0) + ISNULL(A.ReceiptAmt5,0) + ISNULL(A.ReceiptAmt6,0) + ISNULL(A.LongBondAmt,0) + ISNULL(A.BadBondAmt,0)
      FROM #yw_TACSalesReceiptPlan AS A 
    
    SELECT * FROM #yw_TACSalesReceiptPlan   
      
    RETURN  
GO
begin tran
exec yw_SACSalesReceiptPlanExpSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>D</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <Status>0</Status>
    <DeptName />
    <DeptSeq>0</DeptSeq>
    <PlanYM>201312</PlanYM>
    <SMInType>0</SMInType>
    <SMInTypeName />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019843,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016756
rollback