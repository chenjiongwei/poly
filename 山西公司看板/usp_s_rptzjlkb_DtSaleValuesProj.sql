USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_rptzjlkb_DtSaleValuesProj]    Script Date: 2024/11/22 18:42:16 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[usp_s_rptzjlkb_DtSaleValuesProj]
AS
/*
功能：总经理看板PC报表,获取030103项目货值金额
创建人：chenjw
创建时间：20200818
[usp_s_rptzjlkb_DtSaleValuesProj]
修改：chenjw 20201106
1、成都公司存货需要统计所有项目，不用排除非操盘项目，华南公司需要排除掉操盘项目
修改:chenjw 20210728
增加商办产品的货值金额和货量面积统计
更改部分:新增项目的管理模式字段(华南公司运营大屏)
*/
BEGIN

    SELECT p.BUGUID AS 公司Guid,
           CASE
               WHEN p.XMSSCSGSGUID IS NULL THEN
                   p.BUGUID
               ELSE
                   p.XMSSCSGSGUID
           END AS buguid,
           LOWER(p.ProjGUID) AS orgguid,
           p.SpreadName AS OrganizationName,
		   p.ManageModeName,
           SUM(ISNULL(总货值金额, 0)) / 100000000.0 AS 总货值,
           SUM(ISNULL(hz.总货值面积, 0)) / 10000.0 AS 总货量面积,
           SUM(ISNULL(hz.已售金额, 0)) / 100000000.0 AS 已售货值,
           SUM(ISNULL(hz.已售面积, 0)) / 10000.0 AS 已售货量面积,
           SUM(ISNULL(hz.未售货值, 0)) / 100000000.0 AS 剩余货值,
           SUM(ISNULL(hz.未售面积, 0)) / 10000.0 AS 剩余货量面积,
           SUM(ISNULL(hz.剩余可售货值金额, 0)) / 100000000.0 AS 剩余可售货值,
           SUM(ISNULL(hz.剩余可售货值面积, 0)) / 10000.0 AS 剩余可售货量面积,
           SUM(ISNULL(hz.未完工_达预售条件未取证货值金额, 0) + ISNULL(hz.已完工_达预售条件未取证货值金额, 0)
		   -ISNULL(hz.未完工_达预售条件未取证已推货值金额,0) -ISNULL(hz.已完工_达预售条件未取证已推货值金额,0)) / 100000000.0 AS 工程达到未获证货值,
           SUM(ISNULL(hz.未完工_达预售条件未取证货量面积, 0) + ISNULL(hz.已完工_达预售条件未取证货量面积, 0)
		   -ISNULL(hz.未完工_达预售条件未取证已推货量面积, 0) - ISNULL(hz.已完工_达预售条件未取证已推货量面积, 0)) / 10000.0 AS 工程达到未获证货量面积,
           SUM(ISNULL(hz.未完工_获证未推货值金额, 0) + ISNULL(hz.已完工_获证未推货值金额, 0)) / 100000000.0 AS 获证未推货值,
           SUM(ISNULL(hz.未完工_获证未推货量面积, 0) + ISNULL(hz.已完工_获证未推货量面积, 0)) / 10000.0 AS 获证未推货量面积,
           SUM(ISNULL(hz.未完工_已推未售货值金额, 0) + ISNULL(hz.已完工_已推未售货值金额, 0)) / 100000000.0 AS 已推未售货值,
           SUM(ISNULL(hz.未完工_已推未售货量面积, 0) + ISNULL(hz.已完工_已推未售货量面积, 0)) / 10000.0 AS 已推未售货量面积,
           SUM(   CASE
                      WHEN hz.topproductname IN ( '写字楼', '公寓', '商业', '企业会所' ) THEN
                          ISNULL(hz.剩余可售货值金额, 0)
                      ELSE
                          0
                  END
              ) / 100000000.0 AS 商办剩余可售货值,
           SUM(   CASE
                      WHEN hz.topproductname IN ( '写字楼', '公寓', '商业', '企业会所' ) THEN
                          ISNULL(hz.剩余可售货值面积, 0)
                      ELSE
                          0
                  END
              ) / 10000.0 商办剩余可售货量面积
			  
    INTO #hz
    FROM dbo.data_wide_dws_mdm_Project p
        LEFT JOIN dbo.data_wide_dws_jh_YtHzOverview hz ON p.ProjGUID = hz.ProjGUID
    WHERE p.Level = 2 AND p.ProjStatus ='正常'
    GROUP BY p.BUGUID,
             CASE
                 WHEN p.XMSSCSGSGUID IS NULL THEN
                     p.BUGUID
                 ELSE
                     p.XMSSCSGSGUID
             END,
             p.ProjGUID,
             p.SpreadName,
			 p.ManageModeName
			 ;
    --输出查询结果
    SELECT ISNULL(ch.afterGuid, hz.公司Guid) AS 公司Guid,
           hz.buguid,
           LOWER(hz.orgguid) AS orgguid,
           hz.OrganizationName,
           总货值,
           总货量面积,
           已售货值,
           已售货量面积,
           剩余货值,
           剩余货量面积,
           CASE
               WHEN ISNULL(nd.ndtask, 0) = 0 THEN
                   0
               ELSE
                   剩余货值 * 1.0 / nd.ndtask
           END 货量保障系数,
           剩余可售货值 AS 存货余额计划口径, --工程达到未获证货值+ 已推未售货值 +获证未推货值
           剩余可售货量面积 AS 存货面积计划口径,
           CASE
               WHEN ISNULL(t.qyamount, 0) = 0 THEN
                   0
               ELSE
                   剩余可售货值 * 1.0 / ISNULL(t.qyamount, 0)
           END AS 存货去化周期,
           工程达到未获证货值,
           工程达到未获证货量面积,
           获证未推货值,
           获证未推货量面积,
           已推未售货值,             --已竣工+未竣工
           已推未售货量面积,            --已竣工+未竣工
		   商办剩余可售货值,
		   商办剩余可售货量面积,
		   hz.ManageModeName
    INTO #s_rptzjlkb_DtSaleValuesProj
    FROM #hz hz
        LEFT JOIN
        (
            SELECT r.ParentProjGUID AS orgguid,
                   SUM(r.CjRmbTotal) * 1.0 / 300000000 AS qyamount
            FROM dbo.data_wide_s_RoomoVerride r
            WHERE r.FangPanTime IS NOT NULL
                  AND DATEDIFF(yy, r.FangPanTime, GETDATE()) >= 0
                  AND r.Status = '签约'
                  AND DATEDIFF(mm, r.QsDate, GETDATE()) < 3
            GROUP BY r.ParentProjGUID
        ) t
            ON t.orgguid = hz.orgguid
        --获取本年签约任务值
        LEFT JOIN
        (
            SELECT sbv.OrganizationGUID,
                   SUM(ISNULL(BudgetContractAmount, 0)) / 100000000 AS ndtask
            FROM data_wide_dws_s_SalesBudgetVerride sbv
                INNER JOIN data_wide_dws_mdm_Project b
                    ON sbv.OrganizationGUID = b.ProjGUID
                LEFT JOIN data_wide_dws_s_Dimension_Organization do
                    ON do.OrgGUID = b.XMSSCSGSGUID
                LEFT JOIN data_wide_dws_s_Dimension_Organization do1
                    ON do1.OrgGUID = do.ParentOrganizationGUID
            WHERE BudgetDimension = '年度'
                  AND BudgetDimensionValue = CONVERT(VARCHAR(4), YEAR(GETDATE()))
            GROUP BY sbv.OrganizationGUID
        ) nd
            ON nd.OrganizationGUID = hz.orgguid
        LEFT JOIN s_rptzjlkb_OrgInfo_chg ch
            ON ch.beforeGuid = hz.公司Guid;

    --插入正式表
    DELETE FROM s_rptzjlkb_DtSaleValuesProj
    WHERE 1 = 1;

    INSERT INTO s_rptzjlkb_DtSaleValuesProj
    SELECT *
    FROM #s_rptzjlkb_DtSaleValuesProj;

    SELECT *
    FROM #s_rptzjlkb_DtSaleValuesProj;

    DROP TABLE #hz,#s_rptzjlkb_DtSaleValuesProj;

END;

