-- 2025-08-13 增加本日成交房间明细数据，列表字段包括 项目、房间、认购金额、签约金额、成交面积
-- 2025-08-20 增加认购和签约单价，同时项目按照认购金额进行排序

SELECT ImportSaleProjGUID,
       ProjGUID,
       ProjName,
       projcode,
       SpreadName,
       OrgCompanyGUID as  BUGUID
INTO #p
FROM mdm_Project p
WHERE Level = 2
      AND DevelopmentCompanyGUID = 'AADC0FA7-9546-49C9-B64B-825056C828ED';


--获取房间没有关联到特殊业绩的房间明细,以便操盘项目跟特殊业绩不会重复计算该房间业绩
SELECT p.parentprojguid as  projguid,
       a.RoomGUID,
       a.BldGUID,
       a.BldArea,
       a.ProductType,
       a.Productname,
       a.RoomName,
       a.roominfo -- 房间信息
INTO #room
FROM ep_room a
inner join mdm_Project p on a.projguid = p.projguid
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
SELECT ISNULL(p1.ProjGUID, p.ProjGUID) projguid,roominfo,a.roomguid,                                                                                                                     
       SUM(   CASE
                  WHEN DATEDIFF(dd, o.QSDate, GETDATE()) = 0
                       AND YEAR(o.QSDate) = YEAR(GETDATE())
                       AND o.Status = '激活' THEN o.JyTotal
                  WHEN DATEDIFF(dd, o.QSDate, GETDATE()) = 0
                       AND YEAR(o.QSDate) = YEAR(GETDATE())
                       AND sc.Status = '激活' THEN sc.JyTotal ELSE 0 END
          ) /10000.0  brrgAmount, -- 本日认购金额
       SUM(   CASE
                  WHEN DATEDIFF(dd, o.QSDate, GETDATE()) = 0
                       AND YEAR(o.QSDate) = YEAR(GETDATE())
                       AND o.Status = '激活' THEN a.BldArea
                  WHEN DATEDIFF(dd, o.QSDate, GETDATE()) = 0
                       AND YEAR(o.QSDate) = YEAR(GETDATE())
                       AND sc.Status = '激活' THEN a.bldArea ELSE 0 END
          )  brrgArea -- 本日认购面积
INTO #order
FROM s_Order o
     INNER JOIN #room a ON a.RoomGUID = o.RoomGUID
     LEFT JOIN dbo.p_Project p ON p.ProjGUID = o.ProjGUID
     LEFT JOIN dbo.p_Project p1 ON p.ParentCode = p1.ProjCode
     LEFT JOIN dbo.s_Contract sc ON sc.Status = '激活'
                                    AND sc.TradeGUID = o.TradeGUID
WHERE 1 = 1 and datediff(day,o.QSDate,GETDATE()) = 0  
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
GROUP BY ISNULL(p1.ProjGUID, p.ProjGUID),roominfo,a.RoomGUID;

--缓存签约
SELECT ISNULL(p1.ProjGUID, p.ProjGUID) projguid,a.roominfo,a.roomguid,
       SUM(   CASE
                  WHEN DATEDIFF(DAY, c.QSDate, GETDATE()) = 0 THEN c.JyTotal ELSE 0 END
          ) /10000.0 brqyAmount,
       SUM(   CASE
                  WHEN DATEDIFF(DAY, c.QSDate, GETDATE()) = 0 THEN a.BldArea ELSE 0 END
          )  brqyArea,

       SUM(   CASE
                  WHEN DATEDIFF(DAY, c.QSDate, GETDATE()) = 0
                       AND so.OrderGUID IS NULL THEN c.JyTotal ELSE 0 END
          ) /10000.0  brrgAmount, -- 本日直接签约金额
       SUM(   CASE
                  WHEN DATEDIFF(DAY, c.QSDate, GETDATE()) = 0
                       AND so.OrderGUID IS NULL THEN a.BldArea ELSE 0 END
          )  brrgArea -- 本月直接签约面积
