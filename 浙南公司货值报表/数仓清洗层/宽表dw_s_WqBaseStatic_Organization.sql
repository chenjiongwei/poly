-- 资源地图底表组织架构表清洗
-- 宽表名称：data_wide_dws_s_WqBaseStatic_Organization  

CREATE TABLE #ydkb_BaseInfo
(
    组织架构ID UNIQUEIDENTIFIER NOT NULL,
    组织架构编码 VARCHAR(100) NULL,
    组织架构父级ID UNIQUEIDENTIFIER NOT NULL,
    组织架构名称 VARCHAR(400) NULL,
    组织架构类型 INT NULL,
    组织架构类型名称 VARCHAR(64),
    --1平台公司 2城市公司 3一级项目 4业态 5产品组合 6工程楼栋 7产品楼栋 8户型 
    平台公司GUID UNIQUEIDENTIFIER,
    平台公司名称 VARCHAR(64),
    项目guid UNIQUEIDENTIFIER,
    项目代码 VARCHAR(64),
    项目名称 varchar(64),
    业态 VARCHAR(64),
    产品名称 VARCHAR(200),
    商业类型 VARCHAR(64),
    装修标准 VARCHAR(64),
    分期ID UNIQUEIDENTIFIER,
    分期名称 VARCHAR(200), 
    工程楼栋ID UNIQUEIDENTIFIER,
    工程楼栋名称 VARCHAR(200), 
    产品楼栋ID UNIQUEIDENTIFIER,
    产品楼栋名称 VARCHAR(200),
    户型 VARCHAR(64), --X房X厅X卫X阳台
    房 decimal(16,2),
    厅 decimal(16,2),
    卫 decimal(16,2),
    阳台 decimal(16,2)
);
 

--1、插入平台公司数据
INSERT INTO #ydkb_BaseInfo
    (
        组织架构ID,
        组织架构编码,
        组织架构父级ID,
        组织架构名称,
        组织架构类型,
        组织架构类型名称,
        平台公司GUID,
        平台公司名称
    )
SELECT
    DISTINCT a.buguid,
    b.DevelopmentCompanyCode,
    bu.ParentGUID,
    a.DevelopmentCompanyName,
    1,
    '平台公司',
    a.DevelopmentCompanyGUID,
    a.DevelopmentCompanyName
FROM erp25.dbo.companyjoin a
    LEFT JOIN erp25.dbo.myBusinessUnit bu ON a.buguid = bu.BUGUID
    LEFT JOIN erp25.dbo.p_DevelopmentCompany b ON a.DevelopmentCompanyGUID = b.DevelopmentCompanyGUID
WHERE a.DevelopmentCompanyGUID IN ('C69E89BB-A2DB-E511-80B8-E41F13C51836','461889dc-e991-4238-9d7c-b29e0aa347bb','5A4B2DEF-E803-49F8-9FE2-308735E7233D','7DF92561-3B0D-E711-80BA-E61F13C57837');

--2、插入城市公司数据,按照投管系统项目概况上的项目所属城市公司归集
--创建临时表
SELECT y.组织架构ID AS ParentGUID,
    city.ParamValue AS BUName,
    y.组织架构编码 AS ParentBUCode,
    mp.DevelopmentCompanyGUID,
    y.平台公司名称,
    city.ParamGUID 
INTO #AreaTemp
FROM erp25.dbo.mdm_Project mp
    inner JOIN #ydkb_BaseInfo y ON y.平台公司GUID = mp.DevelopmentCompanyGUID
    AND y.组织架构类型 = 1
    inner JOIN (
        SELECT
            ParamGUID,
            ParamValue
        FROM
            myBizParamOption
        WHERE
            ParamName = 'mdm_XMSSCSGS'
    ) city ON city.ParamGUID = mp.XMSSCSGSGUID
WHERE mp.Level = 2
GROUP BY
    y.组织架构ID,
    ParamGUID,
    city.ParamValue,
    y.组织架构编码,
    mp.DevelopmentCompanyGUID,
    y.平台公司名称;

