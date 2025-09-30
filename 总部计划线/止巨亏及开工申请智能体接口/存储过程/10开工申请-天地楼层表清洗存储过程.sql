-- ============================================
-- 存储过程名称：[usp_s_集团开工申请天地楼层智能体数据提取]
-- 创建人: chenjw 2025-09-28
-- 作用：清洗并提取集团开工申请天地楼层数据，供智能体使用
-- ============================================

CREATE OR ALTER PROC [dbo].[usp_s_集团开工申请天地楼层智能体数据提取]
AS
BEGIN
    /**************************************************************
    * 步骤1：定义时间变量
    * @Thisyear_start：本年度第一天（如2025-01-01 00:00:00.000）
    * @Thisyear_end  ：本年度最后一天（如2025-12-31 23:59:59.997）
    **************************************************************/
    DECLARE @Thisyear_start DATETIME = DATEADD(yy, DATEDIFF(yy, 0, GETDATE()), 0);  
    DECLARE @Thisyear_end   DATETIME = DATEADD(ms, -3, DATEADD(yy, DATEDIFF(yy, 0, GETDATE()) + 1, 0));  
    DECLARE @buguidlist     VARCHAR(MAX) = NULL;

    /**************************************************************
    * 步骤2：获取所有末级公司（IsEndCompany=1）且为公司（IsCompany=1）的BUGUID列表
    * 以逗号分隔，供后续存储过程调用
    **************************************************************/
    SELECT @buguidList = STUFF(
        (
            SELECT DISTINCT RTRIM(',' + CONVERT(VARCHAR(MAX), unit.buguid))
            FROM [172.16.4.141].erp25.dbo.myBusinessUnit unit
            INNER JOIN [172.16.4.141].erp25.dbo.p_project p ON unit.buguid = p.buguid
            WHERE unit.IsEndCompany = 1 AND unit.IsCompany = 1
            FOR XML PATH('')
        ), 1, 1, ''
    );

    /**************************************************************
    * 步骤3：创建临时表#s_楼层齐步走，用于存储楼层齐步走明细数据
    * 字段涵盖公司、项目、楼层、业态、去化、未售等多维度信息
    **************************************************************/
    CREATE TABLE #s_楼层齐步走 (
        BUGUID UNIQUEIDENTIFIER,                -- 公司GUID
        projguid UNIQUEIDENTIFIER,              -- 项目GUID
        平台公司 VARCHAR(200),                  -- 平台公司名称
        城市 VARCHAR(200),                      -- 城市
        城市分类 VARCHAR(200),                  -- 城市分类
        标签城市分类 VARCHAR(200),              -- 标签城市分类
        城市六分化 VARCHAR(200),                -- 城市六分化
        项目五分类 VARCHAR(200),                -- 项目五分类
        板块分类 VARCHAR(200),                  -- 板块分类
        板块能级 VARCHAR(200),                  -- 板块能级
        并表方式 VARCHAR(200),                  -- 并表方式
        项目股权比例 VARCHAR(200),              -- 项目股权比例
        项目出资比例 VARCHAR(200),              -- 项目出资比例
        财务收益比例 VARCHAR(200),              -- 财务收益比例
        操盘方式 VARCHAR(200),                  -- 操盘方式
        获取时间 DATETIME,                      -- 数据获取时间
        项目名 VARCHAR(200),                    -- 项目名称
        推广名 VARCHAR(200),                    -- 推广名称
        项目代码 VARCHAR(200),                  -- 项目代码
        投管代码 VARCHAR(200),                  -- 投管代码
        操盘方式2 VARCHAR(200),                  -- 操盘方式（重复字段，建议后续优化）
        并表方式2 VARCHAR(200),                  -- 并表方式（重复字段，建议后续优化）
        总可售面积合计 DECIMAL(38,10),          -- 总可售面积合计
        总可售面积其中住宅 DECIMAL(38,10),      -- 总可售面积-住宅
        总可售面积其中商业 DECIMAL(38,10),      -- 总可售面积-商业
        总可售面积其中写字楼 DECIMAL(38,10),    -- 总可售面积-写字楼
        总可售面积其中公寓 DECIMAL(38,10),      -- 总可售面积-公寓
        总可售面积其中车位 DECIMAL(38,10),      -- 总可售面积-车位
        总可售套数合计 DECIMAL(38,10),          -- 总可售套数合计
        总可售套数其中住宅 DECIMAL(38,10),      -- 总可售套数-住宅
        总可售套数其中商业 DECIMAL(38,10),      -- 总可售套数-商业
        总可售套数其中写字楼 DECIMAL(38,10),    -- 总可售套数-写字楼
        总可售套数其中公寓 DECIMAL(38,10),      -- 总可售套数-公寓
        总可售套数其中车位 DECIMAL(38,10),      -- 总可售套数-车位
        车位首套成交日期 DATETIME,        -- 车位首套成交日期
        住宅首套成交日期 DATETIME,        -- 住宅首套成交日期
        楼层总已推住宅套数 DECIMAL(38,10),      -- 楼层总已推住宅套数
        楼层非天地层已推住宅套数 DECIMAL(38,10),-- 楼层非天地层已推住宅套数
        楼层天地层已推住宅套数 DECIMAL(38,10),  -- 楼层天地层已推住宅套数
        楼层总已售住宅套数 DECIMAL(38,10),      -- 楼层总已售住宅套数
        楼层非天地层已售住宅套数 DECIMAL(38,10),-- 楼层非天地层已售住宅套数
        楼层天地层已售住宅套数 DECIMAL(38,10),  -- 楼层天地层已售住宅套数
        楼层去化率 DECIMAL(38,10),              -- 楼层去化率
        楼层非天地去化率 DECIMAL(38,10),        -- 楼层非天地去化率
        楼层天地去化率 DECIMAL(38,10),          -- 楼层天地去化率
        天地非天地极差 DECIMAL(38,10),          -- 天地与非天地极差
        楼层范围内总已售住宅套数 DECIMAL(38,10),-- 楼层范围内总已售住宅套数
        楼层范围内非天地层已售住宅套数 DECIMAL(38,10), -- 楼层范围内非天地层已售住宅套数
        楼层范围内天地层已售住宅套数 DECIMAL(38,10),   -- 楼层范围内天地层已售住宅套数
        楼层非天地层未售住宅套数 DECIMAL(38,10),      -- 楼层非天地层未售住宅套数
        楼层非天地层未售住宅面积 DECIMAL(38,10),      -- 楼层非天地层未售住宅面积
        楼层非天地层未售住宅金额 DECIMAL(38,10),      -- 楼层非天地层未售住宅金额
        楼层天地层未售住宅套数 DECIMAL(38,10),        -- 楼层天地层未售住宅套数
        楼层天地层未售住宅面积 DECIMAL(38,10),        -- 楼层天地层未售住宅面积
        楼层天地层未售住宅金额 DECIMAL(38,10),        -- 楼层天地层未售住宅金额
        是否纳入考核 VARCHAR(200),                    -- 是否纳入考核
        qxdate DATETIME                               -- 清洗日期
    );

    /**************************************************************
    * 步骤4：调用楼层齐步走明细数据的存储过程，将结果插入临时表
    * 参数说明：
    *   @buguidlist      ：公司GUID列表
    *   @Thisyear_start  ：本年第一天
    *   @Thisyear_end    ：本年最后一天
    **************************************************************/
    INSERT INTO #s_楼层齐步走
    EXEC [172.16.4.141].erp25.dbo.usp_s_楼层齐步走 @buguidlist, @Thisyear_start, @Thisyear_end;

        /***********************************************************************
    步骤3：删除当天已存在的数据，避免重复插入
    说明：
        - 以清洗日期为准，删除当天数据
        - 保证数据唯一性
    ***********************************************************************/
    DELETE FROM s_集团开工申请天地楼层智能体数据提取
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0

	-- 插入智能体接口数据
    insert  into  s_集团开工申请天地楼层智能体数据提取
	SELECT 
       [projguid]
      ,a.平台公司 as  [平台公司]
      ,a.项目名 as  [项目名称]
      ,a.推广名 as  [推广名称]
      ,a.楼层总已推住宅套数 as  [已推住宅套数合计]
      ,a.楼层非天地层已推住宅套数 as  [已推住宅套数_其中非天地]
      ,a.楼层天地层已推住宅套数 as  [已推住宅套数_其中天地]
      ,a.楼层总已售住宅套数 as  [已售住宅套数合计]
      ,a.楼层非天地层已售住宅套数 as  [已售住宅套数_其中非天地]
      ,a.楼层天地层已售住宅套数 as  [已售住宅套数_其中天地]
      ,a.楼层去化率 *100 as  [去化率合计]
      ,a.楼层非天地去化率 *100 as  [非天地楼层去化率]
      ,a.楼层天地去化率 *100 as  [天地楼层去化率]
      ,a.天地非天地极差 *100 as  [楼层去化极差]
      ,a.楼层范围内总已售住宅套数 as  [已售住宅套数_统计范围内_合计]
      ,a.楼层范围内非天地层已售住宅套数 as  [已售住宅套数_统计范围内_其中非天地]
      ,a.楼层范围内天地层已售住宅套数 as  [已售住宅套数_统计范围内_其中天地]
      ,a.楼层非天地层未售住宅套数 as  [未售住宅情况_非天地套数]
      ,a.楼层非天地层未售住宅面积 /10000.0 as  [未售住宅情况_非天地面积] -- 万平方米
      ,a.楼层非天地层未售住宅金额 /100000000.0 as  [未售住宅情况_非天地金额] -- 亿元
      ,a.楼层天地层未售住宅套数 as  [未售住宅情况_天地套数]
      ,a.楼层天地层未售住宅面积 /10000.0  as  [未售住宅情况_天地面积]
      ,a.楼层天地层未售住宅金额 /100000000.0  as  [未售住宅情况_天地金额]
      ,a.是否纳入考核 as  [是否楼层齐步走考核项目]
      ,a.qxdate as  [清洗日期]
  FROM #s_楼层齐步走 a


