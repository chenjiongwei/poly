
--DECLARE @BUGUID varchar(400)
--DECLARE @BgnDate datetime
--DECLARE @EndDate datetime
--SET @BgnDate = '2024-01-01'
--SET @EndDate = '2024-12-19'

--获取楼栋范围
SELECT DISTINCT
	   bldguid
INTO #build
FROM p_room
WHERE status IN ( '认购', '签约' )
-- AND BUGUID in (   SELECT Value  FROM   [dbo].[fn_Split2](@BUGUID , ',') );

--获取总可售
SELECT a.projguid,
SUM(a.zksmj) zksmj,
SUM(CASE WHEN a.producttype ='住宅' THEN a.zksmj ELSE 0 END ) zzzksmj,
SUM(CASE WHEN a.producttype ='商业' THEN a.zksmj ELSE 0 END ) syzksmj,
SUM(CASE WHEN a.producttype ='写字楼' THEN a.zksmj ELSE 0 END ) xzlzksmj,
SUM(CASE WHEN a.producttype ='公寓' THEN a.zksmj ELSE 0 END ) gyzksmj,
SUM(CASE WHEN a.producttype ='地下室/车库' THEN a.zksmj ELSE 0 END ) cwzksmj,
SUM(a.zksts) zksts,
SUM(CASE WHEN a.producttype ='住宅' THEN a.zksts ELSE 0 END ) zzzksts,
SUM(CASE WHEN a.producttype ='商业' THEN a.zksts ELSE 0 END ) syzksts,
SUM(CASE WHEN a.producttype ='写字楼' THEN a.zksts ELSE 0 END ) xzlzksts,
SUM(CASE WHEN a.producttype ='公寓' THEN a.zksts ELSE 0 END ) gyzksts,
SUM(CASE WHEN a.producttype ='地下室/车库' THEN a.zksts ELSE 0 END ) cwzksts
INTO #zks
FROM p_lddb a 
LEFT JOIN p_project p on a.projguid = p.projguid 
WHERE DATEDIFF(dd,a.qxdate,GETDATE()) =0
-- and p.BUGUID in (   SELECT Value  FROM   [dbo].[fn_Split2](@BUGUID , ',') )
GROUP BY a.projguid

--缓存最早车位成交日期、最早住宅成交日期

SELECT l.projguid,
	   MIN(o.qsdate) cwst
INTO #cwst
FROM s_order o
	 LEFT JOIN p_room r ON o.roomguid = r.roomguid
	 LEFT JOIN p_lddb l ON r.bldguid = l.salebldguid
						   AND DATEDIFF(dd, l.qxdate, GETDATE()) = 0
WHERE (
		  o.status = '激活'
		  OR o.closereason = '转签约'
	  )
	  AND l.producttype = '地下室/车库'
	--   AND o.BUGUID in (   SELECT Value FROM   [dbo].[fn_Split2]( @BUGUID , ',') )
	  GROUP BY l.ProjGUID;


SELECT l.projguid,
	   MIN(o.qsdate) zzst
INTO #zzst
FROM s_order o
	 LEFT JOIN p_room r ON o.roomguid = r.roomguid
	 LEFT JOIN p_lddb l ON r.bldguid = l.salebldguid
						   AND DATEDIFF(dd, l.qxdate, GETDATE()) = 0
WHERE (
		  o.status = '激活'
		  OR o.closereason = '转签约'
	  )
	  AND l.producttype = '住宅'
	--   AND o.BUGUID in (   SELECT Value FROM   [dbo].[fn_Split2](@BUGUID , ',') )
	  GROUP BY l.ProjGUID;

 
