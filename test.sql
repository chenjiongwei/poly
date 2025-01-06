
--统计住宅类交付情况，需要获取缴清合同最后一个实收款日期
--缓存房间信息
select a.RoomGUID,c.ContractGUID,BlRhDate ,TradeGUID,r.Status,DeliveryBatchDate,c.JFDate,k.DeliveryBatchGUID
into #room
from s_YearJLPlanRoom a
  INNER  JOIN dbo.ep_room r ON a.roomguid=r.roomguid
  INNER JOIN s_YearJLPlan y ON a.YearJLPlanGUID=y.YearJLPlanGUID
  INNER JOIN k_DeliveryBatch k ON r.ProjGUID = k.ProjGUID
  AND k.DeliveryBatchName = REPLACE(r.DeliveryBatch , '?' , '·')
  LEFT JOIN s_Contract c ON r.RoomGUID = c.RoomGUID AND c.Status = '激活'
  where y.ProductType='住宅类（住宅、高层住宅、高级住宅）'
  
SELECT * 
INTO #LAST
FROM (SELECT ROW_NUMBER() OVER (PARTITION BY r.ContractGUID
                             ORDER BY s.CreatedOn DESC, g.GetDate DESC) AS id,
          r.ContractGUID,
          r.roomguid,
          g.GetDate
FROM #room r
LEFT JOIN dbo.s_Getin g ON g.SaleGUID = r.TradeGUID
LEFT JOIN dbo.s_Voucher s ON g.VouchGUID = s.VouchGUID
WHERE 1=1
AND s.YwType NOT IN ('诚意金转定金' ,  '换房转账') AND s.VouchType <> '换票单' 
AND r.RoomGUID IN (SELECT RoomGUID FROM dbo.s_Contract tr WHERE tr.Status = '激活' AND NOT EXISTS
  (SELECT 1 FROM s_Fee fe WHERE tr.TradeGUID = fe.TradeGUID 
   --AND ((ItemType IN ( '非贷款类房款' ,'贷款类房款')
   --AND ItemName <> '房款补差款')   OR (ItemType = '其它' AND ItemName = '滞纳金'))  
   AND RmbYe > 0))) s 
WHERE s.id=1 

SELECT r.DeliveryBatchGUID,
         sum(CASE WHEN DATEDIFF(DAY, r.DeliveryBatchDate, l.GetDate) < 30 THEN 1 ELSE 0 END) PlanKFCountMonth_ZZ,
         sum(CASE WHEN DATEDIFF(DAY, r.DeliveryBatchDate, l.GetDate) < 30
             AND r.BlRhDate IS NOT NULL
             AND datediff(DAY,r.JFDate,r.BlRhDate) <= 30 THEN 1 ELSE 0 END) RealJFCountMonth_ZZ,
         sum(CASE WHEN l.GETDATE < getdate() THEN 1 ELSE 0 END) PlanKFCount_ZZ,
         sum(CASE WHEN l.GETDATE < getdate()
             AND r.BlRhDate IS NOT NULL THEN 1 ELSE 0 END) RealJFCount_ZZ 
			 into #zz
FROM #room r
LEFT JOIN #LAST l ON r.roomguid=l.roomguid
group by r.DeliveryBatchGUID

--合并最后结果
select 
BUGUID
,YearJLPlanGUID
,p.DeliveryBatchGUID
,p.YearJLPlanCode
,ProjName
,PlanYFDate
,PlanJFDate
,CASE WHEN PlanKFCount = 0 THEN ISNULL(PlanKFCountHand, 0)
             ELSE PlanKFCount
         END AS PlanKFCount --若没有数据就取手填数
,RealJFPCName
,RealJFStartDate
,case when (select count(1) from s_Contract sc
inner join p_room p on sc.RoomGUID = p.RoomGUID
where sc.Status = '激活'
and QRSDate is not null
and p.DeliveryBatch =c.DeliveryBatchName)=0 then hz.RealJFCount else (select count(1) from s_Contract sc
inner join p_room p on sc.RoomGUID = p.RoomGUID
where sc.Status = '激活'
and QRSDate is not null
and p.DeliveryBatch =c.DeliveryBatchName) end RealJFCount
,CreateBy
,CreateDate
,RContent
,p.ProjGUID
,PlanKFCountHand
,ProductType
,SelBldGUIDS
,IsPushYfw --是否推送云服务
,case when hz.YearJLPlanCode is null then '否' else '是' end ishzyjlr --合作业绩录入还是非合作业绩录入
,c.DeliveryBatchCode
,c.DeliveryBatchDate
,c.DeliveryBatchName
,c.DeliveryBatchRange
,PlanKFCountMonth_ZZ -- 住宅类一个月应交户数
,RealJFCountMonth_ZZ --住宅类一个月实际交付户数
,PlanKFCount_ZZ--住宅类实际应交户数，
,RealJFCount_ZZ --住宅类实际交付户数
from s_YearJLPlan p
LEFT JOIN k_DeliveryBatch C ON p.DeliveryBatchGUID = C.DeliveryBatchGUID
left join #zz zz on c.DeliveryBatchGUID = zz.DeliveryBatchGUID
left join (--获取合作项目的填报情况
select YearJLPlanCode,RealJFCount,k.projguid
from k_HZXMJFLR k) hz on hz.YearJLPlanCode = p.YearJLPlanCode and hz.projguid = p.projguid

--where YearJLPlanCode not in (select YearJLPlanCode from k_HZXMJFLR ) --存在部分合作项目建了房间之后引用年度交付计划的情况，这部分需要统计上

