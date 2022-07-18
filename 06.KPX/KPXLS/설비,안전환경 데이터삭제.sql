
drop proc tooldata_jclee1
go 
create proc tooldata_jclee1
as 


-- 작업요청내역등록(일반) 
delete from _TEQWorkOrderReqMasterCHE 
delete from _TEQWorkOrderReqItemCHE
delete from KPXCM_TEQWorkOrderReqMasterCHEIsStop 

delete from _TCOMCreateSeqMax where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxESM where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxHR where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxLG where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxPD where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxPE where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxPU where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxSI where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = '_TEQWorkOrderReqMasterCHE' 
delete from _TCOMCreateNoMaxSL where TableName = '_TEQWorkOrderReqMasterCHE' 

-- 작업접수등록(일반), 작업실적등록(일반), 작업완료확인처리(일반)
delete from _TEQWorkOrderReceiptMasterCHE
delete from KPXCM_TEQWorkOrderReceiptMasterCHEAdd
delete from _TEQWorkOrderReceiptItemCHE

delete from _TCOMCreateSeqMax where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxESM where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxHR where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxLG where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxPD where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxPE where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxPU where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxSI where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = '_TEQWorkOrderReceiptMasterCHE' 
delete from _TCOMCreateNoMaxSL where TableName = '_TEQWorkOrderReceiptMasterCHE' 

-- 연차기간등록
delete from KPXCM_TEQYearRepairPeriodCHE 

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TEQYearRepairPeriodCHE' 


-- 연차보수요청등록 

delete from KPXCM_TEQYearRepairReqRegCHE
delete from KPXCM_TEQYearRepairReqRegItemCHE

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TEQYearRepairReqRegCHE' 

-- 연차보수접수등록
              
delete from KPXCM_TEQYearRepairReceiptRegCHE
delete from KPXCM_TEQYearRepairReceiptRegItemCHE

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TEQYearRepairReceiptRegCHE' 

-- 연차보수실적등록 

delete from KPXCM_TEQYearRepairResultRegCHE
delete from KPXCM_TEQYearRepairResultRegItemCHE

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TEQYearRepairResultRegCHE' 

-- 점검설비등록 

delete from KPX_TEQCheckItem 

delete from _TCOMCreateSeqMax where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPX_TEQCheckItem' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPX_TEQCheckItem' 

-- 점검내역등록

delete from KPX_TEQCheckReport

delete from _TCOMCreateSeqMax where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPX_TEQCheckReport' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPX_TEQCheckReport' 

-- 설비검교정내역등록및조회LS 

delete from _TEQExamCorrectEditCHE 

delete from _TCOMCreateSeqMax where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxESM where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxHR where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxLG where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxPD where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxPE where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxPU where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxSI where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = '_TEQExamCorrectEditCHE' 
delete from _TCOMCreateNoMaxSL where TableName = '_TEQExamCorrectEditCHE' 

-- 정기검사설비등록 

delete from KPXCM_TEQRegInspect 

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TEQRegInspect' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TEQRegInspect' 

-- 정기검사내역등록및조회 

delete from KPXCM_TEQRegInspectRst 

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TEQRegInspectRst' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TEQRegInspectRst' 


-- 설비자재출고요청등록

delete from KPX_TLGInOutReqAdd 

delete from _TCOMCreateSeqMax where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPX_TLGInOutReqAdd' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPX_TLGInOutReqAdd' 


-- 사고발생보고등록, 사고조사등록

delete from KPXCM_TSEAccidentCHE 
delete from KPXCM_TSEAccidentCHE_Confirm 

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TSEAccidentCHE' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TSEAccidentCHE' 

-- 상해조사등록 
delete from KPXCM_TSEDesasterCHE

delete from _TCOMCreateSeqMax where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxESM where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxHR where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxLG where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxPD where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxPE where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxPU where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxSI where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = 'KPXCM_TSEDesasterCHE' 
delete from _TCOMCreateNoMaxSL where TableName = 'KPXCM_TSEDesasterCHE' 

-- 보호구일괄지급, 보호구개인지급  

delete from _TSEBracerCHE 

delete from _TCOMCreateSeqMax where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxBPM where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxESM where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxHR where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxLG where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxPD where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxPE where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxPMS where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxPU where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxSI where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxSITE where TableName = '_TSEBracerCHE' 
delete from _TCOMCreateNoMaxSL where TableName = '_TSEBracerCHE' 



return 
go 
begin tran 
exec tooldata_jclee1
rollback 