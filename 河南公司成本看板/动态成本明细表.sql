/*select ProjectGUID 
from data_wide_dws_cb_deviation_analysis 
where level=3 and CostLevel=1 and datediff(yy,回顾日期,getdate())=0
and ProjectGUID in()
*/
-- 创建临时表存储项目成本调整数据
SELECT 
    a.projguid AS ProjectGUID,                                                     -- 项目GUID
    a.ParentProjGUID,                                                             -- 父项目GUID
    gl.动态成本调整值 * 100000000 AS 动态成本调整值_粤中,                           -- 粤中公司动态成本调整值(单位:亿元)
    bzgl.动态成本调整值 * 100000000 AS 动态成本调整值_标准,                         -- 标准动态成本调整值(单位:亿元)
    (ISNULL(gl.动态成本调整值, 0) + ISNULL(bzgl.动态成本调整值, 0)) * 100000000 AS 动态成本调整值  -- 总动态成本调整值(单位:亿元)
INTO #projguid
FROM data_wide_cb_ProjCostAccount a 
    -- 关联粤中公司成本管理表(取最新批次)
    LEFT JOIN (
        SELECT ProjGUID, 动态成本调整值
        FROM data_tb_yz_cb_xmgl 
        WHERE batch_update_time = (
            SELECT MAX(batch_update_time) FROM data_tb_yz_cb_xmgl
        )
    ) gl ON a.ProjGUID = gl.ProjGUID
    -- 关联标准成本管理表(取最新批次) 
    LEFT JOIN (
        SELECT 分期guid, 动态成本调整值
        FROM data_tb_cb_xmgl 
        WHERE batch_update_time = (
            SELECT MAX(batch_update_time) FROM data_tb_cb_xmgl
        )
    ) bzgl ON a.ProjGUID = bzgl.分期guid
WHERE CostLevel = 1 
    AND (
        -- 粤中、华南公司条件:目标成本不为0且动态成本不为0
        (a.buguid IN ('6acca53b-0df4-43c3-bc9a-874feba48986','455fc380-b609-4a5a-9aac-ee0f84c7f1b8') 
            AND TargetCost <> 0 
            AND (DynamicCost_HFXJ + ISNULL(gl.动态成本调整值, 0)) <> 0
        ) 
        OR 
        -- 其他公司条件:动态成本调整值不为0,或目标成本和动态成本都不为0
        (a.buguid NOT IN ('6acca53b-0df4-43c3-bc9a-874feba48986','455fc380-b609-4a5a-9aac-ee0f84c7f1b8') 
            AND (
                ISNULL(bzgl.动态成本调整值, 0) <> 0 
                OR (TargetCost <> 0 AND DynamicCost_HFXJ <> 0)
            )
        )
    )

-- 添加聚集索引
CREATE CLUSTERED INDEX IX_projguid_ProjectGUID ON #projguid(ProjectGUID)

--粤中要求目标成本、动态成本都为0的项目要去掉。标准看板要求取填报的不为0或者目标和动态成本都不为0
--公司级
SELECT 
BUGUID,buname,ConstructStatus,max(ParentProjName+'('+p.TgProjCode+')') 项目名称,ProjCode,coalesce(p.p_projname,'全分期') 分期,
max(竣工日期)竣工日期,a.ParentProjGUID parentguid,a.TargetStageVersion as 目标成本业务版本,
 --公司GUID
