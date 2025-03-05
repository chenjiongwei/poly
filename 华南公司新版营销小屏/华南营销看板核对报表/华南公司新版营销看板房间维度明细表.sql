--  华南公司房间维度明细表
-- 2025-02-25 华南公司新版营销看板核对报表
--DECLARE @var_Sdate DATETIME = '2024-01-01';
--DECLARE @var_Edate DATETIME = GETDATE();
--DECLARE @var_projguid VARCHAR(MAX) = '5d7326c7-e603-ed11-b39c-f40270d39969';

SELECT  *
INTO    #room
FROM    ep_room
WHERE   buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF';

SELECT  BuildingGUID ,
        FactFinishDate  -- 竣工备案表日期
INTO    #Bld
FROM    [172.16.4.161].[HighData_prod].dbo.data_wide_dws_mdm_Building b
WHERE   b.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF';

--数字营销房间
SELECT  DISTINCT sz.roomguid
INTO    #szyx
FROM    [172.16.4.161].[HighData_prod].dbo.data_wide_s_OnlineSaleRoomDtl sz
WHERE   sz.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF';

-- WHERE   BldGUID IN(SELECT   Value FROM  dbo.fn_Split2(@var_build, ',') );
SELECT  o.* ,
        CASE WHEN sz.roomguid IS NOT NULL THEN '是' ELSE '否' END AS IsSzyx
INTO    #order
FROM    s_Order o
        INNER JOIN #room r ON r.RoomGUID = o.RoomGUID
        LEFT JOIN #szyx sz ON sz.roomguid = o.RoomGUID
WHERE   o.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' AND   o.Status = '激活' AND (o.OrderType = '认购' OR  o.OrderType = '小订');    -- AND o.QSDate BETWEEN @var_Sdate AND @var_Edate;

SELECT  c.* ,
        CASE WHEN sz.roomguid IS NOT NULL THEN '是' ELSE '否' END AS IsSzyx
INTO    #contract
FROM    dbo.s_Contract c
        INNER JOIN #room r ON r.RoomGUID = c.RoomGUID
        LEFT JOIN #szyx sz ON sz.roomguid = c.RoomGUID
WHERE   c.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' AND   c.Status = '激活' AND c.QSDate BETWEEN @var_Sdate AND @var_Edate;

--标识特殊业绩房间    by mcc 20210913
SELECT  a.BldGUID ,
        r.RoomGUID ,
        b.RdDate
INTO    #ts
FROM    S_PerformanceAppraisalBuildings a
        LEFT JOIN dbo.p_room r ON a.BldGUID = r.BldGUID
        LEFT JOIN S_PerformanceAppraisal b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
WHERE   b.AuditStatus = '已审核'
UNION
SELECT  NULL ,
        RoomGUID ,
        b.RdDate
FROM    S_PerformanceAppraisalRoom a
        LEFT JOIN S_PerformanceAppraisal b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
WHERE   b.AuditStatus = '已审核';


--标记特殊楼层
SELECT  r.ProjGUID ,
        r.BldGUID ,
        CONVERT(VARCHAR,MAX(CONVERT(INT, REPLACE(r.Floor, '栋', ''))) ) AS 最高楼层 ,
        CONVERT(VARCHAR,MIN(CONVERT(INT,REPLACE(r.Floor, '栋', ''))) ) AS 最低楼层
INTO    #顶层
FROM    p_lddb lddb WITH(NOLOCK)
        INNER JOIN ep_room r WITH(NOLOCK)ON r.BldGUID = lddb.SaleBldGUID
WHERE(1 = 1) AND DATEDIFF(DD, lddb.QXDate, getdate()) = 0 AND lddb.ProductType IN ('住宅', '公寓', '写字楼')
     and DATALENGTH( REPLACE(r.Floor,'栋','') ) < = 3   --过滤字节数超过3的
     and r.Floor not like '%-%'
     and r.Floor not like '%S%'
     and r.Floor not like '%G%'
     and r.Floor not like '%H%'
     and r.Floor not like '%C%'
     and r.Floor not like '%B%'
     and r.Floor not like '%A%'
     and r.Floor not like '%F%'
     and r.Floor not like '%座%'
     and r.Floor not like '%幢%'
     AND r.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
	 --and lddb.ProjGUID in  ( SELECT Value FROM [dbo].[fn_Split2]( @var_proj ,',') )
GROUP BY r.ProjGUID ,
         r.BldGUID;
		 
SELECT  项目名称 ,
        明源项目代码 ,
        投管代码 ,
        分区 ,
        楼栋名称 ,
        单元 ,
        房号 ,
        房间GUID ,
        房间结构 ,
	   特殊楼层,
        产品类型 ,
        装修标准 ,
        预售建筑面积 ,
        预售套内面积 ,
        毛坯总价 ,
        装修总价 ,
        推货日期 ,
        销售状态 ,
        认购证号合同号 ,
        认购日期 ,
        订单创建日期 ,
        签约日期 ,
        合同创建日期 ,
        约定签约日期 ,
        是否逾期签约 ,
        成交总价 ,
        成交面积 ,
        成交均价 ,
        回收总价 ,
        折扣说明 ,
        --客户名称 ,
        --证件号码 ,
        --联系电话 ,
        --客户地址 ,
        --电子邮箱 ,
        付款方式 ,
        按揭银行 ,
        代理公司 ,
        销售员 ,
        非按揭金额 ,
        按揭金额 ,
        累计已收款 ,
        累计欠款金额 ,
        非按揭欠款金额 ,
        按揭放款日期 ,
        最后一笔实收日期 ,
        佣金申报人 ,
        佣金申报日期 ,
        是否已交楼 ,
        交楼日期 ,
        合同审核人 ,
        备案日期 ,
        合同备案号 ,
        销售经理 ,
        备注 ,
        交房日期 ,
        是否特殊业绩 ,
        认定日期 ,
        bldguid ,
        区域 ,
        房间信息 ,
        合同类型 ,
        临转正日期 ,
        RgxyPrintTimes 认购书打印次数 ,
        PotocolNO 认购书编号 ,
        客户来源 ,
        是否联动房源 ,
        备注内容 ,
        实际竣工备案日期 ,
        是否数字营销
