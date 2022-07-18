
IF OBJECT_ID('KPX_SCOMUserDefineTableDefinedModuleQuery') IS NOT NULL 
    DROP PROC KPX_SCOMUserDefineTableDefinedModuleQuery
GO 

-- v2014.09.24 

-- 미통합관리사용자정의코드(모듈) by 이재천

-- SP파라미터들  
CREATE PROCEDURE KPX_SCOMUserDefineTableDefinedModuleQuery  
    @xmlDocument NVARCHAR(MAX)    ,  
    @xmlFlags    INT = 0          ,  
    @ServiceSeq  INT = 0          ,  
    @WorkingTag  NVARCHAR(10) = '',  
    @CompanySeq  INT = 0          ,  
    @LanguageSeq INT = 1          ,  
    @UserSeq     INT = 0          ,  
    @PgmSeq      INT = 0  
  
AS  
    
    -- 변수 선언  
    DECLARE @docHandle      INT          ,  
            @TableName      NVARCHAR(100),  
            @Name           NVARCHAR(100),    -- 컬럼명(조회를 위한 컬럼명)  
            @DefineUnitSQL  NVARCHAR(1000)  
    
    -- XML문서  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
    SELECT @TableName = ISNULL(TableName , ''),  
           @Name      = ISNULL(ColumnName, '')  
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
      WITH (TableName  NVARCHAR(100),  
            ColumnName NVARCHAR(100)  
           )  
    
    -- 시트에 값을 출력하는 부분  
    SELECT ISNULL(A.MajorName, '') AS Name  , ISNULL(A.MajorSeq, 0) AS Seq,  
           ISNULL(B.PgmSeq   ,  0) AS PgmSeq  
      FROM _TDAUMajor AS A 
      LEFT OUTER JOIN _TDAUMajorPgm AS B ON ( A.CompanySeq = B.CompanySeq AND A.MajorSeq = B.MajorSeq ) 
     WHERE A.CompanySeq   = @CompanySeq  
       AND A.MajorName LIKE @Name + '%'  
       AND B.PgmSeq       = @PgmSeq 
       AND NOT EXISTS (SELECT 1 FROM KPX_TDAUMajorMaster WHERE CompanySeq = @CompanySeq AND UMajorSeq = A.MajorSeq)
     ORDER BY A.MajorSeq  
    
--        SET @DefineUnitSQL = ''  
--        SET @DefineUnitSQL = @DefineUnitSQL + 'SELECT A.MajorName AS Name, A.MajorSeq AS Seq, B.PgmSeq FROM _TDAUMajor AS A '  
--        SET @DefineUnitSQL = @DefineUnitSQL + 'LEFT OUTER JOIN _TDAUMajorPgm AS B ON A.CompanySeq = B.CompanySeq AND A.MajorSeq = B.MajorSeq '  
--        SET @DefineUnitSQL = @DefineUnitSQL + 'WHERE A.CompanySeq = @1 AND MajorName LIKE @2 + ''%'' '  
--        SET @DefineUnitSQL = @DefineUnitSQL + 'AND B.pgmSeq = ' + CONVERT(NVARCHAR(10), @PgmSeq)    -- 링크폼에 맞는(인사, 회계, 생산 등등)  
--        SET @DefineUnitSQL = @DefineUnitSQL + ' ORDER BY A.MajorSeq'  
    
    RETURN  
GO 
exec KPX_SCOMUserDefineTableDefinedModuleQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ColumnName />
    <TableName>_TDAUMajor</TableName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1024281,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020817