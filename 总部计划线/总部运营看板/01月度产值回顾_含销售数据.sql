 -- 01 月度产值回归-含销售数据 报表
-- 1. 创建索引建议
/*
建议在以下表和字段上创建索引:
- cb_OutputValueMonthReview: (projguid, ApproveState)
- md_Project: (ProjGUID, ApproveState, CreateDate)
- p_lddbamj: (GCBldGUID, QXDate)
- jd_PlanTaskExecuteObjectForReport: (projguid)
*/
-- declare @buguid varchar(max) ='2FF7167B-4398-4F0B-AFD8-AEA73DDAD8F5';
-- 2. 优化主查询
    -- 获取最新基础数据系统已审核项目信息
    SELECT p.*
    into #ProjectBase
    FROM (
        SELECT ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) AS rowmo,
               *
        FROM dbo.md_Project
        WHERE ApproveState = '已审核'
            AND ISNULL(CreateReason, '') <> '补录'
    ) p
    WHERE p.rowmo = 1 

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
           SUM(ISNULL(syhz,0)) AS syhz,
           sum(case when SjDdysxxDate is not null then  ISNULL(ytwsmj, 0) + ISNULL(wtmj, 0) else 0 end  ) as ydysxxhzmj,-- 已达预售形象货值面积
           sum(case when SjDdysxxDate is not null then isnull(syhz,0) else  0  end   ) as ydysxxhz  --已达预售形象货值
    into #SalesInfo
    FROM erp25.dbo.p_lddbamj ld WITH(NOLOCK)
    INNER JOIN erp25.dbo.mdm_GCBuild gc WITH(NOLOCK)  ON gc.GCBldGUID = ld.GCBldGUID
    WHERE DATEDIFF(day, QXDate, GETDATE()) = 0 
    GROUP BY gc.ProjGUID


    --  近3个月地上销售面积
      --获取近三个月的平均签约金额
  SELECT sp.ProjGUID,
      SUM( case when TopProductTypeName <> '地下室/车库' then  ISNULL(sp.SpecialCNetArea,0)+ISNULL(sp.CNetArea,0) else  0 end  )  / 3  近3个月地上销售面积
--    SUM(ISNULL(sp.SpecialCNetCount,0)+ISNULL(sp.CNetCount,0))/(CASE WHEN DATEDIFF(mm,sk.skdate,GETDATE()) in (0,1) THEN 1.0
--   WHEN DATEDIFF(mm,sk.skdate,GETDATE()) = 2 THEN 2.0
--   ELSE 3.0 END)  近三个月平均签约流速_套数
  INTO #xsls
  FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_s_SalesPerf sp
  WHERE DATEDIFF(mm,sp.StatisticalDate,GETDATE()) BETWEEN 1 AND 3
  GROUP BY sp.ProjGUID


    -- 预先计算停工缓建信息
    SELECT d.projguid, 
           COUNT(1) AS tghjNum
    into #StopWorkInfo
    FROM jd_StopOrReturnWork tg WITH(NOLOCK)
    LEFT JOIN jd_ProjectPlanTaskExecute f WITH(NOLOCK)
        ON f.PlanID = tg.PlanID 
        AND f.Level = 1
    LEFT JOIN jd_ProjectPlanExecute d WITH(NOLOCK)
        ON d.ID = f.PlanID 
        AND d.PlanType = 103
    WHERE tg.ApplyState = '已审核'   AND tg.type IN ('停工','缓建')
    GROUP BY d.projguid

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
    into #ProgressInfo
    FROM jd_PlanTaskExecuteObjectForReport por WITH(NOLOCK)
    --and   SELECT [Value] FROM dbo.fn_Split1(@buguid, ',')
    GROUP BY por.projguid


