SELECT ImportSaleProjGUID,
       ProjGUID,
       OrgCompanyGUID BUGUID
INTO #p
FROM mdm_Project
WHERE Level = 2
      AND DevelopmentCompanyGUID = 'AADC0FA7-9546-49C9-B64B-825056C828ED';


--获取DSS任务
SELECT p.BUGUID,
       p.ProjGUID,
       SUM(a.[签约任务(亿元)]) * 10000.0 年度签约任务
INTO #nd
FROM dss.dbo.[nmap_F_平台公司项目层级年度任务填报] a
     INNER JOIN dss.dbo.nmap_F_FillHistory f ON f.FillHistoryGUID = a.FillHistoryGUID
     INNER JOIN #p p ON p.ProjGUID = a.BusinessGUID
WHERE YEAR(f.BeginDate) = YEAR(GETDATE())
GROUP BY p.BUGUID,
         p.ProjGUID;

SELECT p.BUGUID,
       p.ProjGUID,
       SUM(a.[签约任务(亿元)]) * 10000.0 月度签约任务
INTO #yd
FROM dss.dbo.[nmap_F_平台公司项目层级月度任务填报] a
     INNER JOIN dss.dbo.nmap_F_FillHistory f ON f.FillHistoryGUID = a.FillHistoryGUID
     LEFT JOIN dbo.mdm_Project mp ON mp.ProjGUID = a.BusinessGUID
     INNER JOIN #p p ON p.ProjGUID = a.BusinessGUID
WHERE DATEDIFF(MONTH, f.BeginDate, GETDATE()) = 0
GROUP BY p.BUGUID,
         p.ProjGUID;

--产成品
SELECT cc.SaleBldGUID
INTO #ccp
FROM dbo.s_ccpsuodingbld cc
     INNER JOIN dbo.mdm_SaleBuild sb ON sb.SaleBldGUID = cc.SaleBldGUID
     INNER JOIN mdm_GCBuild gc ON gc.GCBldGUID = sb.GCBldGUID
     INNER JOIN #p p ON cc.投管一级guid = p.ProjGUID
WHERE YEAR(ISNULL(gc.JgbabFactDate, '2099-01-01')) < YEAR(GETDATE());

--获取房间没有关联到特殊业绩的房间明细,以便操盘项目跟特殊业绩不会重复计算该房间业绩
SELECT a.RoomGUID,
       a.BldGUID,
       a.BldArea
INTO #room
FROM p_room a
WHERE a.RoomGUID NOT IN (
                            SELECT sr.RoomGUID
                            FROM dbo.S_PerformanceAppraisalRoom sr
                                 INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                                            AND s.AuditStatus = '已审核'
                                                                            AND s.yjtype NOT IN ( '经营类(溢价款)',
                                                                                                  '物业公司车位代销'
                                                                                                )
                        )
      AND a.BldGUID NOT IN (
                               SELECT sr.BldGUID
                               FROM dbo.S_PerformanceAppraisalBuildings sr
                                    INNER JOIN dbo.S_PerformanceAppraisal s ON s.PerformanceAppraisalGUID = sr.PerformanceAppraisalGUID
                                                                               AND s.AuditStatus = '已审核'
                                                                               AND s.yjtype NOT IN ( '经营类(溢价款)',
                                                                                                     '物业公司车位代销'
                                                                                                   )

                           )
      AND EXISTS
(
    SELECT 1 FROM #p p WHERE a.BUGUID = p.BUGUID
);