INTO #con
FROM s_Contract c
     LEFT JOIN dbo.p_Project p ON p.ProjGUID = c.ProjGUID
     LEFT JOIN dbo.p_Project p1 ON p.ParentCode = p1.ProjCode
     INNER JOIN #room a ON a.RoomGUID = c.RoomGUID
     LEFT JOIN dbo.s_Order so ON ISNULL(so.TradeGUID, '') = ISNULL(c.TradeGUID, '')
     INNER JOIN dbo.p_Building bd ON a.BldGUID = bd.BldGUID
     LEFT JOIN mdm_SaleBuild sb ON bd.BldGUID = sb.ImportSaleBldGUID
WHERE 1 = 1
      AND c.Status = '激活'
      and  DATEDIFF(DAY, c.QSDate, GETDATE()) = 0
      AND
      (
          (
              so.Status = '关闭'
              AND so.CloseReason = '转签约'
          )
          OR so.TradeGUID IS NULL
      )
GROUP BY ISNULL(p1.ProjGUID, p.ProjGUID),a.roominfo,a.roomguid;


--获取操盘项目完成情况
SELECT 
       -- '03.'+ convert(varchar(10), row_number() over ( partition by mp.ProjGUID order by sum(ISNULL(rg.brrgAmount, 0) + ISNULL(qy.brrgAmount, 0)) desc ) ) +'.' + mp.projcode  as  rownum, 
       sum(ISNULL(rg.brrgAmount, 0) + ISNULL(qy.brrgAmount, 0)) over( partition by mp.ProjGUID ) as  '项目本日认购金额', -- 按照金额汇总排序
       mp.BUGUID BUGUID,
       mp.SpreadName,
       mp.projname,
       mp.projcode,
       mp.ProjGUID,
        a.RoomGUID,
	   a.RoomInfo,
        a.RoomName,
       ISNULL(rg.brrgAmount, 0) + ISNULL(qy.brrgAmount, 0) AS '本日认购',
       ISNULL(rg.brrgArea, 0) + ISNULL(qy.brrgArea, 0) AS '本日认购面积',
       case when  rg.brrgAmount > 0 then  1 else  0 end '本日认购套数',   
       case when  (ISNULL(rg.brrgArea, 0) + ISNULL(qy.brrgArea, 0 ) ) =0 then 0 
             else  (ISNULL(rg.brrgAmount, 0) + ISNULL(qy.brrgAmount, 0) ) * 10000.0 / (ISNULL(rg.brrgArea, 0) + ISNULL(qy.brrgArea, 0) ) end '本日认购单价',   
       ISNULL(qy.brqyAmount, 0) AS '本日签约',
       ISNULL(qy.brqyArea, 0) AS '本日签约面积',
       case when  qy.brqyAmount > 0 then 1 else 0  end  '本日签约套数',
       case when  ISNULL(qy.brqyArea, 0) =0 then 0 
             else  ISNULL(qy.brqyAmount, 0) *10000.0 / ISNULL(qy.brqyArea, 0)  end  '本日签约单价'
INTO #t
FROM #p mp 
     inner join #room a on mp.ProjGUID = a.ProjGUID
     LEFT JOIN #order rg ON rg.roomguid = a.RoomGUID
     LEFT JOIN #con qy ON qy.roomguid = a.roomguid
     -- LEFT JOIN
     -- (
     --     SELECT mp.ProjGUID,
     --            SUM(s.AreaTotal) AS AreaTotal,
     --            SUM(s.TotalAmount) AS TotalAmount
     --     FROM S_PerformanceAppraisal AS s
     --          INNER JOIN #p mp ON mp.ProjGUID = s.ManagementProjectGUID
     --     WHERE s.Year = YEAR(GETDATE())
     --     GROUP BY mp.ProjGUID
     -- ) ts ON ts.ProjGUID = mp.ProjGUID
where (ISNULL(rg.brrgAmount, 0) + ISNULL(qy.brrgAmount, 0) ) <> 0  or ISNULL(qy.brqyAmount, 0) <> 0


-- 按照认购金额金额排序
select 
     convert(varchar(10), DENSE_RANK() over (order by 项目本日认购金额 desc ) ) + projcode as rowcode,*
     into #t2
from #t

