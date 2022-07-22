IF OBJECT_ID('hencom_SCACodeHelpQCDept') IS NOT NULL 
    DROP PROC hencom_SCACodeHelpQCDept
GO 

-- v2017.04.12
-- 품질모듈표시 체크되어 있는 것만 나오도록 수정
/***********************************************************************************************
ROCEDURE    - 사업소_hencom	hencom_SCACodeHelpQCDept
DESCRIPTION - 
작  성  일   - 2105.10.27
*************************************************************************************************/
CREATE PROCEDURE hencom_SCACodeHelpQCDept
    @WorkingTag     NVARCHAR(1),
    @LanguageSeq    INT,
    @CodeHelpSeq    INT,
    @DefQueryOption INT, -- 2: direct search
    @CodeHelpType   TINYINT,
    @PageCount      INT = 20,
    @CompanySeq     INT = 0,
    @Keyword        NVARCHAR(50) = '',
    @Param1         NVARCHAR(50) = '',  -- 자국통화 포함여부(1=포함, 0=제외)
    @Param2         NVARCHAR(50) = '',
    @Param3         NVARCHAR(50) = '',
    @Param4         NVARCHAR(50) = ''
     -- 새로 추가됨 : _TCACodeHelpData에 UseLoginInfo 값이 1일때만 아래 파라메터 호출됨.      
     , @AccUnit          INT = NULL      
     , @BizUnit          INT = NULL      
     , @FactUnit         INT = NULL      
     , @DeptSeq          INT = NULL      
     , @WkDeptSeq        INT = NULL      
     , @EmpSeq           INT = NULL      
     , @UserSeq          INT = NULL   
AS

    SET ROWCOUNT @PageCount

	SELECT A.DeptSeq, A.DeptName
	FROM	_TDADept				AS A WITH(NOLOCK)
	LEFT OUTER JOIN hencom_TDADeptAdd	AS B WITH(NOLOCK) ON A.CompanySeq = B.CompanySeq AND A.DeptSeq = B.DeptSeq  
	
	WHERE B.DispQC = '1' 
       AND A.DeptName LIKE '%' + @Keyword + '%'
	ORDER BY B.DispSeq
 

    SET ROWCOUNT 0

    RETURN
/**********************************************************************************************************/
