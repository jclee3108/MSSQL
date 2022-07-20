IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id('mnpt_SPJTShipWorkPlanFinishSave'))
DROP PROCEDURE dbo.mnpt_SPJTShipWorkPlanFinishSave
GO 
-- v2017.10.11
  
-- 본선작업계획완료입력-저장 by 이재천
CREATE PROC mnpt_SPJTShipWorkPlanFinishSave  
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0   
AS  
    
    -- 로그 남기기    
    DECLARE @TableColumns NVARCHAR(4000)    
      
    -- Master 로그   
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTShipWorkPlanFinish')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTShipWorkPlanFinish'    , -- 테이블명        
                  '#BIZ_OUT_DataBlock1'    , -- 임시 테이블명        
                  'ShipPlanFinishSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    
    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock1 AS A   
          JOIN mnpt_TPJTShipWorkPlanFinish AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipPlanFinishSeq = B.ShipPlanFinishSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
    
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.ShipSeq       = A.ShipSeq       ,  
               B.ShipSerl      = A.ShipSerl      ,  
               B.PJTSeq        = A.PJTSeq        ,  
               B.DockPJTSeq    = A.DockPJTSeq    , 
			   B.DockCustSeq   = A.DockCustSeq	,
               B.PlanQty       = A.PlanQty       ,  
               B.PlanMTWeight  = A.PlanMTWeight  ,  
               B.PlanCBMWeight = A.PlanCBMWeight ,  
               B.IsCfm         = A.IsCfm         ,  
               --B.InDate        = A.InDate        ,  
               --B.InTime        = A.InTime        ,  
               --B.ApproachDate  = A.ApproachDate  ,  
               --B.ApproachTime  = A.ApproachTime  ,  
               --B.OutDate       = A.OutDate       ,  
               --B.OutTime       = A.OutTime       ,  
               B.FirstUserSeq  = @UserSeq,  
               B.FirstDateTime = GETDATE(),  
               B.LastUserSeq   = @UserSeq, 
               B.LastDateTime  = GETDATE(),  
               B.PgmSeq        = @PgmSeq
                 
          FROM #BIZ_OUT_DataBlock1 AS A   
          JOIN mnpt_TPJTShipWorkPlanFinish AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipPlanFinishSeq = B.ShipPlanFinishSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
        

        

        SELECT A.WorkingTag, 
               A.Status, 
               A.ShipSeq, 
               A.ShipSerl, 
               A.InDate + A.InTime AS InDateTime, 
               A.ApproachDate + A.ApproachTime AS ApproachDateTime, 
               A.OutDate + A.OutTime AS OutDateTime, 
               A.WorkSrtDate + A.WorkSrtTime AS WorkSrtDateTime, 
               A.WorkEndDate + A.WorkEndTime AS WorkEndDateTime


          INTO #ShipLog
          FROM #BIZ_OUT_DataBlock1 AS A 
         WHERE A.WorkingTag = 'U' 
           AND A.Status = 0 
        
        
        -- Master 로그   
        SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTShipDetail')    
      
        EXEC _SCOMLog @CompanySeq   ,        
                      @UserSeq      ,        
                      'mnpt_TPJTShipDetail'    , -- 테이블명        
                      '#ShipLog'    , -- 임시 테이블명        
                      'ShipSeq,ShipSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                      @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
        
        UPDATE B
           SET B.InDateTime = A.InDateTime, 
               B.ApproachDateTime = A.ApproachDateTime, 
               B.OutDateTime = A.OutDateTime, 
               B.WorkSrtDateTime = A.WorkSrtDateTime, 
               B.WorkEndDateTime = A.WorkEndDateTime,
               B.DiffApproachTime = CASE WHEN LEN(A.ApproachDateTime) <> 12 OR LEN(A.OutDateTime) <> 12 THEN 0 
                                         ELSE CEILING(DATEDIFF(MI,
                                                                   STUFF(STUFF(LEFT(A.ApproachDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.ApproachDateTime,4),3,0,':') + ':00.000', 
                                                                   STUFF(STUFF(LEFT(A.OutDateTime,8),5,0,'-'),8,0,'-') + ' ' + STUFF(RIGHT(A.OutDateTime,4),3,0,':') + ':00.000'
                                                              ) / 60.
                                                     ) 
                                         END 
          FROM #ShipLog             AS A   
          JOIN mnpt_TPJTShipDetail  AS B ON ( B.CompanySeq = @CompanySeq AND A.ShipSeq = B.ShipSeq AND A.ShipSerl = B.ShipSerl )   
         WHERE A.Status = 0 
        
    /*
    분산트랜잭션으로 인해 스케쥴링으로 작업 
    */
    --    -- 운영정보System Update
    --    IF DB_NAME() LIKE 'MNPT%' 
    --    BEGIN 
    --        UPDATE A
    --           SET ATA = C.InDateTime, 
    --               ATB = C.ApproachDateTime, 
    --               ATD = C.OutDateTime 
    --          FROM OPENQUERY(mokpo21, 'SELECT * FROM DVESSEL ') AS A 
    --          JOIN #BIZ_OUT_DataBlock1                          AS B ON (
    --                                                                     A.VESSEL = LEFT(B.ShipSerlNo,4) 
    --                                                                 AND A.VES_YY = SUBSTRING(B.ShipSerlNo,6,4) 
    --                                                                 AND A.VES_SEQ = CONVERT(INT,RIGHT(B.ShipSerlNo,3))
    --                                                                    )
    --          JOIN mnpt_TPJTShipDetail                          AS C ON ( C.CompanySeq = @CompanySeq AND C.ShipSeq = B.ShipSeq AND C.ShipSerl = B.ShipSerl ) 
    --         WHERE B.WorkingTag = 'U' 
    --           AND B.Status = 0 
    --    END 
                 
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTShipWorkPlanFinish  
        (   
            CompanySeq, ShipPlanFinishSeq, ShipSeq, ShipSerl, PJTSeq, 
            DockPJTSeq, PlanQty, PlanMTWeight, PlanCBMWeight, IsCfm, 
            FirstUserSeq, FirstDateTime, LastUserSeq, LastDateTime, PgmSeq,
			DockCustSeq
        )   
        SELECT @CompanySeq, ShipPlanFinishSeq, ShipSeq, ShipSerl, PJTSeq, 
               DockPJTSeq, PlanQty, PlanMTWeight, PlanCBMWeight, IsCfm, 
               @UserSeq, GETDATE(), @UserSeq, GETDATE(), @PgmSeq,
			   DockCustSeq
          FROM #BIZ_OUT_DataBlock1 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    RETURN  
