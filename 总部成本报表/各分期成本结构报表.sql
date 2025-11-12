USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_cb_CostStructureReport]    Script Date: 2025/11/11 11:10:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




/*
 * 各分期成本结构报表
 * 主要功能:查询各分期的成本结构信息,包括基本信息、总成本情况、预留金、产值及支付等
 */
 -- exec sp_executesql N'EXEC usp_cb_BudgetTitle @ProjGUID',N'@ProjGUID nvarchar(36)',@ProjGUID=N'9a86d4ea-8513-e711-80ba-e61f13c57837'
 -- exec sp_executesql N'EXEC  usp_cb_GetBudgetInfoMain  @ProjGUID ,@State,@BudgetName',N'@ProjGUID nvarchar(36),@State nvarchar(4000),@BudgetName nvarchar(4000)',@ProjGUID=N'9a86d4ea-8513-e711-80ba-e61f13c57837',@State=N'',@BudgetName=N''
 --exec [usp_rpt_cb_CostStructureReport] '4A1E877C-A0B2-476D-9F19-B5C426173C38'
 -- modify by zhangjie 2025-05-27 增加已发生预留金(已结算)和已发生预留金(未结算)字段
 -- modify by tangqn01 20250723 增加 本年新签合同份数 /本年新签合同金额 /本年招标结余金额
 -- modify by chenjw 2025-08-04 动态成本计算只取执行版的合约规划
