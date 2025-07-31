
-- data_wide_dws_s_nkfx
-- 华南公司内控分析（认购录入逾期签约逾期及退房信息）

--- /// 跨年退换房
declare @var_BgnDate datetime =DATEADD(yy, DATEDIFF(yy,0,getdate()), 0)   
declare @var_EndDate datetime = getdate()

SELECT ISNULL(c.TradeGUID,o.TradeGUID)  TradeGUID,rs.ApplyDate 
INTO #rsroom
		FROM rptvs_SaleModiLog_ByRoom rs with(nolock)    
		LEFT JOIN s_Contract c with(nolock)  ON rs.ForeRoomroomguid = c.RoomGUID AND  rs.ForeSaleGUID = c.ContractGUID
        LEFT JOIN s_Order o with(nolock)   ON rs.ForeRoomroomguid = o.RoomGUID AND rs.ForeSaleGUID = o.OrderGUID
		WHERE   rs.ApplyType != '退号' 
       --  AND rs.ProjGUID IN ( @var_ProjGUID) 
        AND rs.ApplyDate >= ( @var_BgnDate ) 
        AND rs.ApplyDate <= ( @var_EndDate)
		AND ISNULL(c.TradeGUID,o.TradeGUID)  IS NOT null
        and rs.buguid in ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF')

SELECT  b.buguid as '公司GUID',
        pp.parentprojguid AS '项目GUID' ,
        b.ProjGUID AS '项目分期GUID' ,
        b.ProjName AS '项目分期名称' ,
        b.ForeRoomInfo AS '房间' ,
        b.ForeArea AS '房间面积' ,
        isnull(o.QSDate,oc.qsdate) AS '认购日期' ,
        c.HtType AS '合同类型' ,
        b.ForePayformName AS '付款方式' ,
        --isnull(g.截止入参回款,g1.截止入参回款) AS '变更前累计交款金额' ,
        b.ForeRmbHtTotal AS '成交总价' ,
        a.cs AS '变更次数' ,
        b.OrderType AS '协议类型' ,
        b.ApplyType AS '变更类型' ,
        b.oldQsDate AS '签署日期' ,
        b.CstName AS '客户名称' ,
        b.ApproveBy AS '批准人' ,
        b.ApproveDate AS '批准日期' ,
        b.ApplyDate AS '执行日期' ,
        b.Reason AS '变更原因' ,
        b.ForeRoomstatus AS '状态' ,
        sa.BgType AS '类型' ,
        b.CstSource AS '客户来源' ,
        r.BusinessType '产品类型' ,
        CASE WHEN tsyj.RoomGUID IS NOT NULL THEN '是' ELSE '否' END AS '是否特殊业绩房间'
into #kntjthf
FROM    rptvs_SaleModiLog_ByRoom b with(nolock)
        LEFT JOIN es_SaleModiApply sa with(nolock) ON b.ForeRoomroomguid = sa.RoomGUID AND  b.ApplyType = sa.ApplyType AND  b.ApplyDate = sa.ApplyDate AND  b.ApplyBy = sa.ApplyBy AND  b.ApproveBy = sa.ApproveBy
        LEFT JOIN mdm_project pp with(nolock) ON b.ProjGUID = pp.ProjGUID
        LEFT JOIN dbo.p_room r with(nolock) ON r.RoomGUID = b.ForeRoomroomguid
        LEFT JOIN s_Contract c with(nolock) ON b.ForeRoomroomguid = c.RoomGUID AND  b.ForeSaleGUID = c.ContractGUID
        left join s_Order oc with(nolock) on c.lastsaleguid=oc.OrderGUID
        LEFT JOIN s_Order o with(nolock) ON b.ForeRoomroomguid = o.RoomGUID AND b.ForeSaleGUID = o.OrderGUID
        -- LEFT JOIN #getin g with(nolock) ON c.TradeGUID=g.TradeGUID
        -- LEFT JOIN #getin g1 with(nolock) ON o.TradeGUID=g1.TradeGUID
        LEFT JOIN(SELECT    DISTINCT BUGUID ,
                                     ParentProjGUID projguid ,
                                     RoomGUID
                  FROM  [172.16.4.161].HighData_prod.dbo.data_wide_s_SpecialPerformance with(nolock)) tsyj ON tsyj.RoomGUID = r.RoomGUID
        LEFT JOIN(SELECT    ForeRoomInfo ,
                            COUNT(ForeRoomInfo) AS cs
                  FROM  rptvs_SaleModiLog_ByRoom with(nolock)
                  WHERE ApplyType != '退号' 
				  --AND ProjGUID IN ( @var_ProjGUID) 
				  AND ApplyDate >= ( @var_BgnDate) AND ApplyDate <= ( @var_EndDate)
                  GROUP BY ForeRoomInfo) a ON a.ForeRoomInfo = b.ForeRoomInfo
