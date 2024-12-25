/*
按揭房款情况表，用于分析各房间按揭及公积金款项房款情况
*/

-- DECLARE @projGUID VARCHAR(MAX) = '00B3D5B4-2B7C-EB11-B398-F40270D39969';
-- declare @buguid varchar(max) ='B2770421-F2D0-421C-B210-E6C7EF71B270';
-- DECLARE @ajfkBdate DATETIME = '2024-01-01';
-- DECLARE @ajfkEdate DATETIME = '2024-12-31';
-- DECLARE @ajdsBdate DATETIME = '2024-01-01';
-- DECLARE @ajdsEdate DATETIME = '2024-8-23';

-- 定义实收款表
WITH #getin AS (SELECT  g.Saleguid ,
                        v.Jkr ,
                        g.Bz ,
                        v.ajbank ,
                        v.gjjbank ,
                        v.GROUPbankname ,
                       -- CASE WHEN g.ItemName IN ('公积金', '保证金（公积金）') THEN v.GROUPbankname END AS gjjGROUPbankname ,
                        v.gjjGROUPbankname ,
                        SUM(g.Amount) AS FkGetAmount ,
                        SUM(CASE WHEN g.ItemType = '贷款类房款' THEN g.Amount ELSE 0 END) AS AjFkAmount ,
                        MAX(CASE WHEN g.ItemType = '贷款类房款' THEN g.GetDate END) AS LastGetDate ,
                        --公积金
                        SUM(CASE WHEN g.ItemType = '贷款类房款' AND  itemname IN ('公积金', '保证金（公积金）') THEN g.Amount ELSE 0 END) AS gjjFkAmount ,
                        MAX(CASE WHEN g.ItemType = '贷款类房款' AND  itemname IN ('公积金', '保证金（公积金）') THEN g.GetDate END) AS LastGjjGetDate
                FROM    s_getin g WITH(NOLOCK)
		        INNER JOIN(SELECT   
						    v1.ProjGUID,
							v1.VouchGUID ,
							v1.Jkr ,
						    case when g1.ItemName in ('银行按揭','按揭款','组合贷款','按揭装修款','信用卡装修房款') then  v1.ajbank  end ajbank ,
							case when g1.ItemName in ('公积金', '保证金（公积金）') then  v1.gjjbank end as  gjjbank,
							t.GROUPbankname,
                            t2.gjjGROUPbankname
					        FROM s_Voucher v1
                            inner join  s_getin g1 on v1.VouchGUID =g1.VouchGUID
                            -- 取集团按揭银行
						    OUTER APPLY(SELECT  TOP 1   sbk.GroupBankName
									FROM    s_Bank sbk
									WHERE  sbk.ProjGUID = v1.ProjGUID AND  v1.ajbank = sbk.BankName AND sbk.GroupBankName <> ''
                                                                        and g1.ItemType ='贷款类房款' ) t 
                            -- 取集团公积金银行
                            OUTER APPLY(SELECT  TOP 1   sbk.GroupBankName as gjjGROUPbankname
                                FROM    s_Bank sbk
                                WHERE  sbk.ProjGUID = v1.ProjGUID AND  v1.gjjbank = sbk.BankName AND sbk.GroupBankName <> ''
                                                                    and g1.ItemType ='贷款类房款' ) t2
                           ) v ON v.VouchGUID = g.VouchGUID
                        --LEFT JOIN [s_Bank] bk WITH(NOLOCK)ON bk.projguid = v.projguid AND  v.ajbank = bk.BankName
                        --LEFT JOIN [s_Bank] gjj WITH(NOLOCK)ON gjj.projguid = v.projguid AND v.ajbank = gjj.BankName and  g.itemname IN ('公积金', '保证金（公积金）')
                WHERE   ISNULL(g.Status, '') <> '作废' AND g.SaleType = '交易' AND  g.SaleGUID IS NOT NULL
                        -- AND  g.GetDate BETWEEN @ajfkBdate AND @ajfkEdate 
                        AND v.ProjGUID IN (@projGUID) AND   ItemType IN ('贷款类房款', '非贷款类房款')
                GROUP BY g.Saleguid ,
                         v.Jkr ,
                         g.bz ,
                         v.ajbank ,
                         v.gjjbank ,
                         v.GROUPbankname ,
                         v.gjjGROUPbankname ) ,

        -- 待收款
     #fee AS (SELECT    TradeGUID ,
                        SUM(Amount) AS YsFKAmount ,
                        SUM(CASE WHEN ItemType = '贷款类房款' THEN Amount ELSE 0 END) AS YsAjAmount ,
                        SUM(CASE WHEN ItemType = '贷款类房款' THEN ye ELSE 0 END) AS DsAjAmount ,
                        MIN(CASE WHEN ItemType = '贷款类房款' THEN lastDate END) AS NearlastDate ,                                                                                           --该房间按揭类款项最新的付款期限
                        SUM(CASE WHEN ItemType = '贷款类房款' AND   DATEDIFF(YEAR, GETDATE(), lastDate) = 0 THEN Ye ELSE 0 END) AS ThisYearDsAjAmount ,                                      -- 本年待收按揭款
                        SUM(CASE WHEN ItemType = '贷款类房款' AND   DATEDIFF(YEAR, GETDATE(), lastDate) = 1 THEN Ye ELSE 0 END) AS NextYearDsAjAmount ,                                      -- 明年待收按揭款
                                                                                                                                                                                        --公积金
                        SUM(CASE WHEN ItemType = '贷款类房款' AND   itemname IN ('公积金', '保证金（公积金）') THEN Amount ELSE 0 END) AS YsGjjAmount ,
                        SUM(CASE WHEN ItemType = '贷款类房款' AND   itemname IN ('公积金', '保证金（公积金）') THEN ye ELSE 0 END) AS DsGjjAmount ,
                        MIN(CASE WHEN ItemType = '贷款类房款' AND   itemname IN ('公积金', '保证金（公积金）') THEN lastDate END) AS NearGjjlastDate ,                                                  --该房间公积金款项最新的付款期限
                        SUM(CASE WHEN ItemType = '贷款类房款' AND   itemname IN ('公积金', '保证金（公积金）') AND DATEDIFF(YEAR, GETDATE(), lastDate) = 0 THEN Ye ELSE 0 END) AS ThisYearDsGjjAmount , -- 本年待收公积金款
                        SUM(CASE WHEN ItemType = '贷款类房款' AND   itemname IN ('公积金', '保证金（公积金）') AND DATEDIFF(YEAR, GETDATE(), lastDate) = 1 THEN Ye ELSE 0 END) AS NextYearDsGjjAmount   -- 明年待收公积金款
              FROM  s_Fee WITH(NOLOCK)
              WHERE ItemType IN ('贷款类房款', '非贷款类房款')
              --AND s_fee.lastDate BETWEEN @ajdsBdate AND @ajdsEdate
              GROUP BY TradeGUID)
