DECLARE @lastMonthEndDay DATETIME = DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, GETDATE()), 0)); -- 上月末

-- 统计平台公司的现金流 
SELECT  
        org.清洗时间,
        org.平台公司GUID ,
        org.组织架构父级id ,
        org.组织架构id ,
        org.组织架构名称 ,
        org.组织架构类型, 
        sale.本月签约任务 ,
        sale.本月签约金额 ,
        case when sale.本月签约任务 = 0 then 0 else sale.本月签约金额/sale.本月签约任务 end as 本月签约完成率,
        sale.本年签约任务 ,
        sale.本年已签约金额 AS 本年签约金额 ,
        case when sale.本年签约任务 = 0 then 0 else sale.本年已签约金额/sale.本年签约任务 end as 本年签约完成率,
        sale.本月认购任务 ,
        sale.本月认购金额 ,
        case when sale.本月认购任务 = 0 then 0 else sale.本月认购金额/sale.本月认购任务 end as 本月认购完成率,
        sale.本年认购任务 ,
        sale.本年认购金额 ,
        case when sale.本年认购任务 = 0 then 0 else sale.本年认购金额/sale.本年认购任务 end as 本年认购完成率,
        hl.本月回笼任务 ,
        hl.本月回笼金额 ,
        case when hl.本月回笼任务 = 0 then 0 else hl.本月回笼金额/hl.本月回笼任务 end as 本月回笼完成率,
        hl.本月权益回笼任务 ,
        hl.本月权益回笼金额 ,
        case when hl.本月权益回笼任务 = 0 then 0 else hl.本月权益回笼金额/hl.本月权益回笼任务 end as 本月权益回笼完成率,
        hl.本年回笼任务 ,
        hl.本年回笼金额 ,
        case when hl.本年回笼任务 = 0 then 0 else hl.本年回笼金额/hl.本年回笼任务 end as 本年回笼完成率,
        hl.本年权益回笼任务 ,
        hl.本年权益回笼金额 ,
        case when hl.本年权益回笼任务 = 0 then 0 else hl.本年权益回笼金额/hl.本年权益回笼任务 end as 本年权益回笼完成率,
        
        /*sch.本月计划开工面积 ,
        sch.本月实际开工面积 ,
        case when sch.本月计划开工面积 = 0 then 0 else sch.本月实际开工面积/sch.本月计划开工面积 end as 本月开工完成率,
        sch.本月计划竣工面积 , 
        sch.本月实际竣工面积 ,
        case when sch.本月计划竣工面积 = 0 then 0 else sch.本月实际竣工面积/sch.本月计划竣工面积 end as 本月竣工完成率,
        sch.本年计划开工面积 , 
        sch.本年实际开工面积 ,
        case when sch.本年计划开工面积 = 0 then 0 else sch.本年实际开工面积/sch.本年计划开工面积 end as 本年开工完成率,
        sch.本年计划竣工面积 ,
        sch.本年实际竣工面积 ,
        case when sch.本年计划竣工面积 = 0 then 0 else sch.本年实际竣工面积/sch.本年计划竣工面积 end as 本年竣工完成率, */

        cash.本月土地任务 AS 本月地价任务 ,
        cash.本月地价支出 ,
        cash.本月除地价外直投任务 ,
        cash.本月除地价外直投发生 ,
        case when cash.本月除地价外直投任务 = 0 then 0 else cash.本月除地价外直投发生/cash.本月除地价外直投任务 end as 本月除地价外直投完成率,
        cash.本年除地价外直投任务 ,
        cash.本年除地价外直投发生 ,
        case when cash.本年除地价外直投任务 = 0 then 0 else cash.本年除地价外直投发生/cash.本年除地价外直投任务 end as 本年除地价外直投完成率,
        cash.本年贷款任务 ,
        cash.本年净增贷款 ,
        case when cash.本年贷款任务 = 0 then 0 else cash.本年净增贷款/cash.本年贷款任务 end as 本年贷款完成率,
        cash.本月贷款任务 ,
        cash.本月贷款金额 ,
        case when cash.本月贷款任务 = 0 then 0 else cash.本月贷款金额/cash.本月贷款任务 end as 本月贷款完成率,
        cash.本月营销费支出 ,
        cash.本月管理费支出 ,
        cash.本月财务费支出 ,
        cash.本月三费任务 AS 本月三费任务 ,
        ISNULL(cash.本月营销费支出, 0) + ISNULL(cash.本月管理费支出, 0) + ISNULL(cash.本月财务费支出, 0) AS 本月三费金额 ,
        cash.本月税金支出 ,
        cash.本月经营性现金流目标 AS 本月经营性现金流任务 ,
        cash.本月经营性现金流 ,
        case when cash.本月经营性现金流目标 = 0 then null  else cash.本月经营性现金流/cash.本月经营性现金流目标 end as 本月经营性现金流完成率,
        cash.本年经营性现金流目标 AS 本年经营性现金流任务 ,
        cash.本年经营性现金流 ,
        case when cash.本年经营性现金流目标 = 0 then null else cash.本年经营性现金流/cash.本年经营性现金流目标 end as 本年经营性现金流完成率,
        cash.本年股东投资现金流目标 AS 本年股东现金流任务 ,
        cash.本年股东现金流 ,
        profit.本年预计销售净利润账面 ,
        profit.本年预计销售净利率账面 ,
        profit.本年销售净利率账面 ,
        profit.本年销售净利润账面 , 
        profit.本月销售净利率账面 ,
        profit.本月净利润签约
