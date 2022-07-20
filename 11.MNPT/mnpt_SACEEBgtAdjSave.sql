  
IF OBJECT_ID('mnpt_SACEEBgtAdjSave') IS NOT NULL   
    DROP PROC mnpt_SACEEBgtAdjSave  
GO  
    
-- v2017.12.18
  
-- 경비예산입력-저장 by 이재천   
CREATE PROC mnpt_SACEEBgtAdjSave  
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
    SELECT @TableColumns = dbo._FGetColumnsForLog('mnpt_TACEEBgtAdj')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  'mnpt_TACEEBgtAdj'    , -- 테이블명        
                  '#BIZ_OUT_DataBlock1'    , -- 임시 테이블명        
                  'AdjSeq'   , -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   
    --select * from #BIZ_OUT_DataBlock1 
    --return 
    
    
    DECLARE @EnvValue   INT, -- 환경설정  
            @DeptSeq    INT, 
            @CCtrSeq    INT 
    
    SELECT @EnvValue = EnvValue  
      FROM _TCOMEnv WITH(NOLOCK)  
     WHERE CompanySeq = @CompanySeq  
       AND EnvSeq = 4008  

    UPDATE A 
       SET DeptSeq = CASE WHEN @EnvValue = 4013001 THEN DeptCCtrSeq ELSE 0 END,  
           CCtrSeq = CASE WHEN @EnvValue = 4013002 THEN DeptCCtrSeq ELSE 0 END
      FROM #BIZ_OUT_DataBlock1 AS A 
    
    


    -- DELETE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'D' AND Status = 0 )    
    BEGIN    
        
        UPDATE A
           SET AccUnit = B.AccUnit,
               StdYear = B.StdYear 
          FROM #BIZ_OUT_DataBlock1  AS A 
          JOIN mnpt_TACEEBgtAdj     AS B ON ( B.CompanySeq = @CompanySeq AND B.AdjSeq = A.AdjSeq ) 
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   

        DELETE B   
          FROM #BIZ_OUT_DataBlock1 AS A   
          JOIN mnpt_TACEEBgtAdj AS B ON ( B.CompanySeq = @CompanySeq AND A.AdjSeq = B.AdjSeq )   
         WHERE A.WorkingTag = 'D'   
           AND A.Status = 0   
          
        IF @@ERROR <> 0  RETURN  
    
    END    
      
    -- UPDATE      
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'U' AND Status = 0 )    
    BEGIN  
          
        UPDATE B   
           SET B.DeptSeq        = A.DeptSeq     ,  
               B.CCtrSeq        = A.CCtrSeq     ,  
               B.AccSeq         = A.AccSeq      ,  
               B.UMCostType     = A.UMCostType  ,  
               B.Month01        = CASE WHEN A.AmtUnit <> 0 THEN A.Month01 * A.AmtUnit ELSE 0 END,  
               B.Month02        = CASE WHEN A.AmtUnit <> 0 THEN A.Month02 * A.AmtUnit ELSE 0 END,
               B.Month03        = CASE WHEN A.AmtUnit <> 0 THEN A.Month03 * A.AmtUnit ELSE 0 END,
               B.Month04        = CASE WHEN A.AmtUnit <> 0 THEN A.Month04 * A.AmtUnit ELSE 0 END, 
               B.Month05        = CASE WHEN A.AmtUnit <> 0 THEN A.Month05 * A.AmtUnit ELSE 0 END, 
               B.Month06        = CASE WHEN A.AmtUnit <> 0 THEN A.Month06 * A.AmtUnit ELSE 0 END, 
               B.Month07        = CASE WHEN A.AmtUnit <> 0 THEN A.Month07 * A.AmtUnit ELSE 0 END, 
               B.Month08        = CASE WHEN A.AmtUnit <> 0 THEN A.Month08 * A.AmtUnit ELSE 0 END, 
               B.Month09        = CASE WHEN A.AmtUnit <> 0 THEN A.Month09 * A.AmtUnit ELSE 0 END, 
               B.Month10        = CASE WHEN A.AmtUnit <> 0 THEN A.Month10 * A.AmtUnit ELSE 0 END, 
               B.Month11        = CASE WHEN A.AmtUnit <> 0 THEN A.Month11 * A.AmtUnit ELSE 0 END, 
               B.Month12        = CASE WHEN A.AmtUnit <> 0 THEN A.Month12 * A.AmtUnit ELSE 0 END, 
               B.LastUserSeq    = @UserSeq,  
               B.LastDateTime   = GETDATE(),  
               B.PgmSeq         = @PgmSeq  
          FROM #BIZ_OUT_DataBlock1 AS A   
          JOIN mnpt_TACEEBgtAdj AS B ON ( B.CompanySeq = @CompanySeq AND A.AdjSeq = B.AdjSeq )   
         WHERE A.WorkingTag = 'U'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0  RETURN  
          
    END    
    
    -- INSERT  
    IF EXISTS ( SELECT TOP 1 1 FROM #BIZ_OUT_DataBlock1 WHERE WorkingTag = 'A' AND Status = 0 )    
    BEGIN    
          
        INSERT INTO mnpt_TACEEBgtAdj  
        (   
            CompanySeq, AdjSeq, DeptSeq, CCtrSeq, StdYear, 
            AccUnit, AccSeq, UMCostType, Month01, Month02, 
            Month03, Month04, Month05, Month06, Month07, 
            Month08, Month09, Month10, Month11, Month12, 
            FirstUserSeq, FirstDateTime, LastUserSeq, LastDateTime, PgmSeq
        )   
        SELECT @CompanySeq, AdjSeq, DeptSeq, CCtrSeq, StdYear, 
               AccUnit, AccSeq, UMCostType, 
               CASE WHEN A.AmtUnit <> 0 THEN A.Month01 * A.AmtUnit ELSE 0 END, 
               CASE WHEN A.AmtUnit <> 0 THEN A.Month02 * A.AmtUnit ELSE 0 END, 
               
               CASE WHEN A.AmtUnit <> 0 THEN A.Month03 * A.AmtUnit ELSE 0 END,
               CASE WHEN A.AmtUnit <> 0 THEN A.Month04 * A.AmtUnit ELSE 0 END,
               CASE WHEN A.AmtUnit <> 0 THEN A.Month05 * A.AmtUnit ELSE 0 END,
               CASE WHEN A.AmtUnit <> 0 THEN A.Month06 * A.AmtUnit ELSE 0 END, 
               CASE WHEN A.AmtUnit <> 0 THEN A.Month07 * A.AmtUnit ELSE 0 END, 

               CASE WHEN A.AmtUnit <> 0 THEN A.Month08 * A.AmtUnit ELSE 0 END,
               CASE WHEN A.AmtUnit <> 0 THEN A.Month09 * A.AmtUnit ELSE 0 END,
               CASE WHEN A.AmtUnit <> 0 THEN A.Month10 * A.AmtUnit ELSE 0 END,
               CASE WHEN A.AmtUnit <> 0 THEN A.Month11 * A.AmtUnit ELSE 0 END, 
               CASE WHEN A.AmtUnit <> 0 THEN A.Month12 * A.AmtUnit ELSE 0 END, 
               
               @UserSeq, GETDATE(), @UserSeq, GETDATE(), @PgmSeq   
          FROM #BIZ_OUT_DataBlock1 AS A   
         WHERE A.WorkingTag = 'A'   
           AND A.Status = 0      
          
        IF @@ERROR <> 0 RETURN  
          
    END   
    
    -- 예산과목은 집계 
    SELECT A.StdYear, 
           A.AccUnit, 
           A.DeptSeq, 
           A.CCtrSeq, 
           A.UMCostType, 
           B.BgtSeq, 
           SUM(A.Month01) AS Month01, 
           SUM(A.Month02) AS Month02, 
           SUM(A.Month03) AS Month03, 
           SUM(A.Month04) AS Month04, 
           SUM(A.Month05) AS Month05, 
           SUM(A.Month06) AS Month06, 
           SUM(A.Month07) AS Month07, 
           SUM(A.Month08) AS Month08, 
           SUM(A.Month09) AS Month09, 
           SUM(A.Month10) AS Month10, 
           SUM(A.Month11) AS Month11, 
           SUM(A.Month12) AS Month12
      INTO #mnpt_TACEEBgtAdj 
      FROM mnpt_TACEEBgtAdj AS A 
      JOIN (
            SELECT Z.AccSeq, MAX(BgtSeq) AS BgtSeq 
              FROM _TACBgtAcc AS Z 
             WHERE Z.CompanySeq = @CompanySeq
             GROUP BY Z.AccSeq 
           ) AS B ON ( B.AccSeq = A.AccSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND EXISTS (SELECT 1 
                     FROM #BIZ_OUT_DataBlock1 
                    WHERE StdYear = A.StdYear 
                      AND AccUnit = A.AccUnit
                  ) 
     GROUP BY A.StdYear, A.AccUnit, A.DeptSeq, A.CCtrSeq, A.UMCostType, B.BgtSeq
    
    --select * from #mnpt_TACEEBgtAdj 
    --return 
    -- Site 테이블의 데이터 월별Row 만들어주기 
    SELECT StdYear AS BgtYear, 
           AccUnit, 
           DeptSeq, 
           CCtrSeq, 
           StdYear + '01' AS BgtYM, 
           BgtSeq, 
           UMCostType, 
           Month01 AS InputAmt, 
           '0' AS IsAdj
      INTO #TACBgtAdjItem_Sub 
      FROM #mnpt_TACEEBgtAdj 
    UNION ALL 
    SELECT StdYear AS BgtYear, 
           AccUnit, 
           DeptSeq, 
           CCtrSeq, 
           StdYear + '02' AS BgtYM, 
           BgtSeq, 
           UMCostType, 
           Month02 AS InputAmt, 
           '0' AS IsAdj
      FROM #mnpt_TACEEBgtAdj 
    UNION ALL 
    SELECT StdYear AS BgtYear, 
           AccUnit, 
           DeptSeq, 
           CCtrSeq, 
           StdYear + '03' AS BgtYM, 
           BgtSeq, 
           UMCostType, 
           Month03 AS InputAmt, 
           '0' AS IsAdj
      FROM #mnpt_TACEEBgtAdj 
    UNION ALL 
    SELECT StdYear AS BgtYear, 
           AccUnit, 
           DeptSeq, 
           CCtrSeq, 
           StdYear + '04' AS BgtYM, 
           BgtSeq, 
           UMCostType, 
           Month04 AS InputAmt, 
           '0' AS IsAdj
      FROM #mnpt_TACEEBgtAdj 
    UNION ALL 
    SELECT StdYear AS BgtYear, 
           AccUnit, 
           DeptSeq, 
           CCtrSeq, 
           StdYear + '05' AS BgtYM, 
           BgtSeq, 
           UMCostType, 
           Month05 AS InputAmt, 
           '0' AS IsAdj
      FROM #mnpt_TACEEBgtAdj 
    UNION ALL 
    SELECT StdYear AS BgtYear, 
           AccUnit, 
           DeptSeq, 
           CCtrSeq, 
           StdYear + '06' AS BgtYM, 
           BgtSeq, 
           UMCostType, 
           Month06 AS InputAmt, 
           '0' AS IsAdj
      FROM #mnpt_TACEEBgtAdj 
    UNION ALL 
    SELECT StdYear AS BgtYear, 
           AccUnit, 
           DeptSeq, 
           CCtrSeq, 
           StdYear + '07' AS BgtYM, 
           BgtSeq, 
           UMCostType, 
           Month07 AS InputAmt, 
           '0' AS IsAdj
      FROM #mnpt_TACEEBgtAdj 
    UNION ALL 
    SELECT StdYear AS BgtYear, 
           AccUnit, 
           DeptSeq, 
           CCtrSeq, 
           StdYear + '08' AS BgtYM, 
           BgtSeq, 
           UMCostType, 
           Month08 AS InputAmt, 
           '0' AS IsAdj
      FROM #mnpt_TACEEBgtAdj 
    UNION ALL 
    SELECT StdYear AS BgtYear, 
           AccUnit, 
           DeptSeq, 
           CCtrSeq, 
           StdYear + '09' AS BgtYM, 
           BgtSeq, 
           UMCostType, 
           Month09 AS InputAmt,
           '0' AS IsAdj
      FROM #mnpt_TACEEBgtAdj 
    UNION ALL 
    SELECT StdYear AS BgtYear, 
           AccUnit, 
           DeptSeq, 
           CCtrSeq, 
           StdYear + '10' AS BgtYM, 
           BgtSeq, 
           UMCostType, 
           Month10 AS InputAmt, 
           '0' AS IsAdj
      FROM #mnpt_TACEEBgtAdj 
    UNION ALL 
    SELECT StdYear AS BgtYear, 
           AccUnit, 
           DeptSeq, 
           CCtrSeq, 
           StdYear + '11' AS BgtYM, 
           BgtSeq, 
           UMCostType, 
           Month11 AS InputAmt,
           '0' AS IsAdj
      FROM #mnpt_TACEEBgtAdj 
    UNION ALL 
    SELECT StdYear AS BgtYear, 
           AccUnit, 
           DeptSeq, 
           CCtrSeq, 
           StdYear + '12' AS BgtYM, 
           BgtSeq, 
           UMCostType, 
           Month12 AS InputAmt, 
           '0' AS IsAdj
      FROM #mnpt_TACEEBgtAdj 
     ORDER BY BgtYear, AccUnit, DeptSeq, CCtrSeq, BgtSeq, UMCostType, BgtYM
    


    -- WorkingTag 만들어주기 
    CREATE TABLE #TACBgtAdjItemReal
    (
        WorkingTag      NCHAR(1), 
        BgtYear         NCHAR(4), 
        AccUnit         INT, 
        DeptSeq         INT, 
        CCtrSeq         INT, 
        BgtYM           NCHAR(6), 
        BgtSeq          INT, 
        UMCostType      INT, 
        IsAdj           NCHAR(1), 
        Status          INT, 
        InputAmt        DECIMAL(19,5) 
    )
    
    --select * From #TACBgtAdjItem_Sub 
    --return 
    INSERT INTO #TACBgtAdjItemReal 
    (
        WorkingTag, BgtYear, AccUnit, DeptSeq, CCtrSeq, 
        BgtYM, BgtSeq, UMCostType, IsAdj, Status, 
        InputAmt 
    ) 
    SELECT CASE WHEN B.CompanySeq IS NULL THEN 'A' 
                WHEN A.InputAmt <> B.InPutAmt THEN 'U' 
                ELSE ''
                END AS WorkingTag, 
           A.BgtYear, 
           A.AccUnit, 
           A.DeptSeq, 
           A.CCtrSeq, 
           A.BgtYM, 
           A.BgtSeq, 
           A.UMCostType, 
           A.IsAdj, 
           0 AS Status, 
           A.InputAmt 
      FROM #TACBgtAdjItem_Sub           AS A 
      LEFT OUTER JOIN _TACBgtAdjItem    AS B ON ( B.CompanySeq = @CompanySeq 
                                              AND B.BgtYear = A.BgtYear 
                                              AND B.AccUnit = A.AccUnit 
                                              AND B.DeptSeq = A.DeptSeq 
                                              AND B.CCtrSeq = A.CCtrSeq 
                                              AND B.BgtYM = A.BgtYM 
                                              AND B.BgtSeq = A.BgtSeq 
                                              AND B.UMCostType = A.UMCostType 
                                              AND B.IsAdj = A.IsAdj 
                                                ) 
     WHERE CASE WHEN B.CompanySeq IS NULL THEN 'A' 
                WHEN A.InputAmt <> B.InPutAmt THEN 'U' 
                ELSE ''
                END IN ( 'A', 'U' )
    
    INSERT INTO #TACBgtAdjItemReal 
    (
        WorkingTag, BgtYear, AccUnit, DeptSeq, CCtrSeq, 
        BgtYM, BgtSeq, UMCostType, IsAdj, Status, 
        InputAmt 
    ) 
    SELECT 'D' AS WorkingTag, 
           A.BgtYear, 
           A.AccUnit, 
           A.DeptSeq, 
           A.CCtrSeq, 
           A.BgtYM, 
           A.BgtSeq, 
           A.UMCostType, 
           A.IsAdj, 
           0 AS Status, 
           A.InputAmt 
      FROM _TACBgtAdjItem               AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.IsAdj = '0' 
       AND EXISTS (SELECT 1 FROM #BIZ_OUT_DataBlock1 WHERE StdYear = A.BgtYear AND AccUnit = A.AccUnit) 
       AND NOT EXISTS (SELECT 1 
                         FROM mnpt_TACEEBgtAdj AS Z 
                         JOIN (
                                SELECT AccSeq, MAX(BgtSeq) AS BgtSeq 
                                  FROM _TACBgtAcc
                                 WHERE CompanySeq = @CompanySeq
                                 GROUP BY AccSeq 
                              ) AS Y ON ( Y.AccSeq = Z.AccSeq )  
                        WHERE Z.CompanySeq = @CompanySeq 
                          AND Z.StdYear = A.BgtYear 
                          AND Z.AccUnit = A.AccUnit 
                          AND Z.DeptSeq = A.DeptSeq 
                          AND Z.CCtrSeq = A.CCtrSeq 
                          AND Z.UMCostType = A.UMCostType 
                          AND Y.BgtSeq = A.BgtSeq 
                      )
    
    -- 로그테이블 남기기
    SELECT @TableColumns = dbo._FGetColumnsForLog('_TACBgtAdjItem')    
      
    EXEC _SCOMLog @CompanySeq   ,        
                  @UserSeq      ,        
                  '_TACBgtAdjItem'    , -- 테이블명        
                  '#TACBgtAdjItemReal'    , -- 임시 테이블명        
                  'BgtYear, AccUnit, DeptSeq, CCtrSeq, BgtYM, BgtSeq, UMCostType, IsAdj', -- CompanySeq를 제외한 키( 키가 여러개일 경우는 , 로 연결 )        
                  @TableColumns , '', @PgmSeq  -- 테이블 모든 필드명   

    -- DELETE            
    IF EXISTS (SELECT TOP 1 1 FROM #TACBgtAdjItemReal WHERE WorkingTag = 'D' AND Status = 0)          
    BEGIN          
        DELETE _TACBgtAdjItem        
          FROM _TACBgtAdjItem A 
          JOIN #TACBgtAdjItemReal B ON (A.BgtYear = B.BgtYear         
                                    AND A.AccUnit = B.AccUnit         
                                    AND A.DeptSeq = B.DeptSeq         
                                    AND A.CCtrSeq = B.CCtrSeq        
                                    AND A.BgtYM = B.BgtyM        
                                    AND A.BgtSeq = B.BgtSeq      
                                    AND A.IsAdj  = B.IsAdj
                                    AND A.UMCostType = B.UMCostType 
                                       )          
         WHERE B.WorkingTag = 'D' AND B.Status = 0            
           AND A.CompanySeq  = @CompanySeq   
  
            
        IF @@ERROR <> 0  RETURN        
    END          
  
    -- UPDATE            
    IF EXISTS (SELECT 1 FROM #TACBgtAdjItemReal WHERE WorkingTag = 'U' AND Status = 0)          
      BEGIN        
        UPDATE _TACBgtAdjItem        
           SET  InputAmt = B.InputAmt  
          FROM _TACBgtAdjItem AS A 
          JOIN #TACBgtAdjItemReal AS B ON ( A.BgtYear = B.BgtYear         
                                        AND A.AccUnit = B.AccUnit         
                                        AND A.DeptSeq = B.DeptSeq        
                                        AND A.CCtrSeq = B.CCtrSeq        
                                        AND A.BgtYM = B.BgtYM        
                                        AND A.BgtSeq = B.BgtSeq      
                                        AND A.IsAdj = B.IsAdj      
                                        AND A.UMCostType = B.UMCostType 
                                           )        
         WHERE B.WorkingTag = 'U' AND B.Status = 0            
           AND A.CompanySeq  = @CompanySeq          
        IF @@ERROR <> 0  RETURN        
      
       
    END           
        
    -- INSERT        
    IF EXISTS (SELECT 1 FROM #TACBgtAdjItemReal WHERE WorkingTag = 'A' AND Status = 0)          
    BEGIN          
        INSERT INTO _TACBgtAdjItem 
        (
            CompanySeq, BgtYear, AccUnit, DeptSeq, CCtrSeq,  
            BgtYM, BgtSeq, UMCostType, IsAdj, IsCfm,  
            SMInputMethod, InputAmt, AdjAmt, AdjDesc, UMChgType
        )        
        SELECT @CompanySeq,     BgtYear,     AccUnit,        DeptSeq,    CCtrSeq,  
               BgtYM,           BgtSeq,      UMCostType,     IsAdj,      '1',  
               0,               InputAmt,    0,              '경비예산입력에서 생성',    0 
          FROM #TACBgtAdjItemReal AS A           
         WHERE A.WorkingTag = 'A' 
           AND A.Status = 0            
        
        IF @@ERROR <> 0 RETURN        
    END           
    

    RETURN  

go

begin tran 
DECLARE   @CONST_#BIZ_IN_DataBlock1 INT        , @CONST_#BIZ_OUT_DataBlock1 INTSELECT    @CONST_#BIZ_IN_DataBlock1 = 0        , @CONST_#BIZ_OUT_DataBlock1 = 0
IF @CONST_#BIZ_IN_DataBlock1 = 0
BEGIN
    CREATE TABLE #BIZ_IN_DataBlock1
    (
        WorkingTag      NCHAR(1)
        , IDX_NO        INT
        , DataSeq       INT
        , Selected      INT
        , MessageType   INT
        , Status        INT
        , Result        NVARCHAR(255)
        , ROW_IDX       INT
        , IsChangedMst  NCHAR(1)
        , TABLE_NAME    NVARCHAR(255)

        , StdYear CHAR(4), AccUnitName NVARCHAR(200), AmtUnit DECIMAL(19, 5), AccUnit INT, DeptCCtrName NVARCHAR(200), AccName NVARCHAR(200), UMCostTypeName NVARCHAR(200), Month01 DECIMAL(19, 5), Month02 DECIMAL(19, 5), Month03 DECIMAL(19, 5), Month04 DECIMAL(19, 5), Month05 DECIMAL(19, 5), Month06 DECIMAL(19, 5), Month07 DECIMAL(19, 5), Month08 DECIMAL(19, 5), Month09 DECIMAL(19, 5), Month10 DECIMAL(19, 5), Month11 DECIMAL(19, 5), Month12 DECIMAL(19, 5), MonthSum DECIMAL(19, 5), DeptCCtrSeq INT, AccSeq INT, UMCostType INT, AdjSeq INT, DeptSeq INT, CCtrSeq INT
    )
    
    SET @CONST_#BIZ_IN_DataBlock1 = 1

END

IF @CONST_#BIZ_OUT_DataBlock1 = 0
BEGIN
    CREATE TABLE #BIZ_OUT_DataBlock1
    (
        WorkingTag      NCHAR(1)
        , IDX_NO        INT
        , DataSeq       INT
        , Selected      INT
        , MessageType   INT
        , Status        INT
        , Result        NVARCHAR(255)
        , ROW_IDX       INT
        , IsChangedMst  NCHAR(1)
        , TABLE_NAME    NVARCHAR(255)

        , StdYear CHAR(4), AccUnitName NVARCHAR(200), AmtUnit DECIMAL(19, 5), AccUnit INT, DeptCCtrName NVARCHAR(200), AccName NVARCHAR(200), UMCostTypeName NVARCHAR(200), Month01 DECIMAL(19, 5), Month02 DECIMAL(19, 5), Month03 DECIMAL(19, 5), Month04 DECIMAL(19, 5), Month05 DECIMAL(19, 5), Month06 DECIMAL(19, 5), Month07 DECIMAL(19, 5), Month08 DECIMAL(19, 5), Month09 DECIMAL(19, 5), Month10 DECIMAL(19, 5), Month11 DECIMAL(19, 5), Month12 DECIMAL(19, 5), MonthSum DECIMAL(19, 5), DeptCCtrSeq INT, AccSeq INT, UMCostType INT, AdjSeq INT, DeptSeq INT, CCtrSeq INT
    )
    
    SET @CONST_#BIZ_OUT_DataBlock1 = 1

END
DECLARE   @INPUT_ERROR_MESSAGE    NVARCHAR(4000)
        , @INPUT_ERROR_SEVERITY   INT
        , @INPUT_ERROR_STATE      INT
        , @INPUT_ERROR_PROCEDURE  NVARCHAR(128)
INSERT INTO #BIZ_IN_DataBlock1 (WorkingTag, IDX_NO, DataSeq, Selected, Status, Result, ROW_IDX, IsChangedMst, TABLE_NAME, StdYear, AccUnitName, AmtUnit, AccUnit, DeptCCtrName, AccName, UMCostTypeName, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, MonthSum, DeptCCtrSeq, AccSeq, UMCostType, AdjSeq, DeptSeq, CCtrSeq) 
SELECT N'D', 2, 1, 0, 0, NULL, NULL, NULL, N'DataBlock1', NULL, NULL, NULL, NULL, N'구매부서', N'복리후생비', N'제조', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'2', N'24', N'5', N'212', N'4001001', N'31', NULL, NULL UNION ALL 
SELECT N'D', 3, 2, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, N'생산부서', N'복리후생비', N'용역', N'1', N'1', N'1', N'1', N'1', N'1', N'1', N'1', N'1', N'1', N'1', N'1', N'12', N'4', N'212', N'4001003', N'32', NULL, NULL
IF @@ERROR <> 0 RETURN


DECLARE @HasError           NCHAR(1)
        , @UseTransaction   NCHAR(1)
        -- 내부 SP용 파라메터
        , @ServiceSeq       INT
        , @MethodSeq        INT
        , @WorkingTag       NVARCHAR(10)
        , @CompanySeq       INT
        , @LanguageSeq      INT
        , @UserSeq          INT
        , @PgmSeq           INT
        , @IsTransaction    BIT

SET @HasError = N'0'
SET @UseTransaction = N'0'

BEGIN TRY

SET @ServiceSeq     = 13820089
--SET @MethodSeq      = 2
SET @WorkingTag     = N''
SET @CompanySeq     = 1
SET @LanguageSeq    = 1
SET @UserSeq        = 167
SET @PgmSeq         = 13820092
SET @IsTransaction  = 1
-- InputData를 OutputData에 복사INSERT INTO #BIZ_OUT_DataBlock1(WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdYear, AccUnitName, AmtUnit, AccUnit, DeptCCtrName, AccName, UMCostTypeName, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, MonthSum, DeptCCtrSeq, AccSeq, UMCostType, AdjSeq, DeptSeq, CCtrSeq)    SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType, Status, Result, ROW_IDX, IsChangedMst, StdYear, AccUnitName, AmtUnit, AccUnit, DeptCCtrName, AccName, UMCostTypeName, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, MonthSum, DeptCCtrSeq, AccSeq, UMCostType, AdjSeq, DeptSeq, CCtrSeq      FROM  #BIZ_IN_DataBlock1-- ExecuteOrder : 1 : StartEXEC    mnpt_SACEEBgtAdjCheck            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0)
BEGIN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 1 : End-- ExecuteOrder : 2 : StartSET @UseTransaction = N'1'BEGIN TRANEXEC    mnpt_SACEEBgtAdjSave            @ServiceSeq            , @WorkingTag            , @CompanySeq            , @LanguageSeq            , @UserSeq            , @PgmSeq            , @IsTransaction
IF @@ERROR <> 0  OR EXISTS(SELECT * FROM #BIZ_OUT_DataBlock1 WHERE Status != 0)
BEGIN
    --ROLLBACK TRAN
    SET @HasError = N'1'
    GOTO GOTO_END
END
-- ExecuteOrder : 2 : EndCOMMIT TRANSET @UseTransaction = N'0'GOTO_END:SELECT  WorkingTag, IDX_NO, DataSeq, Selected, MessageType
        , CASE
            WHEN Status = 0 OR Status IS NULL THEN
                -- 정상인건 중에
                CASE
                    WHEN @HasError = N'1' THEN
                        -- 오류가 발생된 건이면
                        CASE
                            WHEN @UseTransaction = N'1' THEN
                                999999  -- 트랜잭션인 경우
                            ELSE
                                999998  -- 트랜잭션이 아닌 경우
                        END
                    ELSE
                        -- 오류가 발생되지 않은 건이면
                        0
                END
            ELSE
                Status
        END AS Status
        , Result, ROW_IDX, IsChangedMst, StdYear, AccUnitName, AmtUnit, AccUnit, DeptCCtrName, AccName, UMCostTypeName, Month01, Month02, Month03, Month04, Month05, Month06, Month07, Month08, Month09, Month10, Month11, Month12, MonthSum, DeptCCtrSeq, AccSeq, UMCostType, AdjSeq, DeptSeq, CCtrSeq  FROM #BIZ_OUT_DataBlock1 ORDER BY IDX_NO, ROW_IDX
END TRY
BEGIN CATCH
-- SQL 오류인 경우는 여기서 처리가 된다
    IF @UseTransaction = N'1'
        ROLLBACK TRAN
    
    DECLARE   @ERROR_MESSAGE    NVARCHAR(4000)
            , @ERROR_SEVERITY   INT
            , @ERROR_STATE      INT
            , @ERROR_PROCEDURE  NVARCHAR(128)

    SELECT    @ERROR_MESSAGE    = ERROR_MESSAGE()
            , @ERROR_SEVERITY   = ERROR_SEVERITY() 
            , @ERROR_STATE      = ERROR_STATE() 
            , @ERROR_PROCEDURE  = ERROR_PROCEDURE()
    RAISERROR (@ERROR_MESSAGE, @ERROR_SEVERITY, @ERROR_STATE, @ERROR_PROCEDURE)

    RETURN
END CATCH

-- SQL 오류를 제외한 체크로직으로 발생된 오류는 여기서 처리
IF @HasError = N'1' AND @UseTransaction = N'1'
    ROLLBACK TRAN
DROP TABLE #BIZ_IN_DataBlock1DROP TABLE #BIZ_OUT_DataBlock1rollback 