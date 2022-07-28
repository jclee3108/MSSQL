
IF OBJECT_ID('_SGACompHouseCostChargeSaveCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostChargeSaveCHE
GO 

/************************************************************  
 설  명 - 데이터-사택료등록 : 저장  
 작성일 - 20110315  
 작성자 - 천경민  
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
  
  
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #TGAHouseCostChargeItem (WorkingTag NCHAR(1) NULL)   
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TGAHouseCostChargeItem'  
    IF @@ERROR <> 0 RETURN   
  
  
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   '_TGAHouseCostChargeItem', -- 원테이블명    
                   '#TGAHouseCostChargeItem', -- 템프테이블명    
                   'CalcYm,HouseSeq,CostType' , -- 키가 여러개일 경우는 , 로 연결한다.     
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