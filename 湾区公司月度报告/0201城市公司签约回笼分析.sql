/*
功能说明：基于保利湾区公司的基础底表 统计月度会议报告的签约分析城市公司部分数据指标

创建:2024-07-12  by chenjw
*/

BEGIN
    -- 定义变量 
    DECLARE @lastMonthStartDay DATETIME = DATEADD(mm, DATEDIFF(mm, 0, DATEADD(mm, -1, GETDATE())), 0); --上月初
    DECLARE @lastMonthEndDay DATETIME = DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, GETDATE()), 0)); -- 上月末

    -- 查询清洗日期每月末
	SELECT 组织架构id,
		组织架构类型,
		组织架构名称,
		DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间) + 1, 0)) AS 清洗时间月末
	INTO #qxDate
	  FROM s_WqBaseStatic_summary sy
	  WHERE sy.组织架构类型 = 1
			AND DATEDIFF(DAY, 清洗时间, DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间) + 1, 0))) = 0
			AND 平台公司名称 = '湾区公司';

    --从清洗底表中取项目层级对应时间进度
    SELECT  
            a.清洗时间,
            a.平台公司名称 ,
            a.平台公司GUID ,
            base.组织架构名称 AS 城市公司 ,
            SUM(ISNULL(本年已签约金额, 0)) AS 上月年度签约金额 ,
            SUM(ISNULL(本年签约任务, 0)) AS 上月年度签约任务 ,
            --SUM(ISNULL(本年签约任务, 0))* @LastMonthTimeFtRate  AS 上月年度签约任务按时间分摊比例 ,
            CASE WHEN SUM(ISNULL(本年签约任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年已签约金额, 0)) / SUM(ISNULL(本年签约任务, 0))  END AS 上月年度签约完成率 ,
            SUM(ISNULL(本年签约金额不含税, 0) * 10000.0) AS 上月本年签约金额不含税 ,
            SUM(ISNULL(本年销售净利润账面, 0) * 10000.0) AS 上月本年销售净利润账面 ,
            CASE WHEN SUM(ISNULL(本年签约金额不含税, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年销售净利润账面, 0)) / SUM(ISNULL(本年签约金额不含税, 0))END AS 上月本年签约净利率 ,
            SUM(ISNULL(本年回笼金额, 0)) AS 上月年度回笼金额 ,
            SUM(ISNULL(本年回笼任务, 0)) AS 上月年度回笼任务 ,
		    --SUM(ISNULL(本年回笼任务, 0)) * @LastMonthTimeFtRate AS 上月年度回笼任务按时间分摊比例 ,
            CASE WHEN SUM(ISNULL(本年回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年回笼金额, 0)) / SUM(ISNULL(本年回笼任务, 0))  END AS 上月年度回笼完成率
    INTO    #lastMonthSale
    FROM    s_WqBaseStatic_summary a
            INNER JOIN highdata_prod.dbo.data_wide_dws_s_WqBaseStatic_baseinfo base ON a.组织架构id = base.组织架构id
            inner join #qxDate d on  DATEDIFF(day,a.清洗时间,d.清洗时间月末) =0
    WHERE   a.组织架构类型 = 2 AND  平台公司名称 = '湾区公司'
    GROUP BY a.清洗时间,
             a.平台公司名称 ,
             a.平台公司GUID ,
             base.组织架构名称;

    --创建销售项目层级数据临时表
    SELECT  org.清洗时间,
            org.平台公司名称 ,
            org.平台公司GUID ,
            org.组织架构父级id ,
            org.组织架构id ,
            org.组织架构名称 ,
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
            profit.本年销售净利润账面 ,
            hl.本月回笼任务 ,
            hl.本月回笼金额 ,
            hl.本年回笼任务 ,
            hl.本年回笼金额,
			hl.待收款金额,
			hl.本年签约本年回笼,
			hl.年初待收款,
			hl.年初待收款回笼
    INTO    #SaleTmp
    FROM    highdata_prod.dbo.dw_s_WqBaseStatic_Organization org
            LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_baseinfo base ON org.组织架构id = base.组织架构id  and  org.清洗时间id = base.清洗时间id
            LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_tradeInfo sale ON sale.组织架构id = org.组织架构id and  org.清洗时间id = sale.清洗时间id
            LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_ProfitInfo profit ON profit.组织架构id = org.组织架构id and  org.清洗时间id = profit.清洗时间id
            LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_returnInfo hl ON hl.组织架构id = org.组织架构id and  org.清洗时间id = hl.清洗时间id
    WHERE   1 = 1 AND   org.组织架构类型 = 2 AND  org.平台公司名称 = '湾区公司' 

    --签约分析（按分析维度）按照存量、增量、新增量、产成品、商办、车位6个分析维度指标
    SELECT  
            清洗时间,
            平台公司名称 ,
            平台公司GUID ,
            组织架构名称 AS 城市公司 ,
            SUM(ISNULL(s.本月签约任务, 0)) AS 月度去化目标 ,
            SUM(ISNULL(s.本月签约金额, 0)) AS 本月完成 ,
            CASE WHEN SUM(ISNULL(s.本月签约任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本月签约金额, 0)) / SUM(ISNULL(s.本月签约任务, 0))END AS 本月完成率 ,
            SUM(ISNULL(s.本年签约任务, 0)) AS 年度去化目标 ,
            SUM(ISNULL(s.本年已签约金额, 0)) AS 本年完成 ,
            CASE WHEN SUM(ISNULL(s.本年签约任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本年已签约金额, 0)) / SUM(ISNULL(s.本年签约任务, 0))END AS 本年完成率 ,
            --SUM(ISNULL(s.本年签约任务, 0)) * @TimeFtRate AS 本月年度去化目标按时间分摊比例 ,
            CASE WHEN SUM(ISNULL(s.本年签约任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本年已签约金额, 0)) / SUM(ISNULL(s.本年签约任务, 0))  END AS 本月年度签约完成率 ,    -- 按照时间分摊比例
            SUM(ISNULL(本年签约金额不含税, 0) * 10000.0) AS 本年签约金额不含税 ,
            SUM(ISNULL(本年销售净利润账面, 0) * 10000.0) AS 本年销售净利润账面 ,
            CASE WHEN SUM(ISNULL(本年签约金额不含税, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年销售净利润账面, 0)) / SUM(ISNULL(本年签约金额不含税, 0))END AS 本年签约净利率 ,
            SUM(ISNULL(s.本月回笼任务, 0)) AS 月度回笼目标 ,
            SUM(ISNULL(s.本月回笼金额, 0)) AS 本月回笼完成 ,
            CASE WHEN SUM(ISNULL(s.本月回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本月回笼金额, 0)) / SUM(ISNULL(s.本月回笼任务, 0))END AS 本月回笼完成率 ,
            SUM(ISNULL(s.本年回笼任务, 0)) AS 年度回笼目标 ,
            SUM(ISNULL(s.本年回笼金额, 0)) AS 本年回笼完成 ,
			CASE WHEN SUM(ISNULL(s.本年回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本年回笼金额, 0)) / SUM(ISNULL(s.本年回笼任务, 0))END AS 本年回笼完成率,
            --SUM(ISNULL(s.本年回笼任务, 0)) * @TimeFtRate AS 本月年度回笼任务按时间分摊比例 ,
            CASE WHEN SUM(ISNULL(s.本年回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(s.本年回笼金额, 0)) / SUM(ISNULL(s.本年回笼任务, 0))  END AS 本月年度回笼完成率,     -- 按照时间分摊比例
			SUM(ISNULL(s.待收款金额,0)) AS 待收款金额,
			SUM(ISNULL(s.本年签约本年回笼,0)) AS 本年签约本年回笼 ,
			SUM(ISNULL(s.年初待收款,0)) AS 年初待收款,
			SUM(ISNULL(s.年初待收款回笼,0)) AS 年初待收款回笼
    INTO    #MonthSale
    FROM    #SaleTmp s
    GROUP BY 清洗时间,
             平台公司名称 ,
             平台公司GUID ,
             组织架构名称;

    -- 查询结果
    SELECT  
            a.清洗时间 ,
            ROW_NUMBER() OVER (PARTITION BY a.清洗时间  ORDER BY 本月完成率 DESC) AS 排序 ,
		    ROW_NUMBER() OVER( PARTITION BY a.清洗时间 ORDER BY  CASE WHEN  ISNULL(a.年初待收款,0) =0  THEN 0  ELSE  ISNULL(a.年初待收款回笼,0) /ISNULL(a.年初待收款,0)   END    DESC ) AS 待收款回笼率排序,
			ROW_NUMBER() OVER( PARTITION BY a.清洗时间 ORDER BY  CASE WHEN  ISNULL(a.本年完成,0)  =0 THEN  0 ELSE  ISNULL(本年签约本年回笼,0)  / ISNULL(a.本年完成,0) END DESC  ) AS 新签回笼率排序,	      
            CONVERT(VARCHAR(10), MONTH(a.清洗时间)) + '月' AS 月份 ,
            CONVERT(VARCHAR(10), DAY(a.清洗时间)) + '日' AS 日期 ,
            a.平台公司名称 ,
            a.平台公司GUID ,
            a.城市公司 ,
            a.月度去化目标 ,
            a.本月完成 ,
            a.本月完成率 ,
            a.年度去化目标 ,

            a.本年完成 ,
            a.本年完成率 ,
            --a.本月年度去化目标按时间分摊比例 ,
            --b.上月年度签约任务按时间分摊比例 ,
            b.上月年度签约金额 ,
            CASE WHEN ISNULL(b.上月本年签约净利率, 0) = 0 THEN 0 ELSE (ISNULL(a.本年签约净利率, 0) - ISNULL(b.上月本年签约净利率, 0) ) / ISNULL(b.上月本年签约净利率, 0) END   AS 环比上月与时间进度变化 ,
            a.本年签约金额不含税 ,
            a.本年销售净利润账面 ,
            a.本年签约净利率 ,
            b.上月本年签约金额不含税 ,
            b.上月本年销售净利润账面 ,
            b.上月本年签约净利率 ,
            CASE WHEN ISNULL(b.上月本年签约净利率, 0) = 0 THEN 0 ELSE (ISNULL(a.本年签约净利率, 0) - ISNULL(b.上月本年签约净利率, 0) ) / ISNULL(b.上月本年签约净利率, 0)END AS 本年签约净利率环比 ,
            CASE WHEN CASE WHEN ISNULL(b.上月本年签约净利率, 0) = 0 THEN 0 ELSE (ISNULL(a.本年签约净利率, 0) - ISNULL(b.上月本年签约净利率, 0) ) / ISNULL(b.上月本年签约净利率, 0)END  > 0 THEN '提升' ELSE '下降' END AS 提升或下降_净利率 ,
            a.月度回笼目标 ,
            a.本月回笼完成 ,
            a.本月回笼完成率 ,

            a.年度回笼目标 ,
            a.本年回笼完成 ,
            a.本年回笼完成率,
			--a.本月年度回笼任务按时间分摊比例,
			--b.上月年度回笼任务按时间分摊比例,
			b.上月年度回笼金额,
            b.上月年度回笼任务 ,			
            CASE WHEN  ISNULL(b.上月年度回笼完成率,0) =0  THEN  0  ELSE  (ISNULL(a.本月年度回笼完成率,0) -ISNULL(b.上月年度回笼完成率,0)) / ISNULL(b.上月年度回笼完成率,0) END  AS 回笼环比上月与时间进度变化,
			CASE WHEN  CASE WHEN  ISNULL(b.上月年度回笼完成率,0) =0  THEN  0  ELSE  (ISNULL(a.本月年度回笼完成率,0) -ISNULL(b.上月年度回笼完成率,0)) / ISNULL(b.上月年度回笼完成率,0) END > 0 THEN    '扩大' ELSE  '缩小' END  扩大或缩小_本年回笼完成率,
			a.待收款金额,
			a.本年签约本年回笼 ,
			a.年初待收款,
			a.年初待收款回笼,
            CASE WHEN  (ISNULL(a.年初待收款,0)+ISNULL(a.本年完成,0)) =0  THEN  0  ELSE   (ISNULL(a.本年签约本年回笼,0)+ ISNULL(年初待收款回笼,0 )) / (ISNULL(a.年初待收款,0)+ISNULL(a.本年完成,0)) END  AS   综合回笼率,
			CASE WHEN  ISNULL(a.本年完成,0)  =0 THEN  0 ELSE  ISNULL(本年签约本年回笼,0)  / ISNULL(a.本年完成,0) END  AS  新签约回笼率,
			CASE WHEN  ISNULL(a.年初待收款,0) =0  THEN 0  ELSE  ISNULL(a.年初待收款回笼,0) /ISNULL(a.年初待收款,0)   END   AS  待收款回笼率
    into  #CityMonthSale
    FROM    #MonthSale a
            left  JOIN #lastMonthSale b ON a.平台公司GUID = b.平台公司GUID AND a.城市公司 = b.城市公司 and  datediff(month,b.清洗时间,a.清洗时间) =1
    -- 公司整体
    UNION ALL
		SELECT  a.清洗时间 as 清洗时间,
                NULL AS 排序 ,
		        NULL AS 待收款回笼率排序,
				NULL AS 新签回笼率排序,
				CONVERT(VARCHAR(10), MONTH(a.清洗时间)) + '月' AS 月份 ,
				CONVERT(VARCHAR(10), DAY(a.清洗时间)) + '日' AS 日期 ,
				a.平台公司名称 ,
				a.平台公司GUID ,
				'公司整体' AS 城市公司 ,
				SUM(ISNULL(a.月度去化目标, 0)) AS 月度去化目标 ,
				SUM(ISNULL(a.本月完成, 0)) AS 本月完成 ,
				CASE WHEN SUM(ISNULL(a.月度去化目标, 0)) = 0 THEN 0 ELSE SUM(ISNULL(a.本月完成, 0)) / SUM(ISNULL(a.本月完成, 0))END AS 本月完成率 ,
				SUM(ISNULL(a.年度去化目标, 0)) AS 年度去化目标 ,
				SUM(ISNULL(a.本年完成, 0)) AS 本年完成 ,
				CASE WHEN SUM(ISNULL(a.年度去化目标, 0)) = 0 THEN 0 ELSE SUM(ISNULL(a.本年完成, 0)) / SUM(ISNULL(a.年度去化目标, 0))END AS 本年完成率 ,
				--SUM(ISNULL(a.本月年度去化目标按时间分摊比例, 0)) AS 本月年度去化目标按时间分摊比例 ,
				--SUM(ISNULL(b.上月年度签约任务按时间分摊比例, 0)) AS 上月年度签约任务按时间分摊比例 ,
				SUM(ISNULL(b.上月年度签约金额, 0)) AS 上月年度签约金额 ,
                CASE WHEN
				    (CASE WHEN SUM(ISNULL(b.上月本年销售净利润账面, 0)) = 0 THEN 0 ELSE SUM(ISNULL(b.上月本年签约金额不含税, 0)) / SUM(ISNULL(b.上月本年销售净利润账面, 0))END) =0 then 0 
				ELSE  
					(  CASE WHEN SUM(ISNULL(b.上月本年销售净利润账面, 0)) = 0 THEN 0 ELSE SUM(ISNULL(b.上月本年签约金额不含税, 0)) / SUM(ISNULL(b.上月本年销售净利润账面, 0)) END
					   - CASE WHEN SUM(ISNULL(a.本年签约金额不含税, 0)) = 0 THEN 0 ELSE SUM(ISNULL(a.本年销售净利润账面, 0)) / SUM(ISNULL(a.本年签约金额不含税, 0)) END ) / 
					CASE WHEN SUM(ISNULL(b.上月本年销售净利润账面, 0)) = 0 THEN 0 ELSE SUM(ISNULL(b.上月本年签约金额不含税, 0)) / SUM(ISNULL(b.上月本年销售净利润账面, 0))END  
				END AS 环比上月与时间进度变化 ,-- (上月末-本月)/上月末
				SUM(ISNULL(a.本年签约金额不含税, 0)) AS 本年签约金额不含税 ,
				SUM(ISNULL(a.本年销售净利润账面, 0)) AS 本年销售净利润账面 ,
				CASE WHEN SUM(ISNULL(a.本年签约金额不含税, 0)) = 0 THEN 0 ELSE SUM(ISNULL(a.本年销售净利润账面, 0)) / SUM(ISNULL(a.本年签约金额不含税, 0))END AS 本年签约净利率 ,

				SUM(ISNULL(b.上月本年签约金额不含税, 0)) AS 上月本年签约金额不含税 ,
				SUM(ISNULL(b.上月本年销售净利润账面, 0)) AS 上月本年销售净利润账面 ,
				CASE WHEN SUM(ISNULL(b.上月本年销售净利润账面, 0)) = 0 THEN 0 ELSE SUM(ISNULL(b.上月本年签约金额不含税, 0)) / SUM(ISNULL(b.上月本年销售净利润账面, 0))END AS 上月本年签约净利率 ,
				NULL AS 本年签约净利率环比 ,
				NULL AS 提升或下降_净利率 ,
				SUM(ISNULL(a.月度回笼目标, 0)) AS 月度回笼目标 ,
				SUM(ISNULL(a.本月回笼完成, 0)) AS 本月回笼完成 ,
				CASE WHEN SUM(ISNULL(a.月度回笼目标, 0)) = 0 THEN 0 ELSE SUM(ISNULL(a.本月回笼完成, 0)) / SUM(ISNULL(a.月度回笼目标, 0))END AS 本月回笼完成率 ,
				SUM(ISNULL(a.年度回笼目标, 0)) AS 年度回笼目标 ,
				SUM(ISNULL(a.本年回笼完成, 0)) AS 本年回笼完成 ,
				CASE WHEN SUM(ISNULL(a.年度回笼目标, 0)) = 0 THEN 0 ELSE SUM(ISNULL(a.本年回笼完成, 0)) / SUM(ISNULL(a.年度回笼目标, 0))END AS 本年回笼完成率,
			    --SUM(ISNULL(a.本月年度回笼任务按时间分摊比例,0)) AS 本月年度回笼任务按时间分摊比例,
			    --SUM(ISNULL(b.上月年度回笼任务按时间分摊比例,0)) AS 上月年度回笼任务按时间分摊比例,
			    SUM(ISNULL(b.上月年度回笼金额,0)) AS 上月年度回笼金额 ,
                sum(isnull(b.上月年度回笼任务,0)) as 上月年度回笼任务,
				case  when  
				     CASE WHEN SUM(ISNULL(b.上月年度回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(上月年度回笼金额, 0)) / SUM(ISNULL(b.上月年度回笼任务, 0))  END  =0  then  0
			    else  
				     ( CASE WHEN SUM(ISNULL(b.上月年度回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(上月年度回笼金额, 0)) / SUM(ISNULL(b.上月年度回笼任务, 0))  END
				     - CASE WHEN SUM(ISNULL(a.年度回笼目标, 0)) = 0 THEN 0 ELSE SUM(ISNULL(a.本年回笼完成, 0)) / SUM(ISNULL(a.年度回笼目标, 0))END ) 
				     / CASE WHEN SUM(ISNULL(b.上月年度回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(上月年度回笼金额, 0)) / SUM(ISNULL(b.上月年度回笼任务, 0))  END
				end as 回笼环比上月与时间进度变化, -- (上月末-本月)/上月末
				CASE WHEN  
				  (				
				   case  when  
				     CASE WHEN SUM(ISNULL(b.上月年度回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(上月年度回笼金额, 0)) / SUM(ISNULL(b.上月年度回笼任务, 0))  END  =0  then  0
			       else  
				     ( CASE WHEN SUM(ISNULL(b.上月年度回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(上月年度回笼金额, 0)) / SUM(ISNULL(b.上月年度回笼任务, 0))  END
				     - CASE WHEN SUM(ISNULL(a.年度回笼目标, 0)) = 0 THEN 0 ELSE SUM(ISNULL(a.本年回笼完成, 0)) / SUM(ISNULL(a.年度回笼目标, 0))END ) 
				     / CASE WHEN SUM(ISNULL(b.上月年度回笼任务, 0)) = 0 THEN 0 ELSE SUM(ISNULL(上月年度回笼金额, 0)) / SUM(ISNULL(b.上月年度回笼任务, 0))  END
				   end  ) > 0  THEN  '扩大' ELSE  '缩小' END  扩大或缩小_本年回笼完成率,	
				SUM(isnull(a.待收款金额,0)) AS 待收款金额,
				sum(isnull(a.本年签约本年回笼,0)) AS 本年签约本年回笼 ,
				sum(isnull(a.年初待收款,0)) AS 年初待收款,
				sum(isnull(a.年初待收款回笼,0)) AS 	年初待收款回笼,
				CASE WHEN  SUM(ISNULL(a.年初待收款,0)+ISNULL(a.本年完成,0)) =0  THEN  0 
                 ELSE   SUM(ISNULL(a.本年签约本年回笼,0)+ ISNULL(年初待收款回笼,0 )) / SUM(ISNULL(a.年初待收款,0)+ISNULL(a.本年完成,0)) END  AS   综合回笼率,
				CASE WHEN  sum(ISNULL(a.本年完成,0))  =0 THEN  0 ELSE  SUM(ISNULL(本年签约本年回笼,0))  / SUM(ISNULL(a.本年完成,0))  END  AS  新签约回笼率,
				CASE WHEN  SUM(ISNULL(a.年初待收款,0)) =0  THEN 0  ELSE  SUM(ISNULL(a.年初待收款回笼,0)) / SUM(ISNULL(a.年初待收款,0))   END   AS  待收款回笼率
		FROM    #MonthSale a
				left  JOIN #lastMonthSale b ON a.平台公司GUID = b.平台公司GUID AND a.城市公司 = b.城市公司 and  datediff(month,b.清洗时间,a.清洗时间) =1
		GROUP BY a.清洗时间 ,
                 a.平台公司名称 ,
				 a.平台公司GUID

     --将清洗时间转换为日期型
     select convert(datetime,清洗时间) as 清洗日期, * from  #CityMonthSale            

    -- 删除临时表
    DROP TABLE #lastMonthSale ,#CityMonthSale,#MonthSale,#qxDate,#SaleTmp
END;