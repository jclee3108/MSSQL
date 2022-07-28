
IF OBJECT_ID('_SGACompHouseCostChargeQueryCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostChargeQueryCHE
GO 

/************************************************************  
 설  명 - 데이터-사택료등록: 조회  
 작성일 - 20110315  
 작성자 - 천경민  
************************************************************/  
CREATE PROC dbo._SGACompHouseCostChargeQueryCHE  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT             = 0,  
    @ServiceSeq     INT             = 0,  
    @WorkingTag     NVARCHAR(10)    = '',  
    @CompanySeq     INT             = 1,  
    @LanguageSeq    INT             = 1,  
    @UserSeq        INT             = 0,  
    @PgmSeq         INT             = 0  
AS  
      
    DECLARE @docHandle     INT,  
            @CalcYm        NCHAR(6),  
            @CalcYmTo      NCHAR(6),  
            @HouseClass    INT,  
            @HouseSeq      INT,  
            @DongSerl      INT,  
            @EmpSeq        INT,  
            @DeptSeq       INT  
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
    SELECT @CalcYm     = ISNULL(CalcYm, ''),  
           @CalcYmTo   = ISNULL(CalcYmTo, ''),  
           @HouseClass = ISNULL(HouseClass, 0),  
           @HouseSeq   = ISNULL(HouseSeq, 0),  
           @DongSerl   = ISNULL(DongSerl, 0),  
           @EmpSeq     = ISNULL(EmpSeq, 0),  
           @DeptSeq    = ISNULL(DeptSeq, 0)  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock3', @xmlFlags)  
      WITH (CalcYm        NCHAR(6),  
            CalcYmTo      NCHAR(6),  
            HouseClass    INT,  
            HouseSeq      INT,  
            DongSerl      INT,  
            EmpSeq        INT,  
            DeptSeq       INT)  
  
  
    SELECT @CalcYmTo = '999912' WHERE @CalcYmTo = ''  
  
    -- 가변컬럼 헤더정보  
    SELECT B.MinorName AS Title,  
           A.CostType  AS TitleSeq,  
           'enFloat'   AS CellType,  
           A.OrderNo  
      INTO #Temp_Title2  
      FROM _TGACompHouseCostMaster AS A WITH(NOLOCK)  
           LEFT OUTER JOIN _TDAUMinor AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                       AND A.CostType   = B.MinorSeq  
     WHERE A.CompanySeq = @CompanySeq  
       AND (@HouseClass = 0 OR A.HouseClass = @HouseClass)  
       AND A.CalcType <> 1000599001  -- 적용방식이 별도계산이 아닌 것  
  
  
    SELECT DISTINCT IDENTITY(INT, 0, 1) AS ColIDX,  
           *  
      INTO #Temp_Title  
      FROM #Temp_Title2  
     ORDER BY OrderNo  
       
  
    -- 가변컬럼 헤더조회  
    SELECT Title, TitleSeq, CellType  
      FROM #Temp_Title  
     ORDER BY ColIDX  
  
  
    -- 고정컬럼 데이터집계  
    SELECT IDENTITY(INT, 0, 1)  AS RowIDX,  
           A.CalcYm,  
           A.HouseSeq,  
           H.MinorName          AS HouseClassName,  
           A.HouseClass,  
           B.DongName,  
           B.HoName,  
           --CASE WHEN LEFT(C.EnterDate,6) <= @CalcYm AND LEFT(C.LeavingDate,6) >= @CalcYm THEN D.EmpName ELSE NULL END AS EmpName,      
           --CASE WHEN LEFT(C.EnterDate,6) <= @CalcYm AND LEFT(C.LeavingDate,6) >= @CalcYm THEN D.EmpID   ELSE NULL END AS EmpId,      
           --CASE WHEN LEFT(C.EnterDate,6) <= @CalcYm AND LEFT(C.LeavingDate,6) >= @CalcYm THEN C.EmpSeq  ELSE NULL END AS EmpSeq,                     
           --CASE WHEN LEFT(C.EnterDate,6) <= @CalcYm AND LEFT(C.LeavingDate,6) >= @CalcYm THEN D.DeptName ELSE NULL  END AS DeptName,      
           --CASE WHEN LEFT(C.EnterDate,6) <= @CalcYm AND LEFT(C.LeavingDate,6) >= @CalcYm THEN D.DeptSeq ELSE NULL END AS DeptSeq,             
           F.EmpName,  
           F.EmpId,  
           C.EmpSeq,  
           G.DeptName,  
           E.DeptSeq,  
           ISNULL(A.CfmYn, '0')     AS CfmYn,  
           ISNULL(E.WaterCost, 0)   AS WaterCost,    -- 당월금액(상하수도료)  
           ISNULL(E.GeneralCost, 0) AS GeneralCost,  -- 당월금액(일반관리비)  
           ISNULL(E.WaterCost, 0) + ISNULL(E.GeneralCost, 0) + (SELECT SUM(ChargeAmt) FROM _TGAHouseCostChargeItem WHERE CompanySeq = @CompanySeq AND CalcYm = A.CalcYm AND HouseSeq = A.HouseSeq) AS TotalAmt  
      INTO #Temp_FixData  
      FROM _TGAHouseCostCalcInfo AS E WITH(NOLOCK)  
             LEFT OUTER JOIN _TGAHouseCostChargeItem AS A WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq  
                                                                       AND A.CalcYm     = E.CalcYm  
                                                                       AND A.HouseSeq   = E.HouseSeq  
           LEFT OUTER JOIN _TGACompHouseMaster   AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                                       AND A.HouseSeq   = B.HouseSeq  
           LEFT OUTER JOIN _TGACompHouseResident AS C WITH(NOLOCK) ON E.CompanySeq = C.CompanySeq  
                                                                       AND E.HouseSeq   = C.HouseSeq  
                                                                       AND E.EmpSeq     = C.EmpSeq  
                                                                       AND C.FinalUseYn = '1'  
           --LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq, '') AS D       ON C.EmpSeq     = D.EmpSeq  
           LEFT OUTER JOIN _TDAEmp                    AS F WITH(NOLOCK) ON E.CompanySeq = F.CompanySeq  
                                                                       AND E.EmpSeq     = F.EmpSeq  
           LEFT OUTER JOIN _TDADept                   AS G WITH(NOLOCK) ON E.CompanySeq = G.CompanySeq  
                                                                       AND E.DeptSeq    = G.DeptSeq        
           LEFT OUTER JOIN _TDAUMinor                 AS H WITH(NOLOCK) ON A.CompanySeq = H.CompanySeq  
                                                                       AND A.HouseClass = H.MinorSeq  
     WHERE A.CompanySeq = @CompanySeq  
       AND A.CalcYm >= @CalcYm   
       AND A.CalcYm <= @CalcYmTo  
       AND (@HouseClass = 0 OR A.HouseClass = @HouseClass)  
       AND (@HouseSeq   = 0 OR A.HouseSeq   = @HouseSeq)  
       AND (@DongSerl   = 0 OR B.DongSerl   = @DongSerl)  
       AND (@EmpSeq     = 0 OR E.EmpSeq     = @EmpSeq)  
       AND (@DeptSeq    = 0 OR E.DeptSeq    = @DeptSeq)  
     GROUP BY A.CalcYm, A.HouseSeq, H.MinorName, A.HouseClass, B.DongName, B.HoName, F.EmpName, F.EmpId, C.EmpSeq, G.DeptName, E.DeptSeq, A.CfmYn, E.WaterCost, E.GeneralCost,C.LeavingDate,C.EnterDate  
     ORDER BY A.CalcYm, B.HoName  
  
         --SELECT IDENTITY(INT, 0, 1) AS RowIDX,  
         --       @CalcYm AS CalcYm,  
         --       HouseSeq,  
         --       MAX(HouseClassName) AS HouseClassName,  
         --       MAX(HouseClass) AS HouseClass,  
         --       DongName,  
         --       MAX(HoName) AS HoName,  
         --       MAX(EmpName) AS EmpName,  
         --       MAX(EmpId) AS EmpId,  
         --       MAX(EmpSeq) AS EmpSeq,  
         --       MAX(DeptName) AS DeptName,  
         --       MAX(DeptSeq) AS DeptSeq,  
         --       GeneralCost,  
         --       WaterCost,  
         --       CfmYn,  
         --       0 AS TotalAmt  
         --  INTO #Temp_FixData  
         --  FROM #Temp_FixData1  
         -- GROUP BY HouseSeq,DongName,GeneralCost,WaterCost,CfmYn  
         -- ORDER BY HoName   
            
         -- UPDATE #Temp_FixData  
         --    SET TotalAmt = A.GeneralCost + A.WaterCost + (SELECT SUM(ChargeAmt) FROM _TGAHouseCostChargeItem WHERE CompanySeq = @CompanySeq AND CalcYm = A.CalcYm AND HouseSeq = A.HouseSeq)  
         --   FROM #Temp_FixData AS A  
  
  
    IF @WorkingTag = 'SUM'  -- 사택료조회_capro 시트1  
    BEGIN  
  
        -- 월별 사택구분 항목 SUM  
        SELECT IDENTITY(INT, 0, 1)  AS RowIDX,  
               CalcYm,  
               HouseClassName,  
               HouseClass,  
               SUM(WaterCost)   AS WaterCost,  
               SUM(GeneralCost) AS GeneralCost,  
               SUM(TotalAmt)    AS TotalAmt  
          INTO #Temp_FixData_SS1  
          FROM #Temp_FixData  
         GROUP BY CalcYm, HouseClassName, HouseClass  
  
  
        -- 고정컬럼 조회  
        SELECT * FROM #Temp_FixData_SS1 ORDER BY RowIDX  
  
  
        -- 가변데이터 조회  
        SELECT C.RowIDX         AS RowIDX,  
               A.ColIDX         AS ColIDX,  
                 SUM(B.ChargeAmt) AS ChargeAmt  
          FROM #Temp_Title AS A  
               JOIN _TGAHouseCostChargeItem AS B ON B.CompanySeq = @CompanySeq  
                                                     AND A.TitleSeq   = B.CostType  
               JOIN #Temp_FixData_SS1            AS C ON B.HouseClass = C.HouseClass  
                                                     AND B.CalcYm     = C.CalcYm  
         GROUP BY C.RowIDX, A.ColIDX  
      
    END  
    ELSE  
    BEGIN  
  
        -- 고정컬럼 조회  
        SELECT * FROM #Temp_FixData ORDER BY RowIDX  
  
  
        -- 가변데이터 조회  
        SELECT C.RowIDX    AS RowIDX,    
               A.ColIDX    AS ColIDX,    
               B.ChargeAmt AS ChargeAmt  
          FROM #Temp_Title AS A  
               JOIN _TGAHouseCostChargeItem AS B ON B.CompanySeq = @CompanySeq  
                                                     AND A.TitleSeq   = B.CostType  
               JOIN #Temp_FixData                AS C ON B.HouseSeq   = C.HouseSeq  
                                                     AND B.CalcYm     = C.CalcYm  
    END  
  
RETURN  