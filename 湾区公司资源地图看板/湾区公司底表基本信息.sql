--获取产品楼栋层级的技术指标，并循环更新工程楼栋->业态->项目->区域公司->公司的数据
SELECT  do.OrganizationName ,
        pb.ParentProjGUID ,
        pb.GCBldGUID ,
        pb.BuildingGUID ,
        pb.TopProductTypeName ,
        SUM(ISNULL(pb.CountRjlArea, 0)) AS 总计容面积 ,
        SUM(CASE WHEN pb.TopProductTypeName IN ('地下室/车库') THEN 0 ELSE ISNULL(pb.CountRjlArea, 0)END) 地上计容面积 ,
        SUM(CASE WHEN pb.TopProductTypeName IN ('地下室/车库') AND   pb.issalebld = 1 AND pb.ishold = 0 THEN ISNULL(pb.BuildArea, 0)ELSE 0 END) 可售车库面积 ,
        SUM(CASE WHEN pb.TopProductTypeName IN ('地下室/车库') AND   pb.issalebld = 1 AND pb.ishold = 0 THEN ISNULL(pb.setnum, 0)ELSE 0 END) 可售车位个数 ,
        SUM(CASE WHEN pb.ProductTypeName IN ('人防车库') THEN ISNULL(pb.BuildArea, 0)ELSE 0 END) 人防车库面积 ,
        SUM(CASE WHEN pb.ProductTypeName IN ('人防车库') THEN ISNULL(pb.setnum, 0)ELSE 0 END) 人防车位个数 ,
        SUM(ISNULL(pb.UpBuildArea, 0) + ISNULL(DownBuildArea, 0)) 总建筑面积 ,
        SUM(ISNULL(pb.UpBuildArea, 0)) 地上建筑面积 ,
        SUM(ISNULL(pb.DownBuildArea, 0)) 地下建筑面积 ,
        SUM(ISNULL(pb.UpSaleArea, 0) + ISNULL(pb.DownSaleArea, 0)) 可售面积 ,
        SUM(ISNULL(pb.HoldArea, 0)) 自持面积 ,
        SUM(ISNULL(pb.setnum, 0)) 户数 ,
        --获取工程楼栋的在建面积，即实际开工时间不为空，且竣工备案时间为空的
        SUM(CASE WHEN sjzskgdate IS NOT NULL AND sjjgbadate IS NULL THEN ISNULL(pb.BuildArea, 0)ELSE 0 END) 在建建筑面积 ,
        SUM(CASE WHEN pb.TopProductTypeName IN ('住宅', '高级住宅') AND   issalebld = 1 THEN ISNULL(pb.setnum, 0)ELSE 0 END) AS 住宅总可售户数 ,
        SUM(CASE WHEN pb.IsHold = 1 THEN ISNULL(pb.UpBuildArea, 0)ELSE 0 END) AS 自持地上面积 ,
        SUM(CASE WHEN pb.IsHold = 1 AND pb.TopProductTypeName NOT IN ('地下室/车库') THEN ISNULL(pb.DownBuildArea, 0)ELSE 0 END) AS 自持地下面积不含车库 ,
        SUM(CASE WHEN pb.IsHold = 1 AND pb.TopProductTypeName IN ('地下室/车库') THEN ISNULL(pb.BuildArea, 0)ELSE 0 END) AS 自持车位面积 ,
        SUM(CASE WHEN pb.IsHold = 1 AND pb.TopProductTypeName IN ('地下室/车库') THEN ISNULL(pb.setnum, 0)ELSE 0 END) AS 自持车位个数 ,
        SUM(CASE WHEN pb.IsHold = 0 AND issalebld = 0 AND   pb.TopProductTypeName IN ('地下室/车库') THEN ISNULL(pb.setnum, 0)ELSE 0 END) AS 配套车位个数 ,
        SUM(CASE WHEN pb.IsHold = 0 AND issalebld = 0 AND   pb.TopProductTypeName IN ('地下室/车库') THEN ISNULL(pb.BuildArea, 0)ELSE 0 END) AS 配套车位面积
