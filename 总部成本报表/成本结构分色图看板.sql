USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_cost_structure_color_board]    Script Date: 2025/5/4 16:58:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
-- 成本结构分色图看板
-- 2025-04-27 chenjw
exec usp_cost_structure_color_board '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8','2025-04-28'
*/

ALTER proc [dbo].[usp_cost_structure_color_board]
(
    @buguid  varchar(max), -- 公司GUID
    @qxDate datetime --  查询日期
)
as 
Begin 
    declare @buguidList  varchar(max)=null -- 公司GUID列表
     -- 调用成本结构表清洗存储过程
     exec usp_cb_CostStructureReport_Clean @buguid,@qxDate

    -- declare @buguid  varchar(max)=null -- 公司GUID
    -- declare @qxDate datetime=getdate() --  查询日期

     if @buguid is null or @buguid = '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23'
     begin
        select @buguidList = STUFF(
        (
            SELECT distinct RTRIM(',' + CONVERT(VARCHAR(MAX), unit.buguid))
            FROM myBusinessUnit unit
            INNER JOIN p_project p ON unit.buguid = p.buguid
            WHERE IsEndCompany = 1 AND IsCompany = 1
            FOR XML PATH('')
        ), 1, 1, '' );
     end
     else  
        select @buguidList = @buguid
     

     -- 判断该项目是否有动态成本拍照记录（不含系统给管理员）
     -- 1、获取动态成本拍照记录
       SELECT 
           p.ProjGUID,
           p.ProjName,
           cb_DTCostRecollect.RecollectCount,
           CASE 
               WHEN ISNULL(cb_DTCostRecollect.RecollectCount, 0) > 0 THEN '是'
               ELSE '否'
           END AS IsRecollect -- 是否存在拍照记录
        into  #ProjectRecollect
       FROM   p_project p
       OUTER APPLY (
           SELECT TOP 1 
               t.ProjectGUID,
               t.ProjectName,
               t.RecollectCount
           FROM (
               SELECT 
                   ProjectGUID,
                   ProjectName,
                   COUNT(1) AS RecollectCount
               FROM 
                   cb_DTCostRecollect 
               WHERE 
                   CreateUserGUID <> '4230BC6E-69E6-46A9-A39E-B929A06A84E8'
               GROUP BY 
                   ProjectGUID,
                   ProjectName
           ) t
           WHERE 
               t.ProjectGUID = p.ProjGUID
       ) AS cb_DTCostRecollect 
       where  p.buguid in (  SELECT  Value FROM  [dbo].[fn_Split2](@buguidList, ',') )

       -- 获取成本结构报表清洗表数据
       SELECT 
           *, 
           CASE 
               WHEN ISNULL(总成本情况_动态成本, 0) = 0 THEN 0 
               ELSE ISNULL(结算_结算金额, 0) / ISNULL(总成本情况_动态成本, 0) 
           END AS 结算完成率,
           convert(varchar(50),'') as 项目分期分类
       INTO #cb_CostStructureReport_qx 
       FROM cb_CostStructureReport_qx 
       WHERE DATEDIFF(DAY, 清洗日期, @qxDate) = 0 AND 公司GUID in ( SELECT  Value FROM  [dbo].[fn_Split2](@buguidList, ',') )
    
       -- 1、已竣备分期:[实际竣备时间]有数据
       select  
       proj.ProjGUID,proj.ProjName,
       case when str.结算完成率 >= 1 then '已竣备分期_结算完成率等于100%' 
       when str.结算完成率 > 0.95 and str.结算完成率 < 1 then '已竣备分期_结算完成率95%至100%'
       when str.结算完成率 <= 0.95 then '已竣备分期_结算完成率小于95%'
       end as 项目分期分类
       into #已竣备分期1
       from  #ProjectRecollect proj
       inner join #cb_CostStructureReport_qx str on proj.ProjGUID = str.项目guid
       where  str.实际竣备时间 is not null 
       -- 2. 本年计划竣备分期:剔除[实际竣备时间]有数据，【计划竣备时间】在本年内    
       select 
       proj.ProjGUID,proj.ProjName,
       '本年计划竣备分期' as 项目分期分类
       into #本年计划竣备分期2
       from  #ProjectRecollect proj
       inner join #cb_CostStructureReport_qx str on proj.ProjGUID = str.项目guid
       where  datediff(year,str.计划竣备时间,@qxDate) = 0
       and not exists(select 1 from #已竣备分期1 where proj.ProjGUID = #已竣备分期1.ProjGUID)
       --4.本年新开工：剔除1/2后，[实际开工日期]在本年内
       select 
       proj.ProjGUID,proj.ProjName,
       '本年新开工' as 项目分期分类
       into #本年新开工4
       from  #ProjectRecollect proj
       inner join #cb_CostStructureReport_qx str on proj.ProjGUID = str.项目guid
       where datediff(year,str.实际开工时间,@qxDate) = 0
       and not exists(select 1 from #已竣备分期1 where proj.ProjGUID = #已竣备分期1.ProjGUID)
       and not exists(select 1 from #本年计划竣备分期2 where proj.ProjGUID = #本年计划竣备分期2.ProjGUID)
       -- 3. 在建分期:剔除1、2、4后，【实际开工日期】有数据 
       select 
       proj.ProjGUID,proj.ProjName,
       '在建分期' as 项目分期分类
       into #在建分期3
       from  #ProjectRecollect proj
       inner join #cb_CostStructureReport_qx str on proj.ProjGUID = str.项目guid
       where  str.实际开工时间 is not null
       and not exists(select 1 from #已竣备分期1 where proj.ProjGUID = #已竣备分期1.ProjGUID)
       and not exists(select 1 from #本年计划竣备分期2 where proj.ProjGUID = #本年计划竣备分期2.ProjGUID)
       and not exists(select 1 from #本年新开工4 where proj.ProjGUID = #本年新开工4.ProjGUID)   
       -- 5. 未开工：剔除1、2、3、4后，【实际开工日期】为空
       select 
       proj.ProjGUID,proj.ProjName,
       '未开工' as 项目分期分类
       into #未开工5
       from  #ProjectRecollect proj
       inner join #cb_CostStructureReport_qx str on proj.ProjGUID = str.项目guid
       where  str.实际开工时间 is null
       and not exists(select 1 from #已竣备分期1 where proj.ProjGUID = #已竣备分期1.ProjGUID)
       and not exists(select 1 from #本年计划竣备分期2 where proj.ProjGUID = #本年计划竣备分期2.ProjGUID)
       and not exists(select 1 from #本年新开工4 where proj.ProjGUID = #本年新开工4.ProjGUID)     
       and not exists(select 1 from #在建分期3 where proj.ProjGUID = #在建分期3.ProjGUID)

       -- 刷新#cb_CostStructureReport_qx表的[项目分期分类]
       update cb
       set 项目分期分类 = #已竣备分期1.项目分期分类
       from #cb_CostStructureReport_qx cb
       inner join #已竣备分期1 on cb.项目guid = #已竣备分期1.ProjGUID
       --where cb.项目分期分类 is null

       update cb
       set 项目分期分类 = #本年计划竣备分期2.项目分期分类
       from #cb_CostStructureReport_qx cb
       inner join #本年计划竣备分期2 on cb.项目guid = #本年计划竣备分期2.ProjGUID           
       --where cb.项目分期分类 is null

       update cb
       set 项目分期分类 = #本年新开工4.项目分期分类
       from #cb_CostStructureReport_qx cb
       inner join #本年新开工4 on cb.项目guid = #本年新开工4.ProjGUID               
       --where cb.项目分期分类 is null

       update cb
       set 项目分期分类 = #在建分期3.项目分期分类
       from #cb_CostStructureReport_qx cb
       inner join #在建分期3 on cb.项目guid = #在建分期3.ProjGUID
       --where cb.项目分期分类 is null                

       update cb
       set 项目分期分类 = #未开工5.项目分期分类
       from #cb_CostStructureReport_qx cb
       inner join #未开工5 on cb.项目guid = #未开工5.ProjGUID
       --where cb.项目分期分类 is null
       
       --2、 获取本年新增降本取值逻辑
      -- 2.1 在建分期： 本年和去年12月均有拍照数据
      -- 去年12月份拍照数据
       SELECT 
           a.ProjectGUID,
           SUM(b.SumAlterAmount_Fxj) AS SumAlterAmount_Fxj,
           SUM(b.DtCost) AS DtCost,
           ISNULL(SUM(b.DtCost), 0) - ISNULL(SUM(b.SumAlterAmount_Fxj), 0) AS DtCost_NotFxj -- 动态成本不含非现金含税
       into #去年12月拍照动态成本不含非现金
       FROM 
           (
               SELECT 
                   ROW_NUMBER() OVER (PARTITION BY ProjectGUID ORDER BY RecollectDate DESC) AS rn,
                   ProjectGUID,
                   RecollectGUID
               FROM 
                   cb_DTCostRecollect 
               WHERE 
                   DATEDIFF(YEAR, RecollectDate, GETDATE()) = 1
                   AND MONTH(RecollectDate) = 12
           ) a
       INNER JOIN 
           [dbo].[cb_DtCostRecollectDetails] b ON a.RecollectGUID = b.RecollectGUID AND a.rn = 1
       INNER JOIN 
           cb_Cost cost ON cost.CostGUID = b.CostGUID
       WHERE b.costcode NOT LIKE '5001.01.%' 
           AND b.costcode NOT LIKE '5001.09.%'
           AND b.costcode NOT LIKE '5001.10.%' 
           AND b.costcode NOT LIKE '5001.11%' 
           AND b.ytGUID ='00000000-0000-0000-0000-000000000000'
           AND cost.IfEndCost = 1
       GROUP BY 
           a.ProjectGUID

     -- 本年最早一个月的动态成本不含非现金含税
      SELECT 
           a.ProjectGUID,
           SUM(b.SumAlterAmount_Fxj) AS SumAlterAmount_Fxj,
           SUM(b.DtCost) AS DtCost,
           ISNULL(SUM(b.DtCost), 0) - ISNULL(SUM(b.SumAlterAmount_Fxj), 0) AS DtCost_NotFxj -- 动态成本不含非现金含税
       into #本年最早一个月拍照动态成本不含非现金
       FROM 
           (
               SELECT 
                   ROW_NUMBER() OVER (PARTITION BY ProjectGUID ORDER BY RecollectDate ) AS rn,
                   ProjectGUID,
                   RecollectGUID
               FROM 
                   cb_DTCostRecollect 
               WHERE 
                   DATEDIFF(YEAR, RecollectDate, GETDATE()) = 0 
           ) a
       INNER JOIN 
           [dbo].[cb_DtCostRecollectDetails] b ON a.RecollectGUID = b.RecollectGUID AND a.rn = 1
       INNER JOIN 
           cb_Cost cost ON cost.CostGUID = b.CostGUID
       WHERE b.costcode NOT LIKE '5001.01.%' 
           AND b.costcode NOT LIKE '5001.09.%'
           AND b.costcode NOT LIKE '5001.10.%' 
           AND b.costcode NOT LIKE '5001.11%' 
           AND b.ytGUID ='00000000-0000-0000-0000-000000000000'
           AND cost.IfEndCost = 1
       GROUP BY 
           a.ProjectGUID      

     -- 本月动态成本拍照数据
      SELECT 
           a.ProjectGUID,
           SUM(b.SumAlterAmount_Fxj) AS SumAlterAmount_Fxj,
           SUM(b.DtCost) AS DtCost,
           ISNULL(SUM(b.DtCost), 0) - ISNULL(SUM(b.SumAlterAmount_Fxj), 0) AS DtCost_NotFxj -- 动态成本不含非现金含税
       into #本月动态成本拍照数据
       FROM 
           (
               SELECT 
                   ROW_NUMBER() OVER (PARTITION BY ProjectGUID ORDER BY RecollectDate DESC) AS rn,
                   ProjectGUID,
                   RecollectGUID
               FROM 
                   cb_DTCostRecollect 
               WHERE 
                   DATEDIFF(YEAR, RecollectDate, GETDATE()) = 0 and MONTH(RecollectDate) = MONTH(GETDATE())
           ) a
       INNER JOIN 
           [dbo].[cb_DtCostRecollectDetails] b ON a.RecollectGUID = b.RecollectGUID AND a.rn = 1
       INNER JOIN 
           cb_Cost cost ON cost.CostGUID = b.CostGUID
       WHERE b.costcode NOT LIKE '5001.01.%' 
           AND b.costcode NOT LIKE '5001.09.%'
           AND b.costcode NOT LIKE '5001.10.%' 
           AND b.costcode NOT LIKE '5001.11%' 
           AND b.ytGUID ='00000000-0000-0000-0000-000000000000'
           AND cost.IfEndCost = 1
       GROUP BY 
           a.ProjectGUID         

     -- 今年最近一次拍照的动态成本不含非现金含税
       SELECT 
           a.ProjectGUID,
           SUM(b.SumAlterAmount_Fxj) AS SumAlterAmount_Fxj,
           SUM(b.DtCost) AS DtCost,
           ISNULL(SUM(b.DtCost), 0) - ISNULL(SUM(b.SumAlterAmount_Fxj), 0) AS DtCost_NotFxj -- 动态成本不含非现金含税
       into #今年最近一次拍照动态成本不含非现金
       FROM 
           (
               SELECT 
                   ROW_NUMBER() OVER (PARTITION BY ProjectGUID ORDER BY RecollectDate DESC) AS rn,
                   ProjectGUID,
                   RecollectGUID
               FROM 
                   cb_DTCostRecollect 
               WHERE 
                   DATEDIFF(YEAR, RecollectDate, GETDATE()) = 0
           ) a
       INNER JOIN 
           [dbo].[cb_DtCostRecollectDetails] b ON a.RecollectGUID = b.RecollectGUID AND a.rn = 1
       INNER JOIN 
           cb_Cost cost ON cost.CostGUID = b.CostGUID
       WHERE b.costcode NOT LIKE '5001.01.%' 
           AND b.costcode NOT LIKE '5001.09.%'
           AND b.costcode NOT LIKE '5001.10.%' 
           AND b.costcode NOT LIKE '5001.11%' 
           AND b.ytGUID ='00000000-0000-0000-0000-000000000000'
           AND cost.IfEndCost = 1
       GROUP BY 
           a.ProjectGUID
      --- 历史拍照数据
       SELECT 
           a.ProjectGUID,
           SUM(b.SumAlterAmount_Fxj) AS SumAlterAmount_Fxj,
           SUM(b.DtCost) AS DtCost,
           ISNULL(SUM(b.DtCost), 0) - ISNULL(SUM(b.SumAlterAmount_Fxj), 0) AS DtCost_NotFxj -- 动态成本不含非现金含税
       into #历史拍照动态成本不含非现金
       FROM 
           (
               SELECT 
                   ROW_NUMBER() OVER (PARTITION BY ProjectGUID ORDER BY RecollectDate DESC) AS rn,
                   ProjectGUID,
                   RecollectGUID
               FROM 
                   cb_DTCostRecollect 
               WHERE 
                   DATEDIFF(YEAR, RecollectDate, GETDATE()) >=1 AND MONTH(RecollectDate) <> 12
           ) a
       INNER JOIN 
           [dbo].[cb_DtCostRecollectDetails] b ON a.RecollectGUID = b.RecollectGUID AND a.rn = 1
       INNER JOIN 
           cb_Cost cost ON cost.CostGUID = b.CostGUID
       WHERE b.costcode NOT LIKE '5001.01.%' 
           AND b.costcode NOT LIKE '5001.09.%'
           AND b.costcode NOT LIKE '5001.10.%' 
           AND b.costcode NOT LIKE '5001.11%' 
           AND b.ytGUID ='00000000-0000-0000-0000-000000000000'
           AND cost.IfEndCost = 1
       GROUP BY 
           a.ProjectGUID    
     
     -- 计算本年新增降本金额
     SELECT 
        a.*,
        -- 本年和去年12月均有拍照数据
        CASE 
            WHEN qn12.DtCost_NotFxj IS NOT NULL AND cur.DtCost_NotFxj IS NOT NULL THEN ISNULL(qn12.DtCost_NotFxj, 0) - ISNULL(cur.DtCost_NotFxj, 0)
            -- 本年有数据，去年12月和历史均无数据
            WHEN qn12.DtCost_NotFxj IS NULL AND ls.DtCost_NotFxj IS NULL AND cur.DtCost_NotFxj IS NOT NULL THEN 
                CASE 
                    WHEN curmonth.DtCost_NotFxj IS NOT NULL THEN 0 
                    ELSE ISNULL(curfirst.DtCost_NotFxj, 0) - ISNULL(cur.DtCost_NotFxj, 0) 
                END
            -- 历史项目：本年有数据，去年12月无数据但历史数据数据
            WHEN cur.DtCost_NotFxj IS NOT NULL AND qn12.DtCost_NotFxj IS NULL AND ls.DtCost_NotFxj IS NOT NULL THEN ISNULL(ls.DtCost_NotFxj, 0) - ISNULL(cur.DtCost_NotFxj, 0)
            -- 历史老项目：本年无数据，历史有拍照数据
            WHEN cur.DtCost_NotFxj IS NULL AND ls.DtCost_NotFxj IS NOT NULL THEN 0
        END AS 本年新增降本,
        qn12.DtCost_NotFxj AS 去年12月拍照动态成本金额,
        cur.DtCost_NotFxj AS 本年最近一次拍照动态成本金额,
        ls.DtCost_NotFxj AS 历史拍照动态成本金额,
        curfirst.DtCost_NotFxj AS 本年最早一个月拍照动态成本金额,
        curmonth.DtCost_NotFxj AS 本月拍照动态成本金额
     INTO #cb_CostStructureReport_qx_pz 
     FROM #cb_CostStructureReport_qx a
     LEFT JOIN #去年12月拍照动态成本不含非现金 qn12 ON a.项目guid = qn12.ProjectGUID
     LEFT JOIN #今年最近一次拍照动态成本不含非现金 cur ON a.项目guid = cur.ProjectGUID
     LEFT JOIN #历史拍照动态成本不含非现金 ls ON a.项目guid = ls.ProjectGUID
     LEFT JOIN #本月动态成本拍照数据 curmonth ON a.项目guid = curmonth.ProjectGUID
     LEFT JOIN #本年最早一个月拍照动态成本不含非现金 curfirst ON a.项目guid = curfirst.ProjectGUID


    -- 查询结果
    -- 如果是总部数据
    if @buguid is null or @buguid = '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23'
    begin 
        SELECT
                '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' AS [公司GUID],
                '总部' AS [公司名称],
                GETDATE() AS [清洗日期],

                -- 分期数
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 1 else  0  end ) AS [已竣备分期_结算完成率等于100%_分期数],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then 1 else  0  end )  AS [已竣备分期_结算完成率95%至100%_分期数],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then 1 else  0  end )  AS [已竣备分期_结算完成率小于95%_分期数],
                sum( case when  项目分期分类 ='本年计划竣备分期' then 1 else  0  end )  AS [本年计划竣备分期_分期数],
                sum( case when  项目分期分类 ='在建分期' then 1 else  0  end )  AS [在建分期_分期数],
                sum( case when  项目分期分类 ='本年新开工' then 1 else  0  end )  AS [本年新开工_分期数], 
                sum( case when  项目分期分类 ='未开工' then 1 else  0  end )  AS [未开工_分期数],
                sum( case when  项目分期分类 is not null  then  1 else 0 end  ) as [分期数合计],

                -- 动态成本
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率等于100%_动态成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_动态成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_动态成本],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_动态成本],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [在建分期_动态成本],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [本年新开工_动态成本],
                sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [未开工_动态成本],
                sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) /100000000.0 as [动态成本合计],

                -- 除地价外直投不含非现金
                -- 3.1 AS [已竣备分期_结算完成率等于100%_除地价外直投不含非现金],
                -- 3.2 AS [已竣备分期_结算完成率95%至100%_除地价外直投不含非现金],
                -- 3.3 AS [已竣备分期_结算完成率小于95%_除地价外直投不含非现金],
                -- 3.4 AS [本年计划竣备分期_除地价外直投不含非现金],
                -- 3.5 AS [在建分期_除地价外直投不含非现金]
                -- 3.6 AS [本年新开工_除地价外直投不含非现金],
                -- 3.7 AS [未开工_除地价外直投不含非现金],

                -- 除地价外直投不含非现金占比
                case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
                else  sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end  AS [已竣备分期_结算完成率等于100%_除地价外直投不含非现金占比],
                case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
                else  sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end  AS [已竣备分期_结算完成率95%至100%_除地价外直投不含非现金占比],
                        case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
                else  sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [已竣备分期_结算完成率小于95%_除地价外直投不含非现金占比],
                case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
                else  sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [本年计划竣备分期_除地价外直投不含非现金占比],
                case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
                else  sum( case when  项目分期分类 ='已在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [在建分期_除地价外直投不含非现金占比],
                case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
                else  sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [本年新开工_除地价外直投不含非现金占比],
                case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
                else  sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [未开工_除地价外直投不含非现金占比],

                -- 已结算_合约成本
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_已结算_合约成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_已结算_合约成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_已结算_合约成本],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_已结算_合约成本],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_已结算_合约成本],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_已结算_合约成本],
                -- 未开工的取已结算的结算含税金额合计，单位亿，整数
                sum( case when  项目分期分类 ='未开工' then isnull(cb.结算_结算金额,0) else  0  end ) /100000000.0 AS [未开工_已结算_合约成本],
                round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end   ) /100000000.0 
                + sum( case when  项目分期分类 ='未开工' then isnull(cb.结算_结算金额,0) else  0  end ) /100000000.0, 0) AS [已结算合约成本合计],
                round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                else (sum( case when  项目分期分类 <>'未开工' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) + sum( case when  项目分期分类 ='未开工' then isnull(cb.结算_结算金额,0) else  0  end )  )
                / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0 end ,0)   as [已结算合约成本占动态成本比例],

                -- 已结算_预留成本 已结算合同的预留金金额默认为0
                0 AS [已竣备分期_结算完成率等于100%_已结算_预留成本],
                0 AS [已竣备分期_结算完成率95%至100%_已结算_预留成本],
                0 AS [已竣备分期_结算完成率小于95%_已结算_预留成本],
                0  AS [本年计划竣备分期_已结算_预留成本],
                0 AS [在建分期_已结算_预留成本],
                0 AS [本年新开工_已结算_预留成本],
                0 AS [未开工_已结算_预留成本],

                -- 已签约未结算_合约成本
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 
                isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0)
                    else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_已签约未结算_合约成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then 
                isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) 
                    else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_已签约未结算_合约成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then 
                isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_已签约未结算_合约成本],
                sum( case when  项目分期分类 ='本年计划竣备分期' then 
                isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [本年计划竣备分期_已签约未结算_合约成本],
                sum( case when  项目分期分类 ='在建分期' then 
                isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_已签约未结算_合约成本],
                sum( case when  项目分期分类 ='本年新开工' then 
                isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_已签约未结算_合约成本],
                sum( case when  项目分期分类 ='未开工' then isnull(合同签订情况_未结算的已签合同金额,0) else  0  end ) /100000000.0  AS [未开工_已签约未结算_合约成本],
                round(sum( case when  项目分期分类 <>'未开工' then 
                isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 
                + sum( case when  项目分期分类 ='未开工' then isnull(合同签订情况_未结算的已签合同金额,0) else  0  end ) /100000000.0 ,0)  AS [已签约未结算_合约成本合计],
                round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                    else ( sum( case when  项目分期分类 <>'未开工' then  isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) 
                + sum( case when  项目分期分类 ='未开工' then isnull(合同签订情况_未结算的已签合同金额,0) else  0  end )) / 
                sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
                end,0)  as [已签约未结算_合约成本占动态成本比例],
                

                -- 已签约未结算 预留成本
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 
                        isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
                    else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_已签约未结算_预留成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then 
                    isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
                    else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_已签约未结算_预留成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
                    else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_已签约未结算_预留成本],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
                    else  0  end ) /100000000.0 AS [本年计划竣备分期_已签约未结算_预留成本],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
                    else  0  end ) /100000000.0 AS [在建分期_已签约未结算_预留成本],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
                    else  0  end ) /100000000.0 AS [本年新开工_已签约未结算_预留成本],
                0  AS [未开工_已签约未结算_预留成本],

                -- 总价合同_合约成本
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_总价合同_合约成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_总价合同_合约成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_总价合同_合约成本],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_总价合同_合约成本],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_总价合同_合约成本],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_总价合同_合约成本],
                sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为总价包干_未结算的已签合同金额,0) else  0  end ) /100000000.0  AS [未开工_总价合同_合约成本],
                round(sum( case when  项目分期分类 <> '未开工' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 
                +  sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为总价包干_未结算的已签合同金额,0) else  0  end ) /100000000.0 ,0) as [总价合同_合约成本合计],
                round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                    else ( sum( case when  项目分期分类 <>'未开工' then  isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) 
                + sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为总价包干_未结算的已签合同金额,0) else  0  end )) / 
                sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
                end,0)  as [总价合同_合约成本占动态成本比例],     


                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_总价合同_预留成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_总价合同_预留成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_总价合同_预留成本],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_总价合同_预留成本],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [在建分期_总价合同_预留成本],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [本年新开工_总价合同_预留成本],
                0  AS [未开工_总价合同_预留成本],

                -- 单价合同(已转总)_合约成本
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_单价合同_已转总_合约成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_单价合同_已转总_合约成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_单价合同_已转总_合约成本],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [本年计划竣备分期_单价合同_已转总_合约成本],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [在建分期_单价合同_已转总_合约成本],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [本年新开工_单价合同_已转总_合约成本],
                sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_未结算的已签合同金额,0) else  0  end ) /100000000.0  AS [未开工_单价合同_已转总_合约成本],
                round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0 
                + sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_未结算的已签合同金额,0) else  0  end ) /100000000.0 ,0) as  [单价合同_已转总_合约成本合计],
                round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                    else ( sum( case when  项目分期分类 <>'未开工' then  isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) 
                + sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_未结算的已签合同金额,0) else  0  end )) / 
                sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
                end,0)  as [单价合同_已转总_合约成本占动态成本比例],

                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_单价合同_已转总_预留成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_单价合同_已转总_预留成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_单价合同_已转总_预留成本],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_单价合同_已转总_预留成本],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [在建分期_单价合同_已转总_预留成本],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [本年新开工_单价合同_已转总_预留成本],
                0  AS [未开工_单价合同_已转总_预留成本],


                -- 单价合同(未转总)_合约成本
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_单价合同_未转总_合约成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_单价合同_未转总_合约成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_单价合同_未转总_合约成本],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_单价合同_未转总_合约成本],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_单价合同_未转总_合约成本],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_单价合同_未转总_合约成本],
                sum( case when  项目分期分类 ='未开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_未结算的已签合同金额,0) else  0  end ) /100000000.0  AS [未开工_单价合同_未转总_合约成本],
                round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 
                + sum( case when  项目分期分类 ='未开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_未结算的已签合同金额,0) else  0  end ) /100000000.0,0) as [单价合同_未转总_合约成本合计],
                round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                    else ( sum( case when  项目分期分类 <>'未开工' then  isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) 
                + sum( case when  项目分期分类 ='未开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_未结算的已签合同金额,0) else  0  end )) 
                / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
                end,0)  as [单价合同_未转总_合约成本占动态成本比例],

                -- 单价合同(未转总)_预留成本
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_单价合同_未转总_预留成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_单价合同_未转总_预留成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_单价合同_未转总_预留成本],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_单价合同_未转总_预留成本],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [在建分期_单价合同_未转总_预留成本],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [本年新开工_单价合同_未转总_预留成本],
                0  AS [未开工_单价合同_未转总_预留成本],

                -- 未签约_合约成本
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_未签约_合约成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_未签约_合约成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_未签约_合约成本],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_未签约_合约成本],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_未签约_合约成本],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_未签约_合约成本],
                null AS [未开工_未签约_合约成本],
                round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 ,0) as [未签约_合约成本合计], 
                round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                    else  sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end )  
                    / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
                end,0)   [未签约_合约成本占动态成本比例],

                -- 未签约_预留成本
                0 AS [已竣备分期_结算完成率等于100%_未签约_预留成本], -- 默认为0
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_未签约_预留成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_未签约_预留成本],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_未签约_预留成本],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [在建分期_未签约_预留成本],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [本年新开工_未签约_预留成本],
                null   AS [未开工_未签约_预留成本],

                -- 预留金
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 
                        isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_预留金],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then 
                    isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else 0 end  ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_预留金],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then 
                    isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else 0 end  ) /100000000.0 AS [已竣备分期_结算完成率小于95%_预留金],
                sum( case when  项目分期分类 ='本年计划竣备分期' then 
                        isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end  ) /100000000.0 AS [本年计划竣备分期_预留金],
                sum( case when  项目分期分类 ='在建分期' then 
                        isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end  ) /100000000.0 AS [在建分期_预留金],
                sum( case when  项目分期分类 ='本年新开工' then 
                        isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end  ) /100000000.0 AS [本年新开工_预留金],
                0  AS [未开工_预留金],
                round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                        + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end ) /100000000.0 ,0 ) AS [预留金合计],
                case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                    else  ( sum( case when  项目分期分类 <>'未开工' then 
                        isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end )  )
                    / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) 
                end  as  [预留金占动态成本比例],   

                

                -- 预留金占比
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_预留金占比],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_预留金占比],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_预留金占比],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_预留金占比],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [在建分期_预留金占比],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [本年新开工_预留金占比],
                sum( case when  项目分期分类 ='未开工' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0  AS [未开工_预留金占比],

                -- 余量池
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_余量池],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_余量池],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_余量池],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_余量池],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [在建分期_余量池],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [本年新开工_余量池],
                null  AS [未开工_余量池],
                sum( case when  项目分期分类 <>'未开工' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0  as [余量池总计],
                case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                else   sum( case when  项目分期分类 <>'未开工' then isnull(cb.总成本情况_余量池,0) else  0  end ) 
                    / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )
                end  [余量池占动态成本比例],

                --最新执行版目标成本
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_最新版目标成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_最新版目标成本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_最新版目标成本],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_最新版目标成本],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [在建分期_最新版目标成本],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [本年新开工_最新版目标成本],
                NULL  AS [未开工_最新版目标成本],


                -- 余量池占比
                case when  
                    sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0  else 
                    sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_余量池,0) else  0  end )  
                    /sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end  AS [已竣备分期_结算完成率等于100%_余量池占比],
                case when  sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
                    sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_余量池,0) else  0  end )  
                    /sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end  AS [已竣备分期_结算完成率95%至100%_余量池占比],

                case when  sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
                    sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_余量池,0) else  0  end )  
                    /sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end AS [已竣备分期_结算完成率小于95%_余量池占比],
                
                case when  sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
                    sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_余量池,0) else  0  end )  
                    /sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end AS [本年计划竣备分期_余量池占比],

                case when  sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
                    sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_余量池,0) else  0  end )  
                    /sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end AS [在建分期_余量池占比],

                case when  sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
                    sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_余量池,0) else  0  end )  
                    /sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end AS [本年新开工_余量池占比],
                NULL  AS [未开工_余量池占比],


                -- 本年新增降本
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率等于100%_本年新增降本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率95%至100%_本年新增降本],
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_本年新增降本],
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [本年计划竣备分期_本年新增降本],
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [在建分期_本年新增降本],
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [本年新开工_本年新增降本],
                sum( case when  项目分期分类 ='未开工' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0    AS [未开工_本年新增降本],
                sum( case when  项目分期分类 is not NULL then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0    AS [新增降本合计],

                -- 本年新增降本占比
                case 
                    when sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                    then  0 
                    else 
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.本年新增降本,0) else  0  end ) 
                        / sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                end AS [已竣备分期_结算完成率等于100%_本年新增降本占比],
                case 
                    when sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                    then  0 
                    else 
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.本年新增降本,0) else  0  end ) 
                        / sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                end AS [已竣备分期_结算完成率95%至100%_本年新增降本占比],
                case 
                    when sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                    then  0 
                    else 
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.本年新增降本,0) else  0  end ) 
                        / sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                end AS [已竣备分期_结算完成率小于95%_本年新增降本占比],
                case 
                    when sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                    then  0 
                    else 
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.本年新增降本,0) else  0  end ) 
                        / sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                end AS [本年计划竣备分期_本年新增降本占比],
                case 
                    when sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                    then  0 
                    else 
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.本年新增降本,0) else  0  end ) 
                        / sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                end AS [在建分期_本年新增降本占比],
                case 
                    when sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                    then  0 
                    else 
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.本年新增降本,0) else  0  end ) 
                        / sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                end AS [本年新开工_本年新增降本占比],
                case 
                    when sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                    then  0 
                    else 
                        sum( case when  项目分期分类 ='未开工' then isnull(cb.本年新增降本,0) else  0  end ) 
                        / sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                end AS [未开工_本年新增降本占比],
                case 
                    when sum( case when  项目分期分类 is not NULL then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                    then  0 
                    else 
                        sum( case when  项目分期分类 is not NULL then isnull(cb.本年新增降本,0) else  0  end ) 
                        / sum( case when  项目分期分类 is not NULL then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                end as  [新增降本金额占比]
            FROM  #cb_CostStructureReport_qx_pz cb 
            where 公司guid IN ( SELECT  Value FROM  [dbo].[fn_Split2](@buguidList, ',') )
            -- GROUP BY 公司guid,公司名称
            
            -- 加上各个平台公司数据
            union all 

                      SELECT
                            公司GUID AS [公司GUID],
                            公司名称 AS [公司名称],
                        GETDATE() AS [清洗日期],

                        -- 分期数
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 1 else  0  end ) AS [已竣备分期_结算完成率等于100%_分期数],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then 1 else  0  end )  AS [已竣备分期_结算完成率95%至100%_分期数],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then 1 else  0  end )  AS [已竣备分期_结算完成率小于95%_分期数],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then 1 else  0  end )  AS [本年计划竣备分期_分期数],
                        sum( case when  项目分期分类 ='在建分期' then 1 else  0  end )  AS [在建分期_分期数],
                        sum( case when  项目分期分类 ='本年新开工' then 1 else  0  end )  AS [本年新开工_分期数], 
                        sum( case when  项目分期分类 ='未开工' then 1 else  0  end )  AS [未开工_分期数],
                        sum( case when  项目分期分类 is not null  then  1 else 0 end  ) as [分期数合计],

                        -- 动态成本
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率等于100%_动态成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_动态成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_动态成本],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_动态成本],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [在建分期_动态成本],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [本年新开工_动态成本],
                        sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [未开工_动态成本],
                        sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) /100000000.0 as [动态成本合计],

                        -- 除地价外直投不含非现金
                        -- 3.1 AS [已竣备分期_结算完成率等于100%_除地价外直投不含非现金],
                        -- 3.2 AS [已竣备分期_结算完成率95%至100%_除地价外直投不含非现金],
                        -- 3.3 AS [已竣备分期_结算完成率小于95%_除地价外直投不含非现金],
                        -- 3.4 AS [本年计划竣备分期_除地价外直投不含非现金],
                        -- 3.5 AS [在建分期_除地价外直投不含非现金]
                        -- 3.6 AS [本年新开工_除地价外直投不含非现金],
                        -- 3.7 AS [未开工_除地价外直投不含非现金],

                        -- 除地价外直投不含非现金占比
                        case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
                        else  sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end  AS [已竣备分期_结算完成率等于100%_除地价外直投不含非现金占比],
                        case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
                        else  sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end  AS [已竣备分期_结算完成率95%至100%_除地价外直投不含非现金占比],
                                case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
                        else  sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [已竣备分期_结算完成率小于95%_除地价外直投不含非现金占比],
                        case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
                        else  sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [本年计划竣备分期_除地价外直投不含非现金占比],
                        case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
                        else  sum( case when  项目分期分类 ='已在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [在建分期_除地价外直投不含非现金占比],
                        case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
                        else  sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [本年新开工_除地价外直投不含非现金占比],
                        case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
                        else  sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [未开工_除地价外直投不含非现金占比],

                        -- 已结算_合约成本
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_已结算_合约成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_已结算_合约成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_已结算_合约成本],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_已结算_合约成本],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_已结算_合约成本],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_已结算_合约成本],
                        -- 未开工的取已结算的结算含税金额合计，单位亿，整数
                        sum( case when  项目分期分类 ='未开工' then isnull(cb.结算_结算金额,0) else  0  end ) /100000000.0 AS [未开工_已结算_合约成本],
                        round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end   ) /100000000.0 
                        + sum( case when  项目分期分类 ='未开工' then isnull(cb.结算_结算金额,0) else  0  end ) /100000000.0, 0) AS [已结算合约成本合计],
                        round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                        else (sum( case when  项目分期分类 <>'未开工' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) + sum( case when  项目分期分类 ='未开工' then isnull(cb.结算_结算金额,0) else  0  end )  )
                        / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0 end ,0)   as [已结算合约成本占动态成本比例],

                        -- 已结算_预留成本 已结算合同的预留金金额默认为0
                        0 AS [已竣备分期_结算完成率等于100%_已结算_预留成本],
                        0 AS [已竣备分期_结算完成率95%至100%_已结算_预留成本],
                        0 AS [已竣备分期_结算完成率小于95%_已结算_预留成本],
                        0  AS [本年计划竣备分期_已结算_预留成本],
                        0 AS [在建分期_已结算_预留成本],
                        0 AS [本年新开工_已结算_预留成本],
                        0 AS [未开工_已结算_预留成本],

                        -- 已签约未结算_合约成本
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 
                        isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0)
                            else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_已签约未结算_合约成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then 
                        isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) 
                            else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_已签约未结算_合约成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then 
                        isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_已签约未结算_合约成本],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then 
                        isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [本年计划竣备分期_已签约未结算_合约成本],
                        sum( case when  项目分期分类 ='在建分期' then 
                        isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_已签约未结算_合约成本],
                        sum( case when  项目分期分类 ='本年新开工' then 
                        isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_已签约未结算_合约成本],
                        sum( case when  项目分期分类 ='未开工' then isnull(合同签订情况_未结算的已签合同金额,0) else  0  end ) /100000000.0  AS [未开工_已签约未结算_合约成本],
                        round(sum( case when  项目分期分类 <>'未开工' then 
                        isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 
                        + sum( case when  项目分期分类 ='未开工' then isnull(合同签订情况_未结算的已签合同金额,0) else  0  end ) /100000000.0 ,0)  AS [已签约未结算_合约成本合计],
                        round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                            else ( sum( case when  项目分期分类 <>'未开工' then  isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) 
                        + sum( case when  项目分期分类 ='未开工' then isnull(合同签订情况_未结算的已签合同金额,0) else  0  end )) / 
                        sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
                        end,0)  as [已签约未结算_合约成本占动态成本比例],
                        

                        -- 已签约未结算 预留成本
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 
                                isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
                            else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_已签约未结算_预留成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then 
                            isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
                            else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_已签约未结算_预留成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
                            else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_已签约未结算_预留成本],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
                            else  0  end ) /100000000.0 AS [本年计划竣备分期_已签约未结算_预留成本],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
                            else  0  end ) /100000000.0 AS [在建分期_已签约未结算_预留成本],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
                            else  0  end ) /100000000.0 AS [本年新开工_已签约未结算_预留成本],
                        0  AS [未开工_已签约未结算_预留成本],

                        -- 总价合同_合约成本
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_总价合同_合约成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_总价合同_合约成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_总价合同_合约成本],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_总价合同_合约成本],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_总价合同_合约成本],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_总价合同_合约成本],
                        sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为总价包干_未结算的已签合同金额,0) else  0  end ) /100000000.0  AS [未开工_总价合同_合约成本],
                        round(sum( case when  项目分期分类 <> '未开工' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 
                        +  sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为总价包干_未结算的已签合同金额,0) else  0  end ) /100000000.0 ,0) as [总价合同_合约成本合计],
                        round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                            else ( sum( case when  项目分期分类 <>'未开工' then  isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) 
                        + sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为总价包干_未结算的已签合同金额,0) else  0  end )) / 
                        sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
                        end,0)  as [总价合同_合约成本占动态成本比例],     


                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_总价合同_预留成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_总价合同_预留成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_总价合同_预留成本],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_总价合同_预留成本],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [在建分期_总价合同_预留成本],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [本年新开工_总价合同_预留成本],
                        0  AS [未开工_总价合同_预留成本],

                        -- 单价合同(已转总)_合约成本
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_单价合同_已转总_合约成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_单价合同_已转总_合约成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_单价合同_已转总_合约成本],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [本年计划竣备分期_单价合同_已转总_合约成本],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [在建分期_单价合同_已转总_合约成本],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [本年新开工_单价合同_已转总_合约成本],
                        sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_未结算的已签合同金额,0) else  0  end ) /100000000.0  AS [未开工_单价合同_已转总_合约成本],
                        round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0 
                        + sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_未结算的已签合同金额,0) else  0  end ) /100000000.0 ,0) as  [单价合同_已转总_合约成本合计],
                        round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                            else ( sum( case when  项目分期分类 <>'未开工' then  isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) 
                        + sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_未结算的已签合同金额,0) else  0  end )) / 
                        sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
                        end,0)  as [单价合同_已转总_合约成本占动态成本比例],

                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_单价合同_已转总_预留成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_单价合同_已转总_预留成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_单价合同_已转总_预留成本],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_单价合同_已转总_预留成本],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [在建分期_单价合同_已转总_预留成本],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [本年新开工_单价合同_已转总_预留成本],
                        0  AS [未开工_单价合同_已转总_预留成本],


                        -- 单价合同(未转总)_合约成本
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_单价合同_未转总_合约成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_单价合同_未转总_合约成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_单价合同_未转总_合约成本],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_单价合同_未转总_合约成本],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_单价合同_未转总_合约成本],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_单价合同_未转总_合约成本],
                        sum( case when  项目分期分类 ='未开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_未结算的已签合同金额,0) else  0  end ) /100000000.0  AS [未开工_单价合同_未转总_合约成本],
                        round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 
                        + sum( case when  项目分期分类 ='未开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_未结算的已签合同金额,0) else  0  end ) /100000000.0,0) as [单价合同_未转总_合约成本合计],
                        round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                            else ( sum( case when  项目分期分类 <>'未开工' then  isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) 
                        + sum( case when  项目分期分类 ='未开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_未结算的已签合同金额,0) else  0  end )) 
                        / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
                        end,0)  as [单价合同_未转总_合约成本占动态成本比例],

                        -- 单价合同(未转总)_预留成本
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_单价合同_未转总_预留成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_单价合同_未转总_预留成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_单价合同_未转总_预留成本],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_单价合同_未转总_预留成本],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [在建分期_单价合同_未转总_预留成本],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [本年新开工_单价合同_未转总_预留成本],
                        0  AS [未开工_单价合同_未转总_预留成本],

                        -- 未签约_合约成本
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_未签约_合约成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_未签约_合约成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_未签约_合约成本],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_未签约_合约成本],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_未签约_合约成本],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_未签约_合约成本],
                        null AS [未开工_未签约_合约成本],
                        round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 ,0) as [未签约_合约成本合计], 
                        round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                            else  sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end )  
                            / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
                        end,0)   [未签约_合约成本占动态成本比例],

                        -- 未签约_预留成本
                        0 AS [已竣备分期_结算完成率等于100%_未签约_预留成本], -- 默认为0
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_未签约_预留成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_未签约_预留成本],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_未签约_预留成本],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [在建分期_未签约_预留成本],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [本年新开工_未签约_预留成本],
                        null   AS [未开工_未签约_预留成本],

                        -- 预留金
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 
                                isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_预留金],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then 
                            isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else 0 end  ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_预留金],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then 
                            isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else 0 end  ) /100000000.0 AS [已竣备分期_结算完成率小于95%_预留金],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then 
                                isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end  ) /100000000.0 AS [本年计划竣备分期_预留金],
                        sum( case when  项目分期分类 ='在建分期' then 
                                isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end  ) /100000000.0 AS [在建分期_预留金],
                        sum( case when  项目分期分类 ='本年新开工' then 
                                isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end  ) /100000000.0 AS [本年新开工_预留金],
                        0  AS [未开工_预留金],
                        round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                                + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end ) /100000000.0 ,0 ) AS [预留金合计],
                        case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                            else  ( sum( case when  项目分期分类 <>'未开工' then 
                                isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end )  )
                            / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) 
                        end  as  [预留金占动态成本比例],   

                        

                        -- 预留金占比
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_预留金占比],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_预留金占比],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_预留金占比],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_预留金占比],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [在建分期_预留金占比],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [本年新开工_预留金占比],
                        sum( case when  项目分期分类 ='未开工' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0  AS [未开工_预留金占比],

                        -- 余量池
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_余量池],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_余量池],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_余量池],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_余量池],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [在建分期_余量池],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [本年新开工_余量池],
                        null  AS [未开工_余量池],
                        sum( case when  项目分期分类 <>'未开工' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0  as [余量池总计],
                        case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                        else   sum( case when  项目分期分类 <>'未开工' then isnull(cb.总成本情况_余量池,0) else  0  end ) 
                            / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )
                        end  [余量池占动态成本比例],

                        --最新执行版目标成本
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_最新版目标成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_最新版目标成本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_最新版目标成本],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_最新版目标成本],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [在建分期_最新版目标成本],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [本年新开工_最新版目标成本],
                        NULL  AS [未开工_最新版目标成本],


                        -- 余量池占比
                        case when  
                            sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0  else 
                            sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_余量池,0) else  0  end )  
                            /sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end  AS [已竣备分期_结算完成率等于100%_余量池占比],
                        case when  sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
                            sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_余量池,0) else  0  end )  
                            /sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end  AS [已竣备分期_结算完成率95%至100%_余量池占比],

                        case when  sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
                            sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_余量池,0) else  0  end )  
                            /sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end AS [已竣备分期_结算完成率小于95%_余量池占比],
                        
                        case when  sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
                            sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_余量池,0) else  0  end )  
                            /sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end AS [本年计划竣备分期_余量池占比],

                        case when  sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
                            sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_余量池,0) else  0  end )  
                            /sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end AS [在建分期_余量池占比],

                        case when  sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
                            sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_余量池,0) else  0  end )  
                            /sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end AS [本年新开工_余量池占比],
                        NULL  AS [未开工_余量池占比],


                        -- 本年新增降本
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率等于100%_本年新增降本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率95%至100%_本年新增降本],
                        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_本年新增降本],
                        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [本年计划竣备分期_本年新增降本],
                        sum( case when  项目分期分类 ='在建分期' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [在建分期_本年新增降本],
                        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [本年新开工_本年新增降本],
                        sum( case when  项目分期分类 ='未开工' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0    AS [未开工_本年新增降本],
                        sum( case when  项目分期分类 is not NULL then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0    AS [新增降本合计],

                        -- 本年新增降本占比
                        case 
                            when sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                            then  0 
                            else 
                                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.本年新增降本,0) else  0  end ) 
                                / sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                        end AS [已竣备分期_结算完成率等于100%_本年新增降本占比],
                        case 
                            when sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                            then  0 
                            else 
                                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.本年新增降本,0) else  0  end ) 
                                / sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                        end AS [已竣备分期_结算完成率95%至100%_本年新增降本占比],
                        case 
                            when sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                            then  0 
                            else 
                                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.本年新增降本,0) else  0  end ) 
                                / sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                        end AS [已竣备分期_结算完成率小于95%_本年新增降本占比],
                        case 
                            when sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                            then  0 
                            else 
                                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.本年新增降本,0) else  0  end ) 
                                / sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                        end AS [本年计划竣备分期_本年新增降本占比],
                        case 
                            when sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                            then  0 
                            else 
                                sum( case when  项目分期分类 ='在建分期' then isnull(cb.本年新增降本,0) else  0  end ) 
                                / sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                        end AS [在建分期_本年新增降本占比],
                        case 
                            when sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                            then  0 
                            else 
                                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.本年新增降本,0) else  0  end ) 
                                / sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                        end AS [本年新开工_本年新增降本占比],
                        case 
                            when sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                            then  0 
                            else 
                                sum( case when  项目分期分类 ='未开工' then isnull(cb.本年新增降本,0) else  0  end ) 
                                / sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                        end AS [未开工_本年新增降本占比],
                        case 
                            when sum( case when  项目分期分类 is not NULL then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
                            then  0 
                            else 
                                sum( case when  项目分期分类 is not NULL then isnull(cb.本年新增降本,0) else  0  end ) 
                                / sum( case when  项目分期分类 is not NULL then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                        end as  [新增降本金额占比]
                    FROM  #cb_CostStructureReport_qx_pz cb 
                    where 公司guid IN ( SELECT  Value FROM  [dbo].[fn_Split2](@buguidList, ',') )
                    GROUP BY 公司guid,公司名称
        
    end  
    else 
    begin
        SELECT
            公司GUID AS [公司GUID],
            公司名称 AS [公司名称],
        GETDATE() AS [清洗日期],

        -- 分期数
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 1 else  0  end ) AS [已竣备分期_结算完成率等于100%_分期数],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then 1 else  0  end )  AS [已竣备分期_结算完成率95%至100%_分期数],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then 1 else  0  end )  AS [已竣备分期_结算完成率小于95%_分期数],
        sum( case when  项目分期分类 ='本年计划竣备分期' then 1 else  0  end )  AS [本年计划竣备分期_分期数],
        sum( case when  项目分期分类 ='在建分期' then 1 else  0  end )  AS [在建分期_分期数],
        sum( case when  项目分期分类 ='本年新开工' then 1 else  0  end )  AS [本年新开工_分期数], 
        sum( case when  项目分期分类 ='未开工' then 1 else  0  end )  AS [未开工_分期数],
        sum( case when  项目分期分类 is not null  then  1 else 0 end  ) as [分期数合计],

        -- 动态成本
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率等于100%_动态成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_动态成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_动态成本],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_动态成本],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [在建分期_动态成本],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [本年新开工_动态成本],
        sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [未开工_动态成本],
        sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) /100000000.0 as [动态成本合计],

        -- 除地价外直投不含非现金
        -- 3.1 AS [已竣备分期_结算完成率等于100%_除地价外直投不含非现金],
        -- 3.2 AS [已竣备分期_结算完成率95%至100%_除地价外直投不含非现金],
        -- 3.3 AS [已竣备分期_结算完成率小于95%_除地价外直投不含非现金],
        -- 3.4 AS [本年计划竣备分期_除地价外直投不含非现金],
        -- 3.5 AS [在建分期_除地价外直投不含非现金]
        -- 3.6 AS [本年新开工_除地价外直投不含非现金],
        -- 3.7 AS [未开工_除地价外直投不含非现金],

        -- 除地价外直投不含非现金占比
        case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
           else  sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end  AS [已竣备分期_结算完成率等于100%_除地价外直投不含非现金占比],
        case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
           else  sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end  AS [已竣备分期_结算完成率95%至100%_除地价外直投不含非现金占比],
                case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
           else  sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [已竣备分期_结算完成率小于95%_除地价外直投不含非现金占比],
        case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
           else  sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [本年计划竣备分期_除地价外直投不含非现金占比],
        case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
           else  sum( case when  项目分期分类 ='已在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [在建分期_除地价外直投不含非现金占比],
        case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
           else  sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [本年新开工_除地价外直投不含非现金占比],
        case when sum(isnull(cb.总成本情况_动态成本,0)) =0  then  0 
           else  sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [未开工_除地价外直投不含非现金占比],

        -- 已结算_合约成本
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_已结算_合约成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_已结算_合约成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_已结算_合约成本],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_已结算_合约成本],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_已结算_合约成本],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_已结算_合约成本],
        -- 未开工的取已结算的结算含税金额合计，单位亿，整数
        sum( case when  项目分期分类 ='未开工' then isnull(cb.结算_结算金额,0) else  0  end ) /100000000.0 AS [未开工_已结算_合约成本],
        round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end   ) /100000000.0 
        + sum( case when  项目分期分类 ='未开工' then isnull(cb.结算_结算金额,0) else  0  end ) /100000000.0, 0) AS [已结算合约成本合计],
        round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
        else (sum( case when  项目分期分类 <>'未开工' then isnull(cb.结算_已结算最新合约规划金额,0) else  0  end ) + sum( case when  项目分期分类 ='未开工' then isnull(cb.结算_结算金额,0) else  0  end )  )
           / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0 end ,0)   as [已结算合约成本占动态成本比例],

        -- 已结算_预留成本 已结算合同的预留金金额默认为0
        0 AS [已竣备分期_结算完成率等于100%_已结算_预留成本],
        0 AS [已竣备分期_结算完成率95%至100%_已结算_预留成本],
        0 AS [已竣备分期_结算完成率小于95%_已结算_预留成本],
        0  AS [本年计划竣备分期_已结算_预留成本],
        0 AS [在建分期_已结算_预留成本],
        0 AS [本年新开工_已结算_预留成本],
        0 AS [未开工_已结算_预留成本],

        -- 已签约未结算_合约成本
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 
           isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0)
            else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_已签约未结算_合约成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then 
           isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) 
            else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_已签约未结算_合约成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then 
          isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_已签约未结算_合约成本],
        sum( case when  项目分期分类 ='本年计划竣备分期' then 
           isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [本年计划竣备分期_已签约未结算_合约成本],
        sum( case when  项目分期分类 ='在建分期' then 
           isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_已签约未结算_合约成本],
        sum( case when  项目分期分类 ='本年新开工' then 
           isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_已签约未结算_合约成本],
        sum( case when  项目分期分类 ='未开工' then isnull(合同签订情况_未结算的已签合同金额,0) else  0  end ) /100000000.0  AS [未开工_已签约未结算_合约成本],
        round(sum( case when  项目分期分类 <>'未开工' then 
           isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 
           + sum( case when  项目分期分类 ='未开工' then isnull(合同签订情况_未结算的已签合同金额,0) else  0  end ) /100000000.0 ,0)  AS [已签约未结算_合约成本合计],
        round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
            else ( sum( case when  项目分期分类 <>'未开工' then  isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) + isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) 
           + sum( case when  项目分期分类 ='未开工' then isnull(合同签订情况_未结算的已签合同金额,0) else  0  end )) / 
           sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
        end,0)  as [已签约未结算_合约成本占动态成本比例],
        

        -- 已签约未结算 预留成本
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 
                isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
             else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_已签约未结算_预留成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then 
               isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
             else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_已签约未结算_预留成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
             else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_已签约未结算_预留成本],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
             else  0  end ) /100000000.0 AS [本年计划竣备分期_已签约未结算_预留成本],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
             else  0  end ) /100000000.0 AS [在建分期_已签约未结算_预留成本],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)     
             else  0  end ) /100000000.0 AS [本年新开工_已签约未结算_预留成本],
        0  AS [未开工_已签约未结算_预留成本],

        -- 总价合同_合约成本
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_总价合同_合约成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_总价合同_合约成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_总价合同_合约成本],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_总价合同_合约成本],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_总价合同_合约成本],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_总价合同_合约成本],
        sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为总价包干_未结算的已签合同金额,0) else  0  end ) /100000000.0  AS [未开工_总价合同_合约成本],
        round(sum( case when  项目分期分类 <> '未开工' then isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) /100000000.0 
          +  sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为总价包干_未结算的已签合同金额,0) else  0  end ) /100000000.0 ,0) as [总价合同_合约成本合计],
        round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
            else ( sum( case when  项目分期分类 <>'未开工' then  isnull(cb.总价合同_首次签约为总价包干_最新合约规划金额,0) else  0  end ) 
           + sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为总价包干_未结算的已签合同金额,0) else  0  end )) / 
           sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
        end,0)  as [总价合同_合约成本占动态成本比例],     


        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_总价合同_预留成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_总价合同_预留成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_总价合同_预留成本],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_总价合同_预留成本],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [在建分期_总价合同_预留成本],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) else  0  end ) /100000000.0 AS [本年新开工_总价合同_预留成本],
        0  AS [未开工_总价合同_预留成本],

        -- 单价合同(已转总)_合约成本
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_单价合同_已转总_合约成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_单价合同_已转总_合约成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_单价合同_已转总_合约成本],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [本年计划竣备分期_单价合同_已转总_合约成本],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [在建分期_单价合同_已转总_合约成本],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0  AS [本年新开工_单价合同_已转总_合约成本],
        sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_未结算的已签合同金额,0) else  0  end ) /100000000.0  AS [未开工_单价合同_已转总_合约成本],
        round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) /100000000.0 
         + sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_未结算的已签合同金额,0) else  0  end ) /100000000.0 ,0) as  [单价合同_已转总_合约成本合计],
        round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
            else ( sum( case when  项目分期分类 <>'未开工' then  isnull(cb.总价合同_首次签约为单价合同_目前已转总_最新合约规划金额,0) else  0  end ) 
           + sum( case when  项目分期分类 ='未开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_未结算的已签合同金额,0) else  0  end )) / 
           sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
        end,0)  as [单价合同_已转总_合约成本占动态成本比例],

        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_单价合同_已转总_预留成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_单价合同_已转总_预留成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_单价合同_已转总_预留成本],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_单价合同_已转总_预留成本],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [在建分期_单价合同_已转总_预留成本],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) else  0  end ) /100000000.0 AS [本年新开工_单价合同_已转总_预留成本],
        0  AS [未开工_单价合同_已转总_预留成本],


        -- 单价合同(未转总)_合约成本
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_单价合同_未转总_合约成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_单价合同_未转总_合约成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_单价合同_未转总_合约成本],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_单价合同_未转总_合约成本],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_单价合同_未转总_合约成本],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_单价合同_未转总_合约成本],
        sum( case when  项目分期分类 ='未开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_未结算的已签合同金额,0) else  0  end ) /100000000.0  AS [未开工_单价合同_未转总_合约成本],
        round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) /100000000.0 
          + sum( case when  项目分期分类 ='未开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_未结算的已签合同金额,0) else  0  end ) /100000000.0,0) as [单价合同_未转总_合约成本合计],
        round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
            else ( sum( case when  项目分期分类 <>'未开工' then  isnull(cb.单价合同_首次签约为单价合同且未完成转总_最新合约规划金额,0) else  0  end ) 
           + sum( case when  项目分期分类 ='未开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_未结算的已签合同金额,0) else  0  end )) 
           / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
        end,0)  as [单价合同_未转总_合约成本占动态成本比例],

        -- 单价合同(未转总)_预留成本
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_单价合同_未转总_预留成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_单价合同_未转总_预留成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_单价合同_未转总_预留成本],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_单价合同_未转总_预留成本],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [在建分期_单价合同_未转总_预留成本],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) /100000000.0 AS [本年新开工_单价合同_未转总_预留成本],
        0  AS [未开工_单价合同_未转总_预留成本],

        -- 未签约_合约成本
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_未签约_合约成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_未签约_合约成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_未签约_合约成本],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_未签约_合约成本],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [在建分期_未签约_合约成本],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 AS [本年新开工_未签约_合约成本],
        null AS [未开工_未签约_合约成本],
        round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 ,0) as [未签约_合约成本合计], 
        round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
            else  sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end )  
              / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
        end,0)   [未签约_合约成本占动态成本比例],

        -- 未签约_预留成本
        0 AS [已竣备分期_结算完成率等于100%_未签约_预留成本], -- 默认为0
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_未签约_预留成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_未签约_预留成本],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_未签约_预留成本],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [在建分期_未签约_预留成本],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.待签约_待发生预留金,0) else  0  end ) /100000000.0 AS [本年新开工_未签约_预留成本],
        null   AS [未开工_未签约_预留成本],

        -- 预留金
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 
                isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_预留金],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then 
               isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else 0 end  ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_预留金],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then 
               isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else 0 end  ) /100000000.0 AS [已竣备分期_结算完成率小于95%_预留金],
        sum( case when  项目分期分类 ='本年计划竣备分期' then 
                isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end  ) /100000000.0 AS [本年计划竣备分期_预留金],
        sum( case when  项目分期分类 ='在建分期' then 
                isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end  ) /100000000.0 AS [在建分期_预留金],
        sum( case when  项目分期分类 ='本年新开工' then 
                isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end  ) /100000000.0 AS [本年新开工_预留金],
        0  AS [未开工_预留金],
        round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end ) /100000000.0 ,0 ) AS [预留金合计],
        case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
            else  ( sum( case when  项目分期分类 <>'未开工' then 
                isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end )  )
              / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) 
        end  as  [预留金占动态成本比例],   

        

        -- 预留金占比
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_预留金占比],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_预留金占比],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_预留金占比],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_预留金占比],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [在建分期_预留金占比],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0 AS [本年新开工_预留金占比],
        sum( case when  项目分期分类 ='未开工' then isnull(cb.预留金_待发生预留金,0) else  0  end ) /100000000.0  AS [未开工_预留金占比],

        -- 余量池
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_余量池],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_余量池],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_余量池],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_余量池],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [在建分期_余量池],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0 AS [本年新开工_余量池],
        null  AS [未开工_余量池],
        sum( case when  项目分期分类 <>'未开工' then isnull(cb.总成本情况_余量池,0) else  0  end ) /100000000.0  as [余量池总计],
        case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
           else   sum( case when  项目分期分类 <>'未开工' then isnull(cb.总成本情况_余量池,0) else  0  end ) 
               / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )
        end  [余量池占动态成本比例],

        --最新执行版目标成本
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率等于100%_最新版目标成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率95%至100%_最新版目标成本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [已竣备分期_结算完成率小于95%_最新版目标成本],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [本年计划竣备分期_最新版目标成本],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [在建分期_最新版目标成本],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) /100000000.0 AS [本年新开工_最新版目标成本],
        NULL  AS [未开工_最新版目标成本],


        -- 余量池占比
        case when  
            sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0  else 
            sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_余量池,0) else  0  end )  
            /sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end  AS [已竣备分期_结算完成率等于100%_余量池占比],
        case when  sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
            sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_余量池,0) else  0  end )  
            /sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end  AS [已竣备分期_结算完成率95%至100%_余量池占比],

        case when  sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
            sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_余量池,0) else  0  end )  
            /sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end AS [已竣备分期_结算完成率小于95%_余量池占比],
        
        case when  sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
            sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_余量池,0) else  0  end )  
            /sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end AS [本年计划竣备分期_余量池占比],

        case when  sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
            sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_余量池,0) else  0  end )  
            /sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end AS [在建分期_余量池占比],

        case when  sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) = 0 then  0 else     
            sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_余量池,0) else  0  end )  
            /sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_当前执行版目标成本,0) else  0  end ) end AS [本年新开工_余量池占比],
        NULL  AS [未开工_余量池占比],


        -- 本年新增降本
        sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率等于100%_本年新增降本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率95%至100%_本年新增降本],
        sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [已竣备分期_结算完成率小于95%_本年新增降本],
        sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [本年计划竣备分期_本年新增降本],
        sum( case when  项目分期分类 ='在建分期' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [在建分期_本年新增降本],
        sum( case when  项目分期分类 ='本年新开工' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0  AS [本年新开工_本年新增降本],
        sum( case when  项目分期分类 ='未开工' then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0    AS [未开工_本年新增降本],
        sum( case when  项目分期分类 is not NULL then isnull(cb.本年新增降本,0) else  0  end ) /100000000.0    AS [新增降本合计],

        -- 本年新增降本占比
        case 
            when sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
            then  0 
            else 
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.本年新增降本,0) else  0  end ) 
                / sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
        end AS [已竣备分期_结算完成率等于100%_本年新增降本占比],
        case 
            when sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
            then  0 
            else 
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.本年新增降本,0) else  0  end ) 
                / sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
        end AS [已竣备分期_结算完成率95%至100%_本年新增降本占比],
        case 
            when sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
            then  0 
            else 
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.本年新增降本,0) else  0  end ) 
                / sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
        end AS [已竣备分期_结算完成率小于95%_本年新增降本占比],
        case 
            when sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
            then  0 
            else 
                sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.本年新增降本,0) else  0  end ) 
                / sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
        end AS [本年计划竣备分期_本年新增降本占比],
        case 
            when sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
            then  0 
            else 
                sum( case when  项目分期分类 ='在建分期' then isnull(cb.本年新增降本,0) else  0  end ) 
                / sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
        end AS [在建分期_本年新增降本占比],
        case 
            when sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
            then  0 
            else 
                sum( case when  项目分期分类 ='本年新开工' then isnull(cb.本年新增降本,0) else  0  end ) 
                / sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
        end AS [本年新开工_本年新增降本占比],
        case 
            when sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
            then  0 
            else 
                sum( case when  项目分期分类 ='未开工' then isnull(cb.本年新增降本,0) else  0  end ) 
                / sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
        end AS [未开工_本年新增降本占比],
         case 
            when sum( case when  项目分期分类 is not NULL then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0 
            then  0 
            else 
                sum( case when  项目分期分类 is not NULL then isnull(cb.本年新增降本,0) else  0  end ) 
                / sum( case when  项目分期分类 is not NULL then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
        end as  [新增降本金额占比]
    FROM  #cb_CostStructureReport_qx_pz cb 
    where 公司guid IN ( SELECT  Value FROM  [dbo].[fn_Split2](@buguidList, ',') )
    GROUP BY 公司guid,公司名称

    end 

   -- 删除临时表
   drop table #cb_CostStructureReport_qx
   drop table #cb_CostStructureReport_qx_pz
   drop table #ProjectRecollect
   drop table #已竣备分期1
   drop table #本年计划竣备分期2
   drop table #本年新开工4
   drop table #在建分期3
   drop table #未开工5
   drop table #去年12月拍照动态成本不含非现金
   drop table #本年最早一个月拍照动态成本不含非现金
   drop table #本月动态成本拍照数据
   drop table #今年最近一次拍照动态成本不含非现金
   drop table #历史拍照动态成本不含非现金


end     