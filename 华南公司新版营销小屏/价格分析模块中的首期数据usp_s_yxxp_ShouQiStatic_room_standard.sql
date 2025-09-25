USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_yxxp_ShouQiStatic_room_standard]    Script Date: 2025/8/20 14:12:48 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- [usp_s_yxxp_ShouQiStatic_room_standard] '2025-08-20'

ALTER proc [dbo].[usp_s_yxxp_ShouQiStatic_room_standard] (@var_date DATETIME)as
/*
用途：用于统计华南营销小屏价格分析模块中首期数据
author:ltx
date:20210913
[usp_s_yxxp_ShouQiStatic_room_standard] '2022-05-30'
修改首付分期时长以付款定义为准 ——lintx 20210913
*/
begin
--正常房间签约 
SELECT so.BUGUID,so.ProjGUID,
       r.bldguid,
       r.roomguid,
       so.QSDate,
       r.ProductType,
	   ISNULL(sc_total.payformname,so.payformname) AS payformname,
       SUM(sf.Amount) AS 首期分期,
	   --COUNT(sf.ItemName) AS 首期分期个数,
	   SUM(CASE WHEN sf.ItemName LIKE '%首期%' THEN 1 ELSE 0 END ) AS 首期分期个数,
	   SUM(ISNULL(sc_total.RmbHtTotal,so.RmbCjTotal)) 合同金额
INTO #standard_qy
FROM [172.16.4.141].ERP25.dbo.s_Order so WITH(NOLOCK)
    INNER JOIN [172.16.4.141].ERP25.dbo.s_Fee sf WITH(NOLOCK)
        ON sf.TradeGUID = so.TradeGUID
    LEFT JOIN [172.16.4.141].ERP25.dbo.s_Contract sc WITH(NOLOCK)
        ON so.TradeGUID = sc.TradeGUID
           AND sc.CloseReason = '换房'
	LEFT JOIN [172.16.4.141].ERP25.dbo.s_Contract sc_total WITH(NOLOCK) ON so.TradeGUID = sc_total.TradeGUID AND sc_total.status = '激活'
    INNER JOIN [172.16.4.141].ERP25.dbo.ep_room r WITH(NOLOCK)
        ON r.RoomGUID = so.RoomGUID
WHERE DATEDIFF(yy, so.QSDate, @var_date) = 0
      AND sc.ContractGUID IS NULL
      AND
      (
          so.Status = '激活'
          OR
          (  so.CloseReason = '转签约'
			  AND sc_total.status = '激活'
           )
      )
      AND so.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
       AND (ItemName LIKE '%首期%' OR so.TradeGUID NOT IN (SELECT DISTINCT TradeGUID FROM [172.16.4.141].ERP25.dbo.s_Fee WITH(NOLOCK) WHERE ItemName LIKE '%首期%' ) 
	  )
GROUP BY so.ProjGUID,
         r.bldguid,
         so.QSDate,
         r.roomguid,
         r.ProductType,so.BUGUID,
		 ISNULL(sc_total.payformname,so.payformname) 
UNION ALL
--统计退房或者是直接签约部分 
SELECT sc.BUGUID,sc.ProjGUID,
       r.bldguid,
       r.roomguid,
       sc.QSDate,
       r.ProductType,
	   sc.payformname,
       SUM(sf.Amount) AS 首期分期,
	  SUM(CASE WHEN sf.ItemName LIKE '%首期%' THEN 1 ELSE 0 END ) AS 首期分期个数,
	   SUM(ISNULL(sc.RmbHtTotal,0)) 合同金额
FROM [172.16.4.141].ERP25.dbo.s_Contract sc WITH(NOLOCK)
    LEFT JOIN [172.16.4.141].ERP25.dbo.s_Order so
        ON sc.TradeGUID = so.TradeGUID
    INNER JOIN [172.16.4.141].ERP25.dbo.s_Fee sf WITH(NOLOCK)
        ON sf.TradeGUID = so.TradeGUID
    INNER JOIN [172.16.4.141].ERP25.dbo.ep_room r WITH(NOLOCK)
        ON r.RoomGUID = so.RoomGUID
