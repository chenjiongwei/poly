-- 查询某日特定楼栋的面积表（示例，非本脚本核心逻辑）
-- select * from p_lddbamj where DATEDIFF(day, qxdate, getdate()) = 0 and SaleBldGUID = '92D42C7A-8B77-43CD-8A26-7EB12CA87275'

-- ==========================================
-- 1. 汇总销售房间信息（订单和合同），只取激活状态
--    生成临时表 #saleroom，包含所有激活订单和合同的房间及其装修标准
-- ==========================================
WITH #saleroom AS (
    -- 订单表：取激活订单
    SELECT 
        ProjGUID AS fqProjguid,      -- 项目GUID（分期）
        RoomGUID,                    -- 房间GUID
        TradeGUID,                   -- 交易GUID
        OrderGUID AS SaleGUID,       -- 销售主键（订单）
        JyTotal,                     -- 交易总价
        BldArea,                     -- 建筑面积
        ZxBz                         -- 装修标准
    FROM s_Order 
    WHERE Status = '激活'
    UNION  
    -- 合同表：取激活合同
    SELECT 
        ProjGUID AS fqProjguid,      -- 项目GUID（分期）
        RoomGUID,                    -- 房间GUID
        TradeGUID,                   -- 交易GUID
        ContractGUID AS SaleGUID,    -- 销售主键（合同）
        JyTotal,                     -- 交易总价
        BldArea,                     -- 建筑面积
        ZxBz                         -- 装修标准
    FROM s_Contract 
    WHERE Status = '激活'
)

-- ==========================================
-- 2. 查找房间表中装修标准为空，但销售表中有装修标准的房间
--    生成临时表 #roomZxBz，便于后续修复
-- ==========================================
SELECT 
    r.RoomGUID, 
    sr.ZxBz AS SaleZxBz,    -- 销售表中的装修标准
    r.ZxBz AS roomZxBz      -- 房间表中的装修标准（此时为空）
INTO #roomZxBz 
FROM p_room r
INNER JOIN #saleroom sr ON sr.RoomGUID = r.RoomGUID
WHERE ISNULL(sr.ZxBz, '') <> ''      -- 销售表有装修标准
  AND ISNULL(r.ZxBz, '') = ''        -- 房间表无装修标准

-- ==========================================
-- 3. 备份即将被修复的房间数据，便于回溯
--    只备份需要修复的房间
-- ==========================================
SELECT a.* 
INTO p_room_bak20250805
FROM p_room a
INNER JOIN #roomZxBz b ON a.RoomGUID = b.RoomGUID

-- ==========================================
-- 4. 用成交交易单上的装修标准，反向刷新房间的装修标准字段
--    只更新房间表中装修标准与销售表不一致的记录
-- ==========================================
UPDATE a
SET a.ZxBz = b.SaleZxBz
FROM p_room a
INNER JOIN #roomZxBz b ON a.RoomGUID = b.RoomGUID
WHERE a.ZxBz <> b.SaleZxBz





-- ==========================================
-- 5. 对于成交房间中，楼栋、户型、房间结构相同但装修标准为空的房间，
--    尝试用同楼栋同户型同结构下其他已成交房间的非空装修标准进行修复建议
--    便于后续批量修复或人工核查
-- ==========================================

-- 1. 汇总所有激活订单和合同的房间及其装修标准，生成临时表 #saleroom
WITH #saleroom AS (
    -- 订单表：取激活订单
    SELECT 
        ProjGUID AS fqProjguid,      -- 项目GUID（分期）
        RoomGUID,                    -- 房间GUID
        TradeGUID,                   -- 交易GUID
        OrderGUID AS SaleGUID,       -- 销售主键（订单）
        JyTotal,                     -- 交易总价
        BldArea,                     -- 建筑面积
        ZxBz                         -- 装修标准
    FROM s_Order 
    WHERE Status = '激活'
    UNION  
    -- 合同表：取激活合同
    SELECT 
        ProjGUID AS fqProjguid,      -- 项目GUID（分期）
        RoomGUID,                    -- 房间GUID
        TradeGUID,                   -- 交易GUID
        ContractGUID AS SaleGUID,    -- 销售主键（合同）
        JyTotal,                     -- 交易总价
        BldArea,                     -- 建筑面积
        ZxBz                         -- 装修标准
    FROM s_Contract 
    WHERE Status = '激活'
),

-- 2. 查找成交房间中，装修标准为空的房间（即销售表无装修标准）
#notexitstroomZxBz AS (
    SELECT 
        r.BldGUID,                  -- 楼栋GUID
        r.RoomGUID,                 -- 房间GUID
        r.HuXing,                   -- 户型
        r.RoomStru,                 -- 房间结构
        sr.ZxBz                     -- 销售表中的装修标准（此时为空）
    FROM p_room r
    INNER JOIN #saleroom sr ON sr.RoomGUID = r.RoomGUID
    WHERE ISNULL(sr.ZxBz, '') = ''  -- 销售表无装修标准
),

-- 3. 查找成交房间中，装修标准不为空的房间（即销售表有装修标准）
#exitsroomZxBz AS (
    SELECT 
        r.BldGUID,                  -- 楼栋GUID
        r.RoomGUID,                 -- 房间GUID
        r.HuXing,                   -- 户型
        r.RoomStru,                 -- 房间结构
        sr.ZxBz                     -- 销售表中的装修标准（不为空）
    FROM p_room r
    INNER JOIN #saleroom sr ON sr.RoomGUID = r.RoomGUID
    WHERE ISNULL(sr.ZxBz, '') <> '' -- 销售表有装修标准
)

-- 4. 通过楼栋、户型、房间结构关联，将有装修标准的房间标准推荐给无装修标准的房间
SELECT 
    a.*, 
    t.ZxBz 
FROM 
    #notexitstroomZxBz a
OUTER APPLY (
    SELECT TOP 1 
        b.ZxBz
    FROM 
        #exitsroomZxBz b 
    WHERE  
        a.BldGUID = b.BldGUID 
        AND a.HuXing = b.HuXing 
        AND a.RoomStru = b.RoomStru
    ORDER BY 
        b.ZxBz
) t
WHERE 
    ISNULL(t.ZxBz, '') <> ''