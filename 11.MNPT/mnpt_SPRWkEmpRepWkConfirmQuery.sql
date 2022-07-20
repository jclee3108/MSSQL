IF OBJECT_ID('mnpt_SPRWkEmpRepWkConfirmQuery') IS NOT NULL
    DROP PROC mnpt_SPRWkEmpRepWkConfirmQuery
GO 

-- v2018.01.23 
/************************************************************    
 설  명 - 데이터-대체근무신청확정-조회
 작성일 - 20110215
 작성자 - 안병국    
************************************************************/       
CREATE PROCEDURE mnpt_SPRWkEmpRepWkConfirmQuery    
    @xmlDocument    NVARCHAR(MAX),   -- : 화면의 정보를 xml로 전달  
    @xmlFlags       INT = 0,         -- : 해당 xml의 Type  
    @ServiceSeq     INT = 0,         -- : 서비스 번호  
    @WorkingTag     NVARCHAR(10)= '',-- : WorkingTag  
    @CompanySeq     INT = 1,         -- : 회사 번호  
    @LanguageSeq    INT = 1,         -- : 언어 번호  
    @UserSeq        INT = 0,         -- : 사용자 번호  
    @PgmSeq         INT = 0          -- : 프로그램 번호  
  
AS  
  
    DECLARE @docHandle         INT,  
            @EmpSeq            INT,
            @AppFrDate         NCHAR(8),   -- 신청기간fr  
            @AppToDate         NCHAR(8),   -- 신청기간to
            @WkItemSeq         INT     ,
            @DeptSeq           INT     ,
            @IsConfirm         NCHAR(1)    -- 확정포함여부
  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument        
  
    SELECT @EmpSeq         = ISNULL(EmpSeq, 0),    
           @AppFrDate      = ISNULL(AppFrDate, ''),    
           @AppToDate      = ISNULL(AppToDate, ''),  
           @WkItemSeq      = ISNULL(WkItemSeq, 0), 
           @DeptSeq        = ISNULL(DeptSeq, 0), 
           @IsConfirm       = ISNULL(IsConfirm, '0') 
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)       
      WITH (  EmpSeq          INT,
              AppFrDate       NCHAR(8),  
              AppToDate       NCHAR(8),  
              WkItemSeq       INT     ,
              DeptSeq         INT     ,
              IsConfirm       NCHAR(1)
            )     
  
   IF @AppFrDate = ''
      SELECT @AppFrDate = '19000101'
   IF @AppToDate = ''
      SELECT @AppToDate = '99991231'

   SELECT  A.EmpSeq
          ,A.RepWkSeq
          ,E.EmpName
          ,E.EmpID
          ,E.DeptName
          ,E.PosName
          ,A.WkItemSeq
          ,ISNULL(B.WkItemName,'')  AS WkItemName
          ,A.RepWkDate
          ,A.AppDate
          ,A.SMEndType
          ,ISNULL((SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMEndType),'') AS SMEndTypeName
          ,A.EndTime
          ,A.RepWkReason
          ,ISNULL(A.IsHalf,'0') AS IsHalf
          ,CASE WHEN ISNULL(C.CfmCode,0) = 1 THEN '1' ELSE '0' END AS ISConfirm
          -- 출근시간(StartTime) , 출근구분코드(SMStartType) , 출근구분(SMStartTypeName) 추가
          ,A.SMStartType
          ,ISNULL((SELECT MinorName FROM _TDASMinor WHERE CompanySeq = @CompanySeq AND MinorSeq = A.SMStartType),'') AS SMStartTypeName
          ,A.StartTime
          ,D.WkMoney 
          ,STUFF(F.BegTime,3,0,':') AS StartTimeSub 
          ,STUFF(F.EndTime,3,0,':') AS EndTimeSub
     FROM _TPRWkEmpRepWk AS A WITH(NOLOCK)
          LEFT OUTER JOIN _fnAdmEmpOrd(@CompanySeq,'') AS E
                          ON (A.EmpSeq = E.EmpSeq)  
          LEFT OUTER JOIN _TPRWkItem AS B WITH(NOLOCK) 
                          ON (A.CompanySeq = B.CompanySeq
                          AND A.WkItemSeq  = B.WkItemSeq)
          LEFT OUTER JOIN _TPRWkEmpRepWk_Confirm AS C WITH(NOLOCK)
                          ON (A.CompanySeq = C.CompanySeq
                          AND A.EmpSeq     = C.CfmSeq
                          AND A.RepWkSeq   = C.CfmSerl)          
          LEFT OUTER JOIN mnpt_TPREEWkEmpRepWk  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq 
                                                                   AND D.EmpSeq = A.EmpSeq 
                                                                   AND D.RepWkSeq = A.RepWkSeq 
                                                                     ) 
          OUTER APPLY ( 
                        SELECT MAX(Z.BegTime) AS BegTime, MAX(Z.EndTime) AS EndTime
                          FROM _TPRWkEmpWkDaily AS Z 
                         WHERE Z.CompanySeq = @CompanySeq 
                           AND Z.WkDate = A.RepWkDate 
                           AND Z.EmpSeq = A.EMpSeq 
                      )  AS F 

    WHERE A.CompanySeq = @CompanySeq
      AND (@EmpSeq    = 0 OR A.EmpSeq     = @EmpSeq)
      AND (@DeptSeq   = 0 OR E.DeptSeq    = @DeptSeq)
      AND (@WkItemSeq = 0 OR A.WkItemSeq  = @WkItemSeq)
      AND A.AppDate BETWEEN @AppFrDate AND @AppToDate      
      AND (@IsConfirm = '1' OR (@IsConfirm = '0' AND ISNULL(C.CfmCode,0) = 0 ))  
    ORDER BY E.DeptName, E.EmpID, A.AppDate 
    
    RETURN
go

begin tran 
exec mnpt_SPRWkEmpRepWkConfirmQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <AppFrDate />
    <AppToDate />
    <WkItemSeq />
    <DeptSeq />
    <EmpSeq />
    <IsConfirm>0</IsConfirm>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=13820136,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=167,@PgmSeq=13820125
rollback 