WHERE so.TradeGUID IS NULL
      AND sc.Status = '激活'
      AND DATEDIFF(yy, sc.QSDate, @var_date) = 0
      AND sc.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
      AND (sf.ItemName LIKE '%首期%' OR sc.TradeGUID NOT IN (SELECT DISTINCT TradeGUID FROM [172.16.4.141].ERP25.dbo.s_Fee WITH(NOLOCK) WHERE ItemName LIKE '%首期%' ) 
	  )
GROUP BY sc.ProjGUID,sc.BUGUID,
         r.bldguid,
         sc.QSDate,
         r.roomguid,
         r.ProductType,
		 sc.payformname;
 
--SELECT * FROM #standard_qy WHERE RoomGUID = '1B425A55-0581-4316-A8AD-B6EA9CA4F0C8'
 
--付款方式名称，取对应的首付分期时长
SELECT pj.ProjGUID,sp.PayformName,bld.bldguid,
CASE WHEN MAX(dtl.ItemName) NOT LIKE '%首期%' THEN 0 ELSE (
CASE when  MAX(dtl.ActiMonth)=0 then MAX(dtl.ActiDays) ELSE MAX(dtl.ActiMonth)*30 END) END  AS 首期分期时长
INTO #standard_payform
FROM [172.16.4.141].ERP25.dbo.s_PayForm sp WITH(NOLOCK)
    INNER JOIN [172.16.4.141].ERP25.dbo.s_PayDetail dtl WITH(NOLOCK)
        ON sp.PayFormGUID = dtl.PayFormGUID
    INNER JOIN [172.16.4.141].ERP25.dbo.mdm_Project pj WITH(NOLOCK)
        ON pj.ProjGUID = sp.ProjGUID
	LEFT JOIN [172.16.4.141].ERP25.dbo.s_Payform2Bld bld WITH(NOLOCK) ON bld.PayformGUID = sp.PayFormGUID
WHERE  (dtl.ItemName LIKE '%首期%' OR sp.PayFormGUID NOT IN (SELECT DISTINCT PayFormGUID FROM [172.16.4.141].ERP25.dbo.s_PayDetail WITH(NOLOCK) WHERE ItemName LIKE '%首期%' ) 
	  )
      AND pj.DevelopmentCompanyGUID = 'AADC0FA7-9546-49C9-B64B-825056C828ED'
	  AND GETDATE() BETWEEN BgnDate AND EndDate
	  AND pj.ApprovedStatus = '已审核'
	  GROUP BY pj.ProjGUID,sp.PayformName,bld.bldguid;

--select * from #standard_payform where payformname = '首付分期付款（3个月）' and projguid = '595A223D-6E6D-E811-80BF-E61F13C57837'

--合并签约及付款方式
--按楼栋粒度设置付款方式的数据

SELECT qy.*,pay.首期分期时长
INTO #standard_res
FROM #standard_qy qy WITH(NOLOCK)
INNER JOIN #standard_payform pay WITH(NOLOCK) ON qy.projguid = pay.projguid AND qy.bldguid = pay.bldguid AND qy.payformname = pay.payformname
WHERE pay.bldguid IS NOT NULL  
UNION ALL 
SELECT qy.*,pay.首期分期时长 
FROM #standard_qy qy WITH(NOLOCK)
INNER JOIN #standard_payform pay  WITH(NOLOCK) ON qy.projguid = pay.projguid  AND qy.payformname = pay.payformname
WHERE pay.bldguid IS  NULL  
 

