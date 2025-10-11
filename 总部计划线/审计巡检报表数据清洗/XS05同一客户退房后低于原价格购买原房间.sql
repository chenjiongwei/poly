
-- XS05同一客户退房后低于原价格购买原房间
-- 此存储过程用于查询同一客户退房后低于原价格购买原房间的情况
-- 主要用于审计巡检报表数据清洗
use erp25
go

create or alter proc usp_dss_XS05同一客户退房后低于原价格购买原房间_qx
as 
begin 
--DECLARE @buname VARCHAR(20);
--SET @buname = '海南公司';

    -- 第一步：查询同一客户多次购买同一房间的情况，并存入临时表#t
    SELECT 
        -- 拼接客户姓名，最多支持4个客户
        CASE
            WHEN CstName2.CstName IS NULL THEN
                CstName1.CstName
            WHEN CstName3.CstName IS NULL THEN
                CstName1.CstName + ';' + CstName2.CstName
            WHEN CstName4.CstName IS NULL THEN
                CstName1.CstName + ';' + CstName2.CstName + ';' + CstName3.CstName
            ELSE 
                CstName1.CstName + ';' + CstName2.CstName + ';' + CstName3.CstName + ';' + CstName4.CstName
        END AS CstName,
        -- 拼接客户身份证号，最多支持4个客户
        CASE
            WHEN CstName2.CardID IS NULL THEN
                CstName1.CardID
            WHEN CstName3.CardID IS NULL THEN
                CstName1.CardID + ';' + CstName2.CardID
            WHEN CstName4.CardID IS NULL THEN
                CstName1.CardID + ';' + CstName2.CardID + ';' + CstName3.CardID
            ELSE 
                CstName1.CardID + ';' + CstName2.CardID + ';' + CstName3.CardID + ';' + CstName4.CardID
        END AS CardID,
        RoomInfo,
        roomguid,
        COUNT(1) ts  -- 统计同一房间被同一客户购买的次数
    INTO #t
    FROM es_order c with(nolock)
        LEFT JOIN s_trade2cst Cst1 with(nolock) ON c.TradeGUID = Cst1.TradeGUID AND Cst1.CstNum = 1
        LEFT JOIN p_Customer CstName1 with(nolock) ON Cst1.CstGUID = CstName1.CstGUID
        LEFT JOIN s_trade2cst Cst2 with(nolock) ON c.TradeGUID = Cst2.TradeGUID AND Cst2.CstNum = 2
        LEFT JOIN p_Customer CstName2 with(nolock) ON Cst2.CstGUID = CstName2.CstGUID
        LEFT JOIN s_trade2cst Cst3 with(nolock) ON c.TradeGUID = Cst3.TradeGUID AND Cst3.CstNum = 3
        LEFT JOIN p_Customer CstName3 with(nolock) ON Cst3.CstGUID = CstName3.CstGUID
        LEFT JOIN s_trade2cst Cst4 with(nolock) ON c.TradeGUID = Cst4.TradeGUID AND Cst4.CstNum = 4
        LEFT JOIN p_Customer CstName4 with(nolock) ON Cst4.CstGUID = CstName4.CstGUID
    WHERE (
            c.status = '激活'
            OR c.closereason IN ( '退房', '转签约' )  -- 包含退房和转签约的订单
        )
        -- 公司筛选条件（已注释）
        -- AND c.buguid IN (
        --                     SELECT buguid FROM mybusinessunit a
        --                         left join p_DevelopmentCompany b on a.BUName = b.DevelopmentCompanyName 
        --                         where b.DevelopmentCompanyGUID in (@buname)
        --                 )
    --AND c.roomguid ='4ab76f27-9069-4112-8495-9d5c85dfb55d'  -- 测试用
    GROUP BY 
        -- 按客户姓名分组
        CASE
            WHEN CstName2.CstName IS NULL THEN
                CstName1.CstName
            WHEN CstName3.CstName IS NULL THEN
                CstName1.CstName + ';' + CstName2.CstName
            WHEN CstName4.CstName IS NULL THEN
                CstName1.CstName + ';' + CstName2.CstName + ';' + CstName3.CstName
            ELSE 
                CstName1.CstName + ';' + CstName2.CstName + ';' + CstName3.CstName + ';' + CstName4.CstName
        END,
        -- 按客户身份证号分组
        CASE
            WHEN CstName2.CardID IS NULL THEN
                CstName1.CardID
            WHEN CstName3.CardID IS NULL THEN
                CstName1.CardID + ';' + CstName2.CardID
            WHEN CstName4.CardID IS NULL THEN
                CstName1.CardID + ';' + CstName2.CardID + ';' + CstName3.CardID
            ELSE 
                CstName1.CardID + ';' + CstName2.CardID + ';' + CstName3.CardID + ';' + CstName4.CardID
        END,
        RoomInfo,
        roomguid
    HAVING (COUNT(1)) > 1;  -- 只保留同一客户多次购买同一房间的记录

    -- 第二步：获取订单详细信息，并按照房间和创建时间排序
    SELECT 
        ROW_NUMBER() OVER (PARTITION BY c.roomguid ORDER BY c.createdon) rownum,  -- 为每个房间的订单按创建时间排序编号
        c.roomguid,
        c.orderguid,
        c.tradeguid,
        -- 拼接客户姓名
        CASE
            WHEN CstName2.CstName IS NULL THEN
                CstName1.CstName
            WHEN CstName3.CstName IS NULL THEN
                CstName1.CstName + ';' + CstName2.CstName
            WHEN CstName4.CstName IS NULL THEN
                CstName1.CstName + ';' + CstName2.CstName + ';' + CstName3.CstName
            ELSE 
                CstName1.CstName + ';' + CstName2.CstName + ';' + CstName3.CstName + ';' + CstName4.CstName
        END AS CstName,
        -- 拼接客户身份证号
        CASE
            WHEN CstName2.CardID IS NULL THEN
                CstName1.CardID
            WHEN CstName3.CardID IS NULL THEN
                CstName1.CardID + ';' + CstName2.CardID
            WHEN CstName4.CardID IS NULL THEN
                CstName1.CardID + ';' + CstName2.CardID + ';' + CstName3.CardID
            ELSE 
                CstName1.CardID + ';' + CstName2.CardID + ';' + CstName3.CardID + ';' + CstName4.CardID
        END AS CardID
    INTO #order
    FROM es_order c with(nolock)
        LEFT JOIN s_trade2cst Cst1 with(nolock) ON c.TradeGUID = Cst1.TradeGUID AND Cst1.CstNum = 1
        LEFT JOIN p_Customer CstName1 with(nolock) ON Cst1.CstGUID = CstName1.CstGUID
        LEFT JOIN s_trade2cst Cst2 with(nolock) ON c.TradeGUID = Cst2.TradeGUID AND Cst2.CstNum = 2
        LEFT JOIN p_Customer CstName2 with(nolock) ON Cst2.CstGUID = CstName2.CstGUID
        LEFT JOIN s_trade2cst Cst3 with(nolock) ON c.TradeGUID = Cst3.TradeGUID AND Cst3.CstNum = 3
        LEFT JOIN p_Customer CstName3 with(nolock) ON Cst3.CstGUID = CstName3.CstGUID
        LEFT JOIN s_trade2cst Cst4 with(nolock) ON c.TradeGUID = Cst4.TradeGUID AND Cst4.CstNum = 4
        LEFT JOIN p_Customer CstName4 with(nolock) ON Cst4.CstGUID = CstName4.CstGUID
    WHERE roomguid IN (
                        SELECT roomguid FROM #t
                    )
        AND c.CstName IN (
                            SELECT CstName FROM #t
                        );
   
    -- 删除结果表
    truncate table XS05同一客户退房后低于原价格购买原房间_qx;

    -- 第三步：生成最终报表，展示同一客户多次购买同一房间的详细信息
    insert into XS05同一客户退房后低于原价格购买原房间_qx
    SELECT 
        c.RoomGUID,
        bu.BUName 公司名称,
        ISNULL(p1.ProjName, p.ProjName) 项目名称,
        ISNULL(p1.SpreadName, p.SpreadName) 推广名称,
        --r.ProductType 产品,
        --r.bldfullname 楼栋,
        r.RoomInfo 房间,
        o.CstName AS '客户名称',
        o.CardID AS '身份证号',
        r.bldarea 面积,
        so.QSDate 认购时间,
        sc.QSDate 签约时间,
        so.JyTotal 成交金额,
        so.PayformName 付款方式,
        so.DiscntRemark 折扣说明,
        c.QSDate 第一次认购时间,
        c.JyTotal 第一次成交金额,
        c.PayformName 第一次付款方式,
        c.DiscntRemark 第一次折扣说明,
        c.closedate 第一次关闭时间,
        c.closereason 第一次关闭原因,
        so1.QSDate 第二次认购时间,
        so1.JyTotal 第二次成交金额,
        so1.PayformName 第二次付款方式,
        so1.DiscntRemark 第二次折扣说明,
        so1.closedate 第二次关闭时间,
        so1.closereason 第二次关闭原因,
        so2.QSDate 第三次认购时间,
        so2.JyTotal 第三次成交金额,
        so2.PayformName 第三次付款方式,
        so2.DiscntRemark 第三次折扣说明,
        so2.closedate 第三次关闭时间,
        so2.closereason 第三次关闭原因
    FROM #order o
        LEFT JOIN s_order so with(nolock) on o.orderguid = so.orderguid
        LEFT JOIN s_contract sc with(nolock) on sc.TradeGUID = so.TradeGUID and sc.status = '激活' and so.closereason = '转签约'
        LEFT JOIN #order o1 ON o.roomguid = o1.roomguid AND o1.rownum = 2
        LEFT JOIN s_order so1 with(nolock) ON o1.orderguid = so1.orderguid
        LEFT JOIN #order o2 ON o.roomguid = o2.roomguid AND o2.rownum = 3
        LEFT JOIN s_order so2 with(nolock) ON o2.orderguid = so2.orderguid
        LEFT JOIN #order o3 ON o.roomguid = o3.roomguid AND o3.rownum = 4
        LEFT JOIN s_order so3 with(nolock) ON o3.orderguid = so3.orderguid
        LEFT JOIN s_order c with(nolock) ON o.orderguid = c.orderguid
        LEFT JOIN myBusinessUnit bu with(nolock) ON c.BUGUID = bu.BUGUID
        INNER JOIN ep_room r with(nolock) ON c.RoomGUID = r.RoomGUID
        LEFT JOIN p_Project p with(nolock) ON c.ProjGUID = p.ProjGUID
        LEFT JOIN p_Project p1 with(nolock) ON p.ParentCode = p1.ProjCode AND p1.ApplySys LIKE '%0101%'
    WHERE o.rownum = 1  -- 只取每个房间的第一条记录作为主记录
    ORDER BY 
        bu.BUName,  -- 按公司名称排序
        r.RoomInfo;  -- 按房间信息排序

    -- 清理临时表
    DROP TABLE #order, #t;

