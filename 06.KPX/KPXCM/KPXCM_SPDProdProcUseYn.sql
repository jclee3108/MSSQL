  
IF OBJECT_ID('KPXCM_SPDProdProcUseYn') IS NOT NULL   
    DROP PROC KPXCM_SPDProdProcUseYn  
GO  
  
-- v2016.04.29 
  
-- 제품별생산소요등록-조회 by 작성자   
CREATE PROC KPXCM_SPDProdProcUseYn  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @ItemSeq    INT,  
            @PatternRev NCHAR(2), 
            @UseYn      NCHAR(1) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ItemSeq     = ISNULL( ItemSeq, 0 ),  
           @PatternRev  = ISNULL( PatternRev, '00' ),  
           @UseYn       = ISNULL( UseYn, '0' ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ItemSeq    INT,  
            PatternRev NCHAR(2), 
            UseYn      NCHAR(1)       
           )    
    
    UPDATE A
       SET UseYn = @UseYn -- CASE WHEN @UseYn = '1' THEN '0' ELSE '1' END 
      FROM KPX_TPDProdProc AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ItemSeq = @ItemSeq 
       AND A.PatternRev = @PatternRev 
    
    SELECT A.ItemSeq, A.PatternRev, A.UseYn 
      FROM KPX_TPDProdProc AS A 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ItemSeq = @ItemSeq 
       AND A.PatternRev = @PatternRev 
       
    RETURN  
    GO
    begin tran 
exec KPXCM_SPDProdProcUseYn @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>8</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemSeq>1001148</ItemSeq>
    <PatternRev>09</PatternRev>
    <UseYn>0</UseYn>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1035598,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1029315
rollback 