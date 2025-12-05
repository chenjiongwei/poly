USE [dss]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_F076项目运营情况跟进表]    Script Date: 2025/12/2 18:01:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[usp_s_F076项目运营情况跟进表]
(
    @var_buguid VARCHAR(MAX),
    -- @var_edate VARCHAR(200),
    @Date DATETIME = NULL,
    @VersionGUID VARCHAR(40) = '',
    @IsNew INT = 0
)

/*
运行样例：[usp_s_F076项目运营情况跟进表] 'BFAB07FD-3BE5-4543-BA33-81C07DE6A5EC'

modify by lintx 2025-01-17
将盈利规划的除地价外直投改成含税口径
*/


AS
BEGIN

    IF @VersionGUID = '默认值'
       OR @VersionGUID = '00000000-0000-0000-0000-000000000000'
    BEGIN
        SET @VersionGUID = NULL;
    END;

    --判断查询日期，是否存在拍照数据，如果存在，则获取拍照版本表中的版本数据，不存在则实收获取
    IF (ISNULL(@VersionGUID, '') <> '' AND @IsNew = 0)
    BEGIN
        SELECT [VersionGUID],
               [项目代码],
               [项目投管编码],
               [平台公司GUID],
               [平台公司名称],
               [城市],
               [地块名],
               [项目GUID],
               [项目名称],
               [项目推广名称],
               [项目获取方式],
               [总地价],
               [股权溢价],
               [其中取得价],
               [可售楼面价],
               [获取时间],
               [股权结构],
               [股权比例],
               [操盘方],
               [操盘条线],
               [并表方],
               [占地面积],
               [容积率],
               [计容建筑面积],
               [立项地上可售面积],
               [立项住宅可售面积],
               [立项商办可售面积],
               [立项销售车位个数],
               [地上可售面积合计],
               [住宅可售面积],
               [商办可售面积],
               [销售车位个数],
               [总建筑面积],
               [累计开工面积],
               [地上开工面积],
               [累计竣工面积],
               [地上竣工面积],
               [目前在建面积],
               [地上剩余可售面积],
               [住宅剩余可售套数],
               [住宅剩余可售面积],
               [住宅剩余可售面积占压权益地价],
               [住宅剩余可售面积占压权益建安],
               [住宅剩余可售面积未开工],
               [住宅剩余可售面积已开工未达预售形象],
               [住宅剩余可售面积已达预售形象未售],
               [住宅剩余可售面积产成品],
               [商办剩余可售套数],
               [商办剩余可售面积],
               [商办剩余可售面积占压权益地价],
               [商办剩余可售面积占压权益建安],
               [商办剩余可售面积未开工],
               [商办剩余可售面积已开工未达预售形象],
               [商办剩余可售面积已达预售形象未售],
               [商办剩余可售面积产成品],
               [车位剩余可售个数],
               [车位剩余可售面积占压权益地价],
               [车位剩余可售面积占压权益建安],
               [车位剩余可售个数未开工],
               [车位剩余可售个数已开工未达预售形象],
               [车位剩余可售个数已达预售形象未售],
               [车位剩余可售个数产成品],
               [总货值],
               [已售货值],
               [住宅已售货值],
               [商办已售货值],
               [车位已售货值],
               [剩余货值],
               [住宅剩余货值],
               [住宅剩余货值未开工],
               [住宅剩余货值已开工未达预售形象],
               [住宅剩余货值已达预售形象未售],
               [住宅剩余货值产成品],
               [商办剩余货值],
               [商办剩余货值未开工],
               [商办剩余货值已开工未达预售形象],
               [商办剩余货值已达预售形象未售],
               [商办剩余货值产成品],
               [车位剩余货值],
               [车位剩余货值未开工],
               [车位剩余货值已开工未达预售形象],
               [车位剩余货值已达预售形象未售],
               [车位剩余货值产成品],
               [项目首开时间],
               [累计推售金额],
               [累计认购金额],
               [累计推售套数],
               [累计认购套数],
               [累计套数去化率],
               [立项签约均价],
               [动态签约均价],
               [本年签约均价全口径],
               [上三个月签约均价全口径],
               [上两个月签约均价全口径],
               [上一个月签约均价全口径],
               [近三月月均签约均价],
               [当月签约均价全口径],
               [近三月月均签约套数],
               [车位签约套数],
               [上三个月签约套数],
               [上两个月签约套数],
               [上一个月签约套数],
               [当月签约套数],
               [近三月月均签约面积全口径],
               [车位签约面积全口径],
               [上三个月签约面积全口径],
               [上两个月签约面积全口径],
               [上一个月签约面积全口径],
               [当月签约面积全口径],
               [近三月月均签约金额全口径],
               [车位签约金额全口径],
               [上三个月签约金额全口径],
               [上两个月签约金额全口径],
               [上一个月签约金额全口径],
               [当月签约金额全口径],
               [累计回笼金额],
               [累计总投资金额],
               [累计建安费用],
               [累计经营性现金流],
               [累计权益经营性现金流],
               [开发贷款余额],
               [供应链融资余额],
               [股东投入余额],
               [我司投入余额],
               [合作方投入余额],
               [立项税前成本利润率],
               [立项税前利润],
               [立项含税总投资],
               [立项除地价外直投],
               [立项财务费用],
               [立项营销费用],
               [立项管理费用],
               [立项税后利润],
               [立项税后净现金],
               [立项固定资产],
               [立项全投资IRR],
               [立项税前成本利润率_我方],
               [立项税前利润_我方],
               [立项含税总投资_我方],
               [立项除地价外直投_我方],
               [立项财务费用_我方],
               [立项营销费用_我方],
               [立项管理费用_我方],
               [立项税后利润_我方],
               [立项税后净现金_我方],
               [立项固定资产_我方],
               [立项全投资IRR_我方],
               [税前成本利润率_计划口径],
               [税前利润计划口径],
               [总成本含税计划口径],
               [除地价外直投不含税_财务分摊],
               [财务费用计划口径],
               [营销费用],
               [综合管理费协议口径],
               [税后利润计划口径],
               [税后净现金计划口径],
               [固定资产计划口径],
               [全投资IRR计划口径],
               [股东税前成本利润率_计划口径],
               [股东税前利润计划口径],
               [股东总成本含税计划口径],
               [股东除地价外直投不含税_财务分摊],
               [股东财务费用计划口径],
               [股东营销费用],
               [股东综合管理费协议口径],
               [股东税后利润计划口径],
               [股东税后净现金计划口径],
               [股东固定资产计划口径],
               [股东全投资IRR计划口径],
               [税前成本利润率_账面口径],
               [税前利润账面口径],
               [总成本含税账面口径],
               [除地价外直投不含税_财务分摊账面口径],
               [财务费用账面口径],
               [营销费用账面口径],
               [综合管理费协议口径_账面口径],
               [税后利润账面口径],
               [税后净现金账面口径],
               [固定资产账面口径],
               [全投资IRR账面],
               [股东税前成本利润率_账面口径],
               [股东税前利润账面口径],
               [股东总成本含税账面口径],
               [股东除地价外直投不含税_财务分摊账面口径],
               [股东财务费用账面口径],
               [股东营销费用账面口径],
               [股东综合管理费协议口径_账面口径],
               [股东税后利润账面口径],
               [股东税后净现金账面口径],
               [股东固定资产账面口径],
               [股东全投资IRR账面],
               [立项实际开工时间],
               [立项首开时间],
               [立项全投资现金流回正时间],
               [立项首期竣备时间],
               [动态实际开工时间最早完成日期],
               [动态首开时间],
               [动态全投资现金流回正],
               [动态竣工备案最早完成日期],
               [累计税金],
               [运行时间],
               是否录入合作业绩,
               盈利规划版本信息,
               开盘一个月推货套数,
               开盘一个月推货面积,
               开盘一个月推货金额,
               首开均价,
			   立项承诺首年签约,
			   立项承诺次年签约,
			   动态情况首年签约,
			   动态情况次年签约,
               除地价外直投含税,
               除地价外直投含税单方,
               除地价外直投含税_账面口径,
               股东除地价外直投含税,
               股东除地价外直投含税_账面口径
        FROM [nmap_s_F076项目运营情况跟进表]
        WHERE VersionGuid = @VersionGUID
              AND 平台公司guid IN (
                                  SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
                              );
    END;

    ELSE
    BEGIN
        SET NOCOUNT ON;
        SET @VersionGUID = NEWID();

        WITH lxlr
        AS (SELECT lxlr.项目guid,
                   SUM(ISNULL(lxlr.立项地上可售面积, 0)) AS 立项地上可售面积,
                   SUM(ISNULL(lxlr.立项住宅可售面积, 0)) AS 立项住宅可售面积,
                   SUM(ISNULL(lxlr.立项商办可售面积, 0)) AS 立项商办可售面积,
                   SUM(ISNULL(lxlr.立项销售车位个数, 0)) AS 立项销售车位个数,
                   立项产品预计售价 = STUFF(
                              (
                                  SELECT CHAR(10) + lx1.立项产品预计售价
                                  FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_qt_LxDwProfit_yt lx1
                                  WHERE lx1.项目guid = lxlr.项目guid
                                        AND lx1.立项产品预计售价 IS NOT NULL
                                        AND lx1.是否可售 = '是'
                                  ORDER BY CHARINDEX('住宅', 产品类型) DESC,
                                           CHARINDEX('公寓', 产品类型) DESC,
                                           CHARINDEX('别墅', 产品类型) DESC,
                                           CHARINDEX('地下室/车库', 产品类型)
                                  FOR XML PATH('')
                              ),
                              1,
                              1,
                              ''
                                   )
            FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_qt_LxDwProfit_yt lxlr
            GROUP BY 项目guid),
             lx
        AS (SELECT yt.ProjGUID AS 项目guid,
                   PreTaxCostProfitRate 立项税前成本利润率,
                   BeforeProfit 立项税前利润,
                   TotalInvestmentTax 立项含税总投资,
                   除地价外直投 立项除地价外直投,
                   CwExpenses 立项财务费用,
                   YxExpenses 立项营销费用,
                   GlExpenses 立项管理费用,
                   AfterTaxProfit 立项税后利润,
                   CashProfit 立项税后净现金,
                   FixedAssetsOne 立项固定资产,
                   QTZIRR 立项全投资IRR,
                   --我方,增加容错，如果为空或者为0，则项目层级的*权益比例
                   PreTaxCostProfitRateBL 立项税前成本利润率_我方,
                   CASE
                       WHEN ISNULL(BeforeProfitBL, 0) = 0 THEN
                            BeforeProfit * EquityRatio / 100.0
                       ELSE BeforeProfitBL
                   END 立项税前利润_我方,
                   CASE
                       WHEN ISNULL(TotalInvestmentTaxBL, 0) = 0 THEN
                            TotalInvestmentTax * EquityRatio / 100.0
                       ELSE TotalInvestmentTaxBL
                   END 立项含税总投资_我方,
                   CASE
                       WHEN ISNULL(JaInvestMenstAmountBL, 0) = 0 THEN
                            除地价外直投 * EquityRatio / 100.0
                       ELSE JaInvestMenstAmountBL
                   END 立项除地价外直投_我方,
                   CASE
                       WHEN ISNULL(CwExpensesBL, 0) = 0 THEN
                            CwExpenses * EquityRatio / 100.0
                       ELSE CwExpensesBL
                   END 立项财务费用_我方,
                   CASE
                       WHEN ISNULL(YxExpensesBL, 0) = 0 THEN
                            YxExpensesBL * EquityRatio / 100.0
                       ELSE YxExpensesBL
                   END 立项营销费用_我方,
                   CASE
                       WHEN ISNULL(GlExpensesBL, 0) = 0 THEN
                            GlExpenses * EquityRatio / 100.0
                       ELSE GlExpensesBL
                   END 立项管理费用_我方,
                   CASE
                       WHEN ISNULL(AfterTaxProfitBL, 0) = 0 THEN
                            AfterTaxProfit * EquityRatio / 100.0
                       ELSE AfterTaxProfitBL
                   END 立项税后利润_我方,
                   CASE
                       WHEN ISNULL(CashProfitBL, 0) = 0 THEN
                            CashProfit * EquityRatio / 100.0
                       ELSE CashProfitBL
                   END 立项税后净现金_我方,
                   CASE
                       WHEN ISNULL(FixedAssetsOneBL, 0) = 0 THEN
                            FixedAssetsOne * EquityRatio / 100.0
                       ELSE FixedAssetsOneBL
                   END 立项固定资产_我方,
                   QTZIRRBL 立项全投资IRR_我方,
                   --其余
                   FactBeginDate AS 立项实际开工时间,
                   FirstOpenDate AS 立项首开时间,
                   QtzXjlhzDate AS 立项全投资现金流回正时间,
                   SqfinishDate AS 立项首期竣备时间
            FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_ys_SumOperatingProfitDataLXDWBfYt yt
                 INNER JOIN [172.16.4.161].highdata_prod.dbo.data_wide_dws_mdm_Project p ON p.projguid = yt.projguid
            WHERE EditonType = '立项版'),
             Area
        AS (SELECT pj.项目GUID,
                   CASE
                       WHEN (ISNULL(pj.计容可售面积, 0) + ISNULL(pj.自持面积, 0)) = 0 THEN
                            0
                       ELSE ((ISNULL(hz.住宅剩余可售面积, 0)) / (ISNULL(pj.计容可售面积, 0) + ISNULL(pj.自持面积, 0)))
                   END AS 住宅面积占比,
                   CASE
                       WHEN (ISNULL(pj.计容可售面积, 0) + ISNULL(pj.自持面积, 0)) = 0 THEN
                            0
                       ELSE ((ISNULL(hz.商办剩余可售面积, 0)) / (ISNULL(pj.计容可售面积, 0) + ISNULL(pj.自持面积, 0)))
                   END AS 商办面积占比,
                   CASE
                       WHEN (ISNULL(pj.计容可售面积, 0) + ISNULL(pj.自持面积, 0)) = 0 THEN
                            0
                       ELSE ((ISNULL(hz.车位剩余可售面积, 0)) / (ISNULL(pj.计容可售面积, 0) + ISNULL(pj.自持面积, 0)))
                   END AS 车位面积占比,
                   CASE
                       WHEN (ISNULL(pj.累计开工可售面积, 0) + ISNULL(pj.累计开工自持面积, 0)) = 0 THEN
                            0
                       ELSE
                   ((ISNULL(hz.住宅剩余可售面积, 0) - ISNULL(hz.住宅剩余可售面积未开工, 0))
                    / (ISNULL(pj.累计开工可售面积, 0) + ISNULL(pj.累计开工自持面积, 0))
                   )
                   END AS 住宅开工面积占比,
                   CASE
                       WHEN (ISNULL(pj.累计开工可售面积, 0) + ISNULL(pj.累计开工自持面积, 0)) = 0 THEN
                            0
                       ELSE
                   ((ISNULL(hz.商办剩余可售面积, 0) - ISNULL(hz.商办剩余可售面积未开工, 0))
                    / (ISNULL(pj.累计开工可售面积, 0) + ISNULL(pj.累计开工自持面积, 0))
                   )
                   END AS 商办开工面积占比,
                   CASE
                       WHEN (ISNULL(pj.累计开工可售面积, 0) + ISNULL(pj.累计开工自持面积, 0)) = 0 THEN
                            0
                       ELSE
                   ((ISNULL(hz.车位剩余可售面积, 0) - ISNULL(hz.车位剩余可售面积未开工, 0))
                    / (ISNULL(pj.累计开工可售面积, 0) + ISNULL(pj.累计开工自持面积, 0))
                   )
                   END AS 车位开工面积占比
            FROM [172.16.4.161].highdata_prod.dbo.dw_d_TopProject pj
                 INNER JOIN [172.16.4.161].highdata_prod.dbo.dw_f_TopProject_SaleValue hz ON pj.项目GUID = hz.项目GUID),
		立项承诺首年签约 AS
		( SELECT a.projguid,
				 b.SjkgDate 实际开工时间,
				 b.SqjgDate 首期竣工时间,
				 b.SqjzDate 首期结转时间,
				 b.SckpDate 首次开盘时间,
				 a.saleJE/10000 立项承诺首年签约
		  FROM  [ERP25].[dbo].mdm_ProjectXJLIndex a
		  inner join [ERP25].[dbo].mdm_ProjectNodeIndex b ON b.ProjGUID = a.ProjGUID AND YEAR(b.SckpDate) = a.datayear
		  WHERE a.DataType=1
		),
		立项承诺次年签约 AS
		( SELECT a.projguid,
				 b.SjkgDate 实际开工时间,
				 b.SqjgDate 首期竣工时间,
				 b.SqjzDate 首期结转时间,
				 b.SckpDate 首次开盘时间,
				 a.saleJE/10000 立项承诺次年签约
		  FROM  [ERP25].[dbo].mdm_ProjectXJLIndex a
		  inner join [ERP25].[dbo].mdm_ProjectNodeIndex b ON b.ProjGUID = a.ProjGUID AND YEAR(b.SckpDate)+1 = a.datayear
		  WHERE a.DataType=1
		),
		首开时间 as 
		(
			SELECT	--ISNULL(p1.projguid, p.projguid) projguid,
					pp.projGUID as projGUID,
					MIN(o.qsdate) AS stdate
			FROM [ERP25].[dbo].s_order o
			LEFT JOIN [ERP25].[dbo].s_contract c on o.orderGUID = c.lastSaleGUID
			LEFT JOIN [ERP25].[dbo].p_project p ON o.projguid = p.projguid
			LEFT JOIN [ERP25].[dbo].p_project pp ON p.parentcode = pp.projcode AND pp.applysys LIKE '%0101%'
			WHERE --o.status = '激活' OR o.closereason = '转签约'
					isnull(o.CloseReason,'') in ('','转签约')  and o.Status='激活'
					and (ISNULL(c.Status,'') in ('','激活') or c.CloseReason = '重置认购')
			GROUP BY pp.projGUID
		),
		动态情况首年签约  AS
		(
			SELECT  pp.projGUID,
					SUM(c.jytotal)/100000000 AS 动态情况首年签约
			FROM [ERP25].[dbo].s_contract c
			LEFT JOIN [ERP25].[dbo].s_trade t on t.TradeGUID = c.TradeGUID 
			LEFT JOIN [ERP25].[dbo].p_project p ON c.projguid = p.projguid
			LEFT JOIN [ERP25].[dbo].p_project pp ON p.parentcode = pp.projcode AND pp.applysys LIKE '%0101%'
			INNER JOIN 首开时间 on 首开时间.ProjGUID = pp.projGUID
			WHERE c.status = '激活'
			AND datediff(yy,首开时间.stdate,c.QsDate)=0
			GROUP BY pp.projGUID
		),
		动态情况次年签约  AS
		(
			SELECT  pp.projGUID,
					SUM(c.jytotal)/100000000 AS 动态情况次年签约
			FROM [ERP25].[dbo].s_contract c
			LEFT JOIN [ERP25].[dbo].s_trade t on t.TradeGUID = c.TradeGUID 
			LEFT JOIN [ERP25].[dbo].p_project p ON c.projguid = p.projguid
			LEFT JOIN [ERP25].[dbo].p_project pp ON p.parentcode = pp.projcode AND pp.applysys LIKE '%0101%'
			INNER JOIN 首开时间 on 首开时间.ProjGUID = pp.projGUID
			WHERE c.status = '激活'
			AND datediff(yy,首开时间.stdate,c.QsDate)=1
			GROUP BY pp.projGUID
		)
		
        SELECT @VersionGUID VersionGUID,
                                                                                                            --基础信息
               pj.投管明源系统项目代码 AS 项目代码,
               pj.项目投管编码,
               pj.平台公司GUID,
               pj.平台公司名称,
               pj.城市,
               pj.地块名,
               pj.项目GUID,
               pj.项目名称,
               pj.项目推广名称,
               pj.项目获取方式,
               CONVERT(DECIMAL(16, 4), pj.获取地价 / 100000000.0) AS 总地价,
               CONVERT(DECIMAL(16, 4), pj.股权溢价 / 100000000.0) AS 股权溢价,
               CONVERT(DECIMAL(16, 4), pj.其中取得价 / 100000000.0) AS 其中取得价,
               CONVERT(DECIMAL(16, 4), pj.可售楼面价) 可售楼面价,
               pj.获取时间,
               pj.合作方信息 AS 股权结构,
               pj.财务收益比例 / 100.0 AS 股权比例,
               pj.操盘方式 操盘方,
               pj.操盘条线,
               pj.并表类型 AS 并表方,
               CONVERT(DECIMAL(16, 4), pj.占地面积 / 10000.0) AS 占地面积,
               pj.容积率,
               CONVERT(DECIMAL(16, 4), pj.计容建筑面积 / 10000.0) AS 计容建筑面积,
                                                                                                            --立项可售面积
               CONVERT(DECIMAL(16, 4), lxlr.立项地上可售面积 / 10000.0) AS 立项地上可售面积,
               CONVERT(DECIMAL(16, 4), lxlr.立项住宅可售面积 / 10000.0) AS 立项住宅可售面积,
               CONVERT(DECIMAL(16, 4), lxlr.立项商办可售面积 / 10000.0) AS 立项商办可售面积,
               lxlr.立项销售车位个数,
                                                                                                            --动态可售面积
               CONVERT(DECIMAL(16, 4), (ISNULL(pj.住宅可售面积, 0) + ISNULL(pj.商办可售面积, 0)) / 10000.0) AS 地上可售面积合计,
               CONVERT(DECIMAL(16, 4), pj.住宅可售面积 / 10000.0) AS 住宅可售面积,
               CONVERT(DECIMAL(16, 4), pj.商办可售面积 / 10000.0) AS 商办可售面积,
               pj.销售车位个数,
                                                                                                            --工程情况 
               CONVERT(DECIMAL(16, 4), pj.总建筑面积 / 10000.0) AS 总建筑面积,
               CONVERT(DECIMAL(16, 4), ISNULL(jh.累计开工面积, 0) / 10000.0) AS 累计开工面积,
               CONVERT(DECIMAL(16, 4), ISNULL(jh.地上开工面积, 0) / 10000.0) AS 地上开工面积,
               CONVERT(DECIMAL(16, 4), ISNULL(jh.累计竣工面积, 0) / 10000.0) AS 累计竣工面积,
               CONVERT(DECIMAL(16, 4), ISNULL(jh.地上竣工面积, 0) / 10000.0) AS 地上竣工面积,
               CONVERT(DECIMAL(16, 4), ISNULL(jh.目前在建面积, 0) / 10000.0) AS 目前在建面积,
                                                                                                            --资源结构                                        
               CONVERT(DECIMAL(16, 4), 地上剩余可售面积 / 10000.0) AS 地上剩余可售面积,
               住宅剩余可售套数,
               CONVERT(DECIMAL(16, 4), 住宅剩余可售面积 / 10000.0) AS 住宅剩余可售面积,
                                                                                                            --convert(decimal(16,4),hz.住宅面积占比 * ylgh.土地款不含税单方_财务分摊 * pj.权益比例 / 100) AS 住宅剩余可售面积占压权益地价, --业态待售面积/(总可售面积+自持面积)*单方*项目权益比例
               CONVERT(DECIMAL(16, 4), 住宅剩余可售面积 * ylgh.住宅土地款不含税单方_财务分摊 * pj.权益比例 / 100 / 100000000.0) AS 住宅剩余可售面积占压权益地价,
                                                                                                            -- convert(decimal(16,4),fill.累计建安费用 * 住宅开工面积占比 * 住宅总投资占比) AS 住宅剩余可售面积占压权益建安,               --累计建安成本*（业态剩余可售面积/累计开工的可售+自持面积）*（业态总投资含税计划口径/项目总投资含税计划口径）
               CONVERT(DECIMAL(16, 4), fill.累计建安费用 * 住宅开工面积占比 * pj.权益比例 / 100 / 10000.0) AS 住宅剩余可售面积占压权益建安, --累计建安成本*（业态开工剩余可售面积/累计开工的可售+自持面积）*项目权益比例
               CONVERT(DECIMAL(16, 4), 住宅剩余可售面积未开工 / 10000.0) AS 住宅剩余可售面积未开工,
               CONVERT(   DECIMAL(16, 4),
                          (CASE
                               WHEN nc.projguid IS NOT NULL THEN
                                    住宅剩余可售面积
                               ELSE 住宅剩余可售面积已开工未达预售形象_未完工
                           END
                          ) / 10000.0
                      ) AS 住宅剩余可售面积已开工未达预售形象,
               CONVERT(DECIMAL(16, 4), 住宅剩余可售面积已达预售形象未售_未完工 / 10000.0) AS 住宅剩余可售面积已达预售形象未售,
               CONVERT(DECIMAL(16, 4), 住宅剩余可售面积产成品 / 10000.0) AS 住宅剩余可售面积产成品,
               商办剩余可售套数,
               CONVERT(DECIMAL(16, 4), 商办剩余可售面积 / 10000.0) AS 商办剩余可售面积,
               CONVERT(DECIMAL(16, 4), 商办剩余可售面积 * ylgh.商办土地款不含税单方_财务分摊 * pj.权益比例 / 100 / 100000000.0) AS 商办剩余可售面积占压权益地价,
               CONVERT(DECIMAL(16, 4), fill.累计建安费用 * 商办开工面积占比 * pj.权益比例 / 100 / 10000.0) AS 商办剩余可售面积占压权益建安,
               CONVERT(DECIMAL(16, 4), 商办剩余可售面积未开工 / 10000.0) AS 商办剩余可售面积未开工,
               CONVERT(   DECIMAL(16, 4),
                          (CASE
                               WHEN nc.projguid IS NOT NULL THEN
                                    商办剩余可售面积
                               ELSE 商办剩余可售面积已开工未达预售形象_未完工
                           END
                          ) / 10000.0
                      ) AS 商办剩余可售面积已开工未达预售形象,
               CONVERT(DECIMAL(16, 4), 商办剩余可售面积已达预售形象未售_未完工 / 10000.0) AS 商办剩余可售面积已达预售形象未售,
               CONVERT(DECIMAL(16, 4), 商办剩余可售面积产成品 / 10000.0) AS 商办剩余可售面积产成品,
               车位剩余可售个数,
               CONVERT(DECIMAL(16, 4), 车位剩余可售面积 * ylgh.车位土地款不含税单方_财务分摊 * pj.权益比例 / 100 / 100000000.0) AS 车位剩余可售面积占压权益地价,
               CONVERT(DECIMAL(16, 4), fill.累计建安费用 * 车位开工面积占比 * pj.权益比例 / 100 / 10000.0) AS 车位剩余可售面积占压权益建安,
               车位剩余可售个数未开工,
               (CASE
                    WHEN nc.projguid IS NOT NULL THEN
                         车位剩余可售个数
                    ELSE 车位剩余可售个数已开工未达预售形象_未完工
                END
               ) 车位剩余可售个数已开工未达预售形象,
               车位剩余可售个数已达预售形象未售_未完工 AS 车位剩余可售个数已达预售形象未售,
               车位剩余可售个数产成品,
               CONVERT(DECIMAL(16, 4), 动态总货值金额 / 100000000.0) AS 总货值,
               CONVERT(DECIMAL(16, 4), 已售金额 / 100000000.0) AS 已售货值,
               CONVERT(DECIMAL(16, 4), 住宅已售货值 / 100000000.0) AS 住宅已售货值,
               CONVERT(DECIMAL(16, 4), 商办已售货值 / 100000000.0) AS 商办已售货值,
               CONVERT(DECIMAL(16, 4), 车位已售货值 / 100000000.0) AS 车位已售货值,
               CONVERT(DECIMAL(16, 4), 动态未售货值金额 / 100000000.0) AS 剩余货值,
               CONVERT(DECIMAL(16, 4), 住宅剩余货值 / 100000000.0) AS 住宅剩余货值,
               CONVERT(DECIMAL(16, 4), 住宅剩余货值未开工 / 100000000.0) AS 住宅剩余货值未开工,
               CONVERT(   DECIMAL(16, 4),
                          (CASE
                               WHEN nc.projguid IS NOT NULL THEN
                                    住宅剩余货值
                               ELSE 住宅剩余货值已开工未达预售形象_未完工
                           END
                          ) / 100000000.0
                      ) AS 住宅剩余货值已开工未达预售形象,
               CONVERT(DECIMAL(16, 4), 住宅剩余货值已达预售形象未售_未完工 / 100000000.0) AS 住宅剩余货值已达预售形象未售,
               CONVERT(DECIMAL(16, 4), 住宅剩余货值产成品 / 100000000.0) AS 住宅剩余货值产成品,
               CONVERT(DECIMAL(16, 4), 商办剩余货值 / 100000000.0) AS 商办剩余货值,
               CONVERT(DECIMAL(16, 4), 商办剩余货值未开工 / 100000000.0) AS 商办剩余货值未开工,
               CONVERT(   DECIMAL(16, 4),
                          (CASE
                               WHEN nc.projguid IS NOT NULL THEN
                                    商办剩余货值
                               ELSE 商办剩余货值已开工未达预售形象_未完工
                           END
                          ) / 100000000.0
                      ) AS 商办剩余货值已开工未达预售形象,
               CONVERT(DECIMAL(16, 4), 商办剩余货值已达预售形象未售_未完工 / 100000000.0) AS 商办剩余货值已达预售形象未售,
               CONVERT(DECIMAL(16, 4), 商办剩余货值产成品 / 100000000.0) AS 商办剩余货值产成品,
               CONVERT(DECIMAL(16, 4), 车位剩余货值 / 100000000.0) AS 车位剩余货值,
               CONVERT(DECIMAL(16, 4), 车位剩余货值未开工 / 100000000.0) AS 车位剩余货值未开工,
               CONVERT(   DECIMAL(16, 4),
                          (CASE
                               WHEN nc.projguid IS NOT NULL THEN
                                    车位剩余货值
                               ELSE 车位剩余货值已开工未达预售形象_未完工
                           END
                          ) / 100000000.0
                      ) AS 车位剩余货值已开工未达预售形象,
               CONVERT(DECIMAL(16, 4), 车位剩余货值已达预售形象未售_未完工 / 100000000.0) AS 车位剩余货值已达预售形象未售,
               CONVERT(DECIMAL(16, 4), 车位剩余货值产成品 / 100000000.0) AS 车位剩余货值产成品,
                                                                                                            --实际首开情况
               项目房间首次开盘时间 项目首开时间,
               开盘一个月推货金额 / 100000000.0 累计推售金额,
               开盘一个月认购金额 / 100000000.0 累计认购金额,
               开盘一个月推货套数 累计推售套数,
               开盘一个月认购套数 累计认购套数,
               CASE
                   WHEN 开盘一个月推货套数 = 0 THEN
                        0
                   ELSE 开盘一个月认购套数 * 1.0 / 开盘一个月推货套数
               END 累计套数去化率,
                                                                                                            --销售签约情况 
               lxlr.立项产品预计售价 AS 立项签约均价,
               产品累计签约均价 AS 动态签约均价,
               产品本年签约均价 AS 本年签约均价全口径,
               产品上三个月签约均价 上三个月签约均价全口径,
               产品上两个月签约均价 上两个月签约均价全口径,
               产品上一个月签约均价 上一个月签约均价全口径,
               产品近三月月均签约均价 近三月月均签约均价,
               产品本月签约均价 当月签约均价全口径,
               近三月月均签约套数 - 车位近三月月均签约套数 近三月月均签约套数,
               车位近三月月均签约套数 车位签约套数,
               上三个月签约套数 - 车位上三个月签约套数 上三个月签约套数,
               上两个月签约套数 - 车位上两个月签约套数 上两个月签约套数,
               上一个月签约套数 - 车位上一个月签约套数 上一个月签约套数,
               本月签约套数全口径 - 本月车位签约套数 AS 当月签约套数,
               CONVERT(DECIMAL(16, 4), 近三月月均签约面积全口径 / 10000.0) AS 近三月月均签约面积全口径,
               CONVERT(DECIMAL(16, 4), 车位近三月月均签约面积 / 10000.0) AS 车位签约面积全口径,
               CONVERT(DECIMAL(16, 4), 上三个月签约面积全口径 / 10000.0) AS 上三个月签约面积全口径,
               CONVERT(DECIMAL(16, 4), 上两个月签约面积全口径 / 10000.0) AS 上两个月签约面积全口径,
               CONVERT(DECIMAL(16, 4), 上一个月签约面积全口径 / 10000.0) AS 上一个月签约面积全口径,
               CONVERT(DECIMAL(16, 4), 本月签约面积全口径 / 10000.0) AS 当月签约面积全口径,
               CONVERT(DECIMAL(16, 4), 近三月月均签约金额全口径 / 100000000.0) AS 近三月月均签约金额全口径,
               CONVERT(DECIMAL(16, 4), 车位近三月月均签约金额 / 100000000.0) AS 车位签约金额全口径,
               CONVERT(DECIMAL(16, 4), 上三个月签约金额全口径 / 100000000.0) AS 上三个月签约金额全口径,
               CONVERT(DECIMAL(16, 4), 上两个月签约金额全口径 / 100000000.0) AS 上两个月签约金额全口径,
               CONVERT(DECIMAL(16, 4), 上一个月签约金额全口径 / 100000000.0) AS 上一个月签约金额全口径,
               CONVERT(DECIMAL(16, 4), 本月签约金额全口径 / 100000000.0) AS 当月签约金额全口径,
                                                                                                            --现金流
               CONVERT(DECIMAL(16, 4), fill.累计回笼金额 / 10000.0) AS 累计回笼金额,
               CONVERT(DECIMAL(16, 4), fill.累计总投资金额 / 10000.0) AS 累计总投资金额,
               CONVERT(DECIMAL(16, 4), fill.累计建安费用 / 10000.0) AS 累计建安费用,
               CONVERT(DECIMAL(16, 4), fill.累计经营性现金流 / 10000.0) AS 累计经营性现金流,
               CONVERT(DECIMAL(16, 4), fill.累计权益经营性现金流 / 10000.0) AS 累计权益经营性现金流,
               CONVERT(DECIMAL(16, 4), fill.开发贷款余额 / 10000.0) AS 开发贷款余额,
               CONVERT(DECIMAL(16, 4), fill.供应链融资余额 / 10000.0) AS 供应链融资余额,
               NULL 股东投入余额,                                                                                 --留空
               NULL 我司投入余额,                                                                                 --留空
               NULL 合作方投入余额,                                                                                --留空 
                                                                                                            --立项盈利情况（计划、项目）
               lx.立项税前成本利润率,
               CONVERT(DECIMAL(16, 4), lx.立项税前利润 / 100000000.0) 立项税前利润,
               CONVERT(DECIMAL(16, 4), lx.立项含税总投资 / 100000000.0) 立项含税总投资,
               CONVERT(DECIMAL(16, 4), lx.立项除地价外直投 / 100000000.0) 立项除地价外直投,
               CONVERT(DECIMAL(16, 4), lx.立项财务费用 / 100000000.0) AS 立项财务费用,
               CONVERT(DECIMAL(16, 4), lx.立项营销费用 / 100000000.0) AS 立项营销费用,
               CONVERT(DECIMAL(16, 4), lx.立项管理费用 / 100000000.0) AS 立项管理费用,
               CONVERT(DECIMAL(16, 4), lx.立项税后利润 / 100000000.0) AS 立项税后利润,
               CONVERT(DECIMAL(16, 4), lx.立项税后净现金 / 100000000.0) AS 立项税后净现金,
               CONVERT(DECIMAL(16, 4), lx.立项固定资产 / 100000000.0) AS 立项固定资产,
               lx.立项全投资IRR,
                                                                                                            --立项盈利情况（计划、股东）
               CASE
                   WHEN 立项含税总投资_我方 = 0 THEN
                        0
                   ELSE 立项税前利润_我方 / 立项含税总投资_我方
               END 立项税前成本利润率_我方,
               CONVERT(DECIMAL(16, 4), lx.立项税前利润_我方 / 100000000.0) AS 立项税前利润_我方,
               CONVERT(DECIMAL(16, 4), lx.立项含税总投资_我方 / 100000000.0) AS 立项含税总投资_我方,
               CONVERT(DECIMAL(16, 4), lx.立项除地价外直投_我方 / 100000000.0) AS 立项除地价外直投_我方,
               CONVERT(DECIMAL(16, 4), lx.立项财务费用_我方 / 100000000.0) AS 立项财务费用_我方,
               CONVERT(DECIMAL(16, 4), lx.立项营销费用_我方 / 100000000.0) AS 立项营销费用_我方,
               CONVERT(DECIMAL(16, 4), lx.立项管理费用_我方 / 100000000.0) AS 立项管理费用_我方,
               CONVERT(DECIMAL(16, 4), lx.立项税后利润_我方 / 100000000.0) AS 立项税后利润_我方,
               CONVERT(DECIMAL(16, 4), lx.立项税后净现金_我方 / 100000000.0) AS 立项税后净现金_我方,
               CONVERT(DECIMAL(16, 4), lx.立项固定资产_我方 / 100000000.0) AS 立项固定资产_我方,
               lx.立项全投资IRR_我方,
                                                                                                            --动态盈利情况（计划，项目）
               ylgh.税前成本利润率_计划口径,
               CONVERT(DECIMAL(16, 4), ylgh.税前利润计划口径 / 100000000.0) AS 税前利润计划口径,
               CONVERT(DECIMAL(16, 4), ylgh.总成本含税计划口径 / 100000000.0) AS 总成本含税计划口径,
               CONVERT(DECIMAL(16, 4), ylgh.除地价外直投含税 / 100000000.0) AS 除地价外直投不含税_财务分摊,
               CONVERT(DECIMAL(16, 4), ylgh.财务费用计划口径 / 100000000.0) AS 财务费用计划口径,
               CONVERT(DECIMAL(16, 4), ylgh.营销费用 / 100000000.0) AS 营销费用,
               CONVERT(DECIMAL(16, 4), ylgh.综合管理费协议口径 / 100000000.0) AS 综合管理费协议口径,
               CONVERT(DECIMAL(16, 4), ylgh.税后利润计划口径 / 100000000.0) AS 税后利润计划口径,
               CONVERT(DECIMAL(16, 4), ylgh.税后净现金计划口径 / 100000000.0) AS 税后净现金计划口径,                          --税前利润计划 - 累计结转成本
               CONVERT(DECIMAL(16, 4), ylgh.固定资产计划口径 / 100000000.0) AS 固定资产计划口径,
               ylgh.全投资IRR计划口径,
                                                                                                            --动态盈利情况（计划，股东）
               ylgh.股东税前成本利润率_计划口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东税前利润计划口径 / 100000000.0) AS 股东税前利润计划口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东总成本含税计划口径 / 100000000.0) AS 股东总成本含税计划口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东除地价外直投含税 / 100000000.0) AS 股东除地价外直投不含税_财务分摊,
               CONVERT(DECIMAL(16, 4), ylgh.股东财务费用计划口径 / 100000000.0) AS 股东财务费用计划口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东营销费用 / 100000000.0) AS 股东营销费用,
               CONVERT(DECIMAL(16, 4), ylgh.股东综合管理费协议口径 / 100000000.0) AS 股东综合管理费协议口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东税后利润计划口径 / 100000000.0) AS 股东税后利润计划口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东税后净现金计划口径 / 100000000.0) AS 股东税后净现金计划口径,                      --税前利润计划 - 累计结转成本
               CONVERT(DECIMAL(16, 4), ylgh.股东固定资产计划口径 / 100000000.0) AS 股东固定资产计划口径,
               ylgh.股东全投资IRR计划口径,
                                                                                                            --动态盈利情况（财务，项目）
               ylgh.税前成本利润率_账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.税前利润账面口径 / 100000000.0) AS 税前利润账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.总成本含税账面口径 / 100000000.0) AS 总成本含税账面口径,                          --等于含税总投资计划- 财务
               CONVERT(DECIMAL(16, 4), ylgh.除地价外直投含税_账面口径 / 100000000.0) AS 除地价外直投不含税_财务分摊账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.财务费用账面口径 / 100000000.0) AS 财务费用账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.营销费用账面口径 / 100000000.0) AS 营销费用账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.综合管理费协议口径_账面口径 / 100000000.0) AS 综合管理费协议口径_账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.税后利润账面口径 / 100000000.0) AS 税后利润账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.税后净现金账面口径 / 100000000.0) AS 税后净现金账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.固定资产账面口径 / 100000000.0) AS 固定资产账面口径,
               ylgh.全投资IRR账面,
                                                                                                            --动态盈利情况（财务，股东）
               ylgh.股东税前成本利润率_账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东税前利润账面口径 / 100000000.0) AS 股东税前利润账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东总成本含税账面口径 / 100000000.0) AS 股东总成本含税账面口径,                      --等于含税总投资计划- 财务
               CONVERT(DECIMAL(16, 4), ylgh.股东除地价外直投含税_账面口径 / 100000000.0) AS 股东除地价外直投不含税_财务分摊账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东财务费用账面口径 / 100000000.0) AS 股东财务费用账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东营销费用账面口径 / 100000000.0) AS 股东营销费用账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东综合管理费协议口径_账面口径 / 100000000.0) AS 股东综合管理费协议口径_账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东税后利润账面口径 / 100000000.0) AS 股东税后利润账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东税后净现金账面口径 / 100000000.0) AS 股东税后净现金账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东固定资产账面口径 / 100000000.0) AS 股东固定资产账面口径,
               ylgh.股东全投资IRR账面,
                                                                                                            --立项关键计划节点                                                                  
               lx.立项实际开工时间,
               lx.立项首开时间,
               lx.立项全投资现金流回正时间,
               lx.立项首期竣备时间,
                                                                                                            --动态关键完成时间                            
               jh.实际开工最早完成日期_实际 动态实际开工时间最早完成日期,
               jh.开盘销售最早完成日期_实际 动态首开时间,
               jh.首次现金流回正完成日期_实际 动态全投资现金流回正,
               jh.竣工备案表最早完成日期_实际 动态竣工备案最早完成日期,
               CONVERT(DECIMAL(16, 4), fill.累计税金 / 10000.0) AS 累计税金,
               GETDATE() 运行时间,
               pj.是否录入合作业绩,
               盈利规划版本信息,
                              开盘一个月推货套数,
               开盘一个月推货面积,
               开盘一个月推货金额,
               CASE
                   WHEN 开盘一个月推货面积 > 0 THEN
                        开盘一个月推货金额 / 开盘一个月推货面积
                   ELSE 0
               END 首开均价,
			   lxcnsnqy.立项承诺首年签约,
			   lxcncnqy.立项承诺次年签约,
			   dtqksnqy.动态情况首年签约,
			   dtqkcnqy.动态情况次年签约,
               CONVERT(DECIMAL(16, 4), ylgh.除地价外直投含税 / 100000000.0) AS  除地价外直投含税,
               ylgh.除地价外直投含税单方,
               CONVERT(DECIMAL(16, 4), ylgh.除地价外直投含税_账面口径 / 100000000.0) AS  除地价外直投含税_账面口径,
               CONVERT(DECIMAL(16, 4), ylgh.股东除地价外直投含税 / 100000000.0) AS  股东除地价外直投含税,
               CONVERT(DECIMAL(16, 4), ylgh.股东除地价外直投含税_账面口径 / 100000000.0) AS  股东除地价外直投含税_账面口径
        FROM [172.16.4.161].highdata_prod.dbo.dw_d_TopProject pj
             LEFT JOIN lxlr lxlr ON pj.项目guid = lxlr.项目guid
             LEFT JOIN lx lx ON pj.项目guid = lx.项目guid
             LEFT JOIN [172.16.4.161].highdata_prod.dbo.[dw_f_TopProject_Schedule] jh ON pj.项目guid = jh.项目guid
             LEFT JOIN [172.16.4.161].highdata_prod.dbo.dw_f_TopProj_Filltab_Fact fill ON fill.项目guid = pj.项目guid
             LEFT JOIN [172.16.4.161].highdata_prod.dbo.dw_f_TopProJect_ProfitCost_ylgh ylgh ON ylgh.项目guid = pj.项目guid
             LEFT JOIN [172.16.4.161].highdata_prod.dbo.dw_f_TopProject_SaleValue salevalue ON salevalue.项目guid = pj.项目guid
             LEFT JOIN [172.16.4.161].highdata_prod.dbo.dw_f_TopProjSale sp ON sp.项目guid = pj.项目guid
             LEFT JOIN Area hz ON pj.项目GUID = hz.项目GUID
             LEFT JOIN
             (
                 SELECT projguid,
                        '项目归档源版本为：' + ylghpro.BusinessEdition + ';' + CHAR(10) + '最新落盘版本为：' + ylghpro.edition + ';'
                        + CHAR(10) + '最新落盘时间为：' + ylghpro.VersionDate AS 盈利规划版本信息
                 FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_ys_ProjGUID ylghpro
                 WHERE isbase = 1
                       AND Level = 2
             ) ylghpro ON ylghpro.projguid = pj.项目guid
             --判断合作业绩是否录入到楼栋
             LEFT JOIN
             (
                 SELECT DISTINCT
                        projguid
                 FROM [172.16.4.161].highdata_prod.dbo.data_wide_s_NoControl
                 WHERE IfBuildingYJRL = 0
             ) nc ON pj.项目guid = nc.projguid
			 --关联立项表的指标
			 LEFT JOIN 立项承诺首年签约 lxcnsnqy ON lxcnsnqy.ProjGUID = pj.项目guid
			 LEFT JOIN 立项承诺次年签约 lxcncnqy ON lxcncnqy.ProjGUID = pj.项目guid
			 LEFT JOIN 动态情况首年签约 dtqksnqy ON dtqksnqy.ProjGUID = pj.项目guid
			 LEFT JOIN 动态情况次年签约 dtqkcnqy ON dtqkcnqy.ProjGUID = pj.项目guid
			 -----------------------------
        WHERE pj.平台公司guid IN (
                                 SELECT Value FROM dbo.fn_Split2(@var_buguid, ',')
                             )
        ORDER BY pj.平台公司名称,
                 pj.城市,
                 pj.获取时间;
    END;
END;



