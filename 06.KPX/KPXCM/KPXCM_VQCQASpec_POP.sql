IF OBJECT_ID('KPXCM_VQCQASpec_POP') IS NOT NULL 
    DROP VIEW KPXCM_VQCQASpec_POP 
GO 

-- v2016.11.03

-- 검사규격 by이재천 
CREATE VIEW KPXCM_VQCQASpec_POP 
AS 
    
    SELECT DISTINCT 
           Q.QCType,    
           Q.QCTypeName,    
           S.TestItemSeq,    
           I.TestItemName,    
           I.InTestItemName,    
           N.QAAnalysisType,    
           N.QAAnalysisTypeName, 
           N.QAAnalysisTypeNo,   
           S.SMInputType,    
           R.MinorName AS SMInputTypeName,    
           S.LowerLimit,    
           S.UpperLimit,    
           U.QCUnit,    
           U.QCUnitName,    
           A.WorkOrderSeq, 
           A.WorkOrderSerl, 
           '0' AS IsSave,    
           S.Sort,    
           S.Serl,
           Q.Sort AS NSort
      FROM _TPDSFCWorkOrder                     AS A  WITH(NOLOCK)
      Left Outer Join _TPDMPSDailyProdPlan      AS A1 WITH(NOLOCK) ON ( A.CompanySeq = A1.CompanySeq And A.ProdPlanSeq = A1.ProdPlanSeq ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCType    AS Q  WITH(NOLOCK) ON ( Q.CompanySeq = 2      
                                                                    AND Q.ProcQC = 1000498001    
                                                                    AND Q.QCType IN (SELECT DISTINCT QCType     
                                                                                       FROM KPX_TQCQASpec     
                                                                                      WHERE CompanySeq  = 2    
                                                                                        AND ItemSeq     = Case when Isnull(convert(Int,A1.WorkCond5),0) = 0 or A.FactUnit <> 3 then A.GoodItemSeq
																								               else convert(Int,A1.WorkCond5)
																											   end
																				    )    
                                                                       )
      LEFT OUTER JOIN KPX_TQCQASpec           AS S WITH(NOLOCK) ON ( S.CompanySeq = Q.CompanySeq    
                                                                 AND S.QCType = Q.QCType    
                                                                 AND S.ItemSeq = Case when Isnull(convert(Int,A1.WorkCond5),0) = 0 or A.FactUnit <> 3 then A.GoodItemSeq
																					else convert(Int,A1.WorkCond5)
																					end
                                                                 AND (CASE WHEN A.FactUnit = 1 THEN A.WorkCond1 ELSE A.WorkOrderDate END) BETWEEN S.SDate AND S.EDate  
                                                                   )
      LEFT OUTER JOIN KPX_TQCQATestItems      AS I WITH(NOLOCK) ON ( I.CompanySeq = S.CompanySeq AND I.TestItemSeq = S.TestItemSeq ) 
      LEFT OUTER JOIN KPX_TQCQAAnalysisType   AS N WITH(NOLOCK) ON ( N.CompanySeq = S.CompanySeq AND N.QAAnalysisType = S.QAAnalysisType ) 
      LEFT OUTER JOIN KPX_TQCQAProcessQCUnit  AS U WITH(NOLOCK) ON ( U.CompanySeq = S.CompanySeq AND U.QCUnit = S.QCUnit ) 
      LEFT OUTER JOIN _TDASMinor              AS R WITH(NOLOCK) ON ( R.CompanySeq = S.CompanySeq AND R.MinorSeq = S.SMInputType ) 
     WHERE A.CompanySeq = 2    
       AND A.FactUnit = 3 
    

GO 
SELECT * FROM KPXCM_VQCQASpec_POP WHERE WorkOrderSeq = 207717 