INTO    #SubCompayMonthCshflow
FROM    highdata_prod.dbo.dw_s_WqBaseStatic_Organization org
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_baseinfo base ON org.组织架构id = base.组织架构id  and org.清洗时间id = base.清洗时间id 
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_tradeInfo sale ON sale.组织架构id = org.组织架构id and  org.清洗时间id = sale.清洗时间id
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_ProfitInfo profit ON profit.组织架构id = org.组织架构id and  org.清洗时间id = profit.清洗时间id
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_returnInfo hl ON hl.组织架构id = org.组织架构id and  org.清洗时间id = hl.清洗时间id
        --LEFT JOIN highdata_prod.dbo.data_wide_dws_s_WqBaseStatic_ScheduleInfo sch ON sch.组织架构id = org.组织架构id
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_cashflowInfo cash ON cash.组织架构id = org.组织架构id and  org.清洗时间id = cash.清洗时间id
WHERE   1 = 1 AND   org.组织架构类型 IN  (1,2)  AND  org.平台公司名称 = '湾区公司';

--本月计划开工 竣备节点
select  
   bd.BUGUID, 
   shi.清洗时间,
   sum(case when  DATEDIFF(year,shi.实际开工计划完成时间,shi.清洗时间 ) =0 then  BuildArea end ) as 本年计划开工面积, -- 实际开工
   sum(case when  DATEDIFF(year,shi.实际开工实际完成时间,shi.清洗时间 ) =0 then  BuildArea end ) as 本年实际开工面积,
   case when  sum(case when  DATEDIFF(year,实际开工计划完成时间,shi.清洗时间 ) =0 then  BuildArea end )  =0  then  0 
     else sum(case when  DATEDIFF(year,实际开工实际完成时间,shi.清洗时间) =0 then  BuildArea end ) /
        sum(case when  DATEDIFF(year,实际开工计划完成时间,shi.清洗时间) =0 then  BuildArea end )  end  as 本年开工完成率,
	 sum(case when  DATEDIFF(month,实际开工计划完成时间,shi.清洗时间 ) =0 then  BuildArea end ) as 本月计划开工面积,
	 sum(case when  DATEDIFF(month,实际开工实际完成时间,shi.清洗时间 ) =0 then  BuildArea end ) as 本月实际开工面积,
   case when  sum(case when  DATEDIFF(month,实际开工计划完成时间,shi.清洗时间 ) =0 then  BuildArea end )  =0  then 0
    else sum(case when  DATEDIFF(month,实际开工实际完成时间,shi.清洗时间 ) =0 then  BuildArea end ) /
     sum(case when  DATEDIFF(month,实际开工计划完成时间,shi.清洗时间) =0 then  BuildArea end )   end as 本月开工完成率,

   sum(case when  DATEDIFF(year,shi.竣工备案计划完成时间,shi.清洗时间) =0 then  BuildArea end ) as 本年计划竣工面积,
	 sum(case when  DATEDIFF(year,竣工备案实际完成时间,shi.清洗时间) =0 then  BuildArea end ) as 本年实际竣工面积,
   case when  sum(case when  DATEDIFF(year,竣工备案计划完成时间,shi.清洗时间) =0 then  BuildArea end )  =0 then 0
    else  sum(case when  DATEDIFF(year,竣工备案实际完成时间,shi.清洗时间) =0 then  BuildArea end ) /
      sum(case when  DATEDIFF(year,竣工备案计划完成时间,shi.清洗时间) =0 then  BuildArea end )
   end as  本年竣工完成率,  
    sum(case when  DATEDIFF(month,竣工备案计划完成时间,shi.清洗时间) =0 then  BuildArea end ) as 本月计划竣工面积,
    sum(case when  DATEDIFF(month,竣工备案实际完成时间,shi.清洗时间) =0 then  BuildArea end ) as 本月实际竣工面积,
  case when   sum(case when  DATEDIFF(year,竣工备案计划完成时间,shi.清洗时间) =0 then  BuildArea end )  =0 then 0
    else sum(case when  DATEDIFF(month,竣工备案实际完成时间,shi.清洗时间) =0 then  BuildArea end ) /
     sum(case when  DATEDIFF(month,竣工备案计划完成时间,shi.清洗时间) =0 then  BuildArea end ) 
  end as 本月竣工完成率  
