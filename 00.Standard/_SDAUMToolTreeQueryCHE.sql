
IF OBJECT_ID('_SDAUMToolTreeQueryCHE') IS NOT NULL 
    DROP PROC _SDAUMToolTreeQueryCHE
GO 

-- v2014.10.06 

/************************************************************      
��  �� - ������ Ʈ�� ��ȸ    
�ۼ��� - 2011/03/18    
�ۼ��� - shpark    
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
            @ToolNoQ    NVARCHAR(100) -- �߰� by ������    
              
        EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument        
          
      SELECT @FactUnit    = ISNULL(LTRIM(RTRIM(FactUnit)),0),    
            @ToolNoQ = ISNULL(ToolNoQ, '')    
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1',@xmlFlags)       
       WITH (FactUnit     INT,    
            ToolNoQ NVARCHAR(100))      
      /***************************************************************************************    
     Seq   : ��� ������ ��ȣ    
     ParentSeq : �θ��� Seq    
     NodeName : �̹����� ���� ������ �⺻�̹����� ����Ѵ�.    
                                (TreeNode �� �ѱ�� ���� �̹����� ���� open�� close�϶�����ϴ�  TreeNode_O.png, TreeNode_C.png �� �־�� �Ѵ�.)    
     IsFile  : ������ �ƴ� ���Ͽ���(�ǹ� ���� ��� 0���� ������.)    
     Sort  : �������� ����(�θ��������� 1���� �����Ѵ�.)    
     Level  : ����� ����(��Ʈ���� 1�̰� ���� 1�� �����Ѵ�.)    
         (Sort, �� Level�� 0�� ��ȸ������ Ʈ����带 ������ Ʈ������Ÿ�� �����Ҷ� ��Ʈ���� �̰����� �ڵ����� ä���� �����Ѵ�.)    
     ��������ǰ�: Ʈ���� �����ϸ� ������ Row�� ��簪����  �����Ѵ�. DataSet���� �����Ѵ�.    
     ***************************************************************************************/    
      
     SELECT  A.UMToolKind        AS Seq,    
             A.UpperUMToolKind   AS ParentSeq,    
             CASE WHEN A.UMToolKind = 9999999 THEN '����������������' ELSE ISNULL(B.MinorName,'') END AS NodeName,    
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
             '1'             AS IsTool,   -- ���񿩺�    
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
            IsTool,   -- ���񿩺�    
            FactUnit,    
            FactUnitName    
       FROM #Result AS A  
      ORDER BY Level, Sort        
            
     RETURN 
    
/*************************************************************************************************/      
/*************************************************************************************************/      
