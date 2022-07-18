IF OBJECT_ID('KPXCM_SPRAccPaySlipProgCheck') IS NOT NULL 
    DROP PROC KPXCM_SPRAccPaySlipProgCheck
GO 
  
-- v2015.11.12   

-- 회계처리 체크 by이재천 
CREATE PROCEDURE KPXCM_SPRAccPaySlipProgCheck  
     @xmlDocument NVARCHAR(MAX)    ,    -- : 화면의 정보를 XML로 전달  
     @xmlFlags    INT = 0          ,    -- : 해당 XML의 Type  
     @ServiceSeq  INT = 0          ,    -- : 서비스 번호  
     @WorkingTag  NVARCHAR(10) = '',    -- : WorkingTag  
     @CompanySeq  INT = 1          ,    -- : 회사 번호  
     @LanguageSeq INT = 1          ,    -- : 언어 번호  
     @UserSeq     INT = 0          ,    -- : 사용자 번호  
     @PgmSeq      INT = 0               -- : 프로그램 번호  
AS  
    
    DECLARE @MessageType    INT,  
            @Status         INT,  
            @Results        NVARCHAR(250)   
      
    CREATE TABLE #TPRAccPaySlip( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPRAccPaySlip'   
    IF @@ERROR <> 0 RETURN     

    SELECT DISTINCT D.AccUnit -- 급상여처리 기본 회계단위
      INTO #PayResult 
      FROM _TPRPayResult                AS A 
      JOIN #TPRAccPaySlip               AS B ON ( B.PbYm = A.PbYm AND B.SerialNo = A.SerialNo ) 
      LEFT OUTER JOIN _THROrgDeptCCtr   AS C WITH(NOLOCK) ON A.CompanySeq = C.CompanySeq -- 부서에연결된 기본활동센터
                                                         AND A.DeptSeq = C.DeptSeq
                                                         AND C.BegYM <= A.PbYm 
                                                         AND C.EndYM >= A.PbYm 
                                                         AND NOT EXISTS (SELECT 1 
                                                                           FROM _TPRAccEmpRate 
                                                                          WHERE EmpSeq = A.EmpSeq 
                                                                            AND (ISNULL(EndYM,'999999') >= B.PbYM AND ISNULL(BegYM,'000000') <= B.PbYM) 
                                                                            AND EnvValue = 5518002
                                                                        )
      LEFT OUTER JOIN _TDACCtr          AS D ON ( D.CompanySeq = @CompanySeq AND D.CCtrSeq = C.CCtrSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND D.CCtrSeq IS NOT NULL 
    
    UNION -- 회계처리사원별활동센터적용률입력의 회계단위 
    
    SELECT DISTINCT D.AccUnit 
      FROM _TPRPayResult                AS A 
      JOIN #TPRAccPaySlip               AS B ON ( B.PbYm = A.PbYm AND B.SerialNo = A.SerialNo AND B.PuSeq = A.PbSeq ) 
      JOIN _TPRAccEmpRate               AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq AND C.EnvValue = B.EnvValue AND (ISNULL(C.EndYM,'999999') >= B.PbYM AND ISNULL(C.BegYM,'000000') <= B.PbYM) )
      LEFT OUTER JOIN _TDACCtr          AS D ON ( D.CompanySeq = @CompanySeq AND D.CCtrSeq = C.DtlSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
    
    --SELECT * FROM #PayResult 
    
    
    SELECT A.AccUnit, 
           C.AccUnitName 
      INTO #Error            
      FROM #PayResult AS A 
      LEFT OUTER JOIN (
                        SELECT DISTINCT B.AccUnit 
                          FROM #TPRAccPaySlip           AS Z 
                          JOIN _TPRAccPaySlip           AS A ON ( A.CompanySeq = @CompanySeq AND A.PbYm = Z.PbYm AND A.EnvValue = Z.EnvValue AND A.SerialNo = Z.SerialNo ) 
                          LEFT OUTER JOIN _TDACCtr      AS B ON ( B.CompanySeq = @CompanySeq AND B.CCtrSeq = A.DtlSeq ) 
                          LEFT OUTER JOIN #PayResult    AS C ON ( C.AccUnit = B.AccUnit ) 
                      ) AS B ON ( B.AccUnit = A.AccUnit ) 
      LEFT OUTER JOIN _TDAAccUnit AS C ON ( C.CompanySeq = @CompanySeq AND C.AccUnit = A.AccUnit ) 
     WHERE B.AccUnit IS NULL                       
    
    
    DECLARE @Message    NVARCHAR(MAX)
    
    SELECT @Message = REPLACE(REPLACE(REPLACE((SELECT A.AccUnitName from #Error AS A  FOR XML AUTO, ELEMENTS),'</AccUnitName></A><A><AccUnitName>',','),'<A><AccUnitName>',''),'</AccUnitName></A>','')
    
    IF EXISTS (SELECT 1 FROM #Error) 
    BEGIN 
        SELECT 1234 AS Status, 
               @Message + '이(가) 회계자료생성을 하지 않았습니다.' AS Result, 
               1234 AS MessageType 
    END 
    ELSE
    BEGIN
        SELECT 0 AS Status, '' AS Result, 0 AS MessageType 
    END 
        
    RETURN 
GO 
exec KPXCM_SPRAccPaySlipProgCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <EnvValue>5518002</EnvValue>
    <PuSeq>1</PuSeq>
    <PbYM>201509</PbYM>
    <SerialNo>1</SerialNo>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033142,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027461