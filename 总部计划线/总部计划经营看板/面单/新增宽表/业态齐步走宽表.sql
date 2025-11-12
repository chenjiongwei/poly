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
-- AND BUGUID in ( @BUGUID);

--获取总可售
SELECT 
	a.projguid,
	SUM(a.zksmj) zksmj,
	SUM(CASE WHEN a.producttype in ('住宅','高级住宅') THEN a.zksmj ELSE 0 END ) zzzksmj,
	SUM(CASE WHEN a.producttype ='商业' THEN a.zksmj ELSE 0 END ) syzksmj,
	SUM(CASE WHEN a.producttype ='写字楼' THEN a.zksmj ELSE 0 END ) xzlzksmj,
	SUM(CASE WHEN a.producttype ='公寓' THEN a.zksmj ELSE 0 END ) gyzksmj,
	SUM(CASE WHEN a.producttype ='地下室/车库' THEN a.zksmj ELSE 0 END ) cwzksmj,
	SUM(a.zksts) zksts,
	SUM(CASE WHEN a.producttype in ('住宅','高级住宅') THEN a.zksts ELSE 0 END ) zzzksts,
	SUM(CASE WHEN a.producttype ='商业' THEN a.zksts ELSE 0 END ) syzksts,
	SUM(CASE WHEN a.producttype ='写字楼' THEN a.zksts ELSE 0 END ) xzlzksts,
	SUM(CASE WHEN a.producttype ='公寓' THEN a.zksts ELSE 0 END ) gyzksts,
	SUM(CASE WHEN a.producttype ='地下室/车库' THEN a.zksts ELSE 0 END ) cwzksts,
	SUM(CASE WHEN a.producttype ='地下室/车库' THEN a.zhz ELSE 0 END ) cwzksje,
	SUM(CASE WHEN a.producttype ='地下室/车库' THEN a.ysje ELSE 0 END ) cwysje,
	SUM(CASE WHEN a.producttype ='地下室/车库' THEN a.ytwsje ELSE 0 END ) cwytwsje
INTO #zks
FROM p_lddb a 
LEFT JOIN p_project p on a.projguid = p.projguid 
WHERE DATEDIFF(dd,a.qxdate,GETDATE()) =0
-- and p.BUGUID in ( @BUGUID)
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
    --   AND o.BUGUID in ( @BUGUID)
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
    --   AND o.BUGUID in ( @BUGUID)
      GROUP BY l.ProjGUID;

 
