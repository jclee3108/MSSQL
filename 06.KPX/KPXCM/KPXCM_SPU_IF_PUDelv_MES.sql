IF OBJECT_ID('KPXCM_SPU_IF_PUDelv_MES') IS NOT NULL 
    DROP PROC KPXCM_SPU_IF_PUDelv_MES
GO 

-- v2015.09.23 

-- 발주정보 MES 연동 by이재천 
CREATE Proc KPXCM_SPU_IF_PUDelv_MES    
   @CompanySeq INT = 2    
 as     
    
    
    select A.CompanySeq    
      --,F.BizUnit    
      ,5   as BizUnit    
      ,A.POSeq    
      ,A.PONO    
      ,B.POSerl    
      ,A.PODate    
      ,C.CustName    
      ,D.ItemNo    
      ,D.Spec    
      ,E.UnitName    
      ,Isnull(convert(float,G.MngValText ),0)    AS LotUnitQty     
      ,convert(INT,B.StdUnitQty)  AS LotQty    
      ,Case when Isnull(J.WorkingTag,'D') = 'D' then  'A' else 'U' end    AS WorkingTag    
      ,'0'               AS ProcYn    
      ,'N'               AS ConfirmFlag    
      ,GetDate()         AS CreateTime    
      ,''                AS UpdateTime    
      ,''                AS ConfirmTime    
      ,''                AS ErrorMessage      
      , case when A.SmImpType = 8008001   then '0' else '1' end   as ImpType  
      ,B.LastDateTime   AS LastDateTime  
  Into #IF_PUDelv_MES     
  from _TPUORDPO AS A (NOLOCK)    
       Join _TPUORDPoItem AS  B with(Nolock) ON A.CompanySeq = B.CompanySeq And A.POSeq = B.POSeq    
       Join _TDACust      AS  C With(Nolock) ON A.CompanySeq = C.CompanySeq And A.CustSeq = C.CustSeq     
       Join _TDAItem      AS  D With(Nolock) ON B.CompanySeq = D.CompanySeq And B.ItemSeq = D.ItemSeq    
       Join _TDAUnit      AS  E With(Nolock) ON A.CompanySeq = E.CompanySeq And D.UnitSeq = E.UnitSeq    
       Join _TDAWh        AS  F with(Nolock) ON B.CompanySeq = F.CompanySeq And B.WhSeq = F.WhSeq    
       Left Outer Join _TDAItemUserDefine AS G with(Nolock) ON G.CompanySeq = D.CompanySeq  
                                                           And G.ItemSeq = D.ItemSeq  
                                                           And G.MngSerl = '1000012'    
       Left OUter Join (select H.CompanySeq , H.BizUnit,H.POSeq,H.POSerl ,H.WorkingTag   
                          from IF_PUDelv_MES AS H With(Nolock)  
                         where Serl in (select MAX(Serl) from IF_PUDelv_MES AS I With(nolock)   
                                          where H.CompanySeq = I.CompanySeq  
                                           and H.POSeq  = I.PoSeq  
                                           and H.POSerl = I.PoSerl) ) AS J ON J.CompanySeq = B.CompanySeq   
                                                                          And J.POSeq = B.POSeq  
                                                                          And J.POSerl = B.POSerl  
  
where A.CompanySeq = 2    
  and F.BizUnit = 26  --천안사업장    
 -- and A.POSeq NOT IN (select PoSeq from IF_PUDelv_MES)     
  and B.LastDateTime > (select Isnull(max(LastDateTime),'') from IF_MES_INTERFaceTime (Nolock)     
                         where CompanySeq = @CompanySeq     
                           and TableName = '_TPUORDPoItem')   
                              
 Insert into IF_PUDelv_MES(CompanySeq,BizUnit,POSeq,PONo,POSerl,PODate,CustName  
                           ,ItemNo,Spec,UnitName,LotUnitQty,LotQty,WorkingTag,ProcYn  
                           ,ConfirmFlag,CreateTime,UpdateTime,ConfirmTime,ErrorMessage,ImpType)  
  select  CompanySeq,BizUnit,POSeq,PONo,POSerl,PODate,CustName  
                           ,ItemNo,Spec,UnitName,LotUnitQty,LotQty,WorkingTag,ProcYn  
                           ,ConfirmFlag,CreateTime,UpdateTime,ConfirmTime,ErrorMessage,ImpType  
   from #IF_PUDelv_MES  
  
  
     
 if exists (select 1 from IF_MES_INTERFaceTime  (nolock) where CompanySeq = 2 and TableName = '_TPUORDPoItem'  )    
 begin    
       If exists(select 1  from #IF_PUDelv_MES )   
      Begin  
   update IF_MES_INTERFaceTime    
      set LastDateTime = (select max(LastDateTime)    
          from #IF_PUDelv_MES  )  
    where CompanySeq = @CompanySeq    
      and TableName = '_TPUORDPoItem'    
      end  
     
 end    
 else    
 begin    
     Insert into IF_MES_INTERFaceTime    
      select  CompanySeq          AS CompanySeq    
             ,'_TPUORDPoItem'     AS TableName     
             ,max(LastDateTime )  As LastDateTime    
      from #IF_PUDelv_MES     
   where CompanySeq = 2    
   group by CompanySeq    
 end     
    
return    
  