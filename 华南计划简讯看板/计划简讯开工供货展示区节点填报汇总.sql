
--供货填报  data_tb_hn_SupplySaleValueNodePlan
--开工填报  data_tb_hn_StartWorkNodePlan
--展示区填报 data_tb_data_tb_hn_ShowAreaNodePlan
--两翼填报 data_tb_hn_TwoWingNodePlan

WITH #kg AS (SELECT 序号 ,
                    项目名称 + '-' + 计划组团名称 + '开工：原节点' + CONVERT(VARCHAR(10), 计划开工完成日期, 121) + '，已逾期超' + CONVERT(VARCHAR(10), ISNULL(延期月, 0)) + '个月' + ';' AS 简讯内容 ,
                    CASE WHEN t.序号 <= 10 THEN '是' ELSE '否' END AS 短讯是否显示 ,
                    公司名称 ,
                    项目名称 ,
                    计划组团名称 ,
                    决策开工时间 AS 决策开工日期 ,
                    计划开工完成日期 ,
                    实际开工完成日期 ,
                    NULL AS 关联工程楼栋 ,
                    本年计划开工面积 ,
                    本年已开工面积 ,
                    本月计划开工面积 ,
                    本月逾期未开工面积 ,
                    本月已开工面积 ,
                    延期月
             FROM   (
                     SELECT ROW_NUMBER() OVER (ORDER BY 序号) AS 序号 ,
                            '华南公司' AS 公司名称 ,
                            项目名称 ,
                            计划组团名称 ,
                            决策开工时间 ,
                            计划开工完成日期 ,
                            实际开工完成日期 ,
                            --关联工程楼栋 ,
                            CASE WHEN DATEDIFF(YEAR, 计划开工完成日期, GETDATE()) = 0 THEN 本年计划开工面积 ELSE 0 END AS 本年计划开工面积 ,
                            CASE WHEN DATEDIFF(YEAR, 计划开工完成日期, GETDATE()) = 0  and  DATEDIFF(YEAR, 实际开工完成日期, GETDATE()) >= 0 and 决策开工时间  IS NOT NULL THEN 本年计划开工面积 ELSE 0 END AS 本年已开工面积 ,
                            CASE WHEN DATEDIFF(MONTH, 计划开工完成日期, GETDATE()) = 0 THEN 本年计划开工面积 ELSE 0 END AS 本月计划开工面积 ,
                            CASE WHEN DATEDIFF(MONTH, 计划开工完成日期, GETDATE()) = 0 AND   DATEDIFF(DAY, 计划开工完成日期, GETDATE()) >= 0 AND   实际开工完成日期 IS NULL  AND   决策开工时间 IS NOT NULL   THEN 本年计划开工面积 ELSE 0 END AS 本月逾期未开工面积 ,
                            CASE WHEN DATEDIFF(MONTH, 实际开工完成日期, GETDATE()) = 0 and 决策开工时间  IS NOT NULL THEN 本年计划开工面积 ELSE 0 END AS 本月已开工面积 ,
                            CASE WHEN DATEDIFF(YEAR, 计划开工完成日期, GETDATE()) = 0 AND DATEDIFF(DAY, 计划开工完成日期, GETDATE()) >= 0 AND  实际开工完成日期 IS NULL  AND   决策开工时间 IS NOT NULL    
                                 THEN DATEDIFF(MONTH, 决策开工时间, ISNULL(实际开工完成日期, GETDATE()))
                            END AS 延期月
                     FROM   data_tb_hn_StartWorkNodePlan a
                            OUTER APPLY(SELECT  TOP 1   batch_id
                                        FROM    data_tb_hn_StartWorkNodePlan
                                        ORDER BY batch_update_time DESC) px
                     WHERE a.batch_id = px.batch_id 
                    ) t 
                ) ,
     #gh AS (SELECT 序号 ,
                    项目名称 + '-' + 计划组团名称 + '供货：原节点' + CONVERT(VARCHAR(10), 计划供货完成日期, 121) + '，已逾期超' + CONVERT(VARCHAR(10), ISNULL(延期月, 0)) + '个月' + ';' AS 简讯内容 ,
                    CASE WHEN t.序号 <= 10 THEN '是' ELSE '否' END AS 短讯是否显示 ,
                    公司名称 ,
                    项目名称 ,
                    计划组团名称 ,
                    是否开工 ,
                    计划供货完成日期 ,
                    实际供货完成日期 ,
                    NULL AS 关联工程楼栋 ,
                    本年计划供货面积 ,
                    本年已供货面积 ,
                    本月计划供货面积 ,
                    本月逾期未供货面积 ,
                    本月已供货面积 ,
                    延期月
             FROM   (SELECT ROW_NUMBER() OVER (ORDER BY 序号) AS 序号 ,
                            '华南公司' AS 公司名称 ,
                            项目名称 ,
                            计划组团名称 ,
                            是否开工 ,
                            计划供货完成日期 ,
                            实际供货完成日期 ,
                            --关联工程楼栋 ,
                            CASE WHEN DATEDIFF(YEAR, 计划供货完成日期, GETDATE()) = 0 THEN 本年计划供货面积 ELSE 0 END AS 本年计划供货面积 ,
                            CASE WHEN DATEDIFF(YEAR, 计划供货完成日期, GETDATE()) = 0  and DATEDIFF(YEAR, 实际供货完成日期, GETDATE()) >= 0 and 是否开工 = '是' THEN 本年计划供货面积 ELSE 0 END AS 本年已供货面积 ,
                            CASE WHEN DATEDIFF(MONTH, 计划供货完成日期, GETDATE()) = 0 THEN 本年计划供货面积 ELSE 0 END AS 本月计划供货面积 ,
                            CASE WHEN DATEDIFF(MONTH, 计划供货完成日期, GETDATE()) = 0 AND DATEDIFF(DAY, 计划供货完成日期, GETDATE()) >= 0 AND 实际供货完成日期 IS NULL AND 是否开工 = '是' THEN 本年计划供货面积 ELSE 0 END AS 本月逾期未供货面积 ,
                            CASE WHEN DATEDIFF(MONTH, 实际供货完成日期, GETDATE()) = 0 and 是否开工 = '是' THEN 本年计划供货面积 ELSE 0 END AS 本月已供货面积 ,
                            CASE WHEN DATEDIFF(YEAR, 计划供货完成日期, GETDATE()) = 0 AND  DATEDIFF(DAY, 计划供货完成日期, GETDATE()) >= 0 AND 实际供货完成日期 IS NULL AND 是否开工 = '是' THEN
                                     DATEDIFF(MONTH, 计划供货完成日期, ISNULL(实际供货完成日期, GETDATE()))
                            END AS 延期月
                     FROM   data_tb_hn_SupplySaleValueNodePlan a
                            OUTER APPLY(SELECT  TOP 1   batch_id
                                        FROM    data_tb_hn_SupplySaleValueNodePlan
                                        ORDER BY batch_update_time DESC) px
                     WHERE a.batch_id = px.batch_id) t ) ,
     -- 展示区                
     #zsq AS (
            SELECT    序号 ,
                        项目名称 + '-' + 计划组团名称 + '供货：原节点' + CONVERT(VARCHAR(10), 计划展示区完工日期, 121) + '，已逾期超' + CONVERT(VARCHAR(10), ISNULL(延期月, 0)) + '个月' + ';' AS 简讯内容 ,
                        CASE WHEN t.序号 <= 10 THEN '是' ELSE '否' END AS 短讯是否显示 ,
                        公司名称 ,
                        项目名称 ,
                        计划组团名称 ,
                        计划展示区完工日期 AS 计划展示区完工日期 ,
                        实际展示区完工日期 AS 实际展示区完工日期 ,
                        NULL AS 关联工程楼栋 ,
                        本年计划展示区完工批次 ,
                        本年展示区已完工批次 ,
                        本月计划展示区完工批次 ,
                        本月逾期批次 ,
                        本月展示区已完工批次 ,
                        延期月
              FROM  (SELECT ROW_NUMBER() OVER (ORDER BY(CASE WHEN DATEDIFF(YEAR, 计划展示区完工日期, GETDATE()) = 0 AND  DATEDIFF(DAY, 计划展示区完工日期, GETDATE()) >= 0 AND 实际展示区完工日期 IS NULL THEN
                                                                 DATEDIFF(MONTH, 计划展示区完工日期, ISNULL(实际展示区完工日期, GETDATE()))
                                                        END) DESC) AS 序号 ,
                            '华南公司' AS 公司名称 ,
                            项目名称 ,
                            计划组团名称 ,
                            开放情况,
                            计划展示区完工日期 ,
                            实际展示区完工日期 ,
                            --关联工程楼栋 ,
                            CASE WHEN DATEDIFF(YEAR, 计划展示区完工日期, GETDATE()) = 0 THEN 1 ELSE 0 END AS 本年计划展示区完工批次 ,
                            CASE WHEN DATEDIFF(YEAR, 计划展示区完工日期, GETDATE()) = 0 and  开放情况 like '%已开放%'  THEN 1 ELSE 0 END AS 本年展示区已完工批次 ,
                            CASE WHEN DATEDIFF(MONTH, 计划展示区完工日期, GETDATE()) = 0 THEN 1 ELSE 0 END AS 本月计划展示区完工批次 ,
                            CASE WHEN DATEDIFF(MONTH, 计划展示区完工日期, GETDATE()) = 0 and 开放情况 like '%逾期未开放%' THEN 1 ELSE 0 END AS 本月逾期批次 ,
                            CASE WHEN DATEDIFF(MONTH, 计划展示区完工日期, GETDATE()) = 0 and 开放情况 like '%已开放%' THEN 1 ELSE 0 END AS 本月展示区已完工批次 ,
                            CASE WHEN DATEDIFF(YEAR, 计划展示区完工日期, GETDATE()) = 0  and 开放情况 like '%逾期未开放%'  THEN
                                     DATEDIFF(MONTH, 计划展示区完工日期, GETDATE())
                            END AS 延期月
                     FROM   data_tb_data_tb_hn_ShowAreaNodePlan a
                            OUTER APPLY(SELECT  TOP 1   batch_id
                                        FROM    data_tb_data_tb_hn_ShowAreaNodePlan
                                        ORDER BY batch_update_time DESC) px
                     WHERE  a.batch_id = px.batch_id) t ),
       -- 两翼指标
        #ly as (
                SELECT
                    序号,
                    项目名称 + '-' + 计划经营楼栋 + 业态类型 + '开业：原节点' + CONVERT(VARCHAR(10), 计划开业日期, 121) + '，已逾期超' + CONVERT(VARCHAR(10), ISNULL(延期月, 0)) + '个月' + ';' AS 简讯内容,
                    CASE
                        WHEN t.序号 <= 10 THEN '是'
                        ELSE '否'
                    END AS 短讯是否显示,
                    公司名称,
                    项目名称,
                    计划经营楼栋,
                    逾期风险等级,
                    业态类型,
                    计划开业日期,
                    实际开业日期,
                    本年计划开业套数,
                    本年已开业套数,
                    本月计划开业套数,
					本月已开业套数,
                    本月逾期开业套数,
                    延期月
                    FROM
                    (
                        SELECT
                            ROW_NUMBER() OVER (
                                ORDER BY
                                    (
                                        CASE
                                            WHEN DATEDIFF(YEAR, 计划开业日期, GETDATE()) = 0
                                            AND DATEDIFF(DAY, 计划开业日期, GETDATE()) >= 0
                                            AND 实际开业日期 IS NULL THEN DATEDIFF(MONTH, 计划开业日期, ISNULL(实际开业日期, GETDATE()))
                                        END
                                    ) DESC
                            ) AS 序号,
                            '华南公司' AS 公司名称,
                            项目名称,
                            计划经营楼栋,
                            逾期风险等级,
                            业态类型,
                            计划开业日期,
                            实际开业日期,
                            CASE
                                WHEN DATEDIFF(YEAR, 计划开业日期, GETDATE()) = 0 THEN 本年开业套数
                                ELSE 0
                            END AS 本年计划开业套数,
                            CASE
                                WHEN DATEDIFF(YEAR, 实际开业日期, GETDATE()) = 0 THEN 本年开业套数
                                ELSE 0
                            END AS 本年已开业套数,
                            CASE
                                WHEN DATEDIFF(MONTH, 计划开业日期, GETDATE()) = 0 THEN 本年开业套数
                                ELSE 0
                            END AS 本月计划开业套数,
                            CASE
                                WHEN DATEDIFF(MONTH, 计划开业日期, GETDATE()) = 0
                                AND DATEDIFF(DAY, 计划开业日期, GETDATE()) >= 0
                                AND 实际开业日期 IS NULL THEN 本年开业套数
                                ELSE 0
                            END AS 本月逾期开业套数,
                            CASE
                                WHEN DATEDIFF(MONTH, 实际开业日期, GETDATE()) = 0 THEN 本年开业套数
                                ELSE 0
                            END AS 本月已开业套数,
                            CASE
                                WHEN DATEDIFF(YEAR, 计划开业日期, GETDATE()) = 0
                                AND DATEDIFF(DAY, 计划开业日期, GETDATE()) >= 0
                                AND 实际开业日期 IS NULL THEN DATEDIFF(MONTH, 计划开业日期, ISNULL(实际开业日期, GETDATE()))
                            END AS 延期月
                        FROM
                            data_tb_hn_TwoWingNodePlan a
                            OUTER APPLY(
                                SELECT
                                    TOP 1 batch_id
                                FROM
                                    data_tb_hn_TwoWingNodePlan
                                ORDER BY
                                    batch_update_time DESC
                            ) px
                        WHERE
                            a.batch_id = px.batch_id
                    ) t
        )

