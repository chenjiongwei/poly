/***********************************************************************
 * 天地楼层统计宽表数据提取脚本（data_wide_dws_s_LHFloorBldHz取数）
 * 
 * 需求说明：
 *   - 住宅统计最高1层及最低两层的未售房间（天地层），其余为普通楼层。
 *   - 商业/办公类：若楼栋≤5层，天地层为2层及以上的商业；否则，仍统计最高1层及最低两层为天地层。
 *
 * 输出包括各类楼层的房间数量、面积、金额统计。
 ***********************************************************************/

-- -- 可用来限定公司范围
-- DECLARE @BUGUID VARCHAR(400) = '512381FE-A9CB-E511-80B8-E41F13C51836' -- 广东公司

/*********************************************************
 * 第一步：找出有成交信息（认购/签约）的楼栋（基础范围）
 *********************************************************/
SELECT DISTINCT
    bldguid
INTO #build
FROM p_room
WHERE status IN ('认购', '签约')


/*********************************************************
 * 第二步：整理每栋楼的最大楼层数
 * 方法：以ep_room为基础，剔除南北等楼字，统计每楼栋最大楼层
 *********************************************************/
SELECT 
    BldGUID,
    MAX(newFloor) AS MaxFloor
INTO #NewBldFloor
FROM (
    SELECT 
        BldGUID,
        ROW_NUMBER() OVER (PARTITION BY BldGUID ORDER BY MAX(FloorNo)) AS newFloor
    FROM ep_room
    WHERE ISNULL(floor, '') <> '' 
    GROUP BY 
        bldguid,
        REPLACE(REPLACE(FLOOR, '南', ''), '北', '')
) a
GROUP BY BldGUID


/*********************************************************
 * 第三步：分成住宅和商办两大类进行天地层分界
 *  1. 住宅：ProductType = '住宅','高级住宅'
 *      - LowFloor = 1 (最高1层)
 *      - HighFloor = CASE WHEN MaxFloor >= 2 THEN 2 ELSE MaxFloor END (最低两层)
 *  2. 商办：ProductType 不属于 '住宅','高级住宅','地下室/车库'
 *      - MaxFloor <= 5: LowFloor = 2, HighFloor = 3（2层及以上）
 *      - MaxFloor > 5 : LowFloor = 1 (最高1层), HighFloor = CASE WHEN MaxFloor >= 2 THEN 2 ELSE MaxFloor END (最低两层)
 *********************************************************/
SELECT 
    a.SaleBldGUID,
	case when a.ProductType IN ('住宅', '高级住宅') then  '住宅' 
	     when a.ProductType NOT IN ('住宅', '高级住宅', '地下室/车库') then  '商办'
		 else '其他' end  as  ProductTypeNew , 
    rf.MaxFloor,
    CASE 
        -- 住宅类：最低2层
        WHEN a.ProductType IN ('住宅', '高级住宅') THEN 
            CASE WHEN rf.MaxFloor >= 2 THEN 2 ELSE rf.MaxFloor END
        -- 商办类：小于等于5层，2层
        WHEN a.ProductType NOT IN ('住宅', '高级住宅', '地下室/车库') AND rf.MaxFloor <= 5 THEN 2
        -- 商办类：大于5层，最低2层
        WHEN a.ProductType NOT IN ('住宅', '高级住宅', '地下室/车库') AND rf.MaxFloor > 5 THEN 
            CASE WHEN rf.MaxFloor >= 2 THEN 2 ELSE rf.MaxFloor END
        ELSE NULL
    END AS LowFloor,
    CASE 
        -- 住宅类：最高1层
        WHEN a.ProductType IN ('住宅', '高级住宅') THEN  case when   rf.MaxFloor >2 then  rf.MaxFloor else null end 
        -- 商办类：楼层小于等于5层，2层及以上
        WHEN a.ProductType NOT IN ('住宅', '高级住宅', '地下室/车库') AND rf.MaxFloor <= 5 THEN 3
        -- 商办类：楼层大于5层，最高1层
        WHEN a.ProductType NOT IN ('住宅', '高级住宅', '地下室/车库') AND rf.MaxFloor > 5 THEN rf.MaxFloor
        ELSE NULL
    END AS HighFloor
INTO #bldMaxFloor
FROM p_lddb a
LEFT JOIN #NewBldFloor rf ON rf.bldguid = a.SaleBldGUID
INNER JOIN #build ytld ON ytld.bldguid = a.SaleBldGUID
WHERE  a.ProductType IS NOT NULL  
    AND a.ProductType <> '地下室/车库'
    AND DATEDIFF(DAY,a.QXDate,GETDATE()) = 0  


