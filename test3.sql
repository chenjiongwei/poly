--缓存产品楼栋
SELECT  ms.SaleBldGUID ,
        '华南公司' buname ,
        p1.spreadname ,
        gc.GCBldGUID ,
        ms.BldCode ,
        gc.BldName gcBldName ,
        ISNULL(ms.UpBuildArea, 0) + ISNULL(ms.DownBuildArea, 0) zjm ,
        ms.UpBuildArea dsjm ,
        ms.DownBuildArea dxjm ,
        pr.ProductType ,
        pr.ProductName ,
        pr.BusinessType ,
        pr.IsSale ,
        pr.IsHold ,
        pr.STANDARD ,
        ms.UpNum ,
        ms.DownNum ,
        c.*
INTO    #ms
FROM    dbo.mdm_SaleBuild ms
        INNER JOIN mdm_Product pr ON pr.ProductGUID = ms.ProductGUID
        INNER JOIN mdm_GCBuild gc ON gc.GCBldGUID = ms.GCBldGUID
        LEFT JOIN mdm_project p ON gc.projguid = p.projguid
        LEFT JOIN mdm_project p1 ON p.parentprojguid = p1.projguid
        LEFT JOIN MyCost_Erp352.dbo.p_HkbBiddingBuilding2BuildingWork b ON ms.GCBldGUID = b.BuildingGUID
        LEFT JOIN MyCost_Erp352.dbo.jd_PlanTaskExecuteObjectForReport c ON b.budguid = c.ztguid
WHERE   p.developmentcompanyguid = 'AADC0FA7-9546-49C9-B64B-825056C828ED' 
and  isnull(c.是否停工,'') not in ('停工','缓建')

----竣备
--SELECT DISTINCT buname,
--       投管项目名称 + '-' + 关联工程楼栋 楼栋,
--       竣工备案计划完成时间,
--       CONVERT(CHAR, DATEDIFF(mm, 竣工备案计划完成时间, GETDATE())) 月,
--       ISNULL(竣工备案预计完成时间, 竣工备案计划完成时间) 预计,
--       ISNULL(集中交付实际完成时间, 集中交付计划完成时间) 交付,
--       spreadname + '-' + 关联工程楼栋 + '竣备：原节点' + 竣工备案计划完成时间 + '，已逾期超' + CONVERT(VARCHAR(2), DATEDIFF(mm, 竣工备案计划完成时间, GETDATE()))
--       + '个月'+ ';' 合并
--       --投管项目名称 + '-' + 关联工程楼栋 + '竣备：原节点' + 竣工备案计划完成时间 + '，已逾期超' + CONVERT(CHAR, DATEDIFF(mm, 竣工备案计划完成时间, GETDATE()))
--       --+ '个月，预计' + ISNULL(竣工备案预计完成时间, 竣工备案计划完成时间) + '完成；交付' + ISNULL(集中交付实际完成时间, 集中交付计划完成时间) + ';' 合并
--	   INTO #jb
--FROM #ms a
--WHERE DATEDIFF(dd, 竣工备案计划完成时间, GETDATE()) > 0
--      AND 竣工备案实际完成时间 IS NULL;

--SELECT b.buname,
--       竣备 = STUFF(
--            (
--                SELECT ',' + 合并 FROM #jb t WHERE t.buname = b.buname FOR XML PATH('')
--            ),
--            1,
--            1,
--            ''
--                 )
--INTO #jbresult
--FROM mybusinessunit a
--     INNER JOIN #jb b ON a.buname = b.buname
--GROUP BY b.buname;
--drop  table   #gc 
-- 剔除掉以下楼栋的逾期交付批次
select  
   GCBldGUID,BldCode,BldName
into   #gc
from  mdm_GCBuild where GCBldGUID in (
    '037F8327-F90F-40C9-9735-849DEF13C4F0',
    'C39487D5-87A4-4396-82EA-344816B9CF01',
    'FDA6DBC9-75E4-4E0B-ACC3-731AED8FA0B8', 
    '8B4550AF-6825-FBC0-AD8C-2AB8029558E9',
    '6059B7F0-59B5-4287-828A-80EAB382058F',
    '00A09357-2BA9-4A26-97CF-E9D5135C7AEC',
    '7F741580-3B80-46E0-9106-F5C4D91E8888'
)

