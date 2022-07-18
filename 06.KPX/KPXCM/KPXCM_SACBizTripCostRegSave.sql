IF OBJECT_ID('KPXCM_SACBizTripCostRegSave') IS NOT NULL 
    DROP PROC KPXCM_SACBizTripCostRegSave
GO 

-- v2015.09.24 

-- 출장상신(저장) by이재천   Save As  
/************************************************************  
 설  명 - 데이터-일반증빙상신_kpx : 저장  
 작성일 - 20150811  
 작성자 - 민형준  
************************************************************/  
CREATE PROC dbo.KPXCM_SACBizTripCostRegSave  
 @xmlDocument    NVARCHAR(MAX),    
 @xmlFlags       INT     = 0,    
 @ServiceSeq     INT     = 0,    
 @WorkingTag     NVARCHAR(10)= '',    
 @CompanySeq     INT     = 1,    
 @LanguageSeq    INT     = 1,    
 @UserSeq        INT     = 0,    
 @PgmSeq         INT     = 0    
  
AS     
    
    CREATE TABLE #KPXCM_TACBizTripCostReg (WorkingTag NCHAR(1) NULL)    
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#KPXCM_TACBizTripCostReg'       
    IF @@ERROR <> 0 RETURN    
    
    
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
    EXEC _SCOMLog  @CompanySeq   ,  
         @UserSeq      ,  
         'KPXCM_TACBizTripCostReg', -- 원테이블명  
         '#KPXCM_TACBizTripCostReg', -- 템프테이블명  
         'Seq           ' , -- 키가 여러개일 경우는 , 로 연결한다.   
         'CompanySeq,  
          Seq,  
          AccUnit,  
          CostDate,  
          CostAccSeq,  
          Amt,  
          DeptSeq,  
          EmpSeq,  
          CCtrSeq,  
          RemSeq,  
          RemValSeq,  
          UMCostType,  
          Remark,  
          OppAccSeq,  
          CashDate,  
          SlipSeq,  
          LastUserSeq,  
          LastDateTime'  
          ,''  
          ,@PgmSeq  
    
    -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT  
      
    -- DELETE      
    IF EXISTS (SELECT TOP 1 1 FROM #KPXCM_TACBizTripCostReg WHERE WorkingTag = 'D' AND Status = 0)    
    BEGIN    
        DELETE KPXCM_TACBizTripCostReg  
          FROM #KPXCM_TACBizTripCostReg A   
          JOIN KPXCM_TACBizTripCostReg B ON ( A.Seq = B.Seq )   
         WHERE B.CompanySeq  = @CompanySeq 
           AND A.WorkingTag = 'D'   
           AND A.Status = 0      
        
        IF @@ERROR <> 0  RETURN  
    END    
  
    -- UPDATE      
    IF EXISTS (SELECT 1 FROM #KPXCM_TACBizTripCostReg WHERE WorkingTag = 'U' AND Status = 0)    
    BEGIN  
        UPDATE KPXCM_TACBizTripCostReg  
           SET AccUnit     = A.AccUnit,  
               CostDate    = A.CostDate,  
               CostAccSeq  = A.CostAccSeq,  
               Amt         = A.Amt,  
               DeptSeq     = A.DeptSeq,  
               EmpSeq      = A.EmpSeq,   
               CCtrSeq     = A.CCtrSeq,  
               RemSeq      = A.RemSeq,  
               RemValSeq   = A.RemValSeq,    
               UMCostType  = A.UMCostType,  
               Remark      = A.Remark,  
               OppAccSeq   = A.OppAccSeq,  
               CashDate    = A.CashDate,  
               LastUserSeq = @UserSeq,  
               LastDateTime= GETDATE()  
          FROM #KPXCM_TACBizTripCostReg AS A   
          JOIN KPXCM_TACBizTripCostReg AS B ON ( A.Seq = B.Seq )   
         WHERE B.CompanySeq = @CompanySeq  
           AND A.WorkingTag = 'U'   
           AND A.Status = 0      
    
        IF @@ERROR <> 0  RETURN  
    END    
    
    -- INSERT  
    IF EXISTS (SELECT 1 FROM #KPXCM_TACBizTripCostReg WHERE WorkingTag = 'A' AND Status = 0)    
    BEGIN    
        INSERT INTO KPXCM_TACBizTripCostReg 
        (
            CompanySeq, Seq, AccUnit, CostDate, CostAccSeq, 
            Amt, DeptSeq, EmpSeq, CCtrSeq, RemSeq, 
            RemValSeq, UMCostType, Remark, OppAccSeq, CashDate, 
            SlipSeq, LastUserSeq, LastDateTime
        )   
        SELECT @CompanySeq, Seq, AccUnit, CostDate, CostAccSeq, 
               Amt, DeptSeq, EmpSeq, CCtrSeq, RemSeq, 
               RemValSeq, UMCostType, Remark, OppAccSeq, CashDate, 
               0, @UserSeq, GETDATE()
          FROM #KPXCM_TACBizTripCostReg AS A     
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
    
        IF @@ERROR <> 0 RETURN  
 END     
    
    SELECT * FROM #KPXCM_TACBizTripCostReg   
    
    RETURN      