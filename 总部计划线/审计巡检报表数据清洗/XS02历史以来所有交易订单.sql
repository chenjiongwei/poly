 -- XS02历史以来所有交易订单
 -- 此存储过程用于查询历史以来所有交易订单信息
 -- 主要用于审计巡检报表数据清洗
 use erp25
 go
create or alter proc usp_dss_XS02历史以来所有交易订单_qx
AS
BEGIN
        -- 取房间第一次定价时间
        SELECT 
            ROW_NUMBER() OVER (PARTITION BY roomguid ORDER BY tjdate) num,
            roomguid,
            tjdate,
            total,
            HSZJ,
            zxtotal,
            hltotal
        INTO #tj
        FROM s_pricechg with(nolock)
        WHERE hltotal > 0
            -- AND roomguid IN (
            --                     SELECT roomguid
            --                     FROM p_room
            --                     WHERE buguid IN (
            --                                         SELECT buguid FROM mybusinessunit a
            --                                         left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
            --                                         where b.DevelopmentCompanyGUID in (@buname)
            --                                     )
            --                 );

        -- 获取交易合同信息
        SELECT 
            c.contractguid,
            c.tradeguid,
            c.roomguid,
            c.qsdate,
            c.closedate,
            c.status
        INTO #trade
        FROM s_contract c with(nolock)
        WHERE 1=1
        -- c.BUGUID IN (
        --                     SELECT buguid FROM mybusinessunit a
        --                         left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
        --                         where b.DevelopmentCompanyGUID in (@buname)
        --                 )
        -- and c.QSDate between @var_bdate and @var_edate;

        -- 获取交易最早收款日期
        SELECT 
            o.tradeguid,
            MIN(kpdate) minkpdate,
            MIN(CreatedOn) CreatedOn
        INTO #minkpdate
        FROM s_voucher a with(nolock)
            INNER JOIN #trade o ON a.saleguid = o.tradeguid
        WHERE ISNULL(a.VouchStatus, '') <> '作废'
        GROUP BY o.tradeguid;

        -- 计算各类回款金额
        SELECT 
            r.tradeguid,
            SUM(CASE
                WHEN g.ItemType IN ('贷款类房款', '非贷款类房款') THEN
                    g.Amount
                ELSE 0
                END) dqhk,
            SUM(CASE 
                WHEN r.status='激活' and g.ItemType IN ('贷款类房款', '非贷款类房款') AND DATEDIFF(dd, g.getdate, r.qsdate) >=0 THEN g.amount
                WHEN r.status='关闭' and g.ItemType IN ('贷款类房款', '非贷款类房款') AND DATEDIFF(dd, IIF(v.CreatedOn >= g.getdate, g.getdate, v.CreatedOn), r.qsdate) >= 0 AND v.VouchType <> '退款单' THEN
                    g.amount
                ELSE 0
                END) qyshk,
            SUM(CASE
                WHEN g.ItemType IN ('贷款类房款', '非贷款类房款')
                    AND DATEDIFF(mm, g.getdate, r.qsdate) = 0 THEN
                    g.amount
                ELSE 0
                END) qydyhk,
            SUM(CASE
                WHEN g.ItemType IN ('贷款类房款', '非贷款类房款')
                    AND DATEDIFF(dd, v.kpdate, r.closedate) > 0 THEN
                    g.amount
                ELSE 0
                END) gbshk,
            SUM(CASE
                WHEN g.itemname IN ('滞纳金', '违约金') THEN
                    g.amount
                ELSE 0
                END) wyjsk
        INTO #dqhk
        FROM #trade r
            LEFT JOIN dbo.s_Getin g with(nolock) ON g.SaleGUID = r.TradeGUID
            LEFT JOIN s_voucher v with(nolock) ON g.vouchguid = v.vouchguid
        WHERE g.ItemType IN ('贷款类房款', '非贷款类房款')
            AND g.Status IS NULL
        GROUP BY r.tradeguid;

        -- 获取交易缴款人信息
        SELECT DISTINCT
            tradeguid,
            Jkr,
            VouchType
        INTO #s_voucher
        FROM s_Voucher v with(nolock)
            INNER JOIN #trade c ON v.SaleGUID = c.tradeguid
        WHERE v.VouchType <> '退款单';

        -- 合并缴款人信息
        SELECT 
            tradeguid,
            Jkr = STUFF(
                    (
                        SELECT ',' + Jkr
                        FROM #s_voucher t
                        WHERE tradeguid = t1.tradeguid
                        FOR XML PATH('')
                    ),
                    1,
                    1,
                    ''
                )
        INTO #jkr
        FROM #trade t1
        GROUP BY tradeguid;

        -- 获取定金缴纳日期
        SELECT 
            r.tradeguid,
            MIN(g.getdate) ddate
        INTO #djdate
        FROM #trade r
            LEFT JOIN dbo.s_Getin g with(nolock) ON g.SaleGUID = r.TradeGUID
        WHERE g.ItemType IN ('贷款类房款', '非贷款类房款')
            AND g.Status IS NULL
            AND g.itemname = '定金'
        GROUP BY r.tradeguid;

        -- 获取最后一笔回款时间
        SELECT 
            r.tradeguid,
            MAX(g.GetDate) lstime
        INTO #lstime
        FROM #trade r
            OUTER APPLY
        (
            SELECT TOP 1
                g1.SaleGUID,
                g1.GetDate
            FROM dbo.s_Getin g1 with(nolock)
            WHERE g1.SaleGUID = r.TradeGUID
                AND ISNULL(g1.Status, '') = ''
                AND g1.ItemType IN ('非贷款类房款', '贷款类房款')
            ORDER BY g1.GetDate DESC
        ) g
        GROUP BY r.tradeguid;

        -- 价格拆分折扣情况
        SELECT 
            saleguid,
            SUM(PreferentialPrice) cfje
        INTO #cf
        FROM s_OCDiscount with(nolock)
        WHERE DiscntName = '价格拆分折扣(房款)'
        GROUP BY saleguid;

        -- 获取房间最新交易状态
        SELECT 
            a.RoomGUID,
            isnull(b.JyTotal, a.JyTotal) JyTotal,
            b.QSDate
        INTO #lastTrade
        FROM s_order a with(nolock)
            LEFT JOIN s_contract b with(nolock) on a.TradeGUID = b.TradeGUID and a.CloseReason = '转签约' and b.status = '激活'
            LEFT JOIN mybusinessunit bu with(nolock) ON a.buguid = bu.buguid
        WHERE (a.status = '激活' or (a.CloseReason = '转签约' and b.status = '激活'))
        -- and bu.BUGUID IN (
        --                     SELECT buguid FROM mybusinessunit a
        --                         left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
        --                         where b.DevelopmentCompanyGUID in (@buname)
        --                 );

        -- 获取重置认购信息
        SELECT DISTINCT
            tradeguid
        INTO #czrg
        FROM s_contract with(nolock)
        WHERE closereason = '重置认购';

        -- 删除数据
        TRUNCATE Table XS02历史以来所有交易订单_qx
        
        -- 最终查询结果
        insert into  XS02历史以来所有交易订单_qx 
        SELECT 
            --bu.buname 公司名称,
            ISNULL(p1.projname, p.projname) 项目名称,
            ISNULL(p1.spreadname, p.spreadname) 推广名称,
            r.ProductType 产品,
            r.roominfo 房间,
            CASE
                WHEN CstName2.CstName IS NULL THEN
                    CstName1.CstName
                WHEN CstName3.CstName IS NULL THEN
                    CstName1.CstName + ';' + CstName2.CstName
                WHEN CstName4.CstName IS NULL THEN
                    CstName1.CstName + ';' + CstName2.CstName + ';' + CstName3.CstName
                ELSE CstName1.CstName + ';' + CstName2.CstName + ';' + CstName3.CstName + ';' + CstName4.CstName
            END AS '客户名称',
            CASE
                WHEN CstName2.cardID IS NULL THEN
                    CstName1.cardID
                WHEN CstName3.cardID IS NULL THEN
                    CstName1.cardID + ';' + CstName2.cardID
                WHEN CstName4.cardID IS NULL THEN
                    CstName1.cardID + ';' + CstName2.cardID + ';' + CstName3.cardID
                ELSE CstName1.cardID + ';' + CstName2.cardID + ';' + CstName3.cardID + ';' + CstName4.cardID
            END AS '身份证号',
            CASE
                WHEN CstName2.MobileTel IS NULL THEN
                    CstName1.MobileTel
                WHEN CstName3.MobileTel IS NULL THEN
                    CstName1.MobileTel + ';' + CstName2.MobileTel
                WHEN CstName4.MobileTel IS NULL THEN
                    CstName1.MobileTel + ';' + CstName2.MobileTel + ';' + CstName3.MobileTel
                ELSE CstName1.MobileTel + ';' + CstName2.MobileTel + ';' + CstName3.MobileTel + ';' + CstName4.MobileTel
            END AS '联系电话',
            c.httype AS '合同类型',
            --c.contractno AS '合同编号',
            c.CstSource 客户来源,
            o.qsdate 认购时间,
            c.qsdate 签约时间,
            c.CreatedOn 合同创建日期,
            c.BldArea 建筑面积,
            c.TnArea 套内面积,
            --c.LZZDate 临转正日期,
            --CASE
            --    WHEN czrg.tradeguid IS NOT NULL THEN
            --         '是'
            --    ELSE '否'
            --END 是否有重置认购,
            dj.ddate 定金刷卡时间,
            tj.tjdate 第一次定价时间,
            --c.jfdate 约定交房时间,
            --c.bano 备案号,
            --c.badate 备案时间,
            r.FGJBAPrice as '交易备案价',
            tj.total 第一次定价房间总价,
            tj.HSZJ 第一次定价回收总价,
            tj.zxtotal 第一次定价装修款,
            tj.hltotal 第一次定价货量总价,
            c.total 成交时房间总价,
            c.ZxTotalZq 成交时房间装修款,
            c.ZxTotal 成交后装修款金额,
            c.roomtotal 成交后房间金额,
            c.jytotal 成交金额,
            c.PayformName 付款方式,
            --CASE WHEN ISNULL(cf.cfje, 0) > 0 THEN '是' ELSE '否' END 是否价格拆分,
            --cf.cfje 价格拆分金额,
            c.DiscntValue 折扣值,
            c.total + c.ZxTotal - c.jytotal 折扣金额,
            c.DiscntRemark 折扣说明,
            --r.blrhdate 实际交房日期,
            hk.qyshk 签约时缴款金额,
            jkr.Jkr 缴款人,
            --hk.qydyhk 签约当月回款,
            hk.dqhk 当前缴款金额,
            lt.lstime 最后一笔回款时间,
            c.ywy 代理公司,
            CASE
                WHEN isnull(c.xsjl2,'') = '' THEN
                    c.Xsjl 
                WHEN isnull(c.xsjl3,'') = '' THEN
                    c.Xsjl + ';' + c.Xsjl2
                ELSE c.Xsjl + ';' + c.Xsjl2 + ';' + c.Xsjl3 
            END AS '销售经理',
            CASE
                WHEN isnull(c.zygw2,'') = '' THEN
                    c.Zygw
                WHEN isnull(c.zygw3,'') = '' THEN
                    c.Zygw + ';' + c.zygw2
                ELSE c.Zygw + ';' + c.zygw2 + ';' + c.zygw3
            END AS '置业顾问',
            r.status 对应房间销售状态,
            case when isnull(o.IsUnderWritten,'') = 1 then '包销;' else '' end 
            +
            case when isnull(o.isldf,'') = 1 then '联动房' else '' end 房源标记,
            CASE 
                WHEN c.AgentfeeTypeCode = '10000' THEN '普通市场客户'
                WHEN c.AgentfeeTypeCode = '10001' THEN '甲方资源客户'
                WHEN c.AgentfeeTypeCode = '10002' THEN '员工购房'
                WHEN c.AgentfeeTypeCode = '10003' THEN '大客户团购'
                WHEN c.AgentfeeTypeCode = '10004' THEN '合作方购房'
                WHEN c.AgentfeeTypeCode = '10005' THEN '普通市场客户（开展主体是开发）'
                WHEN c.AgentfeeTypeCode = '10006' THEN '甲方客户资源（开展主体是开发）'
                WHEN c.AgentfeeTypeCode = '10007' THEN '员工购房（开展主体是开发）'
                WHEN c.AgentfeeTypeCode = '10008' THEN '大客户团购（开展主体是开发）'
                WHEN c.AgentfeeTypeCode = '10009' THEN '普通市场客户（开展主体是代理）'
                WHEN c.AgentfeeTypeCode = '10010' THEN '甲方客户资源（开展主体是代理）'
                WHEN c.AgentfeeTypeCode = '10011' THEN '员工购房（开展主体是代理）'
                WHEN c.AgentfeeTypeCode = '10012' THEN '大客户团购（开展主体是代理）'
                WHEN c.AgentfeeTypeCode = '10013' THEN '联动房'
                ELSE '无' END 代理费结算类型,
            --c.AgentfeeTypeCode 代理费结算类型,
            c.status 当前订单状态,
            c.closereason 关闭原因,
            c.closedate 关闭时间,
            hk.gbshk 关闭时累计缴款金额,
            lt2.QSDate 最新激活交易签署日期,
            hk.wyjsk 是否缴纳违约金或者滞纳金,
            c.LastMender 此订单最后操作人,
            c.ModiDate 最后操作时间,
            bu.buname 公司名称,
            minKp.minkpdate 首次收款日期,
            minKp.CreatedOn 首次收款录入日期
        -- into XS02历史以来所有交易订单_qx
        FROM s_contract c with(nolock)
            INNER JOIN #trade tr ON c.contractguid = tr.contractguid
            LEFT JOIN #czrg czrg ON c.tradeguid = czrg.tradeguid
            LEFT JOIN #dqhk hk ON c.tradeguid = hk.tradeguid
            LEFT JOIN #lstime lt ON c.tradeguid = lt.tradeguid
            LEFT JOIN #tj tj ON c.roomguid = tj.roomguid
                                AND tj.num = 1
            --LEFT JOIN #cf cf ON c.contractguid = cf.saleguid
            LEFT JOIN #djdate dj ON c.tradeguid = dj.tradeguid
            LEFT JOIN #jkr jkr ON c.tradeguid = jkr.tradeguid
            LEFT JOIN myBusinessUnit bu with(nolock) ON c.buguid = bu.buguid
            INNER JOIN ep_room r with(nolock) ON c.roomguid = r.roomguid
            LEFT JOIN p_project p with(nolock) ON c.projguid = p.projguid
            LEFT JOIN p_project p1 with(nolock) ON p.parentcode = p1.projcode
                                    AND p1.applysys LIKE '%0101%'
            LEFT JOIN s_Order o with(nolock) ON c.TradeGUID = o.TradeGUID
                                    AND o.CloseReason = '转签约'
            LEFT JOIN s_Trade2Cst Cst1 with(nolock) ON c.tradeGUID = Cst1.tradeGUID
                                        AND Cst1.CstNum = 1
            LEFT JOIN p_Customer CstName1 with(nolock) ON Cst1.CstGUID = CstName1.CstGUID
            LEFT JOIN s_Trade2Cst Cst2 with(nolock) ON c.tradeGUID = Cst2.tradeGUID
                                        AND Cst2.CstNum = 2
            LEFT JOIN p_Customer CstName2 with(nolock) ON Cst2.CstGUID = CstName2.CstGUID
            LEFT JOIN s_Trade2Cst Cst3 with(nolock) ON c.tradeGUID = Cst3.tradeGUID
                                        AND Cst3.CstNum = 3
            LEFT JOIN p_Customer CstName3 with(nolock) ON Cst3.CstGUID = CstName3.CstGUID
            LEFT JOIN s_Trade2Cst Cst4 with(nolock) ON c.tradeGUID = Cst4.tradeGUID
                                        AND Cst4.CstNum = 4
            LEFT JOIN p_Customer CstName4 with(nolock) ON Cst4.CstGUID = CstName4.CstGUID
            LEFT JOIN #minkpdate minKp ON minKp.TradeGUID = c.TradeGUID
            LEFT JOIN #lastTrade lt2 on lt2.RoomGUID = c.RoomGUID

        WHERE 1=1 -- c.QSDate between @var_bdate and @var_edate
        ORDER BY 项目名称

        -- 清理临时表
        DROP TABLE #tj,
                #trade,
                #dqhk,
                #s_voucher,
                #jkr,
                #djdate,
                #lstime,
                #cf,
                #czrg,
                #minkpdate,
                #lastTrade;

end 