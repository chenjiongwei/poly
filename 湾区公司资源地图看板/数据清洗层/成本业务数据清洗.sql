USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_ydkb_dthz_wq_deal_cbinfo]    Script Date: 2025/5/28 19:52:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
author:ltx  date:20220504
运行样例：[usp_ydkb_dthz_wq_deal_cbinfo]

modify:lintx date:20220608
1、增加地价（投管系统 - 获取总成本)

modify:lintx date:20221107
1、增加除地价外直投对应的本日发生金额，本月发生金额，本年发生金额，累计发生金额
对应的是昨天的数据，只统计项目及以上层级

modify:lintx date 20231120
1、增加三费的累计、本年、本月情况
modify:chenjw  date 20241017
1、增加已发生、待发生、已支付和合同性成本字段
2、增加成本降本目标、降本金额字段

modify:chenjw  date 20241022
1、增加总包、装修、园林、其他合约分类的变更签证情况

modify:lintx date 20241223
1、剔除动态成本为空的项目
2、动态三费调整为取最新盈利规划的分业态收益利润表
3、已实现、已支付、合同性的三费取dss系统
4、已实现和已签合同和已支付的地价取DSS数据里的土地款实付数据
5、总成本通过科目汇总

modify:lintx date 20250113
1、增加目标成本、动态成本、已发生成本、合同性成本、已支付成本、待发生成本对应的总成本、土地款、除地价外直投、营销费用、管理费用、财务费用不含税口径

modify:lintx date 20250429
1、增加目标成本、动态成本、已发生成本、合同性成本、已支付成本、待发生成本对应的开发前期费、建筑安装工程费、红线内配套费、政府收费、不可预见费含税及不含税口径

