IF OBJECT_ID('hencom_SPDMESErpApplyGroupDtlQuery') IS NOT NULL 
    DROP PROC hencom_SPDMESErpApplyGroupDtlQuery
GO 

-- v2017.04.26 

/************************************************************                            
  설  명 - 데이터-출하연동ERP반영_hencom : 조회                            
  작성일 - 20150921                            
  작성자 - 영림원                            
 ************************************************************/                            
                             
 CREATE PROC dbo.hencom_SPDMESErpApplyGroupDtlQuery                                          
  @xmlDocument   NVARCHAR(MAX) ,                                        
  @xmlFlags      INT  = 0,                                        
  @ServiceSeq    INT  = 0,                                        
  @WorkingTag    NVARCHAR(10)= '',                                              
  @CompanySeq    INT  = 1,                                        
  @LanguageSeq   INT  = 1,                                        
  @UserSeq       INT  = 0,                                        
  @PgmSeq        INT  = 0                                     
                                 
 AS                                    
                              
     DECLARE @docHandle          INT,    
             @SumMesKey          NCHAR(30),
             @DateFr             NCHAR(8),
             @DeptSeq            INT        
     
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument                                         
                             
     SELECT  @SumMesKey         = SumMesKey    ,
             @DateFr            = ISNULL(DateFr,''),
             @DeptSeq           = ISNULL(DeptSeq,0)     
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)                            
      WITH (SumMesKey           NCHAR(30),
            DateFr               NCHAR(8),
            DeptSeq              INT)                            
                              
     SELECT  A.MesKey         ,                             
             A.ExpShipSeq     ,                             
             A.WorkDate       ,                             
             A.ProdQty       AS ProdQty      ,                             
             A.OutQty        AS OutQty       ,--표기수량                           
             A.CarNo         AS NewCarNo     ,--신규차량                        
             A.CarCode       AS NewCarCode   ,--신규차량              
             A.Driver        AS NewDriver    ,--신규차량          
             A.GPSDepartTime  ,                             
             A.GPSArriveTime  ,                             
             A.Rotation       ,                            
             A.RealDistance   ,                             
             A.InvCreDateTime ,                             
             --'20160127 24:01:00' 일 경우 Datetime 형변환시 에러발생.
--             CONVERT(DATETIME,A.WorkDate+' '+SUBSTRING(A.InvPrnTime,1,2) +':'+SUBSTRING(A.InvPrnTime,3,2)+':'+SUBSTRING(A.InvPrnTime,5,2))  AS InvPrnTime ,     
             SUBSTRING(A.WorkDate,1,4)+'-'+SUBSTRING(A.WorkDate,5,2)+'-'+SUBSTRING(A.WorkDate,7,2)+' '+SUBSTRING(A.InvPrnTime,1,2) +':'+SUBSTRING(A.InvPrnTime,3,2)+':'+SUBSTRING(A.InvPrnTime,5,2)  AS InvPrnTime ,                       
             A.IsNew          ,                             
             A.WorkOrderSeq   ,                             
             A.WorkReportSeq  ,                             
             A.InvoiceSeq     ,                             
             A.ProdIsErpApply ,                             
             A.ProdResults    ,                             
             A.ProdStatus     ,                             
             A.InvIsErpApply  ,                             
             A.InvResults     ,                             
             A.InvStatus      ,                            
             -----명칭가져올것-------------------------------                            
             (SELECT ItemName FROM _TDAItem WHERE CompanySeq = @CompanySeq AND ItemSeq = A.GoodItemSeq ) AS GoodItemName   ,                             
             (SELECT DeptName FROM _TDADept WHERE CompanySeq = @CompanySeq AND DeptSeq = A.DeptSeq )     AS DeptName       ,                             
             (SELECT PJTName FROM _TPJTProject WHERE CompanySeq = @CompanySeq AND PJTSeq = A.PJTSeq )    AS PJTName        ,                            
               (SELECT CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = A.CustSeq )     AS CustName       ,                            
             A.CustSeq,                         
             A.PJTSeq ,                    
             A.GoodItemSeq ,
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMOutType )  AS UMOutTypeName  ,                              
             A.UMOutType AS UMOutTypeSeq,      
             C.CarCode       AS CarCode , --ERP의 차량정보        
             C.CarNo         AS CarNo , --ERP의 차량정보        
             C.Driver        AS Driver ,  --ERP의 차량정보         
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = C.UMCarClass)  AS UMCarClassName, --ERP의 차량정보                          
             --데이터 체크할 것-----------------                            
             A.SubContrCarSeq AS SubContrCarSeq,                            
             A.DeptSeq,                            
             A.MesNo ,                        
             EXSP.ExpShipNo      AS ExpShipNo, --출하예정번호                      
             EXSP.UMExpShipType  AS UMExpShipType , --출하예정구분                     
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND Minorseq = EXSP.UMExpShipType ) AS UMExpShipTypeName ,                
             (SELECT ToolName FROM V_mstm_PDToolBP WHERE CompanySeq = A.CompanySeq AND DeptSeq = A.DeptSeq AND BPNo = A.BPNo) AS ToolName , --ERP설비정보                
             A.BPNo AS BPNo ,              
             --현장추가정보의 단가정보              
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = EXSP.UMPriceType ) AS UMPriceTypeName , --단가구분              
 --            dbo.hencom_FunGetItemPrice( @CompanySeq ,A.DeptSeq  ,A.PJTSeq ,A.GoodItemSeq ,EXSP.UMPriceType ,A.WorkDate)  AS Price,         
 --            dbo.hencom_FunGetItemPrice( @CompanySeq ,A.DeptSeq  ,A.PJTSeq ,A.GoodItemSeq ,EXSP.UMPriceType ,A.WorkDate) * A.ProdQty AS DomAmt ,        
             --출하에서 신규데이터        
             A.CustName AS NewCustName,        
             (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMCarClass) AS NewCarClass  --신규일 경우 닛소에서 ERP의 차량구분코드로 넘겨받는다.        
            ,EXSP.PriceRate 
     FROM hencom_TIFProdWorkReportClose  AS A WITH (NOLOCK)                                   
     LEFT OUTER JOIN hencom_TSLExpShipment AS EXSP ON EXSP.CompanySeq = @CompanySeq AND EXSP.ExpShipSeq = A.ExpShipSeq          
     LEFT OUTER JOIN hencom_TPUSubContrCar AS C ON C.CompanySeq = @CompanySeq AND C.SubContrCarSeq = A.SubContrCarSeq        
     WHERE  A.CompanySeq = @CompanySeq                   
     AND (ISNULL(@SumMesKey,0) = 0 OR A.SumMesKey = @SumMesKey)     
     AND (@DateFr = '' OR A.WorkDate = @DateFr )
     AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq)                  
            
 RETURN

go 

exec hencom_SPDMESErpApplyGroupDtlQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DateFr>20151202</DateFr>
    <DeptSeq>49</DeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1032173,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027245