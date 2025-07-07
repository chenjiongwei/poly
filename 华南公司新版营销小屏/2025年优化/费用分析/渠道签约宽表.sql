/* 功能：宽表创建脚本，用于统计各类销售渠道对应的房间销售情况
   创建人: chenjw 2025-06-16
   备注：
*/
SELECT  r.buguid , --公司GUID
        bu.buname , --公司名称
        r.ProjGUID , --项目GUID
        p.ProjName , --项目名称
        pp.ProjGUID AS ParentProjGUID , --父项目GUID
        r.BldGUID AS SaleBldGUID , --销售楼栋GUID
        bld.BldName AS SaleBldName , -- 销售楼栋名称
        r.RoomGUID , --房间GUID
        bld.BldFullName + (CASE WHEN r.Unit <> '' THEN '-' + r.Unit + '-' + r.Room ELSE +'-' + r.Room END) AS RoomInfo , --房间全称
        ord.RgQyDate AS RgQsDate , -- 认购日期
        -- CASE WHEN ord.SaleType = '认购' THEN ISNULL(ord.JyTotal, '')ELSE 0 END AS RgAmount ,
        ord.JyTotal AS QdRgAmount , -- 渠道认购金额
        ord.bldArea AS QdRgbldArea ,-- 渠道认购建筑面积 
        ord.QyQsDate AS QyQsDate , -- 签约日期
        CASE WHEN ord.SaleType = '签约' THEN ISNULL(ord.JyTotal, 0)ELSE 0 END AS QdQyAmount ,-- 渠道签约金额
        CASE WHEN ord.SaleType = '签约' THEN ISNULL(ord.bldArea, 0)ELSE 0 END AS QdQybldArea ,-- 渠道签约建筑面积
        ord.CstSource AS CstSource , -- 客户来源
        ord.CstSourceCode AS CstSourceCode , -- 客户来源编码
        case when  ord.CstSource ='保利惠' then '销售代理'  
             when  ord.CstSource ='老带新' then '老带新'
             when  ord.CstSource ='小程序导流' then '数字营销'
             when  ord.CstSource ='二手转介' then '第三方分销'
             when  ord.CstSource ='渠道分销' then '第三方分销'
             when  ord.CstSource ='全民营销' then '全民营销'
             when  ord.CstSource ='数字营销' then '数字营销'
             when  ord.CstSource ='外拓渠道' then '销售代理'
             when  ord.CstSource ='自然来访' then '销售代理'
             when  ord.CstSource ='广告投放' then '数字营销'
             when  ord.CstSource ='销售自获客' then '销售代理'
             when  ord.CstSource ='行销自拓' then '销售代理'
             when  ord.CstSource ='一手代理' then '销售代理'
             when  ord.CstSource ='置业顾问拓客' then '销售代理'
             else '' end as FourthSaleCostName --四级科目
FROM    p_room r
        INNER JOIN p_Building bld ON bld.BldGUID = r.BldGUID
        INNER JOIN myBusinessUnit bu ON bu.BUGUID = r.BUGUID
        INNER JOIN p_Project p ON r.ProjGUID = p.ProjGUID
        LEFT JOIN p_Project pp ON p.ParentCode = pp.ProjCode AND   pp.Level = 2
        INNER JOIN(SELECT   BUGUID ,
                            ProjGUID ,
                            RoomGUID ,
                            TradeGUID ,
                            Status ,
                            CstSourceCode ,
                            CstSource ,
                            QSDate AS RgQyDate ,
                            NULL AS QyQsDate ,
                            JyTotal ,
                            bldArea ,
                            '认购' AS SaleType
                   FROM s_order
                   WHERE   Status = '激活'  AND   CstSource in (
                                '保利惠',
                                '老带新',
                                '小程序导流',
                                '二手转介',
                                '渠道分销',
                                '全民营销',
                                '数字营销',
                                '外拓渠道',
                                '自然来访',
                                '广告投放',
                                '销售自获客',
                                '行销自拓',
                                '一手代理',
                                '置业顾问拓客'
                   )
                   UNION ALL
                   SELECT   a.BUGUID ,
                            a.ProjGUID ,
                            a.RoomGUID ,
                            a.TradeGUID ,
                            a.Status ,
                            a.CstSourceCode ,
                            a.CstSource ,
                            o.QSDate AS RgQyDate ,
                            a.QSDate AS QyQsDate ,
                            a.JyTotal ,
                            a.bldArea AS bldArea ,
                            '签约' AS SaleType
                   FROM s_Contract a
                        LEFT JOIN s_Order o ON a.TradeGUID = o.TradeGUID AND   o.Status = '关闭'
                   WHERE   a.Status = '激活' AND (o.Status = '关闭' AND o.CloseReason = '转签约')  
                   AND a.CstSource in (
                                '保利惠',
                                '老带新',
                                '小程序导流',
                                '二手转介',
                                '渠道分销',
                                '全民营销',
                                '数字营销',
                                '外拓渠道',
                                '自然来访',
                                '广告投放',
                                '销售自获客',
                                '行销自拓',
                                '一手代理',
                                '置业顾问拓客'
                   )
        ) ord ON ord.RoomGUID = r.RoomGUID
WHERE   r.RoomGUID = ord.RoomGUID AND   r.IsVirtualRoom = 0 










