SELECT  CASE WHEN a.序号 <= 10 THEN '是' ELSE '否' END AS 短讯是否显示 ,
        *
FROM(SELECT ROW_NUMBER() OVER (ORDER BY 延期月 DESC) AS 序号 ,
            项目名称 + '-' + 计划组团名称 + '开工：原节点' + CONVERT(VARCHAR(10), 计划开工完成日期, 121) + '，已逾期超' + CONVERT(VARCHAR(10), CONVERT(DECIMAL(18,1), ISNULL(延期月, 0)) ) + '个月' + ';' AS 简讯内容 ,
            公司名称 ,
            项目名称 ,
            计划组团名称 ,
            逾期风险等级,
            决策开工时间 AS 决策开工日期 ,
            计划开工完成日期 AS 计划开工日期 ,
            实际开工完成日期 AS 实际开工日期 ,
            NULL AS 关联工程楼栋 ,
            本年计划开工面积 ,
            本年已开工面积 ,
            本月计划开工面积 ,
            本月逾期未开工面积 ,
            本月已开工面积 ,
            延期月
     FROM   (SELECT '华南公司' AS 公司名称 ,
                    项目名称 ,
                    计划组团名称 ,
                    逾期风险等级,
                    决策开工时间 ,
                    计划开工完成日期 ,
                    实际开工完成日期 ,
                    --关联工程楼栋 ,
                    CASE WHEN DATEDIFF(YEAR, 计划开工完成日期, GETDATE()) = 0 THEN 本年计划开工面积 ELSE 0 END AS 本年计划开工面积 ,
                    CASE WHEN DATEDIFF(YEAR, 实际开工完成日期, GETDATE()) = 0 THEN 本年计划开工面积 ELSE 0 END AS 本年已开工面积 ,
                    CASE WHEN DATEDIFF(MONTH, 计划开工完成日期, GETDATE()) = 0 THEN 本年计划开工面积 ELSE 0 END AS 本月计划开工面积 ,
                    CASE WHEN DATEDIFF(MONTH, 计划开工完成日期, GETDATE()) = 0 AND   DATEDIFF(DAY, 计划开工完成日期, GETDATE()) >= 0 AND   实际开工完成日期 IS NULL AND 决策开工时间 IS NOT NULL   
					      THEN 本年计划开工面积 ELSE 0 END AS 本月逾期未开工面积 ,
                    CASE WHEN DATEDIFF(MONTH, 实际开工完成日期, GETDATE()) = 0 THEN 本年计划开工面积 ELSE 0 END AS 本月已开工面积 ,
                    CASE WHEN DATEDIFF(YEAR, 计划开工完成日期, GETDATE()) = 0 AND DATEDIFF(DAY, 计划开工完成日期, GETDATE()) >= 0 AND  实际开工完成日期 IS NULL  AND  决策开工时间 IS NOT NULL 
					       THEN DATEDIFF(DAY, 计划开工完成日期, ISNULL(实际开工完成日期, GETDATE())) * 1.0 / 30.0
                    END AS 延期月
             FROM   data_tb_hn_StartWorkNodePlan a
                    OUTER APPLY(SELECT  TOP 1   batch_id
                                FROM    data_tb_hn_StartWorkNodePlan
                                ORDER BY batch_update_time DESC) px
             WHERE a.batch_id = px.batch_id AND 决策开工时间 IS NOT NULL) t ) a;