SELECT  buname 公司名称 ,spreadname,gcBldName,
        --展示区
        SUM(CASE WHEN DATEDIFF(yy, 售楼部展示区正式开放计划完成时间, GETDATE()) = 0 THEN 1 ELSE 0 END) AS  '24年计划展示区' ,
        SUM(CASE WHEN DATEDIFF(yy, 售楼部展示区正式开放计划完成时间, GETDATE()) = 0 AND   售楼部展示区正式开放实际完成时间 IS NOT NULL THEN 1 ELSE 0 END) AS  '24年已完工展示区' ,
        CASE WHEN SUM(CASE WHEN YEAR(售楼部展示区正式开放计划完成时间) = 2024 THEN 1 ELSE 0 END) > 0 THEN
                 SUM(CASE WHEN DATEDIFF(yy, 售楼部展示区正式开放计划完成时间, GETDATE()) = 0 AND 售楼部展示区正式开放实际完成时间 IS NOT NULL THEN 1 ELSE 0 END) *1.0 / 
				 SUM(CASE WHEN DATEDIFF(yy, 售楼部展示区正式开放计划完成时间, GETDATE()) = 0 THEN 1 ELSE 0 END)
        END '24年计划展示区完成率' ,
        SUM(CASE WHEN DATEDIFF(mm, 售楼部展示区正式开放计划完成时间, GETDATE()) = 0 THEN 1 ELSE 0 END) AS  '24年7月计划展示区' ,
        SUM(CASE WHEN DATEDIFF(mm, 售楼部展示区正式开放计划完成时间, GETDATE()) = 0 AND   售楼部展示区正式开放实际完成时间 IS NOT NULL THEN 1 ELSE 0 END) AS  '24年7月已完工展示区' ,
        SUM(CASE WHEN DATEDIFF(mm, 售楼部展示区正式开放计划完成时间, GETDATE()) = 0 AND   售楼部展示区正式开放实际完成时间 IS NULL THEN 1 ELSE 0 END) AS  '24年7月逾期展示区' ,
        CASE WHEN SUM(CASE WHEN DATEDIFF(mm, 售楼部展示区正式开放计划完成时间, GETDATE()) = 0 THEN 1 ELSE 0 END) > 0 THEN
                 SUM(CASE WHEN DATEDIFF(mm, 售楼部展示区正式开放计划完成时间, GETDATE()) = 0 AND 售楼部展示区正式开放实际完成时间 IS NOT NULL THEN 1 ELSE 0 END) *1.0 / 
				 SUM(CASE WHEN DATEDIFF(mm, 售楼部展示区正式开放计划完成时间, GETDATE()) = 0 THEN 1 ELSE 0 END)
        END '24年7月展示区完成率' ,
     
        --开工
        SUM(CASE WHEN DATEDIFF(yy, 实际开工计划完成时间, GETDATE()) = 0 THEN zjm ELSE 0 END) / 10000 '24年计划开工' ,
        SUM(CASE WHEN DATEDIFF(yy, 实际开工计划完成时间, GETDATE()) = 0 AND   实际开工实际完成时间 IS NOT NULL THEN zjm ELSE 0 END) / 10000 '24年已开工' ,
        CASE WHEN SUM(CASE WHEN YEAR(实际开工计划完成时间) = 2024 THEN zjm ELSE 0 END) > 0 THEN
                 SUM(CASE WHEN DATEDIFF(yy, 实际开工计划完成时间, GETDATE()) = 0 AND 实际开工实际完成时间 IS NOT NULL THEN zjm ELSE 0 END) 
				 / SUM(CASE WHEN DATEDIFF(yy, 实际开工计划完成时间, GETDATE()) = 0 THEN zjm ELSE 0 END)
        END '24年计划开工完成率' ,
        SUM(CASE WHEN DATEDIFF(mm, 实际开工计划完成时间, GETDATE()) = 0 THEN zjm ELSE 0 END) / 10000 '24年7月计划开工' ,
        SUM(CASE WHEN DATEDIFF(mm, 实际开工计划完成时间, GETDATE()) = 0 AND   实际开工实际完成时间 IS NOT NULL THEN zjm ELSE 0 END) / 10000 '24年7月已开工' ,
        SUM(CASE WHEN DATEDIFF(mm, 实际开工计划完成时间, GETDATE()) = 0 AND   实际开工实际完成时间 IS NULL THEN zjm ELSE 0 END) / 10000 '24年7月逾期未开工' ,
        CASE WHEN SUM(CASE WHEN DATEDIFF(mm, 实际开工计划完成时间, GETDATE()) = 0 THEN zjm ELSE 0 END) > 0 THEN
                 SUM(CASE WHEN DATEDIFF(mm, 实际开工计划完成时间, GETDATE()) = 0 AND 实际开工实际完成时间 IS NOT NULL THEN zjm ELSE 0 END) 
				 / SUM(CASE WHEN DATEDIFF(mm, 实际开工计划完成时间, GETDATE()) = 0 THEN zjm ELSE 0 END)
        END '24年7月开工完成率' 
FROM    #ms a
left join #gc b on a.GCBldGUID = b.GCBldGUID
GROUP BY buname,spreadname,gcBldName

