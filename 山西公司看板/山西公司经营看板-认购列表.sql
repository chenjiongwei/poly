-- 查询项目认购和签约相关数据
SELECT   
    -- 公司组织相关字段
    isnull(o.aftername,do1.ParentOrganizationName) as ParentOrganizationName,  -- 上级组织名称
    isnull(o.afterguid,do1.ParentOrganizationguid) as ParentOrganizationguid, -- 上级组织GUID
    do1.OrganizationName,  -- 组织名称
    
    -- 项目基本信息
    pj.TgProjCode,  -- 项目编码
    pj.SpreadName+'('+pj.[TgProjCode]+')' SpreadName,  -- 项目推广名称(带编码)
    pj.projguid,  -- 项目GUID
    
    -- 项目名称处理逻辑
    case  
        when pj.tgprojcode ='6004' then '晋中和府' 
        when isnull(p.SpreadName,pj.SpreadName) like '%青江和府%' then '青江和府' 
        else replace(replace(replace(replace(replace(replace(replace(replace(replace(
            isnull(p.SpreadName,pj.SpreadName),
            '创展国宾和煦花园','国宾和煦'),
            '椿实.',''),
            '成都',''),
            '保利.',''),
            '保利',''),
            '德阳',''),
            '宜宾',''),
            '遂宁',''),
            '市','') 
    end AS ProjName,	
    -- replace(replace(replace(replace(isnull(p.SpreadName,pj.SpreadName),'成都',''),'保利',''),'德阳',''),'宜宾',''),'遂宁','') AS ProjName,		 
    
    -- 签约相关指标
    SUM(ISNULL(hl.本年实际签约全口径,0)) AS 本年签约,  -- 本年实际签约金额
    SUM(ISNULL(t.签约任务, 0)) AS 签约任务,  -- 签约任务金额
    CASE 
        WHEN SUM(ISNULL(t.签约任务, 0)) = 0 THEN 0 
        ELSE ISNULL(SUM(hl.本年实际签约全口径),0) / SUM(ISNULL(t.签约任务, 0))
    END AS 本年签约率,  -- 本年签约完成率
    
    -- 利润相关指标
    ISNULL(SUM(isnull(M.本年净利润签约,0))/NULLIF(sum(isnull(M.本年签约金额不含税,0)),0),0) 本年签约净利率,  -- 本年签约净利率
    SUM(YLGH.税前利润账面口径) 税前利润账面口径,  -- 税前利润(账面口径)
    SUM(YLGH.税前利润账面口径扣减股权溢价) 税前利润账面口径扣减股权溢价,  -- 税前利润(扣减股权溢价)
    
    -- 认购相关指标
    sum(isnull(hl.本年认购金额,0)) as 年度认购金额,  -- 年度累计认购金额
    sum(isnull(hl.本月认购金额,0)) as 月度认购金额,  -- 本月认购金额
    sum(isnull(hl.本月认购套数,0)) as 月度认购套数,  -- 本月认购套数
    sum(isnull(hl.本日认购套数,0)) as 本日认购套数,  -- 本日认购套数
    sum(isnull(hl.本日认购金额,0)) as 本日认购金额   -- 本日认购金额

