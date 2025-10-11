USE mycost_erp352
GO

CREATE OR ALTER PROC usp_dss_ZC03明源招标基本信息表_qx
AS 
BEGIN 
   declare @var_bgDate DATETIME = DATEADD(yy, DATEDIFF(yy,0,getdate()), 0)  --  本年的第一天
   declare @var_endDate DATETIME = getdate()
     
    -- 缓存采购方案信息
    SELECT 
        e.cgplanadjustguid,        -- 采购计划调整GUID
        e.CgSolutionGUID,          -- 采购方案GUID
        e.SolutionName,            -- 方案名称
        e.SJWCSendBidDate,         -- 实际完成发标日期
        e.SJWCSolutionShowDate,    -- 实际完成方案展示日期
        e.SJWCReturnBidDate,       -- 实际完成回标日期
        e.ManagerName,             -- 经办人姓名
        e.ProjNameList,            -- 项目名称列表
        x.事业部,                  -- 所属事业部
        e.PlanSortName,            -- 计划分类名称
        e.CreatedBy,               -- 创建人
        e.BUGUID,                  -- 业务单元GUID
        e.CgFormGUID,              -- 采购形式GUID
        n.定标开始时间,            -- 定标节点开始时间
        n.定标完成时间,            -- 定标节点完成时间
        n.供方选择开始时间,        -- 供方选择节点开始时间
        n.供方选择完成时间         -- 供方选择节点完成时间
    INTO #solution
    FROM cg_cgsolution e WITH(NOLOCK)
    LEFT JOIN (
        -- 获取项目所属事业部信息
        SELECT 
            f.CgPlanAdjustGUID,
            ROW_NUMBER() OVER(PARTITION BY f.CgPlanAdjustGUID ORDER BY f.projguid) num,
            t.事业部
        FROM cg_CgSolutionSectionForPlan f WITH(NOLOCK)
        INNER JOIN erp25.dbo.mdm_project p WITH(NOLOCK) ON f.ProjGUID = p.ProjGUID
        INNER JOIN erp25.dbo.vmdm_projectFlag t WITH(NOLOCK) ON t.ProjGUID = p.ParentProjGUID
    ) x ON x.CgPlanAdjustGUID = e.CgPlanAdjustGUID AND x.num = 1
    LEFT JOIN (
        -- 获取采购计划节点时间信息
        SELECT 
            t.CgPlanAdjustGUID,
            MAX(CASE WHEN g.CgPlanNodeName = '供方选择' THEN t.PlanBeginDate END) 供方选择开始时间,
            MAX(CASE WHEN g.CgPlanNodeName = '供方选择' THEN t.RealEndDate END) 供方选择完成时间,
            MAX(CASE WHEN g.CgPlanNodeName = '定标' THEN t.PlanBeginDate END) 定标开始时间,
            MAX(CASE WHEN g.CgPlanNodeName = '定标' THEN t.RealEndDate END) 定标完成时间
        FROM dbo.Cg_CgPlanNodeTime t WITH(NOLOCK)
        INNER JOIN Cg_CgPlanNodeSetting g WITH(NOLOCK) ON t.CgPlanNodeSettingGUID = g.CgPlanNodeSettingGUID
        GROUP BY t.CgPlanAdjustGUID
    ) n ON n.CgPlanAdjustGUID = e.CgPlanAdjustGUID
    WHERE 1=1
    -- 以下为参数化查询条件，根据需要可以取消注释
    -- AND e.BUGUID IN (SELECT buguid FROM mybusinessunit a WITH(NOLOCK)
    --                  LEFT JOIN erp25.dbo.p_DevelopmentCompany b WITH(NOLOCK) ON a.BUName = b.DevelopmentCompanyName 
    --                  WHERE b.DevelopmentCompanyGUID IN (@var_buguid))
    -- AND e.PlanSortName IN (SELECT value FROM fn_split2(@var_caigoulb,','))
    AND (CASE
         WHEN e.CreatedBy = '系统管理员' THEN n.供方选择完成时间 
         ELSE e.SJWCSolutionShowDate END BETWEEN @var_bgDate AND @var_endDate)

    -- 缓存流程信息
    -- 获取定标和合同流程信息
    -- 创建索引以提高临时表查询性能
    CREATE INDEX IX_solution_CgSolutionGUID ON #solution(CgSolutionGUID);
    
    -- 分别获取定标和合同流程信息，避免使用UNION ALL
    -- 定标流程信息
    SELECT 
        s.CgSolutionGUID,
        '定标' AS type,
        w.InitiateDatetime AS 发起时间,
        CONVERT(XML, w.BT_DomainXML) AS data
    INTO #tj_dingbiao
    FROM dbo.cg_CgProcWinBid a WITH(NOLOCK)
    INNER JOIN #solution s ON a.CgSolutionGUID = s.CgSolutionGUID
    INNER JOIN myWorkflowProcessEntity w WITH(NOLOCK) ON w.BusinessGUID = a.CgProcWinBidGUID 
    WHERE w.ProcessStatus NOT IN (-1,-2,-4);
    
    -- 合同流程信息
    SELECT 
        s.CgSolutionGUID,
        '合同' AS type,
        w.InitiateDatetime AS 发起时间,
        CONVERT(XML, w.BT_DomainXML) AS data
    INTO #tj_hetong
    FROM cb_Contract a WITH(NOLOCK)
    INNER JOIN cg_Contract2CgProc p WITH(NOLOCK) ON a.Contract2CgProcGUID = p.Contract2CgProcGUID
    INNER JOIN #solution s ON p.CgSolutionGUID = s.CgSolutionGUID
    INNER JOIN myWorkflowProcessEntity w WITH(NOLOCK) ON w.BusinessGUID = a.ContractGUID 
    WHERE w.ProcessStatus NOT IN (-1,-2,-4);
    
    -- 合并两个临时表的结果
    SELECT * INTO #tj 
    FROM #tj_dingbiao
    UNION ALL
    SELECT * FROM #tj_hetong;
    
    -- 清理中间临时表
    DROP TABLE #tj_dingbiao;
    DROP TABLE #tj_hetong;

    -- 解析XML数据，提取关键属性值
    SELECT 
        s.CgSolutionGUID,
        s.type,
        s.发起时间,
        m.c.value('@name', 'varchar(max)') AS 属性,
        m.c.value('.', 'nvarchar(max)') AS Value
    INTO #value
    FROM #tj AS s
    OUTER APPLY s.data.nodes('BusinessType/Item/Domain') AS m(c)
    WHERE m.c.value('@name', 'varchar(max)') IN ('供方分配流水号', '图纸签发编号')

    -- 汇总定标和合同流程信息
    SELECT 
        a.CgSolutionGUID,
        MAX(CASE WHEN a.type='定标' THEN a.发起时间 END) AS 定标发起时间,
        MAX(CASE WHEN a.type='定标' AND 属性 = '供方分配流水号' THEN a.Value END) AS 定标供方分配流水号,
        MAX(CASE WHEN a.type='定标' AND 属性 = '图纸签发编号' THEN a.Value END) AS 定标图纸签发编号,
        MAX(CASE WHEN a.type='合同' THEN a.发起时间 END) AS 合同发起时间,
        MAX(CASE WHEN a.type='合同' AND 属性 = '供方分配流水号' THEN a.Value END) AS 合同供方分配流水号,
        MAX(CASE WHEN a.type='合同' AND 属性 = '图纸签发编号' THEN a.Value END) AS 合同图纸签发编号
    INTO #re
    FROM #value a
    GROUP BY a.CgSolutionGUID

    -- 注释掉的中标价格临时表代码
    --SELECT e.CgSolutionGUID,
    --        CASE
    --           WHEN e.CgSolutionGUID IS NULL THEN ROUND(a.HtAmount, 2) 
    --           ELSE ROUND(k.WinBidPrice, 2) 
    --        END AS '中标价格'
    --INTO #zbjg
    --FROM #solution e
    --LEFT JOIN cg_Contract2CgProc d WITH(NOLOCK) ON d.CgSolutionGUID = e.CgSolutionGUID
    --LEFT JOIN cb_Contract a WITH(NOLOCK) ON a.Contract2CgProcGUID = d.Contract2CgProcGUID
    --LEFT JOIN Cg_CgProcReturnBid k WITH(NOLOCK) ON k.CgSolutionGUID = e.CgSolutionGUID
    --                                       AND WinBidResult = '已中标'
    --SELECT * FROM #zbjg WHERE 中标价格>=4000000      

    TRUNCATE TABLE ZC03明源招标基本信息表_qx;

    insert into ZC03明源招标基本信息表_qx
    -- 主查询：获取明源招标基本信息
    SELECT DISTINCT
        w.BUName AS '平台公司名称',                -- 平台公司名称
        e.ProjNameList AS '项目名称',              -- 项目名称
        e.事业部,                                  -- 所属事业部
        e.SolutionName AS '采购方案名称',          -- 采购方案名称
        e.PlanSortName AS 采购类别,                -- 采购类别
        f.CgFormName AS '采购方式',                -- 采购方式
        CASE WHEN e.CreatedBy = '系统管理员' THEN '是' ELSE '否' END AS 是否来自筑龙,  -- 判断是否来自筑龙系统
        CASE
            WHEN e.CreatedBy = '系统管理员' THEN e.供方选择完成时间 
            ELSE CONVERT(VARCHAR(12), e.SJWCSolutionShowDate, 111) 
        END AS '供方入围完成审批时间',              -- 供方入围完成审批时间
        CONVERT(VARCHAR(12), g.ApproveDate, 111) AS '招标文件完成审批时间',  -- 招标文件完成审批时间
        CONVERT(VARCHAR(12), e.SJWCSendBidDate, 111) AS '发标时间',         -- 发标时间
        CONVERT(VARCHAR(12), e.SJWCReturnBidDate, 111) AS '开回标时间',     -- 开回标时间
        CASE
            WHEN e.CreatedBy = '系统管理员' THEN e.定标完成时间 
            ELSE CONVERT(VARCHAR(12), h.AuditDate, 111) 
        END AS '定标呈批完成时间',                  -- 定标呈批完成时间
        CONVERT(VARCHAR(12), a.SignDate, 111) AS '合同呈批完成时间',        -- 合同呈批完成时间
        CASE
            WHEN e.CgSolutionGUID IS NULL THEN ROUND(a.HtAmount, 2) 
            ELSE ROUND(k.WinBidPrice, 2) 
        END AS '中标价格',                         -- 中标价格
        CASE
            WHEN a.JsState = '结算' OR a.JsState = '结算中' THEN a.JsState 
            ELSE
                CASE WHEN a.ApproveState = '已审核' THEN '已签约' ELSE a.ApproveState END 
        END AS '合同状态',                         -- 合同状态
        c.HtTypeName AS '合同类别',                -- 合同类别
        a.ContractCode AS '合同编号',              -- 合同编号
        a.ContractName AS '合同名称',              -- 合同名称
        ROUND(a.TotalAmount, 2) AS '合同含税金额',  -- 合同含税金额
        ROUND(a.HtAmount_Bz, 2) AS '有效签约含税金额',  -- 有效签约含税金额
        ROUND(a.ExcludingTaxHtAmount_Bz, 2) AS '有效签约不含税金额',  -- 有效签约不含税金额
        a.JfProviderName AS '甲方单位',            -- 甲方单位
        a.YfProviderName AS '签约单位',            -- 签约单位
        e.ManagerName AS '招标经办人',              -- 招标经办人
        r.定标发起时间,                            -- 定标发起时间
        r.定标供方分配流水号,                      -- 定标供方分配流水号
        r.定标图纸签发编号,                        -- 定标图纸签发编号
        r.合同发起时间,                            -- 合同发起时间
        r.合同供方分配流水号,                      -- 合同供方分配流水号
        r.合同图纸签发编号,                        -- 合同图纸签发编号
        -- 使用STUFF函数合并入围供方名称
        STUFF(
            (
                SELECT ';' + p2.providername
                FROM cg_cgsolutionProvider so WITH(NOLOCK)
                LEFT JOIN p_provider p2 WITH(NOLOCK) ON p2.providerGUID = so.providerGUID
                WHERE so.FinalistState='已入围' AND so.CgSolutionGUID = e.CgSolutionGUID
                FOR XML PATH('')
            ),
            1,
            1,
            ''
        ) AS 入围供方,                             -- 入围供方列表
        p1.providername AS 中标供方                 -- 中标供方
    -- into ZC03明源招标基本信息表_qx
    FROM #solution e
    LEFT JOIN cg_Contract2CgProc d WITH(NOLOCK) ON d.CgSolutionGUID = e.CgSolutionGUID
    LEFT JOIN (
        -- 获取每个采购方案最新的合同关联记录
        SELECT 
            CgSolutionGUID,
            MAX(CreateOn) AS createon
        FROM cg_Contract2CgProc WITH(NOLOCK)
        GROUP BY CgSolutionGUID
    ) z ON d.CgSolutionGUID = z.CgSolutionGUID
    LEFT JOIN cb_Contract a WITH(NOLOCK) ON a.Contract2CgProcGUID = d.Contract2CgProcGUID
    LEFT JOIN MyArea2Company b WITH(NOLOCK) ON a.BUGUID = b.BUGUID
    LEFT JOIN MyArea2Company i WITH(NOLOCK) ON i.BUCode = b.ParentCode
    LEFT JOIN cb_HtType c WITH(NOLOCK) ON a.HtTypeCode = c.HtTypeCode AND a.BUGUID = c.BUGUID
    LEFT JOIN dbo.ek_Company w WITH(NOLOCK) ON e.BUGUID = w.BUGUID
    LEFT JOIN cg_p_CgForm f WITH(NOLOCK) ON f.CgFormGUID = e.CgFormGUID
    LEFT JOIN Cg_CgProcBidDocument g WITH(NOLOCK) ON g.CgSolutionGUID = e.CgSolutionGUID
    LEFT JOIN cg_CgProcWinBid h WITH(NOLOCK) ON h.CgSolutionGUID = e.CgSolutionGUID
    LEFT JOIN Cg_CgProcReturnBid k WITH(NOLOCK) ON k.CgSolutionGUID = e.CgSolutionGUID AND WinBidResult = '已中标'
    LEFT JOIN P_provider p1 WITH(NOLOCK) ON p1.providerGUID = k.providerGUID
    LEFT JOIN cb_Contract_Pre l WITH(NOLOCK) ON l.PreContractGUID = a.PreContractGUID
    LEFT JOIN #re r ON r.CgSolutionGUID = e.CgSolutionGUID
    WHERE 1 = 1
    -- 以下为参数化查询条件，根据需要可以取消注释
    -- AND CASE
    --     WHEN e.CgSolutionGUID IS NULL THEN ROUND(a.HtAmount, 2) 
    --     ELSE ROUND(k.WinBidPrice, 2) 
    --     END >= 4000000
    AND (
        (
            d.IsStrategyMode = 0  -- 只取非集采
            AND EXISTS (
                SELECT 1
                FROM cb_Contract cb WITH(NOLOCK)
                WHERE cb.Contract2CgProcGUID = d.Contract2CgProcGUID
            )
        )
        OR d.Contract2CgProcGUID IS NULL
    ) 
    -- 过滤掉异常数据的条件，根据需要可以取消注释
    -- AND e.CreatedBy='系统管理员'
    -- AND e.IsZF !='1'
    ORDER BY 
        w.BUName,           -- 按平台公司名称排序
        e.ProjNameList,     -- 按项目名称排序
        e.SolutionName      -- 按采购方案名称排序
    
    -- 清理临时表
    DROP TABLE #tj, #value, #solution, #re
END 