-- 汇总
-- 房间明细
SELECT 
     rowcode + '.03' AS rownum,
     BUGUID,
     SpreadName,
     projname,
     ProjGUID,
     RoomGUID,
     RoomInfo,
     RoomName,
     本日认购,
     本日认购面积,
     本日认购套数,
     本日认购单价,
     本日签约,
     本日签约面积,
     本日签约套数,
     本日签约单价
FROM #t2
UNION ALL
-- 项目小计
SELECT 
     rowcode + '.02' AS rownum,
     BUGUID,
     SpreadName,
     projname,
     ProjGUID,
       NULL AS RoomGUID,
       NULL AS RoomInfo,
       '小计' AS RoomName,
       SUM(本日认购) AS 本日认购,
       SUM(本日认购面积) AS 本日认购面积,
       SUM(本日认购套数) AS 本日认购套数,
       CASE
           WHEN SUM(本日认购面积) = 0 THEN 0
           ELSE SUM(本日认购) * 10000.0 / SUM(本日认购面积)
       END AS 本日认购单价,
       SUM(本日签约) AS 本日签约,
       SUM(本日签约面积) AS 本日签约面积,
       SUM(本日签约套数) AS 本日签约套数,
       CASE
           WHEN SUM(本日签约面积) = 0 THEN 0
           ELSE SUM(本日签约) * 10000.0 / SUM(本日签约面积)
       END AS 本日签约单价
FROM #t2
GROUP BY BUGUID,
         projcode,
         SpreadName,
         projname,
         ProjGUID,
         rowcode
UNION ALL
-- 公司合计
SELECT '00.0000' AS rownum,
       BUGUID,
       '合计' AS SpreadName,
       NULL AS projname,
       NULL AS ProjGUID,
       NULL AS RoomGUID,
       NULL AS RoomInfo,
       NULL AS RoomName,
       SUM(本日认购) AS 本日认购,
       SUM(本日认购面积) AS 本日认购面积,
       SUM(本日认购套数) AS 本日认购套数,
       CASE
           WHEN SUM(本日认购面积) = 0 THEN 0
           ELSE SUM(本日认购) * 10000.0 / SUM(本日认购面积)
       END AS 本日认购单价,
       SUM(本日签约) AS 本日签约,
       SUM(本日签约面积) AS 本日签约面积,
       SUM(本日签约套数) AS 本日签约套数,
       CASE
           WHEN SUM(本日签约面积) = 0 THEN 0
           ELSE SUM(本日签约) * 10000.0 / SUM(本日签约面积)
       END AS 本日签约单价
FROM #t2
GROUP BY BUGUID

