-- 20240622 山西公司项目去化看板调整，标准户型采用填报数据处理
-- 将山西公司的标准户型填报信息插入临时表
-- 取最新的填报版本
-- 增加剩余货值认购口径字段
SELECT  *
INTO    #data_tb_SaleBldHxInfoBySx
FROM(SELECT ROW_NUMBER() OVER (PARTITION BY 产品楼栋GUID ORDER BY batch_update_time DESC) AS num ,
            *
     FROM   [172.16.4.161].[HighData_prod].dbo.data_tb_SaleBldHxInfoBySx) t
WHERE   t.num = 1;

SELECT  项目GUID ,
        项目名称 ,
        分期GUID ,
        分期名称 ,
        工程楼栋GUID ,
        工程楼栋名称 ,
        产品楼栋GUID ,
        产品楼栋名称 ,
        产品类型 ,
        产品名称 ,
        户型1_房 AS 房 ,
        户型1_厅 AS 厅 ,
        户型1_卫 AS 卫 ,
        户型1_阳台 AS 阳台 ,
        户型1_单套面积 AS 单套面积 ,
        户型1_精装成本 AS 精装成本
INTO    #SxRoomStr
FROM    #data_tb_SaleBldHxInfoBySx
WHERE   户型1_房 IS NOT NULL OR 户型1_厅 IS NOT NULL OR   户型1_卫 IS NOT NULL OR 户型1_阳台 IS NOT NULL OR  户型1_单套面积 IS NOT NULL
UNION ALL
SELECT  项目GUID ,
        项目名称 ,
        分期GUID ,
        分期名称 ,
        工程楼栋GUID ,
        工程楼栋名称 ,
        产品楼栋GUID ,
        产品楼栋名称 ,
        产品类型 ,
        产品名称 ,
        户型2_房 AS 房 ,
        户型2_厅 AS 厅 ,
        户型2_卫 AS 卫 ,
        户型2_阳台 AS 阳台 ,
        户型2_单套面积 AS 单套面积 ,
        户型2_精装成本 AS 精装成本
FROM    #data_tb_SaleBldHxInfoBySx
WHERE   户型2_房 IS NOT NULL OR 户型2_厅 IS NOT NULL OR   户型2_卫 IS NOT NULL OR 户型2_阳台 IS NOT NULL OR  户型2_单套面积 IS NOT NULL
UNION ALL
SELECT  项目GUID ,
        项目名称 ,
        分期GUID ,
        分期名称 ,
        工程楼栋GUID ,
        工程楼栋名称 ,
        产品楼栋GUID ,
        产品楼栋名称 ,
        产品类型 ,
        产品名称 ,
        户型3_房 AS 房 ,
        户型3_厅 AS 厅 ,
        户型3_卫 AS 卫 ,
        户型3_阳台 AS 阳台 ,
        户型3_单套面积 AS 单套面积 ,
        户型3_精装成本 AS 精装成本
FROM    #data_tb_SaleBldHxInfoBySx
WHERE   户型3_房 IS NOT NULL OR 户型3_厅 IS NOT NULL OR   户型3_卫 IS NOT NULL OR 户型3_阳台 IS NOT NULL OR  户型3_单套面积 IS NOT NULL
UNION ALL
SELECT  项目GUID ,
        项目名称 ,
        分期GUID ,
        分期名称 ,
        工程楼栋GUID ,
        工程楼栋名称 ,
        产品楼栋GUID ,
        产品楼栋名称 ,
        产品类型 ,
        产品名称 ,
        户型4_房 AS 房 ,
        户型4_厅 AS 厅 ,
        户型4_卫 AS 卫 ,
        户型4_阳台 AS 阳台 ,
        户型4_单套面积 AS 单套面积 ,
        户型4_精装成本 AS 精装成本
FROM    #data_tb_SaleBldHxInfoBySx
WHERE   户型4_房 IS NOT NULL OR 户型4_厅 IS NOT NULL OR   户型4_卫 IS NOT NULL OR 户型4_阳台 IS NOT NULL OR  户型4_单套面积 IS NOT NULL
UNION ALL
SELECT  项目GUID ,
        项目名称 ,
        分期GUID ,
        分期名称 ,
        工程楼栋GUID ,
        工程楼栋名称 ,
        产品楼栋GUID ,
        产品楼栋名称 ,
        产品类型 ,
        产品名称 ,
        户型5_房 AS 房 ,
        户型5_厅 AS 厅 ,
        户型5_卫 AS 卫 ,
        户型5_阳台 AS 阳台 ,
        户型5_单套面积 AS 单套面积 ,
        户型5_精装成本 AS 精装成本
FROM    #data_tb_SaleBldHxInfoBySx
WHERE   户型5_房 IS NOT NULL OR 户型5_厅 IS NOT NULL OR   户型5_卫 IS NOT NULL OR 户型5_阳台 IS NOT NULL OR  户型5_单套面积 IS NOT NULL
UNION ALL
SELECT  项目GUID ,
        项目名称 ,
        分期GUID ,
        分期名称 ,
        工程楼栋GUID ,
        工程楼栋名称 ,
        产品楼栋GUID ,
        产品楼栋名称 ,
        产品类型 ,
        产品名称 ,
        户型6_房 AS 房 ,
        户型6_厅 AS 厅 ,
        户型6_卫 AS 卫 ,
        户型6_阳台 AS 阳台 ,
        户型6_单套面积 AS 单套面积 ,
        户型6_精装成本 AS 精装成本
FROM    #data_tb_SaleBldHxInfoBySx
WHERE   户型6_房 IS NOT NULL OR 户型6_厅 IS NOT NULL OR   户型6_卫 IS NOT NULL OR 户型6_阳台 IS NOT NULL OR  户型6_单套面积 IS NOT NULL
UNION ALL
SELECT  项目GUID ,
        项目名称 ,
        分期GUID ,
        分期名称 ,
        工程楼栋GUID ,
        工程楼栋名称 ,
        产品楼栋GUID ,
        产品楼栋名称 ,
        产品类型 ,
        产品名称 ,
        户型7_房 AS 房 ,
        户型7_厅 AS 厅 ,
        户型7_卫 AS 卫 ,
        户型7_阳台 AS 阳台 ,
        户型7_单套面积 AS 单套面积 ,
        户型7_精装成本 AS 精装成本
FROM    #data_tb_SaleBldHxInfoBySx
WHERE   户型7_房 IS NOT NULL OR 户型7_厅 IS NOT NULL OR   户型7_卫 IS NOT NULL OR 户型7_阳台 IS NOT NULL OR  户型7_单套面积 IS NOT NULL
UNION ALL
SELECT  项目GUID ,
        项目名称 ,
        分期GUID ,
        分期名称 ,
        工程楼栋GUID ,
        工程楼栋名称 ,
        产品楼栋GUID ,
        产品楼栋名称 ,
        产品类型 ,
        产品名称 ,
        户型8_房 AS 房 ,
        户型8_厅 AS 厅 ,
        户型8_卫 AS 卫 ,
        户型8_阳台 AS 阳台 ,
        户型8_单套面积 AS 单套面积 ,
        户型8_精装成本 AS 精装成本
FROM    #data_tb_SaleBldHxInfoBySx
WHERE   户型8_房 IS NOT NULL OR 户型8_厅 IS NOT NULL OR   户型8_卫 IS NOT NULL OR 户型8_阳台 IS NOT NULL OR  户型8_单套面积 IS NOT NULL
UNION ALL
SELECT  项目GUID ,
        项目名称 ,
        分期GUID ,
        分期名称 ,
        工程楼栋GUID ,
        工程楼栋名称 ,
        产品楼栋GUID ,
        产品楼栋名称 ,
        产品类型 ,
        产品名称 ,
        户型9_房 AS 房 ,
        户型9_厅 AS 厅 ,
        户型9_卫 AS 卫 ,
        户型9_阳台 AS 阳台 ,
        户型9_单套面积 AS 单套面积 ,
        户型9_精装成本 AS 精装成本
FROM    #data_tb_SaleBldHxInfoBySx
WHERE   户型9_房 IS NOT NULL OR 户型9_厅 IS NOT NULL OR   户型9_卫 IS NOT NULL OR 户型9_阳台 IS NOT NULL OR  户型9_单套面积 IS NOT NULL
UNION ALL
SELECT  项目GUID ,
        项目名称 ,
        分期GUID ,
        分期名称 ,
        工程楼栋GUID ,
        工程楼栋名称 ,
        产品楼栋GUID ,
        产品楼栋名称 ,
        产品类型 ,
        产品名称 ,
        户型10_房 AS 房 ,
        户型10_厅 AS 厅 ,
        户型10_卫 AS 卫 ,
        户型10_阳台 AS 阳台 ,
        户型10_单套面积 AS 单套面积 ,
        户型10_精装成本 AS 精装成本
