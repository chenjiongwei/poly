-- XS08房源历次调价表
-- 功能：查询房源的历次调价信息，包括调价方案、调价金额、审批流程等
-- 作者：未知
-- 修改日期：未知

USE erp25
GO

CREATE OR ALTER PROC usp_dss_XS08房源历次调价表_qx
AS 
BEGIN 
    -- 创建临时表存储房间信息
    SELECT roomguid,
           bldguid
    INTO #room
    FROM ep_room WITH(NOLOCK)
    WHERE 1=1 
    -- 注释掉的条件可用于按公司筛选
    -- BUGUID IN (
    --     SELECT buguid FROM mybusinessunit a
    --     LEFT JOIN p_DevelopmentCompany b ON a.BUName = b.DevelopmentCompanyName 
    --     WHERE b.DevelopmentCompanyGUID IN (@buname)
    -- );

    -- 获取房源的调价记录，按调价日期排序
    SELECT a.roomguid,
           a.hltotal,      -- 货量总价
           a.hszj,         -- 回收总价
           a.ChangeReason, -- 调价原因
           b.planname,     -- 调价方案名称
           ROW_NUMBER() OVER (PARTITION BY a.roomguid ORDER BY a.tjdate) rownum
    INTO #tj
    FROM s_PriceChg a WITH(NOLOCK)
        LEFT JOIN s_TjPlan b WITH(NOLOCK) ON a.planguid = b.planguid
        INNER JOIN #room r ON a.roomguid = r.roomguid;

    -- 获取最后一次调价记录（按调价日期降序）
    SELECT *
    INTO #tj1
    FROM
    (
        SELECT t.roomguid,
               t.hltotal,      -- 货量总价
               t.hszj,         -- 回收总价
               t.PlanGUID,     -- 调价方案GUID
               b.planname,     -- 调价方案名称
               b.zddate,       -- 调价方案制定时间
               c.ChangeReason, -- 调价原因
               ROW_NUMBER() OVER (PARTITION BY t.roomguid ORDER BY b.zddate DESC) rownum
        FROM s_TjResult t WITH(NOLOCK)
            LEFT JOIN s_TjPlan b WITH(NOLOCK) ON t.PlanGUID = b.PlanGUID
            INNER JOIN #room r ON t.roomguid = r.roomguid
            LEFT JOIN s_PriceChg c WITH(NOLOCK) ON b.PlanGUID = c.PlanGUID AND c.roomguid = r.roomguid
        -- 筛选有价格变动的记录
        WHERE t.Price <> t.OriginalPrice
           OR t.TnPrice <> t.OriginalTnPrice
           OR t.Total <> t.OriginalToTal
           OR t.JZHSDJ <> t.JZHSDJ_Old
           OR t.TNHSDJ <> t.TNHSDJ_Old
           OR t.HSZJ <> t.HSZJ_Old
           OR t.JzDj <> t.JzDj_old
           OR t.TnDJ <> t.TnDJ_old
           OR t.DjTotal <> t.DjTotal_old
           OR t.ZxToTal <> t.OriginalZxToTal
           OR t.ZxBagAmount_Old <> t.ZxBagAmount
    ) a
    WHERE rownum = 1;

    -- 获取未在#tj1中的房源的第一次调价记录
    SELECT *
    INTO #tj2
    FROM
    (
        SELECT t.roomguid,
               t.hltotal,      -- 货量总价
               t.hszj,         -- 回收总价
               t.PlanGUID,     -- 调价方案GUID
               b.planname,     -- 调价方案名称
               b.zddate,       -- 调价方案制定时间
               c.ChangeReason, -- 调价原因
               ROW_NUMBER() OVER (PARTITION BY t.roomguid ORDER BY b.zddate) rownum
        FROM s_TjResult t WITH(NOLOCK)
            LEFT JOIN s_TjPlan b WITH(NOLOCK) ON t.PlanGUID = b.PlanGUID
            INNER JOIN #room r ON t.roomguid = r.roomguid
            LEFT JOIN s_PriceChg c WITH(NOLOCK) ON b.PlanGUID = c.PlanGUID AND c.roomguid = r.roomguid
        WHERE r.roomguid NOT IN (
            SELECT roomguid FROM #tj1
        )
    ) a
    WHERE rownum = 1;

    -- 合并两个调价结果表
    SELECT *
    INTO #tjresult
    FROM #tj1
    UNION
    SELECT *
    FROM #tj2;

    -- 获取调价审批流程信息
    SELECT ROW_NUMBER() OVER (PARTITION BY n.ProcessGUID,
                                          a.roomguid
                              ORDER BY n.HandleDatetime DESC
                             ) row,
           w.processname,      -- 流程名称
           a.*,                -- 调价信息
           n.*                 -- 节点信息
    INTO #sp
    FROM #tjresult a
        LEFT JOIN s_TjPlan t WITH(NOLOCK) ON a.PlanGUID = t.PlanGUID
        LEFT JOIN dbo.myWorkflowProcessEntity w WITH(NOLOCK) ON a.PlanGUID = w.BusinessGUID
                                                    AND w.ProcessStatus = '2'
        LEFT JOIN myWorkflowNodeEntity n WITH(NOLOCK) ON w.ProcessGUID = n.ProcessGUID
        LEFT JOIN myWorkflowStepPathEntity b WITH(NOLOCK) ON b.StepGUID = n.StepGUID
    WHERE b.StepName <> '归档'
      AND b.StepName <> '系统归档'
      AND b.StepName <> '自动归档';
    
    TRUNCATE table XS08房源历次调价表_qx;

    insert into  XS08房源历次调价表_qx
    -- 最终查询结果：房源历次调价信息
    SELECT er.roomguid,
           bu.buname AS '公司',
           p.projname AS '项目',
           --er.bldfullname AS '楼栋',
           er.roominfo AS '房间',
           er.status AS '房间状态',
           er.bldarea AS '房间面积',
           ISNULL(ISNULL(o1.qsdate, c.qsdate), o.qsdate) AS '认购时间',
           c.qsdate AS '签约时间',
           ISNULL(c.jytotal, o.jytotal) AS '成交总价',
           ISNULL(c.DiscntValue, o.DiscntValue) AS '成交折扣',
           ISNULL(c.DiscntRemark, o.DiscntRemark) AS '折扣说明',
           -- 合并客户信息
           ISNULL(
               CASE
                   WHEN CstName2.CstName IS NULL THEN
                       CstName1.CstName
                   WHEN CstName3.CstName IS NULL THEN
                       CstName1.CstName + ';' + CstName2.CstName
                   WHEN CstName4.CstName IS NULL THEN
                       CstName1.CstName + ';' + CstName2.CstName + ';' + CstName3.CstName
                   ELSE CstName1.CstName + ';' + CstName2.CstName + ';' + CstName3.CstName + ';' + CstName4.CstName
               END,
               CASE
                   WHEN CstName21.CstName IS NULL THEN
                       CstName11.CstName
                   WHEN CstName31.CstName IS NULL THEN
                       CstName11.CstName + ';' + CstName21.CstName
                   WHEN CstName41.CstName IS NULL THEN
                       CstName11.CstName + ';' + CstName21.CstName + ';' + CstName31.CstName
                   ELSE CstName11.CstName + ';' + CstName21.CstName + ';' + CstName31.CstName + ';'
                       + CstName41.CstName
               END
           ) AS '客户',
           '' AS '是否关闭此交易单',
           '' AS '关闭时间',
           tj.ChangeReason AS '价格调整原因',
           tj.zddate AS '调价方案制定时间',
           tj.planname AS '调价方案名称',
           tj.hltotal AS '最后一次调价货量总价',
           tj.hszj AS '最后一次调价回收总价',
           sp.processname AS '最后一次调价流程名称',
           sp.AuditorName AS '最后一次调价审批人',
           -- 第1-10次调价信息
           tj1.hltotal AS '第1次调价现房间总货量',
           tj1.hszj AS '第1次调价现房间回收价',
           tj1.ChangeReason AS '第1次调价类别',
           tj1.planname AS '第1次调价方案名称',
           tj2.hltotal AS '第2次调价现房间总货量',
           tj2.hszj AS '第2次调价现房间回收价',
           tj2.ChangeReason AS '第2次调价类别',
           tj2.planname AS '第2次调价方案名称',
           tj3.hltotal AS '第3次调价现房间总货量',
           tj3.hszj AS '第3次调价现房间回收价',
           tj3.ChangeReason AS '第3次调价类别',
           tj3.planname AS '第3次调价方案名称',
           tj4.hltotal AS '第4次调价现房间总货量',
           tj4.hszj AS '第4次调价现房间回收价',
           tj4.ChangeReason AS '第4次调价类别',
           tj4.planname AS '第4次调价方案名称',
           tj5.hltotal AS '第5次调价现房间总货量',
           tj5.hszj AS '第5次调价现房间回收价',
           tj5.ChangeReason AS '第5次调价类别',
           tj5.planname AS '第5次调价方案名称',
           tj6.hltotal AS '第6次调价现房间总货量',
           tj6.hszj AS '第6次调价现房间回收价',
           tj6.ChangeReason AS '第6次调价类别',
           tj6.planname AS '第6次调价方案名称',
           tj7.hltotal AS '第7次调价现房间总货量',
           tj7.hszj AS '第7次调价现房间回收价',
           tj7.ChangeReason AS '第7次调价类别',
           tj7.planname AS '第7次调价方案名称',
           tj8.hltotal AS '第8次调价现房间总货量',
           tj8.hszj AS '第8次调价现房间回收价',
           tj8.ChangeReason AS '第8次调价类别',
           tj8.planname AS '第8次调价方案名称',
           tj9.hltotal AS '第9次调价现房间总货量',
           tj9.hszj AS '第9次调价现房间回收价',
           tj9.ChangeReason AS '第9次调价类别',
           tj9.planname AS '第9次调价方案名称',
           tj10.hltotal AS '第10次调价现房间总货量',
           tj10.hszj AS '第10次调价现房间回收价',
           tj10.ChangeReason AS '第10次调价类别',
           tj10.planname AS '第10次调价方案名称'
    -- into XS08房源历次调价表_qx
    FROM ep_room er WITH(NOLOCK)
        LEFT JOIN #tjresult tj ON er.roomguid = tj.roomguid
        LEFT JOIN #sp sp ON er.roomguid = sp.roomguid
                          AND sp.row = 1
        LEFT JOIN p_project p WITH(NOLOCK) ON er.projguid = p.projguid
        LEFT JOIN mybusinessunit bu WITH(NOLOCK) ON er.buguid = bu.buguid
        LEFT JOIN s_order o WITH(NOLOCK) ON er.roomguid = o.roomguid
                                AND o.status = '激活'
        LEFT JOIN s_trade2cst Cst1 WITH(NOLOCK) ON o.TradeGUID = Cst1.TradeGUID
                                    AND Cst1.CstNum = 1
        LEFT JOIN p_Customer CstName1 WITH(NOLOCK) ON Cst1.CstGUID = CstName1.CstGUID
        LEFT JOIN s_trade2cst Cst2 WITH(NOLOCK) ON o.TradeGUID = Cst2.TradeGUID
                                    AND Cst2.CstNum = 2
        LEFT JOIN p_Customer CstName2 WITH(NOLOCK) ON Cst2.CstGUID = CstName2.CstGUID
        LEFT JOIN s_trade2cst Cst3 WITH(NOLOCK) ON o.TradeGUID = Cst3.TradeGUID
                                    AND Cst3.CstNum = 3
        LEFT JOIN p_Customer CstName3 WITH(NOLOCK) ON Cst3.CstGUID = CstName3.CstGUID
        LEFT JOIN s_trade2cst Cst4 WITH(NOLOCK) ON o.TradeGUID = Cst4.TradeGUID
                                    AND Cst4.CstNum = 4
        LEFT JOIN p_Customer CstName4 WITH(NOLOCK) ON Cst4.CstGUID = CstName4.CstGUID
        LEFT JOIN s_contract c WITH(NOLOCK) ON er.roomguid = c.roomguid
                                AND c.status = '激活'
        LEFT JOIN s_trade2cst Cst11 WITH(NOLOCK) ON c.TradeGUID = Cst11.TradeGUID
                                        AND Cst11.CstNum = 1
        LEFT JOIN p_Customer CstName11 WITH(NOLOCK) ON Cst11.CstGUID = CstName11.CstGUID
        LEFT JOIN s_trade2cst Cst21 WITH(NOLOCK) ON c.TradeGUID = Cst21.TradeGUID
                                        AND Cst21.CstNum = 2
        LEFT JOIN p_Customer CstName21 WITH(NOLOCK) ON Cst21.CstGUID = CstName21.CstGUID
        LEFT JOIN s_trade2cst Cst31 WITH(NOLOCK) ON c.TradeGUID = Cst31.TradeGUID
                                        AND Cst31.CstNum = 3
        LEFT JOIN p_Customer CstName31 WITH(NOLOCK) ON Cst31.CstGUID = CstName31.CstGUID
        LEFT JOIN s_trade2cst Cst41 WITH(NOLOCK) ON c.TradeGUID = Cst41.TradeGUID
                                        AND Cst41.CstNum = 4
        LEFT JOIN p_Customer CstName41 WITH(NOLOCK) ON Cst41.CstGUID = CstName41.CstGUID
        LEFT JOIN s_order o1 WITH(NOLOCK) ON c.lastsaleguid = o1.orderguid
                                AND o1.closereason = '转签约'
        -- 关联各次调价信息
        LEFT JOIN #tj tj1 ON er.roomguid = tj1.roomguid
                          AND tj1.rownum = 1
        LEFT JOIN #tj tj2 ON er.roomguid = tj2.roomguid
                          AND tj2.rownum = 2
        LEFT JOIN #tj tj3 ON er.roomguid = tj3.roomguid
                          AND tj3.rownum = 3
        LEFT JOIN #tj tj4 ON er.roomguid = tj4.roomguid
                          AND tj4.rownum = 4
        LEFT JOIN #tj tj5 ON er.roomguid = tj5.roomguid
                          AND tj5.rownum = 5
        LEFT JOIN #tj tj6 ON er.roomguid = tj6.roomguid
                          AND tj6.rownum = 6
        LEFT JOIN #tj tj7 ON er.roomguid = tj7.roomguid
                          AND tj7.rownum = 7
        LEFT JOIN #tj tj8 ON er.roomguid = tj8.roomguid
                          AND tj8.rownum = 8
        LEFT JOIN #tj tj9 ON er.roomguid = tj9.roomguid
                          AND tj9.rownum = 9
        LEFT JOIN #tj tj10 ON er.roomguid = tj10.roomguid
                           AND tj10.rownum = 10
    WHERE 1=1 
        -- 注释掉的条件可用于按公司筛选
        -- AND er.BUGUID IN (
        --     SELECT buguid FROM mybusinessunit a
        --     LEFT JOIN p_DevelopmentCompany b ON a.BUName = b.DevelopmentCompanyName 
        --     WHERE b.DevelopmentCompanyGUID IN (@buname)
        -- )
        AND tj.zddate >= '2022-01-01' AND tj.zddate <= '2024-12-31'    -- 筛选调价时间范围
    ORDER BY er.roominfo;

    -- 清理临时表
    DROP TABLE #room,
              #sp,
              #tj,
              #tj1,
              #tj2,
              #tjresult;

    /*
        -- 以下是注释掉的备选查询逻辑
        SELECT t.roomguid,
            t.hltotal,
            t.PlanGUID,
            b.planname,
            b.zddate,
            ROW_NUMBER() OVER (PARTITION BY t.roomguid ORDER BY b.zddate ) rownum
            INTO #tj1
        FROM s_TjResult t
            LEFT JOIN s_TjPlan b ON t.PlanGUID = b.PlanGUID
            INNER JOIN #room r ON t.roomguid = er.roomguid
        WHERE t.Price <> t.OriginalPrice
            OR t.TnPrice <> t.OriginalTnPrice
            OR t.Total <> t.OriginalToTal
            OR t.JZHSDJ <> t.JZHSDJ_Old
            OR t.TNHSDJ <> t.TNHSDJ_Old
            OR t.HSZJ <> t.HSZJ_Old
            OR t.JzDj <> t.JzDj_old
            OR t.TnDJ <> t.TnDJ_old
            OR t.DjTotal <> t.DjTotal_old
            OR t.ZxToTal <> t.OriginalZxToTal
            OR t.ZxBagAmount_Old <> t.ZxBagAmount
    

    
        SELECT t.roomguid,
            t.hltotal,
            t.PlanGUID,
            b.planname,
            b.zddate,
            ROW_NUMBER() OVER (PARTITION BY t.roomguid ORDER BY b.zddate) rownum
            INTO #tj2
        FROM s_TjResult t
            LEFT JOIN s_TjPlan b ON t.PlanGUID = b.PlanGUID
            INNER JOIN #room r ON t.roomguid = er.roomguid
        WHERE er.roomguid NOT IN (
                                    SELECT roomguid FROM #tj1
                                )
    


    SELECT *
    INTO #tj
    FROM #tj1
    UNION
    SELECT *
    FROM #tj2;


    


    SELECT er.roomguid,
        er.bldfullname 楼栋,
        er.roominfo 房间,
        er.status 房间状态,
        er.bldarea 房间面积,
        tj1.hltotal  '第1次调价现房间总货量',
        tj2.hltotal  '第2次调价现房间总货量',
        tj3.hltotal  '第3次调价现房间总货量',
        tj4.hltotal  '第4次调价现房间总货量',
        tj5.hltotal  '第5次调价现房间总货量',
        tj6.hltotal  '第6次调价现房间总货量',
        tj7.hltotal  '第7次调价现房间总货量',
        tj8.hltotal  '第8次调价现房间总货量',
        tj9.hltotal  '第9次调价现房间总货量'
    FROM #room r
    LEFT JOIN ep_room er ON er.roomguid=eer.roomguid
        LEFT JOIN #tj tj1 ON er.roomguid = tj1.roomguid AND tj1.rownum=1
        LEFT JOIN #tj tj2 ON er.roomguid = tj2.roomguid AND tj2.rownum=2
        LEFT JOIN #tj tj3 ON er.roomguid = tj3.roomguid AND tj3.rownum=3
        LEFT JOIN #tj tj4 ON er.roomguid = tj4.roomguid AND tj4.rownum=4
        LEFT JOIN #tj tj5 ON er.roomguid = tj5.roomguid AND tj5.rownum=5
        LEFT JOIN #tj tj6 ON er.roomguid = tj6.roomguid AND tj6.rownum=6
        LEFT JOIN #tj tj7 ON er.roomguid = tj7.roomguid AND tj7.rownum=7
        LEFT JOIN #tj tj8 ON er.roomguid = tj8.roomguid AND tj8.rownum=8
        LEFT JOIN #tj tj9 ON er.roomguid = tj9.roomguid AND tj9.rownum=9
        
    ORDER BY er.roominfo;


    DROP TABLE #room,
            
            #tj,
            #tj1,
            #tj2;

            */
END 