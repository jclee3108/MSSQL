
IF OBJECT_ID('_SGACompHouseCostMasterQueryCHE') IS NOT NULL 
    DROP PROC _SGACompHouseCostMasterQueryCHE
GO 

/************************************************************    
 설  명 - 데이터-사택료항목정의정보 : 조회    
 작성일 - 20110315    
 작성자 - 박헌기    
************************************************************/    
CREATE PROC _SGACompHouseCostMasterQueryCHE    
    @xmlDocument    NVARCHAR(MAX),    
    @xmlFlags       INT             = 0,    
    @ServiceSeq     INT             = 0,    
    @WorkingTag     NVARCHAR(10)    = '',    
    @CompanySeq     INT             = 1,    
    @LanguageSeq    INT             = 1,    
    @UserSeq        INT             = 0,    
    @PgmSeq         INT             = 0    
AS    
    
    DECLARE @docHandle      INT,    
            @HouseClass        INT ,    
            @CostType          INT    
    
    EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument    
    
    SELECT  @HouseClass        = HouseClass         ,    
            @CostType          = CostType    
      FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)    
      WITH  (HouseClass         INT ,    
            CostType           INT )    
    
    SELECT  A.CompanySeq        ,    
            A.CostSeq           ,    
            A.HouseClass        ,    
            B.MinorName HouseClassName   ,--사택구분    
            A.CostType          ,    
            C.MinorName CostTypeName     ,--비용항목    
            A.ApplyFrDate       ,    
            A.ApplyToDate       ,    
            A.CalcType          ,    
            D.MinorName CalcTypeName     ,--적용방식    
            A.PackageAmt        ,    
            A.FreeApplyYn       ,    
            A.CalcPointType     ,    
            E.MinorName CalcPointTypeName,--금액계산위치    
            A.AmtCalcType       ,    
            F.MinorName AmtCalcTypeName  ,--금액계산방식    
            A.OrderNo           ,    
            A.Remark    
      FROM  _TGACompHouseCostMaster AS A WITH (NOLOCK)    
            LEFT OUTER JOIN _TDAUMinor AS B WITH(NOLOCK) ON A.CompanySeq    = B.CompanySeq    
                                                        AND A.HouseClass    = B.MinorSeq       
            LEFT OUTER JOIN _TDAUMinor AS C WITH(NOLOCK) ON A.CompanySeq    = C.CompanySeq    
                                                        AND A.CostType      = C.MinorSeq                                                                    
            LEFT OUTER JOIN _TDAUMinor AS D WITH(NOLOCK) ON A.CompanySeq    = D.CompanySeq    
                                                        AND A.CalcType      = D.MinorSeq                                                                   
            LEFT OUTER JOIN _TDASMinor AS E WITH(NOLOCK) ON A.CompanySeq    = E.CompanySeq    
                                                        AND A.CalcPointType = E.MinorSeq    
            LEFT OUTER JOIN _TDASMinor AS F WITH(NOLOCK) ON A.CompanySeq    = F.CompanySeq    
                                                        AND A.AmtCalcType   = F.MinorSeq                                                                                                                                  
                                                                     
     WHERE  A.CompanySeq         = @CompanySeq    
       AND  (@HouseClass = 0 OR A.HouseClass         = @HouseClass)    
       AND  (@CostType   = 0 OR A.CostType           = @CostType)    
     ORDER BY A.OrderNo   
      RETURN   
      