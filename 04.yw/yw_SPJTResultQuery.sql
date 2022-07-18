  
IF OBJECT_ID('yw_SPJTResultQuery') IS NOT NULL   
    DROP PROC yw_SPJTResultQuery  
GO  
  
-- v2014.07.07 
  
-- 프로젝트실적입력_YW(조회) by 이재천   
CREATE PROC yw_SPJTResultQuery  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @PJTSeq         INT, 
            @BegDate        NCHAR(8), 
            @WBSLevelSeq    INT, 
            @UMStepSeq      INT 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @PJTSeq      = ISNULL( PJTSeq, 0 ), 
           @BegDate     = ISNULL( BegDate, '' ), 
           @WBSLevelSeq = ISNULL( WBSLevelSeq, 0 ), 
           @UMStepSeq   = ISNULL( UMStepSeq, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH ( 
            PJTSeq      INT, 
            BegDate     NCHAR(8), 
            WBSLevelSeq INT, 
            UMStepSeq   INT 
           )    
    
    -- 프로젝트 
    CREATE TABLE #YW_TPJTWBS 
    (
        IDX_NO          INT IDENTITY(1,1), 
        WBSLevelName    NVARCHAR(20), 
        UMWBSSeq        INT, 
        UMWBSName       NVARCHAR(100), 
        DateCount       INT, 
        MinorSort       INT
    )
    
    INSERT INTO #YW_TPJTWBS (WBSLevelName, UMWBSSeq, UMWBSName, DateCount, MinorSort) 
    SELECT WBSLevelName, UMWBSSeq, B.MinorName, DateCount, B.MinorSort
      FROM YW_TPJTWBS             AS A 
      LEFT OUTER JOIN _TDAUMinor AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.UMWBSSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.WBSLevelSeq = @WBSLevelSeq 
       AND A.UMWBSSeq <= @UMStepSeq 
     ORDER BY UMWBSSeq, MinorSort
    
    SELECT A.IDX_NO AS Serl, 
           A.UMWBSSeq, 
           CASE WHEN LEFT(A.UMWBSSeq, 7) = 1009757 THEN '설계' 
                WHEN LEFT(A.UMWBSSeq, 7) = 1009758 THEN '금형제작' 
                WHEN LEFT(A.UMWBSSeq, 7) = 1009759 THEN 'T1' 
                WHEN LEFT(A.UMWBSSeq, 7) = 1009760 THEN 'T2' 
                WHEN LEFT(A.UMWBSSeq, 7) = 1009761 THEN 'T3' 
                ELSE '' 
                END AS Step, 
           A.UMWBSName, 
           CONVERT(NCHAR(8),DATEADD(Day, B.DateCount, @BegDate),112) AS TargetDate, 
           C.TargetDate, 
           C.BegDate, 
           C.EndDate, 
           C.ChgDate, 
           C.Results, 
           C.FileSeq, 
           CASE WHEN ISNULL(C.PJTSeq,0) = 0 THEN 1 ELSE 0 END AS WorkingTagKind, 
           D.NowStep 
      FROM #YW_TPJTWBS AS A 
      OUTER APPLY (SELECT SUM(DateCount) AS DateCount 
                     FROM #YW_TPJTWBS AS Y 
                    WHERE Y.IDX_NO <= A.IDX_NO 
                  ) AS B 
      LEFT OUTER JOIN YW_TPJTWBSResult AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.UMWBSSeq = A.UMWBSSeq AND C.PJTSeq = @PJTSeq ) 
      OUTER APPLY (SELECT CASE WHEN LEFT(MAX(Z.UMWBSSeq), 7) = 1009757 THEN '설계'   
                               WHEN LEFT(MAX(Z.UMWBSSeq), 7) = 1009758 THEN '금형제작'   
                               WHEN LEFT(MAX(Z.UMWBSSeq), 7) = 1009759 THEN 'T1'   
                               WHEN LEFT(MAX(Z.UMWBSSeq), 7) = 1009760 THEN 'T2'   
                               WHEN LEFT(MAX(Z.UMWBSSeq), 7) = 1009761 THEN 'T3'   
                               ELSE ''   
                               END AS NowStep
                     FROM #YW_TPJTWBS AS Z
                     LEFT OUTER JOIN YW_TPJTWBSResult AS Y WITH(NOLOCK) ON ( Y.CompanySeq = @CompanySeq AND Y.UMWBSSeq = Z.UMWBSSeq AND Y.PJTSeq = @PJTSeq )   
                    WHERE ISNULL(Y.PJTSeq,0) <> 0 
                  ) AS D 
    
    -- 금형정보 
    SELECT C.ToolNo, 
           C.ToolName, 
           B.TestCnt, 
           A.RevEndDate AS LastDate, 
           A.Results AS LastResults
      FROM yw_TPJTToolResult AS A WITH(NOLOCK) 
      CROSS APPLY ( 
                    SELECT PJTSeq, ToolSeq, Count(1) AS TestCnt 
                      FROM yw_TPJTToolResult AS Z 
                     WHERE CompanySeq = @CompanySeq 
                       AND Z.PJTSeq = A.PJTSeq
                       AND Z.ToolSeq = A.ToolSeq 
                     GROUP BY ToolSeq, PJTSeq 
                     HAVING MAX(RevEndDate) = A.RevEndDate 
                  ) AS B 
      LEFT OUTER JOIN _TPDTool AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ToolSeq = A.ToolSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
      AND ( @PJTSeq = 0 OR A.PJTSeq = @PJTSeq ) 
    
    RETURN  
    
GO
exec yw_SPJTResultQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <WBSLevelSeq>0</WBSLevelSeq>
    <UMStepSeq>0</UMStepSeq>
    <PJTSeq>1</PJTSeq>
    <BegDate />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1023453,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1019685