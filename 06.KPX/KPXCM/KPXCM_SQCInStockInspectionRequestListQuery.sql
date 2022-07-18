IF OBJECT_ID('KPXCM_SQCInStockInspectionRequestListQuery') IS NOT NULL 
    DROP PROC KPXCM_SQCInStockInspectionRequestListQuery
GO 

-- v2016.06.02 
/************************************************************
 설  명 - 데이터-재고검사의뢰조회 : 조회
 작성일 - 20141203
 작성자 - 오정환
 수정자 - 
************************************************************/

CREATE PROC KPXCM_SQCInStockInspectionRequestListQuery
    @xmlDocument   NVARCHAR(MAX) ,            
    @xmlFlags      INT = 0,            
    @ServiceSeq    INT = 0,            
    @WorkingTag    NVARCHAR(10)= '',                  
    @CompanySeq    INT = 1,            
    @LanguageSeq   INT = 1,            
    @UserSeq       INT = 0,            
    @PgmSeq        INT = 0       

AS        
    

    DECLARE @docHandle     INT,
            @ItemNo        NVARCHAR(100) ,
            @ReqDateTo     NCHAR(8) ,
            @ItemName      NVARCHAR(100) ,
            @ReqDateFr     NCHAR(8) ,
            @BizUnit       INT ,
            @LotNo         NVARCHAR(100) ,
            @ReqNo         NVARCHAR(100) ,
            @DeptSeq       INT ,
            @EmpSeq        INT ,
            @QCGubnSeq     INT 
 
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument             

    SELECT @ItemNo        = ISNULL(ItemNo   , '')      ,
           @ReqDateTo     = ISNULL(ReqDateTo, '')      ,
           @ItemName      = ISNULL(ItemName , '')      ,
           @ReqDateFr     = ISNULL(ReqDateFr, '')      ,
           @BizUnit       = ISNULL(BizUnit  ,  0)      ,
           @LotNo         = ISNULL(LotNo    , '')      ,
           @ReqNo         = ISNULL(ReqNo    , '')      ,
           @DeptSeq       = ISNULL(DeptSeq  ,  0)      ,
           @EmpSeq        = ISNULL(EmpSeq   ,  0)      ,
           @QCGubnSeq     = ISNULL(QCGubnSeq,  0)      
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags) WITH (ItemNo         NVARCHAR(100) ,
                                                                     ReqDateTo      NCHAR(8) ,
                                                                     ItemName       NVARCHAR(100) ,
                                                                     ReqDateFr      NCHAR(8) ,
                                                                     BizUnit        INT ,
                                                                     LotNo          NVARCHAR(100) ,
                                                                     ReqNo          NVARCHAR(100) ,
                                                                     DeptSeq        INT ,
                                                                     EmpSeq         INT ,
                                                                     QCGubnSeq      INT
                                                                    )


    IF @ReqDateTo = ''
        SELECT @ReqDateTo = '9991231'


    SELECT A.ReqSeq                             ,   -- 요청코드
           A.ReqSerl                            ,   -- 요청순번
           CASE WHEN ISNULL(R.SMTestResult, 0) = 0 THEN '미검사'
                ELSE  R2.MinorName
            END           AS QCGubnName	        ,   -- 검사구분
           ISNULL(CASE WHEN R.SMTestResult = 0 THEN 1010418004
                       ELSE R.SMTestResult END, 1010418004) AS QCGubnSeq          ,   -- 검사구분코드
           B.BizUnitName                        ,   -- 사업부문
           M.BizUnit                            ,   -- 사업부문코드
           M.ReqNo                              ,   -- 검사의뢰번호
           M.ReqDate                            ,   -- 검사의뢰일
           D.DeptName                           ,   -- 검사의뢰부서
           M.DeptSeq                            ,   -- 검사의뢰부서코드
           E.EmpName                            ,   -- 검사의뢰자
           E.EmpSeq                             ,   -- 검사의뢰자코드
           Q.QCTypeName                         ,   -- 검사공정
           A.QCType                             ,   -- 검사공정코드
           I.ItemName                           ,   -- 품명
           I.ItemNo                             ,   -- 품번
           I.Spec                               ,   -- 규격
           A.ItemSeq                            ,   -- 품목코드
           A.LotNo                              ,   -- LotNo
           W.WHName                             ,   -- 창고
           A.WHSeq                              ,   -- 창고코드
           A.ReqQty                             ,   -- 검사의뢰수량
           U.UnitName                           ,   -- 단위
           A.UnitSeq                            ,   -- 단위코드
           L.CreateDate                         ,   -- 제조일자
           L.RegDate                            ,   -- 입고일자
           C.CustName       AS SupplyCustName   ,   -- 납품거래처
           L.SupplyCustSeq                      ,   -- 납품거래처코드
           A.Remark                             ,   -- 비고
           R.QCSeq                              ,    -- 검사등록내부코드
           A.Memo1                                  -- LotNo2 


      FROM KPX_TQCTestRequest       M JOIN KPX_TQCTestRequestItem           AS A WITH(NOLOCK) ON M.CompanySeq   = A.CompanySeq
                                                                                             AND M.ReqSeq       = A.ReqSeq
                           LEFT OUTER JOIN KPX_TQCQAProcessQCType           AS Q WITH(NOLOCK) ON Q.CompanySeq = A.CompanySeq
                                                                                             AND Q.QCType = A.QCType
                           LEFT OUTER JOIN _TDAItem                         AS I WITH(NOLOCK) ON I.CompanySeq = A.CompanySeq
                                                                                             AND I.ItemSeq = A.ItemSeq
                           LEFT OUTER JOIN _TDAWH                           AS W WITH(NOLOCK) ON W.CompanySeq = A.CompanySeq
                                                                                             AND W.WHSeq = A.WHSeq
                           LEFT OUTER JOIN _TDAUnit                         AS U WITH(NOLOCK) ON U.CompanySeq = A.CompanySeq
                                                                                             AND U.UnitSeq = A.UnitSeq
                           LEFT OUTER JOIN _TLGLotMaster                    AS L WITH(NOLOCK) ON L.CompanySeq = A.CompanySeq
                                                                                             AND L.ItemSeq = A.ItemSeq
                                                                                             AND L.LotNo = A.LotNo
                           LEFT OUTER JOIN _TDACust                         AS C WITH(NOLOCK) ON C.CompanySeq = L.CompanySeq
                                                                                             AND C.CustSeq = L.SupplyCustSeq
                           LEFT OUTER JOIN _TDABizUnit                      AS B WITH(NOLOCK) ON B.CompanySeq = W.CompanySeq
                                                                                             AND B.BizUnit = W.BizUnit
                           LEFT OUTER JOIN _TDADept                         AS D WITH(NOLOCK) ON D.CompanySeq = M.CompanySeq
                                                                                             AND D.DeptSeq = M.DeptSeq
                           LEFT OUTER JOIN _TDAEmp                          AS E WITH(NOLOCK) ON E.CompanySeq = M.CompanySeq
                                                                                             AND E.EmpSeq = M.EmpSeq
                           LEFT OUTER JOIN KPX_TQCTestResult                AS R WITH(NOLOCK) ON R.CompanySeq = M.CompanySeq
                                                                                             AND R.ReqSeq   = A.ReqSeq
                                                                                             AND R.ReqSerl  = A.ReqSerl
                           LEFT OUTER JOIN _TDAUMinor                      AS R2 WITH(NOLOCK) ON A.CompanySeq   = R2.CompanySeq
                                 AND R.SMTestResult = R2.MinorSeq
                    
 
     WHERE 1=1
       AND A.CompanySeq = @CompanySeq
       AND (@BizUnit   = '' OR M.BizUnit = @BizUnit)
       AND M.ReqDate BETWEEN @ReqDateFr AND @ReqDateTo
       AND (@ReqNo     = '' OR M.ReqNo    LIKE @ReqNo + '%')
       AND (@LotNo     = '' OR A.LotNo    LIKE @LotNo + '%')
       AND (@DeptSeq   = '' OR M.DeptSeq  = @DeptSeq)
       AND (@EmpSeq    = '' OR M.EmpSeq   = @EmpSeq)
       AND (@ItemName  = '' OR I.ItemName LIKE @ItemName + '%')
       AND (@ItemNo    = '' OR I.ItemNo   LIKE @ItemNo   + '%')
       AND A.SMSourceType = 1000522001  -- 재고검사
       AND (@QCGubnSeq    = 0 OR ISNULL(CASE WHEN R.SMTestResult = 0 THEN 1010418004
                                             ELSE R.SMTestResult END, 1010418004)   = @QCGubnSeq)

--select @QCGubnseq
    
RETURN

GO


exec KPXCM_SQCInStockInspectionRequestListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <BizUnit />
    <ReqDateFr>20160601</ReqDateFr>
    <ReqDateTo>20160602</ReqDateTo>
    <ReqNo />
    <LotNo />
    <DeptSeq />
    <EmpSeq />
    <ItemName />
    <ItemNo />
    <QCGubnSeq />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037328,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030570