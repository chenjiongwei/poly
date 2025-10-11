USE [ERP25]
GO

-- 创建或修改存储过程：延期签约流程数据清洗
CREATE OR ALTER PROC usp_dss_XS15延期签约流程_qx
AS 
BEGIN 
        -- 缓存项目信息
        -- 获取三级项目信息及其对应的开发公司GUID
        SELECT      
                p.buguid,                  -- 业务单元GUID
                p.ProjGUID,                -- 项目GUID
                p.ParentCode,              -- 父级项目代码
                p.ProjName,                -- 项目名称
                mp.DevelopmentCompanyGUID  -- 开发公司GUID
        INTO      #p
        FROM      p_Project p WITH(NOLOCK)
        INNER JOIN p_Project p1 WITH(NOLOCK)
            ON p.ParentCode = p1.ProjCode
            AND p1.ApplySys LIKE '%0101%'  -- 筛选应用系统类型
        INNER JOIN mdm_Project mp WITH(NOLOCK)
            ON p1.ProjGUID = ISNULL(mp.ImportSaleProjGUID, mp.ProjGUID)
        WHERE     1=1 
        -- 注释掉的参数化查询条件，可根据需要启用
        -- AND mp.DevelopmentCompanyGUID IN (SELECT Value FROM dbo.fn_Split2(@var_buguid, ','))
        AND p.Level = 3;  -- 只获取三级项目

        -- 获取延期签约的工作流程信息
        -- 筛选已完成的延期签约申请流程
        SELECT 
            m.ProcessGUID,           -- 流程GUID
            syq.SaleModiApplyGUID    -- 销售修改申请GUID
        INTO #myWorkflowProcessEntity
        FROM myWorkflowProcessEntity m WITH(NOLOCK)
            INNER JOIN s_SaleModiApply syq WITH(NOLOCK) 
                ON m.BusinessGUID = syq.SaleModiApplyGUID
                AND syq.ApplyType = '延期签约'  -- 筛选延期签约类型
        WHERE m.ProcessStatus = '2';  -- 状态为2表示已完成的流程

        -- 分析工作流程审批路径
        -- 判断流程是否经过总部、董事长、总经理审批
        SELECT DISTINCT
            m.ProcessGUID,
            m.SaleModiApplyGUID,
            MAX(CASE
                WHEN p.StepName LIKE '%总部%' OR p.StepName LIKE '%集团%' 
                THEN '是' ELSE '否' END) AS 是否过总部,
            MAX(CASE 
                WHEN p.StepName LIKE '%董事长%' 
                THEN '是' ELSE '否' END) AS 是否过董事长,
            MAX(CASE 
                WHEN p.StepName LIKE '%总经理%' 
                THEN '是' ELSE '否' END) AS 是否过总经理
        INTO #w
        FROM #myWorkflowProcessEntity m
            LEFT JOIN myWorkflowStepPathEntity p WITH(NOLOCK) 
                ON m.ProcessGUID = p.ProcessGUID
        GROUP BY 
            m.ProcessGUID,
            m.SaleModiApplyGUID;

        TRUNCATE table XS15延期签约流程_qx;

        insert into  XS15延期签约流程_qx
        -- 主查询：获取延期签约的详细信息
        SELECT 
            bu.BUGUID,
            bu.BUName AS 公司名称,
            o.RoomGUID,
            ISNULL(p1.ProjName, p.ProjName) AS 项目名称,
            ISNULL(p1.SpreadName, p.SpreadName) AS 推广名称,
            r.ProductType AS 产品,
            r.RoomInfo AS 房间,
            o.QSDate AS 认购时间,
            o.EndDate AS 约定签约时间,
            o.JfDate AS 约定交房时间,
            -- 合并多个客户名称
            CASE
                WHEN CstName2.CstName IS NULL THEN CstName1.CstName
                WHEN CstName3.CstName IS NULL THEN CstName1.CstName + ';' + CstName2.CstName
                WHEN CstName4.CstName IS NULL THEN CstName1.CstName + ';' + CstName2.CstName + ';' + CstName3.CstName 
                ELSE CstName1.CstName + ';' + CstName2.CstName + ';' + CstName3.CstName + ';' + CstName4.CstName 
            END AS '客户名称',
            -- 合并多个身份证号
            CASE
                WHEN CstName2.CardID IS NULL THEN CstName1.CardID
                WHEN CstName3.CardID IS NULL THEN CstName1.CardID + ';' + CstName2.CardID
                WHEN CstName4.CardID IS NULL THEN CstName1.CardID + ';' + CstName2.CardID + ';' + CstName3.CardID 
                ELSE CstName1.CardID + ';' + CstName2.CardID + ';' + CstName3.CardID + ';' + CstName4.CardID 
            END AS '身份证号',
            -- 合并多个联系电话
            CASE
                WHEN CstName2.MobileTel IS NULL THEN CstName1.MobileTel
                WHEN CstName3.MobileTel IS NULL THEN CstName1.MobileTel + ';' + CstName2.MobileTel
                WHEN CstName4.MobileTel IS NULL THEN CstName1.MobileTel + ';' + CstName2.MobileTel + ';' + CstName3.MobileTel 
                ELSE CstName1.MobileTel + ';' + CstName2.MobileTel + ';' + CstName3.MobileTel + ';' + CstName4.MobileTel 
            END AS '联系电话',
            o.Total AS 成交时房间总价,
            o.ZxTotalZq AS 成交时房间装修款,
            o.ZxTotal AS 成交后装修款金额,
            o.RoomTotal AS 成交后房间金额,
            o.JyTotal AS 成交金额,
            -- 注释掉的字段，可根据需要启用
            -- bz.ParamValue AS 设置的项目约定签约时长,
            DATEDIFF(dd, QSDate, o.EndDate) AS 约定签约时间与认购时间差,
            syq.ApplyBy AS 申请人,
            syq.ApplyDate AS 延期申请时间,
            syq.EndDate AS 原约定签约日期,
            syq.ApplyEndDate AS 申请约定签约日期,
            syq.ReasonSort AS 原因分类,
            syq.Reason AS 原因,
            o.Status AS 当前状态,
            o.CloseDate AS 关闭时间,
            o.CloseReason AS 关闭原因,
            DATEDIFF(dd, o.QSDate, syq.ApplyEndDate) AS 申请延期天数,
            w.是否过总经理,
            w.是否过董事长,
            -- 判断是否30-60天延期且经过总经理审批
            CASE
                WHEN DATEDIFF(dd, o.QSDate, syq.ApplyEndDate) >= 30
                    AND DATEDIFF(dd, o.QSDate, syq.ApplyEndDate) < 60
                    AND w.是否过总经理 = '是' THEN '是' 
                ELSE '否' 
            END AS '是否30_60过总经理',
            -- 判断是否60-90天延期且经过董事长审批
            CASE
                WHEN DATEDIFF(dd, o.QSDate, syq.ApplyEndDate) >= 60
                    AND DATEDIFF(dd, o.QSDate, syq.ApplyEndDate) < 90
                    AND w.是否过董事长 = '是' THEN '是' 
                ELSE '否' 
            END AS '是否60_90过董事长'
        -- INTO XS15延期签约流程_qx
        FROM s_Order o WITH(NOLOCK)
            LEFT JOIN myBusinessUnit bu WITH(NOLOCK) 
                ON o.BUGUID = bu.BUGUID
            INNER JOIN ep_room r WITH(NOLOCK) 
                ON o.RoomGUID = r.RoomGUID
            LEFT JOIN p_Project p WITH(NOLOCK) 
                ON o.ProjGUID = p.ProjGUID
            LEFT JOIN p_Project p1 WITH(NOLOCK) 
                ON p.ParentCode = p1.ProjCode
                AND p1.ApplySys LIKE '%0101%'
            -- 获取第一个客户信息
            LEFT JOIN s_trade2cst Cst1 WITH(NOLOCK) 
                ON o.TradeGUID = Cst1.TradeGUID
                AND Cst1.CstNum = 1
            LEFT JOIN p_Customer CstName1 WITH(NOLOCK) 
                ON Cst1.CstGUID = CstName1.CstGUID
            -- 获取第二个客户信息
            LEFT JOIN s_trade2cst Cst2 WITH(NOLOCK) 
                ON o.TradeGUID = Cst2.TradeGUID
                AND Cst2.CstNum = 2
            LEFT JOIN p_Customer CstName2 WITH(NOLOCK) 
                ON Cst2.CstGUID = CstName2.CstGUID
            -- 获取第三个客户信息
            LEFT JOIN s_trade2cst Cst3 WITH(NOLOCK) 
                ON o.TradeGUID = Cst3.TradeGUID
                AND Cst3.CstNum = 3
            LEFT JOIN p_Customer CstName3 WITH(NOLOCK) 
                ON Cst3.CstGUID = CstName3.CstGUID
            -- 获取第四个客户信息
            LEFT JOIN s_trade2cst Cst4 WITH(NOLOCK) 
                ON o.TradeGUID = Cst4.TradeGUID
                AND Cst4.CstNum = 4
            LEFT JOIN p_Customer CstName4 WITH(NOLOCK) 
                ON Cst4.CstGUID = CstName4.CstGUID
            -- 关联延期签约申请信息
            INNER JOIN s_SaleModiApply syq WITH(NOLOCK) 
                ON o.OrderGUID = syq.SaleGUID
                AND syq.ApplyType = '延期签约'
            -- 关联工作流程信息
            LEFT JOIN #w w 
                ON w.SaleModiApplyGUID = syq.SaleModiApplyGUID
        WHERE 1=1
            -- 注释掉的参数化查询条件，可根据需要启用
            -- AND o.qsdate BETWEEN @var_bgndate AND @var_enddate
            -- AND o.buguid IN (SELECT DISTINCT buguid FROM #p)
        ORDER BY r.RoomInfo;  -- 按房间信息排序

        -- 清理临时表
        DROP TABLE #w, #myWorkflowProcessEntity, #p;

END
