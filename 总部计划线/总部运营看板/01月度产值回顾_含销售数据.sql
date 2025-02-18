-- -- 楼栋产值
--         SELECT ISNULL(a.Xmpdljwccz, 0) AS 已完成产值, 
--         ISNULL(a.Ljyfkje, 0) AS 合同约定应付金额,
--         ISNULL(a.Ljsfk, 0) AS 累计支付金额,
--         0 - ISNULL(a.Ljsfk, 0) AS 产值未付,
--         ISNULL(a.Ljyfkje, 0) - ISNULL(a.Ljsfk, 0) AS 应付未付,
--         a.BldGUID
--         into #ldcz
--         FROM (
--             SELECT   
--                     SUM(ISNULL(b.Xmpdljwccz, 0)) AS Xmpdljwccz, 
--                     SUM(ISNULL(b.Ljyfkje, 0)) AS Ljyfkje,
--                     SUM(ISNULL(b.Ljsfk, 0)) AS Ljsfk,
--                     BldGUID
--             FROM mycost_erp352.dbo.cb_OutputValueReviewDetail a with(nolock) 
--                 INNER JOIN mycost_erp352.dbo.cb_OutputValueReviewBld b with(nolock) ON b.OutputValueReviewDetailGUID = a.OutputValueReviewDetailGUID
--                                 inner join #ms ms with(nolock) on ms.SaleBldGUID = b.BldGUID
--             WHERE (1=1)
--                 AND (2=2)
--             GROUP BY b.BldGUID
--         ) a   

-- --项目产值
--  --获取产值月度回顾情况
--         --获取项目已审核的最晚回顾时间记录
--         select * 
--         into #OutputValuebb
--         from (
--         select projguid,ROW_NUMBER() over(PARTITION BY projguid order by ReviewDate desc) as RowNum,OutputValueMonthReviewGUID 
--         from MyCost_Erp352.dbo.cb_OutputValueMonthReview where ApproveState = '已审核') t where t.RowNum = 1

--         SELECT  pp.projguid, 
--                 sum(ydhg.TotalOutputValue)/10000.0 as 已完成产值金额, 
--                 sum(ydhg.LjyfkAmount)/10000.0 AS 合同约定应付金额,
--                 sum(ydhg.LjsfAmount)/10000.0 as 累计支付金额, 
--                 sum(ydhg.YfwfAmount)/10000.0 as 应付未付 
--         into #OutputValue
--         FROM    MyCost_Erp352.dbo.cb_OutputValueMonthReview ydhg
--                 inner join #OutputValuebb bb on ydhg.OutputValueMonthReviewGUID = bb.OutputValueMonthReviewGUID
--                 inner join erp25.dbo.mdm_Project p on p.ProjGUID = bb.ProjGUID
--                 inner join #p pp on p.ParentProjGUID = pp.ProjGUID
--         group by pp.projguid


-- 01 月度产值回归-含销售数据 报表
-- 1. 创建索引建议
/*
建议在以下表和字段上创建索引:
- cb_OutputValueMonthReview: (projguid, ApproveState)
- md_Project: (ProjGUID, ApproveState, CreateDate)
- p_lddbamj: (GCBldGUID, QXDate)
- jd_PlanTaskExecuteObjectForReport: (projguid)
*/