/****************************************************************************************
 * 第四步：标记每个房间的楼层归类（低天地层/高天地层/普通楼层），生成#LH_Room
 *
 * 规则说明：
 *   - 低天地层（LowHighType = 1）：
 *       - 住宅：最高1层（即newFloor=1）
 *       - 商办（>5层）：最高1层（即newFloor=1）
 *       - 商办（≤5层）：2层及以上（即newFloor >= 2）
 *   - 高天地层（LowHighType = 2）：
 *       - 住宅、商办（>5层）：最低2层（即newFloor >= HighFloor，通常高楼层）
 *       - 商办（≤5层）：3层及以上（即newFloor >= 3）
 *   - 普通楼层（LowHighType = 3）：
 *       - 不属于以上任一类别的其他楼层
 *
 * 备注：
 *   - newFloor为按照同楼栋去除南北后排序后的楼层号。
 *   - ProductTypeNew：'住宅'/'商办'。
 ****************************************************************************************/
SELECT 
    r.RoomGUID,
    LHFloor.SaleBldGUID         AS BldGUID,        -- 楼栋GUID
    LHFloor.ProductTypeNew,                       -- 住宅/商办/其他
    LHFloor.MaxFloor,                             -- 楼栋最大层数
    LHFloor.LowFloor,                             -- 天地层分界下层
    LHFloor.HighFloor,                            -- 天地层分界上层
    -- 判断房间lowhigh类型：1低天地层 2高天地层 3普通楼层
    CASE 
        -- 住宅或商办类（楼层>5）
        WHEN LHFloor.ProductTypeNew = '住宅' 
             OR (LHFloor.ProductTypeNew = '商办' AND LHFloor.MaxFloor > 5) THEN
            CASE 
                WHEN nr.newFloor > 0 AND nr.newFloor <= LHFloor.LowFloor THEN 1   -- 低天地层（如1层）
                WHEN nr.newFloor >= LHFloor.HighFloor THEN 2                      -- 高天地层（如顶楼/倒数二楼）
                ELSE 3                                                            -- 普通楼层
            END
        -- 商办类（楼层≤5）
        WHEN LHFloor.ProductTypeNew = '商办' AND LHFloor.MaxFloor <= 5 THEN
            CASE 
                WHEN nr.newFloor > 0 AND nr.newFloor > LHFloor.LowFloor   THEN 1   -- 2层以上都看作低天地层
                WHEN nr.newFloor >= LHFloor.HighFloor THEN 2                      -- 按规则（3层及以上看作高天地层）
                ELSE 3                                                            -- 普通楼层
            END
        -- 其他类型，按住宅/商办高层规则
        ELSE
            CASE 
                WHEN nr.newFloor > 0 AND nr.newFloor <= LHFloor.LowFloor THEN 1   -- 低天地层
                WHEN nr.newFloor >= LHFloor.HighFloor THEN 2                      -- 高天地层
                ELSE 3
            END
    END AS LowHighType
INTO #LH_Room
FROM ep_room r
LEFT JOIN (
    -- 为每个楼栋生成标准序号楼层（去除南/北、从1递增）
    SELECT 
        BldGUID,
        REPLACE(REPLACE(FLOOR, '南', ''), '北', '') AS FLOOR,
        ROW_NUMBER() OVER (PARTITION BY BldGUID ORDER BY MAX(FloorNo)) AS newFloor
    FROM ep_room
    WHERE ISNULL(FLOOR, '') <> ''
    GROUP BY 
        BldGUID,
        REPLACE(REPLACE(FLOOR, '南', ''), '北', '')
) nr 
    ON nr.BldGUID = r.BldGUID 
    AND REPLACE(REPLACE(r.FLOOR, '南', ''), '北', '') = nr.FLOOR
INNER JOIN #bldMaxFloor LHFloor ON LHFloor.SaleBldGUID = r.BldGUID    



/*********************************************************
 * 第五步：整合项目与楼栋，统计房间数量/面积/金额等
 *  各类统计项：
 *   - 楼层总住宅套数         = 房间总数
 *   - 楼层总已售住宅套数     = 有签约激活合同的房间数
 *   - 楼层非天地层未售住宅套数/面积/金额
 *   - 楼层天地层未售住宅套数/面积/金额
 *********************************************************/
