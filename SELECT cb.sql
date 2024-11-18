SELECT cb.组织架构ID 组织架构ID,
    cb.组织架构名称 组织架构名称,
    cb.组织架构类型 组织架构类型,
    cb.组织架构编码 组织架构编码,
    ISNULL(cb.目标成本, 0) 目标成本,
    ISNULL(目标成本直投, 0) 目标成本直投,
    ISNULL(目标成本除地价外直投, 0) 目标成本除地价外直投,
    ISNULL(目标成本营销费用, 0) 目标成本营销费用,
    ISNULL(目标成本管理费用, 0) 目标成本管理费用,
    ISNULL(目标成本财务费用, 0) 目标成本财务费用,
    ISNULL(动态成本, 0) 动态成本,
    ISNULL(动态成本直投, 0) 动态成本直投,
    ISNULL(动态成本除地价外直投, 0) 动态成本除地价外直投,
    ISNULL(动态成本营销费用, 0) 动态成本营销费用,
    ISNULL(动态成本管理费用, 0) 动态成本管理费用,
    ISNULL(动态成本财务费用, 0) 动态成本财务费用,
    ISNULL(年初目标成本, 0) 年初目标成本,
    ISNULL(年初目标成本直投, 0) 年初目标成本直投,
    ISNULL(年初目标成本除地价外直投, 0) 年初目标成本除地价外直投,
    ISNULL(年初目标成本营销费用, 0) 年初目标成本营销费用,
    ISNULL(年初目标成本管理费用, 0) 年初目标成本管理费用,
    ISNULL(年初目标成本财务费用, 0) 年初目标成本财务费用,
    -- 已发生成本
    ISNULL(已发生成本, 0) AS 已发生成本,
    ISNULL(已发生成本直投, 0) AS 已发生成本直投,
    ISNULL(已发生成本除地价外直投, 0) AS 已发生成本除地价外直投,
    ISNULL(已发生成本营销费用, 0) AS 已发生成本营销费用,
    ISNULL(已发生成本管理费用, 0) AS 已发生成本管理费用,
    ISNULL(已发生成本财务费用, 0) AS 已发生成本财务费用,
    -- 待发生成本
    ISNULL(待发生成本, 0) AS 待发生成本,
    ISNULL(待发生成本直投, 0) 待发生成本直投,
    ISNULL(待发生成本除地价外直投, 0) AS 待发生成本除地价外直投,
    ISNULL(待发生成本营销费用, 0) AS 待发生成本营销费用,
    ISNULL(待发生成本管理费用, 0) AS 待发生成本管理费用,
    ISNULL(待发生成本财务费用, 0) AS 待发生成本财务费用,
    -- 已支付成本
    ISNULL(已支付成本, 0) AS 已支付成本,
    ISNULL(已支付成本直投, 0) AS 已支付成本直投,
    ISNULL(已支付成本除地价外直投, 0) AS 已支付成本除地价外直投,
    ISNULL(已支付成本营销费用, 0) AS 已支付成本营销费用,
    ISNULL(已支付成本管理费用, 0) AS 已支付成本管理费用,
    ISNULL(已支付成本财务费用, 0) AS 已支付成本财务费用,
    -- 合同性成本
    ISNULL(合同性成本, 0) AS 合同性成本,
    ISNULL(合同性成本直投, 0) AS 合同性成本直投,
    ISNULL(合同性成本除地价外直投, 0) AS 合同性成本除地价外直投,
    ISNULL(合同性成本营销费用, 0) AS 合同性成本营销费用,
    ISNULL(合同性成本管理费用, 0) AS 合同性成本管理费用,
    ISNULL(合同性成本财务费用, 0) AS 合同性成本财务费用,
    -- 降本任务
    ISNULL(降本任务,0) as 降本任务  ,
    ISNULL(直投降本任务,0) as 直投降本任务,
    ISNULL(除地价外直投降本任务,0) as 除地价外直投降本任务 ,
    ISNULL(营销费用降本任务,0) as 营销费用降本任务 ,
    ISNULL(管理费用降本任务,0) as 管理费用降本任务 ,
    ISNULL(财务费用降本任务 ,0) as 财务费用降本任务
  FROM ydkb_dthz_wq_deal_cbinfo cb
  WHERE cb.组织架构类型 <> 4