ALTER  proc [dbo].[usp_rpt_cb_CostStructureReport]
(
    @var_buguid varchar(max) ,  -- 公司guid
    @var_projguid varchar(max) =null  -- 项目guid
)
as
begin
--  select  Level,* from p_Project where  ProjGUID ='2b3b0206-f785-e911-80b7-0a94ef7517dd'
-- declare  @var_projguid varchar(max) ='2b3b0206-f785-e911-80b7-0a94ef7517dd'
	--已签约的合同
	SELECT 
        c.ContractGUID
        ,c.ContractName
        ,case when zjcon.是否已转总价合同 =1 then '总价包干' else   c.bgxs end  as  bgxs -- 计价方式
        ,b.ExecutingBudgetGUID
        ,c.HtClass 
        ,c.JsState
        ,zjcon.是否首次总价合同
        ,zjcon.是否已转总价合同
        ,SUM(a.CfAmount) AS HtCfAmount
        ,SUM(a.YgAlterAmount) AS  YgAlterAmount
        ,sum(case when zjcon.是否首次总价合同=1 then a.CfAmount else 0 end) as zjHtCfAmount -- 总价合同金额
        ,sum(case when zjcon.是否已转总价合同=1 then a.CfAmount else 0 end) as yzzjHtCfAmount -- 已转总价合同金额
        ,sum(case when isnull(c.bgxs,'')<>'总价包干' and zjcon.是否已转总价合同 <> 1 then a.CfAmount else 0 end) as djHtCfAmount -- 单价合同金额
		,c.SignDate
		,ISNULL(SUM(b.BudgetAmount),0) - ISNULL(SUM(a.CfAmount),0) - ISNULL(SUM(a.YgAlterAmount),0) AS zbjyAmount --招标结余金额
	INTO  #HT
	FROM  dbo.cb_BudgetUse a WITH(NOLOCK)
	INNER JOIN dbo.cb_Budget b WITH(NOLOCK) ON b.BudgetGUID = a.BudgetGUID 
    INNER JOIN cb_Budget_Executing e  WITH(NOLOCK) ON e.ExecutingBudgetGUID=b.ExecutingBudgetGUID
	INNER JOIN cb_Contract c WITH(NOLOCK) ON c.ContractGUID=a.RefGUID
	INNER JOIN dbo.p_Project p WITH(NOLOCK) ON a.ProjectCode=p.ProjCode
    left  join (
            select  ContractGUID,
            case when  bgxs='总价包干'  and  isnull(fscon.补充合同数,0)= isnull(fscon.未关联暂转固单据且未施工图结算的补充合同数,0) then 1 else 0 end as 是否首次总价合同,
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
            -- where  bgxs='总价包干' 
        ) zjcon on zjcon.ContractGUID=a.RefGUID
	WHERE a.IsApprove= 1  -- 审核中或已审核
    AND	 c.IfDdhs=1  -- 是否单独核算    
    AND ( p.ProjGUID in ( SELECT [Value] FROM dbo.fn_Split1(@var_projguid, ',') ) or @var_projguid is null )
    AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
	GROUP BY  c.ContractGUID,c.ContractName,c.bgxs, b.ExecutingBudgetGUID,c.HtClass ,c.JsState,zjcon.是否首次总价合同,zjcon.是否已转总价合同,c.SignDate

	--负数补协 负数补协(不含暂转固）
	SELECT 
        b.ExecutingBudgetGUID, 
        ISNULL(SUM(f.CfAmount),0)  FsBxAmount
	INTO  #fsBx
	FROM  cb_BudgetUse f  WITH(NOLOCK)
	INNER JOIN dbo.cb_Budget b WITH(NOLOCK) ON b.BudgetGUID = f.BudgetGUID
	INNER JOIN cb_HTAlter g WITH(NOLOCK) ON f.RefGUID = g.HTAlterGUID  
	INNER JOIN dbo.cb_Contract ct WITH(NOLOCK) ON  g.RefGUID=ct.ContractGUID 
	INNER JOIN dbo.p_Project p WITH(NOLOCK) ON p.ProjCode=f.ProjectCode
	WHERE f.CfSource = '变更' 
		  AND f.IsApprove = 1  
		  AND g.AlterType='附属合同'
		  -- AND ct.ZzgHTBalanceGUID IS NULL 
          AND ( ct.ZzgHTBalanceGUID IS NULL or isnull(ct.IsConstructionBalance,0) =0 )
		  AND g.AlterAmount<0
            AND ( p.ProjGUID in ( SELECT [Value] FROM dbo.fn_Split1(@var_projguid, ',') ) or @var_projguid is null )
            AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
	GROUP BY	b.ExecutingBudgetGUID


    --暂转固
	--项目下所有的转固变更
	SELECT DISTINCT  b.ContractGUID,b.HTAlterGUID ,a.ApproveDate
	INTO #ZZGBG
	FROM dbo.cb_Contract a WITH(NOLOCK)
    left join cb_Contract  ca on ca.MasterContractGUID =a.ContractGUID and ca.HtProperty ='补充合同'-- 补充协议
	INNER JOIN dbo.cb_HTAlter b WITH(NOLOCK) ON a.ContractGUID=b.RefGUID or ca.ContractGUID =b.RefGUID
	INNER JOIN  dbo.cb_BudgetUse bu WITH(NOLOCK) ON bu.RefGUID=b.HTAlterGUID 
	INNER JOIN dbo.p_Project p WITH(NOLOCK) ON p.ProjCode=bu.ProjectCode
	WHERE  ( p.ProjGUID in ( SELECT [Value] FROM dbo.fn_Split1(@var_projguid, ',') ) or @var_projguid is null )
     AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') )  and   b.AlterType='附属合同' 
     -- AND a.ZzgHTBalanceGUID IS NOT NULL 
     -- 是否施工图结算为'是' 或 有暂转固单据
    -- and  ( ( a.ZzgHTBalanceGUID IS NOT NULL  or isnull(a.IsConstructionBalance,0) =1 )  or (ca.ZzgHTBalanceGUID is not null or isnull(ca.IsConstructionBalance,0) =1 ) )
    and  (ca.ZzgHTBalanceGUID is not null or isnull(ca.IsConstructionBalance,0) =1 )
    --  and  isnull(ca.IsConstructionBalance,0) =1

	--获取合同最新的暂转固合约规划金额 
	SELECT d.ExecutingBudgetGUID,
    -- ISNULL(SUM(c.ZzgAmount),0) AS ZzgAmount
    isnull(sum(c.CfAmount),0) as ZzgAmount
	INTO #ZZG
	FROM dbo.cb_BudgetUse c WITH(NOLOCK)
	INNER JOIN dbo.cb_Budget d  WITH(NOLOCK) ON d.BudgetGUID =c.BudgetGUID
	INNER JOIN dbo.p_Project p WITH(NOLOCK) ON p.ProjCode=c.ProjectCode
	-- INNER JOIN  (
	-- 	SELECT ContractGUID
	-- 	,HTAlterGUID 
	-- 	,ROW_NUMBER() OVER(PARTITION BY ContractGUID ORDER BY ApproveDate desc) rowno 
	-- 	FROM #ZZGBG
	-- ) aa  ON c.RefGUID=aa.HTAlterGUID AND  aa.rowno=1
	WHERE  ( p.ProjGUID in ( SELECT [Value] FROM dbo.fn_Split1(@var_projguid, ',') ) or @var_projguid is null )
            AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
    and  EXISTS ( SELECT 1 FROM #ZZGBG WHERE #ZZGBG.HTAlterGUID=c.RefGUID )
	GROUP BY d.ExecutingBudgetGUID

   -- 预留金金额
	SELECT 
        b.ExecutingBudgetGUID
	,ISNULL(SUM(a.CfAmount),0)  AS YgYeAmount
	,ISNULL(SUM(a.ygAlterAdj),0) AS ygAlterAdj
	INTO #ylj
	FROM cb_YgAlter2Budget a WITH(NOLOCK)
	INNER JOIN dbo.cb_Budget b WITH(NOLOCK) ON b.BudgetGUID = a.BudgetGUID
	where  ( b.ProjectGUID in ( SELECT [Value] FROM dbo.fn_Split1(@var_projguid, ',') ) or @var_projguid is null )
            AND b.BUGUID in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
	GROUP  BY b.ExecutingBudgetGUID

    --已发生
	SELECT b.ExecutingBudgetGUID
	,SUM(ISNULL(f.CfAmount,0) )   AS YfsCost
	,SUM(CASE WHEN c.HTAlterGUID IS NOT NULL THEN  ISNULL(f.CfAmount,0) ELSE 0 END) ylj_yfs
	INTO #yfs
	FROM  cb_BudgetUse f  WITH(NOLOCK) 
	INNER JOIN dbo.cb_Budget b WITH(NOLOCK) ON b.BudgetGUID = f.BudgetGUID
	INNER JOIN dbo.p_Project p WITH(NOLOCK) ON p.ProjCode=f.ProjectCode
	LEFT JOIN  dbo.cb_HTAlter c WITH(NOLOCK) ON c.HTAlterGUID=f.RefGUID AND c.isUseYgAmount=1
	WHERE  f.IsApprove = 1 
	AND ISNULL(f.IsFromXyl,0)=0
            AND ( p.ProjGUID in ( SELECT [Value] FROM dbo.fn_Split1(@var_projguid, ',') ) or @var_projguid is null )
            AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
	GROUP  BY b.ExecutingBudgetGUID

    --已结算合同-已定合同
	SELECT
	d.ExecutingBudgetGUID,
        SUM(c.JsAmount) AS JsAmount
	INTO  #JS
	FROM dbo.cb_HTBalance a WITH(NOLOCK)
	INNER JOIN cb_HTAlter b WITH(NOLOCK) ON a.HTBalanceGUID=b.RefGUID
	INNER JOIN dbo.cb_BudgetUse c WITH(NOLOCK) ON c.RefGUID=b.HTAlterGUID
	INNER JOIN dbo.cb_Budget d WITH(NOLOCK) ON d.BudgetGUID = c.BudgetGUID 
	INNER JOIN dbo.p_Project p WITH(NOLOCK) ON c.ProjectCode=p.ProjCode
	WHERE c.IsApprove=1  	
            AND ( p.ProjGUID in ( SELECT [Value] FROM dbo.fn_Split1(@var_projguid, ',') ) or @var_projguid is null )
            AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
	GROUP BY d.ExecutingBudgetGUID

--非现金变更
	SELECT
	d.ExecutingBudgetGUID,
    SUM(c.CfAmount) AS fxjAmount
	INTO  #FXJ
	FROM cb_HTAlter b WITH(NOLOCK)
	INNER JOIN dbo.cb_BudgetUse c WITH(NOLOCK) ON c.RefGUID=b.HTAlterGUID
	INNER JOIN dbo.cb_Budget d WITH(NOLOCK) ON d.BudgetGUID = c.BudgetGUID 
	INNER JOIN dbo.p_Project p WITH(NOLOCK) ON c.ProjectCode=p.ProjCode
	WHERE c.IsApprove=1  AND b.IsFromXyl=1
            AND ( p.ProjGUID in ( SELECT [Value] FROM dbo.fn_Split1(@var_projguid, ',') ) or @var_projguid is null )
            AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
	GROUP BY d.ExecutingBudgetGUID

-- 查询考核版目标成本版本
-- WITH target_versions AS (
    -- 获取考核版目标成本的各版本信息
    SELECT 
        ex.buguid,
        ex.projguid,
        ex.targetcost,
        ex.targetstage2projectguid,
        trg2p.TargetStageVersion,
        trg2p.approvedate,
        -- 按审核日期倒序排序
        ROW_NUMBER() OVER (PARTITION BY ex.projguid ORDER BY trg2p.approvedate DESC) AS rn,
        -- 版本优先级:定位版>立项版>其他
        CASE 
            WHEN trg2p.TargetStageVersion = '定位版' AND trg2p.approvestate = '已审核' THEN 1
            WHEN trg2p.TargetStageVersion = '立项版' AND trg2p.approvestate = '已审核' THEN 2 
            ELSE 3
        END AS version_priority
    into  #target_versions
    FROM (
        -- 汇总考核版目标成本
        SELECT  
            p.buguid,
            cbexam.projguid,
            trg2cost.targetstage2projectguid,
            SUM(cbexam.targetcost) AS targetcost
        FROM cb_TargetExamineCost cbexam WITH(NOLOCK)
        INNER JOIN p_project p WITH(NOLOCK) ON p.projguid = cbexam.projguid
        INNER JOIN cb_TargetStage2Cost trg2cost  WITH(NOLOCK) ON trg2cost.costguid = cbexam.costguid  AND trg2cost.projguid = cbexam.projguid
        WHERE cbexam.costcode NOT LIKE '5001.01.%' 
            AND cbexam.costcode NOT LIKE '5001.09.%'
            AND cbexam.costcode NOT LIKE '5001.10.%' 
            AND cbexam.costcode NOT LIKE '5001.11%' 
            AND cbexam.ifendcost = 1
        GROUP BY p.buguid,cbexam.projguid, trg2cost.targetstage2projectguid
    ) ex
    INNER JOIN cb_TargetCostRevise_KH trg2p WITH(NOLOCK) ON trg2p.projguid = ex.projguid  -- AND ex.targetstage2projectguid = trg2p.targetstage2projectguid
    WHERE 1=1 AND ( ex.projguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_projguid, ',') ) or @var_projguid is null )
            AND ex.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 


-- 查询执行版目标成本
-- execute_versions AS (
    SELECT 
        ex.buguid,
        ex.projguid,
        ex.targetcost,
        ex.dtcostNotFxj,
        ex.targetstage2projectguid,
        trg2p.TargetStageVersion,
        trg2p.approvedate,
        -- 按审核日期倒序排序
        ROW_NUMBER() OVER (PARTITION BY ex.projguid ORDER BY trg2p.approvedate DESC) AS rn
    into  #execute_versions
    FROM (
        -- 汇总执行版目标成本
        SELECT  
            cost.buguid,
            trg2cost.ProjGUID,
            trg2cost.targetstage2projectguid,
            SUM(cost.targetcost) AS targetcost,
            sum( ISNULL(cost.YfsCost, 0) + ISNULL(cost.DfsCost, 0) - ISNULL(cost.FxjCost, 0) ) AS  dtcostNotFxj --'动态成本_含税_不含非现金'
        FROM cb_cost cost WITH(NOLOCK)
        INNER JOIN cb_TargetStage2Cost trg2cost WITH(NOLOCK)
            ON trg2cost.costguid = cost.costguid 
            AND trg2cost.ProjCode = cost.ProjectCode
        WHERE cost.costcode NOT LIKE '5001.01.%' 
            AND cost.costcode NOT LIKE '5001.09.%'
            AND cost.costcode NOT LIKE '5001.10.%' 
            AND cost.costcode NOT LIKE '5001.11%' 
            AND cost.ifendcost = 1
        GROUP BY cost.buguid, trg2cost.projguid, trg2cost.targetstage2projectguid
    ) ex
    INNER JOIN cb_TargetCostRevise_KH trg2p  WITH(NOLOCK) ON trg2p.projguid = ex.projguid 
       -- AND ex.targetstage2projectguid = trg2p.targetstage2projectguid
    WHERE 1=1  AND ( ex.projguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_projguid, ',') ) or @var_projguid is null )
        AND ex.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 