--缓存认购
SELECT ISNULL(p1.ProjGUID, p.ProjGUID) projguid,
       SUM(   CASE
                  WHEN DATEDIFF(dd, o.QSDate, GETDATE()) = 0
                       AND YEAR(o.QSDate) = YEAR(GETDATE())
                       AND o.Status = '激活' THEN o.JyTotal
                  WHEN DATEDIFF(dd, o.QSDate, GETDATE()) = 0
                       AND YEAR(o.QSDate) = YEAR(GETDATE())
                       AND sc.Status = '激活' THEN sc.JyTotal ELSE 0 END
          ) / 10000 brrg,
       SUM(   CASE
                  WHEN MONTH(o.QSDate) = MONTH(GETDATE())
                       AND YEAR(o.QSDate) = YEAR(GETDATE())
                       AND o.Status = '激活' THEN o.JyTotal
                  WHEN MONTH(o.QSDate) = MONTH(GETDATE())
                       AND YEAR(o.QSDate) = YEAR(GETDATE())
                       AND sc.Status = '激活' THEN sc.JyTotal ELSE 0 END
          ) / 10000 rg,
       SUM(   CASE
                  WHEN YEAR(o.QSDate) = YEAR(GETDATE())
                       AND o.Status = '激活' THEN o.JyTotal
                  WHEN YEAR(o.QSDate) = YEAR(GETDATE())
                       AND sc.Status = '激活' THEN sc.JyTotal ELSE 0 END
          ) / 10000 nrg, --年度认购万元  --hegj
       SUM(CASE WHEN o.Status = '激活' THEN o.JyTotal ELSE 0 END) / 10000 rgwqy
INTO #order
FROM s_Order o
     INNER JOIN #room a ON a.RoomGUID = o.RoomGUID
     LEFT JOIN dbo.p_Project p ON p.ProjGUID = o.ProjGUID
     LEFT JOIN dbo.p_Project p1 ON p.ParentCode = p1.ProjCode
     LEFT JOIN dbo.s_Contract sc ON sc.Status = '激活'
                                    AND sc.TradeGUID = o.TradeGUID
WHERE 1 = 1
      AND
      (
          o.Status = '激活'
          OR
          (
              o.CloseReason = '转签约'
              AND sc.Status = '激活'
              AND YEAR(o.QSDate) = YEAR(GETDATE())
          )
      )
GROUP BY ISNULL(p1.ProjGUID, p.ProjGUID);

--缓存签约
SELECT ISNULL(p1.ProjGUID, p.ProjGUID) projguid,
       SUM(   CASE
                  WHEN DATEDIFF(YEAR, c.QSDate, GETDATE()) = 0 THEN c.JyTotal ELSE 0 END
          ) / 10000 nqy,
       SUM(   CASE
                  WHEN DATEDIFF(DAY, c.QSDate, GETDATE()) = 0 THEN c.JyTotal ELSE 0 END
          ) / 10000 brqy,
       SUM(   CASE
                  WHEN DATEDIFF(MONTH, c.QSDate, GETDATE()) = 0 THEN c.JyTotal ELSE 0 END
          ) / 10000 yqy,
                                                                                      --获取直接签约的金额
       SUM(   CASE
                  WHEN DATEDIFF(YEAR, c.QSDate, GETDATE()) = 0
                       AND so.OrderGUID IS NULL THEN c.JyTotal ELSE 0 END
          ) / 10000 nrg,
       SUM(   CASE
                  WHEN DATEDIFF(DAY, c.QSDate, GETDATE()) = 0
                       AND so.OrderGUID IS NULL THEN c.JyTotal ELSE 0 END
          ) / 10000 brrg,
       SUM(   CASE
                  WHEN DATEDIFF(MONTH, c.QSDate, GETDATE()) = 0
                       AND so.OrderGUID IS NULL THEN c.JyTotal ELSE 0 END
          ) / 10000 yrg,
                                                                                      --hegj
       SUM(   CASE
                  WHEN DATEDIFF(MONTH, c.QSDate, GETDATE()) = 0
                       AND bd.ProductType <> '地下室/车库' THEN c.JyTotal ELSE 0 END
          ) yqyfcw,                                                                   --月度非车位签约金额元
       SUM(   CASE
                  WHEN DATEDIFF(MONTH, c.QSDate, GETDATE()) = 0
                       AND bd.ProductType <> '地下室/车库' THEN a.BldArea ELSE 0 END
          ) yqymjfcw,                                                                 --月度非车位签约面积
       SUM(   CASE
                  WHEN bd.ProductType <> '地下室/车库'
                       AND DATEDIFF(YEAR, c.QSDate, GETDATE()) = 0 THEN c.JyTotal ELSE 0 END
          ) nqyfcw,                                                                   --年度非车位签约金额
       SUM(   CASE
                  WHEN bd.ProductType <> '地下室/车库'
                       AND DATEDIFF(YEAR, c.QSDate, GETDATE()) = 0 THEN a.BldArea ELSE 0 END
          ) nqymjfcw,                                                                 --年度非车位签约面积
       SUM(CASE WHEN bd.ProductType <> '地下室/车库' THEN c.JyTotal ELSE 0 END) Ljqyfcw,   --累计非车位签约金额
       SUM(CASE WHEN bd.ProductType <> '地下室/车库' THEN a.BldArea ELSE 0 END) Ljqymjfcw, --累计非车位签约面积
                                                                                      --产成品 
       SUM(   CASE
                  WHEN DATEDIFF(DAY, c.QSDate, GETDATE()) = 0
                       AND cc.SaleBldGUID IS NOT NULL THEN c.JyTotal ELSE 0 END
          ) brcqy,                                                                    --产日签金
       SUM(   CASE
                  WHEN DATEDIFF(MONTH, c.QSDate, GETDATE()) = 0
                       AND cc.SaleBldGUID IS NOT NULL THEN c.JyTotal ELSE 0 END
          ) bycqy,                                                                    --产月签金
       SUM(   CASE
                  WHEN DATEDIFF(YEAR, c.QSDate, GETDATE()) = 0
                       AND cc.SaleBldGUID IS NOT NULL THEN c.JyTotal ELSE 0 END
          ) bncqy                                                                     --产年签金