into #sh
from  data_wide_dws_mdm_Building bd
inner join  dw_s_WqBaseStatic_ScheduleInfo shi on  组织架构类型 =7  and bd.BuildingGUID =shi.组织架构ID
where  bd.BUGUID ='248B1E17-AACB-E511-80B8-E41F13C51836' and bd.BldType ='产品楼栋' --and datediff(day, shi.清洗时间,getdate()) =0
group by  BUGUID, shi.清洗时间



--统计上月开工、竣备情况
select  
     bd.BUGUID,
     shi.清洗时间,
     sum(case when  DATEDIFF(year,shi.实际开工计划完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0))  ) =0 then  BuildArea end ) as 本年计划开工面积, -- 实际开工
     sum(case when  DATEDIFF(year,shi.实际开工实际完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end ) as 本年实际开工面积,
     case when  sum(case when  DATEDIFF(year,实际开工计划完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end )  =0  then  0 
     else sum(case when  DATEDIFF(year,实际开工实际完成时间, DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end ) /
        sum(case when  DATEDIFF(year,实际开工计划完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end )  end  as 本年开工完成率,

	 sum(case when  DATEDIFF(month,实际开工计划完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end ) as 本月计划开工面积,
	 sum(case when  DATEDIFF(month,实际开工实际完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end ) as 本月实际开工面积,
   case when  sum(case when  DATEDIFF(month,实际开工计划完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end )  =0  then 0
    else sum(case when  DATEDIFF(month,实际开工实际完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end ) /
     sum(case when  DATEDIFF(month,实际开工计划完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end )   end as 本月开工完成率,

   sum(case when  DATEDIFF(year,shi.竣工备案计划完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end ) as 本年计划竣工面积,
	 sum(case when  DATEDIFF(year,竣工备案实际完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end ) as 本年实际竣工面积,
   case when  sum(case when  DATEDIFF(year,竣工备案计划完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end )  =0 then 0
    else  sum(case when  DATEDIFF(year,竣工备案实际完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end ) /
      sum(case when  DATEDIFF(year,竣工备案计划完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end )
   end as  本年竣工完成率,  

    sum(case when  DATEDIFF(month,竣工备案计划完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end ) as 本月计划竣工面积,
    sum(case when  DATEDIFF(month,竣工备案实际完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end ) as 本月实际竣工面积,
    case when   sum(case when  DATEDIFF(year,竣工备案计划完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0))) =0 then  BuildArea end )  =0 then 0
    else sum(case when  DATEDIFF(month,竣工备案实际完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end ) /
     sum(case when  DATEDIFF(month,竣工备案计划完成时间,DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, 清洗时间), 0)) ) =0 then  BuildArea end ) 
  end as 本月竣工完成率  
into #Lastsh
from  data_wide_dws_mdm_Building bd
inner join  dw_s_WqBaseStatic_ScheduleInfo shi on  组织架构类型 =7  and bd.BuildingGUID =shi.组织架构ID
where  bd.BUGUID ='248B1E17-AACB-E511-80B8-E41F13C51836' and bd.BldType ='产品楼栋' 
--and datediff(day, shi.清洗时间,EOMONTH(dateadd(mm,-1,getdate())-1,0)) =0
group by  BUGUID,shi.清洗时间

--截止上月末的签约、认购完成率
SELECT  
        org.清洗时间,
        org.平台公司GUID ,
        org.组织架构父级id ,
        org.组织架构id ,
        org.组织架构名称 ,
        sum(case when  datediff(day,sale.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   sale.本年签约任务 else  0  end ) as 本年签约任务,
	sum(case when  datediff(day,sale.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0))  ) = 0 then   sale.本年已签约金额 else  0  end ) as 本年已签约金额,
        case when  sum(case when  datediff(day,sale.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   sale.本年签约任务 else  0  end )  =0  then  0
          else  
             sum(case when  datediff(day,sale.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0))  ) = 0 then   sale.本年已签约金额 else  0  end ) /
             sum(case when  datediff(day,sale.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   sale.本年签约任务 else  0  end ) 
        end  as  本年签约完成率,
        sum(case when  datediff(day,sale.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   sale.本年认购任务 else  0  end ) as 本年认购任务,
	sum(case when  datediff(day,sale.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0))  ) = 0 then   sale.本年认购金额 else  0  end ) as 本年认购金额,
        case when  
		    sum(case when  datediff(day,sale.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   sale.本年认购任务 else  0  end )  =0  then  0
          else  
             sum(case when  datediff(day,sale.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0))  ) = 0 then   sale.本年认购金额 else  0  end ) /
             sum(case when  datediff(day,sale.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   sale.本年认购任务 else  0  end ) 
        end  as  本年认购完成率     
INTO    #RgQy_last
FROM    highdata_prod.dbo.dw_s_WqBaseStatic_Organization org
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_tradeInfo sale ON sale.组织架构id = org.组织架构id and  sale.组织架构类型 =1 --and org.清洗时间id = sale.清洗时间id
WHERE   1 = 1 AND   org.组织架构类型 = 1 AND  org.平台公司名称 = '湾区公司' 
group by 
        org.清洗时间,
        org.平台公司GUID ,
        org.组织架构父级id ,
        org.组织架构id ,
        org.组织架构名称 
order by org.清洗时间 


--截止上月末的回笼完成率以及权益回笼完成率
SELECT  
        org.清洗时间,
        org.平台公司GUID ,
        org.组织架构父级id ,
        org.组织架构id ,
        org.组织架构名称 ,
        sum(case when  datediff(day,hl.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   hl.本年回笼任务 else  0  end ) as 本年回笼任务,
	    sum(case when  datediff(day,hl.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0))  ) = 0 then  hl.本年回笼金额 else  0  end ) as 本年回笼金额,
        case when  sum(case when  datediff(day,hl.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   hl.本年回笼任务 else  0  end )  =0  then  0
          else  
             sum(case when  datediff(day,hl.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0))  ) = 0 then   hl.本年回笼金额 else  0  end ) /
             sum(case when  datediff(day,hl.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   hl.本年回笼任务 else  0  end ) 
        end  as  本年回笼完成率,
        sum(case when  datediff(day,hl.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   hl.本年权益回笼任务 else  0  end ) as 本年权益回笼任务,
	    sum(case when  datediff(day,hl.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0))  ) = 0 then   hl.本年权益回笼金额 else  0  end ) as 本年权益回笼金额,
        case when  
		    sum(case when  datediff(day,hl.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   hl.本年权益回笼任务 else  0  end )  =0  then  0
          else  
             sum(case when  datediff(day,hl.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0))  ) = 0 then   hl.本年权益回笼金额 else  0  end ) /
             sum(case when  datediff(day,hl.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   hl.本年权益回笼任务 else  0  end ) 
        end  as  本年权益回笼完成率     
INTO    #hl_last
FROM    highdata_prod.dbo.dw_s_WqBaseStatic_Organization org
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_returnInfo hl ON hl.组织架构id = org.组织架构id and  hl.组织架构类型 =1 --and org.清洗时间id = hl.清洗时间id
WHERE   1 = 1 AND   org.组织架构类型 in (1,2) AND  org.平台公司名称 = '湾区公司' 
group by 
        org.清洗时间,
        org.平台公司GUID ,
        org.组织架构父级id ,
        org.组织架构id ,
        org.组织架构名称 
order by org.清洗时间 

--截止上月末的除地价外直投、贷款、经营性现金流
SELECT  
        org.清洗时间,
        org.平台公司GUID ,
        org.组织架构父级id ,
        org.组织架构id ,
        org.组织架构名称 ,
        sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   cash.本年除地价外直投任务 else  0  end ) as 本年除地价外直投任务,
	    sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0))  ) = 0 then  cash.本年除地价外直投发生 else  0  end ) as 本年除地价外直投发生,
        case when  sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   cash.本年除地价外直投任务 else  0  end )  =0  then  0
          else  
             sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0))  ) = 0 then   cash.本年除地价外直投发生  else  0  end ) /
             sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   cash.本年除地价外直投任务 else  0  end ) 
        end  as  本年除地价外直投完成率,
        sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   cash.本年贷款任务 else  0  end ) as 本年贷款任务,
	    sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0))  ) = 0 then   cash.本年净增贷款 else  0  end ) as 本年净增贷款,
        case when  
	     sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   cash.本年贷款任务 else  0  end )  =0  then  0
          else  
             sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0))  ) = 0 then  cash.本年净增贷款 else  0  end ) /
             sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   cash.本年贷款任务 else  0  end ) 
        end  as  本年贷款完成率,
        sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   cash.本年经营性现金流目标 else  0  end ) as 本年经营性现金流目标,
	    sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0))  ) = 0 then   cash.本年经营性现金流 else  0  end ) as 本年经营性现金流,
        case when  
	     sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   cash.本年经营性现金流目标 else  0  end )  =0  then  0
          else  
             sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0))  ) = 0 then  cash.本年经营性现金流 else  0  end ) /
             sum(case when  datediff(day,cash.清洗时间,  DATEADD(ms, -3, DATEADD(mm, DATEDIFF(m, 0, org.清洗时间), 0)) ) = 0 then   cash.本年经营性现金流目标 else  0  end ) 
        end  as  本年经营性现金流完成率          
