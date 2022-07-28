
IF OBJECT_ID('_SGACompHouseCostCalcSaveCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostCalcSaveCHE
GO 

/************************************************************  
 ��  �� - ������-���÷��׸񺰰�� : ����  
 �ۼ��� - 20110315  
 �ۼ��� - õ���  
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
  
  
    -- ���� ����Ÿ ��� ����  
    CREATE TABLE #TGAHouseCostCalcInfo (WorkingTag NCHAR(1) NULL)   
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock3', '#TGAHouseCostCalcInfo'  
    IF @@ERROR <> 0 RETURN   
  
  
    -- �α����̺� �����(������ �Ķ���ʹ� �ݵ�� ���ٷ� ������)    
    EXEC _SCOMLog  @CompanySeq   ,    
                   @UserSeq      ,    
                   '_TGAHouseCostCalcInfo', -- �����̺��    
                   '#TGAHouseCostCalcInfo', -- �������̺��    
                   'CalcYm,HouseSeq' , -- Ű�� �������� ���� , �� �����Ѵ�.     
                   'CompanySeq,CalcYm,HouseSeq,CheckQty,UseQty,WaterCost,GeneralCost,LastDateTime,LastUserSeq,EmpSeq,DeptSeq'  
  
  
    -- ���ϼ�����, �Ϲݰ����� ���(�ݿø�, �ø�, ���� ó��)  
    UPDATE A  
       SET WaterCost   = CASE WHEN ISNULL(D.LeavingDate, '') = '99991231' THEN dbo._FCOMGetRoundAmt(UseQty * Price , B.CalcPointType, B.AmtCalcType)   
                              WHEN ISNULL(D.LeavingDate, '') <> '99991231' AND B.FreeApplyYn = 1 THEN dbo._FCOMGetRoundAmt(UseQty * Price , B.CalcPointType, B.AmtCalcType)  
                              ELSE 0 END,   
           GeneralCost = CASE WHEN ISNULL(D.LeavingDate, '') = '99991231' THEN dbo._FCOMGetRoundAmt(PrivateSize * Price2, C.CalcPointType, C.AmtCalcType)   
                              WHEN ISNULL(D.LeavingDate, '') <> '99991231' AND C.FreeApplyYn = 1 THEN dbo._FCOMGetRoundAmt(PrivateSize * Price2, C.CalcPointType, C.AmtCalcType)   
                              ELSE 0 END  
      FROM #TGAHouseCostCalcInfo AS A  
           JOIN _TGACompHouseCostMaster AS B ON A.HouseClass = B.HouseClass  
                                                 AND A.CostType   = B.CostType  -- ���ϼ�����  
                                                 AND B.CompanySeq = @CompanySeq    
           JOIN _TGACompHouseCostMaster AS C ON A.HouseClass = C.HouseClass  
                                                 AND A.CostType2  = C.CostType  -- �Ϲݰ�����  
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