
IF OBJECT_ID('KPX_SSLReceiptPlanDomSave') IS NOT NULL
    DROP PROC KPX_SSLReceiptPlanDomSave
GO 

-- v2014.12.19 
    
-- 채권수금계획(내수)-저장 by 이재천     
CREATE PROC KPX_SSLReceiptPlanDomSave    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS     
    CREATE TABLE #KPX_TLReceiptPlanDom (WorkingTag NCHAR(1) NULL)      
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPX_TLReceiptPlanDom'     
    IF @@ERROR <> 0 RETURN      
    
    -- 로그 남기기      
    DECLARE @TableColumns NVARCHAR(4000)      
        
    -- Master 로그     
    SELECT @TableColumns = dbo._FGetColumnsForLog('KPX_TLReceiptPlanDom')      
    
    IF @WorkingTag = 'Del' 
    BEGIN
        EXEC _SCOMLog @CompanySeq   ,          
              @UserSeq      ,          
              'KPX_TLReceiptPlanDom'    , -- 테이블명          
              '#KPX_TLReceiptPlanDom'    , -- 임시 테이블명          
              'PlanYM,PlanType'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )          
              @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명     
    END 
    ELSE
    BEGIN
        EXEC _SCOMLog @CompanySeq   ,          
              @UserSeq      ,          
              'KPX_TLReceiptPlanDom'    , -- 테이블명          
              '#KPX_TLReceiptPlanDom'    , -- 임시 테이블명          
              'PlanYM,PlanType,Serl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )          
              @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명  
    END 
    
    -- DELETE        
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TLReceiptPlanDom WHERE WorkingTag = 'D' AND Status = 0 )      
    BEGIN   
        IF @WorkingTag = 'Del'  
        BEGIN  
            DELETE B     
              FROM #KPX_TLReceiptPlanDom AS A     
              JOIN KPX_TLReceiptPlanDom AS B ON ( B.CompanySeq = @CompanySeq AND A.PlanYM = B.PlanYM AND B.PlanType = '1' )      
             WHERE A.WorkingTag = 'D'     
               AND A.Status = 0    
        END  
        ELSE  
        BEGIN   
        
            DELETE B     
              FROM #KPX_TLReceiptPlanDom AS A     
              JOIN KPX_TLReceiptPlanDom AS B ON ( B.CompanySeq = @CompanySeq AND A.PlanYM = B.PlanYM AND A.Serl = B.Serl AND B.PlanType = '1' )      
             WHERE A.WorkingTag = 'D'     
               AND A.Status = 0  
        END  
          
        IF @@ERROR <> 0  RETURN    
      
    END      
    
    -- UPDATE        
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TLReceiptPlanDom WHERE WorkingTag = 'U' AND Status = 0 )      
    BEGIN    
        UPDATE B     
           SET B.PlanDomAmt     = A.PlanAmt,   
               B.LastUserSeq    = @UserSeq,   
               B.LastDateTime   = GETDATE(),   
               B.PgmSeq         = @PgmSeq   
          FROM #KPX_TLReceiptPlanDom AS A     
          JOIN KPX_TLReceiptPlanDom AS B ON ( B.CompanySeq = @CompanySeq AND A.PlanYM = B.PlanYM AND A.Serl = B.Serl AND B.PlanType = '1' )     
         WHERE A.WorkingTag = 'U'     
           AND A.Status = 0        
            
        IF @@ERROR <> 0  RETURN    
            
    END      
  
    -- INSERT    
    IF EXISTS ( SELECT TOP 1 1 FROM #KPX_TLReceiptPlanDom WHERE WorkingTag = 'A' AND Status = 0 )      
    BEGIN      
        INSERT INTO KPX_TLReceiptPlanDom    
        (     
            CompanySeq, PlanYM, PlanType, Serl, BizUnit,   
            CustSeq, CurrSeq, SMInType, PlanAmt, ReceiptAmt,   
            ReceiptAmt1, ReceiptAmt2, ReceiptAmt3, ReceiptAmt4, ReceiptAmt5,   
            LongBondAmt, BadBondAmt, PlanDomAmt, ReceiptDomAmt,   
            ReceiptDomAmt1, ReceiptDomAmt2, ReceiptDomAmt3, ReceiptDomAmt4, ReceiptDomAmt5,   
            LongBondDomAmt, BadBondDomAmt, LastUserSeq, LastDateTime,   
            PgmSeq    
        )     
        SELECT @CompanySeq , A.PlanYM, '1', A.Serl, A.BizUnit,   
               A.CustSeq, 0, A.SMInType, 0, 0,   
               0, 0, 0, 0, 0,   
               0, 0, A.PlanAmt, A.ReceiptAmt,   
               A.ReceiptAmt1, A.ReceiptAmt2, A.ReceiptAmt3, A.ReceiptAmt4, A.ReceiptAmt5,   
               A.LongBondAmt, A.BadBondAmt, @UserSeq, GETDATE(),   
               @PgmSeq   
          FROM #KPX_TLReceiptPlanDom AS A     
         WHERE A.WorkingTag = 'A'     
           AND A.Status = 0        
          
        IF @@ERROR <> 0 RETURN    
      
    END   
          
    UPDATE A   
       SET SumAmt = ISNULL(A.PlanAmt,0) + ISNULL(A.ReceiptAmt,0) + ISNULL(A.ReceiptAmt1,0) + ISNULL(A.ReceiptAmt2,0) + ISNULL(A.ReceiptAmt3,0) +   
                    ISNULL(A.ReceiptAmt4,0) + ISNULL(A.ReceiptAmt5,0) + ISNULL(A.LongBondAmt,0) + ISNULL(A.BadBondAmt,0)  
      FROM #KPX_TLReceiptPlanDom AS A   
      
    SELECT * FROM #KPX_TLReceiptPlanDom     
        
    RETURN    