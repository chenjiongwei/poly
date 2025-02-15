-- -- 查询临时表，验证本年签约金额和套数数据是否正确
--  select  sum(isnull(CNetAmount,0))  + sum(isnull(SpecialCNetAmount,0)),
--  sum(isnull(CNetCount,0))  + sum(isnull(SpecialCNetCount,0))
--  from  data_wide_dws_s_SalesPerf  where datediff(yy, StatisticalDate, '2024-12-19') = 0
-- and  ParentProjGUID ='49D1D48B-F10F-E911-80BF-E61F13C57837'

-- select sum(isnull(CNetAmount,0))  + sum(isnull(SpecialCNetAmount,0)) from data_wide_dws_s_SalesPerf  where  datediff(day, StatisticalDate, '2024-12-17') = 0

--记录新增规则(必须配置) 
/*销售交易汇总*/
select 	
org.OrgGUID AS BUGUID,																		--公司GUID
org.OrganizationName AS BUName,																--公司名称
org.OrganizationCode AS BUCode,																--公司编码
p.ParentGUID as ParentProjGUID,																--项目GUID
p.ParentName as ParentProjName,																--项目名称
p.ParentCode as ParentProjCode,																--项目编码
p.ProjGUID,																					--分期GUID
p.ProjName,																					--分期名称
p.ProjCode,																					--分期编码
sb.GCBldGUID,																				--工程楼栋GUID
sb.GCBldName,																				--工程楼栋名称
sb.GCBldCode,																				--工程楼栋编码
sb.BuildingGUID as BldGUID,																	--产品楼栋GUID
sb.BuildingName as BldName,																	--产品楼栋名称
sb.Code as BldCode,																			--产品楼栋编码
sb.TopProductTypeGuid as TopProductTypeGUID,												--一级产品类型GUID
sb.TopProductTypeName as TopProductTypeName,												--一级产品类型名称
sb.TopProductTypeCode as TopProductTypeCode,												--一级产品类型Code
sb.ProductTypeGUID as ProductTypeGUID,														--末级产品类型GUID
sb.ProductTypeName as ProductTypeName,														--末级类型名称
sb.ProductTypeCode as ProductTypeCode,														--末级产品类型编码
tempSum.StatisticalDate as StatisticalDate,													--统计日期
p.RightsRate,																				--权益比例
p.GenreTableType,																			--并表类型
p.DiskType,																					--操盘类型
p.DiskFlag,																					--是否操盘
p.HistoryType,																				--是否历史
sb.FactNotOpen as YszGetDate,																--取证日期
sb.IsLock as IsLock,																		--是否锁定
tempSum.ONetArea,																			--认购面积
tempSum.ONetAmount,																			--认购金额
tempSum.ONetCount,																			--认购套数
(isnull(tempSum.ONetAmount,0) + (case when isnull(tempSum.SpecialONetAmount,0) = 0 then isnull(spp.OCjAmount,0) else tempSum.SpecialONetAmount end)) * p.RightsRate / 100.00 as RightsONetAmount,--认购金额_权益口径（【认购金额】+【认购金额_特殊业绩】）
tempSum.CNetArea,																			--签约面积
tempSum.CNetAmount,																			--签约金额
tempSum.CNetAmountNotTax,																	--签约金额(不含税)
tempSum.CNetCount,																			--签约套数
(isnull(tempSum.CNetAmount,0) + (case when isnull(tempSum.SpecialCNetAmount,0) = 0 then isnull(spp.CCjAmount,0) else tempSum.SpecialCNetAmount end)) * p.RightsRate / 100.00 as RightsCNetAmount,--签约金额_权益口径（【签约金额】+【签约金额_特殊业绩】）
tempSum.SpecialCNetArea,																	--签约面积_特殊业绩
tempSum.SpecialCNetAmount,																	--签约金额_特殊业绩
CASE 
		WHEN tempSum.StatisticalDate<'2016-04-01' THEN 	ISNULL(tempSum.SpecialCNetAmount,0) 
		WHEN tempSum.StatisticalDate>='2016-04-01' AND  tempSum.StatisticalDate<'2018-05-01' THEN 	ISNULL(tempSum.SpecialCNetAmount,0) /(1+0.11)
		WHEN tempSum.StatisticalDate>='2018-05-01' AND  tempSum.StatisticalDate<'2019-04-01' THEN 	ISNULL(tempSum.SpecialCNetAmount,0) /(1+0.10)
		WHEN tempSum.StatisticalDate>='2019-04-01'  THEN 	ISNULL(tempSum.SpecialCNetAmount,0) /(1+0.09)
ELSE 0 END AS SpecialCNetAmountNotTax,														--签约金额不含税_特殊业绩
tempSum.SpecialCNetCount,																	--签约套数_特殊业绩
tempSum.NCCumArea,																			--累计草签面积
tempSum.NCCumAmount,																		--累计草签金额
tempSum.NCCumCount,																			--累计草签套数
tempSum.ICCumArea,																			--累计网签面积
tempSum.ICCumAmount,																		--累计网签金额
tempSum.ICCumCount,																			--累计网签套数
tempr.FangPanArea,																			--推盘面积
tempr.FangPanAmount,																		--推盘金额
tempr.FangPanCount,																	--推盘套数	
tempSum.SpecialCNetArea_1,																	--签约面积_特殊业绩_用于算净利毛利
tempSum.SpecialCNetAmount_1,																--签约金额_特殊业绩_用于算净利毛利
CASE 
		WHEN tempSum.StatisticalDate<'2016-04-01' THEN 	ISNULL(tempSum.SpecialCNetAmount_1,0) 
		WHEN tempSum.StatisticalDate>='2016-04-01' AND  tempSum.StatisticalDate<'2018-05-01' THEN 	ISNULL(tempSum.SpecialCNetAmount_1,0) /(1+0.11)
		WHEN tempSum.StatisticalDate>='2018-05-01' AND  tempSum.StatisticalDate<'2019-04-01' THEN 	ISNULL(tempSum.SpecialCNetAmount_1,0) /(1+0.10)
		WHEN tempSum.StatisticalDate>='2019-04-01'  THEN 	ISNULL(tempSum.SpecialCNetAmount_1,0) /(1+0.09)