INTO #con
FROM s_Contract c
     LEFT JOIN dbo.p_Project p ON p.ProjGUID = c.ProjGUID
     LEFT JOIN dbo.p_Project p1 ON p.ParentCode = p1.ProjCode
     INNER JOIN #room a ON a.RoomGUID = c.RoomGUID
     LEFT JOIN dbo.s_Order so ON ISNULL(so.TradeGUID, '') = ISNULL(c.TradeGUID, '')
     INNER JOIN dbo.p_Building bd ON a.BldGUID = bd.BldGUID
     LEFT JOIN mdm_SaleBuild sb ON bd.BldGUID = sb.ImportSaleBldGUID
     --增加产成品判断
     LEFT JOIN #ccp cc ON sb.SaleBldGUID = cc.SaleBldGUID
WHERE 1 = 1
      AND c.Status = '激活'
      AND
      (
          (
              so.Status = '关闭'
              AND so.CloseReason = '转签约'
          )
          OR so.TradeGUID IS NULL
      )
GROUP BY ISNULL(p1.ProjGUID, p.ProjGUID);


--获取操盘项目完成情况
SELECT mp.BUGUID BUGUID,
       mp.ProjGUID,
       ISNULL(SUM(rg.brrg), 0) + ISNULL(SUM(qy.brrg), 0) AS '本日认购',
       ISNULL(SUM(rg.rg), 0) + ISNULL(SUM(qy.yrg), 0) AS '月度认购',
       ISNULL(SUM(rg.rgwqy), 0) AS '认购未签约',
       ISNULL(SUM(qy.brqy), 0) AS '本日签约',
       ISNULL(SUM(qy.yqy), 0) AS '月度签约',
       ISNULL(SUM(qy.nqy), 0) AS '年度签约',                          --增加特殊业绩
                                                                  --  ISNULL(SUM(qy.nqy), 0) + ISNULL(SUM(ts.TotalAmount), 0) AS '年度签约', --增加特殊业绩
       ISNULL(SUM(hk.yhk), 0) AS '月度回款',
       ISNULL(SUM(hk.nhk), 0) AS '年度回款',
                                                                  --产成品 --hegj
       ISNULL(SUM(qy.yqyfcw), 0) AS '月度非车位签约金额元',
       ISNULL(SUM(qy.yqymjfcw), 0) AS '月度非车位签约面积',
       ISNULL(SUM(qy.nqyfcw), 0) AS '年度非车位签约金额元',
       ISNULL(SUM(qy.nqymjfcw), 0) AS '年度非车位签约面积',
       ISNULL(SUM(qy.Ljqyfcw), 0) AS '累计非车位签约金额元',
       ISNULL(SUM(qy.Ljqymjfcw), 0) AS '累计非车位签约面积',
       ISNULL(SUM(rg.nrg), 0) + ISNULL(SUM(qy.nrg), 0) AS '年度认购', --hegj
       ISNULL(SUM(qy.brcqy), 0) AS '产日签金',
       ISNULL(SUM(qy.bycqy), 0) AS '产月签金',
       ISNULL(SUM(qy.bncqy), 0) AS '产年签金'
