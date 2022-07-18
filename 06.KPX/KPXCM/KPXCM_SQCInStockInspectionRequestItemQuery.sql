IF OBJECT_ID('KPXCM_SQCInStockInspectionRequestItemQuery') IS NOT NULL 
    DROP PROC KPXCM_SQCInStockInspectionRequestItemQuery
GO 

-- v2016.06.02 
/************************************************************
 설  명 - 재고검사의뢰-Item조회
 작성일 - 20141202
 작성자 - 전경만
************************************************************/
CREATE PROC KPXCM_SQCInStockInspectionRequestItemQuery
	@xmlDocument    NVARCHAR(MAX),  
	@xmlFlags       INT     = 0,  
	@ServiceSeq     INT     = 0,  
	@WorkingTag     NVARCHAR(10)= '',  
	@CompanySeq     INT     = 1,  
	@LanguageSeq    INT     = 1,  
	@UserSeq        INT     = 0,  
	@PgmSeq         INT     = 0  
AS   

	DECLARE @docHandle      INT,
			@ReqSeq         INT
			
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
	SELECT  @ReqSeq         = ISNULL(ReqSeq, 0)
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock2', @xmlFlags)
	  WITH (
			ReqSeq          INT
		   )
    
    SELECT A.ReqSeq,
           A.ReqSerl,
           A.QCType,
           Q.QCTypeName,
           A.ItemSeq,
           I.ItemName,
           I.ItemNo,
           I.Spec,
           A.LotNo,
           A.WHSeq,
           W.WHName,
           A.UnitSeq,
           U.UnitName,
           A.ReqQty,
           A.Remark,
           L.CreateDate, 
           L.RegDate, 
           L.SupplyCustSeq,
           C.CustName       AS SupplyCustName,
           B.BizUnitName, 
           A.Memo1 -- LotNo2 
      FROM KPX_TQCTestRequestItem   AS A           LEFT OUTER JOIN KPX_TQCQAProcessQCType   AS Q WITH(NOLOCK) ON Q.CompanySeq = A.CompanySeq
                                                                                                             AND Q.QCType = A.QCType
                                                   LEFT OUTER JOIN _TDAItem                 AS I WITH(NOLOCK) ON I.CompanySeq = A.CompanySeq
                                                                                                             AND I.ItemSeq = A.ItemSeq
                                                   LEFT OUTER JOIN _TDAWH                   AS W WITH(NOLOCK) ON W.CompanySeq = A.CompanySeq
                                                                                                             AND W.WHSeq = A.WHSeq
                                                   LEFT OUTER JOIN _TDAUnit                 AS U WITH(NOLOCK) ON U.CompanySeq = A.CompanySeq
                                                                                                             AND U.UnitSeq = A.UnitSeq
                                                   LEFT OUTER JOIN _TLGLotMaster            AS L WITH(NOLOCK) ON L.CompanySeq = A.CompanySeq
                                                                                                             AND L.ItemSeq = A.ItemSeq
                                                                                                             AND L.LotNo = A.LotNo
                                                   LEFT OUTER JOIN _TDACust                 AS C WITH(NOLOCK) ON C.CompanySeq = L.CompanySeq
                                                                                                             AND C.CustSeq = L.SupplyCustSeq
                                                   LEFT OUTER JOIN _TDABizUnit              AS B WITH(NOLOCK) ON B.CompanySeq = W.CompanySeq
                                                                                                             AND B.BizUnit = W.BizUnit 
     WHERE A.CompanySeq = @CompanySeq
       AND A.ReqSeq = @ReqSeq
RETURN
GO


