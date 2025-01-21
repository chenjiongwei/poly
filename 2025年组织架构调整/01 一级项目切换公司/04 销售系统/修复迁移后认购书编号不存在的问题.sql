/*
问题描述：
保利里城迁移到湖南公司的长沙保利城项目，在保利里程的时候操作的认购，迁移过来之后无法转签约，提示该认购书未分配给当前项目使用,请重新录入。定单里面的认购书编号修改不了，保利里程也查不到这个编号，客户整理了数据需要后台修复
问题排查：
1、原保利里城公司的项目都没有启动认购书管理，长沙保利城和长沙保利檀樾两个项目都没有认购书使用记录
2、客户已经在华南公司-认购书管理模块中新建了两个认购书编号使用模版；
3、将客户提供修复清单里的认购书插入到新创建的模版中，并设置为“已使用”状态；
*/

/*
-- 将有问题的认购书清单插入到临时表
CREATE TABLE [dbo].[情况明细表](
	[序号] [float] NULL,
	[公司名称] [nvarchar](255) NULL,
	[项目推广名称] [nvarchar](255) NULL,
	[项目简称] [nvarchar](255) NULL,
	[房间] [nvarchar](255) NULL,
	[客户名称] [nvarchar](255) NULL,
	[认购日期] [datetime] NULL,
	[认购书编号] [nvarchar](255) NULL
) ON [PRIMARY]

GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (1, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-商业-2-20栋底商-1--213', N'何熹武', CAST(N'2024-04-22 00:00:00.000' AS DateTime), N'0001338')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (2, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期（B）区洋房负一层-1-412', N'胡石林', CAST(N'2022-11-06 00:00:00.000' AS DateTime), N'2100883')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (3, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期（B）区洋房负一层-1-415', N'雷薛夫', CAST(N'2022-11-06 00:00:00.000' AS DateTime), N'2100916')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (4, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期（B）区洋房负一层-1-416', N'卜翔钰', CAST(N'2022-11-06 00:00:00.000' AS DateTime), N'2100908')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (5, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期（B）区洋房负一层-1-425', N'王婧', CAST(N'2022-11-06 00:00:00.000' AS DateTime), N'2100925')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (6, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期（B）区洋房负一层-1-427', N'李双', CAST(N'2022-11-06 00:00:00.000' AS DateTime), N'2100868')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (7, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期B区高层负三层-1-001', N'李嘉程', CAST(N'2024-05-16 00:00:00.000' AS DateTime), N'0000924')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (8, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期B区洋房负二层-1-222', N'张小利', CAST(N'2022-11-06 00:00:00.000' AS DateTime), N'2100728')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (9, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期B区洋房负二层-1-223', N'张小利', CAST(N'2022-11-06 00:00:00.000' AS DateTime), N'2100729')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (10, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期B区洋房负二层-1-249', N'陈香华', CAST(N'2022-11-06 00:00:00.000' AS DateTime), N'2100876')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (11, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期B区洋房负二层-1-251', N'易永良', CAST(N'2022-11-06 00:00:00.000' AS DateTime), N'2100884')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (12, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期B区洋房负二层-1-253', N'雷智慧', CAST(N'2022-11-06 00:00:00.000' AS DateTime), N'2100913')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (13, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期B区洋房负二层-1-257', N'王奕莹', CAST(N'2022-11-06 00:00:00.000' AS DateTime), N'2100726')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (14, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期B区洋房负二层-1-267', N'张小利', CAST(N'2022-11-06 00:00:00.000' AS DateTime), N'2100730')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (15, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期B区洋房负二层-1-274', N'邬颖', CAST(N'2022-11-06 00:00:00.000' AS DateTime), N'2100861')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (16, N'湖南公司', N'长沙保利城', N'长沙保利城-三期', N'长沙保利城-三期-车位-三期B区洋房负二层-1-287', N'王俊', CAST(N'2022-11-06 00:00:00.000' AS DateTime), N'2100877')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (17, N'湖南公司', N'长沙保利城', N'长沙保利城-四期', N'长沙保利城-四期-商业-1－13A栋-1-109', N'彭彩霞', CAST(N'2024-03-27 00:00:00.000' AS DateTime), N'0001335')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (18, N'湖南公司', N'长沙保利城', N'长沙保利城-四期', N'长沙保利城-四期-商业-1－16栋-1-104', N'廖宇鑫', CAST(N'2023-07-05 00:00:00.000' AS DateTime), N'0001365')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (19, N'湖南公司', N'长沙保利城', N'长沙保利城-四期', N'长沙保利城-四期-住宅-2－40栋-1-1401', N'张春媚', CAST(N'2024-05-13 00:00:00.000' AS DateTime), N'0001340')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (20, N'湖南公司', N'长沙保利城', N'长沙保利城-四期', N'长沙保利城-四期-车位-四期K区高层负一层A-1-045', N'刘丽', CAST(N'2024-05-05 00:00:00.000' AS DateTime), N'0000923')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (21, N'湖南公司', N'长沙保利城', N'长沙保利城-一期', N'长沙保利城-一期-商业-A1-101', N'长沙五丰商业管理有限公司', CAST(N'2023-09-29 00:00:00.000' AS DateTime), N'0001191')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (22, N'湖南公司', N'长沙保利城', N'长沙保利城-一期', N'长沙保利城-一期-商业-A6-106', N'张扬;曾琼', CAST(N'2024-03-24 00:00:00.000' AS DateTime), N'0001371')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (23, N'湖南公司', N'长沙保利城', N'长沙保利城-一期', N'长沙保利城-一期-商业-A6-206', N'张扬;曾琼', CAST(N'2024-03-24 00:00:00.000' AS DateTime), N'0001372')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (24, N'湖南公司', N'一期', N'长沙保利檀樾-一期', N'长沙保利檀樾-一期-2栋-1-104', N'蔡燕', CAST(N'2024-06-05 00:00:00.000' AS DateTime), N'0000367')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (25, N'湖南公司', N'一期', N'长沙保利檀樾-一期', N'长沙保利檀樾-一期-3栋-1-506', N'李嘉;王晓玉', CAST(N'2023-07-27 00:00:00.000' AS DateTime), N'0000258')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (26, N'湖南公司', N'一期', N'长沙保利檀樾-一期', N'长沙保利檀樾-一期-5栋-1-507', N'周卫平', CAST(N'2024-02-17 00:00:00.000' AS DateTime), N'0000357')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (27, N'湖南公司', N'一期', N'长沙保利檀樾-一期', N'长沙保利檀樾-一期-5栋-1-707', N'肖航', CAST(N'2024-05-02 00:00:00.000' AS DateTime), N'0000366')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (28, N'湖南公司', N'一期', N'长沙保利檀樾-一期', N'长沙保利檀樾-一期-8栋-1-909', N'郑益琴', CAST(N'2022-10-21 00:00:00.000' AS DateTime), N'0000141')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (29, N'湖南公司', N'一期', N'长沙保利檀樾-一期', N'长沙保利檀樾-一期-9栋-1-505', N'李鸿军;李杨淇', CAST(N'2023-08-21 00:00:00.000' AS DateTime), N'0000261')
GO
INSERT [dbo].[情况明细表] ([序号], [公司名称], [项目推广名称], [项目简称], [房间], [客户名称], [认购日期], [认购书编号]) VALUES (30, N'湖南公司', N'一期', N'长沙保利檀樾-一期', N'长沙保利檀樾-一期-9栋-1-506', N'李湘平', CAST(N'2023-08-13 00:00:00.000' AS DateTime), N'0000263')
GO
*/

