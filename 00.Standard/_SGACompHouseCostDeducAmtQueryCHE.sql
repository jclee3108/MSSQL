    
IF OBJECT_ID('_SGACompHouseCostDeducAmtQueryCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostDeducAmtQueryCHE
GO 

/************************************************************    
 설  명 - 데이터-사택료 급상여반영 조회  
 작성일 - 20110512    
 작성자 - 전경만   
************************************************************/    
CREATE PROC dbo._SGACompHouseCostDeducAmtQueryCHE  
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT             = 0,    
    @ServiceSeq     INT             = 0,    
    @WorkingTag     NVARCHAR(10)    = '',    
    @CompanySeq     INT             = 1,    
    @LanguageSeq    INT             = 1,    
    @UserSeq        INT             = 0,    
    @PgmSeq         INT             = 0    
AS    
  
    DECLARE @docHandle  INT,    
            @HouseDate  NCHAR(6),  
            @HouseClass  INT  
   
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
    
    SELECT @HouseDate   = ISNULL(HouseDate, ''),  
     @HouseClass = ISNULL(HouseClass, 0)   
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
      WITH (HouseDate       NCHAR(6),  
   HouseClass  INT)    
    
    
 IF @HouseDate = ''  
  SELECT @HouseDate = LEFT(CONVERT(NCHAR(8),DATEADD(MONTH,-1,GETDATE()),112),6)  
    
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
    SELECT Title, TitleSeq--, CellType    
      FROM #Temp_Title    
     ORDER BY ColIDX    
       
       
    -- 사용자 정의코드에 연결되어있는 추가정보 가져오기  
   CREATE TABLE #TempTitle(IDX INT IDENTITY(0,1), HouseClass INT, CodeHelpConst INT, TitleSeq INT,  
       MajorSeq INT, Serl INT, ValueSeq INT)  
 INSERT INTO #TempTitle  
 SELECT DISTINCT A.HouseClass,  
     F.CodeHelpConst,  
     CASE WHEN F.SMInputType IN (1027003, 1027005) THEN -1 ELSE F.TitleSerl END AS TitleSeq,  
     M.MajorSeq,  
     F.TitleSerl AS Serl  
     ,V.ValueSeq  
      FROM _TGAHouseCostChargeItem AS A  
     LEFT OUTER JOIN _TDAUMinor AS M WITH(NOLOCK) ON M.CompanySeq = A.CompanySeq  
                AND M.MinorSeq = A.HouseClass  
     LEFT OUTER JOIN _TCOMUserDefine AS F WITH(NOLOCK) ON F.CompanySeq = M.CompanySeq  
               AND F.DefineUnitSeq = M.MajorSeq  
               AND F.TableName = '_TDAUMajor'  
     LEFT OUTER JOIN _TDAUMinorValue AS V WITH(NOLOCK) ON V.CompanySeq = F.CompanySeq  
               AND V.MajorSeq = F.DefineUnitSeq  
               AND V.ValueSeq > 0  
               AND V.Serl = F.TitleSerl  
               AND V.MinorSeq = M.MinorSeq  
  WHERE A.CompanySeq = @CompanySeq  
    AND M.MajorSeq = 1000598  
    AND F.SMInputType IN (1027003,1027005)  
  
      
    -- 코드헬프의 명칭을 가져오기 위한 임시테이블 생성    
    CREATE TABLE #temp    
    (    
  --IDX   INT,  
     CodeHelpSeq INT,    
     Seq   INT,  
     IsMinorValue NCHAR(1),    -- MinorValue사용여부      
     MajorSeq  INT  
    )  
  
    INSERT INTO #temp(CodeHelpSeq, Seq, IsMinorValue,  MajorSeq)  
         SELECT DISTINCT A.CodeHelpConst, C.ValueSeq , '0' , 0  
           FROM #TempTitle AS A JOIN _TDAUMinorValue AS C ON C.CompanySeq = @CompanySeq  
                                                         AND C.MajorSeq   = A.MajorSeq  
                                                         AND C.Serl       = A.Serl  
                                                         AND C.ValueSeq   > 0  
          WHERE A.TitleSeq = -1  -- 코드헬프로 설정된 컬럼이다.  
            AND A.CodeHelpConst <> 19998  
            AND A.CodeHelpConst <> 10009  
  
    -- 명칭을 가져온다.  
      -- 실행 후에는 ValueName 컬럼이 자동생성되어 진다.  
    EXEC _SCOMGetCodeHelpDataName @CompanySeq, @LanguageSeq, '#temp', '', '', '1'  
  
 SELECT DISTINCT A.HouseClass,  
     --CASE WHEN B.CodeHelpSeq = 10003 THEN A.ValueSeq END BizUnit,  
     MAX(CASE WHEN B.CodeHelpSeq = 20004 THEN A.ValueSeq END) AS ItemSeq,  
     MAX(CASE WHEN B.CodeHelpSeq = 20004 THEN B.ValueName END) AS ItemName,  
     MAX(CASE WHEN B.CodeHelpSeq = 20002 THEN B.ValueName END) AS PbName,  
     MAX(CASE WHEN B.CodeHelpSeq = 20002 THEN A.ValueSeq END) AS PbSeq  
     --CASE WHEN B.CodeHelpSeq = 20001 THEN A.ValueSeq END PuSeq  
   INTO #RESULT  
   FROM #TempTitle AS A  
     JOIN _TDAUMinorValue AS V WITH(NOLOCK) ON V.MajorSeq = A.MajorSeq  
             AND A.Serl = V.Serl  
   JOIN #temp AS B ON B.CodeHelpSeq = A.CodeHelpConst  
         AND B.Seq = V.ValueSeq  
         AND B.Seq = A.ValueSeq  
  WHERE V.CompanySeq = @CompanySeq  
  GROUP BY A.HouseClass  
