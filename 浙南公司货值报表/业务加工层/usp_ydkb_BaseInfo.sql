USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_ydkb_BaseInfo]    Script Date: 2025/1/6 10:28:29 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--清洗组织架构表，先删除后插入

--usp_ydkb_BaseInfo
ALTER PROC [dbo].[usp_ydkb_BaseInfo]
AS
    BEGIN
        IF OBJECT_ID(N'ydkb_BaseInfo', N'U') IS NOT NULL
            BEGIN
                DROP TABLE  ydkb_BaseInfo;
            END; 


        CREATE TABLE ydkb_BaseInfo
            (
              组织架构ID VARCHAR(100) NOT NULL ,
              组织架构编码 [VARCHAR](100) NULL ,
              组织架构父级ID VARCHAR(100) NOT NULL ,
              组织架构名称 [VARCHAR](400) NULL ,
              组织架构类型 [INT] NULL ,--1平台公司 2城市公司 3一级项目 4分期
              项目状态 VARCHAR(20) ,--项目状态
              销售状态 VARCHAR(20), --销售状态
              操盘方式 VARCHAR(200) ,--操盘方式
              并表方式 VARCHAR(200) ,
              工程楼栋名称 VARCHAR(200) ,
              产品楼栋名称 VARCHAR(200) ,
              平台公司GUID UNIQUEIDENTIFIER, --平台公司
              获取时间 datetime
            );

      --插入平台公司数据
        INSERT  INTO dbo.ydkb_BaseInfo
                ( 组织架构ID , --销售系统BUGUID
                  组织架构编码 ,
                  组织架构父级ID ,--销售系统父级BUGUID
                  组织架构名称 ,
                  组织架构类型 ,
                  项目状态 ,
                  平台公司GUID
                )
                SELECT DISTINCT
                        a.buguid ,
                        b.DevelopmentCompanyCode ,
                        bu.ParentGUID ,
                        a.DevelopmentCompanyName ,
                        1 AS ProjStatus ,
                        '' AS ProjStatus ,
                        a.DevelopmentCompanyGUID
                FROM    erp25.dbo.companyjoin a
                        LEFT  JOIN erp25.dbo.myBusinessUnit bu ON a.buguid = bu.BUGUID
                        LEFT JOIN erp25.dbo.p_DevelopmentCompany b ON a.DevelopmentCompanyGUID = b.DevelopmentCompanyGUID
                WHERE   a.buname IN ( '湾区公司', '华南公司', '海南公司','上海公司','湖南公司','浙南公司' );
                



      --插入城市公司数据,按照投管系统项目概况上的项目所属城市公司归集

      --删除临时表
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#AreaTemp')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #AreaTemp;
            END; 

       --创建临时表
        SELECT  y.组织架构ID AS ParentGUID ,
                city.ParamValue AS BUName ,
                y.组织架构编码 AS ParentBUCode ,
                mp.DevelopmentCompanyGUID,
                city.ParamGUID
        INTO    #AreaTemp
        FROM    erp25.dbo.mdm_Project mp
                LEFT JOIN ydkb_BaseInfo y ON y.平台公司GUID = mp.DevelopmentCompanyGUID
                                             AND y.组织架构类型 = 1
                LEFT JOIN ( SELECT  ParamGUID ,
                                    ParamValue
                            FROM    myBizParamOption
                            WHERE   ParamName = 'mdm_XMSSCSGS'
                          ) city ON city.ParamGUID = mp.XMSSCSGSGUID
        WHERE   mp.Level = 2
                AND mp.DevelopmentCompanyGUID IN (
                'AADC0FA7-9546-49C9-B64B-825056C828ED',
                'C69E89BB-A2DB-E511-80B8-E41F13C51836',
                '526B9630-A469-4780-991D-E90F4DD6357B',
                '461889dc-e991-4238-9d7c-b29e0aa347bb',
                '5A4B2DEF-E803-49F8-9FE2-308735E7233D',
                '7DF92561-3B0D-E711-80BA-E61F13C57837') --华南公司、湾区公司、海南公司、上海公司、浙南公司
        GROUP BY y.组织架构ID ,
                 ParamGUID,
                city.ParamValue ,
                y.组织架构编码 ,
                mp.DevelopmentCompanyGUID;
        --where mp.DevelopmentCompanyGUID='AADC0FA7-9546-49C9-B64B-825056C828ED'


        INSERT  INTO dbo.ydkb_BaseInfo
                ( 组织架构ID ,
                  组织架构编码 ,
                  组织架构父级ID ,
                  组织架构名称 ,
                  组织架构类型 ,
                  项目状态 ,
                  平台公司GUID
                )
                SELECT  ---CONVERT(VARCHAR(max),HASHBYTES('MD5',BUName )) AS BUGUID ,
                        ParamGUID AS BUGUID ,
                        ParentBUCode + '.'
                        + CONVERT(VARCHAR(10), ROW_NUMBER() OVER ( PARTITION BY ParentGUID ORDER BY BUName )) AS BUCode ,
                        ParentGUID ,
                        BUName ,
                        2 AS BUType ,
                        '' AS ProjStatus ,
                        DevelopmentCompanyGUID
                FROM    #AreaTemp
                WHERE   ISNULL(BUName, '') <> '';
       

        --插入一级项目数据
        INSERT  INTO ydkb_BaseInfo
                ( 组织架构ID ,
                  组织架构编码 ,
                  组织架构父级ID ,
                  组织架构名称 ,
                  组织架构类型 ,
                  项目状态 ,
                  销售状态,
                  操盘方式 ,
                  并表方式 ,
                  平台公司GUID,
                  获取时间
                )
                SELECT DISTINCT
                        mp.ProjGUID AS BUGUID ,
                        b.组织架构编码 + '.' + mp.ProjCode AS BUCode ,
                        b.组织架构ID AS ParentGUID ,
                        mp.SpreadName AS BUName , --修改成投管系统推广名称
                        3 AS BUType , --1平台公司 2城市公司 3一级项目 4分期
                        mp.ProjStatus ,
                        mp.SaleStatus,
                        mp.TradersWay ,
                        mp.BbWay ,
                        mp.DevelopmentCompanyGUID,
                        mp.AcquisitionDate
                FROM    erp25.dbo.mdm_Project mp
                        LEFT JOIN ( SELECT  ParamGUID ,
                                            ParamValue
                                    FROM    myBizParamOption
                                    WHERE   ParamName = 'mdm_XMSSCSGS'
                                  ) city ON city.ParamGUID = mp.XMSSCSGSGUID
                        INNER JOIN ydkb_BaseInfo b ON mp.DevelopmentCompanyGUID = b.平台公司GUID
                                                      AND city.ParamValue = b.组织架构名称
                                                      AND b.组织架构类型 = 2
                WHERE   mp.Level = 2
                        AND mp.DevelopmentCompanyGUID IN (
                        'AADC0FA7-9546-49C9-B64B-825056C828ED',
                        'C69E89BB-A2DB-E511-80B8-E41F13C51836',
                        '526B9630-A469-4780-991D-E90F4DD6357B',
                        '461889dc-e991-4238-9d7c-b29e0aa347bb',
                        '5A4B2DEF-E803-49F8-9FE2-308735E7233D',
                        '7DF92561-3B0D-E711-80BA-E61F13C57837')
                        --排除肇庆端州区石牌留用地项目不做统计
                        --AND  mp.ProjGUID <>'58E917CE-2FA0-E811-80BF-E61F13C57837'
                      

        ----插入二级项目数据
        --INSERT  INTO ydkb_BaseInfo
        --        ( 组织架构ID ,
        --          组织架构编码 ,
        --          组织架构父级ID ,
        --          组织架构名称 ,
        --          组织架构类型 ,
        --          项目状态 ,
        --          平台公司GUID
        --        )
        --        SELECT DISTINCT
        --                mp.ProjGUID AS BUGUID ,
        --                b1.组织架构编码 + '.' + mp.ProjCode AS BUCode ,
        --                b.组织架构ID AS ParentGUID ,
        --                mp.ProjName AS BUName ,
        --                4 AS BUType , --1平台公司 2城市公司 3一级项目 4分期
        --                mp.ProjStatus ,
        --                mp.DevelopmentCompanyGUID
        --        FROM    erp25.dbo.mdm_Project mp
        --                LEFT JOIN ydkb_BaseInfo b ON mp.ParentProjGUID = b.组织架构ID
        --                                             AND b.组织架构类型 = 3
        --                LEFT  JOIN ydkb_BaseInfo b1 ON b.组织架构父级ID = b1.组织架构ID
        --                                               AND b1.组织架构类型 = 2
        --        WHERE   mp.Level = 3
        --                AND mp.DevelopmentCompanyGUID IN  ( 'AADC0FA7-9546-49C9-B64B-825056C828ED','C69E89BB-A2DB-E511-80B8-E41F13C51836')
        
        --生成业态编码
        --删除临时表
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ProductTypeCode')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #ProductTypeCode;
            END; 
        SELECT  ProductType ,
                CONVERT(VARCHAR(10), ROW_NUMBER() OVER ( ORDER BY ProductType DESC )) AS ProductTypeCode
        INTO    #ProductTypeCode
        FROM    mdm_Product
        GROUP BY ProductType;

		IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#mdm_product')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #mdm_product;
            END; 
        select distinct isnull(pj.parentprojguid, pd.projguid) as projguid,ProductType
		into #mdm_Product
		from erp25.dbo.mdm_Product pd
		left join erp25.dbo.mdm_project pj on pd.projguid = pj.projguid and pj.level = 3
        
        --插入产品业态类型信息
        INSERT  INTO ydkb_BaseInfo
                ( 组织架构ID ,
                  组织架构编码 ,
                  组织架构父级ID ,
                  组织架构名称 ,
                  组织架构类型 ,
                  项目状态 ,
                  平台公司GUID
                )
                SELECT  NEWID() AS 组织架构ID ,
                        b.组织架构编码 + '.' + c.ProductTypeCode AS 组织架构编码 ,
                        pd.ProjGUID AS 组织架构父级ID ,
                        pd.ProductType AS 组织架构名称 ,
                        4 组织架构类型 ,
                        '' AS 项目状态 ,
                        b.平台公司GUID AS 平台公司GUID
                FROM    #mdm_Product pd
                        INNER JOIN ydkb_BaseInfo b ON pd.ProjGUID = b.组织架构ID
                        LEFT JOIN #ProductTypeCode c ON c.ProductType = pd.ProductType
                WHERE   b.组织架构类型 = 3
                GROUP BY b.组织架构编码 + '.' + c.ProductTypeCode ,
                        pd.ProjGUID ,
                        pd.ProductType ,
                        b.平台公司GUID; 

        --插入楼栋信息
        INSERT  INTO ydkb_BaseInfo
                ( 组织架构ID ,
                  组织架构编码 ,
                  组织架构父级ID ,
                  组织架构名称 ,
                  组织架构类型 ,
                  项目状态 ,
                  工程楼栋名称 ,
                  产品楼栋名称 ,
                  平台公司GUID
                )
                SELECT  a.SaleBldGUID AS 组织架构ID ,
                        bi.组织架构编码 + '.' + ISNULL(a.BldCode, a.BldName) AS 组织架构编码 ,
                        bi.组织架构ID AS 组织架构父级ID ,
                        ISNULL(a.BldCode, a.BldName) AS 组织架构名称 ,
                        5 AS 组织架构类型 ,
                        mp1.ProjStatus AS 项目状态 ,
                        gc.BldName AS 工程楼栋名称 ,
                        a.BldName AS 产品楼栋名称 ,
                        mp1.DevelopmentCompanyGUID AS 平台公司GUID
                FROM    dbo.mdm_SaleBuild a
                        LEFT JOIN dbo.mdm_GCBuild gc ON gc.GCBldGUID = a.GCBldGUID
                        INNER  JOIN dbo.mdm_Product pd ON a.ProductGUID = pd.ProductGUID
                        INNER  JOIN dbo.mdm_Project mp ON mp.ProjGUID = pd.ProjGUID
                        LEFT  JOIN dbo.mdm_Project mp1 ON mp1.ProjGUID = mp.ParentProjGUID
                        LEFT   JOIN ydkb_BaseInfo bi ON bi.组织架构父级ID = mp1.ProjGUID
                                                        AND bi.组织架构名称 = pd.ProductType
                WHERE   bi.组织架构类型 = 4
                ORDER BY bi.组织架构编码 ,
                        bi.组织架构类型;

        --查询插入结果       
        SELECT  组织架构ID ,
                组织架构编码 ,
                组织架构父级ID ,
                组织架构名称 ,
                组织架构类型 ,
                项目状态,
                销售状态,                
                操盘方式 ,
                并表方式 ,
                工程楼栋名称 ,
                产品楼栋名称 ,
                平台公司GUID,
                获取时间
        FROM    ydkb_BaseInfo
        WHERE   ( 1 = 1 )
                AND 平台公司GUID IN ( 'AADC0FA7-9546-49C9-B64B-825056C828ED',
                                  'C69E89BB-A2DB-E511-80B8-E41F13C51836',
                                  '526B9630-A469-4780-991D-E90F4DD6357B',
                                '461889dc-e991-4238-9d7c-b29e0aa347bb',
                                '5A4B2DEF-E803-49F8-9FE2-308735E7233D',
                                '7DF92561-3B0D-E711-80BA-E61F13C57837')
        ORDER BY 组织架构编码 ,
                组织架构类型;
                
       --向ERP352的数据库上插入组织架构表
	   --先删除后插入
        DELETE  FROM myCost_erp352.dbo.ydkb_BaseInfo;

        INSERT  INTO myCost_erp352.dbo.ydkb_BaseInfo
                ( 组织架构ID ,
                  组织架构编码 ,
                  组织架构父级ID ,
                  组织架构名称 ,
                  组织架构类型 ,
                  项目状态 ,
                  销售状态,
                  操盘方式 ,
                  并表方式 ,
                  工程楼栋名称 ,
                  产品楼栋名称 ,
                  平台公司GUID,
                  获取时间
	            )
                SELECT  组织架构ID ,
                        组织架构编码 ,
                        组织架构父级ID ,
                        组织架构名称 ,
                        组织架构类型 ,
                        项目状态 ,
                        销售状态,
                        操盘方式 ,
                        并表方式 ,
                        工程楼栋名称 ,
                        产品楼栋名称 ,
                        平台公司GUID,
                        获取时间
                FROM    dbo.ydkb_BaseInfo;

    END; 
       
      