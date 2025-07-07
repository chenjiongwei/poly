USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_gsfkylb]    Script Date: 2025/7/3 18:40:44 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[usp_s_gsfkylb](@var_buguid VARCHAR(MAX), @var_endDate DATETIME)
AS
   /*
exec usp_s_gsfkylb_test20250425 '512381FE-A9CB-E511-80B8-E41F13C51836','2025-04-25'
公司房款一览表
2020-06-20 chenjw 增加本年签约本年回笼金额的统计
2020-12-05 yp 区分经营类特殊业绩
2021-2-23 chenjw 修改虚拟退房场景中已关闭交易单上的退款金额无法统计到的问题
2025-04-25 zhengyy 修改物业公司车位代销类型的特殊业绩统计房间回款
*/
    BEGIN
        SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

        SELECT  DISTINCT CAST(Value AS UNIQUEIDENTIFIER) BUGUID
        INTO    #B
        FROM    [dbo].[fn_Split2](@var_buguid, ',');

        CREATE UNIQUE CLUSTERED INDEX CX#B ON #B(BUGUID);

        --认购
        SELECT  es_Order.TradeGUID ,
                RoomGUID ,
                CstName ,
                BldArea ,
                QSDate AS rgDate ,
                NULL AS qyDate ,
                '认购' AS SaleType ,
                '订单' AS HtType ,
                PotocolNO AS yjNo ,
                PayformName AS PayformName ,
                Ywy ,
                ISNULL(Zygw, '') + ISNULL(Zygw2, '') + ISNULL(Zygw3, '') + ISNULL(Zygw4, '') + ISNULL(Zygw5, '') AS zygw ,
                RoomTotal ,
                ZxTotal ,
                ISNULL(bc.bcAmount, 0) + ISNULL(bc2.bcyeAmount, 0) AS bcAmount ,
                FsTotal AS FsTotal ,
                JyTotal
        INTO    #ord
        FROM    dbo.es_Order
                LEFT JOIN(SELECT    SUM(Amount) AS bcAmount ,
                                    SaleGUID
                          FROM  s_Getin
                          WHERE ItemName IN ('房款补差款', '补差款') AND   ISNULL(SaleType, '') <> '预约单'
                          GROUP BY SaleGUID) bc ON bc.SaleGUID = es_Order.TradeGUID
                LEFT JOIN(SELECT    TradeGUID ,
                                    SUM(Ye) AS bcyeAmount
                          FROM  s_Fee
                          WHERE ItemName IN ('房款补差款', '补差款')
                          GROUP BY TradeGUID) bc2 ON bc2.TradeGUID = es_Order.TradeGUID
        WHERE   OrderType = '认购' AND Status = '激活'
        --合同
        UNION
        SELECT  c.TradeGUID ,
                c.RoomGUID ,
                c.CstName ,
                c.BldArea ,
                o.QSDate AS rgDate ,
                c.QSDate AS qyDate ,
                '签约' AS SaleType ,
                c.HtType AS HtType ,
                c.ContractNO AS yjNo ,
                c.PayformName AS PayformName ,
                c.Ywy ,
                ISNULL(c.Zygw, '') + ISNULL(c.Zygw2, '') + ISNULL(c.Zygw3, '') + ISNULL(c.Zygw4, '') + ISNULL(c.Zygw5, '') AS zygw ,
                c.RoomTotal ,
                c.ZxTotal ,
                --ISNULL(bc.bcAmount, 0)
                --+ ISNULL(bc2.bcyeAmount, 0) AS bcAmount ,
                SjBcTotal AS bcAmount ,
                c.FsTotal AS FsTotal ,
                c.JyTotal
        FROM    dbo.es_Contract c
                LEFT JOIN dbo.es_Order o ON c.TradeGUID = o.TradeGUID AND  c.Status = '激活'
        --LEFT JOIN ( SELECT  SUM(Amount) AS bcAmount ,
        --                    SaleGUID
        --            FROM    s_Getin
        --            WHERE   ItemName = '房款补差款'
        --                    AND ISNULL(SaleType,
        --                          '') <> '预约单'
        --            GROUP BY SaleGUID
        --          ) bc ON bc.SaleGUID = c.TradeGUID
        --LEFT JOIN ( SELECT  TradeGUID ,
        --                    SUM(Ye) AS bcyeAmount
        --            FROM    s_Fee
        --            WHERE   ItemName = '房款补差款'
        --            GROUP BY TradeGUID
        --          ) bc2 ON bc2.TradeGUID = c.TradeGUID
        WHERE   c.Status = '激活' AND ((o.OrderType IN ('认购', '小订') AND   o.Status = '关闭' AND o.CloseReason = '转签约') OR   o.OrderGUID IS NULL)
        UNION
        --小订
        SELECT  TradeGUID ,
                RoomGUID ,
                CstName ,
                BldArea ,
                NULL AS rgDate ,
                NULL AS qyDate ,
                '小订' AS SaleType ,
                '' AS HtType ,
                '' AS yjNo ,
                '' AS PayformName ,
                '' AS Ywy ,
                '' AS Zygw ,
                RoomTotal AS RoomTotal ,
                ZxTotal AS ZxTotal ,
                0 AS bcAmount ,
                --BcTotal AS bcAmount ,
                FsTotal AS FsTotal ,
                JyTotal AS JyTotal
        FROM    dbo.es_Order
        WHERE   OrderType = '小订' AND Status = '激活';

        --按照款项判断是否存在预收款或者预约金的转账单
        SELECT  v1.VouchGUID ,
                COUNT(1) AS tfnum
        INTO    #yt1
        FROM    dbo.s_Voucher v1
                LEFT JOIN dbo.s_Getin g1 ON v1.VouchGUID = g1.VouchGUID
        WHERE   ISNULL(g1.Status, '') <> '作废'
                --AND ISNULL(g1.SaleType,
                --'') <> '预约单'
                AND v1.VouchType = '转账单' AND g1.ItemName IN ('预收款', '预约金', '挞定款')
        GROUP BY v1.VouchGUID;

        --SELECT  *
        --INTO    #es_Order
        --FROM    es_Order;
        --SELECT  *
        --INTO    #es_Contract
        --FROM    es_Contract;
        WITH myvs_trade AS (SELECT  TnCjPrice ,
                                    TnArea ,
                                    BUGUID ,
                                    ProjGUID ,
                                    TradeGUID ,
                                    OrderGUID AS SaleGUID ,
                                    QSDate ,
                                    YwblDate ,
                                    CstName ,
                                    CstTel ,
                                    RoomInfo ,
                                    Ywy ,
                                    OrderType AS SaleStatus ,
                                    Status ,
                                    CjTotal ,
                                    RmbCjTotal ,
                                    Bz ,
                                    RoomGUID ,
                                    CstAllGUID ,
                                    ISNULL(OrderType, '') AS saletype ,
                                    AjBank ,
                                    AjTotal ,
                                    GjjBank ,
                                    GjjTotal ,
                                    Tjr ,
                                    BldArea ,
                                    ExRate ,
                                    ISNULL(PayformName, '') AS PayformName ,
                                    JzDate ,
                                    JzAmount ,
                                    0 AS SjBcTotal ,
                                    0 AS IsZxkbrht ,
                                    0 AS ZxTotal ,
                                    BldGUID ,
                                    bldarea1 ,
                                    --ISNULL(getin.Amount, 0.00) AS HkAmount ,
                                    IsCreatorUse ,
                                    CreatedByGUID ,
                                    UserGUIDList ,
                                    'DD' AS TradeType ,
                                    RoomTotal ,
                                    IsZxkbrht AS IsZxkbrhtTemp ,
                                    JyTotal ,
                                    LastSaleGUID ,
                                    CloseDate ,
                                    CloseReason ,
                                    '' AS HTTYPE ,
                                    LastSaleType ,
                                    Earnest
                            FROM    es_Order
                            UNION ALL
                            SELECT  TnCjPrice ,
                                    TnArea ,
                                    BUGUID ,
                                    ProjGUID ,
                                    TradeGUID ,
                                    ContractGUID AS SaleGUID ,
                                    QSDate ,
                                    YwblDate ,
                                    CstName ,
                                    CstTel ,
                                    RoomInfo ,
                                    Ywy ,
                                    '签约' ,
                                    Status ,
                                    HtTotal ,
                                    RmbHtTotal ,
                                    Bz ,
                                    RoomGUID ,
                                    CstAllGUID ,
                                    '合同' AS saletype ,
                                    AjBank ,
                                    AjTotal ,
                                    GjjBank ,
                                    GjjTotal ,
                                    Tjr ,
                                    BldArea ,
                                    ExRate ,
                                    ISNULL(PayformName, '') AS PayformName ,
                                    JzDate ,
                                    JzAmount ,
                                    SjBcTotal ,
                                    IsZxkbrht ,
                                    ZxTotal ,
                                    BldGUID ,
                                    BldArea1 ,
                                    --ISNULL(getin.Amount, 0.00) AS HkAmount ,
                                    IsCreatorUse ,
                                    CreatedByGUID ,
                                    UserGUIDList ,
                                    'HT' AS TradeType ,
                                    RoomTotal ,
                                    IsZxkbrht AS IsZxkbrhtTemp ,
                                    JyTotal ,
                                    LastSaleGUID ,
                                    CloseDate ,
                                    CloseReason ,
                                    HtType AS HTTYPE ,
                                    LastSaleType ,
                                    Earnest
                            FROM    es_Contract)
        SELECT  a.RoomGUID ,
                CASE WHEN ISNULL(SUM(g.Amount), 0) > 0 THEN SUM(g.Amount)ELSE 0 END AS ytAmount ,
                CASE WHEN ISNULL(SUM(CASE WHEN ItemType = '贷款类房款' THEN g.Amount ELSE 0 END), 0) > 0 THEN SUM(CASE WHEN ItemType = '贷款类房款' THEN g.Amount ELSE 0 END)ELSE 0 END AS ytdkAmount ,
                CASE WHEN ISNULL(SUM(CASE WHEN ItemType = '非贷款类房款' OR   ItemName = '装修款' THEN g.Amount ELSE 0 END), 0) > 0 THEN
                         SUM(CASE WHEN ItemType = '非贷款类房款' OR ItemName = '装修款' THEN g.Amount ELSE 0 END)
                     ELSE 0
                END AS ytNodkAmount ,
                CASE WHEN ISNULL(SUM(CASE WHEN DATEDIFF(yy, g.getDate, @var_endDate) = 0 THEN g.Amount ELSE 0 END), 0) > 0 THEN
                         SUM(CASE WHEN DATEDIFF(yy, g.getDate, @var_endDate) = 0 THEN g.Amount ELSE 0 END)
                     ELSE 0
                END AS bnytAmount ,
                CASE WHEN ISNULL(SUM(CASE WHEN DATEDIFF(yy, g.getDate, @var_endDate) = 0 AND ItemType = '贷款类房款' THEN g.Amount ELSE 0 END), 0) > 0 THEN
                         SUM(CASE WHEN DATEDIFF(yy, g.getDate, @var_endDate) = 0 AND  ItemType = '贷款类房款' THEN g.Amount ELSE 0 END)
                     ELSE 0
                END AS bnytdkAmount ,
                CASE WHEN ISNULL(SUM(CASE WHEN DATEDIFF(yy, g.getDate, @var_endDate) = 0 AND (ItemType = '非贷款类房款' OR ItemName = '装修款') THEN g.Amount ELSE 0 END), 0) > 0 THEN
                         SUM(CASE WHEN DATEDIFF(yy, g.getDate, @var_endDate) = 0 AND   (ItemType = '非贷款类房款' OR ItemName = '装修款') THEN g.Amount ELSE 0 END)
                     ELSE 0
                END AS bnytNodkAmount ,
                CASE WHEN ISNULL(SUM(CASE WHEN DATEDIFF(mm, g.getDate, @var_endDate) = 0 THEN g.Amount ELSE 0 END), 0) > 0 THEN
                         SUM(CASE WHEN DATEDIFF(mm, g.getDate, @var_endDate) = 0 THEN g.Amount ELSE 0 END)
                     ELSE 0
                END AS byytAmount ,
                CASE WHEN ISNULL(SUM(CASE WHEN DATEDIFF(mm, g.getDate, @var_endDate) = 0 AND ItemType = '贷款类房款' THEN g.Amount ELSE 0 END), 0) > 0 THEN
                         SUM(CASE WHEN DATEDIFF(mm, g.getDate, @var_endDate) = 0 AND  ItemType = '贷款类房款' THEN g.Amount ELSE 0 END)
                     ELSE 0
                END AS byytdkAmount ,
                CASE WHEN ISNULL(SUM(CASE WHEN DATEDIFF(mm, g.getDate, @var_endDate) = 0 AND (ItemType = '非贷款类房款' OR ItemName = '装修款') THEN g.Amount ELSE 0 END), 0) > 0 THEN
                         SUM(CASE WHEN DATEDIFF(mm, g.getDate, @var_endDate) = 0 AND   (ItemType = '非贷款类房款' OR ItemName = '装修款') THEN g.Amount ELSE 0 END)
                     ELSE 0
                END AS byytNodkAmount ,
                CASE WHEN ISNULL(SUM(CASE WHEN DATEDIFF(dd, g.getDate, @var_endDate) = 0 THEN g.Amount ELSE 0 END), 0) > 0 THEN
                         SUM(CASE WHEN DATEDIFF(dd, g.getDate, @var_endDate) = 0 THEN g.Amount ELSE 0 END)
                     ELSE 0
                END AS brytAmount ,
                SUM(CASE WHEN DATEDIFF(yy, g.getDate, @var_endDate) = 0 AND (ItemType IN ('非贷款类房款', '贷款类房款') OR ItemName = '装修款') THEN g.Amount ELSE 0 END) AS bntfAmount , ---关闭交易本年退款金额
                SUM(CASE WHEN DATEDIFF(mm, g.getDate, @var_endDate) = 0 AND (ItemType IN ('非贷款类房款', '贷款类房款') OR ItemName = '装修款') THEN g.Amount ELSE 0 END) AS bytfAmount , ---关闭交易本月退款金额
                SUM(CASE WHEN DATEDIFF(dd, g.getDate, @var_endDate) = 0 AND (ItemType IN ('非贷款类房款', '贷款类房款') OR ItemName = '装修款') THEN g.Amount ELSE 0 END) AS brtfAmount   ---关闭交易本日退款金额
        INTO    #yt
        FROM    myvs_trade a
                LEFT JOIN(SELECT    v.BuGUID ,
                                    v.ProjGUID ,
                                    g.GetinGUID ,
                                    g.SaleGUID ,
                                    v.VouchGUID ,
                                    v.VouchType ,
                                    g.ItemType ,
                                    g.ItemName ,
                                    g.Amount ,
                                    CASE WHEN v.VouchType = '退款单' OR ISNULL(tf.tfnum, 0) > 0 THEN v.KpDate ELSE g.GetDate END AS getDate ,
                                    g.Status
                          FROM  dbo.s_Getin g
                                LEFT JOIN dbo.s_Voucher v ON g.VouchGUID = v.VouchGUID
                                LEFT JOIN #yt1 tf ON tf.VouchGUID = v.VouchGUID
                          WHERE g.Status IS NULL AND   ISNULL(g.SaleType, '') <> '预约单') g ON a.TradeGUID = g.SaleGUID
        WHERE   a.Status = '关闭' AND g.ItemType IN ('贷款类房款', '非贷款类房款')
                --20210223 增加关闭原因为“换房”
                AND a.CloseReason IN ('挞定', '系统挞定', '退房', '作废', '换房') AND   ISNULL(g.Status, '') <> '作废'
        GROUP BY a.RoomGUID;

        SELECT  g.RoomGUID ,
                SUM(CASE WHEN ItemType IN ('贷款类房款', '非贷款类房款') THEN Amount ELSE 0 END) AS getAmount ,
                SUM(CASE WHEN ItemType = '贷款类房款' THEN Amount ELSE 0 END) AS ljdkgetAmount ,
                SUM(CASE WHEN (ItemType = '非贷款类房款' OR   ItemName = '装修款') THEN Amount ELSE 0 END) AS ljNodkgetAmount ,
                SUM(CASE WHEN ItemType = '其它' AND   ItemName LIKE '装修款%' THEN Amount ELSE 0 END) ljzxkAmount ,
                --本年
                SUM(CASE WHEN ItemType IN ('贷款类房款', '非贷款类房款') AND   DATEDIFF(yy, getDate, @var_endDate) = 0 THEN Amount ELSE 0 END) AS bngetAmount ,
                SUM(CASE WHEN DATEDIFF(yy, getDate, @var_endDate) = 0 AND   ItemType = '贷款类房款' THEN Amount ELSE 0 END) AS bndkgetAmount ,
                SUM(CASE WHEN DATEDIFF(yy, getDate, @var_endDate) = 0 AND   (ItemType = '非贷款类房款' OR ItemName = '装修款') THEN Amount ELSE 0 END) AS bnNodkgetAmount ,
                SUM(CASE WHEN DATEDIFF(yy, getDate, @var_endDate) = 0 AND   ItemName IN ('房款补差款', '补差款') THEN Amount ELSE 0 END) AS bnbcAmount ,
                --本月
                SUM(CASE WHEN ItemType IN ('贷款类房款', '非贷款类房款') AND   DATEDIFF(mm, getDate, @var_endDate) = 0 THEN Amount ELSE 0 END) AS bygetAmount ,
                SUM(CASE WHEN DATEDIFF(mm, getDate, @var_endDate) = 0 AND   ItemType = '贷款类房款' THEN Amount ELSE 0 END) AS bydkgetAmount ,
                SUM(CASE WHEN DATEDIFF(mm, getDate, @var_endDate) = 0 AND   (ItemType = '非贷款类房款' OR ItemName = '装修款') THEN Amount ELSE 0 END) AS byNodkgetAmount ,
                SUM(CASE WHEN DATEDIFF(mm, getDate, @var_endDate) = 0 AND   ItemName IN ('房款补差款', '补差款') THEN Amount ELSE 0 END) AS bybcAmount ,

                --本日
                SUM(CASE WHEN ItemType IN ('贷款类房款', '非贷款类房款') AND   DATEDIFF(dd, getDate, @var_endDate) = 0 THEN Amount ELSE 0 END) AS brgetAmount ,
                SUM(CASE WHEN DATEDIFF(dd, getDate, @var_endDate) = 0 AND   ItemType = '贷款类房款' THEN Amount ELSE 0 END) AS brdkgetAmount ,
                SUM(CASE WHEN DATEDIFF(dd, getDate, @var_endDate) = 0 AND   (ItemType = '非贷款类房款' OR ItemName = '装修款') THEN Amount ELSE 0 END) AS brNodkgetAmount ,
                SUM(CASE WHEN DATEDIFF(dd, getDate, @var_endDate) = 0 AND   ItemName IN ('房款补差款', '补差款') THEN Amount ELSE 0 END) AS brbcAmount ,
                --补差款
                SUM(CASE WHEN ItemName IN ('房款补差款', '补差款') THEN Amount ELSE 0 END) AS bcAmount ,
                --特殊业绩回笼,按照回笼缴费日期统计本年、本月
                SUM(CASE WHEN SaleType = '特殊业绩' THEN g.Amount ELSE 0 END) AS tsljAmount ,
                SUM(CASE WHEN SaleType = '特殊业绩' AND DATEDIFF(mm, getDate, @var_endDate) = 0 THEN g.Amount ELSE 0 END) AS tsbyAmount ,
                SUM(CASE WHEN SaleType = '特殊业绩' AND DATEDIFF(yy, getDate, @var_endDate) = 0 THEN g.Amount ELSE 0 END) AS tsbnAmount
        INTO    #g
        FROM(SELECT v.BuGUID ,
                    v.ProjGUID ,
                    g.GetinGUID ,
                    tr.RoomGUID ,
                    g.SaleGUID ,
                    v.VouchGUID ,
                    v.VouchType ,
                    g.SaleType ,
                    g.ItemType ,
                    g.ItemName ,
                    g.Amount ,
                    CASE WHEN v.VouchType = '退款单' OR ISNULL(tf.tfnum, 0) > 0 THEN v.KpDate ELSE g.GetDate END AS getDate ,
                    g.Status
             FROM   dbo.s_Getin g
                    LEFT JOIN dbo.s_Voucher v ON g.VouchGUID = v.VouchGUID
                    LEFT JOIN dbo.vs_Trade tr ON tr.TradeGUID = g.SaleGUID
                    LEFT JOIN(
                             --按照款项判断是否存在预收款或者预约金的转账单
                             SELECT v1.VouchGUID ,
                                    COUNT(1) AS tfnum
                             FROM   dbo.s_Voucher v1
                                    LEFT JOIN dbo.s_Getin g1 ON v1.VouchGUID = g1.VouchGUID
                             WHERE  ISNULL(g1.Status, '') <> '作废'
                                    --AND ISNULL(g1.SaleType,
                                    --'') <> '预约单'
                                    AND v1.VouchType = '转账单' AND g1.ItemName IN ('预收款', '预约金', '挞定款')
                             GROUP BY v1.VouchGUID) tf ON tf.VouchGUID = v.VouchGUID
             WHERE  g.Status IS NULL AND ISNULL(g.SaleType, '') <> '预约单' AND tr.Status = '激活') g
        WHERE   ISNULL(Status, '') <> '作废'
                --AND ItemType IN ( '贷款类房款', '非贷款类房款' )
                AND getDate <= @var_endDate
        GROUP BY g.RoomGUID;

        SELECT  TradeGUID ,
                --正常待收款
                SUM(CASE WHEN (ItemType = '非贷款类房款' OR   ItemName = '装修款') AND   ISNULL(lastDate, '2099-01-01') >= @var_endDate THEN ISNULL(Ye, 0) - ISNULL(DsAmount, 0)ELSE 0 END) AS zcNodkAmount ,
                SUM(CASE WHEN ItemType = '贷款类房款' AND ISNULL(lastDate, '2099-01-01') >= @var_endDate THEN ISNULL(Ye, 0) - ISNULL(DsAmount, 0)ELSE 0 END) AS zcdkAmount ,
                SUM(CASE WHEN ItemType IN ('贷款类房款', '非贷款类房款') AND   ISNULL(lastDate, '2099-01-01') >= @var_endDate THEN ISNULL(Ye, 0) - ISNULL(DsAmount, 0)ELSE 0 END) AS zcAmount ,
                --逾期待收款        
                SUM(CASE WHEN (ItemType = '非贷款类房款' OR   ItemName = '装修款') AND   ISNULL(lastDate, '2099-01-01') < @var_endDate THEN ISNULL(Ye, 0) - ISNULL(DsAmount, 0)ELSE 0 END) AS yqNodkAmount ,
                SUM(CASE WHEN ItemType = '贷款类房款' AND ISNULL(lastDate, '2099-01-01') < @var_endDate THEN ISNULL(Ye, 0) - ISNULL(DsAmount, 0)ELSE 0 END) AS yqdkAmount ,
                SUM(CASE WHEN ItemType IN ('贷款类房款', '非贷款类房款') AND   ISNULL(lastDate, '2099-01-01') < @var_endDate THEN ISNULL(Ye, 0) - ISNULL(DsAmount, 0)ELSE 0 END) AS yqAmount ,
                SUM(CASE WHEN ItemType IN ('贷款类房款', '非贷款类房款') THEN ISNULL(Ye, 0) - ISNULL(DsAmount, 0)ELSE 0 END) AS dsAmount ,
                SUM(CASE WHEN ItemName IN ('房款补差款', '补差款') THEN ISNULL(Ye, 0) - ISNULL(DsAmount, 0)ELSE 0 END) AS dsbcAmount ,
                SUM(CASE WHEN ItemType = '其它' AND   ItemName LIKE '装修款%' THEN ISNULL(Ye, 0) - ISNULL(DsAmount, 0)ELSE 0 END) dszxkAmount
        INTO    #f
        FROM    dbo.s_Fee
        WHERE(1 = 1)    --ItemType IN ( '贷款类房款', '非贷款类房款' )
        GROUP BY TradeGUID;

        SELECT  a.BldGUID ,
                r.RoomGUID ,
				b.YjType ,
				--按楼栋关联，则取分摊到该房间特殊业绩认定的金额（该房间建筑面积/关联该房间特殊业绩总面积*关联该房间特殊业绩总金额）
                CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 THEN 0 ELSE (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0)) * ISNULL(a.AmountDetermined, 0)END * 10000 AS AmountDetermined ,
                --特殊业绩回笼
                CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 OR ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.huilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0)) * (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0))END AS huilongjiner ,
                --本年特殊业绩回笼
                CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 OR ISNULL(b.TotalAmount, 0) = 0  THEN 0 ELSE ISNULL(t.bnhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0)) * (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0))END AS bnhuilongjiner ,
                --本月特殊业绩回笼
                CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 OR ISNULL(b.TotalAmount, 0) = 0  THEN 0 ELSE ISNULL(t.byhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0)) * (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0))END AS byhuilongjiner ,
                --本日特殊业绩回笼
                CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 OR ISNULL(b.TotalAmount, 0) = 0  THEN 0 ELSE ISNULL(t.brhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0)) * (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0))END AS brhuilongjiner
        INTO    #ts
        FROM    S_PerformanceAppraisalBuildings a
                LEFT JOIN dbo.p_room r ON a.BldGUID = r.BldGUID
                LEFT JOIN(SELECT    BldGUID ,
                                    SUM(BldArea) AS TotalBldArea
                          FROM  dbo.p_room
                          GROUP BY BldGUID) r2 ON r2.BldGUID = a.BldGUID
                LEFT JOIN S_PerformanceAppraisal b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
                LEFT JOIN(SELECT    v.SaleGUID ,
                                    SUM(ISNULL(g.RmbAmount, 0)) AS huilongjiner ,
                                    SUM(CASE WHEN DATEDIFF(mm, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS byhuilongjiner ,
                                    SUM(CASE WHEN DATEDIFF(yy, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS bnhuilongjiner ,
                                    SUM(CASE WHEN DATEDIFF(DAY, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS brhuilongjiner
                          FROM  dbo.s_Voucher v
                                INNER JOIN dbo.s_Getin g ON g.VouchGUID = v.VouchGUID
                          WHERE g.SaleType = '特殊业绩' AND (v.VouchStatus IS NULL OR  v.VouchStatus = '')
                          GROUP BY v.SaleGUID) t ON t.SaleGUID = b.PerformanceAppraisalGUID
        WHERE   b.AuditStatus = '已审核'
                --AND b.YjType<>'经营类' --AND a.BldGUID ='9FC6AB14-D9E8-4D02-9A02-AA535B718385'
                AND b.YjType NOT IN ('经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)')
        UNION
        SELECT  NULL ,
                RoomGUID ,
				b.YjType ,
                AmountDetermined * 10000 ,
                --特殊业绩回笼,关联房间回笼按照认定金额比例分摊
                CASE WHEN ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.huilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0))END AS huilongjiner ,
                --本年特殊业绩回笼
                CASE WHEN ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.bnhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0))END AS bnhuilongjiner ,
                --本月特殊业绩回笼
                CASE WHEN ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.byhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0))END AS byhuilongjiner ,
                --本日特殊业绩回笼
                CASE WHEN ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.brhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0))END AS brhuilongjiner
        FROM    S_PerformanceAppraisalRoom a
                LEFT JOIN S_PerformanceAppraisal b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
                LEFT JOIN(SELECT    v.SaleGUID ,
                                    SUM(ISNULL(g.RmbAmount, 0)) AS huilongjiner ,
                                    SUM(CASE WHEN DATEDIFF(mm, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS byhuilongjiner ,
                                    SUM(CASE WHEN DATEDIFF(yy, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS bnhuilongjiner ,
                                    SUM(CASE WHEN DATEDIFF(DAY, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS brhuilongjiner
                          FROM  dbo.s_Voucher v
                                INNER JOIN dbo.s_Getin g ON g.VouchGUID = v.VouchGUID
                          WHERE g.SaleType = '特殊业绩' AND (v.VouchStatus IS NULL OR  v.VouchStatus = '')
                          GROUP BY v.SaleGUID) t ON t.SaleGUID = b.PerformanceAppraisalGUID
        WHERE   b.AuditStatus = '已审核'
                --AND b.YjType<>'经营类'
                AND b.YjType NOT IN ('经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)');

        ---经营类特殊业绩单列
        SELECT  a.BldGUID ,
                r.RoomGUID ,
				b.YjType ,
				--按楼栋关联，则取分摊到该房间特殊业绩认定的金额（该房间建筑面积/关联该房间特殊业绩总面积*关联该房间特殊业绩总金额）
                CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 THEN 0 ELSE (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0)) * ISNULL(a.AmountDetermined, 0)END * 10000 AS AmountDetermined ,
                --特殊业绩回笼
                CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 OR ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.huilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0)) * (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0))END AS huilongjiner ,
                --本年特殊业绩回笼
                CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 OR ISNULL(b.TotalAmount, 0) = 0  THEN 0 ELSE ISNULL(t.bnhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0)) * (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0))END AS bnhuilongjiner ,
                --本月特殊业绩回笼
                CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 OR ISNULL(b.TotalAmount, 0) = 0  THEN 0 ELSE ISNULL(t.byhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0)) * (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0))END AS byhuilongjiner ,
                --本日特殊业绩回笼
                CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 OR ISNULL(b.TotalAmount, 0) = 0  THEN 0 ELSE ISNULL(t.brhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0)) * (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0))END AS brhuilongjiner
        INTO    #ts2
        FROM    S_PerformanceAppraisalBuildings a
                LEFT JOIN dbo.p_room r ON a.BldGUID = r.BldGUID
                LEFT JOIN(SELECT    BldGUID ,
                                    SUM(BldArea) AS TotalBldArea
                          FROM  dbo.p_room
                          GROUP BY BldGUID) r2 ON r2.BldGUID = a.BldGUID
                LEFT JOIN S_PerformanceAppraisal b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
                LEFT JOIN(SELECT    v.SaleGUID ,
                                    SUM(ISNULL(g.RmbAmount, 0)) AS huilongjiner ,
                                    SUM(CASE WHEN DATEDIFF(mm, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS byhuilongjiner ,
                                    SUM(CASE WHEN DATEDIFF(yy, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS bnhuilongjiner ,
                                    SUM(CASE WHEN DATEDIFF(DAY, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS brhuilongjiner
                          FROM  dbo.s_Voucher v
                                INNER JOIN dbo.s_Getin g ON g.VouchGUID = v.VouchGUID
                          WHERE g.SaleType = '特殊业绩' AND (v.VouchStatus IS NULL OR  v.VouchStatus = '')
                          GROUP BY v.SaleGUID) t ON t.SaleGUID = b.PerformanceAppraisalGUID
        WHERE   b.AuditStatus = '已审核'
                --AND b.YjType='经营类'--AND a.BldGUID ='9FC6AB14-D9E8-4D02-9A02-AA535B718385'
                AND b.YjType IN ('经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)')
        UNION
        SELECT  NULL ,
                RoomGUID ,
				b.YjType ,
                AmountDetermined * 10000 ,
                --特殊业绩回笼,关联房间回笼按照认定金额比例分摊
                CASE WHEN ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.huilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0))END AS huilongjiner ,
                --本年特殊业绩回笼
                CASE WHEN ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.bnhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0))END AS bnhuilongjiner ,
                --本月特殊业绩回笼
                CASE WHEN ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.byhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0))END AS byhuilongjiner ,
                --本日特殊业绩回笼
                CASE WHEN ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.brhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0))END AS brhuilongjiner
        FROM    S_PerformanceAppraisalRoom a
                LEFT JOIN S_PerformanceAppraisal b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
                LEFT JOIN(SELECT    v.SaleGUID ,
                                    SUM(ISNULL(g.RmbAmount, 0)) AS huilongjiner ,
                                    SUM(CASE WHEN DATEDIFF(mm, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS byhuilongjiner ,
                                    SUM(CASE WHEN DATEDIFF(yy, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS bnhuilongjiner ,
                                    SUM(CASE WHEN DATEDIFF(DAY, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS brhuilongjiner
                          FROM  dbo.s_Voucher v
                                INNER JOIN dbo.s_Getin g ON g.VouchGUID = v.VouchGUID
                          WHERE g.SaleType = '特殊业绩' AND (v.VouchStatus IS NULL OR  v.VouchStatus = '')
                          GROUP BY v.SaleGUID) t ON t.SaleGUID = b.PerformanceAppraisalGUID
        WHERE   b.AuditStatus = '已审核'
                --AND b.YjType='经营类'
                AND b.YjType IN ('经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)');

        SELECT  @var_endDate AS qxDate ,
                bu.BUGUID ,
                p.ProjGUID ,
                p1.ProjGUID AS topprojguid ,
                bu.BUName AS '公司名称' ,
                p1.ProjName AS '销售项目名称' ,
                p1.ParentCode AS '销售项目代码' ,
                mp.ProjName AS '投管项目名称' ,
                mp.ProjCode AS '投管项目代码' ,
                mp.TradersWay AS '操盘方式' ,
                mp.BbWay AS '并表方式' ,
                                                    --mp.EquityRatio AS '项目权益比例' ,
                lbp.LbProjectValue AS '项目权益比例' ,    --财务收益比例
                r.RoomInfo AS '房间信息' ,
                bd.ProductType AS '产品类型' ,
                bd.ProductName AS '产品名称' ,
                bd.BldName AS '楼栋名称' ,
                ISNULL(ord.CstName, r1.CstName) AS '客户姓名' ,
                ord.SaleType AS '销售状态' ,
                CASE WHEN ISNULL(ord.HtType, '') <> '' THEN ord.HtType ELSE '未售' END AS '合同类型' ,
                ord.yjNo AS '交易编号' ,
                ord.BldArea AS '建筑面积' ,
                ord.qyDate AS '签署日期' ,
                ord.PayformName AS '付款方式' ,
                ord.Ywy AS '代理公司' ,
                ord.zygw AS '置业顾问' ,
                ISNULL(ord.RoomTotal, 0) AS '房间成交金额' ,
                ISNULL(CASE WHEN ord.SaleType = '签约' THEN ord.JyTotal ELSE 0 END, 0) AS '签约金额' ,
                ISNULL(ord.ZxTotal, 0) AS '装修款' ,
                ISNULL(ord.FsTotal, 0) AS '附属房间成交金额' ,
                ISNULL(ord.bcAmount, 0) AS '补差款' ,
                ISNULL(ord.JyTotal, 0) + ISNULL(ord.bcAmount, 0) AS '交易金额' ,

                                                    --累计数
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(yt.ytAmount, 0)ELSE 0 END AS '应退未退累计金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('小订', '认购') THEN ISNULL(g.getAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '认购累计回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('签约') THEN ISNULL(g.getAmount, 0)ELSE 0 END ELSE 0 END AS '签约累计回笼金额' ,
                                                    --该房间的总收款，包含应退未退及激活交易单实收（累计回笼为0的剔除）
                                                    --1.1如果房间不是特殊业绩关联房间则正常取数；
                                                    --1.2如果房间是特殊业绩关联房间则判断是否从房间取数
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' THEN ISNULL(g.getAmount, 0) + ISNULL(yt.ytAmount, 0)
                     ELSE
                         CASE WHEN ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 AND ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 1 THEN
                                  ISNULL(g.getAmount, 0) + ISNULL(yt.ytAmount, 0) + ISNULL(ts.huilongjiner, 0)
                              WHEN ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 AND ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 0 THEN ISNULL(g.getAmount, 0) + ISNULL(yt.ytAmount, 0)
                              WHEN ISNULL(sps.ifSelectRoomHkAmount, 0) = 0 AND ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 1 THEN ISNULL(ts.huilongjiner, 0)
                              ELSE 0
                         END
                END AS '累计回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(g.bcAmount, 0)ELSE 0 END AS '其中补差款累计回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('签约') THEN ISNULL(g.ljdkgetAmount, 0)
                                                                                              --  + ISNULL(yt.ytdkAmount, 0)
                                                                                              END
                     ELSE 0
                END AS '累计签约按揭回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('小订', '认购') THEN ISNULL(g.ljdkgetAmount, 0)
                                                                                              --  + ISNULL(yt.ytdkAmount, 0)
                                                                                              END
                     ELSE 0
                END AS '累计认购按揭回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('签约') THEN ISNULL(g.ljNodkgetAmount, 0)
                                                                                              --   + ISNULL(yt.ytNodkAmount, 0)
                                                                                              END
                     ELSE 0
                END AS '累计签约非按揭回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('小订', '认购') THEN ISNULL(g.ljNodkgetAmount, 0)
                                                                                              --   + ISNULL(yt.ytNodkAmount, 0)
                                                                                              END
                     ELSE 0
                END AS '累计认购非按揭回笼金额' ,
                                                    --本年数
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(yt.bnytAmount, 0)ELSE 0 END AS '应退未退本年金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('小订', '认购') THEN ISNULL(g.bngetAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '认购累计本年金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('签约') THEN ISNULL(g.bngetAmount, 0)ELSE 0 END ELSE 0 END AS '签约本年回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' THEN ISNULL(g.bngetAmount, 0) + ISNULL(yt.bnytAmount, 0) + CASE WHEN ISNULL(yt.bntfAmount, 0) < 0 THEN ISNULL(yt.bntfAmount, 0)ELSE 0 END
                     ELSE
                         CASE WHEN ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 AND ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 1 THEN
                                  ISNULL(g.bngetAmount, 0) + ISNULL(yt.bnytAmount, 0) + CASE WHEN ISNULL(yt.bntfAmount, 0) < 0 THEN ISNULL(yt.bntfAmount, 0)ELSE 0 END + ISNULL(ts.bnhuilongjiner, 0)
                              WHEN ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 AND ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 0 THEN
                                  ISNULL(g.bngetAmount, 0) + ISNULL(yt.bnytAmount, 0) + CASE WHEN ISNULL(yt.bntfAmount, 0) < 0 THEN ISNULL(yt.bntfAmount, 0)ELSE 0 END
                              WHEN ISNULL(sps.ifSelectRoomHkAmount, 0) = 0 AND ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 1 THEN ISNULL(ts.bnhuilongjiner, 0)
                              ELSE 0
                         END
                END AS '累计本年回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(g.bndkgetAmount, 0)ELSE 0 END AS '累计本年按揭回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(g.bnNodkgetAmount, 0)ELSE 0 END AS '累计本年非按揭回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(g.bnbcAmount, 0)ELSE 0 END AS '其中补差款本年回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('签约') THEN ISNULL(g.bndkgetAmount, 0)
                                                                                              --+ ISNULL(yt.bnytdkAmount, 0)
                                                                                              END
                     ELSE 0
                END '本年签约按揭回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('小订', '认购') THEN ISNULL(g.bndkgetAmount, 0)
                                                                                              -- + ISNULL(yt.bnytdkAmount, 0)
                                                                                              END
                     ELSE 0
                END AS '本年认购按揭回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('签约') THEN ISNULL(g.bnNodkgetAmount, 0)
                                                                                              -- + ISNULL(yt.bnytNodkAmount, 0)
                                                                                              END
                     ELSE 0
                END AS '本年签约非按揭回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('小订', '认购') THEN ISNULL(g.bnNodkgetAmount, 0)
                                                                                              -- + ISNULL(yt.bnytNodkAmount, 0)
                                                                                              END
                     ELSE 0
                END AS '本年认购非按揭回笼金额' ,
                                                    --本月
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(yt.byytAmount, 0)ELSE 0 END AS '应退未退本月金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('小订', '认购') THEN ISNULL(g.bygetAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '认购累计本月金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('签约') THEN ISNULL(g.bygetAmount, 0)ELSE 0 END ELSE 0 END AS '签约本月回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' THEN ISNULL(g.bygetAmount, 0) + ISNULL(yt.byytAmount, 0) + CASE WHEN ISNULL(yt.bytfAmount, 0) < 0 THEN ISNULL(yt.bytfAmount, 0)ELSE 0 END
                     ELSE
                         CASE WHEN ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 AND ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 1 THEN
                                  ISNULL(g.bygetAmount, 0) + ISNULL(yt.byytAmount, 0) + CASE WHEN ISNULL(yt.bytfAmount, 0) < 0 THEN ISNULL(yt.bytfAmount, 0)ELSE 0 END + ISNULL(ts.byhuilongjiner, 0)
                              WHEN ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 AND ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 0 THEN
                                  ISNULL(g.bygetAmount, 0) + ISNULL(yt.byytAmount, 0) + CASE WHEN ISNULL(yt.bytfAmount, 0) < 0 THEN ISNULL(yt.bytfAmount, 0)ELSE 0 END
                              WHEN ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 AND ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 0 THEN +ISNULL(ts.byhuilongjiner, 0)
                              ELSE 0
                         END
                END AS '累计本月回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(g.bydkgetAmount, 0)ELSE 0 END AS '累计本月按揭回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(g.byNodkgetAmount, 0)ELSE 0 END AS '累计本月非按揭回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(g.bybcAmount, 0)ELSE 0 END AS '其中补差款本月回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('签约') THEN ISNULL(g.bydkgetAmount, 0)
                                                                                              -- + ISNULL(yt.byytdkAmount, 0)
                                                                                              END
                     ELSE 0
                END AS '本月签约按揭回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('小订', '认购') THEN ISNULL(g.bydkgetAmount, 0)
                                                                                              -- + ISNULL(yt.byytdkAmount, 0)
                                                                                              END
                     ELSE 0
                END AS '本月认购按揭回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('签约') THEN ISNULL(g.byNodkgetAmount, 0)
                                                                                              -- + ISNULL(yt.byytNodkAmount, 0)
                                                                                              END
                     ELSE 0
                END AS '本月签约非按揭回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('小订', '认购') THEN ISNULL(g.byNodkgetAmount, 0)
                                                                                              --  + ISNULL(yt.byytNodkAmount, 0)
                                                                                              END
                     ELSE 0
                END AS '本月认购非按揭回笼金额' ,

                                                    ---本月签约本月回笼
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN
                         CASE WHEN ord.SaleType IN ('签约') AND  DATEDIFF(mm, ord.qyDate, @var_endDate) = 0 THEN ISNULL(g.byNodkgetAmount, 0)
                              -- + ISNULL(yt.byytNodkAmount, 0)
                              ELSE 0
                         END
                     ELSE 0
                END AS '本月签约本月回笼非按揭回笼' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN
                         CASE WHEN ord.SaleType IN ('签约') AND  DATEDIFF(mm, ord.qyDate, @var_endDate) = 0 THEN ISNULL(g.bydkgetAmount, 0)
                              -- + ISNULL(yt.byytdkAmount, 0)
                              ELSE 0
                         END
                     ELSE 0
                END AS '本月签约本月回笼按揭回笼' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN
                         CASE WHEN ord.SaleType IN ('签约') AND  DATEDIFF(mm, ord.qyDate, @var_endDate) = 0 THEN ISNULL(g.bygetAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '本月签约本月回笼回笼合计' ,

                                                    --本年签约本月回笼
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN
                         CASE WHEN ord.SaleType IN ('签约') AND  DATEDIFF(yy, ord.qyDate, @var_endDate) = 0 THEN ISNULL(g.byNodkgetAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '本年签约本月回笼非按揭回笼' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN
                         CASE WHEN ord.SaleType IN ('签约') AND  DATEDIFF(yy, ord.qyDate, @var_endDate) = 0 THEN ISNULL(g.bydkgetAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '本年签约本月回笼按揭回笼' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN
                         CASE WHEN ord.SaleType IN ('签约') AND  DATEDIFF(yy, ord.qyDate, @var_endDate) = 0 THEN ISNULL(g.bygetAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '本年签约本月回笼回笼合计' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(f.zcNodkAmount, 0)ELSE 0 END AS '正常非按揭待收款' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(f.zcdkAmount, 0)ELSE 0 END AS '正常按揭待收款' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(f.zcAmount, 0)ELSE 0 END AS '正常待收款' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(f.yqNodkAmount, 0)ELSE 0 END AS '非按揭逾期待收款' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(f.yqdkAmount, 0)ELSE 0 END AS '按揭逾期待收款' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(f.yqAmount, 0)ELSE 0 END AS '逾期合计' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(f.dsAmount, 0)ELSE 0 END AS '待收房款合计' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(f.dsbcAmount, 0)ELSE 0 END AS '其中待收补差款合计' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ISNULL(yt.bntfAmount, 0) < 0 THEN ISNULL(yt.bntfAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '关闭交易本年退款金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ISNULL(yt.bytfAmount, 0) < 0 THEN ISNULL(yt.bytfAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '关闭交易本月退款金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('小订', '认购') THEN ISNULL(f.dsAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '认购累计待收款' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('签约') THEN ISNULL(f.dsAmount, 0)ELSE 0 END ELSE 0 END AS '签约累计待收款' ,

                                                    --本日
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(yt.brytAmount, 0)ELSE 0 END AS '应退未退本日金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('小订', '认购') THEN ISNULL(g.brgetAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '认购累计本日金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ord.SaleType IN ('签约') THEN ISNULL(g.brgetAmount, 0)ELSE 0 END ELSE 0 END AS '签约本日回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN CASE WHEN ISNULL(yt.brtfAmount, 0) < 0 THEN ISNULL(yt.brtfAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '关闭交易本日退款金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' THEN ISNULL(g.brgetAmount, 0) + ISNULL(yt.brytAmount, 0) + CASE WHEN ISNULL(yt.brtfAmount, 0) < 0 THEN ISNULL(yt.brtfAmount, 0)ELSE 0 END
                     ELSE
                         CASE WHEN ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 AND ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 1 THEN
                                  ISNULL(g.brgetAmount, 0) + ISNULL(yt.brytAmount, 0) + CASE WHEN ISNULL(yt.brtfAmount, 0) < 0 THEN ISNULL(yt.brtfAmount, 0)ELSE 0 END + ISNULL(ts.brhuilongjiner, 0)
                              WHEN ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 AND ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 0 THEN
                                  ISNULL(g.brgetAmount, 0) + ISNULL(yt.brytAmount, 0) + CASE WHEN ISNULL(yt.brtfAmount, 0) < 0 THEN ISNULL(yt.brtfAmount, 0)ELSE 0 END
                              WHEN ISNULL(sps.ifSelectRoomHkAmount, 0) = 0 AND ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 1 THEN ISNULL(ts.brhuilongjiner, 0)
                              ELSE 0
                         END
                END AS '累计本日回笼金额' ,
                CASE WHEN ISNULL(mpp.ProjStatus, '') <> '' THEN mpp.ProjStatus ELSE mp.ProjStatus END AS '项目状态' ,
                r.RoomGUID ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(f.dszxkAmount, 0)ELSE 0 END AS '累计装修款待收款' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(g.ljzxkAmount, 0)ELSE 0 END AS '累计装修款回笼金额' ,
                CASE WHEN ISNULL(sps.ifSelectPerformanceAmount, 0) = 1 THEN ISNULL(ts.AmountDetermined, 0) + ISNULL(ts2.AmountDetermined, 0)ELSE 0 END AS '特殊业绩认定金额' ,
                CASE WHEN ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 1 THEN ISNULL(ts.huilongjiner, 0)ELSE 0 END AS '特殊业绩累计回笼金额' ,
                CASE WHEN ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 1 THEN ISNULL(ts.bnhuilongjiner, 0)ELSE 0 END AS '特殊业绩本年回笼金额' ,
                CASE WHEN ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 1 THEN ISNULL(ts.byhuilongjiner, 0)ELSE 0 END AS '特殊业绩本月回笼金额' ,
                CASE WHEN ts.RoomGUID IS NOT NULL OR ts2.RoomGUID IS NOT NULL THEN '是' ELSE '否' END AS '是否特殊业绩' ,

                                                    --本年签约本年回笼
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN
                         CASE WHEN ord.SaleType IN ('签约') AND  DATEDIFF(yy, ord.qyDate, @var_endDate) = 0 THEN ISNULL(g.bnNodkgetAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '本年签约本年回笼非按揭回笼' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN
                         CASE WHEN ord.SaleType IN ('签约') AND  DATEDIFF(yy, ord.qyDate, @var_endDate) = 0 THEN ISNULL(g.bndkgetAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '本年签约本年回笼按揭回笼' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN
                         CASE WHEN ord.SaleType IN ('签约') AND  DATEDIFF(yy, ord.qyDate, @var_endDate) = 0 THEN ISNULL(g.bngetAmount, 0)ELSE 0 END
                     ELSE 0
                END AS '本年签约本年回笼回笼合计' ,
                CASE WHEN ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 1 THEN ISNULL(ts2.huilongjiner, 0)ELSE 0 END AS '经营类特殊业绩累计回笼金额' ,
                CASE WHEN ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 1 THEN ISNULL(ts2.bnhuilongjiner, 0)ELSE 0 END AS '经营类特殊业绩本年回笼金额' ,
                CASE WHEN ISNULL(sps.ifSelectPerformanceHkAmount, 0) = 1 THEN ISNULL(ts2.byhuilongjiner, 0)ELSE 0 END AS '经营类特殊业绩本月回笼金额'
        FROM    dbo.ep_room r
                INNER JOIN dbo.p_room r1 ON r1.RoomGUID = r.RoomGUID
                LEFT JOIN dbo.p_Building bd ON bd.BldGUID = r.BldGUID
                LEFT JOIN dbo.p_Project p ON r.ProjGUID = p.ProjGUID
                LEFT JOIN dbo.mdm_Project mpp ON mpp.ProjGUID = p.ProjGUID
                LEFT JOIN dbo.p_Project p1 ON p1.ProjCode = p.ParentCode
                LEFT JOIN S_PerformanceProjectSet sps ON sps.ProjGUID = p1.ProjGUID
                LEFT JOIN mdm_Project mp ON mp.ImportSaleProjGUID = p1.ProjGUID
                LEFT JOIN(SELECT    projGUID ,
                                    MAX(LbProjectValue) AS LbProjectValue
                          FROM  mdm_LbProject
                          WHERE LbProject = 'cwsybl'
                          GROUP BY projGUID) lbp ON lbp.projGUID = mp.ProjGUID
                LEFT JOIN dbo.myBusinessUnit bu ON bu.BUGUID = r.BUGUID
                LEFT JOIN #ord ord ON ord.RoomGUID = r.RoomGUID
                LEFT JOIN #yt yt ON yt.RoomGUID = r.RoomGUID
                LEFT JOIN #g g ON g.RoomGUID = r1.RoomGUID
                LEFT JOIN #f f ON f.TradeGUID = ord.TradeGUID
                --标识特殊业绩房间
                LEFT JOIN #ts ts ON ts.RoomGUID = r.RoomGUID
                LEFT JOIN #ts2 ts2 ON ts2.RoomGUID = r.RoomGUID
        WHERE   r.IsVirtualRoom = 0 AND p.ApplySys LIKE '%0101%' AND p1.ApplySys LIKE '%0101%' AND  r1.isAnnexe = 0 AND r.BUGUID IN(
                                                                                                                                   --SELECT  Value
                                                                                                                                   --FROM    [dbo].[fn_Split2](@var_buguid, ',') 
                                                                                                                                   SELECT   BUGUID FROM #B)
        ORDER BY r.RoomInfo;

        SET TRANSACTION ISOLATION LEVEL READ COMMITTED;

        DROP TABLE #B;
        DROP TABLE #f;
        DROP TABLE #g;
        DROP TABLE #ord;
        DROP TABLE #ts;
        DROP TABLE #yt;
        DROP TABLE #yt1;
    --DROP TABLE #es_Contract;
    --DROP TABLE #es_Order;
    END;

EXEC sp_recompile usp_s_gsfkylb;