FROM(SELECT p2.ProjCode 明源项目代码 ,
            lb.LbProjectValue 投管代码 ,
            P.ProjName 项目名称 ,
            CASE WHEN CHARINDEX('-', REPLACE(b.BldFullName, P.ProjName + '-', '')) > 0 THEN REPLACE(REPLACE(b.BldFullName, P.ProjName + '-', ''), '-' + b.BldName, '')ELSE '' END 分区 ,
            b.BldGUID AS bldguid ,
            b.BldName 楼栋名称 ,
            r.Unit 单元 ,
            r.Room 房号 ,
            r.roomguid 房间GUID ,
            r.RoomStru 房间结构 ,
            m.ParamValue 产品类型 ,
            r.ZxBz AS 装修标准 ,
            r.YsBldArea 预售建筑面积 ,
            r.YsTnArea 预售套内面积 ,
            CASE WHEN o.Total IS NULL OR o.Total <= 0 THEN r.Total ELSE o.Total END AS 毛坯总价 ,
            CASE WHEN o.ZxTotal IS NULL OR  o.ZxTotal <= 0 THEN r.ZxTotal ELSE o.ZxTotal END AS 装修总价 ,
            r.ThDate 推货日期 ,
            r.Status 销售状态 ,
            o.PotocolNO 认购证号合同号 ,
            o.QSDate 认购日期 ,
            o.CreatedOn 订单创建日期 ,
            NULL AS 签约日期 ,
            NULL AS 合同创建日期 ,
            o.EndDate 约定签约日期 ,
            CASE WHEN o.EndDate >= CONVERT(CHAR(10), GETDATE(), 120) THEN '未逾期' ELSE '已逾期' END 是否逾期签约 ,
            o.JyTotal 成交总价 ,
            r.BldArea AS 成交面积 ,
            CAST((o.JyTotal / r.YsBldArea) AS DECIMAL(20, 2)) 成交均价 ,
            CASE WHEN o.hszj IS NULL OR o.hszj <= 0 THEN r.HSZJ ELSE o.hszj END AS 回收总价 ,
            o.DiscntRemark 折扣说明 ,
            /* CASE WHEN c2.CstName IS NULL THEN c1.CstName
                 WHEN c3.CstName IS NULL THEN c1.CstName + ';' + c2.CstName
                 WHEN c4.CstName IS NULL THEN c1.CstName + ';' + c2.CstName + ';' + c3.CstName
                 ELSE c1.CstName + ';' + c2.CstName + ';' + c3.CstName + ';' + c4.CstName
            END 客户名称 ,
            CASE WHEN c2.CardID IS NULL THEN c1.CardID + ';'
                 WHEN c3.CardID IS NULL THEN c1.CardID + ';' + c2.CardID
                 WHEN c4.CardID IS NULL THEN c1.CardID + ';' + c2.CardID + ';' + c3.CardID
                 ELSE c1.CardID + ';' + c2.CardID + ';' + c3.CardID + ';' + c4.CardID
            END 证件号码 ,
            (CASE WHEN c2.MobileTel IS NULL THEN c1.MobileTel
                  WHEN c3.MobileTel IS NULL THEN c1.MobileTel + ';' + c2.MobileTel
                  WHEN c4.MobileTel IS NULL THEN c1.MobileTel + ';' + c2.MobileTel + ';' + c3.MobileTel
                  ELSE c1.MobileTel + ';' + c2.MobileTel + ';' + c3.MobileTel + ';' + c4.MobileTel
             END) + ';' + ISNULL((CASE WHEN c2.OfficeTel IS NULL THEN c1.OfficeTel
                                       WHEN c3.OfficeTel IS NULL THEN c1.OfficeTel + ';' + c2.OfficeTel
                                       WHEN c4.OfficeTel IS NULL THEN c1.OfficeTel + ';' + c2.OfficeTel + ';' + c3.OfficeTel
                                       ELSE c1.OfficeTel + ';' + c2.OfficeTel + ';' + c3.OfficeTel + ';' + c4.OfficeTel
                                  END) + ';', '') + ISNULL((CASE WHEN c2.HomeTel IS NULL THEN c1.HomeTel
                                                                 WHEN c3.HomeTel IS NULL THEN c1.HomeTel + ';' + c2.HomeTel
                                                                 WHEN c4.HomeTel IS NULL THEN c1.HomeTel + ';' + c2.HomeTel + ';' + c3.HomeTel
                                                                 ELSE c1.HomeTel + ';' + c2.HomeTel + ';' + c3.HomeTel + ';' + c4.HomeTel
                                                            END), '') 联系电话 ,
            CASE WHEN c2.Address IS NULL THEN c1.Address
                 WHEN c3.Address IS NULL THEN c1.Address + ';' + c2.Address
                 WHEN c4.Address IS NULL THEN c1.Address + ';' + c2.Address + ';' + c3.Address
                 ELSE c1.Address + ';' + c2.Address + ';' + c3.Address + ';' + c4.Address
            END 客户地址 ,
            CASE WHEN c2.Email IS NULL THEN c1.Email
                 WHEN c3.Email IS NULL THEN c1.Email + ';' + c2.Email
                 WHEN c4.Email IS NULL THEN c1.Email + ';' + c2.Email + ';' + c3.Email
                 ELSE c1.Email + ';' + c2.Email + ';' + c3.Email + ';' + c4.Email
            END 电子邮箱 ,*/
            o.PayformName 付款方式 ,
            CASE WHEN o.AjBank = '' OR  o.GjjBank = '' OR   (o.AjBank = '' AND  o.GjjBank = '') THEN o.AjBank + o.GjjBank ELSE o.AjBank + '+' + o.GjjBank END 按揭银行 ,
            o.Ywy 代理公司 ,
            o.Zygw 销售员 ,
            f.fkamount1 非按揭金额 ,
            f.fkamount2 按揭金额 ,
            g.skamount 累计已收款 ,
            f.qkamount1 累计欠款金额 ,
            f.qkamount2 非按揭欠款金额 ,
            NULL AS 按揭放款日期 ,
            g.skdate 最后一笔实收日期 ,
            '' 佣金申报人 ,
            NULL AS 佣金申报日期 ,
            '否' 是否已交楼 ,
            NULL AS 交楼日期 ,
            '' AS '合同审核人' ,
            '' AS '备案日期' ,
            '' AS '合同备案号' ,
            o.Xsjl + ';' + CASE WHEN ISNULL(o.Xsjl2, '') = '' THEN '' ELSE o.Xsjl2 + ';' END + CASE WHEN ISNULL(o.Xsjl3, '') = '' THEN '' ELSE o.Xsjl3 + ';' END 销售经理 ,
            o.ReMark AS '备注' ,
            o.JfDate AS '交房日期' ,
            CASE WHEN tsyj.RoomGUID IS NOT NULL THEN '是' ELSE '否' END AS '是否特殊业绩' ,
            tsyj.RdDate '认定日期' ,
            P.XMSSCSGS AS '区域' ,
            r.RoomInfo 房间信息 ,
            '定单' 合同类型 ,
            NULL AS 临转正日期 ,
            o.RgxyPrintTimes ,
            o.PotocolNO ,
            o.CstSource AS 客户来源 ,
            CASE WHEN ISNULL(o.IsLdf, 0) = 0 THEN '否' ELSE '是' END AS 是否联动房源 ,
            o.Comments AS 备注内容 ,
            bld.FactFinishDate AS 实际竣工备案日期 ,
            o.IsSzyx AS 是否数字营销,
			CASE WHEN dc.最高楼层 = REPLACE(r.Floor, '栋', '') and dc.bldGUID is not null THEN '顶层' 
                 WHEN RIGHT(REPLACE(r.Floor, '栋', ''), 1) = '4' and dc.bldGUID is not null THEN '尾数为4层'
                 WHEN REPLACE(r.Floor, '栋', '') = '18' and dc.bldGUID is not null THEN '18层'
                 WHEN REPLACE(r.Floor, '栋', '') IN ('1', '2', '3') and dc.bldGUID is not null THEN '1至3层' ELSE '' END AS 特殊楼层
     FROM   #order o
            INNER JOIN #room r ON o.RoomGUID = r.RoomGUID
            LEFT JOIN #Bld bld ON r.BldGUID = bld.BuildingGUID
            LEFT JOIN p_Project P ON r.ProjGUID = P.ProjGUID
            LEFT JOIN dbo.p_Project P1 ON P1.ProjCode = P.ParentCode AND P1.ApplySys LIKE '%0101%'
            LEFT JOIN mdm_Project p2 ON ISNULL(p2.ImportSaleProjGUID, p2.ProjGUID) = P1.ProjGUID
            LEFT JOIN dbo.mdm_LbProject lb ON lb.projGUID = p2.ProjGUID AND lb.LbProject = 'tgid'
            LEFT JOIN p_Building b ON r.BldGUID = b.BldGUID
            LEFT JOIN myBizParamOption m ON r.BProductTypeCode = m.ParamCode AND ScopeGUID = '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' AND ParamName = 'tz_ProductType'
            LEFT JOIN s_trade2cst t2c1 ON o.TradeGUID = t2c1.TradeGUID AND  t2c1.CstNum = 1
            --LEFT JOIN p_Customer c1 ON t2c1.CstGUID = c1.CstGUID
            --LEFT JOIN s_trade2cst t2c2 ON o.TradeGUID = t2c2.TradeGUID AND  t2c2.CstNum = 2
            --LEFT JOIN p_Customer c2 ON t2c2.CstGUID = c2.CstGUID
            --LEFT JOIN s_trade2cst t2c3 ON o.TradeGUID = t2c3.TradeGUID AND  t2c3.CstNum = 3
            --LEFT JOIN p_Customer c3 ON t2c3.CstGUID = c3.CstGUID
            --LEFT JOIN s_trade2cst t2c4 ON o.TradeGUID = t2c4.TradeGUID AND  t2c4.CstNum = 4
            --LEFT JOIN p_Customer c4 ON t2c4.CstGUID = c4.CstGUID
            LEFT JOIN(SELECT    f.TradeGUID ,
                                SUM(CASE WHEN ItemType = '非贷款类房款' THEN Amount ELSE 0 END) fkamount1 ,
                                SUM(CASE WHEN ItemType = '贷款类房款' THEN Amount ELSE 0 END) fkamount2 ,
                                SUM(CASE WHEN ItemType LIKE '%贷款类房款' THEN RmbYe ELSE 0 END) qkamount1 ,
                                SUM(CASE WHEN ItemType = '非贷款类房款' THEN RmbYe ELSE 0 END) qkamount2
                      FROM  s_Fee f
                            INNER JOIN #order o ON f.TradeGUID = o.TradeGUID
                      GROUP BY f.TradeGUID) f ON o.TradeGUID = f.TradeGUID
            LEFT JOIN(SELECT    g.SaleGUID ,
                                SUM(CASE WHEN ItemType LIKE '%贷款类房款' THEN Amount ELSE 0 END) skamount ,
                                MAX(CASE WHEN ItemType = '贷款类房款' THEN g.GetDate ELSE NULL END) fkdate ,
                                MAX(CASE WHEN ItemType LIKE '%贷款类房款' THEN g.GetDate ELSE NULL END) skdate
                      FROM  s_Getin g
                            INNER JOIN #order o ON o.TradeGUID = g.SaleGUID
                      WHERE ISNULL(g.Status, '') <> '作废'
                      GROUP BY g.SaleGUID) g ON o.TradeGUID = g.SaleGUID
            LEFT JOIN #ts tsyj ON o.roomguid = tsyj.roomguid
			LEFT JOIN #顶层 dc ON dc.projGUID = r.projGUID AND   dc.bldGUID = r.bldGUID
     WHERE  1 = 1 AND   P1.projguid IN (@var_projguid)
     UNION ALL
     SELECT p2.ProjCode 明源项目代码 ,
            lb.LbProjectValue 投管代码 ,
            P.ProjName 项目名称 ,
            CASE WHEN CHARINDEX('-', REPLACE(b.BldFullName, P.ProjName + '-', '')) > 0 THEN REPLACE(REPLACE(b.BldFullName, P.ProjName + '-', ''), '-' + b.BldName, '')ELSE '' END 分区 ,
            b.BldGUID AS BldGUID ,
            b.BldName 楼栋名称 ,
            r.Unit 单元 ,
            r.Room 房号 ,
            r.roomguid 房间GUID ,
            r.RoomStru 房间结构 ,
            m.ParamValue 产品类型 ,
            r.ZxBz AS 装修标准 ,
            r.YsBldArea 预售建筑面积 ,
            r.YsTnArea 预售套内面积 ,
            CASE WHEN c.Total IS NULL OR c.Total <= 0 THEN r.Total ELSE c.Total END AS 毛坯总价 ,
            CASE WHEN c.ZxTotal IS NULL OR  c.ZxTotal <= 0 THEN r.ZxTotal ELSE c.ZxTotal END AS 装修总价 ,
            r.ThDate 推货日期 ,
            r.Status 销售状态 ,
            c.ContractNO 认购证号合同号 ,
            o.QSDate 认购日期 ,
            o.CreatedOn 订单创建日期 ,
            c.QSDate 签约日期 ,
            c.CreatedOn 合同创建日期 ,
            o.EndDate 约定签约日期 ,
            CASE WHEN o.EndDate >= CONVERT(CHAR(10), c.QSDate, 120) THEN '未逾期' ELSE '已逾期' END 是否逾期签约 ,
            c.JyTotal 成交总价 ,
            r.BldArea AS 成交面积 ,
            CAST((c.JyTotal / r.YsBldArea) AS DECIMAL(20, 2)) 成交均价 ,
            CASE WHEN c.hszj IS NULL OR c.hszj <= 0 THEN r.HSZJ ELSE c.hszj END AS 回收总价 ,
            c.DiscntRemark 折扣说明 ,
            /* CASE WHEN c2.CstName IS NULL THEN c1.CstName
                 WHEN c3.CstName IS NULL THEN c1.CstName + ';' + c2.CstName
                 WHEN c4.CstName IS NULL THEN c1.CstName + ';' + c2.CstName + ';' + c3.CstName
                 ELSE c1.CstName + ';' + c2.CstName + ';' + c3.CstName + ';' + c4.CstName
            END 客户名称 ,
            CASE WHEN c2.CardID IS NULL THEN c1.CardID + ';'
                 WHEN c3.CardID IS NULL THEN c1.CardID + ';' + c2.CardID
                 WHEN c4.CardID IS NULL THEN c1.CardID + ';' + c2.CardID + ';' + c3.CardID
                 ELSE c1.CardID + ';' + c2.CardID + ';' + c3.CardID + ';' + c4.CardID
            END 证件号码 ,
            (CASE WHEN c2.MobileTel IS NULL THEN c1.MobileTel
                  WHEN c3.MobileTel IS NULL THEN c1.MobileTel + ';' + c2.MobileTel
                  WHEN c4.MobileTel IS NULL THEN c1.MobileTel + ';' + c2.MobileTel + ';' + c3.MobileTel
                  ELSE c1.MobileTel + ';' + c2.MobileTel + ';' + c3.MobileTel + ';' + c4.MobileTel
             END) + ';' + ISNULL((CASE WHEN c2.OfficeTel IS NULL THEN c1.OfficeTel
                                       WHEN c3.OfficeTel IS NULL THEN c1.OfficeTel + ';' + c2.OfficeTel
                                       WHEN c4.OfficeTel IS NULL THEN c1.OfficeTel + ';' + c2.OfficeTel + ';' + c3.OfficeTel
                                       ELSE c1.OfficeTel + ';' + c2.OfficeTel + ';' + c3.OfficeTel + ';' + c4.OfficeTel
                                  END) + ';', '') + ISNULL((CASE WHEN c2.HomeTel IS NULL THEN c1.HomeTel
                                                                 WHEN c3.HomeTel IS NULL THEN c1.HomeTel + ';' + c2.HomeTel
                                                                 WHEN c4.HomeTel IS NULL THEN c1.HomeTel + ';' + c2.HomeTel + ';' + c3.HomeTel
                                                                 ELSE c1.HomeTel + ';' + c2.HomeTel + ';' + c3.HomeTel + ';' + c4.HomeTel
                                                            END), '') 联系电话 ,
            CASE WHEN c2.Address IS NULL THEN c1.Address
                 WHEN c3.Address IS NULL THEN c1.Address + ';' + c2.Address
                 WHEN c4.Address IS NULL THEN c1.Address + ';' + c2.Address + ';' + c3.Address
                 ELSE c1.Address + ';' + c2.Address + ';' + c3.Address + ';' + c4.Address
            END 客户地址 ,
            CASE WHEN c2.Email IS NULL THEN c1.Email
                 WHEN c3.Email IS NULL THEN c1.Email + ';' + c2.Email
                 WHEN c4.Email IS NULL THEN c1.Email + ';' + c2.Email + ';' + c3.Email
                 ELSE c1.Email + ';' + c2.Email + ';' + c3.Email + ';' + c4.Email
            END 电子邮箱 ,*/
            c.PayformName 付款方式 ,
            CASE WHEN c.AjBank = '' OR  c.GjjBank = '' OR   (c.AjBank = '' AND  c.GjjBank = '') THEN c.AjBank + c.GjjBank ELSE c.AjBank + '+' + c.GjjBank END 按揭银行 ,
            c.Ywy 代理公司 ,
            c.Zygw 销售员 ,
            f.fkamount1 非按揭金额 ,
            f.fkamount2 按揭金额 ,
            g.skamount 累计已收款 ,
            f.qkamount1 累计欠款金额 ,
            f.qkamount2 非按揭欠款金额 ,
            g.fkdate 按揭放款日期 ,
            g.skdate 最后一笔实收日期 ,
            c.CommissionSbBy 佣金申报人 ,
            c.CommissionSbDate 佣金申报日期 ,
            CASE WHEN s1.ServiceProc = '已交接钥匙' THEN '是' ELSE '否' END 是否已交楼 ,
            CASE WHEN s1.ServiceProc = '已交接钥匙' THEN s.CompleteDate ELSE NULL END 交楼日期 ,
            c.AuditBy AS '合同审核人' ,
            c.BaDate AS '备案日期' ,
            c.BaNo AS '合同备案号' ,
            c.Xsjl + ';' + CASE WHEN ISNULL(c.Xsjl2, '') = '' THEN '' ELSE c.Xsjl2 + ';' END + CASE WHEN ISNULL(c.Xsjl3, '') = '' THEN '' ELSE c.Xsjl3 + ';' END 销售经理 ,
            c.HtBeiZhu AS '备注' ,
            c.JFDate AS '交房日期' ,
            CASE WHEN tsyj.RoomGUID IS NOT NULL THEN '是' ELSE '否' END AS '是否特殊业绩' ,
            tsyj.RdDate '认定日期' ,
            P.XMSSCSGS AS '区域' ,
            r.RoomInfo 房间信息 ,
            c.HtType 合同类型 ,
            ISNULL(c.LZZDate, NULL) 临转正日期 ,
            o.RgxyPrintTimes ,
            o.PotocolNO ,
            c.CstSource AS 客户来源 ,
            CASE WHEN ISNULL(c.IsLdf, 0) = 0 THEN '否' ELSE '是' END AS 是否联动房源 ,
            o.Comments AS 备注内容 ,
            bld.FactFinishDate AS 实际竣工备案日期 ,
            c.IsSzyx AS 是否数字营销,
			CASE WHEN dc.最高楼层 = REPLACE(r.Floor, '栋', '') and dc.bldGUID is not null THEN '顶层' 
                 WHEN RIGHT(REPLACE(r.Floor, '栋', ''), 1) = '4' and dc.bldGUID is not null THEN '尾数为4层'
                 WHEN REPLACE(r.Floor, '栋', '') = '18' and dc.bldGUID is not null THEN '18层'
                 WHEN REPLACE(r.Floor, '栋', '') IN ('1', '2', '3') and dc.bldGUID is not null THEN '1至3层' ELSE '' END AS 特殊楼层
     FROM   #contract c
            INNER JOIN #room r ON c.RoomGUID = r.RoomGUID
            LEFT JOIN #Bld bld ON r.BldGUID = bld.BuildingGUID
            INNER JOIN p_Project P ON r.ProjGUID = P.ProjGUID
            LEFT JOIN dbo.p_Project P1 ON P1.ProjCode = P.ParentCode AND P1.ApplySys LIKE '%0101%'
            LEFT JOIN mdm_Project p2 ON ISNULL(p2.ImportSaleProjGUID, p2.ProjGUID) = P1.ProjGUID
            LEFT JOIN dbo.mdm_LbProject lb ON lb.projGUID = p2.ProjGUID AND lb.LbProject = 'tgid'
            INNER JOIN p_Building b ON r.BldGUID = b.BldGUID
            LEFT JOIN myBizParamOption m ON r.BProductTypeCode = m.ParamCode AND ScopeGUID = '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' AND ParamName = 'tz_ProductType'
            LEFT JOIN s_trade2cst t2c1 ON c.TradeGUID = t2c1.TradeGUID AND  t2c1.CstNum = 1
            --LEFT JOIN p_Customer c1 ON t2c1.CstGUID = c1.CstGUID
            --LEFT JOIN s_trade2cst t2c2 ON c.TradeGUID = t2c2.TradeGUID AND  t2c2.CstNum = 2
            --LEFT JOIN p_Customer c2 ON t2c2.CstGUID = c2.CstGUID
            --LEFT JOIN s_trade2cst t2c3 ON c.TradeGUID = t2c3.TradeGUID AND  t2c3.CstNum = 3
            --LEFT JOIN p_Customer c3 ON t2c3.CstGUID = c3.CstGUID
            --LEFT JOIN s_trade2cst t2c4 ON c.TradeGUID = t2c4.TradeGUID AND  t2c4.CstNum = 4
            --LEFT JOIN p_Customer c4 ON t2c4.CstGUID = c4.CstGUID
            LEFT JOIN s_Order o ON c.TradeGUID = o.TradeGUID AND ISNULL(o.CloseReason, '') = '转签约'
            LEFT JOIN(SELECT    f.TradeGUID ,
                                SUM(CASE WHEN ItemType = '非贷款类房款' THEN Amount ELSE 0 END) fkamount1 ,
                                SUM(CASE WHEN ItemType = '贷款类房款' THEN Amount ELSE 0 END) fkamount2 ,
                                SUM(CASE WHEN ItemType LIKE '%贷款类房款' THEN RmbYe ELSE 0 END) qkamount1 ,
                                SUM(CASE WHEN ItemType = '非贷款类房款' THEN RmbYe ELSE 0 END) qkamount2
                      FROM  s_Fee f
                            INNER JOIN #contract c ON f.TradeGUID = c.TradeGUID
                      GROUP BY f.TradeGUID) f ON c.TradeGUID = f.TradeGUID
            LEFT JOIN(SELECT    g.SaleGUID ,
                                SUM(CASE WHEN ItemType LIKE '%贷款类房款' THEN Amount ELSE 0 END) skamount ,
                                MAX(CASE WHEN ItemType = '贷款类房款' THEN g.GetDate ELSE NULL END) fkdate ,
                                MAX(CASE WHEN ItemType LIKE '%贷款类房款' THEN g.GetDate ELSE NULL END) skdate
                      FROM  s_Getin g
                            INNER JOIN #contract c ON g.SaleGUID = c.TradeGUID
                      WHERE ISNULL(g.Status, '') <> '作废'
                      GROUP BY g.SaleGUID) g ON c.TradeGUID = g.SaleGUID
            LEFT JOIN s_SaleService s ON c.ContractGUID = s.ContractGUID AND s.ServiceItem = '入伙服务'
            LEFT JOIN s_SaleServiceProc s1 ON s.SaleServiceGUID = s1.SaleServiceGUID AND s1.ServiceProc = '已交接钥匙'
            LEFT JOIN #ts tsyj ON c.roomguid = tsyj.roomguid
			LEFT JOIN #顶层 dc ON dc.projGUID = r.projGUID AND   dc.bldGUID = r.bldGUID
     WHERE  1 = 1 AND   P1.projguid IN (@var_projguid)
     UNION ALL
     SELECT p2.ProjCode 明源项目代码 ,
            lb.LbProjectValue 投管代码 ,
            P.ProjName 项目名称 ,
            CASE WHEN CHARINDEX('-', REPLACE(b.BldFullName, P.ProjName + '-', '')) > 0 THEN REPLACE(REPLACE(b.BldFullName, P.ProjName + '-', ''), '-' + b.BldName, '')ELSE '' END 分区 ,
            b.BldGUID AS bldguid ,
            b.BldName 楼栋名称 ,
            r.Unit 单元 ,
            r.Room 房号 ,
            r.roomguid 房间GUID ,
            r.RoomStru 房间结构 ,
            m.ParamValue 产品类型 ,
            r.ZxBz AS 装修标准 ,
            r.YsBldArea 预售建筑面积 ,
            r.YsTnArea 预售套内面积 ,
            CASE WHEN c.Total IS NULL OR c.Total <= 0 THEN r.Total ELSE c.Total END AS 毛坯总价 ,
            CASE WHEN c.ZxTotal IS NULL OR  c.ZxTotal <= 0 THEN r.ZxTotal ELSE c.ZxTotal END AS 装修总价 ,
            r.ThDate 推货日期 ,
            r.Status 销售状态 ,
            c.ContractNO 认购证号合同号 ,
            o.QSDate 认购日期 ,
            o.CreatedOn 订单创建日期 ,
            c.QSDate 签约日期 ,
            c.CreatedOn 合同创建日期 ,
            o.EndDate 约定签约日期 ,
            CASE WHEN o.EndDate >= CONVERT(CHAR(10), c.QSDate, 120) THEN '未逾期' ELSE '已逾期' END 是否逾期签约 ,
            c.JyTotal 成交总价 ,
            r.BldArea AS 成交面积 ,
            CAST((c.JyTotal / r.YsBldArea) AS DECIMAL(20, 2)) 成交均价 ,
            CASE WHEN c.hszj IS NULL OR c.hszj <= 0 THEN r.HSZJ ELSE c.hszj END AS 回收总价 ,
            c.DiscntRemark 折扣说明 ,
            /* CASE WHEN c2.CstName IS NULL THEN c1.CstName
                 WHEN c3.CstName IS NULL THEN c1.CstName + ';' + c2.CstName
                 WHEN c4.CstName IS NULL THEN c1.CstName + ';' + c2.CstName + ';' + c3.CstName
                 ELSE c1.CstName + ';' + c2.CstName + ';' + c3.CstName + ';' + c4.CstName
            END 客户名称 ,
            CASE WHEN c2.CardID IS NULL THEN c1.CardID + ';'
                 WHEN c3.CardID IS NULL THEN c1.CardID + ';' + c2.CardID
                 WHEN c4.CardID IS NULL THEN c1.CardID + ';' + c2.CardID + ';' + c3.CardID
                 ELSE c1.CardID + ';' + c2.CardID + ';' + c3.CardID + ';' + c4.CardID
            END 证件号码 ,
            (CASE WHEN c2.MobileTel IS NULL THEN c1.MobileTel
                  WHEN c3.MobileTel IS NULL THEN c1.MobileTel + ';' + c2.MobileTel
                  WHEN c4.MobileTel IS NULL THEN c1.MobileTel + ';' + c2.MobileTel + ';' + c3.MobileTel
                  ELSE c1.MobileTel + ';' + c2.MobileTel + ';' + c3.MobileTel + ';' + c4.MobileTel
             END) + ';' + ISNULL((CASE WHEN c2.OfficeTel IS NULL THEN c1.OfficeTel
                                       WHEN c3.OfficeTel IS NULL THEN c1.OfficeTel + ';' + c2.OfficeTel
                                       WHEN c4.OfficeTel IS NULL THEN c1.OfficeTel + ';' + c2.OfficeTel + ';' + c3.OfficeTel
                                       ELSE c1.OfficeTel + ';' + c2.OfficeTel + ';' + c3.OfficeTel + ';' + c4.OfficeTel
                                  END) + ';', '') + ISNULL((CASE WHEN c2.HomeTel IS NULL THEN c1.HomeTel
                                                                 WHEN c3.HomeTel IS NULL THEN c1.HomeTel + ';' + c2.HomeTel
                                                                 WHEN c4.HomeTel IS NULL THEN c1.HomeTel + ';' + c2.HomeTel + ';' + c3.HomeTel
                                                                 ELSE c1.HomeTel + ';' + c2.HomeTel + ';' + c3.HomeTel + ';' + c4.HomeTel
                                                            END), '') 联系电话 ,
            CASE WHEN c2.Address IS NULL THEN c1.Address
                 WHEN c3.Address IS NULL THEN c1.Address + ';' + c2.Address
                 WHEN c4.Address IS NULL THEN c1.Address + ';' + c2.Address + ';' + c3.Address
                 ELSE c1.Address + ';' + c2.Address + ';' + c3.Address + ';' + c4.Address
            END 客户地址 ,
            CASE WHEN c2.Email IS NULL THEN c1.Email
                 WHEN c3.Email IS NULL THEN c1.Email + ';' + c2.Email
                 WHEN c4.Email IS NULL THEN c1.Email + ';' + c2.Email + ';' + c3.Email
                 ELSE c1.Email + ';' + c2.Email + ';' + c3.Email + ';' + c4.Email
            END 电子邮箱 ,*/
            c.PayformName 付款方式 ,
            CASE WHEN c.AjBank = '' OR  c.GjjBank = '' OR   (c.AjBank = '' AND  c.GjjBank = '') THEN c.AjBank + c.GjjBank ELSE c.AjBank + '+' + c.GjjBank END 按揭银行 ,
            c.Ywy 代理公司 ,
            c.Zygw 销售员 ,
            f.fkamount1 非按揭金额 ,
            f.fkamount2 按揭金额 ,
            g.skamount 累计已收款 ,
            f.qkamount1 累计欠款金额 ,
            f.qkamount2 非按揭欠款金额 ,
            g.fkdate 按揭放款日期 ,
            g.skdate 最后一笔实收日期 ,
            c.CommissionSbBy 佣金申报人 ,
            c.CommissionSbDate 佣金申报日期 ,
            CASE WHEN s1.ServiceProc = '已交接钥匙' THEN '是' ELSE '否' END 是否已交楼 ,
            CASE WHEN s1.ServiceProc = '已交接钥匙' THEN s.CompleteDate ELSE NULL END 交楼日期 ,
            c.AuditBy AS '合同审核人' ,
            c.BaDate AS '备案日期' ,
            c.BaNo AS '合同备案号' ,
            c.Xsjl + ';' + CASE WHEN ISNULL(c.Xsjl2, '') = '' THEN '' ELSE c.Xsjl2 + ';' END + CASE WHEN ISNULL(c.Xsjl3, '') = '' THEN '' ELSE c.Xsjl3 + ';' END 销售经理 ,
            c.HtBeiZhu AS '备注' ,
            c.JFDate AS '交房日期' ,
            CASE WHEN tsyj.RoomGUID IS NOT NULL THEN '是' ELSE '否' END AS '是否特殊业绩' ,
            tsyj.RdDate '认定日期' ,
            P.XMSSCSGS AS '区域' ,
            r.RoomInfo 房间信息 ,
            c.HtType 合同类型 ,
            ISNULL(c.LZZDate, NULL) 临转正日期 ,
            o.RgxyPrintTimes ,
            o.PotocolNO ,
            c.CstSource AS 客户来源 ,
            CASE WHEN ISNULL(c.IsLdf, 0) = 0 THEN '否' ELSE '是' END AS 是否联动房源 ,
            o.Comments AS 备注内容 ,
            bld.FactFinishDate AS 实际竣工备案日期 ,
            c.IsSzyx AS 是否数字营销,
			CASE WHEN dc.最高楼层 = REPLACE(r.Floor, '栋', '') and dc.bldGUID is not null THEN '顶层' 
                 WHEN RIGHT(REPLACE(r.Floor, '栋', ''), 1) = '4' and dc.bldGUID is not null THEN '尾数为4层'
                 WHEN REPLACE(r.Floor, '栋', '') = '18' and dc.bldGUID is not null THEN '18层'
                 WHEN REPLACE(r.Floor, '栋', '') IN ('1', '2', '3') and dc.bldGUID is not null THEN '1至3层' ELSE '' END AS 特殊楼层
     FROM   #contract c
            INNER JOIN #room r ON c.RoomGUID = r.RoomGUID
            LEFT JOIN #Bld bld ON r.BldGUID = bld.BuildingGUID
            INNER JOIN p_Project P ON r.ProjGUID = P.ProjGUID
            LEFT JOIN dbo.p_Project P1 ON P1.ProjCode = P.ParentCode AND P1.ApplySys LIKE '%0101%'
            LEFT JOIN mdm_Project p2 ON ISNULL(p2.ImportSaleProjGUID, p2.ProjGUID) = P1.ProjGUID
            LEFT JOIN dbo.mdm_LbProject lb ON lb.projGUID = p2.ProjGUID AND lb.LbProject = 'tgid'
            INNER JOIN p_Building b ON r.BldGUID = b.BldGUID
            LEFT JOIN myBizParamOption m ON r.BProductTypeCode = m.ParamCode AND ScopeGUID = '11B11DB4-E907-4F1F-8835-B9DAAB6E1F23' AND ParamName = 'tz_ProductType'
            LEFT JOIN s_trade2cst t2c1 ON c.TradeGUID = t2c1.TradeGUID AND  t2c1.CstNum = 1
            --LEFT JOIN p_Customer c1 ON t2c1.CstGUID = c1.CstGUID
            --LEFT JOIN s_trade2cst t2c2 ON c.TradeGUID = t2c2.TradeGUID AND  t2c2.CstNum = 2
            --LEFT JOIN p_Customer c2 ON t2c2.CstGUID = c2.CstGUID
            --LEFT JOIN s_trade2cst t2c3 ON c.TradeGUID = t2c3.TradeGUID AND  t2c3.CstNum = 3
            --LEFT JOIN p_Customer c3 ON t2c3.CstGUID = c3.CstGUID
            --LEFT JOIN s_trade2cst t2c4 ON c.TradeGUID = t2c4.TradeGUID AND  t2c4.CstNum = 4
            --LEFT JOIN p_Customer c4 ON t2c4.CstGUID = c4.CstGUID
            LEFT JOIN s_Order o ON c.TradeGUID = o.TradeGUID AND ISNULL(o.CloseReason, '') = '转签约'
            LEFT JOIN s_Contract sc ON c.LastSaleGUID = sc.ContractGUID AND sc.CloseReason = '换房'
            LEFT JOIN(SELECT    f.TradeGUID ,
                                SUM(CASE WHEN ItemType = '非贷款类房款' THEN Amount ELSE 0 END) fkamount1 ,
                                SUM(CASE WHEN ItemType = '贷款类房款' THEN Amount ELSE 0 END) fkamount2 ,
                                SUM(CASE WHEN ItemType LIKE '%贷款类房款' THEN RmbYe ELSE 0 END) qkamount1 ,
                                SUM(CASE WHEN ItemType = '非贷款类房款' THEN RmbYe ELSE 0 END) qkamount2
                      FROM  s_Fee f
                            INNER JOIN #contract c ON f.TradeGUID = c.TradeGUID
                      GROUP BY f.TradeGUID) f ON c.TradeGUID = f.TradeGUID
            LEFT JOIN(SELECT    g.SaleGUID ,
                                SUM(CASE WHEN ItemType LIKE '%贷款类房款' THEN Amount ELSE 0 END) skamount ,
                                MAX(CASE WHEN ItemType = '贷款类房款' THEN g.GetDate ELSE NULL END) fkdate ,
                                MAX(CASE WHEN ItemType LIKE '%贷款类房款' THEN g.GetDate ELSE NULL END) skdate
                      FROM  s_Getin g
                            INNER JOIN #contract c ON g.SaleGUID = c.TradeGUID
                      WHERE ISNULL(g.Status, '') <> '作废'
                      GROUP BY g.SaleGUID) g ON c.TradeGUID = g.SaleGUID
            LEFT JOIN s_SaleService s ON c.ContractGUID = s.ContractGUID AND s.ServiceItem = '入伙服务'
            LEFT JOIN s_SaleServiceProc s1 ON s.SaleServiceGUID = s1.SaleServiceGUID AND s1.ServiceProc = '已交接钥匙'
            LEFT JOIN #ts tsyj ON c.roomguid = tsyj.roomguid
			LEFT JOIN #顶层 dc ON dc.projGUID = r.projGUID AND   dc.bldGUID = r.bldGUID
     WHERE  c.Status = '激活' AND sc.CloseReason = '换房' AND   ISNULL(o.QSDate, sc.QSDate) IS NULL AND P1.projguid IN (@var_projguid)) a
ORDER BY a.项目名称 ,
         a.分区 ,
         a.楼栋名称 ,
         a.单元 ,
         a.房号;

DROP TABLE #contract ,
           #order ,
           #room ,
           #ts ,
           #szyx,
		   #顶层;