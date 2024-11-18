/*
chenjw add 2024-10-14
*/
--//////////////////////////1.1项目动态成本分析
--科目合计
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
    '科目合计' AS 科目,
    convert(varchar(50), org.组织架构名称) +'-科目合计'    as id,
    null as pid,
    --计划阶段
    lxdw.立项总投资 AS 立项目标成本,
    lxdw.定位总投资 AS 定位目标成本,
    cbi.目标成本 AS 执行版目标成本,
    --动态阶段
    cbi.动态成本 AS 总成本,
    cbi.已发生成本 AS 已实现,
    cbi.合同性成本 AS 已签合同,
    cbi.已支付成本 AS 已支付,
    isnull(cbi.已发生成本,0 ) - isnull( cbi.已支付成本,0 ) AS 已发生待支付,
    cbi.待发生成本 as 待实现,
    --降本目标
    cbi.降本任务 AS 总成本降本目标,
    isnull(cbi.目标成本,0) - isnull(cbi.动态成本,0) AS 已实现降本金额,
    case when isnull(cbi.降本任务,0) =0 then  0  else (isnull(cbi.目标成本,0) - isnull(cbi.动态成本,0)) /  isnull(cbi.降本任务,0) end AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
WHERE 1 = 1
      AND org.组织架构类型 IN ( 1, 2 )
      AND org.平台公司名称 = '湾区公司'
	  --AND DATEDIFF(dd, org.清洗时间, GETDATE()) = 0
--地价
UNION ALL
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
    '地价' AS 科目,
    convert(varchar(50), org.组织架构名称) +'-地价'  as id,
    convert(varchar(50), org.组织架构名称) +'-科目合计' as pid,
    --计划阶段
    lxdw.立项土地款 AS 立项目标成本,
    lxdw.定位土地款 AS 定位目标成本,
    isnull(cbi.目标成本直投,0) - isnull(cbi.目标成本除地价外直投,0) AS 执行版目标成本,
    --动态阶段
    isnull(cbi.动态成本直投,0) - isnull(cbi.动态成本除地价外直投,0) AS 总成本,
    isnull(cbi.已发生成本直投,0) - isnull(cbi.已发生成本除地价外直投,0) AS 已实现,
    isnull(cbi.合同性成本直投,0) - isnull(cbi.合同性成本除地价外直投,0) AS 已签合同,
    isnull(cbi.已支付成本直投,0) - isnull(cbi.已支付成本除地价外直投,0) AS 已支付,
    (isnull(cbi.已发生成本直投,0) - isnull(cbi.已发生成本除地价外直投,0)) - isnull(cbi.已支付成本直投,0) - isnull(cbi.已支付成本除地价外直投,0) AS 已发生待支付,
    isnull(cbi.待发生成本直投,0) - isnull(cbi.待发生成本除地价外直投,0) as  待实现,
    --降本目标
    isnull(cbi.直投降本任务,0) - isnull(cbi.除地价外直投降本任务,0) AS 总成本降本目标,
    (isnull(cbi.目标成本直投,0) - isnull(cbi.目标成本除地价外直投,0)) -(isnull(cbi.动态成本直投,0) - isnull(cbi.动态成本除地价外直投,0) )  AS 已实现降本金额,
    case when ( isnull(cbi.直投降本任务,0) - isnull(cbi.除地价外直投降本任务,0) ) = 0 then  0 
       else  
       ( (isnull(cbi.目标成本直投,0) - isnull(cbi.目标成本除地价外直投,0)) -(isnull(cbi.动态成本直投,0) - isnull(cbi.动态成本除地价外直投,0) )  ) / 
       ( isnull(cbi.直投降本任务,0) - isnull(cbi.除地价外直投降本任务,0) ) end  AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
WHERE 1 = 1
      AND org.组织架构类型 IN ( 1, 2 )
      AND org.平台公司名称 = '湾区公司'
      --AND DATEDIFF(dd, org.清洗时间, GETDATE()) = 0
--除地价外直投
UNION ALL
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
    '除地价外直投' AS 科目,
    convert(varchar(50), org.组织架构名称) +'-除地价外直投'  as id,
    convert(varchar(50), org.组织架构名称) +'-科目合计'  as pid, 
    --计划阶段
    lxdw.立项除地价外直投 AS 立项目标成本,
    lxdw.定位除地价外直投 AS 定位目标成本,
    cbi.目标成本除地价外直投 AS 执行版目标成本,
    --动态阶段
    cbi.动态成本除地价外直投 AS 总成本,
    cbi.已发生成本除地价外直投 AS 已实现,
    cbi.合同性成本除地价外直投 AS 已签合同,
    cbi.已支付成本除地价外直投 AS 已支付,
    isnull(cbi.已发生成本除地价外直投,0 ) - isnull( cbi.已支付成本除地价外直投,0 ) AS 已发生待支付,
    cbi.待发生成本除地价外直投 as 待实现,
    --降本目标
    cbi.除地价外直投降本任务 AS 总成本降本目标,
    isnull(cbi.目标成本除地价外直投,0) - isnull(cbi.动态成本除地价外直投,0) AS 已实现降本金额,
    case when isnull(cbi.除地价外直投降本任务,0) =0 then  0  else (isnull(cbi.目标成本除地价外直投,0) - isnull(cbi.动态成本除地价外直投,0) ) /  isnull(cbi.除地价外直投降本任务,0) end AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi  ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