*/
--select * from  myBusinessUnit where  BUName ='湾区公司'
ALTER PROC [dbo].[usp_ydkb_dthz_wq_deal_cbinfo]
AS
BEGIN

     ---------------------参数设置------------------------
    DECLARE @bnYear VARCHAR(4);
    SET @bnYear = YEAR(GETDATE());
    DECLARE @byMonth VARCHAR(2);
    SET @byMonth = MONTH(GETDATE());
    DECLARE @buguid VARCHAR(max) = '248B1E17-AACB-E511-80B8-E41F13C51836,4975b69c-9953-4dd0-a65e-9a36db8c66df,4A1E877C-A0B2-476D-9F19-B5C426173C38,31120F08-22C4-4220-8ED2-DCAD398C823C';
    DECLARE @developmentguid VARCHAR(max) = 'C69E89BB-A2DB-E511-80B8-E41F13C51836,461889dc-e991-4238-9d7c-b29e0aa347bb,5A4B2DEF-E803-49F8-9FE2-308735E7233D,7DF92561-3B0D-E711-80BA-E61F13C57837';


    -----------------获取项目成本信息 begin---------------------------
    --预处理动态成本为空或为0的情况
    select pj.projguid
    into #p_exclude
    from MyCost_Erp352.dbo.cb_Cost cb
    INNER JOIN MyCost_Erp352.dbo.p_Project pj ON cb.ProjectCode = pj.ProjCode
    WHERE pj.Level = 2 AND cb.BUGUID IN ( SELECT value FROM fn_Split2(@buguid, ',') ) and cb.CostCode = '5001' 
    and ISNULL(cb.DtCost, 0) = 0
    group by pj.projguid

    --动态的三费要从盈利规划取，预缓存相关数据
    select 项目guid, 产品类型,
        sum(isnull(财务费用计划口径, 0)) as 财务费用,
        sum(isnull(营销费用, 0)) as 营销费用,
        sum(isnull(综合管理费协议口径, 0)) as 管理费用
    into #ylgh
    from [172.16.4.161].highdata_prod.[dbo].[dw_f_ProfitCost_byyt_ylgh]
    group by 项目guid, 产品类型

    --已支付、已实现、合同性的三费用dss系统取
    --收购项目
    SELECT ProjGUID,
        sum(累计土地款) as 累计土地款,
        SUM(本年已付除地价外直投) AS 本年已付除地价外直投,
        SUM(累计营销费支出) AS 累计营销费支出,
        SUM(累计管理费支出) AS 累计管理费支出,
        SUM(累计财务费支出) AS 累计财务费支出,
        SUM(本年营销费支出) AS 本年营销费支出,
        SUM(本年管理费支出) AS 本年管理费支出,
        SUM(本年财务费支出) AS 本年财务费支出,
        SUM(本月营销费支出) AS 本月营销费支出,
        SUM(本月管理费支出) AS 本月管理费支出,
        SUM(本月财务费支出) AS 本月财务费支出
    INTO #pro_cdjwzt
      FROM
      (
          SELECT pj.ProjGUID,
              isnull(sg.[项目-累计直接投资土地费用（万元）],0) as 累计土地款,
              ISNULL(sg.[项目-本年除地价外直投（万元）], 0) AS 本年已付除地价外直投,
              ISNULL(sg.[项目-累计营销费用（万元）], 0) AS 累计营销费支出,
              ISNULL(sg.[项目-累计管理费用（万元）], 0) AS 累计管理费支出,
              ISNULL(sg.[项目-累计财务费用（万元）], 0) AS 累计财务费支出,
              ISNULL(sg.[项目-本年营销费用（万元）], 0) AS 本年营销费支出,
              ISNULL(sg.[项目-本年管理费用（万元）], 0) AS 本年管理费支出,
              ISNULL(sg.[项目-本年财务费用（万元）], 0) AS 本年财务费支出,
              ISNULL(sg.[项目-本月营销费用（万元）], 0) AS 本月营销费支出,
              ISNULL(sg.[项目-本月管理费用（万元）], 0) AS 本月管理费支出,
              ISNULL(sg.[项目-本月财务费用（万元）], 0) AS 本月财务费支出
            FROM dss.dbo.[nmap_F_收购项目投资、结转、回笼、贷款情况表_2021] sg
           INNER JOIN MyCost_Erp352.dbo.p_Project pj
               ON sg.BusinessGUID = pj.ProjGUID
           INNER JOIN
                 (
                     SELECT t.BUGUID,
                         year,
                         t.month
                       FROM
                       (
                           SELECT ROW_NUMBER() OVER (PARTITION BY t.BUGUID ORDER BY t.year DESC, CONVERT(INT, t.month) DESC) AS num,
                               t.BUGUID,
                               t.year,
                               t.month
                             FROM
                             (
                                 SELECT pj.BUGUID,
                                     YEAR(sc.最后导入时间) AS year,
                                     MONTH(sc.最后导入时间) AS month
                                   FROM dss.dbo.[nmap_F_收购项目投资、结转、回笼、贷款情况表_2021] sc
                                  INNER JOIN MyCost_Erp352.dbo.p_Project pj
                                      ON pj.ProjGUID = sc.BusinessGUID
                                   GROUP BY pj.BUGUID,
                                     YEAR(sc.最后导入时间),
                                     MONTH(sc.最后导入时间)
                                   HAVING SUM(sc.[项目-累计总投资（万元）]) > 0
                             ) t
                       ) t
                       WHERE num = 1
                 ) t
               ON pj.BUGUID = t.BUGUID
                  AND YEAR(sg.最后导入时间) = t.year
                  AND t.month = MONTH(sg.最后导入时间)
            WHERE ISNULL(sg.[项目-本年除地价外直投（万元）], 0) <> 0
          UNION ALL
          --招拍挂
          SELECT pj.ProjGUID,
              isnull(sg.[项目-累计直接投资其中土地费用（万元）],0) as 累计土地款,
              ISNULL(sg.[项目-本年直接建安投资（万元）], 0) AS 本年已付除地价外直投,
              ISNULL(sg.[项目-累计营销费用（万元）], 0) AS 累计营销费支出,
              ISNULL(sg.[项目-累计管理费用（万元）], 0) AS 累计管理费支出,
              ISNULL(sg.[项目-累计财务费用（万元）], 0) AS 累计财务费支出,
              ISNULL(sg.[项目-本年营销费用（万元）], 0) AS 本年营销费支出,
              ISNULL(sg.[项目-本年管理费用（万元）], 0) AS 本年管理费支出,
              ISNULL(sg.[项目-本年财务费用（万元）], 0) AS 本年财务费支出,
              ISNULL(sg.[项目-本月营销费用（万元）], 0) AS 本月营销费支出,
              ISNULL(sg.[项目-本月管理费用（万元）], 0) AS 本月管理费支出,
              ISNULL(sg.[项目-本月财务费用（万元）], 0) AS 本月财务费支出
            FROM dss.dbo.[nmap_F_招拍挂项目投资、结转、回笼、贷款情况月报表_2021] sg
           INNER JOIN MyCost_Erp352.dbo.p_Project pj
               ON sg.BusinessGUID = pj.ProjGUID
           INNER JOIN
                 (
                     SELECT t.BUGUID,
                         year,
                         t.month
                       FROM
                       (
                           SELECT ROW_NUMBER() OVER (PARTITION BY t.BUGUID ORDER BY t.year DESC, CONVERT(INT, t.month) DESC) AS num,
                               t.BUGUID,
                               t.year,
                               t.month
                             FROM
                             (
                                 SELECT pj.BUGUID,
                                     YEAR(sc.最后导入时间) AS year,
                                     MONTH(sc.最后导入时间) AS month
                                   FROM dss.dbo.[nmap_F_招拍挂项目投资、结转、回笼、贷款情况月报表_2021] sc
                                  INNER JOIN MyCost_Erp352.dbo.p_Project pj
                                      ON pj.ProjGUID = sc.BusinessGUID
                                   GROUP BY pj.BUGUID,
                                     YEAR(sc.最后导入时间),
                                     MONTH(sc.最后导入时间)
                                   HAVING SUM(sc.[项目-累计总投资（万元）]) > 0
                             ) t
                       ) t
                       WHERE num = 1
                 ) t
               ON pj.BUGUID = t.BUGUID
                  AND YEAR(sg.最后导入时间) = t.year
                  AND t.month = MONTH(sg.最后导入时间)
      ) t
      GROUP BY projguid;

    SELECT pj.ProjGUID,
        -- 目标成本
        -- SUM(CASE WHEN cb.CostCode = '5001' THEN ISNULL(TargetCost, 0) ELSE 0 END) / 10000.0 AS 目标成本,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(TargetCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 目标成本直投,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(TargetCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 目标成本除地价外直投,
        SUM(CASE WHEN cb.CostCode IN ( '5001.02' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCost, 0) ELSE 0 END ) / 10000.0 AS 目标成本开发前期费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.03' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCost, 0) ELSE 0 END ) / 10000.0 AS 目标成本建筑安装工程费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.04' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCost, 0) ELSE 0 END ) / 10000.0 AS 目标成本红线内配套费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.05' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCost, 0) ELSE 0 END ) / 10000.0 AS 目标成本政府收费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.08' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCost, 0) ELSE 0 END ) / 10000.0 AS 目标成本不可预见费,

        SUM(CASE WHEN cb.CostCode IN ( '5001.09' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCost, 0) ELSE 0 END) / 10000.0 AS 目标成本营销费用,
        SUM(CASE WHEN cb.CostCode IN ( '5001.10' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCost, 0) ELSE 0 END) / 10000.0 AS 目标成本管理费用,
        SUM(CASE WHEN cb.CostCode IN ( '5001.11' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCost, 0) ELSE 0 END) / 10000.0 AS 目标成本财务费用,
        --不含税
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(TargetCostNoTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 目标成本直投不含税,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(TargetCostNoTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 目标成本除地价外直投不含税,

        SUM(CASE WHEN cb.CostCode IN ( '5001.02' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCostNoTax, 0) ELSE 0 END ) / 10000.0 AS 目标成本开发前期费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.03' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCostNoTax, 0) ELSE 0 END ) / 10000.0 AS 目标成本建筑安装工程费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.04' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCostNoTax, 0) ELSE 0 END ) / 10000.0 AS 目标成本红线内配套费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.05' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCostNoTax, 0) ELSE 0 END ) / 10000.0 AS 目标成本政府收费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.08' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCostNoTax, 0) ELSE 0 END ) / 10000.0 AS 目标成本不可预见费不含税,

        SUM(CASE WHEN cb.CostCode IN ( '5001.09' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCostNoTax, 0) ELSE 0 END) / 10000.0 AS 目标成本营销费用不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.10' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCostNoTax, 0) ELSE 0 END) / 10000.0 AS 目标成本管理费用不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.11' ) AND cb.CostLevel = 2 THEN ISNULL(TargetCostNoTax, 0) ELSE 0 END) / 10000.0 AS 目标成本财务费用不含税,

        -- 动态成本    
        -- SUM(CASE WHEN cb.CostCode = '5001' THEN ISNULL(cb.DtCost, 0) ELSE 0 END) / 10000.0 AS 动态成本,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(DtCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 动态成本直投,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(DtCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 动态成本除地价外直投,
        SUM(CASE WHEN cb.CostCode IN ( '5001.02' ) AND cb.CostLevel = 2 THEN ISNULL(DtCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本开发前期费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.03' ) AND cb.CostLevel = 2 THEN ISNULL(DtCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本建筑安装工程费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.04' ) AND cb.CostLevel = 2 THEN ISNULL(DtCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本红线内配套费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.05' ) AND cb.CostLevel = 2 THEN ISNULL(DtCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本政府收费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.08' ) AND cb.CostLevel = 2 THEN ISNULL(DtCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本不可预见费,

        isnull(ylgh.营销费用,0)/ 10000.0 as 动态成本营销费用,
        isnull(ylgh.管理费用,0)/ 10000.0 as 动态成本管理费用,
        isnull(ylgh.财务费用,0)/ 10000.0 as 动态成本财务费用,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(ExcludingTaxDtCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 动态成本直投不含税,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(ExcludingTaxDtCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 动态成本除地价外直投不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.02' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxDtCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本开发前期费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.03' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxDtCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本建筑安装工程费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.04' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxDtCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本红线内配套费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.05' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxDtCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本政府收费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.08' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxDtCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本不可预见费不含税,
        isnull(ylgh.营销费用,0)/ 10000.0 as 动态成本营销费用不含税,
        isnull(ylgh.管理费用,0)/ 10000.0 as 动态成本管理费用不含税,
        isnull(ylgh.财务费用,0)/ 10000.0 as 动态成本财务费用不含税,
        -- SUM(CASE WHEN cb.CostCode IN ( '5001.09' ) AND cb.CostLevel = 2 THEN ISNULL(DtCost, 0) ELSE 0 END) / 10000.0 AS 动态成本营销费用,
        -- SUM(CASE WHEN cb.CostCode IN ( '5001.10' ) AND cb.CostLevel = 2 THEN ISNULL(DtCost, 0) ELSE 0 END) / 10000.0 AS 动态成本管理费用,
        -- SUM(CASE WHEN cb.CostCode IN ( '5001.11' ) AND cb.CostLevel = 2 THEN ISNULL(DtCost, 0) ELSE 0 END) / 10000.0 AS 动态成本财务费用,
        -- 已发生成本
        -- SUM(CASE WHEN cb.CostCode = '5001' THEN ISNULL(YfsCost, 0) ELSE 0 END) / 10000.0 AS 已发生成本,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(YfsCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 已发生成本直投,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(YfsCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 已发生成本除地价外直投, 
        SUM(CASE WHEN cb.CostCode IN ( '5001.02' ) AND cb.CostLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本开发前期费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.03' ) AND cb.CostLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本建筑安装工程费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.04' ) AND cb.CostLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本红线内配套费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.05' ) AND cb.CostLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本政府收费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.08' ) AND cb.CostLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本不可预见费,
        isnull(dss.累计土地款,0) as 已发生成本土地款,
        isnull(dss.累计营销费支出,0) as 已发生成本营销费用,
        isnull(dss.累计管理费支出,0) as 已发生成本管理费用,
        isnull(dss.累计财务费支出,0) as 已发生成本财务费用,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(ExcludingTaxYfsCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 已发生成本直投不含税,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(ExcludingTaxYfsCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 已发生成本除地价外直投不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.02' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxYfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本开发前期费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.03' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxYfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本建筑安装工程费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.04' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxYfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本红线内配套费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.05' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxYfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本政府收费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.08' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxYfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本不可预见费不含税,

        isnull(dss.累计土地款,0) as 已发生成本土地款不含税,
        isnull(dss.累计营销费支出,0) as 已发生成本营销费用不含税,
        isnull(dss.累计管理费支出,0) as 已发生成本管理费用不含税,
        isnull(dss.累计财务费支出,0) as 已发生成本财务费用不含税,
        -- SUM(CASE WHEN cb.CostCode IN ( '5001.09' ) AND cb.CostLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END) / 10000.0 AS 已发生成本营销费用,
        -- SUM(CASE WHEN cb.CostCode IN ( '5001.10' ) AND cb.CostLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END) / 10000.0 AS 已发生成本管理费用,
        -- SUM(CASE WHEN cb.CostCode IN ( '5001.11' ) AND cb.CostLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END) / 10000.0 AS 已发生成本财务费用,
        -- 待发生成本
        -- SUM(CASE WHEN cb.CostCode = '5001' THEN ISNULL(DfsCost, 0) ELSE 0 END) / 10000.0 AS 待发生成本,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(DfsCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 待发生成本直投,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(DfsCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 待发生成本除地价外直投,
        SUM(CASE WHEN cb.CostCode IN ( '5001.02' ) AND cb.CostLevel = 2 THEN ISNULL(DfsCost, 0) ELSE 0 END ) / 10000.0 AS 待发生成本开发前期费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.03' ) AND cb.CostLevel = 2 THEN ISNULL(DfsCost, 0) ELSE 0 END ) / 10000.0 AS 待发生成本建筑安装工程费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.04' ) AND cb.CostLevel = 2 THEN ISNULL(DfsCost, 0) ELSE 0 END ) / 10000.0 AS 待发生成本红线内配套费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.05' ) AND cb.CostLevel = 2 THEN ISNULL(DfsCost, 0) ELSE 0 END ) / 10000.0 AS 待发生成本政府收费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.08' ) AND cb.CostLevel = 2 THEN ISNULL(DfsCost, 0) ELSE 0 END ) / 10000.0 AS 待发生成本不可预见费,

        SUM(CASE WHEN cb.CostCode IN ( '5001.09' ) AND cb.CostLevel = 2 THEN ISNULL(DfsCost, 0) ELSE 0 END) / 10000.0 AS 待发生成本营销费用,
        SUM(CASE WHEN cb.CostCode IN ( '5001.10' ) AND cb.CostLevel = 2 THEN ISNULL(DfsCost, 0) ELSE 0 END) / 10000.0 AS 待发生成本管理费用,
        SUM(CASE WHEN cb.CostCode IN ( '5001.11' ) AND cb.CostLevel = 2 THEN ISNULL(DfsCost, 0) ELSE 0 END) / 10000.0 AS 待发生成本财务费用,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(ExcludingTaxDfsCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 待发生成本直投不含税,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(ExcludingTaxDfsCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 待发生成本除地价外直投不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.02' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxDfsCost, 0) ELSE 0 END ) / 10000.0 AS 待发生成本开发前期费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.03' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxDfsCost, 0) ELSE 0 END ) / 10000.0 AS 待发生成本建筑安装工程费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.04' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxDfsCost, 0) ELSE 0 END ) / 10000.0 AS 待发生成本红线内配套费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.05' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxDfsCost, 0) ELSE 0 END ) / 10000.0 AS 待发生成本政府收费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.08' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxDfsCost, 0) ELSE 0 END ) / 10000.0 AS 待发生成本不可预见费不含税,

        SUM(CASE WHEN cb.CostCode IN ( '5001.09' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxDfsCost, 0) ELSE 0 END) / 10000.0 AS 待发生成本营销费用不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.10' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxDfsCost, 0) ELSE 0 END) / 10000.0 AS 待发生成本管理费用不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.11' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxDfsCost, 0) ELSE 0 END) / 10000.0 AS 待发生成本财务费用不含税,
        -- 已支付成本
        -- SUM(CASE WHEN cb.CostCode = '5001' THEN ISNULL(PayCost, 0) ELSE 0 END) / 10000.0 AS 已支付成本,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(PayCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 已支付成本直投,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(PayCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 已支付成本除地价外直投,
        SUM(CASE WHEN cb.CostCode IN ( '5001.02' ) AND cb.CostLevel = 2 THEN ISNULL(PayCost, 0) ELSE 0 END ) / 10000.0 AS 已支付成本开发前期费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.03' ) AND cb.CostLevel = 2 THEN ISNULL(PayCost, 0) ELSE 0 END ) / 10000.0 AS 已支付成本建筑安装工程费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.04' ) AND cb.CostLevel = 2 THEN ISNULL(PayCost, 0) ELSE 0 END ) / 10000.0 AS 已支付成本红线内配套费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.05' ) AND cb.CostLevel = 2 THEN ISNULL(PayCost, 0) ELSE 0 END ) / 10000.0 AS 已支付成本政府收费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.08' ) AND cb.CostLevel = 2 THEN ISNULL(PayCost, 0) ELSE 0 END ) / 10000.0 AS 已支付成本不可预见费,

        isnull(dss.累计土地款,0) as 已支付成本土地款,
        isnull(dss.累计营销费支出,0) as 已支付成本营销费用,
        isnull(dss.累计管理费支出,0) as 已支付成本管理费用,
        isnull(dss.累计财务费支出,0) as 已支付成本财务费用,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(ExcludingTaxPayCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 已支付成本直投不含税,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.CostLevel = 2 THEN
                       ISNULL(ExcludingTaxPayCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 已支付成本除地价外直投不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.02' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxPayCost, 0) ELSE 0 END ) / 10000.0 AS 已支付成本开发前期费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.03' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxPayCost, 0) ELSE 0 END ) / 10000.0 AS 已支付成本建筑安装工程费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.04' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxPayCost, 0) ELSE 0 END ) / 10000.0 AS 已支付成本红线内配套费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.05' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxPayCost, 0) ELSE 0 END ) / 10000.0 AS 已支付成本政府收费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.08' ) AND cb.CostLevel = 2 THEN ISNULL(ExcludingTaxPayCost, 0) ELSE 0 END ) / 10000.0 AS 已支付成本不可预见费不含税,
        isnull(dss.累计土地款,0) as 已支付成本土地款不含税,
        isnull(dss.累计营销费支出,0) as 已支付成本营销费用不含税,
        isnull(dss.累计管理费支出,0) as 已支付成本管理费用不含税,
        isnull(dss.累计财务费支出,0) as 已支付成本财务费用不含税,
        -- SUM(CASE WHEN cb.CostCode IN ( '5001.09' ) AND cb.CostLevel = 2 THEN ISNULL(PayCost, 0) ELSE 0 END) / 10000.0 AS 已支付成本营销费用,
        -- SUM(CASE WHEN cb.CostCode IN ( '5001.10' ) AND cb.CostLevel = 2 THEN ISNULL(PayCost, 0) ELSE 0 END) / 10000.0 AS 已支付成本管理费用,
        -- SUM(CASE WHEN cb.CostCode IN ( '5001.11' ) AND cb.CostLevel = 2 THEN ISNULL(PayCost, 0) ELSE 0 END) / 10000.0 AS 已支付成本财务费用,
        -- 合同性成本
        -- SUM(CASE WHEN cb.CostCode = '5001' THEN ISNULL(SumHtxCost, 0) ELSE 0 END) / 10000.0 AS 合同性成本,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.CostLevel = 2 THEN
                       (cb.WjsQyAmount + cb.YjsQyAmount + cb.FhtxCost)
                   ELSE
                       0
               END
           ) / 10000.0 AS 合同性成本直投,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.CostLevel = 2 THEN (cb.WjsQyAmount + cb.YjsQyAmount + cb.FhtxCost)
                   ELSE
                       0
               END
           ) / 10000.0 AS 合同性成本除地价外直投,
        SUM(CASE WHEN cb.CostCode IN ( '5001.02' ) AND cb.CostLevel = 2 THEN (cb.WjsQyAmount + cb.YjsQyAmount + cb.FhtxCost) ELSE 0 END ) / 10000.0 AS 合同性成本开发前期费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.03' ) AND cb.CostLevel = 2 THEN (cb.WjsQyAmount + cb.YjsQyAmount + cb.FhtxCost) ELSE 0 END ) / 10000.0 AS 合同性成本建筑安装工程费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.04' ) AND cb.CostLevel = 2 THEN (cb.WjsQyAmount + cb.YjsQyAmount + cb.FhtxCost) ELSE 0 END ) / 10000.0 AS 合同性成本红线内配套费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.05' ) AND cb.CostLevel = 2 THEN (cb.WjsQyAmount + cb.YjsQyAmount + cb.FhtxCost) ELSE 0 END ) / 10000.0 AS 合同性成本政府收费,
        SUM(CASE WHEN cb.CostCode IN ( '5001.08' ) AND cb.CostLevel = 2 THEN (cb.WjsQyAmount + cb.YjsQyAmount + cb.FhtxCost) ELSE 0 END ) / 10000.0 AS 合同性成本不可预见费,

        isnull(dss.累计土地款,0) as 合同性成本土地款,
        isnull(dss.累计营销费支出,0) as 合同性成本营销费用,
        isnull(dss.累计管理费支出,0) as 合同性成本管理费用,
        isnull(dss.累计财务费支出,0) as 合同性成本财务费用,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.CostLevel = 2 THEN
                       (cb.ExcludingTaxWjsQyAmount + cb.ExcludingTaxYjsQyAmount + cb.ExcludingTaxFhtxCost)
                   ELSE
                       0
               END
           ) / 10000.0 AS 合同性成本直投不含税,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.CostLevel = 2 THEN
                       (cb.ExcludingTaxWjsQyAmount + cb.ExcludingTaxYjsQyAmount + cb.ExcludingTaxFhtxCost)
                   ELSE
                       0
               END
           ) / 10000.0 AS 合同性成本除地价外直投不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.02' ) AND cb.CostLevel = 2 THEN (cb.ExcludingTaxWjsQyAmount + cb.ExcludingTaxYjsQyAmount + cb.ExcludingTaxFhtxCost) ELSE 0 END ) / 10000.0 AS 合同性成本开发前期费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.03' ) AND cb.CostLevel = 2 THEN (cb.ExcludingTaxWjsQyAmount + cb.ExcludingTaxYjsQyAmount + cb.ExcludingTaxFhtxCost) ELSE 0 END ) / 10000.0 AS 合同性成本建筑安装工程费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.04' ) AND cb.CostLevel = 2 THEN (cb.ExcludingTaxWjsQyAmount + cb.ExcludingTaxYjsQyAmount + cb.ExcludingTaxFhtxCost) ELSE 0 END ) / 10000.0 AS 合同性成本红线内配套费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.05' ) AND cb.CostLevel = 2 THEN (cb.ExcludingTaxWjsQyAmount + cb.ExcludingTaxYjsQyAmount + cb.ExcludingTaxFhtxCost) ELSE 0 END ) / 10000.0 AS 合同性成本政府收费不含税,
        SUM(CASE WHEN cb.CostCode IN ( '5001.08' ) AND cb.CostLevel = 2 THEN (cb.ExcludingTaxWjsQyAmount + cb.ExcludingTaxYjsQyAmount + cb.ExcludingTaxFhtxCost) ELSE 0 END ) / 10000.0 AS 合同性成本不可预见费不含税,

        isnull(dss.累计土地款,0) as 合同性成本土地款不含税,
        isnull(dss.累计营销费支出,0) as 合同性成本营销费用不含税,
        isnull(dss.累计管理费支出,0) as 合同性成本管理费用不含税,
        isnull(dss.累计财务费支出,0) as 合同性成本财务费用不含税
        -- SUM(CASE WHEN cb.CostCode IN ( '5001.09' ) AND cb.CostLevel = 2 THEN ISNULL(SumHtxCost, 0) ELSE 0 END) / 10000.0 AS 合同性成本营销费用,
        -- SUM(CASE WHEN cb.CostCode IN ( '5001.10' ) AND cb.CostLevel = 2 THEN ISNULL(SumHtxCost, 0) ELSE 0 END) / 10000.0 AS 合同性成本管理费用,
        -- SUM(CASE WHEN cb.CostCode IN ( '5001.11' ) AND cb.CostLevel = 2 THEN ISNULL(SumHtxCost, 0) ELSE 0 END) / 10000.0 AS 合同性成本财务费用
      INTO #proj_cb
      FROM MyCost_Erp352.dbo.cb_Cost cb
      INNER JOIN MyCost_Erp352.dbo.p_Project pj ON cb.ProjectCode = pj.ProjCode
      left join (select 项目guid,sum(财务费用) as 财务费用,sum(管理费用) as 管理费用, sum(营销费用) as 营销费用 
      from #ylgh group by 项目guid) ylgh on ylgh.项目guid = pj.projguid
      left join #pro_cdjwzt dss on dss.projguid =  pj.projguid
      left join #p_exclude p on pj.projguid = p.projguid
      WHERE pj.Level = 2 and p.projguid is null --动态成本为空或为0的情况不统计
            AND cb.BUGUID IN
                (
                    SELECT value FROM fn_Split2(@buguid, ',')
                )
      GROUP BY pj.ProjGUID,isnull(ylgh.财务费用,0),isnull(ylgh.管理费用,0),isnull(ylgh.营销费用,0),isnull(dss.累计营销费支出,0),
        isnull(dss.累计管理费支出,0) , isnull(dss.累计财务费支出,0),isnull(dss.累计土地款,0);

    --变更签证情况
    --统计合同对应的合约包名称存入临时表
   SELECT  DISTINCT 
                    c.BUGUID ,
                    cp.ProjGUID ,
                    c.ContractGUID,
				    case when  hyb.ContractName ='施工总承包工程' then  '施工总承包工程'  
					     when  hyb.ContractName ='园林绿化工程' then '园林绿化工程'
						 when  cost.CostCode like '%5001.03.01.04.01%' or cost.CostCode like '%5001.03.01.04.02%' then  '装修工程'
					end   ContractName --合约包名称
    INTO    #hyb
    FROM    MyCost_Erp352.dbo.cb_ProjHyb hyb
            INNER JOIN MyCost_Erp352.dbo.cb_httype ht ON hyb.buguid = ht.BUGUID AND  ht.HtTypeGUID = hyb.HtTypeGUID
            INNER JOIN MyCost_Erp352.dbo.cb_Contract c ON c.HtTypeCode = ht.HtTypeCode AND   c.BUGUID = ht.BUGUID
            INNER JOIN MyCost_Erp352.dbo.cb_ContractProj cp ON cp.ContractGUID = c.ContractGUID AND  cp.ProjGUID = hyb.ProjGUID
			inner join MyCost_Erp352.dbo.[cb_ProjHyb2Cost] hy2cost on hy2cost.projhybguid=hyb.projhybguid 
			inner join MyCost_Erp352.dbo.cb_cost cost on cost.buguid  =hyb.buguid and  cost.costguid =hy2cost.costguid
    WHERE   ( hyb.ContractName IN ('施工总承包工程','园林绿化工程')  or  cost.CostCode like '%5001.03.01.04.01%' or cost.CostCode like '%5001.03.01.04.02%') 
    --'公共部位精装修工程（毛坯）','公建配套精装修工程','其他精装修材料/设备','室内精装修工程','室内精装修设计','售楼处/样板间精装修工程', 
    AND  c.approvestate = '已审核' 
	AND  c.buguid in ( SELECT value FROM fn_Split2(@buguid, ',') )

   -- 查询变更明细情况存入临时表：只统计主合同的情况
   select  
        pp.ProjGUID as ParentProjGUID,
        p.ProjGUID ,
        p.projcode ,
        p.projname,
		c.ContractCode ,
        c.ContractGUID ,
        c.contractname ,
        c.HtTypeCode ,
        ht.htTypeName,
		c.HtAmount , --合同金额
        ROW_NUMBER() OVER ( PARTITION BY pp.ProjGUID,c.ContractGUID ORDER BY alt.AlterDate ASC ) AS num,
        ROW_NUMBER() OVER ( PARTITION BY pp.ProjGUID,c.ContractGUID,alt.HTAlterGUID ORDER BY alt.AlterDate ASC ) AS AltNum,  
		alt.HTAlterGUID,
        alt.AlterType , --变更类型：设计变更、现场签证
		alt.ApplyAmount , --申报金额
		alt.QrApproveState, --金额确认状态
        alt.AlterAmount ,
		alt.QrAlterAmount,
		case when isnull(alt.QrAlterAmount,0) = 0 then 
		(case when isnull(alt.AlterAmount,0) = 0 then alt.ApplyAmount else alt.AlterAmount end )
		else alt.QrAlterAmount end finalamount, --完工确认审核金额＞变更审核金额＞申报金额
		isnull(case when lib.BudgetName like '%装修%' and lib.BudgetName<>'其他精装修材料/设备'  then '装修工程'  else lib.BudgetName end,hyb.ContractName) as  hybName
    into  #HtAlter
    FROM  MyCost_Erp352.dbo.cb_contract c
        LEFT JOIN MyCost_Erp352.dbo.cb_httype ht ON c.HtTypeCode = ht.HtTypeCode AND c.buguid = ht.buguid
        INNER JOIN MyCost_Erp352.dbo.cb_ContractProj cp ON cp.ContractGUID = c.ContractGUID
        INNER JOIN MyCost_Erp352.dbo.p_Project p ON p.ProjGUID = cp.ProjGUID
        left  join MyCost_Erp352.dbo.p_Project pp on pp.projcode = p.ParentCode and  pp.Level=2 
        INNER JOIN MyCost_Erp352.dbo.cb_HtAlter alt ON alt.ContractGUID = c.ContractGUID
        LEFT JOIN MyCost_Erp352.dbo.cb_DesignAlter e ON alt.DesignAlterGuid = e.DesignAlterGuid
		LEFT JOIN MyCost_Erp352.dbo.cb_BudgetLibrary lib  ON c.BudgetLibraryGUID = lib.BudgetLibraryGUID
        -- 合同归属多个合约包选择其中一个进行归属
	    OUTER APPLY (
		   select top 1 *  from  #hyb where  #hyb.ProjGUID =cp.ProjGUID and  #hyb.ContractGUID =c.ContractGUID
		   order by ContractName
		) hyb 
     where  alt.ApproveState = '已审核' AND alt.AlterType IN ('设计变更', '现场签证')  AND c.approvestate = '已审核'
	 and c.MasterContractGUID is null --只统计主合同
	and c.buguid in ( SELECT value FROM fn_Split2(@buguid, ',') )


     select 
        a.ParentProjGUID as 项目GUID,
        sum(case when  num =1  then  isnull(a.HtAmount,0) else  0 end )  / 10000.0 
          + sum( case when AltNum = 1 then isnull(a.finalamount,0) else 0 end) / 10000.0  as 合同总金额,
        sum(case when AltNum = 1 then isnull(a.finalamount,0) else 0 end ) / 10000.0   as 变更总金额,
        sum(case when  num =1  then  isnull(a.HtAmount,0) else  0 end ) / 10000.0  as  合同金额,
        sum(case when AltNum = 1  and  a.AlterType='现场签证' then  isnull(a.finalamount,0) else  0 end  ) / 10000.0  as 现场签证累计发生金额,
        sum(case when AltNum = 1  and  a.AlterType='设计变更' then  isnull(a.finalamount,0) else  0 end  ) / 10000.0  as 设计变更累计发生金额,
        --总承包
        sum(case when  num =1 and  hybName ='施工总承包工程' then isnull(a.HtAmount,0) else  0 end ) / 10000.0
        + sum( case when  AltNum = 1  and hybName ='施工总承包工程' then isnull(a.finalamount,0) else  0 end  ) / 10000.0   as 总包合同总金额,
        sum( case when  AltNum = 1 and  hybName ='施工总承包工程' then isnull(a.finalamount,0) else  0 end  ) / 10000.0  as 总包变更总金额,
         sum(case when  num =1 and  hybName ='施工总承包工程' then isnull(a.HtAmount,0) else  0 end ) / 10000.0  as  总包合同金额,
        sum( case when  AltNum = 1 and a.AlterType='现场签证' and   hybName ='施工总承包工程'  then isnull(a.finalamount,0) else  0 end  ) / 10000.0  as  总包现场签证累计发生金额,
        sum( case when  AltNum = 1 and a.AlterType='设计变更' and   hybName ='施工总承包工程'  then isnull(a.finalamount,0) else  0 end  ) / 10000.0 as  总包设计变更累计发生金额,
        --装修
        sum(case when  num =1 and  hybName in ('装修工程' ) then isnull(a.HtAmount,0) else  0 end ) / 10000.0 
        + sum( case when  AltNum = 1 and    hybName in ('装修工程') then isnull(a.finalamount,0) else  0 end  )  / 10000.0   as 精装合同总金额,
        sum( case when  AltNum = 1 and  hybName in ('装修工程') then isnull(a.finalamount,0) else  0 end  )  / 10000.0  as 精装变更总金额,
        sum(case when  num =1 and  hybName in ('装修工程')  then isnull(a.HtAmount,0) else  0 end ) / 10000.0  as  精装合同金额,
        sum( case when  AltNum = 1 and  a.AlterType='现场签证' and hybName in ('装修工程')  then  isnull(a.finalamount,0) else  0 end)  / 10000.0  as  精装现场签证累计发生金额,
        sum( case when  AltNum = 1 and a.AlterType='设计变更' and   hybName in ('装修工程') then  isnull(a.finalamount,0) else  0 end  )  / 10000.0  as  精装设计变更累计发生金额,
        --园林
        sum(case when  num =1 and  hybName ='园林绿化工程' then isnull(a.HtAmount,0) else  0 end ) / 10000.0 
        + sum( case when  AltNum = 1 and  hybName ='园林绿化工程' then isnull(a.finalamount,0)  else  0 end  ) / 10000.0   as 园林合同总金额,
        sum( case when  AltNum = 1 and  hybName ='园林绿化工程' then isnull(a.finalamount,0)  else  0 end  ) / 10000.0  as 园林变更总金额,
         sum(case when  num =1 and  hybName ='园林绿化工程' then isnull(a.HtAmount,0) else  0 end ) / 10000.0  as  园林合同金额,
        sum( case when  AltNum = 1 and a.AlterType='现场签证' and   hybName ='园林绿化工程'  then  isnull(a.finalamount,0) else  0 end  )  / 10000.0 as  园林现场签证累计发生金额,
        sum( case when  AltNum = 1 and a.AlterType='设计变更' and   hybName ='园林绿化工程'  then  isnull(a.finalamount,0) else  0 end  )  / 10000.0 as  园林设计变更累计发生金额,
        --其他
        sum(case when  num =1 and isnull(hybName,'') not in ('施工总承包工程','装修工程','园林绿化工程')  then isnull(a.HtAmount,0) else  0 end ) / 10000.0 
        + sum( case when   AltNum = 1 and  isnull(hybName,'') not in ('施工总承包工程','装修工程','园林绿化工程') then isnull(a.finalamount,0) else  0 end  ) / 10000.0   as 其他合同总金额,
        sum( case when   AltNum = 1 and  isnull(hybName,'') not in ('施工总承包工程','装修工程','园林绿化工程') then isnull(a.finalamount,0) else  0 end  ) / 10000.0  as 其他变更总金额,
        sum(case when  num =1 and  isnull(hybName,'') not in ('施工总承包工程','装修工程','园林绿化工程')   then isnull(a.HtAmount,0) else  0 end )/ 10000.0 as  其他合同金额,
        sum( case when  AltNum = 1 and  a.AlterType='现场签证' and  isnull(hybName,'') not in ('施工总承包工程','装修工程','园林绿化工程') then  isnull(a.finalamount,0) else  0 end  ) / 10000.0  as  其他现场签证累计发生金额,
        sum( case when  AltNum = 1 and a.AlterType='设计变更' and  isnull(hybName,'') not in ('施工总承包工程','装修工程','园林绿化工程') then  isnull(a.finalamount,0) else  0 end  ) / 10000.0  as  其他设计变更累计发生金额
    into  #ProjHtAlter
    from #HtAlter a 
    group by  a.ParentProjGUID

 
   -- 湾区公司降本目标金额
   select 项目guid,
        isnull(降本任务填报,0) as  降本任务,
        isnull(除地价外直投降本任务填报,0)+isnull(地价降本任务填报,0) as  直投降本任务,
        isnull(除地价外直投降本任务填报,0) as 除地价外直投降本任务,
        isnull(营销费用降本任务填报,0) as 营销费用降本任务 ,
        isnull(管理费用降本任务填报,0) as 管理费用降本任务 ,
        isnull(财务费用降本任务填报,0) as 财务费用降本任务
   into #proj_cblowerRisk 
   from [172.16.4.161].[HighData_prod].dbo.data_tb_Wq_LowerCostTask
    

    --年初成本数据
    SELECT pj.ParentProjGUID,
        cb.projectguid,
        cb.RecollectGUID,
        ROW_NUMBER() OVER (PARTITION BY cb.projectguid ORDER BY cb.RecollectDate) num
    INTO #bb
    FROM MyCost_Erp352.dbo.cb_DTCostRecollect cb
     INNER JOIN mdm_project pj
         ON cb.projectguid = pj.projguid
    left join #p_exclude p on pj.ParentProjGUID = p.projguid
      WHERE
      (
          ApproveState = '已审核'
          OR CreateUserName = '系统管理员'
      )
      AND YEAR(RecollectDate) = YEAR(GETDATE()) and p.projguid is null ;

    SELECT bb.ParentProjGUID,
        -- SUM(CASE WHEN cb.CostCode = '5001' THEN ISNULL(TargetCost, 0) ELSE 0 END) / 10000.0 AS 年初目标成本,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.ParentCode = '5001' THEN
                       ISNULL(TargetCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 年初目标成本直投,
        SUM(   CASE
                   WHEN cb.CostCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.ParentCode = '5001' THEN
                       ISNULL(TargetCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 年初目标成本除地价外直投,
        SUM(   CASE
                   WHEN cb.CostCode IN ( '5001.09' )
                        AND cb.ParentCode = '5001' THEN
                       ISNULL(TargetCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 年初目标成本营销费用,
        SUM(   CASE
                   WHEN cb.CostCode IN ( '5001.10' )
                        AND cb.ParentCode = '5001' THEN
                       ISNULL(TargetCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 年初目标成本管理费用,
        SUM(   CASE
                   WHEN cb.CostCode IN ( '5001.11' )
                        AND cb.ParentCode = '5001' THEN
                       ISNULL(TargetCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 年初目标成本财务费用
    INTO #nc_cb
      FROM MyCost_Erp352.dbo.cb_DtCostRecollectDetails cb
     INNER JOIN #bb bb
         ON cb.RecollectGUID = bb.RecollectGUID
            AND bb.num = 1
      GROUP BY bb.ParentProjGUID;
 

    --获取项目地价
    SELECT ProjGUID,
        TotalLandPrice / 10000.0 AS 地价
    INTO #dj
      FROM dbo.mdm_Project
      WHERE Level = 2
            AND DevelopmentCompanyGUID IN
                (
                    SELECT Value FROM dbo.fn_Split2(@developmentguid, ',')
                );

    --获取除地价外直投的付款申请审核数据
    --预处理多分期的合同付款情况，按照项目个数将金额均分
    SELECT ContractGUID,
        HtTypeCode,
        LEN(ProjName) - LEN(REPLACE(ProjName, ';', '')) + 1 AS 项目个数,
        t.value AS projcode
    INTO #cb_cdjwzt
      FROM MyCost_Erp352.dbo.vcb_Contract cb
     OUTER APPLY (SELECT value FROM fn_Split2(cb.projcode, ';') ) t
      WHERE BUGUID IN
            (
                SELECT value FROM fn_Split2(@buguid, ',')
            );


    SELECT pj.ProjGUID,
        SUM(   CASE
                   WHEN DATEDIFF(dd, GETDATE() - 1, c.FinishDatetime) = 0
                        AND ISNULL(b.项目个数, 0) <> 0 THEN
                       fk.ApplyAmount / b.项目个数
                   ELSE
                       0
               END
           ) / 10000.0 除地价外直投本日发生金额,
        SUM(   CASE
                   WHEN DATEDIFF(mm, GETDATE() - 1, c.FinishDatetime) = 0
                        AND ISNULL(b.项目个数, 0) <> 0 THEN
                       fk.ApplyAmount / b.项目个数
                   ELSE
                       0
               END
           ) / 10000.0 除地价外直投本月发生金额,
        SUM(   CASE
                   WHEN DATEDIFF(yy, GETDATE() - 1, c.FinishDatetime) = 0
                        AND ISNULL(b.项目个数, 0) <> 0 THEN
                       fk.ApplyAmount / b.项目个数
                   ELSE
                       0
               END
           ) / 10000.0 除地价外直投本年发生金额,
        SUM(CASE WHEN ISNULL(b.项目个数, 0) <> 0 THEN fk.ApplyAmount / b.项目个数 ELSE 0 END) / 10000.0 除地价外直投累计发生金额
    INTO #cdjwzt
      FROM MyCost_Erp352.dbo.cb_HTFKApply fk
      LEFT JOIN #cb_cdjwzt b
          ON fk.ContractGUID = b.ContractGUID
      LEFT JOIN MyCost_Erp352.dbo.myWorkflowProcessEntity c
          ON fk.HTFKApplyGUID = c.BusinessGUID
     INNER JOIN MyCost_Erp352.dbo.p_project p
         ON b.projcode = p.ProjCode
     INNER JOIN MyCost_Erp352.dbo.p_project pj
         ON pj.projcode = p.ParentCode
      WHERE fk.ApplyState = '已审核'
            AND c.ProcessStatus = '2'
            --去掉土地款、营销费、管理费、财务费
            AND b.HtTypeCode NOT LIKE '01%'
            AND b.HtTypeCode NOT LIKE '07%'
            AND b.HtTypeCode NOT LIKE '08%'
            AND b.HtTypeCode NOT LIKE '09%'
            AND fk.BUGUID IN
                (
                    SELECT value FROM fn_Split2(@buguid, ',')
                )
      GROUP BY pj.ProjGUID;


    -----------------获取项目成本信息 end---------------------------

    -----------------获取业态成本信息 begin---------------------------
    SELECT *
    INTO #yt
      FROM
      (
          SELECT p.ProjGUID,
              mp.VersionGUID,
              YtCode,
              mp.ProductType,
              ROW_NUMBER() OVER (PARTITION BY p.ProjGUID, mp.VersionGUID, mp.YtCode ORDER BY mp.ProductType) AS num
            FROM MyCost_Erp352.dbo.md_Product mp
           INNER JOIN MyCost_Erp352.dbo.md_Project p
               ON p.IsActive = 1
                  AND mp.ProjGUID = p.ProjGUID
                  AND mp.VersionGUID = p.VersionGUID
            WHERE YtCode IS NOT NULL
                  AND p.DevelopmentCompanyGUID IN
                      (
                          SELECT Value FROM dbo.fn_Split2(@developmentguid, ',')
                      )
      ) t
      WHERE num = 1;

    SELECT par.ProjGUID,
        pr.ProductType,
        -- 目标成本
        -- SUM(CASE WHEN cb.AccountCode = '5001' THEN ISNULL(TargetCost, 0) ELSE 0 END) / 10000.0 AS 目标成本,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(TargetCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 目标成本直投,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(TargetCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 目标成本除地价外直投,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.02' ) AND cb.AccountLevel = 2 THEN ISNULL(TargetCost, 0) ELSE 0 END ) / 10000.0 AS 目标成本开发前期费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.03' ) AND cb.AccountLevel = 2 THEN ISNULL(TargetCost, 0) ELSE 0 END ) / 10000.0 AS 目标成本建筑安装工程费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.04' ) AND cb.AccountLevel = 2 THEN ISNULL(TargetCost, 0) ELSE 0 END ) / 10000.0 AS 目标成本红线内配套费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.05' ) AND cb.AccountLevel = 2 THEN ISNULL(TargetCost, 0) ELSE 0 END ) / 10000.0 AS 目标成本政府收费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.08' ) AND cb.AccountLevel = 2 THEN ISNULL(TargetCost, 0) ELSE 0 END ) / 10000.0 AS 目标成本不可预见费,
        SUM(   CASE
                   WHEN cb.AccountCode IN ( '5001.09' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(TargetCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 目标成本营销费用,
        SUM(   CASE
                   WHEN cb.AccountCode IN ( '5001.10' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(TargetCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 目标成本管理费用,
        SUM(   CASE
                   WHEN cb.AccountCode IN ( '5001.11' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(TargetCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 目标成本财务费用,
        --不含税
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(TargetCostNonTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 目标成本直投不含税,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(TargetCostNonTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 目标成本除地价外直投不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.02' ) AND cb.AccountLevel = 2 THEN ISNULL(TargetCostNonTax, 0) ELSE 0 END ) / 10000.0 AS 目标成本开发前期费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.03' ) AND cb.AccountLevel = 2 THEN ISNULL(TargetCostNonTax, 0) ELSE 0 END ) / 10000.0 AS 目标成本建筑安装工程费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.04' ) AND cb.AccountLevel = 2 THEN ISNULL(TargetCostNonTax, 0) ELSE 0 END ) / 10000.0 AS 目标成本红线内配套费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.05' ) AND cb.AccountLevel = 2 THEN ISNULL(TargetCostNonTax, 0) ELSE 0 END ) / 10000.0 AS 目标成本政府收费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.08' ) AND cb.AccountLevel = 2 THEN ISNULL(TargetCostNonTax, 0) ELSE 0 END ) / 10000.0 AS 目标成本不可预见费不含税,
        SUM(   CASE
                   WHEN cb.AccountCode IN ( '5001.09' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(TargetCostNonTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 目标成本营销费用不含税,
        SUM(   CASE
                   WHEN cb.AccountCode IN ( '5001.10' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(TargetCostNonTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 目标成本管理费用不含税,
        SUM(   CASE
                   WHEN cb.AccountCode IN ( '5001.11' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(TargetCostNonTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 目标成本财务费用不含税, 
        -- 动态成本   
        -- SUM(CASE WHEN cb.AccountCode = '5001' THEN ISNULL(cb.DynamicCost, 0) ELSE 0 END) / 10000.0 AS 动态成本,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(DynamicCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 动态成本直投,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(DynamicCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 动态成本除地价外直投, 
        SUM(CASE WHEN cb.AccountCode IN ( '5001.02' ) AND cb.AccountLevel = 2 THEN ISNULL(DynamicCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本开发前期费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.03' ) AND cb.AccountLevel = 2 THEN ISNULL(DynamicCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本建筑安装工程费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.04' ) AND cb.AccountLevel = 2 THEN ISNULL(DynamicCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本红线内配套费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.05' ) AND cb.AccountLevel = 2 THEN ISNULL(DynamicCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本政府收费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.08' ) AND cb.AccountLevel = 2 THEN ISNULL(DynamicCost, 0) ELSE 0 END ) / 10000.0 AS 动态成本不可预见费,
        isnull(ylgh.营销费用,0)/ 10000.0 as 动态成本营销费用,
        isnull(ylgh.管理费用,0)/ 10000.0 as 动态成本管理费用,
        isnull(ylgh.财务费用,0)/ 10000.0 as 动态成本财务费用,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(DynamicCostNonTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 动态成本直投不含税,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(DynamicCostNonTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 动态成本除地价外直投不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.02' ) AND cb.AccountLevel = 2 THEN ISNULL(DynamicCostNonTax, 0) ELSE 0 END ) / 10000.0 AS 动态成本开发前期费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.03' ) AND cb.AccountLevel = 2 THEN ISNULL(DynamicCostNonTax, 0) ELSE 0 END ) / 10000.0 AS 动态成本建筑安装工程费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.04' ) AND cb.AccountLevel = 2 THEN ISNULL(DynamicCostNonTax, 0) ELSE 0 END ) / 10000.0 AS 动态成本红线内配套费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.05' ) AND cb.AccountLevel = 2 THEN ISNULL(DynamicCostNonTax, 0) ELSE 0 END ) / 10000.0 AS 动态成本政府收费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.08' ) AND cb.AccountLevel = 2 THEN ISNULL(DynamicCostNonTax, 0) ELSE 0 END ) / 10000.0 AS 动态成本不可预见费不含税,
        isnull(ylgh.营销费用,0)/ 10000.0 as 动态成本营销费用不含税,
        isnull(ylgh.管理费用,0)/ 10000.0 as 动态成本管理费用不含税,
        isnull(ylgh.财务费用,0)/ 10000.0 as 动态成本财务费用不含税,
        -- SUM(   CASE
        --            WHEN cb.AccountCode IN ( '5001.09' )
        --                 AND cb.AccountLevel = 2 THEN
        --                ISNULL(DynamicCost, 0)
        --            ELSE
        --                0
        --        END
        --    ) / 10000.0 AS 动态成本营销费用,
        -- SUM(   CASE
        --            WHEN cb.AccountCode IN ( '5001.10' )
        --                 AND cb.AccountLevel = 2 THEN
        --                ISNULL(DynamicCost, 0)
        --            ELSE
        --                0
        --        END
        --    ) / 10000.0 AS 动态成本管理费用,
        -- SUM(   CASE
        --            WHEN cb.AccountCode IN ( '5001.11' )
        --                 AND cb.AccountLevel = 2 THEN
        --                ISNULL(DynamicCost, 0)
        --            ELSE
        --                0
        --        END
        --    ) / 10000.0 AS 动态成本财务费用,
        -- 已发生成本
        -- SUM(CASE WHEN cb.AccountCode = '5001' THEN ISNULL(cb.YfsCost, 0) ELSE 0 END) / 10000.0 AS 已发生成本,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(YfsCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 已发生成本直投,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(YfsCost, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 已发生成本除地价外直投, 
        SUM(CASE WHEN cb.AccountCode IN ( '5001.02' ) AND cb.AccountLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本开发前期费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.03' ) AND cb.AccountLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本建筑安装工程费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.04' ) AND cb.AccountLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本红线内配套费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.05' ) AND cb.AccountLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本政府收费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.08' ) AND cb.AccountLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END ) / 10000.0 AS 已发生成本不可预见费,

        convert(money,0.0) as 已发生成本土地款,
        convert(money,0.0) AS 已发生成本营销费用,
        convert(money,0.0) AS 已发生成本管理费用,
        convert(money,0.0) AS 已发生成本财务费用,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(YfsCostNoTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 已发生成本直投不含税,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(YfsCostNoTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 已发生成本除地价外直投不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.02' ) AND cb.AccountLevel = 2 THEN ISNULL(YfsCostNoTax, 0) ELSE 0 END ) / 10000.0 AS 已发生成本开发前期费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.03' ) AND cb.AccountLevel = 2 THEN ISNULL(YfsCostNoTax, 0) ELSE 0 END ) / 10000.0 AS 已发生成本建筑安装工程费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.04' ) AND cb.AccountLevel = 2 THEN ISNULL(YfsCostNoTax, 0) ELSE 0 END ) / 10000.0 AS 已发生成本红线内配套费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.05' ) AND cb.AccountLevel = 2 THEN ISNULL(YfsCostNoTax, 0) ELSE 0 END ) / 10000.0 AS 已发生成本政府收费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.08' ) AND cb.AccountLevel = 2 THEN ISNULL(YfsCostNoTax, 0) ELSE 0 END ) / 10000.0 AS 已发生成本不可预见费不含税,
        convert(money,0.0) as 已发生成本土地款不含税,
        convert(money,0.0) AS 已发生成本营销费用不含税,
        convert(money,0.0) AS 已发生成本管理费用不含税,
        convert(money,0.0) AS 已发生成本财务费用不含税,
        -- SUM(CASE WHEN cb.AccountCode IN ( '5001.09' ) AND cb.AccountLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END) / 10000.0 AS 已发生成本营销费用,
        -- SUM(CASE WHEN cb.AccountCode IN ( '5001.10' ) AND cb.AccountLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END) / 10000.0 AS 已发生成本管理费用,
        -- SUM(CASE WHEN cb.AccountCode IN ( '5001.11' ) AND cb.AccountLevel = 2 THEN ISNULL(YfsCost, 0) ELSE 0 END) / 10000.0 AS 已发生成本财务费用,
                       -- 待发生成本
        -- SUM(CASE WHEN cb.AccountCode = '5001' THEN ISNULL(cb.ContractPlanningOccur, 0) ELSE 0 END) / 10000.0 AS 待发生成本,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(ContractPlanningOccur, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 待发生成本直投,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(ContractPlanningOccur, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 待发生成本除地价外直投,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.02' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractPlanningOccur, 0) ELSE 0 END ) / 10000.0 AS 待发生成本开发前期费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.03' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractPlanningOccur, 0) ELSE 0 END ) / 10000.0 AS 待发生成本建筑安装工程费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.04' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractPlanningOccur, 0) ELSE 0 END ) / 10000.0 AS 待发生成本红线内配套费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.05' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractPlanningOccur, 0) ELSE 0 END ) / 10000.0 AS 待发生成本政府收费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.08' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractPlanningOccur, 0) ELSE 0 END ) / 10000.0 AS 待发生成本不可预见费,

        SUM(   CASE
                   WHEN cb.AccountCode IN ( '5001.09' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(ContractPlanningOccur, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 待发生成本营销费用,
        SUM(   CASE
                   WHEN cb.AccountCode IN ( '5001.10' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(ContractPlanningOccur, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 待发生成本管理费用,
        SUM(   CASE
                   WHEN cb.AccountCode IN ( '5001.11' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(ContractPlanningOccur, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 待发生成本财务费用,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(ContractPlanningOccurNonTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 待发生成本直投不含税, 
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(ContractPlanningOccurNonTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 待发生成本除地价外直投不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.02' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractPlanningOccurNonTax, 0) ELSE 0 END ) / 10000.0 AS 待发生成本开发前期费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.03' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractPlanningOccurNonTax, 0) ELSE 0 END ) / 10000.0 AS 待发生成本建筑安装工程费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.04' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractPlanningOccurNonTax, 0) ELSE 0 END ) / 10000.0 AS 待发生成本红线内配套费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.05' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractPlanningOccurNonTax, 0) ELSE 0 END ) / 10000.0 AS 待发生成本政府收费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.08' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractPlanningOccurNonTax, 0) ELSE 0 END ) / 10000.0 AS 待发生成本不可预见费不含税,
        SUM(   CASE
                   WHEN cb.AccountCode IN ( '5001.09' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(ContractPlanningOccurNonTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 待发生成本营销费用不含税,
        SUM(   CASE
                   WHEN cb.AccountCode IN ( '5001.10' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(ContractPlanningOccurNonTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 待发生成本管理费用不含税,
        SUM(   CASE
                   WHEN cb.AccountCode IN ( '5001.11' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(ContractPlanningOccurNonTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 待发生成本财务费用不含税,
        -- 已支付成本
        -- convert(money,0.0) AS 已支付成本, -- 暂不实现
        convert(money,0.0) AS 已支付成本直投,
        convert(money,0.0) AS 已支付成本除地价外直投, 
        convert(money,0.0) AS 已支付成本开发前期费,
        convert(money,0.0) AS 已支付成本建筑安装工程费,
        convert(money,0.0) AS 已支付成本红线内配套费,
        convert(money,0.0) AS 已支付成本政府收费,
        convert(money,0.0) AS 已支付成本不可预见费,

        convert(money,0.0) AS 已支付成本土地款,
        convert(money,0.0) AS 已支付成本营销费用,
        convert(money,0.0) AS 已支付成本管理费用,
        convert(money,0.0) AS 已支付成本财务费用,
        convert(money,0.0) AS 已支付成本直投不含税,
        convert(money,0.0) AS 已支付成本除地价外直投不含税,
        convert(money,0.0) AS 已支付成本开发前期费不含税,
        convert(money,0.0) AS 已支付成本建筑安装工程费不含税,
        convert(money,0.0) AS 已支付成本红线内配套费不含税,
        convert(money,0.0) AS 已支付成本政府收费不含税,
        convert(money,0.0) AS 已支付成本不可预见费不含税,
        convert(money,0.0) AS 已支付成本土地款不含税,
        convert(money,0.0) AS 已支付成本营销费用不含税,
        convert(money,0.0) AS 已支付成本管理费用不含税,
        convert(money,0.0) AS 已支付成本财务费用不含税,
        -- 合同性成本
        -- SUM(CASE WHEN cb.AccountCode = '5001' THEN ISNULL(cb.ContractAmount, 0) ELSE 0 END) / 10000.0 AS 合同性成本,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(ContractAmount, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 合同性成本直投,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(ContractAmount, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 合同性成本除地价外直投,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.02' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractAmount, 0) ELSE 0 END ) / 10000.0 AS 合同性成本开发前期费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.03' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractAmount, 0) ELSE 0 END ) / 10000.0 AS 合同性成本建筑安装工程费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.04' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractAmount, 0) ELSE 0 END ) / 10000.0 AS 合同性成本红线内配套费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.05' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractAmount, 0) ELSE 0 END ) / 10000.0 AS 合同性成本政府收费,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.08' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractAmount, 0) ELSE 0 END ) / 10000.0 AS 合同性成本不可预见费,
        convert(money,0.0) as 合同性成本土地款,
        convert(money,0.0) as 合同性成本营销费用,
        convert(money,0.0) as 合同性成本管理费用,
        convert(money,0.0) as 合同性成本财务费用,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(ContractAmountNonTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 合同性成本直投不含税,
        SUM(   CASE
                   WHEN cb.AccountCode NOT IN ( '5001.09', '5001.10', '5001.11', '5001.01' )
                        AND cb.AccountLevel = 2 THEN
                       ISNULL(ContractAmountNonTax, 0)
                   ELSE
                       0
               END
           ) / 10000.0 AS 合同性成本除地价外直投不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.02' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractAmountNonTax, 0) ELSE 0 END ) / 10000.0 AS 合同性成本开发前期费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.03' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractAmountNonTax, 0) ELSE 0 END ) / 10000.0 AS 合同性成本建筑安装工程费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.04' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractAmountNonTax, 0) ELSE 0 END ) / 10000.0 AS 合同性成本红线内配套费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.05' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractAmountNonTax, 0) ELSE 0 END ) / 10000.0 AS 合同性成本政府收费不含税,
        SUM(CASE WHEN cb.AccountCode IN ( '5001.08' ) AND cb.AccountLevel = 2 THEN ISNULL(ContractAmountNonTax, 0) ELSE 0 END ) / 10000.0 AS 合同性成本不可预见费不含税,
        convert(money,0.0) as 合同性成本土地款不含税,
        convert(money,0.0) as 合同性成本营销费用不含税,
        convert(money,0.0) as 合同性成本管理费用不含税,
        convert(money,0.0) as 合同性成本财务费用不含税
        -- SUM(   CASE
        --            WHEN cb.AccountCode IN ( '5001.09' )
        --                 AND cb.AccountLevel = 2 THEN
        --                ISNULL(ContractAmount, 0)
        --            ELSE
        --                0
        --        END
        --    ) / 10000.0 AS 合同性成本营销费用,
        -- SUM(   CASE
        --            WHEN cb.AccountCode IN ( '5001.10' )
        --                 AND cb.AccountLevel = 2 THEN
        --                ISNULL(ContractAmount, 0)
        --            ELSE
        --                0
        --        END
        --    ) / 10000.0 AS 合同性成本管理费用,
        -- SUM(   CASE
        --            WHEN cb.AccountCode IN ( '5001.11' )
        --                 AND cb.AccountLevel = 2 THEN
        --                ISNULL(ContractAmount, 0)
        --            ELSE
        --                0
        --        END
        --    ) / 10000.0 AS 合同性成本财务费用
    INTO #yt_cb
      FROM MyCost_Erp352.dbo.cb_CostAccount cb
     INNER JOIN MyCost_Erp352.dbo.p_Project pj
         ON cb.ProjCode = pj.ProjCode
     INNER JOIN #yt pr
         ON pr.ProjGUID = cb.ProjGUID
            AND pr.YtCode = cb.YtCode
     INNER JOIN MyCost_Erp352.dbo.p_Project par
         ON par.ProjCode = pj.ParentCode
      left join #ylgh ylgh on par.projguid = ylgh.项目guid and pr.ProductType = ylgh.产品类型
      GROUP BY par.ProjGUID, pr.ProductType,isnull(ylgh.营销费用,0), isnull(ylgh.管理费用,0), isnull(ylgh.财务费用,0);


    -----------------获取业态成本信息 end--------------------------- 
    IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = OBJECT_ID(N'ydkb_dthz_wq_deal_cbinfo') AND OBJECTPROPERTY(id, 'IsTable') = 1)
    BEGIN
        DROP TABLE ydkb_dthz_wq_deal_cbinfo;
    END;

    --湾区PC端货量报表 
    CREATE TABLE ydkb_dthz_wq_deal_cbinfo
    (   组织架构父级ID UNIQUEIDENTIFIER,
        组织架构ID UNIQUEIDENTIFIER,
        组织架构名称 VARCHAR(400),
        组织架构编码 [VARCHAR](100),
        组织架构类型 [INT],
        目标成本 MONEY,
        目标成本直投 MONEY,
        目标成本除地价外直投 MONEY,
        目标成本开发前期费 MONEY,
        目标成本建筑安装工程费 MONEY,
        目标成本红线内配套费 MONEY,
        目标成本政府收费 MONEY,
        目标成本不可预见费 MONEY,
        目标成本营销费用 MONEY,
        目标成本管理费用 MONEY,
        目标成本财务费用 MONEY,
        --不含税
        目标成本不含税 MONEY,
        目标成本直投不含税 MONEY,
        目标成本除地价外直投不含税 MONEY,
        目标成本开发前期费不含税 MONEY,
        目标成本建筑安装工程费不含税 MONEY,
        目标成本红线内配套费不含税 MONEY,
        目标成本政府收费不含税 MONEY,
        目标成本不可预见费不含税 MONEY,
        目标成本营销费用不含税 MONEY,
        目标成本管理费用不含税 MONEY,
        目标成本财务费用不含税 MONEY,
        
        动态成本 MONEY,
        动态成本直投 MONEY,
        动态成本除地价外直投 MONEY,
        动态成本开发前期费 MONEY,
        动态成本建筑安装工程费 MONEY,
        动态成本红线内配套费 MONEY,
        动态成本政府收费 MONEY,
        动态成本不可预见费 MONEY,
        动态成本营销费用 MONEY,
        动态成本管理费用 MONEY,
        动态成本财务费用 MONEY,
        --不含税
        动态成本不含税 MONEY,
        动态成本直投不含税 MONEY,
        动态成本除地价外直投不含税 MONEY, 
        动态成本开发前期费不含税 MONEY,
        动态成本建筑安装工程费不含税 MONEY,
        动态成本红线内配套费不含税 MONEY,
        动态成本政府收费不含税 MONEY,
        动态成本不可预见费不含税 MONEY,
        动态成本营销费用不含税 MONEY,
        动态成本管理费用不含税 MONEY,
        动态成本财务费用不含税 MONEY,
        本年已发生除地价外直投 MONEY,
        累计营销费支出 MONEY,
        累计财务费支出 MONEY,
        累计管理费支出 MONEY,
        本年营销费支出 MONEY,
        本年财务费支出 MONEY,
        本年管理费支出 MONEY,
        本月营销费支出 MONEY,
        本月财务费支出 MONEY,
        本月管理费支出 MONEY,
        地价 MONEY,
        除地价外直投本日发生金额 MONEY,
        除地价外直投本月发生金额 MONEY,
        除地价外直投本年发生金额 MONEY,
        除地价外直投累计发生金额 MONEY,
        --年初成本
        年初目标成本 MONEY,
        年初目标成本直投 MONEY,
        年初目标成本除地价外直投 MONEY,
        年初目标成本营销费用 MONEY,
        年初目标成本管理费用 MONEY,
        年初目标成本财务费用 MONEY,
        -- 已发生成本
        已发生成本 MONEY,
        已发生成本直投 MONEY,
        已发生成本除地价外直投 MONEY,
        已发生成本开发前期费 MONEY,
        已发生成本建筑安装工程费 MONEY,
        已发生成本红线内配套费 MONEY,
        已发生成本政府收费 MONEY,
        已发生成本不可预见费 MONEY,
        已发生成本土地款 money,
        已发生成本营销费用 MONEY,
        已发生成本管理费用 MONEY,
        已发生成本财务费用 MONEY,
        已发生成本不含税 MONEY,
        已发生成本直投不含税 MONEY,
        已发生成本除地价外直投不含税 MONEY,
        已发生成本开发前期费不含税 MONEY,
        已发生成本建筑安装工程费不含税 MONEY,
        已发生成本红线内配套费不含税 MONEY,
        已发生成本政府收费不含税 MONEY,
        已发生成本不可预见费不含税 MONEY,
        已发生成本土地款不含税 MONEY,
        已发生成本营销费用不含税 MONEY,
        已发生成本管理费用不含税 MONEY,
        已发生成本财务费用不含税 MONEY,
        -- 待发生成本
        待发生成本 MONEY,
        待发生成本直投 MONEY,
        待发生成本除地价外直投 MONEY,
        待发生成本开发前期费 MONEY,
        待发生成本建筑安装工程费 MONEY,
        待发生成本红线内配套费 MONEY,
        待发生成本政府收费 MONEY,
        待发生成本不可预见费 MONEY,
        待发生成本营销费用 MONEY,
        待发生成本管理费用 MONEY,
        待发生成本财务费用 MONEY,
        待发生成本不含税 MONEY,
        待发生成本直投不含税 MONEY,
        待发生成本除地价外直投不含税 MONEY,
        待发生成本开发前期费不含税 MONEY,
        待发生成本建筑安装工程费不含税 MONEY,
        待发生成本红线内配套费不含税 MONEY,
        待发生成本政府收费不含税 MONEY,
        待发生成本不可预见费不含税 MONEY,
        待发生成本营销费用不含税 MONEY,
        待发生成本管理费用不含税 MONEY,
        待发生成本财务费用不含税 MONEY,
        -- 已支付成本
        已支付成本 MONEY,
        已支付成本直投 MONEY,
        已支付成本除地价外直投 MONEY,
        已支付成本开发前期费 MONEY,
        已支付成本建筑安装工程费 MONEY,
        已支付成本红线内配套费 MONEY,
        已支付成本政府收费 MONEY,
        已支付成本不可预见费 MONEY,
        已支付成本土地款 money,
        已支付成本营销费用 MONEY,
        已支付成本管理费用 MONEY,
        已支付成本财务费用 MONEY,
        --不含税
        已支付成本不含税 MONEY,
        已支付成本直投不含税 MONEY,
        已支付成本除地价外直投不含税 MONEY,
        已支付成本开发前期费不含税 MONEY,
        已支付成本建筑安装工程费不含税 MONEY,
        已支付成本红线内配套费不含税 MONEY,
        已支付成本政府收费不含税 MONEY,
        已支付成本不可预见费不含税 MONEY,
        已支付成本土地款不含税 MONEY,
        已支付成本营销费用不含税 MONEY,
        已支付成本管理费用不含税 MONEY,
        已支付成本财务费用不含税 MONEY,
        -- 合同性成本
        合同性成本 MONEY,
        合同性成本直投 MONEY,
        合同性成本除地价外直投 MONEY,
        合同性成本开发前期费 MONEY,
        合同性成本建筑安装工程费 MONEY,
        合同性成本红线内配套费 MONEY,
        合同性成本政府收费 MONEY,
        合同性成本不可预见费 MONEY,
        合同性成本土地款 money,
        合同性成本营销费用 MONEY,
        合同性成本管理费用 MONEY,
        合同性成本财务费用 MONEY,
        合同性成本不含税 MONEY,
        合同性成本直投不含税 MONEY,
        合同性成本除地价外直投不含税 MONEY,
        合同性成本开发前期费不含税 MONEY,
        合同性成本建筑安装工程费不含税 MONEY,
        合同性成本红线内配套费不含税 MONEY,
        合同性成本政府收费不含税 MONEY,
        合同性成本不可预见费不含税 MONEY,
        合同性成本土地款不含税 MONEY,
        合同性成本营销费用不含税 MONEY,
        合同性成本管理费用不含税 MONEY,
        合同性成本财务费用不含税 MONEY,
        --降本任务
        降本任务 MONEY,
        直投降本任务 MONEY,
        除地价外直投降本任务 MONEY,
        营销费用降本任务 MONEY ,
        管理费用降本任务 MONEY ,
        财务费用降本任务 MONEY,

        --设计变更
        合同总金额 MONEY,
        总变更率 MONEY,
        变更总金额 MONEY,
        合同金额 MONEY,
        现场签证累计发生比例 MONEY,
        现场签证累计发生金额 MONEY,
        设计变更累计发生比例 MONEY,
        设计变更累计发生金额 MONEY,
        -- 总包
        总包合同总金额 MONEY,
        总包总变更率 MONEY,
        总包变更总金额 MONEY,
        总包合同金额 MONEY,
        总包现场签证累计发生比例 MONEY,
        总包现场签证累计发生金额 MONEY,
        总包设计变更累计发生比例 MONEY,
        总包设计变更累计发生金额 MONEY,
        -- 装修
        装修合同总金额 MONEY,
        装修总变更率 MONEY,
        装修变更总金额 MONEY,
        装修合同金额 MONEY,
        装修现场签证累计发生比例 MONEY,
        装修现场签证累计发生金额 MONEY,
        装修设计变更累计发生比例 MONEY,
        装修设计变更累计发生金额 MONEY,
        -- 园林
        园林合同总金额 MONEY,
        园林总变更率 MONEY,
        园林变更总金额 MONEY,
        园林合同金额 MONEY,
        园林现场签证累计发生比例 MONEY,
        园林现场签证累计发生金额 MONEY,
        园林设计变更累计发生比例 MONEY,
        园林设计变更累计发生金额 MONEY,
        -- 其他
        其他合同总金额 MONEY,
        其他总变更率 MONEY,
        其他变更总金额 MONEY, 
        其他合同金额 MONEY,
        其他现场签证累计发生比例 MONEY,
        其他现场签证累计发生金额 MONEY,
        其他设计变更累计发生比例 MONEY,
        其他设计变更累计发生金额 MONEY
    );

    --插入业态的值 
    INSERT INTO ydkb_dthz_wq_deal_cbinfo
    (
        组织架构父级ID,
        组织架构ID,
        组织架构名称,
        组织架构编码,
        组织架构类型,
        目标成本,
        目标成本直投,
        目标成本除地价外直投,
        目标成本开发前期费,
        目标成本建筑安装工程费,
        目标成本红线内配套费,
        目标成本政府收费,
        目标成本不可预见费,
        目标成本营销费用,
        目标成本管理费用,
        目标成本财务费用,
        --不含税
        目标成本不含税,
        目标成本直投不含税,
        目标成本除地价外直投不含税,
        目标成本开发前期费不含税,
        目标成本建筑安装工程费不含税,
        目标成本红线内配套费不含税,
        目标成本政府收费不含税,
        目标成本不可预见费不含税,
        目标成本营销费用不含税,
        目标成本管理费用不含税,
        目标成本财务费用不含税,
        动态成本,
        动态成本直投,
        动态成本除地价外直投,
        动态成本开发前期费,
        动态成本建筑安装工程费,
        动态成本红线内配套费,
        动态成本政府收费,
        动态成本不可预见费,
        动态成本营销费用,
        动态成本管理费用,
        动态成本财务费用,
        --不含税
        动态成本不含税,
        动态成本直投不含税,
        动态成本除地价外直投不含税,
        动态成本开发前期费不含税,
        动态成本建筑安装工程费不含税,
        动态成本红线内配套费不含税,
        动态成本政府收费不含税,
        动态成本不可预见费不含税,
        动态成本营销费用不含税,
        动态成本管理费用不含税,
        动态成本财务费用不含税,
        本年已发生除地价外直投,
        累计营销费支出,
        累计财务费支出,
        累计管理费支出,
        本年营销费支出,
        本年财务费支出,
        本年管理费支出,
        本月营销费支出,
        本月财务费支出,
        本月管理费支出,
        地价,
        -- 已发生成本
        已发生成本,
        已发生成本直投,
        已发生成本除地价外直投,
        已发生成本开发前期费,
        已发生成本建筑安装工程费,
        已发生成本红线内配套费,
        已发生成本政府收费,
        已发生成本不可预见费,
        已发生成本土地款,
        已发生成本营销费用,
        已发生成本管理费用,
        已发生成本财务费用,
        已发生成本不含税,
        已发生成本直投不含税,
        已发生成本除地价外直投不含税,
        已发生成本开发前期费不含税,
        已发生成本建筑安装工程费不含税,
        已发生成本红线内配套费不含税,
        已发生成本政府收费不含税,
        已发生成本不可预见费不含税,
        已发生成本土地款不含税,
        已发生成本营销费用不含税,
        已发生成本管理费用不含税,
        已发生成本财务费用不含税,
        -- 待发生成本
        待发生成本,
        待发生成本直投,
        待发生成本除地价外直投,
        待发生成本开发前期费,
        待发生成本建筑安装工程费,
        待发生成本红线内配套费,
        待发生成本政府收费,
        待发生成本不可预见费,
        待发生成本营销费用,
        待发生成本管理费用,
        待发生成本财务费用,
        待发生成本不含税,
        待发生成本直投不含税,
        待发生成本除地价外直投不含税,
        待发生成本开发前期费不含税,
        待发生成本建筑安装工程费不含税,
        待发生成本红线内配套费不含税,
        待发生成本政府收费不含税,
        待发生成本不可预见费不含税,
        待发生成本营销费用不含税,
        待发生成本管理费用不含税,
        待发生成本财务费用不含税,
        -- 已支付成本
        已支付成本,
        已支付成本直投,
        已支付成本除地价外直投,
        已支付成本开发前期费,
        已支付成本建筑安装工程费,
        已支付成本红线内配套费,
        已支付成本政府收费,
        已支付成本不可预见费,
        已支付成本土地款,
        已支付成本营销费用,
        已支付成本管理费用,
        已支付成本财务费用,
        --不含税
        已支付成本不含税,
        已支付成本直投不含税,
        已支付成本除地价外直投不含税,
        已支付成本开发前期费不含税,
        已支付成本建筑安装工程费不含税,
        已支付成本红线内配套费不含税,
        已支付成本政府收费不含税,
        已支付成本不可预见费不含税,
        已支付成本土地款不含税,
        已支付成本营销费用不含税,
        已支付成本管理费用不含税,
        已支付成本财务费用不含税,
        -- 合同性成本
        合同性成本,
        合同性成本直投,
        合同性成本除地价外直投,
        合同性成本开发前期费,
        合同性成本建筑安装工程费,
        合同性成本红线内配套费,
        合同性成本政府收费,
        合同性成本不可预见费,
        合同性成本土地款,
        合同性成本营销费用,
        合同性成本管理费用,
        合同性成本财务费用,
        合同性成本不含税,
        合同性成本直投不含税,
        合同性成本除地价外直投不含税,
        合同性成本开发前期费不含税,
        合同性成本建筑安装工程费不含税,
        合同性成本红线内配套费不含税,
        合同性成本政府收费不含税,
        合同性成本不可预见费不含税,
        合同性成本土地款不含税,
        合同性成本营销费用不含税,
        合同性成本管理费用不含税,
        合同性成本财务费用不含税,
        -- 降本目标
        降本任务,
        直投降本任务,
        除地价外直投降本任务,
        营销费用降本任务 ,
        管理费用降本任务 ,
        财务费用降本任务

    )
      SELECT bi2.组织架构父级ID,
          bi2.组织架构ID,
          bi2.组织架构名称,
          bi2.组织架构编码,
          bi2.组织架构类型,
          isnull(目标成本直投,0)+isnull(目标成本除地价外直投,0)+isnull(目标成本营销费用,0)+isnull(目标成本管理费用,0)+isnull(目标成本财务费用,0) 目标成本,
          目标成本直投,
          目标成本除地价外直投,
          目标成本开发前期费,
          目标成本建筑安装工程费,
          目标成本红线内配套费,
          目标成本政府收费,
          目标成本不可预见费,
          目标成本营销费用,
          目标成本管理费用,
          目标成本财务费用,
          --不含税
          isnull(目标成本直投不含税,0)+isnull(目标成本除地价外直投不含税,0)+isnull(目标成本营销费用不含税,0)+isnull(目标成本管理费用不含税,0)+isnull(目标成本财务费用不含税,0) 目标成本不含税,
          目标成本直投不含税,
          目标成本除地价外直投不含税,
          目标成本开发前期费不含税,
          目标成本建筑安装工程费不含税,
          目标成本红线内配套费不含税,
          目标成本政府收费不含税,
          目标成本不可预见费不含税,
          目标成本营销费用不含税,
          目标成本管理费用不含税,
          目标成本财务费用不含税,
          isnull(动态成本直投,0)+isnull(动态成本除地价外直投,0)+isnull(动态成本营销费用,0)+isnull(动态成本管理费用,0)+isnull(动态成本财务费用,0) 动态成本,
          动态成本直投,
          动态成本除地价外直投,
          动态成本开发前期费,
          动态成本建筑安装工程费,
          动态成本红线内配套费,
          动态成本政府收费,
          动态成本不可预见费,
          动态成本营销费用,
          动态成本管理费用,
          动态成本财务费用,
          isnull(动态成本直投不含税,0)+isnull(动态成本除地价外直投不含税,0)+isnull(动态成本营销费用不含税,0)+isnull(动态成本管理费用不含税,0)+isnull(动态成本财务费用不含税,0) 动态成本不含税,
          动态成本直投不含税,
          动态成本除地价外直投不含税,
          动态成本开发前期费不含税,
          动态成本建筑安装工程费不含税,
          动态成本红线内配套费不含税,
          动态成本政府收费不含税,
          动态成本不可预见费不含税,
          动态成本营销费用不含税,
          动态成本管理费用不含税,
          动态成本财务费用不含税,
          NULL 本年已发生除地价外直投,
          NULL 累计营销费支出,
          NULL 累计财务费支出,
          NULL 累计管理费支出,
          NULL 本年营销费支出,
          NULL 本年财务费支出,
          NULL 本年管理费支出,
          NULL 本月营销费支出,
          NULL 本月财务费支出,
          NULL 本月管理费支出,
          NULL AS 地价,
          -- 已发生成本
          isnull(已发生成本除地价外直投,0)+isnull(已发生成本土地款,0)+isnull(已发生成本营销费用,0)+isnull(已发生成本管理费用,0)+isnull(已发生成本财务费用,0) 已发生成本,
          已发生成本直投,
          已发生成本除地价外直投,
          已发生成本开发前期费,
          已发生成本建筑安装工程费,
          已发生成本红线内配套费,
          已发生成本政府收费,
          已发生成本不可预见费,
          已发生成本土地款,
          已发生成本营销费用,
          已发生成本管理费用,
          已发生成本财务费用,
          isnull(已发生成本除地价外直投不含税,0)+isnull(已发生成本土地款不含税,0)+isnull(已发生成本营销费用不含税,0)+isnull(已发生成本管理费用不含税,0)+isnull(已发生成本财务费用不含税,0) 已发生成本不含税,
          已发生成本直投不含税,
          已发生成本除地价外直投不含税,
          已发生成本开发前期费不含税,
          已发生成本建筑安装工程费不含税,
          已发生成本红线内配套费不含税,
          已发生成本政府收费不含税,
          已发生成本不可预见费不含税,
          已发生成本土地款不含税,
          已发生成本营销费用不含税,
          已发生成本管理费用不含税,
          已发生成本财务费用不含税,
          -- 待发生成本
          isnull(待发生成本直投,0)+isnull(待发生成本营销费用,0)+isnull(待发生成本管理费用,0)+isnull(待发生成本财务费用,0) 待发生成本,
          待发生成本直投,
          待发生成本除地价外直投,
          待发生成本开发前期费,
          待发生成本建筑安装工程费,
          待发生成本红线内配套费,
          待发生成本政府收费,
          待发生成本不可预见费,
          待发生成本营销费用,
          待发生成本管理费用,
          待发生成本财务费用,
          isnull(待发生成本直投不含税,0)+isnull(待发生成本营销费用不含税,0)+isnull(待发生成本管理费用不含税,0)+isnull(待发生成本财务费用不含税,0) 待发生成本不含税,
          待发生成本直投不含税,
          待发生成本除地价外直投不含税,
          待发生成本开发前期费不含税,
          待发生成本建筑安装工程费不含税,
          待发生成本红线内配套费不含税,
          待发生成本政府收费不含税,
          待发生成本不可预见费不含税,
          待发生成本营销费用不含税,
          待发生成本管理费用不含税,
          待发生成本财务费用不含税,
          -- 已支付成本
          isnull(已支付成本除地价外直投,0)+isnull(已支付成本土地款,0)+isnull(已支付成本营销费用,0)+isnull(已支付成本管理费用,0)+isnull(已支付成本财务费用,0) 已支付成本,
          已支付成本直投,
          已支付成本除地价外直投,
          已支付成本开发前期费,
          已支付成本建筑安装工程费,
          已支付成本红线内配套费,
          已支付成本政府收费,
          已支付成本不可预见费,
          已支付成本土地款,
          已支付成本营销费用,
          已支付成本管理费用,
          已支付成本财务费用,
          --不含税
          isnull(已支付成本除地价外直投不含税,0)+isnull(已支付成本土地款不含税,0)+isnull(已支付成本营销费用不含税,0)+isnull(已支付成本管理费用不含税,0)+isnull(已支付成本财务费用不含税,0) 已支付成本不含税,
          已支付成本直投不含税,
          已支付成本除地价外直投不含税,
          已支付成本开发前期费不含税,
          已支付成本建筑安装工程费不含税,
          已支付成本红线内配套费不含税,
          已支付成本政府收费不含税,
          已支付成本不可预见费不含税,
          已支付成本土地款不含税,
          已支付成本营销费用不含税,
          已支付成本管理费用不含税,
          已支付成本财务费用不含税,
          -- 合同性成本
          isnull(合同性成本除地价外直投,0)+isnull(合同性成本土地款,0)+isnull(合同性成本营销费用,0)+isnull(合同性成本管理费用,0)+isnull(合同性成本财务费用,0) 合同性成本,
          合同性成本直投,
          合同性成本除地价外直投,
          合同性成本开发前期费,
          合同性成本建筑安装工程费,
          合同性成本红线内配套费,
          合同性成本政府收费,
          合同性成本不可预见费,
          合同性成本土地款,
          合同性成本营销费用,
          合同性成本管理费用,
          合同性成本财务费用,
          isnull(合同性成本除地价外直投不含税,0)+isnull(合同性成本土地款不含税,0)+isnull(合同性成本营销费用不含税,0)+isnull(合同性成本管理费用不含税,0)+isnull(合同性成本财务费用不含税,0) 合同性成本不含税,
          合同性成本直投不含税,
          合同性成本除地价外直投不含税,
          合同性成本开发前期费不含税,
          合同性成本建筑安装工程费不含税,
          合同性成本红线内配套费不含税,
          合同性成本政府收费不含税,
          合同性成本不可预见费不含税,
          合同性成本土地款不含税,
          合同性成本营销费用不含税,
          合同性成本管理费用不含税,
          合同性成本财务费用不含税,
          null as   降本任务,
          null as   直投降本任务,
          null as   除地价外直投降本任务,
          null as   营销费用降本任务 ,
          null as   管理费用降本任务 ,
          null as   财务费用降本任务
      FROM ydkb_BaseInfo bi2
      LEFT JOIN #yt_cb ytcb ON bi2.组织架构父级ID = ytcb.ProjGUID AND bi2.组织架构名称 = ytcb.ProductType
      WHERE bi2.组织架构类型 = 4
            AND bi2.平台公司GUID IN
                (
                    SELECT Value FROM dbo.fn_Split2(@developmentguid, ',')
                );

    --插入项目的值 
    INSERT INTO ydkb_dthz_wq_deal_cbinfo
    (
        组织架构父级ID,
        组织架构ID,
        组织架构名称,
        组织架构编码,
        组织架构类型,
        目标成本,
        目标成本直投,
        目标成本除地价外直投,
        目标成本开发前期费,
        目标成本建筑安装工程费,
        目标成本红线内配套费,
        目标成本政府收费,
        目标成本不可预见费,
        目标成本营销费用,
        目标成本管理费用,
        目标成本财务费用,
        --不含税
        目标成本不含税,
        目标成本直投不含税,
        目标成本除地价外直投不含税,
        目标成本开发前期费不含税,
        目标成本建筑安装工程费不含税,
        目标成本红线内配套费不含税,
        目标成本政府收费不含税,
        目标成本不可预见费不含税,
        目标成本营销费用不含税,
        目标成本管理费用不含税,
        目标成本财务费用不含税,
        动态成本,
        动态成本直投,
        动态成本除地价外直投,
        动态成本开发前期费,
        动态成本建筑安装工程费,
        动态成本红线内配套费,
        动态成本政府收费,
        动态成本不可预见费,
        动态成本营销费用,
        动态成本管理费用,
        动态成本财务费用,
        --不含税
        动态成本不含税,
        动态成本直投不含税,
        动态成本除地价外直投不含税,
        动态成本开发前期费不含税,
        动态成本建筑安装工程费不含税,
        动态成本红线内配套费不含税,
        动态成本政府收费不含税,
        动态成本不可预见费不含税,
        动态成本营销费用不含税,
        动态成本管理费用不含税,
        动态成本财务费用不含税,
        本年已发生除地价外直投,
        累计营销费支出,
        累计财务费支出,
        累计管理费支出,
        本年营销费支出,
        本年财务费支出,
        本年管理费支出,
        本月营销费支出,
        本月财务费支出,
        本月管理费支出,
        地价,
        除地价外直投本日发生金额,
        除地价外直投本月发生金额,
        除地价外直投本年发生金额,
        除地价外直投累计发生金额,
        --年初成本
        年初目标成本,
        年初目标成本直投,
        年初目标成本除地价外直投,
        年初目标成本营销费用,
        年初目标成本管理费用,
        年初目标成本财务费用,
        -- 已发生成本
        已发生成本,
        已发生成本直投,
        已发生成本除地价外直投,
        已发生成本开发前期费,
        已发生成本建筑安装工程费,
        已发生成本红线内配套费,
        已发生成本政府收费,
        已发生成本不可预见费,
        已发生成本土地款,
        已发生成本营销费用,
        已发生成本管理费用,
        已发生成本财务费用,
        已发生成本不含税,
        已发生成本直投不含税,
        已发生成本除地价外直投不含税,
        已发生成本开发前期费不含税,
        已发生成本建筑安装工程费不含税,
        已发生成本红线内配套费不含税,
        已发生成本政府收费不含税,
        已发生成本不可预见费不含税,
        已发生成本土地款不含税,
        已发生成本营销费用不含税,
        已发生成本管理费用不含税,
        已发生成本财务费用不含税,
        -- 待发生成本
        待发生成本,
        待发生成本直投,
        待发生成本除地价外直投,
        待发生成本开发前期费,
        待发生成本建筑安装工程费,
        待发生成本红线内配套费,
        待发生成本政府收费,
        待发生成本不可预见费,
        待发生成本营销费用,
        待发生成本管理费用,
        待发生成本财务费用,
        待发生成本不含税,
        待发生成本直投不含税,
        待发生成本除地价外直投不含税,
        待发生成本开发前期费不含税,
        待发生成本建筑安装工程费不含税,
        待发生成本红线内配套费不含税,
        待发生成本政府收费不含税,
        待发生成本不可预见费不含税,
        待发生成本营销费用不含税,
        待发生成本管理费用不含税,
        待发生成本财务费用不含税,
        -- 已支付成本
        已支付成本,
        已支付成本直投,
        已支付成本除地价外直投,
        已支付成本开发前期费,
        已支付成本建筑安装工程费,
        已支付成本红线内配套费,
        已支付成本政府收费,
        已支付成本不可预见费,
        已支付成本土地款,
        已支付成本营销费用,
        已支付成本管理费用,
        已支付成本财务费用,
        --不含税
        已支付成本不含税,
        已支付成本直投不含税,
        已支付成本除地价外直投不含税,
        已支付成本开发前期费不含税,
        已支付成本建筑安装工程费不含税,
        已支付成本红线内配套费不含税,
        已支付成本政府收费不含税,
        已支付成本不可预见费不含税,
        已支付成本土地款不含税,
        已支付成本营销费用不含税,
        已支付成本管理费用不含税,
        已支付成本财务费用不含税,
        -- 合同性成本
        合同性成本,
        合同性成本直投,
        合同性成本除地价外直投,
        合同性成本开发前期费,
        合同性成本建筑安装工程费,
        合同性成本红线内配套费,
        合同性成本政府收费,
        合同性成本不可预见费,
        合同性成本土地款,
        合同性成本营销费用,
        合同性成本管理费用,
        合同性成本财务费用,
        合同性成本不含税,
        合同性成本直投不含税,
        合同性成本除地价外直投不含税,
        合同性成本开发前期费不含税,
        合同性成本建筑安装工程费不含税,
        合同性成本红线内配套费不含税,
        合同性成本政府收费不含税,
        合同性成本不可预见费不含税,
        合同性成本土地款不含税,
        合同性成本营销费用不含税,
        合同性成本管理费用不含税,
        合同性成本财务费用不含税,
        -- 降本目标
        降本任务,
        直投降本任务,
        除地价外直投降本任务,
        营销费用降本任务 ,
        管理费用降本任务 ,
        财务费用降本任务,
        
        --设计变更
        合同总金额 ,
        总变更率 ,
        变更总金额,
        合同金额,
        现场签证累计发生比例 ,
        现场签证累计发生金额 ,
        设计变更累计发生比例 ,
        设计变更累计发生金额 ,
        -- 总包
        总包合同总金额 ,
        总包总变更率 ,
        总包变更总金额,
        总包合同金额,
        总包现场签证累计发生比例 ,
        总包现场签证累计发生金额 ,
        总包设计变更累计发生比例 ,
        总包设计变更累计发生金额 ,
        -- 装修
        装修合同总金额,
        装修总变更率,
        装修变更总金额,
        装修合同金额,
        装修现场签证累计发生比例,
        装修现场签证累计发生金额,
        装修设计变更累计发生比例,
        装修设计变更累计发生金额,
        -- 园林
        园林合同总金额,
        园林总变更率,
        园林变更总金额,
        园林合同金额,
        园林现场签证累计发生比例,
        园林现场签证累计发生金额,
        园林设计变更累计发生比例,
        园林设计变更累计发生金额,
        -- 其他
        其他合同总金额,
        其他总变更率,
        其他变更总金额,
        其他合同金额,
        其他现场签证累计发生比例,
        其他现场签证累计发生金额,
        其他设计变更累计发生比例,
        其他设计变更累计发生金额
    )
      SELECT bi2.组织架构父级ID,
          bi2.组织架构ID,
          bi2.组织架构名称,
          bi2.组织架构编码,
          bi2.组织架构类型,
          isnull(目标成本直投,0)+isnull(目标成本营销费用,0)+isnull(目标成本管理费用,0)+isnull(目标成本财务费用,0) AS 目标成本,
          ISNULL(目标成本直投, 0) AS 目标成本直投,
          ISNULL(目标成本除地价外直投, 0) AS 目标成本除地价外直投,
          目标成本开发前期费,
          目标成本建筑安装工程费,
          目标成本红线内配套费,
          目标成本政府收费,
          目标成本不可预见费,
          ISNULL(目标成本营销费用, 0) AS 目标成本营销费用,
          ISNULL(目标成本管理费用, 0) AS 目标成本管理费用,
          ISNULL(目标成本财务费用, 0) AS 目标成本财务费用,
          isnull(目标成本直投不含税,0)+isnull(目标成本营销费用不含税,0)+isnull(目标成本管理费用不含税,0)+isnull(目标成本财务费用不含税,0) AS 目标成本不含税,
          ISNULL(目标成本直投不含税, 0) AS 目标成本直投不含税,
          ISNULL(目标成本除地价外直投不含税, 0) AS 目标成本除地价外直投不含税,
          目标成本开发前期费不含税,
          目标成本建筑安装工程费不含税,
          目标成本红线内配套费不含税,
          目标成本政府收费不含税,
          目标成本不可预见费不含税,
          ISNULL(目标成本营销费用不含税, 0) AS 目标成本营销费用不含税,
          ISNULL(目标成本管理费用不含税, 0) AS 目标成本管理费用不含税,
          ISNULL(目标成本财务费用不含税, 0) AS 目标成本财务费用不含税,

          isnull(动态成本直投,0)+isnull(动态成本营销费用,0)+isnull(动态成本管理费用,0)+isnull(动态成本财务费用,0) AS 动态成本,
          ISNULL(动态成本直投, 0) AS 动态成本直投,
          ISNULL(动态成本除地价外直投, 0) AS 动态成本除地价外直投,
          动态成本开发前期费,
          动态成本建筑安装工程费,
          动态成本红线内配套费,
          动态成本政府收费,
          动态成本不可预见费,
          ISNULL(动态成本营销费用, 0) AS 动态成本营销费用,
          ISNULL(动态成本管理费用, 0) AS 动态成本管理费用,
          ISNULL(动态成本财务费用, 0) AS 动态成本财务费用,
          isnull(动态成本直投不含税,0)+isnull(动态成本营销费用不含税,0)+isnull(动态成本管理费用不含税,0)+isnull(动态成本财务费用不含税,0) 动态成本不含税,
          ISNULL(动态成本直投不含税, 0) AS 动态成本直投不含税,
          ISNULL(动态成本除地价外直投不含税, 0) AS 动态成本除地价外直投不含税,
          动态成本开发前期费不含税,
          动态成本建筑安装工程费不含税,
          动态成本红线内配套费不含税,
          动态成本政府收费不含税,
          动态成本不可预见费不含税,
          ISNULL(动态成本营销费用不含税, 0) AS 动态成本营销费用不含税,
          ISNULL(动态成本管理费用不含税, 0) AS 动态成本管理费用不含税,
          ISNULL(动态成本财务费用不含税, 0) AS 动态成本财务费用不含税,
          ISNULL(cb1.本年已付除地价外直投, 0) AS 本年已发生除地价外直投,
          ISNULL(cb1.累计营销费支出, 0) AS 累计营销费支出,
          ISNULL(cb1.累计财务费支出, 0) AS 累计财务费支出,
          ISNULL(cb1.累计管理费支出, 0) AS 累计管理费支出,
          ISNULL(cb1.本年营销费支出, 0) AS 本年营销费支出,
          ISNULL(cb1.本年财务费支出, 0) AS 本年财务费支出,
          ISNULL(cb1.本年管理费支出, 0) AS 本年管理费支出,
          ISNULL(cb1.本月营销费支出, 0) AS 本月营销费支出,
          ISNULL(cb1.本月财务费支出, 0) AS 本月财务费支出,
          ISNULL(cb1.本月管理费支出, 0) AS 本月管理费支出,
          ISNULL(地价, 0) AS 地价,
          ISNULL(除地价外直投本日发生金额, 0) AS 除地价外直投本日发生金额,
          ISNULL(除地价外直投本月发生金额, 0) AS 除地价外直投本月发生金额,
          ISNULL(除地价外直投本年发生金额, 0) AS 除地价外直投本年发生金额,
          ISNULL(除地价外直投累计发生金额, 0) AS 除地价外直投累计发生金额,
          --年初
          isnull(年初目标成本直投,0)+isnull(年初目标成本营销费用,0)+isnull(年初目标成本管理费用,0)+isnull(年初目标成本财务费用,0) AS 年初目标成本,
          ISNULL(年初目标成本直投, 0) AS 年初目标成本直投,
          ISNULL(年初目标成本除地价外直投, 0) AS 年初目标成本除地价外直投,
          ISNULL(年初目标成本营销费用, 0) AS 年初目标成本营销费用,
          ISNULL(年初目标成本管理费用, 0) AS 年初目标成本管理费用,
          ISNULL(年初目标成本财务费用, 0) AS 年初目标成本财务费用,

          -- 已发生成本
          isnull(已发生成本除地价外直投,0)+isnull(已发生成本土地款,0)+isnull(已发生成本营销费用,0)+isnull(已发生成本管理费用,0)+isnull(已发生成本财务费用,0) 已发生成本,
          已发生成本直投,
          已发生成本除地价外直投,
          已发生成本开发前期费,
          已发生成本建筑安装工程费,
          已发生成本红线内配套费,
          已发生成本政府收费,
          已发生成本不可预见费,
          已发生成本土地款,
          已发生成本营销费用,
          已发生成本管理费用,
          已发生成本财务费用,
          isnull(已发生成本除地价外直投不含税,0)+isnull(已发生成本土地款不含税,0)+isnull(已发生成本营销费用不含税,0)+isnull(已发生成本管理费用不含税,0)+isnull(已发生成本财务费用不含税,0) 已发生成本不含税,
          已发生成本直投不含税,
          已发生成本除地价外直投不含税,
          已发生成本开发前期费不含税,
          已发生成本建筑安装工程费不含税,
          已发生成本红线内配套费不含税,
          已发生成本政府收费不含税,
          已发生成本不可预见费不含税,
          已发生成本土地款不含税,
          已发生成本营销费用不含税,
          已发生成本管理费用不含税,
          已发生成本财务费用不含税,
          -- 待发生成本
          isnull(待发生成本直投,0)+isnull(待发生成本营销费用,0)+isnull(待发生成本管理费用,0)+isnull(待发生成本财务费用,0) 待发生成本,
          待发生成本直投,
          待发生成本除地价外直投,
          待发生成本开发前期费,
          待发生成本建筑安装工程费,
          待发生成本红线内配套费,
          待发生成本政府收费,
          待发生成本不可预见费,
          待发生成本营销费用,
          待发生成本管理费用,
          待发生成本财务费用,
          isnull(待发生成本直投不含税,0)+isnull(待发生成本营销费用不含税,0)+isnull(待发生成本管理费用不含税,0)+isnull(待发生成本财务费用不含税,0) 待发生成本不含税,
          待发生成本直投不含税,
          待发生成本除地价外直投不含税,
          待发生成本开发前期费不含税,
          待发生成本建筑安装工程费不含税,
          待发生成本红线内配套费不含税,
          待发生成本政府收费不含税,
          待发生成本不可预见费不含税,
          待发生成本营销费用不含税,
          待发生成本管理费用不含税,
          待发生成本财务费用不含税,
          -- 已支付成本
          isnull(已支付成本除地价外直投,0)+isnull(已支付成本土地款,0)+isnull(已支付成本营销费用,0)+isnull(已支付成本管理费用,0)+isnull(已支付成本财务费用,0) 已支付成本,
          已支付成本直投,
          已支付成本除地价外直投,
          已支付成本开发前期费,
          已支付成本建筑安装工程费,
          已支付成本红线内配套费,
          已支付成本政府收费,
          已支付成本不可预见费,
          已支付成本土地款,
          已支付成本营销费用,
          已支付成本管理费用,
          已支付成本财务费用,
          --不含税
          isnull(已支付成本直投不含税,0)+isnull(已支付成本营销费用不含税,0)+isnull(已支付成本管理费用不含税,0)+isnull(已支付成本财务费用不含税,0) 已支付成本不含税,
          已支付成本直投不含税,
          已支付成本除地价外直投不含税,
          已支付成本开发前期费不含税,
          已支付成本建筑安装工程费不含税,
          已支付成本红线内配套费不含税,
          已支付成本政府收费不含税,
          已支付成本不可预见费不含税,
          已支付成本土地款不含税,
          已支付成本营销费用不含税,
          已支付成本管理费用不含税,
          已支付成本财务费用不含税,
          -- 合同性成本
          isnull(合同性成本除地价外直投,0)+isnull(合同性成本土地款,0)+isnull(合同性成本营销费用,0)+isnull(合同性成本管理费用,0)+isnull(合同性成本财务费用,0) 合同性成本,
          合同性成本直投,
          合同性成本除地价外直投,
          合同性成本开发前期费,
          合同性成本建筑安装工程费,
          合同性成本红线内配套费,
          合同性成本政府收费,
          合同性成本不可预见费,
          合同性成本土地款,
          合同性成本营销费用,
          合同性成本管理费用,
          合同性成本财务费用,
          isnull(合同性成本除地价外直投不含税,0)+isnull(合同性成本土地款不含税,0)+isnull(合同性成本营销费用不含税,0)+isnull(合同性成本管理费用不含税,0)+isnull(合同性成本财务费用不含税,0) 合同性成本不含税,
          合同性成本直投不含税,
          合同性成本除地价外直投不含税,
          合同性成本开发前期费不含税,
          合同性成本建筑安装工程费不含税,
          合同性成本红线内配套费不含税,
          合同性成本政府收费不含税,
          合同性成本不可预见费不含税,
          合同性成本土地款不含税,
          合同性成本营销费用不含税,
          合同性成本管理费用不含税,
          合同性成本财务费用不含税,
            -- 降本任务
        cblr.降本任务,
        cblr.直投降本任务,
        cblr.除地价外直投降本任务,
        cblr.营销费用降本任务 ,
        cblr.管理费用降本任务 ,
        cblr.财务费用降本任务,

        --设计变更
         isnull(palt.合同总金额,0) as 合同总金额 ,
         case when isnull(palt.合同总金额,0) = 0 then 0 else   isnull(palt.变更总金额,0) / isnull(palt.合同总金额,0)   end  总变更率 ,
         isnull(palt.变更总金额,0) as 变更总金额,
         isnull(palt.合同金额,0) as 合同金额,
         case when (isnull(palt.现场签证累计发生金额,0) + isnull(palt.合同金额,0) ) =0 then 0  else  isnull(palt.现场签证累计发生金额,0) /  (isnull(palt.现场签证累计发生金额,0) + isnull(palt.合同金额,0) ) end as 现场签证累计发生比例 ,
         isnull(palt.现场签证累计发生金额,0)  as 现场签证累计发生金额 ,
         case when (isnull(palt.设计变更累计发生金额,0) + isnull(palt.合同金额,0) ) =0 then 0  else  isnull(palt.设计变更累计发生金额,0) /  (isnull(palt.设计变更累计发生金额,0) + isnull(palt.合同金额,0) ) end as  设计变更累计发生比例 ,
         isnull(palt.设计变更累计发生金额,0)  as 设计变更累计发生金额 ,
            -- 总包
         isnull(palt.总包合同总金额,0)  as 总包合同总金额 ,
         case when isnull(palt.总包合同总金额,0) = 0 then 0 else isnull(palt.总包变更总金额,0) / isnull(palt.总包合同总金额,0) end as  总包总变更率 ,
         isnull(palt.总包变更总金额,0) as 总包变更总金额,
         isnull(palt.总包合同金额,0) as 总包合同金额,
         case when (isnull(palt.总包现场签证累计发生金额,0) + isnull(palt.总包合同总金额,0) ) =0 then 0  else  isnull(palt.总包现场签证累计发生金额,0) /  (isnull(palt.总包现场签证累计发生金额,0) + isnull(palt.总包合同总金额,0) ) end  as 总包现场签证累计发生比例 ,
         isnull(palt.总包现场签证累计发生金额,0)  as 总包现场签证累计发生金额 ,
         case when (isnull(palt.总包设计变更累计发生金额,0) + isnull(palt.总包合同金额,0) ) =0 then 0  else  isnull(palt.总包设计变更累计发生金额,0) /  (isnull(palt.总包设计变更累计发生金额,0) + isnull(palt.总包合同金额,0) ) end as    总包设计变更累计发生比例 ,
         isnull(palt.总包设计变更累计发生金额,0)  as 总包设计变更累计发生金额 ,
            -- 装修
         isnull(palt.精装合同总金额,0)  as 装修合同总金额,
         case when isnull(palt.精装合同总金额,0) = 0 then 0 else   isnull(palt.精装变更总金额,0) / isnull(palt.精装合同总金额,0) end as 装修总变更率,
         isnull(palt.精装变更总金额,0) as 装修变更总金额,
         isnull(palt.精装合同金额,0) as 装修合同金额,
         case when (isnull(palt.精装现场签证累计发生金额,0) + isnull(palt.精装合同总金额,0) ) =0 then 0  else  isnull(palt.精装现场签证累计发生金额,0) /  (isnull(palt.精装现场签证累计发生金额,0) + isnull(palt.精装合同总金额,0) ) end  as 装修现场签证累计发生比例,
         isnull(palt.精装现场签证累计发生金额,0)   装修现场签证累计发生金额,
         case when (isnull(palt.精装设计变更累计发生金额,0) + isnull(palt.精装合同金额,0) ) =0 then 0  else  isnull(palt.精装设计变更累计发生金额,0) /  (isnull(palt.精装设计变更累计发生金额,0) + isnull(palt.精装合同金额,0) ) end  装修设计变更累计发生比例,
         isnull(palt.精装设计变更累计发生金额,0)   装修设计变更累计发生金额,
            -- 园林
         isnull(palt.园林合同总金额,0)  as 园林合同总金额,
         case when isnull(palt.园林合同总金额,0) = 0 then 0 else   isnull(palt.园林变更总金额,0) / isnull(palt.园林合同总金额,0) end as 园林总变更率,
         isnull(palt.园林变更总金额,0) as 园林变更总金额,
         isnull(palt.园林合同金额,0) as 园林合同金额,
         case when (isnull(palt.园林现场签证累计发生金额,0) + isnull(palt.园林合同总金额,0) ) =0 then 0  else  isnull(palt.园林现场签证累计发生金额,0) /  (isnull(palt.园林现场签证累计发生金额,0) + isnull(palt.园林合同总金额,0) ) end  as 园林现场签证累计发生比例,
         isnull(palt.园林现场签证累计发生金额,0)   园林现场签证累计发生金额,
         case when (isnull(palt.园林设计变更累计发生金额,0) + isnull(palt.园林合同金额,0) ) =0 then 0  else  isnull(palt.园林设计变更累计发生金额,0) /  (isnull(palt.园林设计变更累计发生金额,0) + isnull(palt.园林合同金额,0) ) end  as 园林设计变更累计发生比例,
         isnull(palt.园林设计变更累计发生金额,0)   园林设计变更累计发生金额,
            -- 其他
         isnull(palt.其他合同总金额,0)  as 其他合同总金额,
         case when isnull(palt.其他合同总金额,0) = 0 then 0 else   isnull(palt.其他变更总金额,0) / isnull(palt.其他合同总金额,0) end as 其他总变更率,
         isnull(palt.其他变更总金额,0) as 其他变更总金额,
         isnull(palt.其他合同金额,0) as 其他合同金额,
         case when (isnull(palt.其他现场签证累计发生金额,0) + isnull(palt.其他合同总金额,0) ) =0 then 0  else  isnull(palt.其他现场签证累计发生金额,0) /  (isnull(palt.其他现场签证累计发生金额,0) + isnull(palt.其他合同总金额,0) ) end as   其他现场签证累计发生比例,
         isnull(palt.其他现场签证累计发生金额,0)   其他现场签证累计发生金额,
         case when (isnull(palt.其他设计变更累计发生金额,0) + isnull(palt.其他合同金额,0) ) =0 then 0  else  isnull(palt.其他设计变更累计发生金额,0) /  (isnull(palt.其他设计变更累计发生金额,0) + isnull(palt.其他合同金额,0) ) end  as 其他设计变更累计发生比例,
         isnull(palt.其他设计变更累计发生金额,0)   其他设计变更累计发生金额
      FROM ydkb_BaseInfo bi2
      LEFT JOIN #proj_cb cb ON bi2.组织架构ID = cb.ProjGUID
      LEFT JOIN #pro_cdjwzt cb1 ON cb1.ProjGUID = bi2.组织架构ID
      LEFT JOIN #dj dj ON dj.ProjGUID = bi2.组织架构ID
      LEFT JOIN #cdjwzt cdjwzt ON cdjwzt.ProjGUID = bi2.组织架构ID
      --年初成本
      LEFT JOIN #nc_cb nc  ON nc.parentprojguid = bi2.组织架构id
      -- 降本任务
      left join #proj_cblowerRisk cblr on  bi2.组织架构ID = cblr.项目guid
      -- 变更签证
      left  join #ProjHtAlter  palt On bi2.组织架构ID =  palt.项目GUID
      WHERE bi2.组织架构类型 = 3  AND bi2.平台公司GUID IN ( SELECT Value FROM dbo.fn_Split2(@developmentguid, ',') );


    --循环插入项目，城市公司，平台公司的值   
    DECLARE @baseinfo INT;
    SET @baseinfo = 3;

    WHILE (@baseinfo > 1)
    BEGIN
        INSERT INTO ydkb_dthz_wq_deal_cbinfo
        (
            组织架构父级ID,
            组织架构ID,
            组织架构名称,
            组织架构编码,
            组织架构类型,
            目标成本,
            目标成本直投,
            目标成本除地价外直投,
            目标成本开发前期费,
            目标成本建筑安装工程费,
            目标成本红线内配套费,
            目标成本政府收费,
            目标成本不可预见费,
            目标成本营销费用,
            目标成本管理费用,
            目标成本财务费用,
            目标成本不含税,
            目标成本直投不含税,
            目标成本除地价外直投不含税,
            目标成本开发前期费不含税,
            目标成本建筑安装工程费不含税,
            目标成本红线内配套费不含税,
            目标成本政府收费不含税,
            目标成本不可预见费不含税,
            目标成本营销费用不含税,
            目标成本管理费用不含税,
            目标成本财务费用不含税,
            动态成本,
            动态成本直投,
            动态成本除地价外直投,
            动态成本开发前期费,
            动态成本建筑安装工程费,
            动态成本红线内配套费,
            动态成本政府收费,
            动态成本不可预见费,
            动态成本营销费用,
            动态成本管理费用,
            动态成本财务费用,
            --不含税
            动态成本不含税,
            动态成本直投不含税,
            动态成本除地价外直投不含税,
            动态成本开发前期费不含税,
            动态成本建筑安装工程费不含税,
            动态成本红线内配套费不含税,
            动态成本政府收费不含税,
            动态成本不可预见费不含税,
            动态成本营销费用不含税,
            动态成本管理费用不含税,
            动态成本财务费用不含税,
            本年已发生除地价外直投,
            累计营销费支出,
            累计财务费支出,
            累计管理费支出,
            本年营销费支出,
            本年财务费支出,
            本年管理费支出,
            本月营销费支出,
            本月财务费支出,
            本月管理费支出,
            地价,
            除地价外直投本日发生金额,
            除地价外直投本月发生金额,
            除地价外直投本年发生金额,
            除地价外直投累计发生金额,
            --年初成本
            年初目标成本,
            年初目标成本直投,
            年初目标成本除地价外直投,
            年初目标成本营销费用,
            年初目标成本管理费用,
            年初目标成本财务费用,

            -- 已发生成本
            已发生成本,
            已发生成本直投,
            已发生成本除地价外直投,
            已发生成本开发前期费,
            已发生成本建筑安装工程费,
            已发生成本红线内配套费,
            已发生成本政府收费,
            已发生成本不可预见费,
            已发生成本土地款,
            已发生成本营销费用,
            已发生成本管理费用,
            已发生成本财务费用,
            已发生成本不含税,
            已发生成本直投不含税,
            已发生成本除地价外直投不含税,
            已发生成本开发前期费不含税,
            已发生成本建筑安装工程费不含税,
            已发生成本红线内配套费不含税,
            已发生成本政府收费不含税,
            已发生成本不可预见费不含税,
            已发生成本土地款不含税,
            已发生成本营销费用不含税,
            已发生成本管理费用不含税,
            已发生成本财务费用不含税,
            -- 待发生成本
            待发生成本,
            待发生成本直投,
            待发生成本除地价外直投,
            待发生成本开发前期费,
            待发生成本建筑安装工程费,
            待发生成本红线内配套费,
            待发生成本政府收费,
            待发生成本不可预见费,
            待发生成本营销费用,
            待发生成本管理费用,
            待发生成本财务费用,
            待发生成本不含税,
            待发生成本直投不含税,
            待发生成本除地价外直投不含税,
            待发生成本开发前期费不含税,
            待发生成本建筑安装工程费不含税,
            待发生成本红线内配套费不含税,
            待发生成本政府收费不含税,
            待发生成本不可预见费不含税,
            待发生成本营销费用不含税,
            待发生成本管理费用不含税,
            待发生成本财务费用不含税,
            -- 已支付成本
            已支付成本,
            已支付成本直投,
            已支付成本除地价外直投,
            已支付成本开发前期费,
            已支付成本建筑安装工程费,
            已支付成本红线内配套费,
            已支付成本政府收费,
            已支付成本不可预见费,
            已支付成本土地款,
            已支付成本营销费用,
            已支付成本管理费用,
            已支付成本财务费用,
            --不含税
            已支付成本不含税,
            已支付成本直投不含税,
            已支付成本除地价外直投不含税,
            已支付成本开发前期费不含税,
            已支付成本建筑安装工程费不含税,
            已支付成本红线内配套费不含税,
            已支付成本政府收费不含税,
            已支付成本不可预见费不含税,
            已支付成本土地款不含税,
            已支付成本营销费用不含税,
            已支付成本管理费用不含税,
            已支付成本财务费用不含税,
            -- 合同性成本
            合同性成本,
            合同性成本直投,
            合同性成本除地价外直投,
            合同性成本开发前期费,
            合同性成本建筑安装工程费,
            合同性成本红线内配套费,
            合同性成本政府收费,
            合同性成本不可预见费,
            合同性成本土地款,
            合同性成本营销费用,
            合同性成本管理费用,
            合同性成本财务费用,
            合同性成本不含税,
            合同性成本直投不含税,
            合同性成本除地价外直投不含税,
            合同性成本开发前期费不含税,
            合同性成本建筑安装工程费不含税,
            合同性成本红线内配套费不含税,
            合同性成本政府收费不含税,
            合同性成本不可预见费不含税,
            合同性成本土地款不含税,
            合同性成本营销费用不含税,
            合同性成本管理费用不含税,
            合同性成本财务费用不含税,
            -- 降本目标
            降本任务,
            直投降本任务,
            除地价外直投降本任务,
            营销费用降本任务 ,
            管理费用降本任务 ,
            财务费用降本任务,

            --设计变更
            合同总金额 ,
            总变更率 ,
            变更总金额,
            合同金额,
            现场签证累计发生比例 ,
            现场签证累计发生金额 ,
            设计变更累计发生比例 ,
            设计变更累计发生金额 ,
            -- 总包
            总包合同总金额 ,
            总包总变更率 ,
            总包变更总金额,
            总包合同金额,
            总包现场签证累计发生比例 ,
            总包现场签证累计发生金额 ,
            总包设计变更累计发生比例 ,
            总包设计变更累计发生金额 ,
            -- 装修
            装修合同总金额,
            装修总变更率,
            装修变更总金额,
            装修合同金额,
            装修现场签证累计发生比例,
            装修现场签证累计发生金额,
            装修设计变更累计发生比例,
            装修设计变更累计发生金额,
            -- 园林
            园林合同总金额,
            园林总变更率,
            园林变更总金额,
            园林合同金额,
            园林现场签证累计发生比例,
            园林现场签证累计发生金额,
            园林设计变更累计发生比例,
            园林设计变更累计发生金额,
            -- 其他
            其他合同总金额,
            其他总变更率,
            其他变更总金额,
            其他合同金额,
            其他现场签证累计发生比例,
            其他现场签证累计发生金额,
            其他设计变更累计发生比例,
            其他设计变更累计发生金额  
        )
          SELECT bi.组织架构父级ID,
              bi.组织架构ID,
              bi.组织架构名称,
              bi.组织架构编码,
              bi.组织架构类型,
              SUM(ISNULL(目标成本, 0)) AS 目标成本,
              SUM(ISNULL(目标成本直投, 0)) AS 目标成本直投,
              SUM(ISNULL(目标成本除地价外直投, 0)) AS 目标成本除地价外直投,
              sum(isnull(目标成本开发前期费,0)) as 目标成本开发前期费,
              sum(isnull(目标成本建筑安装工程费,0)) as 目标成本建筑安装工程费,
              sum(isnull(目标成本红线内配套费,0)) as 目标成本红线内配套费,
              sum(isnull(目标成本政府收费,0)) as 目标成本政府收费,
              sum(isnull(目标成本不可预见费,0)) as 目标成本不可预见费,
              SUM(ISNULL(目标成本营销费用, 0)) AS 目标成本营销费用,
              SUM(ISNULL(目标成本管理费用, 0)) AS 目标成本管理费用,
              SUM(ISNULL(目标成本财务费用, 0)) AS 目标成本财务费用,
              SUM(ISNULL(目标成本不含税, 0)) AS 目标成本不含税,
              SUM(ISNULL(目标成本直投不含税, 0)) AS 目标成本直投不含税,
              SUM(ISNULL(目标成本除地价外直投不含税, 0)) AS 目标成本除地价外直投不含税,
              sum(isnull(目标成本开发前期费不含税,0)) as 目标成本开发前期费不含税,
              sum(isnull(目标成本建筑安装工程费不含税,0)) as 目标成本建筑安装工程费不含税,
              sum(isnull(目标成本红线内配套费不含税,0)) as 目标成本红线内配套费不含税,
              sum(isnull(目标成本政府收费不含税,0)) as 目标成本政府收费不含税,
              sum(isnull(目标成本不可预见费不含税,0)) as 目标成本不可预见费不含税,
              SUM(ISNULL(目标成本营销费用不含税, 0)) AS 目标成本营销费用不含税,
              SUM(ISNULL(目标成本管理费用不含税, 0)) AS 目标成本管理费用不含税,
              SUM(ISNULL(目标成本财务费用不含税, 0)) AS 目标成本财务费用不含税,
              SUM(ISNULL(动态成本, 0)) AS 动态成本,
              SUM(ISNULL(动态成本直投, 0)) AS 动态成本直投,
              SUM(ISNULL(动态成本除地价外直投, 0)) AS 动态成本除地价外直投,
              sum(isnull(动态成本开发前期费,0)) as 动态成本开发前期费,
              sum(isnull(动态成本建筑安装工程费,0)) as 动态成本建筑安装工程费,
              sum(isnull(动态成本红线内配套费,0)) as 动态成本红线内配套费,
              sum(isnull(动态成本政府收费,0)) as 动态成本政府收费,
              sum(isnull(动态成本不可预见费,0)) as 动态成本不可预见费,
              SUM(ISNULL(动态成本营销费用, 0)) AS 动态成本营销费用,
              SUM(ISNULL(动态成本管理费用, 0)) AS 动态成本管理费用,
              SUM(ISNULL(动态成本财务费用, 0)) AS 动态成本财务费用,
              --不含税
              SUM(ISNULL(动态成本不含税, 0)) AS 动态成本不含税,
              SUM(ISNULL(动态成本直投不含税, 0)) AS 动态成本直投不含税,
              SUM(ISNULL(动态成本除地价外直投不含税, 0)) AS 动态成本除地价外直投不含税,
              sum(isnull(动态成本开发前期费不含税,0)) as 动态成本开发前期费不含税,
              sum(isnull(动态成本建筑安装工程费不含税,0)) as 动态成本建筑安装工程费不含税,
              sum(isnull(动态成本红线内配套费不含税,0)) as 动态成本红线内配套费不含税,
              sum(isnull(动态成本政府收费不含税,0)) as 动态成本政府收费不含税,
              sum(isnull(动态成本不可预见费不含税,0)) as 动态成本不可预见费不含税,
              SUM(ISNULL(动态成本营销费用不含税, 0)) AS 动态成本营销费用不含税,
              SUM(ISNULL(动态成本管理费用不含税, 0)) AS 动态成本管理费用不含税,
              SUM(ISNULL(动态成本财务费用不含税, 0)) AS 动态成本财务费用不含税,
              SUM(ISNULL(本年已发生除地价外直投, 0)) AS 本年已发生除地价外直投,
              SUM(ISNULL(累计营销费支出, 0)) AS 累计营销费支出,
              SUM(ISNULL(累计财务费支出, 0)) AS 累计财务费支出,
              SUM(ISNULL(累计管理费支出, 0)) AS 累计管理费支出,
              SUM(ISNULL(本年营销费支出, 0)) AS 本年营销费支出,
              SUM(ISNULL(本年财务费支出, 0)) AS 本年财务费支出,
              SUM(ISNULL(本年管理费支出, 0)) AS 本年管理费支出,
              SUM(ISNULL(本月营销费支出, 0)) AS 本月营销费支出,
              SUM(ISNULL(本月财务费支出, 0)) AS 本月财务费支出,
              SUM(ISNULL(本月管理费支出, 0)) AS 本月管理费支出,
              SUM(ISNULL(地价, 0)) AS 地价,
              SUM(ISNULL(除地价外直投本日发生金额, 0)) AS 除地价外直投本日发生金额,
              SUM(ISNULL(除地价外直投本月发生金额, 0)) AS 除地价外直投本月发生金额,
              SUM(ISNULL(除地价外直投本年发生金额, 0)) AS 除地价外直投本年发生金额,
              SUM(ISNULL(除地价外直投累计发生金额, 0)) AS 除地价外直投累计发生金额,
              SUM(ISNULL(年初目标成本, 0)) AS 年初目标成本,
              SUM(ISNULL(年初目标成本直投, 0)) AS 年初目标成本直投,
              SUM(ISNULL(年初目标成本除地价外直投, 0)) AS 年初目标成本除地价外直投,
              SUM(ISNULL(年初目标成本营销费用, 0)) AS 年初目标成本营销费用,
              SUM(ISNULL(年初目标成本管理费用, 0)) AS 年初目标成本管理费用,
              SUM(ISNULL(年初目标成本财务费用, 0)) AS 年初目标成本财务费用,
              -- 已发生成本
              SUM(ISNULL(已发生成本, 0)) AS 已发生成本,
              SUM(ISNULL(已发生成本直投, 0)) AS 已发生成本直投,
              SUM(ISNULL(已发生成本除地价外直投, 0)) AS 已发生成本除地价外直投,
              SUM(ISNULL(已发生成本开发前期费,0)) as 已发生成本开发前期费, 
              SUM(ISNULL(已发生成本建筑安装工程费,0)) as 已发生成本建筑安装工程费, 
              SUM(ISNULL(已发生成本红线内配套费,0)) as 已发生成本红线内配套费, 
              SUM(ISNULL(已发生成本政府收费,0)) as 已发生成本政府收费, 
              SUM(ISNULL(已发生成本不可预见费,0)) as 已发生成本不可预见费, 
              SUM(ISNULL(已发生成本土地款, 0)) AS 已发生成本土地款,
              SUM(ISNULL(已发生成本营销费用, 0)) AS 已发生成本营销费用,
              SUM(ISNULL(已发生成本管理费用, 0)) AS 已发生成本管理费用,
              SUM(ISNULL(已发生成本财务费用, 0)) AS 已发生成本财务费用,
              SUM(ISNULL(已发生成本不含税, 0)) AS 已发生成本不含税,
              SUM(ISNULL(已发生成本直投不含税, 0)) AS 已发生成本直投不含税,
              SUM(ISNULL(已发生成本除地价外直投不含税, 0)) AS 已发生成本除地价外直投不含税,
              SUM(ISNULL(已发生成本开发前期费不含税,0)) as 已发生成本开发前期费不含税, 
              SUM(ISNULL(已发生成本建筑安装工程费不含税,0)) as 已发生成本建筑安装工程费不含税, 
              SUM(ISNULL(已发生成本红线内配套费不含税,0)) as 已发生成本红线内配套费不含税, 
              SUM(ISNULL(已发生成本政府收费不含税,0)) as 已发生成本政府收费不含税, 
              SUM(ISNULL(已发生成本不可预见费不含税,0)) as 已发生成本不可预见费不含税, 
              SUM(ISNULL(已发生成本土地款不含税, 0)) AS 已发生成本土地款不含税,
              SUM(ISNULL(已发生成本营销费用不含税, 0)) AS 已发生成本营销费用不含税,
              SUM(ISNULL(已发生成本管理费用不含税, 0)) AS 已发生成本管理费用不含税,
              SUM(ISNULL(已发生成本财务费用不含税, 0)) AS 已发生成本财务费用不含税,
              -- 待发生成本
              SUM(ISNULL(待发生成本, 0)) AS 待发生成本,
              SUM(ISNULL(待发生成本直投, 0)) AS 待发生成本直投,
              SUM(ISNULL(待发生成本除地价外直投, 0)) AS 待发生成本除地价外直投,
              sum(isnull(待发生成本开发前期费,0)) as 待发生成本开发前期费,
              sum(isnull(待发生成本建筑安装工程费,0)) as 待发生成本建筑安装工程费,
              sum(isnull(待发生成本红线内配套费,0)) as 待发生成本红线内配套费,
              sum(isnull(待发生成本政府收费,0)) as 待发生成本政府收费,
              sum(isnull(待发生成本不可预见费,0)) as 待发生成本不可预见费,
              SUM(ISNULL(待发生成本营销费用, 0)) AS 待发生成本营销费用,
              SUM(ISNULL(待发生成本管理费用, 0)) AS 待发生成本管理费用,
              SUM(ISNULL(待发生成本财务费用, 0)) AS 待发生成本财务费用,
              SUM(ISNULL(待发生成本不含税, 0)) AS 待发生成本不含税,
              SUM(ISNULL(待发生成本直投不含税, 0)) AS 待发生成本直投不含税,
              SUM(ISNULL(待发生成本除地价外直投不含税, 0)) AS 待发生成本除地价外直投不含税,
              sum(isnull(待发生成本开发前期费不含税,0)) as 待发生成本开发前期费不含税,
              sum(isnull(待发生成本建筑安装工程费不含税,0)) as 待发生成本建筑安装工程费不含税,
              sum(isnull(待发生成本红线内配套费不含税,0)) as 待发生成本红线内配套费不含税,
              sum(isnull(待发生成本政府收费不含税,0)) as 待发生成本政府收费不含税,
              sum(isnull(待发生成本不可预见费不含税,0)) as 待发生成本不可预见费不含税,
              SUM(ISNULL(待发生成本营销费用不含税, 0)) AS 待发生成本营销费用不含税,
              SUM(ISNULL(待发生成本管理费用不含税, 0)) AS 待发生成本管理费用不含税,
              SUM(ISNULL(待发生成本财务费用不含税, 0)) AS 待发生成本财务费用不含税,
              -- 已支付成本
              SUM(ISNULL(已支付成本, 0)) AS 已支付成本,
              SUM(ISNULL(已支付成本直投, 0)) AS 已支付成本直投,
              SUM(ISNULL(已支付成本除地价外直投, 0)) AS 已支付成本除地价外直投,
              sum(isnull(已支付成本开发前期费,0)) as 已支付成本开发前期费,
              sum(isnull(已支付成本建筑安装工程费,0)) as 已支付成本建筑安装工程费,
              sum(isnull(已支付成本红线内配套费,0)) as 已支付成本红线内配套费,
              sum(isnull(已支付成本政府收费,0)) as 已支付成本政府收费,
              sum(isnull(已支付成本不可预见费,0)) as 已支付成本不可预见费,
              SUM(ISNULL(已支付成本土地款, 0)) AS 已支付成本土地款,
              SUM(ISNULL(已支付成本营销费用, 0)) AS 已支付成本营销费用,
              SUM(ISNULL(已支付成本管理费用, 0)) AS 已支付成本管理费用,
              SUM(ISNULL(已支付成本财务费用, 0)) AS 已支付成本财务费用,
              --不含税
              SUM(ISNULL(已支付成本不含税, 0)) AS 已支付成本不含税,
              SUM(ISNULL(已支付成本直投不含税, 0)) AS 已支付成本直投不含税,
              SUM(ISNULL(已支付成本除地价外直投不含税, 0)) AS 已支付成本除地价外直投不含税,
              sum(isnull(已支付成本开发前期费不含税,0)) as 已支付成本开发前期费不含税,
              sum(isnull(已支付成本建筑安装工程费不含税,0)) as 已支付成本建筑安装工程费不含税,
              sum(isnull(已支付成本红线内配套费不含税,0)) as 已支付成本红线内配套费不含税,
              sum(isnull(已支付成本政府收费不含税,0)) as 已支付成本政府收费不含税,
              sum(isnull(已支付成本不可预见费不含税,0)) as 已支付成本不可预见费不含税,
              SUM(ISNULL(已支付成本土地款不含税, 0)) AS 已支付成本土地款不含税,
              SUM(ISNULL(已支付成本营销费用不含税, 0)) AS 已支付成本营销费用不含税,
              SUM(ISNULL(已支付成本管理费用不含税, 0)) AS 已支付成本管理费用不含税,
              SUM(ISNULL(已支付成本财务费用不含税, 0)) AS 已支付成本财务费用不含税,
              -- 合同性成本
              SUM(ISNULL(合同性成本, 0)) AS 合同性成本,
              SUM(ISNULL(合同性成本直投, 0)) AS 合同性成本直投,
              SUM(ISNULL(合同性成本除地价外直投, 0)) AS 合同性成本除地价外直投,
              SUM(ISNULL(合同性成本开发前期费,0)) as 合同性成本开发前期费,
              SUM(ISNULL(合同性成本建筑安装工程费,0)) as 合同性成本建筑安装工程费,
              SUM(ISNULL(合同性成本红线内配套费,0)) as 合同性成本红线内配套费,
              SUM(ISNULL(合同性成本政府收费,0)) as 合同性成本政府收费,
              SUM(ISNULL(合同性成本不可预见费,0)) as 合同性成本不可预见费,
              SUM(ISNULL(合同性成本土地款, 0)) AS 合同性成本土地款,
              SUM(ISNULL(合同性成本营销费用, 0)) AS 合同性成本营销费用,
              SUM(ISNULL(合同性成本管理费用, 0)) AS 合同性成本管理费用,
              SUM(ISNULL(合同性成本财务费用, 0)) AS 合同性成本财务费用,
              SUM(ISNULL(合同性成本不含税, 0)) AS 合同性成本不含税,
              SUM(ISNULL(合同性成本直投不含税, 0)) AS 合同性成本直投不含税,
              SUM(ISNULL(合同性成本除地价外直投不含税, 0)) AS 合同性成本除地价外直投不含税,
              SUM(ISNULL(合同性成本开发前期费不含税,0)) as 合同性成本开发前期费不含税,
              SUM(ISNULL(合同性成本建筑安装工程费不含税,0)) as 合同性成本建筑安装工程费不含税,
              SUM(ISNULL(合同性成本红线内配套费不含税,0)) as 合同性成本红线内配套费不含税,
              SUM(ISNULL(合同性成本政府收费不含税,0)) as 合同性成本政府收费不含税,
              SUM(ISNULL(合同性成本不可预见费不含税,0)) as 合同性成本不可预见费不含税,
              SUM(ISNULL(合同性成本土地款不含税, 0)) AS 合同性成本土地款不含税,
              SUM(ISNULL(合同性成本营销费用不含税, 0)) AS 合同性成本营销费用不含税,
              SUM(ISNULL(合同性成本管理费用不含税, 0)) AS 合同性成本管理费用不含税,
              SUM(ISNULL(合同性成本财务费用不含税, 0)) AS 合同性成本财务费用不含税,
               -- 降本目标
            sum(isnull(降本任务,0)) as 降本任务 ,
            sum(isnull(直投降本任务,0)) as 直投降本任务,
            sum(isnull(除地价外直投降本任务,0)) as 除地价外直投降本任务,
            sum(isnull(营销费用降本任务,0)) as  营销费用降本任务,
            sum(isnull(管理费用降本任务,0)) as  管理费用降本任务,
            sum(isnull(财务费用降本任务,0)) as  财务费用降本任务,

            sum(isnull(b.合同总金额,0)) as 合同总金额 ,
            case when sum(isnull(b.合同总金额,0)) = 0 then 0 else   sum(isnull(b.变更总金额,0)) / sum(isnull(b.合同总金额,0)) end as 总变更率 ,
            sum(isnull(b.变更总金额,0)) as 变更总金额,
            sum(isnull(b.合同金额,0)) as 合同金额,
            case when (sum(isnull(b.现场签证累计发生金额,0)) + sum(isnull(b.合同金额,0)) ) =0 then 0  else  sum(isnull(b.现场签证累计发生金额,0)) /  (sum(isnull(b.现场签证累计发生金额,0)) + sum(isnull(b.合同金额,0)) ) end as 现场签证累计发生比例 ,
            sum(isnull(b.现场签证累计发生金额,0))  as 现场签证累计发生金额 ,
            case when (sum(isnull(b.设计变更累计发生金额,0)) + sum(isnull(b.合同金额,0)) ) =0 then 0  else  sum(isnull(b.设计变更累计发生金额,0)) /  (sum(isnull(b.设计变更累计发生金额,0)) + sum(isnull(b.合同金额,0)) ) end as  设计变更累计发生比例 ,
            sum(isnull(b.设计变更累计发生金额,0))  as 设计变更累计发生金额 ,
            -- 总包
            sum(isnull(b.总包合同总金额,0))  as 总包合同总金额 ,
            case when sum(isnull(b.总包合同总金额,0)) = 0 then 0 else sum(isnull(b.总包变更总金额,0)) / sum(isnull(b.总包合同总金额,0)) end as  总包总变更率 ,
            sum(isnull(b.总包变更总金额,0)) as 总包变更总金额,
            sum(isnull(b.总包合同金额,0)) as 总包合同金额,
            case when (sum(isnull(b.总包现场签证累计发生金额,0)) + sum(isnull(b.总包合同金额,0)) ) =0 then 0  else  sum(isnull(b.总包现场签证累计发生金额,0)) /  (sum(isnull(b.总包现场签证累计发生金额,0)) + sum(isnull(b.总包合同金额,0)) ) end  as 总包现场签证累计发生比例 ,
            sum(isnull(b.总包现场签证累计发生金额,0))  as 总包现场签证累计发生金额 ,
            case when (sum(isnull(b.总包设计变更累计发生金额,0)) + sum(isnull(b.总包合同金额,0)) ) =0 then 0  else  sum(isnull(b.总包设计变更累计发生金额,0)) /  (sum(isnull(b.总包设计变更累计发生金额,0)) + sum(isnull(b.总包合同金额,0)) ) end as  总包设计变更累计发生比例 ,
            sum(isnull(b.总包设计变更累计发生金额,0))  as 总包设计变更累计发生金额 ,
            -- 装修
            sum(isnull(b.装修合同总金额,0))  as 装修合同总金额,
            case when sum(isnull(b.装修合同总金额,0)) = 0 then 0 else   sum(isnull(b.装修变更总金额,0)) / sum(isnull(b.装修合同总金额,0)) end as 装修总变更率,
            sum(isnull(b.装修变更总金额,0)) as 装修变更总金额,
            sum(isnull(b.装修合同金额,0)) as 装修合同金额,
            case when (sum(isnull(b.装修现场签证累计发生金额,0)) + sum(isnull(b.装修合同金额,0)) ) =0 then 0  else  sum(isnull(b.装修现场签证累计发生金额,0)) /  (sum(isnull(b.装修现场签证累计发生金额,0)) + sum(isnull(b.装修合同金额,0)) ) end  as 装修现场签证累计发生比例 ,
            sum(isnull(b.装修现场签证累计发生金额,0))  as 装修现场签证累计发生金额 ,
            case when (sum(isnull(b.装修设计变更累计发生金额,0)) + sum(isnull(b.装修合同金额,0)) ) =0 then 0  else  sum(isnull(b.装修设计变更累计发生金额,0)) /  (sum(isnull(b.装修设计变更累计发生金额,0)) + sum(isnull(b.装修合同金额,0)) ) end as  装修设计变更累计发生比例 ,
            sum(isnull(b.装修设计变更累计发生金额,0))  as 装修设计变更累计发生金额 ,
            -- 园林
            sum(isnull(b.园林合同总金额,0))  as 园林合同总金额,
            case when sum(isnull(b.园林合同总金额,0)) = 0 then 0 else   sum(isnull(b.园林变更总金额,0)) / sum(isnull(b.园林合同总金额,0)) end as 园林总变更率,
            sum(isnull(b.园林变更总金额,0)) as 园林变更总金额,
            sum(isnull(b.园林合同金额,0)) as 园林合同金额,
            case when (sum(isnull(b.园林现场签证累计发生金额,0)) + sum(isnull(b.园林合同金额,0)) ) =0 then 0  else  sum(isnull(b.园林现场签证累计发生金额,0)) /  (sum(isnull(b.园林现场签证累计发生金额,0)) + sum(isnull(b.园林合同金额,0)) ) end  as 园林现场签证累计发生比例 ,
            sum(isnull(b.园林现场签证累计发生金额,0))  as 园林现场签证累计发生金额 ,
            case when (sum(isnull(b.园林设计变更累计发生金额,0)) + sum(isnull(b.园林合同金额,0)) ) =0 then 0  else  sum(isnull(b.园林设计变更累计发生金额,0)) /  (sum(isnull(b.园林设计变更累计发生金额,0)) + sum(isnull(b.园林合同金额,0)) ) end as  园林设计变更累计发生比例 ,
            sum(isnull(b.园林设计变更累计发生金额,0))  as 园林设计变更累计发生金额 ,
            -- 其他
            sum(isnull(b.其他合同总金额,0))  as 其他合同总金额,
            case when sum(isnull(b.其他合同总金额,0)) = 0 then 0 else   sum(isnull(b.其他变更总金额,0)) / sum(isnull(b.其他合同总金额,0)) end as 其他总变更率,
            sum(isnull(b.其他变更总金额,0)) as 其他变更总金额,
            sum(isnull(b.其他合同金额,0)) as 其他合同金额,
            case when (sum(isnull(b.其他现场签证累计发生金额,0)) + sum(isnull(b.其他合同金额,0)) ) =0 then 0  else  sum(isnull(b.其他现场签证累计发生金额,0)) /  (sum(isnull(b.其他现场签证累计发生金额,0)) + sum(isnull(b.其他合同金额,0)) ) end  as 其他现场签证累计发生比例 ,
            sum(isnull(b.其他现场签证累计发生金额,0))  as 其他现场签证累计发生金额 ,
            case when (sum(isnull(b.其他设计变更累计发生金额,0)) + sum(isnull(b.其他合同金额,0)) ) =0 then 0  else  sum(isnull(b.其他设计变更累计发生金额,0)) /  (sum(isnull(b.其他设计变更累计发生金额,0)) + sum(isnull(b.其他合同金额,0)) ) end as  其他设计变更累计发生比例 ,
            sum(isnull(b.其他设计变更累计发生金额,0))  as 其他设计变更累计发生金额 
          FROM ydkb_dthz_wq_deal_cbinfo b
          INNER JOIN ydkb_BaseInfo bi ON bi.组织架构ID = b.组织架构父级ID 
          WHERE b.组织架构类型 = @baseinfo
          GROUP BY bi.组织架构父级ID,
              bi.组织架构ID,
              bi.组织架构名称,
              bi.组织架构编码,
              bi.组织架构类型;

        SET @baseinfo = @baseinfo - 1;

    END;

    SELECT *
      FROM dbo.ydkb_dthz_wq_deal_cbinfo;

    --删除临时表
    DROP TABLE #proj_cb,
        #pro_cdjwzt,
        #yt,
        #yt_cb,#bb,#cb_cdjwzt,#cdjwzt,#dj,#nc_cb,#proj_cblowerRisk,#ProjHtAlter,#HtAlter,#hyb

END;

