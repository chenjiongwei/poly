
-- 迁移后合同、变更、结算等界面以及表单中存在重复的项目名称


-- 查询合同模块中重复项目名的合同
SELECT 
    a.projectnamelist,
    COUNT(1) AS 数量
FROM 
    cb_contract a
    INNER JOIN cb_contractproj b ON a.contractguid = b.contractguid
    INNER JOIN p_project p ON p.projguid = b.projguid
WHERE 
    a.buguid = 'BC0235CB-1137-4488-8192-E55DC27ACCD7'
    -- AND a.contractguid = '317D5367-944D-4E26-8A2F-A3D30AC74071'
    AND parentcode = '14.0537005'
GROUP BY 
    a.projectnamelist

-- 备份数据表
SELECT 
    a.* into cb_contract_bak20250812
FROM 
    cb_contract a
    INNER JOIN cb_contractproj b ON a.contractguid = b.contractguid
    INNER JOIN p_project p ON p.projguid = b.projguid
WHERE 
    a.buguid = 'BC0235CB-1137-4488-8192-E55DC27ACCD7'
    -- AND a.contractguid = '317D5367-944D-4E26-8A2F-A3D30AC74071'
    AND parentcode = '14.0537005'


-- 开始修改合同中重复的项目名称
-- 济宁济宁济宁济宁济宁济宁济宁济宁济宁天博食品西片区AB地块-一期
update a set a.projectnamelist = '天博食品西片区AB地块-一期'
FROM 
    cb_contract a
    INNER JOIN cb_contractproj b ON a.contractguid = b.contractguid
    INNER JOIN p_project p ON p.projguid = b.projguid
WHERE 
    a.buguid = 'BC0235CB-1137-4488-8192-E55DC27ACCD7'
    -- AND a.contractguid = '317D5367-944D-4E26-8A2F-A3D30AC74071'
    AND parentcode = '14.0537005'
    and a.projectnamelist = '济宁济宁济宁济宁济宁济宁济宁济宁济宁天博食品西片区AB地块-一期'

-- 济宁济宁济宁济宁天博食品西片区AB地块-二期A地块
update a set a.projectnamelist = '天博食品西片区AB地块-二期A地块'
FROM 
    cb_contract a
    INNER JOIN cb_contractproj b ON a.contractguid = b.contractguid
    INNER JOIN p_project p ON p.projguid = b.projguid
WHERE 
    a.buguid = 'BC0235CB-1137-4488-8192-E55DC27ACCD7'
    -- AND a.contractguid = '317D5367-944D-4E26-8A2F-A3D30AC74071'
    AND parentcode = '14.0537005'
    and a.projectnamelist = '济宁济宁济宁济宁天博食品西片区AB地块-二期A地块'


-- 济宁市任城区大三角地块-一期;济宁市邹城市工业文化产业园一期地块-一期;济宁鲁抗片区CE地块-一期（E地块）;济宁鲁抗片区CE地块-二期（C地块）;济宁凯赛生物地块-一期;济宁凯赛生物地块-二期;济宁济宁济宁济宁济宁济宁济宁济宁济宁天博食品西片区AB地块-一期;济宁天博食品西片区AB地块-二期A地块;济宁市高新区蓼河新区板块海川路麒麟岛A片-一期;济宁市邹城市工业文化产业园二期D1、F地块-一期;济宁市邹城市工业文化产业园二期D1、F地块-二期;济宁市任城区风园路50亩地块-一期
update a set a.projectnamelist = '济宁市任城区大三角地块-一期;济宁市邹城市工业文化产业园一期地块-一期;济宁鲁抗片区CE地块-一期（E地块）;济宁鲁抗片区CE地块-二期（C地块）;济宁凯赛生物地块-一期;济宁凯赛生物地块-二期;天博食品西片区AB地块-一期;天博食品西片区AB地块-二期A地块;济宁市高新区蓼河新区板块海川路麒麟岛A片-一期;济宁市邹城市工业文化产业园二期D1、F地块-一期;济宁市邹城市工业文化产业园二期D1、F地块-二期;济宁市任城区风园路50亩地块-一期'
FROM 
    cb_contract a
    INNER JOIN cb_contractproj b ON a.contractguid = b.contractguid
    INNER JOIN p_project p ON p.projguid = b.projguid
WHERE 
    a.buguid = 'BC0235CB-1137-4488-8192-E55DC27ACCD7'
    -- AND a.contractguid = '317D5367-944D-4E26-8A2F-A3D30AC74071'
    AND parentcode = '14.0537005'
    and a.projectnamelist = '济宁市任城区大三角地块-一期;济宁市邹城市工业文化产业园一期地块-一期;济宁鲁抗片区CE地块-一期（E地块）;济宁鲁抗片区CE地块-二期（C地块）;济宁凯赛生物地块-一期;济宁凯赛生物地块-二期;济宁济宁济宁济宁济宁济宁济宁济宁济宁天博食品西片区AB地块-一期;济宁天博食品西片区AB地块-二期A地块;济宁市高新区蓼河新区板块海川路麒麟岛A片-一期;济宁市邹城市工业文化产业园二期D1、F地块-一期;济宁市邹城市工业文化产业园二期D1、F地块-二期;济宁市任城区风园路50亩地块-一期'

