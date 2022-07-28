
IF OBJECT_ID('_SGACompHouseCostCalcQueryCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostCalcQueryCHE
GO 

/************************************************************  
 설  명 - 데이터-사택료계산항목: 조회  
 작성일 - 20110315  
 작성자 - 천경민  
************************************************************/  
CREATE PROC _SGACompHouseCostCalcQueryCHE 
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
  
  
    
    SELECT A.CalcYm,    
           A.HouseSeq,    
           (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @COmpanySeq AND MinorSeq = B.HouseClass) AS HouseClassName,    
           B.HouseClass,    
           B.DongName,    
           B.HoName,    
               --CASE WHEN LEFT(C.EnterDate,6) <= @CalcYm AND LEFT(C.LeavingDate,6) >= @CalcYm THEN D.EmpName ELSE NULL END AS EmpName,      
               --CASE WHEN LEFT(C.EnterDate,6) <= @CalcYm AND LEFT(C.LeavingDate,6) >= @CalcYm THEN D.EmpID   ELSE NULL END AS EmpId,      
               --CASE WHEN LEFT(C.EnterDate,6) <= @CalcYm AND LEFT(C.LeavingDate,6) >= @CalcYm THEN C.EmpSeq  ELSE NULL END AS EmpSeq,                     
               --CASE WHEN LEFT(C.EnterDate,6) <= @CalcYm AND LEFT(C.LeavingDate,6) >= @CalcYm THEN D.DeptName ELSE NULL  END AS DeptName,      
               --CASE WHEN LEFT(C.EnterDate,6) <= @CalcYm AND LEFT(C.LeavingDate,6) >= @CalcYm THEN D.DeptSeq ELSE NULL END AS DeptSeq,    
           F.EmpName,    
           F.EmpId,    
           A.EmpSeq,    
           G.DeptName,    
           A.DeptSeq,    
           C.TmpUseYn       AS TmpUseYn,    -- 임시사용  
           E.CheckQty       AS PreCheckQty, -- 전월검침량    
           A.CheckQty       AS CheckQty,    -- 당월검침량    
           A.UseQty         AS UseQty,      -- 당월사용량    
           A.WaterCost      AS WaterCost,   -- 당월금액(상하수도료)    
           B.PrivateSize    AS PrivateSize, -- 전용면적    
           A.GeneralCost    AS GeneralCost  -- 당월금액(일반관리비)    
      --INTO #RESULT  
      FROM _TGAHouseCostCalcInfo AS A WITH(NOLOCK)    
           LEFT OUTER JOIN _TGACompHouseMaster   AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq    
                                                                       AND A.HouseSeq   = B.HouseSeq    
           LEFT OUTER JOIN _TGACompHouseResident AS C WITH(NOLOCK) ON B.CompanySeq = C.CompanySeq    
                                                                       AND B.HouseSeq   = C.HouseSeq    
                                                                       AND A.EmpSeq     = C.EmpSeq  
                                                                       AND C.FinalUseYn = '1'  
           --LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq, '') AS D       ON C.EmpSeq     = D.EmpSeq    
             LEFT OUTER JOIN _TDAEmp                    AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq  
                                                                       AND A.EmpSeq     = F.EmpSeq  
           LEFT OUTER JOIN _TDADept                   AS G WITH(NOLOCK) ON A.CompanySeq = G.CompanySeq  
                                                                       AND A.DeptSeq    = G.DeptSeq  
           LEFT OUTER JOIN _TGAHouseCostCalcInfo AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq    
                                                                       AND A.HouseSeq   = E.HouseSeq    
                                                                       AND E.CalcYm     = LEFT(CONVERT(NCHAR(8), DATEADD(mm, -1, A.CalcYm + '01'), 112), 6)    
     WHERE A.CompanySeq = @CompanySeq    
       AND A.CalcYm >= @CalcYm     
       AND A.CalcYm <= @CalcYmTo    
       AND (@HouseClass = 0 OR B.HouseClass = @HouseClass)    
       AND (@HouseSeq   = 0 OR A.HouseSeq   = @HouseSeq)    
       AND (@DongSerl   = 0 OR B.DongSerl   = @DongSerl)    
       AND (@EmpSeq     = 0 OR A.EmpSeq     = @EmpSeq)    
       AND (@DeptSeq    = 0 OR A.DeptSeq    = @DeptSeq)    
     ORDER BY A.CalcYm, B.HoName    
           
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
         --       MAX(CheckQty)   AS CheckQty,  
         --       MAX(UseQty)     AS UseQty,  
         --       MAX(WaterCost)  AS WaterCost,  
         --       PrivateSize,  
         --       MAX(GeneralCost)AS GeneralCost  
         --  FROM #RESULT  
         -- GROUP BY HouseSeq,DongName,TmpUseYn,PreCheckQty,PrivateSize  
         -- ORDER BY HoName       
  
RETURN  