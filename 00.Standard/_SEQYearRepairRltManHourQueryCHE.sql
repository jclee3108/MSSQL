
IF OBJECT_ID('_SEQYearRepairRltManHourQueryCHE') IS NOT NULL 
    DROP PROC _SEQYearRepairRltManHourQueryCHE
GO 

-- v2014.12.02 

/************************************************************  
  설  명 - 데이터-년차보수 실적 Item : 조회/ 현황조회   
  작성일 - 20110705  
  작성자 - 김수용   
  ************************************************************/  
 CREATE PROC [dbo].[_SEQYearRepairRltManHourQueryCHE]  
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
             @WONo               NCHAR(20)   
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
      SELECT    
             @WONo         = WONo          
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
       WITH  (WONo             NCHAR(20) )  
    
  /********************************************************************************************************************/  
 /********************************************************************************************************************/  
      
     SELECT    
             A.WONo          AS WONo,  
             A.RltSerl       AS RltSerl,  
             B.MinorName     AS WorkOperSerlName,  
             A.WorkOperSerl  AS WorkOperSerl,  
             A.ManHour       AS ManHour ,  
             A.OTManHour     AS OTManHour, 
             A.DivSeq, 
             C.MinorName AS DivName, 
             A.EmpSeq AS EmpSeqSub, 
             CASE WHEN A.DivSeq = 20117001 THEN D.EmpName ELSE E.CustName END AS EmpNameSub
             
       FROM _TEQYearRepairRltManHourCHE AS A WITH (NOLOCK)  
            JOIN _TDAUMinor AS B WITH (NOLOCK) ON 1 = 1  
                                                                AND A.CompanySeq    = B.CompanySeq  
                                                                AND A.WorkOperSerl   = B.MinorSeq   
       LEFT OUTER JOIN _TDAUMinor AS C WITh(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.DivSeq ) 
       LEFT OUTER JOIN _TDAEmp    AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = A.EmpSEq ) 
       LEFT OUTER JOIN _TDACust   AS E WITH(NOLOCK) ON ( E.CompanySeq=  @CompanySeq AND E.CustSeq = A.EmpSEq )
       
       WHERE 1 = 1  
        AND A.CompanySeq = @CompanySeq  
        AND A.WONo       = @WONo  
    
    
      RETURN  
  
    GO 
    exec _SEQYearRepairRltManHourQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <WONo>20140612</WONo>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=10323,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1000204,@PgmSeq=100201