/*
2024-11-22 东莞公司归属合并
SELECT distinct y.组织架构ID AS ParentGUID,
    case when ParamGUID in ('9A391706-FC87-45EE-B5B3-3945FE85187C','9DABB377-2927-485E-B5E0-EF9DA343AC31') 
then '东莞' else ParamValue end AS BUName,
    y.组织架构编码 AS ParentBUCode,
    mp.DevelopmentCompanyGUID,
    y.平台公司名称,
    case when city.ParamGUID ='9A391706-FC87-45EE-B5B3-3945FE85187C' then '9DABB377-2927-485E-B5E0-EF9DA343AC31' else city.ParamGUID end ParamGUID 
INTO #AreaTemp
FROM erp25.dbo.mdm_Project mp
    inner JOIN #ydkb_BaseInfo y ON y.平台公司GUID = mp.DevelopmentCompanyGUID
    AND y.组织架构类型 = 1
    inner JOIN (
        SELECT
            ParamGUID,
            ParamValue
        FROM
            myBizParamOption
        WHERE
            ParamName = 'mdm_XMSSCSGS'
    ) city ON city.ParamGUID = mp.XMSSCSGSGUID
WHERE mp.Level = 2
GROUP BY
    y.组织架构ID,
    ParamGUID,
    city.ParamValue,
    y.组织架构编码,
    mp.DevelopmentCompanyGUID,
    y.平台公司名称;
  */  

INSERT INTO #ydkb_BaseInfo
    (
        组织架构ID,
        组织架构编码,
        组织架构父级ID,
        组织架构名称,
        组织架构类型,
        组织架构类型名称,
        平台公司GUID,
        平台公司名称
    )
SELECT ParamGUID AS BUGUID,
    ParentBUCode + '.' + CONVERT(
        VARCHAR(10),
        ROW_NUMBER() OVER (
            PARTITION BY ParentGUID
            ORDER BY
                BUName
        )
    ) AS BUCode,
    ParentGUID,
    BUName,
    2 AS BUType,
    '城市公司',
    DevelopmentCompanyGUID,
    平台公司名称
FROM #AreaTemp
WHERE ISNULL(BUName, '') <> '';

--3、插入一级项目数据
INSERT INTO #ydkb_BaseInfo
    (
        组织架构ID,
        组织架构编码,
        组织架构父级ID,
        组织架构名称,
        组织架构类型,
        组织架构类型名称,
        平台公司GUID,
        平台公司名称,
        项目guid,
        项目代码,
        项目名称
    )
SELECT DISTINCT mp.ProjGUID AS BUGUID,
    b.组织架构编码 + '.' + mp.ProjCode AS BUCode,
    b.组织架构ID AS ParentGUID,
    mp.SpreadName AS BUName,
    --修改成投管系统推广名称
    3 AS BUType,
    '项目',
    mp.DevelopmentCompanyGUID,
    b.平台公司名称,
    mp.projguid,
    mp.projcode,
    mp.spreadname
FROM erp25.dbo.mdm_Project mp
    LEFT JOIN (
        SELECT
            ParamGUID,
            ParamValue
        FROM
            myBizParamOption
        WHERE
            ParamName = 'mdm_XMSSCSGS'
    ) city ON city.ParamGUID = mp.XMSSCSGSGUID
    INNER JOIN #ydkb_BaseInfo b ON mp.DevelopmentCompanyGUID = b.平台公司GUID
    AND city.ParamValue = b.组织架构名称
    AND b.组织架构类型 = 2
WHERE mp.Level = 2 

/*
2024-11-22 东莞公司归属合并
INSERT INTO #ydkb_BaseInfo
    (
        组织架构ID,
        组织架构编码,
        组织架构父级ID,
        组织架构名称,
        组织架构类型,
        组织架构类型名称,
        平台公司GUID,
        平台公司名称,
        项目guid,
        项目代码,
        项目名称
    )
SELECT DISTINCT mp.ProjGUID AS BUGUID,
    b.组织架构编码 + '.' + mp.ProjCode AS BUCode,
    b.组织架构ID AS ParentGUID,
    mp.SpreadName AS BUName,
    --修改成投管系统推广名称
    3 AS BUType,
    '项目',
    mp.DevelopmentCompanyGUID,
    b.平台公司名称,
    mp.projguid,
    mp.projcode,
    mp.spreadname
FROM erp25.dbo.mdm_Project mp
    LEFT JOIN (
        SELECT ParamGUID,
            ParamValue
        FROM myBizParamOption
        WHERE ParamName = 'mdm_XMSSCSGS'
    ) city ON city.ParamGUID = mp.XMSSCSGSGUID
    INNER JOIN #ydkb_BaseInfo b ON mp.DevelopmentCompanyGUID = b.平台公司GUID
    AND case when ParamGUID in ('9A391706-FC87-45EE-B5B3-3945FE85187C','9DABB377-2927-485E-B5E0-EF9DA343AC31') 
then '东莞' else ParamValue end = b.组织架构名称
    AND b.组织架构类型 = 2
WHERE mp.Level = 2 
*/

