
IF OBJECT_ID('_SGACompHouseCostCalcCreateCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostCalcCreateCHE
GO 

/************************************************************  
 설  명 - 데이터-사택료계산항목: 입력대상생성  
 작성일 - 20110315  
 작성자 - 천경민  
************************************************************/  
CREATE PROC dbo._SGACompHouseCostCalcCreateCHE  
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
            @PreYm         NCHAR(6),  
            @HouseClass    INT  
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
    SELECT @CalcYm     = ISNULL(CalcYm, ''),  
           @HouseClass = ISNULL(HouseClass, 0)  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock3', @xmlFlags)  
      WITH (CalcYm        NCHAR(6),  
            HouseClass    INT)  
  
  
  
    -- 서비스 마스타 등록 생성  
    CREATE TABLE #TGAHouseCostCalcInfo (WorkingTag NCHAR(1), Status INT, CalcYm NCHAR(6), HouseSeq INT, CostType INT)  
  
  
    IF @WorkingTag <> 'C' -- 사택료항목별계산 화면의 입력대상생성  
    BEGIN  
        -- 로그 남기기 위해 데이터 수집  
        INSERT INTO #TGAHouseCostCalcInfo (WorkingTag, Status, CalcYm, HouseSeq)  
        SELECT 'D', 0, @CalcYm, HouseSeq  
          FROM _TGACompHouseMaster  
         WHERE CompanySeq = @CompanySeq  
           AND HouseClass = @HouseClass  
  
  
        -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
        EXEC _SCOMLog  @CompanySeq   ,  
                       @UserSeq      ,    
                       '_TGAHouseCostCalcInfo', -- 원테이블명    
                       '#TGAHouseCostCalcInfo', -- 템프테이블명    
                       'CalcYm,HouseSeq' , -- 키가 여러개일 경우는 , 로 연결한다.  
                       'CompanySeq,CalcYm,HouseSeq,CheckQty,UseQty,WaterCost,GeneralCost,LastDateTime,LastUserSeq,EmpSeq,DeptSeq'  
  
  
        -- 기존 등록된 데이터 삭제  
        DELETE _TGAHouseCostCalcInfo  
          FROM _TGAHouseCostCalcInfo AS A  
               JOIN #TGAHouseCostCalcInfo AS B ON A.CalcYm   = B.CalcYm  
                                                    AND A.HouseSeq = B.HouseSeq  
  
  
  
        SELECT @PreYm = LEFT(CONVERT(NCHAR(8), DATEADD(mm, -1, @CalcYm + '01'), 112), 6)  
  
  
        SELECT @CalcYm AS CalcYm,  
               A.HouseSeq,  
               (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @COmpanySeq AND MinorSeq = A.HouseClass) AS HouseClassName,  
               A.HouseClass,  
               A.DongName,  
               A.HoName,  
               CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.EmpName ELSE NULL END AS EmpName,      
               CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.EmpID   ELSE NULL END AS EmpId,      
               CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN B.EmpSeq  ELSE NULL END AS EmpSeq,                     
               CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.DeptName ELSE NULL  END AS DeptName,      
               CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.DeptSeq ELSE NULL END AS DeptSeq,   
               --C.EmpName,  
               --C.EmpId,  
               --B.EmpSeq,  
               --C.DeptName,  
               --C.DeptSeq,  
               B.TmpUseYn       AS TmpUseYn,    -- 임시사용  
               D.CheckQty       AS PreCheckQty, -- 전월검침량  
               A.PrivateSize    AS PrivateSize  -- 전용면적  
          --INTO #RESULT  
          FROM _TGACompHouseMaster AS A WITH(NOLOCK)  
               LEFT OUTER JOIN _TGACompHouseResident AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                                           AND A.HouseSeq   = B.HouseSeq  
                             AND B.FinalUseYn = '1' --최종으로 걸어놓으면 6월퇴거, 6월 입실 시 데이터 검증 불가능 //2011-11-17 최종대상자로 변경 - 문성호  
               LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq, '') AS C       ON B.EmpSeq     = C.EmpSeq  
               LEFT OUTER JOIN _TGAHouseCostCalcInfo AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq  
                                                                           AND A.HouseSeq   = D.HouseSeq  
                                                                           AND D.CalcYm     = @PreYm  
         WHERE A.CompanySeq = @CompanySeq  
           AND A.HouseClass = @HouseClass  
           AND A.UseType <> 1000600003 -- 공용은 제외(가상의 호실-유형자산을 공용으로 등록하기 위함.)  
           --and (LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm )  
           --and (CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.EmpName ELSE null END) is not null  
         ORDER BY A.HoName  
           
           
         --SELECT @CalcYm AS CalcYm,  
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
         --       TmpUseYn,  
         --       PreCheckQty,  
         --       PrivateSize  
         --  FROM #RESULT  
         -- GROUP BY HouseSeq,DongName,TmpUseYn,PreCheckQty,PrivateSize  
         -- ORDER BY HoName  
    END  
  
    ELSE  -- 사택료등록 화면의 입력대상생성  
    BEGIN  
        -- 로그 남기기 위해 데이터 수집  
        INSERT INTO #TGAHouseCostCalcInfo (WorkingTag, Status, CalcYm, HouseSeq, CostType)  
        SELECT 'D', 0, A.CalcYm, A.HouseSeq, A.CostType  
          FROM _TGAHouseCostChargeItem AS A  
               JOIN _TGACompHouseMaster AS B ON A.CompanySeq = B.CompanySeq  
                                                 AND A.HouseSeq   = B.HouseSeq  
         WHERE A.CompanySeq = @CompanySeq  
           AND A.CalcYm     = @CalcYm  
           AND B.HouseClass = @HouseClass  
  
  
        -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)    
        EXEC _SCOMLog  @CompanySeq   ,  
                       @UserSeq      ,    
                       '_TGAHouseCostChargeItem', -- 원테이블명    
                       '#TGAHouseCostCalcInfo', -- 템프테이블명  
                       'CalcYm,HouseSeq,CostType' , -- 키가 여러개일 경우는 , 로 연결한다.  
                       'CompanySeq,CalcYm,HouseSeq,CostType,HouseClass,CfmYn,ChargeAmt,LastDateTime,LastUserSeq,EmpSeq,DeptSeq'  
  
  
        -- 기존 등록된 데이터 삭제  
        DELETE _TGAHouseCostChargeItem  
          FROM _TGAHouseCostChargeItem AS A  
               JOIN #TGAHouseCostCalcInfo AS B ON A.CalcYm   = B.CalcYm  
                                                    AND A.HouseSeq = B.HouseSeq  
  
  
        -- 가변컬럼 헤더정보  
        SELECT IDENTITY(INT, 0, 1) AS ColIDX,  
               B.MinorName AS Title,  
               A.CostType  AS TitleSeq,  
               'enFloat'   AS CellType  
          INTO #Temp_Title  
          FROM _TGACompHouseCostMaster AS A WITH(NOLOCK)  
               LEFT OUTER JOIN _TDAUMinor AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq  
                                                           AND A.CostType   = B.MinorSeq  
         WHERE A.CompanySeq = @CompanySeq  
           AND A.HouseClass = @HouseClass  
           AND A.CalcType <> 1000599001  -- 적용방식이 별도계산이 아닌 것  
         ORDER BY A.OrderNo  
  
  
        -- 가변컬럼 헤더조회  
        SELECT Title, TitleSeq, CellType  
          FROM #Temp_Title  
         ORDER BY ColIDX  
  
  
        -- 고정컬럼 데이터집계  
        SELECT IDENTITY(INT, 0, 1) AS RoWIDX,  
               @CalcYm AS CalcYm,  
               A.HouseSeq,  
               E.MinorName AS HouseClassName,  
               A.HouseClass,  
                 A.DongName,  
               A.HoName,  
               --CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.EmpName ELSE NULL END AS EmpName,      
               --CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.EmpID   ELSE NULL END AS EmpId,      
               --CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN B.EmpSeq  ELSE NULL END AS EmpSeq,                     
               --CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.DeptName ELSE NULL  END AS DeptName,      
               --CASE WHEN LEFT(B.EnterDate,6) <= @CalcYm AND LEFT(B.LeavingDate,6) >= @CalcYm THEN C.DeptSeq ELSE NULL END AS DeptSeq,   
               F.EmpName,  
               F.EmpId,  
               D.EmpSeq,  
               G.DeptName,  
               D.DeptSeq,  
               D.GeneralCost,  
               D.WaterCost,  
               CASE WHEN ISNULL(B.LeavingDate, '') <> '99991231' THEN '1' ELSE '0' END AS IsEmpty  
          INTO #Temp_FixData  
          FROM _TGAHouseCostCalcInfo AS D WITH(NOLOCK)  
               LEFT OUTER JOIN _TGACompHouseMaster AS A WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq  
                                                                           AND A.HouseSeq   = D.HouseSeq  
               LEFT OUTER JOIN _TGACompHouseResident AS B WITH(NOLOCK) ON D.CompanySeq = B.CompanySeq  
                                                                           AND D.HouseSeq   = B.HouseSeq  
                                                                           AND D.EmpSeq     = B.EmpSeq  
                                                                           AND B.FinalUseYn = '1'  
               --LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq, '') AS C       ON B.EmpSeq     = C.EmpSeq  
               LEFT OUTER JOIN _TDAEmp                    AS F WITH(NOLOCK) ON D.CompanySeq = F.CompanySeq  
                                                                           AND D.EmpSeq     = F.EmpSeq  
               LEFT OUTER JOIN _TDADept                   AS G WITH(NOLOCK) ON D.CompanySeq = G.CompanySeq  
                                                                           AND D.DeptSeq    = G.DeptSeq                 
               LEFT OUTER JOIN _TDAUMinor                 AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq  
                                                                           AND A.HouseClass = E.MinorSeq  
         WHERE A.CompanySeq = @CompanySeq  
           AND A.HouseClass = @HouseClass  
           AND D.CalcYm     = @CalcYm  
           AND A.UseType <> 1000600003 -- 공용은 제외(가상의 호실-유형자산을 공용으로 등록하기 위함.)  
         ORDER BY A.HoName  
          
        -- 고정컬럼 조회  
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
         --       MAX(IsEmpty) AS IsEmpty  
         --  INTO #Temp_FixData  
         --  FROM #Temp_FixData1  
         -- GROUP BY HouseSeq,DongName,GeneralCost,WaterCost  
         -- ORDER BY HoName          
            
        SELECT * FROM #Temp_FixData ORDER BY RowIDX  
  
  
        -- 가변데이터 조회  
        SELECT C.RowIDX         AS RowIDX,    
               A.ColIDX         AS ColIDX,    
               B.CalcType,  
               B.FreeApplyYn,  
               CASE WHEN B.CalcType = 1000599002 AND C.IsEmpty = '0'                         THEN B.PackageAmt -- 공실아니면 일괄금액 적용  
                      WHEN B.CalcType = 1000599002 AND C.IsEmpty = '1'  AND B.FreeApplyYn = '1' THEN B.PackageAmt -- 공실이면서 공실적용 체크되어 있으면 일괄금액 적용  
                    ELSE 0 END AS ChargeAmt  
          FROM #Temp_Title AS A  
               JOIN _TGACompHouseCostMaster AS B ON B.CompanySeq = @CompanySeq  
                                                     AND A.TitleSeq   = B.CostType  
               JOIN #Temp_FixData                AS C ON B.HouseClass = C.HouseClass  
                                        
    END  
RETURN  
--GO  
--exec _SGACompHouseCostCalcCreate @xmlDocument=N'<ROOT>  
--  <DataBlock3>  
--    <WorkingTag>A</WorkingTag>  
--    <IDX_NO>1</IDX_NO>  
--    <Status>0</Status>  
--    <DataSeq>1</DataSeq>  
--    <Selected>1</Selected>  
--    <TABLE_NAME>DataBlock3</TABLE_NAME>  
--    <IsChangedMst>0</IsChangedMst>  
--    <HouseClass>1000598001</HouseClass>  
--    <CalcYm>201112</CalcYm>  
--  </DataBlock3>  
  --</ROOT>',@xmlFlags=2,@ServiceSeq=1005473,@WorkingTag=N'C',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1004990