-- -- 项目小计
-- union all 
-- select 
--     '02.' + convert(varchar(10), row_number() over (order by 本日认购 desc ) ) + '.' + projcode as rownum,
--     BUGUID,
--     SpreadName,
--     projname,
--     ProjGUID,
--     RoomGUID,
--     RoomInfo,
--     RoomName,
--     本日认购,
--     本日认购面积,
--     本日认购套数,
--     本日认购单价,
--     本日签约,
--     本日签约面积,
--     本日签约套数,
--     本日签约单价
-- from  (
--      SELECT 
--           -- mp.projcode +'.02'  as  rownum, 
--           mp.projcode,
--           mp.BUGUID BUGUID,
--           mp.SpreadName,
--           mp.projname,
--           mp.ProjGUID,
--           null as RoomGUID,   --    a.RoomGUID,
--           null as RoomInfo, --    a.RoomInfo,
--           '小计' as RoomName , --    a.RoomName,
--           sum( ISNULL(rg.brrgAmount, 0) + ISNULL(qy.brrgAmount, 0) ) AS '本日认购',
--           sum(ISNULL(rg.brrgArea, 0) + ISNULL(qy.brrgArea, 0)) AS '本日认购面积',
--           sum(case when  rg.brrgAmount > 0 then  1 else  0 end ) as '本日认购套数',  
--           case when  sum(ISNULL(rg.brrgArea, 0) + ISNULL(qy.brrgArea, 0 ) ) =0 then 0 
--                else  sum(ISNULL(rg.brrgAmount, 0) + ISNULL(qy.brrgAmount, 0) ) / sum(ISNULL(rg.brrgArea, 0) + ISNULL(qy.brrgArea, 0) ) end  '本日认购单价',    
--           sum(ISNULL(qy.brqyAmount, 0) ) AS '本日签约',
--           sum(ISNULL(qy.brqyArea, 0) ) AS '本日签约面积',
--           sum(case when  qy.brqyAmount > 0 then 1 else 0  end ) as '本日签约套数',
--           case when  sum(ISNULL(qy.brqyArea, 0)) =0 then 0 
--                else  sum(ISNULL(qy.brqyAmount, 0)) / sum(ISNULL(qy.brqyArea, 0))  end  '本日签约单价'
--      -- INTO #t
--      FROM #p mp 
--           inner join #room a on mp.ProjGUID = a.ProjGUID
--           LEFT JOIN #order rg ON rg.roomguid = a.RoomGUID
--           LEFT JOIN #con qy ON qy.roomguid = a.roomguid
--      where (ISNULL(rg.brrgAmount, 0) + ISNULL(qy.brrgAmount, 0) ) <> 0  or ISNULL(qy.brqyAmount, 0) <> 0
--      group by  mp.BUGUID,mp.projcode, mp.SpreadName, mp.projname, mp.ProjGUID
-- ) proj
-- -- 合计
-- union all 
-- SELECT 
--        '000000'  as  rownum,
--        mp.BUGUID BUGUID,
--        '合计' as SpreadName,
--        null ,
--        NULL,
--        null,   --    a.RoomGUID,
-- 	  null, --    a.RoomInfo,
--        '--', --    a.RoomName,
--        sum( ISNULL(rg.brrgAmount, 0) + ISNULL(qy.brrgAmount, 0) ) AS '本日认购',
--        sum(ISNULL(rg.brrgArea, 0) + ISNULL(qy.brrgArea, 0)) AS '本日认购面积',
--        sum(case when  rg.brrgAmount > 0 then  1 else  0 end ) as '本日认购套数',   
--        case when  sum(ISNULL(rg.brrgArea, 0) + ISNULL(qy.brrgArea, 0 ) ) =0 then 0 
--              else  sum(ISNULL(rg.brrgAmount, 0) + ISNULL(qy.brrgAmount, 0) ) / sum(ISNULL(rg.brrgArea, 0) + ISNULL(qy.brrgArea, 0) ) end  '本日认购单价',  
--        sum(ISNULL(qy.brqyAmount, 0) ) AS '本日签约',
--        sum(ISNULL(qy.brqyArea, 0) ) AS '本日签约面积',
--        sum(case when  qy.brqyAmount > 0 then 1 else 0  end ) as '本日签约套数',
--        case when  sum(ISNULL(qy.brqyArea, 0)) =0 then 0 
--              else  sum(ISNULL(qy.brqyAmount, 0)) / sum(ISNULL(qy.brqyArea, 0))  end  '本日签约单价'
-- -- INTO #t
-- FROM #p mp 
--      inner join #room a on mp.ProjGUID = a.ProjGUID
--      LEFT JOIN #order rg ON rg.roomguid = a.RoomGUID
--      LEFT JOIN #con qy ON qy.roomguid = a.roomguid
--      -- LEFT JOIN
--      -- (
--      --     SELECT mp.ProjGUID,
--      --            SUM(s.AreaTotal) AS AreaTotal,
--      --            SUM(s.TotalAmount) AS TotalAmount
--      --     FROM S_PerformanceAppraisal AS s
--      --          INNER JOIN #p mp ON mp.ProjGUID = s.ManagementProjectGUID
--      --     WHERE s.Year = YEAR(GETDATE())
--      --     GROUP BY mp.ProjGUID
--      -- ) ts ON ts.ProjGUID = mp.ProjGUID
-- where (ISNULL(rg.brrgAmount, 0) + ISNULL(qy.brrgAmount, 0) ) <> 0  or ISNULL(qy.brqyAmount, 0) <> 0
-- group by  mp.BUGUID

