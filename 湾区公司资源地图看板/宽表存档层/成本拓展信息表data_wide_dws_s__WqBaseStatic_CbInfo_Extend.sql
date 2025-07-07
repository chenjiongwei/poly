-- 将结算信息插入临时表
SELECT 
    c.buguid,
    p.ParentGUID,
    p.ParentName,
    p.ProjGUID,
    p.ProjName,
    CASE WHEN p.ProjGUID IS NULL THEN '项目' ELSE '分期' END AS 项目维度,
    -- 竣工日期,
    -- SUM(totalAmount) /10000.0 已签金额, 
    -- sum(CASE WHEN jsstate = '结算' THEN totalAmount ELSE 0 ENd) /10000.0 已结算已签金额, 
    SUM(htCfAmount) /10000.0 已签金额, 
    sum(CASE WHEN jsstate = '结算' THEN htCfAmount ELSE 0 ENd) /10000.0 已结算已签金额, 
    sum(case when MasterContractGUID is null then 1 else 0 end) 已签份数, --算结算率的时候，不包含补充协议的份数
    SUM(CASE WHEN jsstate = '结算' THEN jsamount_all ELSE 0 END)  /10000.0  as 结算金额,
    SUM(CASE WHEN jsstate = '结算' and MasterContractGUID is null THEN 1 ELSE 0 END) 结算份数,--算结算率的时候，不包含补充协议的份数
    CASE
        WHEN ISNULL(sum(case when MasterContractGUID is null then 1 else 0 end) , 0) = 0 THEN
            0
        ELSE
            ISNULL(SUM(CASE WHEN JsState = '结算' and MasterContractGUID is null THEN 1 ELSE 0 END),
                      0
                  ) * 1.0 / ISNULL(sum(case when MasterContractGUID is null then 1 else 0 end) , 0)
    END AS 综合结算率_份数, --算结算率（结算份数/已签份数）的时候，不包含补充协议
    -- CASE
    --     WHEN SUM(totalAmount) = 0 THEN
    --         0
    --     ELSE
    --         ISNULL(SUM(CASE WHEN JsState = '结算' THEN jsamount_all ELSE 0 END),
    --                   0
    --               ) * 1.0 / SUM(totalAmount)
    -- END AS 综合结算率_金额, --结算金额/已签金额
    -- (CASE
    --     WHEN ISNULL(sum(case when MasterContractGUID is null then 1 else 0 end) , 0) = 0 THEN
    --         0
    --     ELSE
    --         ISNULL(SUM(CASE WHEN JsState = '结算' and MasterContractGUID is null THEN 1 ELSE 0 END),
    --                   0
    --               ) * 1.0 / ISNULL(sum(case when MasterContractGUID is null then 1 else 0 end) , 0)
    -- END + CASE
    --            WHEN SUM(totalAmount) = 0 THEN
    --                0
    --            ELSE
    --                ISNULL(SUM(CASE WHEN JsState = '结算' THEN jsamount_all ELSE 0 END),
    --                          0
    --                      ) * 1.0 / SUM(totalAmount)
    --        END
    -- ) / 2 综合结算率
    CASE
        WHEN SUM(htCfAmount) = 0 THEN
            0
        ELSE
            ISNULL(SUM(CASE WHEN JsState = '结算' THEN jsamount_all ELSE 0 END),
                      0
                  ) * 1.0 / SUM(htCfAmount)
    END AS 综合结算率_金额, --结算金额/已签金额
    (CASE
        WHEN ISNULL(sum(case when MasterContractGUID is null then 1 else 0 end) , 0) = 0 THEN
            0
        ELSE
            ISNULL(SUM(CASE WHEN JsState = '结算' and MasterContractGUID is null THEN 1 ELSE 0 END),
                      0
                  ) * 1.0 / ISNULL(sum(case when MasterContractGUID is null then 1 else 0 end) , 0)
    END + CASE
               WHEN SUM(htCfAmount) = 0 THEN
                   0
               ELSE
                   ISNULL(SUM(CASE WHEN JsState = '结算' THEN jsamount_all ELSE 0 END),
                             0
                         ) * 1.0 / SUM(htCfAmount)
           END
    ) / 2 综合结算率
  INTO #Js
  FROM data_wide_dws_cb_cf_contract c
 INNER JOIN data_wide_dws_mdm_Project p ON p.ProjGUID = c.ProjGUID
  WHERE p.Level = 3  
  GROUP BY GROUPING SETS((p.ProjGUID, c.buguid, p.ParentGUID, p.ParentName, p.ProjName), (p.ParentGUID, c.buguid, p.ParentName))

  --查询结果
  --项目和分期层级
  SELECT  
	org.组织架构ID,
	org.组织架构名称,
	org.组织架构类型,
	org.组织架构编码,
	js.项目维度,
	js.ParentGUID as 项目GUID,
	js.ParentName as 项目名称,
	js.ProjName as 项目分期名称,
	js.ProjGUID as 项目分期GUID,
	js.已签金额 as 合同总金额,
	js.已签份数 as 合同份数		,
	js.结算份数		,
	js.结算金额		,
    js.已结算已签金额 as 已结算已签金额,
	case when isnull(js.已结算已签金额,0)  =0 then  0  else   (isnull(js.结算金额,0) - isnull(js.已结算已签金额,0) ) / isnull(js.已结算已签金额,0) end  as 结算偏差率, -- （结算金额-合同总金额）/合同总金额*100%
	综合结算率 as 结算综合完成率,	
	综合结算率_份数 ,
	综合结算率_金额	 
  FROM data_Wide_Dws_s_WqBaseStatic_Organization org
  INNER join  #Js js ON  org.组织架构ID =js.ParentGUID
  WHERE  org.组织架构类型 =3
  union all 
  --城市公司/事业部
  SELECT  
	porg.组织架构ID,
	porg.组织架构名称,
	porg.组织架构类型,
	porg.组织架构编码,
	null 项目维度,
    null as 项目GUID,
	null as 项目名称,
	null as 项目分期名称,
	null as 项目分期GUID,
	sum(isnull(js.已签金额,0)) as 合同总金额,
	sum(isnull(js.已签份数,0))  as 合同份数		,
	sum(isnull(js.结算份数,0)) 	as 结算份数	,
	sum(isnull(js.结算金额,0)) 	as 结算金额	,
    sum(isnull(js.已结算已签金额,0)) as 已结算已签金额,
     case when sum(isnull(js.已结算已签金额,0))  =0 then  0  else   (sum(isnull(js.结算金额,0)) - sum(isnull(js.已结算已签金额,0)) ) / sum(isnull(js.已结算已签金额,0)) end  as 结算偏差率, -- （结算金额-合同总金额）/合同总金额*100%
	( 
	   case when  sum(isnull(js.已签份数,0))  = 0 THEN 0 ELSE  sum(isnull(js.结算份数,0)) *1.0 / sum(isnull(js.已签份数,0)) end + 
	   case when  sum(isnull(js.已签金额,0))  = 0 then 0 ELSE  SUM(isnull(js.结算金额,0)) *1.0 / sum(isnull(js.已签金额,0)) end
	 )  /2  as 结算综合完成率	 ,
     case when  sum(isnull(js.已签份数,0))  = 0 THEN 0 ELSE  sum(isnull(js.结算份数,0)) *1.0 / sum(isnull(js.已签份数,0)) end as  综合结算率_份数 ,
	case when  sum(isnull(js.已签金额,0))  = 0 THEN  0 ELSE  SUM(isnull(js.结算金额,0)) *1.0 / sum(isnull(js.已签金额,0)) end as 综合结算率_金额	 	 
  FROM data_Wide_Dws_s_WqBaseStatic_Organization org
  inner join  data_Wide_Dws_s_WqBaseStatic_Organization porg  on porg.组织架构ID = org.组织架构父级ID and  porg.组织架构类型 =2
  INNER join  #Js js ON  org.组织架构ID =js.ParentGUID
  WHERE  org.组织架构类型 =3 and  js.项目维度 ='项目'
  group by  porg.组织架构ID,
	porg.组织架构名称,
	porg.组织架构类型,
	porg.组织架构编码
	--平台公司层级
