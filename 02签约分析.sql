
/*
功能说明：基于保利湾区公司的基础底表 统计月度会议报告的签约和回笼分析部分数据指标

创建:2024-07-11  by chenjw
*/

BEGIN
    -- 定义变量 
    DECLARE @lastMonthStartDay DATETIME = DATEADD(mm, DATEDIFF(mm, 0, DATEADD(mm, -1, GETDATE())), 0); --上月初
    DECLARE @lastMonthEndDay DATETIME = DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, GETDATE()), 0)); -- 上月末

    -- 查询清洗日期每月末
    select 组织架构id,组织架构类型,组织架构名称 , dateadd(ms,-3,DATEADD(mm, DATEDIFF(m,0,清洗时间)+1, 0))  as 清洗时间月末
    into #qxDate
    from  s_WqBaseStatic_summary sy 
    where  sy.组织架构类型 =1 and datediff(day,清洗时间,dateadd(ms,-3,DATEADD(mm, DATEDIFF(m,0,清洗时间)+1, 0)) ) =0 and  平台公司名称='湾区公司'

    --从清洗底表中取项目层级对应时间进度
   --从清洗底表中取项目层级对应时间进度
    SELECT  
            a.清洗时间,
            a.平台公司名称 ,
            a.平台公司GUID ,
            CASE WHEN base.存量增量 IS NULL THEN '公司整体' ELSE base.存量增量 END AS 分析维度 ,
            SUM(ISNULL(本年已签约金额, 0)) AS 上月年度签约金额 ,
            SUM(ISNULL(本年签约任务, 0)) AS 上月年度签约任务 ,
            CASE WHEN SUM(ISNULL(本年签约任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年已签约金额, 0)) / SUM(ISNULL(本年签约任务, 0))  END AS 上月年度签约完成率 ,
            SUM(ISNULL(本年签约金额不含税, 0) * 10000.0 ) AS 上月本年签约金额不含税 ,
            SUM(ISNULL(本年销售净利润账面, 0) * 10000.0 ) AS 上月本年销售净利润账面 ,
            CASE WHEN SUM(ISNULL(本年签约金额不含税, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年销售净利润账面, 0)) / SUM(ISNULL(本年签约金额不含税, 0))END AS 上月本年签约净利率,
			SUM(ISNULL(本年回笼金额,0)) AS 上月年度回笼金额,
			SUM(ISNULL(本年回笼任务, 0)) AS 上月年度回笼任务 ,
            CASE WHEN SUM(ISNULL(本年回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年回笼金额, 0)) / SUM(ISNULL(本年回笼任务, 0))  END AS 上月年度回笼完成率 
    INTO    #lastMonthSale
    FROM    s_WqBaseStatic_summary a
	INNER JOIN highdata_prod.dbo.data_wide_dws_s_WqBaseStatic_baseinfo base ON a.组织架构id = base.组织架构id
	inner join #qxDate d on  DATEDIFF(day,a.清洗时间,d.清洗时间月末) =0
    WHERE   a.组织架构类型 = 3 AND  平台公司名称 = '湾区公司'
    GROUP BY GROUPING SETS((a.清洗时间,a.平台公司名称, a.平台公司GUID, base.存量增量), (a.清洗时间,a.平台公司名称, a.平台公司GUID))
	UNION ALL 
	--从清洗底表中取业态层级对应时间进度
    SELECT  a.清洗时间,
	        平台公司名称 ,
            平台公司GUID ,
            CASE WHEN  a.业态 IN  ('高级住宅','住宅','别墅') THEN  '住宅' 
			           WHEN a.业态 ='地下室/车库' THEN  '车位'
					  ELSE  '商办' END  AS 分析维度 ,
            SUM(ISNULL(本年已签约金额, 0)) AS 上月年度签约金额 ,
            SUM(ISNULL(本年签约任务, 0)) AS 上月年度签约任务 ,
            CASE WHEN SUM(ISNULL(本年签约任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年已签约金额, 0)) / SUM(ISNULL(本年签约任务, 0))  END AS 上月年度签约完成率 ,
            SUM(ISNULL(本年签约金额不含税, 0) * 10000.0 ) AS 上月本年签约金额不含税 ,
            SUM(ISNULL(本年销售净利润账面, 0) * 10000.0 ) AS 上月本年销售净利润账面 ,
            CASE WHEN SUM(ISNULL(本年签约金额不含税, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年销售净利润账面, 0)) / SUM(ISNULL(本年签约金额不含税, 0))END AS 上月本年签约净利率,
		    SUM(ISNULL(本年回笼金额, 0)) AS 上月年度回笼金额 ,
            SUM(ISNULL(本年回笼任务, 0)) AS 上月年度回笼任务 ,
            CASE WHEN SUM(ISNULL(本年回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年回笼金额, 0)) / SUM(ISNULL(本年回笼任务, 0))  END AS 上月年度回笼完成率 
    FROM    s_WqBaseStatic_summary a
    inner join #qxDate d on  DATEDIFF(day,a.清洗时间,d.清洗时间月末) =0
    WHERE   a.组织架构类型 = 4 AND  平台公司名称 = '湾区公司'
    GROUP BY  a.清洗时间, 平台公司名称 ,
            平台公司GUID , CASE WHEN  a.业态 IN  ('高级住宅','住宅','别墅') THEN  '住宅' 
			           WHEN a.业态 ='地下室/车库' THEN  '车位'
					  ELSE  '商办' END


    --创建销售项目层级数据临时表
    SELECT  
            org.清洗时间,
            org.平台公司名称 ,
            org.平台公司GUID ,
            org.组织架构父级id ,
            org.组织架构id ,
            org.组织架构名称 ,
            base.区域 ,
            base.项目名称 ,
            base.项目推广名 ,
            base.地块名 AS 项目地块名 ,
            base.项目guid ,
            base.投管代码 ,
            base.明源代码 ,
            base.所属镇街 ,
            base.项目所属城市 ,
            base.销售片区 ,
            base.项目标签 ,
            base.存量增量 ,
            sale.本年认购任务 ,
            sale.本年认购金额 ,
            sale.本年认购面积 ,
            sale.本年认购套数 ,
            sale.本年签约任务 ,
            sale.本年已签约金额 ,
            sale.本年已签约面积 ,
            sale.本年已签约套数 ,
            sale.本月认购任务 ,
            sale.本月认购金额 ,
            sale.本月认购面积 ,
            sale.本月认购套数 ,
            sale.本月签约任务 ,
            sale.本月签约金额 ,
            sale.本月签约面积 ,
            sale.本月签约套数 ,
            profit.本年签约金额不含税 ,
            profit.本年销售净利润账面,
			hl.本月回笼任务 ,
			hl.本月回笼金额 ,
			hl.本年回笼任务 ,
			hl.本年回笼金额 
    INTO    #SaleTmp
    FROM    highdata_prod.dbo.dw_s_WqBaseStatic_Organization org
            LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_baseinfo base ON org.组织架构id = base.组织架构id and  org.清洗时间id = base.清洗时间id
            LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_tradeInfo sale ON sale.组织架构id = org.组织架构id and  org.清洗时间id = sale.清洗时间id
            LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_ProfitInfo profit ON profit.组织架构id = org.组织架构id and  org.清洗时间id = profit.清洗时间id
			LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_returnInfo hl ON hl.组织架构id = org.组织架构id and  org.清洗时间id = hl.清洗时间id
    WHERE   1 = 1 AND   org.组织架构类型 = 3 AND  org.平台公司名称 = '湾区公司'

    --创建销售业态层级数据临时表
    SELECT  org.清洗时间,
            org.平台公司名称 ,
            org.平台公司GUID ,
            org.组织架构父级id ,
            org.组织架构id ,
            org.组织架构名称 ,
			org.业态,
            base.区域 ,
            base.项目名称 ,
            base.项目推广名 ,
            base.地块名 AS 项目地块名 ,
            base.项目guid ,
            base.投管代码 ,
            base.明源代码 ,
            base.所属镇街 ,
            base.项目所属城市 ,
            base.销售片区 ,
            base.项目标签 ,
            base.存量增量 ,
            sale.本年认购任务 ,
            sale.本年认购金额 ,
            sale.本年认购面积 ,
            sale.本年认购套数 ,
            sale.本年签约任务 ,
            sale.本年已签约金额 ,
            sale.本年已签约面积 ,
            sale.本年已签约套数 ,
            sale.本月认购任务 ,
            sale.本月认购金额 ,
            sale.本月认购面积 ,
            sale.本月认购套数 ,
            sale.本月签约任务 ,
            sale.本月签约金额 ,
            sale.本月签约面积 ,
            sale.本月签约套数 ,
            profit.本年签约金额不含税 ,
            profit.本年销售净利润账面,
		    hl.本月回笼任务 ,
			hl.本月回笼金额 ,
			hl.本年回笼任务 ,
			hl.本年回笼金额 
    INTO    #YtSaleTmp
    FROM    highdata_prod.dbo.dw_s_WqBaseStatic_Organization org
            LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_baseinfo base ON org.组织架构id = base.组织架构id and  org.清洗时间id = base.清洗时间id
            LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_tradeInfo sale ON sale.组织架构id = org.组织架构id and  org.清洗时间id = sale.清洗时间id
            LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_ProfitInfo profit ON profit.组织架构id = org.组织架构id and  org.清洗时间id = profit.清洗时间id
			LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_returnInfo hl ON hl.组织架构id = org.组织架构id and  org.清洗时间id = hl.清洗时间id
    WHERE   1 = 1 AND   org.组织架构类型 =4 AND  org.平台公司名称 = '湾区公司'


    --签约分析（按分析维度）按照存量、增量、新增量、产成品、商办、车位6个分析维度指标
    SELECT  清洗时间,
            平台公司名称 ,
            平台公司GUID ,
            CASE WHEN 存量增量 IS NULL THEN '公司整体' ELSE 存量增量 END AS 分析维度 ,
            SUM(ISNULL(s.本月签约任务, 0)) AS 月度去化目标 ,
            SUM(ISNULL(s.本月签约金额, 0)) AS 本月完成 ,
            CASE WHEN SUM(ISNULL(s.本月签约任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本月签约金额, 0)) / SUM(ISNULL(s.本月签约任务, 0))END AS 本月完成率 ,
            SUM(ISNULL(s.本年签约任务, 0)) AS 年度去化目标 ,
            SUM(ISNULL(s.本年已签约金额, 0)) AS 本年完成 ,
            CASE WHEN SUM(ISNULL(s.本年签约任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本年已签约金额, 0)) / SUM(ISNULL(s.本年签约任务, 0))END AS 本年完成率 ,
            CASE WHEN SUM(ISNULL(s.本年签约任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本年已签约金额, 0)) / SUM(ISNULL(s.本年签约任务, 0)) END AS 本月年度签约完成率 ,    -- 按照时间分摊比例
            SUM(ISNULL(本年签约金额不含税, 0) * 10000.0 ) AS 本年签约金额不含税 ,
            SUM(ISNULL(本年销售净利润账面, 0) * 10000.0 ) AS 本年销售净利润账面 ,
            CASE WHEN SUM(ISNULL(本年签约金额不含税, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年销售净利润账面, 0)) / SUM(ISNULL(本年签约金额不含税, 0))END AS 本年签约净利率,
            SUM(ISNULL(s.本月回笼任务, 0)) AS 月度回笼目标 ,
            SUM(ISNULL(s.本月回笼金额, 0)) AS 本月回笼完成 ,
            CASE WHEN SUM(ISNULL(s.本月回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本月回笼金额, 0)) / SUM(ISNULL(s.本月回笼任务, 0))END AS 本月回笼完成率 ,
            SUM(ISNULL(s.本年回笼任务, 0)) AS 年度回笼目标 ,
            SUM(ISNULL(s.本年回笼金额, 0)) AS 本年回笼完成 ,
            CASE WHEN SUM(ISNULL(s.本年回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本年回笼金额, 0)) / SUM(ISNULL(s.本年回笼任务, 0))END AS 本年回笼完成率 
    INTO    #MonthSale
    FROM    #SaleTmp s
    GROUP BY GROUPING SETS((清洗时间,平台公司名称, 平台公司GUID, 存量增量), (清洗时间,平台公司名称, 平台公司GUID))
	-- 住宅：高级住宅, 住宅, 别墅 车位：地下室/车库  商办：除高级住宅, 住宅, 别墅、地下室/车库外的业态
	-- 业态层级的销售任务为空值
	UNION ALL 
    SELECT  
            清洗时间,
            平台公司名称 ,
            平台公司GUID ,
            CASE WHEN  业态 IN  ('高级住宅','住宅','别墅') THEN  '住宅' 
			           WHEN 业态 ='地下室/车库' THEN  '车位'
					  ELSE  '商办' END  AS 分析维度 ,
            SUM(ISNULL(s.本月签约任务, 0)) AS 月度去化目标 ,
            SUM(ISNULL(s.本月签约金额, 0)) AS 本月完成 ,
            CASE WHEN SUM(ISNULL(s.本月签约任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本月签约金额, 0)) / SUM(ISNULL(s.本月签约任务, 0))END AS 本月完成率 ,
            SUM(ISNULL(s.本年签约任务, 0)) AS 年度去化目标 ,
            SUM(ISNULL(s.本年已签约金额, 0)) AS 本年完成 ,
            CASE WHEN SUM(ISNULL(s.本年签约任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本年已签约金额, 0)) / SUM(ISNULL(s.本年签约任务, 0))END AS 本年完成率 ,
            CASE WHEN SUM(ISNULL(s.本年签约任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本年已签约金额, 0)) / SUM(ISNULL(s.本年签约任务, 0))  END AS 本月年度签约完成率 ,    -- 按照时间分摊比例
            SUM(ISNULL(本年签约金额不含税, 0) * 10000.0 ) AS 本年签约金额不含税 ,
            SUM(ISNULL(本年销售净利润账面, 0) * 10000.0 ) AS 本年销售净利润账面 ,
            CASE WHEN SUM(ISNULL(本年签约金额不含税, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年销售净利润账面, 0)) / SUM(ISNULL(本年签约金额不含税, 0))END AS 本年签约净利率,
			SUM(ISNULL(s.本月回笼任务, 0)) AS 月度回笼目标 ,
            SUM(ISNULL(s.本月回笼金额, 0)) AS 本月回笼完成 ,
            CASE WHEN SUM(ISNULL(s.本月回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本月回笼金额, 0)) / SUM(ISNULL(s.本月回笼任务, 0))END AS 本月回笼完成率 ,
            SUM(ISNULL(s.本年回笼任务, 0)) AS 年度回笼目标 ,
            SUM(ISNULL(s.本年回笼金额, 0)) AS 本年回笼完成 ,
            CASE WHEN SUM(ISNULL(s.本年回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本年回笼金额, 0)) / SUM(ISNULL(s.本年回笼任务, 0))END AS 本年回笼完成率 
    FROM    #YtSaleTmp s
	GROUP BY  清洗时间,平台公司名称 ,
            平台公司GUID, CASE WHEN  业态 IN  ('高级住宅','住宅','别墅') THEN  '住宅' 
			           WHEN 业态 ='地下室/车库' THEN  '车位'
					  ELSE  '商办' END
	

    -- 查询结果
    SELECT  
	        CONVERT(VARCHAR(10), MONTH(GETDATE())) + '月' AS 月份,
			CONVERT(VARCHAR(10), day(GETDATE())) + '日' AS 日期,
			a.平台公司名称 ,
            a.平台公司GUID ,
            a.分析维度 ,
            a.月度去化目标 ,
            a.本月完成 ,
            a.本月完成率 ,
            a.年度去化目标 ,
            a.本年完成 ,
            a.本年完成率 ,
            --a.本月年度签约完成率,
            --b.上月年度签约完成率,
            case when ISNULL(b.上月年度签约完成率, 0) =0 then  0 else  ( ISNULL(b.上月年度签约完成率, 0) - ISNULL(本月年度签约完成率, 0) ) /ISNULL(b.上月年度签约完成率, 0) end AS 环比上月与时间进度变化 ,  -- (上月-本月 )/ 上月
			CASE WHEN case when ISNULL(b.上月年度签约完成率, 0) =0 then  0 else  ( ISNULL(b.上月年度签约完成率, 0) - ISNULL(本月年度签约完成率, 0) ) /ISNULL(b.上月年度签约完成率, 0) end  > 0 THEN '提升' ELSE '下降' END AS 提升或下降_年度签约完成率 ,
            a.本年签约金额不含税 ,
            a.本年销售净利润账面 ,
            a.本年签约净利率 ,
            b.上月本年签约金额不含税 ,
            b.上月本年销售净利润账面 ,
            b.上月本年签约净利率 ,
            --CASE WHEN ISNULL(b.上月本年签约净利率, 0) = 0 THEN 0 ELSE (ISNULL(b.上月本年签约净利率, 0) - ISNULL(a.本年签约净利率, 0)) / ISNULL(b.上月本年签约净利率, 0)END AS 本年签约净利率环比,
			--case when   CASE WHEN ISNULL(b.上月本年签约净利率, 0) = 0 THEN 0 ELSE (ISNULL(b.上月本年签约净利率, 0) - ISNULL(a.本年签约净利率, 0)) / ISNULL(b.上月本年签约净利率, 0)END  > 0  then '提升' ELSE '下降' END as  提升或下降_本年签约净利率 ,
			( ISNULL(a.本年签约净利率, 0) - ISNULL(b.上月本年签约净利率, 0) )  AS 本年签约净利率环比, --计算逻辑:较上月变化=本年累计至本月签约净利率-本年累计至上月月签约净利率
			case when  ( ISNULL(a.本年签约净利率, 0) - ISNULL(b.上月本年签约净利率, 0) )   > 0  then '提升' ELSE '下降' END as  提升或下降_本年签约净利率 ,
            
            a.月度回笼目标,
			a.本月回笼完成,
			a.本月回笼完成率,
			a.年度回笼目标,
			a.本年回笼完成,
			a.本年回笼完成率
    FROM    #MonthSale a
            left  JOIN #lastMonthSale b ON a.平台公司GUID = b.平台公司GUID AND a.分析维度 = b.分析维度 and datediff(month,b.清洗时间,a.清洗时间) =1


    -- 删除临时表
    DROP TABLE #lastMonthSale ,
               #MonthSale ,
               #SaleTmp,
			   #YtSaleTmp
END;