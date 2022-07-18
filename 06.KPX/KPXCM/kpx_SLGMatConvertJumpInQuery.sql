  
IF OBJECT_ID('kpx_SLGMatConvertJumpInQuery') IS NOT NULL   
    DROP PROC kpx_SLGMatConvertJumpInQuery  
GO  
  
-- v2015.10.14  
  
-- 상품 원자재대체처리-점프인조회 by 이재천 
CREATE PROC kpx_SLGMatConvertJumpInQuery  
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
            @InOutSeq   INT,  
            @ConvertSeq INT 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @InOutSeq    = ISNULL( InOutSeq, 0 ),  
           @ConvertSeq  = ISNULL( ConvertSeq, 0 ) 
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            InOutSeq    INT,   
            ConvertSeq  INT 
           )    
    
    IF @ConvertSeq = 0 
    BEGIN 
        SELECT @ConvertSeq = MAX(ConvertSeq) 
          FROM kpx_TLGMatConvertItem AS A 
         WHERE A.CompanySeq = @CompanySeq  
           AND A.InOutSeq = @InOutSeq 
    END 
    
    SELECT @ConvertSeq AS ConvertSeq 
    
    RETURN  
GO
exec kpx_SLGMatConvertJumpInQuery @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <ConvertSeq>31</ConvertSeq>
    <InOutSeq>100002217</InOutSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030290,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025265