INTO    #js
FROM    data_wide_dws_mdm_building pb
        INNER JOIN data_wide_dws_mdm_Project pj ON pb.ParentProjGUID = pj.ProjGUID
        INNER JOIN data_wide_dws_s_Dimension_Organization do ON do.OrgGUID = pj.BUGUID
        LEFT JOIN data_wide_dws_s_p_lddbamj ld ON ld.salebldguid = pb.BuildingGUID AND DATEDIFF(dd, qxdate, GETDATE()) = 0
WHERE   do.OrganizationName IN ('湾区公司', '上海公司','湖南公司') AND pb.bldtype = '产品楼栋'
GROUP BY pb.ParentProjGUID ,
         pb.GCBldGUID ,
         pb.BuildingGUID ,
         pb.TopProductTypeName ,
         do.OrganizationName;

--初始化结果临时表
SELECT  o.组织架构父级ID ,
        o.组织架构id ,
        o.组织架构名称 ,
        7 AS 组织架构类型 ,
        j.总计容面积 ,
        j.地上计容面积 ,
        j.可售车库面积 ,
        j.可售车位个数 ,
        j.人防车库面积 ,
        j.人防车位个数 ,
        j.总建筑面积 ,
        j.地上建筑面积 ,
        j.地下建筑面积 ,
        j.可售面积 ,
        j.自持面积 ,
        j.户数 ,
        CONVERT(DECIMAL(16, 2), 0.0) 地价 ,
        NULL 占地面积 ,
        NULL 项目数量 ,
        j.在建建筑面积 ,
        NULL 在建项目数量 ,
        j.住宅总可售户数 ,
        j.自持地上面积 ,
        j.自持地下面积不含车库 ,
        j.自持车位面积 ,
        j.自持车位个数 ,
        j.配套车位个数 ,
        j.配套车位面积
INTO    #temp
FROM    data_wide_dws_s_WqBaseStatic_Organization o
        LEFT JOIN #js j ON o.组织架构id = j.BuildingGUID
WHERE   o.组织架构类型 = 7;

--循环更新数据
DECLARE @baseinfo INT;

SET @baseinfo = 6;

WHILE(@baseinfo > 0)
    BEGIN
        INSERT INTO #temp
        SELECT  o.组织架构父级ID ,
                o.组织架构id ,
                o.组织架构名称 ,
                o.组织架构类型 ,
                SUM(ISNULL(j.总计容面积, 0)) AS 总计容面积 ,
                SUM(ISNULL(j.地上计容面积, 0)) AS 地上计容面积 ,
                SUM(ISNULL(j.可售车库面积, 0)) AS 可售车库面积 ,
                SUM(ISNULL(j.可售车位个数, 0)) AS 可售车位个数 ,
                SUM(ISNULL(j.人防车库面积, 0)) AS 人防车库面积 ,
                SUM(ISNULL(j.人防车位个数, 0)) AS 人防车位个数 ,
                SUM(ISNULL(j.总建筑面积, 0)) AS 总建筑面积 ,
                SUM(ISNULL(j.地上建筑面积, 0)) AS 地上建筑面积 ,
                SUM(ISNULL(j.地下建筑面积, 0)) AS 地下建筑面积 ,
                SUM(ISNULL(j.可售面积, 0)) AS 可售面积 ,
                SUM(ISNULL(j.自持面积, 0)) AS 自持面积 ,
                SUM(ISNULL(j.户数, 0)) AS 户数 ,
                SUM(ISNULL(j.地价, 0)) + ISNULL(p.TotalLandPrice, 0) AS 地价 ,
                SUM(ISNULL(j.占地面积, 0)) + ISNULL(p.BuildOccupyArea, 0) AS 占地面积 , --占地面积只有项目层级有
                SUM(ISNULL(j.项目数量, 0)) + ISNULL(CASE WHEN o.组织架构类型 = 3 THEN 1 ELSE 0 END, 0) AS 项目数量 ,
                SUM(ISNULL(j.在建建筑面积, 0)) AS 在建建筑面积 ,
                SUM(ISNULL(j.在建项目数量, 0)) + ISNULL(COUNT(DISTINCT CASE WHEN o.组织架构类型 = 3 AND j.在建建筑面积 <> 0 THEN p.ProjGUID ELSE NULL END), 0) AS 在建项目数量 ,
                SUM(ISNULL(j.住宅总可售户数, 0)) AS 住宅总可售户数 ,
                SUM(ISNULL(j.自持地上面积, 0)) AS 自持地上面积 ,
                SUM(ISNULL(j.自持地下面积不含车库, 0)) AS 自持地下面积不含车库 ,
                SUM(ISNULL(j.自持车位面积, 0)) AS 自持车位面积 ,
                SUM(ISNULL(j.自持车位个数, 0)) AS 自持车位个数 ,
                SUM(ISNULL(j.配套车位个数, 0)) AS 配套车位个数 ,
                SUM(ISNULL(j.配套车位面积, 0)) AS 配套车位面积
        FROM    data_wide_dws_s_WqBaseStatic_Organization o
                LEFT JOIN #temp j ON o.组织架构id = j.组织架构父级id
                LEFT JOIN data_wide_dws_mdm_project p ON p.ProjGUID = o.组织架构id
        WHERE   o.组织架构类型 = @baseinfo
        GROUP BY o.组织架构父级ID ,
                 o.组织架构id ,
                 o.组织架构名称 ,
                 o.组织架构类型 ,
                 ISNULL(p.BuildOccupyArea, 0) ,
                 p.ConstructStatus ,
                 p.buildarea ,
                 p.TotalLandPrice;

        SET @baseinfo = @baseinfo - 1;
    END;

