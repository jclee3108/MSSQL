  
IF OBJECT_ID('KPX_SPDSFCProdPackOrderQuery') IS NOT NULL   
    DROP PROC KPX_SPDSFCProdPackOrderQuery  
GO  
  
-- v2014.11.25  
  
-- 포장작업지시입력-조회 by 이재천   
CREATE PROC KPX_SPDSFCProdPackOrderQuery  
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
            @PackOrderSeq   INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @PackOrderSeq   = ISNULL( PackOrderSeq, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (PackOrderSeq   INT)    
    
    -- 최종조회   
    SELECT A.PackOrderSeq, 
           A.FactUnit, 
           B.FactUnitName, 
           A.PackDate, 
           A.OrderNo, 
           A.OutWHSeq, 
           C.WHName AS OutWHName, 
           A.InWHSeq, 
           D.WHName AS InWHName, 
           A.UMProgType, 
           E.MinorName AS UMProgTypeName, 
           A.Remark, 
           F.WHName AS SubOutWHName, 
           A.SubOutWHSeq 

           
      FROM KPX_TPDSFCProdPackOrder AS A 
      LEFT OUTER JOIN _TDAFactUnit AS B ON ( B.CompanySeq = @CompanySeq AND B.FactUnit = A.FactUnit ) 
      LEFT OUTER JOIN _TDAWH       AS C ON ( C.CompanySeq = @CompanySeq AND C.WHSeq = A.OutWHSeq ) 
      LEFT OUTER JOIN _TDAWH       AS D ON ( D.CompanySeq = @CompanySeq AND D.WHSeq = A.InWHSeq ) 
      LEFT OUTER JOIN _TDAUMinor   AS E ON ( E.CompanySeq = @CompanySeq AND E.MinorSeq = A.UMProgType ) 
      LEFT OUTER JOIN _TDAWH       AS F ON ( F.CompanySeq = @CompanySeq AND F.WHSeq = A.SubOutWHSeq ) 

     WHERE A.CompanySeq = @CompanySeq  
       AND @PackOrderSeq = A.PackOrderSeq
    
    
    
    SELECT A.PackOrderSeq, 
           A.PackOrderSerl, 
           B.ItemSeq, 
           B.ItemName, 
           B.ItemNo,
           B.Spec, 
           A.UnitSeq, 
           C.UnitName, 
           A.OrderQty, 
           A.LotNo, 
           A.UMDMMarking, 
           D.MinorName AS UMDMMArkingName, 
           A.OutLotNo, 
           A.PackOnDate, 
           A.PackReOnDate, 
           A.Remark, 
           A.SubItemSeq, 
           E.ItemName AS SubItemName, 
           E.ItemNo AS SubItemNo, 
           E.Spec AS SubSpec, 
           A.SubUnitSeq, 
           F.UnitName AS SubUnitName, 
           A.NonMarking, 
           A.PopInfo, 
           A.IsStop, 
           G.GHS, 
           H.BrandName 
           
      FROM KPX_TPDSFCProdPackOrderItem  AS A 
      LEFT OUTER JOIN _TDAItem          AS B ON ( B.CompanySeq = @CompanySeq AND B.ItemSeq = A.ItemSeq ) 
      LEFT OUTER JOIN _TDAUnit          AS C ON ( C.CompanySeq = @CompanySeq AND C.UnitSeq = A.UnitSeq ) 
      LEFT OUTER JOIN _TDAUMinor        AS D ON ( D.CompanySeq = @CompanySeq AND D.MinorSeq = A.UMDMMarking ) 
      LEFT OUTER JOIN _TDAItem          AS E ON ( E.CompanySeq = @CompanySeq AND E.ItemSeq = A.SubItemSeq ) 
      LEFT OUTER JOIN _TDAUnit          AS F ON ( F.CompanySeq = @CompanySeq AND F.UnitSeq = A.SubUnitSeq ) 
      OUTER APPLY (SELECT MngValText AS GHS  
                     FROM _TDAItemUserDefine AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.MngSerl = 1000005 
                      AND Z.ItemSeq = A.ItemSeq 
                  ) AS G
      OUTER APPLY (SELECT MngValText AS BrandName  
                     FROM _TDAItemUserDefine AS Z 
                    WHERE Z.CompanySeq = @CompanySeq 
                      AND Z.MngSerl = 1000004 
                      AND Z.ItemSeq = A.ItemSeq 
                  ) AS H
     WHERE A.CompanySeq = @CompanySeq 
       AND @PackOrderSeq = A.PackOrderSeq
     
    RETURN  
GO 
exec KPX_SPDSFCProdPackOrderQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <PackOrderSeq>20</PackOrderSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1026147,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021349