--业态齐步走BEGIN
SELECT 
l.projguid,
SUM(r.bldarea) ytzksmj,
SUM(CASE WHEN l.producttype ='住宅' THEN r.bldarea ELSE 0 END ) ytzzzksmj,
SUM(CASE WHEN l.producttype ='商业' THEN r.bldarea ELSE 0 END ) ytsyzksmj,
SUM(CASE WHEN l.producttype ='写字楼' THEN r.bldarea ELSE 0 END ) ytxzlzksmj,
SUM(CASE WHEN l.producttype ='公寓' THEN r.bldarea ELSE 0 END ) ytgyzksmj,
SUM(CASE WHEN l.producttype ='地下室/车库' THEN r.bldarea ELSE 0 END ) ytcwzksmj,
SUM(1) ytzksts,
SUM(CASE WHEN l.producttype ='住宅' THEN 1 ELSE 0 END ) ytzzzksts,
SUM(CASE WHEN l.producttype ='商业' THEN 1 ELSE 0 END ) ytsyzksts,
SUM(CASE WHEN l.producttype ='写字楼' THEN 1 ELSE 0 END ) ytxzlzksts,
SUM(CASE WHEN l.producttype ='公寓' THEN 1 ELSE 0 END ) ytgyzksts,
SUM(CASE WHEN l.producttype ='地下室/车库' THEN 1 ELSE 0 END ) ytcwzksts
-- --范围内
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 THEN r.bldarea ELSE 0 END ) rangeysmj,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype ='住宅' THEN r.bldarea ELSE 0 END ) rangeyszzmj,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype ='商业' THEN r.bldarea ELSE 0 END ) rangeyssymj,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype ='写字楼' THEN r.bldarea ELSE 0 END ) rangeysxzlmj,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype ='公寓' THEN r.bldarea ELSE 0 END ) rangeysgymj,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype ='地下室/车库' THEN r.bldarea ELSE 0 END ) rangeyscwmj,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 THEN 1 ELSE 0 END ) rangeysts,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype ='住宅' THEN 1 ELSE 0 END ) rangeyszzts,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype ='商业' THEN 1 ELSE 0 END ) rangeyssyts,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype ='写字楼' THEN 1 ELSE 0 END ) rangeysxzlts,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype ='公寓' THEN 1 ELSE 0 END ) rangeysgyts,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype ='地下室/车库' THEN 1 ELSE 0 END ) rangeyscwts
INTO #yetaiqibuzou
FROM p_room r 
INNER JOIN #build b ON r.bldguid=b.bldguid 
LEFT JOIN p_lddb l ON r.bldguid=l.salebldguid AND DATEDIFF(dd,qxdate,GETDATE()) =0
LEFT JOIN s_contract c ON r.roomguid=c.roomguid AND c.status='激活'
WHERE r.IsVirtualRoom=0 
-- and r.BUGUID in  (   SELECT Value FROM   [dbo].[fn_Split2](  @BUGUID , ',') )
GROUP BY l.projguid
--业态齐步走END

--户型齐步走BEGIN

