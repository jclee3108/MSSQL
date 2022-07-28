
IF OBJECT_ID('_SEQGWorkOrderReqQueryCHE') IS NOT NULL 
    DROP PROC _SEQGWorkOrderReqQueryCHE
GO 

-- v2015.03.31 

/************************************************************
  설  명 - 데이터-작업요청Master : 조회(일반)
  작성일 - 20110429
  작성자 - 신용식
 ************************************************************/
 CREATE PROC dbo._SEQGWorkOrderReqQueryCHE
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
     
     DECLARE @docHandle      INT,
             @WOReqSeq     INT 
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT  @WOReqSeq     = WOReqSeq      
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH  (WOReqSeq      INT )
     
     SELECT  A.WOReqSeq     , 
             A.ReqDate      , 
             A.DeptSeq      , 
             A.EmpSeq       , 
             A.WorkType     , 
             A.ReqCloseDate , 
             A.WorkContents , 
             A.WONo         , 
             A.FileSeq      , 
             B.FactUnitName AS AccUnitName  , 
             B.AccUnitSeq
             
             --A.DeptName     , 
             --A.EmpName      , 
             --A.WorkTypeName
       FROM  _TEQWorkOrderReqMasterCHE AS A WITH (NOLOCK)
       OUTER APPLY ( SELECT TOP 1 Y.FactUnitName, Z.PdAccUnitSeq AS AccUnitSeq
                       FROM _TEQWorkOrderReqItemCHE AS Z 
                       LEFT OUTER JOIN _TDAFactUnit AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.FactUnit = Z.PdAccUnitSeq ) 
                      WHERE Z.CompanySeq = @CompanySeq 
                        AND Z.WOReqSeq = A.WOReqSeq 
                   ) AS B 
        
      WHERE  A.CompanySeq = @CompanySeq
        AND  A.WOReqSeq   = @WOReqSeq 
         
      RETURN