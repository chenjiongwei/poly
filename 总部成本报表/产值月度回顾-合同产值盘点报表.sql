-- 产值月度回顾-合同产值盘点报表
-- 查看回顾拍照的合同列表关联楼数据
SELECT  
        ROW_NUMBER() OVER(ORDER BY ovr.ReviewDate DESC) as 序号,
        bu.BUGUID,
        bu.BUName AS 公司名称,
        p.ProjCode AS 项目编码, 
        p.ProjName AS 项目名称,
        p.ProjGUID,
        ovr.ReviewDate AS 回顾日期,
		FORMAT(ovr.ReviewDate, 'MM') as 回顾月份,
        ovr.CreateOn AS 创建人,
        ovr.ApproveState AS 审批状态,
        CZManageModel AS 产值分摊模式,
        b.OutputValueReviewDetailGUID as 产值盘点明细GUID,
        BusinessName AS 合同名称,
        b.BudgetAmount AS 合约规划金额,
        b.HtAmount AS 合同金额,
        b.BcxyAmount AS 补充协议金额,
        b.HtylAmount AS 合同预留金额,
        b.JsState AS 结算状态,
        b.JsAmount AS 合同结算金额,
        b.Bysfsbcz AS 本月是否申报产值,
        BldName AS 楼栋名称,
        a.BldArea AS 建筑面积,
        a.Jszt AS 建设状态,
        a.Xmpdljwccz AS [项目盘点累计完成产值G],
        a.Ljyfkje AS [项目盘点累计应付款I],
        a.Dfscz AS [待发生产值H],
        a.LjsfkNoFxj AS [累计实付款不含非现金J],
        a.Ljsfk AS [累计实付款],
        ISNULL(a.Xmpdljwccz, 0) - ISNULL(a.LjsfkNoFxj, 0) AS [已发产值未付金额K],
        ISNULL(a.Ljyfkje, 0) - ISNULL(a.LjsfkNoFxj, 0) AS [应付未付金额L],
        a.Sgdwysbcz AS [施工单位已申报产值],
        a.Sgdwysbyfk AS [施工单位已申报应付款],
        a.Jfysdcz AS [甲方已审定产值],
        a.Jfysdyfk AS [甲方已审定应付款]
FROM    cb_OutputValueMonthReview ovr
        INNER JOIN dbo.cb_OutputValueReviewDetail b ON ovr.OutputValueMonthReviewGUID = b.OutputValueMonthReviewGUID
        INNER JOIN dbo.cb_OutputValueReviewBld a ON b.OutputValueReviewDetailGUID = a.OutputValueReviewDetailGUID
        INNER JOIN p_Project p
            ON p.ProjGUID = ovr.ProjGUID
        INNER JOIN myBusinessUnit bu
            ON bu.BUGUID = p.BUGUID
--WHERE   b.OutputValueMonthReviewGUID = 'd9aff95d-7eae-453b-a9d1-f70e89d0e336'
where p.projguid in ( @var_projguid )
and  FORMAT(ovr.ReviewDate, 'MM') in (@var_month)
ORDER BY bu.BUName,
         p.ProjName,
         a.BldName,
         ovr.ReviewDate DESC