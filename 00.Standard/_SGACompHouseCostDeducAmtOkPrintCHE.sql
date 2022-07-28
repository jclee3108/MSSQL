
IF OBJECT_ID('_SGACompHouseCostDeducAmtOkPrintCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostDeducAmtOkPrintCHE
GO 

/************************************************************    
 설  명 - 데이터-사택료 급상여반영 출력  
 작성일 - 201110.18  
 작성자 -  
************************************************************/    
CREATE PROC _SGACompHouseCostDeducAmtOkPrintCHE
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
     IsMinorValue NCHAR(1),    -- MinorValue사용여부      MajorSeq  INT  
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
      
    SELECT LEFT(A.CalcYm,4) + '년 ' + SUBSTRING(A.CalcYm,5,2) + '월' AS BaseDate,  
           A.CalcYm    AS HouseDate,    
           A.HouseSeq,    
           --F.MinorName          AS HouseClassName,  --출력물에서 쓰이지 않기 떄문에 급여반영 구분자로 이용  
           'A'  AS HouseClassName,  
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
           --ISNULL(E.WaterCost, 0) + ISNULL(E.GeneralCost, 0) + (SELECT SUM(ChargeAmt) FROM _TGAHouseCostChargeItem WHERE CompanySeq = @CompanySeq AND CalcYm = A.CalcYm AND HouseSeq = A.HouseSeq) AS TotalAmt  ,  
           MAX(CASE WHEN ASum.CostType = 1000597003 THEN ASum.ChargeAmt ELSE 0 END) AS CleanAmt,  
           MAX(CASE WHEN ASum.CostType = 1000597004 THEN ASum.ChargeAmt ELSE 0 END) AS BroadAmt,  
           MAX(CASE WHEN ASum.CostType = 1000597005 THEN ASum.ChargeAmt ELSE 0 END) AS FumiAmt,  
           MAX(CASE WHEN ASum.CostType = 1000597006 THEN ASum.ChargeAmt ELSE 0 END) AS FoodAmt,  
           MAX(CASE WHEN ASum.CostType = 1000597007 THEN ASum.ChargeAmt ELSE 0 END) AS WomenSocAmt,  
           MAX(CASE WHEN ASum.CostType = 1000597010 THEN ASum.ChargeAmt ELSE 0 END) AS RemarkAmt1,  
           MAX(CASE WHEN ASum.CostType = 1000597009 THEN ASum.ChargeAmt ELSE 0 END) AS RemarkAmt2,  
           MAX(CASE WHEN ASum.CostType = 1000597008 THEN ASum.ChargeAmt ELSE 0 END) AS RemarkAmt3  
      FROM _TGAHouseCostChargeItem AS A   
  
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
           LEFT OUTER JOIN (SELECT CalcYm,HouseSeq,CostType,SUM(ChargeAmt) AS ChargeAmt  
                              FROM _TGAHouseCostChargeItem  
                             WHERE CompanySeq = @CompanySeq   
                              GROUP BY  CalcYm,HouseSeq,CostType ) AS ASum  ON A.CalcYm = ASum.CalcYm  
                                                                           AND A.HouseSeq = ASum.HouseSeq  
                                                                           --AND A.CostType = ASum.CostType                       
     WHERE A.CompanySeq = @CompanySeq    
       AND A.CalcYm = RTRIM(LTRIM(@HouseDate))  
       AND (@HouseClass = 0 OR A.HouseClass = @HouseClass)    
    AND C.EmpSeq <> 0 --사원코드가 없는 값은 제외  
    AND H.IsPay = '1' --급여반영된 건만  
     GROUP BY A.CalcYm, A.HouseSeq, F.MinorName, A.HouseClass, B.DongName, B.HoName,   
     D.EmpName, D.EmpId, C.EmpSeq, D.DeptName, D.DeptSeq, A.CfmYn, E.WaterCost, E.GeneralCost,C.EnterDate,C.LeavingDate,  
     D.PuSeq, D.PuName, R.ItemSeq, R.ItemName, R.PbName, R.PbSeq, H.IsPay, H.Seq--,ASum.CostType  
     ORDER BY B.HoName--A.CalcYm, A.HouseSeq    
  
    
RETURN    
  