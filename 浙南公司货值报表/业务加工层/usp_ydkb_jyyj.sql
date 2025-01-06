USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_ydkb_jyyj]    Script Date: 2025/1/6 10:32:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--usp_ydkb_jyyj
ALTER   PROC [dbo].[usp_ydkb_jyyj]
AS
    BEGIN 

--01移动-总经理-经营业绩
/*
1、任务数单位都是金额，无面积任务。与移动报表端取数口径相同。
  华南公司年度任务：全口径（含代建项目及非操盘项目）
  城市公司的年度任务数要包含代建项目任务，不包含非操盘项目任务
  年度完成数华南公司整体是全部项目加和；城市公司是除非操盘项目加和
  月度完成数华南公司整体是全部项目加和；城市公司是除非操盘项目加和
2、计算去化率全部用签约面积计算，新货去化率用认购面积计算去化率。
3、计算任务完成率全部用金额计算，因为任务是以金额下达的。

4、城市公司月度任务和签约任务数据用项目任务那里汇总，并且要求剔除万科里水、万科F06、金茂绿岛湖、高明美的 四个非操盘项目；
5、华南公司全口径任务=城市公司任务+非我司操盘任务
6、计算完成率的时候，城市公司的任务完成率要剔除非我司操盘，华南公司整体要包含非我司操盘。
7、取数口径同集团业绩短信取数口径保持一致。注意：销售日报“本年签约金额”也需要同步增加特殊业绩录入金额
8、将本年回笼金额的取数口径进行调整，本年累计回笼金额=应退未退金额 +本年认购金额+本年签约金额+关闭交易本年退款金额

2019-09-10 增加合作项目业绩统计
2019-11-05 chenjw 修改
1、增加签约、销售金额的权益口径和并表口径取数
*/

        IF OBJECT_ID(N'ydkb_jyyj', N'U') IS NOT NULL
            BEGIN
                DROP TABLE  ydkb_jyyj;
            END; 

        CREATE TABLE ydkb_jyyj
            (
              组织架构ID UNIQUEIDENTIFIER ,
              组织架构名称 VARCHAR(400) ,
              组织架构编码 [VARCHAR](100) ,
              组织架构类型 [INT] ,
      
      --本月任务金额
              本月销售任务金额 MONEY , --本月销售任务金额
              本月操盘销售任务金额 MONEY , --本月操盘销售任务金额
              本月签约任务金额 MONEY ,--本月签约任务金额
              本月操盘签约任务金额 MONEY ,--本月操盘签约任务金额
              本月产成品任务金额 MONEY , --本月产成品任务金额 
              本月回款任务金额 MONEY ,--本月回款任务金额
              本月操盘回款任务金额 MONEY ,--本月操盘回款任务金额
              本月成本直投任务金额 MONEY , --本月成本直投任务金额
              

      
      --本月完成金额
              本月销售金额 MONEY , --本月销售金额
              本月操盘销售金额 MONEY , --本月操盘销售金额
              本月签约金额 MONEY ,--本月签约金额
              本月操盘签约金额 MONEY ,--本月操盘签约金额
              本月产成品金额 MONEY , --本月产成品金额 
              本月回款金额 MONEY ,--本月回款金额
              本月操盘回款金额 MONEY ,--本月操盘回款金额
              本月回款金额权益口径 MONEY ,--本月回款金额权益口径 
              本月回款金额并表口径 MONEY ,--本月回款金额并表口径 
              本月成本直投金额 MONEY , --本月成本直投金额
               
      
      --本月完成率
              本月销售完成率 MONEY , --本月销售完成率
              本月签约完成率 MONEY ,--本月签约完成率
              本月产成品完成率 MONEY , --本月产成品完成率
              本月回款完成率 MONEY ,--本月回款完成率
              本月成本直投完成率 MONEY ,--本月成本直投完成率
      
     
      --本年任务金额
              本年销售任务金额 MONEY , --本年销售任务金额
              本年操盘销售任务金额 MONEY , --本年操盘销售任务金额
              本年签约任务金额 MONEY ,--本年签约任务金额
              本年操盘签约任务金额 MONEY ,--本年操盘签约任务金额
              本年产成品任务金额 MONEY , --本年产成品任务金额 
              本年回款任务金额 MONEY ,--本年回款任务金额
              本年操盘回款任务金额 MONEY ,--本年操盘回款任务金额
              本年成本直投任务金额 MONEY , --本年成本直投任务金额
              本年投资拓展任务金额 MONEY , --本年投资拓展任务金额
            
      --本年完成金额
              本年销售金额 MONEY , --本年销售金额
              本年销售金额权益口径 MONEY , --本年销售金额权益口径
              本年销售金额并表口径 MONEY , --本年销售金额并表口径
              本年操盘销售金额 MONEY , --本年操盘销售金额
              本年签约金额 MONEY ,--本年签约金额
              本年签约金额权益口径 MONEY ,--本年签约金额权益口径
              本年签约金额并表口径 MONEY ,--本年签约金额并表口径
              本年操盘签约金额 MONEY ,--本年操盘签约金额
              本年产成品金额 MONEY , --本年产成品金额 
              本年回款金额 MONEY ,--本年回款金额
              本年操盘回款金额 MONEY ,--本年操盘回款金额
              本年回款金额权益口径 MONEY ,--本年回款金额权益口径 
              本年回款金额并表口径 MONEY ,--本年回款金额并表口径 
              本年成本直投金额 MONEY , --本年成本直投金额
              本年投资拓展金额 MONEY , --  本年投资拓展金额
      
      --本年完成率
              本年销售完成率 MONEY , --本年销售完成率
              本年签约完成率 MONEY ,--本年签约完成率
              本年产成品完成率 MONEY , --本年产成品完成率
              本年回款完成率 MONEY ,--本年回款完成率
              本年成本直投完成率 MONEY ,--本年成本直投完成率   
              本年投资拓展完成率 MONEY , --本年投资拓展完成率
              
      --本季度任务金额
              本季度成本直投任务金额 MONEY , --本季度成本直投任务金额 
       --本季度完成金额
              本季度成本直投金额 MONEY , --本季度成本直投金额 
      --本季度完成率
              本季度成本直投完成率 MONEY , --本季度成本直投完成率 
      
      --1-2月份
              JanFeb新货推货面积 MONEY , --1-2月份新货推货面积
              JanFeb存货推货面积 MONEY , --1-2月份存货推货面积
              JanFeb新货认购面积 MONEY , --1-2月份新货认购面积
              JanFeb存货签约面积 MONEY , --1-2月份存货签约面积
              JanFeb新货去化率 MONEY , --1-2月份新货去化率
              JanFeb存货去化率 MONEY , --1-2月份存货去化率
              JanFeb综合去化率 MONEY , --1-2月份综合去化率
      
      --3月份
              Mar新货推货面积 MONEY , --3月份新货推货面积
              Mar存货推货面积 MONEY , --3月份存货推货面积
              Mar新货认购面积 MONEY , --3月份新货认购面积
              Mar存货签约面积 MONEY , --3月份存货签约面积
              Mar新货去化率 MONEY , --3月份新货去化率
              Mar存货去化率 MONEY , --3月份存货去化率
              Mar综合去化率 MONEY , --3月份综合去化率
      
      --4月份
              Apr新货推货面积 MONEY , --4月份新货认购面积
              Apr存货推货面积 MONEY , --4月份存货签约面积
              Apr新货认购面积 MONEY , --4月份新货认购面积
              Apr存货签约面积 MONEY , --4月份存货签约面积
              Apr新货去化率 MONEY , --4月份新货去化率
              Apr存货去化率 MONEY , --4月份存货去化率
              Apr综合去化率 MONEY , --4月份综合去化率
      
      --5月份
              May新货推货面积 MONEY , --5月份新货认购面积
              May存货推货面积 MONEY , --5月份存货签约面积
              May新货认购面积 MONEY , --5月份新货认购面积
              May存货签约面积 MONEY , --5月份存货签约面积
              May新货去化率 MONEY , --5月份新货去化率
              May存货去化率 MONEY , --5月份存货去化率
              May综合去化率 MONEY , --5月份综合去化率
      
      --6月份
              Jun新货推货面积 MONEY , --6月份新货认购面积
              Jun存货推货面积 MONEY , --6月份存货签约面积
              Jun新货认购面积 MONEY , --6月份新货认购面积
              Jun存货签约面积 MONEY , --6月份存货签约面积   
              Jun新货去化率 MONEY , --6月份新货去化率
              Jun存货去化率 MONEY , --6月份存货去化率
              Jun综合去化率 MONEY , --6月份综合去化率
      
      --7月份
              July新货推货面积 MONEY , --7月份新货认购面积
              July存货推货面积 MONEY , --7月份存货签约面积
              July新货认购面积 MONEY , --7月份新货认购面积
              July存货签约面积 MONEY , --7月份存货签约面积
              July新货去化率 MONEY , --7月份新货去化率
              July存货去化率 MONEY , --7月份存货去化率
              July综合去化率 MONEY , --7月份综合去化率
      
      --8月份
              Aug新货推货面积 MONEY , --8月份新货认购面积
              Aug存货推货面积 MONEY , --8月份存货签约面积
              Aug新货认购面积 MONEY , --8月份新货认购面积
              Aug存货签约面积 MONEY , --8月份存货签约面积
              Aug新货去化率 MONEY , --8月份新货去化率
              Aug存货去化率 MONEY , --8月份存货去化率
              Aug综合去化率 MONEY , --8月份综合去化率
      
      --9月份
              Sep新货推货面积 MONEY , --9月份新货认购面积
              Sep存货推货面积 MONEY , --9月份存货签约面积
              Sep新货认购面积 MONEY , --9月份新货认购面积
              Sep存货签约面积 MONEY , --9月份存货签约面积
              Sep新货去化率 MONEY , --9月份新货去化率
              Sep存货去化率 MONEY , --9月份存货去化率
              Sep综合去化率 MONEY , --9月份综合去化率
      
      --10月份
              Oct新货推货面积 MONEY , --10月份新货认购面积
              Oct存货推货面积 MONEY , --10月份存货签约面积
              Oct新货认购面积 MONEY , --10月份新货认购面积
              Oct存货签约面积 MONEY , --10月份存货签约面积
              Oct新货去化率 MONEY , --10月份新货去化率
              Oct存货去化率 MONEY , --10月份存货去化率
              Oct综合去化率 MONEY , --10月份综合去化率
      
      --11月份
              Nov新货推货面积 MONEY , --11月份新货认购面积
              Nov存货推货面积 MONEY , --11月份存货签约面积
              Nov新货认购面积 MONEY , --11月份新货认购面积
              Nov存货签约面积 MONEY , --11月份存货签约面积
              Nov新货去化率 MONEY , --11月份新货去化率
              Nov存货去化率 MONEY , --11月份存货去化率
              Nov综合去化率 MONEY , --11月份综合去化率
      
      --12月份
              Dec新货推货面积 MONEY , --12月份新货认购面积
              Dec存货推货面积 MONEY , --12月份存货签约面积
              Dec新货认购面积 MONEY , --12月份新货认购面积
              Dec存货签约面积 MONEY , --12月份存货签约面积
              Dec新货去化率 MONEY , --12月份新货去化率
              Dec存货去化率 MONEY , --12月份存货去化率
              Dec综合去化率 MONEY , --12月份综合去化率
              本年新货推货面积 MONEY ,
              本年存货推货面积 MONEY ,
              本年新货认购面积 MONEY ,
              本年存货签约面积 MONEY ,
              本年新货去化率 MONEY ,
              本年存货去化率 MONEY ,
              本年综合去化率 MONEY ,
       
      --本年的新货去化率 :取销售系统放盘时间在本年范围内，放盘房源的本年成交面积/放盘房源的总面积
      --本年的存货去化率 存货本年销售去化率：取销售系统放盘时间在本年范围前，放盘房源的本年成交面积/放盘房源的总面积
      
      --开盘7天转签约率（%）
              开盘7天认购转签约签约金额 MONEY ,
              开盘7天转签约率 MONEY , --认购转签约日期在认购日期7天之内，7天内认购转签约的占当年认购额的比例
              已认购未签约金额 MONEY ,
              已签约未回款金额 MONEY
            );

---计算特殊项目业绩 项目级
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#tsProjSaleAmount')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #tsProjSaleAmount;
            END;   
            
        SELECT  mp.ProjGUID AS 组织架构ID ,
                s.ProjectName ,
                s.ManagementProjectGUID ,
                SUM(s.AreaTotal) AS AreaTotal , --总特殊业绩签约面积
                SUM(s.TotalAmount) AS TotalAmount , --总特殊业绩签约金额
                SUM(CASE WHEN DATEDIFF(yy, ISNULL(s.RdDate, s.CreationTime),
                                       GETDATE()) = 0 THEN ts.huilongjiner
                         ELSE 0
                    END) AS bnhkAmount ,--本年特殊业绩回笼金额
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(s.RdDate, s.CreationTime),
                                       GETDATE()) = 0 THEN ts.huilongjiner
                         ELSE 0
                    END) AS byhkAmount ,--本月特殊业绩回笼金额
                SUM(CASE WHEN mp.BbWay = '我司并表'
                              AND DATEDIFF(yy,
                                           ISNULL(s.RdDate, s.CreationTime),
                                           GETDATE()) = 0 THEN ts.huilongjiner
                         ELSE 0
                    END) AS bnhkbbAmount ,
                SUM(CASE WHEN DATEDIFF(yy, ISNULL(s.RdDate, s.CreationTime),
                                       GETDATE()) = 0
                         THEN ISNULL(ts.huilongjiner, 0)
                              * ISNULL(mp.EquityRatio, 1) / 100
                         ELSE 0
                    END) AS bnhkqyAmount , --权益口径
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(s.RdDate, s.CreationTime),
                                       GETDATE()) = 0
                         THEN ISNULL(ts.huilongjiner, 0)
                              * ISNULL(mp.EquityRatio, 1) / 100
                         ELSE 0
                    END) AS byhkqyAmount ,
                SUM(CASE WHEN mp.BbWay = '我司并表'
                              AND DATEDIFF(mm,
                                           ISNULL(s.RdDate, s.CreationTime),
                                           GETDATE()) = 0 THEN ts.huilongjiner
                         ELSE 0
                    END) AS byhkbbAmount
        INTO    #tsProjSaleAmount
        FROM    S_PerformanceAppraisal AS s
                LEFT JOIN mdm_Project mp ON mp.ProjGUID = s.ManagementProjectGUID
               -- LEFT JOIN ydkb_ts_ztProjData ts ON ts.ProjGUID = mp.ProjGUID
                LEFT JOIN ( SELECT  v.SaleGUID ,
                                    SUM(ISNULL(g.RmbAmount, 0)) / 10000 AS huilongjiner
                            FROM    dbo.s_Voucher v
                                    INNER JOIN dbo.s_Getin g ON g.VouchGUID = v.VouchGUID
                            WHERE   g.SaleType = '特殊业绩'
                                    AND ( v.VouchStatus IS NULL
                                          OR v.VouchStatus = ''
                                        )
                            GROUP BY v.SaleGUID
                          ) ts ON ts.SaleGUID = s.PerformanceAppraisalGUID
        WHERE   ( 1 = 1 )
                AND s.Year = YEAR(GETDATE())
        GROUP BY mp.ProjGUID ,
                s.ProjectName ,
                s.ManagementProjectGUID;

---计算特殊项目业绩 城市公司级 
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#tsCitySaleAmount')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #tsCitySaleAmount;
            END;   
            
        SELECT  bi.组织架构父级ID AS 组织架构ID ,
                --SUM(ISNULL(s.AreaTotal, 0)) AS AreaTotal ,
                --SUM(ISNULL(s.TotalAmount, 0)) AS TotalAmount ,
                --SUM(ISNULL(ts.bnhkAmount, 0)) AS bnhkAmount ,
                --SUM(ISNULL(ts.byhkAmount, 0)) AS byhkAmount ,
                --SUM(CASE WHEN mp.BbWay = '我司并表' THEN ISNULL(ts.bnhkAmount, 0)
                --         ELSE 0
                --    END) AS bnhkbbAmount ,
                --SUM(ISNULL(ts.bnhkAmount, 0) * ISNULL(mp.EquityRatio, 1) / 100) AS bnhkqyAmount ,
                --SUM(ISNULL(ts.byhkAmount, 0) * ISNULL(mp.EquityRatio, 1) / 100) AS byhkqyAmount ,
                --SUM(CASE WHEN mp.BbWay = '我司并表' THEN ts.byhkAmount
                --         ELSE 0
                --    END) AS byhkbbAmount
                SUM(s.AreaTotal) AS AreaTotal , --总特殊业绩签约面积
                SUM(s.TotalAmount) AS TotalAmount , --总特殊业绩签约金额
                SUM(CASE WHEN DATEDIFF(yy, ISNULL(s.RdDate, s.CreationTime),
                                       GETDATE()) = 0 THEN ts.huilongjiner
                         ELSE 0
                    END) AS bnhkAmount ,--本年特殊业绩回笼金额
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(s.RdDate, s.CreationTime),
                                       GETDATE()) = 0 THEN ts.huilongjiner
                         ELSE 0
                    END) AS byhkAmount ,--本月特殊业绩回笼金额
                SUM(CASE WHEN mp.BbWay = '我司并表'
                              AND DATEDIFF(yy,
                                           ISNULL(s.RdDate, s.CreationTime),
                                           GETDATE()) = 0 THEN ts.huilongjiner
                         ELSE 0
                    END) AS bnhkbbAmount ,
                SUM(CASE WHEN DATEDIFF(yy, ISNULL(s.RdDate, s.CreationTime),
                                       GETDATE()) = 0
                         THEN ISNULL(ts.huilongjiner, 0)
                              * ISNULL(mp.EquityRatio, 1) / 100
                         ELSE 0
                    END) AS bnhkqyAmount , --权益口径
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(s.RdDate, s.CreationTime),
                                       GETDATE()) = 0
                         THEN ISNULL(ts.huilongjiner, 0)
                              * ISNULL(mp.EquityRatio, 1) / 100
                         ELSE 0
                    END) AS byhkqyAmount ,
                SUM(CASE WHEN mp.BbWay = '我司并表'
                              AND DATEDIFF(mm,
                                           ISNULL(s.RdDate, s.CreationTime),
                                           GETDATE()) = 0 THEN ts.huilongjiner
                         ELSE 0
                    END) AS byhkbbAmount
        INTO    #tsCitySaleAmount
        FROM    S_PerformanceAppraisal AS s
                LEFT JOIN mdm_Project mp ON mp.ProjGUID = s.ManagementProjectGUID
                LEFT JOIN ydkb_BaseInfo bi ON bi.组织架构ID = mp.ProjGUID
               -- LEFT JOIN ydkb_ts_ztProjData ts ON ts.ProjGUID = mp.ProjGUID
                LEFT JOIN ( SELECT  v.SaleGUID ,
                                    SUM(ISNULL(g.RmbAmount, 0)) / 10000 AS huilongjiner
                            FROM    dbo.s_Voucher v
                                    INNER JOIN dbo.s_Getin g ON g.VouchGUID = v.VouchGUID
                            WHERE   g.SaleType = '特殊业绩'
                                    AND ( v.VouchStatus IS NULL
                                          OR v.VouchStatus = ''
                                        )
                            GROUP BY v.SaleGUID
                          ) ts ON ts.SaleGUID = s.PerformanceAppraisalGUID
        WHERE   bi.组织架构类型 = 3
                AND s.Year = YEAR(GETDATE())
        GROUP BY 组织架构父级ID;


/*计算回款数据临时表，计算口径同房款一览表保持一致*/
   
        --财务类实收金额取清洗数据，如果当天的数据没有清洗成功则取今天的数据，如果没有则取前一天的数据
        ---删除掉临时表
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#s_getin')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #s_getin;
            END; 
        --创建临时表
        CREATE TABLE #s_getin
            (
              BUGUID UNIQUEIDENTIFIER ,
              topprojguid UNIQUEIDENTIFIER ,
              公司名称 VARCHAR(200) ,
              销售项目名称 VARCHAR(200) ,
              应退未退本年金额 MONEY DEFAULT 0 ,
              认购累计本年金额 MONEY DEFAULT 0 ,
              签约本年回笼金额 MONEY DEFAULT 0 ,
              关闭交易本年退款金额 MONEY DEFAULT 0 ,
              本年累计回笼金额 MONEY DEFAULT 0 ,
              应退未退本月金额 MONEY DEFAULT 0 ,
              认购累计本月金额 MONEY DEFAULT 0 ,
              签约累计本月金额 MONEY DEFAULT 0 ,
              关闭交易本月退款金额 MONEY DEFAULT 0 ,
              本月累计回笼金额 MONEY DEFAULT 0 ,
              本年特殊业绩关联房间 MONEY NULL ,
              本年特殊业绩未关联房间 MONEY NULL ,
              本月特殊业绩关联房间 MONEY NULL ,
              本月特殊业绩未关联房间 MONEY NULL
            );
         
                
        IF EXISTS ( SELECT  *
                    FROM    dbo.s_gsfkylbhzb
                    WHERE   DATEDIFF(DAY, GETDATE(), qxDate) = 0 )
           
	       --插入临时表     
            INSERT  INTO #s_getin
                    SELECT  buguid ,
                            TopProjGUID ,
                            公司名称 ,
                            销售项目名称 ,
                            ISNULL(SUM(应退未退本年金额), 0) AS 应退未退本年金额 ,
                            ISNULL(SUM(本年回笼金额认购), 0) AS 认购累计本年金额 ,
                            ISNULL(SUM(本年回笼金额签约), 0) AS 签约本年回笼金额 ,
                            ISNULL(SUM(关闭交易本年退款金额), 0) AS 关闭交易本年退款金额 ,
                            SUM(ISNULL(应退未退本年金额, 0) + ISNULL(本年回笼金额认购, 0)
                                + ISNULL(本年回笼金额签约, 0) + ISNULL(关闭交易本年退款金额, 0)
                                + ISNULL(本年特殊业绩关联房间, 0) + ISNULL(本年特殊业绩未关联房间,
                                                              0)) AS 本年累计回笼金额 ,
                            ISNULL(SUM(应退未退本月金额), 0) AS 应退未退本月金额 ,
                            ISNULL(SUM(本月回笼金额认购), 0) AS 认购累计本月金额 ,
                            ISNULL(SUM(本月回笼金额签约), 0) AS 签约累计本月金额 ,
                            ISNULL(SUM(关闭交易本月退款金额), 0) AS 关闭交易本月退款金额 ,
                            SUM(ISNULL(应退未退本月金额, 0) + ISNULL(本月回笼金额认购, 0)
                                + ISNULL(本月回笼金额签约, 0) + ISNULL(关闭交易本月退款金额, 0)
                                + ISNULL(本月特殊业绩关联房间, 0) + ISNULL(本月特殊业绩未关联房间,
                                                              0)) AS 本月累计回笼金额 ,
                            ISNULL(SUM(本年特殊业绩关联房间), 0) AS 本年特殊业绩关联房间 ,
                            ISNULL(SUM(本年特殊业绩未关联房间), 0) AS 本年特殊业绩未关联房间 ,
                            ISNULL(SUM(本月特殊业绩关联房间), 0) AS 本月特殊业绩关联房间 ,
                            ISNULL(SUM(本月特殊业绩未关联房间), 0) AS 本月特殊业绩未关联房间
                    FROM    dbo.s_gsfkylbhzb
                    WHERE   --公司名称 = '华南公司' AND
                            DATEDIFF(DAY, GETDATE(), qxDate) = 0
                    GROUP BY buguid ,
                            TopProjGUID ,
                            公司名称 ,
                            销售项目名称; 
        ELSE
            INSERT  INTO #s_getin
                    SELECT  buguid ,
                            TopProjGUID ,
                            公司名称 ,
                            销售项目名称 ,
                            ISNULL(SUM(应退未退本年金额), 0) AS 应退未退本年金额 ,
                            ISNULL(SUM(本年回笼金额认购), 0) AS 认购累计本年金额 ,
                            ISNULL(SUM(本年回笼金额签约), 0) AS 签约本年回笼金额 ,
                            ISNULL(SUM(关闭交易本年退款金额), 0) AS 关闭交易本年退款金额 ,
                            SUM(ISNULL(应退未退本年金额, 0) + ISNULL(本年回笼金额认购, 0)
                                + ISNULL(本年回笼金额签约, 0) + ISNULL(关闭交易本年退款金额, 0)
                                + ISNULL(本年特殊业绩关联房间, 0) + ISNULL(本年特殊业绩未关联房间,
                                                              0)) AS 本年累计回笼金额 ,
                            ISNULL(SUM(应退未退本月金额), 0) AS 应退未退本月金额 ,
                            ISNULL(SUM(本月回笼金额认购), 0) AS 认购累计本月金额 ,
                            ISNULL(SUM(本月回笼金额签约), 0) AS 签约累计本月金额 ,
                            ISNULL(SUM(关闭交易本月退款金额), 0) AS 关闭交易本月退款金额 ,
                            SUM(ISNULL(应退未退本月金额, 0) + ISNULL(本月回笼金额认购, 0)
                                + ISNULL(本月回笼金额签约, 0) + ISNULL(关闭交易本月退款金额, 0)
                                + ISNULL(本月特殊业绩关联房间, 0) + ISNULL(本月特殊业绩未关联房间,
                                                              0)) AS 本月累计回笼金额 ,
                            ISNULL(SUM(本年特殊业绩关联房间), 0) AS 本年特殊业绩关联房间 ,
                            ISNULL(SUM(本年特殊业绩未关联房间), 0) AS 本年特殊业绩未关联房间 ,
                            ISNULL(SUM(本月特殊业绩关联房间), 0) AS 本月特殊业绩关联房间 ,
                            ISNULL(SUM(本月特殊业绩未关联房间), 0) AS 本月特殊业绩未关联房间
                    FROM    dbo.s_gsfkylbhzb
                    WHERE   --公司名称 = '华南公司' AND
                            DATEDIFF(DAY, GETDATE(), qxDate) = -1
                    GROUP BY buguid ,
                            TopProjGUID ,
                            公司名称 ,
                            销售项目名称; 
                            

        
