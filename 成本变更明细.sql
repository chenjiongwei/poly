SELECT 
    org.清洗时间id,
    org.清洗时间,
    org.项目guid,
    org.项目名称,
    org.组织架构类型,
    org.组织架构名称 as 业态,
	lxdw.立项总建筑面积,
	lxdw.立项总投资建筑单方 as 立项建筑单方,
	lxdw.定位总建筑面积 as 定位总建筑面积,
	lxdw.定位总投资,
	case when  isnull(lxdw.定位总建筑面积,0) =0  then  0  else   isnull(lxdw.定位总投资,0) / isnull(lxdw.定位总建筑面积,0)*10000.0 end  as 定位建筑单方,
    null as 车位分摊口径,
    --综合单方_不含税等于：营业成本单方+营销费用单方+综合管理费单方+税金单方
    isnull(lr.盈利规划营业成本单方,0) + isnull(lr.盈利规划营销费用单方,0) + isnull(lr.盈利规划综合管理费单方,0) + isnull(盈利规划税金及附加单方,0) as 综合单方_不含税, 
    lr.盈利规划营业成本单方 as 营业成本单方,  
    lr.盈利规划土地款单方 as 土地款单方,
    lr.盈利规划除地价外直投单方 as 除地价外直投单方,
    lr.盈利规划开发间接费单方 as 开发间接费单方,
    lr.盈利规划资本化利息单方 as 资本化利息单方,
    lr.盈利规划营销费用单方  as 营销费用单方,
    lr.盈利规划综合管理费单方 as 综合管理费单方,
    lr.盈利规划税金及附加单方 as 税金单方
  FROM [dbo].[dw_s_WqBaseStatic_Organization] org
  LEFT  JOIN  [dbo].[dw_s_WqBaseStatic_LxdwInfo] lxdw ON org.组织架构ID =lxdw.组织架构ID and org.清洗时间id =lxdw.清洗时间id
  left  join  [dbo].[dw_s_WqBaseStatic_ProfitInfo]  lr on  org.组织架构ID =lr.组织架构ID and org.清洗时间id =lr.清洗时间id
  WHERE org.平台公司名称 = '湾区公司' AND org.组织架构类型 = 5  and  DATEDIFF(day,org.清洗时间,getdate()) =0

--车位分摊用的指标/车位数量＞20就是大面积，≤20就是小面积。
  select  * 
  from [dbo].[cb_FtModelZdZbRecollect] 
  where ProductCostRecollectGUID='b7cdbd62-ffa3-4ec3-a20f-bf6c0b8c5856'and ytcode=1

-- 获取成本二次分摊最新已审核拍照版本的车位业态的分摊模式
SELECT pcr.ProductCostRecollectGUID,
       pcr.ProjGUID,
       pcr.CurVersion, --版本号
       pcr.RecollectTime, --二次分摊拍照日期
       pkcbr.CostCode, --分摊科目名称
       pkcbr.CostGUID, --分摊科目GUID
       pkcbr.IfEndCost,
       dtl.YtCode, --成本业态编码
       dtl.YtName, --成本业态名称
       CASE
            WHEN sjft.SjFtModel LIKE '%按建造面积-%' THEN '按建造面积' --0.01
            WHEN sjft.SjFtModel LIKE '%按用地面积-%' THEN '按用地面积' --0.02
            WHEN sjft.SjFtModel LIKE '%按可售面积-%' THEN '按可售面积' --0.03
            WHEN sjft.SjFtModel LIKE '%按计容面积-%' THEN '按计容面积' --0.04
            WHEN sjft.SjFtModel LIKE '%按自持面积-%' THEN '按自持面积' --0.05
            WHEN sjft.SjFtModel LIKE '%按（自持+可售）面积-%' THEN '按（自持+可售）面积' --0.06
            WHEN sjft.SjFtModel LIKE '%指定指标-%' THEN '指定指标' --0.07
            ELSE sjft.SjFtModel END SjFtModel --科目实际分摊模式
