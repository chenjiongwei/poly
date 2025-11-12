-- 跨分期成本合同
-- 杓袁项目
-- B956D877-F0D7-E811-80BF-E61F13C57837
-- 刘庄项目
-- 60B21DA6-2E37-E811-80BA-E61F13C57837
-- 柳林项目
-- 82A4FCF3-ABDE-E911-80B7-0A94EF7517DD

use [MyCost_Erp352]
go 

SELECT 
    projguid, 
    projname, 
    level, 
    projcode 
into  #mp
FROM 
    erp25.dbo.mdm_project 
WHERE 
    projguid IN (
        'B956D877-F0D7-E811-80BF-E61F13C57837', 
        '60B21DA6-2E37-E811-80BA-E61F13C57837', 
        '82A4FCF3-ABDE-E911-80B7-0A94EF7517DD'
    )
    AND level = 2
UNION ALL
SELECT 
    mp.projguid,
    mp.projname,
    mp.level,
    mp.projcode 
FROM 
    erp25.dbo.mdm_project mp
    INNER JOIN erp25.dbo.mdm_project mpp 
        ON mpp.projguid = mp.ParentProjGUID
WHERE 
    mpp.projguid IN (
        'B956D877-F0D7-E811-80BF-E61F13C57837', 
        '60B21DA6-2E37-E811-80BA-E61F13C57837', 
        '82A4FCF3-ABDE-E911-80B7-0A94EF7517DD'
    )
    AND mp.level = 3

-- 查询合同情况
SELECT 
    p.projguid,
    p.projname,
    p.projcode,
	cb.HtClass,
	ht.HtTypeName,
    cb.contractguid,
    cb.contractname,
    cb.contractcode,
    cb.IfDdhs,
    cb.SignDate,
    cb.YfProviderName,
	cb.HtAmount,
	cb.ApproveState,
    case when cb.isFyControl = 1 then  cb.sumpayAmount else pay.PayAmount end as PayAmount,
	cb.JsState,
	cb.ProjectNameList,
	cb.ProjectCodeList,
	cb.IsFyControl,
    mat.contractcode as MasterContractCode,
    mat.contractname as MasterContractName,
    mat.SignDate as MasterContractSignDate,
    mat.HtAmount as MasterContractHtAmount
into #cb
FROM 
    cb_contract cb
	left join cb_HtType ht on ht.HtTypeCode =cb.HtTypeCode and  cb.BUGUID =ht.BUGUID
    left  join  cb_contract mat on mat.contractguid = cb.mastercontractguid
    INNER JOIN ( select  contractguid,projguid  from  cb_contractproj group by contractguid,projguid ) cbp 
        ON cb.contractguid = cbp.contractguid
    INNER JOIN p_project p  ON p.projguid = cbp.projguid
    left  join (
        select ContractGUID,sum(PayAmount) as PayAmount  from  cb_Pay group by  ContractGUID
    ) pay on pay.contractguid = cb.contractguid
WHERE 
    p.projguid IN (SELECT projguid FROM #mp)
order by p.projcode,cb.contractcode

-- 查询跨分期合同
SELECT DISTINCT
    con.HtClass as 合同属性,
    con.HtTypeName as 合同类别,
    con.contractguid      AS 合同GUID,
    con.contractname      AS 合同名称,
    con.contractcode      AS 合同编号,
    con.SignDate          AS 签约日期,
    con.YfProviderName    AS 乙方单位,
    con.HtAmount          AS 有效签约金额,
    con.ApproveState      AS 审核状态,
    con.PayAmount         AS 累计付款金额,
    con.JsState           AS 结算状态,
    case when con.IfDdhs =1  then '是' else '否' end AS 是否单独执行,
    CASE WHEN con.IsFyControl = 1 THEN '是' ELSE '否' END AS 是否费用合同,
    con.MasterContractCode AS 主合同编号,
    con.MasterContractName AS 主合同名称,
    con.MasterContractSignDate AS 主合同签约日期,
    con.MasterContractHtAmount AS 主合同有效签约金额,
    con.ProjectNameList   AS 所属分期,
    con.ProjectCodeList   AS 所属分期编码
FROM
    #cb con
WHERE
    EXISTS (
        SELECT
            1
        FROM
            #cb cb
        WHERE
            con.contractguid = cb.contractguid
        GROUP BY
            contractguid
        HAVING
            COUNT(1) > 1
    );


-- 删除临时表
drop table #mp,#cb