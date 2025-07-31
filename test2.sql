-- 创建索引提示以提高性能
SET NOCOUNT ON;

-- 使用CTE替代部分临时表，减少IO开销
WITH ProjectCTE AS (
    SELECT pj.ImportSaleProjGUID,
           pj.ProjGUID,
           pj.OrgCompanyGUID AS BUGUID,
           CASE WHEN pj.cityguid = 'A9001052-40D6-4CA3-9BD3-C3DF4F9DDCF8' THEN 1 ELSE 0 END AS 是否佛山区域,
           CASE 
                WHEN DATEDIFF(yy,'2023-01-01',pj.AcquisitionDate) >= 0 THEN '新增量'  
                WHEN DATEDIFF(yy,'2022-01-01',pj.AcquisitionDate) = 0 THEN '增量'
                ELSE '存量' 
           END AS 项目类型,
           parentbiz.ParamValue AS 所属区域
    FROM mdm_Project pj WITH (NOLOCK)
    INNER JOIN myBizParamOption biz WITH (NOLOCK) ON pj.xmsscsgsguid = biz.ParamGUID
    LEFT JOIN myBizParamOption parentBiz WITH (NOLOCK) ON biz.ParentCode = parentBiz.ParamCode
                                                   AND biz.ScopeGUID = parentBiz.ScopeGUID
                                                   AND parentBiz.ParamLevel = 1
    WHERE Level = 2
    AND DevelopmentCompanyGUID = 'AADC0FA7-9546-49C9-B64B-825056C828ED'
    -- AND projguid IN ( @projguid )
)

-- 创建临时表并添加索引以提高后续查询性能
SELECT *,
       CASE WHEN (SELECT COUNT(DISTINCT 所属区域) FROM ProjectCTE) >= 8 THEN '是' ELSE '否' END AS 是否公司层级
INTO #p
FROM ProjectCTE;

-- 添加索引以提高后续查询性能
CREATE NONCLUSTERED INDEX IX_p_ProjGUID ON #p(ProjGUID);
CREATE NONCLUSTERED INDEX IX_p_BUGUID ON #p(BUGUID);
CREATE NONCLUSTERED INDEX IX_p_ImportSaleProjGUID ON #p(ImportSaleProjGUID);

-- 获取DSS任务，优化GROUP BY操作
SELECT 
    p.BUGUID,
    CASE WHEN p.是否公司层级 = '是' THEN '华南公司' ELSE p.所属区域 END AS 所属区域,
    SUM(a.[签约任务(亿元)]) AS 月度签约任务,
    SUM(a.[回笼任务(亿元)]) AS 月度回笼任务,
    SUM(a.[开工任务(万平)]) AS 月度开工任务,
    MAX(CASE WHEN p.是否公司层级 = '是' AND ISNULL(a.销净率,0) <> 0 THEN a.销净率 ELSE NULL END) AS 月度销净率任务
INTO #yd
FROM dss.dbo.[nmap_F_平台公司项目层级月度任务填报] a WITH (NOLOCK)
INNER JOIN dss.dbo.nmap_F_FillHistory f WITH (NOLOCK) ON f.FillHistoryGUID = a.FillHistoryGUID
INNER JOIN #p p ON p.ProjGUID = a.BusinessGUID
WHERE DATEDIFF(MONTH, f.BeginDate, GETDATE()) = 0
GROUP BY p.BUGUID, CASE WHEN p.是否公司层级 = '是' THEN '华南公司' ELSE p.所属区域 END;

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_yd_BUGUID ON #yd(BUGUID);
CREATE NONCLUSTERED INDEX IX_yd_所属区域 ON #yd(所属区域);

-- 缓存处理过期特殊业绩，优化查询条件
-- 使用临时表存储特殊业绩关联的清单
WITH SpecialPerformanceRooms AS (
    SELECT a.PerformanceAppraisalGUID,
           s.rddate,
           r.roomguid,
           r.bldarea
    FROM S_PerformanceAppraisalBuildings a WITH (NOLOCK)
    LEFT JOIN p_building b WITH (NOLOCK) ON a.BldGUID = b.BldGUID
    LEFT JOIN p_room r WITH (NOLOCK) ON b.BldGUID = r.BldGUID
    INNER JOIN S_PerformanceAppraisal s WITH (NOLOCK) ON a.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
    INNER JOIN #p p ON p.projguid = s.ManagementProjectGUID 
    WHERE (s.auditstatus IN ('过期审核中','已过期')
        OR (s.auditstatus = '作废' AND s.CancelAuditTime >= '2024-01-01'))
        AND s.PerformanceAppraisalGUID <> 'CDF2A700-1117-EE11-B3A3-F40270D39969'
        AND s.DevelopmentCompanyGUID = 'AADC0FA7-9546-49C9-B64B-825056C828ED'
    
    UNION ALL
    
    SELECT r.PerformanceAppraisalGUID,
           s.rddate,
           p.roomguid,
           p.bldarea
    FROM S_PerformanceAppraisalRoom r WITH (NOLOCK)
    LEFT JOIN p_room p WITH (NOLOCK) ON r.roomguid = p.roomguid
    INNER JOIN S_PerformanceAppraisal s WITH (NOLOCK) ON r.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
    INNER JOIN #p pp ON pp.projguid = s.ManagementProjectGUID 
    WHERE (s.auditstatus IN ('过期审核中','已过期')
        OR (s.auditstatus = '作废' AND s.CancelAuditTime >= '2024-01-01'))
        AND s.PerformanceAppraisalGUID <> 'CDF2A700-1117-EE11-B3A3-F40270D39969'
        AND s.DevelopmentCompanyGUID = 'AADC0FA7-9546-49C9-B64B-825056C828ED'
)