--     /***********************************************************************
--     步骤5：清理历史数据，仅保留必要快照
--     说明：
--         - 保留当天数据
--         - 仅保留以下特殊快照，其余超过7天的历史数据将被删除：
--             1. 每周一
--             2. 每月1号
--             3. 每月最后一天
--             4. 每年最后一天
--     ***********************************************************************/
    DELETE FROM s_集团开工申请天地楼层智能体数据提取
    WHERE
        (
            -- 非每周一
            DATENAME(WEEKDAY, 清洗日期) <> '星期一'
            -- 非每月1号
            AND DATEPART(DAY, 清洗日期) <> 1
            -- 非每年最后一天
            AND DATEDIFF(DAY, 清洗日期, CONVERT(VARCHAR(4), YEAR(清洗日期)) + '-12-31') <> 0
            -- 非每月最后一天
            AND DATEDIFF(DAY, 清洗日期, DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗日期) + 1, 0))) <> 0
            -- 距今超过7天
            AND DATEDIFF(DAY, 清洗日期, GETDATE()) > 7
        )

--     /***********************************************************************
--     步骤6：查询当天数据，供后续分析或校验
--     说明：
--         - 返回当天清洗后的明细数据，便于后续分析或校验
--     ***********************************************************************/
    SELECT *
    FROM s_集团开工申请天地楼层智能体数据提取
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0
    ORDER BY 项目名称

	-- 删除临时表
	drop  TABLE #s_楼层齐步走

