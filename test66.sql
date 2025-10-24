-- 声明公司ID（如需要可启用此变量）
-- declare @BUGUID varchar(400) ='512381FE-A9CB-E511-80B8-E41F13C51836' -- 广东公司

/**********************************************
 * 1. 获取涉及的楼栋GUID列表
 **********************************************/
SELECT DISTINCT
    bldguid
INTO #build
FROM p_room
WHERE status IN ('认购', '签约')
-- 只取涉及项目/公司时可加下方条件：
-- AND BUGUID in (SELECT Value FROM [dbo].[fn_Split2](@BUGUID, ','))

/**********************************************
 * 2. 整理每个楼栋的最大楼层号(MaxFloor)
 *    通过分组并对FLOOR字段处理去除"南""北"字样
 **********************************************/
SELECT 
    BldGUID,
    MAX(newFloor) AS MaxFloor
INTO #NewBldFloor
FROM (
    SELECT 
        BldGUID,
        ROW_NUMBER() OVER (PARTITION BY BldGUID ORDER BY MAX(FloorNo)) AS newFloor
    FROM ep_room
    WHERE ISNULL(FLOOR, '') <> '' 
    -- 针对公司筛选可以启用下方条件
    -- AND BUGUID IN (SELECT Value FROM [dbo].[fn_Split2](@BUGUID, ','))
    GROUP BY 
        BldGUID,
        REPLACE(REPLACE(FLOOR, '南', ''), '北', '')
) a
GROUP BY BldGUID

/**********************************************
 * 3. 计算并缓存每个住宅楼栋的天地楼层范围
 *    LowFloor：底部10%为低楼层（至少为1层）
 *    HighFloor：顶部10%为高楼层（至少为倒数第一层）
 *    MaxFloor：最大楼层号
 **********************************************/
SELECT 
    a.SaleBldGUID,
    rf.MaxFloor,
    CASE 
        WHEN ROUND(rf.MaxFloor*0.1, 0) = 0 THEN 1 
        ELSE ROUND(rf.MaxFloor*0.1, 0) 
    END AS LowFloor,
    CASE 
        WHEN ROUND(rf.MaxFloor*0.1, 0) = 0 THEN ROUND(rf.MaxFloor, 0)-1 
        ELSE ROUND(rf.MaxFloor - ROUND(rf.MaxFloor*0.1, 0), 0)+1 
    END AS HighFloor
INTO #bldMaxFloor
FROM p_lddb a
LEFT JOIN #NewBldFloor rf ON rf.bldguid = a.SaleBldGUID
INNER JOIN #build ytld ON ytld.bldguid = a.SaleBldGUID
WHERE a.ProductType IN ('住宅') 
    AND DATEDIFF(day, a.QXDate, GETDATE()) = 0

/**********************************************
 * 4. 缓存所有房间在其楼栋的天地楼层位置
 *    LowHighType: 1=低楼层; 2=高楼层; 3=普通楼层
 **********************************************/
SELECT 
    r.RoomGUID,
    LHFloor.SaleBldGUID AS BldGUID,
    LHFloor.MaxFloor,
    LHFloor.LowFloor,
    LHFloor.HighFloor,
    CASE 
        WHEN nr.newFloor > 0 AND nr.newFloor <= LHFloor.LowFloor THEN 1      -- 低楼层
        WHEN nr.newFloor >= LHFloor.HighFloor THEN 2                          -- 高楼层
        ELSE 3                                                                -- 中间普通楼层
    END AS LowHighType
INTO #LH_Room
FROM ep_room r
LEFT JOIN (
    -- 计算房间所在楼层的新楼层号（去除南北重复楼层）
    SELECT 
        BldGUID,
        REPLACE(REPLACE(FLOOR, '南', ''), '北', '') AS FLOOR,
        ROW_NUMBER() OVER (PARTITION BY BldGUID ORDER BY MAX(FloorNo)) AS newFloor
    FROM ep_room
    WHERE ISNULL(FLOOR, '') <> ''
    -- 可加公司条件
    -- AND BUGUID IN (SELECT Value FROM [dbo].[fn_Split2](@BUGUID, ','))
    GROUP BY 
        BldGUID,
        REPLACE(REPLACE(FLOOR, '南', ''), '北', '')
) nr ON nr.BldGUID = r.BldGUID 
    AND REPLACE(REPLACE(r.FLOOR, '南', ''), '北', '') = nr.FLOOR
INNER JOIN #bldMaxFloor LHFloor ON LHFloor.SaleBldGUID = r.BldGUID

/**********************************************
 * 5. 整合项目统计数据
 *    按项目及楼栋统计住宅套数、已售套数、未售套数与面积
 **********************************************/
SELECT 
    l.ProjGUID,                                 -- 项目GUID
    r.BldGUID,                                  -- 楼栋GUID

    -- 住宅楼层总套数
    SUM(1) AS 楼层总住宅套数,

    -- 住宅已售总套数
    SUM(CASE WHEN c.qsdate IS NOT NULL THEN 1 ELSE 0 END) AS 楼层总已售住宅套数,

    -- 非天地层（即中间楼层）未售住宅相关
    SUM(CASE WHEN b.LowHighType = 3 AND r.status NOT IN ('认购','签约') THEN 1 ELSE 0 END) AS 楼层非天地层未售住宅套数,
    SUM(CASE WHEN b.LowHighType = 3 AND r.status NOT IN ('认购','签约') THEN r.bldarea ELSE 0 END) AS 楼层非天地层未售住宅面积,
    SUM(CASE WHEN b.LowHighType = 3 AND r.status NOT IN ('认购','签约') THEN r.HSZJ ELSE 0 END) AS 楼层非天地层未售住宅金额,

    -- 天地层（低+高楼层）未售住宅相关
    SUM(CASE WHEN b.LowHighType <> 3 AND r.status NOT IN ('认购','签约') THEN 1 ELSE 0 END) AS 楼层天地层未售住宅套数,
    SUM(CASE WHEN b.LowHighType <> 3 AND r.status NOT IN ('认购','签约') THEN r.bldarea ELSE 0 END) AS 楼层天地层未售住宅面积,
    SUM(CASE WHEN b.LowHighType <> 3 AND r.status NOT IN ('认购','签约') THEN r.HSZJ ELSE 0 END) AS 楼层天地层未售住宅金额

    -- 如需缓存结果可打开下行
    -- INTO #loucengqibuzou

FROM p_room r
    -- 关联房间天地类型以及其物理楼栋信息
    INNER JOIN #LH_Room b ON r.RoomGUID = b.RoomGUID
    -- 关联楼栋表，限制统计口径当前在售楼盘
    LEFT JOIN p_lddb l ON r.BldGUID = l.SaleBldGUID AND DATEDIFF(dd, qxdate, GETDATE()) = 0
    -- 关联合同表，确定是否有签约
    LEFT JOIN s_contract c ON r.roomguid = c.roomguid AND c.status = '激活'
WHERE 
    r.IsVirtualRoom = 0                    -- 剔除虚拟房源
GROUP BY 
    l.ProjGUID,
    r.BldGUID