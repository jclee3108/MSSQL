  
IF OBJECT_ID('yw_SACSalesReceiptPlanDiffListQuery') IS NOT NULL   
    DROP PROC yw_SACSalesReceiptPlanDiffListQuery  
GO  
  
-- v2013.12.17  
  
-- 수금계획대비실적_yw(조회) by이재천   
CREATE PROC yw_SACSalesReceiptPlanDiffListQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @QueryYM    NVARCHAR(6), 
            @CustSeq    INT, 
            @DeptSeq    INT, 
            @SMLocalExp INT, 
            @AmtUnit    DECIMAL(19,5), 
            @CheckBox   NCHAR(1), 
            @PlanType   INT 
            
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @QueryYM    = ISNULL(QueryYM,''),   
           @CustSeq    = ISNULL(CustSeq,0),   
           @DeptSeq    = ISNULL(DeptSeq,0),  
           @SMLocalExp = ISNULL(SMLocalExp,0), 
           @AmtUnit    = ISNULL(AmtUnit,0),   
           @CheckBox   = ISNULL(CheckBox, '')    
    
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            QueryYM    NVARCHAR(6), 
            CustSeq    INT, 
            DeptSeq    INT, 
            SMLocalExp INT, 
            AmtUnit    DECIMAL(19,5),
            CheckBox   NCHAR(1) 
          )    
      
    SELECT @PlanType = CASE WHEN ISNULL(@SMLocalExp,0) = 8918001 THEN 1 
                            WHEN ISNULL(@SMLocalExp,0) = 8918002 THEN 2 
                            ELSE 0 END 
    --select @CheckBox, @QueryYM
    -- 최종조회   
    SELECT CASE WHEN A.PlanType = 1 THEN 8918001 
                WHEN A.PlanType = 2 THEN 8918002
                ELSE 0 
                END AS SMLocalExp,  
           --A.PlanType AS PlanType, 
           A.CustSeq, 
           A.DeptSeq, 
           A.SMInType, 
           A.CurrSeq, 
           A.PlanAmt, 
           A.PlanDomAmt, 
           0 AS ThisAmt, 
           0 AS ThisDomAmt, 
           (SELECT SUM(PlanAmt) 
              FROM yw_TACSalesReceiptPlan 
             WHERE CompanySeq = @CompanySeq AND PlanYM BETWEEN LEFT(@QueryYM,4) + '01' AND @QueryYM
               AND PlanType = A.PlanType 
               AND Serl = A.Serl 
            ) AS PlanSumAmt, 
          (SELECT SUM(PlanDomAmt) 
             FROM yw_TACSalesReceiptPlan 
            WHERE CompanySeq = @CompanySeq AND PlanYM BETWEEN LEFT(@QueryYM,4) + '01' AND @QueryYM
              AND PlanType = A.PlanType 
              AND Serl = A.Serl 
          ) AS PlanSumDomAmt, 
           0 AS ThisSumAmt, 
           0 AS ThisSumDomAmt ,
           A.PlanYm AS DateYM
      INTO #yw_TACSalesReceiptPlan
      FROM yw_TACSalesReceiptPlan AS A WITH(NOLOCK) 
     WHERE A.CompanySeq = @CompanySeq 
       AND (@CustSeq = 0 OR A.CustSeq = @CustSeq) 
       AND (@DeptSeq = 0 OR A.DeptSeq = @DeptSeq) 
       AND (@PlanType = 0 OR A.PlanType = @PlanType) 
       AND (@QueryYM = A.PlanYM) 
    
    --select * From  #yw_TACSalesReceiptPlan
    INSERT INTO #yw_TACSalesReceiptPlan (
                                         SMLocalExp, CustSeq, DeptSeq, SMInType, CurrSeq, 
                                         PlanAmt, PlanDomAmt, ThisAmt, ThisDomAmt, PlanSumAmt, 
                                         PlanSumDomAmt, ThisSumAmt, ThisSumDomAmt, DateYM
                                        )
        SELECT CASE WHEN L.ValueText = '1' AND M.ValueText = '0' THEN 8918001 
                    WHEN M.ValueText = '1' AND L.ValueText = '0' THEN 8918002 
                    ELSE 0 
                    END, 
               A.RemValSeq AS CustSeq, -- 거래처코드  
               ISNULL(G.DeptSeq,0) AS DeptSeq, 
               CASE WHEN  L.ValueText = '1' AND M.ValueText = '0' THEN I.SMReceiptKind 
                    ELSE 0 
                    END AS SMInType, 
               A.CurrSeq, 
               0,
               0,
               (SELECT ISNULL(SUM(P.OffAmt) ,0)
                  FROM _TACSlipOff AS P 
                 WHERE P.CompanySeq = @CompanySeq 
                   AND P.SlipSeq = J.SlipSeq 
                   AND P.OnSlipSeq = J.OnSlipSeq 
                   AND LEFT(B.AccDate,6) = @QueryYM
               ), 
               (SELECT ISNULL(SUM(P.OffForAmt),0) 
                  FROM _TACSlipOff AS P 
                 WHERE P.CompanySeq = @CompanySeq 
                   AND P.SlipSeq = J.SlipSeq 
                   AND P.OnSlipSeq = J.OnSlipSeq 
                   AND LEFT(B.AccDate,6) = @QueryYM
               ), 
               0,
               0,
               (SELECT ISNULL(SUM(P.OffAmt),0) 
                  FROM _TACSlipOff AS P
                 WHERE P.CompanySeq = @CompanySeq 
                   AND P.SlipSeq = J.SlipSeq 
                   AND P.OnSlipSeq = J.OnSlipSeq
                   AND LEFT(B.AccDate,6) BETWEEN LEFT(@QueryYM,4)+'01' AND @QueryYM 
              ),
              (SELECT ISNULL(SUM(P.OffForAmt),0)
                  FROM _TACSlipOff AS P
                WHERE P.CompanySeq = @CompanySeq 
                  AND P.SlipSeq = J.SlipSeq 
                  AND P.OnSlipSeq = J.OnSlipSeq 
                  AND LEFT(B.AccDate,6) BETWEEN LEFT(@QueryYM,4)+'01' AND @QueryYM
              ), 
              LEFT(B.AccDate,6)
        
          FROM _TACSlipOff            AS J WITH(NOLOCK)   
          JOIN _TACSlipOn             AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.SlipSeq = J.OnSlipSeq AND RemSeq = 1017 ) 
          JOIN _TACSlipRow            AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq 
                                                         AND B.SlipSeq = A.SlipSeq 
                                                         AND LEFT(B.AccDate,6) BETWEEN LEFT(@QueryYM,4)+'01' AND @QueryYM
                                                         AND B.AccSeq IN (SELECT A.ValueSeq 
                                                                            FROM _TDAUMinorValue AS A 
                                                                           WHERE A.CompanySeq = @CompanySeq 
                                                                             AND A.MajorSeq = 1008968 AND A.Serl = 1000001
                                                                         ) 
                                                          ) -- 외상매출금 
          JOIN _TACSlip               AS Z WITH(NOLOCK) ON ( Z.CompanySeq = @CompanySeq AND Z.SlipMstSeq = B.SlipMstSeq AND Z.IsSet = '1' ) 
          JOIN _TDACust               AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.RemValSeq )    
          LEFT OUTER JOIN _TSLCustSalesEmp      AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.RemValSeq AND D.SDate <= B.AccDate )  
          LEFT OUTER JOIN _TSLCustSalesEmpHist  AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.RemValSeq AND B.AccDate BETWEEN E.SDate AND E.EDate )  
          OUTER APPLY (SELECT TOP 1 --I2.ReceiptMonth, I2.ReceiptDate,  
                              I1.SMCondStd, 
                              I2.SMReceiptKind   
                        FROM _TDACustSalesReceiptCond AS I1 WITH(NOLOCK) -- select * from _TDASMinor where MinorSeq in (8018002,8016001)  
                        JOIN _TDACustSalesReceiptStd  AS I2 WITH(NOLOCK) ON ( I2.CompanySeq = @CompanySeq AND I2.CondSeq = I1.CondSeq )  
                       WHERE I1.CompanySeq = @CompanySeq   
                         AND I1.CustSeq = C.CustSeq  
                       ORDER BY I2.CondSerl   
                      ) AS I   
          JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON ( K.CompanySeq = @CompanySeq AND K.ValueSeq = B.AccSeq AND K.MajorSeq = 1008968 AND K.Serl = 1000001 ) 
          JOIN _TDAUMinorValue AS L WITH(NOLOCK) ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = K.MinorSeq AND L.Serl = 1000002 ) 
          JOIN _TDAUMinorValue AS M WITH(NOLOCK) ON ( M.CompanySeq = @CompanySeq AND M.MinorSeq = K.MinorSeq AND M.Serl = 1000003 ) 
          LEFT OUTER JOIN dbo._fnAdmEmpOrd(@CompanySeq,'')  AS G ON ( G.EmpSeq = ISNULL(ISNULL(D.EmpSeq,E.EmpSeq),0) ) -- dbo._fnAdmEmpOrd(1,'') 
        
         WHERE A.CompanySeq = @CompanySeq   
           AND A.RemSeq = 1017 -- 관리항목(거래처)   
           --AND A.OnAmt <> ISNULL(J.OffAmt,0)   
           AND (@CustSeq = 0 OR A.RemValSeq = @CustSeq) 
           AND (@DeptSeq = 0 OR Z.RegDeptSeq = @DeptSeq) 
        
               
        IF @CheckBox = '0' 
        BEGIN 
        SELECT A.SMLocalExp AS SMLocalExp, 
               F.MinorName AS SMLocalExpName,  
               A.CustSeq, 
               B.CustName, 
               A.DeptSeq, 
               C.DeptName, 
               A.SMInType, 
               E.MinorName AS SMInTypeName, 
               A.CurrSeq, 
               D.CurrName, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.PlanAmt) ELSE SUM(A.PlanAmt) / @AmtUnit END AS PlanAmt, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.PlanDomAmt) ELSE SUM(A.PlanDomAmt) / @AmtUnit END AS PlanDomAmt, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.ThisAmt) ELSE SUM(A.ThisAmt) / @AmtUnit END AS ThisAmt, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.ThisDomAmt) ELSE SUM(A.ThisDomAmt) / @AmtUnit END AS ThisDomAmt, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.PlanSumAmt) ELSE SUM(A.PlanSumAmt) / @AmtUnit END AS PlanSumAmt, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.PlanSumDomAmt) ELSE SUM(A.PlanSumDomAmt) / @AmtUnit END AS PlanSumDomAmt, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.ThisSumAmt) ELSE SUM(A.ThisSumAmt) / @AmtUnit END AS ThisSumAmt, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.ThisSumDomAmt) ELSE SUM(A.ThisSumDomAmt) / @AmtUnit END  AS ThisSumDomAmt, 
               CONVERT(DECIMAL(19,2),CASE WHEN SUM(A.PlanAmt) = 0 THEN 0 ELSE (SUM(A.ThisAmt)/SUM(A.PlanAmt)) * 100 END) AS ReceiptM, 
               CONVERT(DECIMAL(19,2),CASE WHEN SUM(A.PlanSumAmt) = 0 THEN 0 ELSE (SUM(A.ThisSumAmt)/SUM(A.PlanSumAmt)) * 100 END) AS ReceiptSum
               
          FROM #yw_TACSalesReceiptPlan AS A 
          LEFT OUTER JOIN _TDACust AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq ) 
          LEFT OUTER JOIN _TDADept AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
          LEFT OUTER JOIN _TDACurr AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CurrSeq = A.CurrSeq ) 
          LEFT OUTER JOIN _TDASMinor AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.SMInType ) 
          LEFT OUTER JOIN _TDASMinor AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND  A.SMLocalExp = F.MinorSeq ) 
         WHERE @SMLocalExp = 0 OR A.SMLocalExp = @SMLocalExp 
         GROUP BY A.SMLocalExp, A.CustSeq, A.DeptSeq, A.SMInType, A.CurrSeq, B.CustName, C.DeptName, E.MinorName, D.CurrName, F.MinorName 
         
        END 
        ELSE
        BEGIN
        SELECT A.SMLocalExp AS SMLocalExp, 
               F.MinorName AS SMLocalExpName,  
               A.CustSeq, 
               B.CustName, 
               A.DeptSeq, 
               C.DeptName, 
               A.SMInType, 
               E.MinorName AS SMInTypeName, 
               A.CurrSeq, 
               D.CurrName, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.PlanAmt) ELSE SUM(A.PlanAmt) / @AmtUnit END AS PlanAmt, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.PlanDomAmt) ELSE SUM(A.PlanDomAmt) / @AmtUnit END AS PlanDomAmt, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.ThisAmt) ELSE SUM(A.ThisAmt) / @AmtUnit END AS ThisAmt, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.ThisDomAmt) ELSE SUM(A.ThisDomAmt) / @AmtUnit END AS ThisDomAmt, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.PlanSumAmt) ELSE SUM(A.PlanSumAmt) / @AmtUnit END AS PlanSumAmt, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.PlanSumDomAmt) ELSE SUM(A.PlanSumDomAmt) / @AmtUnit END AS PlanSumDomAmt, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.ThisSumAmt) ELSE SUM(A.ThisSumAmt) / @AmtUnit END AS ThisSumAmt, 
               CASE WHEN @AmtUnit = 0 THEN SUM(A.ThisSumDomAmt) ELSE SUM(A.ThisSumDomAmt) / @AmtUnit END  AS ThisSumDomAmt, 
               CONVERT(DECIMAL(19,2),CASE WHEN SUM(A.PlanAmt) = 0 THEN 0 ELSE (SUM(A.ThisAmt)/SUM(A.PlanAmt)) * 100 END) AS ReceiptM, 
               CONVERT(DECIMAL(19,2),CASE WHEN SUM(A.PlanSumAmt) = 0 THEN 0 ELSE (SUM(A.ThisSumAmt)/SUM(A.PlanSumAmt)) * 100 END) AS ReceiptSum
               
          FROM #yw_TACSalesReceiptPlan AS A 
          LEFT OUTER JOIN _TDACust AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.CustSeq = A.CustSeq ) 
          LEFT OUTER JOIN _TDADept AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
          LEFT OUTER JOIN _TDACurr AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.CurrSeq = A.CurrSeq ) 
          LEFT OUTER JOIN _TDASMinor AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.SMInType ) 
          LEFT OUTER JOIN _TDASMinor AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND  A.SMLocalExp = F.MinorSeq ) 
         WHERE @SMLocalExp = 0 OR A.SMLocalExp = @SMLocalExp 
           AND DateYM = @QueryYM 
         GROUP BY A.SMLocalExp, A.CustSeq, A.DeptSeq, A.SMInType, A.CurrSeq, B.CustName, C.DeptName, E.MinorName, D.CurrName, F.MinorName
         HAVING SUM(A.PlanAmt) <> 0 OR SUM(A.ThisAmt) <> 0 
        END
    
    RETURN  
GO
exec yw_SACSalesReceiptPlanDiffListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <QueryYM>201512</QueryYM>
    <CustSeq />
    <DeptSeq />
    <SMLocalExp />
    <AmtUnit>0</AmtUnit>
    <CheckBox>1</CheckBox>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019964,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016833