ELSE 0 END AS SpecialCNetAmountNotTax_1,
tempSum.SpecialCNetCount_1		,
tempSum.YONetAmount,
tempSum.YONetArea,
tempSum.YONetCount
from 
(
	select 
	tempDisk.BldGUID,																		--产品楼栋GUID
	tempDisk.StatisticalDate,																--统计日期
	SUM(tempDisk.ONetArea) as ONetArea,														--认购面积
	SUM(tempDisk.ONetAmount) as ONetAmount,													--认购金额
	SUM(tempDisk.ONetCount) as ONetCount,													--认购套数
	SUM(tempDisk.CNetArea) as CNetArea,														--签约面积
	SUM(tempDisk.CNetAmount) as CNetAmount,													--签约金额
	SUM(tempDisk.CNetAmountNotTax) as CNetAmountNotTax,													--签约金额(不含税)
	SUM(tempDisk.CNetCount) as CNetCount,													--签约套数
	SUM(tempDisk.SpecialONetAmount) as SpecialONetAmount,									--认购金额_特殊业绩
	SUM(tempDisk.SpecialCNetArea) as SpecialCNetArea,										--签约面积_特殊业绩
	SUM(tempDisk.SpecialCNetAmount) as SpecialCNetAmount,									--签约金额_特殊业绩
	SUM(tempDisk.SpecialCNetCount) as SpecialCNetCount,										--签约套数_特殊业绩
	SUM(tempDisk.NCCumArea) as NCCumArea,													--累计草签面积
	SUM(tempDisk.NCCumAmount) as NCCumAmount,												--累计草签金额
	SUM(tempDisk.NCCumCount) as NCCumCount,													--累计草签套数
	SUM(tempDisk.ICCumArea) as ICCumArea,													--累计网签面积
	SUM(tempDisk.ICCumAmount) as ICCumAmount,												--累计网签金额
	SUM(tempDisk.ICCumCount) as ICCumCount,													--累计网签套数
    SUM(tempDisk.SpecialCNetArea_1) as SpecialCNetArea_1,										--签约面积_特殊业绩_用于算毛利净利
	SUM(tempDisk.SpecialCNetAmount_1) as SpecialCNetAmount_1,									--签约金额_特殊业绩_用于算毛利净利 
	SUM(tempDisk.SpecialCNetCount_1) as SpecialCNetCount_1,									--签约金额_特殊业绩_用于算毛利净利
	sum(tempDisk.YONetAmount) as YONetAmount, --预认购
	sum(tempDisk.YONetArea) as YONetArea,
	sum(tempDisk.YONetCount) as YONetCount
	from
	(
		select
		sb.BuildingGUID as BldGUID,															--产品楼栋GUID
		tempYesDisk.StatisticalDate,														--统计日期
		sum(isnull(tempYesDisk.ONetArea,0)) as ONetArea,											--认购面积
		sum(isnull(tempYesDisk.ONetAmount,0)) as ONetAmount,										--认购金额
		sum(isnull(tempYesDisk.ONetCount,0)) as ONetCount,										--认购套数
		sum(isnull(tempYesDisk.CNetArea,0)) as CNetArea,											--签约面积
		sum(isnull(tempYesDisk.CNetAmount,0)) as CNetAmount,										--签约金额
		sum(isnull(tempYesDisk.CNetAmountNotTax,0)) as CNetAmountNotTax,							--签约金额(不含税)
		sum(isnull(tempYesDisk.CNetCount,0)) as CNetCount,										--签约套数
		0 as SpecialONetAmount,																--认购金额_特殊业绩
		0 as SpecialCNetArea,																--签约面积_特殊业绩
		0 as SpecialCNetAmount,																--签约金额_特殊业绩
		0 as SpecialCNetCount,																--签约套数_特殊业绩
		sum(isnull(tempYesDisk.NCCumArea,	0)) as NCCumArea	,														--累计草签面积
		sum(isnull(tempYesDisk.NCCumAmount,	0)) as NCCumAmount,														--累计草签金额
		sum(isnull(tempYesDisk.NCCumCount,	0)) as NCCumCount,															--累计草签套数
		sum(isnull(tempYesDisk.ICCumArea,	0)) as ICCumArea,															--累计网签面积
		sum(isnull(tempYesDisk.ICCumAmount,	0)) as ICCumAmount,														--累计网签金额
		sum(isnull(tempYesDisk.ICCumCount,	0)) as ICCumCount,															--累计网签套数
        0 as SpecialCNetArea_1,
        0 as SpecialCNetAmount_1,
		0 as SpecialCNetCount_1
		,sum(isnull(YONetAmount,0))YONetAmount
		,sum(isnull(YONetArea,0))YONetArea
		,sum(isnull(YONetCount,0))YONetCount
		from data_wide_dws_mdm_Building sb  --楼栋宽表
		inner join 
		( 
			SELECT  shd.ProjGUID,
					shd.BldGUID,
					--CONVERT(NVARCHAR(10), shd.QsDate, 23) AS StatisticalDate,			
					CONVERT(NVARCHAR(10), isnull(r.TsRoomQSDate, shd.QsDate), 23) AS StatisticalDate,											--统计日期
					--SUM(CASE WHEN (p.DiskFlag = '是' and r.specialFlag = '否') or sp.TsyjType='经营类(溢价款)' THEN isnull(shd.BldArea,0) ELSE 0 END) as ONetArea, 							--认购面积
					--SUM(CASE WHEN (p.DiskFlag = '是' and r.specialFlag = '否') or sp.TsyjType='经营类(溢价款)' THEN isnull(shd.jyTotal,0) ELSE 0 END) as ONetAmount, 						--认购金额
					--SUM(CASE WHEN (p.DiskFlag = '是' and r.specialFlag = '否') or sp.TsyjType='经营类(溢价款)' THEN isnull(shd.Ts,0) ELSE 0 END) as ONetCount, 								--认购套数
					0 AS ONetArea,
					0 AS ONetAmount,
					0 AS ONetCount,
					SUM(CASE WHEN ((p.DiskFlag = '是' and r.specialFlag = '否') or ISNULL(sp.YJMode,sp1.YJMode)=1) AND shd.TradeType = '签约' THEN isnull(shd.BldArea,0) ELSE 0 END) as CNetArea, --签约面积
					SUM(CASE WHEN ((p.DiskFlag = '是' and r.specialFlag = '否') or ISNULL(sp.YJMode,sp1.YJMode)=1) AND shd.TradeType = '签约' THEN isnull(shd.jyTotal,0) ELSE 0 END) as CNetAmount, --签约金额
					SUM(CASE WHEN ((p.DiskFlag = '是' and r.specialFlag = '否') or ISNULL(sp.YJMode,sp1.YJMode)=1) AND shd.TradeType = '签约' THEN isnull(shd.jyTotalNoTax,0) ELSE 0 END) as CNetAmountNotTax, --签约金额(不含税)
					SUM(CASE WHEN ((p.DiskFlag = '是' and r.specialFlag = '否') or ISNULL(sp.YJMode,sp1.YJMode)=1)  AND shd.TradeType = '签约' THEN isnull(shd.Ts,0) ELSE 0 END) as CNetCount, 	--签约套数
					SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType='草签' THEN isnull(shd.BldArea,0) ELSE 0 END) as NCCumArea, 					--累计草签面积
					SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType='草签' THEN isnull(shd.jytotal,0) ELSE 0 END) as NCCumAmount, 				--累计草签金额
					SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType='草签' THEN isnull(shd.Ts,0) ELSE 0 END) as NCCumCount, 						--累计草签套数
					SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType='网签' THEN isnull(shd.BldArea,0) ELSE 0 END) as ICCumArea, 					--累计网签面积
					SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType='网签' THEN isnull(shd.jytotal,0) ELSE 0 END) as ICCumAmount, 				--累计网签金额
					SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType='网签' THEN isnull(shd.Ts,0) ELSE 0 END) as ICCumCount 						--累计网签套数
					,0 YONetAmount
					,0 YONetArea
					,0 YONetCount
			FROM    data_wide_s_SaleHsData shd with(nolock)
			inner join data_wide_s_RoomoVerride r with(nolock)  on r.RoomGUID = shd.RoomGUID
			inner join data_wide_dws_mdm_Project p with(nolock) on p.ProjGUID = shd.ProjGUID	
			LEFT JOIN (SELECT roomguid,YJMode FROM dbo.data_wide_s_SpecialPerformance where YJMode=1 GROUP BY  roomguid,YJMode) sp ON sp.RoomGUID = r.RoomGUID
			LEFT JOIN (SELECT BldGUID,YJMode FROM dbo.data_wide_s_SpecialPerformance where YJMode=1 AND RoomGUID IS null GROUP BY  BldGUID,YJMode) sp1 ON sp1.BldGUID = r.BldGUID
            where shd.QsDate is not null
			GROUP BY  shd.ProjGUID, shd.BldGUID, CONVERT(NVARCHAR(10), isnull(r.TsRoomQSDate, shd.QsDate), 23)
			UNION ALL 
			--获取认购信息：1、直接签约的以签约日期为准；2、认购转签约除日期按照认购时间统计外，其余按照签约进行统计；
			SELECT r.ProjGUID,r.BldGUID,
			 --CONVERT(NVARCHAR(10), r.RgQsDate, 23) AS StatisticalDate,
			 CONVERT(NVARCHAR(10), isnull(r.TsRoomQSDate, r.RgQsDate), 23) AS StatisticalDate,
			 SUM(CASE WHEN (r.specialFlag = '否' or ISNULL(sp.YJMode,sp1.YJMode)=1) AND r.Status IN ('签约','认购') THEN r.BldArea ELSE 0 END ) AS ONetArea,
			 SUM(CASE WHEN (r.specialFlag = '否' or ISNULL(sp.YJMode,sp1.YJMode)=1) AND r.Status IN ('签约','认购') THEN r.CjRmbTotal+ISNULL(specialYj,0) ELSE 0 END ) AS ONetAmount,
			 sum(CASE WHEN (r.specialFlag = '否' OR isnull(specialYj,0)<>0  or ISNULL(sp.YJMode,sp1.YJMode)=1) AND r.Status IN ('签约','认购') THEN 1 ELSE 0 END ) AS ONetCount,
			 0 as CNetArea, --签约面积
			 0 as CNetAmount, --签约金额
			 0 as CNetAmountNotTax, --签约金额(不含税)
			 0 as CNetCount, 	--签约套数
			 0 as NCCumArea, 	--累计草签面积
			 0 as NCCumAmount, 	--累计草签金额
			 0 AS NCCumCount, 	--累计草签套数
			 0 AS ICCumArea, 	--累计网签面积
			 0 as ICCumAmount, 	--累计网签金额
			 0 AS ICCumCount,	--累计网签套数
			 sum(case when pre.roomguid is null and (r.specialFlag = '否' or ISNULL(sp.YJMode,sp1.YJMode)=1) AND r.Status IN ('签约','认购') THEN r.CjRmbTotal+ISNULL(specialYj,0) ELSE 0 END )YONetAmount,--预认购
			 sum(case when pre.roomguid is null and (r.specialFlag = '否' or ISNULL(sp.YJMode,sp1.YJMode)=1) AND r.Status IN ('签约','认购') THEN r.BldArea ELSE 0 END )YONetArea,
			 sum(case when pre.roomguid is null and (r.specialFlag = '否' or ISNULL(sp.YJMode,sp1.YJMode)=1) AND r.Status IN ('签约','认购') THEN 1 ELSE 0 END )YONetCount
			 FROM   data_wide_s_RoomoVerride r with(nolock)   
			LEFT JOIN (SELECT roomguid,YJMode FROM dbo.data_wide_s_SpecialPerformance where YJMode=1 GROUP BY  roomguid,YJMode) sp ON sp.RoomGUID = r.RoomGUID
			LEFT JOIN (SELECT BldGUID,YJMode FROM dbo.data_wide_s_SpecialPerformance where YJMode=1 AND RoomGUID IS null 
			GROUP BY  BldGUID,YJMode) sp1 ON sp1.BldGUID = r.BldGUID
			LEFT JOIN data_wide_s_pre_order pre on r.roomguid = pre.roomguid
			GROUP BY r.ProjGUID,r.BldGUID,CONVERT(NVARCHAR(10), isnull(r.TsRoomQSDate, r.RgQsDate), 23) 
			UNION ALL 
			--获取预认购信息
			SELECT ProjGUID,BldGUID,CONVERT(NVARCHAR(10), CJDate, 23) AS StatisticalDate,
			 0 ONetArea,
			 0 AS ONetAmount,
			 0 AS ONetCount,
			 0 as CNetArea, --签约面积
			 0 as CNetAmount, --签约金额
			 0 as CNetAmountNotTax, --签约金额(不含税)
			 0 as CNetCount, --签约套数
			 0 as NCCumArea, --累计草签面积
			 0 as NCCumAmount, --累计草签金额
			 0 AS NCCumCount, --累计草签套数
			 0 AS ICCumArea,  --累计网签面积
			 0 as ICCumAmount,--累计网签金额
			 0 AS ICCumCount, --累计网签套数
			 SUM(CJAmount)YONetAmount,--预认购
			 SUM(BldArea)YONetArea,
			 sum(1)YONetCount
			 FROM   data_wide_s_pre_order with(nolock)   			 
			GROUP BY ProjGUID,BldGUID,CONVERT(NVARCHAR(10), CJDate, 23)
		) tempYesDisk  --销售交易回溯宽表-营销操盘取数
		on tempYesDisk.BldGUID = sb.BuildingGUID
		GROUP BY sb.BuildingGUID,															--产品楼栋GUID
		tempYesDisk.StatisticalDate
		union all		
		select 
		d.BldGUID,
		d.StatisticalDate,
		0 as ONetArea,																		--认购面积
		0 as ONetAmount,																	--认购金额
		0 as ONetCount,																		--认购套数
		0 as CNetArea,																		--签约面积
		0 as CNetAmount,																	--签约金额
		0 AS CNetAmountNotTax, --签约金额(不含税)
		0 as CNetCount,																		--签约套数
		isnull(d.OCjAmount,0) as SpecialONetAmount,											--认购金额_特殊业绩
		isnull(d.CCjArea,0) as SpecialCNetArea,												--签约面积_特殊业绩
		isnull(d.CCjAmount,0) as SpecialCNetAmount,											--签约金额_特殊业绩
		isnull(d.CCjCount,0) as SpecialCNetCount,											--签约套数_特殊业绩
		0 as NCCumArea,																		--累计草签面积
		0 as NCCumAmount,																	--累计草签金额
		0 as NCCumCount,																	--累计草签套数
		0 as ICCumArea,																		--累计网签面积
		0 as ICCumAmount,																	--累计网签金额
		0 as ICCumCount	,																	--累计网签套数	
        isnull(d.CCjArea_1,0)  as SpecialCNetArea_1,
        isnull(d.CCjAmount_1,0) as SpecialCNetAmount_1,	
		isnull(d.CCjCount_1,0)  as SpecialCNetCount_1,
		0 YONetAmount,
		0 YONetArea,
		0 YONetCount
 		from 
		(
			select  c.BldGUID,
					c.StatisticalDate,
					isnull(c.OCjAmount,0) * 10000.00 as OCjAmount,--特殊业绩的认购金额
					c.CCjArea,
					isnull(c.CCjAmount,0) * 10000.00 as CCjAmount,
					c.CCjCount,
					c.SpecialType,
					Row_Number() over(partition by c.BldGUID,c.StatisticalDate order by c.SpecialType asc) as Num,
					isnull(c.SpecialCNetAmount_1,0) * 10000.00 as CCjAmount_1,
					c.SpecialCNetArea_1 as CCjArea_1,
					c.SpecialCNetCount_1 as CCjCount_1
			from 
			(
				select  b.BldGUID,
						CONVERT(NVARCHAR(10), b.StatisticalDate, 23) as StatisticalDate,
						sum(b.OCjAmount) as OCjAmount,
						sum(case when b.YJMode<>1 then b.CCjArea else 0 end) as CCjArea,
						sum(b.CCjAmount) as CCjAmount,
						sum(case when b.YJMode<>1 then b.CCjCount else 0 end) as CCjCount,
						0 as SpecialType, --楼栋维度取数
                        sum(case when TsyjType in ('整体销售', '其他销售', '回购', '包销', '代建类') then (case when pb.TopProductTypeName = '地下室/车库' then CCjCount else CCjArea end) else 0 end ) as SpecialCNetArea_1,
                        sum(case when TsyjType in ('整体销售', '其他销售', '经营类(溢价款)', '回购', '包销', '代建类') then CCjAmount else 0 end)  as SpecialCNetAmount_1,	
						sum(case when TsyjType in ('整体销售', '其他销售', '经营类(溢价款)', '回购', '包销', '代建类') then CCjCount else 0 end)  as SpecialCNetCount_1
				from data_wide_s_SpecialPerformance b with(nolock)  
				inner join data_wide_dws_mdm_Building pb on b.BldGUID = pb.BuildingGUID
				where  isnull(b.TsyjType,'') NOT IN (SELECT TsyjTypeName FROM data_wide_s_TsyjType WHERE IsRelatedBuildingsRoom =0) and b.RoomGUID is null and b.StatisticalDate is not null
				group by b.BldGUID,
						CONVERT(NVARCHAR(10), b.StatisticalDate, 23)
				union all
				select  a.BldGUID,
						CONVERT(NVARCHAR(10), a.StatisticalDate, 23) as StatisticalDate,
						sum(a.OCjAmount) as OCjAmount,
						sum(case when a.YJMode<>1 then a.CCjArea else 0 end) as CCjArea,
						sum(a.CCjAmount) as CCjAmount,
						sum(case when a.YJMode<>1 then a.CCjCount else 0 end) as CCjCount,
						1 as SpecialType, --房间维度取数
						sum(case when TsyjType in ('整体销售', '其他销售', '回购', '包销', '代建类') then (case when pb.TopProductTypeName = '地下室/车库' then CCjCount else CCjArea end) else 0 end) as SpecialCNetArea_1,
						sum(case when TsyjType in ('整体销售', '其他销售', '经营类(溢价款)', '回购', '包销', '代建类') then CCjAmount else 0 end)  as SpecialCNetAmount_1,
						sum(case when TsyjType in ('整体销售', '其他销售', '经营类(溢价款)', '回购', '包销', '代建类') then 1 else 0 end) as SpecialCNetCount_1
				from data_wide_s_SpecialPerformance a  with(nolock) 
				inner join data_wide_dws_mdm_Building pb on a.BldGUID = pb.BuildingGUID
				where isnull(a.TsyjType,'') NOT IN (SELECT TsyjTypeName FROM data_wide_s_TsyjType WHERE IsRelatedBuildingsRoom =0) and a.RoomGUID is not null and a.StatisticalDate is not null
				group by a.BldGUID,
						CONVERT(NVARCHAR(10), a.StatisticalDate, 23)
			) c
		) d
		where d.Num = 1	
	) tempDisk
	group by tempDisk.BldGUID,tempDisk.StatisticalDate
) tempSum
inner join data_wide_dws_mdm_Building sb with(nolock) on sb.BuildingGUID = tempSum.BldGUID
inner join data_wide_dws_mdm_Project p with(nolock)  on p.ProjGUID = sb.ProjGUID	--分期项目
left join data_wide_dws_s_Dimension_Organization org with(nolock) on org.OrgGUID = p.XMSSCSGSGUID AND  org.ParentOrganizationGUID =p.BUGUID --公司
left join 
(
	select  b.ParentProjGUID,
			CONVERT(NVARCHAR(10), b.StatisticalDate, 23) as StatisticalDate,
			sum(isnull(b.OCjAmount,0)) * 10000.00 as OCjAmount,--特殊业绩的认购金额
			sum(b.CCjArea) as CCjArea,
			sum(b.CCjAmount)*10000.00 as CCjAmount,
			sum(b.CCjCount) as CCjCount
	from data_wide_s_SpecialPerformance b  with(nolock)
	where b.TsyjType IN  (SELECT TsyjTypeName FROM data_wide_s_TsyjType WHERE IsRelatedBuildingsRoom =0) and b.StatisticalDate is not null
	group by b.ParentProjGUID,
			CONVERT(NVARCHAR(10), b.StatisticalDate, 23)
) spp --特殊业绩(一级项目维度)
on spp.ParentProjGUID = p.ParentGUID and datediff(day,spp.StatisticalDate,tempSum.StatisticalDate) = 0 
left join 
(
	select *  from (select ROW_NUMBER() OVER  (partition by BldGUID order by FangPanTime desc) AS rowno,* from 
			(select  BldGUID,FangPanTime,sum(BldArea) as FangPanArea, sum(Total) as FangPanAmount, sum(1) as FangPanCount
				from data_wide_s_RoomoVerride with(nolock) where FangPanTime is not null group by BldGUID,FangPanTime) temp)temp1 where rowno=1
) tempr 
on tempr.BldGUID = tempSum.BldGUID and datediff(day,tempr.FangPanTime,tempSum.StatisticalDate) = 0
union all

