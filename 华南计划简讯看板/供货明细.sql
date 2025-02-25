-- 供货明细表
SELECT  CASE WHEN a.序号 <= 10 THEN '是' ELSE '否' END AS 短讯是否显示 ,
        *
FROM(SELECT ROW_NUMBER() OVER (ORDER BY 延期月 DESC) AS 序号 ,
            项目名称 + '-' + 计划组团名称 + '供货：原节点' + CONVERT(VARCHAR(10), 计划供货完成日期, 121) + '，已逾期超' +CONVERT(VARCHAR(10), CONVERT(DECIMAL(18,1), ISNULL(延期月, 0)) ) + '个月' + ';' AS 简讯内容 ,
            公司名称 ,
            项目GUID ,
            项目名称 ,
            计划组团名称 ,
            逾期风险等级,
            是否开工 ,
            计划供货完成日期 AS 计划供货日期 ,
            实际供货完成日期 AS 实际完成日期 ,
            NULL AS 关联工程楼栋 ,
            本年计划供货面积 ,
            本年已供货面积 ,
            本月计划供货面积 ,
            本月逾期未供货面积 ,
            本月已供货面积 ,
            延期月
     FROM   (SELECT '华南公司' AS 公司名称 ,
                    项目名称 ,
                    p.ProjGUID as 项目GUID,
                    计划组团名称 ,
                    逾期风险等级,
                    是否开工 ,
                    计划供货完成日期 ,
                    实际供货完成日期 ,
                    --关联工程楼栋 ,
                    CASE WHEN DATEDIFF(YEAR, 计划供货完成日期, GETDATE()) = 0 THEN 本年计划供货面积 ELSE 0 END AS 本年计划供货面积 ,
                    CASE WHEN DATEDIFF(YEAR, 实际供货完成日期, GETDATE()) = 0  and 是否开工 = '是' THEN 本年计划供货面积 ELSE 0 END AS 本年已供货面积 ,
                    CASE WHEN DATEDIFF(MONTH, 计划供货完成日期, GETDATE()) = 0 THEN 本年计划供货面积 ELSE 0 END AS 本月计划供货面积 ,
                    CASE WHEN DATEDIFF(MONTH, 计划供货完成日期, GETDATE()) = 0 AND DATEDIFF(DAY, 计划供货完成日期, GETDATE()) >= 0 AND 实际供货完成日期 IS NULL AND 是否开工 = '是' THEN 本年计划供货面积 ELSE 0 END AS 本月逾期未供货面积 ,
                    CASE WHEN DATEDIFF(MONTH, 计划供货完成日期, GETDATE()) = 0 and 是否开工 = '是' THEN 本年计划供货面积 ELSE 0 END AS 本月已供货面积 ,
                    CASE WHEN DATEDIFF(YEAR, 计划供货完成日期, GETDATE()) = 0 AND  DATEDIFF(DAY, 计划供货完成日期, GETDATE()) >= 0 AND 实际供货完成日期 IS NULL AND 是否开工 = '是' THEN
                             DATEDIFF(DAY, 计划供货完成日期, ISNULL(实际供货完成日期, GETDATE())) * 1.0 / 30.0
                    END AS 延期月
             FROM   data_tb_hn_SupplySaleValueNodePlan a
                    OUTER APPLY(SELECT  TOP 1   batch_id
                                FROM    data_tb_hn_SupplySaleValueNodePlan
                                ORDER BY batch_update_time DESC) px
                    inner join data_wide_dws_mdm_Project p on p.TgProjCode =a.投管项目编码 and p.Level =2
             WHERE a.batch_id = px.batch_id AND 是否开工 = '是') t ) a;
