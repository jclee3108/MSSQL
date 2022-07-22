IF OBJECT_ID('hencom_SSLDeptAddInfoQuery') IS NOT NULL 
    DROP PROC hencom_SSLDeptAddInfoQuery
GO 

-- v2017.05.22 

/************************************************************
  설  명 - 데이터-사업소관리(추가정보)_hencom : 조회
  작성일 - 20151020
  작성자 - 박수영
        - 2016.03.17  kth 매핑용 생산사업소 추가
 ************************************************************/
  CREATE PROC hencom_SSLDeptAddInfoQuery
  @xmlDocument    NVARCHAR(MAX) ,            
  @xmlFlags     INT  = 0,            
  @ServiceSeq     INT  = 0,            
  @WorkingTag     NVARCHAR(10)= '',                  
  @CompanySeq     INT  = 1,            
  @LanguageSeq INT  = 1,            
  @UserSeq     INT  = 0,            
  @PgmSeq         INT  = 0         
     
 AS        
  
     SELECT  M.DeptSeq           AS DeptSeq,
             M.DeptName          AS DeptName,
             A.UmAreaLClass      AS UMAreaLClass,
             A.UMTotalDiv        AS UMTotalDiv,
             A.DispSeq           AS DispSeq,
             A.IsLentCarPrice    AS IsLentCarPrice,
             A.MinRotation       AS MinRotation,
             A.Remark            AS Remark,
             A.LastUserSeq       AS LastUserSeq,
             A.LastDateTime      AS LastDateTime,
             A.OracleKey         AS OracleKey,
             -------------------------------
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UmAreaLClass ) AS UMAreaLClassName,
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMTotalDiv )   AS UMTotalDivName,
              ------------------------------- 2016.03.17  kth 매핑용 생산사업소 추가
             A.ProdDeptSeq       AS ProdDeptSeq,
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.ProdDeptSeq) AS ProdDeptName,
             A.DispQC           AS DispQC,--품질모듈 화면에 조회되는 기본사업소
             A.IsUseReport
      FROM _TDADept AS M
     LEFT OUTER JOIN hencom_TDADeptAdd  AS A WITH (NOLOCK) ON A.CompanySeq = @CompanySeq AND A.DeptSeq = M.DeptSeq
     WHERE  M.CompanySeq = @CompanySeq
 --    ORDER BY A.DispSeq
    
  RETURN
