  
IF OBJECT_ID('KPXCM_SEQYearRepairPeriodRegCHEListQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairPeriodRegCHEListQuery  
GO  
  
-- v2015.07.13  
  
-- 연차보수기간등록-현황조회 by 이재천   
CREATE PROC KPXCM_SEQYearRepairPeriodRegCHEListQuery  
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
            @Amd            INT, 
            @EmpName        NVARCHAR(100), 
            @RepairYear     NCHAR(4), 
            @DeptName       NVARCHAR(100), 
            @RepairToDate   NCHAR(8), 
            @ReceiptFrDate  NCHAR(8), 
            @RepairFrDate   NCHAR(8), 
            @ReceiptToDate  NCHAR(8), 
            @FactUnit       INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @Amd            = ISNULL( Amd          , 0 ), 
           @EmpName        = ISNULL( EmpName      , '' ), 
           @RepairYear     = ISNULL( RepairYear   , '' ), 
           @DeptName       = ISNULL( DeptName     , '' ), 
           @RepairToDate   = ISNULL( RepairToDate , '' ), 
           @ReceiptFrDate  = ISNULL( ReceiptFrDate, '' ), 
           @RepairFrDate   = ISNULL( RepairFrDate , '' ), 
           @ReceiptToDate  = ISNULL( ReceiptToDate, '' ), 
           @FactUnit       = ISNULL( FactUnit     , 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH ( 
                Amd            INT, 
                EmpName        NVARCHAR(100), 
                RepairYear     NCHAR(4), 
                DeptName       NVARCHAR(100), 
                RepairToDate   NCHAR(8), 
                ReceiptFrDate  NCHAR(8), 
                RepairFrDate   NCHAR(8), 
                ReceiptToDate  NCHAR(8), 
                FactUnit       INT 
           )    
    
    IF @RepairToDate = '' SELECT @RepairToDate = '99991231' 
    IF @ReceiptToDate = '' SELECT @ReceiptToDate = '99991231'
    
    -- 최종조회   
    SELECT A.RepairSeq, 
           A.RepairYear, 
           A.FactUnit, 
           D.FactUnitName, 
           A.Amd, 
           A.EmpSeq, 
           B.EmpName, 
           A.DeptSeq, 
           C.DeptName, 
           A.RepairName, 
           A.RepairFrDate, 
           A.RepairToDate, 
           A.ReceiptFrDate, 
           A.ReceiptToDate, 
           A.RepairCfmYn, 
           A.ReceiptCfmyn, 
           A.Remark 
      FROM KPXCM_TEQYearRepairPeriodCHE AS A  
      LEFT OUTER JOIN _TDAEmp           AS B ON ( B.CompanySeq = @CompanySeq AND B.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDADept          AS C ON ( C.CompanySeq = @CompanySeq AND C.DeptSeq = A.DeptSeq ) 
      LEFT OUTER JOIN _TDAFactUnit      AS D ON ( D.CompanySeq = @CompanySeq AND D.FactUnit = A.FactUnit ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( @Amd = '' OR A.Amd = @Amd ) 
       AND ( @EmpName = '' OR B.EmpName LIKE @EmpName + '%' ) 
       AND ( @DeptName = '' OR C.DeptName LIKE @DeptName + '%' ) 
       AND ( @RepairYear = '' OR A.RepairYear = @RepairYear ) 
       AND ( A.RepairFrDate BETWEEN @RepairFrDate AND @RepairToDate ) 
       AND ( A.ReceiptFrDate BETWEEN @ReceiptFrDate AND @ReceiptToDate ) 
    
    RETURN  