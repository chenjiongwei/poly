USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_gsfkylbhzb]    Script Date: 2025/12/4 15:01:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROC [dbo].[usp_s_gsfkylbhzb]
(
    @var_buguid VARCHAR(MAX),
    @var_endDate DATETIME
)
AS /*
 公司房款一览汇总表
 2019-10-28 chenjw 修改
 1、增加特殊业绩回笼统计
 2019-11-13 chenjw 修改
 2、如果项目状态“代建”的则不统计认购签约中的回笼，只统计特殊业绩的回笼。销售金额正常统计
 2019-12-18 chenjw 修改
 1、累计回笼金额、本年回笼金额、本月回笼金额统计时按照特殊业绩项目统计口径定义设置的规则进行统计S_PerformanceProjectSet
①只勾选”是否取房间特殊业绩回笼金额”： 《公司房款一览汇总表（集团考核用）》关联特殊业绩的房间和楼栋只统计房间明细收款金额，不再统计特殊业绩模块中录入的回笼金额。
②只勾选“是否取特殊业绩模块特殊业绩回笼”： 《公司房款一览汇总表（集团考核用）》关联特殊业绩的房间和楼栋只统计特殊业绩模块中录入的回笼金额，不再统计房间下的明细收款金额。
③同时勾选：《公司房款一览汇总表（集团考核用）》关联特殊业绩的房间和楼栋同时从房间明细回笼和特殊业绩模块录入回笼金额中取数，特殊业绩房间的回笼金额为两者相加。
④都不勾选：《公司房款一览汇总表（集团考核用）》关联特殊业绩的房间和楼栋回笼金额为0。

2020-06-20 chenjw 增加本年签约本年回笼金额的统计
2020-7-27 yp 调整特殊业绩金额时间判断逻辑（原来按认定日期，现在改为单据缴费日期）
2020-12-05 yp 区分经营类特殊业绩
20210621 z 修改是否计算回笼的逻辑，如果项目标签的是否计算回笼为是，则计算，否则不计算
20220517 jst 修改“不包含在合作项目和操盘项目里的特殊业绩”的项目“签约累计待收款”,原来默认为0
20220519 jst 
1、修改“不包含在合作项目和操盘项目里的特殊业绩”的项目 只筛选已审核的
2、增加签约未回笼金额正常待收款非按揭待收款、签约未回笼金额正常待收款按揭待收款、签约未回笼金额逾期待收款非按揭待收款、签约未回笼金额逾期待收款按揭待收款 四个字段
3、修改是否计算回笼的逻辑，如果项目标签的是否计算回笼为是，则计算，否则待收款、回笼都不计算
4、过滤部分没有回笼的项目
5、“不包含在合作项目和操盘项目里的特殊业绩”的项目剔除关联房间或楼栋的项目
6、计算操盘项目特殊业绩字段时，只统计关联房间部分的单据
20220523 jst 计算特殊业绩累计回笼，区分经营类特殊业绩
B10_1 累计经营类特殊业绩：改为经营类（租金）： 只算  经营类(租金)
B10 累计关联房间特殊业绩：不剔除 ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
B11 累计不关联房间特殊业绩：不剔除 ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
20220608 jst
1、增加字段“累计特殊业绩待收款” 。统计特殊业绩关联房间/楼栋的部分的待收款
20220719 jst
计算待收款剔除 '经营类(租金)'类
20240123 z
增加合作业绩本年回笼中的新签约回笼数据逻辑
2025-04-25 zhengyy 修改物业公司车位代销类型的特殊业绩统计房间回款
*/
BEGIN

    --特殊业绩的房间
    SELECT DISTINCT
           s.ManagementProjectGUID,
           s.PerformanceAppraisalGUID
    INTO #tsyjzqy_temp01
    FROM p_room r
         INNER JOIN dbo.S_PerformanceAppraisalRoom sr ON sr.RoomGUID = r.RoomGUID
         INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                    AND s.AuditStatus = '已审核'
                                                    AND s.yjtype NOT IN ( '经营类(溢价款)', '物业公司车位代销' )
    --AND s.YjType <> '经营类(租金)'
    UNION ALL
    SELECT DISTINCT
           s.ManagementProjectGUID,
           s.PerformanceAppraisalGUID
    FROM p_room r
         INNER JOIN dbo.S_PerformanceAppraisalBuildings sr ON sr.BldGUID = r.BldGUID
         INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                    AND s.AuditStatus = '已审核'
                                                    AND s.yjtype NOT IN ( '经营类(溢价款)', '物业公司车位代销' );
    --AND s.YjType <> '经营类(租金)';

    SELECT DISTINCT
           ManagementProjectGUID projectGUID,
           PerformanceAppraisalGUID
    INTO #tsyjzqy --特殊业绩房间明细
    FROM #tsyjzqy_temp01;
    DROP TABLE #tsyjzqy_temp01;
    ---获取项目的回笼标识
    SELECT mp.ProjGUID,
           mp.ProjCode,
           mp.ProjName,
           mp.ProjStatus,
           mp.TradersWay,
           mp.BbWay,
           mp.Level,
           mp.DevelopmentCompanyGUID,
           b.LbProjectValue sfjshl,
           f.是否录入合作业绩,
           CASE
               WHEN f.项目状态 IN ( '清算退出', '跟进待落实' )
                    OR
                    (
                        f.管理方式 IN ( '一级整理', '代建', '代管' )
                        AND f.projguid NOT IN ( '4168DFEA-F47F-E811-80BF-E61F13C57837',
                                                'DBDC02D2-9D51-EB11-B398-F40270D39969',
                                                '0032F5A7-9450-EA11-80B8-0A94EF7517DD',
                                                '2ABA731B-F11D-E911-80BF-E61F13C57837',
                                                '4AB775FA-2EE1-EA11-80B8-0A94EF7517DD',
                                                '6AC77D4C-C457-E711-80BA-E61F13C57837',
                                                '7E3C6BFB-69E5-E711-80BA-E61F13C57837',
                                                '53D1C866-F76A-E811-80BF-E61F13C57837',
                                                '0A0DCCF4-237D-E911-80B7-0A94EF7517DD',
                                                'EEF28B36-247D-E911-80B7-0A94EF7517DD'
                                              )
                    )
           --如下项目代建，算入待收款
           THEN
                    '否'
               ELSE '是'
           END 是否计算回笼按规则判断
    INTO #md
    FROM dbo.mdm_Project mp
         LEFT JOIN mdm_LbProject b ON mp.ProjGUID = b.projGUID
                                      AND b.LbProject = 'sfjshl'
         LEFT JOIN vmdm_projectflag f ON f.projguid = b.projguid
    WHERE mp.Level = 2;


    ---统计操盘项目
    SELECT @var_endDate AS qxDate,
           t1.BUGUID,
           t1.公司名称,
           t1.销售项目名称,
           t1.投管项目代码,
           t1.投管项目名称,
           t1.操盘方式,
           t1.并表方式,
           t1.项目权益比例,
           t1.项目标签是否计算回笼,                 --20240428新增
                                          -- '操盘项目'项目类型,                               --累计签约
           '销售业绩' AS 业绩类型,
           SUM(t1.房间成交金额) / 10000 AS 累计房间成交金额,
           SUM(t1.装修款) / 10000 AS 累计装修款,
           SUM(t1.附属房间成交金额) / 10000 AS 累计附属房间成交金额,
           SUM(t1.补差款) / 10000 AS 累计补差款,
           SUM(t1.交易金额) / 10000 AS 累计交易金额,
           SUM(t1.签约金额) / 10000 AS 累计签约金额,


                                          --累计回笼
           SUM(t1.应退未退累计金额) / 10000 AS 应退未退累计金额,
           SUM(t1.签约累计回笼金额) / 10000 AS 累计回笼金额签约,
           SUM(t1.认购累计回笼金额) / 10000 AS 累计回笼金额认购,
           SUM(t1.其中补差款累计回笼金额) / 10000 AS 累计回笼金额其中补差款,
           SUM(t1.累计签约按揭回笼金额) / 10000 AS 累计回笼金额签约按揭,
           SUM(t1.累计认购按揭回笼金额) / 10000 AS 累计回笼金额认购按揭,
           SUM(t1.累计签约非按揭回笼金额) / 10000 AS 累计回笼金额签约非按揭,
           SUM(t1.累计认购非按揭回笼金额) / 10000 AS 累计回笼金额认购非按揭,

                                          --本年
           SUM(t1.应退未退本年金额) / 10000 AS 应退未退本年金额,
           SUM(t1.签约本年回笼金额) / 10000 AS 本年回笼金额签约,
           SUM(t1.认购本年回笼金额) / 10000 AS 本年回笼金额认购,
           SUM(t1.其中补差款本年回笼金额) / 10000 AS 本年回笼金额其中补差款,
           SUM(t1.本年签约按揭回笼金额) / 10000 AS 本年回笼金额签约按揭,
           SUM(t1.本年认购按揭回笼金额) / 10000 AS 本年回笼金额认购按揭,
           SUM(t1.本年签约非按揭回笼金额) / 10000 AS 本年回笼金额签约非按揭,
           SUM(t1.本年认购非按揭回笼金额) / 10000 AS 本年回笼金额认购非按揭,
                                          --本月
           SUM(t1.应退未退本月金额) / 10000 AS 应退未退本月金额,
           SUM(t1.签约本月回笼金额) / 10000 AS 本月回笼金额签约,
           SUM(t1.认购本月回笼金额) / 10000 AS 本月回笼金额认购,
           SUM(t1.其中补差款本月回笼金额) / 10000 AS 本月回笼金额其中补差款,
           SUM(t1.本月签约按揭回笼金额) / 10000 AS 本月回笼金额签约按揭,
           SUM(t1.本月认购按揭回笼金额) / 10000 AS 本月回笼金额认购按揭,
           SUM(t1.本月签约非按揭回笼金额) / 10000 AS 本月回笼金额签约非按揭,
           SUM(t1.本月认购非按揭回笼金额) / 10000 AS 本月回笼金额认购非按揭,

                                          --本月签约本月回笼
           SUM(t1.本月签约本月回笼非按揭回笼) / 10000 AS 本月签约本月回笼非按揭回笼,
           SUM(t1.本月签约本月回笼按揭回笼) / 10000 AS 本月签约本月回笼按揭回笼,
           SUM(t1.本月签约本月回笼回笼合计) / 10000 AS 本月签约本月回笼回笼合计,

                                          --本年签约本月回笼
           SUM(t1.本年签约本月回笼非按揭回笼) / 10000 AS 本年签约本月回笼非按揭回笼,
           SUM(t1.本年签约本月回笼按揭回笼) / 10000 AS 本年签约本月回笼按揭回笼,
           SUM(t1.本年签约本月回笼回笼合计) / 10000 AS 本年签约本月回笼回笼合计,

                                          --待收款
           SUM(   CASE
                      WHEN t1.销售状态 = '签约' THEN
                           t1.正常非按揭待收款
                      ELSE 0
                  END
              ) / 10000 AS 未回笼金额正常待收款非按揭待收款,
           SUM(   CASE
                      WHEN t1.销售状态 = '签约' THEN
                           t1.正常按揭待收款
                      ELSE 0
                  END
              ) / 10000 AS 未回笼金额正常待收款按揭待收款,
           SUM(t1.签约正常非按揭待收款) / 10000 AS 签约未回笼金额正常待收款非按揭待收款,
           SUM(t1.签约正常按揭待收款) / 10000 AS 签约未回笼金额正常待收款按揭待收款,
           SUM(   CASE
                      WHEN t1.销售状态 = '签约' THEN
                           t1.正常待收款
                      ELSE 0
                  END
              ) / 10000 AS 未回笼金额正常待收款合计,
           SUM(   CASE
                      WHEN t1.销售状态 = '签约' THEN
                           t1.非按揭逾期待收款
                      ELSE 0
                  END
              ) / 10000 AS 未回笼金额逾期待收款非按揭逾期待收款,
           SUM(   CASE
                      WHEN t1.销售状态 = '签约' THEN
                           t1.按揭逾期待收款
                      ELSE 0
                  END
              ) / 10000 AS 未回笼金额逾期待收款按揭逾期待收款,
           SUM(t1.签约非按揭逾期待收款) / 10000 AS 签约未回笼金额逾期待收款非按揭逾期待收款,
           SUM(t1.签约按揭逾期待收款) / 10000 AS 签约未回笼金额逾期待收款按揭逾期待收款,
           SUM(   CASE
                      WHEN t1.销售状态 = '签约' THEN
                           t1.逾期合计
                      ELSE 0
                  END
              ) / 10000 AS 未回笼金额逾期待收款逾期合计,
           SUM(t1.待收房款合计) / 10000 AS 待收款合计,
           SUM(t1.其中待收补差款合计) / 10000 AS 其中待收补差款合计,
           CASE
               WHEN ISNULL(SUM(t1.签约金额), 0) = 0 THEN
                    0
               ELSE SUM(t1.签约累计回笼金额) * 1.00 / SUM(t1.签约金额)
           END AS 房款回笼率,                  ---签约累计回笼金额/累计签约额		
           CONVERT(MONEY, 0) AS 房款逾期率,    --1 - 签约本月回笼金额/(累计应收-月初实收)
           CONVERT(MONEY, 0) AS 非按揭房款逾期率, --1- 非按揭实收/(非按揭累计应收-非按揭月初实收)
           CONVERT(MONEY, 0) AS '累计回笼金额大于累计认购金额',
           CONVERT(MONEY, 0) AS '逾期款加正常款不等于总额',
           CONVERT(MONEY, 0) AS '按揭款加非按揭款不等于总额',
           CONVERT(MONEY, 0) AS [累计预收款],
           CONVERT(MONEY, 0) AS [本年预收款],
           CONVERT(MONEY, 0) AS [本月预收款],
           SUM(t1.[关闭交易本年退款金额]) / 10000 AS [关闭交易本年退款金额],
           SUM(t1.[关闭交易本月退款金额]) / 10000 AS [关闭交易本月退款金额],
           SUM(t1.[认购累计待收款]) / 10000 AS [认购累计待收款],
           SUM(t1.[签约累计待收款]) / 10000 AS [签约累计待收款],

                                          --本日
           SUM(t1.应退未退本日金额) / 10000 AS 应退未退本日金额,
           SUM(t1.签约本日回笼金额) / 10000 AS 本日回笼金额签约,
           SUM(t1.认购累计本日金额) / 10000 AS 本日回笼金额认购,
           SUM(t1.关闭交易本日退款金额) / 10000 AS 关闭交易本日退款金额,
           (
               SELECT STUFF(
                      (
                          SELECT DISTINCT
                                 ',' + CONVERT(VARCHAR(200), a.ProjStatus)
                          FROM ERP25.dbo.mdm_Project a
                          WHERE t1.topprojguid = ISNULL(a.ParentProjGUID, a.ImportSaleProjGUID)
                          FOR XML PATH('')
                      ),
                      1,
                      1,
                      ''
                           )
           ) AS 项目状态,
           t1.topprojguid,
                                          --本年签约
           SUM(   CASE
                      WHEN DATEDIFF(yy, @var_endDate, t1.签署日期) = 0 THEN
                           t1.房间成交金额
                      ELSE 0
                  END
              ) / 10000 AS 本年房间成交金额,
           SUM(   CASE
                      WHEN DATEDIFF(yy, @var_endDate, t1.签署日期) = 0 THEN
                           t1.装修款
                      ELSE 0
                  END
              ) / 10000 AS 本年装修款,
           SUM(   CASE
                      WHEN DATEDIFF(yy, @var_endDate, t1.签署日期) = 0 THEN
                           t1.附属房间成交金额
                      ELSE 0
                  END
              ) / 10000 AS 本年附属房间成交金额,
           SUM(   CASE
                      WHEN DATEDIFF(yy, @var_endDate, t1.签署日期) = 0 THEN
                           t1.补差款
                      ELSE 0
                  END
              ) / 10000 AS 本年补差款,
           SUM(   CASE
                      WHEN DATEDIFF(yy, @var_endDate, t1.签署日期) = 0 THEN
                           t1.交易金额
                      ELSE 0
                  END
              ) / 10000 AS 本年交易金额,
           SUM(   CASE
                      WHEN DATEDIFF(yy, @var_endDate, t1.签署日期) = 0 THEN
                           t1.签约金额
                      ELSE 0
                  END
              ) / 10000 AS 本年签约金额,
           CONVERT(MONEY, 0) AS 累计特殊业绩待收款,
           CONVERT(MONEY, 0) AS 累计特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 累计经营类特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 累计特殊业绩未关联房间,
           CONVERT(MONEY, 0) AS 本年特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 本年经营类特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 本年特殊业绩未关联房间,
           CONVERT(MONEY, 0) AS 本月特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 本月经营类特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 本月特殊业绩未关联房间,
           CONVERT(MONEY, 0) AS 本日特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 本日经营类特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 本日特殊业绩未关联房间,

                                          --本年签约本年回笼
           SUM(t1.本年签约本年回笼非按揭回笼) / 10000 AS 本年签约本年回笼非按揭回笼,
           SUM(t1.本年签约本年回笼按揭回笼) / 10000 AS 本年签约本年回笼按揭回笼,
           SUM(t1.本年签约本年回笼回笼合计) / 10000 AS 本年签约本年回笼回笼合计
    INTO #temp1
    FROM
    (
        SELECT qxDate,
               s.BUGUID,
               topprojguid,
               公司名称,
               销售项目名称,
               投管项目代码,
               投管项目名称,
               操盘方式,
               并表方式,
               项目权益比例,
               mp.是否计算回笼按规则判断 AS 项目标签是否计算回笼, --20240428新增
               房间成交金额,
               装修款,
               附属房间成交金额,
               补差款,
               交易金额,
               签约金额,
               签署日期,
               销售状态,
                                             --累计
               应退未退累计金额,
               签约累计回笼金额,
               认购累计回笼金额,
               其中补差款累计回笼金额,
               累计签约按揭回笼金额,
               累计认购按揭回笼金额,
               累计签约非按揭回笼金额,
               累计认购非按揭回笼金额,
                                             --CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --         0
                                             --    ELSE 应退未退累计金额
                                             --END AS 应退未退累计金额, 
                                             --CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --        0
                                             --   ELSE 签约累计回笼金额
                                             --END AS 签约累计回笼金额,
                                             -- CASE
                                             --     WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --          0
                                             --     ELSE 认购累计回笼金额
                                             --END AS 认购累计回笼金额,
                                             -- CASE
                                             ---    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --      0
                                             --ELSE 其中补差款累计回笼金额
                                             --END AS 其中补差款累计回笼金额,
                                             --  CASE
                                             --      WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --      ELSE 累计签约按揭回笼金额
                                             --  END AS 累计签约按揭回笼金额,
                                             --  CASE
                                             --     WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --          0
                                             --      ELSE 累计认购按揭回笼金额
                                             --  END AS 累计认购按揭回笼金额,
                                             --  CASE
                                             --     WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --          0
                                             --     ELSE 累计签约非按揭回笼金额
                                             -- END AS 累计签约非按揭回笼金额,
                                             -- CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --         0
                                             --   ELSE 累计认购非按揭回笼金额
                                             -- END AS 累计认购非按揭回笼金额,

                                             --本年
               应退未退本年金额,
               签约本年回笼金额,
               认购累计本年金额 AS 认购本年回笼金额,
               其中补差款本年回笼金额,
               本年签约按揭回笼金额,
               本年认购按揭回笼金额,
               本年签约非按揭回笼金额,
               本年认购非按揭回笼金额,
                                             --CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --        0
                                             --    ELSE 应退未退本年金额
                                             --END AS 应退未退本年金额, --新增
                                             -- CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --         0
                                             --     ELSE 签约本年回笼金额
                                             -- END AS 签约本年回笼金额,
                                             -- CASE
                                             --     WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --         0
                                             --    ELSE 认购累计本年金额
                                             --END AS 认购本年回笼金额,
                                             -- CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --        0
                                             --   ELSE 其中补差款本年回笼金额
                                             -- END AS 其中补差款本年回笼金额,
                                             -- CASE
                                             --     WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --         0
                                             --     ELSE 本年签约按揭回笼金额
                                             --END AS 本年签约按揭回笼金额,
                                             -- CASE
                                             --     WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --         0
                                             --    ELSE 本年认购按揭回笼金额
                                             --END AS 本年认购按揭回笼金额,
                                             -- CASE
                                             --     WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --          0
                                             --     ELSE 本年签约非按揭回笼金额
                                             -- END AS 本年签约非按揭回笼金额,
                                             -- CASE
                                             --     WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --          0
                                             --     ELSE 本年认购非按揭回笼金额
                                             -- END AS 本年认购非按揭回笼金额,
                                             --本月
               应退未退本月金额,
               签约本月回笼金额,
               认购累计本月金额 AS 认购本月回笼金额,
               其中补差款本月回笼金额,
               本月签约按揭回笼金额,
               本月认购按揭回笼金额,
               本月签约非按揭回笼金额,
               本月认购非按揭回笼金额,
                                             --      CASE
                                             --         WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --              0
                                             --         ELSE 应退未退本月金额
                                             --     END AS 应退未退本月金额, --新增
                                             --     CASE
                                             --       WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --          0
                                             --      ELSE 签约本月回笼金额
                                             -- END AS 签约本月回笼金额,
                                             --   CASE
                                             --      WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --     ELSE 认购累计本月金额
                                             -- END AS 认购本月回笼金额,
                                             --  CASE
                                             --      WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --      ELSE 其中补差款本月回笼金额
                                             -- END AS 其中补差款本月回笼金额,
                                             -- CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --          0
                                             --     ELSE 本月签约按揭回笼金额
                                             -- END AS 本月签约按揭回笼金额,
                                             --   CASE
                                             --     WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --          0
                                             --     ELSE 本月认购按揭回笼金额
                                             -- END AS 本月认购按揭回笼金额,
                                             --CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --         0
                                             --    ELSE 本月签约非按揭回笼金额
                                             --END AS 本月签约非按揭回笼金额,
                                             --  CASE
                                             --      WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --      ELSE 本月认购非按揭回笼金额
                                             --  END AS 本月认购非按揭回笼金额,

                                             --本月签约本月回笼
               本月签约本月回笼非按揭回笼,
               本月签约本月回笼按揭回笼,
               本月签约本月回笼回笼合计,
               本年签约本月回笼非按揭回笼,
               本年签约本月回笼按揭回笼,
               本年签约本月回笼回笼合计,
                                             --   CASE
                                             --       WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --             0
                                             --        ELSE 本月签约本月回笼非按揭回笼
                                             --   END AS 本月签约本月回笼非按揭回笼,
                                             --   CASE
                                             --       WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --            0
                                             --       ELSE 本月签约本月回笼按揭回笼
                                             --   END AS 本月签约本月回笼按揭回笼,
                                             --    CASE
                                             --       WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --            0
                                             --       ELSE 本月签约本月回笼回笼合计
                                             --   END AS 本月签约本月回笼回笼合计,

                                             --本年签约本月回笼
                                             --   CASE
                                             --       WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --      ELSE 本年签约本月回笼非按揭回笼
                                             -- END AS 本年签约本月回笼非按揭回笼,
                                             --   CASE
                                             --       WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --      ELSE 本年签约本月回笼按揭回笼
                                             --  END AS 本年签约本月回笼按揭回笼,
                                             --   CASE
                                             --      WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --      ELSE 本年签约本月回笼回笼合计
                                             -- END AS 本年签约本月回笼回笼合计,

                                             --待收款
               正常非按揭待收款,
                                             --   CASE
                                             --       WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --            0
                                             --       ELSE 正常非按揭待收款
                                             --  END AS 正常非按揭待收款,
                                             --CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --         0
                                             --     ELSE CASE
                                             --              WHEN 销售状态 = '签约' THEN
                                             --                   正常非按揭待收款
                                             --             ELSE 0
                                             --          END
                                             -- END AS 签约正常非按揭待收款,
               CASE
                   WHEN 销售状态 = '签约' THEN
                        正常非按揭待收款
                   ELSE 0
               END AS 签约正常非按揭待收款,
               正常按揭待收款,
                                             --CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --         0
                                             --   ELSE 正常按揭待收款
                                             --END AS 正常按揭待收款,
               CASE
                   WHEN 销售状态 = '签约' THEN
                        正常按揭待收款
                   ELSE 0
               END AS 签约正常按揭待收款,
                                             -- CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --        0
                                             --  ELSE CASE
                                             --         WHEN 销售状态 = '签约' THEN
                                             --            正常按揭待收款
                                             --     ELSE 0
                                             -- END
                                             --END AS 签约正常按揭待收款,
               正常待收款,
                                             --CASE
                                             --       WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --     ELSE 正常待收款
                                             --  END AS 正常待收款,
               非按揭逾期待收款,
                                             --CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --         0
                                             --    ELSE 非按揭逾期待收款
                                             -- END AS 非按揭逾期待收款,
               CASE
                   WHEN 销售状态 = '签约' THEN
                        非按揭逾期待收款
                   ELSE 0
               END AS 签约非按揭逾期待收款,
                                             -- CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --          0
                                             --     ELSE CASE
                                             --              WHEN 销售状态 = '签约' THEN
                                             --                   非按揭逾期待收款
                                             --              ELSE 0
                                             --         END
                                             -- END AS 签约非按揭逾期待收款,
               按揭逾期待收款,
                                             --   CASE
                                             --        WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --            0
                                             --       ELSE 按揭逾期待收款
                                             --   END AS 按揭逾期待收款,
               CASE
                   WHEN 销售状态 = '签约' THEN
                        按揭逾期待收款
                   ELSE 0
               END AS 签约按揭逾期待收款,
                                             --   CASE
                                             --       WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --            0
                                             --       ELSE CASE
                                             --                WHEN 销售状态 = '签约' THEN
                                             --                     按揭逾期待收款
                                             --               ELSE 0
                                             --           END
                                             --   END AS 签约按揭逾期待收款,
               逾期合计,
                                             --CASE
                                             --      WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --      ELSE 逾期合计
                                             --  END AS 逾期合计,
               待收房款合计,
                                             --  CASE
                                             --     WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --      ELSE 待收房款合计
                                             -- END AS 待收房款合计,
               其中待收补差款合计,
                                             --  CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --       0
                                             --ELSE 其中待收补差款合计
                                             -- END AS 其中待收补差款合计,
               关闭交易本年退款金额,
                                             --  CASE
                                             --    WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --       0
                                             --ELSE [关闭交易本年退款金额]
                                             -- END AS [关闭交易本年退款金额],
               关闭交易本月退款金额,
                                             --   CASE
                                             --       WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --      ELSE [关闭交易本月退款金额]
                                             --  END AS [关闭交易本月退款金额],
               认购累计待收款,
                                             --  CASE
                                             --      WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --      ELSE [认购累计待收款]
                                             --  END AS [认购累计待收款],
               签约累计待收款,
                                             --  CASE
                                             --     WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --          0
                                             --     ELSE [签约累计待收款]
                                             --  END AS [签约累计待收款],
               应退未退本日金额,
                                             --   CASE
                                             --       WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --            0
                                             --       ELSE 应退未退本日金额
                                             --   END AS 应退未退本日金额,
               认购累计本日金额,
                                             --  CASE
                                             --     WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --     ELSE 认购累计本日金额
                                             --  END AS 认购累计本日金额,
               签约本日回笼金额,
                                             --   CASE
                                             --       WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --            0
                                             --       ELSE 签约本日回笼金额
                                             --  END AS 签约本日回笼金额,
               关闭交易本日退款金额,
                                             --  CASE
                                             --      WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --      ELSE 关闭交易本日退款金额
                                             --  END AS 关闭交易本日退款金额,

                                             --本年签约本年回笼
               本年签约本年回笼非按揭回笼,
                                             --  CASE
                                             --      WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --           0
                                             --      ELSE 本年签约本年回笼非按揭回笼
                                             --  END AS 本年签约本年回笼非按揭回笼,
               本年签约本年回笼按揭回笼,
                                             -- CASE
                                             --     WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                             --          0
                                             --    ELSE 本年签约本年回笼按揭回笼
                                             --  END AS 本年签约本年回笼按揭回笼,
               本年签约本年回笼回笼合计
        --     CASE
        --         WHEN mp.是否计算回笼按规则判断 = '否' THEN
        --              0
        --         ELSE 本年签约本年回笼回笼合计
        --     END AS 本年签约本年回笼回笼合计
        FROM s_gsfkylbmxb s
             LEFT JOIN p_room r ON s.roomguid = r.RoomGUID
             LEFT JOIN #md mp ON s.topprojguid = mp.ProjGUID
        WHERE DATEDIFF(DAY, @var_endDate, qxDate) = 0
              AND s.BUGUID IN (
                                  SELECT Value FROM [dbo].[fn_Split2](@var_buguid, ',')
                              )
              --过滤特殊业绩部分的房间
              AND NOT EXISTS
        (
            SELECT 1
            FROM dbo.S_PerformanceAppraisalRoom sr
                 INNER JOIN S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                        AND s.AuditStatus = '已审核'
                                                        AND s.yjtype NOT IN ( '经营类(溢价款)', '物业公司车位代销', '经营类(租金)' )
            WHERE r.roomguid = sr.RoomGUID
        )
              AND NOT EXISTS
        (
            SELECT 1
            FROM dbo.S_PerformanceAppraisalBuildings sr
                 INNER JOIN S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                        AND s.AuditStatus = '已审核'
                                                        AND s.yjtype NOT IN ( '经营类(溢价款)', '物业公司车位代销', '经营类(租金)' )
            WHERE r.BldGUID = sr.BldGUID
        )
    ) t1
    GROUP BY t1.BUGUID,
             t1.公司名称,
             t1.topprojguid,
             t1.销售项目名称,
             t1.投管项目代码,
             t1.投管项目名称,
             t1.操盘方式,
             t1.并表方式,
             t1.项目权益比例,
             t1.项目标签是否计算回笼; --20240428新增

    ---按照公司统计预收款金额,因为关联不到房间只能在汇总表上手工加上。
    UPDATE #temp1
    SET [累计预收款] = ISNULL(ysk.[累计预收款], 0) / 10000,
        [本年预收款] = ISNULL(ysk.[本年预收款], 0) / 10000,
        [本月预收款] = ISNULL(ysk.[本月预收款], 0) / 10000
    FROM #temp1
         LEFT JOIN
         (
             SELECT v.BuGUID,
                    mp1.ProjGUID,
                    mp1.ProjCode,
                    SUM(g.Amount) AS 累计预收款,
                    SUM(   CASE
                               WHEN DATEDIFF(yy, v.KpDate, @var_endDate) = 0 THEN
                                    g.Amount
                               ELSE 0
                           END
                       ) AS 本年预收款,
                    SUM(   CASE
                               WHEN DATEDIFF(mm, v.KpDate, @var_endDate) = 0 THEN
                                    g.Amount
                               ELSE 0
                           END
                       ) AS 本月预收款
             FROM dbo.s_Getin g
                  LEFT JOIN dbo.s_Voucher v ON g.VouchGUID = v.VouchGUID
                  LEFT JOIN dbo.myBusinessUnit bu ON bu.BUGUID = v.BuGUID
                  LEFT JOIN dbo.mdm_Project mp ON v.ProjGUID = mp.ProjGUID
                  LEFT JOIN dbo.mdm_Project mp1 ON mp1.ProjGUID = mp.ParentProjGUID
             WHERE g.Status IS NULL
                   --AND g.ItemName = '预收款'
                   AND ISNULL(CONVERT(VARCHAR(50), v.SaleGUID), '') = ''
                   AND VouchType <> '放款单'
                   AND VouchType <> '划拨单'
                   --AND g.SaleGUID IS NULL
                   AND g.GetDate <= @var_endDate
             GROUP BY v.BuGUID,
                      mp1.ProjGUID,
                      mp1.ProjCode
         ) ysk ON ysk.BuGUID = #temp1.BUGUID
                  AND ysk.ProjCode = #temp1.投管项目代码;



    -----统计非操盘项目 
    --取合作业绩已审核部分的内容
    SELECT ROW_NUMBER() OVER (PARTITION BY a.projguid ORDER BY a.BizDate DESC) AS num,
           *
    INTO #合作业绩已审核部分
    FROM
    (
        SELECT CONVERT(DATETIME, b.DateYear + '-' + b.DateMonth + '-27') AS [BizDate],
               b.*,
               c.projguid
        FROM s_YJRLProducteDetail b
             LEFT JOIN dbo.s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
        WHERE b.Shenhe = '审核'
    ) a;

    --取合作业绩录入的待收款信息
    SELECT s.projguid,
           a.dskName,
           SUM(a.Amount) AS Amount
    INTO #应收
    FROM s_HzyjFinacePlanDetail a
         LEFT JOIN s_HzyjFinaceBase b ON a.HzyjFinaceBaseGUID = b.HzyjFinaceBaseGUID
         INNER JOIN #合作业绩已审核部分 s ON b.ProducteDetailGUID = s.ProducteDetailGUID
                                    AND s.num = 1
    GROUP BY s.projguid,
             a.dskName;

    --取合作业绩的待收款
    SELECT zz.ProjGUID,
           zz.dskname,
           zz.Amount
    INTO #待收
    FROM
    (
        SELECT p.ProjGUID,
               SUM(ISNULL(a.Amount, 0)) yjje,
               SUM(ISNULL(a.huilongjiner, 0)) hlje,
               SUM(ISNULL(a.Amount, 0) - ISNULL(a.huilongjiner, 0)) dsk,
               SUM(ISNULL(a.ZcfajdsAmount, 0)) AS 正常非按揭待收款,
               SUM(ISNULL(a.ZcajdsAmount, 0)) AS 正常按揭待收款,
               SUM(ISNULL(a.YqfajdskAmount, 0)) AS 逾期非按揭待收款,
               SUM(ISNULL(a.YqajdskAmount, 0)) AS 逾期按揭待收款
        FROM dbo.s_YJRLProducteDescript a
             INNER JOIN dbo.#合作业绩已审核部分 b ON b.ProducteDetailGUID = a.ProducteDetailGUID
                                            AND b.num = 1
             LEFT JOIN dbo.s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
             INNER JOIN mdm_Project p ON p.ProjGUID = c.ProjGUID
        WHERE Shenhe = '审核'
        GROUP BY p.ProjGUID
    ) zhuanzhi
        UNPIVOT
        (
            Amount
            FOR dskname IN ([正常非按揭待收款], [正常按揭待收款], [逾期非按揭待收款], [逾期按揭待收款])
        ) zz;

    SELECT a.projguid,
           ISNULL(b.dskname, a.dskname) dskname,
           SUM(ISNULL(b.Amount, a.Amount)) amount
    INTO #应收待收
    FROM #待收 a
         LEFT JOIN #应收 b ON a.projguid = b.projguid
                            AND a.dskname = b.dskname
    GROUP BY a.projguid,
             ISNULL(b.dskname, a.dskname);

    SELECT @var_endDate AS qxDate,
           c.BUGuid,
           bu.BUName AS 公司名称,
           p.projGUID,
           p.ProjName AS 销售项目名称,
           mp.ProjCode AS 投管项目代码,
           mp.ProjName AS 投管项目名称,
           mp.TradersWay AS 操盘方式,
           mp.BbWay AS 并表方式,
           lbp.LbProjectValue AS 项目权益比例,
           mp.是否计算回笼按规则判断 AS 项目标签是否计算回笼, --20240428新增
           '合作业绩' AS 业绩类型,
           SUM(a.Amount) AS 累计房间成交金额,
           CONVERT(MONEY, 0) AS 累计装修款,
           CONVERT(MONEY, 0) AS 累计附属房间成交金额,
           CONVERT(MONEY, 0) AS 累计补差款,
           SUM(a.Amount) AS 累计交易金额,
           SUM(a.Amount) AS 累计签约金额,
           CONVERT(MONEY, 0) AS 应退未退累计金额,
                                         --SUM(   CASE
                                         --           WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                         --                0
                                         --           ELSE a.huilongjiner
                                         --       END
                                         --   ) AS 累计回笼金额签约,
           SUM(a.huilongjiner) AS 累计回笼金额签约,
           CONVERT(MONEY, 0) AS 累计回笼金额认购,
           CONVERT(MONEY, 0) AS 累计回笼金额其中补差款,
           CONVERT(MONEY, 0) AS 累计回笼金额签约按揭,
           CONVERT(MONEY, 0) AS 累计回笼金额认购按揭,
                                         --SUM(   CASE
                                         --           WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                         --                0
                                         --           ELSE a.huilongjiner
                                         --       END
                                         --   ) AS 累计回笼金额签约非按揭,
           SUM(a.huilongjiner) AS 累计回笼金额签约非按揭,
           CONVERT(MONEY, 0) AS 累计回笼金额认购非按揭,
           CONVERT(MONEY, 0) AS 应退未退本年金额,
           SUM(   CASE
                      WHEN DATEDIFF(yy, b.BizDate, @var_endDate) = 0
                  --AND
                  -- ( ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                  --     OR ISNULL(mp.是否计算回笼按规则判断, '是') = '' ) 
                  THEN
                           a.huilongjiner
                      ELSE 0
                  END
              ) AS 本年回笼金额签约,
           CONVERT(MONEY, 0) AS 本年回笼金额认购,
           CONVERT(MONEY, 0) AS 本年回笼金额其中补差款,
           CONVERT(MONEY, 0) AS 本年回笼金额签约按揭,
           CONVERT(MONEY, 0) AS 本年回笼金额认购按揭,
           CONVERT(MONEY, 0) AS 本年回笼金额签约非按揭,
           SUM(   CASE
                      WHEN DATEDIFF(yy, b.BizDate, @var_endDate) = 0
                  --AND
                  -- (
                  --    ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                  --     OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                  -- ) 
                  THEN
                           a.huilongjiner
                      ELSE 0
                  END
              ) AS 本年回笼金额认购非按揭,
           CONVERT(MONEY, 0) AS 应退未退本月金额,
           SUM(   CASE
                      WHEN DATEDIFF(mm, b.BizDate, @var_endDate) = 0
                  -- AND
                  --(
                  --     ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                  --     OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                  --  ) 
                  THEN
                           a.huilongjiner
                      ELSE 0
                  END
              ) AS 本月回笼金额签约,
           CONVERT(MONEY, 0) AS 本月回笼金额认购,
           CONVERT(MONEY, 0) AS 本月回笼金额其中补差款,
           CONVERT(MONEY, 0) AS 本月回笼金额签约按揭,
           CONVERT(MONEY, 0) AS 本月回笼金额认购按揭,
           SUM(   CASE
                      WHEN DATEDIFF(mm, b.BizDate, @var_endDate) = 0
                  --AND
                  --(
                  --    ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                  --    OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                  -- ) 
                  THEN
                           a.huilongjiner
                      ELSE 0
                  END
              ) AS 本月回笼金额签约非按揭,
           CONVERT(MONEY, 0) AS 本月回笼金额认购非按揭,
           CONVERT(MONEY, 0) AS 本月签约本月回笼非按揭回笼,
           CONVERT(MONEY, 0) AS 本月签约本月回笼按揭回笼,
           CONVERT(MONEY, 0) AS 本月签约本月回笼回笼合计,
           CONVERT(MONEY, 0) AS 本年签约本月回笼非按揭回笼,
           CONVERT(MONEY, 0) AS 本年签约本月回笼按揭回笼,
           CONVERT(MONEY, 0) AS 本年签约本月回笼回笼合计,
                                         --SUM(   CASE
                                         --           WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                         --                0
                                         --           ELSE a.Amount
                                         --       END
                                         --   ) - SUM(   CASE
                                         --                  WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                         --                       0
                                         --                  ELSE a.huilongjiner
                                         --              END
                                         --          ) AS 未回笼金额正常待收款非按揭待收款,
           SUM(   CASE
                      WHEN
                      (
                          hzyj.DateYear = YEAR(@var_endDate)
                          AND hzyj.DateMonth = MONTH(@var_endDate)
                      ) THEN
                      a.ZcfajdsAmount
                      ELSE 0
                  END
              ) AS 未回笼金额正常待收款非按揭待收款,
                                         --CONVERT(MONEY, 0) AS 未回笼金额正常待收款按揭待收款,
           SUM(   CASE
                      WHEN
                      (
                          hzyj.DateYear = YEAR(@var_endDate)
                          AND hzyj.DateMonth = MONTH(@var_endDate)
                      ) THEN
                      a.ZcajdsAmount
                      ELSE 0
                  END
              ) AS 未回笼金额正常待收款按揭待收款,
           SUM(a.Amount) - SUM(a.huilongjiner) AS 签约未回笼金额正常待收款非按揭待收款,
                                         -- SUM(   CASE
                                         --            WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                         --                0
                                         --           ELSE a.Amount
                                         --       END
                                         --   ) - SUM(   CASE
                                         --                  WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                         --                      0
                                         --                 ELSE a.huilongjiner
                                         --             END
                                         --         ) AS 签约未回笼金额正常待收款非按揭待收款,
           CONVERT(MONEY, 0) AS 签约未回笼金额正常待收款按揭待收款,
           SUM(a.Amount) - SUM(a.huilongjiner) AS 未回笼金额正常待收款合计,
                                         --SUM(   CASE
                                         --         WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                         --            0
                                         --     ELSE a.Amount
                                         -- END
                                         --  ) - SUM(   CASE
                                         --               WHEN mp.是否计算回笼按规则判断 = '否' THEN
                                         --                  0
                                         --           ELSE a.huilongjiner
                                         --     END
                                         --      ) AS 未回笼金额正常待收款合计,
                                         --SUM(CASE WHEN mp.是否计算回笼按规则判断 = '否' THEN 0 ELSE a.ZcdsAmount END) AS 未回笼金额正常待收款合计,
           CONVERT(MONEY, 0) AS 未回笼金额逾期待收款非按揭逾期待收款,
           CONVERT(MONEY, 0) AS 未回笼金额逾期待收款按揭逾期待收款,
           CONVERT(MONEY, 0) AS 签约未回笼金额逾期待收款非按揭逾期待收款,
           CONVERT(MONEY, 0) AS 签约未回笼金额逾期待收款按揭逾期待收款,
           CONVERT(MONEY, 0) AS 未回笼金额逾期待收款逾期合计,
           SUM(a.Amount) - SUM(a.huilongjiner) AS 待收款合计,
                                         --SUM(CASE WHEN mp.是否计算回笼按规则判断 = '否' THEN 0
                                         --       ELSE a.Amount END
                                         --  ) - SUM(   CASE WHEN mp.是否计算回笼按规则判断 = '否' THEN 0
                                         --                        ELSE a.huilongjiner
                                         --                  END
                                         --    ) AS 待收款合计,
                                         --SUM(CASE WHEN mp.是否计算回笼按规则判断 = '否' THEN 0 ELSE a.DskAmount END) AS 待收款合计,
           CONVERT(MONEY, 0) AS 其中待收补差款合计,
           CONVERT(MONEY, 0) AS 房款回笼率,
           CONVERT(MONEY, 0) AS 房款逾期率,
           CONVERT(MONEY, 0) AS 非按揭房款逾期率,
           CONVERT(MONEY, 0) AS 累计回笼金额大于累计认购金额,
           CONVERT(MONEY, 0) AS 逾期款加正常款不等于总额,
           CONVERT(MONEY, 0) AS 按揭款加非按揭款不等于总额,
           CONVERT(MONEY, 0) AS [累计预收款],
           CONVERT(MONEY, 0) AS [本年预收款],
           CONVERT(MONEY, 0) AS [本月预收款],
           CONVERT(MONEY, 0) AS [关闭交易本年退款金额],
           CONVERT(MONEY, 0) AS [关闭交易本月退款金额],
           CONVERT(MONEY, 0) AS [认购累计待收款],
           SUM(a.Amount) - SUM(a.huilongjiner) AS [签约累计待收款],
                                         --SUM(CASE WHEN mp.是否计算回笼按规则判断 = '否' THEN 0 ELSE a.DskAmount END) AS [签约累计待收款],

                                         --本日
           0 AS 应退未退本日金额,
           0 AS 本日回笼金额签约,
           0 AS 本日回笼金额认购,
           0 AS 关闭交易本日退款金额,
           mp.ProjStatus AS 项目状态,
           mp.ProjGUID AS TopProjGUID,
                                         --本年签约
           SUM(   CASE
                      WHEN DATEDIFF(yy, b.BizDate, @var_endDate) = 0 THEN
                           a.Amount
                      ELSE 0
                  END
              ) AS 本年房间成交金额,
           0 AS 本年装修款,
           0 AS 本年附属房间成交金额,
           0 AS 本年补差款,
           SUM(   CASE
                      WHEN DATEDIFF(yy, b.BizDate, @var_endDate) = 0 THEN
                           a.Amount
                      ELSE 0
                  END
              ) AS 本年交易金额,
           SUM(   CASE
                      WHEN DATEDIFF(yy, b.BizDate, @var_endDate) = 0 THEN
                           a.Amount
                      ELSE 0
                  END
              ) AS 本年签约金额,
                                         --特殊业绩
           CONVERT(MONEY, 0) AS 累计特殊业绩待收款,
           CONVERT(MONEY, 0) AS 累计特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 累计经营类特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 累计特殊业绩未关联房间,
           CONVERT(MONEY, 0) AS 本年特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 本年经营类特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 本年特殊业绩未关联房间,
           CONVERT(MONEY, 0) AS 本月特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 本月经营类特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 本月特殊业绩未关联房间,
           CONVERT(MONEY, 0) AS 本日特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 本日经营类特殊业绩关联房间,
           CONVERT(MONEY, 0) AS 本日特殊业绩未关联房间,
           CONVERT(MONEY, 0) AS 本年签约本年回笼非按揭回笼,
           CONVERT(MONEY, 0) AS 本年签约本年回笼按揭回笼,
           CONVERT(MONEY, 0) AS 本年签约本年回笼回笼合计
    INTO #temp2hhh
    FROM dbo.s_YJRLProducteDescript a
         LEFT JOIN vs_HzyjFinaceBase hzyj ON a.ProducteDetailGUID = hzyj.ProducteDetailGUID
         LEFT JOIN
         (
             SELECT *,
                    CONVERT(DATETIME, b.DateYear + '-' + b.DateMonth + '-01') AS [BizDate]
             FROM dbo.s_YJRLProducteDetail b
             WHERE b.Shenhe = '审核'
         ) b ON b.ProducteDetailGUID = a.ProducteDetailGUID
         LEFT JOIN dbo.s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
         LEFT JOIN #md mp ON mp.ProjGUID = c.ProjGUID
         LEFT JOIN dbo.p_Project p ON p.ProjGUID = c.ProjGUID
         LEFT JOIN dbo.p_DevelopmentCompany m ON m.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
         LEFT JOIN dbo.myBusinessUnit bu ON bu.BUGUID = c.BUGuid
         LEFT JOIN
         (
             SELECT projGUID,
                    MAX(LbProjectValue) AS LbProjectValue
             FROM mdm_LbProject
             WHERE LbProject = 'cwsybl'
             GROUP BY projGUID
         ) lbp ON lbp.projGUID = mp.ProjGUID
         LEFT JOIN
         (
             SELECT projGUID,
                    MAX(LbProjectValue) AS LbProjectValue
             FROM mdm_LbProject
             WHERE LbProject = 'sfjshl'
             GROUP BY projGUID
         ) sfjshl ON sfjshl.projGUID = mp.ProjGUID
    WHERE b.Shenhe = '审核'
          AND c.BUGUID IN (
                              SELECT Value FROM [dbo].[fn_Split2](@var_buguid, ',')
                          )
    --AND (  hzyj.DateYear=YEAR(@var_endDate) and hzyj.DateMonth=month(@var_endDate)  )
    --AND p.ApplySys LIKE '%0101%'

    GROUP BY c.BUGuid,
             bu.BUName,
             p.projGUID,
             p.ProjName,
             mp.ProjCode,
             mp.ProjGUID,
             mp.ProjName,
             mp.ProjStatus,
             mp.TradersWay,
             mp.BbWay,
             lbp.LbProjectValue,
             mp.是否计算回笼按规则判断; --20240428新增

    SELECT hh.qxDate,
           hh.BUGuid,
           hh.公司名称,
           hh.销售项目名称,
           hh.投管项目代码,
           hh.投管项目名称,
           hh.操盘方式,
           hh.并表方式,
           hh.项目权益比例,
           hh.项目标签是否计算回笼,
           hh.业绩类型,
           hh.累计房间成交金额,
           hh.累计装修款,
           hh.累计附属房间成交金额,
           hh.累计补差款,
           hh.累计交易金额,
           hh.累计签约金额,
           hh.应退未退累计金额,
           hh.累计回笼金额签约,
           hh.累计回笼金额认购,
           hh.累计回笼金额其中补差款,
           hh.累计回笼金额签约按揭,
           hh.累计回笼金额认购按揭,
           hh.累计回笼金额签约非按揭,
           hh.累计回笼金额认购非按揭,
           hh.应退未退本年金额,
           hh.本年回笼金额签约,
           hh.本年回笼金额认购,
           hh.本年回笼金额其中补差款,
           hh.本年回笼金额签约按揭,
           hh.本年回笼金额认购按揭,
           hh.本年回笼金额签约非按揭,
           hh.本年回笼金额认购非按揭,
           hh.应退未退本月金额,
           hh.本月回笼金额签约,
           hh.本月回笼金额认购,
           hh.本月回笼金额其中补差款,
           hh.本月回笼金额签约按揭,
           hh.本月回笼金额认购按揭,
           hh.本月回笼金额签约非按揭,
           hh.本月回笼金额认购非按揭,
           hh.本月签约本月回笼非按揭回笼,
           hh.本月签约本月回笼按揭回笼,
           hh.本月签约本月回笼回笼合计,
           hh.本年签约本月回笼非按揭回笼,
           hh.本年签约本月回笼按揭回笼,
           hh.本年签约本月回笼回笼合计,
           ISNULL(ysfaj.amount, hh.未回笼金额正常待收款非按揭待收款) AS 未回笼金额正常待收款非按揭待收款,
           ISNULL(ysaj.amount, hh.未回笼金额正常待收款按揭待收款) AS 未回笼金额正常待收款按揭待收款,
           --hh.签约未回笼金额正常待收款非按揭待收款,
           ISNULL(ysfaj.amount, hh.未回笼金额正常待收款非按揭待收款) + ISNULL(ysaj.amount, hh.未回笼金额正常待收款按揭待收款) AS 签约未回笼金额正常待收款非按揭待收款,
           hh.签约未回笼金额正常待收款按揭待收款,
           --hh.未回笼金额正常待收款合计,
           ISNULL(ysfaj.amount, hh.未回笼金额正常待收款非按揭待收款) + ISNULL(ysaj.amount, hh.未回笼金额正常待收款按揭待收款) AS 未回笼金额正常待收款合计,
           ISNULL(yqysfaj.amount, hh.未回笼金额逾期待收款非按揭逾期待收款) AS 未回笼金额逾期待收款非按揭逾期待收款,
           ISNULL(yqysaj.amount, hh.未回笼金额逾期待收款按揭逾期待收款) AS 未回笼金额逾期待收款按揭逾期待收款,
           hh.签约未回笼金额逾期待收款非按揭逾期待收款,
           hh.签约未回笼金额逾期待收款按揭逾期待收款,
           --hh.未回笼金额逾期待收款逾期合计,
           ISNULL(yqysfaj.amount, hh.未回笼金额逾期待收款非按揭逾期待收款) + ISNULL(yqysaj.amount, hh.未回笼金额逾期待收款按揭逾期待收款) AS 未回笼金额逾期待收款逾期合计,
           hh.待收款合计,
           hh.其中待收补差款合计,
           hh.房款回笼率,
           hh.房款逾期率,
           hh.非按揭房款逾期率,
           hh.累计回笼金额大于累计认购金额,
           hh.逾期款加正常款不等于总额,
           hh.按揭款加非按揭款不等于总额,
           hh.累计预收款,
           hh.本年预收款,
           hh.本月预收款,
           hh.关闭交易本年退款金额,
           hh.关闭交易本月退款金额,
           hh.认购累计待收款,
           hh.签约累计待收款,
           hh.应退未退本日金额,
           hh.本日回笼金额签约,
           hh.本日回笼金额认购,
           hh.关闭交易本日退款金额,
           hh.项目状态,
           hh.TopProjGUID,
           hh.本年房间成交金额,
           hh.本年装修款,
           hh.本年附属房间成交金额,
           hh.本年补差款,
           hh.本年交易金额,
           hh.本年签约金额,
           hh.累计特殊业绩待收款,
           hh.累计特殊业绩关联房间,
           hh.累计经营类特殊业绩关联房间,
           hh.累计特殊业绩未关联房间,
           hh.本年特殊业绩关联房间,
           hh.本年经营类特殊业绩关联房间,
           hh.本年特殊业绩未关联房间,
           hh.本月特殊业绩关联房间,
           hh.本月经营类特殊业绩关联房间,
           hh.本月特殊业绩未关联房间,
           hh.本日特殊业绩关联房间,
           hh.本日经营类特殊业绩关联房间,
           hh.本日特殊业绩未关联房间,
           hh.本年签约本年回笼非按揭回笼,
           hh.本年签约本年回笼按揭回笼,
           hh.本年签约本年回笼回笼合计
    INTO #temp2
    FROM #temp2hhh hh
         LEFT JOIN #应收待收 ysfaj ON hh.projGUID = ysfaj.projGUID
                                  AND ysfaj.dskname = '正常非按揭待收款'
         LEFT JOIN #应收待收 ysaj ON hh.projGUID = ysaj.projGUID
                                 AND ysaj.dskname = '正常按揭待收款'
         LEFT JOIN #应收待收 yqysfaj ON hh.projGUID = yqysfaj.projGUID
                                    AND yqysfaj.dskname = '逾期非按揭待收款'
         LEFT JOIN #应收待收 yqysaj ON hh.projGUID = yqysaj.projGUID
                                   AND yqysaj.dskname = '逾期按揭待收款';

    --合作业绩回笼 更新本年回笼合计
    SELECT c.ProjGUID,
           mp.projcode,
           lb.LbProjectValue sfjshl,
           CONVERT(DATE, b.DateYear + '-' + b.DateMonth + '-27') AS [BizDate],
           b.*
    INTO #s_YJRLProducteDetail
    FROM s_YJRLProducteDetail b
         INNER JOIN s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
         LEFT JOIN mdm_project mp ON c.projguid = mp.projguid
         LEFT JOIN mdm_LbProject lb ON c.ProjGUID = lb.projGUID
                                       AND lb.LbProject = 'sfjshl'
    WHERE b.Shenhe = '审核'
          AND b.DateYear = YEAR(GETDATE());


    SELECT a.projguid,
           a.projcode,
           CASE
               WHEN ISNULL(a.sfjshl, '') = '否' THEN
                    0
               ELSE a.bnhl
           END bnhl,
           CASE
               WHEN ISNULL(a.sfjshl, '') = '否' THEN
                    0
               ELSE a.hl
           END hl
    INTO #hzhl
    FROM
    (
        SELECT b.projguid,
               b.projcode,
               b.sfjshl,
               a.YearHuilongjiner bnhl,
               a.YearNewHuilongjiner hl,
               ROW_NUMBER() OVER (PARTITION BY b.projguid ORDER BY b.BizDate DESC) rownum
        FROM s_HzyjFinaceBase a
             INNER JOIN #s_YJRLProducteDetail b ON a.ProducteDetailGUID = b.ProducteDetailGUID
        WHERE a.AuditStatus = '审核'
    ) a
    WHERE a.rownum = 1;


    UPDATE a
    SET a.本年签约本年回笼回笼合计 = ISNULL(b.hl, 0)
    FROM #temp2 a
         INNER JOIN #hzhl b ON a.投管项目代码 = b.projcode;


    --计算特殊业绩回笼金额
    --操盘项目
    UPDATE t1
    SET t1.累计特殊业绩关联房间 = ISNULL(t2.累计特殊业绩关联房间, 0),
        t1.累计经营类特殊业绩关联房间 = ISNULL(t2.累计经营类特殊业绩关联房间, 0),
        t1.累计特殊业绩未关联房间 = ISNULL(t2.累计特殊业绩未关联房间, 0),
        t1.本年特殊业绩关联房间 = ISNULL(t2.本年特殊业绩关联房间, 0),
        t1.本年经营类特殊业绩关联房间 = ISNULL(t2.本年经营类特殊业绩关联房间, 0),
        t1.本年特殊业绩未关联房间 = ISNULL(t2.本年特殊业绩未关联房间, 0),
        t1.本月特殊业绩关联房间 = ISNULL(t2.本月特殊业绩关联房间, 0),
        t1.本月经营类特殊业绩关联房间 = ISNULL(t2.本月经营类特殊业绩关联房间, 0),
        t1.本月特殊业绩未关联房间 = ISNULL(t2.本月特殊业绩未关联房间, 0),
        t1.本日特殊业绩关联房间 = ISNULL(t2.本日特殊业绩关联房间, 0),
        t1.本日经营类特殊业绩关联房间 = ISNULL(t2.本日经营类特殊业绩关联房间, 0),
        t1.本日特殊业绩未关联房间 = ISNULL(t2.本日特殊业绩未关联房间, 0),
        t1.累计特殊业绩待收款 = ISNULL(t2.累计特殊业绩签约金额, 0) - ISNULL(t2.累计特殊业绩关联房间, 0) - ISNULL(t2.累计特殊业绩未关联房间, 0)
    FROM #temp1 t1
         LEFT JOIN
         (
             SELECT ManagementProjectGUID,
                    SUM(   CASE
                               WHEN sps.ifSelectPerformanceAmount = 1 THEN
                                    ISNULL(a.TotalAmount, 0)
                               ELSE 0
                           END
                       ) AS 累计特殊业绩签约金额,
                    SUM(   CASE
                               WHEN --a.YjType NOT IN ( '一级开发类','经营类')
                           tt.IsRelatedBuildingsRoom = 1
                           --AND a.YjType NOT IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           AND sps.ifSelectPerformanceHkAmount = 1 --是否取特殊业绩模块特殊业绩回笼设置1
                           THEN
                           ISNULL(t.huilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 累计特殊业绩关联房间,
                    SUM(   CASE
                               WHEN --a.YjType = '经营类'
                           --a.YjType IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           a.YjType IN ( '经营类(租金)' )
                           AND sps.ifSelectPerformanceHkAmount = 1 --是否取特殊业绩模块特殊业绩回笼设置1
                           THEN
                           ISNULL(t.huilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 累计经营类特殊业绩关联房间,
                    SUM(   CASE
                               WHEN --a.YjType = '一级开发类'
                           tt.IsRelatedBuildingsRoom = 0
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.huilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 累计特殊业绩未关联房间,
                    SUM(   CASE
                               WHEN --DATEDIFF(yy, t.KpDate,@var_endDate) = 0 AND
                           --a.YjType NOT IN ( '一级开发类','经营类')
                           tt.IsRelatedBuildingsRoom = 1
                           -- AND a.YjType NOT IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.bnhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本年特殊业绩关联房间,
                    SUM(   CASE
                               WHEN --a.YjType = '经营类'
                           --a.YjType IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           a.YjType = '经营类(租金)'
                           AND sps.ifSelectPerformanceHkAmount = 1 --是否取特殊业绩模块特殊业绩回笼设置1
                           THEN
                           ISNULL(t.bnhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本年经营类特殊业绩关联房间,
                    SUM(   CASE
                               WHEN --DATEDIFF(yy,t.KpDate,@var_endDate) = 0 AND
                           --a.YjType = '一级开发类'
                           tt.IsRelatedBuildingsRoom = 0
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.bnhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本年特殊业绩未关联房间,
                    SUM(   CASE
                               WHEN --DATEDIFF(mm,t.KpDate,@var_endDate) = 0 AND
                           -- a.YjType NOT IN ( '一级开发类','经营类')
                           tt.IsRelatedBuildingsRoom = 1
                           --AND a.YjType NOT IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.byhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本月特殊业绩关联房间,
                    SUM(   CASE
                               WHEN --a.YjType = '经营类'
                           --a.YjType IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           a.YjType = '经营类(租金)'
                           AND sps.ifSelectPerformanceHkAmount = 1 --是否取特殊业绩模块特殊业绩回笼设置1
                           THEN
                           ISNULL(t.byhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本月经营类特殊业绩关联房间,
                    SUM(   CASE
                               WHEN --DATEDIFF(mm, t.KpDate,@var_endDate) = 0 AND
                           -- a.YjType = '一级开发类'
                           tt.IsRelatedBuildingsRoom = 0
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.byhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本月特殊业绩未关联房间,
                    SUM(   CASE
                               WHEN --DATEDIFF(dd,t.KpDate, @var_endDate) = 0 AND
                           --a.YjType NOT IN ( '一级开发类','经营类')
                           tt.IsRelatedBuildingsRoom = 1
                           --AND a.YjType NOT IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )

                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.brhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本日特殊业绩关联房间,
                    SUM(   CASE
                               WHEN --a.YjType = '经营类'
                           --a.YjType IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           a.YjType IN ( '经营类(租金)' )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.brhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本日经营类特殊业绩关联房间,
                    SUM(   CASE
                               WHEN -- DATEDIFF(dd,t.KpDate, @var_endDate) = 0 AND
                           --a.YjType = '一级开发类'
                           tt.IsRelatedBuildingsRoom = 0
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.brhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本日特殊业绩未关联房间
             FROM dbo.S_PerformanceAppraisal a
                  LEFT JOIN
                  (
                      SELECT v.SaleGUID,
                             --v.KpDate,
                             SUM(   CASE
                                        WHEN DATEDIFF(yy, g.GetDate, @var_endDate) = 0 THEN
                                             ISNULL(g.RmbAmount, 0)
                                        ELSE 0
                                    END
                                ) / 10000 AS bnhuilongjiner,
                             SUM(   CASE
                                        WHEN DATEDIFF(mm, g.GetDate, @var_endDate) = 0 THEN
                                             ISNULL(g.RmbAmount, 0)
                                        ELSE 0
                                    END
                                ) / 10000 AS byhuilongjiner,
                             SUM(   CASE
                                        WHEN DATEDIFF(dd, g.GetDate, @var_endDate) = 0 THEN
                                             ISNULL(g.RmbAmount, 0)
                                        ELSE 0
                                    END
                                ) / 10000 AS brhuilongjiner,
                             SUM(ISNULL(g.RmbAmount, 0)) / 10000 AS huilongjiner
                      FROM dbo.s_Voucher v
                           INNER JOIN dbo.s_Getin g ON g.VouchGUID = v.VouchGUID
                      WHERE g.SaleType = '特殊业绩'
                            AND
                            (
                                v.VouchStatus IS NULL
                                OR v.VouchStatus = ''
                            )
                      GROUP BY v.SaleGUID --,v.KpDate
                  ) t ON t.SaleGUID = a.PerformanceAppraisalGUID
                  --项目特殊业绩回笼统计规则设置表S_PerformanceProjectSet
                  LEFT JOIN S_PerformanceProjectSet sps ON sps.ProjGUID = a.ManagementProjectGUID
                  LEFT JOIN s_TsyjType tt ON a.YjType = tt.TsyjTypeName
             --INNER JOIN #tsyjzqy ts ON a.PerformanceAppraisalGUID = ts.PerformanceAppraisalGUID
             WHERE a.AuditStatus = '已审核'
			 and a.yjtype <> '物业公司车位代销'
             GROUP BY a.ManagementProjectGUID
         ) t2 ON t1.topprojguid = t2.ManagementProjectGUID;


    --非操盘项目
    UPDATE t1
    SET t1.累计特殊业绩关联房间 = ISNULL(t2.累计特殊业绩关联房间, 0),
        t1.累计经营类特殊业绩关联房间 = ISNULL(t2.累计经营类特殊业绩关联房间, 0),
        t1.累计特殊业绩未关联房间 = ISNULL(t2.累计特殊业绩未关联房间, 0),
        t1.本年特殊业绩关联房间 = ISNULL(t2.本年特殊业绩关联房间, 0),
        t1.本年经营类特殊业绩关联房间 = ISNULL(t2.本年经营类特殊业绩关联房间, 0),
        t1.本年特殊业绩未关联房间 = ISNULL(t2.本年特殊业绩未关联房间, 0),
        t1.本月特殊业绩关联房间 = ISNULL(t2.本月特殊业绩关联房间, 0),
        t1.本月经营类特殊业绩关联房间 = ISNULL(t2.本月经营类特殊业绩关联房间, 0),
        t1.本月特殊业绩未关联房间 = ISNULL(t2.本月特殊业绩未关联房间, 0),
        t1.本日特殊业绩关联房间 = ISNULL(t2.本日特殊业绩关联房间, 0),
        t1.本日经营类特殊业绩关联房间 = ISNULL(t2.本日经营类特殊业绩关联房间, 0),
        t1.本日特殊业绩未关联房间 = ISNULL(t2.本日特殊业绩未关联房间, 0),
        t1.累计特殊业绩待收款 = ISNULL(t2.累计特殊业绩签约金额, 0) - ISNULL(t2.累计特殊业绩关联房间, 0) - ISNULL(t2.累计特殊业绩未关联房间, 0)
    FROM #temp2 t1
         LEFT JOIN
         (
             SELECT ManagementProjectGUID,
                    SUM(   CASE
                               WHEN sps.ifSelectPerformanceAmount = 1 THEN
                                    ISNULL(a.TotalAmount, 0)
                               ELSE 0
                           END
                       ) AS 累计特殊业绩签约金额,
                    SUM(   CASE
                               WHEN --a.YjType NOT IN ( '一级开发类','经营类')
                           tt.IsRelatedBuildingsRoom = 1
                           -- AND a.YjType NOT IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           AND sps.ifSelectPerformanceHkAmount = 1 --是否取特殊业绩模块特殊业绩回笼设置1
                           THEN
                           ISNULL(t.huilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 累计特殊业绩关联房间,
                    SUM(   CASE
                               WHEN --a.YjType = '经营类'
                           --a.YjType IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           a.YjType IN ( '经营类(租金)' )
                           AND sps.ifSelectPerformanceHkAmount = 1 --是否取特殊业绩模块特殊业绩回笼设置1
                           THEN
                           ISNULL(t.huilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 累计经营类特殊业绩关联房间,
                    SUM(   CASE
                               WHEN --a.YjType = '一级开发类'
                           tt.IsRelatedBuildingsRoom = 0
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.huilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 累计特殊业绩未关联房间,
                    SUM(   CASE
                               WHEN --DATEDIFF(yy, t.KpDate,@var_endDate) = 0 AND
                           --a.YjType NOT IN ( '一级开发类','经营类')
                           tt.IsRelatedBuildingsRoom = 1
                           --  AND a.YjType NOT IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.bnhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本年特殊业绩关联房间,
                    SUM(   CASE
                               WHEN --a.YjType = '经营类'
                           -- a.YjType IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           a.YjType = '经营类(租金)'
                           AND sps.ifSelectPerformanceHkAmount = 1 --是否取特殊业绩模块特殊业绩回笼设置1
                           THEN
                           ISNULL(t.bnhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本年经营类特殊业绩关联房间,
                    SUM(   CASE
                               WHEN --DATEDIFF(yy,t.KpDate,@var_endDate) = 0 AND
                           -- a.YjType = '一级开发类'
                           tt.IsRelatedBuildingsRoom = 0
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.bnhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本年特殊业绩未关联房间,
                    SUM(   CASE
                               WHEN --DATEDIFF(mm,t.KpDate,@var_endDate) = 0 AND
                           --a.YjType NOT IN ( '一级开发类','经营类')
                           tt.IsRelatedBuildingsRoom = 1
                           --AND a.YjType NOT IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.byhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本月特殊业绩关联房间,
                    SUM(   CASE
                               WHEN --a.YjType = '经营类'
                           --a.YjType IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           a.YjType IN ( '经营类(租金)' )
                           AND sps.ifSelectPerformanceHkAmount = 1 --是否取特殊业绩模块特殊业绩回笼设置1
                           THEN
                           ISNULL(t.byhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本月经营类特殊业绩关联房间,
                    SUM(   CASE
                               WHEN --DATEDIFF(mm, t.KpDate,@var_endDate) = 0 AND
                           --a.YjType = '一级开发类'
                           tt.IsRelatedBuildingsRoom = 0
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.byhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本月特殊业绩未关联房间,
                    SUM(   CASE
                               WHEN --DATEDIFF(dd,t.KpDate, @var_endDate) = 0 AND
                           -- a.YjType NOT IN ( '一级开发类','经营类')
                           tt.IsRelatedBuildingsRoom = 1
                           --AND a.YjType NOT IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.brhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本日特殊业绩关联房间,
                    SUM(   CASE
                               WHEN --a.YjType = '经营类'
                           --a.YjType IN ( '经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)' )
                           a.YjType = '经营类(租金)'
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.brhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本日经营类特殊业绩关联房间,
                    SUM(   CASE
                               WHEN -- DATEDIFF(dd,t.KpDate, @var_endDate) = 0 AND
                           -- a.YjType = '一级开发类'
                           tt.IsRelatedBuildingsRoom = 0
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.brhuilongjiner, 0)
                               ELSE 0
                           END
                       ) AS 本日特殊业绩未关联房间
             FROM dbo.S_PerformanceAppraisal a
                  LEFT JOIN
                  (
                      SELECT v.SaleGUID,
                             --v.KpDate,
                             SUM(   CASE
                                        WHEN DATEDIFF(yy, g.GetDate, @var_endDate) = 0 THEN
                                             ISNULL(g.RmbAmount, 0)
                                        ELSE 0
                                    END
                                ) / 10000 AS bnhuilongjiner,
                             SUM(   CASE
                                        WHEN DATEDIFF(mm, g.GetDate, @var_endDate) = 0 THEN
                                             ISNULL(g.RmbAmount, 0)
                                        ELSE 0
                                    END
                                ) / 10000 AS byhuilongjiner,
                             SUM(   CASE
                                        WHEN DATEDIFF(dd, g.GetDate, @var_endDate) = 0 THEN
                                             ISNULL(g.RmbAmount, 0)
                                        ELSE 0
                                    END
                                ) / 10000 AS brhuilongjiner,
                             SUM(ISNULL(g.RmbAmount, 0)) / 10000 AS huilongjiner
                      FROM dbo.s_Voucher v
                           INNER JOIN dbo.s_Getin g ON g.VouchGUID = v.VouchGUID
                      WHERE g.SaleType = '特殊业绩'
                            AND
                            (
                                v.VouchStatus IS NULL
                                OR v.VouchStatus = ''
                            )
                      GROUP BY v.SaleGUID --,v.KpDate
                  ) t ON t.SaleGUID = a.PerformanceAppraisalGUID
                  --项目特殊业绩回笼统计规则设置表S_PerformanceProjectSet
                  LEFT JOIN S_PerformanceProjectSet sps ON sps.ProjGUID = a.ManagementProjectGUID
                  LEFT JOIN s_TsyjType tt ON a.YjType = tt.TsyjTypeName
             WHERE a.AuditStatus = '已审核'
			 and a.yjtype <> '物业公司车位代销'
             GROUP BY a.ManagementProjectGUID
         ) t2 ON t1.TopProjGUID = t2.ManagementProjectGUID
		WHERE NOT EXISTS
		(select 1 from ( select distinct TopProjGUID from #temp1 ) temp1 where temp1.TopProjGUID = t1.TopProjGUID) ;

    --统计不包含在合作项目和操盘项目里的特殊业绩回笼
    --如果项目状态“代建”的则不统计认购签约中的回笼，只统计特殊业绩的回笼。销售金额正常统计
    SELECT @var_endDate AS qxDate,
           bu.BUGUID,
           bu.BUName AS 公司名称,
           p.ProjName AS 销售项目名称,
           mp.ProjCode AS 投管项目代码,
           mp.ProjName AS 投管项目名称,
           mp.TradersWay AS 操盘方式,
           mp.BbWay AS 并表方式,
           lbp.LbProjectValue AS 项目权益比例,
           mp.是否计算回笼按规则判断 AS 项目标签是否计算回笼,
           '特殊业绩' AS 业绩类型,
           SUM(a.TotalAmount) AS 累计房间成交金额,
           0 AS 累计装修款,
           0 AS 累计附属房间成交金额,
           0 AS 累计补差款,
           SUM(a.TotalAmount) AS 累计交易金额,
           0 AS 累计签约金额,
           0 AS 应退未退累计金额,
           0 AS 累计回笼金额签约,
           0 AS 累计回笼金额认购,
           0 AS 累计回笼金额其中补差款,
           0 AS 累计回笼金额签约按揭,
           0 AS 累计回笼金额认购按揭,
           0 AS 累计回笼金额签约非按揭,
           0 AS 累计回笼金额认购非按揭,
           0 AS 应退未退本年金额,
           0 AS 本年回笼金额签约,
           0 AS 本年回笼金额认购,
           0 AS 本年回笼金额其中补差款,
           0 AS 本年回笼金额签约按揭,
           0 AS 本年回笼金额认购按揭,
           0 AS 本年回笼金额签约非按揭,
           0 AS 本年回笼金额认购非按揭,
           0 AS 应退未退本月金额,
           0 AS 本月回笼金额签约,
           0 AS 本月回笼金额认购,
           0 AS 本月回笼金额其中补差款,
           0 AS 本月回笼金额签约按揭,
           0 AS 本月回笼金额认购按揭,
           0 AS 本月回笼金额签约非按揭,
           0 AS 本月回笼金额认购非按揭,
           0 AS 本月签约本月回笼非按揭回笼,
           0 AS 本月签约本月回笼按揭回笼,
           0 AS 本月签约本月回笼回笼合计,
           0 AS 本年签约本月回笼非按揭回笼,
           0 AS 本年签约本月回笼按揭回笼,
           0 AS 本年签约本月回笼回笼合计,
           --SUM(   CASE
           --           WHEN
           --       --mp.是否计算回笼按规则判断 = '否' OR 
           --      a.YjType IN ( '经营类(租金)', '收购类项目已售业绩认定', '品牌管理费' ) THEN
           --       0
           --           ELSE ISNULL(a.TotalAmount, 0) - ISNULL(t.huilongjiner, 0)
           --       END
           --   ) AS 未回笼金额正常待收款非按揭待收款,
		   SUM(ISNULL(skplan.未回笼金额正常待收款非按揭待收款,0)) AS 未回笼金额正常待收款非按揭待收款,
           0 AS 未回笼金额正常待收款按揭待收款,
           SUM(   CASE
                      WHEN
                  --mp.是否计算回笼按规则判断 = '否' OR 
                  a.YjType IN ( '经营类(租金)', '收购类项目已售业绩认定', '品牌管理费' ) THEN
                  0
                      ELSE ISNULL(a.TotalAmount, 0) - ISNULL(t.huilongjiner, 0)
                  END
              ) AS 签约未回笼金额正常待收款非按揭待收款,
           0 AS 签约未回笼金额正常待收款按揭待收款,
           --SUM(a.TotalAmount) - CASE
           --                         WHEN mp.是否计算回笼按规则判断 = '否' THEN
           --                             0
           --                         ELSE
           --                             SUM(t.huilongjiner)
           --                     END AS 未回笼金额正常待收款合计,
           --SUM(   CASE
           --           WHEN
           --       --mp.是否计算回笼按规则判断 = '否'  OR 
           --       a.YjType IN ( '经营类(租金)', '收购类项目已售业绩认定', '品牌管理费' ) THEN
           --       0
           --           ELSE ISNULL(a.TotalAmount, 0) - ISNULL(t.huilongjiner, 0)
           --       END
           --   ) AS 未回笼金额正常待收款合计,
		   SUM(ISNULL(skplan.未回笼金额正常待收款非按揭待收款,0)) as 未回笼金额正常待收款合计,
		   --0 AS 未回笼金额逾期待收款非按揭逾期待收款,
           SUM(isnull(skplan.未回笼金额逾期待收款非按揭逾期待收款,0)) AS 未回笼金额逾期待收款非按揭逾期待收款,
           0 AS 未回笼金额逾期待收款按揭逾期待收款,
           --0 AS 签约未回笼金额逾期待收款非按揭逾期待收款,
		   SUM(isnull(skplan.未回笼金额逾期待收款非按揭逾期待收款,0)) AS 签约未回笼金额逾期待收款非按揭逾期待收款,
           0 AS 签约未回笼金额逾期待收款按揭逾期待收款,
           --0 AS 未回笼金额逾期待收款逾期合计,
		   SUM(isnull(skplan.未回笼金额逾期待收款非按揭逾期待收款,0)) AS 未回笼金额逾期待收款逾期合计,
           --SUM(a.TotalAmount) - CASE
           --                         WHEN mp.是否计算回笼按规则判断 = '否' THEN
           --                             0
           --                         ELSE
           --                             SUM(t.huilongjiner)
           --                     END AS 待收款合计,
           SUM(   CASE
                      WHEN
                  --mp.是否计算回笼按规则判断 = '否'  OR 
                  a.YjType IN ( '经营类(租金)', '收购类项目已售业绩认定', '品牌管理费' ) THEN
                  0
                      ELSE ISNULL(a.TotalAmount, 0) - ISNULL(t.huilongjiner, 0)
                  END
              ) AS 待收款合计,
           0 AS 其中待收补差款合计,
           0 AS 房款回笼率,
           0 AS 房款逾期率,
           0 AS 非按揭房款逾期率,
           0 AS 累计回笼金额大于累计认购金额,
           0 AS 逾期款加正常款不等于总额,
           0 AS 按揭款加非按揭款不等于总额,
           0 AS [累计预收款],
           0 AS [本年预收款],
           0 AS [本月预收款],
           0 AS [关闭交易本年退款金额],
           0 AS [关闭交易本月退款金额],
           0 AS [认购累计待收款],
           SUM(   CASE
                      WHEN
                  --mp.是否计算回笼按规则判断 = '否' OR 
                  a.YjType IN ( '经营类(租金)', '收购类项目已售业绩认定', '品牌管理费' ) THEN
                  0
                      ELSE ISNULL(a.TotalAmount, 0) - ISNULL(t.huilongjiner, 0)
                  END
              ) AS [签约累计待收款],

           --本日
           0 AS 应退未退本日金额,
           0 AS 本日回笼金额签约,
           0 AS 本日回笼金额认购,
           0 AS 关闭交易本日退款金额,
           mp.ProjStatus AS 项目状态,
           mp.ProjGUID AS TopProjGUID,
           --本年签约
           SUM(   CASE
                      WHEN DATEDIFF(yy, a.RdDate, @var_endDate) = 0 THEN
                           a.TotalAmount
                      ELSE 0
                  END
              ) AS 本年房间成交金额,
           0 AS 本年装修款,
           0 AS 本年附属房间成交金额,
           0 AS 本年补差款,
           SUM(   CASE
                      WHEN DATEDIFF(yy, a.RdDate, @var_endDate) = 0 THEN
                           a.TotalAmount
                      ELSE 0
                  END
              ) AS 本年交易金额,
           SUM(   CASE
                      WHEN DATEDIFF(yy, a.RdDate, @var_endDate) = 0 THEN
                           a.TotalAmount
                      ELSE 0
                  END
              ) AS 本年签约金额,
           --特殊业绩
           0 AS 累计特殊业绩待收款,
           SUM(   CASE
                      WHEN tt.IsRelatedBuildingsRoom = 1
                           --AND
                           --(
                           --     ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                           --     OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                           -- )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.huilongjiner, 0)
                      ELSE 0
                  END
              ) AS 累计特殊业绩关联房间,
           SUM(   CASE
                      WHEN a.YjType IN ( '经营类(租金)', '收购类项目已售业绩认定', '品牌管理费' )
                           -- AND
                           --  (
                           --      ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                           --      OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                           --   )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.huilongjiner, 0)
                      ELSE 0
                  END
              ) AS 累计经营类特殊业绩关联房间,
           SUM(   CASE
                      WHEN tt.IsRelatedBuildingsRoom = 0
                           --AND
                           -- (
                           --     ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                           --     OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                           --  )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.huilongjiner, 0)
                      ELSE 0
                  END
              ) AS 累计特殊业绩未关联房间,
           SUM(   CASE
                      WHEN tt.IsRelatedBuildingsRoom = 1
                           -- AND
                           -- (
                           --      ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                           --      OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                           --  )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.bnhuilongjiner, 0)
                      ELSE 0
                  END
              ) AS 本年特殊业绩关联房间,
           SUM(   CASE
                      WHEN a.YjType = '经营类(租金)'
                           AND
                           (
                               ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                               OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                           )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.bnhuilongjiner, 0)
                      ELSE 0
                  END
              ) AS 本年经营类特殊业绩关联房间,
           SUM(   CASE
                      WHEN tt.IsRelatedBuildingsRoom = 0
                           --AND
                           --  (
                           --      ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                           --      OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                           --  )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.bnhuilongjiner, 0)
                      ELSE 0
                  END
              ) AS 本年特殊业绩未关联房间,
           SUM(   CASE
                      WHEN tt.IsRelatedBuildingsRoom = 1
                           --  AND
                           --  (
                           --       ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                           --       OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                           --  )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.byhuilongjiner, 0)
                      ELSE 0
                  END
              ) AS 本月特殊业绩关联房间,
           SUM(   CASE
                      WHEN a.YjType IN ( '经营类(租金)' )
                           --   AND
                           --   (
                           --       ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                           --       OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                           --   )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.byhuilongjiner, 0)
                      ELSE 0
                  END
              ) AS 本月经营类特殊业绩关联房间,
           SUM(   CASE
                      WHEN tt.IsRelatedBuildingsRoom = 0
                           -- AND
                           -- (
                           --     ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                           --     OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                           -- )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.byhuilongjiner, 0)
                      ELSE 0
                  END
              ) AS 本月特殊业绩未关联房间,
           SUM(   CASE
                      WHEN tt.IsRelatedBuildingsRoom = 1
                           -- AND
                           --  (
                           --      ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                           --      OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                           --  )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.brhuilongjiner, 0)
                      ELSE 0
                  END
              ) AS 本日特殊业绩关联房间,
           SUM(   CASE
                      WHEN a.YjType IN ( '经营类(租金)' )
                           --   AND
                           --    (
                           --        ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                           --        OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                           --    )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.brhuilongjiner, 0)
                      ELSE 0
                  END
              ) AS 本日经营类特殊业绩关联房间,
           SUM(   CASE
                      WHEN tt.IsRelatedBuildingsRoom = 0
                           --   AND
                           --  (
                           --       ISNULL(mp.是否计算回笼按规则判断, '是') = '是'
                           --       OR ISNULL(mp.是否计算回笼按规则判断, '是') = ''
                           --    )
                           AND sps.ifSelectPerformanceHkAmount = 1 THEN
                           ISNULL(t.brhuilongjiner, 0)
                      ELSE 0
                  END
              ) AS 本日特殊业绩未关联房间,
           SUM(   CASE
                      WHEN YEAR(a.rddate) = YEAR(GETDATE()) THEN
                           t.bnhuilongjinerfaj
                      ELSE 0
                  END
              ) AS 本年签约本年回笼非按揭回笼,
           SUM(   CASE
                      WHEN YEAR(a.rddate) = YEAR(GETDATE()) THEN
                           t.bnhuilongjineraj
                      ELSE 0
                  END
              ) AS 本年签约本年回笼按揭回笼,
           SUM(   CASE
                      WHEN YEAR(a.rddate) = YEAR(GETDATE()) THEN
                           t.bnhuilongjiner
                      ELSE 0
                  END
              ) AS 本年签约本年回笼回笼合计
    INTO #temp3
    FROM S_PerformanceAppraisal a
         LEFT JOIN #md mp ON a.ManagementProjectGUID = mp.ProjGUID
         LEFT JOIN dbo.p_Project p ON mp.ProjGUID = p.ProjGUID
         LEFT JOIN dbo.myBusinessUnit bu ON bu.BUGUID = p.BUGUID
         LEFT JOIN
         (
             SELECT projGUID,
                    MAX(LbProjectValue) AS LbProjectValue
             FROM mdm_LbProject
             WHERE LbProject = 'cwsybl'
             GROUP BY projGUID
         ) lbp ON lbp.projGUID = mp.ProjGUID
         LEFT JOIN
         (
             SELECT projGUID,
                    MAX(LbProjectValue) AS LbProjectValue
             FROM mdm_LbProject
             WHERE LbProject = 'sfjshl'
             GROUP BY projGUID
         ) sfjshl ON sfjshl.projGUID = mp.ProjGUID
         LEFT JOIN
         (
             SELECT v.SaleGUID,
                    SUM(   CASE
                               WHEN DATEDIFF(yy, g.GetDate, @var_endDate) = 0 THEN
                                    ISNULL(g.RmbAmount, 0)
                               ELSE 0
                           END
                       ) / 10000 AS bnhuilongjiner,
                    SUM(   CASE
                               WHEN DATEDIFF(yy, g.GetDate, @var_endDate) = 0
                                    AND g.itemtype = '非贷款类房款' THEN
                                    ISNULL(g.RmbAmount, 0)
                               ELSE 0
                           END
                       ) / 10000 AS bnhuilongjinerfaj,
                    SUM(   CASE
                               WHEN DATEDIFF(yy, g.GetDate, @var_endDate) = 0
                                    AND g.itemtype = '贷款类房款' THEN
                                    ISNULL(g.RmbAmount, 0)
                               ELSE 0
                           END
                       ) / 10000 AS bnhuilongjineraj,
                    SUM(   CASE
                               WHEN DATEDIFF(mm, g.GetDate, @var_endDate) = 0 THEN
                                    ISNULL(g.RmbAmount, 0)
                               ELSE 0
                           END
                       ) / 10000 AS byhuilongjiner,
                    SUM(   CASE
                               WHEN DATEDIFF(dd, g.GetDate, @var_endDate) = 0 THEN
                                    ISNULL(g.RmbAmount, 0)
                               ELSE 0
                           END
                       ) / 10000 AS brhuilongjiner,
                    SUM(ISNULL(g.RmbAmount, 0)) / 10000 AS huilongjiner
             FROM dbo.s_Voucher v
                  INNER JOIN dbo.s_Getin g ON g.VouchGUID = v.VouchGUID
             WHERE g.SaleType = '特殊业绩'
                   AND
                   (
                       v.VouchStatus IS NULL
                       OR v.VouchStatus = ''
                   )
             GROUP BY v.SaleGUID --,v.KpDate
         ) t ON t.SaleGUID = a.PerformanceAppraisalGUID
         --项目特殊业绩回笼统计规则设置表S_PerformanceProjectSet
         LEFT JOIN S_PerformanceProjectSet sps ON sps.ProjGUID = a.ManagementProjectGUID
         LEFT JOIN s_TsyjType tt ON a.YjType = tt.TsyjTypeName
		 LEFT JOIN (
					select PerformanceAppraisalGUID,
					       sum(case when DATEDIFF(dd, ReceiptPlanDate,GETDATE()) > 0 then YeAmount else 0 end)/ 10000 as 未回笼金额逾期待收款非按揭逾期待收款,
	                       sum(case when DATEDIFF(dd, ReceiptPlanDate,GETDATE()) <= 0 then YeAmount else 0 end)/ 10000 as 未回笼金额正常待收款非按揭待收款
                    from s_PerformanceAppraisalSkPlan
                    group by PerformanceAppraisalGUID
		            ) skplan on skplan.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
    WHERE
        --mp.Level = 2 AND  -- 桎钟那个收款表没有这个条件
        a.AuditStatus = '已审核'
        AND bu.BUGUID IN (
                             SELECT Value FROM [dbo].[fn_Split2](@var_buguid, ',')
                         )
        --AND a.ManagementProjectGUID NOT IN (
        --                                       SELECT TopProjGUID FROM #temp2
        --                                   )   --桎钟那个收款表没有这个条件

        AND a.yjtype IN ( '包销', '回购', '经营类(溢价款)', '其他销售', '整体销售' )
        --1、包销  取特殊业绩待收款
        --2、回购  取特殊业绩待收款
        --3、溢价类  取特殊业绩+房间待收款
        --4、品牌管理费  剔除
        --5、其他业绩  取特殊业绩待收款
        --6、收购类项目已售业绩认定  剔除
        --7、物业公司车位代销  取房间待收款
        --8、整体销售  取特殊业绩待收款
        AND a.PerformanceAppraisalGUID NOT IN (
                                                  --特殊业绩中的回购业绩里面的河南杓袁、刘庄、中原路项目为无偿移交政府安置房的，有签约无回笼无待收款，需剔除；
                                                  '92E02BF7-E2A3-EB11-B398-F40270D39969',
                                                  'D5A88B3A-3814-EC11-B398-F40270D39969',
                                                  '297ABBC6-00B7-EB11-B398-F40270D39969',
                                                  '782C17B5-DDA0-EB11-B398-F40270D39969',
                                                  '11CBE60E-DEA0-EB11-B398-F40270D39969',
                                                  '5598D9FB-78C3-EC11-B39C-F40270D39969',
                                                  'A1336061-21C1-EC11-B39C-F40270D39969',
                                                  '102B6166-DBAB-EC11-B39C-F40270D39969',
                                                  '62745AFB-89BC-EB11-B398-F40270D39969',
                                                  'FE08151F-43EF-EB11-B398-F40270D39969',
                                                  '8920D973-B400-EC11-B398-F40270D39969',
                                                  --其他业绩里面的四川成都市天府新区30亩、成都市新都区中石油项目实为REITS，春湖国际项目为未获取地块回迁房业绩，需剔除。
                                                  '012F31E6-3588-ED11-B3A2-F40270D39969',
                                                  '8080B7C7-B693-ED11-B3A2-F40270D39969',
                                                  '27568463-4587-ED11-B3A2-F40270D39969',
                                                  'A9A8DB66-3887-ED11-B3A2-F40270D39969'
                                              )
    GROUP BY bu.BUGUID,
             bu.BUName,
             p.ProjName,
             mp.ProjCode,
             mp.ProjGUID,
             mp.ProjName,
             mp.ProjStatus,
             mp.TradersWay,
             mp.BbWay,
             lbp.LbProjectValue,
             mp.是否计算回笼按规则判断;
    --特殊业绩如果前面temp1、temp2中的项目里已经关联了相关数据，为了防止重复计算，将对应的特殊业绩指标更新为0
    UPDATE t3
    SET t3.累计特殊业绩关联房间 = 0,
        t3.累计经营类特殊业绩关联房间 = 0,
        t3.累计特殊业绩未关联房间 = 0,
        t3.本年特殊业绩关联房间 = 0,
        t3.本年经营类特殊业绩关联房间 = 0,
        t3.本年特殊业绩未关联房间 = 0,
        t3.本月特殊业绩关联房间 = 0,
        t3.本月经营类特殊业绩关联房间 = 0,
        t3.本月特殊业绩未关联房间 = 0,
        t3.本日特殊业绩关联房间 = 0,
        t3.本日经营类特殊业绩关联房间 = 0,
        t3.本日特殊业绩未关联房间 = 0,
        t3.累计特殊业绩待收款 = 0
    FROM #temp3 t3
    WHERE t3.TopProjGUID IN (
                                SELECT TopProjGUID FROM #temp1 UNION ALL SELECT TopProjGUID FROM #temp2
                            );

    --非操盘和操盘项目及特殊业绩项目进行合并处理
    SELECT [qxDate],
           [BUGUID],
           [公司名称],
           [销售项目名称],
           [投管项目代码],
           [投管项目名称],
           [操盘方式],
           [并表方式],
           [项目权益比例],
           [项目标签是否计算回笼],
           SUM(ISNULL([累计房间成交金额], 0)) AS [累计房间成交金额],
           SUM(ISNULL([累计装修款], 0)) AS [累计装修款],
           SUM(ISNULL([累计附属房间成交金额], 0)) AS [累计附属房间成交金额],
           SUM(ISNULL([累计补差款], 0)) AS [累计补差款],
           SUM(ISNULL([累计交易金额], 0)) AS [累计交易金额],
           SUM(ISNULL([累计签约金额], 0)) AS [累计签约金额],
           SUM(ISNULL([应退未退累计金额], 0)) AS [应退未退累计金额],
           SUM(ISNULL([累计回笼金额签约], 0)) AS [累计回笼金额签约],
           SUM(ISNULL([累计回笼金额认购], 0)) AS [累计回笼金额认购],
           SUM(ISNULL([累计回笼金额其中补差款], 0)) AS [累计回笼金额其中补差款],
           SUM(ISNULL([累计回笼金额签约按揭], 0)) AS [累计回笼金额签约按揭],
           SUM(ISNULL([累计回笼金额认购按揭], 0)) AS [累计回笼金额认购按揭],
           SUM(ISNULL([累计回笼金额签约非按揭], 0)) AS [累计回笼金额签约非按揭],
           SUM(ISNULL([累计回笼金额认购非按揭], 0)) AS [累计回笼金额认购非按揭],
           SUM(ISNULL([应退未退本年金额], 0)) AS [应退未退本年金额],
           SUM(ISNULL([本年回笼金额签约], 0)) AS [本年回笼金额签约],
           SUM(ISNULL([本年回笼金额认购], 0)) AS [本年回笼金额认购],
           SUM(ISNULL([本年回笼金额其中补差款], 0)) AS [本年回笼金额其中补差款],
           SUM(ISNULL([本年回笼金额签约按揭], 0)) AS [本年回笼金额签约按揭],
           SUM(ISNULL([本年回笼金额认购按揭], 0)) AS [本年回笼金额认购按揭],
           SUM(ISNULL([本年回笼金额签约非按揭], 0)) AS [本年回笼金额签约非按揭],
           SUM(ISNULL([本年回笼金额认购非按揭], 0)) AS [本年回笼金额认购非按揭],
           SUM(ISNULL([应退未退本月金额], 0)) AS [应退未退本月金额],
           SUM(ISNULL([本月回笼金额签约], 0)) AS [本月回笼金额签约],
           SUM(ISNULL([本月回笼金额认购], 0)) AS [本月回笼金额认购],
           SUM(ISNULL([本月回笼金额其中补差款], 0)) AS [本月回笼金额其中补差款],
           SUM(ISNULL([本月回笼金额签约按揭], 0)) AS [本月回笼金额签约按揭],
           SUM(ISNULL([本月回笼金额认购按揭], 0)) AS [本月回笼金额认购按揭],
           SUM(ISNULL([本月回笼金额签约非按揭], 0)) AS [本月回笼金额签约非按揭],
           SUM(ISNULL([本月回笼金额认购非按揭], 0)) AS [本月回笼金额认购非按揭],
           SUM(ISNULL([本月签约本月回笼非按揭回笼], 0)) AS [本月签约本月回笼非按揭回笼],
           SUM(ISNULL([本月签约本月回笼按揭回笼], 0)) AS [本月签约本月回笼按揭回笼],
           SUM(ISNULL([本月签约本月回笼回笼合计], 0)) AS [本月签约本月回笼回笼合计],
           SUM(ISNULL([本年签约本月回笼非按揭回笼], 0)) AS [本年签约本月回笼非按揭回笼],
           SUM(ISNULL([本年签约本月回笼按揭回笼], 0)) AS [本年签约本月回笼按揭回笼],
           SUM(ISNULL([本年签约本月回笼回笼合计], 0)) AS [本年签约本月回笼回笼合计],
           SUM(ISNULL([未回笼金额正常待收款非按揭待收款], 0)) AS [未回笼金额正常待收款非按揭待收款],
           SUM(ISNULL([未回笼金额正常待收款按揭待收款], 0)) AS [未回笼金额正常待收款按揭待收款],
           SUM(ISNULL([签约未回笼金额正常待收款非按揭待收款], 0)) AS [签约未回笼金额正常待收款非按揭待收款],
           SUM(ISNULL([签约未回笼金额正常待收款按揭待收款], 0)) AS [签约未回笼金额正常待收款按揭待收款],
           SUM(ISNULL([未回笼金额正常待收款合计], 0)) AS [未回笼金额正常待收款合计],
           SUM(ISNULL([未回笼金额逾期待收款非按揭逾期待收款], 0)) AS [未回笼金额逾期待收款非按揭逾期待收款],
           SUM(ISNULL([未回笼金额逾期待收款按揭逾期待收款], 0)) AS [未回笼金额逾期待收款按揭逾期待收款],
           SUM(ISNULL([签约未回笼金额逾期待收款非按揭逾期待收款], 0)) AS [签约未回笼金额逾期待收款非按揭逾期待收款],
           SUM(ISNULL([签约未回笼金额逾期待收款按揭逾期待收款], 0)) AS [签约未回笼金额逾期待收款按揭逾期待收款],
           SUM(ISNULL([未回笼金额逾期待收款逾期合计], 0)) AS [未回笼金额逾期待收款逾期合计],
           SUM(ISNULL([待收款合计], 0)) AS [待收款合计],
           SUM(ISNULL([其中待收补差款合计], 0)) AS [其中待收补差款合计],
           SUM(ISNULL([房款回笼率], 0)) AS [房款回笼率],
           SUM(ISNULL([房款逾期率], 0)) AS [房款逾期率],
           SUM(ISNULL([非按揭房款逾期率], 0)) AS [非按揭房款逾期率],
           SUM(ISNULL([累计回笼金额大于累计认购金额], 0)) AS [累计回笼金额大于累计认购金额],
           SUM(ISNULL([逾期款加正常款不等于总额], 0)) AS [逾期款加正常款不等于总额],
           SUM(ISNULL([按揭款加非按揭款不等于总额], 0)) AS [按揭款加非按揭款不等于总额],
           SUM(ISNULL([累计预收款], 0)) AS [累计预收款],
           SUM(ISNULL([本年预收款], 0)) AS [本年预收款],
           SUM(ISNULL([本月预收款], 0)) AS [本月预收款],
           SUM(ISNULL([关闭交易本年退款金额], 0)) AS [关闭交易本年退款金额],
           SUM(ISNULL([关闭交易本月退款金额], 0)) AS [关闭交易本月退款金额],
           SUM(ISNULL([认购累计待收款], 0)) AS [认购累计待收款],
           SUM(ISNULL([签约累计待收款], 0)) AS [签约累计待收款],
           NEWID() AS qxGuid,
           SUM(ISNULL([应退未退本日金额], 0)) AS [应退未退本日金额],
           SUM(ISNULL([本日回笼金额签约], 0)) AS [本日回笼金额签约],
           SUM(ISNULL([本日回笼金额认购], 0)) AS [本日回笼金额认购],
           SUM(ISNULL([关闭交易本日退款金额], 0)) AS [关闭交易本日退款金额],
           MAX([项目状态]) 项目状态,
           [topprojguid],
           SUM(ISNULL(本年房间成交金额, 0)) AS 本年房间成交金额,
           SUM(ISNULL(本年装修款, 0)) AS 本年装修款,
           SUM(ISNULL(本年附属房间成交金额, 0)) AS 本年附属房间成交金额,
           SUM(ISNULL(本年补差款, 0)) AS 本年补差款,
           SUM(ISNULL(本年交易金额, 0)) AS 本年交易金额,
           SUM(ISNULL(本年签约金额, 0)) AS 本年签约金额,
           SUM(ISNULL(累计特殊业绩待收款, 0)) AS 累计特殊业绩待收款,
           SUM(ISNULL(累计特殊业绩关联房间, 0)) AS 累计特殊业绩关联房间,
           SUM(ISNULL(累计特殊业绩未关联房间, 0)) AS 累计特殊业绩未关联房间,
           SUM(ISNULL(本年特殊业绩关联房间, 0)) AS 本年特殊业绩关联房间,
           SUM(ISNULL(本年特殊业绩未关联房间, 0)) AS 本年特殊业绩未关联房间,
           SUM(ISNULL(本月特殊业绩关联房间, 0)) AS 本月特殊业绩关联房间,
           SUM(ISNULL(本月特殊业绩未关联房间, 0)) AS 本月特殊业绩未关联房间,
           SUM(ISNULL(本日特殊业绩关联房间, 0)) AS 本日特殊业绩关联房间,
           SUM(ISNULL(本日特殊业绩未关联房间, 0)) AS 本日特殊业绩未关联房间,
           SUM(ISNULL([本年签约本年回笼非按揭回笼], 0)) AS [本年签约本年回笼非按揭回笼],
           SUM(ISNULL([本年签约本年回笼按揭回笼], 0)) AS [本年签约本年回笼按揭回笼],
           SUM(ISNULL([本年签约本年回笼回笼合计], 0)) AS [本年签约本年回笼回笼合计],
           SUM(ISNULL(累计经营类特殊业绩关联房间, 0)) AS 累计经营类特殊业绩关联房间,
           SUM(ISNULL(本年经营类特殊业绩关联房间, 0)) AS 本年经营类特殊业绩关联房间,
           SUM(ISNULL(本月经营类特殊业绩关联房间, 0)) AS 本月经营类特殊业绩关联房间,
           SUM(ISNULL(本日经营类特殊业绩关联房间, 0)) AS 本日经营类特殊业绩关联房间,
           SUM(   CASE
                      WHEN tt.业绩类型 = '合作业绩'
                           AND tt.项目标签是否计算回笼 = '是' THEN
                           签约累计待收款
                      ELSE 0
                  END
              ) AS 合作业绩待收款,
           SUM(   CASE
                      WHEN tt.业绩类型 <> '合作业绩'
                           AND tt.项目标签是否计算回笼 = '是' THEN
                           签约累计待收款
                      ELSE 0
                  END
              ) AS 非合作业绩待收款
    INTO #temp4
    FROM
    (
        SELECT *
        FROM #temp1
        UNION ALL
        SELECT *
        FROM #temp2
        UNION ALL
        SELECT *
        FROM #temp3
    ) tt
    WHERE topprojguid NOT IN ( '293175BC-A947-E811-80BA-E61F13C57837', '24557EBC-70A7-E811-80BF-E61F13C57837',
                               'B9E22E4A-70A7-E811-80BF-E61F13C57837', '70ABA7A4-0B3B-E811-80BA-E61F13C57837',
                               'E3685D26-F046-E911-80B7-0A94EF7517DD', '26F1F4C4-4DA7-E811-80BF-E61F13C57837',
                               '94FA3898-70A7-E811-80BF-E61F13C57837'
                             )
    GROUP BY [qxDate],
             [BUGUID],
             [公司名称],
             [销售项目名称],
             [投管项目代码],
             [投管项目名称],
             [操盘方式],
             [并表方式],
             [项目权益比例],
                           --[项目状态],
             [项目标签是否计算回笼], ----------20240428新增
             [topprojguid];



    --输出查询结果
    SELECT *
    FROM #temp4;

    --删除临时表
    DROP TABLE #temp1;
    DROP TABLE #temp2hhh;
    DROP TABLE #temp2;
    DROP TABLE #temp3;
    DROP TABLE #temp4;
    DROP TABLE #md;
    DROP TABLE #s_YJRLProducteDetail;

    DROP TABLE #hzhl;
    DROP TABLE #合作业绩已审核部分,
               #应收,
               #待收,
               #应收待收,
			   #tsyjzqy;

END;