END





-- SELECT [projguid]
--       ,[平台公司]
--       ,[项目名称]
--       ,[推广名称]
--       ,[已推住宅套数合计]
--       ,[已推住宅套数_其中非天地]
--       ,[已推住宅套数_其中天地]
--       ,[已售住宅套数合计]
--       ,[已售住宅套数_其中非天地]
--       ,[已售住宅套数_其中天地]
--       ,[去化率合计]
--       ,[非天地楼层去化率]
--       ,[天地楼层去化率]
--       ,[楼层去化极差]
--       ,[已售住宅套数_统计范围内_合计]
--       ,[已售住宅套数_统计范围内_其中非天地]
--       ,[已售住宅套数_统计范围内_其中天地]
--       ,[未售住宅情况_非天地套数]
--       ,[未售住宅情况_非天地面积]
--       ,[未售住宅情况_非天地金额]
--       ,[未售住宅情况_天地套数]
--       ,[未售住宅情况_天地面积]
--       ,[未售住宅情况_天地金额]
--       ,[是否楼层齐步走考核项目]
--       ,[清洗日期]
--   FROM [dbo].[s_集团开工申请天地楼层智能体数据提取]
--   WHERE DATEDIFF(DAY, 清洗日期, @ChangeDate) = 0
--      AND (
--             @ProjGUID IS NULL
--             OR projguid IN (
--                 SELECT [Value]
--                 FROM dbo.fn_Split1(@ProjGUID, ',')
--             )
--         )


-- 参考住宅天地楼栋
-- USE [ERP25]
-- GO
-- /****** Object:  StoredProcedure [dbo].[usp_s_楼层齐步走]    Script Date: 2025/9/28 15:29:42 ******/
-- SET ANSI_NULLS ON
-- GO
-- SET QUOTED_IDENTIFIER ON
-- GO
-- ALTER proc [dbo].[usp_s_楼层齐步走](@BUGUID varchar(max),
-- @BgnDate datetime,
-- @EndDate datetime
-- )
-- as
-- --DECLARE @BUGUID varchar(400)
-- --DECLARE @BgnDate datetime
-- --DECLARE @EndDate datetime
-- --SET @BgnDate = '2024-01-01'
-- --SET @EndDate = '2024-12-19'
-- --select * from myBusinessUnit a where a.buname = '安徽公司'

