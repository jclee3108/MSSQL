IF OBJECT_ID('hencom_SPDMesMatItemMapTimeSlotQuery') IS NOT NULL 
    DROP PROC hencom_SPDMesMatItemMapTimeSlotQuery
GO 

-- v2017.03.13 
-- 송장분할 원본, 신규추가 된 내역은 제외 
/************************************************************  
  설  명 - 데이터-시간대별투입자재변경_hencom : 조회  
  작성일 - 20160317  
  작성자 - 박수영  
 ************************************************************/  
   
 CREATE PROC dbo.hencom_SPDMesMatItemMapTimeSlotQuery                  
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
            @BPNo           NVARCHAR(50) ,  
            @WorkDate       NCHAR(8) ,  
            @DeptSeq        INT    
    
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
   
     SELECT  @BPNo     = ISNULL(BPNo,'')      ,  
             @WorkDate = WorkDate  ,  
             @DeptSeq  = DeptSeq     
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
     WITH (  BPNo      NVARCHAR(50) ,  
             WorkDate  NCHAR(8) ,  
             DeptSeq   INT )  
    
           
     CREATE TABLE #TmpTitle_Tmp           
     (                  
         ColIDX       INT IDENTITY(0,1)  ,  
         Title        NVARCHAR(100)      ,            
         TitleSeq     INT                ,          
         Sort         INT        
     )               
             
     INSERT #TmpTitle_Tmp(Title,TitleSeq,Sort)        
     SELECT  A.MinorName   AS Title    ,         
             A.MinorSeq    AS TitleSeq,      
             A.MinorSort      
      FROM _TDAUMinor AS A WITH (NOLOCK)       
      LEFT OUTER JOIN _TDAUMinorValue AS B ON B.companyseq = A.CompanySeq       
                                         AND B.MajorSeq = A.MajorSeq  
                                         AND B.MinorSeq = A.MinorSeq       
                                         AND B.Serl = 1000001        
     WHERE  A.CompanySeq = @CompanySeq        
     AND A.MajorSeq = 1011629      
     AND ISNULL(B.ValueText,'') <> '1' --자재투입제외 체크된 건 제외   
 --    AND A.MinorName NOT IN ('W1','W2','W3')  
     ORDER BY A.MinorSort ,A.MinorSeq  
   
     CREATE TABLE #TmpTitleColumn        
     (        
          TitleSeq2     INT,        
          Title2    NVARCHAR(100)        
      )        
         
     INSERT #TmpTitleColumn        
     SELECT 1, '자재'         
     INSERT #TmpTitleColumn        
     SELECT 2, '수량'         
     INSERT #TmpTitleColumn        
     SELECT 3, '자재코드'    
       
   
     CREATE TABLE #TmpTitleRst                    
     (                         
         ColIDX       INT IDENTITY(0,1)  ,                      
         Title        NVARCHAR(100)   ,                
         TitleSeq     NVARCHAR(100)     ,         
         Title2        NVARCHAR(100)   ,                
         TitleSeq2     NVARCHAR(100)            
                              
     )     
     INSERT #TmpTitleRst(Title,TitleSeq,Title2,TitleSeq2)   
     SELECT A.Title,A.TitleSeq,B.Title2,B.TitleSeq2  
     FROM #TmpTitle_Tmp AS A  
     JOIN #TmpTitleColumn AS B ON 1=1  
     ORDER BY A.Sort ,A.TitleSeq ,B.TitleSeq2      
 --      select * from #TmpTitle_Tmp  
       
     SELECT * FROM #TmpTitleRst       
    
     --사업소별자재기준정보  
     SELECT  A.DeptSeq       ,       
             T.BPNo      ,    
             A.ToolSeq       ,       
 --            A.MatItemMstSeq ,        
 --            T.ToolName AS ToolName   ,  
             A.StartDate     ,    
             A.EndDate,  
             D.UMMatType ,  
             D.ItemSeq         
     INTO #TMPStdMatData  
     FROM hencom_VSLStdMatInputData  AS A   
     LEFT OUTER JOIN hencom_TPDDeptInputMatItemDet AS D ON D.CompanySeq = A.CompanySeq AND D.MatItemMstSeq = A.MatItemMstSeq  
