     
IF OBJECT_ID('mnpt_SPJTWorkPlanShipQtyInfo') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkPlanShipQtyInfo  
GO  
    
-- v2017.10.16
  
-- 작업계획입력-모선수량정보 by 이재천
CREATE PROC mnpt_SPJTWorkPlanShipQtyInfo      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @PJTSeq     INT, 
            @ShipSeq    INT, 
            @ShipSerl   INT
      
    SELECT @PJTSeq      = ISNULL( PJTSeq    , 0 ), 
           @ShipSeq     = ISNULL( ShipSeq   , 0 ), 
           @ShipSerl    = ISNULL( ShipSerl  , 0 )
      FROM #BIZ_IN_DataBlock1 
    
    SELECT PlanQty AS GoodsQty, 
           PlanMTWeight AS GoodsMTWeight, 
           PlanCBMWeight AS GoodsCBMWeight
      FROM mnpt_TPJTShipWorkPlanFinish AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ShipSeq = @ShipSeq 
       AND A.ShipSerl = @ShipSerl
       AND A.PJTSeq = @PJTSeq 

    RETURN  
 go