--按照90以下/90-140/140-180/180-220/220-260/260m*以上
SELECT l.projguid,
--80平以下	180平以上 中间每10平一列
SUM(1) ytts,
SUM(CASE WHEN r.bldarea<80 THEN 1 ELSE 0 END ) 'ts80以下', 
SUM(CASE WHEN r.bldarea>=80 AND r.bldarea<90 THEN 1 ELSE 0 END ) 'ts8090', 
SUM(CASE WHEN r.bldarea>=90 AND r.bldarea<100 THEN 1 ELSE 0 END ) 'ts90100', 
SUM(CASE WHEN r.bldarea>=100 AND r.bldarea<110 THEN 1 ELSE 0 END ) 'ts100110', 
SUM(CASE WHEN r.bldarea>=110 AND r.bldarea<120 THEN 1 ELSE 0 END ) 'ts110120', 
SUM(CASE WHEN r.bldarea>=120 AND r.bldarea<130 THEN 1 ELSE 0 END ) 'ts120130', 
SUM(CASE WHEN r.bldarea>=130 AND r.bldarea<140 THEN 1 ELSE 0 END ) 'ts130140', 
SUM(CASE WHEN r.bldarea>=140 AND r.bldarea<150 THEN 1 ELSE 0 END ) 'ts140150', 
SUM(CASE WHEN r.bldarea>=150 AND r.bldarea<160 THEN 1 ELSE 0 END ) 'ts150160', 
SUM(CASE WHEN r.bldarea>=160 AND r.bldarea<170 THEN 1 ELSE 0 END ) 'ts160170', 
SUM(CASE WHEN r.bldarea>=170 AND r.bldarea<180 THEN 1 ELSE 0 END ) 'ts170180', 
SUM(CASE WHEN r.bldarea>=180  THEN 1 ELSE 0 END ) 'ts180',
SUM(CASE WHEN r.bldarea<90 THEN 1 ELSE 0 END ) 'ts90以下', 
SUM(CASE WHEN r.bldarea>=90 AND r.bldarea<140 THEN 1 ELSE 0 END ) 'ts90140', 
SUM(CASE WHEN r.bldarea>=140 AND r.bldarea<180 THEN 1 ELSE 0 END ) 'ts140180', 
SUM(CASE WHEN r.bldarea>=180 AND r.bldarea<220 THEN 1 ELSE 0 END ) 'ts180220', 
SUM(CASE WHEN r.bldarea>=220 AND r.bldarea<260 THEN 1 ELSE 0 END ) 'ts220260', 
SUM(CASE WHEN r.bldarea>=260  THEN 1 ELSE 0 END ) 'ts260'

INTO #huxingks
FROM p_room r  
LEFT JOIN p_lddb l ON r.bldguid=l.salebldguid AND DATEDIFF(dd,qxdate,GETDATE()) =0 
WHERE l.producttype='住宅' 
AND r.IsVirtualRoom=0 
-- AND r.BUGUID in (   SELECT Value FROM   [dbo].[fn_Split2]( @BUGUID , ',') )
GROUP BY l.projguid



--户型齐步走
SELECT l.projguid,
--80平以下	80-100平	100-130平	130-150平	150-180平	180平以上
SUM(1) ytts,
SUM(CASE WHEN r.bldarea<80 THEN 1 ELSE 0 END ) 'ts80以下', 
SUM(CASE WHEN r.bldarea>=80 AND r.bldarea<90 THEN 1 ELSE 0 END ) 'ts8090', 
SUM(CASE WHEN r.bldarea>=90 AND r.bldarea<100 THEN 1 ELSE 0 END ) 'ts90100', 
SUM(CASE WHEN r.bldarea>=100 AND r.bldarea<110 THEN 1 ELSE 0 END ) 'ts100110', 
SUM(CASE WHEN r.bldarea>=110 AND r.bldarea<120 THEN 1 ELSE 0 END ) 'ts110120', 
SUM(CASE WHEN r.bldarea>=120 AND r.bldarea<130 THEN 1 ELSE 0 END ) 'ts120130', 
SUM(CASE WHEN r.bldarea>=130 AND r.bldarea<140 THEN 1 ELSE 0 END ) 'ts130140', 
SUM(CASE WHEN r.bldarea>=140 AND r.bldarea<150 THEN 1 ELSE 0 END ) 'ts140150', 
SUM(CASE WHEN r.bldarea>=150 AND r.bldarea<160 THEN 1 ELSE 0 END ) 'ts150160', 
SUM(CASE WHEN r.bldarea>=160 AND r.bldarea<170 THEN 1 ELSE 0 END ) 'ts160170', 
SUM(CASE WHEN r.bldarea>=170 AND r.bldarea<180 THEN 1 ELSE 0 END ) 'ts170180', 
SUM(CASE WHEN r.bldarea>=180  THEN 1 ELSE 0 END ) 'ts180',  
SUM(CASE WHEN r.bldarea<90 THEN 1 ELSE 0 END ) 'ts90以下', 
SUM(CASE WHEN r.bldarea>=90 AND r.bldarea<140 THEN 1 ELSE 0 END ) 'ts90140', 
SUM(CASE WHEN r.bldarea>=140 AND r.bldarea<180 THEN 1 ELSE 0 END ) 'ts140180', 
SUM(CASE WHEN r.bldarea>=180 AND r.bldarea<220 THEN 1 ELSE 0 END ) 'ts180220', 
SUM(CASE WHEN r.bldarea>=220 AND r.bldarea<260 THEN 1 ELSE 0 END ) 'ts220260', 
SUM(CASE WHEN r.bldarea>=260  THEN 1 ELSE 0 END ) 'ts260',