-- 如果多重对接的话，取去重的数据
SELECT roomguid,
       PerformanceAppraisalGUID,
       ROW_NUMBER() OVER (PARTITION BY roomguid ORDER BY rddate DESC) AS num,
       bldarea
INTO #r
FROM SpecialPerformanceRooms;

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_r_roomguid ON #r(roomguid);
CREATE NONCLUSTERED INDEX IX_r_PerformanceAppraisalGUID ON #r(PerformanceAppraisalGUID);

-- 关联特殊业绩认定信息
SELECT s.*,
       a.RoomGUID
INTO #sroom
FROM #r a
INNER JOIN S_PerformanceAppraisal s WITH (NOLOCK) ON a.PerformanceAppraisalGUID = s.PerformanceAppraisalGUID
    AND (s.auditstatus IN ('已过期', '过期审核中') 
        OR (s.auditstatus = '作废' AND s.CancelAuditTime >= '2024-01-01')
    )
WHERE a.num = 1
AND s.yjtype NOT IN ('物业公司车位代销', '经营类(溢价款)');

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_sroom_RoomGUID ON #sroom(RoomGUID);

-- 获取房间没有关联到特殊业绩的房间明细
-- 使用EXISTS代替IN提高性能
SELECT a.RoomGUID,
       a.BldGUID,
       a.BldArea,
       p.projguid
INTO #room
FROM p_room a WITH (NOLOCK)
INNER JOIN mdm_project pj WITH (NOLOCK) ON a.projguid = pj.projguid
INNER JOIN #p p ON p.projguid = pj.parentprojguid
WHERE NOT EXISTS (
    SELECT 1 FROM dbo.S_PerformanceAppraisalRoom sr WITH (NOLOCK)
    INNER JOIN dbo.S_PerformanceAppraisal s WITH (NOLOCK) ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
    WHERE sr.RoomGUID = a.RoomGUID
    AND s.AuditStatus = '已审核'
    AND s.yjtype NOT IN ('经营类(溢价款)', '物业公司车位代销')
)
AND NOT EXISTS (
    SELECT 1 FROM dbo.S_PerformanceAppraisalBuildings sr WITH (NOLOCK)
    INNER JOIN dbo.S_PerformanceAppraisal s WITH (NOLOCK) ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
    WHERE sr.BldGUID = a.BldGUID
    AND s.AuditStatus = '已审核'
    AND s.yjtype NOT IN ('经营类(溢价款)', '物业公司车位代销')
);

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_room_RoomGUID ON #room(RoomGUID);
CREATE NONCLUSTERED INDEX IX_room_projguid ON #room(projguid);

-- 优化订单查询
SELECT o.QSDate, 
       o.TradeGUID,
       o.Status,
       o.CloseReason,
       o.JyTotal,
       a.projguid
INTO #so
FROM s_Order o WITH (NOLOCK)
INNER JOIN #room a ON a.RoomGUID = o.RoomGUID  
LEFT JOIN #sroom sr ON sr.roomguid = o.roomguid
WHERE YEAR(
    CASE
        WHEN DATEDIFF(DAY, ISNULL(o.CreatedOn, o.qsdate), ISNULL(sr.SetGqAuditTime, ISNULL(sr.CancelAuditTime,'1900-01-01'))) > 0 
        THEN sr.rddate
        ELSE o.QSDate
    END
) = YEAR(GETDATE());

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_so_projguid ON #so(projguid);
CREATE NONCLUSTERED INDEX IX_so_TradeGUID ON #so(TradeGUID);
CREATE NONCLUSTERED INDEX IX_so_Status ON #so(Status);
CREATE NONCLUSTERED INDEX IX_so_QSDate ON #so(QSDate);

-- 缓存认购，优化聚合计算
SELECT 
    o.projguid,
    SUM(CASE
        WHEN DATEDIFF(dd, o.QSDate, GETDATE()) = 0 AND o.Status = '激活' THEN o.JyTotal
        WHEN DATEDIFF(dd, o.QSDate, GETDATE()) = 0 AND sc.Status = '激活' THEN sc.JyTotal 
        ELSE 0 
    END) / 10000 AS brrg,
    SUM(CASE
        WHEN MONTH(o.QSDate) = MONTH(GETDATE()) AND o.Status = '激活' THEN o.JyTotal
        WHEN MONTH(o.QSDate) = MONTH(GETDATE()) AND sc.Status = '激活' THEN sc.JyTotal 
        ELSE 0 
    END) / 10000 AS rg,
    SUM(CASE
        WHEN o.Status = '激活' THEN o.JyTotal
        WHEN sc.Status = '激活' THEN sc.JyTotal 
        ELSE 0 
    END) / 10000 AS nrg, --年度认购万元  
    SUM(CASE 
        WHEN o.Status = '激活' THEN o.JyTotal 
        ELSE 0 
    END) / 10000 AS rgwqy
