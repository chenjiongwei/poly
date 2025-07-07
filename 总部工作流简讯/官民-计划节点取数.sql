
-- 公司、项目名称、分期名称、楼栋名称、节点名称、计划完成时间（计划的）、实际完成时间（汇报的）、时间差

-- 节点包括：项目实际开工、地下室结构完成、主体结构2/3层、达到预售形象、外架拆除完成、首批移交精装、精装完成、封顶、竣工备案、交付准备、集中交付
SELECT  
        公司,
        投管项目编码,
        a.投管代码,
        投管项目名称,
        项目分期,
        计划组团名称,
        关联工程楼栋,
        '项目实际开工' as 节点名称,
        实际开工工作项状态 as 状态,
        实际开工计划完成时间 as 计划完成日期,
        实际开工实际完成时间 as 实际完成日期,
        实际开工预计完成时间 as 预计完成日期,
        datediff(day,实际开工计划完成时间,实际开工实际完成时间) as 时间差 --  
FROM    jd_PlanTaskExecuteObjectForReport a
inner join  erp25.dbo.vmdm_projectFlagnew b on a.投管项目编码=b.项目代码
where  是否停工 not in ('停工','缓建') and b.项目状态 <> '清算退出'
union ALL

SELECT  公司,
        投管项目编码,
        a.投管代码,
        投管项目名称,
        项目分期,
        计划组团名称,
        关联工程楼栋,
        '地下室结构完成' as 节点名称,
        地下结构完成工作项状态 as 状态,
        地下结构完成计划完成时间 as 计划完成日期,
        地下结构完成实际完成时间 as 实际完成日期,
        地下结构完成预计完成时间 as 预计完成日期,
        datediff(day,地下结构完成计划完成时间,地下结构完成实际完成时间) as 时间差 --  
FROM    jd_PlanTaskExecuteObjectForReport a
 inner join  erp25.dbo.vmdm_projectFlagnew b on a.投管项目编码=b.项目代码
where  是否停工 not in ('停工','缓建') and b.项目状态 <> '清算退出'
union ALL

SELECT  公司,
        投管项目编码,
        a.投管代码,
        投管项目名称,
        项目分期,
        计划组团名称,
        关联工程楼栋,
        '达预售形象' as 节点名称,
        达到预售形象工作项状态 as 状态,
        达到预售形象计划完成时间 as 计划完成日期,
        达到预售形象实际完成时间 as 实际完成日期,
        达到预售形象预计完成时间 as 预计完成日期,
        datediff(day,达到预售形象计划完成时间,达到预售形象实际完成时间) as 时间差 --  
FROM    jd_PlanTaskExecuteObjectForReport a
inner join  erp25.dbo.vmdm_projectFlagnew b on a.投管项目编码=b.项目代码
where  是否停工 not in ('停工','缓建') and b.项目状态 <> '清算退出'
union all
SELECT  公司,
        投管项目编码,
        a.投管代码,
        投管项目名称,
        项目分期,
        计划组团名称,
        关联工程楼栋,
        '精装完成' as 节点名称,
        全部移交精装完成工作项状态 as 状态,
        全部移交精装完成计划完成时间 as 计划完成日期,
        全部移交精装完成实际完成时间 as 实际完成日期,
        null as 预计完成日期,
        datediff(day,全部移交精装完成计划完成时间,全部移交精装完成实际完成时间) as 时间差 --  
FROM    jd_PlanTaskExecuteObjectForReport a
inner join  erp25.dbo.vmdm_projectFlagnew b on a.投管项目编码=b.项目代码
where  是否停工 not in ('停工','缓建') and b.项目状态 <> '清算退出'
-- 主体结构封顶计划完成时间

union all
SELECT  公司,
        投管项目编码,
        a.投管代码,
        投管项目名称,
        项目分期,
        计划组团名称,
        关联工程楼栋,
        '封顶' as 节点名称,
        主体结构封顶工作项状态 as 状态,
        主体结构封顶计划完成时间 as 计划完成日期,
        主体结构封顶实际完成时间 as 实际完成日期,
        主体结构封顶预计完成时间 as 预计完成日期,
        datediff(day,主体结构封顶计划完成时间,主体结构封顶实际完成时间) as 时间差 --  
FROM    jd_PlanTaskExecuteObjectForReport a
inner join  erp25.dbo.vmdm_projectFlagnew b on a.投管项目编码=b.项目代码
where  是否停工 not in ('停工','缓建') and b.项目状态 <> '清算退出'

union all
SELECT  公司,
        投管项目编码,
        投管代码,
        投管项目名称,
        项目分期,
        计划组团名称,
        关联工程楼栋,
        '封顶' as 节点名称,
        竣工备案工作项状态 as 状态,
        主体结构封顶计划完成时间 as 计划完成日期,
        主体结构封顶实际完成时间 as 实际完成日期,
        主体结构封顶预计完成时间 as 预计完成日期,
        datediff(day,主体结构封顶计划完成时间,主体结构封顶实际完成时间) as 时间差 --  
FROM    jd_PlanTaskExecuteObjectForReport 
where  是否停工 not in ('停工','缓建')
--竣工备案计划完成时间

union all
SELECT  公司,
        投管项目编码,
        a.投管代码,
        投管项目名称,
        项目分期,
        计划组团名称,
        关联工程楼栋,
        '竣工备案' as 节点名称,
        竣工备案工作项状态 as 状态,
        竣工备案计划完成时间 as 计划完成日期,
        竣工备案实际完成时间 as 实际完成日期,
        竣工备案预计完成时间 as 预计完成日期,
        datediff(day,竣工备案计划完成时间,竣工备案实际完成时间) as 时间差 --  
FROM    jd_PlanTaskExecuteObjectForReport a
inner join  erp25.dbo.vmdm_projectFlagnew b on a.投管项目编码=b.项目代码
where  是否停工 not in ('停工','缓建') and b.项目状态 <> '清算退出'
--交付准备
union all
SELECT  公司,
        投管项目编码,
        a.投管代码,
        投管项目名称,
        项目分期,
        计划组团名称,
        关联工程楼栋,
        '交付准备' as 节点名称,
        交付准备工作项状态 as 状态,
        交付准备计划完成时间 as 计划完成日期,
        交付准备实际完成时间 as 实际完成日期,
        交付准备预计完成时间 as 预计完成日期,
        datediff(day,交付准备计划完成时间,交付准备实际完成时间) as 时间差 --  
FROM    jd_PlanTaskExecuteObjectForReport a
inner join  erp25.dbo.vmdm_projectFlagnew b on a.投管项目编码=b.项目代码
where  是否停工 not in ('停工','缓建') and b.项目状态 <> '清算退出'
--集中交付
union all
SELECT  公司,
        投管项目编码,
        a.投管代码,
        投管项目名称,
        项目分期,
        计划组团名称,
        关联工程楼栋,
        '集中交付' as 节点名称,
        集中交付工作项状态 as 状态,
        集中交付计划完成时间 as 计划完成日期,
        集中交付实际完成时间 as 实际完成日期,
        集中交付预计完成时间 as 预计完成日期,
        datediff(day,集中交付计划完成时间,集中交付实际完成时间) as 时间差 --  
FROM    jd_PlanTaskExecuteObjectForReport a
inner join  erp25.dbo.vmdm_projectFlagnew b on a.投管项目编码=b.项目代码
where  是否停工 not in ('停工','缓建') and b.项目状态 <> '清算退出'