SUM(CASE WHEN c.qsdate is not null THEN 1 ELSE 0 END ) 'ysts', 
SUM(CASE WHEN c.qsdate is not null and r.bldarea<90 THEN 1 ELSE 0 END ) 'ysts90以下', 
SUM(CASE WHEN c.qsdate is not null and r.bldarea>=90 AND r.bldarea<140 THEN 1 ELSE 0 END ) 'ysts90140', 
SUM(CASE WHEN c.qsdate is not null and r.bldarea>=140 AND r.bldarea<180 THEN 1 ELSE 0 END ) 'ysts140180', 
SUM(CASE WHEN c.qsdate is not null and r.bldarea>=180 AND r.bldarea<220 THEN 1 ELSE 0 END ) 'ysts180220', 
SUM(CASE WHEN c.qsdate is not null and r.bldarea>=220 AND r.bldarea<260 THEN 1 ELSE 0 END ) 'ysts220260', 
SUM(CASE WHEN c.qsdate is not null and r.bldarea>=260  THEN 1 ELSE 0 END ) 'ysts260'
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 THEN 1 ELSE 0 END ) 'rangeysts', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 and r.bldarea<90 THEN 1 ELSE 0 END ) 'rangeysts90以下', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 and r.bldarea>=90 AND r.bldarea<140 THEN 1 ELSE 0 END ) 'rangeysts90140', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 and r.bldarea>=140 AND r.bldarea<180 THEN 1 ELSE 0 END ) 'rangeysts140180', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 and r.bldarea>=180 AND r.bldarea<220 THEN 1 ELSE 0 END ) 'rangeysts180220', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 and r.bldarea>=220 AND r.bldarea<260 THEN 1 ELSE 0 END ) 'rangeysts220260', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 and r.bldarea>=260  THEN 1 ELSE 0 END ) 'rangeysts260',
-- --范围内已售
-- --SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 THEN 1 ELSE 0 END ) 'rangeysts', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND r.bldarea<80 THEN 1 ELSE 0 END ) 'rangeysts80以下', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND r.bldarea>=80 AND r.bldarea<90 THEN 1 ELSE 0 END ) 'rangeysts8090', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND r.bldarea>=90 AND r.bldarea<100 THEN 1 ELSE 0 END ) 'rangeysts90100', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND r.bldarea>=100 AND r.bldarea<110 THEN 1 ELSE 0 END ) 'rangeysts100110', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND r.bldarea>=110 AND r.bldarea<120 THEN 1 ELSE 0 END ) 'rangeysts110120', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND r.bldarea>=120 AND r.bldarea<130 THEN 1 ELSE 0 END ) 'rangeysts120130',
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND r.bldarea>=130 AND r.bldarea<140 THEN 1 ELSE 0 END ) 'rangeysts130140', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND r.bldarea>=140 AND r.bldarea<150 THEN 1 ELSE 0 END ) 'rangeysts140150', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND r.bldarea>=150 AND r.bldarea<160 THEN 1 ELSE 0 END ) 'rangeysts150160',
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND r.bldarea>=160 AND r.bldarea<170 THEN 1 ELSE 0 END ) 'rangeysts160170',  
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND r.bldarea>=170 AND r.bldarea<180 THEN 1 ELSE 0 END ) 'rangeysts170180', 
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND r.bldarea>=180  THEN 1 ELSE 0 END ) 'rangeysts180'
INTO #huxingqibuzou
FROM p_room r 
INNER JOIN #build b ON r.bldguid=b.bldguid 
LEFT JOIN p_lddb l ON r.bldguid=l.salebldguid AND DATEDIFF(dd,qxdate,GETDATE()) =0
LEFT JOIN s_contract c ON r.roomguid=c.roomguid AND c.status='激活'
WHERE l.producttype='住宅' 
AND r.IsVirtualRoom=0 
-- AND r.BUGUID in (   SELECT Value FROM   [dbo].[fn_Split2](@BUGUID , ',') )
GROUP BY l.projguid