--更新项目层级的基本信息
--获取项目基本属性
SELECT  O.组织架构ID ,
        O.组织架构名称 ,
        O.组织架构类型 ,
        O.组织架构编码 ,
        do.organizationname 区域 ,
        pj.city 项目所属城市 ,
        pj.BelongAreaName 所属镇街 ,
        tb.销售片区 ,   --填报
        O.项目guid ,
        pj.ProjCode_25 明源代码 ,
        pj.TgProjCode 投管代码 ,
        pj.ProjName 项目名称 ,
        land.LandNameList 地块名 ,
        pj.SpreadName 项目推广名 ,
        j.地价 / 10000.0 AS 地价 ,
        tb.项目标签 ,   --填报
        pj.BeginDate 获取时间 ,
        pj.XMHQFS 获取方式 ,
        hzf.ShareholderName 合作方 ,
        pj.DiskFlag 是否操盘 ,
        CASE WHEN pj.GenreTableType IN ('合作方并表', '都不并表') AND O.组织架构类型 NOT IN (1, 2) THEN '否' ELSE '是' END 是否并表 ,
        pj.RightsRate 股权比例 ,
        pj.ConstructStatus AS 工程状态 ,
        O.业态 ,
        O.产品名称 ,
        O.工程楼栋名称 AS 工程楼栋 ,
        O.产品楼栋名称 产品楼栋 ,
        j.占地面积 ,
        pj.Rjl 容积率 ,
        j.总计容面积 ,
        j.地上计容面积 ,
        j.可售车库面积 ,
        j.可售车位个数 ,
        j.人防车库面积 ,
        j.人防车位个数 ,
        j.总建筑面积 ,
        j.地上建筑面积 ,
        j.地下建筑面积 ,
        j.可售面积 ,
        j.自持面积 ,
        j.户数 ,
        j.项目数量 ,
        j.在建项目数量 ,
        j.在建建筑面积 ,
        CASE WHEN O.组织架构类型 = 3 THEN pj.LMDJ ELSE NULL END 可售楼面价 ,
        --获取公司董事信息
        CASE WHEN O.组织架构类型 = 3 THEN
                 REPLACE(ISNULL(MyDirectors + ';', '') + ISNULL(MyDirectors1 + ';', '') + ISNULL(MyDirectors2 + ';', '') +
				 ISNULL(MyDirectors3 + ';', '') + ISNULL(MyDirectors4 + ';', '')
                 + ISNULL(MyDirectors5 + ';', '') + ISNULL(MyDirectors6 + ';', '') + ISNULL(MyDirectors7 + ';', '') 
				 + ISNULL(MyDirectors8 + ';', ''),';;','')
             ELSE ''
        END 董事 ,
        CASE WHEN O.组织架构类型 = 3 THEN Chairman ELSE '' END 董事长 ,
        CASE WHEN O.组织架构类型 = 3 THEN GeneralManager ELSE '' END 总经理 ,
        CASE WHEN O.组织架构类型 = 3 THEN LegalRepresentative ELSE '' END 法定代表人 ,
        CASE WHEN O.组织架构类型 = 3 THEN
                 REPLACE(ISNULL(Supervisor + ';', '') + ISNULL(Supervisor1 + ';', '') + ISNULL(Supervisor2 + ';', '') 
                 + ISNULL(Supervisor3 + ';', '') + ISNULL(Supervisor4 + ';', ''),';;','')
             ELSE ''
        END 监事 ,
        pj.ProjCompanyName AS 项目公司名 ,
        pj.FoundDate AS 成立日期 ,
        pj.RegisteredAmount AS 注册资本 ,
        pj.NewPauliRealPayment_ZB AS 实缴资本 ,
        pj.PauliConfis AS 保利方认缴资本 ,
        pj.projstatus AS 项目状态 ,
        pj.YXCpf AS 营销操盘方 ,
        pj.GCCpf AS 工程操盘方 ,
        pj.CBCpf AS 成本操盘方 ,
        pj.JSCpf AS 技术操盘方 ,
        pj.KFCpf AS 开发操盘方 ,
        pj.WYCpf AS 物业操盘方 ,
        pj.KGCPF AS 客关操盘方 ,
        pj.bbf AS 并表方 ,
        j.住宅总可售户数 ,
        j.自持地上面积 ,
        j.自持地下面积不含车库 ,
        j.自持车位面积 ,
        j.自持车位个数 ,
        j.配套车位个数 ,
        j.配套车位面积,
		CASE WHEN YEAR(pj.BeginDate) > 2022 THEN '新增量' WHEN YEAR(pj.BeginDate) = 2022 THEN '增量' ELSE '存量'  END   AS 存量增量