-- --exec usp_s_楼层齐步走 '455FC380-B609-4A5A-9AAC-EE0F84C7F1B8','2025-01-01','2025-12-31'

-- --获取楼栋范围
-- SELECT DISTINCT
-- 	   bldguid
-- INTO #build
-- FROM p_room
-- WHERE status IN ( '认购', '签约' )
-- AND BUGUID in (   SELECT Value
--                                                          FROM   [dbo].[fn_Split2](
--                                                                     @BUGUID , ',') );

-- --获取总可售
-- SELECT 
-- a.projguid,
-- SUM(a.zksmj) zksmj,
-- SUM(CASE WHEN a.producttype ='住宅' THEN a.zksmj ELSE 0 END ) zzzksmj,
-- SUM(CASE WHEN a.producttype ='商业' THEN a.zksmj ELSE 0 END ) syzksmj,
-- SUM(CASE WHEN a.producttype ='写字楼' THEN a.zksmj ELSE 0 END ) xzlzksmj,
-- SUM(CASE WHEN a.producttype ='公寓' THEN a.zksmj ELSE 0 END ) gyzksmj,
-- SUM(CASE WHEN a.producttype ='地下室/车库' THEN a.zksmj ELSE 0 END ) cwzksmj,
-- SUM(a.zksts) zksts,
-- SUM(CASE WHEN a.producttype ='住宅' THEN a.zksts ELSE 0 END ) zzzksts,
-- SUM(CASE WHEN a.producttype ='商业' THEN a.zksts ELSE 0 END ) syzksts,
-- SUM(CASE WHEN a.producttype ='写字楼' THEN a.zksts ELSE 0 END ) xzlzksts,
-- SUM(CASE WHEN a.producttype ='公寓' THEN a.zksts ELSE 0 END ) gyzksts,
-- SUM(CASE WHEN a.producttype ='地下室/车库' THEN a.zksts ELSE 0 END ) cwzksts
-- INTO #zks
-- FROM p_lddb a 
-- LEFT JOIN p_project p on a.projguid = p.projguid 
-- WHERE DATEDIFF(dd,a.qxdate,GETDATE()) =0
-- and p.BUGUID in (   SELECT Value
--                                                          FROM   [dbo].[fn_Split2](
--                                                                     @BUGUID , ',') )
-- GROUP BY a.projguid

-- --缓存最早车位成交日期、最早住宅成交日期

-- SELECT l.projguid,
-- 	   MIN(o.qsdate) cwst
-- INTO #cwst
-- FROM s_order o
-- 	 LEFT JOIN p_room r ON o.roomguid = r.roomguid
-- 	 LEFT JOIN p_lddb l ON r.bldguid = l.salebldguid
-- 						   AND DATEDIFF(dd, l.qxdate, GETDATE()) = 0
-- WHERE (
-- 		  o.status = '激活'
-- 		  OR o.closereason = '转签约'
-- 	  )
-- 	  AND l.producttype = '地下室/车库'
-- 	  AND o.BUGUID  IN  (   SELECT Value
--                                                          FROM   [dbo].[fn_Split2](
--                                                                     @BUGUID , ',') )
-- 	  GROUP BY l.ProjGUID;


-- SELECT l.projguid,
-- 	   MIN(o.qsdate) zzst
-- INTO #zzst
-- FROM s_order o
-- 	 LEFT JOIN p_room r ON o.roomguid = r.roomguid
-- 	 LEFT JOIN p_lddb l ON r.bldguid = l.salebldguid
-- 						   AND DATEDIFF(dd, l.qxdate, GETDATE()) = 0
-- WHERE (
-- 		  o.status = '激活'
-- 		  OR o.closereason = '转签约'
-- 	  )
-- 	  AND l.producttype = '住宅'
-- 	  AND o.BUGUID in  (   SELECT Value
--                                                          FROM   [dbo].[fn_Split2](
--                                                                     @BUGUID , ',') )
-- 	  GROUP BY l.ProjGUID;

 
-- --业态齐步走BEGIN
-- SELECT l.projguid,
-- SUM(r.bldarea) ytzksmj,
-- SUM(CASE WHEN l.producttype ='住宅' THEN r.bldarea ELSE 0 END ) ytzzzksmj,
-- SUM(CASE WHEN l.producttype ='商业' THEN r.bldarea ELSE 0 END ) ytsyzksmj,
-- SUM(CASE WHEN l.producttype ='写字楼' THEN r.bldarea ELSE 0 END ) ytxzlzksmj,
-- SUM(CASE WHEN l.producttype ='公寓' THEN r.bldarea ELSE 0 END ) ytgyzksmj,
-- SUM(CASE WHEN l.producttype ='地下室/车库' THEN r.bldarea ELSE 0 END ) ytcwzksmj,
-- SUM(1) ytzksts,
-- SUM(CASE WHEN l.producttype ='住宅' THEN 1 ELSE 0 END ) ytzzzksts,
-- SUM(CASE WHEN l.producttype ='商业' THEN 1 ELSE 0 END ) ytsyzksts,
-- SUM(CASE WHEN l.producttype ='写字楼' THEN 1 ELSE 0 END ) ytxzlzksts,
-- SUM(CASE WHEN l.producttype ='公寓' THEN 1 ELSE 0 END ) ytgyzksts,
-- SUM(CASE WHEN l.producttype ='地下室/车库' THEN 1 ELSE 0 END ) ytcwzksts,
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
-- INTO #yetaiqibuzou
-- FROM p_room r 
-- INNER JOIN #build b ON r.bldguid=b.bldguid 
-- LEFT JOIN p_lddb l ON r.bldguid=l.salebldguid AND DATEDIFF(dd,qxdate,GETDATE()) =0
-- LEFT JOIN s_contract c ON r.roomguid=c.roomguid AND c.status='激活'
-- WHERE r.IsVirtualRoom=0 
-- and r.BUGUID in  (   SELECT Value
--                                                          FROM   [dbo].[fn_Split2](
--                                                                     @BUGUID , ',') )
-- GROUP BY l.projguid
-- --业态齐步走END

