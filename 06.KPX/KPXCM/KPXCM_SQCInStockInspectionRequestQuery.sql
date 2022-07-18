IF OBJECT_ID('KPXCM_SQCInStockInspectionRequestQuery') IS NOT NULL 
    DROP PROC KPXCM_SQCInStockInspectionRequestQuery
GO 

-- v2016.06.02 
/************************************************************
 설  명 - 재고검사의뢰-M조회
 작성일 - 20141202
 작성자 - 전경만
************************************************************/
CREATE PROC KPXCM_SQCInStockInspectionRequestQuery
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
			@ReqSeq         INT,
            @QCTypeName     NVARCHAR(100),
            @QCType         INT
			
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
	SELECT  @ReqSeq         = ISNULL(ReqSeq, 0)
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (
			ReqSeq          INT
		   )
    

    SELECT TOP 1
           @QCTypeName  = Q.QCTypeName,
           @QCType      = A.QCType
      FROM KPX_TQCTestRequestItem A LEFT OUTER JOIN KPX_TQCQAProcessQCType   AS Q WITH(NOLOCK) ON Q.CompanySeq  = A.CompanySeq
                                                                                              AND Q.QCType      = A.QCType
     WHERE 1=1
       AND A.CompanySeq   = @CompanySeq
       AND A.ReqSeq       = @ReqSeq


    SELECT A.ReqSeq,
           A.ReqNo,
           A.BizUnit,
           B.BizUnitName,
           A.ReqDate,
           A.DeptSeq,
           D.DeptName,
           A.EmpSeq, 
           E.EmpName,
           @QCTypeName  AS QCTypeName,
           @QCType      AS QCType    
      FROM KPX_TQCTestRequest       AS A LEFT OUTER JOIN _TDABizUnit    AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq
                                                                                         AND B.BizUnit = A.BizUnit
                                         LEFT OUTER JOIN _TDADept       AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq
                                                                                         AND D.DeptSeq = A.DeptSeq
                                         LEFT OUTER JOIN _TDAEmp        AS E WITH(NOLOCK) ON E.CompanySeq = A.CompanySeq
                                                                                         AND E.EmpSeq = A.EmpSeq
     WHERE A.CompanySeq = @CompanySeq
       AND A.ReqSeq = @ReqSeq
     
RETURN
GO


