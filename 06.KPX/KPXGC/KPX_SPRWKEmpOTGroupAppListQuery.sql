
IF OBJECT_ID('KPX_SPRWKEmpOTGroupAppListQuery') IS NOT NULL 
    DROP PROC KPX_SPRWKEmpOTGroupAppListQuery
GO 

-- v2014.12.17    
    
-- OT일괄신청- 리스트 조회 by 이재천     
CREATE PROC KPX_SPRWKEmpOTGroupAppListQuery    
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
    
    DECLARE @docHandle      INT,    
            -- 조회조건     
            @BaseDateFr     NCHAR(8), 
            @BaseDateTo     NCHAR(8) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
        
    SELECT @BaseDateFr   = ISNULL( BaseDateFr, '' ), 
           @BaseDateTo   = ISNULL( BaseDateTo, '' ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock3', @xmlFlags )         
      WITH (
            BaseDateFr     NCHAR(8),
            BaseDateTo     NCHAR(8) 
           )      
    
    IF @BaseDateTo = '' SELECT @BaseDateTo = '99991231' 
    
    -- 최종조회     
    SELECT ISNULL(D.CfmCode,'0') AS IsCfm, 
           A.GroupAppSeq, 
           A.GroupAppNo, 
           A.BaseDate, -- 집계일자 
           C.EmpName + '외 ' + CONVERT(NVARCHAR(10),B.Cnt) + '명' AS EmpName, -- 사원 외 o명
           B.MINWkDate AS WkDateFr, -- 근무일자(From)
           B.MAXWkDate AS WkDateTo -- 근무일자(To)
      FROM KPX_TPRWKEmpOTGroupApp               AS A 
      OUTER APPLY (SELECT MIN(Z.EmpSeq) AS EmpSeq, COUNT(1) - 1 AS Cnt, MIN(Y.WkDate) AS MINWkDate, MAX(Y.WkDate) AS MAXWkDate 
                     FROM KPX_TPRWKEmpOTGroupAppEmp     AS Z 
                     LEFT OUTER JOIN _TPRWkEmpOTTimeDtl AS Y ON ( Y.CompanySeq = @CompanySeq AND Y.EmpSeq = Z.EmpSeq AND Y.AppSeq = Z.AppSeq ) 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.GroupAppSeq = A.GroupAppSeq 
                  ) AS B
      LEFT OUTER JOIN _TDAEmp                   AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = B.EmpSeq ) 
      LEFT OUTER JOIN KPX_TPRWKEmpOTGroupApp_Confirm AS D ON ( D.CompanySeq = @CompanySeq AND D.CfmSeq = A.GroupAppSeq ) 
     WHERE A.CompanySeq = @CompanySeq    
       AND A.BaseDate BETWEEN @BaseDateFr AND @BaseDateTo 
    
    RETURN    
GO 
exec KPX_SPRWKEmpOTGroupAppListQuery @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BaseDateFr>20141201</BaseDateFr>
    <BaseDateTo>20141217</BaseDateTo>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026866,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022469