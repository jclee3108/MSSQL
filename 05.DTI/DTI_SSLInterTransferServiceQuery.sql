
IF OBJECT_ID('DTI_SSLInterTransferServiceQuery ') IS NOT NULL
    DROP PROC DTI_SSLInterTransferServiceQuery 
    
GO

-- v2013.06.20

-- 사내대체등록(서비스)조회_DTI By 이재천

CREATE PROC DTI_SSLInterTransferServiceQuery 
    @xmlDocument    NVARCHAR(MAX) ,            
    @xmlFlags	      INT 	= 0,            
    @ServiceSeq	    INT 	= 0,            
    @WorkingTag	    NVARCHAR(10)= '',                  
    @CompanySeq	    INT 	= 1,            
    @LanguageSeq	  INT 	= 1,            
    @UserSeq	      INT 	= 0,            
    @PgmSeq	        INT 	= 0         
AS 
    	
    DECLARE @docHandle  INT,
            @TransYM    NCHAR(6),
            @RcvDeptSeq INT  
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
    
    SELECT @TransYM    = TransYM,
           @RcvDeptSeq = RcvDeptSeq  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (TransYM     NCHAR(6),
            RcvDeptSeq  INT )
    
    SELECT A.TransYM, 
           A.Remark, 
           A.ItemSeq, 
           A.TransSeq, 
           A.SndDeptSeq, 
           A.RcvDeptSeq , 
           A.TransAmt, 
           B.DeptName    AS SndDeptName, 
           C.DeptName    AS RcvDeptName, 
           D.ItemName    AS ItemName,
           D.ItemNo      AS ItemNo,
           E.CfmCode     AS CfmCode
      FROM DTI_TSLInterTransferService AS A WITH (NOLOCK) 
      LEFT OUTER JOIN _TDADept         AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.DeptSeq = A.SndDeptSeq ) 
      LEFT OUTER JOIN _TDADept         AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.RcvDeptSeq ) 
      LEFT OUTER JOIN _TDAItem         AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN DTI_TSLInterTransferService_Confirm AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CfmSeq = A.TransSeq ) 
     WHERE A.CompanySeq = @CompanySeq
       AND (@TransYM = '' OR A.TransYM = @TransYM ) 
       AND (@RcvDeptSeq = 0 OR A.RcvDeptSeq = @RcvDeptSeq ) 

		

RETURN