INTO    #xjl_last
FROM    highdata_prod.dbo.dw_s_WqBaseStatic_Organization org
        LEFT JOIN highdata_prod.dbo.dw_s_WqBaseStatic_cashflowInfo cash ON cash.组织架构id = org.组织架构id and  cash.组织架构类型 =1  --and org.清洗时间id = cash.清洗时间id
WHERE   1 = 1 AND   org.组织架构类型 = 1 AND  org.平台公司名称 = '湾区公司' 
group by 
        org.清洗时间,
        org.平台公司GUID ,
        org.组织架构父级id ,
        org.组织架构id ,
        org.组织架构名称 
order by org.清洗时间 

--查询结果集
--认购
SELECT  convert(datetime, t.清洗时间) as  清洗时间 ,
        1 AS 序号 ,
        '认购' AS 关键指标 ,
        t.本月认购任务/ 10000.0 AS 湾区公司月度任务 ,
        t.本月认购金额/ 10000.0 AS 湾区公司月度金额 ,
        t.本月认购完成率 AS 湾区公司月度完成率 ,
        t.本年认购任务/ 10000.0 AS 湾区公司年度任务 ,
        t.本年认购金额/ 10000.0 AS 湾区公司年度金额 ,
        t.本年认购完成率 AS 湾区公司年度完成率 ,
        case when l.本年认购完成率 = 0 then 0 else (t.本年认购完成率 - l.本年认购完成率)/l.本年认购完成率 end AS 环比上月与时间进度变化
