-- 2025-02-25 对数产值回顾报表新增字段
-- 1、成本-产值月度回顾单据状态（未审批、审核中、已审批）
-- 2、计划-月度形象进度单据状态（未审批、审核中、已审批）
-- 3、成本-产值月度回顾最新发起月份
-- 4、计划-月度形象进度回顾最新发起月份
-- exec sp_executesql N'EXEC  usp_cb_GetBudgetInfoMain  @ProjGUID ,@State,@BudgetName'
-- ,N'@ProjGUID nvarchar(36),@State nvarchar(4000),@BudgetName nvarchar(4000)',@ProjGUID=N'2b3b0206-f785-e911-80b7-0a94ef7517dd',@State=N'',@BudgetName=N''
-- 5、动态成本金额（不含非现金）（取值合约规划-合约规划总金额）
-- 6、成本月度回顾-项目盘点应付款（I）
-- 7、合同-累计付款申请（不含土地+三费）
-- 8、成本月度回顾-累计实付款（J）
-- 9、合同-累计付款登记（不含土地+三费）

declare @buguid nvarchar(36)
set @buguid = '248B1E17-AACB-E511-80B8-E41F13C51836'

--已签约的合同
SELECT 
	 c.ContractGUID
	,c.ContractName
	,c.bgxs 
	,b.ExecutingBudgetGUID
	,c.HtClass 
	,c.JsState
	,SUM(a.CfAmount) AS HtCfAmount
	,SUM(a.YgAlterAmount) AS  YgAlterAmount
	INTO  #HT
	FROM  dbo.cb_BudgetUse a
	INNER JOIN dbo.cb_Budget b ON b.BudgetGUID = a.BudgetGUID 
	INNER JOIN cb_Contract c ON c.ContractGUID=a.RefGUID
	INNER JOIN dbo.p_Project p ON a.ProjectCode=p.ProjCode
	WHERE a.IsApprove=1 AND	 c.IfDdhs=1
	-- AND p.ProjGUID=@ProjGUID
        and  p.buguid in ( @buguid )
	GROUP BY  c.ContractGUID,c.ContractName,c.bgxs, b.ExecutingBudgetGUID,c.HtClass ,c.JsState
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
	-- AND p.ProjGUID=@ProjGUID  
        and  p.buguid in ( @buguid )
	GROUP  BY b.ExecutingBudgetGUID

--预留金额
	SELECT 
        b.ExecutingBudgetGUID
	,ISNULL(SUM(a.CfAmount),0)  AS YgYeAmount
	,ISNULL(SUM(a.ygAlterAdj),0) AS ygAlterAdj
	INTO #ylj
	FROM cb_YgAlter2Budget a
	INNER JOIN dbo.cb_Budget b ON b.BudgetGUID = a.BudgetGUID
	where -- b.ProjectGUID=@ProjGUID  
        b.buguid in ( @buguid )
	GROUP  BY b.ExecutingBudgetGUID

--暂转固
--项目下所有的转固变更
        SELECT 
        DISTINCT  b.ContractGUID,b.HTAlterGUID ,a.ApproveDate
        INTO #ZZGBG
        FROM dbo.cb_Contract a
        INNER JOIN dbo.cb_HTAlter b ON a.ContractGUID=b.RefGUID
        INNER JOIN  dbo.cb_BudgetUse bu ON bu.RefGUID=b.HTAlterGUID 
        INNER JOIN dbo.p_Project p ON p.ProjCode=bu.ProjectCode
        WHERE  -- p.ProjGUID=@ProjGUID 
        p.buguid in ( @buguid )
        and   b.AlterType='附属合同' AND a.ZzgHTBalanceGUID IS NOT NULL 

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
        WHERE p.buguid in ( @buguid ) -- p.ProjGUID=@ProjGUID  
        GROUP BY d.ExecutingBudgetGUID