UNION ALL
SELECT bi.组织架构ID 组织架构ID,
    bi.组织架构名称 组织架构名称,
    4 组织架构类型,
    bi.组织架构编码 组织架构编码,
    ISNULL(cb.目标成本, 0) 目标成本,
    ISNULL(目标成本直投, 0) 目标成本直投,
    ISNULL(目标成本除地价外直投, 0) 目标成本除地价外直投,
    ISNULL(目标成本营销费用, 0) 目标成本营销费用,
    ISNULL(目标成本管理费用, 0) 目标成本管理费用,
    ISNULL(目标成本财务费用, 0) 目标成本财务费用,
    ISNULL(动态成本, 0) 动态成本,
    ISNULL(动态成本直投, 0) 动态成本直投,
    ISNULL(动态成本除地价外直投, 0) 动态成本除地价外直投,
    ISNULL(动态成本营销费用, 0) 动态成本营销费用,
    ISNULL(动态成本管理费用, 0) 动态成本管理费用,
    ISNULL(动态成本财务费用, 0) 动态成本财务费用,
    ISNULL(年初目标成本, 0) 年初目标成本,
    ISNULL(年初目标成本直投, 0) 年初目标成本直投,
    ISNULL(年初目标成本除地价外直投, 0) 年初目标成本除地价外直投,
    ISNULL(年初目标成本营销费用, 0) 年初目标成本营销费用,
    ISNULL(年初目标成本管理费用, 0) 年初目标成本管理费用,
    ISNULL(年初目标成本财务费用, 0) 年初目标成本财务费用,
    -- 已发生成本
    ISNULL(已发生成本, 0) AS 已发生成本,
    ISNULL(已发生成本直投, 0) AS 已发生成本直投,
    ISNULL(已发生成本除地价外直投, 0) AS 已发生成本除地价外直投,
    ISNULL(已发生成本营销费用, 0) AS 已发生成本营销费用,
    ISNULL(已发生成本管理费用, 0) AS 已发生成本管理费用,
    ISNULL(已发生成本财务费用, 0) AS 已发生成本财务费用,
    -- 待发生成本
    ISNULL(待发生成本, 0) AS 待发生成本,
    ISNULL(待发生成本直投, 0) 待发生成本直投,
    ISNULL(待发生成本除地价外直投, 0) AS 待发生成本除地价外直投,
    ISNULL(待发生成本营销费用, 0) AS 待发生成本营销费用,
    ISNULL(待发生成本管理费用, 0) AS 待发生成本管理费用,
    ISNULL(待发生成本财务费用, 0) AS 待发生成本财务费用,
    -- 已支付成本
    ISNULL(已支付成本, 0) AS 已支付成本,
    ISNULL(已支付成本直投, 0) AS 已支付成本直投,
    ISNULL(已支付成本除地价外直投, 0) AS 已支付成本除地价外直投,
    ISNULL(已支付成本营销费用, 0) AS 已支付成本营销费用,
    ISNULL(已支付成本管理费用, 0) AS 已支付成本管理费用,
    ISNULL(已支付成本财务费用, 0) AS 已支付成本财务费用,
    -- 合同性成本
    ISNULL(合同性成本, 0) AS 合同性成本,
    ISNULL(合同性成本直投, 0) AS 合同性成本直投,
    ISNULL(合同性成本除地价外直投, 0) AS 合同性成本除地价外直投,
    ISNULL(合同性成本营销费用, 0) AS 合同性成本营销费用,
    ISNULL(合同性成本管理费用, 0) AS 合同性成本管理费用,
    ISNULL(合同性成本财务费用, 0) AS 合同性成本财务费用
	--降本任务
    ISNULL(降本任务,0) as 降本任务  ,
    ISNULL(直投降本任务,0) as 直投降本任务,
    ISNULL(除地价外直投降本任务,0) as 除地价外直投降本任务 ,
    ISNULL(营销费用降本任务,0) as 营销费用降本任务 ,
    ISNULL(管理费用降本任务,0) as 管理费用降本任务 ,
    ISNULL(财务费用降本任务 ,0) as 财务费用降本任务
  FROM ydkb_dthz_wq_deal_cbinfo cb
 INNER JOIN [172.16.4.161].highdata_prod.dbo.Data_Wide_Dws_s_WqBaseStatic_Organization bi
     ON cb.组织架构名称 = bi.组织架构名称
        AND cb.组织架构父级id = bi.组织架构父级id
  WHERE cb.组织架构类型 = 4
        AND bi.组织架构类型 = 4
