IF OBJECT_ID('KPXHD_SPDBizUnitCompany') IS NOT NULL 
    DROP PROC KPXHD_SPDBizUnitCompany
GO 

-- v2016.03.22 

-- 경영보고 사업부문 CodeHelp by이재천 
CREATE PROC dbo.KPXHD_SPDBizUnitCompany  
    @WorkingTag     NVARCHAR(1),                                  
    @LanguageSeq    INT,                                  
    @CodeHelpSeq    INT,                                  
    @DefQueryOption INT,                
    @CodeHelpType   TINYINT,                                  
    @PageCount      INT = 20,                       
    @CompanySeq     INT = 1,                                 
    @Keyword        NVARCHAR(200) = '',                                  
    @Param1         NVARCHAR(50) = 0,       
    @Param2         NVARCHAR(50) = '',       
    @Param3         NVARCHAR(50) = '',                      
    @Param4         NVARCHAR(50) = ''         
          
AS          
    SET ROWCOUNT @PageCount                
    
    CREATE TABLE #Minor 
    (
        CompanySeq      INT, 
        MinorName       NVARCHAR(100), 
        MinorSeq        INT 
    )
    
    IF @Param2 = '1'
    BEGIN
        INSERT INTO #Minor ( CompanySeq, MinorName, MinorSeq ) 
        -- KPXGC 
        SELECT A.CompanySeq, A.MinorName, A.MinorSeq 
          FROM KPXERP.._TDAUMinor       AS A 
         WHERE A.Majorseq = 1011113 
           AND A.CompanySeq = 1 
        
        UNION ALL 
        -- KPXCM
        SELECT A.CompanySeq, A.MinorName, A.MinorSeq 
          FROM KPXCM.._TDAUMinor       AS A 
         WHERE A.Majorseq = 1011113 
           AND A.CompanySeq = 2
        
        UNION ALL 
        -- KPXLS
        SELECT A.CompanySeq, A.MinorName, A.MinorSeq 
          FROM KPXLS.._TDAUMinor       AS A 
         WHERE A.Majorseq = 1011113 
           AND A.CompanySeq = 3 
        
        UNION ALL 
        -- KPXHD
        SELECT A.CompanySeq, A.MinorName, A.MinorSeq 
          FROM KPXHD.._TDAUMinor       AS A 
         WHERE A.Majorseq = 1011113 
           AND A.CompanySeq = 4  
    END 
    ELSE
    BEGIN 
        INSERT INTO #Minor ( CompanySeq, MinorName, MinorSeq ) 
        -- KPXGC 
        SELECT A.CompanySeq, A.MinorName, A.MinorSeq 
          FROM KPXERP.._TDAUMinor       AS A 
          JOIN KPXERP.._TDAUMinorValue  AS B ON ( B.CompanySeq = A.CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000003 AND ISNULL(B.ValueText,'0') = '0' ) 
         WHERE A.Majorseq = 1010558 
           AND A.CompanySeq = 1 
        
        UNION ALL 
        -- KPXCM
        SELECT A.CompanySeq, A.MinorName, A.MinorSeq 
          FROM KPXCM.._TDAUMinor       AS A 
          JOIN KPXCM.._TDAUMinorValue  AS B ON ( B.CompanySeq = A.CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000003 AND ISNULL(B.ValueText,'0') = '0' ) 
         WHERE A.Majorseq = 1010558 
           AND A.CompanySeq = 2
        
        UNION ALL 
        -- KPXLS
        SELECT A.CompanySeq, A.MinorName, A.MinorSeq 
          FROM KPXLS.._TDAUMinor       AS A 
          JOIN KPXLS.._TDAUMinorValue  AS B ON ( B.CompanySeq = A.CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000003 AND ISNULL(B.ValueText,'0') = '0' ) 
         WHERE A.Majorseq = 1010558 
           AND A.CompanySeq = 3 
        
        UNION ALL 
        -- KPXHD
        SELECT A.CompanySeq, A.MinorName, A.MinorSeq 
          FROM KPXHD.._TDAUMinor       AS A 
          JOIN KPXHD.._TDAUMinorValue  AS B ON ( B.CompanySeq = A.CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000003 AND ISNULL(B.ValueText,'0') = '0' ) 
         WHERE A.Majorseq = 1010558 
           AND A.CompanySeq = 4  
    END 
    --*/
            
    SELECT * FROM #Minor WHERE CompanySeq = CONVERT(INT,@Param1) 
            
RETURN    
