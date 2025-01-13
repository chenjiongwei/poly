USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_dw_d_TopProject]    Script Date: 2025/1/7 11:01:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER PROC [dbo].[usp_dw_d_TopProject]
AS
/*
项目维度表 清洗存储过程
created by 于丹丹 2021-06-03
实例：usp_dw_d_TopProject
备注：
1、该表包括项目部、城市公司、区域公司字段；如果没有就为空值
2、由于历史原因，中航里程公司下面的项目分期及楼栋未能同主数据打通，清洗脚本先排除掉中航里城公司下关联不到工程楼栋和项目分期的相关数据

modify chenjw 2022-06-09
1、新增项目获取地价、 板块分类、计容可售面积、营销操盘方等字段
修改 chenjw 2022-10-13
1、增加投管系统明源系统代码字段

modified by lintx 2022-11-29
1、增加项目的可售楼面价/地块名/股权溢价/其中取得价/操盘条线/占地面积6个字段
2、增加商办/住宅类可售面积，销售车位个数

modified by lintx 2022-12-07
1、增加项目的自持面积，累计开工计容可售面积，累计开工自持面积

modified by lintx 2023-03-17
1、增加合作方简称信息、项目五分类、城市六分化

modified by lintx 20240603
1、注册资本、各条操盘线情况

*/
BEGIN

    -- 一级项目
    SELECT do.DevelopmentCompanyGUID AS 平台公司GUID ,
           do.DevelopmentCompanyName AS 平台公司名称 ,
           do.OrgGUID AS 组织公司GUID ,
           do.OrganizationName AS 组织公司名称 ,
           p.ProjGUID AS 项目GUID ,
           p.ProjName AS 项目名称 ,
           p.SpreadName AS 项目推广名称 ,
           p.ProjCode AS 项目编码 ,
           p.TgProjCode AS 项目投管编码 ,
           p.Level AS 项目级数 ,
           p.Rjl AS 容积率 ,
           p.BuildArea AS 总建筑面积 ,
           p.UpArea AS 地上建筑面积 ,
           p.DownArea AS 地下建筑面积 ,
           p.SaleArea AS 可售面积 ,
           p.UpSaleArea AS 地上可售面积 ,
           p.DownSaleArea AS 地下可售面积 ,
           p.BuildOccupyArea AS 建筑用地面积 ,
           p.CountRjlArea AS 计容建筑面积 ,
           ISNULL(p.DiskType, '') AS 操盘方式 ,
           ISNULL(p.DiskFlag, '') AS 是否操盘 ,
           ISNULL(p.GenreTableType, '') AS 并表类型 ,
           p.CityGUID AS 城市GUID ,
           p.City AS 城市 ,
           p.SetNum AS [户/个数] ,
           p.RightsRate AS 财务收益比例 ,
           p.EquityRatio AS 权益比例 ,
           p.GQRatio AS 股权比例 ,
           p.BelongAreaGUID AS 区域公司GUID ,
           p.BelongAreaName AS 区域公司名称 ,
           p.XMSSCSGSGUID AS 项目部GUID ,
           do1.OrganizationName AS 项目部名称 ,
           p.XMHQFS AS 项目获取方式 ,
           p.PlanUrl AS 项目总图地址 ,
           p.sfqs AS 是否清算 ,
           p.IsBg AS 是否并购 ,
           p.BelongAreaName AS 片区名称 ,
           p.Address AS 详细地址 ,
           p.BuildBeginDate AS 计划开工日期 ,
           p.BuildEndDate AS 计划竣工日期 ,
           p.Principal AS 项目负责人 ,
           T.最早实际开工日期 AS 最早实际开工日期 ,
           T.最早实际竣工日期 AS 最早实际竣工日期 ,
           CASE WHEN p.Level = 3 THEN 1 ELSE 0 END AS 是否末级 ,
           sh.ProjCompanyName AS 项目公司名称 ,
           sh.BLShareRate AS 项目公司股权 ,
           sh.ShareholderList AS 合作方信息 ,
           p.JrSaleArea AS 计容可售面积 ,
           p.YXCpf AS 营销操盘方 ,
           p.TotalLandPrice AS 获取地价,
		   p.BeginDate as 获取时间,
		   p.ProjStatus  as 项目状态,
		   p.ManageModeName as 项目管理方式,
		   case when nc.ProjGUID is null then '否' else '是' end  是否录入合作业绩,
		   p.ProjCode_25 as 投管明源系统项目代码,
		   p.LMDJ 可售楼面价 ,	   
		   LandName 地块名 ,
		   Land.股权溢价 ,
		   Land.土地出让价 其中取得价 ,
		   '其中营销操盘方为：'+isnull(yxcpf,'空')+'；'+'其中工程操盘方为：'+isnull(gccpf,'空')+'；'+ '其中成本操盘方为：'+isnull(cbcpf,'空')+'；'+'其中技术操盘方为：'+isnull(jscpf,'空')+'；'+'其中开发操盘方为：'+isnull(kfcpf,'空')+'；'+'其中物业操盘方为：'+isnull(wycpf,'空') 	操盘条线 ,
		   Jarea 占地面积,
		   ksarea.住宅类产品可售面积 住宅可售面积,
		   ksarea.商办类产品可售面积 商办可售面积,
		   销售车位个数,
		   自持面积,
		   累计开工可售面积,
		   累计开工自持面积,
		   PartnerName as 合作方简称,
		   city_lfh 城市六分化,
		   project_wfl 项目五分类,
		   p.JRLMJ 计容楼面价,
		   是否对等投入,
		   是否对等分配,
		   p.ConstructStatus 建设状态,
           p.salestatus as 销售状态,
		   p.RegisteredAmount 注册资本 , 
		   p.GCCpf 工程操盘方 ,
		   p.WYCpf 物业操盘方, 
		   p.JSCpf 技术操盘方 ,
		   p.CBCpf 成本操盘方,
		   p.KFCpf 开发操盘方,
		   p.kgcpf as 客关操盘方,
		   CASE WHEN YEAR(ISNULL(p.BeginDate,'1999-01-01')) = 2022 THEN '增量' WHEN  YEAR(ISNULL(p.BeginDate,'1999-01-01')) < 2022 THEN '存量' ELSE  '新增量' end  增量存量分类,
		   p.kfsx
    INTO   #dw_d_TopProject
    FROM   [HighData_prod].dbo.data_wide_dws_mdm_Project p --分期；level：2:一级项目，3：分期  
		   --获取地块名
		   left join (
		    SELECT   ProjGUID ,sum(isnull(StockPremium,0)) as 股权溢价,sum(isnull(LandTransferFee,0)) as 土地出让价,max(IsEqalInput)是否对等投入,max(IsEqalAllocation)是否对等分配,
                      ( SELECT STUFF(
                               (   SELECT DISTINCT
                                          ';' + sh.LandName 
                                   FROM   [HighData_prod].dbo.data_wide_mdm_Project2Land sh
                                   WHERE  sh.ProjGUID = land.ProjGUID
                                   FOR XML PATH('')) ,
                               1 ,
                               1 ,
                               '')) AS LandName
               FROM   [HighData_prod].dbo.data_wide_mdm_Project2Land land 
			   group by ProjGUID
		   ) land on p.ProjGUID = land.ProjGUID
		   --获取可售面积
		   left join (
		   SELECT    ParentProjGUID as projguid, sum(HoldArea) as 自持面积,sum(case when factbegindate is not null then isnull(UpSaleArea,0)+isnull(downSaleArea,0) else 0 end) as 累计开工可售面积,
sum(case when factbegindate is not null then isnull(HoldArea,0) else 0 end) as 累计开工自持面积,
SUM(CASE WHEN TopProductTypeName IN ('住宅', '别墅', '高级住宅') THEN isnull(ld.zksmj,0) ELSE 0 END)  住宅类产品可售面积 , 
SUM(CASE WHEN TopProductTypeName not IN ('住宅', '别墅', '高级住宅', '地下室/车库') THEN isnull(ld.zksmj,0) ELSE 0 END)  商办类产品可售面积
FROM  data_wide_dws_mdm_Building Pb 
left join data_wide_dws_s_p_lddbamj ld on ld.salebldguid = pb.buildingguid and datediff(dd,qxdate,getdate()) = 0
where BldType = '产品楼栋'  
GROUP BY ParentProjGUID
		   ) ksarea on ksarea.projguid = p.ProjGUID
           LEFT JOIN
           (   SELECT DISTINCT
                      ProjGUID ,
                      ProjCompanyName ,
                      BLShareRate ,
                      ( SELECT STUFF(
                               (   SELECT DISTINCT
                                          ',' + sh.ShareholderName + '('
                                          + CONVERT(VARCHAR(20), ROUND(CONVERT(DECIMAL(18, 2), ShareRate), 2)) + '%)'
                                   FROM   [HighData_prod].dbo.data_wide_s_ProjShareholder sh
                                   WHERE  sh.ProjGUID = spsh.ProjGUID
                                   FOR XML PATH('')) ,
                               1 ,
                               1 ,
                               '')) AS ShareholderList
               FROM   [HighData_prod].dbo.data_wide_s_ProjShareholder spsh ) sh ON sh.ProjGUID = p.ProjGUID --合作方信息
           INNER JOIN [HighData_prod].dbo.data_wide_dws_s_Dimension_Organization do ON do.OrgGUID = p.BUGUID
                                                                                       AND do.OrganizationType = '平台公司'
                                                                                       AND do.IsEndCompany = 1
           LEFT JOIN [HighData_prod].dbo.data_wide_dws_s_Dimension_Organization do1 ON do1.OrgGUID = p.XMSSCSGSGUID
                                                                                       AND ( do.DevelopmentCompanyGUID = do1.DevelopmentCompanyGUID OR do1.Level = 3 ) --华南公司是四级架构
           LEFT JOIN
           (   SELECT   p.ProjGUID AS 项目GUID ,
                        p.ProjName AS 项目分期名称 ,
                        MIN(CASE WHEN YEAR(bl.FactBeginDate) < 1901 OR bl.FactBeginDate IS NULL THEN NULL ELSE
                                                                                                              ISNULL(
                                                                                                                  bl.FactBeginDate ,
                                                                                                                  0)END) AS 最早实际开工日期 ,
                        MIN(CASE WHEN YEAR(bl.FactFinishDate) < 1901 OR bl.FactFinishDate IS NULL THEN NULL ELSE
                                                                                                                ISNULL(
                                                                                                                    bl.FactFinishDate ,
                                                                                                                    0)END) AS 最早实际竣工日期
               FROM     [HighData_prod].dbo.data_wide_dws_mdm_Building bl
                        INNER JOIN [HighData_prod].dbo.data_wide_dws_mdm_Project p ON bl.ParentProjGUID = p.ProjGUID
               WHERE    p.Level = 2
                        AND p.ProjGUID IS NOT NULL
               GROUP BY p.ProjGUID ,
                        p.ProjName ) T ON T.项目GUID = p.ProjGUID
			left join (select distinct projguid from  data_wide_s_NoControl) nc on nc.ProjGUID = p.ProjGUID
			left join (select ProjGUID,sum(zksts) as 销售车位个数 from data_wide_dws_s_p_lddbamj where datediff(day,qxdate,getdate())=0 
			and ProductType='地下室/车库' group by ProjGUID)  xscw on  p.ProjGUID=xscw.ProjGUID
	WHERE  p.Level = 2
           AND p.ProjGUID IS NOT NULL;



    --删除dw_d_TopProject 表
    TRUNCATE TABLE dbo.dw_d_TopProject;

    --将临时表插入到dw_d_TopProject表
    INSERT INTO dbo.dw_d_TopProject 
	SELECT * FROM #dw_d_TopProject  

    --删除临时表
    TRUNCATE TABLE #dw_d_TopProject;
    DROP TABLE #dw_d_TopProject;

END; 
 