/*
存货本月销售去化率：取销售系统放盘时间在本月范围前，放盘房源的本月成交面积/放盘房源的总面积
存货本年销售去化率：取销售系统放盘时间在本年范围前，放盘房源的本年成交面积/放盘房源的总面积
*/ 

--获取本年一级项目的销售去化情况
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ProjSaleQh')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #ProjSaleQh;
            END;  

        DECLARE @bnYear VARCHAR(4);
        SET @bnYear = CONVERT(VARCHAR(4), YEAR(GETDATE()));


        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
        --新货销售情况
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-01-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Jan新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-01-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-01-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Jan新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-02-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Feb新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-02-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-02-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Feb新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-03-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Mar新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-03-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-03-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Mar新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-04-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Apr新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-04-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-04-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Apr新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-05-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS May新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-05-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-05-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS May新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-06-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Jun新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-06-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-06-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Jun新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-07-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS July新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-07-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-07-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS July新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-08-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Aug新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-08-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-08-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Aug新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-09-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Sep新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-09-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-09-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Sep新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-10-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Oct新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-10-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-10-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Oct新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-11-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Nov新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-11-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-11-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Nov新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-12-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Dec新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-12-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-12-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Dec新货认购面积 ,
            
       --存货销售情况     
                SUM(CASE WHEN r.ThDate < @bnYear + '-01-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-01-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Jan存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-01-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-01-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Jan存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-02-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-02-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Feb存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-02-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-02-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Feb存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-03-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-03-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Mar存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-03-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-03-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Mar存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-04-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-04-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Apr存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-04-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-04-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Apr存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-05-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-05-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS May存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-05-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-05-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS May存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-06-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-06-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Jun存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-06-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-06-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Jun存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-07-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-07-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS July存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-07-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-07-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS July存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-08-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-08-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Aug存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-08-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-08-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Aug存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-09-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-09-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN ord.BldArea
                         ELSE 0
                    END) AS Sep存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-09-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-09-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Sep存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-10-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-10-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Oct存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-10-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-10-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Oct存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-11-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-11-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Nov存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-11-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-11-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Nov存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-12-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-12-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Dec存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-12-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-12-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Dec存货签约面积 ,
                
                ------------------------------------------------------------------
                SUM(CASE WHEN DATEDIFF(yy, r.ThDate, @bnYear + '-01-01') = 0
                         THEN r.BldArea
                         ELSE 0
                    END) AS 本年新货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-01-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(yy,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  GETDATE()) = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS 本年存货推货面积 ,
                SUM(CASE WHEN DATEDIFF(yy, r.ThDate, @bnYear + '-01-01') = 0
                              AND DATEDIFF(yy, ord.rgDate, r.ThDate) = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS 本年新货认购面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-01-01'
                              AND DATEDIFF(mm, ord.qyDate, r.ThDate) <> 0
                              AND DATEDIFF(yy, ord.qyDate, GETDATE()) = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS 本年存货签约面积
        INTO    #ProjSaleQh
        FROM    erp25.dbo.p_room r
                LEFT JOIN ( SELECT  ProjGUID ,
                                    RoomGUID ,
                                    '认购' AS SaleType ,
                                    BldArea ,
                                    QSDate AS rgDate ,
                                    NULL AS qyDate
                            FROM    dbo.s_Order
                            WHERE   Status = '激活'
                                    AND OrderType = '认购'
                            UNION
                            SELECT  c.ProjGUID ,
                                    c.RoomGUID ,
                                    '签约' AS SaleType ,
                                    o.BldArea ,
                                    o.QSDate AS rgDate ,
                                    c.QSDate AS qyDate
                            FROM    dbo.s_Contract c
                                    LEFT JOIN dbo.s_Order o ON c.TradeGUID = o.TradeGUID
                            WHERE   ( c.Status = '激活'
                                      OR ( o.Status = '关闭'
                                           AND o.CloseReason = '转签约'
                                           AND c.Status = '激活'
                                         )
                                    )
                          ) ord ON ord.RoomGUID = r.RoomGUID
                LEFT JOIN erp25.dbo.p_Project p ON p.ProjGUID = r.ProjGUID
                LEFT JOIN erp25.dbo.p_Project p1 ON p1.ProjCode = p.ParentCode
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON p1.ProjGUID = bi.组织架构ID
        WHERE   r.IsVirtualRoom = 0
                AND r.isAnnexe = 0
                AND bi.组织架构类型 = 3
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型; 
 
        
--获取本年城市公司的销售去化情况
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#CitySaleQh')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #CitySaleQh;
            END;  

        SELECT  bi2.组织架构ID ,
                bi2.组织架构名称 ,
                bi2.组织架构编码 ,
                bi2.组织架构类型 ,
                --新货销售情况
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-01-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Jan新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-01-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-01-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Jan新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-02-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Feb新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-02-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-02-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Feb新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-03-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Mar新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-03-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-03-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Mar新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-04-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Apr新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-04-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-04-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Apr新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-05-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS May新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-05-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-05-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS May新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-06-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Jun新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-06-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-06-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Jun新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-07-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS July新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-07-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-07-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS July新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-08-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Aug新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-08-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-08-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Aug新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-09-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Sep新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-09-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-09-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Sep新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-10-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Oct新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-10-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-10-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Oct新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-11-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Nov新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-11-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-11-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Nov新货认购面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-12-01') = 0
                              AND r.ThDate <= GETDATE() THEN r.BldArea
                         ELSE 0
                    END) AS Dec新货推货面积 ,
                SUM(CASE WHEN DATEDIFF(mm, r.ThDate, @bnYear + '-12-01') = 0
                              AND r.ThDate <= GETDATE()
                              AND DATEDIFF(mm, ord.rgDate, @bnYear + '-12-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Dec新货认购面积 ,
              --存货销售情况     
                SUM(CASE WHEN r.ThDate < @bnYear + '-01-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-01-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Jan存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-01-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-01-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Jan存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-02-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-02-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Feb存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-02-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-02-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Feb存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-03-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-03-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Mar存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-03-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-03-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Mar存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-04-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-04-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Apr存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-04-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-04-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Apr存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-05-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-05-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS May存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-05-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-05-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS May存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-06-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-06-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Jun存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-06-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-06-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Jun存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-07-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-07-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS July存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-07-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-07-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS July存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-08-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-08-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Aug存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-08-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-08-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Aug存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-09-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-09-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN ord.BldArea
                         ELSE 0
                    END) AS Sep存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-09-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-09-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Sep存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-10-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-10-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Oct存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-10-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-10-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Oct存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-11-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-11-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Nov存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-11-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-11-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Nov存货签约面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-12-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(mm,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  @bnYear + '-12-01') = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS Dec存货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-12-01'
                              AND DATEDIFF(mm, ord.qyDate, @bnYear + '-12-01') = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS Dec存货签约面积 ,
                
                ------------------------------------------------------------------
                SUM(CASE WHEN DATEDIFF(yy, r.ThDate, @bnYear + '-01-01') = 0
                         THEN r.BldArea
                         ELSE 0
                    END) AS 本年新货推货面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-01-01'
                              AND ( r.Status IN ( '待售', '预约', '销控' )
                                    OR ( DATEDIFF(yy,
                                                  ISNULL(ord.qyDate,
                                                         ord.rgDate),
                                                  GETDATE()) = 0
                                         AND r.Status IN ( '认购', '签约' )
                                       )
                                  ) THEN r.BldArea
                         ELSE 0
                    END) AS 本年存货推货面积 ,
                SUM(CASE WHEN DATEDIFF(yy, r.ThDate, @bnYear + '-01-01') = 0
                              AND DATEDIFF(yy, ord.rgDate, r.ThDate) = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS 本年新货认购面积 ,
                SUM(CASE WHEN r.ThDate < @bnYear + '-01-01'
                              AND DATEDIFF(mm, ord.qyDate, r.ThDate) <> 0
                              AND DATEDIFF(yy, ord.qyDate, GETDATE()) = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS 本年存货签约面积
        INTO    #CitySaleQh
        FROM    erp25.dbo.p_room r
                LEFT JOIN ( SELECT  ProjGUID ,
                                    RoomGUID ,
                                    '认购' AS SaleType ,
                                    BldArea ,
                                    QSDate AS rgDate ,
                                    NULL AS qyDate
                            FROM    dbo.s_Order
                            WHERE   Status = '激活'
                                    AND OrderType = '认购'
                            UNION
                            SELECT  c.ProjGUID ,
                                    c.RoomGUID ,
                                    '签约' AS SaleType ,
                                    o.BldArea ,
                                    o.QSDate AS rgDate ,
                                    c.QSDate AS qyDate
                            FROM    dbo.s_Contract c
                                    LEFT JOIN dbo.s_Order o ON c.TradeGUID = o.TradeGUID
                            WHERE   ( c.Status = '激活'
                                      OR ( o.Status = '关闭'
                                           AND o.CloseReason = '转签约'
                                           AND c.Status = '激活'
                                         )
                                    )
                          ) ord ON ord.RoomGUID = r.RoomGUID
                LEFT JOIN erp25.dbo.p_Project p ON p.ProjGUID = r.ProjGUID
                LEFT JOIN erp25.dbo.p_Project p1 ON p1.ProjCode = p.ParentCode
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON p1.ProjGUID = bi.组织架构ID
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi2 ON bi2.组织架构ID = bi.组织架构父级ID
        WHERE   r.IsVirtualRoom = 0
                AND r.isAnnexe = 0
                AND bi.组织架构类型 = 3
        GROUP BY bi2.组织架构ID ,
                bi2.组织架构名称 ,
                bi2.组织架构编码 ,
                bi2.组织架构类型; 


--获取本年平台公司的销售去化情况
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#CompanySaleQh')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #CompanySaleQh;
            END;  

        SELECT  bi2.组织架构ID ,
                bi2.组织架构名称 ,
                bi2.组织架构编码 ,
                bi2.组织架构类型 ,
        --新货销售情况
                SUM(Jan新货推货面积) AS Jan新货推货面积 ,
                SUM(Jan新货认购面积) AS Jan新货认购面积 ,
                SUM(Feb新货推货面积) AS Feb新货推货面积 ,
                SUM(Feb新货认购面积) AS Feb新货认购面积 ,
                SUM(Mar新货推货面积) AS Mar新货推货面积 ,
                SUM(Mar新货认购面积) AS Mar新货认购面积 ,
                SUM(Apr新货推货面积) AS Apr新货推货面积 ,
                SUM(Apr新货认购面积) AS Apr新货认购面积 ,
                SUM(May新货推货面积) AS May新货推货面积 ,
                SUM(May新货认购面积) AS May新货认购面积 ,
                SUM(Jun新货推货面积) AS Jun新货推货面积 ,
                SUM(Jun新货认购面积) AS Jun新货认购面积 ,
                SUM(July新货推货面积) AS July新货推货面积 ,
                SUM(July新货认购面积) AS July新货认购面积 ,
                SUM(Aug新货推货面积) AS Aug新货推货面积 ,
                SUM(Aug新货认购面积) AS Aug新货认购面积 ,
                SUM(Sep新货推货面积) AS Sep新货推货面积 ,
                SUM(Sep新货认购面积) AS Sep新货认购面积 ,
                SUM(Oct新货推货面积) AS Oct新货推货面积 ,
                SUM(Oct新货认购面积) AS Oct新货认购面积 ,
                SUM(Nov新货推货面积) AS Nov新货推货面积 ,
                SUM(Nov新货认购面积) AS Nov新货认购面积 ,
                SUM(Dec新货推货面积) AS Dec新货推货面积 ,
                SUM(Dec新货认购面积) AS Dec新货认购面积 ,
            
       --存货销售情况     
                SUM(Jan存货推货面积) AS Jan存货推货面积 ,
                SUM(Jan存货签约面积) AS Jan存货签约面积 ,
                SUM(Feb存货推货面积) AS Feb存货推货面积 ,
                SUM(Feb存货签约面积) AS Feb存货签约面积 ,
                SUM(Mar存货推货面积) AS Mar存货推货面积 ,
                SUM(Mar存货签约面积) AS Mar存货签约面积 ,
                SUM(Apr存货推货面积) AS Apr存货推货面积 ,
                SUM(Apr存货签约面积) AS Apr存货签约面积 ,
                SUM(May存货推货面积) AS May存货推货面积 ,
                SUM(May存货签约面积) AS May存货签约面积 ,
                SUM(Jun存货推货面积) AS Jun存货推货面积 ,
                SUM(Jun存货签约面积) AS Jun存货签约面积 ,
                SUM(July存货推货面积) AS July存货推货面积 ,
                SUM(July存货签约面积) AS July存货签约面积 ,
                SUM(Aug存货推货面积) AS Aug存货推货面积 ,
                SUM(Aug存货签约面积) AS Aug存货签约面积 ,
                SUM(Sep存货推货面积) AS Sep存货推货面积 ,
                SUM(Sep存货签约面积) AS Sep存货签约面积 ,
                SUM(Oct存货推货面积) AS Oct存货推货面积 ,
                SUM(Oct存货签约面积) AS Oct存货签约面积 ,
                SUM(Nov存货推货面积) AS Nov存货推货面积 ,
                SUM(Nov存货签约面积) AS Nov存货签约面积 ,
                SUM(Dec存货推货面积) AS Dec存货推货面积 ,
                SUM(Dec存货签约面积) AS Dec存货签约面积 ,
                
                --------------------------------------------------------------------
                SUM(本年新货推货面积) AS 本年新货推货面积 ,
                SUM(本年存货推货面积) AS 本年存货推货面积 ,
                SUM(本年新货认购面积) AS 本年新货认购面积 ,
                SUM(本年存货签约面积) AS 本年存货签约面积
        INTO    #CompanySaleQh
        FROM    #CitySaleQh cs
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON cs.组织架构ID = bi.组织架构ID
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi2 ON bi2.组织架构ID = bi.组织架构父级ID
        WHERE   bi2.组织架构类型 = 1
        GROUP BY bi2.组织架构ID ,
                bi2.组织架构名称 ,
                bi2.组织架构编码 ,
                bi2.组织架构类型; 




    
/*插入城市公司任务数据*/    
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ydTask')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #ydTask;
            END; 

--获取月度任务，城市公司月度任务和签约任务数据用项目任务那里汇总，并且要求剔除万科里水、万科F06、金茂绿岛湖、高明美的 四个非操盘项目；
--产成品任务，采用系统临时表导入数据的方式执行
--B3363602-A589-E811-80BF-E61F13C57837	70DD6DF4-47F7-46AF-B470-BC18EE57D8FF	nh.0757039(s)	佛山里水沙涌地块
--C1D24E44-A589-E811-80BF-E61F13C57837	70DD6DF4-47F7-46AF-B470-BC18EE57D8FF	nh.0757039(s).01	佛山里水沙涌地块-一期

--31783072-6849-E811-80BA-E61F13C57837	70DD6DF4-47F7-46AF-B470-BC18EE57D8FF	nh.0757042(s)	佛山绿岛湖临湖六地块
--AB4DDE00-6949-E811-80BA-E61F13C57837	70DD6DF4-47F7-46AF-B470-BC18EE57D8FF	nh.0757042(s).01	佛山绿岛湖临湖六地块-一期

--CACA1201-F746-E811-80BA-E61F13C57837	70DD6DF4-47F7-46AF-B470-BC18EE57D8FF	nh.0757027(s)	佛山商务区F06项目
--B3C6BEC8-F846-E811-80BA-E61F13C57837	70DD6DF4-47F7-46AF-B470-BC18EE57D8FF	nh.0757027(s).01	佛山商务区F06项目-一期

--445AD138-A747-E811-80BA-E61F13C57837	70DD6DF4-47F7-46AF-B470-BC18EE57D8FF	nh.0757057(s)	美的明湖北湾二期
--03F9E60A-B675-E811-80BF-E61F13C57837	70DD6DF4-47F7-46AF-B470-BC18EE57D8FF	nh.0757057(s).001	美的明湖北湾二期-一期
        SELECT  bi2.组织架构ID ,
                bi2.组织架构名称 ,
                bi2.组织架构编码 ,
                bi2.组织架构类型 ,
                SUM(s.RgTask) AS 本月销售任务 ,
                SUM(CASE WHEN mp.TradersWay <> '合作方操盘' THEN s.RgTask
                         ELSE 0
                    END) AS 本月操盘销售任务 ,
                SUM(s.SigningTask) 本月签约任务 ,
                SUM(CASE WHEN mp.TradersWay <> '合作方操盘' THEN s.SigningTask
                         ELSE 0
                    END) AS 本月操盘签约任务 ,
                SUM(s.PaymentTask) 本月回笼任务 ,
                SUM(CASE WHEN mp.TradersWay <> '合作方操盘' THEN s.PaymentTask
                         ELSE 0
                    END) AS 本月操盘回笼任务 ,
                0 AS 本月成本直投任务 ,
                SUM(ccp.[本月份产成品任务]) * 10000 AS 本月产成品任务 --转换为亿元
        INTO    #ydTask
        FROM    erp25.dbo.ydkb_BaseInfo bi
                LEFT JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = bi.组织架构ID
                LEFT JOIN erp25.dbo.s_SaleProjectTaskList s ON bi.组织架构ID = s.ProjectGUID
                LEFT JOIN erp25.dbo.s_SaleProjectTask t ON s.ProjectTaskGUID = t.ProjectTaskGUID
                LEFT JOIN ydkb_BaseInfo bi2 ON bi2.组织架构ID = bi.组织架构父级ID
                LEFT JOIN erp25.dbo.ykdb_hn_ccpTask ccp ON ccp.项目GUID = bi.组织架构ID
        WHERE   bi.组织架构类型 = 3 --t.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' AND
                AND t.Syear = YEAR(GETDATE())
                AND t.Smonth = MONTH(GETDATE())
                AND t.TaskPUnit = '月度'
                --AND mp.TradersWay <> '合作方操盘'
                --AND mp.ProjGUID NOT IN (
                --'7081EF46-2814-E711-80BA-E61F13C57837',
                --'31783072-6849-E811-80BA-E61F13C57837',
                --'CACA1201-F746-E811-80BA-E61F13C57837',
                --'445AD138-A747-E811-80BA-E61F13C57837',
                --'B3363602-A589-E811-80BF-E61F13C57837' )
        GROUP BY bi2.组织架构ID ,
                bi2.组织架构名称 ,
                bi2.组织架构编码 ,
                bi2.组织架构类型; 
                

--获取季度任务，直投任务案场季度录入，实际系统录入是按照月份录入的，1-4个月就是对应的4个季度的直投任务数据
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#jdTask')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #jdTask;
            END; 
            
            
        SELECT  t1.组织架构ID ,
                t1.组织架构名称 ,
                t1.组织架构编码 ,
                t1.组织架构类型 ,
                --华南公司的是按照月度录入的直投任务，1-4月份对应的是1-4个季度的任务
                SUM(CASE WHEN t1.Smonth = DATEPART(QUARTER, GETDATE())
                         THEN 成本直投任务
                         ELSE 0
                    END) AS 本季度成本直投任务
                --SUM(CASE WHEN DATEDIFF(qq, t1.ztTaskDate, GETDATE()) = 0
                --         THEN 成本直投任务
                --         ELSE 0
                --    END) AS 本季度成本直投任务
        INTO    #jdTask
        FROM    ( SELECT    bi.组织架构ID ,
                            bi.组织架构名称 ,
                            bi.组织架构编码 ,
                            bi.组织架构类型 ,
                            s.CbztTask 成本直投任务 ,
                            t.Syear ,
                            t.Smonth
                            --CONVERT(VARCHAR(10), t.Syear) + '-'
                            --+ CONVERT(VARCHAR(2), t.Smonth) + '-01' AS ztTaskDate
                  FROM      erp25.dbo.s_SaleCityTaskList s
                            LEFT JOIN erp25.dbo.s_SaleCityTask t ON s.CityTaskGUID = t.CityTaskGUID
                            LEFT JOIN ( SELECT  ParamGUID ,
                                                ParamValue
                                        FROM    erp25.dbo.myBizParamOption
                                        WHERE   ParamName = 'mdm_XMSSCSGS'
                                      ) city ON city.ParamGUID = s.CityCompanyGUID
                            LEFT JOIN erp25.dbo.companyjoin cp ON cp.buguid = t.BUGUID
                            INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON bi.组织架构类型 = 2
                                                              AND bi.平台公司GUID = cp.DevelopmentCompanyGUID
                                                              AND bi.组织架构名称 = city.ParamValue
                  WHERE     t.Syear = YEAR(GETDATE())
                            AND t.TaskPUnit = '月度'
                ) t1
        GROUP BY t1.组织架构ID ,
                t1.组织架构名称 ,
                t1.组织架构类型 ,
                t1.组织架构编码;
        
--获取年度任务
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ndTask')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #ndTask;
            END; 

        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                s.RgTask AS 本年销售任务 ,
                s.SigningTask AS 本年签约任务 ,
                s.PaymentTask 本年回笼任务 ,
                s.CbztTask 本年成本直投任务 ,
                cpp.年产成品任务 AS 本年产成品任务
        INTO    #ndTask
        FROM    erp25.dbo.s_SaleCityTaskList s
                LEFT JOIN erp25.dbo.s_SaleCityTask t ON s.CityTaskGUID = t.CityTaskGUID
                LEFT JOIN ( SELECT  ParamGUID ,
                                    ParamValue
                            FROM    erp25.dbo.myBizParamOption
                            WHERE   ParamName = 'mdm_XMSSCSGS'
                          ) city ON city.ParamGUID = s.CityCompanyGUID
                LEFT JOIN erp25.dbo.companyjoin cp ON cp.buguid = t.BUGUID
                INNER  JOIN erp25.dbo.ydkb_BaseInfo bi ON bi.组织架构类型 = 2
                                                          AND bi.平台公司GUID = cp.DevelopmentCompanyGUID
                                                          AND bi.组织架构名称 = city.ParamValue
                LEFT  JOIN ( SELECT b2.组织架构ID ,
                                    SUM(ccp.年度产成品任务) * 10000 AS 年产成品任务
                             FROM   erp25.dbo.ykdb_hn_ccpTask ccp
                                    LEFT JOIN erp25.dbo.ydkb_BaseInfo b ON ccp.项目GUID = b.组织架构ID
                                    LEFT JOIN erp25.dbo.ydkb_BaseInfo b2 ON b2.组织架构ID = b.组织架构父级ID
                             WHERE  b.组织架构类型 = 3
                             GROUP BY b2.组织架构ID
                           ) cpp ON cpp.组织架构ID = bi.组织架构ID
        WHERE   t.Syear = YEAR(GETDATE())
                AND t.TaskPUnit = '年度';
        
 
 

---实际成本直投完成情况
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#PayAmount')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #PayAmount;
            END; 
         
        SELECT  bi2.组织架构ID ,
                bi2.组织架构名称 ,
                bi2.组织架构编码 ,
                bi2.组织架构类型 ,
                ISNULL(SUM(pay.本月实付金额), 0) AS 本月实付金额 ,
                ISNULL(SUM(pay.本季度实付金额), 0) AS 本季度实付金额 ,
                ISNULL(SUM(pay.本年实付金额), 0) + ISNULL(SUM(ts.bnZtAmount), 0) AS 本年实付金额
        INTO    #PayAmount
        FROM    erp25.dbo.ydkb_BaseInfo bi
                LEFT JOIN ( SELECT  a.ProjGUID ,
                                    SUM(CASE WHEN DATEDIFF(mm, a.PayDate,
                                                           GETDATE()) = 0
                                             THEN a.pj
                                             ELSE 0
                                        END) / 10000 AS '本月实付金额' ,
                                    SUM(CASE WHEN DATEDIFF(qq, a.PayDate,
                                                           GETDATE()) = 0
                                             THEN a.pj
                                             ELSE 0
                                        END) / 10000 AS '本季度实付金额' ,
                                    SUM(a.pj) / 10000 AS '本年实付金额'
                            FROM    ( SELECT    p.BUGUID ,
                                                pp.ProjGUID ,
                                                p.PayDate ,
                                                p.PayAmount ,
                                                pj.ts ,
                                                p.PayAmount / pj.ts pj
                                      FROM      myCost_erp352.dbo.cb_Pay p
                                                LEFT JOIN myCost_erp352.dbo.vcb_Contract c ON c.ContractGUID = p.ContractGUID
                                                LEFT JOIN myCost_erp352.dbo.cb_ContractProj cb ON p.ContractGUID = cb.ContractGUID
                                                LEFT JOIN ( SELECT
                                                              ContractGUID ,
                                                              COUNT(1) ts
                                                            FROM
                                                              myCost_erp352.dbo.cb_ContractProj
                                                            GROUP BY ContractGUID
                                                          ) pj ON p.ContractGUID = pj.ContractGUID
                                                LEFT JOIN myCost_erp352.dbo.p_Project p1 ON p1.ProjGUID = cb.ProjGUID
                                                LEFT JOIN myCost_erp352.dbo.p_Project pp ON pp.ProjCode = p1.ParentCode
                                      WHERE     YEAR(p.PayDate) = YEAR(GETDATE())
                                                AND c.HtTypeName NOT LIKE '%管理%'
                                                AND c.HtTypeName NOT LIKE '%营销%'
                                                AND c.HtTypeName NOT LIKE '%财务%'
                                                AND c.HtTypeName NOT LIKE '%土地%'
                                    ) a
                            GROUP BY a.ProjGUID
                          ) pay ON pay.ProjGUID = bi.组织架构ID
                LEFT  JOIN ydkb_ts_ztProjData ts ON ts.ProjGUID = bi.组织架构ID --增加特殊直投金额录入
                INNER JOIN ydkb_BaseInfo bi2 ON bi2.组织架构ID = bi.组织架构父级ID
        WHERE   bi2.组织架构类型 = 2
        GROUP BY bi2.组织架构ID ,
                bi2.组织架构名称 ,
                bi2.组织架构编码 ,
                bi2.组织架构类型;   

--销售完成情况 城市公司统计 不含非操盘项目
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#SaleAmount')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #SaleAmount;
            END; 

        SELECT  bi2.组织架构ID ,
                bi2.组织架构名称 ,
                bi2.组织架构编码 ,
                bi2.组织架构类型 ,
                SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                              AND DATEDIFF(mm, ord.rgDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本月销售金额 ,
                SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                              AND mp.TradersWay <> '合作方操盘'
                              AND DATEDIFF(mm, ord.rgDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本月操盘销售金额 ,
                SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                              AND DATEDIFF(yy, ord.rgDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本年销售金额 ,
                SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                              AND DATEDIFF(yy, ord.rgDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END * ( ISNULL(lbp.LbProjectValue, 0) / 100.00 )) / 10000 AS 本年销售金额权益口径 ,
                SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                              AND DATEDIFF(yy, ord.rgDate, GETDATE()) = 0
                              AND mp.BbWay = '我司并表'
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本年销售金额并表口径 ,
                SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                              AND mp.TradersWay <> '合作方操盘'
                              AND DATEDIFF(yy, ord.rgDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本年操盘销售金额 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND DATEDIFF(mm, ord.QSDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本月签约金额 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND mp.TradersWay <> '合作方操盘'
                              AND DATEDIFF(mm, ord.QSDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本月操盘签约金额 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND DATEDIFF(yy, ord.QSDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本年签约金额 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND DATEDIFF(yy, ord.QSDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END * ( ISNULL(lbp.LbProjectValue, 0) / 100.00 )) / 10000 AS 本年签约金额权益口径 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND DATEDIFF(yy, ord.QSDate, GETDATE()) = 0
                              AND mp.BbWay = '我司并表'
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本年签约金额并表口径 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND mp.TradersWay <> '合作方操盘'
                              AND DATEDIFF(yy, ord.QSDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本年操盘签约金额 ,
                convert(MONEY,0) AS 本月回款金额 ,
                convert(MONEY,0) AS 本月操盘回款金额 ,
                convert(MONEY,0) AS 本月回款金额权益口径 ,
                convert(MONEY,0) AS 本月回款金额并表口径 ,
                convert(MONEY,0) AS 本年回款金额 ,
                convert(MONEY,0) AS 本年操盘回款金额 ,
                convert(MONEY,0) AS 本年回款金额权益口径 ,
                convert(MONEY,0) AS 本年回款金额并表口径 ,  
                           
        --开盘7天转签约率（%）认购转签约日期在认购日期7天之内，7天内认购转签约的金额占当年认购额的比例
                SUM(CASE WHEN ord.saleType = '签约'
                              AND ord.QSDate BETWEEN ord.rgDate
                                             AND     DATEADD(DAY, 7,
                                                             ord.rgDate)
                              AND DATEDIFF(yy, ord.rgDate, GETDATE()) = 0
                         THEN ord.JyTotal
                         ELSE 0
                    END) / 10000 AS 开盘7天认购转签约签约金额 ,
                CASE WHEN ISNULL(SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                                               AND DATEDIFF(yy, ord.rgDate,
                                                            GETDATE()) = 0
                                          THEN ISNULL(ord.JyTotal, 0)
                                          ELSE 0
                                     END), 0) = 0 THEN 0
                     ELSE SUM(CASE WHEN ord.saleType = '签约'
                                        AND ord.QSDate BETWEEN ord.rgDate
                                                       AND    DATEADD(DAY, 7,
                                                              ord.rgDate)
                                        AND DATEDIFF(yy, ord.rgDate, GETDATE()) = 0
                                   THEN ord.JyTotal
                                   ELSE 0
                              END)
                          / SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                                          AND DATEDIFF(yy, ord.rgDate,
                                                       GETDATE()) = 0
                                     THEN ISNULL(ord.JyTotal, 0)
                                     ELSE 0
                                END)
                END AS 开盘7天转签约率 ,
                SUM(CASE WHEN ord.saleType = '认购'
                              AND ord.rgDate <= GETDATE() THEN ord.JyTotal
                         ELSE 0
                    END) / 10000 AS 已认购未签约金额 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND ord.QSDate <= GETDATE()
                              AND ISNULL(g.sstotal, 0) < ISNULL(f.ystotal, 0)
                         THEN f.RmbYe
                         ELSE 0
                    END) / 10000 AS 已签约未回款金额
        INTO    #SaleAmount
        FROM    ( SELECT    BUGUID ,
                            ProjGUID ,
                            '认购' AS saleType ,
                            TradeGUID ,
                            BldArea ,
                            JyTotal ,
                            NULL AS QSDate ,
                            QSDate AS rgDate
                  FROM      erp25.dbo.s_Order
                  WHERE     Status = '激活'
                            AND OrderType = '认购'
                  UNION ALL
                  SELECT    c.BUGUID ,
                            c.ProjGUID ,
                            '签约' AS saleType ,
                            c.TradeGUID ,
                            o.BldArea ,
                            c.JyTotal ,
                            c.QSDate ,
                            o.QSDate AS rgDate
                  FROM      erp25.dbo.s_Contract c
                            LEFT JOIN erp25.dbo.s_Order o ON c.TradeGUID = o.TradeGUID
                                                             AND o.Status = '关闭'
                                                             AND o.CloseReason = '转签约'
                  WHERE     c.Status = '激活'
                ) ord
                LEFT JOIN erp25..p_Project p ON p.ProjGUID = ord.ProjGUID
                LEFT JOIN erp25..p_Project p1 ON p1.ProjCode = p.ParentCode
                                                 AND p1.Level = 2
                LEFT  JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = p1.ProjGUID
                LEFT JOIN ( SELECT  projGUID ,
                                    MAX(LbProjectValue) AS LbProjectValue
                            FROM    mdm_LbProject
                            WHERE   LbProject = 'cwsybl'
                            GROUP BY projGUID
                          ) lbp ON lbp.projGUID = mp.ProjGUID
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON p1.ProjGUID = bi.组织架构ID
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi2 ON bi2.组织架构ID = bi.组织架构父级ID
                LEFT JOIN ( SELECT  TradeGUID ,
                                    SUM(RmbAmount) ystotal ,
                                    SUM(RmbYe) AS RmbYe
                            FROM    s_Fee
                            WHERE   ItemType LIKE '%房款%'
                            GROUP BY TradeGUID
                          ) f ON f.TradeGUID = ord.TradeGUID
                LEFT JOIN ( SELECT  SaleGUID ,
                                    SUM(RmbAmount) sstotal
                            FROM    s_Getin
                            WHERE   ItemType LIKE '%房款%'
                                    AND ISNULL(Status, '') <> '作废'
                            GROUP BY SaleGUID
                          ) g ON g.SaleGUID = ord.TradeGUID
        WHERE   p1.Level = 2
                AND bi.组织架构类型 = 3
                AND bi2.组织架构类型 = 2
                --AND mp.TradersWay <> '合作方操盘' 
        GROUP BY bi2.组织架构ID ,
                bi2.组织架构名称 ,
                bi2.组织架构编码 ,
                bi2.组织架构类型; 
             
           
                
        ---更新回笼数据
        UPDATE  a
        SET     a.本月回款金额 = ISNULL(t1.本月累计回笼金额, 0)  ,
                a.本月操盘回款金额 = ISNULL(t1.本月操盘累计回笼金额, 0)  ,
                a.本月回款金额权益口径 = ISNULL(t1.本月回款金额权益口径, 0)  ,
                a.本月回款金额并表口径 = ISNULL(t1.本月回款金额并表口径, 0)  ,
                a.本年回款金额 = ISNULL(t1.本年累计回笼金额, 0)  ,
                a.本年操盘回款金额 = ISNULL(t1.本年操盘累计回笼金额, 0)  ,
                a.本年回款金额权益口径 = ISNULL(t1.本年回款金额权益口径, 0)  ,
                a.本年回款金额并表口径 = ISNULL(t1.本年回款金额并表口径, 0) 
        FROM    #SaleAmount a
                LEFT JOIN ( SELECT  bi.组织架构父级ID AS 组织架构ID ,
                                    SUM(ISNULL(b.本月累计回笼金额, 0)) AS 本月累计回笼金额 ,
                                    SUM(CASE WHEN mp.TradersWay <> '合作方操盘'
                                             THEN ISNULL(b.本月累计回笼金额, 0)
                                             ELSE 0
                                        END) AS 本月操盘累计回笼金额 ,
                                    SUM(ISNULL(b.本月累计回笼金额, 0)
                                        * ISNULL(lbp.LbProjectValue, 0)
                                        / 100.00) AS 本月回款金额权益口径 ,
                                    SUM(CASE WHEN mp.BbWay = '我司并表'
                                             THEN ISNULL(b.本月累计回笼金额, 0)
                                             ELSE 0
                                        END) 本月回款金额并表口径 ,
                                    SUM(ISNULL(b.本年累计回笼金额, 0)) AS 本年累计回笼金额 ,
                                    SUM(CASE WHEN mp.TradersWay <> '合作方操盘'
                                             THEN ISNULL(b.本年累计回笼金额, 0)
                                             ELSE 0
                                        END) AS 本年操盘累计回笼金额 ,
                                    SUM(ISNULL(b.本年累计回笼金额, 0)
                                        * ISNULL(lbp.LbProjectValue, 0)
                                        / 100.00) AS 本年回款金额权益口径 ,
                                    SUM(CASE WHEN mp.BbWay = '我司并表'
                                             THEN ISNULL(b.本年累计回笼金额, 0)
                                             ELSE 0
                                        END) AS 本年回款金额并表口径
                            FROM    ydkb_BaseInfo bi
                                    LEFT JOIN dbo.mdm_Project mp ON bi.组织架构ID = mp.ProjGUID
                                    LEFT JOIN ( SELECT  projGUID ,
                                                        MAX(LbProjectValue) AS LbProjectValue
                                                FROM    mdm_LbProject
                                                WHERE   LbProject = 'cwsybl'
                                                GROUP BY projGUID
                                              ) lbp ON lbp.projGUID = mp.ProjGUID
                                    LEFT JOIN #s_getin b ON bi.组织架构ID = b.topprojguid
                            WHERE   bi.组织架构类型 = 3 AND mp.TradersWay <> '合作方操盘'
                            GROUP BY bi.组织架构父级ID
                          ) t1 ON a.组织架构ID = t1.组织架构ID;
                          
         
         
---产成品实际销售情况统计，非操盘项目
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#buildSaleTemp')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #buildSaleTemp;
            END; 
            
--按照产品楼栋计算产成品的销售情况
        SELECT  p_lddb.SaleBldGUID ,
                SUM([ThisMonthSaleJeQY]) / 10000 AS byqyje ,
                SUM([ThisYearSaleJeQY]) / 10000 AS bnqyje ,
                SUM([ThisMonthSaleMjQY]) / 10000 AS byqymj ,
                SUM([ThisYearSaleMjQY]) / 10000 AS bnqymj
        INTO    #buildSaleTemp
        FROM    p_lddb
                LEFT JOIN s_ccpsuodingbld sd ON p_lddb.SaleBldGUID = sd.SaleBldGUID
        WHERE   ISNULL(SJjgbadate, '2099-01-01') <= CONVERT(VARCHAR(4), YEAR(GETDATE()))
                + '-01-01'
                AND DATEDIFF(DAY, QXDate, GETDATE()) = 0
                AND sd.SaleBldGUID IS NOT NULL  --只统计锁定产成品的完成金额
        GROUP BY p_lddb.SaleBldGUID;


---获取一级项目产成品销售情况，不含非操作盘项目
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#projccbSaleTemp')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #projccbSaleTemp;
            END; 
            
        SELECT  ISNULL(mp1.ProjGUID, mp.ProjGUID) AS ProjGUID ,
                SUM(a.byqyje) AS 本月产成品签约金额 ,
                SUM(a.bnqyje) AS 本年产成品签约金额 ,
                SUM(a.byqymj) AS 本月产成品签约面积 ,
                SUM(a.bnqymj) AS 本年产成品签约面积
        INTO    #projccbSaleTemp
        FROM    erp25.dbo.mdm_GCBuild gc
                LEFT  JOIN erp25.dbo.mdm_SaleBuild sb ON gc.GCBldGUID = sb.GCBldGUID
                LEFT  JOIN #buildSaleTemp a ON a.SaleBldGUID = sb.SaleBldGUID
                LEFT JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = gc.ProjGUID
                LEFT JOIN erp25.dbo.mdm_Project mp1 ON mp1.ProjGUID = mp.ParentProjGUID
        WHERE   ( 1 = 1 ) --AND sb.SaleBldGUID IS NOT NULL
                AND mp1.Level = 2
        GROUP BY ISNULL(mp1.ProjGUID, mp.ProjGUID); 
        
 --获取城市公司产成品销售情况，不含非操盘项目
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#CityccbSaleTemp')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #CityccbSaleTemp;
            END; 
            
        SELECT  bi2.组织架构ID ,
                bi2.组织架构编码 ,
                bi2.组织架构父级ID ,
                bi2.组织架构名称 ,
                bi2.组织架构类型 ,
                SUM(pc.本月产成品签约金额) AS 本月产成品签约金额 ,
                SUM(pc.本年产成品签约金额) AS 本年产成品签约金额 ,
                SUM(pc.本月产成品签约面积) AS 本月产成品签约面积 ,
                SUM(pc.本年产成品签约面积) AS 本年产成品签约面积
        INTO    #CityccbSaleTemp
        FROM    #projccbSaleTemp pc
                LEFT JOIN ydkb_BaseInfo bi ON bi.组织架构ID = pc.ProjGUID
                LEFT JOIN ydkb_BaseInfo bi2 ON bi2.组织架构ID = bi.组织架构父级ID
        GROUP BY bi2.组织架构ID ,
                bi2.组织架构编码 ,
                bi2.组织架构父级ID ,
                bi2.组织架构名称 ,
                bi2.组织架构类型;
 
 
 ---获取平台公司产成品销售情况，不含非操作盘项目
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#CompccbSaleTemp')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #CompccbSaleTemp;
            END; 
            
        SELECT  mp.DevelopmentCompanyGUID AS DevelopmentCompanyGUID ,
                SUM(a.byqyje) AS 本月产成品签约金额 ,
                SUM(a.bnqyje) AS 本年产成品签约金额 ,
                SUM(a.byqymj) AS 本月产成品签约面积 ,
                SUM(a.bnqymj) AS 本年产成品签约面积
        INTO    #CompccbSaleTemp
        FROM    erp25.dbo.mdm_GCBuild gc
                LEFT JOIN erp25.dbo.mdm_SaleBuild sb ON gc.GCBldGUID = sb.GCBldGUID
                LEFT JOIN #buildSaleTemp a ON a.SaleBldGUID = sb.SaleBldGUID
                LEFT JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = gc.ProjGUID
        WHERE   ( 1 = 1 )  --AND sb.SaleBldGUID IS NOT NULL
                --AND ISNULL(gc.JgbabFactDate, '2099-01-01') < CONVERT(VARCHAR(4), YEAR(GETDATE()))
                --+ '-01-01'
                --AND ISNULL(mp.TradersWay, '') <> '合作方操盘'
        GROUP BY mp.DevelopmentCompanyGUID;      
       
/*插入城市公司数据*/      
        INSERT  INTO dbo.ydkb_jyyj
                ( 组织架构ID ,
                  组织架构名称 ,
                  组织架构编码 ,
                  组织架构类型 ,
                  本月销售任务金额 ,
                  本月操盘销售任务金额 ,
                  本月签约任务金额 ,
                  本月操盘签约任务金额 ,
                  本月产成品任务金额 ,
                  本月回款任务金额 ,
                  本月操盘回款任务金额 ,
                  本月成本直投任务金额 ,
                  本月销售金额 ,
                  本月操盘销售金额 ,
                  本月签约金额 ,
                  本月操盘签约金额 ,
                  本月产成品金额 ,
                  本月回款金额 ,
                  本月操盘回款金额 ,
                  本月回款金额权益口径 ,
                  本月回款金额并表口径 ,
                  本月成本直投金额 ,
                  本月销售完成率 ,
                  本月签约完成率 ,
                  本月产成品完成率 ,
                  本月回款完成率 ,
                  本月成本直投完成率 ,
                  本年销售任务金额 ,
                  本年签约任务金额 ,
                  本年产成品任务金额 ,
                  本年回款任务金额 ,
                  本年成本直投任务金额 ,
                  本年投资拓展任务金额 ,
                  本年销售金额 ,
                  本年销售金额权益口径 ,
                  本年销售金额并表口径 ,
                  本年操盘销售金额 ,
                  本年签约金额 ,
                  本年签约金额权益口径 ,
                  本年签约金额并表口径 ,
                  本年操盘签约金额 ,
                  本年产成品金额 ,
                  本年回款金额 ,
                  本年操盘回款金额 ,
                  本年回款金额权益口径 ,
                  本年回款金额并表口径 ,
                  本年成本直投金额 ,
                  本年销售完成率 ,
                  本年签约完成率 ,
                  本年产成品完成率 ,
                  本年回款完成率 ,
                  本年成本直投完成率 ,
                  本季度成本直投任务金额 ,
                  本季度成本直投金额 ,
                  本季度成本直投完成率 ,
                  本年投资拓展金额 ,
                  本年投资拓展完成率 ,
                  JanFeb新货推货面积 ,
                  JanFeb存货推货面积 ,
                  JanFeb新货认购面积 ,
                  JanFeb存货签约面积 ,
                  JanFeb新货去化率 ,
                  JanFeb存货去化率 ,
                  JanFeb综合去化率 ,
                  Mar新货推货面积 ,
                  Mar存货推货面积 ,
                  Mar新货认购面积 ,
                  Mar存货签约面积 ,
                  Mar新货去化率 ,
                  Mar存货去化率 ,
                  Mar综合去化率 ,
                  Apr新货推货面积 ,
                  Apr存货推货面积 ,
                  Apr新货认购面积 ,
                  Apr存货签约面积 ,
                  Apr新货去化率 ,
                  Apr存货去化率 ,
                  Apr综合去化率 ,
                  May新货推货面积 ,
                  May存货推货面积 ,
                  May新货认购面积 ,
                  May存货签约面积 ,
                  May新货去化率 ,
                  May存货去化率 ,
                  May综合去化率 ,
                  Jun新货推货面积 ,
                  Jun存货推货面积 ,
                  Jun新货认购面积 ,
                  Jun存货签约面积 ,
                  Jun新货去化率 ,
                  Jun存货去化率 ,
                  Jun综合去化率 ,
                  July新货推货面积 ,
                  July存货推货面积 ,
                  July新货认购面积 ,
                  July存货签约面积 ,
                  July新货去化率 ,
                  July存货去化率 ,
                  July综合去化率 ,
                  Aug新货推货面积 ,
                  Aug存货推货面积 ,
                  Aug新货认购面积 ,
                  Aug存货签约面积 ,
                  Aug新货去化率 ,
                  Aug存货去化率 ,
                  Aug综合去化率 ,
                  Sep新货推货面积 ,
                  Sep存货推货面积 ,
                  Sep新货认购面积 ,
                  Sep存货签约面积 ,
                  Sep新货去化率 ,
                  Sep存货去化率 ,
                  Sep综合去化率 ,
                  Oct新货推货面积 ,
                  Oct存货推货面积 ,
                  Oct新货认购面积 ,
                  Oct存货签约面积 ,
                  Oct新货去化率 ,
                  Oct存货去化率 ,
                  Oct综合去化率 ,
                  Nov新货推货面积 ,
                  Nov存货推货面积 ,
                  Nov新货认购面积 ,
                  Nov存货签约面积 ,
                  Nov新货去化率 ,
                  Nov存货去化率 ,
                  Nov综合去化率 ,
                  Dec新货推货面积 ,
                  Dec存货推货面积 ,
                  Dec新货认购面积 ,
                  Dec存货签约面积 ,
                  Dec新货去化率 ,
                  Dec存货去化率 ,
                  Dec综合去化率 ,
                  本年新货推货面积 ,
                  本年存货推货面积 ,
                  本年新货认购面积 ,
                  本年存货签约面积 ,
                  本年新货去化率 ,
                  本年存货去化率 ,
                  本年综合去化率 ,
                  开盘7天认购转签约签约金额 ,
                  开盘7天转签约率 ,
                  已认购未签约金额 ,
                  已签约未回款金额  
                )
                SELECT  bi.组织架构ID ,
                        bi.组织架构名称 ,
                        bi.组织架构编码 ,
                        bi.组织架构类型 ,
                        yd.本月销售任务 AS bySaleTaskAmount ,
                        yd.本月操盘销售任务 ,
                        yd.本月签约任务 AS byqyTaskAmount ,
                        yd.本月操盘签约任务 ,
                        yd.本月产成品任务 AS byccpTaskAmount ,
                        yd.本月回笼任务 AS byhlTaskAmount ,
                        yd.本月操盘回笼任务 ,
                        yd.本月成本直投任务 AS byztTaskAmount ,
                        ISNULL(qy.本月销售金额, 0) AS bySaleAmount ,
                        ISNULL(qy.本月操盘销售金额, 0) ,
                        ISNULL(qy.本月签约金额, 0) AS byqyAmount ,
                        ISNULL(qy.本月操盘签约金额, 0) ,
                        ISNULL(pc.本月产成品签约金额, 0) AS byccpAmount ,
                        ISNULL(qy.本月回款金额, 0) AS byhlAmount ,
                        ISNULL(qy.本月操盘回款金额, 0) ,
                        ISNULL(qy.本月回款金额权益口径, 0) AS 本月回款金额权益口径 ,
                        ISNULL(qy.本月回款金额并表口径, 0) AS 本月回款金额并表口径 ,
                        pa.本月实付金额 AS byztAmount ,
                        CASE WHEN ISNULL(yd.本月销售任务, 0) = 0 THEN 0
                             ELSE ISNULL(qy.本月销售金额, 0) * 1.00
                                  / ISNULL(yd.本月销售任务, 0)
                        END AS bySaleCompletionRate ,
                        CASE WHEN ISNULL(yd.本月签约任务, 0) = 0 THEN 0
                             ELSE ISNULL(qy.本月签约金额, 0) * 1.00
                                  / ISNULL(yd.本月签约任务, 0)
                        END AS byqyCompletionRate ,
                        CASE WHEN ISNULL(yd.本月产成品任务, 0) = 0 THEN 0
                             ELSE ISNULL(pc.本月产成品签约金额, 0) / ISNULL(yd.本月产成品任务,
                                                              0) * 1.00
                        END AS 本月产成品完成率 ,
                        CASE WHEN ISNULL(yd.本月回笼任务, 0) = 0 THEN 0
                             ELSE ( ISNULL(qy.本月回款金额, 0) ) * 1.00
                                  / ISNULL(yd.本月回笼任务, 0)
                        END AS byhlCompletionRate ,
                        CASE WHEN ISNULL(yd.本月成本直投任务, 0) = 0 THEN 0
                             ELSE ISNULL(pa.本月实付金额, 0) / ISNULL(yd.本月成本直投任务, 0)
                                  * 1.00
                        END AS byztCompletionRate ,
                        nd.本年销售任务 AS bnSaleTaskAmount ,
                        nd.本年签约任务 AS bnqyTaskAmount ,
                        nd.本年产成品任务 AS bnccpTaskAmount ,
                        nd.本年回笼任务 AS bnhlTaskAmount ,
                        nd.本年成本直投任务 AS bnztTaskAmount ,
                        ISNULL(hntz.rw, 0) * 10000 AS 本年投资拓展任务金额 ,
                        ISNULL(qy.本年销售金额, 0) + ISNULL(ts.TotalAmount, 0) AS bnSalemount , --本年销售金额加上特殊业绩录入的数据
                        ISNULL(qy.本年销售金额权益口径, 0) , --未加上特殊业绩的金额
                        ISNULL(qy.本年销售金额并表口径, 0) ,
                        ISNULL(qy.本年操盘销售金额, 0) + ISNULL(ts.TotalAmount, 0) ,
                        ISNULL(qy.本年签约金额, 0) + ISNULL(ts.TotalAmount, 0) AS bnqyAmount , --本年签约金额加上特殊业绩录入的数据
                        ISNULL(qy.本年签约金额权益口径, 0) ,
                        ISNULL(qy.本年签约金额并表口径, 0) ,
                        ISNULL(qy.本年操盘签约金额, 0) + ISNULL(ts.TotalAmount, 0) ,
                        ISNULL(pc.本年产成品签约金额, 0) AS bnccpAmount ,
                        ISNULL(qy.本年回款金额, 0) AS bnhlAmount ,--本年回笼金额加上特殊业绩录入数据，韶关高铁项目有1.83亿元
                        ISNULL(qy.本年操盘回款金额, 0) ,
                        ISNULL(qy.本年回款金额权益口径, 0) AS 本年回款金额权益口径 ,
                        ISNULL(qy.本年回款金额并表口径, 0) AS 本年回款金额并表口径 ,
                        pa.本年实付金额 AS bnztAmount ,
                        CASE WHEN ISNULL(nd.本年销售任务, 0) = 0 THEN 0
                             ELSE ( ISNULL(qy.本年销售金额, 0)
                                    + ISNULL(ts.TotalAmount, 0) ) * 1.00
                                  / ISNULL(nd.本年销售任务, 0)
                        END AS bnSaleCompletionRate ,
                        CASE WHEN ISNULL(nd.本年签约任务, 0) = 0 THEN 0
                             ELSE ( ISNULL(qy.本年签约金额, 0)
                                    + ISNULL(ts.TotalAmount, 0) ) * 1.00
                                  / ISNULL(nd.本年签约任务, 0)
                        END AS bnqyCompletionRate ,
                        CASE WHEN ISNULL(nd.本年产成品任务, 0) = 0 THEN 0
                             ELSE ISNULL(pc.本年产成品签约金额, 0) / ISNULL(nd.本年产成品任务,
                                                              0) * 1.00
                        END AS 本年产成品完成率 ,
                        CASE WHEN ISNULL(nd.本年回笼任务, 0) = 0 THEN 0
                             ELSE ( ISNULL(qy.本年回款金额, 0) ) * 1.00
                                  / ISNULL(nd.本年回笼任务, 0)
                        END AS bnhlCompletionRate ,
                        CASE WHEN ISNULL(nd.本年成本直投任务, 0) = 0 THEN 0
                             ELSE ISNULL(pa.本年实付金额, 0) / ISNULL(nd.本年成本直投任务, 0)
                                  * 1.00
                        END AS 本年成本直投完成率 ,
                        jd.本季度成本直投任务 AS 本季度成本直投任务金额 ,
                        pa.本季度实付金额 AS 本季度成本直投金额 ,
                        CASE WHEN ISNULL(jd.本季度成本直投任务, 0) = 0 THEN 0
                             ELSE ISNULL(pa.本季度实付金额, 0) / ISNULL(jd.本季度成本直投任务,
                                                              0) * 1.00
                        END AS 本季度成本直投完成率 ,
                        ISNULL(hntz.sj, 0) * 10000 AS 本年投资拓展金额 ,
                        CASE WHEN ISNULL(hntz.rw, 0) = 0 THEN 0.00
                             ELSE ISNULL(hntz.sj, 0) * 1.00 / ISNULL(hntz.rw,
                                                              0)
                        END AS 本年投资拓展完成率 ,
                        
                        --去化率
                        ISNULL(cs.Jan新货推货面积, 0) + ISNULL(cs.Feb新货推货面积, 0) AS JanFeb新货推货面积 ,
                        ISNULL(cs.Jan存货推货面积, 0) + ISNULL(cs.Feb存货推货面积, 0) AS JanFeb存货推货面积 ,
                        ISNULL(cs.Jan新货认购面积, 0) + ISNULL(cs.Feb新货认购面积, 0) AS JanFeb新货认购面积 ,
                        ISNULL(cs.Jan存货签约面积, 0) + ISNULL(cs.Feb存货签约面积, 0) AS JanFeb存货签约面积 ,
                        
                        --去化率
                        CASE WHEN ( ISNULL(cs.Jan新货推货面积, 0)
                                    + ISNULL(cs.Feb新货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Jan新货认购面积, 0)
                                    + ISNULL(cs.Feb新货认购面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Jan新货推货面积, 0)
                                      + ISNULL(cs.Feb新货推货面积, 0) )
                        END AS JanFeb新货去化率 ,
                        CASE WHEN ( ISNULL(cs.Jan存货推货面积, 0)
                                    + ISNULL(cs.Feb存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Jan存货签约面积, 0)
                                    + ISNULL(cs.Feb存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Jan存货推货面积, 0)
                                      + ISNULL(cs.Feb存货推货面积, 0) )
                        END AS JanFeb存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Jan新货推货面积, 0)
                                    + ISNULL(cs.Feb新货推货面积, 0)
                                    + ISNULL(cs.Jan存货推货面积, 0)
                                    + ISNULL(cs.Feb存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Jan新货认购面积, 0)
                                    + ISNULL(cs.Feb新货认购面积, 0)
                                    + ISNULL(cs.Jan存货签约面积, 0)
                                    + ISNULL(cs.Feb存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Jan新货推货面积, 0)
                                      + ISNULL(cs.Feb新货推货面积, 0)
                                      + ISNULL(cs.Jan存货推货面积, 0)
                                      + ISNULL(cs.Feb存货推货面积, 0) )
                        END AS JanFeb综合去化率 ,
                        cs.Mar新货推货面积 AS Mar新货推货面积 ,
                        cs.Mar存货推货面积 AS Mar存货推货面积 ,
                        cs.Mar新货认购面积 AS Mar新货认购面积 ,
                        cs.Mar存货签约面积 AS Mar存货签约面积 ,
                        CASE WHEN ISNULL(cs.Mar新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Mar新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Mar新货推货面积, 0)
                        END AS Mar新货去化率 ,
                        CASE WHEN ISNULL(cs.Mar存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Mar存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Mar存货推货面积, 0)
                        END AS Mar存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Mar新货推货面积, 0)
                                    + ISNULL(cs.Mar存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Mar新货认购面积, 0)
                                    + ISNULL(cs.Mar存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Mar新货推货面积, 0)
                                      + ISNULL(cs.Mar存货推货面积, 0) )
                        END AS Mar综合去化率 ,
                        cs.Apr新货推货面积 AS Apr新货推货面积 ,
                        cs.Apr存货推货面积 AS Apr存货推货面积 ,
                        cs.Apr新货认购面积 AS Apr新货认购面积 ,
                        cs.Apr存货签约面积 AS Apr存货签约面积 ,
                        CASE WHEN ISNULL(cs.Apr新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Apr新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Apr新货推货面积, 0)
                        END AS Apr新货去化率 ,
                        CASE WHEN ISNULL(cs.Apr存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Apr存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Apr存货推货面积, 0)
                        END AS Apr存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Apr新货推货面积, 0)
                                    + ISNULL(cs.Apr存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Apr新货认购面积, 0)
                                    + ISNULL(cs.Apr存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Apr新货推货面积, 0)
                                      + ISNULL(cs.Apr存货推货面积, 0) )
                        END AS Apr综合去化率 ,
                        cs.May新货推货面积 AS May新货推货面积 ,
                        cs.May存货推货面积 AS May存货推货面积 ,
                        cs.May新货认购面积 AS May新货认购面积 ,
                        cs.May存货签约面积 AS May存货签约面积 ,
                        CASE WHEN ISNULL(cs.May新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.May新货认购面积, 0) * 1.00
                                  / ISNULL(cs.May新货推货面积, 0)
                        END AS May新货去化率 ,
                        CASE WHEN ISNULL(cs.May存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.May存货签约面积, 0) * 1.00
                                  / ISNULL(cs.May存货推货面积, 0)
                        END AS May存货去化率 ,
                        CASE WHEN ( ISNULL(cs.May新货推货面积, 0)
                                    + ISNULL(cs.May存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.May新货认购面积, 0)
                                    + ISNULL(cs.May存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.May新货推货面积, 0)
                                      + ISNULL(cs.May存货推货面积, 0) )
                        END AS May综合去化率 ,
                        cs.Jun新货推货面积 AS Jun新货推货面积 ,
                        cs.Jun存货推货面积 AS Jun存货推货面积 ,
                        cs.Jun新货认购面积 AS Jun新货认购面积 ,
                        cs.Jun存货签约面积 AS Jun存货签约面积 ,
                        CASE WHEN ISNULL(cs.Jun新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Jun新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Jun新货推货面积, 0)
                        END AS Jun新货去化率 ,
                        CASE WHEN ISNULL(cs.Jun存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Jun存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Jun存货推货面积, 0)
                        END AS Jun存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Jun新货推货面积, 0)
                                    + ISNULL(cs.Jun存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Jun新货认购面积, 0)
                                    + ISNULL(cs.Jun存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Jun新货推货面积, 0)
                                      + ISNULL(cs.Jun存货推货面积, 0) )
                        END AS Jun综合去化率 ,
                        cs.July新货推货面积 AS July新货推货面积 ,
                        cs.July存货推货面积 AS July存货推货面积 ,
                        cs.July新货认购面积 AS July新货认购面积 ,
                        cs.July存货签约面积 AS July存货签约面积 ,
                        CASE WHEN ISNULL(cs.July新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.July新货认购面积, 0) * 1.00
                                  / ISNULL(cs.July新货推货面积, 0)
                        END AS July新货去化率 ,
                        CASE WHEN ISNULL(cs.July存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.July存货签约面积, 0) * 1.00
                                  / ISNULL(cs.July存货推货面积, 0)
                        END AS July存货去化率 ,
                        CASE WHEN ( ISNULL(cs.July新货推货面积, 0)
                                    + ISNULL(cs.July存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.July新货认购面积, 0)
                                    + ISNULL(cs.July存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.July新货推货面积, 0)
                                      + ISNULL(cs.July存货推货面积, 0) )
                        END AS July综合去化率 ,
                        cs.Aug新货推货面积 AS Aug新货推货面积 ,
                        cs.Aug存货推货面积 AS Aug存货推货面积 ,
                        cs.Aug新货认购面积 AS Aug新货认购面积 ,
                        cs.Aug存货签约面积 AS Aug存货签约面积 ,
                        CASE WHEN ISNULL(cs.Aug新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Aug新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Aug新货推货面积, 0)
                        END AS Aug新货去化率 ,
                        CASE WHEN ISNULL(cs.Aug存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Aug存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Aug存货推货面积, 0)
                        END AS Aug存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Aug新货推货面积, 0)
                                    + ISNULL(cs.Aug存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Aug新货认购面积, 0)
                                    + ISNULL(cs.Aug存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Aug新货推货面积, 0)
                                      + ISNULL(cs.Aug存货推货面积, 0) )
                        END AS Aug综合去化率 ,
                        cs.Sep新货推货面积 AS Sep新货推货面积 ,
                        cs.Sep存货推货面积 AS Sep存货推货面积 ,
                        cs.Sep新货认购面积 AS Sep新货认购面积 ,
                        cs.Sep存货签约面积 AS Sep存货签约面积 ,
                        CASE WHEN ISNULL(cs.Sep新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Sep新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Sep新货推货面积, 0)
                        END AS Sep新货去化率 ,
                        CASE WHEN ISNULL(cs.Sep存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Sep存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Sep存货推货面积, 0)
                        END AS Sep存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Sep新货推货面积, 0)
                                    + ISNULL(cs.Sep存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Sep新货认购面积, 0)
                                    + ISNULL(cs.Sep存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Sep新货推货面积, 0)
                                      + ISNULL(cs.Sep存货推货面积, 0) )
                        END AS Sep综合去化率 ,
                        cs.Oct新货推货面积 AS Oct新货推货面积 ,
                        cs.Oct存货推货面积 AS Oct存货推货面积 ,
                        cs.Oct新货认购面积 AS Oct新货认购面积 ,
                        cs.Oct存货签约面积 AS Oct存货签约面积 ,
                        CASE WHEN ISNULL(cs.Oct新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Oct新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Oct新货推货面积, 0)
                        END AS Oct新货去化率 ,
                        CASE WHEN ISNULL(cs.Oct存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Oct存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Oct存货推货面积, 0)
                        END AS Oct存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Oct新货推货面积, 0)
                                    + ISNULL(cs.Oct存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Oct新货认购面积, 0)
                                    + ISNULL(cs.Oct存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Oct新货推货面积, 0)
                                      + ISNULL(cs.Oct存货推货面积, 0) )
                        END AS Oct综合去化率 ,
                        cs.Nov新货推货面积 AS Nov新货推货面积 ,
                        cs.Nov存货推货面积 AS Nov存货推货面积 ,
                        cs.Nov新货认购面积 AS Nov新货认购面积 ,
                        cs.Nov存货签约面积 AS Nov存货签约面积 ,
                        CASE WHEN ISNULL(cs.Nov新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Nov新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Nov新货推货面积, 0)
                        END AS Nov新货去化率 ,
                        CASE WHEN ISNULL(cs.Nov存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Nov存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Nov存货推货面积, 0)
                        END AS Nov存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Nov新货推货面积, 0)
                                    + ISNULL(cs.Nov存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Nov新货认购面积, 0)
                                    + ISNULL(cs.Nov存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Nov新货推货面积, 0)
                                      + ISNULL(cs.Nov存货推货面积, 0) )
                        END AS Nov综合去化率 ,
                        cs.Dec新货推货面积 AS Dec新货推货面积 ,
                        cs.Dec存货推货面积 AS Dec存货推货面积 ,
                        cs.Dec新货认购面积 AS Dec新货认购面积 ,
                        cs.Dec存货签约面积 AS Dec存货签约面积 ,
                        CASE WHEN ISNULL(cs.Dec新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Dec新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Dec新货推货面积, 0)
                        END AS Dec新货去化率 ,
                        CASE WHEN ISNULL(cs.Dec存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Dec存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Dec存货推货面积, 0)
                        END AS Dec存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Dec新货推货面积, 0)
                                    + ISNULL(cs.Dec存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Dec新货认购面积, 0)
                                    + ISNULL(cs.Dec存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Dec新货推货面积, 0)
                                      + ISNULL(cs.Dec存货推货面积, 0) )
                        END AS Dec综合去化率 ,
                        -------------------------------------------------------------------
                        ISNULL(cs.本年新货推货面积, 0) AS 本年新货推货面积 ,
                        ISNULL(cs.本年存货推货面积, 0) AS 本年存货推货面积 ,
                        ISNULL(cs.本年新货认购面积, 0) AS 本年新货认购面积 ,
                        ISNULL(cs.本年存货签约面积, 0) AS 本年存货签约面积 ,
                        CASE WHEN ISNULL(cs.本年新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.本年新货认购面积, 0) * 1.00
                                  / ISNULL(cs.本年新货推货面积, 0)
                        END AS 本年新货去化率 ,
                        CASE WHEN ISNULL(cs.本年存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.本年存货签约面积, 0) * 1.00
                                  / ISNULL(cs.本年存货推货面积, 0)
                        END AS 本年存货去化率 ,
                        CASE WHEN ( ISNULL(cs.本年新货推货面积, 0)
                                    + ISNULL(cs.本年存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.本年新货认购面积, 0)
                                    + ISNULL(cs.本年存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.本年新货推货面积, 0)
                                      + ISNULL(cs.本年存货推货面积, 0) )
                        END AS 本年综合去化率 ,
                        qy.开盘7天认购转签约签约金额 ,
                        qy.开盘7天转签约率 ,
                        qy.已认购未签约金额 ,
                        qy.已签约未回款金额
                FROM    ydkb_BaseInfo bi
                        LEFT JOIN #ydTask yd ON yd.组织架构ID = bi.组织架构ID
                        LEFT JOIN #ndTask nd ON nd.组织架构ID = bi.组织架构ID
                        LEFT JOIN #jdTask jd ON jd.组织架构ID = bi.组织架构ID
                        LEFT JOIN #SaleAmount qy ON qy.组织架构ID = bi.组织架构ID
                        LEFT JOIN #CitySaleQh cs ON cs.组织架构ID = bi.组织架构ID
                        LEFT  JOIN #PayAmount pa ON pa.组织架构ID = bi.组织架构ID
                        LEFT JOIN #CityccbSaleTemp pc ON pc.组织架构ID = bi.组织架构ID
                        LEFT JOIN #tsCitySaleAmount ts ON ts.组织架构ID = bi.组织架构ID
                        LEFT JOIN s_hntzrw hntz ON hntz.buguid = bi.组织架构父级ID
                                                   AND hntz.city = bi.组织架构名称
                WHERE   bi.组织架构类型 = 2;
        



