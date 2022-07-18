  
IF OBJECT_ID('KPXCM_SPDDailyProdBasisQuerySub') IS NOT NULL   
    DROP PROC KPXCM_SPDDailyProdBasisQuerySub  
GO  
  
-- v2016.05.10  
  
-- 일일생산량관리기준정보입력(전자재료)-Item조회 by 이재천   
CREATE PROC KPXCM_SPDDailyProdBasisQuerySub  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS  
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED -- WITH(NOLOCK) 대신
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @UnitProcSeq    INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @UnitProcSeq   = ISNULL( UnitProcSeq, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH ( UnitProcSeq   INT )    
      
    -- 최종조회   
    SELECT A.UnitProcSeq, A.ItemSeq, B.ItemName, B.ItemNo, A.ItemPrtName, 
           A.ConvDen, A.Sort, A.Remark, A.ItemSeq AS ItemSeqOld
      FROM KPXCM_TPDDailyProdBasisItem  AS A 
      LEFT OUTER JOIN _TDAItem          AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.UnitProcSeq = @UnitProcSeq )  
      
    RETURN  
GO
exec KPXCM_SPDDailyProdBasisQuerySub @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <UnitProcSeq>1</UnitProcSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1036949,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1030269