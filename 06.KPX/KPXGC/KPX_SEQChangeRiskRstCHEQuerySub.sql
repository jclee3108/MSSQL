  
IF OBJECT_ID('KPX_SEQChangeRiskRstCHEQuerySub') IS NOT NULL   
    DROP PROC KPX_SEQChangeRiskRstCHEQuerySub  
GO  
  
-- v2014.12.12  
  
-- 변경위험성평가등록-변경등급조회 by 이재천   
CREATE PROC KPX_SEQChangeRiskRstCHEQuerySub  
    @xmlDocument    NVARCHAR(MAX),  
    @xmlFlags       INT = 0,  
    @ServiceSeq     INT = 0,   
    @WorkingTag     NVARCHAR(10)= '',  
    @CompanySeq     INT = 1,  
    @LanguageSeq    INT = 1,  
    @UserSeq        INT = 0,  
    @PgmSeq         INT = 0  
AS   
    
    SELECT 'I' AS F1, '18초과 ~ 24' AS F2, 'HAZOP기법 외(위험과 운전분석)' AS F3
    UNION ALL
    SELECT 'II' AS F1, '12초과 ~ 18이하' AS F2, 'HAZOP기법 외(위험과 운전분석)' AS F3
    UNION ALL
    SELECT 'III' AS F1, '6초과 ~ 12이하' AS F2, 'CheckList기법 외' AS F3
    UNION ALL
    SELECT 'IV' AS F1, '1초과 ~ 6이하' AS F2, 'CheckList기법 외' AS F3
    
    RETURN  
GO
exec KPX_SEQChangeRiskRstCHEQuerySub @xmlDocument=N'<ROOT></ROOT>',@xmlFlags=2,@ServiceSeq=1026700,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1022351