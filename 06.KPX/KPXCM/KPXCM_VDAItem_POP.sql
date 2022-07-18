IF OBJECT_ID('KPXCM_VDAItem_POP') IS NOT NULL 
    DROP VIEW KPXCM_VDAItem_POP
GO 

-- v2016.05.12 

-- KPXCM View  by이재천 
CREATE VIEW KPXCM_VDAItem_POP
AS      
     -- 1. 품목정보      
     SELECT A.CompanySeq     AS CompanySeq       
   ,ISNULL(A.ItemSeq,0)   AS ItemSeq          -- 품목내부코드        
   ,ISNULL(A.ItemNo,'')   AS ItemNo           -- 품목번호        
   ,ISNULL(A.ItemName,'')   AS ItemName         -- 품목명        
   ,CASE WHEN ISNULL(A.ItemEngSName,'') = '' THEN ISNULL(A.ItemSName,'') ELSE ISNULL(A.ItemEngSName,'') END AS ItemEngSName -- 영문약명 
   ,ISNULL(A.Spec,'')    AS Spec             -- 규격        
   ,ISNULL(A.UnitSeq,0)   AS UnitSeq          -- 기준단위코드      
   ,ISNULL((CASE WHEN J.MinorValue = 0 THEN '1'  -- 제상품      
                          WHEN J.MinorValue = 1 THEN '0'  -- 자재      
        ELSE '' END) ,'') AS ItemType   -- 품목구분 '1' : 제품 (품목자산분류가 상품,제품,반제품인 경우) '2' : 자재 (품목자산분류가 재공품,원자재,부자재인 경우)      
   ,ISNULL(A.AssetSeq,0)   AS AssetSeq         -- 품목자산분류코드        
   ,ISNULL(C.AssetName,'')   AS AssetName        -- 품목자산분류명      
   ,C.SMAssetGrp 
   ,ISNULL(A.SMStatus,0)   AS ItemStatusSeq    -- 품목상태코드      
   ,CASE WHEN ISNULL(A.SMStatus,0) = 0 THEN ''      
      ELSE (SELECT ISNULL(MinorName,'') FROM _TDASMinor WITH (NOLOCK) WHERE CompanySeq = A.CompanySeq AND MajorSeq = 2001 AND MinorSeq = A.SMStatus)       
    END       AS ItemStatus  -- 품목 상태      
   ,ISNULL(S.STDUnitSeq, 0)        AS BOMUnitSeq       -- BOM단위코드      
   ,ISNULL(L.ValueSeq,0)   AS ItemClassLSeq    -- 품목대분류코드       
   ,ISNULL(K.ValueSeq,0)   AS ItemClassMSeq    -- 품목중분류코드       
   ,ISNULL(B.UMItemClass,0)  AS ItemClassSSeq    -- 품목소분류코드        
   ,ISNULL(T.ConvNum, 0)   AS ConvNum   -- BOM단위 환산 분자      
   ,ISNULL(T.ConvDen, 0)   AS ConvDen   -- BOM단위 환산 분모      
   ,ISNULL((SELECT TOP 1 InWHSeq FROM _TDAItemStdWH WHERE CompanySeq = A.CompanySeq AND ItemSeq = A.ItemSeq), 0)   AS InWHSeq     -- 기본입고창고      
   ,ISNULL((SELECT TOP 1 OutWHSeq FROM _TDAItemStdWH WHERE CompanySeq = A.CompanySeq AND ItemSeq = A.ItemSeq),0)   AS OutWHSeq    -- 기본출고창고      
   ,F.MngValSeq                    AS UserDefine      
   ,case when isNumeric(R.MngValText)  = 0 then '' else   R.MngValText end               AS UserDefineSTDYR      
   ,case when isNumeric(M.MngValText)  = 0 then '' else   M.MngValText end    AS UserDefineSTDTime1    
   ,case when isNumeric(P.MngValText)  = 0 then '' else   P.MngValText end    AS UserDefineSTDTime2    
   ,Z.LastDateTime          --최종일자      
     ,Q.IsLotMng                     AS IsLotMng 
     ,isnull(N1.MinorName,'')                   AS WashFlag   
	 ,U1.ProcSeq  As ProcSeq
	 ,U1.ItemSeq  AS GoodItemSeq
       FROM _TDAItem      AS A WITH(NOLOCK)         
      LEFT OUTER JOIN _TDAItemClass   AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) )       
      LEFT OUTER JOIN _TDAItemAsset   AS C WITH(NOLOCK) ON ( A.CompanySeq = C.CompanySeq AND A.AssetSeq = C.AssetSeq )       
            LEFT OUTER JOIN _TDASMInor      AS E WITH(NOLOCK) ON (C.CompanySeq = E.CompanySeq AND C.SMAssetGrp = E.MinorSeq)      
       LEFT OUTER JOIN _TDAItemSales   AS D WITH(NOLOCK) ON ( A.CompanySeq = D.CompanySeq AND A.ItemSeq = D.ItemSeq )       
      LEFT OUTER JOIN _TDAUMinor      AS H WITH(NOLOCK) ON ( B.CompanySeq = H.CompanySeq AND H.MajorSeq = LEFT( B.UMItemClass, 4 ) AND B.UMItemClass = H.MinorSeq )       
      LEFT OUTER JOIN _TDASMinor      AS J WITH(NOLOCK) ON ( C.CompanySeq = J.CompanySeq AND J.MajorSeq = 6008 AND C.SMAssetGrp = J.MinorSeq )       
      LEFT OUTER JOIN _TDAUMinorValue AS K WITH(NOLOCK) ON ( H.CompanySeq = K.CompanySeq AND K.MajorSeq IN (2001,2004) AND H.MinorSeq = K.MinorSeq AND K.Serl IN (1001,2001) )       
      LEFT OUTER JOIN _TDAUMinorValue AS L WITH(NOLOCK) ON ( K.CompanySeq = L.CompanySeq AND L.MajorSeq IN (2002,2005) AND K.ValueSeq = L.MinorSeq AND L.Serl = 2001 )      
            LEFT OUTER JOIN _TDAItemDefUnit AS S WITH(NOLOCK) ON (A.COmpanySeq = S.CompanySeq AND A.ItemSeq = S.ItemSeq AND S.UMModuleSeq = 1003004)      
            LEFT OUTER JOIN _TDAItemUnit    AS T WITH(NOLOCK) ON (S.CompanySeq = T.CompanySeq AND S.ItemSeq = T.ItemSeq AND S.STDUnitSeq = T.UnitSeq)      
      LEFT OUTER JOIN _TDAItemUserDefine AS F WITH(NOLOCK) ON F.CompanySeq = A.CompanySeq AND F.ItemSeq = A.ItemSeq AND F.MngSerl = 1000001      
      LEFT OUTER JOIN _TDAItemUserDefine AS R WITH(NOLOCK) ON R.CompanySeq = A.CompanySeq AND R.ItemSeq = A.ItemSeq AND R.MngSerl = 1000007   --수율      
      
      LEFT OUTER JOIN _TDAItemUserDefine AS M WITH(NOLOCK) ON M.CompanySeq = A.CompanySeq AND M.ItemSeq = A.ItemSeq AND M.MngSerl = 1000008   --표준작업시간      
      LEFT OUTER JOIN _TDAItemUserDefine AS P WITH(NOLOCK) ON P.CompanySeq = A.CompanySeq AND P.ItemSeq = A.ItemSeq AND P.MngSerl = 1000009   --표준작업시간(후공정)      
        LEFT OUter JOin _TDAItemStock      AS Q With(nolock) ON A.CompanySEq = Q.CompanySeq And A.ItemSeq = Q.ItemSeq    
      LEFT OUTER JOIN _TDAItemUserDefine AS N WITH(NOLOCK) ON N.CompanySeq = A.CompanySeq AND N.ItemSeq = A.ItemSeq AND N.MngSerl = 1000003   --생산분류(세척)      
      LEFT OUTER JOIN _TDAUMinor      AS N1 WITH(NOLOCK) ON ( N.CompanySeq = N1.CompanySeq and N.MngValSeq = N1.MinorSeq )       
	  Left Outer Join (select CompanySeq,ItemSeq,AssyItemSeq,max(ProcSeq) ProcSeq
	     from _TPDROUItemProcMat AS U With(nolock) 
		group by CompanySeq,ItemSeq,AssyItemSeq ) as U1 ON A.CompanySeq = U1.CompanySeq 
		                                              and  A.ItemSeq = U1.AssyItemSeq
             
   
      LEFT OUTER JOIN (SELECT ItemSeq, MAX(LastDateTime) AS LastDateTime      
             FROM (SELECT A.ItemSeq, A.LastDateTime      
               FROM _TDAItem                        AS A WITH(NOLOCK)      
             UNION ALL      
             SELECT A.ItemSeq, S.LastDateTime      
               FROM _TDAItem                        AS A WITH(NOLOCK)      
               LEFT OUTER JOIN _TDAItemDefUnit AS S WITH(NOLOCK) ON (A.COmpanySeq = S.CompanySeq AND A.ItemSeq = S.ItemSeq AND S.UMModuleSeq = 1003004)      
             UNION ALL      
             SELECT A.ItemSeq, T.LastDateTime      
               FROM _TDAItem                        AS A WITH(NOLOCK)      
               LEFT OUTER JOIN _TDAItemDefUnit AS S WITH(NOLOCK) ON (A.COmpanySeq = S.CompanySeq AND A.ItemSeq = S.ItemSeq AND S.UMModuleSeq = 1003004)      
               LEFT OUTER JOIN _TDAItemUnit    AS T WITH(NOLOCK) ON (S.CompanySeq = T.CompanySeq AND S.ItemSeq = T.ItemSeq AND S.STDUnitSeq = T.UnitSeq)      
             UNION ALL      
             SELECT A.ItemSeq, I1.LastDateTime      
               FROM _TDAItem                        AS A WITH(NOLOCK)      
               LEFT OUTER JOIN _TDAItemClass   AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) )       
               LEFT OUTER JOIN _TDAItemUserDefine AS I1 WITH(NOLOCK) ON (A.CompanySeq = I1.CompanySeq AND A.ItemSeq = I1.ItemSeq AND I1.MngSerl = 1000001 AND B.UMajorItemClass = 2001)      
             UNION ALL      
             SELECT A.ItemSeq, I2.LastDateTime      
               FROM _TDAItem                        AS A WITH(NOLOCK)      
               LEFT OUTER JOIN _TDAItemClass   AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) )       
               LEFT OUTER JOIN _TDAItemUserDefine AS I2 WITH(NOLOCK) ON (A.CompanySeq = I2.CompanySeq AND A.ItemSeq = I2.ItemSeq AND I2.MngSerl = 1000002 AND B.UMajorItemClass = 2001)      
             UNION ALL      
             SELECT A.ItemSeq, I3.LastDateTime      
               FROM _TDAItem                        AS A WITH(NOLOCK)      
               LEFT OUTER JOIN _TDAItemClass   AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) )       
               LEFT OUTER JOIN _TDAItemUserDefine AS I3 WITH(NOLOCK) ON (A.CompanySeq = I3.CompanySeq AND A.ItemSeq = I3.ItemSeq AND I3.MngSerl = 1000003 AND B.UMajorItemClass = 2001)      
             UNION ALL      
             SELECT A.ItemSeq, I4.LastDateTime      
               FROM _TDAItem                        AS A WITH(NOLOCK)      
               LEFT OUTER JOIN _TDAItemClass   AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) )       
               LEFT OUTER JOIN _TDAItemUserDefine AS I4 WITH(NOLOCK) ON (A.CompanySeq = I4.CompanySeq AND A.ItemSeq = I4.ItemSeq AND I4.MngSerl = 1000004 AND B.UMajorItemClass = 2001)      
             UNION ALL      
             SELECT A.ItemSeq, I5.LastDateTime      
               FROM _TDAItem                        AS A WITH(NOLOCK)      
               LEFT OUTER JOIN _TDAItemClass   AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) )      
               LEFT OUTER JOIN _TDAItemUserDefine AS I5 WITH(NOLOCK) ON (A.CompanySeq = I5.CompanySeq AND A.ItemSeq = I5.ItemSeq AND I5.MngSerl = 1000005 AND B.UMajorItemClass = 2001)      
             UNION ALL      
             SELECT A.ItemSeq, I6.LastDateTime      
               FROM _TDAItem                        AS A WITH(NOLOCK)      
               LEFT OUTER JOIN _TDAItemClass   AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) )      
               LEFT OUTER JOIN _TDAItemUserDefine AS I6 WITH(NOLOCK) ON (A.CompanySeq = I6.CompanySeq AND A.ItemSeq = I6.ItemSeq AND I6.MngSerl = 1000006 AND B.UMajorItemClass = 2001)      
             UNION ALL      
             SELECT A.ItemSeq, I7.LastDateTime      
               FROM _TDAItem                        AS A WITH(NOLOCK)      
               LEFT OUTER JOIN _TDAItemClass   AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) )       
               LEFT OUTER JOIN _TDAItemUserDefine AS I7 WITH(NOLOCK) ON (A.CompanySeq = I7.CompanySeq AND A.ItemSeq = I7.ItemSeq AND I7.MngSerl = 1000007 AND B.UMajorItemClass = 2001)      
             UNION ALL      
             SELECT A.ItemSeq, I8.LastDateTime      
               FROM _TDAItem                        AS A WITH(NOLOCK)      
               LEFT OUTER JOIN _TDAItemClass   AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) )       
               LEFT OUTER JOIN _TDAItemUserDefine AS I8 WITH(NOLOCK) ON (A.CompanySeq = I8.CompanySeq AND A.ItemSeq = I8.ItemSeq AND I8.MngSerl = 1000008 AND B.UMajorItemClass = 2001)      
             UNION ALL      
             SELECT A.ItemSeq, I9.LastDateTime      
               FROM _TDAItem                        AS A WITH(NOLOCK)      
               LEFT OUTER JOIN _TDAItemClass   AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) )         
               LEFT OUTER JOIN _TDAItemUserDefine AS I9 WITH(NOLOCK) ON (A.CompanySeq = I9.CompanySeq AND A.ItemSeq = I9.ItemSeq AND I9.MngSerl = 1000009 AND B.UMajorItemClass = 2001)                                  
             UNION ALL      
             SELECT A.ItemSeq, I10.LastDateTime      
               FROM _TDAItem                        AS A WITH(NOLOCK)      
               LEFT OUTER JOIN _TDAItemClass   AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) )         
               LEFT OUTER JOIN _TDAItemUserDefine AS I10 WITH(NOLOCK) ON (A.CompanySeq = I10.CompanySeq AND A.ItemSeq = I10.ItemSeq AND I10.MngSerl = 1000010 AND B.UMajorItemClass = 2001)      
             UNION ALL      
             SELECT A.ItemSeq, U3.LastDateTime      
               FROM _TDAItem                        AS A WITH(NOLOCK)      
               LEFT OUTER JOIN _TDAItemClass   AS B WITH(NOLOCK) ON ( A.CompanySeq = B.CompanySeq AND A.ItemSeq = B.ItemSeq AND B.UMajorItemClass IN (2001,2004) )         
               LEFT OUTER JOIN _TDAItemUserDefine AS U3 WITH(NOLOCK) ON (A.CompanySeq = U3.CompanySeq AND A.ItemSeq = U3.ItemSeq AND U3.MngSerl = 1000003 AND B.UMajorItemClass = 2004)      
               ) AS A      
           GROUP BY A.ItemSeq) AS Z ON Z.ItemSeq = A.ItemSeq      
      WHERE A.CompanySeq  in ( 1 ,2 )     


GO