union  all 
  SELECT  
	pporg.组织架构ID,
	pporg.组织架构名称,
	pporg.组织架构类型,
	pporg.组织架构编码,
	null as 项目维度,
	null as 项目GUID,
	null as 项目名称,
	null as 项目分期名称,
	null as 项目分期GUID,
	sum(isnull(js.已签金额,0))  as 合同总金额,
	sum(isnull(js.已签份数,0))  as 合同份数		,
	sum(isnull(js.结算份数,0))  as 结算份数	,
	sum(isnull(js.结算金额,0))  as 结算金额	,
    sum(isnull(js.已结算已签金额,0)) as 已结算已签金额,
	case when sum(isnull(js.已结算已签金额,0))  =0 then  0  else   (sum(isnull(js.结算金额,0)) - sum(isnull(js.已结算已签金额,0)) ) / sum(isnull(js.已结算已签金额,0)) end  as 结算偏差率, -- （结算金额-合同总金额）/合同总金额*100%
		( 
	   case when  sum(isnull(js.已签份数,0))  = 0 THEN 0 ELSE  sum(isnull(js.结算份数,0)) *1.0 / sum(isnull(js.已签份数,0)) end + 
	   case when  sum(isnull(js.已签金额,0))  = 0 THEN 0 ELSE  sum(isnull(js.结算金额,0)) *1.0 / sum(isnull(js.已签金额,0)) end
	 )  /2  as 结算综合完成率	 ,
    case when  sum(isnull(js.已签份数,0))  = 0 THEN 0 ELSE  sum(isnull(js.结算份数,0)) *1.0 / sum(isnull(js.已签份数,0)) end as  综合结算率_份数 ,
	case when  sum(isnull(js.已签金额,0))  = 0 THEN 0 ELSE  sum(isnull(js.结算金额,0)) *1.0 / sum(isnull(js.已签金额,0)) end as 综合结算率_金额	 	
  FROM data_Wide_Dws_s_WqBaseStatic_Organization org
  inner join  data_Wide_Dws_s_WqBaseStatic_Organization porg  on porg.组织架构ID = org.组织架构父级ID and  porg.组织架构类型 =2
  inner join  data_Wide_Dws_s_WqBaseStatic_Organization pporg  on pporg.组织架构ID = porg.组织架构父级ID and  pporg.组织架构类型 =1
  INNER join  #Js js ON  org.组织架构ID =js.ParentGUID
  WHERE  org.组织架构类型 =3 and  js.项目维度 ='项目'
  group by  pporg.组织架构ID,
	pporg.组织架构名称,
	pporg.组织架构类型,
	pporg.组织架构编码


 --删除临时表
 drop  table  #Js
