IF OBJECT_ID('KPXCM_SEQGWorkOrderReqCheckCHEIsCfmAlram') IS NOT NULL 
    DROP PROC KPXCM_SEQGWorkOrderReqCheckCHEIsCfmAlram
GO 

-- v2015.10.13

-- 작업요청조회 확정 알림 by이재천 
CREATE PROC KPXCM_SEQGWorkOrderReqCheckCHEIsCfmAlram
    @xmlDocument    NVARCHAR(MAX),
    @xmlFlags       INT             = 0,
    @ServiceSeq     INT             = 0,
    @WorkingTag     NVARCHAR(10)    = '',
    @CompanySeq     INT             = 1,
    @LanguageSeq    INT             = 1,
    @UserSeq        INT             = 0,
    @PgmSeq         INT             = 0
AS
    
    CREATE TABLE #_TEQWorkOrderReqMasterCHE (WorkingTag NCHAR(1) NULL)
    EXEC dbo._SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#_TEQWorkOrderReqMasterCHE'
    IF @@ERROR <> 0 RETURN
    
    -- 알림 2015.10.13 by이재천 
    DECLARE @BizUnit        INT, 
            @Msg1           NVARCHAR(200), 
            @JumpData       NVARCHAR(MAX), 
            @WOReqSeq       INT, 
            @ReqDate        NCHAR(8)
        
    SELECT TOP 1 @BizUnit   = C.BizUnit,  
                 @Msg1      = B.WONo, 
                 @WOReqSeq  = A.WOReqSeq, 
                 @ReqDate   = B.ReqDate
      FROM #_TEQWorkOrderReqMasterCHE AS A   
      JOIN _TEQWorkOrderReqMasterCHE  AS B ON ( B.CompanySeq = @CompanySeq AND B.WOReqSeq = A.WOReqSeq ) 
      JOIN _TDAFactUnit               AS C ON ( C.CompanySeq = @CompanySeq AND C.FactUnit = A.AccUnitSeq ) 
     WHERE A.IsCfm = '1' 
    
    
    SELECT @JumpData =  '<ROOT><DataBlock1><WOReqSeq>' + CONVERT(NVARCHAR(50), @WOReqSeq) + '</WOReqSeq>'  
    SELECT @JumpData = @JumpData + '<WONo>' + CONVERT(NVARCHAR(50), @Msg1) + '</WONo>'   
    SELECT @JumpData = @JumpData + '<ReqDateFr>' + CONVERT(NVARCHAR(50), @ReqDate) + '</ReqDateFr>'  
    SELECT @JumpData = @JumpData + '<ReqDateTo>' + CONVERT(NVARCHAR(50),@ReqDate) + '</ReqDateTo>'   
    SELECT @JumpData = @JumpData + '<ProgType>0</ProgType>'   

    SELECT @JumpData = @JumpData + '</DataBlock1></ROOT>'  
    
    EXEC KPXCM_SCASendMessageProgram      
         @WorkingTag      = ''    
        ,@CompanySeq      = @CompanySeq  
        ,@LanguageSeq     = @LanguageSeq  
        ,@UserSeq         = @UserSeq  
        ,@DeptSeq         = ''  
        ,@IsFast          = 0 -- 1 이면긴급   
        ,@TblKey          = @WOReqSeq    
        ,@PgmSeq          = @PgmSeq  
        ,@ToPgmSeq        = @PgmSeq  
        ,@JumpMode        = 150002 -- 150001 신구, 150002 조회, 150003 저장, 150006 추가   
        ,@JumpData        = @JumpData  
        ,@Msg1            = @Msg1  
        ,@Msg2            = ''  
        ,@Msg3            = ''  
        ,@Msg4            = ''  
        ,@Msg5            = ''    
        ,@SendEmail       = '' 
        ,@BizUnit         = @BizUnit  

    SELECT * FROM #_TEQWorkOrderReqMasterCHE
    
    RETURN
GO
begin tran 
exec KPXCM_SEQGWorkOrderReqCheckCHEIsCfmAlram @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>6</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <WONo>GEP-151013-006</WONo>
    <WOReqSeq>70</WOReqSeq>
    <AccUnitSeq>3</AccUnitSeq>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1030987,@WorkingTag=N'',@CompanySeq=2,@LanguageSeq=1,@UserSeq=2466,@PgmSeq=1025841
rollback 