SELECT a.projguid,
MAX(qhl) maxQhl,
MIN(qhl) minQhl
INTO #huxingqibuzouQhl
FROM (
	SELECT projguid,
	case when h.ts90以下 = 0 then NULL else h.ysts90以下*1.00/h.ts90以下 end 'qhl'
	FROM #huxingqibuzou h
	UNION ALL 
	SELECT projguid,
	case when h.ts90140 = 0 then NULL else h.ysts90140*1.00/h.ts90140 end 'qhl'
	FROM #huxingqibuzou h
	UNION ALL 
	SELECT projguid,
	case when h.ts140180 = 0 then NULL else h.ysts140180*1.00/h.ts140180 end 'qhl'
	FROM #huxingqibuzou h
	UNION ALL 
	SELECT projguid,
	case when h.ts180220 = 0 then NULL else h.ysts180220*1.00/h.ts180220 end 'qhl'
	FROM #huxingqibuzou h
	UNION ALL 
	SELECT projguid,
	case when h.ts220260 = 0 then NULL else h.ysts220260*1.00/h.ts220260 end 'qhl'
	FROM #huxingqibuzou h
	UNION ALL 
	SELECT projguid,
	case when h.ts260 = 0 then NULL else h.ysts260*1.00/h.ts260 end 'qhl'
	FROM #huxingqibuzou h
)a 
GROUP BY a.projguid



--户型齐步走END

