--缓存项目清单
SELECT  pj.projguid,p.增量存量分类
INTO    #p
FROM    data_wide_dws_mdm_project pj
inner join dw_d_topproject p on pj.projguid = p.项目guid
WHERE   pj.projstatus = '正常' AND pj.LEVEL = 2 and p.项目管理方式 in ('二级开发','收益权合作')
and isnull(p.开发受限,'')<>'否';

SELECT  p.增量存量分类,
        sum(ISNULL(剩余货值, 0) + ISNULL(lx.zhz, 0)) AS 剩余货值 ,
        sum(ISNULL(剩余面积, 0) + ISNULL(lx.zksmj, 0)) AS 剩余面积 ,
        sum(ISNULL(剩余套数, 0)) AS 剩余套数 ,
		sum(ISNULL(剩余面积不含车位, 0) + ISNULL(lx.zksmjnotcar, 0)) AS 剩余面积不含车位 ,
        sum(ISNULL(剩余套数不含车位, 0))  AS 剩余套数不含车位 ,
        sum(ISNULL(剩余货值不含车位, 0) + ISNULL(lx.zhznotcar, 0)) AS 剩余货值不含车位 ,
        sum(ISNULL(未开工剩余可售货值, 0) + ISNULL(lx.zhz, 0)) AS 未开工剩余可售货值 ,
        sum(ISNULL(未开工剩余可售面积, 0) + ISNULL(lx.zksmj, 0)) AS 未开工剩余可售面积 ,
        sum(ISNULL(未开工剩余可售套数, 0))  AS 未开工剩余可售套数,
		sum(ISNULL(未开工剩余可售面积不含车位, 0) + ISNULL(lx.zksmjnotcar, 0)) AS 未开工剩余可售面积不含车位 ,
        sum(ISNULL(未开工剩余可售套数不含车位, 0)) AS 未开工剩余可售套数不含车位 ,
        sum(ISNULL(未开工剩余可售货值不含车位, 0) + ISNULL(lx.zhznotcar, 0)) AS 未开工剩余可售货值不含车位 ,
        sum(ISNULL(已开工未达预售货值, 0)) AS 已开工未达预售货值 ,
        sum(ISNULL(已开工未达预售面积, 0)) AS 已开工未达预售面积 ,
        sum(ISNULL(已开工未达预售套数, 0)) AS 已开工未达预售套数,
		sum(ISNULL(已开工未达预售面积不含车位, 0)) AS 已开工未达预售面积不含车位 ,
        sum(ISNULL(已开工未达预售套数不含车位, 0)) AS 已开工未达预售套数不含车位 ,
        sum(ISNULL(已开工未达预售货值不含车位, 0)) AS 已开工未达预售货值不含车位 ,
        sum(ISNULL(产成品货值, 0)) AS 产成品货值 ,
        sum(ISNULL(产成品面积, 0)) AS 产成品面积 ,
        sum(ISNULL(产成品套数, 0)) AS 产成品套数 ,
		sum(ISNULL(产成品面积不含车位, 0)) AS 产成品面积不含车位 ,
        sum(ISNULL(产成品套数不含车位, 0)) AS 产成品套数不含车位 ,
        sum(ISNULL(产成品货值不含车位, 0)) AS 产成品货值不含车位 ,
        sum(ISNULL(准产成品面积, 0)) AS 准产成品面积 ,
        sum(ISNULL(准产成品套数, 0)) AS 准产成品套数 ,
		sum(ISNULL(准产成品面积不含车位, 0)) AS 准产成品面积不含车位 ,
        sum(ISNULL(准产成品套数不含车位, 0)) AS 准产成品套数不含车位 ,
        sum(ISNULL(准产成品货值, 0)) AS 准产成品货值 ,
        sum(ISNULL(准产成品货值不含车位, 0)) AS 准产成品货值不含车位 ,
        sum(ISNULL(达预售货值, 0)) AS 达预售货值 ,
        sum(ISNULL(达预售面积, 0)) AS 达预售面积 ,
        sum(ISNULL(达预售套数, 0)) AS 达预售套数 ,
		sum(ISNULL(达预售面积不含车位, 0)) AS 达预售面积不含车位 ,
        sum(ISNULL(达预售套数不含车位, 0)) AS 达预售套数不含车位 ,
        sum(ISNULL(达预售货值不含车位, 0)) AS 达预售货值不含车位 ,
        sum(ISNULL(达预售货值, 0) - ISNULL(产成品货值, 0) - ISNULL(准产成品货值, 0)) AS 达预售未形成准产成品货值 ,
        sum(ISNULL(达预售面积, 0) - ISNULL(产成品面积, 0) - ISNULL(准产成品面积, 0)) AS 达预售未形成准产成品面积 ,
        sum(ISNULL(达预售套数, 0) - ISNULL(产成品套数, 0) - ISNULL(准产成品套数, 0)) AS 达预售未形成准产成品套数 ,
		sum(ISNULL(达预售面积不含车位, 0) - ISNULL(产成品面积不含车位, 0) - ISNULL(准产成品面积不含车位, 0)) AS 达预售未形成准产成品面积不含车位 ,
        sum(ISNULL(达预售套数不含车位, 0) - ISNULL(产成品套数不含车位, 0) - ISNULL(准产成品套数不含车位, 0)) AS 达预售未形成准产成品套数不含车位 ,
        sum(ISNULL(达预售货值不含车位, 0) - ISNULL(产成品货值不含车位, 0) - ISNULL(准产成品货值不含车位, 0)) AS 达预售未形成准产成品货值不含车位 ,
        sum(ISNULL(剩余货值* EquityRatio, 0) + ISNULL(lx.zhz* EquityRatio, 0)) AS 剩余货值权益口径 ,
        sum(ISNULL(剩余面积* EquityRatio, 0) + ISNULL(lx.zksmj* EquityRatio, 0)) AS 剩余面积权益口径 ,
        sum(ISNULL(剩余套数* EquityRatio, 0) + ISNULL(lx.zksmj* EquityRatio, 0)) AS 剩余套数权益口径 ,
		sum(ISNULL(剩余面积不含车位* EquityRatio, 0) + ISNULL(lx.zksmjnotcar* EquityRatio, 0)) AS 剩余面积权益口径不含车位 ,
        sum(ISNULL(剩余套数不含车位* EquityRatio, 0) + ISNULL(lx.zksmjnotcar* EquityRatio, 0)) AS 剩余套数权益口径不含车位 ,
        sum(ISNULL(剩余货值不含车位* EquityRatio, 0) + ISNULL(lx.zhznotcar* EquityRatio, 0)) AS 剩余货值权益口径不含车位 ,
        sum(ISNULL(未开工剩余可售货值 * EquityRatio, 0)) 未开工剩余可售货值权益口径 ,
        sum(ISNULL(未开工剩余可售面积 * EquityRatio, 0)) 未开工剩余可售面积权益口径 ,
        sum(ISNULL(未开工剩余可售套数 * EquityRatio, 0)) 未开工剩余可售套数权益口径 ,
		sum(ISNULL(未开工剩余可售面积不含车位 * EquityRatio, 0)) 未开工剩余可售面积不含车位权益口径 ,
        sum(ISNULL(未开工剩余可售套数不含车位 * EquityRatio, 0)) 未开工剩余可售套数不含车位权益口径 ,
        sum(ISNULL(未开工剩余可售货值不含车位 * EquityRatio, 0)) 未开工剩余可售货值不含车位权益口径 ,
        sum(ISNULL(已开工未达预售货值 * EquityRatio, 0)) 已开工未达预售货值权益口径 ,
        sum(ISNULL(已开工未达预售面积 * EquityRatio, 0)) 已开工未达预售面积权益口径 ,
        sum(ISNULL(已开工未达预售套数 * EquityRatio, 0)) 已开工未达预售套数权益口径 ,
		sum(ISNULL(已开工未达预售面积不含车位 * EquityRatio, 0)) 已开工未达预售面积不含车位权益口径 ,
        sum(ISNULL(已开工未达预售套数不含车位 * EquityRatio, 0)) 已开工未达预售套数不含车位权益口径 ,
        sum(ISNULL(已开工未达预售货值不含车位 * EquityRatio, 0)) 已开工未达预售货值不含车位权益口径 ,
        sum(ISNULL(产成品货值 * EquityRatio, 0)) 产成品货值权益口径 ,
        sum(ISNULL(产成品面积 * EquityRatio, 0)) 产成品面积权益口径 ,
        sum(ISNULL(产成品套数 * EquityRatio, 0)) 产成品套数权益口径 ,
		sum(ISNULL(产成品面积不含车位 * EquityRatio, 0)) 产成品面积不含车位权益口径 ,
        sum(ISNULL(产成品套数不含车位 * EquityRatio, 0)) 产成品套数不含车位权益口径 ,
        sum(ISNULL(产成品货值不含车位 * EquityRatio, 0)) 产成品货值不含车位权益口径 ,
        sum(ISNULL(准产成品面积 * EquityRatio, 0)) 准产成品面积权益口径 ,
        sum(ISNULL(准产成品套数 * EquityRatio, 0)) 准产成品套数权益口径 ,
		sum(ISNULL(准产成品面积不含车位 * EquityRatio, 0)) 准产成品面积不含车位权益口径 ,
		sum(ISNULL(准产成品套数不含车位 * EquityRatio, 0)) 准产成品套数不含车位权益口径 ,
        sum(ISNULL(准产成品货值不含车位 * EquityRatio, 0)) 准产成品货值不含车位权益口径 ,
        sum(ISNULL(准产成品货值 * EquityRatio, 0)) 准产成品货值权益口径 ,
        sum((ISNULL(达预售货值, 0) - ISNULL(产成品货值, 0) - ISNULL(准产成品货值, 0)) * ISNULL(EquityRatio, 0)) 达预售未形成准产成品货值权益口径 ,
        sum((ISNULL(达预售面积, 0) - ISNULL(产成品面积, 0) - ISNULL(准产成品面积, 0)) * ISNULL(EquityRatio, 0)) 达预售未形成准产成品面积权益口径,
        sum((ISNULL(达预售套数, 0) - ISNULL(产成品套数, 0) - ISNULL(准产成品套数, 0)) * ISNULL(EquityRatio, 0)) 达预售未形成准产成品套数权益口径,
		sum((ISNULL(达预售面积不含车位, 0) - ISNULL(产成品面积不含车位, 0) - ISNULL(准产成品面积不含车位, 0)) * ISNULL(EquityRatio, 0)) 达预售未形成准产成品面积不含车位权益口径,
        sum((ISNULL(达预售套数不含车位, 0) - ISNULL(产成品套数不含车位, 0) - ISNULL(准产成品套数不含车位, 0)) * ISNULL(EquityRatio, 0)) 达预售未形成准产成品套数不含车位权益口径,
        sum((ISNULL(达预售货值不含车位, 0) - ISNULL(产成品货值不含车位, 0) - ISNULL(准产成品货值不含车位, 0)) * ISNULL(EquityRatio, 0)) 达预售未形成准产成品货值不含车位权益口径