INTO #order
FROM #so o
LEFT JOIN dbo.s_Contract sc WITH (NOLOCK) ON sc.Status = '激活' AND sc.TradeGUID = o.TradeGUID
WHERE o.Status = '激活' OR (o.CloseReason = '转签约' AND sc.Status = '激活')
GROUP BY o.projguid;

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_order_projguid ON #order(projguid);

-- 优化签约查询
SELECT 
    a.projguid,
    c.JyTotal,
    c.QSDate,
    c.TradeGUID,
    a.BldGUID,
    a.BldArea
INTO #sc
FROM s_Contract c WITH (NOLOCK)
INNER JOIN #room a ON a.RoomGUID = c.RoomGUID
LEFT JOIN #sroom sr ON sr.roomguid = a.roomguid
WHERE c.Status = '激活' 
AND YEAR(
    CASE
        WHEN DATEDIFF(DAY, ISNULL(c.CreatedOn, c.qsdate), ISNULL(sr.SetGqAuditTime, ISNULL(sr.CancelAuditTime,'1900-01-01'))) > 0 
        THEN sr.rddate
        ELSE c.QSDate
    END
) = YEAR(GETDATE());

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_sc_projguid ON #sc(projguid);
CREATE NONCLUSTERED INDEX IX_sc_TradeGUID ON #sc(TradeGUID);
CREATE NONCLUSTERED INDEX IX_sc_BldGUID ON #sc(BldGUID);

-- 缓存签约，优化聚合计算
SELECT 
    c.projguid,
    SUM(c.JyTotal) / 10000 AS nqy,
    SUM(CASE WHEN DATEDIFF(dd, c.QSDate, GETDATE()) = 0 THEN c.JyTotal ELSE 0 END) / 10000 AS brqy,
    SUM(CASE WHEN MONTH(c.QSDate) = MONTH(GETDATE()) THEN c.JyTotal ELSE 0 END) / 10000 AS yqy,
    -- 获取直接签约的金额
    SUM(CASE WHEN so.OrderGUID IS NULL THEN c.JyTotal ELSE 0 END) / 10000 AS nrg,
    SUM(CASE WHEN DATEDIFF(dd, c.QSDate, GETDATE()) = 0 AND so.OrderGUID IS NULL THEN c.JyTotal ELSE 0 END) / 10000 AS brrg,
    SUM(CASE WHEN MONTH(c.QSDate) = MONTH(GETDATE()) AND so.OrderGUID IS NULL THEN c.JyTotal ELSE 0 END) / 10000 AS yrg                                           
INTO #con
FROM #sc c
LEFT JOIN dbo.s_Order so WITH (NOLOCK) ON ISNULL(so.TradeGUID, '') = ISNULL(c.TradeGUID, '')
INNER JOIN dbo.p_Building bd WITH (NOLOCK) ON c.BldGUID = bd.BldGUID
LEFT JOIN mdm_SaleBuild sb WITH (NOLOCK) ON bd.BldGUID = sb.ImportSaleBldGUID 
WHERE (so.Status = '关闭' AND so.CloseReason = '转签约') OR so.TradeGUID IS NULL
GROUP BY c.projguid;

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_con_projguid ON #con(projguid);

-- 获取操盘项目完成情况，优化聚合计算
SELECT 
    mp.BUGUID AS BUGUID,
    CASE WHEN mp.是否公司层级 = '是' THEN '华南公司' ELSE mp.所属区域 END AS 所属区域,
    ISNULL(SUM(rg.brrg), 0) + ISNULL(SUM(qy.brrg), 0) AS '本日认购',
    ISNULL(SUM(rg.rg), 0) + ISNULL(SUM(qy.yrg), 0) AS '月度认购',
    ISNULL(SUM(rg.nrg), 0) + ISNULL(SUM(qy.nrg), 0) AS '年度认购', 
    -- 新增字段 
    SUM(CASE WHEN mp.项目类型 = '存量' THEN ISNULL(rg.nrg, 0) + ISNULL(qy.nrg, 0) ELSE 0 END) AS 本年存量项目认购金额,
    SUM(CASE WHEN mp.项目类型 = '增量' THEN ISNULL(rg.nrg, 0) + ISNULL(qy.nrg, 0) ELSE 0 END) AS 本年增量项目认购金额,
    SUM(CASE WHEN mp.项目类型 = '新增量' THEN ISNULL(rg.nrg, 0) + ISNULL(qy.nrg, 0) ELSE 0 END) AS 本年新增量项目认购金额,
    SUM(CASE WHEN mp.是否佛山区域 = 1 THEN ISNULL(rg.nrg, 0) + ISNULL(qy.nrg, 0) ELSE 0 END) AS 佛山本年认购金额, 
    ISNULL(SUM(rg.rgwqy), 0) AS '认购未签约',
    ISNULL(SUM(qy.brqy), 0) AS '本日签约',
    ISNULL(SUM(qy.yqy), 0) AS '月度签约',
    ISNULL(SUM(qy.nqy), 0) AS '年度签约'    