--4、插入业态类型信息
--生成业态编码
SELECT ProductType,
    CONVERT(
        VARCHAR(10),
        ROW_NUMBER() OVER (
            ORDER BY
                ProductType DESC
        )
    ) AS ProductTypeCode 
INTO #ProductTypeCode
FROM mdm_Product
GROUP BY ProductType;

--预处理业态数据，,投管系统项目的业态不等于分期合计值,需特殊处理
select distinct isnull(pj.parentprojguid, pd.projguid) as projguid,ProductType,ProductName,BusinessType,Standard
into #mdm_Product
from erp25.dbo.mdm_Product pd
left join erp25.dbo.mdm_project pj on pd.projguid = pj.projguid and pj.level = 3

INSERT INTO #ydkb_BaseInfo
    (
        组织架构ID,
        组织架构编码,
        组织架构父级ID,
        组织架构名称,
        组织架构类型,
        组织架构类型名称,
        平台公司GUID,
        平台公司名称,
        项目guid,
        项目代码,
        项目名称,
        业态
    )
SELECT
    NEWID() AS 组织架构ID,
    b.组织架构编码 + '.' + c.ProductTypeCode AS 组织架构编码,
    pd.ProjGUID AS 组织架构父级ID,
    pd.ProductType AS 组织架构名称,
    4 组织架构类型,
    '业态',
    b.平台公司GUID AS 平台公司GUID,
    b.平台公司名称,
    b.组织架构id,
    b.项目代码,
    b.项目名称,
    pd.ProductType
