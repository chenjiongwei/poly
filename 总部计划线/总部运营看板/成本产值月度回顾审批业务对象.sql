SELECT b.ProjName AS [项目分期名称],cb_OutputValueMonthReview.ReviewDate AS [回顾日期],
       cb_OutputValueMonthReview.CreateOn AS [填表人],
       cb_OutputValueMonthReview.ApproveState AS [审核状态],
       cb_OutputValueMonthReview.Approver AS [审核人],
       cb_OutputValueMonthReview.ApproveDate AS [审核日期],
       cb_OutputValueMonthReview.BuildTotalArea AS [总建筑面积],
       cb_OutputValueMonthReview.StartWorkArea AS [已开工面积],
       cb_OutputValueMonthReview.ShutDownArea AS [停工缓建面积],
       cb_OutputValueMonthReview.TotalOutputValue AS [总产值],
       cb_OutputValueMonthReview.YfsOutputValue AS [已发生产值],
       cb_OutputValueMonthReview.DfsOutputValue AS [待发生产值],
       cb_OutputValueMonthReview.LjyfAmount AS [累计应付款],
       cb_OutputValueMonthReview.LjsfAmount AS [累计实付款],
       cb_OutputValueMonthReview.BnljsfAmount AS [本年累计实付款],
       cb_OutputValueMonthReview.YfwfAmount AS [应付未付金额],
       cb_OutputValueMonthReview.YdczwfAmount AS [已达产值未付金额],
       cb_OutputValueMonthReview.XyyfzfAmount AS [下月预估支付金额],
       cb_OutputValueMonthReview.Ndzjjh AS [年度资金计划],
       ISNULL(cb_OutputValueMonthReview.Ndzjjh,0) - ISNULL(cb_OutputValueMonthReview.BnljsfAmount,0) AS [本年预估剩余支付金额],      
       cb_OutputValueMonthReview.OutputValueMonthReviewName AS [回顾名称],
       cb_OutputValueMonthReview.ProjGUID AS [分期GUID]
FROM dbo.cb_OutputValueMonthReview
 LEFT JOIN dbo.p_Project b
        ON b.ProjGUID = dbo.cb_OutputValueMonthReview.ProjGUID 
    WHERE cb_OutputValueMonthReview.OutputValueMonthReviewGUID = [业务GUID]