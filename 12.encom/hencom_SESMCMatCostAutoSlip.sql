IF OBJECT_ID('hencom_SESMCMatCostAutoSlip') IS NOT NULL 
    DROP PROC hencom_SESMCMatCostAutoSlip
GO 

-- v2017.04.06 

-- 제조원가재료비대체전표처리-자동전표생성 by이재천 
CREATE PROC hencom_SESMCMatCostAutoSlip
    @CompanySeq INT = 1, 
    @UserSeq    INT = 1 
AS 



declare @TransSeq int 
select @TransSeq = 3128


--select * from _TESMCProdSlipM where Transseq = @TransSeq
--select * from _TESMCProdSlipD where Transseq = @TransSeq 


select * From _TACSlip where SlipMstSeq = (select SlipMstSeq From _TACSlipRow where SlipSeq = (select SlipSeq from _TESMCProdSlipM where Transseq = @TransSeq))
    
    CREATE TABLE #TACSlip_Sub 
    (
        CompanySeq      INT, 
        SlipMstSeq      INT, 
        AccUnit         INT, 
        SlipUnit        INT, 
        AccDate         NCHAR(8), 
        SlipKind        INT, 
        RegEmpSeq       INT, 
        RegDeptSeq      INT, 
        Remark          NVARCHAR(200), 
        SMCurrStatus    INT, 
        AptDate         NCHAR(8), 
        AptEmpSeq       INT, 
        AptDetpSeq      INT, 
        AptRemark       NVARCHAR(200), 
        SMCheckStatus   INT, 
        CheckOrigin     INT, 
        IsSet           NCHAR(1), 
        SetEmpSeq       INT, 
        SetDeptSeq      INT, 
        LastUserSeq     INT, 
        LastDateTime    DATETIME, 
        RegDateTime     DATETIME, 
        RegAccDate      NCHAR(8)
    )
    
    INSERT INTO #TACSlip_Sub
    (
        CompanySeq    , SlipMstSeq    , AccUnit       , SlipUnit      , AccDate       , 
        SlipKind      , RegEmpSeq     , RegDeptSeq    , Remark        , SMCurrStatus  , 
        AptDate       , AptEmpSeq     , AptDetpSeq    , AptRemark     , SMCheckStatus , 
        CheckOrigin   , IsSet         , SetEmpSeq     , SetDeptSeq    , LastUserSeq   , 
        LastDateTime  , RegDateTime   , RegAccDate     
    )
    SELECT @CompanySeq, 0, 1 AS AccUnit, 18, CONVERT(NCHAR(8),DATEADD(DAY,-1,DATEADD(MONTH,1,B.CostYM + '01')),112), 
           10036, 0, 0, '', 0, 
           '', 0, 0, '', 0, 
           0, '1', A.EmpSeq, C.DeptSeq, @UserSeq, 
           GETDATE(), GETDATE(), CONVERT(NCHAR(8),DATEADD(DAY,-1,DATEADD(MONTH,1,B.CostYM + '01')),112)
      FROM _TESMCProdSlipM  AS A 
                 JOIN _TESMDCostKey    AS B ON ( B.CompanySeq = @CompanySeq AND B.CostKeySeq = A.CostKeySeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS C ON ( C.EmpSeq = A.EmpSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.TransSeq = @TransSeq
    
    SELECT (SELECT Initial FROM _TCOMUnitInitial where CompanySeq = @CompanySeq and SMInitialUnit = 1033001 and Unit = A.AccUnit) + '-' +
           (SELECT Initial FROM _TCOMUnitInitial where CompanySeq = @CompanySeq and SMInitialUnit = 1033008 and Unit = A.SlipUnit ) + '-' + A.AccDate + '-' + 
           RIGHT('000' + CONVERT(nvarchar(100),ROW_NUMBER() OVER (PARTITION BY A.AccDate, A.SlipUnit, A.AccUnit ORDER BY A.AccDate, A.SlipUnit, A.AccUnit) + isnull(B.SlipMstIDMaxSerl,0)),4) AS SlipMstID, 

           RIGHT('000' + CONVERT(nvarchar(100),ROW_NUMBER() OVER (PARTITION BY A.AccDate, A.SlipUnit, A.AccUnit ORDER BY A.AccDate, A.SlipUnit, A.AccUnit) + isnull(B.SlipMstIDMaxSerl,0)),4) AS SlipNo, 
           
           RIGHT('000' + CONVERT(nvarchar(100),ROW_NUMBER() OVER (PARTITION BY A.AccDate, A.SlipUnit, A.AccUnit ORDER BY A.AccDate, A.SlipUnit, A.AccUnit)+isnull(B.SetSlipIDMaxSerl,0)),4) AS SetSlipNo, 
           
           (SELECT Initial FROM _TCOMUnitInitial where CompanySeq = @CompanySeq and SMInitialUnit = 1033001 and Unit = A.AccUnit) + '-' + 
           CONVERT(nchar(8),A.AccDate) + '-' + 
           RIGHT('000' + CONVERT(nvarchar(100),ROW_NUMBER() OVER (PARTITION BY A.AccDate, A.SlipUnit, A.AccUnit ORDER BY A.AccDate, A.SlipUnit, A.AccUnit)+isnull(B.SetSlipIDMaxSerl,0)),4) AS SetSlipID ,
           A.CompanySeq    ,
           A.SlipMstSeq    ,
           A.AccUnit       ,
           A.SlipUnit      ,
           A.AccDate       ,
           A.SlipKind      ,
           A.RegEmpSeq     ,
           A.RegDeptSeq    ,
           A.Remark        ,
           A.SMCurrStatus  ,
           A.AptDate       ,
           A.AptEmpSeq     ,
           A.AptDetpSeq    ,
           A.AptRemark     ,
           A.SMCheckStatus ,
           A.CheckOrigin   ,
           A.IsSet         ,
           A.SetEmpSeq     ,
           A.SetDeptSeq    ,
           A.LastUserSeq   ,
           A.LastDateTime  ,
           A.RegDateTime   ,
           A.RegAccDate    
      INTO #TACSlip  
      FROM #TACSlip_Sub AS A 
      LEFT OUTER JOIN ( 
                        SELECT Z.AccDate , Z.AccUnit , Z.SlipUnit , MAX(CONVERT(INT,Y.MaxSerl)) AS SlipMstIDMaxSerl, MAX(CONVERT(INT,Q.MaxSerl)) AS SetSlipIDMaxSerl
                          FROM #TACSlip_Sub as z 
                          JOIN _TCOMCreateNoMaxAC AS Y ON ( Y.CompanySeq = @CompanySeq 
                                                        AND Y.TableName = '_TACSlip' 
                                                        AND Y.YMDInfo = Z.AccDate 
                                                        AND Y.FirstInfo =  (SELECT Initial FROM _TCOMUnitInitial WHERE CompanySeq = @CompanySeq AND SMInitialUnit = 1033001 AND Unit = Z.AccUnit) 
                                                        AND Y.NoColumnName = 'SlipMstID' 
                                                        AND Y.SecondInfo = (SELECT Initial FROM _TCOMUnitInitial WHERE CompanySeq = @CompanySeq AND SMInitialUnit = 1033008 AND Unit = Z.SlipUnit )
                                                          ) 
                          JOIN _TCOMCreateNoMaxAC AS Q ON ( Q.CompanySeq = @CompanySeq 
                                                        AND Q.TableName = '_TACSlip' 
                                                        AND Q.YMDInfo = Z.AccDate 
                                                        AND Q.FirstInfo =  (SELECT Initial FROM _TCOMUnitInitial WHERE CompanySeq = @CompanySeq AND SMInitialUnit = 1033001 AND Unit = Z.AccUnit) 
                                                        AND Q.NoColumnName = 'SetSlipID' 
                                                          ) 
                        GROUP BY Z.AccDate , Z.AccUnit , Z.SlipUnit 
                    ) AS B ON ( B.AccDate = A.AccDate AND B.AccUnit = A.AccUnit AND B.SlipUnit = A.SlipUnit ) 
    



    DECLARE @SlipMstSeq INT 

    EXEC @SlipMstSeq = dbo._SCOMCreateSeq @CompanySeq, '_TACSlip', 'SlipMstSeq', 1
    -- Temp Talbe 에 생성된 키값 UPDATE
    UPDATE A
       SET SlipMstSeq = @SlipMstSeq + 1
      FROM #TACSlip AS A 
    
    SELECT * FROM #TACSlip 
        
    RETURN 
go
begin tran 
    exec hencom_SESMCMatCostAutoSlip
rollback 