--业态齐步走BEGIN
SELECT 
    l.projguid,
    SUM(r.bldarea) ytzksmj,
    SUM(CASE WHEN l.producttype in ('住宅','高级住宅') THEN r.bldarea ELSE 0 END ) ytzzzksmj,
    SUM(CASE WHEN l.producttype ='商业' THEN r.bldarea ELSE 0 END ) ytsyzksmj,
    SUM(CASE WHEN l.producttype ='写字楼' THEN r.bldarea ELSE 0 END ) ytxzlzksmj,
    SUM(CASE WHEN l.producttype ='公寓' THEN r.bldarea ELSE 0 END ) ytgyzksmj,
    SUM(CASE WHEN l.producttype ='地下室/车库' THEN r.bldarea ELSE 0 END ) ytcwzksmj,
    SUM(1) ytzksts,
    SUM(CASE WHEN l.producttype in ('住宅','高级住宅') THEN 1 ELSE 0 END ) ytzzzksts,
    SUM(CASE WHEN l.producttype ='商业' THEN 1 ELSE 0 END ) ytsyzksts,
    SUM(CASE WHEN l.producttype ='写字楼' THEN 1 ELSE 0 END ) ytxzlzksts,
    SUM(CASE WHEN l.producttype ='公寓' THEN 1 ELSE 0 END ) ytgyzksts,
    SUM(CASE WHEN l.producttype ='地下室/车库' THEN 1 ELSE 0 END ) ytcwzksts,


    SUM(CASE WHEN r.status in ('认购','签约') THEN r.bldarea ELSE 0 END ) ysmj,
    SUM(CASE WHEN r.status in ('认购','签约') AND l.producttype in ('住宅','高级住宅') THEN r.bldarea ELSE 0 END ) yszzmj,
    SUM(CASE WHEN r.status in ('认购','签约') AND l.producttype ='商业' THEN r.bldarea ELSE 0 END ) yssymj,
    SUM(CASE WHEN r.status in ('认购','签约') AND l.producttype ='写字楼' THEN r.bldarea ELSE 0 END ) ysxzlmj,
    SUM(CASE WHEN r.status in ('认购','签约') AND l.producttype ='公寓' THEN r.bldarea ELSE 0 END ) ysgymj,
    SUM(CASE WHEN r.status in ('认购','签约') AND l.producttype ='地下室/车库' THEN r.bldarea ELSE 0 END ) yscwmj,
    SUM(CASE WHEN r.status in ('认购','签约') THEN 1 ELSE 0 END ) ysts,
    SUM(CASE WHEN r.status in ('认购','签约') AND l.producttype in ('住宅','高级住宅') THEN 1 ELSE 0 END ) yszzts,
    SUM(CASE WHEN r.status in ('认购','签约') AND l.producttype ='商业' THEN 1 ELSE 0 END ) yssyts,
    SUM(CASE WHEN r.status in ('认购','签约') AND l.producttype ='写字楼' THEN 1 ELSE 0 END ) ysxzlts,
    SUM(CASE WHEN r.status in ('认购','签约') AND l.producttype ='公寓' THEN 1 ELSE 0 END ) ysgyts,
    SUM(CASE WHEN r.status in ('认购','签约') AND l.producttype ='地下室/车库' THEN 1 ELSE 0 END ) yscwts

-- --范围内
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 THEN r.bldarea ELSE 0 END ) rangeysmj,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype in ('住宅','高级住宅') THEN r.bldarea ELSE 0 END ) rangeyszzmj,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype ='商业' THEN r.bldarea ELSE 0 END ) rangeyssymj,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype ='写字楼' THEN r.bldarea ELSE 0 END ) rangeysxzlmj,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype ='公寓' THEN r.bldarea ELSE 0 END ) rangeysgymj,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype ='地下室/车库' THEN r.bldarea ELSE 0 END ) rangeyscwmj,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 THEN 1 ELSE 0 END ) rangeysts,
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND l.producttype in ('住宅','高级住宅') THEN 1 ELSE 0 END ) rangeyszzts,
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
-- and r.BUGUID in ( @BUGUID)
GROUP BY l.projguid
--业态齐步走END



