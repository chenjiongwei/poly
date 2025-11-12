DECLARE @MaxLevel INT
DECLARE @CurrentLevel INT

--定义临时表：存放临时计算数据
DECLARE @data TABLE
(
		CostAccountGUID UNIQUEIDENTIFIER,   --平衡表主键
		ParentGUID UNIQUEIDENTIFIER,            --父级节点GUID
		OrderHierarchyCode NVARCHAR(512),   --排序字段
		AccountCode NVARCHAR(512),      --科目代码
		NodeName NVARCHAR(512),          --科目、合约规划名称
		NodeType NVARCHAR(50),            --节点类别
		BudgetOrderName NVARCHAR(500),   --合约消费者名称
		[Level] INT ,      --层级
		A DECIMAL(18,2),    --可研版目标成本
		B DECIMAL(18,2),    --最新版目标成本（版号）
		C DECIMAL(18,2),    --合约规划金额
		D DECIMAL(18,2),    --动态成本
		E NVARCHAR(512),    --合同编号
		F NVARCHAR(512),    --合同名称
		G NVARCHAR(512),    --乙方名称
		--H DECIMAL(18,2),    --图差
		--I DECIMAL(18,2),    --价差
		J DATE,    --合同签订时间
		K DECIMAL(18,2),    --合同金额
		R DECIMAL(18,2),    --其中不计成本金额
		L DECIMAL(18,2),    --合同净值
		M DECIMAL(18,2),    --合同净值+补协金额
		N1 DECIMAL(18,2),    --合同变更金额（全变更）
		N DECIMAL(18,2),    --合同净值+补协+合同变更金额
		O1 DECIMAL(18,2),    --待发生合约规划金额
		O DECIMAL(18,2),    --规划余量
		P1 DECIMAL(18,2),    --合同申请金额
		P DECIMAL(18,2),    --已支付金额
		Q DECIMAL(18,2),    --支付比例
		R1 NVARCHAR(512),    --是否结算
		S DECIMAL(18,2),    --结算金额
		T DATE,    --结算时间
		U DECIMAL(18,2),    --未支付金额
		V DECIMAL(18,2),    --其中：质保金
		W DECIMAL(18,2),    --合同累计扣款金额
		X DECIMAL(18,2),    --已扣款金额
		Y DECIMAL(18,2),    --未扣款金额
		IsUseable TINYINT	--合约规划是否可用
)

--检测是否从末级项目穿透过来的，如果不是末级项目，返回空集合
IF NOT EXISTS (SELECT 1 FROM dbo.data_wide_mdm_Project a WHERE a.p_projectId=@projguid AND NOT EXISTS(SELECT 1 FROM dbo.data_wide_mdm_Project b WHERE b.ParentGUID=a.p_projectId))
BEGIN
		SELECT 
		CostAccountGUID,
		ParentGUID,	
		OrderHierarchyCode AS '排序编码',
		ROW_NUMBER() OVER (ORDER BY OrderHierarchyCode) AS '序号',
		AccountCode AS '科目代码',
		NodeName AS '科目名称',
		NodeType AS '类别',
		BudgetOrderName AS '合同名称',
		A ,
		B ,
		C ,
		D ,
		E ,
		F ,
		G ,
		--H ,
		--I ,
		J ,
		K ,
		R ,
		L ,
		M ,
		N1,
		N ,
		O1,
		O ,
		P1,
		P ,
		Q,
		R,
		S,
		T,
		U,
		V,
		W,
		X,
		Y,
		IsUseable
		FROM @data
		RETURN
END

--1. 插入科目节点
INSERT INTO @data    
SELECT
a.CostAccountGUID , -- CostAccountGUID 
a.ParentGUID , -- ParentGUID 
a.HierarchyCode , -- OrderHierarchyCode 
a.AccountCode , -- AccountCode 
a.AccountShortName , --NodeName
N'科目' , -- NodeType 
N'' , -- BudgetOrderName 
a.AccountLevel,    --[Level]
b.TotalTargetCost , -- A 可研版目标成本
a.TotalTargetCost , -- B 最新版目标成本（版号）
0, -- C 合约规划金额
a.DynamicCost , -- D 动态成本
N'' , -- E 合同编号
N'', -- F 合同名称
N'', -- G 乙方名称
--a.AreaDifferent , -- H 
--a.PriceDifferent , -- I 
NULL, -- J 合同签订日期
NULL , -- K 合同金额
NULL , --R 不计成本金额
a.Contract, -- L 合同净值
a.Contract + a.SupplementalContract , -- M 合同净值+补协金额
a.DesignAlter+a.SiteVisa+a.MaterialDiff , -- N1 合同变更金额（全变更）
a.Contract + a.SupplementalContract+a.DesignAlter+a.SiteVisa+a.MaterialDiff , -- N 合同净值+补协+合同变更金额
a.EstimateChange+ a.ContractPlanningOccur, -- O1 待发生合约规划金额
-a.ExcessSavings, -- O 规划余量
a.Payable - a.WithoutContractPayment , -- P1 合同申请金额
a.Paid , -- P 已支付金额
CASE WHEN a.Payable - a.WithoutContractPayment = 0 THEN 0 ELSE CONVERT(DECIMAL(18,2),ROUND(a.Paid * 100 / (a.Payable - a.WithoutContractPayment),2)) END, -- Q 支付比例
N'',  -- R1 是否结算
a.SettlementAmount, -- S 结算金额
NULL, --T 结算时间
a.Payable - a.Paid, -- U 未支付
NULL ,-- V 其中：质保金
NULL , --W 合同累计扣款金额
a.DeductAmount, --X 已扣款金额
NULL , --Y 未扣款金额
1 AS IsUseable
FROM dbo.data_wide_cb_costaccount a WITH (NOLOCK)
LEFT JOIN dbo.data_wide_cb_TargetCostStageVersionDetail b WITH (NOLOCK) ON a.BelongGUID = b.StageAccountGUID AND b.ProjectGUID = a.ProjGUID AND b.TargetCostVersionNAME = '可研版'
WHERE a.ProjGUID = @projguid AND a.NodeType = 0

