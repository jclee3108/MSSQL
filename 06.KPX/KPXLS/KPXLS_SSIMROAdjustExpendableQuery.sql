IF OBJECT_ID('KPXLS_SSIMROAdjustExpendableQuery') IS NOT NULL 
    DROP PROC KPXLS_SSIMROAdjustExpendableQuery
GO 

-- v2016.05.19 

/*
KPXLS 

저장품을 MRO에서 입고하고, ERP에서도 발주 후 입고처리해서 중복정산이 발생한다. 
MRO에서는 ERP에서 발주 등록 한 기준을 알지 못해 구분을 보낼 수 없기에
MRO계정과목으로 구분하여 MRO소모품입고정산에는 정산을 하지 못하도록 조회에 제외한다. 
*/
/************************************************************  
 설  명 - MRO소모품비용정산-조회  
 작성일 - 20141118  
 작성자 - 전경만  
 수정일 - 20151005 계산서번호 추가  
************************************************************/  
CREATE PROC KPXLS_SSIMROAdjustExpendableQuery
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
        @DelvDateFr     NCHAR(8),  
        @DelvDateTo     NCHAR(8),  
        @PODateFr       NCHAR(8),  
        @PODateTo       NCHAR(8),  
        @MROItemKind    NVARCHAR(100),  
        @PONo           NVARCHAR(100),  
        @GrNo           NVARCHAR(100),  
        @DeptName       NVARCHAR(100),  
        @EmpName        NVARCHAR(100),  
        @IsSlip         INT,  
        @CurrSeq        INT,  
        @CustSeq        INT,  
        @CustName       NVARCHAR(100),  
        @MROItemNo      NVARCHAR(100),  
        @MROAccName     NVARCHAR(100),  
        @BizUnit        INT,  
        @REQNO          NVARCHAR(100)  ,
        @DefEvidSeq     INT
     
 EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
 SELECT  @DelvDateFr     = ISNULL(DelvDateFr, ''),  
   @DelvDateTo     = ISNULL(DelvDateTo, ''),  
   @PODateFr       = ISNULL(PODateFr, ''),  
   @PODateTo       = ISNULL(PODateTo, ''),  
   @MROItemKind    = ISNULL(MROItemKind, ''),  
   @PONo           = ISNULL(PONo, ''),  
   @GrNo           = ISNULL(GrNo, ''),  
   @DeptName       = ISNULL(DeptName, ''),  
   @EmpName        = ISNULL(EmpName, ''),  
   @IsSlip         = ISNULL(IsSlip, 0),  
   @MROItemNo  = ISNULL(MROItemNo,''),  
   @MROAccName  = ISNULL(MROAccName,''),  
   @BizUnit  = ISNULL(BizUnit,0),  
   @REQNO   = ISNULL(REQNO,'')  
   FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
   WITH (  
   DelvDateFr      NCHAR(8),  
   DelvDateTo      NCHAR(8),  
   PODateFr        NCHAR(8),  
   PODateTo        NCHAR(8),  
   MROItemKind     NVARCHAR(100),  
   PONo            NVARCHAR(100),  
   GrNo            NVARCHAR(100),  
   DeptName        NVARCHAR(100),  
   EmpName         NVARCHAR(100),  
   IsSlip          INT,  
   MROItemNo  NVARCHAR(100),  
   MROAccName  NVARCHAR(100),  
   BizUnit   INT,  
   REQNO   NVARCHAR(100)  
     )  
      
   
  
    SELECT @CurrSeq=EnvValue   
    FROM _TCOMEnv WHERE EnvSeq=13 AND CompanySeq=@CompanySeq  
      
    SELECT @CustSeq = EnvValue FROM KPX_TCOMEnvItem WHERE CompanySeq = @CompanySeq AND EnvSeq = 20  
    SELECT @CustName = CustName FROM _TDACust WHERE CompanySeq = @CompanySeq AND CustSeq = @CustSeq  

    SELECT @DefEvidSeq = CASE WHEN @CompanySeq = 3 THEN 61 ELSE 10 END -- LS는 디폴트 증빙이 전자세금계산서(일반과세) -- 61 로 세팅
    
    -- 제외 할 계정과목 v2016.05.19 by이재천 
    CREATE TABLE #AccNo 
    (
        AccNo       NVARCHAR(100) 
    )
    INSERT INTO #AccNo ( AccNo ) 
    SELECT B.AccNo  
      FROM _TDAUMinorValue  AS A 
      JOIN _TDAAccount      AS B ON ( B.CompanySeq = @CompanySeq AND B.AccSeq = A.ValueSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.MajorSeq = 1012964 
       aND A.Serl = 1000001
    
      
 -- 20151002 세금계산서번호 입력된 경우 매입세금계산서의 사업자번호 조회되도록 수정  
 CREATE TABLE #TaxBillChoice(Serl INT, GRNo NVARCHAR(100), TaxNo NVARCHAR(100), TaxUnit INT)  
 INSERT INTO #TaxBillChoice(Serl, GRNo, TaxNo, TaxUnit)  
 SELECT Z.Serl, Z.GRNo, MAX(TU.TaxNoAlias), MAX(TU.TaxUnit)  
   FROM KPX_TPUDelvInItem_IF AS A WITH(NOLOCK)  
           LEFT OUTER JOIN _TDADept         AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq  
                                                             AND D.DeptSeq = A.DeptSeq  
           LEFT OUTER JOIN _TDAEmp          AS E WITH(NOLOCK) ON E.CompanySeq = A.CompanySeq  
                                                             AND E.EmpID = A.EmpID  
           LEFT OUTER JOIN KPX_TSIMROAdjustExpendable AS Z WITH(NOLOCK) ON Z.CompanySeq = A.CompanySeq  
                                                                       AND Z.GrNo = A.GrNo  
           LEFT OUTER JOIN ECTax..ZDTV3T_AP_HEAD AS B WITH(NOLOCK) ON RTRIM(B.ISSUE_ID) = Z.BillNo  
           JOIN _TDATaxUnit AS TU WITH(NOLOCK) ON TU.CompanySeq=@CompanySeq     
           AND REPLACE(B.IP_ID,'-','')=REPLACE(TU.TaxNo, '-','')   
           LEFT OUTER JOIN _TDAAccount      AS T WITH(NOLOCK) ON T.CompanySeq = A.CompanySeq  
                                                             AND T.AccNo = LEFT(A.AccSeq, 7)  
                                                             --AND T.AccSeq = LEFT(A.AccSeq,7)  
       LEFT OUTER JOIN _TDAItem AS II WITH(NOLOCK) ON II.CompanySeq = @CompanySeq AND A.ItemSeq = II.ItemNo   
     WHERE A.CompanySeq = @CompanySeq  
       AND (@DelvDateFr = '' OR A.DelvDate >= @DelvDateFr)  
       AND (@DelvDateTo = '' OR A.DelvDate <= @DelvDateTo)  
       AND (@PODateFr = '' OR A.PODate >= @PODateFr)  
       AND (@PODateTo = '' OR A.PODate <= @PODateTo)  
       AND (@MROItemNo = '' OR A.ItemNo LIKE @MROItemNo + '%')  
       AND (@PONo = '' OR A.PONo LIKE @PONo+'%')  
       AND (@GrNo = '' OR A.GRNo LIKE @GrNo+'%')  
       AND (@DeptName = '' OR D.DeptName LIKE @DeptName+'%')  
       AND (@EmpName = '' OR ISNULL(A.EmpName, E.EmpName) LIKE @EmpName+'%')  
       --AND A.ProcYN = '1'  
       AND (A.ItemSeq IS NULL OR II.ItemSeq IS NULL)  
       AND (@IsSlip=0 OR  CASE WHEN ISNULL(Z.SlipSeq,0) = 0 THEN 1039002 ELSE 1039001 END = @isSlip)   
    AND (@MROAccName='' OR T.AccName LIKE @MROAccName+'%')  
    AND (@BizUnit = 0 OR CASE WHEN ISNULL(Z.BizUnit,0) =0 THEN A.BizUnit ELSE Z.BizUnit END = @BizUnit)  
    AND (@REQNO = '' OR ISNULL(A.REQNO,'') LIKE @REQNO +'%')  
    AND ISNULL(Z.BillNo,'') <> ''  
  GROUP BY Z.Serl, Z.GRNo  
  
    SELECT A.GRNo,  
     A.Serl,  
           --CASE WHEN A.STATUS = 'C' THEN '신규'  
           --     WHEN A.Status = 'D' THEN '삭제' ELSE '' END    AS MROStatus,  
           --A.CompanySeq,  
           A.PONo,  
           A.DelvDate,  
           A.PODate,  
           A.ItemNo         AS MROItemNo,  
           A.POSeq,  
           A.DeptSeq,  
           D.DeptName,  
            A.AccSeq         AS MROAccSeq,  
           CONVERT(NVARCHAR(100),T.AccNo)          AS MROAccNo,  
           CONVERT(NVARCHAR(100),T.AccName)        AS MROAccName,  
           A.ItemName,  
           A.ItemSeq,  
           A.POQty,  
           A.DelvQty,  
           A.Price,  
     A.Price * A.DelvQty   AS Amt,  
           A.Price*0.1*A.DelvQty        AS VAT,  
           A.Price*A.DelvQty*1.1        AS TotalAmt,  
           @CustName                    AS CustName,  
           @CustSeq                     AS CustSeq,  
           A.EmpName,  
           A.EmpID,  
           ISNULL(E.EmpSeq, 0) AS EmpSeq,  
           CASE WHEN ISNULL(Z.BizUnit,0) =0 THEN A.BizUnit ELSE Z.BizUnit END BizUnit,  
           B.BizUnitName,   
     A.BizUnit AS BudgetBizUnit,  
     B2.BizUnitName AS BudgetBizUnitName,  
           CASE WHEN ISNULL(Z.CurrSeq,0)=0 THEN @CurrSeq ELSE Z.CurrSeq END AS CurrSeq,  
           CASE WHEN ISNULL(Z.CurrSeq,0)=0 THEN R1.CurrName ELSE R.CurrName END AS CurrName,  
             
           CASE WHEN ISNULL(Z.AccSeq,0) = 0 THEN T.AccSeq ELSE Z.AccSeq END AS AccSeq,  
           CASE WHEN ISNULL(Z.AccSeq,0) = 0 THEN T.AccName ELSE  C.AccName END AS AccName,  
           CASE WHEN ISNULL(Z.OppAccSeq,0) = 0 THEN 108 ELSE Z.OppAccSeq END AS OppAccSeq,  
           O.AccName        AS OppAccName,  
           CASE WHEN ISNULL(Z.VATSeq,0) = 0 THEN 32 ELSE Z.VATSeq END AS VatSeq,  
           V.AccName        AS VATName,  
           CASE WHEN ISNULL(Z.EvidSeq,0) = 0 THEN @DefEvidSeq ELSE Z.EvidSeq END AS EvidSeq,  
           I.EvidName,  
           Z.AccDate,  
           Z.CashDate,  
           Z.SlipSeq,  
           S.SlipID,  
           S.SlipNo,  
           CASE WHEN Z.GrNo IS NULL THEN '0'  
                ELSE '1' END AS IsSave,  
     Z.CCtrSeq,  
     ISNULL(CT.CCtrName,  CT2.CCtrName) AS CCtrName,  --- 연동테이블에 활동센터가없을때 ERP본테이블의 활동센터코드를 읽어 명칭을 가저온다. 2016.04.01 jhpark
     CASE WHEN ISNULL(T.SMAccKind,0)    = 4018005 THEN
        CASE WHEN ISNULL(Z.UMCostType,0) = 0 THEN 4001001 ELSE Z.UMCostType END 
     ELSE 0 END AS UMCostType,   
     UM.MinorName AS UMCostTypeName,  
     --CASE WHEN ISNULL(Z.TaxUnit,0) = 0 THEN 2 ELSE Z.TaxUnit END AS TaxUnit ,  
     --X.TaxNo,  
     CASE WHEN ISNULL(F.TaxNo,'') <> '' THEN F.TaxNo ELSE X.TaxNo END AS TaxNo,  
     CASE WHEN ISNULL(F.TaxUnit,0) <> 0 THEN F.TaxUnit ELSE (CASE WHEN ISNULL(Z.TaxUnit,0) = 0 THEN 2 ELSE Z.TaxUnit END) END AS TaxUnit ,        
     Z.SMPayType,  
     M.MinorName          AS SMPayTypeName,  
     CASE WHEN ISNULL(Z.SlipSeq,0) = 0 THEN '0'  
          ELSE '1' END IsSlipCK,  
  
   Delv.UseHistory,  
   ISNULL(A.ReqNo,'') AS ReqNo  
           --ISNULL(E.EmpName, '') AS EmpName  
             --A.ORY_GR_ID          AS Ory_GrNo             
           ,MI.MinorName AS CCtrSeq            
           ,CT.CCtrName    
           ,Z.BillNo  
      FROM KPX_TPUDelvInItem_IF AS A WITH(NOLOCK)  
           LEFT OUTER JOIN KPX_TSIMROAdjustExpendable AS Z WITH(NOLOCK) ON Z.CompanySeq = A.CompanySeq  
                                                                       AND Z.GrNo = A.GrNo  
           LEFT OUTER JOIN _TACSlipRow  AS S WITH(NOLOCK) ON S.CompanySeq = @CompanySeq  
                                                         AND S.SlipSeq = Z.SlipSeq   
           LEFT OUTER JOIN _TDABizUnit AS B WITH(NOLOCK) ON B.CompanySeq = @CompanySeq  
                                                        AND B.BizUnit = CASE WHEN ISNULL(Z.BizUnit,0) =0 THEN A.BizUnit ELSE Z.BizUnit END  
     LEFT OUTER JOIN _TDABizUnit AS B2 WITH(NOLOCK) ON B2.CompanySeq = @CompanySeq  
              AND  B2.BizUnit    = A.BizUnit    
           LEFT OUTER JOIN _TDAAccount AS C WITH(NOLOCK) ON C.CompanySeq = @CompanySeq  
                                                        AND C.AccSeq = Z.AccSeq  
           LEFT OUTER JOIN _TDAAccount AS O WITH(NOLOCK) ON O.CompanySeq = @CompanySeq  
                                                        AND O.AccSeq = CASE WHEN ISNULL(Z.OppAccSeq,0) = 0 THEN 108 ELSE Z.OppAccSeq END  
           LEFT OUTER JOIN _TDAAccount AS V WITH(NOLOCK) ON V.CompanySeq = @CompanySeq  
                                                        AND V.AccSeq = CASE WHEN ISNULL(Z.VATSeq,0) = 0 THEN 32 ELSE Z.VATSeq END  
           LEFT OUTER JOIN _TDACurr AS R WITH(NOLOCK) ON R.CompanySeq = @CompanySeq  
                                                     AND R.CurrSeq = Z.CurrSeq  
           LEFT OUTER JOIN _TDACurr AS R1 WITH(NOLOCK) ON R1.CompanySeq=@CompanySeq  
               AND R1.CurrSeq=@CurrSeq  
           LEFT OUTER JOIN _TDAEvid AS I WITH(NOLOCK) ON I.CompanySeq = @CompanySeq  
                                                     AND I.EvidSeq = CASE WHEN ISNULL(Z.EvidSeq,0) = 0 THEN @DefEvidSeq ELSE Z.EvidSeq END  
           LEFT OUTER JOIN _TDADept         AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq  
                                                             AND D.DeptSeq = A.DeptSeq  
           LEFT OUTER JOIN _TDAEmp          AS E WITH(NOLOCK) ON E.CompanySeq = A.CompanySeq  
                                                             AND E.EmpID = A.EmpID  
           LEFT OUTER JOIN _TDAAccount      AS T WITH(NOLOCK) ON T.CompanySeq = A.CompanySeq  
                                                             AND T.AccNo = LEFT(A.AccSeq, 7)  
                                                             --AND T.AccSeq = LEFT(A.AccSeq,7)  
     --LEFT OUTER JOIN _TDACCtr   AS CT WITH(NOLOCK) ON Z.CompanySeq = CT.CompanySeq  
     --            AND Z.CCtrSeq    = CT.CCtrSeq  
           LEFT OUTER JOIN _TDAUMinor  AS UM WITH(NOLOCK) ON  UM.CompanySeq = @CompanySeq  
                                                         AND CASE WHEN ISNULL(T.SMAccKind,0)    = 4018005 THEN
              CASE WHEN ISNULL(Z.UMCostType,0) = 0 THEN 4001001 ELSE Z.UMCostType END 
                                                                  ELSE 0 END = UM.MinorSeq  
           LEFT OUTER JOIN _TDATaxUnit AS X WITH(NOLOCK) ON X.CompanySeq = @CompanySeq  
                                                        AND X.TaxUnit = CASE WHEN ISNULL(Z.TaxUnit,0) = 0 THEN 2 ELSE Z.TaxUnit END  
           LEFT OUTER JOIN _TDASMinor  AS M WITH(NOLOCK) ON M.CompanySeq = @CompanySeq  
                                                        AND M.MinorSeq = Z.SMPayType  
           --LEFT OUTER JOIN _TDAEmp          AS P WITH(NOLOCK) ON P.CompanySeq = @CompanySeq  
           --                                                  AND P.EmpId = A.EmpID       
           LEFT OUTER JOIN (SELECT CompanySeq,GRNo, MAX(UseHistory) AS UseHistory  
                              FROM KPX_TPUDelvItem_IF  
                             WHERE CompanySeq = @CompanySeq  
                             GROUP BY CompanySeq,GRNo ) AS Delv ON Delv.CompanySeq = A.CompanySeq  
                                                               AND Delv.GRNO  = A.GRNO      
           LEFT OUTER JOIN _TDAItem AS II WITH(NOLOCK) ON II.CompanySeq = @CompanySeq AND A.ItemSeq = II.ItemNo   
           LEFT OUTER JOIN _TDAUMinor AS MI WITH(NOLOCK) ON MI.CompanySeq = @CompanySeq AND MI.MajorSeq = 1011634 AND MI.MinorName = A.CCtrCd        
           LEFT OUTER JOIN _TDAUMinorValue AS MV WITH(NOLOCK) ON MV.CompanySeq = MI.CompanySeq AND MI.MinorSeq = MV.MinorSeq       
           LEFT OUTER JOIN _TDACCtr   AS CT WITH(NOLOCK) ON MV.CompanySeq = CT.CompanySeq    AND MV.ValueSeq    = CT.CCtrSeq       
           LEFT OUTER JOIN _TDACCtr   AS CT2 WITH(NOLOCK) ON Z.CompanySeq = CT2.CompanySeq   AND Z.CCtrSeq    = CT2.CCtrSeq  

           LEFT OUTER JOIN #TaxBillChoice AS F WITH(NOLOCK) ON F.Serl = Z.Serl AND F.GRNo = Z.GRNo  
     WHERE A.CompanySeq = @CompanySeq  
       AND (@DelvDateFr = '' OR A.DelvDate >= @DelvDateFr)  
       AND (@DelvDateTo = '' OR A.DelvDate <= @DelvDateTo)  
       AND (@PODateFr = '' OR A.PODate >= @PODateFr)  
       AND (@PODateTo = '' OR A.PODate <= @PODateTo)  
       AND (@MROItemKind = '')  
       AND (@MROItemNo = '' OR A.ItemNo LIKE @MROItemNo + '%')  
       AND (@PONo = '' OR A.PONo LIKE @PONo+'%')  
       AND (@GrNo = '' OR A.GRNo LIKE @GrNo+'%')  
       AND (@DeptName = '' OR D.DeptName LIKE @DeptName+'%')  
       AND (@EmpName = '' OR ISNULL(A.EmpName, E.EmpName) LIKE @EmpName+'%')  
       --AND A.ProcYN = '1'  
       AND (A.ItemSeq IS NULL OR II.ItemSeq IS NULL)  
       AND (@IsSlip=0 OR  CASE WHEN ISNULL(Z.SlipSeq,0) = 0 THEN 1039002 ELSE 1039001 END = @isSlip)   
    AND (@MROAccName='' OR T.AccName LIKE @MROAccName+'%')  
    AND (@BizUnit = 0 OR CASE WHEN ISNULL(Z.BizUnit,0) =0 THEN A.BizUnit ELSE Z.BizUnit END = @BizUnit)  
    AND (@REQNO = '' OR ISNULL(A.REQNO,'') LIKE @REQNO +'%')  
    AND NOT EXISTS (SELECT 1 FROM #AccNo WHERE AccNo = A.AccSeq )  -- 제외 할 계정과목 v2016.05.19 by이재천 
RETURN

GO


EXEC KPXLS_SSIMROAdjustExpendableQuery @xmlDocument = N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <DelvDateFr>20160401</DelvDateFr>
    <DelvDateTo>20160430</DelvDateTo>
    <PODateFr />
    <PODateTo />
    <MROAccName />
    <PONo />
    <DeptName />
    <EmpName />
    <GrNo />
    <IsSlip />
    <MROItemNo />
    <BizUnit />
    <REQNO />
  </DataBlock1>
</ROOT>', @xmlFlags = 2, @ServiceSeq = 1036138, @WorkingTag = N'', @CompanySeq = 3, @LanguageSeq = 1, @UserSeq = 1, @PgmSeq = 1021423
