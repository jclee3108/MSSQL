IF OBJECT_ID('KPXCM_SESMZProdCostInMonListQuery') IS NOT NULL 
    DROP PROC KPXCM_SESMZProdCostInMonListQuery
GO 

-- v2016.06.22 

/************************************************************
 설  명 - D-월별 제조원가현황 : 투입조회  
 작성일 - 2009년 06월 10일
 작성자 - 한 혜 진
************************************************************/
CREATE PROC KPXCM_SESMZProdCostInMonListQuery
 @xmlDocument    NVARCHAR(MAX), -- 화면의 정보를 xml로 전달  
 @xmlFlags       INT = 0, -- 해당 xml의 Type  
 @ServiceSeq     INT = 0, -- 서비스 번호  
 @WorkingTag     NVARCHAR(10)= '', -- WorkingTag  
 @CompanySeq     INT = 1, -- 회사 번호  
 @LanguageSeq    INT = 1, -- 언어 번호  
 @UserSeq        INT = 0, -- 사용자 번호  
 @PgmSeq         INT = 0  -- 프로그램 번호  
  
AS  

DECLARE @docHandle      INT,  
        @CostUnit       INT,
        @CostYY         NCHAR(4),
        @SMCostDiv      INT,
        @RptUnit        INT,
        @SMCostMng      INT,
        @CostMngAmdSeq  INT,
        @PlanYear       NCHAR(4),
        @ItemSeq        INT,
        @QueryKind      INT 

    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument  
    SELECT @CostUnit        = ISNULL(A.CostUnit,0 ),
           @CostYY          = ISNULL(A.CostYY   ,''),
           @RptUnit         = ISNULL(A.RptUnit  ,0 ),
           @SMCostMng       = ISNULL(A.SMCostMng,0 ),
           @CostMngAmdSeq   = ISNULL(A.CostMngAmdSeq,0),
           @PlanYear        = ISNULL(A.PlanYear ,''),
           @ItemSeq         = ISNULL(A.ItemSeq, 0), 
           @QueryKind       = ISNULL(A.QueryKind,0)
           
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)   
      WITH (CostUnit         INT, CostYY     NCHAR(4) ,
            RptUnit         INT, SMCostMng  INT      ,
            CostMngAmdSeq   INT, PlanYear   NCHAR(4) ,
            ItemSeq          INT, QueryKind INT) AS A

    EXEC sp_xml_removedocument @docHandle 
    

    
    IF @QueryKind IN(5548002, 5548003)      
    BEGIN 
        
        CREATE TABLE #Result 
        (
            CostAccSeq      INT, 
            CostAccName     NVARCHAR(100), 
            TotalAmt        DECIMAL(19,5), 
            Mo1Amt          DECIMAL(19,5), 
            Mo2Amt          DECIMAL(19,5), 
            Mo3Amt          DECIMAL(19,5), 
            Mo4Amt          DECIMAL(19,5), 
            Mo5Amt          DECIMAL(19,5), 
            Mo6Amt          DECIMAL(19,5), 
            Mo7Amt          DECIMAL(19,5), 
            Mo8Amt          DECIMAL(19,5), 
            Mo9Amt          DECIMAL(19,5), 
            Mo10Amt         DECIMAL(19,5), 
            Mo11Amt         DECIMAL(19,5), 
            Mo12Amt         DECIMAL(19,5)
        )
    
        INSERT INTO #Result 
        (
            CostAccSeq  , CostAccName   , TotalAmt  , Mo1Amt    , Mo2Amt    , 
            Mo3Amt      , Mo4Amt        , Mo5Amt    , Mo6Amt    , Mo7Amt    , 
            Mo8Amt      , Mo9Amt        , Mo10Amt   , Mo11Amt   , Mo12Amt   
        )
        SELECT B.CostAccSeq,  
               B.CostAccName, 
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '01' THEN A.ProdQty ELSE 0 END) + 
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '02' THEN A.ProdQty ELSE 0 END) + 
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '03' THEN A.ProdQty ELSE 0 END) + 
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '04' THEN A.ProdQty ELSE 0 END) + 
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '05' THEN A.ProdQty ELSE 0 END) + 
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '06' THEN A.ProdQty ELSE 0 END) + 
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '07' THEN A.ProdQty ELSE 0 END) + 
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '08' THEN A.ProdQty ELSE 0 END) + 
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '09' THEN A.ProdQty ELSE 0 END) + 
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '10' THEN A.ProdQty ELSE 0 END) + 
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '11' THEN A.ProdQty ELSE 0 END) + 
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '12' THEN A.ProdQty ELSE 0 END) AS TotalAmt, 
               
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '01' THEN A.ProdQty ELSE 0 END) AS Mo1Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '02' THEN A.ProdQty ELSE 0 END) AS Mo2Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '03' THEN A.ProdQty ELSE 0 END) AS Mo3Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '04' THEN A.ProdQty ELSE 0 END) AS Mo4Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '05' THEN A.ProdQty ELSE 0 END) AS Mo5Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '06' THEN A.ProdQty ELSE 0 END) AS Mo6Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '07' THEN A.ProdQty ELSE 0 END) AS Mo7Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '08' THEN A.ProdQty ELSE 0 END) AS Mo8Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '09' THEN A.ProdQty ELSE 0 END) AS Mo9Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '10' THEN A.ProdQty ELSE 0 END) AS Mo10Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '11' THEN A.ProdQty ELSE 0 END) AS Mo11Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '12' THEN A.ProdQty ELSE 0 END) AS Mo12Amt      
          FROM _TESMCProdFGoodCostResult    AS A WITH(NOLOCK)
                 JOIN _TESMDCostKey         AS K WITH(NOLOCK) ON A.CompanySeq    = K.CompanySeq 
                                                             AND A.CostKeySeq    = K.CostKeySeq  
                 JOIN _TESMBAccount         AS B WITH(NOLOCK) ON A.CompanySeq  = B.CompanySeq
                                                             AND A.CostAccSeq = B.CostAccSeq

         WHERE A.CompanySeq     = @CompanySeq
           AND K.SMCostMng	     = @SMCostMng 
           AND K.CostMngAmdSeq  = @CostMngAmdSeq 
           AND K.RptUnit		 = @RptUnit 
           AND K.PlanYear       = @PlanYear
           AND K.CostYM		 >= RTRIM(@CostYY) + '01' AND K.CostYM <= RTRIM(@CostYY) + '12'  
           AND A.ItemSeq        = @ItemSeq
           AND ( @CostUnit = 0 OR A.CostUnit = @CostUnit)
           AND ( @ItemSeq  = 0 OR A.ItemSeq  = @ItemSeq)     
         GROUP BY B.CostAccSeq, B.CostAccName
    
        IF @QueryKind = 5548003  
        BEGIN  
            DELETE FROM #Result 
            SELECT * FROM #Result   
        END 
    END
    ELSE
    BEGIN
        SELECT B.CostAccSeq,  
               B.CostAccName, 
               SUM(a.ProdCost) AS TotalAmt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '01' THEN ProdCost-RevProcCost ELSE 0 END) AS Mo1Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '02' THEN ProdCost-RevProcCost ELSE 0 END) AS Mo2Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '03' THEN ProdCost-RevProcCost ELSE 0 END) AS Mo3Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '04' THEN ProdCost-RevProcCost ELSE 0 END) AS Mo4Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '05' THEN ProdCost-RevProcCost ELSE 0 END) AS Mo5Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '06' THEN ProdCost-RevProcCost ELSE 0 END) AS Mo6Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '07' THEN ProdCost-RevProcCost ELSE 0 END) AS Mo7Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '08' THEN ProdCost-RevProcCost ELSE 0 END) AS Mo8Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '09' THEN ProdCost-RevProcCost ELSE 0 END) AS Mo9Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '10' THEN ProdCost-RevProcCost ELSE 0 END) AS Mo10Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '11' THEN ProdCost-RevProcCost ELSE 0 END) AS Mo11Amt,      
               SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '12' THEN ProdCost-RevProcCost ELSE 0 END) AS Mo12Amt      
          FROM _TESMCProdFGoodCostResult    AS A WITH(NOLOCK)
                 JOIN _TESMDCostKey         AS K WITH(NOLOCK) ON A.CompanySeq    = K.CompanySeq 
                                                             AND A.CostKeySeq    = K.CostKeySeq  
                 JOIN _TESMBAccount         AS B WITH(NOLOCK) ON A.CompanySeq  = B.CompanySeq
                                                             AND A.CostAccSeq = B.CostAccSeq

         WHERE A.CompanySeq     = @CompanySeq
           AND K.SMCostMng	     = @SMCostMng 
           AND K.CostMngAmdSeq  = @CostMngAmdSeq 
           AND K.RptUnit		 = @RptUnit 
           AND K.PlanYear       = @PlanYear
           AND K.CostYM		 >= RTRIM(@CostYY) + '01' AND K.CostYM <= RTRIM(@CostYY) + '12'  
           AND A.ItemSeq        = @ItemSeq
           AND ( @CostUnit = 0 OR A.CostUnit = @CostUnit)
           AND ( @ItemSeq  = 0 OR A.ItemSeq  = @ItemSeq)     
         GROUP BY B.CostAccSeq, B.CostAccName
    END 
    
    IF @QueryKind = 5548002  
    BEGIN 
        
        SELECT B.CostAccSeq,  
               B.CostAccName, 
               --CASE WHEN MAX(Z.TotalAmt) = 0 THEN 0 ELSE SUM(a.ProdCost) / MAX(Z.TotalAmt) END AS TotalAmt, 
               0 AS TotalAmt, 
               
               CASE WHEN MAX(Z.Mo1Amt) = 0 THEN 0 ELSE SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '01' THEN ProdCost-RevProcCost ELSE 0 END) / MAX(Z.Mo1Amt) END AS Mo1Amt,        
               CASE WHEN MAX(Z.Mo2Amt) = 0 THEN 0 ELSE SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '02' THEN ProdCost-RevProcCost ELSE 0 END) / MAX(Z.Mo2Amt) END AS Mo2Amt,        
               CASE WHEN MAX(Z.Mo3Amt) = 0 THEN 0 ELSE SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '03' THEN ProdCost-RevProcCost ELSE 0 END) / MAX(Z.Mo3Amt) END AS Mo3Amt,        
               CASE WHEN MAX(Z.Mo4Amt) = 0 THEN 0 ELSE SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '04' THEN ProdCost-RevProcCost ELSE 0 END) / MAX(Z.Mo4Amt) END AS Mo4Amt,        
               CASE WHEN MAX(Z.Mo5Amt) = 0 THEN 0 ELSE SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '05' THEN ProdCost-RevProcCost ELSE 0 END) / MAX(Z.Mo5Amt) END AS Mo5Amt,        
               CASE WHEN MAX(Z.Mo6Amt) = 0 THEN 0 ELSE SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '06' THEN ProdCost-RevProcCost ELSE 0 END) / MAX(Z.Mo6Amt) END AS Mo6Amt,        
               CASE WHEN MAX(Z.Mo7Amt) = 0 THEN 0 ELSE SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '07' THEN ProdCost-RevProcCost ELSE 0 END) / MAX(Z.Mo7Amt) END AS Mo7Amt,        
               CASE WHEN MAX(Z.Mo8Amt) = 0 THEN 0 ELSE SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '08' THEN ProdCost-RevProcCost ELSE 0 END) / MAX(Z.Mo8Amt) END AS Mo8Amt,        
               CASE WHEN MAX(Z.Mo9Amt) = 0 THEN 0 ELSE SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '09' THEN ProdCost-RevProcCost ELSE 0 END) / MAX(Z.Mo9Amt) END AS Mo9Amt,        
               CASE WHEN MAX(Z.Mo10Amt) = 0 THEN 0 ELSE SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '10' THEN ProdCost-RevProcCost ELSE 0 END) / MAX(Z.Mo10Amt) END AS Mo10Amt,        
               CASE WHEN MAX(Z.Mo11Amt) = 0 THEN 0 ELSE SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '11' THEN ProdCost-RevProcCost ELSE 0 END) / MAX(Z.Mo11Amt) END AS Mo11Amt,        
               CASE WHEN MAX(Z.Mo12Amt) = 0 THEN 0 ELSE SUM(CASE K.CostYM WHEN RTRIM(@CostYY) + '12' THEN ProdCost-RevProcCost ELSE 0 END) / MAX(Z.Mo12Amt) END AS Mo12Amt        
               
          FROM _TESMCProdFGoodCostResult    AS A WITH(NOLOCK)
                 JOIN _TESMDCostKey         AS K WITH(NOLOCK) ON A.CompanySeq    = K.CompanySeq 
                                                             AND A.CostKeySeq    = K.CostKeySeq  
                 JOIN _TESMBAccount         AS B WITH(NOLOCK) ON A.CompanySeq  = B.CompanySeq
                                                             AND A.CostAccSeq = B.CostAccSeq
                 LEFT OUTER JOIN #Result    AS Z              ON ( Z.CostAccSeq = A.CostAccSeq ) 

         WHERE A.CompanySeq     = @CompanySeq
           AND K.SMCostMng	     = @SMCostMng 
           AND K.CostMngAmdSeq  = @CostMngAmdSeq 
           AND K.RptUnit		 = @RptUnit 
           AND K.PlanYear       = @PlanYear
           AND K.CostYM		 >= RTRIM(@CostYY) + '01' AND K.CostYM <= RTRIM(@CostYY) + '12'  
           AND A.ItemSeq        = @ItemSeq
           AND ( @CostUnit = 0 OR A.CostUnit = @CostUnit)
           AND ( @ItemSeq  = 0 OR A.ItemSeq  = @ItemSeq)     
         GROUP BY B.CostAccSeq, B.CostAccName
         
    END 
    

    
    RETURN  

GO
exec KPXCM_SESMZProdCostInMonListQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <SMCostMng>5512001</SMCostMng>
    <CostMngAmdSeq />
    <PlanYear />
    <RptUnit />
    <CostUnit />
    <CostYY>2016</CostYY>
    <AssetSeq />
    <AssetName />
    <QueryKind>5548002</QueryKind>
    <ItemSeq>413</ItemSeq>
    <ItemName />
    <ItemNo />
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1037583,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1030745