WHERE 1 = 1
      AND org.组织架构类型 IN ( 1, 2 )
      AND org.平台公司名称 = '湾区公司'
      --AND DATEDIFF(dd, org.清洗时间, GETDATE()) = 0
--营销费
UNION ALL
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
    '营销费' AS 科目,
    convert(varchar(50), org.组织架构名称) +'-营销费'  as id,
    convert(varchar(50), org.组织架构名称) +'-科目合计'  as pid,     
    --计划阶段
    lxdw.立项营销费用 AS 立项目标成本,
    lxdw.定位营销费用 AS 定位目标成本,
    cbi.目标成本营销费用 AS 执行版目标成本,
    --动态阶段
    cbi.动态成本营销费用 AS 总成本,
    cbi.已发生成本营销费用 AS 已实现,
    cbi.合同性成本营销费用 AS 已签合同,
    cbi.已支付成本营销费用 AS 已支付,
    isnull(cbi.已发生成本营销费用,0 ) - isnull( cbi.已支付成本营销费用,0 ) AS 已发生待支付,
    cbi.待发生成本营销费用 as 待实现,
    --降本目标
    cbi.营销费用降本任务 AS 总成本降本目标,
    isnull(cbi.目标成本营销费用,0) - isnull(cbi.动态成本营销费用,0) AS 已实现降本金额,
    case when isnull(cbi.营销费用降本任务,0) =0 then  0  else (isnull(cbi.目标成本营销费用,0) - isnull(cbi.动态成本营销费用,0)) /  isnull(cbi.营销费用降本任务,0) end AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
WHERE 1 = 1
      AND org.组织架构类型 IN ( 1, 2 )
      AND org.平台公司名称 = '湾区公司'
      --AND DATEDIFF(dd, org.清洗时间, GETDATE()) = 0
--管理费
UNION ALL
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
    '管理费' AS 科目,
    convert(varchar(50), org.组织架构名称) +'-管理费'  as id,
    convert(varchar(50), org.组织架构名称) +'-科目合计'  as pid,    
    --计划阶段
    lxdw.立项管理费用  AS 立项目标成本,
    lxdw.定位管理费用  AS 定位目标成本,
    cbi.目标成本管理费用 AS 执行版目标成本,
    --动态阶段
    cbi.动态成本管理费用 AS 总成本,
    cbi.已发生成本管理费用 AS 已实现,
    cbi.合同性成本管理费用 AS 已签合同,
    cbi.已支付成本管理费用 AS 已支付,
    isnull(cbi.已发生成本管理费用,0 ) - isnull( cbi.已支付成本管理费用,0 ) AS 已发生待支付,
    cbi.待发生成本管理费用 as 待实现,
    --降本目标
    cbi.管理费用降本任务 AS 总成本降本目标,
    isnull(cbi.目标成本管理费用,0) - isnull(cbi.动态成本管理费用,0) AS 已实现降本金额,
    case when isnull(cbi.管理费用降本任务,0) =0 then  0  else (isnull(cbi.目标成本管理费用,0) - isnull(cbi.动态成本管理费用,0)) /  isnull(cbi.管理费用降本任务,0) end AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
WHERE 1 = 1
      AND org.组织架构类型 IN ( 1, 2 )
      AND org.平台公司名称 = '湾区公司'
      -- AND DATEDIFF(dd, org.清洗时间, GETDATE()) = 0
--财务费
UNION ALL
SELECT 
    org.清洗时间,
    org.组织架构ID,
    org.组织架构类型,
    org.组织架构名称,
    org.组织架构父级ID,
    '财务费' AS 科目,
    convert(varchar(50), org.组织架构名称) +'-财务费'  as id,
    convert(varchar(50), org.组织架构名称) +'-科目合计'  as pid,        
    --计划阶段
    lxdw.立项财务费用账面 AS 立项目标成本,
    lxdw.定位财务费用 AS 定位目标成本,
    cbi.目标成本财务费用 AS 执行版目标成本,
    --动态阶段
    cbi.动态成本财务费用 AS 总成本,
    cbi.已发生成本财务费用 AS 已实现,
    cbi.合同性成本财务费用 AS 已签合同,
    cbi.已支付成本财务费用 AS 已支付,
    isnull(cbi.已发生成本财务费用,0 ) - isnull( cbi.已支付成本财务费用,0 ) AS 已发生待支付,
    cbi.待发生成本财务费用 as 待实现,
    --降本目标
    cbi.财务费用降本任务 AS 总成本降本目标,
    isnull(cbi.目标成本财务费用,0) - isnull(cbi.动态成本财务费用,0) AS 已实现降本金额,
    case when isnull(cbi.财务费用降本任务,0) =0 then  0  else (isnull(cbi.目标成本财务费用,0) - isnull(cbi.动态成本财务费用,0)) /  isnull(cbi.财务费用降本任务,0) end AS 达成率
FROM dw_s_WqBaseStatic_Organization org
    LEFT JOIN [dbo].[dw_s_WqBaseStatic_CbInfo] cbi  ON org.组织架构ID = cbi.组织架构ID AND org.清洗时间id = cbi.清洗时间id
    left join [dw_s_WqBaseStatic_LxdwInfo] lxdw on org.组织架构ID = lxdw.组织架构ID AND org.清洗时间id = lxdw.清洗时间id
WHERE 1 = 1
      AND org.组织架构类型 IN ( 1, 2 )
      AND org.平台公司名称 = '湾区公司'
      --AND DATEDIFF(dd, org.清洗时间, GETDATE()) = 0;