--楼层齐步走BEGIN

	--整理楼栋楼层
	SELECT BldGUID,
	MAX(newFloor) AS MaxFloor 
	INTO #NewBldFloor
	FROM (
		SELECT 
		BldGUID,
		ROW_NUMBER() over(PARTITION BY BldGUID ORDER BY MAX(FloorNo)) newFloor
		FROM 
		ep_room
		where isnull(floor,'') <> '' 
		-- and BUGUID in (   SELECT Value FROM   [dbo].[fn_Split2]( @BUGUID , ',') )
		GROUP by bldguid,
			replace( 
					replace(FLOOR,
							'南',''),
					'北','')
	)a
	GROUP BY BldGUID


	--缓存住宅楼栋天地楼层
	SELECT a.SaleBldGUID,
		rf.MaxFloor,
		CASE WHEN ROUND(rf.MaxFloor*0.1,0) = 0 THEN 1 ELSE ROUND(rf.MaxFloor*0.1,0) END LowFloor,
		CASE WHEN ROUND(rf.MaxFloor*0.1,0) = 0 THEN ROUND(rf.MaxFloor,0) -1 ELSE ROUND(rf.MaxFloor -ROUND(rf.MaxFloor*0.1,0),0) END HighFloor																					
	INTO #bldMaxFloor
	FROM p_lddb a
	LEFT JOIN #NewBldFloor rf ON rf.bldguid = a.SaleBldGUID
	INNER JOIN #build ytld ON ytld.bldguid = a.SaleBldGUID
	WHERE a.ProductType IN ('住宅') AND DATEDIFF(day,a.QXDate,GETDATE()) = 0

	--缓存房间天地楼层情况
	SELECT 
	r.RoomGUID,
	LHFloor.SaleBldGUID BldGUID,
	LHFloor.MaxFloor MaxFloor,
	LHFloor.LowFloor LowFloor,
	LHFloor.HighFloor HighFloor,
	CASE WHEN r.FloorNo >0 AND r.FloorNo <= LHFloor.LowFloor THEN 1
		WHEN r.FloorNo >= HighFloor THEN 2
		ELSE 3
	END AS LowHighType
	INTO #LH_Room
	FROM 
	ep_room r 
	INNER JOIN #bldMaxFloor LHFloor ON LHFloor.SaleBldGUID = r.BldGUID
	
	--整合项目统计
	SELECT 
	l.ProjGUID,
	--已推住宅套数
	SUM(1) AS ytTs,
	SUM(CASE WHEN b.LowHighType = 3 THEN 1 ELSE 0 END) AS YtNormalTs,
	SUM(CASE WHEN b.LowHighType <> 3 THEN 1 ELSE 0 END) AS YtLowHighTs,
	--已售住宅套数-全部已售
	SUM(CASE WHEN c.qsdate is not null THEN 1 ELSE 0 END) AS ysTs,
	SUM(CASE WHEN c.qsdate is not null AND b.LowHighType = 3 THEN 1 ELSE 0 END) AS ysNormalTs,
	SUM(CASE WHEN c.qsdate is not null AND b.LowHighType <> 3 THEN 1 ELSE 0 END) AS ysLowHighTs,
	--已售住宅套数-范围内
	-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 THEN 1 ELSE 0 END) AS RangeYtTs,
	-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND b.LowHighType = 3 THEN 1 ELSE 0 END) AS RangeYtNormalTs,
	-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND b.LowHighType <> 3 THEN 1 ELSE 0 END) AS RangeYtLowHighTs,
	SUM(CASE WHEN b.LowHighType = 3 and r.status not in ('认购','签约') THEN 1 ELSE 0 END) AS wsNormalTs,
	SUM(CASE WHEN b.LowHighType = 3 and r.status not in ('认购','签约') THEN r.bldarea ELSE 0 END) AS wsNormalArea,
	SUM(CASE WHEN b.LowHighType = 3 and r.status not in ('认购','签约') THEN r.HSZJ ELSE 0 END) AS wsNormalje,
	SUM(CASE WHEN b.LowHighType <> 3 and r.status not in ('认购','签约') THEN 1 ELSE 0 END) AS wsLowHighTs,
	SUM(CASE WHEN b.LowHighType <> 3 and r.status not in ('认购','签约') THEN r.bldarea ELSE 0 END) AS wsLowHighArea,
	SUM(CASE WHEN b.LowHighType <> 3 and r.status not in ('认购','签约') THEN r.HSZJ ELSE 0 END) AS wsLowHighje
	INTO #loucengqibuzou
	FROM 
	p_room r
	INNER JOIN #LH_Room b on r.RoomGUID = b.RoomGUID
	LEFT JOIN p_lddb l ON r.BldGUID=l.SaleBldGUID AND DATEDIFF(dd,qxdate,GETDATE()) =0
	LEFT JOIN s_contract c ON r.roomguid=c.roomguid AND c.status='激活'
	WHERE r.IsVirtualRoom=0 
	GROUP BY l.ProjGUID

--楼层齐步走END