FROM    #p P
        LEFT JOIN(SELECT    ld.projguid ,
                            pj.EquityRatio * 1.0 / 100 AS EquityRatio ,
                            SUM(syhz) AS 剩余货值 ,
							SUM(CASE WHEN isnull(ld.producttype,'') in ('地下室/车库','仓库') THEN 0 ELSE ISNULL(zksmj, 0) - ISNULL(ysmj, 0) END) AS 剩余面积不含车位 ,
                            SUM(CASE WHEN isnull(ld.producttype,'') in ('地下室/车库','仓库') THEN 0 ELSE ISNULL(zksts, 0) - ISNULL(ysts, 0) END) AS 剩余套数不含车位 ,
                            SUM(CASE WHEN isnull(ld.producttype,'') in ('地下室/车库','仓库') THEN 0 ELSE ISNULL(syhz, 0) END) AS 剩余货值不含车位 ,
                            SUM( ISNULL(zksmj, 0) - ISNULL(ysmj, 0)) AS 剩余面积 ,
                            SUM( ISNULL(zksts, 0) - ISNULL(ysts, 0)) AS 剩余套数 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL THEN syhz ELSE 0 END) 未开工剩余可售货值 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) 未开工剩余可售面积 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) 未开工剩余可售套数 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL AND  isnull(ld.producttype,'') not  in ('地下室/车库','仓库') THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) 未开工剩余可售面积不含车位 ,
							SUM(CASE WHEN ld.SJzskgdate IS NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL AND  isnull(ld.producttype,'') not  in ('地下室/车库','仓库') THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) 未开工剩余可售套数不含车位 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL AND  isnull(ld.producttype,'') not  in ('地下室/车库','仓库') THEN syhz ELSE 0 END) 未开工剩余可售货值不含车位 ,
                            --按产品楼栋，对应“实际开工时间”不为空，“达预售形象时间”为空或大于报表截止日期的楼栋的“剩余可售面积”之和
                            SUM(CASE WHEN ld.SJzskgdate IS NOT NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL THEN syhz ELSE 0 END) 已开工未达预售货值 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NOT NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) 已开工未达预售面积 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NOT NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) 已开工未达预售套数 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NOT NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL AND isnull(ld.producttype,'') not  in ('地下室/车库','仓库') THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) 已开工未达预售面积不含车位 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NOT NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL AND isnull(ld.producttype,'') not  in ('地下室/车库','仓库') THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) 已开工未达预售套数不含车位 ,
							SUM(CASE WHEN ld.SJzskgdate IS NOT NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL AND isnull(ld.producttype,'') not  in ('地下室/车库','仓库') THEN ISNULL(syhz, 0) ELSE 0 END) 已开工未达预售货值不含车位 ,
                            --实际竣工备案时间不为空
                            SUM(CASE WHEN SJjgbadate IS NOT NULL THEN syhz ELSE 0 END) AS 产成品货值 ,
                            SUM(CASE WHEN SJjgbadate IS NOT NULL THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) AS 产成品面积 ,
                            SUM(CASE WHEN SJjgbadate IS NOT NULL THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) AS 产成品套数 ,
                            SUM(CASE WHEN SJjgbadate IS NOT NULL AND  isnull(ld.producttype,'') not  in ('地下室/车库','仓库') THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) AS 产成品面积不含车位 ,
                            SUM(CASE WHEN SJjgbadate IS NOT NULL AND  isnull(ld.producttype,'') not  in ('地下室/车库','仓库') THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) AS 产成品套数不含车位 ,
                            SUM(CASE WHEN SJjgbadate IS NOT NULL AND  isnull(ld.producttype,'') not  in ('地下室/车库','仓库') THEN ISNULL(syhz, 0) ELSE 0 END) AS 产成品货值不含车位 ,
							--按产品楼栋，对应，【①“达预售形象时间”小于等于报表截止日期，②”达预售形象时间“为空或大于报表截止日期，且“累计销售金额>0”】，
                            -- 且“计划竣工备案表获取时间”小于等于当年12-31，“实际竣工备案表获取时间”为空或大于报表截止日期的楼栋的“剩余可售面积”之和
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR   SjDdysxxDate IS NOT NULL) AND   (DATEDIFF(dd, SjDdysxxDate, GETDATE()) >= 0 OR  (SjDdysxxDate IS NULL AND   ysje > 0))
                                      AND  SJjgbadate IS NULL AND  DATEDIFF(dd, Yjjgbadate, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31') >= 0 THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0)
                                 ELSE 0
                            END) 准产成品面积 ,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR   SjDdysxxDate IS NOT NULL) AND   (DATEDIFF(dd, SjDdysxxDate, GETDATE()) >= 0 OR  (SjDdysxxDate IS NULL AND   ysje > 0))
                                      AND  SJjgbadate IS NULL AND  DATEDIFF(dd, Yjjgbadate, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31') >= 0 THEN ISNULL(zksts, 0) - ISNULL(ysts, 0)
                                 ELSE 0
                            END) 准产成品套数 ,
							SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR   SjDdysxxDate IS NOT NULL) AND   (DATEDIFF(dd, SjDdysxxDate, GETDATE()) >= 0 OR  (SjDdysxxDate IS NULL AND   ysje > 0))
                                      AND  SJjgbadate IS NULL AND  DATEDIFF(dd, Yjjgbadate, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31') >= 0 AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库') THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0)
                                 ELSE 0
                            END) 准产成品面积不含车位 ,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR   SjDdysxxDate IS NOT NULL) AND   (DATEDIFF(dd, SjDdysxxDate, GETDATE()) >= 0 OR  (SjDdysxxDate IS NULL AND   ysje > 0))
                                      AND  SJjgbadate IS NULL AND  DATEDIFF(dd, Yjjgbadate, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31') >= 0 AND  isnull(ld.producttype,'')not in ('地下室/车库','仓库')  THEN ISNULL(zksts, 0) - ISNULL(ysts, 0)
                                 ELSE 0
                            END) 准产成品套数不含车位 ,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR   SjDdysxxDate IS NOT NULL) AND   (DATEDIFF(dd, SjDdysxxDate, GETDATE()) >= 0 OR  (SjDdysxxDate IS NULL AND   ysje > 0))
                                      AND  SJjgbadate IS NULL AND  DATEDIFF(dd, Yjjgbadate, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31') >= 0 THEN syhz
                                 ELSE 0
                            END) 准产成品货值 ,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR   SjDdysxxDate IS NOT NULL) AND   (DATEDIFF(dd, SjDdysxxDate, GETDATE()) >= 0 OR  (SjDdysxxDate IS NULL AND   ysje > 0))
                                      AND  SJjgbadate IS NULL AND  DATEDIFF(dd, Yjjgbadate, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31') >= 0 AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(syhz, 0)
                                 ELSE 0
                            END) 准产成品货值不含车位 ,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR  SjDdysxxDate IS NOT NULL or (SjDdysxxDate is null and sjjgbadate is not null and ysje=0))  THEN syhz ELSE 0 END) 达预售货值 ,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR  SjDdysxxDate IS NOT NULL or (SjDdysxxDate is null and sjjgbadate is not null and ysje=0))  THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) 达预售面积,
							SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR  SjDdysxxDate IS NOT NULL or (SjDdysxxDate is null and sjjgbadate is not null and ysje=0))  THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) 达预售套数,
							SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR  SjDdysxxDate IS NOT NULL or (SjDdysxxDate is null and sjjgbadate is not null and ysje=0))  AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) 达预售面积不含车位,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR  SjDdysxxDate IS NOT NULL or (SjDdysxxDate is null and sjjgbadate is not null and ysje=0))  AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) 达预售套数不含车位,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR  SjDdysxxDate IS NOT NULL or (SjDdysxxDate is null and sjjgbadate is not null and ysje=0))  AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(syhz, 0) ELSE 0 END) 达预售货值不含车位
                  FROM  data_wide_dws_s_p_lddbamj ld
                        INNER JOIN data_wide_dws_mdm_project pj ON pj.projguid = ld.projguid
                  GROUP BY ld.projguid , pj.EquityRatio) t ON P.projguid = t.projguid
        LEFT JOIN(SELECT    项目guid ,
                            SUM(CASE WHEN 是否可售 = '是' AND 是否自持 = '否' THEN CASE WHEN 定位销售收入含税 = 0 THEN 立项现金流入含税 ELSE 定位销售收入含税 END ELSE 0 END) AS zhz ,
                            SUM(CASE WHEN 是否可售 = '是' AND 是否自持 = '否' THEN CASE WHEN 定位可售面积 = 0 THEN 立项可售面积 ELSE 定位可售面积 END ELSE 0 END) AS zksmj,
							SUM(CASE WHEN 是否可售 = '是' AND 是否自持 = '否' and isnull(产品类型,'') not in ('地下室/车库','仓库')  THEN CASE WHEN 定位可售面积 = 0 THEN 立项可售面积 ELSE 定位可售面积 END ELSE 0 END) AS zksmjnotcar,
                            SUM(CASE WHEN 是否可售 = '是' AND 是否自持 = '否' and isnull(产品类型,'') not in ('地下室/车库','仓库')  THEN CASE WHEN 定位销售收入含税 = 0 THEN 立项现金流入含税 ELSE 定位销售收入含税 END ELSE 0 END) AS zhznotcar
				  FROM  data_wide_dws_qt_LxDwProfit_yt lxdw
                        LEFT JOIN(SELECT    DISTINCT   ParentProjGUID FROM  data_wide_dws_mdm_Building) pb ON pb.ParentProjGUID = lxdw.项目guid
                  WHERE pb.ParentProjGUID IS NULL
                  GROUP BY 项目guid) lx ON lx.项目guid = P.projguid
