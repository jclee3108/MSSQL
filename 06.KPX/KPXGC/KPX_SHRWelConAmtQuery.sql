
IF OBJECT_ID('KPX_SHRWelConAmtQuery') IS NOT NULL 
    DROP PROC KPX_SHRWelConAmtQuery
GO 

-- v2014.11.27 

-- 경조사지급기준등록(조회) by이재천 
CREATE PROCEDURE KPX_SHRWelConAmtQuery        
    @xmlDocument    NVARCHAR(MAX),      
    @xmlFlags       INT = 0,      
    @ServiceSeq     INT = 0,-- 서비스등록한것 Seq가 넘어온다.      
    @WorkingTag     NVARCHAR(10)= '',      
    @CompanySeq     INT = 1,      
    @LanguageSeq    INT = 1,      
    @UserSeq        INT = 0,      
    @PgmSeq         INT = 0      
AS             
    DECLARE @docHandle      INT      
          , @SMConMutual     INT       
          , @IsNoUseInclude NCHAR(1)       
          , @UMConClass     INT       
      
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument       
      
  
    SELECT  @SMConMutual     = ISNULL(SMConMutual, 0)         -- 경조지급구분(경조/공조)  
        , @IsNoUseInclude   = ISNULL(IsNoUseInclude,'')     -- 사용안함포함  
        , @UMConClass       = ISNULL(UMConClass,0)          -- 경조사분류  
             
    FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)           
    WITH (SMConMutual        INT  
        , IsNoUseInclude    NCHAR(1)  
        , UMConClass        INT)        
      
    SELECT @SMConMutual     = ISNULL(@SMConMutual, 0)         -- 경조지급구분(경조/공조)  
        , @IsNoUseInclude   = ISNULL(@IsNoUseInclude,'')     -- 사용안함포함  
        , @UMConClass       = ISNULL(@UMConClass,0)          -- 경조사분류  
    
    -- 최종조회 
    SELECT A.ConSeq   AS ConSeq        -- 경조사코드  
        , A.ConName         AS ConName       -- 경조사명  
        , A.UMConClass      AS UMConClass    -- 경조사분류코드  
        , A.IsFlower        AS IsFlower      -- 경조화지급  
        , A.HoliDays        AS HoliDays      -- 휴가일수  
        , A.WkItemSeq       AS WkItemSeq     -- 근태항목코드  
        , A.IsConAmt        AS IsConAmt      -- 경조금지급  
        , A.IsMutualAmt     AS IsMutualAmt   -- 공조금지급  
        , A.SMConPayMth     AS SMConPayMth   -- 경조금지급기준코드  
        , A.SMMutualPayMth  AS SMMutualPayMth-- 공조금지급기준코드  
        , A.UMConType       AS UMConType     -- 경조금복리후생구분  
        , A.UMMutualType    AS UMMutualType  -- 공조금복리후생구분  
        , A.IsNoUse         AS IsNoUse       -- 사용안함  
        , B.WkItemName      AS WkItemName       -- 근태항목명  
        , C.MinorName       AS SMConPayMthName  -- 경조금지급기준명  
        , D.MinorName       AS SMMutualPayMthName   -- 공조금지급기준명  
        , E.MinorName       AS UMConTypeName   -- 경조금복리후생구분명  
        , F.MinorName       AS UMMutualTypeName   -- 공조금복리후생구분  
        , CASE @SMConMutual WHEN 3236001 THEN A.SMConPayMth ELSE A.SMMutualPayMth END AS SMPayMth   -- 지급지준코드  
        , G.MinorName   AS SMPayMth -- 지급기준명  
        , A.EvidPaper AS EvidPaper -- 20101129김지훈 :: 증빙서류 필드추가  
        , A.Remark  AS Remark  -- 20101129김지훈 :: 비고 필드추가  
        
      FROM _THRWelCon               AS A   
      LEFT OUTER JOIN _TPRWkItem    AS B ON A.CompanySeq = B.CompanySeq AND A.WkItemSeq = B.WkItemSeq  
      LEFT OUTER JOIN _TDAUMinor    AS C ON A.CompanySeq = C.CompanySeq AND A.SMConPayMth = C.MinorSeq  
      LEFT OUTER JOIN _TDASMinor    AS D ON A.CompanySeq = D.CompanySeq AND A.SMMutualPayMth = D.MinorSeq  
      LEFT OUTER JOIN _TDAUMinor    AS E ON A.CompanySeq = E.CompanySeq AND A.UMConType = E.MinorSeq  
      LEFT OUTER JOIN _TDAUMinor    AS F ON A.CompanySeq = F.CompanySeq AND A.UMMutualType = F.MinorSeq  
      LEFT OUTER JOIN _TDASMinor    AS G ON A.CompanySeq = G.CompanySeq AND CASE @SMConMutual WHEN 3236001 THEN A.SMConPayMth ELSE A.SMMutualPayMth END = G.MinorSeq  
    
     WHERE A.CompanySeq = @CompanySeq  
       AND (@SMConMutual = 0 OR (@SMConMutual = 3236001 AND A.IsConAmt = '1') OR (@SMConMutual = 3236002 AND A.IsMutualAmt = '1'))   
       AND (@IsNoUseInclude = '' OR @IsNoUseInclude = '1' OR (@IsNoUseInclude = '0' AND A.IsNoUse <> '1'))  
       AND (@UMConClass = 0 OR A.UMConClass = @UMConClass)  
       AND (@SMConMutual <> 3236001  OR A.SMConPayMth <> 0)  
       AND (@SMConMutual <> 3236002  OR A.SMMutualPayMth <> 0)  
       AND (@SMConMutual = 3236001 AND A.SMConPayMth = 3235999) OR (@SMConMutual = 3236002 AND A.SMMutualPayMth = 3235999)
    RETURN        
  