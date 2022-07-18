  
IF OBJECT_ID('KPX_SHRWelMediSlipCCtrQuery') IS NOT NULL   
    DROP PROC KPX_SHRWelMediSlipCCtrQuery  
GO  
  
-- v2014.12.10  
  
-- 의료비회계처리(활동센터)-조회 by 이재천   
CREATE PROC KPX_SHRWelMediSlipCCtrQuery  
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
    
    DECLARE @docHandle  INT  ,      
            @AccUnit    INT,  
            @YY         NCHAR(4),    
            @RegSeq     INT, 
            @DeptSeq    INT, 
            @EmpSeq     INT, 
            @EnvValue   INT,            -- 원가구분   
            @SMSlipProc INT,            -- 전표처리여부  
            @MAXYM      NCHAR(6)
                 
     
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument          
     
    SELECT @AccUnit    = ISNULL(AccUnit   ,0),  
           @YY         = ISNULL(YY        ,''), 
           @RegSeq     = ISNULL(RegSeq    ,0), 
           @DeptSeq    = ISNULL(DeptSeq   ,0), 
           @EmpSeq     = ISNULL(EmpSeq    , 0), 
           @EnvValue   = ISNULL(EnvValue  , 0), 
           @SMSlipProc = ISNULL(SMSlipProc, 0) 
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1',@xmlFlags)         
      WITH ( 
             AccUnit    INT,  
             YY         NCHAR(4),
             RegSeq     INT, 
             DeptSeq    INT, 
             EmpSeq     INT, 
             EnvValue   INT, 
             SMSlipProc INT 
           )          
    
    SELECT @MAXYM = (SELECT MAX(YM) FROM _TPRAccGroup WHERE CompanySeq = @CompanySeq AND EnvValue = @EnvValue)
    
    -- 최종조회   
    SELECT 
           A.WelMediSeq AS Seq, 
           B.SlipID, 
           A.EmpSeq, 
           C.EmpName, 
           C.EmpID, 
           C.DeptSeq, 
           C.DeptName, 
           C.PosName, 
           C.UMJpName, -- 직위
           F.MinorSeq AS UMWelFareType, 
           O.MinorName AS UMWelFareTypeName, 
           A.YY, 
           D.RegSeq, 
           D.RegName, 
           A.ComAmt AS CompanyAmt, 
           
           J.AccSeq, 
           K.AccName AS AccName, 
           J.UMCostType, 
           L.MinorName AS UMCostTypeName, 
           J.OppAccSeq, 
           M.AccName AS OppAccName, 
           
           
           I.CCtrSeq AS SlipCCtrSeq, 
           I.CCtrName AS SlipCCtrName
           
      FROM KPX_THRWelMedi AS A 
      LEFT OUTER JOIN _TACSlipRow AS B ON ( B.CompanySeq = @CompanySeq AND B.SlipSeq = A.SlipSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS C ON ( C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN KPX_THRWelCodeYearItem        AS D ON ( D.CompanySeq = @CompanySeq AND D.RegSeq = A.RegSeq ) 
      LEFT OUTER JOIN KPX_THRWelCode                AS E ON ( E.CompanySeq = @CompanySeq AND E.WelCodeSeq = D.WelCodeSeq ) 
      OUTER APPLY (SELECT TOP 1 MinorSeq 
                     FROM _TDAUMinorValue AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.MajorSeq = 3004 
                      AND Z.Serl = 1001 
                      AND Z.ValueSeq = E.WelFareKind
                  ) AS F 
      --LEFT OUTER JOIN _TDAUMinorValue               AS F ON ( F.CompanySeq = @CompanySeq AND F.MajorSeq = 3004 AND F.Serl = 1001 AND F.ValueSeq = E.WelFareKind ) 
      LEFT OUTER JOIN _TDAUMinor                    AS O ON ( O.CompanySeq = @CompanySeq AND O.MinorSeq = F.MinorSeq ) 
      OUTER APPLY ( SELECT TOP 1 GroupSeq
                      FROM _TPRAccGroup AS Z 
                     WHERE Z.CompanySeq = @CompanySeq 
                       AND Z.CostDeptSeq = C.DeptSeq 
                       AND Z.YM = @MAXYM 
                       AND Z.EnvValue = @EnvValue 
                       AND Z.IsUse = '1'
                  ) AS G 
      LEFT OUTER JOIN _TPRAccGroupDtl               AS H ON ( H.CompanySeq = @CompanySeq AND H.EnvValue = @EnvValue AND H.GroupSeq = G.GroupSeq ) 
      LEFT OUTER JOIN _TDACCtr                      AS I ON ( I.CompanySeq = @CompanySeq AND H.DtlSeq = I.CCtrSeq ) 
      LEFT OUTER JOIN KPX_THRWelmediAccCCtr         AS J ON ( J.CompanySeq = @CompanySeq AND J.YM = @MAXYM AND J.GroupSeq = G.GroupSeq AND J.WelCodeSeq = E.WelCodeSeq ) 
      LEFT OUTER JOIN _TDAAccount                   AS K ON ( K.CompanySeq = @CompanySeq AND K.AccSeq = J.AccSeq ) 
      LEFT OUTER JOIN _TDAUMinor                    AS L ON ( L.CompanySeq = @CompanySeq AND L.MinorSeq = J.UMCostType ) 
      LEFT OUTER JOIN _TDAAccount                   AS M ON ( M.CompanySeq = @CompanySeq AND M.AccSeq = J.OppAccSeq ) 
                 JOIN _TDADept                      AS N ON ( N.CompanySeq = @CompanySeq AND N.DeptSeq = C.DeptSeq AND N.AccUnit = @AccUnit )  
     WHERE (@SMSlipProc = 0 OR (@SMSlipProc = 1039001 AND ISNULL(A.SlipSeq,0) <> 0 )    
                            OR (@SMSlipProc = 1039002 AND ISNULL(A.SlipSeq,0) =  0 )     
            )          
       AND (@YY = '' OR A.YY = @YY)
       AND (@RegSeq = 0 OR D.RegSeq = @RegSeq)
       AND (@DeptSeq = 0 OR C.DeptSeq = @DeptSeq) 
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq) 
    
    RETURN  
GO 
exec KPX_SHRWelMediSlipCCtrQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <EnvValue>5518002</EnvValue>
    <AccUnit>1</AccUnit>
    <RegSeq />
    <SMSlipProc />
    <YY>2014</YY>
    <DeptSeq />
    <EmpSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026643,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022308