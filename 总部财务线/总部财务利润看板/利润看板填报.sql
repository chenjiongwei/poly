
-- 盈利规划利润表落盘
-- select  * from  data_wide_dws_qt_f090016当年销售对应结转计划
-- 盈利规划年度利润
create or alter  proc usp_ylgh_盈利规划年度利润预算数据
as 
begin 
        -- 定义变量
        DECLARE @bgyear DATETIME; --本年开始日期
        DECLARE @endyear DATETIME; --本年截止日期
        DECLARE @buguid VARCHAR(MAX);

        SET @bgyear = DATEADD(yy, DATEDIFF(yy, 0, getdate()), 0);
        --SET @endyear = @qxdate;
        SET @endyear = DATEADD(month, datediff(month, -1,getdate()), -1)   --0112改为月底最后一天

        SELECT  @buguid = STUFF(
                        (SELECT   RTRIM(',' + CONVERT(VARCHAR(MAX), devCom.DevelopmentCompanyGUID))
                        FROM     [172.16.4.141].erp25.dbo.myBusinessUnit unit
                                LEFT JOIN [172.16.4.141].erp25.dbo.companyjoin comJoin ON unit.BUGUID = comJoin.BUGUID
                                LEFT JOIN [172.16.4.141].erp25.dbo.p_DevelopmentCompany devCom ON devCom.DevelopmentCompanyGUID = comJoin.DevelopmentCompanyGUID
                                INNER JOIN(SELECT   DISTINCT DevelopmentCompanyGUID 
                                           FROM    [172.16.4.141].erp25.dbo.mdm_Project) p ON p.DevelopmentCompanyGUID = devCom.DevelopmentCompanyGUID
                        WHERE  IsEndCompany = 1 AND IsCompany = 1 
                        AND  unit.BUGUID <> '3FBB0CE8-E09A-47B8-AEA7-BBD84A926715'
                        AND   unit.BUGUID NOT IN ('bbd25c3a-209d-4f67-8ff2-d7f7ba39d0db', '32560bca-d251-4f93-bfe1-3809f94d5183', '669afb34-13e4-e411-b873-e41f13c51836' ,
                                                        'dfe03264-02f8-41a0-9d06-7b03582f7cf2' , 'bc5ba7b5-c677-43d7-ae24-3645b9482394', 'b35cdda9-43ac-40ae-8e1b-2711b960bf39' ,
                                                        '8412A5B2-0147-4AA3-813B-CC41D5D3D55B' ,    --福州公司、营口公司、丹东公司、通化公司
                                                        'B0F2292B-95B5-47DE-B50D-F1E61BDF4692', '75B65764-C79A-429B-9086-427BB923294F', '7220E82B-A68D-4444-8B4D-1BD5FB8C1996' ,
                                                        '1A0D7025-356E-4344-9074-C9BC416E6E66')
                        FOR XML PATH('')), 1, 1, '');

        -- 创建临时表
        SELECT  *
        INTO    #s_M002项目业态级毛利净利表_year
        FROM    [172.16.4.141].dss.dbo.nmap_s_M002项目业态级毛利净利表
        WHERE   1 = 0;

        -- 将本年数据插入到临时表中
        INSERT INTO #s_M002项目业态级毛利净利表_year
        EXEC [172.16.4.141].erp25.dbo.usp_s_M002项目业态级毛利净利表 @buguid, @bgyear, @endyear, NULL, '', 0;


        -- 清除数据避免数据重复
        truncate   table   盈利规划年度利润预算数据 

        insert into 盈利规划年度利润预算数据 
        SELECT
                ROW_NUMBER() over(order by flg.平台公司,a.明源匹配主键 ) 序号,
                -- 项目基本信息
                flg.平台公司          AS 公司,
                flg.投管代码,
                flg.项目名           AS 项目,
                flg.推广名,
                flg.获取时间         AS 获取日期,
                flg.[项目股权比例]    AS 我方股比,
                flg.并表方式         AS 是否并表,
                flg.合作方名称       AS 合作方,
                -- 是否风险合作方 (待补充)
                proj.UpSaleArea      AS 地上总可售面积,
                proj.TotalLandPrice  AS 项目地价,
                flg.盈利规划上线方式,
                a.产品类型,
                a.产品名称,
                a.装修标准,
                a.商品类型,
                a.明源匹配主键,
                a.业态组合键,

                -- 年度签约预算
                a.当期签约面积 as  签约面积,  -- 年度签约面积
                a.当期签约套数 as 签约个数, -- 年度签约套数
                a.当期签约金额  as 签约, -- 年度签约金额
                a.当期认购金额不含税 as 签约不含税, -- 年度签约不含税金额
                -- 单方成本费用
                a.盈利规划营业成本单方 as  营业成本单方,
                a.土地款_单方 as  土地款单方,
                a.除地外直投_单方 as 除地价外直投单方,
                a.开发间接费单方 as  开发间接费单方,
                a.资本化利息单方 as  资本化利息单方,
                a.盈利规划股权溢价单方 as  股权溢价单方,
                a.盈利规划营销费用单方 as  营销费用单方,
                a.盈利规划综合管理费单方协议口径 as 综合管理费单方协议口径,
                a.盈利规划税金及附加单方 as  税金及附加单方,

                -- 年度签约利润_原有版本
                isnull(a.当期签约面积,0) *  isnull(a.盈利规划营业成本单方,0) as  营业成本, -- 营业成本单方签约面积
                isnull(a.当期签约面积,0) * isnull(a.盈利规划股权溢价单方,0) as 股权溢价,
                isnull(a.当期签约面积,0) * isnull(a.盈利规划营销费用单方,0) as 营销费用,
                isnull(a.当期签约面积,0) * isnull(a.盈利规划营销费用单方,0) as 管理费用,
                isnull(a.当期签约面积,0) * isnull(a.盈利规划税金及附加单方,0) as  税金及附加,
                a.税前利润签约 as 税前利润,
                a.净利润签约 as 净利润
                -- 年度签约利润_修正版本
                -- 其中：本年结转_原有版本
                -- 其中：本年结转_修正版本
                -- 其中：第二年结转_原有版本
                -- 其中：第二年结转_修正版
                -- 其中：第三年结转_原有版本
                -- 其中：第三年结转_修正版
        FROM 
        #s_M002项目业态级毛利净利表_year a 
        INNER JOIN [172.16.4.141].erp25.dbo.vmdm_projectFlagnew flg ON a.ProjGUID = flg.ProjGUID
        INNER JOIN data_wide_dws_mdm_Project proj  ON proj.ProjGUID = a.projguid


        
  -- 删除临时表
     drop table  #s_M002项目业态级毛利净利表_year

end 



