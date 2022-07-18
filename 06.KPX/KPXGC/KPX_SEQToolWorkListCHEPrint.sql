
IF OBJECT_ID('KPX_SEQToolWorkListCHEPrint') IS NOT NULL 
    DROP PROC KPX_SEQToolWorkListCHEPrint 
GO 
  
-- v2015.03.05 

-- 설비이력조회 출력물 by이재천 
/************************************************************  
 설  명 - 데이터-설비이력조회 : 조회  
 작성일 - 20141212  
 작성자 - 오정환  
 수정자 -   
************************************************************/  
  
CREATE PROC KPX_SEQToolWorkListCHEPrint               
    @xmlDocument   NVARCHAR(MAX) ,              
    @xmlFlags      INT = 0,              
    @ServiceSeq    INT = 0,              
    @WorkingTag    NVARCHAR(10)= '',                    
    @CompanySeq    INT = 1,              
    @LanguageSeq   INT = 1,              
    @UserSeq       INT = 0,              
    @PgmSeq        INT = 0         
  
AS      
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    CREATE TABLE #Tool (WorkingTag NCHAR(1) NULL)    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#Tool'   
    IF @@ERROR <> 0 RETURN    
    
    
    CREATE TABLE #Temp 
    (
        IDX_NO          INT IDENTITY, 
        WorkType        INT, 
        WorkTypeName    NVARCHAR(100), 
        AccUnitName     NVARCHAR(100), 
        AccUnitSeq      INT, 
        ToolName        NVARCHAR(100), 
        ToolNo          NVARCHAR(100), 
        ToolSeq         INT, 
        WorkOperName    NVARCHAR(100), 
        ReqDeptName     NVARCHAR(100), 
        ReqDeptSeq      INT, 
        ReqEmpName      NVARCHAR(100), 
        ReqEmpSeq       INT, 
        WorkName        NVARCHAR(100), 
        ReqDate         NCHAR(8), 
        WONo            NVARCHAR(100), 
        ReqCloseDate    NCHAR(8), 
        WorkContents    NVARCHAR(100), 
        EmpSeq          INT, 
        EmpName         NVARCHAR(100), 
        QryDate         NCHAR(8), 
        TitleName1      NVARCHAR(100), 
        Data1           NVARCHAR(100),
        TitleName2      NVARCHAR(100), 
        Data2           NVARCHAR(100),
        TitleName3      NVARCHAR(100), 
        Data3           NVARCHAR(100),
        TitleName4      NVARCHAR(100), 
        Data4           NVARCHAR(100),
        TitleName5      NVARCHAR(100), 
        Data5           NVARCHAR(100),
        TitleName6      NVARCHAR(100), 
        Data6           NVARCHAR(100),
        TitleName7      NVARCHAR(100), 
        Data7           NVARCHAR(100),
        TitleName8      NVARCHAR(100), 
        Data8           NVARCHAR(100),
        TitleName9      NVARCHAR(100), 
        Data9           NVARCHAR(100),
        TitleName10     NVARCHAR(100), 
        Data10          NVARCHAR(100),
        TitleName11     NVARCHAR(100), 
        Data11          NVARCHAR(100),
        TitleName12     NVARCHAR(100), 
        Data12          NVARCHAR(100),
        TitleName13     NVARCHAR(100), 
        Data13          NVARCHAR(100),
        TitleName14     NVARCHAR(100), 
        Data14          NVARCHAR(100),
        TitleName15     NVARCHAR(100), 
        Data15          NVARCHAR(100),
        TitleName16     NVARCHAR(100), 
        Data16          NVARCHAR(100),
        TitleName17     NVARCHAR(100), 
        Data17          NVARCHAR(100),
        TitleName18     NVARCHAR(100), 
        Data18          NVARCHAR(100),
        TitleName19     NVARCHAR(100), 
        Data19          NVARCHAR(100),
        TitleName20     NVARCHAR(100), 
        Data20          NVARCHAR(100),
        TitleName21     NVARCHAR(100), 
        Data21          NVARCHAR(100)
    )
    
    INSERT INTO #Temp 
    (
        WorkType        ,WorkTypeName     ,AccUnitName      ,AccUnitSeq       ,ToolName         ,
        ToolNo          ,ToolSeq          ,WorkOperName     ,ReqDeptName      ,ReqDeptSeq       ,
        ReqEmpName      ,ReqEmpSeq        ,WorkName         ,ReqDate          ,WONo             ,
        ReqCloseDate    ,WorkContents     ,EmpSeq           ,EmpName          ,QryDate          
    ) 
    --작업실적등록(일반)  
    SELECT 6028001                          AS WorkType         ,  
           '작업실적등록(일반)'             AS WorkTypeName     ,  
           ISNULL(D.FactUnitName,'')        AS AccUnitName      ,  
           B.PdAccUnitSeq                   AS AccUnitSeq       ,  
           C.ToolName, 
           C.ToolNo, 
           B.ToolSeq                        AS ToolSeq          ,  
           ISNULL(G.MinorName,'')           AS WorkOperName     ,  
           I.DeptName                       AS ReqDeptName      ,  
           H.DeptSeq                        AS ReqDeptSeq       ,  
           J.EmpName                        AS ReqEmpName       ,  
           H.EmpSeq                         AS ReqEmpSeq        ,  
           H.WorkName                       AS WorkName         ,  
           H.ReqDate                        AS ReqDate          ,  
           H.WONo                           AS WONo             ,  
           H.ReqCloseDate                   AS ReqCloseDate     ,  
           F.WorkContents                   AS WorkContents  ,  
           F.EmpSeq       AS EmpSeq   ,  
           L.EmpName      AS EmpName   ,  
           F.ReceiptDate     AS QryDate     
      FROM _TEQWorkOrderReceiptItemCHE                AS A 
                 JOIN _TEQWorkOrderReceiptMasterCHE   AS F ON ( A.CompanySeq = F.CompanySeq AND A.ReceiptSeq = F.ReceiptSeq  ) 
      LEFT OUTER JOIN _TEQWorkOrderReqItemCHE         AS B ON ( A.CompanySeq = B.CompanySeq AND A.WOReqSeq = B.WOReqSeq AND A.WOReqSerl = B.WOReqSerl ) 
      LEFT OUTER JOIN _TEQWorkOrderReqMasterCHE       AS H ON ( B.CompanySeq = H.CompanySeq AND B.WOReqSeq = H.WOReqSeq ) 
      LEFT OUTER JOIN _TPDTool                        AS C ON ( B.CompanySeq = C.CompanySeq AND B.ToolSeq = C.ToolSeq ) 
      LEFT OUTER JOIN _TDAFactUnit                    AS D ON ( B.CompanySeq = D.CompanySeq AND B.PdAccUnitSeq = D.FactUnit )    -- 생산사업장  
      LEFT OUTER JOIN _TDAUMinor                      AS G ON ( B.CompanySeq = G.CompanySeq AND B.WorkOperSeq = G.MinorSeq )    -- 작업수행과  
      LEFT OUTER JOIN _TDADept                        AS I ON ( H.CompanySeq = I.CompanySeq AND H.DeptSeq = I.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp                         AS J ON ( H.CompanySeq = J.CompanySeq AND H.EmpSeq = J.EmpSeq ) 
      LEFT OUTER JOIN _TDAEmp                         AS L ON ( F.CompanySeq = L.CompanySeq AND F.EmpSeq = L.EmpSeq ) 
     WHERE 1=1  
       AND ISNULL(B.ToolSeq,0) <> 0 
       AND EXISTS (SELECT 1 FROM #Tool WHERE ToolSeq = B.ToolSeq) 
    
    UNION ALL  
    --작업실적등록(연차보수)(연차보수실적등록)  
    SELECT 6028002            AS WorkType  ,  
           (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq=@CompanySeq AND MinorSeq=6028002) AS WorkTypeName,  
           C.FactUnitName     AS AccUnitName,  
           A.FactUnit      AS AccUnitSeq,  
           B.ToolName, 
           B.ToolNo, 
           B.ToolSeq            AS ToolSeq,  
           ISNULL(D.MinorName,'') AS WorkOperName     ,  
           E.DeptName AS ReqDeptName      ,  
           A.DeptSeq AS ReqDeptSeq       ,  
           F.EmpName AS ReqEmpName       ,  
           A.EmpSeq AS ReqEmpSeq        ,  
           '' AS WorkName         ,  
           A.ReqDate AS ReqDate          ,  
           A.WONo AS WONo             ,  
           '' AS ReqCloseDate     ,  
           A.WorkContents AS WorkContents    ,  
           0 AS EmpSeq     ,  
           '' AS EmpName     ,  
           '' AS QryDate     
      FROM _TEQYearRepairMngCHE    AS A  
      JOIN (SELECT CompanySeq, ReqSeq, MAX(Amd) AS Amt 
              FROM _TEQYearRepairMngCHE 
             GROUP BY CompanySeq, ReqSeq 
           ) AS AA ON ( A.CompanySeq = AA.CompanySeq AND A.ReqSeq  = AA.ReqSeq ) 
      LEFT OUTER JOIN _TPDTool              AS B ON ( A.CompanySeq = B.CompanySeq AND A.ToolSeq = B.ToolSeq ) 
      LEFT OUTER JOIN _TDAFactUnit          AS C ON ( A.CompanySeq = C.CompanySeq AND A.FactUnit = C.FactUnit ) 
      LEFT OUTER JOIN _TDAUMinor            AS D ON ( A.CompanySeq = D.CompanySeq AND A.WorkOperSeq = D.MinorSeq ) 
      LEFT OUTER JOIN _TDADept              AS E ON ( A.CompanySeq = E.CompanySeq AND A.DeptSeq = E.DeptSeq ) 
      LEFT OUTER JOIN _TDAEmp               AS F ON ( A.CompanySeq = F.CompanySeq AND A.EmpSeq = F.EmpSeq ) 
     WHERE 1=1  
       AND A.CompanySeq = @CompanySeq  
       AND ISNULL(B.ToolSeq,0) <> 0 
       AND EXISTS (SELECT 1 FROM #Tool WHERE ToolSeq = B.ToolSeq) 

    UNION ALL  
    --설비검교정내역등록  
    SELECT 6028003            AS WorkType  ,  
           (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq=@CompanySeq AND MinorSeq=6028003) AS WorkTypeName,  
           ISNULL(C.FactUnitName,'')        AS AccUnitName,  
           B.FactUnit           AS AccUnitSeq,  
           B.ToolName, 
           B.ToolNo, 
           B.ToolSeq AS ToolSeq,  
           '' AS WorkOperName     ,  
           '' AS ReqDeptName      ,  
           0 AS ReqDeptSeq       ,  
           '' AS ReqEmpName       ,  
             0 AS  ReqEmpSeq        ,  
           '' AS WorkName         ,  
           '' AS ReqDate          ,  
           '' AS WONo             ,  
           '' AS ReqCloseDate     ,  
           A.WkContent AS WorkContents  ,  
           0 AS EmpSeq   ,  
           '' AS EmpName   ,  
           A.CorrectDate AS QryDate     
    
      FROM _TEQExamCorrectEditCHE              AS A  
      LEFT OUTER JOIN _TPDTool                 AS B  ON ( A.CompanySeq = B.CompanySeq AND A.ToolSeq = B.ToolSeq ) 
      LEFT OUTER JOIN _TDAFactUnit             AS C ON ( B.CompanySeq = C.CompanySeq AND B.FactUnit = C.FactUnit ) 
     WHERE 1=1  
       AND A.CompanySeq = @CompanySeq  
       AND ISNULL(B.ToolSeq,0) <> 0 
       AND EXISTS (SELECT 1 FROM #Tool WHERE ToolSeq = B.ToolSeq) 
    
    UNION ALL  
    
    SELECT 6028004            AS WorkType  ,  
          (SELECT MinorName FROM _TDAUMinor WHERE CompanySeq=@CompanySeq AND MinorSeq=6028004) AS WorkTypeName,  
          ISNULL(C.FactUnitName,'')        AS AccUnitName,  
          B.FactUnit           AS AccUnitSeq,  
          B.ToolName, 
          B.ToolNo, 
          B.ToolSeq AS ToolSeq,  
          '' AS WorkOperName     ,  
          '' AS ReqDeptName      ,  
          0 AS ReqDeptSeq       ,  
          '' AS ReqEmpName       ,  
          0 AS ReqEmpSeq        ,  
          '' AS WorkName         ,  
          '' AS ReqDate          ,  
          '' AS WONo             ,  
          '' AS ReqCloseDate     ,  
          A.Remark AS WorkContents  ,  
          0 AS EmpSeq   ,  
          '' AS EmpName   ,  
          A.CheckDate AS QryDate     
      FROM KPX_TEQCheckReport               AS A  
      LEFT OUTER JOIN _TPDTool              AS B ON ( A.CompanySeq = B.CompanySeq AND A.ToolSeq = B.ToolSeq ) 
      LEFT OUTER JOIN _TDAFactUnit          AS C ON ( B.CompanySeq = C.CompanySeq AND B.FactUnit = C.FactUnit ) 
     WHERE 1=1  
       AND A.CompanySeq = @CompanySeq  
       AND ISNULL(B.ToolSeq,0) <> 0 
       AND EXISTS (SELECT 1 FROM #Tool WHERE ToolSeq = B.ToolSeq) 
    
    
    
    

    
    CREATE TABLE #ToolSeq
    (
        IDX_NO      INT IDENTITY, 
        ToolSeq     INT
    ) 
    INSERT INTO #ToolSeq
    SELECT ToolSeq FROM #Temp GROUP BY ToolSeq ORDER BY ToolSeq 
    
    --select * from #ToolSeq 
    CREATE TABLE #UserDefine ( IDX_NO INT IDENTITY, ToolSeq INT, Title NVARCHAR(100), MngValText NVARCHAR(100) )
    
    
    DECLARE @ToolSeq        INT, 
            @DefineUnitSeq  INT, 
            @Cnt            INT, 
            @CntSub         INT, 
            @Count          INT 
    DECLARE @Sql NVARCHAR(MAX) 
    
    
    IF EXISTS (SELECT 1 FROM #ToolSeq)
    BEGIN 
        SELECT @Cnt = 1 
        
        WHILE ( 1 = 1 ) -- 모든 설비 적용하기 
        BEGIN
            
            SELECT @ToolSeq = A.ToolSeq, 
                   @DefineUnitSeq = UMToolKind 
              FROM #ToolSeq AS A 
              LEFT OUTER JOIN _TPDTool AS B ON ( B.CompanySeq = @CompanySeq AND B.ToolSeq = A.ToolSeq ) 
             WHERE IDX_NO = @Cnt 
                
           
            TRUNCATE TABLE #UserDefine
            INSERT INTO #UserDefine(Title, MngValText, ToolSeq)
            SELECT A.Title,  
                   ISNULL(B.MngValText,'') AS MngValText, 
                   @ToolSeq
              FROM _TCOMUserDefine AS A WITH(NOLOCK) 
              LEFT OUTER JOIN _TPDToolUserDefine AS B ON A.CompanySeq = B.CompanySeq AND A.TitleSerl = B.MngSerl AND B.ToolSeq = @ToolSeq
             WHERE A.CompanySeq     = @CompanySeq  
               AND A.TableName      = '_TDAUMajor_6009'  
               AND A.DefineUnitSeq  = @DefineUnitSeq 
            
            
            
            
                SELECT @Sql = '' 
                
                SELECT @Count = 1 
                
                WHILE ( 1 = 1 ) -- 제원 가로로 가공 
                BEGIN
                    
                    SELECT @Sql = (SELECT 'UPDATE A
                                              SET TitleName' + CONVERT(NVARCHAR(10),@Count) + ' = B.Title, 
                                                  Data' + CONVERT(NVARCHAR(10),@Count) + ' = B.MngValText
                                             FROM #Temp AS A 
                                             JOIN #UserDefine AS B ON ( B.ToolSeq = A.ToolSeq ) 
                                            WHERE B.IDX_NO = '+ CONVERT(NVARCHAR(10),@Count)
                                  )
                    
                
                    
                    
      
                    EXEC (@Sql)
                    
                    IF @Count = (SELECT MAX(IDX_NO) FROM #UserDefine)
                    BEGIN
                        BREAK 
                    END 
                    ELSE 
                    BEGIN
                        SELECT @Count = @Count + 1 
                    END 
                END 
            
            IF @Cnt = (SELECT MAX(IDX_NO) FROM #ToolSeq)
            BEGIN
                BREAK 
            END 
            ELSE 
            BEGIN
                SELECT @Cnt = @Cnt + 1 
            END 
        END 
    END 
    
    SELECT (SELECT CompanyName FROM _TCACompany WHERE CompanySeq = @CompanySeq) AS CompanyName, 
           A.WorkTypeName, 
           A.AccUnitName, 
           D.FactUnitName, 
           C.MinorName AS ToolKindName, 
           A.ToolName, 
           A.ToolNo, 
           A.ToolSeq, 
           ISNULL(TitleName1,'') AS TitleName1,
           ISNULL(TitleName2,'') AS TitleName2,
           ISNULL(TitleName3,'') AS TitleName3,
           ISNULL(TitleName4,'') AS TitleName4,
           ISNULL(TitleName5,'') AS TitleName5,
           ISNULL(TitleName6,'') AS TitleName6,
           ISNULL(TitleName7,'') AS TitleName7,
           ISNULL(TitleName8,'') AS TitleName8,
           ISNULL(TitleName9,'') AS TitleName9,
           ISNULL(TitleName10,'') AS TitleName10,
           ISNULL(TitleName11,'') AS TitleName11,
           ISNULL(TitleName12,'') AS TitleName12,
           ISNULL(TitleName13,'') AS TitleName13,
           ISNULL(TitleName14,'') AS TitleName14,
           ISNULL(TitleName15,'') AS TitleName15,
           ISNULL(TitleName16,'') AS TitleName16,
           ISNULL(TitleName17,'') AS TitleName17,
           ISNULL(TitleName18,'') AS TitleName18,
           ISNULL(TitleName19,'') AS TitleName19,
           ISNULL(TitleName20,'') AS TitleName20,
           ISNULL(TitleName21,'') AS TitleName21,
           ISNULL(Data1,'') AS Data1, 
           ISNULL(Data2,'') AS Data2, 
           ISNULL(Data3,'') AS Data3, 
           ISNULL(Data4,'') AS Data4, 
           ISNULL(Data5,'') AS Data5, 
           ISNULL(Data6,'') AS Data6, 
           ISNULL(Data7,'') AS Data7, 
           ISNULL(Data8,'') AS Data8, 
           ISNULL(Data9,'') AS Data9, 
           ISNULL(Data10,'') AS Data10, 
           ISNULL(Data11,'') AS Data11, 
           ISNULL(Data12,'') AS Data12, 
           ISNULL(Data13,'') AS Data13, 
           ISNULL(Data14,'') AS Data14, 
           ISNULL(Data15,'') AS Data15, 
           ISNULL(Data16,'') AS Data16, 
           ISNULL(Data17,'') AS Data17, 
           ISNULL(Data18,'') AS Data18, 
           ISNULL(Data19,'') AS Data19, 
           ISNULL(Data20,'') AS Data20, 
           ISNULL(Data21,'') AS Data21, 
           A.QryDate, 
           A.WorkName, 
           A.WorkContents, 
           A.ReqEmpName, 
           A.ReqDeptName, 
           A.WorkOperName, 
           A.EmpName, 
           CASE WHEN TitleName1 IS NULL THEN '1' ELSE '0' END Row1, 
           CASE WHEN TitleName4 IS NULL THEN '1' ELSE '0' END Row2, 
           CASE WHEN TitleName7 IS NULL THEN '1' ELSE '0' END Row3, 
           CASE WHEN TitleName10 IS NULL THEN '1' ELSE '0' END Row4, 
           CASE WHEN TitleName13 IS NULL THEN '1' ELSE '0' END Row5, 
           CASE WHEN TitleName16 IS NULL THEN '1' ELSE '0' END Row6, 
           CASE WHEN TitleName19 IS NULL THEN '1' ELSE '0' END Row7
    
      FROM #Temp AS A 
      LEFT OUTER JOIN _TPDTool AS B ON ( B.CompanySeq = @CompanySeq AND B.ToolSeq = A.ToolSeq ) 
      LEFT OUTER JOIN _TDAUMinor AS C ON ( C.CompanySeq = @CompanySeq AND C.MinorSeq = B.UMToolKind ) 
      OUTER APPLY (SELECT TOP 1 Z.FactUnitName 
                     FROM _TDAFactUnit AS Z 
                    WHERE Z.FactUnit = A.AccUnitSeq 
                  ) AS D 
                    
                     
                     
      
    
    RETURN  
go

exec KPX_SEQToolWorkListCHEPrint @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ToolSeq>479</ToolSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ToolSeq>446</ToolSeq>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>3</IDX_NO>
    <DataSeq>3</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ToolSeq>443</ToolSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026691,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1021376