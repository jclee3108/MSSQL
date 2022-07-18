
IF OBJECT_ID('KPX_SPRWkempVacAppGWQuery') IS NOT NULL 
    DROP PROC KPX_SPRWkempVacAppGWQuery 
GO 

-- v2014.12.10 

-- 휴가신청 전자결재SP by이재천 
CREATE PROC KPX_SPRWkempVacAppGWQuery                  
    @xmlDocument    NVARCHAR(MAX) ,              
    @xmlFlags       INT = 0,              
    @ServiceSeq     INT = 0,              
    @WorkingTag     NVARCHAR(10)= '',                    
    @CompanySeq     INT = 1,              
    @LanguageSeq    INT = 1,              
    @UserSeq        INT = 0,              
    @PgmSeq         INT = 0         
AS          
    
    DECLARE @docHandle  INT,  
            @EmpSeq     INT, 
            @VacSeq     INT
   
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument               
    
    SELECT @EmpSeq = EmpSeq, 
           @VacSeq = VacSeq    
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (
            EmpSeq     INT,
            VacSeq     INT
           )     
    
    SELECT A.EmpSeq, 
           C.EmpName, 
           A.WkItemSeq                           , --근태항목코드
           ISNULL(D.WkItemName, '') AS WkItemName, --근태항목
           A.VacSeq                              , --일련번호
           A.WkFrDate                            , --휴가시작일자
           A.WkToDate                            , --휴가종료일자
           A.PrevUseDays                         , --휴가일수
           A.AppDate                             , --신청일자
           A.VacReason                           , --휴가사유
           A.CrisisTel                           , --긴급연락처
           A.TelNo                               , --전화번호
           A.AccptEmpSeq                         , --인수자
           A.CCSeq                               , --경조사
           A.IsHalf                              , --반차여부
           A.IsEnd                               , --확정여부
           A.IsReturn                            , --반송여부
           A.ReturnReason                        , --반송사유
           A.TimeTerm AS TimeTerm,
           ISNULL(A.CCSeq,0) AS CCSeq,
           ISNULL((SELECT ConName FROM _THRWelCon WHERE CompanySeq = @CompanySeq AND ConSeq = A.CCSeq),'') AS CCName,
           CASE WHEN EXISTS(SELECT * FROM _TPRWkAppItem WHERE CompanySeq = @CompanySeq AND SMWkAppSeq = 3122003 AND WkItemSeq = A.WkItemSeq ) THEN '1' ELSE '0' END AS IsCC, 
           
           E.DeptSeq, 
           E.DeptName, 
           E.PosName, -- PosName 
           E.UMJpName, -- 직위

           F.ItemName + ' * ' + CONVERT(NVARCHAR(10),CONVERT(INT,B.Numerator)) + '/' + CONVERT(NVARCHAR(10),CONVERT(INT,B.Denominator)) AS StdCon, -- 기준   
           0 AS ConAmt  -- 경조금   
      FROM _TPRWkEmpVacApp              AS A 
      LEFT OUTER JOIN KPX_THRWelConAmt  AS B ON ( B.CompanySeq = @CompanySeq AND B.WkItemSeq = A.WKItemSEq AND B.ConSeq = A.CCSeq )
      LEFT OUTER JOIN _TDAEmp           AS C ON ( C.CompanySeq = @CompanySeq AND C.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TPRWkItem        AS D ON ( D.CompanySeq = @CompanySeq AND D.WkItemSeq = A.WkItemSeq ) 
      LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq, '') AS E ON ( E.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TPRBasPayItem    AS F ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = B.WkItemSeq )   
     WHERE A.CompanySeq = @CompanySeq 
       AND A.EmpSeq = @EmpSeq 
       AND A.VacSeq = @VacSeq 
    
    RETURN 
    