--获取汇总数
SELECT p.BUGUID,
	   f.projguid,
	   f.平台公司,
	   f.城市,
	   f.城市分类,
	   f.标签城市分类,
	   f.城市六分化,
	   f.项目五分类,
	   f.板块分类,
	   f.板块能级,
	   f.并表方式,
	   f.项目股权比例,
	   f.项目出资比例,
	   f.财务收益比例,
	   f.操盘方式,
	   f.获取时间,
	   f.项目名,
	   f.推广名,
	   f.项目代码,
	   f.投管代码,
	--    f.操盘方式 as 操盘方式2,
	--    f.并表方式 as 并表方式2,
	   
	   --总可售
	   CAST(z.zksmj/10000 AS DECIMAL(18,2)) 总可售面积合计,
	   CAST(z.zzzksmj/10000 AS DECIMAL(18,2)) 总可售面积其中住宅,
	   CAST(z.syzksmj/10000 AS DECIMAL(18,2)) 总可售面积其中商业,
	   CAST(z.xzlzksmj/10000 AS DECIMAL(18,2)) 总可售面积其中写字楼,
	   CAST(z.gyzksmj/10000 AS DECIMAL(18,2)) 总可售面积其中公寓,
	   CAST(z.cwzksmj/10000 AS DECIMAL(18,2)) 总可售面积其中车位,
	   z.zksts 总可售套数合计,
	   z.zzzksts 总可售套数其中住宅,
	   z.syzksts 总可售套数其中商业,
	   z.xzlzksts 总可售套数其中写字楼,
	   z.gyzksts 总可售套数其中公寓,
	   z.cwzksts 总可售套数其中车位,
	   cwst.cwst 车位首套成交日期,
	   zzst.zzst 住宅首套成交日期,

	   --户型齐步走

	   hs.ytts 户型总可售住宅住宅套数,
	   hs.ts80以下 '户型总可售住宅住宅80以下',
	   hs.ts8090 '户型总可售住宅住宅8090平',
	   hs.ts90100 '户型总可售住宅住宅90100平',
	   hs.ts100110 '户型总可售住宅住宅100110平',
	   hs.ts110120 '户型总可售住宅住宅110120平',
	   hs.ts120130 '户型总可售住宅住宅120130平',
	   hs.ts130140 '户型总可售住宅住宅130140平',
	   hs.ts140150 '户型总可售住宅住宅140150平',
	   hs.ts150160 '户型总可售住宅住宅150160平',
	   hs.ts160170 '户型总可售住宅住宅160170平',
	   hs.ts170180 '户型总可售住宅住宅170180平',
	   hs.ts180 '户型总可售住宅住宅180平以上',
	   
	   hs.ts90以下 '户型总可售住宅住宅90以下',
	   hs.ts90140 '户型总可售住宅住宅90140平',
	   hs.ts140180 '户型总可售住宅住宅140180平',
	   hs.ts180220 '户型总可售住宅住宅180220平',
	   hs.ts220260 '户型总可售住宅住宅220260平',
	   hs.ts260 '户型总可售住宅住宅260平以上',
	   
	   h.ytts 户型已推住宅套数,
	   h.ts80以下 '户型已推住宅80以下',
	   h.ts8090 '户型已推住宅8090平',
	   h.ts90100 '户型已推住宅90100平',
	   h.ts100110 '户型已推住宅100110平',
	   h.ts110120 '户型已推住宅110120平',
	   h.ts120130 '户型已推住宅120130平',
	   h.ts130140 '户型已推住宅130140平',
	   h.ts140150 '户型已推住宅140150平',
	   h.ts150160 '户型已推住宅150160平',
	   h.ts160170 '户型已推住宅160170平',
	   h.ts170180 '户型已推住宅170180平',
	   h.ts180 '户型已推住宅180平以上',
	   
	   
	   h.ts90以下 '户型已推住宅住宅90以下',
	   h.ts90140 '户型已推住宅住宅90140平',
	   h.ts140180 '户型已推住宅住宅140180平',
	   h.ts180220 '户型已推住宅住宅180220平',
	   h.ts220260 '户型已推住宅住宅220260平',
	   h.ts260 '户型已推住宅住宅260平以上',
	   
	   h.ysTs '户型已售住宅',
	   h.ysts90以下 '户型已售住宅住宅90以下',
	   h.ysts90140 '户型已售住宅住宅90140平',
	   h.ysts140180 '户型已售住宅住宅140180平',
	   h.ysts180220 '户型已售住宅住宅180220平',
	   h.ysts220260 '户型已售住宅住宅220260平',
	   h.ysts260 '户型已售住宅住宅260平以上',
	   
	   
	   case when h.ts90以下 = 0 then 0 else h.ysts90以下*1.00/h.ts90以下 end '户型去化率住宅住宅90以下',
	   case when h.ts90140 = 0 then 0 else h.ysts90140*1.00/h.ts90140 end '户型去化率住宅住宅90140平',
	   case when h.ts140180 = 0 then 0 else h.ysts140180*1.00/h.ts140180 end '户型去化率住宅住宅140180平',
	   case when h.ts180220 = 0 then 0 else h.ysts180220*1.00/h.ts180220 end '户型去化率住宅住宅180220平',
	   case when h.ts220260 = 0 then 0 else h.ysts220260*1.00/h.ts220260 end '户型去化率住宅住宅220260平',
	   case when h.ts260 = 0 then 0 else h.ysts260*1.00/h.ts260 end '户型去化率住宅住宅260平以上',
	   
	   hq.maxQhl '最大去化率',
	   hq.minQhl '最小去化率',
	   hq.maxQhl - hq.minQhl '户型去化率极差',
			
	   --h.rangeysts '户型范围内已售住宅',
	--    h.rangeysts90以下 '户型范围内已售住宅住宅90以下',
	--    h.rangeysts90140 '户型范围内已售住宅住宅90140平',
	--    h.rangeysts140180 '户型范围内已售住宅住宅140180平',
	--    h.rangeysts180220 '户型范围内已售住宅住宅180220平',
	--    h.rangeysts220260 '户型范围内已售住宅住宅220260平',
	--    h.rangeysts260 '户型范围内已售住宅住宅260平以上',

	   --h.rangeysts80以下 '户型范围内已售住宅80以下',
	   --h.rangeysts8090 '户型范围内已售住宅8090平',
	   --h.rangeysts90100 '户型范围内已售住宅90100平',
	   --h.rangeysts100110 '户型范围内已售住宅100110平',
	   --h.rangeysts110120 '户型范围内已售住宅110120平',
	   --h.rangeysts120130 '户型范围内已售住宅120130平',
	   --h.rangeysts130140 '户型范围内已售住宅130140平',
	   --h.rangeysts140150 '户型范围内已售住宅140150平',
	   --h.rangeysts150160 '户型范围内已售住宅150160平',
	   --h.rangeysts160170 '户型范围内已售住宅160170平',
	   --h.rangeysts170180 '户型范围内已售住宅170180平',
	   --h.rangeysts180 '户型范围内已售住宅180平以上',
	   CASE WHEN isnull(fp.投管代码,'') <> '' then '是' else '否' end 是否纳入考核,
	   getdate() qxdate   
	-- into hx_qbz
