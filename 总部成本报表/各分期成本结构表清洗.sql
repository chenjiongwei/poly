USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_cb_CostStructureReport_Detail]    Script Date: 2025/11/11 11:14:15 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 各分期成本结构穿透明细表
-- exec usp_rpt_cb_CostStructureReport_Detail '264ABDB2-FCA3-E711-80BA-E61F13C57837'
-- 修改：chenjw 2025-09-08 增加“合同大类”和“合同类别”字段

ALTER proc [dbo].[usp_rpt_cb_CostStructureReport_Detail]
(
   -- @var_buguid varchar(max) ,  -- 公司guid
    @var_projguid varchar(max) =null  -- 项目guid
)
as
begin
    --已签约的合同
	SELECT 
        c.ContractGUID
        ,c.ContractCode
        ,c.ContractName
        --,httype.HtTypeGUID
        --,httype.HtTypeName
        ,isnull(lib.BudgetName, hyb.ContractName) as BudgetLibraryName
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
	INTO  #HT
	FROM  dbo.cb_BudgetUse a WITH(NOLOCK)
	INNER JOIN dbo.cb_Budget b WITH(NOLOCK) ON b.BudgetGUID = a.BudgetGUID 
    INNER JOIN cb_Budget_Executing e  WITH(NOLOCK) ON e.ExecutingBudgetGUID=b.ExecutingBudgetGUID
	INNER JOIN cb_Contract c WITH(NOLOCK) ON c.ContractGUID=a.RefGUID
    -- inner join cb_httype  httype on httype.HtTypeCode =c.HtTypeCode  and  httype.buguid =c.buguid
	INNER JOIN dbo.p_Project p WITH(NOLOCK) ON a.ProjectCode=p.ProjCode
    LEFT JOIN dbo.cb_BudgetLibrary lib WITH(NOLOCK) ON c.BudgetLibraryGUID = lib.BudgetLibraryGUID
    outer apply (
       select  top 1 hyb.ContractName 
       from  cb_ProjHyb hyb WITH(NOLOCK) 
       where hyb.ContractBaseGUID =c.BudgetLibraryGUID   and  hyb.projguid =p.projguid
       order by  hyb.ContractName
    ) hyb
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
    --AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
	GROUP BY  c.ContractGUID,c.ContractCode,c.ContractName,isnull(lib.BudgetName, hyb.ContractName),c.bgxs, b.ExecutingBudgetGUID,c.HtClass ,c.JsState,zjcon.是否首次总价合同,zjcon.是否已转总价合同

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
            -- AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
	GROUP BY	b.ExecutingBudgetGUID


    --暂转固 
    -- 判断是否施工图结算为'是' 或 有暂转固单据
	--项目下所有的转固变更
	SELECT DISTINCT  b.ContractGUID,b.HTAlterGUID ,a.ApproveDate
	INTO #ZZGBG
	FROM dbo.cb_Contract a WITH(NOLOCK)
    left join cb_Contract  ca on ca.MasterContractGUID =a.ContractGUID and ca.HtProperty ='补充合同'-- 补充协议
	INNER JOIN dbo.cb_HTAlter b WITH(NOLOCK) ON a.ContractGUID=b.RefGUID or ca.ContractGUID =b.RefGUID
	INNER JOIN dbo.cb_BudgetUse bu WITH(NOLOCK) ON bu.RefGUID=b.HTAlterGUID 
	INNER JOIN dbo.p_Project p WITH(NOLOCK) ON p.ProjCode=bu.ProjectCode
	WHERE  ( p.ProjGUID in ( SELECT [Value] FROM dbo.fn_Split1(@var_projguid, ',') ) or @var_projguid is null )
    --  AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') )  
    and   b.AlterType='附属合同' 
    --AND a.ZzgHTBalanceGUID IS NOT NULL 
    -- 是否施工图结算为'是' 或 有暂转固单据
    -- and  ( ( a.ZzgHTBalanceGUID IS NOT NULL  or isnull(a.IsConstructionBalance,0) =1 )  or (ca.ZzgHTBalanceGUID is not null or isnull(ca.IsConstructionBalance,0) =1 ) )
    and  (ca.ZzgHTBalanceGUID is not null or isnull(ca.IsConstructionBalance,0) =1 ) 

	--获取合同最新的暂转固合约规划金额 
    --用暂转固补充合同的有效签约金额
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
            -- AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
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
            --AND b.BUGUID in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
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
            -- AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
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
            -- AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
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
            -- AND p.buguid in ( SELECT [Value] FROM dbo.fn_Split1(@var_buguid, ',') ) 
	GROUP BY d.ExecutingBudgetGUID

