--   SELECT p.ProjGUID,
--          VersionGUID,
--          VersionTypeName,
--          '上报版' AS dw_ver
--     INTO #dw_ver
--       FROM mdm_Project p
--      INNER JOIN
--            (
--                SELECT v.VersionGUID,
--                    v.VersionTypeName,
--                    v.ProjGUID,
--                    ROW_NUMBER() OVER (PARTITION BY p.ProjGUID
--                                       ORDER BY CASE
--                                                    WHEN ISNULL(VersionTypeName, '') = '二次定位上报版' THEN
--                                                        3
--                                                    WHEN ISNULL(VersionTypeName, '') = '定位上报版' THEN
--                                                        1
--                                                    ELSE
--                                                        0
--                                                END DESC,
--                                           CreateDate DESC
--                                      ) num
--                  FROM dbo.mdm_DWProjVer v
--                 INNER JOIN #mdm_project p
--                     ON p.ProjGUID = v.ProjGUID
--            ) ver  ON ver.ProjGUID = p.ProjGUID  AND num = 1
--       WHERE DevelopmentCompanyGUID IN
--             (
--                 SELECT value FROM dbo.fn_Split2(@developmentguid, ',')
--             )
--             AND p.Level = 2
--             AND VersionTypeName LIKE '%上报版%'
--     UNION ALL
--     SELECT p.ProjGUID,
--         VersionGUID,
--         VersionTypeName,
--         '批复版' AS dw_ver
--       FROM mdm_Project p
--      INNER JOIN
--            (
--                SELECT v.VersionGUID,
--                    v.VersionTypeName,
--                    v.ProjGUID,
--                    ROW_NUMBER() OVER (PARTITION BY p.ProjGUID
--                                       ORDER BY CASE
--                                                    WHEN ISNULL(VersionTypeName, '') = '二次定位批复版' THEN
--                                                        4
--                                                    WHEN ISNULL(VersionTypeName, '') = '定位批复版' THEN
--                                                        2
--                                                    ELSE
--                                                        0
--                                                END DESC,
--                                           CreateDate DESC
--                                      ) num
--                  FROM dbo.mdm_DWProjVer v
--                 INNER JOIN #mdm_project p ON p.ProjGUID = v.ProjGUID
--            ) ver
--          ON ver.ProjGUID = p.ProjGUID AND num = 1
--       WHERE DevelopmentCompanyGUID IN
--             (
--                 SELECT value FROM dbo.fn_Split2(@developmentguid, ',')
--             )
--             AND p.Level = 2
--             AND VersionTypeName LIKE '%批复版%';



-- 新获取项目获取后20天内未上报定位，推送预警
-- 公司	项目	获取时间	应上报定位时间	状态	备注
-- 预警规则：未到上报时间
-- 应上报时间少于3天
-- 已逾期

SELECT 
    '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' AS buguid, 
    dc.DevelopmentCompanyName AS 公司,
    mp.ProjName AS 项目,
    mp.AcquisitionDate AS 获取时间,
    DATEADD(DAY, 20, mp.AcquisitionDate) AS 应上报定位时间, 
    CASE 
        WHEN GETDATE() < DATEADD(DAY, 17, mp.AcquisitionDate) THEN '绿灯'  
        WHEN DATEDIFF(DAY, GETDATE(), DATEADD(DAY, 20, mp.AcquisitionDate)) BETWEEN 0 AND 3 THEN '黄灯'
        WHEN DATEDIFF(DAY, GETDATE(), DATEADD(DAY, 20, mp.AcquisitionDate)) < 0 THEN '红灯'
    END AS 状态,
    CASE 
        WHEN GETDATE() < DATEADD(DAY, 17, mp.AcquisitionDate) THEN '未到上报时间'  
        WHEN DATEDIFF(DAY, GETDATE(), DATEADD(DAY, 20, mp.AcquisitionDate)) BETWEEN 0 AND 3 THEN '应上报时间少于3天'
        WHEN DATEDIFF(DAY, GETDATE(), DATEADD(DAY, 20, mp.AcquisitionDate)) < 0 THEN '已逾期' + 
        convert(varchar(10), DATEDIFF(DAY, DATEADD(DAY, 20, mp.AcquisitionDate), GETDATE())) + '天'  
    END AS 备注
FROM 
    mdm_Project mp
LEFT JOIN 
    p_DevelopmentCompany dc ON mp.DevelopmentCompanyGUID = dc.DevelopmentCompanyGUID
LEFT JOIN 
    (
        SELECT 
            ProjGUID, 
            MAX(ISNULL(ApproveDate, CreateDate)) AS dwDate 
        FROM 
            mdm_DWProjVer 
        GROUP BY 
            ProjGUID
    ) dw ON dw.ProjGUID = mp.ProjGUID