-- 济宁市任城区大三角地块-一期;济宁市邹城市工业文化产业园一期地块-一期;济宁鲁抗片区CE地块-一期（E地块）;济宁鲁抗片区CE地块-二期（C地块）;济宁凯赛生物地块-一期;济宁凯赛生物地块-二期;济宁济宁济宁济宁济宁济宁济宁济宁济宁天博食品西片区AB地块-一期;济宁天博食品西片区AB地块-二期A地块;济宁市高新区蓼河新区板块海川路麒麟岛A片-一期;邹城市工业文化创意产业园二期用地（A-F地-一期;邹城市工业文化创意产业园二期用地（A-F地-二期（B地块回迁安置）;济宁市任城区风园路50亩地块-一期
update a set a.projectnamelist = '济宁市任城区大三角地块-一期;济宁市邹城市工业文化产业园一期地块-一期;济宁鲁抗片区CE地块-一期（E地块）;济宁鲁抗片区CE地块-二期（C地块）;济宁凯赛生物地块-一期;济宁凯赛生物地块-二期;天博食品西片区AB地块-一期;天博食品西片区AB地块-二期A地块;济宁市高新区蓼河新区板块海川路麒麟岛A片-一期;邹城市工业文化创意产业园二期用地（A-F地-一期;邹城市工业文化创意产业园二期用地（A-F地-二期（B地块回迁安置）;济宁市任城区风园路50亩地块-一期'
FROM 
    cb_contract a
    INNER JOIN cb_contractproj b ON a.contractguid = b.contractguid
    INNER JOIN p_project p ON p.projguid = b.projguid
WHERE 
    a.buguid = 'BC0235CB-1137-4488-8192-E55DC27ACCD7'
    -- AND a.contractguid = '317D5367-944D-4E26-8A2F-A3D30AC74071'
    AND parentcode = '14.0537005'
    and a.projectnamelist = '济宁市任城区大三角地块-一期;济宁市邹城市工业文化产业园一期地块-一期;济宁鲁抗片区CE地块-一期（E地块）;济宁鲁抗片区CE地块-二期（C地块）;济宁凯赛生物地块-一期;济宁凯赛生物地块-二期;济宁济宁济宁济宁济宁济宁济宁济宁济宁天博食品西片区AB地块-一期;济宁天博食品西片区AB地块-二期A地块;济宁市高新区蓼河新区板块海川路麒麟岛A片-一期;邹城市工业文化创意产业园二期用地（A-F地-一期;邹城市工业文化创意产业园二期用地（A-F地-二期（B地块回迁安置）;济宁市任城区风园路50亩地块-一期'


-- 查询变更确认审批表中的项目名称
-- 查询并备份
SELECT 
    wf.* 
INTO 
    myWorkflowProcessEntity_bak20250812
FROM 
    cb_contract_bak20250812 c
    INNER JOIN cb_htalter alt ON c.contractguid = alt.contractguid
    INNER JOIN [myWorkflowProcessEntity] wf ON alt.QrProcessGuid = wf.BusinessGUID

-- 查询工作流表单中的“项目名称”字段的值
select 
    wf.processguid,                           -- 流程GUID
    -- wf.ProcessNo,                          -- 流程编号（已注释）
    wf.processname,                           -- 流程名称
    CONVERT(XML, wf.bt_domainxml) AS data     -- 流程表单数据（XML格式）
into #qr
from  myWorkflowProcessEntity_bak20250812 wf

SELECT 
    s.*,
    m.c.value('@name', 'varchar(max)') AS 属性,
    m.c.value('.', 'nvarchar(max)') AS Value
INTO #value
FROM  #qr AS s
    OUTER APPLY s.data.nodes('BusinessType/Item/Domain') AS m(c)
WHERE  
    m.c.value('@name', 'varchar(max)') IN ('项目名称');

-- 修改数据
-- 济宁济宁济宁济宁天博食品西片区AB地块-一期
update  b set b.bt_domainxml =replace(convert(varchar(max),b.bt_domainxml),'济宁济宁济宁济宁天博食品西片区AB地块-一期','天博食品西片区AB地块-一期')
from #value a  
inner join myWorkflowProcessEntity b on a.processguid =b.processguid
where a.Value ='济宁济宁济宁济宁天博食品西片区AB地块-一期'
-- 济宁济宁济宁济宁济宁济宁济宁济宁济宁天博食品西片区AB地块-一期
update  b set b.bt_domainxml =replace(convert(varchar(max),b.bt_domainxml),'济宁济宁济宁济宁济宁济宁济宁济宁济宁天博食品西片区AB地块-一期','天博食品西片区AB地块-一期')
from #value a  
inner join myWorkflowProcessEntity b on a.processguid =b.processguid
where a.Value ='济宁济宁济宁济宁济宁济宁济宁济宁济宁天博食品西片区AB地块-一期'
-- 济宁济宁济宁济宁济宁天博食品西片区AB地块-一期
update  b set b.bt_domainxml =replace(convert(varchar(max),b.bt_domainxml),'济宁济宁济宁济宁济宁天博食品西片区AB地块-一期','天博食品西片区AB地块-一期')
from #value a  
inner join myWorkflowProcessEntity b on a.processguid =b.processguid
where a.Value ='济宁济宁济宁济宁济宁天博食品西片区AB地块-一期'
-- 济宁济宁济宁天博食品西片区AB地块-一期
update  b set b.bt_domainxml =replace(convert(varchar(max),b.bt_domainxml),'济宁济宁济宁天博食品西片区AB地块-一期','天博食品西片区AB地块-一期')
from #value a  
inner join myWorkflowProcessEntity b on a.processguid =b.processguid
where a.Value ='济宁济宁济宁天博食品西片区AB地块-一期'
-- 济宁济宁天博食品西片区AB地块-二期A地块
update  b set b.bt_domainxml =replace(convert(varchar(max),b.bt_domainxml),'济宁济宁天博食品西片区AB地块-二期A地块','天博食品西片区AB地块-二期A地块')
from #value a  
inner join myWorkflowProcessEntity b on a.processguid =b.processguid
where a.Value ='济宁济宁天博食品西片区AB地块-二期A地块'