-- 2. 优化主查询
WITH ProjectBase AS (
    -- 获取最新基础数据系统已审核项目信息
    SELECT p.*
    FROM (
        SELECT ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) AS rowmo,
               *
        FROM dbo.md_Project
        WHERE ApproveState = '已审核'
            AND ISNULL(CreateReason, '') <> '补录'
    ) p
    WHERE p.rowmo = 1
),
SalesInfo AS (
    -- 预先计算销售信息,避免重复计算
    SELECT gc.ProjGUID,
           SUM(ISNULL(ysmj, 0)) AS ysmj,
           SUM(ISNULL(zhz,0)) AS zhz,
           SUM(CASE 
               WHEN DATEDIFF(day,ISNULL(ld.Realysxx_th,'2099-12-31'),GETDATE())>=0 
               THEN ISNULL(ld.syhz,0) 
               ELSE 0 
           END) AS dysxxhz,
           SUM(ISNULL(ysje,0)) AS ysje,
           SUM(ISNULL(syhz,0)) AS syhz
    FROM erp25.dbo.p_lddbamj ld WITH(NOLOCK)
    INNER JOIN erp25.dbo.mdm_GCBuild gc WITH(NOLOCK)
        ON gc.GCBldGUID = ld.GCBldGUID
    WHERE DATEDIFF(day, QXDate, GETDATE()) = 0
    GROUP BY gc.ProjGUID
),
StopWorkInfo AS (
    -- 预先计算停工缓建信息
    SELECT d.projguid, 
           COUNT(1) AS tghjNum
    FROM jd_StopOrReturnWork tg WITH(NOLOCK)
    LEFT JOIN jd_ProjectPlanTaskExecute f WITH(NOLOCK)
        ON f.PlanID = tg.PlanID 
        AND f.Level = 1
    LEFT JOIN jd_ProjectPlanExecute d WITH(NOLOCK)
        ON d.ID = f.PlanID 
        AND d.PlanType = 103
    WHERE tg.ApplyState = '已审核' 
        AND tg.type IN ('停工','缓建')
    GROUP BY d.projguid
),
ProgressInfo AS (
    -- 预先计算进度信息
    SELECT por.projguid,
           SUM(CASE 
               WHEN 实际开工实际完成时间 IS NOT NULL 
               THEN ISNULL(计划组团建筑面积, 0) 
               ELSE 0 
           END) AS 累计开工面积,
           SUM(CASE 
               WHEN ISNULL(是否停工, '') <> '正常' 
                   AND 实际开工实际完成时间 IS NOT NULL     
               THEN ISNULL(计划组团建筑面积, 0) 
               ELSE 0 
           END) AS 当前停工面积
    FROM jd_PlanTaskExecuteObjectForReport por WITH(NOLOCK)
    GROUP BY por.projguid
)

-- 主查询
SELECT  bu.buname AS '公司名称',                                                      -- 合同的归属公司
        p.projname AS '所属项目',                                                    -- 合同的所属项目
        mp.ProjStatus AS '项目状态',
        mp.ConstructStatus AS '工程状态',
        CASE 
            WHEN ISNULL(cyj.tghjNum,0) > 0 THEN '是' 
            ELSE '否' 
        END AS '是否存在停工缓建',
        flg.工程操盘方 AS '工程操盘方',
        flg.成本操盘方 AS '成本操盘方',
        flg.项目代码 AS '明源系统代码',
        flg.投管代码 AS '投管代码',
        CONVERT(VARCHAR(7),ovr.ReviewDate,121) AS '月度回顾月份',
        CASE 
            WHEN ISNULL(proj.SumBuildArea,0) = 0 THEN 0 
            ELSE ISNULL(jd.累计开工面积,0) / ISNULL(proj.SumBuildArea,0) 
        END AS '累计开工比例',                                                      -- 已开工面积/总建筑面积
        CASE 
            WHEN ISNULL(proj.SumSaleArea, 0) = 0 THEN 0  
            ELSE ISNULL(ys.ysmj,0) / ISNULL(proj.SumSaleArea, 0) 
        END AS '累计销售比例',                                                      -- 已售面积/总可售面积
        proj.SumBuildArea AS '产值信息_总建筑面积',                                  -- 基础数据系统最新版的建筑面积之和
        jd.累计开工面积 AS '产值信息_已开工面积',                                     -- 楼栋计划"实际开工"节点的实际完成日期不为空的建筑面积之和
        jd.当前停工面积 AS '产值信息_停工缓建面积',                                   -- 组团楼栋状态为停工，"实际开工日期"不为空的组团的建筑面积之和
        ovr.TotalOutputValue AS '产值信息_总产值',                                  -- 汇总各楼栋总产值
        ovr.YfsOutputValue AS '产值信息_已发生产值',                                -- 汇总各楼栋项目盘点累计已完成产值
        ISNULL(ovr.TotalOutputValue,0) - ISNULL(ovr.YfsOutputValue,0) AS '产值信息_待发生产值',  --总产值-待发生产值
        
        -- 销售信息
        ISNULL(proj.SumSaleArea, 0) AS '销售信息_总可售面积',                                              -- 基础数据系统最新版的可售面积之和
        ys.ysmj AS '销售信息_已售面积',                                                -- 销售管理系统中分期的已售房源面积之和
        ISNULL(proj.SumSaleArea, 0) - ISNULL(ys.ysmj,0) AS '销售信息_待售面积',                                                -- 总可售面积-已售面积
        ys.zhz AS '销售信息_总货值',
        ovr.Ydysxxhz * 10000.0 AS '销售信息_已达预售形象货值',
        ys.ysje AS '销售信息_已售货值',
        ys.syhz AS '销售信息_待售货值',
        
        -- 付款信息
        ovr.LjyfAmount AS '付款信息_累计应付款',                                    --汇总当前项目分期下合同累计应付款
        ovr.LjsfAmount AS '付款信息_累计实付款',                                    -- 汇总当前项目分期下合同累计实付款
        ovr.BnljsfAmount AS '付款信息_本年累计实付款',                             -- 取当前分期下面，实付开票日期为当前年的实付金额
        ovr.YdczwfAmount AS '付款信息_已达产值未付金额',
        ovr.YfwfAmount AS '付款信息_应付未付金额',
        ovr.XyyfzfAmount AS '付款信息_下月预估支付金额',
        ovr.Ndzjjh AS '付款信息_年度资金计划',
        ISNULL(ovr.Ndzjjh,0) - ISNULL(ovr.BnljsfAmount,0) AS '付款信息_本年预估剩余支付金额',  --年度资金计划-本年累计实付款

        -- 楼栋产值盘点
        ld.BldName AS '楼栋产值盘点_楼栋名称',
        ld.Jszt AS '楼栋产值盘点_建设状态',
        ld.ldzhz AS '楼栋产值盘点_总货值',
        ld.ldysje AS '楼栋产值盘点_已售货值',
        ld.ldsyhz AS '楼栋产值盘点_待售货值',

        ld.BldArea AS '楼栋产值盘点_建筑面积',
        ld.ldysmj AS '楼栋产值盘点_已售面积',
        ld.ldkgmj AS '楼栋产值盘点_开工面积',
        ld.Zcz AS '楼栋产值盘点_总产值',
        ld.Xmpdljwccz AS '楼栋产值盘点_项目盘点累计已完成产值',
        ld.Dfscz AS '楼栋产值盘点_待发生产值',
        ld.Ljyfkje AS '楼栋产值盘点_累计应付金额',
        ld.Ljsfk AS '楼栋产值盘点_累计实付金额',
        ld.Ydczwzfje AS '楼栋产值盘点_已达产值未付金额',
        ld.Yfwfje AS '楼栋产值盘点_应付未付金额'