INTO #t
FROM #p mp
     LEFT JOIN #order rg ON rg.projguid = ISNULL(mp.ImportSaleProjGUID, mp.ProjGUID)
     LEFT JOIN #con qy ON qy.projguid = ISNULL(mp.ImportSaleProjGUID, mp.ProjGUID)
     LEFT JOIN
     (
         SELECT a.TopProjGUID Projguid,
                ISNULL(a.本月回笼金额认购, 0) + ISNULL(a.本月回笼金额签约, 0) + ISNULL(a.应退未退本月金额, 0) + ISNULL(a.关闭交易本月退款金额, 0)
                + ISNULL(a.本月特殊业绩关联房间, 0) + ISNULL(a.本月特殊业绩未关联房间, 0) AS yhk,
                ISNULL(a.本年回笼金额认购, 0) + ISNULL(a.本年回笼金额签约, 0) + ISNULL(a.应退未退本年金额, 0) + ISNULL(a.关闭交易本年退款金额, 0)
                + ISNULL(a.本年特殊业绩关联房间, 0) + ISNULL(a.本年特殊业绩未关联房间, 0) AS nhk
         FROM s_gsfkylbhzb a
              INNER JOIN #p p ON a.TopProjGUID = p.ProjGUID
         WHERE DATEDIFF(DAY, a.qxDate, GETDATE()) = 0
     ) hk ON mp.ProjGUID = hk.Projguid
     LEFT JOIN
     (
         SELECT mp.ProjGUID,
                SUM(s.AreaTotal) AS AreaTotal,
                SUM(s.TotalAmount) AS TotalAmount
         FROM S_PerformanceAppraisal AS s
              INNER JOIN #p mp ON mp.ProjGUID = s.ManagementProjectGUID
         WHERE s.Year = YEAR(GETDATE())
         GROUP BY mp.ProjGUID
     ) ts ON ts.ProjGUID = mp.ProjGUID
GROUP BY mp.BUGUID,
         mp.ProjGUID;

--获取非操盘项目完成情况
-- 合作业绩
SELECT c.BUGuid,
       c.ProjGUID,
       SUM(   CASE
                  WHEN b.DateYear = YEAR(GETDATE())
                       AND b.datemonth = MONTH(GETDATE()) THEN a.Amount ELSE 0 END
          ) AS '月度认购',
       SUM(CASE WHEN b.DateYear = YEAR(GETDATE()) THEN a.Amount ELSE 0 END) AS '年度认购', --hegj
       SUM(   CASE
                  WHEN b.DateYear = YEAR(GETDATE())
                       AND b.datemonth = MONTH(GETDATE()) THEN a.Amount ELSE 0 END
          ) AS '月度签约',
       SUM(CASE WHEN b.DateYear = YEAR(GETDATE()) THEN a.Amount ELSE 0 END) AS '年度签约',
       SUM(   CASE
                  WHEN b.DateYear = YEAR(GETDATE())
                       AND b.datemonth = MONTH(GETDATE()) THEN a.huilongjiner ELSE 0 END
          ) AS '月度回款',
       SUM(CASE WHEN b.DateYear = YEAR(GETDATE()) THEN a.huilongjiner ELSE 0 END) AS '年度回款'
INTO #t1
FROM dbo.s_YJRLProducteDescript a
     LEFT JOIN
     (
         SELECT *,
                CONVERT(DATETIME, b.DateYear + '-' + b.DateMonth + '-01') AS [BizDate]
         FROM dbo.s_YJRLProducteDetail b
     ) b ON b.ProducteDetailGUID = a.ProducteDetailGUID
     LEFT JOIN dbo.s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
     INNER JOIN #p p ON p.ProjGUID = c.ProjGUID
WHERE 1 = 1
      AND b.Shenhe = '审核'
      AND b.DateYear = YEAR(GETDATE())
