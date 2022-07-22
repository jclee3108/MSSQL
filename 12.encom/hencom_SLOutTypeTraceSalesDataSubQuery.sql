     
IF OBJECT_ID('hencom_SLOutTypeTraceSalesDataSubQuery') IS NOT NULL       
    DROP PROC hencom_SLOutTypeTraceSalesDataSubQuery      
GO      
      
-- v2017.02.03
      
-- 출하실적수량표-조회Sub by이재천  
CREATE PROC hencom_SLOutTypeTraceSalesDataSubQuery      
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
      
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @DateFr     NCHAR(8), 
            @DateTo     NCHAR(8), 
            @DeptSeq    INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DateFr    = ISNULL( DateFr  , '' ),  
           @DateTo    = ISNULL( DateTo  , '' ),  
           @DeptSeq   = ISNULL( DeptSeq , 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (
            DateFr     NCHAR(8), 
            DateTo     NCHAR(8), 
            DeptSeq    INT
           )    
    
    

    select ReplaceRegSeq, ReplaceRegSerl
      from hencom_TSLCloseSumReplaceMapping 
      where ReplaceRegSeq in ( 
                                SELECT ReplaceRegSeq 
                                  FROM hencom_VInvoiceReplaceItem 
                                 GROUP BY ReplaceRegSeq 
                                 having count(1) = 1 
                              )
     GROUP BY ReplaceRegSeq, ReplaceRegSerl
    having count(1) > 1 


     select * from hencom_TIFProdWorkReportCloseSum where SumMesKey = 217381 
     select * From hencom_VInvoiceReplaceItem where ReplaceRegSeq = 5788 

     select * from hencom_TSLInvoiceReplace where ReplaceRegSeq = 5788 
     select * from hencom_TSLInvoiceReplaceItem where ReplaceRegSeq = 5788 
     select * From hencom_TSLCloseSumReplaceMapping where ReplaceRegSeq = 5788 
     select * from hencom_TSLInvoiceReplaceItem where ReplaceRegSeq = 5788 
     --230219


     select * From _TDADept where DeptSeq = 49 

    SELECT D.DeptName, 
           A.WorkDate, 
           E.CustName, 
           G.PJTName, 
           F.ItemName AS GoodItemName, 
           A.Qty AS AfterQty

      FROM hencom_VInvoiceReplaceItem                   AS A 
      LEFT OUTER JOIN hencom_TSLCloseSumReplaceMapping  AS B ON ( B.CompanySeq = @CompanySeq AND B.ReplaceRegSeq = A.ReplaceRegSeq AND B.ReplaceRegSerl = A.ReplaceRegSerl )
      LEFT OUTER JOIN hencom_TIFProdWorkReportCloseSum  AS C ON ( C.CompanySeq = @CompanySeq AND C.SumMesKey = B.SumMesKey ) 
      LEFT OUTER JOIN _TDADept                          AS D ON ( D.CompanySeq = @CompanySeq AND D.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDACust                          AS E ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = C.CustSeq ) 
      LEFT OUTER JOIN _TDAItem                          AS F ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = C.GoodItemSeq ) 
      LEFT OUTER JOIN _TPJTProject                      AS G ON ( G.CompanySeq = @CompanySeq AND G.PJTSeq = C.PJTSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.DeptSeq = @DeptSeq 
       AND A.WorkDate BETWEEN @DateFr AND @DateTo 
       AND A.IsReplace = '1' 
    

    RETURN     
GO 
exec hencom_SLOutTypeTraceSalesDataSubQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <DeptSeq>44</DeptSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
    <DateFr>20170101</DateFr>
    <DateTo>20170203</DateTo>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037348,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1030584
