  
IF OBJECT_ID('KPX_SPDToolCHEUpLoadSave') IS NOT NULL   
    DROP PROC KPX_SPDToolCHEUpLoadSave  
GO  
  
-- v2015.02.04  
  
-- 설비등록(UpLoad)-저장 by 이재천   
CREATE PROC KPX_SPDToolCHEUpLoadSave  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    CREATE TABLE #TPDTool (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDTool'   
    IF @@ERROR <> 0 RETURN    
    
    DECLARE @Seq    INT, 
            @Count  INT 
    
    
    CREATE TABLE #Temp 
    (
        IDX_NO      INT IDENTITY, 
        ToolSeq     INT, 
        ToolName    NVARCHAR(100), 
        ToolNo      NVARCHAR(100), 
        UMToolKind  INT, 
        FactUnit    INT, 
        ToolTypeName NVARCHAR(100)
    )
    INSERT INTO #Temp ( ToolName, ToolNo, UMToolKind, FactUnit, ToolTypeName ) 
    SELECT A.ToolName, A.ToolNo, B.MinorSeq, C.FactUnit, A.ToolTypeName
      FROM #TPDTool AS A 
      LEFT OUTER JOIN _TDAUMinor    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.MinorName = A.ToolTypeName AND B.MajorSeq = 6009) 
      LEFT OUTER JOIN _TDAFactUnit  AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.FactUnitName = BizUnitName ) 
     WHERE NOT EXISTS (SELECT 1 FROM _TPDTool WHERE CompanySeq = @CompanySeq AND ToolNo = A.ToolNo) 
    
    SELECT @Count = (SELECT COUNT(1) FROM #Temp)
    
    -- 키값생성코드부분 시작  
    EXEC @Seq = dbo._SCOMCreateSeq @CompanySeq, '_TPDTool', 'ToolSeq', @Count
    
    UPDATE A
       SET ToolSeq = @Seq + IDX_NO 
      FROM #Temp AS A 
    
    DECLARE @Message NVARCHAR(MAX)
    
    -- 체크1, 설비종류(사용자정의코드)가 존재하지 않습니다.( 설비종류명 : @@ )
    IF EXISTS ( SELECT 1 FROM #Temp WHERE UMToolKind IS NULL ) 
    BEGIN
        
        SELECT @Message =  
        (SELECT TOP 1 
               REPLACE( REPLACE( REPLACE( ( SELECT DISTINCT ToolTypeName
                                              FROM #Temp 
                                             WHERE UMToolKind IS NULL
                                            FOR XML AUTO, ELEMENTS 
                                           ), '</ToolTypeName></_x0023_Temp><_x0023_Temp><ToolTypeName>', ',' 
                                        ), '<_x0023_Temp><ToolTypeName>', '' 
                               ), '</ToolTypeName></_x0023_Temp>', '' 
                      ) 
                 AS A 
          FROM #Temp )
    
        UPDATE #TPDTool 
           SET Result = '설비종류(사용자정의코드)가 존재하지 않습니다.( 설비종류명 : ' + @Message + ' )', 
               MessageType = 1234, 
               Status = 1234 
        
        SELECT * FROM #TPDTool 
        RETURN 
    END 
    -- 체크1, END 
    
    
    INSERT INTO _TPDTool
    (
        CompanySeq, ToolSeq, ToolName, ToolNo, UMToolKind, 
        Spec, Capacity, DeptSeq, EmpSeq, BuyDate, 
        BuyCost, SMStatus, CustSeq, Cavity, DesignShot, 
        InitialShot, WorkShot, TotalShot, AssetSeq,Remark, 
        LastUserSeq, LastDateTime, Uses, Forms, SerialNo, 
        NationSeq, ManuCompnay, MoldCount, OrderCustSeq, CustShareRate,
        ModifyShot, ModifyDate, DisuseDate, DisuseCustSeq, ProdSrtDate, 
        ASTelNo, FactUnit
    ) 
    SELECT @CompanySeq, ToolSeq, ToolName, ToolNo, UMToolKind,
           '', '', 0, 0, '',
           0, 0, 0, 0, 0,
           0, 0, 0, 0, '',
           @UserSeq, GETDATE(), '', '', '', 
           0, N'', 0, 0, 0, 
           0, '', '', 0, '', '', FactUnit
      FROM #Temp     
    
    
    
    CREATE TABLE #Define 
    (
        Name        NVARCHAR(200), 
        ToolName    NVARCHAR(200), 
        ToolNo      NVARCHAR(200), 
        Serl        INT 
    ) 
    
    
    INSERT INTO #Define ( Name, ToolName, ToolNo, Serl ) 
    SELECT Name1, ToolName, ToolNo, 1 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name1,'') <> '' 
    
    UNION ALL 
    
    SELECT Name2, ToolName, ToolNo, 2 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name2,'') <> '' 
    
    UNION ALL
    
    SELECT Name3, ToolName, ToolNo, 3 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name3,'') <> '' 
    
    UNION ALL 
    
    SELECT Name4, ToolName, ToolNo, 4 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name4,'') <> '' 
    
    UNION ALL
    
    SELECT Name5, ToolName, ToolNo, 5 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name5,'') <> '' 
    
    UNION ALL 
    
    SELECT Name6, ToolName, ToolNo, 6 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name6,'') <> '' 
    
    UNION ALL 
    
    SELECT Name7, ToolName, ToolNo, 7 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name7,'') <> '' 
    
    UNION ALL 
    
    SELECT Name8, ToolName, ToolNo, 8 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name8,'') <> '' 
    
    UNION ALL 
    
    SELECT Name9, ToolName, ToolNo, 9 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name9,'') <> '' 
    
    UNION ALL 
    
    SELECT Name10, ToolName, ToolNo, 10 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name10,'') <> '' 
    
    UNION ALL 
    
    SELECT Name11, ToolName, ToolNo, 11 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name11,'') <> '' 
    
    UNION ALL 
    
    SELECT Name12, ToolName, ToolNo, 12 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name12,'') <> '' 
    
    UNION ALL 
    
    SELECT Name13, ToolName, ToolNo, 13 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name13,'') <> '' 
    
    UNION ALL 
    
    SELECT Name14, ToolName, ToolNo, 14 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name14,'') <> '' 
    
    UNION ALL 
    
    SELECT Name15, ToolName, ToolNo, 15 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name15,'') <> '' 

    UNION ALL 
    
    SELECT Name16, ToolName, ToolNo, 16 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name16,'') <> '' 
     
    UNION ALL 
    
    SELECT Name17, ToolName, ToolNo, 17 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name17,'') <> '' 
     
    UNION ALL 
    
    SELECT Name18, ToolName, ToolNo, 18 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name18,'') <> '' 
     
    UNION ALL 
    
    SELECT Name19, ToolName, ToolNo, 19 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name19,'') <> '' 
     
    UNION ALL 
    
    SELECT Name20, ToolName, ToolNo, 20 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name20,'') <> '' 
     
         UNION ALL 
    
    SELECT Name21, ToolName, ToolNo, 21 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name21,'') <> '' 
     
    UNION ALL 
    
    SELECT Name22, ToolName, ToolNo, 22 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name22,'') <> '' 
     
         UNION ALL 
    
    SELECT Name23, ToolName, ToolNo, 23 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name23,'') <> '' 
     
    UNION ALL 
    
    SELECT Name24, ToolName, ToolNo, 24 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name24,'') <> '' 
     
         UNION ALL 
    
    SELECT Name25, ToolName, ToolNo, 25 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name25,'') <> '' 
     
    UNION ALL 
    
    SELECT Name26, ToolName, ToolNo, 26 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name26,'') <> '' 
     
    UNION ALL 
    
    SELECT Name27, ToolName, ToolNo, 27 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name27,'') <> '' 
     
    UNION ALL 
    
    SELECT Name28, ToolName, ToolNo, 28 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name28,'') <> '' 
     
     
    UNION ALL 
    
    SELECT Name29, ToolName, ToolNo, 29 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name29,'') <> '' 
     
    UNION ALL 
    
    SELECT Name30, ToolName, ToolNo, 30 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name30,'') <> '' 
     
     UNION ALL 
    
    SELECT Name31, ToolName, ToolNo, 31 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name31,'') <> '' 
     
     UNION ALL 
    
    SELECT Name32, ToolName, ToolNo, 32 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name32,'') <> '' 
     
     UNION ALL 
    
    SELECT Name33, ToolName, ToolNo, 33 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name33,'') <> '' 
     
     UNION ALL 
    
    SELECT Name34, ToolName, ToolNo, 34 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name34,'') <> '' 
     
     UNION ALL 
    
    SELECT Name35, ToolName, ToolNo, 35 AS Serl  
      FROM #TPDTool 
     WHERE ISNULL(Name35,'') <> '' 
     
     
    
    
    
    SELECT A.* , B.ToolSeq 
      INTO #Define_Sub
      FROM #Define AS A 
      LEFT OUTER JOIN _TPDTool AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.ToolName = A.ToolName AND B.ToolNo = A.ToolNo ) 
     ORDER BY A.ToolName, A.ToolNo, A.Serl 
    
    
    -- 체크2, 이미 등록 되어 있습니다.( 설비번호 : @@ )
    IF EXISTS ( SELECT 1 FROM #Define_Sub AS A WHERE EXISTS (SELECT 1 FROM _TPDToolUserDefine WHERE CompanySeq = @CompanySeq AND ToolSeq = A.ToolSeq) )
    BEGIN 
    
        SELECT @Message =  
        (SELECT TOP 1 
               REPLACE( REPLACE( REPLACE( ( SELECT DISTINCT ToolNo
                                              FROM #Define_Sub AS A 
                                             WHERE EXISTS (SELECT 1 FROM _TPDToolUserDefine WHERE CompanySeq = @CompanySeq AND ToolSeq = A.ToolSeq) 
                                            FOR XML AUTO, ELEMENTS 
                                           ), '</ToolNo></A><A><ToolNo>', ',' 
                                        ), '<A><ToolNo>', '' 
                               ), '</ToolNo></A>', '' 
                      ) 
                 AS A 
          FROM #Define_Sub )
        
        SELECT @Message = REPLACE(@Message,',',', ')
        
        UPDATE #TPDTool 
           SET Result = '이미 등록 되어 있습니다.( 설비번호 : ' + @Message + ' )', 
               MessageType = 1234, 
               Status = 1234 
        
        SELECT * FROM #TPDTool 
        RETURN 
    
    END 
    -- 체크2, END
    
    INSERT INTO _TPDToolUserDefine 
    ( 
        CompanySeq, ToolSeq, MngSerl, MngValSeq, MngValText, 
        LastUserSeq, LastDateTime 
    )
    SELECT @CompanySeq, ToolSeq, Serl, 0, A.Name, 
           @UserSeq, GETDATE()
      FROM #Define_Sub AS A 
     WHERE A.ToolSeq NOT IN ( SELECT DISTINCT ToolSeq
                                FROM #Define_Sub AS A 
                               GROUP by ToolSeq, Serl, A.Name 
                              HAVING COUNT (1) > 1 
                            )
     ORDER BY ToolSeq, Serl
    
    SELECT * FROM #TPDTool 
    
    RETURN  
GO 
