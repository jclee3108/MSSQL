IF OBJECT_ID('KPXCM_SPUORDPOReqPrintQuery') IS NOT NULL 
    DROP PROC KPXCM_SPUORDPOReqPrintQuery
GO 

-- v2015.10.06 

-- 포장단위 추가 by이재천 
 /************************************************************
  설  명 - 데이터-구매요청 : 구매요청서출력
  작성일 - 20091209
  작성자 - 이성덕
  수정일 - 20100331 UPDATEd BY 박소연 :: 구매요청 구분 추가
           20100331 UPDATEd BY 박소연 :: MEMO1/2/3/4/5/6 추가
           20110610 UPDATED BY 김세호 :: MasterRamrk, Remark '<' '＜ 으로 Replace 처리
 ************************************************************/
  CREATE PROC KPXCM_SPUORDPOReqPrintQuery  
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
   
 AS         
   CREATE TABLE #TPUORDPOReqItem (WorkingTag NCHAR(1) NULL)  
  EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPUORDPOReqItem'     
  IF @@ERROR <> 0 RETURN  
      --Query
     SELECT --Master
            Y.POReqSeq                                           , --구매요청내부코드
            Y.POReqSerl                                          , --구매요청순번
            X.POReqNo                                            , --구매요청번호
            X.ReqDate                                            , --구매요청일
            LTRIM(RTRIM(ISNULL(A.DeptName,'')))  AS DeptName     , --요청부서
            LTRIM(RTRIM(ISNULL(B.EmpName,'')))   AS EmpName      , --요청담당자
            REPLACE(LTRIM(RTRIM(ISNULL(X.Remark,''))),'<','＜')    AS MasterRemark , --비고(마스터)
            X.UMPOReqType                        AS UMPOReqType  , --구매요청구분내부코드 20100331 박소연 추가
            LTRIM(RTRIM(ISNULL(G.MinorName,''))) AS UMPOReqTypeName, --구매요청구분 20100331 박소연 추가
            
            --Detail
            LTRIM(RTRIM(ISNULL(H.PJTNo,'')))     AS PJTNo        , --프로젝트번호
            LTRIM(RTRIM(ISNULL(H.PJTName,'')))   AS PJTName      , --프로젝트명
            LTRIM(RTRIM(ISNULL(C.ItemName,'')))  AS ItemName     , --품명
            LTRIM(RTRIM(ISNULL(C.ItemNo,'')))    AS ItemNo       , --품번
            LTRIM(RTRIM(ISNULL(C.Spec,'')))      AS Spec         , --규격
            LTRIM(RTRIM(ISNULL(D.UnitName,'')))  AS UnitName     , --단위
            LTRIM(RTRIM(ISNULL(Y.DelvDate,'')))  AS DelvDate     , --납기요청일
            ISNULL(Y.Qty,0)                      AS Qty          , --요청수량
            LTRIM(RTRIM(ISNULL(E.CustName,''))) AS MakerName     , --Maker
            ISNULL(Y.Price,0)                    AS Price        , --단가
            CASE ISNULL(Y.CurAmt,0) WHEN 0 THEN Y.Price * Y.Qty ELSE Y.CurAmt END AS CurAmt  , --금액
            ISNULL(Y.CurVat,0)                   AS CurVat       , --부가세
            LTRIM(RTRIM(ISNULL(F.CurrName,'')))  AS CurrName     , --통화
            LTRIM(RTRIM(ISNULL(F.CurrUnit,'')))  AS CurrUnit     , --통화표시
            Y.ExRate                                             , --환율
            REPLACE(LTRIM(RTRIM(ISNULL(Y.Remark,''))),'<','＜') AS Remark,     --비고(디테일)          
            ISNULL(H.PJTName,'')     AS PJTName  ,
            ISNULL(H.PJTNo,'')     AS PJTNo  ,
            ISNULL(Y.Memo1,'')                   AS Memo1        , -- 20100408 박소연 추가
            ISNULL(Y.Memo2,'')                   AS Memo2        , -- 20100408 박소연 추가
            ISNULL(Y.Memo3,'')                   AS Memo3        , -- 20100408 박소연 추가
            ISNULL(Y.Memo4,'')                   AS Memo4        , -- 20100408 박소연 추가
            ISNULL(Y.Memo5,'')                   AS Memo5        , -- 20100408 박소연 추가
            ISNULL(Y.Memo6,'')                   AS Memo6        , -- 20100408 박소연 추가
            (ROW_NUMBER() OVER(ORDER BY Y.POReqSerl)) AS Serl,      -- 20101020 전자결재 순번 출력 위해 추가 hkim
            I.MinorName AS Memo5Name 
       FROM #TPUORDPOReqItem                 AS Z    --출력은 입력받은 값 기준, 하나 이상 건에 대해서 조회 가능하도록 임시테이블 사용
                       JOIN _TPUORDPOReq     AS X WITH(NOLOCK) ON X.CompanySeq   = @CompanySeq
                                                              AND X.POReqSeq     = Z.POReqSeq
                       JOIN _TPUORDPOReqItem AS Y WITH(NOLOCK) ON Y.CompanySeq   = X.CompanySeq
                                AND Y.POReqSeq     = X.POReqSeq 
            LEFT OUTER JOIN _TDADept         AS A WITH(NOLOCK) ON A.CompanySeq   = X.CompanySeq 
                                                              AND A.DeptSeq      = X.DeptSeq  
            LEFT OUTER JOIN _TDAEmp          AS B WITH(NOLOCK) ON B.CompanySeq   = X.CompanySeq 
                                                              AND B.EmpSeq       = X.EmpSeq  
            LEFT OUTER JOIN _TDAItem         AS C WITH(NOLOCK) ON C.CompanySeq   = Y.CompanySeq 
                                                              AND C.ItemSeq      = Y.ItemSeq  
            LEFT OUTER JOIN _TDAUnit         AS D WITH(NOLOCK) ON D.CompanySeq   = Y.CompanySeq 
                                                              AND D.UnitSeq      = Y.UnitSeq  
            LEFT OUTER JOIN _TDACust         AS E WITH(NOLOCK) ON E.CompanySeq   = Y.CompanySeq 
                                                              AND E.CustSeq      = Y.MakerSeq
            LEFT OUTER JOIN _TDACurr         AS F WITH(NOLOCK) ON F.CompanySeq   = Y.CompanySeq 
                                                              AND F.CurrSeq      = Y.CurrSeq
            LEFT OUTER JOIN _TDAUMinor       AS G WITH(NOLOCK) ON G.CompanySeq   = X.CompanySeq  -- 20100331 박소연 추가
                                                              AND G.MinorSeq     = X.UMPOReqType 
            LEFT OUTER JOIN _TPJTProject     AS H WITH(NOLOCK) ON X.Companyseq   = H.CompanySeq 
                                                              AND Y.PJTSeq       = H.PJTSeq 
            LEFT OUTER JOIN _TDAUMinor       AS I WITH(NOLOCK) ON ( I.CompanySeq = @CompanySeq AND I.MinorSeq = Y.Memo5 ) 
      WHERE X.CompanySeq = @CompanySeq
   ORDER BY Y.POReqSeq, Y.POReqSerl
  
 RETURN  
  go 
  begin tran 
  
  EXEC _SCOMGroupWarePrint 2, 1, 1, 1026397, 'BizTrip_CM', '1', ''
  
  rollback 