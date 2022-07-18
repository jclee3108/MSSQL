    
IF OBJECT_ID('DTI_SPNPayPlanSave') IS NOT NULL   
    DROP PROC DTI_SPNPayPlanSave  
    
GO  
    
-- v2013.07.01
  
-- [경영계획]급여계획등록(저장)_DTI by 이재천 
CREATE PROC DTI_SPNPayPlanSave
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,  
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0
AS 
    
    CREATE TABLE #DTI_TPNPayPlan (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#DTI_TPNPayPlan'     
    IF @@ERROR <> 0 RETURN  
    
    -- 로그 남기기
    DECLARE @TableColumns NVARCHAR(4000) 
    
    -- Master 로그
    EXEC _SCOMLog @CompanySeq,
   				  @UserSeq,
   				  'DTI_TPNPayPlan', -- 원테이블명
   				  '#DTI_TPNPayPlan', -- 템프테이블명
   				  'AccUnit,PlanYear,Serl', -- 키가 여러개일 경우는 , 로 연결한다. 
   				  @TableColumns, '', @PgmSeq
    
    -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT

    -- DELETE    
    IF EXISTS (SELECT TOP 1 1 FROM #DTI_TPNPayPlan WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        DELETE DTI_TPNPayPlan
          FROM #DTI_TPNPayPlan A 
          JOIN DTI_TPNPayPlan B ON ( B.CompanySeq = @CompanySeq
                                 AND B.PlanYear = A.PlanYear
                                 AND ((@WorkingTag = 'Delete' AND (B.AccUnit = A.AccUnit)
                                  OR (@WorkingTag <> 'Delete' AND A.AccUnit = B.AccUnit AND A.Serl = B.Serl )
                                      )
                                     )
                                   )
                                    
         WHERE B.CompanySeq  = @CompanySeq
           AND A.WorkingTag = 'D' 
           AND A.Status = 0    
        
        IF @@ERROR <> 0  RETURN
    
    END  


	-- UPDATE    
    IF EXISTS (SELECT 1 FROM #DTI_TPNPayPlan WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN
        UPDATE B
           SET CCtrSeq      = A.CCtrSeq,
               EmpSeq       = A.EmpSeq,
               DeptSeq      = A.DeptSeq,
               PayAmt1      = A.PayAmt1,
               PayAmt2      = A.PayAmt2,
               PayAmt3      = A.PayAmt3,
               PayAmt4      = A.PayAmt4,
               PayAmt5      = A.PayAmt5,
               PayAmt6      = A.PayAmt6,
               PayAmt7      = A.PayAmt7,
               PayAmt8      = A.PayAmt8,
               PayAmt9      = A.PayAmt9,
               PayAmt10     = A.PayAmt10,
               PayAmt11     = A.PayAmt11,
               PayAmt12     = A.PayAmt12,
               Remark       = A.Remark,
               LastUserSeq  = @UserSeq,
               LastDateTime = GetDate()
          FROM #DTI_TPNPayPlan AS A 
          JOIN DTI_TPNPayPlan AS B ON ( A.AccUnit = B.AccUnit AND A.PlanYear = B.PlanYear AND A.Serl = B.Serl ) 
         WHERE B.CompanySeq = @CompanySeq
           AND A.WorkingTag = 'U' 
           AND A.Status = 0    
			   
        IF @@ERROR <> 0  RETURN
    
    END  
    
	-- INSERT
    IF EXISTS (SELECT 1 FROM #DTI_TPNPayPlan WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO DTI_TPNPayPlan (CompanySeq, AccUnit , PlanYear, Serl   , CCtrSeq, 
                                    EmpSeq    , DeptSeq , PayAmt1 , PayAmt2 , PayAmt3, 
                                    PayAmt4   , PayAmt5 , PayAmt6 , PayAmt7 , PayAmt8, 
                                    PayAmt9   , PayAmt10, PayAmt11, PayAmt12, Remark , LastUserSeq, LastDateTime ) 
        SELECT @CompanySeq, ISNULL(AccUnit,0) , PlanYear, Serl    , CCtrSeq , 
               EmpSeq     , DeptSeq           , PayAmt1 , PayAmt2 , PayAmt3 , 
               PayAmt4    , PayAmt5           , PayAmt6 , PayAmt7 , PayAmt8 , 
               PayAmt9    , PayAmt10          , PayAmt11, PayAmt12, Remark  , @UserSeq, GetDate() 
        
          FROM #DTI_TPNPayPlan AS A   
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0    
        
        IF @@ERROR <> 0 RETURN
    
    END   
    
    SELECT * FROM #DTI_TPNPayPlan 
    
    RETURN 
GO
			