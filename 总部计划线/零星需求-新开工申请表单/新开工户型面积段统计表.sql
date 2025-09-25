use erp25
go


-- ==========================================
-- 1. 汇总销售房间信息（订单和合同），只取激活状态
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
    FROM s_Order WITH (NOLOCK)
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
    FROM s_Contract WITH (NOLOCK)
    WHERE Status = '激活'
),

-- ==========================================
-- 2. 获取已开工楼栋信息（通过计划任务表判断实际开工时间）
-- ==========================================
#Kg AS (
    SELECT DISTINCT 
        ms.SaleBldGUID,                 -- 销售楼栋GUID
        c.实际开工实际完成时间           -- 实际开工完成时间
    FROM mdm_SaleBuild ms WITH (NOLOCK)
    INNER JOIN mdm_GCBuild gc WITH (NOLOCK)
        ON ms.GCBldGUID = gc.GCBldGUID
    LEFT JOIN MyCost_Erp352.dbo.p_HkbBiddingBuilding2BuildingWork b WITH (NOLOCK)
        ON ms.GCBldGUID = b.BuildingGUID
    LEFT JOIN MyCost_Erp352.dbo.jd_PlanTaskExecuteObjectForReport c WITH (NOLOCK)
        ON b.budguid = c.ztguid
)

-- ==========================================
-- 3. 查询已建立房间的楼栋及相关统计
-- ==========================================

    SELECT 
        r.buguid,
        mpp.ProjGUID,                                   -- 平台公司/母项目GUID
        r.ProjGUID AS fqProjguid,                       -- 分期项目GUID
        p.projname ,
        r.BldGUID,                                      -- 楼栋GUID
        bd.ProductType,                                 -- 产品类型
        bd.productName,                                 -- 产品名称 
        huxing ,                                         -- 户型
        RoomStru ,                                       -- 房间结构
        ISNULL(sr.zxbz, r.Zxbz) AS Zxbz,                -- 装修标准（优先取销售表，否则取房间表）
        COUNT(1) AS 房间总套数,                         -- 房间总数
        sum(isnull(r.bldarea,0)) as 房间总建筑面积,        -- 房间总建筑面积
        SUM(CASE WHEN kg.实际开工实际完成时间 IS NOT NULL THEN 1 ELSE 0 END) AS 已开工套数, -- 已开工房间数
        SUM(CASE WHEN sr.RoomGUID IS NOT NULL THEN 1 ELSE 0 END) AS 已售套数,      -- 已售房间数
        SUM(ISNULL(sr.JyTotal, 0)) AS 已售金额,                                 -- 已售总金额
        SUM(ISNULL(sr.BldArea, 0)) AS 已售面积,                                 -- 已售总面积
        CASE 
            WHEN SUM(ISNULL(sr.BldArea, 0)) = 0 THEN 0 
            ELSE SUM(ISNULL(sr.JyTotal, 0)) / SUM(ISNULL(sr.BldArea, 0)) 
        END AS 已售均价                                                        -- 已售均价（元/㎡）
    INTO #bldRoom 
    FROM 
        p_room r WITH (NOLOCK)
        LEFT JOIN #saleroom sr ON sr.RoomGUID = r.RoomGUID                        -- 关联销售信息
        INNER JOIN p_Building bd WITH (NOLOCK)  ON r.BldGUID = bd.BldGUID                          -- 关联楼栋
        inner join p_project p WITH (NOLOCK) on p.projguid =r.projguid -- 关联项目表
        LEFT JOIN #Kg kg   ON kg.SaleBldGUID = bd.BldGUID                     -- 关联开工信息
        INNER JOIN mdm_Project mp WITH (NOLOCK)  ON mp.ProjGUID = r.ProjGUID                        -- 关联分期项目
        LEFT JOIN mdm_Project mpp WITH (NOLOCK)  ON mpp.ProjGUID = mp.ParentProjGUID                -- 关联母项目/平台公司
    WHERE 
        IsVirtualRoom = 0                                      -- 剔除虚拟房间
        AND bd.ProductType IN ('住宅', '高级住宅')              -- 只统计住宅类
        -- and  r.BldGUID ='91934870-9109-4884-A8F2-2D37B8CE66DF'
        -- and r.BUGUID ='B7B03F13-566B-409C-A960-AA2C91A384A4' -- 湖北公司
    GROUP BY  
        r.buguid, 
        mpp.ProjGUID, 
        p.projname,
        r.ProjGUID,
        r.BldGUID,
		bd.ProductType,
		bd.productName,
        r.huxing,
        r.RoomStru,
        ISNULL(sr.zxbz, r.Zxbz)      
               

-- ==========================================
-- 4. 查询户型设置信息，将户型设置表（p_hxset）中相关字段提取到临时表#hxset
-- ==========================================
SELECT
    huxingguid,     -- 户型设置GUID，唯一标识
    projguid,       -- 项目GUID
    huxing,         -- 户型名称
    roomstru,       -- 房间结构
    CEILING(bldarea) as bldarea ,        -- 标准建筑面积
    CEILING(tnarea) as tnarea,         -- 标准套内面积
    zxbz            -- 装修标准
INTO #hxset         -- 存入临时表#hxset，后续用于关联
FROM
    p_hxset WITH (NOLOCK)
WHERE 
    (1 = 1)         -- 预留条件，当前无筛选，后续可扩展
    -- 仅用于已经建立房间的楼栋的户型设置

-- ==========================================
-- 5. 关联户型设置信息，将房间统计与户型设置进行关联，补充标准建筑面积
-- ==========================================
SELECT
    a.buguid,
    bu.buname,
    a.ProjGUID,
    a.fqProjguid,
    a.projname      AS 项目名称,
    a.ProductType as 产品类型,
    a.productName as 产品名称,
    a.huxing        AS 户型,
    a.RoomStru      AS 房间结构,
    a.Zxbz          AS 装修标准,
    b.bldarea       AS 建筑面积,
    SUM(房间总套数)     AS 房间总套数,
    SUM(已开工套数)     AS 已开工套数,
    SUM(已售套数)       AS 已售套数,
    SUM(已售金额)       AS 已售金额,
    SUM(已售面积)       AS 已售面积,
    -- case when  SUM(已售套数) =0 then 0  else  SUM(已售面积) /SUM(已售套数) end as  已售平均面积,
    case when  SUM(房间总套数) =0  then  0  else sum(房间总建筑面积) / SUM(房间总套数) end  as 平均面积,
    CASE 
        WHEN SUM(已售面积) = 0 THEN 0
        ELSE SUM(已售金额) / SUM(已售面积)
    END             AS 已售均价
FROM
    #bldRoom a
    INNER JOIN myBusinessUnit bu WITH (NOLOCK)
        ON bu.buguid = a.buguid
    LEFT JOIN #hxset b
        ON  a.fqProjguid = b.projguid      -- 分期项目GUID关联
        AND a.HuXing = b.HuXing           -- 户型名称关联
        AND a.RoomStru = b.RoomStru       -- 房间结构关联
        AND a.zxbz = b.zxbz               -- 装修标准关联
GROUP BY
    a.buguid,
    bu.buname,
    a.ProjGUID,
    a.projname,
    a.ProductType,
    a.productName,
    a.fqProjguid,
    a.huxing,
    a.RoomStru,
    a.Zxbz,
    b.bldarea
ORDER BY
    a.projname,
    a.productType,
    a.productName,
    a.huxing,
    a.RoomStru,
    a.Zxbz,
    b.bldarea


-- 删除临时表
drop  Table #bldRoom,#hxset

