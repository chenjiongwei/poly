USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_cost_structure_color_board_LowerCostDetail]    Script Date: 2025/6/10 16:17:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--exec usp_cost_structure_color_board_LowerCostDetail '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8','2025-05-19'
-- 按项目显示本年新增降本明细
ALTER   proc [dbo].[usp_cost_structure_color_board_LowerCostDetail]
(
    @var_buguid varchar(max),
    @qxDate datetime 
)
as 
begin 
-- declare @var_buguid varchar(max) 
-- declare @qxDate datetime =getdate()

-- set   @var_buguid ='455FC380-B609-4A5A-9AAC-EE0F84C7F1B8' -- 安徽公司

     if @var_buguid is null or @var_buguid = '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23'
     begin
        select @var_buguid = STUFF(
        (
            SELECT distinct RTRIM(',' + CONVERT(VARCHAR(MAX), unit.buguid))
            FROM myBusinessUnit unit
            INNER JOIN p_project p ON unit.buguid = p.buguid
            WHERE IsEndCompany = 1 AND IsCompany = 1
            FOR XML PATH('')
        ), 1, 1, '' );
     end

      -- 剔除不统计项目 投管代码包括如下列表
     -- 创建临时表存储符合条件的项目信息
    select p.ProjGUID, p.ProjName, p.ProjCode
    into #projectFlag
    from p_Project p 
    where p.level = 2 and not exists (
        select 1 from erp25.dbo.vmdm_projectFlag flg
        where flg.ProjGUID = p.projguid and flg.投管代码 in ( 
            -- 以下是需要剔除的投管代码列表
            '5401', '5401', '5401', '5401', -- 重复代码
            '3912', '3901', '1319', '3114',
            '10001', '1822', '1818', '1817',
            '1813', '1838', '713', '711',
            '711', '707', '1823', '2924',
            '2924', '2932', '2928', '2928',
            '2928', '2941', '1330', '1327',
            '1328', '11502', '8609', '2802',
            '2802', '1990027', '1990011', '4801',
            '4801', '4801', '5106', '5102',
            '5102', '5101', '244', '5101',
            '5104', '5104', '5103', '5103',
            '515', '517', '429', '423',
            '423', '425', '425', '425',
            '424', '422', '1299', '1299',
            '2925', '2925', '2925', '2925',
            '2910', '2910', '2919', '1261',
            '2708', '2705', '2705', '2705',
            '9305', '2908', '2908', '2912',
            '2929', '12101', '8001', '2923',
            '41ZZ5', '413', '2937', '2958',
            '2958', '2922', '2922', '2922',
            '2940', '2935', '2934', '1417',
            '4217', '6206', '4209', '4209',
            '4209', '3131', '3115', '3130',
            '4910', '4910', '616', '6303',
            '2422', '2014', '4401', '9302',
            '1990029', '2306', '1128', '608',
            '3324', '4602', '4602', '4602',
            '4602', '4701', '4701', '4701',
            '4701', '4701', '4705', '1703',
            '1703', '1703', '1702', '9602',
            '9602', '6205', '6211', '6217',
            '4801', '4801', '9502', '2972',
            '4204', '2916', '2950', '2920',
            '2920', '2951', '2957', '2946',
            '4201', '5807', '5807', '5807',
            '5808', '4606', '4601', '4601',
            '4601', '4602', '4602', '616',
            '6401', '1702', '1702', '1702',
            '1702', '1704', '4802', '4802',
            '4004', '4004', '4004', '2956',
            '5801', '5801', '5805', '5805',
            '5805', '6001', '6001', '6002',
            '4902', '708', '708', '2004',
            '803', '802', '1816', 'lc1833',
            '1815', '4909', '4904', '4904',
            '4904', '4905', '4905', '4903',
            '4908', '4906', '4901', '4901',
            '1617', '1839', '713', '710',
            '710', '710', '2413', '1245',
            '2926', '2926', '2926', '2926',
            '2921', '2921', '2927', '2927',
            '9502', '9502', '2917', '5001',
            '4201', '4201', '4201', '4201',
            '1504', '511', '405', '5401',
            '412', '429', '1516', '3135',
            '3135', '3132', '3133', '1904',
            '5508', '5508', 'lc4014', '5812',
            '5806', '4604', '4702', '4702',
            '4702', '4703', '4703', '4701',
            '4701', '4701', '4701', '1266',
            '5103', '1611', '1622', '6603'
        )
    )
     
    -- 一级项目
    SELECT p.* 
    into #p_project
    FROM p_project p
    INNER JOIN #projectFlag pf ON p.ProjGUID = pf.ProjGUID
    WHERE p.level = 2
    UNION ALL
    -- 分期
    SELECT p2.* 
    FROM p_project p
    INNER JOIN #projectFlag pf ON p.ProjGUID = pf.ProjGUID
    LEFT JOIN p_project p2 ON p.ProjCode = p2.ParentCode AND p2.Level = 3
    WHERE p.level = 2

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
       FROM   #p_project p
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
       where  p.buguid in (  SELECT  Value FROM  [dbo].[fn_Split2](@var_buguid, ',') )

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
       WHERE DATEDIFF(DAY, 清洗日期, @qxDate) = 0 AND 公司GUID in ( SELECT  Value FROM  [dbo].[fn_Split2](@var_buguid, ',') )
       and  总成本情况_动态成本 is not null 
       and 项目guid in (select projguid from #p_project)

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
           AND b.type ='科目'
           and a.ProjectGUID in (select ProjGUID from #p_project)
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
           AND b.type ='科目'
           and a.ProjectGUID in (select ProjGUID from #p_project)
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
           AND b.type ='科目'
           and a.ProjectGUID in (select ProjGUID from #p_project)
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
           AND b.type ='科目'
           and a.ProjectGUID in (select ProjGUID from #p_project)
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
           AND b.type ='科目'
           and a.ProjectGUID in (select ProjGUID from #p_project)
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
        curfirst.DtCost_NotFxj AS 本年最早一个月拍照动态成本金额,
        curmonth.DtCost_NotFxj AS 本月拍照动态成本金额,
        ls.DtCost_NotFxj AS 历史拍照动态成本金额
    --  INTO #cb_CostStructureReport_qx_pz 
     FROM #cb_CostStructureReport_qx a
     LEFT JOIN #去年12月拍照动态成本不含非现金 qn12 ON a.项目guid = qn12.ProjectGUID
     LEFT JOIN #今年最近一次拍照动态成本不含非现金 cur ON a.项目guid = cur.ProjectGUID
     LEFT JOIN #历史拍照动态成本不含非现金 ls ON a.项目guid = ls.ProjectGUID
     LEFT JOIN #本月动态成本拍照数据 curmonth ON a.项目guid = curmonth.ProjectGUID
     LEFT JOIN #本年最早一个月拍照动态成本不含非现金 curfirst ON a.项目guid = curfirst.ProjectGUID

end 