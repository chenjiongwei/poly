-- 查询合同结算数据并存入临时表
SELECT 
    bu.BUName,                                -- 业务单元名称
    a.htbalanceguid,                          -- 合同结算GUID
    a.contractguid,                           -- 合同GUID
    c.contractname,                           -- 合同名称
    c.contractcode,                           -- 合同编号
    a.balancetype,                            -- 结算类型
    a.balancedate,                            -- 结算日期
	a.BalanceAmount,                          -- 合同结算金额
    a.EsAmountBz,                             -- 二审金额
    wf.processguid,                           -- 流程GUID
    -- wf.ProcessNo,                          -- 流程编号（已注释）
    wf.processname,                           -- 流程名称
    CONVERT(XML, wf.bt_domainxml) AS data     -- 流程表单数据（XML格式）
INTO #tj
FROM 
    cb_HTBalance a
INNER JOIN 
    cb_contract c ON c.contractguid = a.contractguid
INNER JOIN 
    myBusinessUnit bu ON c.BUGUID = bu.BUGUID
INNER JOIN  myWorkflowProcessEntity wf ON wf.BusinessGUID = a.HTBalanceGUID
WHERE 
    a.balancetype IN ('结算', '准结算', '分批次结算')    -- 筛选特定结算类型
    -- AND bu.buname = '福建公司'                         -- 筛选福建公司
    AND wf.ProcessStatus IN (0, 1, 2)                 -- 筛选特定流程状态
    AND IsHistory = 0
    
-- 合同结算调整流程
-- 取最新一条数据
select  * 
   into #tjtz
from  (
SELECT 
    ROW_NUMBER() OVER(PARTITION BY b.HTBalanceGUID ORDER BY b.CreaterDate DESC) as rownum,
    b.HTBalanceGUID,
    a.ProcessGUID as HTBalanceWFGUID,  --合同结算调整工作流ID 
    b.CreaterDate,
    a.ProcessName as HTBalanceWFName, -- 合同结算调整流程名称
    CONVERT(XML, a.bt_domainxml) AS data

FROM myWorkflowProcessEntity a 
INNER JOIN cb_HTBalance2AmountAdjustSp b ON a.BusinessGUID = b.SpGUID 
WHERE a.BusinessType = '修改结算金额审批' AND a.ProcessStatus != '-4' 
and a.IsHistory = 0
) t where rownum = 1

-- 从XML数据中提取二审金额（含税）属性值
SELECT 
    s.*,
    m.c.value('@name', 'varchar(max)') AS 属性,
    m.c.value('.', 'nvarchar(max)') AS Value
INTO #value
FROM   
    #tj AS s
    OUTER APPLY s.data.nodes('BusinessType/Item/Domain') AS m(c)
WHERE  
    m.c.value('@name', 'varchar(max)') IN ('二审金额（含税）');


-- 从XML数据中提取调整后结算金额（含税）
SELECT 
    s.*,
    m.c.value('@name', 'varchar(max)') AS 属性,
    m.c.value('.', 'nvarchar(max)') AS Value
INTO #valuetz
FROM   
    #tjtz AS s
    OUTER APPLY s.data.nodes('BusinessType/Item/Domain') AS m(c)
WHERE  
    m.c.value('@name', 'varchar(max)') IN ('新结算金额（含税）');


/*审批表单的二审金额和结算单据内的二审金额不一致，再看结算调整流程，如有，
那结算调整的流程金额和单据内金额一致就没问题，不一致就有问题，如果没有结算调整，那也有问题*/

-- 查询二审金额不一致的记录
SELECT * 
--    case  when  ISNULL([表单_二审金额（含税）], 0) = ISNULL(二审结算金额, 0) then '是' else  '否' end 表单二审金额同结算单据二审金额是否一致,
--    case  when  [表单_调整后结算金额（含税）] is not null  and  isnull([表单_调整后结算金额（含税）],0) = isnull(结算金额,0)  then '是'
--          when   [表单_调整后结算金额（含税）] is not null  and  isnull([表单_调整后结算金额（含税）],0) <> isnull(结算金额,0)  then  '否' 
--         else  '无调整' end 表单调整后结算金额同结算单据结算金额是否一致
FROM (
    SELECT 
        a.BUName AS 公司名称,  
        a.htbalanceguid AS 合同结算guid,
        a.contractguid AS 合同guid,
        a.contractname AS 合同名称,
        a.contractcode AS 合同编号,
        a.balancetype AS 结算类型,
        a.balancedate AS 结算日期, 
		a.BalanceAmount as 结算金额,
        a.EsAmountBz AS 二审结算金额,
        a.processguid AS 合同结算流程guid,
        a.processname AS 合同结算流程名称,
        MAX(CASE a.属性 WHEN '二审金额（含税）' THEN a.Value END) AS [表单_二审金额（含税）],
        b.HTBalanceWFGUID AS 合同结算调整流程guid,
        b.HTBalanceWFName AS 合同结算调整流程名称,
        MAX(CASE b.属性 WHEN '新结算金额（含税）' THEN b.Value END) AS [表单_调整后结算金额（含税）]
    FROM  #value a
    LEFT JOIN #valuetz b ON a.htbalanceguid = b.HTBalanceGUID
    GROUP BY 
        a.BUName,  
        a.htbalanceguid,
        a.contractguid,
        a.contractname,
        a.contractcode,
        a.balancetype,
        a.balancedate, 
		a.BalanceAmount,
        a.EsAmountBz,
        a.processguid,
        a.processname,
		b.HTBalanceWFGUID ,
		b.HTBalanceWFName
    -- ORDER BY processguid  -- 排序（已注释）
) t
left  join (
    select ContractGUID,sum(PayAmount) as 合同实付金额
    from  cb_Pay
    group by  ContractGUID 
) pay on t.合同guid = pay.ContractGUID
-- WHERE  ISNULL([表单_二审金额（含税）], 0) <> ISNULL(二审结算金额, 0);  -- 筛选二审金额不一致的记录


-- 删除临时表
DROP TABLE #tj;
DROP TABLE #tjtz;
DROP TABLE #value;
DROP TABLE #valuetz;