FROM    p_project p WITH(NOLOCK)
        INNER JOIN mybusinessunit bu WITH(NOLOCK)
            ON p.buguid = bu.buguid
        INNER JOIN ProjectBase proj 
            ON proj.ProjGUID = p.ProjGUID
        LEFT JOIN SalesInfo ys
            ON ys.ProjGUID = p.ProjGUID
        INNER JOIN ERP25.dbo.mdm_project mp WITH(NOLOCK)
            ON mp.projguid = p.ProjGUID
        LEFT JOIN erp25.dbo.vmdm_projectFlag flg 
            ON flg.projguid = mp.ParentProjGUID
        LEFT JOIN StopWorkInfo cyj
            ON cyj.projguid = p.projguid
        LEFT JOIN ProgressInfo jd
            ON jd.projguid = mp.ProjGUID
        INNER JOIN cb_OutputValueMonthReview ovr 
            ON ovr.projguid = p.projguid
        LEFT JOIN (
            SELECT b.OutputValueMonthReviewGUID,
                   b.BldGUID,
                   b.BldName,
                   b.BldArea,
                   b.Jszt, -- 建设状态
                   ISNULL(b.HtAmount, 0) + ISNULL(b.HtylAmount, 0) AS Zcz,
                   lddb.ldysmj,  -- 楼栋已售面积
                   lddb.ldzhz, -- 楼栋总货值
                   lddb.ldysje, -- 楼栋已售货值
                   lddb.ldsyhz, -- 楼栋待售货值
                   ldkg.ldkgmj, -- 楼栋开工面积
                   b.Xmpdljwccz, -- 项目盘点累计已完成产值
                   b.Dfscz, -- 待发生产值
                   b.Ljyfkje,-- 累计应付金额
                   b.Ljsfk ,--累计实付款
                   ISNULL(b.Xmpdljwccz,0) - ISNULL(b.Ljsfk, 0) AS Ydczwzfje, -- 已达产值未付金额
                   ISNULL(b.Ljyfkje, 0) - ISNULL(b.Ljsfk, 0) AS Yfwfje -- 应付未付金额
            FROM (
                  select    
                        a.OutputValueMonthReviewGUID, 
                        b.BldGUID,
						b.BldName,
						b.Jszt,
                        b.BldArea,
                        sum(b.HtAmount) as HtAmount,
                        sum(b.HtylAmount) as HtylAmount,
                        sum(b.Dfscz) as Dfscz,
                        sum(b.Ljyfkje) as Ljyfkje,
                        sum(b.Ljsfk) as Ljsfk,
                        sum(b.Xmpdljwccz) as Xmpdljwccz
                    from  cb_OutputValueReviewDetail a
                    LEFT JOIN cb_OutputValueReviewBld b  ON b.OutputValueReviewDetailGUID = a.OutputValueReviewDetailGUID
                    where b.BldGUID is  Not NULL
                    group by  a.OutputValueMonthReviewGUID, 
                        b.BldGUID,
						b.BldName,
						b.Jszt,
                        b.BldArea
            ) b 
            LEFT JOIN (
                SELECT GCBldGUID,
                       SUM(ISNULL(ld.ysmj,0)) AS ldysmj,--  楼栋已售面积
                       SUM(ISNULL(ld.zhz,0)) AS ldzhz,  -- 楼栋总货值
                       SUM(ISNULL(ld.ysje,0)) AS ldysje, -- 楼栋已售货值
                       SUM(ISNULL(ld.syhz,0)) AS ldsyhz  -- 楼栋待售货值              
                FROM erp25.dbo.p_lddbamj ld
                WHERE DATEDIFF(day, QXDate, GETDATE()) = 0
                GROUP BY GCBldGUID
            ) lddb ON lddb.GCBldGUID = b.BldGUID
            LEFT JOIN ( 
                SELECT ldjd.GCBldGUID,
                       ldjd.BuildArea,
                       case when ldjd.sjkgDate is not null then ldjd.BuildArea else  0  end AS ldkgmj -- 楼栋开工面积
                FROM (
                    SELECT gc.GCBldGUID,
                           max(dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '实际完成时间')) as sjkgDate,
                           SUM(ISNULL(gc.UpBuildArea, 0) + ISNULL(gc.DownBuildArea, 0)) AS BuildArea
                    FROM dbo.p_HkbBiddingBuilding2BuildingWork a 
                    INNER JOIN ERP25.dbo.mdm_GCBuild gc  
                        ON gc.GCBldGUID = a.BuildingGUID
                    INNER JOIN p_HkbBiddingBuildingWork pw 
                        ON pw.BuildGUID = a.BudGUID
                    INNER JOIN jd_ProjectPlanExecute jp 
                        ON jp.ObjectID = pw.BuildGUID
                    GROUP BY gc.GCBldGUID
                ) ldjd
            ) ldkg  ON ldkg.GCBldGUID = b.BldGUID
        ) ld 
            ON ld.OutputValueMonthReviewGUID = ovr.OutputValueMonthReviewGUID
