
IF OBJECT_ID('KPXCM_SSEAccidentGWQueryCHE') IS NOT NULL 
    DROP PROC KPXCM_SSEAccidentGWQueryCHE
GO 

-- v2015.06.24 

-- 사고조사등록 GW Query by이재천 
  CREATE PROC dbo.KPXCM_SSEAccidentGWQueryCHE
      @xmlDocument    NVARCHAR(MAX),
      @xmlFlags       INT             = 0,
      @ServiceSeq     INT             = 0,
      @WorkingTag     NVARCHAR(10)    = '',
      @CompanySeq     INT             = 1,
      @LanguageSeq    INT             = 1,
      @UserSeq        INT             = 0,
      @PgmSeq         INT             = 0
  AS
    
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
    
    DECLARE @docHandle      INT,
            @AccidentSeq    INT,
            @AccidentSerl   NCHAR(1)
    
      EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument
  
    SELECT @AccidentSeq    = ISNULL(AccidentSeq, ''),
           @AccidentSerl   = ISNULL(AccidentSerl, '')
    
      FROM OPENXML(@docHandle, N'/ROOT/DataBlock1', @xmlFlags)
      WITH (
            AccidentSeq    INT,
            AccidentSerl   NCHAR(1) 
           )
    
    SELECT A.AccidentSeq, 
           A.AccidentSerl, 
           A.AccidentName, -- 사고명칭 
           A.AccidentNo, -- 사고번호 
           J.EmpName AS ReporterName, -- 사고보고자 
           A.InvestFrDate + ' ~ ' + A.InvestToDate AS InvestDate, -- 조사일시
           C.EmpName AS EmpName, -- 사고자 
           STUFF(STUFF(A.AccidentDate,5,0,'-'),8,0,'-') AS AccidentDate, -- 사고일자 
           B.DeptName, 
           A.AccidentArea, -- 사고지역
           CASE WHEN A.AccidentClass = 20036001 THEN '■ 화재사고    □ 폭발사고    □ 누출사고    □ 상해사고    □ 아차사고' 
                WHEN A.AccidentClass = 20036002 THEN '□ 화재사고    ■ 폭발사고    □ 누출사고    □ 상해사고    □ 아차사고'
                WHEN A.AccidentClass = 20036003 THEN '□ 화재사고    □ 폭발사고    ■ 누출사고    □ 상해사고    □ 아차사고'
                WHEN A.AccidentClass = 20036004 THEN '□ 화재사고    □ 폭발사고    □ 누출사고    ■ 상해사고    □ 아차사고'
                WHEN A.AccidentClass = 20036005 THEN '□ 화재사고    □ 폭발사고    □ 누출사고    □ 상해사고    ■ 아차사고' 
                ELSE '□ 화재사고    □ 폭발사고    □ 누출사고    □ 상해사고    □ 아차사고' 
                END AS AccidentClassName, -- 사고분류
           
           CASE WHEN A.AccidentType = 20037001 THEN '■ 공정화재    □ 건물화재    □ 일반화재    □ 폭발  □ 내부누출    □ 외부누출' 
                WHEN A.AccidentType = 20037002 THEN '□ 공정화재    ■ 건물화재    □ 일반화재    □ 폭발  □ 내부누출    □ 외부누출' 
                WHEN A.AccidentType = 20037003 THEN '□ 공정화재    □ 건물화재    ■ 일반화재    □ 폭발  □ 내부누출    □ 외부누출' 
                WHEN A.AccidentType = 20037004 THEN '□ 공정화재    □ 건물화재    □ 일반화재    ■ 폭발  □ 내부누출    □ 외부누출' 
                WHEN A.AccidentType = 20037005 THEN '□ 공정화재    □ 건물화재    □ 일반화재    □ 폭발  ■ 내부누출    □ 외부누출' 
                WHEN A.AccidentType = 20037005 THEN '□ 공정화재    □ 건물화재    □ 일반화재    □ 폭발  □ 내부누출    ■ 외부누출' 
                ELSE '□ 공정화재    □ 건물화재    □ 일반화재    □ 폭발    □ 내부누출    □ 외부누출' 
                END AS AccidentTypeName, -- 사고형태  
           
           CASE WHEN A.AccidentGrade = 1011148001 THEN '■ 수질오염    □ 대기오염    □ 토양오염    □ 정전사고    □ 감전사고    □ 추락사고' 
                WHEN A.AccidentGrade = 1011148002 THEN '□ 수질오염    ■ 대기오염    □ 토양오염    □ 정전사고    □ 감전사고    □ 추락사고' 
                WHEN A.AccidentGrade = 1011148003 THEN '□ 수질오염    □ 대기오염    ■ 토양오염    □ 정전사고    □ 감전사고    □ 추락사고' 
                WHEN A.AccidentGrade = 1011148004 THEN '□ 수질오염    □ 대기오염    □ 토양오염    ■ 정전사고    □ 감전사고    □ 추락사고' 
                WHEN A.AccidentGrade = 1011148005 THEN '□ 수질오염    □ 대기오염    □ 토양오염    □ 정전사고    ■ 감전사고    □ 추락사고' 
                WHEN A.AccidentGrade = 1011148006 THEN '□ 수질오염    □ 대기오염    □ 토양오염    □ 정전사고    □ 감전사고    ■ 추락사고' 
                ELSE '□ 수질오염    □ 대기오염    □ 토양오염    □ 정전사고    □ 감전사고    □ 추락사고' 
                END AS AccidentGrade1, -- 세부분류1 
                
           CASE WHEN A.AccidentGrade = 1011148007 THEN '■ 전도사고    □ 충돌사고    □ 낙하·비래사고    □ 붕괴·도괴사고    □ 감전사고    □ 추락사고' 
                WHEN A.AccidentGrade = 1011148008 THEN '□ 전도사고    ■ 충돌사고    □ 낙하·비래사고    □ 붕괴·도괴사고    □ 감전사고    □ 추락사고' 
                WHEN A.AccidentGrade = 1011148009 THEN '□ 전도사고    □ 충돌사고    ■ 낙하·비래사고    □ 붕괴·도괴사고    □ 감전사고    □ 추락사고' 
                WHEN A.AccidentGrade = 1011148010 THEN '□ 전도사고    □ 충돌사고    □ 낙하·비래사고    ■ 붕괴·도괴사고    □ 감전사고    □ 추락사고' 
                WHEN A.AccidentGrade = 1011148011 THEN '□ 전도사고    □ 충돌사고    □ 낙하·비래사고    □ 붕괴·도괴사고    ■ 감전사고    □ 추락사고' 
                WHEN A.AccidentGrade = 1011148012 THEN '□ 전도사고    □ 충돌사고    □ 낙하·비래사고    □ 붕괴·도괴사고    □ 감전사고    ■ 추락사고' 
                ELSE '□ 전도사고    □ 충돌사고    □ 낙하·비래사고    □ 붕괴·도괴사고    □ 감전사고    □ 추락사고' 
                END AS AccidentGrade2, -- 세부분류2 

           CASE WHEN A.AreaClass = 20039001 THEN '■ 사내       □ 사외' 
                WHEN A.AreaClass = 20039001 THEN '□ 사내       ■ 사외' 
                ELSE '□ 사내       □ 사외'  
                END AS AreaClassName, -- 사고지 구분
            
           CASE WHEN A.DOW = 20040001 THEN '■ 북    □ 북동    □ 동    □ 남동    □ 남    □ 남서    □ 서    □ 북서'
                WHEN A.DOW = 20040002 THEN '□ 북    ■ 북동    □ 동    □ 남동    □ 남    □ 남서    □ 서    □ 북서'
                WHEN A.DOW = 20040003 THEN '□ 북    □ 북동    ■ 동    □ 남동    □ 남    □ 남서    □ 서    □ 북서'
                WHEN A.DOW = 20040004 THEN '□ 북    □ 북동    □ 동    ■ 남동    □ 남    □ 남서    □ 서    □ 북서'
                WHEN A.DOW = 20040005 THEN '□ 북    □ 북동    □ 동    □ 남동    ■ 남    □ 남서    □ 서    □ 북서'
                WHEN A.DOW = 20040006 THEN '□ 북    □ 북동    □ 동    □ 남동    □ 남    ■ 남서    □ 서    □ 북서'
                WHEN A.DOW = 20040007 THEN '□ 북    □ 북동    □ 동    □ 남동    □ 남    □ 남서    ■ 서    □ 북서'
                WHEN A.DOW = 20040008 THEN '□ 북    □ 북동    □ 동    □ 남동    □ 남    □ 남서    □ 서    ■ 북서'
                ELSE '□ 북    □ 북동    □ 동    □ 남동    □ 남    □ 남서    □ 서    □ 북서'
                END AS DOWName, -- 풍향 
                
           CASE WHEN A.Weather = 20041001 THEN '■ 맑음    □ 흐림    □ 비    □ 눈    □ 소나기    □ 천둥번개    □ 안개'
                WHEN A.Weather = 20041002 THEN '□ 맑음    ■ 흐림    □ 비    □ 눈    □ 소나기    □ 천둥번개    □ 안개'
                WHEN A.Weather = 20041003 THEN '□ 맑음    □ 흐림    ■ 비    □ 눈    □ 소나기    □ 천둥번개    □ 안개'
                WHEN A.Weather = 20041004 THEN '□ 맑음    □ 흐림    □ 비    ■ 눈    □ 소나기    □ 천둥번개    □ 안개'
                WHEN A.Weather = 20041005 THEN '□ 맑음    □ 흐림    □ 비    □ 눈    ■ 소나기    □ 천둥번개    □ 안개'
                WHEN A.Weather = 20041006 THEN '□ 맑음    □ 흐림    □ 비    □ 눈    □ 소나기    ■ 천둥번개    □ 안개'
                WHEN A.Weather = 20041007 THEN '□ 맑음    □ 흐림    □ 비    □ 눈    □ 소나기    □ 천둥번개    ■ 안개'
                ELSE '□ 맑음    □ 흐림    □ 비    □ 눈    □ 소나기    □ 천둥번개    □ 안개'
                END AS WeatherName, -- 날씨   
                
           A.WV, -- 풍속 
           A.LeakMatName, -- 누출물질명 
           A.LeakMatQty, -- 누출량 
           A.AccidentEqName, -- 사고설비명 
           A.AccidentOutline, -- 사고개요 
           A.AccidentCause, -- 사고원인  
           A.MngRemark, -- 조치사항 
           A.AccidentInjury, -- 사고피해 
           A.PreventMeasure, -- 예방대책 
           REPLACE ( REPLACE ( REPLACE ( (SELECT RealFileName 
                                            FROM KPXERPCommon.DBO._TCAAttachFileData 
                                           WHERE AttachFileSeq = A.FileSeq 
                                          FOR XML AUTO, ELEMENTS
                                         ),'</RealFileName></KPXDEVCommon.DBO._TCAAttachFileData><KPXERPCommon.DBO._TCAAttachFileData><RealFileName>',' , '
                                       ), '<KPXERPCommon.DBO._TCAAttachFileData><RealFileName>',''
                             ), '</RealFileName></KPXERPCommon.DBO._TCAAttachFileData>', ''
                   ) AS RealFileName -- 첨부자료 
      FROM KPXCM_TSEAccidentCHE     AS A 
      LEFT OUTER JOIN _TDADept      AS B ON A.CompanySeq = B.CompanySeq AND A.DeptSeq = B.DeptSeq
      LEFT OUTER JOIN _TDAEmp       AS C ON A.CompanySeq = C.CompanySeq AND A.EmpSeq = C.EmpSeq
      LEFT OUTER JOIN _TDAEmp       AS J ON A.CompanySeq = J.CompanySeq AND A.ReporterSeq = J.EmpSeq
     WHERE A.CompanySeq   = @CompanySeq
       AND (@AccidentSerl = '' or   A.AccidentSerl = @AccidentSerl )-- ('1' : 사고발생보고등록, '2' : 사고조사등록)
       AND (@AccidentSeq   = 0  OR A.AccidentSeq   = @AccidentSeq) 
    
    RETURN

 go

exec KPXCM_SSEAccidentGWQueryCHE @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>U</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>0</IsChangedMst>
    <AccidentSerl>2</AccidentSerl>
    <AccidentSeq>1</AccidentSeq>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030103,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1025154
