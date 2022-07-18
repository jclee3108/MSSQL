  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderItemInfo') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderItemInfo  
GO  
  
-- v2014.11.25 
  
-- 포장작업지시입력- 품목추가정보 조회 by 이재천   
CREATE PROC KPX_SPDSFCProdPackOrderItemInfo  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    
    DECLARE @docHandle  INT,  
            -- 조회조건   
            @ItemSeq    INT
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
    
    SELECT @ItemSeq   = ISNULL( ItemSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (ItemSeq   INT)    
    
    SELECT TOP 1 
           A.MngValText AS GHS, 
           B.BrandName 
      FROM _TDAItemUserDefine AS A 
      OUTER APPLY (SELECT MngValText AS BrandName  
                     FROM _TDAItemUserDefine AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.MngSerl = 1000004 
                      AND Z.ItemSeq = A.ItemSeq 
                  ) AS B
     WHERE A.CompanySeq = @CompanySeq 
       AND A.ItemSeq = @ItemSeq 
       AND A.MngSerl = 1000005 
      
      
    RETURN  
go
exec KPX_SPDSFCProdPackOrderItemInfo @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemSeq>27439</ItemSeq>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026147,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021349


--select * from _TDAItemUserDefine  where companyseq = 1 and itemseq = 27439