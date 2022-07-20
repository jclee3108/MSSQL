     
IF OBJECT_ID('mnpt_SPJTWorkPlanTemplateDlgQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTWorkPlanTemplateDlgQuery      
GO      
      
-- v2017.09.18
      
-- 작업계획템플릿-조회 by 이재천  
CREATE PROC mnpt_SPJTWorkPlanTemplateDlgQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @PJTName    NVARCHAR(100),   
            @EnShipName NVARCHAR(100),   
            @ShipName   NVARCHAR(100),   
            @CustSeq    INT, 
            @PJTTypeSeq INT 
      
    SELECT @PJTName    = ISNULL( PJTName      , '' ),   
           @EnShipName = ISNULL( EnShipName   , '' ),  
           @ShipName   = ISNULL( ShipName     , '' ),   
           @CustSeq    = ISNULL( CustSeq      , 0 ),   
           @PJTTypeSeq = ISNULL( PJTTypeSeq   , 0 )
      FROM #BIZ_IN_DataBlock1    
    
    --------------------------------------------------
    -- 할증구분코드를 할증구분명칭으로 바꿔주기, Srt
    --------------------------------------------------
    CREATE TABLE #ExtraSeq
    (
        IDX_NO          INT IDENTITY, 
        WorkPlanSeq     INT, 
        ExtraGroupSeq   NVARCHAR(500)
    )
    
    INSERT INTO #ExtraSeq ( WorkPlanSeq, ExtraGroupSeq ) 
    SELECT WorkPlanSeq, '<XmlString><Code>' + REPLACE(ExtraGroupSeq,',','</Code><Code>') + '</Code></XmlString>'
      FROM mnpt_TPJTWorkPlan 
    
    CREATE TABLE #CheckExtraSeq 
    (
        WorkPlanSeq     INT, 
        UMExtraType     INT, 
        UMExtraTypeName NVARCHAR(200)
    )
    CREATE TABLE #GroupExtraName
    (
        WorkPlanSeq     INT, 
        MultiExtraName  NVARCHAR(500)
    )
    
    DECLARE @Cnt            INT, 
            @ExtraGroupSeq  NVARCHAR(500), 
            @WorkPlanSeq    INT, 
            @ExtraGroupName NVARCHAR(500)

    SELECT @Cnt = 1 

    WHILE ( 1 = 1 ) 
    BEGIN 
        
        SELECT @ExtraGroupSeq = ExtraGroupSeq, 
               @WorkPlanSeq   = WorkPlanSeq
          FROM #ExtraSeq 
         WHERE IDX_NO = @Cnt 
        

        TRUNCATE TABLE #CheckExtraSeq 

        INSERT INTO #CheckExtraSeq ( WorkPlanSeq, UMExtraType, UMExtraTypeName ) 
        SELECT @WorkPlanSeq, Code, B.MinorName
          FROM _FCOMXmlToSeq(0, @ExtraGroupSeq) AS A 
          JOIN _TDAUMinor     AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.Code ) 
        

        SELECT @ExtraGroupName = '' 

        SELECT @ExtraGroupName = @ExtraGroupName + ',' + UMExtraTypeName
          FROM #CheckExtraSeq 
        
        INSERT INTO #GroupExtraName ( WorkPlanSeq, MultiExtraName ) 
        SELECT @WorkPlanSeq, STUFF(@ExtraGroupName,1,1,'')


        IF @Cnt >= ISNULL((SELECT MAX(IDX_NO) FROM #ExtraSeq),0) 
        BEGIN
            BREAK 
        END 
        ELSE
        BEGIN
            SELECT @Cnt = @Cnt + 1 
        END 
    END 
    --------------------------------------------------
    -- 할증구분코드를 할증구분명칭으로 바꿔주기, End  
    --------------------------------------------------
    
    --------------------------------------------------
    -- 최종 모선항차구하기
    --------------------------------------------------
    SELECT Z.ShipSeq, Z.ShipSerl, Z.ShipSerlNo, Z.AgentName
      INTO #ShipSerlNo
      FROM mnpt_TPJTShipDetail AS Z 
      JOIN ( 
            SELECT ShipSeq, MAX(ShipSerlNo) AS ShipSerlNo 
                FROM mnpt_TPJTShipDetail AS A 
                WHERE A.CompanySeq = @CompanySeq 
                GROUP BY ShipSeq
           ) AS Y ON ( Y.ShipSeq = Z.ShipSeq AND Y.ShipSerlNo = Z.ShipSerlNo )
     WHERE Z.CompanySeq = @CompanySeq 
    --------------------------------------------------
    -- 최종 모선항차구하기, End
    --------------------------------------------------

    --------------------------------------------------
    -- 최종조회 
    --------------------------------------------------
    SELECT CASE WHEN @WorkingTag = 'Apply' THEN 0 ELSE A.WorkPlanSeq END WorkPlanSeq,
           A.PJTSeq,        -- 프로젝트코드
           P.PJTName,       -- 프로젝트명
           P.PJTNo,         -- 프로젝트번호 
           C.PJTTypeName,   -- PJTTypeName
           D.CustName,      -- 거래처 
           CASE WHEN E.UMCustKindName IS NULL OR LEN(E.UMCustKindName) = 0 THEN '' 
           	ELSE  SUBSTRING(E.UMCustKindName, 1,  LEN(E.UMCustKindName) -1 ) END   AS UMCustKindName, -- 거래처종류
           F.CustName			AS AGCustName,  -- 실화주 
           B.BizUnitName,   -- 사업부문
           A.ShipSeq, 
           G.ShipSerl, 
           H.IFShipCode + '-' + LEFT(G.ShipSerlNo,4) + '-' + RIGHT(G.ShipSerlNo,3) AS ShipSerlNo, -- 모선항차 
           H.EnShipName,    -- 모선 
           H.LOA,           -- LOA
           
           CASE WHEN A.ShipSeq = 0 OR A.ShipSeq IS NULL THEN (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015815002) 
                ELSE (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = 1015815001) 
                END AS UMWorkDivision, --작업구분
           
           A.UMWorkType,    -- 작업항목코드 
           I.MinorName AS UMWorkTypeName, -- 작업항목
           S.PlanQty AS GoodsQty, 
           S.PlanMTWeight AS GoodsMTWeight, 
           S.PlanCBMWeight AS GoodsCBMWeight, 
           '' AS ExtraGroupSeq, 
           '' AS MultiExtraName, -- 할증구분 
           A.EmpSeq, 
           L.EmpName,   -- 총괄포맨 
           CASE WHEN @WorkingTag = 'Apply' THEN G.AgentName ELSE '' END AgentName, -- 대리점 
           CASE WHEN @WorkingTag = 'Apply' THEN '1' ELSE '0' END IsAdd, -- 적용여부
           A.WorkPlanSeq AS SourceWorkPlanSeq, -- 원천작업계획코드
           A.UMLoadType, 
           R.MinorName UMLoadTypeName -- 하역방식 

      FROM mnpt_TPJTWorkPlan        AS A 
      LEFT OUTER JOIN _TPJTProject  AS P ON ( P.CompanySeq = @CompanySeq AND P.PJTSeq = A.PJTSeq ) 
      LEFT OUTER JOIN _TDABizUnit   AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = P.BizUnit ) 
      LEFT OUTER JOIN _TPJTType     AS C ON ( C.CompanySeq = @CompanySeq AND C.PJTTypeSeq = P.PJTTypeSeq ) 
      LEFT OUTER JOIN _TDACust      AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = P.CustSeq ) 
      LEFT OUTER JOIN ( -- 거래처종류 가로로 나열
                        SELECT CustSeq,
								(
                                    SELECT Y.Minorname + ','
                                      FROM _TDACustKind         AS Z 
                                      LEFT OUTER JOIN _TDAUMinor AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.UMCustKind ) 
                                     WHERE Z.CompanySeq	= @CompanySeq
                                       AND Z.CustSeq = Q.CustSeq
                                     ORDER BY CustSeq for xml path('')
                                ) AS UMCustKindName
                          FROM _TDACust AS Q
                         WHERE CompanySeq = @CompanySeq
                         GROUP BY CustSeq
                      ) AS E ON ( E.CustSeq = P.CustSeq ) 
      LEFT OUTER JOIN _TDACust              AS F ON ( F.CompanySeq = @CompanySeq AND F.CustSeq = P.AGCustSeq ) 
      LEFT OUTER JOIN mnpt_TPJTShipMaster   AS H ON ( H.CompanySeq = @CompanySeq AND H.ShipSeq = A.ShipSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS I ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = A.UMWorkType )
      LEFT OUTER JOIN mnpt_TPJTProject      AS J ON ( J.CompanySeq = @CompanySeq AND J.PJTSeq = P.PJTSeq ) 
      LEFT OUTER JOIN _TDAEmp               AS L ON ( L.CompanySeq = @CompanySeq AND L.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN (
                        SELECT Z.WorkPlanSeq, Count(1) AS UMBisWorkTypeCnt 
                          FROM mnpt_TPJTWorkPlanItem AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                         GROUP BY Z.WorkPlanSeq 
                      ) AS M ON ( M.WorkPlanSeq = A.WorkPlanSeq ) 
      LEFT OUTER JOIN #GroupExtraName   AS O ON ( O.WorkPlanSeq = A.WorkPlanSeq ) 
      LEFT OUTER JOIN #ShipSerlNo       AS G ON ( G.ShipSeq = H.ShipSeq ) 
      LEFT OUTER JOIN mnpt_TPJTShipWorkPlanFinish   AS S ON ( S.CompanySeq = @CompanySeq AND S.PJTSeq = A.PJTSeq AND S.ShipSeq = A.ShipSeq AND S.ShipSerl = A.ShipSerl ) 
      LEFT OUTER JOIN _TDAUMinor        AS R ON ( R.CompanySeq = @CompanySeq AND R.MinorSeq = A.UMLoadType ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND A.IsTemplate = '1' 
       AND ( (@WorkingTag = 'Apply' AND EXISTS (SELECT 1 FROM #BIZ_IN_DataBlock1 WHERE WorkPlanSeq = A.WorkPlanSeq)) OR @WorkingTag = '' )

       -- 조회버튼 조회조건
       AND ( (@WorkingTag = '' AND (@PJTName = '' OR P.PJTName LIKE @PJTName + '%'))          OR @WorkingTag = 'Apply' )
       AND ( (@WorkingTag = '' AND (@EnShipName = '' OR H.EnShipName LIKE @EnShipName + '%')) OR @WorkingTag = 'Apply' )
       AND ( (@WorkingTag = '' AND (@ShipName = '' OR H.ShipName LIKE @ShipName + '%'))       OR @WorkingTag = 'Apply' )
       AND ( (@WorkingTag = '' AND (@CustSeq = 0 OR P.CustSeq = @CustSeq))              OR @WorkingTag = 'Apply' )
       AND ( (@WorkingTag = '' AND (@PJTTypeSeq = 0 OR P.PJTTypeSeq = @PJTTypeSeq))     OR @WorkingTag = 'Apply' )
     ORDER BY P.PJTName, A.WorkSrtTime
    
    RETURN 