LEFT OUTER JOIN V_mstm_PDToolBP AS T ON T.CompanySeq = A.CompanySeq AND T.ToolSeq = A.ToolSeq        
WHERE A.CompanySeq = @CompanySeq        
     AND @DeptSeq = A.DeptSeq  
     AND (@BPNo = '' OR @BPNo = T.BPNo)  
     AND  @WorkDate BETWEEN StartDate AND EndDate   
   
 --select * from #TMPStdMatData  
   
    
    -- 분할된 원본, 신규추가는 보이지 않도록 한다.
    SELECT DISTINCT LEFT(A.MesKey,19) AS MesKey
      INTO #PartiontMeskey
      FROM hencom_TIFProdWorkReportClose AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND ( LEN(A.MesKey) > 19 OR LEFT(A.MesKey,3) = 'NEW' )


     SELECT  IDENTITY(INT, 0,1) AS RowIDX,  
               MesKey,  
             WorkDate ,  
             DeptSeq ,  
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq) AS DeptName   ,     
             (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS CustName   ,   
             (SELECT BizNo FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq) AS BizNo   ,   
             PJTSeq,  
             (SELECT PJTName FROM _TPJTProject WHERE CompanySeq = @CompanySeq AND PJTSeq = A.PJTSeq) AS PJTName   ,     
             SUBSTRING(A.WorkDate,1,4)+'-'+SUBSTRING(A.WorkDate,5,2)+'-'+SUBSTRING(A.WorkDate,7,2) +' '+SUBSTRING(A.InvPrnTime,1,2) +':'+SUBSTRING(A.InvPrnTime,3,2)+':'+SUBSTRING(A.InvPrnTime,5,2) AS InvPrnTime , --송장발행시간   
             BPNo  ,
             (SELECT ItemName FROM _TDAItem WHERE CompanySeq = @CompanySeq AND ItemSeq = A.GoodItemSeq) AS GoodItemName,
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMOutType) AS UMOutTypeName,
             A.ProdQty AS ProdQty
     INTO #TMPFixData  
     FROM hencom_TIFProdWorkReportClose AS A  
     WHERE A.CompanySeq = @CompanySeq   
     AND @WorkDate = A.WorkDate   
     AND @DeptSeq = A.DeptSeq  
     AND (@BPNo = '' OR @BPNo = A.BPNo ) 
     AND NOT EXISTS (SELECT 1 FROM #PartiontMeskey WHERE MesKey = A.MesKey) -- 추가 2017.03.13
     AND EXISTS (SELECT 1 FROM hencom_TIFProdMatInputClose  
                         WHERE CompanySeq = @CompanySeq AND MesKey = A.MesKey)--자재가 있는 것만.
     ORDER BY A.BPNo,SUBSTRING(A.WorkDate,1,4)+'-'+SUBSTRING(A.WorkDate,5,2)+'-'+SUBSTRING(A.WorkDate,7,2) +' '+SUBSTRING(A.InvPrnTime,1,2) +':'+SUBSTRING(A.InvPrnTime,3,2)+':'+SUBSTRING(A.InvPrnTime,5,2)  
   
 --고정데이터  
     SELECT * FROM #TMPFixData  
       
     --동일한 자재가 있는 경우 때문에 합산  
     --주의사항: MatItemSeq 가 그룹바이에 추가되어 있어서 예를 들어 C1에 해당하는 MatItemSeq를 연결했는데 출하시스템에서 동일한 MesKey에 자재를 추가로 받을 경우(MatItemSeq = null)
     SELECT CompanySeq,MesKey,MatItemSeq,MatItemName,SUM(ISNULL(Qty,0)) AS Qty  
     INTO #TMPMatResult  
     FROM hencom_TIFProdMatInputClose  
     WHERE CompanySeq = @CompanySeq   
     AND MesKey IN (SELECT MesKey FROM #TMPFixData)  
     GROUP BY CompanySeq,MesKey,MatItemName ,MatItemSeq
       
       
 --    select * from #TMPMatResult  
 --다이나믹데이터  
     SELECT  F.RowIDX ,  
             T.ColIDX , 
             K.ItemName  AS MatItemName,  
             B.Qty AS Qty,  
             B.MatItemSeq  AS MatItemSeq  
 --            ,B.MatItemName  
 --            ,B.MatItemSeq  
   
     FROM #TMPFixData AS F  
     JOIN #TMPMatResult AS B ON B.CompanySeq = @CompanySeq AND B.MesKey = F.MesKey  
     JOIN #TmpTitle_Tmp AS T ON T.Title = B.MatItemName  
     LEFT OUTER JOIN #TMPStdMatData AS SD ON SD.UMMatType = T.TitleSeq    
     LEFT OUTER JOIN _TDAItem AS I ON I.CompanySeq = @CompanySeq AND I.ItemSeq = SD.ItemSeq  
     LEFT OUTER JOIN _TDAItem AS K ON K.CompanySeq = @CompanySeq AND K.ItemSeq = B.MatItemSeq  
 --    WHERE ISNULL(B.Qty,0) <> 0 --투입될 수량이 0인 건은 제외.  
     ORDER BY F.RowIDX, T.ColIDX  
   
   

 RETURN
 go
 exec hencom_SPDMesMatItemMapTimeSlotQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DeptSeq>42</DeptSeq>
    <WorkDate>20151209</WorkDate>
    <BPNo>1</BPNo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1035837,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1029521