FROM    #SubCompayMonthCshflow t 
left join #RgQy_last l on t.清洗时间 = l.清洗时间 
UNION ALL
--签约
SELECT  
        convert(datetime, t.清洗时间) as  清洗时间 ,
        2 AS 序号 ,
        '签约' AS 关键指标 ,
        t.本月签约任务/ 10000.0 AS 湾区公司月度任务 ,
        t.本月签约金额/ 10000.0 AS 湾区公司月度金额 ,
        t.本月签约完成率 AS 湾区公司月度完成率 ,
        t.本年签约任务/ 10000.0 AS 湾区公司年度任务 ,
        t.本年签约金额/ 10000.0 AS 湾区公司年度金额 ,
        t.本年签约完成率 AS 湾区公司年度完成率 ,
        case when l.本年签约完成率 = 0 then 0 else (t.本年签约完成率 - l.本年签约完成率)/l.本年签约完成率 end AS 环比上月与时间进度变化
FROM    #SubCompayMonthCshflow t
left join #RgQy_last l on t.清洗时间 = l.清洗时间
UNION ALL
--回笼全口径
SELECT  
        convert(datetime, t.清洗时间) as  清洗时间 ,
        3 AS 序号 ,
        '回笼(全口径)' AS 关键指标 ,
        t.本月回笼任务/ 10000.0 AS 湾区公司月度任务 ,
        t.本月回笼金额/ 10000.0 AS 湾区公司月度金额 ,
        t.本月回笼完成率 AS 湾区公司月度完成率 ,
        t.本年回笼任务/ 10000.0 AS 湾区公司年度任务 ,
        t.本年回笼金额/ 10000.0 AS 湾区公司年度金额 ,
        t.本年回笼完成率 AS 湾区公司年度完成率 ,
        case when l.本年回笼完成率 = 0 then 0 else (t.本年回笼完成率 - l.本年回笼完成率)/l.本年回笼完成率 end AS 环比上月与时间进度变化
