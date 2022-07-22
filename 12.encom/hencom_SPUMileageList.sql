IF OBJECT_ID('hencom_SPUMileageList') IS NOT NULL 
    DROP PROC hencom_SPUMileageList
GO 

-- v2017.02.21 

-- Total행 추가 
/************************************************************    
 설  명 - 연비현황조회_hencom    
 작성일 - 2015.12.16    
 작성자 - kth    
 수정자 -by박수영2016.05.30 연비기준 수정.  
************************************************************/    
CREATE PROCEDURE [dbo].[hencom_SPUMileageList]    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
    
AS           
    
    DECLARE @docHandle      INT    
            ,@WorkDateFr    NCHAR(8)    
            ,@WorkDateTo    NCHAR(8)    
            ,@DeptSeq       INT     
            ,@UMCarClass    INT    
            ,@SubContrCarSeq    INT    
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
    
    SELECT   @WorkDateFr          =   ISNULL(WorkDateFr,''   )    
            ,@WorkDateTo          =   ISNULL(WorkDateTo,''   )    
            ,@DeptSeq             =   ISNULL(DeptSeq     ,0)     
            ,@UMCarClass          =   ISNULL(UMCarClass     ,0)     
            ,@SubContrCarSeq      =   ISNULL(SubContrCarSeq     ,0)     
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
      WITH  (WorkDateFr     NCHAR(8)    
            ,WorkDateTo     NCHAR(8)    
            ,DeptSeq        INT    
            ,UMCarClass     INT    
            ,SubContrCarSeq INT)    
    
-- 사업소  차량구분 차량번호 회전수 운행거리(km) 편도거리(km)  주유량(ℓ) 연비기준(ℓ/km) 실적(ℓ/km) 증감(ℓ/km)       
    
    SELECT   A.DeptSeq     
            ,B.DeptName    
            ,A.UMCarClass    
            ,D.MinorName AS UMCarClassName    
            ,A.SubContrCarSeq    
            ,C.CarNo AS CarNo    
--            ,MAX(C.StdMileage) AS StdMileage      -- 연비기준    
            ,MAX(SM.StdMileage) AS StdMileage      -- 연비기준  수정2016.05.31by박수영
            ,MAX(E.OutQty) AS OutQty                        -- 주유량    
            ,SUM(A.Rotation) AS Rotation                    -- 회전수    
            ,SUM(A.RealDistance) AS RealDistance            -- 운행거리    
            ,(SUM(A.RealDistance) / 2) AS OneWayDistance    -- 편도거리    
                       
        
      INTO #TPUSubContrCalc    
      FROM hencom_TPUSubContrCalc AS A WITH (NOLOCK)     
      LEFT OUTER JOIN _TDADept AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq     
                                                AND B.DeptSeq = A.DeptSeq    
      LEFT OUTER JOIN _TDAUMinor AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq     
                                                  AND D.MinorSeq = A.UMCarClass    
      left outer join  hencom_VPUContrCarInfo as c on c.CompanySeq = a.CompanySeq    
                                                  and c.SubContrCarSeq = a.SubContrCarSeq    
                                   and a.workdate between c.StartDate and c.EndDate    
    
      LEFT OUTER JOIN (SELECT CompanySeq, DeptSeq, SubContrCarSeq, SUM(OutQty) AS OutQty     
                         FROM hencom_TPUFuelOut     
                        WHERE OutDate BETWEEN @WorkDateFr AND @WorkDateTo    
                        GROUP BY CompanySeq, DeptSeq, SubContrCarSeq) AS E ON E.CompanySeq = A.CompanySeq    
                                                                          AND E.DeptSeq = A.DeptSeq     
                                                                          AND E.SubContrCarSeq = A.SubContrCarSeq    
        LEFT OUTER JOIN hencom_VPUMileageCarClass AS SM WITH(NOLOCK) ON SM.CompanySeq = @CompanySeq   
                                                                    AND SM.DeptSeq = A.DeptSeq   
                                                                    AND SM.UMCarClass = A.UMCarClass   
                                                                    AND A.WorkDate BETWEEN SM.StartDate AND SM.EndDate  
     WHERE A.CompanySeq   = @CompanySeq    
       AND (A.WorkDate BETWEEN @WorkDateFr AND @WorkDateTo)    
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)     
       AND (@UMCarClass = 0 OR A.UMCarClass = @UMCarClass)     
       AND (@SubContrCarSeq = 0 OR A.SubContrCarSeq = @SubContrCarSeq)     
         
     GROUP BY A.DeptSeq, B.DeptName, A.UMCarClass, D.MinorName, A.SubContrCarSeq, C.CarNo     
    
    

    -- 합계
    SELECT 0 AS DeptSeq    
          ,'TOTAL' AS DeptName    
          ,0 AS UMCarClass    
          ,'' AS UMCarClassName    
          ,0 AS SubContrCarSeq    
          ,'' AS CarNo    
          ,SUM(StdMileage) AS StdMileage
          ,SUM(Rotation) AS Rotation
          ,SUM(RealDistance) AS RealDistance
          ,SUM(OneWayDistance) AS OneWayDistance
          ,SUM(OutQty) AS OutQty
          ,CASE WHEN SUM(ISNULL(RealDistance,0)) = 0 THEN 0    
                ELSE SUM(ISNULL(OutQty,0)) / SUM(ISNULL(RealDistance,0)) END AS ResultMileage      -- 실적(ℓ/km)
          ,CASE WHEN SUM(ISNULL(RealDistance,0)) = 0 THEN 0 - SUM(ISNULL(StdMileage,0))    
                ELSE (SUM(ISNULL(OutQty,0)) / SUM(ISNULL(RealDistance,0))) - SUM(ISNULL(StdMileage,0)) END AS ChangeMileage       -- 증감(ℓ/km)     
          ,1 AS Sort
      FROM #TPUSubContrCalc
    
    UNION ALL 
    -- Result 
    SELECT  DeptSeq    
           ,DeptName    
           ,UMCarClass    
           ,UMCarClassName    
           ,SubContrCarSeq    
           ,CarNo    
           ,StdMileage    
           ,Rotation    
           ,RealDistance    
           ,OneWayDistance    
           ,OutQty    
           ,CASE WHEN ISNULL(RealDistance,0) = 0 THEN 0    
                 ELSE ISNULL(OutQty,0) / ISNULL(RealDistance,0) END AS ResultMileage      -- 실적(ℓ/km)
           ,CASE WHEN ISNULL(RealDistance,0) = 0 THEN 0 - ISNULL(StdMileage,0)    
                 ELSE (ISNULL(OutQty,0) / ISNULL(RealDistance,0)) - ISNULL(StdMileage,0) END AS ChangeMileage       -- 증감(ℓ/km)     
           ,2 AS Sort
      FROM #TPUSubContrCalc AS A    
     ORDER BY Sort
    


RETURN      
/***************************************************************************************************************/    
    
go
begin tran 
exec hencom_SPUMileageList @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <WorkDateFr>20150101</WorkDateFr>
    <DeptSeq>41</DeptSeq>
    <SubContrCarSeq />
    <WorkDateTo>20170221</WorkDateTo>
    <UMCarClass />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033845,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1028023
rollback 