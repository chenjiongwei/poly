-- 统计400万以上招标项目明细
-- 2025-07-31 增加一列合同类别
-- 统计400万以上招标项目明细
-- 2025-07-31 增加一列合同类别
-- 2025-08-05 增加一列是否招采平台定标

SELECT DISTINCT
    bu.buname AS 平台公司,                                   -- 平台公司名称
    c.ContractCode AS 合同编号,                             -- 合同编号
    c.contractname AS 合同名称,                             -- 合同名称
    httype.HtTypeName as 合同类别, -- 合同类别
    prjNamlist.projnamelist AS 所属项目,                                -- 所属项目名称
    CONVERT(DECIMAL(18, 2), c.htamount / 10000.0) AS [合同金额(万元)], -- 合同金额（万元）
    CONVERT(VARCHAR(7), c.signdate, 121) AS [签约时间(年月)],         -- 签约时间（年月）
    CASE
        WHEN ISNULL(c.BfProviderName, '') <> '' THEN c.YfProviderName + ';' + c.BfProviderName
        ELSE c.YfProviderName
    END AS 签约供应商名称,                                   -- 签约供应商名称（含乙方、丙方）
    c.jfProviderName AS 招标主体名称,                        -- 招标主体名称
    c.ProjectNameList AS 招标项目或标段名称,                  -- 招标项目或标段名称
    NULL AS 项目组织形式,                                   -- 项目组织形式（预留，暂无数据）
    -- 委托代理机构名称（如有）此处未取，后续如需可补充
    c.[SignMode] AS 采购方式,                               -- 采购方式
    case when isnull(vc.zlbs,0) =0 then '否' else  '是' end as 是否招采平台定标,
    CONVERT(DECIMAL(18, 2), win.WinBidPrice / 10000.0) AS [定标金额(万元)], -- 定标金额（万元）
    CONVERT(VARCHAR(7), win.SJWCConfirmBidDate, 121) AS [定标时间(年月)],   -- 定标时间（年月）
    win.ProviderName AS 中标供应商名称                      -- 中标供应商名称
FROM
    cb_contract c
    inner join vcb_contract vc on vc.contractguid =c.contractguid
    inner join [dbo].[cb_HtType] httype on c.HtTypeCode =httype.HtTypeCode and  c.BUGUID =httype.BUGUID
    left join (
         SELECT 
             cp.ContractGUID,
             STUFF(
                 (
                     SELECT ',' + p2.ProjName
                     FROM cb_contractproj cp2
                     LEFT JOIN p_project p1 ON p1.ProjGUID = cp2.ProjGUID AND p1.level = 3
                     LEFT JOIN p_project p2 ON p2.projcode = p1.ParentCode
                     WHERE cp2.ContractGUID = cp.ContractGUID
                     AND p2.ProjName IS NOT NULL
                     GROUP BY p2.ProjName
                     FOR XML PATH('')
                 ),
                 1, 1, ''
             ) AS projnamelist
         FROM cb_contractproj cp
         -- WHERE cp.ContractGUID = '4F3CFB24-9196-4B8D-8E2B-623D837FFA11'
		     group by cp.ContractGUID
    ) prjNamlist  On prjNamlist.ContractGUID =c.ContractGUID
    -- left JOIN cb_contractproj cp ON c.contractguid = cp.contractguid      -- 合同与项目关联
    -- left JOIN p_project p ON p.ProjGUID = cp.ProjGUID AND p.level = 3     -- 三级项目
    -- left JOIN p_project pp ON pp.projcode = p.ParentCode                  -- 上级项目
    INNER JOIN dbo.[myBusinessUnit] bu ON bu.buguid = c.buguid             -- 平台公司
    LEFT JOIN (
        -- 中标信息子查询
        SELECT
            c2c.Contract2CgProcGUID,                  -- 合同与采购流程关联GUID
            crb.ProviderGUID,                         -- 供应商GUID
            p.providername AS ProviderName,           -- 供应商名称
            WinBidPrice,                              -- 中标金额
            slt.SJWCConfirmBidDate                    -- 定标时间
        FROM
            cg_Contract2CgProc c2c
            INNER JOIN cg_CgSolution slt ON c2c.CgSolutionGUID = slt.CgSolutionGUID
            INNER JOIN Cg_CgProcReturnBid crb ON c2c.CgSolutionGUID = crb.CgSolutionGUID and c2c.ProviderGUID =crb.ProviderGUID
            LEFT JOIN p_Provider p ON p.ProviderGUID = crb.ProviderGUID
        WHERE
            ISNULL(crb.IsZF, '否') NOT IN ('是', '1') -- 剔除作废
            AND crb.WinBid = 1  and c2c.ZbAmount =crb.WinBidPrice                   
            -- 仅取中标
    ) win ON c.Contract2CgProcGUID = win.Contract2CgProcGUID
WHERE
    c.[ApproveState] = '已审核'         -- 合同已审核
   -- AND c.BfProviderName IS NOT NULL   -- 丙方供应商不为空
    -- AND IfDdhs <> 0                    -- 是否多合同（非0）
    -- AND c.htamount >= 4000000.0         -- 合同金额大于400万
    AND YEAR(c.signdate) >= 2013       -- 2013年及以后
    -- AND c.contractcode = '武汉保利新武昌合20180151' -- 可用于调试
     -- AND c.contractcode = '武汉汉阳区P（2016）096号燎原村B包项目合20190030'
ORDER BY
    bu.buname,                         -- 平台公司
    prjNamlist.projnamelist,                       -- 所属项目
    c.[SignMode] DESC                  -- 采购方式降序
  




      