-- 关联项目主数据表
FROM dbo.data_wide_dws_mdm_Project pj
    -- 关联组织维度表
    INNER JOIN dbo.data_wide_dws_s_Dimension_Organization do1 
        ON pj.XMSSCSGSGUID = do1.OrgGUID
    -- 关联公司合并信息表    
    LEFT JOIN s_rptzjlkb_OrgInfo_chg o 
        ON do1.ParentOrganizationGUID = o.beforeGuid ---公司合并
    
    -- 关联实际签约数据
    LEFT JOIN (
        SELECT 
            sp.ParentProjGUID,
            -- 计算本年实际签约金额
            SUM(case 
                when DATEDIFF(yy, GETDATE(), sp.StatisticalDate) = 0 
                then (ISNULL(sp.CNetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0)) / 100000000.00 
                else 0 
            end) AS 本年实际签约全口径,
            -- 计算本年认购金额
            SUM(case 
                when DATEDIFF(yy, GETDATE(), sp.StatisticalDate) = 0  
                then (ISNULL(sp.ONetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0)) / 100000000.00 
                else 0 
            end) AS 本年认购金额,
            -- 计算本月认购金额
            SUM(case 
                when DATEDIFF(mm, GETDATE(), sp.StatisticalDate) = 0  
                then (ISNULL(sp.ONetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0)) / 100000000.00 
                else 0 
            end) AS 本月认购金额,                   
            -- 计算本月认购套数
            SUM(case 
                when DATEDIFF(mm, GETDATE(), sp.StatisticalDate) = 0  
                and  sp.TopProductTypeName <> '地下室/车库'
                then ISNULL(sp.ONetCount, 0) + ISNULL(sp.SpecialCNetCount, 0)  
                else 0 
            end) AS 本月认购套数,     
            -- 计算本日认购金额
            SUM(case 
                when DATEDIFF(day, GETDATE(), sp.StatisticalDate) = 0  
                then (ISNULL(sp.ONetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0)) / 100000000.00 
                else 0 
            end) AS 本日认购金额,                   
            -- 计算本日认购套数
            SUM(case 
                when DATEDIFF(day, GETDATE(), sp.StatisticalDate) = 0 
                and  sp.TopProductTypeName <> '地下室/车库'
                then ISNULL(sp.ONetCount, 0) + ISNULL(sp.SpecialCNetCount, 0)  
                else 0 
            end) AS 本日认购套数     
        FROM data_wide_dws_s_SalesPerf sp
        --WHERE DATEDIFF(yy, GETDATE(), sp.StatisticalDate) = 0
        GROUP BY sp.ParentProjGUID
    ) hl ON hl.ParentProjGUID = pj.ProjGUID

    -- 关联签约任务数据
    LEFT JOIN (
        SELECT 
            sbv.OrganizationGUID,
            ISNULL(sbv.BudgetContractAmount, 0) / 100000000.00 签约任务
        FROM data_wide_dws_s_SalesBudgetVerride sbv
        WHERE sbv.BudgetDimension = '年度'
            AND sbv.BudgetDimensionValue = CONVERT(VARCHAR(4), YEAR(GETDATE()))
    ) t ON t.OrganizationGUID = pj.ProjGUID

    -- 关联父级项目信息
    LEFT JOIN dbo.data_wide_dws_mdm_Project p 
        ON p.ProjGUID = pj.ParentGUID

    -- 关联净利润数据
    LEFT JOIN (
        SELECT 
            projguid,
            case 
                when orgguid='6CBA0828-D863-4EA8-B594-DE3E11DDF573' then 本年净利润签约 
                else 本年净利润签约_不含异常业态 
            end 本年净利润签约,
            case 
                when orgguid='6CBA0828-D863-4EA8-B594-DE3E11DDF573' then 本年签约金额不含税_不含异常业态 
                else 本年签约金额不含税 
            end 本年签约金额不含税 
        from data_wide_dws_qt_s_M002项目级净利汇总表 
        where DATEDIFF(DD,GETDATE(),QXDATE)=0
    ) M ON M.ProjGUID = pj.ProjGUID

    -- 关联利润成本数据
    LEFT JOIN (
        select distinct 
            项目guid,
            税前利润账面口径,
            税前利润账面口径扣减股权溢价 
        from dw_f_TopProJect_ProfitCost_ylgh
    ) YLGH ON YLGH.项目guid = pj.ProjGUID

-- 筛选条件
WHERE (1=1) 
    and pj.level = 2  -- 只查二级项目
    AND do1.ParentOrganizationName IN ('四川公司','山西公司')  -- 限定公司范围
    AND do1.OrganizationName NOT IN ('非我司操盘', '一级整理')  -- 排除特定组织
    --and pj.ProjGUID = '268b2fcd-a74e-eb11-b398-f40270d39969'
    --AND pj.TgProjCode in ('1274','1273','12401','1272','1271','1270','4403','1269','1268','1267','1266','1265','1259','10501','3501','1201')

-- 分组字段
GROUP BY 
    isnull(o.aftername,do1.ParentOrganizationName),
    do1.OrganizationName,
    isnull(p.SpreadName,pj.SpreadName),
    pj.TgProjCode,
    isnull(o.afterguid,do1.ParentOrganizationguid),
    pj.SpreadName+'('+pj.[TgProjCode]+')',
    pj.projguid
--having SUM(ISNULL(t.签约任务, 0)) >=0.1

UNION ALL 

-- 长春公司数据查询(结构同上,只是筛选条件不同)
SELECT   
    isnull(o.aftername,do1.ParentOrganizationName) as ParentOrganizationName,
    isnull(o.afterguid,do1.ParentOrganizationguid)ParentOrganizationguid,
    do1.OrganizationName,
    pj.TgProjCode,
    pj.SpreadName+'('+pj.[TgProjCode]+')' SpreadName,
    pj.projguid,
    isnull(p.SpreadName,pj.SpreadName) AS ProjName,	 
    SUM(ISNULL(hl.本年实际签约全口径,0)) AS 本年签约,
    SUM(ISNULL(t.签约任务, 0)) AS 签约任务,
    CASE 
        WHEN SUM(ISNULL(t.签约任务, 0)) = 0 THEN 0 
        ELSE ISNULL(SUM(hl.本年实际签约全口径),0) / SUM(ISNULL(t.签约任务, 0))
    END AS 本年签约率,
    ISNULL(SUM(isnull(M.本年净利润签约,0))/NULLIF(sum(isnull(M.本年签约金额不含税,0)),0),0) 本年签约净利率,
    SUM(YLGH.税前利润账面口径) 税前利润账面口径,
    SUM(YLGH.税前利润账面口径扣减股权溢价) 税前利润账面口径扣减股权溢价,
    sum(isnull(hl.本年认购金额,0)) as 年度认购金额,
    sum(isnull(hl.本月认购金额,0)) as 月度认购金额,
    sum(isnull(hl.本月认购套数,0)) as 月度认购套数,
    sum(isnull(hl.本日认购套数,0)) as 本日认购套数,
    sum(isnull(hl.本日认购金额,0)) as 本日认购金额
