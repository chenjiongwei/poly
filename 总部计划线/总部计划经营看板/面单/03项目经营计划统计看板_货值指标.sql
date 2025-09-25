-- 货值指标
create or alter proc usp_zb_jyjhtjkb_SaleValue
as
begin
    /***********************************************************************
    * 1. 删除当天已存在的数据，避免重复插入
    *    说明：防止重复插入同一天的数据，保证数据唯一性
    ***********************************************************************/
    DELETE FROM zb_jyjhtjkb_SaleValue
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0;

    /***********************************************************************
    * 2. 汇总货值相关数据，生成临时表#hz
    *    说明：从data_wide_dws_jh_YtHzOverview表中，按项目汇总各类货值相关指标
    ***********************************************************************/
    SELECT  ld.projguid ,
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
    into  #hz
    FROM  data_wide_dws_s_p_lddbamj ld
        INNER JOIN data_wide_dws_mdm_project pj ON pj.projguid = ld.projguid
    GROUP BY ld.projguid , pj.EquityRatio

    /***********************************************************************
    * 3. 汇总各项数据，插入货值指标表
    *    说明：将临时表#hz与项目主数据表关联，插入目标表zb_jyjhtjkb_SaleValue
    *         只统计二级项目（p.level=2）
    *         产成品货值暂未取值，填NULL
    ***********************************************************************/
    INSERT INTO zb_jyjhtjkb_SaleValue (
        [buguid],              -- 事业部GUID
        [projguid],            -- 项目GUID
        [清洗日期],            -- 当前清洗日期
        [未开工货值],          -- 拿地未开工货值金额
        [已开工未售货值],      -- 动态剩余总可售货值金额
        [产成品货值]           -- 产成品货值（暂未取值）
    )
    SELECT
        p.buguid AS [buguid],                        -- 事业部GUID
        p.projguid AS [projguid],                    -- 项目GUID
        GETDATE() AS [清洗日期],                     -- 当前清洗日期
        hz.未开工剩余可售货值 /100000000.0 AS [未开工货值],         -- 拿地未开工货值金额
        (isnull(hz.已开工未达预售货值,0) + isnull(达预售货值,0) ) /100000000.0  AS [已开工未售货值], -- 动态剩余总可售货值金额 
        --     sum(ISNULL(已开工未达预售货值, 0)) AS 已开工未达预售货值 ,
        --     sum(ISNULL(达预售货值, 0) - ISNULL(产成品货值, 0) - ISNULL(准产成品货值, 0)) AS 达预售未形成准产成品货值 ,
        --     sum(ISNULL(准产成品货值, 0)) AS 准产成品货值 ,
        --    sum(ISNULL(产成品货值, 0)) AS 产成品货值 
        isnull(hz.产成品货值,0) /100000000.0 AS [产成品货值]                          -- 产成品货值（后续如有需求可补充） 
    FROM data_wide_dws_mdm_Project p
    LEFT JOIN #hz hz ON p.projguid = hz.projguid
    WHERE p.level = 2;                               -- 只统计二级项目

    /***********************************************************************
    * 4. 查询当天插入的最终数据，便于校验
    *    说明：便于开发或运维人员核查本次插入的数据
    ***********************************************************************/
    SELECT
        [buguid],
        [projguid],
        [清洗日期],
        [未开工货值],
        [已开工未售货值],
        [产成品货值]
    FROM zb_jyjhtjkb_SaleValue
    WHERE DATEDIFF(DAY, 清洗日期, GETDATE()) = 0;

    /***********************************************************************
    * 5. 删除临时表，释放资源
    ***********************************************************************/
    DROP TABLE #hz

end



--  SELECT
--     [buguid],
--     [projguid],
--     [清洗日期],
--     [未开工货值],
--     [已开工未售货值],
--     [产成品货值]
-- FROM zb_jyjhtjkb_SaleValue
-- WHERE 
-- DATEDIFF(DAY, [清洗日期], ${qxDate}) = 0
