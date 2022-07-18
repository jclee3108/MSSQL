  
IF OBJECT_ID('KPXCM_SPDSFCWorkReportPOPIFQuerySub') IS NOT NULL   
    DROP PROC KPXCM_SPDSFCWorkReportPOPIFQuerySub  
GO  
  
-- v2015.11.18  
  
-- 생산실적반영(POP)-Item조회 by 이재천   
CREATE PROC KPXCM_SPDSFCWorkReportPOPIFQuerySub  
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
            @Seq        INT, 
            @IsNoProc   NCHAR(1)
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @Seq         = ISNULL( Seq, 0 ), 
           @IsNoProc    = ISNULL( IsNoProc, '0') 
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            Seq         INT, 
            IsNoProc    NCHAR(1)
           )    
      
    -- 최종조회   
    SELECT *, 
           '-1' AS Color --CASE WHEN A.ProcYn = '1' THEN '-2365967' ELSE '-136743' END AS Color
      INTO #Result 
      FROM KPX_TPDSFCworkReportExcept_POP     AS A 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.ReportSeq = @Seq 
    
    IF @IsNoProc = '1' 
    BEGIN 
        
        DELETE FROM #Result WHERE ProcYn = '1' 
    
    END 
    
    SELECT A.Seq, 
           A.IFWorkReportSeq, 
           B.ItemName AS ItemSeq, 
           C.UnitName AS UnitSeq, 
           A.Qty, 
           A.ItemLotNo, 
           A.HambaQty, 
           D.WHName AS WHSeq, 
           A.Remark, 
           CASE WHEN A.WorkingTag = 'A' THEN '신규'
                WHEN A.WorkingTag = 'U' THEN '수정' 
                WHEN A.WorkingTag = 'D' THEN '삭제' 
                END AS WorkingTagName, 
           CASE WHEN A.ProcYn = '1' THEN '처리' ELSE '미처리' END AS ProcYn,
           E.EmpName AS RegEmpSeq, 
           A.RegDateTime, 
           A.ProcDateTime, 
           A.ErrorMessage, 
           A.WorkReportSeq, 
           A.ItemSerl, 
           A.POPKey, 
           A.ReportSeq, 
           A.Color
      FROM #Result AS A 
      LEFT OUTER JOIN _TDAItem      AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit      AS C ON ( C.CompanySeq = @CompanySeq AND C.UnitSeq = A.UnitSeq ) 
      LEFT OUTER JOIN _TDAWH        AS D ON ( D.CompanySeq = @CompanySeq AND D.WHSeq = A.WHSeq ) 
      LEFT OUTER JOIN _TDAEmp       AS E ON ( E.CompanySeq = @CompanySeq AND E.EmpSeq = A.RegEmpSeq ) 
     ORDER BY POPKey
    
    
    RETURN  
    go
    exec KPXCM_SPDSFCWorkReportPOPIFQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>12</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <Seq>1000025902</Seq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsNoProc>1</IsNoProc>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033251,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1027544