WHERE   b.ApplyType != '退号' 
--AND b.ProjGUID IN ( @var_ProjGUID) 
AND b.ApplyDate >= ( @var_BgnDate) AND b.ApplyDate <= ( @var_EndDate) 
and b.buguid in ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF') 
ORDER BY b.ProjName ,
         b.ForeRoomInfo ,
         a.cs;


SELECT
    pp.buguid as 公司GUID,
    pp.projguid as 项目GUID,
    ny.Years as 年份,
    ny.Months as 月份,
    tb.营销事业部 AS 片区,
    tb.营销片区 AS 组团,
    tb.项目简称 as 项目简称,
    f.平台公司 AS 平台公司,
    f.项目代码 AS 项目代码,
    f.投管代码 AS 投管代码,
    f.项目名 AS 项目名,
    f.推广名 AS 推广名,
    tb.项目负责人 as 项目责任人,
    rg.总认购套数 AS 总认购套数,
    rg.总认购金额 总认购金额,
    rg.逾期录入认购套数 逾期录入套数,
    rg.逾期录入认购金额 逾期录入金额,
    case when rg.总认购套数 = 0 then 0 else rg.逾期录入认购套数/rg.总认购套数 end as 逾期录入率,
    rg.逾期转签约套数 as 逾期签约套数,
    rg.逾期转签约金额 as 逾期签约金额,
    case when rg.总认购套数 = 0 then 0 else rg.逾期转签约套数/rg.总认购套数 end as  逾期签约率,
    qy.总签约套数 as 总签约套数,
    qy.总签约金额 as 总签约金额,
    qytf.总签约套数 as 签约后退房套数,
    qytf.总签约金额 as 签约后退房金额,
    CASE WHEN qy.总签约套数 = 0 THEN 0 ELSE qytf.总签约套数/qy.总签约套数 END as 退房率,
    qyhf.总签约套数 as 换房套数,
    qyhf.总签约金额 as 换房金额,
    rg.本月认购套数 as 线上认购套数,
    kntjthf.跨年签约后退房套数,
    kntjthf.跨年签约后退房金额,
    kntjthf.跨年换房套数,
    kntjthf.跨年换房金额,
    bntjthf.本年签约后退房套数,
    bntjthf.本年签约后退房金额,
    bntjthf.本年签约后换房套数,
    bntjthf.本年签约后换房金额