WHERE p.level = 3   AND bu.buguid IN (@buguid)
ORDER BY bu.buname, p.ProjName, ld.BldName


-- SELECT  b.BldName,
--         ISNULL(b.BldArea, 0) AS BldArea,
--         b.Jszt,
--         ISNULL(a.HtAmount, 0) + ISNULL(a.HtylAmount, 0) AS Zcz,
--         ISNULL(a.Xmpdljwccz, 0) AS Xmpdljwccz,
--         ISNULL(a.Dfscz, 0) AS Dfscz,
--         ISNULL(a.Ljyfkje, 0) AS Ljyfkje,
--         ISNULL(a.Ljsfk, 0) AS Ljsfk,
--         ISNULL(a.Xmpdljwccz,0) - ISNULL(a.Ljsfk, 0) AS Ydczwzfje,
--         ISNULL(a.Ljyfkje, 0) - ISNULL(a.Ljsfk, 0) AS Yfwfje,
--         a.BldGUID
-- FROM    (
--             SELECT  SUM(ISNULL(a.BudgetAmount, 0)) AS BudgetAmount,
--                     SUM(ISNULL(b.HtAmount, 0)) AS HtAmount,
--                     SUM(ISNULL(b.BcxyAmount, 0)) AS BcxyAmount,
--                     SUM(ISNULL(b.HtylAmount, 0)) AS HtylAmount,
--                     SUM(ISNULL(b.Sgdwysbcz, 0)) AS Sgdwysbcz,
--                     SUM(ISNULL(b.Xmpdljwccz, 0)) AS Xmpdljwccz,
--                     SUM(ISNULL(b.Dfscz, 0)) AS Dfscz,
--                     SUM(ISNULL(b.Ljyfkje, 0)) AS Ljyfkje,
--                     SUM(ISNULL(b.Ljsfk, 0)) AS Ljsfk,
--                     BldGUID
--             FROM    cb_OutputValueReviewDetail a
--                     INNER JOIN dbo.cb_OutputValueReviewBld b ON b.OutputValueReviewDetailGUID = a.OutputValueReviewDetailGUID
--             WHERE   (1=1)
--                     AND (2=2)
--             GROUP BY b.BldGUID
--         ) a
--         INNER JOIN (
--             SELECT  DISTINCT b.BldName,
--                     b.BldArea,
--                     b.BldGUID,
--                     b.Jszt
--             FROM    cb_OutputValueReviewDetail a
--                     INNER JOIN dbo.cb_OutputValueReviewBld b ON b.OutputValueReviewDetailGUID = a.OutputValueReviewDetailGUID
--             WHERE   (1=1)
--                     AND (2=2)
--         ) b ON a.BldGUID = b.BldGUID
-- ORDER BY b.BldName DESC


