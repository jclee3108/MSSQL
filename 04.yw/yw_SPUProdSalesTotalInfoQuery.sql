  
IF OBJECT_ID('yw_SPUProdSalesTotalInfoQuery') IS NOT NULL   
    DROP PROC yw_SPUProdSalesTotalInfoQuery  
GO  
  
-- v2013.11.28  
  
-- 통합장표자료생성(구매)_YW-조회 by 이재천   
CREATE PROC yw_SPUProdSalesTotalInfoQuery  
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
            @OSPPOSeq   INT,  
            @OSPPOSerl  INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @OSPPOSeq   = ISNULL( OSPPOSeq, 0 ),  
           @OSPPOSerl  = ISNULL( OSPPOSerl, 0 )  
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            OSPPOSeq    INT,   
            OSPPOSerl   INT
           )    
      
    -- 최종조회   
    SELECT B.OSPPONo, 
           D.WOrkOrderNo, 
           E.ProcName, 
           F.ItemName, 
           F.ItemNo, 
           G.DeptName, 
           A.OSPPOSeq, 
           A.OSPPOSerl, 
           A.InfoDate, 
           A.Remark
          
      FROM YW_TPUProdSalesTotalInfo     AS A WITH(NOLOCK)   
      LEFT OUTER JOIN _TPDOSPPOItem     AS C WITH(NOLOCK) ON ( C.CompanySeq = @CompanySeq AND C.OSPPOSeq = A.OSPPOSeq AND C.OSPPOSerl = A.OSPPOSerl ) 
      LEFT OUTER JOIN _TPDOSPPO         AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND B.OSPPOSeq = C.OSPPOSeq ) 
      LEFT OUTER JOIN _TPDSFCWorkOrder  AS D WITH(NOLOCK) ON ( D.CompanySeq = @CompanySeq AND D.WorkOrderSeq = C.WorkOrderSeq AND D.WorkOrderSerl = C.WorkOrderSerl ) 
      LEFT OUTER JOIN _TPDBaseProcess   AS E WITH(NOLOCK) ON ( E.CompanySeq = @CompanySeq AND E.ProcSeq = C.ProcSeq ) 
      LEFT OUTER JOIN _TDAItem          AS F WITH(NOLOCK) ON ( F.CompanySeq = @CompanySeq AND F.ItemSeq = C.ItemSeq ) 
      LEFT OUTER JOIN _TDADept          AS G WITH(NOLOCK) ON ( G.CompanySeq = @CompanySeq AND G.DeptSeq = B.DeptSeq ) 
      
     WHERE A.CompanySeq = @CompanySeq  
       AND ( A.OSPPOSeq = @OSPPOSeq )   
       AND ( A.OSPPOSerl = @OSPPOSerl )  
    
    RETURN  
GO
exec yw_SPUProdSalesTotalInfoQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <OSPPOSeq>1000040</OSPPOSeq>
    <OSPPOSerl>1</OSPPOSerl>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1019637,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1016581