case when buguid is null and a.ParentProjGUID is null and a.ProjGUID is null then '11b11db4-e907-4f1f-8835-b9daab6e1f23'
	when buguid is not null and a.ParentProjGUID is null and a.ProjGUID is null then BUGUID
	when a.ParentProjGUID is not null and a.ProjGUID is null then a.ParentProjGUID
	when a.ProjGUID is not null then a.ProjGUID  end as  OrgGUID, --组织架构GUID,
	case when buguid is null and a.ParentProjGUID is null and a.ProjGUID is null then '保利发展集团'
	when buguid is not null and a.ParentProjGUID is null and a.ProjGUID is null then buname
	when a.ParentProjGUID is not null and a.ProjGUID is null then ParentProjName
	when a.ProjGUID is not null then ProjName  end as  OrgName, --组织架构名称,
    --buguid AS OrgGUID, --组织架构GUID
    --buname AS OrgName, --组织架构名称
	case when buguid is null and a.ParentProjGUID is null and a.ProjGUID is null then '总部'
	when buguid is not null and a.ParentProjGUID is null and a.ProjGUID is null then '平台公司'
	when a.ParentProjGUID is not null and a.ProjGUID is null then '项目'
	when a.ProjGUID is not null then '分期' else '其他'  end as  OrgType , --组织架构类型
    --总投
    SUM(CASE WHEN CostLevel=1 THEN ISNULL(TargetCost, 0)ELSE 0 END) AS 总投目标成本, --目标成本
	SUM(CASE WHEN CostLevel=1 THEN ISNULL(DynamicCost, 0)+ISNULL(gl.动态成本调整值, 0) ELSE 0 END)  AS 总投动态成本_不含非现金, --动态成本
    SUM(CASE WHEN CostLevel=1 THEN ISNULL(DynamicCost_HFXJ, 0)+ISNULL(gl.动态成本调整值, 0) ELSE 0 END)  AS 总投动态成本, --动态成本
    SUM(CASE WHEN CostLevel=1 THEN ISNULL(YfsCost, 0)ELSE 0 END) AS 总投已发生成本, --已发成本
    SUM(CASE WHEN CostLevel=1 THEN ISNULL(DfsCost, 0)ELSE 0 END) AS 总投待发生成本, --待发生成本
    --动态成本单方
    CASE WHEN SUM(CASE WHEN CostLevel=1 THEN ISNULL(DynamicCost_HFXJ, 0)+ISNULL(gl.动态成本调整值, 0) ELSE 0 END)=0 THEN 0 ELSE SUM(CASE WHEN CostLevel=1 THEN ISNULL(YfsCost, 0)ELSE 0 END)/ SUM(CASE WHEN CostLevel=1 THEN ISNULL(DynamicCost_HFXJ, 0)+ISNULL(gl.动态成本调整值, 0) ELSE 0 END)END AS 总投已发生占比, --已发生占比（已发生/动态）
    CASE WHEN SUM(CASE WHEN CostLevel=1 THEN ISNULL(TargetCost, 0)ELSE 0 END)=0 THEN 0 ELSE SUM(CASE WHEN CostLevel=1 THEN ISNULL(DynamicCost_HFXJ, 0)+ISNULL(gl.动态成本调整值, 0)ELSE 0 END)/ SUM(CASE WHEN CostLevel=1 THEN ISNULL(TargetCost, 0)ELSE 0 END)END AS 总投成本发生率, --成本发生率（动态/目标）
    --直投
    SUM(CASE WHEN CostLevel=2 AND ISNULL(CostCategory, '') NOT IN ('土地成本', '财务费用', '管理费用', '销售费用') THEN ISNULL(TargetCost, 0)ELSE 0 END) AS 除地价外直投目标成本, --直投目标成本
    SUM(CASE WHEN CostLevel=2 AND ISNULL(CostCategory, '') NOT IN ('土地成本', '财务费用', '管理费用', '销售费用') THEN ISNULL(DynamicCost_HFXJ, 0)ELSE 0 END)+SUM(ISNULL(gl.动态成本调整值, 0)) AS 除地价外直投动态成本, --直投动态成本
	SUM(CASE WHEN CostLevel=2 AND ISNULL(CostCategory, '') NOT IN ('土地成本', '财务费用', '管理费用', '销售费用') THEN ISNULL(DynamicCost, 0)ELSE 0 END)+SUM(ISNULL(gl.动态成本调整值, 0)) AS 除地价外直投动态成本_不含非现金, --直投动态成本_不含非现金
    SUM(CASE WHEN CostLevel=2 AND ISNULL(CostCategory, '') NOT IN ('土地成本', '财务费用', '管理费用', '销售费用') THEN ISNULL(YfsCost, 0)ELSE 0 END) AS 除地价外直投已发生成本, --直投已发成本
    SUM(CASE WHEN CostLevel=2 AND ISNULL(CostCategory, '') NOT IN ('土地成本', '财务费用', '管理费用', '销售费用') THEN ISNULL(DfsCost, 0)ELSE 0 END) AS 除地价外直投待发生成本, --直投待发生成本
    CASE WHEN (SUM(CASE WHEN CostLevel=2 AND ISNULL(CostCategory, '') NOT IN ('土地成本', '财务费用', '管理费用', '销售费用') THEN ISNULL(DynamicCost_HFXJ, 0) ELSE 0 END)+SUM(ISNULL(gl.动态成本调整值, 0)))=0 THEN 0 ELSE SUM(CASE WHEN CostLevel=2 AND ISNULL(CostCategory, '') NOT IN ('土地成本', '财务费用', '管理费用', '销售费用') THEN ISNULL(YfsCost, 0)ELSE 0 END)/ (SUM(CASE WHEN CostLevel=2 AND ISNULL(CostCategory, '') NOT IN ('土地成本', '财务费用', '管理费用', '销售费用') THEN ISNULL(DynamicCost_HFXJ, 0) ELSE 0 END)+SUM(ISNULL(gl.动态成本调整值, 0)))END AS 除地价外直投已发生占比, --已发生占比（已发生/动态）
    CASE WHEN SUM(CASE WHEN CostLevel=2 AND ISNULL(CostCategory, '') NOT IN ('土地成本', '财务费用', '管理费用', '销售费用') THEN ISNULL(TargetCost, 0)ELSE 0 END)=0 THEN 0 ELSE (SUM(CASE WHEN CostLevel=2 AND ISNULL(CostCategory, '') NOT IN ('土地成本', '财务费用', '管理费用', '销售费用') THEN ISNULL(DynamicCost_HFXJ, 0) ELSE 0 END)+SUM(ISNULL(gl.动态成本调整值, 0)))/ SUM(CASE WHEN CostLevel=2 AND ISNULL(CostCategory, '') NOT IN ('土地成本', '财务费用', '管理费用', '销售费用') THEN ISNULL(TargetCost, 0)ELSE 0 END)END AS 除地价外直投成本发生率 --成本发生率（动态/目标）