-- --户型齐步走BEGIN
-- SELECT l.projguid,
-- --80平以下	180平以上 中间每10平一列
-- SUM(1) ytts,
-- SUM(CASE WHEN r.bldarea<80 THEN 1 ELSE 0 END ) 'ts80以下', 
-- SUM(CASE WHEN r.bldarea>=80 AND r.bldarea<90 THEN 1 ELSE 0 END ) 'ts8090', 
-- SUM(CASE WHEN r.bldarea>=90 AND r.bldarea<100 THEN 1 ELSE 0 END ) 'ts90100', 
-- SUM(CASE WHEN r.bldarea>=100 AND r.bldarea<110 THEN 1 ELSE 0 END ) 'ts100110', 
-- SUM(CASE WHEN r.bldarea>=110 AND r.bldarea<120 THEN 1 ELSE 0 END ) 'ts110120', 
-- SUM(CASE WHEN r.bldarea>=120 AND r.bldarea<130 THEN 1 ELSE 0 END ) 'ts120130', 
-- SUM(CASE WHEN r.bldarea>=130 AND r.bldarea<140 THEN 1 ELSE 0 END ) 'ts130140', 
-- SUM(CASE WHEN r.bldarea>=140 AND r.bldarea<150 THEN 1 ELSE 0 END ) 'ts140150', 
-- SUM(CASE WHEN r.bldarea>=150 AND r.bldarea<160 THEN 1 ELSE 0 END ) 'ts150160', 
-- SUM(CASE WHEN r.bldarea>=160 AND r.bldarea<170 THEN 1 ELSE 0 END ) 'ts160170', 
-- SUM(CASE WHEN r.bldarea>=170 AND r.bldarea<180 THEN 1 ELSE 0 END ) 'ts170180', 
-- SUM(CASE WHEN r.bldarea>=180  THEN 1 ELSE 0 END ) 'ts180'
-- INTO #huxingks
-- FROM p_room r  
-- LEFT JOIN p_lddb l ON r.bldguid=l.salebldguid AND DATEDIFF(dd,qxdate,GETDATE()) =0 
-- WHERE l.producttype='住宅' 
-- AND r.IsVirtualRoom=0 
-- AND r.BUGUID in  (   SELECT Value
--                                                          FROM   [dbo].[fn_Split2](
--                                                                     @BUGUID , ',') )
-- GROUP BY l.projguid