-- 主查询:各分期成本结构报表
SELECT  
    -- 基本信息
    bu.buguid AS [公司guid],
    bu.buname AS [公司],
    p.projname AS [项目分期名称],
    p.projguid AS [项目guid],
    flg.投管代码 AS [投管代码],
    mp.ProjCode AS [明源系统代码],
    flg.操盘方式 AS [操盘方式],
    flg.获取时间 AS [拿地时间],
    jd.实际开工计划完成时间 AS [计划开工时间],
    jd.实际开工实际完成时间 AS [实际开工时间],
    jd.竣工备案计划完成时间 AS [计划竣备时间],
    jd.竣工备案实际完成时间 AS [实际竣备时间],
    mdproj.SumBuildArea AS [总建筑面积],
    mdproj.JrSaleArea AS [总可售面积],

    -- 总成本情况
    khtarget.TargetStageVersion AS [总成本情况_考核版目标成本版本名称],
    khtarget.targetcost AS [总成本情况_考核版目标成本],
    ex_target.TargetStageVersion AS [总成本情况_当前执行版目标成本版本名称],
    ex_target.targetcost AS [总成本情况_当前执行版目标成本],
    -- ex_target.dtcostNotFxj AS [总成本情况_动态成本],
    htNewBudget.NewBudget AS [总成本情况_动态成本],
    -- ex_target.ylc AS [总成本情况_余量池],
    isnull(ex_target.targetcost,0) -isnull(htNewBudget.NewBudget,0) AS [总成本情况_余量池],

    -- 预留金
    htNewBudget.YljAmount AS [预留金_总预留金],
    htNewBudget.YljAmount_Yfs AS [预留金_已发生预留金],
    htNewBudget.dfsljAmount AS [预留金_待发生预留金],

    -- 产值及支付   
    htXmpdljwccz.Xmpdljwccz AS [产值及支付_已完成产值],
    htXmpdljwccz.Ljsfk AS [产值及支付_已付款],

    -- 合同签订情况
    htNewBudget.HtCfAmountCount AS [合同签订情况_已签合同数],
    htNewBudget.HtCfAmount AS [合同签订情况_已签合同金额],
    htNewBudget.HtCfAmountWJs AS [合同签订情况_未结算的已签合同金额],
    htNewBudget.NotBudgetAmountCount  AS [合同签订情况_未签合同数],
    htNewBudget.NotBudgetAmount AS [合同签订情况_未签合同金额],

    -- 结算
    htNewBudget.JsHtCfAmountCount AS [结算_合同数],
    htNewBudget.JsHtCfAmount AS [结算_首次签约金额],
    htNewBudget.JsAmount AS [结算_结算金额],
    htNewBudget.JshtNewBudget AS [结算_已结算最新合约规划金额],

    -- 总价合同（首次签约为总价包干）   
    htNewBudget.zjHtNewBudget AS [总价合同_首次签约为总价包干_最新合约规划金额],
    htNewBudget.zjHtCfAmountCount  AS [总价合同_首次签约为总价包干_合同数],
    htNewBudget.zjHtCfAmount AS [总价合同_首次签约为总价包干_首次签约金额],
    htNewBudget.zjHtCfAmountWJs AS [总价合同_首次签约为总价包干_未结算的已签合同金额],
    htNewBudget.zjFsBxAmount AS [总价合同_首次签约为总价包干_负数补协_不含暂转固],
    htNewBudget.zjYljAmount AS [总价合同_首次签约为总价包干_总预留金],
    htNewBudget.zjYljAmount_Yfs AS [总价合同_首次签约为总价包干_预留金已发生],
    htNewBudget.zjdfsljAmount AS [总价合同_首次签约为总价包干_预留金待发生],

    -- 总价合同（首次签约为单价合同，目前已转总）
    htNewBudget.yzzjNewBudget AS [总价合同_首次签约为单价合同_目前已转总_最新合约规划金额],
    htNewBudget.yzzjHtCfAmountCount AS [总价合同_首次签约为单价合同_目前已转总_合同数],
    htNewBudget.yzzjHtCfAmount AS [总价合同_首次签约为单价合同_目前已转总_首次签约金额],
    htNewBudget.yzzjHtCfAmountWJs AS [总价合同_首次签约为单价合同_目前已转总_未结算的已签合同金额],
    htNewBudget.zjZzgAmount AS [总价合同_首次签约为单价合同_目前已转总_暂转固金额],
    htNewBudget.yzzjFsBxAmount AS [总价合同_首次签约为单价合同_目前已转总_负数补协_不含暂转固],
    htNewBudget.yzzjYljAmount AS [总价合同_首次签约为单价合同_目前已转总_总预留金],
    htNewBudget.yzzjYljAmount_Yfs AS [总价合同_首次签约为单价合同_目前已转总_预留金已发生],
    htNewBudget.yzzjdfsljAmount AS [总价合同_首次签约为单价合同_目前已转总_预留金待发生],

    -- 单价合同（首次签约为单价合同且未完成转总）
    htNewBudget.djHtNewBudget AS [单价合同_首次签约为单价合同且未完成转总_最新合约规划金额],
    htNewBudget.djHtCfAmountCount AS [单价合同_首次签约为单价合同且未完成转总_合同数],
    htNewBudget.djHtCfAmount AS [单价合同_首次签约为单价合同且未完成转总_首次签约金额],
    htNewBudget.djHtCfAmountWJs AS [单价合同_首次签约为单价合同且未完成转总_未结算的已签合同金额],
    htNewBudget.djFsBxAmount AS [单价合同_首次签约为单价合同且未完成转总_负数补协_不含暂转固],
    htNewBudget.djYljAmount AS [单价合同_首次签约为单价合同且未完成转总_总预留金],
    htNewBudget.djYljAmount_Yfs AS [单价合同_首次签约为单价合同且未完成转总_预留金已发生],
    htNewBudget.djdfsljAmount AS [单价合同_首次签约为单价合同且未完成转总_预留金待发生],

    -- 待签约
    htNewBudget.NewBudgetAmountCount AS [待签约_合同数],
    htNewBudget.NewBudgetAmount AS [待签约_合约规划金额],
    htNewBudget.wqydfsljAmount AS [待签约_待发生预留金],
    htNewBudget.FxjAmount AS [非现金],
    -- 新增字段
    htNewBudget.YljAmount_Yfs_Js AS [预留金_已发生预留金(已结算)],
    htNewBudget.YljAmount_Yfs_WJs AS [预留金_已发生预留金(未结算)],

	--20250723 add by tangqn01    
	htNewBudget.CurYearHtCount as 本年新签合同份数,
	htNewBudget.CurYearHtCfAmount as 本年新签合同金额,
	htNewBudget.CurYearzbjyAmount as 本年招标结余金额,
	htNewBudget.CurYeardjHtCfAmount as 本年单价包干合同金额,
	qzbg.签证变更金额 as 签证变更金额,
	pay.PayAmount as 进度款支付金额,
    pay.CurYearPayAmount as 本年实付金额,
	CASE WHEN tghj.ProjGUID IS NOT NULL THEN '1' ELSE '0' END AS 停工缓建标识,
	CASE WHEN tghj.ProjGUID IS NOT NULL THEN htNewBudget.tghjHyghCount END AS 停工缓建合约规划数量,
    CASE WHEN tghj.ProjGUID IS NOT NULL THEN htNewBudget.tghjHyghAmount END AS 停工缓建合约规划金额,

	--结算
    ISNULL(js.本月完成合同结算份数,0) AS 本月完成合同结算份数,
    ISNULL(js.本月完成合同结算金额,0) AS 本月完成合同结算金额,
    ISNULL(js.本月完成合同结算送审金额,0) AS 本月完成合同结算送审金额,
    ISNULL(js.本月完成合同结算一审金额,0) AS 本月完成合同结算一审金额,
    CASE WHEN ISNULL(js.本月完成合同结算送审金额,0) = 0 THEN 0 ELSE (ISNULL(js.本月完成合同结算送审金额,0) - ISNULL(js.本月完成合同结算一审金额,0))/ISNULL(js.本月完成合同结算送审金额,0) END AS 本月完成合同结算一核核减率,
    ISNULL(js.本月完成合同结算二审金额,0) AS 本月完成合同结算二审金额,
    CASE WHEN ISNULL(js.本月完成合同结算需二审的一审金额,0) = 0 THEN 0 ELSE (ISNULL(js.本月完成合同结算需二审的一审金额,0) - ISNULL(js.本月完成合同结算二审金额,0))/ISNULL(js.本月完成合同结算需二审的一审金额,0) END AS 本月完成合同结算二核核减率,
    CASE WHEN ISNULL(js.本月完成合同结算份数,0) = 0 THEN 0 ELSE ISNULL(js.本月完成合同结算审批时长,0)/ISNULL(js.本月完成合同结算份数,0) END AS 本月完成合同结算审批时长,
    -- AS 在途合同结算一审审核中份数,
    ISNULL(js.在途合同结算二审审核中份数,0) AS 在途合同结算二审审核中份数,

	--20250731 add by tangqn01
	CurYearHt.ContractNum as 本年新签合同份数_全量,
	CurYearHt.HtAmount as 本年新签合同金额_全量,

	--20250801 add 本月完成合同结算需二审的一审金额
	js.本月完成合同结算需二审的一审金额 as 本月完成合同结算需二审的一审金额,
	js.本年完成合同结算金额 as 本年完成合同结算金额

