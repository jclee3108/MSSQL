
IF OBJECT_ID('jongie_SCOMEnvItemQuery') IS NOT NULL
    DROP PROC jongie_SCOMEnvItemQuery
GO
    
-- v2013.08.07   
  
-- (종이나라) 추가개발 Mapping정보 설정_jongie-조회 by 김철웅 (copy 이재천)      
CREATE PROC jongie_SCOMEnvItemQuery    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT = 0,    
    @ServiceSeq     INT = 0,     
    @WorkingTag     NVARCHAR(10)= '',    
    @CompanySeq     INT = 1,    
    @LanguageSeq    INT = 1,    
    @UserSeq        INT = 0,    
    @PgmSeq         INT = 0    
AS    
      
    -- 최종조회     
    SELECT B.ItemName, B.ItemNo, B.Spec, A.ItemSeq, A.ItemSeq AS ItemSeqOld  
      FROM jongie_TCOMEnvItem AS A WITH(NOLOCK)     
      JOIN _TDAItem        AS B WITH(NOLOCK) ON ( B.CompanySeq = @CompanySeq AND A.ItemSeq = B.ItemSeq )  
     WHERE A.CompanySeq = @CompanySeq    
     ORDER BY B.ItemName, B.ItemNo, B.Spec  
      
    RETURN    