FROM    #data_tb_SaleBldHxInfoBySx
WHERE   户型10_房 IS NOT NULL OR   户型10_厅 IS NOT NULL OR   户型10_卫 IS NOT NULL OR   户型10_阳台 IS NOT NULL OR  户型10_单套面积 IS NOT NULL
UNION ALL
SELECT  项目GUID ,
        项目名称 ,
        分期GUID ,
        分期名称 ,
        工程楼栋GUID ,
        工程楼栋名称 ,
        产品楼栋GUID ,
        产品楼栋名称 ,
        产品类型 ,
        产品名称 ,
        户型11_房 AS 房 ,
        户型11_厅 AS 厅 ,
        户型11_卫 AS 卫 ,
        户型11_阳台 AS 阳台 ,
        户型11_单套面积 AS 单套面积 ,
        户型11_精装成本 AS 精装成本
FROM    #data_tb_SaleBldHxInfoBySx
WHERE   户型11_房 IS NOT NULL OR   户型11_厅 IS NOT NULL OR   户型11_卫 IS NOT NULL OR   户型11_阳台 IS NOT NULL OR  户型11_单套面积 IS NOT NULL
UNION ALL
SELECT  项目GUID ,
        项目名称 ,
        分期GUID ,
        分期名称 ,
        工程楼栋GUID ,
        工程楼栋名称 ,
        产品楼栋GUID ,
        产品楼栋名称 ,
        产品类型 ,
        产品名称 ,
        户型12_房 AS 房 ,
        户型12_厅 AS 厅 ,
        户型12_卫 AS 卫 ,
        户型12_阳台 AS 阳台 ,
        户型12_单套面积 AS 单套面积 ,
        户型12_精装成本 AS 精装成本
FROM    #data_tb_SaleBldHxInfoBySx
WHERE   户型12_房 IS NOT NULL OR   户型12_厅 IS NOT NULL OR   户型12_卫 IS NOT NULL OR   户型12_阳台 IS NOT NULL OR  户型12_单套面积 IS NOT NULL;

-- 对于山西公司填报的标准面积段进行归集处理
-- 按照产品楼栋进行排序，排序第一标准户型开始面积段为0，排序最后的标准户型截止面积段为100000，其他排序中间的面积段取中间值
SELECT  项目GUID ,
        分期GUID ,
        工程楼栋GUID ,
        产品楼栋GUID ,
        房 ,
        厅 ,
        卫 ,
        阳台 ,
        单套面积 AS 标准户型面积段 ,
        精装成本 ,
        CASE WHEN rn = 1 THEN 0 ELSE convert(int,((ISNULL(lagArea, 0) + ISNULL(单套面积, 0)) + 1) / 2.0) END AS 标准户型开始面积段 ,
        CASE WHEN rn = maxrn THEN 100000 ELSE convert(int,((ISNULL(leadArea, 0) + ISNULL(单套面积, 0)) - 1) / 2.0 ) END AS 标准户型截止面积段
