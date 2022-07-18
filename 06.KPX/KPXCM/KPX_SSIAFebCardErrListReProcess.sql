  
IF OBJECT_ID('KPX_SSIAFebCardErrListReProcess') IS NOT NULL   
    DROP PROC KPX_SSIAFebCardErrListReProcess  
GO  
  
-- v2015.08.12 
  
-- 법인카드에러내역확인 및 재처리-재처리 by 이재천   
CREATE PROC KPX_SSIAFebCardErrListReProcess  
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
            @Results        NVARCHAR(250)   
    
    CREATE TABLE #Temp( WorkingTag NCHAR(1) NULL )    
    EXEC _SCAOpenXmlToTemp @xmlDocument, @xmlFlags, @CompanySeq, @ServiceSeq, 'DataBlock1', '#Temp'   
    IF @@ERROR <> 0 RETURN     
    
    INSERT INTO HIST_CORPCD_VERIFICATION 
    SELECT  B.SEQ_NO
           ,B.CARD_COM_CD
           ,B.CARD_NO
           ,B.AUTH_DD
           ,B.AUTH_NO
           ,B.BUY_STS
           ,B.BUY_CLT_NO
           ,B.JUMIN_BIZ_NO
           ,B.AUTH_HH
           ,B.CARD_PATTERN
           ,B.USER_MEMO
           ,B.AUTH_AMT
           ,B.AUTH_AMT_PRIN
           ,B.SUPP_PRICE
           ,B.SURTAX
           ,B.SURTAX_ORGAMT
           ,B.SVC_AMT
           ,B.SVC_ORI_AMT
           ,B.TRAN_CURCD
           ,B.MER_NM
           ,B.MER_BIZNO
           ,B.MER_NO
           ,B.MER_CEONM
           ,B.MER_TELNO
           ,B.MER_ZIPNO
           ,B.MER_ADR1
           ,B.MER_ADR2
           ,B.MER_CLOSE
           ,B.MER_CLOSEDTL
           ,B.BIZ_COND_CD
           ,B.BIZTYPE_CD
           ,B.BIZTYPE_NM
           ,B.BUY_DD
           ,B.BUY_HH
           ,B.BUY_CUR
           ,B.BUY_AMT
           ,B.BUY_PRINAMT
           ,B.BUY_TAX
           ,B.BUY_TAX_PRIN
           ,B.BUY_SVC_CHARGE
           ,B.BUY_AMTSUM
           ,B.BUY_APPLIED_EXCHRATE
           ,B.BUY_USD_CVTRATE
           ,B.BUY_WON_CVTRATE
           ,B.STM_DD
           ,B.FORE_USEGB
           ,B.FORE_USE_NAT
           ,B.BUY_CNC_DD
           ,B.FILE_NM
           ,B.FEB_MCCCD
           ,B.EBANK_TRANTYPEGB
           ,B.CREATE_SEQ
           ,B.CREATE_DD
           ,B.USE_BASE
           ,B.LST_USE_ID
           ,B.LST_USE_NM
           ,B.LST_USE_DDHH
           ,B.HEAD_CD
           ,B.STM_KEY
           ,B.CARD_KEY
           ,B.CARD_KIND
           ,B.KRW_CVT_AMT
           ,B.PRODUCT_NM
           ,B.INSTALL_MM
           ,B.AUTH_BUY_GB
           ,B.RECEIPT_NO
           ,B.TERMINAL_NO
           ,B.RECEIPT_BUY
           ,B.RECEIPT_PRESENT
           ,B.DISCOUNT_SVC_GB
           ,B.PART_AUTH_CNC
           ,B.MER_TAX_TYPE_INF
           ,B.MER_CLOSE_DATE
           ,B.ORG_TRAN_DATE
           ,B.ORG_AUTH_NO
           ,B.ORG_AUTH_TIME
           ,B.PG_CEOBR_NM
           ,B.PG_CEOBR_BIZNO
           ,B.AUTH_SUM_AMT
           ,B.SAVE_DATE
           ,B.SAVE_TIME
           ,B.BUY_AUTH_SUM
           ,B.BUY_AUTH_AMT
           ,B.DISCOUNT_AMT
           ,B.TRAN_FEE
           ,B.PARTBUY_YN
           ,B.EXCH_COMMION
           ,B.SUB_AUTH_SALE_YN
           ,B.STM_DD2
           ,B.SURTAX_CLASS
           ,B.DEDU_INF
           ,B.FILLER_1
           ,B.AUTH_RST_GB
           ,B.TAX_OBJ
           ,B.RELE_BODY
           ,B.COM_COST
           ,B.ERP_SENDYN
           ,B.APPR_YN
           ,B.ACCT_KEY
           ,B.REMAIN_INSTMENT_MM
           ,B.MEDIA_GB
           ,B.BUY_CARD_CO
           ,B.BUY_BR
           ,B.BUY_BR_NM
           ,B.BUY_STAFF_CD
           ,B.BUY_STAFF_NM
           ,B.REMARK
           ,B.INIT_INCOM_DD
           ,B.GRACE_FEEPAYER
           ,B.GRACE_FEE
           ,B.PART_FEE_PAYER
           ,B.PART_FEE
           ,B.RESEND_YN
           ,B.TAX_ITEM
           ,B.CORP_ID
           ,B.SVC_CD
           ,B.WORK_CD
           ,B.STATE_NO
           ,B.SEND_STS
           ,B.USE_FAO
           ,B.BUSINESS_NO
           ,B.ASSIGN_MBR_NO
           ,B.FORE_CVT_FEE
           ,B.MERC_TYPE
           ,B.CURR
           ,B.VAT_STAT
           ,B.GONGJE_NO_CHK
           ,B.COBIZNO_YN
           ,B.SUPPLY_SOCNO
           ,B.SUPPLY_NAME
           ,B.REBILL_NO
           ,B.CHARGE_BACK_NO
           ,B.TRCR_NO
           ,B.REVIS_NO
           ,B.RETRUN_NO
           ,B.INVOICE_NO
           ,B.TRAN_NO
           ,B.AGENCY_CD
           ,B.ALLOT_PERI
           ,B.CUR_CD
           ,B.TOT_AMT
           ,B.STM_AMT
           ,B.CARD_EXPIRE
           ,B.AIR_MERC_NO
           ,B.AIR_CORP_CD
           ,B.LOC_CITY
           ,B.ITINER
           ,B.TRAN_CD
           ,B.LST_DDHH
           ,B.LST_CHE_ID
           ,B.ISSUEDATE
           ,B.TOURROUTE
           ,B.AGENTNAME
           ,B.PASSENGERNAME
           ,B.TRAVELDATE
           ,B.TRCRNumber
           ,B.CLOSE_STS
           ,B.IS_ERP
           ,B.ERP_MGRNO
           ,B.ERP_MKNO
           ,B.ERP_TRANINF
           ,B.ERP_RCVDDHH
           ,B.ERP_SENDOBJ
           ,B.EGT_ID
           ,B.EGT_FLAG
           ,B.EGT_RELID
           ,B.REMARKS
           ,B.BUY_APPLIED_EXCHRATE2
           ,B.STRPROCUSESR
           ,B.STRAUDITFLAG, 
           null 
      FROM #Temp AS A 
      JOIN HIST_CORPCD_ERR AS B ON ( B.SEQ_NO = A.SEQ_NO ) 
    
    -- 테이블 업데이트 
    UPDATE B 
       SET IsReProcess = '1' 
      FROM #Temp AS A 
      JOIN HIST_CORPCD_ERR AS B ON ( B.SEQ_NO = A.SEQ_NO ) 
    
    -- 처리결과 반영 
    UPDATE A 
       SET IsReProcess = '1' 
      FROM #Temp AS A 
    
    
    SELECT * FROM #Temp 
    
    RETURN  
GO 
begin tran 
exec KPX_SSIAFebCardErrListReProcess @xmlDocument=N'<ROOT>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>1</IDX_NO>
    <DataSeq>1</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SEQ_NO>36728</SEQ_NO>
    <TABLE_NAME>DataBlock1</TABLE_NAME>
  </DataBlock1>
  <DataBlock1>
    <WorkingTag />
    <IDX_NO>2</IDX_NO>
    <DataSeq>2</DataSeq>
    <Status>0</Status>
    <Selected>0</Selected>
    <SEQ_NO>36729</SEQ_NO>
  </DataBlock1>
</ROOT>',@xmlFlags=2,@ServiceSeq=1031355,@WorkingTag=N'',@CompanySeq=1,@LanguageSeq=1,@UserSeq=50322,@PgmSeq=1026098
rollback 


--select * from HIST_CORPCD_ERR where IsReProcess = '1'

--select * from HIST_CORPCD_VERIFICATION where BUY_CLT_NO = '20150804X107F311490114'