INTO #t
FROM #p mp
LEFT JOIN #order rg ON rg.projguid = ISNULL(mp.ImportSaleProjGUID, mp.projguid)
LEFT JOIN #con qy ON qy.projguid = ISNULL(mp.ImportSaleProjGUID, mp.projguid)  
GROUP BY 
    mp.BUGUID,
    CASE WHEN mp.是否公司层级 = '是' THEN '华南公司' ELSE mp.所属区域 END;

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_t_BUGUID ON #t(BUGUID);
CREATE NONCLUSTERED INDEX IX_t_所属区域 ON #t(所属区域);

-- 获取非操盘项目完成情况，优化聚合计算
SELECT 
    c.BUGuid,
    CASE WHEN p.是否公司层级 = '是' THEN '华南公司' ELSE p.所属区域 END AS 所属区域,
    SUM(CASE WHEN b.DateYear = YEAR(GETDATE()) AND b.datemonth = MONTH(GETDATE()) THEN a.Amount ELSE 0 END) AS '月度认购',
    SUM(CASE WHEN b.DateYear = YEAR(GETDATE()) THEN a.Amount ELSE 0 END) AS '年度认购', 
    -- 新增字段 
    SUM(CASE WHEN p.项目类型 = '存量' AND b.DateYear = YEAR(GETDATE()) THEN a.Amount ELSE 0 END) AS 本年存量项目认购金额,
    SUM(CASE WHEN p.项目类型 = '增量' AND b.DateYear = YEAR(GETDATE()) THEN a.Amount ELSE 0 END) AS 本年增量项目认购金额,
    SUM(CASE WHEN p.项目类型 = '新增量' AND b.DateYear = YEAR(GETDATE()) THEN a.Amount ELSE 0 END) AS 本年新增量项目认购金额,
    SUM(CASE WHEN p.是否佛山区域 = 1 AND b.DateYear = YEAR(GETDATE()) THEN a.Amount ELSE 0 END) AS 佛山本年认购金额,   
    SUM(CASE WHEN b.DateYear = YEAR(GETDATE()) AND b.datemonth = MONTH(GETDATE()) THEN a.Amount ELSE 0 END) AS '月度签约',
    SUM(CASE WHEN b.DateYear = YEAR(GETDATE()) THEN a.Amount ELSE 0 END) AS '年度签约'
INTO #t1
FROM dbo.s_YJRLProducteDescript a WITH (NOLOCK) 
LEFT JOIN (
    SELECT *,
           CONVERT(DATETIME, b.DateYear + '-' + b.DateMonth + '-01') AS [BizDate]
    FROM dbo.s_YJRLProducteDetail b WITH (NOLOCK)
) b ON b.ProducteDetailGUID = a.ProducteDetailGUID
LEFT JOIN dbo.s_YJRLProjSet c WITH (NOLOCK) ON c.ProjSetGUID = b.ProjSetGUID
INNER JOIN #p p WITH (NOLOCK) ON p.ProjGUID = c.ProjGUID
WHERE b.Shenhe = '审核'
AND b.DateYear = YEAR(GETDATE())
GROUP BY 
    c.BUGuid,
    CASE WHEN p.是否公司层级 = '是' THEN '华南公司' ELSE p.所属区域 END;

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_t1_BUGuid ON #t1(BUGuid);
CREATE NONCLUSTERED INDEX IX_t1_所属区域 ON #t1(所属区域);

