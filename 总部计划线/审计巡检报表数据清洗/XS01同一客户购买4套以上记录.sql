
use erp25
go
-- XS01同一客户购买4套以上记录
-- 此存储过程用于查询同一客户购买4套以上房产的记录
-- 主要用于审计巡检报表数据清洗

-- exec  usp_dss_XS01同一客户购买4套以上记录_qx
create or  alter  proc usp_dss_XS01同一客户购买4套以上记录_qx
as 
begin 
        --DECLARE @buname VARCHAR(20);
        --SET @buname = '浙江公司';

        -- 获取业主变更记录信息
        SELECT 
            a.SaleModiLogGUID,
            a.ForeSaleGUID,
            a.ForeSaleType,
            a.applydate,
            ISNULL(p1.projguid, p.projguid) projguid,
            ISNULL(o.tradeguid, c.TradeGUID) TradeGUID,
            ISNULL(o.roomguid, c.roomguid) roomguid,
            Value
        INTO #bgkh
        FROM s_SaleModiLog a with(nolock)
            LEFT JOIN p_project p with(nolock) ON a.projguid = p.projguid
            LEFT JOIN p_project p1 with(nolock) ON p.parentcode = p1.projcode
                                    AND p1.applysys LIKE '%0101%'
            LEFT JOIN s_order o with(nolock) ON a.ForeSaleGUID = o.orderguid
            LEFT JOIN s_contract c with(nolock) ON a.ForeSaleGUID = c.ContractGUID
            CROSS APPLY dbo.fn_Split1(a.PastObligeeGUID, ';')
        WHERE ApplyType = '增减权益人'
            --   AND a.buguid IN (
                                
            --                       SELECT buguid FROM mybusinessunit a
            --                       left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
            --                       where b.DevelopmentCompanyGUID in (@buname)
            --                   );


        -- 获取交易客户信息（订单）
        SELECT 
            o.orderguid logguid,
            o.orderguid saleguid,
            '定单' jytype,
            ISNULL(p1.projguid, p.projguid) projguid,
            o.tradeguid,
            o.roomguid,
            t.cstguid
        INTO #cjkh
        FROM s_order o with(nolock)
            LEFT JOIN p_project p with(nolock) ON o.projguid = p.projguid
            LEFT JOIN p_project p1 with(nolock) ON p.parentcode = p1.projcode
                                    AND p1.applysys LIKE '%0101%'
            LEFT JOIN s_trade2cst t with(nolock) ON o.tradeguid = t.tradeguid
        WHERE 1=1   
            -- o.buguid IN (
            --                       SELECT buguid FROM mybusinessunit a
            --                       left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
            --                       where b.DevelopmentCompanyGUID in (@buname)
            --               )
            AND
            (
                o.status = '激活'
                OR o.closereason = '退房'
            )
        UNION
        -- 获取交易客户信息（合同）
        SELECT 
            o.contractguid,
            o.contractguid,
            '合同' jytype,
            ISNULL(p1.projguid, p.projguid) projguid,
            o.tradeguid,
            o.roomguid,
            t.cstguid
        FROM s_contract o with(nolock)
            LEFT JOIN p_project p with(nolock) ON o.projguid = p.projguid
            LEFT JOIN p_project p1 with(nolock) ON p.parentcode = p1.projcode
                                    AND p1.applysys LIKE '%0101%'
            LEFT JOIN s_trade2cst t with(nolock) ON o.tradeguid = t.tradeguid
        WHERE 1=1 
            --    o.buguid IN (
            --                   SELECT buguid FROM mybusinessunit a
            --                   left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
            --                   where b.DevelopmentCompanyGUID in (@buname)
            --               )
            AND
            (
                o.status = '激活'
                OR o.closereason = '退房'
            );

        -- 统计同一客户在同一项目中购买的套数
        SELECT 
            projguid,
            cstguid,
            COUNT(1) ts
        INTO #re
        FROM
        (
            SELECT 
                projguid,
                TradeGUID,
                roomguid,
                Value cstguid
            FROM #bgkh
            WHERE Value <> ''
            UNION
            SELECT 
                projguid,
                tradeguid,
                roomguid,
                cstguid
            FROM #cjkh
        ) a
        GROUP BY projguid,
                cstguid
        HAVING (COUNT(1)) > 3;  -- 筛选购买超过3套的客户
        
        -- 获取原业主信息
        SELECT 
            o.*,
            p.cstname,
            p.cardid
        INTO #oldname
        FROM #bgkh o
            LEFT JOIN p_customer p with(nolock) ON o.Value = p.cstguid
        WHERE o.Value <> ''

        -- 合并原业主姓名和身份证信息
        SELECT 
            SaleModiLogGUID,
            name = STUFF(
                    (
                        SELECT ';' + L.cstname
                        FROM #oldname L
                        WHERE t.SaleModiLogGUID = L.SaleModiLogGUID
                        FOR XML PATH('')
                    ),
                    1,
                    1,
                    ''
                        ),
            cardid = STUFF(
                        (
                            SELECT ';' + L.cardid
                            FROM #oldname L
                            WHERE t.SaleModiLogGUID = L.SaleModiLogGUID
                            FOR XML PATH('')
                        ),
                        1,
                        1,
                        ''
                            )
        INTO #oldnamecard
        FROM s_SaleModiLog t with(nolock)
        WHERE t.ApplyType = '增减权益人'
            --   AND t.buguid IN (
            --                     SELECT buguid FROM mybusinessunit a
            --                       left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
            --                       where b.DevelopmentCompanyGUID in (@buname)
            --                   );

        -- 获取新业主GUID
        SELECT 
            SaleModiLogGUID,
            Value
        INTO #new1
        FROM s_SaleModiLog a with(nolock)
            CROSS APPLY dbo.fn_Split1(a.nowObligeeGUID, ';')
        WHERE ApplyType = '增减权益人'
            --   AND buguid IN (
            --                     SELECT buguid FROM mybusinessunit a
            --                       left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
            --                       where b.DevelopmentCompanyGUID in (@buname)
            --                 );

        -- 筛选有效的新业主GUID
        SELECT *
        INTO #new
        FROM #new1
        WHERE LEN(Value) = 36;

        -- 获取新业主信息
        SELECT 
            o.*,
            p.cstname,
            p.cardid
        INTO #newname
        FROM #new o
            LEFT JOIN p_customer p with(nolock) ON o.Value = p.cstguid;

        -- 合并新业主姓名和身份证信息
        SELECT 
            SaleModiLogGUID,
            name = STUFF(
                    (
                        SELECT ';' + L.cstname
                        FROM #newname L
                        WHERE t.SaleModiLogGUID = L.SaleModiLogGUID
                        FOR XML PATH('')
                    ),
                    1,
                    1,
                    ''
                        ),
            cardid = STUFF(
                        (
                            SELECT ';' + L.cardid
                            FROM #newname L
                            WHERE t.SaleModiLogGUID = L.SaleModiLogGUID
                            FOR XML PATH('')
                        ),
                        1,
                        1,
                        ''
                            )
        INTO #newnamecard
        FROM s_SaleModiLog t with(nolock)
        WHERE t.ApplyType = '增减权益人'
            --   AND t.buguid IN (
            --                      SELECT buguid FROM mybusinessunit a
            --                       left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
            --                       where b.DevelopmentCompanyGUID in (@buname)
            --                   );

        -- 获取是否直系亲属信息
        SELECT 
            SaleGUID,
            applydate,
            CASE
                WHEN IsFamily = 1 THEN '是'
                ELSE '否'
            END 是否直系亲属
        INTO #zxqs
        FROM s_SaleModiApply with(nolock)
        WHERE ApplyType = '增减权益人'
            --   AND buguid IN (
            --                     SELECT buguid FROM mybusinessunit a
            --                       left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
            --                       where b.DevelopmentCompanyGUID in (@buname)
            --                 );

        -- 获取回款情况（更名前后）
        SELECT 
            r.TradeGUID,
            SUM(CASE
                WHEN DATEDIFF(dd, g.getdate, r.ApplyDate) >= 0 THEN g.Amount
                ELSE 0
                END) sqqhk,  -- 更名前回款
            SUM(CASE
                WHEN DATEDIFF(dd, g.getdate, r.ApplyDate) < 0 THEN g.Amount
                ELSE 0
                END) sqhhk   -- 更名后回款
        INTO #hk
        FROM
        (
            SELECT DISTINCT
                SaleModiLogGUID,
                ForeSaleGUID,
                applydate,
                TradeGUID
            FROM #bgkh
        ) r
        LEFT JOIN dbo.s_Getin g with(nolock) ON g.SaleGUID = r.TradeGUID
        WHERE g.ItemType IN ('贷款类房款', '非贷款类房款')
            AND g.Status IS NULL
        GROUP BY r.TradeGUID;

        -- 判断是否首付分期
        SELECT 
            r.TradeGUID,
            case when sum(case when g.ItemType = '贷款类房款' then 1 else 0 end) = 0 then '否'
                else 
                    case when sum(case when g.itemtype = '非贷款类房款' then 1 else 0 end) > 2 then '是'
                    else '否'
                    end 
                end sffq
        INTO #sffq1
        FROM
        (
            SELECT DISTINCT
                TradeGUID
            FROM #bgkh
        ) r
        LEFT JOIN dbo.s_fee g with(nolock) ON g.TradeGUID = r.TradeGUID
        WHERE g.ItemType IN ('贷款类房款', '非贷款类房款')
        GROUP BY r.TradeGUID;

        -- 获取违约金/滞纳金情况
        SELECT 
            r.TradeGUID,
            SUM(g.Amount) sk
        INTO #hk1
        FROM
        (
            SELECT DISTINCT
                SaleModiLogGUID,
                ForeSaleGUID,
                applydate,
                TradeGUID
            FROM #bgkh
        ) r
        LEFT JOIN dbo.s_Getin g with(nolock) ON g.SaleGUID = r.TradeGUID
        WHERE (g.Itemname like '%滞纳金%' or g.status like '%违约金%')
            AND g.Status IS NULL
        GROUP BY r.TradeGUID;

        -- 获取缴款人信息
        SELECT DISTINCT
            tradeguid,
            Jkr,
            v.kpdate
        INTO #s_voucher
        FROM s_Voucher v with(nolock)
            INNER JOIN #bgkh c ON v.SaleGUID = c.tradeguid
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
                        ),
            gmhJkr = STUFF(
                    (
                        SELECT ',' + Jkr
                        FROM #s_voucher t
                        WHERE tradeguid = t1.tradeguid
                        and t.kpdate >= min(t1.ApplyDate)
                        FOR XML PATH('')
                    ),
                    1,
                    1,
                    ''
                        )
        INTO #jkr
        FROM #bgkh t1
        GROUP BY tradeguid;

        -- 获取变更业主的房产信息结果集
        SELECT 
            old.name 原业主姓名,
            old.cardid 原业主身份证,
            p.projname 购买的项目名称,
            r.roominfo 房间全称,
            r.bldarea 购买的房间面积,
            ISNULL(c.jytotal, o.jytotal) 成交总价,
            ISNULL(o1.qsdate, o.qsdate) 认购时间,
            c.qsdate 签约时间,
            ISNULL(c.Discntvalue, o.Discntvalue) 成交折扣,
            CONVERT(VARCHAR(30), ISNULL(c.DiscntRemark, o.DiscntRemark)) 折扣说明,
            isnull(o1.ywy,o.ywy) 所属代理公司,
            isnull(o1.Zygw,o.Zygw) 跟进的置业顾问,
            case when isnull(o1.IsUnderWritten,o.IsUnderWritten) = 1 then '包销;' else '' end 
                +
            case when isnull(o1.isldf,o.isldf) = 1 then '联动房' else '' end 房源标记,
            jkr.jkr 缴款人,
            sffq.sffq 是否首付分期,
            isnull(o1.PayformName,o.PayformName) 付款方式,
            case when isnull(c.status,o.status) = '关闭' then '是' else '否' end 是否关闭,
            isnull(c.closereason,o.closereason) 关闭原因,
            isnull(c.closedate,o.closedate) 关闭时间,
            (isnull(hk.sqqhk,0)+isnull(hk.sqhhk,0)) / isnull(c.jytotal,o.jytotal) 已收款比例,
            case when hk1.sk > 0 then '是' else '否' end 是否缴纳违约金或者滞纳金,
            isnull(c.closereason,o.closereason) 关闭说明,
            zx.是否直系亲属 是否直系亲属更名,
            new.name 更名后业主名,
            jkr.gmhJkr 更名后缴款人,
            bu.buname 公司
        INTO #result1
        FROM #bgkh a
            INNER JOIN #re rr ON a.projguid = rr.projguid
                                AND a.value = rr.cstguid
            LEFT JOIN s_order o with(nolock) ON a.ForeSaleGUID = o.orderguid
            LEFT JOIN s_contract c with(nolock) ON a.ForeSaleGUID = c.contractguid
            LEFT JOIN s_order o1 with(nolock) ON c.lastsaleguid = o1.orderguid
                                    AND o1.closereason = '转签约'
            LEFT JOIN p_project p with(nolock) ON a.projguid = p.projguid
            INNER JOIN ep_room r with(nolock) ON a.roomguid = r.roomguid
            LEFT JOIN mybusinessunit bu with(nolock) ON bu.buguid = r.buguid
            LEFT JOIN #oldnamecard old ON a.SaleModiLogGUID = old.SaleModiLogGUID
            LEFT JOIN #newnamecard new ON a.SaleModiLogGUID = new.SaleModiLogGUID
            LEFT JOIN #zxqs zx ON a.ForeSaleGUID = zx.saleguid
                                AND a.applydate = zx.applydate
            LEFT JOIN #hk hk ON a.TradeGUID = hk.TradeGUID
            LEFT JOIN #hk1 hk1 ON a.TradeGUID = hk1.TradeGUID
            LEFT JOIN #jkr jkr ON a.TradeGUID = jkr.TradeGUID
            LEFT JOIN #sffq1 sffq ON sffq.TradeGUID = a.TradeGUID
        WHERE a.value <> ''

        -- 获取未变更业主的房产回款情况
        SELECT 
            r.TradeGUID,
            SUM(g.Amount) sk
        INTO #hk2
        FROM
        (
            SELECT DISTINCT
                TradeGUID
            FROM #cjkh
        ) r
        LEFT JOIN dbo.s_Getin g with(nolock) ON g.SaleGUID = r.TradeGUID
        WHERE g.ItemType IN ('贷款类房款', '非贷款类房款')
            AND g.Status IS NULL
        GROUP BY r.TradeGUID;

        -- 获取未变更业主的违约金/滞纳金情况
        SELECT 
            r.TradeGUID,
            SUM(g.Amount) sk
        INTO #hk3
        FROM
        (
            SELECT DISTINCT
                TradeGUID
            FROM #cjkh
        ) r
        LEFT JOIN dbo.s_Getin g with(nolock) ON g.SaleGUID = r.TradeGUID
        WHERE (g.Itemname like '%滞纳金%' or g.status like '%违约金%')
            AND g.Status IS NULL
        GROUP BY r.TradeGUID;

        -- 获取未变更业主的缴款人信息
        SELECT DISTINCT
            tradeguid,
            Jkr,
            v.kpdate
        INTO #s_voucher1
        FROM s_Voucher v with(nolock)
            INNER JOIN #cjkh c ON v.SaleGUID = c.tradeguid
        WHERE v.VouchType <> '退款单';

        -- 合并未变更业主的缴款人信息
        SELECT 
            tradeguid,
            Jkr = STUFF(
                    (
                        SELECT ',' + Jkr
                        FROM #s_voucher1 t
                        WHERE tradeguid = t1.tradeguid
                        FOR XML PATH('')
                    ),
                    1,
                    1,
                    ''
                        )
        INTO #jkr1
        FROM #cjkh t1
        GROUP BY tradeguid;	 

        -- 判断未变更业主是否首付分期
        SELECT 
            r.TradeGUID,
            case when sum(case when g.ItemType = '贷款类房款' then 1 else 0 end) = 0 then '否'
                else 
                    case when sum(case when g.itemtype = '非贷款类房款' then 1 else 0 end) > 2 then '是'
                    else '否'
                    end 
                end sffq
        INTO #sffq
        FROM
        (
            SELECT DISTINCT
                TradeGUID
            FROM #cjkh
        ) r
        LEFT JOIN dbo.s_fee g with(nolock) ON g.TradeGUID = r.TradeGUID
        WHERE g.ItemType IN ('贷款类房款', '非贷款类房款')
        GROUP BY r.TradeGUID;

        -- 获取未变更业主的房产信息结果集
        SELECT 
            cst.cstname 原业主姓名,
            cst.cardid 原业主身份证,
            p.projname 购买的项目名称,
            r.roominfo 房间全称,
            r.bldarea 购买的房间面积,
            ISNULL(c.jytotal, o.jytotal) 成交总价,
            ISNULL(o1.qsdate, o.qsdate) 认购时间,
            c.qsdate 签约时间,
            ISNULL(c.Discntvalue, o.Discntvalue) 成交折扣,
            CONVERT(VARCHAR(30), ISNULL(c.DiscntRemark, o.DiscntRemark)) 折扣说明,
            isnull(o1.ywy,o.ywy) 所属代理公司,
            isnull(o1.Zygw,o.Zygw) 跟进的置业顾问,
            case when isnull(o1.IsUnderWritten,o.IsUnderWritten) = 1 then '包销;' else '' end 
                +
            case when isnull(o1.isldf,o.isldf) = 1 then '联动房' else '' end 房源标记,
            jkr.Jkr 缴款人,
            sffq.sffq 是否首付分期,
            isnull(o1.PayformName,o.PayformName) 付款方式,
            case when isnull(c.status,o.status) = '关闭' then '是' else '否' end 是否关闭,
            isnull(c.closereason,o.closereason) 关闭原因,
            isnull(c.closedate,o.closedate) 关闭时间,
            case when isnull(c.jytotal,o.jytotal) = 0 then 0 else (isnull(hk2.sk,0)) / isnull(c.jytotal,o.jytotal) end 已收款比例,
            case when hk3.sk > 0 then '是' else '否' end 是否缴纳违约金或者滞纳金,
            isnull(c.closereason,o.closereason) 关闭说明,
            NULL 是否直系亲属更名,
            NULL 更名后业主名,
            NULL 更名后缴款人
        INTO #result2
        FROM #cjkh a
            INNER JOIN #re rr ON a.projguid = rr.projguid
                                AND a.cstguid = rr.cstguid
            LEFT JOIN p_customer cst with(nolock) ON cst.cstguid = a.cstguid
            LEFT JOIN s_order o with(nolock) ON a.logguid = o.orderguid
            LEFT JOIN s_contract c with(nolock) ON a.logguid = c.contractguid
            LEFT JOIN s_order o1 with(nolock) ON c.lastsaleguid = o1.orderguid
                                    AND o1.closereason = '转签约'
            LEFT JOIN p_project p with(nolock) ON a.projguid = p.projguid
            INNER JOIN ep_room r with(nolock) ON a.roomguid = r.roomguid
            LEFT JOIN mybusinessunit bu with(nolock) ON bu.buguid = r.buguid
            LEFT JOIN #jkr1 jkr ON jkr.TradeGUID = a.TradeGUID
            LEFT JOIN #hk2 hk2 ON hk2.TradeGUID = a.TradeGUID
            LEFT JOIN #hk3 hk3 ON hk3.TradeGUID = a.TradeGUID
            LEFT JOIN #sffq sffq ON sffq.TradeGUID = a.TradeGUID;

        TRUNCATE table XS01同一客户购买4套以上记录_qx;

        -- 合并两个结果集并按项目名称排序输出最终结果
        insert  into XS01同一客户购买4套以上记录_qx
        SELECT *
        -- into XS01同一客户购买4套以上记录_qx
        FROM
        (
            SELECT 
                原业主姓名,
                原业主身份证,
                购买的项目名称,
                房间全称,
                购买的房间面积,
                成交总价,
                认购时间,
                签约时间,
                成交折扣,
                折扣说明,
                所属代理公司,
                跟进的置业顾问,
                房源标记,
                缴款人,
                是否首付分期,
                付款方式,
                是否关闭,
                关闭原因,
                关闭时间,
                已收款比例,
                是否缴纳违约金或者滞纳金,
                关闭说明,
                convert(varchar(100),是否直系亲属更名) 是否直系亲属更名,
                convert(varchar(100),更名后业主名) 更名后业主名,
                convert(varchar(100),更名后缴款人) 更名后缴款人
            FROM #result1
            UNION
            SELECT 
                原业主姓名,
                原业主身份证,
                购买的项目名称,
                房间全称,
                购买的房间面积,
                成交总价,
                认购时间,
                签约时间,
                成交折扣,
                折扣说明,
                所属代理公司,
                跟进的置业顾问,
                房源标记,
                缴款人,
                是否首付分期,
                付款方式,
                是否关闭,
                关闭原因,
                关闭时间,
                已收款比例,
                是否缴纳违约金或者滞纳金,
                关闭说明,
                convert(varchar(100),是否直系亲属更名) 是否直系亲属更名,
                convert(varchar(100),更名后业主名) 更名后业主名,
                convert(varchar(100),更名后缴款人) 更名后缴款人
            FROM #result2
        ) a
        ORDER BY 购买的项目名称;

        -- 清理临时表
        DROP TABLE 
            #bgkh,
            #cjkh,
            #hk,
            #new,
            #new1,
            #newname,
            #newnamecard,
            #oldname,
            #oldnamecard,
            #re,
            #zxqs,
            #result1,
            #result2,
            #hk1,
            #hk2,
            #hk3,
            #jkr,
            #jkr1,
            #s_voucher,
            #s_voucher1,
            #sffq,
            #sffq1;

end 