FROM    #SubCompayMonthCshflow t
left join #hl_last l on t.清洗时间 = l.清洗时间
UNION ALL
--回笼权益口径
SELECT  
        convert(datetime, t.清洗时间) as  清洗时间 ,
        4 AS 序号 ,
        '回笼(权益)' AS 关键指标 ,
        t.本月权益回笼任务/ 10000.0 AS 湾区公司月度任务 ,
        t.本月权益回笼金额/ 10000.0 AS 湾区公司月度金额 ,
        t.本月权益回笼完成率 AS 湾区公司月度完成率 ,
        t.本年权益回笼任务/ 10000.0 AS 湾区公司年度任务 ,
        t.本年权益回笼金额/ 10000.0 AS 湾区公司年度金额 ,
        t.本年权益回笼完成率 AS 湾区公司年度完成率 ,
        case when l.本年权益回笼完成率 = 0 then 0 else (t.本年权益回笼完成率 - l.本年权益回笼完成率)/l.本年权益回笼完成率 end AS 环比上月与时间进度变化
FROM    #SubCompayMonthCshflow t
left join #hl_last l on t.清洗时间 = l.清洗时间
UNION ALL
--贷款
SELECT  
        convert(datetime, t.清洗时间) as  清洗时间 ,
        5 AS 序号 ,
        '贷款' AS 关键指标 ,
        t.本月贷款任务/ 10000.0 AS 湾区公司月度任务 ,
        t.本月贷款金额/ 10000.0 AS 湾区公司月度金额 ,
        t.本月贷款完成率 AS 湾区公司月度完成率 ,
        t.本年贷款任务/ 10000.0 AS 湾区公司年度任务 ,
        t.本年净增贷款/ 10000.0 AS 湾区公司年度金额 ,
        t.本年贷款完成率 AS 湾区公司年度完成率 ,
        case when l.本年贷款完成率 = 0 then 0 else (t.本年贷款完成率 - l.本年贷款完成率)/l.本年贷款完成率 end AS 环比上月与时间进度变化
