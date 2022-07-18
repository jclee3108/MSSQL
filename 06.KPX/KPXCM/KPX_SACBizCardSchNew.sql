IF OBJECT_ID('KPX_SACBizCardSchNew') IS NOT NULL 
    DROP PROC KPX_SACBizCardSchNew
GO 

-- v2015.08.10 
/************************************************************  
 설  명 - 법인카드내역가져오기  
 작성일 - 2015.02.03  
 작성자 - 전경만  
************************************************************/  
CREATE PROC dbo.KPX_SACBizCardSchNew 
  
AS   
    DECLARE @MaxSeq INT,  
            @MinSeq INT  
  
    SELECT @MinSeq = MaxSeq 
      FROM HIST_CORPCD_MAXSeq_New  
    
    SELECT @MaxSeq = MAX(Seq_No)  
      FROM HIST_CORPCD_BUY AS A  
     WHERE A.Seq_No > ISNULL(@MinSeq,0)    
    
    SELECT ISNULL(@MinSeq,0)  , @Maxseq  
    
    SELECT  A.SEQ_NO
           ,A.CARD_COM_CD
           ,A.CARD_NO
           ,A.AUTH_DD
           ,A.AUTH_NO
           ,A.BUY_STS
           ,A.BUY_CLT_NO
           ,A.JUMIN_BIZ_NO
           ,A.AUTH_HH
           ,A.CARD_PATTERN
           ,A.USER_MEMO
           ,A.AUTH_AMT
           ,A.AUTH_AMT_PRIN
           ,A.SUPP_PRICE
           ,A.SURTAX
           ,A.SURTAX_ORGAMT
           ,A.SVC_AMT
           ,A.SVC_ORI_AMT
           ,A.TRAN_CURCD
           ,A.MER_NM
           ,A.MER_BIZNO
           ,A.MER_NO
           ,A.MER_CEONM
           ,A.MER_TELNO
           ,A.MER_ZIPNO
           ,A.MER_ADR1
           ,A.MER_ADR2
           ,A.MER_CLOSE
           ,A.MER_CLOSEDTL
           ,A.BIZ_COND_CD
           ,A.BIZTYPE_CD
           ,A.BIZTYPE_NM
           ,A.BUY_DD
           ,A.BUY_HH
           ,A.BUY_CUR
           ,A.BUY_AMT
           ,A.BUY_PRINAMT
           ,A.BUY_TAX
           ,A.BUY_TAX_PRIN
           ,A.BUY_SVC_CHARGE
           ,A.BUY_AMTSUM
           ,A.BUY_APPLIED_EXCHRATE
           ,A.BUY_USD_CVTRATE
           ,A.BUY_WON_CVTRATE
           ,A.STM_DD
           ,A.FORE_USEGB
           ,A.FORE_USE_NAT
           ,A.BUY_CNC_DD
           ,A.FILE_NM
           ,A.FEB_MCCCD
           ,A.EBANK_TRANTYPEGB
           ,A.CREATE_SEQ
           ,A.CREATE_DD
           ,A.USE_BASE
           ,A.LST_USE_ID
           ,A.LST_USE_NM
           ,A.LST_USE_DDHH
           ,A.HEAD_CD
           ,A.STM_KEY
           ,A.CARD_KEY
           ,A.CARD_KIND
           ,A.KRW_CVT_AMT
           ,A.PRODUCT_NM
           ,A.INSTALL_MM
           ,A.AUTH_BUY_GB
           ,A.RECEIPT_NO
           ,A.TERMINAL_NO
           ,A.RECEIPT_BUY
           ,A.RECEIPT_PRESENT
           ,A.DISCOUNT_SVC_GB
           ,A.PART_AUTH_CNC
           ,A.MER_TAX_TYPE_INF
           ,A.MER_CLOSE_DATE
           ,A.ORG_TRAN_DATE
           ,A.ORG_AUTH_NO
           ,A.ORG_AUTH_TIME
           ,A.PG_CEOBR_NM
           ,A.PG_CEOBR_BIZNO
           ,A.AUTH_SUM_AMT
           ,A.SAVE_DATE
           ,A.SAVE_TIME
           ,A.BUY_AUTH_SUM
           ,A.BUY_AUTH_AMT
           ,A.DISCOUNT_AMT
           ,A.TRAN_FEE
           ,A.PARTBUY_YN
           ,A.EXCH_COMMION
           ,A.SUB_AUTH_SALE_YN
           ,A.STM_DD2
           ,A.SURTAX_CLASS
           ,A.DEDU_INF
           ,A.FILLER_1
           ,A.AUTH_RST_GB
           ,A.TAX_OBJ
           ,A.RELE_BODY
           ,A.COM_COST
           ,A.ERP_SENDYN
           ,A.APPR_YN
           ,A.ACCT_KEY
           ,A.REMAIN_INSTMENT_MM
           ,A.MEDIA_GB
           ,A.BUY_CARD_CO
           ,A.BUY_BR
           ,A.BUY_BR_NM
           ,A.BUY_STAFF_CD
           ,A.BUY_STAFF_NM
           ,A.REMARK
           ,A.INIT_INCOM_DD
           ,A.GRACE_FEEPAYER
           ,A.GRACE_FEE
           ,A.PART_FEE_PAYER
           ,A.PART_FEE
           ,A.RESEND_YN
           ,A.TAX_ITEM
           ,A.CORP_ID
           ,A.SVC_CD
           ,A.WORK_CD
           ,A.STATE_NO
           ,A.SEND_STS
           ,A.USE_FAO
           ,A.BUSINESS_NO
           ,A.ASSIGN_MBR_NO
           ,A.FORE_CVT_FEE
           ,A.MERC_TYPE
           ,A.CURR
           ,A.VAT_STAT
           ,A.GONGJE_NO_CHK
           ,A.COBIZNO_YN
           ,A.SUPPLY_SOCNO
           ,A.SUPPLY_NAME
           ,A.REBILL_NO
           ,A.CHARGE_BACK_NO
           ,A.TRCR_NO
           ,A.REVIS_NO
           ,A.RETRUN_NO
           ,A.INVOICE_NO
           ,A.TRAN_NO
           ,A.AGENCY_CD
           ,A.ALLOT_PERI
           ,A.CUR_CD
           ,A.TOT_AMT
           ,A.STM_AMT
           ,A.CARD_EXPIRE
           ,A.AIR_MERC_NO
           ,A.AIR_CORP_CD
           ,A.LOC_CITY
           ,A.ITINER
           ,A.TRAN_CD
           ,A.LST_DDHH
           ,A.LST_CHE_ID
           ,A.ISSUEDATE
           ,A.TOURROUTE
           ,A.AGENTNAME
           ,A.PASSENGERNAME
           ,A.TRAVELDATE
           ,A.TRCRNumber
           ,A.CLOSE_STS
           ,A.IS_ERP
           ,A.ERP_MGRNO
           ,A.ERP_MKNO
           ,A.ERP_TRANINF
           ,A.ERP_RCVDDHH
           ,A.ERP_SENDOBJ
           ,A.EGT_ID
           ,A.EGT_FLAG
           ,A.EGT_RELID
           ,A.REMARKS
           ,A.BUY_APPLIED_EXCHRATE2
           ,A.STRPROCUSESR
           ,A.STRAUDITFLAG
      INTO #Temp_Table 
      FROM HIST_CORPCD_BUY AS A  
     WHERE A.Seq_No > ISNULL(@MinSeq,0)  
       AND A.Seq_No <= @MaxSeq  
    
    ----------------------------------
    -- 매입추심번호 중복 
    ----------------------------------
    INSERT INTO HIST_CORPCD_ERR
    SELECT * , '매입추심번호 중복', '0'
      FROM #Temp_Table 
     WHERE BUY_CLT_NO IN ( 
                            SELECT BUY_CLT_NO
                              FROM HIST_CORPCD_BUY 
                             GROUP BY BUY_CLT_NO
                             HAVING COUNT(1) > 1 
                         )
    
    DELETE A 
      FROM #Temp_Table AS A 
     WHERE BUY_CLT_NO IN ( 
                            SELECT BUY_CLT_NO
                              FROM HIST_CORPCD_BUY 
                             GROUP BY BUY_CLT_NO
                             HAVING COUNT(1) > 1 
                         )
    ----------------------------------
    -- 매입추심번호 중복, END 
    ----------------------------------
    
    ------------------------------
    -- 승인번호 중복
    ------------------------------
 
    
    SELECT A.CARD_NO, A.AUTH_NO, A.AUTH_DD, A.AUTH_AMT, A.BUY_STS, LEN(BUY_CLT_NO) AS LEN_BUY_CLT_NO
      INTO #Temp_Table_Sub
      FROM #Temp_Table AS A 
     WHERE EXISTS ( SELECT 1 
                      FROM ( 
                            SELECT CARD_NO, AUTH_NO, AUTH_DD, AUTH_AMT, BUY_STS
                              FROM HIST_CORPCD_BUY 
                             WHERE BUY_CLT_NO NOT IN (SELECT BUY_CLT_NO 
                                                        FROM HIST_CORPCD_BUY 
                                                       GROUP BY BUY_CLT_NO
                                                       HAVING COUNT(1) > 1 
                                                     ) 
                             GROUP BY CARD_NO, AUTH_NO, AUTH_DD, AUTH_AMT, BUY_STS 
                             HAVING COUNT(1) > 1 
                           ) AS Z 
                     WHERE Z.CARD_NO = A.CARD_NO 
                       AND Z.AUTH_NO = A.AUTH_NO
                       AND Z.AUTH_DD = A.AUTH_DD
                       AND Z.AUTH_AMT = A.AUTH_AMT
                       AND Z.BUY_STS = A.BUY_STS
                  ) 
     GROUP BY A.CARD_NO, A.AUTH_NO, A.AUTH_DD, A.AUTH_AMT, A.BUY_STS, LEN(BUY_CLT_NO)
     ORDER BY A.CARD_NO, A.AUTH_NO, A.AUTH_DD, A.AUTH_AMT, A.BUY_STS, LEN(BUY_CLT_NO) 
    
    
    INSERT INTO HIST_CORPCD_ERR
    SELECT A.* , '승인번호 중복', '0' 
      FROM #Temp_Table AS A 
     WHERE EXISTS (SELECT 1 
                    FROM (
                             SELECT CARD_NO, AUTH_NO, AUTH_DD, AUTH_AMT, BUY_STS
                               FROM #Temp_Table_Sub 
                              GROUP BY CARD_NO, AUTH_NO, AUTH_DD, AUTH_AMT, BUY_STS 
                             HAVING COUNT(1) > 1 
                         ) AS Z 
                     WHERE Z.CARD_NO = A.CARD_NO 
                       AND Z.AUTH_NO = A.AUTH_NO
                       AND Z.AUTH_DD = A.AUTH_DD
                       AND Z.AUTH_AMT = A.AUTH_AMT
                       AND Z.BUY_STS = A.BUY_STS
                  )
    
    
    DELETE A
      FROM #Temp_Table AS A 
     WHERE EXISTS (SELECT 1 
                    FROM (
                             SELECT CARD_NO, AUTH_NO, AUTH_DD, AUTH_AMT, BUY_STS
                               FROM #Temp_Table_Sub 
                              GROUP BY CARD_NO, AUTH_NO, AUTH_DD, AUTH_AMT, BUY_STS 
                             HAVING COUNT(1) > 1 
                         ) AS Z 
                     WHERE Z.CARD_NO = A.CARD_NO 
                       AND Z.AUTH_NO = A.AUTH_NO
                       AND Z.AUTH_DD = A.AUTH_DD
                       AND Z.AUTH_AMT = A.AUTH_AMT
                       AND Z.BUY_STS = A.BUY_STS
                  )
    ------------------------------
    -- 승인번호 중복, END 
    ------------------------------
    
    
 
    ------------------------------
    -- 카드정보 확인 불가
    ------------------------------
    INSERT INTO HIST_CORPCD_ERR
    SELECT * , '카드정보 확인 불가', '0'
      FROM #Temp_Table AS A 
     WHERE A.SEQ_NO IN ( 
                         SELECT SEQ_NO
                           FROM HIST_CORPCD_BUY 
                          WHERE CARD_NO NOT IN (SELECT REPLACE(CardNo,'-','') FROM KPXERP.DBO._TDACard WHERE CompanySeq = 1 
                                                UNION 
                                                SELECT REPLACE(CardNo,'-','') FROM KPXCM.DBO._TDACard WHERE CompanySeq = 2 
                                               )   
                            AND CARD_NO NOT IN (SELECT CARD_NO 
                                                 FROM [KPXGW].SmartBillDB.dbo.[HIST_CORPCD_LIMT] 
                                                WHERE x_active = '1'
                                              ) 
                       )
                       
    DELETE A 
      FROM #Temp_Table AS A 
     WHERE A.SEQ_NO IN ( 
                         SELECT SEQ_NO
                           FROM HIST_CORPCD_BUY 
                          WHERE CARD_NO NOT IN (SELECT REPLACE(CardNo,'-','') FROM KPXERP.DBO._TDACard WHERE CompanySeq = 1 
                                                UNION 
                                                SELECT REPLACE(CardNo,'-','') FROM KPXCM.DBO._TDACard WHERE CompanySeq = 2 
                                               )   
                            AND CARD_NO NOT IN (SELECT CARD_NO 
                                                 FROM [KPXGW].SmartBillDB.dbo.[HIST_CORPCD_LIMT] 
                                                WHERE x_active = '1'
                                              ) 
                       )
                      
    ------------------------------
    -- 카드정보 확인 불가, END 
    ------------------------------
    
    -------------------------------
    -- 정상적인 데이터 
    -------------------------------
    INSERT INTO HIST_CORPCD_VERIFICATION 
    SELECT *, NULL
      FROM #Temp_Table 
    
    
    --select * From HIST_CORPCD_VERIFICATION 
    --select * from HIST_CORPCD_ERR 
    
    
    
    
    ----select * from #Temp_Table 
    --return 
    
    IF ISNULL(@MaxSeq,0) <> 0  
    BEGIN 
        UPDATE HIST_CORPCD_MAXSeq_New  
           SET MaxSeq = @MaxSeq 
    END 
  
  
  
RETURN  
  
        
  
GO  
  
  begin tran 
  
  EXEC KPX_SACBizCardSchNew
  --select * from HIST_CORPCD_MAXSeq_New 
  
  rollback 