-- --户型齐步走
-- SELECT l.projguid,
-- --80平以下	80-100平	100-130平	130-150平	150-180平	180平以上
-- SUM(1) ytts,
-- SUM(CASE WHEN r.bldarea<80 THEN 1 ELSE 0 END ) 'ts80以下', 
-- SUM(CASE WHEN r.bldarea>=80 AND r.bldarea<90 THEN 1 ELSE 0 END ) 'ts8090', 
-- SUM(CASE WHEN r.bldarea>=90 AND r.bldarea<100 THEN 1 ELSE 0 END ) 'ts90100', 
-- SUM(CASE WHEN r.bldarea>=100 AND r.bldarea<110 THEN 1 ELSE 0 END ) 'ts100110', 
-- SUM(CASE WHEN r.bldarea>=110 AND r.bldarea<120 THEN 1 ELSE 0 END ) 'ts110120', 
-- SUM(CASE WHEN r.bldarea>=120 AND r.bldarea<130 THEN 1 ELSE 0 END ) 'ts120130', 
-- SUM(CASE WHEN r.bldarea>=130 AND r.bldarea<140 THEN 1 ELSE 0 END ) 'ts130140', 
-- SUM(CASE WHEN r.bldarea>=140 AND r.bldarea<150 THEN 1 ELSE 0 END ) 'ts140150', 
-- SUM(CASE WHEN r.bldarea>=150 AND r.bldarea<160 THEN 1 ELSE 0 END ) 'ts150160', 
-- SUM(CASE WHEN r.bldarea>=160 AND r.bldarea<170 THEN 1 ELSE 0 END ) 'ts160170', 
-- SUM(CASE WHEN r.bldarea>=170 AND r.bldarea<180 THEN 1 ELSE 0 END ) 'ts170180', 
-- SUM(CASE WHEN r.bldarea>=180  THEN 1 ELSE 0 END ) 'ts180',  
-- --范围内已售
-- SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 THEN 1 ELSE 0 END ) 'rangeysts', 
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
-- INTO #huxingqibuzou
-- FROM p_room r 
-- INNER JOIN #build b ON r.bldguid=b.bldguid 
-- LEFT JOIN p_lddb l ON r.bldguid=l.salebldguid AND DATEDIFF(dd,qxdate,GETDATE()) =0
-- LEFT JOIN s_contract c ON r.roomguid=c.roomguid AND c.status='激活'
-- WHERE l.producttype='住宅' 
-- AND r.IsVirtualRoom=0 
-- AND r.BUGUID in  (   SELECT Value
--                                                          FROM   [dbo].[fn_Split2](
--                                                                     @BUGUID , ',') )
-- GROUP BY l.projguid

-- --户型齐步走END

-- --楼层齐步走BEGIN

-- 	--整理楼栋楼层
-- 	SELECT BldGUID,
-- 	MAX(newFloor) AS MaxFloor 
-- 	INTO #NewBldFloor
-- 	FROM (
-- 		SELECT 
-- 		BldGUID,
-- 		ROW_NUMBER() over(PARTITION BY BldGUID ORDER BY MAX(FloorNo)) newFloor
-- 		FROM 
-- 		ep_room
-- 		where isnull(floor,'') <> '' 
-- 		and BUGUID in  (   SELECT Value
--                                                          FROM   [dbo].[fn_Split2](
--                                                                     @BUGUID , ',') )
-- 		GROUP by bldguid,
-- 			replace( 
-- 					replace(FLOOR,
-- 							'南',''),
-- 					'北','')
-- 	)a
-- 	GROUP BY BldGUID


-- 	--缓存住宅楼栋天地楼层
-- 	SELECT a.SaleBldGUID,
-- 		rf.MaxFloor,
-- 		CASE WHEN ROUND(rf.MaxFloor*0.1,0) = 0 THEN 1 ELSE ROUND(rf.MaxFloor*0.1,0) END LowFloor,
-- 		CASE WHEN ROUND(rf.MaxFloor*0.1,0) = 0 THEN ROUND(rf.MaxFloor,0) -1 ELSE ROUND(rf.MaxFloor -ROUND(rf.MaxFloor*0.1,0),0)+1 END HighFloor																					
-- 	INTO #bldMaxFloor
-- 	FROM p_lddb a
-- 	LEFT JOIN #NewBldFloor rf ON rf.bldguid = a.SaleBldGUID
-- 	INNER JOIN #build ytld ON ytld.bldguid = a.SaleBldGUID
-- 	WHERE a.ProductType IN ('住宅') AND DATEDIFF(day,a.QXDate,GETDATE()) = 0

-- 	--缓存房间天地楼层情况
-- 	SELECT 
-- 	r.RoomGUID,
-- 	LHFloor.SaleBldGUID BldGUID,
-- 	LHFloor.MaxFloor MaxFloor,
-- 	LHFloor.LowFloor LowFloor,
-- 	LHFloor.HighFloor HighFloor,
-- 	CASE WHEN nr.newFloor >0 AND nr.newFloor <= LHFloor.LowFloor THEN 1
-- 		WHEN nr.newFloor >= HighFloor THEN 2
-- 		ELSE 3
-- 	END AS LowHighType
-- 	INTO #LH_Room
-- 	FROM 
-- 	ep_room r 
-- 	left join (
-- 		SELECT 
-- 		BldGUID,
-- 			replace( 
-- 					replace(FLOOR,
-- 							'南',''),
-- 					'北','') FLOOR,
-- 		ROW_NUMBER() over(PARTITION BY BldGUID ORDER BY MAX(FloorNo)) newFloor
-- 		FROM 
-- 		ep_room
-- 		where isnull(floor,'') <> '' 
-- 		and BUGUID in  (   SELECT Value
--                                                          FROM   [dbo].[fn_Split2](
--                                                                     @BUGUID , ',') )
-- 		GROUP by bldguid,
-- 			replace( 
-- 					replace(FLOOR,
-- 							'南',''),
-- 					'北','')
-- 	)nr on nr.BldGUID = r.BldGUID and replace( replace(r.FLOOR,'南',''),'北','') = nr.FLOOR
-- 	INNER JOIN #bldMaxFloor LHFloor ON LHFloor.SaleBldGUID = r.BldGUID
	