-- 将异常信息插入到临时表
SELECT  a.* ,
        r.RoomGUID ,
        o.OrderGUID ,
        o.CreatedBy ,
        o.CreatedOn ,
        o.PotocolNO ,
        o.NoDetailGUID ,
        r.ProjGUID ,
        r.BUGUID
INTO    #Ord
FROM    [情况明细表] a
        INNER JOIN ep_room r ON a.房间 = r.RoomInfo
        INNER JOIN s_Order o ON o.RoomGUID = r.RoomGUID
WHERE   o.Status = '激活';

--备份表
--select  * into  s_PotocolNODetail_bak20240725 from  [s_PotocolNODetail];

--查询保利城 保存到临时表
SELECT  NEWID() AS NoDetailGUID ,
        'C54A8B6F-F034-EF11-B3A4-F40270D39969' AS [PotocolNoGUID] ,
        NULL AS [Notype] ,
        a.PotocolNO ,
        a.CreatedBy AS [Lyr] ,
        a.CreatedOn AS [LyDate] ,
        '已使用' AS [Status] ,
        NULL AS [Hxr] ,
        NULL AS [HxDate] ,
        NULL AS [ZfType] ,
        NULL AS [ZfText] ,
        OrderGUID
INTO    #s_PotocolNODetail_blc
FROM    #Ord a
WHERE   NoDetailGUID IS NULL AND a.项目简称 LIKE '长沙保利城%';