-- --获取非操盘项目完成情况
-- SELECT c.BUGuid,
--        c.ProjGUID,
--        SUM(   CASE
--                   WHEN b.DateYear = YEAR(GETDATE())
--                        AND b.datemonth = MONTH(GETDATE()) THEN a.Amount ELSE 0 END
--           ) AS '月度认购',
--        SUM(CASE WHEN b.DateYear = YEAR(GETDATE()) THEN a.Amount ELSE 0 END) AS '年度认购', --hegj
--        SUM(   CASE
--                   WHEN b.DateYear = YEAR(GETDATE())
--                        AND b.datemonth = MONTH(GETDATE()) THEN a.Amount ELSE 0 END
--           ) AS '月度签约',
--        SUM(CASE WHEN b.DateYear = YEAR(GETDATE()) THEN a.Amount ELSE 0 END) AS '年度签约',
--        SUM(   CASE
--                   WHEN b.DateYear = YEAR(GETDATE())
--                        AND b.datemonth = MONTH(GETDATE()) THEN a.huilongjiner ELSE 0 END
--           ) AS '月度回款',
--        SUM(CASE WHEN b.DateYear = YEAR(GETDATE()) THEN a.huilongjiner ELSE 0 END) AS '年度回款'
-- INTO #t1
-- FROM dbo.s_YJRLProducteDescript a
--      LEFT JOIN
--      (
--          SELECT *,
--                 CONVERT(DATETIME, b.DateYear + '-' + b.DateMonth + '-01') AS [BizDate]
--          FROM dbo.s_YJRLProducteDetail b
--      ) b ON b.ProducteDetailGUID = a.ProducteDetailGUID
--      LEFT JOIN dbo.s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
--      INNER JOIN #p p ON p.ProjGUID = c.ProjGUID
-- WHERE 1 = 1
--       AND b.Shenhe = '审核'
--       AND b.DateYear = YEAR(GETDATE())
-- GROUP BY c.BUGuid,
--          c.ProjGUID;


-- ----加上特殊业绩
-- SELECT t.BUGUID,
--        t.ProjGUID,
--        SUM(t.BNJE) BNJE,
--        SUM(t.BYJE) ByJE
-- INTO #ts
-- FROM
-- (
--     SELECT p.BUGUID,
--            p.ProjGUID,
--            SUM(   CASE
--                       WHEN YEAR(a.RdDate) = YEAR(GETDATE()) THEN a.TotalAmount ELSE 0 END
--               ) BNJE,
--            SUM(   CASE
--                       WHEN DATEDIFF(m, ISNULL(RdDate, a.CreationTime), GETDATE()) = 0 THEN a.TotalAmount ELSE 0 END
--               ) BYJE
--     FROM dbo.S_PerformanceAppraisal a
--          LEFT JOIN #p p ON p.ProjGUID = a.ManagementProjectGUID
--     WHERE 1 = 1
--           AND a.AuditStatus = '已审核'
--           AND a.YjType IN (
--                               SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom = 0
--                           )
--     GROUP BY p.BUGUID,
--              p.ProjGUID
--     UNION ALL
--     SELECT p.BUGUID,
--            p.ProjGUID,
--            SUM(   CASE
--                       WHEN YEAR(a.rddate) = YEAR(GETDATE()) THEN b.totalamount ELSE 0 END
--               ) BNJE,
--            SUM(   CASE
--                       WHEN DATEDIFF(m, ISNULL(rddate, a.CreationTime), GETDATE()) = 0 THEN b.totalamount ELSE 0 END
--               ) BYJE
--     FROM S_PerformanceAppraisal a
--          LEFT JOIN
--          (
--              SELECT PerformanceAppraisalGUID,
--                     BldGUID,
--                     IdentifiedArea areatotal,
--                     AffirmationNumber AggregateNumber,
--                     AmountDetermined totalamount
--              FROM dbo.S_PerformanceAppraisalBuildings
--              UNION ALL
--              SELECT PerformanceAppraisalGUID,
--                     r.ProductBldGUID BldGUID,
--                     SUM(a.IdentifiedArea),
--                     SUM(a.AffirmationNumber),
--                     SUM(a.AmountDetermined)
--              FROM dbo.S_PerformanceAppraisalRoom a
--                   LEFT JOIN MyCost_Erp352.dbo.md_Room r ON a.RoomGUID = r.RoomGUID
--              GROUP BY PerformanceAppraisalGUID,
--                       r.ProductBldGUID
--          ) b ON a.PerformanceAppraisalGUID = b.PerformanceAppraisalGUID
--          INNER JOIN #p p ON p.ProjGUID = a.ManagementProjectGUID
--     WHERE 1 = 1
--           AND a.AuditStatus = '已审核'
--           AND a.YjType IN (
--                               SELECT TsyjTypeName FROM s_TsyjType WHERE IsRelatedBuildingsRoom = 1
--                           )
--     GROUP BY p.BUGUID,
--              p.ProjGUID
-- ) t
-- GROUP BY t.BUGUID,
--          t.ProjGUID;

