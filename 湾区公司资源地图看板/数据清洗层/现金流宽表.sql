
--缓存成本系统本月实付款情况
SELECT  cp.ContractGUID ,
        SUM(CASE WHEN cb.HtTypeCode LIKE '01%' THEN PayAmount ELSE 0 END) / 10000.0 AS 本月地价支出 ,
        SUM(CASE WHEN cb.HtTypeCode NOT LIKE '01%' AND  cb.HtTypeCode NOT LIKE '09%' AND cb.HtTypeCode NOT LIKE '08%' AND   cb.HtTypeCode NOT LIKE '07%' THEN PayAmount
                 ELSE 0
            END) / 10000.0 AS 本月除地价外直投发生 ,
        SUM(CASE WHEN cb.HtTypeCode LIKE '07%' THEN PayAmount ELSE 0 END) / 10000.0 AS 本月营销费支出 ,
        SUM(CASE WHEN cb.HtTypeCode LIKE '08%' THEN PayAmount ELSE 0 END) / 10000.0 AS 本月管理费支出 ,
        SUM(CASE WHEN cb.HtTypeCode LIKE '09%' THEN PayAmount ELSE 0 END) / 10000.0 AS 本月财务费支出
INTO    #confk
FROM    [172.16.4.141].MyCost_Erp352.dbo.cb_Pay cp
        INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.vcb_contract cb ON cp.ContractGUID = cb.ContractGUID
WHERE   DATEDIFF(mm, PayDate, GETDATE()) = 0
GROUP BY cp.ContractGUID;

--获取合同项目信息
SELECT  t.contractguid ,
        t.projguid ,
        ROW_NUMBER() OVER (PARTITION BY t.contractguid ORDER BY t.projguid) AS rn
INTO    #conproj
FROM(SELECT con.contractguid ,
            par.projguid
     FROM   #confk con
            INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.cb_contractproj cpj ON con.contractguid = cpj.contractguid
            INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.p_project pj ON pj.projguid = cpj.projguid
            INNER JOIN [172.16.4.141].MyCost_Erp352.dbo.p_project par ON par.projcode = pj.parentcode
     GROUP BY con.contractguid ,
              par.projguid) t;

--按照项目数据来均分项目
SELECT  pj.projguid ,
        SUM(CONVERT(DECIMAL(16, 4), 本月地价支出 * 1.0 / rn.rn)) AS 本月地价支出 ,
        SUM(CONVERT(DECIMAL(16, 4), 本月除地价外直投发生 * 1.0 / rn.rn)) AS 本月除地价外直投发生 ,
        SUM(CONVERT(DECIMAL(16, 4), 本月营销费支出 * 1.0 / rn.rn)) AS 本月营销费支出 ,
        SUM(CONVERT(DECIMAL(16, 4), 本月管理费支出 * 1.0 / rn.rn)) AS 本月管理费支出 ,
        SUM(CONVERT(DECIMAL(16, 4), 本月财务费支出 * 1.0 / rn.rn)) AS 本月财务费支出
