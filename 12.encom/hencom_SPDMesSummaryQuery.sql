IF OBJECT_ID('hencom_SPDMesSummaryQuery') IS NOT NULL 
    DROP PROC hencom_SPDMesSummaryQuery
GO 

-- v2017.03.15
/************************************************************          
    설  명 - 데이터-출하MES자료확인_hencom : 조회          
    작성일 - 20151110          
    작성자 - 박수영
    수정: 조회조건의 출하일자를 출하예정일자와 비교했던 것을 출하마감테이블의 출하일자와 비교하는 것으로 변경.
    (출하일자와 출하예정일자가 다른 경우 확인) by박수영 2016.04.07  
   ************************************************************/          
             
CREATE PROC dbo.hencom_SPDMesSummaryQuery
    @xmlDocument   NVARCHAR(MAX) ,                      
    @xmlFlags      INT  = 0,                      
    @ServiceSeq    INT  = 0,                      
    @WorkingTag    NVARCHAR(10)= '',                            
    @CompanySeq    INT  = 1,                      
    @LanguageSeq   INT  = 1,                      
    @UserSeq       INT  = 0,                      
    @PgmSeq        INT  = 0                   
                 
   AS                  
             
       DECLARE @docHandle      INT,          
               @DeptSeq        INT ,          
               @StdDate        NCHAR(8),
               @StdDateTo      NCHAR(8)       
              
       EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                       
             
       SELECT  @DeptSeq = ISNULL(DeptSeq,0)  ,          
               @StdDate = ISNULL(StdDate,'') ,
               @StdDateTo = ISNULL(StdDateTo,'')            
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)          
       WITH (DeptSeq  INT ,          
             StdDate  NCHAR(8),
             StdDateTo NCHAR(8)  )          
     
     --MES출하자료확인 화면에서도 동일한 SP사용하기 때문에 적용함.
     IF ISNULL(@StdDateTo,'') = ''
     BEGIN
         SET @StdDateTo = @StdDate
     END
       CREATE TABLE #TmpTitle                 
       (                     
           ColIDX       INT IDENTITY(0,1)  ,                  
           Title        NVARCHAR(100)   ,            
           TitleSeq     NVARCHAR(100)               
                            
       )                  
       CREATE TABLE #TmpTitle_Tmp                 
       (                        
           Title        NVARCHAR(100)      ,                  
           TitleSeq     NVARCHAR(100)      ,                
           Sort         INT              
       )                  
	            
     --  INSERT #TmpTitle_Tmp(Title,TitleSeq,Sort)              
     --  SELECT D.MatItemName AS Title , D.MatItemName AS TitleSeq,               
     --          (SELECT MAX(MinorSort) FROM _TDAUMinor WHERE  CompanySeq = @CompanySeq           
     --                                                      AND MinorName =  D.MatItemName           
     --                                                      AND MajorSeq = 1011629  ) AS MinorSort          
     --  FROM hencom_TIFProdWorkReportClose AS M  WITH(NOLOCK)         
     --  JOIN hencom_TIFProdMatInputClose AS D WITH(NOLOCK) ON D.companyseq = M.companyseq AND D.meskey = M.meskey
     --WHERE M.WorkDate BETWEEN @StdDate AND @StdDateTo
     --  AND (M.DeptSeq = @DeptSeq or @DeptSeq = 0 )
     --  GROUP BY D.MatItemName
    
    -- 분할된 원본은 보이지 않도록 한다.
    SELECT DISTINCT LEFT(A.MesKey,19) AS MesKey
      INTO #PartiontMeskey
      FROM hencom_TIFProdWorkReportClose AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEN(A.MesKey) > 19 


	 INSERT #TmpTitle_Tmp(Title,TitleSeq,Sort)
	 SELECT D.MatItemName AS Title , D.MatItemName AS TitleSeq,               
               (SELECT MAX(MinorSort) FROM _TDAUMinor WHERE  CompanySeq = @CompanySeq           
                                                           AND MinorName =  D.MatItemName           
                                                           AND MajorSeq = 1011629  ) AS MinorSort
	 FROM   hencom_TIFProdMatInputClose AS D WITH(NOLOCK)
	 WHERE  D.WorkDate BETWEEN @StdDate AND @StdDateTo
	 AND    (D.DeptSeq = @DeptSeq or @DeptSeq = 0 )
     AND NOT EXISTS (SELECT 1 FROM #PartiontMeskey WHERE MesKey = D.MesKey)
     GROUP BY D.MatItemName



     INSERT #TmpTitle(Title,TitleSeq)              
     SELECT Title,TitleSeq             
     FROM #TmpTitle_Tmp              
     ORDER BY Sort ,TitleSeq            
                     
     /*헤더 타이틀 조회*/        
     SELECT * FROM #TmpTitle
                    
     SELECT IDENTITY(int, 0,1) AS RowIDX,          
               A.ExpShipSeq,          
               A.ExpShipNo,          
               A.UMExpShipType,          
               A.CustSeq,          
               A.PJTSeq,         
               A.DepositingArea ,          
               A.ItemSeq    ,
               A.DeptSeq    
   --            A.Qty         
       INTO #TMPRowData           
       FROM hencom_TSLExpShipment AS A WITH(NOLOCK) 
       LEFT OUTER JOIN hencom_TDADeptAdd AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq       
        WHERE (@DeptSeq = 0 OR A.deptseq = @DeptSeq)       
       AND A.ExpShipSeq IN (SELECT ExpShipSeq FROM hencom_TIFProdWorkReportClose     
                           WHERE WorkDate BETWEEN @StdDate AND @StdDateTo  --출하일자기준으로 출하예정데이터 보여줌by2016.04.07박수영  
                           --ExpShipSeq = A.ExpShipSeq 
                           AND (@DeptSeq = 0 OR DeptSeq = @DeptSeq)     
          )      
       ORDER BY D.DispSeq,A.ExpShipSeq
       
       /*고정데이터 조회*/        
       SELECT  A.RowIDX,          
               A.ExpShipSeq    AS ExpShipSeq,          
               A.ExpShipNo     AS ExpShipNo,          
               A.UMExpShipType AS UMExpShipType,          
               (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMExpShipType) AS UMOutTypeName ,        
               A.CustSeq       AS CustSeq,          
                 (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName ,        
               A.PJTSeq        AS PJTSeq,          
               (SELECT PJTName FROM _TPJTProject WHERE CompanySeq =  @CompanySeq AND PJTSeq = A.PJTSeq) AS PJTName ,        
               A.DepositingArea    AS DepositingArea , --타설현장        
               A.ItemSeq           AS ItemSeq,          
               (SELECT ItemName FROM _TDAItem WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ItemSeq) AS ItemName ,        
   --            A.Qty               AS Qty         
               (SELECT SUM(ISNULL(ProdQty,0)) FROM hencom_TIFProdWorkReportClose WHERE ExpShipSeq = A.ExpShipSeq ) AS Qty  ,
               (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq ) AS DeptName,--사업소
               A.DeptSeq       AS DeptSeq --사업소코드
       FROM #TMPRowData AS A   
       ORDER BY A.RowIDX     
       
       SELECT R.RowIDX,T.ColIDX,TMP.Qty AS MatQty          
       FROM (          
           SELECT M.ExpShipSeq,D.MatItemName,SUM(ISNULL(D.Qty,0)) AS Qty          
           FROM hencom_TIFProdWorkReportClose AS M WITH(NOLOCK)          
             JOIN hencom_TIFProdMatInputClose AS D WITH(NOLOCK) ON D.CompanySeq = M.CompanySeq AND D.meskey = M.MesKey          
           WHERE M.CompanySeq = @CompanySeq           
             AND M.WorkDate BETWEEN @StdDate AND @StdDateTo           
           AND (@DeptSeq = 0 OR M.deptseq = @DeptSeq)          
           AND NOT EXISTS (SELECT 1 FROM #PartiontMeskey WHERE MesKey = M.MesKey)
           GROUP BY M.ExpShipSeq,D.MatItemName          
           ) AS TMP          
       JOIN #TMPRowData AS R ON R.ExpShipSeq = TMP.ExpShipSeq          
       JOIN #TmpTitle AS T ON T.TitleSeq = TMP.MatItemName          
       ORDER BY R.RowIDX,T.ColIDX              
	   
RETURN
go
begin tran 
exec hencom_SPDMesSummaryQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DeptSeq>42</DeptSeq>
    <StdDate>20151209</StdDate>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033105,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027437
rollback 