-- --获取汇总数据
-- SELECT
--     --ROW_NUMBER() OVER ( PARTITION BY c.BUGUID
--     --                            ORDER BY CASE WHEN SUM(y.月度签约任务) <> 0 THEN SUM(t.月度签约) / SUM(y.月度签约任务)
--     --                                          ELSE 0
--     --                                     END DESC ,
--     --                                     SUM(t.月度签约) DESC ,
--     --                                     SUM(t.年度签约) DESC ,
--     --                                     SUM(t.月度认购) DESC ,
--     --                                     SUM(t.产月签金) DESC ,
--     --                                     SUM(t.产年签金) DESC ,
--     --                                     p.SpreadName ) num ,
--     c.BUGUID,
--     c.ProjGUID,
--     p.SpreadName 推广名,
--     SUM(isnull(t.本日认购,0)) / 10000.0 AS '本日认购',
--     SUM(isnull(t.认购未签约,0)) / 10000.0 AS '认购未签约',
--     SUM(isnull(t.本日签约,0)) / 10000.0 AS '本日签约',
--     SUM(isnull(t.月度认购,0)) / 10000.0 AS '月度认购',
--     SUM(isnull(y.月度签约任务,0)) / 10000.0 AS '月签约任务',
--     SUM(isnull(t.月度签约,0)) / 10000.0 AS '月度签约',
--     CASE
--         WHEN SUM(isnull(y.月度签约任务,0)) = 0 THEN 0 ELSE CONVERT(DECIMAL(18, 4), SUM(isnull(t.月度签约,0)) / SUM(isnull(y.月度签约任务,0))) END AS '月签约完成率',
--     SUM(isnull(n.年度签约任务,0)) / 10000.0 AS '年签约任务',
--     SUM(isnull(t.年度签约,0)) / 10000.0 AS '年度签约',
--     CASE WHEN SUM(isnull(n.年度签约任务,0)) = 0 THEN 0 ELSE SUM(isnull(t.年度签约,0)) / SUM(isnull(n.年度签约任务,0)) END AS '年签约完成率',
--                                    --hegj
--     SUM(isnull(t.月度非车位签约金额元,0)) AS '月度非车位签约金额元',
--     SUM(isnull(t.月度非车位签约面积,0)) AS '月度非车位签约面积',
--     CASE
--         WHEN SUM(t.月度非车位签约金额元) = 0 THEN 0 ELSE SUM(t.月度非车位签约金额元) / SUM(t.月度非车位签约面积) END AS '月度非车位签约均价',
--     SUM(t.年度非车位签约金额元) AS '年度非车位签约金额元',
--     SUM(t.年度非车位签约面积) AS '年度非车位签约面积',
--     CASE
--         WHEN SUM(t.年度非车位签约金额元) = 0 THEN 0 ELSE SUM(t.年度非车位签约金额元) / SUM(t.年度非车位签约面积) END AS '年度非车位签约均价',
--     SUM(t.累计非车位签约金额元) AS '累计非车位签约金额元',
--     SUM(t.累计非车位签约面积) AS '累计非车位签约面积',
--     CASE
--         WHEN SUM(t.累计非车位签约面积) = 0 THEN 0 ELSE SUM(t.累计非车位签约金额元) / SUM(t.累计非车位签约面积) END AS '累计非车位签约均价',
--     SUM(isnull(t.年度认购,0)) / 10000.0 AS '年度认购', --hegj
--     SUM(isnull(t.产日签金,0)) / 10000.0 产日签金,      --产成品日签(元) 
--     SUM(isnull(t.产月签金,0)) / 10000.0 产月签金,      --产成品月签(元) 
--     SUM(isnull(t.产年签金,0)) / 100000000.0 产年签金   --产成品年签(元) 
-- INTO #hz
-- FROM #p c
--      LEFT JOIN mdm_Project p ON c.ProjGUID = p.ProjGUID
--      LEFT JOIN #nd n ON c.BUGUID = n.BUGUID
--                         AND n.ProjGUID = c.ProjGUID
--      LEFT JOIN #yd y ON y.BUGUID = c.BUGUID
--                         AND y.ProjGUID = c.ProjGUID
--      LEFT JOIN
--      (
--          SELECT a.BUGUID,
--                 a.ProjGUID,
--                 a.本日认购 AS 本日认购,
--                 a.认购未签约 AS 认购未签约,
--                 a.本日签约 AS 本日签约,
--                 a.月度认购 + ISNULL(b.月度认购, 0) + ISNULL(t.ByJE, 0) AS 月度认购,
--                 a.月度签约 + ISNULL(b.月度签约, 0) + ISNULL(t.ByJE, 0) AS 月度签约,
--                 a.年度签约 + ISNULL(b.年度签约, 0) + ISNULL(t.BNJE, 0) AS 年度签约,
--                 a.月度回款 AS 月度回款,
--                 a.年度回款 AS 年度回款,
--                                                                         --hegj
--                 a.月度非车位签约金额元 AS 月度非车位签约金额元,
--                 a.月度非车位签约面积 AS 月度非车位签约面积,
--                 a.年度非车位签约金额元 AS 年度非车位签约金额元,
--                 a.年度非车位签约面积 AS 年度非车位签约面积,
--                 a.累计非车位签约金额元,
--                 a.累计非车位签约面积,
--                 a.年度认购 + ISNULL(b.年度认购, 0) + ISNULL(t.BNJE, 0) AS 年度认购, --hegj
--                 a.产日签金 产日签金,                                            --产成品日签(元)
--                 a.产月签金 产月签金,                                            --产成品月签(元)
--                 a.产年签金 产年签金                                             --产成品年签(元)
--          --hegj
--          FROM #t a
--               LEFT JOIN #t1 b ON b.ProjGUID = a.ProjGUID
--               LEFT JOIN #ts t ON t.ProjGUID = a.ProjGUID
--      ) t ON c.BUGUID = t.BUGUID
--             AND t.ProjGUID = c.ProjGUID
-- WHERE 1 = 1
-- GROUP BY c.BUGUID,
--          c.ProjGUID,
--          p.SpreadName;



