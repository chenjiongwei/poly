--户型匹配
SELECT p.房间guid ,
       p.对应技术户型 ,
       p.房间建面 ,
       hx.AreaSection
INTO   #hx
FROM   ( SELECT * FROM data_tb_hnUnitType 
       UNION SELECT * FROM data_tb_yzUnitType 
       --UNION SELECT * FROM data_tb_zjUnitType
       --UNION SELECT * FROM data_tb_znUnitType 
       ) p --粤中公司/华南公司/浙江/浙南
       INNER JOIN dbo.data_wide_s_RoomoVerride r ON r.RoomGUID = p.房间guid
       INNER JOIN data_wide_mdm_ProductBuildUnitAreaSetting hx ON p.房间建面 BETWEEN hx.BgnArea AND hx.EndArea
                                                                  AND p.对应技术户型 = hx.UnitType
                                                                  AND hx.bldGUID = r.BldGUID
WHERE  p.对应技术户型 IS NOT NULL

--记录新增规则(必须配置) 
/*销售交易汇总*/
SELECT p.ParentGUID AS ParentProjGUID ,                                            --项目GUID
       p.ParentName AS ParentProjName ,                                            --项目名称
       p.ParentCode AS ParentProjCode ,                                            --项目编码
       p.ProjGUID ,                                                                --分期GUID
       p.ProjName ,                                                                --分期名称
       p.ProjCode ,                                                                --分期编码
       sb.GCBldGUID ,                                                              --工程楼栋GUID
       sb.GCBldname ,                                                              --工程楼栋名称
       sb.GCBldCode ,                                                              --工程楼栋编码
       sb.BuildingGUID AS BldGUID ,                                                --产品楼栋GUID
       sb.BuildingName AS BldName ,                                                --产品楼栋名称
       sb.Code AS BldCode ,                                                        --产品楼栋编码
       sb.TopProductTypeGuid AS TopProductTypeGUID ,                               --一级产品类型GUID
       sb.TopProductTypeName AS TopProductTypeName ,                               --一级产品类型名称
       sb.TopProductTypeCode AS TopProductTypeCode ,                               --一级产品类型Code
       sb.ProductTypeGuid AS ProductTypeGUID ,                                     --末级产品类型GUID
       sb.ProductTypeName AS ProductTypeName ,                                     --末级类型名称
       sb.ProductTypeCode AS ProductTypeCode ,                                     --末级产品类型编码
       tempSum.StatisticalDate AS StatisticalDate ,                                --统计日期
       p.RightsRate ,                                                              --权益比例
       p.GenreTableType ,                                                          --并表类型
       p.DiskType ,                                                                --操盘类型
       p.DiskFlag ,                                                                --是否操盘
       p.HistoryType ,                                                             --是否历史
       sb.FactNotOpen AS YszGetDate ,                                              --取证日期
       sb.IsLock AS IsLock ,                                                       --是否锁定
       tempSum.ONetArea ,                                                          --认购面积
       tempSum.ONetAmount ,                                                        --认购金额
       tempSum.ONetCount ,                                                         --认购套数
       ISNULL(tempSum.ONetAmount, 0) * p.RightsRate / 100.00 AS RightsONetAmount , --认购金额_权益口径（【认购金额】+【认购金额_特殊业绩】）
       tempSum.CNetArea ,                                                          --签约面积
       tempSum.CNetAmount ,                                                        --签约金额
       tempSum.CNetAmountNotTax ,                                                  --签约金额(不含税)
       tempSum.CNetCount ,                                                         --签约套数
       ISNULL(tempSum.CNetAmount, 0) * p.RightsRate / 100.00 AS RightsCNetAmount , --签约金额_权益口径（【签约金额】+【签约金额_特殊业绩】）
       tempSum.SpecialCNetArea ,                                                   --签约面积_特殊业绩
       tempSum.SpecialCNetAmount ,                                                 --签约金额_特殊业绩
       CASE WHEN tempSum.StatisticalDate < '2016-04-01' THEN ISNULL(tempSum.SpecialCNetAmount, 0)
            WHEN tempSum.StatisticalDate >= '2016-04-01'
                 AND tempSum.StatisticalDate < '2018-05-01' THEN ISNULL(tempSum.SpecialCNetAmount, 0) / ( 1 + 0.11 )
            WHEN tempSum.StatisticalDate >= '2018-05-01'
                 AND tempSum.StatisticalDate < '2019-04-01' THEN ISNULL(tempSum.SpecialCNetAmount, 0) / ( 1 + 0.10 )
            WHEN tempSum.StatisticalDate >= '2019-04-01' THEN ISNULL(tempSum.SpecialCNetAmount, 0) / ( 1 + 0.09 )
            ELSE 0
       END AS SpecialCNetAmountNotTax ,                                            --签约金额不含税_特殊业绩
       tempSum.SpecialCNetCount ,                                                  --签约套数_特殊业绩
       tempSum.NCCumArea ,                                                         --累计草签面积
       tempSum.NCCumAmount ,                                                       --累计草签金额
       tempSum.NCCumCount ,                                                        --累计草签套数
       tempSum.ICCumArea ,                                                         --累计网签面积
       tempSum.ICCumAmount ,                                                       --累计网签金额
       tempSum.ICCumCount ,                                                        --累计网签套数
       tempr.FangPanArea ,                                                         --推盘面积
       tempr.FangPanAmount ,                                                       --推盘金额
       tempr.FangPanCount ,                                                        --推盘套数	
       tempSum.UnitType ,
       AreaSection
