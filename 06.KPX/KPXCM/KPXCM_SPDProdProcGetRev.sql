IF OBJECT_ID('KPXCM_SPDProdProcGetRev') IS NOT NULL 
    DROP PROC KPXCM_SPDProdProcGetRev
GO 

-- v2016.03.07 

-- 제품별생산소요등록-차수증가 by 전경만
CREATE PROC KPXCM_SPDProdProcGetRev
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
            @ItemSeq        INT,
            @ItemBomRev     NCHAR(2),
            @MaxRev     NCHAR(2)
  
    CREATE TABLE #ProdProcGetRev (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#ProdProcGetRev'
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    SELECT @ItemSeq         = ISNULL(ItemSeq, 0)
           --@ItemBOMRev      = ISNULL(ItemBOMRev, '')
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            ItemSeq         INT
            --ItemBomRev      NCHAR(2)
           )    
    
    SELECT @MaxRev = MAX(PatternRev)
      FROM KPX_TPDProdProc 
     WHERE CompanySeq = @CompanySeq AND ItemSeq = @ItemSeq
    
    SELECT @MaxRev = RIGHT('00' + CONVERT(NVARCHAR(10), CONVERT(INT, @MaxRev)+1),2)
    IF ISNULL(@MaxRev,'') = ''
        SELECT @MaxRev = '01'
    
    UPDATE A
       SET PatternRev = @MaxRev
      FROM #ProdProcGetRev AS A
    
    INSERT INTO KPX_TPDProdProc(CompanySeq, ItemSeq, PatternRev, ItemBOMRev, ProdQty,
                                LastUserSeq, LastDateTime)
         SELECT @CompanySeq, ItemSeq, PatternRev, ItemBOMRev, 0,
                @UserSeq, GETDATE()
           FROM #ProdProcGetRev


    SELECT * FROM #ProdProcGetRev AS A
RETURN

go
begin tran 
exec KPXCM_SPDProdProcGetRev @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1035598,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1029315
rollback  