INTO   #projftMode
  FROM TaskCenterData.dbo.[cb_ProductKsCbRecollect] pkcbr
 INNER JOIN TaskCenterData.dbo.[cb_ProductKsCbDtlRecollect] dtl ON dtl.ProductKsCbRecollectGUID  = pkcbr.ProductKsCbRecollectGUID
 -- 查询最新已审核版本    
 INNER JOIN (SELECT a.ProductCostRecollectGUID,
                    a.ProjGUID,
                    a.UpVersion,
                    a.CurVersion,
                    a.ImportVersionName,
                    a.RecollectTime,
                    ROW_NUMBER() OVER (PARTITION BY a.ProjGUID ORDER BY a.RecollectTime DESC) AS num
               FROM TaskCenterData.dbo.cb_ProductCostRecollect a
              WHERE a.ApproveState = '已审核') pcr
    ON pcr.ProductCostRecollectGUID  = pkcbr.ProductCostRecollectGUID AND pcr.num = 1
  ----获取科目的实际分摊模式
  LEFT JOIN (SELECT ProductCostRecollectGUID,
                    cp.CostGUID,
                    ISNULL(cp.SjFtModel, '') SjFtModel
               FROM TaskCenterData.dbo.cb_ProductCbFtRecollect cp
              GROUP BY ProductCostRecollectGUID,
                       cp.CostGUID,
                       ISNULL(cp.SjFtModel, '')) sjft
    ON sjft.ProductCostRecollectGUID = pkcbr.ProductCostRecollectGUID
   AND sjft.CostGUID                 = pkcbr.CostGUID
 WHERE pcr.num = 1
   AND pkcbr.IfEndCost = 1 
   AND dtl.IsCost = 1
   AND dtl.YtName LIKE '%普通地下车库%'
   AND ISNULL(sjft.SjFtModel, '') <> ''
   -- and   pkcbr.ProjGUID ='2B3B0206-F785-E911-80B7-0A94EF7517DD' --汕尾保利海德公馆-一期
 ORDER BY CostCode, CostShortName

--分摊模式去重
-- 统计分摊模式的数量，拼接分摊模式字段
SELECT ProductCostRecollectGUID,
       ProjGUID,
       CurVersion,
       RecollectTime,
       COUNT(SjFtModel) AS SjFtModelNum,
       STRING_AGG(SjFtModel, ',') AS SjFtModelStr
INTO   #projft
  FROM (SELECT DISTINCT ProductCostRecollectGUID,
               ProjGUID,
               CurVersion,
               RecollectTime,
               SjFtModel
          FROM #projftMode) AS projftMode
 GROUP BY ProductCostRecollectGUID,
          ProjGUID,
          CurVersion,
          RecollectTime

--获取车位的分摊面积指标
SELECT ProjGUID,
       ProductCostRecollectGUID,
       SUM(IndexValue) AS IndexValue
INTO   #IndexValue
  FROM [cb_FtModelZdZbRecollect]
 WHERE YtName LIKE '%普通地下车库%' AND ISNULL(FtRate, '') <> 0
 GROUP BY ProjGUID,  ProductCostRecollectGUID 

--获取车位的分摊面积车位数量
SELECT ProductCostRecollectGUID,
       SUM(CwNum) AS CwNum
INTO   #CwNum
FROM cb_YtProjKscbRecollect
WHERE IsCost = 1
GROUP BY ProductCostRecollectGUID;

--汇总查询
--车位分摊用的指标/车位数量＞20就是大面积，≤20就是小面积。
select  
	ProductCostRecollectGUID,
	ProjGUID,
	RecollectTime,
	SjFtModelNum,
	SjFtModelStr,
	IndexValue,
	CwNum,
	IndexValue2CwNum,
	case when IndexValue2CwNum >20 then  
	      SjFtModelStr +' ' + convert(varchar(10),RecollectTime,121) + ' 大面积(' + CONVERT(varchar(50),IndexValue2CwNum )+ ')' 
    else  SjFtModelStr +' ' + convert(varchar(10),RecollectTime,121) + ' 小面积(' + CONVERT(varchar(50),IndexValue2CwNum ) + ')' end  车位分摊口径
from  (
	SELECT a.ProductCostRecollectGUID,
		   a.ProjGUID,
		   a.RecollectTime,
		   a.SjFtModelNum,
		   a.SjFtModelStr,
		   b.IndexValue,
		   c.CwNum,
		   convert(decimal(18,2),  case when isnull(c.CwNum,0) =0 then  0 else  isnull(b.IndexValue,0) *1.0 / isnull(c.CwNum,0) end ) as IndexValue2CwNum --车位分摊用的指标/车位数量
	  FROM #projft a
	  LEFT JOIN #IndexValue b ON a.ProductCostRecollectGUID = b.ProductCostRecollectGUID
	  LEFT JOIN #CwNum c  ON c.ProductCostRecollectGUID = a.ProductCostRecollectGUID 
  ) temp


----删除临时表
DROP TABLE #projftMode,
           #projft,
           #CwNum,
           #IndexValue;