/*插入一级项目任务数据*/        
--获取月度任务
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ydProjTask')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #ydProjTask;
            END;  

        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                mp.ProjGUID ,
                s.RgTask AS 本月销售任务 ,
                CASE WHEN mp.TradersWay <> '合作方操盘' THEN s.RgTask
                     ELSE 0
                END AS 本月操盘销售任务 ,
                s.SigningTask 本月签约任务 ,
                CASE WHEN mp.TradersWay <> '合作方操盘' THEN s.SigningTask
                     ELSE 0
                END AS 本月操盘签约任务 ,
                s.PaymentTask 本月回笼任务 ,
                CASE WHEN mp.TradersWay <> '合作方操盘' THEN s.PaymentTask
                     ELSE 0
                END AS 本月操盘回笼任务 ,
                0 * 10000 AS 本月成本直投任务 ,
                ISNULL(ccp.[本月份产成品任务], 0) * 10000 AS 本月产成品任务
        INTO    #ydProjTask
        FROM    erp25.dbo.ydkb_BaseInfo bi
                LEFT JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = bi.组织架构ID
                LEFT JOIN erp25.dbo.s_SaleProjectTaskList s ON bi.组织架构ID = s.ProjectGUID
                LEFT JOIN erp25.dbo.s_SaleProjectTask t ON s.ProjectTaskGUID = t.ProjectTaskGUID
                LEFT JOIN erp25.dbo.ykdb_hn_ccpTask ccp ON ccp.项目GUID = bi.组织架构ID
        WHERE   bi.组织架构类型 = 3
                AND t.Syear = YEAR(GETDATE())
                AND t.Smonth = MONTH(GETDATE())
                AND t.TaskPUnit = '月度';
               -- AND mp.TradersWay <> '合作方操盘';
                --AND mp.ProjGUID NOT IN (
                --'7081EF46-2814-E711-80BA-E61F13C57837',
                --'31783072-6849-E811-80BA-E61F13C57837',
                --'CACA1201-F746-E811-80BA-E61F13C57837',
                --'445AD138-A747-E811-80BA-E61F13C57837',
                --'B3363602-A589-E811-80BF-E61F13C57837' ); 
