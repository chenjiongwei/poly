USE [HighData_prod]
GO
    /****** Object:  StoredProcedure [dbo].[usp_s_hnxmkb_ylgh_sj]    Script Date: 2025/8/20 14:37:02 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
    -- =============================================
    -- Author:		<Author,,jiangst>
    -- Create date: <Create Date,,2021-06-09>
    -- Description:	<Description,,华南营销小屏-片区维度签约情况> 
-- 增加索引
-- -- 主要查询和过滤条件字段
-- CREATE INDEX IX_F080008_Main ON data_wide_qt_F080008Calc_IRRNPV (实体分期无聚合, 版本, 现金流月份, IRRNPV科目);
-- -- 如果VALUE_STRING经常用于过滤，也可以考虑添加
-- CREATE INDEX IX_F080008_ValueString ON data_wide_qt_F080008Calc_IRRNPV (VALUE_STRING);
-- CREATE INDEX IX_ProjGUID_Main ON data_wide_dws_ys_ProjGUID (YLGHProjGUID, isbase, BUGUID)
-- CREATE INDEX IX_F200003_Main ON data_wide_qt_F200003 (实体分期, 轮循归档科目, value_string);
    -- =============================================
ALTER PROCEDURE [dbo].[usp_s_hnxmkb_ylgh_sj] 
AS 
BEGIN
   SET NOCOUNT ON;

    --取现金流回正时间、收回股东投资时间---------------------------
    --删除临时表
    --取现金流回正时间、收回股东投资时间---------------------------
    --删除临时表
    --将累计现金流量插入到临时表
    SELECT
        实体分期无聚合,
        IRRNPV科目,
        CONVERT(DECIMAL(22, 2), f08.VALUE_STRING) VALUE_STRING,
        CONVERT(INT, REPLACE(REPLACE(现金流月份, '第', ''), '月', '')) AS 月份 
    INTO #tmp1
    FROM
        [data_wide_qt_F080008Calc_IRRNPV] f08 WITH(NOLOCK)
        INNER JOIN (
            SELECT
                实体分期,
                MAX(value_string) AS value_string
            FROM data_wide_qt_F200003 F200003 WITH(NOLOCK)
                 INNER JOIN data_wide_dws_ys_ProjGUID pj WITH(NOLOCK)  ON pj.YLGHProjGUID = F200003.实体分期 AND pj.isbase = 1
            WHERE
                轮循归档科目 = '归档源版本' AND pj.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' -- 华南公司
            GROUP BY
                实体分期
        ) f02 ON f02.实体分期 = f08.实体分期无聚合
        AND f02.value_string = f08.版本
    WHERE
        现金流月份 <> '不区分月份'
        AND IRRNPV科目 IN ('自有资金现金流量', '经营性现金流量')
        AND CHARINDEX('e', ISNULL(f08.VALUE_STRING, '0')) = 0
        AND (
            CONVERT(DECIMAL(22, 2), f08.VALUE_STRING) > 0.01
            OR CONVERT(DECIMAL(22, 2), f08.VALUE_STRING) < -0.01
        );



    --获取第一次回正的时间
    --删除临时表
    --DROP TABLE #proj_hz;
    SELECT
        实体分期无聚合,
        IRRNPV科目,
        MIN(t.月份) AS 月份 INTO #proj_hz
    FROM
        (
            SELECT
                t1.实体分期无聚合,
                t1.月份,
                t1.IRRNPV科目,
                SUM(t2.VALUE_STRING) AS VALUE_STRING
            FROM
                #tmp1 t1 WITH(NOLOCK)
                LEFT JOIN #tmp1 t2 WITH(NOLOCK)
                ON t2.实体分期无聚合 = t1.实体分期无聚合
                AND t1.月份 >= t2.月份
                AND t2.IRRNPV科目 = t1.IRRNPV科目
            GROUP BY
                t1.实体分期无聚合,
                t1.月份,
                t1.IRRNPV科目
        ) t
    WHERE  VALUE_STRING > 0
    GROUP BY
        t.实体分期无聚合,
        IRRNPV科目;

    -- 获取现金流跟自有资金回正的时间
    --drop table #hz_date
    SELECT
        t.ProjGUID,
        MAX(
            CASE
                WHEN hz.IRRNPV科目 = '经营性现金流量' THEN CONVERT(
                    char(10),
                    dateadd(month, CONVERT(INT, 月份), t.BeginDate),
                    120
                )
                ELSE NULL
            END
        ) AS 经营性现金流回正时间,
        MAX(
            CASE
                WHEN hz.IRRNPV科目 = '自有资金现金流量' THEN CONVERT(
                    char(10),
                    dateadd(month, CONVERT(INT, 月份), t.BeginDate),
                    120
                )
                ELSE NULL
            END
        ) AS 自有资金现金流量回正时间 INTO #hz_date
    FROM
        (
            SELECT
                pj.ProjGUID,
                pj.YLGHProjGUID,
                p.BeginDate
            FROM
                dbo.data_wide_dws_ys_ProjGUID pj WITH(NOLOCK)
                INNER JOIN data_wide_dws_mdm_Project p WITH(NOLOCK) ON p.ProjGUID = pj.ProjGUID
            WHERE
                pj.isbase = 1
                AND pj.Level = 3
            GROUP BY
                pj.ProjGUID,
                p.BeginDate,
                pj.YLGHProjGUID
        ) t
        LEFT JOIN #proj_hz hz WITH(NOLOCK)
        ON t.YLGHProjGUID = hz.实体分期无聚合
    GROUP BY
        t.ProjGUID

    -- 删除    
    DELETE FROM s_hnxmkb_ylgh_sj WHERE  1 = 1;
    -- 插入
    INSERT INTO  s_hnxmkb_ylgh_sj
    SELECT    *  FROM  #hz_date;

    -- 删除临时表
    DROP TABLE #tmp1,#hz_date,#proj_hz;
    
    -- 返回查询结果
    SELECT * FROM s_hnxmkb_ylgh_sj;

END