FROM vmdm_projectflag f
	 LEFT JOIN #zks z ON f.projguid = z.projguid
	 LEFT JOIN #yetaiqibuzou y ON f.projguid = y.projguid
	 LEFT JOIN #huxingqibuzou h ON f.projguid = h.projguid
	 LEFT JOIN #huxingks hs ON f.projguid = hs.projguid
	 LEFT JOIN #huxingqibuzouQhl hq ON f.projguid = hq.projguid
	 LEFT JOIN #loucengqibuzou lc on f.projguid = lc.projguid
	 LEFT JOIN #cwst cwst on  f.projguid = cwst.projguid
	 LEFT JOIN #zzst zzst on  f.projguid = zzst.projguid
	 LEFT JOIN p_project p on f.projguid = p.projguid
	 LEFT JOIN s_lchxqbzproj fp on fp.投管代码 = f.投管代码 and isnull(fp.投管代码,'') <> ''
WHERE 1=1
-- WHERE p.BUGUID in (   SELECT Value  FROM   [dbo].[fn_Split2](@BUGUID , ',') )
ORDER BY f.平台公司,
		 f.项目名;


DROP TABLE #bldMaxFloor,#build,#cwst,#huxingks,#huxingqibuzou,#huxingqibuzouQhl,#LH_Room,#loucengqibuzou,#NewBldFloor,#yetaiqibuzou,#zks,#zzst