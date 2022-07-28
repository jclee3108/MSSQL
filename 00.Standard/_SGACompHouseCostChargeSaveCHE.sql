
IF OBJECT_ID('_SGACompHouseCostChargeSaveCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostChargeSaveCHE
GO 

/************************************************************  
 ��  �� - ������-���÷��� : ����  
 �ۼ��� - 20110315  
 �ۼ��� - õ���  
************************************************************/  
CREATE PROC _SGACompHouseCostChargeSaveCHE 
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
  
AS      
    DECLARE @Count       INT,  
            @Seq         INT,  
            @MessageType INT,  
            @Status      INT,  
            @Results     NVARCHAR(250)  
  
  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TGAHouseCostChargeItem (WorkingTag NCHAR(1) NULL)   
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TGAHouseCostChargeItem'  
    IF @@ERROR <> 0 RETURN   
  
  
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   '_TGAHouseCostChargeItem', -- �����̺��    
                   '#TGAHouseCostChargeItem', -- �������̺��    
                   'CalcYm,HouseSeq,CostType' , -- Ű�� �������� ���� , �� �����Ѵ�.     
                   'CompanySeq,CalcYm,HouseSeq,CostType,HouseClass,CfmYn,ChargeAmt,LastDateTime,LastUserSeq'  
  
    
    -- DELETE  
    IF EXISTS (SELECT 1 FROM #TGAHouseCostChargeItem WHERE WorkingTag = 'D' AND Status = 0)    
    BEGIN  
        DELETE _TGAHouseCostChargeItem    
          FROM #TGAHouseCostChargeItem AS A  
               JOIN _TGAHouseCostChargeItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                                  AND B.CalcYm     = A.CalcYm  
                                                                  AND B.HouseSeq   = A.HouseSeq  
                                                                  AND B.CostType   = A.CostType  
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0  
  
        IF @@ERROR <> 0 RETURN  
    END  
  
    -- UPDATE  
    IF EXISTS (SELECT 1 FROM #TGAHouseCostChargeItem WHERE WorkingTag = 'U' AND Status = 0)    
    BEGIN  
        UPDATE _TGAHouseCostChargeItem  
           SET ChargeAmt    = A.ChargeAmt,  
               LastDateTime = GETDATE(),  
               LastUserSeq  = @UserSeq  
          FROM #TGAHouseCostChargeItem AS A    
               JOIN _TGAHouseCostChargeItem AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                                  AND B.CalcYm     = A.CalcYm  
                                                                  AND B.HouseSeq   = A.HouseSeq  
                                                                  AND B.CostType   = A.CostType  
         WHERE A.WorkingTag = 'U'  
           AND A.Status = 0  
  
        IF @@ERROR <> 0 RETURN  
    END    
  
    -- INSERT      
    IF EXISTS (SELECT 1 FROM #TGAHouseCostChargeItem WHERE WorkingTag = 'A' AND Status = 0)   
    BEGIN    
        INSERT INTO _TGAHouseCostChargeItem (  
               CompanySeq     , CalcYm         , HouseSeq       , CostType       , HouseClass     ,  
               ChargeAmt      , LastDateTime   , LastUserSeq  
        )          
        SELECT @CompanySeq    , CalcYm         , HouseSeq       , CostType       , HouseClass     ,  
               ChargeAmt      , GETDATE()      , @UserSeq  
          FROM #TGAHouseCostChargeItem  
         WHERE WorkingTag = 'A'  
           AND Status = 0  
  
        IF @@ERROR <> 0 RETURN  
    END        
  
   SELECT * FROM #TGAHouseCostChargeItem  
  
RETURN  