group by p.增量存量分类
union all 
SELECT  '全项目' 增量存量分类,
        sum(ISNULL(剩余货值, 0) + ISNULL(lx.zhz, 0)) AS 剩余货值 ,
        sum(ISNULL(剩余面积, 0) + ISNULL(lx.zksmj, 0)) AS 剩余面积 ,
        sum(ISNULL(剩余套数, 0)) AS 剩余套数 ,
		sum(ISNULL(剩余面积不含车位, 0) + ISNULL(lx.zksmjnotcar, 0)) AS 剩余面积不含车位 ,
        sum(ISNULL(剩余套数不含车位, 0))  AS 剩余套数不含车位 ,
        sum(ISNULL(剩余货值不含车位, 0) + ISNULL(lx.zhznotcar, 0)) AS 剩余货值不含车位 ,
        sum(ISNULL(未开工剩余可售货值, 0) + ISNULL(lx.zhz, 0)) AS 未开工剩余可售货值 ,
        sum(ISNULL(未开工剩余可售面积, 0) + ISNULL(lx.zksmj, 0)) AS 未开工剩余可售面积 ,
        sum(ISNULL(未开工剩余可售套数, 0))  AS 未开工剩余可售套数,
		sum(ISNULL(未开工剩余可售面积不含车位, 0) + ISNULL(lx.zksmjnotcar, 0)) AS 未开工剩余可售面积不含车位 ,
        sum(ISNULL(未开工剩余可售套数不含车位, 0)) AS 未开工剩余可售套数不含车位 ,
        sum(ISNULL(未开工剩余可售货值不含车位, 0) + ISNULL(lx.zhznotcar, 0)) AS 未开工剩余可售货值不含车位 ,
        sum(ISNULL(已开工未达预售货值, 0)) AS 已开工未达预售货值 ,
        sum(ISNULL(已开工未达预售面积, 0)) AS 已开工未达预售面积 ,
        sum(ISNULL(已开工未达预售套数, 0)) AS 已开工未达预售套数,
		sum(ISNULL(已开工未达预售面积不含车位, 0)) AS 已开工未达预售面积不含车位 ,
        sum(ISNULL(已开工未达预售套数不含车位, 0)) AS 已开工未达预售套数不含车位 ,
        sum(ISNULL(已开工未达预售货值不含车位, 0)) AS 已开工未达预售货值不含车位 ,
        sum(ISNULL(产成品货值, 0)) AS 产成品货值 ,
        sum(ISNULL(产成品面积, 0)) AS 产成品面积 ,
        sum(ISNULL(产成品套数, 0)) AS 产成品套数 ,
		sum(ISNULL(产成品面积不含车位, 0)) AS 产成品面积不含车位 ,
        sum(ISNULL(产成品套数不含车位, 0)) AS 产成品套数不含车位 ,
        sum(ISNULL(产成品货值不含车位, 0)) AS 产成品货值不含车位 ,
        sum(ISNULL(准产成品面积, 0)) AS 准产成品面积 ,
        sum(ISNULL(准产成品套数, 0)) AS 准产成品套数 ,
		sum(ISNULL(准产成品面积不含车位, 0)) AS 准产成品面积不含车位 ,
        sum(ISNULL(准产成品套数不含车位, 0)) AS 准产成品套数不含车位 ,
        sum(ISNULL(准产成品货值, 0)) AS 准产成品货值 ,
        sum(ISNULL(准产成品货值不含车位, 0)) AS 准产成品货值不含车位 ,
        sum(ISNULL(达预售货值, 0)) AS 达预售货值 ,
        sum(ISNULL(达预售面积, 0)) AS 达预售面积 ,
        sum(ISNULL(达预售套数, 0)) AS 达预售套数 ,
		sum(ISNULL(达预售面积不含车位, 0)) AS 达预售面积不含车位 ,
        sum(ISNULL(达预售套数不含车位, 0)) AS 达预售套数不含车位 ,
        sum(ISNULL(达预售货值不含车位, 0)) AS 达预售货值不含车位 ,
        sum(ISNULL(达预售货值, 0) - ISNULL(产成品货值, 0) - ISNULL(准产成品货值, 0)) AS 达预售未形成准产成品货值 ,
        sum(ISNULL(达预售面积, 0) - ISNULL(产成品面积, 0) - ISNULL(准产成品面积, 0)) AS 达预售未形成准产成品面积 ,
        sum(ISNULL(达预售套数, 0) - ISNULL(产成品套数, 0) - ISNULL(准产成品套数, 0)) AS 达预售未形成准产成品套数 ,
		sum(ISNULL(达预售面积不含车位, 0) - ISNULL(产成品面积不含车位, 0) - ISNULL(准产成品面积不含车位, 0)) AS 达预售未形成准产成品面积不含车位 ,
        sum(ISNULL(达预售套数不含车位, 0) - ISNULL(产成品套数不含车位, 0) - ISNULL(准产成品套数不含车位, 0)) AS 达预售未形成准产成品套数不含车位 ,
        sum(ISNULL(达预售货值不含车位, 0) - ISNULL(产成品货值不含车位, 0) - ISNULL(准产成品货值不含车位, 0)) AS 达预售未形成准产成品货值不含车位 ,
        sum(ISNULL(剩余货值* EquityRatio, 0) + ISNULL(lx.zhz* EquityRatio, 0)) AS 剩余货值权益口径 ,
        sum(ISNULL(剩余面积* EquityRatio, 0) + ISNULL(lx.zksmj* EquityRatio, 0)) AS 剩余面积权益口径 ,
        sum(ISNULL(剩余套数* EquityRatio, 0) + ISNULL(lx.zksmj* EquityRatio, 0)) AS 剩余套数权益口径 ,
		sum(ISNULL(剩余面积不含车位* EquityRatio, 0) + ISNULL(lx.zksmjnotcar* EquityRatio, 0)) AS 剩余面积权益口径不含车位 ,
        sum(ISNULL(剩余套数不含车位* EquityRatio, 0) + ISNULL(lx.zksmjnotcar* EquityRatio, 0)) AS 剩余套数权益口径不含车位 ,
        sum(ISNULL(剩余货值不含车位* EquityRatio, 0) + ISNULL(lx.zhznotcar* EquityRatio, 0)) AS 剩余货值权益口径不含车位 ,
        sum(ISNULL(未开工剩余可售货值 * EquityRatio, 0)) 未开工剩余可售货值权益口径 ,
        sum(ISNULL(未开工剩余可售面积 * EquityRatio, 0)) 未开工剩余可售面积权益口径 ,
        sum(ISNULL(未开工剩余可售套数 * EquityRatio, 0)) 未开工剩余可售套数权益口径 ,
		sum(ISNULL(未开工剩余可售面积不含车位 * EquityRatio, 0)) 未开工剩余可售面积不含车位权益口径 ,
        sum(ISNULL(未开工剩余可售套数不含车位 * EquityRatio, 0)) 未开工剩余可售套数不含车位权益口径 ,
        sum(ISNULL(未开工剩余可售货值不含车位 * EquityRatio, 0)) 未开工剩余可售货值不含车位权益口径 ,
        sum(ISNULL(已开工未达预售货值 * EquityRatio, 0)) 已开工未达预售货值权益口径 ,
        sum(ISNULL(已开工未达预售面积 * EquityRatio, 0)) 已开工未达预售面积权益口径 ,
        sum(ISNULL(已开工未达预售套数 * EquityRatio, 0)) 已开工未达预售套数权益口径 ,
		sum(ISNULL(已开工未达预售面积不含车位 * EquityRatio, 0)) 已开工未达预售面积不含车位权益口径 ,
        sum(ISNULL(已开工未达预售套数不含车位 * EquityRatio, 0)) 已开工未达预售套数不含车位权益口径 ,
        sum(ISNULL(已开工未达预售货值不含车位 * EquityRatio, 0)) 已开工未达预售货值不含车位权益口径 ,
        sum(ISNULL(产成品货值 * EquityRatio, 0)) 产成品货值权益口径 ,
        sum(ISNULL(产成品面积 * EquityRatio, 0)) 产成品面积权益口径 ,
        sum(ISNULL(产成品套数 * EquityRatio, 0)) 产成品套数权益口径 ,
		sum(ISNULL(产成品面积不含车位 * EquityRatio, 0)) 产成品面积不含车位权益口径 ,
        sum(ISNULL(产成品套数不含车位 * EquityRatio, 0)) 产成品套数不含车位权益口径 ,
        sum(ISNULL(产成品货值不含车位 * EquityRatio, 0)) 产成品货值不含车位权益口径 ,
        sum(ISNULL(准产成品面积 * EquityRatio, 0)) 准产成品面积权益口径 ,
        sum(ISNULL(准产成品套数 * EquityRatio, 0)) 准产成品套数权益口径 ,
		sum(ISNULL(准产成品面积不含车位 * EquityRatio, 0)) 准产成品面积不含车位权益口径 ,
		sum(ISNULL(准产成品套数不含车位 * EquityRatio, 0)) 准产成品套数不含车位权益口径 ,
        sum(ISNULL(准产成品货值不含车位 * EquityRatio, 0)) 准产成品货值不含车位权益口径 ,
        sum(ISNULL(准产成品货值 * EquityRatio, 0)) 准产成品货值权益口径 ,
        sum((ISNULL(达预售货值, 0) - ISNULL(产成品货值, 0) - ISNULL(准产成品货值, 0)) * ISNULL(EquityRatio, 0)) 达预售未形成准产成品货值权益口径 ,
        sum((ISNULL(达预售面积, 0) - ISNULL(产成品面积, 0) - ISNULL(准产成品面积, 0)) * ISNULL(EquityRatio, 0)) 达预售未形成准产成品面积权益口径,
        sum((ISNULL(达预售套数, 0) - ISNULL(产成品套数, 0) - ISNULL(准产成品套数, 0)) * ISNULL(EquityRatio, 0)) 达预售未形成准产成品套数权益口径,
		sum((ISNULL(达预售面积不含车位, 0) - ISNULL(产成品面积不含车位, 0) - ISNULL(准产成品面积不含车位, 0)) * ISNULL(EquityRatio, 0)) 达预售未形成准产成品面积不含车位权益口径,
        sum((ISNULL(达预售套数不含车位, 0) - ISNULL(产成品套数不含车位, 0) - ISNULL(准产成品套数不含车位, 0)) * ISNULL(EquityRatio, 0)) 达预售未形成准产成品套数不含车位权益口径,
        sum((ISNULL(达预售货值不含车位, 0) - ISNULL(产成品货值不含车位, 0) - ISNULL(准产成品货值不含车位, 0)) * ISNULL(EquityRatio, 0)) 达预售未形成准产成品货值不含车位权益口径