--2 . 插入末级合约节点
INSERT INTO @data    
SELECT
a.CostAccountGUID , -- CostAccountGUID 
c.CostAccountGUID , -- ParentGUID 
c.HierarchyCode + '.' + ISNULL(a.BudgetCode,''), -- OrderHierarchyCode 
'' , -- AccountCode 
a.BudgetName , --NodeName
CASE WHEN a.IsUseable = 1 THEN '合约规划' ELSE ISNULL(a.BudgetOrderType,'三费导入') END , -- NodeType 
CASE WHEN a.IsUseable = 1 THEN '' ELSE ISNULL(a.BudgetOrderName,'三费导入') END , -- BudgetOrderName 
0,    --[Level]
NULL, -- A 可研版目标成本
NULL, -- B 最新版目标成本（版号）
a.BudgetAmount, -- C 合约规划金额
a.DynamicCost , -- D 动态成本
CASE WHEN a.BudgetOrderType = '合同' THEN a.BudgetOrderCode ELSE NULL END , -- E 合同编号
CASE WHEN a.BudgetOrderType = '合同' THEN a.BudgetOrderName ELSE NULL END, -- F 合同名称
CASE WHEN a.BudgetOrderType = '合同' THEN a.BudgetOrderYfProviderName ELSE NULL END, -- G 乙方名称
--a.AreaDifferent , -- H 
--a.PriceDifferent , -- I 
CASE WHEN a.BudgetOrderType = '合同' THEN CC.CreatedTime ELSE NULL END, -- J 合同签订日期
CASE WHEN a.BudgetOrderType = '合同' THEN CC.TotalAmount ELSE NULL END, -- K 合同金额
CASE WHEN a.BudgetOrderType = '合同' THEN CC.BjcbAmount ELSE NULL END, --R 不计成本金额
a.Contract, -- L 合同净值
a.Contract + a.SupplementalContract , -- M 合同净值+补协金额
a.DesignAlter+a.SiteVisa+a.MaterialDiff , -- N1 合同变更金额（全变更）
a.Contract + a.SupplementalContract+a.DesignAlter+a.SiteVisa+a.MaterialDiff , -- N 合同净值+补协+合同变更金额
a.EstimateChange+ a.ContractPlanningOccur, -- O1 待发生合约规划金额
-a.ExcessSavings, -- O 规划余量
a.Payable - a.WithoutContractPayment , -- P1 合同申请金额
a.Paid , -- P 已支付金额
CASE WHEN a.Payable - a.WithoutContractPayment = 0 THEN 0 ELSE CONVERT(DECIMAL(18,2),ROUND(a.Paid * 100 / (a.Payable - a.WithoutContractPayment),2)) END, -- Q 支付比例
CC.JsState,  -- R1 是否结算
a.SettlementAmount, -- S 结算金额
CC.JsDate, --T 结算时间
a.Payable - a.Paid, -- U 未支付
CASE WHEN CC.JsState = '已结算' then CC.BxAmount else 0 END ,-- V 其中：质保金
CC.DeDuctAmount , --W 合同累计扣款金额
CASE WHEN a.BudgetOrderType = '合同' THEN CC.DeductAmount ELSE NULL END, --X 已扣款金额
NULL , --Y 未扣款金额 
a.IsUseable
FROM dbo.data_wide_cb_costaccount a WITH (NOLOCK)   --合约节点
LEFT JOIN dbo.data_wide_cb_costaccount c WITH (NOLOCK)   --合约所属科目节点
ON c.ProjGUID = c.ProjGUID AND c.NodeType = 0 AND a.BelongGUID = c.SourceGUID
LEFT JOIN data_wide_cb_Contract CC on a.BudgetOrderCode = CC.ContractCode
WHERE a.ProjGUID = @projguid AND a.NodeType = 10 AND a.IsEnd  =1

--3.  更新父级节点A列、D列、L列
SELECT @MaxLevel =MAX(Level) FROM @data WHERE NodeType = '科目'
SET @CurrentLevel = @MaxLevel
WHILE @CurrentLevel >= 0
BEGIN
		UPDATE a
		SET  a.C = ISNULL((SELECT SUM(b.C) FROM @data b WHERE b.ParentGUID=a.CostAccountGUID),a.C)
		FROM @data a
		WHERE a.[Level] = @CurrentLevel AND a.NodeType = '科目'

		SET @CurrentLevel = @CurrentLevel - 1
END

--4.  返回数据
SELECT 
CostAccountGUID,
ParentGUID,
OrderHierarchyCode AS '排序编码',
ROW_NUMBER() OVER (ORDER BY OrderHierarchyCode) AS '序号',
AccountCode AS '科目代码',
NodeName AS '科目名称',
NodeType AS '类别',
BudgetOrderName AS '合同名称',
A ,    --可研版目标成本
		B ,
		C ,
		D ,
		E ,
		F ,
		G ,
		J ,
		K ,
		R ,
		L ,
		M ,
		N1,
		N ,
		O1,
		O ,
		P1,
		P ,
		Q ,
		R1 ,
		S ,
		T ,
		U ,
		V ,
		W ,
		X ,
		Y ,
IsUseable
FROM @data