FROM
       (   SELECT    tempDisk.BldGUID ,                                     --产品楼栋GUID
                     tempDisk.StatisticalDate ,
                     tempDisk.UnitType ,
                     tempDisk.AreaSection ,                                 --统计日期
                     SUM(tempDisk.ONetArea) AS ONetArea ,                   --认购面积
                     SUM(tempDisk.ONetAmount) AS ONetAmount ,               --认购金额
                     SUM(tempDisk.ONetCount) AS ONetCount ,                 --认购套数
                     SUM(tempDisk.CNetArea) AS CNetArea ,                   --签约面积
                     SUM(tempDisk.CNetAmount) AS CNetAmount ,               --签约金额
                     SUM(tempDisk.CNetAmountNotTax) AS CNetAmountNotTax ,   --签约金额(不含税)
                     SUM(tempDisk.CNetCount) AS CNetCount ,                 --签约套数
                     SUM(tempDisk.SpecialONetAmount) AS SpecialONetAmount , --认购金额_特殊业绩
                     SUM(tempDisk.SpecialCNetArea) AS SpecialCNetArea ,     --签约面积_特殊业绩
                     SUM(tempDisk.SpecialCNetAmount) AS SpecialCNetAmount , --签约金额_特殊业绩
                     SUM(tempDisk.SpecialCNetCount) AS SpecialCNetCount ,   --签约套数_特殊业绩
                     SUM(tempDisk.NCCumArea) AS NCCumArea ,                 --累计草签面积
                     SUM(tempDisk.NCCumAmount) AS NCCumAmount ,             --累计草签金额
                     SUM(tempDisk.NCCumCount) AS NCCumCount ,               --累计草签套数
                     SUM(tempDisk.ICCumArea) AS ICCumArea ,                 --累计网签面积
                     SUM(tempDisk.ICCumAmount) AS ICCumAmount ,             --累计网签金额
                     SUM(tempDisk.ICCumCount) AS ICCumCount                 --累计网签套数
           FROM
                     (   SELECT       sb.BuildingGUID AS BldGUID ,
                                      tempYesDisk.UnitType ,
                                      tempYesDisk.AreaSection ,                                          --产品楼栋GUID
                                      tempYesDisk.StatisticalDate ,                                      --统计日期
                                      SUM(ISNULL(tempYesDisk.ONetArea, 0)) AS ONetArea ,                 --认购面积
                                      SUM(ISNULL(tempYesDisk.ONetAmount, 0)) AS ONetAmount ,             --认购金额
                                      SUM(ISNULL(tempYesDisk.ONetCount, 0)) AS ONetCount ,               --认购套数
                                      SUM(ISNULL(tempYesDisk.CNetArea, 0)) AS CNetArea ,                 --签约面积
                                      SUM(ISNULL(tempYesDisk.CNetAmount, 0)) AS CNetAmount ,             --签约金额
                                      SUM(ISNULL(tempYesDisk.CNetAmountNotTax, 0)) AS CNetAmountNotTax , --签约金额(不含税)
                                      SUM(ISNULL(tempYesDisk.CNetCount, 0)) AS CNetCount ,               --签约套数
                                      0 AS SpecialONetAmount ,                                           --认购金额_特殊业绩
                                      0 AS SpecialCNetArea ,                                             --签约面积_特殊业绩
                                      0 AS SpecialCNetAmount ,                                           --签约金额_特殊业绩
                                      0 AS SpecialCNetCount ,                                            --签约套数_特殊业绩
                                      SUM(ISNULL(tempYesDisk.NCCumArea, 0)) AS NCCumArea ,               --累计草签面积
                                      SUM(ISNULL(tempYesDisk.NCCumAmount, 0)) AS NCCumAmount ,           --累计草签金额
                                      SUM(ISNULL(tempYesDisk.NCCumCount, 0)) AS NCCumCount ,             --累计草签套数
                                      SUM(ISNULL(tempYesDisk.ICCumArea, 0)) AS ICCumArea ,               --累计网签面积
                                      SUM(ISNULL(tempYesDisk.ICCumAmount, 0)) AS ICCumAmount ,           --累计网签金额
                                      SUM(ISNULL(tempYesDisk.ICCumCount, 0)) AS ICCumCount               --累计网签套数
                         FROM         data_wide_dws_mdm_Building sb --楼栋宽表
                                      INNER JOIN
                                      ( --房间存在一个面积段多个户型的
                                          SELECT   shd.ProjGUID ,
                                                   shd.BldGUID ,
                                                   hz.对应技术户型 AS UnitType ,
                                                   hz.AreaSection ,
                                                   -- CONVERT(NVARCHAR(10), shd.QsDate, 23) AS StatisticalDate ,                                                            --统计日期
                                                    convert(nvarchar(10), isnull(r.TsRoomQSDate, shd.QsDate), 23) AS StatisticalDate,
                                                    --SUM(CASE WHEN (p.DiskFlag = '是' and r.specialFlag = '否') or sp.TsyjType='经营类(溢价款)' THEN isnull(shd.BldArea,0) ELSE 0 END) as ONetArea, 							--认购面积
                                                    --SUM(CASE WHEN (p.DiskFlag = '是' and r.specialFlag = '否') or sp.TsyjType='经营类(溢价款)' THEN isnull(shd.jyTotal,0) ELSE 0 END) as ONetAmount, 						--认购金额
                                                    --SUM(CASE WHEN (p.DiskFlag = '是' and r.specialFlag = '否') or sp.TsyjType='经营类(溢价款)' THEN isnull(shd.Ts,0) ELSE 0 END) as ONetCount, 								--认购套数
                                                   0 AS ONetArea ,
                                                   0 AS ONetAmount ,
                                                   0 AS ONetCount ,
                                                   SUM(CASE WHEN (( p.DiskFlag = '是' AND r.specialFlag = '否' ) OR sp.YJMode = 1 )
                                                                 AND shd.TradeType = '签约' THEN ISNULL(shd.BldArea, 0)
                                                            ELSE 0
                                                       END) AS CNetArea ,                                                                                                --签约面积
                                                   SUM(CASE WHEN (( p.DiskFlag = '是' AND r.specialFlag = '否' ) OR sp.YJMode = 1 )
                                                                 AND shd.TradeType = '签约' THEN ISNULL(shd.jytotal, 0)
                                                            ELSE 0
                                                       END) AS CNetAmount ,                                                                                              --签约金额
                                                   SUM(CASE WHEN (( p.DiskFlag = '是' AND r.specialFlag = '否' ) OR sp.YJMode = 1 )
                                                                 AND shd.TradeType = '签约' THEN ISNULL(shd.JyTotalNoTax, 0)
                                                            ELSE 0
                                                       END) AS CNetAmountNotTax ,                                                                                        --签约金额(不含税)
                                                   SUM(CASE WHEN (( p.DiskFlag = '是' AND r.specialFlag = '否' ) OR sp.YJMode = 1) AND shd.TradeType = '签约' THEN
                                                                ISNULL(shd.Ts, 0)ELSE 0 END) AS CNetCount ,                                                              --签约套数
                                                   SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType = '草签' THEN ISNULL(shd.BldArea, 0)ELSE
                                                                                                                                                 0 END) AS NCCumArea ,   --累计草签面积
                                                   SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType = '草签' THEN ISNULL(shd.jytotal, 0)ELSE
                                                                                                                                                 0 END) AS NCCumAmount , --累计草签金额
                                                   SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType = '草签' THEN ISNULL(shd.Ts, 0)ELSE 0 END) AS NCCumCount ,      --累计草签套数
                                                   SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType = '网签' THEN ISNULL(shd.BldArea, 0)ELSE
                                                                                                                                                 0 END) AS ICCumArea ,   --累计网签面积
                                                   SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType = '网签' THEN ISNULL(shd.jytotal, 0)ELSE
                                                                                                                                                 0 END) AS ICCumAmount , --累计网签金额
                                                   SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType = '网签' THEN ISNULL(shd.Ts, 0)ELSE 0 END) AS ICCumCount        --累计网签套数
                                          FROM     data_wide_s_SaleHsData shd WITH ( NOLOCK )
                                                   INNER JOIN data_wide_s_RoomoVerride r WITH ( NOLOCK ) ON r.RoomGUID = shd.RoomGUID
                                                   INNER JOIN #hx hz ON hz.房间guid = r.RoomGUID
                                                   INNER JOIN data_wide_dws_mdm_Project p WITH ( NOLOCK ) ON p.ProjGUID = shd.ProjGUID
                                                   LEFT JOIN
                                                   (   SELECT   RoomGUID ,
                                                                YJMode
                                                       FROM     dbo.data_wide_s_SpecialPerformance
                                                       WHERE    YJMode=1 --TsyjType = '经营类(溢价款)'
                                                       GROUP BY RoomGUID ,
                                                                YJMode ) sp ON sp.RoomGUID = r.RoomGUID
                                          WHERE    shd.QsDate IS NOT NULL
                                          GROUP BY shd.ProjGUID ,
                                                   shd.BldGUID ,
                                                   -- CONVERT(NVARCHAR(10), shd.QsDate, 23) ,
                                                   convert(nvarchar(10), isnull(r.TsRoomQSDate, shd.QsDate), 23) ,
                                                   hz.对应技术户型 ,
                                                   hz.AreaSection
                                          UNION ALL
                                          --房间不存在一个面积段多个户型的
                                          SELECT   shd.ProjGUID ,
                                                   shd.BldGUID ,
                                                   hz.UnitType ,
                                                   hz.AreaSection ,
                                                   --CONVERT(NVARCHAR(10), shd.QsDate, 23) AS StatisticalDate ,                                                            --统计日期
                                                   convert(nvarchar(10), isnull(r.TsRoomQSDate, shd.QsDate), 23) AS StatisticalDate,
                                                --SUM(CASE WHEN (p.DiskFlag = '是' and r.specialFlag = '否') or sp.TsyjType='经营类(溢价款)' THEN isnull(shd.BldArea,0) ELSE 0 END) as ONetArea, 							--认购面积
                                                --SUM(CASE WHEN (p.DiskFlag = '是' and r.specialFlag = '否') or sp.TsyjType='经营类(溢价款)' THEN isnull(shd.jyTotal,0) ELSE 0 END) as ONetAmount, 						--认购金额
                                                --SUM(CASE WHEN (p.DiskFlag = '是' and r.specialFlag = '否') or sp.TsyjType='经营类(溢价款)' THEN isnull(shd.Ts,0) ELSE 0 END) as ONetCount, 								--认购套数
                                                   0 AS ONetArea ,
                                                   0 AS ONetAmount ,
                                                   0 AS ONetCount ,
                                                   SUM(CASE WHEN (( p.DiskFlag = '是' AND r.specialFlag = '否' ) OR sp.YJMode = 1)
                                                                 AND shd.TradeType = '签约' THEN ISNULL(shd.BldArea, 0)
                                                            ELSE 0
                                                       END) AS CNetArea ,                                                                                                --签约面积
                                                   SUM(CASE WHEN (( p.DiskFlag = '是' AND r.specialFlag = '否' ) OR sp.YJMode = 1 )
                                                                 AND shd.TradeType = '签约' THEN ISNULL(shd.jytotal, 0)
                                                            ELSE 0
                                                       END) AS CNetAmount ,                                                                                              --签约金额
                                                   SUM(CASE WHEN (( p.DiskFlag = '是' AND r.specialFlag = '否' ) OR sp.YJMode = 1 )
                                                                 AND shd.TradeType = '签约' THEN ISNULL(shd.JyTotalNoTax, 0)
                                                            ELSE 0
                                                       END) AS CNetAmountNotTax ,                                                                                        --签约金额(不含税)
                                                   SUM(CASE WHEN (( p.DiskFlag = '是' AND r.specialFlag = '否' )OR sp.YJMode = 1 ) AND shd.TradeType = '签约' THEN
                                                                ISNULL(shd.Ts, 0)ELSE 0 END) AS CNetCount ,                                                              --签约套数
                                                   SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType = '草签' THEN ISNULL(shd.BldArea, 0)ELSE
                                                                                                                                                 0 END) AS NCCumArea ,   --累计草签面积
                                                   SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType = '草签' THEN ISNULL(shd.jytotal, 0)ELSE
                                                                                                                                                 0 END) AS NCCumAmount , --累计草签金额
                                                   SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType = '草签' THEN ISNULL(shd.Ts, 0)ELSE 0 END) AS NCCumCount ,      --累计草签套数
                                                   SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType = '网签' THEN ISNULL(shd.BldArea, 0)ELSE
                                                                                                                                                 0 END) AS ICCumArea ,   --累计网签面积
                                                   SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType = '网签' THEN ISNULL(shd.jytotal, 0)ELSE
                                                                                                                                                 0 END) AS ICCumAmount , --累计网签金额
                                                   SUM(CASE WHEN shd.TradeType = '签约' AND shd.ContractType = '网签' THEN ISNULL(shd.Ts, 0)ELSE 0 END) AS ICCumCount        --累计网签套数
                                          FROM     data_wide_s_SaleHsData shd WITH ( NOLOCK )
                                                   INNER JOIN data_wide_s_RoomoVerride r WITH ( NOLOCK ) ON r.RoomGUID = shd.RoomGUID
                                                   INNER JOIN data_wide_mdm_ProductBuildUnitAreaSetting hz ON r.BldArea BETWEEN hz.BgnArea AND hz.EndArea
                                                                                                              AND hz.bldGUID = r.BldGUID
                                                   INNER JOIN data_wide_dws_mdm_Project p WITH ( NOLOCK ) ON p.ProjGUID = shd.ProjGUID
                                                   LEFT JOIN #hx hx ON r.RoomGUID = hx.房间guid
                                                   LEFT JOIN
                                                   (   SELECT   RoomGUID ,
                                                                YJMode
                                                       FROM     dbo.data_wide_s_SpecialPerformance
                                                       WHERE    YJMode = 1
                                                       GROUP BY RoomGUID ,
                                                                YJMode ) sp ON sp.RoomGUID = r.RoomGUID
                                          WHERE    shd.QsDate IS NOT NULL
                                                   AND hx.房间guid IS NULL
                                          GROUP BY shd.ProjGUID ,
                                                   shd.BldGUID ,
                                                   --   CONVERT(NVARCHAR(10), shd.QsDate, 23) ,
                                                   convert(nvarchar(10), isnull(r.TsRoomQSDate, shd.QsDate), 23) ,
                                                   hz.UnitType ,
                                                   hz.AreaSection
                                          UNION ALL
                                          --获取认购信息：1、直接签约的以签约日期为准；2、认购转签约除日期按照认购时间统计外，其余按照签约进行统计；
                                          --同个面积段存在多个户型
                                          SELECT   r.ProjGUID ,
                                                   r.BldGUID ,
                                                   hx.对应技术户型 UnitType ,
                                                   hx.AreaSection ,
                                                   --CONVERT(NVARCHAR(10), r.RgQsDate, 23) AS StatisticalDate ,
                                                   convert(nvarchar(10), isnull(r.TsRoomQSDate, r.RgQsDate), 23) AS StatisticalDate,
                                                   SUM(CASE WHEN r.specialFlag = '否' AND r.Status IN ( '签约', '认购' ) THEN r.BldArea ELSE 0 END) AS ONetArea ,
                                                   SUM(CASE WHEN r.specialFlag = '否' AND r.Status IN ( '签约', '认购' ) THEN
                                                                r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) AS ONetAmount ,
                                                   SUM(CASE WHEN ( r.specialFlag = '否' OR ISNULL(specialYj, 0) <> 0 ) AND r.Status IN ( '签约', '认购' ) THEN
                                                                1 ELSE 0 END) AS ONetCount ,
                                                   0 AS CNetArea ,         --签约面积
                                                   0 AS CNetAmount ,       --签约金额
                                                   0 AS CNetAmountNotTax , --签约金额(不含税)
                                                   0 AS CNetCount ,        --签约套数
                                                   0 AS NCCumArea ,        --累计草签面积
                                                   0 AS NCCumAmount ,      --累计草签金额
                                                   0 AS NCCumCount ,       --累计草签套数
                                                   0 AS ICCumArea ,        --累计网签面积
                                                   0 AS ICCumAmount ,      --累计网签金额
                                                   0 AS ICCumCount         --累计网签套数
                                          FROM     data_wide_s_RoomoVerride r WITH ( NOLOCK )
                                                   INNER JOIN #hx hx ON r.RoomGUID = hx.房间guid
                                          GROUP BY r.ProjGUID ,
                                                   r.BldGUID ,
                                                   --CONVERT(NVARCHAR(10), r.RgQsDate, 23) ,
                                                   convert(nvarchar(10), isnull(r.TsRoomQSDate, r.RgQsDate), 23) ,
                                                   hx.对应技术户型 ,
                                                   hx.AreaSection
                                          UNION ALL
                                          --同个面积段不存在多个户型
                                          SELECT   r.ProjGUID ,
                                                   r.BldGUID ,
                                                   hz.UnitType ,
                                                   hz.AreaSection ,
                                                   --CONVERT(NVARCHAR(10), r.RgQsDate, 23) AS StatisticalDate ,
                                                   convert(nvarchar(10), isnull(r.TsRoomQSDate, r.RgQsDate), 23) AS StatisticalDate,
                                                   SUM(CASE WHEN r.specialFlag = '否' AND r.Status IN ( '签约', '认购' ) THEN r.BldArea ELSE 0 END) AS ONetArea ,
                                                   SUM(CASE WHEN r.specialFlag = '否' AND r.Status IN ( '签约', '认购' ) THEN
                                                                r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) AS ONetAmount ,
                                                   SUM(CASE WHEN ( r.specialFlag = '否' OR ISNULL(specialYj, 0) <> 0 ) AND r.Status IN ( '签约', '认购' ) THEN
                                                                1 ELSE 0 END) AS ONetCount ,
                                                   0 AS CNetArea ,         --签约面积
                                                   0 AS CNetAmount ,       --签约金额
                                                   0 AS CNetAmountNotTax , --签约金额(不含税)
                                                   0 AS CNetCount ,        --签约套数
                                                   0 AS NCCumArea ,        --累计草签面积
                                                   0 AS NCCumAmount ,      --累计草签金额
                                                   0 AS NCCumCount ,       --累计草签套数
                                                   0 AS ICCumArea ,        --累计网签面积
                                                   0 AS ICCumAmount ,      --累计网签金额
                                                   0 AS ICCumCount         --累计网签套数
                                          FROM     data_wide_s_RoomoVerride r WITH ( NOLOCK )
                                                   LEFT JOIN #hx hx ON r.RoomGUID = hx.房间guid
                                                   INNER JOIN data_wide_mdm_ProductBuildUnitAreaSetting hz ON r.BldArea BETWEEN hz.BgnArea AND hz.EndArea
                                                                                                              AND hz.bldGUID = r.BldGUID
                                          WHERE    hx.房间guid IS NULL
                                          GROUP BY r.ProjGUID ,
                                                   r.BldGUID ,
                                                   --CONVERT(NVARCHAR(10), r.RgQsDate, 23) ,
                                                   convert(nvarchar(10), isnull(r.TsRoomQSDate, r.RgQsDate), 23) ,
                                                   hz.UnitType ,
                                                   hz.AreaSection ) tempYesDisk --销售交易回溯宽表-营销操盘取数
                             ON       tempYesDisk.BldGUID = sb.BuildingGUID
                         GROUP     BY sb.BuildingGUID , --产品楼栋GUID
                                      tempYesDisk.StatisticalDate ,
                                      tempYesDisk.UnitType ,
                                      tempYesDisk.AreaSection ) tempDisk
           GROUP  BY tempDisk.BldGUID ,
                     tempDisk.StatisticalDate ,
                     tempDisk.UnitType ,
                     tempDisk.AreaSection ) tempSum
       INNER JOIN data_wide_dws_mdm_Building sb WITH ( NOLOCK ) ON sb.BuildingGUID = tempSum.BldGUID
       INNER JOIN data_wide_dws_mdm_Project p WITH ( NOLOCK ) ON p.ProjGUID = sb.ProjGUID --分期项目
       LEFT JOIN data_wide_dws_s_Dimension_Organization org WITH ( NOLOCK ) ON org.OrgGUID = p.XMSSCSGSGUID
                                                                               AND org.ParentOrganizationGUID = p.BUGUID --公司
       LEFT JOIN
       (   SELECT *
           FROM
                  (   SELECT ROW_NUMBER() OVER ( PARTITION BY BldGUID
                                                 ORDER BY FangPanTime DESC ) AS rowno ,
                             *
                      FROM
                             (   SELECT    BldGUID ,
                                           FangPanTime ,
                                           SUM(BldArea) AS FangPanArea ,
                                           SUM(Total) AS FangPanAmount ,
                                           SUM(1) AS FangPanCount
                                 FROM      data_wide_s_RoomoVerride WITH ( NOLOCK )
                                 WHERE     FangPanTime IS NOT NULL
                                 GROUP  BY BldGUID ,
                                           FangPanTime ) temp ) temp1
           WHERE  rowno = 1 ) tempr ON tempr.BldGUID = tempSum.BldGUID
                                       AND DATEDIFF(DAY, tempr.FangPanTime, tempSum.StatisticalDate) = 0;


DROP TABLE #hx
