IF OBJECT_ID('KPXCM_SPDWorkOrderCfmPilotCheck') IS NOT NULL 
    DROP PROC KPXCM_SPDWorkOrderCfmPilotCheck
GO 

-- v2016.03.02 

-- 작업지시서생성-체크 by 이재천  
-- 긴급작업지시때문에 별도 SP생성 
CREATE PROC KPXCM_SPDWorkOrderCfmPilotCheck
     @xmlDocument    NVARCHAR(MAX),  
     @xmlFlags       INT = 0,  
     @ServiceSeq     INT = 0,   
     @WorkingTag     NVARCHAR(10)= '',  
     @CompanySeq     INT = 1,  
     @LanguageSeq    INT = 1,  
     @UserSeq        INT = 0,  
     @PgmSeq         INT = 0  
 AS   
     DECLARE @MessageType    INT,  
             @Status         INT,  
             @Results        NVARCHAR(250),
             @SrtDT         DATETIME,
             @EndDT         DATETIME,
			 @UMProcType        INT,
			 @WorkCenterSeq  INT  ,
			 @DataCnt         int,
			 @ProdPlanSeq     INT,
			 @WorkCenterName    NVARCHAR(200),
			 @ItemName          NVARCHAR(200)
       
    --CREATE TABLE #TPDSFCWorkOrder( WorkingTag NCHAR(1) NULL )    
    --EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#TPDSFCWorkOrder'   
    --IF @@ERROR <> 0 RETURN     
    
    --SELECT @SrtDT = CONVERT(DATETIME, FrStdDate+SPACE(1)+LEFT(A.FrTime,2)+':'+RIGHT(A.FrTime,2)),
    --       @EndDT = CONVERT(DATETIME, ToStdDate+SPACE(1)+LEFT(A.ToTime,2)+':'+RIGHT(A.ToTime,2)),
    --       @UMProcType = UMProcType,
    --       @WorkCenterSeq = WorkCenterSeq
    --  FROM #TPDSFCWorkOrder AS A

    

    
    SELECT @DataCnt = Count(1) ,@ProdPlanSeq = min (A.ProdPlanSeq)
      FROM #TPDSFCWorkOrder                               AS B   
                 JOIN _TPDMPSDailyProdPlan      AS A ON ( A.ProdPlanSeq = B.ProdPlanSeq AND A.WorkCond1 <> '' )  
      Left Outer Join _TDAItemStock             AS B1 with(nolock) ON A.CompanySeq = B1.CompanySeq and A.ItemSeq = B1.ItemSeq
      Left Outer Join _TDAUMinorValue           AS C ON C.CompanySeq = @CompanySeq And C.MajorSeq = 1011346 And C.Serl = 1000001 And C.ValueSeq = A.WorkCenterSeq
      Left Outer Join _TDAUMinorValue           AS D ON D.CompanySeq = @CompanySeq And D.MajorSeq = 1011346 and D.Serl = 1000002 and C.MinorSeq = D.MinorSeq
      Left Outer Join _TDAUMinorValue           AS E ON E.CompanySeq = @CompanySeq And E.MajorSeq = 1011265 and E.Serl = 1000001 and E.MinorSeq = D.ValueSeq 
      Left Outer Join _TDAUMinorValue           AS F ON F.CompanySeq = @CompanySeq And F.MajorSeq = 1011266 and F.Serl = 1000001 and F.MinorSeq = E.ValueSeq 
      Left Outer Join (
                        SELECT CompanySeq,ValueSeq AS ItemSeq
                          FROM _TDAUMinorValue
                         WHERE CompanySeq = @CompanySeq
                           AND MajorSeq = 1011291
                           AND Serl = 1000001
                      ) AS G ON A.CompanySeq = G.CompanySeq AND A.ItemSeq = G.ItemSeq
     WHERE A.CompanySeq = @CompanySeq   
       AND (@UMProcType = 0 OR D.ValueSeq = @UMProcType or E.ValueSeq = @UMProcType or F.ValueSeq = @UMProcType)
       AND A.ProdPlanSeq NOT IN (
                                  SELECT ProdPlanSeq   
                                    FROM _TPDSFCWorkOrder 
                                   WHERE CompanySeq = @CompanySeq   
                                )  
       --and ( Isnull(B1.IsLOtMng,'0') = '0' or (B1.IsLotMng = '1' and Isnull(rtrim(A.WorkCond3),'') = '') )
	   --AND A.ProdQty > 0
       and (CASE WHEN G.CompanySeq IS NOT NULL THEN 0 ELSE A.ProdQty END) >0
       and ( Isnull(B1.IsLOtMng,'0') = '0' or (B1.IsLotMng = '1' and Isnull(rtrim(A.WorkCond3),'') = '') )
     
