
IF OBJECT_ID('KPX_SCOMUserDefineTableQueryDefined') IS NOT NULL 
    DROP PROC KPX_SCOMUserDefineTableQueryDefined
GO 

-- v2014.08.27 

-- 통합관리사용자코드등록_KPX(조회) by이재천
/***********************************************************  
 설  명 - 테이블별 사용자정의 테이블에 등록된 쿼리문 조회  
 작성일 - 2008년 7월 10일  
 작성자 - 김일주  
 수정자 -   
************************************************************/  
  
-- SP 파라미터들  
CREATE PROCEDURE KPX_SCOMUserDefineTableQueryDefined  
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
    DECLARE @docHandle     INT          ,  
            @TableName     NVARCHAR(100),  
            @Name          NVARCHAR(100),    -- 컬럼명(조회를 위한 컬럼명)  
            @DefineUnitSQL NVARCHAR(1000),  
            @IsUseColumn   NCHAR(1)  
  
  
  
  
    -- XML문서  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
  
    SELECT @TableName   = ISNULL(TableName , ''),  
           @Name        = ISNULL(ColumnName, ''),  
           @IsUseColumn = ISNULL(IsUseColumn, '')  
  
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)  
  
      WITH (TableName   NVARCHAR(100),  
            ColumnName  NVARCHAR(100),  
            IsUseColumn NCHAR(1)  
           )  
    
    SELECT @DefineUnitSQL = A.DefineUnitSQL  
  
      FROM _TCOMUserDefineTable AS A  
  
     WHERE A.CompanySeq = @CompanySeq  
       AND A.TableName  = @TableName  
  

    
    IF(ISNULL(@DefineUnitSQL, '') = '')  
    BEGIN  
        
        SELECT '' AS Name, 0 AS Seq FROM _TCOMUserDefineTable WHERE 1 = 2  
  
    END  
    ELSE  
    BEGIN  
        
        CREATE TABLE #TEMP (Name NVARCHAR(100), Seq INT)  -- KPX 추가 
            
        SELECT @DefineUnitSQL = REPLACE(@DefineUnitSQL, '@1', @CompanySeq)  
        SELECT @DefineUnitSQL = REPLACE(@DefineUnitSQL, '@2', 'N'+'''' + @Name + '''')  
        SELECT @DefineUnitSQL = REPLACE(@DefineUnitSQL, '@3', @IsUseColumn)  
        
        INSERT INTO #TEMP -- KPX 추가 
        EXEC SP_EXECUTESQL @DefineUnitSQL  
        
        IF @PgmSeq = 1020436 
        BEGIN 
            SELECT * FROM #TEMP WHERE Seq IN ( SELECT UMajorSeq FROM KPX_TDAUMajorMaster WHERE CompanySeq = @CompanySeq ) -- KPX 추가 
        END
        
        IF @PgmSeq = 1020450
        BEGIN
            SELECT * FROM #TEMP WHERE Seq NOT IN ( SELECT UMajorSeq FROM KPX_TDAUMajorMaster WHERE CompanySeq = @CompanySeq ) -- KPX 추가 
        END 
  
    END  

  
  
RETURN  
GO
exec KPX_SCOMUserDefineTableQueryDefined @xmlDocument=N'<ROOT>
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
</ROOT>',@xmlFlags=2,@ServiceSeq=1978,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1020436


