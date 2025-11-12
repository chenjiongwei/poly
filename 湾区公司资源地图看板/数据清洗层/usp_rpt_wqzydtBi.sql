USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_rpt_wqzydtBi]    Script Date: 2025/11/10 18:50:24 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

alter proc [dbo].[usp_rpt_wqzydtBi] as 
/*
[usp_rpt_wqzydtBi]
为了看板性能，将数据集的结果也按天存储进来
01 区域概况&经营任务_1: wqzydtBi_baseinfo_taskinfo
02 现金流情况_1: wqzydtBi_cashflowinfo
0301 公司资源情况_1：wqzydtBi_resourseinfo
0302 公司资源情况_区域：wqzydtBi_resourseinfo_area
04 产成品情况分析_1: wqzydtBi_productedinfo
05 项目销售利润情况_1: wqzydtBi_saleProfitinfo 
06 开竣工情况_1：wqzydtBi_scheduleinfo
07 产存销情况_1: wqzydtBi_product_rest
08 剩余货值分析_1: wqzydtBi_restsalevalue
11 城市片区占比情况: wqzydtBi_city_pq 
12 项目业态量价关系 s_WqBaseStatic_ProjPrice_month 
20 主控计划节点执行分析  wqzydtBi_Master_plan_node
21 组团关键节点预警分析 wqzydtBi_Keynode_Warning

成本分析模块-01项目成本分析： wqzydtBi_dtcostinfo
成本分析模块-02项目变更情况分析： wqzydtBi_costBGinfo
成本分析模块-03项目结算情况分析： wqzydtBi_costjsinfo
成本分析模块-04项目成本单方情况分析： wqzydtBi_costDfinfo

modified by lintx 20250106
1、【整盘合计-税后账面利润】=【整盘可售-税后利润】
2、【整盘合计-税后现金利润】=【整盘合计-税后账面利润】-【整盘合计-固定资产】
*/
begin

declare @date_id varchar(8) = convert(varchar(8),getdate(),112)

-------------------------01 区域概况&经营任务_1
--缓存项目/镇街/片区统计维度，通过项目的组织架构类型3来向上汇总镇街及片区的数据
select '3' as 组织架构类型, '项目' as 统计维度
into #dw01
union all 
select '3' as 组织架构类型, '镇街' as 统计维度
union all 
select '3' as 组织架构类型, '片区' as 统计维度

--预处理增量新增量的数据
SELECT org.组织架构id, org.组织架构编码,
sum(org.本月认购套数) as 本月认购套数实际完成,
sum(tr.本月认购套数任务) as 本月认购套数任务,
case when sum(tr.本月认购套数任务) =0 then 0 else sum(org.本月认购套数)*1.0/sum(tr.本月认购套数任务) end AS 本月认购套数完成率,
sum(org.本月认购面积) as 本月认购面积实际完成,
sum(tr.本月认购面积任务)/10000.0 as 本月认购面积任务,
case when sum(tr.本月认购面积任务) =0 then 0 else sum(org.本月认购面积)*10000.0/sum(tr.本月认购面积任务) end AS 本月认购面积完成率,
sum(org.本年认购套数) as 本年认购套数实际完成,
sum(tr.本年认购套数任务) as 本年认购套数任务,
case when sum(tr.本年认购套数任务) =0 then 0 else sum(org.本年认购套数)*1.0/sum(tr.本年认购套数任务) end AS 本年认购套数完成率,
sum(org.本年认购面积) as 本年认购面积实际完成,
sum(tr.本年认购面积任务)/10000.0 as 本年认购面积任务,
case when sum(tr.本年认购面积任务) =0 then 0 else sum(org.本年认购面积)*10000.0/sum(tr.本年认购面积任务) end AS 本年认购面积完成率,
sum(tr.去年认购套数) as 去年认购套数实际完成,
sum(tr.去年认购套数任务) as 去年认购套数任务,
case when sum(tr.去年认购套数任务) =0 then 0 else sum(tr.去年认购套数)*1.0/sum(tr.去年认购套数任务) end AS 去年认购套数完成率,
sum(tr.去年认购面积) /10000.0 as 去年认购面积实际完成,
sum(tr.去年认购面积任务)/10000.0 as 去年认购面积任务,
case when sum(tr.去年认购面积任务) =0 then 0 else sum(tr.去年认购面积)*10000.0/sum(tr.去年认购面积任务) end AS 去年认购面积完成率,
sum(org.本月签约套数) as 本月签约套数实际完成,
sum(tr.本月签约套数任务) as 本月签约套数任务,
case when sum(tr.本月签约套数任务) =0 then 0 else sum(org.本月签约套数)*1.0/sum(tr.本月签约套数任务) end AS 本月签约套数完成率,
sum(org.本月签约面积) as 本月签约面积实际完成,
sum(tr.本月签约面积任务)/10000.0 as 本月签约面积任务,
case when sum(tr.本月签约面积任务) =0 then 0 else sum(org.本月签约面积)*10000.0/sum(tr.本月签约面积任务) end AS 本月签约面积完成率,
sum(org.本年签约套数) as 本年签约套数实际完成,
sum(tr.本年签约套数任务) as 本年签约套数任务,
case when sum(tr.本年签约套数任务) =0 then 0 else sum(org.本年签约套数)*1.0/sum(tr.本年签约套数任务) end AS 本年签约套数完成率,
sum(org.本年签约面积) as 本年签约面积实际完成,
sum(tr.本年签约面积任务)/10000.0 as 本年签约面积任务,
case when sum(tr.本年签约面积任务) =0 then 0 else sum(org.本年签约面积)*10000.0/sum(tr.本年签约面积任务) end AS 本年签约面积完成率,
sum(tr.去年已签约套数) as 去年签约套数实际完成,
sum(tr.去年签约套数任务) as 去年签约套数任务,
case when sum(tr.去年签约套数任务) =0 then 0 else sum(tr.去年已签约套数)*1.0/sum(tr.去年签约套数任务) end AS 去年签约套数完成率,
sum(tr.去年已签约面积) /10000.0 as 去年签约面积实际完成,
sum(tr.去年签约面积任务)/10000.0 as 去年签约面积任务,
case when sum(tr.去年签约面积任务) =0 then 0 else sum(tr.去年已签约面积)*10000.0/sum(tr.去年签约面积任务) end AS 去年签约面积完成率,

--权益回笼
sum(re.本月权益回笼金额)/10000.0 as 本月权益回笼实际完成,
sum(re.本月权益回笼任务)/10000.0 as 本月权益回笼任务,
case when sum(re.本月权益回笼任务) =0 then 0 else sum(re.本月权益回笼金额)/sum(re.本月权益回笼任务) end AS 本月权益回笼完成率,  
sum(re.本年权益回笼金额)/10000.0 as 本年权益回笼实际完成,
sum(re.本年权益回笼任务)/10000.0 as 本年权益回笼任务,
case when sum(re.本年权益回笼任务) =0 then 0 else sum(re.本年权益回笼金额)/sum(re.本年权益回笼任务) end AS 本年权益回笼完成率, 
sum(re.去年权益回笼金额)/10000.0 as 去年权益回笼实际完成,
sum(re.去年权益回笼任务)/10000.0 as 去年权益回笼任务,
case when sum(re.去年权益回笼任务) =0 then 0 else sum(re.去年权益回笼金额)/sum(re.去年权益回笼任务) end AS 去年权益回笼完成率,

--营销来访情况
sum(tr.本月来访批次) as 本月来访批次,
sum(tr.本月新客来访批次) as 本月新客来访批次,
sum(tr.本月旧客来访批次) as 本月旧客来访批次, 
sum(tr.本年来访批次) as 本年来访批次,
sum(tr.本年新客来访批次) as 本年新客来访批次,
sum(tr.本年旧客来访批次) as 本年旧客来访批次,  
sum(tr.去年来访批次) as 去年来访批次,
sum(tr.去年新客来访批次) as 去年新客来访批次,
sum(tr.去年旧客来访批次) as 去年旧客来访批次,  
-----------------------------------------------------本月---------------------------------------------------
--本月认购 
sum(case when year(org.获取时间)>'2022' then org.本月认购金额 else 0 end) as 新增量本月认购实际完成,
sum(case when year(org.获取时间)>'2022' then org.本月认购任务 else 0 end) as 新增量本月认购任务,
case when sum(case when year(org.获取时间)>'2022' then org.本月认购任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本月认购金额 else 0 end)/sum(case when year(org.获取时间)>'2022' then org.本月认购任务 else 0 end) end AS 新增量本月认购完成率,
sum(case when year(org.获取时间)='2022' then org.本月认购金额 else 0 end) as 增量本月认购实际完成,
sum(case when year(org.获取时间)='2022' then org.本月认购任务 else 0 end) as 增量本月认购任务,
case when sum(case when year(org.获取时间)='2022' then org.本月认购任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本月认购金额 else 0 end)/sum(case when year(org.获取时间)='2022' then org.本月认购任务 else 0 end) end AS 增量本月认购完成率,
sum(case when year(org.获取时间)<'2022' then org.本月认购金额 else 0 end) as 存量本月认购实际完成,
sum(case when year(org.获取时间)<'2022' then org.本月认购任务 else 0 end) as 存量本月认购任务,
case when sum(case when year(org.获取时间)<'2022' then org.本月认购任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本月认购金额 else 0 end)/sum(case when year(org.获取时间)<'2022' then org.本月认购任务 else 0 end) end AS 存量本月认购完成率,

--本月认购套数
sum(case when year(org.获取时间)>'2022' then org.本月认购套数 else 0 end) as 新增量本月认购套数实际完成,
sum(case when year(org.获取时间)>'2022' then tr.本月认购套数任务 else 0 end) as 新增量本月认购套数任务,
case when sum(case when year(org.获取时间)>'2022' then tr.本月认购套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本月认购套数 else 0 end)*1.0/sum(case when year(org.获取时间)>'2022' then tr.本月认购套数任务 else 0 end) end AS 新增量本月认购套数完成率,
sum(case when year(org.获取时间)='2022' then org.本月认购套数 else 0 end) as 增量本月认购套数实际完成,
sum(case when year(org.获取时间)='2022' then tr.本月认购套数任务 else 0 end) as 增量本月认购套数任务,
case when sum(case when year(org.获取时间)='2022' then tr.本月认购套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本月认购套数 else 0 end)*1.0/sum(case when year(org.获取时间)='2022' then tr.本月认购套数任务 else 0 end) end AS 增量本月认购套数完成率,
sum(case when year(org.获取时间)<'2022' then org.本月认购套数 else 0 end) as 存量本月认购套数实际完成,
sum(case when year(org.获取时间)<'2022' then tr.本月认购套数任务 else 0 end) as 存量本月认购套数任务,
case when sum(case when year(org.获取时间)<'2022' then tr.本月认购套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本月认购套数 else 0 end)*1.0/sum(case when year(org.获取时间)<'2022' then tr.本月认购套数任务 else 0 end) end AS 存量本月认购套数完成率,
--本月认购面积
sum(case when year(org.获取时间)>'2022' then org.本月认购面积 else 0 end) as 新增量本月认购面积实际完成,
sum(case when year(org.获取时间)>'2022' then tr.本月认购面积任务 else 0 end)/10000.0 as 新增量本月认购面积任务,
case when sum(case when year(org.获取时间)>'2022' then tr.本月认购面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本月认购面积 else 0 end)/sum(case when year(org.获取时间)>'2022' then tr.本月认购面积任务 else 0 end) end*10000.0 AS 新增量本月认购面积完成率,
sum(case when year(org.获取时间)='2022' then org.本月认购面积 else 0 end) as 增量本月认购面积实际完成,
sum(case when year(org.获取时间)='2022' then tr.本月认购面积任务 else 0 end)/10000.0 as 增量本月认购面积任务,
case when sum(case when year(org.获取时间)='2022' then tr.本月认购面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本月认购面积 else 0 end)/sum(case when year(org.获取时间)='2022' then tr.本月认购面积任务 else 0 end) end*10000.0 AS 增量本月认购面积完成率,
sum(case when year(org.获取时间)<'2022' then org.本月认购面积 else 0 end) as 存量本月认购面积实际完成,
sum(case when year(org.获取时间)<'2022' then tr.本月认购面积任务 else 0 end)/10000.0 as 存量本月认购面积任务,
case when sum(case when year(org.获取时间)<'2022' then tr.本月认购面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本月认购面积 else 0 end)/sum(case when year(org.获取时间)<'2022' then tr.本月认购面积任务 else 0 end) end*10000.0 AS 存量本月认购面积完成率,

--本月签约
sum(case when year(org.获取时间)>'2022' then org.本月签约金额 else 0 end) as 新增量本月签约实际完成,
sum(case when year(org.获取时间)>'2022' then org.本月签约任务 else 0 end) as 新增量本月签约任务,
case when sum(case when year(org.获取时间)>'2022' then org.本月签约任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本月签约金额 else 0 end)/sum(case when year(org.获取时间)>'2022' then org.本月签约任务 else 0 end) end AS 新增量本月签约完成率,
sum(case when year(org.获取时间)='2022' then org.本月签约金额 else 0 end) as 增量本月签约实际完成,
sum(case when year(org.获取时间)='2022' then org.本月签约任务 else 0 end) as 增量本月签约任务,
case when sum(case when year(org.获取时间)='2022' then org.本月签约任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本月签约金额 else 0 end)/sum(case when year(org.获取时间)='2022' then org.本月签约任务 else 0 end) end AS 增量本月签约完成率,
sum(case when year(org.获取时间)<'2022' then org.本月签约金额 else 0 end) as 存量本月签约实际完成,
sum(case when year(org.获取时间)<'2022' then org.本月签约任务 else 0 end) as 存量本月签约任务,
case when sum(case when year(org.获取时间)<'2022' then org.本月签约任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本月签约金额 else 0 end)/sum(case when year(org.获取时间)<'2022' then org.本月签约任务 else 0 end) end AS 存量本月签约完成率,

--本月签约套数
sum(case when year(org.获取时间)>'2022' then org.本月签约套数 else 0 end) as 新增量本月签约套数实际完成,
sum(case when year(org.获取时间)>'2022' then tr.本月签约套数任务 else 0 end) as 新增量本月签约套数任务,
case when sum(case when year(org.获取时间)>'2022' then tr.本月签约套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本月签约套数 else 0 end)*1.0/sum(case when year(org.获取时间)>'2022' then tr.本月签约套数任务 else 0 end) end AS 新增量本月签约套数完成率,
sum(case when year(org.获取时间)='2022' then org.本月签约套数 else 0 end) as 增量本月签约套数实际完成,
sum(case when year(org.获取时间)='2022' then tr.本月签约套数任务 else 0 end) as 增量本月签约套数任务,
case when sum(case when year(org.获取时间)='2022' then tr.本月签约套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本月签约套数 else 0 end)*1.0/sum(case when year(org.获取时间)='2022' then tr.本月签约套数任务 else 0 end) end AS 增量本月签约套数完成率,
sum(case when year(org.获取时间)<'2022' then org.本月签约套数 else 0 end) as 存量本月签约套数实际完成,
sum(case when year(org.获取时间)<'2022' then tr.本月签约套数任务 else 0 end) as 存量本月签约套数任务,
case when sum(case when year(org.获取时间)<'2022' then tr.本月签约套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本月签约套数 else 0 end)*1.0/sum(case when year(org.获取时间)<'2022' then tr.本月签约套数任务 else 0 end) end AS 存量本月签约套数完成率,
--本月签约面积
sum(case when year(org.获取时间)>'2022' then org.本月签约面积 else 0 end) as 新增量本月签约面积实际完成,
sum(case when year(org.获取时间)>'2022' then tr.本月签约面积任务 else 0 end)/10000.0 as 新增量本月签约面积任务,
case when sum(case when year(org.获取时间)>'2022' then tr.本月签约面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本月签约面积 else 0 end)/sum(case when year(org.获取时间)>'2022' then tr.本月签约面积任务 else 0 end) end*10000.0 AS 新增量本月签约面积完成率,
sum(case when year(org.获取时间)='2022' then org.本月签约面积 else 0 end) as 增量本月签约面积实际完成,
sum(case when year(org.获取时间)='2022' then tr.本月签约面积任务 else 0 end)/10000.0 as 增量本月签约面积任务,
case when sum(case when year(org.获取时间)='2022' then tr.本月签约面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本月签约面积 else 0 end)/sum(case when year(org.获取时间)='2022' then tr.本月签约面积任务 else 0 end) end*10000.0 AS 增量本月签约面积完成率,
sum(case when year(org.获取时间)<'2022' then org.本月签约面积 else 0 end) as 存量本月签约面积实际完成,
sum(case when year(org.获取时间)<'2022' then tr.本月签约面积任务 else 0 end)/10000.0 as 存量本月签约面积任务,
case when sum(case when year(org.获取时间)<'2022' then tr.本月签约面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本月签约面积 else 0 end)/sum(case when year(org.获取时间)<'2022' then tr.本月签约面积任务 else 0 end) end*10000.0 AS 存量本月签约面积完成率,

--本月回笼
sum(case when year(org.获取时间)>'2022' then org.本月回笼金额 else 0 end) as 新增量本月回笼实际完成,
sum(case when year(org.获取时间)>'2022' then org.本月回笼任务 else 0 end) as 新增量本月回笼任务,
case when sum(case when year(org.获取时间)>'2022' then org.本月回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本月回笼金额 else 0 end)/sum(case when year(org.获取时间)>'2022' then org.本月回笼任务 else 0 end) end AS 新增量本月回笼完成率,
sum(case when year(org.获取时间)='2022' then org.本月回笼金额 else 0 end) as 增量本月回笼实际完成,
sum(case when year(org.获取时间)='2022' then org.本月回笼任务 else 0 end) as 增量本月回笼任务,
case when sum(case when year(org.获取时间)='2022' then org.本月回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本月回笼金额 else 0 end)/sum(case when year(org.获取时间)='2022' then org.本月回笼任务 else 0 end) end AS 增量本月回笼完成率,
sum(case when year(org.获取时间)<'2022' then org.本月回笼金额 else 0 end) as 存量本月回笼实际完成,
sum(case when year(org.获取时间)<'2022' then org.本月回笼任务 else 0 end) as 存量本月回笼任务,
case when sum(case when year(org.获取时间)<'2022' then org.本月回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本月回笼金额 else 0 end)/sum(case when year(org.获取时间)<'2022' then org.本月回笼任务 else 0 end) end AS 存量本月回笼完成率,

sum(case when year(org.获取时间)>'2022' then re.本月权益回笼金额 else 0 end)/10000.0 as 新增量本月权益回笼实际完成,
sum(case when year(org.获取时间)>'2022' then re.本月权益回笼任务 else 0 end)/10000.0 as 新增量本月权益回笼任务,
case when sum(case when year(org.获取时间)>'2022' then re.本月权益回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then re.本月权益回笼金额 else 0 end)/sum(case when year(org.获取时间)>'2022' then re.本月权益回笼任务 else 0 end) end AS 新增量本月权益回笼完成率,
sum(case when year(org.获取时间)='2022' then re.本月权益回笼金额 else 0 end)/10000.0 as 增量本月权益回笼实际完成,
sum(case when year(org.获取时间)='2022' then re.本月权益回笼任务 else 0 end)/10000.0 as 增量本月权益回笼任务,
case when sum(case when year(org.获取时间)='2022' then re.本月权益回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then re.本月权益回笼金额 else 0 end)/sum(case when year(org.获取时间)='2022' then re.本月权益回笼任务 else 0 end) end AS 增量本月权益回笼完成率,
sum(case when year(org.获取时间)<'2022' then re.本月权益回笼金额 else 0 end)/10000.0 as 存量本月权益回笼实际完成,
sum(case when year(org.获取时间)<'2022' then re.本月权益回笼任务 else 0 end)/10000.0 as 存量本月权益回笼任务,
case when sum(case when year(org.获取时间)<'2022' then re.本月权益回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then re.本月权益回笼金额 else 0 end)/sum(case when year(org.获取时间)<'2022' then re.本月权益回笼任务 else 0 end) end AS 存量本月权益回笼完成率,

--本月直投
sum(case when year(org.获取时间)>'2022' then org.本月除地价外直投发生 else 0 end) as 新增量本月直投实际完成,
sum(case when year(org.获取时间)>'2022' then org.本月除地价外直投任务 else 0 end) as 新增量本月直投任务,
case when sum(case when year(org.获取时间)>'2022' then org.本月除地价外直投任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本月除地价外直投发生 else 0 end)/sum(case when year(org.获取时间)>'2022' then org.本月除地价外直投任务 else 0 end) end AS 新增量本月直投完成率,
sum(case when year(org.获取时间)='2022' then org.本月除地价外直投发生 else 0 end) as 增量本月直投实际完成,
sum(case when year(org.获取时间)='2022' then org.本月除地价外直投任务 else 0 end) as 增量本月直投任务,
case when sum(case when year(org.获取时间)='2022' then org.本月除地价外直投任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本月除地价外直投发生 else 0 end)/sum(case when year(org.获取时间)='2022' then org.本月除地价外直投任务 else 0 end) end AS 增量本月直投完成率,
sum(case when year(org.获取时间)<'2022' then org.本月除地价外直投发生 else 0 end) as 存量本月直投实际完成,
sum(case when year(org.获取时间)<'2022' then org.本月除地价外直投任务 else 0 end) as 存量本月直投任务,
case when sum(case when year(org.获取时间)<'2022' then org.本月除地价外直投任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本月除地价外直投发生 else 0 end)/sum(case when year(org.获取时间)<'2022' then org.本月除地价外直投任务 else 0 end) end AS 存量本月直投完成率,

-----------------------------------------------------本年-----------------------------------------------------
--本年认购
sum(case when year(org.获取时间)>'2022' then org.本年认购金额 else 0 end) as 新增量本年认购实际完成,
sum(case when year(org.获取时间)>'2022' then org.本年认购任务 else 0 end) as 新增量本年认购任务,
case when sum(case when year(org.获取时间)>'2022' then org.本年认购任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本年认购金额 else 0 end)/sum(case when year(org.获取时间)>'2022' then org.本年认购任务 else 0 end) end AS 新增量本年认购完成率,
sum(case when year(org.获取时间)='2022' then org.本年认购金额 else 0 end) as 增量本年认购实际完成,
sum(case when year(org.获取时间)='2022' then org.本年认购任务 else 0 end) as 增量本年认购任务,
case when sum(case when year(org.获取时间)='2022' then org.本年认购任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本年认购金额 else 0 end)/sum(case when year(org.获取时间)='2022' then org.本年认购任务 else 0 end) end AS 增量本年认购完成率,
sum(case when year(org.获取时间)<'2022' then org.本年认购金额 else 0 end) as 存量本年认购实际完成,
sum(case when year(org.获取时间)<'2022' then org.本年认购任务 else 0 end) as 存量本年认购任务,
case when sum(case when year(org.获取时间)<'2022' then org.本年认购任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本年认购金额 else 0 end)/sum(case when year(org.获取时间)<'2022' then org.本年认购任务 else 0 end) end AS 存量本年认购完成率,

 --本年认购套数
sum(case when year(org.获取时间)>'2022' then org.本年认购套数 else 0 end) as 新增量本年认购套数实际完成,
sum(case when year(org.获取时间)>'2022' then tr.本年认购套数任务 else 0 end) as 新增量本年认购套数任务,
case when sum(case when year(org.获取时间)>'2022' then tr.本年认购套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本年认购套数 else 0 end)*1.0/sum(case when year(org.获取时间)>'2022' then tr.本年认购套数任务 else 0 end) end AS 新增量本年认购套数完成率,
sum(case when year(org.获取时间)='2022' then org.本年认购套数 else 0 end) as 增量本年认购套数实际完成,
sum(case when year(org.获取时间)='2022' then tr.本年认购套数任务 else 0 end) as 增量本年认购套数任务,
case when sum(case when year(org.获取时间)='2022' then tr.本年认购套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本年认购套数 else 0 end)*1.0/sum(case when year(org.获取时间)='2022' then tr.本年认购套数任务 else 0 end) end AS 增量本年认购套数完成率,
sum(case when year(org.获取时间)<'2022' then org.本年认购套数 else 0 end) as 存量本年认购套数实际完成,
sum(case when year(org.获取时间)<'2022' then tr.本年认购套数任务 else 0 end) as 存量本年认购套数任务,
case when sum(case when year(org.获取时间)<'2022' then tr.本年认购套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本年认购套数 else 0 end)*1.0/sum(case when year(org.获取时间)<'2022' then tr.本年认购套数任务 else 0 end) end AS 存量本年认购套数完成率,
--本年认购面积
sum(case when year(org.获取时间)>'2022' then org.本年认购面积 else 0 end) as 新增量本年认购面积实际完成,
sum(case when year(org.获取时间)>'2022' then tr.本年认购面积任务 else 0 end)/10000.0 as 新增量本年认购面积任务,
case when sum(case when year(org.获取时间)>'2022' then tr.本年认购面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本年认购面积 else 0 end)/sum(case when year(org.获取时间)>'2022' then tr.本年认购面积任务 else 0 end) end*10000.0 AS 新增量本年认购面积完成率,
sum(case when year(org.获取时间)='2022' then org.本年认购面积 else 0 end) as 增量本年认购面积实际完成,
sum(case when year(org.获取时间)='2022' then tr.本年认购面积任务 else 0 end)/10000.0 as 增量本年认购面积任务,
case when sum(case when year(org.获取时间)='2022' then tr.本年认购面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本年认购面积 else 0 end)/sum(case when year(org.获取时间)='2022' then tr.本年认购面积任务 else 0 end) end*10000.0 AS 增量本年认购面积完成率,
sum(case when year(org.获取时间)<'2022' then org.本年认购面积 else 0 end) as 存量本年认购面积实际完成,
sum(case when year(org.获取时间)<'2022' then tr.本年认购面积任务 else 0 end)/10000.0 as 存量本年认购面积任务,
case when sum(case when year(org.获取时间)<'2022' then tr.本年认购面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本年认购面积 else 0 end)/sum(case when year(org.获取时间)<'2022' then tr.本年认购面积任务 else 0 end) end*10000.0 AS 存量本年认购面积完成率,
--本年签约
sum(case when year(org.获取时间)>'2022' then org.本年已签约金额 else 0 end) as 新增量本年签约实际完成,
sum(case when year(org.获取时间)>'2022' then org.本年签约任务 else 0 end) as 新增量本年签约任务,
case when sum(case when year(org.获取时间)>'2022' then org.本年签约任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本年已签约金额 else 0 end)/sum(case when year(org.获取时间)>'2022' then org.本年签约任务 else 0 end) end AS 新增量本年签约完成率,
sum(case when year(org.获取时间)='2022' then org.本年已签约金额 else 0 end) as 增量本年签约实际完成,
sum(case when year(org.获取时间)='2022' then org.本年签约任务 else 0 end) as 增量本年签约任务,
case when sum(case when year(org.获取时间)='2022' then org.本年签约任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本年已签约金额 else 0 end)/sum(case when year(org.获取时间)='2022' then org.本年签约任务 else 0 end) end AS 增量本年签约完成率,
sum(case when year(org.获取时间)<'2022' then org.本年已签约金额 else 0 end) as 存量本年签约实际完成,
sum(case when year(org.获取时间)<'2022' then org.本年签约任务 else 0 end) as 存量本年签约任务,
case when sum(case when year(org.获取时间)<'2022' then org.本年签约任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本年已签约金额 else 0 end)/sum(case when year(org.获取时间)<'2022' then org.本年签约任务 else 0 end) end AS 存量本年签约完成率,
 --本年签约套数
sum(case when year(org.获取时间)>'2022' then org.本年签约套数 else 0 end) as 新增量本年签约套数实际完成,
sum(case when year(org.获取时间)>'2022' then tr.本年签约套数任务 else 0 end) as 新增量本年签约套数任务,
case when sum(case when year(org.获取时间)>'2022' then tr.本年签约套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本年签约套数 else 0 end)*1.0/sum(case when year(org.获取时间)>'2022' then tr.本年签约套数任务 else 0 end) end AS 新增量本年签约套数完成率,
sum(case when year(org.获取时间)='2022' then org.本年签约套数 else 0 end) as 增量本年签约套数实际完成,
sum(case when year(org.获取时间)='2022' then tr.本年签约套数任务 else 0 end) as 增量本年签约套数任务,
case when sum(case when year(org.获取时间)='2022' then tr.本年签约套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本年签约套数 else 0 end)*1.0/sum(case when year(org.获取时间)='2022' then tr.本年签约套数任务 else 0 end) end AS 增量本年签约套数完成率,
sum(case when year(org.获取时间)<'2022' then org.本年签约套数 else 0 end) as 存量本年签约套数实际完成,
sum(case when year(org.获取时间)<'2022' then tr.本年签约套数任务 else 0 end) as 存量本年签约套数任务,
case when sum(case when year(org.获取时间)<'2022' then tr.本年签约套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本年签约套数 else 0 end)*1.0/sum(case when year(org.获取时间)<'2022' then tr.本年签约套数任务 else 0 end) end AS 存量本年签约套数完成率,
--本年签约面积
sum(case when year(org.获取时间)>'2022' then org.本年签约面积 else 0 end) as 新增量本年签约面积实际完成,
sum(case when year(org.获取时间)>'2022' then tr.本年签约面积任务 else 0 end)/10000.0 as 新增量本年签约面积任务,
case when sum(case when year(org.获取时间)>'2022' then tr.本年签约面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本年签约面积 else 0 end)/sum(case when year(org.获取时间)>'2022' then tr.本年签约面积任务 else 0 end) end*10000.0 AS 新增量本年签约面积完成率,
sum(case when year(org.获取时间)='2022' then org.本年签约面积 else 0 end) as 增量本年签约面积实际完成,
sum(case when year(org.获取时间)='2022' then tr.本年签约面积任务 else 0 end)/10000.0 as 增量本年签约面积任务,
case when sum(case when year(org.获取时间)='2022' then tr.本年签约面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本年签约面积 else 0 end)/sum(case when year(org.获取时间)='2022' then tr.本年签约面积任务 else 0 end) end*10000.0 AS 增量本年签约面积完成率,
sum(case when year(org.获取时间)<'2022' then org.本年签约面积 else 0 end) as 存量本年签约面积实际完成,
sum(case when year(org.获取时间)<'2022' then tr.本年签约面积任务 else 0 end)/10000.0 as 存量本年签约面积任务,
case when sum(case when year(org.获取时间)<'2022' then tr.本年签约面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本年签约面积 else 0 end)/sum(case when year(org.获取时间)<'2022' then tr.本年签约面积任务 else 0 end) end*10000.0 AS 存量本年签约面积完成率,
--本年回笼
sum(case when year(org.获取时间)>'2022' then org.本年回笼金额 else 0 end) as 新增量本年回笼实际完成,
sum(case when year(org.获取时间)>'2022' then org.本年回笼任务 else 0 end) as 新增量本年回笼任务,
case when sum(case when year(org.获取时间)>'2022' then org.本年回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本年回笼金额 else 0 end)/sum(case when year(org.获取时间)>'2022' then org.本年回笼任务 else 0 end) end AS 新增量本年回笼完成率,
sum(case when year(org.获取时间)='2022' then org.本年回笼金额 else 0 end) as 增量本年回笼实际完成,
sum(case when year(org.获取时间)='2022' then org.本年回笼任务 else 0 end) as 增量本年回笼任务,
case when sum(case when year(org.获取时间)='2022' then org.本年回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本年回笼金额 else 0 end)/sum(case when year(org.获取时间)='2022' then org.本年回笼任务 else 0 end) end AS 增量本年回笼完成率,
sum(case when year(org.获取时间)<'2022' then org.本年回笼金额 else 0 end) as 存量本年回笼实际完成,
sum(case when year(org.获取时间)<'2022' then org.本年回笼任务 else 0 end) as 存量本年回笼任务,
case when sum(case when year(org.获取时间)<'2022' then org.本年回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本年回笼金额 else 0 end)/sum(case when year(org.获取时间)<'2022' then org.本年回笼任务 else 0 end) end AS 存量本年回笼完成率,

sum(case when year(org.获取时间)>'2022' then re.本年权益回笼金额 else 0 end)/10000.0 as 新增量本年权益回笼实际完成,
sum(case when year(org.获取时间)>'2022' then re.本年权益回笼任务 else 0 end)/10000.0 as 新增量本年权益回笼任务,
case when sum(case when year(org.获取时间)>'2022' then re.本年权益回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then re.本年权益回笼金额 else 0 end)/sum(case when year(org.获取时间)>'2022' then re.本年权益回笼任务 else 0 end) end AS 新增量本年权益回笼完成率,
sum(case when year(org.获取时间)='2022' then re.本年权益回笼金额 else 0 end)/10000.0 as 增量本年权益回笼实际完成,
sum(case when year(org.获取时间)='2022' then re.本年权益回笼任务 else 0 end)/10000.0 as 增量本年权益回笼任务,
case when sum(case when year(org.获取时间)='2022' then re.本年权益回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then re.本年权益回笼金额 else 0 end)/sum(case when year(org.获取时间)='2022' then re.本年权益回笼任务 else 0 end) end AS 增量本年权益回笼完成率,
sum(case when year(org.获取时间)<'2022' then re.本年权益回笼金额 else 0 end)/10000.0 as 存量本年权益回笼实际完成,
sum(case when year(org.获取时间)<'2022' then re.本年权益回笼任务 else 0 end)/10000.0 as 存量本年权益回笼任务,
case when sum(case when year(org.获取时间)<'2022' then re.本年权益回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then re.本年权益回笼金额 else 0 end)/sum(case when year(org.获取时间)<'2022' then re.本年权益回笼任务 else 0 end) end AS 存量本年权益回笼完成率,
--本年直投
sum(case when year(org.获取时间)>'2022' then org.本年除地价外直投发生 else 0 end) as 新增量本年直投实际完成,
sum(case when year(org.获取时间)>'2022' then org.本年除地价外直投任务 else 0 end) as 新增量本年直投任务,
case when sum(case when year(org.获取时间)>'2022' then org.本年除地价外直投任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.本年除地价外直投发生 else 0 end)/sum(case when year(org.获取时间)>'2022' then org.本年除地价外直投任务 else 0 end) end AS 新增量本年直投完成率,
sum(case when year(org.获取时间)='2022' then org.本年除地价外直投发生 else 0 end) as 增量本年直投实际完成,
sum(case when year(org.获取时间)='2022' then org.本年除地价外直投任务 else 0 end) as 增量本年直投任务,
case when sum(case when year(org.获取时间)='2022' then org.本年除地价外直投任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.本年除地价外直投发生 else 0 end)/sum(case when year(org.获取时间)='2022' then org.本年除地价外直投任务 else 0 end) end AS 增量本年直投完成率,
sum(case when year(org.获取时间)<'2022' then org.本年除地价外直投发生 else 0 end) as 存量本年直投实际完成,
sum(case when year(org.获取时间)<'2022' then org.本年除地价外直投任务 else 0 end) as 存量本年直投任务,
case when sum(case when year(org.获取时间)<'2022' then org.本年除地价外直投任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.本年除地价外直投发生 else 0 end)/sum(case when year(org.获取时间)<'2022' then org.本年除地价外直投任务 else 0 end) end AS 存量本年直投完成率,

-----------------------------------------------------去年-----------------------------------------------------
  --去年认购 
sum(case when year(org.获取时间)>'2022' then org.去年认购金额 else 0 end) as 新增量去年认购实际完成,
sum(case when year(org.获取时间)>'2022' then org.去年认购任务 else 0 end) as 新增量去年认购任务,
case when sum(case when year(org.获取时间)>'2022' then org.去年认购任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.去年认购金额 else 0 end)/sum(case when year(org.获取时间)>'2022' then org.去年认购任务 else 0 end) end AS 新增量去年认购完成率,
sum(case when year(org.获取时间)='2022' then org.去年认购金额 else 0 end) as 增量去年认购实际完成,
sum(case when year(org.获取时间)='2022' then org.去年认购任务 else 0 end) as 增量去年认购任务,
case when sum(case when year(org.获取时间)='2022' then org.去年认购任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.去年认购金额 else 0 end)/sum(case when year(org.获取时间)='2022' then org.去年认购任务 else 0 end) end AS 增量去年认购完成率,
sum(case when year(org.获取时间)<'2022' then org.去年认购金额 else 0 end) as 存量去年认购实际完成,
sum(case when year(org.获取时间)<'2022' then org.去年认购任务 else 0 end) as 存量去年认购任务,
case when sum(case when year(org.获取时间)<'2022' then org.去年认购任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.去年认购金额 else 0 end)/sum(case when year(org.获取时间)<'2022' then org.去年认购任务 else 0 end) end AS 存量去年认购完成率,
 --去年认购套数
sum(case when year(org.获取时间)>'2022' then tr.去年认购套数 else 0 end) as 新增量去年认购套数实际完成,
sum(case when year(org.获取时间)>'2022' then tr.去年认购套数任务 else 0 end) as 新增量去年认购套数任务,
case when sum(case when year(org.获取时间)>'2022' then tr.去年认购套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then tr.去年认购套数 else 0 end)*1.0/sum(case when year(org.获取时间)>'2022' then tr.去年认购套数任务 else 0 end) end AS 新增量去年认购套数完成率,
sum(case when year(org.获取时间)='2022' then tr.去年认购套数 else 0 end) as 增量去年认购套数实际完成,
sum(case when year(org.获取时间)='2022' then tr.去年认购套数任务 else 0 end) as 增量去年认购套数任务,
case when sum(case when year(org.获取时间)='2022' then tr.去年认购套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then tr.去年认购套数 else 0 end)*1.0/sum(case when year(org.获取时间)='2022' then tr.去年认购套数任务 else 0 end) end AS 增量去年认购套数完成率,
sum(case when year(org.获取时间)<'2022' then tr.去年认购套数 else 0 end) as 存量去年认购套数实际完成,
sum(case when year(org.获取时间)<'2022' then tr.去年认购套数任务 else 0 end) as 存量去年认购套数任务,
case when sum(case when year(org.获取时间)<'2022' then tr.去年认购套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then tr.去年认购套数 else 0 end)*1.0/sum(case when year(org.获取时间)<'2022' then tr.去年认购套数任务 else 0 end) end AS 存量去年认购套数完成率,
--去年认购面积
sum(case when year(org.获取时间)>'2022' then tr.去年认购面积 else 0 end) as 新增量去年认购面积实际完成,
sum(case when year(org.获取时间)>'2022' then tr.去年认购面积任务 else 0 end)/10000.0 as 新增量去年认购面积任务,
case when sum(case when year(org.获取时间)>'2022' then tr.去年认购面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then tr.去年认购面积 else 0 end)/sum(case when year(org.获取时间)>'2022' then tr.去年认购面积任务 else 0 end) end*10000.0 AS 新增量去年认购面积完成率,
sum(case when year(org.获取时间)='2022' then tr.去年认购面积 else 0 end) as 增量去年认购面积实际完成,
sum(case when year(org.获取时间)='2022' then tr.去年认购面积任务 else 0 end)/10000.0 as 增量去年认购面积任务,
case when sum(case when year(org.获取时间)='2022' then tr.去年认购面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then tr.去年认购面积 else 0 end)/sum(case when year(org.获取时间)='2022' then tr.去年认购面积任务 else 0 end) end*10000.0 AS 增量去年认购面积完成率,
sum(case when year(org.获取时间)<'2022' then tr.去年认购面积 else 0 end) as 存量去年认购面积实际完成,
sum(case when year(org.获取时间)<'2022' then tr.去年认购面积任务 else 0 end)/10000.0 as 存量去年认购面积任务,
case when sum(case when year(org.获取时间)<'2022' then tr.去年认购面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then tr.去年认购面积 else 0 end)/sum(case when year(org.获取时间)<'2022' then tr.去年认购面积任务 else 0 end) end*10000.0 AS 存量去年认购面积完成率,

--去年签约
sum(case when year(org.获取时间)>'2022' then org.去年已签约金额 else 0 end) as 新增量去年签约实际完成,
sum(case when year(org.获取时间)>'2022' then org.去年签约任务 else 0 end) as 新增量去年签约任务,
case when sum(case when year(org.获取时间)>'2022' then org.去年签约任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.去年已签约金额 else 0 end)/sum(case when year(org.获取时间)>'2022' then org.去年签约任务 else 0 end) end AS 新增量去年签约完成率,
sum(case when year(org.获取时间)='2022' then org.去年已签约金额 else 0 end) as 增量去年签约实际完成,
sum(case when year(org.获取时间)='2022' then org.去年签约任务 else 0 end) as 增量去年签约任务,
case when sum(case when year(org.获取时间)='2022' then org.去年签约任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.去年已签约金额 else 0 end)/sum(case when year(org.获取时间)='2022' then org.去年签约任务 else 0 end) end AS 增量去年签约完成率,
sum(case when year(org.获取时间)<'2022' then org.去年已签约金额 else 0 end) as 存量去年签约实际完成,
sum(case when year(org.获取时间)<'2022' then org.去年签约任务 else 0 end) as 存量去年签约任务,
case when sum(case when year(org.获取时间)<'2022' then org.去年签约任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.去年已签约金额 else 0 end)/sum(case when year(org.获取时间)<'2022' then org.去年签约任务 else 0 end) end AS 存量去年签约完成率,

--去年签约套数
sum(case when year(org.获取时间)>'2022' then tr.去年已签约套数 else 0 end) as 新增量去年签约套数实际完成,
sum(case when year(org.获取时间)>'2022' then tr.去年签约套数任务 else 0 end) as 新增量去年签约套数任务,
case when sum(case when year(org.获取时间)>'2022' then tr.去年签约套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then tr.去年已签约套数 else 0 end)*1.0/sum(case when year(org.获取时间)>'2022' then tr.去年签约套数任务 else 0 end) end AS 新增量去年签约套数完成率,
sum(case when year(org.获取时间)='2022' then tr.去年已签约套数 else 0 end) as 增量去年签约套数实际完成,
sum(case when year(org.获取时间)='2022' then tr.去年签约套数任务 else 0 end) as 增量去年签约套数任务,
case when sum(case when year(org.获取时间)='2022' then tr.去年签约套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then tr.去年已签约套数 else 0 end)*1.0/sum(case when year(org.获取时间)='2022' then tr.去年签约套数任务 else 0 end) end AS 增量去年签约套数完成率,
sum(case when year(org.获取时间)<'2022' then tr.去年已签约套数 else 0 end) as 存量去年签约套数实际完成,
sum(case when year(org.获取时间)<'2022' then tr.去年签约套数任务 else 0 end) as 存量去年签约套数任务,
case when sum(case when year(org.获取时间)<'2022' then tr.去年签约套数任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then tr.去年已签约套数 else 0 end)*1.0/sum(case when year(org.获取时间)<'2022' then tr.去年签约套数任务 else 0 end) end AS 存量去年签约套数完成率,
--去年签约面积
sum(case when year(org.获取时间)>'2022' then tr.去年已签约面积 else 0 end) as 新增量去年签约面积实际完成,
sum(case when year(org.获取时间)>'2022' then tr.去年签约面积任务 else 0 end)/10000.0 as 新增量去年签约面积任务,
case when sum(case when year(org.获取时间)>'2022' then tr.去年签约面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then tr.去年已签约面积 else 0 end)/sum(case when year(org.获取时间)>'2022' then tr.去年签约面积任务 else 0 end) end*10000.0 AS 新增量去年签约面积完成率,
sum(case when year(org.获取时间)='2022' then tr.去年已签约面积 else 0 end) as 增量去年签约面积实际完成,
sum(case when year(org.获取时间)='2022' then tr.去年签约面积任务 else 0 end)/10000.0 as 增量去年签约面积任务,
case when sum(case when year(org.获取时间)='2022' then tr.去年签约面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then tr.去年已签约面积 else 0 end)/sum(case when year(org.获取时间)='2022' then tr.去年签约面积任务 else 0 end) end*10000.0 AS 增量去年签约面积完成率,
sum(case when year(org.获取时间)<'2022' then tr.去年已签约面积 else 0 end) as 存量去年签约面积实际完成,
sum(case when year(org.获取时间)<'2022' then tr.去年签约面积任务 else 0 end)/10000.0 as 存量去年签约面积任务,
case when sum(case when year(org.获取时间)<'2022' then tr.去年签约面积任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then tr.去年已签约面积 else 0 end)/sum(case when year(org.获取时间)<'2022' then tr.去年签约面积任务 else 0 end) end*10000.0 AS 存量去年签约面积完成率,

--去年回笼
sum(case when year(org.获取时间)>'2022' then org.去年回笼金额 else 0 end) as 新增量去年回笼实际完成,
sum(case when year(org.获取时间)>'2022' then org.去年回笼任务 else 0 end) as 新增量去年回笼任务,
case when sum(case when year(org.获取时间)>'2022' then org.去年回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.去年回笼金额 else 0 end)/sum(case when year(org.获取时间)>'2022' then org.去年回笼任务 else 0 end) end AS 新增量去年回笼完成率,
sum(case when year(org.获取时间)='2022' then org.去年回笼金额 else 0 end) as 增量去年回笼实际完成,
sum(case when year(org.获取时间)='2022' then org.去年回笼任务 else 0 end) as 增量去年回笼任务,
case when sum(case when year(org.获取时间)='2022' then org.去年回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.去年回笼金额 else 0 end)/sum(case when year(org.获取时间)='2022' then org.去年回笼任务 else 0 end) end AS 增量去年回笼完成率,
sum(case when year(org.获取时间)<'2022' then org.去年回笼金额 else 0 end) as 存量去年回笼实际完成,
sum(case when year(org.获取时间)<'2022' then org.去年回笼任务 else 0 end) as 存量去年回笼任务,
case when sum(case when year(org.获取时间)<'2022' then org.去年回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.去年回笼金额 else 0 end)/sum(case when year(org.获取时间)<'2022' then org.去年回笼任务 else 0 end) end AS 存量去年回笼完成率,

sum(case when year(org.获取时间)>'2022' then re.去年权益回笼金额 else 0 end)/10000.0 as 新增量去年权益回笼实际完成,
sum(case when year(org.获取时间)>'2022' then re.去年权益回笼任务 else 0 end)/10000.0 as 新增量去年权益回笼任务,
case when sum(case when year(org.获取时间)>'2022' then re.去年权益回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then re.去年权益回笼金额 else 0 end)/sum(case when year(org.获取时间)>'2022' then re.去年权益回笼任务 else 0 end) end AS 新增量去年权益回笼完成率,
sum(case when year(org.获取时间)='2022' then re.去年权益回笼金额 else 0 end)/10000.0 as 增量去年权益回笼实际完成,
sum(case when year(org.获取时间)='2022' then re.去年权益回笼任务 else 0 end)/10000.0 as 增量去年权益回笼任务,
case when sum(case when year(org.获取时间)='2022' then re.去年权益回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then re.去年权益回笼金额 else 0 end)/sum(case when year(org.获取时间)='2022' then re.去年权益回笼任务 else 0 end) end AS 增量去年权益回笼完成率,
sum(case when year(org.获取时间)<'2022' then re.去年权益回笼金额 else 0 end)/10000.0 as 存量去年权益回笼实际完成,
sum(case when year(org.获取时间)<'2022' then re.去年权益回笼任务 else 0 end)/10000.0 as 存量去年权益回笼任务,
case when sum(case when year(org.获取时间)<'2022' then re.去年权益回笼任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then re.去年权益回笼金额 else 0 end)/sum(case when year(org.获取时间)<'2022' then re.去年权益回笼任务 else 0 end) end AS 存量去年权益回笼完成率,
--去年直投 
sum(case when year(org.获取时间)>'2022' then org.去年除地价外直投发生 else 0 end) as 新增量去年直投实际完成,
sum(case when year(org.获取时间)>'2022' then org.去年除地价外直投任务 else 0 end) as 新增量去年直投任务,
case when sum(case when year(org.获取时间)>'2022' then org.去年除地价外直投任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)>'2022' then org.去年除地价外直投发生 else 0 end)/sum(case when year(org.获取时间)>'2022' then org.去年除地价外直投任务 else 0 end) end AS 新增量去年直投完成率,
sum(case when year(org.获取时间)='2022' then org.去年除地价外直投发生 else 0 end) as 增量去年直投实际完成,
sum(case when year(org.获取时间)='2022' then org.去年除地价外直投任务 else 0 end) as 增量去年直投任务,
case when sum(case when year(org.获取时间)='2022' then org.去年除地价外直投任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)='2022' then org.去年除地价外直投发生 else 0 end)/sum(case when year(org.获取时间)='2022' then org.去年除地价外直投任务 else 0 end) end AS 增量去年直投完成率,
sum(case when year(org.获取时间)<'2022' then org.去年除地价外直投发生 else 0 end) as 存量去年直投实际完成,
sum(case when year(org.获取时间)<'2022' then org.去年除地价外直投任务 else 0 end) as 存量去年直投任务,
case when sum(case when year(org.获取时间)<'2022' then org.去年除地价外直投任务 else 0 end) =0 then 0 else 
sum(case when year(org.获取时间)<'2022' then org.去年除地价外直投发生 else 0 end)/sum(case when year(org.获取时间)<'2022' then org.去年除地价外直投任务 else 0 end) end AS 存量去年直投完成率
INTO #zlcl
FROM s_WqBaseStatic_summary org 
left join dw_s_WqBaseStatic_tradeInfo tr on org.组织架构id = tr.组织架构id and org.清洗时间id = tr.清洗时间id
left join dw_s_WqBaseStatic_returnInfo re on org.组织架构id = re.组织架构id and org.清洗时间id = re.清洗时间id
WHERE  org.清洗时间id = @date_id and org.平台公司名称 = '湾区公司' AND org.组织架构类型 =3
GROUP BY org.组织架构id, org.组织架构编码 

--预处理增量存量的数据，向上汇总
INSERT INTO #zlcl
SELECT org.组织架构id,org.组织架构编码,
sum(本月认购套数实际完成) as 本月认购套数实际完成,
sum(本月认购套数任务) as 本月认购套数任务,
case when sum(本月认购套数任务) =0 then 0 else sum(本月认购套数)/sum(本月认购套数任务) end AS 本月认购套数完成率,
sum(本月认购面积实际完成) as 本月认购面积实际完成,
sum(本月认购面积任务) as 本月认购面积任务,
case when sum(本月认购面积任务) =0 then 0 else sum(本月认购面积实际完成)/sum(本月认购面积任务) end AS 本月认购面积完成率,
sum(本年认购套数实际完成) as 本年认购套数实际完成,
sum(本年认购套数任务) as 本年认购套数任务,
case when sum(本年认购套数任务) =0 then 0 else sum(本年认购套数实际完成)*1.0/sum(本年认购套数任务) end AS 本年认购套数完成率,
sum(本年认购面积实际完成) as 本年认购面积实际完成,
sum(本年认购面积任务) as 本年认购面积任务,
case when sum(本年认购面积任务) =0 then 0 else sum(本年认购面积实际完成)/sum(本年认购面积任务) end AS 本年认购面积完成率,
sum(去年认购套数实际完成) as 去年认购套数实际完成,
sum(去年认购套数任务) as 去年认购套数任务,
case when sum(去年认购套数任务) =0 then 0 else sum(去年认购套数实际完成)*1.0/sum(去年认购套数任务) end AS 去年认购套数完成率,
sum(去年认购面积实际完成) as 去年认购面积实际完成,
sum(去年认购面积任务) as 去年认购面积任务,
case when sum(去年认购面积任务) =0 then 0 else sum(去年认购面积任务)/sum(去年认购面积任务) end AS 去年认购面积完成率,
sum(本月签约套数实际完成) as 本月签约套数实际完成,
sum(本月签约套数任务) as 本月签约套数任务,
case when sum(本月签约套数任务) =0 then 0 else sum(本月签约套数实际完成)*1.0/sum(本月签约套数任务) end AS 本月签约套数完成率,
sum(本月签约面积实际完成) as 本月签约面积实际完成,
sum(本月签约面积任务) as 本月签约面积任务,
case when sum(本月签约面积任务) =0 then 0 else sum(本月签约面积实际完成)/sum(本月签约面积任务) end AS 本月签约面积完成率,
sum(本年签约套数实际完成) as 本年签约套数实际完成,
sum(本年签约套数任务) as 本年签约套数任务,
case when sum(本年签约套数任务) =0 then 0 else sum(本年签约套数实际完成)*1.0/sum(本年签约套数任务) end AS 本年签约套数完成率,
sum(本年签约面积实际完成) as 本年签约面积实际完成,
sum(本年签约面积任务) as 本年签约面积任务,
case when sum(本年签约面积任务) =0 then 0 else sum(本年签约面积实际完成)/sum(本年签约面积任务) end AS 本年签约面积完成率,
sum(去年签约套数实际完成) as 去年签约套数实际完成,
sum(去年签约套数任务) as 去年签约套数任务,
case when sum(去年签约套数任务) =0 then 0 else sum(去年签约套数实际完成)*1.0/sum(去年签约套数任务) end AS 去年签约套数完成率,
sum(去年签约面积实际完成) as 去年签约面积实际完成,
sum(去年签约面积任务) as 去年签约面积任务,
case when sum(去年签约面积任务) =0 then 0 else sum(去年签约面积实际完成)/sum(去年签约面积任务) end AS 去年签约面积完成率,

sum(本月权益回笼实际完成) as 本月权益回笼实际完成,
sum(本月权益回笼任务) as 本月权益回笼任务,
case when sum(本月权益回笼任务) =0 then 0 else sum(本月权益回笼实际完成)/sum(本月权益回笼任务) end AS 本月权益回笼完成率,
sum(本年权益回笼实际完成) as 本年权益回笼实际完成,
sum(本年权益回笼任务) as 本年权益回笼任务,
case when sum(本年权益回笼任务) =0 then 0 else sum(本年权益回笼实际完成)/sum(本年权益回笼任务) end AS 本年权益回笼完成率, 
sum(去年权益回笼实际完成) as 去年权益回笼实际完成,
sum(去年权益回笼任务) as 去年权益回笼任务,
case when sum(去年权益回笼任务) =0 then 0 else sum(去年权益回笼实际完成)/sum(去年权益回笼任务) end AS 去年权益回笼完成率,  

--营销来访情况
sum(本月来访批次) as 本月来访批次,
sum(本月新客来访批次) as 本月新客来访批次,
sum(本月旧客来访批次) as 本月旧客来访批次, 
sum(本年来访批次) as 本年来访批次,
sum(本年新客来访批次) as 本年新客来访批次,
sum(本年旧客来访批次) as 本年旧客来访批次,  
sum(去年来访批次) as 去年来访批次,
sum(去年新客来访批次) as 去年新客来访批次,
sum(去年旧客来访批次) as 去年旧客来访批次,  
--本月认购 
sum(isnull(新增量本月认购实际完成,0)) as 新增量本月认购实际完成,
sum(isnull(新增量本月认购任务,0)) as 新增量本月认购任务,
case when sum(isnull(新增量本月认购任务,0)) =0 then 0 else sum(isnull(新增量本月认购实际完成,0))/sum(isnull(新增量本月认购任务,0)) end AS 新增量本月认购完成率,
sum(isnull(增量本月认购实际完成,0)) as 增量本月认购实际完成,
sum(isnull(增量本月认购任务,0)) as 增量本月认购任务,
case when sum(isnull(增量本月认购任务,0)) =0 then 0 else sum(isnull(增量本月认购实际完成,0))/sum(isnull(增量本月认购任务,0)) end AS 增量本月认购完成率,
sum(isnull(存量本月认购实际完成,0)) as 存量本月认购实际完成,
sum(isnull(存量本月认购任务,0)) as 存量本月认购任务,
case when sum(isnull(存量本月认购任务,0)) =0 then 0 else sum(isnull(存量本月认购实际完成,0))/sum(isnull(存量本月认购任务,0)) end AS 存量本月认购完成率,
--本月认购套数
sum(isnull(新增量本月认购套数实际完成,0)) as 新增量本月认购套数实际完成,
sum(isnull(新增量本月认购套数任务,0))  as 新增量本月认购套数任务,
case when sum(isnull(新增量本月认购套数任务,0)) =0 then 0 else sum(isnull(新增量本月认购套数实际完成,0))*1.0/sum(isnull(新增量本月认购套数任务,0)) end AS 新增量本月认购套数完成率, 
sum(isnull(增量本月认购套数实际完成,0)) as 增量本月认购套数实际完成,
sum(isnull(增量本月认购套数任务,0))  as 增量本月认购套数任务,
case when sum(isnull(增量本月认购套数任务,0)) =0 then 0 else sum(isnull(增量本月认购套数实际完成,0))*1.0/sum(isnull(增量本月认购套数任务,0)) end AS 增量本月认购套数完成率, 
sum(isnull(存量本月认购套数实际完成,0)) as 存量本月认购套数实际完成,
sum(isnull(存量本月认购套数任务,0))  as 存量本月认购套数任务,
case when sum(isnull(存量本月认购套数任务,0)) =0 then 0 else sum(isnull(存量本月认购套数实际完成,0))*1.0/sum(isnull(存量本月认购套数任务,0)) end AS 存量本月认购套数完成率, 
--本月认购面积
sum(isnull(新增量本月认购面积实际完成,0)) as 新增量本月认购面积实际完成,
sum(isnull(新增量本月认购面积任务,0))  as 新增量本月认购面积任务,
case when sum(isnull(新增量本月认购面积任务,0)) =0 then 0 else sum(isnull(新增量本月认购面积实际完成,0))/sum(isnull(新增量本月认购面积任务,0)) end AS 新增量本月认购面积完成率, 
sum(isnull(增量本月认购面积实际完成,0)) as 增量本月认购面积实际完成,
sum(isnull(增量本月认购面积任务,0))  as 增量本月认购面积任务,
case when sum(isnull(增量本月认购面积任务,0)) =0 then 0 else sum(isnull(增量本月认购面积实际完成,0))/sum(isnull(增量本月认购面积任务,0)) end AS 增量本月认购面积完成率, 
sum(isnull(存量本月认购面积实际完成,0)) as 存量本月认购面积实际完成,
sum(isnull(存量本月认购面积任务,0))  as 存量本月认购面积任务,
case when sum(isnull(存量本月认购面积任务,0)) =0 then 0 else sum(isnull(存量本月认购面积实际完成,0))/sum(isnull(存量本月认购面积任务,0)) end AS 存量本月认购面积完成率, 
--本月签约 
sum(isnull(新增量本月签约实际完成,0)) as 新增量本月签约实际完成,
sum(isnull(新增量本月签约任务,0)) as 新增量本月签约任务,
case when sum(isnull(新增量本月签约任务,0)) =0 then 0 else sum(isnull(新增量本月签约实际完成,0))/sum(isnull(新增量本月签约任务,0)) end AS 新增量本月签约完成率,
sum(isnull(增量本月签约实际完成,0)) as 增量本月签约实际完成,
sum(isnull(增量本月签约任务,0)) as 增量本月签约任务,
case when sum(isnull(增量本月签约任务,0)) =0 then 0 else sum(isnull(增量本月签约实际完成,0))/sum(isnull(增量本月签约任务,0)) end AS 增量本月签约完成率,
sum(isnull(存量本月签约实际完成,0)) as 存量本月签约实际完成,
sum(isnull(存量本月签约任务,0)) as 存量本月签约任务,
case when sum(isnull(存量本月签约任务,0)) =0 then 0 else sum(isnull(存量本月签约实际完成,0))/sum(isnull(存量本月签约任务,0)) end AS 存量本月签约完成率,
--本月签约套数
sum(isnull(新增量本月签约套数实际完成,0)) as 新增量本月签约套数实际完成,
sum(isnull(新增量本月签约套数任务,0))  as 新增量本月签约套数任务,
case when sum(isnull(新增量本月签约套数任务,0)) =0 then 0 else sum(isnull(新增量本月签约套数实际完成,0))*1.0/sum(isnull(新增量本月签约套数任务,0)) end AS 新增量本月签约套数完成率, 
sum(isnull(增量本月签约套数实际完成,0)) as 增量本月签约套数实际完成,
sum(isnull(增量本月签约套数任务,0))  as 增量本月签约套数任务,
case when sum(isnull(增量本月签约套数任务,0)) =0 then 0 else sum(isnull(增量本月签约套数实际完成,0))*1.0/sum(isnull(增量本月签约套数任务,0)) end AS 增量本月签约套数完成率, 
sum(isnull(存量本月签约套数实际完成,0)) as 存量本月签约套数实际完成,
sum(isnull(存量本月签约套数任务,0))  as 存量本月签约套数任务,
case when sum(isnull(存量本月签约套数任务,0)) =0 then 0 else sum(isnull(存量本月签约套数实际完成,0))*1.0/sum(isnull(存量本月签约套数任务,0)) end AS 存量本月签约套数完成率, 
--本月签约面积
sum(isnull(新增量本月签约面积实际完成,0)) as 新增量本月签约面积实际完成,
sum(isnull(新增量本月签约面积任务,0))  as 新增量本月签约面积任务,
case when sum(isnull(新增量本月签约面积任务,0)) =0 then 0 else sum(isnull(新增量本月签约面积实际完成,0))/sum(isnull(新增量本月签约面积任务,0)) end AS 新增量本月签约面积完成率, 
sum(isnull(增量本月签约面积实际完成,0)) as 增量本月签约面积实际完成,
sum(isnull(增量本月签约面积任务,0))  as 增量本月签约面积任务,
case when sum(isnull(增量本月签约面积任务,0)) =0 then 0 else sum(isnull(增量本月签约面积实际完成,0))/sum(isnull(增量本月签约面积任务,0)) end AS 增量本月签约面积完成率, 
sum(isnull(存量本月签约面积实际完成,0)) as 存量本月签约面积实际完成,
sum(isnull(存量本月签约面积任务,0))  as 存量本月签约面积任务,
case when sum(isnull(存量本月签约面积任务,0)) =0 then 0 else sum(isnull(存量本月签约面积实际完成,0))/sum(isnull(存量本月签约面积任务,0)) end AS 存量本月签约面积完成率, 
--本月回笼 
sum(isnull(新增量本月回笼实际完成,0)) as 新增量本月回笼实际完成,
sum(isnull(新增量本月回笼任务,0)) as 新增量本月回笼任务,
case when sum(isnull(新增量本月回笼任务,0)) =0 then 0 else sum(isnull(新增量本月回笼实际完成,0))/sum(isnull(新增量本月回笼任务,0)) end AS 新增量本月回笼完成率,
sum(isnull(增量本月回笼实际完成,0)) as 增量本月回笼实际完成,
sum(isnull(增量本月回笼任务,0)) as 增量本月回笼任务,
case when sum(isnull(增量本月回笼任务,0)) =0 then 0 else sum(isnull(增量本月回笼实际完成,0))/sum(isnull(增量本月回笼任务,0)) end AS 增量本月回笼完成率,
sum(isnull(存量本月回笼实际完成,0)) as 存量本月回笼实际完成,
sum(isnull(存量本月回笼任务,0)) as 存量本月回笼任务,
case when sum(isnull(存量本月回笼任务,0))  =0 then 0 else sum(isnull(存量本月回笼实际完成,0)) /sum(isnull(存量本月回笼任务,0))  end AS 存量本月回笼完成率,
sum(isnull(新增量本月权益回笼实际完成,0)) as 新增量本月权益回笼实际完成,
sum(isnull(新增量本月权益回笼任务,0)) as 新增量本月权益回笼任务,
case when sum(isnull(新增量本月权益回笼任务,0)) =0 then 0 else sum(isnull(新增量本月权益回笼实际完成,0))/sum(isnull(新增量本月权益回笼任务,0)) end AS 新增量本月权益回笼完成率,
sum(isnull(增量本月权益回笼实际完成,0)) as 增量本月权益回笼实际完成,
sum(isnull(增量本月权益回笼任务,0)) as 增量本月权益回笼任务,
case when sum(isnull(增量本月权益回笼任务,0)) =0 then 0 else sum(isnull(增量本月权益回笼实际完成,0))/sum(isnull(增量本月权益回笼任务,0)) end AS 增量本月权益回笼完成率,
sum(isnull(存量本月权益回笼实际完成,0)) as 存量本月权益回笼实际完成,
sum(isnull(存量本月权益回笼任务,0)) as 存量本月权益回笼任务,
case when sum(isnull(存量本月权益回笼任务,0))  =0 then 0 else sum(isnull(存量本月权益回笼实际完成,0)) /sum(isnull(存量本月权益回笼任务,0))  end AS 存量本月权益回笼完成率,
--本月直投 
sum(isnull(新增量本月直投实际完成,0)) as 新增量本月直投实际完成,
sum(isnull(新增量本月直投任务,0))  as 新增量本月直投任务,
case when sum(isnull(新增量本月直投任务,0)) =0 then 0 else sum(isnull(新增量本月直投实际完成,0))/sum(isnull(新增量本月直投任务,0)) end AS 新增量本月直投完成率,
sum(isnull(增量本月直投实际完成,0))  as 增量本月直投实际完成,
sum(isnull(增量本月直投任务,0))  as 增量本月直投任务,
case when sum(isnull(增量本月直投任务,0)) =0 then 0 else sum(isnull(增量本月直投实际完成,0))/sum(isnull(增量本月直投任务,0)) end AS 增量本月直投完成率,
sum(isnull(存量本月直投实际完成,0))  as 存量本月直投实际完成,
sum(isnull(存量本月直投任务,0))  as 存量本月直投任务,
case when sum(isnull(存量本月直投任务,0)) =0 then 0 else sum(isnull(存量本月直投实际完成,0))/sum(isnull(存量本月直投任务,0)) end AS 存量本月直投完成率,

-----------------------------------------------------本年-----------------------------------------------------
--本年认购 
sum(isnull(新增量本年认购实际完成,0)) as 新增量本年认购实际完成,
sum(isnull(新增量本年认购任务,0)) as 新增量本年认购任务,
case when sum(isnull(新增量本年认购任务,0)) =0 then 0 else sum(isnull(新增量本年认购实际完成,0))/sum(isnull(新增量本年认购任务,0)) end AS 新增量本年认购完成率,
sum(isnull(增量本年认购实际完成,0)) as 增量本年认购实际完成,
sum(isnull(增量本年认购任务,0)) as 增量本年认购任务,
case when sum(isnull(增量本年认购任务,0)) =0 then 0 else sum(isnull(增量本年认购实际完成,0))/sum(isnull(增量本年认购任务,0)) end AS 增量本年认购完成率,
sum(isnull(存量本年认购实际完成,0)) as 存量本年认购实际完成,
sum(isnull(存量本年认购任务,0)) as 存量本年认购任务,
case when sum(isnull(存量本年认购任务,0)) =0 then 0 else sum(isnull(存量本年认购实际完成,0))/sum(isnull(存量本年认购任务,0)) end AS 存量本年认购完成率,
--本年认购套数
sum(isnull(新增量本年认购套数实际完成,0)) as 新增量本年认购套数实际完成,
sum(isnull(新增量本年认购套数任务,0))  as 新增量本年认购套数任务,
case when sum(isnull(新增量本年认购套数任务,0)) =0 then 0 else sum(isnull(新增量本年认购套数实际完成,0))*1.0/sum(isnull(新增量本年认购套数任务,0)) end AS 新增量本年认购套数完成率, 
sum(isnull(增量本年认购套数实际完成,0)) as 增量本年认购套数实际完成,
sum(isnull(增量本年认购套数任务,0))  as 增量本年认购套数任务,
case when sum(isnull(增量本年认购套数任务,0)) =0 then 0 else sum(isnull(增量本年认购套数实际完成,0))*1.0/sum(isnull(增量本年认购套数任务,0)) end AS 增量本年认购套数完成率, 
sum(isnull(存量本年认购套数实际完成,0)) as 存量本年认购套数实际完成,
sum(isnull(存量本年认购套数任务,0))  as 存量本年认购套数任务,
case when sum(isnull(存量本年认购套数任务,0)) =0 then 0 else sum(isnull(存量本年认购套数实际完成,0))*1.0/sum(isnull(存量本年认购套数任务,0)) end AS 存量本年认购套数完成率, 
--本年认购面积
sum(isnull(新增量本年认购面积实际完成,0)) as 新增量本年认购面积实际完成,
sum(isnull(新增量本年认购面积任务,0))  as 新增量本年认购面积任务,
case when sum(isnull(新增量本年认购面积任务,0)) =0 then 0 else sum(isnull(新增量本年认购面积实际完成,0))/sum(isnull(新增量本年认购面积任务,0)) end AS 新增量本年认购面积完成率, 
sum(isnull(增量本年认购面积实际完成,0)) as 增量本年认购面积实际完成,
sum(isnull(增量本年认购面积任务,0))  as 增量本年认购面积任务,
case when sum(isnull(增量本年认购面积任务,0)) =0 then 0 else sum(isnull(增量本年认购面积实际完成,0))/sum(isnull(增量本年认购面积任务,0)) end AS 增量本年认购面积完成率, 
sum(isnull(存量本年认购面积实际完成,0)) as 存量本年认购面积实际完成,
sum(isnull(存量本年认购面积任务,0))  as 存量本年认购面积任务,
case when sum(isnull(存量本年认购面积任务,0)) =0 then 0 else sum(isnull(存量本年认购面积实际完成,0))/sum(isnull(存量本年认购面积任务,0)) end AS 存量本年认购面积完成率, 
--本年签约 
sum(isnull(新增量本年签约实际完成,0)) as 新增量本年签约实际完成,
sum(isnull(新增量本年签约任务,0)) as 新增量本年签约任务,
case when sum(isnull(新增量本年签约任务,0)) =0 then 0 else sum(isnull(新增量本年签约实际完成,0))/sum(isnull(新增量本年签约任务,0)) end AS 新增量本年签约完成率,
sum(isnull(增量本年签约实际完成,0)) as 增量本年签约实际完成,
sum(isnull(增量本年签约任务,0)) as 增量本年签约任务,
case when sum(isnull(增量本年签约任务,0)) =0 then 0 else sum(isnull(增量本年签约实际完成,0))/sum(isnull(增量本年签约任务,0)) end AS 增量本年签约完成率,
sum(isnull(存量本年签约实际完成,0)) as 存量本年签约实际完成,
sum(isnull(存量本年签约任务,0)) as 存量本年签约任务,
case when sum(isnull(存量本年签约任务,0)) =0 then 0 else sum(isnull(存量本年签约实际完成,0))/sum(isnull(存量本年签约任务,0)) end AS 存量本年签约完成率,
--本年签约套数
sum(isnull(新增量本年签约套数实际完成,0)) as 新增量本年签约套数实际完成,
sum(isnull(新增量本年签约套数任务,0))  as 新增量本年签约套数任务,
case when sum(isnull(新增量本年签约套数任务,0)) =0 then 0 else sum(isnull(新增量本年签约套数实际完成,0))*1.0/sum(isnull(新增量本年签约套数任务,0)) end AS 新增量本年签约套数完成率, 
sum(isnull(增量本年签约套数实际完成,0)) as 增量本年签约套数实际完成,
sum(isnull(增量本年签约套数任务,0))  as 增量本年签约套数任务,
case when sum(isnull(增量本年签约套数任务,0)) =0 then 0 else sum(isnull(增量本年签约套数实际完成,0))*1.0/sum(isnull(增量本年签约套数任务,0)) end AS 增量本年签约套数完成率, 
sum(isnull(存量本年签约套数实际完成,0)) as 存量本年签约套数实际完成,
sum(isnull(存量本年签约套数任务,0))  as 存量本年签约套数任务,
case when sum(isnull(存量本年签约套数任务,0)) =0 then 0 else sum(isnull(存量本年签约套数实际完成,0))*1.0/sum(isnull(存量本年签约套数任务,0)) end AS 存量本年签约套数完成率, 
--本年签约面积
sum(isnull(新增量本年签约面积实际完成,0)) as 新增量本年签约面积实际完成,
sum(isnull(新增量本年签约面积任务,0))  as 新增量本年签约面积任务,
case when sum(isnull(新增量本年签约面积任务,0)) =0 then 0 else sum(isnull(新增量本年签约面积实际完成,0))/sum(isnull(新增量本年签约面积任务,0)) end AS 新增量本年签约面积完成率, 
sum(isnull(增量本年签约面积实际完成,0)) as 增量本年签约面积实际完成,
sum(isnull(增量本年签约面积任务,0))  as 增量本年签约面积任务,
case when sum(isnull(增量本年签约面积任务,0)) =0 then 0 else sum(isnull(增量本年签约面积实际完成,0))/sum(isnull(增量本年签约面积任务,0)) end AS 增量本年签约面积完成率, 
sum(isnull(存量本年签约面积实际完成,0)) as 存量本年签约面积实际完成,
sum(isnull(存量本年签约面积任务,0))  as 存量本年签约面积任务,
case when sum(isnull(存量本年签约面积任务,0)) =0 then 0 else sum(isnull(存量本年签约面积实际完成,0))/sum(isnull(存量本年签约面积任务,0)) end AS 存量本年签约面积完成率, 
--本年回笼 
sum(isnull(新增量本年回笼实际完成,0)) as 新增量本年回笼实际完成,
sum(isnull(新增量本年回笼任务,0)) as 新增量本年回笼任务,
case when sum(isnull(新增量本年回笼任务,0)) =0 then 0 else sum(isnull(新增量本年回笼实际完成,0))/sum(isnull(新增量本年回笼任务,0)) end AS 新增量本年回笼完成率,
sum(isnull(增量本年回笼实际完成,0)) as 增量本年回笼实际完成,
sum(isnull(增量本年回笼任务,0)) as 增量本年回笼任务,
case when sum(isnull(增量本年回笼任务,0)) =0 then 0 else sum(isnull(增量本年回笼实际完成,0))/sum(isnull(增量本年回笼任务,0)) end AS 增量本年回笼完成率,
sum(isnull(存量本年回笼实际完成,0)) as 存量本年回笼实际完成,
sum(isnull(存量本年回笼任务,0)) as 存量本年回笼任务,
case when sum(isnull(存量本年回笼任务,0))  =0 then 0 else sum(isnull(存量本年回笼实际完成,0)) /sum(isnull(存量本年回笼任务,0))  end AS 存量本年回笼完成率,
sum(isnull(新增量本年权益回笼实际完成,0)) as 新增量本年权益回笼实际完成,
sum(isnull(新增量本年权益回笼任务,0)) as 新增量本年权益回笼任务,
case when sum(isnull(新增量本年权益回笼任务,0)) =0 then 0 else sum(isnull(新增量本年权益回笼实际完成,0))/sum(isnull(新增量本年权益回笼任务,0)) end AS 新增量本年权益回笼完成率,
sum(isnull(增量本年权益回笼实际完成,0)) as 增量本年权益回笼实际完成,
sum(isnull(增量本年权益回笼任务,0)) as 增量本年权益回笼任务,
case when sum(isnull(增量本年权益回笼任务,0)) =0 then 0 else sum(isnull(增量本年权益回笼实际完成,0))/sum(isnull(增量本年权益回笼任务,0)) end AS 增量本年权益回笼完成率,
sum(isnull(存量本年权益回笼实际完成,0)) as 存量本年权益回笼实际完成,
sum(isnull(存量本年权益回笼任务,0)) as 存量本年权益回笼任务,
case when sum(isnull(存量本年权益回笼任务,0))  =0 then 0 else sum(isnull(存量本年权益回笼实际完成,0)) /sum(isnull(存量本年权益回笼任务,0))  end AS 存量本年权益回笼完成率,
--本年直投 
sum(isnull(新增量本年直投实际完成,0)) as 新增量本年直投实际完成,
sum(isnull(新增量本年直投任务,0))  as 新增量本年直投任务,
case when sum(isnull(新增量本年直投任务,0)) =0 then 0 else sum(isnull(新增量本年直投实际完成,0))/sum(isnull(新增量本年直投任务,0)) end AS 新增量本年直投完成率,
sum(isnull(增量本年直投实际完成,0))  as 增量本年直投实际完成,
sum(isnull(增量本年直投任务,0))  as 增量本年直投任务,
case when sum(isnull(增量本年直投任务,0)) =0 then 0 else sum(isnull(增量本年直投实际完成,0))/sum(isnull(增量本年直投任务,0)) end AS 增量本年直投完成率,
sum(isnull(存量本年直投实际完成,0))  as 存量本年直投实际完成,
sum(isnull(存量本年直投任务,0))  as 存量本年直投任务,
case when sum(isnull(存量本年直投任务,0)) =0 then 0 else sum(isnull(存量本年直投实际完成,0))/sum(isnull(存量本年直投任务,0)) end AS 存量本年直投完成率,

-----------------------------------------------------去年-----------------------------------------------------
--去年认购 
sum(isnull(新增量去年认购实际完成,0)) as 新增量去年认购实际完成,
sum(isnull(新增量去年认购任务,0)) as 新增量去年认购任务,
case when sum(isnull(新增量去年认购任务,0)) =0 then 0 else sum(isnull(新增量去年认购实际完成,0))/sum(isnull(新增量去年认购任务,0)) end AS 新增量去年认购完成率,
sum(isnull(增量去年认购实际完成,0)) as 增量去年认购实际完成,
sum(isnull(增量去年认购任务,0)) as 增量去年认购任务,
case when sum(isnull(增量去年认购任务,0)) =0 then 0 else sum(isnull(增量去年认购实际完成,0))/sum(isnull(增量去年认购任务,0)) end AS 增量去年认购完成率,
sum(isnull(存量去年认购实际完成,0)) as 存量去年认购实际完成,
sum(isnull(存量去年认购任务,0)) as 存量去年认购任务,
case when sum(isnull(存量去年认购任务,0)) =0 then 0 else sum(isnull(存量去年认购实际完成,0))/sum(isnull(存量去年认购任务,0)) end AS 存量去年认购完成率,
--去年认购套数
sum(isnull(新增量去年认购套数实际完成,0)) as 新增量去年认购套数实际完成,
sum(isnull(新增量去年认购套数任务,0))  as 新增量去年认购套数任务,
case when sum(isnull(新增量去年认购套数任务,0)) =0 then 0 else sum(isnull(新增量去年认购套数实际完成,0))*1.0/sum(isnull(新增量去年认购套数任务,0)) end AS 新增量去年认购套数完成率, 
sum(isnull(增量去年认购套数实际完成,0)) as 增量去年认购套数实际完成,
sum(isnull(增量去年认购套数任务,0))  as 增量去年认购套数任务,
case when sum(isnull(增量去年认购套数任务,0)) =0 then 0 else sum(isnull(增量去年认购套数实际完成,0))*1.0/sum(isnull(增量去年认购套数任务,0)) end AS 增量去年认购套数完成率, 
sum(isnull(存量去年认购套数实际完成,0)) as 存量去年认购套数实际完成,
sum(isnull(存量去年认购套数任务,0))  as 存量去年认购套数任务,
case when sum(isnull(存量去年认购套数任务,0)) =0 then 0 else sum(isnull(存量去年认购套数实际完成,0))*1.0/sum(isnull(存量去年认购套数任务,0)) end AS 存量去年认购套数完成率, 
--去年认购面积
sum(isnull(新增量去年认购面积实际完成,0)) as 新增量去年认购面积实际完成,
sum(isnull(新增量去年认购面积任务,0))  as 新增量去年认购面积任务,
case when sum(isnull(新增量去年认购面积任务,0)) =0 then 0 else sum(isnull(新增量去年认购面积实际完成,0))/sum(isnull(新增量去年认购面积任务,0)) end AS 新增量去年认购面积完成率, 
sum(isnull(增量去年认购面积实际完成,0)) as 增量去年认购面积实际完成,
sum(isnull(增量去年认购面积任务,0))  as 增量去年认购面积任务,
case when sum(isnull(增量去年认购面积任务,0)) =0 then 0 else sum(isnull(增量去年认购面积实际完成,0))/sum(isnull(增量去年认购面积任务,0)) end AS 增量去年认购面积完成率, 
sum(isnull(存量去年认购面积实际完成,0)) as 存量去年认购面积实际完成,
sum(isnull(存量去年认购面积任务,0))  as 存量去年认购面积任务,
case when sum(isnull(存量去年认购面积任务,0)) =0 then 0 else sum(isnull(存量去年认购面积实际完成,0))/sum(isnull(存量去年认购面积任务,0)) end AS 存量去年认购面积完成率, 
--去年签约 
sum(isnull(新增量去年签约实际完成,0)) as 新增量去年签约实际完成,
sum(isnull(新增量去年签约任务,0)) as 新增量去年签约任务,
case when sum(isnull(新增量去年签约任务,0)) =0 then 0 else sum(isnull(新增量去年签约实际完成,0))/sum(isnull(新增量去年签约任务,0)) end AS 新增量去年签约完成率,
sum(isnull(增量去年签约实际完成,0)) as 增量去年签约实际完成,
sum(isnull(增量去年签约任务,0)) as 增量去年签约任务,
case when sum(isnull(增量去年签约任务,0)) =0 then 0 else sum(isnull(增量去年签约实际完成,0))/sum(isnull(增量去年签约任务,0)) end AS 增量去年签约完成率,
sum(isnull(存量去年签约实际完成,0)) as 存量去年签约实际完成,
sum(isnull(存量去年签约任务,0)) as 存量去年签约任务,
case when sum(isnull(存量去年签约任务,0)) =0 then 0 else sum(isnull(存量去年签约实际完成,0))/sum(isnull(存量去年签约任务,0)) end AS 存量去年签约完成率,
--去年签约套数
sum(isnull(新增量去年签约套数实际完成,0)) as 新增量去年签约套数实际完成,
sum(isnull(新增量去年签约套数任务,0))  as 新增量去年签约套数任务,
case when sum(isnull(新增量去年签约套数任务,0)) =0 then 0 else sum(isnull(新增量去年签约套数实际完成,0))*1.0/sum(isnull(新增量去年签约套数任务,0)) end AS 新增量去年签约套数完成率, 
sum(isnull(增量去年签约套数实际完成,0)) as 增量去年签约套数实际完成,
sum(isnull(增量去年签约套数任务,0))  as 增量去年签约套数任务,
case when sum(isnull(增量去年签约套数任务,0)) =0 then 0 else sum(isnull(增量去年签约套数实际完成,0))*1.0/sum(isnull(增量去年签约套数任务,0)) end AS 增量去年签约套数完成率, 
sum(isnull(存量去年签约套数实际完成,0)) as 存量去年签约套数实际完成,
sum(isnull(存量去年签约套数任务,0))  as 存量去年签约套数任务,
case when sum(isnull(存量去年签约套数任务,0)) =0 then 0 else sum(isnull(存量去年签约套数实际完成,0))*1.0/sum(isnull(存量去年签约套数任务,0)) end AS 存量去年签约套数完成率, 
--去年签约面积
sum(isnull(新增量去年签约面积实际完成,0)) as 新增量去年签约面积实际完成,
sum(isnull(新增量去年签约面积任务,0))  as 新增量去年签约面积任务,
case when sum(isnull(新增量去年签约面积任务,0)) =0 then 0 else sum(isnull(新增量去年签约面积实际完成,0))/sum(isnull(新增量去年签约面积任务,0)) end AS 新增量去年签约面积完成率, 
sum(isnull(增量去年签约面积实际完成,0)) as 增量去年签约面积实际完成,
sum(isnull(增量去年签约面积任务,0))  as 增量去年签约面积任务,
case when sum(isnull(增量去年签约面积任务,0)) =0 then 0 else sum(isnull(增量去年签约面积实际完成,0))/sum(isnull(增量去年签约面积任务,0)) end AS 增量去年签约面积完成率, 
sum(isnull(存量去年签约面积实际完成,0)) as 存量去年签约面积实际完成,
sum(isnull(存量去年签约面积任务,0))  as 存量去年签约面积任务,
case when sum(isnull(存量去年签约面积任务,0)) =0 then 0 else sum(isnull(存量去年签约面积实际完成,0))/sum(isnull(存量去年签约面积任务,0)) end AS 存量去年签约面积完成率, 
--去年回笼 
sum(isnull(新增量去年回笼实际完成,0)) as 新增量去年回笼实际完成,
sum(isnull(新增量去年回笼任务,0)) as 新增量去年回笼任务,
case when sum(isnull(新增量去年回笼任务,0)) =0 then 0 else sum(isnull(新增量去年回笼实际完成,0))/sum(isnull(新增量去年回笼任务,0)) end AS 新增量去年回笼完成率,
sum(isnull(增量去年回笼实际完成,0)) as 增量去年回笼实际完成,
sum(isnull(增量去年回笼任务,0)) as 增量去年回笼任务,
case when sum(isnull(增量去年回笼任务,0)) =0 then 0 else sum(isnull(增量去年回笼实际完成,0))/sum(isnull(增量去年回笼任务,0)) end AS 增量去年回笼完成率,
sum(isnull(存量去年回笼实际完成,0)) as 存量去年回笼实际完成,
sum(isnull(存量去年回笼任务,0)) as 存量去年回笼任务,
case when sum(isnull(存量去年回笼任务,0))  =0 then 0 else sum(isnull(存量去年回笼实际完成,0)) /sum(isnull(存量去年回笼任务,0))  end AS 存量去年回笼完成率,
sum(isnull(新增量去年权益回笼实际完成,0)) as 新增量去年权益回笼实际完成,
sum(isnull(新增量去年权益回笼任务,0)) as 新增量去年权益回笼任务,
case when sum(isnull(新增量去年权益回笼任务,0)) =0 then 0 else sum(isnull(新增量去年权益回笼实际完成,0))/sum(isnull(新增量去年权益回笼任务,0)) end AS 新增量去年权益回笼完成率,
sum(isnull(增量去年权益回笼实际完成,0)) as 增量去年权益回笼实际完成,
sum(isnull(增量去年权益回笼任务,0)) as 增量去年权益回笼任务,
case when sum(isnull(增量去年权益回笼任务,0)) =0 then 0 else sum(isnull(增量去年权益回笼实际完成,0))/sum(isnull(增量去年权益回笼任务,0)) end AS 增量去年权益回笼完成率,
sum(isnull(存量去年权益回笼实际完成,0)) as 存量去年权益回笼实际完成,
sum(isnull(存量去年权益回笼任务,0)) as 存量去年权益回笼任务,
case when sum(isnull(存量去年权益回笼任务,0))  =0 then 0 else sum(isnull(存量去年权益回笼实际完成,0)) /sum(isnull(存量去年权益回笼任务,0))  end AS 存量去年权益回笼完成率,
--去年直投 
sum(isnull(新增量去年直投实际完成,0)) as 新增量去年直投实际完成,
sum(isnull(新增量去年直投任务,0))  as 新增量去年直投任务,
case when sum(isnull(新增量去年直投任务,0)) =0 then 0 else sum(isnull(新增量去年直投实际完成,0))/sum(isnull(新增量去年直投任务,0)) end AS 新增量去年直投完成率,
sum(isnull(增量去年直投实际完成,0))  as 增量去年直投实际完成,
sum(isnull(增量去年直投任务,0))  as 增量去年直投任务,
case when sum(isnull(增量去年直投任务,0)) =0 then 0 else sum(isnull(增量去年直投实际完成,0))/sum(isnull(增量去年直投任务,0)) end AS 增量去年直投完成率,
sum(isnull(存量去年直投实际完成,0))  as 存量去年直投实际完成,
sum(isnull(存量去年直投任务,0))  as 存量去年直投任务,
case when sum(isnull(存量去年直投任务,0)) =0 then 0 else sum(isnull(存量去年直投实际完成,0))/sum(isnull(存量去年直投任务,0)) end AS 存量去年直投完成率
fROM s_WqBaseStatic_summary org 
left join #zlcl zc on charindex(org.组织架构编码,zc.组织架构编码) > 0  
where org.组织架构类型 in (1,2) AND  org.清洗时间id = @date_id AND org.平台公司名称 = '湾区公司'
GROUP BY org.组织架构id,org.组织架构编码

--清空当天数据
delete from wqzydtBi_baseinfo_taskinfo where datediff(dd,清洗时间,getdate()) = 0

--插入当天数据
insert into wqzydtBi_baseinfo_taskinfo
--获取项目/城市/公司的情况
SELECT 
org.清洗时间 as 清洗时间,
case when org.组织架构类型 = 1 then '公司'  when org.组织架构类型= 2 then '城市' else d.统计维度 end 统计维度, 
'湾区公司' 平台公司名称,
case when org.组织架构类型 = 2 then org.组织架构名称 else org.区域 end 城市,
case when org.组织架构类型 in (1,2) then null else org.销售片区 end 片区,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'') = '片区' then null else org.所属镇街 end 镇街,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'')  in ('片区','镇街') then null else org.项目推广名 end 项目名称,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'')  in ('项目') then org.组织架构名称 
when isnull(d.统计维度,'')='镇街' then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无') 
else org.区域+'_'+isnull(org.销售片区,'无') end 外键关联,
--1.1、区域概况
sum(org.项目数量) as 项目数量,
sum(org.总建筑面积) as 总建筑面积,
sum(org.动态总货值面积) as 总可售面积,
sum(org.在建项目数量_不含停工缓建) as 在建项目数量,
sum(org.在建建筑面积_不含停工缓建) as 在建建筑面积,
sum(org.存货货值面积) as 当前可售面积,	
sum(org.总计容面积) as 总计容面积,
sum(org.占地面积) as 占地面积,				
sum(org.立项货地比) as 立项货地比,		 
sum(org.动态货地比) as 动态货地比,	
--1.2、经营任务
sum(org.本年认购金额) as 本年认购金额,		
sum(org.本年认购任务) as 本年认购任务,		
case when sum(org.本年认购任务) = 0 then 0 else sum(org.本年认购金额)/ sum(org.本年认购任务) end 本年认购完成率,	
sum(org.本年已签约金额) as 本年已签约金额,
sum(org.本年签约任务) as 本年签约任务,		
case when sum(org.本年签约任务) = 0 then 0 else sum(org.本年已签约金额)/ sum(org.本年签约任务) end 本年签约完成率,	
sum(org.本年回笼金额) as 本年回笼金额,
sum(org.本年回笼任务) as 本年回笼任务,		
case when sum(org.本年回笼任务) = 0 then 0 else sum(org.本年回笼金额)/ sum(org.本年回笼任务) end 本年回笼完成率,	
sum(org.本年除地价外直投发生) as 本年除地价外直投发生,
sum(org.本年除地价外直投任务) as 本年除地价外直投任务,		
case when sum(org.本年除地价外直投任务) = 0 then 0 else sum(org.本年除地价外直投发生)/ sum(org.本年除地价外直投任务) end 本年除地价外直投使用率,	
sum(org.去年认购金额) as 去年认购金额,
sum(org.去年认购任务) as 去年认购任务,		
case when sum(org.去年认购任务) = 0 then 0 else sum(org.去年认购金额)/sum(org.去年认购任务) end 去年认购完成率,	
sum(org.去年已签约金额) as 去年已签约金额,
sum(org.去年签约任务) as 去年签约任务,		
case when sum(org.去年签约任务) = 0 then 0 else sum(org.去年已签约金额)/sum(org.去年签约任务) end 去年签约完成率,	
sum(org.去年回笼金额) as 去年回笼金额,
sum(org.去年回笼任务) as 去年回笼任务,		
case when sum(org.去年回笼任务) = 0 then 0 else sum(org.去年回笼金额)/sum(org.去年回笼任务) end 去年回笼完成率,	
sum(org.去年除地价外直投发生) as 去年除地价外直投发生,
sum(org.去年除地价外直投任务) as 去年除地价外直投任务,		
case when sum(org.去年除地价外直投任务) = 0 then 0 else sum(org.去年除地价外直投发生)/sum(org.去年除地价外直投任务) end 去年除地价外直投使用率,
--2.2资金情况
sum(org.账面可动用资金) as 账面可动用资金,		
sum(org.监控款余额) as 监控款余额,		
sum(isnull(org.贷款余额,0) -isnull(org.供应链融资余额,0)) as 贷款余额,	 --包含了供应链余额的，所以要先去掉	
sum(org.我司资金占用) as 我司资金占用 ,	
sum(org.股东投入余额) as 股东投入余额 ,		
sum(org.供应链融资余额) as 供应链融资余额 ,
--并表口径	
sum(org.账面可动用资金并表口径) as 账面可动用资金并表口径,		
sum(org.监控款余额并表口径) as 监控款余额并表口径,		
sum(isnull(org.贷款余额并表口径,0) -isnull(org.供应链融资余额并表口径,0)) as  贷款余额并表口径,		
sum(org.我司资金占用并表口径) as 我司资金占用并表口径,	
sum(org.股东投入余额并表口径) as 股东投入余额并表口径,		
sum(org.供应链融资余额并表口径) as 供应链融资余额并表口径,
--新增量、增量、存量情况
--本月认购 
sum(isnull(新增量本月认购实际完成,0)) as 新增量本月认购实际完成,
sum(isnull(新增量本月认购任务,0)) as 新增量本月认购任务,
case when sum(isnull(新增量本月认购任务,0)) =0 then 0 else sum(isnull(新增量本月认购实际完成,0))/sum(isnull(新增量本月认购任务,0)) end AS 新增量本月认购完成率,
sum(isnull(增量本月认购实际完成,0)) as 增量本月认购实际完成,
sum(isnull(增量本月认购任务,0)) as 增量本月认购任务,
case when sum(isnull(增量本月认购任务,0)) =0 then 0 else sum(isnull(增量本月认购实际完成,0))/sum(isnull(增量本月认购任务,0)) end AS 增量本月认购完成率,
sum(isnull(存量本月认购实际完成,0)) as 存量本月认购实际完成,
sum(isnull(存量本月认购任务,0)) as 存量本月认购任务,
case when sum(isnull(存量本月认购任务,0)) =0 then 0 else sum(isnull(存量本月认购实际完成,0))/sum(isnull(存量本月认购任务,0)) end AS 存量本月认购完成率,
--本月签约 
sum(isnull(新增量本月签约实际完成,0)) as 新增量本月签约实际完成,
sum(isnull(新增量本月签约任务,0)) as 新增量本月签约任务,
case when sum(isnull(新增量本月签约任务,0)) =0 then 0 else sum(isnull(新增量本月签约实际完成,0))/sum(isnull(新增量本月签约任务,0)) end AS 新增量本月签约完成率,
sum(isnull(增量本月签约实际完成,0)) as 增量本月签约实际完成,
sum(isnull(增量本月签约任务,0)) as 增量本月签约任务,
case when sum(isnull(增量本月签约任务,0)) =0 then 0 else sum(isnull(增量本月签约实际完成,0))/sum(isnull(增量本月签约任务,0)) end AS 增量本月签约完成率,
sum(isnull(存量本月签约实际完成,0)) as 存量本月签约实际完成,
sum(isnull(存量本月签约任务,0)) as 存量本月签约任务,
case when sum(isnull(存量本月签约任务,0)) =0 then 0 else sum(isnull(存量本月签约实际完成,0))/sum(isnull(存量本月签约任务,0)) end AS 存量本月签约完成率,
--本月回笼 
sum(isnull(新增量本月回笼实际完成,0)) as 新增量本月回笼实际完成,
sum(isnull(新增量本月回笼任务,0)) as 新增量本月回笼任务,
case when sum(isnull(新增量本月回笼任务,0)) =0 then 0 else sum(isnull(新增量本月回笼实际完成,0))/sum(isnull(新增量本月回笼任务,0)) end AS 新增量本月回笼完成率,
sum(isnull(增量本月回笼实际完成,0)) as 增量本月回笼实际完成,
sum(isnull(增量本月回笼任务,0)) as 增量本月回笼任务,
case when sum(isnull(增量本月回笼任务,0)) =0 then 0 else sum(isnull(增量本月回笼实际完成,0))/sum(isnull(增量本月回笼任务,0)) end AS 增量本月回笼完成率,
sum(isnull(存量本月回笼实际完成,0)) as 存量本月回笼实际完成,
sum(isnull(存量本月回笼任务,0)) as 存量本月回笼任务,
case when sum(isnull(存量本月回笼任务,0))  =0 then 0 else sum(isnull(存量本月回笼实际完成,0)) /sum(isnull(存量本月回笼任务,0))  end AS 存量本月回笼完成率,
--本月直投 
sum(isnull(新增量本月直投实际完成,0)) as 新增量本月直投实际完成,
sum(isnull(新增量本月直投任务,0))  as 新增量本月直投任务,
case when sum(isnull(新增量本月直投任务,0)) =0 then 0 else sum(isnull(新增量本月直投实际完成,0))/sum(isnull(新增量本月直投任务,0)) end AS 新增量本月直投完成率,
sum(isnull(增量本月直投实际完成,0))  as 增量本月直投实际完成,
sum(isnull(增量本月直投任务,0))  as 增量本月直投任务,
case when sum(isnull(增量本月直投任务,0)) =0 then 0 else sum(isnull(增量本月直投实际完成,0))/sum(isnull(增量本月直投任务,0)) end AS 增量本月直投完成率,
sum(isnull(存量本月直投实际完成,0))  as 存量本月直投实际完成,
sum(isnull(存量本月直投任务,0))  as 存量本月直投任务,
case when sum(isnull(存量本月直投任务,0)) =0 then 0 else sum(isnull(存量本月直投实际完成,0))/sum(isnull(存量本月直投任务,0)) end AS 存量本月直投完成率,

-----------------------------------------------------本年-----------------------------------------------------
--本年认购 
sum(isnull(新增量本年认购实际完成,0)) as 新增量本年认购实际完成,
sum(isnull(新增量本年认购任务,0)) as 新增量本年认购任务,
case when sum(isnull(新增量本年认购任务,0)) =0 then 0 else sum(isnull(新增量本年认购实际完成,0))/sum(isnull(新增量本年认购任务,0)) end AS 新增量本年认购完成率,
sum(isnull(增量本年认购实际完成,0)) as 增量本年认购实际完成,
sum(isnull(增量本年认购任务,0)) as 增量本年认购任务,
case when sum(isnull(增量本年认购任务,0)) =0 then 0 else sum(isnull(增量本年认购实际完成,0))/sum(isnull(增量本年认购任务,0)) end AS 增量本年认购完成率,
sum(isnull(存量本年认购实际完成,0)) as 存量本年认购实际完成,
sum(isnull(存量本年认购任务,0)) as 存量本年认购任务,
case when sum(isnull(存量本年认购任务,0)) =0 then 0 else sum(isnull(存量本年认购实际完成,0))/sum(isnull(存量本年认购任务,0)) end AS 存量本年认购完成率,
--本年签约 
sum(isnull(新增量本年签约实际完成,0)) as 新增量本年签约实际完成,
sum(isnull(新增量本年签约任务,0)) as 新增量本年签约任务,
case when sum(isnull(新增量本年签约任务,0)) =0 then 0 else sum(isnull(新增量本年签约实际完成,0))/sum(isnull(新增量本年签约任务,0)) end AS 新增量本年签约完成率,
sum(isnull(增量本年签约实际完成,0)) as 增量本年签约实际完成,
sum(isnull(增量本年签约任务,0)) as 增量本年签约任务,
case when sum(isnull(增量本年签约任务,0)) =0 then 0 else sum(isnull(增量本年签约实际完成,0))/sum(isnull(增量本年签约任务,0)) end AS 增量本年签约完成率,
sum(isnull(存量本年签约实际完成,0)) as 存量本年签约实际完成,
sum(isnull(存量本年签约任务,0)) as 存量本年签约任务,
case when sum(isnull(存量本年签约任务,0)) =0 then 0 else sum(isnull(存量本年签约实际完成,0))/sum(isnull(存量本年签约任务,0)) end AS 存量本年签约完成率,
--本年回笼 
sum(isnull(新增量本年回笼实际完成,0)) as 新增量本年回笼实际完成,
sum(isnull(新增量本年回笼任务,0)) as 新增量本年回笼任务,
case when sum(isnull(新增量本年回笼任务,0)) =0 then 0 else sum(isnull(新增量本年回笼实际完成,0))/sum(isnull(新增量本年回笼任务,0)) end AS 新增量本年回笼完成率,
sum(isnull(增量本年回笼实际完成,0)) as 增量本年回笼实际完成,
sum(isnull(增量本年回笼任务,0)) as 增量本年回笼任务,
case when sum(isnull(增量本年回笼任务,0)) =0 then 0 else sum(isnull(增量本年回笼实际完成,0))/sum(isnull(增量本年回笼任务,0)) end AS 增量本年回笼完成率,
sum(isnull(存量本年回笼实际完成,0)) as 存量本年回笼实际完成,
sum(isnull(存量本年回笼任务,0)) as 存量本年回笼任务,
case when sum(isnull(存量本年回笼任务,0))  =0 then 0 else sum(isnull(存量本年回笼实际完成,0)) /sum(isnull(存量本年回笼任务,0))  end AS 存量本年回笼完成率,
--本年直投 
sum(isnull(新增量本年直投实际完成,0)) as 新增量本年直投实际完成,
sum(isnull(新增量本年直投任务,0))  as 新增量本年直投任务,
case when sum(isnull(新增量本年直投任务,0)) =0 then 0 else sum(isnull(新增量本年直投实际完成,0))/sum(isnull(新增量本年直投任务,0)) end AS 新增量本年直投完成率,
sum(isnull(增量本年直投实际完成,0))  as 增量本年直投实际完成,
sum(isnull(增量本年直投任务,0))  as 增量本年直投任务,
case when sum(isnull(增量本年直投任务,0)) =0 then 0 else sum(isnull(增量本年直投实际完成,0))/sum(isnull(增量本年直投任务,0)) end AS 增量本年直投完成率,
sum(isnull(存量本年直投实际完成,0))  as 存量本年直投实际完成,
sum(isnull(存量本年直投任务,0))  as 存量本年直投任务,
case when sum(isnull(存量本年直投任务,0)) =0 then 0 else sum(isnull(存量本年直投实际完成,0))/sum(isnull(存量本年直投任务,0)) end AS 存量本年直投完成率,

-----------------------------------------------------去年-----------------------------------------------------
--去年认购 
sum(isnull(新增量去年认购实际完成,0)) as 新增量去年认购实际完成,
sum(isnull(新增量去年认购任务,0)) as 新增量去年认购任务,
case when sum(isnull(新增量去年认购任务,0)) =0 then 0 else sum(isnull(新增量去年认购实际完成,0))/sum(isnull(新增量去年认购任务,0)) end AS 新增量去年认购完成率,
sum(isnull(增量去年认购实际完成,0)) as 增量去年认购实际完成,
sum(isnull(增量去年认购任务,0)) as 增量去年认购任务,
case when sum(isnull(增量去年认购任务,0)) =0 then 0 else sum(isnull(增量去年认购实际完成,0))/sum(isnull(增量去年认购任务,0)) end AS 增量去年认购完成率,
sum(isnull(存量去年认购实际完成,0)) as 存量去年认购实际完成,
sum(isnull(存量去年认购任务,0)) as 存量去年认购任务,
case when sum(isnull(存量去年认购任务,0)) =0 then 0 else sum(isnull(存量去年认购实际完成,0))/sum(isnull(存量去年认购任务,0)) end AS 存量去年认购完成率,
--去年签约 
sum(isnull(新增量去年签约实际完成,0)) as 新增量去年签约实际完成,
sum(isnull(新增量去年签约任务,0)) as 新增量去年签约任务,
case when sum(isnull(新增量去年签约任务,0)) =0 then 0 else sum(isnull(新增量去年签约实际完成,0))/sum(isnull(新增量去年签约任务,0)) end AS 新增量去年签约完成率,
sum(isnull(增量去年签约实际完成,0)) as 增量去年签约实际完成,
sum(isnull(增量去年签约任务,0)) as 增量去年签约任务,
case when sum(isnull(增量去年签约任务,0)) =0 then 0 else sum(isnull(增量去年签约实际完成,0))/sum(isnull(增量去年签约任务,0)) end AS 增量去年签约完成率,
sum(isnull(存量去年签约实际完成,0)) as 存量去年签约实际完成,
sum(isnull(存量去年签约任务,0)) as 存量去年签约任务,
case when sum(isnull(存量去年签约任务,0)) =0 then 0 else sum(isnull(存量去年签约实际完成,0))/sum(isnull(存量去年签约任务,0)) end AS 存量去年签约完成率,
--去年回笼 
sum(isnull(新增量去年回笼实际完成,0)) as 新增量去年回笼实际完成,
sum(isnull(新增量去年回笼任务,0)) as 新增量去年回笼任务,
case when sum(isnull(新增量去年回笼任务,0)) =0 then 0 else sum(isnull(新增量去年回笼实际完成,0))/sum(isnull(新增量去年回笼任务,0)) end AS 新增量去年回笼完成率,
sum(isnull(增量去年回笼实际完成,0)) as 增量去年回笼实际完成,
sum(isnull(增量去年回笼任务,0)) as 增量去年回笼任务,
case when sum(isnull(增量去年回笼任务,0)) =0 then 0 else sum(isnull(增量去年回笼实际完成,0))/sum(isnull(增量去年回笼任务,0)) end AS 增量去年回笼完成率,
sum(isnull(存量去年回笼实际完成,0)) as 存量去年回笼实际完成,
sum(isnull(存量去年回笼任务,0)) as 存量去年回笼任务,
case when sum(isnull(存量去年回笼任务,0))  =0 then 0 else sum(isnull(存量去年回笼实际完成,0)) /sum(isnull(存量去年回笼任务,0))  end AS 存量去年回笼完成率,
--去年直投 
sum(isnull(新增量去年直投实际完成,0)) as 新增量去年直投实际完成,
sum(isnull(新增量去年直投任务,0))  as 新增量去年直投任务,
case when sum(isnull(新增量去年直投任务,0)) =0 then 0 else sum(isnull(新增量去年直投实际完成,0))/sum(isnull(新增量去年直投任务,0)) end AS 新增量去年直投完成率,
sum(isnull(增量去年直投实际完成,0))  as 增量去年直投实际完成,
sum(isnull(增量去年直投任务,0))  as 增量去年直投任务,
case when sum(isnull(增量去年直投任务,0)) =0 then 0 else sum(isnull(增量去年直投实际完成,0))/sum(isnull(增量去年直投任务,0)) end AS 增量去年直投完成率,
sum(isnull(存量去年直投实际完成,0))  as 存量去年直投实际完成,
sum(isnull(存量去年直投任务,0))  as 存量去年直投任务,
case when sum(isnull(存量去年直投任务,0)) =0 then 0 else sum(isnull(存量去年直投实际完成,0))/sum(isnull(存量去年直投任务,0)) end AS 存量去年直投完成率,
--本月经营情况
sum(org.本月认购金额) as 本月认购金额,		
sum(org.本月认购任务) as 本月认购任务,		
case when sum(org.本月认购任务) = 0 then 0 else sum(org.本月认购金额)/ sum(org.本月认购任务) end 本月认购完成率,	
sum(org.本月签约金额) as 本月已签约金额,
sum(org.本月签约任务) as 本月签约任务,		
case when sum(org.本月签约任务) = 0 then 0 else sum(org.本月签约金额)/ sum(org.本月签约任务) end 本月签约完成率,	
sum(org.本月回笼金额) as 本月回笼金额,
sum(org.本月回笼任务) as 本月回笼任务,		
case when sum(org.本月回笼任务) = 0 then 0 else sum(org.本月回笼金额)/ sum(org.本月回笼任务) end 本月回笼完成率,	
sum(org.本月除地价外直投发生) as 本月除地价外直投发生,
sum(org.本月除地价外直投任务) as 本月除地价外直投任务,		
case when sum(org.本月除地价外直投任务) = 0 then 0 else sum(org.本月除地价外直投发生)/ sum(org.本月除地价外直投任务) end 本月除地价外直投使用率,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'')  in ('片区','镇街') then null else org.组织架构id end 项目guid,
--新增
sum(本月认购套数实际完成) as 本月认购套数实际完成,
sum(本月认购套数任务) as 本月认购套数任务,
case when sum(本月认购套数任务) =0 then 0 else sum(本月认购套数)/sum(本月认购套数任务) end AS 本月认购套数完成率,
sum(本月认购面积实际完成) as 本月认购面积实际完成,
sum(本月认购面积任务) as 本月认购面积任务,
case when sum(本月认购面积任务) =0 then 0 else sum(本月认购面积实际完成)/sum(本月认购面积任务) end AS 本月认购面积完成率,
sum(本年认购套数实际完成) as 本年认购套数实际完成,
sum(本年认购套数任务) as 本年认购套数任务,
case when sum(本年认购套数任务) =0 then 0 else sum(本年认购套数实际完成)*1.0/sum(本年认购套数任务) end AS 本年认购套数完成率,
sum(本年认购面积实际完成) as 本年认购面积实际完成,
sum(本年认购面积任务) as 本年认购面积任务,
case when sum(本年认购面积任务) =0 then 0 else sum(本年认购面积实际完成)/sum(本年认购面积任务) end AS 本年认购面积完成率,
sum(去年认购套数实际完成) as 去年认购套数实际完成,
sum(去年认购套数任务) as 去年认购套数任务,
case when sum(去年认购套数任务) =0 then 0 else sum(去年认购套数实际完成)*1.0/sum(去年认购套数任务) end AS 去年认购套数完成率,
sum(去年认购面积实际完成) as 去年认购面积实际完成,
sum(去年认购面积任务) as 去年认购面积任务,
case when sum(去年认购面积任务) =0 then 0 else sum(去年认购面积任务)/sum(去年认购面积任务) end AS 去年认购面积完成率,
sum(本月签约套数实际完成) as 本月签约套数实际完成,
sum(本月签约套数任务) as 本月签约套数任务,
case when sum(本月签约套数任务) =0 then 0 else sum(本月签约套数实际完成)*1.0/sum(本月签约套数任务) end AS 本月签约套数完成率,
sum(本月签约面积实际完成) as 本月签约面积实际完成,
sum(本月签约面积任务) as 本月签约面积任务,
case when sum(本月签约面积任务) =0 then 0 else sum(本月签约面积实际完成)/sum(本月签约面积任务) end AS 本月签约面积完成率,
sum(本年签约套数实际完成) as 本年签约套数实际完成,
sum(本年签约套数任务) as 本年签约套数任务,
case when sum(本年签约套数任务) =0 then 0 else sum(本年签约套数实际完成)*1.0/sum(本年签约套数任务) end AS 本年签约套数完成率,
sum(本年签约面积实际完成) as 本年签约面积实际完成,
sum(本年签约面积任务) as 本年签约面积任务,
case when sum(本年签约面积任务) =0 then 0 else sum(本年签约面积实际完成)/sum(本年签约面积任务) end AS 本年签约面积完成率,
sum(去年签约套数实际完成) as 去年签约套数实际完成,
sum(去年签约套数任务) as 去年签约套数任务,
case when sum(去年签约套数任务) =0 then 0 else sum(去年签约套数实际完成)*1.0/sum(去年签约套数任务) end AS 去年签约套数完成率,
sum(去年签约面积实际完成) as 去年签约面积实际完成,
sum(去年签约面积任务) as 去年签约面积任务,
case when sum(去年签约面积任务) =0 then 0 else sum(去年签约面积实际完成)/sum(去年签约面积任务) end AS 去年签约面积完成率,
--本月认购套数
sum(isnull(新增量本月认购套数实际完成,0)) as 新增量本月认购套数实际完成,
sum(isnull(新增量本月认购套数任务,0))  as 新增量本月认购套数任务,
case when sum(isnull(新增量本月认购套数任务,0)) =0 then 0 else sum(isnull(新增量本月认购套数实际完成,0))*1.0/sum(isnull(新增量本月认购套数任务,0)) end AS 新增量本月认购套数完成率, 
sum(isnull(增量本月认购套数实际完成,0)) as 增量本月认购套数实际完成,
sum(isnull(增量本月认购套数任务,0))  as 增量本月认购套数任务,
case when sum(isnull(增量本月认购套数任务,0)) =0 then 0 else sum(isnull(增量本月认购套数实际完成,0))*1.0/sum(isnull(增量本月认购套数任务,0)) end AS 增量本月认购套数完成率, 
sum(isnull(存量本月认购套数实际完成,0)) as 存量本月认购套数实际完成,
sum(isnull(存量本月认购套数任务,0))  as 存量本月认购套数任务,
case when sum(isnull(存量本月认购套数任务,0)) =0 then 0 else sum(isnull(存量本月认购套数实际完成,0))*1.0/sum(isnull(存量本月认购套数任务,0)) end AS 存量本月认购套数完成率, 
--本月认购面积
sum(isnull(新增量本月认购面积实际完成,0)) as 新增量本月认购面积实际完成,
sum(isnull(新增量本月认购面积任务,0))  as 新增量本月认购面积任务,
case when sum(isnull(新增量本月认购面积任务,0)) =0 then 0 else sum(isnull(新增量本月认购面积实际完成,0))/sum(isnull(新增量本月认购面积任务,0)) end AS 新增量本月认购面积完成率, 
sum(isnull(增量本月认购面积实际完成,0)) as 增量本月认购面积实际完成,
sum(isnull(增量本月认购面积任务,0))  as 增量本月认购面积任务,
case when sum(isnull(增量本月认购面积任务,0)) =0 then 0 else sum(isnull(增量本月认购面积实际完成,0))/sum(isnull(增量本月认购面积任务,0)) end AS 增量本月认购面积完成率, 
sum(isnull(存量本月认购面积实际完成,0)) as 存量本月认购面积实际完成,
sum(isnull(存量本月认购面积任务,0))  as 存量本月认购面积任务,
case when sum(isnull(存量本月认购面积任务,0)) =0 then 0 else sum(isnull(存量本月认购面积实际完成,0))/sum(isnull(存量本月认购面积任务,0)) end AS 存量本月认购面积完成率, 
--本月签约套数
sum(isnull(新增量本月签约套数实际完成,0)) as 新增量本月签约套数实际完成,
sum(isnull(新增量本月签约套数任务,0))  as 新增量本月签约套数任务,
case when sum(isnull(新增量本月签约套数任务,0)) =0 then 0 else sum(isnull(新增量本月签约套数实际完成,0))*1.0/sum(isnull(新增量本月签约套数任务,0)) end AS 新增量本月签约套数完成率, 
sum(isnull(增量本月签约套数实际完成,0)) as 增量本月签约套数实际完成,
sum(isnull(增量本月签约套数任务,0))  as 增量本月签约套数任务,
case when sum(isnull(增量本月签约套数任务,0)) =0 then 0 else sum(isnull(增量本月签约套数实际完成,0))*1.0/sum(isnull(增量本月签约套数任务,0)) end AS 增量本月签约套数完成率, 
sum(isnull(存量本月签约套数实际完成,0)) as 存量本月签约套数实际完成,
sum(isnull(存量本月签约套数任务,0))  as 存量本月签约套数任务,
case when sum(isnull(存量本月签约套数任务,0)) =0 then 0 else sum(isnull(存量本月签约套数实际完成,0))*1.0/sum(isnull(存量本月签约套数任务,0)) end AS 存量本月签约套数完成率, 
--本月签约面积
sum(isnull(新增量本月签约面积实际完成,0)) as 新增量本月签约面积实际完成,
sum(isnull(新增量本月签约面积任务,0))  as 新增量本月签约面积任务,
case when sum(isnull(新增量本月签约面积任务,0)) =0 then 0 else sum(isnull(新增量本月签约面积实际完成,0))/sum(isnull(新增量本月签约面积任务,0)) end AS 新增量本月签约面积完成率, 
sum(isnull(增量本月签约面积实际完成,0)) as 增量本月签约面积实际完成,
sum(isnull(增量本月签约面积任务,0))  as 增量本月签约面积任务,
case when sum(isnull(增量本月签约面积任务,0)) =0 then 0 else sum(isnull(增量本月签约面积实际完成,0))/sum(isnull(增量本月签约面积任务,0)) end AS 增量本月签约面积完成率, 
sum(isnull(存量本月签约面积实际完成,0)) as 存量本月签约面积实际完成,
sum(isnull(存量本月签约面积任务,0))  as 存量本月签约面积任务,
case when sum(isnull(存量本月签约面积任务,0)) =0 then 0 else sum(isnull(存量本月签约面积实际完成,0))/sum(isnull(存量本月签约面积任务,0)) end AS 存量本月签约面积完成率, 
--本年认购套数
sum(isnull(新增量本年认购套数实际完成,0)) as 新增量本年认购套数实际完成,
sum(isnull(新增量本年认购套数任务,0))  as 新增量本年认购套数任务,
case when sum(isnull(新增量本年认购套数任务,0)) =0 then 0 else sum(isnull(新增量本年认购套数实际完成,0))*1.0/sum(isnull(新增量本年认购套数任务,0)) end AS 新增量本年认购套数完成率, 
sum(isnull(增量本年认购套数实际完成,0)) as 增量本年认购套数实际完成,
sum(isnull(增量本年认购套数任务,0))  as 增量本年认购套数任务,
case when sum(isnull(增量本年认购套数任务,0)) =0 then 0 else sum(isnull(增量本年认购套数实际完成,0))*1.0/sum(isnull(增量本年认购套数任务,0)) end AS 增量本年认购套数完成率, 
sum(isnull(存量本年认购套数实际完成,0)) as 存量本年认购套数实际完成,
sum(isnull(存量本年认购套数任务,0))  as 存量本年认购套数任务,
case when sum(isnull(存量本年认购套数任务,0)) =0 then 0 else sum(isnull(存量本年认购套数实际完成,0))*1.0/sum(isnull(存量本年认购套数任务,0)) end AS 存量本年认购套数完成率, 
--本年认购面积
sum(isnull(新增量本年认购面积实际完成,0)) as 新增量本年认购面积实际完成,
sum(isnull(新增量本年认购面积任务,0))  as 新增量本年认购面积任务,
case when sum(isnull(新增量本年认购面积任务,0)) =0 then 0 else sum(isnull(新增量本年认购面积实际完成,0))/sum(isnull(新增量本年认购面积任务,0)) end AS 新增量本年认购面积完成率, 
sum(isnull(增量本年认购面积实际完成,0)) as 增量本年认购面积实际完成,
sum(isnull(增量本年认购面积任务,0))  as 增量本年认购面积任务,
case when sum(isnull(增量本年认购面积任务,0)) =0 then 0 else sum(isnull(增量本年认购面积实际完成,0))/sum(isnull(增量本年认购面积任务,0)) end AS 增量本年认购面积完成率, 
sum(isnull(存量本年认购面积实际完成,0)) as 存量本年认购面积实际完成,
sum(isnull(存量本年认购面积任务,0))  as 存量本年认购面积任务,
case when sum(isnull(存量本年认购面积任务,0)) =0 then 0 else sum(isnull(存量本年认购面积实际完成,0))/sum(isnull(存量本年认购面积任务,0)) end AS 存量本年认购面积完成率, 
--本年签约套数
sum(isnull(新增量本年签约套数实际完成,0)) as 新增量本年签约套数实际完成,
sum(isnull(新增量本年签约套数任务,0))  as 新增量本年签约套数任务,
case when sum(isnull(新增量本年签约套数任务,0)) =0 then 0 else sum(isnull(新增量本年签约套数实际完成,0))*1.0/sum(isnull(新增量本年签约套数任务,0)) end AS 新增量本年签约套数完成率, 
sum(isnull(增量本年签约套数实际完成,0)) as 增量本年签约套数实际完成,
sum(isnull(增量本年签约套数任务,0))  as 增量本年签约套数任务,
case when sum(isnull(增量本年签约套数任务,0)) =0 then 0 else sum(isnull(增量本年签约套数实际完成,0))*1.0/sum(isnull(增量本年签约套数任务,0)) end AS 增量本年签约套数完成率, 
sum(isnull(存量本年签约套数实际完成,0)) as 存量本年签约套数实际完成,
sum(isnull(存量本年签约套数任务,0))  as 存量本年签约套数任务,
case when sum(isnull(存量本年签约套数任务,0)) =0 then 0 else sum(isnull(存量本年签约套数实际完成,0))*1.0/sum(isnull(存量本年签约套数任务,0)) end AS 存量本年签约套数完成率, 
--本年签约面积
sum(isnull(新增量本年签约面积实际完成,0)) as 新增量本年签约面积实际完成,
sum(isnull(新增量本年签约面积任务,0))  as 新增量本年签约面积任务,
case when sum(isnull(新增量本年签约面积任务,0)) =0 then 0 else sum(isnull(新增量本年签约面积实际完成,0))/sum(isnull(新增量本年签约面积任务,0)) end AS 新增量本年签约面积完成率, 
sum(isnull(增量本年签约面积实际完成,0)) as 增量本年签约面积实际完成,
sum(isnull(增量本年签约面积任务,0))  as 增量本年签约面积任务,
case when sum(isnull(增量本年签约面积任务,0)) =0 then 0 else sum(isnull(增量本年签约面积实际完成,0))/sum(isnull(增量本年签约面积任务,0)) end AS 增量本年签约面积完成率, 
sum(isnull(存量本年签约面积实际完成,0)) as 存量本年签约面积实际完成,
sum(isnull(存量本年签约面积任务,0))  as 存量本年签约面积任务,
case when sum(isnull(存量本年签约面积任务,0)) =0 then 0 else sum(isnull(存量本年签约面积实际完成,0))/sum(isnull(存量本年签约面积任务,0)) end AS 存量本年签约面积完成率, 
--去年认购套数
sum(isnull(新增量去年认购套数实际完成,0)) as 新增量去年认购套数实际完成,
sum(isnull(新增量去年认购套数任务,0))  as 新增量去年认购套数任务,
case when sum(isnull(新增量去年认购套数任务,0)) =0 then 0 else sum(isnull(新增量去年认购套数实际完成,0))*1.0/sum(isnull(新增量去年认购套数任务,0)) end AS 新增量去年认购套数完成率, 
sum(isnull(增量去年认购套数实际完成,0)) as 增量去年认购套数实际完成,
sum(isnull(增量去年认购套数任务,0))  as 增量去年认购套数任务,
case when sum(isnull(增量去年认购套数任务,0)) =0 then 0 else sum(isnull(增量去年认购套数实际完成,0))*1.0/sum(isnull(增量去年认购套数任务,0)) end AS 增量去年认购套数完成率, 
sum(isnull(存量去年认购套数实际完成,0)) as 存量去年认购套数实际完成,
sum(isnull(存量去年认购套数任务,0))  as 存量去年认购套数任务,
case when sum(isnull(存量去年认购套数任务,0)) =0 then 0 else sum(isnull(存量去年认购套数实际完成,0))*1.0/sum(isnull(存量去年认购套数任务,0)) end AS 存量去年认购套数完成率, 
--去年认购面积
sum(isnull(新增量去年认购面积实际完成,0)) as 新增量去年认购面积实际完成,
sum(isnull(新增量去年认购面积任务,0))  as 新增量去年认购面积任务,
case when sum(isnull(新增量去年认购面积任务,0)) =0 then 0 else sum(isnull(新增量去年认购面积实际完成,0))/sum(isnull(新增量去年认购面积任务,0)) end AS 新增量去年认购面积完成率, 
sum(isnull(增量去年认购面积实际完成,0)) as 增量去年认购面积实际完成,
sum(isnull(增量去年认购面积任务,0))  as 增量去年认购面积任务,
case when sum(isnull(增量去年认购面积任务,0)) =0 then 0 else sum(isnull(增量去年认购面积实际完成,0))/sum(isnull(增量去年认购面积任务,0)) end AS 增量去年认购面积完成率, 
sum(isnull(存量去年认购面积实际完成,0)) as 存量去年认购面积实际完成,
sum(isnull(存量去年认购面积任务,0))  as 存量去年认购面积任务,
case when sum(isnull(存量去年认购面积任务,0)) =0 then 0 else sum(isnull(存量去年认购面积实际完成,0))/sum(isnull(存量去年认购面积任务,0)) end AS 存量去年认购面积完成率, 
--去年签约套数
sum(isnull(新增量去年签约套数实际完成,0)) as 新增量去年签约套数实际完成,
sum(isnull(新增量去年签约套数任务,0))  as 新增量去年签约套数任务,
case when sum(isnull(新增量去年签约套数任务,0)) =0 then 0 else sum(isnull(新增量去年签约套数实际完成,0))*1.0/sum(isnull(新增量去年签约套数任务,0)) end AS 新增量去年签约套数完成率, 
sum(isnull(增量去年签约套数实际完成,0)) as 增量去年签约套数实际完成,
sum(isnull(增量去年签约套数任务,0))  as 增量去年签约套数任务,
case when sum(isnull(增量去年签约套数任务,0)) =0 then 0 else sum(isnull(增量去年签约套数实际完成,0))*1.0/sum(isnull(增量去年签约套数任务,0)) end AS 增量去年签约套数完成率, 
sum(isnull(存量去年签约套数实际完成,0)) as 存量去年签约套数实际完成,
sum(isnull(存量去年签约套数任务,0))  as 存量去年签约套数任务,
case when sum(isnull(存量去年签约套数任务,0)) =0 then 0 else sum(isnull(存量去年签约套数实际完成,0))*1.0/sum(isnull(存量去年签约套数任务,0)) end AS 存量去年签约套数完成率, 
--去年签约面积
sum(isnull(新增量去年签约面积实际完成,0)) as 新增量去年签约面积实际完成,
sum(isnull(新增量去年签约面积任务,0))  as 新增量去年签约面积任务,
case when sum(isnull(新增量去年签约面积任务,0)) =0 then 0 else sum(isnull(新增量去年签约面积实际完成,0))/sum(isnull(新增量去年签约面积任务,0)) end AS 新增量去年签约面积完成率, 
sum(isnull(增量去年签约面积实际完成,0)) as 增量去年签约面积实际完成,
sum(isnull(增量去年签约面积任务,0))  as 增量去年签约面积任务,
case when sum(isnull(增量去年签约面积任务,0)) =0 then 0 else sum(isnull(增量去年签约面积实际完成,0))/sum(isnull(增量去年签约面积任务,0)) end AS 增量去年签约面积完成率, 
sum(isnull(存量去年签约面积实际完成,0)) as 存量去年签约面积实际完成,
sum(isnull(存量去年签约面积任务,0))  as 存量去年签约面积任务,
case when sum(isnull(存量去年签约面积任务,0)) =0 then 0 else sum(isnull(存量去年签约面积实际完成,0))/sum(isnull(存量去年签约面积任务,0)) end AS 存量去年签约面积完成率,
--权益回笼
sum(本月权益回笼实际完成) as 本月权益回笼实际完成,
sum(本月权益回笼任务) as 本月权益回笼任务,
case when sum(本月权益回笼任务) =0 then 0 else sum(本月权益回笼实际完成)/sum(本月权益回笼任务) end AS 本月权益回笼完成率,
sum(本年权益回笼实际完成) as 本年权益回笼实际完成,
sum(本年权益回笼任务) as 本年权益回笼任务,
case when sum(本年权益回笼任务) =0 then 0 else sum(本年权益回笼实际完成)/sum(本年权益回笼任务) end AS 本年权益回笼完成率, 
sum(去年权益回笼实际完成) as 去年权益回笼实际完成,
sum(去年权益回笼任务) as 去年权益回笼任务,
case when sum(去年权益回笼任务) =0 then 0 else sum(去年权益回笼实际完成)/sum(去年权益回笼任务) end AS 去年权益回笼完成率,  

sum(isnull(新增量本月权益回笼实际完成,0)) as 新增量本月权益回笼实际完成,
sum(isnull(新增量本月权益回笼任务,0)) as 新增量本月权益回笼任务,
case when sum(isnull(新增量本月权益回笼任务,0)) =0 then 0 else sum(isnull(新增量本月权益回笼实际完成,0))/sum(isnull(新增量本月权益回笼任务,0)) end AS 新增量本月权益回笼完成率,
sum(isnull(增量本月权益回笼实际完成,0)) as 增量本月权益回笼实际完成,
sum(isnull(增量本月权益回笼任务,0)) as 增量本月权益回笼任务,
case when sum(isnull(增量本月权益回笼任务,0)) =0 then 0 else sum(isnull(增量本月权益回笼实际完成,0))/sum(isnull(增量本月权益回笼任务,0)) end AS 增量本月权益回笼完成率,
sum(isnull(存量本月权益回笼实际完成,0)) as 存量本月权益回笼实际完成,
sum(isnull(存量本月权益回笼任务,0)) as 存量本月权益回笼任务,
case when sum(isnull(存量本月权益回笼任务,0))  =0 then 0 else sum(isnull(存量本月权益回笼实际完成,0)) /sum(isnull(存量本月权益回笼任务,0))  end AS 存量本月权益回笼完成率,

sum(isnull(新增量本年权益回笼实际完成,0)) as 新增量本年权益回笼实际完成,
sum(isnull(新增量本年权益回笼任务,0)) as 新增量本年权益回笼任务,
case when sum(isnull(新增量本年权益回笼任务,0)) =0 then 0 else sum(isnull(新增量本年权益回笼实际完成,0))/sum(isnull(新增量本年权益回笼任务,0)) end AS 新增量本年权益回笼完成率,
sum(isnull(增量本年权益回笼实际完成,0)) as 增量本年权益回笼实际完成,
sum(isnull(增量本年权益回笼任务,0)) as 增量本年权益回笼任务,
case when sum(isnull(增量本年权益回笼任务,0)) =0 then 0 else sum(isnull(增量本年权益回笼实际完成,0))/sum(isnull(增量本年权益回笼任务,0)) end AS 增量本年权益回笼完成率,
sum(isnull(存量本年权益回笼实际完成,0)) as 存量本年权益回笼实际完成,
sum(isnull(存量本年权益回笼任务,0)) as 存量本年权益回笼任务,
case when sum(isnull(存量本年权益回笼任务,0))  =0 then 0 else sum(isnull(存量本年权益回笼实际完成,0)) /sum(isnull(存量本年权益回笼任务,0))  end AS 存量本年权益回笼完成率,
 
sum(isnull(新增量去年权益回笼实际完成,0)) as 新增量去年权益回笼实际完成,
sum(isnull(新增量去年权益回笼任务,0)) as 新增量去年权益回笼任务,
case when sum(isnull(新增量去年权益回笼任务,0)) =0 then 0 else sum(isnull(新增量去年权益回笼实际完成,0))/sum(isnull(新增量去年权益回笼任务,0)) end AS 新增量去年权益回笼完成率,
sum(isnull(增量去年权益回笼实际完成,0)) as 增量去年权益回笼实际完成,
sum(isnull(增量去年权益回笼任务,0)) as 增量去年权益回笼任务,
case when sum(isnull(增量去年权益回笼任务,0)) =0 then 0 else sum(isnull(增量去年权益回笼实际完成,0))/sum(isnull(增量去年权益回笼任务,0)) end AS 增量去年权益回笼完成率,
sum(isnull(存量去年权益回笼实际完成,0)) as 存量去年权益回笼实际完成,
sum(isnull(存量去年权益回笼任务,0)) as 存量去年权益回笼任务,
case when sum(isnull(存量去年权益回笼任务,0))  =0 then 0 else sum(isnull(存量去年权益回笼实际完成,0)) /sum(isnull(存量去年权益回笼任务,0))  end AS 存量去年权益回笼完成率,
--营销来访情况
sum(本月来访批次) as 本月来访批次,
sum(本月新客来访批次) as 本月新客来访批次,
sum(本月旧客来访批次) as 本月旧客来访批次, 
sum(本年来访批次) as 本年来访批次,
sum(本年新客来访批次) as 本年新客来访批次,
sum(本年旧客来访批次) as 本年旧客来访批次,  
sum(去年来访批次) as 去年来访批次,
sum(去年新客来访批次) as 去年新客来访批次,
sum(去年旧客来访批次) as 去年旧客来访批次
FROM s_WqBaseStatic_summary org
left join #dw01 d on org.组织架构类型 = d.组织架构类型
LEFT JOIN #zlcl zc on org.组织架构id = zc.组织架构id
where org.组织架构类型 in (1,2,3) and org.清洗时间id = @date_id and org.平台公司名称 = '湾区公司'
group by org.清洗时间,
case when org.组织架构类型 = 1 then '公司'  when org.组织架构类型= 2 then '城市' else d.统计维度 end , 
case when org.组织架构类型 = 2 then org.组织架构名称 else org.区域 end ,
case when org.组织架构类型 in (1,2) then null else org.销售片区 end ,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'') = '片区' then null else org.所属镇街 end ,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'')  in ('片区','镇街') then null else org.项目推广名 end ,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'')  in ('项目') then org.组织架构名称 
when isnull(d.统计维度,'')='镇街' then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无') 
else org.区域+'_'+isnull(org.销售片区,'无') END, 
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'')  in ('片区','镇街') then null else org.组织架构id end

drop table #dw01,#zlcl


-------------------------02 现金流情况_1
--缓存项目/镇街/片区统计维度，通过项目的组织架构类型3来向上汇总镇街及片区的数据
select '3' as 组织架构类型, '项目' as 统计维度
into #dw02
union all 
select '3' as 组织架构类型, '镇街' as 统计维度
union all 
select '3' as 组织架构类型, '片区' as 统计维度

--预处理时间维度
select '已实现' as 时间
into #date02
union all 
select '本年' as 时间
union all 
select '本月' as 时间
union all
select '未实现' as 时间
union all 
select '全盘' as 时间

--清空当天数据
delete from wqzydtBi_cashflowinfo where datediff(dd,清洗时间,getdate()) = 0
 
insert into wqzydtBi_cashflowinfo 
--预处理现金流数据
select 
org.清洗时间,
case when org.组织架构类型 = 1 then '公司'  when org.组织架构类型= 2 then '城市' else d.统计维度 end 统计维度, 
'湾区公司' 公司名称,
case when org.组织架构类型 = 2 then org.组织架构名称 else org.区域 end 城市,
case when org.组织架构类型 in (1,2) then null else org.销售片区 end 片区,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'') = '片区' then null else org.所属镇街 end 镇街,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'')  in ('片区','镇街') then null else org.项目推广名 end 项目名称,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'')  in ('项目') then org.组织架构名称 
when isnull(d.统计维度,'')='镇街' then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无') 
else org.区域+'_'+isnull(org.销售片区,'无') end 外键关联,
da.时间,
sum(case when da.时间 = '已实现' then org.累计经营性现金流 
         when da.时间 = '本年' then org.本年经营性现金流 
         when da.时间 = '本月' then org.本月经营性现金流 
         when da.时间 = '全盘' then isnull(org.全盘现金流入,0) - isnull(org.全盘现金流出,0)
         when da.时间 = '未实现' then ( isnull(org.全盘现金流入,0) -  isnull(org.累计现金流入,0) ) - ( isnull(org.全盘现金流出,0) -  isnull(org.累计现金流出,0) ) else 0
         end) as 经营性现金流,	
sum(case when da.时间 = '已实现' then org.累计现金流入 
         when da.时间  = '本年' then org.本年现金流入 
         when da.时间  ='本月' then  org.本月现金流入 
         when da.时间 = '全盘' then isnull(org.全盘现金流入,0) 
         when da.时间 = '未实现' then  isnull(org.全盘现金流入,0) -  isnull(org.累计现金流入,0)  else 0
         end)  现金流入,	
sum(case when da.时间 = '已实现' then org.累计现金流出 
         when da.时间 = '本年' then org.本年现金流出 
         when da.时间  ='本月' then  org.本月现金流出 
         when da.时间 = '全盘' then isnull(org.全盘现金流出,0) 
         when da.时间 = '未实现' then  isnull(org.全盘现金流出,0) -  isnull(org.累计现金流出,0)  else 0
         end) 现金流出,	
sum(case when da.时间 = '已实现' then org.累计地价支出 
         when da.时间 = '本年' then org.本年地价支出 
         when da.时间  ='本月' then  org.本月地价支出 
         when da.时间 = '全盘' then isnull(org.全盘地价支出,0) 
         when da.时间 = '未实现' then  isnull(org.全盘地价支出,0) -  isnull(org.累计地价支出,0)  else 0
         end) 地价,	
sum(case when da.时间 = '已实现' then org.累计除地价外直投发生 
         when da.时间 = '本年' then org.本年除地价外直投发生 
         when da.时间  ='本月' then  org.本月除地价外直投发生 
         when da.时间 = '全盘' then isnull(org.全盘除地价外直投发生,0) 
         when da.时间 = '未实现' then  isnull(org.全盘除地价外直投发生,0) -  isnull(org.累计除地价外直投发生,0)  else 0
         end) 直投,	

sum(case when da.时间 = '已实现' then org.累计费用发生 
         when da.时间 = '本年' then org.本年费用发生 
         when da.时间  ='本月' then  org.本月费用发生 
         when da.时间 = '全盘' then isnull(org.全盘营销费用,0)  + isnull(org.全盘财务费用,0) + isnull(org.全盘管理费用,0)
         when da.时间 = '未实现' then  isnull(org.全盘营销费用,0) + isnull(org.全盘财务费用,0) + isnull(org.全盘管理费用,0) -  isnull(org.累计费用发生,0)  else 0
         end) 费用,	
sum(case when da.时间 = '已实现' then org.累计税金支出 
         when da.时间 = '本年' then org.本年税金支出 
         when da.时间  ='本月' then  org.本月税金支出 
         when da.时间 = '全盘' then isnull(org.全盘税金,0) 
         when da.时间 = '未实现' then  isnull(org.全盘税金,0) -  isnull(org.累计税金支出,0)  else 0
         end) 税金,	
sum(case when da.时间 = '已实现' then org.累计贷款余额 
         when da.时间 = '本年' then org.本年净增贷款 
         when da.时间  ='本月' then  org.本月贷款金额 
         when da.时间 = '全盘' then isnull(org.全盘贷款,0) 
         when da.时间 = '未实现' then  isnull(org.全盘贷款,0) -  isnull(org.累计贷款余额,0)  else 0
         end) 贷款,	
sum(case when da.时间 = '已实现' then org.累计股东现金流 
         when da.时间 = '本年' then org.本年股东现金流 
         when da.时间  ='本月' then  org.本月股东现金流 
         when da.时间 = '全盘' then isnull(org.全盘现金流入,0) - isnull(org.全盘现金流出,0) + isnull(org.全盘贷款,0)
         when da.时间 = '未实现' then  isnull(org.全盘现金流入,0) - isnull(org.全盘现金流出,0) + isnull(org.全盘贷款,0) - isnull(org.累计股东现金流,0) else 0
         end) 股东现金流,
-- 新增
sum(case when da.时间 = '已实现' then org.累计营销费支出 
         when da.时间 = '本年' then org.本年营销费支出 
         when da.时间  ='本月' then  org.本月营销费支出 
         when da.时间 = '全盘' then isnull(org.全盘营销费用,0) 
         when da.时间 = '未实现' then  isnull(org.全盘营销费用,0) -  isnull(org.累计营销费支出,0)  else 0
         end) 营销费用,	
sum(case when da.时间 = '已实现' then org.累计财务费支出 
         when da.时间 = '本年' then org.本年财务费支出 
         when da.时间  ='本月' then  org.本月财务费支出 
         when da.时间 = '全盘' then isnull(org.全盘财务费用,0) 
         when da.时间 = '未实现' then  isnull(org.全盘财务费用,0) -  isnull(org.累计财务费支出,0)  else 0
         end) 财务费用,	
sum(case when da.时间 = '已实现' then org.累计管理费支出 
         when da.时间 = '本年' then org.本年管理费支出 
         when da.时间  ='本月' then  org.本月管理费支出 
         when da.时间 = '全盘' then isnull(org.全盘管理费用,0) 
         when da.时间 = '未实现' then  isnull(org.全盘管理费用,0) -  isnull(org.累计管理费支出,0)  else 0
         end) 管理费用
from s_WqBaseStatic_summary org
left join #dw02 d on org.组织架构类型 = d.组织架构类型
inner join #date02 da on 1=1
where org.组织架构类型 in (1,2,3) and org.清洗时间id = @date_id and org.平台公司名称 = '湾区公司'
group by org.清洗时间,
case when org.组织架构类型 = 1 then '公司'  when org.组织架构类型= 2 then '城市' else d.统计维度 end, 
case when org.组织架构类型 = 2 then org.组织架构名称 else org.区域 end ,
case when org.组织架构类型 in (1,2) then null else org.销售片区 end ,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'') = '片区' then null else org.所属镇街 end ,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'')  in ('片区','镇街') then null else org.项目推广名 end ,
case when org.组织架构类型 in (1,2) or isnull(d.统计维度,'')  in ('项目') then org.组织架构名称 
when isnull(d.统计维度,'')='镇街' then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无') 
else org.区域+'_'+isnull(org.销售片区,'无') end ,
da.时间

drop table  #dw02, #date02
                                                

-------------------------03 公司资源情况_1
-- 缓存业态及项目的维度信息
SELECT DISTINCT
    org.清洗时间,
    '4' AS 组织架构类型, -- 业态维度
    tj.统计维度,
    CASE WHEN tj.统计维度 IN ('公司') THEN '湾区公司' ELSE '无' END AS 公司,
    CASE WHEN tj.统计维度 IN ('城市') THEN org.区域 ELSE '无' END AS 城市,
    CASE WHEN tj.统计维度 IN ('片区') THEN org.销售片区 ELSE '无' END AS 片区,
    CASE WHEN tj.统计维度 IN ('镇街') THEN org.所属镇街 ELSE '无' END AS 镇街,
    CASE WHEN tj.统计维度 IN ('项目') THEN yt.项目名称 ELSE '无' END AS 项目,
    CASE
        WHEN tj.统计维度 IN ('公司') THEN '湾区公司'
        WHEN tj.统计维度 IN ('城市') THEN org.区域
        WHEN tj.统计维度 IN ('片区') THEN org.区域 + '_' + ISNULL(org.销售片区, '无')
        WHEN tj.统计维度 IN ('镇街') THEN org.区域 + '_' + ISNULL(org.销售片区, '无') + '_' + ISNULL(org.所属镇街, '无')
        ELSE yt.项目名称
    END AS 外键关联,
    yt.项目guid AS projguid,
    yt.组织架构id AS 组织架构id,
    CASE 
        WHEN 
            CASE WHEN yt.组织架构名称 IN ('别墅') THEN '高级住宅' ELSE yt.组织架构名称 END
            IN ('住宅','高级住宅','公寓','商业','写字楼','地下室/车库')
        THEN CASE WHEN yt.组织架构名称 IN ('别墅') THEN '高级住宅' ELSE yt.组织架构名称 END
        ELSE '其他'
    END AS 组织架构名称,
    t.二级科目
INTO #baseinfo03
FROM s_WqBaseStatic_summary org
INNER JOIN (
    SELECT '货值' AS 二级科目
    UNION ALL SELECT '面积'
    UNION ALL SELECT '均价'
    UNION ALL SELECT '套数'
) t ON 1 = 1
INNER JOIN (
    SELECT DISTINCT 组织架构id, 组织架构名称, 组织架构编码, 项目guid, 项目推广名 AS 项目名称
    FROM s_WqBaseStatic_summary org
    WHERE 组织架构类型 = 4 AND org.清洗时间id = @date_id
) yt ON CHARINDEX(org.组织架构编码, yt.组织架构编码) > 0
INNER JOIN (
    SELECT '公司' 统计维度
    UNION ALL SELECT '城市'
    UNION ALL SELECT '片区'
    UNION ALL SELECT '镇街'
    UNION ALL SELECT '项目'
) tj ON 1 = 1
WHERE org.组织架构类型 = 3 
    AND org.清洗时间id = @date_id 
    AND org.平台公司名称 = '湾区公司'

UNION ALL

-- 汇总数据直接取项目的，因为业态层级的数据不等于项目层级的数据
SELECT DISTINCT
    org.清洗时间,
    org.组织架构类型, -- 项目维度
    tj.统计维度,
    CASE WHEN tj.统计维度 IN ('公司') THEN '湾区公司' ELSE '无' END AS 公司,
    CASE WHEN tj.统计维度 IN ('城市') THEN org.区域 ELSE '无' END AS 城市,
    CASE WHEN tj.统计维度 IN ('片区') THEN org.销售片区 ELSE '无' END AS 片区,
    CASE WHEN tj.统计维度 IN ('镇街') THEN org.所属镇街 ELSE '无' END AS 镇街,
    CASE WHEN tj.统计维度 IN ('项目') THEN org.项目推广名 ELSE '无' END AS 项目,
    CASE
        WHEN tj.统计维度 IN ('公司') THEN '湾区公司'
        WHEN tj.统计维度 IN ('城市') THEN org.区域
        WHEN tj.统计维度 IN ('片区') THEN org.区域 + '_' + ISNULL(org.销售片区, '无')
        WHEN tj.统计维度 IN ('镇街') THEN org.区域 + '_' + ISNULL(org.销售片区, '无') + '_' + ISNULL(org.所属镇街, '无')
        ELSE org.项目推广名
    END AS 外键关联,
    org.项目guid AS projguid,
    org.组织架构id AS 组织架构id,
    org.项目推广名 AS 组织架构名称,
    t.二级科目
FROM s_WqBaseStatic_summary org
INNER JOIN (
    SELECT '货值' AS 二级科目
    UNION ALL SELECT '面积'
    UNION ALL SELECT '均价'
    UNION ALL SELECT '套数'
) t ON 1 = 1
INNER JOIN (
    SELECT '公司' 统计维度
    UNION ALL SELECT '城市'
    UNION ALL SELECT '片区'
    UNION ALL SELECT '镇街'
    UNION ALL SELECT '项目'
) tj ON 1 = 1
WHERE org.组织架构类型 = 3
    AND org.清洗时间id = @date_id
    AND org.平台公司名称 = '湾区公司'



---- 预处理立项定位数据，针对代建以及老项目等存在没有立项定位数据的话，就取动态总资源
-- 如果立项为0，定位有数据，立项就按定位的数据。
-- 如果立项有数据，定位为0，那定位就按立项的数据。
-- 如果两者都为0，那就按动态总资源的数据。
-- 1、通过项目层级判断应该取哪个版本的数据 
SELECT 
    org.清洗时间,
    org.组织架构id,
    CASE 
        WHEN ISNULL(org.立项货值, 0) = 0 
            THEN (CASE WHEN ISNULL(org.定位最新版货值, 0) = 0 THEN '动态' ELSE '定位' END) 
        ELSE '立项'
    END AS 立项版本,
    CASE 
        WHEN ISNULL(org.定位最新版货值, 0) = 0 
            THEN (CASE WHEN ISNULL(org.立项货值, 0) = 0 THEN '动态' ELSE '立项' END) 
        ELSE '定位'
    END AS 定位版本
INTO #ver03
FROM s_WqBaseStatic_summary org
WHERE org.组织架构类型 = 3
    AND org.清洗时间id = @date_id

-- 2、预处理需要计算的指标
SELECT 
    org.清洗时间, 
    org.组织架构id,
    CASE WHEN ver.立项版本 = '立项' THEN org.立项货值 
         WHEN 立项版本 = '定位' THEN org.定位最新版货值 
         ELSE org.动态总货值金额 END AS 立项货值,
    CASE WHEN ver.立项版本 = '立项' THEN org.立项套数 
         WHEN 立项版本 = '定位' THEN org.定位最新版套数 
         ELSE org.总货值套数 END AS 立项套数,
    CASE WHEN ver.立项版本 = '立项' THEN org.立项总建筑面积 
         WHEN 立项版本 = '定位' THEN org.定位最新版总建筑面积 
         ELSE org.动态总货值面积 END AS 立项总建筑面积,
    CASE WHEN ver.定位版本 = '立项' THEN org.立项货值 
         WHEN 定位版本 = '定位' THEN org.定位最新版货值 
         ELSE org.动态总货值金额 END AS 定位最新版货值,
    CASE WHEN ver.定位版本 = '立项' THEN org.立项套数 
         WHEN 定位版本 = '定位' THEN org.定位最新版套数 
         ELSE org.总货值套数 END AS 定位最新版套数,
    CASE WHEN ver.定位版本 = '立项' THEN org.立项总建筑面积 
         WHEN 定位版本 = '定位' THEN org.定位最新版总建筑面积 
         ELSE org.动态总货值面积 END AS 定位最新版总建筑面积,
    --A=B+C
    动态总货值金额 AS 动态总资源, 
    动态总货值面积 AS 总货值面积,
    总货值套数,
    --A1=A-F2
    动态总货值金额 - 预计3年内不开工货值金额 AS 动态总货值金额_除3年不开工,  
    动态总货值面积 - 预计3年内不开工货值面积 AS 动态总货值面积_除3年不开工,
    总货值套数 - 剩余货值套数_三年内不开工 AS 动态总货值套数_除3年不开工,
    --B
    已售货值金额 AS 累计签约货值,
    已售货值面积 AS 累计签约面积,
    累计签约套数,
    --C=D+E+F
    剩余资源金额 AS 剩余货值金额,
    剩余资源面积 AS 剩余货值面积,
    剩余货值套数,
    --D=D1+D2
    ISNULL(存货货值金额, 0) AS 存货货值金额,
    ISNULL(存货货值面积, 0) AS 存货货值面积,
    ISNULL(剩余可售货值套数, 0) AS 存货货值套数,
    --D1=①+②+③
    ISNULL(存货货值金额, 0) - ISNULL(停工缓建剩余可售货值金额, 0) AS 当前可售货值金额, -- 正常销售
    ISNULL(存货货值面积, 0) - ISNULL(停工缓建剩余可售货值面积, 0) AS 当前可售货值面积,
    ISNULL(剩余可售货值套数, 0) - ISNULL(停工缓建剩余可售货值套数, 0) AS 当前可售货值套数,
    --①
    ISNULL(达形象未取证货值, 0) - ISNULL(停工缓建工程达到可售未拿证货值金额, 0) AS 具备条件未领证金额,
    ISNULL(达形象未取证面积, 0) - ISNULL(停工缓建工程达到可售未拿证货值面积, 0) AS 具备条件未领证面积,
    ISNULL(工程达到可售未拿证货值套数, 0) - ISNULL(停工缓建工程达到可售未拿证货值套数, 0) AS 具备条件未领证套数,
    --②
    ISNULL(获证待推货值, 0) - ISNULL(停工缓建获证未推货值金额, 0) AS 获证待推金额,
    ISNULL(获证待推面积, 0) - ISNULL(停工缓建获证未推货值面积, 0) AS 获证待推面积,
    ISNULL(获证未推货值套数, 0) - ISNULL(停工缓建获证未推货值套数, 0) AS 获证待推套数,
    --③
    ISNULL(已推未售货值, 0) - ISNULL(停工缓建已推未售货值金额, 0) AS 已推未售金额,
    ISNULL(已推未售面积, 0) - ISNULL(停工缓建已推未售货值面积, 0) AS 已推未售面积,
    ISNULL(已推未售货值套数, 0) - ISNULL(停工缓建已推未售货值套数, 0) AS 已推未售套数,
    --D2
    ISNULL(停工缓建剩余可售货值金额, 0) AS 停工缓建剩余可售货值金额,
    ISNULL(停工缓建剩余可售货值面积, 0) AS 停工缓建剩余可售货值面积,
    ISNULL(停工缓建剩余可售货值套数, 0) AS 停工缓建剩余可售货值套数,
    --E=E1+E2
    ISNULL(在途货值金额, 0) AS 在途货值金额合计,
    ISNULL(在途货值面积, 0) AS 在途货值面积合计,
    ISNULL(在途剩余货值套数, 0) AS 在途剩余货值套数合计,
    --E1
    ISNULL(在途货值金额, 0) - ISNULL(停工缓建在途剩余货值金额, 0) AS 在途剩余货值金额,
    ISNULL(在途货值面积, 0) - ISNULL(停工缓建在途剩余货值面积, 0) AS 在途剩余货值面积,
    ISNULL(在途剩余货值套数, 0) - ISNULL(停工缓建在途剩余货值套数, 0) AS 在途剩余货值套数,
    --E2
    ISNULL(停工缓建在途剩余货值金额, 0) AS 停工缓建在途剩余货值金额,
    ISNULL(停工缓建在途剩余货值面积, 0) AS 停工缓建在途剩余货值面积,
    ISNULL(停工缓建在途剩余货值套数, 0) AS 停工缓建在途剩余货值套数,
    --F=F1+F2
    未开工货值金额 AS 未开工剩余货值金额,
    未开工货值面积 AS 未开工剩余货值面积,
    未开工剩余货值套数 AS 未开工剩余货值套数,
    --F1
    ISNULL(未开工货值金额, 0) - ISNULL(预计3年内不开工货值金额, 0) AS 三年内开工剩余货值金额,
    ISNULL(未开工货值面积, 0) - ISNULL(预计3年内不开工货值面积, 0) AS 三年内开工剩余货值面积,
    ISNULL(未开工剩余货值套数, 0) - ISNULL(剩余货值套数_三年内不开工, 0) AS 三年内开工剩余货值套数,
    --F2
    预计3年内不开工货值金额 AS 剩余货值金额_三年内不开工,
    预计3年内不开工货值面积 AS 剩余货值面积_三年内不开工,
    剩余货值套数_三年内不开工,

    停工缓建剩余货值金额,
    停工缓建剩余货值面积,
    停工缓建剩余货值套数

INTO #lxdw03
FROM s_WqBaseStatic_summary org
INNER JOIN #ver03 ver ON org.项目guid = ver.组织架构id
WHERE org.组织架构类型 IN (3, 4)
    AND org.清洗时间id = @date_id
    AND org.平台公司名称 = '湾区公司'


-- 清空当天数据
DELETE FROM wqzydtBi_resourseinfo
WHERE DATEDIFF(dd, 清洗时间, GETDATE()) = 0;

-- 汇总结果插入
INSERT INTO wqzydtBi_resourseinfo
SELECT
    base.清洗时间,
    base.统计维度,
    base.公司,
    base.城市,
    base.片区,
    base.镇街,
    base.项目,
    base.外键关联,
    CASE
        WHEN base.组织架构类型 = 4 THEN base.组织架构名称
        ELSE '汇总'
    END AS 业态,
    CASE
        WHEN base.二级科目 = '货值' THEN '货值（亿元）'
        WHEN base.二级科目 = '面积' THEN '面积（万㎡）'
        WHEN base.二级科目 = '套数' THEN '套数（套）'
        ELSE '均价（元）'
    END AS 二级科目,
    CASE
        WHEN base.组织架构类型 = 4 THEN base.组织架构名称
        ELSE '汇总'
    END + base.二级科目 AS id,
    CASE
        WHEN base.二级科目 = '货值' THEN NULL
        ELSE (CASE WHEN base.组织架构类型 = 4 THEN base.组织架构名称 ELSE '汇总' END) + '货值'
    END AS parentid,
    CASE
        WHEN base.组织架构类型 = 4 THEN 0
        ELSE 1
    END AS 是否加背景色, -- 项目汇总的话，就加背景色

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.立项货值)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.立项总建筑面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.立项套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.立项总建筑面积) = 0 THEN 0
                ELSE SUM(lxdw.立项货值) * 10000.0 / SUM(lxdw.立项总建筑面积)
            END
        ELSE 0
    END AS 立项,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.定位最新版货值)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.定位最新版总建筑面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.定位最新版套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.定位最新版总建筑面积) = 0 THEN 0
                ELSE SUM(lxdw.定位最新版货值) * 10000.0 / SUM(lxdw.定位最新版总建筑面积)
            END
        ELSE 0
    END AS 定位,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.动态总资源)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.总货值面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.总货值套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.总货值面积) = 0 THEN 0
                ELSE SUM(lxdw.动态总资源) * 10000.0 / SUM(lxdw.总货值面积)
            END
        ELSE 0
    END AS 总货量,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.动态总货值金额_除3年不开工)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.动态总货值面积_除3年不开工)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.动态总货值套数_除3年不开工)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.动态总货值面积_除3年不开工) = 0 THEN 0
                ELSE SUM(lxdw.动态总货值金额_除3年不开工) * 10000.0 / SUM(lxdw.动态总货值面积_除3年不开工)
            END
        ELSE 0
    END AS 总货量_除3年不开工,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.累计签约货值)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.累计签约面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.累计签约套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.累计签约面积) = 0 THEN 0
                ELSE SUM(lxdw.累计签约货值) * 10000.0 / SUM(lxdw.累计签约面积)
            END
        ELSE 0
    END AS 已售,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.当前可售货值金额)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.当前可售货值面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.当前可售货值套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.当前可售货值面积) = 0 THEN 0
                ELSE SUM(lxdw.当前可售货值金额) * 10000.0 / SUM(lxdw.当前可售货值面积)
            END
        ELSE 0
    END AS 存货合计,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.具备条件未领证金额)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.具备条件未领证面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.具备条件未领证套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.具备条件未领证面积) = 0 THEN 0
                ELSE SUM(lxdw.具备条件未领证金额) * 10000.0 / SUM(lxdw.具备条件未领证面积)
            END
        ELSE 0
    END AS 达形象未取证剩余货量,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.获证待推金额)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.获证待推面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.获证待推套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.获证待推面积) = 0 THEN 0
                ELSE SUM(lxdw.获证待推金额) * 10000.0 / SUM(lxdw.获证待推面积)
            END
        ELSE 0
    END AS 获证待推剩余货量,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.已推未售金额)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.已推未售面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.已推未售套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.已推未售面积) = 0 THEN 0
                ELSE SUM(lxdw.已推未售金额) * 10000.0 / SUM(lxdw.已推未售面积)
            END
        ELSE 0
    END AS 已推未售,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.在途剩余货值金额)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.在途剩余货值面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.在途剩余货值套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.在途剩余货值面积) = 0 THEN 0
                ELSE SUM(lxdw.在途剩余货值金额) * 10000.0 / SUM(lxdw.在途剩余货值面积)
            END
        ELSE 0
    END AS 在途,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.未开工剩余货值金额)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.未开工剩余货值面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.未开工剩余货值套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.未开工剩余货值面积) = 0 THEN 0
                ELSE SUM(lxdw.未开工剩余货值金额) * 10000.0 / SUM(lxdw.未开工剩余货值面积)
            END
        ELSE 0
    END AS 未开工,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.剩余货值金额_三年内不开工)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.剩余货值面积_三年内不开工)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.剩余货值套数_三年内不开工)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.剩余货值面积_三年内不开工) = 0 THEN 0
                ELSE SUM(lxdw.剩余货值金额_三年内不开工) * 10000.0 / SUM(lxdw.剩余货值面积_三年内不开工)
            END
        ELSE 0
    END AS 预计三年内不开工,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.停工缓建剩余货值金额)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.停工缓建剩余货值面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.停工缓建剩余货值套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.停工缓建剩余货值面积) = 0 THEN 0
                ELSE SUM(lxdw.停工缓建剩余货值金额) * 10000.0 / SUM(lxdw.停工缓建剩余货值面积)
            END
        ELSE 0
    END AS 停工缓建剩余货值,

    -- 新增
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.剩余货值金额)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.剩余货值面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.剩余货值套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.剩余货值面积) = 0 THEN 0
                ELSE SUM(lxdw.剩余货值金额) * 10000.0 / SUM(lxdw.剩余货值面积)
            END
        ELSE 0
    END AS 未售合计,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.存货货值金额)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.存货货值面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.存货货值套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.存货货值面积) = 0 THEN 0
                ELSE SUM(lxdw.存货货值金额) * 10000.0 / SUM(lxdw.存货货值面积)
            END
        ELSE 0
    END AS 存货合计含停工缓建,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.停工缓建剩余可售货值金额)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.停工缓建剩余可售货值面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.停工缓建剩余可售货值套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.停工缓建剩余可售货值面积) = 0 THEN 0
                ELSE SUM(lxdw.停工缓建剩余可售货值金额) * 10000.0 / SUM(lxdw.停工缓建剩余可售货值面积)
            END
        ELSE 0
    END AS 存货停工缓建,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.在途货值金额合计)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.在途货值面积合计)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.在途剩余货值套数合计)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.在途货值面积合计) = 0 THEN 0
                ELSE SUM(lxdw.在途货值金额合计) * 10000.0 / SUM(lxdw.在途货值面积合计)
            END
        ELSE 0
    END AS 在途合计,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.停工缓建在途剩余货值金额)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.停工缓建在途剩余货值面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.停工缓建在途剩余货值套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.停工缓建在途剩余货值面积) = 0 THEN 0
                ELSE SUM(lxdw.停工缓建在途剩余货值金额) * 10000.0 / SUM(lxdw.停工缓建在途剩余货值面积)
            END
        ELSE 0
    END AS 在途停工缓建,

    CASE
        WHEN base.二级科目 = '货值' THEN SUM(lxdw.三年内开工剩余货值金额)
        WHEN base.二级科目 = '面积' THEN SUM(lxdw.三年内开工剩余货值面积)
        WHEN base.二级科目 = '套数' THEN SUM(lxdw.三年内开工剩余货值套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(lxdw.三年内开工剩余货值面积) = 0 THEN 0
                ELSE SUM(lxdw.三年内开工剩余货值金额) * 10000.0 / SUM(lxdw.三年内开工剩余货值面积)
            END
        ELSE 0
    END AS 三年内开工,

    -- 2025-11-11新增字段
    --反算总货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算总货量_总货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算总货量_总面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算总货量_套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算总货量_总面积) = 0 THEN 0
                ELSE SUM(res.反算总货量_总货值)  / SUM(res.反算总货量_总面积)
            END
        ELSE 0
    END AS 反算总货量,
    -- 反算已开工货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算已开工货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算已开工面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算已开工套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算已开工面积) = 0 THEN 0
                ELSE SUM(res.反算已开工货值)  / SUM(res.反算已开工面积)
            END
        ELSE 0
    END AS 反算已开工货量,
    -- 反算剩余货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算剩余货量_剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算剩余货量_剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算剩余货量_剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算剩余货量_剩余面积) = 0 THEN 0
                ELSE SUM(res.反算剩余货量_剩余货值)  / SUM(res.反算剩余货量_剩余面积)
            END
        ELSE 0
    END AS 反算剩余货量, 
    -- 反算存货货量
     CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算存货货量_存货货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算存货货量_存货面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算存货货量_存货套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算存货货量_存货面积) = 0 THEN 0
                ELSE SUM(res.反算存货货量_存货货值)  / SUM(res.反算存货货量_存货面积)
            END
        ELSE 0
    END AS 反算存货货量, 
    -- 反算在途货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算在途货量_在途货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算在途货量_在途面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算在途货量_在途套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算在途货量_在途面积) = 0 THEN 0
                ELSE SUM(res.反算在途货量_在途货值)  / SUM(res.反算在途货量_在途面积)
            END
        ELSE 0
    END AS 反算在途货量, 
    -- 反算未开工货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算未开工货量_未开工货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算未开工货量_未开工面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算未开工货量_未开工套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算未开工货量_未开工面积) = 0 THEN 0
                ELSE SUM(res.反算未开工货量_未开工货值)  / SUM(res.反算未开工货量_未开工面积)
            END
        ELSE 0
    END AS 反算未开工货量,
    -- 当前处置临时冻结合计
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结货值合计)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结面积合计)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结套数合计)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结面积合计) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结货值合计)  / SUM(res.处置前临时冻结面积合计)
            END
        ELSE 0
    END  as [当前处置临时冻结合计],
    -- 当前处置其中：合作受阻
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结_合作受阻冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结_合作受阻冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结_合作受阻冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结_合作受阻冻结面积) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结_合作受阻冻结货值)  / SUM(res.处置前临时冻结_合作受阻冻结面积)
            END
        ELSE 0
    END  as  [当前处置其中：合作受阻],
  -- 开发受限
   CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结_开发受限冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结_开发受限冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结_开发受限冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结_开发受限冻结面积) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结_开发受限冻结货值)  / SUM(res.处置前临时冻结_开发受限冻结面积)
            END
        ELSE 0
    END as  [当前处置其中：开发受限],
    -- 当前处置其中：停工缓建
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结_停工缓建冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结_停工缓建冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结_停工缓建冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结_停工缓建冻结面积) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结_停工缓建冻结货值)  / SUM(res.处置前临时冻结_停工缓建冻结面积)
            END
        ELSE 0
    END  as [当前处置其中：停工缓建],
    -- 当前处置其中：投资未落实
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结_投资未落实冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结_投资未落实冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结_投资未落实冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结_投资未落实冻结面积) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结_投资未落实冻结货值)  / SUM(res.处置前临时冻结_投资未落实冻结面积)
            END
        ELSE 0
    END  as [当前处置其中：投资未落实],
    -- 当前处置退换调转
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前退换调转剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前退换调转剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前退换调转剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前退换调转剩余面积) = 0 THEN 0
                ELSE SUM(res.处置前退换调转剩余货值)  / SUM(res.处置前退换调转剩余面积)
            END
        ELSE 0
    END  as [当前处置退换调转],
    -- 当前处置正常销售
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前正常销售剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前正常销售剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前正常销售剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前正常销售剩余面积) = 0 THEN 0
                ELSE SUM(res.处置前正常销售剩余货值)  / SUM(res.处置前正常销售剩余面积)
            END
        ELSE 0
    END  as [当前处置正常销售],
    -- 当前处置转经营 
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前转经营剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前转经营剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前转经营剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前转经营剩余面积) = 0 THEN 0
                ELSE SUM(res.处置前转经营剩余货值)  / SUM(res.处置前转经营剩余面积)
            END
        ELSE 0
    END  as [当前处置转经营],
    -- 处置前尾盘剩余面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前尾盘剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前尾盘剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前尾盘剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前尾盘剩余面积) = 0 THEN 0
                ELSE SUM(res.处置前尾盘剩余货值)  / SUM(res.处置前尾盘剩余面积)
            END
        ELSE 0
    END as  [尾盘],
    -- 处置后临时冻结合计
   CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结货值合计)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结面积合计)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结套数合计)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结面积合计) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结货值合计)  / SUM(res.处置后临时冻结面积合计)
            END
        ELSE 0
    END  as  [处置后临时冻结合计],
    -- 处置后临时冻结_合作受阻冻结面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结_合作受阻冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结_合作受阻冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结_合作受阻冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结_合作受阻冻结面积) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结_合作受阻冻结货值)  / SUM(res.处置后临时冻结_合作受阻冻结面积)
            END
        ELSE 0
    END as [处置后其中：合作受阻],
    -- 处置后临时冻结_开发受限冻结面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结_开发受限冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结_开发受限冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结_开发受限冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结_开发受限冻结面积) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结_开发受限冻结货值)  / SUM(res.处置后临时冻结_开发受限冻结面积)
            END
        ELSE 0
    END  as [处置后其中：开发受限],
    -- 处置后临时冻结_停工缓建冻结面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结_停工缓建冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结_停工缓建冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结_停工缓建冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结_停工缓建冻结面积) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结_停工缓建冻结货值)  / SUM(res.处置后临时冻结_停工缓建冻结面积)
            END
        ELSE 0
    END  as [处置后其中：停工缓建],
    -- 处置后临时冻结_投资未落实冻结面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结_投资未落实冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结_投资未落实冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结_投资未落实冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结_投资未落实冻结面积) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结_投资未落实冻结货值)  / SUM(res.处置后临时冻结_投资未落实冻结面积)
            END
        ELSE 0
    END  as [处置后其中：投资未落实],
    -- 处置后退换调转剩余
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后退换调转剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后退换调转剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后退换调转剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后退换调转剩余面积) = 0 THEN 0
                ELSE SUM(res.处置后退换调转剩余货值)  / SUM(res.处置后退换调转剩余面积)
            END
        ELSE 0
    END  as [处置后退换调转],
    -- 处置后正常销售剩余
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后正常销售剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后正常销售剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后正常销售剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后正常销售剩余面积) = 0 THEN 0
                ELSE SUM(res.处置后正常销售剩余货值)  / SUM(res.处置后正常销售剩余面积)
            END
        ELSE 0
    END  as [处置后正常销售],
    -- 处置后转经营剩余货值
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后转经营剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后转经营剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后转经营剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后转经营剩余面积) = 0 THEN 0
                ELSE SUM(res.处置后转经营剩余货值)  / SUM(res.处置后转经营剩余面积)
            END
        ELSE 0
    END  as [处置后转经营],
    -- 处置后尾盘
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后尾盘剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后尾盘剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后尾盘剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后尾盘剩余面积) = 0 THEN 0
                ELSE SUM(res.处置后尾盘剩余货值)  / SUM(res.处置后尾盘剩余面积)
            END
        ELSE 0
    END  as  [处置后尾盘],
    -- 新增 销售状态分析字段
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_已推未售剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_已推未售剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_已推未售剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_已推未售剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_已推未售剩余货值)  / SUM(res.已开工剩余货量_已推未售剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量已推未售],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_获证待推剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_获证待推剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_获证待推剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_获证待推剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_获证待推剩余货值)  / SUM(res.已开工剩余货量_获证待推剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量获证待推],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_达形象未取证剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_达形象未取证剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_达形象未取证剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_达形象未取证剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_达形象未取证剩余货值)  / SUM(res.已开工剩余货量_达形象未取证剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量达形象未取证],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_正常在途剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_正常在途剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_正常在途剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_正常在途剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_正常在途剩余货值)  / SUM(res.已开工剩余货量_正常在途剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量正常在途],
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_停工缓建在途剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_停工缓建在途剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_停工缓建在途剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_停工缓建在途剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_停工缓建在途剩余货值)  / SUM(res.已开工剩余货量_停工缓建在途剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量停工缓建在途],
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.未开工剩余货量_停工缓建剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.未开工剩余货量_停工缓建剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.未开工剩余货量_停工缓建剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.未开工剩余货量_停工缓建剩余面积) = 0 THEN 0
                ELSE SUM(res.未开工剩余货量_停工缓建剩余货值)  / SUM(res.未开工剩余货量_停工缓建剩余面积)
            END
        ELSE 0
    END as [未开工剩余货量停工缓建],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.未开工剩余货量_预计三年内开工剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.未开工剩余货量_预计三年内开工剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.未开工剩余货量_预计三年内开工剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.未开工剩余货量_预计三年内开工剩余面积) = 0 THEN 0
                ELSE SUM(res.未开工剩余货量_预计三年内开工剩余货值)  / SUM(res.未开工剩余货量_预计三年内开工剩余面积)
            END
        ELSE 0
    END as [未开工剩余货量预计三年内开工],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.未开工剩余货量_预计三年后开工剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.未开工剩余货量_预计三年后开工剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.未开工剩余货量_预计三年后开工剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.未开工剩余货量_预计三年后开工剩余面积) = 0 THEN 0
                ELSE SUM(res.未开工剩余货量_预计三年后开工剩余货值)  / SUM(res.未开工剩余货量_预计三年后开工剩余面积)
            END
        ELSE 0
    END as [未开工剩余货量预计三年后开工],
    --  建设状态新增字段
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.建设状态_已竣备剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.建设状态_已竣备剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.建设状态_已竣备剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.建设状态_已竣备剩余面积) = 0 THEN 0
                ELSE SUM(res.建设状态_已竣备剩余货值)  / SUM(res.建设状态_已竣备剩余面积)
            END
        ELSE 0
    END 已竣备,
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.建设状态_已达形象未达竣备剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.建设状态_已达形象未达竣备剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.建设状态_已达形象未达竣备剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.建设状态_已达形象未达竣备剩余面积) = 0 THEN 0
                ELSE SUM(res.建设状态_已达形象未达竣备剩余货值)  / SUM(res.建设状态_已达形象未达竣备剩余面积)
            END
        ELSE 0
    END 形象未达竣备,
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.建设状态_已开工未达形象剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.建设状态_已开工未达形象剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.建设状态_已开工未达形象剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.建设状态_已开工未达形象剩余面积) = 0 THEN 0
                ELSE SUM(res.建设状态_已开工未达形象剩余货值)  / SUM(res.建设状态_已开工未达形象剩余面积)
            END
        ELSE 0
    END 开工未达形象,
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.建设状态_停工缓建剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.建设状态_停工缓建剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.建设状态_停工缓建剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.建设状态_停工缓建剩余面积) = 0 THEN 0
                ELSE SUM(res.建设状态_停工缓建剩余货值)  / SUM(res.建设状态_停工缓建剩余面积)
            END
        ELSE 0
    END 停工缓建
FROM
    #baseinfo03 base
    --LEFT JOIN s_WqBaseStatic_summary hz ON base.组织架构id = lxdw.组织架构id   
    LEFT JOIN #lxdw03 lxdw ON base.组织架构id = lxdw.组织架构id AND base.清洗时间 = lxdw.清洗时间
    left join dw_s_WqBaseStatic_CompanyResource  res On base.组织架构id = res.组织架构id and  base.清洗时间 =res.清洗时间
WHERE
    lxdw.立项货值 <> 0
    OR lxdw.动态总资源 <> 0
    OR lxdw.累计签约货值 <> 0
GROUP BY
    base.清洗时间,
    base.统计维度,
    base.公司,
    base.城市,
    base.片区,
    base.镇街,
    base.项目,
    base.外键关联,
    CASE WHEN base.组织架构类型 = 4 THEN base.组织架构名称 ELSE '汇总' END,
    CASE WHEN base.组织架构类型 = 4 THEN base.组织架构名称 ELSE '汇总' END + base.二级科目,
    CASE WHEN base.二级科目 = '货值' THEN NULL ELSE (CASE WHEN base.组织架构类型 = 4 THEN base.组织架构名称 ELSE '汇总' END) + '货值' END,
    CASE WHEN base.组织架构类型 = 4 THEN 0 ELSE 1 END,
    base.二级科目


DROP TABLE #baseinfo03, #lxdw03, #ver03


-------------------------0302 公司资源情况_区域
--缓存项目的维度信息
select distinct
org.清洗时间,
org.组织架构类型, --项目维度
tj.统计维度,
'湾区公司' 外键关联,
org.项目guid as projguid,  
org.组织架构id as 组织架构id,
org.组织架构名称 as 组织架构名称,
t.二级科目 
into #baseinfo03_1
from s_WqBaseStatic_summary org
inner join (select '货值' as 二级科目 union all select '面积' as 二级科目 union all select '均价' as 二级科目 union all select '套数' as 二级科目) t on 1=1
inner join (select '公司' 统计维度) tj on 1=1
where org.组织架构类型 in (2,3)  --获取区域层级和项目层级的数据
and org.清洗时间id = @date_id and org.平台公司名称 = '湾区公司'

----预处理立项定位数据，针对代建以及老项目等存在没有立项定位数据的话，就取动态总资源
-- 如果立项为0，定位有数据，立项就按定位的数据。
-- 如果立项有数据，定位为0，那定位就按立项的数据。
-- 如果两者都为0，那就按动态总资源的数据。
--1、通过项目层级判断应该取哪个版本的数据 
select org.清洗时间,
org.组织架构id,
org.组织架构父级id,
case when isnull(org.立项货值,0)=0 then (case when isnull(org.定位最新版货值,0) = 0 then '动态' else '定位' end) else '立项' end  立项版本,
case when isnull(org.定位最新版货值,0)=0 then (case when isnull(org.立项货值,0) = 0 then '动态' else '立项' end) else '定位' end 定位版本
into #ver02_1
from s_WqBaseStatic_summary org
where org.组织架构类型=3 
and org.清洗时间id = @date_id

select org.清洗时间,
ver.组织架构父级id,
sum(case when ver.立项版本='立项' then org.立项货值 when 立项版本='定位' then org.定位最新版货值 else  org.动态总货值金额 end)  立项货值,
sum(case when ver.立项版本='立项' then org.立项套数 when 立项版本='定位' then org.定位最新版套数 else  org.总货值套数 end)  立项套数,
sum(case when ver.立项版本='立项' then org.立项总建筑面积 when 立项版本='定位' then org.定位最新版总建筑面积 else  org.动态总货值面积 end)  立项总建筑面积,
sum(case when ver.定位版本='立项' then org.立项货值 when 定位版本='定位' then org.定位最新版货值 else  org.动态总货值金额 end) 定位最新版货值,
sum(case when ver.定位版本='立项' then org.立项套数 when 定位版本='定位' then org.定位最新版套数 else  org.总货值套数 end) 定位最新版套数,
sum(case when ver.定位版本='立项' then org.立项总建筑面积 when 定位版本='定位' then org.定位最新版总建筑面积 else  org.动态总货值面积 end) 定位最新版总建筑面积
into #ver03_1
from s_WqBaseStatic_summary org
inner join #ver02_1 ver on org.项目guid = ver.组织架构id
where org.组织架构类型=3 and org.清洗时间id = @date_id and org.平台公司名称 = '湾区公司'
group by org.清洗时间,
ver.组织架构父级id

--2、预处理需要计算的指标
select org.清洗时间, 
org.组织架构id,
ver.立项货值,
ver.立项总建筑面积,
ver.立项套数,
ver.定位最新版货值,
ver.定位最新版总建筑面积,
ver.定位最新版套数,
--A=B+C
动态总货值金额 动态总资源, 
动态总货值面积 总货值面积,
总货值套数,
--A1=A-F2
动态总货值金额 -预计3年内不开工货值金额 动态总货值金额_除3年不开工,  
动态总货值面积 -预计3年内不开工货值面积 动态总货值面积_除3年不开工,
总货值套数 -剩余货值套数_三年内不开工 动态总货值套数_除3年不开工,
--B
已售货值金额 累计签约货值,
已售货值面积 累计签约面积,
累计签约套数,
--C=D+E+F
剩余资源金额 剩余货值金额,
剩余资源面积 剩余货值面积,
剩余货值套数,
--D=D1+D2
isnull(存货货值金额,0) as 存货货值金额,
isnull(存货货值面积,0) as 存货货值面积,
isnull(剩余可售货值套数,0) as 存货货值套数,
--D1=①+②+③
isnull(存货货值金额,0) - isnull(停工缓建剩余可售货值金额,0) 当前可售货值金额, --正常销售
isnull(存货货值面积,0) - isnull(停工缓建剩余可售货值面积,0) 当前可售货值面积,
isnull(剩余可售货值套数,0) - isnull(停工缓建剩余可售货值套数,0) 当前可售货值套数,
--①
isnull(达形象未取证货值,0) - isnull(停工缓建工程达到可售未拿证货值金额,0) 具备条件未领证金额,
isnull(达形象未取证面积,0) - isnull(停工缓建工程达到可售未拿证货值面积,0) 具备条件未领证面积,
isnull(工程达到可售未拿证货值套数,0) - isnull(停工缓建工程达到可售未拿证货值套数,0) 具备条件未领证套数,
--②
isnull(获证待推货值,0)-isnull(停工缓建获证未推货值金额,0) 获证待推金额,
isnull(获证待推面积,0)-isnull(停工缓建获证未推货值面积,0)  获证待推面积,
isnull(获证未推货值套数,0)-isnull(停工缓建获证未推货值套数,0)  获证待推套数,
--③
isnull(已推未售货值,0)-isnull(停工缓建已推未售货值金额,0) 已推未售金额,
isnull(已推未售面积,0)-isnull(停工缓建已推未售货值面积,0) 已推未售面积,
isnull(已推未售货值套数,0)-isnull(停工缓建已推未售货值套数,0) 已推未售套数,
--D2
isnull(停工缓建剩余可售货值金额,0) as 停工缓建剩余可售货值金额,
isnull(停工缓建剩余可售货值面积,0) as 停工缓建剩余可售货值面积,
isnull(停工缓建剩余可售货值套数,0) as 停工缓建剩余可售货值套数,
--E=E1+E2
isnull(在途货值金额,0)  as 在途货值金额合计,
isnull(在途货值面积,0) as 在途货值面积合计,
isnull(在途剩余货值套数,0) 在途剩余货值套数合计,
--E1
isnull(在途货值金额,0)-isnull(停工缓建在途剩余货值金额,0) 在途剩余货值金额,
isnull(在途货值面积,0)-isnull(停工缓建在途剩余货值面积,0) 在途剩余货值面积,
isnull(在途剩余货值套数,0)-isnull(停工缓建在途剩余货值套数,0) 在途剩余货值套数,
--E2
isnull(停工缓建在途剩余货值金额,0) as 停工缓建在途剩余货值金额,
isnull(停工缓建在途剩余货值面积,0) as 停工缓建在途剩余货值面积,
isnull(停工缓建在途剩余货值套数,0) as 停工缓建在途剩余货值套数,
--F=F1+F2
未开工货值金额 未开工剩余货值金额,
未开工货值面积 未开工剩余货值面积,
未开工剩余货值套数 未开工剩余货值套数,
--F1
isnull(未开工货值金额,0) - isnull(预计3年内不开工货值金额,0) as 三年内开工剩余货值金额,
isnull(未开工货值面积,0) - isnull(预计3年内不开工货值面积,0) as 三年内开工剩余货值面积,
isnull(未开工剩余货值套数,0) - isnull(剩余货值套数_三年内不开工,0) as 三年内开工剩余货值套数,
--F2
预计3年内不开工货值金额 剩余货值金额_三年内不开工,  
预计3年内不开工货值面积 剩余货值面积_三年内不开工,
剩余货值套数_三年内不开工,

停工缓建剩余货值金额,
停工缓建剩余货值面积,
停工缓建剩余货值套数
into #lxdw03_1
from s_WqBaseStatic_summary org
inner join #ver03_1 ver on org.组织架构id = ver.组织架构父级id
where org.组织架构类型 =2
and org.清洗时间id = @date_id and org.平台公司名称 = '湾区公司'

--清空当天数据
delete from wqzydtBi_resourseinfo_area where datediff(dd,清洗时间,getdate()) = 0
insert into wqzydtBi_resourseinfo_area
-- 汇总结果
select
    base.清洗时间,
    base.统计维度,
    base.外键关联,
    base.组织架构类型,
    base.组织架构名称,
    case 
        when base.组织架构类型 = 2 then base.组织架构名称
        else '汇总'
    end as 业态,
    case
        when base.二级科目 = '货值' then '货值（亿元）'
        when base.二级科目 = '面积' then '面积（万㎡）'
        when base.二级科目 = '套数' then '套数（套）'
        else '均价（元）'
    end as 二级科目,  
    case 
        when base.组织架构类型 = 2 then base.组织架构名称 
        else '汇总'
    end + base.二级科目 as id,
    case 
        when base.二级科目 = '货值' then null
        else (case when base.组织架构类型 = 2 then base.组织架构名称 else '汇总' end) + '货值'
    end as parentid,
    case 
        when base.组织架构类型 = 2 then 0
        else 1
    end as 是否加背景色, -- 项目汇总的话，就加背景色

    -- 立项
    case
        when base.二级科目 = '货值' then sum(lxdw.立项货值)
        when base.二级科目 = '面积' then sum(lxdw.立项总建筑面积)
        when base.二级科目 = '套数' then sum(lxdw.立项套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.立项总建筑面积) = 0 then 0 else sum(lxdw.立项货值) * 10000.0 / sum(lxdw.立项总建筑面积) end
        else 0
    end as 立项,

    -- 定位
    case
        when base.二级科目 = '货值' then sum(lxdw.定位最新版货值)
        when base.二级科目 = '面积' then sum(lxdw.定位最新版总建筑面积)
        when base.二级科目 = '套数' then sum(lxdw.定位最新版套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.定位最新版总建筑面积) = 0 then 0 else sum(lxdw.定位最新版货值) * 10000.0 / sum(lxdw.定位最新版总建筑面积) end
        else 0
    end as 定位,

    -- 总货量
    case
        when base.二级科目 = '货值' then sum(lxdw.动态总资源)
        when base.二级科目 = '面积' then sum(lxdw.总货值面积)
        when base.二级科目 = '套数' then sum(lxdw.总货值套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.总货值面积) = 0 then 0 else sum(lxdw.动态总资源) * 10000.0 / sum(lxdw.总货值面积) end
        else 0
    end as 总货量,

    -- 总货量_除3年不开工
    case
        when base.二级科目 = '货值' then sum(lxdw.动态总货值金额_除3年不开工)
        when base.二级科目 = '面积' then sum(lxdw.动态总货值面积_除3年不开工)
        when base.二级科目 = '套数' then sum(lxdw.动态总货值套数_除3年不开工)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.动态总货值面积_除3年不开工) = 0 then 0 else sum(lxdw.动态总货值金额_除3年不开工) * 10000.0 / sum(lxdw.动态总货值面积_除3年不开工) end
        else 0
    end as 总货量_除3年不开工,

    -- 已售
    case
        when base.二级科目 = '货值' then sum(lxdw.累计签约货值)
        when base.二级科目 = '面积' then sum(lxdw.累计签约面积)
        when base.二级科目 = '套数' then sum(lxdw.累计签约套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.累计签约面积) = 0 then 0 else sum(lxdw.累计签约货值) * 10000.0 / sum(lxdw.累计签约面积) end
        else 0
    end as 已售,

    -- 存货合计
    case
        when base.二级科目 = '货值' then sum(lxdw.当前可售货值金额)
        when base.二级科目 = '面积' then sum(lxdw.当前可售货值面积)
        when base.二级科目 = '套数' then sum(lxdw.当前可售货值套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.当前可售货值面积) = 0 then 0 else sum(lxdw.当前可售货值金额) * 10000.0 / sum(lxdw.当前可售货值面积) end
        else 0
    end as 存货合计,

    -- 达形象未取证剩余货量
    case
        when base.二级科目 = '货值' then sum(lxdw.具备条件未领证金额)
        when base.二级科目 = '面积' then sum(lxdw.具备条件未领证面积)
        when base.二级科目 = '套数' then sum(lxdw.具备条件未领证套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.具备条件未领证面积) = 0 then 0 else sum(lxdw.具备条件未领证金额) * 10000.0 / sum(lxdw.具备条件未领证面积) end
        else 0
    end as 达形象未取证剩余货量,

    -- 获证待推剩余货量
    case
        when base.二级科目 = '货值' then sum(lxdw.获证待推金额)
        when base.二级科目 = '面积' then sum(lxdw.获证待推面积)
        when base.二级科目 = '套数' then sum(lxdw.获证待推套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.获证待推面积) = 0 then 0 else sum(lxdw.获证待推金额) * 10000.0 / sum(lxdw.获证待推面积) end
        else 0
    end as 获证待推剩余货量,

    -- 已推未售
    case
        when base.二级科目 = '货值' then sum(lxdw.已推未售金额)
        when base.二级科目 = '面积' then sum(lxdw.已推未售面积)
        when base.二级科目 = '套数' then sum(lxdw.已推未售套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.已推未售面积) = 0 then 0 else sum(lxdw.已推未售金额) * 10000.0 / sum(lxdw.已推未售面积) end
        else 0
    end as 已推未售,

    -- 在途
    case
        when base.二级科目 = '货值' then sum(lxdw.在途剩余货值金额)
        when base.二级科目 = '面积' then sum(lxdw.在途剩余货值面积)
        when base.二级科目 = '套数' then sum(lxdw.在途剩余货值套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.在途剩余货值面积) = 0 then 0 else sum(lxdw.在途剩余货值金额) * 10000.0 / sum(lxdw.在途剩余货值面积) end
        else 0
    end as 在途,

    -- 未开工
    case
        when base.二级科目 = '货值' then sum(lxdw.未开工剩余货值金额)
        when base.二级科目 = '面积' then sum(lxdw.未开工剩余货值面积)
        when base.二级科目 = '套数' then sum(lxdw.未开工剩余货值套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.未开工剩余货值面积) = 0 then 0 else sum(lxdw.未开工剩余货值金额) * 10000.0 / sum(lxdw.未开工剩余货值面积) end
        else 0
    end as 未开工,

    -- 预计三年内不开工
    case
        when base.二级科目 = '货值' then sum(lxdw.剩余货值金额_三年内不开工)
        when base.二级科目 = '面积' then sum(lxdw.剩余货值面积_三年内不开工)
        when base.二级科目 = '套数' then sum(lxdw.剩余货值套数_三年内不开工)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.剩余货值面积_三年内不开工) = 0 then 0 else sum(lxdw.剩余货值金额_三年内不开工) * 10000.0 / sum(lxdw.剩余货值面积_三年内不开工) end
        else 0
    end as 预计三年内不开工,

    -- 停工缓建剩余货值
    case
        when base.二级科目 = '货值' then sum(lxdw.停工缓建剩余货值金额)
        when base.二级科目 = '面积' then sum(lxdw.停工缓建剩余货值面积)
        when base.二级科目 = '套数' then sum(lxdw.停工缓建剩余货值套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.停工缓建剩余货值面积) = 0 then 0 else sum(lxdw.停工缓建剩余货值金额) * 10000.0 / sum(lxdw.停工缓建剩余货值面积) end
        else 0
    end as 停工缓建剩余货值,

    -- 新增: 未售合计
    case
        when base.二级科目 = '货值' then sum(lxdw.剩余货值金额)
        when base.二级科目 = '面积' then sum(lxdw.剩余货值面积)
        when base.二级科目 = '套数' then sum(lxdw.剩余货值套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.剩余货值面积) = 0 then 0 else sum(lxdw.剩余货值金额) * 10000.0 / sum(lxdw.剩余货值面积) end
        else 0
    end as 未售合计,

    -- 存货合计含停工缓建
    case
        when base.二级科目 = '货值' then sum(lxdw.存货货值金额)
        when base.二级科目 = '面积' then sum(lxdw.存货货值面积)
        when base.二级科目 = '套数' then sum(lxdw.存货货值套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.存货货值面积) = 0 then 0 else sum(lxdw.存货货值金额) * 10000.0 / sum(lxdw.存货货值面积) end
        else 0
    end as 存货合计含停工缓建,

    -- 存货停工缓建
    case
        when base.二级科目 = '货值' then sum(lxdw.停工缓建剩余可售货值金额)
        when base.二级科目 = '面积' then sum(lxdw.停工缓建剩余可售货值面积)
        when base.二级科目 = '套数' then sum(lxdw.停工缓建剩余可售货值套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.停工缓建剩余可售货值面积) = 0 then 0 else sum(lxdw.停工缓建剩余可售货值金额) * 10000.0 / sum(lxdw.停工缓建剩余可售货值面积) end
        else 0
    end as 存货停工缓建,

    -- 在途合计
    case
        when base.二级科目 = '货值' then sum(lxdw.在途货值金额合计)
        when base.二级科目 = '面积' then sum(lxdw.在途货值面积合计)
        when base.二级科目 = '套数' then sum(lxdw.在途剩余货值套数合计)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.在途货值面积合计) = 0 then 0 else sum(lxdw.在途货值金额合计) * 10000.0 / sum(lxdw.在途货值面积合计) end
        else 0
    end as 在途合计,

    -- 在途停工缓建
    case
        when base.二级科目 = '货值' then sum(lxdw.停工缓建在途剩余货值金额)
        when base.二级科目 = '面积' then sum(lxdw.停工缓建在途剩余货值面积)
        when base.二级科目 = '套数' then sum(lxdw.停工缓建在途剩余货值套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.停工缓建在途剩余货值面积) = 0 then 0 else sum(lxdw.停工缓建在途剩余货值金额) * 10000.0 / sum(lxdw.停工缓建在途剩余货值面积) end
        else 0
    end as 在途停工缓建,

    -- 三年内开工
    case
        when base.二级科目 = '货值' then sum(lxdw.三年内开工剩余货值金额)
        when base.二级科目 = '面积' then sum(lxdw.三年内开工剩余货值面积)
        when base.二级科目 = '套数' then sum(lxdw.三年内开工剩余货值套数)
        when base.二级科目 = '均价' then 
            case when sum(lxdw.三年内开工剩余货值面积) = 0 then 0 else sum(lxdw.三年内开工剩余货值金额) * 10000.0 / sum(lxdw.三年内开工剩余货值面积) end
        else 0
    end as 三年内开工,

    -- 2025-11-11新增字段
    --反算总货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算总货量_总货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算总货量_总面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算总货量_套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算总货量_总面积) = 0 THEN 0
                ELSE SUM(res.反算总货量_总货值)  / SUM(res.反算总货量_总面积)
            END
        ELSE 0
    END AS 反算总货量,
    -- 反算已开工货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算已开工货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算已开工面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算已开工套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算已开工面积) = 0 THEN 0
                ELSE SUM(res.反算已开工货值)  / SUM(res.反算已开工面积)
            END
        ELSE 0
    END AS 反算已开工货量,
    -- 反算剩余货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算剩余货量_剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算剩余货量_剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算剩余货量_剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算剩余货量_剩余面积) = 0 THEN 0
                ELSE SUM(res.反算剩余货量_剩余货值)  / SUM(res.反算剩余货量_剩余面积)
            END
        ELSE 0
    END AS 反算剩余货量, 
    -- 反算存货货量
     CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算存货货量_存货货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算存货货量_存货面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算存货货量_存货套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算存货货量_存货面积) = 0 THEN 0
                ELSE SUM(res.反算存货货量_存货货值)  / SUM(res.反算存货货量_存货面积)
            END
        ELSE 0
    END AS 反算存货货量, 
    -- 反算在途货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算在途货量_在途货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算在途货量_在途面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算在途货量_在途套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算在途货量_在途面积) = 0 THEN 0
                ELSE SUM(res.反算在途货量_在途货值)  / SUM(res.反算在途货量_在途面积)
            END
        ELSE 0
    END AS 反算在途货量, 
    -- 反算未开工货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算未开工货量_未开工货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算未开工货量_未开工面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算未开工货量_未开工套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算未开工货量_未开工面积) = 0 THEN 0
                ELSE SUM(res.反算未开工货量_未开工货值)  / SUM(res.反算未开工货量_未开工面积)
            END
        ELSE 0
    END AS 反算未开工货量,
    -- 当前处置临时冻结合计
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结货值合计)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结面积合计)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结套数合计)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结面积合计) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结货值合计)  / SUM(res.处置前临时冻结面积合计)
            END
        ELSE 0
    END  as [当前处置临时冻结合计],
    -- 当前处置其中：合作受阻
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结_合作受阻冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结_合作受阻冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结_合作受阻冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结_合作受阻冻结面积) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结_合作受阻冻结货值)  / SUM(res.处置前临时冻结_合作受阻冻结面积)
            END
        ELSE 0
    END  as  [当前处置其中：合作受阻],
  -- 开发受限
   CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结_开发受限冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结_开发受限冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结_开发受限冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结_开发受限冻结面积) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结_开发受限冻结货值)  / SUM(res.处置前临时冻结_开发受限冻结面积)
            END
        ELSE 0
    END as  [当前处置其中：开发受限],
    -- 当前处置其中：停工缓建
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结_停工缓建冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结_停工缓建冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结_停工缓建冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结_停工缓建冻结面积) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结_停工缓建冻结货值)  / SUM(res.处置前临时冻结_停工缓建冻结面积)
            END
        ELSE 0
    END  as [当前处置其中：停工缓建],
    -- 当前处置其中：投资未落实
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结_投资未落实冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结_投资未落实冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结_投资未落实冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结_投资未落实冻结面积) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结_投资未落实冻结货值)  / SUM(res.处置前临时冻结_投资未落实冻结面积)
            END
        ELSE 0
    END  as [当前处置其中：投资未落实],
    -- 当前处置退换调转
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前退换调转剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前退换调转剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前退换调转剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前退换调转剩余面积) = 0 THEN 0
                ELSE SUM(res.处置前退换调转剩余货值)  / SUM(res.处置前退换调转剩余面积)
            END
        ELSE 0
    END  as [当前处置退换调转],
    -- 当前处置正常销售
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前正常销售剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前正常销售剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前正常销售剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前正常销售剩余面积) = 0 THEN 0
                ELSE SUM(res.处置前正常销售剩余货值)  / SUM(res.处置前正常销售剩余面积)
            END
        ELSE 0
    END  as [当前处置正常销售],
    -- 当前处置转经营 
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前转经营剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前转经营剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前转经营剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前转经营剩余面积) = 0 THEN 0
                ELSE SUM(res.处置前转经营剩余货值)  / SUM(res.处置前转经营剩余面积)
            END
        ELSE 0
    END  as [当前处置转经营],
    -- 处置前尾盘剩余面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前尾盘剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前尾盘剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前尾盘剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前尾盘剩余面积) = 0 THEN 0
                ELSE SUM(res.处置前尾盘剩余货值)  / SUM(res.处置前尾盘剩余面积)
            END
        ELSE 0
    END as  [尾盘],
    -- 处置后临时冻结合计
   CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结货值合计)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结面积合计)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结套数合计)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结面积合计) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结货值合计)  / SUM(res.处置后临时冻结面积合计)
            END
        ELSE 0
    END  as  [处置后临时冻结合计],
    -- 处置后临时冻结_合作受阻冻结面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结_合作受阻冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结_合作受阻冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结_合作受阻冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结_合作受阻冻结面积) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结_合作受阻冻结货值)  / SUM(res.处置后临时冻结_合作受阻冻结面积)
            END
        ELSE 0
    END as [处置后其中：合作受阻],
    -- 处置后临时冻结_开发受限冻结面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结_开发受限冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结_开发受限冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结_开发受限冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结_开发受限冻结面积) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结_开发受限冻结货值)  / SUM(res.处置后临时冻结_开发受限冻结面积)
            END
        ELSE 0
    END  as [处置后其中：开发受限],
    -- 处置后临时冻结_停工缓建冻结面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结_停工缓建冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结_停工缓建冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结_停工缓建冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结_停工缓建冻结面积) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结_停工缓建冻结货值)  / SUM(res.处置后临时冻结_停工缓建冻结面积)
            END
        ELSE 0
    END  as [处置后其中：停工缓建],
    -- 处置后临时冻结_投资未落实冻结面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结_投资未落实冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结_投资未落实冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结_投资未落实冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结_投资未落实冻结面积) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结_投资未落实冻结货值)  / SUM(res.处置后临时冻结_投资未落实冻结面积)
            END
        ELSE 0
    END  as [处置后其中：投资未落实],
    -- 处置后退换调转剩余
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后退换调转剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后退换调转剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后退换调转剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后退换调转剩余面积) = 0 THEN 0
                ELSE SUM(res.处置后退换调转剩余货值)  / SUM(res.处置后退换调转剩余面积)
            END
        ELSE 0
    END  as [处置后退换调转],
    -- 处置后正常销售剩余
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后正常销售剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后正常销售剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后正常销售剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后正常销售剩余面积) = 0 THEN 0
                ELSE SUM(res.处置后正常销售剩余货值)  / SUM(res.处置后正常销售剩余面积)
            END
        ELSE 0
    END  as [处置后正常销售],
    -- 处置后转经营剩余货值
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后转经营剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后转经营剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后转经营剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后转经营剩余面积) = 0 THEN 0
                ELSE SUM(res.处置后转经营剩余货值)  / SUM(res.处置后转经营剩余面积)
            END
        ELSE 0
    END  as [处置后转经营],
    -- 处置后尾盘
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后尾盘剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后尾盘剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后尾盘剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后尾盘剩余面积) = 0 THEN 0
                ELSE SUM(res.处置后尾盘剩余货值)  / SUM(res.处置后尾盘剩余面积)
            END
        ELSE 0
    END  as  [处置后尾盘],

    -- 新增 销售状态分析字段
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_已推未售剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_已推未售剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_已推未售剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_已推未售剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_已推未售剩余货值)  / SUM(res.已开工剩余货量_已推未售剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量已推未售],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_获证待推剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_获证待推剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_获证待推剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_获证待推剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_获证待推剩余货值)  / SUM(res.已开工剩余货量_获证待推剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量获证待推],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_达形象未取证剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_达形象未取证剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_达形象未取证剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_达形象未取证剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_达形象未取证剩余货值)  / SUM(res.已开工剩余货量_达形象未取证剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量达形象未取证],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_正常在途剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_正常在途剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_正常在途剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_正常在途剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_正常在途剩余货值)  / SUM(res.已开工剩余货量_正常在途剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量正常在途],
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_停工缓建在途剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_停工缓建在途剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_停工缓建在途剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_停工缓建在途剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_停工缓建在途剩余货值)  / SUM(res.已开工剩余货量_停工缓建在途剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量停工缓建在途],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.未开工剩余货量_停工缓建剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.未开工剩余货量_停工缓建剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.未开工剩余货量_停工缓建剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.未开工剩余货量_停工缓建剩余面积) = 0 THEN 0
                ELSE SUM(res.未开工剩余货量_停工缓建剩余货值)  / SUM(res.未开工剩余货量_停工缓建剩余面积)
            END
        ELSE 0
    END as [未开工剩余货量停工缓建],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.未开工剩余货量_预计三年内开工剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.未开工剩余货量_预计三年内开工剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.未开工剩余货量_预计三年内开工剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.未开工剩余货量_预计三年内开工剩余面积) = 0 THEN 0
                ELSE SUM(res.未开工剩余货量_预计三年内开工剩余货值)  / SUM(res.未开工剩余货量_预计三年内开工剩余面积)
            END
        ELSE 0
    END as [未开工剩余货量预计三年内开工],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.未开工剩余货量_预计三年后开工剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.未开工剩余货量_预计三年后开工剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.未开工剩余货量_预计三年后开工剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.未开工剩余货量_预计三年后开工剩余面积) = 0 THEN 0
                ELSE SUM(res.未开工剩余货量_预计三年后开工剩余货值)  / SUM(res.未开工剩余货量_预计三年后开工剩余面积)
            END
        ELSE 0
    END as [未开工剩余货量预计三年后开工],
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.建设状态_已竣备剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.建设状态_已竣备剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.建设状态_已竣备剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.建设状态_已竣备剩余面积) = 0 THEN 0
                ELSE SUM(res.建设状态_已竣备剩余货值)  / SUM(res.建设状态_已竣备剩余面积)
            END
        ELSE 0
    END 已竣备,
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.建设状态_已达形象未达竣备剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.建设状态_已达形象未达竣备剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.建设状态_已达形象未达竣备剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.建设状态_已达形象未达竣备剩余面积) = 0 THEN 0
                ELSE SUM(res.建设状态_已达形象未达竣备剩余货值)  / SUM(res.建设状态_已达形象未达竣备剩余面积)
            END
        ELSE 0
    END 形象未达竣备,
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.建设状态_已开工未达形象剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.建设状态_已开工未达形象剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.建设状态_已开工未达形象剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.建设状态_已开工未达形象剩余面积) = 0 THEN 0
                ELSE SUM(res.建设状态_已开工未达形象剩余货值)  / SUM(res.建设状态_已开工未达形象剩余面积)
            END
        ELSE 0
    END 开工未达形象,
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.建设状态_停工缓建剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.建设状态_停工缓建剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.建设状态_停工缓建剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.建设状态_停工缓建剩余面积) = 0 THEN 0
                ELSE SUM(res.建设状态_停工缓建剩余货值)  / SUM(res.建设状态_停工缓建剩余面积)
            END
        ELSE 0
    END 停工缓建
from #baseinfo03_1 base
left join #lxdw03_1 lxdw on  base.组织架构id = lxdw.组织架构id and base.清洗时间 = lxdw.清洗时间
left join dw_s_WqBaseStatic_CompanyResource  res On base.组织架构id = res.组织架构id and  base.清洗时间 =res.清洗时间
where lxdw.立项货值 <> 0 or lxdw.动态总资源 <> 0
group by
    base.清洗时间,
    base.统计维度,
    base.外键关联,
    base.组织架构类型,
    base.组织架构名称,
    case when base.组织架构类型 = 2 then base.组织架构名称 else '汇总' end,
    case when base.组织架构类型 = 2 then base.组织架构名称 else '汇总' end + base.二级科目,
    case when base.二级科目 = '货值' then null else (case when base.组织架构类型 = 2 then base.组织架构名称 else '汇总' end) + '货值' end,
    case when base.组织架构类型 = 2 then 0 else 1 end,
    base.二级科目

union all

select
    base.清洗时间,
    base.统计维度,
    base.外键关联,
    '1' as 组织架构类型,
    '湾区公司' as 组织架构名称,
    '汇总' as 业态,
    case
        when base.二级科目 = '货值' then '货值（亿元）'
        when base.二级科目 = '面积' then '面积（万㎡）'
        when base.二级科目 = '套数' then '套数（套）'
        else '均价（元）'
    end as 二级科目, 
    '汇总' + base.二级科目 as id,
    case
        when base.二级科目 = '货值' then null
        else '汇总' end + '货值'
    as parentid,
    1 as 是否加背景色, -- 项目汇总的话，就加背景色

    -- 立项
    case
        when base.二级科目 = '货值' then sum(lxdw.立项货值)
        when base.二级科目 = '面积' then sum(lxdw.立项总建筑面积)
        when base.二级科目 = '套数' then sum(lxdw.立项套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.立项总建筑面积) = 0 then 0 else sum(lxdw.立项货值) * 10000.0 / sum(lxdw.立项总建筑面积) end
        else 0
    end as 立项,
    -- 定位
    case
        when base.二级科目 = '货值' then sum(lxdw.定位最新版货值)
        when base.二级科目 = '面积' then sum(lxdw.定位最新版总建筑面积)
        when base.二级科目 = '套数' then sum(lxdw.定位最新版套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.定位最新版总建筑面积) = 0 then 0 else sum(lxdw.定位最新版货值) * 10000.0 / sum(lxdw.定位最新版总建筑面积) end
        else 0
    end as 定位,
    -- 总货量
    case
        when base.二级科目 = '货值' then sum(lxdw.动态总资源)
        when base.二级科目 = '面积' then sum(lxdw.总货值面积)
        when base.二级科目 = '套数' then sum(lxdw.总货值套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.总货值面积) = 0 then 0 else sum(lxdw.动态总资源) * 10000.0 / sum(lxdw.总货值面积) end
        else 0
    end as 总货量,
    -- 总货量_除3年不开工
    case
        when base.二级科目 = '货值' then sum(lxdw.动态总货值金额_除3年不开工)
        when base.二级科目 = '面积' then sum(lxdw.动态总货值面积_除3年不开工)
        when base.二级科目 = '套数' then sum(lxdw.动态总货值套数_除3年不开工)
        when base.二级科目 = '均价' then
            case when sum(lxdw.动态总货值面积_除3年不开工) = 0 then 0 else sum(lxdw.动态总货值金额_除3年不开工) * 10000.0 / sum(lxdw.动态总货值面积_除3年不开工) end
        else 0
    end as 总货量_除3年不开工,
    -- 已售
    case
        when base.二级科目 = '货值' then sum(lxdw.累计签约货值)
        when base.二级科目 = '面积' then sum(lxdw.累计签约面积)
        when base.二级科目 = '套数' then sum(lxdw.累计签约套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.累计签约面积) = 0 then 0 else sum(lxdw.累计签约货值) * 10000.0 / sum(lxdw.累计签约面积) end
        else 0
    end as 已售,
    -- 存货合计
    case
        when base.二级科目 = '货值' then sum(lxdw.当前可售货值金额)
        when base.二级科目 = '面积' then sum(lxdw.当前可售货值面积)
        when base.二级科目 = '套数' then sum(lxdw.当前可售货值套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.当前可售货值面积) = 0 then 0 else sum(lxdw.当前可售货值金额) * 10000.0 / sum(lxdw.当前可售货值面积) end
        else 0
    end as 存货合计,
    -- 达形象未取证剩余货量
    case
        when base.二级科目 = '货值' then sum(lxdw.具备条件未领证金额)
        when base.二级科目 = '面积' then sum(lxdw.具备条件未领证面积)
        when base.二级科目 = '套数' then sum(lxdw.具备条件未领证套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.具备条件未领证面积) = 0 then 0 else sum(lxdw.具备条件未领证金额) * 10000.0 / sum(lxdw.具备条件未领证面积) end
        else 0
    end as 达形象未取证剩余货量,
    -- 获证待推剩余货量
    case
        when base.二级科目 = '货值' then sum(lxdw.获证待推金额)
        when base.二级科目 = '面积' then sum(lxdw.获证待推面积)
        when base.二级科目 = '套数' then sum(lxdw.获证待推套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.获证待推面积) = 0 then 0 else sum(lxdw.获证待推金额) * 10000.0 / sum(lxdw.获证待推面积) end
        else 0
    end as 获证待推剩余货量,
    -- 已推未售
    case
        when base.二级科目 = '货值' then sum(lxdw.已推未售金额)
        when base.二级科目 = '面积' then sum(lxdw.已推未售面积)
        when base.二级科目 = '套数' then sum(lxdw.已推未售套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.已推未售面积) = 0 then 0 else sum(lxdw.已推未售金额) * 10000.0 / sum(lxdw.已推未售面积) end
        else 0
    end as 已推未售,
    -- 在途
    case
        when base.二级科目 = '货值' then sum(lxdw.在途剩余货值金额)
        when base.二级科目 = '面积' then sum(lxdw.在途剩余货值面积)
        when base.二级科目 = '套数' then sum(lxdw.在途剩余货值套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.在途剩余货值面积) = 0 then 0 else sum(lxdw.在途剩余货值金额) * 10000.0 / sum(lxdw.在途剩余货值面积) end
        else 0
    end as 在途,
    -- 未开工
    case
        when base.二级科目 = '货值' then sum(lxdw.未开工剩余货值金额)
        when base.二级科目 = '面积' then sum(lxdw.未开工剩余货值面积)
        when base.二级科目 = '套数' then sum(lxdw.未开工剩余货值套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.未开工剩余货值面积) = 0 then 0 else sum(lxdw.未开工剩余货值金额) * 10000.0 / sum(lxdw.未开工剩余货值面积) end
        else 0
    end as 未开工,
    -- 预计三年内不开工
    case
        when base.二级科目 = '货值' then sum(lxdw.剩余货值金额_三年内不开工)
        when base.二级科目 = '面积' then sum(lxdw.剩余货值面积_三年内不开工)
        when base.二级科目 = '套数' then sum(lxdw.剩余货值套数_三年内不开工)
        when base.二级科目 = '均价' then
            case when sum(lxdw.剩余货值面积_三年内不开工) = 0 then 0 else sum(lxdw.剩余货值金额_三年内不开工) * 10000.0 / sum(lxdw.剩余货值面积_三年内不开工) end
        else 0
    end as 预计三年内不开工,
    -- 停工缓建剩余货值
    case
        when base.二级科目 = '货值' then sum(lxdw.停工缓建剩余货值金额)
        when base.二级科目 = '面积' then sum(lxdw.停工缓建剩余货值面积)
        when base.二级科目 = '套数' then sum(lxdw.停工缓建剩余货值套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.停工缓建剩余货值面积) = 0 then 0 else sum(lxdw.停工缓建剩余货值金额) * 10000.0 / sum(lxdw.停工缓建剩余货值面积) end
        else 0
    end as 停工缓建剩余货值,
    -- 新增: 未售合计
    case
        when base.二级科目 = '货值' then sum(lxdw.剩余货值金额)
        when base.二级科目 = '面积' then sum(lxdw.剩余货值面积)
        when base.二级科目 = '套数' then sum(lxdw.剩余货值套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.剩余货值面积) = 0 then 0 else sum(lxdw.剩余货值金额) * 10000.0 / sum(lxdw.剩余货值面积) end
        else 0
    end as 未售合计,
    -- 存货合计含停工缓建
    case
        when base.二级科目 = '货值' then sum(lxdw.存货货值金额)
        when base.二级科目 = '面积' then sum(lxdw.存货货值面积)
        when base.二级科目 = '套数' then sum(lxdw.存货货值套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.存货货值面积) = 0 then 0 else sum(lxdw.存货货值金额) * 10000.0 / sum(lxdw.存货货值面积) end
        else 0
    end as 存货合计含停工缓建,
    -- 存货停工缓建
    case
        when base.二级科目 = '货值' then sum(lxdw.停工缓建剩余可售货值金额)
        when base.二级科目 = '面积' then sum(lxdw.停工缓建剩余可售货值面积)
        when base.二级科目 = '套数' then sum(lxdw.停工缓建剩余可售货值套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.停工缓建剩余可售货值面积) = 0 then 0 else sum(lxdw.停工缓建剩余可售货值金额) * 10000.0 / sum(lxdw.停工缓建剩余可售货值面积) end
        else 0
    end as 存货停工缓建,
    -- 在途合计
    case
        when base.二级科目 = '货值' then sum(lxdw.在途货值金额合计)
        when base.二级科目 = '面积' then sum(lxdw.在途货值面积合计)
        when base.二级科目 = '套数' then sum(lxdw.在途剩余货值套数合计)
        when base.二级科目 = '均价' then
            case when sum(lxdw.在途货值面积合计) = 0 then 0 else sum(lxdw.在途货值金额合计) * 10000.0 / sum(lxdw.在途货值面积合计) end
        else 0
    end as 在途合计,
    -- 在途停工缓建
    case
        when base.二级科目 = '货值' then sum(lxdw.停工缓建在途剩余货值金额)
        when base.二级科目 = '面积' then sum(lxdw.停工缓建在途剩余货值面积)
        when base.二级科目 = '套数' then sum(lxdw.停工缓建在途剩余货值套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.停工缓建在途剩余货值面积) = 0 then 0 else sum(lxdw.停工缓建在途剩余货值金额) * 10000.0 / sum(lxdw.停工缓建在途剩余货值面积) end
        else 0
    end as 在途停工缓建,
    -- 三年内开工
    case
        when base.二级科目 = '货值' then sum(lxdw.三年内开工剩余货值金额)
        when base.二级科目 = '面积' then sum(lxdw.三年内开工剩余货值面积)
        when base.二级科目 = '套数' then sum(lxdw.三年内开工剩余货值套数)
        when base.二级科目 = '均价' then
            case when sum(lxdw.三年内开工剩余货值面积) = 0 then 0 else sum(lxdw.三年内开工剩余货值金额) * 10000.0 / sum(lxdw.三年内开工剩余货值面积) end
        else 0
    end as 三年内开工,
 -- 2025-11-11新增字段
    --反算总货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算总货量_总货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算总货量_总面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算总货量_套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算总货量_总面积) = 0 THEN 0
                ELSE SUM(res.反算总货量_总货值)  / SUM(res.反算总货量_总面积)
            END
        ELSE 0
    END AS 反算总货量,
    -- 反算已开工货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算已开工货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算已开工面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算已开工套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算已开工面积) = 0 THEN 0
                ELSE SUM(res.反算已开工货值)  / SUM(res.反算已开工面积)
            END
        ELSE 0
    END AS 反算已开工货量,
    -- 反算剩余货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算剩余货量_剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算剩余货量_剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算剩余货量_剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算剩余货量_剩余面积) = 0 THEN 0
                ELSE SUM(res.反算剩余货量_剩余货值)  / SUM(res.反算剩余货量_剩余面积)
            END
        ELSE 0
    END AS 反算剩余货量, 
    -- 反算存货货量
     CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算存货货量_存货货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算存货货量_存货面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算存货货量_存货套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算存货货量_存货面积) = 0 THEN 0
                ELSE SUM(res.反算存货货量_存货货值)  / SUM(res.反算存货货量_存货面积)
            END
        ELSE 0
    END AS 反算存货货量, 
    -- 反算在途货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算在途货量_在途货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算在途货量_在途面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算在途货量_在途套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算在途货量_在途面积) = 0 THEN 0
                ELSE SUM(res.反算在途货量_在途货值)  / SUM(res.反算在途货量_在途面积)
            END
        ELSE 0
    END AS 反算在途货量, 
    -- 反算未开工货量
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.反算未开工货量_未开工货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.反算未开工货量_未开工面积)
        WHEN base.二级科目 = '套数' THEN sum(res.反算未开工货量_未开工套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.反算未开工货量_未开工面积) = 0 THEN 0
                ELSE SUM(res.反算未开工货量_未开工货值)  / SUM(res.反算未开工货量_未开工面积)
            END
        ELSE 0
    END AS 反算未开工货量,
    -- 当前处置临时冻结合计
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结货值合计)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结面积合计)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结套数合计)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结面积合计) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结货值合计)  / SUM(res.处置前临时冻结面积合计)
            END
        ELSE 0
    END  as [当前处置临时冻结合计],
    -- 当前处置其中：合作受阻
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结_合作受阻冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结_合作受阻冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结_合作受阻冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结_合作受阻冻结面积) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结_合作受阻冻结货值)  / SUM(res.处置前临时冻结_合作受阻冻结面积)
            END
        ELSE 0
    END  as  [当前处置其中：合作受阻],
  -- 开发受限
   CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结_开发受限冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结_开发受限冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结_开发受限冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结_开发受限冻结面积) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结_开发受限冻结货值)  / SUM(res.处置前临时冻结_开发受限冻结面积)
            END
        ELSE 0
    END as  [当前处置其中：开发受限],
    -- 当前处置其中：停工缓建
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结_停工缓建冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结_停工缓建冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结_停工缓建冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结_停工缓建冻结面积) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结_停工缓建冻结货值)  / SUM(res.处置前临时冻结_停工缓建冻结面积)
            END
        ELSE 0
    END  as [当前处置其中：停工缓建],
    -- 当前处置其中：投资未落实
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前临时冻结_投资未落实冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前临时冻结_投资未落实冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前临时冻结_投资未落实冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前临时冻结_投资未落实冻结面积) = 0 THEN 0
                ELSE SUM(res.处置前临时冻结_投资未落实冻结货值)  / SUM(res.处置前临时冻结_投资未落实冻结面积)
            END
        ELSE 0
    END  as [当前处置其中：投资未落实],
    -- 当前处置退换调转
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前退换调转剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前退换调转剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前退换调转剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前退换调转剩余面积) = 0 THEN 0
                ELSE SUM(res.处置前退换调转剩余货值)  / SUM(res.处置前退换调转剩余面积)
            END
        ELSE 0
    END  as [当前处置退换调转],
    -- 当前处置正常销售
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前正常销售剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前正常销售剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前正常销售剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前正常销售剩余面积) = 0 THEN 0
                ELSE SUM(res.处置前正常销售剩余货值)  / SUM(res.处置前正常销售剩余面积)
            END
        ELSE 0
    END  as [当前处置正常销售],
    -- 当前处置转经营 
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前转经营剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前转经营剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前转经营剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前转经营剩余面积) = 0 THEN 0
                ELSE SUM(res.处置前转经营剩余货值)  / SUM(res.处置前转经营剩余面积)
            END
        ELSE 0
    END  as [当前处置转经营],
    -- 处置前尾盘剩余面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置前尾盘剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置前尾盘剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置前尾盘剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置前尾盘剩余面积) = 0 THEN 0
                ELSE SUM(res.处置前尾盘剩余货值)  / SUM(res.处置前尾盘剩余面积)
            END
        ELSE 0
    END as  [尾盘],
    -- 处置后临时冻结合计
   CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结货值合计)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结面积合计)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结套数合计)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结面积合计) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结货值合计)  / SUM(res.处置后临时冻结面积合计)
            END
        ELSE 0
    END  as  [处置后临时冻结合计],
    -- 处置后临时冻结_合作受阻冻结面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结_合作受阻冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结_合作受阻冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结_合作受阻冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结_合作受阻冻结面积) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结_合作受阻冻结货值)  / SUM(res.处置后临时冻结_合作受阻冻结面积)
            END
        ELSE 0
    END as [处置后其中：合作受阻],
    -- 处置后临时冻结_开发受限冻结面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结_开发受限冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结_开发受限冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结_开发受限冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结_开发受限冻结面积) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结_开发受限冻结货值)  / SUM(res.处置后临时冻结_开发受限冻结面积)
            END
        ELSE 0
    END  as [处置后其中：开发受限],
    -- 处置后临时冻结_停工缓建冻结面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结_停工缓建冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结_停工缓建冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结_停工缓建冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结_停工缓建冻结面积) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结_停工缓建冻结货值)  / SUM(res.处置后临时冻结_停工缓建冻结面积)
            END
        ELSE 0
    END  as [处置后其中：停工缓建],
    -- 处置后临时冻结_投资未落实冻结面积
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后临时冻结_投资未落实冻结货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后临时冻结_投资未落实冻结面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后临时冻结_投资未落实冻结套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后临时冻结_投资未落实冻结面积) = 0 THEN 0
                ELSE SUM(res.处置后临时冻结_投资未落实冻结货值)  / SUM(res.处置后临时冻结_投资未落实冻结面积)
            END
        ELSE 0
    END  as [处置后其中：投资未落实],
    -- 处置后退换调转剩余
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后退换调转剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后退换调转剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后退换调转剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后退换调转剩余面积) = 0 THEN 0
                ELSE SUM(res.处置后退换调转剩余货值)  / SUM(res.处置后退换调转剩余面积)
            END
        ELSE 0
    END  as [处置后退换调转],
    -- 处置后正常销售剩余
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后正常销售剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后正常销售剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后正常销售剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后正常销售剩余面积) = 0 THEN 0
                ELSE SUM(res.处置后正常销售剩余货值)  / SUM(res.处置后正常销售剩余面积)
            END
        ELSE 0
    END  as [处置后正常销售],
    -- 处置后转经营剩余货值
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后转经营剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后转经营剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后转经营剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后转经营剩余面积) = 0 THEN 0
                ELSE SUM(res.处置后转经营剩余货值)  / SUM(res.处置后转经营剩余面积)
            END
        ELSE 0
    END  as [处置后转经营],
    -- 处置后尾盘
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.处置后尾盘剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.处置后尾盘剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.处置后尾盘剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.处置后尾盘剩余面积) = 0 THEN 0
                ELSE SUM(res.处置后尾盘剩余货值)  / SUM(res.处置后尾盘剩余面积)
            END
        ELSE 0
    END  as  [处置后尾盘],

    -- 新增 销售状态分析字段
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_已推未售剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_已推未售剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_已推未售剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_已推未售剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_已推未售剩余货值)  / SUM(res.已开工剩余货量_已推未售剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量已推未售],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_获证待推剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_获证待推剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_获证待推剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_获证待推剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_获证待推剩余货值)  / SUM(res.已开工剩余货量_获证待推剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量获证待推],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_达形象未取证剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_达形象未取证剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_达形象未取证剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_达形象未取证剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_达形象未取证剩余货值)  / SUM(res.已开工剩余货量_达形象未取证剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量达形象未取证],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_正常在途剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_正常在途剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_正常在途剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_正常在途剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_正常在途剩余货值)  / SUM(res.已开工剩余货量_正常在途剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量正常在途],
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.已开工剩余货量_停工缓建在途剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.已开工剩余货量_停工缓建在途剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.已开工剩余货量_停工缓建在途剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.已开工剩余货量_停工缓建在途剩余面积) = 0 THEN 0
                ELSE SUM(res.已开工剩余货量_停工缓建在途剩余货值)  / SUM(res.已开工剩余货量_停工缓建在途剩余面积)
            END
        ELSE 0
    END as [已开工剩余货量停工缓建在途],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.未开工剩余货量_停工缓建剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.未开工剩余货量_停工缓建剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.未开工剩余货量_停工缓建剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.未开工剩余货量_停工缓建剩余面积) = 0 THEN 0
                ELSE SUM(res.未开工剩余货量_停工缓建剩余货值)  / SUM(res.未开工剩余货量_停工缓建剩余面积)
            END
        ELSE 0
    END as [未开工剩余货量停工缓建],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.未开工剩余货量_预计三年内开工剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.未开工剩余货量_预计三年内开工剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.未开工剩余货量_预计三年内开工剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.未开工剩余货量_预计三年内开工剩余面积) = 0 THEN 0
                ELSE SUM(res.未开工剩余货量_预计三年内开工剩余货值)  / SUM(res.未开工剩余货量_预计三年内开工剩余面积)
            END
        ELSE 0
    END as [未开工剩余货量预计三年内开工],
      CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.未开工剩余货量_预计三年后开工剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.未开工剩余货量_预计三年后开工剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.未开工剩余货量_预计三年后开工剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.未开工剩余货量_预计三年后开工剩余面积) = 0 THEN 0
                ELSE SUM(res.未开工剩余货量_预计三年后开工剩余货值)  / SUM(res.未开工剩余货量_预计三年后开工剩余面积)
            END
        ELSE 0
    END as [未开工剩余货量预计三年后开工],
    -- 建设状态信息字段
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.建设状态_已竣备剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.建设状态_已竣备剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.建设状态_已竣备剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.建设状态_已竣备剩余面积) = 0 THEN 0
                ELSE SUM(res.建设状态_已竣备剩余货值)  / SUM(res.建设状态_已竣备剩余面积)
            END
        ELSE 0
    END 已竣备,
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.建设状态_已达形象未达竣备剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.建设状态_已达形象未达竣备剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.建设状态_已达形象未达竣备剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.建设状态_已达形象未达竣备剩余面积) = 0 THEN 0
                ELSE SUM(res.建设状态_已达形象未达竣备剩余货值)  / SUM(res.建设状态_已达形象未达竣备剩余面积)
            END
        ELSE 0
    END 形象未达竣备,
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.建设状态_已开工未达形象剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.建设状态_已开工未达形象剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.建设状态_已开工未达形象剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.建设状态_已开工未达形象剩余面积) = 0 THEN 0
                ELSE SUM(res.建设状态_已开工未达形象剩余货值)  / SUM(res.建设状态_已开工未达形象剩余面积)
            END
        ELSE 0
    END 开工未达形象,
    CASE
        WHEN base.二级科目 = '货值' THEN SUM(res.建设状态_停工缓建剩余货值)
        WHEN base.二级科目 = '面积' THEN SUM(res.建设状态_停工缓建剩余面积)
        WHEN base.二级科目 = '套数' THEN sum(res.建设状态_停工缓建剩余套数)
        WHEN base.二级科目 = '均价' THEN
            CASE
                WHEN SUM(res.建设状态_停工缓建剩余面积) = 0 THEN 0
                ELSE SUM(res.建设状态_停工缓建剩余货值)  / SUM(res.建设状态_停工缓建剩余面积)
            END
        ELSE 0
    END 停工缓建
FROM  #baseinfo03_1 base
left join #lxdw03_1 lxdw on base.组织架构id = lxdw.组织架构id and base.清洗时间 = lxdw.清洗时间
left join dw_s_WqBaseStatic_CompanyResource  res On base.组织架构id = res.组织架构id and  base.清洗时间 =res.清洗时间
where lxdw.立项货值 <> 0 or lxdw.动态总资源 <> 0
group by
    base.清洗时间,
    base.统计维度,
    base.外键关联,
    case
        when base.二级科目 = '货值' then '货值（亿元）'
        when base.二级科目 = '面积' then '面积（万㎡）'
        else '均价（元）'
    end,
    '汇总' + base.二级科目,
    case when base.二级科目 = '货值' then null else '汇总' end + '货值',
    base.二级科目
 
drop table #baseinfo03_1,#lxdw03_1,#ver02_1,#ver03_1

-------------------------04 产成品情况分析_1
--缓存维度信息
select distinct
org.清洗时间, 
tj.统计维度,
case when tj.统计维度 in ('公司') then '湾区公司' else '无' end  公司,
case when tj.统计维度 in ('城市') then org.区域 else '无' end  城市,
case when tj.统计维度 in ('片区') then org.销售片区 else '无' end 片区,
case when tj.统计维度 in ('镇街') then org.所属镇街 else '无' end 镇街,
case when tj.统计维度 in ('项目') then yt.项目名称 else '无' end  项目,
case when  tj.统计维度 in ('公司') then '湾区公司'
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else yt.项目名称 end 外键关联,
yt.项目名称,
case when case when yt.组织架构名称 in ('别墅') then '高级住宅' else yt.组织架构名称 end in (
'住宅','高级住宅','公寓','商业','写字楼','地下室/车库') then case when yt.组织架构名称 in ('别墅') then '高级住宅' else yt.组织架构名称 end else '其他' end 业态,
ccp.二级科目,
yt.组织架构id 业态id 
into #b04
from s_WqBaseStatic_summary org
inner join (select DISTINCT 组织架构id,组织架构名称,组织架构编码, 项目推广名 as 项目名称 from s_WqBaseStatic_summary org    
where 组织架构类型 = 4 and org.清洗时间id = @date_id)yt on CHARINDEX(org.组织架构编码,yt.组织架构编码)>0
inner join (select '公司' 统计维度 union all select '城市' 统计维度 union all select '片区' 统计维度 union all select '镇街' 统计维度 union all select '项目' 统计维度) tj on 1=1
inner join (select '货值' as 二级科目 union all select '面积' as 二级科目 union all select '均价' as 二级科目) ccp on 1=1
where org.组织架构类型=3 --项目以上层级
and org.清洗时间id = @date_id and org.平台公司名称 = '湾区公司'

--预处理三种场景：项目名称+业态+二级科目、项目+二级科目、项目汇总+二级科目
select base.清洗时间,base.统计维度,base.公司,base.城市,base.片区,base.镇街,base.项目,base.外键关联,base.项目名称,base.业态,base.业态id,
null as 项目名称_展示,base.业态 as 业态_展示,0 是否加背景色,base.二级科目,
base.项目名称+base.业态+base.二级科目 id,base.项目名称+case when base.二级科目 = '面积' then '' else base.业态 end+'面积' parentid
into #baseinfo04
from #b04 base
union all 
select base.清洗时间,base.统计维度,base.公司,base.城市,base.片区,base.镇街,base.项目,base.外键关联,base.项目名称,base.业态,base.业态id,
case when base.二级科目='面积' then base.项目名称 else '' end as 项目名称,'业态合计' 业态,0 是否加背景色,base.二级科目,
base.项目名称+base.二级科目 id,case when base.二级科目 = '面积' then null else base.项目名称+'面积' end parentid
from #b04 base
union all
select base.清洗时间,base.统计维度,base.公司,base.城市,base.片区,base.镇街,base.项目,base.外键关联,base.项目名称,base.业态,base.业态id,
'项目汇总' 项目名称,'业态合计' 业态,1 是否加背景色,base.二级科目,
'项目汇总'+base.二级科目  id,'项目汇总'+case when base.二级科目 = '面积' then  null  else '面积' end parentid
from #b04 base

--清空当天数据
delete from wqzydtBi_productedinfo where datediff(dd,清洗时间,getdate()) = 0
insert into wqzydtBi_productedinfo
--统计产成品情况
select base.清洗时间,
base.统计维度,
base.公司,
base.城市,
base.片区,
base.镇街,
base.项目,
base.外键关联,
base.项目名称_展示 项目名称,
base.业态_展示 业态,
base.id,
base.parentid,
base.是否加背景色
,case when base.二级科目 = '货值' then '货值（亿元）' when base.二级科目 = '面积' then '面积（万㎡）' else '均价（元）' end as 二级科目 
,case when base.二级科目 = '货值' then sum(org.动态总货值金额) when base.二级科目 = '面积' then sum(org.动态总货值面积)
 when base.二级科目 ='均价' then (case when sum(org.动态总货值面积) = 0 then 0 else sum(org.动态总货值金额)*10000.0/sum(org.动态总货值面积) end) 
 else 0 end as 总货值面积 
,case when base.二级科目 = '货值' then sum(org.剩余资源金额) when base.二级科目 = '面积' then sum(org.剩余资源面积)
 when base.二级科目 ='均价' then (case when sum(org.剩余资源面积) = 0 then 0 else sum(org.剩余资源金额)*10000.0/sum(org.剩余资源面积)  end) 
 else 0 end as 剩余货值面积
,case when base.二级科目 = '货值' then sum(org.剩余资源金额)-sum(org.未开工货值金额) when base.二级科目 = '面积' then sum(org.剩余资源面积)-sum(org.未开工货值面积)
 when base.二级科目 ='均价' then (case when (sum(org.剩余资源面积)-sum(org.未开工货值面积)) = 0 then 0 else (sum(org.剩余资源金额)-sum(org.未开工货值金额))*10000.0/(sum(org.剩余资源面积)-sum(org.未开工货值面积))  end) 
 else 0 end  已开工剩余货值金额面积
,case when base.二级科目 = '货值' then sum(年初产成品金额) when base.二级科目 = '面积' then sum(年初产成品面积) 
 when base.二级科目 ='均价' then (case when sum(年初产成品面积) = 0 then 0 else sum(年初产成品金额)*10000.0/sum(年初产成品面积)  end) 
 else 0 end  as 年初产成品剩余货值面积 
,case when base.二级科目 = '货值' then sum(年初准产成品金额) when base.二级科目 = '面积' then sum(年初准产成品面积) 
 when base.二级科目 ='均价' then (case when sum(年初准产成品面积) = 0 then 0 else sum(年初准产成品金额)*10000.0/sum(年初准产成品面积)  end) 
 else 0 end  as 年初准产成品剩余货值面积
-- ,sum(本年已售产成品金额)  as 本年已售产成品金额
,case when base.二级科目 = '货值' then sum(本年已售产成品金额) when base.二级科目 = '面积' then sum(本年已售产成品面积)  
 when base.二级科目 ='均价' then (case when sum(本年已售产成品面积) = 0 then 0 else sum(本年已售产成品金额)*10000.0/sum(本年已售产成品面积)  end) 
 else 0 end as 本年已售产成品面积 
,case when base.二级科目 = '货值' then sum(本年已售准产成品金额) when base.二级科目 = '面积' then sum(本年已售准产成品面积)
 when base.二级科目 ='均价' then (case when sum(本年已售准产成品面积) = 0 then 0 else sum(本年已售准产成品金额)*10000.0/sum(本年已售准产成品面积)  end) 
 else 0 end  as 本年已售准产成品面积 
,case when base.二级科目 = '货值' then sum(预估去化产成品金额) when base.二级科目 = '面积' then sum(预估去化产成品面积) 
 when base.二级科目 ='均价' then (case when sum(预估去化产成品面积) = 0 then 0 else sum(预估去化产成品金额)*10000.0/sum(预估去化产成品面积)  end) 
 else 0 end  as 预估去化产成品面积 
,case when base.二级科目 = '货值' then sum(预估去化准产成品金额) when base.二级科目 = '面积' then sum(预估去化准产成品面积)
 when base.二级科目 ='均价' then (case when sum(预估去化准产成品面积) = 0 then 0 else sum(预估去化准产成品金额)*10000.0/sum(预估去化准产成品面积)  end) 
 else 0 end  as 预估去化准产成品面积 
,case when base.二级科目 = '货值' then sum(预计年底产成品金额) when base.二级科目 = '面积' then sum(预计年底产成品面积) 
 when base.二级科目 ='均价' then (case when sum(预计年底产成品面积) = 0 then 0 else sum(预计年底产成品金额)*10000.0/sum(预计年底产成品面积)  end) 
 else 0 end as 预计年底产成品货值面积
-- ,sum(预计明年准产成品金额) as 预计年底明年准产成品货值金额
,case when base.二级科目 = '货值' then sum(预计明年准产成品金额) when base.二级科目 = '面积' then sum(预计明年准产成品面积) 
 when base.二级科目 ='均价' then (case when sum(预计明年准产成品面积) = 0 then 0 else sum(预计明年准产成品金额)*10000.0/sum(预计明年准产成品面积)  end) 
 else 0 end as 预计年底明年准产成品货值面积 
,case when base.二级科目 = '货值' then sum(动态产成品金额) when base.二级科目 = '面积' then sum(动态产成品面积)
 when base.二级科目 ='均价' then (case when sum(动态产成品面积) = 0 then 0 else sum(动态产成品金额)*10000.0/sum(动态产成品面积)  end) 
 else 0 end as 动态产成品货值面积 
,case when base.二级科目 = '货值' then sum(动态准产成品金额) when base.二级科目 = '面积' then sum(动态准产成品面积) 
 when base.二级科目 ='均价' then (case when sum(动态准产成品面积) = 0 then 0 else sum(动态准产成品金额)*10000.0/sum(动态准产成品面积)  end) 
 else 0 end as 动态准产成品货值面积
from #baseinfo04 base
inner join s_WqBaseStatic_summary org on base.业态id=org.组织架构id and datediff(dd,base.清洗时间,org.清洗时间) = 0
where org.清洗时间id = @date_id
group by base.清洗时间,
base.统计维度,
base.公司,
base.城市,
base.片区,
base.镇街,
base.项目,
base.外键关联,
base.项目名称_展示 ,
base.业态_展示 ,
base.id,
base.parentid,
base.是否加背景色,
base.二级科目
having sum(org.动态总货值金额) <> 0 

drop table #baseinfo04,#b04 


-------------------------05 项目销售利润情况_1 
--缓存业态层级维度信息
select org.清洗时间, 
tj.统计维度,
case when tj.统计维度 in ('公司') then '湾区公司' else '无' end  公司,
case when tj.统计维度 in ('城市') then org.区域 else '无' end  城市,
case when tj.统计维度 in ('片区') then org.销售片区 else '无' end 片区,
case when tj.统计维度 in ('镇街') then org.所属镇街 else '无' end 镇街,
case when tj.统计维度 in ('项目') then yt.项目名称 else '无' end  项目,
case when  tj.统计维度 in ('公司') then '湾区公司'
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else yt.项目名称 end 外键关联,
yt.业态,
yt.项目名称,
yt.存量增量,
yt.组织架构名称,
yt.组织架构id,
yt.组织架构类型 
into #b05
from s_WqBaseStatic_summary org
inner join (select DISTINCT 组织架构id,组织架构名称,项目推广名 项目名称,存量增量,组织架构编码,业态,组织架构类型 from s_WqBaseStatic_summary 
where 组织架构类型 = 5 and 清洗时间id = @date_id)yt on CHARINDEX(org.组织架构编码,yt.组织架构编码)>0
inner join (select '公司' 统计维度 union all select '城市' 统计维度 union all select '片区' 统计维度 union all select '镇街' 统计维度 union all select '项目' 统计维度) tj on 1=1
where org.组织架构类型=3 and org.清洗时间id = @date_id--项目以上层级
and org.平台公司名称 = '湾区公司'
 
--缓存项目层级维度信息
select distinct org.清洗时间, 
tj.统计维度,
case when tj.统计维度 in ('公司') then '湾区公司' else '无' end  公司,
case when tj.统计维度 in ('城市') then org.区域 else '无' end  城市,
case when tj.统计维度 in ('片区') then org.销售片区 else '无' end 片区,
case when tj.统计维度 in ('镇街') then org.所属镇街 else '无' end 镇街,
case when tj.统计维度 in ('项目') then yt.项目名称 else '无' end  项目,
case when  tj.统计维度 in ('公司') then '湾区公司'
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else yt.项目名称 end 外键关联,
-- null as 业态
yt.存量增量,
yt.项目名称 as 组织架构名称,
yt.组织架构id,
yt.组织架构类型  
into #b_proj05
from s_WqBaseStatic_summary org
inner join (select DISTINCT 组织架构id,组织架构名称,存量增量,项目推广名 项目名称,组织架构编码,组织架构类型 from s_WqBaseStatic_summary 
where 组织架构类型 = 3 and 清洗时间id = @date_id)yt on CHARINDEX(org.组织架构编码,yt.组织架构编码)>0
inner join (select '公司' 统计维度 union all select '城市' 统计维度 union all select '片区' 统计维度 union all select '镇街' 统计维度 union all select '项目' 统计维度) tj on 1=1
where org.组织架构类型=3 and org.清洗时间id = @date_id --项目以上层级
and org.平台公司名称 = '湾区公司'

--预处理5种场景：项目汇总+产品合计、项目汇总+产品、存量增量+产品合计、存量增量+项目名称、项目名称+产品
--项目+产品（id：项目名称+产品	parentid：项目名称）
select distinct base.清洗时间,base.统计维度,base.公司,base.城市,base.片区,base.镇街,base.项目,base.外键关联,--base.项目名称,
base.组织架构名称,base.组织架构id,base.组织架构类型,null as 项目名称_展示,base.组织架构名称 as 产品_展示,0 是否加背景色,
base.项目名称+base.组织架构名称 id, base.项目名称 parentid
into #baseinfo05
from #b05 base 
union all 
--项目汇总+产品（id：项目汇总+产品名称	parentid：项目汇总）
select distinct base.清洗时间,base.统计维度,base.公司,base.城市,base.片区,base.镇街,base.项目,base.外键关联,--base.项目名称,
base.组织架构名称,base.组织架构id,base.组织架构类型,'项目汇总' as 项目名称_展示,base.组织架构名称 as 产品_展示,1 是否加背景色,
'项目汇总'+base.组织架构名称 id, '项目汇总' parentid
from #b05 base 
where 组织架构类型 = 5 --产品汇总层级

--项目汇总+产品合计（id：项目汇总 parentid：null）
select distinct base.清洗时间,base.统计维度,base.公司,base.城市,base.片区,base.镇街,base.项目,base.外键关联,--base.组织架构名称 项目名称,
base.组织架构名称,base.组织架构id,base.组织架构类型,'项目汇总' as 项目名称_展示,'产品合计' as 产品_展示,1 是否加背景色,
'项目汇总' id, null parentid
into #baseinfo_proj05
from #b_proj05 base 
where 组织架构类型 = 3 --项目层级
union all
--存量增量+产品合计（id：存量增量	parentid：null）
select distinct base.清洗时间,base.统计维度,base.公司,base.城市,base.片区,base.镇街,base.项目,base.外键关联,--base.组织架构名称 项目名称,
base.组织架构名称,base.组织架构id,base.组织架构类型,base.存量增量 as 项目名称_展示,'产品合计' as 产品_展示,0 是否加背景色,
base.存量增量 id, NULL parentid
from #b_proj05 base 
where 组织架构类型 = 3 --项目层级
union all
--存量增量+项目名称（id：项目名称	parentid：存量增量）
select distinct base.清洗时间,base.统计维度,base.公司,base.城市,base.片区,base.镇街,base.项目,base.外键关联,--base.组织架构名称 项目名称,
base.组织架构名称,base.组织架构id,base.组织架构类型,base.组织架构名称 as 项目名称_展示,'产品合计' as 产品_展示,0 是否加背景色,
base.组织架构名称 id, base.存量增量 parentid
from #b_proj05 base 
where 组织架构类型 = 3 --项目层级


--统计利润情况
select base.清洗时间,
base.统计维度,
base.公司,
base.城市,
base.片区,
base.镇街,
base.项目,
base.外键关联,
base.项目名称_展示 项目名称,
base.产品_展示 产品,
base.id,
base.parentid,
base.是否加背景色
,case when base.项目名称_展示 = '项目汇总' and base.统计维度<> '项目' then (case when sum(lr.剩余面积_利润口径) = 0 then (
    case when sum(lr.累计签约面积_利润口径) = 0 then 0 else sum(case when 业态 = '地下室/车库' then (isnull(累计销售盈利规划营业成本,0)+isnull(累计费用合计,0)+isnull(累计销售盈利规划税金及附加,0))*10000 else (isnull(累计销售盈利规划营业成本,0)+isnull(累计费用合计,0)+isnull(累计销售盈利规划税金及附加,0)) end)*10000.0/sum(lr.累计签约面积_利润口径) end
) else sum(case when 业态 = '地下室/车库' then (isnull(剩余货值销售盈利规划营业成本,0)+isnull(剩余货值销售盈利规划营销费用,0)+isnull(剩余货值销售盈利规划综合管理费,0)+isnull(剩余货值销售盈利规划税金及附加,0))*10000 else (isnull(剩余货值销售盈利规划营业成本,0)+isnull(剩余货值销售盈利规划营销费用,0)+isnull(剩余货值销售盈利规划综合管理费,0)+isnull(剩余货值销售盈利规划税金及附加,0)) end)*10000.0/sum(lr.剩余面积_利润口径) end)
else sum(isnull(费用单方,0)+isnull(税金及附加单方,0)+isnull(营业成本单方,0)) end as 成本单方 --如果是项目的产品成本单方，直接取m002，否则通过计算而来
,sum(isnull(lr.自持盈利规划营销费用单方,0)+isnull(lr.自持盈利规划综合管理费单方协议口径,0)+isnull(lr.自持盈利规划税金及附加单方,0)+isnull(lr.自持盈利规划营业成本单方,0))  as 留置单方
--累计
,case when sum(lr.累计签约面积_利润口径) = 0 then 0 else sum(case when 业态 = '地下室/车库' then lr.累计签约金额_利润口径*10000 else lr.累计签约金额_利润口径 end)*10000.0/sum(lr.累计签约面积_利润口径) end 累计签约单价	
,sum(lr.累计签约面积_利润口径) as 累计签约面积
,sum(lr.累计签约金额_利润口径) as 累计签约金额	
,sum(lr.累计销售净利润账面) as 累计销售净利润账面
,case when sum(lr.累计签约金额不含税) = 0 then 0 else sum(lr.累计销售净利润账面)/sum(lr.累计签约金额不含税) end 累计销售净利率账面 	
,null 股东利润分配
,null 股东利润预分配
--未售
,case when sum(lr.剩余面积_利润口径) = 0 then 0 else sum(case when 业态 = '地下室/车库' then lr.剩余货值金额_利润口径*10000 else lr.剩余货值金额_利润口径 end)*10000.0/sum(lr.剩余面积_利润口径) end  未售均价
,sum(lr.剩余面积_利润口径) as 未售面积
,sum(lr.剩余货值金额_利润口径) as 未售货值	
,sum(lr.剩余货值净利润) as 未售签约净利润
,case when sum(lr.剩余货值不含税) = 0 then 0 else sum(lr.剩余货值净利润)/sum(lr.剩余货值不含税) end as 未售签约净利率
--本年
,case when sum(lr.本年签约面积) = 0 then 0 
   else sum(case when 业态 = '地下室/车库' then lr.本年已签约金额*10000 else lr.本年已签约金额 end)*10000.0 /sum(lr.本年签约面积) end  本年签约单价
,sum(lr.本年签约面积) as 本年签约面积 	
,sum(lr.本年已签约金额) as 本年签约金额
,sum(lr.本年销售净利润账面) as  本年销售净利润账面
,case when sum(lr.本年签约金额不含税) = 0 then 0 else sum(lr.本年销售净利润账面)/sum(lr.本年签约金额不含税) end 本年销售净利率账面 	
--本年预计
,case when sum(lr.本年预计签约面积) = 0 then 0 else sum(case when 业态 = '地下室/车库' then lr.本年预计签约金额*10000 else lr.本年预计签约金额 end )*10000.0/sum(lr.本年预计签约面积) end  本年预计可售均价
,sum(lr.本年预计签约面积) 本年预计可售面积
,sum(lr.本年预计签约金额) 本年预计可售货值
,sum(lr.本年预计销售净利润账面) 本年预计签约净利润
,case when sum(lr.本年预计签约金额不含税) = 0 then 0 else sum(lr.本年预计销售净利润账面)/sum(lr.本年预计签约金额不含税) end 本年预计净利率
--预估全年
,case when sum(lr.预估本年签约面积) = 0 then 0 else sum(case when 业态 = '地下室/车库' then lr.预估本年签约金额*10000 else lr.预估本年签约金额 end )*10000.0/sum(lr.预估本年签约面积) end  预估全年可售均价
,sum(lr.预估本年签约面积) 预估全年签约面积
,sum(lr.预估本年签约金额) 预估全年签约金额
,sum(lr.预估本年销售净利润账面) 预估全年销售毛利润账面
,case when sum(lr.预估全年签约金额不含税) = 0 then 0 else sum(lr.预估本年销售净利润账面)/sum(lr.预估全年签约金额不含税) end 预估全年净利率
--未售实际流速版
,case when sum(lr.剩余货值实际流速版面积) = 0 then 0 else sum(case when 业态 = '地下室/车库' then lr.剩余货值实际流速版金额*10000 else lr.剩余货值实际流速版金额 end)*10000.0/sum(lr.剩余货值实际流速版面积) end  剩余货值实际流速版均价
,sum(lr.剩余货值实际流速版面积) as 剩余货值实际流速版签约面积
,sum(lr.剩余货值实际流速版金额) as 剩余货值实际流速版签约金额	
,sum(lr.剩余货值实际流速版销售净利润账面) as 剩余货值实际流速版净利润
,case when sum(lr.剩余货值实际流速版签约金额不含税) = 0 then 0 else sum(lr.剩余货值实际流速版销售净利润账面)/sum(lr.剩余货值实际流速版签约金额不含税) end as 剩余货值实际流速版净利率
--往年签约本年退房
,case when sum(lr.往年签约本年退房签约面积) = 0 then 0 else sum(case when 业态 = '地下室/车库' then lr.往年签约本年退房签约金额*10000 else lr.往年签约本年退房签约金额 end )*10000.0/sum(lr.往年签约本年退房签约面积) end  往年签约本年退房可售均价
,sum(lr.往年签约本年退房签约面积) 往年签约本年退房签约面积
,sum(lr.往年签约本年退房签约金额) 往年签约本年退房签约金额
,sum(lr.往年签约本年退房销售净利润账面) 往年签约本年退房销售毛利润账面
,case when sum(lr.往年签约本年退房签约金额不含税) = 0 then 0 else sum(lr.往年签约本年退房销售净利润账面)/sum(lr.往年签约本年退房签约金额不含税) end 往年签约本年退房净利率
--本月签约 
,case when sum(lr.本月签约面积_利润口径) = 0 then 0 else sum(case when 业态 = '地下室/车库' then lr.本月签约金额_利润口径*10000 else lr.本月签约金额_利润口径 end)*10000.0/sum(lr.本月签约面积_利润口径) end  本月签约单价
,sum(lr.本月签约面积_利润口径) as 本月签约面积 	
,sum(lr.本月签约金额_利润口径) as 本月签约金额
,sum(lr.本月净利润签约) as  本月净利润签约
,case when sum(lr.本月签约金额不含税) = 0 then 0 else sum(lr.本月净利润签约)/sum(lr.本月签约金额不含税) end 本月销售净利率账面 	
--本月认购 
,case when sum(lr.本月认购面积_利润口径) = 0 then 0 else sum(case when 业态 = '地下室/车库' then lr.本月认购金额_利润口径*10000 else lr.本月认购金额_利润口径 end)*10000.0/sum(lr.本月认购面积_利润口径) end  本月认购单价
,sum(lr.本月认购面积_利润口径) as 本月认购面积 	
,sum(lr.本月认购金额_利润口径) as 本月认购金额
,sum(lr.本月净利润认购) as  本月认购净利润账面
,case when sum(lr.本月认购金额不含税_利润口径) = 0 then 0 else sum(lr.本月净利润认购)/sum(lr.本月认购金额不含税_利润口径) end 本月认购净利率账面
--整盘可售
,case when sum(lr.整盘可售面积) = 0 then 0 else sum(case when 业态 = '地下室/车库' then lr.整盘可售货值*10000 else lr.整盘可售货值 end)*10000.0/sum(lr.整盘可售面积) end 整盘可售单价	
,sum(lr.整盘可售面积) as 整盘可售面积
,sum(lr.整盘可售货值) as 整盘可售货值	
,sum(lr.整盘可售净利润账面) as 整盘可售净利润账面
,case when sum(lr.整盘可售货值不含税) = 0 then 0 else sum(lr.整盘可售净利润账面)/sum(lr.整盘可售货值不含税) end 整盘可售净利率账面
--留置
,sum(case when 业态 = '地下室/车库' then lr.可售且自持车位个数_除人防 else lr.可售且自持面积_除车位 end) 自持面积
,case when sum(isnull(case when 业态 = '地下室/车库' then lr.可售车位个数_除人防 else lr.可售面积_除车位 end,0)+isnull(case when 业态 = '地下室/车库' then lr.可售且自持车位个数_除人防 else lr.可售且自持面积_除车位 end,0) ) = 0 then 
0 else sum(isnull(case when 业态 = '地下室/车库' then lr.可售且自持车位个数_除人防 else lr.可售且自持面积_除车位 end,0))/sum(isnull(case when 业态 = '地下室/车库' then lr.可售车位个数_除人防 else lr.可售面积_除车位 end,0)+isnull(case when 业态 = '地下室/车库' then lr.可售且自持车位个数_除人防 else lr.可售且自持面积_除车位 end,0)) end as 留置比例 --可售且自持面积/业态总可售面积
,sum(lr.固定资产) as 固定资产
into #tmp_result05
from #baseinfo05 base 
left join s_WqBaseStatic_summary lr on base.组织架构id = lr.组织架构id and datediff(dd,base.清洗时间,lr.清洗时间) = 0
where   lr.清洗时间id = @date_id
group by base.清洗时间,
base.统计维度,
base.公司,
base.城市,
base.片区,
base.镇街,
base.项目,
base.外键关联,
base.项目名称_展示,
base.产品_展示,
base.id,
base.parentid,
base.是否加背景色
having sum(lr.累计签约金额) <> 0 or sum(lr.剩余货值金额_利润口径) <> 0 or sum(lr.整盘可售货值)<> 0 or sum(lr.自持面积)<> 0
union all 
select base.清洗时间,
base.统计维度,
base.公司,
base.城市,
base.片区,
base.镇街,
base.项目,
base.外键关联,
base.项目名称_展示 项目名称,
base.产品_展示 产品,
base.id,
base.parentid,
base.是否加背景色
,case when sum(lr.剩余面积不含车位) = 0 then (
case when sum(lr.累计签约面积_利润口径不含车位) = 0 then 0 else sum(isnull(累计销售盈利规划营业成本不含车位,0)+isnull(累计费用合计不含车位,0)+isnull(累计销售盈利规划税金及附加不含车位,0))*10000.0/sum(lr.累计签约面积_利润口径不含车位) end 
) else sum((isnull(剩余货值销售盈利规划营业成本不含车位,0)+isnull(剩余货值销售盈利规划营销费用不含车位,0)+isnull(剩余货值销售盈利规划综合管理费不含车位,0)+isnull(剩余货值销售盈利规划税金及附加不含车位,0)))*10000.0/sum(lr.剩余面积不含车位) end 成本单方
,0 as 留置单方
,case when sum(lr.累计签约面积_利润口径不含车位) = 0 then 0 else sum(lr.累计签约金额不含车位)*10000.0/sum(lr.累计签约面积_利润口径不含车位) end 累计签约单价	
,sum(lr.累计签约面积_利润口径不含车位) as 累计签约面积_利润口径	
,sum(lr.累计签约金额) as 累计签约金额	
,sum(lr.累计销售净利润账面) as 累计销售净利润账面	
,case when sum(lr.累计签约金额不含税) = 0 then 0 else sum(lr.累计销售净利润账面)/sum(lr.累计签约金额不含税) end 累计销售净利率账面 	
,null 股东利润分配
,null 股东利润预分配
--未售
,case when sum(lr.剩余面积不含车位) = 0 then 0 else sum(lr.剩余货值金额不含车位)*10000.0/sum(lr.剩余面积不含车位) end  未售均价
,sum(lr.剩余面积不含车位) as 未售面积
,sum(lr.剩余货值金额_利润口径) as 未售货值	
,sum(lr.剩余货值净利润) as 未售签约净利润
,case when sum(lr.剩余货值不含税) = 0 then 0 else sum(lr.剩余货值净利润)/sum(lr.剩余货值不含税) end as 未售签约净利率
--本年
,case when sum(lr.本年签约面积不含车位) = 0 then 0 else sum(lr.本年签约金额不含车位)*10000.0/sum(lr.本年签约面积不含车位) end  本年签约单价
,sum(lr.本年签约面积不含车位) as 本年签约面积 	
,sum(lr.本年签约金额) as 本年签约金额
,sum(lr.本年销售净利润账面) as  本年销售净利润账面
,case when sum(lr.本年签约金额不含税) = 0 then 0 else sum(lr.本年销售净利润账面)/sum(lr.本年签约金额不含税) end 本年销售净利率账面 	
--本年预计
,case when sum(lr.本年预计签约面积不含车位) = 0 then 0 else sum(lr.本年预计签约金额不含车位)*10000.0/sum(lr.本年预计签约面积不含车位) end  本年预计可售均价
,sum(lr.本年预计签约面积不含车位) 本年预计可售面积
,sum(lr.本年预计签约金额) 本年预计可售货值
,sum(lr.本年预计销售净利润账面) 本年预计签约净利润
,case when sum(lr.本年预计签约金额不含税) = 0 then 0 else sum(lr.本年预计销售净利润账面)/sum(lr.本年预计签约金额不含税) end 本年预计净利率
--预估全年
,case when sum(lr.预估全年签约面积不含车位) = 0 then 0 else sum(lr.预估全年签约金额不含车位)*10000.0/sum(lr.预估全年签约面积不含车位) end  预估全年可售均价
,sum(lr.预估全年签约面积不含车位) 预估全年签约面积不含车位
,sum(lr.预估本年签约金额) 预估全年签约金额
,sum(lr.预估本年销售净利润账面) 预估全年净利润
,case when sum(lr.预估全年签约金额不含税) = 0 then 0 else sum(lr.预估本年销售净利润账面)/sum(lr.预估全年签约金额不含税) end 预估全年净利率
--未售实际流速版
,case when sum(lr.剩余货值实际流速版签约面积不含车位) = 0 then 0 else sum(lr.剩余货值实际流速版签约金额不含车位)*10000.0/sum(lr.剩余货值实际流速版签约面积不含车位) end  剩余货值实际流速版可售均价
,sum(lr.剩余货值实际流速版签约面积不含车位) 剩余货值实际流速版签约面积不含车位
,sum(lr.剩余货值实际流速版金额) 剩余货值实际流速版签约金额
,sum(lr.剩余货值实际流速版净利润) 剩余货值实际流速版净利润
,case when sum(lr.剩余货值实际流速版签约金额不含税) = 0 then 0 else sum(lr.剩余货值实际流速版净利润)/sum(lr.剩余货值实际流速版签约金额不含税) end 剩余货值实际流速版净利率
--往年签约本年退房
,case when sum(lr.往年签约本年退房签约面积不含车位) = 0 then 0 else sum(lr.往年签约本年退房签约金额不含车位)*10000.0/sum(lr.往年签约本年退房签约面积不含车位) end  往年签约本年退房可售均价
,sum(lr.往年签约本年退房签约面积不含车位) 往年签约本年退房签约面积不含车位
,sum(lr.往年签约本年退房签约金额) 往年签约本年退房签约金额
,sum(lr.往年签约本年退房销售净利润账面) 往年签约本年退房净利润
,case when sum(lr.往年签约本年退房签约金额不含税) = 0 then 0 else sum(lr.往年签约本年退房销售净利润账面)/sum(lr.往年签约本年退房签约金额不含税) end 往年签约本年退房净利率
--本月签约 
,case when sum(lr.本月签约面积不含车位) = 0 then 0 else sum(lr.本月签约金额不含车位)*10000.0/sum(lr.本月签约面积不含车位) end  本月签约单价
,sum(lr.本月签约面积不含车位) as 本月签约面积 	
,sum(lr.本月签约金额_利润口径) as 本月签约金额
,sum(lr.本月净利润签约) as  本月净利润签约
,case when sum(lr.本月签约金额不含税) = 0 then 0 else sum(lr.本月净利润签约)/sum(lr.本月签约金额不含税) end 本月销售净利率账面 	
--本月认购 
,case when sum(lr.本月认购面积不含车位) = 0 then 0 else sum(lr.本月认购金额不含车位)*10000.0/sum(lr.本月认购面积不含车位) end  本月认购单价
,sum(lr.本月认购面积不含车位) as 本月认购面积 	
,sum(lr.本月认购金额_利润口径) as 本月认购金额
,sum(lr.本月净利润认购) as  本月净利润认购
,case when sum(lr.本月认购金额不含税_利润口径) = 0 then 0 else sum(lr.本月净利润认购)/sum(lr.本月认购金额不含税_利润口径) end 本月销售净利率账面 
--项目销售利润情况-整盘可售利润
,case when sum(lr.整盘可售面积不含车位) = 0 then 0 else sum(lr.整盘可售货值不含车位)*10000.0/sum(lr.整盘可售面积不含车位) end  整盘可售均价
,sum(lr.整盘可售面积不含车位) as 整盘可售面积
,sum(lr.整盘可售货值) as 整盘可售货值	
,sum(lr.整盘可售净利润账面) as 整盘可售净利润账面
,case when sum(lr.整盘可售货值不含税) = 0 then 0 else sum(lr.整盘可售净利润账面)/sum(lr.整盘可售货值不含税) end as 整盘可售净利率账面
--留置
,sum(lr.可售且自持面积_除车位) as 自持面积 
,case when sum(isnull(lr.可售面积_除车位,0)+isnull(lr.可售且自持面积_除车位,0)) = 0 then 
0 else sum(isnull(lr.可售且自持面积_除车位,0))/sum(isnull(lr.可售面积_除车位,0)+isnull(lr.可售且自持面积_除车位,0)) end as 留置比例
,sum(lr.固定资产) as 固定资产
from #baseinfo_proj05 base 
left join s_WqBaseStatic_summary lr on base.组织架构id = lr.组织架构id and datediff(dd,base.清洗时间,lr.清洗时间) = 0
where  lr.清洗时间id = @date_id 
group by base.清洗时间,
base.统计维度,
base.公司,
base.城市,
base.片区,
base.镇街,
base.项目,
base.外键关联,
base.项目名称_展示,
base.产品_展示,
base.id,
base.parentid,
base.是否加背景色
having sum(lr.累计签约金额) <> 0 or sum(lr.剩余货值金额_利润口径) <> 0 or sum(lr.整盘可售货值)<> 0 or sum(lr.自持面积)<> 0

--清空当天数据
delete from wqzydtBi_saleProfitinfo where datediff(dd,清洗时间,getdate()) = 0

insert into wqzydtBi_saleProfitinfo
--增加预警配置
select 
t.清洗时间,
t.统计维度,
t.公司,
t.城市,
t.片区,
t.镇街,
t.项目,
t.外键关联,
t.项目名称,
t.产品,
t.id,
t.parentid,
t.是否加背景色
,t.成本单方  
--累计
,isnull(t.累计签约单价,0) as 累计签约单价	
,isnull(t.累计签约面积,0) as 累计签约面积
,isnull(t.累计签约金额,0) as 累计签约金额	
,isnull(t.累计销售净利润账面,0) as 累计销售净利润账面
,isnull(t.累计销售净利率账面,0) as 累计销售净利率账面 	
,null 股东利润分配
,null 股东利润预分配
--未售
,isnull(t.未售均价,0) as 未售均价
,isnull(t.未售面积,0) as 未售面积
,isnull(t.未售货值,0) as 未售货值	
,isnull(t.未售签约净利润,0) as 未售签约净利润
,isnull(t.未售签约净利率,0) as 未售签约净利率
--本年
,isnull(t.本年签约单价,0) as 本年签约单价
,isnull(t.本年签约面积,0) as 本年签约面积 	
,isnull(t.本年签约金额,0) as 本年签约金额
,isnull(t.本年销售净利润账面,0) as 本年销售净利润账面
,isnull(t.本年销售净利率账面,0) as 本年销售净利率账面 	
--本年预计
,isnull(t.本年预计可售均价,0) as 本年预计可售均价
,isnull(t.本年预计可售面积,0) as 本年预计可售面积
,isnull(t.本年预计可售货值,0) as 本年预计可售货值
,isnull(t.本年预计签约净利润,0) as 本年预计签约净利润
,isnull(t.本年预计净利率,0) as 本年预计净利率
--预估全年
,isnull(t.预估全年可售均价,0) as 预估全年可售均价
,isnull(t.预估全年签约面积,0) as 预估全年签约面积
,isnull(t.预估全年签约金额,0) as 预估全年签约金额
,isnull(t.预估全年销售毛利润账面,0) as 预估全年销售毛利润账面
,isnull(t.预估全年净利率,0) as 预估全年净利率
--未售实际流速版
,isnull(t.剩余货值实际流速版均价,0) as 剩余货值实际流速版均价
,isnull(t.剩余货值实际流速版签约面积,0) as 剩余货值实际流速版签约面积
,isnull(t.剩余货值实际流速版签约金额,0) as 剩余货值实际流速版签约金额	
,isnull(t.剩余货值实际流速版净利润,0) as 剩余货值实际流速版净利润
,isnull(t.剩余货值实际流速版净利率,0) as 剩余货值实际流速版净利率
--往年签约本年退房
,isnull(t.往年签约本年退房可售均价,0) as 往年签约本年退房可售均价
,isnull(t.往年签约本年退房签约面积,0) as 往年签约本年退房签约面积
,isnull(t.往年签约本年退房签约金额,0) as 往年签约本年退房签约金额
,isnull(t.往年签约本年退房销售毛利润账面,0) as 往年签约本年退房销售毛利润账面
,isnull(t.往年签约本年退房净利率,0) as 往年签约本年退房净利率
,case when 预估全年签约金额<本年预计可售货值 and 是否加背景色 = 1 then 1 
when 预估全年签约金额<本年预计可售货值 and 是否加背景色 = 0 then 2 else 0 end 本年预估全年签约预警
,case when (剩余货值实际流速版签约金额-未售货值)<0.1*未售货值 and  是否加背景色 = 1 then 1 
when (剩余货值实际流速版签约金额-未售货值)<0.1*未售货值 and  是否加背景色 = 0 then  2 else 0 end 全盘剩余货值实际流速版预警
--本月签约 
,isnull(t.本月签约单价,0) as 本月签约单价
,isnull(t.本月签约面积,0) as 本月签约面积 	
,isnull(t.本月签约金额,0) as 本月签约金额
,isnull(t.本月净利润签约,0) as 本月净利润签约
,isnull(t.本月销售净利率账面,0) as 本月销售净利率账面 	
--本月认购 
,isnull(t.本月认购单价,0) as 本月认购单价
,isnull(t.本月认购面积,0) as 本月认购面积 	
,isnull(t.本月认购金额,0) as 本月认购金额
,isnull(t.本月认购净利润账面,0) as 本月认购净利润账面
,isnull(t.本月认购净利率账面,0) as 本月认购净利率账面 
--整盘可售
,isnull(t.整盘可售单价,0) as 整盘可售单价
,isnull(t.整盘可售面积,0) as 整盘可售面积
,isnull(t.整盘可售货值,0) as 整盘可售货值	
,isnull(t.整盘可售净利润账面,0) as 整盘可售净利润账面
,isnull(t.整盘可售净利率账面,0) as 整盘可售净利率账面
--留置
,isnull(t.自持面积,0) as 自持面积 
,isnull(t.留置比例,0) as 留置比例
,isnull(t.固定资产,0) as 固定资产 --自持面积*成本单方
--整盘合计：整盘可售
--,isnull(t.整盘可售净利润账面,0)+isnull(t.固定资产,0) as 整盘合计税后利润 --整盘可售税后利润+固定资产
,isnull(t.整盘可售净利润账面,0) as 整盘合计税后利润 --整盘可售税后利润+固定资产
 from #tmp_result05 t

drop table #baseinfo05,#baseinfo_proj05,#b05,#b_proj05,#tmp_result05

 

-------------------------06 开竣工情况_1
select distinct org.清洗时间,
tj.统计维度 as 统计维度_1,
case when tj.统计维度 in ('公司') then '湾区公司' else '无' end  公司,
case when tj.统计维度 in ('城市') then org.区域 else '无' end  城市,
case when tj.统计维度 in ('片区') then org.销售片区 else '无' end 片区,
case when tj.统计维度 in ('镇街') then org.所属镇街 else '无' end 镇街,
case when tj.统计维度 in ('项目') then yt.项目名称 else '无' end  项目,
case when  tj.统计维度 in ('公司') then '湾区公司'
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else yt.项目名称 end 外键关联,
yt.组织架构id as 业态id, 
case when case when yt.组织架构名称 in ('别墅') then '高级住宅' else yt.组织架构名称 end in (
'住宅','高级住宅','公寓','商业','写字楼','地下室/车库') then case when yt.组织架构名称 in ('别墅') then '高级住宅' else yt.组织架构名称 end else '其他' end as 业态,  
t.时间 as 统计时间
into #baseinfo06
from s_WqBaseStatic_summary org
inner join (
    select '本月' as 时间 union all select '本年' as 时间 union all select '明年' as 时间 union all select '累计' as 时间
) t on 1=1
inner join (select DISTINCT 组织架构父级id,组织架构id,组织架构名称,组织架构编码,业态,项目推广名 项目名称 
from s_WqBaseStatic_summary where 组织架构类型 = 4 and 清洗时间id = @date_id)yt on CHARINDEX(org.组织架构编码,yt.组织架构编码)>0
inner join (select '公司' 统计维度 union all select '城市' 统计维度  union all select '片区' 统计维度 union all select '镇街' 统计维度 union all select '项目' 统计维度) tj on 1=1
where org.组织架构类型=3 and org.清洗时间id = @date_id and org.平台公司名称 = '湾区公司'
  
select base.清洗时间,base.统计维度_1,
base.公司,
base.城市,
base.片区,
base.镇街,
base.项目,
base.外键关联,
base.统计时间,
base.业态 as 统计维度, 
case when base.统计时间 ='本月' then sum(本月计划开工面积) when base.统计时间 ='本年' then sum(本年计划开工面积) 
when base.统计时间 ='明年' then sum(明年计划开工面积) else sum(累计计划开工面积) end 计划开工,
case when base.统计时间 ='本月' then sum(本月计划竣工面积) when base.统计时间 ='本年' then sum(本年计划竣工面积) 
when base.统计时间 ='明年' then sum(明年计划竣工面积) else sum(累计计划竣工面积) end 计划竣工,
case when base.统计时间 ='本月' then sum(本月计划在建面积) when base.统计时间 ='本年' then sum(本年计划在建面积) 
when base.统计时间 ='明年' then sum(明年计划在建面积) else sum(累计计划在建面积) end 计划在建,
case when base.统计时间 ='本月' then sum(本月实际开工面积) when base.统计时间 ='本年' then sum(本年实际开工面积) 
when base.统计时间 ='明年' then null else sum(累计实际开工面积) end 动态开工,
case when base.统计时间 ='本月' then sum(本月实际竣工面积) when base.统计时间 ='本年' then sum(本年实际竣工面积) 
when base.统计时间 ='明年' then null else sum(累计实际竣工面积) end 动态竣工,
case when base.统计时间 ='本月' then sum(本月实际在建面积) when base.统计时间 ='本年' then sum(本年实际在建面积) 
when base.统计时间 ='明年' then null else sum(累计实际在建面积) end 动态在建
into #tmp06
from #baseinfo06 base
inner join s_WqBaseStatic_summary jd on base.业态id = jd.组织架构id
where jd.组织架构类型 in (4) and jd.清洗时间id = @date_id
group by base.统计维度_1,base.清洗时间,
base.公司,
base.城市,
base.片区,
base.镇街,
base.项目,
base.外键关联,
base.统计时间,
base.业态 

--清空当天数据
delete from wqzydtBi_scheduleinfo where datediff(dd,清洗时间,getdate()) = 0
insert into wqzydtBi_scheduleinfo
select * from #tmp06  
where (计划开工<>0 or 动态开工 <>0 or 计划竣工<>0 or 动态竣工 <>0 or 动态在建<> 0 or 计划在建 <>0)

drop table #baseinfo06,#tmp06



-------------------------07 产存销情况_1
--缓存统计维度
select distinct org.清洗时间,
tj.统计维度,
case when tj.统计维度 in ('公司') then '湾区公司' else '无' end  公司,
case when tj.统计维度 in ('城市') then org.区域 else '无' end  城市,
case when tj.统计维度 in ('片区') then org.销售片区 else '无' end 片区,
case when tj.统计维度 in ('镇街') then org.所属镇街 else '无' end 镇街,
case when tj.统计维度 in ('项目') then hx.项目名称 else '无' end  项目,
case when  tj.统计维度 in ('公司') then '湾区公司'
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else hx.项目名称 end 外键关联,
hx.业态,
hx.产品名称,
case when hx.组织架构类型 = 8 then hx.组织架构名称 else null end as 户型,
hx.组织架构名称,
hx.组织架构id,
hx.组织架构类型,
t.Date_YearMonth as 时间维度,
t.Date_MonthDIFDay as 月份差
into #baseinfo07 
from s_WqBaseStatic_summary org
inner join (select distinct Date_YearMonth,Date_MonthDIFDay from dw_d_date where Date_MonthDIFDay between -11 and 0) t on 1=1
inner join (select DISTINCT 组织架构id,组织架构名称,产品名称,组织架构编码,项目推广名 项目名称,业态,组织架构类型
from s_WqBaseStatic_summary where 组织架构类型 in (4,5,8) and 清洗时间id = @date_id) hx on CHARINDEX(org.组织架构编码,hx.组织架构编码)>0
--统计维度
inner join (select '公司' 统计维度 union all select '城市' 统计维度 union all select '片区' 统计维度 union all select '镇街' 统计维度 union all select '项目' 统计维度) tj on 1=1
where org.组织架构类型=3 and org.清洗时间id = @date_id and org.平台公司名称 = '湾区公司' 
AND hx.业态 IN ('住宅','地下室/车库','公寓','商业','高级住宅','写字楼')

--缓存计算过程中的维度主表:业态-产品名称-户型分层级展开
--户型是id,产品名称是父级id
select distinct b.清洗时间,
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联,
b.业态,
b.产品名称,
b.户型, 
b.时间维度,
b.月份差,
b.组织架构id,
b.业态+'_'+b.产品名称+'_'+b.组织架构名称 id,
b.业态+'_'+b.产品名称 parentid
into #baseinfo_107
from #baseinfo07 b
where 组织架构类型 =8
union all 
--产品名称是iD,业态是父级id
select distinct b.清洗时间,
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联,
b.业态,
b.产品名称,
null 户型, 
b.时间维度,
b.月份差,
b.组织架构id,
b.业态+'_'+b.产品名称 id,
b.业态 parentid
from #baseinfo07 b 
where 组织架构类型 =5
union all 
--业态是id
select distinct b.清洗时间,
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联,
b.业态,
null 产品名称,
null 户型, 
b.时间维度,
b.月份差,
b.组织架构id,
b.业态 id,
null parentid
from #baseinfo07 b
where 组织架构类型=4

--缓存基本信息
--户型层级
select b.清洗时间,
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联,
b.业态,
b.产品名称,
b.户型, 
b.时间维度,
b.月份差,
sum(近3月平均签约流速) 近三月流速,
sum(isnull(当前存货面积,0)) 当前存货面积, 
sum(isnull(当前已开工未售面积,0)) 当前已开工未售面积,
sum(isnull(存货货值面积,0)) 存货货值面积, 
sum(isnull(已开工未售面积,0)) 已开工未售面积,
b.业态+'_'+b.产品名称+'_'+b.户型 id,
b.业态+'_'+b.产品名称 parentid
into #tmp_result07
from #baseinfo07 B
inner join dw_s_WqBaseStatic_ProdMarkInfo_month pm on b.组织架构id  = pm.组织架构id and b.月份差 = pm.月份差 and datediff(dd,b.清洗时间,pm.清洗时间) = 0
where b.月份差 = 0 and pm.清洗时间id = @date_id and pm.组织架构类型= 8
group by b.统计维度,b.清洗时间,b.公司,b.城市,b.片区,b.镇街,b.项目,b.外键关联,b.业态,b.产品名称,b.户型, b.时间维度,b.月份差

insert into #tmp_result07
select b.清洗时间,
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联,
b.业态,
b.产品名称,
null 户型, 
b.时间维度,
b.月份差,
sum(近3月平均签约流速) 近三月流速,
sum(isnull(当前存货面积,0)) 当前存货面积, 
sum(isnull(当前已开工未售面积,0)) 当前已开工未售面积,
sum(isnull(存货货值面积,0)) 存货货值面积, 
sum(isnull(已开工未售面积,0)) 已开工未售面积,
b.业态+'_'+b.产品名称 id,
b.业态 parentid
from #baseinfo07 B
inner join dw_s_WqBaseStatic_ProdMarkInfo_month pm on b.组织架构id  = pm.组织架构id and b.月份差 = pm.月份差 and datediff(dd,b.清洗时间,pm.清洗时间) = 0
where b.月份差 = 0 and pm.清洗时间id = @date_id and pm.组织架构类型= 5
group by b.统计维度,b.清洗时间,b.公司,b.城市,b.片区,b.镇街,b.项目,b.外键关联,b.业态,b.产品名称, b.时间维度,b.月份差
union ALL
select b.清洗时间,
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联,
b.业态,
null 产品名称,
null 户型, 
b.时间维度,
b.月份差,
sum(近3月平均签约流速) 近三月流速,
sum(isnull(当前存货面积,0)) 当前存货面积, 
sum(isnull(当前已开工未售面积,0)) 当前已开工未售面积,
sum(isnull(存货货值面积,0)) 存货货值面积, 
sum(isnull(已开工未售面积,0)) 已开工未售面积,
b.业态 id,
null parentid
from #baseinfo07 B
inner join dw_s_WqBaseStatic_ProdMarkInfo_month pm on b.组织架构id  = pm.组织架构id and b.月份差 = pm.月份差 and datediff(dd,b.清洗时间,pm.清洗时间) = 0
where b.月份差 = 0 and pm.清洗时间id = @date_id and pm.组织架构类型= 4
group by b.统计维度,b.清洗时间,b.公司,b.城市,b.片区,b.镇街,b.项目,b.外键关联,b.业态, b.时间维度,b.月份差

 

--缓存本月新增货值情况
--户型
select b.清洗时间,
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联,
b.业态,
b.产品名称,
b.户型, 
b.时间维度,
b.月份差,
sum(isnull(本月预计新增存货面积,0)) 本月预计新增存货面积, 
sum(isnull(本月预计新增已开工未售面积,0)) 本月预计新增已开工未售面积,
b.业态+'_'+b.产品名称+'_'+b.户型 id,
b.业态+'_'+b.产品名称 parentid
into #tmp_result_yj07
from #baseinfo07 B
inner join dw_s_WqBaseStatic_ProdMarkInfo_month pm on b.组织架构id  = pm.组织架构id and b.月份差 = pm.月份差 and datediff(dd,b.清洗时间,pm.清洗时间) = 0
where  pm.清洗时间id = @date_id and pm.组织架构类型= 8
group by b.清洗时间,b.统计维度,b.公司,b.城市,b.片区,b.镇街,b.项目,b.外键关联,b.业态,b.产品名称,b.户型, b.时间维度,b.月份差

insert into #tmp_result_yj07
select b.清洗时间,
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联,
b.业态,
b.产品名称,
null 户型, 
b.时间维度,
b.月份差,
sum(isnull(本月预计新增存货面积,0)) 本月预计新增存货面积, 
sum(isnull(本月预计新增已开工未售面积,0)) 本月预计新增已开工未售面积,
b.业态+'_'+b.产品名称 id,
b.业态 parentid 
from #baseinfo07 B
inner join dw_s_WqBaseStatic_ProdMarkInfo_month pm on b.组织架构id  = pm.组织架构id and b.月份差 = pm.月份差 and datediff(dd,b.清洗时间,pm.清洗时间) = 0
where pm.清洗时间id = @date_id   and pm.组织架构类型= 5
group by b.清洗时间,b.统计维度,b.公司,b.城市,b.片区,b.镇街,b.项目,b.外键关联,b.业态,b.产品名称, b.时间维度,b.月份差
union all
select b.清洗时间,
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联,
b.业态,
null 产品名称,
null 户型, 
b.时间维度,
b.月份差,
sum(isnull(本月预计新增存货面积,0)) 本月预计新增存货面积, 
sum(isnull(本月预计新增已开工未售面积,0)) 本月预计新增已开工未售面积,
b.业态 id,
null parentid 
from #baseinfo07 B
inner join dw_s_WqBaseStatic_ProdMarkInfo_month pm on b.组织架构id  = pm.组织架构id and b.月份差 = pm.月份差 and datediff(dd,b.清洗时间,pm.清洗时间) = 0
where  pm.清洗时间id = @date_id and pm.组织架构类型= 4
group by b.清洗时间,b.统计维度,b.公司,b.城市,b.片区,b.镇街,b.项目,b.外键关联,b.业态,b.时间维度,b.月份差

--维度表去重
select distinct 清洗时间,	统计维度,	公司,	城市,	片区,	镇街,	项目,	外键关联,	业态,	产品名称,	户型,	时间维度,	月份差,	
id,	parentid  
into #baseinfo_107_1
from #baseinfo_107

declare @月份差 int = -1

while(@月份差 >= -11)
begin   

    --循环插入未来11个月的情况
    insert into #tmp_result07
        select b.清洗时间,b.统计维度,
        b.公司,
        b.城市,
        b.片区,
        b.镇街,
        b.项目,
        b.外键关联,
    	b.业态,
        b.产品名称,
        b.户型,
        b.时间维度, b.月份差,近三月流速, 当前存货面积,当前已开工未售面积,
        case when t.存货货值面积+isnull(yj.本月预计新增存货面积,0)>isnull(t.近三月流速,0) then t.存货货值面积+isnull(yj.本月预计新增存货面积,0)-isnull(t.近三月流速,0) else 0 end 存货面积,
        case when t.已开工未售面积+isnull(yj.本月预计新增存货面积,0)>isnull(t.近三月流速,0) then t.已开工未售面积+isnull(yj.本月预计新增已开工未售面积,0)-isnull(t.近三月流速,0) else 0 end 已开工未售面积
        ,b.id,b.parentid
    	from #baseinfo_107_1 B
        inner join #tmp_result07 t on B.统计维度 = t.统计维度 and B.月份差 = t.月份差 - 1 and isnull(b.户型,'') = isnull(t.户型,'')
        and isnull(b.产品名称,'') = isnull(t.产品名称,'') and B.外键关联 = t.外键关联  and b.id = t.id
        left join #tmp_result_yj07 yj on B.统计维度 = yj.统计维度 and B.月份差 = yj.月份差 and isnull(b.户型,'') = isnull(yj.户型,'')
        and isnull(b.产品名称,'') = isnull(yj.产品名称,'') and B.外键关联 = yj.外键关联  and b.id = yj.id
        where b.月份差 = @月份差
    
    set @月份差 = @月份差-1
end  

--清空当天数据
delete from wqzydtBi_product_rest where datediff(dd,清洗时间,getdate()) = 0

insert into wqzydtBi_product_rest
select 
t.清洗时间,	t.统计维度,	t.公司,	t.城市,	t.片区,	t.镇街,	t.项目,	t.外键关联,		t.产品名称,	t.户型,	t.时间维度,	
t.月份差,	t.近三月流速,	t.当前存货面积,	t.当前已开工未售面积,	t.存货货值面积,	t.已开工未售面积,	
case when t.近三月流速 = 0 then 0 else 存货货值面积/近三月流速 end  存销比,
case when t.近三月流速 = 0 then 0 else 已开工未售面积/近三月流速 end 产销比,
t.业态,t.id,t.parentid
 from  #tmp_result07 t 

 --删除临时表
drop table #baseinfo07,#tmp_result07,#tmp_result_yj07,#baseinfo_107,#baseinfo_107_1
-------------------------08 剩余货值分析_1
select distinct org.清洗时间, 
tj.统计维度,
case when tj.统计维度 in ('公司') then '湾区公司' else '无' end  公司,
case when tj.统计维度 in ('城市') then org.区域 else '无' end  城市,
case when tj.统计维度 in ('片区') then org.销售片区 else '无' end 片区,
case when tj.统计维度 in ('镇街') then org.所属镇街 else '无' end 镇街,
case when tj.统计维度 in ('项目') then yt.项目名称 else '无' end  项目,
case when  tj.统计维度 in ('公司') then '湾区公司'
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else yt.项目名称 end 外键关联,
yt.组织架构id as 业态id,
yt.项目所属城市 as 城市统计维度,
qw.统计维度 区位,
case when qw.统计维度='地上' then 地上建筑面积占比 else 地下建筑面积占比 end 区位占比,
case when case when yt.组织架构名称 in ('别墅') then '高级住宅' else yt.组织架构名称 end in (
'住宅','高级住宅','公寓','商业','写字楼','地下室/车库') then case when yt.组织架构名称 in ('别墅') then '高级住宅' else yt.组织架构名称 end else '其他' end 业态
into #baseinfo08
from s_WqBaseStatic_summary org
inner join (select org.组织架构id,org.组织架构名称,org.组织架构编码,org.项目推广名 项目名称, org.项目guid, org.项目所属城市,
    case when sum(isnull(总建筑面积,0)) = 0 then 0 else sum(isnull(地上建筑面积,0))*1.0/sum(isnull(总建筑面积,0)) end as 地上建筑面积占比,
    case when sum(isnull(总建筑面积,0)) = 0 then 0 else sum(isnull(地下建筑面积,0))*1.0/sum(isnull(总建筑面积,0)) end as 地下建筑面积占比 
    from s_WqBaseStatic_summary org
    where org.组织架构类型 = 4 and org.清洗时间id = @date_id
    group by org.组织架构id,org.组织架构名称,org.组织架构编码,org.项目推广名, org.项目guid,org.项目所属城市
)yt on   CHARINDEX(org.组织架构编码,yt.组织架构编码)>0
inner join (select '公司' 统计维度 union all select '城市' 统计维度 union all select '片区' 统计维度 union all select '镇街' 统计维度 union all select '项目' 统计维度) tj on 1=1
inner join (select '地下' 统计维度 union all select '地上' 统计维度) qw on 1=1
where org.组织架构类型=3 and org.平台公司名称 = '湾区公司'and org.清洗时间id = @date_id--项目以上层级

--清空当天数据
delete from wqzydtBi_restsalevalue where datediff(dd,清洗时间,getdate()) = 0

insert into wqzydtBi_restsalevalue
select t.清洗时间,
t.统计维度,
t.公司,
t.城市,
t.片区,
t.镇街,
t.项目,
t.外键关联,
t.业态,
t.城市统计维度,
t.区位, 
sum(t.年初剩余货值*区位占比) as 年初剩余货值 ,
sum(t.年初剩余货值面积*区位占比) as 年初剩余货值面积 ,
sum(t.剩余货值金额*区位占比) as 剩余货值金额 ,
sum(t.剩余货值面积*区位占比) as 剩余货值面积 ,
sum(t.预计年底剩余货值*区位占比) as 预计年底剩余货值 ,
sum(t.预计年底剩余货值面积*区位占比) as 预计年底剩余货值面积
from (
select org.清洗时间,
org.统计维度,
org.公司,
org.城市,
org.片区,
org.镇街,
org.项目,
org.外键关联,
org.业态,
org.城市统计维度,
org.区位,
org.区位占比,
sum(hz.年初剩余资源金额) as 年初剩余货值, 
sum(hz.年初剩余资源面积) as 年初剩余货值面积,
sum(hz.剩余资源金额) as 剩余货值金额, 
sum(hz.剩余资源面积) as 剩余货值面积, 
sum(hz.剩余资源金额)-sum(hz.预估去化货值金额) as 预计年底剩余货值,
sum(hz.剩余资源面积)-sum(hz.预估去化货值面积) as 预计年底剩余货值面积 
from  #baseinfo08 org
inner join s_WqBaseStatic_summary hz on org.业态id = hz.组织架构id and datediff(dd,org.清洗时间,hz.清洗时间) =0
where hz.组织架构类型 = 4 and hz.清洗时间id = @date_id
group by org.统计维度,org.清洗时间,
org.公司,
org.城市,
org.片区,
org.镇街,
org.项目,
org.外键关联,
org.业态  ,
org.城市统计维度,
org.区位,
org.区位占比) t
group by t.统计维度,t.清洗时间,
t.公司,
t.城市,
t.片区,
t.镇街,
t.项目,
t.外键关联,
t.业态,
t.城市统计维度,
t.区位
 
drop table #baseinfo08 
-------------------------11 城市片区占比情况
select org.清洗时间,
sum(org.项目数量) 公司项目数量,
sum(org.在建项目数量) 公司在建项目数量,        
sum(org.总建筑面积) as 公司总建筑面积,
sum(org.动态总货值面积) 公司总货值面积,
sum(org.动态总货值金额) 公司总货值金额, --
sum(org.在建建筑面积) 公司在建建筑面积, 
sum(org.剩余资源面积) 公司剩余货值面积,
sum(org.剩余资源金额) 公司剩余货值金额   -- 
into #total11 
from s_WqBaseStatic_summary org
where org.组织架构类型 = 1 and org.清洗时间id = @date_id and org.平台公司名称 = '湾区公司'
group by org.清洗时间

--东莞汇总
select org.清洗时间,
sum(org.项目数量) 公司项目数量,
sum(org.在建项目数量) 公司在建项目数量,        
sum(org.总建筑面积) as 公司总建筑面积,
sum(org.动态总货值面积) 公司总货值面积,
sum(org.动态总货值金额) 公司总货值金额, 
sum(org.在建建筑面积) 公司在建建筑面积, 
sum(org.剩余资源面积) 公司剩余货值面积,
sum(org.剩余资源金额) 公司剩余货值金额        
into #pqtotal11
from s_WqBaseStatic_summary org
where org.组织架构类型 = 3 and org.项目所属城市='东莞' and org.清洗时间id = @date_id and org.平台公司名称 = '湾区公司'
group by org.清洗时间

--清空当天数据
delete from wqzydtBi_city_pq where datediff(dd,清洗时间,getdate()) = 0

insert into wqzydtBi_city_pq 
select org.清洗时间,
org.项目所属城市 as 统计名称,
'城市' 统计维度,
gs.公司项目数量,
gs.公司在建项目数量,
gs.公司总建筑面积,
gs.公司总货值面积,
gs.公司在建建筑面积,
gs.公司剩余货值面积,
sum(org.项目数量) 项目数量,
case when gs.公司项目数量=0 then 0 else sum(org.项目数量)*1.0/gs.公司项目数量 end 项目数量占比,
sum(org.在建项目数量) 在建项目数量,
case when gs.公司在建项目数量=0 then 0 else sum(org.在建项目数量)*1.0/gs.公司在建项目数量 end 在建项目数量占比,	
sum(org.总建筑面积) as 总建筑面积,
case when gs.公司总建筑面积=0 then 0 else sum(org.总建筑面积)*1.0/gs.公司总建筑面积 end 总建筑面积占比,	
sum(org.动态总货值面积) 总货值面积,
case when gs.公司总货值面积=0 then 0 else sum(org.动态总货值面积)*1.0/gs.公司总货值面积 end 总货值面积占比,
sum(org.在建建筑面积) 在建建筑面积, 
case when gs.公司在建建筑面积=0 then 0 else sum(org.在建建筑面积)*1.0/gs.公司在建建筑面积 end 在建建筑面积占比,
sum(org.剩余资源面积) 剩余货值面积	, 
case when gs.公司剩余货值面积=0 then 0 else sum(org.剩余资源面积)*1.0/gs.公司剩余货值面积 end 剩余货值面积占比 ,
sum(org.动态总货值金额) 总货值金额,
case when gs.公司总货值金额=0 then 0 else sum(org.动态总货值金额)*1.0/gs.公司总货值金额 end 总货值金额占比,
sum(org.剩余资源金额) 剩余货值金额,
case when gs.公司剩余货值金额=0 then 0 else sum(org.剩余资源金额)*1.0/gs.公司剩余货值金额 end 剩余货值金额占比 
from s_WqBaseStatic_summary org
inner join #total11 gs on 1=1 and datediff(dd,gs.清洗时间,org.清洗时间) = 0
where org.组织架构类型 = 3  and org.清洗时间id = @date_id and org.平台公司名称 = '湾区公司'
group by org.清洗时间,
org.项目所属城市, 
gs.公司项目数量,
gs.公司在建项目数量,
gs.公司总建筑面积,
gs.公司总货值面积,
gs.公司在建建筑面积,
gs.公司剩余货值面积,
gs.公司总货值金额,
gs.公司剩余货值金额
union all  
select org.清洗时间,
org.销售片区 as 统计名称,
'片区' 统计维度,
gs.公司项目数量,
gs.公司在建项目数量,
gs.公司总建筑面积,
gs.公司总货值面积,
gs.公司在建建筑面积,
gs.公司剩余货值面积,
sum(org.项目数量) 项目数量,
case when gs.公司项目数量=0 then 0 else sum(org.项目数量)*1.0/gs.公司项目数量 end 项目数量占比,
sum(org.在建项目数量) 在建项目数量,
case when gs.公司在建项目数量=0 then 0 else sum(org.在建项目数量)*1.0/gs.公司在建项目数量 end 在建项目数量占比,	
sum(org.总建筑面积) as 总建筑面积,
case when gs.公司总建筑面积=0 then 0 else sum(org.总建筑面积)*1.0/gs.公司总建筑面积 end 总建筑面积占比,	
sum(org.动态总货值面积) 总货值面积,
case when gs.公司总货值面积=0 then 0 else sum(org.动态总货值面积)*1.0/gs.公司总货值面积 end 总货值面积占比,
sum(org.在建建筑面积) 在建建筑面积, 
case when gs.公司在建建筑面积=0 then 0 else sum(org.在建建筑面积)*1.0/gs.公司在建建筑面积 end 在建建筑面积占比,
sum(org.剩余资源面积) 剩余货值面积	, 
case when gs.公司剩余货值面积=0 then 0 else sum(org.剩余资源面积)*1.0/gs.公司剩余货值面积 end 剩余货值面积占比,
sum(org.动态总货值金额) 总货值金额,
case when gs.公司总货值金额=0 then 0 else sum(org.动态总货值金额)*1.0/gs.公司总货值金额 end 总货值金额占比,
sum(org.剩余资源金额) 剩余货值金额,
case when gs.公司剩余货值金额=0 then 0 else sum(org.剩余资源金额)*1.0/gs.公司剩余货值金额 end 剩余货值金额占比 
from s_WqBaseStatic_summary org
inner join #pqtotal11 gs on 1=1 and datediff(dd,gs.清洗时间,org.清洗时间) = 0
where org.组织架构类型 = 3 and org.清洗时间id = @date_id and org.平台公司名称 = '湾区公司'
group by  org.清洗时间,
org.销售片区, 
gs.公司项目数量,
gs.公司在建项目数量,
gs.公司总建筑面积,
gs.公司总货值面积,
gs.公司在建建筑面积,
gs.公司剩余货值面积 ,
gs.公司总货值金额,
gs.公司剩余货值金额
 
drop table #total11,#pqtotal11

--12 项目业态量价关系 s_WqBaseStatic_ProjPrice_month
DELETE FROM s_WqBaseStatic_ProjPrice_month WHERE DATEDIFF(DAY,清洗时间,GETDATE()) = 0 
	insert into s_WqBaseStatic_ProjPrice_month
	select getdate() as 清洗时间,
	t.ParentProjGUID as 项目guid,
	t.spreadname as 项目推广名,
	t.统计年月,
	case when zl.projguid is null then 0 else 1 end 是否为主力业态,
	t.业态,
	t.销售套数,
	t.销售面积,
	t.销售金额,
	case when t.销售面积 = 0 then 0 else t.销售金额/t.销售面积 end 销售价格
	from (
	select ParentProjGUID,pj.spreadname,
	convert(varchar(7),StatisticalDate,120) 统计年月,
	case when case when TopProductTypeName in ('别墅') then '高级住宅' else TopProductTypeName end in (
	'住宅','高级住宅','公寓','商业','写字楼','地下室/车库') then case when TopProductTypeName in ('别墅') then '高级住宅' 
	else TopProductTypeName end else '其他' end  as 业态,
	sum(case when TopProductTypeName = '地下室/车库' then isnull(CnetCount,0)+isnull(SpecialCnetCount,0)
	else isnull(CnetArea,0)+isnull(SpecialCnetArea,0) end) 销售面积,
	sum(isnull(CnetCount,0)+isnull(SpecialCnetCount,0)) 销售套数,
	sum(isnull(CnetAmount,0)+isnull(SpecialCnetAmount,0)) 销售金额
	 from data_wide_dws_s_salesperf sp 
	 inner join data_wide_dws_mdm_project pj on sp.ParentProjGUID = pj.projguid
	 inner join data_wide_dws_s_dimension_organization do on do.orgguid = pj.buguid
	 where do.organizationname = '湾区公司'
	 group by ParentProjGUID,pj.spreadname,
	convert(varchar(7),StatisticalDate,120) ,
	case when case when TopProductTypeName in ('别墅') then '高级住宅' else TopProductTypeName end in (
	'住宅','高级住宅','公寓','商业','写字楼','地下室/车库') then case when TopProductTypeName in ('别墅') then '高级住宅' 
	else TopProductTypeName end else '其他' end ) t
	left join ( SELECT * FROM
	    (SELECT ProjGUID,
	        case when case when topproductname in ('别墅') then '高级住宅' else topproductname end in ('住宅','高级住宅','公寓','商业','写字楼','地下室/车库') then 
        case when topproductname in ('别墅') then '高级住宅' else topproductname end else '其他' end AS 主力业态,
        ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY SUM(总货值金额) DESC) AS n
      FROM dbo.data_wide_dws_jh_YtHzOverview
      WHERE topproductname <> '地下室/车库'
      GROUP BY ProjGUID,
		case when case when topproductname in ('别墅') then '高级住宅' else topproductname end in ('住宅','高级住宅','公寓','商业','写字楼','地下室/车库') then case when topproductname in ('别墅') then '高级住宅' 
	else topproductname end else '其他' end  ) t
	   WHERE n = 1 ) zl ON t.ParentProjGUID = zl.ProjGUID and zl.主力业态=t.业态
	  where t.销售面积<> 0 
		
--20 主控计划节点执行分析  wqzydtBi_Master_plan_node
DELETE FROM wqzydtBi_Master_plan_node WHERE DATEDIFF(DAY,清洗时间,GETDATE()) = 0 
	insert into wqzydtBi_Master_plan_node
	select getdate() as 清洗时间,
	xmb.organizationname,
	p.spreadname,
	jh.tasktypename,
	count(distinct case when datediff(mm,jh.FinishTime,getdate())=0 and jh.ActualFinishTime<=jh.FinishTime then jh.taskname+convert(varchar(10),jh.FinishTime,23) end) as 本月按期完成数量,	
	count(distinct case when datediff(mm,jh.FinishTime,getdate())=0 and jh.ActualFinishTime>jh.FinishTime then jh.taskname+convert(varchar(10),jh.FinishTime,23) end) as 本月延期完成数量,	
	count(distinct case when datediff(mm,jh.FinishTime,getdate())=0 then jh.taskname+convert(varchar(10),jh.FinishTime,23) end) as 本月计划完成数量,
	count(distinct case when datediff(yy,jh.FinishTime,getdate())=0 and jh.ActualFinishTime<=jh.FinishTime then jh.taskname+convert(varchar(10),jh.FinishTime,23) end) as 本年按期完成数量,	
	count(distinct case when datediff(yy,jh.FinishTime,getdate())=0 and jh.ActualFinishTime>jh.FinishTime then jh.taskname+convert(varchar(10),jh.FinishTime,23) end) as 本年延期完成数量,	
	count(distinct case when datediff(yy,jh.FinishTime,getdate())=0 then jh.taskname+convert(varchar(10),jh.FinishTime,23) end) as 本年计划完成数量,	
	count(distinct case when jh.FinishTime is not null and jh.ActualFinishTime<=jh.FinishTime then jh.taskname+convert(varchar(10),jh.FinishTime,23) end) as 累计按期完成数量,	
	count(distinct case when jh.FinishTime is not null and jh.ActualFinishTime>jh.FinishTime then jh.taskname+convert(varchar(10),jh.FinishTime,23) end) as 累计延期完成数量,	
	count(distinct case when jh.FinishTime is not null then jh.taskname+convert(varchar(10),jh.FinishTime,23) end) as 累计计划完成数量
from data_wide_jh_TaskDetail jh
left join data_tb_wq_yxpqtb tb on jh.projguid=tb.项目GUID
left join data_wide_dws_mdm_Project p on jh.projguid=p.projguid
left join data_wide_dws_s_Dimension_Organization xmb on p.XMSSCSGSGUID=xmb.OrgGUID
where jh.tasktypename in ('里程碑','一级','二级')
and jh.buname='湾区公司'
and jh.level =1
and jh.PlanType = 103
group by 
	xmb.organizationname,
	p.spreadname,
	jh.tasktypename
		
--21 组团关键节点预警分析 wqzydtBi_Keynode_Warning
DELETE FROM wqzydtBi_Keynode_Warning WHERE DATEDIFF(DAY,清洗时间,GETDATE()) = 0 
	insert into wqzydtBi_Keynode_Warning
	select getdate() as 清洗时间,	
	jh.projguid,
	isnull(count(distinct case when jh.实际开工预警 in ('红牌','黄牌') then jh.实际开工计划完成日期 end),0) as 实际开工预警牌数,
	isnull(count(distinct case when jh.施工证预警 in ('红牌','黄牌') then jh.施工证计划完成日期 end),0) as 施工证预警牌数,
	isnull(count(distinct case when jh.展示区开放预警 in ('红牌','黄牌') then jh.展示区开放计划完成日期 end),0) as 展示区开放预警牌数,	
	isnull(count(distinct case when jh.预售形象预警 in ('红牌','黄牌') then jh.预售形象计划完成日期 end),0) as 预售形象预警牌数,	
	isnull(count(distinct case when jh.主体结构封顶预警 in ('红牌','黄牌') then jh.主体结构封顶计划完成日期 end),0) as 主体结构封顶预警牌数,	
	isnull(count(distinct case when jh.交付前精装施工样板房联合验收预警 in ('红牌','黄牌') then jh.交付前精装施工样板房联合验收计划完成日期 end),0) as 交付前精装施工样板房联合验收预警牌数,	
	isnull(count(distinct case when jh.竣工备案预警 in ('红牌','黄牌') then jh.竣工备案计划完成日期 end),0) as 竣工备案预警牌数,	
	isnull(count(distinct case when jh.集中交付预警 in ('红牌','黄牌') then jh.集中交付计划完成日期 end),0) as 集中交付预警牌数,
	isnull(count(distinct case when jh.实际开工预警='红牌' then jh.实际开工计划完成日期 end),0) as 实际开工预警红牌数,
	isnull(count(distinct case when jh.施工证预警='红牌' then jh.施工证计划完成日期 end),0) as 施工证预警红牌数,
	isnull(count(distinct case when jh.展示区开放预警='红牌' then jh.展示区开放计划完成日期 end),0) as 展示区开放预警红牌数,	
	isnull(count(distinct case when jh.预售形象预警='红牌' then jh.预售形象计划完成日期 end),0) as 预售形象预警红牌数,	
	isnull(count(distinct case when jh.主体结构封顶预警='红牌' then jh.主体结构封顶计划完成日期 end),0) as 主体结构封顶预警红牌数,	
	isnull(count(distinct case when jh.交付前精装施工样板房联合验收预警='红牌' then jh.交付前精装施工样板房联合验收计划完成日期 end),0) as 交付前精装施工样板房联合验收预警红牌数,	
	isnull(count(distinct case when jh.竣工备案预警='红牌' then jh.竣工备案计划完成日期 end),0) as 竣工备案预警红牌数,	
	isnull(count(distinct case when jh.集中交付预警='红牌' then jh.集中交付计划完成日期 end),0) as 集中交付预警红牌数
FROM
(
select
	jh.projguid,
	jh.BuildingGUIDs,
	max(case when isnull(jh.keynodename,jh.taskname)='实际开工' and datediff(dd,getdate(),jh.FinishTime)<=365 and jh.ActualFinishTime is null then jh.FinishTime end) as 实际开工计划完成日期,
	case when max(case when isnull(jh.keynodename,jh.taskname)='修详规设计完成' then datediff(dd,jh.FinishTime,isnull(jh.ActualFinishTime,getdate())) end)>0 then '红牌' end as 实际开工预警,
	max(case when isnull(jh.keynodename,jh.taskname)='正式开工' and datediff(dd,getdate(),jh.FinishTime)<=365 and jh.ActualFinishTime is null then jh.FinishTime end) as 施工证计划完成日期,
	case when max(case when isnull(jh.keynodename,jh.taskname)='获取建规证' then datediff(dd,jh.FinishTime,isnull(jh.ActualFinishTime,getdate())) end)>0 then '红牌' end as 施工证预警,
	max(case when isnull(jh.keynodename,jh.taskname)='售楼部、展示区正式开放' and datediff(dd,getdate(),jh.FinishTime)<=365 and jh.ActualFinishTime is null then jh.FinishTime end) as 展示区开放计划完成日期,
	case when max(case when isnull(jh.keynodename,jh.taskname)='基础施工完成' then datediff(dd,jh.FinishTime,isnull(jh.ActualFinishTime,getdate())) end)>0 then '红牌' end as 展示区开放预警,
	max(case when isnull(jh.keynodename,jh.taskname)='达到预售形象' and datediff(dd,getdate(),jh.FinishTime)<=365 and jh.ActualFinishTime is null then jh.FinishTime end) as 预售形象计划完成日期,
	case when max(case when isnull(jh.keynodename,jh.taskname)='基础施工完成' then datediff(dd,jh.FinishTime,isnull(jh.ActualFinishTime,getdate())) end)>0 then '红牌' end as 预售形象预警,
	max(case when isnull(jh.keynodename,jh.taskname)='主体结构封顶' and jh.ActualFinishTime is null then jh.FinishTime end) as 主体结构封顶计划完成日期,
	case when max(case when isnull(jh.keynodename,jh.taskname)='地下结构完成' then datediff(dd,jh.FinishTime,isnull(jh.ActualFinishTime,getdate())) end)>60 then '红牌' 
	when max(case when isnull(jh.keynodename,jh.taskname)='地下结构完成' then datediff(dd,jh.FinishTime,isnull(jh.ActualFinishTime,getdate())) end) between 1 and 60 then '黄牌' end as 主体结构封顶预警,
	max(case when isnull(jh.keynodename,jh.taskname)='交付前精装施工样板房联合验收' and jh.ActualFinishTime is null then jh.FinishTime end) as 交付前精装施工样板房联合验收计划完成日期,
	case when max(case when isnull(jh.keynodename,jh.taskname)='主体结构封顶' then datediff(dd,jh.FinishTime,isnull(jh.ActualFinishTime,getdate())) end)>60 then '红牌' 
	when max(case when isnull(jh.keynodename,jh.taskname)='主体结构封顶' then datediff(dd,jh.FinishTime,isnull(jh.ActualFinishTime,getdate())) end) between 1 and 60 then '黄牌' end as 交付前精装施工样板房联合验收预警,
	max(case when isnull(jh.keynodename,jh.taskname)='竣工备案' and jh.ActualFinishTime is null then jh.FinishTime end) as 竣工备案计划完成日期,
	case when (datediff(dd,max(case when isnull(jh.keynodename,jh.taskname)='主体结构封顶' then isnull(jh.ActualFinishTime,getdate()) end),max(case when isnull(jh.keynodename,jh.taskname)='竣工备案' and jh.ActualFinishTime is null then jh.FinishTime end))<300 
	or datediff(dd,max(case when isnull(jh.keynodename,jh.taskname)='交付前精装施工样板房联合验收' then isnull(jh.ActualFinishTime,getdate()) end),max(case when isnull(jh.keynodename,jh.taskname)='竣工备案' and jh.ActualFinishTime is null then jh.FinishTime end))<180 
	or datediff(dd,max(case when isnull(jh.keynodename,jh.taskname)='园林及配套工程完成' then isnull(jh.ActualFinishTime,getdate()) end),max(case when isnull(jh.keynodename,jh.taskname)='竣工备案' and jh.ActualFinishTime is null then jh.FinishTime end))<180) then '红牌'
	when (datediff(dd,max(case when isnull(jh.keynodename,jh.taskname)='主体结构封顶' then isnull(jh.ActualFinishTime,getdate()) end),max(case when isnull(jh.keynodename,jh.taskname)='竣工备案' and jh.ActualFinishTime is null then jh.FinishTime end)) between 300 and 360
	or datediff(dd,max(case when isnull(jh.keynodename,jh.taskname)='交付前精装施工样板房联合验收' then isnull(jh.ActualFinishTime,getdate()) end),max(case when isnull(jh.keynodename,jh.taskname)='竣工备案' and jh.ActualFinishTime is null then jh.FinishTime end)) between 180 and 240
	or datediff(dd,max(case when isnull(jh.keynodename,jh.taskname)='园林及配套工程完成' then isnull(jh.ActualFinishTime,getdate()) end),max(case when isnull(jh.keynodename,jh.taskname)='竣工备案' and jh.ActualFinishTime is null then jh.FinishTime end)) between 180 and 240) then '黄牌' end as 竣工备案预警,
	max(case when isnull(jh.keynodename,jh.taskname)='集中交付' and jh.ActualFinishTime is null then jh.FinishTime end) as 集中交付计划完成日期,
	case when (datediff(dd,max(case when isnull(jh.keynodename,jh.taskname)='主体结构封顶' then isnull(jh.ActualFinishTime,getdate()) end),max(case when isnull(jh.keynodename,jh.taskname)='集中交付' and jh.ActualFinishTime is null then jh.FinishTime end))<300 
	or datediff(dd,max(case when isnull(jh.keynodename,jh.taskname)='交付前精装施工样板房联合验收' then isnull(jh.ActualFinishTime,getdate()) end),max(case when isnull(jh.keynodename,jh.taskname)='集中交付' and jh.ActualFinishTime is null then jh.FinishTime end))<180 
	or datediff(dd,max(case when isnull(jh.keynodename,jh.taskname)='竣工备案' then isnull(jh.ActualFinishTime,getdate()) end),max(case when isnull(jh.keynodename,jh.taskname)='集中交付' and jh.ActualFinishTime is null then jh.FinishTime end))<30) then '红牌'
	when (datediff(dd,max(case when isnull(jh.keynodename,jh.taskname)='主体结构封顶' then isnull(jh.ActualFinishTime,getdate()) end),max(case when isnull(jh.keynodename,jh.taskname)='集中交付' and jh.ActualFinishTime is null then jh.FinishTime end)) between 300 and 360
	or datediff(dd,max(case when isnull(jh.keynodename,jh.taskname)='交付前精装施工样板房联合验收' then isnull(jh.ActualFinishTime,getdate()) end),max(case when isnull(jh.keynodename,jh.taskname)='集中交付' and jh.ActualFinishTime is null then jh.FinishTime end)) between 180 and 240
	or datediff(dd,max(case when isnull(jh.keynodename,jh.taskname)='竣工备案' then isnull(jh.ActualFinishTime,getdate()) end),max(case when isnull(jh.keynodename,jh.taskname)='集中交付' and jh.ActualFinishTime is null then jh.FinishTime end)) between 30 and 90) then '黄牌' end as 集中交付预警
from data_wide_jh_TaskDetail jh
where jh.buname='湾区公司'
and jh.BuildingGUIDs is not null 
and jh.level =1
and jh.PlanType = 103
group by 
	jh.projguid,
	jh.BuildingGUIDs
) jh 
group by jh.projguid


-------------------------成本分析模块-01项目成本分析
--缓存维度信息
select distinct org.清洗时间, tj.统计维度,
case when tj.统计维度 in ('公司') then '湾区公司' else '无' end  公司,
case when tj.统计维度 in ('城市') then org.区域 else '无' end  城市,
case when tj.统计维度 in ('片区') then org.销售片区 else '无' end 片区,
case when tj.统计维度 in ('镇街') then org.所属镇街 else '无' end 镇街,
case when tj.统计维度 in ('项目') then org.项目名称 else '无' end  项目,
case when tj.统计维度 in ('公司') then null 
when tj.统计维度 in ('城市') then '湾区公司'
when tj.统计维度 in ('片区') then org.区域
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')
else org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无') end   外键关联父级id,
case when tj.统计维度 in ('公司') then '湾区公司' 
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else org.项目名称 end 外键关联id,
case when  tj.统计维度 in ('公司') then '湾区公司'
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else org.组织架构名称 end 外键关联,
 org.组织架构id,
 org.组织架构名称 --项目
into #base_cb01
from s_WqBaseStatic_summary org
inner join (select '公司' 统计维度 union all select '城市' 统计维度 
union all select '片区' 统计维度 union all select '镇街' 统计维度 union all select '项目' 统计维度) tj on 1=1
where org.组织架构类型=3 --项目以上层级
and org.清洗时间id =@date_id and org.平台公司名称 = '湾区公司';

--预处理业务数据
--//////////////////////////1.1项目动态成本分析
-- --剔除动态成本为空的项目
-- select 组织架构id
-- into #p_exclude_cb01
-- from data_wide_dws_s_WqBaseStatic_CbInfo
-- where isnull(动态成本,0)=0 and 组织架构类型 = 3
-- group by 组织架构id

--科目合计
SELECT org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间,
    '科目合计' as 科目,
    convert(varchar(10),org.组织架构类型)+'01' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-科目合计' as id,
    case when  org.组织架构类型 in (1,2)  then null  else  convert(varchar(50),org1.组织架构名称)  +'-科目合计' end as pid,
    --计划阶段
    sum(case when  t.是否含税='含税' then isnull(lxdw.立项总投资,0) else isnull(lxdw.立项总投资不含税,0) end) AS 立项目标成本,
    --总成本（含税，计划）
    sum(case when  t.是否含税='含税' then isnull(lxdw.定位最新版总投资,0) else isnull(lxdw.定位最新版总投资不含税,0) end) AS 定位目标成本, --定位批复>定位上报版
    sum(case when  t.是否含税='含税' then isnull(cbi.目标成本,0) else isnull(cbi.目标成本不含税,0) end) AS 执行版目标成本,
    --动态阶段
    sum(case when  t.是否含税='含税' then cbi.动态成本 else cbi.动态成本不含税 end) AS 总成本,
    sum(case when  t.是否含税='含税' then cbi.已发生成本 else cbi.已发生成本不含税 end) AS 已实现,
    sum(case when  t.是否含税='含税' then cbi.合同性成本 else cbi.合同性成本不含税 end) AS 已签合同,
    sum(case when  t.是否含税='含税' then cbi.已支付成本 else cbi.已支付成本不含税 end) AS 已支付,
    sum(case when  t.是否含税='含税' then isnull(cbi.已发生成本,0 ) - isnull( cbi.已支付成本,0 ) else isnull(cbi.已发生成本不含税,0 ) - isnull( cbi.已支付成本不含税,0 ) end) AS 已发生待支付,
    sum(case when  t.是否含税='含税' then cbi.待发生成本 else cbi.待发生成本不含税 end) AS 待实现,
    --降本目标
    max(cbi.降本任务) AS 总成本降本目标,
    null AS 已实现降本金额,
    null AS 达成率
into #temp_cb01 
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
    -- left join #p_exclude_cb01 p on org.组织架构id=p.组织架构id
	left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
	left join dw_s_WqBaseStatic_Organization org1 on org.组织架构父级ID = org1.组织架构ID AND org.清洗时间id = org1.清洗时间id 
	left join (select '含税' as 是否含税 union all select '不含税' as 是否含税) t on 1=1
WHERE 1 = 1 AND org.组织架构类型 in (1,2,3) AND org.平台公司名称 = '湾区公司' --and p.组织架构id is null  
group by org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间,
	case when  org.组织架构类型 in (1,2)  then null  else  convert(varchar(50),org1.组织架构名称)  +'-科目合计' end
UNION ALL
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间,
    '地价' AS 科目,
    convert(varchar(10),org.组织架构类型)+'02' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-地价'  as id,
    convert(varchar(50), org.组织架构名称)  +'-科目合计'  as pid,
    --计划阶段
    sum(case when  t.是否含税='含税' then lxdw.立项土地款 else lxdw.立项土地款不含税 end) AS 立项目标成本,
    sum(case when  t.是否含税='含税' then lxdw.定位最新版土地款 else lxdw.定位最新版土地款不含税 end) AS 定位目标成本,
    sum(case when  t.是否含税='含税' then isnull(cbi.目标成本直投,0) - isnull(cbi.目标成本除地价外直投,0) else isnull(cbi.目标成本直投不含税,0) - isnull(cbi.目标成本除地价外直投不含税,0) end) AS 执行版目标成本,
    --动态阶段
    sum(case when  t.是否含税='含税' then isnull(cbi.动态成本直投,0) - isnull(cbi.动态成本除地价外直投,0) else isnull(cbi.动态成本直投不含税,0) - isnull(cbi.动态成本除地价外直投不含税,0) end) AS 总成本,
    sum(case when  t.是否含税='含税' then isnull(cbi.已发生成本土地款,0) else isnull(cbi.已发生成本土地款不含税,0) end) AS 已实现,
    sum(case when  t.是否含税='含税' then isnull(cbi.合同性成本土地款,0) else isnull(cbi.合同性成本土地款不含税,0) end) AS 已签合同,
    sum(case when  t.是否含税='含税' then isnull(cbi.已支付成本土地款,0) else isnull(cbi.已支付成本土地款不含税,0) end) AS 已支付,
    sum(case when  t.是否含税='含税' then isnull(cbi.合同性成本土地款,0) - isnull(cbi.已支付成本土地款,0) else isnull(cbi.合同性成本土地款不含税,0) - isnull(cbi.已支付成本土地款不含税,0) end) AS 已发生待支付, --已签合同-已支付
    sum(case when  t.是否含税='含税' then isnull(cbi.动态成本直投,0) - isnull(cbi.动态成本除地价外直投,0)-isnull(cbi.已发生成本土地款,0) else isnull(cbi.动态成本直投不含税,0) - isnull(cbi.动态成本除地价外直投不含税,0)-isnull(cbi.已发生成本土地款不含税,0) end) as  待实现, --总成本 - 已实现
    --降本目标
    max(isnull(cbi.直投降本任务,0) - isnull(cbi.除地价外直投降本任务,0)) AS 总成本降本目标,
    null AS 已实现降本金额,
    null AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
    -- left join #p_exclude_cb01 p on org.组织架构id=p.组织架构id
	left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
	left join (select '含税' as 是否含税 union all select '不含税' as 是否含税) t on 1=1
WHERE 1 = 1 AND org.组织架构类型 in (1,2,3) AND org.平台公司名称 = '湾区公司' --and p.组织架构id is null  
group by org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间
--除地价外直投
UNION ALL
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间,
    '除地价外直投' AS 科目,
    convert(varchar(10),org.组织架构类型)+'03' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-除地价外直投'  as id,
    convert(varchar(50), org.组织架构名称)  +'-科目合计'  as pid,
    --计划阶段
    sum(case when  t.是否含税='含税' then lxdw.立项除地价外直投 else lxdw.立项除地价外直投不含税 end) AS 立项目标成本,
    sum(case when  t.是否含税='含税' then lxdw.定位最新版除地价外直投 else lxdw.定位最新版除地价外直投不含税 end) AS 定位目标成本,
    sum(case when  t.是否含税='含税' then isnull(cbi.目标成本除地价外直投,0) else isnull(cbi.目标成本除地价外直投不含税,0) end) AS 执行版目标成本,
    --动态阶段
    sum(case when  t.是否含税='含税' then cbi.动态成本除地价外直投 else cbi.动态成本除地价外直投不含税 end) AS 总成本,
    sum(case when  t.是否含税='含税' then cbi.已发生成本除地价外直投 else cbi.已发生成本除地价外直投不含税 end) AS 已实现,
    sum(case when  t.是否含税='含税' then cbi.合同性成本除地价外直投 else cbi.合同性成本除地价外直投不含税 end) AS 已签合同,
    sum(case when  t.是否含税='含税' then cbi.已支付成本除地价外直投 else cbi.已支付成本除地价外直投不含税 end) AS 已支付,
    sum(case when  t.是否含税='含税' then isnull(cbi.已发生成本除地价外直投,0 ) - isnull( cbi.已支付成本除地价外直投,0 ) else isnull(cbi.已发生成本除地价外直投不含税,0 ) - isnull( cbi.已支付成本除地价外直投不含税,0 ) end) AS 已发生待支付,
    sum(case when  t.是否含税='含税' then cbi.待发生成本除地价外直投 else cbi.待发生成本除地价外直投不含税 end) as 待实现,
    --降本目标
    max(isnull(cbi.除地价外直投降本任务,0)) AS 总成本降本目标,
    null AS 已实现降本金额,
    null AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi  ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
    --left join #p_exclude_cb01 p on org.组织架构id=p.组织架构id
	left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
	left join (select '含税' as 是否含税 union all select '不含税' as 是否含税) t on 1=1
WHERE 1 = 1 AND org.组织架构类型 in (1,2,3) AND org.平台公司名称 = '湾区公司' --and p.组织架构id is null  
group by org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间
--营销费
UNION ALL
SELECT org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间,
    '营销费' AS 科目,
    convert(varchar(10),org.组织架构类型)+'04' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-营销费'  as id,
    convert(varchar(50), org.组织架构名称)  +'-科目合计'  as pid,  
    --计划阶段
    sum(case when  t.是否含税='含税' then lxdw.立项营销费用 else lxdw.立项营销费用不含税 end) AS 立项目标成本,
    sum(case when  t.是否含税='含税' then lxdw.定位最新版营销费用 else lxdw.定位最新版营销费用不含税 end) AS 定位目标成本,
    sum(case when  t.是否含税='含税' then isnull(cbi.目标成本营销费用,0) else isnull(cbi.目标成本营销费用不含税,0) end) AS 执行版目标成本,
    --动态阶段
    sum(case when  t.是否含税='含税' then cbi.动态成本营销费用 else cbi.动态成本营销费用不含税 end) AS 总成本,
    sum(case when  t.是否含税='含税' then cbi.已发生成本营销费用 else cbi.已发生成本营销费用不含税 end) AS 已实现,
    sum(case when  t.是否含税='含税' then cbi.合同性成本营销费用 else cbi.合同性成本营销费用不含税 end) AS 已签合同,
    sum(case when  t.是否含税='含税' then cbi.已支付成本营销费用 else cbi.已支付成本营销费用不含税 end) AS 已支付,
    sum(case when  t.是否含税='含税' then isnull(cbi.已发生成本营销费用,0 ) - isnull( cbi.已支付成本营销费用,0 ) else isnull(cbi.已发生成本营销费用不含税,0 ) - isnull( cbi.已支付成本营销费用不含税,0 ) end) AS 已发生待支付,
    sum(case when  t.是否含税='含税' then cbi.待发生成本营销费用 else cbi.待发生成本营销费用不含税 end) as 待实现,
    --降本目标
    max(isnull(cbi.营销费用降本任务,0)) AS 总成本降本目标,
    null AS 已实现降本金额,
    null AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
    -- left join #p_exclude_cb01 p on org.组织架构id=p.组织架构id
	left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
	left join (select '含税' as 是否含税 union all select '不含税' as 是否含税) t on 1=1
WHERE 1 = 1 AND org.组织架构类型 in (1,2,3) AND org.平台公司名称 = '湾区公司' --and p.组织架构id is null  
group by org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间
--管理费
UNION ALL
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间,
    '管理费' AS 科目,
    convert(varchar(10),org.组织架构类型)+'05' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-管理费'  as id,
    convert(varchar(50), org.组织架构名称)  +'-科目合计'  as pid,   
    --计划阶段
    sum(case when  t.是否含税='含税' then lxdw.立项管理费用 else lxdw.立项管理费用不含税 end) AS 立项目标成本,
    sum(case when  t.是否含税='含税' then lxdw.定位最新版管理费用 else lxdw.定位最新版管理费用不含税 end) AS 定位目标成本,
    sum(case when  t.是否含税='含税' then isnull(cbi.目标成本管理费用,0) else isnull(cbi.目标成本管理费用不含税,0) end) AS 执行版目标成本,
    --动态阶段
    sum(case when  t.是否含税='含税' then cbi.动态成本管理费用 else cbi.动态成本管理费用不含税 end) AS 总成本,
    sum(case when  t.是否含税='含税' then cbi.已发生成本管理费用 else cbi.已发生成本管理费用不含税 end) AS 已实现,
    sum(case when  t.是否含税='含税' then cbi.合同性成本管理费用 else cbi.合同性成本管理费用不含税 end) AS 已签合同,
    sum(case when  t.是否含税='含税' then cbi.已支付成本管理费用 else cbi.已支付成本管理费用不含税 end) AS 已支付,
    sum(case when  t.是否含税='含税' then isnull(cbi.已发生成本管理费用,0 ) - isnull( cbi.已支付成本管理费用,0 ) else isnull(cbi.已发生成本管理费用不含税,0 ) - isnull( cbi.已支付成本管理费用不含税,0 ) end) AS 已发生待支付,
    sum(case when  t.是否含税='含税' then cbi.待发生成本管理费用 else cbi.待发生成本管理费用不含税 end) as 待实现,
    --降本目标
    max(isnull(cbi.管理费用降本任务,0)) AS 总成本降本目标,
    null AS 已实现降本金额,
    null AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
    -- left join #p_exclude_cb01 p on org.组织架构id=p.组织架构id
	left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
	left join (select '含税' as 是否含税 union all select '不含税' as 是否含税) t on 1=1
WHERE 1 = 1 AND org.组织架构类型 in (1,2,3) AND org.平台公司名称 = '湾区公司' --and p.组织架构id is null  
group by org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间
--财务费
UNION ALL
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间,
    '财务费' AS 科目,
    convert(varchar(10),org.组织架构类型)+'06' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-财务费'  as id,
    convert(varchar(50), org.组织架构名称)  +'-科目合计'  as pid,    
    --计划阶段
    sum(case when  t.是否含税='含税' then lxdw.立项财务费用账面 else lxdw.立项财务费用不含税 end) AS 立项目标成本,
    sum(case when  t.是否含税='含税' then lxdw.定位最新版财务费用计划口径 else lxdw.定位最新版财务费用不含税 end) AS 定位目标成本,
    sum(case when  t.是否含税='含税' then isnull(cbi.目标成本财务费用,0) else isnull(cbi.目标成本财务费用不含税,0) end) AS 执行版目标成本,
    --动态阶段
    sum(case when  t.是否含税='含税' then cbi.动态成本财务费用 else cbi.动态成本财务费用不含税 end) AS 总成本,
    sum(case when  t.是否含税='含税' then cbi.已发生成本财务费用 else cbi.已发生成本财务费用不含税 end) AS 已实现,
    sum(case when  t.是否含税='含税' then cbi.合同性成本财务费用 else cbi.合同性成本财务费用不含税 end) AS 已签合同,
    sum(case when  t.是否含税='含税' then cbi.已支付成本财务费用 else cbi.已支付成本财务费用不含税 end) AS 已支付,
    sum(case when  t.是否含税='含税' then isnull(cbi.已发生成本财务费用,0 ) - isnull( cbi.已支付成本财务费用,0 ) else isnull(cbi.已发生成本财务费用不含税,0 ) - isnull( cbi.已支付成本财务费用不含税,0 ) end) AS 已发生待支付,
    sum(case when  t.是否含税='含税' then cbi.待发生成本财务费用 else cbi.待发生成本财务费用不含税 end) as 待实现,
    --降本目标
    max(isnull(cbi.财务费用降本任务,0)) AS 总成本降本目标,
    null AS 已实现降本金额,
    null AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi  ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
    -- left join #p_exclude_cb01 p on org.组织架构id=p.组织架构id
	left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
	left join (select '含税' as 是否含税 union all select '不含税' as 是否含税) t on 1=1
WHERE 1 = 1 AND org.组织架构类型 in (1,2,3) AND org.平台公司名称 = '湾区公司' --and p.组织架构id is null  
group by org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间
--在除地价外直投基础上增加开发间接费等
--开发前期费
UNION ALL
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间,
    '开发前期费' AS 科目,
    convert(varchar(10),org.组织架构类型)+'0301' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-开发前期费'  as id,
    convert(varchar(50), org.组织架构名称)  +'-除地价外直投'  as pid,
    --计划阶段
    sum(case when  t.是否含税='含税' then lxdw.立项开发前期费 else lxdw.立项开发前期费不含税 end) AS 立项目标成本,
    null AS 定位目标成本,
    sum(case when  t.是否含税='含税' then isnull(cbi.目标成本开发前期费,0) else isnull(cbi.目标成本开发前期费不含税,0) end) AS 执行版目标成本,
    --动态阶段
    sum(case when  t.是否含税='含税' then cbi.动态成本开发前期费 else cbi.动态成本开发前期费不含税 end) AS 总成本,
    sum(case when  t.是否含税='含税' then cbi.已发生成本开发前期费 else cbi.已发生成本开发前期费不含税 end) AS 已实现,
    sum(case when  t.是否含税='含税' then cbi.合同性成本开发前期费 else cbi.合同性成本开发前期费不含税 end) AS 已签合同,
    sum(case when  t.是否含税='含税' then cbi.已支付成本开发前期费 else cbi.已支付成本开发前期费不含税 end) AS 已支付,
    sum(case when  t.是否含税='含税' then isnull(cbi.已发生成本开发前期费,0 ) - isnull( cbi.已支付成本开发前期费,0 ) 
    else isnull(cbi.已发生成本开发前期费不含税,0 ) - isnull( cbi.已支付成本开发前期费不含税,0 ) end) AS 已发生待支付,
    sum(case when  t.是否含税='含税' then cbi.待发生成本开发前期费 else cbi.待发生成本开发前期费不含税 end) as 待实现,
    --降本目标
    null AS 总成本降本目标,
    null AS 已实现降本金额,
    null AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi  ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
    --left join #p_exclude_cb01 p on org.组织架构id=p.组织架构id
	left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
	left join (select '含税' as 是否含税 union all select '不含税' as 是否含税) t on 1=1
WHERE 1 = 1 AND org.组织架构类型 in (1,2,3) AND org.平台公司名称 = '湾区公司' --and p.组织架构id is null  
group by org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间    
--建筑安装工程费
UNION ALL
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间,
    '建筑安装工程费' AS 科目,
    convert(varchar(10),org.组织架构类型)+'0302' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-建筑安装工程费'  as id,
    convert(varchar(50), org.组织架构名称)  +'-除地价外直投'  as pid,
    --计划阶段
    sum(case when  t.是否含税='含税' then lxdw.立项建筑安装工程费 else lxdw.立项建筑安装工程费不含税 end) AS 立项目标成本,
    null AS 定位目标成本,
    sum(case when  t.是否含税='含税' then isnull(cbi.目标成本建筑安装工程费,0) else isnull(cbi.目标成本建筑安装工程费不含税,0) end) AS 执行版目标成本,
    --动态阶段
    sum(case when  t.是否含税='含税' then cbi.动态成本建筑安装工程费 else cbi.动态成本建筑安装工程费不含税 end) AS 总成本,
    sum(case when  t.是否含税='含税' then cbi.已发生成本建筑安装工程费 else cbi.已发生成本建筑安装工程费不含税 end) AS 已实现,
    sum(case when  t.是否含税='含税' then cbi.合同性成本建筑安装工程费 else cbi.合同性成本建筑安装工程费不含税 end) AS 已签合同,
    sum(case when  t.是否含税='含税' then cbi.已支付成本建筑安装工程费 else cbi.已支付成本建筑安装工程费不含税 end) AS 已支付,
    sum(case when  t.是否含税='含税' then isnull(cbi.已发生成本建筑安装工程费,0 ) - isnull( cbi.已支付成本建筑安装工程费,0 ) 
    else isnull(cbi.已发生成本建筑安装工程费不含税,0 ) - isnull( cbi.已支付成本建筑安装工程费不含税,0 ) end) AS 已发生待支付,
    sum(case when  t.是否含税='含税' then cbi.待发生成本建筑安装工程费 else cbi.待发生成本建筑安装工程费不含税 end) as 待实现,
    --降本目标
    null AS 总成本降本目标,
    null AS 已实现降本金额,
    null AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi  ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
    --left join #p_exclude_cb01 p on org.组织架构id=p.组织架构id
	left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
	left join (select '含税' as 是否含税 union all select '不含税' as 是否含税) t on 1=1
WHERE 1 = 1 AND org.组织架构类型 in (1,2,3) AND org.平台公司名称 = '湾区公司' --and p.组织架构id is null  
group by org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间    
--红线内配套费
UNION ALL
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间,
    '红线内配套费' AS 科目,
    convert(varchar(10),org.组织架构类型)+'0303' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-红线内配套费'  as id,
    convert(varchar(50), org.组织架构名称)  +'-除地价外直投'  as pid,
    --计划阶段
    sum(case when  t.是否含税='含税' then lxdw.立项红线内配套费 else lxdw.立项红线内配套费不含税 end) AS 立项目标成本,
    null AS 定位目标成本,
    sum(case when  t.是否含税='含税' then isnull(cbi.目标成本红线内配套费,0) else isnull(cbi.目标成本红线内配套费不含税,0) end) AS 执行版目标成本,
    --动态阶段
    sum(case when  t.是否含税='含税' then cbi.动态成本红线内配套费 else cbi.动态成本红线内配套费不含税 end) AS 总成本,
    sum(case when  t.是否含税='含税' then cbi.已发生成本红线内配套费 else cbi.已发生成本红线内配套费不含税 end) AS 已实现,
    sum(case when  t.是否含税='含税' then cbi.合同性成本红线内配套费 else cbi.合同性成本红线内配套费不含税 end) AS 已签合同,
    sum(case when  t.是否含税='含税' then cbi.已支付成本红线内配套费 else cbi.已支付成本红线内配套费不含税 end) AS 已支付,
    sum(case when  t.是否含税='含税' then isnull(cbi.已发生成本红线内配套费,0 ) - isnull( cbi.已支付成本红线内配套费,0 ) 
    else isnull(cbi.已发生成本红线内配套费不含税,0 ) - isnull( cbi.已支付成本红线内配套费不含税,0 ) end) AS 已发生待支付,
    sum(case when  t.是否含税='含税' then cbi.待发生成本红线内配套费 else cbi.待发生成本红线内配套费不含税 end) as 待实现,
    --降本目标
    null AS 总成本降本目标,
    null AS 已实现降本金额,
    null AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi  ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
    --left join #p_exclude_cb01 p on org.组织架构id=p.组织架构id
	left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
	left join (select '含税' as 是否含税 union all select '不含税' as 是否含税) t on 1=1
WHERE 1 = 1 AND org.组织架构类型 in (1,2,3) AND org.平台公司名称 = '湾区公司' --and p.组织架构id is null  
group by org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间   
--政府收费
UNION ALL
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间,
    '政府收费' AS 科目,
    convert(varchar(10),org.组织架构类型)+'0303' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-政府收费'  as id,
    convert(varchar(50), org.组织架构名称)  +'-除地价外直投'  as pid,
    --计划阶段
    sum(case when  t.是否含税='含税' then lxdw.立项政府收费 else lxdw.立项政府收费不含税 end) AS 立项目标成本,
    null AS 定位目标成本,
    sum(case when  t.是否含税='含税' then isnull(cbi.目标成本政府收费,0) else isnull(cbi.目标成本政府收费不含税,0) end) AS 执行版目标成本,
    --动态阶段
    sum(case when  t.是否含税='含税' then cbi.动态成本政府收费 else cbi.动态成本政府收费不含税 end) AS 总成本,
    sum(case when  t.是否含税='含税' then cbi.已发生成本政府收费 else cbi.已发生成本政府收费不含税 end) AS 已实现,
    sum(case when  t.是否含税='含税' then cbi.合同性成本政府收费 else cbi.合同性成本政府收费不含税 end) AS 已签合同,
    sum(case when  t.是否含税='含税' then cbi.已支付成本政府收费 else cbi.已支付成本政府收费不含税 end) AS 已支付,
    sum(case when  t.是否含税='含税' then isnull(cbi.已发生成本政府收费,0 ) - isnull( cbi.已支付成本政府收费,0 ) 
    else isnull(cbi.已发生成本政府收费不含税,0 ) - isnull( cbi.已支付成本政府收费不含税,0 ) end) AS 已发生待支付,
    sum(case when  t.是否含税='含税' then cbi.待发生成本政府收费 else cbi.待发生成本政府收费不含税 end) as 待实现,
    --降本目标
    null AS 总成本降本目标,
    null AS 已实现降本金额,
    null AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi  ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
    --left join #p_exclude_cb01 p on org.组织架构id=p.组织架构id
	left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
	left join (select '含税' as 是否含税 union all select '不含税' as 是否含税) t on 1=1
WHERE 1 = 1 AND org.组织架构类型 in (1,2,3) AND org.平台公司名称 = '湾区公司' --and p.组织架构id is null  
group by org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间  
--不可预见费
UNION ALL
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间,
    '不可预见费' AS 科目,
    convert(varchar(10),org.组织架构类型)+'0303' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-不可预见费'  as id,
    convert(varchar(50), org.组织架构名称)  +'-除地价外直投'  as pid,
    --计划阶段
    sum(case when  t.是否含税='含税' then lxdw.立项不可预见费 else lxdw.立项不可预见费不含税 end) AS 立项目标成本,
    null AS 定位目标成本,
    sum(case when  t.是否含税='含税' then isnull(cbi.目标成本不可预见费,0) else isnull(cbi.目标成本不可预见费不含税,0) end) AS 执行版目标成本,
    --动态阶段
    sum(case when  t.是否含税='含税' then cbi.动态成本不可预见费 else cbi.动态成本不可预见费不含税 end) AS 总成本,
    sum(case when  t.是否含税='含税' then cbi.已发生成本不可预见费 else cbi.已发生成本不可预见费不含税 end) AS 已实现,
    sum(case when  t.是否含税='含税' then cbi.合同性成本不可预见费 else cbi.合同性成本不可预见费不含税 end) AS 已签合同,
    sum(case when  t.是否含税='含税' then cbi.已支付成本不可预见费 else cbi.已支付成本不可预见费不含税 end) AS 已支付,
    sum(case when  t.是否含税='含税' then isnull(cbi.已发生成本不可预见费,0 ) - isnull( cbi.已支付成本不可预见费,0 ) 
    else isnull(cbi.已发生成本不可预见费不含税,0 ) - isnull( cbi.已支付成本不可预见费不含税,0 ) end) AS 已发生待支付,
    sum(case when  t.是否含税='含税' then cbi.待发生成本不可预见费 else cbi.待发生成本不可预见费不含税 end) as 待实现,
    --降本目标
    null AS 总成本降本目标,
    null AS 已实现降本金额,
    null AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi  ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
    --left join #p_exclude_cb01 p on org.组织架构id=p.组织架构id
	left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
	left join (select '含税' as 是否含税 union all select '不含税' as 是否含税) t on 1=1
WHERE 1 = 1 AND org.组织架构类型 in (1,2,3) AND org.平台公司名称 = '湾区公司' --and p.组织架构id is null  
group by org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
	t.是否含税,
	bi.获取时间  
    
--整合维度跟业务数据:公司看板呈现公司汇总+区域汇总+项目情况；片区、市镇看板呈现项目汇总+项目情况；项目看板呈现项目汇总情况
select   t.*, 
--rank() over(partition by 清洗时间 
--order by  case when 组织架构名称 ='湾区公司' then '0' 
--when 组织架构名称 in ('项目汇总') and 科目 = '科目合计' then '1' 
--when 组织架构名称 in ('汕揭梅城市公司','东莞第二项目部','深圳项目部','河惠城市公司','汕尾城市公司','东莞第一项目部') 
--and 科目 = '科目合计' then 组织架构名称 else null end , case when 获取时间 is null 
--and 组织架构名称 in ('湾区公司','项目汇总','汕揭梅城市公司','东莞第二项目部','深圳项目部','河惠城市公司','汕尾城市公司','东莞第一项目部') then '2099-12-31' 
--else 获取时间 end desc, 科目排序) as 排序  
rank() over(partition by 清洗时间 
order by  case when 组织架构名称 ='湾区公司' then '0'
when 组织架构名称 in ('项目汇总','汕揭梅城市公司','东莞第二项目部','深圳项目部','河惠城市公司','汕尾城市公司','东莞第一项目部') 
and 科目 = '科目合计' then 组织架构名称
else '项目汇总01' end , 
case when 获取时间 is null 
and 组织架构名称 in ('湾区公司','项目汇总','汕揭梅城市公司','东莞第二项目部','深圳项目部','河惠城市公司','汕尾城市公司','东莞第一项目部') then '2099-12-31' 
else 获取时间 end desc,科目排序) as 排序
into #res_cb01
from (
select b.清洗时间, 
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联id,
b.外键关联父级id,
b.外键关联,
id,
pid,
t.组织架构名称,
t.科目,
t.获取时间,
t.科目排序,
t.立项目标成本,
t.定位目标成本,
t.执行版目标成本,
t.总成本,
t.已实现,
t.已签合同,
t.已支付,
t.已发生待支付,
t.待实现,
t.总成本降本目标,
t.已实现降本金额,
t.达成率,
t.是否含税
from (select distinct b.清洗时间, b.统计维度,b.公司,b.城市,b.片区,b.镇街,b.项目,b.外键关联id,b.外键关联父级id,
b.外键关联 from #base_cb01 b where b.统计维度 = '公司') b  --公司看板按照 公司汇总-区域汇总-项目来展示
inner join #temp_cb01 t on datediff(dd,b.清洗时间 ,t.清洗时间) = 0 
union all  
select b.清洗时间, 
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联id,
b.外键关联父级id,
b.外键关联,
--case when t.科目 = '科目合计' then '项目汇总-科目合计' else 外键关联id+'-科目合计' end id,
case when t.科目 = '科目合计' then '项目汇总-科目合计' else 外键关联id+'-'+t.科目 end id,
case when t.科目 = '科目合计' then NULL when t.科目 in ('开发前期费','建筑安装工程费','政府收费','不可预见费','红线内配套费') 
then 外键关联id+'-'+'除地价外直投' else '项目汇总-科目合计' end pid,
'项目汇总' 组织架构名称,
t.科目,
case when b.项目 ='无' then null else t.获取时间 end as 获取时间,
t.科目排序,
sum(isnull(t.立项目标成本,0)) as 立项目标成本,
sum(isnull(t.定位目标成本,0)) as 定位目标成本,
sum(isnull(t.执行版目标成本,0)) as 执行版目标成本,
sum(isnull(t.总成本,0)) as 总成本,
sum(isnull(t.已实现,0)) as 已实现,
sum(isnull(t.已签合同,0)) as 已签合同,
sum(isnull(t.已支付,0)) as 已支付,
sum(isnull(t.已发生待支付,0)) as 已发生待支付,
sum(isnull(t.待实现,0)) as 待实现,
sum(isnull(t.总成本降本目标,0)) as 总成本降本目标,
sum(isnull(t.已实现降本金额,0)) as 已实现降本金额,
case when sum(isnull(t.总成本降本目标,0)) = 0 then 0 else sum(isnull(t.已实现降本金额,0))/sum(isnull(t.总成本降本目标,0)) end 达成率,
t.是否含税
from #base_cb01 b
inner join #temp_cb01 t on datediff(dd,b.清洗时间 ,t.清洗时间) = 0 and b.组织架构id = t.组织架构id
where b.统计维度 not in ('公司') --and b.外键关联 = '深圳项目部'
--非公司看板按照项目汇总的来看
group by b.清洗时间, 
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联,
b.外键关联id,
b.外键关联父级id,
case when t.科目 = '科目合计' then '项目汇总-科目合计' else 外键关联id+'-'+t.科目 end ,
case when t.科目 = '科目合计' then NULL when t.科目 in ('开发前期费','建筑安装工程费','政府收费','不可预见费','红线内配套费') 
then 外键关联id+'-'+'除地价外直投' else '项目汇总-科目合计' end,
t.科目,
case when b.项目 ='无' then null else t.获取时间 end ,
t.科目排序,
t.是否含税
union all 
select b.清洗时间, 
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联id,
b.外键关联父级id,
b.外键关联,
t.id,
case when t.科目 = '科目合计' then null else t.pid end pid,
t.组织架构名称,
t.科目,
t.获取时间,
t.科目排序,
t.立项目标成本,
t.定位目标成本,
t.执行版目标成本,
t.总成本,
t.已实现,
t.已签合同,
t.已支付,
t.已发生待支付,
t.待实现,
t.总成本降本目标,
t.已实现降本金额,
t.达成率,
t.是否含税
from #base_cb01 b
inner join #temp_cb01 t on datediff(dd,b.清洗时间 ,t.清洗时间) = 0 and b.组织架构id = t.组织架构id
where b.统计维度 not in ('公司','项目') --and b.外键关联 = '深圳项目部' and t.组织架构id = 'C5739487-4CD1-EA11-80B8-0A94EF7517DD' 
--非公司、非项目看板中间要有项目情况
) t
where 科目 is not null  

delete from wqzydtBi_dtcostinfo where datediff(dd,清洗时间,getdate()) = 0

insert into wqzydtBi_dtcostinfo
select * from #res_cb01


drop table #base_cb01,#res_cb01,#temp_cb01

-------------------------成本分析模块-02项目变更情况分析： wqzydtBi_costBGinfo
--缓存维度信息
select distinct org.清洗时间, tj.统计维度,
case when tj.统计维度 in ('公司') then '湾区公司' else '无' end  公司,
case when tj.统计维度 in ('城市') then org.区域 else '无' end  城市,
case when tj.统计维度 in ('片区') then org.销售片区 else '无' end 片区,
case when tj.统计维度 in ('镇街') then org.所属镇街 else '无' end 镇街,
case when tj.统计维度 in ('项目') then org.项目名称 else '无' end  项目,
case when tj.统计维度 in ('公司') then null 
when tj.统计维度 in ('城市') then '湾区公司'
when tj.统计维度 in ('片区') then org.区域
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')
else org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无') end   外键关联父级id,
case when tj.统计维度 in ('公司') then '湾区公司' 
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else org.项目名称 end 外键关联id,
case when  tj.统计维度 in ('公司') then '湾区公司'
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else org.组织架构名称 end 外键关联,
 org.组织架构id,
 org.组织架构名称 --项目
into #base_bg01
from s_WqBaseStatic_summary org
inner join (select '公司' 统计维度 union all select '城市' 统计维度 
union all select '片区' 统计维度 union all select '镇街' 统计维度 union all select '项目' 统计维度) tj on 1=1
where org.组织架构类型=3 --项目以上层级
and org.清洗时间id =@date_id and org.平台公司名称 = '湾区公司';

--预处理业务数据
--//////////////////////////1.2项目变更情况分析
select 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
    bi.获取时间,
    '科目合计' AS 科目,
    convert(varchar(10),org.组织架构类型)+'01' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-科目合计'    as id,
    case when  org.组织架构类型 in (1,2)  then null  else  convert(varchar(50),org1.组织架构名称)  +'-科目合计' end as pid,
    cbi.合同金额 合同总金额, 
    cbi.变更总金额,
    cbi.合同总金额 as 合同总金额含变更 ,
    cbi.总变更率, --变更总金额/合同总金额
    cbi.现场签证累计发生比例, --现场签证累计发生金额/(现场签证累计发生金额+合同金额）
    cbi.现场签证累计发生金额,
    cbi.设计变更累计发生比例,--设计变更累计发生金额/(设计变更累计发生金额+合同金额)
    cbi.设计变更累计发生金额
into #temp_bg01
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
	left join dw_s_WqBaseStatic_Organization org1 on org.组织架构父级ID = org1.组织架构ID AND org.清洗时间id = org1.清洗时间id 
WHERE 1 = 1
      AND org.组织架构类型 IN ( 1, 2 , 3 )
      AND org.平台公司名称 = '湾区公司'    
union all       
--总包
select 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
    bi.获取时间,
    '总包' AS 科目,
    convert(varchar(10),org.组织架构类型)+'02' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-总包'  as id,
    convert(varchar(50), org.组织架构名称)  +'-科目合计'  as pid,
    cbi.总包合同金额 总包合同总金额,
    cbi.总包变更总金额,
    cbi.总包合同总金额 as 总包合同总金额含变更 ,
    cbi.总包总变更率, 
    cbi.总包现场签证累计发生比例,
    cbi.总包现场签证累计发生金额,
    cbi.总包设计变更累计发生比例,
    cbi.总包设计变更累计发生金额
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
WHERE 1 = 1
      AND org.组织架构类型 IN ( 1, 2 , 3 )
      AND org.平台公司名称 = '湾区公司'    
union all           
--装修
select 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
    bi.获取时间,
    '装修' AS 科目,
    convert(varchar(10),org.组织架构类型)+'03' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-装修'  as id,
    convert(varchar(50), org.组织架构名称)  +'-科目合计'  as pid,
    cbi.装修合同金额 装修合同总金额,
    cbi.装修变更总金额,
    cbi.装修合同总金额 as 装修合同总金额含变更, 
    cbi.装修总变更率,
    cbi.装修现场签证累计发生比例,
    cbi.装修现场签证累计发生金额,
    cbi.装修设计变更累计发生比例,
    cbi.装修设计变更累计发生金额
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
WHERE 1 = 1
      AND org.组织架构类型 IN ( 1, 2 , 3 )
      AND org.平台公司名称 = '湾区公司'    
union all     
--园林
select 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
    bi.获取时间,
    '园林' AS 科目,
    convert(varchar(10),org.组织架构类型)+'04' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-园林'  as id,
    convert(varchar(50), org.组织架构名称)  +'-科目合计'  as pid,
    cbi.园林合同金额 园林合同总金额,
    cbi.园林变更总金额,
    cbi.园林合同总金额 as 园林合同总金额含变更, 
    cbi.园林总变更率,
    cbi.园林现场签证累计发生比例,
    cbi.园林现场签证累计发生金额,
    cbi.园林设计变更累计发生比例,
    cbi.园林设计变更累计发生金额
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
WHERE 1 = 1
      AND org.组织架构类型 IN ( 1, 2 , 3 )
      AND org.平台公司名称 = '湾区公司'   
union all     
--其他
select 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
    bi.获取时间,
    '其他' AS 科目,
    convert(varchar(10),org.组织架构类型)+'05' as 科目排序,
    convert(varchar(50), org.组织架构名称) +'-其他'  as id,
    convert(varchar(50), org.组织架构名称)  +'-科目合计'  as pid,
    cbi.其他合同金额 其他合同总金额,
    cbi.其他变更总金额,
    cbi.其他合同总金额 as 其他合同总金额含变更, 
    cbi.其他总变更率,
    cbi.其他现场签证累计发生比例,
    cbi.其他现场签证累计发生金额,
    cbi.其他设计变更累计发生比例,
    cbi.其他设计变更累计发生金额
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id 
WHERE 1 = 1
      AND org.组织架构类型 IN ( 1, 2 , 3 )
      AND org.平台公司名称 = '湾区公司' 
 
    
--整合维度跟业务数据:公司看板呈现公司汇总+区域汇总+项目情况；片区、市镇看板呈现项目汇总+项目情况；项目看板呈现项目汇总情况
select   t.*, 
rank() over(partition by 清洗时间 
order by  case when 组织架构名称 ='湾区公司' then '0'
when 组织架构名称 in ('项目汇总','汕揭梅城市公司','东莞第二项目部','深圳项目部','河惠城市公司','汕尾城市公司','东莞第一项目部') 
and 科目 = '科目合计' then 组织架构名称
else '项目汇总01' end , 
case when 获取时间 is null 
and 组织架构名称 in ('湾区公司','项目汇总','汕揭梅城市公司','东莞第二项目部','深圳项目部','河惠城市公司','汕尾城市公司','东莞第一项目部') then '2099-12-31' 
else 获取时间 end desc,科目排序) as 排序
into #res_bg01
from (
select b.清洗时间, 
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联id,
b.外键关联父级id,
b.外键关联,
id,
pid,
t.组织架构名称,
t.科目,
t.获取时间,
t.科目排序,
t.合同总金额, 
t.变更总金额,
t.合同总金额含变更 ,
t.总变更率, 
t.现场签证累计发生比例, 
t.现场签证累计发生金额,
t.设计变更累计发生比例, 
t.设计变更累计发生金额
from (select distinct b.清洗时间, b.统计维度,b.公司,b.城市,b.片区,b.镇街,b.项目,b.外键关联id,b.外键关联父级id,
b.外键关联 from #base_bg01 b where b.统计维度 = '公司') b  --公司看板按照 公司汇总-区域汇总-项目来展示
inner join #temp_bg01 t on datediff(dd,b.清洗时间 ,t.清洗时间) = 0 
union all  
select b.清洗时间, 
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联id,
b.外键关联父级id,
b.外键关联,
case when t.科目 = '科目合计' then '项目汇总-科目合计' else 外键关联id+'-'+t.科目 end id,
case when t.科目 = '科目合计' then NULL else '项目汇总-科目合计' end pid,
'项目汇总' 组织架构名称,
t.科目,
case when b.项目 ='无' then null else t.获取时间 end as 获取时间,
t.科目排序,
sum(isnull(t.合同总金额,0)) as 合同总金额, 
sum(isnull(t.变更总金额,0)) as 变更总金额,
sum(isnull(t.合同总金额含变更,0)) as 合同总金额含变更,
case when sum(isnull(t.合同总金额含变更,0)) = 0 then 0 else sum(isnull(t.变更总金额,0))/sum(isnull(t.合同总金额含变更,0)) end 总变更率, 
case when sum(isnull(t.现场签证累计发生金额,0)+isnull(t.合同总金额,0)) = 0 then 0 else sum(isnull(t.现场签证累计发生金额,0))/sum(isnull(t.现场签证累计发生金额,0)+isnull(t.合同总金额,0)) end 现场签证累计发生比例, 
sum(isnull(t.现场签证累计发生金额,0)) as 现场签证累计发生金额,
case when sum(isnull(t.设计变更累计发生金额,0)+isnull(t.合同总金额,0)) = 0 then 0 else sum(isnull(t.设计变更累计发生金额,0))/sum(isnull(t.设计变更累计发生金额,0)+isnull(t.合同总金额,0)) end 设计变更累计发生比例, 
sum(isnull(t.设计变更累计发生金额,0)) as 设计变更累计发生金额
from #base_bg01 b
inner join #temp_bg01 t on datediff(dd,b.清洗时间 ,t.清洗时间) = 0 and b.组织架构id = t.组织架构id
where b.统计维度 not in ('公司') --and b.外键关联 = '深圳项目部'
--非公司看板按照项目汇总的来看
group by b.清洗时间, 
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联,
b.外键关联id,
b.外键关联父级id,
case when t.科目 = '科目合计' then '项目汇总-科目合计' else 外键关联id+'-'+t.科目 end ,
case when t.科目 = '科目合计' then NULL else '项目汇总-科目合计' end ,
t.科目,
case when b.项目 ='无' then null else t.获取时间 end ,
t.科目排序 
union all 
select b.清洗时间, 
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联id,
b.外键关联父级id,
b.外键关联,
t.id,
case when t.科目 = '科目合计' then null else t.pid end pid,
t.组织架构名称,
t.科目,
t.获取时间,
t.科目排序,
t.合同总金额, 
t.变更总金额,
t.合同总金额含变更 ,
t.总变更率, 
t.现场签证累计发生比例, 
t.现场签证累计发生金额,
t.设计变更累计发生比例, 
t.设计变更累计发生金额
from #base_bg01 b
inner join #temp_bg01 t on datediff(dd,b.清洗时间 ,t.清洗时间) = 0 and b.组织架构id = t.组织架构id
where b.统计维度 not in ('公司','项目') --and b.外键关联 = '深圳项目部' and t.组织架构id = 'C5739487-4CD1-EA11-80B8-0A94EF7517DD' 
--非公司、非项目看板中间要有项目情况
) t
where 科目 is not null  


delete from wqzydtBi_costBGinfo where datediff(dd,清洗时间,getdate()) = 0

insert into wqzydtBi_costBGinfo
select * from #res_bg01

drop table #base_bg01,#res_bg01,#temp_bg01

-------------------------成本分析模块-03项目结算情况分析： wqzydtBi_costjsinfo
--缓存维度信息
select distinct org.清洗时间, tj.统计维度,
case when tj.统计维度 in ('公司') then '湾区公司' else '无' end  公司,
case when tj.统计维度 in ('城市') then org.区域 else '无' end  城市,
case when tj.统计维度 in ('片区') then org.销售片区 else '无' end 片区,
case when tj.统计维度 in ('镇街') then org.所属镇街 else '无' end 镇街,
case when tj.统计维度 in ('项目') then org.项目名称 else '无' end  项目,
case when tj.统计维度 in ('公司') then null 
when tj.统计维度 in ('城市') then '湾区公司'
when tj.统计维度 in ('片区') then org.区域
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')
else org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无') end   外键关联父级id,
case when tj.统计维度 in ('公司') then '湾区公司' 
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else org.项目名称 end 外键关联id,
case when  tj.统计维度 in ('公司') then '湾区公司'
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else org.组织架构名称 end 外键关联,
 org.组织架构id,
 org.组织架构名称 --项目
into #base_js01
from s_WqBaseStatic_summary org
inner join (select '公司' 统计维度 union all select '城市' 统计维度 
union all select '片区' 统计维度 union all select '镇街' 统计维度 union all select '项目' 统计维度) tj on 1=1
where org.组织架构类型=3 --项目以上层级
and org.清洗时间id =@date_id and org.平台公司名称 = '湾区公司';

--预处理业务数据
--//////////////////////////1.3项目结算情况分析
-- 平台公司和区事
SELECT
     org.清洗时间,
     org.组织架构ID,
     org.组织架构类型,
     org.组织架构名称,
     org.组织架构父级ID,
     convert(varchar(50),org.组织架构名称) as id,
     case when  org.组织架构类型 = 1 then  null else convert(varchar(50), org1.组织架构名称) end  as  pid,
     '合计' as 分期,
     cbi.[合同总金额],
     cbi.[合同份数],
     cbi.[结算份数],
     cbi.[结算金额],
     cbi.[结算偏差率],
     cbi.[结算综合完成率],
     cbi.[综合结算率_份数],
     cbi.[综合结算率_金额],
     cbi.已结算已签金额,
     convert(datetime,null) as 获取时间
     into #temp_js01
FROM dw_s_WqBaseStatic_Organization org
     LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo_Extend] cbi ON org.组织架构ID = cbi.组织架构ID
     AND org.清洗时间id = cbi.清洗时间id
     left join dw_s_WqBaseStatic_Organization org1 on org.组织架构父级ID = org1.组织架构ID
     AND org.清洗时间id = org1.清洗时间id
WHERE 1 = 1
     AND org.组织架构类型 IN (1, 2)
     AND org.平台公司名称 = '湾区公司'
     AND DATEDIFF(DAY, org.清洗时间, GETDATE()) = 0
union all
-- 项目
SELECT
     org.清洗时间,
     org.组织架构ID,
     org.组织架构类型,
     org.组织架构名称,
     org.组织架构父级ID,
     convert(varchar(50),org.组织架构名称) + '分期合计' as id,
     case when  org.组织架构类型 = 1 then  null else  convert(varchar(50),org1.组织架构名称) end  as  pid,
     '分期合计' as 分期,     
     cbi.[合同总金额],
     cbi.[合同份数],
     cbi.[结算份数],
     cbi.[结算金额],
     cbi.[结算偏差率],
     cbi.[结算综合完成率],
     cbi.[综合结算率_份数],
     cbi.[综合结算率_金额],
     cbi.已结算已签金额,
     bi.获取时间
FROM dw_s_WqBaseStatic_Organization org
     LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo_Extend] cbi ON org.组织架构ID = cbi.组织架构ID
     AND org.清洗时间id = cbi.清洗时间id
     left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id  
     left join dw_s_WqBaseStatic_Organization org1 on org.组织架构父级ID = org1.组织架构ID AND org.清洗时间id = org1.清洗时间id
WHERE 1 = 1
     AND org.组织架构类型 IN (3)
     and cbi.项目维度 = '项目'
     AND org.平台公司名称 = '湾区公司'
     AND DATEDIFF(DAY, org.清洗时间, GETDATE()) = 0
union all
-- 分期
SELECT
     org.清洗时间,
     org.组织架构ID,
     org.组织架构类型,
     org.组织架构名称,
     org.组织架构父级ID,
     convert(varchar(50),org.组织架构名称) + cbi.项目分期名称 as id,
     convert(varchar(50),org.组织架构名称) + '分期合计'  as  pid,
     cbi.项目分期名称 as 分期,     
     cbi.[合同总金额],
     cbi.[合同份数],
     cbi.[结算份数],
     cbi.[结算金额],
     cbi.[结算偏差率],
     cbi.[结算综合完成率],
     cbi.[综合结算率_份数],
     cbi.[综合结算率_金额],
     cbi.已结算已签金额,
     convert(datetime,null) as 获取时间
FROM dw_s_WqBaseStatic_Organization org
     LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo_Extend] cbi ON org.组织架构ID = cbi.组织架构ID
     AND org.清洗时间id = cbi.清洗时间id
WHERE
     1 = 1
     AND org.组织架构类型 IN (3)
     and cbi.项目维度 = '分期'
     AND org.平台公司名称 = '湾区公司'
     AND DATEDIFF(DAY, org.清洗时间, GETDATE()) = 0

--整合维度跟业务数据: 公司看板呈现公司-区域-项目-分期层级；其余看板呈现项目汇总-项目-分期的层级；项目看板呈现项目汇总-分期的层级
select   t.*, 
rank() over(partition by 清洗时间 
order by  case when 组织架构名称 ='湾区公司' then '0'
when 组织架构名称 in ('项目汇总','汕揭梅城市公司','东莞第二项目部','深圳项目部','河惠城市公司','汕尾城市公司','东莞第一项目部') 
and 分期 in ('分期合计','合计') then 组织架构名称
else '项目汇总01' end , 
case when 获取时间 is null 
and 组织架构名称 in ('湾区公司','项目汇总','汕揭梅城市公司','东莞第二项目部','深圳项目部','河惠城市公司','汕尾城市公司','东莞第一项目部') then '2099-12-31' 
else 获取时间 end desc) as 排序
into #res_js01
from (
select b.清洗时间, 
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联id,
b.外键关联父级id,
b.外键关联,
t.id,
t.pid, 
t.组织架构名称, 
t.分期,
t.获取时间,
t.[合同总金额],
t.[合同份数],
t.[结算份数],
t.[结算金额],
t.[结算偏差率],
t.[结算综合完成率],
t.[综合结算率_份数],
t.[综合结算率_金额]
from (select distinct b.清洗时间, b.统计维度,b.公司,b.城市,b.片区,b.镇街,b.项目,b.外键关联id,b.外键关联父级id,
b.外键关联 from #base_js01 b where b.统计维度 = '公司') b  --公司看板按照 公司汇总-区域汇总-项目-分期来展示
inner join #temp_js01 t on datediff(dd,b.清洗时间 ,t.清洗时间) = 0 
union all  

select b.清洗时间, 
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联id,
b.外键关联父级id,
b.外键关联,
case when t.分期 = '分期合计' then '项目汇总-分期合计' else 外键关联id+'-'+t.分期 end id,
case when t.分期 = '分期合计' then NULL else '项目汇总-分期合计' end pid,
'项目汇总' 组织架构名称,
t.分期,
case when b.项目 ='无' then null else t.获取时间 end as 获取时间, 
sum(isnull(t.[合同总金额],0)) as 合同总金额,
sum(isnull(t.[合同份数],0)) as [合同份数],
sum(isnull(t.[结算份数],0)) as [结算份数],
sum(isnull(t.[结算金额],0)) as [结算金额],
case when sum(isnull(t.已结算已签金额,0))=0 then 0 else (sum(isnull(t.结算金额,0))-sum(isnull(t.已结算已签金额,0)))/sum(isnull(t.已结算已签金额,0)) end as [结算偏差率], 
(case when sum(isnull(t.合同份数,0))  = 0 THEN 0 ELSE  sum(isnull(t.结算份数,0)) *1.0 / sum(isnull(t.合同份数,0)) end + 
case when  sum(isnull(t.合同总金额,0))  = 0 then 0 ELSE  SUM(isnull(t.结算金额,0)) *1.0 / sum(isnull(t.合同总金额,0)) end)/2 as [结算综合完成率],
case when sum(isnull(t.合同份数,0))  = 0 THEN 0 ELSE  sum(isnull(t.结算份数,0)) *1.0 / sum(isnull(t.合同份数,0)) end as [综合结算率_份数],
case when  sum(isnull(t.合同总金额,0))  = 0 then 0 ELSE  SUM(isnull(t.结算金额,0)) *1.0 / sum(isnull(t.合同总金额,0)) end as [综合结算率_金额]
from #base_js01 b
inner join #temp_js01 t on datediff(dd,b.清洗时间 ,t.清洗时间) = 0 and b.组织架构id = t.组织架构id
where b.统计维度 not in ('公司','项目') and t.分期 = '分期合计'--非公司、项目看板按照项目汇总-项目-分期来看
group by b.清洗时间, 
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联,
b.外键关联id,
b.外键关联父级id,
case when t.分期 = '分期合计' then '项目汇总-分期合计' else 外键关联id+'-'+t.分期 end ,
case when t.分期 = '分期合计' then NULL else '项目汇总-分期合计' end ,
t.分期,
case when b.项目 ='无' then null else t.获取时间 end 
union all 
select b.清洗时间, 
b.统计维度,
b.公司,
b.城市,
b.片区,
b.镇街,
b.项目,
b.外键关联id,
b.外键关联父级id,
b.外键关联,
t.id,
case when b.统计维度 = '项目' and t.组织架构类型 = 3 and t.分期 = '分期合计' then null when t.分期 = '分期合计' then  
'项目汇总-分期合计' else pid end pid, 
t.组织架构名称, 
t.分期,
t.获取时间,
t.[合同总金额],
t.[合同份数],
t.[结算份数],
t.[结算金额],
t.[结算偏差率],
t.[结算综合完成率],
t.[综合结算率_份数],
t.[综合结算率_金额]
from #base_js01 b
inner join #temp_js01 t on datediff(dd,b.清洗时间 ,t.清洗时间) = 0 and b.组织架构id = t.组织架构id
where b.统计维度  not in ('公司')  --项目看板呈现项目-分期的层级
) t 

delete from wqzydtBi_costJsinfo where datediff(dd,清洗时间,getdate()) = 0

insert into wqzydtBi_costJsinfo
select *  from #res_js01  

drop table #base_js01,#res_js01,#temp_js01

-------------------------成本分析模块-04项目成本单方情况分析： wqzydtBi_costDfinfo
--缓存维度信息
select distinct org.清洗时间, tj.统计维度,
case when tj.统计维度 in ('公司') then '湾区公司' else '无' end  公司,
case when tj.统计维度 in ('城市') then org.区域 else '无' end  城市,
case when tj.统计维度 in ('片区') then org.销售片区 else '无' end 片区,
case when tj.统计维度 in ('镇街') then org.所属镇街 else '无' end 镇街,
case when tj.统计维度 in ('项目') then org.项目名称 else '无' end  项目,
case when tj.统计维度 in ('公司') then null 
when tj.统计维度 in ('城市') then '湾区公司'
when tj.统计维度 in ('片区') then org.区域
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')
else org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无') end   外键关联父级id,
case when tj.统计维度 in ('公司') then '湾区公司' 
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else org.项目名称 end 外键关联id,
case when  tj.统计维度 in ('公司') then '湾区公司'
when tj.统计维度 in ('城市') then org.区域
when tj.统计维度 in ('片区') then org.区域+'_'+isnull(org.销售片区,'无')
when tj.统计维度 in ('镇街') then org.区域+'_'+isnull(org.销售片区,'无')+'_'+isnull(org.所属镇街,'无')
else org.组织架构名称 end 外键关联,
 org.组织架构id,
 org.组织架构名称 --项目
into #base_df01
from s_WqBaseStatic_summary org
inner join (select '公司' 统计维度 union all select '城市' 统计维度 
union all select '片区' 统计维度 union all select '镇街' 统计维度 union all select '项目' 统计维度) tj on 1=1
where org.组织架构类型=3 --项目以上层级
and org.清洗时间id =@date_id and org.平台公司名称 = '湾区公司';

--预处理业务数据
WITH #TwoFtCb
AS (SELECT ParentGUID AS 项目GUID,
           STRING_AGG(二次分摊车位分摊口径, CHAR(13))WITHIN GROUP(ORDER BY 二次分摊车位分摊口径 DESC) AS 二次分摊车位分摊口径
    FROM
    (
        SELECT DISTINCT
               p.ParentGUID,
               p.ProjName + ':' + twft.二次分摊车位分摊口径 AS 二次分摊车位分摊口径
        FROM data_wide_dws_mdm_Project p
            INNER JOIN data_wide_dws_s_WqBaseStatic_TwoFtCbInfo twft
                ON twft.项目分期GUID = p.ProjGUID
        WHERE p.Level = 3
    ) t
    GROUP BY ParentGUID)
    
SELECT org.清洗时间id,
       org.清洗时间,
       org.项目guid,
       org.项目名称,
       org.组织架构类型,
       '业态合计' AS 业态,
       org.项目名称 id,
       null pid,
       lxdw.立项总建筑面积,
       lxdw.立项总投资建筑单方 AS 立项建筑单方,
       lxdw.定位最新版总建筑面积 AS 定位总建筑面积,
       lxdw.定位最新版总投资 定位总投资,
       lxdw.定位最新版总投资建筑单方 AS 定位建筑单方,
       twft.二次分摊车位分摊口径 AS 车位分摊口径,
       --综合单方_不含税等于：营业成本单方+营销费用单方+综合管理费单方+税金单方
       ISNULL(lr.盈利规划营业成本单方, 0) + ISNULL(lr.盈利规划营销费用单方, 0) + ISNULL(lr.盈利规划综合管理费单方, 0) + ISNULL(盈利规划税金及附加单方, 0) AS 综合单方_不含税,
       lr.盈利规划营业成本单方 AS 营业成本单方,
       lr.盈利规划土地款单方 AS 土地款单方,
       lr.盈利规划除地价外直投单方 AS 除地价外直投单方,
       lr.盈利规划开发间接费单方 AS 开发间接费单方,
       lr.盈利规划资本化利息单方 AS 资本化利息单方,
       lr.盈利规划营销费用单方 AS 营销费用单方,
       lr.盈利规划综合管理费单方 AS 综合管理费单方,
       lr.盈利规划税金及附加单方 AS 税金单方,
       bi.获取时间
into #temp_df01
FROM [dbo].[dw_s_WqBaseStatic_Organization] org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_LxdwInfo] lxdw
        ON org.组织架构ID = lxdw.组织架构ID
           AND org.清洗时间id = lxdw.清洗时间id
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_ProfitInfo] lr
        ON org.组织架构ID = lr.组织架构ID
           AND org.清洗时间id = lr.清洗时间id
    LEFT JOIN #TwoFtCb twft
        ON twft.项目GUID = org.项目guid
    left join dw_s_WqBaseStatic_BaseInfo bi on org.组织架构ID = bi.组织架构ID AND org.清洗时间id = bi.清洗时间id  
WHERE org.平台公司名称 = '湾区公司'
      AND org.组织架构类型 = 3
      AND DATEDIFF(DAY, org.清洗时间, GETDATE()) = 0
      and (lxdw.立项总投资建筑单方 <> 0 or 定位最新版总投资建筑单方<> 0 or ISNULL(lr.盈利规划营业成本单方, 0) + ISNULL(lr.盈利规划营销费用单方, 0) + ISNULL(lr.盈利规划综合管理费单方, 0) + ISNULL(盈利规划税金及附加单方, 0)<> 0)
union all 
SELECT org.清洗时间id,
       org.清洗时间,
       org.项目guid,
       org.项目名称,
       org.组织架构类型,
       org.组织架构名称 AS 业态,
       org.项目名称+'_'+org.组织架构名称 id,
       org.项目名称 pid,
       lxdw.立项总建筑面积,
       lxdw.立项总投资建筑单方  AS 立项建筑单方, 
       lxdw.定位最新版总建筑面积 AS 定位总建筑面积,
       lxdw.定位最新版总投资 定位总投资,
       lxdw.定位最新版总投资建筑单方 AS 定位建筑单方,
       twft.二次分摊车位分摊口径 AS 车位分摊口径,
       --综合单方_不含税等于：营业成本单方+营销费用单方+综合管理费单方+税金单方
       ISNULL(lr.盈利规划营业成本单方, 0) + ISNULL(lr.盈利规划营销费用单方, 0) + ISNULL(lr.盈利规划综合管理费单方, 0) + ISNULL(盈利规划税金及附加单方, 0) AS 综合单方_不含税,
       lr.盈利规划营业成本单方 AS 营业成本单方,
       lr.盈利规划土地款单方 AS 土地款单方,
       lr.盈利规划除地价外直投单方 AS 除地价外直投单方,
       lr.盈利规划开发间接费单方 AS 开发间接费单方,
       lr.盈利规划资本化利息单方 AS 资本化利息单方,
       lr.盈利规划营销费用单方 AS 营销费用单方,
       lr.盈利规划综合管理费单方 AS 综合管理费单方,
       lr.盈利规划税金及附加单方 AS 税金单方,
       null as 获取时间
FROM [dbo].[dw_s_WqBaseStatic_Organization] org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_LxdwInfo] lxdw
        ON org.组织架构ID = lxdw.组织架构ID
           AND org.清洗时间id = lxdw.清洗时间id
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_ProfitInfo] lr
        ON org.组织架构ID = lr.组织架构ID
           AND org.清洗时间id = lr.清洗时间id
    LEFT JOIN #TwoFtCb twft
        ON twft.项目GUID = org.项目guid
WHERE org.平台公司名称 = '湾区公司'
      AND org.组织架构类型 = 5
      AND DATEDIFF(DAY, org.清洗时间, GETDATE()) = 0
      and (lxdw.立项总投资建筑单方<>0 or lxdw.定位最新版总投资建筑单方<> 0 or ISNULL(lr.盈利规划营业成本单方, 0) + ISNULL(lr.盈利规划营销费用单方, 0) + ISNULL(lr.盈利规划综合管理费单方, 0) + ISNULL(盈利规划税金及附加单方, 0)<> 0)
    

--整合维度跟业务数据: 每个看板都是业态合计-业态层级
select 
    b.清洗时间, 
    b.统计维度,
    b.公司,
    b.城市,
    b.片区,
    b.镇街,
    b.项目,
    b.外键关联id,
    b.外键关联父级id,
    b.外键关联,
    t.id,
    t.pid,
    t.项目名称,
    t.业态,
    t.立项总建筑面积,
    t.立项建筑单方, 
    t.定位总建筑面积,
    t.定位总投资,
    t.定位建筑单方,
    t.车位分摊口径,
    t.综合单方_不含税,
    t.营业成本单方,
    t.土地款单方,
    t.除地价外直投单方,
    t.开发间接费单方,
    t.资本化利息单方,
    t.营销费用单方,
    t.综合管理费单方,
    t.税金单方,
    t.获取时间,
    rank() over(partition by b.清洗时间 
order by  获取时间 desc) as 排序
into #res_df01
from #base_df01 b
inner join #temp_df01 t on datediff(dd,b.清洗时间 ,t.清洗时间) = 0 and b.组织架构id = t.项目guid

delete from wqzydtBi_costdfinfo where datediff(dd,清洗时间,getdate()) = 0

insert into wqzydtBi_costdfinfo
select *   from #res_df01
 

drop table #base_df01,#res_df01,#temp_df01

-----------------------------版本清理 开始
select distinct date_date
into #d_day
from (select date_date
from highdata_prod.dbo.dw_d_date
where Date_DataDIFDay between 0 and 29
union all 
--节假日
SELECT t.date_date
FROM highdata_prod.dbo.dw_d_date t 
inner join [172.16.4.141].[MyCost_Erp352].dbo.myWorkflowSpecialDay d on t.date_date BETWEEN d.BeginDate and d.enddate
WHERE (1=1) and  isworkday = 0 and buguid  = '248B1E17-AACB-E511-80B8-E41F13C51836'
and t.date_year>='2023年'
union all
--每月月初
select min(date_date) as date_date
from highdata_prod.dbo.dw_d_date
where Date_DataDIFDay>0  and date_year>='2023年'
group by Date_YearMonth
union all
--每月月末
select max(date_date) as date_date
from highdata_prod.dbo.dw_d_date
where Date_DataDIFDay>0 and date_year>='2023年'
group by Date_YearMonth) t

--清理 
delete t from wqzydtBi_baseinfo_taskinfo t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_cashflowinfo t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_resourseinfo t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_resourseinfo_area t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_productedinfo t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_saleProfitinfo t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_scheduleinfo t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_product_rest t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_restsalevalue t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_city_pq t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_Master_plan_node t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_Keynode_Warning t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_costBGinfo t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_costdfinfo t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_costJsinfo t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
delete t from wqzydtBi_dtcostinfo t left join  #d_day d on  datediff(dd,t.清洗时间  , d.date_date)=0 where d.date_date is null
-----------------------------版本清理 结束
end
