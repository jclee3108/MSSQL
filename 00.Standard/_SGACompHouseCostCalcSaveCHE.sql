
IF OBJECT_ID('_SGACompHouseCostCalcSaveCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostCalcSaveCHE
GO 

/************************************************************  
 설  명 - 데이터-사택료항목별계산 : 저장  
 작성일 - 20110315  
 작성자 - 천경민  
************************************************************/  
CREATE PROC _SGACompHouseCostCalcSaveCHE  
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
    CREATE TABLE #TGAHouseCostCalcInfo (WorkingTag NCHAR(1) NULL)   
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TGAHouseCostCalcInfo'  
    IF @@ERROR <> 0 RETURN   
  
  
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   '_TGAHouseCostCalcInfo', -- 원테이블명    
                   '#TGAHouseCostCalcInfo', -- 템프테이블명    
                   'CalcYm,HouseSeq' , -- 키가 여러개일 경우는 , 로 연결한다.     
                   'CompanySeq,CalcYm,HouseSeq,CheckQty,UseQty,WaterCost,GeneralCost,LastDateTime,LastUserSeq,EmpSeq,DeptSeq'  
  
  
    -- 상하수도료, 일반관리비 계산(반올림, 올림, 절사 처리)  
    UPDATE A  
       SET WaterCost   = CASE WHEN ISNULL(D.LeavingDate, '') = '99991231' THEN dbo._FCOMGetRoundAmt(UseQty * Price , B.CalcPointType, B.AmtCalcType)   
                              WHEN ISNULL(D.LeavingDate, '') <> '99991231' AND B.FreeApplyYn = 1 THEN dbo._FCOMGetRoundAmt(UseQty * Price , B.CalcPointType, B.AmtCalcType)  
                              ELSE 0 END,   
           GeneralCost = CASE WHEN ISNULL(D.LeavingDate, '') = '99991231' THEN dbo._FCOMGetRoundAmt(PrivateSize * Price2, C.CalcPointType, C.AmtCalcType)   
                              WHEN ISNULL(D.LeavingDate, '') <> '99991231' AND C.FreeApplyYn = 1 THEN dbo._FCOMGetRoundAmt(PrivateSize * Price2, C.CalcPointType, C.AmtCalcType)   
                              ELSE 0 END  
      FROM #TGAHouseCostCalcInfo AS A  
           JOIN _TGACompHouseCostMaster AS B ON A.HouseClass = B.HouseClass  
                                                 AND A.CostType   = B.CostType  -- 상하수도료  
                                                 AND B.CompanySeq = @CompanySeq    
           JOIN _TGACompHouseCostMaster AS C ON A.HouseClass = C.HouseClass  
                                                 AND A.CostType2  = C.CostType  -- 일반관리비  
                                                 AND C.CompanySeq = @CompanySeq    
           LEFT OUTER JOIN  _TGACompHouseResident AS D ON A.HouseSeq = D.HouseSeq  
                                                 AND D.CompanySeq = @CompanySeq  
     WHERE Status = 0  
  
  
    -- DELETE  
    IF EXISTS (SELECT 1 FROM #TGAHouseCostCalcInfo WHERE WorkingTag = 'D' AND Status = 0)    
    BEGIN  
        DELETE _TGAHouseCostCalcInfo    
          FROM #TGAHouseCostCalcInfo AS A  
               JOIN _TGAHouseCostCalcInfo AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                                AND B.CalcYm     = A.CalcYm  
                                                                AND B.HouseSeq   = A.HouseSeq  
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0  
  
        IF @@ERROR <> 0 RETURN  
    END    
  
    -- UPDATE  
    IF EXISTS (SELECT 1 FROM #TGAHouseCostCalcInfo WHERE WorkingTag = 'U' AND Status = 0)    
    BEGIN  
        UPDATE _TGAHouseCostCalcInfo  
           SET CheckQty     = A.CheckQty,  
               WaterCost    = A.WaterCost,  
               GeneralCost  = A.GeneralCost,  
               LastDateTime = GETDATE(),  
               LastUserSeq  = @UserSeq  
          FROM #TGAHouseCostCalcInfo AS A    
        JOIN _TGAHouseCostCalcInfo AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq    
                                                                AND B.CalcYm     = A.CalcYm  
                                                                AND B.HouseSeq   = A.HouseSeq  
         WHERE A.WorkingTag = 'U'  
           AND A.Status = 0  
  
        IF @@ERROR <> 0 RETURN  
    END    
  
    -- INSERT      
    IF EXISTS (SELECT 1 FROM #TGAHouseCostCalcInfo WHERE WorkingTag = 'A' AND Status = 0)   
    BEGIN  
        INSERT INTO _TGAHouseCostCalcInfo (  
                CompanySeq     , CalcYm         , HouseSeq       , CheckQty       , UseQty         ,  
                WaterCost      , GeneralCost    , LastDateTime   , LastUserSeq    , EmpSeq         ,  
                DeptSeq  
        )           
        SELECT  @CompanySeq    , CalcYm         , HouseSeq       , CheckQty       , UseQty         ,  
                WaterCost      , GeneralCost    , GETDATE()      , @UserSeq       , EmpSeq         ,  
                DeptSeq  
          FROM #TGAHouseCostCalcInfo  
         WHERE WorkingTag = 'A'  
           AND Status = 0  
  
        IF @@ERROR <> 0 RETURN  
    END        
  
   SELECT * FROM #TGAHouseCostCalcInfo   
  
RETURN  