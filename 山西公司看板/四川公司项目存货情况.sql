/*
2024-11-22 剩余货值剔除掉两个项目的部分楼栋的剩余货值
一个是4910项目的中地块、南地块、北地块三个地块的所有面积和货值
另外一个是4918项目的“南地块住宅5号楼、7号楼、8号楼”
*/
--创建临时表,统计各项目和公司的货值和面积汇总数据
SELECT 公司Guid,
       o.organizationname AS 公司名称,
       a.organizationname AS 项目名称,
       a.Orgguid AS projguid,
       CASE WHEN a.Orgguid IS NULL THEN 公司Guid ELSE a.Orgguid END AS orgguid,
       CASE WHEN a.Orgguid IS NULL THEN '公司' ELSE '项目' END AS orgtype,
       SUM(总货值) AS 总货值,
       SUM(总货量面积) AS 总货量面积,
       SUM(剩余货值) AS 剩余货值,
       SUM(剩余货量面积) AS 剩余货量面积,
       SUM(CASE WHEN ManageModeName IN ('二级开发') THEN 存货余额计划口径 ELSE 0 END) AS 存货余额计划口径,
       SUM(CASE WHEN ManageModeName IN ('二级开发') THEN 存货面积计划口径 ELSE 0 END) AS 存货面积计划口径
INTO #ch
FROM s_rptzjlkb_DtSaleValuesProj a
LEFT JOIN data_wide_dws_s_Dimension_Organization o ON a.公司Guid = o.orgguid
GROUP BY GROUPING SETS((公司Guid, a.Orgguid, o.organizationname, a.organizationname),
                      (公司Guid, o.organizationname))

--存货取证口径统计,按项目和公司维度统计各类型存货数据			 
SELECT p.buguid,
       a.projguid,
       CASE WHEN a.projguid IS NULL THEN '公司' ELSE '项目' END AS orgtype,
       CASE WHEN a.projguid IS NULL THEN p.buguid ELSE a.projguid END AS orgguid,
       SUM(CASE WHEN DATEDIFF(dd, b.FactNotOpen, GETDATE()) > 0 THEN 剩余可售货值金额 ELSE 0 END) AS 存货金额取证口径,
       SUM(CASE WHEN DATEDIFF(dd, b.FactNotOpen, GETDATE()) > 0 THEN 剩余可售货值面积 ELSE 0 END) AS 存货面积取证口径,
       SUM(CASE WHEN ProjStatus = '正常' THEN 未售货值 ELSE 0 END) AS 剩余货值,
       SUM(CASE WHEN ProjStatus = '正常' THEN 未售面积 ELSE 0 END) AS 剩余面积,
       SUM(CASE WHEN ProjStatus = '正常' AND topproductname IN ('住宅', '高级住宅') THEN 未售货值 ELSE 0 END) AS 住宅剩余货值,
       SUM(CASE WHEN ProjStatus = '正常' AND topproductname NOT IN ('住宅', '高级住宅', '地下室/车库') THEN 未售货值 ELSE 0 END) AS 商业剩余货值,
       SUM(CASE WHEN ProjStatus = '正常' AND topproductname = '地下室/车库' THEN 未售货值 ELSE 0 END) AS 车位剩余货值,
       SUM(CASE WHEN ProjStatus = '正常' AND topproductname IN ('住宅', '高级住宅') THEN 未售面积 ELSE 0 END) AS 住宅剩余面积,
       SUM(CASE WHEN ProjStatus = '正常' AND topproductname NOT IN ('住宅', '高级住宅', '地下室/车库') THEN 未售面积 ELSE 0 END) AS 商业剩余面积,
       SUM(CASE WHEN ProjStatus = '正常' AND topproductname = '地下室/车库' THEN 未售面积 ELSE 0 END) AS 车位剩余面积,
       SUM(CASE WHEN ProjStatus = '正常' AND topproductname = '地下室/车库' THEN 未售套数 ELSE 0 END) AS 车位剩余个数