FROM    #SubCompayMonthCshflow t
left join #xjl_last l on t.清洗时间 = l.清洗时间
UNION ALL
--直投
SELECT  
        convert(datetime, t.清洗时间) as  清洗时间 ,
        6 AS 序号 ,
        '直投' AS 关键指标 ,
        t.本月除地价外直投任务/ 10000.0 AS 湾区公司月度任务 ,
        t.本月除地价外直投发生/ 10000.0 AS 湾区公司月度金额 ,
        t.本月除地价外直投完成率 AS 湾区公司月度完成率 ,
        t.本年除地价外直投任务/ 10000.0 AS 湾区公司年度任务 ,
        t.本年除地价外直投发生/ 10000.0 AS 湾区公司年度金额 ,
        t.本年除地价外直投完成率 AS 湾区公司年度完成率 ,
        case when l.本年除地价外直投完成率 = 0 then 0 else (t.本年除地价外直投完成率 - l.本年除地价外直投完成率)/l.本年除地价外直投完成率 end AS 环比上月与时间进度变化
FROM    #SubCompayMonthCshflow t
left join #xjl_last l on t.清洗时间 = l.清洗时间
UNION ALL
SELECT  
       convert(datetime, t.清洗时间) as  清洗时间 ,
        7 AS 序号 ,
        '开工' AS 关键指标 ,
        t.本月计划开工面积/ 10000.0 AS 湾区公司月度任务 ,
        t.本月实际开工面积/ 10000.0 AS 湾区公司月度金额 ,
        case  when isnull(t.本月计划开工面积,0) =0 then  0  else t.本月实际开工面积 /  t.本月计划开工面积  end AS 湾区公司月度完成率 ,
        t.本年计划开工面积/ 10000.0 AS 湾区公司年度任务 ,
        t.本年实际开工面积/ 10000.0 AS 湾区公司年度金额 ,
        case when  isnull(t.本年计划开工面积,0) =0  then  0 else t.本年实际开工面积 /  t.本年计划开工面积 end   AS 湾区公司年度完成率 ,  
        case when l.本年开工完成率 = 0 then 0 else (t.本年开工完成率 - l.本年开工完成率) /l.本年开工完成率 end AS 环比上月与时间进度变化
