USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_cb_rptBudgetYgAlterInfo]    Script Date: 2025/8/6 14:47:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
 * 合约规划及预留金一览表
 * 主要功能:查合约规划及预留金一览表
 --南京市江北广西埂大街北G14、G15、G17、G18-一期
 * exec usp_cb_rptBudgetYgAlterInfo '4975B69C-9953-4DD0-A65E-9A36DB8C66DF','2025-01-01','2025-05-13'
 E33F4636-3875-4EE8-B4C3-04DF4CF90119
 */
 -- 参考合约规划明细界面的存储过程 [usp_cb_GetBudgetInfoMain]
-- select   * from  cb_BudgetBill where ProjectGUID ='592d98ab-2883-e811-80bf-e61f13c57837' order by  ApplyDate  desc
--    EXEC usp_cb_GetBudgetBill_Grid1 'b8637b08-15a9-11f0-9c22-005056bdcec8'
 -- exec sp_executesql N'EXEC  usp_cb_GetBudgetInfoMain  @ProjGUID ,@State,@BudgetName',N'@ProjGUID nvarchar(36),@State nvarchar(4000),@BudgetName nvarchar(4000)',@ProjGUID=N'51D38836-2B57-E711-80BA-E61F13C57837',@State=N'',@BudgetName=N''

