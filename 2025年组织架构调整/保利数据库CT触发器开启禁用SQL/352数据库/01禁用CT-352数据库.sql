--352数据库
----------------------禁用CT--------------------------------------
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_HTFKApplyWFNodeEntity')) ,0))>0 BEGIN ALTER TABLE cb_HTFKApplyWFNodeEntity disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_TargetStage2Project')) ,0))>0 BEGIN ALTER TABLE cb_TargetStage2Project disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('wy_Room')) ,0))>0 BEGIN ALTER TABLE wy_Room disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_Contract')) ,0))>0 BEGIN ALTER TABLE cb_Contract disable CHANGE_TRACKING END ; 
--IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('myTaskWake_bakYB')) ,0))>0 BEGIN ALTER TABLE myTaskWake_bakYB disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_ContractWFNodeEntity')) ,0))>0 BEGIN ALTER TABLE cb_ContractWFNodeEntity disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('jd_TaskReport')) ,0))>0 BEGIN ALTER TABLE jd_TaskReport disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_ExecYgAlterAmount')) ,0))>0 BEGIN ALTER TABLE cb_ExecYgAlterAmount disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_SKBankRequestLog')) ,0))>0 BEGIN ALTER TABLE cb_SKBankRequestLog disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_NodeFinishCanSealApply')) ,0))>0 BEGIN ALTER TABLE cb_NodeFinishCanSealApply disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('myWorkflowProcessEntity')) ,0))>0 BEGIN ALTER TABLE myWorkflowProcessEntity disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_ContractCommissionBillingAttach')) ,0))>0 BEGIN ALTER TABLE cb_ContractCommissionBillingAttach disable CHANGE_TRACKING END ; 
--IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('myTaskWake_bakWB')) ,0))>0 BEGIN ALTER TABLE myTaskWake_bakWB disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('fy_ProviderYhjCt')) ,0))>0 BEGIN ALTER TABLE fy_ProviderYhjCt disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_DTCostRecollect')) ,0))>0 BEGIN ALTER TABLE cb_DTCostRecollect disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_MipPayFeeBillStatusData')) ,0))>0 BEGIN ALTER TABLE cb_MipPayFeeBillStatusData disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_ProviderChgNotice')) ,0))>0 BEGIN ALTER TABLE p_ProviderChgNotice disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('idm_CompanyOrganization')) ,0))>0 BEGIN ALTER TABLE idm_CompanyOrganization disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_ProviderBusinessContactApplyArea')) ,0))>0 BEGIN ALTER TABLE p_ProviderBusinessContactApplyArea disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_Provider2Service')) ,0))>0 BEGIN ALTER TABLE p_Provider2Service disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_ProjHyb')) ,0))>0 BEGIN ALTER TABLE cb_ProjHyb disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_ProviderEmployee')) ,0))>0 BEGIN ALTER TABLE p_ProviderEmployee disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_Provider2ServiceFreeze')) ,0))>0 BEGIN ALTER TABLE p_Provider2ServiceFreeze disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_BiddingBuilding')) ,0))>0 BEGIN ALTER TABLE p_BiddingBuilding disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_ProductType')) ,0))>0 BEGIN ALTER TABLE p_ProductType disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_HtType')) ,0))>0 BEGIN ALTER TABLE cb_HtType disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('CompanyJoin')) ,0))>0 BEGIN ALTER TABLE CompanyJoin disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_Provider2ServiceCompany')) ,0))>0 BEGIN ALTER TABLE p_Provider2ServiceCompany disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_ProjHyb2Cost2Yt')) ,0))>0 BEGIN ALTER TABLE cb_ProjHyb2Cost2Yt disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('jd_KeyNode')) ,0))>0 BEGIN ALTER TABLE jd_KeyNode disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cg_ProviderRelationship')) ,0))>0 BEGIN ALTER TABLE cg_ProviderRelationship disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_ProviderBusinessContact')) ,0))>0 BEGIN ALTER TABLE p_ProviderBusinessContact disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('jd_ProjectPlanExecute')) ,0))>0 BEGIN ALTER TABLE jd_ProjectPlanExecute disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('jd_ProjectPlanTaskExecute')) ,0))>0 BEGIN ALTER TABLE jd_ProjectPlanTaskExecute disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_Provider2Unit')) ,0))>0 BEGIN ALTER TABLE p_Provider2Unit disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_Provider')) ,0))>0 BEGIN ALTER TABLE p_Provider disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('jd_StopOrReturnWork')) ,0))>0 BEGIN ALTER TABLE jd_StopOrReturnWork disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cg_ProductServiceProperty')) ,0))>0 BEGIN ALTER TABLE cg_ProductServiceProperty disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_Provider2ServiceQualification')) ,0))>0 BEGIN ALTER TABLE p_Provider2ServiceQualification disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_Budget_Executing')) ,0))>0 BEGIN ALTER TABLE cb_Budget_Executing disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_ProviderGrade')) ,0))>0 BEGIN ALTER TABLE p_ProviderGrade disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_Provider2Bank')) ,0))>0 BEGIN ALTER TABLE p_Provider2Bank disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_Provider2Type')) ,0))>0 BEGIN ALTER TABLE p_Provider2Type disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_ProviderSource')) ,0))>0 BEGIN ALTER TABLE p_ProviderSource disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_ProviderType')) ,0))>0 BEGIN ALTER TABLE p_ProviderType disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_ContractCommissionBillingRulePdf')) ,0))>0 BEGIN ALTER TABLE cb_ContractCommissionBillingRulePdf disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_DesignAlterToTZXT')) ,0))>0 BEGIN ALTER TABLE cb_DesignAlterToTZXT disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_DealPayData')) ,0))>0 BEGIN ALTER TABLE cb_DealPayData disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('myWorkflowNodeEntity')) ,0))>0 BEGIN ALTER TABLE myWorkflowNodeEntity disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cg_ZLBidInfo_dl')) ,0))>0 BEGIN ALTER TABLE cg_ZLBidInfo_dl disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cg_TacticCgAgreementProduct_AttachmentOrders')) ,0))>0 BEGIN ALTER TABLE cg_TacticCgAgreementProduct_AttachmentOrders disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('p_HkbBiddingBuilding2BuildingWork')) ,0))>0 BEGIN ALTER TABLE p_HkbBiddingBuilding2BuildingWork disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('XdjxAnsy')) ,0))>0 BEGIN ALTER TABLE XdjxAnsy disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_Budget2Yt')) ,0))>0 BEGIN ALTER TABLE cb_Budget2Yt disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('fy_AgencyFeeSettleFile')) ,0))>0 BEGIN ALTER TABLE fy_AgencyFeeSettleFile disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_PayUpdTrigger')) ,0))>0 BEGIN ALTER TABLE cb_PayUpdTrigger disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_TargetCostRevise')) ,0))>0 BEGIN ALTER TABLE cb_TargetCostRevise disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('jd_RelativeWork')) ,0))>0 BEGIN ALTER TABLE jd_RelativeWork disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_SKBankRequestLog')) ,0))>0 BEGIN ALTER TABLE cb_SKBankRequestLog disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('cb_RepairOutputValueHistoryData')) ,0))>0 BEGIN ALTER TABLE cb_RepairOutputValueHistoryData disable CHANGE_TRACKING END ; 
IF (SELECT ISNULL( CHANGE_TRACKING_MIN_VALID_VERSION( OBJECT_ID('myTaskWake')) ,0))>0 BEGIN ALTER TABLE myTaskWake disable CHANGE_TRACKING END ; 

