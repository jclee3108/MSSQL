IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id('mnpt_SCACodeHelpProject'))
DROP PROCEDURE dbo.mnpt_SCACodeHelpProject
GO  
  /************************************************************
 설  명		- 여러화면의.. 프로젝트코드도움
 작성일		- 2017년 9월 12일  
 작성자		- 방혁
 수정사항		- 
 ************************************************************/
CREATE PROCEDURE mnpt_SCACodeHelpProject
	@WorkingTag     NVARCHAR(1),                    
    @LanguageSeq    INT,                    
    @CodeHelpSeq    INT,                    
    @DefQueryOption INT, -- 2: direct search                    
    @CodeHelpType   TINYINT,                    
    @PageCount      INT = 20,         
    @CompanySeq     INT = 1,                   
    @Keyword        NVARCHAR(50) = '',                    
    @Param1         NVARCHAR(50) = '',        
    @Param2         NVARCHAR(50) = '',        
    @Param3         NVARCHAR(50) = '',        
    @Param4         NVARCHAR(50) = ''        
AS     


	SELECT G.PJTName,
		   G.PJTNo,
		   A.ContractName,
		   A.ContractNo,
		   C.MinorName			AS UMContractTypeName,
		   D.MinorName			AS UMContractKindName,
		   E.MinorName			AS UMChargeTypeName,
		   A.IsFakeContract,
		   H.PJTTypeName,
		   I.ItemClassLName		AS PJTTypeClassLName,
		   I.ItemClassMName		AS PJTTypeClassMName,
		   I.ItemClassSName		AS PJTTypeClassSName,
		   J.EmpName			AS ChargeEmpName,
		   K.DeptName			AS ChargeDeptName,
           A.CustSeq, 
		   L.CustName,
		   CASE WHEN M.UMCustKindName IS NULL OR LEN(M.UMCustKindName) = 0 THEN '' 
		   	ELSE  SUBSTRING(M.UMCustKindName, 1,  LEN(M.UMCustKindName) -1 ) END   AS UMCustKindName,
		   N.CustName			AS AGCustName,
		   O.CustName			AS BKCustName,
		   A.PlanFrDate,
		   A.PlanToDate,
		   A.ContractFrDate,
		   A.ContractToDate,
		   A.ContractPayCondition,
		   A.ContractGoodsCondition,
		   A.EtcCondition,
		   A.CustRequest1,
		   A.CustRequest2,
		   A.CustRequest3,
		   F.GoodsName,
		   F.GoodsQty,
		   CASE WHEN F.UMApplyTonnage = 1015780001 THEN F.GoodsMTWeight
		   		WHEN F.UMApplyTonnage = 1015780002 THEN F.GoodsCBMWeight
		   		WHEN F.UMApplyTonnage = 1015780003 THEN F.GoodsRTWeight
		   		END					AS Weight,
		   P.MinorName				AS UMApplyTonnageName,
		   F.GoodsMTWeight,
		   F.GoodsCBMWeight,
		   F.GoodsRTWeight,
		   F.GoodsLData,
		   F.GoodsWData,
		   F.GoodsHData,
		   --CASE WHEN A.ShipSeq = 0 THEN A.IFShipCode2
		   --		ELSE Q.IFShipCode 
		   --		END					AS IFShipCode,
		   
		   --CASE WHEN A.ShipSeq = 0 THEN A.EnShipName2
		   --		ELSE Q.EnShipName 
		   --		END					AS EnShipName,
		   --CASE WHEN A.ShipSeq = 0 THEN A.ShipName2
		   --		ELSE Q.ShipName 
		   --		END					AS ShipName,
		   --CASE WHEN ISNULL(A.ShipSeq, 0) = 0 THEN A.LOA
		   --		ELSE Q.LOA
		   --		END					AS LOA,
		   --CASE WHEN ISNULL(A.ShipSeq, 0) = 0 THEN A.DRAFT
		   --		ELSE Q.DRAFT
		   --		END					AS DRAFT,
		   --CASE WHEN ISNULL(A.ShipSeq, 0) = 0 THEN A.TotalTON
		   --		ELSE Q.TotalTON
		   --		END					AS TotalTON,
		   A.ContractSeq,
		   F.PJTSeq,
		   B.BizUnitName,
		   B.BizUnit, 
           G.CCtrSeq, 
           U.CCtrName, -- 프로젝트활동센터 
           F.UMLoadType AS UMLoadTypeC, -- 하역방식(계약)
           R.MinorName AS UMLoadTypeCName, -- 하역방식(계약) 
           CASE WHEN S.UMLoadTypeCCnt > 1 THEN 0 ELSE S.UMLoadTypeW END AS UMLoadTypeW, -- 하역방식(작업)
           CASE WHEN S.UMLoadTypeCCnt > 1 THEN '' ELSE S.UMLoadTypeWName END AS UMLoadTypeWName -- 하역방식(작업)

		FROM mnpt_TPJTContract AS A WITH(NOLOCK)
			LEFT  JOIN _TDABizUnit AS B WITH(NOLOCK)
					ON B.CompanySeq	= A.CompanySeq
				   AND B.BizUnit		= A.BizUnit
			LEFT  JOIN _TDAUMinor AS C WITH(NOLOCK)
					ON C.CompanySeq	= A.CompanySeq
				   AND C.MinorSeq	= A.UMContractType
			LEFT  JOIN _TDAUMinor AS D WITH(NOLOCK)
					ON D.CompanySeq	= A.CompanySeq
				   AND D.MinorSeq	= A.UMContractKind
			LEFT  JOIN _TDAUMinor AS E WITH(NOLOCK)
					ON E.CompanySeq	= A.CompanySeq
				   AND E.MinorSeq	= A.UMChargeType
			LEFT  JOIN mnpt_TPJTProject AS F WITH(NOLOCK)
					ON F.CompanySeq	= A.CompanySeq
				   AND F.ContractSeq	= A.ContractSeq
			LEFT  JOIN _TPJTProject AS G WITH(NOLOCK)
					ON G.CompanySeq	= F.CompanySeq
				   AND G.PJTSeq		= F.PJTSeq
			LEFT  JOIN _TPJTType AS H WITH(NOLOCK)
					ON H.CompanySeq	= G.CompanySeq
				   AND H.PJTTypeSeq	= G.PJTTypeSeq
			LEFT  JOIN _VDAItemClass AS I
					ON I.CompanySeq		= H.CompanySeq
				   AND I.ItemClassSSeq	= H.ItemClassSeq
			LEFT  JOIN _TDAEmp AS J WITH(NOLOCK)
					ON J.CompanySeq	= A.CompanySeq
				   AND J.EmpSeq		= A.EmpSeq
			LEFT  JOIN _TDADept AS K WITH(NOLOCK)
					ON K.CompanySeq	= A.CompanySeq
				   AND K.DeptSeq		= A.DeptSeq
			LEFT  JOIN _TDACust AS L WITH(NOLOCK)
					ON L.CompanySeq	= A.CompanySeq
				   AND L.CustSeq		= A.CustSeq
			LEFT  JOIN (
						SELECT CustSeq,
								(
									SELECT B.Minorname + ','
										FROM _TDACustKind AS A WITH(NOLOCK)
											LEFT  JOIN _TDAUMinor AS B WITH(NOLOCK)
													ON B.CompanySeq	= A.CompanySeq
													AND B.MinorSeq	= A.UMCustKind
										WHERE A.CompanySeq	= @CompanySeq
										AND A.CustSeq	= C.CustSeq
										ORDER BY CustSeq for xml path('')
								) AS UMCustKindName
							FROM _TDACust AS C
							WHERE CompanySeq	= @CompanySeq
							GROUP BY CustSeq
					) AS M ON M.CustSeq	= A.CustSeq
			LEFT  JOIN _TDACust AS N WITH(NOLOCK)
					ON N.CompanySeq	= A.CompanySeq
				   AND N.CustSeq		= A.AGCustSeq
			LEFT  JOIN _TDACust AS O WITH(NOLOCK)
					ON O.CompanySeq	= A.CompanySeq
				   AND O.CustSeq		= A.BKCustSeq
			LEFT  JOIN _TDAUMinor AS P WITH(NOLOCK)
					ON P.CompanySeq	= F.CompanySeq
				   AND P.MinorSeq	= F.UMApplyTonnage
			LEFT  JOIN MNPT_TPJTShipMaster AS Q WITH(NOLOCK)
					ON Q.CompanySeq	= A.CompanySeq
				   AND Q.ShipSeq		= A.ShipSeq
			LEFT  JOIN _TDAUMinor AS R WITH(NOLOCK)
					ON R.CompanySeq	= A.CompanySeq
				   AND R.MinorSeq = F.UMLoadType 
            LEFT  JOIN (
                        SELECT B.ValueSeq AS UMLoadTypeC, 
                               MAX(A.MinorName) AS UMLoadTypeWName, -- 하역방식(작업)
                               MAX(A.MinorSeq) AS UMLoadTypeW, 
                               COUNT(1) AS UMLoadTypeCCnt
                          FROM _TDAUMinor                   AS A   
                          LEFT OUTER JOIN _TDAUMinorValue   AS B ON ( B.CompanySeq = @CompanySeq AND B.MinorSeq = A.MinorSeq AND B.Serl = 1000001 ) 
                         WHERE A.CompanySeq	= @CompanySeq 
                           AND A.MajorSeq = 1015935 
                         GROUP BY B.ValueSeq 
                       ) AS S ON ( S.UMLoadTypeC = F.UMLoadType ) 
            LEFT  JOIN _TDAUMinorValue AS T ON ( T.CompanySeq = @CompanySeq AND T.MinorSeq = A.UMContractKind AND T.Serl = 1000002 ) 
            LEFT  JOIN _TDACCtr        AS U ON ( U.CompanySeq = @CompanySeq AND U.CCtrSeq = G.CCtrSeq ) 
	WHERE A.CompanySeq		= @CompanySeq
	   	AND F.SourcePJTseq	= 0
		
        AND ( @Keyword = '' 
             OR (@DefQueryOption = '1' AND CASE WHEN @CodeHelpSeq = 13820008 THEN G.PJTName
                                                WHEN @CodeHelpSeq = 13820015 THEN G.PJTNo
                                                END LIKE @Keyword ) 
             OR (@DefQueryOption = '2' AND L.CustName LIKE @Keyword )
            ) 

		AND A.ContractSeq		= CASE WHEN @Param1 <> '' THEN @Param1
									   WHEN @Param1 = ''  THEN A.ContractSeq
									   END
		AND G.PJTTypeSeq		= CASE WHEN @Param2 <> '' THEN @Param2
									   WHEN @Param2 = ''  THEN G.PJTTypeSeq
									   END 
        AND ( @Param3 = '' OR ISNULL(T.ValueText,'0') = @Param3 ) 
        