FROM    #p P
        LEFT JOIN(SELECT    ld.projguid ,
                            pj.EquityRatio * 1.0 / 100 AS EquityRatio ,
                            SUM(syhz) AS 剩余货值 ,
							SUM(CASE WHEN isnull(ld.producttype,'') in ('地下室/车库','仓库')  THEN 0 ELSE ISNULL(zksmj, 0) - ISNULL(ysmj, 0) END) AS 剩余面积不含车位 ,
                            SUM(CASE WHEN isnull(ld.producttype,'') in ('地下室/车库','仓库')  THEN 0 ELSE ISNULL(zksts, 0) - ISNULL(ysts, 0) END) AS 剩余套数不含车位 ,
                            SUM(CASE WHEN isnull(ld.producttype,'') in ('地下室/车库','仓库')  THEN 0 ELSE ISNULL(syhz, 0) END) AS 剩余货值不含车位 ,
                            SUM( ISNULL(zksmj, 0) - ISNULL(ysmj, 0)) AS 剩余面积 ,
                            SUM( ISNULL(zksts, 0) - ISNULL(ysts, 0)) AS 剩余套数 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL THEN syhz ELSE 0 END) 未开工剩余可售货值 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) 未开工剩余可售面积 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) 未开工剩余可售套数 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) 未开工剩余可售面积不含车位 ,
							SUM(CASE WHEN ld.SJzskgdate IS NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) 未开工剩余可售套数不含车位 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN syhz ELSE 0 END) 未开工剩余可售货值不含车位 ,
                            --按产品楼栋，对应“实际开工时间”不为空，“达预售形象时间”为空或大于报表截止日期的楼栋的“剩余可售面积”之和
                            SUM(CASE WHEN ld.SJzskgdate IS NOT NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL THEN syhz ELSE 0 END) 已开工未达预售货值 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NOT NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) 已开工未达预售面积 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NOT NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) 已开工未达预售套数 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NOT NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL AND isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) 已开工未达预售面积不含车位 ,
                            SUM(CASE WHEN ld.SJzskgdate IS NOT NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL AND isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) 已开工未达预售套数不含车位 ,
							SUM(CASE WHEN ld.SJzskgdate IS NOT NULL AND SjDdysxxDate IS NULL AND ld.ysje <= 0 AND   SJjgbadate IS NULL AND isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(syhz, 0) ELSE 0 END) 已开工未达预售货值不含车位 ,
                            --实际竣工备案时间不为空
                            SUM(CASE WHEN SJjgbadate IS NOT NULL THEN syhz ELSE 0 END) AS 产成品货值 ,
                            SUM(CASE WHEN SJjgbadate IS NOT NULL THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) AS 产成品面积 ,
                            SUM(CASE WHEN SJjgbadate IS NOT NULL THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) AS 产成品套数 ,
                            SUM(CASE WHEN SJjgbadate IS NOT NULL AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) AS 产成品面积不含车位 ,
                            SUM(CASE WHEN SJjgbadate IS NOT NULL AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) AS 产成品套数不含车位 ,
                            SUM(CASE WHEN SJjgbadate IS NOT NULL AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(syhz, 0) ELSE 0 END) AS 产成品货值不含车位 ,
							--按产品楼栋，对应，【①“达预售形象时间”小于等于报表截止日期，②”达预售形象时间“为空或大于报表截止日期，且“累计销售金额>0”】，
                            -- 且“计划竣工备案表获取时间”小于等于当年12-31，“实际竣工备案表获取时间”为空或大于报表截止日期的楼栋的“剩余可售面积”之和
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR   SjDdysxxDate IS NOT NULL) AND   (DATEDIFF(dd, SjDdysxxDate, GETDATE()) >= 0 OR  (SjDdysxxDate IS NULL AND   ysje > 0))
                                      AND  SJjgbadate IS NULL AND  DATEDIFF(dd, Yjjgbadate, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31') >= 0 THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0)
                                 ELSE 0
                            END) 准产成品面积 ,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR   SjDdysxxDate IS NOT NULL) AND   (DATEDIFF(dd, SjDdysxxDate, GETDATE()) >= 0 OR  (SjDdysxxDate IS NULL AND   ysje > 0))
                                      AND  SJjgbadate IS NULL AND  DATEDIFF(dd, Yjjgbadate, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31') >= 0 THEN ISNULL(zksts, 0) - ISNULL(ysts, 0)
                                 ELSE 0
                            END) 准产成品套数 ,
							SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR   SjDdysxxDate IS NOT NULL) AND   (DATEDIFF(dd, SjDdysxxDate, GETDATE()) >= 0 OR  (SjDdysxxDate IS NULL AND   ysje > 0))
                                      AND  SJjgbadate IS NULL AND  DATEDIFF(dd, Yjjgbadate, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31') >= 0 AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0)
                                 ELSE 0
                            END) 准产成品面积不含车位 ,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR   SjDdysxxDate IS NOT NULL) AND   (DATEDIFF(dd, SjDdysxxDate, GETDATE()) >= 0 OR  (SjDdysxxDate IS NULL AND   ysje > 0))
                                      AND  SJjgbadate IS NULL AND  DATEDIFF(dd, Yjjgbadate, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31') >= 0 AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(zksts, 0) - ISNULL(ysts, 0)
                                 ELSE 0
                            END) 准产成品套数不含车位 ,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR   SjDdysxxDate IS NOT NULL) AND   (DATEDIFF(dd, SjDdysxxDate, GETDATE()) >= 0 OR  (SjDdysxxDate IS NULL AND   ysje > 0))
                                      AND  SJjgbadate IS NULL AND  DATEDIFF(dd, Yjjgbadate, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31') >= 0 THEN syhz
                                 ELSE 0
                            END) 准产成品货值 ,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR   SjDdysxxDate IS NOT NULL) AND   (DATEDIFF(dd, SjDdysxxDate, GETDATE()) >= 0 OR  (SjDdysxxDate IS NULL AND   ysje > 0))
                                      AND  SJjgbadate IS NULL AND  DATEDIFF(dd, Yjjgbadate, CONVERT(VARCHAR(4), YEAR(GETDATE())) + '-12-31') >= 0 AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(syhz, 0)
                                 ELSE 0
                            END) 准产成品货值不含车位 ,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR  SjDdysxxDate IS NOT NULL or (SjDdysxxDate is null and sjjgbadate is not null and ysje=0))  THEN syhz ELSE 0 END) 达预售货值 ,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR  SjDdysxxDate IS NOT NULL or (SjDdysxxDate is null and sjjgbadate is not null and ysje=0))  THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) 达预售面积,
							SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR  SjDdysxxDate IS NOT NULL or (SjDdysxxDate is null and sjjgbadate is not null and ysje=0))  THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) 达预售套数,
							SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR  SjDdysxxDate IS NOT NULL or (SjDdysxxDate is null and sjjgbadate is not null and ysje=0))  AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(zksmj, 0) - ISNULL(ysmj, 0) ELSE 0 END) 达预售面积不含车位,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR  SjDdysxxDate IS NOT NULL or (SjDdysxxDate is null and sjjgbadate is not null and ysje=0))  AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(zksts, 0) - ISNULL(ysts, 0) ELSE 0 END) 达预售套数不含车位,
                            SUM(CASE WHEN ((SjDdysxxDate IS NULL AND ysje > 0) OR  SjDdysxxDate IS NOT NULL or (SjDdysxxDate is null and sjjgbadate is not null and ysje=0))  AND  isnull(ld.producttype,'') not in ('地下室/车库','仓库')  THEN ISNULL(syhz, 0) ELSE 0 END) 达预售货值不含车位
                  FROM  data_wide_dws_s_p_lddbamj ld
                        INNER JOIN data_wide_dws_mdm_project pj ON pj.projguid = ld.projguid
                  GROUP BY ld.projguid , pj.EquityRatio) t ON P.projguid = t.projguid
        LEFT JOIN(SELECT    项目guid ,
                            SUM(CASE WHEN 是否可售 = '是' AND 是否自持 = '否' THEN CASE WHEN 定位销售收入含税 = 0 THEN 立项现金流入含税 ELSE 定位销售收入含税 END ELSE 0 END) AS zhz ,
                            SUM(CASE WHEN 是否可售 = '是' AND 是否自持 = '否' THEN CASE WHEN 定位可售面积 = 0 THEN 立项可售面积 ELSE 定位可售面积 END ELSE 0 END) AS zksmj,
							SUM(CASE WHEN 是否可售 = '是' AND 是否自持 = '否' and isnull(产品类型,'') not in ('地下室/车库','仓库')  THEN CASE WHEN 定位可售面积 = 0 THEN 立项可售面积 ELSE 定位可售面积 END ELSE 0 END) AS zksmjnotcar,
                            SUM(CASE WHEN 是否可售 = '是' AND 是否自持 = '否' and isnull(产品类型,'') not in ('地下室/车库','仓库')  THEN CASE WHEN 定位销售收入含税 = 0 THEN 立项现金流入含税 ELSE 定位销售收入含税 END ELSE 0 END) AS zhznotcar
				  FROM  data_wide_dws_qt_LxDwProfit_yt lxdw
                        LEFT JOIN(SELECT    DISTINCT   ParentProjGUID FROM  data_wide_dws_mdm_Building) pb ON pb.ParentProjGUID = lxdw.项目guid
                  WHERE pb.ParentProjGUID IS NULL
                  GROUP BY 项目guid) lx ON lx.项目guid = P.projguid
;
 
DROP TABLE #p;