--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------
    
    EXEC dbo._SCOMMessage @MessageType OUTPUT,  
                          @Status      OUTPUT,  
                          @Results     OUTPUT,  
                          1                  , -- @1을(를) 입력하세요.(SELECT * FROM _TCAMessageLanguage WHERE Message like '%오류%')  
                          @LanguageSeq       ,  
                          0, '품목 검사규격'

   --select * from _TPDMPSDailyProdPlan
   --where SrtDate >= '20151201'

    select @WorkCenterName = C.WorkCenterName
          ,@ItemName       = B.ItemEngSName
      from _TPDMPSDailyProdPlan     AS A With(Nolock) 
	      Join _TDAItem             AS B With(Nolock) ON A.CompanySeq = B.CompanySeq And A.ItemSeq = B.ItemSeq
		  Join _TPDBaseWorkCenter   AS C With(Nolock) ON A.CompanySeq = C.CompanySeq And A.WorkCenterSeq = C.WorkCenterSeq
     where A.CompanySeq = @CompanySeq
       and A.ProdPlanSeq = @ProdPlanSeq
    
    if @DataCnt > 0 
    Begin
       UPDATE #TPDSFCWorkOrder
          SET Result       = '['+ @WorkCenterName +'/'+@ItemName +']'+'LOTNO 등록하세요',--@Results, 
              MessageType  = @MessageType,  
              Status       = @Status  
       
    end


  
/*
--print 41
    UPDATE B
       SET Result       = '품목 검사규격이 누락된 계획이 있습니다.',--@Results, 
           MessageType  = @MessageType,  
           Status       = @Status  
    --select *
--           A.ProdPlanSeq,
--           CONVERT(DATETIME, A.SrtDate+SPACE(1)+LEFT(A.WorkCond1,2)+':'+RIGHT(A.WorkCond1,2)), @SrtDT, @EndDt,
--A.SrtDate+A.WorkCond1 , B.FrStdDate+B.FrTime,
--A.SrtDate+A.WorkCond1 , B.ToStdDate+B.ToTime
      FROM #TPDSFCWorkOrder AS B  
       JOIN _TPDMPSDailyProdPlan     AS A ON ( 
                                            --    CONVERT(DATETIME, A.SrtDate+SPACE(1)+LEFT(A.WorkCond1,2)+':'+RIGHT(A.WorkCond1,2))
                                            --    BETWEEN @SrtDT AND @EndDT
                                            --AND 
                                            --CONVERT(DATETIME, A.SrtDate+SPACE(1)+LEFT(A.WorkCond1,2)+':'+RIGHT(A.WorkCond1,2)) >= @SrtDT
                                            --AND CONVERT(DATETIME, A.SrtDate+SPACE(1)+LEFT(A.WorkCond1,2)+':'+RIGHT(A.WorkCond1,2)) <= @EndDT
                                            --AND
                                            B.WorkCenterSeq = A.WorkCenterSeq
                                            AND A.SrtDate+A.WorkCond1 >= B.FrStdDate+B.FrTime
                                            AND A.SrtDate+A.WorkCond1 <= B.ToStdDate+B.ToTime
                                            AND A.SrtDate >= B.FrStdDate
                                            AND A.SrtDate <= B.ToStdDate
                                            AND A.WorkCond1 <> ''
                                            )   
         LEFT OUTER JOIN KPX_TQCQAProcessQCType AS Q WITH(NOLOCK) ON Q.CompanySeq = @CompanySeq  
                                                            AND Q.ProcQC = 1000498001
                                                            AND Q.QCType IN (SELECT DISTINCT QCType FROM KPX_TQCQASpec WHERE CompanySeq = @CompanySeq
                                                                                                                         AND ItemSeq = A.ItemSeq)
      WHERE A.CompanySeq = @CompanySeq
        AND ISNULL(Q.CompanySeq, 0) = 0
        AND A.ItemSeq NOT IN (SELECT ItemSeq FROM _TDAItem WHERE CompanySeq = @CompanySeq AND SMStatus = 2001002)
        AND A.WorkCenterSeq IN (SELECT WorkCenterSeq FROM _TPDBaseWorkCenter WHERE CompanySeq = @CompanySeq AND CapaRate > 0 AND OutMatLeadTime <> '1' )
        AND A.ProdPlanSeq NOT IN (SELECT ProdPlanSeq   
                                  FROM _TPDSFCWorkOrder 
                              WHERE CompanySeq = @CompanySeq   
                               )    */
--order by A.ProdplanSeq
--print 66
--select 1
     --SELECT * FROM #TPDSFCWorkOrder   

RETURN  

--GO
BEGIN TRAN
exec KPXCM_SPDWorkOrderCfmCheck @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag>A</WorkingTag>
    <IDX_NO>1</IDX_NO>
    <Status>0</Status>
    <DataSeq>1</DataSeq>
    <Selected>1</Selected>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
    <IsChangedMst>1</IsChangedMst>
    <WorkCenterSeq />
    <WorkCenterName />
    <FrStdDate>20161201</FrStdDate>
    <FrTime>0800</FrTime>
    <ToStdDate>20161204</ToStdDate>
    <ToTime>1200</ToTime>
    <UMProcType>1011267001</UMProcType>
    <UMProcTypeName>PPG PART</UMProcTypeName>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030923,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=1,@PgmSeq=1025550
rollback tran
GO


