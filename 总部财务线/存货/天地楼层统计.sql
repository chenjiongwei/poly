-- declare @BUGUID varchar(400) ='512381FE-A9CB-E511-80B8-E41F13C51836' -- 广东公司

--获取楼栋范围
SELECT DISTINCT
	   bldguid
INTO #build
FROM p_room
WHERE status IN ( '认购', '签约' )
-- AND BUGUID in (   SELECT Value
--            FROM   [dbo].[fn_Split2](
--                                                                     @BUGUID , ',') );

-- 整理楼栋楼层 最大楼层数
SELECT 
    BldGUID,
    MAX(newFloor) AS MaxFloor
INTO #NewBldFloor
FROM (
    SELECT 
        BldGUID,
        ROW_NUMBER() OVER (PARTITION BY BldGUID ORDER BY MAX(FloorNo)) AS newFloor
    FROM 
        ep_room
    WHERE 
        ISNULL(floor, '') <> '' 
        -- AND BUGUID IN (
        --     SELECT Value
        --     FROM [dbo].[fn_Split2](@BUGUID, ',')
        -- )
    GROUP BY 
        bldguid,
        REPLACE(REPLACE(FLOOR, '南', ''), '北', '')
) a
GROUP BY  BldGUID                    

    --缓存住宅楼栋天地楼层
	SELECT a.SaleBldGUID,
		rf.MaxFloor,
		CASE WHEN ROUND(rf.MaxFloor*0.1,0) = 0 THEN 1 ELSE ROUND(rf.MaxFloor*0.1,0) END LowFloor,
		CASE WHEN ROUND(rf.MaxFloor*0.1,0) = 0 THEN ROUND(rf.MaxFloor,0) -1 ELSE ROUND(rf.MaxFloor -ROUND(rf.MaxFloor*0.1,0),0)+1 END HighFloor																					
	INTO #bldMaxFloor
	FROM p_lddb a
	LEFT JOIN #NewBldFloor rf ON rf.bldguid = a.SaleBldGUID
	INNER JOIN #build ytld ON ytld.bldguid = a.SaleBldGUID
	WHERE a.ProductType IN ('住宅') AND DATEDIFF(day,a.QXDate,GETDATE()) = 0      

    -- 缓存房间天地楼层情况
	SELECT 
		r.RoomGUID,
		LHFloor.SaleBldGUID AS BldGUID,
		LHFloor.MaxFloor AS MaxFloor,
		LHFloor.LowFloor AS LowFloor,
		LHFloor.HighFloor AS HighFloor,
		CASE 
			WHEN nr.newFloor > 0 AND nr.newFloor <= LHFloor.LowFloor THEN 1
			WHEN nr.newFloor >= LHFloor.HighFloor THEN 2
			ELSE 3
		END AS LowHighType
	INTO #LH_Room
	FROM 
		ep_room r
		LEFT JOIN (
			SELECT 
				BldGUID,
				REPLACE(REPLACE(FLOOR, '南', ''), '北', '') AS FLOOR,
				ROW_NUMBER() OVER (PARTITION BY BldGUID ORDER BY MAX(FloorNo)) AS newFloor
			FROM 
				ep_room
			WHERE 
				ISNULL(FLOOR, '') <> ''
				-- AND BUGUID IN (
				-- 	SELECT Value
				-- 	FROM [dbo].[fn_Split2](@BUGUID, ',')
				-- )
			GROUP BY 
				BldGUID,
				REPLACE(REPLACE(FLOOR, '南', ''), '北', '')
		) nr 
			ON nr.BldGUID = r.BldGUID 
			AND REPLACE(REPLACE(r.FLOOR, '南', ''), '北', '') = nr.FLOOR
		INNER JOIN #bldMaxFloor LHFloor  ON LHFloor.SaleBldGUID = r.BldGUID      

--整合项目统计
	SELECT 
        l.ProjGUID,
        r.BldGUID,
        --已推住宅套数
        SUM(1) AS 楼层总住宅套数,
        -- SUM(CASE WHEN b.LowHighType = 3 THEN 1 ELSE 0 END) AS YtNormalTs,
        -- SUM(CASE WHEN b.LowHighType <> 3 THEN 1 ELSE 0 END) AS YtLowHighTs,
        -- --已售住宅套数-全部已售
        SUM(CASE WHEN c.qsdate is not null THEN 1 ELSE 0 END) AS 楼层总已售住宅套数,
        -- SUM(CASE WHEN c.qsdate is not null AND b.LowHighType = 3 THEN 1 ELSE 0 END) AS ysNormalTs,
        -- SUM(CASE WHEN c.qsdate is not null AND b.LowHighType <> 3 THEN 1 ELSE 0 END) AS ysLowHighTs,
        --已售住宅套数-范围内

        SUM(CASE WHEN b.LowHighType = 3 and r.status not in ('认购','签约') THEN 1 ELSE 0 END) AS 楼层非天地层未售住宅套数, 
        SUM(CASE WHEN b.LowHighType = 3 and r.status not in ('认购','签约') THEN r.bldarea ELSE 0 END) AS 楼层非天地层未售住宅面积,
        SUM(CASE WHEN b.LowHighType = 3 and r.status not in ('认购','签约') THEN r.HSZJ ELSE 0 END) AS 楼层非天地层未售住宅金额,
        SUM(CASE WHEN b.LowHighType <> 3 and r.status not in ('认购','签约') THEN 1 ELSE 0 END) AS 楼层天地层未售住宅套数,
        SUM(CASE WHEN b.LowHighType <> 3 and r.status not in ('认购','签约') THEN r.bldarea ELSE 0 END) AS 楼层天地层未售住宅面积,
        SUM(CASE WHEN b.LowHighType <> 3 and r.status not in ('认购','签约') THEN r.HSZJ ELSE 0 END) AS 楼层天地层未售住宅金额
	-- INTO #loucengqibuzou
	FROM p_room r
	INNER JOIN #LH_Room b on r.RoomGUID = b.RoomGUID
	LEFT JOIN p_lddb l ON r.BldGUID=l.SaleBldGUID AND DATEDIFF(dd,qxdate,GETDATE()) =0
	LEFT JOIN s_contract c ON r.roomguid=c.roomguid AND c.status='激活'
	WHERE r.IsVirtualRoom=0 
	GROUP BY l.ProjGUID,r.BldGUID                                  