-- 加上特殊业绩，优化聚合计算
WITH SpecialPerformance AS (
    SELECT 
        p.BUGUID,
        CASE WHEN p.是否公司层级 = '是' THEN '华南公司' ELSE p.所属区域 END AS 所属区域,
        SUM(CASE WHEN YEAR(a.RdDate) = YEAR(GETDATE()) THEN a.TotalAmount ELSE 0 END) AS BNJE,
        SUM(CASE WHEN DATEDIFF(m, ISNULL(RdDate, a.CreationTime), GETDATE()) = 0 THEN a.TotalAmount ELSE 0 END) AS BYJE,
        -- 新增字段
        SUM(CASE WHEN p.项目类型 = '存量' AND YEAR(a.RdDate) = YEAR(GETDATE()) THEN a.TotalAmount ELSE 0 END) AS 本年存量项目认购金额,
        SUM(CASE WHEN p.项目类型 = '增量' AND YEAR(a.RdDate) = YEAR(GETDATE()) THEN a.TotalAmount ELSE 0 END) AS 本年增量项目认购金额,
        SUM(CASE WHEN p.项目类型 = '新增量' AND YEAR(a.RdDate) = YEAR(GETDATE()) THEN a.TotalAmount ELSE 0 END) AS 本年新增量项目认购金额,
        SUM(CASE WHEN p.是否佛山区域 = 1 AND YEAR(a.RdDate) = YEAR(GETDATE()) THEN a.TotalAmount ELSE 0 END) AS 佛山本年认购金额
    FROM dbo.S_PerformanceAppraisal a WITH (NOLOCK) 
    INNER JOIN #p p ON p.ProjGUID = a.ManagementProjectGUID
    WHERE a.AuditStatus = '已审核'
    AND a.YjType IN (SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom = 0)
    AND YEAR(a.RdDate) = YEAR(GETDATE())
    GROUP BY 
        p.BUGUID,
        CASE WHEN p.是否公司层级 = '是' THEN '华南公司' ELSE p.所属区域 END
    
    UNION ALL
    
    SELECT 
        p.BUGUID,
        CASE WHEN p.是否公司层级 = '是' THEN '华南公司' ELSE p.所属区域 END AS 所属区域,
        SUM(CASE WHEN YEAR(a.rddate) = YEAR(GETDATE()) THEN b.totalamount ELSE 0 END) AS BNJE,
        SUM(CASE WHEN DATEDIFF(m, ISNULL(rddate, a.CreationTime), GETDATE()) = 0 THEN b.totalamount ELSE 0 END) AS BYJE,
        -- 新增字段
        SUM(CASE WHEN p.项目类型 = '存量' AND YEAR(a.rddate) = YEAR(GETDATE()) THEN b.totalamount ELSE 0 END) AS 本年存量项目认购金额,
        SUM(CASE WHEN p.项目类型 = '增量' AND YEAR(a.rddate) = YEAR(GETDATE()) THEN b.totalamount ELSE 0 END) AS 本年增量项目认购金额,
        SUM(CASE WHEN p.项目类型 = '新增量' AND YEAR(a.rddate) = YEAR(GETDATE()) THEN b.totalamount ELSE 0 END) AS 本年新增量项目认购金额,
        SUM(CASE WHEN p.是否佛山区域 = 1 AND YEAR(a.rddate) = YEAR(GETDATE()) THEN b.totalamount ELSE 0 END) AS 佛山本年认购金额
    FROM S_PerformanceAppraisal a WITH (NOLOCK)
    LEFT JOIN (
        SELECT 
            PerformanceAppraisalGUID,
            BldGUID,
            IdentifiedArea AS areatotal,
            AffirmationNumber AS AggregateNumber,
            AmountDetermined AS totalamount
        FROM dbo.S_PerformanceAppraisalBuildings WITH (NOLOCK)
        
        UNION ALL
        
        SELECT 
            PerformanceAppraisalGUID,
            r.ProductBldGUID AS BldGUID,
            SUM(a.IdentifiedArea),
            SUM(a.AffirmationNumber),
            SUM(a.AmountDetermined)
        FROM dbo.S_PerformanceAppraisalRoom a WITH (NOLOCK)
        LEFT JOIN MyCost_Erp352.dbo.md_Room r WITH (NOLOCK) ON a.RoomGUID = r.RoomGUID
        GROUP BY 
            PerformanceAppraisalGUID,
            r.ProductBldGUID
    ) b ON a.PerformanceAppraisalGUID = b.PerformanceAppraisalGUID
    INNER JOIN #p p ON p.ProjGUID = a.ManagementProjectGUID
    WHERE a.AuditStatus = '已审核'
    AND a.YjType IN (SELECT TsyjTypeName FROM s_TsyjType WITH (NOLOCK) WHERE IsRelatedBuildingsRoom = 1)
    AND YEAR(a.rddate) = YEAR(GETDATE())
    GROUP BY 
        p.BUGUID,
        CASE WHEN p.是否公司层级 = '是' THEN '华南公司' ELSE p.所属区域 END
)

SELECT 
    BUGUID,
    所属区域,
    SUM(BNJE) AS BNJE,
    SUM(BYJE) AS ByJE,
    SUM(本年存量项目认购金额) AS 本年存量项目认购金额, 
    SUM(本年增量项目认购金额) AS 本年增量项目认购金额,
    SUM(本年新增量项目认购金额) AS 本年新增量项目认购金额,
    SUM(佛山本年认购金额) AS 佛山本年认购金额
INTO #ts
FROM SpecialPerformance
GROUP BY 
    BUGUID,
    所属区域;

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_ts_BUGUID ON #ts(BUGUID);
CREATE NONCLUSTERED INDEX IX_ts_所属区域 ON #ts(所属区域);

-- 取本年产成品签约从楼栋底表取p_lddbamj，优化聚合计算
SELECT 
    c.BUGUID,
    CASE WHEN c.是否公司层级 = '是' THEN '华南公司' ELSE c.所属区域 END AS 所属区域,
    SUM(CASE WHEN DATEDIFF(dd, a.SJzskgdate, GETDATE()) = 0 THEN ISNULL(UpBuildArea, 0) + ISNULL(DownBuildArea, 0) ELSE 0 END) AS 本日新开工,
    SUM(CASE WHEN DATEDIFF(mm, a.SJzskgdate, GETDATE()) = 0 THEN ISNULL(UpBuildArea, 0) + ISNULL(DownBuildArea, 0) ELSE 0 END) AS 本月新开工,
    SUM(CASE WHEN DATEDIFF(yy, a.SJzskgdate, GETDATE()) = 0 THEN ISNULL(UpBuildArea, 0) + ISNULL(DownBuildArea, 0) ELSE 0 END) AS 本年新开工