--select * from #Result  
    -- 고정컬럼 데이터집계    
    SELECT IDENTITY(INT, 0, 1)  AS RowIDX,    
           A.CalcYm    AS HouseDate,    
           A.HouseSeq,    
           F.MinorName          AS HouseClassName,    
           A.HouseClass,    
           B.DongName,    
           B.HoName,    
           CASE WHEN LEFT(C.EnterDate,6) <= @HouseDate AND LEFT(C.LeavingDate,6) >= @HouseDate THEN D.EmpName ELSE NULL END AS EmpName,      
           CASE WHEN LEFT(C.EnterDate,6) <= @HouseDate AND LEFT(C.LeavingDate,6) >= @HouseDate THEN D.EmpID   ELSE NULL END AS EmpId,      
           CASE WHEN LEFT(C.EnterDate,6) <= @HouseDate AND LEFT(C.LeavingDate,6) >= @HouseDate THEN C.EmpSeq  ELSE NULL END AS EmpSeq,                     
           CASE WHEN LEFT(C.EnterDate,6) <= @HouseDate AND LEFT(C.LeavingDate,6) >= @HouseDate THEN D.DeptName ELSE NULL  END AS DeptName,      
           CASE WHEN LEFT(C.EnterDate,6) <= @HouseDate AND LEFT(C.LeavingDate,6) >= @HouseDate THEN D.DeptSeq ELSE NULL END AS DeptSeq,      
           --D.EmpName,    
           --D.EmpId,    
           --C.EmpSeq,    
           --D.DeptName,    
           --D.DeptSeq,    
           R.ItemSeq,  
           R.ItemName,  
           R.PbName,   
           R.PbSeq,  
           D.PuSeq,  
           D.PuName,  
           H.IsPay AS Sel,  
           H.Seq,  
           ISNULL(A.CfmYn, '0')     AS CfmYn,    
           ISNULL(E.WaterCost, 0)   AS WaterCost,    -- 당월금액(상하수도료)    
           ISNULL(E.GeneralCost, 0) AS GeneralCost,  -- 당월금액(일반관리비)    
           ISNULL(E.WaterCost, 0) + ISNULL(E.GeneralCost, 0) + (SELECT SUM(ChargeAmt) FROM _TGAHouseCostChargeItem WHERE CompanySeq = @CompanySeq AND CalcYm = A.CalcYm AND HouseSeq = A.HouseSeq) AS TotalAmt    
      INTO #Temp_FixData    
      FROM _TGAHouseCostChargeItem AS A WITH(NOLOCK)    
           LEFT OUTER JOIN _TGACompHouseMaster   AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                                       AND A.HouseSeq   = B.HouseSeq    
           LEFT OUTER JOIN _TGACompHouseResident AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq    
                                                                       AND B.HouseSeq   = C.HouseSeq    
                                                                       AND C.FinalUseYn = '1'    
           LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq, '') AS D       ON C.EmpSeq     = D.EmpSeq    
           LEFT OUTER JOIN _TGAHouseCostCalcInfo AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq    
                    AND A.CalcYm     = E.CalcYm    
                                                                       AND A.HouseSeq   = E.HouseSeq    
           LEFT OUTER JOIN _TDAUMinor                 AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq    
                                                                       AND A.HouseClass = F.MinorSeq   
     LEFT OUTER JOIN _TDAUMinorValue     AS M WITH(NOLOCK) ON M.CompanySeq = A.CompanySeq  
                    AND M.MinorSeq = A.HouseClass  
       LEFT OUTER JOIN #RESULT       AS R ON R.HouseClass = A.HouseClass  
     LEFT OUTER JOIN _TGACompHouseCostDeducAmt AS H WITH(NOLOCK) ON H.CompanySeq = A.CompanySeq  
                     AND H.CalcYm = CONVERT(NCHAR(6),DATEADD(MONTH,1,A.CalcYm+'01'),112) --사택료 적용 년월과 계산년월은 다른거임.  
                     AND H.HouseSeq = C.HouseSeq  
                     AND H.EmpSeq = C.EmpSeq  
     WHERE A.CompanySeq = @CompanySeq    
       AND A.CalcYm = RTRIM(LTRIM(@HouseDate))  
       AND (@HouseClass = 0 OR A.HouseClass = @HouseClass)    
    --AND C.EmpSeq <> 0   
     GROUP BY A.CalcYm, A.HouseSeq, F.MinorName, A.HouseClass, B.DongName, B.HoName,   
     D.EmpName, D.EmpId, C.EmpSeq, D.DeptName, D.DeptSeq, A.CfmYn, E.WaterCost, E.GeneralCost,  
     D.PuSeq, D.PuName, R.ItemSeq, R.ItemName, R.PbName, R.PbSeq, H.IsPay, H.Seq,C.LeavingDate,C.EnterDate  
     ORDER BY B.HoName--A.CalcYm, A.HouseSeq    
  
--select * from _TGAHouseCostChargeItem where CalcYm ='201103' and HouseSeq = 233  
    
    
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
                                                     AND B.CalcYm     = C.HouseDate    
  
    
RETURN    
  