-- 项目产值回顾 对数需求
SELECT  bu.buname AS [公司名称],
        p.ProjName AS [所属项目],
        mp.ProjStatus AS [项目状态],
        mp.ConstructStatus AS [工程状态],
        TotalOutputValue AS [回顾总产值],
        YfsOutputValue AS [回顾已发生产值],
        DfsOutputValue AS [回顾待发生产值], 
        ht.HtAmount AS [合同累计合同金额],
        ht.Yljze AS [合同累计预留金金额],
        ht.jfljywccz AS [合同现场累计产值],
        ht.wfqcz AS [合同累计未发起产值金额],

        htNotfee.HtAmountNotfee AS [合同累计合同金额不含土地及三费],
        htNotfee.YljzeNotfee AS [合同累计预留金金额不含土地及三费],
        htNotfee.jfljywcczNotfee AS [合同现场累计产值不含土地及三费],
        htNotfee.wfqczNotfee AS [合同累计未发起产值金额不含土地及三费],

        isnull(YfsOutputValue,0) - isnull(ht.jfljywccz,0) AS [差值], -- （"回顾-已发生产值"-"合同-累计现场累计产值"）
        isnull(YfsOutputValue,0) - isnull(htNotfee.jfljywcczNotfee,0) AS [差值不含土地及三费] -- （"回顾-已发生产值"-"合同-累计现场累计产值"）
FROM    p_project p 
        INNER JOIN ERP25.dbo.mdm_project mp ON mp.projguid = p.ProjGUID
        INNER JOIN mybusinessunit bu ON bu.buguid = p.buguid
        LEFT JOIN p_project pp ON pp.ProjCode = p.ParentCode AND pp.Level = 2
        OUTER APPLY (
            SELECT  TOP 1 ProjGUID,
                    ReviewDate,
                    ApproveState,
                    TotalOutputValue,
                    YfsOutputValue,
                    DfsOutputValue
            FROM    cb_OutputValueMonthReview 
            WHERE   -- ApproveState = '已审核' AND
                     cb_OutputValueMonthReview.ProjGUID = p.ProjGUID
            ORDER BY ReviewDate DESC
        ) cbview
        -- 合同金额统计
        LEFT JOIN (
            SELECT  cbp.ProjGUID,
                    SUM(ISNULL(cb.HtAmount,0)) AS HtAmount,  -- 合同金额
                    SUM(ISNULL(Yljze,0)) AS Yljze, -- 预留金金额
                    SUM(ISNULL(cbz.jfljywccz,0)) AS jfljywccz, -- 甲方审核-现场累计产值
                    SUM(CASE WHEN cb.JsState = '结算' 
                            THEN cb.JsAmount_Bz 
                            ELSE ISNULL(cb.htamount, 0) + ISNULL(cb.sumalteramount, 0)
                        END - ISNULL(cbz.jfljywccz, 0)) AS wfqcz -- 未发起产值金额
            FROM    cb_Contract cb
			        inner  join cb_httype ty on ty.HtTypeGUID =ty.HtTypeGUID and  ty.BUGUID =cb.BUGUID
                    INNER JOIN cb_ContractProj cbp ON cbp.ContractGUID = cb.ContractGUID
                    LEFT JOIN cb_contractcz cbz ON cbz.contractguid = cb.contractguid
                    LEFT JOIN (
                        SELECT  ContractGUID,
                                SUM(ISNULL(CfAmount,0)) AS Yljze -- 预留金金额
                        FROM    [dbo].[cb_YgAlter2Budget] 
                        GROUP BY ContractGUID
                    ) ylj ON ylj.ContractGUID = cb.ContractGUID
            WHERE   cb.ApproveState = '已审核' -- and  ty.HtTypeCode not in ('01','01.01','01.02','01.03','01.04','01.05')
            GROUP BY cbp.ProjGUID
        ) ht ON ht.ProjGUID = p.ProjGUID
        -- 不含土地款及三费
        LEFT JOIN (
            SELECT  cbp.ProjGUID,
                    SUM(ISNULL(cb.HtAmount,0)) AS HtAmountNotfee,  -- 合同金额
                    SUM(ISNULL(Yljze,0)) AS YljzeNotfee, -- 预留金金额
                    SUM(ISNULL(cbz.jfljywccz,0)) AS jfljywcczNotfee, -- 甲方审核-现场累计产值
                    SUM(CASE WHEN cb.JsState = '结算' 
                            THEN cb.JsAmount_Bz 
                            ELSE ISNULL(cb.htamount, 0) + ISNULL(cb.sumalteramount, 0)
                        END - ISNULL(cbz.jfljywccz, 0)) AS wfqczNotfee -- 未发起产值金额
            FROM    cb_Contract cb
			        inner  join cb_httype ty on ty.HtTypeGUID =ty.HtTypeGUID and  ty.BUGUID =cb.BUGUID
                    INNER JOIN cb_ContractProj cbp ON cbp.ContractGUID = cb.ContractGUID
                    LEFT JOIN cb_contractcz cbz ON cbz.contractguid = cb.contractguid
                    LEFT JOIN (
                        SELECT  ContractGUID,
                                SUM(ISNULL(CfAmount,0)) AS Yljze -- 预留金金额
                        FROM    [dbo].[cb_YgAlter2Budget] 
                        GROUP BY ContractGUID
                    ) ylj ON ylj.ContractGUID = cb.ContractGUID
            WHERE   cb.ApproveState = '已审核' 
            -- 不含土地款及管理费、营销费、财务费合同
            and  ty.HtTypeCode not in ('01','01.01','01.02','01.03','01.04','01.05',
                                      '07','07.01','07.02','07.03','07.04','07.05',
                                      '07.06','07.07','07.08','07.09','07.10','07.11',
                                      '07.12','07.13','07.14','08','08.01','09','09.01')
            GROUP BY cbp.ProjGUID
        ) htNotfee ON htNotfee.ProjGUID = p.ProjGUID
