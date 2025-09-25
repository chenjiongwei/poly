USE [MyCost_Erp352]
GO
/****** Object:  StoredProcedure [dbo].[usp_cost_structure_color_board]    Script Date: 2025/9/9 20:20:11 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
-- 成本结构分色图看板
-- 2025-04-27 chenjw
exec usp_cost_structure_color_board '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8','2025-05-13'
modify chenjw 2025-07-11
修订降本目标的金额计算逻辑，考虑历史项目数据为0或NULL的情况
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
     -- exec [172.16.4.129].[MyCost_Erp352].dbo.usp_cb_CostStructureReport_Clean @buguid,@qxDate

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
     
  -- 剔除不统计项目 投管代码包括如下列表
     -- 创建临时表存储符合条件的项目信息
    select 
        p.ParentProjGUID,
        p.ProjGUID,  -- 分期GUID
        p.ProjName, 
        p.ProjCode
    into #projectFlag
    from erp25.dbo.mdm_Project p 
    where 
        p.level = 3 
        and not exists (
            select 1 
            from erp25.dbo.mdm_project mp 
            where 
                p.projguid = mp.projguid 
                and mp.projcode  in (
                    '0931001-008', '0931001-010', '0931001-004', '0931001-011', '0311011-001', '0311001-005', '0571021-001', '0769010-001', '0710001-002', 
                    '0025028-001', '0025022-001', '0025024-001', '0025019-001', '0025047-001', '0731014-003', '0731013-003', '0731013-001', '0731007-002', 
                    '0025029-001', '0757032-02', '0757032-01', '0757041-001', '0757036-004', '0757036-003', '0757036-001', '0757049-001', '0571034-001', 
                    '0571031-001', '0571032-001', '0691002-005', '0512022-001', '0574002-002', '0574002-001', '0020134-001', '0020106-001', '0759002-001', 
                    '0759002-009', '0757023-001', '0758007-002', '0758003-001', '0758003-002', '0758001-002', '0010047-001', '0758001-001', '0758005-002', 
                    '0758005-001', '0758004-002', '0758004-003', '0023015-001', '0023017-004', '0027027-001', '0027023-002', '0027023-001', '0027025-01019', 
                    '0027025-01022', '0027025-001', '0027024-001', '0027022-001', '0028030-001', '0028030-002', '0757033-001', '0757033-004', '0757033-005', 
                    '0757033-003', '0757010-001', '0757010-005', '0757026-001', '0028065-001', '0756007-001', '0756005-002', '0756005-003', '0756005-001', 
                    '0871004-006', '0757008-002', '0757008-001', '0757012-001', '0757037-001', '0514001-001', '0511001-001', '0757031-001', '0371020-001', 
                    '0027014-003', '0757046-001', '0757070-002', '0757070-001', '0757030-002', '0757030-003', '0757030-001', '0757048-001', '0757043-01', 
                    '0757044-001', '0791013-009', '4602012-001', '0595006-001', '4602004-003', '4602004-002', '4602004-001', '0769031-001', '0769012-003', 
                    '0769029-002', '0351010-002', '0351010-001', '0024014-005', '0317003-001', '0591020-001', '0760014-001', '0028019-001', '0871002-002', 
                    '0020137-001', '0519007-001', '0431030-001', '0024008-002', '0411022-004', '0763001-009', '0763001-004', '0763001-003', '0763001-001', 
                    '0751002-001', '0751002-007', '0751002-002', '0751002-006', '0757022-001', '0751006-001', '0662004-002', '0662004-003', '0662004-001', 
                    '0662002-007', '0310002-002', '0310002-001', '0595005-001', '0595012-001', '0595017-001', '0759002-005', '0759002-002', '0378002-004', 
                    '0757086-001', '0898004-001', '0757018-001', '0757059-001', '0757028-002', '0757028-003', '0757060-004', '0757068-001', '0757056-001', 
                    '0898001-001', '0668007-005', '0668007-004', '0668007-001', '0668009-001', '0763007-002', '0763002-001', '0763002-002', '0757020-001', 
                    '0763001-007', '0763001-005', '0024014-004', '0736001-001', '0662002-004', '0662002-002', '0662002-003', '0662002-001', '0662005-001', 
                    '0759001-001', '0759001-002', '0029004-006', '0029004-008', '0029004-001', '0757069-001', '0668001-002', '0668001-001', '0668004-002', 
                    '0668004-004', '0668004-001', '0354001-002', '0354001-001', '0354002-001', '0351002-001', '0731009-002', '0731009-001', '0760004-001', 
                    '0730003-001', '0730002-003', '0025023-001', '0025039-001', '0025021-001', '0351008-001', '0351004-002', '0351004-003', '0351004-001', 
                    '0351005-002', '0351005-001', '0351003-001', '0351007-001', '0351006-001', '0351001-002', '0351001-001', '0532020-001', '0025045-001', 
                    '0731014-001', '0731011-003', '0731011-002', '0731011-001', '0591011-001', '0028062-001', '0757034-002', '0757034-003', '0757034-004', 
                    '0757034-001', '0757029-002', '0757029-001', '0757035-002', '0757035-001', '0378002-002', '0378002-003', '0757021-001', '4601001-001', 
                    '0898001-002', '0898001-004-2', '0898001-003', '0898001-005', '0022004-002', '0023011-003', '0027005-001', '0931001-003', '0027012-002', 
                    '0027027-002', '0022016-006', '0769034-002', '0769034-001', '0769030-001', '0769032-001', '0510005-001', '0752008-004', '0752008-005', 
                    '0029023-001', '0668010-001', '0668005-001', '0763005-001', '0751001-003', '0751001-002', '0751001-001', '0751004-002', '0751004-001', 
                    '0751002-004', '0751002-008', '0751002-005', '0751002-011', '0028070-001', '0758004-001', '0532014-001', '0532025-001', '0755003-001'
                )
        )
     
    -- 一级项目
    SELECT p.* 
    into #p_project
    FROM p_project p
    --INNER JOIN #projectFlag pf ON p.ProjGUID = pf.ParentProjGUID
    WHERE p.level = 2 and EXISTS (
        select   1 from  #projectFlag pf where p.ProjGUID = pf.ParentProjGUID
    )
    UNION ALL
    -- 分期
    SELECT p2.* 
    FROM p_project p
    -- INNER JOIN #projectFlag pf ON p.ProjGUID = pf.ProjGUID
    LEFT JOIN p_project p2 ON p.ProjCode = p2.ParentCode AND p2.Level = 3
    WHERE p.level = 2 and  EXISTS (
        select   1 from  #projectFlag pf where p2.ProjGUID = pf.ProjGUID
    )


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
       and  总成本情况_动态成本 is not null 
       and  项目GUID in (select ProjGUID from #p_project)
    
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
        -- CASE 
        --     WHEN qn12.DtCost_NotFxj IS NOT NULL AND cur.DtCost_NotFxj IS NOT NULL THEN ISNULL(qn12.DtCost_NotFxj, 0) - ISNULL(cur.DtCost_NotFxj, 0)
        --     -- 本年有数据，去年12月和历史均无数据
        --     WHEN qn12.DtCost_NotFxj IS NULL AND ls.DtCost_NotFxj IS NULL AND cur.DtCost_NotFxj IS NOT NULL THEN 
        --         CASE 
        --             WHEN curmonth.DtCost_NotFxj IS NOT NULL THEN 0 
        --             ELSE ISNULL(curfirst.DtCost_NotFxj, 0) - ISNULL(cur.DtCost_NotFxj, 0) 
        --         END
        --     -- 历史项目：本年有数据，去年12月无数据但历史数据数据
        --     WHEN cur.DtCost_NotFxj IS NOT NULL AND qn12.DtCost_NotFxj IS NULL AND ls.DtCost_NotFxj IS NOT NULL THEN ISNULL(ls.DtCost_NotFxj, 0) - ISNULL(cur.DtCost_NotFxj, 0)
        --     -- 历史老项目：本年无数据，历史有拍照数据
        --     WHEN cur.DtCost_NotFxj IS NULL AND ls.DtCost_NotFxj IS NOT NULL THEN 0
        -- END AS 本年新增降本,

        CASE 
            WHEN isnull(qn12.DtCost_NotFxj,0) <>0 AND isnull(cur.DtCost_NotFxj,0)<>0  THEN 
                  ISNULL(qn12.DtCost_NotFxj, 0) - ISNULL(cur.DtCost_NotFxj, 0)
            -- 本年有数据，去年12月和历史均无数据
            WHEN isnull(qn12.DtCost_NotFxj,0) =0  AND isnull(ls.DtCost_NotFxj,0) =0 AND isnull(cur.DtCost_NotFxj,0) <> 0 THEN 
                CASE 
                    -- 只有本月有数据 取0
                    WHEN isnull(curmonth.DtCost_NotFxj,0) <> 0 and isnull(curfirst.DtCost_NotFxj,0) =0 THEN 0 
                    when isnull(curmonth.DtCost_NotFxj,0) =0  and isnull(curfirst.DtCost_NotFxj,0) =0 then  0
                    ELSE ISNULL(curfirst.DtCost_NotFxj, 0) - ISNULL(cur.DtCost_NotFxj, 0) 
                END
            -- 历史项目：本年有数据，去年12月无数据但历史数据有数据
            WHEN isnull(cur.DtCost_NotFxj,0) <>0 AND isnull(qn12.DtCost_NotFxj,0)=0 AND isnull(ls.DtCost_NotFxj,0) <>0  
                 THEN ISNULL(ls.DtCost_NotFxj, 0) - ISNULL(cur.DtCost_NotFxj, 0)
            -- 历史老项目：本年无数据，历史有拍照数据
            WHEN isnull(cur.DtCost_NotFxj,0) =0  AND isnull(ls.DtCost_NotFxj,0) <>0 THEN 0
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
                else  sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [在建分期_除地价外直投不含非现金占比],
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
                
                
                -- 未开工未签约合约成本 = 未开工_动态成本
                sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [未开工_未签约_合约成本],
                -- round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 ,0) as [未签约_合约成本合计], 
                -- round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                --     else  sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end )  
                --     / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
                -- end,0)   [未签约_合约成本占动态成本比例],
                round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 + 
                    sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 ,0) as [未签约_合约成本合计], 
                round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                    else (
                        sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end )  + 
                        sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                    ) / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
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
               case  when  sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) =0  then 0 else    
                    sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 
                                isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                                +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                                + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end ) 
                    /  sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end AS [已竣备分期_结算完成率等于100%_预留金占比],
               case when  sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end )  =0 then 0 else  
                     sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then  
                        isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                        +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                        + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) 
                    /  sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [已竣备分期_结算完成率95%至100%_预留金占比],
               case when  sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) =0 then  0 else 
                     sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then 
                        isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                        +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                        + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else  0  end ) 
                    / sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [已竣备分期_结算完成率小于95%_预留金占比],
               case when  sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) =0 then 0 else  
                    sum( case when  项目分期分类 ='本年计划竣备分期' then 
                            isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                            +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                            + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else  0  end ) 
                   / sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [本年计划竣备分期_预留金占比],
               case when  sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0  then  0 else   
                      sum( case when  项目分期分类 ='在建分期' then 
                         isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                        +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                        + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else  0  end ) 
                   / sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [在建分期_预留金占比],
               case when  sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) =0 then 0 else 
                   sum( case when  项目分期分类 ='本年新开工' then 
                        isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                        +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                        + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else  0  end ) 
                   / sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [本年新开工_预留金占比],
                0 AS [未开工_预留金占比],

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
                        else  sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [在建分期_除地价外直投不含非现金占比],
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
                        -- 未开工未签约合约成本 = 未开工_动态成本
                        sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [未开工_未签约_合约成本],
                        -- round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 ,0) as [未签约_合约成本合计], 
                        -- round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                        --     else  sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end )  
                        --     / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
                        -- end,0)   [未签约_合约成本占动态成本比例],
                        round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 + 
                            sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 ,0) as [未签约_合约成本合计], 
                        round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
                            else (
                                sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end )  + 
                                sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
                            ) / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
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
                        case  when  sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) =0  then 0 else    
                                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 
                                            isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                                            +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                                            + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end ) 
                                /  sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end AS [已竣备分期_结算完成率等于100%_预留金占比],
                        case when  sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end )  =0 then 0 else  
                                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then  
                                    isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                                    +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                                    + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) 
                                /  sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [已竣备分期_结算完成率95%至100%_预留金占比],
                        case when  sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) =0 then  0 else 
                                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then 
                                    isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                                    +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                                    + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else  0  end ) 
                                / sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [已竣备分期_结算完成率小于95%_预留金占比],
                        case when  sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) =0 then 0 else  
                                sum( case when  项目分期分类 ='本年计划竣备分期' then 
                                        isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                                        +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                                        + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else  0  end ) 
                            / sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [本年计划竣备分期_预留金占比],
                        case when  sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0  then  0 else   
                                sum( case when  项目分期分类 ='在建分期' then 
                                    isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                                    +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                                    + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else  0  end ) 
                            / sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [在建分期_预留金占比],
                        case when  sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) =0 then 0 else 
                            sum( case when  项目分期分类 ='本年新开工' then 
                                    isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                                    +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                                    + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else  0  end ) 
                            / sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [本年新开工_预留金占比],
                            0 AS [未开工_预留金占比],

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
           else  sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end )  / sum(isnull(cb.总成本情况_动态成本,0)) end   AS [在建分期_除地价外直投不含非现金占比],
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
        
         -- 未开工未签约合约成本 = 未开工_动态成本
        sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 AS [未开工_未签约_合约成本],
        round(sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end ) /100000000.0 + 
           sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) /100000000.0 ,0) as [未签约_合约成本合计], 
        round( case when sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  )   =0  then  0 
            else (
                sum( case when  项目分期分类 <>'未开工' then isnull(cb.待签约_合约规划金额,0) else  0  end )  + 
                sum( case when  项目分期分类 ='未开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) 
            ) / sum( case when  项目分期分类 is not null  then  isnull(cb.总成本情况_动态成本,0) else 0 end  ) *100.0
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
        case  when  sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) =0  then 0 else    
                sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then 
                            isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                            +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                            + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else 0 end ) 
                /  sum( case when  项目分期分类 ='已竣备分期_结算完成率等于100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [已竣备分期_结算完成率等于100%_预留金占比],
        case when  sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end )  =0 then 0 else  
                sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then  
                    isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                    +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                    + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0) else  0  end ) 
                /  sum( case when  项目分期分类 ='已竣备分期_结算完成率95%至100%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [已竣备分期_结算完成率95%至100%_预留金占比],
        case when  sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) =0 then  0 else 
                sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then 
                    isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                    +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                    + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else  0  end ) 
                / sum( case when  项目分期分类 ='已竣备分期_结算完成率小于95%' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [已竣备分期_结算完成率小于95%_预留金占比],
        case when  sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) =0 then 0 else  
                sum( case when  项目分期分类 ='本年计划竣备分期' then 
                        isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                        +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                        + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else  0  end ) 
            / sum( case when  项目分期分类 ='本年计划竣备分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [本年计划竣备分期_预留金占比],
        case when  sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) = 0  then  0 else   
                sum( case when  项目分期分类 ='在建分期' then 
                    isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                    +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                    + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else  0  end ) 
            / sum( case when  项目分期分类 ='在建分期' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [在建分期_预留金占比],
        case when  sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) =0 then 0 else 
            sum( case when  项目分期分类 ='本年新开工' then 
                    isnull(cb.总价合同_首次签约为总价包干_预留金待发生,0) 
                    +isnull(cb.总价合同_首次签约为单价合同_目前已转总_预留金待发生,0) 
                    + isnull(cb.单价合同_首次签约为单价合同且未完成转总_预留金待发生,0)  else  0  end ) 
            / sum( case when  项目分期分类 ='本年新开工' then isnull(cb.总成本情况_动态成本,0) else  0  end ) end  AS [本年新开工_预留金占比],
            0 AS [未开工_预留金占比],

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
   drop table #p_project
   drop table #projectFlag


end     