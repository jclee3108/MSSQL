  
IF OBJECT_ID('KPXCM_SUIImpDelvItemListPrintJump_KPXCM') IS NOT NULL   
    DROP PROC KPXCM_SUIImpDelvItemListPrintJump_KPXCM  
GO  
  
-- v2015.07.08
  
-- 원료입고요청서-점프조회 by 이재천 
CREATE PROC KPXCM_SUIImpDelvItemListPrintJump_KPXCM  
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
            @DelvSeq    INT,  
            @DelvSerl   INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @DelvSeq     = ISNULL( DelvSeq, 0 ), 
           @DelvSerl    = ISNULL( DelvSerl, 0 )
    
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            DelvSeq     INT, 
            DelvSerl    INT
           )    
    
    -- 최종조회   
    SELECT C.ItemName, 
           C.ItemNo, 
           B.STDQty AS STDUnitQty, 
           D.BizUnitName, 
           A.DelvSeq, 
           B.DelvSerl,
           E.CustName 
      FROM _TUIImpDelv                  AS A 
                 JOIN _TUIImpDelvItem   AS B ON ( B.CompanySeq = @CompanySeq AND B.DelvSeq = A.DelvSeq ) 
      LEFT OUTER JOIN _TDAItem          AS C ON ( C.CompanySeq = @CompanySeq AND C.ItemSeq = B.ItemSeq ) 
      LEFT OUTER JOIN _TDABizUnit       AS D ON ( D.CompanySeq = @CompanySeq AND D.BizUnit = A.BizUnit ) 
      LEFT OUTER JOIN _TDACust          AS E ON ( E.CompanySeq = @CompanySeq AND E.CustSeq = A.CustSeq ) 
     WHERE A.CompanySeq = @CompanySeq 
       AND A.DelvSeq = @DelvSeq 
       AND B.DelvSerl = @DelvSerl 
    
    RETURN  
GO 