FROM    data_wide_dws_s_WqBaseStatic_Organization O
        LEFT JOIN data_wide_dws_mdm_project pj ON O.项目guid = pj.projguid
        LEFT JOIN data_wide_dws_s_Dimension_Organization do ON do.orgguid = pj.XMSSCSGSGUID
        --获取技术指标
        LEFT JOIN #temp j ON j.组织架构id = O.组织架构id
        --获取土地列表
        LEFT JOIN(SELECT    ProjGUID ,
                            STUFF((SELECT   ';' + LandName
                                   FROM data_wide_mdm_Project2Land
                                   WHERE ProjGUID = proj2Land.ProjGUID
                                  FOR XML PATH('')), 1, 1, '') AS LandNameList
                  FROM  data_wide_mdm_Project2Land proj2Land
                  GROUP BY proj2Land.ProjGUID) land ON O.项目guid = land.projguid
        --获取合作方
        LEFT JOIN(SELECT    ParentProjGUID ,
                            STUFF((SELECT   DISTINCT '；' + ISNULL(ShareholderName + ':', '空') + ISNULL(CONVERT(VARCHAR(20), CONVERT(DECIMAL(18, 2), ShareRate)), '空') + '%'
                                   FROM data_wide_s_ProjShareholder
                                   WHERE ParentProjGUID = hzf.ParentProjGUID
                                  FOR XML PATH('')), 1, 1, '') AS ShareholderName
                  FROM  data_wide_s_ProjShareholder hzf
                  GROUP BY hzf.ParentProjGUID) hzf ON O.项目guid = hzf.ParentProjGUID
        --获取填报信息
        LEFT JOIN data_tb_WqBaseStatic_Projinfo tb ON tb.组织架构ID = O.组织架构id
        --获取项目公司对应的董事信息
        LEFT JOIN [172.16.4.141].erp25.dbo.mdm_project tgpj ON tgpj.projguid = pj.ProjGUID
        LEFT JOIN [172.16.4.141].erp25.dbo.p_developmentcompany dsinfo ON dsinfo.DevelopmentCompanyGUID = tgpj.ProjCompanyGUID
ORDER BY O.组织架构类型 ,
         O.组织架构编码;

DROP TABLE #js ,
           #temp;
