USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_ydkb_dthz_wq_deal_returninfo]    Script Date: 2025/1/6 10:41:10 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/* 
author:ltx  date:20220430
说明：湾区货量报表回笼

运行样例：[usp_ydkb_dthz_wq_deal_returninfo]

modify:lintx  date:20220608
1、增加年初待收款
年初待收款：取房款表1月1号的待收款合计

modify:lintx date:20221107
1、增加本日/本周回笼，只统计到项目及项目层级以上
本周回笼：取房款表最近7天清洗的本日回笼数汇总值
本日回笼：取昨天的清洗数据

modify:lintx date:20231117
1、增加今年及去年的回笼任务
2、增加去年的回笼金额

modify:chenjw date:20240726
1、增加待收款金额
*/

ALTER PROC [dbo].[usp_ydkb_dthz_wq_deal_returninfo]
AS
    BEGIN
        ---------------------参数设置------------------------
        DECLARE @bnYear VARCHAR(4);

        SET @bnYear = YEAR(GETDATE());

        DECLARE @byMonth VARCHAR(2);

        SET @byMonth = MONTH(GETDATE());

        DECLARE @buguid VARCHAR(max) = '248B1E17-AACB-E511-80B8-E41F13C51836,4975b69c-9953-4dd0-a65e-9a36db8c66df,4A1E877C-A0B2-476D-9F19-B5C426173C38,31120F08-22C4-4220-8ED2-DCAD398C823C';
        DECLARE @developmentguid VARCHAR(max) = 'C69E89BB-A2DB-E511-80B8-E41F13C51836,461889dc-e991-4238-9d7c-b29e0aa347bb,5A4B2DEF-E803-49F8-9FE2-308735E7233D,7DF92561-3B0D-E711-80BA-E61F13C57837';
        DECLARE @本周一 DATETIME; --取自然周（周一至周日为一周）

        SET @本周一 = CASE WHEN DATEPART(WEEKDAY, GETDATE() - 1) = 1 THEN DATEADD(ww, 0, DATEADD(WEEK, DATEDIFF(ww, 0, GETDATE() - 2), 0))
                        ELSE DATEADD(ww, 0, DATEADD(WEEK, DATEDIFF(ww, 0, GETDATE() - 1), 0))
                   END;

        DECLARE @本周天 DATETIME;

        SET @本周天 = CASE WHEN DATEPART(WEEKDAY, GETDATE() - 1) = 1 THEN DATEADD(ww, 0, DATEADD(WEEK, DATEDIFF(ww, 0, GETDATE() - 2), 6))
                        ELSE DATEADD(ww, 0, DATEADD(WEEK, DATEDIFF(ww, 0, GETDATE() - 1), 6))
                   END;

        ---------------------产品楼栋粒度统计--------------------- 
        --获取本年各月份的回笼金额
        SELECT  p.BldGUID ,
                p.ProductType ,
                paret.ProjGUID ,
                SUM(CASE WHEN (MONTH(getin.GetDate) = '1') THEN ISNULL(getin.Amount, 0)ELSE 0 END) * 1.0 / 10000.0 AS Jan回笼金额 ,
                SUM(CASE WHEN (MONTH(getin.GetDate) = '2') THEN ISNULL(getin.Amount, 0)ELSE 0 END) * 1.0 / 10000.0 AS Feb回笼金额 ,
                SUM(CASE WHEN (MONTH(getin.GetDate) = '3') THEN ISNULL(getin.Amount, 0)ELSE 0 END) * 1.0 / 10000.0 AS Mar回笼金额 ,
                SUM(CASE WHEN (MONTH(getin.GetDate) = '4') THEN ISNULL(getin.Amount, 0)ELSE 0 END) * 1.0 / 10000.0 AS Apr回笼金额 ,
                SUM(CASE WHEN (MONTH(getin.GetDate) = '5') THEN ISNULL(getin.Amount, 0)ELSE 0 END) * 1.0 / 10000.0 AS May回笼金额 ,
                SUM(CASE WHEN (MONTH(getin.GetDate) = '6') THEN ISNULL(getin.Amount, 0)ELSE 0 END) * 1.0 / 10000.0 AS Jun回笼金额 ,
                SUM(CASE WHEN (MONTH(getin.GetDate) = '7') THEN ISNULL(getin.Amount, 0)ELSE 0 END) * 1.0 / 10000.0 AS July回笼金额 ,
                SUM(CASE WHEN (MONTH(getin.GetDate) = '8') THEN ISNULL(getin.Amount, 0)ELSE 0 END) * 1.0 / 10000.0 AS Aug回笼金额 ,
                SUM(CASE WHEN (MONTH(getin.GetDate) = '9') THEN ISNULL(getin.Amount, 0)ELSE 0 END) * 1.0 / 10000.0 AS Sep回笼金额 ,
                SUM(CASE WHEN (MONTH(getin.GetDate) = '10') THEN ISNULL(getin.Amount, 0)ELSE 0 END) * 1.0 / 10000.0 AS Oct回笼金额 ,
                SUM(CASE WHEN (MONTH(getin.GetDate) = '11') THEN ISNULL(getin.Amount, 0)ELSE 0 END) * 1.0 / 10000.0 AS Nov回笼金额 ,
                SUM(CASE WHEN (MONTH(getin.GetDate) = '12') THEN ISNULL(getin.Amount, 0)ELSE 0 END) * 1.0 / 10000.0 AS Dec回笼金额
        INTO    #ld_hl
        FROM    dbo.s_Trade tr
                LEFT JOIN dbo.s_Getin getin ON tr.TradeGUID = getin.SaleGUID
                INNER JOIN dbo.ep_room p ON p.RoomGUID = tr.RoomGUID
                INNER JOIN dbo.p_Project pj ON pj.ProjGUID = p.ProjGUID
                INNER JOIN dbo.p_Project paret ON paret.ProjCode = pj.ParentCode
        WHERE   DATEDIFF(yy, getin.GetDate, GETDATE()) = 0 AND  getin.Status IS NULL AND pj.BUGUID IN(SELECT    Value FROM  dbo.fn_Split2(@buguid, ',') )
        GROUP BY p.BldGUID ,
                 p.ProductType ,
                 paret.ProjGUID;

        --获取年初待收款金额
        SELECT  topprojguid AS projguid ,
                r.BldGUID ,
                r.ProductType ,
                --SUM(ISNULL(签约累计待收款,0)+ISNULL(mx.认购累计待收款,0))/10000.0 AS 年初待收款合计
                SUM(ISNULL(待收房款合计, 0)) / 10000.0 AS 年初待收款合计
        INTO    #ld_ncdsk
        FROM    dbo.s_gsfkylbmxb mx
                INNER JOIN ep_room r ON r.Roomguid = mx.roomguid
        WHERE   DATEDIFF(dd, qxDate, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-01-01') = 0 AND   r.BUGUID IN(SELECT  Value FROM  dbo.fn_Split2(@buguid, ',') )
        GROUP BY topprojguid ,
                 r.BldGUID ,
                 r.ProductType;

        --获取楼栋层级的待收款金额
        SELECT  topprojguid AS projguid ,
                r.BldGUID ,
                r.ProductType ,
                SUM(ISNULL(待收房款合计, 0)) / 10000.0 AS 待收款合计
        INTO    #ld_dsk
        FROM    dbo.s_gsfkylbmxb mx
                INNER JOIN ep_room r ON r.Roomguid = mx.roomguid
        WHERE   DATEDIFF(dd, qxDate, GETDATE() ) = 0 AND   r.BUGUID IN(SELECT  Value FROM  dbo.fn_Split2(@buguid, ',') )
        GROUP BY topprojguid ,
                 r.BldGUID ,
                 r.ProductType;

        ---------------------业态粒度统计---------------------  
        --获取本年每月回笼金额
        --操盘项目
        SELECT  ld.ProductType ,
                ld.ProjGUID ,
                SUM(ld.Jan回笼金额) AS Jan回笼金额 ,
                SUM(ld.Feb回笼金额) AS Feb回笼金额 ,
                SUM(ld.Mar回笼金额) AS Mar回笼金额 ,
                SUM(ld.Apr回笼金额) AS Apr回笼金额 ,
                SUM(ld.May回笼金额) AS May回笼金额 ,
                SUM(ld.Jun回笼金额) AS Jun回笼金额 ,
                SUM(ld.July回笼金额) AS July回笼金额 ,
                SUM(ld.Aug回笼金额) AS Aug回笼金额 ,
                SUM(ld.Sep回笼金额) AS Sep回笼金额 ,
                SUM(ld.Oct回笼金额) AS Oct回笼金额 ,
                SUM(ld.Nov回笼金额) AS Nov回笼金额 ,
                SUM(ld.Dec回笼金额) AS Dec回笼金额
        INTO    #yt_hl
        FROM    #ld_hl ld
        GROUP BY ld.ProductType ,
                 ld.ProjGUID
        --合作业绩
        UNION ALL
        SELECT  yc.ProductType ,
                ys.ProjGUID ,
                SUM(CASE WHEN yd.DateMonth = 1 THEN yc.huilongjiner ELSE 0 END) AS Jan回笼金额 ,
                SUM(CASE WHEN yd.DateMonth = 2 THEN yc.huilongjiner ELSE 0 END) AS Feb回笼金额 ,
                SUM(CASE WHEN yd.DateMonth = 3 THEN yc.huilongjiner ELSE 0 END) AS Mar回笼金额 ,
                SUM(CASE WHEN yd.DateMonth = 4 THEN yc.huilongjiner ELSE 0 END) AS Apr回笼金额 ,
                SUM(CASE WHEN yd.DateMonth = 5 THEN yc.huilongjiner ELSE 0 END) AS May回笼金额 ,
                SUM(CASE WHEN yd.DateMonth = 6 THEN yc.huilongjiner ELSE 0 END) AS Jun回笼金额 ,
                SUM(CASE WHEN yd.DateMonth = 7 THEN yc.huilongjiner ELSE 0 END) AS July回笼金额 ,
                SUM(CASE WHEN yd.DateMonth = 8 THEN yc.huilongjiner ELSE 0 END) AS Aug回笼金额 ,
                SUM(CASE WHEN yd.DateMonth = 9 THEN yc.huilongjiner ELSE 0 END) AS Sep回笼金额 ,
                SUM(CASE WHEN yd.DateMonth = 10 THEN yc.huilongjiner ELSE 0 END) AS Oct回笼金额 ,
                SUM(CASE WHEN yd.DateMonth = 11 THEN yc.huilongjiner ELSE 0 END) AS Nov回笼金额 ,
                SUM(CASE WHEN yd.DateMonth = 12 THEN yc.huilongjiner ELSE 0 END) AS Dec回笼金额
        FROM    dbo.s_YJRLProducteDescript yc
                INNER JOIN dbo.s_YJRLProducteDetail yd ON yc.ProducteDetailGUID = yd.ProducteDetailGUID
                INNER JOIN dbo.s_YJRLProjSet ys ON ys.ProjSetGUID = yd.ProjSetGUID
        WHERE   yd.Shenhe = '审核' AND yd.DateYear = YEAR(GETDATE()) AND  ys.BUGuid IN(SELECT Value FROM  dbo.fn_Split2(@buguid, ',') )
        GROUP BY yc.ProductType ,
                 ys.ProjGUID;

        ---------------------项目粒度统计---------------------  
        --获取年初待收款金额
        SELECT  topprojguid AS projguid ,
                SUM(ISNULL(签约累计待收款, 0) + ISNULL(mx.认购累计待收款, 0)) AS 年初待收款合计
        INTO    #proj_ncdsk
        FROM    dbo.s_gsfkylbhzb mx
        WHERE   DATEDIFF(dd, qxDate, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-01-01') = 0 AND BUGUID IN(SELECT    Value FROM  dbo.fn_Split2(@buguid, ',') )
        GROUP BY topprojguid;

		--获取项目待收款金额
        SELECT  topprojguid AS projguid ,
                SUM(ISNULL(签约累计待收款, 0) + ISNULL(mx.认购累计待收款, 0)) AS 待收款合计
        INTO    #proj_dsk
        FROM    dbo.s_gsfkylbhzb mx
        WHERE   DATEDIFF(dd, qxDate, GETDATE()) = 0 AND BUGUID IN(SELECT    Value FROM  dbo.fn_Split2(@buguid, ',') )
        GROUP BY topprojguid;

        ---汇总数据
        IF EXISTS (SELECT   *
                   FROM dbo.sysobjects
                   WHERE id = OBJECT_ID(N'ydkb_dthz_wq_deal_returninfo') AND OBJECTPROPERTY(id, 'IsTable') = 1)
            BEGIN
                DROP TABLE ydkb_dthz_wq_deal_returninfo;
            END;

        --湾区PC端货量报表回笼信息
        CREATE TABLE ydkb_dthz_wq_deal_returninfo (组织架构父级ID UNIQUEIDENTIFIER ,
                                                   组织架构ID UNIQUEIDENTIFIER ,
                                                   组织架构名称 VARCHAR(400) ,
                                                   组织架构编码 [VARCHAR](100) ,
                                                   组织架构类型 [INT] ,
                                                   累计已回笼金额 MONEY ,
                                                   本年回笼金额 MONEY ,
                                                   本月回笼金额 MONEY ,
                                                   本年签约本年回笼 MONEY ,
                                                   年初待收款回笼 MONEY ,

                                                    --1-12月的回笼情况
                                                   Jan回笼金额 MONEY ,
                                                   Feb回笼金额 MONEY ,
                                                   Mar回笼金额 MONEY ,
                                                   Apr回笼金额 MONEY ,
                                                   May回笼金额 MONEY ,
                                                   Jun回笼金额 MONEY ,
                                                   July回笼金额 MONEY ,
                                                   Aug回笼金额 MONEY ,
                                                   Sep回笼金额 MONEY ,
                                                   Oct回笼金额 MONEY ,
                                                   Nov回笼金额 MONEY ,
                                                   Dec回笼金额 MONEY ,
                                                   年初待收款 MONEY ,
												   待收款金额 MONEY,

                                                   本日回笼金额 MONEY ,
                                                   本周回笼金额 MONEY ,
                                                   去年回笼金额 MONEY ,
                                                    --回笼任务
                                                   本月回笼任务 MONEY ,
                                                   本年回笼任务 MONEY ,
                                                   去年回笼任务 MONEY);

        --插入产品楼栋的值 
        INSERT INTO ydkb_dthz_wq_deal_returninfo(组织架构父级ID, 组织架构ID, 组织架构名称, 组织架构编码, 组织架构类型 ,
                                                    --1-12月的回笼情况
                                                 Jan回笼金额, Feb回笼金额, Mar回笼金额, Apr回笼金额, May回笼金额, Jun回笼金额, July回笼金额, Aug回笼金额, Sep回笼金额, Oct回笼金额, Nov回笼金额, Dec回笼金额, 年初待收款,待收款金额)
        SELECT  gc.GCBldGUID 组织架构父级ID ,
                bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                6 组织架构类型 ,
                ld.Jan回笼金额 ,
                ld.Feb回笼金额 ,
                ld.Mar回笼金额 ,
                ld.Apr回笼金额 ,
                ld.May回笼金额 ,
                ld.Jun回笼金额 ,
                ld.July回笼金额 ,
                ld.Aug回笼金额 ,
                ld.Sep回笼金额 ,
                ld.Oct回笼金额 ,
                ld.Nov回笼金额 ,
                ld.Dec回笼金额 ,
                nc.年初待收款合计,
				dsk.待收款合计
        FROM    ydkb_BaseInfo bi
                LEFT JOIN #ld_hl ld ON ld.BldGUID = bi.组织架构ID
                LEFT JOIN #ld_ncdsk nc ON ld.BldGUID = nc.BldGUID
				LEFT JOIN #ld_dsk dsk ON ld.BldGUID = dsk.BldGUID 
                INNER JOIN mdm_SaleBuild sb ON bi.组织架构ID = sb.SaleBldGUID
                INNER JOIN mdm_GCBuild gc ON sb.GCBldGUID = gc.GCBldGUID
        WHERE   bi.组织架构类型 = 5;

        --插入工程楼栋的值
        INSERT INTO ydkb_dthz_wq_deal_returninfo(组织架构父级ID, 组织架构ID, 组织架构名称, 组织架构编码, 组织架构类型 ,
                                                    --1-12月的回笼情况
                                                 Jan回笼金额, Feb回笼金额, Mar回笼金额, Apr回笼金额, May回笼金额, Jun回笼金额, July回笼金额, Aug回笼金额, Sep回笼金额, Oct回笼金额, Nov回笼金额, Dec回笼金额, 年初待收款,待收款金额)
        SELECT  bi.组织架构父级ID ,
                gc.GCBldGUID 组织架构ID ,
                gc.BldName 组织架构名称 ,
                bi2.组织架构编码 ,
                5 组织架构类型 ,
                SUM(ISNULL(ld.Jan回笼金额, 0)) Jan回笼金额 ,
                SUM(ISNULL(ld.Feb回笼金额, 0)) Feb回笼金额 ,
                SUM(ISNULL(ld.Mar回笼金额, 0)) Mar回笼金额 ,
                SUM(ISNULL(ld.Apr回笼金额, 0)) Apr回笼金额 ,
                SUM(ISNULL(ld.May回笼金额, 0)) May回笼金额 ,
                SUM(ISNULL(ld.Jun回笼金额, 0)) Jun回笼金额 ,
                SUM(ISNULL(ld.July回笼金额, 0)) July回笼金额 ,
                SUM(ISNULL(ld.Aug回笼金额, 0)) Aug回笼金额 ,
                SUM(ISNULL(ld.Sep回笼金额, 0)) Sep回笼金额 ,
                SUM(ISNULL(ld.Oct回笼金额, 0)) Oct回笼金额 ,
                SUM(ISNULL(ld.Nov回笼金额, 0)) Nov回笼金额 ,
                SUM(ISNULL(ld.Dec回笼金额, 0)) Dec回笼金额 ,
                SUM(ISNULL(nc.年初待收款合计, 0)) 年初待收款,
				SUM(ISNULL(dsk.待收款合计,0)) AS 待收款金额
        FROM    ydkb_BaseInfo bi
                LEFT JOIN #ld_hl ld ON ld.BldGUID = bi.组织架构ID
                LEFT JOIN #ld_ncdsk nc ON ld.BldGUID = nc.BldGUID
				LEFT JOIN  #ld_dsk  dsk ON ld.BldGUID =dsk.BldGUID
                INNER JOIN mdm_SaleBuild sb ON bi.组织架构ID = sb.SaleBldGUID
                INNER JOIN mdm_GCBuild gc ON sb.GCBldGUID = gc.GCBldGUID
                INNER JOIN dbo.mdm_Project pj ON pj.ProjGUID = gc.ProjGUID
                INNER JOIN dbo.mdm_Product pr ON pr.ProductGUID = sb.ProductGUID
                INNER JOIN(SELECT   DISTINCT 组织架构名称, 组织架构父级ID, 组织架构编码 FROM  dbo.ydkb_BaseInfo) bi2 ON pr.ProductType = bi2.组织架构名称 AND   pj.ParentProjGUID = bi2.组织架构父级ID
        WHERE   bi.组织架构类型 = 5
        GROUP BY bi.组织架构父级ID ,
                 gc.GCBldGUID ,
                 gc.BldName ,
                 bi2.组织架构编码 ,
                 ld.ProjGUID;

        --插入业态的值       
        INSERT INTO ydkb_dthz_wq_deal_returninfo(组织架构父级ID, 组织架构ID, 组织架构名称, 组织架构编码, 组织架构类型, Jan回笼金额, Feb回笼金额, Mar回笼金额, Apr回笼金额, May回笼金额, Jun回笼金额, July回笼金额, Aug回笼金额, Sep回笼金额, Oct回笼金额, Nov回笼金额, Dec回笼金额 ,
                                                 年初待收款,待收款金额)
        SELECT  bi2.组织架构父级ID ,
                bi2.组织架构ID ,
                bi2.组织架构名称 ,
                bi2.组织架构编码 ,
                bi2.组织架构类型 ,
                SUM(ISNULL(ld.Jan回笼金额, 0) + ISNULL(yt.Jan回笼金额, 0)) AS Jan回笼金额 ,
                SUM(ISNULL(ld.Feb回笼金额, 0) + ISNULL(yt.Feb回笼金额, 0)) AS Feb回笼金额 ,
                SUM(ISNULL(ld.Mar回笼金额, 0) + ISNULL(yt.Mar回笼金额, 0)) AS Mar回笼金额 ,
                SUM(ISNULL(ld.Apr回笼金额, 0) + ISNULL(yt.Apr回笼金额, 0)) AS Apr回笼金额 ,
                SUM(ISNULL(ld.May回笼金额, 0) + ISNULL(yt.May回笼金额, 0)) AS May回笼金额 ,
                SUM(ISNULL(ld.Jun回笼金额, 0) + ISNULL(yt.Jun回笼金额, 0)) AS Jun回笼金额 ,
                SUM(ISNULL(ld.July回笼金额, 0) + ISNULL(yt.July回笼金额, 0)) AS July回笼金额 ,
                SUM(ISNULL(ld.Aug回笼金额, 0) + ISNULL(yt.Aug回笼金额, 0)) AS Aug回笼金额 ,
                SUM(ISNULL(ld.Sep回笼金额, 0) + ISNULL(yt.Sep回笼金额, 0)) AS Sep回笼金额 ,
                SUM(ISNULL(ld.Oct回笼金额, 0) + ISNULL(yt.Oct回笼金额, 0)) AS Oct回笼金额 ,
                SUM(ISNULL(ld.Nov回笼金额, 0) + ISNULL(yt.Nov回笼金额, 0)) AS Nov回笼金额 ,
                SUM(ISNULL(ld.Dec回笼金额, 0) + ISNULL(yt.Dec回笼金额, 0)) AS Dec回笼金额 ,
                SUM(ISNULL(nc.年初待收款, 0)) AS 年初待收款,
				SUM(ISNULL(dsk.待收款金额,0)) AS 待收款金额
        FROM    ydkb_BaseInfo bi2
                --系统自动取数部分
                LEFT JOIN(SELECT    ld.ProjGUID ,
                                    ld.ProductType ,
                                    SUM(Jan回笼金额) AS Jan回笼金额 ,
                                    SUM(Feb回笼金额) AS Feb回笼金额 ,
                                    SUM(Mar回笼金额) AS Mar回笼金额 ,
                                    SUM(Apr回笼金额) AS Apr回笼金额 ,
                                    SUM(May回笼金额) AS May回笼金额 ,
                                    SUM(Jun回笼金额) AS Jun回笼金额 ,
                                    SUM(July回笼金额) AS July回笼金额 ,
                                    SUM(Aug回笼金额) AS Aug回笼金额 ,
                                    SUM(Sep回笼金额) AS Sep回笼金额 ,
                                    SUM(Oct回笼金额) AS Oct回笼金额 ,
                                    SUM(Nov回笼金额) AS Nov回笼金额 ,
                                    SUM(Dec回笼金额) AS Dec回笼金额
                          FROM  #ld_hl ld
                          GROUP BY ld.ProjGUID ,
                                   ld.ProductType) ld ON ld.ProjGUID = bi2.组织架构父级ID AND ld.ProductType = bi2.组织架构名称
                --年初待收款
                LEFT JOIN(SELECT    nc.ProjGUID ,
                                    nc.ProductType ,
                                    SUM(ISNULL(nc.年初待收款合计, 0)) AS 年初待收款
                          FROM  #ld_ncdsk nc
                          GROUP BY nc.ProjGUID ,
                                   nc.ProductType) nc ON nc.ProjGUID = bi2.组织架构父级ID AND nc.ProductType = bi2.组织架构名称
                --待收款
                LEFT JOIN(
				          SELECT    dsk.ProjGUID ,
                                    dsk.ProductType ,
                                    SUM(ISNULL(dsk.待收款合计, 0)) AS 待收款金额
                          FROM  #ld_dsk dsk
                          GROUP BY dsk.ProjGUID ,
                                   dsk.ProductType ) dsk ON dsk.ProjGUID = bi2.组织架构父级ID AND dsk.ProductType = bi2.组织架构名称
                --手工铺排部分 
                LEFT JOIN #yt_hl yt ON yt.ProjGUID = bi2.组织架构父级ID AND  yt.ProductType = bi2.组织架构名称
        WHERE   bi2.组织架构类型 = 4 AND  bi2.平台公司GUID IN(SELECT  Value FROM  dbo.fn_Split2(@developmentguid, ',') )
        GROUP BY bi2.组织架构父级ID ,
                 bi2.组织架构ID ,
                 bi2.组织架构名称 ,
                 bi2.组织架构编码 ,
                 bi2.组织架构类型;

        --循环插入项目，城市公司，平台公司的值   
        DECLARE @baseinfo INT;

        SET @baseinfo = 4;

        WHILE(@baseinfo > 1)
            BEGIN
                INSERT INTO ydkb_dthz_wq_deal_returninfo(组织架构父级ID, 组织架构ID, 组织架构名称, 组织架构编码, 组织架构类型, Jan回笼金额, Feb回笼金额, Mar回笼金额, Apr回笼金额, May回笼金额, Jun回笼金额, July回笼金额, Aug回笼金额, Sep回笼金额, Oct回笼金额, Nov回笼金额 ,
                                                         Dec回笼金额 , 累计已回笼金额, 本年回笼金额, 本月回笼金额, 本年签约本年回笼, 年初待收款回笼, 年初待收款,待收款金额, 本日回笼金额, 本周回笼金额, 去年回笼金额 ,
                                                            --回笼任务
                                                         本月回笼任务, 本年回笼任务, 去年回笼任务)
                SELECT  bi.组织架构父级ID ,
                        bi.组织架构ID ,
                        bi.组织架构名称 ,
                        bi.组织架构编码 ,
                        bi.组织架构类型 ,
                        SUM(Jan回笼金额) AS Jan回笼金额 ,
                        SUM(Feb回笼金额) AS Feb回笼金额 ,
                        SUM(Mar回笼金额) AS Mar回笼金额 ,
                        SUM(Apr回笼金额) AS Apr回笼金额 ,
                        SUM(May回笼金额) AS May回笼金额 ,
                        SUM(Jun回笼金额) AS Jun回笼金额 ,
                        SUM(July回笼金额) AS July回笼金额 ,
                        SUM(Aug回笼金额) AS Aug回笼金额 ,
                        SUM(Sep回笼金额) AS Sep回笼金额 ,
                        SUM(Oct回笼金额) AS Oct回笼金额 ,
                        SUM(Nov回笼金额) AS Nov回笼金额 ,
                        SUM(Dec回笼金额) AS Dec回笼金额 ,
                        SUM(ISNULL(累计已回笼金额, 0)) AS 累计已回笼金额 ,
                        SUM(ISNULL(本年回笼金额, 0)) AS 本年回笼金额 ,
                        SUM(ISNULL(本月回笼金额, 0)) AS 本月回笼金额 ,
                        SUM(ISNULL(本年签约本年回笼, 0)) AS 本年签约本年回笼 ,
                        SUM(ISNULL(年初待收款回笼, 0)) AS 年初待收款回笼 ,
                        SUM(ISNULL(年初待收款, 0)) AS 年初待收款 ,
						SUM(ISNULL(待收款金额,0)) AS 待收款金额,
                        SUM(ISNULL(本日回笼金额, 0)) AS 本日回笼金额 ,
                        SUM(ISNULL(本周回笼金额, 0)) AS 本周回笼金额 ,
                        SUM(ISNULL(去年回笼金额, 0)) 去年回笼金额 ,
                        --回笼任务
                        SUM(ISNULL(本月回笼任务, 0)) 本月回笼任务 ,
                        SUM(ISNULL(本年回笼任务, 0)) 本年回笼任务 ,
                        SUM(ISNULL(去年回笼任务, 0)) 去年回笼任务
                FROM    ydkb_dthz_wq_deal_returninfo b
                        INNER JOIN ydkb_BaseInfo bi ON bi.组织架构ID = b.组织架构父级ID
                WHERE   b.组织架构类型 = @baseinfo
                GROUP BY bi.组织架构父级ID ,
                         bi.组织架构ID ,
                         bi.组织架构名称 ,
                         bi.组织架构编码 ,
                         bi.组织架构类型;

                IF(@baseinfo = 4) --更新项目层级的指标
                    BEGIN
                        --回笼
                        UPDATE  t
                        SET t.累计已回笼金额 = info.累计实际回笼全口径 ,
                            t.去年回笼金额 = info.去年实际回笼全口径 ,
                            t.本年回笼金额 = info.本年实际回笼全口径 ,
                            t.本月回笼金额 = info.本月实际回笼全口径 ,
                            t.本年签约本年回笼 = info.本年签约本年回笼 ,
                            t.本日回笼金额 = info.本日回笼金额 ,
                            t.本周回笼金额 = info.本周回笼金额
                        FROM    dbo.ydkb_dthz_wq_deal_returninfo t
                                INNER JOIN(SELECT   TopProjGUID AS projguid ,
                                                    累计实际回笼全口径 ,
                                                    去年实际回笼全口径 ,
                                                    本年实际回笼全口径 ,
                                                    CASE WHEN MONTH(GETDATE()) = 1 THEN 本年实际回笼全口径 ELSE 本年实际回笼全口径 - 上个月本年实际回笼全口径 END AS 本月实际回笼全口径 ,
                                                    t.本年签约本年回笼 ,
                                                    昨天本年实际回笼全口径 - 前天本年实际回笼全口径 本日回笼金额 ,
                                                    昨天本年实际回笼全口径 - 上周日本年实际回笼全口径 本周回笼金额
                                           FROM (SELECT TopProjGUID ,
                                                        SUM(
                                                        CASE WHEN DATEDIFF(dd, qxDate, GETDATE()) = 0 THEN
                                                                 ISNULL(hl.应退未退累计金额, 0) + ISNULL(hl.累计回笼金额认购, 0) + ISNULL(hl.累计回笼金额签约, 0) + ISNULL(hl.累计特殊业绩关联房间, 0) + ISNULL(hl.累计特殊业绩未关联房间, 0)
                                                             ELSE 0
                                                        END) AS 累计实际回笼全口径 ,
                                                        SUM(
                                                        CASE WHEN DATEDIFF(dd, qxDate, DATEADD(dd, -1, (@bnYear + '-01-01'))) = 0 THEN
                                                                 ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + ISNULL(hl.本年特殊业绩关联房间, 0)
                                                                 + ISNULL(hl.本年特殊业绩未关联房间, 0)
                                                             ELSE 0
                                                        END) AS 去年实际回笼全口径 ,
                                                        SUM(
                                                        CASE WHEN DATEDIFF(dd, qxDate, GETDATE()) = 0 THEN
                                                                 ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + ISNULL(hl.本年特殊业绩关联房间, 0)
                                                                 + ISNULL(hl.本年特殊业绩未关联房间, 0)
                                                             ELSE 0
                                                        END) AS 本年实际回笼全口径 ,
                                                        SUM(
                                                        CASE WHEN DATEDIFF(dd, qxDate, GETDATE() - 1) = 0 THEN
                                                                 ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + ISNULL(hl.本年特殊业绩关联房间, 0)
                                                                 + ISNULL(hl.本年特殊业绩未关联房间, 0)
                                                             ELSE 0
                                                        END) AS 昨天本年实际回笼全口径 ,
                                                        SUM(
                                                        CASE WHEN DATEDIFF(dd, qxDate, GETDATE() - 2) = 0 THEN
                                                                 ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + ISNULL(hl.本年特殊业绩关联房间, 0)
                                                                 + ISNULL(hl.本年特殊业绩未关联房间, 0)
                                                             ELSE 0
                                                        END) AS 前天本年实际回笼全口径 ,
                                                        SUM(
                                                        CASE WHEN DATEDIFF(dd, qxDate, @本周一 - 1) = 0 THEN
                                                                 ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + ISNULL(hl.本年特殊业绩关联房间, 0)
                                                                 + ISNULL(hl.本年特殊业绩未关联房间, 0)
                                                             ELSE 0
                                                        END) AS 上周日本年实际回笼全口径 ,
                                                        SUM(
                                                        CASE WHEN DATEDIFF(dd, qxDate, DATEADD(m, DATEDIFF(MONTH, -1, GETDATE()) - 1, -1)) = 0 THEN
                                                                 ISNULL(hl.应退未退本年金额, 0) + ISNULL(hl.本年回笼金额认购, 0) + ISNULL(hl.本年回笼金额签约, 0) + ISNULL(hl.关闭交易本年退款金额, 0) + ISNULL(hl.本年特殊业绩关联房间, 0)
                                                                 + ISNULL(hl.本年特殊业绩未关联房间, 0)
                                                             ELSE 0
                                                        END) AS 上个月本年实际回笼全口径 ,
                                                        SUM(CASE WHEN DATEDIFF(dd, qxDate, GETDATE()) = 0 THEN ISNULL(hl.本年签约本年回笼非按揭回笼, 0) + ISNULL(本年签约本年回笼按揭回笼, 0)ELSE 0 END) AS 本年签约本年回笼
                                                 FROM   s_gsfkylbhzb hl
                                                 WHERE  hl.buguid IN(SELECT Value FROM  dbo.fn_Split2(@buguid, ',') )
                                                 GROUP BY TopProjGUID) t ) info ON t.组织架构ID = info.projguid;

                        --年初待收款回笼
                        UPDATE  t
                        SET t.年初待收款回笼 = ISNULL(t.本年回笼金额, 0) - ISNULL(t.本年签约本年回笼, 0)
                        FROM    dbo.ydkb_dthz_wq_deal_returninfo t;

                        --年初待收款
                        UPDATE  t
                        SET t.年初待收款 = info.年初待收款合计
                        FROM    dbo.ydkb_dthz_wq_deal_returninfo t
                                INNER JOIN #proj_ncdsk info ON t.组织架构ID = info.projguid;
                        --待收款
                        UPDATE  t
                        SET t.待收款金额 = info.待收款合计
                        FROM    dbo.ydkb_dthz_wq_deal_returninfo t
                                INNER JOIN #proj_dsk info ON t.组织架构ID = info.projguid;

                        --回笼任务  
                        UPDATE  t
                        SET t.本年回笼任务 = isnull(info.本年回笼任务,0) ,
                            t.去年回笼任务 = isnull(info.去年回笼任务,0) ,
                            t.本月回笼任务 = isnull(byrw.本月回笼任务,0)
                        FROM    dbo.ydkb_dthz_wq_deal_returninfo t
                                INNER JOIN(SELECT   OrganizationGUID AS projguid ,
                                                    SUM(CASE WHEN BudgetDimensionValue = @bnYear - 1 THEN BudgetGetinAmount ELSE 0 END) / 10000.0 AS 去年回笼任务 ,
                                                    SUM(CASE WHEN BudgetDimensionValue = @bnYear THEN BudgetGetinAmount ELSE 0 END) / 10000.0 AS 本年回笼任务
                                           FROM [172.16.4.161].highdata_prod.dbo.data_wide_dws_s_SalesBudgetVerride
                                           WHERE   BudgetDimension = '年度' AND  BudgetDimensionValue BETWEEN @bnYear - 1 AND @bnYear
                                           GROUP BY OrganizationGUID) info ON t.组织架构ID = info.projguid
                                LEFT JOIN(SELECT    a.BusinessGUID ,
                                                    SUM([回笼任务（亿元）]) * 10000 AS 本月回笼任务
                                          FROM  dss.dbo.nmap_F_平台公司项目层级月度任务填报 a
                                                INNER JOIN dss.dbo.nmap_F_FillHistory f ON f.FillHistoryGUID = a.FillHistoryGUID
                                          WHERE DATEDIFF(mm, f.BeginDate, GETDATE()) = 0
                                          GROUP BY a.BusinessGUID) byrw ON byrw.BusinessGUID = t.组织架构ID;
                    END;

                SET @baseinfo = @baseinfo - 1;
            END;

        --------------------------------------begin 业态、楼栋回笼------------------------------ 
        SELECT  topprojguid ,
                BldGUID ,
                GCBldGUID ,
                ProductType ,
                累计实际回笼全口径 ,
                去年实际回笼全口径 ,
                本年实际回笼全口径 ,
                CASE WHEN MONTH(GETDATE()) = 1 THEN ISNULL(本年实际回笼全口径, 0)ELSE ISNULL(本年实际回笼全口径, 0) - ISNULL(t.上个月本年实际回笼全口径, 0)END AS 本月实际回笼全口径 ,
                t.本年签约本年回笼 ,
                ISNULL(本年实际回笼全口径, 0) - ISNULL(t.本年签约本年回笼, 0) 年初待收款回笼 ,
                ISNULL(t.昨天实际回笼全口径, 0) - ISNULL(t.前天实际回笼全口径, 0) 本日回笼金额 ,
                ISNULL(昨天实际回笼全口径, 0) - ISNULL(t.一周前实际回笼全口径, 0) 本周回笼金额
        INTO    #hl
        FROM(SELECT hl.topprojguid ,
                    r.BldGUID ,
                    sb.GCBldGUID ,
                    pr.ProductType ,
                    SUM(CASE WHEN DATEDIFF(dd, qxDate, GETDATE()) = 0 THEN ISNULL(累计回笼金额, 0)ELSE 0 END) / 10000.0 AS 累计实际回笼全口径 ,
                    SUM(CASE WHEN DATEDIFF(dd, qxDate, DATEADD(dd, -1, (@bnYear + '-01-01'))) = 0 THEN ISNULL(累计本年回笼金额, 0)ELSE 0 END) / 10000.0 AS 去年实际回笼全口径 ,
                    SUM(CASE WHEN DATEDIFF(dd, qxDate, GETDATE()) = 0 THEN ISNULL(累计本年回笼金额, 0)ELSE 0 END) / 10000.0 AS 本年实际回笼全口径 ,
                    SUM(CASE WHEN DATEDIFF(dd, qxDate, GETDATE() - 1) = 0 THEN ISNULL(累计本年回笼金额, 0)ELSE 0 END) / 10000.0 AS 昨天实际回笼全口径 ,
                    SUM(CASE WHEN DATEDIFF(dd, qxDate, GETDATE() - 2) = 0 THEN ISNULL(累计本年回笼金额, 0)ELSE 0 END) / 10000.0 AS 前天实际回笼全口径 ,
                    SUM(CASE WHEN DATEDIFF(dd, qxDate, @本周一 - 1) = 0 THEN ISNULL(累计本年回笼金额, 0)ELSE 0 END) / 10000.0 AS 一周前实际回笼全口径 ,
                    SUM(CASE WHEN DATEDIFF(dd, qxDate, DATEADD(m, DATEDIFF(MONTH, -1, GETDATE()) - 1, -1)) = 0 THEN ISNULL(累计本年回笼金额, 0)ELSE 0 END) / 10000.0 AS 上个月本年实际回笼全口径 ,
                    SUM(CASE WHEN DATEDIFF(dd, qxDate, GETDATE()) = 0 THEN ISNULL(hl.本年签约本年回笼回笼合计, 0)ELSE 0 END) / 10000.0 AS 本年签约本年回笼
             FROM   s_gsfkylbmxb hl
                    INNER JOIN p_room r ON hl.roomguid = r.RoomGUID
                    INNER JOIN dbo.mdm_SaleBuild sb ON sb.SaleBldGUID = r.BldGUID
                    INNER JOIN dbo.mdm_Product pr ON pr.ProductGUID = sb.ProductGUID
             WHERE  (DATEDIFF(dd, qxDate, GETDATE()) = 0 OR DATEDIFF(dd, qxDate, DATEDIFF(m, DATEDIFF(MONTH, -1, GETDATE()) - 1, -1)) = 0
                     OR DATEDIFF(dd, qxDate, DATEADD(dd, -1, (@bnYear + '-01-01'))) = 0) AND   hl.BUGUID IN(SELECT  Value FROM  dbo.fn_Split2(@buguid, ',') )
             GROUP BY sb.GCBldGUID ,
                      r.BldGUID ,
                      hl.topprojguid ,
                      pr.ProductType) t;

        --产品楼栋
        UPDATE  t
        SET t.累计已回笼金额 = info.累计实际回笼全口径 ,
            t.去年回笼金额 = info.去年实际回笼全口径 ,
            t.本年回笼金额 = info.本年实际回笼全口径 ,
            t.本月回笼金额 = info.本月实际回笼全口径 ,
            t.本年签约本年回笼 = info.本年签约本年回笼 ,
            t.年初待收款回笼 = info.年初待收款回笼 ,
            t.本日回笼金额 = info.本日回笼金额 ,
            t.本周回笼金额 = info.本周回笼金额
        FROM    dbo.ydkb_dthz_wq_deal_returninfo t
                INNER JOIN #hl info ON t.组织架构ID = info.BldGUID;

        --工程楼栋
        UPDATE  t
        SET t.累计已回笼金额 = info.累计实际回笼全口径 ,
            t.去年回笼金额 = info.去年实际回笼全口径 ,
            t.本年回笼金额 = info.本年实际回笼全口径 ,
            t.本月回笼金额 = info.本月实际回笼全口径 ,
            t.本年签约本年回笼 = info.本年签约本年回笼 ,
            t.年初待收款回笼 = info.年初待收款回笼 ,
            t.本日回笼金额 = info.本日回笼金额 ,
            t.本周回笼金额 = info.本周回笼金额
        FROM    dbo.ydkb_dthz_wq_deal_returninfo t
                INNER JOIN(SELECT   GCBldGUID ,
                                    SUM(累计实际回笼全口径) AS 累计实际回笼全口径 ,
                                    SUM(去年实际回笼全口径) AS 去年实际回笼全口径 ,
                                    SUM(本年实际回笼全口径) AS 本年实际回笼全口径 ,
                                    SUM(本月实际回笼全口径) AS 本月实际回笼全口径 ,
                                    SUM(本年签约本年回笼) AS 本年签约本年回笼 ,
                                    SUM(年初待收款回笼) AS 年初待收款回笼 ,
                                    SUM(本日回笼金额) AS 本日回笼金额 ,
                                    SUM(本周回笼金额) AS 本周回笼金额
                           FROM #hl
                           GROUP BY GCBldGUID) info ON t.组织架构ID = info.GCBldGUID;

        --业态
        UPDATE  t
        SET t.累计已回笼金额 = info.累计实际回笼全口径 ,
            t.去年回笼金额 = info.去年实际回笼全口径 ,
            t.本年回笼金额 = info.本年实际回笼全口径 ,
            t.本月回笼金额 = info.本月实际回笼全口径 ,
            t.本年签约本年回笼 = info.本年签约本年回笼 ,
            t.年初待收款回笼 = info.年初待收款回笼 ,
            t.本日回笼金额 = info.本日回笼金额 ,
            t.本周回笼金额 = info.本周回笼金额
        FROM    dbo.ydkb_dthz_wq_deal_returninfo t
                INNER JOIN(SELECT   topprojguid ,
                                    ProductType ,
                                    SUM(累计实际回笼全口径) AS 累计实际回笼全口径 ,
                                    SUM(去年实际回笼全口径) AS 去年实际回笼全口径 ,
                                    SUM(本年实际回笼全口径) AS 本年实际回笼全口径 ,
                                    SUM(本月实际回笼全口径) AS 本月实际回笼全口径 ,
                                    SUM(本年签约本年回笼) AS 本年签约本年回笼 ,
                                    SUM(年初待收款回笼) AS 年初待收款回笼 ,
                                    SUM(本日回笼金额) AS 本日回笼金额 ,
                                    SUM(本周回笼金额) AS 本周回笼金额
                           FROM #hl
                           GROUP BY topprojguid ,
                                    ProductType) info ON t.组织架构父级ID = info.topprojguid AND t.组织架构名称 = info.ProductType;

        --------------------------------------end 业态、楼栋回笼------------------------------    
        SELECT  * FROM  dbo.ydkb_dthz_wq_deal_returninfo;

        --删除临时表
        DROP TABLE #hl ,
                   #ld_hl ,
                   #yt_hl;
    END;