GROUP BY c.BUGuid,
         c.ProjGUID;


----加上特殊业绩
SELECT t.BUGUID,
       t.ProjGUID,
       SUM(t.BNJE) BNJE,
       SUM(t.BYJE) ByJE
INTO #ts
FROM
(
    SELECT p.BUGUID,
           p.ProjGUID,
           SUM(   CASE
                      WHEN YEAR(a.RdDate) = YEAR(GETDATE()) THEN a.TotalAmount ELSE 0 END
              ) BNJE,
           SUM(   CASE
                      WHEN DATEDIFF(m, ISNULL(RdDate, a.CreationTime), GETDATE()) = 0 THEN a.TotalAmount ELSE 0 END
              ) BYJE
    FROM dbo.S_PerformanceAppraisal a
         LEFT JOIN #p p ON p.ProjGUID = a.ManagementProjectGUID
    WHERE 1 = 1
          AND a.AuditStatus = '已审核'
          AND a.YjType IN (
                              SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom = 0
                          )
    GROUP BY p.BUGUID,
             p.ProjGUID
    UNION ALL
    SELECT p.BUGUID,
           p.ProjGUID,
           SUM(   CASE
                      WHEN YEAR(a.rddate) = YEAR(GETDATE()) THEN b.totalamount ELSE 0 END
              ) BNJE,
           SUM(   CASE
                      WHEN DATEDIFF(m, ISNULL(rddate, a.CreationTime), GETDATE()) = 0 THEN b.totalamount ELSE 0 END
              ) BYJE
    FROM S_PerformanceAppraisal a
         LEFT JOIN
         (
             SELECT PerformanceAppraisalGUID,
                    BldGUID,
                    IdentifiedArea areatotal,
                    AffirmationNumber AggregateNumber,
                    AmountDetermined totalamount
             FROM dbo.S_PerformanceAppraisalBuildings
             UNION ALL
             SELECT PerformanceAppraisalGUID,
                    r.ProductBldGUID BldGUID,
                    SUM(a.IdentifiedArea),
                    SUM(a.AffirmationNumber),
                    SUM(a.AmountDetermined)
             FROM dbo.S_PerformanceAppraisalRoom a
                  LEFT JOIN MyCost_Erp352.dbo.md_Room r ON a.RoomGUID = r.RoomGUID
             GROUP BY PerformanceAppraisalGUID,
                      r.ProductBldGUID
         ) b ON a.PerformanceAppraisalGUID = b.PerformanceAppraisalGUID
         INNER JOIN #p p ON p.ProjGUID = a.ManagementProjectGUID
    WHERE 1 = 1
          AND a.AuditStatus = '已审核'
          AND a.YjType IN (
                              SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom = 1
                          )
    GROUP BY p.BUGUID,
             p.ProjGUID
) t
GROUP BY t.BUGUID,
         t.ProjGUID;

