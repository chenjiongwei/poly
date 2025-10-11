USE mycost_erp352
GO

CREATE OR ALTER PROC usp_dss_CB05工程类合同付款情况明细表_qx
AS 
BEGIN      
        -- 筛选工程类合同
        SELECT ContractGUID
        INTO #con
        FROM vcb_Contract WITH(NOLOCK)
        WHERE HtTypeName LIKE '%工程%'
            -- 注释掉的参数化查询条件，可根据需要启用
            -- AND buguid IN (SELECT buguid FROM mybusinessunit a
            --                     left join erp25.dbo.p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
            --                     where b.DevelopmentCompanyGUID in (@buname))
            -- AND SignDate BETWEEN @var_bdate AND @var_edate 

        -- 获取合同付款申请信息
        SELECT 
            a.contractguid,          -- 合同GUID
            a.ApplyDate,             -- 申请日期
            a.Subject,               -- 申请主题
            a.ApplyState,            -- 申请状态
            a.PayState,              -- 付款状态
            a.ApproveDate,           -- 审批日期
            a.applyamount,           -- 申请金额
            a.HTFKApplyGUID,         -- 合同付款申请GUID
            a.ApplyCode,             -- 申请编号
            a.FundType,              -- 款项类型
            a.FundName,              -- 款项名称
            ROW_NUMBER() OVER (PARTITION BY a.contractguid ORDER BY a.ApplyDate) rownum,  -- 按合同分组的申请序号
            w.InitiateDatetime       -- 工作流发起时间
        INTO #t
        FROM cb_htfkapply a WITH(NOLOCK)
            INNER JOIN #con c ON a.ContractGUID = c.ContractGUID
            LEFT JOIN myWorkflowProcessEntity w WITH(NOLOCK) ON a.HTFKApplyGUID = w.BusinessGUID 
                                                            AND w.processstatus IN('0','1','2')  -- 0:进行中 1:已撤回 2:已完成
        WHERE a.ApplyState IN ('审批中', '已审批', '审核中', '已审核')  -- 筛选有效的申请状态
            -- 注释掉的筛选条件，可根据需要启用
            -- AND a.FundType LIKE '%工程%'

        truncate table CB05工程类合同付款情况明细表_qx

        insert into CB05工程类合同付款情况明细表_qx
        -- 主查询：获取工程类合同付款情况明细
        SELECT 
            a.ContractGUID,                      -- 合同GUID
            a.BUName AS 公司名称,                -- 公司名称
            a.ProjName AS '所属项目',            -- 所属项目
            mp1.ManageModeName AS '管理方式_一级项目',  -- 一级项目管理方式
            mp1.projstatus AS '项目状态_一级项目',      -- 一级项目状态
            mp.ProjCode AS 明源系统代码,         -- 明源系统项目代码
            lb.LbProjectValue AS 投管代码,       -- 投管代码
            a.JfProviderName AS '甲方单位',      -- 甲方单位
            a.YfProviderName AS '乙方单位',      -- 乙方单位
            a.ContractCode AS '合同编号',        -- 合同编号
            a.ContractName AS '合同名称',        -- 合同名称
            a.HtClass AS '合同分类',             -- 合同分类
            HtTypeName AS '合同类别',            -- 合同类别
            a.SignMode AS '采购方式',            -- 采购方式
            a.SignDate AS '签约日期',            -- 签约日期
            a.ApproveDate AS 审批时间,           -- 合同审批时间
            a.HtAmount AS '有效签约金额元',      -- 有效签约金额(元)
            t.Subject AS 申请主题,               -- 第一笔款申请主题
            t.ApplyDate AS 第一笔款申请时间,     -- 第一笔款申请时间
            t.InitiateDatetime AS 发起时间,      -- 第一笔款发起时间
            t.FundType AS 第一笔款款项类型,      -- 第一笔款款项类型
            t.FundName AS 第一笔款款项名称,      -- 第一笔款款项名称
            t.applyamount AS 第一笔款申请金额,   -- 第一笔款申请金额
            db.auditdate AS 定标审核时间,        -- 定标审核时间
            mydb.FinishDatetime AS 定标审批流程审批时间  -- 定标审批流程完成时间
        -- INTO CB05工程类合同付款情况明细表_qx
        FROM vcb_Contract a WITH(NOLOCK)
            -- 关联采购流程信息
            LEFT JOIN cg_Contract2CgProc cc WITH(NOLOCK) ON cc.Contract2CgProcGUID = a.Contract2CgProcGUID
            LEFT JOIN cg_CgProcWinBid db WITH(NOLOCK) ON db.CgSolutionGUID = cc.CgSolutionGUID
            -- 关联定标审批流程
            LEFT JOIN myWorkflowProcessEntity mydb WITH(NOLOCK) ON mydb.BusinessGUID = db.CgProcWinBidGUID
                                                               AND mydb.ProcessStatus = '2'  -- 已完成的流程
            -- 关联筛选的工程类合同
            INNER JOIN #con c ON a.contractguid = c.contractguid
            -- 关联第一笔付款申请
            LEFT JOIN #t t ON a.contractguid = t.contractguid
                          AND t.rownum = 1  -- 只取每个合同的第一笔付款申请
            -- 关联项目信息
            LEFT JOIN p_Project p WITH(NOLOCK) ON p.ProjCode = CASE
                                                    -- 处理项目代码格式：单个项目代码
                                                    WHEN LEN(a.ProjectCode) > 1
                                                         AND CHARINDEX(';', a.ProjectCode) < 1 THEN
                                                         a.ProjectCode
                                                    -- 处理项目代码格式：多个项目代码，以分号分隔，取第一个
                                                    WHEN LEN(a.ProjectCode) > 1
                                                         AND CHARINDEX(';', a.ProjectCode) >= 1 THEN
                                                         LEFT(a.ProjectCode, CHARINDEX(';', a.ProjectCode) - 1)
                                                    ELSE NULL
                                                END
            -- 关联MDM项目信息
            LEFT JOIN ERP25.dbo.mdm_Project mp WITH(NOLOCK) ON mp.ProjGUID = p.ProjGUID
            LEFT JOIN ERP25.dbo.mdm_Project mp1 WITH(NOLOCK) ON mp.ParentProjGUID = mp1.ProjGUID
            -- 关联投管代码
            LEFT JOIN ERP25.dbo.mdm_LbProject lb WITH(NOLOCK) ON lb.projGUID = ISNULL(mp.ParentProjGUID, mp.ProjGUID)
                                                             AND lb.LbProject = 'tgid'  -- 投管代码标识
        WHERE (1 = 1)  -- 预留条件位置，方便后续扩展
        ORDER BY 
            a.BUName,       -- 按公司名称排序
            a.ProjName,     -- 按项目名称排序
            a.ContractName, -- 按合同名称排序
            t.ApplyDate;    -- 按申请日期排序

        -- 清理临时表
        DROP TABLE #t, #con;

        -- 数据字典查询参考（已注释）
        -- SELECT * FROM dbo.data_dict WHERE table_name='cb_HTFKApply'
END 