FROM p_project p WITH(NOLOCK) 
INNER JOIN mybusinessunit bu WITH(NOLOCK)   ON bu.buguid = p.buguid 
INNER JOIN ERP25.dbo.mdm_project mp WITH(NOLOCK)  ON mp.projguid = p.ProjGUID
LEFT JOIN erp25.dbo.vmdm_projectFlag flg WITH(NOLOCK)   ON flg.projguid = mp.ParentProjGUID
-- 基础数据系统
LEFT JOIN (
    SELECT 
        ProjGUID,
        ParentProjGUID,
        ProjName,
        ProjCode,
        AcquisitionDate,
        SumUpArea,
        SumDownArea, 
        SumBuildArea,
        SumJrArea,
        JrSaleArea, -- 计容可售面积
        SumSaleArea
    FROM (
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) AS rowmo,
            *
        FROM dbo.md_Project WITH(NOLOCK)
        WHERE ApproveState = '已审核'
            AND Level = 3
            AND ISNULL(CreateReason, '') <> '补录'
    ) x
    WHERE x.rowmo = 1
) mdproj  ON mdproj.ProjGUID = p.ProjGUID
-- 组团计划
LEFT JOIN (
    SELECT 
        jd_PlanTaskExecuteObjectForReport.projguid,gc.isCompare,
        MAX(实际开工计划完成时间) AS 实际开工计划完成时间,
        MAX(实际开工实际完成时间) AS 实际开工实际完成时间,
        MAX(竣工备案计划完成时间) AS 竣工备案计划完成时间,
        MAX(case when gc.isCompare = '是' then 竣工备案实际完成时间 else null end ) AS 竣工备案实际完成时间
    FROM jd_PlanTaskExecuteObjectForReport WITH(NOLOCK)
    LEFT JOIN (
        SELECT projguid,
            NodeNum,
            TaskStateNum,
            CASE 
                WHEN ISNULL(NodeNum,0) = ISNULL(TaskStateNum,0) THEN '是' 
                ELSE '否' 
            END AS isCompare
        FROM (
            SELECT jpe.projguid,
                COUNT(1) AS NodeNum,
                SUM(CASE 
                    WHEN enumTask.EnumerationName IN ('按期完成','延期完成') THEN 1 
                    ELSE 0 
                END) AS TaskStateNum
            FROM jd_ProjectPlanTaskExecute jpte
            left JOIN jd_EnumerationDictionary enumTask   ON enumTask.EnumerationType = '工作状态枚举' AND enumTask.EnumerationValue = jpte.TaskState
            inner  join jd_ProjectPlanExecute jpe on jpe.ID =jpte.PlanID
            where    jpte.TaskName like '%竣工备案%'
            GROUP BY jpe.projguid
        ) jppt 
    ) gc ON gc.projguid = jd_PlanTaskExecuteObjectForReport.ProjGUID
    -- WHERE 定位报告计划完成时间 IS NOT NULL
    GROUP BY jd_PlanTaskExecuteObjectForReport.projguid,gc.isCompare
) jd  ON jd.projguid = p.ProjGUID
-- 考核版-目标成本
LEFT JOIN (
    -- 取最新已审核的定位版的版本名称，如果没有定位则取立项版，如果都不存在则取考核版最新版本名称
    SELECT 
        t1.projguid,
        t1.targetcost,                    -- 考核版目标成本含税
        t1.targetstage2projectguid,       -- 考核版目标成本业务版本guid   
        t1.TargetStageVersion,            -- 考核版目标成本业务版本
        t1.approvedate                    -- 考核版目标成本业务版本审核日期
    FROM #target_versions t1
    INNER JOIN (
        SELECT 
            projguid,
            MIN(version_priority) AS min_priority
        FROM #target_versions 
        WHERE rn = 1
        GROUP BY projguid
    ) t2 
        ON t1.projguid = t2.projguid 
        AND t1.version_priority = t2.min_priority 
        AND t1.rn = 1
) khtarget  ON khtarget.projguid = p.ProjGUID    
-- 执行版 - 目标成本
LEFT JOIN (
    SELECT  
        projguid,
        targetcost,  --目标成本
        dtcostNotFxj, -- 动态成本不含非现金
        isnull(targetcost,0) - isnull(dtcostNotFxj,0) as ylc, --余量池 取含税的执行版目标成本-动态成本（不含非现金）（除地价外直投）
        targetstage2projectguid,
        TargetStageVersion,
        approvedate
    FROM #execute_versions
    WHERE rn = 1
) ex_target  ON ex_target.projguid = p.ProjGUID
-- 预留金/未签合同/已签合同/变更(非现金)
left join (
        SELECT 
            a.ProjectGUID,
            sum(CASE WHEN ht.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0) +ISNULL(ylj.YgYeAmount,0) ELSE ex.BudgetAmount END)  AS  NewBudget, -- 最近合约规划金额
            sum(CASE WHEN ht.ExecutingBudgetGUID IS  NULL THEN  ex.BudgetAmount  END  ) AS  NotBudgetAmount,  -- 未签合同金额
            --sum( case when ht.ExecutingBudgetGUID is null then 1 else 0 end ) AS  NotBudgetAmountCount,  -- 未签合同份数
            count(ex.ExecutingBudgetGUID) - count(DISTINCT ht.ExecutingBudgetGUID ) as NotBudgetAmountCount ,  -- 未签合同份数
            sum(ISNULL(ht.HtCfAmount,0)) AS HtCfAmount, -- 合同首次签约金额 已签合同金额
            sum(case when ht.jsState not in ('结算','结算中') then ISNULL(ht.HtCfAmount,0) else 0 end ) as HtCfAmountWJs, --未结算的已签合同金额
            count(DISTINCT ht.ExecutingBudgetGUID ) AS HtCfAmountCount, -- 合同首次签约金额 已签合同数量

            sum( case when ht.jsState in ('结算','结算中') then CASE WHEN ht.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0) +ISNULL(ylj.YgYeAmount,0) ELSE ex.BudgetAmount END else 0 end )  as JshtNewBudget, -- 已结算最新合约规划金额
            sum( case when ht.jsState  in ('结算','结算中')  then ISNULL(yfs.ylj_yfs,0) else ISNULL(ht.YgAlterAmount,0) +ISNULL(ylj.ygAlterAdj,0) end ) AS  YljAmount , -- 总预留金
            sum(ISNULL(yfs.ylj_yfs,0) ) AS  YljAmount_Yfs,-- 已发生预留金
            sum(case when ht.jsState in ('结算','结算中') then ISNULL(yfs.ylj_yfs,0) else 0 end ) AS  YljAmount_Yfs_Js,-- 已发生预留金(已结算)
            sum(case when ht.jsState not in ('结算','结算中') then ISNULL(yfs.ylj_yfs,0) else 0 end ) AS  YljAmount_Yfs_WJs,-- 已发生预留金(未结算)
            -- 结算和结算中的待发生预留金都计算为0
            sum( case when ht.jsState in  ('结算','结算中') then 0 else ISNULL(ht.YgAlterAmount,0) +ISNULL(ylj.ygAlterAdj,0) - ISNULL(yfs.ylj_yfs,0) end )  AS  dfsljAmount,  -- 待发生预留金

            sum(fxj.FxjAmount) as FxjAmount, -- 变更(非现金)
            -- 结算统计
            sum( CASE WHEN  (ht.HtClass='已定非合同' AND  ht.JsState in ('结算','结算中') ) 
                THEN ht.HtCfAmount ELSE(  CASE WHEN js.ExecutingBudgetGUID IS NOT NULL   
                THEN ISNULL(js.JsAmount,0) - ISNULL(fxj.fxjAmount,0) 
            ELSE ISNULL(js.JsAmount,0) END) END) AS JsAmount, --结算金额
            sum(case when  ht.JsState in ('结算','结算中') then  ISNULL(ht.HtCfAmount,0) else  0 end  ) as  JsHtCfAmount, --结算对应合同的首次签约金额
            count( case when  ht.JsState  in ('结算','结算中')  then  ht.ContractGUID end  ) as  JsHtCfAmountCount,        -- 已结算的合同份数

            -- 总价合同 首次签约为总价包干合同
            sum( case when ht.是否首次总价合同 =1 and  ht.JsState not in ('结算','结算中') then  
                  CASE WHEN ht.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0) +ISNULL(ylj.YgYeAmount,0) ELSE ex.BudgetAmount END else 0 end ) as zjHtNewBudget, -- 总价合同首次签约为总价包干最新合约规划金额
            count( DISTINCT case when ht.是否首次总价合同 =1 and  ht.JsState not in ('结算','结算中')  then  ht.ExecutingBudgetGUID end  ) as  zjHtCfAmountCount, -- 总价合同份数
            sum(case when  ht.JsState not in ( '结算','结算中') then isnull(ht.zjHtCfAmount,0) else  0  end ) as zjHtCfAmount, -- 总价合同首次签约金额
            sum(case when  ht.jsState  not in ('结算','结算中')  then  ISNULL(ht.zjHtCfAmount,0) else 0 end ) as zjHtCfAmountWJs, -- 未结算的已转总价合同金额
            sum(case when ht.是否首次总价合同 =1 and   ht.JsState not in ('结算','结算中') then  fs.FsBxAmount else 0 end ) as zjFsBxAmount, -- 负数补协金额
            
            -- 判断如果合同已结算，则将预留金总额=【预留金已发生】，然后将预留金余额取为0   
            sum(case  when  ht.是否首次总价合同 =1  and ht.jsState not in ('结算','结算中')  then 
                    ISNULL(ht.YgAlterAmount,0) +ISNULL(ylj.ygAlterAdj,0) else 0 end )  AS  zjYljAmount , -- 总预留金
            sum(case when ht.是否首次总价合同 =1 and  ht.JsState not in ('结算','结算中') then  ISNULL(yfs.ylj_yfs,0) else 0 end ) AS  zjYljAmount_Yfs,-- 已发生预留金
            -- 总预留金 - 已发生预留金
            sum(case  when  ht.是否首次总价合同 =1  and ht.jsState not in ('结算','结算中')  then 
                    ISNULL(ht.YgAlterAmount,0) +ISNULL(ylj.ygAlterAdj,0) else 0 end ) 
            - sum(case when ht.是否首次总价合同 =1 and  ht.JsState not in ('结算','结算中') then  ISNULL(yfs.ylj_yfs,0) else 0 end ) AS  zjdfsljAmount,  -- 待发生预留金

            -- 总价合同 首次签约为单价合同，目前已转总价
            sum( case when ht.是否已转总价合同 =1 and  ht.JsState not in ('结算','结算中') then 
               CASE WHEN ht.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0) +ISNULL(ylj.YgYeAmount,0) ELSE ex.BudgetAmount END else 0 end ) as yzzjNewBudget, -- 总价合同首次签约为单价合同，目前已转总价最新合约规划金额
            count( DISTINCT case when ht.是否已转总价合同 =1  and  ht.JsState not  in ('结算','结算中') then  ht.ExecutingBudgetGUID end  ) as  yzzjHtCfAmountCount, -- 已转总价合同份数
            sum(case when  ht.JsState not  in ('结算','结算中') then  isnull(ht.yzzjHtCfAmount,0) else  0 end ) as yzzjHtCfAmount, -- 已转总价合同金额
            sum(case when  ht.jsState not  in ('结算','结算中') then  ISNULL(ht.yzzjHtCfAmount,0) else 0 end ) as yzzjHtCfAmountWJs, -- 未结算的已转总价合同金额
            sum(case when  ht.是否已转总价合同 =1  and ht.JsState not  in ('结算','结算中')  then 
              case when zzg.ZzgAmount is not null then isnull(ht.HtCfAmount,0) + isnull(zzg.ZzgAmount,0) else 0 end  else 0 end) as zjZzgAmount, -- 暂转固金额
            sum(case when  ht.是否已转总价合同 =1  and ht.JsState not  in ('结算','结算中')  then  fs.fsBxAmount else 0 end ) as yzzjFsBxAmount, -- 负数补协金额 
            -- 判断如果合同已结算，则将预留金总额=【预留金已发生】，然后将预留金余额取为0   
            sum( case when  ht.是否已转总价合同 =1  and  ht.JsState not in  ('结算','结算中')  then  
                            ISNULL(ht.YgAlterAmount,0) + ISNULL(ylj.ygAlterAdj,0) else 0 end ) AS  yzzjYljAmount , -- 总预留金
            sum(case when ht.是否已转总价合同 =1 and   ht.JsState  not in  ('结算','结算中') then  ISNULL(yfs.ylj_yfs,0) else 0 end ) AS  yzzjYljAmount_Yfs,-- 已发生预留金
              --总预留金- 已发生预留金            
            sum( case when  ht.是否已转总价合同 =1  and  ht.JsState not in  ('结算','结算中')  then  
                            ISNULL(ht.YgAlterAmount,0) + ISNULL(ylj.ygAlterAdj,0) else 0 end )
            -  sum(case when ht.是否已转总价合同 =1 and   ht.JsState  not in  ('结算','结算中') then  ISNULL(yfs.ylj_yfs,0) else 0 end ) AS  yzzjdfsljAmount,  -- 待发生预留金 
            -- 单价合同
            sum( case when isnull(ht.bgxs,'')<>'总价包干' and   ht.JsState  not  in ('结算','结算中') then  
                CASE WHEN ht.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0) +ISNULL(ylj.YgYeAmount,0) ELSE ex.BudgetAmount END else 0 end ) as djHtNewBudget, -- 单价合同最新合约规划金额
            count( DISTINCT case when isnull(ht.bgxs,'')<>'总价包干' and   ht.JsState not  in ('结算','结算中') then  ht.ExecutingBudgetGUID end  ) as  djHtCfAmountCount, -- 单价合同份数
            sum(case when  ht.JsState not  in ('结算','结算中')  then   isnull(ht.djHtCfAmount,0) else  0  end ) as djHtCfAmount, -- 单价合同金额 
            sum(case when  ht.jsState not  in ('结算','结算中')   then  ISNULL(ht.djHtCfAmount,0) else 0 end ) as djHtCfAmountWJs, -- 未结算的单价合同金额
            sum(case when  isnull(ht.bgxs,'')<>'总价包干' and   ht.JsState not  in ('结算','结算中') then  fs.FsBxAmount else 0 end ) as djFsBxAmount, -- 负数补协金额

            -- 判断如果合同已结算，则将预留金总额=【预留金已发生】，然后将预留金余额取为0   
            sum(case when  isnull(ht.bgxs,'')<>'总价包干'  and ht.jsState not in ('结算','结算中')  then   
                    ISNULL(ht.YgAlterAmount,0) +ISNULL(ylj.ygAlterAdj,0) else 0 end ) AS  djYljAmount , -- 总预留金
            sum(case when  isnull(ht.bgxs,'')<>'总价包干' and  ht.JsState not in ('结算','结算中') then  ISNULL(yfs.ylj_yfs,0) else 0 end ) AS  djYljAmount_Yfs,-- 已发生预留金
            --总预留金 - 已发生预留金
            sum(case when  isnull(ht.bgxs,'')<>'总价包干'  and ht.jsState not in ('结算','结算中')  then   
                    ISNULL(ht.YgAlterAmount,0) +ISNULL(ylj.ygAlterAdj,0) else 0 end ) 
            - sum(case when  isnull(ht.bgxs,'')<>'总价包干' and  ht.JsState not in ('结算','结算中') then  ISNULL(yfs.ylj_yfs,0) else 0 end )  AS  djdfsljAmount, -- 待发生预留金
            -- 待签约
            count(ex.ExecutingBudgetGUID) - count(DISTINCT ht.ExecutingBudgetGUID )  as  NewBudgetAmountCount,
            sum( case when ht.ExecutingBudgetGUID is null then ISNULL(ht.YgAlterAmount,0) +ISNULL(ylj.ygAlterAdj,0) - ISNULL(yfs.ylj_yfs,0) else 0 end ) as  wqydfsljAmount, -- 未签约_待发生预留金
            sum( CASE WHEN ht.ExecutingBudgetGUID IS NULL THEN ex.BudgetAmount else  0 END) AS  NewBudgetAmount,

			--本年新签合同份数/本年新签合同金额/本年招标结余金额
			sum(case when year(ht.SignDate) = year(getdate()) then isnull(ht.HtCfAmount,0) end) AS CurYearHtCfAmount,
            count(DISTINCT case when year(ht.SignDate) = year(getdate()) then ht.ExecutingBudgetGUID end) AS CurYearHtCount,
			SUM(case when year(ht.SignDate) = year(getdate()) 
                        --剔除补录合同
                        and ht.ContractGUID not in ('2E5B0584-B0AA-4B45-AE0F-8B46B389FF80',
                                                    '13387399-E456-4EED-8EF6-8DE606A08FEF',
                                                    'E44D5B0F-4A11-4D63-B500-F7FB4A0772A6',
                                                    '07E34053-0343-4703-92F1-9E48F7F422A4',
                                                    '10D1DA81-EA79-4FED-84B6-49C68B3FDBFE',
                                                    '0CFC0290-0558-464D-90B0-0F00062208E4',
                                                    '1DC5BEFA-EA69-4D50-9115-FEECEE6B1C0B',
                                                    '6F0A46C3-E643-466E-90D8-45500A266F35',
                                                    'BE6377B6-37AA-4C25-AF40-5DAB88E0594F')
                then isnull(ht.zbjyAmount,0) end) AS CurYearzbjyAmount,
			sum(case when year(ht.SignDate) = year(getdate()) then isnull(ht.djHtCfAmount,0) end) AS CurYeardjHtCfAmount,

			 --停工缓建的分期，对应合约规划数量和金额（不去重），剔除已结算的合同
            count(case when isnull(ht.jsState,'') not in ('结算','结算中') then a.WorkingBudgetGUID end) AS tghjHyghCount,
            sum(case when isnull(ht.jsState,'') not in ('结算','结算中') then ex.BudgetAmount else 0 end) AS tghjHyghAmount
        FROM dbo.cb_Budget_Working a WITH(NOLOCK)
        inner JOIN dbo.cb_Budget_Executing ex WITH(NOLOCK) ON ex.ExecutingBudgetGUID=a.WorkingBudgetGUID
        LEFT JOIN dbo.cb_HtType b WITH(NOLOCK) ON a.BigHTTypeGUID = b.HtTypeGUID
        LEFT JOIN #HT ht WITH(NOLOCK) ON ht.ExecutingBudgetGUID = a.WorkingBudgetGUID
        LEFT JOIN #ZZG zzg WITH(NOLOCK) ON zzg.ExecutingBudgetGUID = a.WorkingBudgetGUID
        LEFT JOIN #yfs yfs WITH(NOLOCK) ON yfs.ExecutingBudgetGUID = a.WorkingBudgetGUID
        LEFT JOIN #ylj ylj WITH(NOLOCK) ON ylj.ExecutingBudgetGUID = a.WorkingBudgetGUID
        LEFT JOIN #Fxj fxj WITH(NOLOCK) ON fxj.ExecutingBudgetGUID=a.WorkingBudgetGUID
        LEFT JOIN #fsBx fs WITH(NOLOCK) ON fs.ExecutingBudgetGUID=a.WorkingBudgetGUID
        LEFT JOIN #JS js WITH(NOLOCK) ON js.ExecutingBudgetGUID=a.WorkingBudgetGUID
        WHERE b.HtTypeName not in ('土地类','管理费','营销费','财务费')  -- and a.ProjectGUID = '2b3b0206-f785-e911-80b7-0a94ef7517dd' --@ProjGUID
        GROUP BY a.ProjectGUID
) htNewBudget ON htNewBudget.ProjectGUID = p.ProjGUID
--签证变更金额
LEFT JOIN (
    select 
        p.ProjGUID,
        SUM(case when a.QrStatus ='已完工' then a.QrAlterAmount else a.AlterAmount end) as 签证变更金额
    from MyCost_Erp352.dbo.vcb_HtAlter a
    INNER JOIN MyCost_Erp352.dbo.cb_contract c ON a.ContractGUID = c.ContractGUID
    LEFT JOIN p_Project p ON p.ProjCode = CASE WHEN LEN(c.ProjectCodeList) > 1 AND CHARINDEX(';', c.ProjectCodeList) < 1 THEN c.ProjectCodeList
                                                WHEN LEN(c.ProjectCodeList) > 1 AND CHARINDEX(';', c.ProjectCodeList) >= 1 THEN LEFT(ProjectCodeList, CHARINDEX(';', c.ProjectCodeList) - 1)
                                                ELSE NULL END
    where a.ApproveState = '已审核'
        AND (
                c.HtTypeCode LIKE '04%'
                OR c.HtTypeCode LIKE '02%'
                OR c.HtTypeCode LIKE '06%'
                OR c.HtTypeCode LIKE '03%'
                OR c.HtTypeCode LIKE '05%'
            )
        AND c.htclass NOT LIKE '%非合同%'
        AND a.ApproveState = '已审核'
        AND a.AlterType IN ( '现场签证', '设计变更' )
		AND case when a.QrStatus ='已完工' then a.QrAlterAmount else a.AlterAmount end >-2000000
    GROUP BY p.ProjGUID
) qzbg on qzbg.projguid = p.ProjGUID
--实付金额
LEFT JOIN (
    SELECT p.ProjGUID,
        SUM(e.PayAmount) AS PayAmount,
        SUM(case when year(e.PayDate) = year(getdate()) then e.PayAmount else 0 end) as CurYearPayAmount
    FROM MyCost_Erp352.dbo.cb_htfkapply a
    LEFT JOIN MyCost_Erp352.dbo.cb_pay e ON e.htfkapplyGUID = a.htfkapplyGUID
    INNER JOIN MyCost_Erp352.dbo.cb_contract c ON a.ContractGUID = c.ContractGUID
    LEFT JOIN MyCost_Erp352.dbo.p_Project p ON p.ProjCode = CASE WHEN LEN(c.ProjectCodeList) > 1 AND CHARINDEX(';', c.ProjectCodeList) < 1 THEN c.ProjectCodeList
                                                WHEN LEN(c.ProjectCodeList) > 1 AND CHARINDEX(';', c.ProjectCodeList) >= 1 THEN LEFT(ProjectCodeList, CHARINDEX(';', c.ProjectCodeList) - 1)
                                                ELSE NULL END
    WHERE a.ApplyState = '已审核'
        AND (
                c.HtTypeCode LIKE '04%'
                OR c.HtTypeCode LIKE '02%'
                OR c.HtTypeCode LIKE '06%'
                OR c.HtTypeCode LIKE '03%'
                OR c.HtTypeCode LIKE '05%'
            )
       -- AND c.htclass NOT LIKE '%非合同%'
    group by p.ProjGUID
) pay on pay.projguid = p.ProjGUID
--停工缓建标识
LEFT JOIN (
		SELECT a.ProjGUID
        FROM
        (
            SELECT d.BldGUID,
                   ROW_NUMBER() OVER (PARTITION BY d.BldGUID ORDER BY a.ApplicationTime DESC) AS RowID,
                   a.Type,
                   d.SumBuildArea,
                   d.ProjGUID
            FROM jd_StopOrReturnWork a
            INNER JOIN jd_ProjectPlanCompile b ON a.PlanID = b.ID
            INNER JOIN p_BiddingBuilding2Building c ON c.BudGUID = b.ObjectID
            INNER JOIN md_GCbuild d ON d.BldGUID = c.BuildingGUID AND d.IsActive = 1
            WHERE  a.ApplyState = '已审核' 
        ) a
        WHERE a.Type IN ( '停工', '缓建' )
              AND a.RowID = 1
		group by a.ProjGUID
) tghj on tghj.ProjGUID = p.ProjGUID
--结算
LEFT JOIN (
    SELECT 
        p.ProjGUID,
        COUNT(case when YEAR(my.FinishDatetime) = YEAR(GETDATE()) AND MONTH(my.FinishDatetime) = MONTH(GETDATE()) AND htb.ApproveState ='已审核' THEN htb.HTBalanceGUID END) AS 本月完成合同结算份数,
        sum(case when YEAR(my.FinishDatetime) = YEAR(GETDATE()) AND MONTH(my.FinishDatetime) = MONTH(GETDATE()) AND htb.ApproveState ='已审核' THEN htb.BalanceAmount ELSE 0 END) AS 本月完成合同结算金额,
        sum(case when YEAR(my.FinishDatetime) = YEAR(GETDATE()) AND MONTH(my.FinishDatetime) = MONTH(GETDATE()) AND htb.ApproveState ='已审核' THEN htb.SsAmountBz ELSE 0 END) AS 本月完成合同结算送审金额,
        sum(case when YEAR(my.FinishDatetime) = YEAR(GETDATE()) AND MONTH(my.FinishDatetime) = MONTH(GETDATE()) AND htb.ApproveState ='已审核' THEN case when ISNULL(htb.YsAmountBz,0) = 0 then htb.SsAmountBz else htb.YsAmountBz end
		ELSE 0 END) AS 本月完成合同结算一审金额,
        sum(case when YEAR(my.FinishDatetime) = YEAR(GETDATE()) AND MONTH(my.FinishDatetime) = MONTH(GETDATE()) AND htb.ApproveState ='已审核' AND (ISNULL(htb.Sfbxes,'无需二审') IN ('子公司二审','总部二审') OR ISNULL(htb.Sfkdes,'否')<>'是') THEN 
				case when isnull(htb.YsAmountBz,0) = 0 then htb.SsAmountBz else htb.YsAmountBz end 
			ELSE 0 END) AS 本月完成合同结算需二审的一审金额,
        sum(case when YEAR(my.FinishDatetime) = YEAR(GETDATE()) AND MONTH(my.FinishDatetime) = MONTH(GETDATE()) AND htb.ApproveState ='已审核' AND (ISNULL(htb.Sfbxes,'无需二审')IN ('子公司二审','总部二审') OR ISNULL(htb.Sfkdes,'否')<>'是') THEN 
			case when isnull(htb.EsAmountBz,0) = 0 then htb.BalanceAmount else htb.EsAmountBz end 
		ELSE 0 END) AS 本月完成合同结算二审金额,
        SUM(case when YEAR(my.FinishDatetime) = YEAR(GETDATE()) AND MONTH(my.FinishDatetime) = MONTH(GETDATE()) AND htb.ApproveState ='已审核' THEN datediff(dd,my.InitiateDatetime,my.FinishDatetime) END) AS 本月完成合同结算审批时长,
        COUNT(CASE WHEN htb.ApproveState ='审核中' AND (ISNULL(htb.Sfbxes,'无需二审') <>'无需二审' OR ISNULL(htb.Sfkdes,'否')<>'否') THEN htb.HTBalanceGUID END) AS 在途合同结算二审审核中份数,
		--sum(case when YEAR(htb.BalanceDate) = YEAR(GETDATE()) AND htb.ApproveState ='已审核' THEN htb.BalanceAmount ELSE 0 END) AS 本年完成合同结算金额,
		sum(case when YEAR(my.FinishDatetime) = YEAR(GETDATE()) AND htb.ApproveState ='已审核' THEN htb.BalanceAmount ELSE 0 END) AS 本年完成合同结算金额

    FROM cb_HTBalance htb
    INNER JOIN MyCost_Erp352.dbo.cb_contract c ON htb.ContractGUID = c.ContractGUID
    LEFT JOIN p_Project p ON p.ProjCode = CASE WHEN LEN(c.ProjectCodeList) > 1 AND CHARINDEX(';', c.ProjectCodeList) < 1 THEN c.ProjectCodeList
                                                WHEN LEN(c.ProjectCodeList) > 1 AND CHARINDEX(';', c.ProjectCodeList) >= 1 THEN LEFT(ProjectCodeList, CHARINDEX(';', c.ProjectCodeList) - 1)
                                                ELSE NULL END
    LEFT JOIN myWorkflowProcessEntity my ON my.BusinessGUID = htb.HTBalanceGUID AND my.ProcessStatus IN ('0','1','2')
    WHERE htb.ApproveState IN ('已审核', '审核中')
		 AND htb.BalanceType ='结算'
         AND (
                c.HtTypeCode LIKE '04%'
                OR c.HtTypeCode LIKE '02%'
                OR c.HtTypeCode LIKE '06%'
                OR c.HtTypeCode LIKE '03%'
                OR c.HtTypeCode LIKE '05%'
            )
        AND c.htclass NOT LIKE '%非合同%'
		AND c.ContractCode <>'海西公司-晋江中航城-2025-0506'
		AND isnull(htb.YsAmountBz,0) <> 0
		AND ISNULL(htb.SsAmountBz,0)<>0
		AND ISNULL(htb.BalanceAmount,0) <>0
    GROUP BY p.ProjGUID
) js on js.ProjGUID = p.ProjGUID
--本年合同
LEFT JOIN (
	SELECT b.ProjGUID,
          COUNT(a.ContractGUID) AS ContractNum,
		  SUM(a.htamount) as HtAmount
    FROM vcb_Contract a
    INNER JOIN (
		SELECT 
			a.ContractGUID,
			a.ProjGUID,
			row_number() over(partition by a.ContractGUID order by a.ProjGUID asc) as rn
		FROM cb_ContractProj a
		INNER JOIN cb_contract c ON a.ContractGUID = c.ContractGUID
		INNER JOIN p_project p ON a.ProjGUID = p.ProjGUID
		WHERE 1 = 1
			AND c.IsFyControl <> 1
			AND c.ApproveState = '已审核'
			AND c.IfDdhs = 1
			AND c.HtProperty IN ('补充合同','直接合同')
			AND (
                c.HtTypeCode LIKE '04%'
                OR c.HtTypeCode LIKE '02%'
                OR c.HtTypeCode LIKE '06%'
                OR c.HtTypeCode LIKE '03%'
                OR c.HtTypeCode LIKE '05%'
            )
			--AND c.htclass NOT LIKE '%非合同%'
			AND YEAR(c.SignDate)=YEAR(GETDATE())
    ) b ON a.ContractGUID = b.ContractGUID and b.rn = 1
    LEFT JOIN p_Project c ON b.ProjGUID = c.ProjGUID
	WHERE YEAR(a.SignDate)=YEAR(GETDATE())
		AND a.IfDdhs = 1
		AND a.ApproveState = '已审核'
		AND a.IsFyControl <> 1
	GROUP BY b.ProjGUID
) CurYearHt on CurYearHt.ProjGUID = p.ProjGUID
-- 月度产值回顾 取上一个月拍照的已完成产值合计（除地价外直投）
left join (       
    SELECT  outputvalue.projguid,
                sum(ISNULL(outputvalue.Xmpdljwccz, 0)) AS Xmpdljwccz, -- 项目盘点累计完成产值
                sum(isnull(outputvalue.Ljyfkje,0)) as Ljyfkje, --项目盘点累计应付款
                sum(isnull(outputvalue.yfwsAmount,0)) as yfwsAmount, -- 应付未付金额
                sum(ISNULL(outputvalue.Ljsfk, 0)) AS Ljsfk, -- 累计实付款
                sum(isnull(outputvalue.ydczwzfAmount,0)) as ydczwzfAmount -- 已达产值未支付金额
    FROM    (
            SELECT  b.projguid,
                    b.OutputValueMonthReviewGUID,
                    b.ReviewDate,
                    a.BusinessGUID AS ContractGUID,
                    a.BusinessName,
                    a.BusinessType,
                    Xmpdljwccz, -- 项目盘点累计完成产值
                    Ljyfkje, -- 项目盘点累计应付款
                    Ljsfk,-- 累计实付款
                    isnull(Xmpdljwccz,0) - isnull(Ljsfk,0) as ydczwzfAmount, -- 已达产值未支付金额 等于 项目盘点累计完成产值 减去 累计实付款
                    isnull(Ljyfkje,0) - isnull(Ljsfk,0) as yfwsAmount, -- 应付未付金额 等于 项目判断累计应付款 减去 累计实付款
                    ROW_NUMBER() OVER (PARTITION BY a.BusinessGUID ORDER BY ReviewDate DESC) AS rownum
            FROM    cb_OutputValueReviewDetail a WITH(NOLOCK)
                    INNER JOIN cb_OutputValueMonthReview b WITH(NOLOCK) ON a.OutputValueMonthReviewGUID = b.OutputValueMonthReviewGUID
            WHERE   a.BusinessType = '合同' and  datediff(month, b.ReviewDate,getdate()) =1
            ) outputvalue
    WHERE   outputvalue.rownum = 1
    GROUP BY outputvalue.projguid
) htXmpdljwccz ON htXmpdljwccz.projguid = p.ProjGUID
WHERE p.Level = 3  AND  ( p.ProjGUID in (  SELECT [Value] FROM dbo.fn_Split1(@var_projguid, ',')  ) or @var_projguid is null )
            AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
