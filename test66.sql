-- ========================================================
-- Step 1：将指定楼盘名称的二级项目（level=2）筛选到临时表 #proj
-- ========================================================
SELECT 
    projguid,         -- 项目GUID，主键标识项目
    projname,         -- 项目名称
    projcode          -- 项目编码
INTO #proj
FROM p_Project
WHERE SpreadName IN (
    '佛山保利清能和府',
    '佛山映月湖保利天珺',
    '合肥琅悦',
    '合肥锦上',
    '合肥和光峯境',
    '合肥海上瑧悦',
    '合肥龙川瑧悦',
    '芜湖保利和光瑞府',
    '芜湖保利文华和颂',
    '阜阳保利大国璟'
)
AND Level = 2   -- 仅筛选二级项目


-- ============================================================
-- Step 2：查询上述项目（作为父项目）的各房间详细信息
-- （包括房间基本信息、价格等），实现表连接
-- ============================================================

SELECT 
    pp.projname         AS 项目名称,           -- 项目名称
    p.projname          AS 分期名称,           -- 分期名称
    er.BldFullName      AS 楼栋名称,           -- 楼栋名称
    er.ProductType      AS 产品类型,           -- 产品类型
    er.ProductName      AS 产品名称,           -- 产品名称
    er.roominfo         AS 房间详细描述,       -- 房间详细描述（可能为JSON或字符串）
    r.roomguid          AS 房间GUID,           -- 房间GUID
    r.HSZJ              AS 房间回收总价,       -- 房间合约总价
    r.JZHSDJ            AS 建筑回收单价,       -- 建筑单价（含税）
    r.BldArea           AS 房间建筑面积,       -- 房间建筑面积
    r.[Status]          AS 销售状态,           -- 销售状态
    ord.[BldCjPrice]    AS 成交单价,           -- 成交单价
    ord.JyTotal         AS 成家总价            -- 成家总价
FROM 
    p_room r
    INNER JOIN ep_room er 
        ON r.RoomGUID = er.RoomGUID           -- 连接房间扩展信息
    LEFT JOIN (
        SELECT 
            ProjGUID,
            RoomGUID,
            JyTotal,
            [BldCjPrice],
            TradeGUID
        FROM 
            s_Order
        WHERE 
            Status = '激活'

        UNION ALL

        SELECT 
            ProjGUID,
            RoomGUID,
            JyTotal,
            [BldCjPrice],
            TradeGUID
        FROM 
            s_Contract c
        WHERE 
            c.Status = '激活'
    ) ord 
        ON ord.RoomGUID = r.RoomGUID
    INNER JOIN mdm_project p 
        ON p.projguid = er.projguid           -- 连接项目主表，获取项目名称
    INNER JOIN p_project pj 
        ON pj.projguid = r.projguid
    LEFT JOIN p_project pp 
        ON pp.projcode = pj.parentcode 
        AND pp.level = 2
WHERE 
    EXISTS (
        -- 仅查找属于选定父项目列表下的房间信息
        SELECT 1 
        FROM #proj 
        WHERE p.parentprojguid = #proj.projguid   -- p 的父GUID等于#proj中项目GUID
    );


-- 删除临时表

DROP TABLE #proj