--获取年度任务
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ndProjTask')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #ndProjTask;
            END;  


        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                mp.ProjGUID ,
                s.RgTask AS 本年销售任务 ,
                CASE WHEN mp.TradersWay <> '合作方操盘' THEN s.RgTask
                     ELSE 0
                END AS 本年操盘销售任务 ,
                s.SigningTask 本年签约任务 ,
                CASE WHEN mp.TradersWay <> '合作方操盘' THEN s.SigningTask
                     ELSE 0
                END AS 本年操盘签约任务 ,
                s.PaymentTask 本年回笼任务 ,
                CASE WHEN mp.TradersWay <> '合作方操盘' THEN s.PaymentTask
                     ELSE 0
                END AS 本年操盘回笼任务 ,
                ISNULL(zt.年度建安费用, 0) AS 本年成本直投任务 ,
                ISNULL(ccp.年度产成品任务, 0) * 10000 AS 本年产成品任务
        INTO    #ndProjTask
        FROM    erp25.dbo.ydkb_BaseInfo bi
                LEFT JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = bi.组织架构ID
                LEFT JOIN erp25.dbo.s_SaleProjectTaskList s ON bi.组织架构ID = s.ProjectGUID
                LEFT JOIN erp25.dbo.s_SaleProjectTask t ON s.ProjectTaskGUID = t.ProjectTaskGUID
                LEFT JOIN erp25.dbo.ykdb_hn_ccpTask ccp ON ccp.项目GUID = bi.组织架构ID
                LEFT JOIN erp25.dbo.s_hncbzt zt ON zt.ProjGuid = bi.组织架构ID
        WHERE   bi.组织架构类型 = 3 --t.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' AND
                AND t.Syear = YEAR(GETDATE())
                AND t.TaskPUnit = '年度';
               -- AND mp.TradersWay <> '合作方操盘';
                --AND mp.ProjGUID NOT IN (
                --'7081EF46-2814-E711-80BA-E61F13C57837',
                --'31783072-6849-E811-80BA-E61F13C57837',
                --'CACA1201-F746-E811-80BA-E61F13C57837',
                --'445AD138-A747-E811-80BA-E61F13C57837',
                --'B3363602-A589-E811-80BF-E61F13C57837' );