--获取汇总数据
SELECT
    --ROW_NUMBER() OVER ( PARTITION BY c.BUGUID
    --                            ORDER BY CASE WHEN SUM(y.月度签约任务) <> 0 THEN SUM(t.月度签约) / SUM(y.月度签约任务)
    --                                          ELSE 0
    --                                     END DESC ,
    --                                     SUM(t.月度签约) DESC ,
    --                                     SUM(t.年度签约) DESC ,
    --                                     SUM(t.月度认购) DESC ,
    --                                     SUM(t.产月签金) DESC ,
    --                                     SUM(t.产年签金) DESC ,
    --                                     p.SpreadName ) num ,
    c.BUGUID,
    c.ProjGUID,
    p.SpreadName 推广名,
    SUM(isnull(t.本日认购,0)) / 10000.0 AS '本日认购',
    SUM(isnull(t.认购未签约,0)) / 10000.0 AS '认购未签约',
    SUM(isnull(t.本日签约,0)) / 10000.0 AS '本日签约',
    SUM(isnull(t.月度认购,0)) / 10000.0 AS '月度认购',
    SUM(isnull(y.月度签约任务,0)) / 10000.0 AS '月签约任务',
    SUM(isnull(t.月度签约,0)) / 10000.0 AS '月度签约',
    CASE
        WHEN SUM(isnull(y.月度签约任务,0)) = 0 THEN 0 ELSE CONVERT(DECIMAL(18, 4), SUM(isnull(t.月度签约,0)) / SUM(isnull(y.月度签约任务,0))) END AS '月签约完成率',
    SUM(isnull(n.年度签约任务,0)) / 10000.0 AS '年签约任务',
    SUM(isnull(t.年度签约,0)) / 10000.0 AS '年度签约',
    CASE WHEN SUM(isnull(n.年度签约任务,0)) = 0 THEN 0 ELSE SUM(isnull(t.年度签约,0)) / SUM(isnull(n.年度签约任务,0)) END AS '年签约完成率',
                                   --hegj
    SUM(isnull(t.月度非车位签约金额元,0)) AS '月度非车位签约金额元',
    SUM(isnull(t.月度非车位签约面积,0)) AS '月度非车位签约面积',
    CASE
        WHEN SUM(t.月度非车位签约金额元) = 0 THEN 0 ELSE SUM(t.月度非车位签约金额元) / SUM(t.月度非车位签约面积) END AS '月度非车位签约均价',
    SUM(t.年度非车位签约金额元) AS '年度非车位签约金额元',
    SUM(t.年度非车位签约面积) AS '年度非车位签约面积',
    CASE
        WHEN SUM(t.年度非车位签约金额元) = 0 THEN 0 ELSE SUM(t.年度非车位签约金额元) / SUM(t.年度非车位签约面积) END AS '年度非车位签约均价',
    SUM(t.累计非车位签约金额元) AS '累计非车位签约金额元',
    SUM(t.累计非车位签约面积) AS '累计非车位签约面积',
    CASE
        WHEN SUM(t.累计非车位签约面积) = 0 THEN 0 ELSE SUM(t.累计非车位签约金额元) / SUM(t.累计非车位签约面积) END AS '累计非车位签约均价',
    SUM(isnull(t.年度认购,0)) / 10000.0 AS '年度认购', --hegj
    SUM(isnull(t.产日签金,0)) / 10000.0 产日签金,      --产成品日签(元) 
    SUM(isnull(t.产月签金,0)) / 10000.0 产月签金,      --产成品月签(元) 
    SUM(isnull(t.产年签金,0)) / 100000000.0 产年签金   --产成品年签(元) 
INTO #hz
FROM #p c
     LEFT JOIN mdm_Project p ON c.ProjGUID = p.ProjGUID
     LEFT JOIN #nd n ON c.BUGUID = n.BUGUID
                        AND n.ProjGUID = c.ProjGUID
     LEFT JOIN #yd y ON y.BUGUID = c.BUGUID
                        AND y.ProjGUID = c.ProjGUID
     LEFT JOIN
     (
         SELECT a.BUGUID,
                a.ProjGUID,
                a.本日认购 AS 本日认购,
                a.认购未签约 AS 认购未签约,
                a.本日签约 AS 本日签约,
                a.月度认购 + ISNULL(b.月度认购, 0) + ISNULL(t.ByJE, 0) AS 月度认购,
                a.月度签约 + ISNULL(b.月度签约, 0) + ISNULL(t.ByJE, 0) AS 月度签约,
                a.年度签约 + ISNULL(b.年度签约, 0) + ISNULL(t.BNJE, 0) AS 年度签约,
                a.月度回款 AS 月度回款,
                a.年度回款 AS 年度回款,
                                                                        --hegj
                a.月度非车位签约金额元 AS 月度非车位签约金额元,
                a.月度非车位签约面积 AS 月度非车位签约面积,
                a.年度非车位签约金额元 AS 年度非车位签约金额元,
                a.年度非车位签约面积 AS 年度非车位签约面积,
                a.累计非车位签约金额元,
                a.累计非车位签约面积,
                a.年度认购 + ISNULL(b.年度认购, 0) + ISNULL(t.BNJE, 0) AS 年度认购, --hegj
                a.产日签金 产日签金,                                            --产成品日签(元)
                a.产月签金 产月签金,                                            --产成品月签(元)
                a.产年签金 产年签金                                             --产成品年签(元)
         --hegj
         FROM #t a
              LEFT JOIN #t1 b ON b.ProjGUID = a.ProjGUID
              LEFT JOIN #ts t ON t.ProjGUID = a.ProjGUID
     ) t ON c.BUGUID = t.BUGUID
            AND t.ProjGUID = c.ProjGUID
