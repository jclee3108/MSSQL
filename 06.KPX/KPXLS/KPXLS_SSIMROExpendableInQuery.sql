IF OBJECT_ID('KPXLS_SSIMROExpendableInQuery') IS NOT NULL 
    DROP PROC KPXLS_SSIMROExpendableInQuery
GO 

-- v2016.04.28 

-- KPXLS용 by이재천 
/************************************************************
  설  명 - MRO소모품입고조회-조회
  작성일 - 20141118
  작성자 - 전경만
 ************************************************************/
 CREATE PROC KPXLS_SSIMROExpendableInQuery
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
    @BizUnit        INT,
    @MROItemKind    NVARCHAR(100),
    @MROItemNo      NVARCHAR(100),
    @ItemNo         NVARCHAR(100),
    @ItemName       NVARCHAR(100),
    @PONo           NVARCHAR(100),
    @DelvNo         NVARCHAR(100),
    @DeptName       NVARCHAR(100),
    @EmpName        NVARCHAR(100)
    
    
  EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
  SELECT  @DelvDateFr     = ISNULL(DelvDateFr, ''),
    @DelvDateTo     = ISNULL(DelvDateTo, ''),
    @PODateFr       = ISNULL(PODateFr, ''),
    @PODateTo       = ISNULL(PODateTo, ''),
    @BizUnit        = ISNULL(BizUnit, 0),
    @MROItemKind    = ISNULL(MROItemKind, ''),
    @MROItemNo      = ISNULL(MROItemNo, ''),
    @ItemNo         = ISNULL(ItemNo, ''),
    @ItemName       = ISNULL(ItemName, ''),
    @PONo           = ISNULL(PONo, ''),
    @DelvNo         = ISNULL(DelvNo, ''),
    @DeptName       = ISNULL(DeptName, ''),
    @EmpName        = ISNULL(EmpName, '')
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
    WITH (
    DelvDateFr      NCHAR(8),
    DelvDateTo      NCHAR(8),
    PODateFr        NCHAR(8),
    PODateTo        NCHAR(8),
    BizUnit         INT,
    MROItemKind     NVARCHAR(100),
    MROItemNo       NVARCHAR(100),
    ItemNo          NVARCHAR(100),
    ItemName        NVARCHAR(100),
    PONo            NVARCHAR(100),
    DelvNo          NVARCHAR(100),
    DeptName        NVARCHAR(100),
    EmpName         NVARCHAR(100)
      )
     
     SELECT A.Serl,
			A.GRNo,
            CASE WHEN A.STATUS = 'C' THEN '신규'
                 WHEN A.Status = 'D' THEN '삭제' ELSE '' END    AS MROStatus,
            A.CompanySeq,
            A.PONo,
            A.DelvDate,
            A.PODate,
            A.ItemNo         AS MROItemNo,
            A.POSeq,
            A.DeptSeq,
            D.DeptName,
            T.AccSeq,
            T.AccNo, 
            T.AccName,
            --A.ItemName,
            --A.ItemSeq,
            A.POQty,
            A.DelvQty,
            A.Price,
            A.Price*0.1*A.DelvQty        AS VAT,
            A.Price*A.DelvQty            AS Amt,
            A.Price*A.DelvQty*1.1        AS TotAmt,
            A.CustName,
            --A.CustSeq,
            A.EmpName,
            A.EmpID,
            ISNULL(A.EmpSeq, P.EmpSeq) AS EmpSeq,
            ISNULL(E.EmpName, P.EmpName) AS EmpName,
            A.ORY_GR_ID          AS Ory_GrNo
        FROM KPX_TPUDelvItem_IF AS A WITH(NOLOCK)
            --LEFT OUTER JOIN _TDABizUnit      AS B WITH(NOLOCK) ON B.CompanySeq = A.CompanySeq
            --                                                  AND B.BizUnit = A.BizUnit
            LEFT OUTER JOIN _TDADept         AS D WITH(NOLOCK) ON D.CompanySeq = A.CompanySeq
                                                              AND D.DeptSeq = A.DeptSeq
            LEFT OUTER JOIN _TDAEmp          AS E WITH(NOLOCK) ON E.CompanySeq = A.CompanySeq
                                                              AND E.EmpSeq = A.EmpSeq
            LEFT OUTER JOIN _TDAAccount      AS T WITH(NOLOCK) ON T.CompanySeq = A.CompanySeq
                                                              AND T.AccNo = CONVERT(NVARCHAR(10),LEFT(A.AccSeq,7))
            LEFT OUTER JOIN _TDAEmp          AS P WITH(NOLOCK) ON P.CompanySeq = @CompanySeq
                                                              AND P.EmpId = A.EmpID                        
      WHERE A.CompanySeq = @CompanySeq
        AND (@DelvDateFr = '' OR A.DelvDate >= @DelvDateFr)
        AND (@DelvDateTo = '' OR A.DelvDate <= @DelvDateTo)
        AND (@PODateFr = '' OR A.PODate >= @PODateFr)
        AND (@PODateTo = '' OR A.PODate <= @PODateTo)
        AND (@MROItemKind = '')
        AND (@MROItemNo = '' OR A.ItemNo LIKE @MROItemNo + '%')
        AND (@PONo = '' OR A.PONo LIKE @PONo+'%')
        AND (@DelvNo = '' OR A.GRNo LIKE @DelvNo+'%')
        AND (@DeptName = '' OR D.DeptName LIKE @DeptName+'%')
        AND (@EmpName = '' OR ISNULL(E.EmpName, P.EmpName) LIKE @EmpName+'%')
        --AND A.ProcYN = '1'
        AND A.ItemSeq IS NULL
        --AND A.GRNO NOT IN (SELECT ORY_GR_ID FROM KPX_TPUDelvItem_IF WHERE STATUS = 'D')
 RETURN
GO