INTO #ccpqy
FROM p_lddbamj a WITH (NOLOCK)
INNER JOIN #p c ON a.ProjGUID = c.ProjGUID
INNER JOIN mdm_SaleBuild sb WITH (NOLOCK) ON sb.salebldguid = a.salebldguid
WHERE DATEDIFF(DAY, a.QXDate, GETDATE()) = 0
GROUP BY 
    c.BUGUID,
    CASE WHEN c.是否公司层级 = '是' THEN '华南公司' ELSE c.所属区域 END;

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_ccpqy_BUGUID ON #ccpqy(BUGUID);
CREATE NONCLUSTERED INDEX IX_ccpqy_所属区域 ON #ccpqy(所属区域);

-- 获取回款，优化聚合计算
SELECT 
    mp.buguid,
    CASE WHEN mp.是否公司层级 = '是' THEN '华南公司' ELSE mp.所属区域 END AS 所属区域,
    CASE 
        WHEN DAY(GETDATE()) = 1 THEN ISNULL(SUM(hk.yhk), 0) 
        ELSE ISNULL(SUM(hk.yhk), 0) - ISNULL(SUM(zrhk.yhk), 0) 
    END AS 本日回款,   
    ISNULL(SUM(hk.yhk), 0) AS '月度回款',
    ISNULL(SUM(hk.nhk), 0) AS '年度回款'
INTO #hk
FROM #p mp 
LEFT JOIN (
    SELECT 
        a.TopProjGUID AS Projguid,
        ISNULL(a.本月回笼金额认购, 0) + ISNULL(a.本月回笼金额签约, 0) + ISNULL(a.应退未退本月金额, 0) + ISNULL(a.关闭交易本月退款金额, 0)
        + ISNULL(a.本月特殊业绩关联房间, 0) + ISNULL(a.本月特殊业绩未关联房间, 0) AS yhk,
        ISNULL(a.本年回笼金额认购, 0) + ISNULL(a.本年回笼金额签约, 0) + ISNULL(a.应退未退本年金额, 0) + ISNULL(a.关闭交易本年退款金额, 0)
        + ISNULL(a.本年特殊业绩关联房间, 0) + ISNULL(a.本年特殊业绩未关联房间, 0) AS nhk
    FROM s_gsfkylbhzb a WITH (NOLOCK)
    INNER JOIN #p p ON a.TopProjGUID = p.ProjGUID
    WHERE DATEDIFF(DAY, a.qxDate, GETDATE()) = 0
) hk ON mp.projguid = hk.projguid
LEFT JOIN (
    SELECT 
        a.TopProjGUID AS Projguid,
        ISNULL(a.本月回笼金额认购, 0) + ISNULL(a.本月回笼金额签约, 0) + ISNULL(a.应退未退本月金额, 0) + ISNULL(a.关闭交易本月退款金额, 0)
        + ISNULL(a.本月特殊业绩关联房间, 0) + ISNULL(a.本月特殊业绩未关联房间, 0) AS yhk
    FROM s_gsfkylbhzb a WITH (NOLOCK)
    INNER JOIN #p p ON a.TopProjGUID = p.ProjGUID
    WHERE DATEDIFF(DAY, a.qxDate, GETDATE()) = 1
) zrhk ON mp.projguid = zrhk.projguid
GROUP BY 
    mp.buguid,
    CASE WHEN mp.是否公司层级 = '是' THEN '华南公司' ELSE mp.所属区域 END;

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_hk_BUGUID ON #hk(BUGUID);
CREATE NONCLUSTERED INDEX IX_hk_所属区域 ON #hk(所属区域);

-- 获取销净率，优化聚合计算
SELECT 
    p.buguid, 
    CASE WHEN p.是否公司层级 = '是' THEN '华南公司' ELSE p.所属区域 END AS 所属区域,
    SUM(本月认购金额) AS 本月认购金额,
    SUM(本月认购金额不含税) AS 本月认购金额不含税,
    SUM(本月净利润认购) AS 本月净利润认购,
    CASE 
        WHEN SUM(本月认购金额不含税) = 0 THEN 0 
        ELSE SUM(本月净利润认购) / SUM(本月认购金额不含税) 
    END AS 本月认购销净率,
    SUM(本年认购金额) AS 本年认购金额,
    SUM(本年认购金额不含税) AS 本年认购金额不含税,
    SUM(本年净利润认购) AS 本年净利润认购,
    CASE 
        WHEN SUM(本年认购金额不含税) = 0 THEN 0 
        ELSE SUM(本年净利润认购) / SUM(本年认购金额不含税) 
    END AS 本年认购销净率
INTO #jlr
FROM s_M002项目级毛利净利汇总表New t WITH (NOLOCK)
INNER JOIN #p p ON t.projguid = p.projguid
WHERE DATEDIFF(dd, qxdate, GETDATE()) = 0
AND 平台公司 = '华南公司'
GROUP BY 
    p.buguid,
    CASE WHEN p.是否公司层级 = '是' THEN '华南公司' ELSE p.所属区域 END;

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_jlr_BUGUID ON #jlr(BUGUID);
CREATE NONCLUSTERED INDEX IX_jlr_所属区域 ON #jlr(所属区域);