INTO    #SxBaseRoomStr
FROM(SELECT ROW_NUMBER() OVER (PARTITION BY 产品楼栋GUID ORDER BY 单套面积) AS rn ,
            COUNT(产品楼栋GUID) OVER (PARTITION BY 产品楼栋GUID) AS maxrn ,
            LAG(单套面积, 1, 0) OVER (PARTITION BY 产品楼栋GUID ORDER BY 单套面积) AS lagArea ,
            LEAD(单套面积, 1, 0) OVER (PARTITION BY 产品楼栋GUID ORDER BY 单套面积) AS leadArea ,
            *
     FROM   (SELECT DISTINCT   项目GUID ,
                               分期GUID ,
                               工程楼栋GUID ,
                               产品楼栋GUID ,
                               房 ,
                               厅 ,
                               卫 ,
                               阳台 ,
                               单套面积 ,
                               精装成本
             FROM   #SxRoomStr) r ) sta;

--获取户型的基本信息：总套数、总面积、已推未售套数、已推未售面积、已售套数、已售面积、剩余套数、剩余面积、达预售形象未售面积、达预售形象未售套数、已开工未售套数、已开工未售面积、取证未推未售面积、取证未推未售套数
--1、缓存楼栋节点信息：楼栋实际开盘时间以及达到预售形象的实际完成时间
SELECT  ld.projguid ,
        sb.SaleBldGUID ,
        ld.SjDdysxxDate ,
        ld.SJkpxsDate ,
        ld.SjYsblDate ,
        ld.SJzskgdate ,
        ld.sjjgbadate ,
        ld.yjDdysxxDate ,
        ld.yJkpxsDate ,
        ld.yjYsblDate ,
        ld.yJzskgdate ,
        ld.yjjgbadate ,
        ld.ProductType ,
        ld.ProductName ,
        ld.BusinessType ,   --商品类型
        ld.Standard ,        --装修标准
		ld.ycprice
INTO    #ldjd
FROM    mdm_salebuild sb
        INNER JOIN p_lddbamj ld ON sb.salebldguid = ld.salebldguid
WHERE   DATEDIFF(dd, ld.qxdate, GETDATE()) = 0;

--2、获取已建房间的户型信息
SELECT  pp.projguid ,
        r.bldguid ,
        r.producttype ,
        r.ProductName ,
        r.RoomGUID ,
        r.thdate ,
        r.bldarea ,
		r.hszj, -- 回收总价
        r.status ,
        hx.HxAreaHgNumSettingGUID ,
        CASE WHEN r.RoomStru LIKE '%一室%' OR r.RoomStru LIKE '%1室%' OR   r.RoomStru LIKE '%单室%' OR   r.RoomStru LIKE '%单房%' OR   r.RoomStru LIKE '%一房%' OR   r.RoomStru LIKE '%1房%' THEN 1
             WHEN r.RoomStru LIKE '%两房%' OR r.RoomStru LIKE '%两室%' OR   r.RoomStru LIKE '%二室%' OR   r.RoomStru LIKE '%2室%' OR   r.RoomStru LIKE '%双室%' OR   r.RoomStru LIKE '%二房%'
                  OR   r.RoomStru LIKE '%双房%' OR   r.RoomStru LIKE '%2房%' THEN 2
             WHEN r.RoomStru LIKE '%三室%' OR r.RoomStru LIKE '%3室%' OR   r.RoomStru LIKE '%三房%' OR   r.RoomStru LIKE '%3房%' THEN 3
             WHEN r.RoomStru LIKE '%四室%' OR r.RoomStru LIKE '%4室%' OR   r.RoomStru LIKE '%四房%' OR   r.RoomStru LIKE '%4房%' THEN 4
             WHEN r.RoomStru LIKE '%五室%' OR r.RoomStru LIKE '%5室%' OR   r.RoomStru LIKE '%五房%' OR   r.RoomStru LIKE '%5房%' THEN 5
             WHEN r.RoomStru LIKE '%六室%' OR r.RoomStru LIKE '%6室%' OR   r.RoomStru LIKE '%六房%' OR   r.RoomStru LIKE '%6房%' THEN 6
             WHEN r.RoomStru LIKE '%七室%' OR r.RoomStru LIKE '%7室%' OR   r.RoomStru LIKE '%七房%' OR   r.RoomStru LIKE '%7房%' THEN 7
             WHEN r.RoomStru LIKE '%八室%' OR r.RoomStru LIKE '%8室%' OR   r.RoomStru LIKE '%八房%' OR   r.RoomStru LIKE '%8房%' THEN 8
             WHEN r.RoomStru LIKE '%九室%' OR r.RoomStru LIKE '%9室%' OR   r.RoomStru LIKE '%九房%' OR   r.RoomStru LIKE '%9房%' THEN 9
             WHEN r.RoomStru LIKE '%十室%' OR r.RoomStru LIKE '%10室%' OR  r.RoomStru LIKE '%十房%' OR   r.RoomStru LIKE '%10房%' THEN 10
             ELSE -1
        END RoomNum ,   --几房
        CASE WHEN r.RoomStru LIKE '%零厅%' OR r.RoomStru LIKE '%0厅%' THEN 0
             WHEN r.RoomStru LIKE '%一厅%' OR r.RoomStru LIKE '%1厅%' THEN 1
             WHEN r.RoomStru LIKE '%二厅%' OR r.RoomStru LIKE '%2厅%' OR   r.RoomStru LIKE '%两厅%' THEN 2
             WHEN r.RoomStru LIKE '%三厅%' OR r.RoomStru LIKE '%3厅%' THEN 3
             WHEN r.RoomStru LIKE '%四厅%' OR r.RoomStru LIKE '%4厅%' THEN 4
             WHEN r.RoomStru LIKE '%五厅%' THEN 5
             ELSE -1
        END Hall ,      --几厅
        CASE WHEN r.RoomStru LIKE '%零卫%' OR r.RoomStru LIKE '%0卫%' THEN 0
             WHEN r.RoomStru LIKE '%一卫%' OR r.RoomStru LIKE '%1卫%' OR   r.RoomStru LIKE '%单卫%' THEN 1
             WHEN r.RoomStru LIKE '%1.5卫%' THEN 1.5
             WHEN r.RoomStru LIKE '%二卫%' OR r.RoomStru LIKE '%2卫%' OR   r.RoomStru LIKE '%双卫%' OR   r.RoomStru LIKE '%两卫%' THEN 2
             WHEN r.RoomStru LIKE '%2.5卫%' THEN 2.5
             WHEN r.RoomStru LIKE '%三卫%' OR r.RoomStru LIKE '%3卫%' THEN 3
             WHEN r.RoomStru LIKE '%四卫%' OR r.RoomStru LIKE '%4卫%' THEN 4
             WHEN r.RoomStru LIKE '%五卫%' OR (r.RoomStru LIKE '%5卫%' AND r.RoomStru NOT IN ('1.5卫', '2.5卫')) THEN 5
             WHEN r.RoomStru LIKE '六卫' OR   r.RoomStru LIKE '%6卫%' THEN 6
             WHEN r.RoomStru LIKE '%七卫%' OR r.RoomStru LIKE '%7卫%' THEN 7
             WHEN r.RoomStru LIKE '%八卫%' OR r.RoomStru LIKE '%8卫%' THEN 8
             ELSE -1
        END Toilet ,    --几卫
        CASE WHEN r.RoomStru LIKE '%0阳台%' THEN 0
             WHEN r.RoomStru LIKE '%1阳台%' OR r.RoomStru LIKE '%一阳台%' THEN 1
             WHEN r.RoomStru LIKE '%2阳台%' OR r.RoomStru LIKE '%两阳台%' OR r.RoomStru LIKE '%双阳台%' THEN 2
             WHEN r.RoomStru LIKE '%3阳台%' OR r.RoomStru LIKE '%三阳台%' THEN 3
             WHEN r.RoomStru LIKE '%4阳台%' THEN 4
             ELSE -1
        END Balcony     --几阳台 
INTO    #r
FROM    ERP25.dbo.ep_room r
        INNER JOIN p_Project p ON r.projguid = p.projguid
        INNER JOIN p_Project pp ON p.parentcode = pp.projcode
        LEFT JOIN dbo.p_HxSet hx ON r.BldGUID = hx.ProductBuildGUID AND hx.huxing = r.huxing AND   HxAreaHgNumSettingGUID IS NOT NULL
                                    AND  (r.ProjGUID <> 'F9D6FAC7-6131-E711-80BA-E61F13C57837' OR hx.BldArea <> hx.TnArea)		
WHERE   r.IsVirtualRoom = 0 AND r.producttype IN ('住宅', '高级住宅', '企业会所', '公寓','商业','地下室/车库','写字楼','企业会所');

--统计房间的货值情况
SELECT  r.projguid ,
        r.bldguid ,
        r.producttype ,
        r.ProductName ,
        jd.BusinessType ,
        jd.Standard ,
        r.HxAreaHgNumSettingGUID ,
        r.bldarea ,
        r.RoomNum ,
        r.Hall ,		
        CAST(r.Toilet AS REAL) Toilet ,
        r.Balcony ,
        CASE WHEN r.RoomNum = -1 THEN '' ELSE CAST(r.RoomNum AS VARCHAR(50)) + '房' END + CASE WHEN r.Hall = -1 THEN '' ELSE CAST(r.Hall AS VARCHAR(50)) + '厅' END
        + CASE WHEN r.Toilet = -1 THEN '' ELSE CAST(CAST(r.Toilet AS REAL) AS VARCHAR(50)) + '卫' END + CASE WHEN r.Balcony = -1 THEN '' ELSE CAST(r.Balcony AS VARCHAR(50)) + '阳台' END hxStru ,
        SUM(r.bldarea) zksmj ,
		sum(case when r.hszj = 0 then isnull(jd.ycprice,0)*r.bldarea else r.hszj end ) as hszj,
        COUNT(1) zksts ,
        --认购口径
        SUM(CASE WHEN r.status in ('签约','认购') THEN r.bldarea ELSE 0 END) ysmj_rg ,
        SUM(CASE WHEN r.status in ('签约','认购') THEN 1 ELSE 0 END) ysts_rg ,
        SUM(CASE WHEN r.status in ('签约','认购') THEN ISNULL(sc.JyTotal, 0)ELSE 0 END) ysje_rg ,
        --近三月认购情况
        SUM(CASE WHEN r.status in ('签约','认购') AND  so.qsdate between convert(varchar(10),dateadd(mm,-3,getdate()),120) and convert(varchar(10),dateadd(mm,-1,getdate()),120)  
        THEN isnull(sc.JyTotal,so.jytotal) ELSE 0 END) rgje_j3y ,
        SUM(CASE WHEN r.status in ('签约','认购') AND  so.qsdate between convert(varchar(10),dateadd(mm,-3,getdate()),120) and convert(varchar(10),dateadd(mm,-1,getdate()),120)   THEN r.bldarea ELSE 0 END) rgmj_j3y ,
        SUM(CASE WHEN r.status in ('签约','认购') AND  so.qsdate between convert(varchar(10),dateadd(mm,-3,getdate()),120) and convert(varchar(10),dateadd(mm,-1,getdate()),120)   THEN 1 ELSE 0 END) rgts_j3y ,
        SUM(r.bldarea) - SUM(CASE WHEN r.status in ('签约','认购') THEN r.bldarea ELSE 0 END) symj_rg ,
        COUNT(1) - SUM(CASE WHEN r.status in ('签约','认购') THEN 1 ELSE 0 END) syts_rg ,
        sum(case when sc.contractguid is null and so.orderguid is null and r.hszj = 0  then  isnull(jd.ycprice,0)*r.bldarea 
             when  sc.contractguid is null and so.orderguid is null then r.hszj else 0 end  ) as syhz_rg, -- 剩余货值认购口径

        SUM(CASE WHEN jd.SJzskgdate IS NOT NULL AND sc.contractguid IS NULL and so.orderguid is null  THEN r.bldarea ELSE 0 END) ykgwsmj_rg ,                                --已开工未售	
        SUM(CASE WHEN jd.SJzskgdate IS NOT NULL AND sc.contractguid IS NULL and so.orderguid is null  THEN 1 ELSE 0 END) ykgwsts_rg ,
        sum(case when jd.SJzskgdate is not null and sc.contractguid is null and so.orderguid is null and r.hszj = 0 then isnull(jd.ycprice,0)*r.bldarea when jd.SJzskgdate is not null and sc.contractguid is null and so.orderguid is null then r.hszj else 0 end) as ykgwshz_rg, --已开工未售货值
        SUM(CASE WHEN DATEDIFF(dd, thdate, GETDATE()) >= 0 AND  sc.contractguid IS NULL and so.orderguid is null  THEN r.bldarea ELSE 0 END) ytwsmj_rg ,                     --已推未售	
        SUM(CASE WHEN DATEDIFF(dd, thdate, GETDATE()) >= 0 AND  sc.contractguid IS NULL and so.orderguid is null THEN 1 ELSE 0 END) ytwsts_rg ,
        SUM(CASE WHEN jd.SjDdysxxDate IS NULL  AND  sc.contractguid IS NULL and so.orderguid is null THEN 0 ELSE r.bldarea END) ysxxwsmj_rg ,                                                             --已达预售形象未售	
        SUM(CASE WHEN jd.SjDdysxxDate IS NULL  AND  sc.contractguid IS NULL and so.orderguid is null THEN 0 ELSE 1 END) ysxxwsts_rg ,
        SUM(CASE WHEN jd.SJkpxsDate IS NULL AND jd.SjYsblDate IS NOT NULL AND   sc.contractguid IS NULL and so.orderguid is null THEN r.bldarea ELSE 0 END) yszwsmj_rg ,    --取证未推未售	
        SUM(CASE WHEN jd.SJkpxsDate IS NULL AND jd.SjYsblDate IS NOT NULL AND   sc.contractguid IS NULL and so.orderguid is null THEN 1 ELSE 0 END) yszwsts_rg,

        --签约口径
        SUM(CASE WHEN r.status = '签约' THEN r.bldarea ELSE 0 END) ysmj ,
        SUM(CASE WHEN r.status = '签约' THEN 1 ELSE 0 END) ysts ,
        SUM(CASE WHEN r.status = '签约' THEN ISNULL(sc.JyTotal, 0)ELSE 0 END) ysje ,
		SUM(CASE WHEN so.roomguid is not null THEN r.bldarea ELSE 0 END) ljrgmj ,
        SUM(CASE WHEN so.roomguid is not null THEN 1 ELSE 0 END) ljrgts ,
        SUM(CASE WHEN so.roomguid is not null then ISNULL(so.JyTotal, 0)ELSE 0 END) ljrgje ,
        SUM(CASE WHEN r.status = '签约' THEN ISNULL(sc.JyTotalNoTax, 0)ELSE 0 END) ysjeNoTax ,                                                    --已签约金额不含税
        SUM(CASE WHEN r.status = '签约' AND DATEDIFF(yy, sc.qsdate, GETDATE()) = 0 THEN sc.JyTotal ELSE 0 END) bnqyje ,
        SUM(CASE WHEN r.status = '签约' AND DATEDIFF(yy, sc.qsdate, GETDATE()) = 0 THEN r.bldarea ELSE 0 END) bnqymj ,
        SUM(CASE WHEN r.status = '签约' AND DATEDIFF(yy, sc.qsdate, GETDATE()) = 0 THEN 1 ELSE 0 END) bnqyts ,
		SUM(CASE WHEN r.status = '签约' AND DATEDIFF(yy, so.qsdate, GETDATE()) = 0 THEN so.JyTotal ELSE 0 END) bnrgje ,
        SUM(CASE WHEN r.status = '签约' AND DATEDIFF(yy, so.qsdate, GETDATE()) = 0 THEN r.bldarea ELSE 0 END) bnrgmj ,
        SUM(CASE WHEN r.status = '签约' AND DATEDIFF(yy, so.qsdate, GETDATE()) = 0 THEN 1 ELSE 0 END) bnrgts ,
        SUM(CASE WHEN r.status = '签约' AND DATEDIFF(mm, sc.qsdate, GETDATE()) = 0 THEN sc.JyTotal ELSE 0 END) byqyje ,
        SUM(CASE WHEN r.status = '签约' AND DATEDIFF(mm, sc.qsdate, GETDATE()) = 0 THEN r.bldarea ELSE 0 END) byqymj ,
        SUM(CASE WHEN r.status = '签约' AND DATEDIFF(mm, sc.qsdate, GETDATE()) = 0 THEN 1 ELSE 0 END) byqyts ,
        --近三月签约情况
        SUM(CASE WHEN r.status = '签约' AND sc.qsdate between convert(varchar(10),dateadd(mm,-3,getdate()),120) and convert(varchar(10),dateadd(mm,-1,getdate()),120) THEN sc.JyTotal ELSE 0 END) qyje_j3y ,
        SUM(CASE WHEN r.status = '签约' AND sc.qsdate between convert(varchar(10),dateadd(mm,-3,getdate()),120) and convert(varchar(10),dateadd(mm,-1,getdate()),120) THEN r.bldarea ELSE 0 END) qymj_j3y ,
        SUM(CASE WHEN r.status = '签约' AND sc.qsdate between convert(varchar(10),dateadd(mm,-3,getdate()),120) and convert(varchar(10),dateadd(mm,-1,getdate()),120) THEN 1 ELSE 0 END) qyts_j3y ,
        SUM(r.bldarea) - SUM(CASE WHEN r.status = '签约' THEN r.bldarea ELSE 0 END) symj ,
        COUNT(1) - SUM(CASE WHEN r.status = '签约' THEN 1 ELSE 0 END) syts ,
        sum(case when sc.contractguid is null and r.hszj = 0  then  isnull(jd.ycprice,0)* r.bldarea when  sc.contractguid is null then r.hszj else 0 end  ) as syhz,

        SUM(CASE WHEN jd.SJzskgdate IS NOT NULL AND sc.contractguid IS NULL THEN r.bldarea ELSE 0 END) ykgwsmj ,                                --已开工未售	
        SUM(CASE WHEN jd.SJzskgdate IS NOT NULL AND sc.contractguid IS NULL THEN 1 ELSE 0 END) ykgwsts ,
        sum(case when jd.SJzskgdate is not null and sc.contractguid is null and r.hszj = 0 then isnull(jd.ycprice,0)*r.bldarea when jd.SJzskgdate is not null and sc.contractguid is null then r.hszj else 0 end) as ykgwshz, --已开工未售货值

        SUM(CASE WHEN DATEDIFF(dd, thdate, GETDATE()) >= 0 AND  sc.contractguid IS NULL THEN r.bldarea ELSE 0 END) ytwsmj ,                     --已推未售	
        SUM(CASE WHEN DATEDIFF(dd, thdate, GETDATE()) >= 0 AND  sc.contractguid IS NULL THEN 1 ELSE 0 END) ytwsts ,
        SUM(CASE WHEN jd.SjDdysxxDate IS NULL THEN 0 ELSE r.bldarea END) ysxxwsmj ,                                                             --已达预售形象未售	
        SUM(CASE WHEN jd.SjDdysxxDate IS NULL THEN 0 ELSE 1 END) ysxxwsts ,
        SUM(CASE WHEN jd.SJkpxsDate IS NULL AND jd.SjYsblDate IS NOT NULL AND   sc.contractguid IS NULL THEN r.bldarea ELSE 0 END) yszwsmj ,    --取证未推未售	
        SUM(CASE WHEN jd.SJkpxsDate IS NULL AND jd.SjYsblDate IS NOT NULL AND   sc.contractguid IS NULL THEN 1 ELSE 0 END) yszwsts,
		sum(case when DATEDIFF(dd, thdate, GETDATE()) >= 0 and r.hszj = 0 then isnull(jd.ycprice,0)*r.bldarea when DATEDIFF(dd, thdate, GETDATE()) >= 0 then r.hszj else 0 end) as ythz,--已推货值
		sum(case when DATEDIFF(dd, thdate, GETDATE()) >= 0 then r.bldarea else 0 end)ytmj,
		sum(case when DATEDIFF(dd, thdate, GETDATE()) >= 0 then 1 else 0 end)ytts
		
INTO    #hx1
FROM    #r r
        LEFT JOIN #ldjd jd ON r.bldguid = jd.salebldguid
        LEFT JOIN erp25.dbo.s_contract sc ON sc.roomguid = r.roomguid AND  sc.status = '激活' AND r.status = '签约'
		LEFT JOIN erp25.dbo.s_order so ON so.roomguid = r.roomguid AND so.OrderType='认购' and (so.Status = '激活' OR (so.Status = '关闭' AND so.CloseReason = '转签约' AND  so.TradeGUID = sc.TradeGUID and sc.contractguid is not null))  
GROUP BY r.projguid ,
         r.bldguid ,
         r.producttype ,
         r.ProductName ,
         jd.BusinessType ,
         jd.Standard ,
         r.bldarea ,
         r.HxAreaHgNumSettingGUID ,
         r.RoomNum ,
         r.Hall ,
         CAST(r.Toilet AS REAL) ,
         r.Balcony ,
         CASE WHEN r.RoomNum = -1 THEN '' ELSE CAST(r.RoomNum AS VARCHAR(50)) + '房' END + CASE WHEN r.Hall = -1 THEN '' ELSE CAST(r.Hall AS VARCHAR(50)) + '厅' END
         + CASE WHEN r.Toilet = -1 THEN '' ELSE CAST(CAST(r.Toilet AS REAL) AS VARCHAR(50)) + '卫' END + CASE WHEN r.Balcony = -1 THEN '' ELSE CAST(r.Balcony AS VARCHAR(50)) + '阳台' END;

--获取未建房间楼栋货值情况
SELECT  ld.projguid ,
        ld.salebldguid bldguid ,
        ld.producttype ,
        ld.ProductName ,
        ld.BusinessType ,
        ld.Standard ,
        hx.HxAreaHgNumSettingGUID ,
        CONVERT(DECIMAL(16, 0), hx.HxArea) bldarea ,
        isnull(hx.RoomNum,-1) as RoomNum,
        isnull(hx.Hall,-1) as Hall,
        isnull(hx.Toilet,-1) as Toilet,
        isnull(hx.Balcony,-1) as Balcony,
        CAST(hx.RoomNum AS VARCHAR(50)) + '房' + CAST(hx.Hall AS VARCHAR(50)) + '厅' + CAST(CAST(hx.Toilet AS REAL) AS VARCHAR(50)) + '卫' + CAST(hx.Balcony AS VARCHAR(50)) + '阳台' hxStru ,
        SUM(ISNULL(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)) zksmj ,
		SUM(ISNULL(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)*isnull(ld.ycprice,0)) hszj ,
        SUM(hx.HgNum) zksts ,
        --认购口径
        0 ysmj_rg ,
        0 ysts_rg ,
        0 ysje_rg ,
        --近三月认购情况
        0 rgje_j3y ,
        0 rgmj_j3y ,
        0 rgts_j3y ,
        SUM(ISNULL(hx.HxArea, 0) * ISNULL(hx.HgNum, 0))  as symj_rg ,
        SUM(ISNULL(hx.HgNum, 0)) as syts_rg ,
        sum(isnull(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)*isnull(ld.ycprice,0) ) as syhz_rg ,

        --已开工未售 
        SUM(CASE WHEN ld.SJzskgdate IS NOT NULL THEN ISNULL(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)ELSE 0 END)  ykgwsmj_rg ,                                	
        SUM(CASE WHEN ld.SJzskgdate IS NOT NULL THEN ISNULL(hx.HgNum, 0)ELSE 0 END) ykgwsts_rg ,
        sum(case when ld.SJzskgdate is not null then isnull(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)*isnull(ld.ycprice,0) else 0 end)  ykgwshz_rg ,
         --已推未售	
        SUM(CASE WHEN sjkpxsdate IS NOT NULL THEN ISNULL(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)ELSE 0 END) ytwsmj_rg ,                    
        SUM(CASE WHEN sjkpxsdate IS NOT NULL THEN ISNULL(hx.HgNum, 0)ELSE 0 END)  ytwsts_rg ,
        SUM(CASE WHEN ld.SjDdysxxDate IS NULL THEN 0 ELSE ISNULL(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)END)  ysxxwsmj_rg , --已达预售形象未售	
        SUM(CASE WHEN ld.SjDdysxxDate IS NULL THEN 0 ELSE ISNULL(hx.HgNum, 0)END)  ysxxwsts_rg ,
        SUM(CASE WHEN ld.SJkpxsDate IS NULL AND ld.SjYsblDate IS NOT NULL THEN ISNULL(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)ELSE 0 END)  yszwsmj_rg ,    --取证未推未售	
        SUM(CASE WHEN ld.SJkpxsDate IS NULL AND ld.SjYsblDate IS NOT NULL THEN ISNULL(hx.HgNum, 0) ELSE 0 END)  yszwsts_rg,
        --签约口径
        0 ysmj ,
        0 ysts ,
        0 ysje ,
		0 ljrgmj ,
        0 ljrgts ,
        0 ljrgje ,
        0 ysjeNoTax ,
        0 bnqyje ,
        0 bnqymj ,
        0 bnqyts ,
		0 bnrgje ,
        0 bnrgmj ,
        0 bnrgts ,
        0 byqyje ,
        0 byqymj ,
        0 byqyts ,  
        --近三月签约情况
        0 qyje_j3y ,
        0 qymj_j3y ,
        0 qyts_j3y ,
        SUM(ISNULL(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)) symj ,
        SUM(ISNULL(hx.HgNum, 0)) syts ,
        sum(isnull(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)*isnull(ld.ycprice,0) ) syhz,

        SUM(CASE WHEN ld.SJzskgdate IS NOT NULL THEN ISNULL(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)ELSE 0 END) ykgwsmj ,                            --已开工未售	
        SUM(CASE WHEN ld.SJzskgdate IS NOT NULL THEN ISNULL(hx.HgNum, 0)ELSE 0 END) ykgwsts ,
        sum(case when ld.SJzskgdate is not null then isnull(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)*isnull(ld.ycprice,0) else 0 end)  ykgwshz,      --已开工未售货值
        SUM(CASE WHEN sjkpxsdate IS NOT NULL THEN ISNULL(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)ELSE 0 END) ytwsmj ,                                --已推未售	
        SUM(CASE WHEN sjkpxsdate IS NOT NULL THEN ISNULL(hx.HgNum, 0)ELSE 0 END) ytwsts ,
        SUM(CASE WHEN ld.SjDdysxxDate IS NULL THEN 0 ELSE ISNULL(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)END) ysxxwsmj ,                             --已达预售形象未售	
        SUM(CASE WHEN ld.SjDdysxxDate IS NULL THEN 0 ELSE ISNULL(hx.HgNum, 0)END) ysxxwsts ,
        SUM(CASE WHEN ld.SJkpxsDate IS NULL AND ld.SjYsblDate IS NOT NULL THEN ISNULL(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)ELSE 0 END) yszwsmj ,  --取证未推未售	
        SUM(CASE WHEN ld.SJkpxsDate IS NULL AND ld.SjYsblDate IS NOT NULL THEN ISNULL(hx.HgNum, 0) ELSE 0 END) yszwsts,
		sum(case when DATEDIFF(dd, ld.SJkpxsDate, GETDATE()) >= 0 then ISNULL(hx.HxArea, 0) * ISNULL(hx.HgNum, 0)*isnull(ld.ycprice,0) else 0 end) as ythz,--已推货值
		sum(case when DATEDIFF(dd, ld.SJkpxsDate, GETDATE()) >= 0 then ISNULL(hx.HxArea, 0) * ISNULL(hx.HgNum, 0) else 0 end) ytmj,
		sum(case when DATEDIFF(dd, ld.SJkpxsDate, GETDATE()) >= 0 then ISNULL(hx.HgNum, 0) else 0 end)ytts
INTO    #hx2
FROM    MyCost_Erp352..vmd_ProductBuild_ZX t
        LEFT JOIN MyCost_Erp352.dbo.md_Room r ON r.ProductBldGUID = t.productbuildguid
        INNER JOIN MyCost_Erp352.dbo.md_ProductBuildHxAreaHgNumSetting hx ON t.ProductBuildGUID = hx.ProductBuildGUID AND t.versionguid = hx.versionguid
        INNER JOIN #ldjd ld ON t.ProductBuildGUID = ld.salebldguid
WHERE   r.roomguid IS NULL AND  ld.ProductType IN ('住宅', '高级住宅', '企业会所', '公寓','商业','地下室/车库','写字楼','企业会所')
GROUP BY ld.projguid ,
         ld.salebldguid ,
         ld.producttype ,
         ld.ProductName ,
         ld.BusinessType ,
         ld.Standard ,
         hx.HxAreaHgNumSettingGUID ,
         CONVERT(DECIMAL(16, 0), hx.HxArea) ,
         hx.RoomNum ,
         hx.Hall ,
         hx.Toilet ,
         hx.Balcony ,
         CAST(hx.RoomNum AS VARCHAR(50)) + '房' + CAST(hx.Hall AS VARCHAR(50)) + '厅' + CAST(CAST(hx.Toilet AS REAL) AS VARCHAR(50)) + '卫' + CAST(hx.Balcony AS VARCHAR(50)) + '阳台';

SELECT  t.projguid ,
        t.bldguid AS productbuildguid ,
        t.producttype ,
        t.ProductName ,
        t.BusinessType ,
        t.Standard ,
        t.HxAreaHgNumSettingGUID ,
        CONVERT(DECIMAL(16, 0), t.bldarea) bldarea ,
        t.RoomNum ,
        t.Hall ,
        CAST(t.Toilet AS REAL) AS Toilet ,
        t.Balcony ,
        t.hxStru ,
        SUM(t.zksmj) AS zksmj ,
        SUM(t.zksts) AS zksts ,
		sum(t.hszj)as hszj,
        --认购口径
        sum(t.ysmj_rg) ysmj_rg ,
        sum(t.ysts_rg) ysts_rg ,
        sum(t.ysje_rg) ysje_rg ,
        --近三月认购情况
        sum(t.rgje_j3y) rgje_j3y ,
        sum(t.rgmj_j3y) rgmj_j3y ,
        sum(t.rgts_j3y) rgts_j3y ,
        sum(t.symj_rg) symj_rg ,
        sum(t.syts_rg) syts_rg ,
        sum(t.syhz_rg) syhz_rg,

        sum(t.ykgwsmj_rg) ykgwsmj_rg ,                                --已开工未售	
        sum(t.ykgwsts_rg) ykgwsts_rg ,
        sum(t.ykgwshz_rg) ykgwshz_rg ,
        sum(t.ytwsmj_rg) ytwsmj_rg ,                     --已推未售	
        sum(t.ytwsts_rg) ytwsts_rg ,
        sum(t.ysxxwsmj_rg) ysxxwsmj_rg ,                                                             --已达预售形象未售	
        sum(t.ysxxwsts_rg) ysxxwsts_rg ,
        sum(t.yszwsmj_rg) yszwsmj_rg ,    --取证未推未售	
        sum(t.yszwsts_rg) yszwsts_rg,
        --签约口径
        SUM(ysmj) AS ysmj ,
        SUM(ysts) AS ysts ,
        SUM(ysje) AS ysje ,
		SUM(ljrgmj) AS ljrgmj ,
        SUM(ljrgts) AS ljrgts ,
        SUM(ljrgje) AS ljrgje ,
        SUM(ysjeNoTax) AS ysjeNoTax ,
        SUM(bnqyje) AS bnqyje ,
        SUM(bnqymj) AS bnqymj ,
        SUM(bnqyts) AS bnqyts ,
		SUM(bnrgje) AS bnrgje ,
        SUM(bnrgmj) AS bnrgmj ,
        SUM(bnrgts) AS bnrgts ,
        SUM(byqyje) AS byqyje ,
        SUM(byqymj) AS byqymj ,
        SUM(byqyts) AS byqyts ,
        --近三月签约情况
        SUM(qyje_j3y) AS  qyje_j3y ,
        SUM(qymj_j3y) AS  qymj_j3y ,
        SUM(qyts_j3y) AS  qyts_j3y ,
        SUM(symj) AS symj ,
        SUM(syts) AS syts ,
        sum(syhz) as syhz ,
        SUM(ykgwsmj) AS ykgwsmj ,   --已开工未售	
        SUM(ykgwsts) AS ykgwsts ,
        SUM(ykgwshz) AS ykgwshz ,
        SUM(ytwsmj) AS ytwsmj ,     --已推未售	
        SUM(ytwsts) AS ytwsts ,
        SUM(ysxxwsmj) AS ysxxwsmj , --已达预售形象未售	
        SUM(ysxxwsts) ysxxwsts ,
        SUM(yszwsmj) yszwsmj ,      --取证未推未售	
        SUM(yszwsts) yszwsts,
		sum(ythz)ythz ,--已推货值
		sum(ytmj)ytmj ,
		sum(ytts)ytts 
--  convert(decimal(16,0),0.0) bldarea_base --取归并后的标准面积
INTO    #tmp_result
FROM(SELECT * FROM  #hx1 hx1 UNION ALL SELECT   * FROM  #hx2 hx2) t
    LEFT JOIN MyCost_Erp352..md_ProductBuildHxAreaHgNumSetting hx ON hx.HxAreaHgNumSettingGUID = t.HxAreaHgNumSettingGUID
GROUP BY t.projguid ,
         t.bldguid ,
         t.producttype ,
         t.ProductName ,
         t.BusinessType ,
         t.Standard ,
         t.HxAreaHgNumSettingGUID ,
         CONVERT(DECIMAL(16, 0), t.bldarea) ,
         t.RoomNum ,
         t.Hall ,
         CAST(t.Toilet AS REAL) ,
         t.Balcony ,
         t.hxStru ,
         CONVERT(DECIMAL(16, 0), hx.HxArea);

-- 山西公司的标准户型匹配，考虑按照户型+面积来匹配，如果匹配不上再考虑按照楼栋+面积来匹配
-- 户型+面积
SELECT  t.projguid ,
        t.productbuildguid ,
        t.producttype ,
        t.ProductName ,
        t.BusinessType ,
        t.Standard ,
        t.HxAreaHgNumSettingGUID ,
        t.bldarea ,
        ISNULL(st.房, 0) AS RoomNum ,
        ISNULL(st.厅, 0) AS Hall ,
        ISNULL(st.卫, 0) AS Toilet ,
        ISNULL(st.阳台, 0) AS Balcony ,
        CASE WHEN ISNULL(st.房, 0) = 0 THEN ''
             ELSE CASE WHEN st.房 = FLOOR(st.房) THEN CAST(CAST(st.房 AS INT) AS VARCHAR(50))ELSE CAST(CAST(st.房 AS DECIMAL(18, 1)) AS VARCHAR(50))END + '房'
        END + CASE WHEN ISNULL(st.厅, 0) = 0 THEN ''
                   ELSE CASE WHEN st.厅 = FLOOR(st.厅) THEN CAST(CAST(st.厅 AS INT) AS VARCHAR(50))ELSE CAST(CAST(st.厅 AS DECIMAL(18, 1)) AS VARCHAR(50))END + '厅'
              END + CASE WHEN ISNULL(st.卫, 0) = 0 THEN ''
                         ELSE CASE WHEN st.卫 = FLOOR(st.卫) THEN CAST(CAST(st.卫 AS INT) AS VARCHAR(50))ELSE CAST(CAST(st.卫 AS DECIMAL(18, 1)) AS VARCHAR(50))END + '卫'
                    END + CASE WHEN ISNULL(st.阳台, 0) = 0 THEN ''
                               ELSE CASE WHEN st.阳台 = FLOOR(st.阳台) THEN CAST(CAST(st.阳台 AS INT) AS VARCHAR(50))ELSE CAST(CAST(st.阳台 AS DECIMAL(18, 1)) AS VARCHAR(50))END + '阳台'
                          END AS hxStru ,   --户型 --户型
        t.zksmj ,
        t.zksts ,
		t.hszj,
        --认购口径
        t.ysmj_rg ,
        t.ysts_rg ,
        t.ysje_rg ,
        --近三月认购情况
        t.rgje_j3y ,
        t.rgmj_j3y ,
        t.rgts_j3y ,
        t.symj_rg ,
        t.syts_rg ,
        t.syhz_rg ,

        t.ykgwsmj_rg ,                                --已开工未售	
        t.ykgwsts_rg ,
        t.ykgwshz_rg ,
        t.ytwsmj_rg ,                     --已推未售	
        t.ytwsts_rg ,
        t.ysxxwsmj_rg ,                                                             --已达预售形象未售	
        t.ysxxwsts_rg ,
        t.yszwsmj_rg ,    --取证未推未售	
        t.yszwsts_rg,
        --签约口径
        t.ysmj ,
        t.ysts ,
        t.ysje ,
		t.ljrgmj ,
        t.ljrgts ,
        t.ljrgje ,
        t.ysjeNoTax ,
        t.bnqyje ,
        t.bnqymj ,
        t.bnqyts ,
		t.bnrgje ,
        t.bnrgmj ,
        t.bnrgts ,
        t.byqyje ,
        t.byqymj ,
        t.byqyts ,
        t.qyje_j3y,
        t.qymj_j3y,
        t.qyts_j3y,
        t.symj ,
        t.syts ,
        t.syhz ,
        t.ykgwsmj ,                         --已开工未售	
        t.ykgwsts ,
        t.ykgwshz ,
        t.ytwsmj ,                          --已推未售	
        t.ytwsts ,
        t.ysxxwsmj ,                        --已达预售形象未售	
        t.ysxxwsts ,
        t.yszwsmj ,                         --取证未推未售	
        t.yszwsts ,
		t.ythz,t.ytmj,t.ytts,--已推
        st.标准户型面积段 AS bldarea_base ,
        st.标准户型开始面积段 AS bgnarea ,
        st.标准户型截止面积段 AS endarea ,
        ISNULL(st.精装成本, 0) AS jzcb
INTO    #tmp
FROM    #tmp_result t
        inner JOIN #SxBaseRoomStr st ON t.productbuildguid = st.产品楼栋GUID AND   ISNULL(t.RoomNum, 0) = ISNULL(st.房, 0) AND  ISNULL(t.Hall, 0) = ISNULL(st.厅, 0) AND ISNULL(t.Toilet, 0) = ISNULL(st.卫, 0)
                                        AND   ISNULL(t.Balcony, 0) = ISNULL(st.阳台, 0) AND t.bldarea >= st.标准户型开始面积段 AND   t.bldarea <= st.标准户型截止面积段;

-- 楼栋+面积
INSERT INTO #tmp
SELECT  t.projguid ,
        t.productbuildguid ,
        t.producttype ,
        t.ProductName ,
        t.BusinessType ,
        t.Standard ,
        t.HxAreaHgNumSettingGUID ,
        t.bldarea ,
        ISNULL(st.房, 0) AS RoomNum ,
        ISNULL(st.厅, 0) AS Hall ,
        ISNULL(st.卫, 0) AS Toilet ,
        ISNULL(st.阳台, 0) AS Balcony ,
        CASE WHEN ISNULL(st.房, 0) = 0 THEN ''
             ELSE CASE WHEN st.房 = FLOOR(st.房) THEN CAST(CAST(st.房 AS INT) AS VARCHAR(50))ELSE CAST(CAST(st.房 AS DECIMAL(18, 1)) AS VARCHAR(50))END + '房'
        END + CASE WHEN ISNULL(st.厅, 0) = 0 THEN ''
                   ELSE CASE WHEN st.厅 = FLOOR(st.厅) THEN CAST(CAST(st.厅 AS INT) AS VARCHAR(50))ELSE CAST(CAST(st.厅 AS DECIMAL(18, 1)) AS VARCHAR(50))END + '厅'
              END + CASE WHEN ISNULL(st.卫, 0) = 0 THEN ''
                         ELSE CASE WHEN st.卫 = FLOOR(st.卫) THEN CAST(CAST(st.卫 AS INT) AS VARCHAR(50))ELSE CAST(CAST(st.卫 AS DECIMAL(18, 1)) AS VARCHAR(50))END + '卫'
                    END + CASE WHEN ISNULL(st.阳台, 0) = 0 THEN ''
                               ELSE CASE WHEN st.阳台 = FLOOR(st.阳台) THEN CAST(CAST(st.阳台 AS INT) AS VARCHAR(50))ELSE CAST(CAST(st.阳台 AS DECIMAL(18, 1)) AS VARCHAR(50))END + '阳台'
                          END AS hxStru ,   --户型 --户型
        t.zksmj ,
        t.zksts ,
		t.hszj,
        --认购口径
        t.ysmj_rg ,
        t.ysts_rg ,
        t.ysje_rg ,
        --近三月认购情况
        t.rgje_j3y ,
        t.rgmj_j3y ,
        t.rgts_j3y ,
        t.symj_rg ,
        t.syts_rg ,
        t.syhz_rg,
        
        t.ykgwsmj_rg ,                                --已开工未售	
        t.ykgwsts_rg ,
        t.ykgwshz_rg ,
        t.ytwsmj_rg ,                     --已推未售	
        t.ytwsts_rg ,
        t.ysxxwsmj_rg ,                                                             --已达预售形象未售	
        t.ysxxwsts_rg ,
        t.yszwsmj_rg ,    --取证未推未售	
        t.yszwsts_rg,
        --签约口径
        t.ysmj ,
        t.ysts ,
        t.ysje ,
		t.ljrgmj ,
        t.ljrgts ,
        t.ljrgje ,
        t.ysjeNoTax ,
        t.bnqyje ,
        t.bnqymj ,
        t.bnqyts ,
		t.bnrgje ,
        t.bnrgmj ,
        t.bnrgts ,
        t.byqyje ,
        t.byqymj ,
        t.byqyts ,
        t.qyje_j3y,
        t.qymj_j3y,
        t.qyts_j3y,
        t.symj ,
        t.syts ,
        t.syhz ,
        t.ykgwsmj ,                         --已开工未售	
        t.ykgwsts ,
        t.ykgwshz ,
        t.ytwsmj ,                          --已推未售	
        t.ytwsts ,
        t.ysxxwsmj ,                        --已达预售形象未售	
        t.ysxxwsts ,
        t.yszwsmj ,                         --取证未推未售	
        t.yszwsts ,
		t.ythz,t.ytmj,t.ytts,
        st.标准户型面积段 AS bldarea_base ,
        st.标准户型开始面积段 AS bgnarea ,
        st.标准户型截止面积段 AS endarea ,
        ISNULL(st.精装成本, 0) AS jzcb
FROM    #tmp_result t
        inner JOIN #SxBaseRoomStr st ON t.productbuildguid = st.产品楼栋GUID AND   t.bldarea >= st.标准户型开始面积段 AND   t.bldarea <= st.标准户型截止面积段
WHERE   NOT EXISTS (SELECT  1
                    FROM    #tmp temp
                    WHERE   temp.productbuildguid = st.产品楼栋GUID AND ISNULL(temp.RoomNum, 0) = ISNULL(st.房, 0) AND   ISNULL(temp.Hall, 0) = ISNULL(st.厅, 0)
                            AND  ISNULL(temp.Toilet, 0) = ISNULL(st.卫, 0) AND ISNULL(temp.Balcony, 0) = ISNULL(st.阳台, 0) AND temp.bldarea >= st.标准户型开始面积段 AND temp.bldarea <= st.标准户型截止面积段);

--将面积归并到标准户型面积里面，优先考虑户型+面积的匹配，如果匹配不上再考虑按照楼栋+面积来匹配
--户型+面积
INSERT INTO #tmp
SELECT  t.* ,
        sta.hxarea bldarea_base ,
        sta.hxBgnArea bgnarea ,
        sta.hxEndArea endarea ,
        0 AS jzcb
--INTO    #tmp
FROM    #tmp_result t
        inner JOIN(SELECT   DISTINCT productbuildguid ,
                                     RoomNum ,
                                     Hall ,
                                     Toilet ,
                                     Balcony ,
                                     hxBgnArea ,
                                     hxEndArea ,
                                     hxarea
                   FROM s_hxArea_Standard
                   WHERE   NOT EXISTS (SELECT   1 FROM  #SxRoomStr st WHERE st.产品楼栋GUID = productbuildguid)) sta ON t.productbuildguid = sta.productbuildguid AND   t.RoomNum = sta.RoomNum
                                                                                                                    AND t.Hall = sta.Hall AND   t.Toilet = sta.Toilet AND   t.Balcony = sta.Balcony
                                                                                                                    AND t.bldarea >= sta.hxBgnArea AND  t.bldarea < hxEndArea;

--楼栋+面积
INSERT INTO #tmp
SELECT  t.* ,
        sta.hxarea bldarea_base ,
        sta.bldBgnArea bgnarea ,
        sta.bldEndArea endarea ,
        0 AS jzcb
FROM    #tmp_result t
        inner JOIN(SELECT   DISTINCT productbuildguid ,
                                     hxarea ,
                                     bldBgnArea ,
                                     bldEndArea
                   FROM s_hxArea_Standard
                   WHERE   NOT EXISTS (SELECT   1 FROM  #SxRoomStr st WHERE st.产品楼栋GUID = productbuildguid)) sta ON t.productbuildguid = sta.productbuildguid AND   t.bldarea >= sta.bldBgnArea
                                                                                                                    AND t.bldarea < bldEndArea
WHERE   t.HxAreaHgNumSettingGUID is not null and NOT EXISTS (SELECT  *
                    FROM    #tmp tmp
                    WHERE   t.productbuildguid = tmp.productbuildguid AND   t.HxAreaHgNumSettingGUID = tmp.HxAreaHgNumSettingGUID);

--还存在部分楼栋是没有户型设置guid的情况
INSERT INTO #tmp
SELECT  t.* ,
        sta.hxarea bldarea_base ,
        sta.bldBgnArea bgnarea ,
        sta.bldEndArea endarea ,
        0 AS jzcb
FROM    #tmp_result t
        inner JOIN(SELECT   DISTINCT productbuildguid ,
                                     hxarea ,
                                     bldBgnArea ,
                                     bldEndArea
                   FROM s_hxArea_Standard
                   WHERE   NOT EXISTS (SELECT   1 FROM  #SxRoomStr st WHERE st.产品楼栋GUID = productbuildguid)) sta ON t.productbuildguid = sta.productbuildguid AND   t.bldarea >= sta.bldBgnArea
                                                                                                                    AND t.bldarea < bldEndArea
WHERE   t.HxAreaHgNumSettingGUID is null and NOT EXISTS (SELECT  *
                    FROM    #tmp tmp
                    WHERE   t.productbuildguid = tmp.productbuildguid and t.hxStru = tmp.hxStru);  
                    
INSERT INTO #tmp
SELECT  t.* ,
        null bldarea_base ,
        null bgnarea ,
        null endarea ,
        0 AS jzcb
FROM    #tmp_result t 
WHERE    NOT EXISTS (SELECT  *
                    FROM    #tmp tmp
                    WHERE   t.productbuildguid = tmp.productbuildguid and t.hxStru = tmp.hxStru and t.bldarea = tmp.bldarea);  

--获取盈利规划业态基础信息
SELECT  DISTINCT do.DevelopmentCompanyGUID AS 公司Guid ,
                 do.OrganizationName AS 公司名称 ,
                 pj.ProjGUID AS 项目Guid ,
                 pj.SpreadName AS 项目推广名 ,
                 pj1.ProjCode AS 项目代码 ,
                 pj.TgProjCode AS 项目投管代码 ,
                 pj1.Ylghsxfs AS 盈利规划上线方式 ,
                 pr.TopProductTypeName 产品类型 ,
                 SUBSTRING(YtName, 0, CHARINDEX('_', YtName)) 产品名称 ,
                 SUBSTRING(SUBSTRING(YtName, CHARINDEX('_', YtName) + 1, 100), CHARINDEX('_', SUBSTRING(YtName, CHARINDEX('_', YtName) + 1, 100)) + 1, 100) 装修标准 ,
                 SUBSTRING(SUBSTRING(YtName, CHARINDEX('_', YtName) + 1, 100), 0, CHARINDEX('_', SUBSTRING(YtName, CHARINDEX('_', YtName) + 1, 100))) 商品类型 ,
                 ISNULL(pj1.ProjCode, '') + '_' + ISNULL(pr.TopProductTypeName, '') + '_' + ISNULL(yt.YtName, '') 匹配主键 ,
                 yt.YtName
INTO    #base
FROM    [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_SumProjProductYt yt
        INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID p ON p.YLGHProjGUID = yt.ProjGUID AND p.isbase = 1 AND   p.Level = 3
        INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_mdm_Project pj ON p.ProjGUID = pj.ProjGUID
        INNER JOIN ERP25.dbo.mdm_Project pj1 ON pj1.ProjGUID = pj.ProjGUID
        INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_s_Dimension_Organization do ON pj.BUGUID = do.OrgGUID
        --获取一级产品类型
        LEFT JOIN(SELECT    ProductTypeName ,
                            TopProductTypeName ,
                            ROW_NUMBER() OVER (PARTITION BY pr.ProductTypeName ORDER BY ProductTypeName) AS num
                  FROM  [172.16.4.161].HighData_prod.dbo.data_wide_dws_mdm_Product pr) pr ON pr.num = 1 AND pr.ProductTypeName = yt.ProductType
WHERE   yt.IsBase = 1 AND   pj.Level = 2 AND yt.YtName <> '不区分业态';

--获取盈利规划系统数据情况
--总可售金额跟面积
SELECT  pj.ProjGUID AS projguid ,
        yt.YtName ,
        SUM(ISNULL(TotalSaleValueArea, 0)) 总可售面积 ,
        SUM(ISNULL(TotalSaleValueAmountNotTax, 0)) 总可售金额不含税
INTO    #mj
FROM    [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_SaleValueByYt yt
        INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj ON yt.ProjGUID = pj.YLGHProjGUID AND  pj.isbase = 1 AND   pj.Level = 3
        INNER JOIN erp25.dbo.mdm_project p ON pj.ProjGUID = p.projguid
WHERE   yt.IsBase = 1
GROUP BY pj.ProjGUID ,
         yt.YtName;

--单方数据1
SELECT  pj.ProjGUID AS projguid ,
        yt.YtName ,
        SUM(ISNULL(HuNum, 0)) 户数 ,
        SUM(ISNULL(OperatingCost, 0)) AS 营业成本 ,
        SUM(ISNULL(FinanceCost, 0)) AS 资本化利息_综合管理费 ,
        SUM(ISNULL(TaxeAndSurcharges, 0)) AS 税金及附加 ,
        SUM(ISNULL(EquityPremium, 0)) AS 股权溢价 ,
        --   SUM(ISNULL(yt.managementCost, 0)) AS 管理费用,
        SUM(ISNULL(yt.Marketingcost, 0)) AS 营销费用 ,
        SUM(ISNULL(yt.TotalInvestment, 0)) AS 总成本含税
INTO    #df
FROM    [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_expenses_yt yt
        INNER JOIN [172.16.4.161].HighData_prod.dbo.data_wide_dws_ys_ProjGUID pj ON yt.ProjGUID = pj.YLGHProjGUID AND  pj.isbase = 1 AND   pj.Level = 3
        INNER JOIN erp25.dbo.mdm_project p ON pj.ProjGUID = p.projguid
WHERE   yt.IsBase = 1
GROUP BY pj.ProjGUID ,
         yt.YtName;

-- 查询项目业态层级的营业成本单方和税金及附加单方金额 
SELECT  base.* ,
        SUM(ISNULL(mj.总可售金额不含税, 0)) AS 总可售金额不含税 ,
        SUM(CASE WHEN base.产品类型 = '地下室/车库' THEN ISNULL(df.户数, 0)ELSE ISNULL(mj.总可售面积, 0)END) AS 总可售面积 ,
        SUM(CASE WHEN base.产品类型 = '地下室/车库' THEN ISNULL(df.户数, 0)ELSE 0 END) AS 盈利规划车位数 ,
        SUM(ISNULL(df.营业成本, 0)) AS 营业成本 ,
        SUM(ISNULL(df.资本化利息_综合管理费, 0)) AS 资本化利息_综合管理费 ,
        SUM(ISNULL(df.税金及附加, 0)) AS 税金及附加 ,
        SUM(ISNULL(df.股权溢价, 0)) AS 股权溢价 ,
        CASE WHEN SUM(CASE WHEN base.产品类型 = '地下室/车库' THEN ISNULL(df.户数, 0)ELSE ISNULL(mj.总可售面积, 0)END) = 0 THEN 0
             ELSE SUM(ISNULL(df.股权溢价, 0)) / SUM(CASE WHEN base.产品类型 = '地下室/车库' THEN ISNULL(df.户数, 0)ELSE ISNULL(mj.总可售面积, 0)END)
        END AS 股权溢价单方 ,
        CASE WHEN SUM(CASE WHEN base.产品类型 = '地下室/车库' THEN ISNULL(df.户数, 0)ELSE ISNULL(mj.总可售面积, 0)END) = 0 THEN 0
             ELSE SUM(ISNULL(df.营业成本, 0)) / SUM(CASE WHEN base.产品类型 = '地下室/车库' THEN ISNULL(df.户数, 0)ELSE ISNULL(mj.总可售面积, 0)END)
        END AS 盈利规划营业成本单方 ,
        CASE WHEN SUM(CASE WHEN base.产品类型 = '地下室/车库' THEN ISNULL(df.户数, 0)ELSE ISNULL(mj.总可售面积, 0)END) = 0 THEN 0
             ELSE SUM(ISNULL(df.税金及附加, 0)) / SUM(CASE WHEN base.产品类型 = '地下室/车库' THEN ISNULL(df.户数, 0)ELSE ISNULL(mj.总可售面积, 0)END)
        END AS 税金及附加单方
INTO    #df_base
FROM    #base base
        LEFT JOIN #mj mj ON base.项目Guid = mj.projguid AND  base.YtName = mj.YtName
        LEFT JOIN #df df ON df.projguid = base.项目Guid AND  df.YtName = base.YtName
GROUP BY base.公司名称 ,
         base.项目Guid ,
         base.项目推广名 ,
         base.项目代码 ,
         base.项目投管代码 ,
         base.盈利规划上线方式 ,
         base.产品类型 ,
         base.产品名称 ,
         base.装修标准 ,
         base.商品类型 ,
         base.匹配主键 ,
         base.YtName ,
         base.公司Guid;

--输出查询结果
SELECT  a.* ,
        ld.SjDdysxxDate ,
        ld.SJkpxsDate ,
        ld.SjYsblDate ,
        ld.SJzskgdate ,
        ld.sjjgbadate ,
        ld.yjDdysxxDate ,
        ld.yJkpxsDate ,
        ld.yjYsblDate ,
        ld.yJzskgdate ,
        ld.yjjgbadate ,
        b.盈利规划营业成本单方 AS yycbdf ,
        b.税金及附加单方 AS sjdf,
		b.股权溢价单方 as EquityPremiumdf
FROM    #tmp a
        left join #ldjd ld on ld.salebldguid = a.productbuildguid 
        LEFT JOIN #df_base b ON a.projguid = b.项目Guid AND  a.ProductType = b.产品类型 AND  a.ProductName = b.产品名称 AND  a.BusinessType = b.商品类型 AND a.Standard = b.装修标准
-- where  a.ProjGUID ='7abbac1a-b1f8-ea11-b398-f40270d39969'

DROP TABLE #hx1 ,
           #hx2 ,
           #ldjd ,
           #r ,
           #tmp ,
           #tmp_result ,
           #SxRoomStr ,
           #SxBaseRoomStr ,
           #data_tb_SaleBldHxInfoBySx
