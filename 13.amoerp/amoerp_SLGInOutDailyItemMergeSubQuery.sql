
IF OBJECT_ID('amoerp_SLGInOutDailyItemMergeSubQuery') IS NOT NULL 
    DROP PROC amoerp_SLGInOutDailyItemMergeSubQuery
GO 

-- v2013.11.21 
  
-- 위탁출고입력_amoerp by이재천
CREATE PROC amoerp_SLGInOutDailyItemMergeSubQuery
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,    
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS    
    DECLARE @docHandle      INT,    
            -- 조회조건     
            @InOutSeq       INT,  
            @InOutSerl      INT   
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument     
        
    SELECT @InOutSeq   = ISNULL( InOutSeq, 0 ),  
           @InOutSerl  = ISNULL( InOutSerl, 0 )  
             
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock3', @xmlFlags )         
      WITH (InOutSeq   INT,  
            InOutSerl  INT)      
      
    SELECT A.LotNo, A.Qty AS LotNoQty
             
      FROM amoerp_TLGInOutDailyItemMergeSub AS A WITH(NOLOCK) 
     WHERE A.CompanySeq = @CompanySeq   
       AND A.InOutSeq = @InOutSeq   
       AND A.InOutSerl = @InOutSerl   
     ORDER BY A.LotNo   
      
    RETURN  
    GO
exec amoerp_SLGInOutDailyItemMergeSubQuery @xmlDocument=N'<ROOT>
  <DataBlock3>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>1</Selected>
    <InOutSerl>1</InOutSerl>
    <InOutSeq>1001227</InOutSeq>
    <TABLE_NAME>DataBlock3</TABLE_NAME>
  </DataBlock3>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019447,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016426