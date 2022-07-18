IF OBJECT_ID('KPXLS_SCACodeHelpCOALotNo') IS NOT NULL 
    DROP PROC KPXLS_SCACodeHelpCOALotNo
GO 

-- v2015.12.23 

/*************************************************************************************************    
PROCEDURE    - KPX_SCACodeHelpCOALotNo    
DESCRIPTION - CodeHellp 정보를 _TLGLotMaster 에서 조회한다.    
작  성  일 - 2009년 3월    
수  정  일 -    
*************************************************************************************************/    
CREATE PROC KPXLS_SCACodeHelpCOALotNo

    @WorkingTag         NVARCHAR(1),    
    @LanguageSeq        INT,    
    @CodeHelpSeq        INT,    
    @DefQueryOption     INT, -- 2: direct search    
    @CodeHelpType       TINYINT,    
    @PageCount          INT = 20,    
    @CompanySeq         INT = 1,    
    @Keyword            NVARCHAR(50) = '',    
    @Param1             NVARCHAR(50) = '',    
    @Param2             NVARCHAR(50) = '',    
    @Param3             NVARCHAR(50) = '',    
    @Param4             NVARCHAR(50) = '',      
    @SubConditionSql    NVARCHAR(500)= '' -- 20130205 박성호 추가     
AS    
	
	DECLARE @WHSeq   INT,    
            @StdDate NCHAR(8)    
    
    SET ROWCOUNT @PageCount      
    
     CREATE TABLE #temp 
    (
        LotNo       nvarchar(100), 
        ItemName    nvarchar(100), 
        ItemNo      nvarchar(100), 
        UnitName    nvarchar(100), 
        ItemSeq     int, 
        LotSeq      nvarchar(100)
    ) 
    
    
    IF NOT EXISTS (  
    
    SELECT 1 
      FROM KPX_TQCTestResult AS A 
      JOIN KPX_TQCTestResultItem AS B ON ( b.companyseq = a.companyseq and b.qcseq = a.qcseq ) 
     WHERE a.companyseq = @CompanySeq
       AND a.lotno LIKE  @Keyword + '%' 
       --AND A.SMTestResult NOT IN (1010418002)  
       --and a.workcenterseq = 1 
       AND (ISNULL(@Param1,0)=0 OR A.ItemSeq = @Param1)
       AND b.qctype in ( 12 ) 
       AND b.SMTestResult <> '0'
       AND ISSpecial = 0  
     GROUP BY B.qctype, b.testItemSeq, B.QAAnalysisType, B.QCUnit
     HAVING MIN(b.SMTestResult) = '6035004'
       ) 
    BEGIN
        
        INSERT INTO #temp ( LotNo, ItemName, ItemNo, UnitName, ItemSeq, LotSeq ) 
        SELECT DISTINCT 
               R.LotNo,  
               M.ItemName,  
               M.ItemNo,  
               U.UnitName,  
               M.ItemSeq,  
               R.LotNo      AS LotSeq
          FROM KPX_TQCTestResult AS R  
               JOIN KPX_TQCTestResultItem AS I WITH(NOLOCK) ON I.CompanySeq = R.CompanySeq  
                                                           AND I.QCSeq = R.QCSeq  
               LEFT OUTER JOIN _TDAItem AS M WITH(NOLOCK) ON M.CompanySeq = R.CompanySeq  
                                                         AND M.ItemSeq = R.ItemSeq  
               LEFT OUTER JOIN _TDAUnit AS U WITH(NOLOCK) ON U.CompanySeq = M.CompanySeq  
                                                         AND U.UnitSeq = M.UnitSeq  
         WHERE R.CompanySeq= @CompanySeq   
           AND R.LotNo LIKE  @Keyword + '%' 
           -- AND R.SMTestResult NOT IN (1010418002)  
           
           AND (ISNULL(@Param2,0)=0 OR (CASE WHEN ISNULL(R.QCType,0) = 0 THEN I.QCType  
                                        ELSE R.QCType END) =@Param2)   
         AND (ISNULL(@Param1,0)=0 OR R.ItemSeq = @Param1)
         AND I.qctype in ( 12 ) 
         AND I.SMTestResult <> '6035004'   AND I.SMTestResult <> 0      
         AND R.LotNo NOT IN  ( SELECT LotNo       
                                 FROM KPX_TQCTestResult AS A       
                                 JOIN KPX_TQCTestResultItem AS B ON ( b.companyseq = a.companyseq and b.qcseq = a.qcseq )       
                                WHERE a.companyseq = @CompanySeq
                                  AND (ISNULL(@Param1,0)=0 OR A.ItemSeq = @Param1)
                                  AND b.qctype in ( 12 )       
                                  AND b.SMTestResult <> '0'      
                                  AND ISSpecial = 0  
                             GROUP BY  B.qctype, b.testItemSeq, B.QAAnalysisType, B.QCUnit  , LotNo   
                               HAVING MIN(b.SMTestResult) = '6035004' )  
        
        SELECT * FROM #temp 

    END 
    ELSE
    BEGIN
        SELECT * FROM #temp 
    END 
    
    SET ROWCOUNT 0    

    
RETURN    

GO