-- SELECT DENSE_RANK() OVER (PARTITION BY a.BUGUID
--                           ORDER BY CASE WHEN 月签约任务 <> 0 THEN 月签约完成率 ELSE 0 END DESC,
--                                    月度签约 DESC,
--                                    年度签约 DESC,
--                                    月度认购 DESC,
--                                    产月签金 DESC,
--                                    产年签金 DESC
--                          ) num,
--        a.*
-- FROM #hz a
--      LEFT JOIN dbo.mdm_Project mp ON a.ProjGUID = mp.ProjGUID
-- WHERE 1 = 1
--       AND mp.ManageModeName NOT IN ( '一级整理', '代建' )
--     --  AND mp.SaleStatus NOT IN ( '计划今年后首开', '未售', '售罄', '本年首开（预计）' )
--       AND mp.SpreadName NOT IN ( '佛山万科金域滨江', '佛山万科金域缇香', '佛山金茂绿岛湖', '佛山美的明湖北湾二期' )
--       AND ProjStatus NOT IN ( '跟进待落实', '清算退出' )
--       AND mp.ProjGUID NOT IN ( 'D8FBB537-8934-E711-80BA-E61F13C57837' )


-- DROP TABLE #p;
-- DROP TABLE #t;
-- DROP TABLE #ccp;
-- DROP TABLE #t1;
-- DROP TABLE #ts;
-- DROP TABLE #room;
-- DROP TABLE #nd;
-- DROP TABLE #yd;
-- DROP TABLE #con;
-- DROP TABLE #order;
-- DROP TABLE #hz;