-- SELECT b.BldName,
--        ISNULL(b.BldArea, 0) AS BldArea,
--        b.Jszt,
--        ISNULL(a.HtAmount, 0) + ISNULL(a.HtylAmount, 0) AS Zcz,
--        ISNULL(a.Xmpdljwccz, 0) AS Xmpdljwccz,
--        ISNULL(a.Dfscz, 0) AS Dfscz,
--        ISNULL(a.Ljyfkje, 0) AS Ljyfkje,
--        ISNULL(a.Ljsfk, 0) AS Ljsfk,
--        ISNULL(a.Xmpdljwccz, 0) - ISNULL(a.Ljsfk, 0) AS Ydczwzfje,
--        ISNULL(a.Ljyfkje, 0) - ISNULL(a.Ljsfk, 0) AS Yfwfje,
--        a.BldGUID
-- FROM
-- (
--     SELECT SUM(ISNULL(a.BudgetAmount, 0)) AS BudgetAmount,
--            SUM(ISNULL(b.HtAmount, 0)) AS HtAmount,
--            SUM(ISNULL(b.BcxyAmount, 0)) AS BcxyAmount,
--            SUM(ISNULL(b.HtylAmount, 0)) AS HtylAmount,
--            SUM(ISNULL(b.Sgdwysbcz, 0)) AS Sgdwysbcz,
--            SUM(ISNULL(b.Xmpdljwccz, 0)) AS Xmpdljwccz,
--            SUM(ISNULL(b.Dfscz, 0)) AS Dfscz,
--            SUM(ISNULL(b.Ljyfkje, 0)) AS Ljyfkje,
--            SUM(ISNULL(b.Ljsfk, 0)) AS Ljsfk,
--            BldGUID
--     FROM cb_OutputValueReviewDetail a
--         INNER JOIN dbo.cb_OutputValueReviewBld b ON b.OutputValueReviewDetailGUID = a.OutputValueReviewDetailGUID
--         INNER JOIN dbo.cb_OutputValueMonthReview c ON c.OutputValueMonthReviewGUID = a.OutputValueMonthReviewGUID
--     WHERE (1 = 1)
--           AND (2 = 2)
--           AND c.ProjGUID = 'b4e52965-44aa-4073-83bd-a7cef63301d'
--     GROUP BY b.BldGUID
-- ) a
--     INNER JOIN
--     (
--         SELECT DISTINCT
--                b.BldName,
--                b.BldArea,
--                b.BldGUID,
--                b.Jszt
--         FROM cb_OutputValueReviewDetail a
--             INNER JOIN dbo.cb_OutputValueReviewBld b
--                 ON b.OutputValueReviewDetailGUID = a.OutputValueReviewDetailGUID
--             INNER JOIN dbo.cb_OutputValueMonthReview c
--                 ON c.OutputValueMonthReviewGUID = a.OutputValueMonthReviewGUID
--         WHERE (1 = 1)
--               AND (2 = 2)
--               AND c.ProjGUID = 'b4e52965-44aa-4073-83bd-a7cef63301d1'
--     ) b
--         ON a.BldGUID = b.BldGUID
-- ORDER BY b.BldName DESC;

