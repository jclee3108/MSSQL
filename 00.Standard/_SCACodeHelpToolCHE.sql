
IF OBJECT_ID('_SCACodeHelpToolCHE') IS NOT NULL 
    DROP PROC _SCACodeHelpToolCHE
GO 

-- v2014.10.06 

/*************************************************************************************************                        
 PROCEDURE    - _SCACodeHelpToolCHE             
 작  성  일 - 2011년 04월 29일                        
 수  정  일 - 2011년 04월 29일         
 작  성  자 - 신용식  
 *************************************************************************************************/                 
 CREATE PROCEDURE _SCACodeHelpToolCHE
     @WorkingTag     NVARCHAR(1),                                
     @LanguageSeq    INT,                                
     @CodeHelpSeq    INT,                                
     @DefQueryOption INT, -- 2: direct search                                
     @CodeHelpType   TINYINT,                                
     @PageCount      INT = 20,                     
     @CompanySeq     INT = 1,                               
     @Keyword        NVARCHAR(50) = '',                                
     @Param1         NVARCHAR(50) = '',                    
     @Param2         NVARCHAR(50) = '',                    
     @Param3         NVARCHAR(50) = '',                    
     @Param4         NVARCHAR(50) = ''                    
 AS       
    
     DECLARE @WorkCenterSeq  INT ,  
             @AssyItemSeq    INT ,  
             @FactUnit       INT  
--select ISNUMERIC(@Param1)  
    IF @Param1 <> 1006425  
    BEGIN  
          IF ISNUMERIC(@Param1) = 1   
             SELECT @WorkCenterSeq = CONVERT(INT,@Param1)  
         ELSE   
             SELECT @WorkCenterSeq = 0  
          IF ISNUMERIC(@Param2) = 1  
             SELECT @AssyItemSeq = CONVERT(INT,@Param2)  
         ELSE   
             SELECT @AssyItemSeq = 0  
          IF ISNUMERIC(@Param3) = 1  
             SELECT @FactUnit = CONVERT(INT,@Param3)  
         ELSE   
             SELECT @FactUnit = 0  
    END  
    ELSE   
        SELECT @WorkCenterSeq = 0,  
               @AssyItemSeq = 0,  
               @FactUnit = 0  
      
