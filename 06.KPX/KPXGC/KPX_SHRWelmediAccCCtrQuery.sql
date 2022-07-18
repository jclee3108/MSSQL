
IF OBJECT_ID('KPX_SHRWelmediAccCCtrQuery') IS NOT NULL 
    DROP PROC KPX_SHRWelmediAccCCtrQuery
GO 

-- v2014.12.08 

-- 의료비계정등록(활동센터)-조회 by이재천
CREATE PROCEDURE KPX_SHRWelmediAccCCtrQuery  
    @xmlDocument NVARCHAR(MAX)   ,    -- 화면의 정보를 XML로 전달  
    @xmlFlags    INT = 0         ,    -- 해당 XML의 TYPE  
    @ServiceSeq  INT = 0         ,    -- 서비스 번호  
    @WorkingTag  NVARCHAR(10)= '',    -- 워킹 태그  
    @CompanySeq  INT = 1         ,    -- 회사 번호  
    @LanguageSeq INT = 1         ,    -- 언어 번호  
    @UserSeq     INT = 0         ,    -- 사용자 번호  
    @PgmSeq      INT = 0              -- 프로그램 번호  

AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    -- 사용할 변수를 선언한다.  
    DECLARE @docHandle  INT, 
            @EnvValue   INT, 
            @YM         NCHAR(6), 
            @GroupSeq   INT 
    
    -- XML파싱  
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    -- @xmlDocument의 XML을 @docHandle로 핸들한다.  
    
    -- XML의 DataBlock1으로부터 값을 가져와 변수에 저장한다.  
    SELECT @EnvValue       = ISNULL(EnvValue,0),  
           @YM             = ISNULL(YM,''),
           @GroupSeq       = ISNULL(GroupSeq,0)
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    -- XML의 DataBlock1으로부터  
      WITH (
            EnvValue       INT,  
            YM             NCHAR(6),
            GroupSeq       INT
           )  
    
    SELECT A.WelCodeName, 
           A.WelCodeSeq, 
           B.AccSeq AS AccSeq,
           C.AccName,
           B.UMCostType, 
           D.MinorName AS UMCostTypeName,
           B.OppAccSeq, 
           E.AccName AS OppAccName,
           B.VatAccSeq, 
           F.AccName AS VatAccName 
    
      FROM KPX_THRWelCode                   AS A 
      LEFT OUTER JOIN KPX_THRWelmediAccCCtr AS B ON ( B.CompanySeq  = @CompanySeq 
                                                  AND A.WelCodeSeq  = B.WelCodeSeq 
                                                  AND B.EnvValue    = @EnvValue 
                                                  AND B.YM          = @YM   
                                                  AND B.GroupSeq    = @GroupSeq
                                                    ) 
      LEFT OUTER JOIN _TDAAccount           AS C ON ( C.CompanySeq = @CompanySeq AND C.AccSeq = B.AccSeq ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = B.UMCostType ) 
      LEFT OUTER JOIN _TDAAccount           AS E ON ( E.CompanySeq = @CompanySeq AND E.AccSeq = B.OppAccSeq ) 
      LEFT OUTER JOIN _TDAAccount           AS F ON ( F.CompanySeq = @CompanySeq AND F.AccSeq = B.VATAccSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
    
    RETURN
GO 
exec KPX_SHRWelmediAccCCtrQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <EnvValue>5518002</EnvValue>
    <YM>201001</YM>
    <GroupSeq>7</GroupSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026567,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022249