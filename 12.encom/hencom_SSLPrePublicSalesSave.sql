IF OBJECT_ID('hencom_SSLPrePublicSalesSave') IS NOT NULL 
    DROP PROC hencom_SSLPrePublicSalesSave
GO 

/************************************************************
 설  명 - 데이터-관급배정물량등록_hencom : 저장
 작성일 - 20160307
 작성자 - 영림원
************************************************************/
CREATE PROC dbo.hencom_SSLPrePublicSalesSave
	@xmlDocument    NVARCHAR(MAX),  
	@xmlFlags       INT     = 0,  
	@ServiceSeq     INT     = 0,  
	@WorkingTag     NVARCHAR(10)= '',  
	@CompanySeq     INT     = 1,  
	@LanguageSeq    INT     = 1,  
	@UserSeq        INT     = 0,  
	@PgmSeq         INT     = 0  
AS   
	
	CREATE TABLE #hencom_TSLPrePublicSales (WorkingTag NCHAR(1) NULL)  
	EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#hencom_TSLPrePublicSales'     
	IF @@ERROR <> 0 RETURN  
	
	-- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)
	EXEC _SCOMLog  @CompanySeq   ,
   				   @UserSeq      ,
   				   'hencom_TSLPrePublicSales', -- 원테이블명
   				   '#hencom_TSLPrePublicSales', -- 템프테이블명
   				   'PPSRegSeq      ' , -- 키가 여러개일 경우는 , 로 연결한다. 
   				   'companyseq, DeptSeq, LastUserSeq, PPSRegSeq,ItemSeq, Qty, PublicSalesNo, Price, AssignDate, CurAmt, LastDateTime, PJTSeq, CurVat, CustSeq, Remark, DueDate, DelayDate, AddDate, IsAdd, AllotQty, AddQty'
	-- 작업순서 맞추기: DELETE -> UPDATE -> INSERT
	-- DELETE    
	IF EXISTS (SELECT TOP 1 1 FROM #hencom_TSLPrePublicSales WHERE WorkingTag = 'D' AND Status = 0)  
	BEGIN  
			DELETE hencom_TSLPrePublicSales
			  FROM #hencom_TSLPrePublicSales A 
				   JOIN hencom_TSLPrePublicSales B ON ( A.PPSRegSeq      = B.PPSRegSeq ) 
			 WHERE B.CompanySeq  = @CompanySeq
			   AND A.WorkingTag = 'D' 
			   AND A.Status = 0    
			 IF @@ERROR <> 0  RETURN
	END  
	-- UPDATE    
	IF EXISTS (SELECT 1 FROM #hencom_TSLPrePublicSales WHERE WorkingTag = 'U' AND Status = 0)  
	BEGIN
			UPDATE hencom_TSLPrePublicSales
			   SET DeptSeq        = A.DeptSeq        ,
                   LastUserSeq    = @UserSeq    ,
                   ItemSeq        = A.ItemSeq        ,
                   Qty            = IsNull(A.AllotQty,0)+IsNull(A.AddQty,0)    ,
                   PublicSalesNo  = A.PublicSalesNo  ,
                   Price          = A.Price          ,
                   AssignDate     = A.AssignDate     ,
                   CurAmt         = ((IsNull(A.AllotQty,0)+IsNull(A.AddQty,0))*A.Price)/1.1+0.5         ,
                   LastDateTime   = GetDate()   ,
                   PJTSeq         = A.PJTSeq         ,
                   CurVat         = ((IsNull(A.AllotQty,0)+IsNull(A.AddQty,0))*A.Price)-((IsNull(A.AllotQty,0)+IsNull(A.AddQty,0))*A.Price)/1.1+0.5        ,
                   CustSeq        = A.CustSeq        ,
                   Remark         = A.Remark         ,
				   DueDate        = A.DueDate        ,
				   DelayDate      = A.DelayDate      ,
				   AddDate        = A.AddDate        ,
				   IsAdd          = A.IsAdd,
				   AllotQty       = A.AllotQty,
				   AddQty         = A.AddQty
			  FROM #hencom_TSLPrePublicSales AS A 
			       JOIN hencom_TSLPrePublicSales AS B ON ( A.PPSRegSeq      = B.PPSRegSeq ) 
			 WHERE B.CompanySeq = @CompanySeq
			   AND A.WorkingTag = 'U' 
			   AND A.Status = 0    
			   
			IF @@ERROR <> 0  RETURN
	END  
	-- INSERT
	IF EXISTS (SELECT 1 FROM #hencom_TSLPrePublicSales WHERE WorkingTag = 'A' AND Status = 0)  
	BEGIN  
			INSERT INTO hencom_TSLPrePublicSales ( companyseq, DeptSeq        ,LastUserSeq    ,PPSRegSeq      ,
                         ItemSeq        ,Qty            ,PublicSalesNo  ,
                         Price          ,AssignDate     ,CurAmt         ,LastDateTime   ,
                         PJTSeq         ,CurVat         ,CustSeq        ,Remark,
						 DueDate        ,DelayDate      ,AddDate        ,IsAdd,
						 AllotQty       ,AddQty) 
			SELECT @CompanySeq,DeptSeq        , @UserSeq    ,PPSRegSeq      ,
                   ItemSeq        ,Qty            ,PublicSalesNo  ,
                   Price          ,AssignDate     ,((IsNull(A.AllotQty,0)+IsNull(A.AddQty,0))*A.Price)/1.1+0.5         ,GetDate()   ,
                   PJTSeq         ,((IsNull(A.AllotQty,0)+IsNull(A.AddQty,0))*A.Price)-((IsNull(A.AllotQty,0)+IsNull(A.AddQty,0))*A.Price)/1.1+0.5         ,CustSeq        ,Remark,
				   DueDate        ,DelayDate      ,AddDate        ,IsAdd,
				   AllotQty       ,AddQty
			  FROM #hencom_TSLPrePublicSales AS A   
			 WHERE A.WorkingTag = 'A' 
			   AND A.Status = 0    
			IF @@ERROR <> 0 RETURN
	END   
	SELECT * FROM #hencom_TSLPrePublicSales 
RETURN
