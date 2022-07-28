
IF OBJECT_ID('_SSEVicegerentListQueryCHE') IS NOT NULL 
    DROP PROC _SSEVicegerentListQueryCHE
GO 

-- v2015.03.13 

/************************************************************
  ��  �� - ������-�����������_capro : ����Ʈ��ȸ
  �ۼ��� - 20110329
  �ۼ��� - ������
 ************************************************************/
 CREATE PROC [dbo].[_SSEVicegerentListQueryCHE]
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
             @InspectOrgan      NVARCHAR(50) ,
             @InspectResult     INT ,
             @InspectDateFrom   NCHAR(8) ,
             @InspectDateTo     NCHAR(8) 
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
      SELECT  @InspectOrgan      = InspectOrgan       ,
             @InspectResult     = InspectResult      ,
             @InspectDateFrom   = InspectDateFrom    ,
             @InspectDateTo     = InspectDateTo      
       FROM  OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
       WITH  (InspectOrgan       NVARCHAR(50) ,
             InspectResult      INT ,
             InspectDateFrom    NCHAR(8) ,
             InspectDateTo      NCHAR(8) )
     
     SELECT  A.InspectSeq        , 
             A.InspectDate       , 
             A.InspectOrgan      , 
             A.InspectResult     , 
             B.MinorName AS InspectResultName,
             A.Inspector         , 
             A.InspectContent    , 
             A.Pointed           ,
             A.Remark            , 
             A.JoinEmpName, 
             A.MRemark 
       FROM  _TSEVicegerentCHE AS A WITH (NOLOCK)
             LEFT OUTER JOIN _TDAUMinor AS B WITH (NOLOCK) ON A.CompanySeq   = B.CompanySeq
                                                          AND A.InspectResult= B.MinorSeq
      WHERE  A.CompanySeq     = @CompanySeq
        AND  ( @InspectOrgan  = '' OR A.InspectOrgan       = @InspectOrgan      )
        AND  ( @InspectResult = '' OR A.InspectResult      = @InspectResult     )
        AND  A.InspectDate  BETWEEN @InspectDateFrom  AND @InspectDateTo    
         
      RETURN