--查询结果
SELECT  p.ProjGUID ,
        bu.buname as 公司名称,
        p.projname AS 项目名称 ,
		city.ParamValue as 城市,
        r.BldName AS 楼栋 ,
        r.Unit AS 单元 ,
        r.Room AS 房号 ,
        r.RoomInfo AS 房间信息 ,
        r.BldArea AS 建筑面积 ,
        gg.Jkr AS 交款人 ,
        ord.HtType AS 合同类型 ,
        ord.RgQsDate AS 认购日期 ,
        ord.QyQsDate AS 签约日期 ,
        gg.Bz AS 币种 ,
        gg.FkGetAmount AS 已收房款 ,
        ord.Status AS 状态 ,  --订单/合同状态
        ord.CloseReason AS 关闭原因 ,
        ord.JyTotal AS 合同总金额 ,
		fee.YsAjAmount as 其中按揭总金额,
        -- CASE WHEN ISNULL(ord.AjTotal, 0) = 0 THEN fee.YsAjAmount ELSE ISNULL(ord.AjTotal, 0)END AS 其中按揭总金额 ,
        gg.AjGROUPbankname   AS 按揭银行 ,
        gg.ajbank AS 按揭支行 ,
        gg.AjFkAmount AS 按揭实收 ,
        gg.LastGetDate AS 按揭放款日期 ,
        -- fee.DsAjAmount AS 按揭待收 ,
        CASE WHEN fee.DsAjAmount > 0 THEN isnull(fee.YsAjAmount,0)- ISNULL(gg.AjFkAmount, 0)
             ELSE fee.DsAjAmount
        END AS 按揭待收 ,       -- 取应收-实收
        fee.NearlastDate AS 按揭待收日期 ,
        fee.ThisYearDsAjAmount AS 按揭其中本年计划收取 ,
        fee.NextYearDsAjAmount AS 按揭其中明年计划收取 ,
        fee.YsGjjAmount AS 其中公积金总金额 ,
        gg.gjjGROUPbankname  AS 公积金银行 ,
        gg.gjjbank  AS 公积金支行 ,
        gg.gjjFkAmount AS 公积金实收 ,
        gg.LastGjjGetDate AS 公积金放款日期 ,
        --fee.DsGjjAmount AS 公积金待收 ,-- 取应收-实收
        CASE WHEN fee.DsGjjAmount > 0 THEN ISNULL(fee.YsGjjAmount, 0) - ISNULL(gg.gjjFkAmount, 0)ELSE fee.DsGjjAmount END AS 公积金待收 ,
        fee.NearGjjlastDate AS 公积金待收日期 ,
        fee.ThisYearDsGjjAmount AS 公积金其中本年计划收取 ,
        fee.NextYearDsGjjAmount AS 公积金其中明年计划收取