-- 	--整合项目统计
-- 	SELECT 
-- 	l.ProjGUID,
-- 	--已推住宅套数
-- 	SUM(1) AS ytTs,
-- 	SUM(CASE WHEN b.LowHighType = 3 THEN 1 ELSE 0 END) AS YtNormalTs,
-- 	SUM(CASE WHEN b.LowHighType <> 3 THEN 1 ELSE 0 END) AS YtLowHighTs,
-- 	--已售住宅套数-全部已售
-- 	SUM(CASE WHEN c.qsdate is not null THEN 1 ELSE 0 END) AS ysTs,
-- 	SUM(CASE WHEN c.qsdate is not null AND b.LowHighType = 3 THEN 1 ELSE 0 END) AS ysNormalTs,
-- 	SUM(CASE WHEN c.qsdate is not null AND b.LowHighType <> 3 THEN 1 ELSE 0 END) AS ysLowHighTs,
-- 	--已售住宅套数-范围内
-- 	SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 THEN 1 ELSE 0 END) AS RangeYtTs,
-- 	SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND b.LowHighType = 3 THEN 1 ELSE 0 END) AS RangeYtNormalTs,
-- 	SUM(CASE WHEN datediff(dd,isnull(c.qsdate,'2099-01-01'),@BgnDate)<=0 and datediff(dd,isnull(c.qsdate,'2099-01-01'),@EndDate)>=0 AND b.LowHighType <> 3 THEN 1 ELSE 0 END) AS RangeYtLowHighTs,
-- 	SUM(CASE WHEN b.LowHighType = 3 and r.status not in ('认购','签约') THEN 1 ELSE 0 END) AS wsNormalTs,
-- 	SUM(CASE WHEN b.LowHighType = 3 and r.status not in ('认购','签约') THEN r.bldarea ELSE 0 END) AS wsNormalArea,
-- 	SUM(CASE WHEN b.LowHighType = 3 and r.status not in ('认购','签约') THEN r.HSZJ ELSE 0 END) AS wsNormalje,
-- 	SUM(CASE WHEN b.LowHighType <> 3 and r.status not in ('认购','签约') THEN 1 ELSE 0 END) AS wsLowHighTs,
-- 	SUM(CASE WHEN b.LowHighType <> 3 and r.status not in ('认购','签约') THEN r.bldarea ELSE 0 END) AS wsLowHighArea,
-- 	SUM(CASE WHEN b.LowHighType <> 3 and r.status not in ('认购','签约') THEN r.HSZJ ELSE 0 END) AS wsLowHighje
-- 	INTO #loucengqibuzou
-- 	FROM 
-- 	p_room r
-- 	INNER JOIN #LH_Room b on r.RoomGUID = b.RoomGUID
-- 	LEFT JOIN p_lddb l ON r.BldGUID=l.SaleBldGUID AND DATEDIFF(dd,qxdate,GETDATE()) =0
-- 	LEFT JOIN s_contract c ON r.roomguid=c.roomguid AND c.status='激活'
-- 	WHERE r.IsVirtualRoom=0 
-- 	GROUP BY l.ProjGUID

-- --楼层齐步走END



