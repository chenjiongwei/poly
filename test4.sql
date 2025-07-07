-- data_tb_hn_yxpq



-- SELECT
--     pp.buguid as 公司GUID,
--     pp.projguid as 项目GUID,
--     ny.Years as 年份,
--     ny.Months as 月份,
--     tb.营销事业部 AS 片区,
--     tb.营销片区 AS 组团,
--     tb.项目简称 as 项目简称,
--     f.平台公司 AS 平台公司,
--     f.项目代码 AS 项目代码,
--     f.投管代码 AS 投管代码,
--     f.项目名 AS 项目名,
--     f.推广名 AS 推广名,
--     tb.区域负责人 项目责任人,
--     rg.总认购套数 AS 总认购套数,
--     rg.总认购金额 总认购金额,
--     rg.逾期录入认购套数 逾期录入套数,
--     rg.逾期录入认购金额 逾期录入金额,
--     case when rg.总认购套数 = 0 then 0 else rg.逾期录入认购套数/rg.总认购套数 end as 逾期录入率,
--     rg.逾期转签约套数 as 逾期签约套数,
--     rg.逾期转签约金额 as 逾期签约金额,
--     case when rg.总认购套数 = 0 then 0 else rg.逾期转签约套数/rg.总认购套数 end as  逾期签约率,
--     qy.总签约套数 as 总签约套数,
--     qy.总签约金额 as 总签约金额,
--     qytf.总签约套数 as 签约后退房套数,
--     qytf.总签约金额 as 签约后退房金额,
--     CASE WHEN qy.总签约套数 = 0 THEN 0 ELSE qytf.总签约套数/qy.总签约套数 END as 退房率,
--     qyhf.总签约套数 as 换房套数,
--     qyhf.总签约金额 as 换房金额,
--     rg.本月认购套数 as 线上认购套数
-- FROM  p_project pp 
-- LEFT JOIN vmdm_projectFlag f ON pp.ProjGUID = f.ProjGUID
-- LEFT JOIN [172.16.4.161].[HighData_prod].dbo.data_tb_hn_yxpq tb ON pp.ProjGUID = tb.项目GUID
-- -- 生成一个临时表，用于存储年份和月份，起始年份为2009年，终止年份为本年
-- LEFT JOIN(
--      SELECT 
--           YEAR(DATEADD(MONTH, v.number, '2009-01-01')) as Years,
--           MONTH(DATEADD(MONTH, v.number, '2009-01-01')) as Months
--      FROM master..spt_values v
--      WHERE v.type = 'P'
--      AND v.number >= 0
--      AND DATEADD(MONTH, v.number, '2009-01-01') <= EOMONTH(GETDATE())
-- ) ny on 1 = 1
-- --认购内容
-- LEFT JOIN (
--     SELECT 
--         YEAR(a.qsdate) as Years,
--         Month(a.qsdate) as Months,
--         pp.ProjGUID,
--         count(distinct a.RoomGUID) as 总认购套数,
--         sum(case when sb.BillGUID is not null then 1 else 0 end) as 本月认购套数,
--         sum(a.JyTotal) as 总认购金额,
--         sum(CASE WHEN DATEDIFF(dd,a.qsdate,a.CreatedOn)>3 THEN 1 ELSE 0 END) as  逾期录入认购套数,
--         sum(CASE WHEN DATEDIFF(dd,a.qsdate,a.CreatedOn)>3 THEN a.JyTotal ELSE 0 END) as 逾期录入认购金额,
--         sum(CASE WHEN DATEDIFF(dd,  a.qsdate, ISNULL(a.closedate, GETDATE()))>15 THEN 1 ELSE 0 END) as 逾期转签约套数,
--         sum(CASE WHEN DATEDIFF(dd,  a.qsdate, ISNULL(a.closedate, GETDATE()))>15 THEN a.JyTotal ELSE 0 END) as 逾期转签约金额
--     FROM s_order a
--     LEFT JOIN s_Order b on a.LastSaleGUID = b.OrderGUID and (b.CloseReason = '换房' or b.closereason = '折扣变更')
--     LEFT JOIN s_contract c on a.LastSaleGUID = c.contractguid and c.CloseReason = '换房'
--     LEFT JOIN ep_room r ON a.RoomGUID = r.RoomGUID
--     LEFT JOIN p_project p ON a.projguid = p.projguid
--     LEFT JOIN p_project pp ON pp.projcode = p.parentcode AND pp.applysys LIKE '%0101%'
--     LEFT JOIN s_SubscriptionBook sb ON sb.BillGUID =a.OrderGUID and sb.State ='已完成'
--     WHERE YEAR(a.qsdate) = YEAR(GETDATE())
--         AND
--         (
--             a.status = '激活'
--             OR ISNULL(a.CloseReason, '') = '转签约'
--             OR isnull(a.CloseReason,'') = '换房' 
--             OR ISNULL(a.CloseReason,'') = '折扣变更'
--         )
--         and (b.OrderGUID is null and c.contractguid is null)
--         and a.buguid in ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF') --华南公司
--     GROUP BY YEAR(a.qsdate), Month(a.qsdate), pp.ProjGUID
-- ) rg on rg.ProjGUID = pp.ProjGUID and rg.Years = ny.Years and rg.Months = ny.Months
-- LEFT JOIN (
--     SELECT pp.projguid,
--        COUNT(c.RoomGUID) AS 总签约套数,
--        SUM(c.JyTotal + ISNULL(bck.amount, 0)) AS 总签约金额,
--        YEAR(c.qsdate) AS Years,
--        Month(c.qsdate) AS Months
--     FROM s_Contract c
--     LEFT JOIN ep_room r ON c.RoomGUID = r.RoomGUID
--     LEFT JOIN p_project p ON c.projguid = p.projguid
--     LEFT JOIN p_project pp ON pp.projcode = p.parentcode AND pp.applysys LIKE '%0101%'
--     LEFT JOIN vmdm_projectFlag f ON pp.ProjGUID = f.ProjGUID
--     LEFT JOIN
--     (
--         SELECT f.TradeGUID,
--             SUM(Amount) amount
--         FROM s_Fee f
--         WHERE f.ItemName LIKE '%补差%'
--         GROUP BY f.TradeGUID
--     ) bck ON c.TradeGUID = bck.TradeGUID
--     WHERE ( c.status = '激活' OR c.CloseReason = '退房') 
--         AND c.buguid in ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF')
--     GROUP BY pp.projguid, YEAR(c.qsdate), Month(c.qsdate)
-- ) qy on qy.projguid = pp.projguid and qy.Years = ny.Years and qy.Months = ny.Months
-- LEFT JOIN (
--     SELECT pp.projguid,
--        COUNT(c.RoomGUID) AS 总签约套数,
--        SUM(c.JyTotal + ISNULL(bck.amount, 0)) AS 总签约金额,
--        YEAR(c.closedate) AS Years,
--        Month(c.closedate) AS Months
--     FROM s_Contract c
--     LEFT JOIN ep_room r ON c.RoomGUID = r.RoomGUID
--     LEFT JOIN p_project p ON c.projguid = p.projguid
--     LEFT JOIN p_project pp ON pp.projcode = p.parentcode AND pp.applysys LIKE '%0101%'
--     LEFT JOIN vmdm_projectFlag f ON pp.ProjGUID = f.ProjGUID
--     LEFT JOIN
--     (
--         SELECT f.TradeGUID,
--             SUM(Amount) amount
--         FROM s_Fee f
--         WHERE f.ItemName LIKE '%补差%'
--         GROUP BY f.TradeGUID
--     ) bck ON c.TradeGUID = bck.TradeGUID
--     WHERE c.CloseReason = '退房'
--         AND c.buguid in ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF')
--     GROUP BY pp.projguid, YEAR(c.closedate), Month(c.closedate)
-- ) qytf on qytf.projguid = pp.projguid and qytf.Years = ny.Years and qytf.Months = ny.Months
-- LEFT JOIN (
--     SELECT pp.projguid,
--        COUNT(c.RoomGUID) AS 总签约套数,
--        SUM(c.JyTotal + ISNULL(bck.amount, 0)) AS 总签约金额,
--        YEAR(c.closedate) AS Years,
--        Month(c.closedate) AS Months
--     FROM s_Contract c
--     LEFT JOIN ep_room r ON c.RoomGUID = r.RoomGUID
--     LEFT JOIN p_project p ON c.projguid = p.projguid
--     LEFT JOIN p_project pp ON pp.projcode = p.parentcode AND pp.applysys LIKE '%0101%'
--     LEFT JOIN vmdm_projectFlag f ON pp.ProjGUID = f.ProjGUID
--     LEFT JOIN
--     (
--         SELECT f.TradeGUID,
--             SUM(Amount) amount
--         FROM s_Fee f
--         WHERE f.ItemName LIKE '%补差%'
--         GROUP BY f.TradeGUID
--     ) bck ON c.TradeGUID = bck.TradeGUID
--     WHERE c.CloseReason = '换房'
--         AND c.buguid in ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF')
--     GROUP BY pp.projguid, YEAR(c.closedate), Month(c.closedate)
-- ) qyhf on qyhf.projguid = pp.projguid and qyhf.Years = ny.Years and qyhf.Months = ny.Months
-- WHERE pp.buguid in ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF') --华南公司
--     AND pp.applysys LIKE '%0101%'
--     AND pp.level = 2