INTO #chqz
FROM data_wide_dws_jh_LdHzOverview a
INNER JOIN data_wide_dws_mdm_Project p ON a.projguid = p.projguid 
INNER JOIN data_wide_dws_mdm_Building b ON a.BuildingGUID = b.BuildingGUID AND b.bldtype = '产品楼栋'
where   not EXISTS (
    SELECT BuildingGUID 
    FROM data_wide_dws_jh_LdHzOverview 
    WHERE ProjGUID = 'BCF91594-0604-E911-80BF-E61F13C57837' 
    AND (gcbldname LIKE '中地块%' 
        OR gcbldname LIKE '南地块%'
        OR gcbldname LIKE '北地块%')
    AND data_wide_dws_jh_LdHzOverview.BuildingGUID = a.BuildingGUID
    UNION ALL
    SELECT BuildingGUID 
    FROM data_wide_dws_jh_LdHzOverview 
    WHERE ProjGUID = '1A7402F0-816E-EA11-80B8-0A94EF7517DD'
    AND (gcbldname LIKE '%南地块住宅5号楼%'
        OR gcbldname LIKE '%南地块住宅7号楼%'
        OR gcbldname LIKE '%南地块住宅8号楼%')
    AND data_wide_dws_jh_LdHzOverview.BuildingGUID = a.BuildingGUID
)
GROUP BY GROUPING SETS((p.buguid), (p.buguid, a.projguid))

--产成品（含预计产成品）统计
SELECT pj.buguid,
       pj.projguid,
       CASE WHEN pj.projguid IS NULL THEN pj.buguid ELSE pj.projguid END AS orgguid,
       CASE WHEN pj.projguid IS NULL THEN '公司' ELSE '项目' END AS orgtype,
       SUM(CASE WHEN YEAR(ISNULL(SJjgbadate, YJjgbadate)) <= YEAR(GETDATE()) THEN syhz ELSE 0 END) AS 本年预计实际产成品货值,
       SUM(CASE WHEN YEAR(ISNULL(SJjgbadate, YJjgbadate)) <= YEAR(GETDATE()) THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0) ELSE 0 END) AS 本年预计实际产成品面积,
       SUM(CASE WHEN ld.SJjgbadate <= GETDATE() THEN syhz ELSE 0 END) AS 产成品货值金额,
       SUM(CASE WHEN ld.SJjgbadate <= GETDATE() THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0) ELSE 0 END) AS 产成品货值面积
INTO #ccp
FROM data_wide_dws_s_p_lddbamj ld
INNER JOIN data_wide_dws_mdm_Project pj ON ld.ProjGUID = pj.ProjGUID
LEFT JOIN (SELECT DISTINCT ParentProjGUID AS projguid FROM dbo.data_wide_s_NoControl) nc ON pj.ProjGUID = nc.projguid
WHERE level = 2 AND nc.projguid IS NULL
GROUP BY GROUPING SETS((pj.buguid, pj.projguid), (pj.buguid))

--已开工未售统计
DECLARE @ykg TABLE
(
    buguid UNIQUEIDENTIFIER,
    orgguid UNIQUEIDENTIFIER,
    已开工未售货值 MONEY,
    已开工未售面积 MONEY
)

INSERT INTO @ykg
SELECT pj.buguid,
       CASE WHEN pj.projguid IS NULL THEN pj.buguid ELSE pj.projguid END AS orgguid,
       SUM(CASE 
           WHEN hz.topproductname = '地下室/车库' AND (hz.FactFinishDate IS NOT NULL OR hz.FactOpenDate IS NOT NULL) THEN ISNULL(hz.未售货值, 0)
           WHEN hz.topproductname <> '地下室/车库' THEN ISNULL(hz.未售货值, 0) - ISNULL(hz.未开工未售货值, 0)
           ELSE 0 
       END) / 100000000 AS 已开工未售货值,
       SUM(CASE
           WHEN hz.topproductname = '地下室/车库' AND (hz.FactFinishDate IS NOT NULL OR hz.FactOpenDate IS NOT NULL) THEN ISNULL(hz.未售面积, 0)
           WHEN hz.topproductname <> '地下室/车库' THEN ISNULL(hz.未售面积, 0) - ISNULL(hz.未开工未售面积, 0)
           ELSE 0
       END) / 10000 AS 已开工未售面积