FROM    #sh t
left join #Lastsh l on t.BUGUID=l.BUGUID and  t.清洗时间 = l.清洗时间
UNION ALL
--竣工
SELECT  
        convert(datetime, t.清洗时间) as  清洗时间 ,
        8 AS 序号 ,
        '竣工' AS 关键指标 ,
        t.本月计划竣工面积/ 10000.0 AS 湾区公司月度任务 ,
        t.本月实际竣工面积/ 10000.0 AS 湾区公司月度金额 ,
        t.本月竣工完成率 AS 湾区公司月度完成率 ,
        t.本年计划竣工面积/ 10000.0 AS 湾区公司年度任务 ,
        t.本年实际竣工面积/ 10000.0 AS 湾区公司年度金额 ,
        t.本年竣工完成率 AS 湾区公司年度完成率 ,
        case when l.本年竣工完成率 = 0 then 0 else (t.本年竣工完成率 - l.本年竣工完成率)/l.本年竣工完成率 end AS 环比上月与时间进度变化
FROM    #sh t
left join #Lastsh l on t.BUGUID = l.BUGUID and  t.清洗时间 = l.清洗时间
UNION ALL
--经营性现金流
SELECT  
        convert(datetime, t.清洗时间) as  清洗时间 ,
        9 AS 序号 ,
        '经营性现金流' AS 关键指标 ,
        t.本月经营性现金流任务/ 10000.0 AS 湾区公司月度任务 ,
        t.本月经营性现金流/ 10000.0 AS 湾区公司月度金额 ,
        t.本月经营性现金流完成率 AS 湾区公司月度完成率 ,
        t.本年经营性现金流任务/ 10000.0 AS 湾区公司年度任务 ,
        t.本年经营性现金流/ 10000.0 AS 湾区公司年度金额 ,
        t.本年经营性现金流完成率 AS 湾区公司年度完成率 ,
        case when l.本年经营性现金流完成率 = 0 then 0 else (t.本年经营性现金流完成率 - l.本年经营性现金流完成率)/l.本年经营性现金流完成率 end  AS 环比上月与时间进度变化
FROM    #SubCompayMonthCshflow t
left join #xjl_last l on t.清洗时间 = l.清洗时间
UNION ALL 
--签约净利率
SELECT  
        convert(datetime, t.清洗时间) as  清洗时间 ,
        10 AS 序号 ,
        '签约净利率' AS 关键指标 ,
        NULL  AS 湾区公司月度任务 ,
        ISNULL(本月销售净利率账面,0)  AS 湾区公司月度金额 ,
        NULL  AS 湾区公司月度完成率 ,
        ISNULL(本年预计销售净利率账面, 0) AS 湾区公司年度任务 ,
        ISNULL(本年销售净利率账面, 0)  AS 湾区公司年度金额 ,
        NULL  湾区公司年度完成率 ,
        NULL AS 环比上月与时间进度变化
FROM    #SubCompayMonthCshflow t
--left join #SubCompayMonthCshflow_last l on t.清洗时间 = l.清洗时间
UNION ALL
--签约净利润
SELECT  
        convert(datetime, t.清洗时间) as  清洗时间 ,
        11 AS 序号 ,
        '签约净利润' AS 关键指标 ,
        NULL  AS 湾区公司月度任务 ,
        ISNULL(本月净利润签约,0) AS 湾区公司月度金额 ,
        NULL AS 湾区公司月度完成率 ,
        ISNULL(本年预计销售净利润账面, 0)  AS 湾区公司年度任务 ,
        ISNULL(本年销售净利润账面, 0)  AS 湾区公司年度金额 ,
        NULL AS 湾区公司年度完成率 ,
        NULL AS 环比上月与时间进度变化
FROM    #SubCompayMonthCshflow t
--left join #SubCompayMonthCshflow_last l on t.清洗时间 = l.清洗时间
--结算利润(并表)

--删除临时表
DROP TABLE #SubCompayMonthCshflow,#sh,#Lastsh,#hl_last,#RgQy_last,#xjl_last