--获取汇总数
SELECT f.projguid,
       f.平台公司,
       f.城市,
       f.获取时间,
       f.存量增量,
       f.项目名,
       f.推广名,
       f.项目代码,
       f.投管代码,
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
       CAST(z.cwzksje/10000 AS DECIMAL(18,2)) 车位总可售金额,
       CAST(z.cwysje/10000 AS DECIMAL(18,2)) 车位已售金额,
       CAST(z.cwytwsje/10000 AS DECIMAL(18,2)) 车位已推未售金额,
       --业态齐步走
       CAST(y.ytzksmj/10000 AS DECIMAL(18,2)) 业态已推面积合计,
       CAST(y.ytzzzksmj/10000 AS DECIMAL(18,2)) 业态已推面积其中住宅,
       CAST(y.ytsyzksmj/10000 AS DECIMAL(18,2)) 业态已推面积其中商业,
       CAST(y.ytxzlzksmj/10000 AS DECIMAL(18,2)) 业态已推面积其中写字楼,
       CAST(y.ytgyzksmj/10000 AS DECIMAL(18,2)) 业态已推面积其中公寓,
       CAST(y.ytcwzksmj/10000 AS DECIMAL(18,2)) 业态已推面积其中车位,
       y.ytzksts 业态已推套数合计,
       y.ytzzzksts 业态已推套数其中住宅,
       y.ytsyzksts 业态已推套数其中商业,
       y.ytxzlzksts 业态已推套数其中写字楼,
       y.ytgyzksts 业态已推套数其中公寓,
       y.ytcwzksts 业态已推套数其中车位,

    --    CAST(y.rangeysmj/10000 AS DECIMAL(18,2)) 业态已售面积范围内合计,
    --    CAST(y.rangeyszzmj/10000 AS DECIMAL(18,2)) 业态已售面积范围内其中住宅,
    --    CAST(y.rangeyssymj/10000 AS DECIMAL(18,2)) 业态已售面积范围内其中商业,
    --    CAST(y.rangeysxzlmj/10000 AS DECIMAL(18,2)) 业态已售面积范围内其中写字楼,
    --    CAST(y.rangeysgymj/10000 AS DECIMAL(18,2)) 业态已售面积范围内其中公寓,
    --    CAST(y.rangeyscwmj/10000 AS DECIMAL(18,2)) 业态已售面积范围内其中车位,
    --    y.rangeysts 业态已售套数范围内合计,
    --    y.rangeyszzts 业态已售套数范围内其中住宅,
    --    y.rangeyssyts 业态已售套数范围内其中商业,
    --    y.rangeysxzlts 业态已售套数范围内其中写字楼,
    --    y.rangeysgyts 业态已售套数范围内其中公寓,
    --    y.rangeyscwts 业态已售套数范围内其中车位,
       
       
       CAST(y.ysmj/10000 AS DECIMAL(18,2)) 业态已售面积合计,
       CAST(y.yszzmj/10000 AS DECIMAL(18,2)) 业态已售面积其中住宅,
       CAST(y.yssymj/10000 AS DECIMAL(18,2)) 业态已售面积其中商业,
       CAST(y.ysxzlmj/10000 AS DECIMAL(18,2)) 业态已售面积其中写字楼,
       CAST(y.ysgymj/10000 AS DECIMAL(18,2)) 业态已售面积其中公寓,
       CAST(y.yscwmj/10000 AS DECIMAL(18,2)) 业态已售面积其中车位,
       y.ysts 业态已售套数合计,
       y.yszzts 业态已售套数其中住宅,
       y.yssyts 业态已售套数其中商业,
       y.ysxzlts 业态已售套数其中写字楼,
       y.ysgyts 业态已售套数其中公寓,
       y.yscwts 业态已售套数其中车位,
       
       case when CAST(y.ytzzzksmj/10000 AS DECIMAL(18,2)) = 0 then 0 
       else 
       CAST(y.yszzmj/10000 AS DECIMAL(18,2)) / CAST(y.ytzzzksmj/10000 AS DECIMAL(18,2))
       end 住宅去化率_按面积,
       
       case when CAST(y.ytcwzksts AS DECIMAL(18,2)) = 0 then 0 
       else 
       CAST(y.yscwts AS DECIMAL(18,2)) / CAST(y.ytcwzksts AS DECIMAL(18,2))
       end 车位去化率_按套数
       
FROM vmdm_projectflag f
     LEFT JOIN #zks z ON f.projguid = z.projguid
     LEFT JOIN #yetaiqibuzou y ON f.projguid = y.projguid
     LEFT JOIN #cwst cwst on  f.projguid = cwst.projguid
     LEFT JOIN #zzst zzst on  f.projguid = zzst.projguid
     LEFT JOIN p_project p on f.projguid = p.projguid
    -- INNER JOIN s_ytqbzproj fp on fp.投管代码 = f.投管代码
WHERE  1=1 -- p.BUGUID in ( @BUGUID)
ORDER BY f.平台公司,
         f.项目名;



DROP TABLE #build,#zks,#yetaiqibuzou,#cwst,#zzst
