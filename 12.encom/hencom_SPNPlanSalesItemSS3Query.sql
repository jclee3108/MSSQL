IF OBJECT_ID('hencom_SPNPlanSalesItemSS3Query') IS NOT NULL 
    DROP PROC hencom_SPNPlanSalesItemSS3Query
GO 

-- v2017.05.31 
/************************************************************    
 설  명 - 데이터-사업계획매출계획등록_hencom : 조회시트3    
 작성일 - 20161024    
 작성자 - 박수영    
************************************************************/    
    
CREATE PROC dbo.hencom_SPNPlanSalesItemSS3Query                    
 @xmlDocument    NVARCHAR(MAX) ,                
 @xmlFlags     INT  = 0,                
 @ServiceSeq     INT  = 0,                
 @WorkingTag     NVARCHAR(10)= '',                      
 @CompanySeq     INT  = 1,                
 @LanguageSeq INT  = 1,                
 @UserSeq     INT  = 0,                
 @PgmSeq         INT  = 0             
        
AS            
     
    DECLARE @docHandle      INT,    
            @PlanSeq        INT ,    
            @DeptSeq        INT      
     
 EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                 
    
    SELECT  @PlanSeq       = PlanSeq        ,    
            @DeptSeq       = DeptSeq            
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock3', @xmlFlags)    
    WITH (  PlanSeq        INT ,    
            DeptSeq        INT )    
                
    SELECT  M.ItemSeq,    
            M.PJTRegSeq ,    
            M.CustRegSeq ,    
            A.BPYm ,    
            SUM( CASE WHEN RIGHT(A.BPYm,2) = '01' THEN ISNULL(A.SalesQty,0) ELSE 0 END  ) AS Mth1 ,    
            SUM( CASE WHEN RIGHT(A.BPYm,2) = '02' THEN ISNULL(A.SalesQty,0) ELSE 0 END  ) AS Mth2 ,    
            SUM( CASE WHEN RIGHT(A.BPYm,2) = '03' THEN ISNULL(A.SalesQty,0) ELSE 0 END  ) AS Mth3 ,    
            SUM( CASE WHEN RIGHT(A.BPYm,2) = '04' THEN ISNULL(A.SalesQty,0) ELSE 0 END  ) AS Mth4 ,    
            SUM( CASE WHEN RIGHT(A.BPYm,2) = '05' THEN ISNULL(A.SalesQty,0) ELSE 0 END  ) AS Mth5 ,    
            SUM( CASE WHEN RIGHT(A.BPYm,2) = '06' THEN ISNULL(A.SalesQty,0) ELSE 0 END  ) AS Mth6 ,    
            SUM( CASE WHEN RIGHT(A.BPYm,2) = '07' THEN ISNULL(A.SalesQty,0) ELSE 0 END  ) AS Mth7 ,    
            SUM( CASE WHEN RIGHT(A.BPYm,2) = '08' THEN ISNULL(A.SalesQty,0) ELSE 0 END  ) AS Mth8 ,    
            SUM( CASE WHEN RIGHT(A.BPYm,2) = '09' THEN ISNULL(A.SalesQty,0) ELSE 0 END  ) AS Mth9 ,    
            SUM( CASE WHEN RIGHT(A.BPYm,2) = '10' THEN ISNULL(A.SalesQty,0) ELSE 0 END  ) AS Mth10 ,    
            SUM( CASE WHEN RIGHT(A.BPYm,2) = '11' THEN ISNULL(A.SalesQty,0) ELSE 0 END  ) AS Mth11 ,    
            SUM( CASE WHEN RIGHT(A.BPYm,2) = '12' THEN ISNULL(A.SalesQty,0) ELSE 0 END  ) AS Mth12    
    INTO #TMPData    
    FROM hencom_TPNPSalesPlanD AS A WITH (NOLOCK)    
    JOIN hencom_TPNPSalesPlan AS M ON M.CompanySeq = A.CompanySeq AND M.PSalesRegSeq = A.PSalesRegSeq    
    WHERE  M.CompanySeq = @CompanySeq    
        AND M.PlanSeq = @PlanSeq           
        AND M.DeptSeq = @DeptSeq       
        AND ((@PgmSeq = 1031795 AND ISNULL(M.ItemSeq,0) <> 0) --제품매출계획   
            OR (@PgmSeq <> 1031795 AND ISNULL(M.ItemSeq,0) = 0 ) )  
    GROUP BY M.ItemSeq,M.PJTRegSeq ,M.CustRegSeq ,A.BPYm    
        
    SELECT  M.ItemSeq,    
            M.PJTRegSeq ,    
            M.CustRegSeq ,     
            SUM(ISNULL(M.Mth1,0)) AS Mth1  ,    
            SUM(ISNULL(M.Mth2,0)) AS Mth2  ,    
            SUM(ISNULL(M.Mth3,0)) AS Mth3  ,    
            SUM(ISNULL(M.Mth4,0)) AS Mth4  ,    
            SUM(ISNULL(M.Mth5,0)) AS Mth5  ,    
            SUM(ISNULL(M.Mth6,0)) AS Mth6  ,    
            SUM(ISNULL(M.Mth7,0)) AS Mth7  ,    
            SUM(ISNULL(M.Mth8,0)) AS Mth8  ,    
            SUM(ISNULL(M.Mth9,0)) AS Mth9  ,    
            SUM(ISNULL(M.Mth10,0)) AS Mth10  ,    
            SUM(ISNULL(M.Mth11,0)) AS Mth11 ,    
            SUM(ISNULL(M.Mth12,0)) AS Mth12     
    INTO #TMPDataResutl    
    FROM #TMPData AS M    
    GROUP BY M.ItemSeq,M.PJTRegSeq ,M.CustRegSeq     
        
    SELECT     
            A.ItemSeq ,    
            (SELECT ItemName FROM _TDAItem WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ItemSeq) AS ItemName ,    
            A.PJTRegSeq AS PlanPjtSeq  ,    
            (SELECT PlanPJTName FROM hencom_TPNPJT WITH (NOLOCK) WHERE CompanySeq  = @CompanySeq AND PJTRegSeq = A.PJTRegSeq ) AS PlanPJTName ,    
            A.CustRegSeq    AS PlanCustSeq,
            C.PlanCustName  AS PlanCustName ,    
            (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq =  C.UMChannel ) AS UMChannelName ,  
             C.UMChannel AS UMChannel ,  
            A.Mth1  ,    
            A.Mth2  ,    
            A.Mth3  ,    
            A.Mth4  ,    
            A.Mth5  ,    
            A.Mth6  ,    
            A.Mth7  ,    
            A.Mth8  ,    
            A.Mth9  ,    
            A.Mth10  ,    
            A.Mth11 ,    
            A.Mth12 , 
            ISNULL(A.Mth1,0) + ISNULL(A.Mth2,0) + ISNULL(A.Mth3,0) + ISNULL(A.Mth4,0) + ISNULL(A.Mth5,0) + ISNULL(A.Mth6,0) + 
            ISNULL(A.Mth7,0) + ISNULL(A.Mth8,0) + ISNULL(A.Mth9,0) + ISNULL(A.Mth10,0) + ISNULL(A.Mth11,0) + ISNULL(A.Mth12,0) AS MthTotal
    FROM #TMPDataResutl AS A    
    LEFT OUTER JOIN hencom_TPNCust AS C WITH (NOLOCK) ON C.CompanySeq = @CompanySeq   
                                                    AND C.CustRegSeq = A.CustRegSeq  
    
     
    
RETURN

go 
begin tran 

exec hencom_SPNPlanSalesItemSS3Query @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DeptSeq>28</DeptSeq>
    <PlanSeq>18</PlanSeq>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1039019,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031795
rollback 