--查询结果
SELECT --ISNULL(t1.公司名称, t2.公司名称) AS 公司名称 ,
		DATEPART(YY, GETDATE()) AS 年份 ,
		DATEPART(mm, GETDATE()) AS 月份 ,
		t1.本年计划开工面积 ,
		t1.本年已开工面积 ,
		t1.本年开工完成率 ,
		t1.本月计划开工面积 ,
		t1.本月已开工面积 ,
		t1.本月逾期未开工面积 ,
		t1.本月开工完成率 ,
		t2.本年计划供货面积 ,
		t2.本年已供货面积 ,
		t2.本年供货完成率 ,
		t2.本月计划供货面积 ,
		t2.本月已供货面积 ,
		t2.本月逾期未供货面积 ,
		t2.本月供货完成率 ,
		
        t3.本年计划展示区完工批次 ,
		t3.本年展示区已完工批次 ,
		t3.本年计划展示区完成率 ,
		t3.本月计划展示区完工批次 ,
		t3.本月展示区已完工批次 ,
		t3.本月逾期批次 ,
		t3.本月计划展示区完成率,

        t4.本年计划开业套数,
        t4.本年已开业套数,
        t4.本年计划开业完成率,
        t4.本月计划开业套数,
        t4.本月已开业套数,
        t4.本月逾期开业套数,
        t4.本月计划开业完成率
