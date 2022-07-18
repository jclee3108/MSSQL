begin tran

--작업요청내역등록(일반), 작업완료확인처리(일반)
DELETE FROM _TEQWorkOrderReqMasterCHE
DELETE FROM _TEQWorkOrderReqMasterCHELog
DELETE FROM _TEQWorkOrderReqItemCHE
DELETE FROM _TEQWorkOrderReqItemCHELog


--작업접수등록(일반)
DELETE FROM _TEQWorkOrderReceiptMasterCHE
DELETE FROM _TEQWorkOrderReceiptMasterCHELog
DELETE FROM _TEQWorkOrderReceiptItemCHE
DELETE FROM _TEQWorkOrderReceiptItemCHELog

--작업실적등록(일반)


DELETE FROM _TEQWorkOrderReceiptMasterCHE
DELETE FROM _TEQWorkOrderReceiptMasterCHELog
DELETE FROM _TEQWorkOrderReceiptItemCHE
DELETE FROM _TEQWorkOrderReceiptItemCHELog



--연차보수기간등록
DELETE FROM KPXCM_TEQYearRepairPeriodCHE
DELETE FROM KPXCM_TEQYearRepairPeriodCHELog



--연차보수요청등록
DELETE FROM KPXCM_TEQYearRepairReqRegCHE
DELETE FROM KPXCM_TEQYearRepairReqRegCHELog
DELETE FROM KPXCM_TEQYearRepairReqRegItemCHE
DELETE FROM KPXCM_TEQYearRepairReqRegItemCHELog


--연차보수접수등록
DELETE FROM KPXCM_TEQYearRepairReceiptRegCHE
DELETE FROM KPXCM_TEQYearRepairReceiptRegCHELog
DELETE FROM KPXCM_TEQYearRepairReceiptRegItemCHE
DELETE FROM KPXCM_TEQYearRepairReceiptRegItemCHELog


--연차보수실적등록
DELETE FROM KPXCM_TEQYearRepairResultRegCHE
DELETE FROM KPXCM_TEQYearRepairResultRegCHELog
DELETE FROM KPXCM_TEQYearRepairResultRegItemCHE
DELETE FROM KPXCM_TEQYearRepairResultRegItemCHELog


--점검내역등록
DELETE FROM KPX_TEQCheckReport
DELETE FROM KPX_TEQCheckReportLog

--설비검교정내역등록
DELETE FROM _TEQExamCorrectEditCHE
DELETE FROM _TEQExamCorrectEditCHELog

--정기검사계획조정등록
DELETE FROM KPXCM_TEQRegInspectChg
DELETE FROM KPXCM_TEQRegInspectChgLog

--정기검사내역등록
DELETE FROM KPXCM_TEQRegInspectRst
DELETE FROM KPXCM_TEQRegInspectRstLog


--설비자재출고요청등록 더 확인 필요
DELETE FROM KPX_TLGInOutReqAdd
DELETE FROM KPX_TLGInOutReqAddLog
--_TLGInOutReq
--_TLGInOutReqLog
--_TLGInOutReqItem
--_TLGInOutReqItemLog

--설비자재출고등록	더 확인 필요
DELETE FROM KPX_TLGInOutDailyAdd
DELETE FROM KPX_TLGInOutDailyAddLog
--_TLGInOutDaily
--_TLGInOutDailyLog


--변경등록
DELETE FROM KPXCM_TEQChangeRequestCHE
DELETE FROM KPXCM_TEQChangeRequestCHELog
DELETE FROM KPXCM_TEQChangeRequestCHE_Confirm
DELETE FROM KPXCM_TEQChangeRequestCHE_ConfirmLog

--변경접수등록
DELETE FROM KPXCM_TEQChangeRequestRecv
DELETE FROM KPXCM_TEQChangeRequestRecvLog
DELETE FROM KPXCM_TEQChangeRequestRecv_Confirm
DELETE FROM KPXCM_TEQChangeRequestRecv_ConfirmLog

--변경기술검토등록
DELETE FROM KPXCM_TEQTaskOrderCHE
DELETE FROM KPXCM_TEQTaskOrderCHELog
DELETE FROM KPXCM_TEQTaskOrderCHE_Confirm
DELETE FROM KPXCM_TEQTaskOrderCHE_ConfirmLog


--변경실행결과등록
DELETE FROM KPXCM_TEQChangeFinalReport
DELETE FROM KPXCM_TEQChangeFinalReportLog


--Utility일별사용량등록
DELETE FROM KPXCM_TPDProcBusiUtilityReg
DELETE FROM KPXCM_TPDProcBusiUtilityRegLog

--Utility월별정산등록
DELETE FROM KPXCM_TPDUtilityMonAcc
DELETE FROM KPXCM_TPDUtilityMonAccLog

rollback tran