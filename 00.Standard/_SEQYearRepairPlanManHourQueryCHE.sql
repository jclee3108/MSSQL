
IF OBJECT_ID('_SEQYearRepairPlanManHourQueryCHE') IS NOT NULL
    DROP PROC _SEQYearRepairPlanManHourQueryCHE
GO 

-- v2014.12.04 

/************************************************************
  설  명 - 데이터-년차보수 계획공수 : 조회/ 현황조회 
  작성일 - 20110704
  작성자 - 김수용 
  ************************************************************/
 CREATE PROC [dbo].[_SEQYearRepairPlanManHourQueryCHE]
     @xmlDocument    NVARCHAR(MAX),
     @xmlFlags       INT             = 0,
     @ServiceSeq     INT             = 0,
     @WorkingTag     NVARCHAR(10)    = '',
     @CompanySeq     INT             = 1,
     @LanguageSeq    INT             = 1,
     @UserSeq        INT             = 0,
     @PgmSeq         INT             = 0
 AS
     
     DECLARE @docHandle          INT,
             @ReqSeq             INT,
             @WONo               NCHAR(8)
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT  
             @ReqSeq         = ReqSeq,
             @WONo           = WONo        
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH  (ReqSeq             INT,
              WONo               NCHAR(8) )
  
 /********************************************************************************************************************/
 /********************************************************************************************************************/
   IF @WorkingTag = 'WONO_QUERY' 
   BEGIN
         GOTO WONO_QUERY
   END
   ELSE
   BEGIN
         GOTO MAJOR_QUERY
   END
  
 /********************************************************************************************************************/
 /********************************************************************************************************************/
  -- WO번호 조회
  WONO_QUERY:
  BEGIN
    
     SELECT  
             A.WONo          AS WONo,
             C.MinorName     AS WorkOperSerlName,
             B.WorkOperSerl  AS WorkOperSerl,
             SUM(B.ManHour)       AS ManHour ,
             SUM(B.OTManHour)       AS OTManHour 
       FROM  _TEQYearRepairMngCHE AS A WITH (NOLOCK) JOIN  _TEQYearRepairPlanManHourCHE AS B WITH (NOLOCK) 
                                                         ON 1 = 1
                                                        AND A.CompanySeq = B.CompanySeq
                                                        AND A.ReqSeq     = B.ReqSeq
                                                       JOIN _TDAUMinor AS C WITH (NOLOCK)
                                                         ON 1 = 1
                                                        AND B.CompanySeq    = C.CompanySeq
                                                        AND B.WorkOperSerl   = C.MinorSeq 
       WHERE 1 = 1
        AND A.CompanySeq = @CompanySeq
        AND A.WONo       = @WONo
       GROUP BY  A.WONo,C.MinorName,B.WorkOperSerl
  
  
     RETURN
  END
  
 /********************************************************************************************************************/
 /********************************************************************************************************************/
    
  /********************************************************************************************************************/
 /********************************************************************************************************************/
  -- 조회
  MAJOR_QUERY:
  BEGIN
     SELECT  
             A.ReqSeq        AS ReqSeq,
             A.ReqSerl       AS ReqSerl,
             B.MinorName     AS WorkOperSerlName,
             A.WorkOperSerl  AS WorkOperSerl,
             A.ManHour       AS ManHour, 
             A.OTManHour     AS OTManHour, 
             A.DivSeq, 
             C.MinorName AS DivName, 
             A.EmpSeq AS EmpSeqSub, 
             CASE WHEN A.DivSeq = 20117001 THEN D.EmpName ELSE E.CustName END AS EmpNameSub 
       FROM _TEQYearRepairPlanManHourCHE AS A WITH (NOLOCK) 
       LEFT OUTER JOIN _TDAUMinor AS B WITH (NOLOCK) ON 1 = 1 AND A.CompanySeq = B.CompanySeq AND A.WorkOperSerl = B.MinorSeq 
       LEFT OUTER JOIN _TDAUMinor AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.DivSeq ) 
       LEFT OUTER JOIN _TDAEmp    AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = A.EmpSeq ) 
       LEFT OUTER JOIN _TDACust   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.EmpSeq ) 
     WHERE 1 = 1
       AND A.CompanySeq = @CompanySeq 
       AND A.ReqSeq = @ReqSeq 
  
  
      RETURN
  END
  
 /********************************************************************************************************************/
 /********************************************************************************************************************/
 GO 
