
IF OBJECT_ID('_SGACompHouseCostMasterSaveCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostMasterSaveCHE
GO 

/************************************************************  
 설  명 - 데이터-사택료항목정의정보 : 저장  
 작성일 - 20110315  
 작성자 - 박헌기  
************************************************************/  
CREATE PROC _SGACompHouseCostMasterSaveCHE
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT             = 0,  
    @ServiceSeq     INT             = 0,  
    @WorkingTag     NVARCHAR(10)    = '',  
    @CompanySeq     INT             = 1,  
    @LanguageSeq    INT             = 1,  
    @UserSeq        INT             = 0,  
    @PgmSeq         INT             = 0  
AS  
  
    CREATE TABLE #TGACompHouseCostMaster (WorkingTag NCHAR(1) NULL)  
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TGACompHouseCostMaster'  
    IF @@ERROR <> 0 RETURN  
  
  
    -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
    EXEC _SCOMLog  @CompanySeq   ,  
                   @UserSeq      ,  
                   '_TGACompHouseCostMaster', -- 원테이블명  
                   '#TGACompHouseCostMaster', -- 템프테이블명  
                   'CostSeq        ' , -- 키가 여러개일 경우는 , 로 연결한다.  
                   'CompanySeq,CostSeq,HouseClass,CostType,CalcType,PackageAmt,ApplyFrDate,ApplyToDate,FreeApplyYn,CalcPointType,AmtCalcType,OrderNo,Remark,LastDateTime,LastUserSeq'  
  
    -- 작업순서 맞추기: DELETE -> UPDATE -> INSERT  
  
    -- DELETE  
    IF EXISTS (SELECT TOP 1 1 FROM #TGACompHouseCostMaster WHERE WorkingTag = 'D' AND Status = 0)  
    BEGIN  
        DELETE _TGACompHouseCostMaster  
          FROM _TGACompHouseCostMaster A  
               JOIN #TGACompHouseCostMaster B ON ( A.CostSeq = B.CostSeq )  
         WHERE A.CompanySeq  = @CompanySeq  
           AND B.WorkingTag = 'D'  
           AND B.Status = 0  
  
         IF @@ERROR <> 0  RETURN  
    END  
  
    -- UPDATE  
    IF EXISTS (SELECT 1 FROM #TGACompHouseCostMaster WHERE WorkingTag = 'U' AND Status = 0)  
    BEGIN  
        UPDATE _TGACompHouseCostMaster  
           SET HouseClass         = B.HouseClass         ,  
               CostType           = B.CostType           ,  
               ApplyFrDate        = B.ApplyFrDate        ,  
               ApplyToDate        = B.ApplyToDate        ,  
               CalcType           = B.CalcType           ,  
               PackageAmt         = B.PackageAmt         ,  
               FreeApplyYn        = B.FreeApplyYn        ,  
               CalcPointType      = B.CalcPointType      ,  
               AmtCalcType        = B.AmtCalcType        ,  
               OrderNo            = B.OrderNo            ,  
               Remark             = B.Remark             ,  
               LastDateTime       = GetDate()            ,  
               LastUserSeq        = @UserSeq  
          FROM _TGACompHouseCostMaster AS A  
               JOIN #TGACompHouseCostMaster AS B ON ( A.CostSeq        = B.CostSeq )  
         WHERE A.CompanySeq = @CompanySeq  
           AND B.WorkingTag = 'U'  
           AND B.Status = 0  
             
        IF @@ERROR <> 0  RETURN  
    END  
  
    -- INSERT  
    IF EXISTS (SELECT 1 FROM #TGACompHouseCostMaster WHERE WorkingTag = 'A' AND Status = 0)  
    BEGIN  
        INSERT INTO _TGACompHouseCostMaster ( CompanySeq ,CostSeq       ,HouseClass  ,CostType   ,  
                                                   CalcType   ,PackageAmt    ,ApplyFrDate ,ApplyToDate,  
                                                   FreeApplyYn,CalcPointType ,AmtCalcType ,OrderNo    ,  
                                                   Remark     ,LastDateTime  ,LastUserSeq             )  
                                           SELECT @CompanySeq ,CostSeq       ,HouseClass  ,CostType   ,  
                                                   CalcType   ,PackageAmt    ,ApplyFrDate ,ApplyToDate,  
                                                   FreeApplyYn,CalcPointType ,AmtCalcType ,OrderNo    ,  
                                                   Remark     ,GetDate()     ,@UserSeq  
                                      FROM #TGACompHouseCostMaster AS A  
                                            WHERE A.WorkingTag = 'A'  
                                              AND A.Status = 0  
  
        IF @@ERROR <> 0 RETURN  
    END  
  
    SELECT * FROM #TGACompHouseCostMaster  
  
    RETURN  