FROM dbo.data_wide_dws_jh_LdHzOverview hz
INNER JOIN dbo.data_wide_dws_mdm_Project pj ON hz.ProjGUID = pj.ProjGUID
GROUP BY GROUPING SETS((pj.buguid, pj.projguid), (pj.buguid))

--统计近三个月签约数据
SELECT pj.buguid,
       CASE WHEN pj.projguid IS NULL THEN pj.buguid ELSE pj.projguid END AS orgguid,
       SUM(Sale.CNetArea) / 3.0 / 10000.0 AS 近三个月平均签约面积,
       SUM(Sale.CNetAmount) / 3.0 / 100000000.0 AS 近三个月平均签约金额
INTO #jsy
FROM data_wide_dws_s_SalesPerf Sale
INNER JOIN data_wide_dws_mdm_Project pj ON pj.ProjGUID = Sale.ParentProjGUID
INNER JOIN data_wide_dws_s_Dimension_Organization do ON do.OrgGUID = pj.XMSSCSGSGUID
INNER JOIN (
    --判断各项目的首次销售时间
    SELECT ParentProjGUID,
           MIN(StatisticalDate) AS skDate
    FROM dbo.data_wide_dws_s_SalesPerf WITH (NOLOCK)
    GROUP BY ParentProjGUID
) sk ON sk.ParentProjGUID = Sale.ParentProjGUID
WHERE Sale.StatisticalDate BETWEEN DATEADD(mm, -3, CONVERT(nvarchar(100), GETDATE(), 111)) AND GETDATE()
GROUP BY GROUPING SETS((pj.BUGUID, pj.ProjGUID), (pj.BUGUID))

--汇总最终结果
SELECT a.公司GUID,
       a.公司名称,
       a.项目名称,
       a.orgtype,
       a.orgguid,
       a.projguid,
       a.剩余货值,
       a.剩余货量面积,
       b.近三个月平均签约面积,
       a.存货面积计划口径 AS 存货货量面积,
       ykg.已开工未售面积,
       ISNULL(已开工未售货值, 0) AS 已开工未售货值,
       ISNULL(a.存货余额计划口径, 0) AS 存货余额计划口径,
       b.近三个月平均签约金额,
       chqz.剩余货值 AS 剩余货值_宽表,
       chqz.剩余面积 AS 剩余面积_宽表,
       CASE WHEN ISNULL(b.近三个月平均签约面积, 0) = 0 THEN 0 ELSE ISNULL(存货面积计划口径, 0) / ISNULL(b.近三个月平均签约面积, 0) END AS 存销比_面积,
       CASE WHEN ISNULL(b.近三个月平均签约面积, 0) = 0 THEN 0 ELSE ISNULL(已开工未售面积, 0) / ISNULL(b.近三个月平均签约面积, 0) END AS 产销比_面积,
       CASE WHEN ISNULL(b.近三个月平均签约金额, 0) = 0 THEN 0 ELSE ISNULL(存货余额计划口径, 0) / ISNULL(b.近三个月平均签约金额, 0) END AS 存销比_金额,
       CASE WHEN ISNULL(b.近三个月平均签约金额, 0) = 0 THEN 0 ELSE ISNULL(已开工未售货值, 0) / ISNULL(b.近三个月平均签约金额, 0) END AS 产销比_金额,
       chqz.存货金额取证口径,
       chqz.存货面积取证口径,
       ccp.本年预计实际产成品货值,
       ccp.本年预计实际产成品面积,
       ccp.产成品货值金额,
       ccp.产成品货值面积,
       chqz.住宅剩余货值,
       chqz.商业剩余货值,
       chqz.车位剩余货值,
       chqz.住宅剩余面积,
       chqz.商业剩余面积,
       chqz.车位剩余面积,
       chqz.车位剩余个数
FROM #ch a
INNER JOIN @ykg ykg ON ykg.orgguid = a.orgguid
LEFT JOIN #jsy b ON a.orgguid = b.orgguid
LEFT JOIN #chqz chqz ON chqz.orgguid = a.orgguid
LEFT JOIN #ccp ccp ON ccp.orgguid = a.orgguid

--清理临时表
DROP TABLE #jsy, #ch, #chqz, #ccp