     
IF OBJECT_ID('mnpt_SPJTEERentToolContractQuery') IS NOT NULL       
    DROP PROC mnpt_SPJTEERentToolContractQuery      
GO      
      
-- v2017.11.21
      
-- 외부장비임차계약입력-SS1조회 by 이재천
CREATE PROC mnpt_SPJTEERentToolContractQuery      
    @ServiceSeq     INT = 0,         
    @WorkingTag     NVARCHAR(10)= '',        
    @CompanySeq     INT = 1,        
    @LanguageSeq    INT = 1,        
    @UserSeq        INT = 0,        
    @PgmSeq         INT = 0,    
    @IsTransaction  BIT = 0      
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

    DECLARE @FrContractDate NCHAR(8), 
            @ToContractDate NCHAR(8), 
            @BizUnit        INT, 
            @DeptSeq        INT
      
    SELECT @FrContractDate   = ISNULL( FrContractDate, '' ),   
           @ToContractDate   = ISNULL( ToContractDate, '' ), 
           @BizUnit          = ISNULL( BizUnit, 0 ), 
           @DeptSeq          = ISNULL( DeptSeq, 0 ) 
      FROM #BIZ_IN_DataBlock1    
    
    IF @ToContractDate = '' SELECT @ToContractDate = '99991231'
    
    -- SS2 의 임차구분이 장비데이터
    SELECT A.ContractSeq, D.EquipmentSName AS RentToolName, B.Qty, C.MinorName AS UMRentTypeName, B.TotalAmt, B.Cnt 
      INTO #RentToolInfo
      FROM mnpt_TPJTEERentToolContractItem  AS A 
      JOIN ( 
            SELECT ContractSeq, MIN(ContractSerl) AS ContractSerl , SUM(Qty) AS Qty, SUM(Amt) AS TotalAmt, COUNT(1) AS Cnt 
              FROM mnpt_TPJTEERentToolContractItem 
             WHERE CompanySeq = @CompanySeq 
               AND UMRentKind = 1016351001 
             GROUP BY ContractSeq
           ) AS B ON ( B.ContractSeq = A.ContractSeq AND B.ContractSerl = A.ContractSerl ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMRentType ) 
      LEFT OUTER JOIN mnpt_TPDEquipment AS D ON ( D.CompanySeq = @CompanySeq AND D.EquipmentSeq = A.RentToolSeq ) 
    
    -- SS2 의 임차구분이 운전원데이터
    SELECT A.ContractSeq, B.Qty, C.MinorName AS UMRentTypeName, B.TotalAmt
      INTO #ManInfo
      FROM mnpt_TPJTEERentToolContractItem  AS A 
      JOIN ( 
            SELECT ContractSeq, MIN(ContractSerl) AS ContractSerl , SUM(Qty) AS Qty, SUM(Amt) AS TotalAmt 
              FROM mnpt_TPJTEERentToolContractItem 
             WHERE CompanySeq = @CompanySeq 
               AND UMRentKind = 1016351002 
             GROUP BY ContractSeq
           ) AS B ON ( B.ContractSeq = A.ContractSeq AND B.ContractSerl = A.ContractSerl ) 
      LEFT OUTER JOIN _TDAUMinor        AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = A.UMRentType ) 
    

    -- 최종조회
    SELECT A.ContractSeq, -- 내부코드 
           A.BizUnit, -- 사업부문코드 
           B.BizUnitName, -- 사업부문 
           A.ContractDate, -- 계약일 
           A.ContractNo, -- 계약번호 
           A.RentCustSeq, -- 임차업체코드 
           C.CustName AS RentCustName, --임차업체 
           A.RentSrtDate, -- 임차시작일 
           A.RentEndDate, -- 임차종료일 
           
           F.RentToolName + CASE WHEN F.Cnt > 1 THEN ' 외 ' + CONVERT(NVARCHAR(10),F.Cnt-1) + '건' ELSE '' END AS ToolName, -- 장비임차 장비 
           F.Qty AS ToolCnt,  -- 장비임차 댓수
           F.UMRentTypeName AS ToolUMToolTypeName, -- 장비임차 형태
           F.TotalAmt AS ToolAmt, -- 장비임차 임차금액
           G.Qty AS ManCnt, -- 운전원임차 인원 
           G.UMRentTypeName AS ManUMToolTypeName, -- 운전원임차 형태
           G.TotalAmt AS ManAmt, -- 운전원임차 임차금액 
           ISNULL(F.TotalAmt,0) + ISNULL(G.TotalAmt,0) AS TotalAmt, -- 총금액 
           A.EmpSeq, -- 담당자코드 
           D.EmpName, -- 담당자 
           A.DeptSeq, -- 담당부서코드 
           E.DeptName, -- 담당부서 
           A.Remark -- 비고 

      FROM mnpt_TPJTEERentToolContract  AS A   
      LEFT OUTER JOIN _TDABizUnit       AS B ON ( B.CompanySeq = @CompanySeq AND B.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDACust          AS C ON ( C.CompanySeq = @CompanySeq AND C.CustSeq = A.RentCustSeq ) 
      LEFT OUTER JOIN _TDAEmp           AS D ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept          AS E ON ( E.CompanySeq = @CompanySeq AND E.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN #RentToolInfo     AS F ON ( F.ContractSeq = A.ContractSeq ) 
      LEFT OUTER JOIN #ManInfo          AS G ON ( G.ContractSeq = A.ContractSeq ) 
     WHERE A.CompanySeq = @CompanySeq   
       AND A.ContractDate BETWEEN @FrContractDate AND @ToContractDate 
       AND (@BizUnit = 0 OR A.BizUnit = @BizUnit) 
       AND (@DeptSEq = 0 OR A.DeptSeq = @DeptSeq)
     ORDER BY BizUnit, ContractDate 
    
    RETURN     
    

    go
