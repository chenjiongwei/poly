-- ============================================
-- 1. 获取今日收款单相关数据，并存入临时表#g
--    - 包含业务单元、项目、POS等重要字段
--    - 仅获取 GetDate 的时分秒和毫秒不为 0 的记录
-- ============================================

SELECT 
    v.BuGUID,           -- 业务单元GUID
    v.ProjGUID,         -- 项目GUID
    g.PosCode,          -- POS机编号
    g.PosGUID,          -- POS机GUID
    g.YhPayform,        -- 银行收款方式（如：POS机、现金等）
    g.GetinGUID,        -- 收款GUID
    g.Amount,           -- 收款金额
    g.GetDate,          -- 收款日期
    v.VouchGUID,        -- 单据GUID
    v.VouchType,        -- 单据类型
    v.CreatedOn,
    v.RzDate,
	v.Jkr,
	g.JfDate
INTO #g
FROM s_Getin g
INNER JOIN s_Voucher v ON g.VouchGUID = v.VouchGUID
WHERE g.Status IS NULL                                    -- 状态为NULL表示有效
     AND DATEDIFF(year, g.GetDate, GETDATE()) = 0          -- 仅统计今天的数据
     AND v.VouchType in ( '收款单','转账单')                             -- 只统计收款单类型
    -- ASCAND g.YhPayform = 'POS机'
     -- 查询 GetDate 的时分秒和毫秒信息不为0
        --  AND (DATEPART(HOUR, g.JfDate) <> 0 
        --  OR DATEPART(MINUTE, g.JfDate) <> 0 
        --  OR DATEPART(SECOND, g.JfDate) <> 0
        --  OR DATEPART(MILLISECOND, g.JfDate) <> 0)    

-- ============================================
-- 2. 统计各业务单元“POS机”收款相关占比
--    - 逐业务单元统计总收款笔数、POS收款笔数及比例
--    - 统计总收款金额、POS收款金额及比例
-- ============================================
SELECT
    t.BUGUID as 公司GUID,                        -- 业务单元GUID
    t.BUName as 公司名称,                        -- 业务单元名称
    t.TotalSKNum as 总收款笔数,                      -- 总收款笔数
    t.postSKNum as 使用POS机收款笔数,                       -- 使用POS机收款笔数
    t.znpostSKNum as 智能POS机收款笔数,
    CASE 
        WHEN ISNULL(t.TotalSKNum, 0) = 0 THEN 0
        ELSE t.postSKNum * 1.0 / t.TotalSKNum
    END  as POS收款笔数占比,              -- POS收款笔数占比
    case when  isnull(t.TotalSKNum,0) =0 then 0 else isnull(t.znpostSKNum,0) *1.0 / isnull(t.TotalSKNum,0) end 智能POS机收款占比,
    t.TotalZzNum as 总转账笔数,                   -- 总收款金额
    t.postZzNum as POS机转账笔数,                    -- POS机收款金额
    CASE 
        WHEN ISNULL(t.TotalZzNum, 0) = 0 THEN 0
        ELSE t.postZzNum * 1.0 / t.TotalZzNum
    END AS POS转账笔数占比,            -- POS收款金额占比
    t.znpostZzNum as 智能POS机转账笔数,
    case when  isnull(t.TotalZzNum,0) =0 then 0 else isnull(t.znpostZzNum,0) *1.0 / isnull(t.TotalZzNum,0) end 智能POS机转账占比