--逾期签约率红黑榜
-- 查询结果
SELECT *,
    /*
    入榜规则：年度有认购项目
    红榜评分规则：
    红榜 <=10%
    黑榜评分规则：
    黑榜 >10%
    */
    CASE 
        WHEN 总认购套数 > 0 AND 逾期签约率 <= 0.1 THEN 
            -- 红榜评分
            CASE 
                WHEN 逾期签约率 <= 0.1 AND 逾期签约率 > 0.005 THEN '及格'
                WHEN 逾期签约率 <= 0.005 AND 逾期签约率 > 0 THEN '良好'
                WHEN 逾期签约率 <= 0 THEN '优秀'                      
            END 
        ELSE  
            -- 黑榜评分
            CASE  
                WHEN 逾期签约率 > 0.3 THEN '严重不及格'
                WHEN 逾期签约率 > 0.1 AND 逾期签约率 <= 0.3 THEN '不及格'
            END 
    END AS 评分,
    CASE 
        WHEN 总认购套数 > 0 AND 逾期签约率 <= 0.1 THEN '红榜' 
        ELSE '黑榜' 
    END 红黑榜
INTO #ztfl
FROM (
    SELECT 
        片区,
        组团,
        推广名,
        项目责任人,
        项目简称,
        SUM(总认购套数) AS 总认购套数,
        SUM(逾期签约套数) AS 逾期签约套数,
        CASE 
            WHEN SUM(总认购套数) = 0 THEN 0 
            ELSE SUM(逾期签约套数)/SUM(总认购套数) 
        END AS 逾期签约率
    FROM data_wide_dws_s_nkfx
    WHERE 年份 = YEAR(GETDATE())
    GROUP BY 片区, 组团, 推广名, 项目责任人,项目简称
    HAVING SUM(总认购套数) > 0
) t  

