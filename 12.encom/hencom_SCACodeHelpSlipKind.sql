IF OBJECT_ID('hencom_SCACodeHelpSlipKind') IS NOT NULL 
    DROP PROC hencom_SCACodeHelpSlipKind
GO 

-- v2017.04.11 
/*************************************************************************************************
ROCEDURE    - _SCACodeHelpSlipKind
DESCRIPTION - CodeHellp 정보를 _TACSlipKind 에서 조회한다.
작  성  일  - 2008년 6월 16일
수  정  일  -
*************************************************************************************************/
CREATE PROCEDURE dbo.hencom_SCACodeHelpSlipKind
    @WorkingTag     NVARCHAR(1),
    @LanguageSeq    INT,
    @CodeHelpSeq    INT,
    @DefQueryOption INT, -- 2: direct search
    @CodeHelpType   TINYINT,
    @PageCount      INT = 20,
    @CompanySeq     INT = 0,
    @Keyword        NVARCHAR(50) = '',
    @Param1         NVARCHAR(50) = '',
    @Param2         NVARCHAR(50) = '',
    @Param3         NVARCHAR(50) = '',
    @Param4         NVARCHAR(50) = ''
AS
    SET ROWCOUNT @PageCount
    DECLARE @PgmID NVARCHAR(100)
	SELECT @PgmID = ''
    SELECT @PgmID = A.PgmID
      FROM _TCAPgm AS A
     WHERE A.PgmSeq = CAST(@Param3 AS INT)

    SELECT A.SlipKindName,
           A.SlipKind,
           A.SlipKindNo,
           A.PgmSeq,
           B.SlipAutoEnvSeq,
           C.PgmId,
           ISNULL( Z.Word, C.Caption ) AS Caption,
           ISNULL(A.IsNotUse,0) AS IsNotUse   -- 코드헬프 하부조건으로 사용여부 추가 2011.05.19
      FROM _TACSlipKind AS A WITH (NOLOCK)
           LEFT JOIN _TACSlipAutoEnv AS B WITH (NOLOCK)
                  ON B.CompanySeq   = A.CompanySeq
                 AND B.SlipKindNo   = A.SlipKindNo
           LEFT OUTER JOIN _TCAPgm AS C WITH(NOLOCK) ON A.PgmSeq = C.PgmSeq
           LEFT OUTER JOIN _TCADictionaryCommon AS Z WITH(NOLOCK) ON ( C.WordSeq = Z.WordSeq AND Z.LanguageSeq = @LanguageSeq )
                      JOIN ( 
                            SELECT ValueSeq AS SlipKind
                              FROM _TDAUMinorValue AS Z WITH(NOLOCK) 
                              LEFT OUTER JOIN _TDAUMinor AS Y WITH(NOLOCK) ON ( Y.CompanySeq = @CompanySeq AND Y.MinorSeq = Z.MinorSeq ) 
                             WHERE Z.CompanySeq = @CompanySeq 
                               AND Z.MajorSeq = 1015027 
                               AND Z.Serl = 1000001
                               AND ISNULL(Y.IsUse,'0') = '1'
                           ) AS Q ON ( Q.SlipKind = A.SlipKind )  

     WHERE A.CompanySeq     = @CompanySeq
       AND A.SlipKindName   LIKE @Keyword + '%'
       AND (@PgmID = '' OR (@PgmID = 'FrmACSlipAutoEnv')) --AND (A.IsNotUse <> '1' OR A.IsNotUse IS NULL)))
       AND (@Param1 = '' OR A.PgmSeq = CAST(@Param1 AS INT))
       AND (@Param2 = '' OR A.IsPurCash = @Param2)            --구매팀 출납전표구분
     ORDER BY A.SlipKindName
    SET ROWCOUNT 0
    RETURN
/*******************************************************************************************************************/