-- 查询预算明细
 SELECT 
            bu.buguid,
            bu.buname as [公司名称],
            a.ProjectGUID,
            p.ProjName as [项目名称],
			a.BudgetName as [合约名称],
            a.WorkingBudgetGUID,
            ht.ExecutingBudgetGUID,
            ht.ContractGUID,
            ht.BudgetLibraryName as [合同类别],
            ht.ContractName as [合同名称],
            -- ht.HtTypeName as [合同类别],
            -- ht.HtTypeGUID as [合同类别GUID],
            b.HtTypeName AS  [合同大类], -- BigHTTypename
			CASE WHEN isnull(a.IsZGGCL, 0) = 1 THEN '是' ELSE '否' END as 是否资管工程类,
            ht.bgxs as [计价方式],
            case when isnull(ht.是否首次总价合同,0)=1 then '是' else '否' end as [是否首次总价合同],
            case when isnull(ht.是否已转总价合同,0)=1 then '是' else '否' end as [是否已转总价合同],
            ht.JsState as [结算状态],
            CASE WHEN ht.ExecutingBudgetGUID IS  NULL THEN  ex.BudgetAmount  END   AS  [未签合同金额],  -- 未签合同金额
            ISNULL(ht.HtCfAmount,0) AS  [合同首次签约金额], -- 合同首次签约金额 已签合同金额
            -- 暂转固金额= 合同有效签约金额 + 补充协议的有效签约金额
            case when  zzg.ZzgAmount is not null  then  ISNULL(ht.HtCfAmount,0)  + isnull(zzg.ZzgAmount,0) else 0 end as [暂转固金额],
            isnull(fs.fsBxAmount,0) as [负数补协金额],
           
            case when  ht.JsState in ('结算','结算中') then   ISNULL(yfs.ylj_yfs,0)  
                else   
                 ISNULL(ht.YgAlterAmount,0) +ISNULL(ylj.ygAlterAdj,0)  end  AS  [总预留金] , -- 总预留金
            ISNULL(yfs.ylj_yfs,0)  AS  [已发生预留金],-- 已发生预留金

            case when ht.jsState in ('结算','结算中') then  0 else 
                ISNULL(ht.YgAlterAmount,0) +ISNULL(ylj.ygAlterAdj,0)  -  ISNULL(yfs.ylj_yfs,0) 
             end  AS  [待发生预留金],  -- 待发生预留金
            fxj.FxjAmount as [非现金], -- 变更(非现金)
            CASE WHEN  (ht.HtClass='已定非合同' AND  ht.JsState in ('结算','结算中') ) 
                THEN ht.HtCfAmount ELSE(  CASE WHEN js.ExecutingBudgetGUID IS NOT NULL   
                THEN ISNULL(js.JsAmount,0) - ISNULL(fxj.fxjAmount,0) 
            ELSE ISNULL(js.JsAmount,0) END) END AS [结算金额], --结算金额
            case when  ht.JsState in ('结算','结算中') then  ISNULL(ht.HtCfAmount,0) else  0 end  as  [结算合同的首次签约金额] --结算对应合同的首次签约金额
        FROM dbo.cb_Budget_Working a WITH(NOLOCK)
        inner join dbo.p_project p WITH(NOLOCK) on p.ProjGUID=a.ProjectGUID
        inner join mybusinessunit bu WITH(NOLOCK) on bu.buguid=p.buguid
        inner JOIN dbo.cb_Budget_Executing ex WITH(NOLOCK) ON ex.ExecutingBudgetGUID=a.WorkingBudgetGUID
        LEFT JOIN dbo.cb_HtType b WITH(NOLOCK) ON a.BigHTTypeGUID = b.HtTypeGUID
        LEFT JOIN #HT ht WITH(NOLOCK) ON ht.ExecutingBudgetGUID = a.WorkingBudgetGUID
        LEFT JOIN #ZZG zzg WITH(NOLOCK) ON zzg.ExecutingBudgetGUID = a.WorkingBudgetGUID
        LEFT JOIN #yfs yfs WITH(NOLOCK) ON yfs.ExecutingBudgetGUID = a.WorkingBudgetGUID
        LEFT JOIN #ylj ylj WITH(NOLOCK) ON ylj.ExecutingBudgetGUID = a.WorkingBudgetGUID
        LEFT JOIN #Fxj fxj WITH(NOLOCK) ON fxj.ExecutingBudgetGUID=a.WorkingBudgetGUID
        LEFT JOIN #fsBx fs WITH(NOLOCK) ON fs.ExecutingBudgetGUID=a.WorkingBudgetGUID
        LEFT JOIN #JS js WITH(NOLOCK) ON js.ExecutingBudgetGUID=a.WorkingBudgetGUID
        WHERE b.HtTypeName not in ('土地类','管理费','营销费','财务费')  
        and (a.ProjectGUID in ( SELECT [Value] FROM dbo.fn_Split1(@var_projguid, ',') ) or @var_projguid is null)
        order by bu.buname, a.ProjectGUID,a.BudgetName,ht.ContractName


-- 删除临时表
drop table IF EXISTS #HT
drop table IF EXISTS #ZZGBG
drop table IF EXISTS #ZZG
drop table IF EXISTS #ylj
drop table IF EXISTS #yfs
drop table IF EXISTS #JS
drop table IF EXISTS #FXJ

end 



