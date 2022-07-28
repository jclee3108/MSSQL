
IF OBJECT_ID('_SPRRetroPayDeducCalcItemQueryCHE') IS NOT NULL 
    DROP PROC _SPRRetroPayDeducCalcItemQueryCHE
GO 

/************************************************************ 
설  명 - 소급지급공제차액내역조회 - 항목조회 
작성일 - 2011.11.01 작성자 - 전경만 
************************************************************/ 
CREATE PROCEDURE _SPRRetroPayDeducCalcItemQueryCHE 
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
      WITH (  
            DeptSeq         INT,             
            EmpSeq          INT,             
            PuSeq           INT,             
            SerialNo        INT,             
            PbYM            NCHAR(6)
           )  
    
--select * from sysobjects where name like '_Tpr%Retro%'  
  
--_TPRRetroPb  
    SELECT P.ItemSeq,  
           I.ItemName,  
           SUM(ISNULL(P.RetroAmt,0) - ISNULL(P.Amt,0)) AS Amt,  
           S.MinorName AS SMIsAorDName  
      INTO #Result  
      FROM _TPRRetroPayResult AS A  
           LEFT OUTER JOIN _TPRRetroPayPay AS P WITH(NOLOCK) ON P.CompanySeq = A.CompanySeq  
                                                       AND P.PbYm = A.PbYm  
                                                       AND P.EmpSeq = A.EmpSeq  
                                                       AND P.SerialNo = A.SerialNo  
           LEFT OUTER JOIN _TPRBasPayItem AS I WITH(NOLOCK) ON I.CompanySeq = P.CompanySeq  
                                                           AND I.ItemSeq = P.ItemSeq  
           LEFT OUTER JOIN _TDASMinor AS S WITH(NOLOCK) ON S.CompanySeq = I.CompanySeq  
                                                       AND S.MinorSeq = I.SMIsAorD  
     WHERE A.CompanySeq = @CompanySeq  
       AND (A.EmpSeq = @EmpSeq)  
       AND (A.PuSeq = @PuSeq)  
       AND (A.SerialNo = @SerialNo)  
       AND (A.PbYm = @PbYM)  
     GROUP BY P.ItemSeq, I.ItemName, S.MinorName  
     UNION ALL  
    SELECT 0,  
           '지급총액',  
           SUM(A.TotPayAmt),  
           ''  
      FROM _TPRRetroPayResult AS A  
     WHERE A.CompanySeq = @CompanySeq  
       AND (A.EmpSeq = @EmpSeq)  
       AND (A.PuSeq = @PuSeq)  
       AND (A.SerialNo = @SerialNo)  
       AND (A.PbYm = @PbYM)  
     UNION ALL  
    SELECT D.ItemSeq,  
           I.ItemName,  
           SUM(ISNULL(D.RetroAmt,0) - ISNULL(D.Amt,0)) AS Amt,  
           S.MinorName AS SMIsAorDName  
      FROM _TPRRetroPayResult AS A  
           LEFT OUTER JOIN _TPRRetroPayDeduc AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq  
                                                         AND D.PbYm = A.PbYm  
                                                         AND D.EmpSeq = A.EmpSeq  
                                                         AND D.SerialNo = A.SerialNo  
           LEFT OUTER JOIN _TPRBasPayItem AS I WITH(NOLOCK) ON I.CompanySeq = D.CompanySeq  
                                                           AND I.ItemSeq = D.ItemSeq  
           LEFT OUTER JOIN _TDASMinor AS S WITH(NOLOCK) ON S.CompanySeq = I.CompanySeq  
                                                       AND S.MinorSeq = I.SMIsAorD  
     WHERE A.CompanySeq = @CompanySeq  
       AND (A.EmpSeq = @EmpSeq)  
       AND (A.PuSeq = @PuSeq)  
       AND (A.SerialNo = @SerialNo)  
       AND (A.PbYm = @PbYM)  
     GROUP BY D.ItemSeq, I.ItemName, S.MinorName  
     UNION ALL  
    SELECT 0,  
           '공제총액',  
           SUM(A.TotDeducAmt),  
           ''  
      FROM _TPRRetroPayResult AS A  
     WHERE A.CompanySeq = @CompanySeq  
  AND (A.EmpSeq = @EmpSeq)  
       AND (A.PuSeq = @PuSeq)  
       AND (A.SerialNo = @SerialNo)  
       AND (A.PbYm = @PbYM)  
     UNION ALL  
    SELECT 0,  
           '기지급총액',  
           SUM(A.TotPrevPayAmt),  
           ''  
      FROM _TPRRetroPayResult AS A  
     WHERE A.CompanySeq = @CompanySeq  
       AND (A.EmpSeq = @EmpSeq)  
       AND (A.PuSeq = @PuSeq)  
       AND (A.SerialNo = @SerialNo)  
       AND (A.PbYm = @PbYM)  
     UNION ALL  
    SELECT 0,  
           '실지급액',  
           SUM(A.ActPayAmt),  
           ''  
      FROM _TPRRetroPayResult AS A  
     WHERE A.CompanySeq = @CompanySeq  
       AND (A.EmpSeq = @EmpSeq)  
       AND (A.PuSeq = @PuSeq)  
       AND (A.SerialNo = @SerialNo)  
       AND (A.PbYm = @PbYM)  
      
    SELECT * FROM #Result  
RETURN  
  