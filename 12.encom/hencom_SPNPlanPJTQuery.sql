IF OBJECT_ID('hencom_SPNPlanPJTQuery') IS NOT NULL 
    DROP PROC hencom_SPNPlanPJTQuery
GO 

-- v2017.04.18 

-- 자차구간구분 컬럼추가 
/************************************************************
 설  명 - 데이터-사업계획현장등록_hncom : 조회
 작성일 - 20161014
 작성자 - 박수영
************************************************************/
CREATE PROC dbo.hencom_SPNPlanPJTQuery                
	@xmlDocument    NVARCHAR(MAX) ,            
	@xmlFlags	    INT 	= 0,            
	@ServiceSeq	    INT 	= 0,            
	@WorkingTag	    NVARCHAR(10)= '',                  
	@CompanySeq	    INT 	= 1,            
	@LanguageSeq	INT 	= 1,            
	@UserSeq	    INT 	= 0,            
	@PgmSeq	        INT 	= 0         
    
AS        
	
	DECLARE @docHandle      INT,
		    @DeptSeq         INT ,
            @BPYear          NCHAR(4)  
 
	EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             
	SELECT  @DeptSeq         = DeptSeq          ,
            @BPYear          = BPYear           
	  FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
	  WITH (DeptSeq          INT ,
            BPYear           NCHAR(4) )
	
	SELECT  A.PJTRegSeq ,
            A.BPYear ,
            A.DeptSeq ,
            A.PlanPJTName ,
            A.ShuttleDistance ,
            A.UMPriceType ,
            (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.UMPriceType ) AS UMPriceTypeName ,
            A.PriceRate ,
            A.Remark ,
            A.PJTSeq ,
            (SELECT PJTName FROM _TPJTProject WITH (NOLOCK) WHERE CompanySeq = @CompanySeq AND PJTSeq = A.PJTSeq ) AS PJTName ,
            A.CustRegSeq ,
            B.PlanCustName ,
            A.LastUserSeq ,
            A.LastDateTime, 
            C.MinorName AS UMDistanceDegreeName, 
            A.UMDistanceDegree
            
    FROM hencom_TPNPJT              AS A WITH (NOLOCK) 
    LEFT OUTER JOIN hencom_TPNCust  AS B WITH (NOLOCK) ON B.CompanySeq = A.CompanySeq AND B.CustRegSeq = A.CustRegSeq
    LEFT OUTER JOIN _TDAUMinor      AS C WITH (NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMDistanceDegree ) 
	 WHERE  A.CompanySeq = @CompanySeq
    AND A.DeptSeq = @DeptSeq         
    AND A.BPYear = @BPYear          
RETURN
go
exec hencom_SPNPlanPJTQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <BPYear>2017</BPYear>
    <DeptSeq>44</DeptSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1038924,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1031709