FROM    p_project p
        inner join mdm_Project mp on mp.ProjGUID =p.ProjGUID
	     LEFT JOIN
		 (
			 SELECT ParamGUID,
					ParamCode,
					ParamValue,
					ZTCategory
			 FROM myBizParamOption
			 WHERE ParamName = 'td_City'
		 ) city ON city.ParamGUID = mp.CityGUID
        INNER JOIN ep_room r ON r.ProjGUID = p.ProjGUID 
		inner join myBusinessUnit  bu on bu.BUGUID =p.BUGUID
        INNER JOIN(SELECT   c.projguid ,
                            c.TradeGUID ,
                            c.Status ,
                            c.RoomGUID ,
                            c.HtType ,
                            o.QSDate AS RgQsDate ,
                            c.QSDate AS QyQsDate ,
                            c.CloseReason ,
                            c.JyTotal ,
                            c.AjTotal
                   FROM s_contract c
                        LEFT JOIN s_Order o ON c.TradeGUID = o.TradeGUID AND   o.Status = '关闭' AND o.CloseReason = '转签约'
                   WHERE   c.CloseReason NOT IN ('重置认购', '折扣变更') AND   c.ProjGUID IN (@projGUID)) ord ON ord.RoomGUID = r.RoomGUID
        LEFT JOIN(SELECT    g.SaleGUID ,
                            (SELECT STUFF((SELECT   DISTINCT ',' + CONVERT(VARCHAR(200), a.Jkr)
                                           FROM #getin a
                                           WHERE a.SaleGUID = g.SaleGUID
                                          FOR XML PATH('')), 1, 1, '')) AS Jkr ,
                            (SELECT STUFF((SELECT   DISTINCT ',' + CONVERT(VARCHAR(200), a.Bz)
                                           FROM #getin a
                                           WHERE a.SaleGUID = g.SaleGUID
                                          FOR XML PATH('')), 1, 1, '')) AS Bz ,
                            (SELECT STUFF((SELECT   DISTINCT ',' + CONVERT(VARCHAR(200), a.ajbank)
                                           FROM #getin a
                                           WHERE a.SaleGUID = g.SaleGUID AND ISNULL(a.ajbank, '') <> ''
                                          FOR XML PATH('')), 1, 1, '')) AS ajbank ,
                            (SELECT STUFF((SELECT   DISTINCT ',' + CONVERT(VARCHAR(200), a.GROUPbankname)
                                           FROM #getin a
                                           WHERE a.SaleGUID = g.SaleGUID AND ISNULL(a.GROUPbankname, '') <> ''
                                          FOR XML PATH('')), 1, 1, '')) AS AjGROUPbankname ,
                            (SELECT STUFF((SELECT   DISTINCT ',' + CONVERT(VARCHAR(200), a.gjjbank)
                                           FROM #getin a
                                           WHERE a.SaleGUID = g.SaleGUID AND ISNULL(a.gjjbank, '') <> ''
                                          FOR XML PATH('')), 1, 1, '')) AS gjjbank ,
                            (SELECT STUFF((SELECT   DISTINCT ',' + CONVERT(VARCHAR(200), a.gjjGROUPbankname)
                                           FROM #getin a
                                           WHERE a.SaleGUID = g.SaleGUID
                                          FOR XML PATH('')), 1, 1, '')) AS gjjGROUPbankname ,
                            SUM(FkGetAmount) AS FkGetAmount ,
                            SUM(AjFkAmount) AS AjFkAmount ,
                            MAX(LastGetDate) AS LastGetDate ,
                            SUM(gjjFkAmount) AS gjjFkAmount ,
                            MAX(LastGjjGetDate) AS LastGjjGetDate
                  FROM  #getin g
                  GROUP BY g.SaleGUID) gg ON gg.Saleguid = ord.TradeGUID
        LEFT JOIN #fee fee ON fee.TradeGUID = ord.TradeGUID
WHERE   p.ProjGUID IN (@projGUID) AND   ((gg.LastGetDate BETWEEN (@ajfkBdate) AND (@ajfkEdate)) OR  (gg.LastGjjGetDate BETWEEN (@ajfkBdate) AND (@ajfkEdate)))
        OR   ((fee.NearlastDate BETWEEN (@ajdsBdate) AND (@ajdsEdate)) OR (fee.NearGjjlastDate BETWEEN (@ajdsBdate) AND (@ajdsEdate)))
ORDER BY p.projname ,
         r.Room;