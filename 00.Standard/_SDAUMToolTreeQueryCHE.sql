
IF OBJECT_ID('_SDAUMToolTreeQueryCHE') IS NOT NULL 
    DROP PROC _SDAUMToolTreeQueryCHE
GO 

-- v2014.10.06 

/************************************************************      
설  명 - 설비등록 트리 조회    
작성일 - 2011/03/18    
작성자 - shpark    
************************************************************/      
CREATE PROC _SDAUMToolTreeQueryCHE      
     @xmlDocument    NVARCHAR(MAX),      
     @xmlFlags       INT = 0,      
     @ServiceSeq     INT = 0,      
     @WorkingTag     NVARCHAR(10) = '',      
     @CompanySeq     INT = 0,      
     @LanguageSeq    INT = 1,      
     @UserSeq        INT = 0,      
     @PgmSeq         INT = 0      
 AS      
    DECLARE @docHandle  INT,    
            @FactUnit   INT,    
            @ToolNoQ    NVARCHAR(100) -- 추가 by 이재현    
              
        EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument        
          
      SELECT @FactUnit    = ISNULL(LTRIM(RTRIM(FactUnit)),0),    
            @ToolNoQ = ISNULL(ToolNoQ, '')    
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1',@xmlFlags)       
       WITH (FactUnit     INT,    
            ToolNoQ NVARCHAR(100))      
      /***************************************************************************************    
     Seq   : 노드 고유의 번호    
     ParentSeq : 부모의 Seq    
     NodeName : 이미지명 빈값을 보내면 기본이미지를 사용한다.    
                                (TreeNode 를 넘기면 실제 이미지는 폴더 open과 close일때사용하는  TreeNode_O.png, TreeNode_C.png 가 있어야 한다.)    
     IsFile  : 폴더가 아닌 파일여부(의미 없는 경우 0으로 보낸다.)    
     Sort  : 폴더들의 순서(부모폴더마다 1부터 시작한다.)    
     Level  : 노드의 레벨(루트노드는 1이고 이후 1씩 증가한다.)    
         (Sort, 와 Level은 0을 조회하한후 트리노드를 편집후 트리데이타를 수집할때 컨트롤이 이값들을 자동으로 채워서 리턴한다.)    
     사용자정의값: 트리를 선택하면 선택한 Row의 모든값들을  리턴한다. DataSet으로 리턴한다.    
     ***************************************************************************************/    
      
     SELECT  A.UMToolKind        AS Seq,    
             A.UpperUMToolKind   AS ParentSeq,    
             CASE WHEN A.UMToolKind = 9999999 THEN '설비제원유형내역' ELSE ISNULL(B.MinorName,'') END AS NodeName,    
             '0'         AS IsFile,    
             ''          AS NodeImg,    
             A.Sort      AS Sort,    
             A.Level     AS Level,    
             ''          AS UMToolKindName,    
             ''          AS ToolNo,    
             '0'         AS IsTool,    
             0           AS FactUnit,    
             ''          AS FactUnitName    
       INTO #Result  
       FROM _TDAUMToolKindTreeCHE AS A WITH (NOLOCK) LEFT OUTER JOIN _TDAUMinor AS B    
                                                         ON A.CompanySeq = B.CompanySeq    
                                                        AND A.UMToolKind = B.MinorSeq    
                                                        ANd B.MajorSeq   = 6009    
                                                        --JOIN _TPDTool AS C    
                                                        -- ON A.CompanySeq = C.CompanySeq    
                                                        --ANd A.UMToolKind = C.UMToolKind    
       WHERE A.CompanySeq = @CompanySeq    
     UNION ALL    
     SELECT  C.ToolSeq       AS Seq,    
             A.UMToolKind    AS ParentSeq,    
             C.ToolNo        AS NodeName,    
             '1'             AS IsFile,    
             'FSFormIsSlip'  AS NodeImg,    
             A.Sort          AS Sort,    
             A.Level + 1     AS Level,    
             B.MinorName     AS UMToolKindName,    
             C.ToolName      AS ToolNo,    
             '1'             AS IsTool,   -- 설비여부    
             ISNULL(C.FactUnit,0)        AS FactUnit,    
             ISNULL(D.FactUnitName,'')   AS FactUnitName    
       FROM _TDAUMToolKindTreeCHE AS A WITH (NOLOCK) LEFT OUTER JOIN _TDAUMinor AS B     
                                                         ON A.CompanySeq = B.CompanySeq    
                                                        AND A.UMToolKind = B.MinorSeq    
                                                        ANd B.MajorSeq   = 6009    
                                                       JOIN _TPDTool AS C    
                                     ON A.CompanySeq = C.CompanySeq    
                                                          ANd A.UMToolKind = C.UMToolKind    
                                                       LEFT OUTER JOIN _TDAFactUnit AS D    
                                                         ON A.CompanySeq = D.CompanySeq    
                                                        AND C.FactUnit   = D.FactUnit    
      WHERE A.CompanySeq = @CompanySeq     
        AND (@FactUnit = 0 OR C.FactUnit = @FactUnit)    
        AND (@ToolNoQ = '' OR C.ToolNo LIKE @ToolNoQ + '%')    
        
        
     SELECT Seq,    
            ParentSeq,    
            NodeName,    
            IsFile,    
            NodeImg,    
            CASE WHEN Level < 4 THEN A.Sort ELSE DENSE_RANK() OVER (PARTITION BY ParentSeq,Level ORDER BY FactUnit,NodeName,ToolNo) END AS Sort,   
            --Sort,   
            Level,    
            UMToolKindName,    
            ToolNo,    
            IsTool,   -- 설비여부    
            FactUnit,    
            FactUnitName    
       FROM #Result AS A  
      ORDER BY Level, Sort        
            
     RETURN 
    
/*************************************************************************************************/      
/*************************************************************************************************/      