FROM (
    SELECT
        bu.BUGUID,                   -- 业务单元GUID
        bu.BUName,                   -- 业务单元名称
        sum(case when VouchType ='收款单' then  1  else 0  end ) AS TotalSKNum,        -- 总收款笔数
        SUM(CASE WHEN VouchType ='收款单' and g.YhPayform = 'POS机' THEN 1 ELSE 0 END) AS postSKNum, -- POS机收款笔数
        SUM(CASE WHEN VouchType ='收款单' and g.YhPayform = 'POS机' and ( DATEPART(HOUR, g.JfDate) <> 0  OR DATEPART(MINUTE, g.JfDate) <> 0 
        OR DATEPART(SECOND, g.JfDate) <> 0 ) THEN 1 ELSE 0 END) AS znpostSKNum, -- 智能POS机收款笔数       
        SUM(case when VouchType ='转账单' then  1  else 0  end ) AS TotalZzNum, -- 总收款金额
        SUM(CASE WHEN VouchType ='转账单' and g.YhPayform = 'POS机' THEN 1 ELSE 0 END) AS postZzNum, -- POS机收款金额
        SUM(CASE WHEN VouchType ='转账单' and g.YhPayform = 'POS机' and ( DATEPART(HOUR, g.JfDate) <> 0  OR DATEPART(MINUTE, g.JfDate) <> 0 
        OR DATEPART(SECOND, g.JfDate) <> 0 ) THEN 1 ELSE 0 END) AS znpostZzNum
    FROM #g g
    INNER JOIN myBusinessUnit bu ON bu.BUGUID = g.BuGUID
    GROUP BY bu.BUGUID, bu.BUName
) t

UNION ALL

-- ============================================
-- 3. 汇总全局（全公司/集团）“POS机”收款相关占比
--    - 此处BUGUID和BUName写死为公司集团，统计全量，不分业务单元
-- ============================================
SELECT
    '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' AS 公司GUID,  -- 集团BU GUID（写死）
    '保利发展集团' AS 公司名称,                         -- 集团名称
    t.TotalSKNum as 总收款笔数,                      -- 总收款笔数
    t.postSKNum as 使用POS机收款笔数,                       -- 使用POS机收款笔数
    t.znpostSKNum as 智能POS机收款笔数,
    CASE 
        WHEN ISNULL(t.TotalSKNum, 0) = 0 THEN 0
        ELSE t.postSKNum * 1.0 / t.TotalSKNum
    END  as POS收款笔数占比,              -- POS收款笔数占比
    case when  isnull(t.TotalSKNum,0) =0 then 0 else isnull(t.znpostSKNum,0) *1.0 / isnull(t.TotalSKNum,0) end 智能POS机收款占比,
    t.TotalZzNum as 总转账笔数,                   -- 总收款金额
    t.postZzNum as POS机转账笔数,                    -- POS机收款金额
    CASE 
        WHEN ISNULL(t.TotalZzNum, 0) = 0 THEN 0
        ELSE t.postZzNum * 1.0 / t.TotalZzNum
    END AS POS转账笔数占比,            -- POS收款金额占比
    t.znpostZzNum as 智能POS机转账笔数,
    case when  isnull(t.TotalZzNum,0) =0 then 0 else isnull(t.znpostZzNum,0) *1.0 / isnull(t.TotalZzNum,0) end 智能POS机转账占比
FROM (
    SELECT
        sum(case when VouchType ='收款单' then  1  else 0  end ) AS TotalSKNum,        -- 总收款笔数
        SUM(CASE WHEN VouchType ='收款单' and g.YhPayform = 'POS机' THEN 1 ELSE 0 END) AS postSKNum, -- POS机收款笔数
        SUM(CASE WHEN VouchType ='收款单' and g.YhPayform = 'POS机' and ( DATEPART(HOUR, g.JfDate) <> 0  OR DATEPART(MINUTE, g.JfDate) <> 0 
        OR DATEPART(SECOND, g.JfDate) <> 0 ) THEN 1 ELSE 0 END) AS znpostSKNum, -- 智能POS机收款笔数       
        SUM(case when VouchType ='转账单' then  1  else 0  end ) AS TotalZzNum, -- 总收款金额
        SUM(CASE WHEN VouchType ='转账单' and g.YhPayform = 'POS机' THEN 1 ELSE 0 END) AS postZzNum, -- POS机收款金额
        SUM(CASE WHEN VouchType ='转账单' and g.YhPayform = 'POS机' and ( DATEPART(HOUR, g.JfDate) <> 0  OR DATEPART(MINUTE, g.JfDate) <> 0 
        OR DATEPART(SECOND, g.JfDate) <> 0 ) THEN 1 ELSE 0 END) AS znpostZzNum
    FROM #g g
    INNER JOIN myBusinessUnit bu ON bu.BUGUID = g.BuGUID
) t
-- 删除临时表
drop  Table #g