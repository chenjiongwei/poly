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

--供货
SELECT  DISTINCT buname ,
                 投管项目名称 + '-' + 关联工程楼栋 楼栋 ,
                 达到预售形象计划完成时间 ,
                 达到预售形象实际完成时间 ,
                 case when 达到预售形象实际完成时间 IS NULL then 
                     convert(decimal(10,2), DATEDIFF(day, 达到预售形象计划完成时间, GETDATE()) *1.0/ 30.0 )  else  0 end  as  月 ,
                 ISNULL(达到预售形象预计完成时间, 达到预售形象计划完成时间) 预计 ,
                 spreadname + '-' + 关联工程楼栋 + '供货：原节点' + 达到预售形象计划完成时间 + '，已逾期超' + CONVERT(VARCHAR(2), DATEDIFF(mm, 达到预售形象计划完成时间, GETDATE())) + '个月' + ';' 合并
INTO    #gh
FROM    #ms a
where  ProductType IN ('住宅', '商业')
and  DATEDIFF(yy, 达到预售形象计划完成时间, GETDATE()) >= 0 and  DATEDIFF(mm, 达到预售形象计划完成时间, GETDATE()) >= 0

--排序
SELECT  CASE WHEN t.序号 <= 10 THEN '是' ELSE '否' END AS 短讯是否显示 ,
        *
FROM(SELECT ROW_NUMBER() OVER (ORDER BY 月 desc) AS 序号, * FROM #gh) t;

--删除临时表
DROP TABLE #gh ,
           #ms;