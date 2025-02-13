SELECT * FROM (
    SELECT 
        FbfzInfoGUID,
        cb_FbfzInfo.ProjGUID,
        ZbdImage,
        YsImage,
        ApproveState,
        cb_FbfzInfo.VersionName,
        JbrGUID,
        JbrName,
        CreateTime,
        ApprovedBy,
        ApproveDate,
        P_Project.ProjName,
        P_Project.ProjCode AS ProjectCode
    FROM cb_FbfzInfo
    LEFT JOIN P_Project 
        ON cb_FbfzInfo.ProjGUID = P_Project.ProjGUID
) cb_FbfzInfo 
WHERE (1=1)  AND (2=2)

-- 1、获取时间：取系统项目获取时间
-- 2、开工时间：发起审批时手填
-- 3、总建面：取基础数据系统分期总建面
-- 4、地上建面：取基础数据系统分期地上面积
-- 5总包标段个数、施工证个数、验收批次个数：取审批页面中相关内容


   -- 获取最新已审核的项目信息

--    select p_Project.ProjName as '项目分期'
-- ,cb_FbfzInfo.VersionName as '版本'
-- ,cb_FbfzInfo.JbrName as '经办人' 
-- from cb_FbfzInfo inner join p_Project on cb_FbfzInfo.ProjGUID=p_Project.ProjGUID
-- WHERE cb_FbfzInfo.FbfzInfoGUID= [业务GUID]


-- 湖北公司-一期-工程策划审批-0006

 SELECT 
        Fbfz.FbfzInfoGUID as [工程策划GUID],
        Fbfz.VersionName as [版本],
        Fbfz.JbrName as [经办人],
        isnull(pp.ProjName,'') + '-' + mp.ProjName as [项目分期],
        mp.AcquisitionDate as [获取时间],
        mp.SumBuildArea as [总建面],
        mp.SumDownArea as [地下建面],
        mp.SumUpArea as [地上建面],
        bd.BdCount as [总包标段个数],
        sgz.sgzcount as [施工证个数],
        sgz.YsBatchCount as [验收批次个数]
    FROM cb_FbfzInfo Fbfz
        INNER JOIN
        (
            SELECT ProjGUID,
			       ParentProjGUID,
                   ProjName,
                   ProjCode,
                   AcquisitionDate,
                   SumUpArea,
                   SumDownArea, 
                   SumBuildArea,
                   SumJrArea,
                   SumSaleArea
            FROM 
            (
                SELECT ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) AS rowmo,
                       *
                FROM dbo.md_Project
                WHERE ApproveState = '已审核'
                      AND Level = 3
                      AND ISNULL(CreateReason, '') <> '补录'
            ) x
            WHERE x.rowmo = 1
        ) mp  ON mp.ProjGUID = Fbfz.ProjGUID
		left join p_Project  pp on pp.ProjGUID =mp.ParentProjGUID and  pp.Level =2
        LEFT JOIN
        (
            SELECT FbfzInfoGUID,
                   SUM(ISNULL(BdCount, 0)) AS BdCount 
            FROM cb_FbfzInfo2Bdhf
            where  ContractType ='施工总承包工程'
            GROUP BY FbfzInfoGUID
        ) bd
            ON bd.FbfzInfoGUID = Fbfz.FbfzInfoGUID
        LEFT JOIN
        (
            SELECT FbfzInfoGUID,
                   COUNT(DISTINCT SgzName) AS sgzcount, 
                   COUNT(YsBatch) AS YsBatchCount 
            FROM cb_FbfzInfo2Sgz
            WHERE IsEnd = 1
            GROUP BY FbfzInfoGUID
        ) sgz
            ON sgz.FbfzInfoGUID = Fbfz.FbfzInfoGUID
    WHERE Fbfz.FbfzInfoGUID =  [业务GUID]
   -- WHERE Fbfz.FbfzInfoGUID = '6B845FAB-1FB0-4F3A-A71C-411975A5C446'