--处理结果数据
--公司信息 、营销片区信息、项目信息、年度情况、月度情况 
SELECT pj.BUGUID AS 公司GUID,
       do.OrganizationName AS 公司名称,
	  
       pj.City AS 城市,
       
       pa.ProjGUID AS 项目guid,
       pa.SpreadName AS 项目推广名,
       pj.ProjGUID AS 分期guid,
       pj.SpreadName AS 分期名称,
	   b.SaleBldName 楼栋名称,
	   qy.RoomGUID,
	   r.RoomInfo 房间信息,
       case when qy.ProductType in ('住宅','别墅','公寓','写字楼','商业') then qy.ProductType when qy.producttype = '地下室/车库' then '车位'
	   WHEN qy.producttype = '企业会所' then '商业'
	   else '其他' end 业态,
       qy.bldguid,
       CASE
           WHEN qy.首期分期个数 = 1 THEN
               '无分期'
           WHEN qy.首期分期时长 / 30 < 1 THEN
               '无分期'
           ELSE
               CONVERT(VARCHAR(100), qy.首期分期时长 / 30) + '个月'
       END AS 年度首期时长,
       SUM(qy.首期分期) AS 年度首期分期,
       COUNT(DISTINCT qy.RoomGUID) AS 年度认购套数,
       CASE
           WHEN DATEDIFF(mm, qy.qsdate, @var_date) = 0 THEN
       (CASE
            WHEN qy.首期分期个数 = 1 THEN
                '无分期'
            WHEN qy.首期分期时长 / 30 < 1 THEN
                '无分期'
            ELSE
                CONVERT(VARCHAR(100), qy.首期分期时长 / 30) + '个月'
        END
       )
           ELSE
               '无'
       END AS 月度首期时长,
       SUM(   CASE
                  WHEN DATEDIFF(mm, qy.qsdate, @var_date) = 0 THEN
                      qy.首期分期
                  ELSE
                      0
              END
          ) AS 月度首期分期,
       SUM(   CASE
                  WHEN DATEDIFF(mm, qy.qsdate, @var_date) = 0 THEN
                      1
                  ELSE
                      0
              END
          ) AS 月度认购套数,
		  SUM(qy.合同金额)房间成交总价
		  ,qy.payformname 首付分期类型,@var_date AS qxdate,qy.qsdate
		  into #standard_s_hnyxxp_ShouQiStatic_room
FROM #standard_res qy WITH(NOLOCK)
    INNER JOIN dbo.data_wide_dws_mdm_Project pj WITH(NOLOCK)
        ON qy.ProjGUID = pj.ProjGUID
    INNER JOIN data_wide_dws_mdm_project pa WITH(NOLOCK)
        ON pj.ParentGUID = pa.ProjGUID
	LEFT JOIN dbo.data_wide_dws_mdm_Building b WITH(NOLOCK) ON b.BuildingGUID=qy.BldGUID
    INNER JOIN dbo.data_wide_dws_s_Dimension_Organization do WITH(NOLOCK)
        ON do.OrgGUID = pj.BUGUID 
    LEFT JOIN dbo.data_wide_s_RoomoVerride r WITH(NOLOCK) ON r.RoomGUID=qy.RoomGUID
WHERE pj.BUGUID='70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
GROUP BY pj.BUGUID,
         do.OrganizationName,
		 qy.payformname,b.SaleBldName,
         pj.City,
         pj.ProjGUID,
         pj.SpreadName,
         case when qy.ProductType in ('住宅','别墅','公寓','写字楼','商业') then qy.ProductType when qy.producttype = '地下室/车库' then '车位'
	   WHEN qy.producttype = '企业会所' then '商业'
	   else '其他' end ,
         qy.bldguid,  
         pa.ProjGUID,
         pa.SpreadName,
		 qy.RoomGUID,r.RoomInfo,qy.QSDate,
         CASE
             WHEN qy.首期分期个数 = 1 THEN
                 '无分期'
             WHEN qy.首期分期时长 / 30 < 1 THEN
                 '无分期'
             ELSE
                 CONVERT(VARCHAR(100), qy.首期分期时长 / 30) + '个月'
         END,
         CASE
             WHEN DATEDIFF(mm, qy.qsdate, @var_date) = 0 THEN
         (CASE
              WHEN qy.首期分期个数 = 1 THEN
                  '无分期'
              WHEN qy.首期分期时长 / 30 < 1 THEN
                  '无分期'
              ELSE
                  CONVERT(VARCHAR(100), qy.首期分期时长 / 30) + '个月'
          END
         )
             ELSE
                 '无'
         END;
    --插入正式表
    delete from s_yxxp_ShouQiStatic_room_standard WHERE 1=1
    insert into s_yxxp_ShouQiStatic_room_standard
    select * from #standard_s_hnyxxp_ShouQiStatic_room WITH(NOLOCK);

    select * from s_yxxp_ShouQiStatic_room_standard WITH(NOLOCK) WHERE DATEDIFF(dd,qxdate,@var_date)=0;

    DROP TABLE #standard_qy,#standard_s_hnyxxp_ShouQiStatic_room,#standard_payform,#standard_res;

end;
 

