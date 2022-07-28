
IF OBJECT_ID('_SPRRetroPayDeducCalcEmpQueryCHE') IS NOT NULL 
    DROP PROC _SPRRetroPayDeducCalcEmpQueryCHE
GO 

/************************************************************ 
설  명 - 소급지급공제차액내역조회 - 인원조회 
작성일 - 2011.11.01 작성자 - 전경만 
************************************************************/ 
CREATE PROCEDURE _SPRRetroPayDeducCalcEmpQueryCHE 
    @xmlDocument    NVARCHAR(MAX),     
    @xmlFlags       INT = 0,     
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',     
    @CompanySeq     INT = 0,    
    @LanguageSeq    INT = 1,     
    @UserSeq        INT = 0,     
    @PgmSeq         INT = 0 AS      
    
    
    DECLARE @docHandle  INT,             
            @DeptSeq        INT,             
            @EmpSeq         INT,             
            @PuSeq          INT,             
            @SerialNo       INT,             
            @PbYM           NCHAR(6)      

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument      

    SELECT  @DeptSeq        = ISNULL(DeptSeq, 0),  
            @EmpSeq         = ISNULL(EmpSeq, 0),  
            @PuSeq          = ISNULL(PuSeq, 0),  
            @SerialNo       = ISNULL(SerialNo, 0),  
            @PbYM           = ISNULL(PbYM, '')     
      FROM OPENXML (@docHandle, N'/ROOT/DataBlock1', @xmlFlags)     
      WITH (  DeptSeq         INT,             
              EmpSeq          INT,             
              PuSeq           INT,             
              SerialNo        INT,             
              PbYM            NCHAR(6)
           )  
    
    SELECT A.EmpSeq,  
           A.EmpID,  
           A.EmpName,  
           A.Ps,  
           A.UMPgName,  
           A.UMJpName,  
           A.PtName,  
           A.DeptSeq,  
           A.DeptName  
      FROM _TPRPayResult AS R  
           LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, @PbYM+'31') AS A ON A.EmpSeq = R.EmpSeq  
           LEFT OUTER JOIN _TDAUMinor AS G WITH(NOLOCK) ON G.CompanySeq = @CompanySeq  
                                                       AND G.MinorSeq = A.UMPgSeq  
           LEFT OUTER JOIN _TDAUMinor AS J WITH(NOLOCK) ON J.CompanySeq = @CompanySeq  
                                                       AND J.MinorSeq = A.UMJpSeq  
           LEFT OUTER JOIN _TDADept AS D WITH(NOLOCK) ON D.CompanySeq = @CompanySeq  
                                                     AND D.DeptSeq = A.DeptSeq  
     WHERE R.CompanySeq = @CompanySeq  
       AND (@EmpSeq = 0 OR R.EmpSeq = @EmpSeq)  
       AND (@DeptSeq = 0 OR R.DeptSeq = @DeptSeq)  
       AND (@PuSeq = R.PuSeq)  
       AND (@SerialNo = R.SerialNo)  
       AND (@PbYM = R.PbYm)  
     ORDER BY D.DispSeq, G.MinorSort, J.MinorSort, A.EmpID  
RETURN  
  