INTO #cb_temp01
FROM data_wide_cb_ProjCostAccount a 
inner join (select projguid as p_ProjGUID,projname p_projname,TgProjCode,ProjCode,ConstructStatus from data_wide_dws_mdm_project )p on a.ProjGUID=p.p_ProjGUID
left join (SELECT    projguid ,
                            MAX(ISNULL(FactFinishDate, PlanFinishDate)) AS 竣工日期
                  FROM  data_wide_dws_mdm_Building
                  WHERE bldtype = '工程楼栋'
                  GROUP BY projguid
        --HAVING  DATEDIFF(YEAR, MAX(FactFinishDate), GETDATE()) >= 1
        ) jb ON jb.projguid = a.ProjGUID

left join #projguid gl on a.ProjGUID=gl.ProjectGUID and costlevel =1
WHERE CostLevel IN (1, 2) --AND buname='粤中公司' 
and exists(select * from #projguid where ProjectGUID=a.ProjGUID)
GROUP BY 
grouping sets((),(buguid,buname),( buguid,buname,a.ParentProjGUID,ParentProjName),(buguid,buname,a.ParentProjGUID,ParentProjName,a.ProjGUID,ProjName,p.p_projname,p.TgProjCode,ConstructStatus,ProjCode,a.TargetStageVersion))

-- 添加索引
CREATE NONCLUSTERED INDEX IX_cb_temp01_OrgGUID ON #cb_temp01(OrgGUID)
CREATE NONCLUSTERED INDEX IX_cb_temp01_ProjGUID ON #cb_temp01(ProjGUID)

--超限科目数 ，分期
select '直投'type,
ProjGUID,sum(case when ISNULL((TargetCost-DynamicCost_HFXJ)/NULLIF(TargetCost,0),0) <0 then 1 else 0 end) as 超限科目数
,sum(case when TargetCost<>0 or DynamicCost_HFXJ<>0 and ISNULL((TargetCost-DynamicCost_HFXJ)/NULLIF(TargetCost,0),0) >=0 and ISNULL((TargetCost-DynamicCost_HFXJ)/NULLIF(TargetCost,0),0) <0.01 then 1 else 0 end) as 预警科目数
,sum(case when ISNULL((TargetCost-DynamicCost_HFXJ)/NULLIF(TargetCost,0),0) >0.03 then 1 else 0 end) as 异常科目数
,sum(case when ISNULL((TargetCost-DynamicCost_HFXJ)/NULLIF(TargetCost,0),0) between 0.01 and 0.03 then 1 else 0 end) as 正常科目数
into #cx_proj
from data_wide_cb_ProjCostAccount where ifendcost =1 and (costcode not like '5001.01%' or costcode not like '5001.09%' or costcode not like '5001.10%' or costcode not like '5001.11%')
group by ProjGUID
union all 
select '总投'type,
ProjGUID,sum(case when ISNULL((TargetCost-DynamicCost_HFXJ)/NULLIF(TargetCost,0),0) <0 then 1 else 0 end) as 超限科目数
,sum(case when TargetCost<>0 or DynamicCost_HFXJ<>0 and ISNULL((TargetCost-DynamicCost_HFXJ)/NULLIF(TargetCost,0),0) >=0 and ISNULL((TargetCost-DynamicCost_HFXJ)/NULLIF(TargetCost,0),0) <0.01 then 1 else 0 end) as 预警科目数
,sum(case when ISNULL((TargetCost-DynamicCost_HFXJ)/NULLIF(TargetCost,0),0) >0.03 then 1 else 0 end) as 异常科目数
,sum(case when ISNULL((TargetCost-DynamicCost_HFXJ)/NULLIF(TargetCost,0),0) between 0.01 and 0.03 then 1 else 0 end) as 正常科目数
from data_wide_cb_ProjCostAccount where ifendcost =1 
group by ProjGUID

--上月已审核动态成本，若上月无审核版本，则取最近的已审核版本，分期
select 
	'总投' cb_type,回顾日期,case when datediff(mm,回顾日期,getdate())=0 then '是' else '否' end as 本月是否审核,ProjectGUID,BUGUID,
	动态成本_不含非现金,目标成本,上次目标成本,上次动态成本_不含非现金 上次动态成本,
	动态成本,动态成本-动态成本_不含非现金 非现金,
	case when datediff(mm,回顾日期,getdate())=0 then 上次动态成本_不含非现金 else 动态成本_不含非现金 end as 上月动态成本 ,
	case when datediff(mm,回顾日期,getdate())=0 then 上次目标成本 else 目标成本 end as 上月目标成本 
into #lasemonth_dt
from data_wide_dws_cb_deviation_analysis_latest  
where  level=3 and CostLevel=1 and 审核版本类型='最新'
--where  ProjectGUID='a4e360d4-129a-e911-80b7-0a94ef7517dd' 
union all 
select
	'直投' cb_type,max(回顾日期)回顾日期,case when datediff(mm,回顾日期,getdate())=0 then '是' else '否' end as 本月是否审核,ProjectGUID,BUGUID,
	sum(动态成本_不含非现金)动态成本_不含非现金,
	sum(目标成本)目标成本,sum(上次目标成本)上次目标成本,sum(上次动态成本_不含非现金)上次动态成本,
	sum(动态成本)动态成本,sum(动态成本-动态成本_不含非现金) 非现金,
	sum(case when datediff(mm,回顾日期,getdate())=0 then 上次动态成本_不含非现金 else 动态成本_不含非现金 end) as 上月动态成本 ,
	sum(case when datediff(mm,回顾日期,getdate())=0 then 上次目标成本 else 目标成本 end) as 上月目标成本 
--into #lasemonth_dt
from data_wide_dws_cb_deviation_analysis_latest  
where CostLevel=2 and 科目编码 not in ('5001.01','5001.09','5001.11','5001.10')
and 审核版本类型='最新'
group by ProjectGUID,BUGUID,case when datediff(mm,回顾日期,getdate())=0 then '是' else '否' end 
 
 
--合并 
select '总投' type,项目名称,分期,BUGUID,buname,ConstructStatus,parentguid,OrgGUID,OrgName,OrgType,ProjCode,目标成本业务版本,总投目标成本 目标成本,总投动态成本 动态成本,总投动态成本_不含非现金 动态成本_不含非现金,总投已发生成本 已发生成本,总投待发生成本 待发生成本,总投已发生占比 已发生占比,总投成本发生率 成本发生率 ,竣工日期
  into #cb_temp02
from #cb_temp01 
union all 
select '直投' type,项目名称,分期,BUGUID,buname,ConstructStatus,parentguid,OrgGUID,OrgName,OrgType,ProjCode,目标成本业务版本,除地价外直投目标成本,除地价外直投动态成本,除地价外直投动态成本_不含非现金,除地价外直投已发生成本,除地价外直投待发生成本,除地价外直投已发生占比,除地价外直投成本发生率,竣工日期
from #cb_temp01 



-- 查询建筑面积和可售面积数据
-- 根据不同组织层级(总部/平台公司/项目/分期)汇总建筑面积和可售面积
SELECT 
    -- 确定组织GUID
    CASE 
        WHEN buguid IS NULL THEN '11b11db4-e907-4f1f-8835-b9daab6e1f23' 
        WHEN parentguid IS NULL THEN buguid 
        WHEN projguid IS NULL THEN parentguid 
        ELSE projguid 
    END AS OrgGUID,
    -- 确定组织类型 
    CASE 
        WHEN buguid IS NULL THEN '总部'
        WHEN parentguid IS NULL THEN '平台公司'
        WHEN projguid IS NULL THEN '项目'
        ELSE '分期'
    END AS OrgType,
    -- 汇总面积数据
    SUM(ISNULL(BuildArea, 0)) AS 总建筑面积,
    SUM(ISNULL(SaleArea, 0)) AS 可售面积,
    sum(isnull(JrSaleArea,0)) as 计容可售面积
INTO #proj
FROM data_wide_dws_mdm_Project p 
WHERE level = 3 
    AND EXISTS (
        SELECT * 
        FROM #projguid 
        WHERE p.projguid = ProjectGUID
    )
-- 使用GROUPING SETS实现多层级汇总
GROUP BY GROUPING SETS(
    (), -- 全部汇总
    (buguid), -- 按事业部汇总
    (buguid, parentguid), -- 按项目汇总
    (buguid, parentguid, projguid) -- 按分期汇总
)

--查询结果
SELECT 
	a.BUGUID,a.buname,a.ConstructStatus 项目状态,a.ProjCode,a.type, a.OrgGUID, a.OrgName, a.OrgType, a.项目名称,a.分期,
	a.竣工日期,a.目标成本业务版本,
	case when a.orgtype ='项目' then isnull(pj.项目简称,pp.spreadname) when a.orgtype='分期' then isnull(pj.项目简称,pp.spreadname)+'-'+a.分期 else '' end as 项目分期简称,
	a.目标成本, a.动态成本,a.动态成本_不含非现金,(a.动态成本-a.动态成本_不含非现金)动态成本_非现金, a.已发生成本, a.待发生成本, a.已发生占比, a.成本发生率, 
	p.总建筑面积, 
    p.可售面积, 
    p.计容可售面积,
    ISNULL((a.目标成本-a.动态成本)/NULLIF(a.目标成本,0),0)as 偏差率
	, ISNULL((a.目标成本-a.动态成本_不含非现金)/NULLIF(a.目标成本,0),0)as 偏差率_不含非现金
	,b.回顾日期 
	,b.上月动态成本,b.上月目标成本,b.本月是否审核
	,b.目标成本 已审核版本_目标成本
	,b.动态成本 已审核版本_动态成本
	,b.动态成本_不含非现金 已审核版本_动态成本_不含非现金
	,b.非现金 已审核版本_非现金
	,b.上次目标成本 已审核版本_上次目标成本
	,b.上次动态成本 已审核版本_上次动态成本
	,ISNULL((b.目标成本-b.动态成本)/NULLIF(b.目标成本,0),0)as 已审核版本_偏差率
	,ISNULL((a.动态成本-b.上月动态成本)/NULLIF(b.上月动态成本,0),0)as 较上月偏差率,cx.超限科目数,cx.预警科目数,cx.异常科目数,cx.正常科目数,
	CASE WHEN  ISNULL(p.总建筑面积,0) =0 THEN 0 else  ISNULL(a.目标成本,0) / ISNULL(p.总建筑面积,0) END  AS  目标成本单方,
	CASE WHEN  ISNULL(p.总建筑面积,0) =0 THEN 0 else   ISNULL(a.动态成本,0) / ISNULL(p.总建筑面积,0) END  AS  动态成本单方
	,CASE WHEN  ISNULL(p.总建筑面积,0) =0 THEN 0 else   ISNULL(a.动态成本_不含非现金,0) / ISNULL(p.总建筑面积,0) END  AS  动态成本单方_不含非现金
	,ISNULL((a.动态成本-a.动态成本_不含非现金)/NULLIF(p.总建筑面积,0),0) 其中非现金单方
	,ISNULL(a.已发生成本/NULLIF(p.总建筑面积,0),0)已发生成本单方
	,ISNULL(a.待发生成本/NULLIF(p.总建筑面积,0),0)待发生成本单方
FROM #cb_temp02 a WITH (NOLOCK)
     LEFT JOIN #proj p WITH (NOLOCK) ON a.orgguid=p.orgguid AND a.OrgType=p.OrgType
	 LEFT JOIN #lasemonth_dt b WITH (NOLOCK) ON b.cb_type=a.type and a.OrgGUID=b.ProjectGUID
	 LEFT JOIN data_tb_sichuan_projname pj WITH (NOLOCK) ON 
        a.parentguid = pj.项目GUID 
        AND pj.batch_update_time=(select max(batch_update_time) from data_tb_sichuan_projname)
	 LEFT JOIN #cx_proj cx WITH (NOLOCK) ON cx.type =a.type and cx.ProjGUID=a.OrgGUID
	 LEFT JOIN data_wide_dws_mdm_project pp WITH (NOLOCK) ON a.parentguid = pp.projguid
--where a.buname='粤中公司' and a.OrgType='平台公司'

--删除临时表
DROP TABLE #cb_temp01,#cb_temp02, #proj,#lasemonth_dt,#cx_proj,#projguid