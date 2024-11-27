-- 两翼节点手工填报数据统计
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
                AND 实际开业日期 IS NULL THEN DATEDIFF(day, 计划开业日期, ISNULL(实际开业日期, GETDATE())) /30.0
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