WHERE 
    mp.Level = 2 
    AND dw.dwDate IS NULL 
    AND DATEDIFF(YEAR, mp.AcquisitionDate, GETDATE()) IN (0, 1)
    -- 剔除掉OA系统已上报定位的项目
    and mp.ProjGUID not in (
    'C416DD16-C1D7-EE11-B3A4-F40270D39969',
    '97D74542-0ADA-EE11-B3A4-F40270D39969',
    'F3603B5D-C206-EF11-B3A4-F40270D39969',
    'ACE3DBD2-A718-EF11-B3A4-F40270D39969',
    '3AC73D80-4638-EF11-B3A4-F40270D39969',
    '980DF6B4-2839-EF11-B3A4-F40270D39969',
    '9570D5F8-1F44-EF11-B3A4-F40270D39969',
    '9E291CCE-A345-EF11-B3A4-F40270D39969',
    '5FB0C8B1-2956-EF11-B3A5-F40270D39969',
    '836F34C5-506B-EF11-B3A5-F40270D39969',
    '07093FFF-4E7E-EF11-B3A5-F40270D39969',
    '13666543-7B94-EF11-B3A5-F40270D39969',
    'A862EDDC-0495-EF11-B3A5-F40270D39969',
    '88AAA857-41BC-EF11-B3A5-F40270D39969',
    'CB543CAD-6DC2-EF11-B3A5-F40270D39969',
    'A632F5EB-31C3-EF11-B3A6-F40270D39969',
    '1BCF8FE5-46C7-EF11-B3A6-F40270D39969',
    '4A287E14-39D9-EF11-B3A6-F40270D39969',
    'FA793E95-5AD9-EF11-B3A6-F40270D39969',
    '66C7786C-C7ED-EF11-B3A6-F40270D39969',
    '49424682-42F3-EF11-B3A6-F40270D39969',
    'F75D9398-0100-F011-B3A6-F40270D39969',
    'BD2DE217-CC7E-EF11-B3A5-F40270D39969'
    )

--- ///////////////2.0 剔除部分已经上报定位的项目///////////////////////////////////////
SELECT 
    '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' AS buguid, 
	mp.ProjGUID,
    dc.DevelopmentCompanyName AS 公司,
    mp.ProjName AS 项目,
    mp.AcquisitionDate AS 获取时间,
    DATEADD(DAY, 20, mp.AcquisitionDate) AS 应上报定位时间, 
    CASE 
        WHEN GETDATE() < DATEADD(DAY, 17, mp.AcquisitionDate) THEN '绿灯'  
        WHEN DATEDIFF(DAY, GETDATE(), DATEADD(DAY, 20, mp.AcquisitionDate)) BETWEEN 0 AND 3 THEN '黄灯'
        WHEN DATEDIFF(DAY, GETDATE(), DATEADD(DAY, 20, mp.AcquisitionDate)) < 0 THEN '红灯'
    END AS 状态,
    CASE 
        WHEN GETDATE() < DATEADD(DAY, 17, mp.AcquisitionDate) THEN '未到上报时间'  
        WHEN DATEDIFF(DAY, GETDATE(), DATEADD(DAY, 20, mp.AcquisitionDate)) BETWEEN 0 AND 3 THEN '应上报时间少于3天'
        WHEN DATEDIFF(DAY, GETDATE(), DATEADD(DAY, 20, mp.AcquisitionDate)) < 0 THEN '已逾期' + 
        convert(varchar(10), DATEDIFF(DAY, DATEADD(DAY, 20, mp.AcquisitionDate), GETDATE())) + '天'  
    END AS 备注
FROM 
    mdm_Project mp
LEFT JOIN 
    p_DevelopmentCompany dc ON mp.DevelopmentCompanyGUID = dc.DevelopmentCompanyGUID
LEFT JOIN 
    (
        SELECT 
            ProjGUID, 
            MAX(ISNULL(ApproveDate, CreateDate)) AS dwDate 
        FROM 
            mdm_DWProjVer 
        GROUP BY 
            ProjGUID
    ) dw ON dw.ProjGUID = mp.ProjGUID
WHERE 
    mp.Level = 2 
    AND dw.dwDate IS NULL 
    AND DATEDIFF(YEAR, mp.AcquisitionDate, GETDATE()) IN (0, 1)
    -- 剔除掉OA系统已上报定位的项目
    and mp.ProjGUID not in (
    'C416DD16-C1D7-EE11-B3A4-F40270D39969',
    '97D74542-0ADA-EE11-B3A4-F40270D39969',
    'F3603B5D-C206-EF11-B3A4-F40270D39969',
    'ACE3DBD2-A718-EF11-B3A4-F40270D39969',
    '3AC73D80-4638-EF11-B3A4-F40270D39969',
    '980DF6B4-2839-EF11-B3A4-F40270D39969',
    '9570D5F8-1F44-EF11-B3A4-F40270D39969',
    '9E291CCE-A345-EF11-B3A4-F40270D39969',
    '5FB0C8B1-2956-EF11-B3A5-F40270D39969',
    '836F34C5-506B-EF11-B3A5-F40270D39969',
    '07093FFF-4E7E-EF11-B3A5-F40270D39969',
    '13666543-7B94-EF11-B3A5-F40270D39969',
    'A862EDDC-0495-EF11-B3A5-F40270D39969',
    '88AAA857-41BC-EF11-B3A5-F40270D39969',
    'CB543CAD-6DC2-EF11-B3A5-F40270D39969',
    'A632F5EB-31C3-EF11-B3A6-F40270D39969',
    '1BCF8FE5-46C7-EF11-B3A6-F40270D39969',
    '4A287E14-39D9-EF11-B3A6-F40270D39969',
    'FA793E95-5AD9-EF11-B3A6-F40270D39969',
    '66C7786C-C7ED-EF11-B3A6-F40270D39969',
    '49424682-42F3-EF11-B3A6-F40270D39969',
    'F75D9398-0100-F011-B3A6-F40270D39969',
	'229923BC-9EC1-EF11-B3A5-F40270D39969',
	'B65AE1EF-A5E7-EF11-B3A6-F40270D39969',
	'895DF029-CE15-F011-B3A6-F40270D39969',
	'AD240DD9-BF2B-F011-B3A6-F40270D39969'
    )