select
org.OrgGUID AS BUGUID,																	--公司GUID
org.OrganizationName AS BUName,															--公司名称
org.OrganizationCode AS BUCode,															--公司编码
p.ProjGUID as ParentProjGUID,															--项目GUID
p.ProjName as ParentProjName,															--项目名称
p.ProjCode as ParentProjCode,															--项目编码
childProj.ProjGUID as ProjGUID,																		--分期GUID
childProj.ProjName as ProjName,																		--分期名称
childProj.ProjCode as ProjCode,																		--分期编码
null as GCBldGUID,																		--工程楼栋GUID
null as GCBldName,																		--工程楼栋名称
null as GCBldCode,																		--工程楼栋编码
tempNoDisk.BuildingGUID as BldGUID,																		--产品楼栋GUID
tempNoDisk.BuildingName as BldName,																		--产品楼栋名称
tempNoDisk.Code as BldCode,																		--产品楼栋编码
tempNoDisk.TopProductTypeGUID,															--一级产品类型GUID
pt1.HierarchyName as TopProductTypeName,												--一级产品类型名称
pt1.HierarchyCode as TopProductTypeCode,												--一级产品类型Code
tempNoDisk.ProductTypeGUID,																--末级产品类型GUID
pt2.HierarchyName as ProductTypeName,													--末级类型名称
pt2.HierarchyCode as ProductTypeCode,													--末级产品类型编码
tempNoDisk.StatisticalDate as StatisticalDate,											--统计日期	
p.RightsRate,																			--权益比例
p.GenreTableType,																		--并表类型
p.DiskType,																				--操盘类型
p.DiskFlag,																				--是否操盘
p.HistoryType,																			--是否历史
null as YszGetDate,																		--取证日期
null as IsLock,																			--是否锁定
isnull(tempNoDisk.ONetArea,0) as ONetArea,												--认购面积
isnull(tempNoDisk.ONetAmount,0) as ONetAmount,											--认购金额
isnull(tempNoDisk.ONetCount,0) as ONetCount,											--认购套数
isnull(tempNoDisk.ONetAmount,0) * p.RightsRate / 100.00 as RightsONetAmount,			--认购金额_权益口径（【认购金额】+【认购金额_特殊业绩】）*【权益比例】
isnull(tempNoDisk.CNetArea,0) as CNetArea,												--签约面积
isnull(tempNoDisk.CNetAmount,0) as CNetAmount,											--签约金额
--合作项目的签约金额（不含税）使用含税金额除以税率反算，判断合作业绩单的签约日期，如201604以前不计算税率，不含税和含税签约金额相等；201604~201804按照11%税率计算；201805~201903按照10%税率计算；201904及以后按照9%税率计算；
	CASE 
		WHEN tempNoDisk.StatisticalDate<'2016-04-01' THEN 	ISNULL(tempNoDisk.CNetAmount,0) 
		WHEN tempNoDisk.StatisticalDate>='2016-04-01' AND  tempNoDisk.StatisticalDate<'2018-05-01' THEN 	ISNULL(tempNoDisk.CNetAmount,0) /(1+0.11)
		WHEN tempNoDisk.StatisticalDate>='2018-05-01' AND  tempNoDisk.StatisticalDate<'2019-04-01' THEN 	ISNULL(tempNoDisk.CNetAmount,0) /(1+0.10)
		WHEN tempNoDisk.StatisticalDate>='2019-04-01'  THEN 	ISNULL(tempNoDisk.CNetAmount,0) /(1+0.09)
	ELSE 0 END AS  CNetAmountNotTax, --签约金额(不含税)
