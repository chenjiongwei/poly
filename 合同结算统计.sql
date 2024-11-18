--//////////////////////////1.3项目结算情况分析
-- 平台公司和区事
SELECT
     org.清洗时间,
     org.组织架构ID,
     org.组织架构类型,
     org.组织架构名称,
     org.组织架构父级ID,
     convert(varchar(50),org.组织架构ID) as id,
     case when  org.组织架构类型 = 1 then  null else convert(varchar(50), org.组织架构父级ID) end  as  pid,
     '合计' as 分期,
     cbi.[合同总金额],
     cbi.[合同份数],
     cbi.[结算份数],
     cbi.[结算金额],
     cbi.[结算偏差率],
     cbi.[结算综合完成率],
     cbi.[综合结算率_份数],
     cbi.[综合结算率_金额]
FROM
     dw_s_WqBaseStatic_Organization org
     LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo_Extend] cbi ON org.组织架构ID = cbi.组织架构ID
     AND org.清洗时间id = cbi.清洗时间id
WHERE
     1 = 1
     AND org.组织架构类型 IN (1, 2)
     AND org.平台公司名称 = '湾区公司'
     AND DATEDIFF(DAY, org.清洗时间, GETDATE()) = 0
union all
-- 项目
SELECT
     org.清洗时间,
     org.组织架构ID,
     org.组织架构类型,
     org.组织架构名称,
     org.组织架构父级ID,
     convert(varchar(50),org.组织架构ID) + '分期合计' as id,
     case when  org.组织架构类型 = 1 then  null else  convert(varchar(50),org.组织架构父级ID) end  as  pid,
     '分期合计' as 分期,     
     cbi.[合同总金额],
     cbi.[合同份数],
     cbi.[结算份数],
     cbi.[结算金额],
     cbi.[结算偏差率],
     cbi.[结算综合完成率],
     cbi.[综合结算率_份数],
     cbi.[综合结算率_金额]
FROM
     dw_s_WqBaseStatic_Organization org
     LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo_Extend] cbi ON org.组织架构ID = cbi.组织架构ID
     AND org.清洗时间id = cbi.清洗时间id
WHERE
     1 = 1
     AND org.组织架构类型 IN (3)
     and cbi.项目维度 = '项目'
     AND org.平台公司名称 = '湾区公司'
     AND DATEDIFF(DAY, org.清洗时间, GETDATE()) = 0
union all
-- 分期
SELECT
     org.清洗时间,
     org.组织架构ID,
     org.组织架构类型,
     org.组织架构名称,
     org.组织架构父级ID,
     convert(varchar(50),org.组织架构ID) + cbi.项目分期名称 as id,
     convert(varchar(50),org.组织架构ID) + '分期合计'  as  pid,
     cbi.项目分期名称 as 分期,     
     cbi.[合同总金额],
     cbi.[合同份数],
     cbi.[结算份数],
     cbi.[结算金额],
     cbi.[结算偏差率],
     cbi.[结算综合完成率],
     cbi.[综合结算率_份数],
     cbi.[综合结算率_金额]
FROM
     dw_s_WqBaseStatic_Organization org
     LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo_Extend] cbi ON org.组织架构ID = cbi.组织架构ID
     AND org.清洗时间id = cbi.清洗时间id
WHERE
     1 = 1
     AND org.组织架构类型 IN (3)
     and cbi.项目维度 = '分期'
     AND org.平台公司名称 = '湾区公司'
     AND DATEDIFF(DAY, org.清洗时间, GETDATE()) = 0