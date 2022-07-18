
IF OBJECT_ID('KPX_SDAItemProductSave') IS NOT NULL 
    DROP PROC KPX_SDAItemProductSave
GO 

-- v2014.11.06 

-- 품목생산정보 저장 by이재천 (PgmSeq 저장하기위해 사이트로 생성)

/*************************************************************************************************  
  설  명 - 품목생산정보 저장  
  작성일 - 2008.6. : CREATED BY 김준모
  수정일 - 2011.9.1 김준식 LotSize(1일적정생산량) 추가
        -- 2014.01.09 : UPDATE BY 서보영 -- 최종검사여부 체크항목 추가
 *************************************************************************************************/  
 CREATE PROCEDURE KPX_SDAItemProductSave
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,  
     @WorkingTag     NVARCHAR(10)= '',  
     
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS  
     DECLARE @docHandle          INT,  
             @MaxSeq             INT,  
             @ItemSeq            INT
      -- 마스타 등록 생성  
     CREATE TABLE #TDAItemProduct (WorkingTag NCHAR(1) NULL)  
     ExEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TDAItemProduct'  
      -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
     EXEC _SCOMLog  @CompanySeq   ,  
                    @UserSeq      ,  
                    '_TDAItemProduct', -- 원테이블명  
                    '#TDAItemProduct', -- 템프테이블명  
                    'ItemSeq' , -- 키가 여러개일 경우는 , 로 연결한다.   
                    'CompanySeq,ItemSeq,SMConsgnmtKind,BOMUnitSeq,OutLoss,InLoss,SMMrpKind,SMOutKind,SMProdMethod,SMProdSpec,LastUserSeq,LastDateTime,PgmSeq'      
    
     -- 2014.01.09 : UPDATE BY 서보영 -- 최종검사여부 체크항목 추가
     SELECT CASE WHEN A.WorkingTag = 'A' AND ISNULL(B.ItemSeq, 0) <> 0 THEN 'U'
                 WHEN A.WorkingTag = 'A' AND ISNULL(B.ItemSeq, 0)  = 0 THEN 'A'
                 WHEN A.WorkingTag = 'U' AND ISNULL(B.ItemSeq, 0) <> 0 THEN 'U'
                 WHEN A.WorkingTag = 'U' AND ISNULL(B.ItemSeq, 0)  = 0 THEN 'A'
                 WHEN A.WorkingTag = 'D' AND ISNULL(B.ItemSeq, 0) <> 0 THEN 'D'
                 WHEN A.WorkingTag = 'D' AND ISNULL(B.ItemSeq, 0)  = 0 THEN '' END AS WorkingTag,
            A.IDX_NO, A.DataSeq, A.Selected, A.MessageType, A.Status, A.Result, A.ROW_IDX, A.ItemSeq, A.IsLastQc
       INTO #TPDBaseItemQCType
       FROM #TDAItemProduct AS A
       LEFT OUTER JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq    = B.ItemSeq
                                                            AND B.CompanySeq = @CompanySeq
      WHERE A.IsLastQc IS NOT NULL
        AND A.Status = 0
  
     -- 로그테이블 남기기(마지막 파라메터는 반드시 한줄로 보내기)  
     EXEC _SCOMLog  @CompanySeq   ,  
                    @UserSeq      ,  
                    '_TPDBaseItemQCType', -- 원테이블명  
                    '#TPDBaseItemQCType', -- 템프테이블명  
                    'ItemSeq' , -- 키가 여러개일 경우는 , 로 연결한다.   
                    'CompanySeq, ItemSeq, IsInQC, IsOutQC, IsLastQc, LastUserSeq, LastDateTime, IsInAfterQC, IsNotAutoIn, IsSutakQc'      
      -- DELETE    
     IF EXISTS (SELECT 1 FROM #TDAItemProduct WHERE WorkingTag = 'D' AND Status = 0  )  
     BEGIN  
         DELETE _TDAItemProduct
         FROM #TDAItemProduct AS A  
              JOIN _TDAItemProduct AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                     AND B.ItemSeq = A.ItemSeq
         WHERE A.WorkingTag = 'D' AND Status = 0
         
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END  
         
         -- 2014.01.09 : UPDATE BY 서보영 -- 최종검사여부 체크항목 추가
         IF EXISTS (SELECT 1 FROM #TPDBaseItemQCType AS A
                             JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                                       AND B.CompanySeq = @CompanySeq
                            WHERE A.WorkingTag = 'D' AND A.Status = 0 )
         BEGIN 
             DELETE _TPDBaseItemQCType
               FROM #TPDBaseItemQCType AS A
               JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                         AND B.CompanySeq = @CompanySeq
              WHERE A.WorkingTag = 'D' AND Status = 0
     
             IF @@ERROR <> 0    
             BEGIN    
                 RETURN    
             END  
         END
     END
      -- Update    
     IF EXISTS (SELECT 1 FROM #TDAItemProduct WHERE WorkingTag = 'U' AND Status = 0  )  
     BEGIN   
         UPDATE _TDAItemProduct  
            SET  SMConsgnmtKind = ISNULL(A.SMConsgnmtKind,0),
                 BOMUnitSeq     = ISNULL(A.BOMUnitSeq,0),
                 OutLoss        = ISNULL(A.OutLoss,0),
                 InLoss         = ISNULL(A.InLoss,0),
                 SMMrpKind      = ISNULL(A.SMMrpKind,0),
                 SMOutKind      = ISNULL(A.SMOutKind,0),
                 SMProdMethod   = ISNULL(A.SMProdMethod,0),
                 SMProdSpec     = ISNULL(A.SMProdSpec,0),
                 LastUserSeq    = @UserSeq,
                 LastDateTime   = GETDATE(),
                 LotSize        = ISNULL(A.LotSize,0), 
                 PgmSeq         = @PgmSeq 
           FROM #TDAItemProduct AS A  
                JOIN _TDAItemProduct AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                       AND B.ItemSeq = A.ItemSeq
          WHERE A.WorkingTag = 'U' AND A.Status = 0
          IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END  
  
         INSERT INTO _TDAItemProduct(  
             CompanySeq,
             ItemSeq,
             SMConsgnmtKind,
             BOMUnitSeq,
             OutLoss,
             InLoss,
             SMMrpKind,
             SMOutKind,
             SMProdMethod,
             SMProdSpec,
             LastUserSeq,
             LastDateTime,
             LotSize, 
             PgmSeq )
         SELECT
              @CompanySeq ,
              ISNULL(A.ItemSeq,0),
              ISNULL(A.SMConsgnmtKind,0),
              ISNULL(A.BOMUnitSeq,0),
              ISNULL(A.OutLoss,0),
              ISNULL(A.InLoss,0),
              ISNULL(A.SMMrpKind,0),
              ISNULL(A.SMOutKind,0),
              ISNULL(A.SMProdMethod,0),
              ISNULL(A.SMProdSpec,0),
              @UserSeq,  
              GETDATE(),
              ISNULL(A.LotSize,0), 
              @PgmSeq 
           FROM #TDAItemProduct AS A 
                LEFT OUTER JOIN _TDAItemProduct AS B WITH (NOLOCK) ON B.CompanySeq  = @CompanySeq  
                                                                  AND B.ItemSeq = A.ItemSeq
          WHERE A.WorkingTag = 'U' AND A.Status = 0 
            AND ISNULL(B.ItemSeq, 0) = 0
   
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END     
          -- 2014.01.09 : UPDATE BY 서보영 -- 최종검사여부 체크항목 추가        
         IF EXISTS (SELECT 1 FROM #TPDBaseItemQCType AS A
                             JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                                       AND B.CompanySeq = @CompanySeq
                            WHERE A.WorkingTag = 'U' AND A.Status = 0)
         BEGIN 
             UPDATE _TPDBaseItemQCType
                SET IsLastQc = ISNULL(A.IsLastQc,'0') 
               FROM #TPDBaseItemQCType AS A
               JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                         AND B.CompanySeq = @CompanySeq
              WHERE A.WorkingTag = 'U' AND Status = 0
     
             IF @@ERROR <> 0    
             BEGIN    
                 RETURN    
             END  
         END
         ELSE IF NOT EXISTS (SELECT 1 FROM #TPDBaseItemQCType AS A
                                      JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                                                AND B.CompanySeq = @CompanySeq
                              WHERE A.WorkingTag = 'A' AND A.Status = 0)
         BEGIN
             INSERT INTO _TPDBaseItemQCType(CompanySeq  , ItemSeq     , IsInQC      , IsOutQC     , IsLastQc ,
                                            LastUserSeq , LastDateTime, IsInAfterQC , IsNotAutoIn , IsSutakQc)
             SELECT @CompanySeq , A.ItemSeq , '0' , '0' , ISNULL(A.IsLastQc,'0'), 
                    @UserSeq    , GETDATE() , '0' , '0' , '0'
          FROM #TPDBaseItemQCType AS A 
              WHERE A.WorkingTag = 'A' AND Status = 0
              
             IF @@ERROR <> 0    
             BEGIN    
                 RETURN    
             END  
         END
         
     END  
      
     -- INSERT    
     IF EXISTS (SELECT 1 FROM #TDAItemProduct WHERE WorkingTag = 'A' AND Status = 0  )  
     BEGIN  
          INSERT INTO _TDAItemProduct(  
             CompanySeq,
             ItemSeq,
             SMConsgnmtKind,
             BOMUnitSeq,
             OutLoss,
             InLoss,
             SMMrpKind,
             SMOutKind,
             SMProdMethod,
             SMProdSpec,
             LastUserSeq,
             LastDateTime,
             LotSize, 
             PgmSeq )
         SELECT
              @CompanySeq ,
              ISNULL(ItemSeq,0),
              ISNULL(SMConsgnmtKind,0),
              ISNULL(BOMUnitSeq,0),
              ISNULL(OutLoss,0),
              ISNULL(InLoss,0),
              ISNULL(SMMrpKind,0),
              ISNULL(SMOutKind,0),
              ISNULL(SMProdMethod,0),
              ISNULL(SMProdSpec,0),
              @UserSeq,  
              GETDATE(),
              ISNULL(LotSize,0), 
              @PgmSeq
           FROM #TDAItemProduct   
          WHERE WorkingTag = 'A' AND Status = 0 
   
         IF @@ERROR <> 0    
         BEGIN    
             RETURN    
         END     
         
         -- 2014.01.09 : UPDATE BY 서보영 -- 최종검사여부 체크항목 추가        
         IF EXISTS (SELECT 1 FROM #TPDBaseItemQCType AS A
                             JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                                       AND B.CompanySeq = @CompanySeq
                            WHERE A.WorkingTag = 'U' AND A.Status = 0)
         BEGIN 
             UPDATE _TPDBaseItemQCType
                SET IsLastQc = ISNULL(A.IsLastQc,'0') 
               FROM #TPDBaseItemQCType AS A
               JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                         AND B.CompanySeq = @CompanySeq
              WHERE A.WorkingTag = 'U' AND Status = 0
     
             IF @@ERROR <> 0    
             BEGIN    
                 RETURN    
             END  
         END
         ELSE IF NOT EXISTS (SELECT 1 FROM #TPDBaseItemQCType AS A
                                      JOIN _TPDBaseItemQCType AS B WITH (NOLOCK) ON A.ItemSeq = B.ItemSeq
                                                                                AND B.CompanySeq = @CompanySeq
                              WHERE A.WorkingTag = 'A' AND A.Status = 0)
         BEGIN
             INSERT INTO _TPDBaseItemQCType(CompanySeq  , ItemSeq     , IsInQC      , IsOutQC     , IsLastQc ,
                                            LastUserSeq , LastDateTime, IsInAfterQC , IsNotAutoIn , IsSutakQc)
             SELECT @CompanySeq , A.ItemSeq , '0' , '0' , ISNULL(A.IsLastQc,'0'), 
                    @UserSeq    , GETDATE() , '0' , '0' , '0'
               FROM #TPDBaseItemQCType AS A 
              WHERE A.WorkingTag = 'A' AND Status = 0
              
             IF @@ERROR <> 0    
             BEGIN    
                 RETURN    
             END  
         END
          
     END      
     
     SELECT *  
       FROM #TDAItemProduct  
   
 RETURN  
 GO
 begin tran 
 exec KPX_SDAItemProductSave @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <SMConsgnmtKind>6003001</SMConsgnmtKind>
    <ConsgnmtKind>무상사급</ConsgnmtKind>
    <BOMUnitSeq>2</BOMUnitSeq>
    <BOMUnitName>EA</BOMUnitName>
    <SMMrpKind>6004002</SMMrpKind>
    <MrpKind>ROP</MrpKind>
    <OutLoss>567</OutLoss>
    <SMOutKind>6005002</SMOutKind>
    <OutKind>자동출고</OutKind>
    <InLoss>777</InLoss>
    <IsLastQc>0</IsLastQc>
    <SMProdMethod />
    <ProdMethod />
    <SMProdSpec />
    <ProdSpec />
    <LotSize>0</LotSize>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1025654,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1021312

rollback 