ORDER BY bu.buname, p.projname


--  删除临时表
DROP TABLE IF EXISTS #HT;
DROP TABLE IF EXISTS #ysf;
DROP TABLE IF EXISTS #yfs;
DROP TABLE IF EXISTS #ylj;
DROP TABLE IF EXISTS #JS;
DROP TABLE IF EXISTS #Fxj;
DROP TABLE IF EXISTS #fsBx;
DROP TABLE IF EXISTS #ZZGBG;
DROP TABLE IF EXISTS #ZZG;
DROP TABLE IF EXISTS #target_versions;
DROP TABLE IF EXISTS #execute_versions;

END 



-- 目标成本考核版本记录
-- SELECT 
--     AdjustHistoryGUID,
--     StageType,
--     AdjustName,
--     ApproveDate,
--     Adjuster,
--     ProjGUID,
--     TargetStageVersion,
--     ZbApproveState,
--     ZbApproveDate,
--     ZbApprovePerson,
--     TargetStage2ProjectGUID,
--     '<a herf="#" onclick="parent.parent.OpenProjectInfo('''+ CAST(ProjGUID AS VARCHAR(40))+''','''+ 
--         case when HkbApproveGUID is NULL then '' else CAST(HkbApproveGUID AS VARCHAR(40)) end+''')"><u>' + 
--         ProjectZbVersionName + '</u></a>' AS ProjectZbVersionNameHTML,
--     TargetCost,
--     TargetCostNoTax,
--     ztTargetCost,
--     ztTargetCostNoTax 
-- FROM (
--     select 
--         p.TargetCostReviseKHGUID AS AdjustHistoryGUID,
--         '调整单' AS StageType,
--         p.ReviserName AS AdjustName,
--         p.ApproveDate,
--         p.Reviser AS Adjuster,
--         11 as OrderCode,
--         p.ProjGUID,
--         proj.BUGUID,
--         p.TargetStageVersion,
--         p.ProjectZbVersionName,
--         p.HkbApproveGUID,
--         p.ZbApproveState,
--         p.ZbApproveDate,
--         p.ZbApprovePerson,
--         p.TargetStage2ProjectGUID,
--         kh.TargetCost,
--         kh.TargetCostNoTax,
--         zt.TargetCost AS ztTargetCost,
--         zt.TargetCostNoTax AS ztTargetCostNoTax
--     from cb_TargetCostRevise_KH p
--     LEFT JOIN p_Project proj ON p.ProjGUID = proj.ProjGUID
--     LEFT JOIN cb_TargetStage2Cost_KH kh ON kh.TargetCostReviseKHGUID = p.TargetCostReviseKHGUID 
--         AND kh.CostCode='5001'
--     LEFT JOIN (
--         select 
--             sum(p.targetcost) as targetcost,
--             sum(p.targetcostnotax) as targetcostnotax,
--             p.targetcostrevisekhguid
--         from cb_targetstage2cost_kh p
--         inner join p_project proj on p.projguid = proj.projguid
--         inner join cb_cost b2 on p.costguid = b2.costguid
--         where isnull(b2.costcategory, '') <> '土地成本'
--             and isnull(b2.costkind, '') = '开发成本'
--             and b2.ifendcost = 1
--             and (2=2)
--         group by p.targetcostrevisekhguid
--     ) zt ON zt.TargetCostReviseKHGUID = p.TargetCostReviseKHGUID
--     where p.ApproveState = '已审核'
--         AND (2=2)
-- ) a
-- ORDER BY ApproveDate DESC








