IF OBJECT_ID('hencom_VPNPalnReplaceRateMonth') IS NOT NULL 
    DROP VIEW hencom_VPNPalnReplaceRateMonth
GO 

-- v2017.04.25 

/***********************************  
사업계획  
-월별치환율 
2016.11.15   
by 박수영  
************************************/  
CREATE VIEW hencom_VPNPalnReplaceRateMonth   
AS 
    SELECT  M.CompanySeq, 
            M.DeptSeq, 
            M.PlanSeq, 
            B.StYM,
            M.ItemSeq,  
           CONVERT(DECIMAL(19,5),(M.C1 * B.C1) / 100 ) AS C1,  
           CONVERT( DECIMAL(19,5),(M.C2 * B.C2) / 100) AS C2,  
           CONVERT(DECIMAL(19,5), (M.C3 * B.C3) / 100 ) AS C3,  
           CONVERT(DECIMAL(19,5), (M.C4 * B.C4) / 100 ) AS C4,  
           CONVERT(DECIMAL(19,5), (M.C5 * B.C5) / 100 ) AS C5,  
           CONVERT(DECIMAL(19,5), (M.C6 * B.C6) / 100 ) AS C6,  
           CONVERT(DECIMAL(19,5), (M.S1 * B.S1) / 100 ) AS S1,  
           CONVERT(DECIMAL(19,5), (M.S2 * B.S2) / 100 ) AS S2,  
           CONVERT(DECIMAL(19,5), (M.S3 * B.S3) / 100 ) AS S3,  
           CONVERT(DECIMAL(19,5), (M.S4 * B.S4) / 100 ) AS S4,  
           CONVERT(DECIMAL(19,5), (M.G1 * B.G1) / 100) AS G1,  
           CONVERT(DECIMAL(19,5), (M.G2 * B.G2) / 100) AS G2,  
           CONVERT(DECIMAL(19,5), (M.G3 * B.G3) / 100) AS G3,  
           CONVERT(DECIMAL(19,5), (M.G4 * B.G4) / 100) AS G4,  
           CONVERT(DECIMAL(19,5), (M.A1 )) AS A1,  
           CONVERT(DECIMAL(19,5), (M.A2 )) AS A2,  
           CONVERT(DECIMAL(19,5), (M.A3 )) AS A3,  
           CONVERT(DECIMAL(19,5), (M.A4 )) AS A4,  
           CONVERT(DECIMAL(19,5), (M.A5 )) AS A5,  
           CONVERT(DECIMAL(19,5), (M.A6 )) AS A6,  
           CONVERT(DECIMAL(19,5), (M.A7 )) AS A7,  
           CONVERT(DECIMAL(19,5), (M.W1 * B.W1) / 100) AS W1,  
           CONVERT(DECIMAL(19,5), (M.W2 * B.W2) / 100) AS W2,  
           CONVERT(DECIMAL(19,5), (M.W3 * B.W3) / 100) AS W3 
FROM ( 
    SELECT
    B.CompanySeq ,
    B.MixSeq,
    B.DeptSeq,  
    B.PlanSeq,  
    B.ItemSeq,  
    B.C1 + B.C2 + B.C3 + B.C4 + B.C5 + B.C6 AS C1   ,
    B.C1 + B.C2 + B.C3 + B.C4 + B.C5 + B.C6 AS C2   , 
    B.C1 + B.C2 + B.C3 + B.C4 + B.C5 + B.C6 AS C3   ,
    B.C1 + B.C2 + B.C3 + B.C4 + B.C5 + B.C6 AS C4   ,
    B.C1 + B.C2 + B.C3 + B.C4 + B.C5 + B.C6 AS C5   ,
    B.C1 + B.C2 + B.C3 + B.C4 + B.C5 + B.C6 AS C6   ,
    B.S1 + B.S2 + B.S3 + B.S4 AS S1,
    B.S1 + B.S2 + B.S3 + B.S4 AS S2,
    B.S1 + B.S2 + B.S3 + B.S4 AS S3,
    B.S1 + B.S2 + B.S3 + B.S4 AS S4,
    B.G1 + B.G2 + B.G3 + B.G4 AS G1,
    B.G1 + B.G2 + B.G3 + B.G4 AS G2,
    B.G1 + B.G2 + B.G3 + B.G4 AS G3,
    B.G1 + B.G2 + B.G3 + B.G4 AS G4,
    B.A1 AS A1, 
    B.A2 AS A2,
    B.A3 AS A3,
    B.A4 AS A4,
    B.A5 AS A5,
    B.A6 AS A6,
    B.A7 AS A7,
    B.W1 + B.W2 + B.W3 AS W1,
    B.W1 + B.W2 + B.W3 AS W2,
    B.W1 + B.W2 + B.W3 AS W3
    FROM hencom_TPNQCStMix AS B WITH(NOLOCK)    
) AS M
LEFT OUTER JOIN hencom_TPNQCReplaceRate AS B ON B.CompanySeq = M.CompanySeq 
                                        AND B.DeptSeq = M.DeptSeq  
                                        AND B.PlanSeq = M.PlanSeq

