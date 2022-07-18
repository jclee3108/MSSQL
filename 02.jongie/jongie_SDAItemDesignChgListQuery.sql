  
IF OBJECT_ID('jongie_SDAItemDesignChgListQuery') IS NOT NULL   
    DROP PROC jongie_SDAItemDesignChgListQuery  
GO  
  
-- v2013.09.17  
  
-- 디자인변경조회_jongie(조회) by 이재천   
CREATE PROC jongie_SDAItemDesignChgListQuery  
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
            @AssetSeq       INT, 
            @ItemClassLSeq  INT,  
            @ItemClassMSeq  INT, 
            @ItemClassSSeq  INT, 
		    @ItemName       NVARCHAR(200), 
            @ItemNo         NVARCHAR(100), 
            @Spec           NVARCHAR(100), 
            @EmpSeq         INT, 
            @ChangeDateFr   NVARCHAR(8), 
            @ChangeDateTo   NVARCHAR(8), 
            @LastDateFr     NVARCHAR(8), 
            @LastDateTo     NVARCHAR(8), 
            @DateFr         NVARCHAR(8), 
            @DateTo         NVARCHAR(8)

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @AssetSeq      = ISNULL( AssetSeq      ,0 ), 
           @ItemClassLSeq = ISNULL( ItemClassLSeq ,0 ), 
           @ItemClassMSeq = ISNULL( ItemClassMSeq ,0 ), 
           @ItemClassSSeq = ISNULL( ItemClassSSeq ,0 ), 
           @ItemName      = ISNULL( ItemName      ,'' ), 
           @ItemNo        = ISNULL( ItemNo        ,'' ), 
           @Spec          = ISNULL( Spec          ,'' ), 
           @EmpSeq        = ISNULL( EmpSeq        ,0 ), 
           @ChangeDateFr  = ISNULL( ChangeDateFr  ,'' ), 
           @ChangeDateTo  = ISNULL( ChangeDateTo  ,'' ), 
           @LastDateFr    = ISNULL( LastDateFr    ,'' ), 
           @LastDateTo    = ISNULL( LastDateTo    ,'' ), 
           @DateFr        = ISNULL( DateFr        ,'' ),
           @DateTo        = ISNULL( DateTo        ,'' )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            AssetSeq       INT, 
            ItemClassLSeq  INT,  
            ItemClassMSeq  INT, 
            ItemClassSSeq  INT, 
            ItemName       NVARCHAR(200),
            ItemNo         NVARCHAR(100),
            Spec           NVARCHAR(100),
            EmpSeq         INT, 
            ChangeDateFr   NVARCHAR(8), 
            ChangeDateTo   NVARCHAR(8), 
            LastDateFr     NVARCHAR(8), 
            LastDateTo     NVARCHAR(8), 
            DateFr         NVARCHAR(8), 
            DateTo         NVARCHAR(8) 
           )    
    
    IF @ChangeDateTo = '' SELECT @ChangeDateTo = '99991231' 
    IF @LastDateTo   = '' SELECT @LastDateTo   = '99991231' 
    IF @DateTo       = '' SELECT @DateTo       = '99991231'
    
    -- 최종조회   
    SELECT A.ItemSeq, 
           A.ItemName, 
           A.ItemNo, 
           A.Spec,
           C.AssetName, 
           B.ItemClassLSeq, 
           B.ItemClasLName AS ItemClassLName, 
           B.ItemClassMSeq, 
           B.ItemClasMName AS ItemClassMName, 
           B.ItemClassSSeq, 
           B.ItemClasSName AS ItemClassSName, 
           D.EmpName, 
           D.EmpSeq, 
           CONVERT(NVARCHAR(8), A.RegDateTime, 112) AS RegDate, 
           REPLACE(E.MngValText,'-','') AS LastDate, 
           G.MngValText AS ChangeDate, 
           F.FileSeq AS FileAdd, 
           CASE WHEN ISNULL(F.FileSeq,0) = 0 THEN 0 ELSE 1 END AS IsFile
           
      FROM _TDAItem AS A WITH(NOLOCK)   
      LEFT OUTER JOIN _FDAGetItemClass(@CompanySeq, 0) AS B ON ( B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAItemAsset      AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.AssetSeq = A.AssetSeq ) 
      LEFT OUTER JOIN _TDAEmp            AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.EmpSeq = A.EmpSeq ) 
      LEFT OUTER JOIN _TDAItemUserDefine AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.ItemSeq AND E.MngSerl = 1000010 ) 
      LEFT OUTER JOIN _TDAItemUserDefine AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.ItemSeq = A.ItemSeq AND G.MngSerl = 1000009 ) 
      LEFT OUTER JOIN _TDAItemFile       AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = A.ItemSeq ) 
     
     WHERE A.CompanySeq = @CompanySeq 
       AND (@AssetSeq = 0 OR A.AssetSeq = @AssetSeq) 
       AND (@ItemClassLSeq = 0 OR B.ItemClassLSeq = @ItemClassLSeq) 
       AND (@ItemClassMSeq = 0 OR B.ItemClassMSeq = @ItemClassMSeq) 
       AND (@ItemClassSSeq = 0 OR B.ItemClassSSeq = @ItemClassSSeq) 
       AND (@ItemName = '' OR A.ItemName LIKE @ItemName + '%')
       AND (@ItemNo = '' OR A.ItemNo LIKE @ItemNo + '%') 
       AND (@Spec = '' OR A.Spec LIKE @Spec + '%') 
       AND (@EmpSeq = 0 OR A.EmpSeq = @EmpSeq) 
       AND (CONVERT(NVARCHAR(8), A.RegDateTime, 112) BETWEEN @DateFr AND @DateTo) 
       AND ((E.MngValText BETWEEN @LastDateFr AND @LastDateTo)) 
       AND ((G.MngValText BETWEEN @ChangeDateFr AND @ChangeDateTo)) 
       AND (ISNULL(RTRIM(G.MngValText),'') <> '' OR ISNULL(RTRIM(E.MngValText),'') <> '')
      
    RETURN 
GO
exec jongie_SDAItemDesignChgListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>I</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ItemName></ItemName>
    <ItemNo />
    <Spec />
    <AssetSeq />
    <EmpSeq />
    <ItemClassSSeq />
    <DateFr />
    <DateTo />
    <ItemClassMSeq />
    <ItemClassLSeq />
    <ChangeDateFr />
    <ChangeDateTo />
    <LastDateFr />
    <LastDateTo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1017869,@WorkingTag=N'I',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1015291
