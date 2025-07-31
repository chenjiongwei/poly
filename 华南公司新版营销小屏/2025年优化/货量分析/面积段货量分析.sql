--获取前台变量，按照区域、项目、组团来进行统计
-- 2025-07-14 增加本年本月的维度的分析
select pj.projguid
into #p
from data_wide_dws_mdm_project pj 
inner join data_tb_hn_yxpq t on pj.projguid = t.项目Guid
where 1=1
and ((${var_biz} in ('全部区域','全部项目','全部组团')) --若前台选择“全部区域”、“全部项目”、“全部组团”，则按照公司来统计
or (${var_biz} = t.营销事业部) --前台选择了具体某个区域
or (${var_biz} = t.营销片区) --前台选择了具体某个组团
or (${var_biz}  = pj.spreadname)) --前台选择了具体某个项目
--根据每个人的项目权限过滤
and pj.projguid in ${proj} 
and pj.level = 2 

select --p.projguid,
    tb.面积段显示名称 面积段,
    SUM(CASE WHEN r.Status = '签约' THEN 1 ELSE 0 END) 累计签约套数,
    SUM(CASE WHEN r.Status = '签约' THEN CjBldArea ELSE 0 END) 累计签约面积,
    SUM(CASE WHEN r.Status = '签约' THEN r.CjRmbTotal ELSE 0 END) / 10000.00 累计签约金额,

    -- 本年
    SUM(CASE WHEN r.Status = '签约' and datediff(year,QsDate,getdate()) =0 THEN 1 ELSE 0 END) 本年签约套数,
    SUM(CASE WHEN r.Status = '签约' and datediff(year,QsDate,getdate()) =0 THEN CjBldArea ELSE 0 END) 本年签约面积,
    SUM(CASE WHEN r.Status = '签约' and datediff(year,QsDate,getdate()) =0 THEN r.CjRmbTotal ELSE 0 END) / 10000.00 本年签约金额,
    -- 本月
    SUM(CASE WHEN r.Status = '签约' and datediff(month,QsDate,getdate()) =0 THEN 1 ELSE 0 END) 本月签约套数,
    SUM(CASE WHEN r.Status = '签约' and datediff(month,QsDate,getdate()) =0 THEN CjBldArea ELSE 0 END) 本月签约面积,
    SUM(CASE WHEN r.Status = '签约' and datediff(month,QsDate,getdate()) =0 THEN r.CjRmbTotal ELSE 0 END) / 10000.00 本月签约金额,
    --近一月
    SUM(CASE WHEN r.Status = '签约' and r.QsDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-1,getdate()),121) AND getdate()  
    THEN r.CjRmbTotal ELSE 0 END) / 10000.00 AS 近一月去化货值 ,
    SUM(CASE WHEN r.Status = '签约' and r.QsDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-1,getdate()),121) AND getdate() 
    THEN 1 ELSE 0 END) AS 近一月去化套数,
    SUM(CASE WHEN r.Status = '签约' and r.QsDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-1,getdate()),121) AND getdate() 
    THEN CjBldArea ELSE 0 END) 近一月去化面积,
    --近三月
    SUM(CASE WHEN r.Status = '签约' and r.QsDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-3,getdate()),121) AND getdate()  
    THEN r.CjRmbTotal ELSE 0 END) / 10000.00 AS 近三月去化货值 ,
    SUM(CASE WHEN r.Status = '签约' and r.QsDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-3,getdate()),121) AND getdate() 
    THEN 1 ELSE 0 END) AS 近三月去化套数,
    SUM(CASE WHEN r.Status = '签约' and r.QsDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-3,getdate()),121) AND getdate() 
    THEN CjBldArea ELSE 0 END) 近三月去化面积,
    --近六月
    SUM(CASE WHEN r.Status = '签约' and r.QsDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-6,getdate()),121) AND getdate()  
    THEN r.CjRmbTotal ELSE 0 END) / 10000.00 AS 近六月去化货值 ,
    SUM(CASE WHEN r.Status = '签约' and r.QsDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-6,getdate()),121) AND getdate() 
    THEN 1 ELSE 0 END) AS 近六月去化套数,
    SUM(CASE WHEN r.Status = '签约' and r.QsDate BETWEEN CONVERT(VARCHAR(10),DATEADD(MONTH,-6,getdate()),121) AND getdate() 
    THEN CjBldArea ELSE 0 END) 近六月去化面积 ,

    sum(case when FangPanTime is null or r.Status = '签约' then 0 else 1 end) 已推未售套数,
    sum(case when FangPanTime is null or r.Status = '签约' then 0 else bldarea end)  已推未售面积,
    sum(case when FangPanTime is null or r.Status = '签约' then 0 else total end)/10000.0  已推未售货值,

    sum(case when FangPanTime is null and r.Status <> '签约' then 1 else 0 end) 未推套数,
    sum(case when FangPanTime is null and r.Status <> '签约' then bldarea else 0 end)  未推面积,
    sum(case when FangPanTime is null and r.Status <> '签约' then total else 0 end)/10000.0  未推货值
from dbo.data_wide_s_RoomoVerride r
INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = r.BldGUID
inner join data_tb_hnyx_areasection tb on bld.TopProductTypeName = tb.业态 and r.bldarea >=tb.开始面积	
and r.bldarea <tb.截止面积	
inner join #p p on r.parentprojguid = p.projguid
WHERE   r.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
group by 
tb.面积段显示名称

-- 删除临时表 
drop table #p