isnull(tempNoDisk.CNetCount,0) as CNetCount,											--签约套数
isnull(tempNoDisk.CNetAmount,0) * p.RightsRate / 100.00 as RightsCNetAmount,			--签约金额_权益口径（【签约金额】+【签约金额_特殊业绩】）*【权益比例】
null as SpecialCNetArea,																--签约面积_特殊业绩
null as SpecialCNetAmount,																--签约金额_特殊业绩
null as SpecialCNetAmountNotTax,														--签约金额不含税_特殊业绩
null as SpecialCNetCount,																--签约套数_特殊业绩
null as NCCumArea,																		--累计草签面积
null as NCCumAmount,																	--累计草签金额
null as NCCumCount,																		--累计草签套数
null as ICCumArea,																		--累计网签面积
null as ICCumAmount,																	--累计网签金额
null as ICCumCount,																		--累计网签套数
null as FangPanArea,																	--推盘面积
null as FangPanAmount,																	--推盘金额
null as FangPanCount,																	--推盘套数
0 SpecialCNetArea_1,																	--签约面积_特殊业绩_用于算净利毛利
0 SpecialCNetAmount_1,																--签约金额_特殊业绩_用于算净利毛利
0 SpecialCNetAmountNotTax_1,														--签约金额不含税_特殊业绩_用于算净利毛利
0 SpecialCNetCount_1,														--签约套数不含税_特殊业绩_用于算净利毛利
isnull(tempNoDisk.ONetAmount,0) as YONetAmount,
isnull(tempNoDisk.ONetArea,0) as YONetArea,
isnull(tempNoDisk.ONetCount,0) as YONetCount
from 
(
	--select  nc.ParentProjGUID,
	--		nc.TopProductTypeGUID,
	--		nc.ProductTypeGUID ,
	--		bld.BuildingGUID,
	--		bld.BuildingName,
	--		bld.Code,
	--		CONVERT(NVARCHAR(10), nc.StatisticalDate, 23) AS StatisticalDate,			--统计日期
	--		SUM(nc.OCjArea) as ONetArea, 												--认购面积
	--		SUM(nc.OCjTotal) * 10000.00 as ONetAmount, 									--认购金额
	--		SUM(nc.OCjCount) as ONetCount, 												--认购套数
	--		SUM(nc.CCjArea) as CNetArea, 												--签约面积
	--		SUM(nc.CCjTotal) * 10000.00 as CNetAmount, 									--签约金额
	--		SUM(nc.CCjCount) as CNetCount 												--签约套数
	--from data_wide_s_NoControl nc with(nolock)
	--Left join (select  Row_Number() over(partition by ParentProjGUID,ProductTypeGuid,TopProductTypeGuid order by code asc) as Num,* from data_wide_dws_mdm_Building where BldType='产品楼栋') bld 
	--	on nc.ProductTypeGUID=bld.ProductTypeGuid and nc.TopProductTypeGUID=bld.TopProductTypeGuid and nc.ProjGUID=bld.ParentProjGUID and bld.Num=1
	--inner join data_wide_dws_mdm_Project p with(nolock) on p.ProjGUID = nc.ParentProjGUID
	--where nc.StatisticalDate is not null
	--GROUP BY  nc.ParentProjGUID,
	--		nc.TopProductTypeGUID,
	--		nc.ProductTypeGUID,
	--		bld.BuildingGUID,
	--		bld.BuildingName,
	--		bld.Code,
	--		CONVERT(NVARCHAR(10), nc.StatisticalDate, 23)
   select t.ParentProjGUID,t.TopProductTypeGUID,t.ProductTypeGUID,t.BuildingGUID,t.BuildingName,t.Code,t.StatisticalDate,
	sum(ONetArea) as ONetArea , sum(ONetAmount) as ONetAmount ,sum(ONetCount) as ONetCount ,
	sum(CNetArea) as CNetArea , sum(CNetAmount) as CNetAmount ,sum(CNetCount) as CNetCount from (
	select  nc.ParentProjGUID,
			nc.TopProductTypeGUID,
			nc.ProductTypeGUID ,
			bld.BuildingGUID,
			bld.BuildingName,
			bld.Code,
			CONVERT(NVARCHAR(10), nc.StatisticalDate, 23) AS StatisticalDate,			--统计日期
			SUM(nc.OCjArea) as ONetArea, 												--认购面积
			SUM(nc.OCjTotal) * 10000.00 as ONetAmount, 									--认购金额
			SUM(nc.OCjCount) as ONetCount, 												--认购套数
			SUM(nc.CCjArea) as CNetArea, 												--签约面积
			SUM(nc.CCjTotal) * 10000.00 as CNetAmount, 									--签约金额
			SUM(nc.CCjCount) as CNetCount 												--签约套数
	from data_wide_s_NoControl nc with(nolock)
	--Left join (select  Row_Number() over(partition by ParentProjGUID,ProductTypeGuid,TopProductTypeGuid order by code asc) as Num,* from data_wide_dws_mdm_Building where BldType='产品楼栋') bld 
	--	on nc.ProductTypeGUID=bld.ProductTypeGuid and nc.TopProductTypeGUID=bld.TopProductTypeGuid and nc.ProjGUID=bld.ParentProjGUID and bld.Num=1
	Left join (select  Row_Number() over(partition by ParentProjGUID,productname,TopProductTypename,commoditytype,zxbz order by code asc) as Num,*
	from data_wide_dws_mdm_Building where BldType='产品楼栋') bld 
		on nc.ProductName=bld.productname and nc.ProductType=bld.TopProductTypename 
		and nc.RoomType = bld.commoditytype and nc.zxbz = bld.zxbz
		and nc.ProjGUID=bld.ParentProjGUID and bld.Num=1
	inner join data_wide_dws_mdm_Project p with(nolock) on p.ProjGUID = nc.ParentProjGUID
	where nc.StatisticalDate is not null and nc.bldguid is null
	GROUP BY  nc.ParentProjGUID,
			nc.TopProductTypeGUID,
			nc.ProductTypeGUID,
			bld.BuildingGUID,
			bld.BuildingName,
			bld.Code,
			CONVERT(NVARCHAR(10), nc.StatisticalDate, 23)
	union all
	select  nc.ParentProjGUID,
			nc.TopProductTypeGUID,
			nc.ProductTypeGUID ,
			bld.BuildingGUID,
			bld.BuildingName,
			bld.Code,
			CONVERT(NVARCHAR(10), nc.StatisticalDate, 23) AS StatisticalDate,			--统计日期
			SUM(nc.OCjArea) as ONetArea, 												--认购面积
			SUM(nc.OCjTotal) * 10000.00 as ONetAmount, 									--认购金额
			SUM(nc.OCjCount) as ONetCount, 												--认购套数
			SUM(nc.CCjArea) as CNetArea, 												--签约面积
			SUM(nc.CCjTotal) * 10000.00 as CNetAmount, 									--签约金额
			SUM(nc.CCjCount) as CNetCount 												--签约套数
	from data_wide_s_NoControl nc with(nolock)
	inner join  data_wide_dws_mdm_Building bld on BldType='产品楼栋' and bld.BuildingGUID = nc.bldguid
	inner join data_wide_dws_mdm_Project p with(nolock) on p.ProjGUID = nc.ParentProjGUID
	where nc.StatisticalDate is not null and  nc.bldguid is not null
	GROUP BY  nc.ParentProjGUID,
			nc.TopProductTypeGUID,
			nc.ProductTypeGUID,
			bld.BuildingGUID,
			bld.BuildingName,
			bld.Code,
			CONVERT(NVARCHAR(10), nc.StatisticalDate, 23)) t
			group by  t.ParentProjGUID,t.TopProductTypeGUID,t.ProductTypeGUID,t.BuildingGUID,t.BuildingName,t.Code,t.StatisticalDate
) tempNoDisk --销售交易宽表-非营销操盘取数
inner join data_wide_dws_mdm_Project p with(nolock) on tempNoDisk.ParentProjGUID = p.ProjGUID 
left join (select  Row_Number() over(partition by ParentGUID order by projcode asc) as Num,* from data_wide_dws_mdm_Project where ParentGUID is not null) childProj on Num=1 and p.ProjGUID = childProj.ParentGUID
inner join data_wide_mdm_ProductType pt1 with(nolock) on pt1.p_MasterDataProductTypeId = tempNoDisk.TopProductTypeGUID 
inner join data_wide_mdm_ProductType pt2 with(nolock) on pt2.p_MasterDataProductTypeId = tempNoDisk.ProductTypeGUID 
left join data_wide_dws_s_Dimension_Organization org with(nolock) on org.OrgGUID = p.XMSSCSGSGUID AND  org.ParentOrganizationGUID =p.BUGUID --公司


