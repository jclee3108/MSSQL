  
IF OBJECT_ID('KPXCM_SEQYearRepairReceiptRegCHEIsRtnReasonQuery') IS NOT NULL   
    DROP PROC KPXCM_SEQYearRepairReceiptRegCHEIsRtnReasonQuery  
GO  
  
-- v2015.07.15  
  
-- 연차보수접수등록-보류회송구분 by 이재천   
CREATE PROC KPXCM_SEQYearRepairReceiptRegCHEIsRtnReasonQuery  
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
    
    DECLARE @docHandle      INT,  
            -- 조회조건   
            @ProgType       INT, 
            @IsRtnReason    NCHAR(1) 
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @ProgType   = ISNULL( ProgType, 0 )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock2', @xmlFlags )       
      WITH (ProgType   INT)    
      
    -- 최종조회   
    SELECT @IsRtnReason = A.ValueText 
      FROM _TDAUMinorValue AS A 
     WHERE A.CompanySeq = @CompanySeq  
       AND A.MinorSeq = @ProgType 
       AND A.Serl = 1000007 
    
    SELECT ISNULL(@IsRtnReason,0) AS IsRtnReason
    
    RETURN  
GO
exec KPXCM_SEQYearRepairReceiptRegCHEIsRtnReasonQuery @xmlDocument=N'<ROOT>
  <DataBlock2>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>3</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ProgType>20109001</ProgType>
    <TABLE_NAME>DataBlock2</TABLE_NAME>
  </DataBlock2>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030864,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1025743