FROM(SELECT 公司名称 ,
            SUM(ISNULL(本年计划开工面积, 0)) AS 本年计划开工面积 ,
            SUM(ISNULL(本年已开工面积, 0)) AS 本年已开工面积 ,
            CASE WHEN SUM(ISNULL(本年计划开工面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年已开工面积, 0)) / SUM(ISNULL(本年计划开工面积, 0))END AS 本年开工完成率 ,
            SUM(ISNULL(本月计划开工面积, 0)) AS 本月计划开工面积 ,
            SUM(ISNULL(本月已开工面积, 0)) AS 本月已开工面积 ,
            SUM(ISNULL(本月逾期未开工面积, 0)) AS 本月逾期未开工面积 ,
            CASE WHEN SUM(ISNULL(本月计划开工面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本月已开工面积, 0)) / SUM(ISNULL(本月计划开工面积, 0))END AS 本月开工完成率
     FROM   #kg
     GROUP BY 公司名称) t1
    JOIN(SELECT 公司名称 ,
                SUM(ISNULL(本年计划供货面积, 0)) AS 本年计划供货面积 ,
                SUM(ISNULL(本年已供货面积, 0)) AS 本年已供货面积 ,
                CASE WHEN SUM(ISNULL(本年计划供货面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年已供货面积, 0)) / SUM(ISNULL(本年计划供货面积, 0))END AS 本年供货完成率 ,
                SUM(ISNULL(本月计划供货面积, 0)) AS 本月计划供货面积 ,
                SUM(ISNULL(本月已供货面积, 0)) AS 本月已供货面积 ,
                SUM(ISNULL(本月逾期未供货面积, 0)) AS 本月逾期未供货面积 ,
                CASE WHEN SUM(ISNULL(本月计划供货面积, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本月已供货面积, 0)) / SUM(ISNULL(本月计划供货面积, 0))END AS 本月供货完成率
         FROM   #gh
         GROUP BY 公司名称) t2 ON t1.公司名称 = t2.公司名称
    JOIN(
        SELECT 公司名称 ,
                SUM(ISNULL(本年计划展示区完工批次, 0)) AS 本年计划展示区完工批次 ,
                SUM(ISNULL(本年展示区已完工批次, 0)) AS 本年展示区已完工批次 ,
                CASE WHEN SUM(ISNULL(本年计划展示区完工批次, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年展示区已完工批次, 0)) *1.0/ SUM(ISNULL(本年计划展示区完工批次, 0))END AS 本年计划展示区完成率 ,
                SUM(ISNULL(本月计划展示区完工批次, 0)) AS 本月计划展示区完工批次 ,
                SUM(ISNULL(本月展示区已完工批次, 0)) AS 本月展示区已完工批次 ,
                SUM(ISNULL(本月逾期批次, 0)) AS 本月逾期批次 ,
                CASE WHEN SUM(ISNULL(本月计划展示区完工批次, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本月展示区已完工批次, 0)) *1.0 / SUM(ISNULL(本月计划展示区完工批次, 0))END AS 本月计划展示区完成率
         FROM   #zsq
         GROUP BY 公司名称) t3 ON t1.公司名称 = t3.公司名称
    join (
        SELECT 公司名称 ,
                SUM(ISNULL(本年计划开业套数, 0)) AS 本年计划开业套数 ,
                SUM(ISNULL(本年已开业套数, 0)) AS 本年已开业套数 ,
                CASE WHEN SUM(ISNULL(本年计划开业套数, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本年已开业套数, 0)) *1.0/ SUM(ISNULL(本年计划开业套数, 0))END AS 本年计划开业完成率 ,
                SUM(ISNULL(本月计划开业套数, 0)) AS 本月计划开业套数 ,
                SUM(ISNULL(本月已开业套数, 0)) AS 本月已开业套数 ,
                SUM(ISNULL(本月逾期开业套数, 0)) AS 本月逾期开业套数 ,
                CASE WHEN SUM(ISNULL(本月计划开业套数, 0)) = 0 THEN 0 ELSE SUM(ISNULL(本月已开业套数, 0)) *1.0 / SUM(ISNULL(本月计划开业套数, 0))END AS 本月计划开业完成率
         FROM   #ly
         GROUP BY 公司名称) t4 ON t1.公司名称 = t4.公司名称            
WHERE   1 = 1