union all

select
org.OrgGUID AS BUGUID,																	--公司GUID
org.OrganizationName AS BUName,															--公司名称
org.OrganizationCode AS BUCode,															--公司编码
p.ProjGUID as ParentProjGUID,															--项目GUID
p.ProjName as ParentProjName,															--项目名称
p.ProjCode as ParentProjCode,															--项目编码
childProj.ProjGUID as ProjGUID,																		--分期GUID
childProj.ProjName as ProjName,																		--分期名称
childProj.ProjCode as ProjCode,																		--分期编码
null as GCBldGUID,																		--工程楼栋GUID
null as GCBldName,																		--工程楼栋名称
null as GCBldCode,																		--工程楼栋编码
null as BldGUID,																		--产品楼栋GUID
null as BldName,																		--产品楼栋名称
null as BldCode,																		--产品楼栋编码
null as TopProductTypeGUID,																--一级产品类型GUID
null as TopProductTypeName,																--一级产品类型名称
null as TopProductTypeCode,																--一级产品类型Code
null as ProductTypeGUID,																--末级产品类型GUID
null as ProductTypeName,																--末级类型名称
null as ProductTypeCode,																--末级产品类型编码
spp.StatisticalDate,																	--统计日期	
p.RightsRate,																			--权益比例
p.GenreTableType,																		--并表类型
p.DiskType,																				--操盘类型
p.DiskFlag,																				--是否操盘
p.HistoryType,																			--是否历史
null as YszGetDate,																		--取证日期
null as IsLock,																			--是否锁定
null as ONetArea,																		--认购面积
null as ONetAmount,																		--认购金额
null as ONetCount,																		--认购套数
isnull(spp.OCjAmount,0) * p.RightsRate / 100.00 as RightsONetAmount,					--认购金额_权益口径（【认购金额】+【认购金额_特殊业绩】）*【权益比例】
null as CNetArea,																		--签约面积
null as CNetAmount,																		--签约金额
NULL AS CNetAmountNotTax, --签约金额(不含税)
null as CNetCount,																		--签约套数
isnull(spp.CCjAmount,0) * p.RightsRate / 100.00 as RightsCNetAmount,					--签约金额_权益口径（【签约金额】+【签约金额_特殊业绩】）*【权益比例】
isnull(spp.CCjArea,0) as SpecialCNetArea,												--签约面积_特殊业绩
isnull(spp.CCjAmount,0) as SpecialCNetAmount,											--签约金额_特殊业绩
CASE 
		WHEN spp.StatisticalDate<'2016-04-01' THEN 	ISNULL(spp.CCjAmount,0) 
		WHEN spp.StatisticalDate>='2016-04-01' AND  spp.StatisticalDate<'2018-05-01' THEN 	ISNULL(spp.CCjAmount,0) /(1+0.11)
		WHEN spp.StatisticalDate>='2018-05-01' AND  spp.StatisticalDate<'2019-04-01' THEN 	ISNULL(spp.CCjAmount,0) /(1+0.10)
		WHEN spp.StatisticalDate>='2019-04-01'  THEN 	ISNULL(spp.CCjAmount,0) /(1+0.09)