--select @WorkCenterSeq, @AssyItemSeq, @FactUnit  
    
       
     SET ROWCOUNT @PageCount   
                                  
    IF @Param1 <> 1006425             
     SELECT A.ToolName     AS ToolName        ,     
            A.ToolSeq      AS ToolSeq         ,    
            A.ToolNo       AS ToolNo          ,  
            A.Spec         AS Spec            ,  
            B.MinorSeq     AS UMToolKind      ,  
            B.MinorName    AS UMToolKindName  ,  
            CASE D.SMMovePlaceType WHEN 1093001 THEN (SELECT DeptName FROM _TDADept WITH(NOLOCK) WHERE CompanySeq = D.CompanySeq AND DeptSeq = D.MovePlaceSeq)  
                                   WHEN 1093002 THEN (SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = D.CompanySeq AND CustSeq = D.MovePlaceSeq)  
                                   WHEN 1093003 THEN (SELECT WHName FROM _TDAWH WITH(NOLOCK) WHERE CompanySeq = D.CompanySeq AND WHSeq = D.MovePlaceSeq)  
                                   ELSE F.DeptName  
            END            AS PrePlace ,  
            ISNULL((SELECT ValueText FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = A.CompanySeq AND MinorSeq = B.MinorSeq AND Serl = '1001'),'0') AS IsDie , -- 금형여부  
            A.Cavity       AS Cavity          ,  
            E.EmpSeq       AS EmpSeq          ,  
            E.EmpName      AS EmpName         ,  
            F.DeptSeq      AS DeptSeq         ,  
            F.DeptName     AS DeptName        ,  
            A.FactUnit                        ,  
            ISNULL(G.FactUnitName,'')   AS FactUnitName,  
            I.CCtrName AS ActCenterName       ,  
            ISNULL(J.GongjongSeq,0)     AS GongjongSeq ,  
            K.MinorName    AS GongjongName       
       FROM _TPDTool                          AS A WITH(NOLOCK)                          
            LEFT OUTER JOIN _TDAUMinor        AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq   
                                                               AND A.UMToolKind = B.MinorSeq  
              LEFT OUTER JOIN _TPDToolMove      AS D WITH(NOLOCK) ON A.CompanySeq  = D.CompanySeq   
                                                               AND A.ToolSeq    = D.ToolSeq  
            LEFT OUTER JOIN _TDAEmp           AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq   
                                                               AND A.EmpSeq     = E.EmpSeq  
            LEFT OUTER JOIN _TDADept          AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq   
                                                               AND A.DeptSeq    = F.DeptSeq  
            LEFT OUTER JOIN _TDAFactUnit AS G ON A.CompanySeq = G.CompanySeq  
                                             AND A.FactUnit   = G.FactUnit  
            LEFT OUTER JOIN _TPDToolUserDefine AS H ON A.CompanySeq = H.CompanySeq  
                                                   AND A.ToolSeq    = H.ToolSeq       
                                                   AND H.MngSerl    = 1000005         
            LEFT OUTER JOIN _TDACCtr AS I ON H.CompanySeq = I.CompanySeq  
                                         AND H.MngValSeq  = I.CCtrSeq  
            LEFT OUTER JOIN _TDAUMToolKindTreeCHE AS J ON A.CompanySeq = J.CompanySeq  
                                                        AND A.UMToolKind = J.UMToolKind  
            LEFT OUTER JOIN _TDAUMinor              AS K ON J.CompanySeq = K.CompanySeq  
                                                        AND J.GongjongSeq = K.MinorSeq  
                                                        ANd K.MajorSeq   = 6009                                              
      WHERE A.CompanySeq = @CompanySeq                  
        AND (@Keyword = '' OR (ToolName LIKE @Keyword + '%') OR (ToolNo LIKE @Keyword + '%'))  
        AND (D.Serl IS NULL OR D.Serl = (SELECT MAX(Serl) FROM _TPDToolMove WITH(NOLOCK) WHERE CompanySeq = D.CompanySeq AND ToolSeq = D.ToolSeq))  
        AND ((@WorkCenterSeq = 0 AND @AssyItemSeq = 0)  
          OR  A.ToolSeq IN (SELECT EquipSeq FROM _TPDBaseWorkCenterEquip WITH(NOLOCK) WHERE CompanySeq = A.CompanySeq AND WorkCenterSeq = @WorkCenterSeq  
                             UNION  
                            SELECT ToolSeq  FROM _TPDToolAssy            WITH(NOLOCK) WHERE CompanySeq = A.CompanySeq AND ItemSeq = @AssyItemSeq  
                             ))  
         AND (A.FactUnit = @FactUnit OR @FactUnit = 0)  
                                                
    ELSE   
    --select * from #result WHERE toolseq = 494560  
      
     SELECT A.ToolName     AS ToolName        ,     
            A.ToolSeq      AS ToolSeq         ,    
            A.ToolNo       AS ToolNo          ,  
            A.Spec         AS Spec            ,  
            B.MinorSeq     AS UMToolKind      ,  
            B.MinorName    AS UMToolKindName  ,  
            CASE D.SMMovePlaceType WHEN 1093001 THEN (SELECT DeptName FROM _TDADept WITH(NOLOCK) WHERE CompanySeq = D.CompanySeq AND DeptSeq = D.MovePlaceSeq)  
                                   WHEN 1093002 THEN (SELECT CustName FROM _TDACust WITH(NOLOCK) WHERE CompanySeq = D.CompanySeq AND CustSeq = D.MovePlaceSeq)  
                                   WHEN 1093003 THEN (SELECT WHName FROM _TDAWH WITH(NOLOCK) WHERE CompanySeq = D.CompanySeq AND WHSeq = D.MovePlaceSeq)  
                                   ELSE F.DeptName  
            END            AS PrePlace ,  
            ISNULL((SELECT ValueText FROM _TDAUMinorValue WITH(NOLOCK) WHERE CompanySeq = A.CompanySeq AND MinorSeq = B.MinorSeq AND Serl = '1001'),'0') AS IsDie , -- 금형여부  
            A.Cavity       AS Cavity          ,  
            E.EmpSeq       AS EmpSeq          ,  
            E.EmpName      AS EmpName         ,  
            F.DeptSeq      AS DeptSeq         ,  
            F.DeptName     AS DeptName        ,  
            A.FactUnit                        ,  
            ISNULL(G.FactUnitName,'')   AS FactUnitName,  
            I.CCtrName AS ActCenterName       ,  
            ISNULL(J.GongjongSeq,0)     AS GongjongSeq ,  
            K.MinorName    AS GongjongName                    
         FROM _TPDTool                          AS A WITH(NOLOCK)                          
            LEFT OUTER JOIN _TDAUMinor        AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq   
                                                               AND A.UMToolKind = B.MinorSeq  
            LEFT OUTER JOIN _TPDToolMove      AS D WITH(NOLOCK) ON A.CompanySeq = D.CompanySeq   
                                                               AND A.ToolSeq    = D.ToolSeq  
            LEFT OUTER JOIN _TDAEmp           AS E WITH(NOLOCK) ON A.CompanySeq = E.CompanySeq   
                                                               AND A.EmpSeq     = E.EmpSeq  
            LEFT OUTER JOIN _TDADept          AS F WITH(NOLOCK) ON A.CompanySeq = F.CompanySeq   
                                                               AND A.DeptSeq    = F.DeptSeq  
            LEFT OUTER JOIN _TDAFactUnit AS G ON A.CompanySeq = G.CompanySeq  
                                             AND A.FactUnit   = G.FactUnit  
            LEFT OUTER JOIN _TPDToolUserDefine AS H ON A.CompanySeq = H.CompanySeq  
                                                   AND A.ToolSeq    = H.ToolSeq       
                                                   AND H.MngSerl    = 1000005         
            LEFT OUTER JOIN _TDACCtr AS I ON H.CompanySeq = I.CompanySeq  
                                         AND H.MngValSeq  = I.CCtrSeq  
            LEFT OUTER JOIN _TPDToolUserDefine AS H6 ON @CompanySeq   = H6.CompanySeq  
                                                      AND A.ToolSeq     = H6.ToolSeq       
                                                      AND H6.MngSerl     = 1000006  
                                                      AND H6.MngValText  = 'True'  
            LEFT OUTER JOIN _TPDToolUserDefine AS H7 ON @CompanySeq   = H7.CompanySeq  
                                                      AND A.ToolSeq     = H7.ToolSeq       
                                                      AND H7.MngSerl     = 1000007  
                                                      AND H7.MngValText  = 'True'  
            LEFT OUTER JOIN _TDAUMToolKindTreeCHE AS J ON A.CompanySeq = J.CompanySeq  
                                                        AND A.UMToolKind = J.UMToolKind  
            LEFT OUTER JOIN _TDAUMinor              AS K ON J.CompanySeq = K.CompanySeq  
                                                        AND J.GongjongSeq= K.MinorSeq  
                                                        ANd K.MajorSeq   = 6009                                                            
      WHERE A.CompanySeq = @CompanySeq                  
        AND (@Keyword = '' OR (ToolName LIKE @Keyword + '%') OR (ToolNo LIKE @Keyword + '%'))  
        AND (D.Serl IS NULL OR D.Serl = (SELECT MAX(Serl) FROM _TPDToolMove WITH(NOLOCK) WHERE CompanySeq = D.CompanySeq AND ToolSeq = D.ToolSeq))  
        AND ((@WorkCenterSeq = 0 AND @AssyItemSeq = 0)  
          OR  A.ToolSeq IN (SELECT EquipSeq FROM _TPDBaseWorkCenterEquip WITH(NOLOCK) WHERE CompanySeq = A.CompanySeq AND WorkCenterSeq = @WorkCenterSeq  
                             UNION  
                            SELECT ToolSeq  FROM _TPDToolAssy            WITH(NOLOCK) WHERE CompanySeq = A.CompanySeq AND ItemSeq = @AssyItemSeq  
                             ))  
        AND (A.FactUnit = @FactUnit OR @FactUnit = 0)  
        AND (H6.ToolSeq IS NOT NULL OR H7.ToolSeq IS NOT NULL)  
  
     SET ROWCOUNT 0             
                  
RETURN  