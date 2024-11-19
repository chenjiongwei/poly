-- 统计各楼栋的去化率
SELECT  t.* ,
       -- CASE WHEN 已推套数 = 0 THEN 0 ELSE 已售套数 * 1.0 / 已推套数 END AS 去化率
	   CASE WHEN  ISNULL(总货值套数,0) =0  THEN 0  ELSE  ISNULL(已售套数,0) *1.0 / ISNULL(总货值套数,0) END  AS 去化率,
	   CASE WHEN  ISNULL(纯住宅总货值套数,0) =0  THEN 0  ELSE  ISNULL(纯住宅已售套数,0) *1.0 / ISNULL(纯住宅总货值套数,0) END  AS 纯住宅去化率
INTO    #hxqhl
FROM(SELECT a.gcbldguid ,
            SUM(ISNULL(总货值套数, 0)) AS 总货值套数 ,
            SUM(ISNULL(已售套数, 0)) AS 已售套数 ,
            SUM(ISNULL(未完工_已推未售套数, 0) + ISNULL(已完工_已推未售套数, 0) + ISNULL(已售套数, 0)) 已推套数,
			sum(case when  topproductname in ('住宅','高级住宅') then isnull(总货值套数,0) else  0 end) as 纯住宅总货值套数,
			sum(case when  topproductname in ('住宅','高级住宅') then isnull(已售套数,0) else  0 end) as 纯住宅已售套数
     FROM   data_wide_dws_jh_LdHzOverview a
            INNER JOIN data_wide_dws_mdm_Building b ON a.BuildingGUID = b.BuildingGUID AND  b.BldType = '产品楼栋'
     GROUP BY a.gcbldguid) t;


--取项目最新版的户型配比图
SELECT  t.PorjectTotalPicGUID,t.ParentGUID,t.ProjGUID
INTO    #propic
FROM(SELECT t.* ,
            RANK() OVER (PARTITION BY isnull(t.ParentGUID,t.ProjGUID) ORDER BY t.flag) AS flagnum
     FROM   (SELECT pj.ParentGUID,
	                isnull(a.projguid,pj.ProjGUID) as  ProjGUID ,
                    PorjectTotalPicGUID ,
                    CASE WHEN ProjectTotalPicType LIKE '%修详规版%' THEN 3  WHEN  ProjectTotalPicType ='项目户型配比图' then  1   WHEN ProjectTotalPicType LIKE '%定位版%' THEN 2 ELSE 4 END AS flag
             FROM   data_wide_mdm_PorjectTotalPic a
                    INNER JOIN dbo.data_wide_dws_mdm_Project pj ON (a.ProjGUID = pj.ProjGUID or  a.ProjGUID = pj.ParentGUID) 
             WHERE ProjectTotalPicType LIKE '%户型配比图%' AND  ProjectTotalPicType NOT LIKE '%历史版本%') t ) t
WHERE   t.flagnum = 1   


--统计楼栋去化率
SELECT  distinct 
        isnull(a.ParentProjGUID,a.ProjGUID) as 项目GUID ,
        --ISNULL(pic.ParentGUID, pic.ProjGUID) as 项目GUID,
        a.ProjectTotalPicType 总图类型 ,
        a.BldOrderNo 锚点排序 ,
        REPLACE(a.picouturl, '"IsShowBldPoint":"0"', '"IsShowBldPoint":"1"') 图片信息 ,
        a.PorjectTotalPicCode 总图类型排序 ,
        a.bldguid 楼栋GUID ,
        a.PosJosn 锚点信息 ,
        CONVERT(VARCHAR(20), CONVERT(DECIMAL(18, 2), a.BuildArea / 10000.0)) + '万㎡' AS 建筑面积 ,
        a.BldGUID AS 工程楼栋GUID ,
        a.BldName AS 工程楼栋名称 ,
        CONVERT(VARCHAR(20), b.总货值套数) + '套' AS 总货值套数 ,
        CONVERT(VARCHAR(20), b.已推套数) + '套' AS 已推套数 ,
        CONVERT(VARCHAR(20), b.已售套数) + '套' AS 已售套数 ,
	    CONVERT(VARCHAR(20), b.纯住宅总货值套数) + '套' AS 纯住宅总货值套数 ,
        CONVERT(VARCHAR(20), b.纯住宅已售套数) + '套' AS 纯住宅已售套数 ,
        b.去化率 ,
		b.纯住宅去化率,
        CASE WHEN ISNULL(b.去化率, 0) >= 0.15 AND  ISNULL(b.去化率, 0) < 0.25 THEN '绿色预警'
             WHEN ISNULL(b.去化率, 0) >= 0.25 AND  ISNULL(b.去化率, 0) < 0.5 THEN '黄色预警'
             WHEN ISNULL(b.去化率, 0) >= 0.5 AND   ISNULL(b.去化率, 0) < 0.9 THEN '蓝色预警'
             WHEN ISNULL(b.去化率, 0) >= 0.9 THEN '红色预警'
             WHEN ISNULL(b.去化率, 0) < 0.15 THEN '灰色预警'
        END AS 去化率预警 ,
        CONVERT(VARCHAR(20), CONVERT(DECIMAL(18, 2), ISNULL(b.去化率, 0) * 100)) + '%' AS 楼栋综合去化率 ,
		CONVERT(VARCHAR(20), CONVERT(DECIMAL(18, 2), ISNULL(b.纯住宅去化率, 0) * 100)) + '%' AS 楼栋纯住宅去化率 ,
        CASE WHEN ldsc.ldscrgdate = '2099-12-31' THEN NULL ELSE ldsc.ldscrgdate END AS 楼栋首次认购时间 ,
        NULL 查看详情 ,
        gc.buildingname AS 工程楼栋名称_楼栋表
FROM    data_wide_dws_mdm_ProjTotalPic2Bld a
        INNER JOIN #propic pic ON pic.PorjectTotalPicGUID = a.PorjectTotalPicGUID
        LEFT JOIN #hxqhl b ON a.BldGUID = b.gcbldguid
        LEFT JOIN(SELECT    gcbldguid ,
                            MIN(ISNULL(ldscrgdate_hhzts, '2099-12-31')) AS ldscrgdate
                  FROM  data_wide_dws_mdm_building pb
                  WHERE pb.bldtype = '产品楼栋'
                  GROUP BY gcbldguid) ldsc ON ldsc.gcbldguid = a.BldGUID
        --为了通过工程楼栋名称穿透，统一用楼栋宽表的工程楼栋名称
        LEFT JOIN data_wide_dws_mdm_building gc ON gc.buildingguid = a.bldguid AND gc.bldtype = '工程楼栋'
WHERE  (  pic.ParentGUID =${projguid} and  not exists ( select 1 from #propic where  projguid =${projguid} )  )
     or  ( pic.ProjGUID =${projguid}   and  exists ( select 1 from #propic where  projguid =${projguid} ) ) 
-- isnull(pic.ProjGUID , pic.ParentGUID) = ${projguid}
-- isnull( pic.ParentGUID,pic.ProjGUID ) = ${projguid}
--删除临时表
DROP TABLE #hxqhl ,
           #propic;
