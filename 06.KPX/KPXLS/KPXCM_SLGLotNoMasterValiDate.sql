  
IF OBJECT_ID('KPXCM_SLGLotNoMasterValiDate') IS NOT NULL   
    DROP PROC KPXCM_SLGLotNoMasterValiDate  
GO  
  
-- v2015.12.03 
  
-- LOTNo Master 등록-유효일자계산 by 이재천 
CREATE PROC KPXCM_SLGLotNoMasterValiDate  
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
            @CreateDate     NCHAR(8), 
            @ItemSeq        INT
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @CreateDate   = ISNULL( CreateDate, '' ), 
           @ItemSeq      = ISNULL( ItemSeq, 0 )
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock1', @xmlFlags )       
      WITH (
            CreateDate  NCHAR(8), 
            ItemSeq     INT
           )    
      
    -- 최종조회   
    SELECT CASE WHEN A.SMLimitTermKind = 8004001 THEN CONVERT(NCHAR(8),DATEADD(MONTH,A.LimitTerm,@CreateDate),112) -- 월 
                WHEN A.SMLimitTermKind = 8004002 THEN CONVERT(NCHAR(8),DATEADD(DAY,A.LimitTerm,@CreateDate),112) -- 일 
                ELSE '' 
                END AS ValiDate 
      FROM _TDAItemStock AS A
     WHERE A.CompanySeq = @CompanySeq  
       AND A.ItemSeq = @ItemSeq 
      
    RETURN  
Go
exec KPXCM_SLGLotNoMasterValiDate @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <ItemSeq>1002126</ItemSeq>
    <CreateDate>20151203</CreateDate>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1033515,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1027756