FROM  p_project pp 
LEFT JOIN vmdm_projectFlag f ON pp.ProjGUID = f.ProjGUID
LEFT JOIN [172.16.4.161].[HighData_prod].dbo.data_tb_hn_yxpq tb ON pp.ProjGUID = tb.项目GUID
-- 生成一个临时表，用于存储年份和月份，起始年份为2009年，终止年份为本年
LEFT JOIN(
     SELECT 
          YEAR(DATEADD(MONTH, v.number, '2009-01-01')) as Years,
          MONTH(DATEADD(MONTH, v.number, '2009-01-01')) as Months
     FROM master..spt_values v
     WHERE v.type = 'P'
     AND v.number >= 0
     AND DATEADD(MONTH, v.number, '2009-01-01') <= EOMONTH(GETDATE())
) ny on 1 = 1
--认购内容
LEFT JOIN (
    SELECT 
        YEAR(a.qsdate) as Years,
        Month(a.qsdate) as Months,
        pp.ProjGUID,
        count(distinct a.RoomGUID) as 总认购套数,
        sum(case when sb.BillGUID is not null then 1 else 0 end) as 本月认购套数,
        sum(a.JyTotal) as 总认购金额,
        sum(CASE WHEN DATEDIFF(dd,a.qsdate,a.CreatedOn)>3 THEN 1 ELSE 0 END) as  逾期录入认购套数,
        sum(CASE WHEN DATEDIFF(dd,a.qsdate,a.CreatedOn)>3 THEN a.JyTotal ELSE 0 END) as 逾期录入认购金额,
        sum(CASE WHEN DATEDIFF(dd,  a.qsdate, ISNULL(a.closedate, GETDATE()))>15 THEN 1 ELSE 0 END) as 逾期转签约套数,
        sum(CASE WHEN DATEDIFF(dd,  a.qsdate, ISNULL(a.closedate, GETDATE()))>15 THEN a.JyTotal ELSE 0 END) as 逾期转签约金额
    FROM s_order a
    LEFT JOIN s_Order b on a.LastSaleGUID = b.OrderGUID and (b.CloseReason = '换房' or b.closereason = '折扣变更')
    LEFT JOIN s_contract c on a.LastSaleGUID = c.contractguid and c.CloseReason = '换房'
    LEFT JOIN ep_room r ON a.RoomGUID = r.RoomGUID
    LEFT JOIN p_project p ON a.projguid = p.projguid
    LEFT JOIN p_project pp ON pp.projcode = p.parentcode AND pp.applysys LIKE '%0101%'
    LEFT JOIN s_SubscriptionBook sb ON sb.BillGUID =a.OrderGUID and sb.State ='已完成'
    WHERE YEAR(a.qsdate) = YEAR(GETDATE())
        AND
        (
            a.status = '激活'
            OR ISNULL(a.CloseReason, '') = '转签约'
            OR isnull(a.CloseReason,'') = '换房' 
            OR ISNULL(a.CloseReason,'') = '折扣变更'
        )
        and (b.OrderGUID is null and c.contractguid is null)
        and a.buguid in ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF') --华南公司
    GROUP BY YEAR(a.qsdate), Month(a.qsdate), pp.ProjGUID
) rg on rg.ProjGUID = pp.ProjGUID and rg.Years = ny.Years and rg.Months = ny.Months
LEFT JOIN (
    SELECT pp.projguid,
       COUNT(c.RoomGUID) AS 总签约套数,
       SUM(c.JyTotal + ISNULL(bck.amount, 0)) AS 总签约金额,
       YEAR(c.qsdate) AS Years,
       Month(c.qsdate) AS Months
    FROM s_Contract c
    LEFT JOIN ep_room r ON c.RoomGUID = r.RoomGUID
    LEFT JOIN p_project p ON c.projguid = p.projguid
    LEFT JOIN p_project pp ON pp.projcode = p.parentcode AND pp.applysys LIKE '%0101%'
    LEFT JOIN vmdm_projectFlag f ON pp.ProjGUID = f.ProjGUID
    LEFT JOIN
    (
        SELECT f.TradeGUID,
            SUM(Amount) amount
        FROM s_Fee f
        WHERE f.ItemName LIKE '%补差%'
        GROUP BY f.TradeGUID
    ) bck ON c.TradeGUID = bck.TradeGUID
    WHERE ( c.status = '激活' OR c.CloseReason = '退房') 
        AND c.buguid in ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF')
    GROUP BY pp.projguid, YEAR(c.qsdate), Month(c.qsdate)
) qy on qy.projguid = pp.projguid and qy.Years = ny.Years and qy.Months = ny.Months
LEFT JOIN (
    SELECT pp.projguid,
       COUNT(c.RoomGUID) AS 总签约套数,
      --  SUM(c.JyTotal + ISNULL(bck.amount, 0)) AS 总签约金额,
        sum(c.JyTotal) as 总签约金额,
       YEAR(c.closedate) AS Years,
       Month(c.closedate) AS Months
    FROM s_Contract c
    LEFT JOIN ep_room r ON c.RoomGUID = r.RoomGUID
    LEFT JOIN p_project p ON c.projguid = p.projguid
    LEFT JOIN p_project pp ON pp.projcode = p.parentcode AND pp.applysys LIKE '%0101%'
    LEFT JOIN vmdm_projectFlag f ON pp.ProjGUID = f.ProjGUID
    LEFT JOIN
    (
        SELECT f.TradeGUID,
            SUM(Amount) amount
        FROM s_Fee f
        WHERE f.ItemName LIKE '%补差%'
        GROUP BY f.TradeGUID
    ) bck ON c.TradeGUID = bck.TradeGUID
    WHERE c.CloseReason = '退房'
        AND c.buguid in ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF')
    GROUP BY pp.projguid, YEAR(c.closedate), Month(c.closedate)
) qytf on qytf.projguid = pp.projguid and qytf.Years = ny.Years and qytf.Months = ny.Months
LEFT JOIN (
    SELECT pp.projguid,
       COUNT(c.RoomGUID) AS 总签约套数,
       -- SUM(c.JyTotal + ISNULL(bck.amount, 0)) AS 总签约金额,
       sum(c.JyTotal) as 总签约金额,
       YEAR(c.closedate) AS Years,
       Month(c.closedate) AS Months
    FROM s_Contract c
    LEFT JOIN ep_room r ON c.RoomGUID = r.RoomGUID
    LEFT JOIN p_project p ON c.projguid = p.projguid
    LEFT JOIN p_project pp ON pp.projcode = p.parentcode AND pp.applysys LIKE '%0101%'
    LEFT JOIN vmdm_projectFlag f ON pp.ProjGUID = f.ProjGUID
    LEFT JOIN
    (
        SELECT f.TradeGUID,
            SUM(Amount) amount
        FROM s_Fee f
        WHERE f.ItemName LIKE '%补差%'
        GROUP BY f.TradeGUID
    ) bck ON c.TradeGUID = bck.TradeGUID
    WHERE c.CloseReason = '换房'
        AND c.buguid in ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF')
    GROUP BY pp.projguid, YEAR(c.closedate), Month(c.closedate)
) qyhf on qyhf.projguid = pp.projguid and qyhf.Years = ny.Years and qyhf.Months = ny.Months
-- 跨年签约后退房套数 
LEFT JOIN (
    SELECT 项目GUID,
        YEAR(签署日期) AS 年份,
        MONTH(签署日期) AS 月份,
        SUM(CASE WHEN 变更类型 = '退房' THEN 1 ELSE 0 END) AS 跨年签约后退房套数,
        SUM(CASE WHEN 变更类型 = '退房' THEN 成交总价 ELSE 0 END) AS 跨年签约后退房金额,
        SUM(CASE WHEN 变更类型 = '换房' THEN 1 ELSE 0 END) AS 跨年换房套数,
        SUM(CASE WHEN 变更类型 = '换房' THEN 成交总价 ELSE 0 END) AS 跨年换房金额
    FROM #kntjthf 
    -- 变更执行日期为查询截止年份,且合同签署日期为查询截止日期之前
    where  year(执行日期) = year( @var_EndDate ) and  year(签署日期) < year( @var_EndDate )
      and 变更类型 in ('退房','换房') and 协议类型='合同'
    GROUP BY 项目GUID, YEAR(签署日期), MONTH(签署日期)
) kntjthf ON kntjthf.项目GUID = pp.projguid and kntjthf.年份 = ny.Years and kntjthf.月份 = ny.Months
-- 本年签约后退房套数 
LEFT JOIN (
    SELECT 项目GUID,
        YEAR(签署日期) AS 年份,
        MONTH(签署日期) AS 月份,
        SUM(CASE WHEN 变更类型 = '退房' THEN 1 ELSE 0 END) AS 本年签约后退房套数,
        SUM(CASE WHEN 变更类型 = '退房' THEN 成交总价 ELSE 0 END) AS 本年签约后退房金额,
        SUM(CASE WHEN 变更类型 = '换房' THEN 1 ELSE 0 END) AS 本年签约后换房套数,
        SUM(CASE WHEN 变更类型 = '换房' THEN 成交总价 ELSE 0 END) AS 本年签约后换房金额
    FROM #kntjthf 
    -- 变更执行日期为查询截止年份,且合同签署日期为查询截止日期之前
    where  year(执行日期) = year( @var_EndDate ) --and  year(签署日期) < year( @var_EndDate )
      and 变更类型 in ('退房','换房') and 协议类型='合同'
    GROUP BY 项目GUID, YEAR(签署日期), MONTH(签署日期)
) bntjthf ON bntjthf.项目GUID = pp.projguid and bntjthf.年份 = ny.Years and bntjthf.月份 = ny.Months
WHERE pp.buguid in ('70DD6DF4-47F7-46AF-B470-BC18EE57D8FF') --华南公司
    AND pp.applysys LIKE '%0101%'
    AND pp.level = 2

-- 删除临时表
DROP TABLE #rsroom;
DROP TABLE #kntjthf;

