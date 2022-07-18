 
IF OBJECT_ID('hye_SSLOilSalesIsCfm') IS NOT NULL   
    DROP PROC hye_SSLOilSalesIsCfm  
GO  
  
-- v2016.11.04 
  
-- 주유소판매제출-제출 by 이재천
CREATE PROC hye_SSLOilSalesIsCfm  
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
            @BizUnit    INT, 
            @StdDate    NCHAR(8), 
            @StdYM      NCHAR(6), 
            @IsCfm      NCHAR(1) 
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument   
      
    SELECT @BizUnit     = ISNULL( BizUnit, 0 ),  
           @StdDate     = ISNULL( StdDate, '' ),  
           @StdYM       = ISNULL( StdYM  , '' )
      
      FROM OPENXML( @docHandle, N'/ROOT/DataBlock15', @xmlFlags )       
      WITH (
            BizUnit    INT,       
            StdDate    NCHAR(8),      
            StdYM      NCHAR(6)       
           )    
    
    
    -- 체크 
    SELECT @IsCfm = IsCfm 
      FROM hye_TSLOilSalesIsCfm AS A 
     WHERE A.Companyseq = @CompanySeq 
       AND A.BizUnit = @BizUnit 
       AND A.StdYMDate = CASE WHEN @StdDate = '' THEN @StdYM ELSE @StdDate END 
    
    SELECT @IsCfm = ISNULL(@IsCfm,'0')

    IF @WorkingTag = 'C' -- 제출 
    BEGIN
        IF @IsCfm = '1' 
        BEGIN
            SELECT '이미 제출이 완료되어 있습니다.' AS Result, 9999 Status, @IsCfm AS IsCfm 
            RETURN 
        END 
    END 
    ELSE IF @WorkingTag = 'CC' -- 제출 취소 
    BEGIN
        IF @IsCfm = '0' 
        BEGIN
            SELECT '이미 제출취소가 완료되어 있습니다.' AS Result, 9999 Status, @IsCfm AS IsCfm 
            RETURN 
        END 
    END 




    IF EXISTS (
                SELECT 1 
                  FROM hye_TSLOilSalesIsClose 
                 WHERE BizUnit = @BizUnit
                   AND StdYMDate = CASE WHEN @StdDate = '' THEN @StdYM ELSE @StdDate END 
                   AND IsClose = '1' 
              ) 
    BEGIN 
        SELECT '마감이 진행 되어 처리 할 수 없습니다.' AS Result, 9999 AS Status, 9 AS IsClose
        RETURN 
    END 


    -- 반영 
    IF @WorkingTag = 'C' -- 제출 
    BEGIN
        
        IF @StdYM = '' -- 일제출 
        BEGIN 
                
            INSERT INTO hye_TSLOilSalesIsCfm 
            (
                CompanySeq, BizUnit, StdYMDate, IsCfm, CfmDate, 
                LastUserSeq, LastDateTime, PgmSeq 
            )
            SELECT @CompanySeq, @BizUnit, @StdDate, '0', '', 
                   @UserSeq, GETDATE(), @PgmSeq 
             WHERE NOT EXISTS (SELECT 1 FROM hye_TSLOilSalesIsCfm WHERE CompanySeq = @CompanySeq AND BizUnit = @BizUnit AND StdYMDate = @StdDate)

            UPDATE A 
               SET IsCfm = '1', 
                   CfmDate = CONVERT(NCHAR(8),GETDATE(),112)
              FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdDate
             
            SELECT A.IsCfm, 0 AS Status 
              FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdDate

        END 
        ELSE IF @StdDate = '' -- 월제출 
        BEGIN 
            INSERT INTO hye_TSLOilSalesIsCfm 
            (
                CompanySeq, BizUnit, StdYMDate, IsCfm, CfmDate, 
                LastUserSeq, LastDateTime, PgmSeq 
            )
            SELECT @CompanySeq, @BizUnit, @StdYM, '0', '', 
                   @UserSeq, GETDATE(), @PgmSeq 
             WHERE NOT EXISTS (SELECT 1 FROM hye_TSLOilSalesIsCfm WHERE CompanySeq = @CompanySeq AND BizUnit = @BizUnit AND StdYMDate = @StdYM)

            UPDATE A 
               SET IsCfm = '1', 
                   CfmDate = CONVERT(NCHAR(8),GETDATE(),112)
              FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdYM
            
             SELECT A.IsCfm, 0 AS Status 
               FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdYM

        END 

    END 
    ELSE IF @WorkingTag = 'CC' -- 제출 취소 
    BEGIN

        IF @StdYM = '' -- 일제출취소
        BEGIN 
            UPDATE A 
               SET IsCfm = '0', 
                   CfmDate = ''
              FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdDate
             
             SELECT A.IsCfm, 0 AS Status 
               FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdDate

        END 
        ELSE IF @StdDate = '' -- 월제출취소
        BEGIN 
            UPDATE A 
               SET IsCfm = '0', 
                   CfmDate = ''
              FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdYM
        
             SELECT A.IsCfm, 0 AS Status 
               FROM hye_TSLOilSalesIsCfm AS A 
             WHERE A.CompanySeq = @CompanySeq 
               AND A.BizUnit = @BizUnit 
               AND StdYMDate = @StdYM

        END 
    END 
    

    RETURN  
GO 

begin tran 
exec hye_SSLOilSalesIsCfm @xmlDocument=N'<ROOT>
  <DataBlock15>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock15</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <IsCfm>0</IsCfm>
    <BizUnit>902</BizUnit>
    <StdDate>20160601</StdDate>
  </DataBlock15>
</ROOT>',@xmlFlags=2,@ServiceSeq=77730148,@WorkingTag=N'C',@CompanySeq=1,@LanguageSeq=1,@UserSeq=21,@PgmSeq=77730008
rollback 