INTO    #byfk
FROM    #confk fk
        INNER JOIN #conproj pj ON pj.contractguid = fk.ContractGUID
        INNER JOIN(SELECT   contractguid, MAX(rn) AS rn FROM    #conproj GROUP BY contractguid) rn ON rn.contractguid = fk.ContractGUID
GROUP BY pj.projguid;

--缓存销售系统本月回笼情况
-- SELECT  TopProjGUID ,
--         SUM(ISNULL(hl.应退未退本月金额, 0) + ISNULL(hl.本月回笼金额认购, 0) + ISNULL(hl.本月回笼金额签约, 0) + ISNULL(hl.关闭交易本月退款金额, 0) + ISNULL(hl.本月特殊业绩关联房间, 0) + ISNULL(hl.本月特殊业绩未关联房间, 0)) AS 本月实际回笼全口径
-- INTO    #byhl
-- FROM    data_wide_dws_s_gsfkylbhzb hl
-- WHERE   DATEDIFF(DAY, qxDate, GETDATE()) = 0
-- GROUP BY TopProjGUID;

SELECT   TopProjGUID  ,
CASE WHEN MONTH(GETDATE()) = 1 THEN 本年实际回笼全口径 ELSE 本年实际回笼全口径 - 上个月本年实际回笼全口径 END AS 本月实际回笼全口径 
INTO    #byhl
FROM (SELECT TopProjGUID ,
       SUM(
       CASE WHEN DATEDIFF(dd, qxDate, GETDATE()) = 0 THEN
                ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + ISNULL(hl.本年特殊业绩关联房间, 0)
                + ISNULL(hl.本年特殊业绩未关联房间, 0)
            ELSE 0
       END) AS 本年实际回笼全口径 ,
       SUM(
       CASE WHEN DATEDIFF(dd, qxDate, DATEADD(m, DATEDIFF(MONTH, -1, GETDATE()) - 1, -1)) = 0 THEN
                ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + ISNULL(hl.本年特殊业绩关联房间, 0)
                + ISNULL(hl.本年特殊业绩未关联房间, 0)
            ELSE 0
       END) AS 上个月本年实际回笼全口径 
FROM   data_wide_dws_s_gsfkylbhzb hl
GROUP BY TopProjGUID) t

--获取项目层级的现金流数据，并循环更新区域公司->公司的数据
SELECT  o.组织架构父级ID ,
        o.组织架构id ,
        o.组织架构名称 ,
        3 AS 组织架构类型 ,
        --dss累计现金流+成本本月实时现金流
        xjl.累计经营性现金流 +(isnull(byhl.本月实际回笼全口径,0) - (isnull(byfk.本月地价支出,0) + isnull(byfk.本月除地价外直投发生,0) + isnull(byfk.本月营销费支出,0) 
        + isnull(byfk.本月管理费支出,0) + isnull(byfk.本月财务费支出,0)))  AS 累计经营性现金流 ,
        isnull(xjl.累计回笼金额,0)+isnull(byhl.本月实际回笼全口径,0) AS 累计现金流入 ,
        isnull(xjl.累计直接投资土地费用,0) + isnull(xjl.累计建安费用,0) + isnull(sanf.累计营销费支出,0) + isnull(sanf.累计管理费支出,0) 
        + isnull(sanf.累计财务费支出,0) + isnull(xjl.累计税金,0)+
        isnull(byfk.本月地价支出,0) + isnull(byfk.本月除地价外直投发生,0) + isnull(byfk.本月营销费支出,0) + isnull(byfk.本月管理费支出,0) 
        + isnull(byfk.本月财务费支出,0) AS 累计现金流出 ,
        isnull(xjl.累计直接投资土地费用,0)+isnull(byfk.本月地价支出,0) AS 累计地价支出 ,
        isnull(xjl.累计建安费用,0)+isnull(byfk.本月除地价外直投发生,0) AS 累计除地价外直投发生 ,
        isnull(sanf.累计营销费支出,0)+isnull(byfk.本月营销费支出,0) as 累计营销费支出,
        isnull(sanf.累计管理费支出,0)+isnull(byfk.本月管理费支出,0) as 累计管理费支出,
        isnull(sanf.累计财务费支出,0)+isnull(byfk.本月财务费支出,0) as  累计财务费支出,
        xjl.累计税金 AS 累计税金支出 ,
        --dss本年现金流+成本本月实时现金流
        xjl.本年经营性现金流+(isnull(byhl.本月实际回笼全口径,0) - (isnull(byfk.本月地价支出,0) + isnull(byfk.本月除地价外直投发生,0) + isnull(byfk.本月营销费支出,0) 
        + isnull(byfk.本月管理费支出,0) + isnull(byfk.本月财务费支出,0))) AS 本年经营性现金流 ,
        tb.本年我司股东净投入 ,
        isnull(xjl.本年回笼金额,0)+isnull(byhl.本月实际回笼全口径,0) AS 本年现金流入 ,
        isnull(xjl.本年直接投资土地费用,0) + isnull(xjl.本年建安费用,0) + isnull(sanf.本年营销费支出,0) + isnull(sanf.本年管理费支出,0) 
        + isnull(sanf.本年财务费支出,0) + isnull(xjl.本年税金,0)+isnull(byfk.本月地价支出,0) + isnull(byfk.本月除地价外直投发生,0) + isnull(byfk.本月营销费支出,0) + isnull(byfk.本月管理费支出,0) 
        + isnull(byfk.本月财务费支出,0) AS 本年现金流出 ,
        isnull(xjl.本年直接投资土地费用,0)+isnull(byfk.本月地价支出,0) AS 本年地价支出 ,
        isnull(xjl.本年建安费用,0)+isnull(byfk.本月除地价外直投发生,0) AS 本年除地价外直投发生 ,
        rw.ZtPlanTotal / 10000.0 AS 本年除地价外直投任务 ,
        qnrw.ZtPlanTotal / 10000.0 AS 去年除地价外直投任务 ,
        qnzt.YearJaInvestmentAmount AS 去年除地价外直投发生 ,
        byrw.ZtPlanTotal / 10000.0 AS 本月除地价外直投任务 ,
        byrw.PlanThreeInvestment / 10000.0 AS 本月三费任务 ,
        byrw.PlanTaxAmount / 10000.0 AS 本月税金任务 ,
        byrw.getLandAmount / 10000.0 AS 本月土地任务 ,
		byrw.LoanTaskAmount/ 10000.0 AS 本月贷款任务,
        isnull(sanf.本年营销费支出,0)+isnull(byfk.本月营销费支出,0) as 本年营销费支出,
        isnull(sanf.本年管理费支出,0)+isnull(byfk.本月管理费支出,0) as 本年管理费支出,
        isnull(sanf.本年财务费支出,0)+isnull(byfk.本月财务费支出,0) as 本年财务费支出,
        xjl.本年税金 AS 本年税金支出 ,
        rw.PlanInvestmentAmount / 10000.0 AS 本年拓展任务 ,
        rw.RealInvestmentAmount AS 本年实际拓展金额 ,
	    rw.LoanTaskAmount /  10000.0 AS 本年贷款任务,
        --本月情况要取成本的
        isnull(byhl.本月实际回笼全口径,0) - (isnull(byfk.本月地价支出,0) + isnull(byfk.本月除地价外直投发生,0) + isnull(byfk.本月营销费支出,0) 
        + isnull(byfk.本月管理费支出,0) + isnull(byfk.本月财务费支出,0)) AS 本月经营性现金流 ,
        byhl.本月实际回笼全口径 AS 本月现金流入 ,
        isnull(byfk.本月地价支出,0) + isnull(byfk.本月除地价外直投发生,0) + isnull(byfk.本月营销费支出,0) + isnull(byfk.本月管理费支出,0) 
        + isnull(byfk.本月财务费支出,0) AS 本月现金流出 ,
        byfk.本月地价支出 ,
        byfk.本月除地价外直投发生 ,
        byfk.本月营销费支出 ,
        byfk.本月管理费支出 ,
        byfk.本月财务费支出 ,
        0 AS 本月税金支出 ,                           --税金取不了，留空
        0 AS 本月贷款金额 ,                           --贷款金额取不了，留空
        isnull(byhl.本月实际回笼全口径,0)-(isnull(byfk.本月地价支出,0)+isnull(byfk.本月除地价外直投发生,0)+isnull(byfk.本月营销费支出,0)
        +isnull(byfk.本月管理费支出,0)+isnull(byfk.本月财务费支出,0)) AS 本月股东现金流 ,
        tb.保利方投入余额 我司资金占用 ,
        tb.账面可动用资金 ,
        tb.监控款余额 ,
        xjl.供应链融资余额 ,
        xjl.本年净增贷款 ,
        xjl.累计贷款余额 AS 贷款余额 ,
        isnull(xjl.累计股东投资回收金额,0)+(isnull(byhl.本月实际回笼全口径,0)-(isnull(byfk.本月地价支出,0)+isnull(byfk.本月除地价外直投发生,0)+isnull(byfk.本月营销费支出,0)
        +isnull(byfk.本月管理费支出,0)+isnull(byfk.本月财务费支出,0))) AS 累计股东现金流 ,
        isnull(xjl.本年股东投资回收金额,0)+(isnull(byhl.本月实际回笼全口径,0)-(isnull(byfk.本月地价支出,0)+isnull(byfk.本月除地价外直投发生,0)+isnull(byfk.本月营销费支出,0)
        +isnull(byfk.本月管理费支出,0)+isnull(byfk.本月财务费支出,0))) AS 本年股东现金流 ,
        tb.股东投入余额 ,
        tb.保利方投入余额 ,
        CASE WHEN ISNULL(pj.GenreTableType, '') = '我司并表' THEN tb.账面可动用资金 ELSE 0 END 账面可动用资金并表口径 ,
        CASE WHEN ISNULL(pj.GenreTableType, '') = '我司并表' THEN tb.监控款余额 ELSE 0 END 监控款余额并表口径 ,
        CASE WHEN ISNULL(pj.GenreTableType, '') = '我司并表' THEN xjl.累计贷款余额 ELSE 0 END 贷款余额并表口径 ,
        CASE WHEN ISNULL(pj.GenreTableType, '') = '我司并表' THEN tb.保利方投入余额 ELSE 0 END 我司资金占用并表口径 ,
        CASE WHEN ISNULL(pj.GenreTableType, '') = '我司并表' THEN tb.股东投入余额 ELSE 0 END 股东投入余额并表口径 ,
        CASE WHEN ISNULL(pj.GenreTableType, '') = '我司并表' THEN xjl.供应链融资余额 ELSE 0 END 供应链融资余额并表口径 ,
        rw.PlanCashFlowAmount / 10000.0 AS 本年经营性现金流目标 ,   --万元
        rw.ShareholdersInvestmentsTask / 10000.0 AS 本年股东投资现金流目标 ,
        byrw.PlanCashFlowAmount / 10000.0 AS 本月经营性现金流目标 , --万元
        byrw.ShareholdersInvestmentsTask / 10000.0 AS 本月股东投资现金流目标
INTO    #temp_result
FROM    data_wide_dws_s_WqBaseStatic_Organization o
        INNER JOIN data_wide_dws_mdm_project pj ON pj.projguid = o.组织架构id
        --获取现金流数据
        LEFT JOIN dw_f_TopProj_Filltab_Fact xjl ON o.组织架构id = xjl.项目guid
        --获取本年拓展、现金流任务数据
        LEFT JOIN data_wide_dws_s_SalesBudgetVerride rw ON rw.BudgetDimension = '年度' AND   rw.BudgetDimensionValue = YEAR(GETDATE()) AND   rw.OrganizationGUID = o.组织架构id
        --获取去年的直投任务
        LEFT JOIN data_wide_dws_s_SalesBudgetVerride qnrw ON qnrw.BudgetDimension = '年度' AND   qnrw.BudgetDimensionValue = YEAR(GETDATE()) - 1 AND qnrw.OrganizationGUID = o.组织架构id
        --获取本月的直投、三费、土地、税金、现金流任务
        LEFT JOIN data_wide_dws_s_SalesBudgetVerride byrw ON byrw.BudgetDimension = '月度' AND   byrw.BudgetDimensionValue = SUBSTRING(CONVERT(NVARCHAR(7), GETDATE(), 120), 1, 7)
                                                             AND   byrw.OrganizationGUID = o.组织架构id
        --获取去年的直投发生数
        LEFT JOIN(SELECT    ProjGUID ,
                            YearJaInvestmentAmount
                  FROM  data_wide_dws_ys_ys_DssCashFlowData
                  WHERE Year = YEAR(GETDATE()) - 1 AND month = 12) qnzt ON qnzt.projguid = o.组织架构id
        --获取三费
        LEFT JOIN(SELECT    组织架构id ,
                            本月营销费支出 ,
                            本月管理费支出 ,
                            本月财务费支出 ,
                            本年营销费支出 ,
                            本年管理费支出 ,
                            本年财务费支出 ,
                            累计营销费支出 ,
                            累计管理费支出 ,
                            累计财务费支出
                  FROM  [172.16.4.141].erp25.dbo.ydkb_dthz_wq_deal_cbinfo
                  WHERE 组织架构类型 = 3) sanf ON sanf.组织架构id = o.组织架构id
        --获取填报内容
        LEFT JOIN(SELECT    组织架构ID ,
                            我司资金占用 ,
                            本年我司股东净投入 ,
                            股东投入余额 ,
                            保利方投入余额 ,
                            账面可动用资金 ,
                            监控款余额
                  FROM  data_tb_WqBaseStatic_Projinfo) tb ON tb.组织架构id = o.组织架构id
        --获取本月回笼金额
        LEFT JOIN #byhl byhl ON byhl.topprojguid = o.组织架构id
        --获取本月实付款数据
        LEFT JOIN #byfk byfk ON byfk.projguid = o.组织架构id
WHERE   o.组织架构类型 = 3;

--select  * from  #temp_result where 本月税金支出 is null 

--循环更新数据
DECLARE @baseinfo INT;

SET @baseinfo = 2;

WHILE(@baseinfo > 0)
    BEGIN
        INSERT INTO #temp_result
        SELECT  o.组织架构父级ID ,
                o.组织架构id ,
                o.组织架构名称,
                o.组织架构类型,
                SUM(isnull(j.累计经营性现金流,0)) AS 累计经营性现金流 ,
                SUM(isnull(j.累计现金流入,0)) AS 累计现金流入 ,
                SUM(isnull(j.累计现金流出,0)) AS 累计现金流出 ,
                SUM(isnull(j.累计地价支出,0)) AS 累计地价支出 ,
                SUM(isnull(j.累计除地价外直投发生,0)) AS 累计除地价外直投发生 ,
                SUM(isnull(j.累计营销费支出,0)) AS 累计营销费支出 ,
                SUM(isnull(j.累计管理费支出,0)) AS 累计管理费支出 ,
                SUM(isnull(j.累计财务费支出,0)) AS 累计财务费支出 ,
                SUM(isnull(j.累计税金支出,0)) AS 累计税金支出 ,
                SUM(isnull(j.本年经营性现金流,0)) AS 本年经营性现金流 ,
                SUM(isnull(j.本年我司股东净投入,0)) AS 本年我司股东净投入 ,
                SUM(isnull(j.本年现金流入,0)) AS 本年现金流入 ,
                SUM(isnull(j.本年现金流出,0)) AS 本年现金流出 ,
                SUM(isnull(j.本年地价支出,0)) AS 本年地价支出 ,
                SUM(isnull(j.本年除地价外直投发生,0)) AS 本年除地价外直投发生 ,
                SUM(isnull(j.本年除地价外直投任务,0)) AS 本年除地价外直投任务 ,
                SUM(isnull(j.去年除地价外直投任务,0)) AS 去年除地价外直投任务 ,
                SUM(isnull(j.去年除地价外直投发生,0)) AS 去年除地价外直投发生 ,
                SUM(isnull(j.本月除地价外直投任务,0)) AS 本月除地价外直投任务 ,
                SUM(isnull(j.本月三费任务,0)) AS 本月三费任务 ,
                SUM(isnull(j.本月税金任务,0)) AS 本月税金任务 ,
                SUM(isnull(j.本月土地任务,0)) AS 本月土地任务 ,
                SUM(isnull(j.本月贷款任务,0)) AS 本月贷款任务 ,
                SUM(isnull(j.本年营销费支出,0)) AS 本年营销费支出 ,
                SUM(isnull(j.本年管理费支出,0)) AS 本年管理费支出 ,
                SUM(isnull(j.本年财务费支出,0)) AS 本年财务费支出 ,
                SUM(isnull(j.本年税金支出,0)) AS 本年税金支出 ,
                SUM(isnull(j.本年拓展任务,0)) AS 本年拓展任务 ,
                SUM(isnull(j.本年实际拓展金额,0)) AS 本年实际拓展金额 ,
				SUM(isnull(j.本年贷款任务,0)) AS 本年贷款任务,
                SUM(isnull(j.本月经营性现金流,0)) AS 本月经营性现金流 ,
                SUM(isnull(j.本月现金流入,0)) AS 本月现金流入 ,
                SUM(isnull(j.本月现金流出,0)) AS 本月现金流出 ,
                SUM(isnull(j.本月地价支出,0)) AS 本月地价支出 ,
                SUM(isnull(j.本月除地价外直投发生,0)) AS 本月除地价外直投发生 ,
                SUM(isnull(j.本月营销费支出,0)) AS 本月营销费支出 ,
                SUM(isnull(j.本月管理费支出,0)) AS 本月管理费支出 ,
                SUM(isnull(j.本月财务费支出,0)) AS 本月财务费支出 ,
                SUM(isnull(j.本月税金支出,0)) AS 本月税金支出 ,
                SUM(isnull(j.本月贷款金额,0)) AS 本月贷款金额 ,
                SUM(isnull(j.本月股东现金流,0)) AS 本月股东现金流 ,
                SUM(isnull(j.我司资金占用,0)) AS 我司资金占用 ,
                SUM(isnull(j.账面可动用资金,0)) AS 账面可动用资金 ,
                SUM(isnull(j.监控款余额,0)) AS 监控款余额 ,
                SUM(isnull(j.供应链融资余额,0)) AS 供应链融资余额 ,
                SUM(isnull(j.本年净增贷款,0)) AS 本年净增贷款 ,
                SUM(isnull(j.贷款余额,0)) AS 贷款余额 ,
                SUM(isnull(j.累计股东现金流,0)) AS 累计股东现金流 ,
                SUM(isnull(j.本年股东现金流,0)) AS 本年股东现金流 ,
                SUM(isnull(j.股东投入余额,0)) AS 股东投入余额 ,
                SUM(isnull(j.保利方投入余额,0)) AS 保利方投入余额 ,
                SUM(isnull(j.账面可动用资金并表口径,0)) AS 账面可动用资金并表口径 ,
                SUM(isnull(j.监控款余额并表口径,0)) AS 监控款余额并表口径 ,
                SUM(isnull(j.贷款余额并表口径,0)) AS 贷款余额并表口径 ,
                SUM(isnull(j.我司资金占用并表口径,0)) AS 我司资金占用并表口径 ,
                SUM(isnull(j.股东投入余额并表口径,0)) AS 股东投入余额并表口径 ,
                SUM(isnull(j.供应链融资余额并表口径,0)) AS 供应链融资余额并表口径 ,
                SUM(isnull(j.本年经营性现金流目标,0)) AS 本年经营性现金流目标 ,
                SUM(isnull(j.本年股东投资现金流目标,0)) AS 本年股东投资现金流目标 ,
                SUM(isnull(j.本月经营性现金流目标,0)) AS 本月经营性现金流目标 ,
                SUM(isnull(j.本月股东投资现金流目标,0)) AS 本月股东投资现金流目标
        FROM    data_wide_dws_s_WqBaseStatic_Organization o
                LEFT JOIN #temp_result j ON o.组织架构id = j.组织架构父级id
                LEFT JOIN data_wide_dws_mdm_project p ON p.ProjGUID = o.组织架构id
        WHERE   o.组织架构类型 = @baseinfo
        GROUP BY o.组织架构父级ID ,
                 o.组织架构id ,
                 o.组织架构名称 ,
                 o.组织架构类型;

        SET @baseinfo = @baseinfo - 1;
    END

SELECT  * FROM  #temp_result

DROP TABLE #temp_result ,
           #byfk ,
           #byhl ,
           #confk ,
           #conproj
