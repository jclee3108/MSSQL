
IF OBJECT_ID('KPXCM_SEQGWorkOrderReqQueryCHE') IS NOT NULL 
    DROP PROC KPXCM_SEQGWorkOrderReqQueryCHE
GO 

-- v2015.08.27 
/************************************************************
    설  명 - 데이터-작업요청Master : 조회(일반)
    작성일 - 20110429
    작성자 - 신용식
************************************************************/
CREATE PROC KPXCM_SEQGWorkOrderReqQueryCHE
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
    
    SELECT  @WOReqSeq = ISNULL(WOReqSeq,0) 
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH  (WOReqSeq      INT )
    
    SELECT A.WOReqSeq     , 
           A.ReqDate      , 
           A.DeptSeq      , 
           A.EmpSeq       , 
           A.WorkType     , 
           A.ReqCloseDate , 
           A.WorkContents , 
           A.WONo         , 
           A.FileSeq      , 
           B.FactUnitName AS AccUnitName  , 
           B.AccUnitSeq, 
           CASE WHEN ISNULL(C.CfmCode,0) = 0 AND ISNULL(D.IsProg,0) = 0 THEN 1010655001   
                WHEN ISNULL(C.CfmCode,0) = 5 AND ISNULL(D.IsProg,0) = 1 THEN 1010655002   
                WHEN ISNULL(C.CfmCode,0) = 1 THEN 1010655003   
                ELSE 0 END AS ProgType,   
           (SELECT TOP 1 MinorName   
              FROM _TDAUMinor   
             WHERE CompanySeq = @CompanySeq   
               AND MinorSeq = (CASE WHEN ISNULL(C.CfmCode,0) = 0 AND ISNULL(D.IsProg,0) = 0 THEN 1010655001   
                                 WHEN ISNULL(C.CfmCode,0) = 5 AND ISNULL(D.IsProg,0) = 1 THEN 1010655002   
                                 WHEN ISNULL(C.CfmCode,0) = 1 THEN 1010655003   
                                 ELSE 0 END  
                              )   
           ) AS ProgTypeName 
      FROM  _TEQWorkOrderReqMasterCHE AS A WITH (NOLOCK)
      OUTER APPLY ( SELECT TOP 1 Y.FactUnitName, Z.PdAccUnitSeq AS AccUnitSeq
                      FROM _TEQWorkOrderReqItemCHE AS Z 
                      LEFT OUTER JOIN _TDAFactUnit AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.FactUnit = Z.PdAccUnitSeq ) 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.WOReqSeq = A.WOReqSeq 
                  ) AS B 
      LEFT OUTER JOIN KPXCM_TEQChangeRequestCHE_Confirm  AS C ON ( C.CompanySeq = @CompanySeq AND C.CfmSeq = A.WOReqSeq ) 
      LEFT OUTER JOIN _TCOMGroupWare                    AS D ON ( D.CompanySeq = @CompanySeq AND D.WorkKind = 'EQOrderReq_CM' AND D.TblKey = C.CfmSeq )  
     WHERE A.CompanySeq = @CompanySeq
       AND A.WOReqSeq = @WOReqSeq 
    
    RETURN