--查询长沙保利檀樾 保存到临时表
SELECT  NEWID() AS NoDetailGUID ,
        'f8bce6c2-bf36-ef11-b3a4-f40270d39969' AS [PotocolNoGUID] ,
        NULL AS [Notype] ,
        a.PotocolNO ,
        a.CreatedBy AS [Lyr] ,
        a.CreatedOn AS [LyDate] ,
        '已使用' AS [Status] ,
        NULL AS [Hxr] ,
        NULL AS [HxDate] ,
        NULL AS [ZfType] ,
        NULL AS [ZfText] ,
        OrderGUID
INTO    #s_PotocolNODetail_blty
FROM    #Ord a
WHERE   NoDetailGUID IS NULL AND a.项目简称 LIKE '长沙保利檀樾%';

--插入认购书使用明细
INSERT INTO [s_PotocolNODetail]([NoDetailGUID], [PotocolNoGUID], [Notype], [PotocolNO], [Lyr], [LyDate], [Status], [Hxr], [HxDate], [ZfType], [ZfText])
SELECT  [NoDetailGUID] ,
        [PotocolNoGUID] ,
        [Notype] ,
        [PotocolNO] ,
        [Lyr] ,
        [LyDate] ,
        [Status] ,
        [Hxr] ,
        [HxDate] ,
        [ZfType] ,
        NULL AS [ZfText]
FROM    #s_PotocolNODetail_blc;

--插入认购书使用明细
INSERT INTO [s_PotocolNODetail]([NoDetailGUID], [PotocolNoGUID], [Notype], [PotocolNO], [Lyr], [LyDate], [Status], [Hxr], [HxDate], [ZfType], [ZfText])
SELECT  [NoDetailGUID] ,
        [PotocolNoGUID] ,
        [Notype] ,
        [PotocolNO] ,
        [Lyr] ,
        [LyDate] ,
        [Status] ,
        [Hxr] ,
        [HxDate] ,
        [ZfType] ,
        NULL AS [ZfText]
FROM    #s_PotocolNODetail_blty;

-- 更新认购单的NoDetailGUID字段
--备份数据表
SELECT  o.*
INTO    s_Order_bak20240725
FROM    s_Order o
WHERE   o.OrderGUID IN(SELECT   OrderGUID FROM  #Ord);

--修改
UPDATE  a
SET a.NoDetailGUID = b.NoDetailGUID
--select  a.OrderGUID,a.NoDetailGUID,b.NoDetailGUID
FROM    s_Order a
        INNER JOIN #s_PotocolNODetail_blc b ON a.OrderGUID = b.OrderGUID
WHERE   a.NoDetailGUID IS NULL;

UPDATE  a
SET a.NoDetailGUID = b.NoDetailGUID
--select  a.OrderGUID,a.NoDetailGUID,b.NoDetailGUID
FROM    s_Order a
        INNER JOIN #s_PotocolNODetail_blty b ON a.OrderGUID = b.OrderGUID
WHERE   a.NoDetailGUID IS NULL;

--删除临时表
DROP TABLE #Ord;
DROP TABLE #s_PotocolNODetail_blty;
DROP TABLE #s_PotocolNODetail_blc;