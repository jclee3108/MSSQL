
IF OBJECT_ID('KPX_SEQYearRepairReceiptRegListCHEQuerySub') IS NOT NULL 
    DROP PROC KPX_SEQYearRepairReceiptRegListCHEQuerySub
GO

-- v2014.12.11 

-- 작업접수조회Sub(연차보수) by이재천
CREATE PROC KPX_SEQYearRepairReceiptRegListCHEQuerySub                
    @xmlDocument    NVARCHAR(MAX) , 
    @xmlFlags       INT  = 0, 
    @ServiceSeq     INT  = 0, 
    @WorkingTag     NVARCHAR(10)= '', 
    @CompanySeq     INT  = 1, 
    @LanguageSeq    INT  = 1, 
    @UserSeq        INT  = 0, 
    @PgmSeq         INT  = 0 
    
 AS        
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    -- 서비스 마스타 등록 생성
    CREATE TABLE #TEQYearRepairMatReqCHE (WorkingTag NCHAR(1) NULL) 
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TEQYearRepairMatReqCHE'
    IF @@ERROR <> 0 RETURN 
    
    SELECT MAX(A.ReqSeq) AS ReqSeq     ,  
           A.ItemSeq    ,   
           B.ItemName   ,   
           B.ItemNo     ,
           SUM(A.ItemReqQty) AS ItemReqQty ,   
           B.UnitSeq    ,   
           D.UnitName   ,
           M.WONo       ,
           M.ReqDate 
      FROM #TEQYearRepairMatReqCHE              AS R 
                 JOIN _TEQYearRepairMatReqCHE   AS A ON ( A.ReqSeq = R.ReqSeq ) 
      LEFT OUTER JOIN _TDAItem                  AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit                  AS D ON ( D.CompanySeq = @CompanySeq AND D.UnitSeq = B.UnitSeq ) 
      LEFT OUTER JOIN _TEQYearRepairMngCHE      AS M ON ( M.CompanySeq = @CompanySeq AND A.ReqSeq = M.ReqSeq ) 
      WHERE A.CompanySeq = @CompanySeq
     GROUP BY A.ItemSeq, B.ItemName, B.ItemNo, B.UnitSeq, D.UnitName, M.WONo, M.ReqDate       
    
    RETURN
GO 
exec KPX_SEQYearRepairReceiptRegListCHEQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <ReqSeq>9</ReqSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026682,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021371