--销售&回款实际完成情况 
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#SaleProjAmount')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #SaleProjAmount;
            END; 

        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                              AND DATEDIFF(mm, ord.rgDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本月销售金额 ,
                SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                              AND mp.TradersWay <> '合作方操盘'
                              AND DATEDIFF(mm, ord.rgDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本月操盘销售金额 ,
                SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                              AND DATEDIFF(yy, ord.rgDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本年销售金额 ,
                SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                              AND DATEDIFF(yy, ord.rgDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END * ( ISNULL(lbp.LbProjectValue, 0) / 100.00 )) / 10000 AS 本年销售金额权益口径 ,
                SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                              AND mp.BbWay = '我司并表'
                              AND DATEDIFF(yy, ord.rgDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本年销售金额并表口径 ,
                SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                              AND mp.TradersWay <> '合作方操盘'
                              AND DATEDIFF(yy, ord.rgDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本年操盘销售金额 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND DATEDIFF(mm, ord.QSDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本月签约金额 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND mp.TradersWay <> '合作方操盘'
                              AND DATEDIFF(mm, ord.QSDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本月操盘签约金额 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND DATEDIFF(yy, ord.QSDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本年签约金额 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND DATEDIFF(yy, ord.QSDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END * ( ISNULL(lbp.LbProjectValue, 0) / 100.00 )) / 10000 AS 本年签约金额权益口径 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND mp.BbWay = '我司并表'
                              AND DATEDIFF(yy, ord.QSDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本年签约金额并表口径 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND mp.TradersWay <> '合作方操盘'
                              AND DATEDIFF(yy, ord.QSDate, GETDATE()) = 0
                         THEN ISNULL(ord.JyTotal, 0)
                         ELSE 0
                    END) / 10000 AS 本年操盘签约金额 ,
                convert(MONEY,0) 本月回款金额 ,
                convert(MONEY,0) 本月操盘回款金额 ,
                convert(MONEY,0) 本月回款金额权益口径 ,
                convert(MONEY,0) 本月回款金额并表口径 ,
                convert(MONEY,0) 本年回款金额 ,
                convert(MONEY,0) 本年操盘回款金额 ,
                convert(MONEY,0) 本年回款金额权益口径 ,
                convert(MONEY,0) 本年回款金额并表口径 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND ord.rgDate BETWEEN ord.QSDate
                                             AND     DATEADD(DAY, 7,
                                                             ord.QSDate)
                              AND DATEDIFF(yy, ord.QSDate, GETDATE()) = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS 本年认购日期7天之内面积 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND DATEDIFF(yy, ord.QSDate, GETDATE()) = 0
                         THEN ord.BldArea
                         ELSE 0
                    END) AS 本年认购面积 ,      
        --开盘7天转签约率（%）认购转签约日期在认购日期7天之内，7天内认购转签约的占当年认购额的比例
                SUM(CASE WHEN ord.saleType = '签约'
                              AND ord.QSDate BETWEEN ord.rgDate
                                             AND     DATEADD(DAY, 7,
                                                             ord.rgDate)
                              AND DATEDIFF(yy, ord.rgDate, GETDATE()) = 0
                         THEN ord.JyTotal
                         ELSE 0
                    END) / 10000 AS 开盘7天认购转签约签约金额 ,
                CASE WHEN ISNULL(SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                                               AND DATEDIFF(yy, ord.rgDate,
                                                            GETDATE()) = 0
                                          THEN ISNULL(ord.JyTotal, 0)
                                          ELSE 0
                                     END), 0) = 0 THEN 0
                     ELSE SUM(CASE WHEN ord.saleType = '签约'
                                        AND ord.QSDate BETWEEN ord.rgDate
                                                       AND    DATEADD(DAY, 7,
                                                              ord.rgDate)
                                        AND DATEDIFF(yy, ord.rgDate, GETDATE()) = 0
                                   THEN ord.JyTotal
                                   ELSE 0
                              END)
                          / SUM(CASE WHEN ord.saleType IN ( '认购', '签约' )
                                          AND DATEDIFF(yy, ord.rgDate,
                                                       GETDATE()) = 0
                                     THEN ISNULL(ord.JyTotal, 0)
                                     ELSE 0
                                END)
                END AS 开盘7天转签约率 ,
                SUM(CASE WHEN ord.saleType = '认购'
                              AND ord.rgDate <= GETDATE() THEN ord.JyTotal
                         ELSE 0
                    END) / 10000 AS 已认购未签约金额 ,
                SUM(CASE WHEN ord.saleType = '签约'
                              AND ord.QSDate <= GETDATE()
                              AND ISNULL(g.sstotal, 0) < ISNULL(f.ystotal, 0)
                         THEN f.RmbYe
                         ELSE 0
                    END) / 10000 AS 已签约未回款金额
        INTO    #SaleProjAmount
        FROM    erp25.dbo.ydkb_BaseInfo bi
                LEFT JOIN erp25..p_Project p1 ON p1.ProjGUID = bi.组织架构ID
                LEFT JOIN erp25..p_Project p ON p1.ProjCode = p.ParentCode
                                                AND p1.Level = 2
                LEFT JOIN ( SELECT  BUGUID ,
                                    ProjGUID ,
                                    '认购' AS saleType ,
                                    TradeGUID ,
                                    BldArea ,
                                    JyTotal ,
                                    NULL AS QSDate ,
                                    QSDate AS rgDate
                            FROM    erp25.dbo.s_Order
                            WHERE   Status = '激活'
                                    AND OrderType = '认购'
                            UNION ALL
                            SELECT  c.BUGUID ,
                                    c.ProjGUID ,
                                    '签约' AS saleType ,
                                    c.TradeGUID ,
                                    o.BldArea ,
                                    c.JyTotal ,
                                    c.QSDate ,
                                    o.QSDate AS rgDate
                            FROM    erp25.dbo.s_Contract c
                                    LEFT JOIN erp25.dbo.s_Order o ON c.TradeGUID = o.TradeGUID
                                                              AND o.Status = '关闭'
                                                              AND o.CloseReason = '转签约'
                            WHERE   c.Status = '激活'
                          ) ord ON ord.ProjGUID = p.ProjGUID
                LEFT JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = p1.ProjGUID
                LEFT JOIN ( SELECT  projGUID ,
                                    MAX(LbProjectValue) AS LbProjectValue
                            FROM    mdm_LbProject
                            WHERE   LbProject = 'cwsybl'
                            GROUP BY projGUID
                          ) lbp ON lbp.projGUID = mp.ProjGUID
                LEFT JOIN ( SELECT  TradeGUID ,
                                    SUM(RmbAmount) ystotal ,
                                    SUM(RmbYe) AS RmbYe
                            FROM    s_Fee
                            WHERE   ItemType LIKE '%房款%'
                            GROUP BY TradeGUID
                          ) f ON f.TradeGUID = ord.TradeGUID
                LEFT JOIN ( SELECT  SaleGUID ,
                                    SUM(RmbAmount) sstotal
                            FROM    s_Getin
                            WHERE   ItemType LIKE '%房款%'
                                    AND ISNULL(Status, '') <> '作废'
                            GROUP BY SaleGUID
                          ) g ON g.SaleGUID = ord.TradeGUID
        WHERE   bi.组织架构类型 = 3
                AND p1.ApplySys LIKE '%0101%'
                AND p.ApplySys LIKE '%0101%'
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型; 


----更新项目回笼数据
        UPDATE  a
        SET     a.本月回款金额 = ISNULL(b.本月累计回笼金额, 0)  ,
                a.本月操盘回款金额 = CASE WHEN mp.TradersWay <> '合作方操盘'
                                  THEN ISNULL(b.本月累计回笼金额, 0) 
                                  ELSE 0
                             END ,
                a.本月回款金额权益口径 = ( ISNULL(b.本月累计回笼金额, 0)
                                 * ISNULL(lbp.LbProjectValue, 0) / 100.00 ),
                a.本月回款金额并表口径 = CASE WHEN mp.BbWay = '我司并表'
                                    THEN ISNULL(b.本月累计回笼金额, 0)
                                    ELSE 0
                               END  ,
                a.本年回款金额 = ISNULL(b.本年累计回笼金额, 0)  ,
                a.本年操盘回款金额 = CASE WHEN mp.TradersWay <> '合作方操盘'
                                  THEN ISNULL(b.本年累计回笼金额, 0) 
                                  ELSE 0
                             END ,
                a.本年回款金额权益口径 = ( ISNULL(b.本年累计回笼金额, 0)
                                 * ISNULL(lbp.LbProjectValue, 0) / 100.00 ),
                a.本年回款金额并表口径 = CASE WHEN mp.BbWay = '我司并表'
                                    THEN ISNULL(b.本年累计回笼金额, 0)
                                    ELSE 0
                               END 
        FROM    #SaleProjAmount a
                LEFT JOIN dbo.mdm_Project mp ON a.组织架构ID = mp.ProjGUID
                LEFT JOIN ( SELECT  projGUID ,
                                    MAX(LbProjectValue) AS LbProjectValue
                            FROM    mdm_LbProject
                            WHERE   LbProject = 'cwsybl'
                            GROUP BY projGUID
                          ) lbp ON lbp.ProjGUID = mp.ProjGUID
                LEFT JOIN #s_getin b ON a.组织架构ID = b.topprojguid
        WHERE   mp.TradersWay <> '合作方操盘';

----更新非操盘销售项目数据                
        UPDATE  a
        SET     a.本月销售金额 = ISNULL(c.本月销售金额, 0) ,
                a.本年销售金额 = ISNULL(c.本年销售金额, 0) ,
                a.本年销售金额权益口径 = ISNULL(c.本年销售金额, 0) * ISNULL(lbp.LbProjectValue,
                                                            0) / 100.00 ,
                a.本年销售金额并表口径 = CASE WHEN mp.BbWay = '我司并表'
                                    THEN ISNULL(c.本年销售金额, 0)
                                    ELSE 0
                               END ,
                a.本月签约金额 = ISNULL(c.本月签约金额, 0) ,
                a.本年签约金额 = ISNULL(c.本年签约金额, 0) ,
                a.本年签约金额权益口径 = ISNULL(c.本年签约金额, 0) * ISNULL(lbp.LbProjectValue,
                                                            0) / 100.00 ,
                a.本年签约金额并表口径 = CASE WHEN mp.BbWay = '我司并表'
                                    THEN ISNULL(c.本年签约金额, 0)
                                    ELSE 0
                               END ,
                --a.本月回款金额 = ISNULL(c.本月回款金额, 0) ,
                a.本月回款金额 = ISNULL(g.本月累计回笼金额, 0)  ,
                a.本月回款金额权益口径 = ( ISNULL(g.本月累计回笼金额, 0)
                                 * ISNULL(lbp.LbProjectValue, 0) / 100.00 ) ,
                a.本月回款金额并表口径 = CASE WHEN mp.BbWay = '我司并表'
                                    THEN ISNULL(g.本月累计回笼金额, 0) 
                                    ELSE 0
                               END ,
                --a.本年回款金额 = ISNULL(c.本年回款金额, 0) ,
                a.本年回款金额 = ISNULL(g.本年累计回笼金额, 0)  ,
                a.本年回款金额权益口径 = ( ISNULL(g.本年累计回笼金额, 0)
                                 * ISNULL(lbp.LbProjectValue, 0) / 100.00 ),
                a.本年回款金额并表口径 = CASE WHEN mp.BbWay = '我司并表'
                                    THEN ISNULL(g.本年累计回笼金额, 0) 
                                    ELSE 0
                               END
        FROM    #SaleProjAmount a
                INNER  JOIN dbo.mdm_Project mp ON a.组织架构ID = mp.ProjGUID
                LEFT JOIN ( SELECT  projGUID ,
                                    MAX(LbProjectValue) AS LbProjectValue
                            FROM    mdm_LbProject
                            WHERE   LbProject = 'cwsybl'
                            GROUP BY projGUID
                          ) lbp ON lbp.ProjGUID = mp.ProjGUID
                INNER   JOIN ( SELECT   p.ProjGUID ,
                                        SUM(CASE WHEN DATEDIFF(mm, b.BizDate,
                                                              GETDATE()) = 0
                                                 THEN a.Amount
                                                 ELSE 0
                                            END) AS 本月销售金额 , --单位万元
                                        SUM(CASE WHEN DATEDIFF(mm, b.BizDate,
                                                              GETDATE()) = 0
                                                 THEN a.Amount
                                                 ELSE 0
                                            END) AS 本月签约金额 ,
                                        SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                              GETDATE()) = 0
                                                 THEN a.Amount
                                                 ELSE 0
                                            END) AS 本年销售金额 ,
                                        SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                              GETDATE()) = 0
                                                 THEN a.Amount
                                                 ELSE 0
                                            END) AS 本年签约金额 ,
                                        SUM(CASE WHEN DATEDIFF(mm, b.BizDate,
                                                              GETDATE()) = 0
                                                 THEN a.huilongjiner
                                                 ELSE 0
                                            END) AS 本月回款金额 ,
                                        SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                              GETDATE()) = 0
                                                 THEN a.huilongjiner
                                                 ELSE 0
                                            END) AS 本年回款金额
                               FROM     dbo.s_YJRLProducteDescript a
                                        LEFT JOIN ( SELECT  * ,
                                                            CONVERT(DATETIME, b.DateYear
                                                            + '-'
                                                            + b.DateMonth
                                                            + '-01') AS [BizDate]
                                                    FROM    dbo.s_YJRLProducteDetail b
                                                  ) b ON b.ProducteDetailGUID = a.ProducteDetailGUID
                                        LEFT JOIN dbo.s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
                                        LEFT JOIN dbo.mdm_Project p ON p.ProjGUID = c.ProjGUID
                               WHERE    b.Shenhe = '审核'
                               GROUP BY p.ProjGUID
                             ) c ON c.ProjGUID = mp.ProjGUID
                LEFT JOIN #s_getin g ON a.组织架构ID = g.topprojguid;


