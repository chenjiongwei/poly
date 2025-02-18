-- 02 月度产值回顾_不含销售数据 报表
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
SELECT  ROW_NUMBER() OVER(ORDER BY bu.buname, p.projname) AS '编号',
        bu.buname AS '公司名称',                                                      -- 合同的归属公司
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
        proj.SumBuildArea AS '产值信息_总建筑面积',                                  -- 基础数据系统最新版的建筑面积之和
        jd.累计开工面积 AS '产值信息_已开工面积',                                     -- 楼栋计划"实际开工"节点的实际完成日期不为空的建筑面积之和
        jd.当前停工面积 AS '产值信息_停工缓建面积',                                   -- 组团楼栋状态为停工，"实际开工日期"不为空的组团的建筑面积之和
        ovr.TotalOutputValue AS '产值信息_总产值',                                  -- 汇总各楼栋总产值
        ovr.YfsOutputValue AS '产值信息_已发生产值',                                -- 汇总各楼栋项目盘点累计已完成产值
        ISNULL(ovr.TotalOutputValue,0) - ISNULL(ovr.YfsOutputValue,0) AS '产值信息_待发生产值',  --总产值-待发生产值
        ovr.LjyfAmount AS '付款信息_累计应付款',                                    -- 汇总当前项目分期下合同累计应付款
        ovr.LjsfAmount AS '付款信息_累计实付款',                                    -- 汇总当前项目分期下合同累计实付款
        ovr.BnljsfAmount AS '付款信息_本月累计实付款',                              -- 取当前分期下面，实付开票日期为当前年的实付金额
        ovr.YdczwfAmount AS '付款信息_已达产值未付金额',
        ovr.YfwfAmount AS '付款信息_应付未付金额',
        ovr.XyyfzfAmount AS '付款信息_下月预估支付金额',
        ovr.Ndzjjh AS '付款信息_年度资金计划',
        ISNULL(ovr.Ndzjjh,0) - ISNULL(ovr.BnljsfAmount,0) AS '付款信息_本年预估剩余支付金额',  --年度资金计划-本年累计实付款
        ld.BldName AS '楼栋产值盘点_楼栋名称',
        ld.Jszt AS '楼栋产值盘点_建设状态',
        ld.BldArea AS '楼栋产值盘点_建筑面积',
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
                   b.Jszt,
                   ISNULL(b.HtAmount, 0) + ISNULL(b.HtylAmount, 0) AS Zcz,
                   ldkg.ldkgmj,
                   b.Xmpdljwccz,
                   b.Dfscz,
                   b.Ljyfkje,
                   b.Ljsfk,
                   ISNULL(b.Xmpdljwccz,0) - ISNULL(b.Ljsfk, 0) AS Ydczwzfje,
                   ISNULL(b.Ljyfkje, 0) - ISNULL(b.Ljsfk, 0) AS Yfwfje
            FROM  (
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
                SELECT ldjd.GCBldGUID,
                       CASE WHEN ldjd.sjkgDate IS NOT NULL 
                            THEN ldjd.BuildArea 
                            ELSE 0 
                       END AS ldkgmj
                FROM (
                    SELECT gc.GCBldGUID,
                           MAX(dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '实际完成时间')) as sjkgDate,
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
            ) ldkg   ON ldkg.GCBldGUID = b.BldGUID
        ) ld ON ld.OutputValueMonthReviewGUID = ovr.OutputValueMonthReviewGUID
WHERE p.level = 3    AND bu.buguid IN (@buguid)
ORDER BY bu.buname, p.ProjName, ld.BldName;