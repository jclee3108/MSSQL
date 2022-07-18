IF OBJECT_ID('KPXCM_FQCQASpec_POP') IS NOT NULL 
    DROP FUNCTION KPXCM_FQCQASpec_POP
GO 

-- 2016.05.13 

CREATE FUNCTION KPXCM_FQCQASpec_POP
    (
        @IsMulti        NCHAR(1),       -- 검사내역 IN, OUT, PROC 이면 '1' , 하나씩보면 '0' 
        @Type           NVARCHAR(100), 
        @WorkOrderSeq   INT, 
        @WorkOrderSerl  INT 
    )
RETURNS 
    @ResultTable TABLE
    (
        SMSourceType        INT, 
        SMSourceTypeName    NVARCHAR(100), 
        SMInputType         INT, 
        SMInputTypeName     NVARCHAR(100), 
        LowerLimit          NVARCHAR(100), 
        UpperLimit          NVARCHAR(100), 
        WorkOrderSeq        INT, 
        WorkOrderSerl       INT
        --Seq INT ,
        --Serl int 
    )
 AS 
    BEGIN
        
        DECLARE @SMSourceTypeTable TABLE
        (
            SMSourceType INT 
        )
        
        IF @Type = 'IN' AND @IsMulti = '1' 
        BEGIN
            INSERT INTO @SMSourceTypeTable 
            SELECT 1000522007 -- 수입입고검사 
            UNION ALL 
            SELECT 1000522008 -- 내수납품검사 
        END 
        ELSE IF @Type = 'OUT' AND @IsMulti = '1' 
        BEGIN 
            INSERT INTO @SMSourceTypeTable 
            SELECT 1000522005 -- 출하검사 
        END 
        ELSE IF @Type = 'PROC' AND @IsMulti = '1' 
        BEGIN
            INSERT INTO @SMSourceTypeTable  
            SELECT 1000522006 -- 포장검사 
            UNION ALL 
            SELECT 1000522004 -- 공정검사 
        END IF LEN(@Type) = 10 AND @IsMulti = '0' 
        BEGIN
            INSERT INTO @SMSourceTypeTable 
            SELECT @Type
        END 
        
        
        --INSERT INTO @ResultTable
        --SELECT * , 1 FROM @SMSourceTypeTable 
        
        DECLARE @CompanySeq INT 
        SELECT @CompanySeq = 2  
        
        --/*
        IF EXISTS (
                    SELECT 1 
                      FROM KPX_TQCTestResultItem    AS A 
                      JOIN @SMSourceTypeTable       AS B ON ( B.SMSourceType = A.SMSourceType )
                     WHERE CompanySeq = @CompanySeq 
                       AND SourceSeq = @WorkOrderSeq 
                       AND SourceSerl = @WorkOrderSerl
                  )    
        BEGIN  
        
            INSERT INTO @ResultTable
            (
                SMSourceType        , SMSourceTypeName      , SMInputType           , SMInputTypeName       , LowerLimit            , 
                UpperLimit          , WorkOrderSeq          , WorkOrderSerl         
            )
            SELECT A.SMSourceType, 
                   L.MinorName AS SMSourceTypeName, 
                   J.SMInputType,    
                   K.MinorName AS SMInputTypeName,    
                   J.LowerLimit,    
                   J.UpperLimit, 
                   A.SourceSeq AS WorkOrderSeq, 
                   A.SourceSerl AS WOrkOrderSerl
              FROM KPX_TQCTestResultItem AS A    
              LEFT OUTER JOIN KPX_TQCTestResult      AS AA WITH(NOLOCK) ON A.CompanySeq = AA.CompanySeq    
                                                                       AND A.QCSeq   = AA.QCSeq    
              LEFT OUTER JOIN KPX_TQCQAProcessQCType AS Q WITH(NOLOCK) ON Q.CompanySeq = @CompanySeq    
                                                                       AND Q.QCType = A.QCType    
              LEFT OUTER JOIN KPX_TQCQAAnalysisType  AS B WITH(NOLOCK) ON A.CompanySeq     = B.CompanySeq    
                                                                      AND A.QAAnalysisType = B.QAAnalysisType    
              LEFT OUTER JOIN KPX_TQCQATestItems     AS C WITH(NOLOCK) ON A.CompanySeq     = C.CompanySeq    
                                                                      AND A.TestItemSeq = C.TestItemSeq    
              LEFT OUTER JOIN KPX_TQCTestRequest     AS A2 WITH(NOLOCK) ON AA.CompanySeq = A2.CompanySeq    
                                                                      AND  AA.ReqSeq  = A2.ReqSeq    
              LEFT OUTER JOIN KPX_TQCQASpec          AS J WITH(NOLOCK) ON A.CompanySeq = J.CompanySeq    
                                                                      AND A.QCType  = J.QCType    
                                                                      AND A.QAAnalysisType= J.QAAnalysisType    
                                                                      AND A.TestItemSeq = J.TestItemSeq    
                                                                      AND A.QCUnit  = J.QCUnit     
                                                                      AND AA.ItemSeq  = J.ItemSeq    
                                                                      AND A2.ReqDate BETWEEN J.SDate AND J.EDate    
                                                                    --AND A.TestDate BETWEEN J.SDate AND J.EDate   
              LEFT OUTER JOIN _TDASMinor             AS K WITH(NOLOCK) ON J.CompanySeq = K.CompanySeq        
                                                                      AND J.SMInputType = K.MinorSeq    
              LEFT OUTER JOIN _TDASMinor             AS L WITH(NOLOCK) ON A.CompanySeq = L.CompanySeq    
                                                                      AND A.SMSourceType = L.MinorSeq    
                         JOIN @SMSourceTypeTable     AS E ON ( E.SMSourceType = A.SMSourceType ) 
             WHERE A.CompanySeq = @CompanySeq    
               AND A.SourceSeq = @WorkOrderSeq
               AND A.SourceSerl = @WorkOrderSerl
             --ORDER BY Q.Sort, J.Sort, C.TestItemName, B.QAAnalysisTypeNo, A.RegDate
            
        END     
        ELSE IF EXISTS (SELECT 1 FROM @SMSourceTypeTable)
        BEGIN    
            INSERT INTO @ResultTable
            (
                SMSourceType        , SMSourceTypeName      , SMInputType           , SMInputTypeName       , LowerLimit            , 
                UpperLimit          , WorkOrderSeq          , WorkOrderSerl         
            )
            SELECT DISTINCT 
                   1000522004, 
                   W.MinorName AS SMSourceTypeName, 
                   S.SMInputType,    
                   R.MinorName AS SMInputTypeName,    
                   S.LowerLimit,    
                   S.UpperLimit, 
                   A.WorkOrderSeq AS WorkOrderSeq, 
                   A.WOrkOrderSerl AS WOrkOrderSerl
              FROM _TPDSFCWorkOrder    AS A   with(nolock)
              Left Outer Join _TPDMPSDailyProdPlan   AS A1 With(Nolock) ON A.CompanySeq = A1.CompanySeq And A.ProdPlanSeq = A1.ProdPlanSeq
              LEFT OUTER JOIN KPX_TQCQAProcessQCType AS Q  WITH(NOLOCK) ON Q.CompanySeq = @CompanySeq      
                                                                                   AND Q.ProcQC = 1000498001    
                                                                                   AND Q.QCType IN (SELECT DISTINCT QCType     
                                                                                                      FROM KPX_TQCQASpec     
                                                                                                     WHERE CompanySeq  = @CompanySeq    
                                                                                                       AND ItemSeq     = Case when Isnull(convert(Int,A1.WorkCond5),0) = 0 or A.FactUnit <> 3 then A.GoodItemSeq
                                                                                                                              else convert(Int,A1.WorkCond5)
                                                                                                                               end
                                                                                                   )    
              LEFT OUTER JOIN KPX_TQCQASpec           AS S WITH(NOLOCK) ON S.CompanySeq = Q.CompanySeq    
                                                                       AND S.QCType = Q.QCType    
                                                                       AND S.ItemSeq = Case when Isnull(convert(Int,A1.WorkCond5),0) = 0 or A.FactUnit <> 3 then A.GoodItemSeq
                                                                                            else convert(Int,A1.WorkCond5)
                                                                                            end
                                                                       --AND A.WorkCond1 BETWEEN S.SDate AND S.EDate 
                                                                       -- 2015.09.21 by bgKeum 우레탄 사업부(Gantt 사용사업장)는 WorkCond1로 나머지는 WorkOrderDate로 체크하도록 수정
                                                                       AND (CASE WHEN A.FactUnit = 1 THEN A.WorkCond1 ELSE A.WorkOrderDate END) BETWEEN S.SDate AND S.EDate  
              LEFT OUTER JOIN KPX_TQCQATestItems      AS I WITH(NOLOCK) ON I.CompanySeq = S.CompanySeq    
                                                                       AND I.TestItemSeq = S.TestItemSeq    
              LEFT OUTER JOIN KPX_TQCQAAnalysisType   AS N WITH(NOLOCK) ON N.CompanySeq = S.CompanySeq    
                                                                       AND N.QAAnalysisType = S.QAAnalysisType    
              LEFT OUTER JOIN KPX_TQCQAProcessQCUnit  AS U WITH(NOLOCK) ON U.CompanySeq = S.CompanySeq    
                                                                       AND U.QCUnit = S.QCUnit    
              LEFT OUTER JOIN _TDASMinor              AS R WITH(NOLOCK) ON R.CompanySeq = S.CompanySeq    
                                                                       AND R.MinorSeq = S.SMInputType    
              LEFT OUTER JOIN _TDASMinor              AS W WITH(NOLOCK) ON ( W.CompanySeq = @CompanySeq AND W.MinorSeq = 1000522004 ) 
             WHERE 1=1    
               AND A.CompanySeq = @CompanySeq    
               AND A.WorkOrderSeq = @WorkOrderSeq
               AND A.WorkOrderSerl = @WorkOrderSerl
             --ORDER BY Q.Sort, S.Sort, I.TestItemName, N.QAAnalysisTypeNo  
        END    
        --*/
        RETURN 
    END 
 GO
 SELECT * FROM KPXCM_FQCQASpec_POP('1','PROC','183416','183416')
 
