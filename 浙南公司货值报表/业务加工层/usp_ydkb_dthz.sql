USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_ydkb_dthz]    Script Date: 2025/1/6 10:35:33 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--usp_ydkb_dthz
ALTER  PROC [dbo].[usp_ydkb_dthz]
AS
    BEGIN
    --设置时间参数，本年和下一年
        DECLARE @bnyear VARCHAR(4);
        DECLARE @NextYear VARCHAR(4);

        SET @bnyear = CONVERT(VARCHAR(4), GETDATE(), 120);
        SET @NextYear = CONVERT(VARCHAR(4), DATEADD(yy, 1, GETDATE()), 120);


        IF EXISTS ( SELECT  *
                    FROM    dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'ydkb_dthz')
                            AND OBJECTPROPERTY(id, 'IsTable') = 1 )
            BEGIN
                DROP TABLE ydkb_dthz;
            END;

    --02移动-总经理-动态货值

        CREATE TABLE ydkb_dthz
            (
              组织架构ID UNIQUEIDENTIFIER ,
              组织架构名称 VARCHAR(400) ,
              组织架构编码 [VARCHAR](100) ,
              组织架构类型 [INT] ,
              
			  总货值金额 MONEY ,             --总货值金额
              总货值面积 MONEY ,             --总货值面积
              已售货量金额 MONEY ,            --已售货量金额
              已售货量面积 MONEY ,            --已售货量面积
                                 --操盘项目，排除非操盘项目、代建、代管状态的项目以及一级开发项目
              总货值金额操盘项目 MONEY ,         --总货值金额
              总货值面积操盘项目 MONEY ,         --总货值面积
              已售货量金额操盘项目 MONEY ,        --已售货量金额
              已售货量面积操盘项目 MONEY ,        --已售货量面积

              剩余货值金额 MONEY ,
              剩余货值面积 MONEY ,
              剩余可售货值金额 MONEY ,          --剩余可售货值金额C=C1+C2+C3（亿元）	
              剩余可售货值面积 MONEY ,          --剩余可售面积	
              
              --本月情况
              工程达到可售未拿证货值金额 MONEY ,     --其中工程达到可售未拿证货值金额C1（亿元）	
              工程达到可售未拿证货值面积 MONEY ,     --其中工程达到可售未拿证货值面积	
              获证未推货值金额 MONEY ,          --其中获证未推货值金额C2（亿元）	
              获证未推货值面积 MONEY ,          --其中获证未推货值面积
              已推未售货值金额 MONEY ,          --其中已推未售货值金额C3（亿元）
              已推未售货值面积 MONEY ,          --其中已推未售货值面积

                                 --剩余货值金额操盘项目，排除非操盘项目+特殊业绩项目可售货量
              剩余货值金额操盘项目 MONEY ,
              剩余货值面积操盘项目 MONEY ,
              剩余可售货值金额操盘项目 MONEY ,      --剩余可售货值金额C=C1+C2+C3（亿元）	
              剩余可售货值面积操盘项目 MONEY ,      --剩余可售面积	
              工程达到可售未拿证货值金额操盘项目 MONEY , --其中工程达到可售未拿证货值金额C1（亿元）	
              工程达到可售未拿证货值面积操盘项目 MONEY , --其中工程达到可售未拿证货值面积	
              获证未推货值金额操盘项目 MONEY ,      --其中获证未推货值金额C2（亿元）	
              获证未推货值面积操盘项目 MONEY ,      --其中获证未推货值面积
              已推未售货值金额操盘项目 MONEY ,      --其中已推未售货值金额C3（亿元）
              已推未售货值面积操盘项目 MONEY ,      --其中已推未售货值面积

			                     --年初情况 采用往年达到预售条件本年剩余货量+往年达到预售条件本年已售货量反算年初可售货量
              年初工程达到可售未拿证货值金额 MONEY ,   --其中工程达到可售未拿证货值金额 （亿元）	
              年初工程达到可售未拿证货值面积 MONEY ,   --其中工程达到可售未拿证货值面积	
              年初获证未推货值金额 MONEY ,        --其中获证未推货值金额 （亿元）	
              年初获证未推货值面积 MONEY ,        --其中获证未推货值面积
              年初已推未售货值金额 MONEY ,        --其中已推未售货值金额 （亿元）
              年初已推未售货值面积 MONEY ,        --其中已推未售货值面积

              本月新货货量 MONEY ,            --本月新货货量（亿元）	
              本月新货面积 MONEY ,            --本月新货面积（平方米）	
              本年存货货量 MONEY ,            --本年存货货量（亿元）	
              本年存货面积 MONEY ,            --本年存货面积（平方米）	
              后续预计达成货量金额 MONEY ,        --后续预计达成货量金额（亿元）	
              后续预计达成货量面积 MONEY ,        --后续预计达成货量面积（平方米）	
              今年后续预计达成货量金额 MONEY ,      --后续预计达成货量金额（亿元）--取预售证节点未完成、且计划完成时间在本年度的楼栋可售面积*预测单价	
              今年后续预计达成货量面积 MONEY ,      --后续预计达成货量面积（平方米）	--取预售证节点未完成、且计划完成时间在本年度的楼栋可售面积*预测单价

                                 --本年可售已售数据统计
              本年可售货量金额 MONEY ,
              本年可售货量面积 MONEY ,
              本年剩余可售货量金额 MONEY ,
              本年剩余可售货量面积 MONEY ,
			  当前剩余可售货量金额 MONEY,
			  当前剩余可售货量面积 MONEY,

              本年已售货量金额 MONEY ,
              本年已售货量面积 MONEY ,
              Jan预计货量金额 MONEY ,
              Jan实际货量金额 MONEY ,
              Jan货量达成率 MONEY ,
              Feb预计货量金额 MONEY ,
              Feb实际货量金额 MONEY ,
              Feb货量达成率 MONEY ,
              Mar预计货量金额 MONEY ,
              Mar实际货量金额 MONEY ,
              Mar货量达成率 MONEY ,
              Apr预计货量金额 MONEY ,
              Apr实际货量金额 MONEY ,
              Apr货量达成率 MONEY ,
              May预计货量金额 MONEY ,
              May实际货量金额 MONEY ,
              May货量达成率 MONEY ,
              Jun预计货量金额 MONEY ,
              Jun实际货量金额 MONEY ,
              Jun货量达成率 MONEY ,
              July预计货量金额 MONEY ,
              July实际货量金额 MONEY ,
              July货量达成率 MONEY ,
              Aug预计货量金额 MONEY ,
              Aug实际货量金额 MONEY ,
              Aug货量达成率 MONEY ,
              Sep预计货量金额 MONEY ,
              Sep实际货量金额 MONEY ,
              Sep货量达成率 MONEY ,
              Oct预计货量金额 MONEY ,
              Oct实际货量金额 MONEY ,
              Oct货量达成率 MONEY ,
              Nov预计货量金额 MONEY ,
              Nov实际货量金额 MONEY ,
              Nov货量达成率 MONEY ,
              Dec预计货量金额 MONEY ,
              Dec实际货量金额 MONEY ,
              Dec货量达成率 MONEY ,
              本月预计货量金额 MONEY ,
              本月实际货量金额 MONEY ,
              本月货量达成率 MONEY ,
              本年预计货量金额 MONEY ,
              本年实际货量金额 MONEY ,
              本年货量达成率 MONEY ,


                                 --1-2月份
              Jan可售货值金额 MONEY ,         --1月总可售货值	
              Jan可售货值面积 MONEY ,         --1月总可售面积	
              Jan新推货值金额 MONEY ,         --1月新推货量	
              Jan新推货值面积 MONEY ,         --1月新推面积	 
              Feb可售货值金额 MONEY ,         --2月总可售货值	
              Feb可售货值面积 MONEY ,         --2月总可售面积	
              Feb新推货值金额 MONEY ,         --2月新推货量	
              Feb新推货值面积 MONEY ,         --2月新推面积	 
              JanFeb可售货值金额 MONEY ,      --1-2月总可售货值	
              JanFeb可售货值面积 MONEY ,      --1-2月总可售面积	
              JanFeb新推货值金额 MONEY ,      --1-2月新推货量	
              JanFeb新推货值面积 MONEY ,      --1-2月新推面积	
                                 --3月份
              Mar可售货值金额 MONEY ,         --3月总可售货值	
              Mar可售货值面积 MONEY ,         --3月总可售面积	
              Mar新推货值金额 MONEY ,         --3月新推货量	
              Mar新推货值面积 MONEY ,         --3月新推面积	

                                 --4月份
              Apr可售货值金额 MONEY ,         --4月总可售货值	
              Apr可售货值面积 MONEY ,         --4月总可售面积	
              Apr新推货值金额 MONEY ,         --4月新推货量	
              Apr新推货值面积 MONEY ,         --4月新推面积	

                                 --5月份
              May可售货值金额 MONEY ,         --5月总可售货值	
              May可售货值面积 MONEY ,         --5月总可售面积	
              May新推货值金额 MONEY ,         --5月新推货量	
              May新推货值面积 MONEY ,         --5月新推面积	

                                 --6月份
              Jun可售货值金额 MONEY ,         --6月总可售货值	
              Jun可售货值面积 MONEY ,         --6月总可售面积	
              Jun新推货值金额 MONEY ,         --6月新推货量	
              Jun新推货值面积 MONEY ,         --6月新推面积	

                                 --7月份
              July可售货值金额 MONEY ,        --7月总可售货值	
              July可售货值面积 MONEY ,        --7月总可售面积	
              July新推货值金额 MONEY ,        --7月新推货量	
              July新推货值面积 MONEY ,        --7月新推面积	

                                 --8月份
              Aug可售货值金额 MONEY ,         --8月总可售货值	
              Aug可售货值面积 MONEY ,         --8月总可售面积	
              Aug新推货值金额 MONEY ,         --8月新推货量	
              Aug新推货值面积 MONEY ,         --8月新推面积	

                                 --9月份
              Sep可售货值金额 MONEY ,         --9月总可售货值	
              Sep可售货值面积 MONEY ,         --9月总可售面积	
              Sep新推货值金额 MONEY ,         --9月新推货量	
              Sep新推货值面积 MONEY ,         --9月新推面积	

                                 --10月份
              Oct可售货值金额 MONEY ,         --10月总可售货值	
              Oct可售货值面积 MONEY ,         --10月总可售面积	
              Oct新推货值金额 MONEY ,         --10月新推货量	
              Oct新推货值面积 MONEY ,         --10月新推面积	

                                 --11月份
              Nov可售货值金额 MONEY ,         --11月总可售货值	
              Nov可售货值面积 MONEY ,         --11月总可售面积	
              Nov新推货值金额 MONEY ,         --11月新推货量	
              Nov新推货值面积 MONEY ,         --11月新推面积	

                                 --12月份
              Dec可售货值金额 MONEY ,         --12月总可售货值	
              Dec可售货值面积 MONEY ,         --12月总可售面积	
              Dec新推货值金额 MONEY ,         --12月新推货量	
              Dec新推货值面积 MONEY ,         --12月新推面积	

                                 --次年1-12月份        
                                 --1-2月份
              NextJan可售货值金额 MONEY ,     --1月总可售货值	
              NextJan可售货值面积 MONEY ,     --1月总可售面积	
              NextJan新推货值金额 MONEY ,     --1月新推货量	
              NextJan新推货值面积 MONEY ,     --1月新推面积	 
              NextFeb可售货值金额 MONEY ,     --2月总可售货值	
              NextFeb可售货值面积 MONEY ,     --2月总可售面积	
              NextFeb新推货值金额 MONEY ,     --2月新推货量	
              NextFeb新推货值面积 MONEY ,     --2月新推面积	 
              NextJanFeb可售货值金额 MONEY ,  --1-2月总可售货值	
              NextJanFeb可售货值面积 MONEY ,  --1-2月总可售面积	
              NextJanFeb新推货值金额 MONEY ,  --1-2月新推货量	
              NextJanFeb新推货值面积 MONEY ,  --1-2月新推面积	
                                 --3月份
              NextMar可售货值金额 MONEY ,     --3月总可售货值	
              NextMar可售货值面积 MONEY ,     --3月总可售面积	
              NextMar新推货值金额 MONEY ,     --3月新推货量	
              NextMar新推货值面积 MONEY ,     --3月新推面积	

                                 --4月份
              NextApr可售货值金额 MONEY ,     --4月总可售货值	
              NextApr可售货值面积 MONEY ,     --4月总可售面积	
              NextApr新推货值金额 MONEY ,     --4月新推货量	
              NextApr新推货值面积 MONEY ,     --4月新推面积	

                                 --5月份
              NextMay可售货值金额 MONEY ,     --5月总可售货值	
              NextMay可售货值面积 MONEY ,     --5月总可售面积	
              NextMay新推货值金额 MONEY ,     --5月新推货量	
              NextMay新推货值面积 MONEY ,     --5月新推面积	

                                 --6月份
              NextJun可售货值金额 MONEY ,     --6月总可售货值	
              NextJun可售货值面积 MONEY ,     --6月总可售面积	
              NextJun新推货值金额 MONEY ,     --6月新推货量	
              NextJun新推货值面积 MONEY ,     --6月新推面积	

                                 --7月份
              NextJuly可售货值金额 MONEY ,    --7月总可售货值	
              NextJuly可售货值面积 MONEY ,    --7月总可售面积	
              NextJuly新推货值金额 MONEY ,    --7月新推货量	
              NextJuly新推货值面积 MONEY ,    --7月新推面积	

                                 --8月份
              NextAug可售货值金额 MONEY ,     --8月总可售货值	
              NextAug可售货值面积 MONEY ,     --8月总可售面积	
              NextAug新推货值金额 MONEY ,     --8月新推货量	
              NextAug新推货值面积 MONEY ,     --8月新推面积	

                                 --9月份
              NextSep可售货值金额 MONEY ,     --9月总可售货值	
              NextSep可售货值面积 MONEY ,     --9月总可售面积	
              NextSep新推货值金额 MONEY ,     --9月新推货量	
              NextSep新推货值面积 MONEY ,     --9月新推面积	

                                 --10月份
              NextOct可售货值金额 MONEY ,     --10月总可售货值	
              NextOct可售货值面积 MONEY ,     --10月总可售面积	
              NextOct新推货值金额 MONEY ,     --10月新推货量	
              NextOct新推货值面积 MONEY ,     --10月新推面积	

                                 --11月份
              NextNov可售货值金额 MONEY ,     --11月总可售货值	
              NextNov可售货值面积 MONEY ,     --11月总可售面积	
              NextNov新推货值金额 MONEY ,     --11月新推货量	
              NextNov新推货值面积 MONEY ,     --11月新推面积	

                                 --12月份
              NextDec可售货值金额 MONEY ,     --12月总可售货值	
              NextDec可售货值面积 MONEY ,     --12月总可售面积	
              NextDec新推货值金额 MONEY ,     --12月新推货量	
              NextDec新推货值面积 MONEY ,     --12月新推面积	
              月平均销售面积 MONEY ,           --月平均销售面积	
              存货预计去化周期 INT ,            --存货预计去化周期(月份)	
              未开工部分预计达到预售条件周期 INT ,     --未开工部分预计达到预售条件周期	
              存货同预计达到预售条件时间差 INT ,      --存货同预计达到预售条件时间差	
              滞后货量金额 MONEY ,            --截止到今天，应完成预售证节点但未完成的货量； YjYsblDate 预计预售办理日期 SjYsblDate 实际预售办理日期
              滞后货量面积 MONEY ,
              预计达到预售形象日期 DATETIME ,
              实际达到预售形象日期 DATETIME ,
              预计预售办理日期 DATETIME ,
              实际预售办理日期 DATETIME ,
              预计售价 MONEY ,
              今年车位可售金额 MONEY           --本年可售货量-车位-12月新增
            );

    --先获取车位的产品id
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#car')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #car;
            END;

        SELECT DISTINCT
                SaleBldGUID
        INTO    #car
        FROM    erp25.dbo.p_lddb ld
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON bi.组织架构ID = ld.SaleBldGUID
                                                         AND bi.组织架构类型 = 5
                                                         AND bi.组织架构名称 LIKE '%车%'
        WHERE   DATEDIFF(DAY, QXDate, GETDATE()) = 0
                AND bi.组织架构类型 = 5
                AND ( ISNULL(IsSale, 0) = 1
                      OR ( ISNULL(IsSale, 0) = 0
                           AND ysje <> 0
                         )
                    )                            

    --查询各楼栋货量数据
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ldhz')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #ldhz;
            END;

    ---只统计操盘项目，非操盘项目手工填报没有到楼栋
    --本年可售货量 =本年初剩余货量+本年可售货量
    --本年初剩余货量 = 总货量的预售证日期在本年之前-本年之前的销售金额，其中计算“本年之前总货量金额”用预售证日期判断，有实际的取实际没有取计划
    --本年之前销售金额=总销售金额-本年销售金额
        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                SUM(zhz) / 10000 AS 总货值金额 ,
                SUM(zksmj) AS 总货值面积 ,
				SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  zhz END ) / 10000 AS 总货值操盘金额 ,
                SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  zksmj END ) AS 总货值操盘面积 ,

                SUM(ysje) / 10000 AS 已售货量金额 ,
                SUM(ysmj) AS 已售货量面积 ,
				SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  ysje END ) / 10000 AS 已售货量操盘金额 ,
                SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  ysmj END ) AS 已售货量操盘面积 ,

                SUM(syhz) / 10000 AS 未销售部分货量 ,
                SUM(ISNULL(ytwsmj, 0) + ISNULL(wtmj, 0)) AS 未销售部分可售面积 ,
                SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  syhz END ) / 10000 AS 未销售部分操盘货量 ,
                SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  ISNULL(ytwsmj, 0) + ISNULL(wtmj, 0) END ) AS 未销售部分可售操盘面积 , 
				              
                ( ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                         AND SjDdysxxDate IS NULL THEN syhz
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推' THEN syhz
                                      ELSE 0
                                 END), 0) )
                  + ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                           AND SjDdysxxDate IS NOT NULL
                                      THEN syhz
                                      ELSE 0
                                 END), 0)
                      + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推' THEN syhz
                                        ELSE 0
                                   END), 0) )
                  + ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售' THEN syhz
                                      ELSE 0
                                 END), 0)
                      + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售' THEN syhz
                                        ELSE 0
                                   END), 0) ) ) / 10000 AS 剩余可售货值金额 , --待售货量 B1 + B2
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                  THEN wtmj + ytwsmj
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) )
                + ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                         AND SjDdysxxDate IS NOT NULL
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                      THEN wtmj + ytwsmj
                                      ELSE 0
                                 END), 0) )
                + ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                      THEN wtmj + ytwsmj
                                      ELSE 0
                                 END), 0) ) AS 剩余可售货值面积 , --待售货量
                                  --本月情况
                                  ----已完工未推出未具备条件货量(B2-1)  + 未完工具备条件未获证货量(B1-1) 
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL THEN syhz
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 AS 工程达到可售未拿证货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                  THEN wtmj + ytwsmj
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) AS 工程达到可售未拿证货值面积 ,

                                  ----已完工未推出具备条件货量(B2-2) + 未完工已获证待推货量(B1-2)
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL THEN syhz
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 AS 获证未推货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL
                                  THEN wtmj + ytwsmj
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) AS 获证未推货值面积 ,

                                  ----已完工已推出待售货量（B2-3）  +   未完工已推待售货量(B1-3) 
                ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售' THEN syhz
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 AS 已推未售货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                  THEN wtmj + ytwsmj
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) AS 已推未售货值面积 ,

				(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE (( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                         AND SjDdysxxDate IS NULL THEN syhz
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推' THEN syhz
                                      ELSE 0
                                 END), 0) )
                  + ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                           AND SjDdysxxDate IS NOT NULL
                                      THEN syhz
                                      ELSE 0
                                 END), 0)
                      + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推' THEN syhz
                                        ELSE 0
                                   END), 0) )
                  + ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售' THEN syhz
                                      ELSE 0
                                 END), 0)
                      + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售' THEN syhz
                                        ELSE 0
                                   END), 0) ) ) END ) / 10000 AS 剩余可售货值操盘金额 , --待售货量 B1 + B2
                (CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                  THEN wtmj + ytwsmj
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) )
                + ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                         AND SjDdysxxDate IS NOT NULL
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                      THEN wtmj + ytwsmj
                                      ELSE 0
                                 END), 0) )
                + ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                      THEN wtmj + ytwsmj
                                      ELSE 0
                                 END), 0) )END ) AS 剩余可售货值操盘面积 , --待售货量
                                  --本月情况
                                  ----已完工未推出未具备条件货量(B2-1)  + 未完工具备条件未获证货量(B1-1) 
                (CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL THEN syhz
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 END ) AS 工程达到可售未拿证货值操盘金额 ,
                (CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                  THEN wtmj + ytwsmj
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) END ) AS 工程达到可售未拿证货值操盘面积 ,

                                  ----已完工未推出具备条件货量(B2-2) + 未完工已获证待推货量(B1-2)
                (CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL THEN syhz
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 END ) AS 获证未推货值操盘金额 ,
                (CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL
                                  THEN wtmj + ytwsmj
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) )END ) AS 获证未推货值操盘面积 ,

                  ----已完工已推出待售货量（B2-3）  +   未完工已推待售货量(B1-3) 
                (CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售' THEN syhz
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 END ) AS 已推未售货值操盘金额 ,
                (CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                  THEN wtmj + ytwsmj
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) END ) AS 已推未售货值操盘面积 ,

				 --年初情况:预售证在年初1月1号之前，已售+剩余
                                  ----已完工未推出未具备条件货量(B2-1)  + 未完工具备条件未获证货量(B1-1) 
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN syhz + ld.ThisYearSaleJeRg
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN syhz + +ld.ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) / 10000 AS 年初工程达到可售未拿证货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN zksmj - ysmj + ThisYearSaleMjQY
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN zksmj - ysmj + ThisYearSaleMjQY
                                    ELSE 0
                               END), 0) ) AS 年初工程达到可售未拿证货值面积 ,

                                  ----已完工未推出具备条件货量(B2-2) + 未完工已获证待推货量(B1-2)
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN syhz + ld.ThisYearSaleJeRg
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN syhz + ld.ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) / 10000 AS 年初获证未推货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN zksmj - ysmj + ThisYearSaleJeRg
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN zksmj - ysmj + ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) AS 年初获证未推货值面积 ,

                                  ----已完工已推出待售货量（B2-3）  +   未完工已推待售货量(B1-3) 
                ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN syhz + ld.ThisYearSaleJeRg
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN syhz + ld.ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) / 10000 AS 年初已推未售货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN zksmj - ysmj + ThisYearSaleJeRg
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN zksmj - ysmj + ThisYearSaleMjQY
                                    ELSE 0
                               END), 0) ) AS 年初已推未售货值面积 ,

                                  ---未开工货量(A1) + 已开工（在建）货量(A2)
                SUM(CASE WHEN b.hl_type IN ( '已开工', '未开工' ) THEN syhz
                         ELSE 0
                    END) / 10000 AS 后续预计达成货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '已开工', '未开工' ) THEN wtmj + ytwsmj
                         ELSE 0
                    END) AS 后续预计达成货量面积 ,
                                  --本年总可售
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(yy,
                                           ISNULL(ISNULL(ld.SjYsblDate,
                                                         YjYsblDate),
                                                  '2099-01-01'), GETDATE()) = 0
                         THEN zhz
                         ELSE 0
                    END) / 10000 AS 本年可售货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(yy,
                                           ISNULL(ISNULL(ld.SjYsblDate,
                                                         YjYsblDate),
                                                  '2099-01-01'), GETDATE()) = 0
                         THEN ld.zksmj --wtmj + ytwsmj
                         ELSE 0
                    END) 本年可售货量面积 ,
                SUM(CASE WHEN --b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推', '未完工已推待售', '已完工已推待售', '已完工未推' )
                              DATEDIFF(yy,
                                       ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                              '2099-01-01'), GETDATE()) >= 0
                         THEN ld.syhz
                         ELSE 0
                    END) / 10000 AS 本年剩余可售货量金额 ,
                SUM(CASE WHEN -- b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推', '未完工已推待售', '已完工已推待售', '已完工未推' )
                              DATEDIFF(yy,
                                       ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                              '2099-01-01'), GETDATE()) >= 0
                         THEN ld.zksmj - ld.ysmj
                         ELSE 0
                    END) AS 本年剩余可售货量面积 ,
				
				SUM(CASE WHEN --b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推', '未完工已推待售', '已完工已推待售', '已完工未推' )
                              DATEDIFF(dd,
                                       ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                              '2099-01-01'), GETDATE()) >= 0
                         THEN ld.syhz
                         ELSE 0
                    END) / 10000 AS 当前剩余可售货量金额 ,
                SUM(CASE WHEN -- b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推', '未完工已推待售', '已完工已推待售', '已完工未推' )
                              DATEDIFF(dd,
                                       ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                              '2099-01-01'), GETDATE()) >= 0
                         THEN ld.zksmj - ld.ysmj
                         ELSE 0
                    END) AS 当前剩余可售货量面积 ,

                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                         '2099-01-01') < CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01' THEN zhz
                         ELSE 0
                    END) / 10000 AS 本年之前可售货量金额 ,
                SUM(CASE WHEN ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                     '2099-01-01') < CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01'
                         THEN ld.zksmj
                         ELSE 0
                    END) 本年之前可售货量面积 ,
						 
                SUM(ISNULL(ld.ysje, 0) - ISNULL(ld.ThisYearSaleJeRg, 0))
                / 10000 AS 本年之前销售金额 ,
                SUM(ISNULL(ld.ysmj, 0) - ISNULL(ld.ThisYearSaleMjRg, 0)) AS 本年之前销售面积 ,
                ( SUM(CASE WHEN ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                       '2099-01-01') < CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01' THEN zhz
                           ELSE 0
                      END) - SUM(ISNULL(ld.ysje, 0)
                                 - ISNULL(ld.ThisYearSaleJeRg, 0)) ) / 10000 AS 本年初可售货量金额 ,
                SUM(CASE WHEN ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                     '2099-01-01') < CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01'
                         THEN ld.zksmj
                         ELSE 0
                    END) - SUM(ISNULL(ld.ysmj, 0) - ISNULL(ld.ThisYearSaleMjRg,
                                                           0)) AS 本年初可售货量面积 ,


                                  /*
月达成率：本月取证/本月预计取证
本月预计：预售证节点计划完成时间在本月的楼栋可售面积*预测单价
本月达成：预售证节点实际完成时间在本月的楼栋可售面积*预测单价
年达成率：本年取证/本年预计取证
本年预计：预售证节点计划完成时间在本年的楼栋可售面积*预测单价
本年达成：预售证节点实际完成时间在本年的楼栋可售面积*预测单价
*/
                                  --货量计划 
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Jan预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Jan实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                      CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-02-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Feb预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                          CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-02-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Feb实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-03-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Mar预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-03-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Mar实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-04-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Apr预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-04-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Apr实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-05-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS May预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-05-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS May实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-06-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Jun预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-06-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Jun实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-07-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS July预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-07-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS July实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-08-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Aug预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-08-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Aug实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                      CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-09-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Sep预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                          CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-09-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Sep实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                      CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-10-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Oct预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                          CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-10-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Oct实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-11-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Nov预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-11-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Nov实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-12-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Dec预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-12-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Dec实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS 本月预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS 本月实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(yy, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS 本年预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(yy,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS 本年实际货量金额 ,
                SUM(ThisYearSaleJeQY) / 10000 AS 本年已售货量金额 ,
                SUM(ThisYearSaleMjQY) AS 本年已售货量面积 ,
                CASE WHEN ISNULL(mp.TradersWay, '') <> '合作方操盘'
                     THEN SUM(CASE WHEN ISNULL(YjYsblDate, '2099-01-01') <= GETDATE()
                                        AND SjYsblDate IS NULL THEN syhz
                                   ELSE 0
                              END) / 10000
                     ELSE 0
                END AS 滞后货量金额 ,
                CASE WHEN ISNULL(mp.TradersWay, '') <> '合作方操盘'
                     THEN SUM(CASE WHEN ISNULL(YjYsblDate, '2099-01-01') <= GETDATE()
                                        AND SjYsblDate IS NULL
                                   THEN wtmj + ytwsmj
                                   ELSE 0
                              END)
                     ELSE 0
                END AS 滞后货量面积 ,
                SUM(CASE WHEN ld.SjYsblDate IS NULL
                              AND DATEDIFF(yy,
                                           ISNULL(ld.YjYsblDate, '2099-01-01'),
                                           GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS '今年后续预计达成货量金额' ,
                SUM(CASE WHEN ld.SjYsblDate IS NULL
                              AND DATEDIFF(yy,
                                           ISNULL(ld.YjYsblDate, '2099-01-01'),
                                           GETDATE()) = 0 THEN wtmj + ytwsmj
                         ELSE 0
                    END) / 10000 AS '今年后续预计达成货量面积' ,
                MIN(ld.YjDdysxxDate) AS '预计达到预售形象日期' ,
                MIN(ld.SjDdysxxDate) AS '实际达到预售形象日期' ,
                MIN(ld.YjYsblDate) AS '预计预售办理日期' ,
                MIN(ld.SjYsblDate) AS '实际预售办理日期' ,
                ld.hzdj AS '预计售价' ,
                CASE WHEN ( ISNULL(( SELECT TOP 1
                                            1
                                     FROM   #car car
                                     WHERE  car.SaleBldGUID = ld.SaleBldGUID
                                   ), 0) = 0 ) THEN 0
                     ELSE ( SUM(CASE WHEN DATEDIFF(yy,
                                                   ISNULL(ISNULL(ld.SjYsblDate,
                                                              YjYsblDate),
                                                          '2099-01-01'),
                                                   GETDATE()) = 0 THEN zhz
                                     ELSE 0
                                END) / 10000 )
                END 今年车位可售金额
        INTO    #ldhz
        FROM    erp25.dbo.p_lddb ld
                LEFT JOIN ( SELECT  SaleBldGUID ,
                                    CASE WHEN ISNULL(a.SJjgbadate,
                                                     '2099-01-01') < GETDATE()
                                              AND a.SJkpxsDate IS NOT NULL
                                         THEN '已完工已推待售'
                                         WHEN ISNULL(a.SJjgbadate,
                                                     '2099-01-01') < GETDATE()
                                         THEN '已完工未推'
                                         WHEN a.SJkpxsDate IS NOT NULL
                                         THEN '未完工已推待售'
                                         WHEN a.SjYsblDate IS NOT NULL
                                         THEN '未完工已获证未推'
                                         WHEN a.SjDdysxxDate IS NOT NULL
                                         THEN '未完工未获证未推'
                                         WHEN a.SJzskgdate IS NOT NULL
                                         THEN '已开工'
                                         ELSE '未开工'
                                    END hl_type
                            FROM    erp25.dbo.p_lddb a
                            WHERE   DATEDIFF(DAY, a.QXDate, GETDATE()) = 0
                                    AND ( ISNULL(a.IsSale, 0) = 1
                                          OR ( ISNULL(a.IsSale, 0) = 0
                                               AND a.ysje <> 0
                                             )
                                        )
                          ) b ON b.SaleBldGUID = ld.SaleBldGUID
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON ld.SaleBldGUID = bi.组织架构ID
                LEFT JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = ld.ProjGUID
        WHERE   DATEDIFF(DAY, QXDate, GETDATE()) = 0
                AND bi.组织架构类型 = 5
                AND ( ISNULL(IsSale, 0) = 1
                      OR ( ISNULL(IsSale, 0) = 0
                           AND ysje <> 0
                         )
                    )
          --AND ISNULL(mp.TradersWay, '') <> '合作方操盘'
                AND ld.ProjGUID NOT IN ( SELECT ProjGUID
                                         FROM   s_SaleValuePlanSet
                                         WHERE  IsPricePrediction = 2 )
				AND ld.ProjGUID NOT IN ( SELECT ProjGUID
                                         FROM   s_hndjdgProjList )
    --AND ld.DevelopmentCompanyGUID = 'AADC0FA7-9546-49C9-B64B-825056C828ED'
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                mp.TradersWay ,
                ld.hzdj ,
                ld.SaleBldGUID;


    --查询各业态货值数据
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ythz')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #ythz;
            END;

        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                SUM(zhz) / 10000 AS 总货值金额 ,
                SUM(zksmj) AS 总货值面积 ,
				SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  zhz END ) / 10000 AS 总货值操盘金额 ,
                SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  zksmj END ) AS 总货值操盘面积 ,

                SUM(ysje) / 10000 AS 已售货量金额 ,
                SUM(ysmj) AS 已售货量面积 ,
				SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  ysje END ) / 10000 AS 已售货量操盘金额 ,
                SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  ysmj END ) AS 已售货量操盘面积 ,

                SUM(syhz) / 10000 AS 未销售部分货量 ,
                SUM(ISNULL(ytwsmj, 0) + ISNULL(wtmj, 0)) AS 未销售部分可售面积 ,
                SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  syhz END ) / 10000 AS 未销售部分操盘货量 ,
                SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  ISNULL(ytwsmj, 0) + ISNULL(wtmj, 0) END ) AS 未销售部分可售操盘面积 ,
				 
                ( ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                         AND SjDdysxxDate IS NULL THEN syhz
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推' THEN syhz
                                      ELSE 0
                                 END), 0) )
                  + ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                           AND SjDdysxxDate IS NOT NULL
                                      THEN syhz
                                      ELSE 0
                                 END), 0)
                      + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推' THEN syhz
                                        ELSE 0
                                   END), 0) )
                  + ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售' THEN syhz
                                      ELSE 0
                                 END), 0)
                      + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售' THEN syhz
                                        ELSE 0
                                   END), 0) ) ) / 10000 AS 剩余可售货值金额 , --待售货量 B1 + B2
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                  THEN wtmj + ytwsmj
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) )
                + ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                         AND SjDdysxxDate IS NOT NULL
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                      THEN wtmj + ytwsmj
                                      ELSE 0
                                 END), 0) )
                + ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                      THEN wtmj + ytwsmj
                                      ELSE 0
                                 END), 0) ) AS 剩余可售货值面积 , --待售货量

                

                                  --本月情况
                                  ----已完工未推出未具备条件货量(B2-1)  + 未完工具备条件未获证货量(B1-1) 
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL THEN syhz
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 AS 工程达到可售未拿证货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                  THEN wtmj + ytwsmj
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) AS 工程达到可售未拿证货值面积 ,

                                  ----已完工未推出具备条件货量(B2-2) + 未完工已获证待推货量(B1-2)
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL THEN syhz
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 AS 获证未推货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL
                                  THEN wtmj + ytwsmj
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) AS 获证未推货值面积 ,

                                  ----已完工已推出待售货量（B2-3）  +   未完工已推待售货量(B1-3) 
                ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售' THEN syhz
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 AS 已推未售货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                  THEN wtmj + ytwsmj
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) AS 已推未售货值面积 ,

				CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE ( ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                         AND SjDdysxxDate IS NULL THEN syhz
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推' THEN syhz
                                      ELSE 0
                                 END), 0) )
                  + ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                           AND SjDdysxxDate IS NOT NULL
                                      THEN syhz
                                      ELSE 0
                                 END), 0)
                      + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推' THEN syhz
                                        ELSE 0
                                   END), 0) )
                  + ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售' THEN syhz
                                      ELSE 0
                                 END), 0)
                      + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售' THEN syhz
                                        ELSE 0
                                   END), 0) ) ) / 10000 END  AS 剩余可售货值操盘金额 , --待售货量 B1 + B2
                CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                  THEN wtmj + ytwsmj
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) )
                + ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                         AND SjDdysxxDate IS NOT NULL
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                      THEN wtmj + ytwsmj
                                      ELSE 0
                                 END), 0) )
                + ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                      THEN wtmj + ytwsmj
                                      ELSE 0
                                 END), 0) ) END AS 剩余可售货值操盘面积 , --待售货量

                

                                  --本月情况
                                  ----已完工未推出未具备条件货量(B2-1)  + 未完工具备条件未获证货量(B1-1) 
                CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL THEN syhz
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 END AS 工程达到可售未拿证货值操盘金额 ,
                CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                  THEN wtmj + ytwsmj
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) END AS 工程达到可售未拿证货值操盘面积 ,

                                  ----已完工未推出具备条件货量(B2-2) + 未完工已获证待推货量(B1-2)
                CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL THEN syhz
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 END  AS 获证未推货值操盘金额 ,
                CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL
                                  THEN wtmj + ytwsmj
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) END  AS 获证未推货值操盘面积 ,

                                  ----已完工已推出待售货量（B2-3）  +   未完工已推待售货量(B1-3) 
                CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售' THEN syhz
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 END  AS 已推未售货值操盘金额 ,
                CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                  THEN wtmj + ytwsmj
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) END AS 已推未售货值操盘面积 ,

				 --年初情况:预售证在年初1月1号之前，已售+剩余
                 ----已完工未推出未具备条件货量(B2-1)  + 未完工具备条件未获证货量(B1-1) 
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN syhz + ld.ThisYearSaleJeRg
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN syhz + ld.ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) / 10000 AS 年初工程达到可售未拿证货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN zksmj - ysmj + ThisYearSaleJeRg
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN zksmj - ysmj + ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) AS 年初工程达到可售未拿证货值面积 ,

                                  ----已完工未推出具备条件货量(B2-2) + 未完工已获证待推货量(B1-2)
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN syhz + ld.ThisYearSaleJeRg
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN syhz + ld.ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) / 10000 AS 年初获证未推货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN zksmj - ysmj + ThisYearSaleJeRg
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN zksmj - ysmj + ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) AS 年初获证未推货值面积 ,

                                  ----已完工已推出待售货量（B2-3）  +   未完工已推待售货量(B1-3) 
                ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN syhz + ld.ThisYearSaleJeRg
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN syhz + ld.ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) / 10000 AS 年初已推未售货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN zksmj - ysmj + ThisYearSaleJeRg
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN zksmj - ysmj + ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) AS 年初已推未售货值面积 ,

                                  ---未开工货量(A1) + 已开工（在建）货量(A2)
                SUM(CASE WHEN b.hl_type IN ( '已开工', '未开工' ) THEN syhz
                         ELSE 0
                    END) / 10000 AS 后续预计达成货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '已开工', '未开工' ) THEN wtmj + ytwsmj
                         ELSE 0
                    END) AS 后续预计达成货量面积 ,
                                  --本年可售
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(yy,
                                           ISNULL(ISNULL(ld.SjYsblDate,
                                                         YjYsblDate),
                                                  '2099-01-01'), GETDATE()) = 0
                         THEN zhz
                         ELSE 0
                    END) / 10000 AS 本年可售货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(yy,
                                           ISNULL(ISNULL(ld.SjYsblDate,
                                                         YjYsblDate),
                                                  '2099-01-01'), GETDATE()) = 0
                         THEN ld.zksmj --wtmj + ytwsmj
                         ELSE 0
                    END) 本年可售货量面积 ,
                SUM(CASE WHEN --b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推', '未完工已推待售', '已完工已推待售', '已完工未推' )
                              DATEDIFF(yy,
                                       ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                              '2099-01-01'), GETDATE()) >= 0
                         THEN ld.syhz
                         ELSE 0
                    END) / 10000 AS 本年剩余可售货量金额 ,
                SUM(CASE WHEN --b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推', '未完工已推待售', '已完工已推待售', '已完工未推' )
                              DATEDIFF(yy,
                                       ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                              '2099-01-01'), GETDATE()) >= 0
                         THEN ld.zksmj - ld.ysmj
                         ELSE 0
                    END) AS 本年剩余可售货量面积 ,
				SUM(CASE WHEN --b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推', '未完工已推待售', '已完工已推待售', '已完工未推' )
                              DATEDIFF(dd,
                                       ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                              '2099-01-01'), GETDATE()) >= 0
                         THEN ld.syhz
                         ELSE 0
                    END) / 10000 AS 当前剩余可售货量金额 ,
                SUM(CASE WHEN -- b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推', '未完工已推待售', '已完工已推待售', '已完工未推' )
                              DATEDIFF(dd,
                                       ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                              '2099-01-01'), GETDATE()) >= 0
                         THEN ld.zksmj - ld.ysmj
                         ELSE 0
                    END) AS 当前剩余可售货量面积 ,
                SUM(CASE WHEN ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                     '2099-01-01') < CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01' THEN zhz
                         ELSE 0
                    END) / 10000 AS 本年之前可售货量金额 ,
                SUM(CASE WHEN ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                     '2099-01-01') < CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01'
                         THEN ld.zksmj
                         ELSE 0
                    END) 本年之前可售货量面积 ,
                SUM(ISNULL(ld.ysje, 0) - ISNULL(ld.ThisYearSaleJeRg, 0))
                / 10000 AS 本年之前销售金额 ,
                SUM(ISNULL(ld.ysmj, 0) - ISNULL(ld.ThisYearSaleMjRg, 0)) AS 本年之前销售面积 ,
                ( SUM(CASE WHEN ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                       '2099-01-01') < CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01' THEN zhz
                           ELSE 0
                      END) - SUM(ISNULL(ld.ysje, 0)
                                 - ISNULL(ld.ThisYearSaleJeRg, 0)) ) / 10000 AS 本年初可售货量金额 ,
                SUM(CASE WHEN ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                     '2099-01-01') < CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01'
                         THEN ld.zksmj
                         ELSE 0
                    END) - SUM(ISNULL(ld.ysmj, 0) - ISNULL(ld.ThisYearSaleMjRg,
                                                           0)) AS 本年初可售货量面积 ,

                                  --货量计划 
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Jan预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Jan实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                      CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-02-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Feb预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                          CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-02-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Feb实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-03-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Mar预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-03-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Mar实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-04-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Apr预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-04-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Apr实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-05-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS May预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-05-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS May实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-06-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Jun预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-06-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Jun实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-07-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS July预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-07-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS July实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-08-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Aug预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-08-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Aug实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                      CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-09-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Sep预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                          CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-09-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Sep实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                      CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-10-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Oct预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                          CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-10-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Oct实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-11-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Nov预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-11-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Nov实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-12-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Dec预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-12-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Dec实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS 本月预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS 本月实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(yy, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS 本年预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(yy,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS 本年实际货量金额 ,
                SUM(ThisYearSaleJeQY) / 10000 AS 本年已售货量金额 ,
                SUM(ThisYearSaleMjQY) AS 本年已售货量面积 ,
                                  --非操盘项目不再计算滞后货量
                CASE WHEN ISNULL(mp.TradersWay, '') <> '合作方操盘'
                     THEN SUM(CASE WHEN ISNULL(YjYsblDate, '2099-01-01') <= GETDATE()
                                        AND SjYsblDate IS NULL THEN syhz
                                   ELSE 0
                              END) / 10000
                     ELSE 0
                END AS 滞后货量金额 ,
                CASE WHEN ISNULL(mp.TradersWay, '') <> '合作方操盘'
                     THEN SUM(CASE WHEN ISNULL(YjYsblDate, '2099-01-01') <= GETDATE()
                                        AND SjYsblDate IS NULL
                                   THEN wtmj + ytwsmj
                                   ELSE 0
                              END)
                     ELSE 0
                END AS 滞后货量面积 ,
                SUM(CASE WHEN ld.SjYsblDate IS NULL
                              AND DATEDIFF(yy,
                                           ISNULL(ld.YjYsblDate, '2099-01-01'),
                                           GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS '今年后续预计达成货量金额' ,
                SUM(CASE WHEN ld.SjYsblDate IS NULL
                              AND DATEDIFF(yy,
                                           ISNULL(ld.YjYsblDate, '2099-01-01'),
                                           GETDATE()) = 0 THEN wtmj + ytwsmj
                         ELSE 0
                    END) / 10000 AS '今年后续预计达成货量面积' ,
                MIN(ld.YjDdysxxDate) AS '预计达到预售形象日期' ,
                MIN(ld.SjDdysxxDate) AS '实际达到预售形象日期' ,
                MIN(ld.YjYsblDate) AS '预计预售办理日期' ,
                MIN(ld.SjYsblDate) AS '实际预售办理日期' ,
                ld.hzdj AS '预计售价' ,
                CASE WHEN ( ISNULL(( SELECT TOP 1
                                            1
                                     FROM   #car car
                                     WHERE  car.SaleBldGUID = ld.SaleBldGUID
                                   ), 0) = 0 ) THEN 0
                     ELSE ( SUM(CASE WHEN DATEDIFF(yy,
                                                   ISNULL(ISNULL(ld.SjYsblDate,
                                                              YjYsblDate),
                                                          '2099-01-01'),
                                                   GETDATE()) = 0 THEN zhz
                                     ELSE 0
                                END) / 10000 )
                END 今年车位可售金额
        INTO    #ythz
        FROM    erp25.dbo.p_lddb ld
                LEFT JOIN ( SELECT  SaleBldGUID ,
                                    CASE WHEN ISNULL(a.SJjgbadate,
                                                     '2099-01-01') < GETDATE()
                                              AND a.SJkpxsDate IS NOT NULL
                                         THEN '已完工已推待售'
                                         WHEN ISNULL(a.SJjgbadate,
                                                     '2099-01-01') < GETDATE()
                                         THEN '已完工未推'
                                         WHEN a.SJkpxsDate IS NOT NULL
                                         THEN '未完工已推待售'
                                         WHEN a.SjYsblDate IS NOT NULL
                                         THEN '未完工已获证未推'
                                         WHEN a.SjDdysxxDate IS NOT NULL
                                         THEN '未完工未获证未推'
                                         WHEN a.SJzskgdate IS NOT NULL
                                         THEN '已开工'
                                         ELSE '未开工'
                                    END hl_type
                            FROM    erp25.dbo.p_lddb a
                            WHERE   DATEDIFF(DAY, a.QXDate, GETDATE()) = 0
                                    AND ( ISNULL(IsSale, 0) = 1
                                          OR ( ISNULL(IsSale, 0) = 0
                                               AND ysje <> 0
                                             )
                                        )
                          ) b ON b.SaleBldGUID = ld.SaleBldGUID
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON ld.ProjGUID = bi.组织架构父级ID
                                                         AND bi.组织架构名称 = ld.ProductType
                LEFT JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = ld.ProjGUID
        WHERE   DATEDIFF(DAY, QXDate, GETDATE()) = 0
                AND bi.组织架构类型 = 4
                AND ( ISNULL(IsSale, 0) = 1
                      OR ( ISNULL(IsSale, 0) = 0
                           AND ysje <> 0
                         )
                    )
          --AND ISNULL(mp.TradersWay, '') <> '合作方操盘'
                AND ld.ProjGUID NOT IN ( SELECT ProjGUID
                                         FROM   s_SaleValuePlanSet
                                         WHERE  IsPricePrediction = 2 )
				AND ld.ProjGUID NOT IN ( SELECT ProjGUID
                                         FROM   s_hndjdgProjList )
    --AND ld.DevelopmentCompanyGUID = 'AADC0FA7-9546-49C9-B64B-825056C828ED'
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                mp.TradersWay ,
                ld.hzdj ,
                ld.SaleBldGUID;


    --货量看板的非操盘项目的“当前可售货量”和“其中”和“后续预计达成”和“今年后续预计达成”应该取货量铺排的数据； 
    /*
        统计已售货量要按这样的逻辑：
		1、非操盘项目，取合计项目业绩；
		2、尾盘项目（线下铺排），取销售系统已售业绩；
		3、新项目（线下铺排），取销售系统已售业绩；
		4、常规项目（线上铺排），取销售系统已售业绩；
       */
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ythz2_1')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #ythz2_1;
            END;

        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                mp.ProjGUID ,
                a.SaleValuePlanYear ,
                a.SaleValuePlanMonth ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 剩余可售货值金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleAreaQzkj, 0))
                     ELSE 0
                END AS 剩余可售货值面积 ,
                0 AS 工程达到可售未拿证货值金额 ,
                0 AS 工程达到可售未拿证货值面积 ,
                0 AS 获证未推货值金额 ,
                0 AS 获证未推货值面积 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 已推未售货值金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleAreaQzkj, 0))
                     ELSE 0
                END AS 已推未售货值面积 , 

				CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
							AND mp.TradersWay <>'合作方操盘'
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 剩余可售货值操盘金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
							AND mp.TradersWay <>'合作方操盘'
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleAreaQzkj, 0))
                     ELSE 0
                END AS 剩余可售货值操盘面积 ,
				0 AS 工程达到可售未拿证货值操盘金额 ,
                0 AS 工程达到可售未拿证货值操盘面积 ,
                0 AS 获证未推货值操盘金额 ,
                0 AS 获证未推货值操盘面积 ,
				CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
							AND mp.TradersWay <> '合作方操盘'
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 已推未售货值操盘金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
							AND mp.TradersWay <> '合作方操盘'
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleAreaQzkj, 0))
                     ELSE 0
                END AS 已推未售货值操盘面积 ,

				0 AS 年初工程达到可售未拿证货值金额 ,
                0 AS 年初工程达到可售未拿证货值面积 ,
                0 AS 年初获证未推货值金额 ,
                0 AS 年初获证未推货值面积 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = 1
                          ) THEN SUM(ISNULL(a.EarlySaleMoneyQzkj, 0))
                     ELSE 0
                END AS 年初已推未售货值金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = 1
                          ) THEN SUM(ISNULL(a.EarlySaleAreaQzkj, 0))
                     ELSE 0
                END AS 年初已推未售货值面积 ,

                0 AS 后续预计达成货量金额 ,
                0 AS 后续预计达成货量面积 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.YearTotalSumSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 本年可售货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.YearTotalSumSaleAreaQzkj, 0))
                     ELSE 0
                END AS 本年可售货量面积 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 本年剩余可售货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleAreaQzkj, 0))
                     ELSE 0
                END AS 本年剩余可售货量面积 ,
				 CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 当前剩余可售货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleAreaQzkj, 0))
                     ELSE 0
                END AS 当前剩余可售货量面积 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '1'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Jan预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '1'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Jan实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '2'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Feb预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '2'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Feb实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '3'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Mar预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '3'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Mar实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '4'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Apr预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '4'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Apr实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '5'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS May预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '5'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS May实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '6'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Jun预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '6'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Jun实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '7'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS July预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '7'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS July实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '8'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Aug预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '8'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Aug实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '9'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Sep预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '9'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Sep实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '10'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Oct预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '10'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Oct实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '11'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Nov预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '11'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Nov实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '12'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Dec预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = '12'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Dec实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 本月预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 本月实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.YearTotalSumSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 本年预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.YearTotalSumSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 本年实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.YearTotalSaleMoneyRg, 0))
                     ELSE 0
                END AS 本年已售货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.YearTotalSaleAreaRg, 0))
                     ELSE 0
                END AS 本年已售货量面积 ,
                0 AS 滞后货量金额 ,
                0 AS 滞后货量面积 ,
                CASE WHEN CHARINDEX('车', a.ProductType) > 0
                     THEN SUM(ISNULL(a.YearTotalSumSaleMoneyQzkj, 0))
                     ELSE 0
                END 今年车位可售金额
        INTO    #ythz2_1
        FROM    s_SaleValuePlan a
                LEFT JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
                LEFT JOIN erp25.dbo.ydkb_BaseInfo bi ON a.ProjGUID = bi.组织架构父级ID
                                                        AND bi.组织架构名称 = a.ProductType
        WHERE   bi.组织架构类型 = 4
                AND SaleValuePlanYear = YEAR(GETDATE())
                AND a.ProjGUID IN ( SELECT  ProjGUID
                                    FROM    s_SaleValuePlanSet
                                    WHERE   IsPricePrediction = 2 )
				AND a.ProjGUID NOT IN ( SELECT ProjGUID
                                         FROM   s_hndjdgProjList )
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                mp.ProjGUID ,
                a.ProductType ,
                a.SaleValuePlanYear ,
                a.SaleValuePlanMonth,
				mp.TradersWay;


        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ythz2')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #ythz2;
            END;

        SELECT  aa.组织架构ID ,
                aa.组织架构名称 ,
                aa.组织架构编码 ,
                aa.组织架构类型 ,
                ISNULL(bb.zhz, 0) / 10000 AS 总货值金额 ,
                ISNULL(bb.zksmj, 0) AS 总货值面积 ,
                ISNULL(bb.zhz1, 0) / 10000 AS 总货值操盘金额 ,
                ISNULL(bb.zksmj1, 0)  AS 总货值操盘面积 ,
				                                                      
                CASE WHEN ISNULL(bb.ysje, 0) <> 0
                     THEN ISNULL(bb.ysje, 0) / 10000
                     ELSE ISNULL(cc.累计销售金额, 0)
                END AS 已售货量金额 ,
                CASE WHEN ISNULL(bb.ysmj, 0) <> 0 THEN ISNULL(bb.ysmj, 0)
                     ELSE ISNULL(cc.累计销售面积, 0)
                END AS 已售货量面积 ,
				 CASE WHEN ISNULL(bb.ysje1, 0) <> 0
                     THEN ISNULL(bb.ysje1, 0) / 10000
                     ELSE ISNULL(cc.累计销售操盘金额, 0)
                END AS 已售货量操盘金额 ,
                CASE WHEN ISNULL(bb.ysmj1, 0) <> 0 THEN ISNULL(bb.ysmj1, 0)
                     ELSE ISNULL(cc.累计销售操盘面积, 0)
                END AS 已售货量操盘面积 ,

                CASE WHEN ISNULL(bb.ysje, 0) <> 0
                     THEN ( ISNULL(bb.zhz, 0) - ISNULL(bb.ysje, 0) ) / 10000
                     ELSE ISNULL(bb.zhz, 0) / 10000 - ISNULL(cc.累计销售金额, 0)
                END AS 未销售部分货量 ,
                CASE WHEN ISNULL(bb.ysmj, 0) <> 0
                     THEN ( ISNULL(bb.zksmj, 0) - ISNULL(bb.ysmj, 0) )
                     ELSE ISNULL(bb.zksmj, 0) - ISNULL(cc.累计销售面积, 0)
                END AS 未销售部分可售面积 ,
				CASE WHEN ISNULL(bb.ysje1, 0) <> 0
                     THEN ( ISNULL(bb.zhz1, 0) - ISNULL(bb.ysje1, 0) ) / 10000
                     ELSE ISNULL(bb.zhz1, 0) / 10000 - ISNULL(cc.累计销售操盘金额, 0)
                END AS 未销售部分操盘货量 ,
                CASE WHEN ISNULL(bb.ysmj1, 0) <> 0
                     THEN ( ISNULL(bb.zksmj1, 0) - ISNULL(bb.ysmj1, 0) )
                     ELSE ISNULL(bb.zksmj1, 0) - ISNULL(cc.累计销售操盘面积, 0)
                END AS 未销售部分可售操盘面积 ,
				

		   --湾区的谢立峰要求，手工导数的部分要按照货量铺排的来取，而不是按照系统的销售情况来算出剩余可售货值
                ISNULL(aa.剩余可售货值金额, 0) / 10000 AS 剩余可售货值金额 ,
                ISNULL(aa.剩余可售货值面积, 0) AS 剩余可售货值面积 ,
                0 AS 工程达到可售未拿证货值金额 ,
                0 AS 工程达到可售未拿证货值面积 ,
                0 AS 获证未推货值金额 ,
                0 AS 获证未推货值面积 , 
                ISNULL(aa.已推未售货值金额, 0) / 10000 AS 已推未售货值金额 ,
                ISNULL(aa.已推未售货值面积, 0) AS 已推未售货值面积 ,

				ISNULL(aa.剩余可售货值操盘金额, 0) / 10000 AS 剩余可售货值操盘金额 ,
                ISNULL(aa.剩余可售货值操盘面积, 0) AS 剩余可售货值操盘面积 ,
				0 AS 工程达到可售未拿证货值操盘金额 ,
                0 AS 工程达到可售未拿证货值操盘面积 ,
                0 AS 获证未推货值操盘金额 ,
                0 AS 获证未推货值操盘面积 , 
                ISNULL(aa.已推未售货值操盘金额, 0) / 10000 AS 已推未售货值操盘金额 ,
                ISNULL(aa.已推未售货值操盘面积, 0) AS 已推未售货值操盘面积 ,

				--年初情况
                ISNULL(aa.年初已推未售货值金额, 0) / 10000 AS 年初已推未售货值金额 ,
                ISNULL(aa.年初已推未售货值面积, 0) AS 年初已推未售货值面积 , --年初情况：剩余+已售
				0 AS 年初工程达到可售未拿证货值金额 ,
                0 AS 年初工程达到可售未拿证货值面积 ,
                0 AS 年初获证未推货值金额 ,
                0 AS 年初获证未推货值面积 ,
                0 AS 后续预计达成货量金额 ,
                0 AS 后续预计达成货量面积 ,
                ISNULL(aa.本年可售货量金额, 0) / 10000 AS 本年可售货量金额 ,
                ISNULL(aa.本年可售货量面积, 0) AS 本年可售货量面积 ,
                ISNULL(aa.本年剩余可售货量金额, 0) / 10000 AS 本年剩余可售货量金额 ,
                ISNULL(aa.本年剩余可售货量面积, 0) AS 本年剩余可售货量面积 ,
				ISNULL(aa.当前剩余可售货量金额, 0) / 10000 AS 当前剩余可售货量金额 ,
                ISNULL(aa.当前剩余可售货量面积, 0) AS 当前剩余可售货量面积 ,
                ISNULL(aa.Jan预计货量金额, 0) / 10000 Jan预计货量金额 ,
                ISNULL(aa.Jan实际货量金额, 0) / 10000 Jan实际货量金额 ,
                ISNULL(aa.Feb预计货量金额, 0) / 10000 Feb预计货量金额 ,
                ISNULL(aa.Feb实际货量金额, 0) / 10000 Feb实际货量金额 ,
                ISNULL(aa.Mar预计货量金额, 0) / 10000 Mar预计货量金额 ,
                ISNULL(aa.Mar实际货量金额, 0) / 10000 Mar实际货量金额 ,
                ISNULL(aa.Apr预计货量金额, 0) / 10000 Apr预计货量金额 ,
                ISNULL(aa.Apr实际货量金额, 0) / 10000 Apr实际货量金额 ,
                ISNULL(aa.May预计货量金额, 0) / 10000 May预计货量金额 ,
                ISNULL(aa.May实际货量金额, 0) / 10000 May实际货量金额 ,
                ISNULL(aa.Jun预计货量金额, 0) / 10000 Jun预计货量金额 ,
                ISNULL(aa.Jun实际货量金额, 0) / 10000 Jun实际货量金额 ,
                ISNULL(aa.July预计货量金额, 0) / 10000 July预计货量金额 ,
                ISNULL(aa.July实际货量金额, 0) / 10000 July实际货量金额 ,
                ISNULL(aa.Aug预计货量金额, 0) / 10000 Aug预计货量金额 ,
                ISNULL(aa.Aug实际货量金额, 0) / 10000 Aug实际货量金额 ,
                ISNULL(aa.Sep预计货量金额, 0) / 10000 Sep预计货量金额 ,
                ISNULL(aa.Sep实际货量金额, 0) / 10000 Sep实际货量金额 ,
                ISNULL(aa.Oct预计货量金额, 0) / 10000 Oct预计货量金额 ,
                ISNULL(aa.Oct预计货量金额, 0) / 10000 Oct实际货量金额 ,
                ISNULL(aa.Nov预计货量金额, 0) / 10000 Nov预计货量金额 ,
                ISNULL(aa.Nov实际货量金额, 0) / 10000 Nov实际货量金额 ,
                ISNULL(aa.Dec预计货量金额, 0) / 10000 Dec预计货量金额 ,
                ISNULL(aa.Dec实际货量金额, 0) / 10000 Dec实际货量金额 ,
                ISNULL(aa.本月预计货量金额, 0) / 10000 AS 本月预计货量金额 ,
                ISNULL(aa.本月实际货量金额, 0) / 10000 AS 本月实际货量金额 ,
                ISNULL(aa.本年预计货量金额, 0) / 10000 AS 本年预计货量金额 ,
                ISNULL(aa.本年实际货量金额, 0) / 10000 AS 本年实际货量金额 ,
                ISNULL(cc.本年销售金额, 0) AS 本年已售货量金额 ,
                ISNULL(cc.本年销售面积, 0) AS 本年已售货量面积 ,
                0 AS 滞后货量金额 ,
                0 AS 滞后货量面积 ,
                ISNULL(aa.今年车位可售金额, 0) / 10000 今年车位可售金额
        INTO    #ythz2
        FROM    ( SELECT    bi.组织架构ID ,
                            bi.组织架构名称 ,
                            bi.组织架构编码 ,
                            bi.组织架构类型 ,
                            bi.ProjGUID ,
                            SUM(剩余可售货值金额) AS 剩余可售货值金额 ,
                            SUM(剩余可售货值面积) AS 剩余可售货值面积 , 
                            SUM(工程达到可售未拿证货值金额) AS 工程达到可售未拿证货值金额 ,
                            SUM(工程达到可售未拿证货值面积) AS 工程达到可售未拿证货值面积 ,
                            SUM(获证未推货值金额) AS 获证未推货值金额 ,
                            SUM(获证未推货值面积) AS 获证未推货值面积 ,
                            SUM(已推未售货值金额) AS 已推未售货值金额 ,
                            SUM(已推未售货值面积) AS 已推未售货值面积 ,
							SUM(剩余可售货值操盘金额) AS 剩余可售货值操盘金额 ,
                            SUM(剩余可售货值操盘面积) AS 剩余可售货值操盘面积 , 
                            SUM(工程达到可售未拿证货值操盘金额) AS 工程达到可售未拿证货值操盘金额 ,
                            SUM(工程达到可售未拿证货值操盘面积) AS 工程达到可售未拿证货值操盘面积 ,
                            SUM(获证未推货值操盘金额) AS 获证未推货值操盘金额 ,
                            SUM(获证未推货值操盘面积) AS 获证未推货值操盘面积 ,
                            SUM(已推未售货值操盘金额) AS 已推未售货值操盘金额 ,
                            SUM(已推未售货值操盘面积) AS 已推未售货值操盘面积 ,
							SUM(年初工程达到可售未拿证货值金额) AS 年初工程达到可售未拿证货值金额 ,
                            SUM(年初工程达到可售未拿证货值面积) AS 年初工程达到可售未拿证货值面积 ,
                            SUM(年初获证未推货值金额) AS 年初获证未推货值金额 ,
                            SUM(年初获证未推货值面积) AS 年初获证未推货值面积 ,
                            SUM(年初已推未售货值金额) AS 年初已推未售货值金额 ,
                            SUM(年初已推未售货值面积) AS 年初已推未售货值面积 ,
                            SUM(后续预计达成货量金额) AS 后续预计达成货量金额 ,
                            SUM(后续预计达成货量面积) AS 后续预计达成货量面积 ,
                            SUM(本年可售货量金额) AS 本年可售货量金额 ,
                            SUM(本年可售货量面积) AS 本年可售货量面积 ,
                            SUM(本年剩余可售货量金额) AS 本年剩余可售货量金额 ,
                            SUM(本年剩余可售货量面积) AS 本年剩余可售货量面积 ,
							SUM(当前剩余可售货量金额) AS 当前剩余可售货量金额 ,
                            SUM(当前剩余可售货量面积) AS 当前剩余可售货量面积 ,
                            SUM(Jan预计货量金额) AS Jan预计货量金额 ,
                            SUM(Jan实际货量金额) AS Jan实际货量金额 ,
                            SUM(Feb预计货量金额) AS Feb预计货量金额 ,
                            SUM(Feb实际货量金额) AS Feb实际货量金额 ,
                            SUM(Mar预计货量金额) AS Mar预计货量金额 ,
                            SUM(Mar实际货量金额) AS Mar实际货量金额 ,
                            SUM(Apr预计货量金额) AS Apr预计货量金额 ,
                            SUM(Apr实际货量金额) AS Apr实际货量金额 ,
                            SUM(May预计货量金额) AS May预计货量金额 ,
                            SUM(May实际货量金额) AS May实际货量金额 ,
                            SUM(Jun预计货量金额) AS Jun预计货量金额 ,
                            SUM(Jun实际货量金额) AS Jun实际货量金额 ,
                            SUM(July预计货量金额) AS July预计货量金额 ,
                            SUM(July实际货量金额) AS July实际货量金额 ,
                            SUM(Aug预计货量金额) AS Aug预计货量金额 ,
                            SUM(Aug实际货量金额) AS Aug实际货量金额 ,
                            SUM(Sep预计货量金额) AS Sep预计货量金额 ,
                            SUM(Sep实际货量金额) AS Sep实际货量金额 ,
                            SUM(Oct预计货量金额) AS Oct预计货量金额 ,
                            SUM(Oct实际货量金额) AS Oct实际货量金额 ,
                            SUM(Nov预计货量金额) AS Nov预计货量金额 ,
                            SUM(Nov实际货量金额) AS Nov实际货量金额 ,
                            SUM(Dec预计货量金额) AS Dec预计货量金额 ,
                            SUM(Dec实际货量金额) AS Dec实际货量金额 ,
                            SUM(本月预计货量金额) AS 本月预计货量金额 ,
                            SUM(本月实际货量金额) AS 本月实际货量金额 ,
                            SUM(本年预计货量金额) AS 本年预计货量金额 ,
                            SUM(本年实际货量金额) AS 本年实际货量金额 ,
                            SUM(本年已售货量金额) AS 本年已售货量金额 ,
                            SUM(本年已售货量面积) AS 本年已售货量面积 ,
                            SUM(滞后货量金额) AS 滞后货量金额 ,
                            SUM(滞后货量面积) AS 滞后货量面积 ,
                            SUM(今年车位可售金额) AS 今年车位可售金额
                  FROM      #ythz2_1 bi
                  GROUP BY  bi.组织架构ID ,
                            bi.组织架构名称 ,
                            bi.组织架构编码 ,
                            bi.组织架构类型 ,
                            bi.ProjGUID
                ) aa
                LEFT JOIN (
            ---总货量字段不要取手动导入的货量，要取楼栋底表的面积*单价；
                            SELECT  ld.ProjGUID ,
                                    ProductType ,
                                    SUM(zhz) AS zhz ,
                                    SUM(zksmj) AS zksmj ,
                                    SUM(ysje) AS ysje ,
                                    SUM(ysmj) AS ysmj,
									SUM(CASE WHEN mp.tradersway ='合作方操盘' THEN 0 else zhz END ) AS zhz1 ,
                                    SUM(CASE WHEN mp.tradersway ='合作方操盘' THEN 0 ELSE zksmj END ) AS zksmj1 ,
                                    SUM(CASE WHEN mp.tradersway ='合作方操盘' THEN 0 ELSE ysje END ) AS ysje1 ,
                                    SUM(CASE WHEN mp.tradersway ='合作方操盘' THEN 0 ELSE ysmj END ) AS ysmj1
                            FROM    erp25.dbo.p_lddb ld
							        LEFT JOIN dbo.mdm_Project mp ON ld.ProjGUID = mp.ProjGUID
                            WHERE   DATEDIFF(DAY, QXDate, GETDATE()) = 0
                                    AND ( ISNULL(IsSale, 0) = 1
                                          OR ( ISNULL(IsSale, 0) = 0
                                               AND ysje <> 0
                                             )
                                        )
                                    AND ld.ProjGUID IN (
                                    SELECT  ProjGUID
                                    FROM    s_SaleValuePlanSet
                                    WHERE   IsPricePrediction = 2 )
                            GROUP BY ld.ProjGUID ,
                                    ProductType,
									mp.TradersWay
                          ) bb ON bb.ProjGUID = aa.ProjGUID
                                  AND bb.ProductType = aa.组织架构名称
                LEFT JOIN ( SELECT  c.ProjGUID ,
                                    a.ProductType ,
                                    SUM(a.Amount) AS 累计销售金额 , --单位万元
                                    SUM(a.Area) AS 累计销售面积 ,
                                    SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.Amount
                                             ELSE 0
                                        END) AS 本年销售金额 ,
                                    SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.Area
                                             ELSE 0
                                        END) AS 本年销售面积,
									SUM(CASE WHEN p.TradersWay='合作方操盘' THEN 0 ELSE a.Amount END ) AS 累计销售操盘金额 , --单位万元
                                    SUM(CASE WHEN p.TradersWay='合作方操盘' THEN 0 ELSE a.Area END ) AS 累计销售操盘面积 ,
                                    SUM(CASE WHEN p.TradersWay='合作方操盘' THEN 0 ELSE(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.Amount
                                             ELSE 0
                                        END) END ) AS 本年销售操盘金额 ,
                                    SUM(CASE WHEN p.TradersWay='合作方操盘' THEN 0 ELSE(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.Area
                                             ELSE 0
                                        END) END ) AS 本年销售操盘面积
                            FROM    dbo.s_YJRLProducteDescript a
                                    LEFT JOIN ( SELECT  * ,
                                                        CONVERT(DATETIME, b.DateYear
                                                        + '-' + b.DateMonth
                                                        + '-01') AS [BizDate]
                                                FROM    dbo.s_YJRLProducteDetail b
                                              ) b ON b.ProducteDetailGUID = a.ProducteDetailGUID
                                    LEFT JOIN dbo.s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
                                    LEFT JOIN dbo.mdm_Project p ON p.ProjGUID = c.ProjGUID
                            WHERE   b.Shenhe = '审核'
                            GROUP BY c.ProjGUID ,
                                    a.ProductType,
									p.TradersWay
                          ) cc ON cc.ProjGUID = aa.ProjGUID
                                  AND cc.ProductType = aa.组织架构名称;


    ---产品业态，计算本年初可售货量的数据，取数来源于楼栋货量铺排1月份月初可售货量
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ythz3')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #ythz3;
            END;

        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                SUM(svp.EarlySaleMoneyQzkj) / 10000 AS '月初可售货量金额' ,
                SUM(svp.EarlySaleAreaQzkj) AS '月初可售货量面积'
        INTO    #ythz3
        FROM    ( SELECT    ProjGUID ,
                            ProductType ,
                            SUM(EarlySaleMoneyQzkj) AS EarlySaleMoneyQzkj ,
                            SUM(EarlySaleAreaQzkj) AS EarlySaleAreaQzkj
                  FROM      s_SaleValuePlan
                  WHERE     SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = 1
							AND ProjGUID NOT IN ( SELECT ProjGUID
                                         FROM   s_hndjdgProjList )
                  GROUP BY  ProjGUID ,
                            ProductType
                ) svp
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON svp.ProjGUID = bi.组织架构父级ID
                                                         AND bi.组织架构名称 = svp.ProductType
        WHERE   bi.组织架构类型 = 4
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型;

    --查询项目数据货值数据
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#Porjhz')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #Porjhz;
            END;
        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                SUM(zhz) / 10000 AS 总货值金额 ,
                SUM(zksmj) AS 总货值面积 ,
				SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  zhz END ) / 10000 AS 总货值操盘金额 ,
                SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  zksmj END ) AS 总货值操盘面积 ,

                SUM(ysje) / 10000 AS 已售货量金额 ,
                SUM(ysmj) AS 已售货量面积 ,
				SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  ysje END ) / 10000 AS 已售货量操盘金额 ,
                SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  ysmj END ) AS 已售货量操盘面积 ,

                SUM(syhz) / 10000 AS 未销售部分货量 ,
                SUM(ISNULL(ytwsmj, 0) + ISNULL(wtmj, 0)) AS 未销售部分可售面积 ,
                SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  syhz END ) / 10000 AS 未销售部分操盘货量 ,
                SUM(CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE  ISNULL(ytwsmj, 0) + ISNULL(wtmj, 0) END ) AS 未销售部分可售操盘面积 ,
                
				( ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                         AND SjDdysxxDate IS NULL THEN syhz
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推' THEN syhz
                                      ELSE 0
                                 END), 0) )
                  + ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                           AND SjDdysxxDate IS NOT NULL
                                      THEN syhz
                                      ELSE 0
                                 END), 0)
                      + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推' THEN syhz
                                        ELSE 0
                                   END), 0) )
                  + ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售' THEN syhz
                                      ELSE 0
                                 END), 0)
                      + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售' THEN syhz
                                        ELSE 0
                                   END), 0) ) ) / 10000 AS 剩余可售货值金额 , --待售货量 B1 + B2
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                  THEN wtmj + ytwsmj
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) )
                + ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                         AND SjDdysxxDate IS NOT NULL
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                      THEN wtmj + ytwsmj
                                      ELSE 0
                                 END), 0) )
                + ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                      THEN wtmj + ytwsmj
                                      ELSE 0
                                 END), 0) ) AS 剩余可售货值面积 , --待售货量 
                                  ----已完工未推出未具备条件货量(B2-1)  + 未完工具备条件未获证货量(B1-1) 
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL THEN syhz
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 AS 工程达到可售未拿证货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                  THEN wtmj + ytwsmj
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) AS 工程达到可售未拿证货值面积 ,

                                  ----已完工未推出具备条件货量(B2-2) + 未完工已获证待推货量(B1-2)
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL THEN syhz
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 AS 获证未推货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL
                                  THEN wtmj + ytwsmj
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) AS 获证未推货值面积 ,

                                  ----已完工已推出待售货量（B2-3）  +   未完工已推待售货量(B1-3) 
                ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售' THEN syhz
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 AS 已推未售货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                  THEN wtmj + ytwsmj
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) AS 已推未售货值面积 ,

				CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE ( ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                         AND SjDdysxxDate IS NULL THEN syhz
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推' THEN syhz
                                      ELSE 0
                                 END), 0) )
                  + ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                           AND SjDdysxxDate IS NOT NULL
                                      THEN syhz
                                      ELSE 0
                                 END), 0)
                      + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推' THEN syhz
                                        ELSE 0
                                   END), 0) )
                  + ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售' THEN syhz
                                      ELSE 0
                                 END), 0)
                      + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售' THEN syhz
                                        ELSE 0
                                   END), 0) ) ) / 10000 END  AS 剩余可售货值操盘金额 , --待售货量 B1 + B2
                CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                  THEN wtmj + ytwsmj
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) )
                + ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                         AND SjDdysxxDate IS NOT NULL
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                      THEN wtmj + ytwsmj
                                      ELSE 0
                                 END), 0) )
                + ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0)
                    + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                      THEN wtmj + ytwsmj
                                      ELSE 0
                                 END), 0) ) END AS 剩余可售货值操盘面积 , --待售货量 
                                  ----已完工未推出未具备条件货量(B2-1)  + 未完工具备条件未获证货量(B1-1) 
                CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL THEN syhz
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 END AS 工程达到可售未拿证货值操盘金额 ,
                CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                  THEN wtmj + ytwsmj
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) END AS 工程达到可售未拿证货值操盘面积 ,

                                  ----已完工未推出具备条件货量(B2-2) + 未完工已获证待推货量(B1-2)
                CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL THEN syhz
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 END AS 获证未推货值操盘金额 ,
                CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL
                                  THEN wtmj + ytwsmj
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) end AS 获证未推货值操盘面积 ,

                                  ----已完工已推出待售货量（B2-3）  +   未完工已推待售货量(B1-3) 
                CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售' THEN syhz
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售' THEN syhz
                                    ELSE 0
                               END), 0) ) / 10000 END  AS 已推未售货值操盘金额 ,
                CASE WHEN mp.tradersway = '合作方操盘' THEN 0 ELSE( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                  THEN wtmj + ytwsmj
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                    THEN wtmj + ytwsmj
                                    ELSE 0
                               END), 0) ) END  AS 已推未售货值操盘面积 ,
				 --年初情况:预售证在年初1月1号之前，已售+剩余
                                  ----已完工未推出未具备条件货量(B2-1)  + 未完工具备条件未获证货量(B1-1) 
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN syhz + ld.ThisYearSaleJeRg
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN syhz + ld.ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) / 10000 AS 年初工程达到可售未拿证货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NULL
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN zksmj - ysmj + ThisYearSaleJeRg
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工未获证未推'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN zksmj - ysmj + ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) AS 年初工程达到可售未拿证货值面积 ,

                                  ----已完工未推出具备条件货量(B2-2) + 未完工已获证待推货量(B1-2)
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN syhz + ld.ThisYearSaleJeRg
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN syhz + ld.ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) / 10000 AS 年初获证未推货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '已完工未推'
                                       AND SjDdysxxDate IS NOT NULL
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN zksmj - ysmj + ThisYearSaleJeRg
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '未完工已获证未推'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN zksmj - ysmj + ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) AS 年初获证未推货值面积 ,

                                  ----已完工已推出待售货量（B2-3）  +   未完工已推待售货量(B1-3) 
                ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN syhz + ld.ThisYearSaleJeRg
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN syhz + ld.ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) / 10000 AS 年初已推未售货值金额 ,
                ( ISNULL(SUM(CASE WHEN b.hl_type = '未完工已推待售'
                                       AND DATEDIFF(dd,
                                                    ISNULL(SjYsblDate,
                                                           ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                    DATEADD(yy,
                                                            DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                  THEN zksmj - ysmj + ThisYearSaleJeRg
                                  ELSE 0
                             END), 0)
                  + ISNULL(SUM(CASE WHEN b.hl_type = '已完工已推待售'
                                         AND DATEDIFF(dd,
                                                      ISNULL(SjYsblDate,
                                                             ISNULL(YjYsblDate,
                                                              '2099-12-31')),
                                                      DATEADD(yy,
                                                              DATEDIFF(yy, 0,
                                                              GETDATE()), 0)) > 0
                                    THEN zksmj - ysmj + ThisYearSaleJeRg
                                    ELSE 0
                               END), 0) ) AS 年初已推未售货值面积 ,

                                  ---未开工货量(A1) + 已开工（在建）货量(A2)
                SUM(CASE WHEN b.hl_type IN ( '已开工', '未开工' ) THEN syhz
                         ELSE 0
                    END) / 10000 AS 后续预计达成货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '已开工', '未开工' ) THEN wtmj + ytwsmj
                         ELSE 0
                    END) AS 后续预计达成货量面积 ,
                                  --本年可售
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(yy,
                                           ISNULL(ISNULL(ld.SjYsblDate,
                                                         YjYsblDate),
                                                  '2099-01-01'), GETDATE()) = 0
                         THEN zhz
                         ELSE 0
                    END) / 10000 AS 本年可售货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(yy,
                                           ISNULL(ISNULL(ld.SjYsblDate,
                                                         YjYsblDate),
                                                  '2099-01-01'), GETDATE()) = 0
                         THEN ld.zksmj --wtmj + ytwsmj
                         ELSE 0
                    END) 本年可售货量面积 ,
                SUM(CASE WHEN --b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推', '未完工已推待售', '已完工已推待售', '已完工未推' )
                              DATEDIFF(yy,
                                       ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                              '2099-01-01'), GETDATE()) >= 0
                         THEN ld.syhz
                         ELSE 0
                    END) / 10000 AS 本年剩余可售货量金额 ,
                SUM(CASE WHEN --b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推', '未完工已推待售', '已完工已推待售', '已完工未推' )
                              DATEDIFF(yy,
                                       ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                              '2099-01-01'), GETDATE()) >= 0
                         THEN ld.zksmj - ld.ysmj
                         ELSE 0
                    END) AS 本年剩余可售货量面积 ,
				SUM(CASE WHEN --b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推', '未完工已推待售', '已完工已推待售', '已完工未推' )
                              DATEDIFF(dd,
                                       ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                              '2099-01-01'), GETDATE()) >= 0
                         THEN ld.syhz
                         ELSE 0
                    END) / 10000 AS 当前剩余可售货量金额 ,
                SUM(CASE WHEN --b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推', '未完工已推待售', '已完工已推待售', '已完工未推' )
                              DATEDIFF(dd,
                                       ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                              '2099-01-01'), GETDATE()) >= 0
                         THEN ld.zksmj - ld.ysmj
                         ELSE 0
                    END) AS 当前剩余可售货量面积 ,
                SUM(CASE WHEN ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                     '2099-01-01') < CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01' THEN zhz
                         ELSE 0
                    END) / 10000 AS 本年之前可售货量金额 ,
                SUM(CASE WHEN ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                     '2099-01-01') < CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01'
                         THEN ld.zksmj
                         ELSE 0
                    END) 本年之前可售货量面积 ,
                SUM(ISNULL(ld.ysje, 0) - ISNULL(ld.ThisYearSaleJeRg, 0))
                / 10000 AS 本年之前销售金额 ,
                SUM(ISNULL(ld.ysmj, 0) - ISNULL(ld.ThisYearSaleMjRg, 0)) AS 本年之前销售面积 ,
                ( SUM(CASE WHEN ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                       '2099-01-01') < CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01' THEN zhz
                           ELSE 0
                      END) - SUM(ISNULL(ld.ysje, 0)
                                 - ISNULL(ld.ThisYearSaleJeRg, 0)) ) / 10000 AS 本年初可售货量金额 ,
                SUM(CASE WHEN ISNULL(ISNULL(ld.SjYsblDate, YjYsblDate),
                                     '2099-01-01') < CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01'
                         THEN ld.zksmj
                         ELSE 0
                    END) - SUM(ISNULL(ld.ysmj, 0) - ISNULL(ld.ThisYearSaleMjRg,
                                                           0)) AS 本年初可售货量面积 ,


                                  --货量计划 
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Jan预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-01-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Jan实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                      CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-02-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Feb预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                          CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-02-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Feb实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-03-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Mar预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-03-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Mar实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-04-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Apr预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-04-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Apr实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-05-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS May预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-05-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS May实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-06-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Jun预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-06-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Jun实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-07-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS July预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-07-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS July实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-08-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Aug预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-08-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Aug实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                      CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-09-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Sep预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                          CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-09-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Sep实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                      CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-10-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Oct预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                          CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-10-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Oct实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-11-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Nov预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-11-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Nov实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-12-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Dec预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           CONVERT(VARCHAR(4),YEAR(GETDATE()))+'-12-01') = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS Dec实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS 本月预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(mm,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS 本月实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(yy, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS 本年预计货量金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售', '已完工未推',
                                             '未完工已推待售', '已完工已推待售', '已完工未推' )
                              AND DATEDIFF(yy,
                                           ISNULL(SjYsblDate, '2099-01-01'),
                                           GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS 本年实际货量金额 ,
                SUM(ThisYearSaleJeQY) / 10000 AS 本年已售货量金额 ,
                SUM(ThisYearSaleMjQY) AS 本年已售货量面积 ,
                CASE WHEN ISNULL(mp.TradersWay, '') <> '合作方操盘'
                     THEN SUM(CASE WHEN ISNULL(YjYsblDate, '2099-01-01') <= GETDATE()
                                        AND SjYsblDate IS NULL THEN syhz
                                   ELSE 0
                              END) / 10000
                     ELSE 0
                END AS 滞后货量金额 ,
                CASE WHEN ISNULL(mp.TradersWay, '') <> '合作方操盘'
                     THEN SUM(CASE WHEN ISNULL(YjYsblDate, '2099-01-01') <= GETDATE()
                                        AND SjYsblDate IS NULL
                                   THEN wtmj + ytwsmj
                                   ELSE 0
                              END)
                     ELSE 0
                END AS 滞后货量面积 ,
                SUM(CASE WHEN ld.SjYsblDate IS NULL
                              AND DATEDIFF(yy,
                                           ISNULL(ld.YjYsblDate, '2099-01-01'),
                                           GETDATE()) = 0 THEN syhz
                         ELSE 0
                    END) / 10000 AS '今年后续预计达成货量金额' ,
                SUM(CASE WHEN ld.SjYsblDate IS NULL
                              AND DATEDIFF(yy,
                                           ISNULL(ld.YjYsblDate, '2099-01-01'),
                                           GETDATE()) = 0 THEN wtmj + ytwsmj
                         ELSE 0
                    END) / 10000 AS '今年后续预计达成货量面积' ,
                MIN(ld.YjDdysxxDate) AS '预计达到预售形象日期' ,
                MIN(ld.SjDdysxxDate) AS '实际达到预售形象日期' ,
                MIN(ld.YjYsblDate) AS '预计预售办理日期' ,
                MIN(ld.SjYsblDate) AS '实际预售办理日期' ,
                NULL AS '预计售价' ,
                SUM(今年车位可售金额) 今年车位可售金额
        INTO    #Porjhz
        FROM    erp25.dbo.p_lddb ld
                LEFT JOIN ( SELECT  SaleBldGUID ,
                                    CASE WHEN ISNULL(a.SJjgbadate,
                                                     '2099-01-01') < GETDATE()
                                              AND a.SJkpxsDate IS NOT NULL
                                         THEN '已完工已推待售'
                                         WHEN ISNULL(a.SJjgbadate,
                                                     '2099-01-01') < GETDATE()
                                         THEN '已完工未推'
                                         WHEN a.SJkpxsDate IS NOT NULL
                                         THEN '未完工已推待售'
                                         WHEN a.SjYsblDate IS NOT NULL
                                         THEN '未完工已获证未推'
                                         WHEN a.SjDdysxxDate IS NOT NULL
                                         THEN '未完工未获证未推'
                                         WHEN a.SJzskgdate IS NOT NULL
                                         THEN '已开工'
                                         ELSE '未开工'
                                    END hl_type
                            FROM    erp25.dbo.p_lddb a
                            WHERE   DATEDIFF(DAY, a.QXDate, GETDATE()) = 0
                                    AND ( ISNULL(IsSale, 0) = 1
                                          OR ( ISNULL(IsSale, 0) = 0
                                               AND ysje <> 0
                                             )
                                        )
                          ) b ON b.SaleBldGUID = ld.SaleBldGUID
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON ld.ProjGUID = bi.组织架构ID
                LEFT JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = ld.ProjGUID
                LEFT JOIN ( SELECT  a.组织架构ID ,
                                    SUM(a.今年车位可售金额) 今年车位可售金额
                            FROM    ( SELECT    bi.组织架构ID ,
                                                CASE WHEN ( ISNULL(( SELECT TOP 1
                                                              1
                                                              FROM
                                                              #car car
                                                              WHERE
                                                              car.SaleBldGUID = ld.SaleBldGUID
                                                              ), 0) = 0 )
                                                     THEN 0
                                                     ELSE ( SUM(CASE
                                                              WHEN DATEDIFF(yy,
                                                              ISNULL(ISNULL(ld.SjYsblDate,
                                                              YjYsblDate),
                                                              '2099-01-01'),
                                                              GETDATE()) = 0
                                                              THEN zhz
                                                              ELSE 0
                                                              END) / 10000 )
                                                END 今年车位可售金额
                                      FROM      erp25.dbo.p_lddb ld
                                                INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON ld.ProjGUID = bi.组织架构ID
                                                LEFT JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = ld.ProjGUID
                                      WHERE     DATEDIFF(DAY, QXDate,
                                                         GETDATE()) = 0
                                                AND bi.组织架构类型 = 3
                                                AND ( ISNULL(IsSale, 0) = 1
                                                      OR ( ISNULL(IsSale, 0) = 0
                                                           AND ysje <> 0
                                                         )
                                                    )
                                                AND ld.ProjGUID NOT IN (
                                                SELECT  ProjGUID
                                                FROM    s_SaleValuePlanSet
                                                WHERE   IsPricePrediction = 2 )
                                      GROUP BY  bi.组织架构ID ,
                                                ld.SaleBldGUID
                                    ) a
                            GROUP BY a.组织架构ID
                          ) bb ON bb.组织架构ID = bi.组织架构ID
        WHERE   DATEDIFF(DAY, QXDate, GETDATE()) = 0
                AND bi.组织架构类型 = 3
                AND ( ISNULL(IsSale, 0) = 1
                      OR ( ISNULL(IsSale, 0) = 0
                           AND ysje <> 0
                         )
                    )
          --AND ISNULL(mp.TradersWay, '') <> '合作方操盘'
                AND ld.ProjGUID NOT IN ( SELECT ProjGUID
                                         FROM   s_SaleValuePlanSet
                                         WHERE  IsPricePrediction = 2 )
				AND ld.ProjGUID NOT IN ( SELECT ProjGUID
                                         FROM   s_hndjdgProjList )
    --AND ld.DevelopmentCompanyGUID = 'AADC0FA7-9546-49C9-B64B-825056C828ED'
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                mp.TradersWay;




    --货量看板的非操盘项目的“当前可售货量”和“其中”和“后续预计达成”和“今年后续预计达成”应该取货量铺排的数据；
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#Porjhz2_1')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #Porjhz2_1;
            END;

        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                mp.ProjGUID ,
                a.SaleValuePlanYear ,
                a.SaleValuePlanMonth ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 剩余可售货值金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleAreaQzkj, 0))
                     ELSE 0
                END AS 剩余可售货值面积 , 
                0 AS 工程达到可售未拿证货值金额 ,
                0 AS 工程达到可售未拿证货值面积 ,
                0 AS 获证未推货值金额 ,
                0 AS 获证未推货值面积 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 已推未售货值金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleAreaQzkj, 0))
                     ELSE 0
                END AS 已推未售货值面积 , 
				CASE WHEN mp.TradersWay = '合作方操盘' THEN 0 ELSE (CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleMoneyQzkj, 0))
                     ELSE 0
                END) END  AS 剩余可售货值操盘金额 ,
                CASE WHEN mp.TradersWay = '合作方操盘' THEN 0 ELSE (CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleAreaQzkj, 0))
                     ELSE 0
                END) END  AS 剩余可售货值操盘面积 , 
                0 AS 工程达到可售未拿证货值操盘金额 ,
                0 AS 工程达到可售未拿证货值操盘面积 ,
                0 AS 获证未推货值操盘金额 ,
                0 AS 获证未推货值操盘面积 ,
                CASE WHEN mp.TradersWay = '合作方操盘' THEN 0 ELSE (CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleMoneyQzkj, 0))
                     ELSE 0
                END) END  AS 已推未售货值操盘金额 ,
                CASE WHEN mp.TradersWay = '合作方操盘' THEN 0 ELSE (CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleAreaQzkj, 0))
                     ELSE 0
                END ) END AS 已推未售货值操盘面积 , 
				0 AS 年初工程达到可售未拿证货值金额 ,
                0 AS 年初工程达到可售未拿证货值面积 ,
                0 AS 年初获证未推货值金额 ,
                0 AS 年初获证未推货值面积 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = 1
                          ) THEN SUM(ISNULL(a.EarlySaleMoneyQzkj, 0))
                     ELSE 0
                END AS 年初已推未售货值金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = 1
                          ) THEN SUM(ISNULL(a.EarlySaleAreaQzkj, 0))
                     ELSE 0
                END AS 年初已推未售货值面积 ,
                0 AS 后续预计达成货量金额 ,
                0 AS 后续预计达成货量面积 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.YearTotalSumSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 本年可售货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.YearTotalSumSaleAreaQzkj, 0))
                     ELSE 0
                END AS 本年可售货量面积 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 本年剩余可售货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleAreaQzkj, 0))
                     ELSE 0
                END AS 本年剩余可售货量面积 ,
			    CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 当前剩余可售货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthTotalSaleAreaQzkj, 0))
                     ELSE 0
                END AS 当前剩余可售货量面积 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '1'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Jan预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '1'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Jan实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '2'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Feb预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '2'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Feb实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '3'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Mar预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '3'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Mar实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '4'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Apr预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '4'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Apr实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '5'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS May预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '5'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS May实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '6'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Jun预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '6'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Jun实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '7'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS July预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '7'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS July实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '8'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Aug预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '8'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Aug实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '9'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Sep预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '9'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Sep实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '10'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Oct预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '10'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Oct实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '11'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Nov预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '11'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Nov实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '12'
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Dec预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear =YEAR(GETDATE())
                            AND SaleValuePlanMonth = '12'
                            AND MONTH(GETDATE()) >= SaleValuePlanMonth
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS Dec实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 本月预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.ThisMonthSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 本月实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.YearTotalSumSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 本年预计货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.YearTotalSumSaleMoneyQzkj, 0))
                     ELSE 0
                END AS 本年实际货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.YearTotalSaleMoneyRg, 0))
                     ELSE 0
                END AS 本年已售货量金额 ,
                CASE WHEN ( SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = MONTH(GETDATE())
                          ) THEN SUM(ISNULL(a.YearTotalSaleAreaRg, 0))
                     ELSE 0
                END AS 本年已售货量面积 ,
                0 AS 滞后货量金额 ,
                0 AS 滞后货量面积 ,
                CASE WHEN CHARINDEX('车', a.ProductType) > 0
                     THEN SUM(ISNULL(a.YearTotalSumSaleMoneyQzkj, 0))
                     ELSE 0
                END 今年车位可售金额
        INTO    #Porjhz2_1
        FROM    s_SaleValuePlan a
                LEFT JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
                LEFT JOIN erp25.dbo.ydkb_BaseInfo bi ON a.ProjGUID = bi.组织架构ID
        WHERE   bi.组织架构类型 = 3
          --AND ISNULL(mp.TradersWay, '') = '合作方操盘'
                AND a.ProjGUID IN ( SELECT  ProjGUID
                                    FROM    s_SaleValuePlanSet
                                    WHERE   IsPricePrediction = 2 )
				AND a.ProjGUID NOT  IN ( SELECT  ProjGUID FROM    s_hndjdgProjList  )
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                mp.ProjGUID ,
                a.ProductType ,
                a.SaleValuePlanYear ,
                a.SaleValuePlanMonth,
				mp.TradersWay;

        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#Porjhz2')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #Porjhz2;
            END;

        SELECT  aa.组织架构ID ,
                aa.组织架构名称 ,
                aa.组织架构编码 ,
                aa.组织架构类型 ,
                ISNULL(bb.zhz, 0) / 10000 AS 总货值金额 ,
                ISNULL(bb.zksmj, 0) AS 总货值面积 ,
				ISNULL(bb.zhz1, 0) / 10000 AS 总货值操盘金额 ,
                ISNULL(bb.zksmj1, 0) AS 总货值操盘面积 ,

                CASE WHEN ISNULL(bb.ysje, 0) <> 0
                     THEN ISNULL(bb.ysje, 0) / 10000
                     ELSE ISNULL(cc.累计销售金额, 0)
                END AS 已售货量金额 ,
                CASE WHEN ISNULL(bb.ysmj, 0) <> 0 THEN ISNULL(bb.ysmj, 0)
                     ELSE ISNULL(cc.累计销售面积, 0)
                END AS 已售货量面积 ,
				CASE WHEN ISNULL(bb.ysje1, 0) <> 0
                     THEN ISNULL(bb.ysje1, 0) / 10000
                     ELSE ISNULL(cc.累计销售操盘金额, 0)
                END AS 已售货量操盘金额 ,
                CASE WHEN ISNULL(bb.ysmj1, 0) <> 0 THEN ISNULL(bb.ysmj1, 0)
                     ELSE ISNULL(cc.累计销售操盘面积, 0)
                END AS 已售货量操盘面积 ,

                CASE WHEN ISNULL(bb.ysje, 0) <> 0
                     THEN ( ISNULL(bb.zhz, 0) - ISNULL(bb.ysje, 0) ) / 10000
                     ELSE ISNULL(bb.zhz, 0) / 10000 - ISNULL(cc.累计销售金额, 0)
                END AS 未销售部分货量 ,
                CASE WHEN ISNULL(bb.ysmj, 0) <> 0
                     THEN ( ISNULL(bb.zksmj, 0) - ISNULL(bb.ysmj, 0) )
                     ELSE ISNULL(bb.zksmj, 0) - ISNULL(cc.累计销售面积, 0)
                END AS 未销售部分可售面积 ,
				CASE WHEN ISNULL(bb.ysje1, 0) <> 0
                     THEN ( ISNULL(bb.zhz1, 0) - ISNULL(bb.ysje1, 0) ) / 10000
                     ELSE ISNULL(bb.zhz1, 0) / 10000 - ISNULL(cc.累计销售操盘金额, 0)
                END AS 未销售部分操盘货量 ,
                CASE WHEN ISNULL(bb.ysmj1, 0) <> 0
                     THEN ( ISNULL(bb.zksmj1, 0) - ISNULL(bb.ysmj1, 0) )
                     ELSE ISNULL(bb.zksmj1, 0) - ISNULL(cc.累计销售操盘面积, 0)
                END AS 未销售部分可售操盘面积 ,

                ISNULL(aa.剩余可售货值金额, 0) / 10000 AS 剩余可售货值金额 ,
                ISNULL(aa.剩余可售货值面积, 0) AS 剩余可售货值面积 ,
                0 AS 工程达到可售未拿证货值金额 ,
                0 AS 工程达到可售未拿证货值面积 ,
                0 AS 获证未推货值金额 ,
                0 AS 获证未推货值面积 ,
                ISNULL(aa.已推未售货值金额, 0) / 10000 AS 已推未售货值金额 ,
                ISNULL(aa.已推未售货值面积, 0) AS 已推未售货值面积 ,

				ISNULL(aa.剩余可售货值操盘金额, 0) / 10000 AS 剩余可售货值操盘金额 ,
                ISNULL(aa.剩余可售货值操盘面积, 0) AS 剩余可售货值操盘面积 ,
                0 AS 工程达到可售未拿证货值操盘金额 ,
                0 AS 工程达到可售未拿证货值操盘面积 ,
                0 AS 获证未推货值操盘金额 ,
                0 AS 获证未推货值操盘面积 ,
                ISNULL(aa.已推未售货值操盘金额, 0) / 10000 AS 已推未售货值操盘金额 ,
                ISNULL(aa.已推未售货值操盘面积, 0) AS 已推未售货值操盘面积 ,
				--年初情况
                0 AS 年初工程达到可售未拿证货值金额 ,
                0 AS 年初工程达到可售未拿证货值面积 ,
                0 AS 年初获证未推货值金额 ,
                0 AS 年初获证未推货值面积 ,
                ISNULL(aa.年初已推未售货值金额, 0) / 10000 AS 年初已推未售货值金额 ,
                ISNULL(aa.年初已推未售货值面积, 0) AS 年初已推未售货值面积 , --年初情况：剩余+已售
                0 AS 后续预计达成货量金额 ,
                0 AS 后续预计达成货量面积 ,
                ISNULL(aa.本年可售货量金额, 0) / 10000 AS 本年可售货量金额 ,
                ISNULL(aa.本年可售货量面积, 0) AS 本年可售货量面积 ,
                ISNULL(aa.本年剩余可售货量金额, 0) / 10000 AS 本年剩余可售货量金额 ,
                ISNULL(aa.本年剩余可售货量面积, 0) AS 本年剩余可售货量面积 ,
				ISNULL(aa.当前剩余可售货量金额, 0) / 10000 AS 当前剩余可售货量金额 ,
                ISNULL(aa.当前剩余可售货量面积, 0) AS 当前剩余可售货量面积 ,
                ISNULL(aa.Jan预计货量金额, 0) / 10000 Jan预计货量金额 ,
                ISNULL(aa.Jan实际货量金额, 0) / 10000 Jan实际货量金额 ,
                ISNULL(aa.Feb预计货量金额, 0) / 10000 Feb预计货量金额 ,
                ISNULL(aa.Feb实际货量金额, 0) / 10000 Feb实际货量金额 ,
                ISNULL(aa.Mar预计货量金额, 0) / 10000 Mar预计货量金额 ,
                ISNULL(aa.Mar实际货量金额, 0) / 10000 Mar实际货量金额 ,
                ISNULL(aa.Apr预计货量金额, 0) / 10000 Apr预计货量金额 ,
                ISNULL(aa.Apr实际货量金额, 0) / 10000 Apr实际货量金额 ,
                ISNULL(aa.May预计货量金额, 0) / 10000 May预计货量金额 ,
                ISNULL(aa.May实际货量金额, 0) / 10000 May实际货量金额 ,
                ISNULL(aa.Jun预计货量金额, 0) / 10000 Jun预计货量金额 ,
                ISNULL(aa.Jun实际货量金额, 0) / 10000 Jun实际货量金额 ,
                ISNULL(aa.July预计货量金额, 0) / 10000 July预计货量金额 ,
                ISNULL(aa.July实际货量金额, 0) / 10000 July实际货量金额 ,
                ISNULL(aa.Aug预计货量金额, 0) / 10000 Aug预计货量金额 ,
                ISNULL(aa.Aug实际货量金额, 0) / 10000 Aug实际货量金额 ,
                ISNULL(aa.Sep预计货量金额, 0) / 10000 Sep预计货量金额 ,
                ISNULL(aa.Sep实际货量金额, 0) / 10000 Sep实际货量金额 ,
                ISNULL(aa.Oct预计货量金额, 0) / 10000 Oct预计货量金额 ,
                ISNULL(aa.Oct预计货量金额, 0) / 10000 Oct实际货量金额 ,
                ISNULL(aa.Nov预计货量金额, 0) / 10000 Nov预计货量金额 ,
                ISNULL(aa.Nov实际货量金额, 0) / 10000 Nov实际货量金额 ,
                ISNULL(aa.Dec预计货量金额, 0) / 10000 Dec预计货量金额 ,
                ISNULL(aa.Dec实际货量金额, 0) / 10000 Dec实际货量金额 ,
                ISNULL(aa.本月预计货量金额, 0) / 10000 AS 本月预计货量金额 ,
                ISNULL(aa.本月实际货量金额, 0) / 10000 AS 本月实际货量金额 ,
                ISNULL(aa.本年预计货量金额, 0) / 10000 AS 本年预计货量金额 ,
                ISNULL(aa.本年实际货量金额, 0) / 10000 AS 本年实际货量金额 ,
                ISNULL(cc.本年销售金额, 0) AS 本年已售货量金额 ,
                ISNULL(cc.本年销售面积, 0) AS 本年已售货量面积 ,
                0 AS 滞后货量金额 ,
                0 AS 滞后货量面积 ,
                ISNULL(aa.今年车位可售金额, 0) / 10000 AS 今年车位可售金额
        INTO    #Porjhz2
        FROM    ( SELECT    bi.组织架构ID ,
                            bi.组织架构名称 ,
                            bi.组织架构编码 ,
                            bi.组织架构类型 ,
                            bi.ProjGUID ,
                            SUM(剩余可售货值金额) AS 剩余可售货值金额 ,
                            SUM(剩余可售货值面积) AS 剩余可售货值面积 , 
                            SUM(工程达到可售未拿证货值金额) AS 工程达到可售未拿证货值金额 ,
                            SUM(工程达到可售未拿证货值面积) AS 工程达到可售未拿证货值面积 ,
                            SUM(获证未推货值金额) AS 获证未推货值金额 ,
                            SUM(获证未推货值面积) AS 获证未推货值面积 ,
                            SUM(已推未售货值金额) AS 已推未售货值金额 ,
                            SUM(已推未售货值面积) AS 已推未售货值面积 ,

							SUM(剩余可售货值操盘金额) AS 剩余可售货值操盘金额 ,
                            SUM(剩余可售货值操盘面积) AS 剩余可售货值操盘面积 , 
                            SUM(工程达到可售未拿证货值操盘金额) AS 工程达到可售未拿证货值操盘金额 ,
                            SUM(工程达到可售未拿证货值操盘面积) AS 工程达到可售未拿证货值操盘面积 ,
                            SUM(获证未推货值操盘金额) AS 获证未推货值操盘金额 ,
                            SUM(获证未推货值操盘面积) AS 获证未推货值操盘面积 ,
                            SUM(已推未售货值操盘金额) AS 已推未售货值操盘金额 ,
                            SUM(已推未售货值操盘面积) AS 已推未售货值操盘面积 ,

							SUM(年初工程达到可售未拿证货值金额) AS 年初工程达到可售未拿证货值金额 ,
                            SUM(年初工程达到可售未拿证货值面积) AS 年初工程达到可售未拿证货值面积 ,
                            SUM(年初获证未推货值金额) AS 年初获证未推货值金额 ,
                            SUM(年初获证未推货值面积) AS 年初获证未推货值面积 ,
                            SUM(年初已推未售货值金额) AS 年初已推未售货值金额 ,
                            SUM(年初已推未售货值面积) AS 年初已推未售货值面积 ,
                            SUM(后续预计达成货量金额) AS 后续预计达成货量金额 ,
                            SUM(后续预计达成货量面积) AS 后续预计达成货量面积 ,
                            SUM(本年可售货量金额) AS 本年可售货量金额 ,
                            SUM(本年可售货量面积) AS 本年可售货量面积 ,
                            SUM(本年剩余可售货量金额) AS 本年剩余可售货量金额 ,
                            SUM(本年剩余可售货量面积) AS 本年剩余可售货量面积 ,
							SUM(当前剩余可售货量金额) AS 当前剩余可售货量金额 ,
                            SUM(当前剩余可售货量面积) AS 当前剩余可售货量面积 ,
                            SUM(Jan预计货量金额) AS Jan预计货量金额 ,
                            SUM(Jan实际货量金额) AS Jan实际货量金额 ,
                            SUM(Feb预计货量金额) AS Feb预计货量金额 ,
                            SUM(Feb实际货量金额) AS Feb实际货量金额 ,
                            SUM(Mar预计货量金额) AS Mar预计货量金额 ,
                            SUM(Mar实际货量金额) AS Mar实际货量金额 ,
                            SUM(Apr预计货量金额) AS Apr预计货量金额 ,
                            SUM(Apr实际货量金额) AS Apr实际货量金额 ,
                            SUM(May预计货量金额) AS May预计货量金额 ,
                            SUM(May实际货量金额) AS May实际货量金额 ,
                            SUM(Jun预计货量金额) AS Jun预计货量金额 ,
                            SUM(Jun实际货量金额) AS Jun实际货量金额 ,
                            SUM(July预计货量金额) AS July预计货量金额 ,
                            SUM(July实际货量金额) AS July实际货量金额 ,
                            SUM(Aug预计货量金额) AS Aug预计货量金额 ,
                            SUM(Aug实际货量金额) AS Aug实际货量金额 ,
                            SUM(Sep预计货量金额) AS Sep预计货量金额 ,
                            SUM(Sep实际货量金额) AS Sep实际货量金额 ,
                            SUM(Oct预计货量金额) AS Oct预计货量金额 ,
                            SUM(Oct实际货量金额) AS Oct实际货量金额 ,
                            SUM(Nov预计货量金额) AS Nov预计货量金额 ,
                            SUM(Nov实际货量金额) AS Nov实际货量金额 ,
                            SUM(Dec预计货量金额) AS Dec预计货量金额 ,
                            SUM(Dec实际货量金额) AS Dec实际货量金额 ,
                            SUM(本月预计货量金额) AS 本月预计货量金额 ,
                            SUM(本月实际货量金额) AS 本月实际货量金额 ,
                            SUM(本年预计货量金额) AS 本年预计货量金额 ,
                            SUM(本年实际货量金额) AS 本年实际货量金额 ,
                            SUM(本年已售货量金额) AS 本年已售货量金额 ,
                            SUM(本年已售货量面积) AS 本年已售货量面积 ,
                            SUM(滞后货量金额) AS 滞后货量金额 ,
                            SUM(滞后货量面积) AS 滞后货量面积 ,
                            SUM(今年车位可售金额) AS 今年车位可售金额
                  FROM      #Porjhz2_1 bi
                  GROUP BY  bi.组织架构ID ,
                            bi.组织架构名称 ,
                            bi.组织架构编码 ,
                            bi.组织架构类型 ,
                            bi.ProjGUID

                ) aa
                LEFT JOIN ( SELECT  ld.ProjGUID ,
                                    SUM(zhz) AS zhz ,
                                    SUM(zksmj) AS zksmj ,
                                    SUM(ysje) AS ysje ,
                                    SUM(ysmj) AS ysmj,

									SUM(CASE WHEN mp.TradersWay = '合作方操盘' THEN 0 ELSE zhz END ) AS zhz1 ,
                                    SUM(CASE WHEN mp.TradersWay = '合作方操盘' THEN 0 ELSE zksmj END ) AS zksmj1 ,
                                    SUM(CASE WHEN mp.TradersWay = '合作方操盘' THEN 0 ELSE ysje END ) AS ysje1 ,
                                    SUM(CASE WHEN mp.TradersWay = '合作方操盘' THEN 0 ELSE ysmj END ) AS ysmj1
                            FROM    erp25.dbo.p_lddb ld LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = ld.ProjGUID
                            WHERE   DATEDIFF(DAY, QXDate, GETDATE()) = 0
                                    AND ( ISNULL(IsSale, 0) = 1
                                          OR ( ISNULL(IsSale, 0) = 0
                                               AND ysje <> 0
                                             )
                                        )
                                    AND ld.ProjGUID IN (
                                    SELECT  ProjGUID
                                    FROM    s_SaleValuePlanSet
                                    WHERE   IsPricePrediction = 2 )
                            GROUP BY ld.ProjGUID,mp.TradersWay
                          ) bb ON aa.组织架构ID = bb.ProjGUID
                LEFT JOIN ( SELECT  c.ProjGUID ,
                                    SUM(a.Amount) AS 累计销售金额 , --单位万元
                                    SUM(a.Area) AS 累计销售面积 ,
                                    SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.Amount
                                             ELSE 0
                                        END) AS 本年销售金额 ,
                                    SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.Area
                                             ELSE 0
                                        END) AS 本年销售面积,
									SUM(CASE WHEN p.TradersWay = '合作方操盘' THEN 0 ELSE a.Amount END ) AS 累计销售操盘金额 , --单位万元
                                    SUM(CASE WHEN p.TradersWay = '合作方操盘' THEN 0 ELSE a.Area END ) AS 累计销售操盘面积 ,
                                    SUM(CASE WHEN p.TradersWay = '合作方操盘' THEN 0 ELSE(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.Amount
                                             ELSE 0
                                        END)END ) AS 本年销售操盘金额 ,
                                    SUM(CASE WHEN p.TradersWay = '合作方操盘' THEN 0 ELSE(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                           GETDATE()) = 0
                                             THEN a.Area
                                             ELSE 0
                                        END)END) AS 本年销售操盘面积
                            FROM    dbo.s_YJRLProducteDescript a
                                    LEFT JOIN ( SELECT  * ,
                                                        CONVERT(DATETIME, b.DateYear
                                                        + '-' + b.DateMonth
                                                        + '-01') AS [BizDate]
                                                FROM    dbo.s_YJRLProducteDetail b
                                              ) b ON b.ProducteDetailGUID = a.ProducteDetailGUID
                                    LEFT JOIN dbo.s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
                                    LEFT JOIN dbo.mdm_Project p ON p.ProjGUID = c.ProjGUID
                            WHERE   b.Shenhe = '审核'
                            GROUP BY c.ProjGUID
                          ) cc ON cc.ProjGUID = aa.组织架构ID;

    ---一级项目，计算本年初可售货量的数据，取数来源于楼栋货量铺排1月份月初可售货量
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#Porjhz3')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #Porjhz3;
            END;

        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                SUM(svp.EarlySaleMoneyQzkj) / 10000 AS '月初可售货量金额' ,
                SUM(svp.EarlySaleAreaQzkj) AS '月初可售货量面积'
        INTO    #Porjhz3
        FROM    ( SELECT    ProjGUID ,
                            ProductType ,
                            SUM(EarlySaleMoneyQzkj) AS EarlySaleMoneyQzkj ,
                            SUM(EarlySaleAreaQzkj) AS EarlySaleAreaQzkj
                  FROM      s_SaleValuePlan
                  WHERE     SaleValuePlanYear = YEAR(GETDATE())
                            AND SaleValuePlanMonth = 1
                  GROUP BY  ProjGUID ,
                            ProductType
                ) svp
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON svp.ProjGUID = bi.组织架构ID
        WHERE   bi.组织架构类型 = 3 AND ProjGUID NOT  IN ( SELECT  ProjGUID FROM    s_hndjdgProjList  )
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型;

	---查询楼栋总可售和新推货面积金额,预测1-12月份货量的分布情况 
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ldhzyc')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #ldhzyc;
            END;

        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       GETDATE()) = 0 THEN ld.syhz + ld.ysje
                         ELSE 0
                    END) / 10000 AS 本月新货货量 ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       GETDATE()) = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 本月新货面积 ,
                SUM(CASE WHEN DATEDIFF(yy,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       GETDATE()) = 0
                              AND ISNULL(ld.SjYsblDate, ld.YjYsblDate) < CONVERT(VARCHAR(4), GETDATE(), 120)
                              + '-01-01' THEN ld.syhz
                         ELSE 0
                    END) / 10000 本年存货货量 ,
                SUM(CASE WHEN DATEDIFF(yy,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-01-01') = 0
                              AND ISNULL(ld.SjYsblDate, ld.YjYsblDate) < CONVERT(VARCHAR(4), GETDATE(), 120)
                              + '-01-01' THEN wtmj + ytwsmj
                         ELSE 0
                    END) AS 本年存货面积 ,

           --1月份     
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-01-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '1月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-01-01') = 0
                         THEN ld.syhz + ld.ysje
                         ELSE 0
                    END) / 10000 AS '1月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-01-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '1月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-01-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '1月总可售金额' ,
           --2月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-02-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '2月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-02-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '2月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-02-28' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '2月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-02-28' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '2月总可售金额' ,

           --3月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-03-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '3月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-03-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '3月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-03-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '3月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-03-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '3月总可售金额' ,

           --4月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-04-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '4月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-04-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '4月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-04-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '4月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-04-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '4月总可售金额' ,
           --5月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-05-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '5月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-05-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '5月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-05-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '5月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-05-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '5月总可售金额' ,

           --6月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-06-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '6月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-06-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '6月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-06-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '6月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-06-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '6月总可售金额' ,

           --7月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-07-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '7月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-07-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '7月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-07-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '7月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-07-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '7月总可售金额' ,

           --8月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-08-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '8月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-08-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '8月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-08-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '8月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-08-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '8月总可售金额' ,

           ---9月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-09-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '9月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-09-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '9月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-09-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '9月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-09-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '9月总可售金额' ,

           --10月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-10-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '10月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-10-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '10月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-10-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '10月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-10-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '10月总可售金额' ,

           --11月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-11-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '11月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-11-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '11月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-11-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '11月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-11-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '11月总可售金额' ,
           --12月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-12-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '12月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-12-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '12月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-12-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '12月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-12-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '12月总可售金额' ,

           --下一年   
           --1月份     
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-01-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next1月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-01-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next1月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-01-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next1月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-01-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next1月总可售金额' ,
           --2月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-02-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next2月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-02-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next2月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-02-28' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next2月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-02-28' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next2月总可售金额' ,

           --3月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-03-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next3月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-03-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next3月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-03-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next3月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-03-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next3月总可售金额' ,

           --4月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-04-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next4月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-04-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next4月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-04-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next4月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-04-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next4月总可售金额' ,
           --5月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-05-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next5月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-05-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next5月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-05-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next5月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-05-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next5月总可售金额' ,

           --6月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-06-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next6月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-06-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next6月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-06-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next6月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-06-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next6月总可售金额' ,

           --7月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-07-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next7月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-07-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next7月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-07-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next7月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-07-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next7月总可售金额' ,

           --8月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-08-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next8月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-08-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next8月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-08-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next8月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-08-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next8月总可售金额' ,

           ---9月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-09-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next9月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-09-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next9月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-09-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next9月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-09-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next9月总可售金额' ,

           --10月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-10-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next10月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-10-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next10月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-10-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next10月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-10-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next10月总可售金额' ,

           --11月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-11-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next11月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-11-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next11月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-11-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next11月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-11-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next11月总可售金额' ,
           --12月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-12-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next12月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-12-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next12月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-12-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next12月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-12-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next12月总可售金额'
        INTO    #ldhzyc
        FROM    dbo.p_lddb ld
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON bi.组织架构ID = ld.SaleBldGUID
        WHERE   DATEDIFF(DAY, QXDate, GETDATE()) = 0
                AND ( ISNULL(IsSale, 0) = 1
                      OR ( ISNULL(IsSale, 0) = 0
                           AND ysje <> 0
                         )
                    )
                AND bi.组织架构类型 = 5
                AND ld.ProductGUID NOT IN ( SELECT  ProjGUID
                                            FROM    s_SaleValuePlanSet
                                            WHERE   IsPricePrediction = 2 )
				AND ld.ProjGUID NOT  IN ( SELECT  ProjGUID FROM    s_hndjdgProjList  )
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型;
			   
    ---查询楼栋总可售和新推货面积金额,预测1-12月份货量的分布情况 
    --查询产品业态总可售和新推货面积金额,预测1-12月份货量的分布情况
        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ychzyc')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #ychzyc;
            END;

        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       GETDATE()) = 0 THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 本月新货货量 ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       GETDATE()) = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 本月新货面积 ,
                SUM(CASE WHEN DATEDIFF(yy,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       GETDATE()) = 0
                              AND ISNULL(ld.SjYsblDate, ld.YjYsblDate) < CONVERT(VARCHAR(4), GETDATE(), 120)
                              + '-01-01' THEN ld.syhz
                         ELSE 0
                    END) / 10000 本年存货货量 ,
                SUM(CASE WHEN DATEDIFF(yy,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-01-01') = 0
                              AND ISNULL(ld.SjYsblDate, ld.YjYsblDate) < CONVERT(VARCHAR(4), GETDATE(), 120)
                              + '-01-01' THEN wtmj + ytwsmj
                         ELSE 0
                    END) AS 本年存货面积 ,

           --1月份     
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-01-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '1月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-01-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '1月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-01-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '1月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-01-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '1月总可售金额' ,
           --2月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-02-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '2月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-02-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '2月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-02-28' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '2月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-02-28' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '2月总可售金额' ,

           --3月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-03-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '3月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-03-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '3月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-03-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '3月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-03-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '3月总可售金额' ,

           --4月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-04-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '4月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-04-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '4月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-04-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '4月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-04-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '4月总可售金额' ,
           --5月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-05-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '5月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-05-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '5月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-05-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '5月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-05-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '5月总可售金额' ,

           --6月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-06-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '6月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-06-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '6月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-06-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '6月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-06-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '6月总可售金额' ,

           --7月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-07-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '7月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-07-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '7月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-07-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '7月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-07-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '7月总可售金额' ,

           --8月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-08-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '8月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-08-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '8月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-08-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '8月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-08-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '8月总可售金额' ,

           ---9月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-09-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '9月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-09-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '9月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-09-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '9月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-09-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '9月总可售金额' ,

           --10月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-10-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '10月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-10-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '10月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-10-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '10月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-10-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '10月总可售金额' ,

           --11月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-11-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '11月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-11-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '11月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-11-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '11月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-11-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '11月总可售金额' ,
           --12月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-12-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '12月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-12-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '12月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-12-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '12月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-12-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '12月总可售金额' ,

           --下一年   
           --1月份     
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-01-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next1月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-01-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next1月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-01-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next1月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-01-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next1月总可售金额' ,
           --2月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-02-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next2月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-02-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next2月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-02-28' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next2月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-02-28' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next2月总可售金额' ,

           --3月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-03-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next3月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-03-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next3月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-03-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next3月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-03-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next3月总可售金额' ,

           --4月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-04-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next4月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-04-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next4月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-04-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next4月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-04-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next4月总可售金额' ,
           --5月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-05-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next5月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-05-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next5月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-05-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next5月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-05-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next5月总可售金额' ,

           --6月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-06-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next6月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-06-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next6月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-06-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next6月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-06-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next6月总可售金额' ,

           --7月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-07-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next7月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-07-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next7月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-07-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next7月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-07-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next7月总可售金额' ,

           --8月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-08-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next8月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-08-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next8月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-08-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next8月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-08-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next8月总可售金额' ,

           ---9月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-09-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next9月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-09-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next9月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-09-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next9月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-09-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next9月总可售金额' ,

           --10月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-10-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next10月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-10-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next10月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-10-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next10月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-10-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next10月总可售金额' ,

           --11月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-11-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next11月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-11-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next11月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-11-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next11月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-11-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next11月总可售金额' ,
           --12月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-12-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next12月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-12-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next12月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-12-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next12月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-12-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next12月总可售金额'
        INTO    #ychzyc
        FROM    dbo.p_lddb ld
                LEFT JOIN erp25.dbo.ydkb_BaseInfo bi ON ld.ProjGUID = bi.组织架构父级ID
                                                        AND bi.组织架构名称 = ld.ProductType
        WHERE   DATEDIFF(DAY, QXDate, GETDATE()) = 0
                AND ( ISNULL(IsSale, 0) = 1
                      OR ( ISNULL(IsSale, 0) = 0
                           AND ysje <> 0
                         )
                    )
                AND bi.组织架构类型 = 4
                AND ld.ProjGUID NOT IN ( SELECT ProjGUID
                                         FROM   s_SaleValuePlanSet
                                         WHERE  IsPricePrediction = 2 )
				AND ld.ProjGUID NOT  IN ( SELECT  ProjGUID FROM    s_hndjdgProjList  )
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型;

        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#ychzyc2')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #ychzyc2;
            END;

        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                SUM(CASE WHEN SaleValuePlanMonth = MONTH(GETDATE())
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 本月新货货量 ,
                SUM(CASE WHEN SaleValuePlanMonth = MONTH(GETDATE())
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 本月新货面积 ,
                SUM(CASE WHEN SaleValuePlanMonth = MONTH(GETDATE())
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisYearSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 本年存货货量 ,
                SUM(CASE WHEN SaleValuePlanMonth = MONTH(GETDATE())
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisYearSaleAreaQzkj
                         ELSE 0
                    END) AS 本年存货面积 ,

           --1月份     
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '1月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '1月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '1月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '1月总可售金额' ,
           --2月份 
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '2月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '2月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '2月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '2月总可售金额' ,

           --3月份 
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '3月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '3月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '3月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '3月总可售金额' ,

           --4月份 
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '4月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '4月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '4月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '4月总可售金额' ,

           --5月份 
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '5月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '5月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '5月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '5月总可售金额' ,

           --6月份 
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '6月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '6月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '6月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '6月总可售金额' ,

           --7月份 
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '7月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '7月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '7月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '7月总可售金额' ,

           --8月份 
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '8月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '8月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '8月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '8月总可售金额' ,

           ---9月份 
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '9月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '9月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '9月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '9月总可售金额' ,

           --10月份 
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '10月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '10月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '10月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '10月总可售金额' ,

           --11月份 
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '11月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '11月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '11月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '11月总可售金额' ,
           --12月份 
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '12月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '12月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '12月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '12月总可售金额' ,

           --下一年   
           --1月份     
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next1月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next1月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next1月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next1月总可售金额' ,
           --2月份 
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next2月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next2月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next2月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next2月总可售金额' ,

           --3月份 
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next3月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next3月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next3月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next3月总可售金额' ,

           --4月份 
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next4月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next4月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next4月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next4月总可售金额' ,
           --5月份 
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next5月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next5月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next5月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next5月总可售金额' ,

           --6月份 
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next6月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next6月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next6月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next6月总可售金额' ,

           --7月份 
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next7月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next7月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next7月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next7月总可售金额' ,

           --8月份 
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next8月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next8月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next8月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next8月总可售金额' ,

           ---9月份 
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next9月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next9月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next9月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next9月总可售金额' ,

           --10月份 
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next10月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next10月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next10月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next10月总可售金额' ,

           --11月份 
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next11月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next11月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next11月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next11月总可售金额' ,

           --12月份 
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next12月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next12月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next12月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next12月总可售金额'
        INTO    #ychzyc2
        FROM    dbo.s_SaleValuePlan ld
                LEFT JOIN erp25.dbo.ydkb_BaseInfo bi ON ld.ProjGUID = bi.组织架构父级ID
                                                        AND bi.组织架构名称 = ld.ProductType
        WHERE   bi.组织架构类型 = 4
                AND ld.ProjGUID IN ( SELECT ProjGUID
                                     FROM   s_SaleValuePlanSet
                                     WHERE  IsPricePrediction = 2 )
				AND ld.ProjGUID NOT  IN ( SELECT  ProjGUID FROM    s_hndjdgProjList  )
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型;



    ---取货量铺排模块总可售和新推货面积金额,预测1-12月份货量的分布情况
    --YearTotalSaleAreaQzkj	年度总数可售面积（取值口径）
    --YearTotalSaleMoneyQzkj	年度总数可售金额（取值口径）

    --YearTotalSaleAreaQy	年度总数销售面积（签约）
    --YearTotalSaleMoneyQy	年度总数销售金额（签约）

        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#projhzyc')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #projhzyc;
            END;

        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       GETDATE()) = 0 THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 本月新货货量 ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       GETDATE()) = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 本月新货面积 ,
                SUM(CASE WHEN DATEDIFF(yy,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       GETDATE()) = 0
                              AND ISNULL(ld.SjYsblDate, ld.YjYsblDate) < CONVERT(VARCHAR(4), GETDATE(), 120)
                              + '-01-01' THEN ld.syhz
                         ELSE 0
                    END) / 10000 本年存货货量 ,
                SUM(CASE WHEN DATEDIFF(yy,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-01-01') = 0
                              AND ISNULL(ld.SjYsblDate, ld.YjYsblDate) < CONVERT(VARCHAR(4), GETDATE(), 120)
                              + '-01-01' THEN wtmj + ytwsmj
                         ELSE 0
                    END) AS 本年存货面积 ,

           --1月份     
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-01-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '1月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-01-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '1月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-01-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '1月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-01-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '1月总可售金额' ,
           --2月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-02-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '2月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-02-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '2月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-02-28' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '2月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-02-28' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '2月总可售金额' ,

           --3月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-03-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '3月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-03-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '3月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-03-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '3月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-03-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '3月总可售金额' ,

           --4月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-04-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '4月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-04-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '4月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-04-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '4月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-04-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '4月总可售金额' ,
           --5月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-05-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '5月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-05-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '5月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-05-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '5月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-05-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '5月总可售金额' ,

           --6月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-06-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '6月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-06-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '6月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-06-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '6月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-06-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '6月总可售金额' ,

           --7月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-07-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '7月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-07-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '7月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-07-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '7月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-07-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '7月总可售金额' ,

           --8月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-08-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '8月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-08-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '8月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-08-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '8月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-08-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '8月总可售金额' ,

           ---9月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-09-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '9月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-09-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '9月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-09-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '9月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-09-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '9月总可售金额' ,

           --10月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-10-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '10月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-10-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '10月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-10-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '10月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-10-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '10月总可售金额' ,

           --11月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-11-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '11月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-11-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '11月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-11-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '11月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-11-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '11月总可售金额' ,
           --12月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-12-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '12月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @bnyear + '-12-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '12月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-12-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS '12月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @bnyear
                              + '-12-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS '12月总可售金额' ,

           --下一年   
           --1月份     
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-01-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next1月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-01-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next1月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-01-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next1月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-01-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next1月总可售金额' ,
           --2月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-02-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next2月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-02-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next2月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-02-28' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next2月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-02-28' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next2月总可售金额' ,

           --3月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-03-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next3月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-03-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next3月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-03-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next3月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-03-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next3月总可售金额' ,

           --4月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-04-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next4月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-04-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next4月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-04-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next4月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-04-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next4月总可售金额' ,
           --5月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-05-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next5月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-05-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next5月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-05-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next5月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-05-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next5月总可售金额' ,

           --6月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-06-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next6月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-06-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next6月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-06-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next6月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-06-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next6月总可售金额' ,

           --7月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-07-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next7月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-07-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next7月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-07-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next7月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-07-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next7月总可售金额' ,

           --8月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-08-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next8月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-08-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next8月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-08-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next8月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-08-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next8月总可售金额' ,

           ---9月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-09-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next9月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-09-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next9月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-09-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next9月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-09-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next9月总可售金额' ,

           --10月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-10-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next10月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-10-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next10月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-10-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next10月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-10-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next10月总可售金额' ,

           --11月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-11-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next11月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-11-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next11月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-11-30' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next11月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-11-30' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next11月总可售金额' ,
           --12月份 
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-12-01') = 0
                         THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next12月新增可售面积' ,
                SUM(CASE WHEN DATEDIFF(mm,
                                       ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                       @NextYear + '-12-01') = 0
                         THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next12月新增可售金额' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-12-31' THEN wtmj + ytwsmj + ysmj
                         ELSE 0
                    END) AS 'Next12月总可售面积' ,
                SUM(CASE WHEN ISNULL(ld.SjYsblDate, ld.YjYsblDate) <= @NextYear
                              + '-12-31' THEN ld.syhz + ysje
                         ELSE 0
                    END) / 10000 AS 'Next12月总可售金额'
        INTO    #projhzyc
        FROM    dbo.p_lddb ld
                LEFT JOIN erp25.dbo.ydkb_BaseInfo bi ON ld.ProjGUID = bi.组织架构ID
        WHERE   DATEDIFF(DAY, QXDate, GETDATE()) = 0
                AND ( ISNULL(IsSale, 0) = 1
                      OR ( ISNULL(IsSale, 0) = 0
                           AND ysje <> 0
                         )
                    )
                AND bi.组织架构类型 = 3
                AND ld.ProjGUID NOT IN ( SELECT ProjGUID
                                         FROM   s_SaleValuePlanSet
                                         WHERE  IsPricePrediction = 2 )
				AND ld.ProjGUID NOT  IN ( SELECT  ProjGUID FROM    s_hndjdgProjList  )
    --AND SaleValuePlanMonth = MONTH(GETDATE())
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型;

        IF EXISTS ( SELECT  *
                    FROM    tempdb.dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'tempdb..#projhzyc2')
                            AND type = 'U' )
            BEGIN
                DROP TABLE #projhzyc2;
            END;

        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                SUM(CASE WHEN SaleValuePlanMonth = MONTH(GETDATE())
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 本月新货货量 ,
                SUM(CASE WHEN SaleValuePlanMonth = MONTH(GETDATE())
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 本月新货面积 ,
                SUM(CASE WHEN SaleValuePlanMonth = MONTH(GETDATE())
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisYearSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 本年存货货量 ,
                SUM(CASE WHEN SaleValuePlanMonth = MONTH(GETDATE())
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisYearSaleAreaQzkj
                         ELSE 0
                    END) AS 本年存货面积 ,

           --1月份     
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '1月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '1月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '1月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '1月总可售金额' ,
           --2月份 
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '2月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '2月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '2月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '2月总可售金额' ,

           --3月份 
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '3月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '3月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '3月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '3月总可售金额' ,

           --4月份 
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '4月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '4月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '4月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '4月总可售金额' ,

           --5月份 
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '5月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '5月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '5月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '5月总可售金额' ,

           --6月份 
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '6月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '6月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '6月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '6月总可售金额' ,

           --7月份 
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '7月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '7月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '7月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '7月总可售金额' ,

           --8月份 
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '8月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '8月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '8月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '8月总可售金额' ,

           ---9月份 
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '9月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '9月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '9月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '9月总可售金额' ,

           --10月份 
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '10月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '10月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '10月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '10月总可售金额' ,

           --11月份 
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '11月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '11月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '11月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '11月总可售金额' ,
           --12月份 
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS '12月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '12月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS '12月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = YEAR(GETDATE())
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS '12月总可售金额' ,

           --下一年   
           --1月份     
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next1月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next1月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next1月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 1
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next1月总可售金额' ,
           --2月份 
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next2月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next2月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next2月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 2
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next2月总可售金额' ,

           --3月份 
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next3月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next3月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next3月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 3
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next3月总可售金额' ,

           --4月份 
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next4月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next4月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next4月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 4
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next4月总可售金额' ,
           --5月份 
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next5月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next5月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next5月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 5
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next5月总可售金额' ,

           --6月份 
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next6月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next6月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next6月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 6
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next6月总可售金额' ,

           --7月份 
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next7月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next7月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next7月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 7
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next7月总可售金额' ,

           --8月份 
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next8月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next8月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next8月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 8
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next8月总可售金额' ,

           ---9月份 
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next9月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next9月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next9月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 9
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next9月总可售金额' ,

           --10月份 
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next10月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next10月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next10月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 10
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next10月总可售金额' ,

           --11月份 
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next11月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next11月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next11月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 11
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next11月总可售金额' ,

           --12月份 
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next12月新增可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next12月新增可售金额' ,
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleAreaQzkj
                         ELSE 0
                    END) AS 'Next12月总可售面积' ,
                SUM(CASE WHEN SaleValuePlanMonth = 12
                              AND SaleValuePlanYear = ( YEAR(GETDATE()) + 1 )
                         THEN ThisMonthTotalSaleMoneyQzkj
                         ELSE 0
                    END) / 10000 AS 'Next12月总可售金额'
        INTO    #projhzyc2
        FROM    dbo.s_SaleValuePlan ld
                LEFT JOIN erp25.dbo.ydkb_BaseInfo bi ON ld.ProjGUID = bi.组织架构ID
        WHERE   bi.组织架构类型 = 3
                AND ld.ProjGUID IN ( SELECT ProjGUID
                                     FROM   s_SaleValuePlanSet
                                     WHERE  IsPricePrediction = 2 )
				AND ld.ProjGUID NOT  IN ( SELECT  ProjGUID FROM    s_hndjdgProjList  )
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型;

    ---插入楼栋业态货量数据
        INSERT  INTO dbo.ydkb_dthz
                ( 组织架构ID ,
                  组织架构名称 ,
                  组织架构编码 ,
                  组织架构类型 ,
                  总货值金额 ,
                  总货值面积 ,
                  已售货量金额 ,
                  已售货量面积 ,

                  总货值金额操盘项目 ,
                  总货值面积操盘项目 ,
                  已售货量金额操盘项目 ,
                  已售货量面积操盘项目 ,

                  剩余货值金额 ,
                  剩余货值面积 ,
                  剩余可售货值金额 ,
                  剩余可售货值面积 ,
                  --本月情况
                  工程达到可售未拿证货值金额 ,
                  工程达到可售未拿证货值面积 ,
                  获证未推货值金额 ,
                  获证未推货值面积 ,
                  已推未售货值金额 ,
                  已推未售货值面积 ,

                 --操盘项目
                  剩余货值金额操盘项目 ,
                  剩余货值面积操盘项目 ,
                  剩余可售货值金额操盘项目 ,
                  剩余可售货值面积操盘项目 ,
                  工程达到可售未拿证货值金额操盘项目 ,
                  工程达到可售未拿证货值面积操盘项目 ,
                  获证未推货值金额操盘项目 ,
                  获证未推货值面积操盘项目 ,
                  已推未售货值金额操盘项目 ,
                  已推未售货值面积操盘项目 ,

				    --年初可售情况
                  年初工程达到可售未拿证货值金额 ,
                  年初工程达到可售未拿证货值面积 ,
                  年初获证未推货值金额 ,
                  年初获证未推货值面积 ,
                  年初已推未售货值金额 ,
                  年初已推未售货值面积 ,

        --本月新货货量 ,
        --本月新货面积 ,
        --本年存货货量 ,
        --本年存货面积 ,
                  后续预计达成货量金额 ,
                  后续预计达成货量面积 ,
                  今年后续预计达成货量金额 ,
                  今年后续预计达成货量面积 ,
                  本年可售货量金额 ,
                  本年可售货量面积 ,
                  本年剩余可售货量金额 ,
                  本年剩余可售货量面积 ,
				  当前剩余可售货量金额 ,
                  当前剩余可售货量面积 ,
                  本年已售货量金额 ,
                  本年已售货量面积 ,
                  Jan预计货量金额 ,
                  Jan实际货量金额 ,
                  Jan货量达成率 ,
                  Feb预计货量金额 ,
                  Feb实际货量金额 ,
                  Feb货量达成率 ,
                  Mar预计货量金额 ,
                  Mar实际货量金额 ,
                  Mar货量达成率 ,
                  Apr预计货量金额 ,
                  Apr实际货量金额 ,
                  Apr货量达成率 ,
                  May预计货量金额 ,
                  May实际货量金额 ,
                  May货量达成率 ,
                  Jun预计货量金额 ,
                  Jun实际货量金额 ,
                  Jun货量达成率 ,
                  July预计货量金额 ,
                  July实际货量金额 ,
                  July货量达成率 ,
                  Aug预计货量金额 ,
                  Aug实际货量金额 ,
                  Aug货量达成率 ,
                  Sep预计货量金额 ,
                  Sep实际货量金额 ,
                  Sep货量达成率 ,
                  Oct预计货量金额 ,
                  Oct实际货量金额 ,
                  Oct货量达成率 ,
                  Nov预计货量金额 ,
                  Nov实际货量金额 ,
                  Nov货量达成率 ,
                  Dec预计货量金额 ,
                  Dec实际货量金额 ,
                  Dec货量达成率 ,
                  本月预计货量金额 ,
                  本月实际货量金额 ,
                  本月货量达成率 ,
                  本年预计货量金额 ,
                  本年实际货量金额 ,
                  本年货量达成率 ,

		--1-2月份
                  Jan可售货值金额 ,
                  Jan可售货值面积 ,
                  Jan新推货值金额 ,
                  Jan新推货值面积 ,
                  Feb可售货值金额 ,
                  Feb可售货值面积 ,
                  Feb新推货值金额 ,
                  Feb新推货值面积 ,
                  JanFeb可售货值金额 ,
                  JanFeb可售货值面积 ,
                  JanFeb新推货值金额 ,
                  JanFeb新推货值面积 ,
        --3月份
                  Mar可售货值金额 ,
                  Mar可售货值面积 ,
                  Mar新推货值金额 ,
                  Mar新推货值面积 ,

        --4月份
                  Apr可售货值金额 ,
                  Apr可售货值面积 ,
                  Apr新推货值金额 ,
                  Apr新推货值面积 ,

        --5月份
                  May可售货值金额 ,
                  May可售货值面积 ,
                  May新推货值金额 ,
                  May新推货值面积 ,

        --6月份
                  Jun可售货值金额 ,
                  Jun可售货值面积 ,
                  Jun新推货值金额 ,
                  Jun新推货值面积 ,

        --7月份
                  July可售货值金额 ,
                  July可售货值面积 ,
                  July新推货值金额 ,
                  July新推货值面积 ,

        --8月份
                  Aug可售货值金额 ,
                  Aug可售货值面积 ,
                  Aug新推货值金额 ,
                  Aug新推货值面积 ,

        --9月份
                  Sep可售货值金额 ,
                  Sep可售货值面积 ,
                  Sep新推货值金额 ,
                  Sep新推货值面积 ,

        --10月份
                  Oct可售货值金额 ,
                  Oct可售货值面积 ,
                  Oct新推货值金额 ,
                  Oct新推货值面积 ,

        --11月份
                  Nov可售货值金额 ,
                  Nov可售货值面积 ,
                  Nov新推货值金额 ,
                  Nov新推货值面积 ,

        --12月份
                  Dec可售货值金额 ,
                  Dec可售货值面积 ,
                  Dec新推货值金额 ,
                  Dec新推货值面积 ,

        --下一年
        --1-2月份
                  NextJan可售货值金额 ,
                  NextJan可售货值面积 ,
                  NextJan新推货值金额 ,
                  NextJan新推货值面积 ,
                  NextFeb可售货值金额 ,
                  NextFeb可售货值面积 ,
                  NextFeb新推货值金额 ,
                  NextFeb新推货值面积 ,
                  NextJanFeb可售货值金额 ,
                  NextJanFeb可售货值面积 ,
                  NextJanFeb新推货值金额 ,
                  NextJanFeb新推货值面积 ,
        --3月份
                  NextMar可售货值金额 ,
                  NextMar可售货值面积 ,
                  NextMar新推货值金额 ,
                  NextMar新推货值面积 ,

        --4月份
                  NextApr可售货值金额 ,
                  NextApr可售货值面积 ,
                  NextApr新推货值金额 ,
                  NextApr新推货值面积 ,

        --5月份
                  NextMay可售货值金额 ,
                  NextMay可售货值面积 ,
                  NextMay新推货值金额 ,
                  NextMay新推货值面积 ,

        --6月份
                  NextJun可售货值金额 ,
                  NextJun可售货值面积 ,
                  NextJun新推货值金额 ,
                  NextJun新推货值面积 ,

        --7月份
                  NextJuly可售货值金额 ,
                  NextJuly可售货值面积 ,
                  NextJuly新推货值金额 ,
                  NextJuly新推货值面积 ,

        --8月份
                  NextAug可售货值金额 ,
                  NextAug可售货值面积 ,
                  NextAug新推货值金额 ,
                  NextAug新推货值面积 ,

        --9月份
                  NextSep可售货值金额 ,
                  NextSep可售货值面积 ,
                  NextSep新推货值金额 ,
                  NextSep新推货值面积 ,

        --10月份
                  NextOct可售货值金额 ,
                  NextOct可售货值面积 ,
                  NextOct新推货值金额 ,
                  NextOct新推货值面积 ,

        --11月份
                  NextNov可售货值金额 ,
                  NextNov可售货值面积 ,
                  NextNov新推货值金额 ,
                  NextNov新推货值面积 ,

        --12月份
                  NextDec可售货值金额 ,
                  NextDec可售货值面积 ,
                  NextDec新推货值金额 ,
                  NextDec新推货值面积 ,
                  滞后货量金额 ,
                  滞后货量面积 ,
                  预计达到预售形象日期 ,
                  实际达到预售形象日期 ,
                  预计预售办理日期 ,
                  实际预售办理日期 ,
                  预计售价 ,
                  今年车位可售金额
                )
                SELECT  bi.组织架构ID ,
                        bi.组织架构名称 ,
                        bi.组织架构编码 ,
                        bi.组织架构类型 ,

                        phz.总货值金额 ,
                        phz.总货值面积 ,
                        phz.已售货量金额 ,
                        phz.已售货量面积 ,
                        --操盘项目
                        phz.总货值操盘金额 AS 总货值金额操盘项目 ,
                        phz.总货值操盘面积 AS 总货值面积操盘项目 ,
                        phz.已售货量操盘金额 AS 已售货量金额操盘项目 ,
                        phz.已售货量操盘面积 AS 已售货量面积操盘项目 ,

                        phz.未销售部分货量 ,
                        phz.未销售部分可售面积 ,
                        phz.剩余可售货值金额 ,
                        phz.剩余可售货值面积 ,
                        phz.工程达到可售未拿证货值金额 ,
                        phz.工程达到可售未拿证货值面积 ,
                        phz.获证未推货值金额 ,
                        phz.获证未推货值面积 ,
                        phz.已推未售货值金额 ,
                        phz.已推未售货值面积 ,

              --操盘项目
                        phz.未销售部分操盘货量 AS 剩余货值金额操盘项目 ,
                        phz.未销售部分可售操盘面积 AS 剩余货值面积操盘项目 ,
                        phz.剩余可售货值操盘金额 AS 剩余可售货值金额操盘项目 ,
                        phz.剩余可售货值操盘面积 AS 剩余可售货值面积操盘项目 ,
                        phz.工程达到可售未拿证货值操盘金额 AS 工程达到可售未拿证货值金额操盘项目 ,
                        phz.工程达到可售未拿证货值操盘面积 AS 工程达到可售未拿证货值面积操盘项目 ,
                        phz.获证未推货值操盘金额 AS 获证未推货值金额操盘项目 ,
                        phz.获证未推货值操盘面积 AS 获证未推货值面积操盘项目 ,
                        phz.已推未售货值操盘金额 AS 已推未售货值金额操盘项目 ,
                        phz.已推未售货值操盘面积 AS 已推未售货值面积操盘项目 ,

				--年初可售情况
                        phz.年初工程达到可售未拿证货值金额 ,
                        phz.年初工程达到可售未拿证货值面积 ,
                        phz.年初获证未推货值金额 ,
                        phz.年初获证未推货值面积 ,
                        phz.年初已推未售货值金额 AS 年初已推未售货值金额 ,
                        phz.年初已推未售货值面积 AS 年初已推未售货值面积 ,

                        phz.后续预计达成货量金额 AS 后续预计达成货量金额 ,
                        phz.后续预计达成货量面积 AS 后续预计达成货量面积 ,
                        phz.今年后续预计达成货量金额 AS 今年后续预计达成货量金额 ,
                        phz.今年后续预计达成货量面积 AS 今年后续预计达成货量面积 ,
           -- ISNULL(phz.本年可售货量金额, 0) AS 本年可售货量金额 ,
           -- ISNULL(phz.本年可售货量面积, 0) AS 本年可售货量面积 ,
                        (
		   --年初
                          phz.年初工程达到可售未拿证货值金额 + phz.年初获证未推货值金额
                          + phz.年初已推未售货值金额
		   --新增
                          + phzyc.[1月新增可售金额] + phzyc.[2月新增可售金额]
                          + phzyc.[3月新增可售金额] + phzyc.[4月新增可售金额]
                          + phzyc.[5月新增可售金额] + phzyc.[6月新增可售金额]
                          + phzyc.[7月新增可售金额] + phzyc.[8月新增可售金额]
                          + phzyc.[9月新增可售金额] + phzyc.[10月新增可售金额]
                          + phzyc.[11月新增可售金额] + phzyc.[12月新增可售金额] ) AS 本年可售货量金额 ,
                        (
		   --年初
                          phz.年初工程达到可售未拿证货值面积 + phz.年初获证未推货值面积
                          + phz.年初已推未售货值面积
		   --新增
                          + phzyc.[1月新增可售面积] + phzyc.[2月新增可售面积]
                          + phzyc.[3月新增可售面积] + phzyc.[4月新增可售面积]
                          + phzyc.[5月新增可售面积] + phzyc.[6月新增可售面积]
                          + phzyc.[7月新增可售面积] + phzyc.[8月新增可售面积]
                          + phzyc.[9月新增可售面积] + phzyc.[10月新增可售面积]
                          + phzyc.[11月新增可售面积] + phzyc.[12月新增可售面积] ) AS 本年可售货量面积 ,
                        ISNULL(phz.本年剩余可售货量金额, 0) AS 本年剩余可售货量金额 ,
                        ISNULL(phz.本年剩余可售货量面积, 0) AS 本年剩余可售货量面积 ,
						ISNULL(phz.当前剩余可售货量金额, 0) AS 当前剩余可售货量金额 ,
                        ISNULL(phz.当前剩余可售货量面积, 0) AS 当前剩余可售货量面积 ,
                        ISNULL(phz.本年已售货量金额, 0) AS 本年已售货量金额 ,
                        ISNULL(phz.本年已售货量面积, 0) AS 本年已售货量面积 ,

           --货量计划
                        ISNULL(phz.Jan预计货量金额, 0) AS Jan预计货量金额 ,
                        ISNULL(phz.Jan实际货量金额, 0) AS Jan实际货量金额 ,
                        CASE WHEN ISNULL(phz.Jan预计货量金额, 0) = 0 THEN 0
                             ELSE ISNULL(phz.Jan实际货量金额, 0)
                                  / ISNULL(phz.Jan预计货量金额, 0) * 1.00
                        END AS Jan货量达成率 ,
                        ISNULL(phz.Feb预计货量金额, 0) AS Feb预计货量金额 ,
                        ISNULL(phz.Feb实际货量金额, 0) AS Feb实际货量金额 ,
                        CASE WHEN ISNULL(phz.Feb预计货量金额, 0) = 0 THEN 0
                             ELSE ISNULL(phz.Feb实际货量金额, 0)
                                  / ISNULL(phz.Feb预计货量金额, 0) * 1.00
                        END AS Feb货量达成率 ,
                        ISNULL(phz.Mar预计货量金额, 0) AS Mar预计货量金额 ,
                        ISNULL(phz.Mar实际货量金额, 0) AS Mar实际货量金额 ,
                        CASE WHEN ISNULL(phz.Mar预计货量金额, 0) = 0 THEN 0
                             ELSE ISNULL(phz.Mar实际货量金额, 0)
                                  / ISNULL(phz.Mar预计货量金额, 0) * 1.00
                        END AS Mar货量达成率 ,
                        ISNULL(phz.Apr预计货量金额, 0) AS Apr预计货量金额 ,
                        ISNULL(phz.Apr实际货量金额, 0) AS Apr实际货量金额 ,
                        CASE WHEN ISNULL(phz.Apr预计货量金额, 0) = 0 THEN 0
                             ELSE ISNULL(phz.Apr实际货量金额, 0)
                                  / ISNULL(phz.Apr预计货量金额, 0) * 1.00
                        END AS Apr货量达成率 ,
                        ISNULL(phz.May预计货量金额, 0) AS May预计货量金额 ,
                        ISNULL(phz.May实际货量金额, 0) AS May实际货量金额 ,
                        CASE WHEN ISNULL(phz.May预计货量金额, 0) = 0 THEN 0
                             ELSE ISNULL(phz.May实际货量金额, 0)
                                  / ISNULL(phz.May预计货量金额, 0) * 1.00
                        END AS May货量达成率 ,
                        ISNULL(phz.Jun预计货量金额, 0) AS Jun预计货量金额 ,
                        ISNULL(phz.Jun实际货量金额, 0) AS Jun实际货量金额 ,
                        CASE WHEN ISNULL(phz.Jun预计货量金额, 0) = 0 THEN 0
                             ELSE ISNULL(phz.Jun实际货量金额, 0)
                                  / ISNULL(phz.Jun预计货量金额, 0) * 1.00
                        END AS Jun货量达成率 ,
                        ISNULL(phz.July预计货量金额, 0) AS July预计货量金额 ,
                        ISNULL(phz.July实际货量金额, 0) AS July实际货量金额 ,
                        CASE WHEN ISNULL(phz.July预计货量金额, 0) = 0 THEN 0
                             ELSE ISNULL(phz.July实际货量金额, 0)
                                  / ISNULL(phz.July预计货量金额, 0) * 1.00
                        END AS July货量达成率 ,
                        ISNULL(phz.Aug预计货量金额, 0) AS Aug预计货量金额 ,
                        ISNULL(phz.Aug实际货量金额, 0) AS Aug实际货量金额 ,
                        CASE WHEN ISNULL(phz.Aug预计货量金额, 0) = 0 THEN 0
                             ELSE ISNULL(phz.Aug实际货量金额, 0)
                                  / ISNULL(phz.Aug预计货量金额, 0) * 1.00
                        END AS Aug货量达成率 ,
                        ISNULL(phz.Sep预计货量金额, 0) AS Sep预计货量金额 ,
                        ISNULL(phz.Sep实际货量金额, 0) AS Sep实际货量金额 ,
                        CASE WHEN ISNULL(phz.Sep预计货量金额, 0) = 0 THEN 0
                             ELSE ISNULL(phz.Sep实际货量金额, 0)
                                  / ISNULL(phz.Sep预计货量金额, 0) * 1.00
                        END AS Sep货量达成率 ,
                        ISNULL(phz.Oct预计货量金额, 0) AS Oct预计货量金额 ,
                        ISNULL(phz.Oct实际货量金额, 0) AS Oct实际货量金额 ,
                        CASE WHEN ISNULL(phz.Oct预计货量金额, 0) = 0 THEN 0
                             ELSE ISNULL(phz.Oct实际货量金额, 0)
                                  / ISNULL(phz.Oct预计货量金额, 0) * 1.00
                        END AS Oct货量达成率 ,
                        ISNULL(phz.Nov预计货量金额, 0) AS Nov预计货量金额 ,
                        ISNULL(phz.Nov实际货量金额, 0) AS Nov实际货量金额 ,
                        CASE WHEN ISNULL(phz.Nov预计货量金额, 0) = 0 THEN 0
                             ELSE ISNULL(phz.Nov实际货量金额, 0)
                                  / ISNULL(phz.Nov预计货量金额, 0) * 1.00
                        END AS Nov货量达成率 ,
                        ISNULL(phz.Dec预计货量金额, 0) AS Dec预计货量金额 ,
                        ISNULL(phz.Dec实际货量金额, 0) AS Dec实际货量金额 ,
                        CASE WHEN ISNULL(phz.Dec预计货量金额, 0) = 0 THEN 0
                             ELSE ISNULL(phz.Dec实际货量金额, 0)
                                  / ISNULL(phz.Dec预计货量金额, 0) * 1.00
                        END AS Dec货量达成率 ,
                        ISNULL(phz.本月预计货量金额, 0) AS 本月预计货量金额 ,
                        ISNULL(phz.本月实际货量金额, 0) AS 本月实际货量金额 ,
                        CASE WHEN ISNULL(phz.本月预计货量金额, 0) = 0 THEN 0
                             ELSE ISNULL(phz.本月实际货量金额, 0)
                                  / ISNULL(phz.本月预计货量金额, 0) * 1.00
                        END AS 本月货量达成率 ,
                        ISNULL(phz.本年预计货量金额, 0) AS 本年预计货量金额 ,
                        ISNULL(phz.本年实际货量金额, 0) AS 本年实际货量金额 ,
                        CASE WHEN ISNULL(phz.本年预计货量金额, 0) = 0 THEN 0
                             ELSE ISNULL(phz.本年实际货量金额, 0)
                                  / ISNULL(phz.本年预计货量金额, 0) * 1.00
                        END AS 本年货量达成率 ,
                        ISNULL(phzyc.[1月总可售金额], 0) AS Jan可售货值金额 ,
                        ISNULL(phzyc.[1月总可售面积], 0) AS Jan可售货值面积 ,
                        ISNULL(phzyc.[1月新增可售金额], 0) AS Jan新推货值金额 ,
                        ISNULL(phzyc.[1月新增可售面积], 0) AS Jan新推货值面积 ,
                        ISNULL(phzyc.[2月总可售金额], 0) AS Feb可售货值金额 ,
                        ISNULL(phzyc.[2月总可售面积], 0) AS Feb可售货值面积 ,
                        ISNULL(phzyc.[2月新增可售金额], 0) AS Feb新推货值金额 ,
                        ISNULL(phzyc.[2月新增可售面积], 0) AS Feb新推货值面积 ,
                        ISNULL(phzyc.[1月总可售金额], 0) + ISNULL(phzyc.[2月总可售金额], 0) AS JanFeb可售货值金额 ,
                        ISNULL(phzyc.[1月总可售面积], 0) + ISNULL(phzyc.[2月总可售面积], 0) AS JanFeb可售货值面积 ,
                        ISNULL(phzyc.[1月新增可售金额], 0) + ISNULL(phzyc.[2月新增可售金额],
                                                             0) AS JanFeb新推货值金额 ,
                        ISNULL(phzyc.[1月新增可售面积], 0) + ISNULL(phzyc.[2月新增可售面积],
                                                             0) AS JanFeb新推货值面积 ,
                        ISNULL(phzyc.[3月总可售金额], 0) AS Mar可售货值金额 ,
                        ISNULL(phzyc.[3月总可售面积], 0) AS Mar可售货值面积 ,
                        ISNULL(phzyc.[3月新增可售金额], 0) AS Mar新推货值金额 ,
                        ISNULL(phzyc.[3月新增可售面积], 0) AS Mar新推货值面积 ,
                        ISNULL(phzyc.[4月总可售金额], 0) AS Apr可售货值金额 ,
                        ISNULL(phzyc.[4月总可售面积], 0) AS Apr可售货值面积 ,
                        ISNULL(phzyc.[4月新增可售金额], 0) AS Apr新推货值金额 ,
                        ISNULL(phzyc.[4月新增可售面积], 0) AS Apr新推货值面积 ,
                        ISNULL(phzyc.[5月总可售金额], 0) AS May可售货值金额 ,
                        ISNULL(phzyc.[5月总可售面积], 0) AS May可售货值面积 ,
                        ISNULL(phzyc.[5月新增可售金额], 0) AS May新推货值金额 ,
                        ISNULL(phzyc.[5月新增可售面积], 0) AS May新推货值面积 ,
                        ISNULL(phzyc.[6月总可售金额], 0) AS Jun可售货值金额 ,
                        ISNULL(phzyc.[6月总可售面积], 0) AS Jun可售货值面积 ,
                        ISNULL(phzyc.[6月新增可售金额], 0) AS Jun新推货值金额 ,
                        ISNULL(phzyc.[6月新增可售面积], 0) AS Jun新推货值面积 ,
                        ISNULL(phzyc.[7月总可售金额], 0) AS July可售货值金额 ,
                        ISNULL(phzyc.[7月总可售面积], 0) AS July可售货值面积 ,
                        ISNULL(phzyc.[7月新增可售金额], 0) AS July新推货值金额 ,
                        ISNULL(phzyc.[7月新增可售面积], 0) AS July新推货值面积 ,
                        ISNULL(phzyc.[8月总可售金额], 0) AS Aug可售货值金额 ,
                        ISNULL(phzyc.[8月总可售面积], 0) AS Aug可售货值面积 ,
                        ISNULL(phzyc.[8月新增可售金额], 0) AS Aug新推货值金额 ,
                        ISNULL(phzyc.[8月新增可售面积], 0) AS Aug新推货值面积 ,
                        ISNULL(phzyc.[9月总可售金额], 0) AS Sep可售货值金额 ,
                        ISNULL(phzyc.[9月总可售面积], 0) AS Sep可售货值面积 ,
                        ISNULL(phzyc.[9月新增可售金额], 0) AS Sep新推货值金额 ,
                        ISNULL(phzyc.[9月新增可售面积], 0) AS Sep新推货值面积 ,
                        ISNULL(phzyc.[10月总可售金额], 0) AS Oct可售货值金额 ,
                        ISNULL(phzyc.[10月总可售面积], 0) AS Oct可售货值面积 ,
                        ISNULL(phzyc.[10月新增可售金额], 0) AS Oct新推货值金额 ,
                        ISNULL(phzyc.[10月新增可售面积], 0) AS Oct新推货值面积 ,
                        ISNULL(phzyc.[11月总可售金额], 0) AS Nov可售货值金额 ,
                        ISNULL(phzyc.[11月总可售面积], 0) AS Nov可售货值面积 ,
                        ISNULL(phzyc.[11月新增可售金额], 0) AS Nov新推货值金额 ,
                        ISNULL(phzyc.[11月新增可售面积], 0) AS Nov新推货值面积 ,
                        ISNULL(phzyc.[12月总可售金额], 0) AS Dec可售货值金额 ,
                        ISNULL(phzyc.[12月总可售面积], 0) AS Dec可售货值面积 ,
                        ISNULL(phzyc.[12月新增可售金额], 0) AS Dec新推货值金额 ,
                        ISNULL(phzyc.[12月新增可售面积], 0) AS Dec新推货值面积 ,
                        ISNULL(phzyc.[Next1月总可售金额], 0) AS NextJan可售货值金额 ,
                        ISNULL(phzyc.[Next1月总可售面积], 0) AS NextJan可售货值面积 ,
                        ISNULL(phzyc.[Next1月新增可售金额], 0) AS NextJan新推货值金额 ,
                        ISNULL(phzyc.[Next1月新增可售面积], 0) AS NextJan新推货值面积 ,
                        ISNULL(phzyc.[Next2月总可售金额], 0) AS NextFeb可售货值金额 ,
                        ISNULL(phzyc.[Next2月总可售面积], 0) AS NextFeb可售货值面积 ,
                        ISNULL(phzyc.[Next2月新增可售金额], 0) AS NextFeb新推货值金额 ,
                        ISNULL(phzyc.[Next2月新增可售面积], 0) AS NextFeb新推货值面积 ,
                        ISNULL(phzyc.[Next1月总可售金额], 0)
                        + ISNULL(phzyc.[Next2月总可售金额], 0) AS NextJanFeb可售货值金额 ,
                        ISNULL(phzyc.[Next1月总可售面积], 0)
                        + ISNULL(phzyc.[Next2月总可售面积], 0) AS NextJanFeb可售货值面积 ,
                        ISNULL(phzyc.[Next1月新增可售金额], 0)
                        + ISNULL(phzyc.[Next2月新增可售金额], 0) AS NextJanFeb新推货值金额 ,
                        ISNULL(phzyc.[Next1月新增可售面积], 0)
                        + ISNULL(phzyc.[Next2月新增可售面积], 0) AS NextJanFeb新推货值面积 ,
                        ISNULL(phzyc.[Next3月总可售金额], 0) AS NextMar可售货值金额 ,
                        ISNULL(phzyc.[Next3月总可售面积], 0) AS NextMar可售货值面积 ,
                        ISNULL(phzyc.[Next3月新增可售金额], 0) AS NextMar新推货值金额 ,
                        ISNULL(phzyc.[Next3月新增可售面积], 0) AS NextMar新推货值面积 ,
                        ISNULL(phzyc.[Next4月总可售金额], 0) AS NextApr可售货值金额 ,
                        ISNULL(phzyc.[Next4月总可售面积], 0) AS NextApr可售货值面积 ,
                        ISNULL(phzyc.[Next4月新增可售金额], 0) AS NextApr新推货值金额 ,
                        ISNULL(phzyc.[Next4月新增可售面积], 0) AS NextApr新推货值面积 ,
                        ISNULL(phzyc.[Next5月总可售金额], 0) AS NextMay可售货值金额 ,
                        ISNULL(phzyc.[Next5月总可售面积], 0) AS NextMay可售货值面积 ,
                        ISNULL(phzyc.[Next5月新增可售金额], 0) AS NextMay新推货值金额 ,
                        ISNULL(phzyc.[Next5月新增可售面积], 0) AS NextMay新推货值面积 ,
                        ISNULL(phzyc.[Next6月总可售金额], 0) AS NextJun可售货值金额 ,
                        ISNULL(phzyc.[Next6月总可售面积], 0) AS NextJun可售货值面积 ,
                        ISNULL(phzyc.[Next6月新增可售金额], 0) AS NextJun新推货值金额 ,
                        ISNULL(phzyc.[Next6月新增可售面积], 0) AS NextJun新推货值面积 ,
                        ISNULL(phzyc.[Next7月总可售金额], 0) AS NextJuly可售货值金额 ,
                        ISNULL(phzyc.[Next7月总可售面积], 0) AS NextJuly可售货值面积 ,
                        ISNULL(phzyc.[Next7月新增可售金额], 0) AS NextJuly新推货值金额 ,
                        ISNULL(phzyc.[Next7月新增可售面积], 0) AS NextJuly新推货值面积 ,
                        ISNULL(phzyc.[Next8月总可售金额], 0) AS NextAug可售货值金额 ,
                        ISNULL(phzyc.[Next8月总可售面积], 0) AS NextAug可售货值面积 ,
                        ISNULL(phzyc.[Next8月新增可售金额], 0) AS NextAug新推货值金额 ,
                        ISNULL(phzyc.[Next8月新增可售面积], 0) AS NextAug新推货值面积 ,
                        ISNULL(phzyc.[Next9月总可售金额], 0) AS NextSep可售货值金额 ,
                        ISNULL(phzyc.[Next9月总可售面积], 0) AS NextSep可售货值面积 ,
                        ISNULL(phzyc.[Next9月新增可售金额], 0) AS NextSep新推货值金额 ,
                        ISNULL(phzyc.[Next9月新增可售面积], 0) AS NextSep新推货值面积 ,
                        ISNULL(phzyc.[Next10月总可售金额], 0) AS NextOct可售货值金额 ,
                        ISNULL(phzyc.[Next10月总可售面积], 0) AS NextOct可售货值面积 ,
                        ISNULL(phzyc.[Next10月新增可售金额], 0) AS NextOct新推货值金额 ,
                        ISNULL(phzyc.[Next10月新增可售面积], 0) AS NextOct新推货值面积 ,
                        ISNULL(phzyc.[Next11月总可售金额], 0) AS NextNov可售货值金额 ,
                        ISNULL(phzyc.[Next11月总可售面积], 0) AS NextNov可售货值面积 ,
                        ISNULL(phzyc.[Next11月新增可售金额], 0) AS NextNextNov新推货值金额 ,
                        ISNULL(phzyc.[Next11月新增可售面积], 0) AS NextNov新推货值面积 ,
                        ISNULL(phzyc.[Next12月总可售金额], 0) AS NextDec可售货值金额 ,
                        ISNULL(phzyc.[Next12月总可售面积], 0) AS NextDec可售货值面积 ,
                        ISNULL(phzyc.[Next12月新增可售金额], 0) AS NextDec新推货值金额 ,
                        ISNULL(phzyc.[Next12月新增可售面积], 0) AS NextDec新推货值面积 ,
                        ISNULL(phz.滞后货量金额, 0) AS 滞后货量金额 ,
                        ISNULL(phz.滞后货量面积, 0) AS 滞后货量面积 ,
                        phz.预计达到预售形象日期 ,
                        phz.实际达到预售形象日期 ,
                        phz.预计预售办理日期 ,
                        phz.实际预售办理日期 ,
                        phz.预计售价 ,
                        ISNULL(phz.今年车位可售金额, 0) AS 今年车位可售金额
                FROM    erp25.dbo.ydkb_BaseInfo bi
                        INNER JOIN #ldhz phz ON phz.组织架构ID = bi.组织架构ID
                        LEFT JOIN #ldhzyc phzyc ON bi.组织架构ID = phzyc.组织架构ID
                WHERE   bi.组织架构类型 = 5;

    ---插入产品业态货量数据
        INSERT  INTO dbo.ydkb_dthz
                ( 组织架构ID ,
                  组织架构名称 ,
                  组织架构编码 ,
                  组织架构类型 ,
                  总货值金额 ,
                  总货值面积 ,
                  已售货量金额 ,
                  已售货量面积 ,
                  总货值金额操盘项目 ,
                  总货值面积操盘项目 ,
                  已售货量金额操盘项目 ,
                  已售货量面积操盘项目 ,
                  剩余货值金额 ,
                  剩余货值面积 ,
                  剩余可售货值金额 ,
                  剩余可售货值面积 ,
                  --本月情况
                  工程达到可售未拿证货值金额 ,
                  工程达到可售未拿证货值面积 ,
                  获证未推货值金额 ,
                  获证未推货值面积 ,
                  已推未售货值金额 ,
                  已推未售货值面积 ,
                  --操盘项目
                  剩余货值金额操盘项目 ,
                  剩余货值面积操盘项目 ,
                  剩余可售货值金额操盘项目 ,
                  剩余可售货值面积操盘项目 ,
                  工程达到可售未拿证货值金额操盘项目 ,
                  工程达到可售未拿证货值面积操盘项目 ,
                  获证未推货值金额操盘项目 ,
                  获证未推货值面积操盘项目 ,
                  已推未售货值金额操盘项目 ,
                  已推未售货值面积操盘项目 ,
				  --年初可售情况
                  年初工程达到可售未拿证货值金额 ,
                  年初工程达到可售未拿证货值面积 ,
                  年初获证未推货值金额 ,
                  年初获证未推货值面积 ,
                  年初已推未售货值金额 ,
                  年初已推未售货值面积 ,
                  本月新货货量 ,
                  本月新货面积 ,
                  本年存货货量 ,
                  本年存货面积 ,
                  后续预计达成货量金额 ,
                  后续预计达成货量面积 ,
                  今年后续预计达成货量金额 ,
                  今年后续预计达成货量面积 ,
                  本年可售货量金额 ,
                  本年可售货量面积 ,
                  本年剩余可售货量金额 ,
                  本年剩余可售货量面积 ,
				  当前剩余可售货量金额 ,
                  当前剩余可售货量面积 ,
                  本年已售货量金额 ,
                  本年已售货量面积 ,
                  Jan预计货量金额 ,
                  Jan实际货量金额 ,
                  Jan货量达成率 ,
                  Feb预计货量金额 ,
                  Feb实际货量金额 ,
                  Feb货量达成率 ,
                  Mar预计货量金额 ,
                  Mar实际货量金额 ,
                  Mar货量达成率 ,
                  Apr预计货量金额 ,
                  Apr实际货量金额 ,
                  Apr货量达成率 ,
                  May预计货量金额 ,
                  May实际货量金额 ,
                  May货量达成率 ,
                  Jun预计货量金额 ,
                  Jun实际货量金额 ,
                  Jun货量达成率 ,
                  July预计货量金额 ,
                  July实际货量金额 ,
                  July货量达成率 ,
                  Aug预计货量金额 ,
                  Aug实际货量金额 ,
                  Aug货量达成率 ,
                  Sep预计货量金额 ,
                  Sep实际货量金额 ,
                  Sep货量达成率 ,
                  Oct预计货量金额 ,
                  Oct实际货量金额 ,
                  Oct货量达成率 ,
                  Nov预计货量金额 ,
                  Nov实际货量金额 ,
                  Nov货量达成率 ,
                  Dec预计货量金额 ,
                  Dec实际货量金额 ,
                  Dec货量达成率 ,
                  本月预计货量金额 ,
                  本月实际货量金额 ,
                  本月货量达成率 ,
                  本年预计货量金额 ,
                  本年实际货量金额 ,
                  本年货量达成率 ,

        --1-2月份
                  Jan可售货值金额 ,
                  Jan可售货值面积 ,
                  Jan新推货值金额 ,
                  Jan新推货值面积 ,
                  Feb可售货值金额 ,
                  Feb可售货值面积 ,
                  Feb新推货值金额 ,
                  Feb新推货值面积 ,
                  JanFeb可售货值金额 ,
                  JanFeb可售货值面积 ,
                  JanFeb新推货值金额 ,
                  JanFeb新推货值面积 ,
        --3月份
                  Mar可售货值金额 ,
                  Mar可售货值面积 ,
                  Mar新推货值金额 ,
                  Mar新推货值面积 ,

        --4月份
                  Apr可售货值金额 ,
                  Apr可售货值面积 ,
                  Apr新推货值金额 ,
                  Apr新推货值面积 ,

        --5月份
                  May可售货值金额 ,
                  May可售货值面积 ,
                  May新推货值金额 ,
                  May新推货值面积 ,

        --6月份
                  Jun可售货值金额 ,
                  Jun可售货值面积 ,
                  Jun新推货值金额 ,
                  Jun新推货值面积 ,

        --7月份
                  July可售货值金额 ,
                  July可售货值面积 ,
                  July新推货值金额 ,
                  July新推货值面积 ,

        --8月份
                  Aug可售货值金额 ,
                  Aug可售货值面积 ,
                  Aug新推货值金额 ,
                  Aug新推货值面积 ,

        --9月份
                  Sep可售货值金额 ,
                  Sep可售货值面积 ,
                  Sep新推货值金额 ,
                  Sep新推货值面积 ,

        --10月份
                  Oct可售货值金额 ,
                  Oct可售货值面积 ,
                  Oct新推货值金额 ,
                  Oct新推货值面积 ,

        --11月份
                  Nov可售货值金额 ,
                  Nov可售货值面积 ,
                  Nov新推货值金额 ,
                  Nov新推货值面积 ,

        --12月份
                  Dec可售货值金额 ,
                  Dec可售货值面积 ,
                  Dec新推货值金额 ,
                  Dec新推货值面积 ,

        --下一年
        --1-2月份
                  NextJan可售货值金额 ,
                  NextJan可售货值面积 ,
                  NextJan新推货值金额 ,
                  NextJan新推货值面积 ,
                  NextFeb可售货值金额 ,
                  NextFeb可售货值面积 ,
                  NextFeb新推货值金额 ,
                  NextFeb新推货值面积 ,
                  NextJanFeb可售货值金额 ,
                  NextJanFeb可售货值面积 ,
                  NextJanFeb新推货值金额 ,
                  NextJanFeb新推货值面积 ,
        --3月份
                  NextMar可售货值金额 ,
                  NextMar可售货值面积 ,
                  NextMar新推货值金额 ,
                  NextMar新推货值面积 ,

        --4月份
                  NextApr可售货值金额 ,
                  NextApr可售货值面积 ,
                  NextApr新推货值金额 ,
                  NextApr新推货值面积 ,

        --5月份
                  NextMay可售货值金额 ,
                  NextMay可售货值面积 ,
                  NextMay新推货值金额 ,
                  NextMay新推货值面积 ,

        --6月份
                  NextJun可售货值金额 ,
                  NextJun可售货值面积 ,
                  NextJun新推货值金额 ,
                  NextJun新推货值面积 ,

        --7月份
                  NextJuly可售货值金额 ,
                  NextJuly可售货值面积 ,
                  NextJuly新推货值金额 ,
                  NextJuly新推货值面积 ,

        --8月份
                  NextAug可售货值金额 ,
                  NextAug可售货值面积 ,
                  NextAug新推货值金额 ,
                  NextAug新推货值面积 ,

        --9月份
                  NextSep可售货值金额 ,
                  NextSep可售货值面积 ,
                  NextSep新推货值金额 ,
                  NextSep新推货值面积 ,

        --10月份
                  NextOct可售货值金额 ,
                  NextOct可售货值面积 ,
                  NextOct新推货值金额 ,
                  NextOct新推货值面积 ,

        --11月份
                  NextNov可售货值金额 ,
                  NextNov可售货值面积 ,
                  NextNov新推货值金额 ,
                  NextNov新推货值面积 ,

        --12月份
                  NextDec可售货值金额 ,
                  NextDec可售货值面积 ,
                  NextDec新推货值金额 ,
                  NextDec新推货值面积 ,
                  滞后货量金额 ,
                  滞后货量面积 ,
                  存货预计去化周期 ,
                  预计达到预售形象日期 ,
                  实际达到预售形象日期 ,
                  预计预售办理日期 ,
                  实际预售办理日期 ,
                  预计售价 ,
                  今年车位可售金额
                )
                SELECT  bi.组织架构ID ,
                        bi.组织架构名称 ,
                        bi.组织架构编码 ,
                        bi.组织架构类型 ,
                        SUM(ISNULL(phz.总货值金额, 0) + ISNULL(phz2.总货值金额, 0)) ,
                        SUM(ISNULL(phz.总货值面积, 0) + ISNULL(phz2.总货值面积, 0)) ,
                        SUM(ISNULL(phz.已售货量金额, 0) + ISNULL(phz2.已售货量金额, 0)) ,
                        SUM(ISNULL(phz.已售货量面积, 0) + ISNULL(phz2.已售货量面积, 0)) ,

			   --操盘项目
                        SUM(ISNULL(phz.总货值操盘金额, 0) + ISNULL(phz2.总货值操盘金额, 0)) AS 总货值金额操盘项目 ,
                        SUM(ISNULL(phz.总货值操盘金额, 0) + ISNULL(phz2.总货值操盘金额, 0)) AS 总货值面积操盘项目 ,
                        SUM(ISNULL(phz.已售货量操盘金额, 0) + ISNULL(phz2.已售货量操盘金额, 0)) AS 已售货量金额操盘项目 ,
                        SUM(ISNULL(phz.已售货量操盘面积, 0) + ISNULL(phz2.已售货量操盘面积, 0)) AS 已售货量面积操盘项目 ,
                        SUM(ISNULL(phz.未销售部分操盘货量, 0) + ISNULL(phz2.未销售部分操盘货量, 0)) ,
                        SUM(ISNULL(phz.未销售部分可售操盘面积, 0) + ISNULL(phz2.未销售部分可售操盘面积,
                                                              0)) ,
                        SUM(ISNULL(phz.剩余可售货值金额, 0) + ISNULL(phz2.剩余可售货值金额, 0)) ,
                        SUM(ISNULL(phz.剩余可售货值面积, 0) + ISNULL(phz2.剩余可售货值面积, 0)) , 
                        SUM(ISNULL(phz.工程达到可售未拿证货值金额, 0)
                            + ISNULL(phz2.工程达到可售未拿证货值金额, 0)) ,
                        SUM(ISNULL(phz.工程达到可售未拿证货值面积, 0)
                            + ISNULL(phz2.工程达到可售未拿证货值面积, 0)) ,
                        SUM(ISNULL(phz.获证未推货值金额, 0) + ISNULL(phz2.获证未推货值金额, 0)) ,
                        SUM(ISNULL(phz.获证未推货值面积, 0) + ISNULL(phz2.获证未推货值金额, 0)) ,
                        SUM(ISNULL(phz.已推未售货值金额, 0) + ISNULL(phz2.已推未售货值金额, 0)) ,
                        SUM(ISNULL(phz.已推未售货值面积, 0) + ISNULL(phz2.已推未售货值面积, 0)) ,

			   --操盘项目
                        SUM(ISNULL(phz.未销售部分操盘货量, 0) + ISNULL(phz2.剩余可售货值操盘金额, 0)) AS 剩余货值金额操盘项目 ,
                        SUM(ISNULL(phz.未销售部分可售操盘面积, 0) + ISNULL(phz2.未销售部分可售操盘面积, 0)) AS 剩余货值面积操盘项目 ,
                        SUM(ISNULL(phz.剩余可售货值操盘金额, 0) + ISNULL(phz2.剩余可售货值操盘金额, 0)) AS 剩余可售货值金额操盘项目 ,
                        SUM(ISNULL(phz.剩余可售货值操盘面积, 0) + ISNULL(phz2.剩余可售货值操盘面积, 0)) AS 剩余可售货值面积操盘项目 ,
                        SUM(ISNULL(phz.工程达到可售未拿证货值操盘金额, 0)) AS 工程达到可售未拿证货值金额操盘项目 ,
                        SUM(ISNULL(phz.工程达到可售未拿证货值操盘面积, 0)) AS 工程达到可售未拿证货值面积操盘项目 ,
                        SUM(ISNULL(phz.获证未推货值操盘金额, 0)) AS 获证未推货值金额操盘项目 ,
                        SUM(ISNULL(phz.获证未推货值操盘面积, 0)) AS 获证未推货值面积操盘项目 ,
                        SUM(ISNULL(phz.已推未售货值操盘金额, 0)) AS 已推未售货值金额操盘项目 ,
                        SUM(ISNULL(phz.已推未售货值操盘面积, 0)) AS 已推未售货值面积操盘项目 ,

						 --年初情况
                        SUM(ISNULL(phz.年初工程达到可售未拿证货值金额, 0)
                            + ISNULL(phz2.年初工程达到可售未拿证货值金额, 0)) ,
                        SUM(ISNULL(phz.年初工程达到可售未拿证货值面积, 0)
                            + ISNULL(phz2.年初工程达到可售未拿证货值面积, 0)) ,
                        SUM(ISNULL(phz.年初获证未推货值金额, 0) + ISNULL(phz2.年初获证未推货值金额,
                                                              0)) ,
                        SUM(ISNULL(phz.年初获证未推货值面积, 0) + ISNULL(phz2.年初获证未推货值面积,
                                                              0)) ,
                        SUM(ISNULL(phz.年初已推未售货值金额, 0) + ISNULL(phz2.年初已推未售货值金额,
                                                              0)) ,
                        SUM(ISNULL(phz.年初已推未售货值面积, 0) + ISNULL(phz2.年初已推未售货值面积,
                                                              0)) ,
                        SUM(ISNULL(phzyc1.本月新货货量, 0))
                        + SUM(ISNULL(phzyc2.本月新货货量, 0)) AS 本月新货货量 ,
                        SUM(ISNULL(phzyc1.本月新货面积, 0))
                        + SUM(ISNULL(phzyc2.本月新货面积, 0)) AS 本月新货面积 ,
                        SUM(ISNULL(phzyc1.本年存货货量, 0))
                        + SUM(ISNULL(phzyc2.本年存货货量, 0)) AS 本年存货货量 ,
                        SUM(ISNULL(phzyc1.本年存货面积, 0))
                        + SUM(ISNULL(phzyc2.本年存货面积, 0)) AS 本年存货面积 ,
                        SUM(ISNULL(phz.后续预计达成货量金额, 0) + ISNULL(phz2.后续预计达成货量金额,
                                                              0)) AS 后续预计达成货量金额 ,
                        SUM(ISNULL(phz.后续预计达成货量面积, 0) + ISNULL(phz2.后续预计达成货量金额,
                                                              0)) AS 后续预计达成货量面积 ,
                        SUM(ISNULL(phz.今年后续预计达成货量金额, 0)) AS 今年后续预计达成货量金额 ,
                        SUM(ISNULL(phz.今年后续预计达成货量面积, 0)) AS 今年后续预计达成货量面积 ,
                        SUM( --年初
                            ISNULL(phz.年初工程达到可售未拿证货值金额, 0)
                            + ISNULL(phz2.年初工程达到可售未拿证货值金额, 0)
                            + ISNULL(phz.年初获证未推货值金额, 0)
                            + ISNULL(phz2.年初获证未推货值金额, 0)
                            + ISNULL(phz.年初已推未售货值金额, 0)
                            + ISNULL(phz2.年初已推未售货值金额, 0) + --本年新推
					  ISNULL(phzyc1.[1月新增可售金额], 0) + ISNULL(phzyc1.[2月新增可售金额],
                                                            0)
                            + ISNULL(phzyc1.[3月新增可售金额], 0)
                            + ISNULL(phzyc1.[4月新增可售金额], 0)
                            + ISNULL(phzyc1.[5月新增可售金额], 0)
                            + ISNULL(phzyc1.[6月新增可售金额], 0)
                            + ISNULL(phzyc1.[7月新增可售金额], 0)
                            + ISNULL(phzyc1.[8月新增可售金额], 0)
                            + ISNULL(phzyc1.[9月新增可售金额], 0)
                            + ISNULL(phzyc1.[10月新增可售金额], 0)
                            + ISNULL(phzyc1.[11月新增可售金额], 0)
                            + ISNULL(phzyc1.[12月新增可售金额], 0)
                            + ISNULL(phzyc2.[1月新增可售金额], 0)
                            + ISNULL(phzyc2.[2月新增可售金额], 0)
                            + ISNULL(phzyc2.[3月新增可售金额], 0)
                            + ISNULL(phzyc2.[4月新增可售金额], 0)
                            + ISNULL(phzyc2.[5月新增可售金额], 0)
                            + ISNULL(phzyc2.[6月新增可售金额], 0)
                            + ISNULL(phzyc2.[7月新增可售金额], 0)
                            + ISNULL(phzyc2.[8月新增可售金额], 0)
                            + ISNULL(phzyc2.[9月新增可售金额], 0)
                            + ISNULL(phzyc2.[10月新增可售金额], 0)
                            + ISNULL(phzyc2.[11月新增可售金额], 0)
                            + ISNULL(phzyc2.[12月新增可售金额], 0)) AS 本年可售货量金额 ,
                        SUM(ISNULL(phz.年初工程达到可售未拿证货值面积, 0)
                            + ISNULL(phz2.年初工程达到可售未拿证货值面积, 0)
                            + ISNULL(phz.年初获证未推货值面积, 0)
                            + ISNULL(phz2.年初获证未推货值面积, 0)
                            + ISNULL(phz.年初已推未售货值面积, 0)
                            + ISNULL(phz2.年初已推未售货值面积, 0) + --新推
					  ISNULL(phzyc1.[1月新增可售面积], 0) + ISNULL(phzyc1.[2月新增可售面积],
                                                            0)
                            + ISNULL(phzyc1.[3月新增可售面积], 0)
                            + ISNULL(phzyc1.[4月新增可售面积], 0)
                            + ISNULL(phzyc1.[5月新增可售面积], 0)
                            + ISNULL(phzyc1.[6月新增可售面积], 0)
                            + ISNULL(phzyc1.[7月新增可售面积], 0)
                            + ISNULL(phzyc1.[8月新增可售面积], 0)
                            + ISNULL(phzyc1.[9月新增可售面积], 0)
                            + ISNULL(phzyc1.[10月新增可售面积], 0)
                            + ISNULL(phzyc1.[11月新增可售面积], 0)
                            + ISNULL(phzyc1.[12月新增可售面积], 0)
                            + ISNULL(phzyc2.[1月新增可售面积], 0)
                            + ISNULL(phzyc2.[2月新增可售面积], 0)
                            + ISNULL(phzyc2.[3月新增可售面积], 0)
                            + ISNULL(phzyc2.[4月新增可售面积], 0)
                            + ISNULL(phzyc2.[5月新增可售面积], 0)
                            + ISNULL(phzyc2.[6月新增可售面积], 0)
                            + ISNULL(phzyc2.[7月新增可售面积], 0)
                            + ISNULL(phzyc2.[8月新增可售面积], 0)
                            + ISNULL(phzyc2.[9月新增可售面积], 0)
                            + ISNULL(phzyc2.[10月新增可售面积], 0)
                            + ISNULL(phzyc2.[11月新增可售面积], 0)
                            + ISNULL(phzyc2.[12月新增可售面积], 0)) AS 本年可售货量面积 ,
                        SUM(ISNULL(phz.本年剩余可售货量金额, 0) + ISNULL(phz2.本年剩余可售货量金额,
                                                              0)) AS 本年剩余可售货量金额 ,
                        SUM(ISNULL(phz.本年剩余可售货量面积, 0) + ISNULL(phz2.本年剩余可售货量面积,
                                                              0)) AS 本年剩余可售货量面积 ,
						SUM(ISNULL(phz.当前剩余可售货量金额, 0) + ISNULL(phz2.当前剩余可售货量金额,
                                                              0)) AS 当前剩余可售货量金额 ,
                        SUM(ISNULL(phz.当前剩余可售货量面积, 0) + ISNULL(phz2.当前剩余可售货量面积,
                                                              0)) AS 当前剩余可售货量面积 ,
                        SUM(ISNULL(phz.本年已售货量金额, 0) + ISNULL(phz2.本年已售货量金额, 0)) AS 本年已售货量金额 ,
                        SUM(ISNULL(phz.本年已售货量面积, 0) + ISNULL(phz2.本年已售货量面积, 0)) AS 本年已售货量面积 ,

			   --货量计划
                        SUM(ISNULL(phz.Jan预计货量金额, 0)) AS Jan预计货量金额 ,
                        SUM(ISNULL(phz.Jan实际货量金额, 0)) AS Jan实际货量金额 ,
                        CASE WHEN SUM(ISNULL(phz.Jan预计货量金额, 0)) = 0 THEN 0
                             ELSE SUM(ISNULL(phz.Jan实际货量金额, 0))
                                  / SUM(ISNULL(phz.Jan预计货量金额, 0)) * 1.00
                        END AS Jan货量达成率 ,
                        SUM(ISNULL(phz.Feb预计货量金额, 0)) AS Feb预计货量金额 ,
                        SUM(ISNULL(phz.Feb实际货量金额, 0)) AS Feb实际货量金额 ,
                        CASE WHEN SUM(ISNULL(phz.Feb预计货量金额, 0)) = 0 THEN 0
                             ELSE SUM(ISNULL(phz.Feb实际货量金额, 0))
                                  / SUM(ISNULL(phz.Feb预计货量金额, 0)) * 1.00
                        END AS Feb货量达成率 ,
                        SUM(ISNULL(phz.Mar预计货量金额, 0)) AS Mar预计货量金额 ,
                        SUM(ISNULL(phz.Mar实际货量金额, 0)) AS Mar实际货量金额 ,
                        CASE WHEN SUM(ISNULL(phz.Mar预计货量金额, 0)) = 0 THEN 0
                             ELSE SUM(ISNULL(phz.Mar实际货量金额, 0))
                                  / SUM(ISNULL(phz.Mar预计货量金额, 0)) * 1.00
                        END AS Mar货量达成率 ,
                        SUM(ISNULL(phz.Apr预计货量金额, 0)) AS Apr预计货量金额 ,
                        SUM(ISNULL(phz.Apr实际货量金额, 0)) AS Apr实际货量金额 ,
                        CASE WHEN SUM(ISNULL(phz.Apr预计货量金额, 0)) = 0 THEN 0
                             ELSE SUM(ISNULL(phz.Apr实际货量金额, 0))
                                  / SUM(ISNULL(phz.Apr预计货量金额, 0)) * 1.00
                        END AS Apr货量达成率 ,
                        SUM(ISNULL(phz.May预计货量金额, 0)) AS May预计货量金额 ,
                        SUM(ISNULL(phz.May实际货量金额, 0)) AS May实际货量金额 ,
                        CASE WHEN SUM(ISNULL(phz.May预计货量金额, 0)) = 0 THEN 0
                             ELSE SUM(ISNULL(phz.May实际货量金额, 0))
                                  / SUM(ISNULL(phz.May预计货量金额, 0)) * 1.00
                        END AS May货量达成率 ,
                        SUM(ISNULL(phz.Jun预计货量金额, 0)) AS Jun预计货量金额 ,
                        SUM(ISNULL(phz.Jun实际货量金额, 0)) AS Jun实际货量金额 ,
                        CASE WHEN SUM(ISNULL(phz.Jun预计货量金额, 0)) = 0 THEN 0
                             ELSE SUM(ISNULL(phz.Jun实际货量金额, 0))
                                  / SUM(ISNULL(phz.Jun预计货量金额, 0)) * 1.00
                        END AS Jun货量达成率 ,
                        SUM(ISNULL(phz.July预计货量金额, 0)) AS July预计货量金额 ,
                        SUM(ISNULL(phz.July实际货量金额, 0)) AS July实际货量金额 ,
                        CASE WHEN SUM(ISNULL(phz.July预计货量金额, 0)) = 0 THEN 0
                             ELSE SUM(ISNULL(phz.July实际货量金额, 0))
                                  / SUM(ISNULL(phz.July预计货量金额, 0)) * 1.00
                        END AS July货量达成率 ,
                        SUM(ISNULL(phz.Aug预计货量金额, 0)) AS Aug预计货量金额 ,
                        SUM(ISNULL(phz.Aug实际货量金额, 0)) AS Aug实际货量金额 ,
                        CASE WHEN SUM(ISNULL(phz.Aug预计货量金额, 0)) = 0 THEN 0
                             ELSE SUM(ISNULL(phz.Aug实际货量金额, 0))
                                  / SUM(ISNULL(phz.Aug预计货量金额, 0)) * 1.00
                        END AS Aug货量达成率 ,
                        SUM(ISNULL(phz.Sep预计货量金额, 0)) AS Sep预计货量金额 ,
                        SUM(ISNULL(phz.Sep实际货量金额, 0)) AS Sep实际货量金额 ,
                        CASE WHEN SUM(ISNULL(phz.Sep预计货量金额, 0)) = 0 THEN 0
                             ELSE SUM(ISNULL(phz.Sep实际货量金额, 0))
                                  / SUM(ISNULL(phz.Sep预计货量金额, 0)) * 1.00
                        END AS Sep货量达成率 ,
                        SUM(ISNULL(phz.Oct预计货量金额, 0)) AS Oct预计货量金额 ,
                        SUM(ISNULL(phz.Oct实际货量金额, 0)) AS Oct实际货量金额 ,
                        CASE WHEN SUM(ISNULL(phz.Oct预计货量金额, 0)) = 0 THEN 0
                             ELSE SUM(ISNULL(phz.Oct实际货量金额, 0))
                                  / SUM(ISNULL(phz.Oct预计货量金额, 0)) * 1.00
                        END AS Oct货量达成率 ,
                        SUM(ISNULL(phz.Nov预计货量金额, 0)) AS Nov预计货量金额 ,
                        SUM(ISNULL(phz.Nov实际货量金额, 0)) AS Nov实际货量金额 ,
                        CASE WHEN SUM(ISNULL(phz.Nov预计货量金额, 0)) = 0 THEN 0
                             ELSE SUM(ISNULL(phz.Nov实际货量金额, 0))
                                  / SUM(ISNULL(phz.Nov预计货量金额, 0)) * 1.00
                        END AS Nov货量达成率 ,
                        SUM(ISNULL(phz.Dec预计货量金额, 0)) AS Dec预计货量金额 ,
                        SUM(ISNULL(phz.Dec实际货量金额, 0)) AS Dec实际货量金额 ,
                        CASE WHEN SUM(ISNULL(phz.Dec预计货量金额, 0)) = 0 THEN 0
                             ELSE SUM(ISNULL(phz.Dec实际货量金额, 0))
                                  / SUM(ISNULL(phz.Dec预计货量金额, 0)) * 1.00
                        END AS Dec货量达成率 ,
                        SUM(ISNULL(phz.本月预计货量金额, 0)) AS 本月预计货量金额 ,
                        SUM(ISNULL(phz.本月实际货量金额, 0)) AS 本月实际货量金额 ,
                        CASE WHEN SUM(ISNULL(phz.本月预计货量金额, 0)) = 0 THEN 0
                             ELSE SUM(ISNULL(phz.本月实际货量金额, 0))
                                  / SUM(ISNULL(phz.本月预计货量金额, 0)) * 1.00
                        END AS 本月货量达成率 ,
                        SUM(ISNULL(phz.本年预计货量金额, 0)) AS 本年预计货量金额 ,
                        SUM(ISNULL(phz.本年实际货量金额, 0)) AS 本年实际货量金额 ,
                        CASE WHEN SUM(ISNULL(phz.本年预计货量金额, 0)) = 0 THEN 0
                             ELSE SUM(ISNULL(phz.本年实际货量金额, 0))
                                  / SUM(ISNULL(phz.本年预计货量金额, 0)) * 1.00
                        END AS 本年货量达成率 ,
                        SUM(ISNULL(phzyc1.[1月总可售金额], 0)
                            + ISNULL(phzyc2.[1月总可售金额], 0)) AS Jan可售货值金额 ,
                        SUM(ISNULL(phzyc1.[1月总可售面积], 0)
                            + ISNULL(phzyc2.[1月总可售面积], 0)) AS Jan可售货值面积 ,
                        SUM(ISNULL(phzyc1.[1月新增可售金额], 0)
                            + ISNULL(phzyc2.[1月新增可售金额], 0)) AS Jan新推货值金额 ,
                        SUM(ISNULL(phzyc1.[1月新增可售面积], 0)
                            + ISNULL(phzyc2.[1月新增可售面积], 0)) AS Jan新推货值面积 ,
                        SUM(ISNULL(phzyc1.[2月总可售金额], 0)
                            + ISNULL(phzyc2.[2月总可售金额], 0)) AS Feb可售货值金额 ,
                        SUM(ISNULL(phzyc1.[2月总可售面积], 0)
                            + ISNULL(phzyc2.[2月总可售面积], 0)) AS Feb可售货值面积 ,
                        SUM(ISNULL(phzyc1.[2月新增可售金额], 0)
                            + ISNULL(phzyc2.[2月新增可售金额], 0)) AS Feb新推货值金额 ,
                        SUM(ISNULL(phzyc1.[2月新增可售面积], 0)
                            + ISNULL(phzyc2.[2月新增可售面积], 0)) AS Feb新推货值面积 ,
                        SUM(ISNULL(phzyc1.[1月总可售金额], 0)
                            + ISNULL(phzyc1.[2月总可售金额], 0)
                            + ISNULL(phzyc2.[1月总可售金额], 0)
                            + ISNULL(phzyc2.[2月总可售金额], 0)) AS JanFeb可售货值金额 ,
                        SUM(ISNULL(phzyc1.[1月总可售面积], 0)
                            + ISNULL(phzyc1.[2月总可售面积], 0)
                            + ISNULL(phzyc2.[1月总可售面积], 0)
                            + ISNULL(phzyc2.[2月总可售面积], 0)) AS JanFeb可售货值面积 ,
                        SUM(ISNULL(phzyc1.[1月新增可售金额], 0)
                            + ISNULL(phzyc1.[2月新增可售金额], 0)
                            + ISNULL(phzyc2.[1月新增可售金额], 0)
                            + ISNULL(phzyc2.[2月新增可售金额], 0)) AS JanFeb新推货值金额 ,
                        SUM(ISNULL(phzyc1.[1月新增可售面积], 0)
                            + ISNULL(phzyc1.[2月新增可售面积], 0)
                            + ISNULL(phzyc2.[1月新增可售面积], 0)
                            + ISNULL(phzyc2.[2月新增可售面积], 0)) AS JanFeb新推货值面积 ,
                        SUM(ISNULL(phzyc1.[3月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[3月总可售金额], 0)) AS Mar可售货值金额 ,
                        SUM(ISNULL(phzyc1.[3月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[3月总可售面积], 0)) AS Mar可售货值面积 ,
                        SUM(ISNULL(phzyc1.[3月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[3月新增可售金额], 0)) AS Mar新推货值金额 ,
                        SUM(ISNULL(phzyc1.[3月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[3月新增可售面积], 0)) AS Mar新推货值面积 ,
                        SUM(ISNULL(phzyc1.[4月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[4月总可售金额], 0)) AS Apr可售货值金额 ,
                        SUM(ISNULL(phzyc1.[4月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[4月总可售面积], 0)) AS Apr可售货值面积 ,
                        SUM(ISNULL(phzyc1.[4月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[4月新增可售金额], 0)) AS Apr新推货值金额 ,
                        SUM(ISNULL(phzyc1.[4月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[4月新增可售面积], 0)) AS Apr新推货值面积 ,
                        SUM(ISNULL(phzyc1.[5月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[5月总可售金额], 0)) AS May可售货值金额 ,
                        SUM(ISNULL(phzyc1.[5月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[5月总可售面积], 0)) AS May可售货值面积 ,
                        SUM(ISNULL(phzyc1.[5月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[5月新增可售金额], 0)) AS May新推货值金额 ,
                        SUM(ISNULL(phzyc1.[5月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[5月新增可售面积], 0)) AS May新推货值面积 ,
                        SUM(ISNULL(phzyc1.[6月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[6月总可售金额], 0)) AS Jun可售货值金额 ,
                        SUM(ISNULL(phzyc1.[6月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[6月总可售面积], 0)) AS Jun可售货值面积 ,
                        SUM(ISNULL(phzyc1.[6月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[6月新增可售金额], 0)) AS Jun新推货值金额 ,
                        SUM(ISNULL(phzyc1.[6月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[6月新增可售面积], 0)) AS Jun新推货值面积 ,
                        SUM(ISNULL(phzyc1.[7月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[7月总可售金额], 0)) AS July可售货值金额 ,
                        SUM(ISNULL(phzyc1.[7月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[7月总可售面积], 0)) AS July可售货值面积 ,
                        SUM(ISNULL(phzyc1.[7月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[7月新增可售金额], 0)) AS July新推货值金额 ,
                        SUM(ISNULL(phzyc1.[7月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[7月新增可售面积], 0)) AS July新推货值面积 ,
                        SUM(ISNULL(phzyc1.[8月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[8月总可售金额], 0)) AS Aug可售货值金额 ,
                        SUM(ISNULL(phzyc1.[8月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[8月总可售面积], 0)) AS Aug可售货值面积 ,
                        SUM(ISNULL(phzyc1.[8月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[8月新增可售金额], 0)) AS Aug新推货值金额 ,
                        SUM(ISNULL(phzyc1.[8月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[8月新增可售面积], 0)) AS Aug新推货值面积 ,
                        SUM(ISNULL(phzyc1.[9月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[9月总可售金额], 0)) AS Sep可售货值金额 ,
                        SUM(ISNULL(phzyc1.[9月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[9月总可售面积], 0)) AS Sep可售货值面积 ,
                        SUM(ISNULL(phzyc1.[9月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[9月新增可售金额], 0)) AS Sep新推货值金额 ,
                        SUM(ISNULL(phzyc1.[9月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[9月新增可售面积], 0)) AS Sep新推货值面积 ,
                        SUM(ISNULL(phzyc1.[10月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[10月总可售金额], 0)) AS Oct可售货值金额 ,
                        SUM(ISNULL(phzyc1.[10月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[10月总可售面积], 0)) AS Oct可售货值面积 ,
                        SUM(ISNULL(phzyc1.[10月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[10月新增可售金额], 0)) AS Oct新推货值金额 ,
                        SUM(ISNULL(phzyc1.[10月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[10月新增可售面积], 0)) AS Oct新推货值面积 ,
                        SUM(ISNULL(phzyc1.[11月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[11月总可售金额], 0)) AS Nov可售货值金额 ,
                        SUM(ISNULL(phzyc1.[11月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[11月总可售面积], 0)) AS Nov可售货值面积 ,
                        SUM(ISNULL(phzyc1.[11月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[11月新增可售金额], 0)) AS Nov新推货值金额 ,
                        SUM(ISNULL(phzyc1.[11月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[11月新增可售面积], 0)) AS Nov新推货值面积 ,
                        SUM(ISNULL(phzyc1.[12月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[12月总可售金额], 0)) AS Dec可售货值金额 ,
                        SUM(ISNULL(phzyc1.[12月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[12月总可售面积], 0)) AS Dec可售货值面积 ,
                        SUM(ISNULL(phzyc1.[12月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[12月新增可售金额], 0)) AS Dec新推货值金额 ,
                        SUM(ISNULL(phzyc1.[12月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[12月新增可售面积], 0)) AS Dec新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next1月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next1月总可售金额], 0)) AS NextJan可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next1月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next1月总可售面积], 0)) AS NextJan可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next1月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next1月新增可售金额], 0)) AS NextJan新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next1月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next1月新增可售面积], 0)) AS NextJan新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next2月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next2月总可售金额], 0)) AS NextFeb可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next2月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next2月总可售面积], 0)) AS NextFeb可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next2月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next2月新增可售金额], 0)) AS NextFeb新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next2月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next2月新增可售面积], 0)) AS NextFeb新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next1月总可售金额], 0))
                        + SUM(ISNULL(phzyc1.[Next2月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next1月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next2月总可售金额], 0)) AS NextJanFeb可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next1月总可售面积], 0))
                        + SUM(ISNULL(phzyc1.[Next2月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next1月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next2月总可售面积], 0)) AS NextJanFeb可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next1月新增可售金额], 0))
                        + SUM(ISNULL(phzyc1.[Next2月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next1月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next2月新增可售金额], 0)) AS NextJanFeb新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next1月新增可售面积], 0))
                        + SUM(ISNULL(phzyc1.[Next2月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next1月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next2月新增可售面积], 0)) AS NextJanFeb新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next3月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next3月总可售金额], 0)) AS NextMar可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next3月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next3月总可售面积], 0)) AS NextMar可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next3月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next3月新增可售金额], 0)) AS NextMar新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next3月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next3月新增可售面积], 0)) AS NextMar新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next4月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next4月总可售金额], 0)) AS NextApr可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next4月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next4月总可售面积], 0)) AS NextApr可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next4月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next4月新增可售金额], 0)) AS NextApr新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next4月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next4月新增可售面积], 0)) AS NextApr新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next5月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next5月总可售金额], 0)) AS NextMay可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next5月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next5月总可售面积], 0)) AS NextMay可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next5月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next5月新增可售金额], 0)) AS NextMay新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next5月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next5月新增可售面积], 0)) AS NextMay新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next6月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next6月总可售金额], 0)) AS NextJun可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next6月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next6月总可售面积], 0)) AS NextJun可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next6月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next6月新增可售金额], 0)) AS NextJun新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next6月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next6月新增可售金额], 0)) AS NextJun新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next7月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next7月总可售金额], 0)) AS NextJuly可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next7月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next7月总可售面积], 0)) AS NextJuly可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next7月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next7月新增可售金额], 0)) AS NextJuly新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next7月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next7月新增可售面积], 0)) AS NextJuly新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next8月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next8月总可售金额], 0)) AS NextAug可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next8月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next8月总可售面积], 0)) AS NextAug可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next8月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next8月新增可售金额], 0)) AS NextAug新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next8月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next8月新增可售面积], 0)) AS NextAug新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next9月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next9月总可售金额], 0)) AS NextSep可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next9月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next9月总可售面积], 0)) AS NextSep可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next9月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next9月新增可售金额], 0)) AS NextSep新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next9月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next9月新增可售面积], 0)) AS NextSep新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next10月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next10月总可售金额], 0)) AS NextOct可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next10月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next10月总可售面积], 0)) AS NextOct可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next10月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next10月新增可售金额], 0)) AS NextOct新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next10月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next10月新增可售面积], 0)) AS NextOct新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next11月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next11月总可售金额], 0)) AS NextNov可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next11月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next11月总可售面积], 0)) AS NextNov可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next11月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next11月新增可售金额], 0)) AS NextNov新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next11月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next11月新增可售面积], 0)) AS NextNov新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next12月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next12月总可售金额], 0)) AS NextDec可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next12月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next12月总可售面积], 0)) AS NextDec可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next12月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next12月新增可售金额], 0)) AS NextDec新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next12月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next12月新增可售面积], 0)) AS NextDec新推货值面积 ,
                        SUM(ISNULL(phz.滞后货量金额, 0)) AS 滞后货量金额 ,
                        SUM(ISNULL(phz.滞后货量面积, 0)) AS 滞后货量面积 ,
                        0 AS 存货预计去化周期 ,
                        NULL 预计达到预售形象日期 ,
                        NULL 实际达到预售形象日期 ,
                        NULL 预计预售办理日期 ,
                        NULL 实际预售办理日期 ,
                        0 AS 预计售价 ,
                        SUM(phz.今年车位可售金额)
                FROM    erp25.dbo.ydkb_BaseInfo bi
                        LEFT JOIN ( SELECT  组织架构ID ,
                                            SUM(总货值金额) 总货值金额 ,
                                            SUM(总货值面积) 总货值面积 ,
                                            SUM(已售货量金额) 已售货量金额 ,
                                            SUM(已售货量面积) 已售货量面积 , 
                                            SUM(未销售部分货量) 未销售部分货量 ,
                                            SUM(未销售部分可售面积) 未销售部分可售面积 ,
											SUM(总货值操盘金额) 总货值操盘金额 ,
                                            SUM(总货值操盘面积) 总货值操盘面积 ,
                                            SUM(已售货量操盘金额) 已售货量操盘金额 ,
                                            SUM(已售货量操盘面积) 已售货量操盘面积 , 
                                            SUM(未销售部分操盘货量) 未销售部分操盘货量 ,
                                            SUM(未销售部分可售操盘面积) 未销售部分可售操盘面积 ,

                                            SUM(剩余可售货值金额) 剩余可售货值金额 ,
                                            SUM(剩余可售货值面积) 剩余可售货值面积 , 
                                            SUM(工程达到可售未拿证货值金额) 工程达到可售未拿证货值金额 ,
                                            SUM(工程达到可售未拿证货值面积) 工程达到可售未拿证货值面积 ,
                                            SUM(获证未推货值金额) 获证未推货值金额 ,
                                            SUM(获证未推货值面积) 获证未推货值面积 ,
                                            SUM(已推未售货值金额) 已推未售货值金额 ,
                                            SUM(已推未售货值面积) 已推未售货值面积 ,

											SUM(剩余可售货值操盘金额) 剩余可售货值操盘金额 ,
                                            SUM(剩余可售货值操盘面积) 剩余可售货值操盘面积 , 
                                            SUM(工程达到可售未拿证货值操盘金额) 工程达到可售未拿证货值操盘金额 ,
                                            SUM(工程达到可售未拿证货值操盘面积) 工程达到可售未拿证货值操盘面积 ,
                                            SUM(获证未推货值操盘金额) 获证未推货值操盘金额 ,
                                            SUM(获证未推货值操盘面积) 获证未推货值操盘面积 ,
                                            SUM(已推未售货值操盘金额) 已推未售货值操盘金额 ,
                                            SUM(已推未售货值操盘面积) 已推未售货值操盘面积 ,

											SUM(年初工程达到可售未拿证货值金额) 年初工程达到可售未拿证货值金额 ,
                                            SUM(年初工程达到可售未拿证货值面积) 年初工程达到可售未拿证货值面积 ,
                                            SUM(年初获证未推货值金额) 年初获证未推货值金额 ,
                                            SUM(年初获证未推货值面积) 年初获证未推货值面积 ,
                                            SUM(年初已推未售货值金额) 年初已推未售货值金额 ,
                                            SUM(年初已推未售货值面积) 年初已推未售货值面积 ,

                                            SUM(后续预计达成货量金额) 后续预计达成货量金额 ,
                                            SUM(后续预计达成货量面积) 后续预计达成货量面积 ,
                                            SUM(本年可售货量金额) 本年可售货量金额 ,
                                            SUM(本年可售货量面积) 本年可售货量面积 ,
                                            SUM(本年剩余可售货量金额) 本年剩余可售货量金额 ,
                                            SUM(本年剩余可售货量面积) 本年剩余可售货量面积 ,
											SUM(当前剩余可售货量金额) 当前剩余可售货量金额 ,
                                            SUM(当前剩余可售货量面积) 当前剩余可售货量面积 ,
                                            SUM(本年之前可售货量金额) 本年之前可售货量金额 ,
                                            SUM(本年之前可售货量面积) 本年之前可售货量面积 ,
                                            SUM(本年之前销售金额) 本年之前销售金额 ,
                                            SUM(本年之前销售面积) 本年之前销售面积 ,
                                            SUM(本年初可售货量金额) 本年初可售货量金额 ,
                                            SUM(本年初可售货量面积) 本年初可售货量面积 ,
                                            SUM(Jan预计货量金额) Jan预计货量金额 ,
                                            SUM(Jan实际货量金额) Jan实际货量金额 ,
                                            SUM(Feb预计货量金额) Feb预计货量金额 ,
                                            SUM(Feb实际货量金额) Feb实际货量金额 ,
                                            SUM(Mar预计货量金额) Mar预计货量金额 ,
                                            SUM(Mar实际货量金额) Mar实际货量金额 ,
                                            SUM(Apr预计货量金额) Apr预计货量金额 ,
                                            SUM(Apr实际货量金额) Apr实际货量金额 ,
                                            SUM(May预计货量金额) May预计货量金额 ,
                                            SUM(May实际货量金额) May实际货量金额 ,
                                            SUM(Jun预计货量金额) Jun预计货量金额 ,
                                            SUM(Jun实际货量金额) Jun实际货量金额 ,
                                            SUM(July预计货量金额) July预计货量金额 ,
                                            SUM(July实际货量金额) July实际货量金额 ,
                                            SUM(Aug预计货量金额) Aug预计货量金额 ,
                                            SUM(Aug实际货量金额) Aug实际货量金额 ,
                                            SUM(Sep预计货量金额) Sep预计货量金额 ,
                                            SUM(Sep实际货量金额) Sep实际货量金额 ,
                                            SUM(Oct预计货量金额) Oct预计货量金额 ,
                                            SUM(Oct实际货量金额) Oct实际货量金额 ,
                                            SUM(Nov预计货量金额) Nov预计货量金额 ,
                                            SUM(Nov实际货量金额) Nov实际货量金额 ,
                                            SUM(Dec预计货量金额) Dec预计货量金额 ,
                                            SUM(Dec实际货量金额) Dec实际货量金额 ,
                                            SUM(本月预计货量金额) 本月预计货量金额 ,
                                            SUM(本月实际货量金额) 本月实际货量金额 ,
                                            SUM(本年预计货量金额) 本年预计货量金额 ,
                                            SUM(本年实际货量金额) 本年实际货量金额 ,
                                            SUM(本年已售货量金额) 本年已售货量金额 ,
                                            SUM(本年已售货量面积) 本年已售货量面积 ,
                                            SUM(滞后货量金额) 滞后货量金额 ,
                                            SUM(滞后货量面积) 滞后货量面积 ,
                                            SUM(今年后续预计达成货量金额) 今年后续预计达成货量金额 ,
                                            SUM(今年后续预计达成货量面积) 今年后续预计达成货量面积 ,
                                            SUM(今年车位可售金额) 今年车位可售金额
                                    FROM    #ythz phz
                                    GROUP BY 组织架构ID
                                  ) phz ON phz.组织架构ID = bi.组织架构ID
                        LEFT JOIN #ythz2 phz2 ON phz2.组织架构ID = bi.组织架构ID
                        LEFT JOIN #ythz3 phz3 ON phz3.组织架构ID = bi.组织架构ID
                        LEFT JOIN #ychzyc phzyc1 ON phzyc1.组织架构ID = bi.组织架构ID
                        LEFT JOIN #ychzyc2 phzyc2 ON phzyc2.组织架构ID = bi.组织架构ID
                WHERE   bi.组织架构类型 = 4 AND bi.组织架构ID NOT IN (
					 SELECT bi.组织架构ID FROM erp25.dbo.ydkb_BaseInfo bi 
					 INNER JOIN erp25.dbo.ydkb_BaseInfo bi1 ON bi.组织架构ID = bi1.组织架构父级ID
					  WHERE bi.组织架构ID IN (SELECT  ProjGUID FROM    s_hndjdgProjList)
				)
                GROUP BY bi.组织架构ID ,
                        bi.组织架构名称 ,
                        bi.组织架构编码 ,
                        bi.组织架构类型; 
				  

    ---计算平均去化周期,按照业态计算，用业态的剩余货量面积/本年月平均已售面积（认购）
    ---从货量铺排中计算每月平均销售面积（认购口径）,排除掉车位的
        SELECT  t1.ProjGUID ,
                t1.组织架构ID ,
                t1.组织架构名称 ,
                CASE WHEN SUM(CASE WHEN ISNULL(t1.ThisMonthSaleAreaRg, 0) <> 0
                                   THEN 1
                                   ELSE 0
                              END) = 0 THEN 0
                     ELSE SUM(t1.ThisMonthSaleAreaRg)
                          / SUM(CASE WHEN ISNULL(t1.ThisMonthSaleAreaRg, 0) <> 0
                                     THEN 1
                                     ELSE 0
                                END)
                END AS AvgMonthSaleAreaRg
        INTO    #ytAvgMonthSaleAreaRg
        FROM    ( SELECT    a.ProjGUID ,
                            bi.组织架构ID ,
                            bi.组织架构名称 ,
                            SaleValuePlanYear ,
                            SaleValuePlanMonth ,
                            SUM(ThisMonthSaleAreaRg) AS ThisMonthSaleAreaRg
                  FROM      s_SaleValuePlan a
                            INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON a.ProjGUID = bi.组织架构父级ID
                                                              AND bi.组织架构名称 = a.ProductType
                  WHERE     SaleValuePlanYear = YEAR(GETDATE())
                            AND a.ProductType NOT LIKE '车库'
                            AND bi.组织架构类型 = 4
                  GROUP BY  a.ProjGUID ,
                            bi.组织架构ID ,
                            bi.组织架构名称 ,
                            SaleValuePlanYear ,
                            SaleValuePlanMonth
                ) t1
        GROUP BY t1.ProjGUID ,
                t1.组织架构ID ,
                t1.组织架构名称;


        UPDATE  a
        SET     a.存货预计去化周期 = ISNULL(CASE WHEN ISNULL(yt.AvgMonthSaleAreaRg, 0) = 0
                                         THEN 0
                                         ELSE ISNULL(a.剩余货值面积, 0)
                                              / ISNULL(yt.AvgMonthSaleAreaRg,
                                                       0)
                                    END, 0) ,
                a.月平均销售面积 = ISNULL(yt.AvgMonthSaleAreaRg, 0)
        FROM    ydkb_dthz a
                LEFT JOIN #ytAvgMonthSaleAreaRg yt ON yt.组织架构ID = a.组织架构ID
        WHERE   a.组织架构类型 = 4;

    ---插入项目货值数据
        INSERT  INTO dbo.ydkb_dthz
                ( 组织架构ID ,
                  组织架构名称 ,
                  组织架构编码 ,
                  组织架构类型 ,

                  总货值金额 ,
                  总货值面积 ,
                  已售货量金额 ,
                  已售货量面积 ,

                       --操盘项目
                  总货值金额操盘项目 ,
                  总货值面积操盘项目 ,
                  已售货量金额操盘项目 ,
                  已售货量面积操盘项目 ,

                  剩余货值金额 ,
                  剩余货值面积 ,
                  剩余可售货值金额 ,
                  剩余可售货值面积 ,
                  --本月情况
                  工程达到可售未拿证货值金额 ,
                  工程达到可售未拿证货值面积 ,
                  获证未推货值金额 ,
                  获证未推货值面积 ,
                  已推未售货值金额 ,
                  已推未售货值面积 ,

                  --操盘项目
                  剩余货值金额操盘项目 ,
                  剩余货值面积操盘项目 ,
                  剩余可售货值金额操盘项目 ,
                  剩余可售货值面积操盘项目 ,
                  工程达到可售未拿证货值金额操盘项目 ,
                  工程达到可售未拿证货值面积操盘项目 ,
                  获证未推货值金额操盘项目 ,
                  获证未推货值面积操盘项目 ,
                  已推未售货值金额操盘项目 ,
                  已推未售货值面积操盘项目 ,
				       --年初可售情况
                  年初工程达到可售未拿证货值金额 ,
                  年初工程达到可售未拿证货值面积 ,
                  年初获证未推货值金额 ,
                  年初获证未推货值面积 ,
                  年初已推未售货值金额 ,
                  年初已推未售货值面积 ,
                  本月新货货量 ,
                  本月新货面积 ,
                  本年存货货量 ,
                  本年存货面积 ,
                  后续预计达成货量金额 ,
                  后续预计达成货量面积 ,
                  今年后续预计达成货量金额 ,
                  今年后续预计达成货量面积 ,
                  本年可售货量金额 ,
                  本年可售货量面积 ,
                  本年剩余可售货量金额 ,
                  本年剩余可售货量面积 ,
				  当前剩余可售货量金额 ,
                  当前剩余可售货量面积 ,
                  本年已售货量金额 ,
                  本年已售货量面积 ,
                  Jan预计货量金额 ,
                  Jan实际货量金额 ,
                  Jan货量达成率 ,
                  Feb预计货量金额 ,
                  Feb实际货量金额 ,
                  Feb货量达成率 ,
                  Mar预计货量金额 ,
                  Mar实际货量金额 ,
                  Mar货量达成率 ,
                  Apr预计货量金额 ,
                  Apr实际货量金额 ,
                  Apr货量达成率 ,
                  May预计货量金额 ,
                  May实际货量金额 ,
                  May货量达成率 ,
                  Jun预计货量金额 ,
                  Jun实际货量金额 ,
                  Jun货量达成率 ,
                  July预计货量金额 ,
                  July实际货量金额 ,
                  July货量达成率 ,
                  Aug预计货量金额 ,
                  Aug实际货量金额 ,
                  Aug货量达成率 ,
                  Sep预计货量金额 ,
                  Sep实际货量金额 ,
                  Sep货量达成率 ,
                  Oct预计货量金额 ,
                  Oct实际货量金额 ,
                  Oct货量达成率 ,
                  Nov预计货量金额 ,
                  Nov实际货量金额 ,
                  Nov货量达成率 ,
                  Dec预计货量金额 ,
                  Dec实际货量金额 ,
                  Dec货量达成率 ,
                  本月预计货量金额 ,
                  本月实际货量金额 ,
                  本月货量达成率 ,
                  本年预计货量金额 ,
                  本年实际货量金额 ,
                  本年货量达成率 ,

                       --1-2月份
                  Jan可售货值金额 ,     --1月总可售货值	
                  Jan可售货值面积 ,     --1月总可售面积	
                  Jan新推货值金额 ,     --1月新推货量	
                  Jan新推货值面积 ,     --1月新推面积	 
                  Feb可售货值金额 ,     --2月总可售货值	
                  Feb可售货值面积 ,     --2月总可售面积	
                  Feb新推货值金额 ,     --2月新推货量	
                  Feb新推货值面积 ,     --2月新推面积	 
                  JanFeb可售货值金额 ,
                  JanFeb可售货值面积 ,
                  JanFeb新推货值金额 ,
                  JanFeb新推货值面积 ,
                       --3月份
                  Mar可售货值金额 ,
                  Mar可售货值面积 ,
                  Mar新推货值金额 ,
                  Mar新推货值面积 ,

                       --4月份
                  Apr可售货值金额 ,
                  Apr可售货值面积 ,
                  Apr新推货值金额 ,
                  Apr新推货值面积 ,

                       --5月份
                  May可售货值金额 ,
                  May可售货值面积 ,
                  May新推货值金额 ,
                  May新推货值面积 ,

                       --6月份
                  Jun可售货值金额 ,
                  Jun可售货值面积 ,
                  Jun新推货值金额 ,
                  Jun新推货值面积 ,

                       --7月份
                  July可售货值金额 ,
                  July可售货值面积 ,
                  July新推货值金额 ,
                  July新推货值面积 ,

                       --8月份
                  Aug可售货值金额 ,
                  Aug可售货值面积 ,
                  Aug新推货值金额 ,
                  Aug新推货值面积 ,

                       --9月份
                  Sep可售货值金额 ,
                  Sep可售货值面积 ,
                  Sep新推货值金额 ,
                  Sep新推货值面积 ,

                       --10月份
                  Oct可售货值金额 ,
                  Oct可售货值面积 ,
                  Oct新推货值金额 ,
                  Oct新推货值面积 ,

                       --11月份
                  Nov可售货值金额 ,
                  Nov可售货值面积 ,
                  Nov新推货值金额 ,
                  Nov新推货值面积 ,

                       --12月份
                  Dec可售货值金额 ,
                  Dec可售货值面积 ,
                  Dec新推货值金额 ,
                  Dec新推货值面积 ,

                       --下一年
                       --1-2月份
                  NextJan可售货值金额 , --1月总可售货值	
                  NextJan可售货值面积 , --1月总可售面积	
                  NextJan新推货值金额 , --1月新推货量	
                  NextJan新推货值面积 , --1月新推面积	 
                  NextFeb可售货值金额 , --2月总可售货值	
                  NextFeb可售货值面积 , --2月总可售面积	
                  NextFeb新推货值金额 , --2月新推货量	
                  NextFeb新推货值面积 , --2月新推面积	 
                  NextJanFeb可售货值金额 ,
                  NextJanFeb可售货值面积 ,
                  NextJanFeb新推货值金额 ,
                  NextJanFeb新推货值面积 ,
                       --3月份
                  NextMar可售货值金额 ,
                  NextMar可售货值面积 ,
                  NextMar新推货值金额 ,
                  NextMar新推货值面积 ,

                       --4月份
                  NextApr可售货值金额 ,
                  NextApr可售货值面积 ,
                  NextApr新推货值金额 ,
                  NextApr新推货值面积 ,

                       --5月份
                  NextMay可售货值金额 ,
                  NextMay可售货值面积 ,
                  NextMay新推货值金额 ,
                  NextMay新推货值面积 ,

                       --6月份
                  NextJun可售货值金额 ,
                  NextJun可售货值面积 ,
                  NextJun新推货值金额 ,
                  NextJun新推货值面积 ,

                       --7月份
                  NextJuly可售货值金额 ,
                  NextJuly可售货值面积 ,
                  NextJuly新推货值金额 ,
                  NextJuly新推货值面积 ,

                       --8月份
                  NextAug可售货值金额 ,
                  NextAug可售货值面积 ,
                  NextAug新推货值金额 ,
                  NextAug新推货值面积 ,

                       --9月份
                  NextSep可售货值金额 ,
                  NextSep可售货值面积 ,
                  NextSep新推货值金额 ,
                  NextSep新推货值面积 ,

                       --10月份
                  NextOct可售货值金额 ,
                  NextOct可售货值面积 ,
                  NextOct新推货值金额 ,
                  NextOct新推货值面积 ,

                       --11月份
                  NextNov可售货值金额 ,
                  NextNov可售货值面积 ,
                  NextNov新推货值金额 ,
                  NextNov新推货值面积 ,

                       --12月份
                  NextDec可售货值金额 ,
                  NextDec可售货值面积 ,
                  NextDec新推货值金额 ,
                  NextDec新推货值面积 ,
                  滞后货量金额 ,
                  滞后货量面积 ,
                  存货预计去化周期 ,
                  预计达到预售形象日期 ,
                  实际达到预售形象日期 ,
                  预计预售办理日期 ,
                  实际预售办理日期 ,
                  预计售价 ,
                  今年车位可售金额
                )
                SELECT  bi.组织架构ID ,
                        bi.组织架构名称 ,
                        bi.组织架构编码 ,
                        bi.组织架构类型 ,
                        ISNULL(phz.总货值金额, 0) + ISNULL(phz2.总货值金额, 0) ,
                        ISNULL(phz.总货值面积, 0) + ISNULL(phz2.总货值面积, 0) ,
                        ISNULL(phz.已售货量金额, 0) + ISNULL(phz2.已售货量金额, 0) ,
                        ISNULL(phz.已售货量面积, 0) + ISNULL(phz2.已售货量面积, 0) ,
                                                                   --操盘项目
                        ISNULL(phz.总货值操盘金额, 0)+ ISNULL(phz2.总货值操盘金额, 0) AS 总货值金额操盘项目 ,
                        ISNULL(phz.总货值操盘面积, 0)+ ISNULL(phz2.总货值操盘面积, 0) AS 总货值面积操盘项目 ,
                        ISNULL(phz.已售货量操盘金额, 0)+ ISNULL(phz2.已售货量操盘金额, 0) AS 已售货量金额操盘项目 ,
                        ISNULL(phz.已售货量操盘面积, 0)+ ISNULL(phz2.已售货量操盘面积, 0) AS 已售货量面积操盘项目 ,

                        ISNULL(phz.未销售部分货量, 0) + ISNULL(phz2.未销售部分货量, 0) ,
                        ISNULL(phz.未销售部分可售面积, 0) + ISNULL(phz2.未销售部分可售面积, 0) ,
                        ISNULL(phz.剩余可售货值金额, 0) + ISNULL(phz2.剩余可售货值金额, 0) ,
                        ISNULL(phz.剩余可售货值面积, 0) + ISNULL(phz2.剩余可售货值面积, 0) ,
                        ISNULL(phz.工程达到可售未拿证货值金额, 0)
                        + ISNULL(phz2.工程达到可售未拿证货值金额, 0) ,
                        ISNULL(phz.工程达到可售未拿证货值面积, 0)
                        + ISNULL(phz2.工程达到可售未拿证货值面积, 0) ,
                        ISNULL(phz.获证未推货值金额, 0) + ISNULL(phz2.获证未推货值金额, 0) ,
                        ISNULL(phz.获证未推货值面积, 0) + ISNULL(phz2.获证未推货值金额, 0) ,
                        ISNULL(phz.已推未售货值金额, 0) + ISNULL(phz2.已推未售货值金额, 0) ,
                        ISNULL(phz.已推未售货值面积, 0) + ISNULL(phz2.已推未售货值面积, 0) ,


                        --操盘项目
                        ISNULL(phz.未销售部分操盘货量, 0) + ISNULL(phz2.未销售部分操盘货量, 0) AS 剩余货值金额操盘项目 ,
                        ISNULL(phz.未销售部分可售操盘面积, 0) + ISNULL(phz2.未销售部分可售操盘面积, 0) AS 剩余货值面积操盘项目 ,
                        ISNULL(phz.剩余可售货值操盘金额, 0) + ISNULL(phz2.剩余可售货值金额, 0) AS 剩余可售货值金额操盘项目 ,
                        ISNULL(phz.剩余可售货值操盘面积, 0) + ISNULL(phz2.剩余可售货值操盘面积, 0) AS 剩余可售货值面积操盘项目 ,
                        ISNULL(phz.工程达到可售未拿证货值操盘金额, 0) AS 工程达到可售未拿证货值金额操盘项目 ,
                        ISNULL(phz.工程达到可售未拿证货值操盘面积, 0) AS 工程达到可售未拿证货值面积操盘项目 ,
                        ISNULL(phz.获证未推货值操盘金额, 0) AS 获证未推货值金额操盘项目 ,
                        ISNULL(phz.获证未推货值操盘面积, 0) AS 获证未推货值面积操盘项目 ,
                        ISNULL(phz.已推未售货值操盘金额, 0) AS 已推未售货值金额操盘项目 ,
                        ISNULL(phz.已推未售货值操盘面积, 0) AS 已推未售货值面积操盘项目 ,

						  --年初可售情况
                        ISNULL(phz.年初工程达到可售未拿证货值金额, 0)
                        + ISNULL(phz2.年初工程达到可售未拿证货值金额, 0) ,
                        ISNULL(phz.年初工程达到可售未拿证货值面积, 0)
                        + ISNULL(phz2.年初工程达到可售未拿证货值面积, 0) ,
                        ISNULL(phz.年初获证未推货值金额, 0) + ISNULL(phz2.年初获证未推货值金额, 0) ,
                        ISNULL(phz.年初获证未推货值面积, 0) + ISNULL(phz2.年初获证未推货值金额, 0) ,
                        ISNULL(phz.年初已推未售货值金额, 0) + ISNULL(phz2.年初已推未售货值金额, 0) , --+ ISNULL(月初可售货量金额,0),
                        ISNULL(phz.年初已推未售货值面积, 0) + ISNULL(phz2.年初已推未售货值面积, 0) , --+ISNULL(月初可售货量面积,0),
                        
						ISNULL(phzyc1.本月新货货量, 0) + ISNULL(phzyc2.本月新货货量, 0) AS 本月新货货量 ,
                        ISNULL(phzyc1.本月新货面积, 0) + ISNULL(phzyc2.本月新货面积, 0) AS 本月新货面积 ,
                        ISNULL(phzyc1.本年存货货量, 0) + ISNULL(phzyc2.本年存货货量, 0) AS 本年存货货量 ,
                        ISNULL(phzyc1.本年存货面积, 0) + ISNULL(phzyc2.本年存货面积, 0) AS 本年存货面积 ,
                        ISNULL(phz.后续预计达成货量金额, 0) + ISNULL(phz2.后续预计达成货量金额, 0) AS 后续预计达成货量金额 ,
                        ISNULL(phz.后续预计达成货量面积, 0) + ISNULL(phz2.后续预计达成货量金额, 0) AS 后续预计达成货量面积 ,
                        ISNULL(phz.今年后续预计达成货量金额, 0) AS 今年后续预计达成货量金额 ,
                        ISNULL(phz.今年后续预计达成货量面积, 0) AS 今年后续预计达成货量面积 ,                                                 --+ ISNULL(phz3.月初可售货量面积, 0) AS 本年可售货量面积 ,
                        ( --年初	
                          ISNULL(phz.年初工程达到可售未拿证货值金额, 0)
                          + ISNULL(phz2.年初工程达到可售未拿证货值金额, 0)
                          + ISNULL(phz.年初获证未推货值金额, 0) + ISNULL(phz2.年初获证未推货值金额,
                                                              0)
                          + ISNULL(phz.年初已推未售货值金额, 0) + ISNULL(phz2.年初已推未售货值金额,
                                                              0) + --新推
          ISNULL(phzyc1.[1月新增可售金额], 0) + ISNULL(phzyc1.[2月新增可售金额], 0)
                          + ISNULL(phzyc1.[3月新增可售金额], 0)
                          + ISNULL(phzyc1.[4月新增可售金额], 0)
                          + ISNULL(phzyc1.[5月新增可售金额], 0)
                          + ISNULL(phzyc1.[6月新增可售金额], 0)
                          + ISNULL(phzyc1.[7月新增可售金额], 0)
                          + ISNULL(phzyc1.[8月新增可售金额], 0)
                          + ISNULL(phzyc1.[9月新增可售金额], 0)
                          + ISNULL(phzyc1.[10月新增可售金额], 0)
                          + ISNULL(phzyc1.[11月新增可售金额], 0)
                          + ISNULL(phzyc1.[12月新增可售金额], 0)
                          + ISNULL(phzyc2.[1月新增可售金额], 0)
                          + ISNULL(phzyc2.[2月新增可售金额], 0)
                          + ISNULL(phzyc2.[3月新增可售金额], 0)
                          + ISNULL(phzyc2.[4月新增可售金额], 0)
                          + ISNULL(phzyc2.[5月新增可售金额], 0)
                          + ISNULL(phzyc2.[6月新增可售金额], 0)
                          + ISNULL(phzyc2.[7月新增可售金额], 0)
                          + ISNULL(phzyc2.[8月新增可售金额], 0)
                          + ISNULL(phzyc2.[9月新增可售金额], 0)
                          + ISNULL(phzyc2.[10月新增可售金额], 0)
                          + ISNULL(phzyc2.[11月新增可售金额], 0)
                          + ISNULL(phzyc2.[12月新增可售金额], 0) ) AS 本年可售货量金额 ,
                        ( ISNULL(phz.年初工程达到可售未拿证货值面积, 0)
                          + ISNULL(phz2.年初工程达到可售未拿证货值面积, 0)
                          + ISNULL(phz.年初获证未推货值面积, 0) + ISNULL(phz2.年初获证未推货值面积,
                                                              0)
                          + ISNULL(phz.年初已推未售货值面积, 0) + ISNULL(phz2.年初已推未售货值面积,
                                                              0) + --新推
           ISNULL(phzyc1.[1月新增可售面积], 0) + ISNULL(phzyc1.[2月新增可售面积], 0)
                          + ISNULL(phzyc1.[3月新增可售面积], 0)
                          + ISNULL(phzyc1.[4月新增可售面积], 0)
                          + ISNULL(phzyc1.[5月新增可售面积], 0)
                          + ISNULL(phzyc1.[6月新增可售面积], 0)
                          + ISNULL(phzyc1.[7月新增可售面积], 0)
                          + ISNULL(phzyc1.[8月新增可售面积], 0)
                          + ISNULL(phzyc1.[9月新增可售面积], 0)
                          + ISNULL(phzyc1.[10月新增可售面积], 0)
                          + ISNULL(phzyc1.[11月新增可售面积], 0)
                          + ISNULL(phzyc1.[12月新增可售面积], 0)
                          + ISNULL(phzyc2.[1月新增可售面积], 0)
                          + ISNULL(phzyc2.[2月新增可售面积], 0)
                          + ISNULL(phzyc2.[3月新增可售面积], 0)
                          + ISNULL(phzyc2.[4月新增可售面积], 0)
                          + ISNULL(phzyc2.[5月新增可售面积], 0)
                          + ISNULL(phzyc2.[6月新增可售面积], 0)
                          + ISNULL(phzyc2.[7月新增可售面积], 0)
                          + ISNULL(phzyc2.[8月新增可售面积], 0)
                          + ISNULL(phzyc2.[9月新增可售面积], 0)
                          + ISNULL(phzyc2.[10月新增可售面积], 0)
                          + ISNULL(phzyc2.[11月新增可售面积], 0)
                          + ISNULL(phzyc2.[12月新增可售面积], 0) ) AS 本年可售货量面积 ,
                        ISNULL(phz.本年剩余可售货量金额, 0) + ISNULL(phz2.本年剩余可售货量金额, 0) AS 本年剩余可售货量金额 ,
                        ISNULL(phz.本年剩余可售货量面积, 0) + ISNULL(phz2.本年剩余可售货量面积, 0) AS 本年剩余可售货量面积 ,
						ISNULL(phz.当前剩余可售货量金额, 0) + ISNULL(phz2.当前剩余可售货量金额, 0) AS 当前剩余可售货量金额 ,
                        ISNULL(phz.当前剩余可售货量面积, 0) + ISNULL(phz2.当前剩余可售货量面积, 0) AS 当前剩余可售货量面积 ,
                        ISNULL(phz.本年已售货量金额, 0) + ISNULL(phz2.本年已售货量金额, 0) AS 本年已售货量金额 ,
                        ISNULL(phz.本年已售货量面积, 0) + ISNULL(phz2.本年已售货量面积, 0) AS 本年已售货量面积 ,

                                                                   --货量计划
                        ISNULL(phz.Jan预计货量金额, 0) + ISNULL(phz2.Jan预计货量金额, 0) AS Jan预计货量金额 ,
                        ISNULL(phz.Jan实际货量金额, 0) + ISNULL(phz2.Jan实际货量金额, 0) AS Jan实际货量金额 ,
                        CASE WHEN ( ISNULL(phz.Jan预计货量金额, 0)
                                    + ISNULL(phz2.Jan预计货量金额, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(phz.Jan实际货量金额, 0)
                                    + ISNULL(phz2.Jan实际货量金额, 0) )
                                  / ( ISNULL(phz.Jan预计货量金额, 0)
                                      + ISNULL(phz2.Jan预计货量金额, 0) ) * 1.00
                        END AS Jan货量达成率 ,
                        ISNULL(phz.Feb预计货量金额, 0) + ISNULL(phz2.Feb预计货量金额, 0) AS Feb预计货量金额 ,
                        ISNULL(phz.Feb实际货量金额, 0) + ISNULL(phz2.Feb实际货量金额, 0) AS Feb实际货量金额 ,
                        CASE WHEN ( ISNULL(phz.Feb预计货量金额, 0)
                                    + ISNULL(phz2.Feb预计货量金额, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(phz.Feb实际货量金额, 0)
                                    + ISNULL(phz2.Feb实际货量金额, 0) )
                                  / ( ISNULL(phz.Feb预计货量金额, 0)
                                      + ISNULL(phz2.Feb预计货量金额, 0) ) * 1.00
                        END AS Feb货量达成率 ,
                        ISNULL(phz.Mar预计货量金额, 0) + ISNULL(phz2.Mar预计货量金额, 0) AS Mar预计货量金额 ,
                        ISNULL(phz.Mar实际货量金额, 0) + ISNULL(phz2.Mar实际货量金额, 0) AS Mar实际货量金额 ,
                        CASE WHEN ( ISNULL(phz.Mar预计货量金额, 0)
                                    + ISNULL(phz2.Mar预计货量金额, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(phz.Mar实际货量金额, 0)
                                    + ISNULL(phz2.Mar实际货量金额, 0) )
                                  / ( ISNULL(phz.Mar预计货量金额, 0)
                                      + ISNULL(phz2.Mar预计货量金额, 0) ) * 1.00
                        END AS Mar货量达成率 ,
                        ISNULL(phz.Apr预计货量金额, 0) + ISNULL(phz2.Apr预计货量金额, 0) AS Apr预计货量金额 ,
                        ISNULL(phz.Apr实际货量金额, 0) + ISNULL(phz2.Apr实际货量金额, 0) AS Apr实际货量金额 ,
                        CASE WHEN ( ISNULL(phz.Apr预计货量金额, 0)
                                    + ISNULL(phz2.Apr预计货量金额, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(phz.Apr实际货量金额, 0)
                                    + ISNULL(phz2.Apr实际货量金额, 0) )
                                  / ( ISNULL(phz.Apr预计货量金额, 0)
                                      + ISNULL(phz2.Apr预计货量金额, 0) ) * 1.00
                        END AS Apr货量达成率 ,
                        ISNULL(phz.May预计货量金额, 0) + ISNULL(phz2.May预计货量金额, 0) AS May预计货量金额 ,
                        ISNULL(phz.May实际货量金额, 0) + ISNULL(phz2.May实际货量金额, 0) AS May实际货量金额 ,
                        CASE WHEN ( ISNULL(phz.May预计货量金额, 0)
                                    + ISNULL(phz2.May预计货量金额, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(phz.May实际货量金额, 0)
                                    + ISNULL(phz2.May实际货量金额, 0) )
                                  / ( ISNULL(phz.May预计货量金额, 0)
                                      + ISNULL(phz2.May预计货量金额, 0) ) * 1.00
                        END AS May货量达成率 ,
                        ISNULL(phz.Jun预计货量金额, 0) + ISNULL(phz2.Jun预计货量金额, 0) AS Jun预计货量金额 ,
                        ISNULL(phz.Jun实际货量金额, 0) + ISNULL(phz2.Jun实际货量金额, 0) AS Jun实际货量金额 ,
                        CASE WHEN ( ISNULL(phz.Jun预计货量金额, 0)
                                    + ISNULL(phz2.Jun预计货量金额, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(phz.Jun实际货量金额, 0)
                                    + ISNULL(phz2.Jun实际货量金额, 0) )
                                  / ( ISNULL(phz.Jun预计货量金额, 0)
                                      + ISNULL(phz2.Jun预计货量金额, 0) ) * 1.00
                        END AS Jun货量达成率 ,
                        ISNULL(phz.July预计货量金额, 0) + ISNULL(phz2.July预计货量金额, 0) AS July预计货量金额 ,
                        ISNULL(phz.July实际货量金额, 0) + ISNULL(phz2.July实际货量金额, 0) AS July实际货量金额 ,
                        CASE WHEN ( ISNULL(phz.July预计货量金额, 0)
                                    + ISNULL(phz2.July预计货量金额, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(phz.July实际货量金额, 0)
                                    + ISNULL(phz2.July实际货量金额, 0) )
                                  / ( ISNULL(phz.July预计货量金额, 0)
                                      + ISNULL(phz2.July预计货量金额, 0) ) * 1.00
                        END AS July货量达成率 ,
                        ISNULL(phz.Aug预计货量金额, 0) + ISNULL(phz2.Aug预计货量金额, 0) AS Aug预计货量金额 ,
                        ISNULL(phz.Aug实际货量金额, 0) + ISNULL(phz2.Aug实际货量金额, 0) AS Aug实际货量金额 ,
                        CASE WHEN ( ISNULL(phz.Aug预计货量金额, 0)
                                    + ISNULL(phz2.Aug预计货量金额, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(phz.Aug实际货量金额, 0)
                                    + ISNULL(phz2.Aug实际货量金额, 0) )
                                  / ( ISNULL(phz.Aug预计货量金额, 0)
                                      + ISNULL(phz2.Aug预计货量金额, 0) ) * 1.00
                        END AS Aug货量达成率 ,
                        ISNULL(phz.Sep预计货量金额, 0) + ISNULL(phz2.Sep预计货量金额, 0) AS Sep预计货量金额 ,
                        ISNULL(phz.Sep实际货量金额, 0) + ISNULL(phz2.Sep实际货量金额, 0) AS Sep实际货量金额 ,
                        CASE WHEN ( ISNULL(phz.Sep预计货量金额, 0)
                                    + ISNULL(phz2.Sep预计货量金额, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(phz.Sep实际货量金额, 0)
                                    + ISNULL(phz2.Sep实际货量金额, 0) )
                                  / ( ISNULL(phz.Sep预计货量金额, 0)
                                      + ISNULL(phz2.Sep预计货量金额, 0) ) * 1.00
                        END AS Sep货量达成率 ,
                        ISNULL(phz.Oct预计货量金额, 0) + ISNULL(phz2.Oct预计货量金额, 0) AS Oct预计货量金额 ,
                        ISNULL(phz.Oct实际货量金额, 0) + ISNULL(phz2.Oct实际货量金额, 0) AS Oct实际货量金额 ,
                        CASE WHEN ( ISNULL(phz.Oct预计货量金额, 0)
                                    + ISNULL(phz2.Oct预计货量金额, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(phz.Oct实际货量金额, 0)
                                    + ISNULL(phz2.Oct实际货量金额, 0) )
                                  / ( ISNULL(phz.Oct预计货量金额, 0)
                                      + ISNULL(phz2.Oct预计货量金额, 0) ) * 1.00
                        END AS Oct货量达成率 ,
                        ISNULL(phz.Nov预计货量金额, 0) + ISNULL(phz2.Nov预计货量金额, 0) AS Nov预计货量金额 ,
                        ISNULL(phz.Nov实际货量金额, 0) + ISNULL(phz2.Nov实际货量金额, 0) AS Nov实际货量金额 ,
                        CASE WHEN ( ISNULL(phz.Nov预计货量金额, 0)
                                    + ISNULL(phz2.Nov预计货量金额, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(phz.Nov实际货量金额, 0)
                                    + ISNULL(phz2.Nov实际货量金额, 0) )
                                  / ( ISNULL(phz.Nov预计货量金额, 0)
                                      + ISNULL(phz2.Nov预计货量金额, 0) ) * 1.00
                        END AS Nov货量达成率 ,
                        ISNULL(phz.Dec预计货量金额, 0) + ISNULL(phz2.Dec预计货量金额, 0) AS Dec预计货量金额 ,
                        ISNULL(phz.Dec实际货量金额, 0) + ISNULL(phz2.Dec实际货量金额, 0) AS Dec实际货量金额 ,
                        CASE WHEN ( ISNULL(phz.Dec预计货量金额, 0)
                                    + ISNULL(phz2.Dec预计货量金额, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(phz.Dec实际货量金额, 0)
                                    + ISNULL(phz2.Dec实际货量金额, 0) )
                                  / ( ISNULL(phz.Dec预计货量金额, 0)
                                      + ISNULL(phz2.Dec预计货量金额, 0) ) * 1.00
                        END AS Dec货量达成率 ,
                        ISNULL(phz.本月预计货量金额, 0) + ISNULL(phz2.本月预计货量金额, 0) AS 本月预计货量金额 ,
                        ISNULL(phz.本月实际货量金额, 0) + ISNULL(phz2.本月实际货量金额, 0) AS 本月实际货量金额 ,
                        CASE WHEN ( ISNULL(phz.本月预计货量金额, 0)
                                    + ISNULL(phz2.本月预计货量金额, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(phz.本月实际货量金额, 0)
                                    + ISNULL(phz2.本月实际货量金额, 0) )
                                  / ( ISNULL(phz.本月预计货量金额, 0)
                                      + ISNULL(phz2.本月预计货量金额, 0) ) * 1.00
                        END AS 本月货量达成率 ,
                        ISNULL(phz.本年预计货量金额, 0) + ISNULL(phz2.本年预计货量金额, 0) AS 本年预计货量金额 ,
                        ISNULL(phz.本年实际货量金额, 0) + ISNULL(phz2.本年实际货量金额, 0) AS 本年实际货量金额 ,
                        CASE WHEN ( ISNULL(phz.本年预计货量金额, 0)
                                    + ISNULL(phz2.本年预计货量金额, 0) ) = 0 THEN 0
                             ELSE ( ISNULL(phz.本年实际货量金额, 0)
                                    + ISNULL(phz2.本年实际货量金额, 0) )
                                  / ( ISNULL(phz.本年预计货量金额, 0)
                                      + ISNULL(phz2.本年预计货量金额, 0) ) * 1.00
                        END AS 本年货量达成率 ,
                        ISNULL(phzyc1.[1月总可售金额], 0) + ISNULL(phzyc2.[1月总可售金额],
                                                             0) AS Jan可售货值金额 ,
                        ISNULL(phzyc1.[1月总可售面积], 0) + ISNULL(phzyc2.[1月总可售面积],
                                                             0) AS Jan可售货值面积 ,
                        ISNULL(phzyc1.[1月新增可售金额], 0)
                        + ISNULL(phzyc2.[1月新增可售金额], 0) AS Jan新推货值金额 ,
                        ISNULL(phzyc1.[1月新增可售面积], 0)
                        + ISNULL(phzyc2.[1月新增可售面积], 0) AS Jan新推货值面积 ,
                        ISNULL(phzyc1.[2月总可售金额], 0) + ISNULL(phzyc2.[2月总可售金额],
                                                             0) AS Feb可售货值金额 ,
                        ISNULL(phzyc1.[2月总可售面积], 0) + ISNULL(phzyc2.[2月总可售面积],
                                                             0) AS Feb可售货值面积 ,
                        ISNULL(phzyc1.[2月新增可售金额], 0)
                        + ISNULL(phzyc2.[2月新增可售金额], 0) AS Feb新推货值金额 ,
                        ISNULL(phzyc1.[2月新增可售面积], 0)
                        + ISNULL(phzyc2.[2月新增可售面积], 0) AS Feb新推货值面积 ,
                        ISNULL(phzyc1.[1月总可售金额], 0) + ISNULL(phzyc1.[2月总可售金额],
                                                             0)
                        + ISNULL(phzyc2.[1月总可售金额], 0)
                        + ISNULL(phzyc2.[2月总可售金额], 0) AS JanFeb可售货值金额 ,
                        ISNULL(phzyc1.[1月总可售面积], 0) + ISNULL(phzyc1.[2月总可售面积],
                                                             0)
                        + ISNULL(phzyc2.[1月总可售面积], 0)
                        + ISNULL(phzyc2.[2月总可售面积], 0) AS JanFeb可售货值面积 ,
                        ISNULL(phzyc1.[1月新增可售金额], 0)
                        + ISNULL(phzyc1.[2月新增可售金额], 0)
                        + ISNULL(phzyc2.[1月新增可售金额], 0)
                        + ISNULL(phzyc2.[2月新增可售金额], 0) AS JanFeb新推货值金额 ,
                        ISNULL(phzyc1.[1月新增可售面积], 0)
                        + ISNULL(phzyc1.[2月新增可售面积], 0)
                        + ISNULL(phzyc2.[1月新增可售面积], 0)
                        + ISNULL(phzyc2.[2月新增可售面积], 0) AS JanFeb新推货值面积 ,
                        ISNULL(phzyc1.[3月总可售金额], 0) + ISNULL(phzyc2.[3月总可售金额],
                                                             0) AS Mar可售货值金额 ,
                        ISNULL(phzyc1.[3月总可售面积], 0) + ISNULL(phzyc2.[3月总可售面积],
                                                             0) AS Mar可售货值面积 ,
                        ISNULL(phzyc1.[3月新增可售金额], 0)
                        + ISNULL(phzyc2.[3月新增可售金额], 0) AS Mar新推货值金额 ,
                        ISNULL(phzyc1.[3月新增可售面积], 0)
                        + ISNULL(phzyc2.[3月新增可售面积], 0) AS Mar新推货值面积 ,
                        ISNULL(phzyc1.[4月总可售金额], 0) + ISNULL(phzyc2.[4月总可售金额],
                                                             0) AS Apr可售货值金额 ,
                        ISNULL(phzyc1.[4月总可售面积], 0) + ISNULL(phzyc2.[4月总可售面积],
                                                             0) AS Apr可售货值面积 ,
                        ISNULL(phzyc1.[4月新增可售金额], 0)
                        + ISNULL(phzyc2.[4月新增可售金额], 0) AS Apr新推货值金额 ,
                        ISNULL(phzyc1.[4月新增可售面积], 0)
                        + ISNULL(phzyc2.[4月新增可售面积], 0) AS Apr新推货值面积 ,
                        ISNULL(phzyc1.[5月总可售金额], 0) + ISNULL(phzyc2.[5月总可售金额],
                                                             0) AS May可售货值金额 ,
                        ISNULL(phzyc1.[5月总可售面积], 0) + ISNULL(phzyc2.[5月总可售面积],
                                                             0) AS May可售货值面积 ,
                        ISNULL(phzyc1.[5月新增可售金额], 0)
                        + ISNULL(phzyc2.[5月新增可售金额], 0) AS May新推货值金额 ,
                        ISNULL(phzyc1.[5月新增可售面积], 0)
                        + ISNULL(phzyc2.[5月新增可售面积], 0) AS May新推货值面积 ,
                        ISNULL(phzyc1.[6月总可售金额], 0) + ISNULL(phzyc2.[6月总可售金额],
                                                             0) AS Jun可售货值金额 ,
                        ISNULL(phzyc1.[6月总可售面积], 0) + ISNULL(phzyc2.[6月总可售面积],
                                                             0) AS Jun可售货值面积 ,
                        ISNULL(phzyc1.[6月新增可售金额], 0)
                        + ISNULL(phzyc2.[6月新增可售金额], 0) AS Jun新推货值金额 ,
                        ISNULL(phzyc1.[6月新增可售面积], 0)
                        + ISNULL(phzyc2.[6月新增可售面积], 0) AS Jun新推货值面积 ,
                        ISNULL(phzyc1.[7月总可售金额], 0) + ISNULL(phzyc2.[7月总可售金额],
                                                             0) AS July可售货值金额 ,
                        ISNULL(phzyc1.[7月总可售面积], 0) + ISNULL(phzyc2.[7月总可售面积],
                                                             0) AS July可售货值面积 ,
                        ISNULL(phzyc1.[7月新增可售金额], 0)
                        + ISNULL(phzyc2.[7月新增可售金额], 0) AS July新推货值金额 ,
                        ISNULL(phzyc1.[7月新增可售面积], 0)
                        + ISNULL(phzyc2.[7月新增可售面积], 0) AS July新推货值面积 ,
                        ISNULL(phzyc1.[8月总可售金额], 0) + ISNULL(phzyc2.[8月总可售金额],
                                                             0) AS Aug可售货值金额 ,
                        ISNULL(phzyc1.[8月总可售面积], 0) + ISNULL(phzyc2.[8月总可售面积],
                                                             0) AS Aug可售货值面积 ,
                        ISNULL(phzyc1.[8月新增可售金额], 0)
                        + ISNULL(phzyc2.[8月新增可售金额], 0) AS Aug新推货值金额 ,
                        ISNULL(phzyc1.[8月新增可售面积], 0)
                        + ISNULL(phzyc2.[8月新增可售面积], 0) AS Aug新推货值面积 ,
                        ISNULL(phzyc1.[9月总可售金额], 0) + ISNULL(phzyc2.[9月总可售金额],
                                                             0) AS Sep可售货值金额 ,
                        ISNULL(phzyc1.[9月总可售面积], 0) + ISNULL(phzyc2.[9月总可售面积],
                                                             0) AS Sep可售货值面积 ,
                        ISNULL(phzyc1.[9月新增可售金额], 0)
                        + ISNULL(phzyc2.[9月新增可售金额], 0) AS Sep新推货值金额 ,
                        ISNULL(phzyc1.[9月新增可售面积], 0)
                        + ISNULL(phzyc2.[9月新增可售面积], 0) AS Sep新推货值面积 ,
                        ISNULL(phzyc1.[10月总可售金额], 0)
                        + ISNULL(phzyc2.[10月总可售金额], 0) AS Oct可售货值金额 ,
                        ISNULL(phzyc1.[10月总可售面积], 0)
                        + ISNULL(phzyc2.[10月总可售面积], 0) AS Oct可售货值面积 ,
                        ISNULL(phzyc1.[10月新增可售金额], 0)
                        + ISNULL(phzyc2.[10月新增可售金额], 0) AS Oct新推货值金额 ,
                        ISNULL(phzyc1.[10月新增可售面积], 0)
                        + ISNULL(phzyc2.[10月新增可售面积], 0) AS Oct新推货值面积 ,
                        ISNULL(phzyc1.[11月总可售金额], 0)
                        + ISNULL(phzyc2.[11月总可售金额], 0) AS Nov可售货值金额 ,
                        ISNULL(phzyc1.[11月总可售面积], 0)
                        + ISNULL(phzyc2.[11月总可售面积], 0) AS Nov可售货值面积 ,
                        ISNULL(phzyc1.[11月新增可售金额], 0)
                        + ISNULL(phzyc2.[11月新增可售金额], 0) AS Nov新推货值金额 ,
                        ISNULL(phzyc1.[11月新增可售面积], 0)
                        + ISNULL(phzyc2.[11月新增可售面积], 0) AS Nov新推货值面积 ,
                        ISNULL(phzyc1.[12月总可售金额], 0)
                        + ISNULL(phzyc2.[12月总可售金额], 0) AS Dec可售货值金额 ,
                        ISNULL(phzyc1.[12月总可售面积], 0)
                        + ISNULL(phzyc2.[12月总可售面积], 0) AS Dec可售货值面积 ,
                        ISNULL(phzyc1.[12月新增可售金额], 0)
                        + ISNULL(phzyc2.[12月新增可售金额], 0) AS Dec新推货值金额 ,
                        ISNULL(phzyc1.[12月新增可售面积], 0)
                        + ISNULL(phzyc2.[12月新增可售面积], 0) AS Dec新推货值面积 ,
                        ISNULL(phzyc1.[Next1月总可售金额], 0)
                        + ISNULL(phzyc2.[Next1月总可售金额], 0) AS NextJan可售货值金额 ,
                        ISNULL(phzyc1.[Next1月总可售面积], 0)
                        + ISNULL(phzyc2.[Next1月总可售面积], 0) AS NextJan可售货值面积 ,
                        ISNULL(phzyc1.[Next1月新增可售金额], 0)
                        + ISNULL(phzyc2.[Next1月新增可售金额], 0) AS NextJan新推货值金额 ,
                        ISNULL(phzyc1.[Next1月新增可售面积], 0)
                        + ISNULL(phzyc2.[Next1月新增可售面积], 0) AS NextJan新推货值面积 ,
                        ISNULL(phzyc1.[Next2月总可售金额], 0)
                        + ISNULL(phzyc2.[Next2月总可售金额], 0) AS NextFeb可售货值金额 ,
                        ISNULL(phzyc1.[Next2月总可售面积], 0)
                        + ISNULL(phzyc2.[Next2月总可售面积], 0) AS NextFeb可售货值面积 ,
                        ISNULL(phzyc1.[Next2月新增可售金额], 0)
                        + ISNULL(phzyc2.[Next2月新增可售金额], 0) AS NextFeb新推货值金额 ,
                        ISNULL(phzyc1.[Next2月新增可售面积], 0)
                        + ISNULL(phzyc2.[Next2月新增可售面积], 0) AS NextFeb新推货值面积 ,
                        ISNULL(phzyc1.[Next1月总可售金额], 0)
                        + ISNULL(phzyc1.[Next2月总可售金额], 0)
                        + ISNULL(phzyc2.[Next1月总可售金额], 0)
                        + ISNULL(phzyc2.[Next2月总可售金额], 0) AS NextJanFeb可售货值金额 ,
                        ISNULL(phzyc1.[Next1月总可售面积], 0)
                        + ISNULL(phzyc1.[Next2月总可售面积], 0)
                        + ISNULL(phzyc2.[Next1月总可售面积], 0)
                        + ISNULL(phzyc2.[Next2月总可售面积], 0) AS NextJanFeb可售货值面积 ,
                        ISNULL(phzyc1.[Next1月新增可售金额], 0)
                        + ISNULL(phzyc1.[Next2月新增可售金额], 0)
                        + ISNULL(phzyc2.[Next1月新增可售金额], 0)
                        + ISNULL(phzyc2.[Next2月新增可售金额], 0) AS NextJanFeb新推货值金额 ,
                        ISNULL(phzyc1.[Next1月新增可售面积], 0)
                        + ISNULL(phzyc1.[Next2月新增可售面积], 0)
                        + ISNULL(phzyc2.[Next1月新增可售面积], 0)
                        + ISNULL(phzyc2.[Next2月新增可售面积], 0) AS NextJanFeb新推货值面积 ,
                        ISNULL(phzyc1.[Next3月总可售金额], 0)
                        + ISNULL(phzyc2.[Next3月总可售金额], 0) AS NextMar可售货值金额 ,
                        ISNULL(phzyc1.[Next3月总可售面积], 0)
                        + ISNULL(phzyc2.[Next3月总可售面积], 0) AS NextMar可售货值面积 ,
                        ISNULL(phzyc1.[Next3月新增可售金额], 0)
                        + ISNULL(phzyc2.[Next3月新增可售金额], 0) AS NextMar新推货值金额 ,
                        ISNULL(phzyc1.[Next3月新增可售面积], 0)
                        + ISNULL(phzyc2.[Next3月新增可售面积], 0) AS NextMar新推货值面积 ,
                        ISNULL(phzyc1.[Next4月总可售金额], 0)
                        + ISNULL(phzyc2.[Next4月总可售金额], 0) AS NextApr可售货值金额 ,
                        ISNULL(phzyc1.[Next4月总可售面积], 0)
                        + ISNULL(phzyc2.[Next4月总可售面积], 0) AS NextApr可售货值面积 ,
                        ISNULL(phzyc1.[Next4月新增可售金额], 0)
                        + ISNULL(phzyc2.[Next4月新增可售金额], 0) AS NextApr新推货值金额 ,
                        ISNULL(phzyc1.[Next4月新增可售面积], 0)
                        + ISNULL(phzyc2.[Next4月新增可售面积], 0) AS NextApr新推货值面积 ,
                        ISNULL(phzyc1.[Next5月总可售金额], 0)
                        + ISNULL(phzyc2.[Next5月总可售金额], 0) AS NextMay可售货值金额 ,
                        ISNULL(phzyc1.[Next5月总可售面积], 0)
                        + ISNULL(phzyc2.[Next5月总可售面积], 0) AS NextMay可售货值面积 ,
                        ISNULL(phzyc1.[Next5月新增可售金额], 0)
                        + ISNULL(phzyc2.[Next5月新增可售金额], 0) AS NextMay新推货值金额 ,
                        ISNULL(phzyc1.[Next5月新增可售面积], 0)
                        + ISNULL(phzyc2.[Next5月新增可售面积], 0) AS NextMay新推货值面积 ,
                        ISNULL(phzyc1.[Next6月总可售金额], 0)
                        + ISNULL(phzyc2.[Next6月总可售金额], 0) AS NextJun可售货值金额 ,
                        ISNULL(phzyc1.[Next6月总可售面积], 0)
                        + ISNULL(phzyc2.[Next6月总可售面积], 0) AS NextJun可售货值面积 ,
                        ISNULL(phzyc1.[Next6月新增可售金额], 0)
                        + ISNULL(phzyc2.[Next6月新增可售金额], 0) AS NextJun新推货值金额 ,
                        ISNULL(phzyc1.[Next6月新增可售面积], 0)
                        + ISNULL(phzyc2.[Next6月新增可售金额], 0) AS NextJun新推货值面积 ,
                        ISNULL(phzyc1.[Next7月总可售金额], 0)
                        + ISNULL(phzyc2.[Next7月总可售金额], 0) AS NextJuly可售货值金额 ,
                        ISNULL(phzyc1.[Next7月总可售面积], 0)
                        + ISNULL(phzyc2.[Next7月总可售面积], 0) AS NextJuly可售货值面积 ,
                        ISNULL(phzyc1.[Next7月新增可售金额], 0)
                        + ISNULL(phzyc2.[Next7月新增可售金额], 0) AS NextJuly新推货值金额 ,
                        ISNULL(phzyc1.[Next7月新增可售面积], 0)
                        + ISNULL(phzyc2.[Next7月新增可售面积], 0) AS NextJuly新推货值面积 ,
                        ISNULL(phzyc1.[Next8月总可售金额], 0)
                        + ISNULL(phzyc2.[Next8月总可售金额], 0) AS NextAug可售货值金额 ,
                        ISNULL(phzyc1.[Next8月总可售面积], 0)
                        + ISNULL(phzyc2.[Next8月总可售面积], 0) AS NextAug可售货值面积 ,
                        ISNULL(phzyc1.[Next8月新增可售金额], 0)
                        + ISNULL(phzyc2.[Next8月新增可售金额], 0) AS NextAug新推货值金额 ,
                        ISNULL(phzyc1.[Next8月新增可售面积], 0)
                        + ISNULL(phzyc2.[Next8月新增可售面积], 0) AS NextAug新推货值面积 ,
                        ISNULL(phzyc1.[Next9月总可售金额], 0)
                        + ISNULL(phzyc2.[Next9月总可售金额], 0) AS NextSep可售货值金额 ,
                        ISNULL(phzyc1.[Next9月总可售面积], 0)
                        + ISNULL(phzyc2.[Next9月总可售面积], 0) AS NextSep可售货值面积 ,
                        ISNULL(phzyc1.[Next9月新增可售金额], 0)
                        + ISNULL(phzyc2.[Next9月新增可售金额], 0) AS NextSep新推货值金额 ,
                        ISNULL(phzyc1.[Next9月新增可售面积], 0)
                        + ISNULL(phzyc2.[Next9月新增可售面积], 0) AS NextSep新推货值面积 ,
                        ISNULL(phzyc1.[Next10月总可售金额], 0)
                        + ISNULL(phzyc2.[Next10月总可售金额], 0) AS NextOct可售货值金额 ,
                        ISNULL(phzyc1.[Next10月总可售面积], 0)
                        + ISNULL(phzyc2.[Next10月总可售面积], 0) AS NextOct可售货值面积 ,
                        ISNULL(phzyc1.[Next10月新增可售金额], 0)
                        + ISNULL(phzyc2.[Next10月新增可售金额], 0) AS NextOct新推货值金额 ,
                        ISNULL(phzyc1.[Next10月新增可售面积], 0)
                        + ISNULL(phzyc2.[Next10月新增可售面积], 0) AS NextOct新推货值面积 ,
                        ISNULL(phzyc1.[Next11月总可售金额], 0)
                        + ISNULL(phzyc2.[Next11月总可售金额], 0) AS NextNov可售货值金额 ,
                        ISNULL(phzyc1.[Next11月总可售面积], 0)
                        + ISNULL(phzyc2.[Next11月总可售面积], 0) AS NextNov可售货值面积 ,
                        ISNULL(phzyc1.[Next11月新增可售金额], 0)
                        + ISNULL(phzyc2.[Next11月新增可售金额], 0) AS NextNov新推货值金额 ,
                        ISNULL(phzyc1.[Next11月新增可售面积], 0)
                        + ISNULL(phzyc2.[Next11月新增可售面积], 0) AS NextNov新推货值面积 ,
                        ISNULL(phzyc1.[Next12月总可售金额], 0)
                        + ISNULL(phzyc2.[Next12月总可售金额], 0) AS NextDec可售货值金额 ,
                        ISNULL(phzyc1.[Next12月总可售面积], 0)
                        + ISNULL(phzyc2.[Next12月总可售面积], 0) AS NextDec可售货值面积 ,
                        ISNULL(phzyc1.[Next12月新增可售金额], 0)
                        + ISNULL(phzyc2.[Next12月新增可售金额], 0) AS NextDec新推货值金额 ,
                        ISNULL(phzyc1.[Next12月新增可售面积], 0)
                        + ISNULL(phzyc2.[Next12月新增可售面积], 0) AS NextDec新推货值面积 ,
                        ISNULL(phz.滞后货量金额, 0) AS 滞后货量金额 ,
                        ISNULL(phz.滞后货量面积, 0) AS 滞后货量面积 ,
                        0 AS 存货预计去化周期 ,
                        phz.预计达到预售形象日期 ,
                        phz.实际达到预售形象日期 ,
                        phz.预计预售办理日期 ,
                        phz.实际预售办理日期 ,
                        0 预计售价 ,
                        ISNULL(phz.今年车位可售金额, 0) AS 今年车位可售金额
                FROM    erp25.dbo.ydkb_BaseInfo bi
                        LEFT JOIN #Porjhz phz ON phz.组织架构ID = bi.组织架构ID
                        LEFT JOIN #Porjhz2 phz2 ON phz2.组织架构ID = bi.组织架构ID
                        LEFT JOIN #projhzyc phzyc1 ON phzyc1.组织架构ID = bi.组织架构ID
                        LEFT JOIN #projhzyc2 phzyc2 ON phzyc2.组织架构ID = bi.组织架构ID
                        LEFT JOIN #Porjhz3 phz3 ON phz3.组织架构ID = bi.组织架构ID
                WHERE   bi.组织架构类型 = 3 AND bi.组织架构ID NOT IN (
					 (SELECT  ProjGUID FROM    s_hndjdgProjList)
				);



    ---计算平均去化周期,按照业态计算，用业态的剩余可售货量/本年月平均已售面积（认购）
    ---从货量铺排中计算每月平均销售面积（认购口径）
        SELECT  t1.ProjGUID ,
                t1.组织架构ID ,
                t1.组织架构名称 ,
                CASE WHEN SUM(CASE WHEN ISNULL(t1.ThisMonthSaleAreaRg, 0) <> 0
                                   THEN 1
                                   ELSE 0
                              END) = 0 THEN 0
                     ELSE SUM(t1.ThisMonthSaleAreaRg)
                          / SUM(CASE WHEN ISNULL(t1.ThisMonthSaleAreaRg, 0) <> 0
                                     THEN 1
                                     ELSE 0
                                END)
                END AS AvgThisMonthSaleAreaRg
        INTO    #ProjAvgThisMonthSaleAreaRg
        FROM    ( SELECT    a.ProjGUID ,
                            bi.组织架构ID ,
                            bi.组织架构名称 ,
                            SaleValuePlanYear ,
                            SaleValuePlanMonth ,
                            SUM(ThisMonthSaleAreaRg) AS ThisMonthSaleAreaRg
                  FROM      s_SaleValuePlan a
                            INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON a.ProjGUID = bi.组织架构ID
                  WHERE     SaleValuePlanYear = YEAR(GETDATE())
                            AND bi.组织架构类型 = 3
                  GROUP BY  a.ProjGUID ,
                            bi.组织架构ID ,
                            bi.组织架构名称 ,
                            SaleValuePlanYear ,
                            SaleValuePlanMonth
                ) t1
        GROUP BY t1.ProjGUID ,
                t1.组织架构ID ,
                t1.组织架构名称;


   ---平均存货去化周期=剩余货量面积/月平均去化面积
        UPDATE  a
        SET     a.月平均销售面积 = ISNULL(p.AvgThisMonthSaleAreaRg, 0) ,
                a.存货预计去化周期 = ISNULL(CASE WHEN ISNULL(p.AvgThisMonthSaleAreaRg,
                                                     0) = 0 THEN 0
                                         ELSE ISNULL(a.剩余货值面积, 0)
                                              / ISNULL(p.AvgThisMonthSaleAreaRg,
                                                       0)
                                    END, 0)
        FROM    ydkb_dthz a
                LEFT JOIN #ProjAvgThisMonthSaleAreaRg p ON p.组织架构ID = a.组织架构ID
        WHERE   a.组织架构类型 = 3;



    ---插入城市公司数据
        INSERT  INTO dbo.ydkb_dthz
                ( 组织架构ID ,
                  组织架构名称 ,
                  组织架构编码 ,
                  组织架构类型 ,
                  总货值金额 ,
                  总货值面积 ,
                  已售货量金额 ,
                  已售货量面积 ,
                       --操盘项目
                  总货值金额操盘项目 ,
                  总货值面积操盘项目 ,
                  已售货量金额操盘项目 ,
                  已售货量面积操盘项目 ,

                  剩余货值金额 ,
                  剩余货值面积 ,
                  剩余可售货值金额 ,
                  剩余可售货值面积 ,
                       --本月情况
                  工程达到可售未拿证货值金额 ,
                  工程达到可售未拿证货值面积 ,
                  获证未推货值金额 ,
                  获证未推货值面积 ,
                  已推未售货值金额 ,
                  已推未售货值面积 ,

                       --操盘项目
                  剩余货值金额操盘项目 ,
                  剩余货值面积操盘项目 ,
                  剩余可售货值金额操盘项目 ,
                  剩余可售货值面积操盘项目 ,
                  工程达到可售未拿证货值金额操盘项目 ,
                  工程达到可售未拿证货值面积操盘项目 ,
                  获证未推货值金额操盘项目 ,
                  获证未推货值面积操盘项目 ,
                  已推未售货值金额操盘项目 ,
                  已推未售货值面积操盘项目 ,

				    --年初可售情况
                  年初工程达到可售未拿证货值金额 ,
                  年初工程达到可售未拿证货值面积 ,
                  年初获证未推货值金额 ,
                  年初获证未推货值面积 ,
                  年初已推未售货值金额 ,
                  年初已推未售货值面积 ,

                  本月新货货量 ,
                  本月新货面积 ,
                  本年存货货量 ,
                  本年存货面积 ,
                  后续预计达成货量金额 ,
                  后续预计达成货量面积 ,
                  今年后续预计达成货量金额 ,
                  今年后续预计达成货量面积 ,
                  本年可售货量金额 ,
                  本年可售货量面积 ,
                  本年剩余可售货量金额 ,
                  本年剩余可售货量面积 ,
				  当前剩余可售货量金额 ,
                  当前剩余可售货量面积 ,
                  本年已售货量金额 ,
                  本年已售货量面积 ,
                  Jan预计货量金额 ,
                  Jan实际货量金额 ,
                  Jan货量达成率 ,
                  Feb预计货量金额 ,
                  Feb实际货量金额 ,
                  Feb货量达成率 ,
                  Mar预计货量金额 ,
                  Mar实际货量金额 ,
                  Mar货量达成率 ,
                  Apr预计货量金额 ,
                  Apr实际货量金额 ,
                  Apr货量达成率 ,
                  May预计货量金额 ,
                  May实际货量金额 ,
                  May货量达成率 ,
                  Jun预计货量金额 ,
                  Jun实际货量金额 ,
                  Jun货量达成率 ,
                  July预计货量金额 ,
                  July实际货量金额 ,
                  July货量达成率 ,
                  Aug预计货量金额 ,
                  Aug实际货量金额 ,
                  Aug货量达成率 ,
                  Sep预计货量金额 ,
                  Sep实际货量金额 ,
                  Sep货量达成率 ,
                  Oct预计货量金额 ,
                  Oct实际货量金额 ,
                  Oct货量达成率 ,
                  Nov预计货量金额 ,
                  Nov实际货量金额 ,
                  Nov货量达成率 ,
                  Dec预计货量金额 ,
                  Dec实际货量金额 ,
                  Dec货量达成率 ,
                  本月预计货量金额 ,
                  本月实际货量金额 ,
                  本月货量达成率 ,
                  本年预计货量金额 ,
                  本年实际货量金额 ,
                  本年货量达成率 ,

                       --1-2月份
                  Jan可售货值金额 ,     --1月总可售货值	
                  Jan可售货值面积 ,     --1月总可售面积	
                  Jan新推货值金额 ,     --1月新推货量	
                  Jan新推货值面积 ,     --1月新推面积	 
                  Feb可售货值金额 ,     --2月总可售货值	
                  Feb可售货值面积 ,     --2月总可售面积	
                  Feb新推货值金额 ,     --2月新推货量	
                  Feb新推货值面积 ,     --2月新推面积
                  JanFeb可售货值金额 ,
                  JanFeb可售货值面积 ,
                  JanFeb新推货值金额 ,
                  JanFeb新推货值面积 ,
                       --3月份
                  Mar可售货值金额 ,
                  Mar可售货值面积 ,
                  Mar新推货值金额 ,
                  Mar新推货值面积 ,

                       --4月份
                  Apr可售货值金额 ,
                  Apr可售货值面积 ,
                  Apr新推货值金额 ,
                  Apr新推货值面积 ,

                       --5月份
                  May可售货值金额 ,
                  May可售货值面积 ,
                  May新推货值金额 ,
                  May新推货值面积 ,

                       --6月份
                  Jun可售货值金额 ,
                  Jun可售货值面积 ,
                  Jun新推货值金额 ,
                  Jun新推货值面积 ,

                       --7月份
                  July可售货值金额 ,
                  July可售货值面积 ,
                  July新推货值金额 ,
                  July新推货值面积 ,

                       --8月份
                  Aug可售货值金额 ,
                  Aug可售货值面积 ,
                  Aug新推货值金额 ,
                  Aug新推货值面积 ,

                       --9月份
                  Sep可售货值金额 ,
                  Sep可售货值面积 ,
                  Sep新推货值金额 ,
                  Sep新推货值面积 ,

                       --10月份
                  Oct可售货值金额 ,
                  Oct可售货值面积 ,
                  Oct新推货值金额 ,
                  Oct新推货值面积 ,

                       --11月份
                  Nov可售货值金额 ,
                  Nov可售货值面积 ,
                  Nov新推货值金额 ,
                  Nov新推货值面积 ,

                       --12月份
                  Dec可售货值金额 ,
                  Dec可售货值面积 ,
                  Dec新推货值金额 ,
                  Dec新推货值面积 ,

                       --下一年
                       --1-2月份
                  NextJan可售货值金额 , --1月总可售货值	
                  NextJan可售货值面积 , --1月总可售面积	
                  NextJan新推货值金额 , --1月新推货量	
                  NextJan新推货值面积 , --1月新推面积	 
                  NextFeb可售货值金额 , --2月总可售货值	
                  NextFeb可售货值面积 , --2月总可售面积	
                  NextFeb新推货值金额 , --2月新推货量	
                  NextFeb新推货值面积 , --2月新推面积	 
                  NextJanFeb可售货值金额 ,
                  NextJanFeb可售货值面积 ,
                  NextJanFeb新推货值金额 ,
                  NextJanFeb新推货值面积 ,
                       --3月份
                  NextMar可售货值金额 ,
                  NextMar可售货值面积 ,
                  NextMar新推货值金额 ,
                  NextMar新推货值面积 ,

                       --4月份
                  NextApr可售货值金额 ,
                  NextApr可售货值面积 ,
                  NextApr新推货值金额 ,
                  NextApr新推货值面积 ,

                       --5月份
                  NextMay可售货值金额 ,
                  NextMay可售货值面积 ,
                  NextMay新推货值金额 ,
                  NextMay新推货值面积 ,

                       --6月份
                  NextJun可售货值金额 ,
                  NextJun可售货值面积 ,
                  NextJun新推货值金额 ,
                  NextJun新推货值面积 ,

                       --7月份
                  NextJuly可售货值金额 ,
                  NextJuly可售货值面积 ,
                  NextJuly新推货值金额 ,
                  NextJuly新推货值面积 ,

                       --8月份
                  NextAug可售货值金额 ,
                  NextAug可售货值面积 ,
                  NextAug新推货值金额 ,
                  NextAug新推货值面积 ,

                       --9月份
                  NextSep可售货值金额 ,
                  NextSep可售货值面积 ,
                  NextSep新推货值金额 ,
                  NextSep新推货值面积 ,

                       --10月份
                  NextOct可售货值金额 ,
                  NextOct可售货值面积 ,
                  NextOct新推货值金额 ,
                  NextOct新推货值面积 ,

                       --11月份
                  NextNov可售货值金额 ,
                  NextNov可售货值面积 ,
                  NextNov新推货值金额 ,
                  NextNov新推货值面积 ,

                       --12月份
                  NextDec可售货值金额 ,
                  NextDec可售货值面积 ,
                  NextDec新推货值金额 ,
                  NextDec新推货值面积 ,
                  滞后货量金额 ,
                  滞后货量面积 ,
                  存货预计去化周期 ,
                  预计售价 ,
                  今年车位可售金额
                )
                SELECT  bi2.组织架构ID ,
                        bi2.组织架构名称 ,
                        bi2.组织架构编码 ,
                        bi2.组织架构类型 ,
                        SUM(ISNULL(phz.总货值金额, 0)) + SUM(ISNULL(phz2.总货值金额, 0)) ,
                        SUM(ISNULL(phz.总货值面积, 0)) + SUM(ISNULL(phz2.总货值面积, 0)) ,
                        SUM(ISNULL(phz.已售货量金额, 0)) + SUM(ISNULL(phz2.已售货量金额, 0)) ,
                        SUM(ISNULL(phz.已售货量面积, 0)) + SUM(ISNULL(phz2.已售货量面积, 0)) ,

                        --操盘项目
                        SUM(ISNULL(phz.总货值操盘金额, 0)) + SUM(ISNULL(phz2.总货值操盘金额, 0))  ,
                        SUM(ISNULL(phz.总货值操盘面积, 0)) + SUM(ISNULL(phz2.总货值操盘面积, 0)) ,
                        SUM(ISNULL(phz.已售货量操盘金额, 0)) + SUM(ISNULL(phz2.已售货量操盘金额, 0)) ,
                        SUM(ISNULL(phz.已售货量操盘面积, 0)) + SUM(ISNULL(phz2.已售货量操盘面积, 0)) ,

                        SUM(ISNULL(phz.未销售部分货量, 0)) + SUM(ISNULL(phz2.未销售部分货量,
                                                              0)) ,
                        SUM(ISNULL(phz.未销售部分可售面积, 0))
                        + SUM(ISNULL(phz2.未销售部分可售面积, 0)) ,
                        SUM(ISNULL(phz.剩余可售货值金额, 0))
                        + SUM(ISNULL(phz2.剩余可售货值金额, 0)) ,
                        SUM(ISNULL(phz.剩余可售货值面积, 0))
                        + SUM(ISNULL(phz2.剩余可售货值面积, 0)) ,
                        SUM(ISNULL(phz.工程达到可售未拿证货值金额, 0))
                        + SUM(ISNULL(phz2.工程达到可售未拿证货值金额, 0)) ,
                        SUM(ISNULL(phz.工程达到可售未拿证货值面积, 0))
                        + SUM(ISNULL(phz2.工程达到可售未拿证货值面积, 0)) ,
                        SUM(ISNULL(phz.获证未推货值金额, 0))
                        + SUM(ISNULL(phz2.获证未推货值金额, 0)) ,
                        SUM(ISNULL(phz.获证未推货值面积, 0))
                        + SUM(ISNULL(phz2.获证未推货值金额, 0)) ,
                        SUM(ISNULL(phz.已推未售货值金额, 0))
                        + SUM(ISNULL(phz2.已推未售货值金额, 0)) ,
                        SUM(ISNULL(phz.已推未售货值面积, 0))
                        + SUM(ISNULL(phz2.已推未售货值面积, 0)) ,

                        --操盘项目
                        SUM(ISNULL(phz.未销售部分操盘货量, 0)) + SUM(ISNULL(phz2.未销售部分操盘货量,
                                                              0)) AS 剩余货值金额操盘项目 ,
                        SUM(ISNULL(phz.未销售部分可售操盘面积, 0))
                        + SUM(ISNULL(phz2.未销售部分可售操盘面积, 0)) AS 剩余货值面积操盘项目 ,
                        SUM(ISNULL(phz.剩余可售货值操盘金额, 0))
                        + SUM(ISNULL(phz2.剩余可售货值操盘金额, 0)) AS 剩余可售货值金额操盘项目 ,
                        SUM(ISNULL(phz.剩余可售货值操盘面积, 0)) + SUM(ISNULL(phz.剩余可售货值操盘面积,
                                                              0)) AS 剩余可售货值面积操盘项目 ,
                        SUM(ISNULL(phz.工程达到可售未拿证货值操盘金额, 0)) AS 工程达到可售未拿证货值金额操盘项目 ,
                        SUM(ISNULL(phz.工程达到可售未拿证货值操盘面积, 0)) AS 工程达到可售未拿证货值面积操盘项目 ,
                        SUM(ISNULL(phz.获证未推货值操盘金额, 0)) AS 获证未推货值金额操盘项目 ,
                        SUM(ISNULL(phz.获证未推货值操盘面积, 0)) AS 获证未推货值面积操盘项目 ,
                        SUM(ISNULL(phz.已推未售货值操盘金额, 0)) AS 已推未售货值金额操盘项目 ,
                        SUM(ISNULL(phz.已推未售货值操盘面积, 0)) AS 已推未售货值面积操盘项目 ,
						--年初可售
						 SUM(ISNULL(phz.年初工程达到可售未拿证货值金额, 0))
                        + SUM(ISNULL(phz2.年初工程达到可售未拿证货值金额, 0)) ,
                        SUM(ISNULL(phz.年初工程达到可售未拿证货值面积, 0))
                        + SUM(ISNULL(phz2.年初工程达到可售未拿证货值面积, 0)) ,
                        SUM(ISNULL(phz.年初获证未推货值金额, 0))
                        + SUM(ISNULL(phz2.年初获证未推货值金额, 0)) ,
                        SUM(ISNULL(phz.年初获证未推货值面积, 0))
                        + SUM(ISNULL(phz2.年初获证未推货值金额, 0)) ,
                        SUM(ISNULL(phz.年初已推未售货值金额, 0))
                        + SUM(ISNULL(phz2.年初已推未售货值金额, 0)) , -- + SUM(ISNULL( 月初可售货量金额,0)),
                        SUM(ISNULL(phz.年初已推未售货值面积, 0))
                        + SUM(ISNULL(phz2.年初已推未售货值面积, 0)) , --+SUM(ISNULL(月初可售货量面积,0)),
                        SUM(ISNULL(phzyc1.本月新货货量, 0) + ISNULL(phzyc2.本月新货货量, 0)) AS 本月新货货量 ,
                        SUM(ISNULL(phzyc1.本月新货面积, 0) + ISNULL(phzyc2.本月新货面积, 0)) AS 本月新货面积 ,
                        SUM(ISNULL(phzyc1.本年存货货量, 0) + ISNULL(phzyc2.本年存货货量, 0)) AS 本年存货货量 ,
                        SUM(ISNULL(phzyc1.本年存货面积, 0) + ISNULL(phzyc2.本年存货面积, 0)) AS 本年存货面积 ,
                        SUM(ISNULL(phz.后续预计达成货量金额, 0))
                        + SUM(ISNULL(phz2.后续预计达成货量金额, 0)) AS 后续预计达成货量金额 ,
                        SUM(ISNULL(phz.后续预计达成货量面积, 0))
                        + SUM(ISNULL(phz2.后续预计达成货量金额, 0)) AS 后续预计达成货量面积 ,
                        SUM(ISNULL(phz.今年后续预计达成货量金额, 0)) AS 今年后续预计达成货量金额 ,
                        SUM(ISNULL(phz.今年后续预计达成货量面积, 0)) AS 今年后续预计达成货量面积 ,
                        ( --年初
                          SUM(ISNULL(phz.年初工程达到可售未拿证货值金额, 0)
                              + ISNULL(phz2.年初工程达到可售未拿证货值金额, 0)
                              + ISNULL(phz.年初获证未推货值金额, 0)
                              + ISNULL(phz2.年初获证未推货值金额, 0)
                              + ISNULL(phz.年初已推未售货值金额, 0)
                              + ISNULL(phz2.年初已推未售货值金额, 0) + --新推
                  ISNULL(phzyc1.[1月新增可售金额], 0) + ISNULL(phzyc1.[2月新增可售金额], 0)
                              + ISNULL(phzyc1.[3月新增可售金额], 0)
                              + ISNULL(phzyc1.[4月新增可售金额], 0)
                              + ISNULL(phzyc1.[5月新增可售金额], 0)
                              + ISNULL(phzyc1.[6月新增可售金额], 0)
                              + ISNULL(phzyc1.[7月新增可售金额], 0)
                              + ISNULL(phzyc1.[8月新增可售金额], 0)
                              + ISNULL(phzyc1.[9月新增可售金额], 0)
                              + ISNULL(phzyc1.[10月新增可售金额], 0)
                              + ISNULL(phzyc1.[11月新增可售金额], 0)
                              + ISNULL(phzyc1.[12月新增可售金额], 0)
                              + ISNULL(phzyc2.[1月新增可售金额], 0)
                              + ISNULL(phzyc2.[2月新增可售金额], 0)
                              + ISNULL(phzyc2.[3月新增可售金额], 0)
                              + ISNULL(phzyc2.[4月新增可售金额], 0)
                              + ISNULL(phzyc2.[5月新增可售金额], 0)
                              + ISNULL(phzyc2.[6月新增可售金额], 0)
                              + ISNULL(phzyc2.[7月新增可售金额], 0)
                              + ISNULL(phzyc2.[8月新增可售金额], 0)
                              + ISNULL(phzyc2.[9月新增可售金额], 0)
                              + ISNULL(phzyc2.[10月新增可售金额], 0)
                              + ISNULL(phzyc2.[11月新增可售金额], 0)
                              + ISNULL(phzyc2.[12月新增可售金额], 0)) ) AS 本年可售货量金额 ,
                        SUM(( ISNULL(phz.年初工程达到可售未拿证货值面积, 0)
                              + ISNULL(phz2.年初工程达到可售未拿证货值面积, 0)
                              + ISNULL(phz.年初获证未推货值面积, 0)
                              + ISNULL(phz2.年初获证未推货值面积, 0)
                              + ISNULL(phz.年初已推未售货值面积, 0)
                              + ISNULL(phz2.年初已推未售货值面积, 0) + --新推
                  ISNULL(phzyc1.[1月新增可售面积], 0) + ISNULL(phzyc1.[2月新增可售面积], 0)
                              + ISNULL(phzyc1.[3月新增可售面积], 0)
                              + ISNULL(phzyc1.[4月新增可售面积], 0)
                              + ISNULL(phzyc1.[5月新增可售面积], 0)
                              + ISNULL(phzyc1.[6月新增可售面积], 0)
                              + ISNULL(phzyc1.[7月新增可售面积], 0)
                              + ISNULL(phzyc1.[8月新增可售面积], 0)
                              + ISNULL(phzyc1.[9月新增可售面积], 0)
                              + ISNULL(phzyc1.[10月新增可售面积], 0)
                              + ISNULL(phzyc1.[11月新增可售面积], 0)
                              + ISNULL(phzyc1.[12月新增可售面积], 0)
                              + ISNULL(phzyc2.[1月新增可售面积], 0)
                              + ISNULL(phzyc2.[2月新增可售面积], 0)
                              + ISNULL(phzyc2.[3月新增可售面积], 0)
                              + ISNULL(phzyc2.[4月新增可售面积], 0)
                              + ISNULL(phzyc2.[5月新增可售面积], 0)
                              + ISNULL(phzyc2.[6月新增可售面积], 0)
                              + ISNULL(phzyc2.[7月新增可售面积], 0)
                              + ISNULL(phzyc2.[8月新增可售面积], 0)
                              + ISNULL(phzyc2.[9月新增可售面积], 0)
                              + ISNULL(phzyc2.[10月新增可售面积], 0)
                              + ISNULL(phzyc2.[11月新增可售面积], 0)
                              + ISNULL(phzyc2.[12月新增可售面积], 0) )) AS 本年可售货量面积 ,
                        SUM(ISNULL(phz.本年剩余可售货量金额, 0))
                        + SUM(ISNULL(phz2.本年剩余可售货量金额, 0)) AS 本年剩余可售货量金额 ,
                        SUM(ISNULL(phz.本年剩余可售货量面积, 0))
                        + SUM(ISNULL(phz2.本年剩余可售货量面积, 0)) AS 本年剩余可售货量面积 ,
						 SUM(ISNULL(phz.当前剩余可售货量金额, 0))
                        + SUM(ISNULL(phz2.当前剩余可售货量金额, 0)) AS 当前剩余可售货量金额 ,
                        SUM(ISNULL(phz.当前剩余可售货量面积, 0))
                        + SUM(ISNULL(phz2.当前剩余可售货量面积, 0)) AS 当前剩余可售货量面积 ,
                        SUM(ISNULL(phz.本年已售货量金额, 0))
                        + SUM(ISNULL(phz2.本年已售货量金额, 0)) AS 本年已售货量金额 ,
                        SUM(ISNULL(phz.本年已售货量面积, 0))
                        + SUM(ISNULL(phz2.本年已售货量面积, 0)) AS 本年已售货量面积 ,

                                                                             --货量计划
                        SUM(ISNULL(phz.Jan预计货量金额, 0))
                        + SUM(ISNULL(phz2.Jan预计货量金额, 0)) AS Jan预计货量金额 ,
                        SUM(ISNULL(phz.Jan实际货量金额, 0))
                        + SUM(ISNULL(phz2.Jan实际货量金额, 0)) AS Jan实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Jan预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Jan预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Jan实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Jan实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Jan预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Jan预计货量金额, 0)) )
                                  * 1.00
                        END AS Jan货量达成率 ,
                        SUM(ISNULL(phz.Feb预计货量金额, 0))
                        + SUM(ISNULL(phz2.Feb预计货量金额, 0)) AS Feb预计货量金额 ,
                        SUM(ISNULL(phz.Feb实际货量金额, 0))
                        + SUM(ISNULL(phz2.Feb实际货量金额, 0)) AS Feb实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Feb预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Feb预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Feb实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Feb实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Feb预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Feb预计货量金额, 0)) )
                                  * 1.00
                        END AS Feb货量达成率 ,
                        SUM(ISNULL(phz.Mar预计货量金额, 0))
                        + SUM(ISNULL(phz2.Mar预计货量金额, 0)) AS Mar预计货量金额 ,
                        SUM(ISNULL(phz.Mar实际货量金额, 0))
                        + SUM(ISNULL(phz2.Mar实际货量金额, 0)) AS Mar实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Mar预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Mar预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Mar实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Mar实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Mar预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Mar预计货量金额, 0)) )
                                  * 1.00
                        END AS Mar货量达成率 ,
                        SUM(ISNULL(phz.Apr预计货量金额, 0))
                        + SUM(ISNULL(phz2.Apr预计货量金额, 0)) AS Apr预计货量金额 ,
                        SUM(ISNULL(phz.Apr实际货量金额, 0))
                        + SUM(ISNULL(phz2.Apr实际货量金额, 0)) AS Apr实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Apr预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Apr预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Apr实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Apr实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Apr预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Apr预计货量金额, 0)) )
                                  * 1.00
                        END AS Apr货量达成率 ,
                        SUM(ISNULL(phz.May预计货量金额, 0))
                        + SUM(ISNULL(phz2.May预计货量金额, 0)) AS May预计货量金额 ,
                        SUM(ISNULL(phz.May实际货量金额, 0))
                        + SUM(ISNULL(phz2.May实际货量金额, 0)) AS May实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.May预计货量金额, 0))
                                    + SUM(ISNULL(phz2.May预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.May实际货量金额, 0))
                                    + SUM(ISNULL(phz2.May实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.May预计货量金额, 0))
                                      + SUM(ISNULL(phz2.May预计货量金额, 0)) )
                                  * 1.00
                        END AS May货量达成率 ,
                        SUM(ISNULL(phz.Jun预计货量金额, 0))
                        + SUM(ISNULL(phz2.Jun预计货量金额, 0)) AS Jun预计货量金额 ,
                        SUM(ISNULL(phz.Jun实际货量金额, 0))
                        + SUM(ISNULL(phz2.Jun实际货量金额, 0)) AS Jun实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Jun预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Jun预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Jun实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Jun实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Jun预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Jun预计货量金额, 0)) )
                                  * 1.00
                        END AS Jun货量达成率 ,
                        SUM(ISNULL(phz.July预计货量金额, 0))
                        + SUM(ISNULL(phz2.July预计货量金额, 0)) AS July预计货量金额 ,
                        SUM(ISNULL(phz.July实际货量金额, 0))
                        + SUM(ISNULL(phz2.July实际货量金额, 0)) AS July实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.July预计货量金额, 0))
                                    + SUM(ISNULL(phz2.July预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.July实际货量金额, 0))
                                    + SUM(ISNULL(phz2.July实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.July预计货量金额, 0))
                                      + SUM(ISNULL(phz2.July预计货量金额, 0)) )
                                  * 1.00
                        END AS July货量达成率 ,
                        SUM(ISNULL(phz.Aug预计货量金额, 0))
                        + SUM(ISNULL(phz2.Aug预计货量金额, 0)) AS Aug预计货量金额 ,
                        SUM(ISNULL(phz.Aug实际货量金额, 0))
                        + SUM(ISNULL(phz2.Aug实际货量金额, 0)) AS Aug实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Aug预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Aug预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Aug实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Aug实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Aug预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Aug预计货量金额, 0)) )
                                  * 1.00
                        END AS Aug货量达成率 ,
                        SUM(ISNULL(phz.Sep预计货量金额, 0))
                        + SUM(ISNULL(phz2.Sep预计货量金额, 0)) AS Sep预计货量金额 ,
                        SUM(ISNULL(phz.Sep实际货量金额, 0))
                        + SUM(ISNULL(phz2.Sep实际货量金额, 0)) AS Sep实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Sep预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Sep预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Sep实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Sep实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Sep预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Sep预计货量金额, 0)) )
                                  * 1.00
                        END AS Sep货量达成率 ,
                        SUM(ISNULL(phz.Oct预计货量金额, 0))
                        + SUM(ISNULL(phz2.Oct预计货量金额, 0)) AS Oct预计货量金额 ,
                        SUM(ISNULL(phz.Oct实际货量金额, 0))
                        + SUM(ISNULL(phz2.Oct实际货量金额, 0)) AS Oct实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Oct预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Oct预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Oct实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Oct实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Oct预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Oct预计货量金额, 0)) )
                                  * 1.00
                        END AS Oct货量达成率 ,
                        SUM(ISNULL(phz.Nov预计货量金额, 0))
                        + SUM(ISNULL(phz2.Nov预计货量金额, 0)) AS Nov预计货量金额 ,
                        SUM(ISNULL(phz.Nov实际货量金额, 0))
                        + SUM(ISNULL(phz2.Nov实际货量金额, 0)) AS Nov实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Nov预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Nov预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Nov实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Nov实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Nov预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Nov预计货量金额, 0)) )
                                  * 1.00
                        END AS Nov货量达成率 ,
                        SUM(ISNULL(phz.Dec预计货量金额, 0))
                        + SUM(ISNULL(phz2.Dec预计货量金额, 0)) AS Dec预计货量金额 ,
                        SUM(ISNULL(phz.Dec实际货量金额, 0))
                        + SUM(ISNULL(phz2.Dec实际货量金额, 0)) AS Dec实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Dec预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Dec预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Dec实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Dec实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Dec预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Dec预计货量金额, 0)) )
                                  * 1.00
                        END AS Dec货量达成率 ,
                        SUM(ISNULL(phz.本月预计货量金额, 0))
                        + SUM(ISNULL(phz2.本月预计货量金额, 0)) AS 本月预计货量金额 ,
                        SUM(ISNULL(phz.本月实际货量金额, 0))
                        + SUM(ISNULL(phz2.本月实际货量金额, 0)) AS 本月实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.本月预计货量金额, 0))
                                    + SUM(ISNULL(phz2.本月预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.本月实际货量金额, 0))
                                    + SUM(ISNULL(phz2.本月实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.本月预计货量金额, 0))
                                      + SUM(ISNULL(phz2.本月预计货量金额, 0)) ) * 1.00
                        END AS 本月货量达成率 ,
                        SUM(ISNULL(phz.本年预计货量金额, 0))
                        + SUM(ISNULL(phz2.本年预计货量金额, 0)) AS 本年预计货量金额 ,
                        SUM(ISNULL(phz.本年实际货量金额, 0))
                        + SUM(ISNULL(phz2.本年实际货量金额, 0)) AS 本年实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.本年预计货量金额, 0))
                                    + SUM(ISNULL(phz2.本年预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.本年实际货量金额, 0))
                                    + SUM(ISNULL(phz2.本年实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.本年预计货量金额, 0))
                                      + SUM(ISNULL(phz2.本年预计货量金额, 0)) ) * 1.00
                        END AS 本年货量达成率 ,
                        SUM(ISNULL(phzyc1.[1月总可售金额], 0)
                            + ISNULL(phzyc2.[1月总可售金额], 0)) AS Jan可售货值金额 ,
                        SUM(ISNULL(phzyc1.[1月总可售面积], 0)
                            + ISNULL(phzyc2.[1月总可售面积], 0)) AS Jan可售货值面积 ,
                        SUM(ISNULL(phzyc1.[1月新增可售金额], 0)
                            + ISNULL(phzyc2.[1月新增可售金额], 0)) AS Jan新推货值金额 ,
                        SUM(ISNULL(phzyc1.[1月新增可售面积], 0)
                            + ISNULL(phzyc2.[1月新增可售面积], 0)) AS Jan新推货值面积 ,
                        SUM(ISNULL(phzyc1.[2月总可售金额], 0)
                            + ISNULL(phzyc2.[2月总可售金额], 0)) AS Feb可售货值金额 ,
                        SUM(ISNULL(phzyc1.[2月总可售面积], 0)
                            + ISNULL(phzyc2.[2月总可售面积], 0)) AS Feb可售货值面积 ,
                        SUM(ISNULL(phzyc1.[2月新增可售金额], 0)
                            + ISNULL(phzyc2.[2月新增可售金额], 0)) AS Feb新推货值金额 ,
                        SUM(ISNULL(phzyc1.[2月新增可售面积], 0)
                            + ISNULL(phzyc2.[2月新增可售面积], 0)) AS Feb新推货值面积 ,
                        SUM(ISNULL(phzyc1.[1月总可售金额], 0)
                            + ISNULL(phzyc1.[2月总可售金额], 0)
                            + ISNULL(phzyc2.[1月总可售金额], 0)
                            + ISNULL(phzyc2.[2月总可售金额], 0)) AS JanFeb可售货值金额 ,
                        SUM(ISNULL(phzyc1.[1月总可售面积], 0)
                            + ISNULL(phzyc1.[2月总可售面积], 0)
                            + ISNULL(phzyc2.[1月总可售面积], 0)
                            + ISNULL(phzyc2.[2月总可售面积], 0)) AS JanFeb可售货值面积 ,
                        SUM(ISNULL(phzyc1.[1月新增可售金额], 0)
                            + ISNULL(phzyc1.[2月新增可售金额], 0)
                            + ISNULL(phzyc2.[1月新增可售金额], 0)
                            + ISNULL(phzyc2.[2月新增可售金额], 0)) AS JanFeb新推货值金额 ,
                        SUM(ISNULL(phzyc1.[1月新增可售面积], 0)
                            + ISNULL(phzyc1.[2月新增可售面积], 0)
                            + ISNULL(phzyc2.[1月新增可售面积], 0)
                            + ISNULL(phzyc2.[2月新增可售面积], 0)) AS JanFeb新推货值面积 ,
                        SUM(ISNULL(phzyc1.[3月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[3月总可售金额], 0)) AS Mar可售货值金额 ,
                        SUM(ISNULL(phzyc1.[3月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[3月总可售面积], 0)) AS Mar可售货值面积 ,
                        SUM(ISNULL(phzyc1.[3月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[3月新增可售金额], 0)) AS Mar新推货值金额 ,
                        SUM(ISNULL(phzyc1.[3月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[3月新增可售面积], 0)) AS Mar新推货值面积 ,
                        SUM(ISNULL(phzyc1.[4月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[4月总可售金额], 0)) AS Apr可售货值金额 ,
                        SUM(ISNULL(phzyc1.[4月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[4月总可售面积], 0)) AS Apr可售货值面积 ,
                        SUM(ISNULL(phzyc1.[4月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[4月新增可售金额], 0)) AS Apr新推货值金额 ,
                        SUM(ISNULL(phzyc1.[4月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[4月新增可售面积], 0)) AS Apr新推货值面积 ,
                        SUM(ISNULL(phzyc1.[5月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[5月总可售金额], 0)) AS May可售货值金额 ,
                        SUM(ISNULL(phzyc1.[5月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[5月总可售面积], 0)) AS May可售货值面积 ,
                        SUM(ISNULL(phzyc1.[5月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[5月新增可售金额], 0)) AS May新推货值金额 ,
                        SUM(ISNULL(phzyc1.[5月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[5月新增可售面积], 0)) AS May新推货值面积 ,
                        SUM(ISNULL(phzyc1.[6月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[6月总可售金额], 0)) AS Jun可售货值金额 ,
                        SUM(ISNULL(phzyc1.[6月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[6月总可售面积], 0)) AS Jun可售货值面积 ,
                        SUM(ISNULL(phzyc1.[6月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[6月新增可售金额], 0)) AS Jun新推货值金额 ,
                        SUM(ISNULL(phzyc1.[6月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[6月新增可售面积], 0)) AS Jun新推货值面积 ,
                        SUM(ISNULL(phzyc1.[7月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[7月总可售金额], 0)) AS July可售货值金额 ,
                        SUM(ISNULL(phzyc1.[7月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[7月总可售面积], 0)) AS July可售货值面积 ,
                        SUM(ISNULL(phzyc1.[7月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[7月新增可售金额], 0)) AS July新推货值金额 ,
                        SUM(ISNULL(phzyc1.[7月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[7月新增可售面积], 0)) AS July新推货值面积 ,
                        SUM(ISNULL(phzyc1.[8月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[8月总可售金额], 0)) AS Aug可售货值金额 ,
                        SUM(ISNULL(phzyc1.[8月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[8月总可售面积], 0)) AS Aug可售货值面积 ,
                        SUM(ISNULL(phzyc1.[8月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[8月新增可售金额], 0)) AS Aug新推货值金额 ,
                        SUM(ISNULL(phzyc1.[8月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[8月新增可售面积], 0)) AS Aug新推货值面积 ,
                        SUM(ISNULL(phzyc1.[9月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[9月总可售金额], 0)) AS Sep可售货值金额 ,
                        SUM(ISNULL(phzyc1.[9月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[9月总可售面积], 0)) AS Sep可售货值面积 ,
                        SUM(ISNULL(phzyc1.[9月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[9月新增可售金额], 0)) AS Sep新推货值金额 ,
                        SUM(ISNULL(phzyc1.[9月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[9月新增可售面积], 0)) AS Sep新推货值面积 ,
                        SUM(ISNULL(phzyc1.[10月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[10月总可售金额], 0)) AS Oct可售货值金额 ,
                        SUM(ISNULL(phzyc1.[10月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[10月总可售面积], 0)) AS Oct可售货值面积 ,
                        SUM(ISNULL(phzyc1.[10月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[10月新增可售金额], 0)) AS Oct新推货值金额 ,
                        SUM(ISNULL(phzyc1.[10月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[10月新增可售面积], 0)) AS Oct新推货值面积 ,
                        SUM(ISNULL(phzyc1.[11月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[11月总可售金额], 0)) AS Nov可售货值金额 ,
                        SUM(ISNULL(phzyc1.[11月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[11月总可售面积], 0)) AS Nov可售货值面积 ,
                        SUM(ISNULL(phzyc1.[11月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[11月新增可售金额], 0)) AS Nov新推货值金额 ,
                        SUM(ISNULL(phzyc1.[11月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[11月新增可售面积], 0)) AS Nov新推货值面积 ,
                        SUM(ISNULL(phzyc1.[12月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[12月总可售金额], 0)) AS Dec可售货值金额 ,
                        SUM(ISNULL(phzyc1.[12月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[12月总可售面积], 0)) AS Dec可售货值面积 ,
                        SUM(ISNULL(phzyc1.[12月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[12月新增可售金额], 0)) AS Dec新推货值金额 ,
                        SUM(ISNULL(phzyc1.[12月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[12月新增可售面积], 0)) AS Dec新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next1月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next1月总可售金额], 0)) AS NextJan可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next1月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next1月总可售面积], 0)) AS NextJan可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next1月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next1月新增可售金额], 0)) AS NextJan新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next1月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next1月新增可售面积], 0)) AS NextJan新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next2月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next2月总可售金额], 0)) AS NextFeb可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next2月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next2月总可售面积], 0)) AS NextFeb可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next2月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next2月新增可售金额], 0)) AS NextFeb新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next2月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next2月新增可售面积], 0)) AS NextFeb新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next1月总可售金额], 0))
                        + SUM(ISNULL(phzyc1.[Next2月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next1月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next2月总可售金额], 0)) AS NextJanFeb可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next1月总可售面积], 0))
                        + SUM(ISNULL(phzyc1.[Next2月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next1月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next2月总可售面积], 0)) AS NextJanFeb可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next1月新增可售金额], 0))
                        + SUM(ISNULL(phzyc1.[Next2月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next1月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next2月新增可售金额], 0)) AS NextJanFeb新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next1月新增可售面积], 0))
                        + SUM(ISNULL(phzyc1.[Next2月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next1月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next2月新增可售面积], 0)) AS NextJanFeb新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next3月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next3月总可售金额], 0)) AS NextMar可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next3月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next3月总可售面积], 0)) AS NextMar可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next3月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next3月新增可售金额], 0)) AS NextMar新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next3月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next3月新增可售面积], 0)) AS NextMar新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next4月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next4月总可售金额], 0)) AS NextApr可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next4月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next4月总可售面积], 0)) AS NextApr可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next4月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next4月新增可售金额], 0)) AS NextApr新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next4月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next4月新增可售面积], 0)) AS NextApr新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next5月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next5月总可售金额], 0)) AS NextMay可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next5月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next5月总可售面积], 0)) AS NextMay可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next5月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next5月新增可售金额], 0)) AS NextMay新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next5月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next5月新增可售面积], 0)) AS NextMay新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next6月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next6月总可售金额], 0)) AS NextJun可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next6月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next6月总可售面积], 0)) AS NextJun可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next6月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next6月新增可售金额], 0)) AS NextJun新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next6月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next6月新增可售金额], 0)) AS NextJun新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next7月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next7月总可售金额], 0)) AS NextJuly可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next7月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next7月总可售面积], 0)) AS NextJuly可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next7月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next7月新增可售金额], 0)) AS NextJuly新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next7月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next7月新增可售面积], 0)) AS NextJuly新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next8月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next8月总可售金额], 0)) AS NextAug可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next8月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next8月总可售面积], 0)) AS NextAug可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next8月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next8月新增可售金额], 0)) AS NextAug新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next8月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next8月新增可售面积], 0)) AS NextAug新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next9月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next9月总可售金额], 0)) AS NextSep可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next9月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next9月总可售面积], 0)) AS NextSep可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next9月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next9月新增可售金额], 0)) AS NextSep新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next9月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next9月新增可售面积], 0)) AS NextSep新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next10月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next10月总可售金额], 0)) AS NextOct可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next10月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next10月总可售面积], 0)) AS NextOct可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next10月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next10月新增可售金额], 0)) AS NextOct新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next10月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next10月新增可售面积], 0)) AS NextOct新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next11月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next11月总可售金额], 0)) AS NextNov可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next11月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next11月总可售面积], 0)) AS NextNov可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next11月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next11月新增可售金额], 0)) AS NextNov新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next11月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next11月新增可售面积], 0)) AS NextNov新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next12月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next12月总可售金额], 0)) AS NextDec可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next12月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next12月总可售面积], 0)) AS NextDec可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next12月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next12月新增可售金额], 0)) AS NextDec新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next12月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next12月新增可售面积], 0)) AS NextDec新推货值面积 ,
                        SUM(ISNULL(phz.滞后货量金额, 0)) AS 滞后货量金额 ,
                        SUM(ISNULL(phz.滞后货量面积, 0)) AS 滞后货量面积 ,
                        0 AS 存货预计去化周期 ,
                        0 预计售价 ,
                        SUM(ISNULL(phz.今年车位可售金额, 0)) AS 今年车位可售金额
                FROM    erp25.dbo.ydkb_BaseInfo bi
                        INNER JOIN ydkb_BaseInfo bi2 ON bi2.组织架构ID = bi.组织架构父级ID
                        LEFT JOIN #Porjhz phz ON phz.组织架构ID = bi.组织架构ID
                        LEFT JOIN #Porjhz2 phz2 ON phz2.组织架构ID = bi.组织架构ID
                        LEFT JOIN #projhzyc phzyc1 ON phzyc1.组织架构ID = bi.组织架构ID
                        LEFT JOIN #projhzyc2 phzyc2 ON phzyc2.组织架构ID = bi.组织架构ID
                        LEFT JOIN #Porjhz3 phz3 ON phz3.组织架构ID = bi.组织架构ID
                WHERE   bi.组织架构类型 = 3 AND bi.组织架构ID NOT IN   (SELECT  ProjGUID FROM    s_hndjdgProjList)
                GROUP BY bi2.组织架构ID ,
                        bi2.组织架构名称 ,
                        bi2.组织架构编码 ,
                        bi2.组织架构类型;


    --计算平均去化周期 统计的时候需要考虑异常值对统计结果的干扰
        UPDATE  a
        SET     a.存货预计去化周期 = ISNULL(b.存货预计去化周期, 0) ,
                a.月平均销售面积 = ISNULL(b.月平均销售面积, 0)
        FROM    ydkb_dthz a
                LEFT JOIN ( SELECT  bi.组织架构父级ID ,
                                    SUM(a.存货预计去化周期) / COUNT(1) AS 存货预计去化周期 ,
                                    SUM(a.月平均销售面积) / COUNT(1) AS 月平均销售面积
                            FROM    ydkb_dthz a
                                    LEFT JOIN ydkb_BaseInfo bi ON a.组织架构ID = bi.组织架构ID
                            WHERE   ( ISNULL(存货预计去化周期, 0) BETWEEN 10 AND 100 )
                                    AND ISNULL(存货预计去化周期, 0) <> 0
                                    AND ISNULL(月平均销售面积, 0) > 0
                                    AND a.组织架构类型 = 3
                            GROUP BY bi.组织架构父级ID
                          ) b ON a.组织架构ID = b.组织架构父级ID
        WHERE   a.组织架构类型 = 2;

    --插入平台公司数据
        INSERT  INTO dbo.ydkb_dthz
                ( 组织架构ID ,
                  组织架构名称 ,
                  组织架构编码 ,
                  组织架构类型 ,
                  总货值金额 ,
                  总货值面积 ,
                  已售货量金额 ,
                  已售货量面积 ,

                       --操盘项目
                  总货值金额操盘项目 ,
                  总货值面积操盘项目 ,
                  已售货量金额操盘项目 ,
                  已售货量面积操盘项目 ,

                  剩余货值金额 ,
                  剩余货值面积 ,
                  剩余可售货值金额 ,
                  剩余可售货值面积 ,
                       --本月情况
                  工程达到可售未拿证货值金额 ,
                  工程达到可售未拿证货值面积 ,
                  获证未推货值金额 ,
                  获证未推货值面积 ,
                  已推未售货值金额 ,
                  已推未售货值面积 ,

                       --操盘项目
                  剩余货值金额操盘项目 ,
                  剩余货值面积操盘项目 ,
                  剩余可售货值金额操盘项目 ,
                  剩余可售货值面积操盘项目 ,
                  工程达到可售未拿证货值金额操盘项目 ,
                  工程达到可售未拿证货值面积操盘项目 ,
                  获证未推货值金额操盘项目 ,
                  获证未推货值面积操盘项目 ,
                  已推未售货值金额操盘项目 ,
                  已推未售货值面积操盘项目 ,

				   --年初可售情况
                  年初工程达到可售未拿证货值金额 ,
                  年初工程达到可售未拿证货值面积 ,
                  年初获证未推货值金额 ,
                  年初获证未推货值面积 ,
                  年初已推未售货值金额 ,
                  年初已推未售货值面积 ,
                  本月新货货量 ,
                  本月新货面积 ,
                  本年存货货量 ,
                  本年存货面积 ,
                  后续预计达成货量金额 ,
                  后续预计达成货量面积 ,
                  今年后续预计达成货量金额 ,
                  今年后续预计达成货量面积 ,
                  本年可售货量金额 ,
                  本年可售货量面积 ,
                  本年剩余可售货量金额 ,
                  本年剩余可售货量面积 ,
				  当前剩余可售货量金额 ,
                  当前剩余可售货量面积 ,
                  本年已售货量金额 ,
                  本年已售货量面积 ,
                  Jan预计货量金额 ,
                  Jan实际货量金额 ,
                  Jan货量达成率 ,
                  Feb预计货量金额 ,
                  Feb实际货量金额 ,
                  Feb货量达成率 ,
                  Mar预计货量金额 ,
                  Mar实际货量金额 ,
                  Mar货量达成率 ,
                  Apr预计货量金额 ,
                  Apr实际货量金额 ,
                  Apr货量达成率 ,
                  May预计货量金额 ,
                  May实际货量金额 ,
                  May货量达成率 ,
                  Jun预计货量金额 ,
                  Jun实际货量金额 ,
                  Jun货量达成率 ,
                  July预计货量金额 ,
                  July实际货量金额 ,
                  July货量达成率 ,
                  Aug预计货量金额 ,
                  Aug实际货量金额 ,
                  Aug货量达成率 ,
                  Sep预计货量金额 ,
                  Sep实际货量金额 ,
                  Sep货量达成率 ,
                  Oct预计货量金额 ,
                  Oct实际货量金额 ,
                  Oct货量达成率 ,
                  Nov预计货量金额 ,
                  Nov实际货量金额 ,
                  Nov货量达成率 ,
                  Dec预计货量金额 ,
                  Dec实际货量金额 ,
                  Dec货量达成率 ,
                  本月预计货量金额 ,
                  本月实际货量金额 ,
                  本月货量达成率 ,
                  本年预计货量金额 ,
                  本年实际货量金额 ,
                  本年货量达成率 ,

                       --1-2月份
                  Jan可售货值金额 ,     --1月总可售货值	
                  Jan可售货值面积 ,     --1月总可售面积	
                  Jan新推货值金额 ,     --1月新推货量	
                  Jan新推货值面积 ,     --1月新推面积	 
                  Feb可售货值金额 ,     --2月总可售货值	
                  Feb可售货值面积 ,     --2月总可售面积	
                  Feb新推货值金额 ,     --2月新推货量	
                  Feb新推货值面积 ,     --2月新推面积	  
                  JanFeb可售货值金额 ,
                  JanFeb可售货值面积 ,
                  JanFeb新推货值金额 ,
                  JanFeb新推货值面积 ,
                       --3月份
                  Mar可售货值金额 ,
                  Mar可售货值面积 ,
                  Mar新推货值金额 ,
                  Mar新推货值面积 ,

                       --4月份
                  Apr可售货值金额 ,
                  Apr可售货值面积 ,
                  Apr新推货值金额 ,
                  Apr新推货值面积 ,

                       --5月份
                  May可售货值金额 ,
                  May可售货值面积 ,
                  May新推货值金额 ,
                  May新推货值面积 ,

                       --6月份
                  Jun可售货值金额 ,
                  Jun可售货值面积 ,
                  Jun新推货值金额 ,
                  Jun新推货值面积 ,

                       --7月份
                  July可售货值金额 ,
                  July可售货值面积 ,
                  July新推货值金额 ,
                  July新推货值面积 ,

                       --8月份
                  Aug可售货值金额 ,
                  Aug可售货值面积 ,
                  Aug新推货值金额 ,
                  Aug新推货值面积 ,

                       --9月份
                  Sep可售货值金额 ,
                  Sep可售货值面积 ,
                  Sep新推货值金额 ,
                  Sep新推货值面积 ,

                       --10月份
                  Oct可售货值金额 ,
                  Oct可售货值面积 ,
                  Oct新推货值金额 ,
                  Oct新推货值面积 ,

                       --11月份
                  Nov可售货值金额 ,
                  Nov可售货值面积 ,
                  Nov新推货值金额 ,
                  Nov新推货值面积 ,

                       --12月份
                  Dec可售货值金额 ,
                  Dec可售货值面积 ,
                  Dec新推货值金额 ,
                  Dec新推货值面积 ,

                       --下一年
                       --1-2月
                  NextJan可售货值金额 , --1月总可售货值	
                  NextJan可售货值面积 , --1月总可售面积	
                  NextJan新推货值金额 , --1月新推货量	
                  NextJan新推货值面积 , --1月新推面积	 
                  NextFeb可售货值金额 , --2月总可售货值	
                  NextFeb可售货值面积 , --2月总可售面积	
                  NextFeb新推货值金额 , --2月新推货量	
                  NextFeb新推货值面积 , --2月新推面积	 
                  NextJanFeb可售货值金额 ,
                  NextJanFeb可售货值面积 ,
                  NextJanFeb新推货值金额 ,
                  NextJanFeb新推货值面积 ,
                       --3月份
                  NextMar可售货值金额 ,
                  NextMar可售货值面积 ,
                  NextMar新推货值金额 ,
                  NextMar新推货值面积 ,

                       --4月份
                  NextApr可售货值金额 ,
                  NextApr可售货值面积 ,
                  NextApr新推货值金额 ,
                  NextApr新推货值面积 ,

                       --5月份
                  NextMay可售货值金额 ,
                  NextMay可售货值面积 ,
                  NextMay新推货值金额 ,
                  NextMay新推货值面积 ,

                       --6月份
                  NextJun可售货值金额 ,
                  NextJun可售货值面积 ,
                  NextJun新推货值金额 ,
                  NextJun新推货值面积 ,

                       --7月份
                  NextJuly可售货值金额 ,
                  NextJuly可售货值面积 ,
                  NextJuly新推货值金额 ,
                  NextJuly新推货值面积 ,

                       --8月份
                  NextAug可售货值金额 ,
                  NextAug可售货值面积 ,
                  NextAug新推货值金额 ,
                  NextAug新推货值面积 ,

                       --9月份
                  NextSep可售货值金额 ,
                  NextSep可售货值面积 ,
                  NextSep新推货值金额 ,
                  NextSep新推货值面积 ,

                       --10月份
                  NextOct可售货值金额 ,
                  NextOct可售货值面积 ,
                  NextOct新推货值金额 ,
                  NextOct新推货值面积 ,

                       --11月份
                  NextNov可售货值金额 ,
                  NextNov可售货值面积 ,
                  NextNov新推货值金额 ,
                  NextNov新推货值面积 ,

                       --12月份
                  NextDec可售货值金额 ,
                  NextDec可售货值面积 ,
                  NextDec新推货值金额 ,
                  NextDec新推货值面积 ,
                  滞后货量金额 ,
                  滞后货量面积 ,
                  预计售价 ,
                  今年车位可售金额
                )
                SELECT  bi3.组织架构ID ,
                        bi3.组织架构名称 ,
                        bi3.组织架构编码 ,
                        bi3.组织架构类型 ,
                        SUM(ISNULL(phz.总货值金额, 0)) + SUM(ISNULL(phz2.总货值金额, 0)) ,
                        SUM(ISNULL(phz.总货值面积, 0)) + SUM(ISNULL(phz2.总货值面积, 0)) ,
                        SUM(ISNULL(phz.已售货量金额, 0)) + SUM(ISNULL(phz2.已售货量金额, 0)) ,
                        SUM(ISNULL(phz.已售货量面积, 0)) + SUM(ISNULL(phz2.已售货量面积, 0)) ,

                         --操盘项目
                        SUM(ISNULL(phz.总货值操盘金额, 0)) + SUM(ISNULL(phz2.总货值操盘金额, 0)) ,
                        SUM(ISNULL(phz.总货值操盘面积, 0)) + SUM(ISNULL(phz2.总货值操盘面积, 0)) ,
                        SUM(ISNULL(phz.已售货量操盘金额, 0)) + SUM(ISNULL(phz2.已售货量操盘金额, 0)) ,
                        SUM(ISNULL(phz.已售货量操盘面积, 0)) + SUM(ISNULL(phz2.已售货量操盘面积, 0)) ,

                        SUM(ISNULL(phz.未销售部分货量, 0)) + SUM(ISNULL(phz2.未销售部分货量,
                                                              0)) ,
                        SUM(ISNULL(phz.未销售部分可售面积, 0))
                        + SUM(ISNULL(phz2.未销售部分可售面积, 0)) ,
                        SUM(ISNULL(phz.剩余可售货值金额, 0))
                        + SUM(ISNULL(phz2.剩余可售货值金额, 0)) ,
                        SUM(ISNULL(phz.剩余可售货值面积, 0))
                        + SUM(ISNULL(phz2.剩余可售货值面积, 0)) , 
                        SUM(ISNULL(phz.工程达到可售未拿证货值金额, 0))
                        + SUM(ISNULL(phz2.工程达到可售未拿证货值金额, 0)) ,
                        SUM(ISNULL(phz.工程达到可售未拿证货值面积, 0))
                        + SUM(ISNULL(phz2.工程达到可售未拿证货值面积, 0)) ,
                        SUM(ISNULL(phz.获证未推货值金额, 0))
                        + SUM(ISNULL(phz2.获证未推货值金额, 0)) ,
                        SUM(ISNULL(phz.获证未推货值面积, 0))
                        + SUM(ISNULL(phz2.获证未推货值金额, 0)) ,
                        SUM(ISNULL(phz.已推未售货值金额, 0))
                        + SUM(ISNULL(phz2.已推未售货值金额, 0)) ,
                        SUM(ISNULL(phz.已推未售货值面积, 0))
                        + SUM(ISNULL(phz2.已推未售货值面积, 0)) ,

                        --操盘项目
                        SUM(ISNULL(phz.未销售部分操盘货量, 0)) + SUM(ISNULL(phz2.未销售部分操盘货量,
                                                              0)) AS 剩余货值金额操盘项目 ,
                        SUM(ISNULL(phz.未销售部分可售操盘面积, 0))
                        + SUM(ISNULL(phz2.未销售部分可售操盘面积, 0)) AS 剩余货值面积操盘项目 ,
                        SUM(ISNULL(phz.剩余可售货值操盘金额, 0))
                        + SUM(ISNULL(phz2.剩余可售货值操盘金额, 0)) AS 剩余可售货值金额操盘项目 ,
                        SUM(ISNULL(phz.剩余可售货值操盘面积, 0))
                        + SUM(ISNULL(phz2.剩余可售货值操盘面积, 0)) AS 剩余可售货值面积操盘项目 ,
                        SUM(ISNULL(phz.工程达到可售未拿证货值操盘金额, 0)) AS 工程达到可售未拿证货值金额操盘项目 ,
                        SUM(ISNULL(phz.工程达到可售未拿证货值操盘面积, 0)) AS 工程达到可售未拿证货值面积操盘项目 ,
                        SUM(ISNULL(phz.获证未推货值操盘金额, 0)) AS 获证未推货值金额操盘项目 ,
                        SUM(ISNULL(phz.获证未推货值操盘面积, 0)) AS 获证未推货值面积操盘项目 ,
                        SUM(ISNULL(phz.已推未售货值操盘金额, 0)) AS 已推未售货值金额操盘项目 ,
                        SUM(ISNULL(phz.已推未售货值操盘面积, 0)) AS 已推未售货值面积操盘项目 ,
						--年初可售
						SUM(ISNULL(phz.年初工程达到可售未拿证货值金额, 0))
                        + SUM(ISNULL(phz2.年初工程达到可售未拿证货值金额, 0)) ,
                        SUM(ISNULL(phz.年初工程达到可售未拿证货值面积, 0))
                        + SUM(ISNULL(phz2.年初工程达到可售未拿证货值面积, 0)) ,
                        SUM(ISNULL(phz.年初获证未推货值金额, 0))
                        + SUM(ISNULL(phz2.年初获证未推货值金额, 0)) ,
                        SUM(ISNULL(phz.年初获证未推货值面积, 0))
                        + SUM(ISNULL(phz2.年初获证未推货值金额, 0)) ,
                        SUM(ISNULL(phz.年初已推未售货值金额, 0))
                        + SUM(ISNULL(phz2.年初已推未售货值金额, 0)) , -- + SUM(ISNULL(月初可售货量金额,0)),
                        SUM(ISNULL(phz.年初已推未售货值面积, 0))
                        + SUM(ISNULL(phz2.年初已推未售货值面积, 0)) , --+SUM(ISNULL(月初可售货量面积,0)),

                        SUM(ISNULL(phzyc1.本月新货货量, 0))
                        + SUM(ISNULL(phzyc2.本月新货货量, 0)) AS 本月新货货量 ,
                        SUM(ISNULL(phzyc1.本月新货面积, 0))
                        + SUM(ISNULL(phzyc2.本月新货面积, 0)) AS 本月新货面积 ,
                        SUM(ISNULL(phzyc1.本年存货货量, 0))
                        + SUM(ISNULL(phzyc2.本年存货货量, 0)) AS 本年存货货量 ,
                        SUM(ISNULL(phzyc1.本年存货面积, 0))
                        + SUM(ISNULL(phzyc2.本年存货面积, 0)) AS 本年存货面积 ,
                        SUM(ISNULL(phz.后续预计达成货量金额, 0))
                        + SUM(ISNULL(phz2.后续预计达成货量金额, 0)) AS 后续预计达成货量金额 ,
                        SUM(ISNULL(phz.后续预计达成货量面积, 0))
                        + SUM(ISNULL(phz2.后续预计达成货量金额, 0)) AS 后续预计达成货量面积 ,
                        SUM(ISNULL(phz.今年后续预计达成货量金额, 0)) AS 今年后续预计达成货量金额 ,
                        SUM(ISNULL(phz.今年后续预计达成货量面积, 0)) AS 今年后续预计达成货量面积 ,

                                                                             --SUM(ISNULL(phz.本年可售货量金额, 0))
                                                                             --+ SUM(ISNULL(phz2.本年可售货量金额, 0))
                                                                             --+ SUM(ISNULL(phz3.月初可售货量金额, 0)) AS 本年可售货量金额 ,
                                                                             --SUM(ISNULL(phz.本年可售货量面积, 0))
                                                                             --+ SUM(ISNULL(phz2.本年可售货量面积, 0))
                                                                             --+ SUM(ISNULL(phz3.月初可售货量面积, 0)) AS 本年可售货量面积 ,
                        ( --年初
                          SUM(ISNULL(phz.年初工程达到可售未拿证货值金额, 0)
                              + ISNULL(phz2.年初工程达到可售未拿证货值金额, 0)
                              + ISNULL(phz.年初获证未推货值金额, 0)
                              + ISNULL(phz2.年初获证未推货值金额, 0)
                              + ISNULL(phz.年初已推未售货值金额, 0)
                              + ISNULL(phz2.年初已推未售货值金额, 0) + --新推
                  ISNULL(phzyc1.[1月新增可售金额], 0) + ISNULL(phzyc1.[2月新增可售金额], 0)
                              + ISNULL(phzyc1.[3月新增可售金额], 0)
                              + ISNULL(phzyc1.[4月新增可售金额], 0)
                              + ISNULL(phzyc1.[5月新增可售金额], 0)
                              + ISNULL(phzyc1.[6月新增可售金额], 0)
                              + ISNULL(phzyc1.[7月新增可售金额], 0)
                              + ISNULL(phzyc1.[8月新增可售金额], 0)
                              + ISNULL(phzyc1.[9月新增可售金额], 0)
                              + ISNULL(phzyc1.[10月新增可售金额], 0)
                              + ISNULL(phzyc1.[11月新增可售金额], 0)
                              + ISNULL(phzyc1.[12月新增可售金额], 0)
                              + ISNULL(phzyc2.[1月新增可售金额], 0)
                              + ISNULL(phzyc2.[2月新增可售金额], 0)
                              + ISNULL(phzyc2.[3月新增可售金额], 0)
                              + ISNULL(phzyc2.[4月新增可售金额], 0)
                              + ISNULL(phzyc2.[5月新增可售金额], 0)
                              + ISNULL(phzyc2.[6月新增可售金额], 0)
                              + ISNULL(phzyc2.[7月新增可售金额], 0)
                              + ISNULL(phzyc2.[8月新增可售金额], 0)
                              + ISNULL(phzyc2.[9月新增可售金额], 0)
                              + ISNULL(phzyc2.[10月新增可售金额], 0)
                              + ISNULL(phzyc2.[11月新增可售金额], 0)
                              + ISNULL(phzyc2.[12月新增可售金额], 0)) ) AS 本年可售货量金额 ,
                        SUM(( ISNULL(phz.年初工程达到可售未拿证货值面积, 0)
                              + ISNULL(phz2.年初工程达到可售未拿证货值面积, 0)
                              + ISNULL(phz.年初获证未推货值面积, 0)
                              + ISNULL(phz2.年初获证未推货值面积, 0)
                              + ISNULL(phz.年初已推未售货值面积, 0)
                              + ISNULL(phz2.年初已推未售货值面积, 0) + --新推
                  ISNULL(phzyc1.[1月新增可售面积], 0) + ISNULL(phzyc1.[2月新增可售面积], 0)
                              + ISNULL(phzyc1.[3月新增可售面积], 0)
                              + ISNULL(phzyc1.[4月新增可售面积], 0)
                              + ISNULL(phzyc1.[5月新增可售面积], 0)
                              + ISNULL(phzyc1.[6月新增可售面积], 0)
                              + ISNULL(phzyc1.[7月新增可售面积], 0)
                              + ISNULL(phzyc1.[8月新增可售面积], 0)
                              + ISNULL(phzyc1.[9月新增可售面积], 0)
                              + ISNULL(phzyc1.[10月新增可售面积], 0)
                              + ISNULL(phzyc1.[11月新增可售面积], 0)
                              + ISNULL(phzyc1.[12月新增可售面积], 0)
                              + ISNULL(phzyc2.[1月新增可售面积], 0)
                              + ISNULL(phzyc2.[2月新增可售面积], 0)
                              + ISNULL(phzyc2.[3月新增可售面积], 0)
                              + ISNULL(phzyc2.[4月新增可售面积], 0)
                              + ISNULL(phzyc2.[5月新增可售面积], 0)
                              + ISNULL(phzyc2.[6月新增可售面积], 0)
                              + ISNULL(phzyc2.[7月新增可售面积], 0)
                              + ISNULL(phzyc2.[8月新增可售面积], 0)
                              + ISNULL(phzyc2.[9月新增可售面积], 0)
                              + ISNULL(phzyc2.[10月新增可售面积], 0)
                              + ISNULL(phzyc2.[11月新增可售面积], 0)
                              + ISNULL(phzyc2.[12月新增可售面积], 0) )) AS 本年可售货量面积 ,
                        SUM(ISNULL(phz.本年剩余可售货量金额, 0))
                        + SUM(ISNULL(phz2.本年剩余可售货量金额, 0)) AS 本年剩余可售货量金额 ,
                        SUM(ISNULL(phz.本年剩余可售货量面积, 0))
                        + SUM(ISNULL(phz2.本年剩余可售货量面积, 0)) AS 本年剩余可售货量面积 ,
						SUM(ISNULL(phz.当前剩余可售货量金额, 0))
                        + SUM(ISNULL(phz2.当前剩余可售货量金额, 0)) AS 当前剩余可售货量金额 ,
                        SUM(ISNULL(phz.当前剩余可售货量面积, 0))
                        + SUM(ISNULL(phz2.当前剩余可售货量面积, 0)) AS 当前剩余可售货量面积 ,
                        SUM(ISNULL(phz.本年已售货量金额, 0))
                        + SUM(ISNULL(phz2.本年已售货量金额, 0)) AS 本年已售货量金额 ,
                        SUM(ISNULL(phz.本年已售货量面积, 0))
                        + SUM(ISNULL(phz2.本年已售货量面积, 0)) AS 本年已售货量面积 ,

                                                                             --货量计划
                        SUM(ISNULL(phz.Jan预计货量金额, 0))
                        + SUM(ISNULL(phz2.Jan预计货量金额, 0)) AS Jan预计货量金额 ,
                        SUM(ISNULL(phz.Jan实际货量金额, 0))
                        + SUM(ISNULL(phz2.Jan实际货量金额, 0)) AS Jan实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Jan预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Jan预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Jan实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Jan实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Jan预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Jan预计货量金额, 0)) )
                                  * 1.00
                        END AS Jan货量达成率 ,
                        SUM(ISNULL(phz.Feb预计货量金额, 0))
                        + SUM(ISNULL(phz2.Feb预计货量金额, 0)) AS Feb预计货量金额 ,
                        SUM(ISNULL(phz.Feb实际货量金额, 0))
                        + SUM(ISNULL(phz2.Feb实际货量金额, 0)) AS Feb实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Feb预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Feb预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Feb实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Feb实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Feb预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Feb预计货量金额, 0)) )
                                  * 1.00
                        END AS Feb货量达成率 ,
                        SUM(ISNULL(phz.Mar预计货量金额, 0))
                        + SUM(ISNULL(phz2.Mar预计货量金额, 0)) AS Mar预计货量金额 ,
                        SUM(ISNULL(phz.Mar实际货量金额, 0))
                        + SUM(ISNULL(phz2.Mar实际货量金额, 0)) AS Mar实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Mar预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Mar预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Mar实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Mar实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Mar预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Mar预计货量金额, 0)) )
                                  * 1.00
                        END AS Mar货量达成率 ,
                        SUM(ISNULL(phz.Apr预计货量金额, 0))
                        + SUM(ISNULL(phz2.Apr预计货量金额, 0)) AS Apr预计货量金额 ,
                        SUM(ISNULL(phz.Apr实际货量金额, 0))
                        + SUM(ISNULL(phz2.Apr实际货量金额, 0)) AS Apr实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Apr预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Apr预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Apr实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Apr实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Apr预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Apr预计货量金额, 0)) )
                                  * 1.00
                        END AS Apr货量达成率 ,
                        SUM(ISNULL(phz.May预计货量金额, 0))
                        + SUM(ISNULL(phz2.May预计货量金额, 0)) AS May预计货量金额 ,
                        SUM(ISNULL(phz.May实际货量金额, 0))
                        + SUM(ISNULL(phz2.May实际货量金额, 0)) AS May实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.May预计货量金额, 0))
                                    + SUM(ISNULL(phz2.May预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.May实际货量金额, 0))
                                    + SUM(ISNULL(phz2.May实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.May预计货量金额, 0))
                                      + SUM(ISNULL(phz2.May预计货量金额, 0)) )
                                  * 1.00
                        END AS May货量达成率 ,
                        SUM(ISNULL(phz.Jun预计货量金额, 0))
                        + SUM(ISNULL(phz2.Jun预计货量金额, 0)) AS Jun预计货量金额 ,
                        SUM(ISNULL(phz.Jun实际货量金额, 0))
                        + SUM(ISNULL(phz2.Jun实际货量金额, 0)) AS Jun实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Jun预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Jun预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Jun实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Jun实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Jun预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Jun预计货量金额, 0)) )
                                  * 1.00
                        END AS Jun货量达成率 ,
                        SUM(ISNULL(phz.July预计货量金额, 0))
                        + SUM(ISNULL(phz2.July预计货量金额, 0)) AS July预计货量金额 ,
                        SUM(ISNULL(phz.July实际货量金额, 0))
                        + SUM(ISNULL(phz2.July实际货量金额, 0)) AS July实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.July预计货量金额, 0))
                                    + SUM(ISNULL(phz2.July预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.July实际货量金额, 0))
                                    + SUM(ISNULL(phz2.July实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.July预计货量金额, 0))
                                      + SUM(ISNULL(phz2.July预计货量金额, 0)) )
                                  * 1.00
                        END AS July货量达成率 ,
                        SUM(ISNULL(phz.Aug预计货量金额, 0))
                        + SUM(ISNULL(phz2.Aug预计货量金额, 0)) AS Aug预计货量金额 ,
                        SUM(ISNULL(phz.Aug实际货量金额, 0))
                        + SUM(ISNULL(phz2.Aug实际货量金额, 0)) AS Aug实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Aug预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Aug预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Aug实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Aug实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Aug预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Aug预计货量金额, 0)) )
                                  * 1.00
                        END AS Aug货量达成率 ,
                        SUM(ISNULL(phz.Sep预计货量金额, 0))
                        + SUM(ISNULL(phz2.Sep预计货量金额, 0)) AS Sep预计货量金额 ,
                        SUM(ISNULL(phz.Sep实际货量金额, 0))
                        + SUM(ISNULL(phz2.Sep实际货量金额, 0)) AS Sep实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Sep预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Sep预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Sep实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Sep实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Sep预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Sep预计货量金额, 0)) )
                                  * 1.00
                        END AS Sep货量达成率 ,
                        SUM(ISNULL(phz.Oct预计货量金额, 0))
                        + SUM(ISNULL(phz2.Oct预计货量金额, 0)) AS Oct预计货量金额 ,
                        SUM(ISNULL(phz.Oct实际货量金额, 0))
                        + SUM(ISNULL(phz2.Oct实际货量金额, 0)) AS Oct实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Oct预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Oct预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Oct实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Oct实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Oct预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Oct预计货量金额, 0)) )
                                  * 1.00
                        END AS Oct货量达成率 ,
                        SUM(ISNULL(phz.Nov预计货量金额, 0))
                        + SUM(ISNULL(phz2.Nov预计货量金额, 0)) AS Nov预计货量金额 ,
                        SUM(ISNULL(phz.Nov实际货量金额, 0))
                        + SUM(ISNULL(phz2.Nov实际货量金额, 0)) AS Nov实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Nov预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Nov预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Nov实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Nov实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Nov预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Nov预计货量金额, 0)) )
                                  * 1.00
                        END AS Nov货量达成率 ,
                        SUM(ISNULL(phz.Dec预计货量金额, 0))
                        + SUM(ISNULL(phz2.Dec预计货量金额, 0)) AS Dec预计货量金额 ,
                        SUM(ISNULL(phz.Dec实际货量金额, 0))
                        + SUM(ISNULL(phz2.Dec实际货量金额, 0)) AS Dec实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.Dec预计货量金额, 0))
                                    + SUM(ISNULL(phz2.Dec预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.Dec实际货量金额, 0))
                                    + SUM(ISNULL(phz2.Dec实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.Dec预计货量金额, 0))
                                      + SUM(ISNULL(phz2.Dec预计货量金额, 0)) )
                                  * 1.00
                        END AS Dec货量达成率 ,
                        SUM(ISNULL(phz.本月预计货量金额, 0))
                        + SUM(ISNULL(phz2.本月预计货量金额, 0)) AS 本月预计货量金额 ,
                        SUM(ISNULL(phz.本月实际货量金额, 0))
                        + SUM(ISNULL(phz2.本月实际货量金额, 0)) AS 本月实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.本月预计货量金额, 0))
                                    + SUM(ISNULL(phz2.本月预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.本月实际货量金额, 0))
                                    + SUM(ISNULL(phz2.本月实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.本月预计货量金额, 0))
                                      + SUM(ISNULL(phz2.本月预计货量金额, 0)) ) * 1.00
                        END AS 本月货量达成率 ,
                        SUM(ISNULL(phz.本年预计货量金额, 0))
                        + SUM(ISNULL(phz2.本年预计货量金额, 0)) AS 本年预计货量金额 ,
                        SUM(ISNULL(phz.本年实际货量金额, 0))
                        + SUM(ISNULL(phz2.本年实际货量金额, 0)) AS 本年实际货量金额 ,
                        CASE WHEN ( SUM(ISNULL(phz.本年预计货量金额, 0))
                                    + SUM(ISNULL(phz2.本年预计货量金额, 0)) ) = 0
                             THEN 0
                             ELSE ( SUM(ISNULL(phz.本年实际货量金额, 0))
                                    + SUM(ISNULL(phz2.本年实际货量金额, 0)) )
                                  / ( SUM(ISNULL(phz.本年预计货量金额, 0))
                                      + SUM(ISNULL(phz2.本年预计货量金额, 0)) ) * 1.00
                        END AS 本年货量达成率 ,
                        SUM(ISNULL(phzyc1.[1月总可售金额], 0)
                            + ISNULL(phzyc2.[1月总可售金额], 0)) AS Jan可售货值金额 ,
                        SUM(ISNULL(phzyc1.[1月总可售面积], 0)
                            + ISNULL(phzyc2.[1月总可售面积], 0)) AS Jan可售货值面积 ,
                        SUM(ISNULL(phzyc1.[1月新增可售金额], 0)
                            + ISNULL(phzyc2.[1月新增可售金额], 0)) AS Jan新推货值金额 ,
                        SUM(ISNULL(phzyc1.[1月新增可售面积], 0)
                            + ISNULL(phzyc2.[1月新增可售面积], 0)) AS Jan新推货值面积 ,
                        SUM(ISNULL(phzyc1.[2月总可售金额], 0)
                            + ISNULL(phzyc2.[2月总可售金额], 0)) AS Feb可售货值金额 ,
                        SUM(ISNULL(phzyc1.[2月总可售面积], 0)
                            + ISNULL(phzyc2.[2月总可售面积], 0)) AS Feb可售货值面积 ,
                        SUM(ISNULL(phzyc1.[2月新增可售金额], 0)
                            + ISNULL(phzyc2.[2月新增可售金额], 0)) AS Feb新推货值金额 ,
                        SUM(ISNULL(phzyc1.[2月新增可售面积], 0)
                            + ISNULL(phzyc2.[2月新增可售面积], 0)) AS Feb新推货值面积 ,
                        SUM(ISNULL(phzyc1.[1月总可售金额], 0)
                            + ISNULL(phzyc1.[2月总可售金额], 0)
                            + ISNULL(phzyc2.[1月总可售金额], 0)
                            + ISNULL(phzyc2.[2月总可售金额], 0)) AS JanFeb可售货值金额 ,
                        SUM(ISNULL(phzyc1.[1月总可售面积], 0)
                            + ISNULL(phzyc1.[2月总可售面积], 0)
                            + ISNULL(phzyc2.[1月总可售面积], 0)
                            + ISNULL(phzyc2.[2月总可售面积], 0)) AS JanFeb可售货值面积 ,
                        SUM(ISNULL(phzyc1.[1月新增可售金额], 0)
                            + ISNULL(phzyc1.[2月新增可售金额], 0)
                            + ISNULL(phzyc2.[1月新增可售金额], 0)
                            + ISNULL(phzyc2.[2月新增可售金额], 0)) AS JanFeb新推货值金额 ,
                        SUM(ISNULL(phzyc1.[1月新增可售面积], 0)
                            + ISNULL(phzyc1.[2月新增可售面积], 0)
                            + ISNULL(phzyc2.[1月新增可售面积], 0)
                            + ISNULL(phzyc2.[2月新增可售面积], 0)) AS JanFeb新推货值面积 ,
                        SUM(ISNULL(phzyc1.[3月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[3月总可售金额], 0)) AS Mar可售货值金额 ,
                        SUM(ISNULL(phzyc1.[3月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[3月总可售面积], 0)) AS Mar可售货值面积 ,
                        SUM(ISNULL(phzyc1.[3月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[3月新增可售金额], 0)) AS Mar新推货值金额 ,
                        SUM(ISNULL(phzyc1.[3月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[3月新增可售面积], 0)) AS Mar新推货值面积 ,
                        SUM(ISNULL(phzyc1.[4月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[4月总可售金额], 0)) AS Apr可售货值金额 ,
                        SUM(ISNULL(phzyc1.[4月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[4月总可售面积], 0)) AS Apr可售货值面积 ,
                        SUM(ISNULL(phzyc1.[4月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[4月新增可售金额], 0)) AS Apr新推货值金额 ,
                        SUM(ISNULL(phzyc1.[4月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[4月新增可售面积], 0)) AS Apr新推货值面积 ,
                        SUM(ISNULL(phzyc1.[5月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[5月总可售金额], 0)) AS May可售货值金额 ,
                        SUM(ISNULL(phzyc1.[5月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[5月总可售面积], 0)) AS May可售货值面积 ,
                        SUM(ISNULL(phzyc1.[5月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[5月新增可售金额], 0)) AS May新推货值金额 ,
                        SUM(ISNULL(phzyc1.[5月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[5月新增可售面积], 0)) AS May新推货值面积 ,
                        SUM(ISNULL(phzyc1.[6月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[6月总可售金额], 0)) AS Jun可售货值金额 ,
                        SUM(ISNULL(phzyc1.[6月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[6月总可售面积], 0)) AS Jun可售货值面积 ,
                        SUM(ISNULL(phzyc1.[6月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[6月新增可售金额], 0)) AS Jun新推货值金额 ,
                        SUM(ISNULL(phzyc1.[6月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[6月新增可售面积], 0)) AS Jun新推货值面积 ,
                        SUM(ISNULL(phzyc1.[7月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[7月总可售金额], 0)) AS July可售货值金额 ,
                        SUM(ISNULL(phzyc1.[7月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[7月总可售面积], 0)) AS July可售货值面积 ,
                        SUM(ISNULL(phzyc1.[7月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[7月新增可售金额], 0)) AS July新推货值金额 ,
                        SUM(ISNULL(phzyc1.[7月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[7月新增可售面积], 0)) AS July新推货值面积 ,
                        SUM(ISNULL(phzyc1.[8月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[8月总可售金额], 0)) AS Aug可售货值金额 ,
                        SUM(ISNULL(phzyc1.[8月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[8月总可售面积], 0)) AS Aug可售货值面积 ,
                        SUM(ISNULL(phzyc1.[8月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[8月新增可售金额], 0)) AS Aug新推货值金额 ,
                        SUM(ISNULL(phzyc1.[8月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[8月新增可售面积], 0)) AS Aug新推货值面积 ,
                        SUM(ISNULL(phzyc1.[9月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[9月总可售金额], 0)) AS Sep可售货值金额 ,
                        SUM(ISNULL(phzyc1.[9月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[9月总可售面积], 0)) AS Sep可售货值面积 ,
                        SUM(ISNULL(phzyc1.[9月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[9月新增可售金额], 0)) AS Sep新推货值金额 ,
                        SUM(ISNULL(phzyc1.[9月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[9月新增可售面积], 0)) AS Sep新推货值面积 ,
                        SUM(ISNULL(phzyc1.[10月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[10月总可售金额], 0)) AS Oct可售货值金额 ,
                        SUM(ISNULL(phzyc1.[10月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[10月总可售面积], 0)) AS Oct可售货值面积 ,
                        SUM(ISNULL(phzyc1.[10月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[10月新增可售金额], 0)) AS Oct新推货值金额 ,
                        SUM(ISNULL(phzyc1.[10月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[10月新增可售面积], 0)) AS Oct新推货值面积 ,
                        SUM(ISNULL(phzyc1.[11月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[11月总可售金额], 0)) AS Nov可售货值金额 ,
                        SUM(ISNULL(phzyc1.[11月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[11月总可售面积], 0)) AS Nov可售货值面积 ,
                        SUM(ISNULL(phzyc1.[11月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[11月新增可售金额], 0)) AS Nov新推货值金额 ,
                        SUM(ISNULL(phzyc1.[11月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[11月新增可售面积], 0)) AS Nov新推货值面积 ,
                        SUM(ISNULL(phzyc1.[12月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[12月总可售金额], 0)) AS Dec可售货值金额 ,
                        SUM(ISNULL(phzyc1.[12月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[12月总可售面积], 0)) AS Dec可售货值面积 ,
                        SUM(ISNULL(phzyc1.[12月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[12月新增可售金额], 0)) AS Dec新推货值金额 ,
                        SUM(ISNULL(phzyc1.[12月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[12月新增可售面积], 0)) AS Dec新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next1月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next1月总可售金额], 0)) AS NextJan可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next1月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next1月总可售面积], 0)) AS NextJan可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next1月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next1月新增可售金额], 0)) AS NextJan新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next1月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next1月新增可售面积], 0)) AS NextJan新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next2月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next2月总可售金额], 0)) AS NextFeb可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next2月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next2月总可售面积], 0)) AS NextFeb可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next2月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next2月新增可售金额], 0)) AS NextFeb新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next2月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next2月新增可售面积], 0)) AS NextFeb新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next1月总可售金额], 0))
                        + SUM(ISNULL(phzyc1.[Next2月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next1月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next2月总可售金额], 0)) AS NextJanFeb可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next1月总可售面积], 0))
                        + SUM(ISNULL(phzyc1.[Next2月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next1月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next2月总可售面积], 0)) AS NextJanFeb可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next1月新增可售金额], 0))
                        + SUM(ISNULL(phzyc1.[Next2月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next1月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next2月新增可售金额], 0)) AS NextJanFeb新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next1月新增可售面积], 0))
                        + SUM(ISNULL(phzyc1.[Next2月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next1月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next2月新增可售面积], 0)) AS NextJanFeb新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next3月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next3月总可售金额], 0)) AS NextMar可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next3月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next3月总可售面积], 0)) AS NextMar可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next3月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next3月新增可售金额], 0)) AS NextMar新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next3月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next3月新增可售面积], 0)) AS NextMar新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next4月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next4月总可售金额], 0)) AS NextApr可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next4月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next4月总可售面积], 0)) AS NextApr可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next4月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next4月新增可售金额], 0)) AS NextApr新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next4月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next4月新增可售面积], 0)) AS NextApr新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next5月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next5月总可售金额], 0)) AS NextMay可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next5月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next5月总可售面积], 0)) AS NextMay可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next5月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next5月新增可售金额], 0)) AS NextMay新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next5月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next5月新增可售面积], 0)) AS NextMay新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next6月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next6月总可售金额], 0)) AS NextJun可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next6月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next6月总可售面积], 0)) AS NextJun可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next6月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next6月新增可售金额], 0)) AS NextJun新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next6月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next6月新增可售金额], 0)) AS NextJun新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next7月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next7月总可售金额], 0)) AS NextJuly可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next7月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next7月总可售面积], 0)) AS NextJuly可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next7月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next7月新增可售金额], 0)) AS NextJuly新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next7月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next7月新增可售面积], 0)) AS NextJuly新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next8月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next8月总可售金额], 0)) AS NextAug可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next8月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next8月总可售面积], 0)) AS NextAug可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next8月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next8月新增可售金额], 0)) AS NextAug新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next8月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next8月新增可售面积], 0)) AS NextAug新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next9月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next9月总可售金额], 0)) AS NextSep可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next9月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next9月总可售面积], 0)) AS NextSep可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next9月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next9月新增可售金额], 0)) AS NextSep新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next9月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next9月新增可售面积], 0)) AS NextSep新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next10月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next10月总可售金额], 0)) AS NextOct可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next10月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next10月总可售面积], 0)) AS NextOct可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next10月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next10月新增可售金额], 0)) AS NextOct新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next10月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next10月新增可售面积], 0)) AS NextOct新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next11月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next11月总可售金额], 0)) AS NextNov可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next11月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next11月总可售面积], 0)) AS NextNov可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next11月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next11月新增可售金额], 0)) AS NextNov新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next11月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next11月新增可售面积], 0)) AS NextNov新推货值面积 ,
                        SUM(ISNULL(phzyc1.[Next12月总可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next12月总可售金额], 0)) AS NextDec可售货值金额 ,
                        SUM(ISNULL(phzyc1.[Next12月总可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next12月总可售面积], 0)) AS NextDec可售货值面积 ,
                        SUM(ISNULL(phzyc1.[Next12月新增可售金额], 0))
                        + SUM(ISNULL(phzyc2.[Next12月新增可售金额], 0)) AS NextDec新推货值金额 ,
                        SUM(ISNULL(phzyc1.[Next12月新增可售面积], 0))
                        + SUM(ISNULL(phzyc2.[Next12月新增可售面积], 0)) AS NextDec新推货值面积 ,
                        SUM(ISNULL(phz.滞后货量金额, 0)) AS 滞后货量金额 ,
                        SUM(ISNULL(phz.滞后货量面积, 0)) AS 滞后货量面积 ,
                        0 AS '预计售价' ,
                        SUM(ISNULL(phz.今年车位可售金额, 0)) AS 今年车位可售金额
                FROM    erp25.dbo.ydkb_BaseInfo bi
                        INNER JOIN ydkb_BaseInfo bi2 ON bi2.组织架构ID = bi.组织架构父级ID
                        INNER JOIN ydkb_BaseInfo bi3 ON bi3.组织架构ID = bi2.组织架构父级ID
                        LEFT JOIN #Porjhz phz ON phz.组织架构ID = bi.组织架构ID
                        LEFT JOIN #Porjhz2 phz2 ON phz2.组织架构ID = bi.组织架构ID
                        LEFT JOIN #projhzyc phzyc1 ON phzyc1.组织架构ID = bi.组织架构ID
                        LEFT JOIN #projhzyc2 phzyc2 ON phzyc2.组织架构ID = bi.组织架构ID
                        LEFT JOIN #Porjhz3 phz3 ON phz3.组织架构ID = bi.组织架构ID
                WHERE   bi.组织架构类型 = 3 AND bi.组织架构ID NOT IN   (SELECT  ProjGUID FROM    s_hndjdgProjList)
                GROUP BY bi3.组织架构ID ,
                        bi3.组织架构名称 ,
                        bi3.组织架构编码 ,
                        bi3.组织架构类型;

    --计算平均去化周期
        UPDATE  a
        SET     a.存货预计去化周期 = ISNULL(b.存货预计去化周期, 0) ,
                a.月平均销售面积 = ISNULL(b.月平均销售面积, 0)
        FROM    ydkb_dthz a
                LEFT JOIN ( SELECT  bi2.组织架构ID ,
                                    SUM(a.存货预计去化周期) / COUNT(1) AS 存货预计去化周期 ,
                                    SUM(a.月平均销售面积) / COUNT(1) AS 月平均销售面积
                            FROM    ydkb_dthz a
                                    LEFT JOIN ydkb_BaseInfo bi ON a.组织架构ID = bi.组织架构ID
                                    LEFT JOIN ydkb_BaseInfo bi2 ON bi2.组织架构ID = bi.组织架构父级ID
                            WHERE   ( ISNULL(存货预计去化周期, 0) BETWEEN 10 AND 100 )
                                    AND ISNULL(a.存货预计去化周期, 0) <> 0
                                    AND ISNULL(月平均销售面积, 0) > 0
                                    AND a.组织架构类型 = 2
                            GROUP BY bi2.组织架构ID
                          ) b ON a.组织架构ID = b.组织架构ID
        WHERE   a.组织架构类型 = 1;
        
        
      


    --查询结果数据
        SELECT  a.组织架构ID ,
                a.组织架构名称 ,
                a.组织架构编码 ,
                a.组织架构类型 ,
                总货值金额 ,
                总货值面积 ,
                已售货量金额 ,
                已售货量面积 ,
           --操盘项目
                总货值金额操盘项目 ,
                总货值面积操盘项目 ,
                已售货量金额操盘项目 ,
                已售货量面积操盘项目 ,
                b.剩余货值金额 ,
                b.剩余货值面积 ,
                剩余可售货值金额 ,
                剩余可售货值面积 ,
                年初工程达到可售未拿证货值金额 ,
                年初工程达到可售未拿证货值面积 ,
                年初获证未推货值金额 ,
                年初获证未推货值面积 ,
                年初已推未售货值金额 ,
                年初已推未售货值面积 ,
                工程达到可售未拿证货值金额 ,
                工程达到可售未拿证货值面积 ,
                获证未推货值金额 ,
                获证未推货值面积 ,
                已推未售货值金额 ,
                已推未售货值面积 ,

           --操盘项目
                剩余货值金额操盘项目 ,
                剩余货值面积操盘项目 ,
                剩余可售货值金额操盘项目 ,
                剩余可售货值面积操盘项目 ,
                工程达到可售未拿证货值金额操盘项目 ,
                工程达到可售未拿证货值面积操盘项目 ,
                获证未推货值金额操盘项目 ,
                获证未推货值面积操盘项目 ,
                已推未售货值金额操盘项目 ,
                已推未售货值面积操盘项目 ,
                本月新货货量 ,
                本月新货面积 ,
                本年存货货量 ,
                本年存货面积 ,
                后续预计达成货量金额 ,
                后续预计达成货量面积 ,
                今年后续预计达成货量金额 ,
                今年后续预计达成货量面积 ,
                本年可售货量金额 ,
                本年可售货量面积 ,
                本年剩余可售货量金额 ,
                本年剩余可售货量面积 ,
				当前剩余可售货量金额 ,
                当前剩余可售货量面积 ,
                本年已售货量金额 ,
                本年已售货量面积 ,
                Jan预计货量金额 ,
                Jan实际货量金额 ,
                Jan货量达成率 ,
                Feb预计货量金额 ,
                Feb实际货量金额 ,
                Feb货量达成率 ,
                Mar预计货量金额 ,
                Mar实际货量金额 ,
                Mar货量达成率 ,
                Apr预计货量金额 ,
                Apr实际货量金额 ,
                Apr货量达成率 ,
                May预计货量金额 ,
                May实际货量金额 ,
                May货量达成率 ,
                Jun预计货量金额 ,
                Jun实际货量金额 ,
                Jun货量达成率 ,
                July预计货量金额 ,
                July实际货量金额 ,
                July货量达成率 ,
                Aug预计货量金额 ,
                Aug实际货量金额 ,
                Aug货量达成率 ,
                Sep预计货量金额 ,
                Sep实际货量金额 ,
                Sep货量达成率 ,
                Oct预计货量金额 ,
                Oct实际货量金额 ,
                Oct货量达成率 ,
                Nov预计货量金额 ,
                Nov实际货量金额 ,
                Nov货量达成率 ,
                Dec预计货量金额 ,
                Dec实际货量金额 ,
                Dec货量达成率 ,
                本月预计货量金额 ,
                本月实际货量金额 ,
                本月货量达成率 ,
                本年预计货量金额 ,
                本年实际货量金额 ,
                本年货量达成率 ,
                JanFeb可售货值金额 ,
                JanFeb可售货值面积 ,
                JanFeb新推货值金额 ,
                JanFeb新推货值面积 ,
                Mar可售货值金额 ,
                Mar可售货值面积 ,
                Mar新推货值金额 ,
                Mar新推货值面积 ,
                Apr可售货值金额 ,
                Apr可售货值面积 ,
                Apr新推货值金额 ,
                Apr新推货值面积 ,
                May可售货值金额 ,
                May可售货值面积 ,
                May新推货值金额 ,
                May新推货值面积 ,
                Jun可售货值金额 ,
                Jun可售货值面积 ,
                Jun新推货值金额 ,
                Jun新推货值面积 ,
                July可售货值金额 ,
                July可售货值面积 ,
                July新推货值金额 ,
                July新推货值面积 ,
                Aug可售货值金额 ,
                Aug可售货值面积 ,
                Aug新推货值金额 ,
                Aug新推货值面积 ,
                Sep可售货值金额 ,
                Sep可售货值面积 ,
                Sep新推货值金额 ,
                Sep新推货值面积 ,
                Oct可售货值金额 ,
                Oct可售货值面积 ,
                Oct新推货值金额 ,
                Oct新推货值面积 ,
                Nov可售货值金额 ,
                Nov可售货值面积 ,
                Nov新推货值金额 ,
                Nov新推货值面积 ,
                Dec可售货值金额 ,
                Dec可售货值面积 ,
                Dec新推货值金额 ,
                Dec新推货值面积 ,
                月平均销售面积 ,
                存货预计去化周期 ,
                未开工部分预计达到预售条件周期 ,
                存货同预计达到预售条件时间差 ,
                滞后货量金额 ,
                滞后货量面积 ,
                预计达到预售形象日期 ,
                实际达到预售形象日期 ,
                预计预售办理日期 ,
                实际预售办理日期 ,
                预计售价 ,
                今年车位可售金额
        FROM    ydkb_BaseInfo a
                INNER JOIN ydkb_dthz b ON a.组织架构编码 = b.组织架构编码
    --WHERE   a.组织架构编码 LIKE 'bldc.002%'
        ORDER BY a.组织架构编码 ,
                a.组织架构类型;

    END;