-- --获取汇总数
-- SELECT p.BUGUID,
-- 	   f.projguid,
-- 	   f.平台公司,
-- 	   f.城市,
-- 	   f.城市分类,
-- 	   f.标签城市分类,
-- 	   f.城市六分化,
-- 	   f.项目五分类,
-- 	   f.板块分类,
-- 	   f.板块能级,
-- 	   f.并表方式,
-- 	   f.项目股权比例,
-- 	   f.项目出资比例,
-- 	   f.财务收益比例,
-- 	   f.操盘方式,
-- 	   f.获取时间,
-- 	   f.项目名,
-- 	   f.推广名,
-- 	   f.项目代码,
-- 	   f.投管代码,
-- 	   f.操盘方式,
-- 	   f.并表方式,
-- 	   --总可售
-- 	   CAST(z.zksmj/10000 AS DECIMAL(18,2)) 总可售面积合计,
-- 	   CAST(z.zzzksmj/10000 AS DECIMAL(18,2)) 总可售面积其中住宅,
-- 	   CAST(z.syzksmj/10000 AS DECIMAL(18,2)) 总可售面积其中商业,
-- 	   CAST(z.xzlzksmj/10000 AS DECIMAL(18,2)) 总可售面积其中写字楼,
-- 	   CAST(z.gyzksmj/10000 AS DECIMAL(18,2)) 总可售面积其中公寓,
-- 	   CAST(z.cwzksmj/10000 AS DECIMAL(18,2)) 总可售面积其中车位,
-- 	   z.zksts 总可售套数合计,
-- 	   z.zzzksts 总可售套数其中住宅,
-- 	   z.syzksts 总可售套数其中商业,
-- 	   z.xzlzksts 总可售套数其中写字楼,
-- 	   z.gyzksts 总可售套数其中公寓,
-- 	   z.cwzksts 总可售套数其中车位,
-- 	   cwst.cwst 车位首套成交日期,
-- 	   zzst.zzst 住宅首套成交日期,

	   
-- 	   --楼层齐步走
-- 	   lc.ytTs '楼层总已推住宅套数',
-- 	   lc.YtNormalTs '楼层非天地层已推住宅套数',
-- 	   lc.YtLowHighTs '楼层天地层已推住宅套数',
-- 	   lc.ysTs '楼层总已售住宅套数',
-- 	   lc.ysNormalTs '楼层非天地层已售住宅套数',
-- 	   lc.ysLowHighTs '楼层天地层已售住宅套数',
-- 	   case when lc.ytTs = 0 then 0 else lc.ysTs*1.00 / lc.ytTs end '楼层去化率',
-- 	   case when lc.YtNormalTs = 0 then 0 else lc.ysNormalTs*1.00 / lc.YtNormalTs end '楼层非天地去化率',
-- 	   case when lc.YtLowHighTs = 0 then 0 else lc.ysLowHighTs*1.00 / lc.YtLowHighTs end '楼层天地去化率',
-- 	   case when lc.YtLowHighTs = 0 then 0 else lc.ysLowHighTs*1.00 / lc.YtLowHighTs end -
-- 	   case when lc.YtNormalTs = 0 then 0 else lc.ysNormalTs*1.00 / lc.YtNormalTs end '天地非天地极差',
	   
-- 	   lc.RangeYtTs '楼层范围内总已售住宅套数',
-- 	   lc.RangeYtNormalTs '楼层范围内非天地层已售住宅套数',
-- 	   lc.RangeYtLowHighTs '楼层范围内天地层已售住宅套数',
-- 	   lc.wsNormalTs '楼层非天地层未售住宅套数',
-- 	   lc.wsNormalArea '楼层非天地层未售住宅面积',
-- 	   lc.wsNormalje '楼层非天地层未售住宅金额',
-- 	   lc.wsLowHighTs '楼层天地层未售住宅套数',
-- 	   lc.wsLowHighArea '楼层天地层未售住宅面积',
-- 	   lc.wsLowHighje '楼层天地层未售住宅金额',
-- 	   CASE WHEN isnull(fp.投管代码,'') <> '' then '是' else '否' end 是否纳入考核,
-- 	   getdate() qxdate
	   
-- FROM vmdm_projectflag f
-- 	 LEFT JOIN #zks z ON f.projguid = z.projguid
-- 	 LEFT JOIN #yetaiqibuzou y ON f.projguid = y.projguid
-- 	 LEFT JOIN #huxingqibuzou h ON f.projguid = h.projguid
-- 	 LEFT JOIN #huxingks hs ON f.projguid = hs.projguid
-- 	 LEFT JOIN #loucengqibuzou lc on f.projguid = lc.projguid
-- 	 LEFT JOIN #cwst cwst on  f.projguid = cwst.projguid
-- 	 LEFT JOIN #zzst zzst on  f.projguid = zzst.projguid
-- 	 LEFT JOIN p_project p on f.projguid = p.projguid
-- 	 LEFT JOIN s_lchxqbzproj fp on fp.投管代码 = f.投管代码 and isnull(fp.投管代码,'') <> ''
-- WHERE p.BUGUID in  (   SELECT Value
--                                                          FROM   [dbo].[fn_Split2](
--                                                                     @BUGUID , ',') )
-- ORDER BY f.平台公司,
-- 		 f.项目名;


-- DROP TABLE #bldMaxFloor,#build,#cwst,#huxingks,#huxingqibuzou,#LH_Room,#loucengqibuzou,#NewBldFloor,#yetaiqibuzou,#zks,#zzst