ELSE 0 END AS SpecialCNetAmountNotTax,														--签约金额不含税_特殊业绩
isnull(spp.CCjCount,0) as SpecialCNetCount,												--签约套数_特殊业绩
null as NCCumArea,																		--累计草签面积
null as NCCumAmount,																	--累计草签金额
null as NCCumCount,																		--累计草签套数
null as ICCumArea,																		--累计网签面积
null as ICCumAmount,																	--累计网签金额
null as ICCumCount,																		--累计网签套数
null as FangPanArea,																	--推盘面积
null as FangPanAmount,																	--推盘金额
null as FangPanCount,																	--推盘套数
0 SpecialCNetArea_1,																	--签约面积_特殊业绩_用于算净利毛利
0 SpecialCNetAmount_1,																--签约金额_特殊业绩_用于算净利毛利
0 SpecialCNetAmountNotTax_1,														--签约金额不含税_特殊业绩_用于算净利毛利
0 SpecialCNetCount_1,														--签约套数不含税_特殊业绩_用于算净利毛利
null as YONetAmount, --预认购
null as YONetArea,
null as YONetCount
from 
(
	select  b.ParentProjGUID,
			CONVERT(NVARCHAR(10), b.StatisticalDate, 23) as StatisticalDate,
			sum(isnull(b.OCjAmount,0)) * 10000.00 as OCjAmount,--特殊业绩的认购金额
			sum(case when b.YJMode<>1 then b.CCjArea else 0 end) as CCjArea,
			sum(b.CCjAmount)*10000.00 as CCjAmount,
			sum(case when b.YJMode<>1 then b.CCjCount else 0 end) as CCjCount
	from data_wide_s_SpecialPerformance b  with(nolock)
	where (b.bldguid is null or (b.TsyjType IN  (SELECT TsyjTypeName FROM data_wide_s_TsyjType WHERE IsRelatedBuildingsRoom =0))) 
	and b.StatisticalDate is not null
	group by b.ParentProjGUID,
			CONVERT(NVARCHAR(10), b.StatisticalDate, 23)
) spp --特殊业绩(一级项目维度)												
inner join data_wide_dws_mdm_Project p with(nolock) on p.ProjGUID = spp.ParentProjGUID 				--项目
left join (select  Row_Number() over(partition by ParentGUID order by projcode asc) as Num,* from data_wide_dws_mdm_Project where ParentGUID is not null) childProj on Num=1 and p.ProjGUID = childProj.ParentGUID --分期
left join data_wide_dws_s_Dimension_Organization org with(nolock) on org.OrgGUID = p.XMSSCSGSGUID AND  org.ParentOrganizationGUID =p.BUGUID 	