-- 获取销净率排名情况，使用窗口函数优化排名计算
WITH ProjectNetRateRanking AS (
    SELECT 
        CASE WHEN p.是否公司层级 = '是' THEN '华南公司' ELSE p.所属区域 END AS 所属区域,
        pj.SpreadName,
        t.projguid,
        STUFF((
            SELECT DISTINCT '/' + 产品类型 
            FROM s_M002项目级毛利净利汇总表New t1 WITH (NOLOCK)
            WHERE DATEDIFF(dd, qxdate, GETDATE()) = 0 
            AND t1.本日认购套数 <> 0 
            AND t1.产品类型 <> '地下室/车库'
            AND 本日认购金额不含税 > 0
            AND t1.projguid = t.projguid 
            FOR XML PATH('')
        ), 1, 1, '') AS 业态,
        SUM(本日认购金额) * 10000 AS 本日认购金额,
        CASE 
            WHEN SUM(本日认购金额不含税) = 0 THEN 0 
            ELSE SUM(本日净利润认购) / SUM(本日认购金额不含税) 
        END AS 销净率
    FROM s_M002项目级毛利净利汇总表New t WITH (NOLOCK)
    INNER JOIN mdm_project pj WITH (NOLOCK) ON t.ProjGUID = pj.ProjGUID
    INNER JOIN #p p ON t.projguid = p.projguid
    WHERE DATEDIFF(dd, qxdate, GETDATE()) = 0
    AND 本日认购套数 <> 0 
    AND t.产品类型 <> '地下室/车库'
    AND 本日认购金额不含税 > 0
    GROUP BY 
        CASE WHEN p.是否公司层级 = '是' THEN '华南公司' ELSE p.所属区域 END,
        pj.SpreadName,
        t.ProjGUID
)

SELECT 
    所属区域,
    SpreadName,
    projguid,
    业态,
    本日认购金额,
    销净率,
    ROW_NUMBER() OVER(ORDER BY 销净率 DESC) AS 排名_前,
    ROW_NUMBER() OVER(ORDER BY 销净率) AS 排名_后
INTO #jlr_rn
FROM ProjectNetRateRanking;

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_jlr_rn_所属区域 ON #jlr_rn(所属区域);
CREATE NONCLUSTERED INDEX IX_jlr_rn_排名_前 ON #jlr_rn(排名_前);
CREATE NONCLUSTERED INDEX IX_jlr_rn_排名_后 ON #jlr_rn(排名_后);

-- 优化典型项目去化信息的生成
SELECT 
    所属区域, 
    STUFF((
        SELECT CHAR(10) + '【' + t1.SpreadName + '】今日成交' + t1.业态 + 
               CONVERT(VARCHAR(10), CONVERT(DECIMAL(16, 2), 本日认购金额)) + '万,销净率' +
               CONVERT(VARCHAR(10), CONVERT(DECIMAL(16, 2), 销净率 * 100)) + '%'
        FROM #jlr_rn t1 
        WHERE (t1.排名_前 BETWEEN 1 AND 2 OR t1.排名_后 BETWEEN 1 AND 2)
        AND t1.所属区域 = t.所属区域
        ORDER BY t1.销净率 DESC
        FOR XML PATH('')
    ), 1, 1, '') AS 典型项目去化
INTO #jlr_result
FROM #jlr_rn t
WHERE 排名_前 BETWEEN 1 AND 2 OR 排名_后 BETWEEN 1 AND 2
GROUP BY 所属区域;

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_jlr_result_所属区域 ON #jlr_result(所属区域);

-- 获取汇总数据，优化JOIN操作
SELECT 
    c.BUGUID,
    c.所属区域,
    t.本日认购 AS '本日认购',
    t.认购未签约 / 10000 AS '认购未签约',
    t.本日签约 AS '本日签约',
    t.月度认购 / 10000 AS '月度认购',
    t.年度认购 / 10000 AS '年度认购', 
    t.本年存量项目认购金额 / 10000 AS 本年存量项目认购金额,
    t.本年增量项目认购金额 / 10000 AS 本年增量项目认购金额,
    t.本年新增量项目认购金额 / 10000 AS 本年新增量项目认购金额,
    t.佛山本年认购金额 / 10000 AS 佛山本年认购金额, 
    y.月度签约任务 AS '月签约任务',
    y.月度回笼任务,
    y.月度开工任务,
    y.月度销净率任务,
    t.月度签约 / 10000 AS '月度签约',
    t.年度签约 / 10000 AS '年度签约',
    t.本日新开工 AS 本日新开工,
    t.本月新开工 / 10000 AS 本月新开工,
    t.本年新开工 / 10000 AS 本年新开工,
    -- 回款
    hk.本日回款 AS 本日回笼,
    hk.月度回款 / 10000 AS 月度回笼,
    hk.年度回款 / 10000 AS 年度回笼,
    jlr.本月认购销净率,
    jlr.本年认购销净率