-- 主查询
SELECT  bu.buname AS '公司名称',                                                      -- 合同的归属公司
        p.projname AS '所属项目',                                                    -- 合同的所属项目
        flg.推广名 as '推广名',
        mp.ProjStatus AS '项目状态',
        mp.ConstructStatus AS '工程状态',
        CASE 
            WHEN ISNULL(cyj.tghjNum,0) > 0 THEN '是' 
            ELSE '否' 
        END AS '是否存在停工缓建',
        flg.工程操盘方 AS '工程操盘方',
        flg.成本操盘方 AS '成本操盘方',
        flg.项目代码 AS '明源系统代码',
        pp.ProjCode AS '项目代码',
        p.ProjCode AS '分期代码',
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
        -- ovr.Ydysxxhz * 10000.0 AS '销售信息_已达预售形象货值',
        ys.ydysxxhz  AS '销售信息_已达预售形象货值',

        -- 存销比=达预售形象待售货值/近3个月地上销售面积
        ys.ydysxxhzmj as '销售信息_已达预售形象货量面积',
        ls.近3个月地上销售面积 as  '近3个月地上销售面积',
        case when  isnull(ls.近3个月地上销售面积,0) =0  then 0  else  isnull(ys.ydysxxhzmj,0) / ls.近3个月地上销售面积 end as  '存销比',
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
        -- 已开工楼栋总产值：汇总【楼栋产值盘点_建设状态】不等于【未开工】的【产值信息_总产值】
        case when  ld.Jszt<>'未开工' then ld.ldzhz else 0 end as  '楼栋产值盘点_已开工楼栋总产值', 
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
        LEFT JOIN p_project pp WITH(NOLOCK) ON pp.ProjCode = p.ParentCode AND pp.Level = 2
        INNER JOIN mybusinessunit bu WITH(NOLOCK)  ON p.buguid = bu.buguid
        INNER JOIN #ProjectBase proj ON proj.ProjGUID = p.ProjGUID
        LEFT JOIN #SalesInfo ys  ON ys.ProjGUID = p.ProjGUID
        left join #xsls ls on ls.projguid =p.projguid
        INNER JOIN ERP25.dbo.mdm_project mp WITH(NOLOCK) ON mp.projguid = p.ProjGUID
        LEFT JOIN erp25.dbo.vmdm_projectFlag flg  ON flg.projguid = mp.ParentProjGUID
        LEFT JOIN #StopWorkInfo cyj ON cyj.projguid = p.projguid
        LEFT JOIN #ProgressInfo jd ON jd.projguid = mp.ProjGUID
        INNER JOIN cb_OutputValueMonthReview ovr  ON ovr.projguid = p.projguid
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
                    from  cb_OutputValueReviewDetail a WITH(NOLOCK)
                    inner JOIN cb_OutputValueReviewBld b  WITH(NOLOCK) ON b.OutputValueReviewDetailGUID = a.OutputValueReviewDetailGUID
                    inner join erp25.dbo.mdm_GCBuild  gc on b.bldguid =gc.GCBldGUID
                    inner join p_Project p on gc.ProjGUID =p.ProjGUID
                    where b.BldGUID is  Not NULL   and p.BUGUID IN ( @buguid )
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
                FROM erp25.dbo.p_lddbamj ld WITH(NOLOCK)
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
                    FROM dbo.p_HkbBiddingBuilding2BuildingWork a  WITH(NOLOCK)
                    INNER JOIN ERP25.dbo.mdm_GCBuild gc   WITH(NOLOCK)
                        ON gc.GCBldGUID = a.BuildingGUID
                    INNER JOIN p_HkbBiddingBuildingWork pw  WITH(NOLOCK)
                        ON pw.BuildGUID = a.BudGUID
                    INNER JOIN jd_ProjectPlanExecute jp  WITH(NOLOCK)
                        ON jp.ObjectID = pw.BuildGUID
                    GROUP BY gc.GCBldGUID
                ) ldjd
            ) ldkg  ON ldkg.GCBldGUID = b.BldGUID
        ) ld   ON ld.OutputValueMonthReviewGUID = ovr.OutputValueMonthReviewGUID
WHERE p.level = 3    AND bu.buguid IN ( @buguid )
ORDER BY bu.buname, p.ProjName, ld.BldName

-- 删除临时表
DROP TABLE #ProjectBase
DROP TABLE #SalesInfo
DROP TABLE #StopWorkInfo
DROP TABLE #ProgressInfo
drop table #xsls