end 

-- drop table  XS05同一客户退房后低于原价格购买原房间_qx
create TABLE  XS05同一客户退房后低于原价格购买原房间_qx
(
    [RoomGUID] [uniqueidentifier] NULL,
	[公司名称] [varchar](50) NULL,
	[项目名称] [varchar](400) NULL,
	[推广名称] [varchar](400) NULL,
	[房间] [varchar](262) NULL,
	[客户名称] [nvarchar](403) NULL,
	[身份证号] [varchar](803) NULL,
	[面积] [money] NULL,
	[认购时间] [datetime] NULL,
	[签约时间] [datetime] NULL,
	[成交金额] [money] NULL,
	[付款方式] [varchar](240) NULL,
	[折扣说明] [text] NULL,
	[第一次认购时间] [datetime] NULL,
	[第一次成交金额] [money] NULL,
	[第一次付款方式] [varchar](240) NULL,
	[第一次折扣说明] [text] NULL,
	[第一次关闭时间] [datetime] NULL,
	[第一次关闭原因] [varchar](30) NULL,
	[第二次认购时间] [datetime] NULL,
	[第二次成交金额] [money] NULL,
	[第二次付款方式] [varchar](240) NULL,
	[第二次折扣说明] [text] NULL,
	[第二次关闭时间] [datetime] NULL,
	[第二次关闭原因] [varchar](30) NULL,
	[第三次认购时间] [datetime] NULL,
	[第三次成交金额] [money] NULL,
	[第三次付款方式] [varchar](240) NULL,
	[第三次折扣说明] [text] NULL,
	[第三次关闭时间] [datetime] NULL,
	[第三次关闭原因] [varchar](30) NULL
) 