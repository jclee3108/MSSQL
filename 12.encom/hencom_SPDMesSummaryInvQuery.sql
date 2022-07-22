IF OBJECT_ID('hencom_SPDMesSummaryInvQuery') IS NOT NULL 
    DROP PROC hencom_SPDMesSummaryInvQuery
GO 

-- v2017.03.15 

/************************************************************  
 설  명 - 데이터-출하MES자료확인_hencom : 송장내역  
 작성일 - 20151111  
 작성자 - 영림원  
************************************************************/  
  
CREATE PROC dbo.hencom_SPDMesSummaryInvQuery                  
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
            @ExpShipSeq     INT    
 EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
  
    SELECT  @ExpShipSeq     = ExpShipSeq        
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock5', @xmlFlags)  
    WITH (ExpShipSeq      INT )  


    -- 분할된 원본은 보이지 않도록 한다.
    SELECT DISTINCT LEFT(A.MesKey,19) AS MesKey
      INTO #PartiontMeskey
      FROM hencom_TIFProdWorkReportClose AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND LEN(A.MesKey) > 19 
    

    SELECT  A.ExpShipSeq ,  
            A.MesKey ,  
            A.BPNo ,  
    --            SUBSTRING(A.WorkDate,1,4) +'-'+ SUBSTRING(A.WorkDate,5,2)+ '-' + SUBSTRING(A.WorkDate,7,2) +' '+A.InvPrnTime AS InvPrnTime , --송장발행시간  
            CONVERT(DATETIME,A.WorkDate+' '+SUBSTRING(A.InvPrnTime,1,2) +':'+SUBSTRING(A.InvPrnTime,3,2)+':'+SUBSTRING(A.InvPrnTime,5,2)) AS InvPrnTime , --송장발행시간  
            A.ProdQty ,  
            A.SubContrCarSeq , --차량내부순번  
            C.CarNo ,  
            C.CarCode ,  
            C.Driver ,  
            C.UMCarClass, --차량구분코드  
            (SELECT MinorName FROM _TDAUminor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMCarClass ) AS UMCarClassName   
    FROM hencom_TIFProdWorkReportClose AS A WITH (NOLOCK)   
    LEFT OUTER JOIN hencom_TPUSubContrCar AS C WITH (NOLOCK) ON C.CompanySeq = A.CompanySeq AND C.SubContrCarSeq = A.SubContrCarSeq  
    WHERE  A.CompanySeq = @CompanySeq  
        AND A.ExpShipSeq = @ExpShipSeq       
        AND NOT EXISTS (SELECT 1 FROM #PartiontMeskey WHERE MesKey = A.MesKey)



RETURN

go 
exec hencom_SPDMesSummaryInvQuery @xmlDocument=N'<ROOT>
  <DataBlock5>
    <WorkingTag />
    <IDX_NO>0</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <ROW_IDX>1</ROW_IDX>
    <ExpShipSeq>467</ExpShipSeq>
    <TABLE_NAME>DataBlock5</TABLE_NAME>
  </DataBlock5>
  
</ROOT>',@xmlFlags=2,@ServiceSeq=1033105,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027437