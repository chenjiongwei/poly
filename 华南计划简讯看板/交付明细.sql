-- 交付明细
--缓存产品楼栋
SELECT  ms.SaleBldGUID ,
        '华南公司' buname ,
        p1.spreadname ,
        p1.projguid as 项目GUID,
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

--交付
SELECT  DISTINCT buname,
                 项目GUID,
                 投管项目名称 + '-' + 关联工程楼栋 as 楼栋,
                 集中交付计划完成时间 ,
                 集中交付实际完成时间 ,
                 -- case when 集中交付实际完成时间 is null then  CONVERT(CHAR, DATEDIFF(mm, 集中交付计划完成时间, GETDATE())) else  0 end  as  月,
                 case when b.GCBldGUID is not null then 0 else case when 集中交付实际完成时间 is null then 
                    convert(decimal(10,2), DATEDIFF(day, 集中交付计划完成时间, GETDATE()) *1.0/ 30.0 ) else  0 end  end 月,
                 ISNULL(集中交付预计完成时间, 集中交付计划完成时间) as 预计 ,
                 spreadname + '-' + 关联工程楼栋 + '交付：原节点' + 集中交付计划完成时间 +
                 case when  集中交付实际完成时间 is null then
                  '，已逾期超' + CONVERT(VARCHAR(4), DATEDIFF(mm, 集中交付计划完成时间, GETDATE())) + '个月' + ';'  else  ';实际完成：' + 集中交付实际完成时间 end  as 合并
INTO    #jf
FROM    #ms a
left join #gc b on a.GCBldGUID = b.GCBldGUID
WHERE DATEDIFF(yy, 集中交付计划完成时间, GETDATE()) >= 0  and  DATEDIFF(mm, 集中交付计划完成时间, GETDATE()) >= 0 
--AND 集中交付实际完成时间 IS NULL;
and  a.ProductType not in ('地下室/车库','公建配套','其他')


--排序
SELECT  CASE WHEN t.序号 <= 10 THEN '是' ELSE '否' END AS 短讯是否显示 ,
        *
FROM(SELECT ROW_NUMBER() OVER (ORDER BY 月 desc ) AS 序号, * FROM   #jf ) t;

--删除临时表
DROP TABLE #ms ,
          #jf,
          #gc