---实际成本直投完成情况
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#PayProjAmount')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #PayProjAmount;
            END; 
         
        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                ISNULL(pay.本月度实付金额, 0) AS 本月度实付金额 ,
                ISNULL(pay.本季度实付金额, 0) AS 本季度实付金额 ,
                ISNULL(pay.本年度实付金额, 0) + +ISNULL(ts.bnZtAmount, 0) AS 本年度实付金额
        INTO    #PayProjAmount
        FROM    erp25.dbo.ydkb_BaseInfo bi
                LEFT JOIN ( SELECT  a.ProjGUID ,
                                    SUM(CASE WHEN DATEDIFF(mm, a.PayDate,
                                                           GETDATE()) = 0
                                             THEN a.pj
                                             ELSE 0
                                        END) / 10000 AS '本月度实付金额' ,
                                    SUM(CASE WHEN DATEDIFF(qq, a.PayDate,
                                                           GETDATE()) = 0
                                             THEN a.pj
                                             ELSE 0
                                        END) / 10000 AS '本季度实付金额' ,
                                    SUM(a.pj) / 10000 AS '本年度实付金额'
                            FROM    ( SELECT    p.BUGUID ,
                                                pp.ProjGUID ,
                                                p.PayDate ,
                                                p.PayAmount ,
                                                pj.ts ,
                                                p.PayAmount / pj.ts pj
                                      FROM      myCost_erp352.dbo.cb_Pay p
                                                LEFT JOIN myCost_erp352.dbo.vcb_Contract c ON c.ContractGUID = p.ContractGUID
                                                LEFT JOIN myCost_erp352.dbo.cb_ContractProj cb ON p.ContractGUID = cb.ContractGUID
                                                LEFT JOIN ( SELECT
                                                              ContractGUID ,
                                                              COUNT(1) ts
                                                            FROM
                                                              myCost_erp352.dbo.cb_ContractProj
                                                            GROUP BY ContractGUID
                                                          ) pj ON p.ContractGUID = pj.ContractGUID
                                                LEFT JOIN myCost_erp352.dbo.p_Project p1 ON p1.ProjGUID = cb.ProjGUID
                                                LEFT JOIN myCost_erp352.dbo.p_Project pp ON pp.ProjCode = p1.ParentCode
                                      WHERE     YEAR(p.PayDate) = YEAR(GETDATE())
                                                AND c.HtTypeName NOT LIKE '%管理%'
                                                AND c.HtTypeName NOT LIKE '%营销%'
                                                AND c.HtTypeName NOT LIKE '%财务%'
                                                AND c.HtTypeName NOT LIKE '%土地%'
                                                --AND ( p1.projcode NOT LIKE '%0757039%'
                                                --      AND p1.projcode NOT LIKE '%0757042%'
                                                --      AND p1.projcode NOT LIKE '%0757027%'
                                                --      AND p1.projcode NOT LIKE '%0757057%'
                                                --    )
                                    ) a
                            GROUP BY a.ProjGUID
                          ) pay ON pay.ProjGUID = bi.组织架构ID
                LEFT JOIN ydkb_ts_ztProjData ts ON ts.ProjGUID = bi.组织架构ID --增加特殊直投金额录入
        WHERE   bi.组织架构类型 = 3;


  
 --插入一级项目     
        INSERT  INTO dbo.ydkb_jyyj
                ( 组织架构ID ,
                  组织架构名称 ,
                  组织架构编码 ,
                  组织架构类型 ,
                  本月销售任务金额 ,
                  本月操盘销售任务金额 ,
                  本月签约任务金额 ,
                  本月操盘签约任务金额 ,
                  本月产成品任务金额 ,
                  本月回款任务金额 ,
                  本月操盘回款任务金额 ,
                  本月成本直投任务金额 ,
                  本月销售金额 ,
                  本月操盘销售金额 ,
                  本月签约金额 ,
                  本月操盘签约金额 ,
                  本月产成品金额 ,
                  本月回款金额 ,
                  本月操盘回款金额 ,
                  本月回款金额权益口径 ,
                  本月回款金额并表口径 ,
                  本月成本直投金额 ,
                  本月销售完成率 ,
                  本月签约完成率 ,
                  本月产成品完成率 ,
                  本月回款完成率 ,
                  本年销售任务金额 ,
                  本年签约任务金额 ,
                  本年产成品任务金额 ,
                  本年回款任务金额 ,
                  本年成本直投任务金额 ,
                  本年投资拓展任务金额 ,
                  本年销售金额 ,
                  本年销售金额权益口径 ,
                  本年销售金额并表口径 ,
                  本年操盘销售金额 ,
                  本年签约金额 ,
                  本年签约金额权益口径 ,
                  本年签约金额并表口径 ,
                  本年操盘签约金额 ,
                  本年产成品金额 ,
                  本年回款金额 ,
                  本年操盘回款金额 ,
                  本年回款金额权益口径 ,
                  本年回款金额并表口径 ,
                  本年成本直投金额 ,
                  本年投资拓展金额 ,
                  本年销售完成率 ,
                  本年签约完成率 ,
                  本年产成品完成率 ,
                  本年回款完成率 ,
                  本季度成本直投任务金额 ,
                  本季度成本直投金额 ,
                  本季度成本直投完成率 ,
                  JanFeb新货推货面积 ,
                  JanFeb存货推货面积 ,
                  JanFeb新货认购面积 ,
                  JanFeb存货签约面积 ,
                  JanFeb新货去化率 ,
                  JanFeb存货去化率 ,
                  JanFeb综合去化率 ,
                  Mar新货推货面积 ,
                  Mar存货推货面积 ,
                  Mar新货认购面积 ,
                  Mar存货签约面积 ,
                  Mar新货去化率 ,
                  Mar存货去化率 ,
                  Mar综合去化率 ,
                  Apr新货推货面积 ,
                  Apr存货推货面积 ,
                  Apr新货认购面积 ,
                  Apr存货签约面积 ,
                  Apr新货去化率 ,
                  Apr存货去化率 ,
                  Apr综合去化率 ,
                  May新货推货面积 ,
                  May存货推货面积 ,
                  May新货认购面积 ,
                  May存货签约面积 ,
                  May新货去化率 ,
                  May存货去化率 ,
                  May综合去化率 ,
                  Jun新货推货面积 ,
                  Jun存货推货面积 ,
                  Jun新货认购面积 ,
                  Jun存货签约面积 ,
                  Jun新货去化率 ,
                  Jun存货去化率 ,
                  Jun综合去化率 ,
                  July新货推货面积 ,
                  July存货推货面积 ,
                  July新货认购面积 ,
                  July存货签约面积 ,
                  July新货去化率 ,
                  July存货去化率 ,
                  July综合去化率 ,
                  Aug新货推货面积 ,
                  Aug存货推货面积 ,
                  Aug新货认购面积 ,
                  Aug存货签约面积 ,
                  Aug新货去化率 ,
                  Aug存货去化率 ,
                  Aug综合去化率 ,
                  Sep新货推货面积 ,
                  Sep存货推货面积 ,
                  Sep新货认购面积 ,
                  Sep存货签约面积 ,
                  Sep新货去化率 ,
                  Sep存货去化率 ,
                  Sep综合去化率 ,
                  Oct新货推货面积 ,
                  Oct存货推货面积 ,
                  Oct新货认购面积 ,
                  Oct存货签约面积 ,
                  Oct新货去化率 ,
                  Oct存货去化率 ,
                  Oct综合去化率 ,
                  Nov新货推货面积 ,
                  Nov存货推货面积 ,
                  Nov新货认购面积 ,
                  Nov存货签约面积 ,
                  Nov新货去化率 ,
                  Nov存货去化率 ,
                  Nov综合去化率 ,
                  Dec新货推货面积 ,
                  Dec存货推货面积 ,
                  Dec新货认购面积 ,
                  Dec存货签约面积 ,
                  Dec新货去化率 ,
                  Dec存货去化率 ,
                  Dec综合去化率 ,
                  本年新货推货面积 ,
                  本年存货推货面积 ,
                  本年新货认购面积 ,
                  本年存货签约面积 ,
                  本年新货去化率 ,
                  本年存货去化率 ,
                  本年综合去化率 ,
                  开盘7天认购转签约签约金额 ,
                  开盘7天转签约率 ,
                  已认购未签约金额 ,
                  已签约未回款金额  
                )
                SELECT  bi.组织架构ID ,
                        bi.组织架构名称 ,
                        bi.组织架构编码 ,
                        bi.组织架构类型 ,
                        yd.本月销售任务 AS bySaleTaskAmount ,
                        yd.本月操盘销售任务 ,
                        yd.本月签约任务 AS byqyTaskAmount ,
                        yd.本月操盘签约任务 ,
                        yd.本月产成品任务 AS byccpTaskAmount ,
                        yd.本月回笼任务 AS byhlTaskAmount ,
                        yd.本月操盘回笼任务 ,
                        ISNULL(yd.本月成本直投任务, 0) AS byztTaskAmount ,
                        qy.本月销售金额 AS bySaleAmount ,
                        qy.本月操盘销售金额 ,
                        qy.本月签约金额 AS byqyAmount ,
                        qy.本月操盘签约金额 ,
                        ISNULL(PC.本月产成品签约金额, 0) AS byccpAmount ,
                        ISNULL(qy.本月回款金额, 0) AS 本月回款金额 ,
                        ISNULL(qy.本月操盘回款金额, 0) ,
                        ISNULL(qy.本月回款金额权益口径, 0) AS 本月回款金额权益口径 ,
                        ISNULL(qy.本月回款金额并表口径, 0) AS 本月回款金额并表口径 ,
                        pp.本月度实付金额 AS 本月度实付金额 ,
                        CASE WHEN ISNULL(yd.本月销售任务, 0) = 0 THEN 0
                             ELSE ISNULL(qy.本月销售金额, 0) * 1.00
                                  / ISNULL(yd.本月销售任务, 0)
                        END AS 本月销售完成率 ,
                        CASE WHEN ISNULL(yd.本月签约任务, 0) = 0 THEN 0
                             ELSE ISNULL(qy.本月签约金额, 0) * 1.00
                                  / ISNULL(yd.本月签约任务, 0)
                        END AS 本月签约完成率 ,
                        CASE WHEN ISNULL(yd.本月产成品任务, 0) = 0 THEN 0
                             ELSE ISNULL(PC.本月产成品签约金额, 0) / ISNULL(yd.本月产成品任务,
                                                              0) * 1.00
                        END AS 本月产成品任务完成率 ,
                        CASE WHEN ISNULL(yd.本月回笼任务, 0) = 0 THEN 0
                             ELSE ( ISNULL(qy.本月回款金额, 0) ) * 1.00
                                  / ISNULL(yd.本月回笼任务, 0)
                        END AS 本月回款完成率 ,
                        nd.本年销售任务 AS bnSaleTaskAmount ,
                        nd.本年签约任务 AS bnqyTaskAmount ,
                        nd.本年产成品任务 AS bnccpTaskAmount ,
                        nd.本年回笼任务 AS bnhlTaskAmount ,
                        ISNULL(nd.本年成本直投任务, 0) AS 本年成本直投任务金额 ,
                        ISNULL(hntz.rw, 0) * 10000 AS 本年投资拓展任务金额 ,
                        ISNULL(qy.本年销售金额, 0) + ISNULL(ts.TotalAmount, 0) AS bnSalemount , --本年签约金额加上特殊业绩录入
                        ISNULL(qy.本年销售金额权益口径, 0) ,
                        ISNULL(qy.本年销售金额并表口径, 0) ,
                        ISNULL(qy.本年操盘销售金额, 0) + ISNULL(ts.TotalAmount, 0) ,
                        ISNULL(qy.本年签约金额, 0) + ISNULL(ts.TotalAmount, 0) AS bnqyAmount , --本年签约金额加上特殊业绩录入
                        ISNULL(qy.本年签约金额权益口径, 0) ,
                        ISNULL(qy.本年签约金额并表口径, 0) ,
                        ISNULL(qy.本年操盘签约金额, 0) + ISNULL(ts.TotalAmount, 0) ,
                        ISNULL(PC.本年产成品签约金额, 0) AS bnccpAmount ,
                        ISNULL(qy.本年回款金额, 0) AS 本年回款金额 , --本年回笼金额加上特殊业绩录入
                        ISNULL(qy.本年操盘回款金额, 0) ,
                        ISNULL(qy.本年回款金额权益口径, 0) AS 本年回款金额权益口径 ,
                        ISNULL(qy.本年回款金额并表口径, 0) AS 本年回款金额并表口径 ,
                        pp.本年度实付金额 AS 本年度实付金额 ,
                        ISNULL(hntz.sj, 0) * 10000 AS 本年投资拓展任务金额 ,
                        CASE WHEN ISNULL(nd.本年销售任务, 0) = 0 THEN 0
                             ELSE ( ISNULL(qy.本年销售金额, 0)
                                    + ISNULL(ts.TotalAmount, 0) ) * 1.00
                                  / ISNULL(nd.本年销售任务, 0)
                        END AS 本年销售完成率 ,
                        CASE WHEN ISNULL(nd.本年签约任务, 0) = 0 THEN 0
                             ELSE ( ISNULL(qy.本年签约金额, 0)
                                    + ISNULL(ts.TotalAmount, 0) ) * 1.00
                                  / ISNULL(nd.本年签约任务, 0)
                        END AS 本年签约完成率 ,
                        CASE WHEN ISNULL(nd.本年产成品任务, 0) = 0 THEN 0
                             ELSE ISNULL(PC.本年产成品签约金额, 0) / ISNULL(nd.本年产成品任务,
                                                              0) * 1.00
                        END AS 本年产成品任务完成率 ,
                        CASE WHEN ISNULL(nd.本年回笼任务, 0) = 0 THEN 0
                             ELSE ( ISNULL(qy.本年回款金额, 0) ) * 1.00
                                  / ISNULL(nd.本年回笼任务, 0)
                        END AS bnhlCompletionRate ,
                        0 AS 本季度成本直投任务金额 ,
                        pp.本季度实付金额 AS 本季度成本直投金额 ,
                        0 AS 本季度成本直投完成率 ,
                        ISNULL(pq.Jan新货推货面积, 0) + ISNULL(pq.Feb新货推货面积, 0) AS JanFeb新货推货面积 ,
                        ISNULL(pq.Jan存货推货面积, 0) + ISNULL(pq.Feb存货推货面积, 0) AS JanFeb存货推货面积 ,
                        ISNULL(pq.Jan新货认购面积, 0) + ISNULL(pq.Feb新货认购面积, 0) AS JanFeb新货认购面积 ,
                        ISNULL(pq.Jan存货签约面积, 0) + ISNULL(pq.Feb存货签约面积, 0) AS JanFeb存货签约面积 ,
                        CASE WHEN ( ISNULL(pq.Jan新货推货面积, 0)
                                    + ISNULL(pq.Feb新货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(pq.Jan新货认购面积, 0)
                                    + ISNULL(pq.Feb新货认购面积, 0) ) * 1.00
                                  / ( ISNULL(pq.Jan新货推货面积, 0)
                                      + ISNULL(pq.Feb新货推货面积, 0) )
                        END AS JanFeb新货去化率 ,
                        CASE WHEN ( ISNULL(pq.Jan存货推货面积, 0)
                                    + ISNULL(pq.Feb存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(pq.Jan存货签约面积, 0)
                                    + ISNULL(pq.Feb存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(pq.Jan存货推货面积, 0)
                                      + ISNULL(pq.Feb存货推货面积, 0) )
                        END AS JanFeb存货去化率 ,
                        CASE WHEN ( ISNULL(pq.Jan新货推货面积, 0)
                                    + ISNULL(pq.Feb新货推货面积, 0)
                                    + ISNULL(pq.Jan存货推货面积, 0)
                                    + ISNULL(pq.Feb存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(pq.Jan新货认购面积, 0)
                                    + ISNULL(pq.Feb新货认购面积, 0)
                                    + ISNULL(pq.Jan存货签约面积, 0)
                                    + ISNULL(pq.Feb存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(pq.Jan新货推货面积, 0)
                                      + ISNULL(pq.Feb新货推货面积, 0)
                                      + ISNULL(pq.Jan存货推货面积, 0)
                                      + ISNULL(pq.Feb存货推货面积, 0) )
                        END AS JanFeb综合去化率 ,
                        pq.Mar新货推货面积 AS Mar新货推货面积 ,
                        pq.Mar存货推货面积 AS Mar存货推货面积 ,
                        pq.Mar新货认购面积 AS Mar新货认购面积 ,
                        pq.Mar存货签约面积 AS Mar存货签约面积 ,
                        CASE WHEN ISNULL(pq.Mar新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Mar新货认购面积, 0) * 1.00
                                  / ISNULL(pq.Mar新货推货面积, 0)
                        END AS Mar新货去化率 ,
                        CASE WHEN ISNULL(pq.Mar存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Mar存货签约面积, 0) * 1.00
                                  / ISNULL(pq.Mar存货推货面积, 0)
                        END AS Mar存货去化率 ,
                        CASE WHEN ( ISNULL(pq.Mar新货推货面积, 0)
                                    + ISNULL(pq.Mar存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(pq.Mar新货认购面积, 0)
                                    + ISNULL(pq.Mar存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(pq.Mar新货推货面积, 0)
                                      + ISNULL(pq.Mar存货推货面积, 0) )
                        END AS Mar综合去化率 ,
                        pq.Apr新货推货面积 AS Apr新货推货面积 ,
                        pq.Apr存货推货面积 AS Apr存货推货面积 ,
                        pq.Apr新货认购面积 AS Apr新货认购面积 ,
                        pq.Apr存货签约面积 AS Apr存货签约面积 ,
                        CASE WHEN ISNULL(pq.Apr新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Apr新货认购面积, 0) * 1.00
                                  / ISNULL(pq.Apr新货推货面积, 0)
                        END AS Apr新货去化率 ,
                        CASE WHEN ISNULL(pq.Apr存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Apr存货签约面积, 0) * 1.00
                                  / ISNULL(pq.Apr存货推货面积, 0)
                        END AS Apr存货去化率 ,
                        CASE WHEN ( ISNULL(pq.Apr新货推货面积, 0)
                                    + ISNULL(pq.Apr存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(pq.Apr新货认购面积, 0)
                                    + ISNULL(pq.Apr存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(pq.Apr新货推货面积, 0)
                                      + ISNULL(pq.Apr存货推货面积, 0) )
                        END AS Apr综合去化率 ,
                        pq.May新货推货面积 AS May新货推货面积 ,
                        pq.May存货推货面积 AS May存货推货面积 ,
                        pq.May新货认购面积 AS May新货认购面积 ,
                        pq.May存货签约面积 AS May存货签约面积 ,
                        CASE WHEN ISNULL(pq.May新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.May新货认购面积, 0) * 1.00
                                  / ISNULL(pq.May新货推货面积, 0)
                        END AS May新货去化率 ,
                        CASE WHEN ISNULL(pq.May存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.May存货签约面积, 0) * 1.00
                                  / ISNULL(pq.May存货推货面积, 0)
                        END AS May存货去化率 ,
                        CASE WHEN ( ISNULL(pq.May新货推货面积, 0)
                                    + ISNULL(pq.May存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(pq.May新货认购面积, 0)
                                    + ISNULL(pq.May存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(pq.May新货推货面积, 0)
                                      + ISNULL(pq.May存货推货面积, 0) )
                        END AS May综合去化率 ,
                        pq.Jun新货推货面积 AS Jun新货推货面积 ,
                        pq.Jun存货推货面积 AS Jun存货推货面积 ,
                        pq.Jun新货认购面积 AS Jun新货认购面积 ,
                        pq.Jun存货签约面积 AS Jun存货签约面积 ,
                        CASE WHEN ISNULL(pq.Jun新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Jun新货认购面积, 0) * 1.00
                                  / ISNULL(pq.Jun新货推货面积, 0)
                        END AS Jun新货去化率 ,
                        CASE WHEN ISNULL(pq.Jun存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Jun存货签约面积, 0) * 1.00
                                  / ISNULL(pq.Jun存货推货面积, 0)
                        END AS Jun存货去化率 ,
                        CASE WHEN ( ISNULL(pq.Jun新货推货面积, 0)
                                    + ISNULL(pq.Jun存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(pq.Jun新货认购面积, 0)
                                    + ISNULL(pq.Jun存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(pq.Jun新货推货面积, 0)
                                      + ISNULL(pq.Jun存货推货面积, 0) )
                        END AS Jun综合去化率 ,
                        pq.July新货推货面积 AS July新货推货面积 ,
                        pq.July存货推货面积 AS July存货推货面积 ,
                        pq.July新货认购面积 AS July新货认购面积 ,
                        pq.July存货签约面积 AS July存货签约面积 ,
                        CASE WHEN ISNULL(pq.July新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.July新货认购面积, 0) * 1.00
                                  / ISNULL(pq.July新货推货面积, 0)
                        END AS July新货去化率 ,
                        CASE WHEN ISNULL(pq.July存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.July存货签约面积, 0) * 1.00
                                  / ISNULL(pq.July存货推货面积, 0)
                        END AS July存货去化率 ,
                        CASE WHEN ( ISNULL(pq.July新货推货面积, 0)
                                    + ISNULL(pq.July存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(pq.July新货认购面积, 0)
                                    + ISNULL(pq.July存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(pq.July新货推货面积, 0)
                                      + ISNULL(pq.July存货推货面积, 0) )
                        END AS July综合去化率 ,
                        pq.Aug新货推货面积 AS Aug新货推货面积 ,
                        pq.Aug存货推货面积 AS Aug存货推货面积 ,
                        pq.Aug新货认购面积 AS Aug新货认购面积 ,
                        pq.Aug存货签约面积 AS Aug存货签约面积 ,
                        CASE WHEN ISNULL(pq.Aug新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Aug新货认购面积, 0) * 1.00
                                  / ISNULL(pq.Aug新货推货面积, 0)
                        END AS Aug新货去化率 ,
                        CASE WHEN ISNULL(pq.Aug存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Aug存货签约面积, 0) * 1.00
                                  / ISNULL(pq.Aug存货推货面积, 0)
                        END AS Aug存货去化率 ,
                        CASE WHEN ( ISNULL(pq.Aug新货推货面积, 0)
                                    + ISNULL(pq.Aug存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(pq.Aug新货认购面积, 0)
                                    + ISNULL(pq.Aug存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(pq.Aug新货推货面积, 0)
                                      + ISNULL(pq.Aug存货推货面积, 0) )
                        END AS Aug综合去化率 ,
                        pq.Sep新货推货面积 AS Sep新货推货面积 ,
                        pq.Sep存货推货面积 AS Sep存货推货面积 ,
                        pq.Sep新货认购面积 AS Sep新货认购面积 ,
                        pq.Sep存货签约面积 AS Sep存货签约面积 ,
                        CASE WHEN ISNULL(pq.Sep新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Sep新货认购面积, 0) * 1.00
                                  / ISNULL(pq.Sep新货推货面积, 0)
                        END AS Sep新货去化率 ,
                        CASE WHEN ISNULL(pq.Sep存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Sep存货签约面积, 0) * 1.00
                                  / ISNULL(pq.Sep存货推货面积, 0)
                        END AS Sep存货去化率 ,
                        CASE WHEN ( ISNULL(pq.Sep新货推货面积, 0)
                                    + ISNULL(pq.Sep存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(pq.Sep新货认购面积, 0)
                                    + ISNULL(pq.Sep存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(pq.Sep新货推货面积, 0)
                                      + ISNULL(pq.Sep存货推货面积, 0) )
                        END AS Sep综合去化率 ,
                        pq.Oct新货推货面积 AS Oct新货推货面积 ,
                        pq.Oct存货推货面积 AS Oct存货推货面积 ,
                        pq.Oct新货认购面积 AS Oct新货认购面积 ,
                        pq.Oct存货签约面积 AS Oct存货签约面积 ,
                        CASE WHEN ISNULL(pq.Oct新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Oct新货认购面积, 0) * 1.00
                                  / ISNULL(pq.Oct新货推货面积, 0)
                        END AS Oct新货去化率 ,
                        CASE WHEN ISNULL(pq.Oct存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Oct存货签约面积, 0) * 1.00
                                  / ISNULL(pq.Oct存货推货面积, 0)
                        END AS Oct存货去化率 ,
                        CASE WHEN ( ISNULL(pq.Oct新货推货面积, 0)
                                    + ISNULL(pq.Oct存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(pq.Oct新货认购面积, 0)
                                    + ISNULL(pq.Oct存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(pq.Oct新货推货面积, 0)
                                      + ISNULL(pq.Oct存货推货面积, 0) )
                        END AS Oct综合去化率 ,
                        pq.Nov新货推货面积 AS Nov新货推货面积 ,
                        pq.Nov存货推货面积 AS Nov存货推货面积 ,
                        pq.Nov新货认购面积 AS Nov新货认购面积 ,
                        pq.Nov存货签约面积 AS Nov存货签约面积 ,
                        CASE WHEN ISNULL(pq.Nov新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Nov新货认购面积, 0) * 1.00
                                  / ISNULL(pq.Nov新货推货面积, 0)
                        END AS Nov新货去化率 ,
                        CASE WHEN ISNULL(pq.Nov存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Nov存货签约面积, 0) * 1.00
                                  / ISNULL(pq.Nov存货推货面积, 0)
                        END AS Nov存货去化率 ,
                        CASE WHEN ( ISNULL(pq.Nov新货推货面积, 0)
                                    + ISNULL(pq.Nov存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(pq.Nov新货认购面积, 0)
                                    + ISNULL(pq.Nov存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(pq.Nov新货推货面积, 0)
                                      + ISNULL(pq.Nov存货推货面积, 0) )
                        END AS Nov综合去化率 ,
                        pq.Dec新货推货面积 AS Dec新货推货面积 ,
                        pq.Dec存货推货面积 AS Dec存货推货面积 ,
                        pq.Dec新货认购面积 AS Dec新货认购面积 ,
                        pq.Dec存货签约面积 AS Dec存货签约面积 ,
                        CASE WHEN ISNULL(pq.Dec新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Dec新货认购面积, 0) * 1.00
                                  / ISNULL(pq.Dec新货推货面积, 0)
                        END AS Dec新货去化率 ,
                        CASE WHEN ISNULL(pq.Dec存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.Dec存货签约面积, 0) * 1.00
                                  / ISNULL(pq.Dec存货推货面积, 0)
                        END AS Dec存货去化率 ,
                        CASE WHEN ( ISNULL(pq.Dec新货推货面积, 0)
                                    + ISNULL(pq.Dec存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(pq.Dec新货认购面积, 0)
                                    + ISNULL(pq.Dec存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(pq.Dec新货推货面积, 0)
                                      + ISNULL(pq.Dec存货推货面积, 0) )
                        END AS Dec综合去化率 ,
                        ----------------------------------------------------------
                        ISNULL(pq.本年新货推货面积, 0) AS 本年新货推货面积 ,
                        ISNULL(pq.本年存货推货面积, 0) AS 本年存货推货面积 ,
                        ISNULL(pq.本年新货认购面积, 0) AS 本年新货认购面积 ,
                        ISNULL(pq.本年存货签约面积, 0) AS 本年存货签约面积 ,
                        CASE WHEN ISNULL(pq.本年新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.本年新货认购面积, 0) * 1.00
                                  / ISNULL(pq.本年新货推货面积, 0)
                        END AS 本年新货去化率 ,
                        CASE WHEN ISNULL(pq.本年存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(pq.本年存货签约面积, 0) * 1.00
                                  / ISNULL(pq.本年存货推货面积, 0)
                        END AS 本年存货去化率 ,
                        CASE WHEN ( ISNULL(pq.本年新货推货面积, 0)
                                    + ISNULL(pq.本年存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(pq.本年新货认购面积, 0)
                                    + ISNULL(pq.本年存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(pq.本年新货推货面积, 0)
                                      + ISNULL(pq.本年存货推货面积, 0) )
                        END AS 本年综合去化率 ,
                        qy.开盘7天认购转签约签约金额 ,
                        qy.开盘7天转签约率 ,
                        已认购未签约金额 ,
                        已签约未回款金额
                FROM    ydkb_BaseInfo bi
                        LEFT JOIN #ydProjTask yd ON yd.组织架构ID = bi.组织架构ID
                        LEFT JOIN #ndProjTask nd ON nd.组织架构ID = bi.组织架构ID
                        LEFT JOIN #SaleProjAmount qy ON qy.组织架构ID = bi.组织架构ID
                        LEFT JOIN #PayProjAmount pp ON pp.组织架构ID = bi.组织架构ID
                        LEFT JOIN #ProjSaleQh pq ON pq.组织架构ID = bi.组织架构ID
                        LEFT JOIN #projccbSaleTemp PC ON PC.ProjGUID = bi.组织架构ID
                        LEFT JOIN #tsProjSaleAmount ts ON ts.组织架构ID = bi.组织架构ID
                        LEFT JOIN s_hntzrw hntz ON hntz.rwguid = bi.组织架构ID
                                                   AND hntz.Level = 3
                WHERE   bi.组织架构类型 = 3;
                        --AND bi.操盘方式 <> '合作方操盘';
                        --AND bi.组织架构ID NOT  IN (
                        --'7081EF46-2814-E711-80BA-E61F13C57837',
                        --'31783072-6849-E811-80BA-E61F13C57837',
                        --'CACA1201-F746-E811-80BA-E61F13C57837',
                        --'445AD138-A747-E811-80BA-E61F13C57837',
                        --'B3363602-A589-E811-80BF-E61F13C57837' );
        



/*插入平台公司数据,取项目公司的汇总数据，城市公司任务汇总数据加上非操盘项目的汇总*/   
 
 --获取平台公司月度任务
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ydCompanyTask')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #ydCompanyTask;
            END;  

        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                s.本月销售任务 AS 本月销售任务 ,
                s.本月操盘销售任务 ,
                s.本月签约任务 AS 本月签约任务 ,
                s.本月操盘签约任务 ,
                s.本月回笼任务 AS 本月回笼任务 ,
                s.本月操盘回笼任务 ,
                ISNULL(cp.本月产成品任务, 0) AS 本月产成品任务 ,
                0 AS 本月成本直投任务
        INTO    #ydCompanyTask
        FROM    erp25.dbo.ydkb_BaseInfo bi --LEFT JOIN erp25.dbo.s_SaleTaskList s ON bi.组织架构ID = s.BUGUID
                --LEFT JOIN erp25.dbo.s_SaleTask t ON s.TaskGUID = t.TaskGUID
                LEFT JOIN ( SELECT  bi.平台公司GUID ,
                                    SUM(s.RgTask) AS 本月销售任务 ,
                                    SUM(CASE WHEN mp.TradersWay <> '合作方操盘'
                                             THEN s.RgTask
                                             ELSE 0
                                        END) AS 本月操盘销售任务 ,
                                    SUM(s.SigningTask) AS 本月签约任务 ,
                                    SUM(CASE WHEN mp.TradersWay <> '合作方操盘'
                                             THEN s.SigningTask
                                             ELSE 0
                                        END) AS 本月操盘签约任务 ,
                                    SUM(s.PaymentTask) AS 本月回笼任务 ,
                                    SUM(CASE WHEN mp.TradersWay <> '合作方操盘'
                                             THEN s.PaymentTask
                                             ELSE 0
                                        END) AS 本月操盘回笼任务
                            FROM    erp25.dbo.ydkb_BaseInfo bi
                                    LEFT JOIN s_SaleProjectTaskList s ON bi.组织架构ID = s.ProjectGUID
                                    LEFT JOIN erp25.dbo.s_SaleProjectTask t ON s.ProjectTaskGUID = t.ProjectTaskGUID
                                    LEFT JOIN erp25.dbo.mdm_Project mp ON bi.组织架构ID = mp.ProjGUID
                            WHERE   t.Syear = YEAR(GETDATE())
                                    AND t.Smonth = MONTH(GETDATE())
                                    AND t.TaskPUnit = '月度'
                            GROUP BY bi.平台公司GUID
                          ) s ON s.平台公司GUID = bi.平台公司GUID
                LEFT JOIN ( SELECT  b3.组织架构ID ,
                                    SUM(a.年度产成品任务) * 10000 AS 年产成品任务 ,
                                    SUM(a.[本月份产成品任务]) * 10000 AS 本月产成品任务
                            FROM    erp25.dbo.ykdb_hn_ccpTask a
                                    LEFT JOIN erp25.dbo.ydkb_BaseInfo b ON a.项目GUID = b.组织架构ID
                                    LEFT JOIN erp25.dbo.ydkb_BaseInfo b2 ON b2.组织架构ID = b.组织架构父级ID
                                    LEFT JOIN erp25.dbo.ydkb_BaseInfo b3 ON b3.组织架构ID = b2.组织架构父级ID
                            WHERE   b.组织架构类型 = 3
                            GROUP BY b3.组织架构ID
                          ) cp ON cp.组织架构ID = bi.组织架构ID
        WHERE   bi.组织架构类型 = 1;
         


--获取平台公司季度任务
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#jdCompanyTask')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #jdCompanyTask;
            END;  
            
        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                s.本季度成本直投任务 AS 本季度成本直投任务
        INTO    #jdCompanyTask
        FROM    erp25.dbo.ydkb_BaseInfo bi
                LEFT JOIN ( SELECT  t.BUGUID ,
                                    SUM(CASE WHEN t.Smonth = DATEPART(QUARTER,
                                                              GETDATE())
                                             THEN s.CbztTask
                                             ELSE 0
                                        END) AS 本季度成本直投任务
                            FROM    erp25.dbo.s_SaleCityTaskList s
                                    LEFT JOIN erp25.dbo.s_SaleCityTask t ON s.CityTaskGUID = t.CityTaskGUID
                            WHERE   t.Syear = YEAR(GETDATE())
                                    AND t.TaskPUnit = '月度'
                            GROUP BY t.BUGUID
                          ) s ON s.BUGUID = bi.组织架构ID
        WHERE   bi.组织架构类型 = 1;

      
--获取平台公司年度任务
/*
2、本年签约任务金额555亿元、回款任务488亿元、产成品任务52.63亿元。（全口径）
华南公司全口径年度签约任务、回款任务取自销售系统-销售任务-项目任务模块项目汇总数
*/
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ndCompanyTask')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #ndCompanyTask;
            END;  


        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                s.本年销售任务 AS 本年销售任务 ,
                s.本年操盘销售任务 AS 本年操盘销售任务 ,
                s.本年签约任务 AS 本年签约任务 ,
                s.本年操盘签约任务 AS 本年操盘签约任务 ,
                s.本年回笼任务 AS 本年回笼任务 ,
                s.本年操盘回笼任务 AS 本年操盘回笼任务 ,
                zt.本年成本直投任务 AS 本年成本直投任务 ,
                ISNULL(cp.年产成品任务, 0) AS 本年产成品任务
        INTO    #ndCompanyTask
        FROM    erp25.dbo.ydkb_BaseInfo bi
                LEFT JOIN ( SELECT  bi.平台公司GUID ,
                                    SUM(s.RgTask) AS 本年销售任务 ,
                                    SUM(CASE WHEN mp.TradersWay <> '合作方操盘'
                                             THEN s.RgTask
                                             ELSE 0
                                        END) AS 本年操盘销售任务 ,
                                    SUM(s.SigningTask) AS 本年签约任务 ,
                                    SUM(CASE WHEN mp.TradersWay <> '合作方操盘'
                                             THEN s.SigningTask
                                             ELSE 0
                                        END) AS 本年操盘签约任务 ,
                                    SUM(s.PaymentTask) AS 本年回笼任务 ,
                                    SUM(CASE WHEN mp.TradersWay <> '合作方操盘'
                                             THEN s.PaymentTask
                                             ELSE 0
                                        END) AS 本年操盘回笼任务
                            FROM    erp25.dbo.ydkb_BaseInfo bi
                                    LEFT JOIN s_SaleProjectTaskList s ON bi.组织架构ID = s.ProjectGUID
                                    LEFT JOIN erp25.dbo.s_SaleProjectTask t ON s.ProjectTaskGUID = t.ProjectTaskGUID
                                    LEFT JOIN erp25.dbo.mdm_Project mp ON bi.组织架构ID = mp.ProjGUID
                            WHERE   t.Syear = YEAR(GETDATE())
                                    AND t.TaskPUnit = '年度'
                            GROUP BY bi.平台公司GUID
                          ) s ON s.平台公司GUID = bi.平台公司GUID
                LEFT JOIN ( SELECT  t.BUGUID ,
                                    SUM(s.CbztTask) AS 本年成本直投任务
                            FROM    erp25.dbo.s_SaleCityTaskList s
                                    LEFT JOIN erp25.dbo.s_SaleCityTask t ON s.CityTaskGUID = t.CityTaskGUID
                            WHERE   t.Syear = YEAR(GETDATE())
                                    AND t.TaskPUnit = '年度'
                            GROUP BY t.BUGUID
                          ) zt ON zt.BUGUID = bi.组织架构ID
                LEFT JOIN ( SELECT  b3.组织架构ID ,
                                    SUM(a.年度产成品任务) * 10000 AS 年产成品任务 ,
                                    SUM(a.[本月份产成品任务]) * 10000 AS 本月产成品任务
                            FROM    erp25.dbo.ykdb_hn_ccpTask a
                                    LEFT JOIN erp25.dbo.ydkb_BaseInfo b ON a.项目GUID = b.组织架构ID
                                    LEFT JOIN erp25.dbo.ydkb_BaseInfo b2 ON b2.组织架构ID = b.组织架构父级ID
                                    LEFT JOIN erp25.dbo.ydkb_BaseInfo b3 ON b3.组织架构ID = b2.组织架构父级ID
                            WHERE   b.组织架构类型 = 3
                            GROUP BY b3.组织架构ID
                          ) cp ON cp.组织架构ID = bi.组织架构ID
        WHERE   bi.组织架构类型 = 1;
                --AND t.Syear = YEAR(GETDATE())
                --AND t.TaskUnit = '年度';
        
--获取平台公司销售实际完成情况
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#CompanySale')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #CompanySale;
            END;  

        SELECT  a.平台公司GUID ,
                ISNULL(a.本月销售金额, 0) + ISNULL(b.本月销售金额, 0) AS 本月销售金额 ,
                ISNULL(a.本月销售金额, 0) AS 本月操盘销售金额 ,
                ISNULL(a.本月签约金额, 0) + ISNULL(b.本月签约金额, 0) AS 本月签约金额 ,
                ISNULL(a.本月签约金额, 0) AS 本月操盘签约金额 ,
                ISNULL(a.本年销售金额, 0) + ISNULL(b.本年销售金额, 0) AS 本年销售金额 ,
                ISNULL(a.本年销售金额权益口径, 0) + ISNULL(b.本年销售金额权益口径, 0) AS 本年销售金额权益口径 ,
                ISNULL(a.本年销售金额并表口径, 0) + ISNULL(b.本年销售金额并表口径, 0) AS 本年销售金额并表口径 ,
                ISNULL(a.本年销售金额, 0) AS 本年操盘销售金额 ,
                ISNULL(a.本年签约金额, 0) + ISNULL(b.本年签约金额, 0) AS 本年签约金额 ,
                ISNULL(a.本年签约金额权益口径, 0) + ISNULL(b.本年签约金额权益口径, 0) AS 本年签约金额权益口径 ,
                ISNULL(a.本年签约金额并表口径, 0) + ISNULL(b.本年签约金额并表口径, 0) AS 本年签约金额并表口径 ,
                ISNULL(a.本年签约金额, 0) AS 本年操盘签约金额 ,
                ISNULL(a.本月回款金额, 0) + ISNULL(b.本月回款金额, 0) AS 本月回款金额 ,
                ISNULL(a.本月回款金额, 0) AS 本月操盘回款金额 ,
                ISNULL(a.本月回款金额权益口径, 0) + ISNULL(b.本月回款金额权益口径, 0) AS 本月回款金额权益口径 ,
                ISNULL(a.本月回款金额并表口径, 0) + ISNULL(b.本月回款金额并表口径, 0) AS 本月回款金额并表口径 ,
                ISNULL(a.本年回款金额, 0) + ISNULL(b.本年回款金额, 0) AS 本年回款金额 ,
                ISNULL(a.本年回款金额, 0) AS 本年操盘回款金额 ,
                ISNULL(a.本年回款金额权益口径, 0) + ISNULL(b.本年回款金额权益口径, 0) AS 本年回款金额权益口径 ,
                ISNULL(a.本年回款金额并表口径, 0) + ISNULL(b.本年回款金额并表口径, 0) AS 本年回款金额并表口径 ,
                ISNULL(a.开盘7天认购转签约签约金额, 0) + ISNULL(b.本年销售金额, 0) AS 开盘7天认购转签约签约金额 ,
                CASE WHEN ( ISNULL(a.本年销售金额, 0) + ISNULL(b.本年销售金额, 0) ) = 0
                     THEN 0
                     ELSE ( ISNULL(a.开盘7天认购转签约签约金额, 0) + ISNULL(b.本年销售金额, 0) )
                          * 1.00 / ( ISNULL(a.本年销售金额, 0) + ISNULL(b.本年销售金额, 0) )
                END AS 开盘7天转签约率 ,
                ISNULL(已认购未签约金额, 0) AS 已认购未签约金额 ,
                ISNULL(已签约未回款金额, 0) AS 已签约未回款金额
        INTO    #CompanySale
        FROM    (
                --操盘项目汇总
                  SELECT    b.平台公司GUID ,
                            ISNULL(SUM(a.本月销售金额), 0) AS 本月销售金额 ,--单位万元
                            ISNULL(SUM(a.本月签约金额), 0) AS 本月签约金额 ,
                            ISNULL(SUM(a.本年销售金额), 0) AS 本年销售金额 ,
                            ISNULL(SUM(a.本年销售金额权益口径), 0) AS 本年销售金额权益口径 ,
                            ISNULL(SUM(a.本年销售金额并表口径), 0) AS 本年销售金额并表口径 ,
                            --+ ISNULL(SUM(ts.TotalAmount), 0) 
                            ISNULL(SUM(a.本年签约金额), 0) AS 本年签约金额 ,
                            ISNULL(SUM(a.本年签约金额权益口径), 0) AS 本年签约金额权益口径 ,
                            ISNULL(SUM(a.本年签约金额并表口径), 0) AS 本年签约金额并表口径 , 
                            --+ ISNULL(SUM(ts.TotalAmount), 0) 
                            ISNULL(SUM(a.本月回款金额), 0) AS 本月回款金额 ,
                            ISNULL(SUM(a.本月回款金额权益口径), 0) AS 本月回款金额权益口径 ,
                            ISNULL(SUM(a.本月回款金额并表口径), 0) AS 本月回款金额并表口径 ,
                            ISNULL(SUM(a.本年回款金额), 0) AS 本年回款金额 , --已增加特殊业绩手工数据
                            ISNULL(SUM(a.本年回款金额权益口径), 0) AS 本年回款金额权益口径 ,
                            ISNULL(SUM(a.本年回款金额并表口径), 0) AS 本年回款金额并表口径 ,
                            ISNULL(SUM(sp.开盘7天认购转签约签约金额), 0) AS 开盘7天认购转签约签约金额 ,
                            ISNULL(SUM(sp.已认购未签约金额), 0) AS 已认购未签约金额 ,
                            ISNULL(SUM(sp.已签约未回款金额), 0) AS 已签约未回款金额
                            --CASE WHEN ISNULL(SUM(sp.本年销售金额), 0) = 0 THEN 0
                            --     ELSE SUM(sp.开盘7天认购转签约签约金额) / SUM(sp.本年销售金额)
                            --END AS 开盘7天转签约率
                  FROM      erp25.dbo.ydkb_jyyj a
                            LEFT JOIN erp25.dbo.ydkb_BaseInfo b ON a.组织架构ID = b.组织架构ID
                            LEFT JOIN #SaleProjAmount sp ON sp.组织架构ID = a.组织架构ID
                           -- LEFT JOIN #tsProjSaleAmount ts ON ts.组织架构ID = a.组织架构ID
                  WHERE     a.组织架构类型 = 3
                            AND b.操盘方式 <> '合作方操盘'
                  GROUP BY  b.平台公司GUID
                ) a
                LEFT JOIN (
	              --非操盘项目填报数据
                            SELECT  mp.DevelopmentCompanyGUID AS 平台公司GUID ,
                                    SUM(CASE WHEN DATEDIFF(mm, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.Amount
                                             ELSE 0
                                        END) AS 本月销售金额 , --单位万元
                                    SUM(CASE WHEN DATEDIFF(mm, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.Amount
                                             ELSE 0
                                        END) AS 本月签约金额 ,
                                    SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.Amount
                                             ELSE 0
                                        END) AS 本年销售金额 ,
                                    SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.Amount
                                             ELSE 0
                                        END * ISNULL(lbp.LbProjectValue, 0)
                                        / 100.00) AS 本年销售金额权益口径 ,
                                    SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                                  AND mp.BbWay = '我司并表'
                                             THEN a.Amount
                                             ELSE 0
                                        END) AS 本年销售金额并表口径 ,
                                    SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.Amount
                                             ELSE 0
                                        END) AS 本年签约金额 ,
                                    SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.Amount
                                             ELSE 0
                                        END * ISNULL(lbp.LbProjectValue, 0)
                                        / 100.00) AS 本年签约金额权益口径 ,
                                    SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                                  AND mp.BbWay = '我司并表'
                                             THEN a.Amount
                                             ELSE 0
                                        END) AS 本年签约金额并表口径 ,
                                    SUM(CASE WHEN DATEDIFF(mm, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.huilongjiner
                                             ELSE 0
                                        END) AS 本月回款金额 ,
                                    SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.huilongjiner
                                             ELSE 0
                                        END) AS 本年回款金额,
									SUM(CASE WHEN DATEDIFF(mm, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.huilongjiner
                                             ELSE 0
                                        END  * ISNULL(lbp.LbProjectValue, 0) / 100.00) AS 本月回款金额权益口径 ,
                                    SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.huilongjiner
                                             ELSE 0
                                        END  * ISNULL(lbp.LbProjectValue, 0) / 100.00)AS 本年回款金额权益口径,
										SUM(CASE WHEN DATEDIFF(mm, b.BizDate,
                                                           GETDATE()) = 0 
														   AND mp.BbWay = '我司并表'
                                             THEN a.huilongjiner
                                             ELSE 0
                                        END) AS 本月回款金额并表口径 ,
                                    SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
														   AND mp.BbWay = '我司并表'
                                             THEN a.huilongjiner
                                             ELSE 0
                                        END) AS 本年回款金额并表口径
                            FROM    dbo.s_YJRLProducteDescript a
                                    LEFT JOIN ( SELECT  * ,
                                                        CONVERT(DATETIME, b.DateYear
                                                        + '-' + b.DateMonth
                                                        + '-01') AS [BizDate]
                                                FROM    dbo.s_YJRLProducteDetail b
                                              ) b ON b.ProducteDetailGUID = a.ProducteDetailGUID
                                    LEFT JOIN dbo.s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
                                    LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = c.ProjGUID
                                    LEFT JOIN ( SELECT  projGUID ,
                                                        MAX(LbProjectValue) AS LbProjectValue
                                                FROM    mdm_LbProject
                                                WHERE   LbProject = 'cwsybl'
                                                GROUP BY projGUID
                                              ) lbp ON lbp.projGUID = mp.ProjGUID
                            WHERE   b.Shenhe = '审核'
                            GROUP BY mp.DevelopmentCompanyGUID
                          ) b ON a.平台公司GUID = b.平台公司GUID;
 

---平台公司，实际成本直投完成情况
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#PayDevpAmount')
                            AND type = 'U' )
            BEGIN
                DROP TABLE  #PayDevpAmount;
            END; 
            
            
        SELECT  bi2.组织架构ID ,
                bi2.组织架构编码 ,
                bi2.组织架构名称 ,
                bi2.组织架构类型 ,
                ISNULL(SUM(pa.本月实付金额), 0) AS 本月实付金额 ,
                ISNULL(SUM(pa.本季度实付金额), 0) AS 本季度实付金额 ,
                ISNULL(SUM(pa.本年实付金额), 0) AS 本年实付金额
        INTO    #PayDevpAmount
        FROM    erp25.dbo.ydkb_BaseInfo bi
                LEFT JOIN dbo.ydkb_BaseInfo bi2 ON bi2.组织架构ID = bi.组织架构父级ID
                LEFT JOIN #PayAmount pa ON pa.组织架构ID = bi.组织架构ID
        WHERE   pa.组织架构类型 = 2
                AND bi2.组织架构类型 = 1
        GROUP BY bi2.组织架构ID ,
                bi2.组织架构编码 ,
                bi2.组织架构名称 ,
                bi2.组织架构类型;
         
     
--插入平台公司数据     
        INSERT  INTO dbo.ydkb_jyyj
                ( 组织架构ID ,
                  组织架构名称 ,
                  组织架构编码 ,
                  组织架构类型 ,
                  本月销售任务金额 ,
                  本月操盘销售任务金额 ,
                  本月签约任务金额 ,
                  本月操盘签约任务金额 ,
                  本月产成品任务金额 ,
                  本月回款任务金额 ,
                  本月操盘回款任务金额 ,
                  本月成本直投任务金额 ,
                  本月销售金额 ,
                  本月操盘销售金额 ,
                  本月签约金额 ,
                  本月操盘签约金额 ,
                  本月产成品金额 ,
                  本月回款金额 ,
                  本月操盘回款金额 ,
                  本月回款金额权益口径 ,
                  本月回款金额并表口径 ,
                  本月成本直投金额 ,
                  本月销售完成率 ,
                  本月签约完成率 ,
                  本月产成品完成率 ,
                  本月回款完成率 ,
                  本月成本直投完成率 ,
                  本年销售任务金额 ,
                  本年操盘销售任务金额 ,
                  本年签约任务金额 ,
                  本年操盘签约任务金额 ,
                  本年产成品任务金额 ,
                  本年回款任务金额 ,
                  本年操盘回款任务金额 ,
                  本年成本直投任务金额 ,
                  本年投资拓展任务金额 ,
                  本年销售金额 ,
                  本年销售金额权益口径 ,
                  本年销售金额并表口径 ,
                  本年操盘销售金额 ,
                  本年签约金额 ,
                  本年签约金额权益口径 ,
                  本年签约金额并表口径 ,
                  本年操盘签约金额 ,
                  本年产成品金额 ,
                  本年回款金额 ,
                  本年操盘回款金额 ,
                  本年回款金额权益口径 ,
                  本年回款金额并表口径 ,
                  本年成本直投金额 ,
                  本年投资拓展金额 ,
                  本年销售完成率 ,
                  本年签约完成率 ,
                  本年产成品完成率 ,
                  本年回款完成率 ,
                  本年成本直投完成率 ,
                  本年投资拓展完成率 ,
                  本季度成本直投任务金额 ,
                  本季度成本直投金额 ,
                  本季度成本直投完成率 ,
                  JanFeb新货推货面积 ,
                  JanFeb存货推货面积 ,
                  JanFeb新货认购面积 ,
                  JanFeb存货签约面积 ,
                  JanFeb新货去化率 ,
                  JanFeb存货去化率 ,
                  JanFeb综合去化率 ,
                  Mar新货推货面积 ,
                  Mar存货推货面积 ,
                  Mar新货认购面积 ,
                  Mar存货签约面积 ,
                  Mar新货去化率 ,
                  Mar存货去化率 ,
                  Mar综合去化率 ,
                  Apr新货推货面积 ,
                  Apr存货推货面积 ,
                  Apr新货认购面积 ,
                  Apr存货签约面积 ,
                  Apr新货去化率 ,
                  Apr存货去化率 ,
                  Apr综合去化率 ,
                  May新货推货面积 ,
                  May存货推货面积 ,
                  May新货认购面积 ,
                  May存货签约面积 ,
                  May新货去化率 ,
                  May存货去化率 ,
                  May综合去化率 ,
                  Jun新货推货面积 ,
                  Jun存货推货面积 ,
                  Jun新货认购面积 ,
                  Jun存货签约面积 ,
                  Jun新货去化率 ,
                  Jun存货去化率 ,
                  Jun综合去化率 ,
                  July新货推货面积 ,
                  July存货推货面积 ,
                  July新货认购面积 ,
                  July存货签约面积 ,
                  July新货去化率 ,
                  July存货去化率 ,
                  July综合去化率 ,
                  Aug新货推货面积 ,
                  Aug存货推货面积 ,
                  Aug新货认购面积 ,
                  Aug存货签约面积 ,
                  Aug新货去化率 ,
                  Aug存货去化率 ,
                  Aug综合去化率 ,
                  Sep新货推货面积 ,
                  Sep存货推货面积 ,
                  Sep新货认购面积 ,
                  Sep存货签约面积 ,
                  Sep新货去化率 ,
                  Sep存货去化率 ,
                  Sep综合去化率 ,
                  Oct新货推货面积 ,
                  Oct存货推货面积 ,
                  Oct新货认购面积 ,
                  Oct存货签约面积 ,
                  Oct新货去化率 ,
                  Oct存货去化率 ,
                  Oct综合去化率 ,
                  Nov新货推货面积 ,
                  Nov存货推货面积 ,
                  Nov新货认购面积 ,
                  Nov存货签约面积 ,
                  Nov新货去化率 ,
                  Nov存货去化率 ,
                  Nov综合去化率 ,
                  Dec新货推货面积 ,
                  Dec存货推货面积 ,
                  Dec新货认购面积 ,
                  Dec存货签约面积 ,
                  Dec新货去化率 ,
                  Dec存货去化率 ,
                  Dec综合去化率 ,
                  本年新货推货面积 ,
                  本年存货推货面积 ,
                  本年新货认购面积 ,
                  本年存货签约面积 ,
                  本年新货去化率 ,
                  本年存货去化率 ,
                  本年综合去化率 ,
                  开盘7天认购转签约签约金额 ,
                  开盘7天转签约率 ,
                  已认购未签约金额 ,
                  已签约未回款金额
                )
                SELECT  a.组织架构ID ,
                        a.组织架构名称 ,
                        a.组织架构编码 ,
                        a.组织架构类型 ,
                        b.本月销售任务 AS 本月销售任务金额 ,
                        b.本月操盘销售任务 AS 本月操盘销售任务金额 ,
                        b.本月签约任务 AS 本月签约任务金额 ,
                        b.本月操盘签约任务 AS 本月操盘签约任务金额 ,
                        b.本月产成品任务 AS 本月产成品任务金额 ,
                        b.本月回笼任务 AS 本月回款任务金额 ,
                        b.本月操盘回笼任务 AS 本月操盘回款任务金额 ,
                        b.本月成本直投任务 AS 本月成本直投任务金额 ,
                        d.本月销售金额 AS 本月销售金额 ,
                        d.本月操盘销售金额 AS 本月操盘销售金额 ,
                        d.本月签约金额 AS 本月签约金额 ,
                        d.本月操盘签约金额 AS 本月操盘签约金额 ,
                        ISNULL(pc.本月产成品签约金额, 0) AS 本月产成品金额 ,
                        d.本月回款金额 AS 本月回款金额 ,
                        d.本月操盘回款金额 AS 本月操盘回款金额 ,
                        d.本月回款金额权益口径 AS 本月回款金额权益口径 ,
                        d.本月回款金额并表口径 AS 本月回款金额并表口径 ,
                        pda.本月实付金额 AS 本月成本直投金额 ,
                        CASE WHEN ISNULL(b.本月销售任务, 0) = 0 THEN 0
                             ELSE ISNULL(d.本月销售金额, 0) * 1.00 / ISNULL(b.本月销售任务,
                                                              0)
                        END AS 本月销售完成率 ,
                        CASE WHEN ISNULL(b.本月签约任务, 0) = 0 THEN 0
                             ELSE ISNULL(d.本月签约金额, 0) * 1.00 / ISNULL(b.本月签约任务,
                                                              0)
                        END AS 本月签约完成率 ,
                        CASE WHEN ISNULL(b.本月产成品任务, 0) = 0 THEN 0
                             ELSE ISNULL(pc.本月产成品签约金额, 0) / ISNULL(b.本月产成品任务,
                                                              0) * 1.00
                        END AS 本月产成品完成率 ,
                        CASE WHEN ISNULL(b.本月回笼任务, 0) = 0 THEN 0
                             ELSE ISNULL(d.本月回款金额, 0) * 1.00 / ISNULL(b.本月回笼任务,
                                                              0)
                        END AS 本月回款完成率 ,
                        0 AS 本月成本直投完成率 ,
                        c.本年销售任务 AS 本年销售任务金额 ,
                        c.本年操盘销售任务 AS 本年操盘销售任务金额 ,
                        c.本年签约任务 AS 本年签约任务金额 ,
                        c.本年操盘签约任务 AS 本年操盘签约任务金额 ,
                        c.本年产成品任务 AS 本年产成品任务金额 ,
                        c.本年回笼任务 AS 本年回款任务金额 ,
                        c.本年操盘回笼任务 AS 本年操盘回款任务金额 ,
                        c.本年成本直投任务 AS 本年成本直投任务金额 ,
                        ISNULL(hntz.rw, 0) * 10000 AS 本年投资拓展任务金额 ,
                        d.本年销售金额 AS 本年销售金额 ,
                        d.本年销售金额权益口径 AS 本年销售金额权益口径 ,
                        d.本年销售金额并表口径 AS 本年销售金额并表口径 ,
                        d.本年操盘销售金额 AS 本年操盘销售金额 ,
                        d.本年签约金额 AS 本年签约金额 ,
                        d.本年签约金额权益口径 AS 本年签约金额权益口径 ,
                        d.本年签约金额并表口径 AS 本年签约金额并表口径 ,
                        d.本年操盘签约金额 AS 本年操盘签约金额 ,
                        ISNULL(pc.本年产成品签约金额, 0) AS 本年产成品金额 ,
                        d.本年回款金额 AS 本年回款金额 ,
                        d.本年操盘回款金额 AS 本年操盘回款金额 ,
                        d.本年回款金额权益口径 AS 本年回款金额权益口径 ,
                        d.本年回款金额并表口径 AS 本年回款金额并表口径 ,
                        pda.本年实付金额 AS 本年成本直投金额 ,
                        ISNULL(hntz.sj, 0) * 10000 AS 本年投资拓展金额 ,
                        CASE WHEN ISNULL(c.本年销售任务, 0) = 0 THEN 0
                             ELSE ISNULL(d.本年销售金额, 0) * 1.00 / ISNULL(c.本年销售任务,
                                                              0)
                        END AS 本年销售完成率 ,
                        CASE WHEN ISNULL(c.本年签约任务, 0) = 0 THEN 0
                             ELSE ISNULL(d.本年签约金额, 0) * 1.00 / ISNULL(c.本年签约任务,
                                                              0)
                        END AS 本年签约完成率 ,
                        CASE WHEN ISNULL(c.本年产成品任务, 0) = 0 THEN 0
                             ELSE ISNULL(pc.本年产成品签约金额, 0) / ISNULL(c.本年产成品任务,
                                                              0) * 1.00
                        END AS 本年产成品完成率 ,
                        CASE WHEN ISNULL(c.本年回笼任务, 0) = 0 THEN 0
                             ELSE ISNULL(d.本年回款金额, 0) * 1.00 / ISNULL(c.本年回笼任务,
                                                              0)
                        END AS 本年回款完成率 ,
                        CASE WHEN ISNULL(c.本年成本直投任务, 0) = 0 THEN 0
                             ELSE ISNULL(pda.本年实付金额, 0) / ISNULL(c.本年成本直投任务, 0)
                                  * 1.00
                        END AS 本年成本直投完成率 ,
                        CASE WHEN ISNULL(hntz.rw, 0) = 0 THEN 0.00
                             ELSE ISNULL(hntz.sj, 0) * 1.00 / ISNULL(hntz.rw,
                                                              0)
                        END AS 本年投资拓展完成率 ,
                        j.本季度成本直投任务 AS 本季度成本直投任务金额 ,
                        pda.本季度实付金额 AS 本季度成本直投金额 ,
                        CASE WHEN ISNULL(j.本季度成本直投任务, 0) = 0 THEN 0
                             ELSE ISNULL(pda.本季度实付金额, 0) / ISNULL(j.本季度成本直投任务,
                                                              0) * 1.00
                        END AS 本季度成本直投完成率 ,

                        
                        --去化率
                        ISNULL(cs.Jan新货推货面积, 0) + ISNULL(cs.Feb新货推货面积, 0) AS JanFeb新货推货面积 ,
                        ISNULL(cs.Jan存货推货面积, 0) + ISNULL(cs.Feb存货推货面积, 0) AS JanFeb存货推货面积 ,
                        ISNULL(cs.Jan新货认购面积, 0) + ISNULL(cs.Feb新货认购面积, 0) AS JanFeb新货认购面积 ,
                        ISNULL(cs.Jan存货签约面积, 0) + ISNULL(cs.Feb存货签约面积, 0) AS JanFeb存货签约面积 ,
                        CASE WHEN ( ISNULL(cs.Jan新货推货面积, 0)
                                    + ISNULL(cs.Feb新货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Jan新货认购面积, 0)
                                    + ISNULL(cs.Feb新货认购面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Jan新货推货面积, 0)
                                      + ISNULL(cs.Feb新货推货面积, 0) )
                        END AS JanFeb新货去化率 ,
                        CASE WHEN ( ISNULL(cs.Jan存货推货面积, 0)
                                    + ISNULL(cs.Feb存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Jan存货签约面积, 0)
                                    + ISNULL(cs.Feb存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Jan存货推货面积, 0)
                                      + ISNULL(cs.Feb存货推货面积, 0) )
                        END AS JanFeb存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Jan新货推货面积, 0)
                                    + ISNULL(cs.Feb新货推货面积, 0)
                                    + ISNULL(cs.Jan存货推货面积, 0)
                                    + ISNULL(cs.Feb存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Jan新货认购面积, 0)
                                    + ISNULL(cs.Feb新货认购面积, 0)
                                    + ISNULL(cs.Jan存货签约面积, 0)
                                    + ISNULL(cs.Feb存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Jan新货推货面积, 0)
                                      + ISNULL(cs.Feb新货推货面积, 0)
                                      + ISNULL(cs.Jan存货推货面积, 0)
                                      + ISNULL(cs.Feb存货推货面积, 0) )
                        END AS JanFeb综合去化率 ,
                        cs.Mar新货推货面积 AS Mar新货推货面积 ,
                        cs.Mar存货推货面积 AS Mar存货推货面积 ,
                        cs.Mar新货认购面积 AS Mar新货认购面积 ,
                        cs.Mar存货签约面积 AS Mar存货签约面积 ,
                        CASE WHEN ISNULL(cs.Mar新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Mar新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Mar新货推货面积, 0)
                        END AS Mar新货去化率 ,
                        CASE WHEN ISNULL(cs.Mar存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Mar存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Mar存货推货面积, 0)
                        END AS Mar存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Mar新货推货面积, 0)
                                    + ISNULL(cs.Mar存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Mar新货认购面积, 0)
                                    + ISNULL(cs.Mar存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Mar新货推货面积, 0)
                                      + ISNULL(cs.Mar存货推货面积, 0) )
                        END AS Mar综合去化率 ,
                        cs.Apr新货推货面积 AS Apr新货推货面积 ,
                        cs.Apr存货推货面积 AS Apr存货推货面积 ,
                        cs.Apr新货认购面积 AS Apr新货认购面积 ,
                        cs.Apr存货签约面积 AS Apr存货签约面积 ,
                        CASE WHEN ISNULL(cs.Apr新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Apr新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Apr新货推货面积, 0)
                        END AS Apr新货去化率 ,
                        CASE WHEN ISNULL(cs.Apr存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Apr存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Apr存货推货面积, 0)
                        END AS Apr存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Apr新货推货面积, 0)
                                    + ISNULL(cs.Apr存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Apr新货认购面积, 0)
                                    + ISNULL(cs.Apr存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Apr新货推货面积, 0)
                                      + ISNULL(cs.Apr存货推货面积, 0) )
                        END AS Apr综合去化率 ,
                        cs.May新货推货面积 AS May新货推货面积 ,
                        cs.May存货推货面积 AS May存货推货面积 ,
                        cs.May新货认购面积 AS May新货认购面积 ,
                        cs.May存货签约面积 AS May存货签约面积 ,
                        CASE WHEN ISNULL(cs.May新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.May新货认购面积, 0) * 1.00
                                  / ISNULL(cs.May新货推货面积, 0)
                        END AS May新货去化率 ,
                        CASE WHEN ISNULL(cs.May存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.May存货签约面积, 0) * 1.00
                                  / ISNULL(cs.May存货推货面积, 0)
                        END AS May存货去化率 ,
                        CASE WHEN ( ISNULL(cs.May新货推货面积, 0)
                                    + ISNULL(cs.May存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.May新货认购面积, 0)
                                    + ISNULL(cs.May存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.May新货推货面积, 0)
                                      + ISNULL(cs.May存货推货面积, 0) )
                        END AS May综合去化率 ,
                        cs.Jun新货推货面积 AS Jun新货推货面积 ,
                        cs.Jun存货推货面积 AS Jun存货推货面积 ,
                        cs.Jun新货认购面积 AS Jun新货认购面积 ,
                        cs.Jun存货签约面积 AS Jun存货签约面积 ,
                        CASE WHEN ISNULL(cs.Jun新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Jun新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Jun新货推货面积, 0)
                        END AS Jun新货去化率 ,
                        CASE WHEN ISNULL(cs.Jun存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Jun存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Jun存货推货面积, 0)
                        END AS Jun存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Jun新货推货面积, 0)
                                    + ISNULL(cs.Jun存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Jun新货认购面积, 0)
                                    + ISNULL(cs.Jun存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Jun新货推货面积, 0)
                                      + ISNULL(cs.Jun存货推货面积, 0) )
                        END AS Jun综合去化率 ,
                        cs.July新货推货面积 AS July新货推货面积 ,
                        cs.July存货推货面积 AS July存货推货面积 ,
                        cs.July新货认购面积 AS July新货认购面积 ,
                        cs.July存货签约面积 AS July存货签约面积 ,
                        CASE WHEN ISNULL(cs.July新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.July新货认购面积, 0) * 1.00
                                  / ISNULL(cs.July新货推货面积, 0)
                        END AS July新货去化率 ,
                        CASE WHEN ISNULL(cs.July存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.July存货签约面积, 0) * 1.00
                                  / ISNULL(cs.July存货推货面积, 0)
                        END AS July存货去化率 ,
                        CASE WHEN ( ISNULL(cs.July新货推货面积, 0)
                                    + ISNULL(cs.July存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.July新货认购面积, 0)
                                    + ISNULL(cs.July存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.July新货推货面积, 0)
                                      + ISNULL(cs.July存货推货面积, 0) )
                        END AS July综合去化率 ,
                        cs.Aug新货推货面积 AS Aug新货推货面积 ,
                        cs.Aug存货推货面积 AS Aug存货推货面积 ,
                        cs.Aug新货认购面积 AS Aug新货认购面积 ,
                        cs.Aug存货签约面积 AS Aug存货签约面积 ,
                        CASE WHEN ISNULL(cs.Aug新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Aug新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Aug新货推货面积, 0)
                        END AS Aug新货去化率 ,
                        CASE WHEN ISNULL(cs.Aug存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Aug存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Aug存货推货面积, 0)
                        END AS Aug存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Aug新货推货面积, 0)
                                    + ISNULL(cs.Aug存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Aug新货认购面积, 0)
                                    + ISNULL(cs.Aug存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Aug新货推货面积, 0)
                                      + ISNULL(cs.Aug存货推货面积, 0) )
                        END AS Aug综合去化率 ,
                        cs.Sep新货推货面积 AS Sep新货推货面积 ,
                        cs.Sep存货推货面积 AS Sep存货推货面积 ,
                        cs.Sep新货认购面积 AS Sep新货认购面积 ,
                        cs.Sep存货签约面积 AS Sep存货签约面积 ,
                        CASE WHEN ISNULL(cs.Sep新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Sep新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Sep新货推货面积, 0)
                        END AS Sep新货去化率 ,
                        CASE WHEN ISNULL(cs.Sep存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Sep存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Sep存货推货面积, 0)
                        END AS Sep存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Sep新货推货面积, 0)
                                    + ISNULL(cs.Sep存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Sep新货认购面积, 0)
                                    + ISNULL(cs.Sep存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Sep新货推货面积, 0)
                                      + ISNULL(cs.Sep存货推货面积, 0) )
                        END AS Sep综合去化率 ,
                        cs.Oct新货推货面积 AS Oct新货推货面积 ,
                        cs.Oct存货推货面积 AS Oct存货推货面积 ,
                        cs.Oct新货认购面积 AS Oct新货认购面积 ,
                        cs.Oct存货签约面积 AS Oct存货签约面积 ,
                        CASE WHEN ISNULL(cs.Oct新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Oct新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Oct新货推货面积, 0)
                        END AS Oct新货去化率 ,
                        CASE WHEN ISNULL(cs.Oct存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Oct存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Oct存货推货面积, 0)
                        END AS Oct存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Oct新货推货面积, 0)
                                    + ISNULL(cs.Oct存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Oct新货认购面积, 0)
                                    + ISNULL(cs.Oct存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Oct新货推货面积, 0)
                                      + ISNULL(cs.Oct存货推货面积, 0) )
                        END AS Oct综合去化率 ,
                        cs.Nov新货推货面积 AS Nov新货推货面积 ,
                        cs.Nov存货推货面积 AS Nov存货推货面积 ,
                        cs.Nov新货认购面积 AS Nov新货认购面积 ,
                        cs.Nov存货签约面积 AS Nov存货签约面积 ,
                        CASE WHEN ISNULL(cs.Nov新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Nov新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Nov新货推货面积, 0)
                        END AS Nov新货去化率 ,
                        CASE WHEN ISNULL(cs.Nov存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Nov存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Nov存货推货面积, 0)
                        END AS Nov存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Nov新货推货面积, 0)
                                    + ISNULL(cs.Nov存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Nov新货认购面积, 0)
                                    + ISNULL(cs.Nov存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Nov新货推货面积, 0)
                                      + ISNULL(cs.Nov存货推货面积, 0) )
                        END AS Nov综合去化率 ,
                        cs.Dec新货推货面积 AS Dec新货推货面积 ,
                        cs.Dec存货推货面积 AS Dec存货推货面积 ,
                        cs.Dec新货认购面积 AS Dec新货认购面积 ,
                        cs.Dec存货签约面积 AS Dec存货签约面积 ,
                        CASE WHEN ISNULL(cs.Dec新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Dec新货认购面积, 0) * 1.00
                                  / ISNULL(cs.Dec新货推货面积, 0)
                        END AS Dec新货去化率 ,
                        CASE WHEN ISNULL(cs.Dec存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.Dec存货签约面积, 0) * 1.00
                                  / ISNULL(cs.Dec存货推货面积, 0)
                        END AS Dec存货去化率 ,
                        CASE WHEN ( ISNULL(cs.Dec新货推货面积, 0)
                                    + ISNULL(cs.Dec存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.Dec新货认购面积, 0)
                                    + ISNULL(cs.Dec存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.Dec新货推货面积, 0)
                                      + ISNULL(cs.Dec存货推货面积, 0) )
                        END AS Dec综合去化率 ,
                        ---------------------------------------------------------------------
                        ISNULL(cs.本年新货推货面积, 0) AS 本年新货推货面积 ,
                        ISNULL(cs.本年存货推货面积, 0) AS 本年存货推货面积 ,
                        ISNULL(cs.本年新货认购面积, 0) AS 本年新货认购面积 ,
                        ISNULL(cs.本年存货签约面积, 0) AS 本年存货签约面积 ,
                        CASE WHEN ISNULL(cs.本年新货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.本年新货认购面积, 0) * 1.00
                                  / ISNULL(cs.本年新货推货面积, 0)
                        END AS 本年新货去化率 ,
                        CASE WHEN ISNULL(cs.本年存货推货面积, 0) = 0 THEN 0
                             ELSE ISNULL(cs.本年存货签约面积, 0) * 1.00
                                  / ISNULL(cs.本年存货推货面积, 0)
                        END AS 本年存货去化率 ,
                        CASE WHEN ( ISNULL(cs.本年新货推货面积, 0)
                                    + ISNULL(cs.本年存货推货面积, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(cs.本年新货认购面积, 0)
                                    + ISNULL(cs.本年存货签约面积, 0) ) * 1.00
                                  / ( ISNULL(cs.本年新货推货面积, 0)
                                      + ISNULL(cs.本年存货推货面积, 0) )
                        END AS 本年综合去化率 ,
                        d.开盘7天认购转签约签约金额 ,
                        d.开盘7天转签约率 ,
                        d.已认购未签约金额 AS 已认购未签约金额 ,
                        d.已签约未回款金额 AS 已签约未回款金额
                FROM    ydkb_BaseInfo a
                        LEFT  JOIN #ydCompanyTask b ON b.组织架构ID = a.组织架构ID
                        LEFT JOIN #ndCompanyTask c ON c.组织架构ID = a.组织架构ID
                        LEFT JOIN #jdCompanyTask j ON j.组织架构ID = a.组织架构ID
                        LEFT JOIN #CompanySale d ON d.平台公司GUID = a.平台公司GUID
                        LEFT JOIN #CompanySaleQh cs ON cs.组织架构ID = a.组织架构ID
                        LEFT JOIN #PayDevpAmount pda ON pda.组织架构ID = a.组织架构ID
                        LEFT JOIN #CompccbSaleTemp pc ON pc.DevelopmentCompanyGUID = a.平台公司GUID
                        LEFT JOIN ( SELECT  buguid ,
                                            SUM(sj) AS sj ,
                                            SUM(rw) AS rw
                                    FROM    s_hntzrw
                                    WHERE   Level = 2
                                    GROUP BY buguid
                                  ) hntz ON hntz.buguid = a.组织架构ID
                WHERE   a.组织架构类型 = 1;
        
 

--查询数据集结果       
        SELECT  组织架构ID ,
                组织架构名称 ,
                组织架构编码 ,
                组织架构类型 ,
                本月销售任务金额 ,
                本月操盘销售任务金额 ,
                本月签约任务金额 ,
                本月操盘签约任务金额 ,
                本月产成品任务金额 ,
                本月回款任务金额 ,
                本月操盘回款任务金额 ,
                本月成本直投任务金额 ,
                本月销售金额 ,
                本月操盘销售金额 ,
                本月签约金额 ,
                本月操盘签约金额 ,
                本月产成品金额 ,
                本月回款金额 ,
                本月操盘回款金额 ,
                本月回款金额权益口径 ,
                本月回款金额并表口径 ,
                本月成本直投金额 ,
                本月销售完成率 ,
                本月签约完成率 ,
                本月产成品完成率 ,
                本月回款完成率 ,
                本月成本直投完成率 ,
                本年销售任务金额 ,
                本年操盘销售任务金额 ,
                本年签约任务金额 ,
                本年操盘签约任务金额 ,
                本年产成品任务金额 ,
                本年回款任务金额 ,
                本年操盘回款任务金额 ,
                本年成本直投任务金额 ,
                本年投资拓展任务金额 ,
                本年销售金额 ,
                本年销售金额权益口径 ,
                本年销售金额并表口径 ,
                本年操盘销售金额 ,
                本年签约金额 ,
                本年签约金额权益口径 ,
                本年签约金额并表口径 ,
                本年操盘签约金额 ,
                本年产成品金额 ,
                本年回款金额 ,
                本年操盘回款金额 ,
                本年回款金额权益口径 ,
                本年回款金额并表口径 ,
                本年成本直投金额 ,
                本年投资拓展金额 ,
                本年销售完成率 ,
                本年签约完成率 ,
                本年产成品完成率 ,
                本年回款完成率 ,
                本年成本直投完成率 ,
                本年投资拓展完成率 ,
                本季度成本直投任务金额 ,
                本季度成本直投金额 ,
                本季度成本直投完成率 ,
                JanFeb新货推货面积 ,
                JanFeb存货推货面积 ,
                JanFeb新货认购面积 ,
                JanFeb存货签约面积 ,
                JanFeb新货去化率 ,
                JanFeb存货去化率 ,
                JanFeb综合去化率 ,
                Mar新货推货面积 ,
                Mar存货推货面积 ,
                Mar新货认购面积 ,
                Mar存货签约面积 ,
                Mar新货去化率 ,
                Mar存货去化率 ,
                Mar综合去化率 ,
                Apr新货推货面积 ,
                Apr存货推货面积 ,
                Apr新货认购面积 ,
                Apr存货签约面积 ,
                Apr新货去化率 ,
                Apr存货去化率 ,
                Apr综合去化率 ,
                May新货推货面积 ,
                May存货推货面积 ,
                May新货认购面积 ,
                May存货签约面积 ,
                May新货去化率 ,
                May存货去化率 ,
                May综合去化率 ,
                Jun新货推货面积 ,
                Jun存货推货面积 ,
                Jun新货认购面积 ,
                Jun存货签约面积 ,
                Jun新货去化率 ,
                Jun存货去化率 ,
                Jun综合去化率 ,
                July新货推货面积 ,
                July存货推货面积 ,
                July新货认购面积 ,
                July存货签约面积 ,
                July新货去化率 ,
                July存货去化率 ,
                July综合去化率 ,
                Aug新货推货面积 ,
                Aug存货推货面积 ,
                Aug新货认购面积 ,
                Aug存货签约面积 ,
                Aug新货去化率 ,
                Aug存货去化率 ,
                Aug综合去化率 ,
                Sep新货推货面积 ,
                Sep存货推货面积 ,
                Sep新货认购面积 ,
                Sep存货签约面积 ,
                Sep新货去化率 ,
                Sep存货去化率 ,
                Sep综合去化率 ,
                Oct新货推货面积 ,
                Oct存货推货面积 ,
                Oct新货认购面积 ,
                Oct存货签约面积 ,
                Oct新货去化率 ,
                Oct存货去化率 ,
                Oct综合去化率 ,
                Nov新货推货面积 ,
                Nov存货推货面积 ,
                Nov新货认购面积 ,
                Nov存货签约面积 ,
                Nov新货去化率 ,
                Nov存货去化率 ,
                Nov综合去化率 ,
                Dec新货推货面积 ,
                Dec存货推货面积 ,
                Dec新货认购面积 ,
                Dec存货签约面积 ,
                Dec新货去化率 ,
                Dec存货去化率 ,
                Dec综合去化率 ,
                本年新货推货面积 ,
                本年存货推货面积 ,
                本年新货认购面积 ,
                本年存货签约面积 ,
                本年新货去化率 ,
                本年存货去化率 ,
                本年综合去化率 ,
                开盘7天认购转签约签约金额 ,
                开盘7天转签约率 ,
                已认购未签约金额 ,
                已签约未回款金额
        FROM    ydkb_jyyj
        ORDER BY 组织架构编码 ,
                组织架构类型;

    END; 