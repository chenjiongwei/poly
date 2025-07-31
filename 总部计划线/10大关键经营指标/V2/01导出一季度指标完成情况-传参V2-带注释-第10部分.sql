-- =============================================
-- 第十四部分: 结果汇总与输出
-- 合并所有临时表数据并输出最终结果
-- =============================================
SELECT *
FROM
(
    -- 合并所有临时表数据
    SELECT *
    FROM #sumqy  -- 总签约数据
    UNION
    SELECT *
    FROM #sumrg  -- 总认购数据
    UNION
    SELECT *
    FROM #sumrgfl  -- 项目分类认购数据
    UNION
    SELECT *
    FROM #sumrgflxx  -- 项目获取时间分类数据
    UNION
    SELECT *
    FROM #sumqyfenlei  -- 产品类型分类数据
    UNION
    SELECT *
    FROM #sumxjl  -- 净利率数据
    UNION
    SELECT *
    FROM #sumfeiyong  -- 营销费用数据
    UNION
    SELECT *
    FROM #sumjk  -- 巨亏项目数据
    UNION
    SELECT *
    FROM #sumccprg  -- 产成品数据
    UNION
    SELECT *
    FROM #sumqyfenleis  -- S级项目数据
) a
-- 按序号和口径名称排序
ORDER BY a.num,
         口径;

-- =============================================
-- 第十五部分: 清理临时表
-- 删除所有创建的临时表
-- =============================================
DROP TABLE 
           #sumqy,  -- 总签约数据临时表
           #sumqyfenlei,  -- 产品类型分类数据临时表
           #sumxjl,  -- 净利率数据临时表
           #fy,  -- 营销费用数据临时表
           #sumfeiyong,  -- 营销费率数据临时表
		   #sumrg,  -- 总认购数据临时表
		   #ccpqyjll,  -- 产成品签约记录临时表
		   #ord,  -- 订单数据临时表
		   #saleord,  -- 销售订单数据临时表
		   #sumccprg,  -- 产成品认购数据临时表
		   #sumjk,  -- 巨亏项目数据临时表
		   #sumqyfenleis,  -- S级项目数据临时表
		   #bnskp,  -- 本年首开项目临时表
		   #skp,  -- 首开项目临时表
		   #sumrgfl,  -- 项目分类认购数据临时表
		   #sumrgflxx;  -- 项目获取时间分类数据临时表