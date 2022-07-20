  
IF OBJECT_ID('mnpt_SPJTWorkReportItemSave') IS NOT NULL   
    DROP PROC mnpt_SPJTWorkReportItemSave  
GO  
    
-- v2017.09.25
  
-- 작업실적입력-SS2저장 by 이재천
CREATE PROC mnpt_SPJTWorkReportItemSave
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
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TPJTWorkReportItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TPJTWorkReportItem'    , -- 테이블명        
                  '#BIZ_OUT_DataBlock2'    , -- 임시 테이블명        
                  'WorkReportSeq,WorkReportSerl'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   

    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
          
        DELETE B   
          FROM #BIZ_OUT_DataBlock2      AS A   
          JOIN mnpt_TPJTWorkReportItem    AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkReportSeq = B.WorkReportSeq AND A.WorkReportSerl = B.WorkReportSerl )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.UMBisWorkType      = A.UMBisWorkType      ,  
               B.SelfToolSeq        = A.SelfToolSeq        ,  
               B.RentToolSeq        = A.RentToolSeq        ,  
               B.ToolWorkTime       = A.ToolWorkTime       ,  
               B.DriverEmpSeq1      = A.DriverEmpSeq1      ,  
               B.DriverEmpSeq2      = A.DriverEmpSeq2      ,  
               B.DriverEmpSeq3      = A.DriverEmpSeq3      ,  
               B.DUnionDay          = A.DUnionDay          ,  
               B.DUnionHalf         = A.DUnionHalf         ,  
               B.DUnionMonth        = A.DUnionMonth        ,  
               B.DDailyEmpSeq       = A.DDailyEmpSeq        ,  
               B.DDailyDay          = A.DDailyDay          ,  
               B.DDailyHalf         = A.DDailyHalf         ,  
               B.DDailyMonth        = A.DDailyMonth        ,  
               B.DOSDay             = A.DOSDay             ,  
               B.DOSHalf            = A.DOSHalf            ,  
               B.DOSMonth           = A.DOSMonth           ,  
               B.DEtcDay            = A.DEtcDay            ,  
               B.DEtcHalf           = A.DEtcHalf           ,  
               B.DEtcMonth          = A.DEtcMonth          ,  
               B.NDEmpSeq           = A.NDEmpSeq           ,  
               B.NDUnionUnloadGang  = A.NDUnionUnloadGang  ,  
               B.NDUnionUnloadMan   = A.NDUnionUnloadMan   ,  
               B.NDUnionDailyDay    = A.NDUnionDailyDay    ,  
               B.NDUnionDailyHalf   = A.NDUnionDailyHalf   ,  
               B.NDUnionDailyMonth  = A.NDUnionDailyMonth  ,  
               B.NDUnionSignalDay   = A.NDUnionSignalDay   ,  
               B.NDUnionSignalHalf  = A.NDUnionSignalHalf  ,  
               B.NDUnionSignalMonth = A.NDUnionSignalMonth ,  
               B.NDUnionEtcDay      = A.NDUnionEtcDay      ,  
               B.NDUnionEtcHalf     = A.NDUnionEtcHalf     ,  
               B.NDUnionEtcMonth    = A.NDUnionEtcMonth    ,  
               B.NDDailyEmpSeq      = A.NDDailyEmpSeq      , 
               B.NDDailyDay         = A.NDDailyDay         ,  
               B.NDDailyHalf        = A.NDDailyHalf        ,  
               B.NDDailyMonth       = A.NDDailyMonth       ,  
               B.NDOSDay            = A.NDOSDay            ,  
               B.NDOSHalf           = A.NDOSHalf           ,  
               B.NDOSMonth          = A.NDOSMonth          ,  
               B.NDEtcDay           = A.NDEtcDay           ,  
               B.NDEtcHalf          = A.NDEtcHalf          ,  
               B.NDEtcMonth         = A.NDEtcMonth         ,  
               B.DRemark            = A.DRemark            ,  
               B.LastUserSeq        = @UserSeq           ,
               B.LastDateTime       = GETDATE()          ,
               B.PgmSeq             = @PgmSeq
          FROM #BIZ_OUT_DataBlock2      AS A   
          JOIN mnpt_TPJTWorkReportItem    AS B ON ( B.CompanySeq = @CompanySeq AND A.WorkReportSeq = B.WorkReportSeq AND A.WorkReportSerl = B.WorkReportSerl )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END  
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock2 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TPJTWorkReportItem  
        (   
            CompanySeq, WorkReportSeq, WorkReportSerl, UMBisWorkType, SelfToolSeq, 
            RentToolSeq, ToolWorkTime, DriverEmpSeq1, DriverEmpSeq2, DriverEmpSeq3, 
            DUnionDay, DUnionHalf, DUnionMonth, DDailyEmpSeq, DDailyDay, 
            DDailyHalf, DDailyMonth, DOSDay, DOSHalf, DOSMonth, 
            DEtcDay, DEtcHalf, DEtcMonth, NDEmpSeq, NDUnionUnloadGang, 
            NDUnionUnloadMan, NDUnionDailyDay, NDUnionDailyHalf, NDUnionDailyMonth, NDUnionSignalDay, 
            NDUnionSignalHalf, NDUnionSignalMonth, NDUnionEtcDay, NDUnionEtcHalf, NDUnionEtcMonth, 
            NDDailyEmpSeq, NDDailyDay, NDDailyHalf, NDDailyMonth, NDOSDay, 
            NDOSHalf, NDOSMonth, NDEtcDay, NDEtcHalf, NDEtcMonth, 
            DRemark, WorkPlanSeq, WorkPlanSerl, FirstUserSeq, FirstDateTime, 
            LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, WorkReportSeq, WorkReportSerl, UMBisWorkType, SelfToolSeq, 
               RentToolSeq, ToolWorkTime, DriverEmpSeq1, DriverEmpSeq2, DriverEmpSeq3, 
               DUnionDay, DUnionHalf, DUnionMonth, DDailyEmpSeq, DDailyDay, 
               DDailyHalf, DDailyMonth, DOSDay, DOSHalf, DOSMonth, 
               DEtcDay, DEtcHalf, DEtcMonth, NDEmpSeq, NDUnionUnloadGang, 
               NDUnionUnloadMan, NDUnionDailyDay, NDUnionDailyHalf, NDUnionDailyMonth, NDUnionSignalDay, 
               NDUnionSignalHalf, NDUnionSignalMonth, NDUnionEtcDay, NDUnionEtcHalf, NDUnionEtcMonth, 
               NDDailyEmpSeq, NDDailyDay, NDDailyHalf, NDDailyMonth, NDOSDay, 
               NDOSHalf, NDOSMonth, NDEtcDay, NDEtcHalf, NDEtcMonth, 
               DRemark, WorkPlanSeq, WorkPlanSerl, @UserSeq, GETDATE(), 
               @USerSeq, GETDATE(), @PgmSeq
          FROM #BIZ_OUT_DataBlock2 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
    
    END     
    
    RETURN  
    