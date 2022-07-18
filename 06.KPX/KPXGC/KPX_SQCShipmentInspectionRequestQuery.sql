  
IF OBJECT_ID('KPX_SQCShipmentInspectionRequestQuery') IS NOT NULL   
    DROP PROC KPX_SQCShipmentInspectionRequestQuery  
GO  
  
-- v2014.12.11  
  
-- 출하검사의뢰(탱크로리)-조회 by 이재천   
CREATE PROC KPX_SQCShipmentInspectionRequestQuery  
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
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @ReqDateFr  NCHAR(8), 
            @ReqDateTo  NCHAR(8), 
            @ReqNo      NVARCHAR(100), 
            @EmpName    NVARCHAR(100), 
            @DeptName   NVARCHAR(100), 
            @CustName   NVARCHAR(100), 
            @ItemName   NVARCHAR(100), 
            @ItemNo     NVARCHAR(100), 
            @LotNo      NVARCHAR(100)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ReqDateFr   = ISNULL( ReqDateFr, '' ),  
           @ReqDateTo   = ISNULL( ReqDateTo, '' ),  
           @ReqNo       = ISNULL( ReqNo    , '' ),  
           @EmpName     = ISNULL( EmpName  , '' ),  
           @DeptName    = ISNULL( DeptName , '' ),  
           @CustName    = ISNULL( CustName , '' ),  
           @ItemName    = ISNULL( ItemName , '' ),  
           @ItemNo      = ISNULL( ItemNo   , '' ),  
           @LotNo       = ISNULL( LotNo    , '' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
                ReqDateFr  NCHAR(8), 
                ReqDateTo  NCHAR(8), 
                ReqNo      NVARCHAR(100),
                EmpName    NVARCHAR(100),
                DeptName   NVARCHAR(100),
                CustName   NVARCHAR(100),
                ItemName   NVARCHAR(100),
                ItemNo     NVARCHAR(100),
                LotNo      NVARCHAR(100)
           )    
    
    IF @ReqDateTo = '' SELECT @ReqDateTo = '99991231'
    
    -- 최종조회   
    SELECT A.ReqSeq, 
           A.ReqDate, 
           A.ReqNo, 
           A.QCType, 
           F.QCTypeName, 
           A.ItemSeq, 
           E.ItemName, 
           E.ItemNo, 
           E.Spec, 
           A.LotNo, 
           A.Qty, 
           A.UnitSeq, 
           G.UnitName, 
           A.CustSeq, 
           D.CustName, 
           A.EmpSeq, 
           B.EmpName, 
           A.DeptSeq, 
           C.DeptName 
           
      FROM KPX_TQCShipmentInspectionRequest     AS A 
      LEFT OUTER JOIN _TDAEmp                   AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept                  AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDACust                  AS D ON ( D.CompanySeq = @CompanySeq AND D.CustSeq = A.CustSeq ) 
      LEFT OUTER JOIN _TDAItem                  AS E ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCType    AS F ON ( F.CompanySeq = @CompanySeq AND F.QCType = A.QCType ) 
      LEFT OUTER JOIN _TDAUnit                  AS G ON ( G.CompanySeq = @COmpanySeq AND G.UnitSeq = A.UnitSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.ReqDate BETWEEN @ReqDateFr AND @ReqDateTo 
       AND (@ReqNo = '' OR A.ReqNo LIKE @ReqNo + '%')       
       AND (@EmpName = '' OR B.EmpName LIKE @EmpName + '%')       
       AND (@DeptName = '' OR C.DeptName LIKE @DeptName + '%')       
       AND (@CustName = '' OR D.CustName LIKE @CustName + '%')       
       AND (@ItemName = '' OR E.ItemName LIKE @ItemName + '%')       
       AND (@ItemNo = '' OR E.ItemNo LIKE @ItemNo + '%')       
       AND (@LotNo = '' OR A.LotNo LIKE @LotNo + '%')       
      
    RETURN  