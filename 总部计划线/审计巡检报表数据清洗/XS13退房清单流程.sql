
-- XS13退房清单流程
-- 此存储过程用于获取退房清单数据，包括签约退房和认购退房
-- 注释掉的参数可用于按公司筛选数据
--DECLARE @buname VARCHAR(20);
--SET @buname = '陕西公司';
use erp25
go

create or alter proc usp_dss_XS13退房清单流程_qx
as 
begin 
        -- 获取退房申请相关的工作流程实体
        SELECT m.ProcessGUID,
            syq.SaleModiApplyGUID
        INTO #myWorkflowProcessEntity
        FROM myWorkflowProcessEntity m WITH(NOLOCK)
            INNER JOIN s_SaleModiApply syq WITH(NOLOCK) ON m.BusinessGUID = syq.SaleModiApplyGUID
                                            AND syq.ApplyType = '退房'
        WHERE m.ProcessStatus = '2';  -- 状态为2表示已完成的流程


        -- 获取流程审批路径信息，判断是否经过总部、董事长、总经理审批
        SELECT DISTINCT
            m.ProcessGUID,
            m.SaleModiApplyGUID,
            MAX(   CASE
                        WHEN p.StepName LIKE '%总部%'
                            OR p.StepName LIKE '%集团%' THEN
                            '是'
                        ELSE '否'
                    END
                ) 是否过总部,
            MAX(   CASE
                        WHEN p.StepName LIKE '%董事长%' THEN
                            '是'
                        ELSE '否'
                    END
                ) 是否过董事长,
            MAX(   CASE
                        WHEN p.StepName LIKE '%总经理%' THEN
                            '是'
                        ELSE '否'
                    END
                ) 是否过总经理
        INTO #sf
        FROM #myWorkflowProcessEntity m
            LEFT JOIN myWorkflowStepPathEntity p WITH(NOLOCK) ON m.ProcessGUID = p.ProcessGUID
        GROUP BY m.ProcessGUID,
                m.SaleModiApplyGUID;


        -- 获取每个流程的最后一个审批人信息
        SELECT a.row,
            a.ProcessGUID,
            a.AuditorName
        INTO #l
        FROM
        (
            SELECT ROW_NUMBER() OVER (PARTITION BY a.ProcessGUID ORDER BY a.HandleDatetime DESC) row,
                a.*
            FROM dbo.myWorkflowNodeEntity a WITH(NOLOCK)
                LEFT JOIN myWorkflowStepPathEntity b WITH(NOLOCK) ON b.StepGUID = a.StepGUID
                LEFT JOIN myWorkflowProcessEntity w WITH(NOLOCK) ON a.ProcessGUID = w.ProcessGUID
                LEFT JOIN dbo.companyjoin cj WITH(NOLOCK) ON w.BUGUID = cj.buguid
            WHERE b.StepName <> '归档'
                AND b.StepName <> '系统归档'
                AND b.StepName <> '自动归档'
        ) a
        WHERE a.row = 1;  -- 只保留最后一条记录


        -- 获取员工客户的交易GUID
        SELECT TradeGUID
        INTO #tradeguid
        FROM s_trade2cst WITH(NOLOCK)
        WHERE CstGUID IN (
                            SELECT DISTINCT
                                    CstGUID
                            FROM dbo.p_Customer p WITH(NOLOCK)
                                INNER JOIN s_yuangong0928 b WITH(NOLOCK) ON p.cstname = b.姓名
                                                                AND p.cardid = b.身份证
                        );

        -- 获取合同数据
        SELECT c.*
        INTO #es_Contract
        FROM s_contract c WITH(NOLOCK)
            LEFT JOIN mybusinessunit bu WITH(NOLOCK) ON c.buguid = bu.buguid
        WHERE  1=1 
            --    bu.buguid in (SELECT buguid FROM mybusinessunit a
            --                     left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
            --                     where b.DevelopmentCompanyGUID in (@buname));


        -- 获取订单数据
        SELECT c.*
        INTO #es_order
        FROM s_order c WITH(NOLOCK)
            LEFT JOIN mybusinessunit bu WITH(NOLOCK) ON c.buguid = bu.buguid
        WHERE 1=1
            --  bu.buguid in (SELECT buguid FROM mybusinessunit a
            --                     left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
            --                     where b.DevelopmentCompanyGUID in (@buname));


        -- 获取最新激活交易信息
        SELECT a.RoomGUID,isnull(b.JyTotal,a.JyTotal) JyTotal,b.QSDate
        INTO #lastTrade
        FROM s_order a WITH(NOLOCK)
            LEFT JOIN s_contract b WITH(NOLOCK) on a.TradeGUID = b.TradeGUID and a.CloseReason = '转签约' and b.status = '激活'
            LEFT JOIN mybusinessunit bu WITH(NOLOCK) ON a.buguid = bu.buguid
        WHERE (a.status = '激活' or (a.CloseReason = '转签约' and b.status = '激活'))
        -- and bu.buguid in (SELECT buguid FROM mybusinessunit a
        --                         left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
        --                         where b.DevelopmentCompanyGUID in (@buname));


        -- 获取合同相关的交款人信息
        SELECT DISTINCT
            tradeguid,
            contractguid,
            Jkr
        INTO #s_voucher
        FROM s_Voucher v WITH(NOLOCK)
            INNER JOIN #es_Contract c ON v.SaleGUID = c.tradeguid;


        -- 合并同一合同的多个交款人信息
        SELECT t1.contractguid,
            jkr = STUFF(
                    (
                        SELECT ',' + Jkr
                        FROM #s_voucher t
                        WHERE contractguid = t1.contractguid
                        FOR XML PATH('')
                    ),
                    1,
                    1,
                    ''
                        )
        INTO #jkr
        FROM #es_Contract t1
        GROUP BY t1.contractguid;

        -- 获取订单相关的交款人信息
        SELECT DISTINCT
            tradeguid,
            orderguid,
            Jkr
        INTO #s_voucher_o
        FROM s_Voucher v WITH(NOLOCK)
            INNER JOIN #es_order c ON v.SaleGUID = c.tradeguid;


        -- 合并同一订单的多个交款人信息
        SELECT t1.orderguid,
            jkr = STUFF(
                    (
                        SELECT ',' + Jkr
                        FROM #s_voucher_o t
                        WHERE orderguid = t1.orderguid
                        FOR XML PATH('')
                    ),
                    1,
                    1,
                    ''
                        )
        INTO #jkr_o
        FROM #es_order t1
        GROUP BY t1.orderguid;

        TRUNCATE table XS13退房清单流程_qx;

        insert into  XS13退房清单流程_qx
        -- 查询签约退房数据
        SELECT bu.BUGUID,
            bu.BUName 公司名称,
            ISNULL(p1.ProjName, p.ProjName) 项目名称,
            ISNULL(p1.SpreadName, p.SpreadName) 推广名称,
            r.RoomGUID,
            r.ProductType 产品,
            r.RoomInfo 房间,
            '签约退房' as '退房类型',
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
                WHEN CstName2.CardID IS NULL THEN
                        CstName1.CardID
                WHEN CstName3.CardID IS NULL THEN
                        CstName1.CardID + ';' + CstName2.CardID
                WHEN CstName4.CardID IS NULL THEN
                        CstName1.CardID + ';' + CstName2.CardID + ';' + CstName3.CardID
                ELSE CstName1.CardID + ';' + CstName2.CardID + ';' + CstName3.CardID + ';' + CstName4.CardID
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
            c.HtType AS '合同类型',
            o.QSDate 认购时间,
            c.QSDate 签约时间,
            c.Total 成交时房间总价,
            c.ZxTotalZq 成交时房间装修款,
            c.ZxTotal 成交后装修款金额,
            c.RoomTotal 成交后房间金额,
            c.JyTotal 成交金额,
            jk.jkr 交款人,
            c.CloseDate 退房时间,
            c.CloseReason 关闭原因,
            syq.Pay 已交金额,
            syq.HandCharge 手续费,
            syq.Refundment 退款金额,
            /*CASE
                WHEN tr.tradeguid IS NOT NULL THEN
                        '是'
                ELSE '否'
            END 是否员工,*/
            syq.ApplyType 申请类型,
            syq.ReasonSort 原因分类,
            syq.Reason 原因,
            syq.ApplyBy 发起人,
            syq.ApplyDate 发起时间,
            syq.ApplyBy 申请人,
            syq.ApplyDate 申请时间,
            syq.ApproveBy 审批人,
            l.AuditorName 最后审批人,
            syq.ApproveDate 审批时间,
            w.ProcessName 流程名称,
            sf.是否过总经理,
            sf.是否过董事长,
            lt.JyTotal 最新激活交易成交金额,
            lt.QSDate 最新激活交易签署日期
        -- into XS13退房清单流程_qx
        FROM s_Contract c WITH(NOLOCK)
            LEFT JOIN #jkr jk ON c.contractguid = jk.contractguid
            LEFT JOIN #tradeguid tr ON c.tradeguid = tr.tradeguid
            LEFT JOIN s_SaleModiApply syq WITH(NOLOCK) ON c.ContractGUID = syq.SaleGUID
                                            AND syq.ApplyType = '退房'
            LEFT JOIN dbo.myWorkflowProcessEntity w WITH(NOLOCK) ON syq.SaleModiApplyGUID = w.BusinessGUID
                                                        AND w.ProcessStatus IN ( '0', '1', '2' )
            LEFT JOIN #l l ON l.ProcessGUID = w.ProcessGUID
            LEFT JOIN #sf sf ON syq.SaleModiApplyGUID = sf.SaleModiApplyGUID
            LEFT JOIN myBusinessUnit bu WITH(NOLOCK) ON c.BUGUID = bu.BUGUID
            INNER JOIN ep_room r WITH(NOLOCK) ON c.RoomGUID = r.RoomGUID
            LEFT JOIN p_Project p WITH(NOLOCK) ON c.ProjGUID = p.ProjGUID
            LEFT JOIN p_Project p1 WITH(NOLOCK) ON p.ParentCode = p1.ProjCode
                                    AND p1.ApplySys LIKE '%0101%'
            LEFT JOIN s_Order o WITH(NOLOCK) ON c.TradeGUID = o.TradeGUID
                                    AND o.CloseReason = '转签约'
            LEFT JOIN s_trade2cst Cst1 WITH(NOLOCK) ON c.TradeGUID = Cst1.TradeGUID
                                        AND Cst1.CstNum = 1
            LEFT JOIN p_Customer CstName1 WITH(NOLOCK) ON Cst1.CstGUID = CstName1.CstGUID
            LEFT JOIN s_trade2cst Cst2 WITH(NOLOCK) ON c.TradeGUID = Cst2.TradeGUID
                                        AND Cst2.CstNum = 2
            LEFT JOIN p_Customer CstName2 WITH(NOLOCK) ON Cst2.CstGUID = CstName2.CstGUID
            LEFT JOIN s_trade2cst Cst3 WITH(NOLOCK) ON c.TradeGUID = Cst3.TradeGUID
                                        AND Cst3.CstNum = 3
            LEFT JOIN p_Customer CstName3 WITH(NOLOCK) ON Cst3.CstGUID = CstName3.CstGUID
            LEFT JOIN s_trade2cst Cst4 WITH(NOLOCK) ON c.TradeGUID = Cst4.TradeGUID
                                        AND Cst4.CstNum = 4
            LEFT JOIN p_Customer CstName4 WITH(NOLOCK) ON Cst4.CstGUID = CstName4.CstGUID
            LEFT JOIN #lastTrade lt on lt.RoomGUID = c.RoomGUID
        WHERE c.CloseReason = '退房'
            -- AND c.QSDate >= @var_bdate and c.qsdate <= @var_edate
            -- AND bu.buguid in (SELECT buguid FROM mybusinessunit a
            --                     left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
            --                     where b.DevelopmentCompanyGUID in (@buname))
        union ALL

        -- 查询认购退房数据
        SELECT bu.BUGUID,
            bu.BUName 公司名称,
            ISNULL(p1.ProjName, p.ProjName) 项目名称,
            ISNULL(p1.SpreadName, p.SpreadName) 推广名称,
            r.RoomGUID,
            r.ProductType 产品,
            r.RoomInfo 房间,
            '认购退房' as '退房类型',
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
                WHEN CstName2.CardID IS NULL THEN
                        CstName1.CardID
                WHEN CstName3.CardID IS NULL THEN
                        CstName1.CardID + ';' + CstName2.CardID
                WHEN CstName4.CardID IS NULL THEN
                        CstName1.CardID + ';' + CstName2.CardID + ';' + CstName3.CardID
                ELSE CstName1.CardID + ';' + CstName2.CardID + ';' + CstName3.CardID + ';' + CstName4.CardID
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
            '认购' 交易状态,
            c.QSDate 认购时间,
            ' ' 签约时间,
            c.Total 成交时房间总价,
            c.ZxTotalZq 成交时房间装修款,
            c.ZxTotal 成交后装修款金额,
            c.RoomTotal 成交后房间金额,
            c.JyTotal 成交金额,
            jk.jkr 交款人,
            c.CloseDate 退房时间,
            c.CloseReason 关闭原因,
            syq.Pay 已交金额,
            syq.HandCharge 手续费,
            syq.Refundment 退款金额,
            /*CASE
                WHEN tr.tradeguid IS NOT NULL THEN
                        '是'
                ELSE '否'
            END 是否员工,*/
            syq.ApplyType 申请类型,
            syq.ReasonSort 原因分类,
            syq.Reason 原因,
            syq.ApplyBy 发起人,
            syq.ApplyDate 发起时间,
            syq.ApplyBy 申请人,
            syq.ApplyDate 申请时间,
            syq.ApproveBy 审批人,
            l.AuditorName 最后审批人,
            syq.ApproveDate 审批时间,
            w.ProcessName 流程名称,
            sf.是否过总经理,
            sf.是否过董事长,
            lt.JyTotal 最新激活交易成交金额,
            lt.QSDate 最新激活交易的成交日期
        FROM s_order c WITH(NOLOCK)
            LEFT JOIN #jkr_o jk ON c.orderguid = jk.orderguid
            LEFT JOIN #tradeguid tr ON c.tradeguid = tr.tradeguid
            LEFT JOIN s_SaleModiApply syq WITH(NOLOCK) ON c.orderguid = syq.SaleGUID
                                            AND syq.ApplyType = '退房'
            LEFT JOIN dbo.myWorkflowProcessEntity w WITH(NOLOCK) ON syq.SaleModiApplyGUID = w.BusinessGUID
                                                        AND w.ProcessStatus IN ( '0', '1', '2' )
            LEFT JOIN #l l ON l.ProcessGUID = w.ProcessGUID
            LEFT JOIN #sf sf ON syq.SaleModiApplyGUID = sf.SaleModiApplyGUID
            LEFT JOIN myBusinessUnit bu WITH(NOLOCK) ON c.BUGUID = bu.BUGUID
            INNER JOIN ep_room r WITH(NOLOCK) ON c.RoomGUID = r.RoomGUID
            LEFT JOIN p_Project p WITH(NOLOCK) ON c.ProjGUID = p.ProjGUID
            LEFT JOIN p_Project p1 WITH(NOLOCK) ON p.ParentCode = p1.ProjCode
                                    AND p1.ApplySys LIKE '%0101%'
            /*LEFT JOIN s_Order o ON c.TradeGUID = o.TradeGUID
                                    AND o.CloseReason = '转签约'*/
            LEFT JOIN s_trade2cst Cst1 WITH(NOLOCK) ON c.TradeGUID = Cst1.TradeGUID
                                        AND Cst1.CstNum = 1
            LEFT JOIN p_Customer CstName1 WITH(NOLOCK) ON Cst1.CstGUID = CstName1.CstGUID
            LEFT JOIN s_trade2cst Cst2 WITH(NOLOCK) ON c.TradeGUID = Cst2.TradeGUID
                                        AND Cst2.CstNum = 2
            LEFT JOIN p_Customer CstName2 WITH(NOLOCK) ON Cst2.CstGUID = CstName2.CstGUID
            LEFT JOIN s_trade2cst Cst3 WITH(NOLOCK) ON c.TradeGUID = Cst3.TradeGUID
                                        AND Cst3.CstNum = 3
            LEFT JOIN p_Customer CstName3 WITH(NOLOCK) ON Cst3.CstGUID = CstName3.CstGUID
            LEFT JOIN s_trade2cst Cst4 WITH(NOLOCK) ON c.TradeGUID = Cst4.TradeGUID
                                        AND Cst4.CstNum = 4
            LEFT JOIN p_Customer CstName4 WITH(NOLOCK) ON Cst4.CstGUID = CstName4.CstGUID
            LEFT JOIN #lastTrade lt on lt.RoomGUID = c.RoomGUID
        WHERE c.CloseReason = '退房'
            -- AND c.QSDate >= @var_bdate and c.qsdate <= @var_edate
            -- AND bu.buguid in (SELECT buguid FROM mybusinessunit a
            --                     left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
            --                     where b.DevelopmentCompanyGUID in (@buname));
        -- AND c.buguid = 'B2770421-F2D0-421C-B210-E6C7EF71B270';


        -- 清理临时表
        DROP TABLE #sf,
                #myWorkflowProcessEntity,
                #l,
                #tradeguid,
                #es_Contract,
                #jkr,
                #s_voucher,
                #s_voucher_o,
                #jkr_o,
                #es_order,
                #lastTrade
                ;
end  