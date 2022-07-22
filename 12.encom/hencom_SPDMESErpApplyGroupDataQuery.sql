IF OBJECT_ID('hencom_SPDMESErpApplyGroupDataQuery') IS NOT NULL 
    DROP PROC hencom_SPDMESErpApplyGroupDataQuery
GO 

-- v2017.04.26
/************************************************************          
  설  명 - 데이터-출하연동ERP반영_hencom : 합계마감데이터조회          
  작성일 - 20151103          
  작성자 - 박수영          
  수정: 대체여부 필드추가 by박수영 2016.07.01  
 ************************************************************/          
           
 CREATE PROC dbo.hencom_SPDMESErpApplyGroupDataQuery                          
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
             @DateFr         NCHAR(8) ,          
             @DeptSeq        INT            
            
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                       
           
     SELECT  @DateFr         = DateFr ,          
             @DeptSeq        = DeptSeq                      
     FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)          
     WITH (DateFr             NCHAR(8) ,          
           DeptSeq            INT )          
    CREATE TABLE #TMP_BalAmt
    (
        CustSeq     INT,
        DeptSeq     INT,
        BalAmt      DECIMAL(19,5)
    )
INSERT #TMP_BalAmt(CustSeq,DeptSeq,BalAmt)
EXEC hencom_SSLCreditLimitSubQuery @CompanySeq,@DateFr,@DeptSeq,0
--select deptseq,custseq from #TMP_BalAmt
--group by deptseq,custseq
--having count(1) >1
--SELECT * FROM #TMP_BalAmt WHERE DeptSeq = 49 AND Custseq =2275
--
--return
     SELECT  A.SumMesKey AS SumMesKey ,          
             A.GoodItemSeq ,          
             A.CustSeq ,          
             A.PJTSeq ,          
             A.DeptSeq ,          
             A.UMOutType     AS UMOutTypeSeq,          
             A.ExpShipSeq ,          
             A.WorkDate ,          
             A.ProdQty       AS ProdQty ,          
             A.OutQty        AS OutQty ,          
             A.CurAmt        AS CurAmt ,          
             A.CurVAT        AS CurVAT ,          
             A.Price         AS Price ,          
             A.WorkOrderSeq ,          
             A.WorkReportSeq ,          
             A.InvoiceSeq ,          
             A.ProdIsErpApply ,          
             A.ProdResults ,          
             A.ProdStatus ,          
             A.InvIsErpApply ,          
             A.InvResults ,          
             A.InvStatus ,          
             A.Remark ,          
             A.LastUserSeq ,          
             A.LastDateTime     ,          
             -----명칭가져올것-------------------------------                            
             (SELECT ItemName FROM _TDAItem WHERE CompanySeq = @CompanySeq AND ItemSeq = A.GoodItemSeq )     AS GoodItemName   ,                             
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq )         AS DeptName       ,                             
             (SELECT PJTName FROM _TPJTProject WHERE CompanySeq = @CompanySeq AND PJTSeq = A.PJTSeq )       AS PJTName        ,                            
             (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq )        AS CustName       ,          
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMOutType )  AS UMOutTypeName  ,            
             --출하예정정보           
             EXSP.ExpShipNo      AS ExpShipNo, --출하예정번호                      
             EXSP.UMExpShipType  AS UMExpShipType ,  
            exsp.ItemSeq as ExpItemSeq,                      
            (select itemname from _TDAItem where companyseq = @CompanySeq and itemseq = exsp.ItemSeq ) as ExpItemName,  
            (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND Minorseq = EXSP.UMExpShipType ) AS UMExpShipTypeName ,             
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = EXSP.UMPriceType ) AS UMPriceTypeName , --단가구분         
             A.BPNo AS BPNo , --호기정보        
                --현장추가정보의 단가정보            
   --            (SELECT MAX(Price) FROM hencom_VPJTAddInfoDate WHERE CompanySeq = @CompanySeq  AND DeptSeq = A.DeptSeq AND PJTSeq = A.PJTSeq AND ItemSeq = A.GoodItemSeq AND UMPriceType = EXSP.UMPriceType AND A.WorkDate BETWEEN StartDate AND EndDate) AS Price,              
   --            (SELECT MAX(Price) FROM hencom_VPJTAddInfoDate WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq AND PJTSeq = A.PJTSeq AND ItemSeq = A.GoodItemSeq AND UMPriceType = EXSP.UMPriceType AND A.WorkDate BETWEEN StartDate AND EndDate) * A.ProdQty AS DomAmt               
             A.IsInclusedVAT     AS IsInclusedVAT ,    
             A.VATRate           AS VATRate ,    
             A.ItemPrice         AS ItemPrice ,    
             A.CustPrice         AS CustPrice ,  
             ISNULL(A.CurAmt,0) + ISNULL(A.CurVAT,0)  AS TotAmt , --합계금액  
             A.CfmCode           AS CfmCode,  
            (SELECT MAX(1) FROM hencom_TSLCloseSumReplaceMapping WHERE CompanySeq = @CompanySeq AND SumMesKey = A.SumMesKey) AS IsReplaceReg, --대체여부
            (SELECT BalAmt FROM #TMP_BalAmt WHERE DeptSeq = A.DeptSeq AND CustSeq = A.CustSeq) AS BalAmt --여신잔액  
           ,EXSP.PriceRate
       FROM hencom_TIFProdWorkReportCloseSum  AS A WITH (NOLOCK)           
         LEFT OUTER JOIN hencom_TSLExpShipment AS EXSP ON EXSP.CompanySeq = @CompanySeq AND EXSP.ExpShipSeq = A.ExpShipSeq          
     WHERE  A.CompanySeq = @CompanySeq          
         AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq )            
         AND A.WorkDate  = @DateFr              
     ORDER BY A.ExpShipSeq              
           
 RETURN
