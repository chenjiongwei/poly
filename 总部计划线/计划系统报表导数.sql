/*
存储过程名称: usp_rpt_PlanSystemOutValueReport
功能描述: 计划系统报表导数
执行实例: exec usp_rpt_PlanSystemOutValueReport '63E5AF54-6BF4-4D37-B2D6-48E60116334A'
*/
ALTER PROC usp_rpt_PlanSystemOutValueReport(
    @ProjGUID VARCHAR(max)
)
AS
BEGIN
    -- 查询最新版进度回顾时间
    -- 第一次回顾 - 获取最新一次已审核的进度回顾记录
    SELECT 
        rowmo,
        ProjGUID,
        ReportDate,
        OutValueViewGUID
    INTO #FirstView 
    FROM (
        SELECT 
            ROW_NUMBER() OVER(PARTITION BY jdv.ProjGUID ORDER BY jdv.ReportDate DESC) AS rowmo,
            jdv.ProjGUID,
            jdv.ReportDate,
            jdv.OutValueViewGUID
        FROM jd_OutValueView jdv 
        WHERE jdv.ApproveState = '已审核'
    ) FirstView
    WHERE FirstView.rowmo = 1

    -- 第二次回顾 - 获取次新一次已审核的进度回顾记录
    SELECT 
        rowmo,
        ProjGUID,
        ReportDate,
        OutValueViewGUID
    INTO #SecondView
    FROM (
        SELECT 
            ROW_NUMBER() OVER(PARTITION BY jdv.ProjGUID ORDER BY jdv.ReportDate DESC) AS rowmo,
            jdv.ProjGUID,
            jdv.ReportDate,
            jdv.OutValueViewGUID
        FROM jd_OutValueView jdv 
        WHERE jdv.ApproveState = '已审核'
    ) SecondView
    WHERE SecondView.rowmo = 2

    -- 主查询 - 获取项目进度相关信息
    SELECT 
        -- 基本信息
        dev.DevelopmentCompanyName AS [公司],
        lb.TgProjCode [投管代码],
        mpp.ProjName [项目立项名],
        mpp.SpreadName [项目案名], 
        mp.ProjName [分期],
        mpp.AcquisitionDate [项目获取时间],
        mp.ConstructStatus [分期建设状态],
        gc.BldNameList [分期包含楼栋],
        
        -- 面积信息
        ISNULL(p.SumBuildArea, 0) / 10000.0 AS [总建筑面积],
        ISNULL(p.SumSaleArea, 0) / 10000.0 AS [总可售面积],
        ISNULL(jd.累计开工面积, 0) / 10000.0 AS [累计开工面积],
        ISNULL(jd.累计竣工面积, 0) / 10000.0 AS [累计竣工面积],
        -- 当前在建面积 = 累计开工面积 - 累计竣工面积 - 当前停工面积
        (ISNULL(jd.累计开工面积, 0) - ISNULL(jd.累计竣工面积, 0) - ISNULL(jd.当前停工面积, 0)) / 10000.0 AS [当前在建面积],
        ISNULL(ysmj.ysmj, 0) / 10000.0 AS [累计销售面积], -- 没有口径不太好计算
        
        -- 比例信息
        -- 累计开工比例 = 累计开工面积/总建筑面积
        CASE 
            WHEN ISNULL(p.SumBuildArea, 0) = 0 THEN 0 
            ELSE ISNULL(jd.累计开工面积, 0) / ISNULL(p.SumBuildArea, 0) 
        END AS [累计开工比例],
        CASE 
            WHEN ISNULL(p.SumBuildArea, 0) = 0 THEN 0 
            ELSE ISNULL(ysmj.ysmj, 0) / ISNULL(p.SumBuildArea, 0) 
        END [累计销售比例], -- 累计销售面积/总可售面积
        
        -- 时间节点
        jd.分期开工时间 AS [分期开工时间], -- 取分期实际开工时间（未完成取计划时间）
        jd.分期首批竣工时间 AS [分期首批竣工时间], -- 取分期首批竣工时间（未完成取计划时间）
        jd.分期末批竣工时间 AS [分期末批竣备时间], -- 取分期整体竣工时间（未完成取计划时间）
        
        -- 最新版进度回顾信息
        fv.ReportDate AS [最新版进度回顾时间], -- 最新一版审核归档版进度回顾的归档时间
        FvLd.[最新版未开工面积],
        FvLd.[最新版施工准备面积],
        FvLd.[最新版地下结构施工面积],
        FvLd.[最新版主体结构施工面积],
        FvLd.[最新版精装及园林施工面积],
        FvLd.[最新版查验整改面积],
        FvLd.[最新版已竣备未交付面积],
        FvLd.[最新版已交付面积],
        
        -- 次新版进度回顾信息
        sv.ReportDate AS [次新版进度回顾时间],
        Secvld.[次新版未开工面积],
        Secvld.[次新版施工准备面积],
        Secvld.[次新版地下结构施工面积],
        Secvld.[次新版主体结构施工面积],
        Secvld.[次新版精装及园林施工面积],
        Secvld.[次新版查验整改面积],
        Secvld.[次新版已竣备未交付面积],
        Secvld.[次新版已交付面积],
        
        -- 新增开工和停工信息
        CASE 
            WHEN isKg.实际开工实际完成时间 IS NOT NULL THEN '是' 
            ELSE '' 
        END [新增开工],
        CASE 
            WHEN isTg.StopTime IS NOT NULL THEN '是' 
            ELSE '' 
        END [新增停工缓建]
            
    FROM erp25.dbo.mdm_project mp
    -- 关联项目父级信息
    INNER JOIN erp25.dbo.mdm_Project mpp 
        ON mpp.ProjGUID = mp.ParentProjGUID 
        AND mpp.Level = 2
        
    -- 关联最新已审核项目信息    
    INNER JOIN (
        SELECT *
        FROM (
            SELECT 
                ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) AS rowmo,
                *
            FROM dbo.md_Project
            WHERE ApproveState = '已审核'
                AND ISNULL(CreateReason, '') <> '补录'
        ) x
        WHERE x.rowmo = 1
    ) p ON p.ProjGUID = mp.ProjGUID

    -- 查询楼栋底表的已售面积
    LEFT JOIN (
        SELECT 
            gc.ProjGUID,
            SUM(ISNULL(ysmj, 0)) AS ysmj
        FROM erp25.dbo.p_lddbamj ld
        INNER JOIN erp25.dbo.mdm_GCBuild gc 
            ON gc.GCBldGUID = ld.GCBldGUID
        WHERE DATEDIFF(day, QXDate, GETDATE()) = 0
        GROUP BY gc.ProjGUID
    ) ysmj ON ysmj.ProjGUID = mp.ProjGUID

    -- 关联楼栋信息
    LEFT JOIN (
        SELECT 
            ProjGUID,
            VersionGUID,
            STRING_AGG(gc.BldName, ',') WITHIN GROUP(ORDER BY gc.BldName) AS BldNameList
        FROM md_GCBuild gc
        GROUP BY ProjGUID, VersionGUID
    ) gc ON gc.ProjGUID = mp.ProjGUID 
        AND gc.VersionGUID = p.VersionGUID

    -- 关联开发公司信息
    INNER JOIN erp25.dbo.p_DevelopmentCompany dev 
        ON dev.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
        
    -- 关联进度信息    
    LEFT JOIN (
        SELECT 
            por.projguid,
            SUM(CASE 
                WHEN 实际开工实际完成时间 IS NOT NULL THEN ISNULL(计划组团建筑面积, 0) 
                ELSE 0 
            END) AS 累计开工面积,
            SUM(CASE 
                WHEN 竣工备案实际完成时间 IS NOT NULL THEN ISNULL(计划组团建筑面积, 0) 
                ELSE 0 
            END) AS 累计竣工面积,
            SUM(CASE 
                WHEN ISNULL(是否停工, '') <> '正常' THEN ISNULL(计划组团建筑面积, 0) 
                ELSE 0 
            END) AS 当前停工面积,
            MIN(ISNULL(实际开工实际完成时间, 实际开工计划完成时间)) AS 分期开工时间,
            MIN(ISNULL(竣工备案实际完成时间, 竣工备案计划完成时间)) AS 分期首批竣工时间,
            MAX(ISNULL(竣工备案实际完成时间, 竣工备案计划完成时间)) AS 分期末批竣工时间
        FROM jd_PlanTaskExecuteObjectForReport por
        GROUP BY por.projguid
    ) jd ON jd.projguid = mp.ProjGUID
    
    -- 关联投管代码
    LEFT JOIN (
        SELECT 
            ProjGUID AS ParentGUID,
            LbProjectValue AS TgProjCode
        FROM mdm_LbProject
        WHERE LbProject = 'tgid'
    ) lb ON lb.ParentGUID = mp.ParentProjGUID
    
    -- 关联最新版进度回顾
    LEFT JOIN #FirstView fv ON fv.ProjGUID = p.ProjGUID
    LEFT JOIN (
        /*
        已竣备未交付
        精装及室外园林施工
        主体结构施工
        未开工
        查验整改
        地下结构施工
        施工准备
        已交付
        */
        SELECT 
            fvl.OutValueViewGUID,
            fvl.ProjGUID,
            SUM(CASE 
                WHEN fvl.status = '未开工' THEN fvl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [最新版未开工面积],
            SUM(CASE 
                WHEN fvl.status = '施工准备' THEN fvl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [最新版施工准备面积],
            SUM(CASE 
                WHEN fvl.status = '地下结构施工' THEN fvl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [最新版地下结构施工面积],
            SUM(CASE 
                WHEN fvl.status = '主体结构施工' THEN fvl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [最新版主体结构施工面积],
            SUM(CASE 
                WHEN fvl.status = '精装及室外园林施工' THEN fvl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [最新版精装及园林施工面积],
            SUM(CASE 
                WHEN fvl.status = '查验整改' THEN fvl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [最新版查验整改面积],
            SUM(CASE 
                WHEN fvl.status = '已竣备未交付' THEN fvl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [最新版已竣备未交付面积],
            SUM(CASE 
                WHEN fvl.status = '已交付' THEN fvl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [最新版已交付面积]
        FROM (
            SELECT 
                fv.projGUID,
                fv.OutValueViewGUID,
                a.OutValueJsztGUID, -- 主键GUID
                a.BusinessName, -- 组团/楼栋
                a.BusinessGUID, -- 组团/楼栋GUID
                a.YtName, -- 业态名称
                a.KeyNodeName, -- 已完成最新关键节点
                b.status, -- 楼栋建设状态名称
                ld.Name, -- 组团名称
                ld.SumBuildArea -- 楼栋建筑面积
            FROM jd_OutValueJszt a
            INNER JOIN #FirstView fv    ON fv.OutValueViewGUID = a.OutValueViewGUID 
            INNER JOIN jd_BuildConstruction b  ON a.BuildConstructionGUID = b.BuildConstructionGUID
            LEFT JOIN (
                SELECT 
                    a1.BuildingName,
                    a1.BudGUID,
                    pw.BidGUID,
                    pw.Name,
                    sum(gc.SumBuildArea) as SumBuildArea
                FROM md_GCBuild gc
                INNER JOIN (
                    SELECT *
                    FROM (
                        SELECT 
                            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) AS rowmo,
                            *
                        FROM dbo.md_Project
                        WHERE ApproveState = '已审核'
                            AND ISNULL(CreateReason, '') <> '补录'
                    ) x
                    WHERE x.rowmo = 1
                ) p ON p.VersionGUID = gc.VersionGUID  AND p.ProjGUID = gc.ProjGUID
                INNER JOIN p_BiddingBuilding2Building a1  ON a1.BuildingGUID = gc.BldGUID
                LEFT JOIN p_HkbBiddingBuildingWork pw   ON pw.BuildGUID = a1.BudGUID
                group by 
                    a1.BuildingName,
                    a1.BudGUID,
                    pw.BidGUID,
                    pw.Name
            ) ld ON ld.BudGUID = a.BusinessGUID
        ) fvl
        GROUP BY fvl.ProjGUID ,fvl.OutValueViewGUID
    ) FvLd ON FvLd.ProjGUID = p.ProjGUID
    
    -- 关联次新版进度回顾
    LEFT JOIN #SecondView sv ON sv.ProjGUID = p.ProjGUID
    LEFT JOIN (
        SELECT 
            svl.OutValueViewGUID,
            svl.ProjGUID,
            SUM(CASE 
                WHEN svl.status = '未开工' THEN svl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [次新版未开工面积],
            SUM(CASE 
                WHEN svl.status = '施工准备' THEN svl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [次新版施工准备面积],
            SUM(CASE 
                WHEN svl.status = '地下结构施工' THEN svl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [次新版地下结构施工面积],
            SUM(CASE 
                WHEN svl.status = '主体结构施工' THEN svl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [次新版主体结构施工面积],
            SUM(CASE 
                WHEN svl.status = '精装及室外园林施工' THEN svl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [次新版精装及园林施工面积],
            SUM(CASE 
                WHEN svl.status = '查验整改' THEN svl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [次新版查验整改面积],
            SUM(CASE 
                WHEN svl.status = '已竣备未交付' THEN svl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [次新版已竣备未交付面积],
            SUM(CASE 
                WHEN svl.status = '已交付' THEN svl.SumBuildArea 
                ELSE 0 
            END) / 10000.0 AS [次新版已交付面积]
        FROM (
            SELECT 
                sv.projGUID,
                sv.OutValueViewGUID,
                a.OutValueJsztGUID, -- 主键GUID
                a.BusinessName, -- 组团/楼栋
                a.BusinessGUID, -- 组团/楼栋GUID
                a.YtName, -- 业态名称
                a.KeyNodeName, -- 已完成最新关键节点
                b.status, -- 楼栋建设状态名称
                ld.Name, -- 组团名称
                ld.SumBuildArea -- 楼栋建筑面积
            FROM jd_OutValueJszt a
            INNER JOIN #SecondView sv   ON sv.OutValueViewGUID = a.OutValueViewGUID 
            INNER JOIN jd_BuildConstruction b  ON a.BuildConstructionGUID = b.BuildConstructionGUID
            LEFT JOIN (
                SELECT 
                    a1.BuildingName,
                    a1.BudGUID,
                    pw.BidGUID,
                    pw.Name,
                    sum(gc.SumBuildArea) as SumBuildArea
                FROM md_GCBuild gc
                INNER JOIN (
                    SELECT *
                    FROM (
                        SELECT 
                            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) AS rowmo,
                            *
                        FROM dbo.md_Project
                        WHERE ApproveState = '已审核'
                            AND ISNULL(CreateReason, '') <> '补录'
                    ) x
                    WHERE x.rowmo = 1
                ) p ON p.VersionGUID = gc.VersionGUID  AND p.ProjGUID = gc.ProjGUID
                INNER JOIN p_BiddingBuilding2Building a1  ON a1.BuildingGUID = gc.BldGUID
                LEFT JOIN p_HkbBiddingBuildingWork pw   ON pw.BuildGUID = a1.BudGUID
                group by 
                    a1.BuildingName,
                    a1.BudGUID,
                    pw.BidGUID,
                    pw.Name
            ) ld ON ld.BudGUID = a.BusinessGUID
        ) svl
        GROUP BY svl.ProjGUID , svl.OutValueViewGUID 
    ) Secvld ON Secvld.ProjGUID = p.ProjGUID
    
    -- 两次进度回顾间或最新一次进度回顾时，有新增汇报开工并归档的。填"是"，其余留空
    OUTER APPLY (
        SELECT TOP 1 
            a.projguid,
            a.实际开工实际完成时间
        FROM jd_PlanTaskExecuteObjectForReport a
        LEFT JOIN #FirstView fv 
            ON fv.projGUID = a.projGUID  -- 第一次汇报
        LEFT JOIN #SecondView sv 
            ON sv.projGUID = a.projGUID  -- 第二次汇报
        WHERE a.projguid = p.projguid 
            AND a.实际开工实际完成时间 BETWEEN ISNULL(sv.ReportDate, fv.ReportDate) AND fv.ReportDate
        ORDER BY a.实际开工实际完成时间 DESC 
    ) isKg
    
    -- 两次进度回顾间，有新增停工缓建，填"是"，其余留空 
    OUTER APPLY (
        SELECT TOP 1  
            d.ProjGUID,
            d.ObjectID,
            tg.StopTime,
            tg.TgType
        FROM (
            SELECT 
                tg.StopTime,
                tg.PlanID,
                tg.Type TgType
            FROM MyCost_Erp352.dbo.jd_StopOrReturnWork tg
            WHERE tg.ApplyState = '已审核' 
                AND tg.Type = '停工'
        ) tg
        LEFT JOIN MyCost_Erp352.dbo.jd_ProjectPlanTaskExecute f 
            ON f.PlanID = tg.PlanID
            AND f.Level = '1'
        LEFT JOIN MyCost_Erp352.dbo.jd_ProjectPlanExecute d 
            ON d.ID = f.PlanID
            AND d.PlanType = '103'
        WHERE d.ObjectID IS NOT NULL 
            AND tg.StopTime BETWEEN ISNULL(sv.ReportDate, fv.ReportDate) AND fv.ReportDate
        ORDER BY tg.StopTime DESC 
    ) isTg
    WHERE mp.Level = 3
        AND mp.projguid IN (  select strGUID from   [dbo].[fn_GetGuidTable](@ProjGUID) )
END