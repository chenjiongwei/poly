 declare @var_date date = '2025-08-26';


       select  pj.ProjGUID ,
                 bld.TopProductTypeName,
                SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  
                       AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本年准产成品认购金额 ,
                       
                SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本年准产成品认购面积,
				SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本年准产成品认购套数 ,


                SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本年认购金额 ,
				SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本年认购面积 ,
                SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本年认购套数      
          into  #rsale       
        FROM    dbo.data_wide_s_RoomoVerride r
                INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = r.BldGUID
                INNER JOIN data_wide_dws_mdm_Project pj ON r.ParentProjGUID = pj.ProjGUID
                LEFT JOIN data_tb_hnyx_areasection mjd ON r.BldArea between mjd.开始面积 and mjd.截止面积 and mjd.业态 = bld.TopProductTypeName
                LEFT JOIN data_wide_s_LdfSaleDtl ldf on ldf.RoomGUID = r.RoomGUID
        WHERE   r.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' --and   pj.projguid ='7f0a49da-5a96-e911-80b7-0a94ef7517dd'
        GROUP BY pj.ProjGUID ,
                 bld.TopProductTypeName;

        --获取华南公司的所有楼栋一级产品类型信息
        SELECT  ParentProjGUID ,
                p.ProjName AS ParentProjName ,
                TopProductTypeName ,
                TopProductTypeGUID ,
                -- 佛山市顺德区华侨中学扩建工程等7所学校代 代建项目特殊处理，归入到其它类，不要在新增量分类中出现
                MAX(CASE WHEN ISNULL(tb.营销事业部, '') = '其他' OR ISNULL(tb.营销片区, '') = '其他' THEN '其它'
                         ELSE CASE WHEN YEAR(p.BeginDate) > 2022 THEN '新增量' WHEN YEAR(p.BeginDate) = 2022 THEN '增量' ELSE '存量' END
                    END) AS 存量增量 ,
                DATEDIFF(DAY, DATEADD(yy, DATEDIFF(yy, 0, @var_date), 0), @var_date) * 1.00 / 365 本年时间分摊比 ,
                DATEDIFF(DAY, DATEADD(mm, DATEDIFF(mm, 0, @var_date), 0), @var_date) * 1.00 / 30 AS 本月时间分摊比
        INTO    #TopProduct
        FROM    data_wide_dws_mdm_Building bd
        INNER JOIN data_wide_dws_mdm_Project p ON bd.ParentProjGUID = p.ProjGUID AND   p.Level = 2
        LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
        WHERE   bd.BldType = '产品楼栋' AND bd.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
        GROUP BY ParentProjGUID ,
                 p.ProjName ,
                 TopProductTypeName ,
                 TopProductTypeGUID;


    --获取各产品业态的特殊业绩及合作项目的认购情况
        SELECT  pj.ProjGUID ,
                pt.TopProductTypeName ,
                SUM(ISNULL(hz.bnhzje, 0) + ISNULL(ts.bnhzje, 0)) AS 本年认购金额 ,
                SUM(ISNULL(hz.bnhzmj, 0) + ISNULL(ts.bnhzmj, 0)) AS 本年认购面积 ,
                SUM(ISNULL(hz.bnhzts, 0) + ISNULL(ts.bnhzts, 0)) AS 本年认购套数 ,

                SUM(ISNULL(hz.byhzje, 0) + ISNULL(ts.byhzje, 0)) AS 本月认购金额 ,
                SUM(ISNULL(hz.byhzmj, 0) + ISNULL(ts.byhzmj, 0)) AS 本月认购面积 ,          
				SUM(ISNULL(hz.byhzts, 0) + ISNULL(ts.byhzts, 0)) AS 本月认购套数 ,
                

                
				SUM(ISNULL(hz.brhzje, 0) + ISNULL(ts.brhzje, 0)) AS 本日认购金额 ,
				SUM(ISNULL(hz.brhzmj, 0) + ISNULL(ts.brhzmj, 0)) AS 本日认购面积 ,
                SUM(ISNULL(hz.brhzts, 0) + ISNULL(ts.brhzts, 0)) AS 本日认购套数,

                --物业车位代销
                SUM(ISNULL(ts.bnhzje_wycwdx, 0)) AS 本年认购金额_物业车位代销, 
                SUM(ISNULL(ts.bnhzmj_wycwdx, 0)) AS 本年认购面积_物业车位代销, 
                SUM(ISNULL(ts.bnhzts_wycwdx, 0)) AS 本年认购套数_物业车位代销, 

                SUM(ISNULL(ts.byhzje_wycwdx, 0)) AS 本月认购金额_物业车位代销, 
                SUM(ISNULL(ts.byhzmj_wycwdx, 0)) AS 本月认购面积_物业车位代销, 
                SUM(ISNULL(ts.byhzts_wycwdx, 0)) AS 本月认购套数_物业车位代销, 

                --SUM(ISNULL(ts.bzhzje_wycwdx, 0)) AS 本周认购金额_物业车位代销, 
                --SUM(ISNULL(ts.bzhzmj_wycwdx, 0)) AS 本周认购面积_物业车位代销, 
                --SUM(ISNULL(ts.bzhzts_wycwdx, 0)) AS 本周认购套数_物业车位代销, 

                SUM(ISNULL(ts.brhzje_wycwdx, 0)) AS 本日认购金额_物业车位代销, 
                SUM(ISNULL(ts.brhzmj_wycwdx, 0)) AS 本日认购面积_物业车位代销, 
                SUM(ISNULL(ts.brhzts_wycwdx, 0)) AS 本日认购套数_物业车位代销,

                --产成品
				SUM(ISNULL(hz.bnccphzje, 0) + ISNULL(ts.bnccphzje, 0)) AS 本年产成品认购金额 ,
				SUM(ISNULL(hz.bnccphzmj, 0) + ISNULL(ts.bnccphzmj, 0)) AS 本年产成品认购面积 ,
                SUM(ISNULL(hz.bnccphzts, 0) + ISNULL(ts.bnccphzts, 0)) AS 本年产成品认购套数 ,

                SUM(ISNULL(hz.byccphzje, 0) + ISNULL(ts.byccphzje, 0)) AS 本月产成品认购金额 ,
                SUM(ISNULL(hz.byccphzmj, 0) + ISNULL(ts.byccphzmj, 0)) AS 本月产成品认购面积 ,              
				SUM(ISNULL(hz.byccphzts, 0) + ISNULL(ts.byccphzts, 0)) AS 本月产成品认购套数 ,
                
				--SUM(ISNULL(hz.bzccphzje, 0) + ISNULL(ts.bzccphzje, 0)) AS 本周产成品认购金额 ,
    -- 		    SUM(ISNULL(hz.bzccphzmj, 0) + ISNULL(ts.bzccphzmj, 0)) AS 本周产成品认购面积 ,           
				--SUM(ISNULL(hz.bzccphzts, 0) + ISNULL(ts.bzccphzts, 0)) AS 本周产成品认购套数 ,

                SUM(ISNULL(hz.brccphzje, 0) + ISNULL(ts.brccphzje, 0)) AS 本日产成品认购金额 ,
                SUM(ISNULL(hz.brccphzmj, 0) + ISNULL(ts.brccphzmj, 0)) AS 本日产成品认购面积 ,
                SUM(ISNULL(hz.brccphzts, 0) + ISNULL(ts.brccphzts, 0)) AS 本日产成品认购套数 ,

                --产成品-物业代销车位
                SUM(ISNULL(ts.bnccphzje_wycwdx, 0)) AS 本年产成品认购金额_物业车位代销 ,
				SUM(ISNULL(ts.bnccphzmj_wycwdx, 0)) AS 本年产成品认购面积_物业车位代销 ,
                SUM(ISNULL(ts.bnccphzts_wycwdx, 0)) AS 本年产成品认购套数_物业车位代销 ,

                SUM(ISNULL(ts.byccphzje_wycwdx, 0)) AS 本月产成品认购金额_物业车位代销 ,
                SUM(ISNULL(ts.byccphzmj_wycwdx, 0)) AS 本月产成品认购面积_物业车位代销 ,              
				SUM(ISNULL(ts.byccphzts_wycwdx, 0)) AS 本月产成品认购套数_物业车位代销 , 

				--SUM(ISNULL(ts.bzccphzje_wycwdx, 0)) AS 本周产成品认购金额_物业车位代销 ,
    -- 		    SUM(ISNULL(ts.bzccphzmj_wycwdx, 0)) AS 本周产成品认购面积_物业车位代销 ,           
				--SUM(ISNULL(ts.bzccphzts_wycwdx, 0)) AS 本周产成品认购套数_物业车位代销 ,

                SUM(ISNULL(ts.brccphzje_wycwdx, 0)) AS 本日产成品认购金额_物业车位代销 ,
                SUM(ISNULL(ts.brccphzmj_wycwdx, 0)) AS 本日产成品认购面积_物业车位代销 ,
                SUM(ISNULL(ts.brccphzts_wycwdx, 0)) AS 本日产成品认购套数_物业车位代销 ,

                --准产成品
				SUM(ISNULL(hz.zbnccphzje, 0) + ISNULL(ts.zbnccphzje, 0)) AS 本年准产成品认购金额 ,
				SUM(ISNULL(hz.zbnccphzmj, 0) + ISNULL(ts.zbnccphzmj, 0)) AS 本年准产成品认购面积 ,
                SUM(ISNULL(hz.zbnccphzts, 0) + ISNULL(ts.zbnccphzts, 0)) AS 本年准产成品认购套数 ,

                SUM(ISNULL(hz.zbyccphzje, 0) + ISNULL(ts.zbyccphzje, 0)) AS 本月准产成品认购金额 ,
                SUM(ISNULL(hz.zbyccphzmj, 0) + ISNULL(ts.zbyccphzmj, 0)) AS 本月准产成品认购面积 ,              
				SUM(ISNULL(hz.zbyccphzts, 0) + ISNULL(ts.zbyccphzts, 0)) AS 本月准产成品认购套数 ,
                
				--SUM(ISNULL(hz.zbzccphzje, 0) + ISNULL(ts.zbzccphzje, 0)) AS 本周准产成品认购金额 ,
    -- 		    SUM(ISNULL(hz.zbzccphzmj, 0) + ISNULL(ts.zbzccphzmj, 0)) AS 本周准产成品认购面积 ,           
				--SUM(ISNULL(hz.zbzccphzts, 0) + ISNULL(ts.zbzccphzts, 0)) AS 本周准产成品认购套数 ,

                SUM(ISNULL(hz.zbrccphzje, 0) + ISNULL(ts.zbrccphzje, 0)) AS 本日准产成品认购金额 ,
                SUM(ISNULL(hz.zbrccphzmj, 0) + ISNULL(ts.zbrccphzmj, 0)) AS 本日准产成品认购面积 ,
                SUM(ISNULL(hz.zbrccphzts, 0) + ISNULL(ts.zbrccphzts, 0)) AS 本日准产成品认购套数 ,

                --准产成品-物业代销车位
                SUM(ISNULL(ts.zbnccphzje_wycwdx, 0)) AS 本年准产成品认购金额_物业车位代销 ,
				SUM(ISNULL(ts.zbnccphzmj_wycwdx, 0)) AS 本年准产成品认购面积_物业车位代销 ,
                SUM(ISNULL(ts.zbnccphzts_wycwdx, 0)) AS 本年准产成品认购套数_物业车位代销 ,

                SUM(ISNULL(ts.zbyccphzje_wycwdx, 0)) AS 本月准产成品认购金额_物业车位代销 ,
                SUM(ISNULL(ts.zbyccphzmj_wycwdx, 0)) AS 本月准产成品认购面积_物业车位代销 ,              
				SUM(ISNULL(ts.zbyccphzts_wycwdx, 0)) AS 本月准产成品认购套数_物业车位代销 ,  

				--SUM(ISNULL(ts.zbzccphzje_wycwdx, 0)) AS 本周准产成品认购金额_物业车位代销 ,
    -- 		    SUM(ISNULL(ts.zbzccphzmj_wycwdx, 0)) AS 本周准产成品认购面积_物业车位代销 ,           
				--SUM(ISNULL(ts.zbzccphzts_wycwdx, 0)) AS 本周准产成品认购套数_物业车位代销 ,

                SUM(ISNULL(ts.zbrccphzje_wycwdx, 0)) AS 本日准产成品认购金额_物业车位代销 ,
                SUM(ISNULL(ts.zbrccphzmj_wycwdx, 0)) AS 本日准产成品认购面积_物业车位代销 ,
                SUM(ISNULL(ts.zbrccphzts_wycwdx, 0)) AS 本日准产成品认购套数_物业车位代销
        INTO    #rg
        FROM    dbo.data_wide_dws_mdm_Project pj
        INNER JOIN #TopProduct pt ON pt.ParentProjGUID = pj.ProjGUID
        LEFT JOIN(SELECT    a.ProjGUID ,
                            ProductType AS TopProductTypeName ,
                            -- 产成品
                            SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  THEN   CCjTotal ELSE  0  END  ) AS bnccphzje ,                                                                                                                           --产成品本年认购金额
                            SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  THEN   CCjArea ELSE  0  END  ) AS  bnccphzmj ,
                            SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  THEN   CCjCount ELSE  0 END  ) AS  bnccphzts ,                                                                                                                           --产成品本年认购套数
                            SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND  MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjTotal ELSE 0 END) AS byccphzje ,                                                       --产成品本月认购金额
                            SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND  MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjArea ELSE 0 END) AS byccphzmj ,                                                        --产成品本月认购面积      
                            SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND  MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjCount ELSE 0 END) AS byccphzts ,                                                       --产成品本月认购套数

                            SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0 AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjTotal ELSE 0 END) AS brccphzje ,                                                   --产成品本日认购金额
                            SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0 AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS brccphzmj ,                                                    --产成品本日认购面积 
                            SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0 AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS brccphzts ,     

                            -- 准产成品
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) THEN   CCjTotal ELSE  0  END  )AS zbnccphzje ,                                                                                                                           --产成品本年认购金额
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) THEN   CCjArea ELSE  0  END  ) AS zbnccphzmj ,
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) THEN   CCjCount ELSE  0 END  ) AS zbnccphzts ,                                                                                                                           --产成品本年认购套数
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjTotal ELSE 0 END) AS zbyccphzje ,                                                       --产成品本月认购金额
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjArea ELSE 0 END) AS  zbyccphzmj ,                                                        --产成品本月认购面积      
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjCount ELSE 0 END) AS zbyccphzts ,                                                       --产成品本月认购套数

                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjTotal ELSE 0 END) AS zbrccphzje ,                                                   --产成品本日认购金额
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS  zbrccphzmj ,                                                    --产成品本日认购面积 
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS zbrccphzts ,  

                            SUM(CCjTotal) AS bnhzje ,                                                                                                                           -- 本年认购金额
                            SUM(CCjArea)  AS bnhzmj,                                                                                                                            -- 本年认购面积
                            SUM(CCjCount) AS bnhzts ,                                                                                                                           -- 本年认购套数

                            SUM(CASE WHEN MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjTotal ELSE 0 END) AS byhzje ,                                                       --本月认购金额
                            SUM(CASE WHEN MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjArea ELSE 0 END) AS byhzmj ,                                                        --本月认购面积
                            SUM(CASE WHEN MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjCount ELSE 0 END) AS byhzts ,                                                       --本月认购套数

                            SUM(CASE WHEN DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjTotal ELSE 0 END) AS brhzje ,                                                   --本日认购金额
                            SUM(CASE WHEN DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS brhzmj ,                                                    --本日认购面积
                            SUM(CASE WHEN DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS brhzts                                                     --本日认购套数
                    FROM  dbo.data_wide_s_NoControl a
                    INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = a.BldGUID 
                    WHERE StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(@var_date)) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(@var_date)) + '-12-31'
                    GROUP BY a.ProjGUID ,
                            ProductType
                ) hz ON hz.ProjGUID = pj.ProjGUID AND pt.TopProductTypeName = hz.TopProductTypeName
        LEFT JOIN(
                    --如果特殊业绩类型为“代销车位”则业绩金额在项目层级不用双算，在平衡处理上处理
                    SELECT s.ParentProjGUID AS projguid ,
                        bld.TopProductTypeName ,
                        --产成品
                        -- 本年认购套数
                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 
                            -- OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) )
                            THEN CCjAmount ELSE 0 END) AS bnccphzje ,    --产成品本年认购金额
                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 
                            -- OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) ) 
                            THEN CCjArea ELSE 0 END) AS bnccphzmj ,    --产成品本年认购面积
                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 
                            -- OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) ) 
                             THEN CCjCount ELSE 0 END) AS bnccphzts ,     --产成品本年认购套数
                        -- 本月认购套数
                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 
                            -- OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) ) 
                            THEN CCjAmount ELSE 0 END) AS byccphzje ,  -- 产成品本月认购金额
                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND  DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 
                            -- OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) ) 
                            THEN CCjArea ELSE 0 END) AS byccphzmj ,    -- 产成品本月认购面积 
                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 
                            -- OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) ) 
                            THEN CCjCount ELSE 0 END) AS byccphzts ,   --产成品本月认购套数
                                                                                                                                                                                       --产成品本周认购套数
                        --本日认购套数
                        SUM(CASE WHEN  DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 
                               -- OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) ) 
                             THEN CCjAmount ELSE 0 END) AS brccphzje ,     --产成品本日认购金额
                        SUM(CASE WHEN  DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 
                             -- OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) ) 
                             THEN CCjArea ELSE 0 END) AS brccphzmj ,       --产成品本日认购面积
                        SUM(CASE WHEN  DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0 AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 
                             -- OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) )  
                             THEN CCjCount ELSE 0 END) AS brccphzts ,      --产成品本日认购套数
                        
                        --准产成品
                        -- 本年认购套数
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL) )  
                                AND  ( DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 )
                               --OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) ) 
                            THEN CCjAmount ELSE 0 END) AS zbnccphzje ,    --准产成品本年认购金额
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  
                               AND  ( DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 )
                               --OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) ) 
                             THEN CCjArea ELSE 0 END) AS zbnccphzmj ,    --准产成品本年认购面积
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  
                             AND  ( DATEDIFF(YEAR, StatisticalDate, @var_date) = 0  )
                             --OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) ) 
                             THEN CCjCount ELSE 0 END) AS zbnccphzts ,     --准产成品本年认购套数
                        -- 本月认购套数
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  
                             AND  ( DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 )
                             -- OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) ) 
                             THEN CCjAmount ELSE 0 END) AS zbyccphzje ,  -- 准产成品本月认购金额
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  
                             AND  ( DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 )
                             --OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) ) 
                            THEN CCjArea ELSE 0 END) AS zbyccphzmj ,    -- 准产成品本月认购面积 
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  
                            AND  ( DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 )
                            -- OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) ) 
                            THEN CCjCount ELSE 0 END) AS zbyccphzts ,   --准产成品本月认购套数
                                                                                                                                                                                       --准产成品本周认购套数
                        --本日认购套数
                        SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  
                                AND ( DATEDIFF(DAY, StatisticalDate, @var_date) = 0 )
                                --OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) ) 
                             THEN CCjAmount ELSE 0 END) AS zbrccphzje ,     --准产成品本日认购金额
                        SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  
                               AND ( DATEDIFF(DAY, StatisticalDate, @var_date) = 0 )
                                -- OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) ) 
                             THEN CCjArea ELSE 0 END) AS zbrccphzmj ,       --准产成品本日认购面积
                        SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) 
                               AND ( DATEDIFF(DAY, StatisticalDate, @var_date) = 0 )
                               -- OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) )  
                            THEN CCjCount ELSE 0 END) AS zbrccphzts ,      --准产成品本日认购套数

                        --车位代销
                        SUM(CASE WHEN s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 THEN r.CjRmbTotal /10000.0 ELSE 0 END) AS bnhzje_wycwdx,    --本年物业公司车位代销认购金额
                        SUM(CASE WHEN s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS bnhzmj_wycwdx ,  --本年物业公司车位代销认购面积
                        SUM(CASE WHEN s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS bnhzts_wycwdx ,     --本年物业公司车位代销认购套数                                                                                                                          -- 本年认购套数
                        
                        SUM(CASE WHEN s.TsyjType = '物业公司车位代销' AND   DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 THEN r.CjRmbTotal /10000.0 ELSE 0 END) AS byhzje_wycwdx ,  -- 本月物业公司车位代销认购金额
                        SUM(CASE WHEN s.TsyjType = '物业公司车位代销' AND   DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS byhzmj_wycwdx ,  --本月物业公司车位代销认购面积
                        SUM(CASE WHEN s.TsyjType = '物业公司车位代销' AND   DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS byhzts_wycwdx ,   --本月物业公司车位代销认购套数

                       
                        SUM(CASE WHEN s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN r.CjRmbTotal /10000.0 ELSE 0 END) AS brhzje_wycwdx ,        --本日物业公司车位代销认购金额
                        SUM(CASE WHEN s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS brhzmj_wycwdx,   --本日物业公司车位代销认购面积
                        SUM(CASE WHEN s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS brhzts_wycwdx,   --本日物业公司车位代销认购套数
                        
                        --产成品车位代销
                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0 AND s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 THEN r.CjRmbTotal /10000.0 ELSE 0 END) AS bnccphzje_wycwdx,    --本年物业公司车位代销认购金额
                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0 AND s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS bnccphzmj_wycwdx ,  --本年物业公司车位代销认购面积
                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0 AND s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS bnccphzts_wycwdx ,     --本年物业公司车位代销认购套数                                                                                                                          -- 本年认购套数
                        
                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0 AND s.TsyjType = '物业公司车位代销' AND   DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 THEN r.CjRmbTotal /10000.0 ELSE 0 END) AS byccphzje_wycwdx ,  -- 本月物业公司车位代销认购金额
                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0 AND s.TsyjType = '物业公司车位代销' AND   DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS byccphzmj_wycwdx ,  --本月物业公司车位代销认购面积
                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0 AND s.TsyjType = '物业公司车位代销' AND   DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS byccphzts_wycwdx ,   --本月物业公司车位代销认购套数


                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0 AND s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN r.CjRmbTotal /10000.0 ELSE 0 END) AS brccphzje_wycwdx ,        --本日物业公司车位代销认购金额
                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0 AND s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS brccphzmj_wycwdx,   --本日物业公司车位代销认购面积
                        SUM(CASE WHEN DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0 AND s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS brccphzts_wycwdx,   --本日物业公司车位代销认购套数

                        --准成品车位代销
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 THEN r.CjRmbTotal /10000.0 ELSE 0 END) AS zbnccphzje_wycwdx,    --本年物业公司车位代销认购金额
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS zbnccphzmj_wycwdx ,  --本年物业公司车位代销认购面积
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS zbnccphzts_wycwdx ,     --本年物业公司车位代销认购套数                                                                                                                          -- 本年认购套数
                        
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND s.TsyjType = '物业公司车位代销' AND   DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 THEN r.CjRmbTotal /10000.0 ELSE 0 END) AS zbyccphzje_wycwdx ,  -- 本月物业公司车位代销认购金额
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND s.TsyjType = '物业公司车位代销' AND   DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS zbyccphzmj_wycwdx ,  --本月物业公司车位代销认购面积
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND s.TsyjType = '物业公司车位代销' AND   DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS zbyccphzts_wycwdx ,   --本月物业公司车位代销认购套数



                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN r.CjRmbTotal /10000.0 ELSE 0 END) AS zbrccphzje_wycwdx ,        --本日物业公司车位代销认购金额
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS zbrccphzmj_wycwdx,   --本日物业公司车位代销认购面积
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS zbrccphzts_wycwdx ,  --本日物业公司车位代销认购套数

                        --本年、本月、本周、本日
                        SUM(CASE WHEN DATEDIFF(YEAR, StatisticalDate, @var_date) = 0  and s.TsyjType <> '物业公司车位代销' THEN CCjAmount
                                    -- WHEN  (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) THEN r.CjRmbTotal /10000.0 
                            ELSE 0 END) AS bnhzje,    --本年认购金额
                        SUM(CASE WHEN DATEDIFF(YEAR, StatisticalDate, @var_date) = 0  and s.TsyjType <> '物业公司车位代销'
                             -- OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) 
                            THEN CCjArea ELSE 0 END) AS bnhzmj ,  --本年认购面积
                        SUM(CASE WHEN DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 and s.TsyjType <> '物业公司车位代销'
                            -- OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) 
                            THEN CCjCount ELSE 0 END) AS bnhzts ,     --本年认购套数                                                                                                                          -- 本年认购套数
                        
                        SUM(CASE WHEN DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 and s.TsyjType <> '物业公司车位代销' THEN CCjAmount
                              -- WHEN  (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH,StatisticalDate, @var_date) = 0) THEN r.CjRmbTotal /10000.0 
                            ELSE 0 END) AS byhzje ,  -- 本月认购金额
                        SUM(CASE WHEN DATEDIFF(MONTH, StatisticalDate, @var_date) = 0  and s.TsyjType <> '物业公司车位代销'
                            -- OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) 
                            THEN CCjArea ELSE 0 END) AS byhzmj ,  --本月认购面积
                        SUM(CASE WHEN DATEDIFF(MONTH, StatisticalDate, @var_date) = 0  and s.TsyjType <> '物业公司车位代销'
                            -- OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) 
                            THEN CCjCount ELSE 0 END) AS byhzts ,   --本月认购套数
                                                                                                                                                                 --本周认购面积                             
                                                                                                                                                                               --本周认购套数

                        SUM(CASE WHEN DATEDIFF(DAY, StatisticalDate, @var_date) = 0 and s.TsyjType <> '物业公司车位代销' THEN  CCjAmount
                                --WHEN  (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) 
                                --THEN r.CjRmbTotal /10000.0 
                             ELSE 0 END) AS brhzje ,        --本日认购金额
                        SUM(CASE WHEN DATEDIFF(DAY, StatisticalDate, @var_date) = 0 and s.TsyjType <> '物业公司车位代销' 
                               -- OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) 
                               THEN CCjArea ELSE 0 END) AS brhzmj,   --本日认购面积
                        SUM(CASE WHEN DATEDIFF(DAY, StatisticalDate, @var_date) = 0 and s.TsyjType <> '物业公司车位代销'
                               -- OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) 
                            THEN CCjCount ELSE 0 END) AS brhzts           --本日认购套数
                    FROM   dbo.data_wide_s_SpecialPerformance s
                    LEFT JOIN data_wide_s_RoomoVerride r ON s.roomguid = r.roomguid
                    INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = s.BldGUID
                    WHERE 1 = 1    --StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(@var_date)) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(@var_date)) + '-12-31'
                    GROUP BY s.ParentProjGUID ,
                            bld.TopProductTypeName
                ) ts ON ts.ProjGUID = pj.ProjGUID AND  pt.TopProductTypeName = ts.TopProductTypeName
        WHERE   pj.Level = 2
        GROUP BY pj.ProjGUID ,
                 pt.TopProductTypeName;

     --获取其他业绩签约金额，就是以客户提供的项目清单，其中特殊业绩房间认定日期在往年，但是签约日期在今年的房间	 
        CREATE TABLE [dbo].#qtyj ([项目推广名] [NVARCHAR](255) NULL ,
                                  [明源系统代码] [NVARCHAR](255) NULL ,
                                  [项目代码] [NVARCHAR](255) NULL ,
                                  [认定日期] DATETIME);

        -- INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        -- VALUES(N'佛山保利环球汇', N'0757046', N'2937', N'2020-8-31');

        INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        VALUES(N'佛山保利西山林语', N'0757056', N'2946', N'2022-5-27');

        -- INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        -- VALUES(N'佛山保利紫晨花园', N'0757059', N'2950', N'2022-6-28');

        -- INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        -- VALUES(N'佛山保利紫山国际', N'0757028', N'2920', N'2022-6-27');

        -- INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        -- VALUES(N'茂名保利大都会', N'HN0668001', N'5801', N'2021-12-28');

        -- INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        -- VALUES(N'茂名保利中环广场', N'0668005', N'5806', N'2021-4-26');
	    
		-- INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        -- VALUES(N'阳江保利海陵岛', N'yjKF002', N'1702', N'2021-5-24');
        --INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        --VALUES(N'阳江保利海陵岛', N'0662002', N'1702', N'2021-5-24');

    
        --查询其他业绩的签约金额
        --单独统计 物业公司车位代销 的业绩，用于后续剔除@20250707 edit by tangqn01
        SELECT  p.projguid ,
                bld.TopProductTypeName ,

                SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0   THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩本日认购金额 ,
                SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0  THEN r.CjBldArea ELSE 0 END) AS 其他业绩本日认购面积 ,
                SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0  THEN 1 ELSE 0 END) AS 其他业绩本日认购套数,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END)  AS 其他业绩本日认购金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩本日认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩本日认购套数_物业公司车位代销,

            

                SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and  DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩本月认购金额 ,
				SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and  DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩本月认购面积 ,
                SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and  DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩本月认购套数 ,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END)  AS 其他业绩本月认购金额_物业公司车位代销 ,
				SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩本月认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩本月认购套数_物业公司车位代销 ,

                SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and  YEAR(a.StatisticalDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩本年认购金额 ,
                SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and  YEAR(a.StatisticalDate) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩本年认购面积 ,
                SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and  YEAR(a.StatisticalDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩本年认购套数 ,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjAmount ELSE 0 END)  AS 其他业绩本年认购金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjArea ELSE 0 END) AS 其他业绩本年认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND YEAR(a.StatisticalDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩本年认购套数_物业公司车位代销 ,

                SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and  r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩本年签约金额 ,
				SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and  r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩本年签约面积 ,
                SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and  r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩本年签约套数 ,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjAmount ELSE 0 END)  AS 其他业绩本年签约金额_物业公司车位代销 ,
				SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjArea ELSE 0 END) AS 其他业绩本年签约面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩本年签约套数_物业公司车位代销 ,

                SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and  r.Status = '签约' AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩本月签约金额 ,
                SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and  r.Status = '签约' AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩本月签约面积,
                SUM(CASE WHEN a.TsyjType<> '物业公司车位代销' and  r.Status = '签约' AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩本月签约套数,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END) AS 其他业绩本月签约金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩本月签约面积_物业公司车位代销,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩本月签约套数_物业公司车位代销,    

                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END)  AS 其他业绩本日签约金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩本日签约面积,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩本日签约套数,   
              
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END)  AS 其他业绩本日签约金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩本日签约面积_物业公司车位代销,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩本日签约套数_物业公司车位代销,               

				-- 产成品
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(DAY, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩产成品本日认购金额 ,
			    SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(DAY, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩产成品本日认购面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(DAY, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩产成品本日认购套数 ,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END) AS 其他业绩产成品本日认购金额_物业公司车位代销 ,
			    SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩产成品本日认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩产成品本日认购套数_物业公司车位代销 ,



                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩产成品本月认购金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩产成品本月认购面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩产成品本月认购套数 ,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END)  AS 其他业绩产成品本月认购金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩产成品本月认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩产成品本月认购套数_物业公司车位代销 ,
                
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩产成品本年认购金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩产成品本年认购面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩产成品本年认购套数 ,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjAmount ELSE 0 END)  AS 其他业绩产成品本年认购金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjArea ELSE 0 END) AS 其他业绩产成品本年认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩产成品本年认购套数_物业公司车位代销 ,
                
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   r.Status = '签约' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩产成品本年签约金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   r.Status = '签约' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩产成品本年签约面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   r.Status = '签约' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩产成品本年签约套数 ,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjAmount ELSE 0 END)  AS 其他业绩产成品本年签约金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjArea ELSE 0 END) AS 其他业绩产成品本年签约面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩产成品本年签约套数_物业公司车位代销 ,
                
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   r.Status = '签约' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩产成品本月签约金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   r.Status = '签约' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩产成品本月签约面积,
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   r.Status = '签约' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩产成品本月签约套数,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END)  AS 其他业绩产成品本月签约金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩产成品本月签约面积_物业公司车位代销,
				SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND DATEDIFF(YEAR,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩产成品本月签约套数_物业公司车位代销,

                -- 准产成品 本年竣备以及本年预计竣备 PlanFinishDate
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(DAY, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩准产成品本日认购金额 ,
			    SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(DAY, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩准产成品本日认购面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(DAY, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩准产成品本日认购套数 ,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END)  AS 其他业绩准产成品本日认购金额_物业公司车位代销 ,
			    SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩准产成品本日认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩准产成品本日认购套数_物业公司车位代销 ,



                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩准产成品本月认购金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩准产成品本月认购面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩准产成品本月认购套数 ,
                
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END)  AS 其他业绩准产成品本月认购金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩准产成品本月认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩准产成品本月认购套数_物业公司车位代销 ,
                
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩准产成品本年认购金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩准产成品本年认购面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩准产成品本年认购套数 ,
                
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjAmount ELSE 0 END)  AS 其他业绩准产成品本年认购金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjArea ELSE 0 END) AS 其他业绩准产成品本年认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩准产成品本年认购套数_物业公司车位代销 ,

				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   r.Status = '签约' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩准产成品本年签约金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   r.Status = '签约' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩准产成品本年签约面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   r.Status = '签约' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩准产成品本年签约套数 ,
                
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjAmount ELSE 0 END)  AS 其他业绩准产成品本年签约金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjArea ELSE 0 END) AS 其他业绩准产成品本年签约面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩准产成品本年签约套数_物业公司车位代销 ,

				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   r.Status = '签约' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩准产成品本月签约金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   r.Status = '签约' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩准产成品本月签约面积,
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   r.Status = '签约' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩准产成品本月签约套数,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END)  AS 其他业绩准产成品本月签约金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩准产成品本月签约面积_物业公司车位代销,
				SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩准产成品本月签约套数_物业公司车位代销,

                -- 大户型
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(DAY, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩大户型本日认购金额 ,
			    SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(DAY, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩大户型本日认购面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND  bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(DAY, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩大户型本日认购套数 ,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END)  AS 其他业绩大户型本日认购金额_物业公司车位代销 ,
			    SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩大户型本日认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩大户型本日认购套数_物业公司车位代销 ,



                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩大户型本月认购金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩大户型本月认购面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩大户型本月认购套数 ,
                
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END)  AS 其他业绩大户型本月认购金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩大户型本月认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩大户型本月认购套数_物业公司车位代销 ,
               
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩大户型本年认购金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩大户型本年认购面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩大户型本年认购套数 ,
                
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjAmount ELSE 0 END) AS 其他业绩大户型本年认购金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjArea ELSE 0 END) AS 其他业绩大户型本年认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩大户型本年认购套数_物业公司车位代销 ,
               
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   r.Status = '签约' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩大户型本年签约金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   r.Status = '签约' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩大户型本年签约面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   r.Status = '签约' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩大户型本年签约套数 ,
                
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjAmount ELSE 0 END)  AS 其他业绩大户型本年签约金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjArea ELSE 0 END) AS 其他业绩大户型本年签约面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩大户型本年签约套数_物业公司车位代销 ,
               
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   r.Status = '签约' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩大户型本月签约金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   r.Status = '签约' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩大户型本月签约面积,
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   r.Status = '签约' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩大户型本月签约套数,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END) AS 其他业绩大户型本月签约金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩大户型本月签约面积_物业公司车位代销,
				SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩大户型本月签约套数_物业公司车位代销,


                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END) AS 其他业绩大户型本日签约金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩大户型本日签约面积_物业公司车位代销,
				SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩大户型本日签约套数_物业公司车位代销,
                -- 联动房
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   DATEDIFF(DAY, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩联动房本日认购金额 ,
			    SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   DATEDIFF(DAY, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩联动房本日认购面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   DATEDIFF(DAY, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩联动房本日认购套数 ,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END) AS 其他业绩联动房本日认购金额_物业公司车位代销 ,
			    SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩联动房本日认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩联动房本日认购套数_物业公司车位代销 ,



                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩联动房本月认购金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩联动房本月认购面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩联动房本月认购套数 ,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END)  AS 其他业绩联动房本月认购金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩联动房本月认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩联动房本月认购套数_物业公司车位代销 ,
                
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩联动房本年认购金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩联动房本年认购面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩联动房本年认购套数 ,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjAmount ELSE 0 END)  AS 其他业绩联动房本年认购金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjArea ELSE 0 END) AS 其他业绩联动房本年认购面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩联动房本年认购套数_物业公司车位代销 ,
                
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   r.Status = '签约' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩联动房本年签约金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   r.Status = '签约' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩联动房本年签约面积 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   r.Status = '签约' AND   YEAR(ISNULL(qt.认定日期,a.StatisticalDate)) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩联动房本年签约套数 ,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjAmount ELSE 0 END)  AS 其他业绩联动房本年签约金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN a.CCjArea ELSE 0 END) AS 其他业绩联动房本年签约面积_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   YEAR(a.StatisticalDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩联动房本年签约套数_物业公司车位代销 ,
                
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   r.Status = '签约' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩联动房本月签约金额 ,
                SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   r.Status = '签约' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩联动房本月签约面积,
				SUM(CASE WHEN a.TsyjType <>'物业公司车位代销' AND ldf.RoomGUID IS NOT NULL AND   r.Status = '签约' AND   DATEDIFF(MONTH, ISNULL(qt.认定日期,a.StatisticalDate), @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩联动房本月签约套数,

                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL  AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END) AS 其他业绩联动房本月签约金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL  AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩联动房本月签约面积_物业公司车位代销,
				SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL  AND   DATEDIFF(MONTH, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩联动房本月签约套数_物业公司车位代销,


                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL  AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjAmount ELSE 0 END)  AS 其他业绩联动房本日签约金额_物业公司车位代销 ,
                SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL  AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN a.CCjArea ELSE 0 END) AS 其他业绩联动房本日签约面积_物业公司车位代销,
				SUM(CASE WHEN a.TsyjType ='物业公司车位代销' AND ldf.RoomGUID IS NOT NULL  AND   DATEDIFF(DAY, a.StatisticalDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩联动房本日签约套数_物业公司车位代销
        INTO    #qtqy
        FROM    data_wide_s_SpecialPerformance a
        INNER JOIN data_wide_s_RoomoVerride r ON a.RoomGUID = r.RoomGUID
        INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = r.BldGUID
        INNER JOIN data_wide_dws_mdm_Project p ON a.ParentProjGUID = p.ProjGUID AND p.Level = 2
        LEFT JOIN #qtyj qt ON qt.明源系统代码 = p.ProjCode
        LEFT JOIN data_tb_hnyx_areasection mjd ON r.BldArea between mjd.开始面积 and mjd.截止面积 and mjd.业态 = bld.TopProductTypeName
        LEFT JOIN data_wide_s_LdfSaleDtl ldf on ldf.RoomGUID =r.RoomGUID
        -- 剔除过期的特殊业绩
        WHERE 1 = 1 and  a.SetGqAuditTime is null -- DATEDIFF(DAY, a.[StatisticalDate], qt.认定日期) = 0 AND 
            --r.Status IN ('认购', '签约')    -- AND YEAR(r.QsDate) = YEAR(@var_date)
        GROUP BY p.projguid ,
                 bld.TopProductTypeName;

-- 查询结果  
      select 
           tb.营销事业部 AS 区域 ,
				tb.营销片区 ,
				p.ProjGUID AS 项目GUID ,
				ISNULL(tb.推广名称, p.SpreadName) AS 项目名称 ,
	         pt.TopProductTypeName AS 产品类型 ,
				pt.TopProductTypeGUID AS 产品类型GUID ,
				tb.城市 ,
				tb.公司 ,
				tb.投管编码 ,
				tb.项目负责人,
                isnull(qt.其他业绩本年签约金额_物业公司车位代销,0) as 其他业绩本年签约金额_物业公司车位代销,
                isnull(qt.其他业绩本年签约套数_物业公司车位代销,0) as 其他业绩本年签约套数_物业公司车位代销,
                isnull(qt.其他业绩本年签约面积_物业公司车位代销,0) as 其他业绩本年签约面积_物业公司车位代销,


                isnull(qt.其他业绩本年签约金额,0) as 其他业绩本年签约金额,
                isnull(qt.其他业绩本年签约套数,0) as 其他业绩本年签约套数,
                isnull(qt.其他业绩本年签约面积,0) as 其他业绩本年签约面积,
                
				isnull(qt.其他业绩本年认购金额,0) as 其他业绩本年认购金额,
                isnull(qt.其他业绩本年认购套数,0) as 其他业绩本年认购套数,
                isnull(qt.其他业绩本年认购面积,0) as 其他业绩本年认购面积,
                isnull(rs.本年准产成品认购金额,0) as 本年准产成品认购金额,
     
                ISNULL(rs.本年认购金额, 0) + ISNULL(rg.本年认购金额, 0) + ISNULL(qt.其他业绩本年认购金额, 0) + ISNULL(rw.非项目本年实际认购金额, 0) AS 本年认购金额 ,
                ISNULL(rs.本年认购金额, 0)  as 其中正常操盘_本年认购金额,
                ISNULL(rg.本年认购金额, 0)  as 特殊合作业绩_本年认购金额,
                ISNULL(qt.其他业绩本年认购金额, 0)  as 其他业绩填报_本年认购金额,
                ISNULL(rw.非项目本年实际认购金额, 0) as 非项目_本年认购金额,
                        -- ISNULL(rs.本年认购套数, 0) + ISNULL(rg.本年认购套数, 0) + ISNULL(qt.其他业绩本年认购套数, 0) AS 本年认购套数 ,
                ISNULL(rs.本年认购面积, 0) + ISNULL(rg.本年认购面积, 0) + ISNULL(qt.其他业绩本年认购面积, 0) AS 本年认购面积,
                ISNULL(rs.本年认购面积, 0) as 其中正常操盘_本年认购面积,
                ISNULL(rg.本年认购面积, 0) as 特殊合作业绩_本年认购面积,
                ISNULL(qt.其他业绩本年认购面积, 0) AS 其他业绩填报_本年认购面积,

                ISNULL(qt.其他业绩本年签约金额,0) + ISNULL(qt.其他业绩本年签约金额_物业公司车位代销,0) -ISNULL(rw.非项目本年实际签约金额,0) AS 其他业绩本年签约金额 ,
                ISNULL(qt.其他业绩本年签约套数,0) + ISNULL(qt.其他业绩本年签约套数_物业公司车位代销,0)  AS 其他业绩本年签约套数 
		FROM    data_wide_dws_mdm_Project p
				INNER JOIN #TopProduct pt ON pt.ParentProjGUID = p.ProjGUID
				LEFT JOIN data_tb_hnyx_jdfxtb rw ON rw.projguid = p.ProjGUID AND   rw.业态 = pt.TopProductTypeName
				LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
				LEFT JOIN #rsale rs ON rs.ProjGUID = p.ProjGUID AND pt.TopProductTypeName = rs.TopProductTypeName
				LEFT JOIN #rg rg ON rg.ProjGUID = p.ProjGUID AND   pt.TopProductTypeName = rg.TopProductTypeName
				LEFT JOIN #qtqy qt ON qt.projguid = p.projguid AND pt.TopProductTypeName = qt.TopProductTypeName
		WHERE   Level = 2 AND   p.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'   -- and tb.投管编码 = '1703' --  
          and tb.投管编码 ='2926'  

--删除临时表
drop Table #rsale,#qtqy,#qtyj ,#rg ,#TopProduct



--- 
--获取各产品业态的签约金额
        SELECT  Sale.ParentProjGUID AS orgguid ,
                Sale.TopProductTypeName ,
--获取本年签约情况
                SUM(ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)) / 10000 AS 本年签约金额全口径 ,
                SUM(ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)) AS 本年签约面积全口径 ,
                SUM(ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)) AS 本年签约套数全口径 

                SUM(CASE WHEN  (DATEDIFF(YEAR,pb.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,pb.PlanFinishDate,@var_date) = 0 AND pb.FactFinishDate IS NULL))  
                     THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                         ELSE 0
                    END) / 10000 本年准产成品签约金额全口径 ,
               
       --  INTO    #projsale
        FROM    dbo.data_wide_dws_s_SalesPerf Sale
        INNER JOIN data_wide_dws_mdm_Project pj ON pj.ProjGUID = Sale.ParentProjGUID
        LEFT JOIN data_wide_dws_s_Dimension_Organization do ON do.OrgGUID = pj.XMSSCSGSGUID AND do.ParentOrganizationGUID = pj.BUGUID
        LEFT JOIN data_wide_dws_s_Dimension_Organization do1 ON do1.OrgGUID = do.ParentOrganizationGUID
        LEFT JOIN data_wide_dws_mdm_Building pb ON Sale.GCBldGUID = pb.BuildingGUID AND pb.BldType = '工程楼栋'
        WHERE   Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(getdate())) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(getdate())) + '-12-31'
        and pj.ProjGUID ='7F0A49DA-5A96-E911-80B7-0A94EF7517DD'
        GROUP BY Sale.ParentProjGUID ,
                 Sale.TopProductTypeName;