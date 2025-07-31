USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_16变更房间统计表]    Script Date: 2025/7/10 11:08:58 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[usp_s_16变更房间统计表]
(   
    @var_ProjGUID UNIQUEIDENTIFIER,
    @var_bgndate VARCHAR(200),
    @var_enddate  VARCHAR(200)
)
AS
/*  
存储过程名：       [usp_s_16变更房间统计表]    
--  exec usp_s_16变更房间统计表 '82915f71-c748-ea11-80b8-0a94ef7517dd','2024-04-01','2024-04-30'
*/
BEGIN


SELECT ISNULL(c.TradeGUID,o.TradeGUID)  TradeGUID,rs.ApplyDate 
INTO #rsroom
		FROM rptvs_SaleModiLog_ByRoom   rs     
		LEFT JOIN s_Contract c ON rs.ForeRoomroomguid = c.RoomGUID AND  rs.ForeSaleGUID = c.ContractGUID
        LEFT JOIN s_Order o ON rs.ForeRoomroomguid = o.RoomGUID AND rs.ForeSaleGUID = o.OrderGUID
		WHERE   rs.ApplyType != '退号' AND rs.ProjGUID IN ( @var_ProjGUID) AND rs.ApplyDate >= ( @var_BgnDate) AND rs.ApplyDate <= ( @var_EndDate)
		AND ISNULL(c.TradeGUID,o.TradeGUID)  IS NOT null

SELECT  r.TradeGUID ,
        SUM(g.Amount) 截止入参回款
INTO    #getin
FROM    s_Getin g       
        INNER JOIN s_Trade r ON g.SaleGUID = r.TradeGUID
		INNER JOIN #rsroom t on r.TradeGUID=t.TradeGUID
WHERE   1 = 1 
AND   g.Status IS NULL 
AND g.GetDate < t.ApplyDate 
GROUP BY r.TradeGUID;

SELECT  b.ProjName AS '项目名称' ,
        b.ForeRoomInfo AS '房间' ,
        b.ForeArea AS '房间面积' ,
        isnull(o.QSDate,oc.qsdate) AS '认购日期' ,
        c.HtType AS '合同类型' ,
        b.ForePayformName AS '付款方式' ,
        isnull(g.截止入参回款,g1.截止入参回款) AS '变更前累计交款金额' ,
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
FROM    rptvs_SaleModiLog_ByRoom b
        LEFT JOIN es_SaleModiApply sa ON b.ForeRoomroomguid = sa.RoomGUID AND  b.ApplyType = sa.ApplyType AND  b.ApplyDate = sa.ApplyDate AND  b.ApplyBy = sa.ApplyBy AND  b.ApproveBy = sa.ApproveBy
        LEFT JOIN dbo.p_room r ON r.RoomGUID = b.ForeRoomroomguid
        LEFT JOIN s_Contract c ON b.ForeRoomroomguid = c.RoomGUID AND  b.ForeSaleGUID = c.ContractGUID
        left join s_Order oc on c.lastsaleguid=oc.OrderGUID
        LEFT JOIN s_Order o ON b.ForeRoomroomguid = o.RoomGUID AND b.ForeSaleGUID = o.OrderGUID
        LEFT JOIN #getin g ON c.TradeGUID=g.TradeGUID
        LEFT JOIN #getin g1 ON o.TradeGUID=g1.TradeGUID
        LEFT JOIN(SELECT    DISTINCT BUGUID ,
                                     ParentProjGUID projguid ,
                                     RoomGUID
                  FROM  [172.16.4.161].HighData_prod.dbo.data_wide_s_SpecialPerformance) tsyj ON tsyj.RoomGUID = r.RoomGUID
        LEFT JOIN(SELECT    ForeRoomInfo ,
                            COUNT(ForeRoomInfo) AS cs
                  FROM  rptvs_SaleModiLog_ByRoom
                  WHERE ApplyType != '退号' AND ProjGUID IN ( @var_ProjGUID) AND ApplyDate >= ( @var_BgnDate) AND ApplyDate <= ( @var_EndDate)
                  GROUP BY ForeRoomInfo) a ON a.ForeRoomInfo = b.ForeRoomInfo
WHERE   b.ApplyType != '退号' AND b.ProjGUID IN ( @var_ProjGUID) AND b.ApplyDate >= ( @var_BgnDate) AND b.ApplyDate <= ( @var_EndDate)
ORDER BY b.ProjName ,
         b.ForeRoomInfo ,
         a.cs;

DROP TABLE #rsroom;
DROP TABLE #getin;


END