WHERE   1=1  and  bu.buguid  in ( @buguid ) 
-- AND p.projname = '南昌市青山湖区艾溪湖南路019号85亩项目-一期'
order by  bu.buname, p.ProjName


SELECT  a.contractczguid,
        a.contractguid,
        a.ljywccz,
        a.htczljyfje,
        a.jfljywccz,
        b.sumpayamount AS yzfcz,
        ISNULL((SELECT SUM(app.applyamount) 
                FROM cb_htfkapply app 
                WHERE app.contractguid = a.contractguid 
                AND app.applystate = '已审核'), 0) 
        - ISNULL(b.sumpayamount, 0)
        - ISNULL((SELECT ISNULL(SUM(ISNULL(kkamount, 0)), 0)
                  FROM cb_kkmx k 
                  WHERE k.htfkplanguid IN (SELECT htfkapplyguid 
                                         FROM cb_htfkapply app 
                                         WHERE app.applystate = '已审核'
                                         AND app.contractguid = a.contractguid)), 0) AS yspwzfcz,
        ISNULL((SELECT SUM(app.curjfljywccz) - SUM(jfljywccz)
                FROM cb_htfkapply app
                WHERE app.contractguid = a.contractguid 
                AND app.applystate = '审核中'), 0) AS spzcz,
        CASE WHEN b.JsState = '结算' 
             THEN b.JsAmount_Bz 
             ELSE ISNULL(b.htamount, 0) + ISNULL(b.sumalteramount, 0)
        END - ISNULL(a.jfljywccz, 0) AS wfqcz
FROM cb_contractcz a
LEFT JOIN dbo.cb_contract b ON b.contractguid = a.contractguid 
WHERE (1=1)

 --获取产值月度回顾情况
        --获取项目已审核的最晚回顾时间记录
        select * 
        into #OutputValuebb
        from (
        select projguid,ROW_NUMBER() over(PARTITION BY projguid order by ReviewDate desc) as RowNum,OutputValueMonthReviewGUID 
        from MyCost_Erp352.dbo.cb_OutputValueMonthReview where ApproveState = '已审核') t where t.RowNum = 1

        SELECT  pp.projguid, 
                sum(ydhg.TotalOutputValue)/10000.0 as 已完成产值金额, 
                sum(ydhg.LjyfkAmount)/10000.0 AS 合同约定应付金额,
                sum(ydhg.LjsfAmount)/10000.0 as 累计支付金额, 
                sum(ydhg.YfwfAmount)/10000.0 as 应付未付 
        into #OutputValue
        FROM    MyCost_Erp352.dbo.cb_OutputValueMonthReview ydhg
                inner join #OutputValuebb bb on ydhg.OutputValueMonthReviewGUID = bb.OutputValueMonthReviewGUID
                inner join erp25.dbo.mdm_Project p on p.ProjGUID = bb.ProjGUID
                inner join #p pp on p.ParentProjGUID = pp.ProjGUID
        group by pp.projguid