INTO #hz
FROM (
    SELECT DISTINCT 
        buguid,
        CASE WHEN 是否公司层级 = '是' THEN '华南公司' ELSE 所属区域 END AS 所属区域 
    FROM #p
) c
LEFT JOIN #yd y ON y.BUGUID = c.BUGUID AND c.所属区域 = y.所属区域
LEFT JOIN #hk hk ON hk.buguid = c.buguid AND c.所属区域 = hk.所属区域
LEFT JOIN (
    SELECT 
        a.BUGUID,
        a.所属区域,
        a.本日认购 AS 本日认购,
        a.认购未签约 AS 认购未签约,
        a.本日签约 AS 本日签约,
        a.月度认购 + ISNULL(b.月度认购, 0) + ISNULL(t.ByJE, 0) AS 月度认购,
        a.年度认购 + ISNULL(b.年度认购, 0) + ISNULL(t.BNJE, 0) AS 年度认购, 
        a.月度签约 + ISNULL(b.月度签约, 0) + ISNULL(t.ByJE, 0) AS 月度签约,
        a.年度签约 + ISNULL(b.年度签约, 0) + ISNULL(t.BNJE, 0) AS 年度签约,
        a.本年存量项目认购金额 + ISNULL(b.本年存量项目认购金额, 0) + ISNULL(t.本年存量项目认购金额, 0) AS 本年存量项目认购金额,
        a.本年增量项目认购金额 + ISNULL(b.本年增量项目认购金额, 0) + ISNULL(t.本年增量项目认购金额, 0) AS 本年增量项目认购金额,
        a.本年新增量项目认购金额 + ISNULL(b.本年新增量项目认购金额, 0) + ISNULL(t.本年新增量项目认购金额, 0) AS 本年新增量项目认购金额,
        a.佛山本年认购金额 + ISNULL(b.佛山本年认购金额, 0) + ISNULL(t.佛山本年认购金额, 0) AS 佛山本年认购金额, 
        ISNULL(ccpqy.本日新开工, 0) AS 本日新开工,
        ISNULL(ccpqy.本月新开工, 0) AS 本月新开工,
        ISNULL(ccpqy.本年新开工, 0) AS 本年新开工
    FROM #t a
    LEFT JOIN #t1 b ON b.BUGuid = a.BUGUID AND a.所属区域 = b.所属区域
    LEFT JOIN #ts t ON a.BUGUID = t.BUGUID AND a.所属区域 = t.所属区域
    LEFT JOIN #ccpqy ccpqy ON a.BUGUID = ccpqy.BUGUID AND a.所属区域 = ccpqy.所属区域
) t ON c.BUGUID = t.BUGUID AND c.所属区域 = t.所属区域
LEFT JOIN #jlr jlr ON jlr.buguid = c.buguid AND jlr.所属区域 = c.所属区域;

-- 创建索引提高性能
CREATE NONCLUSTERED INDEX IX_hz_BUGUID ON #hz(BUGUID);
CREATE NONCLUSTERED INDEX IX_hz_所属区域 ON #hz(所属区域);

-- 最终结果输出，优化CASE表达式
SELECT 
    a.BUGUID,
    a.所属区域,
    CONVERT(CHAR(4), YEAR(GETDATE())) AS 年,
    MONTH(GETDATE()) AS 月,
    DAY(GETDATE()) AS 日,
    -- 任务指标
    a.月签约任务,
    a.月度回笼任务,
    a.月度开工任务,
    CONVERT(VARCHAR(10), CONVERT(DECIMAL(16, 2), ISNULL(a.月度销净率任务 * 100, 0))) + '%' AS 月度销净率任务,
    a.本日认购,
    a.月度认购,
    CASE WHEN a.所属区域 = '三肇事业部' THEN a.年度认购 - 1.37 ELSE a.年度认购 END AS 年度认购,
    a.本日签约,
    a.月度签约,
    CASE WHEN a.所属区域 = '三肇事业部' THEN a.年度签约 - 1.37 ELSE a.年度签约 END AS 年度签约,
    a.本日回笼,
    a.月度回笼,
    a.年度回笼,
    a.本日新开工,
    a.本月新开工,
    a.本年新开工,
    CONVERT(VARCHAR(10), CONVERT(DECIMAL(16, 2), ISNULL(a.本月认购销净率 * 100, 0))) + '%' AS 本月认购销净率,
    CONVERT(VARCHAR(10), CONVERT(DECIMAL(16, 2), ISNULL(a.本年认购销净率 * 100, 0))) + '%' AS 本年认购销净率,
    a.本年存量项目认购金额,
    a.本年增量项目认购金额,
    a.本年新增量项目认购金额,
    a.佛山本年认购金额,
    CONVERT(VARCHAR(10), CASE WHEN a.年度认购 = 0 THEN 0 ELSE a.佛山本年认购金额 / a.年度认购 * 100 END) + '%' AS 佛山本年认购占比,
    CASE WHEN t.典型项目去化 IS NULL THEN '无' ELSE t.典型项目去化 END AS 典型项目去化
FROM #hz a
LEFT JOIN #jlr_result t ON a.所属区域 = t.所属区域;

-- 清理临时表
DROP TABLE  #p, #ccpqy, #con, #hk, #hz, #jlr, #order, #room, #t, #t1, #ts, #yd, #so, #sc, #r, #sroom, #jlr_rn, #jlr_result;

-- 设置NOCOUNT关闭
SET NOCOUNT OFF;