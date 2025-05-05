CREATE TABLE [dbo].#qtyj ([项目推广名] [NVARCHAR](255) NULL ,
                          [明源系统代码] [NVARCHAR](255) NULL ,
                          [项目代码] [NVARCHAR](255) NULL ,
                          [认定日期] DATETIME);

INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
VALUES(N'佛山保利环球汇', N'0757046', N'2937', N'2020-8-31');

INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
VALUES(N'佛山保利西山林语', N'0757056', N'2946', N'2022-5-27');

INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
VALUES(N'佛山保利紫晨花园', N'0757059', N'2950', N'2022-6-28');

INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
VALUES(N'佛山保利紫山国际', N'0757028', N'2920', N'2022-6-27');

INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
VALUES(N'茂名保利大都会', N'0668001', N'5801', N'2021-12-28');

INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
VALUES(N'茂名保利中环广场', N'0668005', N'5806', N'2021-4-26');

INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
VALUES(N'阳江保利海陵岛', N'0662002', N'1702', N'2021-5-24');

DECLARE @var_date DATETIME = '2025-04-30';

SELECT  
        t1.projguid ,
        t1.ProjName ,
        t1.TopProductTypeName ,
        t1.RoomGUID ,
        t1.RoomInfo ,
        t1.本日认购金额 ,
        t1.本日认购套数 ,
        t2.brhzje AS 本日特殊业绩认购金额 ,
        t2.brhzts AS 本日特殊业绩认购套数 ,
        t3.其他业绩本日认购金额 ,
        t3.其他业绩本日认购套数 ,
        t1.本月认购金额 ,
        t1.本月认购套数 ,
        t2.byhzje AS 本月特殊业绩认购金额 ,
        t2.byhzts AS 本月特殊业绩认购套数 ,
        t3.其他业绩本月认购金额 ,
        t3.其他业绩本月认购套数
FROM(SELECT 
            pj.ProjName ,
            pj.projguid ,
            bld.TopProductTypeName ,
            r.RoomGUID ,
            r.RoomInfo ,
            SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本月认购金额 ,
            SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本月认购套数 ,
            SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本日认购金额 ,
            SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本日认购套数
     FROM   dbo.data_wide_s_RoomoVerride r
            INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = r.BldGUID
            INNER JOIN data_wide_dws_mdm_Project pj ON r.ParentProjGUID = pj.ProjGUID
     WHERE  r.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
     GROUP BY 
              pj.ProjName ,
              pj.projguid ,
              bld.TopProductTypeName ,
              r.RoomGUID ,
              r.RoomInfo) AS t1
    LEFT JOIN(
             --如果特殊业绩类型为“代销车位”则业绩金额要双算
             SELECT s.ParentProjGUID AS projguid ,
                    bld.TopProductTypeName ,
                    r.RoomGUID ,
                    SUM(CASE WHEN DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 THEN CCjAmount
                             WHEN (s.TsyjType = '物业公司车位代销' AND  DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0) THEN r.CjRmbTotal / 10000.0
                             ELSE 0
                        END) AS byhzje ,                                                                                                                                                                -- 本月认购金额
                    SUM(CASE WHEN DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0) THEN CCjCount ELSE 0 END) AS byhzts ,   --本月认购套数
                    SUM(CASE WHEN DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjAmount
                             WHEN (s.TsyjType = '物业公司车位代销' AND  DATEDIFF(DAY, r.RgQsDate, @var_date) = 0) THEN r.CjRmbTotal / 10000.0
                             ELSE 0
                        END) AS brhzje ,                                                                                                                                                                --本日认购金额
                    SUM(CASE WHEN DATEDIFF(DAY, StatisticalDate, @var_date) = 0 OR  (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, r.RgQsDate, @var_date) = 0) THEN CCjCount ELSE 0 END) AS brhzts          --本日认购套数
             FROM   dbo.data_wide_s_SpecialPerformance s
                    LEFT JOIN data_wide_s_RoomoVerride r ON s.roomguid = r.roomguid
                    INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = s.BldGUID
             WHERE  1 = 1   --StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(@var_date)) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(@var_date)) + '-12-31'
             GROUP BY s.ParentProjGUID ,
                      bld.TopProductTypeName ,
                      r.RoomGUID) AS t2 ON t1.RoomGUID = t2.RoomGUID
    LEFT JOIN(
             --查询其他业绩的签约金额
             SELECT p.projguid ,
                    bld.TopProductTypeName ,
                    a.RoomGUID ,
                    SUM(CASE WHEN DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩本月认购金额 ,
                    SUM(CASE WHEN DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩本月认购套数 ,
                    SUM(CASE WHEN DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩本日认购金额 ,
                    SUM(CASE WHEN DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩本日认购套数
             FROM   data_wide_s_SpecialPerformance a
                    INNER JOIN data_wide_s_RoomoVerride r ON a.RoomGUID = r.RoomGUID
                    INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = r.BldGUID
                    INNER JOIN data_wide_dws_mdm_Project p ON a.ParentProjGUID = p.ProjGUID AND p.Level = 2
                    INNER JOIN #qtyj qt ON qt.明源系统代码 = p.ProjCode
             WHERE  DATEDIFF(DAY, a.[StatisticalDate], qt.认定日期) = 0 AND r.Status IN ('认购', '签约')    -- AND YEAR(r.QsDate) = YEAR(@var_date)
             GROUP BY p.projguid ,
                      bld.TopProductTypeName ,
                      a.RoomGUID) AS t3 ON t1.RoomGUID = t3.RoomGUID
WHERE  (ISNULL(t1.本月认购金额, 0) + ISNULL(t2.byhzje, 0) + ISNULL(t3.其他业绩本月认购金额, 0)) > 0;