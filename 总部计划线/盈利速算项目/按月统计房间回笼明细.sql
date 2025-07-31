    declare @var_endDate DATETIME = '2025-07-08';
    
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
			and  v1.buguid ='248B1E17-AACB-E511-80B8-E41F13C51836'  -- 湾区公司
    GROUP BY v1.VouchGUID ;

-- 关闭房间退款金额
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

SELECT  a.RoomGUID ,year(getDate) as year,month(getDate) as month,
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
                and a.BUGUID ='248B1E17-AACB-E511-80B8-E41F13C51836'  -- 湾区公司
        GROUP BY a.RoomGUID,year(getDate),month(getDate)

-- 正常收款房间回笼金额 
       SELECT   g.RoomGUID ,year(g.getDate) as year,month(g.getDate) as month,
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
                and g.buguid ='248B1E17-AACB-E511-80B8-E41F13C51836'  -- 湾区公司
        GROUP BY g.RoomGUID,year(g.getDate),month(g.getdate)

--
        SELECT  a.BldGUID ,
                r.RoomGUID ,
				b.YjType ,
                year(b.RdDate) as year,
                month(b.RdDate) as month,
				--按楼栋关联，则取分摊到该房间特殊业绩认定的金额（该房间建筑面积/关联该房间特殊业绩总面积*关联该房间特殊业绩总金额）
                CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 THEN 0 ELSE (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0)) * ISNULL(a.AmountDetermined, 0)END * 10000 AS AmountDetermined ,
                --特殊业绩回笼
                CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 OR ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.huilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0)) * (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0))END AS huilongjiner 
                -- --本年特殊业绩回笼
                -- CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 OR ISNULL(b.TotalAmount, 0) = 0  THEN 0 ELSE ISNULL(t.bnhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0)) * (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0))END AS bnhuilongjiner ,
                -- --本月特殊业绩回笼
                -- CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 OR ISNULL(b.TotalAmount, 0) = 0  THEN 0 ELSE ISNULL(t.byhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0)) * (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0))END AS byhuilongjiner ,
                -- --本日特殊业绩回笼
                -- CASE WHEN ISNULL(r2.TotalBldArea, 0) = 0 OR ISNULL(b.TotalAmount, 0) = 0  THEN 0 ELSE ISNULL(t.brhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0)) * (ISNULL(r.BldArea, 0) * 1.00 / ISNULL(r2.TotalBldArea, 0))END AS brhuilongjiner
        INTO    #ts
        FROM    S_PerformanceAppraisalBuildings a
                LEFT JOIN dbo.p_room r ON a.BldGUID = r.BldGUID
                LEFT JOIN(SELECT    BldGUID ,
                                    SUM(BldArea) AS TotalBldArea
                          FROM  dbo.p_room
                          GROUP BY BldGUID) r2 ON r2.BldGUID = a.BldGUID
                LEFT JOIN S_PerformanceAppraisal b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
                LEFT JOIN(SELECT    v.SaleGUID ,year(g.getDate) as year,month(g.getDate) as month,
                                    SUM(ISNULL(g.RmbAmount, 0)) AS huilongjiner 
                                    -- SUM(CASE WHEN DATEDIFF(mm, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS byhuilongjiner ,
                                    -- SUM(CASE WHEN DATEDIFF(yy, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS bnhuilongjiner ,
                                    -- SUM(CASE WHEN DATEDIFF(DAY, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS brhuilongjiner
                          FROM  dbo.s_Voucher v
                                INNER JOIN dbo.s_Getin g ON g.VouchGUID = v.VouchGUID
                          WHERE g.SaleType = '特殊业绩' AND (v.VouchStatus IS NULL OR  v.VouchStatus = '')
                          GROUP BY v.SaleGUID,year(g.getDate),month(g.getDate)) t ON t.SaleGUID = b.PerformanceAppraisalGUID and year(b.RdDate)=t.year and month(b.RdDate)=t.month
        WHERE   b.AuditStatus = '已审核' 
                --AND b.YjType<>'经营类' --AND a.BldGUID ='9FC6AB14-D9E8-4D02-9A02-AA535B718385'
                AND b.YjType NOT IN ('经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)')
                and  r.BUGUID ='248B1E17-AACB-E511-80B8-E41F13C51836'  -- 湾区公司
        UNION
        SELECT  NULL ,
                RoomGUID ,
				b.YjType ,
                year(b.RdDate) as year,
                month(b.RdDate) as month,
                AmountDetermined * 10000 ,
                --特殊业绩回笼,关联房间回笼按照认定金额比例分摊
                CASE WHEN ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.huilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0))END AS huilongjiner 
                -- --本年特殊业绩回笼
                -- CASE WHEN ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.bnhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0))END AS bnhuilongjiner ,
                -- --本月特殊业绩回笼
                -- CASE WHEN ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.byhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0))END AS byhuilongjiner ,
                -- --本日特殊业绩回笼
                -- CASE WHEN ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.brhuilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0))END AS brhuilongjiner
        FROM    S_PerformanceAppraisalRoom a
                LEFT JOIN S_PerformanceAppraisal b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
                LEFT JOIN(SELECT    v.SaleGUID ,year(g.getDate) as year,month(g.getDate) as month,
                                    SUM(ISNULL(g.RmbAmount, 0)) AS huilongjiner 
                                    -- SUM(CASE WHEN DATEDIFF(mm, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS byhuilongjiner ,
                                    -- SUM(CASE WHEN DATEDIFF(yy, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS bnhuilongjiner ,
                                    -- SUM(CASE WHEN DATEDIFF(DAY, @var_endDate, g.GetDate) = 0 THEN ISNULL(g.RmbAmount, 0)ELSE 0 END) AS brhuilongjiner
                          FROM  dbo.s_Voucher v
                                INNER JOIN dbo.s_Getin g ON g.VouchGUID = v.VouchGUID
                          WHERE g.SaleType = '特殊业绩' AND (v.VouchStatus IS NULL OR  v.VouchStatus = '')
                          GROUP BY v.SaleGUID,year(g.getDate),month(g.getDate)) t ON t.SaleGUID = b.PerformanceAppraisalGUID and year(b.RdDate)=t.year and month(b.RdDate)=t.month
        WHERE   b.AuditStatus = '已审核'
                --AND b.YjType<>'经营类'
                AND b.YjType NOT IN ('经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)')
                


-- 汇总数据

        select 
                g.year as '年',
                g.month as '月',
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
                r.roomguid as '房间guid',
                r.RoomInfo AS '房间信息' ,
                bd.ProductType AS '产品类型' ,
                bd.ProductName AS '产品名称' ,
                bd.BldName AS '楼栋名称' ,
              --累计数
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN ISNULL(yt.ytAmount, 0)ELSE 0 END AS '应退未退累计金额' ,
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
                END AS '累计回笼金额',
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN 
                     ISNULL(g.ljdkgetAmount, 0)   ELSE 0 
                END AS '累计按揭回笼金额' ,
                CASE WHEN ts.RoomGUID IS NULL OR ts.YjType = '物业公司车位代销' OR ISNULL(sps.ifSelectRoomHkAmount, 0) = 1 THEN 
                    ISNULL(g.ljNodkgetAmount, 0) 
                END AS '累计非按揭回笼金额' 
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
                inner JOIN #g g ON g.RoomGUID = r1.RoomGUID 
                LEFT JOIN #yt yt ON yt.RoomGUID = r.RoomGUID and yt.year=g.year and yt.month=g.month
                LEFT JOIN #ts ts ON ts.RoomGUID = r.RoomGUID and ts.year=g.year and ts.month=g.month
        WHERE   r.IsVirtualRoom = 0 AND p.ApplySys LIKE '%0101%' AND p1.ApplySys LIKE '%0101%' AND  r1.isAnnexe = 0 
        and  r.BUGUID ='248B1E17-AACB-E511-80B8-E41F13C51836'  -- 湾区公司
        ORDER BY r.RoomInfo 
