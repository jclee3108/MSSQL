IF OBJECT_ID('KPX_SSLSampleOutReqGWQuery') IS NOT NULL 
    DROP PROC KPX_SSLSampleOutReqGWQuery
GO 

 /************************************************************      
  설  명 - 데이터-샘플출고요청_KPX GW조회      
  작성일 - 20150720
  작성자 - 영림원
 ************************************************************/      
  CREATE PROC dbo.KPX_SSLSampleOutReqGWQuery      
  @xmlDocument    NVARCHAR(MAX),    
  @xmlFlags       INT     = 0,    
  @ServiceSeq     INT     = 0,    
  @WorkingTag     NVARCHAR(10)= '',    
  @CompanySeq     INT     = 1,    
  @LanguageSeq    INT     = 1,    
  @UserSeq        INT     = 0,    
  @PgmSeq         INT     = 0    
 AS     
   
  DECLARE @docHandle      INT,  
             @ReqSeq      INT 
          
          
     EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument      
    
    CREATE TABLE #KPX_TSLSampleOutReq ( ReqSeq INT ) 
    
    INSERT INTO #KPX_TSLSampleOutReq ( ReqSeq ) 
     SELECT  ISNULL(ReqSeq, 0)      
       FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)      
       WITH (      
             ReqSeq      INT      
            ) 
    
    SELECT  A.ReqSeq AS ReqSeq, 
            A.ReqNo AS ReqNo,  -- 요청번호             
            A.Purpose AS Purpose, -- 목적
            T.CustName AS CustName, -- 거래처         
            A.ReqDate AS ReqDate, -- 신청일  
            A.CompleteWishDate AS CompleteWishDate, -- 도착희망일
            I.ItemSeq,                      
            M.ItemName AS ItemName, -- 품명
            M.ItemNo,                
            M.Spec,
            I.UnitSeq,
            B.UnitName AS UnitName, -- 단위             
            I.Qty,     -- 수량   
            I.STDQty, 
            A.CustEmpName, 
            A.CustAddr, 
            A.ContactInfo
       FROM #KPX_TSLSampleOutReq AS Z 
                        JOIN KPX_TSLSampleOutReq AS A WITH(NOLOCK) ON ( A.CompanySeq = @CompanySeq AND A.ReqSeq = Z.ReqSeq ) 
             LEFT OUTER JOIN _TDACust AS T WITH(NOLOCK) ON T.CompanySeq = A.CompanySeq AND T.CustSeq = A.CustSeq     
             LEFT OUTER JOIN KPX_TSLSampleOutReqItem AS I WITH(NOLOCK) ON I.CompanySeq = A.CompanySeq AND I.ReqSeq = A.ReqSeq    
             LEFT OUTER JOIN _TDAItem AS M WITH(NOLOCK) ON M.CompanySeq = I.CompanySeq AND M.ItemSeq = I.ItemSeq       
             LEFT OUTER JOIN _TDAUnit AS B WITH(NOLOCK) ON B.CompanySeq = I.CompanySeq AND B.UnitSeq = I.UnitSeq
    
    RETURN
go

EXEC _SCOMGroupWarePrint 2, 1, 1, 1025779, 'SampleOutReq_CM', 'GROUP000000000000063', ''






