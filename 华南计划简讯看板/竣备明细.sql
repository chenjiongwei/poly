--竣备明细
--缓存产品楼栋
SELECT  ms.SaleBldGUID ,
        '华南公司' buname ,
        p1.projguid as 项目GUID,
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
WHERE   p.developmentcompanyguid = 'AADC0FA7-9546-49C9-B64B-825056C828ED';

--竣备
SELECT  DISTINCT buname ,
                 a.项目GUID,
                 投管项目名称 + '-' + 关联工程楼栋 楼栋 ,
                 竣工备案计划完成时间 ,
                 竣工备案实际完成时间 ,
                 -- case when 竣工备案实际完成时间 IS NULL then   CONVERT(CHAR, DATEDIFF(mm, 竣工备案计划完成时间, GETDATE())) else 0 end as  月 ,
                 case when b.GCBldGUID is not null then 0 else case when 竣工备案计划完成时间 is null then 
                      CONVERT(CHAR, convert(decimal(10,2), DATEDIFF(day, 竣工备案计划完成时间, GETDATE()) *1.0/ 30.0 ) ) else  0 end  end 月,
                 ISNULL(竣工备案预计完成时间, 竣工备案计划完成时间) 预计 ,
                 ISNULL(集中交付实际完成时间, 集中交付计划完成时间) 交付 ,
                 spreadname + '-' + 关联工程楼栋 + '竣备：原节点' + 竣工备案计划完成时间 +   case when  竣工备案实际完成时间 IS NULL then  '，已逾期超' +  CONVERT(VARCHAR(4), DATEDIFF(mm, 竣工备案计划完成时间, GETDATE())) + '个月' + ';' else  ';实际完成：' + 竣工备案实际完成时间  end as  合并
--投管项目名称 + '-' + 关联工程楼栋 + '竣备：原节点' + 竣工备案计划完成时间 + '，已逾期超' + CONVERT(CHAR, DATEDIFF(mm, 竣工备案计划完成时间, GETDATE()))
--+ '个月，预计' + ISNULL(竣工备案预计完成时间, 竣工备案计划完成时间) + '完成；交付' + ISNULL(集中交付实际完成时间, 集中交付计划完成时间) + ';' 合并
INTO    #jb
FROM    #ms a
WHERE  DATEDIFF(yy, 竣工备案计划完成时间, GETDATE()) >= 0 and  DATEDIFF(mm, 竣工备案计划完成时间, GETDATE()) >= 0  --and  竣工备案实际完成时间 IS NULL;

--排序
SELECT  CASE WHEN t.序号 <= 10 THEN '是' ELSE '否' END AS 短讯是否显示 ,
        *
FROM(SELECT ROW_NUMBER() OVER (ORDER BY 月 desc) AS 序号, * FROM   #jb) t;

--删除临时表
DROP TABLE #jb ,
           #ms