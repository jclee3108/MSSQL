  
IF OBJECT_ID('KPX_SHRWelMediQuerySub') IS NOT NULL   
    DROP PROC KPX_SHRWelMediQuerySub  
GO  
  
-- v2014.12.02  
  
-- 의료비신청-Item조회 by 이재천   
CREATE PROC KPX_SHRWelMediQuerySub  
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
            @QYY            NCHAR(4),  
            @QEmpSeq        INT, 
            @QBaseDateFr    NCHAR(8), 
            @QBaseDateTo    NCHAR(8), 
            @QRegSeq        INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @QYY   = ISNULL( QYY, '' ),  
           @QEmpSeq  = ISNULL( QEmpSeq , '' ) , 
           @QBaseDateFr = ISNULL( QBaseDateFr, '' ), 
           @QBaseDateTo = ISNULL( QBaseDateTo, '' ), 
           @QRegSeq = ISNULL( QRegSeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock3', @xmlFlags )       
      WITH (
            QYY            NCHAR(4), 
            QEmpSeq        INT, 
            QBaseDateFr    NCHAR(8), 
            QBaseDateTo    NCHAR(8), 
            QRegSeq        INT
           )    
    
    
    IF @QBaseDateTo = '' SELECT @QBaseDateTo = '99991231'
    
    -- 최종조회   
    SELECT A.WelMediSeq, 
           B.CfmCode AS IsCfm, 
           A.YY, 
           A.BaseDate, 
           C.EmpAmt, 
           D.EmpName, 
           A.EmpSeq, 
           E.MediAmt, 
           E.NonPayAmt, 
           E.HEmpAmt, 
           E.MediAmt - E.NonPayAmt - C.EmpAmt AS ComAmt, 
           A.RegSeq, 
           C.RegName
           
      FROM KPX_THRWelMedi                       AS A 
      LEFT OUTER JOIN KPX_THRWelMedi_Confirm    AS B ON ( B.CompanySeq = @CompanySeq AND B.CfmSeq = A.WelMediSeq ) 
      LEFT OUTER JOIN KPX_THRWelCodeYearItem    AS C ON ( C.CompanySeq = @CompanySeq AND C.RegSeq = A.RegSeq ) 
      LEFT OUTER JOIN _TDAEmp                   AS D ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = A.EmpSeq ) 
      OUTER APPLY ( SELECT SUM(MediAmt) AS MediAmt, 
                           SUM(NonPayAmt) AS NonPayAmt, 
                           SUM(MediAmt) - SUM(NonPayAmt) AS HEmpAmt
                      FROM KPX_THRWelMediItem AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.WelMediSeq = A.WelMediSeq 
                  ) AS E 
      
      --JOIN KPX_THRWelMediItem   AS B ON ( A.CompanySeq = B.CompanySeq AND A.WelMediSeq = B.WelMediSeq )  
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @QYY = '' OR A.YY = @QYY )  
       AND ( @QEmpSeq = 0 OR A.EmpSeq = @QEmpSeq ) 
       AND ( A.BaseDate BETWEEN @QBaseDateFr AND @QBaseDateTo ) 
       AND ( @QRegSeq = 0 OR A.RegSeq = @QRegSeq ) 
    
    RETURN  
    GO 
    exec KPX_SHRWelMediQuerySub @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <QYY />
    <QEmpSeq />
    <QBaseDateFr />
    <QRegSeq />
    <QBaseDateTo />
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026386,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022105
    
