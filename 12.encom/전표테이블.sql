
declare @TransSeq int 
select @TransSeq = 3128


select * from _TESMCProdSlipM where Transseq = @TransSeq
select * from _TESMCProdSlipD where Transseq = @TransSeq 
select * From _TACSlip where SlipMstSeq = (select SlipMstSeq From _TACSlipRow where SlipSeq = (select SlipSeq from _TESMCProdSlipM where Transseq = @TransSeq))
select * from _TACSlip_Confirm where CfmSeq = (select SlipMstSeq From _TACSlipRow where SlipSeq = (select SlipSeq from _TESMCProdSlipM where Transseq = @TransSeq))
select * From _TACSlipSetData where SlipMstSeq = (select SlipMstSeq From _TACSlipRow where SlipSeq = (select SlipSeq from _TESMCProdSlipM where Transseq = @TransSeq))
select * From _TACSlipRow where SlipMstSeq = (select SlipMstSeq From _TACSlipRow where SlipSeq = (select SlipSeq from _TESMCProdSlipM where Transseq = @TransSeq))
select * From _TACSlipRem where SlipSeq in ( select SlipSeq From _TACSlipRow where SlipMstSeq = (select SlipMstSeq From _TACSlipRow where SlipSeq = (select SlipSeq from _TESMCProdSlipM where Transseq = @TransSeq)) ) 
select * From _TACSlipCost where SlipSeq in ( select SlipSeq From _TACSlipRow where SlipMstSeq = (select SlipMstSeq From _TACSlipRow where SlipSeq = (select SlipSeq from _TESMCProdSlipM where Transseq = @TransSeq)) ) 
select * from _TACSLipAutoTempEnvKey where SlipKindNo = 'FrmESMCMatCostSlip' and KeyColumn1 = @TransSeq and slipseq <> 0 