-- 排序
SELECT  
    t.*,
    CASE 
        WHEN 正序 = 1 THEN 1 
        WHEN 正序 = 2 THEN 2
        WHEN 正序 = 3 THEN 3
        WHEN 倒序 = 3 THEN 6
        WHEN 倒序 = 2 THEN 5
        WHEN 倒序 = 1 THEN 4
        WHEN 正序 > 3 THEN 正序 + 3  -- 首先是红榜前三，然后是黑榜后三，然后才正常排序
    END AS 排序,
    CASE 
        WHEN 倒序 = 1 THEN '倒数第一'
        WHEN 倒序 = 2 THEN '倒数第二'   
        WHEN 倒序 = 3 THEN '倒数第三' 
        ELSE CONVERT(VARCHAR(20), 正序) 
    END AS 序号
FROM (
    SELECT 
        *,
        ROW_NUMBER() OVER(ORDER BY 总认购套数 DESC, 红黑榜 DESC, 逾期签约率) AS 正序,
        ROW_NUMBER() OVER(ORDER BY 红黑榜, 逾期签约率 DESC) AS 倒序
    FROM #ztfl 
) t
WHERE 1=1
    AND ((${var_biz} IN ('全部区域','全部项目','全部组团')) --若前台选择"全部区域"、"全部项目"、"全部组团"，则按照公司来统计
    OR (${var_biz} = t.片区) --前台选择了具体某个区域
    OR (${var_biz} = t.组团) --前台选择了具体某个组团
    OR (${var_biz} = t.推广名)) --前台选择了具体某个项目 

DROP TABLE #ztfl;