WHERE 1 = 1
GROUP BY c.BUGUID,
         c.ProjGUID,
         p.SpreadName;



SELECT DENSE_RANK() OVER (PARTITION BY a.BUGUID
                          ORDER BY CASE WHEN 月签约任务 <> 0 THEN 月签约完成率 ELSE 0 END DESC,
                                   月度签约 DESC,
                                   年度签约 DESC,
                                   月度认购 DESC,
                                   产月签金 DESC,
                                   产年签金 DESC
                         ) num,
       a.*
FROM #hz a
     LEFT JOIN dbo.mdm_Project mp ON a.ProjGUID = mp.ProjGUID
WHERE 1 = 1
      AND mp.ManageModeName NOT IN ( '一级整理', '代建' )
    --  AND mp.SaleStatus NOT IN ( '计划今年后首开', '未售', '售罄', '本年首开（预计）' )
      AND mp.SpreadName NOT IN ( '佛山万科金域滨江', '佛山万科金域缇香', '佛山金茂绿岛湖', '佛山美的明湖北湾二期' )
      AND ProjStatus NOT IN ( '跟进待落实', '清算退出' )
      AND mp.ProjGUID NOT IN ( 'D8FBB537-8934-E711-80BA-E61F13C57837' )
UNION
SELECT 0 num,
       BUGUID BUGUID,
       BUGUID ProjGUID,
       '合计' 推广名,
       SUM(本日认购),
       SUM(认购未签约),
       SUM(本日签约),
       SUM(月度认购),
       SUM(月签约任务),
       SUM(月度签约),
       CASE WHEN SUM(月签约任务) <> 0 THEN SUM(月度签约) / SUM(月签约任务) ELSE 0 END 月签约完成率,
       SUM(年签约任务),
       SUM(年度签约),
       CASE WHEN SUM(年签约任务) <> 0 THEN SUM(年度签约) / SUM(年签约任务) ELSE 0 END 年签约完成率,
       SUM(月度非车位签约金额元),
       SUM(月度非车位签约面积),
       CASE
           WHEN SUM(月度非车位签约面积) <> 0 THEN SUM(月度非车位签约金额元) / SUM(月度非车位签约面积) ELSE 0 END 月度非车位签约均价,
       SUM(年度非车位签约金额元),
       SUM(年度非车位签约面积),
       CASE
           WHEN SUM(年度非车位签约面积) <> 0 THEN SUM(年度非车位签约金额元) / SUM(年度非车位签约面积) ELSE 0 END 年度非车位签约均价,
       SUM(累计非车位签约金额元),
       SUM(累计非车位签约面积),
       CASE
           WHEN SUM(累计非车位签约面积) <> 0 THEN SUM(累计非车位签约金额元) / SUM(累计非车位签约面积) ELSE 0 END 累计非车位签约均价,
       SUM(年度认购),
       SUM(产日签金),
       SUM(产月签金),
       SUM(产年签金)
FROM #hz
GROUP BY BUGUID;

DROP TABLE #p;
DROP TABLE #t;
DROP TABLE #ccp;
DROP TABLE #t1;
DROP TABLE #ts;
DROP TABLE #room;
DROP TABLE #nd;
DROP TABLE #yd;
DROP TABLE #con;
DROP TABLE #order;
DROP TABLE #hz;



        SELECT *
                FROM [dss].[dbo].[nmap_s_M002项目业态级毛利净利表] 
                WHERE VersionGUID IN (
                    SELECT VersionGUID FROM (select VersionGUID,ROW_NUMBER() OVER(PARTITION BY RptID ORDER BY StartTime desc) AS RN 
                    from  nmap_RptVersion 
                    where RptID='00FEFB24_26B7_4727_A3C1_328A73CDC360') t WHERE RN=1
                )
                                and 明源匹配主键 ='0023006_架空层_架空层__毛坯'