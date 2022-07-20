 
IF OBJECT_ID('mnpt_SACEEBgtChgReqPrcQuery') IS NOT NULL   
    DROP PROC mnpt_SACEEBgtChgReqPrcQuery  
GO  

-- v2018.02.06
  
-- 예산변경입력-조회 by 이재천   
CREATE PROC mnpt_SACEEBgtChgReqPrcQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @docHandle      INT,  
            -- 조회조건   
            @AccUnit        INT,  
            @DeptCCtrSeq    INT, 
            @BgtYMFr        NCHAR(6), 
            @BgtYMTo        NCHAR(6), 
            @BgtSeq         INT, 
            @AccSeq         INT, 
            @DeptSeq        INT, 
            @CCtrSeq        INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @AccUnit     = ISNULL( AccUnit     , 0 ),  
           @DeptCCtrSeq = ISNULL( DeptCCtrSeq , 0 ),  
           @BgtYMFr     = ISNULL( BgtYMFr     , '' ),  
           @BgtYMTo     = ISNULL( BgtYMTo     , '' ),  
           @BgtSeq      = ISNULL( BgtSeq      , 0 ),  
           @AccSeq      = ISNULL( AccSeq      , 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            AccUnit        INT,  
            DeptCCtrSeq    INT, 
            BgtYMFr        NCHAR(6), 
            BgtYMTo        NCHAR(6), 
            BgtSeq         INT, 
            AccSeq         INT 
           )    
    IF @BgtYMTo = '' 
    BEGIN 
        SELECT @BgtYMTo = '999912'
    END 

    DECLARE @EnvValue INT 

    SELECT @EnvValue = EnvValue
      FROM _TCOMEnv WITH(NOLOCK)
     WHERE CompanySeq = @CompanySeq
       AND EnvSeq = 4008
    
    SELECT @DeptSeq = CASE WHEN  @EnvValue = 4013001 THEN @DeptCCtrSeq ELSE 0 END,
           @CCtrSeq = CASE WHEN  @EnvValue = 4013002 THEN @DeptCCtrSeq ELSE 0 END
    
    
    SELECT A.AccUnit, 
           LEFT(A.AccDate,6) AccYM, 
           A.AccSeq, 
           C.BgtSeq, 
           A.UMCostType, 
           A.BgtDeptSeq AS DeptSeq, 
           A.BgtCCtrSeq AS CCtrSeq, 
           SUM(A.DrAmt + A.CrAmt) AS ResultAmt
      INTO #AccBgtResultAmt 
      FROM _TACSlipRow AS A 
      JOIN (
            SELECT AccSeq, MAX(BgtSeq) AS BgtSeq 
              FROM _TACBgtAcc
             WHERE CompanySeq = @CompanySeq
             GROUP BY AccSeq 
           ) AS C ON ( C.AccSeq = A.AccSeq )  
     WHERE CompanySeq = @CompanySeq 
       AND LEFT(A.AccDate,6) BETWEEN @BgtYMFr AND @BgtYMTo
       AND (BgtDeptSeq <> 0 OR BgtCCtrSeq <> 0 )
       AND A.IsSet = '1' 
       AND ( @BgtSeq = 0 OR C.BgtSeq = @BgtSeq ) 
       AND ( @AccUnit = 0 OR A.AccUnit = @AccUnit ) 
       AND ( @DeptSeq = 0 OR A.BgtDeptSeq = @DeptSeq ) 
       AND ( @CCtrSeq = 0 OR A.BgtCCtrSeq = @CCtrSeq ) 
       AND ( @AccSeq = 0 OR A.AccSeq = @AccSeq ) 
     GROUP BY A.AccUnit, LEFT(A.AccDate,6), A.AccSeq, C.BgtSeq, A.UMCostType, A.BgtDeptSeq, A.BgtCCtrSeq
    


    SELECT A.ChgSeq, 
           A.BgtYM,
           A.AccUnit,
           A.DeptSeq,
           A.CCtrSeq,
           A.IniOrAmd,
           A.SMBgtChangeKind,
           A.SMBgtChangeSource,
           A.AccSeq, 
           A.BgtSeq,
           A.UMCostType, 
           CASE WHEN A.SMBgtChangeKind = 4137002 THEN (-1) * A.BgtAmt ELSE A.BgtAmt END AS BgtAmt, 
           D.BgtName,
           F.AccName, 
           E.MinorName AS UMCostTypeName, 
           CASE WHEN @EnvValue = 4013001 THEN A.DeptSeq ELSE A.CCtrSeq END AS DeptCCtrSeq,
           CASE WHEN @EnvValue = 4013001 THEN A.DeptSeq ELSE A.CCtrSeq END AS DeptCCtrSeqOld,
           CASE WHEN @EnvValue = 4013001 THEN B.DeptName ELSE C.CCtrName END AS DeptCCtrName, 
            --ISNULL(CASE WHEN G.SMBgtChangeKind = 4137002 THEN (-1) * G.BgtAmt ELSE G.BgtAmt END, 0) AS IniBgtAmt,
            --E.MinorName AS UMCostTypeName, ISNULL(F.BgtAmt, 0) AS BfrBgtAmt, 
            --ISNULL(CASE WHEN A.SMBgtChangeKind = 4137002 THEN (-1) * A.BgtAmt ELSE A.BgtAmt END, 0) + ISNULL(F.BgtAmt, 0) AS ChgBgtAmt,
            ISNULL(A.ChgBgtDesc, '') AS ChgBgtDesc,
            ISNULL(A.UMChgType,0)    AS UMChgType, 
            H.MinorName AS UMChgTypeName, 

            CASE WHEN RIGHT(A.BgtYM,2) = '01' THEN I.Month01 
                 WHEN RIGHT(A.BgtYM,2) = '02' THEN I.Month02 
                 WHEN RIGHT(A.BgtYM,2) = '03' THEN I.Month03 
                 WHEN RIGHT(A.BgtYM,2) = '04' THEN I.Month04 
                 WHEN RIGHT(A.BgtYM,2) = '05' THEN I.Month05 
                 WHEN RIGHT(A.BgtYM,2) = '06' THEN I.Month06 
                 WHEN RIGHT(A.BgtYM,2) = '07' THEN I.Month07 
                 WHEN RIGHT(A.BgtYM,2) = '08' THEN I.Month08 
                 WHEN RIGHT(A.BgtYM,2) = '09' THEN I.Month09 
                 WHEN RIGHT(A.BgtYM,2) = '10' THEN I.Month10 
                 WHEN RIGHT(A.BgtYM,2) = '11' THEN I.Month11 
                 WHEN RIGHT(A.BgtYM,2) = '12' THEN I.Month12
                 ELSE 0 
                 END AS IniBgtAmt, 

            ISNULL(
                    CASE WHEN RIGHT(A.BgtYM,2) = '01' THEN I.Month01 
                         WHEN RIGHT(A.BgtYM,2) = '02' THEN I.Month02 
                         WHEN RIGHT(A.BgtYM,2) = '03' THEN I.Month03 
                         WHEN RIGHT(A.BgtYM,2) = '04' THEN I.Month04 
                         WHEN RIGHT(A.BgtYM,2) = '05' THEN I.Month05 
                         WHEN RIGHT(A.BgtYM,2) = '06' THEN I.Month06 
                         WHEN RIGHT(A.BgtYM,2) = '07' THEN I.Month07 
                         WHEN RIGHT(A.BgtYM,2) = '08' THEN I.Month08 
                         WHEN RIGHT(A.BgtYM,2) = '09' THEN I.Month09 
                         WHEN RIGHT(A.BgtYM,2) = '10' THEN I.Month10 
                         WHEN RIGHT(A.BgtYM,2) = '11' THEN I.Month11 
                         WHEN RIGHT(A.BgtYM,2) = '12' THEN I.Month12
                         ELSE 0 
                         END,0) - ISNULL(J.ResultAmt,0) AS BfrBgtAmt, 
            ISNULL( 
                    CASE WHEN RIGHT(A.BgtYM,2) = '01' THEN I.Month01 
                         WHEN RIGHT(A.BgtYM,2) = '02' THEN I.Month02 
                         WHEN RIGHT(A.BgtYM,2) = '03' THEN I.Month03 
                         WHEN RIGHT(A.BgtYM,2) = '04' THEN I.Month04 
                         WHEN RIGHT(A.BgtYM,2) = '05' THEN I.Month05 
                         WHEN RIGHT(A.BgtYM,2) = '06' THEN I.Month06 
                         WHEN RIGHT(A.BgtYM,2) = '07' THEN I.Month07 
                         WHEN RIGHT(A.BgtYM,2) = '08' THEN I.Month08 
                         WHEN RIGHT(A.BgtYM,2) = '09' THEN I.Month09 
                         WHEN RIGHT(A.BgtYM,2) = '10' THEN I.Month10 
                         WHEN RIGHT(A.BgtYM,2) = '11' THEN I.Month11 
                         WHEN RIGHT(A.BgtYM,2) = '12' THEN I.Month12
                         ELSE 0 
                         END,0) - ISNULL(J.ResultAmt,0) + ISNULL(CASE WHEN A.SMBgtChangeKind = 4137002 THEN (-1) * A.BgtAmt ELSE A.BgtAmt END,0) AS ChgBgtAmt

      FROM mnpt_TACBgt              AS A 
      LEFT OUTER JOIN _TDADept      AS B ON ( B.CompanySeq = @CompanySeq AND A.DeptSeq = B.DeptSeq ) 
      LEFT OUTER JOIN _TDACCtr      AS C ON ( C.CompanySeq = @CompanySeq AND A.CCtrSeq = C.CCtrSeq )
      LEFT OUTER JOIN _TACBgtItem   AS D ON ( D.CompanySeq = @CompanySeq AND A.BgtSeq = D.BgtSeq )
      LEFT OUTER JOIN _TDAUMinor    AS E ON ( E.CompanySeq = @CompanySeq AND A.UMCostType = E.MinorSeq )
      LEFT OUTER JOIN _TDAAccount   AS F ON ( F.CompanySeq = @CompanySeq AND F.AccSeq = A.AccSeq ) 
      LEFT OUTER JOIN _TDAUMinor    AS H ON ( H.CompanySeq = @CompanySeq AND H.MinorSeq = A.UMChgType ) 
      LEFT OUTER JOIN _TACBgt       AS G ON ( A.CompanySeq    = G.CompanySeq
                                          AND A.BgtYM         = G.BgtYM
                                          AND A.AccUnit       = G.AccUnit
                                          AND A.DeptSeq       = G.DeptSeq
                                          AND A.CCtrSeq       = G.CCtrSeq
                                          AND A.BgtSeq        = G.BgtSeq
                                          AND A.UMCostType    = G.UMCostType
                                          AND G.IniOrAmd      = '1' --최종예산
                                          AND G.SMBgtChangeSource = 0
                                            )
      LEFT OUTER JOIN mnpt_TACEEBgtAdj  AS I ON ( I.CompanySeq = @CompanySeq 
                                              AND I.StdYear = LEFT(A.BgtYM,4) 
                                              AND I.AccUnit = A.AccUnit
                                              AND I.DeptSeq = A.DeptSeq 
                                              AND I.CCtrSeq = A.CCtrSeq 
                                              AND I.AccSeq = A.AccSeq 
                                              AND I.UMCostType = A.UMCostType 
                                                )
      LEFT OUTER JOIN #AccBgtResultAmt  AS J ON ( J.AccYM = A.BgtYM
                                              AND J.AccUnit = A.AccUnit
                                              AND J.DeptSeq = A.DeptSeq 
                                              AND J.CCtrSeq = A.CCtrSeq 
                                              AND J.AccSeq = A.AccSeq 
                                              AND J.UMCostType = A.UMCostType 
                                                )
     WHERE A.CompanySeq = @CompanySeq 
       AND ( @AccUnit = 0 OR A.AccUnit = @AccUnit ) 
       AND ( @DeptSeq = 0 OR A.DeptSeq = @DeptSeq ) 
       AND ( @CCtrSeq = 0 OR A.CCtrSeq = @CCtrSeq ) 
       AND ( A.BgtYM BETWEEN @BgtYMFr AND @BgtYMTo ) 
       AND ( @BgtSeq = 0 OR A.BgtSeq = @BgtSeq ) 
       AND ( @AccSeq = 0 OR A.AccSeq = @AccSeq ) 
       AND A.SMBgtChangeSource = 4070003
      
    RETURN  
    GO
begin tran 
exec mnpt_SACEEBgtChgReqPrcQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <AccSeq />
    <AccUnit>1</AccUnit>
    <DeptCCtrSeq />
    <BgtYMFr>201801</BgtYMFr>
    <BgtYMTo>201802</BgtYMTo>
    <BgtSeq />
    <SMBgtChangeSource>4070003</SMBgtChangeSource>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=13820154,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=167,@PgmSeq=13820134
rollback 