-- 为主要查询表创建索引
-- 1. cb_OutputValueMonthReview表索引
CREATE NONCLUSTERED INDEX IX_cb_OutputValueMonthReview_ProjGUID
ON cb_OutputValueMonthReview (ProjGUID)
INCLUDE (ReviewDate, TotalOutputValue, YfsOutputValue, LjyfAmount, 
         LjsfAmount, BnljsfAmount, YdczwfAmount, YfwfAmount, 
         XyyfzfAmount, Ndzjjh);

-- 2. md_Project表索引
CREATE NONCLUSTERED INDEX IX_md_Project_ProjGUID_ApproveState
ON md_Project (ProjGUID, ApproveState, CreateDate)
INCLUDE (CreateReason, SumBuildArea, SumSaleArea);

-- 3. p_lddbamj表索引
CREATE NONCLUSTERED INDEX IX_p_lddbamj_GCBldGUID_QXDate
ON erp25.dbo.p_lddbamj (GCBldGUID, QXDate)
INCLUDE (ysmj, zhz, Realysxx_th, syhz, ysje);

-- 4. jd_PlanTaskExecuteObjectForReport表索引
CREATE NONCLUSTERED INDEX IX_jd_PlanTaskExecuteObjectForReport_ProjGUID
ON jd_PlanTaskExecuteObjectForReport (ProjGUID)
INCLUDE (实际开工实际完成时间, 计划组团建筑面积, 是否停工);

-- 5. p_project表索引
CREATE NONCLUSTERED INDEX IX_p_project_Level_BUGUID
ON p_project (level, BUGUID)
INCLUDE (ProjGUID, ProjName);

-- 6. cb_OutputValueReviewBld表索引
CREATE NONCLUSTERED INDEX IX_cb_OutputValueReviewBld_OutputValueReviewDetailGUID
ON cb_OutputValueReviewBld (OutputValueReviewDetailGUID)
INCLUDE (BldGUID, BldName, BldArea, Jszt, HtAmount, HtylAmount,
         Xmpdljwccz, Dfscz, Ljyfkje, Ljsfk);

-- 注意：在创建索引前请注意：
-- 1. 在生产环境执行前先在测试环境验证
-- 2. 选择业务低峰期执行
-- 3. 评估索引对写入性能的影响
-- 4. 确保有足够的磁盘空间


SELECT b.ProjName,
       cb_OutputValueMonthReview.ReviewDate,
       cb_OutputValueMonthReview.CreateOn,
       cb_OutputValueMonthReview.ApproveState,
       cb_OutputValueMonthReview.Approver,
       cb_OutputValueMonthReview.ApproveDate,
       cb_OutputValueMonthReview.BuildTotalArea,
       cb_OutputValueMonthReview.StartWorkArea,
       cb_OutputValueMonthReview.ShutDownArea,
       cb_OutputValueMonthReview.TotalOutputValue,
       cb_OutputValueMonthReview.YfsOutputValue,
       cb_OutputValueMonthReview.DfsOutputValue,
       cb_OutputValueMonthReview.LjyfAmount,
       cb_OutputValueMonthReview.LjsfAmount,
       cb_OutputValueMonthReview.BnljsfAmount,
       cb_OutputValueMonthReview.YfwfAmount,
       cb_OutputValueMonthReview.YdczwfAmount,
       cb_OutputValueMonthReview.XyyfzfAmount,
       cb_OutputValueMonthReview.Ndzjjh,
       cb_OutputValueMonthReview.OutputValueMonthReviewGUID,
       ISNULL(cb_OutputValueMonthReview.Ndzjjh,0) - ISNULL(cb_OutputValueMonthReview.BnljsfAmount,0) AS BnygsyzfAmount,
       cb_OutputValueMonthReview.ProjGUID,
       cb_OutputValueMonthReview.CreateOnGUID,
       cb_OutputValueMonthReview.OutputValueMonthReviewName,
       cb_OutputValueMonthReview.Zksmj,
       cb_OutputValueMonthReview.Ysmj,
       cb_OutputValueMonthReview.Dsmj,
       cb_OutputValueMonthReview.Zhz,
       cb_OutputValueMonthReview.Ydysxxhz,
       cb_OutputValueMonthReview.Yshz,
       cb_OutputValueMonthReview.Dshz
FROM dbo.cb_OutputValueMonthReview
LEFT JOIN dbo.p_Project b 
    ON b.ProjGUID = dbo.cb_OutputValueMonthReview.ProjGUID
WHERE (1=1)