--负数补协 负数补协(不含暂转固）
        SELECT 
        b.ExecutingBudgetGUID, 
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
                        and  p.buguid in ( @buguid )
                        --- AND p.ProjGUID=@ProjGUID  
        GROUP BY	b.ExecutingBudgetGUID

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
	-- AND p.ProjGUID=@ProjGUID
        and  p.buguid in ( @buguid )
	GROUP BY d.ExecutingBudgetGUID

-- 产值管控
        SELECT id,Value as projguid ,ProjGUIDs,ProjNames,case when  isnull(SetMode,0)=0 then '否' else '是' end as SetMode 
        INTO #czgk  
        FROM  cb_ContractCzcfControl a
        CROSS  APPLY  dbo.fn_Split1(convert(varchar(max),a.ProjGUIDs),',') 
        WHERE  convert(varchar(max),a.ProjGUIDs)<>'' and  a.buguid  in ( @buguid )

--已结算合同-已定合同
	SELECT
	d.ExecutingBudgetGUID,
        SUM(c.JsAmount) AS JsAmount
	INTO  #JS
	FROM dbo.cb_HTBalance a
	INNER JOIN cb_HTAlter b ON a.HTBalanceGUID=b.RefGUID
	INNER JOIN dbo.cb_BudgetUse c ON c.RefGUID=b.HTAlterGUID
	INNER JOIN dbo.cb_Budget d ON d.BudgetGUID = c.BudgetGUID 
	INNER JOIN dbo.p_Project p ON c.ProjectCode=p.ProjCode
	WHERE c.IsApprove=1  	
	-- AND p.ProjGUID=@ProjGUID
        and  p.buguid in ( @buguid )
	GROUP BY d.ExecutingBudgetGUID


-- 项目产值回顾 对数需求
SELECT  bu.buname AS [公司名称],
        p.ProjName AS [所属项目],
        mp.ProjStatus AS [项目状态],
        pp.ProjCode AS [项目代码],
        p.ProjCode as [分期代码],   
        flg.投管代码 AS [投管代码],
        mp.ConstructStatus AS [工程状态],
        TotalOutputValue AS [回顾总产值],
        YfsOutputValue AS [回顾已发生产值],
        DfsOutputValue AS [回顾待发生产值], 
        czgk.SetMode AS [产值管控],
        -- 含土地及三费
        ht.HtAmount AS [合同累计合同金额],
        ht.Yljze AS [合同累计预留金金额],
        ht.jfljywccz AS [合同现场累计产值],
        ht.wfqcz AS [合同累计未发起产值金额],
        ht.PayAmount AS [合同-累计付款登记],
        ht.ApplyAmount AS [合同-累计付款申请金额],
        ht.balanceamount AS [合同-结算金额],
        -- 不含土地及三费
        htNotfee.HtAmountNotfee AS [合同累计合同金额不含土地及三费],
        htNotfee.YljzeNotfee AS [合同累计预留金金额不含土地及三费],
        htNotfee.jfljywcczNotfee AS [合同现场累计产值不含土地及三费],
        htNotfee.wfqczNotfee AS [合同累计未发起产值金额不含土地及三费],
        htNotfee.PayAmountNotfee AS [合同-累计付款登记不含土地三费],
        htNotfee.ApplyAmountNotfee AS [合同-累计付款申请金额不含土地三费],
        htNotfee.balanceamountNotfee AS [合同-结算金额不含土地三费],

        isnull(YfsOutputValue,0) - isnull(ht.jfljywccz,0) AS [差值], -- （"回顾-已发生产值"-"合同-累计现场累计产值"）
        isnull(YfsOutputValue,0) - isnull(htNotfee.jfljywcczNotfee,0) AS [差值不含土地及三费], -- （"回顾-已发生产值"-"合同-累计现场累计产值"）
        cbview.cb_ApproveState AS [成本-产值月度回顾单据状态],
        cbview.ReviewDateMonth AS [成本-产值月度回顾最新发起月份],
        jdview.jd_ApproveState AS [计划-月度形象进度单据状态],
        jdview.ReportDateMonth AS [计划-月度形象进度最新发起月份],
        isnull(htXmpdljwccz.Xmpdljwccz,0) as [成本月度回顾-项目盘点累计完成产值],
        isnull(htXmpdljwccz.Ljyfkje,0) as [成本月度回顾-项目盘点累计应付款],
        isnull(htXmpdljwccz.Ljsfk,0) as [成本月度回顾-累计实付款],
        isnull(htXmpdljwccz.ydczwzfAmount,0) as [成本月度回顾-已达产值未支付金额],
        isnull(htXmpdljwccz.yfwsAmount,0) as [成本月度回顾-应付未付金额],

        isnull(htNewBudgetAmount.NewBudgetAmount,0) AS [合约规划总金额不含土地款及三费],
       	ISNULL(htNewBudgetAmount.HtCfAmount,0) AS   [合同首次签约金额],
        isnull(htNewBudgetAmount.ZzgAmount,0) AS [暂转固金额],
        isnull(htNewBudgetAmount.ZzgDiffAmount,0) AS [暂转固同合同首次签约金额差额],
        isnull(htNewBudgetAmount.FsBxAmount,0) AS [负数补协金额],
        isnull(htNewBudgetAmount.JsAmount,0) AS [结算金额],
        isnull(htNewBudgetAmount.FxjAmount,0) AS [变更非现金],
        isnull(htNewBudgetAmount.FxjDTCost,0) AS [动态成本含非现金]
FROM    p_project p WITH(NOLOCK)
        INNER JOIN ERP25.dbo.mdm_project mp WITH(NOLOCK) ON mp.projguid = p.ProjGUID
        LEFT JOIN erp25.dbo.vmdm_projectFlag flg WITH(NOLOCK) ON flg.projguid = mp.ParentProjGUID
        INNER JOIN mybusinessunit bu WITH(NOLOCK) ON bu.buguid = p.buguid
        LEFT JOIN p_project pp WITH(NOLOCK) ON pp.ProjCode = p.ParentCode AND pp.Level = 2
        left join #czgk czgk WITH(NOLOCK) on czgk.projguid = p.ProjGUID
        -- 成本-产值月度回顾单据状态  
        OUTER APPLY (
            SELECT TOP 1 ProjGUID,
                    ReviewDate,
                    convert(varchar(7),ReviewDate,121) as ReviewDateMonth,-- 回顾月份
                    ApproveState as cb_ApproveState,
                    TotalOutputValue,
                    YfsOutputValue,
                    DfsOutputValue
            FROM (
                SELECT ProjGUID,
                       ReviewDate,
                       ApproveState,
                       TotalOutputValue,
                       YfsOutputValue,
                       DfsOutputValue,
                       ROW_NUMBER() OVER (ORDER BY ReviewDate DESC) as rn
                FROM cb_OutputValueMonthReview WITH(NOLOCK)
                WHERE cb_OutputValueMonthReview.ProjGUID = p.ProjGUID
                      AND ApproveState = '审核中'
                UNION ALL
                SELECT ProjGUID,
                       ReviewDate,
                       ApproveState,
                       TotalOutputValue,
                       YfsOutputValue,
                       DfsOutputValue,
                       ROW_NUMBER() OVER (ORDER BY ReviewDate DESC) as rn
                FROM cb_OutputValueMonthReview WITH(NOLOCK)
                WHERE cb_OutputValueMonthReview.ProjGUID = p.ProjGUID
                      AND ApproveState != '审核中'
            ) t
            WHERE rn = 1
        ) cbview
        -- 计划-月度形象进度单据状态  
        OUTER APPLY (
            SELECT TOP 1 ProjGUID,
                    ReportDate,
                    convert(varchar(7),ReportDate,121) as ReportDateMonth,-- 回顾月份
                    ApproveState as jd_ApproveState
            FROM (
                SELECT ProjGUID,
                       ReportDate, 
                       ApproveState,
                       ROW_NUMBER() OVER (ORDER BY ReportDate DESC) as rn
                FROM jd_OutValueView WITH(NOLOCK)
                WHERE jd_OutValueView.ProjGUID = p.ProjGUID
                      AND ApproveState = '审核中'
                UNION ALL
                SELECT ProjGUID,
                       ReportDate,
                       ApproveState,
                       ROW_NUMBER() OVER (ORDER BY ReportDate DESC) as rn
                FROM jd_OutValueView WITH(NOLOCK)
                WHERE jd_OutValueView.ProjGUID = p.ProjGUID
                      AND ApproveState != '审核中'
            ) t
            WHERE rn = 1
        ) jdview
        -- 合同-项目盘点累计完成产值
        left join (       
            SELECT  outputvalue.projguid,
                     sum(ISNULL(outputvalue.Xmpdljwccz, 0)) AS Xmpdljwccz,
                     sum(isnull(outputvalue.Ljyfkje,0)) as Ljyfkje, --项目盘点累计应付款
                     sum(isnull(outputvalue.yfwsAmount,0)) as yfwsAmount, -- 应付未付金额
                     sum(ISNULL(outputvalue.Ljsfk, 0)) AS Ljsfk,
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
                            INNER JOIN cb_OutputValueMonthReview b WITH(NOLOCK)
                                ON a.OutputValueMonthReviewGUID = b.OutputValueMonthReviewGUID
                    WHERE   a.BusinessType = '合同'
                    ) outputvalue
            WHERE   outputvalue.rownum = 1
            GROUP BY outputvalue.projguid
        ) htXmpdljwccz ON htXmpdljwccz.projguid = p.ProjGUID
        -- 合同金额统计
        LEFT JOIN (
            SELECT  cbp.ProjGUID,
                    SUM(ISNULL(cb.HtAmount,0)) AS HtAmount,  -- 合同金额
                    SUM(ISNULL(Yljze,0)) AS Yljze, -- 预留金金额
                    SUM(ISNULL(cbz.jfljywccz,0)) AS jfljywccz, -- 甲方审核-现场累计产值
                    SUM(CASE WHEN cb.JsState = '结算' 
                            THEN cb.JsAmount_Bz 
                            ELSE ISNULL(cb.htamount, 0) + ISNULL(cb.sumalteramount, 0)
                    END - ISNULL(cbz.jfljywccz, 0)) AS wfqcz, -- 未发起产值金额
                    sum(isnull(pay.PayAmount,0)) as PayAmount, -- 合同-累计付款登记（含土地+三费）
                    sum(isnull(htapply.ApplyAmount,0)) as ApplyAmount, -- 合同-累计付款申请金额（含土地+三费）
                    sum(isnull(balance.balanceamount,0)) as balanceamount -- 合同-结算金额
            FROM    cb_Contract cb WITH(NOLOCK)
		    inner  join cb_httype ty WITH(NOLOCK) on ty.HtTypeCode =cb.HtTypeCode and  ty.BUGUID =cb.BUGUID
                    INNER JOIN cb_ContractProj cbp WITH(NOLOCK) ON cbp.ContractGUID = cb.ContractGUID
                    LEFT JOIN cb_contractcz cbz WITH(NOLOCK) ON cbz.contractguid = cb.contractguid
                    -- 预留金金额
                    LEFT JOIN (
                        SELECT  ContractGUID,
                                SUM(ISNULL(CfAmount,0)) AS Yljze -- 预留金金额
                        FROM    [dbo].[cb_YgAlter2Budget] WITH(NOLOCK)
                        GROUP BY ContractGUID
                    ) ylj ON ylj.ContractGUID = cb.ContractGUID
                    -- 合同-累计付款申请金额（含土地+三费）
                    left join (
                       	select ContractGUID,
                           sum(isnull(ApplyAmount,0)) as ApplyAmount 
                        from  cb_HTFKApply WITH(NOLOCK)
                        group by ContractGUID
                    ) htapply on htapply.ContractGUID = cb.ContractGUID
                    -- 合同-累计付款登记（含土地+三费）
                    left join (
       			select  ContractGUID,sum(isnull(PayAmount,0)) as PayAmount  
                        from  cb_Pay WITH(NOLOCK)
                        group by ContractGUID
                    ) pay on pay.ContractGUID = cb.ContractGUID
                    -- 合同-结算金额
                    left join (
                        select ContractGUID,sum(isnull(balanceamount,0)) as  balanceamount from  cb_HTBalance WITH(NOLOCK)
                        where  BalanceType ='结算'
                        group by  ContractGUID
                    ) balance on balance.ContractGUID = cb.ContractGUID
            WHERE   cb.ApproveState = '已审核' -- and  ty.HtTypeCode not in ('01','01.01','01.02','01.03','01.04','01.05')
            GROUP BY cbp.ProjGUID
        ) ht ON ht.ProjGUID = p.ProjGUID
        -- 不含土地款及三费
        LEFT JOIN (
            SELECT  cbp.ProjGUID,
                    SUM(ISNULL(cb.HtAmount,0)) AS HtAmountNotfee,  -- 合同金额
                    SUM(ISNULL(Yljze,0)) AS YljzeNotfee, -- 预留金金额
                    SUM(ISNULL(cbz.jfljywccz,0)) AS jfljywcczNotfee, -- 甲方审核-现场累计产值
                    SUM(CASE WHEN cb.JsState = '结算' 
                            THEN cb.JsAmount_Bz 
                            ELSE ISNULL(cb.htamount, 0) + ISNULL(cb.sumalteramount, 0)
                        END - ISNULL(cbz.jfljywccz, 0)) AS wfqczNotfee, -- 未发起产值金额
                    sum(isnull(pay.PayAmount,0)) as PayAmountNotfee, -- 合同-累计付款登记（不含土地+三费）    
                    sum(isnull(htapply.ApplyAmount,0)) as ApplyAmountNotfee, -- 合同-累计付款申请金额（含土地+三费）
                    sum(isnull(balance.balanceamount,0)) as balanceamountNotfee -- 合同-结算金额
            FROM    cb_Contract cb WITH(NOLOCK)
		    inner  join cb_httype ty WITH(NOLOCK) on ty.HtTypeCode =cb.HtTypeCode and  ty.BUGUID =cb.BUGUID
                    INNER JOIN cb_ContractProj cbp WITH(NOLOCK) ON cbp.ContractGUID = cb.ContractGUID
                    LEFT JOIN cb_contractcz cbz WITH(NOLOCK) ON cbz.contractguid = cb.contractguid
                    LEFT JOIN (
                        SELECT  ContractGUID,
                                SUM(ISNULL(CfAmount,0)) AS Yljze -- 预留金金额
                        FROM    [dbo].[cb_YgAlter2Budget] WITH(NOLOCK)
                        GROUP BY ContractGUID
                    ) ylj ON ylj.ContractGUID = cb.ContractGUID
                    left join (
                       	select ContractGUID,
                           sum(isnull(ApplyAmount,0)) as ApplyAmount 
                        from  cb_HTFKApply WITH(NOLOCK)
                        group by ContractGUID
                    ) htapply on htapply.ContractGUID = cb.ContractGUID
                    left join (
       			select  ContractGUID,sum(isnull(PayAmount,0)) as PayAmount  
                        from  cb_Pay WITH(NOLOCK)
                        group by ContractGUID

                    ) pay on pay.ContractGUID = cb.ContractGUID      
                    -- 合同-结算金额
                    left join (
                        select ContractGUID,sum(isnull(balanceamount,0)) as  balanceamount from  cb_HTBalance WITH(NOLOCK)
                        where  BalanceType ='结算'
                        group by  ContractGUID
                    ) balance on balance.ContractGUID = cb.ContractGUID     
            WHERE   cb.ApproveState = '已审核' 
            -- 不含土地款及管理费、营销费、财务费合同
            and  ty.HtTypeCode not in ('01','01.01','01.02','01.03','01.04','01.05',
                                      '07','07.01','07.02','07.03','07.04','07.05',
                                      '07.06','07.07','07.08','07.09','07.10','07.11',
                                      '07.12','07.13','07.14','08','08.01','09','09.01')
            GROUP BY cbp.ProjGUID
        ) htNotfee ON htNotfee.ProjGUID = p.ProjGUID
        -- 合约规划总金额不含土地款及三费、暂转固金额、负数补协金额、变更非现金、合同首次签约金额
        left join (
                SELECT 
                        a.ProjectGUID,
                        -- b.HtTypeName AS BigHTTypename,    
                        sum(ISNULL(ht.HtCfAmount,0)) AS HtCfAmount, -- 合同首次签约金额
                        sum(zzg.ZzgAmount) as ZzgAmount, -- 暂转固金额
                        sum(case when  isnull(zzg.ZzgAmount,0) =0 then  0  else  isnull(zzg.ZzgAmount,0) - ISNULL(ht.HtCfAmount,0) end ) as ZzgDiffAmount, -- 暂转固同合同首次签约金额差额              -- 暂转固金额不含土地款及三费
                        sum(fs.FsBxAmount) as FsBxAmount, -- 负数补协金额
                        sum( CASE WHEN  (ht.HtClass='已定非合同' AND  ht.JsState='结算') 
                                THEN ht.HtCfAmount ELSE(  CASE WHEN js.ExecutingBudgetGUID IS NOT NULL   
                                THEN ISNULL(js.JsAmount,0) - ISNULL(fxj.fxjAmount,0) 
                        ELSE ISNULL(js.JsAmount,0) END) END) AS JsAmount, --结算金额
                        sum(CASE WHEN ht.ExecutingBudgetGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0) + ISNULL(ylj.YgYeAmount,0)
                                ELSE a.BudgetAmount  
                        END) AS NewBudgetAmount, -- 合约规划总金额不含土地款及三费
                        sum(fxj.FxjAmount) as FxjAmount,-- 变更(非现金)
                        sum(ISNULL(CASE WHEN ht.ContractGUID IS NOT NULL THEN ISNULL(yfs.YfsCost,0)+ISNULL(ylj.YgYeAmount,0)
                        ELSE ex.BudgetAmount END,0) + ISNULL(fxj.fxjAmount,0))	 AS  FxjDTCost
                FROM dbo.cb_Budget_Working a WITH(NOLOCK)
        	LEFT JOIN dbo.cb_Budget_Executing ex WITH(NOLOCK) ON ex.ExecutingBudgetGUID=a.WorkingBudgetGUID
                LEFT JOIN dbo.cb_HtType b WITH(NOLOCK) ON a.BigHTTypeGUID = b.HtTypeGUID
                LEFT JOIN #HT ht WITH(NOLOCK) ON ht.ExecutingBudgetGUID = a.WorkingBudgetGUID
                LEFT JOIN #yfs yfs WITH(NOLOCK) ON yfs.ExecutingBudgetGUID = a.WorkingBudgetGUID
                LEFT JOIN #ylj ylj WITH(NOLOCK) ON ylj.ExecutingBudgetGUID = a.WorkingBudgetGUID
                LEFT JOIN #JS js WITH(NOLOCK) ON js.ExecutingBudgetGUID=a.WorkingBudgetGUID
                LEFT JOIN #ZZG zzg WITH(NOLOCK) ON zzg.ExecutingBudgetGUID = a.WorkingBudgetGUID
        	LEFT JOIN #fsBx fs WITH(NOLOCK) ON fs.ExecutingBudgetGUID=a.WorkingBudgetGUID
                LEFT JOIN #Fxj fxj WITH(NOLOCK) ON fxj.ExecutingBudgetGUID=a.WorkingBudgetGUID
                WHERE b.HtTypeName not in ('土地类','管理费','营销费','财务费')   --a.ProjectGUID = @ProjGUID
                GROUP BY a.ProjectGUID
        ) htNewBudgetAmount ON htNewBudgetAmount.ProjectGUID = p.ProjGUID

WHERE   1=1  and p.level =3  and  bu.buguid  in ( @buguid ) 
-- AND p.projname = '南昌市青山湖区艾溪湖南路019号85亩项目-一期'
order by  bu.buname, p.ProjName


-- 删除临时表 
drop table #HT
drop table #yfs
drop table #ylj
drop table #zzg
drop table #fsBx
drop table #Fxj
drop table #ZZGBG
drop table #czgk
drop table #JS
