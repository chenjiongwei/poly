
-- 区域
SELECT  '营销大区' AS 层级,
        '全部区域' AS 层级名称,  --区域 
        0 层级排序 
UNION ALL 
SELECT  '营销大区' AS 层级,
        t.营销事业部 AS 层级名称 , --区域 
        row_number() over( order by t.营销事业部) 层级排序 
FROM    data_tb_hn_yxpq t
        INNER JOIN data_wide_dws_mdm_Project p ON t.项目Guid = p.projguid
        INNER JOIN data_wide_dws_s_Dimension_Organization o ON p.XMSSCSGSGUID = o.OrgGUID
GROUP BY t.营销事业部  
UNION  ALL 
SELECT  '组团' AS 层级,
        '全部组团' AS 层级名称 , --区域 
         0 as 层级排序
UNION  ALL 
SELECT  '组团' AS 层级,
        t.营销片区 AS 层级名称 , --区域 
        row_number() over( order by t.营销片区) as 层级排序
FROM    data_tb_hn_yxpq t
        INNER JOIN data_wide_dws_mdm_Project p ON t.项目Guid = p.projguid
        INNER JOIN data_wide_dws_s_Dimension_Organization o ON p.XMSSCSGSGUID = o.OrgGUID
GROUP BY 营销片区  
UNION  ALL 
SELECT  '组团' AS 层级,
        '数字营销' AS 层级名称 , --区域 
        99 as 层级排序
UNION  ALL 
SELECT  '项目' AS 层级,
		'全部项目' AS 层级名称, 
        0 as 层级排序
UNION  ALL 
SELECT  '项目' AS 层级,
		ISNULL(推广名称,p.SpreadName) AS 层级名称,
        row_number() over( order by ISNULL(推广名称,p.SpreadName)) as 排序字段
FROM    data_tb_hn_yxpq t
        INNER JOIN data_wide_dws_mdm_Project p ON t.项目Guid = p.projguid
        INNER JOIN data_wide_dws_s_Dimension_Organization o ON p.XMSSCSGSGUID = o.OrgGUID
		WHERE  ISNULL(营销事业部,'') <>'其他' OR  ISNULL(营销片区,'') <> '其他'
GROUP BY  ISNULL(推广名称,p.SpreadName)



SELECT  '营销大区' AS 层级,
        t.营销事业部 AS 层级名称 , --区域 
        row_number() over( order by t.营销事业部) 层级排序 
FROM    data_tb_hn_yxpq t
        INNER JOIN data_wide_dws_mdm_Project p ON t.项目Guid = p.projguid
        INNER JOIN data_wide_dws_s_Dimension_Organization o ON p.XMSSCSGSGUID = o.OrgGUID
GROUP BY t.营销事业部  
UNION  ALL 
SELECT  '组团' AS 层级,
        t.营销片区 AS 层级名称 , --区域 
        row_number() over( order by t.营销片区) as 层级排序
FROM    data_tb_hn_yxpq t
        INNER JOIN data_wide_dws_mdm_Project p ON t.项目Guid = p.projguid
        INNER JOIN data_wide_dws_s_Dimension_Organization o ON p.XMSSCSGSGUID = o.OrgGUID
GROUP BY 营销片区  
UNION  ALL 
SELECT  '项目' AS 层级,
		'全部项目' AS 层级名称, 
        0 as 层级排序 
UNION  ALL 
SELECT  '项目' AS 层级,
		ISNULL(推广名称,p.SpreadName) AS 层级名称,
        row_number() over( order by ISNULL(推广名称,p.SpreadName)) as 排序字段
FROM    data_tb_hn_yxpq t
        INNER JOIN data_wide_dws_mdm_Project p ON t.项目Guid = p.projguid
        INNER JOIN data_wide_dws_s_Dimension_Organization o ON p.XMSSCSGSGUID = o.OrgGUID
		WHERE  ISNULL(营销事业部,'') <>'其他' OR  ISNULL(营销片区,'') <> '其他'
GROUP BY  ISNULL(推广名称,p.SpreadName)

-- 货量分析筛选
SELECT  '营销大区' AS 层级,
        t.营销事业部 AS 层级名称 , --区域 
        row_number() over( order by t.营销事业部) 层级排序 
FROM    data_tb_hn_yxpq t
        INNER JOIN data_wide_dws_mdm_Project p ON t.项目Guid = p.projguid
        INNER JOIN data_wide_dws_s_Dimension_Organization o ON p.XMSSCSGSGUID = o.OrgGUID
GROUP BY t.营销事业部  
UNION  ALL 
SELECT  '组团' AS 层级,
        t.营销片区 AS 层级名称 , --区域 
        row_number() over( order by t.营销片区) as 层级排序
FROM    data_tb_hn_yxpq t
        INNER JOIN data_wide_dws_mdm_Project p ON t.项目Guid = p.projguid
        INNER JOIN data_wide_dws_s_Dimension_Organization o ON p.XMSSCSGSGUID = o.OrgGUID
GROUP BY 营销片区  
UNION  ALL 
SELECT  '项目' AS 层级,
		'全部项目' AS 层级名称, 
        0 as 层级排序 
UNION  ALL 
SELECT  '项目' AS 层级,
		ISNULL(推广名称,p.SpreadName) AS 层级名称,
        row_number() over( order by ISNULL(推广名称,p.SpreadName)) as 排序字段
FROM    data_tb_hn_yxpq t
        INNER JOIN data_wide_dws_mdm_Project p ON t.项目Guid = p.projguid
        INNER JOIN data_wide_dws_s_Dimension_Organization o ON p.XMSSCSGSGUID = o.OrgGUID
		WHERE  ISNULL(营销事业部,'') <>'其他' OR  ISNULL(营销片区,'') <> '其他'
GROUP BY  ISNULL(推广名称,p.SpreadName)

-- 内控分析
SELECT  '营销大区' AS 层级,
        t.营销事业部 AS 层级名称 , --区域 
        row_number() over( order by t.营销事业部) 层级排序 
FROM    data_tb_hn_yxpq t
        INNER JOIN data_wide_dws_mdm_Project p ON t.项目Guid = p.projguid
        INNER JOIN data_wide_dws_s_Dimension_Organization o ON p.XMSSCSGSGUID = o.OrgGUID
GROUP BY t.营销事业部  
UNION  ALL 
SELECT  '组团' AS 层级,
        t.营销片区 AS 层级名称 , --区域 
        row_number() over( order by t.营销片区) as 层级排序
FROM    data_tb_hn_yxpq t
        INNER JOIN data_wide_dws_mdm_Project p ON t.项目Guid = p.projguid
        INNER JOIN data_wide_dws_s_Dimension_Organization o ON p.XMSSCSGSGUID = o.OrgGUID
GROUP BY 营销片区  
UNION  ALL 
SELECT  '项目' AS 层级,
		'全部项目' AS 层级名称, 
        0 as 层级排序 
UNION  ALL 
SELECT  '项目' AS 层级,
		ISNULL(推广名称,p.SpreadName) AS 层级名称,
        row_number() over( order by ISNULL(推广名称,p.SpreadName)) as 排序字段
FROM    data_tb_hn_yxpq t
        INNER JOIN data_wide_dws_mdm_Project p ON t.项目Guid = p.projguid
        INNER JOIN data_wide_dws_s_Dimension_Organization o ON p.XMSSCSGSGUID = o.OrgGUID
		WHERE  ISNULL(营销事业部,'') <>'其他' OR  ISNULL(营销片区,'') <> '其他'
GROUP BY  ISNULL(推广名称,p.SpreadName)