SELECT 
    l.ProjGUID,           -- 项目GUID
    r.BldGUID,            -- 楼栋GUID
	l.ProductType,
	l.BldCode,
	MaxFloor, -- 总楼层数
	LowFloor, -- 低楼层起始楼层
	HighFloor, -- 高楼层
    -- 1. 全部住房总数
    SUM(1) AS 楼层总住宅套数,

    -- 2. 全部已售住宅数（有签约合同）
    SUM(CASE WHEN c.qsdate IS NOT NULL THEN 1 ELSE 0 END) AS 楼层总已售住宅套数,
    SUM(CASE WHEN r.status NOT IN ('认购','签约') THEN 1 ELSE 0 END) AS 楼层未售住宅套数,

    -- 3. 普通楼层（非天地层）未售住房统计
    SUM(CASE WHEN b.LowHighType = 3 AND r.status NOT IN ('认购','签约') THEN 1 ELSE 0 END) AS 楼层非天地层未售住宅套数, 
    SUM(CASE WHEN b.LowHighType = 3 AND r.status NOT IN ('认购','签约') THEN r.bldarea ELSE 0 END) AS 楼层非天地层未售住宅面积,
    SUM(CASE WHEN b.LowHighType = 3 AND r.status NOT IN ('认购','签约') THEN r.HSZJ ELSE 0 END) AS 楼层非天地层未售住宅金额,

    -- 4. 天地层（高/低）未售住房统计
    SUM(CASE WHEN b.LowHighType <> 3 AND r.status NOT IN ('认购','签约') THEN 1 ELSE 0 END) AS 楼层天地层未售住宅套数,
    SUM(CASE WHEN b.LowHighType <> 3 AND r.status NOT IN ('认购','签约') THEN r.bldarea ELSE 0 END) AS 楼层天地层未售住宅面积,
    SUM(CASE WHEN b.LowHighType <> 3 AND r.status NOT IN ('认购','签约') THEN r.HSZJ ELSE 0 END) AS 楼层天地层未售住宅金额

    -- -- 可直接存中间表
    -- INTO #loucengqibuzou
FROM p_room r
INNER JOIN #LH_Room b ON r.RoomGUID = b.RoomGUID
inner JOIN p_lddb l ON r.BldGUID = l.SaleBldGUID AND DATEDIFF(dd, qxdate, GETDATE()) = 0
LEFT JOIN s_contract c ON r.roomguid = c.roomguid AND c.status = '激活'
WHERE r.IsVirtualRoom = 0 AND l.ProductType IS NOT NULL AND l.ProductType <> '地下室/车库'
GROUP BY 
    l.ProjGUID,
    r.BldGUID,
	l.ProductType,
	l.BldCode,
	b.MaxFloor,
	b.LowFloor,
	b.HighFloor


-- -- 删除所有临时表
-- DROP TABLE IF EXISTS #LH_Room;
-- DROP TABLE IF EXISTS #bldMaxFloor;
-- DROP TABLE IF EXISTS #NewBldFloor;
-- DROP TABLE IF EXISTS #build;

--- 查询结果报表
SELECT  
    bld.ParentProjGUID,
    pp.ProjName                    AS 项目名称,
    pp.SpreadName                  AS 推广名,
    pp.TgProjCode                  AS 投管编码,
    bld.ProjGUID,
    p.ProjName                     AS 分期名称,
    dd.BldGUID,
    bld.BuildingName               AS 楼栋名称,
    bld.Code                       AS 楼栋编码,
    dd.ProductType                 AS 产品类型,
    dd.MaxFloor                    AS 总楼层数,
    dd.LowFloor                    AS 低楼层起始楼层,
    dd.HighFloor                   AS 高楼层起始楼层,
    dd.楼层总住宅套数 as 楼层总套数,
    dd.楼层总已售住宅套数 as 楼层总已售套数,
    dd.楼层未售住宅套数 as 楼层未售套数 ,
    dd.楼层非天地层未售住宅金额 as 非天地层未售金额,
    dd.楼层非天地层未售住宅面积 as 非天地层未售面积,
    dd.楼层非天地层未售住宅套数 as 非天地层未售套数,
    dd.楼层天地层未售住宅金额 as 天地层未售金额,
    dd.楼层天地层未售住宅面积 as 天地层未售面积,
    dd.楼层天地层未售住宅套数 as 天地层未售套数 
FROM data_wide_dws_s_LHFloorBldHz dd
    INNER JOIN data_wide_dws_mdm_Building bld 
        ON bld.BldType = '产品楼栋'
        AND dd.BldGUID = bld.BuildingGUID
    INNER JOIN data_wide_dws_mdm_Project p 
        ON p.ProjGUID = bld.ProjGUID
    LEFT JOIN data_wide_dws_mdm_Project pp 
        ON pp.ProjGUID = bld.ParentProjGUID
	where  dd.BldGUID=  '628A6905-37C2-46C5-8C7B-6C1FC079CB36'
ORDER BY 
    bld.ParentProjGUID, 
    bld.ProjGUID, 
    bld.BuildingName;