FROM (select distinct projguid,ProductType from #mdm_Product) pd
    INNER JOIN #ydkb_BaseInfo b ON pd.ProjGUID = b.组织架构ID
    LEFT JOIN #ProductTypeCode c ON c.ProductType = pd.ProductType
WHERE  b.组织架构类型 = 3

--5、插入产品信息
--生成产品组合键的编码
SELECT ProductType,ProductName,BusinessType,Standard,
    CONVERT(
        VARCHAR(10),
        ROW_NUMBER() OVER (
            ORDER BY
                ProductType,ProductName,BusinessType,Standard DESC
        )
    ) AS ProductCode 
INTO #ProductCode
FROM mdm_Product
GROUP BY ProductType,ProductName,BusinessType,Standard

INSERT INTO #ydkb_BaseInfo
    (
        组织架构ID,
        组织架构编码,
        组织架构父级ID,
        组织架构名称,
        组织架构类型,
        组织架构类型名称,
        平台公司GUID,
        平台公司名称,
        项目guid,
        项目代码,
        项目名称,
        业态,
        产品名称,
        商业类型,
        装修标准
    )
select newid() 组织架构ID,
       b.组织架构编码 + '.' + c.ProductCode 组织架构编码,
       b.组织架构id 组织架构父级ID,
       isnull(pd.ProductName,'')+'_'+isnull(pd.BusinessType,'')+'_'+isnull(pd.Standard,'') 组织架构名称,
       5 组织架构类型,
       '产品名称_商品类型_装修标准' 组织架构类型名称,
       b.平台公司GUID,
       b.平台公司名称,
       b.项目guid,
       b.项目代码,
       b.项目名称,
       b.业态,
       pd.ProductName 产品名称,
       pd.BusinessType 商业类型,
       pd.Standard 装修标准    
FROM #mdm_Product pd 
INNER JOIN #ydkb_BaseInfo b ON pd.ProjGUID = b.项目guid and pd.producttype = b.组织架构名称 and b.组织架构类型 = 4
LEFT JOIN #ProductCode c ON c.ProductType = pd.ProductType and c.ProductName = pd.ProductName and c.BusinessType = pd.BusinessType 
and c.Standard = pd.Standard 

--6、插入工程楼栋信息
select distinct bi.组织架构ID 组织架构父级ID,
    gc.BldName 组织架构名称,
    6 组织架构类型,
    gc.BldName 工程楼栋名称,
    gc.GCBldGUID 工程楼栋ID, 
    bi.组织架构编码 as parentcode,  
    bi.平台公司GUID,
    bi.平台公司名称,
    bi.项目guid,
    bi.项目代码,
    bi.项目名称,
    bi.业态,
    bi.产品名称,
    bi.商业类型,
    bi.装修标准,
    mp.projguid as 分期id,
    mp.spreadname as 分期名称 
    into #tmpGc
from dbo.mdm_GCBuild gc
    inner JOIN dbo.mdm_SaleBuild a ON gc.GCBldGUID = a.GCBldGUID
    INNER JOIN dbo.mdm_Product pd ON a.ProductGUID = pd.ProductGUID
    INNER JOIN dbo.mdm_Project mp ON mp.ProjGUID = pd.ProjGUID
    LEFT JOIN dbo.mdm_Project mp1 ON mp1.ProjGUID = mp.ParentProjGUID
    inner JOIN #ydkb_BaseInfo bi ON bi.项目guid = mp1.ProjGUID
    AND bi.产品名称 = pd.ProductName and bi.业态 = pd.producttype 
    AND bi.商业类型 = pd.BusinessType and bi.装修标准 = pd.Standard
WHERE bi.组织架构类型 = 5
    
INSERT INTO #ydkb_BaseInfo
    (
        组织架构ID,
        组织架构编码,
        组织架构父级ID,
        组织架构名称,
        组织架构类型, 
        组织架构类型名称,
        平台公司GUID,
        平台公司名称,
        项目guid,
        项目代码,
        项目名称,
        业态,
        产品名称,
        商业类型,
        装修标准,
        分期ID,
        分期名称, 
        工程楼栋ID,
        工程楼栋名称
    )
SELECT newid() 组织架构ID,
    parentcode + '.' + CONVERT(
        VARCHAR(10),
        ROW_NUMBER() OVER (
            PARTITION BY 组织架构父级ID
            ORDER BY
                组织架构名称
        )
    ) 组织架构编码,
    组织架构父级ID,
    组织架构名称,
    组织架构类型, 
    '工程楼栋' 组织架构类型名称,
    平台公司GUID,
    平台公司名称,
    项目guid,
    项目代码,
    项目名称,
    业态,
    产品名称,
    商业类型,
    装修标准,
    分期ID,
    分期名称,
    工程楼栋ID,
    工程楼栋名称
FROM #tmpGc

--7、插入产品楼栋信息
INSERT INTO #ydkb_BaseInfo
    (
        组织架构ID,
        组织架构编码,
        组织架构父级ID,
        组织架构名称,
        组织架构类型, 
        组织架构类型名称,
        平台公司GUID,
        平台公司名称,
        项目guid,
        项目代码,
        项目名称,
        业态,
        产品名称,
        商业类型,
        装修标准,
        分期ID,
        分期名称,
        工程楼栋ID,
        工程楼栋名称,
        产品楼栋ID,
        产品楼栋名称
    )
SELECT
    a.SaleBldGUID AS 组织架构ID,
    bi.组织架构编码 + '.' + ISNULL(a.BldCode, a.BldName) AS 组织架构编码,
    bi.组织架构ID AS 组织架构父级ID,
    ISNULL(a.BldCode, a.BldName) AS 组织架构名称,
    7 AS 组织架构类型,
    '产品楼栋' 组织架构类型名称 ,
    bi.平台公司GUID,
    bi.平台公司名称,
    bi.项目guid,
    bi.项目代码,
    bi.项目名称,
    bi.业态,
    bi.产品名称,
    bi.商业类型,
    bi.装修标准,
    bi.分期ID,
    bi.分期名称,
    bi.工程楼栋ID,
    bi.工程楼栋名称,
    a.SaleBldGUID 产品楼栋ID,
    ISNULL(a.BldCode, a.BldName) 产品楼栋名称
FROM dbo.mdm_SaleBuild a
    LEFT JOIN dbo.mdm_GCBuild gc ON gc.GCBldGUID = a.GCBldGUID
    INNER JOIN dbo.mdm_Product pd ON a.ProductGUID = pd.ProductGUID
    INNER JOIN dbo.mdm_Project mp ON mp.ProjGUID = pd.ProjGUID
    LEFT JOIN dbo.mdm_Project mp1 ON mp1.ProjGUID = mp.ParentProjGUID
    inner JOIN #ydkb_BaseInfo bi ON bi.工程楼栋ID = a.GCBldGUID  
    AND bi.产品名称 = pd.ProductName and bi.业态 = pd.producttype 
    AND bi.商业类型 = pd.BusinessType and bi.装修标准 = pd.Standard
WHERE bi.组织架构类型 = 6

--8、户型
--获取户型数据：基础数据系统
select distinct hx.ProductBuildGUID, roomnum,Hall,Toilet,Balcony,
CASE WHEN RoomNum = -1 THEN '' ELSE CAST(RoomNum AS VARCHAR(50)) + '房' END 
+ CASE WHEN Hall = -1 THEN '' ELSE CAST(Hall AS VARCHAR(50)) + '厅' END
+ CASE WHEN Toilet = -1 THEN '' ELSE CAST(CAST(Toilet AS REAL) AS VARCHAR(50)) + '卫' END 
+ CASE WHEN Balcony = -1 THEN '' ELSE CAST(Balcony AS VARCHAR(50)) + '阳台' END as hxstru, 
    case when hx.bldarea <= 90 then '90㎡以下' when bldarea >90 and bldarea<=120 then '90-120㎡'
    when bldarea >120 and bldarea<=140 then '120-140㎡' else '140㎡以上' end as areasection
into #hxinfo
from  [172.16.4.161].highdata_prod.dbo.data_wide_dws_s_HxAnalysis_Summary hx 
where  producttype in ('住宅','高级住宅','企业会所','公寓')
 
 
--户型结构编号
SELECT hxStru,areasection,
    CONVERT(
        VARCHAR(10),
        ROW_NUMBER() OVER ( ORDER BY hxStru)
    ) AS HxCode 
INTO #HxCode
FROM #hxinfo
GROUP BY hxStru,areasection

INSERT INTO #ydkb_BaseInfo
    (
        组织架构ID,
        组织架构编码,
        组织架构父级ID,
        组织架构名称,
        组织架构类型, 
        组织架构类型名称 ,
        平台公司GUID,
        平台公司名称,
        项目guid,
        项目代码,
        项目名称,
        业态,
        产品名称,
        商业类型,
        装修标准,
        分期ID,
        分期名称,
        工程楼栋ID,
        工程楼栋名称,
        产品楼栋ID,
        产品楼栋名称,
        户型, --X房X厅X卫X阳台
        房,
        厅,
        卫,
        阳台
    ) 
SELECT
    newid() AS 组织架构ID,
    bi.组织架构编码 + '.' + code.hxcode AS 组织架构编码,
    bi.组织架构ID AS 组织架构父级ID,
    isnull(a.hxstru,'')+'('+a.areasection+')' AS 组织架构名称,
    8 AS 组织架构类型, 
    '户型' 组织架构类型名称 ,
    bi.平台公司GUID,
    bi.平台公司名称,
    bi.项目guid,
    bi.项目代码,
    bi.项目名称,
    bi.业态,
    bi.产品名称,
    bi.商业类型,
    bi.装修标准,
    bi.分期ID,
    bi.分期名称,
    bi.工程楼栋ID,
    bi.工程楼栋名称,
    bi.产品楼栋ID,
    bi.产品楼栋名称,
    a.HxStru 户型, --X房X厅X卫X阳台
    a.roomnum 房,
    a.Hall 厅,
    a.Toilet 卫,
    a.Balcony 阳台    
FROM #hxinfo a
    inner JOIN #ydkb_BaseInfo bi ON bi.组织架构id = a.ProductBuildGUID  
    inner join #HxCode code on code.hxstru = a.hxstru  and code.areasection = a.areasection
WHERE bi.组织架构类型 = 7

--查询结果       
SELECT * FROM #ydkb_BaseInfo 

drop table #AreaTemp,#ProductTypeCode,#tmpGc,#ydkb_BaseInfo,#mdm_Product,#HxCode,#hxinfo,#ProductCode