ALTER   proc [dbo].[usp_cb_rptBudgetYgAlterInfo]
(
    @buguid varchar(max), -- 项目分期GUID
    @gdSDate datetime, -- 归档开始时间
    @gdEDate datetime, -- 归档截止时间
    @HtType varchar(200) =null  -- 合同类别
)
as
begin
	--已签约的合同
	SELECT 
	 c.ContractGUID
	,c.ContractName
	,c.bgxs 
	,b.ExecutingBudgetGUID
	,c.HtClass 
	,c.JsState
    ,c.SignDate
    , case  when  zjcon.是否首次总价合同=1 then  '首次签约为总价包干'
            when  zjcon.是否已转总价合同=1 then '首次签约为单价合同已转总'
            when  isnull(c.bgxs,'')<>'总价包干' then  '单价合同' end  as JJMode
	,SUM(a.CfAmount) AS HtCfAmount
	,SUM(a.YgAlterAmount) AS  YgAlterAmount
	INTO  #HT
	FROM  dbo.cb_BudgetUse a
	INNER JOIN dbo.cb_Budget b ON b.BudgetGUID = a.BudgetGUID 
	INNER JOIN cb_Contract c ON c.ContractGUID=a.RefGUID
	INNER JOIN dbo.p_Project p ON a.ProjectCode=p.ProjCode
    left  join (
            select  ContractGUID,
            case when isnull(fscon.补充合同数,0)= isnull(fscon.未关联暂转固单据且未施工图结算的补充合同数,0) then 1 else 0 end as 是否首次总价合同,
            case when isnull(fscon.有关联暂转固单据或施工图结算的补充合同数,0) > 0 then 1 else 0 end as 是否已转总价合同
            from  cb_Contract con WITH(NOLOCK)
            left join (
                select  
                MasterContractGUID,
                count(1) as 补充合同数,
                --计划方式=总价包干，且所有补充合同未关联暂转固单据且补充合同【是否施工图结算】字段为'否'
                sum( case when  isnull(IsConstructionBalance ,0) = 0 
                and  ZzgHTBalanceGUID  is null then 1 else 0 end ) as 未关联暂转固单据且未施工图结算的补充合同数,
                -- 计划方式=总价包干，且任意一个补充合同有关联暂转固单据或任意一个补充合同【是否施工图结算】字段为'是'
                sum(  case when  isnull(IsConstructionBalance ,0) = 1 
                or  ZzgHTBalanceGUID  is not null then 1 else 0 end ) as 有关联暂转固单据或施工图结算的补充合同数
                from  cb_Contract fscon WITH(NOLOCK)
                where  HtProperty ='补充合同' 
                group by MasterContractGUID
            ) fscon on con.ContractGUID=fscon.MasterContractGUID
            where  bgxs='总价包干' 
        ) zjcon on zjcon.ContractGUID=a.RefGUID
	WHERE a.IsApprove=1 AND	 c.IfDdhs=1
	AND p.buguid in (  SELECT [Value] FROM dbo.fn_Split1(@buguid, ',') )
	GROUP BY  c.ContractGUID,c.ContractName,c.bgxs, b.ExecutingBudgetGUID,c.HtClass ,c.SignDate,c.JsState,
    case  when  zjcon.是否首次总价合同=1 then  '首次签约为总价包干'
            when  zjcon.是否已转总价合同=1 then '首次签约为单价合同已转总'
            when  isnull(c.bgxs,'')<>'总价包干' then  '单价合同' end 


	--已结算合同-已定合同
	SELECT
	d.ExecutingBudgetGUID
	,SUM(c.JsAmount) AS JsAmount
	INTO  #JS
	FROM dbo.cb_HTBalance a
	INNER JOIN cb_HTAlter b ON a.HTBalanceGUID=b.RefGUID
	INNER JOIN dbo.cb_BudgetUse c ON c.RefGUID=b.HTAlterGUID
	INNER JOIN dbo.cb_Budget d ON d.BudgetGUID = c.BudgetGUID 
	INNER JOIN dbo.p_Project p ON c.ProjectCode=p.ProjCode
	WHERE c.IsApprove=1  	
	AND p.buguid  in (  SELECT [Value] FROM dbo.fn_Split1(@buguid, ',') )
	GROUP BY d.ExecutingBudgetGUID


	--非现金变更
	SELECT
	d.ExecutingBudgetGUID
	,SUM(c.CfAmount) AS fxjAmount
	INTO  #FXJ
	FROM cb_HTAlter b 
	INNER JOIN dbo.cb_BudgetUse c ON c.RefGUID=b.HTAlterGUID
	INNER JOIN dbo.cb_Budget d ON d.BudgetGUID = c.BudgetGUID 
	INNER JOIN dbo.p_Project p ON c.ProjectCode=p.ProjCode
	WHERE c.IsApprove=1  AND b.IsFromXyl=1
	AND p.buguid in (  SELECT [Value] FROM dbo.fn_Split1(@buguid, ',') )
	GROUP BY d.ExecutingBudgetGUID


	
	--合约规划关联采购方案
	SELECT ExecutingBudgetGUID,CgPlanAmount
	INTO #CgPlan FROM (
		SELECT
		 a.ExecutingBudgetGUID
		,a.Amount  AS  CgPlanAmount
		,ROW_NUMBER() OVER (PARTITION BY a.ExecutingBudgetGUID ORDER BY a.createdate desc) rowno
		FROM dbo.cb_BudgetCgPlanAmount a
		INNER JOIN  dbo.cb_Budget_Executing b ON b.ExecutingBudgetGUID = a.ExecutingBudgetGUID
		WHERE b.buguid in (  SELECT [Value] FROM dbo.fn_Split1(@buguid, ',') )
	)  aa WHERE aa.rowno=1


	--预呈批
	SELECT  
	 ExecutingBudgetGUID
	,PreAmount
	,BudgetAmount
	INTO #Pre
	FROM (
		SELECT  
			 ExecutingBudgetGUID
			,PreAmount
			,BudgetAmount
			,ROW_NUMBER() OVER (PARTITION BY ExecutingBudgetGUID ORDER BY SignDate DESC,PreContractGUID) rowno
		FROM (
			SELECT 
			 d.ExecutingBudgetGUID
			,SUM(c.CfAmount) AS  PreAmount
			,SUM(c.BudgetAmount) AS  BudgetAmount
			,a.PreContractGUID
			,a.SignDate
			FROM dbo.cb_Contract_Pre a
			INNER JOIN dbo.cb_BudgetUse c ON c.RefGUID=a.PreContractGUID
			INNER JOIN dbo.cb_Budget d ON d.BudgetGUID = c.BudgetGUID 
			INNER JOIN dbo.p_Project p ON c.ProjectCode=p.ProjCode
			WHERE a.ApproveState IN ('审核中','已审核')
			AND p.buguid in (  SELECT [Value] FROM dbo.fn_Split1(@buguid, ',') )
			GROUP BY d.ExecutingBudgetGUID,a.PreContractGUID,a.SignDate
		) aa 
	)aaa WHERE aaa.rowno=1

	--已发生
	SELECT b.ExecutingBudgetGUID
	,SUM(ISNULL(f.CfAmount,0) )   AS YfsCost
	,SUM(CASE WHEN c.HTAlterGUID IS NOT NULL THEN  ISNULL(f.CfAmount,0) ELSE 0 END) ylj_yfs
	INTO #yfs
	FROM  cb_BudgetUse f  
	INNER JOIN dbo.cb_Budget b ON b.BudgetGUID = f.BudgetGUID
	INNER JOIN dbo.p_Project p ON p.ProjCode=f.ProjectCode
	LEFT JOIN  dbo.cb_HTAlter c ON c.HTAlterGUID=f.RefGUID AND c.isUseYgAmount=1
	WHERE  f.IsApprove = 1 
	AND ISNULL(f.IsFromXyl,0)=0
	AND p.buguid in (  SELECT [Value] FROM dbo.fn_Split1(@buguid, ',') )
	GROUP  BY b.ExecutingBudgetGUID

	--预留金额
	SELECT b.ExecutingBudgetGUID 
	,ISNULL(SUM(a.CfAmount),0)  AS YgYeAmount
	,ISNULL(SUM(a.ygAlterAdj),0) AS ygAlterAdj
	INTO #ylj
	FROM cb_YgAlter2Budget a
	INNER JOIN dbo.cb_Budget b ON b.BudgetGUID = a.BudgetGUID
	where b.buguid in (  SELECT [Value] FROM dbo.fn_Split1(@buguid, ',') )
	GROUP  BY b.ExecutingBudgetGUID


	--上一版合约规划
	SELECT ex.ExecutingBudgetGUID,
	CASE WHEN aa.ExecutingBudgetGUID IS NULL THEN  ex.BudgetAmount ELSE ISNULL(aa.BudgetAmount,0) END  AS UpBudgetAmount
	INTO #UpBudget
	FROM  dbo.cb_Budget_Executing ex
	LEFT JOIN (
		SELECT a.ExecutingBudgetGUID
		,a.BudgetAmount
		,ROW_NUMBER() OVER(PARTITION BY a.ExecutingBudgetGUID ORDER BY a.UpdateDate DESC) AS rowno 
		FROM  cb_BudgetAmountVer a
		LEFT JOIN cb_Budget_Executing b ON a.ExecutingBudgetGUID=b.ExecutingBudgetGUID
		WHERE b.buguid in (  SELECT [Value] FROM dbo.fn_Split1(@buguid, ',') ) 
	) aa on aa.rowno=2 AND ex.ExecutingBudgetGUID=aa.ExecutingBudgetGUID
	WHERE ex.buguid in (  SELECT [Value] FROM dbo.fn_Split1(@buguid, ',') )


	
	--负数补协 负数补协(不含暂转固）
	SELECT b.ExecutingBudgetGUID, 
	ISNULL(SUM(f.CfAmount),0)  FsBxAmount
	INTO  #fsBx
	FROM  cb_BudgetUse f  
	INNER JOIN dbo.cb_Budget b ON b.BudgetGUID = f.BudgetGUID
	INNER JOIN cb_HTAlter g ON f.RefGUID = g.HTAlterGUID  
	INNER JOIN dbo.cb_Contract ct ON  g.RefGUID=ct.ContractGUID 
	INNER JOIN dbo.p_Project p ON p.ProjCode=f.ProjectCode
	WHERE f.CfSource = '变更' 
		  AND f.IsApprove = 1  
		  AND g.AlterType='附属合同'
		  AND ct.ZzgHTBalanceGUID IS NULL
		  AND g.AlterAmount<0
		  AND p.buguid in (  SELECT [Value] FROM dbo.fn_Split1(@buguid, ',') )
	GROUP BY	b.ExecutingBudgetGUID


	--暂转固
	--项目下所有的转固变更
	SELECT DISTINCT  b.ContractGUID,b.HTAlterGUID ,a.ApproveDate
	INTO #ZZGBG
	FROM dbo.cb_Contract a
	INNER JOIN dbo.cb_HTAlter b ON a.ContractGUID=b.RefGUID
	INNER JOIN  dbo.cb_BudgetUse bu ON bu.RefGUID=b.HTAlterGUID 
	INNER JOIN dbo.p_Project p ON p.ProjCode=bu.ProjectCode
	WHERE  p.buguid in (  SELECT [Value] FROM dbo.fn_Split1(@buguid, ',') ) and   b.AlterType='附属合同' AND a.ZzgHTBalanceGUID IS NOT NULL 

	--获取合同最新的暂转固合约规划金额 
	SELECT d.ExecutingBudgetGUID,ISNULL(SUM(c.ZzgAmount),0) AS ZzgAmount
	INTO #ZZG
	FROM dbo.cb_BudgetUse c
	INNER JOIN dbo.cb_Budget d ON d.BudgetGUID =c.BudgetGUID
	INNER JOIN dbo.p_Project p ON p.ProjCode=c.ProjectCode
	INNER JOIN  (
		SELECT ContractGUID
		,HTAlterGUID 
		,ROW_NUMBER() OVER(PARTITION BY ContractGUID ORDER BY ApproveDate desc) rowno 
		FROM #ZZGBG
	) aa  ON c.RefGUID=aa.HTAlterGUID AND  aa.rowno=1
	WHERE p.buguid in (  SELECT [Value] FROM dbo.fn_Split1(@buguid, ',') )
	GROUP BY d.ExecutingBudgetGUID

    -- 合约规划调整明细
    SELECT 
            bl.subject, -- 申请主题
	        bl.applydate, -- 申请日期
			u.username, -- 申请人
			bl.approvelevel, --分级审批类型
            a.BudgetBillGUID,
            a.BudgetBillDetailGUID ,
            wf.InitiateDatetime ,
            wf.FinishDatetime ,
            wf.OwnerName ,

            A.WorkingBudgetGUID ,
            CASE WHEN con.ContractGUID IS NOT NULL THEN con.ContractName ELSE B.BudgetName END  AS  BudgetName,                                                  
            A.ModifyType , -- 调整类型
            CASE A.ModifyType
                WHEN 1 THEN '新增合约规划'
                WHEN 2 THEN '调整合约规划'
                WHEN 3 THEN '删除合约规划'
                WHEN 4 THEN '调整预留金'
            END ModifyTypeDescription , -- 调整类型名称
            ISNULL(PlanAmountBeforeAdjust, 0) PlanAmountBeforeAdjust ,  -- 调整前规划含税金额
            ISNULL(PlanAmountAfterAdjust, 0) PlanAmountAfterAdjust ,    -- 调整后规划含税金额
            ISNULL(PlanNoTaxAmountBeforeAdjust, 0) PlanNoTaxAmountBeforeAdjust , --调整前规划不含税金额
            ISNULL(PlanNoTaxAmountAfterAdjust, 0) PlanNoTaxAmountAfterAdjust , -- 调整后规划不含税金额
            ISNULL(PlanAmountAfterAdjust, 0) - ISNULL(PlanAmountBeforeAdjust, 0) AS DiffBudgetAmount, -- 差异金额

            AdjustReason.合约规划变动原因_标段划分调整调整金额,
            AdjustReason.合约规划变动原因_规划方案调整调整金额,
            AdjustReason.合约规划变动原因_合同范围调整调整金额,
            AdjustReason.合约规划变动原因_合约规划拆分不准调整金额,
            AdjustReason.合约规划变动原因_销售转经营调整金额,
            AdjustReason.合约规划变动原因_新增整改及提升调整金额,
            AdjustReason.合约规划变动原因_其它调整金额, 

            -- 新增字段
            --AdjustReason.合约规划变动原因_合约规划拆分不准或错误,
            AdjustReason.合约规划变动原因_成本预估不足,
            AdjustReason.合约规划变动原因_政府要求或政策原因,
            AdjustReason.合约规划变动原因_促销售焕新或提升,
            AdjustReason.合约规划变动原因_保交付或提升客户满意度整改及提升,
            AdjustReason.合约规划变动原因_质量缺陷,
            AdjustReason.合约规划变动原因_不可抗力抢险等,
            AdjustReason.合约规划变动原因_联动资源原因,

            
            AdjustReason.预留金变动原因_材料调差调整金额,  
            AdjustReason.预留金变动原因_合同范围调整调整金额,    
            AdjustReason.预留金变动原因_阶段结算调整金额,    
            AdjustReason.预留金变动原因_签证变更调整金额,    
            AdjustReason.预留金变动原因_退场调整金额,  
            AdjustReason.预留金变动原因_暂转固调整金额,    
            AdjustReason.预留金变动原因_争议或索赔调整金额,  
            -- 新增字段
            AdjustReason.预留金变动原因_调整暂定价,
            AdjustReason.预留金变动原因_其它调整金额            
                -- STUFF((
                --     SELECT ',' + ReasonName + '(' + CAST(AdjustAmount AS VARCHAR(20)) + ')'
                --     FROM cb_BudgetBill2AdjustReason 
                --     WHERE cb_BudgetBill2AdjustReason.BudgetBillGUID = A.BudgetBillGUID  AND a.WorkingBudgetGUID=cb_BudgetBill2AdjustReason.WorkingBudgetGUID 
                --     FOR XML PATH('')
                -- ), 1, 1, '') AS details -- 调整原因
    into #BudgetBillDetail
    FROM  dbo.cb_BudgetBillDetail a
    inner join  cb_BudgetBill bl on a.budgetbillguid =bl.budgetbillguid
    left join myuser u on bl.userguid =u.userguid
    left join myWorkflowProcessEntity wf on wf.BusinessGUID = a.BudgetBillGUID
    LEFT JOIN dbo.cb_Budget_Working b ON a.WorkingBudgetGUID = b.WorkingBudgetGUID
    left JOIN (
        select  
             BudgetBillGUID,
             WorkingBudgetGUID,
            -- sum(case when  ReasonName ='合约规划拆分不准或错误' and  type <> 4 then  AdjustAmount else 0  end ) as  合约规划变动原因_合约规划拆分不准或错误, --合约规划拆分不准或错误
            sum(case when  ReasonName ='成本预估不足' and  type <> 4 then  AdjustAmount else 0  end ) as   合约规划变动原因_成本预估不足, --成本预估不足
            sum(case when  ReasonName in ('合约规划拆分不准','合约规划拆分不准或错误') and  type <> 4 then  AdjustAmount else 0 end)  as  合约规划变动原因_合约规划拆分不准调整金额,
            sum(case when  ReasonName ='新增整改及提升' and  type <> 4 then  AdjustAmount else 0 end )  as  合约规划变动原因_新增整改及提升调整金额,
            sum(case when  ReasonName ='合同范围调整' and  type <> 4 then  AdjustAmount else 0 end ) as  合约规划变动原因_合同范围调整调整金额,
            sum(case when  ReasonName ='规划方案调整' and  type <> 4 then  AdjustAmount else 0 end ) as  合约规划变动原因_规划方案调整调整金额,
            sum(case when  ReasonName ='政府要求或政策原因' and  type <> 4 then  AdjustAmount else 0 end ) as  合约规划变动原因_政府要求或政策原因,--政府要求或政策原因
            sum(case when  ReasonName ='销售转经营' and  type <> 4 then  AdjustAmount else 0 end ) as  合约规划变动原因_销售转经营调整金额,--销售转经营
            sum(case when  ReasonName ='促销售（焕新或提升）' and  type <> 4 then  AdjustAmount else 0 end ) as  合约规划变动原因_促销售焕新或提升,--促销售（焕新或提升）
            sum(case when  ReasonName ='保交付或提升客户满意度（整改及提升）' and  type <> 4 then  AdjustAmount else 0 end ) as  合约规划变动原因_保交付或提升客户满意度整改及提升,--保交付或提升客户满意度（整改及提升）
            sum(case when  ReasonName ='标段划分调整' and  type <> 4 then  AdjustAmount else 0  end ) as  合约规划变动原因_标段划分调整调整金额,
            sum(case when  ReasonName ='质量缺陷' and  type <> 4 then  AdjustAmount else 0  end ) as  合约规划变动原因_质量缺陷,-- 质量缺陷
            sum(case when  ReasonName ='不可抗力（抢险等）' and  type <> 4 then  AdjustAmount else 0  end ) as  合约规划变动原因_不可抗力抢险等, --不可抗力（抢险等）
            sum(case when  ReasonName ='联动资源原因' and  type <> 4 then  AdjustAmount else 0  end ) as  合约规划变动原因_联动资源原因,--联动资源原因
            sum(case when  ReasonName ='其它' and  type <> 4 then  AdjustAmount else 0 end ) as  合约规划变动原因_其它调整金额,

            sum(case when  ReasonName ='材料调差' and  type = 4 then  AdjustAmount else 0  end ) as  预留金变动原因_材料调差调整金额,  
            sum(case when  ReasonName ='合同范围调整' and  type = 4 then  AdjustAmount else 0 end ) as  预留金变动原因_合同范围调整调整金额,    
            sum(case when  ReasonName ='阶段结算' and  type = 4 then  AdjustAmount else 0 end ) as  预留金变动原因_阶段结算调整金额,    
            sum(case when  ReasonName ='签证变更' and  type = 4 then  AdjustAmount else 0 end )  as  预留金变动原因_签证变更调整金额,    
            sum(case when  ReasonName ='退场' and  type = 4 then  AdjustAmount else  0 end ) as  预留金变动原因_退场调整金额,  
            sum(case when  ReasonName ='暂转固' and  type = 4 then  AdjustAmount else 0 end ) as  预留金变动原因_暂转固调整金额,    
            sum(case when  ReasonName ='争议或索赔' and  type = 4 then  AdjustAmount else 0 end)  as  预留金变动原因_争议或索赔调整金额,    
            sum(case when  ReasonName ='调整暂定价' and  type = 4 then  AdjustAmount else 0 end)  as  预留金变动原因_调整暂定价,    
            sum(case when  ReasonName ='其它' and  type = 4 then  AdjustAmount else 0 end )  as  预留金变动原因_其它调整金额
        from cb_BudgetBill2AdjustReason
        group by BudgetBillGUID,WorkingBudgetGUID
    ) AdjustReason on AdjustReason.BudgetBillGUID = A.BudgetBillGUID  AND a.WorkingBudgetGUID=AdjustReason.WorkingBudgetGUID 
    LEFT JOIN (
                SELECT   c.ContractGUID
                        ,c.ContractName																		 
                        ,b.ExecutingBudgetGUID
                FROM  dbo.cb_BudgetUse a
                        INNER JOIN dbo.cb_Budget b ON b.BudgetGUID = a.BudgetGUID 
                        INNER JOIN cb_Contract c ON c.ContractGUID=a.RefGUID
                        INNER JOIN dbo.p_Project p ON a.ProjectCode=p.ProjCode
                        WHERE a.IsApprove=1
                        AND p.buguid in (  SELECT [Value] FROM dbo.fn_Split1(@buguid, ',') )
                        GROUP BY  c.ContractGUID,c.ContractName, b.ExecutingBudgetGUID
     ) con ON con.ExecutingBudgetGUID = A.WorkingBudgetGUID
     where bl.approvestate in  ('审核中','已审核') 
     and  isnull( wf.InitiateDatetime,bl.applydate )  BETWEEN @gdSDate and @gdEDate

    -- 查询结果
    SELECT 
        bu.buname AS '公司名称',
        bu.buguid as '公司GUID',
        proj.projname AS '项目名称',
        proj.projguid as '项目GUID',
        flg.投管代码 AS '投管代码',
        mp.ProjCode AS '明源系统代码', 

        CASE WHEN ht.ContractGUID IS NOT NULL THEN ht.ContractName ELSE a.BudgetName END   AS '合约名称',
        ht.ContractName AS '合同名称',
        CASE WHEN ht.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0) +ISNULL(ylj.YgYeAmount,0)
		  ELSE a.BudgetAmount  
		  END  AS  '最新合约规划金额',
        ht.JJMode AS '计价方式',
        b.HtTypeName AS '合同大类',
        c.BudgetName AS '合同类别',
        ht.SignDate AS '合同签订时间',
        CASE WHEN ht.ExecutingBudgetGUID IS  NULL THEN  a.BudgetAmount  END AS '未签合同金额', -- 取最新合约规划的金额，已签合同则为空
        isnull(ht.HtCfAmount,0) AS '合同首次签约金额',
        zzg.ZzgAmount AS '暂转固金额',
        -- CASE WHEN a.ModifyType=1 THEN '新增合约规划' 
        --      WHEN a.ModifyType=2 THEN '调整合约规划' 
        --      WHEN a.ModifyType=3 THEN '删除合约规划' 
        --      WHEN yg.YgAlterAdjustGUID IS NOT NULL THEN '调整预留金'  ELSE '' END  AS '调整类型',
        -- workflow.InitiateDatetime AS '发起时间',
        -- workflow.FinishDatetime AS '归档时间',
        -- workflow.OwnerName AS '发起人',
        bugetbill.ModifyTypeDescription as  '调整类型',
        bugetbill.InitiateDatetime AS '发起时间',
        bugetbill.FinishDatetime AS '归档时间',
        bugetbill.OwnerName AS '发起人',

        CASE WHEN pre.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(pre.BudgetAmount,isnull(ex.BudgetAmount,0))
		  WHEN cg.ExecutingBudgetGUID IS NOT NULL THEN  ISNULL(cg.CgPlanAmount,isnull(ex.BudgetAmount,0))
		  ELSE ISNULL(up.UpBudgetAmount,isnull(ex.BudgetAmount,0)) 
	      END   AS '目标成本原规划金额', -- 取合约规划模块合约列表的原合约规划金额

        -- bugetbill.sumPlanAmountBeforeAdjust AS '调整前规划金额',
        -- bugetbill.sumPlanAmountAfterAdjust AS '调整后规划金额',
        -- bugetbill.yljDiffBudgetAmount AS '预留金变动金额',
        bugetbill.subject as 申请主题,
        bugetbill.applydate as 申请日期,
        bugetbill.username as  申请人,
        bugetbill.approvelevel as 分级审批类型,

        -- case  when  bugetbill.ModifyType <> 4  then PlanAmountBeforeAdjust else  0 end as '调整前规划金额',
        -- case  when  bugetbill.ModifyType <> 4  then PlanAmountAfterAdjust else  0 end as '调整后规划金额',
         PlanAmountBeforeAdjust as '调整前规划金额',
         PlanAmountAfterAdjust  as '调整后规划金额',
        case  when  bugetbill.ModifyType = 4  then DiffBudgetAmount else  0 end '预留金变动金额',

        ISNULL(yfs.ylj_yfs,0)  AS '已发生预留金',
        case when   
           CASE WHEN ht.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0) +ISNULL(ylj.YgYeAmount,0) ELSE a.BudgetAmount  END =0 then  0
           else  
           ISNULL(yfs.ylj_yfs,0)  / CASE WHEN ht.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0) +ISNULL(ylj.YgYeAmount,0) ELSE a.BudgetAmount  END
        end   AS '已发生预留金比例', -- 取该合约规划本次调整时的已发生预留金占该合同动态(最新合约规划金额)的比例

        case  when  bugetbill.ModifyType = 4  then PlanAmountAfterAdjust else  0 end AS '调整后待发生预留金',
        case when  
            CASE WHEN ht.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0) +ISNULL(ylj.YgYeAmount,0) ELSE a.BudgetAmount  END =0 then  0
        else 
            case  when  bugetbill.ModifyType = 4  then PlanAmountAfterAdjust else  0 end  / 
            CASE WHEN ht.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0) +ISNULL(ylj.YgYeAmount,0) ELSE a.BudgetAmount  END
        end  AS '调整后待发生预留金比例', -- 取该合约规划本次调整后的待发生预留金额占合同动态(最新合约规划金额)的比例


        -- 合约规划变动原因_合约规划拆分不准或错误 as '合约规划变动原因_合约规划拆分不准或错误', --合约规划拆分不准或错误
        合约规划变动原因_成本预估不足 as '合约规划变动原因_成本预估不足', --成本预估不足
        合约规划变动原因_合约规划拆分不准调整金额 as '合约规划变动原因_合约规划拆分不准',
        合约规划变动原因_新增整改及提升调整金额 as '合约规划变动原因_新增整改及提升',
        合约规划变动原因_合同范围调整调整金额 as '合约规划变动原因_合同范围调整' ,
        合约规划变动原因_规划方案调整调整金额 as '合约规划变动原因_规划方案调整',
        合约规划变动原因_政府要求或政策原因 as '合约规划变动原因_政府要求或政策原因',--政府要求或政策原因
        合约规划变动原因_销售转经营调整金额 as '合约规划变动原因_销售转经营' ,--销售转经营
        合约规划变动原因_促销售焕新或提升 as '合约规划变动原因_促销售焕新或提升' ,--促销售（焕新或提升）
        合约规划变动原因_保交付或提升客户满意度整改及提升 as '合约规划变动原因_保交付或提升客户满意度整改及提升',--保交付或提升客户满意度（整改及提升）
        合约规划变动原因_标段划分调整调整金额 as  '合约规划变动原因_标段划分调整',
        合约规划变动原因_质量缺陷 as '合约规划变动原因_质量缺陷',-- 质量缺陷
        合约规划变动原因_不可抗力抢险等 as '合约规划变动原因_不可抗力抢险等' , --不可抗力（抢险等）
        合约规划变动原因_联动资源原因 as  '合约规划变动原因_联动资源原因',--联动资源原因
        合约规划变动原因_其它调整金额 as '合约规划变动原因_其它',


        预留金变动原因_暂转固调整金额 AS '预留金变动原因_暂转固',
        预留金变动原因_阶段结算调整金额 AS '预留金变动原因_阶段结算',
        预留金变动原因_签证变更调整金额 AS '预留金变动原因_签证变更',
        预留金变动原因_合同范围调整调整金额 AS '预留金变动原因_合同范围调整',
        预留金变动原因_材料调差调整金额 AS '预留金变动原因_材料调差',
        预留金变动原因_争议或索赔调整金额 AS '预留金变动原因_争议或索赔',
        预留金变动原因_退场调整金额 AS '预留金变动原因_退场',
        预留金变动原因_调整暂定价 AS '预留金变动原因_调整暂定价', -- 调整暂定价
        预留金变动原因_其它调整金额 AS '预留金变动原因_其它'
    FROM p_project proj
    INNER JOIN mybusinessunit bu ON proj.buguid = bu.buguid 
    INNER JOIN ERP25.dbo.mdm_project mp WITH(NOLOCK)  ON mp.projguid = proj.ProjGUID
    LEFT JOIN erp25.dbo.vmdm_projectFlag flg WITH(NOLOCK)   ON flg.projguid = mp.ParentProjGUID
    inner join cb_Budget_Working a on a.ProjectGUID = proj.projguid
    LEFT JOIN dbo.cb_Budget_Executing ex ON ex.ExecutingBudgetGUID=a.WorkingBudgetGUID
    LEFT JOIN #UpBudget up ON up.ExecutingBudgetGUID = ex.ExecutingBudgetGUID
    LEFT JOIN dbo.cb_HtType b ON a.BigHTTypeGUID=b.HtTypeGUID
    LEFT JOIN dbo.cb_BudgetLibrary c ON c.BudgetLibraryGUID=a.BudgetLibraryGUID  
    LEFT JOIN #JS js ON js.ExecutingBudgetGUID=a.WorkingBudgetGUID
	LEFT JOIN #HT ht ON ht.ExecutingBudgetGUID = a.WorkingBudgetGUID
    LEFT JOIN #Pre pre ON pre.ExecutingBudgetGUID = a.WorkingBudgetGUID
	LEFT JOIN #CgPlan cg ON cg.ExecutingBudgetGUID = a.WorkingBudgetGUID
    LEFT JOIN #yfs yfs ON yfs.ExecutingBudgetGUID=a.WorkingBudgetGUID
    LEFT JOIN #ZZG zzg ON zzg.ExecutingBudgetGUID = a.WorkingBudgetGUID
    LEFT JOIN #ylj ylj ON ylj.ExecutingBudgetGUID=a.WorkingBudgetGUID
    left join myWorkflowProcessEntity workflow on workflow.BusinessGUID =ht.ContractGUID and  isnull(workflow.IsHistory,0) =0
	LEFT JOIN dbo.cb_YgAlterAdjust_Pre yg ON yg.WorkingBudgetGUID=a.WorkingBudgetGUID
    inner join #BudgetBillDetail bugetbill  on bugetbill.WorkingBudgetGUID =a.WorkingBudgetGUID
    -- left join (
    --      select  
    --         WorkingBudgetGUID,
    --         sum(case  when  ModifyType <> 4  then PlanAmountAfterAdjust else  0 end  ) as sumPlanAmountAfterAdjust, 
    --         sum(case  when  ModifyType <> 4  then PlanAmountBeforeAdjust else  0 end ) as sumPlanAmountBeforeAdjust,
    --         sum(case when  ModifyType =4 then DiffBudgetAmount else 0 end ) as yljDiffBudgetAmount, -- 预留金变动金额

    --         sum(case when  ModifyType =4 then PlanAmountAfterAdjust else  0  end ) as sumPlanAmountAfterAdjustYjl, -- 调整后的预留金金额
    --         sum(case when  ModifyType =4 then PlanAmountBeforeAdjust else  0  end ) as sumPlanAmountBeforeAdjustYjl, -- 调整前的预留金金额  
    --         sum(合约规划变动原因_标段划分调整调整金额) as 合约规划变动原因_标段划分调整调整金额,
    --         sum(合约规划变动原因_规划方案调整调整金额) as 合约规划变动原因_规划方案调整调整金额,
    --         sum(合约规划变动原因_合同范围调整调整金额) as 合约规划变动原因_合同范围调整调整金额,
    --         sum(合约规划变动原因_合约规划拆分不准调整金额) as 合约规划变动原因_合约规划拆分不准调整金额,
    --         sum(合约规划变动原因_销售转经营调整金额) as 合约规划变动原因_销售转经营调整金额,
    --         sum(合约规划变动原因_新增整改及提升调整金额) as 合约规划变动原因_新增整改及提升调整金额,
    --         sum(合约规划变动原因_其它调整金额) as 合约规划变动原因_其它调整金额, 

    --         sum(预留金变动原因_材料调差调整金额) as 预留金变动原因_材料调差调整金额,  
    --         sum(预留金变动原因_合同范围调整调整金额) as 预留金变动原因_合同范围调整调整金额,    
    --         sum(预留金变动原因_阶段结算调整金额) as 预留金变动原因_阶段结算调整金额,    
    --         sum(预留金变动原因_签证变更调整金额) as 预留金变动原因_签证变更调整金额,    
    --         sum(预留金变动原因_退场调整金额) as 预留金变动原因_退场调整金额,  
    --         sum(预留金变动原因_暂转固调整金额) as 预留金变动原因_暂转固调整金额,    
    --         sum(预留金变动原因_争议或索赔调整金额) as 预留金变动原因_争议或索赔调整金额,    
    --         sum(预留金变动原因_其它调整金额) as 预留金变动原因_其它调整金额  
    --      from  #BudgetBillDetail 
    --      group by WorkingBudgetGUID
    -- ) bugetbill  on bugetbill.WorkingBudgetGUID =a.WorkingBudgetGUID
    WHERE proj.level =3 
         and  proj.buguid  in (  SELECT [Value] FROM dbo.fn_Split1(@buguid, ',')  ) 
         and  isnull(bugetbill.InitiateDatetime,bugetbill.applydate) BETWEEN @gdSDate and @gdEDate
         -- and  b.HtTypeName  in ( @HtType ) 
    order by  bu.buname,proj.projname,c.BudgetName


    -- 删除临时表
    DROP TABLE IF EXISTS #HT
    DROP TABLE IF EXISTS #Pre
    DROP TABLE IF EXISTS #ZZG 
    DROP TABLE IF EXISTS #CgPlan
    DROP TABLE IF EXISTS #UpBudget
    DROP TABLE IF EXISTS  #ylj
    DROP TABLE IF EXISTS  #BudgetBillDetail

end 


--  select ReasonName from  cb_BudgetBill2AdjustReason group by  ReasonName
