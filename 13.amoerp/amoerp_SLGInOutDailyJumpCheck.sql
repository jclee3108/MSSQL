  
IF OBJECT_ID('amoerp_SLGInOutDailyJumpCheck') IS NOT NULL   
    DROP PROC amoerp_SLGInOutDailyJumpCheck
GO  
  
-- v2013.12.03 
  
-- 화면명-체크 by이재천
CREATE PROC amoerp_SLGInOutDailyJumpCheck  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    CREATE TABLE #TLGInOutDaily( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TLGInOutDaily'   
    IF @@ERROR <> 0 RETURN     
    
    DECLARE @ItemNos NVARCHAR(2000)
    
    SELECT @ItemNos = '' 
    
    SELECT @ItemNos = @ItemNos+','+(SELECT ItemNo FROM _TDAItem WITH(NOLOCK) WHERE CompanySeq = @CompanySeq AND ItemSeq = B.ItemSeq)
      FROM #TLGInOutDaily                   AS A 
      JOIN amoerp_TLGInOutDailyItemMerge    AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.InOutType = 50 AND B.InOutSeq = A.InOutSeq ) 
      JOIN _TDAItemStock                    AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq AND C.IsLotMng = '1' ) 
     WHERE A.Status = 0
       AND NOT EXISTS (SELECT 1 FROM amoerp_TLGInOutDailyItemMergeSub WHERE CompanySeq = @CompanySeq AND InOutSeq = B.InOutSeq AND InOutSerl = B.InOutSerl ) 
    
    IF @@ROWCOUNT <> 0 
    BEGIN 
        
        UPDATE A
           SET A.Result = N'Lot분할 하지 않은 품목이 존재합니다.[품번:'+SUBSTRING(@ItemNos,2,LEN(@ItemNos))+']', 
               A.Status = 1234, 
               A.MessageType = 1234  
               
          FROM #TLGInOutDaily AS A 
         WHERE A.Status = 0 
        
    END
    
    SELECT * FROM #TLGInOutDaily   
      
    RETURN  
GO
exec amoerp_SLGInOutDailyJumpCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <InOutSeq>1001296</InOutSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019447,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016426