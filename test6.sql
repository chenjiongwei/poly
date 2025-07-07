--开发预警

--预警范围：1、项目状态为正常；2、获取时间在18年之前的
SELECT *
INTO #data_wide_dws_mdm_Project
FROM dbo.data_wide_dws_mdm_Project
WHERE ProjStatus = '正常'
      AND DATEDIFF(yy, BeginDate, '2018-01-01') <= 0; 

SELECT 类别,
       ISNULL(chg.afterGuid, t.BUGUID) BUGUID , 
       t.ProjGUID,
       t.SpreadName,
       逾期面积 / 10000 AS 逾期面积,
       逾期天数,
       计划完成时间
FROM
(
    SELECT a.BUGUID,
           b.ProjGUID,
           b.SpreadName,
           '开工预警' AS 类别,
           SUM(DATEDIFF(dd, a1.PlanBeginDate, GETDATE())) AS 逾期天数,
           SUM(a.BuildArea) 逾期面积,
           MIN(a1.PlanBeginDate) AS 计划完成时间
    FROM data_wide_dws_mdm_Building a
        INNER JOIN data_wide_dws_mdm_Building a1
            ON a1.BuildingGUID = a.GCBldGUID
        INNER JOIN #data_wide_dws_mdm_Project b
            ON a.ParentProjGUID = b.ProjGUID
    WHERE a.BldType = '产品楼栋'
          AND a1.BldType = '工程楼栋'
          AND a1.PlanBeginDate IS NOT NULL
          AND a1.PlanBeginDate < GETDATE()
          AND a1.FactBeginDate IS NULL
          AND DATEDIFF(dd, a1.PlanBeginDate, GETDATE()) > 15
    GROUP BY a.BUGUID,
             b.ProjGUID,
             b.SpreadName
    UNION ALL
    SELECT a.BUGUID,
           b.ProjGUID,
           b.SpreadName,
           '供货预警' AS 类别,
           SUM(DATEDIFF(dd, ISNULL(a.PlanNotOpen, a1.PlanNotOpen), GETDATE())) AS 逾期天数,
           SUM(a.AvailableArea) 逾期面积,
           MIN(ISNULL(a.PlanNotOpen, a1.PlanNotOpen)) AS 计划完成时间
    FROM data_wide_dws_mdm_Building a
        INNER JOIN data_wide_dws_mdm_Building a1
            ON a1.BuildingGUID = a.GCBldGUID
        INNER JOIN #data_wide_dws_mdm_Project b
            ON a.ParentProjGUID = b.ProjGUID
    WHERE a.BldType = '产品楼栋'
          AND a1.BldType = '工程楼栋'
          AND ISNULL(a.PlanNotOpen, a1.PlanNotOpen) IS NOT NULL
          AND ISNULL(a.PlanNotOpen, a1.PlanNotOpen) < GETDATE()
          AND ISNULL(a.FactNotOpen, a1.FactNotOpen) IS NULL
    GROUP BY a.BUGUID,
             b.ProjGUID,
             b.SpreadName
    UNION ALL
    SELECT a.BUGUID,
           b.ProjGUID,
           b.SpreadName,
           '竣备预警' AS 类别,
           SUM(DATEDIFF(dd, a1.PlanFinishDate, GETDATE())) AS 逾期天数,
           SUM(a.BuildArea) 逾期面积,
           MIN(a1.PlanFinishDate) AS 计划完成时间
    FROM data_wide_dws_mdm_Building a
        INNER JOIN data_wide_dws_mdm_Building a1
            ON a1.BuildingGUID = a.GCBldGUID
        INNER JOIN #data_wide_dws_mdm_Project b
            ON a.ParentProjGUID = b.ProjGUID
    WHERE a.BldType = '产品楼栋'
          AND a1.BldType = '工程楼栋'
          AND a1.PlanFinishDate IS NOT NULL
          AND a1.PlanFinishDate < GETDATE()
          --  AND DATEDIFF(yy, a1.PlanFinishDate, GETDATE()) = 0
          AND a1.FactFinishDate IS NULL
    GROUP BY a.BUGUID,
             b.ProjGUID,
             b.SpreadName
    UNION ALL
    SELECT a.BUGUID,
           b.ProjGUID,
           b.SpreadName,
           '交付预警' AS 类别,
           SUM(DATEDIFF(dd, a1.JzjfDatePlan, GETDATE())) AS 逾期天数,
           SUM(a.BuildArea) 逾期面积,
           MIN(a1.JzjfDatePlan) AS 计划完成时间
    FROM data_wide_dws_mdm_Building a
        INNER JOIN data_wide_dws_mdm_Building a1
            ON a1.BuildingGUID = a.GCBldGUID
        INNER JOIN #data_wide_dws_mdm_Project b
            ON a.ParentProjGUID = b.ProjGUID
    WHERE a.BldType = '产品楼栋'
          AND a1.BldType = '工程楼栋'
          AND a1.JzjfDatePlan IS NOT NULL
          AND a1.JzjfDatePlan < GETDATE()
          --   AND DATEDIFF(yy, a1.JzjfDatePlan, GETDATE()) = 0
          AND a1.JzjfDateActual IS NULL
    GROUP BY a.BUGUID,
             b.ProjGUID,
             b.SpreadName
    UNION ALL
    SELECT a.BUGUID,
           b.ProjGUID,
           b.SpreadName,
           '首开预警' AS 类别,
           DATEDIFF(dd, a.PlanOpenDate, GETDATE()) AS 逾期天数,
           SUM(a.AvailableArea) 逾期面积,
           a.PlanOpenDate AS 计划完成时间
    FROM data_wide_dws_mdm_Building a
        INNER JOIN data_wide_dws_mdm_Building a1
            ON a1.BuildingGUID = a.GCBldGUID
        INNER JOIN #data_wide_dws_mdm_Project b
            ON a.ParentProjGUID = b.ProjGUID
        INNER JOIN
        (
            SELECT sk.ParentProjGUID,
                   MIN(PlanOpenDate) AS PlanOpenDate
            FROM data_wide_dws_mdm_Building sk
            GROUP BY sk.ParentProjGUID
            HAVING MIN(sk.FactOpenDate) IS NULL
        ) sk
            ON sk.PlanOpenDate = a.PlanOpenDate
               AND sk.ParentProjGUID = a.ParentProjGUID
    WHERE a.BldType = '产品楼栋'
          AND a1.BldType = '工程楼栋'
          AND a.PlanOpenDate IS NOT NULL
          AND a.PlanOpenDate < GETDATE()
          --    AND DATEDIFF(yy, a.PlanOpenDate, GETDATE()) = 0
          AND a.FactOpenDate IS NULL
    GROUP BY a.BUGUID,
             b.ProjGUID,
             b.SpreadName,
             a.PlanOpenDate
) t
 LEFT JOIN dbo.s_rptzjlkb_OrgInfo_chg chg ON t.buguid = chg.beforeGuid
WHERE t.逾期面积 <> 0
;

DROP TABLE #data_wide_dws_mdm_Project;
