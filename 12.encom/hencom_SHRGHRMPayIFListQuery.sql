 
IF OBJECT_ID('hencom_SHRGHRMPayIFListQuery') IS NOT NULL   
    DROP PROC hencom_SHRGHRMPayIFListQuery  
GO  

-- v2018.04.05
  
-- GHRM급여현황-조회 by 이재천
CREATE PROC hencom_SHRGHRMPayIFListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @docHandle  INT,  
            -- 조회조건   
            @StdYM      NCHAR(6)
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @StdYM   = ISNULL( StdYM, '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (StdYM   NCHAR(6))    

    SELECT  C.EmpName as AAA -- 사원
    ,       C.EmpSeq as BBB -- 사원코드
    ,       A.EMP_NO AS CCC -- 사번
    ,       '' AS DDD -- 기본월급
    ,       '' AS EEE -- 기본일급
    ,       '' AS FFF -- 기본시급
    ,       '' AS GGG -- 통상임금
    ,       '' AS HHH -- 통상일급
    ,       '' AS III -- 통상시급
    ,       '' AS JJJ -- 지급총액
    ,       '' AS KKK -- 소급지급총액차액
    ,       '' AS LLL -- 기지급총액
    ,       '' AS MMM -- 소급기지급총액차액
    ,       '' AS NNN -- 인정상여총액
    ,       '' AS OOO -- 소급인정상여총액차액
    ,       '' AS PPP -- 공제총액
    ,       '' AS QQQ -- 소급공제총액차액
    ,       '' AS RRR -- 실지급액
    ,       '' AS SSS -- 소급실지급액차액
    ,       '' AS TTT -- 갑근세
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Y02' THEN A.ITEM_AMT ELSE 0 END)) AS AAAA -- 건강보험
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Y03' THEN A.ITEM_AMT ELSE 0 END)) AS BBBB -- 고용보험
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Y01' THEN A.ITEM_AMT ELSE 0 END)) AS CCCC -- 국민연금
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'T01' THEN A.ITEM_AMT ELSE 0 END)) AS DDDD -- 기타공제
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'W03' THEN A.ITEM_AMT ELSE 0 END)) AS EEEE -- 대출금상환
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'W04' THEN A.ITEM_AMT ELSE 0 END)) AS FFFF -- 대출금이자
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'V01' THEN A.ITEM_AMT ELSE 0 END)) AS GGGG -- 동호회비
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'W01' THEN A.ITEM_AMT ELSE 0 END)) AS HHHH -- 상조회비
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'T02' THEN A.ITEM_AMT ELSE 0 END)) AS IIII -- 상해보험공제
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Z01' THEN A.ITEM_AMT ELSE 0 END)) AS JJJJ -- 소득세
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'T05' THEN A.ITEM_AMT ELSE 0 END)) AS KKKK -- 신원보증보험
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Z04' THEN A.ITEM_AMT ELSE 0 END)) AS LLLL -- 연말갑근세
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Z06' THEN A.ITEM_AMT ELSE 0 END)) AS MMMM -- 연말농특세
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Z05' THEN A.ITEM_AMT ELSE 0 END)) AS NNNN -- 연말주민세
    ,       '' AS OOOO -- 정산농특세
    ,       '' AS PPPP -- 정산소득세
    ,       '' AS QQQQ -- 정산지방소득세
    ,       '' AS RRRR -- 주민세
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'Z02' THEN A.ITEM_AMT ELSE 0 END)) AS AAAAA -- 지방소득세
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'T03' THEN A.ITEM_AMT ELSE 0 END)) AS BBBBB -- 회람가불
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'G05' THEN A.ITEM_AMT ELSE 0 END)) AS CCCCC -- 귀성여비
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A09' THEN A.ITEM_AMT ELSE 0 END)) AS DDDDD -- 근속수당
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A01' THEN A.ITEM_AMT ELSE 0 END)) AS EEEEE -- 기본급
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A14' THEN A.ITEM_AMT ELSE 0 END)) AS FFFFF -- 기술수당
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'H01' THEN A.ITEM_AMT ELSE 0 END)) AS GGGGG -- 기타수당
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A13' THEN A.ITEM_AMT ELSE 0 END)) AS HHHHH -- 상여금
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'H02' THEN A.ITEM_AMT ELSE 0 END)) AS IIIII -- 상해보험료
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'H06' THEN A.ITEM_AMT ELSE 0 END)) AS JJJJJ -- 소급분
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A15' THEN A.ITEM_AMT ELSE 0 END)) AS KKKKK -- 식대
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A06' THEN A.ITEM_AMT ELSE 0 END)) AS LLLLL -- 야간근무수당
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A02' THEN A.ITEM_AMT ELSE 0 END)) AS MMMMM -- 연장근로수당
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'E01' THEN A.ITEM_AMT ELSE 0 END)) AS NNNNN -- 연차수당
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'H04' THEN A.ITEM_AMT ELSE 0 END)) AS OOOOO -- 자격수당
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'H03' THEN A.ITEM_AMT ELSE 0 END)) AS PPPPP -- 전월조정
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A08' THEN A.ITEM_AMT ELSE 0 END)) AS QQQQQ -- 주휴근무수당
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A04' THEN A.ITEM_AMT ELSE 0 END)) AS RRRRR -- 주휴기본수당
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A10' THEN A.ITEM_AMT ELSE 0 END)) AS SSSSS -- 직무수당
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'G06' THEN A.ITEM_AMT ELSE 0 END)) AS TTTTT -- 직위수당
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A03' THEN A.ITEM_AMT ELSE 0 END)) AS UUUUU-- 직책수당
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'B02' THEN A.ITEM_AMT ELSE 0 END)) AS VVVVV-- 차량유지비
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'G01' THEN A.ITEM_AMT ELSE 0 END)) AS XXXXX-- 학자보조금
    ,       SUM((CASE WHEN A.ATTRIBUTE1 = '휴가비' THEN A.ITEM_AMT ELSE 0 END)) AS YYYYY -- 휴가비
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'G04' THEN A.ITEM_AMT ELSE 0 END)) AS ZZZZZ -- 휴일교통비
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A07' THEN A.ITEM_AMT ELSE 0 END)) AS AAAAAA -- 휴일근무수당
    ,       SUM((CASE WHEN A.ATTRIBUTE2 = 'A05' THEN A.ITEM_AMT ELSE 0 END)) AS BBBBBB -- 휴일기본수당
      FROM   [GHRM]..[HGHR].[ENCOM_PAY_ITEM] AS A
      JOIN [GHRM]..[HGHR].[ENCOM_PAY_WORK] AS B ON A.CALC_SEQ = B.CALC_SEQ AND B.CALC_YY = LEFT(@StdYM,4) AND B.CALC_MM = RIGHT(@StdYM,2)
      LEFT OUTER JOIN (
                        SELECT DISTINCT Z.EmpID, Z.EmpName, Z.EmpSeq
                          FROM _fnAdmEmpOrd(@CompanySeq, '') AS Z 
                      ) AS C ON ( C.EmpID = A.EMP_NO ) 
     GROUP BY C.EmpName, C.EmpSeq, A.EMP_NO
     ORDER BY CCC
    RETURN  
go
begin tran 
EXEC hencom_SHRGHRMPayIFListQuery @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <StdYM>201707</StdYM>
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 2000030, @WorkingTag = N'', @CompanySeq = 1, @LanguageSeq = 1, @UserSeq = 1, @PgmSeq = 2000034
rollback 
