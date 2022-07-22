IF OBJECT_ID('hencom_SSLTaxSalesRelationListDetQuery') IS NOT NULL 
    DROP PROC hencom_SSLTaxSalesRelationListDetQuery
GO 

-- v2017.04.25 
/************************************************************    
  설  명 - 데이터-계산서청구내역조회_hencom : 세부조회    
  작성일 - 20160415    
  작성자 - 영림원    
  수정 : 2016.07.05by박수영  
 ************************************************************/    
  CREATE PROC dbo.hencom_SSLTaxSalesRelationListDetQuery                    
  @xmlDocument    NVARCHAR(MAX) ,                
  @xmlFlags     INT  = 0,                
  @ServiceSeq     INT  = 0,                
  @WorkingTag     NVARCHAR(10)= '',                      
  @CompanySeq     INT  = 1,                
  @LanguageSeq INT  = 1,                
  @UserSeq     INT  = 0,                
  @PgmSeq         INT  = 0             
         
 AS            
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @docHandle      INT,    
            @BillSeq         INT      
  
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                 
   SELECT  @BillSeq         = BillSeq              
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
    WITH (BillSeq          INT )    
      
  /*    
    SELECT  a.DeptSeq         ,     
            a.DeptName        ,     
            a.CustSeq         ,     
            a.CustName        ,     
            a.IsReplace       ,     
            a.workdate as InvoiceDate     ,     
            a.PJTSeq          ,     
            a.PJTName         ,     
            i.AssetSeq        ,     
            (select AssetName from _TDAItemAsset where companyseq = a.CompanySeq and assetseq = i.AssetSeq) as  AssetName       ,     
            a.ItemSeq         ,     
            i.ItemName        ,     
            i.ItemNo          ,     
            a.qty as SalesQty        ,     
            a.price as SalesPrice      ,    
            a.CurAmt  as SalesAmt        ,     
            a.CurVAT as SalesVat        ,     
            a.TotAmt as TotSalesAmt         
    FROM  hencom_VInvoiceReplaceItem AS A WITH (NOLOCK)     
    left outer join _tdaitem as i on i.CompanySeq = a.CompanySeq     
                                and i.itemseq =  a.ItemSeq        
    WHERE  A.CompanySeq = @CompanySeq    
    AND A.BillSeq          = @BillSeq             
    order by a.workdate, a.PJTName    
*/    
    SELECT  a.DeptSeq         ,     
            (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq ) AS DeptName ,    
            a.CustSeq         ,     
            (SELECT CustName FROM _TDACust  WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq ) AS CustName ,    
            a.workdate as InvoiceDate     ,     
            a.PJTSeq          ,     
            (SELECT PJTName FROM _TPJTProject  WHERE CompanySeq = @CompanySeq AND PJTSeq = A.PJTSeq ) AS PJTName ,    
--            a.ItemSeq         ,     
            I.ItemName ,  
--            (SELECT ItemName FROM _TDAItem WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ItemSeq ) AS ItemName,    
--            (SELECT ItemNo FROM _TDAItem WHERE CompanySeq = @CompanySeq AND ItemSeq = A.ItemSeq ) AS ItemNo,    
            ISNULL(a.price,0)        as SalesPrice      ,    
            SUM(ISNULL(a.qty,0))     as SalesQty        ,     
            SUM(ISNULL(a.CurAmt,0))  as SalesAmt        ,     
            SUM(ISNULL(a.CurVAT,0))  as SalesVat        ,     
            SUM(ISNULL(a.TotAmt,0))  as TotSalesAmt         , 
            A.AttachDate
    INTO #TMPResutl    
    FROM  hencom_VInvoiceReplaceItem AS A 
    LEFT OUTER JOIN _TDAItem AS I ON I.CompanySeq = A.CompanySeq     
                                AND I.itemseq =  A.ItemSeq        
    WHERE  A.CompanySeq = @CompanySeq    
    AND A.BillSeq          = @BillSeq       
    GROUP BY a.DeptSeq ,a.CustSeq,a.workdate,a.PJTSeq,I.ItemName,ISNULL(a.price,0), A.AttachDate
--    order by a.workdate, a.PJTName    
    
    SELECT * FROM #TMPResutl    
    order by InvoiceDate, PJTName 
    RETURN
   