FROM dbo.data_wide_dws_mdm_Project pj
    LEFT JOIN (
        SELECT 
            projguid,
            case 
                when orgguid='6CBA0828-D863-4EA8-B594-DE3E11DDF573' then 本年净利润签约 
                else 本年净利润签约_不含异常业态 
            end 本年净利润签约,
            case 
                when orgguid='6CBA0828-D863-4EA8-B594-DE3E11DDF573' then 本年签约金额不含税_不含异常业态 
                else 本年签约金额不含税 
            end 本年签约金额不含税 
        from data_wide_dws_qt_s_M002项目级净利汇总表 
        where DATEDIFF(DD,GETDATE(),QXDATE)=0
    ) M ON M.ProjGUID = pj.ProjGUID
    INNER JOIN dbo.data_wide_dws_s_Dimension_Organization do1 
        ON pj.XMSSCSGSGUID = do1.OrgGUID
    LEFT JOIN s_rptzjlkb_OrgInfo_chg o 
        ON do1.ParentOrganizationGUID = o.beforeGuid ---公司合并
    --实际签约
    LEFT JOIN (
        SELECT 
            sp.ParentProjGUID,
            SUM(ISNULL(sp.CNetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0)) / 100000000.00 AS 本年实际签约全口径,
            SUM(case 
                when DATEDIFF(yy, GETDATE(), sp.StatisticalDate) = 0  
                then (ISNULL(sp.ONetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0)) / 100000000.00 
                else 0 
            end) AS 本年认购金额,
            SUM(case 
                when DATEDIFF(mm, GETDATE(), sp.StatisticalDate) = 0  
                then (ISNULL(sp.ONetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0) ) / 100000000.00 
                else 0 
            end) AS 本月认购金额,                   
            SUM(case 
                when DATEDIFF(mm, GETDATE(), sp.StatisticalDate) = 0  
                and  sp.TopProductTypeName <> '地下室/车库'
                then ISNULL(sp.ONetCount, 0) + ISNULL(sp.SpecialCNetCount, 0)  
                else 0 
            end) AS 本月认购套数,    -- 认购套数不含车位业态 
            SUM(case 
                when DATEDIFF(day, GETDATE(), sp.StatisticalDate) = 0  
                then  (ISNULL(sp.ONetAmount, 0) + ISNULL(sp.SpecialCNetAmount, 0)) / 100000000.00 
                else 0 
            end) AS 本日认购金额,                   
            SUM(case 
                when DATEDIFF(day, GETDATE(), sp.StatisticalDate) = 0  
                and  sp.TopProductTypeName <> '地下室/车库'
                then ISNULL(sp.ONetCount, 0) + ISNULL(sp.SpecialCNetCount, 0)  
                else 0 
            end) AS 本日认购套数                      
        FROM data_wide_dws_s_SalesPerf sp
        -- WHERE DATEDIFF(yy, GETDATE(), sp.StatisticalDate) = 0
        GROUP BY sp.ParentProjGUID
    ) hl ON hl.ParentProjGUID = pj.ProjGUID
    --签约任务
    LEFT JOIN (
        SELECT 
            sbv.OrganizationGUID,
            ISNULL(sbv.BudgetContractAmount, 0) / 100000000.00 签约任务
        FROM data_wide_dws_s_SalesBudgetVerride sbv
        WHERE sbv.BudgetDimension = '年度'
            AND sbv.BudgetDimensionValue = CONVERT(VARCHAR(4), YEAR(GETDATE()))
    ) t ON t.OrganizationGUID = pj.ProjGUID
    LEFT JOIN dbo.data_wide_dws_mdm_Project p 
        ON p.ProjGUID = pj.ParentGUID
    LEFT JOIN (
        select distinct 
            项目guid,
            税前利润账面口径,
            税前利润账面口径扣减股权溢价 
        from dw_f_TopProJect_ProfitCost_ylgh
    ) YLGH ON YLGH.项目guid = pj.ProjGUID
WHERE (1=1) 
    and pj.level = 2
    AND do1.ParentOrganizationName IN ('长春公司')  -- 只查长春公司数据
    AND do1.OrganizationName NOT IN ('非我司操盘', '一级整理')
    --and pj.ProjGUID = '268b2fcd-a74e-eb11-b398-f40270d39969'
    --AND pj.TgProjCode in ('1274','1273','12401','1272','1271','1270','4403','1269','1268','1267','1266','1265','1259','10501','3501','1201')
GROUP BY 
    isnull(o.aftername,do1.ParentOrganizationName),
    do1.OrganizationName,
    isnull(p.SpreadName,pj.SpreadName),
    pj.TgProjCode,
    isnull(o.afterguid,do1.ParentOrganizationguid),
    pj.SpreadName+'('+pj.[TgProjCode]+')',
    pj.projguid
ORDER BY 本年签约 DESC  -- 按本年签约金额降序排序
