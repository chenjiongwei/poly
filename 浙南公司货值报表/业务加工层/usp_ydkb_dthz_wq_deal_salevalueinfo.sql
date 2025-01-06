USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_ydkb_dthz_wq_deal_salevalueinfo]    Script Date: 2025/1/6 10:43:51 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
/*
取数来源说明:
    分为：楼栋底表 + 货量铺排
    楼栋底表可以到楼栋，但是货量铺排的只能到业态；因此若是手工导入铺排的就取货量铺排，若系统自动计算的则取楼栋底表
计算逻辑说明：
  由于有些项目只能到业态部分，因为向上汇总的时候，以业态作为基准，循环向上汇总，直到到达平台公司级

author:ltx  date:20200525

修改：
1.去掉惠州保利天汇项目中，202012的货量铺排中获取的签约及认购金额--谢立峰，20201224
2.去掉第1点的修改，并且去掉惠州保利天汇项目中，年初的的货量铺排中获取的签约及认购金额 --谢立峰，20210114
3.去掉惠州保利天汇的特殊处理 --谢立峰 20220107
4.部分老项目手工铺排的时候，累计签约套数没有取到；手工铺排项目的累计签约套数从楼栋底表出 ——20230727
5.增加剩余货值_三年内不开工情况、在途货值、未开工货值 ——20231122

修改：20231214
1、年初剩余货值调整为反算，不取1月1号存档版本
2、业态层级的年初剩余货值 = 楼栋底表的年初可售货值面积-本年以前的合作特殊的已售货值面积

修改：20240603
1、增加年初存档版本，从1月1号存档版本取——上海公司
2、增加月初存档版本，从上月月底存档版本取——上海公司
3、增加预估去化逻辑，从天数差调整为月份数差

修改：20240730 lintx
调整工程节点逻辑判断及取证逻辑判断

修改：20240816 lintx
增加停工缓建剩余货值

修改：20240822 lintx
增加各阶段的停工缓建货值：在途,存货,达形象未取证货值,获证待推货值,已推未售货值

修改：20240910 lintx
增加套数指标

运行样例：[usp_ydkb_dthz_wq_deal_salevalueinfo]
*/
 
ALTER   PROC [dbo].[usp_ydkb_dthz_wq_deal_salevalueinfo]
AS
    BEGIN

  ---------------------参数设置------------------------
    DECLARE @bnYear VARCHAR(4);
    SET @bnYear =Year(getdate());
    declare @byMonth varchar(2);
    set @byMonth = Month(getdate());
    declare @byYM varchar(7);
    set @byYM = convert(varchar(7),getdate(),120);
    DECLARE @buguid VARCHAR(max) = '248B1E17-AACB-E511-80B8-E41F13C51836,4975b69c-9953-4dd0-a65e-9a36db8c66df,4A1E877C-A0B2-476D-9F19-B5C426173C38,31120F08-22C4-4220-8ED2-DCAD398C823C';
    DECLARE @developmentguid VARCHAR(max) = 'C69E89BB-A2DB-E511-80B8-E41F13C51836,461889dc-e991-4238-9d7c-b29e0aa347bb,5A4B2DEF-E803-49F8-9FE2-308735E7233D,7DF92561-3B0D-E711-80BA-E61F13C57837';
        
    
  ---------------------产品楼栋粒度统计---------------------
    --缓存当前时间的楼栋底表版本
    SELECT DISTINCT * 
    INTO #p_lddb 
    FROM [p_lddbamj] 
    WHERE DATEDIFF(dd,qxdate,getdate()) = 0 AND DevelopmentCompanyGUID IN ( SELECT Value FROM dbo.fn_Split2(@developmentguid,',')); 
    --缓存年初的楼栋底表版本
    SELECT DISTINCT * 
    INTO #nclddb 
    FROM [p_lddbamj] 
    WHERE DATEDIFF(dd,qxdate,@bnYear+'-01-01') = 0 AND DevelopmentCompanyGUID IN ( SELECT Value FROM dbo.fn_Split2(@developmentguid,',')); 
    --缓存上月底的楼栋底表版本
    SELECT DISTINCT * 
    INTO #ydlddb
    FROM [p_lddbamj] 
    WHERE DATEDIFF(dd,qxdate,dateadd(d,-1,@byYM+'-01')) = 0 AND DevelopmentCompanyGUID IN ( SELECT Value FROM dbo.fn_Split2(@developmentguid,',')); 

    --计容面积 
    SELECT pj.ParentProjGUID,sb.GCBldGUID, pb.ProductBuildGUID BldGUID,pr.ProductType,SUM(ISNULL(pb.JrArea,0)) AS 计容面积
    INTO #jr
    FROM MyCost_Erp352.dbo.md_ProductBuild pb
      left JOIN MyCost_Erp352.dbo.md_Project pj
        ON pb.VersionGUID = pj.VersionGUID
          AND pb.ProjGUID = pj.ProjGUID
    left JOIN dbo.mdm_SaleBuild sb ON pb.ProductBuildGUID  = sb.SaleBldGUID
    left JOIN dbo.mdm_Product pr ON sb.ProductGUID = pr.ProductGUID 
    WHERE pj.IsActive = 1
    GROUP BY pj.ParentProjGUID,sb.GCBldGUID, pb.ProductBuildGUID,pr.ProductType 

    --累计推货情况
    select pj.ParentProjGUID,sb.GCBldGUID,BldGUID,pr.ProductType,sum(isnull(HSZJ,0))/10000.0 as 累计推售货值, sum(isnull(BldArea,0)) as 累计推售面积, count(1) as 累计推售套数
    into #ts
    from p_room p
    left JOIN dbo.mdm_SaleBuild sb ON p.BldGUID  = sb.SaleBldGUID
    left JOIN dbo.mdm_Product pr ON sb.ProductGUID = pr.ProductGUID 
    inner join mdm_Project pj on pj.ProjGUID = p.ProjGUID
    where Status not in ('签约','认购') and ThDate is not null
    and BUGUID in (
    SELECT Value FROM dbo.fn_Split2(@buguid,',') )   
    group by pj.ParentProjGUID,sb.GCBldGUID,BldGUID,pr.ProductType

    --获取近三月流速，用来计算剩余货值预估去化
     --判断项目首次签约时间
    SELECT sp.ParentProjGUID,MIN(ISNULL(sp.StatisticalDate,'2099-12-31')) AS skdate 
    INTO #sk
    FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_s_SalesPerf sp
    GROUP BY sp.ParentProjGUID
    
    SELECT sp.BldGUID,
    SUM(ISNULL(sp.SpecialCNetArea,0)+ISNULL(sp.CNetArea,0))/(CASE WHEN DATEDIFF(mm,sk.skdate,getdate()) in (0,1) THEN 1.0
    WHEN DATEDIFF(mm,sk.skdate,getdate()) = 2 THEN 2.0
    ELSE 3.0 END)/30  近三个月平均日流速_面积,
    datediff(dd,getdate(),convert(varchar(4),year(getdate()))+'-12-31')+1 距离年底天数,
    datediff(mm,getdate(),convert(varchar(4),year(getdate()))+'-12-31')+1 距离年底月份数,
    SUM(ISNULL(sp.SpecialCNetArea,0)+ISNULL(sp.CNetArea,0))/(CASE WHEN DATEDIFF(mm,sk.skdate,getdate()) in (0,1) THEN 1.0
    WHEN DATEDIFF(mm,sk.skdate,getdate()) = 2 THEN 2.0
    ELSE 3.0 END)/30 *(datediff(dd,getdate(),convert(varchar(4),year(getdate()))+'-12-31')+1) 预估去化面积,
    SUM(ISNULL(sp.SpecialCNetArea,0)+ISNULL(sp.CNetArea,0))/(CASE WHEN DATEDIFF(mm,sk.skdate,getdate()) in (0,1) THEN 1.0
    WHEN DATEDIFF(mm,sk.skdate,getdate()) = 2 THEN 2.0
    ELSE 3.0 END)*(datediff(mm,getdate(),convert(varchar(4),year(getdate()))+'-12-31')+1) 预估去化面积_按月份差
    INTO #avg_mj
    FROM [172.16.4.161].HighData_prod.dbo.data_wide_dws_s_SalesPerf sp
    INNER JOIN #sk sk ON sk.ParentProjGUID = sp.ParentProjGUID
        WHERE DATEDIFF(mm,sp.StatisticalDate,getdate()) BETWEEN 1 AND 3
    GROUP BY sp.BldGUID,sk.skdate;
    
    SELECT sb.gcbldguid, sb.salebldguid, zt.是否停工 
    into #isstop
    from mdm_salebuild sb 
    left join MyCost_Erp352.dbo.p_HkbBiddingBuilding2BuildingWork b on sb.gcbldguid = b.BuildingGUID
    left JOIN MyCost_Erp352.dbo.vp_HkbBiddingBuildingWork c ON b.BudGUID = c.BuildGUID 
    left join MyCost_Erp352.dbo.jd_PlanTaskExecuteObjectForReport zt on zt.ztguid = b.BudGUID

    --查询各楼栋货量数据
    --本年可售货量 =本年初剩余货量+本年可售货量
    --本年初剩余货量 = 总货量的预售证日期在本年之前-本年之前的销售金额，其中计算“本年之前总货量金额”用预售证日期判断，有实际的取实际没有取计划
    --本年之前销售金额=总销售金额-本年销售金额
        SELECT  bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                ld.ProjGUID ,
                ld.ProductType ,
                SUM(ld.zhz) / 10000 AS 总货值金额 ,
                SUM(ld.zksmj) AS 总货值面积 ,
                sum(ld.zksts) as 总货值套数,
                SUM(CASE WHEN  ld.SjYsblDate IS NOT NULL
                                  THEN ISNULL(ld.zksmj, 0)
                    END) AS 已取证面积 , 
                SUM(ld.ysje) / 10000 AS 已售货量金额 ,
                SUM(ld.ysmj) AS 已售货量面积 ,
                SUM(ld.ysts) AS 已售货量套数 ,
                SUM(ld.syhz) / 10000 AS 未销售部分货量 ,
                SUM(ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0)) AS 未销售部分可售面积 , 
				sum(isnull(ld.zksts,0)-isnull(ld.ysts,0)) as 未销售部分可售套数,
                SUM(case when isnull(st.是否停工,'') in ('停工','缓建') then ld.syhz else 0 end) / 10000 AS 停工缓建未销售部分货量 ,
                SUM(case when isnull(st.是否停工,'') in ('停工','缓建') then ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) else 0 end) AS 停工缓建未销售部分可售面积 , 
				sum(case when isnull(st.是否停工,'') in ('停工','缓建') then isnull(ld.zksts,0)-isnull(ld.ysts,0) else 0 end) as 停工缓建未销售部分可售套数,
                sum(case when qhmj.预估去化面积 is null then 0 when qhmj.预估去化面积 >ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) 
                then ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) else qhmj.预估去化面积 end) 剩余货值预估去化面积,
                sum(case when qhmj.预估去化面积 is null then 0 when qhmj.预估去化面积 >ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) 
                then ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) else qhmj.预估去化面积 end*isnull(ld.hzdj,0))/10000 剩余货值预估去化金额,
                sum(case when qhmj.预估去化面积_按月份差 is null then 0 when qhmj.预估去化面积_按月份差 >ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) 
                then ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) else qhmj.预估去化面积_按月份差 end) 剩余货值预估去化面积_按月份差,
                sum(case when qhmj.预估去化面积_按月份差 is null then 0 when qhmj.预估去化面积_按月份差 >ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) 
                then ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) else qhmj.预估去化面积_按月份差 end*isnull(ld.hzdj,0))/10000 剩余货值预估去化金额_按月份差,
                SUM(case when b.hl_type = '未开工' and datediff(dd,isnull(ld.Yjzskgdate,'2099-12-31'), dateadd(yy,3,getdate())) < 0  then ld.syhz else 0 end) / 10000 AS 未销售部分货量_三年内不开工 ,
                SUM(case when b.hl_type = '未开工' and datediff(dd,isnull(ld.Yjzskgdate,'2099-12-31'), dateadd(yy,3,getdate())) < 0  
                    then ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) else 0 end) AS 未销售部分可售面积_三年内不开工 , 
                SUM(case when b.hl_type = '未开工' and datediff(dd,isnull(ld.Yjzskgdate,'2099-12-31'), dateadd(yy,3,getdate())) < 0  
                    then isnull(ld.zksts,0)-isnull(ld.ysts,0) else 0 end) AS 未销售部分可售套数_三年内不开工 , 
                SUM(CASE WHEN  b.hl_type = '未开工' THEN ISNULL(ld.syhz, 0)  else 0 END) / 10000 未开工剩余货值金额,
                SUM(CASE WHEN  b.hl_type = '未开工' THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0)  else 0 END) 未开工剩余货值面积,
                SUM(CASE WHEN  b.hl_type = '未开工' THEN isnull(ld.zksts,0)-isnull(ld.ysts,0)  else 0 END) 未开工剩余货值套数,
                --在途货值：已开工未达预售形象
                SUM(CASE WHEN  (b.hl_type in ('已开工'))
                    THEN ISNULL(ld.syhz, 0) else 0  END) / 10000 在途剩余货值金额,   
                SUM(CASE WHEN (b.hl_type in ('已开工') ) 
                    THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0) else 0 END) 在途剩余货值面积, 
                SUM(CASE WHEN (b.hl_type in ('已开工') ) 
                    THEN isnull(ld.zksts,0)-isnull(ld.ysts,0) else 0 END) 在途剩余货值套数, 
                SUM(CASE WHEN  (b.hl_type in ('已开工') and isnull(st.是否停工,'') in ('停工','缓建') )
                    THEN ISNULL(ld.syhz, 0) else 0  END) / 10000 停工缓建在途剩余货值金额,  
                SUM(CASE WHEN (b.hl_type in ('已开工') ) and isnull(st.是否停工,'') in ('停工','缓建')  
                    THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0) else 0 END)  停工缓建在途剩余货值面积,  
                SUM(CASE WHEN (b.hl_type in ('已开工') ) and isnull(st.是否停工,'') in ('停工','缓建')  
                    THEN isnull(ld.zksts,0)-isnull(ld.ysts,0) else 0 END)  停工缓建在途剩余货值套数,      
                SUM(CASE WHEN ( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL )
                              OR ( b.hl_type IN ( '已完工已获证未推', '未完工已获证未推', '已完工已推待售', '未完工已推待售' ) )  
                    THEN ISNULL(ld.syhz, 0) else 0  END) / 10000 AS 剩余可售货值金额 , --待售货量 B1 + B2
                SUM(CASE WHEN ( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL )
                              OR ( b.hl_type IN ( '已完工已获证未推', '未完工已获证未推', '已完工已推待售', '未完工已推待售' ) )  
                    THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0) else 0 END) AS 剩余可售货值面积 , --待售货量
                SUM(CASE WHEN ( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL )
                              OR ( b.hl_type IN ( '已完工已获证未推', '未完工已获证未推', '已完工已推待售', '未完工已推待售' ) )  
                    THEN isnull(ld.zksts,0)-isnull(ld.ysts,0) else 0 END) AS 剩余可售货值套数 , --待售货量 
                SUM(CASE WHEN (( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL )
                              OR ( b.hl_type IN ( '已完工已获证未推', '未完工已获证未推', '已完工已推待售', '未完工已推待售' ) ))
                              and isnull(st.是否停工,'') in ('停工','缓建')  
                    THEN ISNULL(ld.syhz, 0) else 0  END) / 10000 AS 停工缓建剩余可售货值金额 , 
                SUM(CASE WHEN (( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL )
                              OR ( b.hl_type IN ( '已完工已获证未推', '未完工已获证未推', '已完工已推待售', '未完工已推待售' ) ))  
                              and isnull(st.是否停工,'') in ('停工','缓建') 
                    THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0) else 0 END) AS 停工缓建剩余可售货值面积 , 
                    SUM(CASE WHEN (( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL )
                              OR ( b.hl_type IN ( '已完工已获证未推', '未完工已获证未推', '已完工已推待售', '未完工已推待售' ) ))  
                              and isnull(st.是否停工,'') in ('停工','缓建') 
                    THEN isnull(ld.zksts,0)-isnull(ld.ysts,0) else 0 END) AS 停工缓建剩余可售货值套数 , 
                --本月情况
                ----已完工未推出未具备条件货量(B2-1)  + 未完工具备条件未获证货量(B1-1) 
                SUM(CASE WHEN ( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL)
                    THEN ISNULL(ld.syhz, 0) else 0 END) / 10000 AS 工程达到可售未拿证货值金额 ,
                SUM(CASE WHEN ( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL)
                    THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0) else 0 END) AS 工程达到可售未拿证货值面积 ,
                SUM(CASE WHEN ( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL)
                    THEN isnull(ld.zksts,0)-isnull(ld.ysts,0) else 0 END) AS 工程达到可售未拿证货值套数 ,
                SUM(CASE WHEN ( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL) and isnull(st.是否停工,'') in ('停工','缓建') 
                    THEN ISNULL(ld.syhz, 0) else 0 END) / 10000 AS 停工缓建工程达到可售未拿证货值金额,
                SUM(CASE WHEN ( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL) and isnull(st.是否停工,'') in ('停工','缓建') 
                    THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0) else 0 END) AS 停工缓建工程达到可售未拿证货值面积 ,
                SUM(CASE WHEN ( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL) and isnull(st.是否停工,'') in ('停工','缓建') 
                    THEN isnull(ld.zksts,0)-isnull(ld.ysts,0) else 0 END) AS 停工缓建工程达到可售未拿证货值套数 ,
                 ----已完工未推出具备条件货量(B2-2) + 未完工已获证待推货量(B1-2)
                SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推') 
                    THEN ISNULL(ld.syhz, 0) ELSE 0 END) / 10000 AS 获证未推货值金额 ,
                SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推') 
                    THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0) ELSE 0 END) AS 获证未推货值面积 ,
                SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推') 
                    THEN isnull(ld.zksts,0)-isnull(ld.ysts,0) ELSE 0 END) AS 获证未推货值套数 ,
                SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推') and  isnull(st.是否停工,'') in ('停工','缓建')
                    THEN ISNULL(ld.syhz, 0) ELSE 0 END) / 10000 AS 停工缓建获证未推货值金额 ,
                SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推') and  isnull(st.是否停工,'') in ('停工','缓建')
                    THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0) ELSE 0 END) AS 停工缓建获证未推货值面积 ,
                SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推') and  isnull(st.是否停工,'') in ('停工','缓建')
                    THEN isnull(ld.zksts,0)-isnull(ld.ysts,0) ELSE 0 END) AS 停工缓建获证未推货值套数 ,
               --产成品指竣工备案时间在本年1月1号前的楼栋
               --非车位产成品
                SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                              AND ld.ProductType <> '地下室/车库'
                              AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear
                         THEN ISNULL(ld.syhz, 0)
                         ELSE 0
                    END) / 10000 AS 获证未推产成品货值金额 ,
               --含车位产成品
               SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                              AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear
                         THEN ISNULL(ld.syhz, 0)
                         ELSE 0
                    END) / 10000 AS 获证未推产成品货值金额含车位 ,
               --含车位准产成品，竣工备案时间在明年1月1号之前
               SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                              AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear+1
                         THEN ISNULL(ld.syhz, 0)
                         ELSE 0
                    END) / 10000 AS 获证未推准产成品货值金额含车位 ,

        --车位指已取预售证节点但是没有放过盘的车位楼栋货值金额
                SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                              AND ld.ProductType = '地下室/车库'
                         THEN ISNULL(ld.syhz, 0)
                         ELSE 0
                    END) / 10000 AS 获证未推车位货值金额 ,
        --正常滚动指产成品及车位外的货值金额
                SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推') THEN ISNULL(ld.syhz, 0)
                         ELSE 0
                    END) / 10000
                - SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                                AND ld.ProductType <> '地下室/车库'
                                AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear
                           THEN ISNULL(ld.syhz, 0)
                           ELSE 0
                      END) / 10000
                - SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                                AND ld.ProductType = '地下室/车库'
                           THEN ISNULL(ld.syhz, 0)
                           ELSE 0
                      END) / 10000 AS 获证未推正常滚动货值金额 ,
           
                 ----已完工已推出待售货量（B2-3）  +   未完工已推待售货量(B1-3) 
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                         THEN ISNULL(ld.syhz, 0)
                         ELSE 0
                    END) / 10000 AS 已推未售货值金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                         THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0)
                         ELSE 0
                    END) AS 已推未售货值面积 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                         THEN ISNULL(ld.ytwsts, 0)
                         ELSE 0
                    END) AS 已推未售货值套数 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' ) and  isnull(st.是否停工,'') in ('停工','缓建')
                         THEN ISNULL(ld.syhz, 0)
                         ELSE 0
                    END) / 10000 AS 停工缓建已推未售货值金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' ) and  isnull(st.是否停工,'') in ('停工','缓建')
                         THEN ISNULL(ld.wtmj, 0) + ISNULL(ld.ytwsmj, 0)
                         ELSE 0
                    END) AS 停工缓建已推未售货值面积 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' ) and  isnull(st.是否停工,'') in ('停工','缓建')
                         THEN ISNULL(ld.ytwsts, 0)
                         ELSE 0
                    END) AS 停工缓建已推未售货值套数,
               --产成品指竣工备案时间在本年1月1号前的楼栋
               --非车位产成品
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                              AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear
                              AND ld.ProductType <> '地下室/车库'
                         THEN ISNULL(ld.syhz, 0)
                         ELSE 0
                    END) / 10000 AS 已推未售产成品货值金额 ,
               --含车位产成品
               SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                              AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear 
                         THEN ISNULL(ld.syhz, 0)
                         ELSE 0
                    END) / 10000 AS 已推未售产成品货值金额含车位 ,
               --准产成品
               SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                              AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear+1
                         THEN ISNULL(ld.syhz, 0)
                         ELSE 0
                    END) / 10000 AS 已推未售准产成品货值金额含车位 ,
        --车位指已取预售证节点但是没有放过盘的车位楼栋货值金额
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                              AND ld.ProductType = '地下室/车库'
                         THEN ISNULL(ld.syhz, 0)
                         ELSE 0
                    END) / 10000 AS 已推未售车位货值金额 ,
        --难销：除去产成品外，住宅首次放盘4个月后未售货值，公寓首次放盘6个月后未售货值
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                              AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) >=@bnYear
                              AND ( ( ld.ProductType = '住宅'
                                      AND DATEDIFF(mm,
                                                   ISNULL(r.thdate,
                                                          '2099-12-31'),
                                                   getdate()) > 4
                                    )
                                    OR ( ld.ProductType = '公寓'
                                         AND DATEDIFF(mm,
                                                      ISNULL(r.thdate,
                                                             '2099-12-31'),
                                                      getdate()) > 6
                                       )
                                  ) THEN ISNULL(ld.syhz, 0)
                         ELSE 0
                    END) / 10000 AS 已推未售难销货值金额 ,
        --正常滚动指产成品及车位，难销外的货值金额
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                         THEN ISNULL(ld.syhz, 0)
                         ELSE 0
                    END) / 10000
                - SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                                AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear
                                AND ld.ProductType <> '地下室/车库'
                           THEN ISNULL(ld.syhz, 0)
                           ELSE 0
                      END) / 10000
                - SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                                AND ld.ProductType = '地下室/车库'
                           THEN ISNULL(ld.syhz, 0)
                           ELSE 0
                      END) / 10000
                - SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                                AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) >=@bnYear
                                AND ( ( ld.ProductType = '住宅'
                                        AND DATEDIFF(mm,
                                                     ISNULL(r.thdate,
                                                            '2099-12-31'),
                                                     getdate()) > 4
                                      )
                                      OR ( ld.ProductType = '公寓'
                                           AND DATEDIFF(mm,
                                                        ISNULL(r.thdate,
                                                              '2099-12-31'),
                                                        getdate()) > 6
                                         )
                                    ) THEN ISNULL(ld.syhz, 0)
                           ELSE 0
                      END) / 10000 AS 已推未售正常滚动货值金额 , 
               --年初情况:预售证在年初1月1号之前，已售+剩余
               sum(isnull(ld.BeginYearSaleJe,0))/ 10000  as 年初动态货值,
               sum(isnull(ld.BeginYearSaleMj,0)) as 年初动态货值面积,
               sum(ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0))/ 10000 as 年初剩余货值  ,
               sum(ISNULL(ld.zksmj, 0) - ISNULL(ld.ysmj, 0)  + ISNULL(ld.ThisYearSaleMjQY, 0)) as 年初剩余货值面积  ,
               sum(isnull(nc.syhz,0))/ 10000 年初剩余货值_年初清洗版,
               sum(ISNULL(nc.zksmj, 0) - ISNULL(nc.ysmj, 0))年初剩余货值面积_年初清洗版,
               sum(case when nc.SjYsblDate is not null then isnull(nc.syhz,0) else 0 end)/ 10000 年初取证未售货值_年初清洗版,
               sum(case when nc.SjYsblDate is not null then ISNULL(nc.zksmj, 0) - ISNULL(nc.ysmj, 0) else 0 end) 年初取证未售面积_年初清洗版,
               sum(ISNULL(yd.ThisYearSaleJeQY, 0))/ 10000 本年已售货值_截止上月底清洗版,
               sum(ISNULL(yd.ThisYearSaleMjQY, 0)) 本年已售面积_截止上月底清洗版, 
               sum(case when yd.SjYsblDate is null then 0 else ISNULL(yd.syhz, 0) end)/ 10000 本年取证剩余货值_截止上月底清洗版,
               sum(case when yd.SjYsblDate is null then 0 else ISNULL(yd.ThisYearSaleMjQY, 0) end) 本年取证剩余面积_截止上月底清洗版,
               ----已完工未推出未具备条件货量(B2-1)  + 未完工具备条件未获证货量(B1-1) 
                SUM(CASE WHEN ( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL)
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate, '2099-12-31'),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                    END) / 10000 AS 年初工程达到可售未拿证货值金额 ,
                SUM(CASE WHEN ( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL)
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate, '2099-12-31'),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.zksmj, 0) - ISNULL(ld.ysmj, 0)
                              + ISNULL(ld.ThisYearSaleMjQY, 0)
                    END) AS 年初工程达到可售未拿证货值面积 ,

                                  ----已完工未推出具备条件货量(B2-2) + 未完工已获证待推货量(B1-2)
                SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                         ELSE 0
                    END) / 10000 AS 年初获证未推货值金额 ,
                SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.zksmj, 0) - ISNULL(ld.ysmj, 0)
                              + ISNULL(ld.ThisYearSaleMjQy, 0)
                         ELSE 0
                    END) AS 年初获证未推货值面积 ,

        --产成品指竣工备案时间在本年1月1号前的楼栋,放盘以获取预售证为准备
               --非车位产成品
                SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                              AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear
                              AND ld.ProductType <> '地下室/车库'
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                         ELSE 0
                    END) / 10000 AS 年初获证未推产成品货值金额 ,
               --含车位产成品
               SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                              AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear 
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                         ELSE 0
                    END) / 10000 AS 年初获证未推产成品货值金额含车位,
               --准产成品：竣工时间在明年1月1号前
               SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                              AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear + 1 
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                         ELSE 0
                    END) / 10000 AS 年初获证未推准产成品货值金额含车位,
               --车位指已取预售证节点但是没有放过盘的车位楼栋货值金额
                SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                              AND ld.ProductType = '地下室/车库'
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                         ELSE 0
                    END) / 10000 AS 年初获证未推车位货值金额 ,
        --正常滚动指产成品及车位外的货值金额
                SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                         ELSE 0
                    END) / 10000
                - SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                                AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear
                                AND ld.ProductType <> '地下室/车库'
                                AND DATEDIFF(dd,
                                             ISNULL(ld.SjYsblDate,
                                                    ISNULL(ld.YjYsblDate,
                                                           '2099-12-31')),
                                             DATEADD(yy,
                                                     DATEDIFF(yy, 0, getdate()),
                                                     0)) > 0
                           THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy,
                                                         0)
                           ELSE 0
                      END) / 10000
                - SUM(CASE WHEN b.hl_type in ('已完工已获证未推','未完工已获证未推')
                                AND ld.ProductType = '地下室/车库'
                                AND DATEDIFF(dd,
                                             ISNULL(ld.SjYsblDate,
                                                    ISNULL(ld.YjYsblDate,
                                                           '2099-12-31')),
                                             DATEADD(yy,
                                                     DATEDIFF(yy, 0, getdate()),
                                                     0)) > 0
                           THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy,
                                                         0)
                           ELSE 0
                      END) / 10000 AS 年初获证未推正常滚动货值金额 ,

                  ----已完工已推出待售货量（B2-3）  +   未完工已推待售货量(B1-3) 
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                         ELSE 0
                    END) / 10000 AS 年初已推未售货值金额 ,
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.zksmj, 0) - ISNULL(ld.ysmj, 0)
                              + ISNULL(ld.ThisYearSaleMjQy, 0)
                         ELSE 0
                    END) AS 年初已推未售货值面积 ,
        --产成品指竣工备案时间在本年1月1号前的楼栋
               --非车位产成品
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                              AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear
                              AND ld.ProductType <> '地下室/车库'
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                         ELSE 0
                    END) / 10000 AS 年初已推未售产成品货值金额 ,
               --含车位产成品
               SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                              AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear 
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                         ELSE 0
                    END) / 10000 AS 年初已推未售产成品货值金额含车位 ,
               --准产成品：竣工时间在明年1月1号之前
               --含车位产成品
               SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                              AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear + 1
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                         ELSE 0
                    END) / 10000 AS 年初已推未售准产成品货值金额含车位 ,
               --车位指已取预售证节点但是没有放过盘的车位楼栋货值金额
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                              AND ld.ProductType = '地下室/车库'
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                         ELSE 0
                    END) / 10000 AS 年初已推未售车位货值金额 ,
        --难销：除去产成品外，住宅首次放盘4个月后未售货值，公寓首次放盘6个月后未售货值
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                              AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) >=@bnYear
                              AND ( ( ld.ProductType = '住宅'
                                      AND DATEDIFF(mm,
                                                   ISNULL(r.thdate,
                                                          '2099-12-31'),
                                                   CONVERT(VARCHAR(4),YEAR(getdate()))+'-01-01') > 4
                                    )
                                    OR ( ld.ProductType = '公寓'
                                         AND DATEDIFF(mm,
                                                      ISNULL(r.thdate,
                                                             '2099-12-31'),
                                                      CONVERT(VARCHAR(4),YEAR(getdate()))+'-01-01') > 6
                                       )
                                  )
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                         ELSE 0
                    END) / 10000 AS 年初已推未售难销货值金额 ,
        --正常滚动指产成品及车位，难销外的货值金额
                SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                              AND DATEDIFF(dd,
                                           ISNULL(ld.SjYsblDate,
                                                  ISNULL(ld.YjYsblDate,
                                                         '2099-12-31')),
                                           DATEADD(yy,
                                                   DATEDIFF(yy, 0, getdate()),
                                                   0)) > 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                         ELSE 0
                    END) / 10000
                - SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                                AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) <@bnYear
                                AND ld.ProductType <> '地下室/车库'
                                AND DATEDIFF(dd,
                                             ISNULL(ld.SjYsblDate,
                                                    ISNULL(ld.YjYsblDate,
                                                           '2099-12-31')),
                                             DATEADD(yy,
                                                     DATEDIFF(yy, 0, getdate()),
                                                     0)) > 0
                           THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy,
                                                         0)
                           ELSE 0
                      END) / 10000
                - SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                                AND ld.ProductType = '地下室/车库'
                                AND DATEDIFF(dd,
                                             ISNULL(ld.SjYsblDate,
                                                    ISNULL(ld.YjYsblDate,
                                                           '2099-12-31')),
                                             DATEADD(yy,
                                                     DATEDIFF(yy, 0, getdate()),
                                                     0)) > 0
                           THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy,
                                                         0)
                           ELSE 0
                      END) / 10000
                - SUM(CASE WHEN b.hl_type IN ( '未完工已推待售', '已完工已推待售' )
                                AND YEAR(ISNULL(ld.SJjgbadate, '2099-12-31')) >=@bnYear
                                AND ( ( ld.ProductType = '住宅'
                                        AND DATEDIFF(mm,
                                                     ISNULL(r.thdate,
                                                            '2099-12-31'),
                                                     CONVERT(VARCHAR(4),YEAR(getdate()))+'-01-01') > 4
                                      )
                                      OR ( ld.ProductType = '公寓'
                                           AND DATEDIFF(mm,
                                                        ISNULL(r.thdate,
                                                              '2099-12-31'),
                                                        CONVERT(VARCHAR(4),YEAR(getdate()))+'-01-01') > 6
                                         )
                                    )
                                AND DATEDIFF(dd,
                                             ISNULL(ld.SjYsblDate,
                                                    ISNULL(ld.YjYsblDate,
                                                           '2099-12-31')),
                                             DATEADD(yy,
                                                     DATEDIFF(yy, 0, getdate()),
                                                     0)) > 0
                           THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy,
                                                         0)
                           ELSE 0
                      END) / 10000 AS 年初已推未售正常滚动货值金额 , 
                             
                 --本年总可售:预售证小于本年的剩余货值 + 预售证等于本年的剩余货值 + 本年已认购货值
                SUM(CASE WHEN DATEDIFF(yy,
                                       ISNULL(ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                              '2099-01-01'), getdate()) >= 0
                         THEN ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)
                         ELSE 0
                    END) / 10000 AS 本年可售货量金额 ,
               SUM(CASE WHEN DATEDIFF(yy,
                                       ISNULL(ISNULL(ld.SjYsblDate,ld.YjYsblDate),
                                              '2099-01-01'), getdate()) >= 0
                         THEN ISNULL(ld.zksmj, 0) - ISNULL(ld.ysmj, 0) + ISNULL(ld.ThisYearSaleMjQy, 0)
                         ELSE 0
                    END)  AS 本年可售货量面积 ,


                --本年新增货量：预售证等于本年  
                SUM(CASE WHEN DATEDIFF(yy,
                                       ISNULL(ISNULL(ld.SjYsblDate, ld.YjYsblDate),
                                              '2099-01-01'), getdate()) = 0
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS 本年新增货量金额 ,
                --预估本年本月及剩余月份新增货值
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ISNULL(ld.SjYsblDate, ld.YjYsblDate), '2099-01-01'), getdate()) <= 0
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                END) 预估本年取证新增货值,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ISNULL(ld.SjYsblDate, ld.YjYsblDate), '2099-01-01'), getdate()) <= 0
                         THEN ISNULL(ld.zksmj, 0) / 10000
                         ELSE 0
                END) 预估本年取证新增面积,
                 --本年情况：货量计划 
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-01-01') = 0
                              AND YEAR(ISNULL(ld.SjYsblDate, ld.YjYsblDate)) =@bnYear
                              AND ld.YjYsblDate < ISNULL(ld.SjYsblDate,
                                                         '2099-01-01')
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Jan预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.SjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-01-01') = 0
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Jan实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-02-01') = 0
                              AND YEAR(ISNULL(ld.SjYsblDate, ld.YjYsblDate)) =@bnYear
                              AND ld.YjYsblDate < ISNULL(ld.SjYsblDate,
                                                         '2099-01-01')
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Feb预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.SjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-02-01') = 0
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Feb实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-03-01') = 0
                              AND YEAR(ISNULL(ld.SjYsblDate, ld.YjYsblDate)) =@bnYear
                              AND ld.YjYsblDate < ISNULL(ld.SjYsblDate,
                                                         '2099-01-01')
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Mar预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.SjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-03-01') = 0
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Mar实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-04-01') = 0
                              AND YEAR(ISNULL(ld.SjYsblDate, ld.YjYsblDate)) =@bnYear
                              AND ld.YjYsblDate < ISNULL(ld.SjYsblDate,
                                                         '2099-01-01')
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Apr预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.SjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-04-01') = 0
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Apr实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-05-01') = 0
                              AND YEAR(ISNULL(ld.SjYsblDate, ld.YjYsblDate)) =@bnYear
                              AND ld.YjYsblDate < ISNULL(ld.SjYsblDate,
                                                         '2099-01-01')
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS May预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.SjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-05-01') = 0
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS May实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-06-01') = 0
                              AND YEAR(ISNULL(ld.SjYsblDate, ld.YjYsblDate)) =@bnYear
                              AND ld.YjYsblDate < ISNULL(ld.SjYsblDate,
                                                         '2099-01-01')
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Jun预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.SjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-06-01') = 0
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Jun实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-07-01') = 0
                              AND YEAR(ISNULL(ld.SjYsblDate, ld.YjYsblDate)) =@bnYear
                              AND ld.YjYsblDate < ISNULL(ld.SjYsblDate,
                                                         '2099-01-01')
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS July预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.SjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-07-01') = 0
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS July实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-08-01') = 0
                              AND YEAR(ISNULL(ld.SjYsblDate, ld.YjYsblDate)) =@bnYear
                              AND ld.YjYsblDate < ISNULL(ld.SjYsblDate,
                                                         '2099-01-01')
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Aug预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.SjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-08-01') = 0
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Aug实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-09-01') = 0
                              AND YEAR(ISNULL(ld.SjYsblDate, ld.YjYsblDate)) =@bnYear
                              AND ld.YjYsblDate < ISNULL(ld.SjYsblDate,
                                                         '2099-01-01')
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Sep预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.SjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-09-01') = 0
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Sep实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-10-01') = 0
                              AND ld.YjYsblDate < ISNULL(ld.SjYsblDate,
                                                         '2099-01-01')
                              AND YEAR(ISNULL(ld.SjYsblDate, ld.YjYsblDate)) =@bnYear
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Oct预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.SjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-10-01') = 0
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Oct实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-11-01') = 0
                              AND YEAR(ISNULL(ld.SjYsblDate, ld.YjYsblDate)) =@bnYear
                              AND ld.YjYsblDate < ISNULL(ld.SjYsblDate,
                                                         '2099-01-01')
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Nov预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.SjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-11-01') = 0
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Nov实际货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-12-01') = 0
                              AND YEAR(ISNULL(ld.SjYsblDate, ld.YjYsblDate)) =@bnYear
                              AND ld.YjYsblDate < ISNULL(ld.SjYsblDate,
                                                         '2099-01-01')
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Dec预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.SjYsblDate, '2099-01-01'),
                                       @bnYear
                                       + '-12-01') = 0
                         THEN ISNULL(ld.zhz, 0) / 10000
                         ELSE 0
                    END) AS Dec实际货量金额 , 

                --明年货量计划 
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 1)
                                       + '-01-01') = 0 
                     AND ld.SjYsblDate is null
                             THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 明年Jan预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 1)
                                       + '-02-01') = 0 
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 明年Feb预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 1)
                                       + '-03-01') = 0 
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 明年Mar预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 1)
                                       + '-04-01') = 0
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 明年Apr预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 1)
                                       + '-05-01') = 0
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 明年May预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 1)
                                       + '-06-01') = 0 
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 明年Jun预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 1)
                                       + '-07-01') = 0 
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 明年July预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 1)
                                       + '-08-01') = 0 
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 明年Aug预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 1)
                                       + '-09-01') = 0 
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 明年Sep预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 1)
                                       + '-10-01') = 0 
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 明年Oct预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 1)
                                       + '-11-01') = 0 
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 明年Nov预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 1)
                                       + '-12-01') = 0 
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 明年Dec预计货量金额 ,
                  
                --后年货量计划
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 2)
                                       + '-01-01') = 0 
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 后年Jan预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 2)
                                       + '-02-01') = 0 
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 后年Feb预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 2)
                                       + '-03-01') = 0 
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 后年Mar预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 2)
                                       + '-04-01') = 0
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 后年Apr预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 2)
                                       + '-05-01') = 0
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 后年May预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 2)
                                       + '-06-01') = 0
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 后年Jun预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 2)
                                       + '-07-01') = 0
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 后年July预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 2)
                                       + '-08-01') = 0
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 后年Aug预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 2)
                                       + '-09-01') = 0 
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 后年Sep预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 2)
                                       + '-10-01') = 0
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 后年Oct预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 2)
                                       + '-11-01') = 0
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 后年Nov预计货量金额 ,
                SUM(CASE WHEN DATEDIFF(mm, ISNULL(ld.YjYsblDate, '2099-01-01'),
                                       CONVERT(VARCHAR(4),@bnYear + 2)
                                       + '-12-01') = 0
                     AND ld.SjYsblDate is null THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 AS 后年Dec预计货量金额 ,
                ISNULL(ld.hzdj, 0) AS '预计售价' ,
                SUM(CASE WHEN DATEDIFF(yy,
                                       ISNULL(ISNULL(ld.SjYsblDate,ld.YjYsblDate),
                                              '2099-01-01'), getdate()) = 0
                              AND ld.ProductType = '地下室/车库'
                         THEN ISNULL(ld.zhz, 0)
                         ELSE 0
                    END) / 10000 今年车位可售金额 ,

        --获取楼栋的总建筑面积、地上/地下建筑面积、可售房源套数
        SUM(ISNULL(sb.UpBuildArea,0)+ISNULL(sb.DownBuildArea,0)) AS 总建筑面积,
        SUM(ISNULL(sb.UpBuildArea,0)) AS 地上建筑面积,
        SUM(ISNULL(sb.DownBuildArea,0)) AS 地下建筑面积,
        SUM(ISNULL(sb.HouseNum,0)) AS 可售房源套数,
        sum(isnull(ld.ysts,0)) AS 累计签约套数,
        sum(isnull(ld.ysmj,0))+sum(isnull(tui.累计推售面积,0)) 累计已推售面积,
        sum(isnull(ld.ysts,0))+sum(isnull(tui.累计推售套数,0)) 累计已推售套数,
        sum(isnull(ld.ysje,0))/10000.0+sum(isnull(tui.累计推售货值,0)) 累计已推售货值,
        sum(CASE  WHEN ld.SJzskgdate IS NOT NULL THEN isnull(ld.zhz,0) ELSE 0 end)/ 10000 已开工货值,
        SUM(ISNULL(jr.计容面积,0)) AS 计容面积
        INTO    #ldhz
        FROM    #p_lddb ld
        left join #isstop st on st.salebldguid = ld.salebldguid
        --获取年初版本的楼栋底表
        left join #nclddb nc on ld.salebldguid = nc.salebldguid
        --获取上月底版本的楼栋底表
        left join #ydlddb yd on yd.salebldguid = ld.salebldguid
        left join #avg_mj qhmj on ld.salebldguid = qhmj.bldguid
        LEFT JOIN #jr jr ON jr.BldGUID = ld.SaleBldGUID
                LEFT JOIN ( SELECT  SaleBldGUID ,
                                    CASE WHEN ISNULL(a.SJjgbadate,
                                                     '2099-01-01') < getdate()
                                              AND a.SJkpxsDate IS NOT NULL
                                         THEN '已完工已推待售'
                                         WHEN ISNULL(a.SJjgbadate, '2099-01-01') < getdate()
                                              and a.SjYsblDate is not null
                                         THEN '已完工已获证未推'
                                         WHEN ISNULL(a.SJjgbadate, '2099-01-01') < getdate()
                                         then '已完工未获证未推'
                                         WHEN a.SJkpxsDate IS NOT NULL
                                         THEN '未完工已推待售'
                                         WHEN a.SjYsblDate IS NOT NULL
                                         THEN '未完工已获证未推'
                                         WHEN a.SjDdysxxDate IS NOT NULL
                                         THEN '未完工未获证未推'
                                         WHEN a.SJzskgdate IS NOT NULL
                                         THEN '已开工'
                                         ELSE '未开工'
                                    END hl_type
                            FROM    #p_lddb a
                          ) b ON b.SaleBldGUID = ld.SaleBldGUID
        --获取楼栋的总建筑面积、地上/地下建筑面积、可售房源套数
            LEFT JOIN  dbo.mdm_SaleBuild sb ON sb.SaleBldGUID = ld.SaleBldGUID
                INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON ld.SaleBldGUID = bi.组织架构ID
                LEFT JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = ld.ProjGUID
                LEFT JOIN ( SELECT  BldGUID ,
                                    MIN(ThDate) AS thdate
                            FROM    erp25.dbo.p_room
                            GROUP BY BldGUID
                          ) r ON r.BldGUID = ld.SaleBldGUID
        --累计推售按照房间粒度来统计
        left join  #ts tui on tui.BldGUID = ld.SaleBldGUID  
        WHERE   bi.组织架构类型 = 5
                AND ld.ProjGUID NOT IN ( SELECT ProjGUID
                                         FROM   s_SaleValuePlanSet
                                         WHERE  IsPricePrediction = 2 )
        GROUP BY bi.组织架构ID ,
                bi.组织架构名称 ,
                bi.组织架构编码 ,
                bi.组织架构类型 ,
                ISNULL(ld.hzdj, 0) ,
                ld.ProjGUID ,
                ld.ProductType; 
         
 
  ---------------------业态粒度统计---------------------
 
    --货量看板的非操盘项目的“当前可售货量”和“其中”和“后续预计达成”和“今年后续预计达成”应该取货量铺排的数据； 
    /*
        统计已售货量要按这样的逻辑：
    1、非操盘项目，取合计项目业绩；
    2、尾盘项目（线下铺排），取销售系统已售业绩；
    3、新项目（线下铺排），取销售系统已售业绩；
    4、常规项目（线上铺排），取销售系统已售业绩；
       */
    --合并业态的值   
SELECT  bb.组织架构ID ,
bb.组织架构名称 ,
bb.组织架构编码 ,
bb.组织架构类型 ,
bb.ProjGUID ,
bb.ProductType ,
ISNULL(bb.zhz, 0) / 10000 AS 总货值金额 ,
ISNULL(bb.zksmj, 0) AS 总货值面积 ,
isnull(bb.zksts,0) as 总货值套数,
isnull(bb.yqzmj,0) as 已取证面积,
CASE WHEN ISNULL(bb.ysje, 0) <> 0 THEN ISNULL(bb.ysje, 0) / 10000 ELSE ISNULL(cc.累计销售金额, 0) END AS 已售货量金额 ,
CASE WHEN ISNULL(bb.ysmj, 0) <> 0 THEN ISNULL(bb.ysmj, 0)
     ELSE ISNULL(cc.累计销售面积, 0)
END AS 已售货量面积 ,
CASE WHEN ISNULL(bb.ysts, 0) <> 0 THEN ISNULL(bb.ysts, 0)
     ELSE ISNULL(cc.累计销售套数, 0)
END AS 已售货量套数 ,
CASE WHEN ISNULL(bb.ysje, 0) <> 0
     THEN ( ISNULL(bb.zhz, 0) - ISNULL(bb.ysje, 0) ) / 10000
     ELSE ISNULL(bb.zhz, 0) / 10000 - ISNULL(cc.累计销售金额, 0)
END AS 未销售部分货量 ,
CASE WHEN ISNULL(bb.ysmj, 0) <> 0
     THEN ( ISNULL(bb.zksmj, 0) - ISNULL(bb.ysmj, 0) )
     ELSE ISNULL(bb.zksmj, 0) - ISNULL(cc.累计销售面积, 0)
END AS 未销售部分可售面积 ,
CASE WHEN ISNULL(bb.ysts, 0) <> 0
     THEN ( ISNULL(bb.zksts, 0) - ISNULL(bb.ysts, 0) )
     ELSE ISNULL(bb.zksts, 0) - ISNULL(cc.累计销售套数, 0)
END AS 未销售部分可售套数 ,
isnull(bb.停工缓建未销售部分货量,0) / 10000 AS 停工缓建未销售部分货量 ,
isnull(bb.停工缓建未销售部分可售套数,0) AS 停工缓建未销售部分可售面积 , 
isnull(bb.停工缓建未销售部分可售套数,0) as 停工缓建未销售部分可售套数,
isnull(bb.剩余货值预估去化面积,0) as 剩余货值预估去化面积,
isnull(bb.剩余货值预估去化金额,0)/10000 as 剩余货值预估去化金额,
isnull(bb.剩余货值预估去化面积_按月份差,0) 剩余货值预估去化面积_按月份差,
isnull(bb.剩余货值预估去化金额_按月份差,0)/10000 as 剩余货值预估去化金额_按月份差,
0 AS 未销售部分货量_三年内不开工 ,
0 AS 未销售部分可售面积_三年内不开工 , 
0 as 未销售部分可售套数_三年内不开工 ,
0 AS 未开工剩余货值金额 ,
0 AS 未开工剩余货值面积 ,
0 as 未开工剩余货值套数, 
CASE WHEN ISNULL(bb.ysje, 0) <> 0 THEN ( ISNULL(bb.zhz, 0) - ISNULL(bb.ysje, 0) ) / 10000 ELSE ISNULL(bb.zhz, 0) / 10000 - ISNULL(cc.累计销售金额, 0)
END - ISNULL(aa.剩余可售货值金额, 0) / 10000  as 在途剩余货值金额, --剩余货值 -未开工 - 剩余可售
CASE WHEN ISNULL(bb.ysmj, 0) <> 0
     THEN ( ISNULL(bb.zksmj, 0) - ISNULL(bb.ysmj, 0) )
     ELSE ISNULL(bb.zksmj, 0) - ISNULL(cc.累计销售面积, 0)
END -ISNULL(aa.剩余可售货值面积, 0) as 在途剩余货值面积,
CASE WHEN ISNULL(bb.ysts, 0) <> 0
     THEN ( ISNULL(bb.zksts, 0) - ISNULL(bb.ysts, 0) )
     ELSE ISNULL(bb.zksts, 0) - ISNULL(cc.累计销售套数, 0)
END -ISNULL(bb.剩余可售货值套数, 0) as 在途剩余货值套数,
0 as 停工缓建在途剩余货值金额,
0 as 停工缓建在途剩余货值面积,
0 as 停工缓建在途剩余货值套数,
--湾区的谢立峰要求，手工导数的部分要按照货量铺排的来取，而不是按照系统的销售情况来算出剩余可售货值
ISNULL(aa.剩余可售货值金额, 0) / 10000 AS 剩余可售货值金额 ,
ISNULL(aa.剩余可售货值面积, 0) AS 剩余可售货值面积 ,
ISNULL(bb.剩余可售货值套数, 0) AS 剩余可售货值套数 ,
0 AS 停工缓建剩余可售货值金额 ,
0 AS 停工缓建剩余可售货值面积 ,
0 as 停工缓建剩余可售货值套数,
0 AS 工程达到可售未拿证货值金额 ,
0 AS 工程达到可售未拿证货值面积 ,
0 as 工程达到可售未拿证货值套数 ,
0 AS 停工缓建工程达到可售未拿证货值金额 ,
0 AS 停工缓建工程达到可售未拿证货值面积 ,
0 AS 停工缓建工程达到可售未拿证货值套数 ,
0 AS 获证未推货值金额 ,
0 AS 获证未推货值面积 ,
0 AS 获证未推货值套数 ,
0 AS 停工缓建获证未推货值金额 ,
0 AS 停工缓建获证未推货值面积 ,
0 AS 停工缓建获证未推货值套数 ,
0 AS 获证未推产成品货值金额 ,
0 AS 获证未推产成品货值金额含车位 ,
0 AS 获证未推准产成品货值金额含车位 ,
0 AS 获证未推车位货值金额 ,
0 AS 获证未推正常滚动货值金额 ,
ISNULL(aa.已推未售货值金额, 0) / 10000 AS 已推未售货值金额 ,
ISNULL(aa.已推未售货值面积, 0) AS 已推未售货值面积 ,
ISNULL(bb.剩余可售货值套数, 0) AS 已推未售货值套数 ,
0 as 停工缓建已推未售货值金额,
0 as 停工缓建已推未售货值面积,
0 as 停工缓建已推未售货值套数,
0 AS 已推未售产成品货值金额 ,
0 AS 已推未售产成品货值金额含车位 ,
0 AS 已推未售准产成品货值金额含车位 ,
ISNULL(aa.已推未售车位货值金额, 0) / 10000 AS 已推未售车位货值金额 ,
0 AS 已推未售难销货值金额 ,
ISNULL(aa.已推未售正常滚动货值金额, 0) / 10000 AS 已推未售正常滚动货值金额 ,
--年初情况
bb.年初动态货值/ 10000 年初动态货值, --楼栋底表的年初可售货值 - 合作特殊业绩本年之前的已售货值
bb.年初动态货值面积,
case when ISNULL(bb.ysje, 0) <> 0 then bb.年初剩余货值/ 10000 else ISNULL(bb.年初动态货值, 0) / 10000 - ISNULL(cc.累计销售金额, 0)+isnull(cc.本年销售金额,0) end as 年初剩余货值,
case when ISNULL(bb.ysmj, 0) <> 0 then bb.年初剩余货值面积 else ISNULL(bb.年初剩余货值面积, 0) - ISNULL(cc.累计销售面积, 0)+isnull(cc.本年销售面积,0) end as 年初剩余货值面积, 
bb.年初剩余货值_年初清洗版/ 10000 as 年初剩余货值_年初清洗版,
bb.年初剩余货值面积_年初清洗版,
bb.年初取证未售货值_年初清洗版/10000 as 年初取证未售货值_年初清洗版,
bb.年初取证未售面积_年初清洗版,
bb.本年已售货值_截止上月底清洗版/10000 as 本年已售货值_截止上月底清洗版,
bb.本年已售面积_截止上月底清洗版,
bb.本年取证剩余货值_截止上月底清洗版/10000 as 本年取证剩余货值_截止上月底清洗版,
bb.本年取证剩余面积_截止上月底清洗版,
0 AS 年初工程达到可售未拿证货值金额 ,
0 AS 年初工程达到可售未拿证货值面积 ,
ISNULL(aa.年初已推未售货值金额, 0) / 10000 AS 年初已推未售货值金额 ,
ISNULL(aa.年初已推未售货值面积, 0) AS 年初已推未售货值面积 , --年初情况：剩余+已售
0 AS 年初已推未售产成品货值金额 ,
0 AS 年初已推未售产成品货值金额含车位 ,
0 AS 年初已推未售准产成品货值金额含车位 ,
ISNULL(aa.年初已推未售车位货值金额, 0) / 10000 AS 年初已推未售车位货值金额 ,
0 AS 年初已推未售难销货值金额 ,
ISNULL(aa.年初已推未售正常滚动货值金额, 0) / 10000 AS 年初已推未售正常滚动货值金额 ,
0 AS 年初获证未推货值金额 ,
0 AS 年初获证未推货值面积 ,
0 AS 年初获证未推产成品货值金额 ,
0 AS 年初获证未推产成品货值金额含车位 ,
0 AS 年初获证未推准产成品货值金额含车位 ,
0 AS 年初获证未推车位货值金额 ,
0 AS 年初获证未推正常滚动货值金额 ,
ISNULL(aa.本年可售货量金额, 0) / 10000 AS 本年可售货量金额 ,
ISNULL(aa.本年可售货量面积, 0)  AS 本年可售货量面积 ,
ISNULL(aa.本年新增货量金额, 0) AS 本年新增货量金额 , 
--预估本年本月及剩余月份新增货值
isnull(aa.预估本年取证新增货值,0) as 预估本年取证新增货值,
isnull(aa.预估本年取证新增面积,0) as 预估本年取证新增面积,
--本年
ISNULL(aa.Jan预计货量金额, 0) Jan预计货量金额 ,
ISNULL(aa.Jan实际货量金额, 0) Jan实际货量金额 ,
ISNULL(aa.Feb预计货量金额, 0) Feb预计货量金额 ,
ISNULL(aa.Feb实际货量金额, 0) Feb实际货量金额 ,
ISNULL(aa.Mar预计货量金额, 0) Mar预计货量金额 ,
ISNULL(aa.Mar实际货量金额, 0) Mar实际货量金额 ,
ISNULL(aa.Apr预计货量金额, 0) Apr预计货量金额 ,
ISNULL(aa.Apr实际货量金额, 0) Apr实际货量金额 ,
ISNULL(aa.May预计货量金额, 0) May预计货量金额 ,
ISNULL(aa.May实际货量金额, 0) May实际货量金额 ,
ISNULL(aa.Jun预计货量金额, 0) Jun预计货量金额 ,
ISNULL(aa.Jun实际货量金额, 0) Jun实际货量金额 ,
ISNULL(aa.July预计货量金额, 0) July预计货量金额 ,
ISNULL(aa.July实际货量金额, 0) July实际货量金额 ,
ISNULL(aa.Aug预计货量金额, 0) Aug预计货量金额 ,
ISNULL(aa.Aug实际货量金额, 0) Aug实际货量金额 ,
ISNULL(aa.Sep预计货量金额, 0) Sep预计货量金额 ,
ISNULL(aa.Sep实际货量金额, 0) Sep实际货量金额 ,
ISNULL(aa.Oct预计货量金额, 0) Oct预计货量金额 ,
ISNULL(aa.Oct预计货量金额, 0) Oct实际货量金额 ,
ISNULL(aa.Nov预计货量金额, 0) Nov预计货量金额 ,
ISNULL(aa.Nov实际货量金额, 0) Nov实际货量金额 ,
ISNULL(aa.Dec预计货量金额, 0) Dec预计货量金额 ,
ISNULL(aa.Dec实际货量金额, 0) Dec实际货量金额 ,
--明年
ISNULL(aa.明年Jan预计货量金额, 0) / 10000 明年Jan预计货量金额 ,
ISNULL(aa.明年Feb预计货量金额, 0) / 10000 明年Feb预计货量金额 ,
ISNULL(aa.明年Mar预计货量金额, 0) / 10000 明年Mar预计货量金额 ,
ISNULL(aa.明年Apr预计货量金额, 0) / 10000 明年Apr预计货量金额 ,
ISNULL(aa.明年May预计货量金额, 0) / 10000 明年May预计货量金额 ,
ISNULL(aa.明年Jun预计货量金额, 0) / 10000 明年Jun预计货量金额 ,
ISNULL(aa.明年July预计货量金额, 0) / 10000 明年July预计货量金额 ,
ISNULL(aa.明年Aug预计货量金额, 0) / 10000 明年Aug预计货量金额 ,
ISNULL(aa.明年Sep预计货量金额, 0) / 10000 明年Sep预计货量金额 ,
ISNULL(aa.明年Oct预计货量金额, 0) / 10000 明年Oct预计货量金额 ,
ISNULL(aa.明年Nov预计货量金额, 0) / 10000 明年Nov预计货量金额 ,
ISNULL(aa.明年Dec预计货量金额, 0) / 10000 明年Dec预计货量金额 ,  
--后年
ISNULL(aa.后年Jan预计货量金额, 0) / 10000 后年Jan预计货量金额 ,
ISNULL(aa.后年Feb预计货量金额, 0) / 10000 后年Feb预计货量金额 ,
ISNULL(aa.后年Mar预计货量金额, 0) / 10000 后年Mar预计货量金额 ,
ISNULL(aa.后年Apr预计货量金额, 0) / 10000 后年Apr预计货量金额 ,
ISNULL(aa.后年May预计货量金额, 0) / 10000 后年May预计货量金额 ,
ISNULL(aa.后年Jun预计货量金额, 0) / 10000 后年Jun预计货量金额 ,
ISNULL(aa.后年July预计货量金额, 0) / 10000 后年July预计货量金额 ,
ISNULL(aa.后年Aug预计货量金额, 0) / 10000 后年Aug预计货量金额 ,
ISNULL(aa.后年Sep预计货量金额, 0) / 10000 后年Sep预计货量金额 ,
ISNULL(aa.后年Oct预计货量金额, 0) / 10000 后年Oct预计货量金额 ,
ISNULL(aa.后年Nov预计货量金额, 0) / 10000 后年Nov预计货量金额 ,
ISNULL(aa.后年Dec预计货量金额, 0) / 10000 后年Dec预计货量金额 ,
ISNULL(aa.今年车位可售金额, 0) / 10000 今年车位可售金额 ,
ISNULL(bb.总建筑面积,0) AS 总建筑面积,
ISNULL(bb.地上建筑面积,0) AS 地上建筑面积,
ISNULL(bb.地下建筑面积,0) AS 地下建筑面积,
ISNULL(bb.可售房源套数,0) AS 可售房源套数,
isnull(bb.ysts,0) AS 累计签约套数,
CASE WHEN ISNULL(bb.ysmj, 0) <> 0 THEN ISNULL(bb.ysmj, 0)
             ELSE ISNULL(cc.累计销售面积, 0)
        END+isnull(ts.累计推售面积,0) 累计已推售面积,
CASE WHEN ISNULL(bb.ysmj, 0) <> 0 THEN ISNULL(bb.ysmj, 0)
             ELSE ISNULL(cc.累计销售面积, 0)
        END+isnull(ts.累计推售套数,0) 累计已推售套数,
CASE WHEN ISNULL(bb.ysje, 0) <> 0
             THEN ISNULL(bb.ysje, 0) / 10000
             ELSE ISNULL(cc.累计销售金额, 0)
        END+isnull(ts.累计推售货值,0) 累计已推售货值,
isnull(已开工货值,0)/ 10000 已开工货值,
ISNULL(计容面积,0) AS 计容面积 
INTO    #ythz
FROM    ( ---总货量字段不要取手动导入的货量，要取楼栋底表的面积*单价；
SELECT    bi.组织架构父级ID ,
          bi.组织架构ID ,
          bi.组织架构名称 ,
          bi.组织架构编码 ,
          bi.组织架构类型 ,
          ld.ProjGUID ,
          ld.ProductType ,
          SUM(ld.zhz) AS zhz ,
          SUM(ld.zksmj) AS zksmj ,			
          SUM(ld.zksts) AS zksts ,
          sum(ld.ytwsts) as ytwsts,
          sum(ld.ytwsmj) as ytwsmj,
          sum(ld.ytwsje) as ytwsje,
          sum(ld.ysts) as ysts,
          SUM(ld.ysje) AS ysje ,
          SUM(ld.ysmj) AS ysmj, 
          sum(case when ld.SjYsblDate is not null then ld.zksmj else 0 end) as yqzmj, 
          
          SUM(case when isnull(st.是否停工,'') in ('停工','缓建') then ld.syhz else 0 end)  AS 停工缓建未销售部分货量 ,
          SUM(case when isnull(st.是否停工,'') in ('停工','缓建') then ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) else 0 end) AS 停工缓建未销售部分可售面积 , 
          sum(case when isnull(st.是否停工,'') in ('停工','缓建') then isnull(ld.zksts,0)-isnull(ld.ysts,0) else 0 end) as 停工缓建未销售部分可售套数,
          --年初
          sum(isnull(ld.BeginYearSaleJe,0)) as 年初动态货值,
          sum(isnull(ld.BeginYearSaleMj,0)) as 年初动态货值面积,
          sum(ISNULL(ld.syhz, 0) + ISNULL(ld.ThisYearSaleJeQy, 0)) as 年初剩余货值,
          sum( ISNULL(ld.zksmj, 0) - ISNULL(ld.ysmj, 0)  + ISNULL(ld.ThisYearSaleMjQY, 0)) as 年初剩余货值面积,
          sum(isnull(nc.syhz,0)) 年初剩余货值_年初清洗版,
          sum(ISNULL(nc.zksmj, 0) - ISNULL(nc.ysmj, 0))  年初剩余货值面积_年初清洗版,
          sum(case when nc.SjYsblDate is null then isnull(nc.syhz,0) else 0 end) 年初取证未售货值_年初清洗版,
          sum(case when nc.SjYsblDate is null then ISNULL(nc.zksmj, 0) - ISNULL(nc.ysmj, 0) else 0 end)年初取证未售面积_年初清洗版,
          sum(ISNULL(yd.ThisYearSaleJeQy, 0)) as 本年已售货值_截止上月底清洗版,
          sum(ISNULL(yd.ThisYearSaleMjQy, 0)) 本年已售面积_截止上月底清洗版,
          sum(case when yd.SjYsblDate is null then 0 else ISNULL(yd.syhz, 0) end) 本年取证剩余货值_截止上月底清洗版,
          sum(case when yd.SjYsblDate is null then 0 else ISNULL(yd.ThisYearSaleMjQY, 0) end) 本年取证剩余面积_截止上月底清洗版,
          --获取楼栋的总建筑面积、地上/地下建筑面积、可售房源套数
          SUM(ISNULL(sb.UpBuildArea,0)+ISNULL(sb.DownBuildArea,0)) AS 总建筑面积,
          SUM(ISNULL(sb.UpBuildArea,0)) AS 地上建筑面积,
          SUM(ISNULL(sb.DownBuildArea,0)) AS 地下建筑面积,
          SUM(ISNULL(sb.HouseNum,0)) AS 可售房源套数 ,
          sum(CASE  WHEN ld.SJzskgdate IS NOT NULL THEN isnull(ld.zhz,0) ELSE 0 end) 已开工货值, 
          sum(case when qhmj.预估去化面积 is null then 0 when qhmj.预估去化面积 >ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) 
          then ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) else qhmj.预估去化面积 end) 剩余货值预估去化面积,
          sum(case when qhmj.预估去化面积 is null then 0 when qhmj.预估去化面积 >ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) 
          then ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) else qhmj.预估去化面积 end*isnull(ld.hzdj,0)) 剩余货值预估去化金额,
          sum(case when qhmj.预估去化面积_按月份差 is null then 0 when qhmj.预估去化面积_按月份差 >ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) 
          then ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) else qhmj.预估去化面积_按月份差 end) 剩余货值预估去化面积_按月份差,
          sum(case when qhmj.预估去化面积_按月份差 is null then 0 when qhmj.预估去化面积_按月份差 >ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) 
          then ISNULL(ld.ytwsmj, 0) + ISNULL(ld.wtmj, 0) else qhmj.预估去化面积_按月份差 end*isnull(ld.hzdj,0)) as 剩余货值预估去化金额_按月份差,
          --套数先从楼栋底表取数
          SUM(CASE WHEN ( b.hl_type in ('已完工未获证未推','未完工未获证未推') AND ld.SjDdysxxDate IS not NULL )
                              OR ( b.hl_type IN ( '已完工已获证未推', '未完工已获证未推', '已完工已推待售', '未完工已推待售' ) )  
                    THEN isnull(ld.zksts,0)-isnull(ld.ysts,0) else 0 END) AS 剩余可售货值套数  
      FROM #p_lddb ld
          left join #nclddb nc on ld.salebldguid = nc.salebldguid
          left join #isstop st on st.salebldguid = ld.salebldguid
          left join #ydlddb yd on yd.salebldguid = ld.salebldguid
          LEFT JOIN dbo.mdm_Project mp ON ld.ProjGUID = mp.ProjGUID
          INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON ld.ProjGUID = bi.组织架构父级ID
                                            AND bi.组织架构名称 = ld.ProductType			LEFT JOIN dbo.mdm_SaleBuild sb ON sb.SaleBldGUID = ld.SaleBldGUID
          left join #avg_mj qhmj on qhmj.bldguid = ld.SaleBldGUID 
          LEFT JOIN ( SELECT  SaleBldGUID ,
                                    CASE WHEN ISNULL(a.SJjgbadate,
                                                     '2099-01-01') < getdate()
                                              AND a.SJkpxsDate IS NOT NULL
                                         THEN '已完工已推待售'
                                         WHEN ISNULL(a.SJjgbadate, '2099-01-01') < getdate()
                                              and a.SjYsblDate is not null
                                         THEN '已完工已获证未推'
                                         WHEN ISNULL(a.SJjgbadate, '2099-01-01') < getdate()
                                         then '已完工未获证未推'
                                         WHEN a.SJkpxsDate IS NOT NULL
                                         THEN '未完工已推待售'
                                         WHEN a.SjYsblDate IS NOT NULL
                                         THEN '未完工已获证未推'
                                         WHEN a.SjDdysxxDate IS NOT NULL
                                         THEN '未完工未获证未推'
                                         WHEN a.SJzskgdate IS NOT NULL
                                         THEN '已开工'
                                         ELSE '未开工'
                                    END hl_type
                            FROM    #p_lddb a
                          ) b ON b.SaleBldGUID = ld.SaleBldGUID
          WHERE  ld.ProjGUID IN ( SELECT ProjGUID FROM   s_SaleValuePlanSet WHERE  IsPricePrediction = 2 )
          AND bi.组织架构类型 = 4
GROUP BY  ld.ProjGUID ,
          ld.ProductType ,
          bi.组织架构父级ID ,
          bi.组织架构ID ,
          bi.组织架构名称 ,
          bi.组织架构编码 ,
          bi.组织架构类型
) bb
left join (select ParentProjGUID as projguid, ProductType,sum(isnull(累计推售面积,0)) as 累计推售面积,
            sum(isnull(累计推售套数,0)) as 累计推售套数,sum(isnull(累计推售货值,0)) as 累计推售货值
from #ts group by ParentProjGUID, ProductType) ts on bb.ProjGUID = ts.projguid and bb.ProductType = ts.ProductType
        LEFT JOIN ( SELECT  bi.组织架构父级ID ,
                            bi.组织架构ID ,
                            bi.组织架构名称 ,
                            bi.组织架构编码 ,
                            bi.组织架构类型 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = @byMonth
                                          )
                                     THEN ISNULL(a.ThisMonthTotalSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 剩余可售货值金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = @byMonth
                                          )
                                     THEN ISNULL(a.ThisMonthTotalSaleAreaQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 剩余可售货值面积 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = @byMonth
                                          )
                                     THEN ISNULL(a.ThisMonthTotalSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 已推未售货值金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = @byMonth
                                          )
                                     THEN ISNULL(a.ThisMonthTotalSaleAreaQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 已推未售货值面积 , 
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = @byMonth
                                            AND a.ProductType <> '地下室/车库'
                                          )
                                     THEN ISNULL(a.ThisMonthTotalSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 已推未售正常滚动货值金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = @byMonth
                                            AND a.ProductType = '地下室/车库'
                                          )
                                     THEN ISNULL(a.ThisMonthTotalSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 已推未售车位货值金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = 1
                                          )
                                     THEN ISNULL(a.EarlySaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 年初已推未售货值金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = 1
                                          )
                                     THEN ISNULL(a.EarlySaleAreaQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 年初已推未售货值面积 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = 1
                                            AND a.ProductType = '地下室/车库'
                                          )
                                     THEN ISNULL(a.EarlySaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 年初已推未售车位货值金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = 1
                                            AND a.ProductType <> '地下室/车库'
                                          )
                                     THEN ISNULL(a.EarlySaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 年初已推未售正常滚动货值金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = @byMonth
                                          )
                                     THEN ISNULL(a.YearTotalSumSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 本年可售货量金额 ,
                           SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = @byMonth
                                          )
                                     THEN ISNULL(a.YearTotalSumSaleAreaQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 本年可售货量面积 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS 本年新增货量金额 ,
                            --预估本年本月及剩余月份新增货值
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear and month(getdate())<=convert(int,SaleValuePlanMonth))
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) as 预估本年取证新增货值,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear and month(getdate())<=convert(int,SaleValuePlanMonth) )
                                     THEN ISNULL(a.YearTotalSumSaleAreaQzkj,
                                                 0)  
                                     ELSE 0
                                END) as 预估本年取证新增面积,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '1'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Jan预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '1'
                                            AND @byMonth >= SaleValuePlanMonth
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Jan实际货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '2'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Feb预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '2'
                                            AND @byMonth >= SaleValuePlanMonth
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Feb实际货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '3'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Mar预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '3'
                                            AND @byMonth >= SaleValuePlanMonth
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Mar实际货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '4'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Apr预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '4'
                                            AND @byMonth >= SaleValuePlanMonth
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Apr实际货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '5'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS May预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '5'
                                            AND @byMonth >= SaleValuePlanMonth
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS May实际货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '6'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Jun预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '6'
                                            AND @byMonth >= SaleValuePlanMonth
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Jun实际货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '7'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS July预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '7'
                                            AND @byMonth >= SaleValuePlanMonth
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS July实际货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '8'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Aug预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '8'
                                            AND @byMonth >= SaleValuePlanMonth
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Aug实际货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '9'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Sep预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '9'
                                            AND @byMonth >= SaleValuePlanMonth
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Sep实际货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '10'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Oct预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '10'
                                            AND @byMonth >= SaleValuePlanMonth
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Oct实际货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '11'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Nov预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '11'
                                            AND @byMonth >= SaleValuePlanMonth
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Nov实际货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '12'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Dec预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            AND SaleValuePlanMonth = '12'
                                            AND @byMonth >= SaleValuePlanMonth
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0) / 10000
                                     ELSE 0
                                END) AS Dec实际货量金额 ,
        --明年
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 1
                                            AND SaleValuePlanMonth = '1'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 明年Jan预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 1
                                            AND SaleValuePlanMonth = '2'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 明年Feb预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 1
                                            AND SaleValuePlanMonth = '3'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 明年Mar预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 1
                                            AND SaleValuePlanMonth = '4'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 明年Apr预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 1
                                            AND SaleValuePlanMonth = '5'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 明年May预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 1
                                            AND SaleValuePlanMonth = '6'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 明年Jun预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 1
                                            AND SaleValuePlanMonth = '7'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 明年July预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 1
                                            AND SaleValuePlanMonth = '8'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 明年Aug预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 1
                                            AND SaleValuePlanMonth = '9'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 明年Sep预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 1
                                            AND SaleValuePlanMonth = '10'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 明年Oct预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 1
                                            AND SaleValuePlanMonth = '11'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 明年Nov预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 1
                                            AND SaleValuePlanMonth = '12'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 明年Dec预计货量金额 ,
        --后年 
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 2
                                            AND SaleValuePlanMonth = '1'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 后年Jan预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 2
                                            AND SaleValuePlanMonth = '2'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 后年Feb预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 2
                                            AND SaleValuePlanMonth = '3'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 后年Mar预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 2
                                            AND SaleValuePlanMonth = '4'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 后年Apr预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 2
                                            AND SaleValuePlanMonth = '5'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 后年May预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 2
                                            AND SaleValuePlanMonth = '6'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 后年Jun预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 2
                                            AND SaleValuePlanMonth = '7'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 后年July预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 2
                                            AND SaleValuePlanMonth = '8'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 后年Aug预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 2
                                            AND SaleValuePlanMonth = '9'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 后年Sep预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 2
                                            AND SaleValuePlanMonth = '10'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 后年Oct预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 2
                                            AND SaleValuePlanMonth = '11'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 后年Nov预计货量金额 ,
                            SUM(CASE WHEN ( SaleValuePlanYear =@bnYear
                                            + 2
                                            AND SaleValuePlanMonth = '12'
                                          )
                                     THEN ISNULL(a.ThisMonthSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) AS 后年Dec预计货量金额 ,
                            SUM(CASE WHEN CHARINDEX('车', a.ProductType) > 0
                                     THEN ISNULL(a.YearTotalSumSaleMoneyQzkj,
                                                 0)
                                     ELSE 0
                                END) 今年车位可售金额
                    FROM    s_SaleValuePlan a
                            INNER JOIN erp25.dbo.mdm_Project mp ON mp.ProjGUID = a.ProjGUID
                            INNER JOIN erp25.dbo.ydkb_BaseInfo bi ON a.ProjGUID = bi.组织架构父级ID
                                                      AND bi.组织架构名称 = a.ProductType
                    WHERE   bi.组织架构类型 = 4
                            AND SaleValuePlanYear =@bnYear
                            AND a.ProjGUID IN (
                            SELECT  ProjGUID
                            FROM    s_SaleValuePlanSet
                            WHERE   IsPricePrediction = 2 )
                    GROUP BY bi.组织架构ID ,
                            bi.组织架构名称 ,
                            bi.组织架构编码 ,
                            bi.组织架构类型 ,
                            bi.组织架构父级ID
                  ) aa ON bb.ProjGUID = aa.组织架构父级ID
                          AND bb.ProductType = aa.组织架构名称
        LEFT JOIN ( SELECT  c.ProjGUID ,
                            a.ProductType ,
                            SUM(a.Amount) AS 累计销售金额 , --单位万元
                            SUM(a.Area) AS 累计销售面积 ,
                            sum(a.Taoshu) as 累计销售套数,
                            SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                   getdate()) = 0
                                     THEN a.Amount
                                     ELSE 0
                                END) AS 本年销售金额 ,
                            SUM(CASE WHEN DATEDIFF(yy, b.BizDate,
                                                   getdate()) = 0
                                     THEN a.Area
                                     ELSE 0
                                END) AS 本年销售面积
                    FROM    dbo.s_YJRLProducteDescript a
                            LEFT JOIN ( SELECT  * ,
                                                CONVERT(DATETIME, b.DateYear
                                                + '-' + b.DateMonth
                                                + '-01') AS [BizDate]
                                        FROM    dbo.s_YJRLProducteDetail b
                                      ) b ON b.ProducteDetailGUID = a.ProducteDetailGUID
                            LEFT JOIN dbo.s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
                            LEFT JOIN dbo.mdm_Project p ON p.ProjGUID = c.ProjGUID
                    WHERE   b.Shenhe = '审核'
                    GROUP BY c.ProjGUID ,
                            a.ProductType
                  ) cc ON cc.ProjGUID = bb.组织架构父级ID
                          AND cc.ProductType = bb.组织架构名称
LEFT JOIN (SELECT ParentProjGUID,ProductType,SUM(ISNULL(计容面积,0)) AS 计容面积 FROM #jr GROUP BY ParentProjGUID,ProductType) jr ON jr.ParentProjGUID = bb.组织架构父级ID AND jr.ProductType= bb.组织架构名称
   

      --获取合作业绩的情况
      SELECT a.ProductType,p.ProjGUID,
    SUM(a.Amount) - SUM(a.huilongjiner) AS 待收款金额,
    SUM(a.Amount) AS 累计签约额,
    SUM(a.Area) AS 累计签约面积,
    SUM(a.taoshu) AS 累计签约套数
    INTO #hzyj
    FROM    dbo.s_YJRLProducteDescript a
        LEFT JOIN dbo.s_YJRLProducteDetail b ON b.ProducteDetailGUID = a.ProducteDetailGUID
        LEFT JOIN dbo.s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
        LEFT JOIN dbo.mdm_Project p ON p.ProjGUID = c.ProjGUID
        LEFT JOIN dbo.p_DevelopmentCompany m ON m.DevelopmentCompanyGUID = p.DevelopmentCompanyGUID
    WHERE   b.Shenhe = '审核'  AND c.BUGuid IN (
        SELECT value FROM dbo.fn_Split2(@buguid,',')
        )
	--合作业绩已经录入到楼栋层级，因为打补丁，避免楼栋底表跟业绩表算了两遍
	and p.ProjGUID IN ( SELECT ProjGUID FROM s_SaleValuePlanSet WHERE IsPricePrediction =2 )
    GROUP BY a.ProductType,p.ProjGUID;  

        IF EXISTS ( SELECT  *
                    FROM    dbo.sysobjects
                    WHERE   id = OBJECT_ID(N'ydkb_dthz_wq_deal_salevalueinfo')
                            AND OBJECTPROPERTY(id, 'IsTable') = 1 )
            BEGIN
                DROP TABLE ydkb_dthz_wq_deal_salevalueinfo;
            END;
       

        --湾区PC端货量报表

        CREATE TABLE ydkb_dthz_wq_deal_salevalueinfo
            (
              组织架构父级ID UNIQUEIDENTIFIER ,
              组织架构ID UNIQUEIDENTIFIER ,
              组织架构名称 VARCHAR(400) ,
              组织架构编码 [VARCHAR](100) ,
              组织架构类型 [INT] ,

              /*总体情况*/
              总货值金额 MONEY ,             --总货值金额
              总货值面积 MONEY ,             --总货值面积
              总货值套数 int,
              已取证面积 Money,
              已售货量金额 MONEY ,            --已售货量金额
              已售货量面积 MONEY ,            --已售货量面积
              累计签约套数 MONEY, 
              累计已推售面积 MONEY, 
              累计已推售套数 MONEY, 
              累计已推售货值 MONEY, 
              已开工货值 money,
              剩余货值金额 MONEY ,
              剩余货值面积 MONEY ,
			  剩余货值套数 int,
              停工缓建剩余货值金额 money,
              停工缓建剩余货值面积 money, 
              停工缓建剩余货值套数 int,
              剩余货值预估去化面积 money,
              剩余货值预估去化金额 money,
              剩余货值预估去化面积_按月份差 money,
              剩余货值预估去化金额_按月份差 money,
              剩余货值金额_三年内不开工 MONEY ,
              剩余货值面积_三年内不开工 MONEY ,
              剩余货值套数_三年内不开工 int ,
              未开工剩余货值金额 money,
              未开工剩余货值面积 money,
              未开工剩余货值套数 int,
              在途剩余货值金额 money,
              在途剩余货值面积 money,
              在途剩余货值套数 int,
              停工缓建在途剩余货值金额 money,
              停工缓建在途剩余货值面积 money,
              停工缓建在途剩余货值套数 int,
              剩余可售货值金额 MONEY ,          --剩余可售货值金额C=C1+C2+C3（亿元）  
              剩余可售货值面积 MONEY ,          --剩余可售面积 
              剩余可售货值套数 int, 
              停工缓建剩余可售货值金额 MONEY ,            
              停工缓建剩余可售货值面积 MONEY ,  
              停工缓建剩余可售货值套数 int ,         
              工程达到可售未拿证货值金额 MONEY ,     --其中工程达到可售未拿证货值金额C1（亿元） 
              工程达到可售未拿证货值面积 MONEY ,     --其中工程达到可售未拿证货值面积 
              工程达到可售未拿证货值套数 int ,     
              停工缓建工程达到可售未拿证货值金额 MONEY ,
              停工缓建工程达到可售未拿证货值面积 MONEY ,
              停工缓建工程达到可售未拿证货值套数 int ,
              获证未推货值金额 MONEY ,          --其中获证未推货值金额C2（亿元）  
              获证未推货值面积 MONEY ,          --其中获证未推货值面积
              获证未推货值套数 int ,  
              停工缓建获证未推货值金额 MONEY ,
              停工缓建获证未推货值面积 MONEY ,
              停工缓建获证未推货值套数 int ,
              获证未推产成品货值金额 MONEY ,
              获证未推产成品货值金额含车位 MONEY ,
              获证未推准产成品货值金额含车位 MONEY ,
              获证未推正常滚动货值金额 MONEY ,
              获证未推车位货值金额 MONEY ,
              已推未售货值金额 MONEY ,          --其中已推未售货值金额C3（亿元）
              已推未售货值面积 MONEY ,          --其中已推未售货值面积
              已推未售货值套数 int,
              停工缓建已推未售货值金额 MONEY ,
              停工缓建已推未售货值面积 MONEY ,
              停工缓建已推未售货值套数 int ,
              已推未售产成品货值金额 MONEY ,
              已推未售产成品货值金额含车位 MONEY ,
              已推未售准产成品货值金额含车位 MONEY ,
              已推未售难销货值金额 MONEY ,
              已推未售正常滚动货值金额 MONEY ,
              已推未售车位货值金额 MONEY ,

               /*年初情况 采用往年达到预售条件本年剩余货量+往年达到预售条件本年已售货量反算年初可售货量*/
              年初动态货值 MONEY ,
              年初动态货值面积 MONEY ,
              年初剩余货值 MONEY ,
              年初剩余货值面积 MONEY ,
              年初剩余货值_年初清洗版 money,
              年初剩余货值面积_年初清洗版 money,
              年初取证未售货值_年初清洗版 money,
              年初取证未售面积_年初清洗版 money,
              本年已售货值_截止上月底清洗版 money,
              本年已售面积_截止上月底清洗版 money,
              本年取证剩余货值_截止上月底清洗版 money,
              本年取证剩余面积_截止上月底清洗版 money,
              年初工程达到可售未拿证货值金额 MONEY ,   --其中工程达到可售未拿证货值金额 （亿元）  
              年初工程达到可售未拿证货值面积 MONEY ,   --其中工程达到可售未拿证货值面积 
              年初获证未推货值金额 MONEY ,        --其中获证未推货值金额 （亿元） 
              年初获证未推货值面积 MONEY ,        --其中获证未推货值面积
        --获证未推分为三个类别：产成品、正常滚动、车位
              年初获证未推产成品货值金额 MONEY ,
              年初获证未推产成品货值金额含车位 MONEY ,
              年初获证未推准产成品货值金额含车位 MONEY ,
              年初获证未推正常滚动货值金额 MONEY ,
              年初获证未推车位货值金额 MONEY ,
              年初已推未售货值金额 MONEY ,        --其中已推未售货值金额 （亿元）
              年初已推未售货值面积 MONEY ,        --其中已推未售货值面积
        --已推未售分为四个类：产成品、难销、正常滚动、车位
              年初已推未售产成品货值金额 MONEY ,
              年初已推未售产成品货值金额含车位 MONEY ,
              年初已推未售准产成品货值金额含车位 MONEY ,
              年初已推未售难销货值金额 MONEY ,
              年初已推未售正常滚动货值金额 MONEY ,
              年初已推未售车位货值金额 MONEY ,
        /*本年新增计划*/
              本年新增货量 MONEY ,
			   预估本年取证新增货值 money,
			  预估本年取证新增面积 money,
        --1-12月的货量计划
              Jan预计货量金额 MONEY ,
              Jan实际货量金额 MONEY ,
              Feb预计货量金额 MONEY ,
              Feb实际货量金额 MONEY ,
              Mar预计货量金额 MONEY ,
              Mar实际货量金额 MONEY ,
              Apr预计货量金额 MONEY ,
              Apr实际货量金额 MONEY ,
              May预计货量金额 MONEY ,
              May实际货量金额 MONEY ,
              Jun预计货量金额 MONEY ,
              Jun实际货量金额 MONEY ,
              July预计货量金额 MONEY ,
              July实际货量金额 MONEY ,
              Aug预计货量金额 MONEY ,
              Aug实际货量金额 MONEY ,
              Sep预计货量金额 MONEY ,
              Sep实际货量金额 MONEY ,
              Oct预计货量金额 MONEY ,
              Oct实际货量金额 MONEY ,
              Nov预计货量金额 MONEY ,
              Nov实际货量金额 MONEY ,
              Dec预计货量金额 MONEY ,
              Dec实际货量金额 MONEY ,
              /*本年可售情况*/
              本年可售货量金额 MONEY ,
              本年可售货量面积 MONEY ,
              预计明年年初可售货量 MONEY ,
              本年有效货量 MONEY , -- 可售 - 车位 - 12月新增

        --明年新增货量
        --1-12月的货量计划
              明年Jan预计货量金额 MONEY ,
              明年Feb预计货量金额 MONEY ,
              明年Mar预计货量金额 MONEY ,
              明年Apr预计货量金额 MONEY ,
              明年May预计货量金额 MONEY ,
              明年Jun预计货量金额 MONEY ,
              明年July预计货量金额 MONEY ,
              明年Aug预计货量金额 MONEY ,
              明年Sep预计货量金额 MONEY ,
              明年Oct预计货量金额 MONEY ,
              明年Nov预计货量金额 MONEY ,
              明年Dec预计货量金额 MONEY ,

        --后年新增货量
        --1-12月的货量计划
              后年Jan预计货量金额 MONEY ,
              后年Feb预计货量金额 MONEY ,
              后年Mar预计货量金额 MONEY ,
              后年Apr预计货量金额 MONEY ,
              后年May预计货量金额 MONEY ,
              后年Jun预计货量金额 MONEY ,
              后年July预计货量金额 MONEY ,
              后年Aug预计货量金额 MONEY ,
              后年Sep预计货量金额 MONEY ,
              后年Oct预计货量金额 MONEY ,
              后年Nov预计货量金额 MONEY ,
              后年Dec预计货量金额 MONEY ,
              预计售价 MONEY,

        总建筑面积 MONEY,
        地上建筑面积 MONEY,
        地下建筑面积 MONEY,
        可售房源套数 MONEY,

        projguid UNIQUEIDENTIFIER,
        计容面积 MONEY,
        占地面积 MONEY,
        容积率 MONEY
            ); 

    --插入产品楼栋的值
        INSERT  INTO ydkb_dthz_wq_deal_salevalueinfo
                ( 组织架构父级ID ,
                  组织架构ID ,
                  组织架构名称 ,
                  组织架构编码 ,
                  组织架构类型 ,
                  总货值金额 ,
                  总货值面积 ,
                  总货值套数,
                  已取证面积,
                  已售货量金额 ,
                  已售货量面积 ,
                  累计签约套数 , 
                  累计已推售面积 , 
                  累计已推售套数 , 
                  累计已推售货值 , 
                  已开工货值,
                  剩余货值金额 ,
                  剩余货值面积 ,
				  剩余货值套数,
				  停工缓建剩余货值金额,
                  停工缓建剩余货值面积,
                  停工缓建剩余货值套数,
                  剩余货值预估去化面积 ,
                  剩余货值预估去化金额 ,
                  剩余货值预估去化面积_按月份差 ,
                  剩余货值预估去化金额_按月份差 ,
                  剩余货值金额_三年内不开工 ,
                  剩余货值面积_三年内不开工 ,
                  剩余货值套数_三年内不开工 ,
                  未开工剩余货值金额 ,
                  未开工剩余货值面积 ,
                  未开工剩余货值套数,
                  在途剩余货值金额,
                  在途剩余货值面积,
                  在途剩余货值套数,
                  停工缓建在途剩余货值金额,
                  停工缓建在途剩余货值面积,
                  停工缓建在途剩余货值套数,
                  剩余可售货值金额 ,
                  剩余可售货值面积 ,
                  剩余可售货值套数,
                  停工缓建剩余可售货值金额 ,
                  停工缓建剩余可售货值面积 ,
                  停工缓建剩余可售货值套数 ,
                  工程达到可售未拿证货值金额 ,
                  工程达到可售未拿证货值面积 ,
                  工程达到可售未拿证货值套数 ,
                  停工缓建工程达到可售未拿证货值金额 ,
                  停工缓建工程达到可售未拿证货值面积 ,
                  停工缓建工程达到可售未拿证货值套数 ,
                  获证未推货值金额 ,
                  获证未推货值面积 ,
                  获证未推货值套数 ,
                  停工缓建获证未推货值金额 ,
                  停工缓建获证未推货值面积 ,
                  停工缓建获证未推货值套数 ,
                  获证未推产成品货值金额 ,
                  获证未推产成品货值金额含车位 ,
                  获证未推准产成品货值金额含车位 ,
                  获证未推正常滚动货值金额 ,
                  获证未推车位货值金额 ,
                  已推未售货值金额 ,
                  已推未售货值面积 ,
                  已推未售货值套数 ,
                  停工缓建已推未售货值金额 ,
                  停工缓建已推未售货值面积 ,
                  停工缓建已推未售货值套数 ,
                  已推未售产成品货值金额 ,
                  已推未售产成品货值金额含车位 ,
                  已推未售准产成品货值金额含车位 ,
                  已推未售难销货值金额 ,
                  已推未售正常滚动货值金额 ,
                  已推未售车位货值金额 ,
                  年初动态货值,
                  年初动态货值面积,
                  年初剩余货值,
                  年初剩余货值面积,
                  年初剩余货值_年初清洗版,
                  年初剩余货值面积_年初清洗版,
                  年初取证未售货值_年初清洗版,
                  年初取证未售面积_年初清洗版,
                  本年已售货值_截止上月底清洗版,
                  本年已售面积_截止上月底清洗版,
                  本年取证剩余货值_截止上月底清洗版,
                  本年取证剩余面积_截止上月底清洗版,
                  年初工程达到可售未拿证货值金额 ,
                  年初工程达到可售未拿证货值面积 ,
                  年初获证未推货值金额 ,
                  年初获证未推货值面积 ,
                  年初获证未推产成品货值金额 ,
                  年初获证未推产成品货值金额含车位 ,
                  年初获证未推准产成品货值金额含车位 ,
                  年初获证未推正常滚动货值金额 ,
                  年初获证未推车位货值金额 ,
                  年初已推未售货值金额 ,        --其中已推未售货值金额 （亿元）
                  年初已推未售货值面积 ,        --其中已推未售货值面积
                  年初已推未售产成品货值金额 ,
                  年初已推未售产成品货值金额含车位 ,
                  年初已推未售准产成品货值金额含车位 ,
                  年初已推未售难销货值金额 ,
                  年初已推未售正常滚动货值金额 ,
                  年初已推未售车位货值金额 ,
                  本年新增货量 ,
				  预估本年取证新增货值,
				  预估本年取证新增面积,
                  Jan预计货量金额 ,
                  Jan实际货量金额 ,
                  Feb预计货量金额 ,
                  Feb实际货量金额 ,
                  Mar预计货量金额 ,
                  Mar实际货量金额 ,
                  Apr预计货量金额 ,
                  Apr实际货量金额 ,
                  May预计货量金额 ,
                  May实际货量金额 ,
                  Jun预计货量金额 ,
                  Jun实际货量金额 ,
                  July预计货量金额 ,
                  July实际货量金额 ,
                  Aug预计货量金额 ,
                  Aug实际货量金额 ,
                  Sep预计货量金额 ,
                  Sep实际货量金额 ,
                  Oct预计货量金额 ,
                  Oct实际货量金额 ,
                  Nov预计货量金额 ,
                  Nov实际货量金额 ,
                  Dec预计货量金额 ,
                  Dec实际货量金额 ,
                  本年可售货量金额 ,
                  本年可售货量面积 ,
                  预计明年年初可售货量 ,
                  本年有效货量 ,
                  明年Jan预计货量金额 ,
                  明年Feb预计货量金额 ,
                  明年Mar预计货量金额 ,
                  明年Apr预计货量金额 ,
                  明年May预计货量金额 ,
                  明年Jun预计货量金额 ,
                  明年July预计货量金额 ,
                  明年Aug预计货量金额 ,
                  明年Sep预计货量金额 ,
                  明年Oct预计货量金额 ,
                  明年Nov预计货量金额 ,
                  明年Dec预计货量金额 ,
                  后年Jan预计货量金额 ,
                  后年Feb预计货量金额 ,
                  后年Mar预计货量金额 ,
                  后年Apr预计货量金额 ,
                  后年May预计货量金额 ,
                  后年Jun预计货量金额 ,
                  后年July预计货量金额 ,
                  后年Aug预计货量金额 ,
                  后年Sep预计货量金额 ,
                  后年Oct预计货量金额 ,
                  后年Nov预计货量金额 ,
                  后年Dec预计货量金额 ,
                  预计售价,
                  总建筑面积,
                  地上建筑面积,
                  地下建筑面积,
                  可售房源套数,
                  projguid,
                  计容面积
                )
                SELECT  gc.GCBldGUID 组织架构父级ID ,
                        bi.组织架构ID ,
                        bi.组织架构名称 ,
                        bi.组织架构编码 ,
                        6 组织架构类型 ,
                        ld.总货值金额 ,
                        ld.总货值面积 ,
                        ld.总货值套数,
                        ld.已取证面积,
                        ld.已售货量金额 ,
                        ld.已售货量面积 ,
                        ld.累计签约套数 , 
                        ISNULL(ld.累计已推售面积,0) 累计已推售面积, 
                        ISNULL(ld.累计已推售套数,0) 累计已推售套数, 
                        ISNULL(ld.累计已推售货值,0) 累计已推售货值, 
                        已开工货值,
                        ld.未销售部分货量 剩余货值金额 ,
                        ld.未销售部分可售面积 剩余货值面积 ,
						ld.未销售部分可售套数 剩余货值套数 ,
                        ld.停工缓建未销售部分货量 as 停工缓建剩余货值金额,
                        ld.停工缓建未销售部分可售面积 as 停工缓建剩余货值面积,
                        ld.停工缓建未销售部分可售套数 as 停工缓建剩余货值套数, 
                        ld.剩余货值预估去化面积 ,
                        ld.剩余货值预估去化金额 ,
                        ld.剩余货值预估去化面积_按月份差 ,
                        ld.剩余货值预估去化金额_按月份差 ,
                        ld.未销售部分货量_三年内不开工 as 剩余货值金额_三年内不开工,
                        ld.未销售部分可售面积_三年内不开工 剩余货值面积_三年内不开工, 
                        ld.未销售部分可售套数_三年内不开工 剩余货值套数_三年内不开工, 
                        ld.未开工剩余货值金额 ,
                        ld.未开工剩余货值面积 ,
                        ld.未开工剩余货值套数 ,
                        ld.在途剩余货值金额,
                        ld.在途剩余货值面积,
                        ld.在途剩余货值套数,
                        ld.停工缓建在途剩余货值金额,
                        ld.停工缓建在途剩余货值面积,
                        ld.停工缓建在途剩余货值套数,
                        ld.剩余可售货值金额 ,
                        ld.剩余可售货值面积 ,
                        ld.剩余可售货值套数 ,
                        ld.停工缓建剩余可售货值金额 ,
                        ld.停工缓建剩余可售货值面积 ,
                        ld.停工缓建剩余可售货值套数 ,
                        ld.工程达到可售未拿证货值金额 ,
                        ld.工程达到可售未拿证货值面积 ,
                        ld.工程达到可售未拿证货值套数 ,
                        ld.停工缓建工程达到可售未拿证货值金额 ,
                        ld.停工缓建工程达到可售未拿证货值面积 ,
                        ld.停工缓建工程达到可售未拿证货值套数 ,
                        ld.获证未推货值金额 ,
                        ld.获证未推货值面积 ,
                        ld.获证未推货值套数 ,
                        ld.停工缓建获证未推货值金额 ,
                        ld.停工缓建获证未推货值面积 ,
                        ld.停工缓建获证未推货值套数 ,
                        ld.获证未推产成品货值金额 ,
                        ld.获证未推产成品货值金额含车位 ,
                        ld.获证未推准产成品货值金额含车位 ,
                        ld.获证未推正常滚动货值金额 ,
                        ld.获证未推车位货值金额 ,
                        ld.已推未售货值金额 ,
                        ld.已推未售货值面积 ,
                        ld.已推未售货值套数 ,
                        ld.停工缓建已推未售货值金额 ,
                        ld.停工缓建已推未售货值面积 ,
                        ld.停工缓建已推未售货值套数 ,
                        ld.已推未售产成品货值金额 ,
                        ld.已推未售产成品货值金额含车位,
                        ld.已推未售准产成品货值金额含车位,
                        ld.已推未售难销货值金额 ,
                        ld.已推未售正常滚动货值金额 ,
                        ld.已推未售车位货值金额 ,
                        ld.年初动态货值,
                        ld.年初动态货值面积,
                        ld.年初剩余货值,
                        ld.年初剩余货值面积,
                        ld.年初剩余货值_年初清洗版,
                        ld.年初剩余货值面积_年初清洗版,
                        ld.年初取证未售货值_年初清洗版,
                        ld.年初取证未售面积_年初清洗版,
                        ld.本年已售货值_截止上月底清洗版,
                        ld.本年已售面积_截止上月底清洗版,
                        ld.本年取证剩余货值_截止上月底清洗版,
                        ld.本年取证剩余面积_截止上月底清洗版,
                        ld.年初工程达到可售未拿证货值金额 ,
                        ld.年初工程达到可售未拿证货值面积 ,
                        ld.年初获证未推货值金额 ,
                        ld.年初获证未推货值面积 ,
                        ld.年初获证未推产成品货值金额 ,
                        ld.年初获证未推产成品货值金额含车位 ,
                        ld.年初获证未推准产成品货值金额含车位 ,
                        ld.年初获证未推正常滚动货值金额 ,
                        ld.年初获证未推车位货值金额 ,
                        ld.年初已推未售货值金额 ,        --其中已推未售货值金额 （亿元）      . d
                        ld.年初已推未售货值面积 ,        --其中已推未售货值面积
                        ld.年初已推未售产成品货值金额 ,
                        ld.年初已推未售产成品货值金额含车位 ,
                        ld.年初已推未售准产成品货值金额含车位 ,
                        ld.年初已推未售难销货值金额 ,
                        ld.年初已推未售正常滚动货值金额 ,
                        ld.年初已推未售车位货值金额 ,
                      
                        ld.本年新增货量金额 AS 本年新增货量 ,
                        ld.预估本年取证新增货值,
                        ld.预估本年取证新增面积,
                        ld.Jan预计货量金额 ,
                        ld.Jan实际货量金额 ,
                        ld.Feb预计货量金额 ,
                        ld.Feb实际货量金额 ,
                        ld.Mar预计货量金额 ,
                        ld.Mar实际货量金额 ,
                        ld.Apr预计货量金额 ,
                        ld.Apr实际货量金额 ,
                        ld.May预计货量金额 ,
                        ld.May实际货量金额 ,
                        ld.Jun预计货量金额 ,
                        ld.Jun实际货量金额 ,
                        ld.July预计货量金额 ,
                        ld.July实际货量金额 ,
                        ld.Aug预计货量金额 ,
                        ld.Aug实际货量金额 ,
                        ld.Sep预计货量金额 ,
                        ld.Sep实际货量金额 ,
                        ld.Oct预计货量金额 ,
                        ld.Oct实际货量金额 ,
                        ld.Nov预计货量金额 ,
                        ld.Nov实际货量金额 ,
                        ld.Dec预计货量金额 ,
                        ld.Dec实际货量金额 ,
                       
                        ld.本年可售货量金额 ,
                        ld.本年可售货量面积 ,
            --本年可售金额 - 本年销售金额
                        null 预计明年年初可售货量 ,
                        ld.本年可售货量金额 - ld.今年车位可售金额
                        - CASE WHEN ld.Dec实际货量金额 = 0 THEN ld.Dec预计货量金额
                               ELSE 0
                          END 本年有效货量 ,
                        ld.明年Jan预计货量金额 ,
                        ld.明年Feb预计货量金额 ,
                        ld.明年Mar预计货量金额 ,
                        ld.明年Apr预计货量金额 ,
                        ld.明年May预计货量金额 ,
                        ld.明年Jun预计货量金额 ,
                        ld.明年July预计货量金额 ,
                        ld.明年Aug预计货量金额 ,
                        ld.明年Sep预计货量金额 ,
                        ld.明年Oct预计货量金额 ,
                        ld.明年Nov预计货量金额 ,
                        ld.明年Dec预计货量金额 ,
                        ld.后年Jan预计货量金额 ,
                        ld.后年Feb预计货量金额 ,
                        ld.后年Mar预计货量金额 ,
                        ld.后年Apr预计货量金额 ,
                        ld.后年May预计货量金额 ,
                        ld.后年Jun预计货量金额 ,
                        ld.后年July预计货量金额 ,
                        ld.后年Aug预计货量金额 ,
                        ld.后年Sep预计货量金额 ,
                        ld.后年Oct预计货量金额 ,
                        ld.后年Nov预计货量金额 ,
                        ld.后年Dec预计货量金额 ,
                        ld.预计售价,
            ld.总建筑面积,
            ld.地上建筑面积,
            ld.地下建筑面积,
            ld.可售房源套数,
            pj.ParentProjGUID ProjGUID,
            ld.计容面积
            FROM    ydkb_BaseInfo bi
            left JOIN #ldhz ld ON ld.组织架构ID = bi.组织架构ID
            INNER JOIN  mdm_SaleBuild sb ON bi.组织架构ID = sb.SaleBldGUID
            INNER JOIN mdm_GCBuild gc ON sb.GCBldGUID = gc.GCBldGUID
			inner join mdm_Project pj on gc.ProjGUID = pj.ProjGUID
                WHERE   bi.组织架构类型 = 5 and bi.平台公司GUID  in (
    SELECT Value FROM dbo.fn_Split2(@developmentguid,',') )  ;  
    
    --插入工程楼栋的值
    INSERT  INTO ydkb_dthz_wq_deal_salevalueinfo
                ( 组织架构父级ID ,
                  组织架构ID ,
                  组织架构名称 ,
                  组织架构编码 ,
                  组织架构类型 ,
                  总货值金额 ,
                  总货值面积 ,
                  总货值套数,
                  已取证面积,
                  已售货量金额 ,
                  已售货量面积 ,
                  累计签约套数 , 
                  累计已推售面积 , 
                  累计已推售套数 , 
                  累计已推售货值 , 
                  已开工货值,
                  剩余货值金额 ,
                  剩余货值面积 ,
				  剩余货值套数,
                  停工缓建剩余货值金额,
                  停工缓建剩余货值面积,
                  停工缓建剩余货值套数,
                  剩余货值预估去化面积 ,
                  剩余货值预估去化金额 ,
                  剩余货值预估去化面积_按月份差 ,
                  剩余货值预估去化金额_按月份差 ,
                  剩余货值金额_三年内不开工 ,
                  剩余货值面积_三年内不开工 ,
                  剩余货值套数_三年内不开工 ,
                  未开工剩余货值金额,
                  未开工剩余货值面积,
                  未开工剩余货值套数 ,
                  在途剩余货值金额,
                  在途剩余货值面积,
                  在途剩余货值套数,
                  停工缓建在途剩余货值金额,
                  停工缓建在途剩余货值面积,
                  停工缓建在途剩余货值套数,
                  剩余可售货值金额 ,
                  剩余可售货值面积 ,
                  剩余可售货值套数,
                  停工缓建剩余可售货值金额 ,
                  停工缓建剩余可售货值面积 ,
                  停工缓建剩余可售货值套数 ,
                  工程达到可售未拿证货值金额 ,
                  工程达到可售未拿证货值面积 ,
                  工程达到可售未拿证货值套数 ,
                  停工缓建工程达到可售未拿证货值金额 ,
                  停工缓建工程达到可售未拿证货值面积 ,
                  停工缓建工程达到可售未拿证货值套数 ,
                  获证未推货值金额 ,
                  获证未推货值面积 ,
                  获证未推货值套数 ,
                  停工缓建获证未推货值金额 ,
                  停工缓建获证未推货值面积 ,
                  停工缓建获证未推货值套数 ,
                  获证未推产成品货值金额 ,
                  获证未推产成品货值金额含车位 ,
                  获证未推准产成品货值金额含车位 ,
                  获证未推正常滚动货值金额 ,
                  获证未推车位货值金额 ,
                  已推未售货值金额 ,
                  已推未售货值面积 ,
                  已推未售货值套数 ,
                  停工缓建已推未售货值金额 ,
                  停工缓建已推未售货值面积 ,
                  停工缓建已推未售货值套数 ,
                  已推未售产成品货值金额 ,
                  已推未售产成品货值金额含车位 ,
                  已推未售准产成品货值金额含车位 ,
                  已推未售难销货值金额 ,
                  已推未售正常滚动货值金额 ,
                  已推未售车位货值金额 ,
                  年初动态货值,
                  年初动态货值面积,
                  年初剩余货值,
                  年初剩余货值面积,
                  年初剩余货值_年初清洗版,
                  年初剩余货值面积_年初清洗版,
                  年初取证未售货值_年初清洗版,
                  年初取证未售面积_年初清洗版,
                  本年已售货值_截止上月底清洗版,
                  本年已售面积_截止上月底清洗版,
                  本年取证剩余货值_截止上月底清洗版,
                  本年取证剩余面积_截止上月底清洗版,
                  年初工程达到可售未拿证货值金额 ,
                  年初工程达到可售未拿证货值面积 ,
                  年初获证未推货值金额 ,
                  年初获证未推货值面积 ,
                  年初获证未推产成品货值金额 ,
                  年初获证未推产成品货值金额含车位 ,
                  年初获证未推准产成品货值金额含车位 ,
                  年初获证未推正常滚动货值金额 ,
                  年初获证未推车位货值金额 ,
                  年初已推未售货值金额 ,        --其中已推未售货值金额 （亿元）
                  年初已推未售货值面积 ,        --其中已推未售货值面积
                  年初已推未售产成品货值金额 ,
                  年初已推未售产成品货值金额含车位 ,
                  年初已推未售准产成品货值金额含车位 ,
                  年初已推未售难销货值金额 ,
                  年初已推未售正常滚动货值金额 ,
                  年初已推未售车位货值金额 ,
                  本年新增货量 ,
				  预估本年取证新增货值,
				  预估本年取证新增面积,
                  Jan预计货量金额 ,
                  Jan实际货量金额 ,
                  Feb预计货量金额 ,
                  Feb实际货量金额 ,
                  Mar预计货量金额 ,
                  Mar实际货量金额 ,
                  Apr预计货量金额 ,
                  Apr实际货量金额 ,
                  May预计货量金额 ,
                  May实际货量金额 ,
                  Jun预计货量金额 ,
                  Jun实际货量金额 ,
                  July预计货量金额 ,
                  July实际货量金额 ,
                  Aug预计货量金额 ,
                  Aug实际货量金额 ,
                  Sep预计货量金额 ,
                  Sep实际货量金额 ,
                  Oct预计货量金额 ,
                  Oct实际货量金额 ,
                  Nov预计货量金额 ,
                  Nov实际货量金额 ,
                  Dec预计货量金额 ,
                  Dec实际货量金额 ,
                  本年可售货量金额 ,
                  本年可售货量面积 ,
                  预计明年年初可售货量 ,
                  本年有效货量 ,
                  明年Jan预计货量金额 ,
                  明年Feb预计货量金额 ,
                  明年Mar预计货量金额 ,
                  明年Apr预计货量金额 ,
                  明年May预计货量金额 ,
                  明年Jun预计货量金额 ,
                  明年July预计货量金额 ,
                  明年Aug预计货量金额 ,
                  明年Sep预计货量金额 ,
                  明年Oct预计货量金额 ,
                  明年Nov预计货量金额 ,
                  明年Dec预计货量金额 ,
                  后年Jan预计货量金额 ,
                  后年Feb预计货量金额 ,
                  后年Mar预计货量金额 ,
                  后年Apr预计货量金额 ,
                  后年May预计货量金额 ,
                  后年Jun预计货量金额 ,
                  后年July预计货量金额 ,
                  后年Aug预计货量金额 ,
                  后年Sep预计货量金额 ,
                  后年Oct预计货量金额 ,
                  后年Nov预计货量金额 ,
                  后年Dec预计货量金额 ,
                  预计售价,
          总建筑面积,
          地上建筑面积,
            地下建筑面积,
            可售房源套数,
          projguid,
          计容面积
                )
                SELECT  bi.组织架构父级ID ,
                        gc.GCBldGUID 组织架构ID ,
                        gc.BldName 组织架构名称 ,
                        bi2.组织架构编码 ,
                        5 组织架构类型 ,
                        sum(isnull(ld.总货值金额,0)) as 总货值金额 ,
                        sum(isnull(ld.总货值面积,0)) as 总货值面积 ,
                        sum(isnull(ld.总货值套数,0)) as 总货值套数,
                        sum(isnull(ld.已取证面积,0)) as 已取证面积,
                        sum(isnull(ld.已售货量金额,0)) as 已售货量金额,
                        sum(isnull(ld.已售货量面积,0)) as 已售货量面积,
                        sum(isnull(累计签约套数 ,  0)) as  累计签约套数 ,  
                        sum(ISNULL(ld.累计已推售面积,0)) 累计已推售面积, 
                        sum(ISNULL(ld.累计已推售套数,0)) 累计已推售套数, 
                        sum(ISNULL(ld.累计已推售货值,0)) 累计已推售货值, 
                        sum(isnull(已开工货值 ,0)) as  已开工货值 ,
                        sum(isnull(ld.未销售部分货量,0)) AS  剩余货值金额 ,
                        sum(isnull(ld.未销售部分可售面积,0)) AS 剩余货值面积 ,
						sum(isnull(ld.未销售部分可售套数,0)) AS 剩余货值套数 ,
                        sum(isnull(ld.停工缓建未销售部分货量,0)) as 停工缓建未销售部分货量,
                        sum(isnull(ld.停工缓建未销售部分可售面积,0)) as 停工缓建未销售部分可售面积,
                        sum(isnull(ld.停工缓建未销售部分可售套数,0)) as 停工缓建未销售部分可售套数,
                        sum(isnull(ld.剩余货值预估去化面积,0)) AS 剩余货值预估去化面积 , 
                        sum(isnull(ld.剩余货值预估去化金额,0)) AS 剩余货值预估去化金额 , 
                        sum(isnull(ld.剩余货值预估去化面积_按月份差,0)) AS 剩余货值预估去化面积_按月份差 ,
                        sum(isnull(ld.剩余货值预估去化金额_按月份差,0)) AS 剩余货值预估去化金额_按月份差 ,
                        sum(isnull(ld.未销售部分货量_三年内不开工,0)) AS  剩余货值金额_三年内不开工  ,
                        sum(isnull(ld.未销售部分可售面积_三年内不开工,0)) AS 剩余货值面积_三年内不开工  ,
                        sum(isnull(ld.未销售部分可售套数_三年内不开工,0)) AS 剩余货值套数_三年内不开工  ,
                        sum(isnull(ld.未开工剩余货值金额,0)) AS 未开工剩余货值金额,
                        sum(isnull(ld.未开工剩余货值面积,0)) AS 未开工剩余货值面积,
                        sum(isnull(ld.未开工剩余货值套数,0)) AS 未开工剩余货值套数,
                        sum(isnull(ld.在途剩余货值金额,0)) as 在途剩余货值金额,
                        sum(isnull(ld.在途剩余货值面积,0)) as 在途剩余货值面积,
                        sum(isnull(ld.在途剩余货值套数,0)) as 在途剩余货值套数,
                        sum(isnull(ld.停工缓建在途剩余货值金额,0)) as 停工缓建在途剩余货值金额,
                        sum(isnull(ld.停工缓建在途剩余货值面积,0)) as 停工缓建在途剩余货值面积,
                        sum(isnull(ld.停工缓建在途剩余货值套数,0)) as 停工缓建在途剩余货值套数,
                        sum(isnull(ld.剩余可售货值金额 ,0)) AS 剩余可售货值金额,
                        sum(isnull(ld.剩余可售货值面积 ,0)) AS 剩余可售货值面积,
                        sum(isnull(ld.剩余可售货值套数 ,0)) AS 剩余可售货值套数,
                        sum(isnull(ld.停工缓建剩余可售货值金额 ,0)) AS 停工缓建剩余可售货值金额,
                        sum(isnull(ld.停工缓建剩余可售货值面积 ,0)) AS 停工缓建剩余可售货值面积,
                        sum(isnull(ld.停工缓建剩余可售货值套数 ,0)) AS 停工缓建剩余可售货值套数,
                        sum(isnull(ld.工程达到可售未拿证货值金额,0)) 工程达到可售未拿证货值金额,
                        sum(isnull(ld.工程达到可售未拿证货值面积,0)) 工程达到可售未拿证货值面积,
                        sum(isnull(ld.工程达到可售未拿证货值套数,0)) 工程达到可售未拿证货值套数,
                        sum(isnull(ld.停工缓建工程达到可售未拿证货值金额,0)) 停工缓建工程达到可售未拿证货值金额,
                        sum(isnull(ld.停工缓建工程达到可售未拿证货值面积,0)) 停工缓建工程达到可售未拿证货值面积,
                        sum(isnull(ld.停工缓建工程达到可售未拿证货值套数,0)) 停工缓建工程达到可售未拿证货值套数,
                        sum(isnull(ld.获证未推货值金额,0)) 获证未推货值金额 ,
                        sum(isnull(ld.获证未推货值面积,0)) 获证未推货值面积 ,
                        sum(isnull(ld.获证未推货值套数,0)) 获证未推货值套数 ,
                        sum(isnull(ld.停工缓建获证未推货值金额,0)) 停工缓建获证未推货值金额 ,
                        sum(isnull(ld.停工缓建获证未推货值面积,0)) 停工缓建获证未推货值面积 ,
                        sum(isnull(ld.停工缓建获证未推货值套数,0)) 停工缓建获证未推货值套数 ,
                        sum(isnull(ld.获证未推产成品货值金额,0)) AS 获证未推产成品货值金额,
                        sum(isnull(ld.获证未推产成品货值金额含车位,0)) AS 获证未推产成品货值金额含车位,
                        sum(isnull(ld.获证未推准产成品货值金额含车位,0)) AS 获证未推准产成品货值金额含车位,
                        sum(isnull(ld.获证未推正常滚动货值金额 ,0)) AS 获证未推正常滚动货值金额,
                        sum(isnull(ld.获证未推车位货值金额,0)) AS 获证未推车位货值金额 ,
                        sum(isnull(ld.已推未售货值金额,0))已推未售货值金额,
                        sum(isnull(ld.已推未售货值面积,0))已推未售货值面积,
                        sum(isnull(ld.已推未售货值套数,0))已推未售货值套数,
                        sum(isnull(ld.停工缓建已推未售货值金额,0))停工缓建已推未售货值金额,
                        sum(isnull(ld.停工缓建已推未售货值面积,0))停工缓建已推未售货值面积,
                        sum(isnull(ld.停工缓建已推未售货值套数,0))停工缓建已推未售货值套数,
                        sum(isnull(ld.已推未售产成品货值金额,0)) 已推未售产成品货值金额 ,
                        sum(isnull(ld.已推未售产成品货值金额含车位,0)) 已推未售产成品货值金额含车位 ,
                        sum(isnull(ld.已推未售准产成品货值金额含车位,0)) 已推未售准产成品货值金额含车位 ,
                        sum(isnull(ld.已推未售难销货值金额,0)) 已推未售难销货值金额,
                        sum(isnull(ld.已推未售正常滚动货值金额,0)) 已推未售正常滚动货值金额,
                        sum(isnull(ld.已推未售车位货值金额,0)) 已推未售车位货值金额,
                        sum(isnull(ld.年初动态货值,0)) 年初动态货值,
                        sum(isnull(ld.年初动态货值面积,0)) 年初动态货值面积,
                        sum(isnull(ld.年初剩余货值,0)) 年初剩余货值,
                        sum(isnull(ld.年初剩余货值面积,0)) 年初剩余货值面积,
                        sum(isnull(ld.年初剩余货值_年初清洗版,0)) 年初剩余货值_年初清洗版,
                        sum(ISNULL(ld.年初剩余货值面积_年初清洗版, 0))  年初剩余货值面积_年初清洗版,
                        sum(isnull(ld.年初取证未售货值_年初清洗版,0)) 年初取证未售货值_年初清洗版,
                        sum(isnull(ld.年初取证未售面积_年初清洗版,0)) 年初取证未售面积_年初清洗版,
                        sum(ISNULL(ld.本年已售货值_截止上月底清洗版, 0)) as 本年已售货值_截止上月底清洗版,
                        sum(ISNULL(ld.本年已售面积_截止上月底清洗版, 0)) 本年已售面积_截止上月底清洗版,
                        sum(ISNULL(ld.本年取证剩余货值_截止上月底清洗版, 0)) 本年取证剩余货值_截止上月底清洗版,
                        sum(ISNULL(ld.本年取证剩余面积_截止上月底清洗版, 0)) 本年取证剩余面积_截止上月底清洗版,
                        sum(isnull(ld.年初工程达到可售未拿证货值金额,0)) 年初工程达到可售未拿证货值金额,
                        sum(isnull(ld.年初工程达到可售未拿证货值面积,0)) 年初工程达到可售未拿证货值面积,
                        sum(isnull(ld.年初获证未推货值金额,0)) 年初获证未推货值金额,
                        sum(isnull(ld.年初获证未推货值面积,0)) 年初获证未推货值面积,
                        sum(isnull(ld.年初获证未推产成品货值金额,0))年初获证未推产成品货值金额 ,
                        sum(isnull(ld.年初获证未推产成品货值金额含车位,0))年初获证未推产成品货值金额含车位 ,
                        sum(isnull(ld.年初获证未推准产成品货值金额含车位,0))年初获证未推准产成品货值金额含车位 ,
                        sum(isnull(ld.年初获证未推正常滚动货值金额,0)) 年初获证未推正常滚动货值金额,
                        sum(isnull(ld.年初获证未推车位货值金额,0)) 年初获证未推车位货值金额,
                        sum(isnull(ld.年初已推未售货值金额,0)) 年初已推未售货值金额,        --其中已推未售货值金额 （亿元）      
                        sum(isnull(ld.年初已推未售货值面积,0)) 年初已推未售货值面积,        --其中已推未售货值面积
                        sum(isnull(ld.年初已推未售产成品货值金额,0)) 年初已推未售产成品货值金额,
                        sum(isnull(ld.年初已推未售产成品货值金额含车位,0)) 年初已推未售产成品货值金额含车位,
                        sum(isnull(ld.年初已推未售准产成品货值金额含车位,0)) 年初已推未售准产成品货值金额含车位,
                        sum(isnull(ld.年初已推未售难销货值金额,0)) 年初已推未售难销货值金额,
                        sum(isnull(ld.年初已推未售正常滚动货值金额,0)) 年初已推未售正常滚动货值金额,
                        sum(isnull(ld.年初已推未售车位货值金额,0)) 年初已推未售车位货值金额,
                        sum(isnull(ld.本年新增货量金额,0)) AS 本年新增货量 ,
                        --预估本年本月及剩余月份新增货值
                        SUM(isnull(ld.预估本年取证新增货值,0)) as 预估本年取证新增货值,
                        sum(isnull(ld.预估本年取证新增面积,0)) as 预估本年取证新增面积,
                        sum(isnull(ld.Jan预计货量金额,0)) Jan预计货量金额,
                        sum(isnull(ld.Jan实际货量金额,0)) Jan实际货量金额,
                        sum(isnull(ld.Feb预计货量金额,0)) Feb预计货量金额,
                        sum(isnull(ld.Feb实际货量金额,0)) Feb实际货量金额,
                        sum(isnull(ld.Mar预计货量金额,0)) Mar预计货量金额,
                        sum(isnull(ld.Mar实际货量金额,0)) Mar实际货量金额,
                        sum(isnull(ld.Apr预计货量金额,0)) Apr预计货量金额,
                        sum(isnull(ld.Apr实际货量金额,0)) Apr实际货量金额,
                        sum(isnull(ld.May预计货量金额,0)) May预计货量金额,
                        sum(isnull(ld.May实际货量金额,0)) May实际货量金额,
                        sum(isnull(ld.Jun预计货量金额,0)) Jun预计货量金额,
                        sum(isnull(ld.Jun实际货量金额,0)) Jun实际货量金额,
                        sum(isnull(ld.July预计货量金额,0)) July预计货量金额 ,
                        sum(isnull(ld.July实际货量金额,0)) July实际货量金额 ,
                        sum(isnull(ld.Aug预计货量金额 ,0)) Aug预计货量金额,
                        sum(isnull(ld.Aug实际货量金额 ,0)) Aug实际货量金额,
                        sum(isnull(ld.Sep预计货量金额 ,0)) Sep预计货量金额,
                        sum(isnull(ld.Sep实际货量金额 ,0)) Sep实际货量金额,
                        sum(isnull(ld.Oct预计货量金额 ,0)) Oct预计货量金额,
                        sum(isnull(ld.Oct实际货量金额 ,0)) Oct实际货量金额,
                        sum(isnull(ld.Nov预计货量金额 ,0)) Nov预计货量金额,
                        sum(isnull(ld.Nov实际货量金额 ,0)) Nov实际货量金额,
                        sum(isnull(ld.Dec预计货量金额 ,0)) Dec预计货量金额,
                        sum(isnull(ld.Dec实际货量金额 ,0)) Dec实际货量金额,
            sum(isnull(ld.本年可售货量金额 ,0)) 本年可售货量金额,
            sum(isnull(ld.本年可售货量面积 ,0)) 本年可售货量面积,
            null 预计明年年初可售货量 ,
                         sum(isnull(ld.本年可售货量金额 - ld.今年车位可售金额
                        - CASE WHEN ld.Dec实际货量金额 = 0 THEN ld.Dec预计货量金额
                               ELSE 0
                          END,0)) 本年有效货量 , 
                        sum(isnull(ld.明年Jan预计货量金额,0))  as 明年Jan预计货量金额  ,
            sum(isnull(ld.明年Feb预计货量金额,0)) as 明年Feb预计货量金额 ,
            sum(isnull(ld.明年Mar预计货量金额,0)) as 明年Mar预计货量金额 ,
            sum(isnull(ld.明年Apr预计货量金额,0)) as 明年Apr预计货量金额 ,
                        sum(isnull(ld.明年May预计货量金额,0))  as 明年May预计货量金额 , 
                        sum(isnull(ld.明年Jun预计货量金额,0))  as 明年Jun预计货量金额 ,
                        sum(isnull(ld.明年July预计货量金额,0)) as 明年July预计货量金额,
                        sum(isnull(ld.明年Aug预计货量金额,0)) as 明年Aug预计货量金额 ,
                        sum(isnull(ld.明年Sep预计货量金额,0)) as 明年Sep预计货量金额 ,
                        sum(isnull(ld.明年Oct预计货量金额,0)) as 明年Oct预计货量金额 ,
                        sum(isnull(ld.明年Nov预计货量金额,0)) as 明年Nov预计货量金额 ,
                        sum(isnull(ld.明年Dec预计货量金额,0)) as 明年Dec预计货量金额 ,
                        sum(isnull(ld.后年Jan预计货量金额,0)) as 后年Jan预计货量金额 ,
                        sum(isnull(ld.后年Feb预计货量金额,0)) as 后年Feb预计货量金额 ,
                        sum(isnull(ld.后年Mar预计货量金额,0)) as 后年Mar预计货量金额 ,
                        sum(isnull(ld.后年Apr预计货量金额,0)) as 后年Apr预计货量金额 ,
                        sum(isnull(ld.后年May预计货量金额,0)) as 后年May预计货量金额 ,
                        sum(isnull(ld.后年Jun预计货量金额,0)) as 后年Jun预计货量金额 ,
                        sum(isnull(ld.后年July预计货量金额,0)) AS 后年July预计货量金额,
                        sum(isnull(ld.后年Aug预计货量金额,0)) as 后年Aug预计货量金额 ,
                        sum(isnull(ld.后年Sep预计货量金额,0)) as 后年Sep预计货量金额 ,
                        sum(isnull(ld.后年Oct预计货量金额,0)) as 后年Oct预计货量金额 ,
                        sum(isnull(ld.后年Nov预计货量金额,0)) as 后年Nov预计货量金额 ,
                        sum(isnull(ld.后年Dec预计货量金额,0)) as 后年Dec预计货量金额 ,
                        NULL AS 预计售价,
            sum(isnull(ld.总建筑面积,0)) AS 总建筑面积,
            sum(isnull(ld.地上建筑面积,0)) as 地上建筑面积,
            sum(isnull(ld.地下建筑面积,0)) as 地下建筑面积,
            sum(isnull(ld.可售房源套数,0)) as 可售房源套数,
            pj.ParentProjGUID projguid,
            sum(isnull(ld.计容面积,0)) as 计容面积
                FROM    ydkb_BaseInfo bi
            left JOIN #ldhz ld ON ld.组织架构ID = bi.组织架构ID
            left JOIN  mdm_SaleBuild sb ON bi.组织架构ID = sb.SaleBldGUID
            left JOIN mdm_GCBuild gc ON sb.GCBldGUID = gc.GCBldGUID 
            LEFT JOIN dbo.mdm_Project pj ON pj.ProjGUID = gc.ProjGUID
            left JOIN dbo.mdm_Product pr ON pr.ProductGUID = sb.ProductGUID
            inner JOIN (SELECT DISTINCT 组织架构名称,组织架构父级ID,组织架构编码 FROM dbo.ydkb_BaseInfo) bi2 ON pr.ProductType = bi2.组织架构名称 AND pj.ParentProjGUID = bi2.组织架构父级ID

                WHERE   bi.组织架构类型 = 5 and bi.平台公司GUID  in ( SELECT Value FROM dbo.fn_Split2(@developmentguid,',') ) 
                GROUP BY bi.组织架构父级ID ,
                        gc.GCBldGUID  ,
                        gc.BldName  ,
                        bi2.组织架构编码,pj.ParentProjGUID; 

    --插入业态的值   
        INSERT  INTO ydkb_dthz_wq_deal_salevalueinfo
                ( 组织架构父级ID ,
                  组织架构ID ,
                  组织架构名称 ,
                  组织架构编码 ,
                  组织架构类型 ,
                  总货值金额 ,
                  总货值面积 ,
                  总货值套数,
                  已取证面积,
                  已售货量金额 ,
                  已售货量面积 ,
                  累计签约套数 , 
                  累计已推售面积 , 
                  累计已推售套数 , 
                  累计已推售货值 , 
                  已开工货值,
                  剩余货值金额 ,
                  剩余货值面积 ,
				  剩余货值套数,
                  停工缓建剩余货值金额,
                  停工缓建剩余货值面积,
                  停工缓建剩余货值套数,
                  剩余货值预估去化面积 ,
                  剩余货值预估去化金额 , 
                  剩余货值预估去化面积_按月份差 ,
                  剩余货值预估去化金额_按月份差 ,
                  剩余货值金额_三年内不开工 ,
                  剩余货值面积_三年内不开工 ,
                  剩余货值套数_三年内不开工 ,
                  未开工剩余货值金额,
                  未开工剩余货值面积,
                  未开工剩余货值套数,
                  在途剩余货值金额,
                  在途剩余货值面积,
                  在途剩余货值套数,
                  停工缓建在途剩余货值金额,
                  停工缓建在途剩余货值面积,
                  停工缓建在途剩余货值套数,
                  剩余可售货值金额 ,
                  剩余可售货值面积 ,
                  剩余可售货值套数,
                  停工缓建剩余可售货值金额 ,
                  停工缓建剩余可售货值面积 ,
                  停工缓建剩余可售货值套数,
                  工程达到可售未拿证货值金额 ,
                  工程达到可售未拿证货值面积 ,
                  工程达到可售未拿证货值套数 ,
                  停工缓建工程达到可售未拿证货值金额 ,
                  停工缓建工程达到可售未拿证货值面积 ,
                  停工缓建工程达到可售未拿证货值套数 ,
                  获证未推货值金额 ,
                  获证未推货值面积 ,
                  获证未推货值套数 ,
                  停工缓建获证未推货值金额 ,
                  停工缓建获证未推货值面积 ,
                  停工缓建获证未推货值套数 ,
                  获证未推产成品货值金额 ,
                  获证未推产成品货值金额含车位 ,
                  获证未推准产成品货值金额含车位 ,
                  获证未推正常滚动货值金额 ,
                  获证未推车位货值金额 ,
                  已推未售货值金额 ,
                  已推未售货值面积 ,
                  已推未售货值套数 ,
                  停工缓建已推未售货值金额 ,
                  停工缓建已推未售货值面积 ,
                  停工缓建已推未售货值套数 ,
                  已推未售产成品货值金额 ,
                  已推未售产成品货值金额含车位 ,
                  已推未售准产成品货值金额含车位 ,
                  已推未售难销货值金额 ,
                  已推未售正常滚动货值金额 ,
                  已推未售车位货值金额 ,
                  年初动态货值,
                  年初动态货值面积,
                  年初剩余货值,
                  年初剩余货值面积,
                  年初剩余货值_年初清洗版,
                  年初剩余货值面积_年初清洗版,
                  年初取证未售货值_年初清洗版,
                  年初取证未售面积_年初清洗版, 
                  本年已售货值_截止上月底清洗版,
                  本年已售面积_截止上月底清洗版,
                  本年取证剩余货值_截止上月底清洗版,
                  本年取证剩余面积_截止上月底清洗版,
                  年初工程达到可售未拿证货值金额 ,
                  年初工程达到可售未拿证货值面积 ,
                  年初获证未推货值金额 ,
                  年初获证未推货值面积 ,
                  年初获证未推产成品货值金额 ,
                  年初获证未推产成品货值金额含车位 ,
                  年初获证未推准产成品货值金额含车位 ,
                  年初获证未推正常滚动货值金额 ,
                  年初获证未推车位货值金额 ,
                  年初已推未售货值金额 ,        --其中已推未售货值金额 （亿元）
                  年初已推未售货值面积 ,        --其中已推未售货值面积
                  年初已推未售产成品货值金额 ,
                  年初已推未售产成品货值金额含车位 ,
                  年初已推未售准产成品货值金额含车位 ,
                  年初已推未售难销货值金额 ,
                  年初已推未售正常滚动货值金额 ,
                  年初已推未售车位货值金额 ,
                  本年新增货量 ,
				  预估本年取证新增货值,
				  预估本年取证新增面积,
                  Jan预计货量金额 ,
                  Jan实际货量金额 ,
                  Feb预计货量金额 ,
                  Feb实际货量金额 ,
                  Mar预计货量金额 ,
                  Mar实际货量金额 ,
                  Apr预计货量金额 ,
                  Apr实际货量金额 ,
                  May预计货量金额 ,
                  May实际货量金额 ,
                  Jun预计货量金额 ,
                  Jun实际货量金额 ,
                  July预计货量金额 ,
                  July实际货量金额 ,
                  Aug预计货量金额 ,
                  Aug实际货量金额 ,
                  Sep预计货量金额 ,
                  Sep实际货量金额 ,
                  Oct预计货量金额 ,
                  Oct实际货量金额 ,
                  Nov预计货量金额 ,
                  Nov实际货量金额 ,
                  Dec预计货量金额 ,
                  Dec实际货量金额 ,
                  本年可售货量金额 ,
                  本年可售货量面积 ,
                  预计明年年初可售货量 ,
                  本年有效货量 ,
                  明年Jan预计货量金额 ,
                  明年Feb预计货量金额 ,
                  明年Mar预计货量金额 ,
                  明年Apr预计货量金额 ,
                  明年May预计货量金额 ,
                  明年Jun预计货量金额 ,
                  明年July预计货量金额 ,
                  明年Aug预计货量金额 ,
                  明年Sep预计货量金额 ,
                  明年Oct预计货量金额 ,
                  明年Nov预计货量金额 ,
                  明年Dec预计货量金额 ,
                  后年Jan预计货量金额 ,
                  后年Feb预计货量金额 ,
                  后年Mar预计货量金额 ,
                  后年Apr预计货量金额 ,
                  后年May预计货量金额 ,
                  后年Jun预计货量金额 ,
                  后年July预计货量金额 ,
                  后年Aug预计货量金额 ,
                  后年Sep预计货量金额 ,
                  后年Oct预计货量金额 ,
                  后年Nov预计货量金额 ,
                  后年Dec预计货量金额 ,
                  预计售价,
          总建筑面积,
          地上建筑面积,
            地下建筑面积,
            可售房源套数,
          projguid,
          计容面积
                )
                SELECT  bi2.组织架构父级ID ,
                        bi2.组织架构ID ,
                        bi2.组织架构名称 ,
                        bi2.组织架构编码 ,
                        bi2.组织架构类型 , 
                        SUM(ISNULL(ld.总货值金额, 0) + ISNULL(yt.总货值金额, 0)) AS 总货值金额 ,
                        SUM(ISNULL(ld.总货值面积, 0) + ISNULL(yt.总货值面积, 0)) AS 总货值面积 , 
                        SUM(ISNULL(ld.总货值套数, 0) + ISNULL(yt.总货值套数, 0)) AS 总货值套数 , 
                        SUM(ISNULL(ld.已取证面积, 0) + ISNULL(yt.已取证面积, 0)) AS 已取证面积 ,
                        SUM(ISNULL(ld.已售货量金额, 0) + ISNULL(yt.已售货量金额, 0)) AS 已售货量金额 ,
                        SUM(ISNULL(ld.已售货量面积, 0) + ISNULL(yt.已售货量面积, 0)) AS 已售货量面积 ,
                        sum(isnull(ld.累计签约套数 ,  0)+isnull(yt.累计签约套数 ,  0)) as  累计签约套数 ,  
                        sum(ISNULL(ld.累计已推售面积,0)+ISNULL(yt.累计已推售面积,0)) as  累计已推售面积 ,
                        sum(ISNULL(ld.累计已推售套数,0)+ISNULL(yt.累计已推售套数,0)) as  累计已推售套数 ,
                        sum(ISNULL(ld.累计已推售货值,0)+ISNULL(yt.累计已推售货值,0)) as  累计已推售货值 ,
                        sum(isnull(ld.已开工货值 ,0)+isnull(yt.已开工货值 ,0)) as  已开工货值 ,
                        SUM(ISNULL(ld.未销售部分货量, 0) + ISNULL(yt.未销售部分货量, 0)) 剩余货值金额 ,
                        SUM(ISNULL(ld.未销售部分可售面积, 0) + ISNULL(yt.未销售部分可售面积, 0)) 剩余货值面积 ,
						SUM(ISNULL(ld.未销售部分可售套数, 0) + ISNULL(yt.未销售部分可售套数, 0)) 剩余货值套数 ,
                        SUM(ISNULL(ld.停工缓建未销售部分货量, 0) + ISNULL(yt.停工缓建未销售部分货量, 0)) 停工缓建未销售部分货量,
                        SUM(ISNULL(ld.停工缓建未销售部分可售面积, 0) + ISNULL(yt.停工缓建未销售部分可售面积, 0)) 停工缓建未销售部分可售面积,
                        SUM(ISNULL(ld.停工缓建未销售部分可售套数, 0) + ISNULL(yt.停工缓建未销售部分可售套数, 0)) 停工缓建未销售部分可售套数,
                        SUM(ISNULL(ld.剩余货值预估去化面积, 0) + ISNULL(yt.剩余货值预估去化面积, 0)) 剩余货值预估去化面积 ,
                        SUM(ISNULL(ld.剩余货值预估去化金额, 0) + ISNULL(yt.剩余货值预估去化金额, 0)) 剩余货值预估去化金额 , 
                        SUM(ISNULL(ld.剩余货值预估去化面积_按月份差, 0) + ISNULL(yt.剩余货值预估去化面积_按月份差, 0)) 剩余货值预估去化面积_按月份差 ,
                        SUM(ISNULL(ld.剩余货值预估去化金额_按月份差, 0) + ISNULL(yt.剩余货值预估去化金额_按月份差, 0)) 剩余货值预估去化金额_按月份差 ,
                        SUM(ISNULL(ld.未销售部分货量_三年内不开工, 0) + ISNULL(yt.未销售部分货量_三年内不开工, 0)) 剩余货值金额_三年内不开工 ,
                        SUM(ISNULL(ld.未销售部分可售面积_三年内不开工, 0) + ISNULL(yt.未销售部分可售面积_三年内不开工, 0)) 剩余货值面积_三年内不开工 ,
                        SUM(ISNULL(ld.未销售部分可售套数_三年内不开工, 0) + ISNULL(yt.未销售部分可售套数_三年内不开工, 0)) 剩余货值套数_三年内不开工 ,
                        SUM(ISNULL(ld.未开工剩余货值金额, 0) + ISNULL(yt.未开工剩余货值金额, 0)) AS 未开工剩余货值金额,
                        SUM(ISNULL(ld.未开工剩余货值面积, 0) + ISNULL(yt.未开工剩余货值面积, 0)) AS 未开工剩余货值面积,
                        SUM(ISNULL(ld.未开工剩余货值套数, 0) + ISNULL(yt.未开工剩余货值套数, 0)) AS 未开工剩余货值套数,
                        SUM(ISNULL(ld.在途剩余货值金额, 0) + ISNULL(yt.在途剩余货值金额, 0)) AS 在途剩余货值金额,
                        SUM(ISNULL(ld.在途剩余货值面积, 0) + ISNULL(yt.在途剩余货值面积, 0)) AS 在途剩余货值面积,
                        SUM(ISNULL(ld.在途剩余货值套数, 0) + ISNULL(yt.在途剩余货值套数, 0)) AS 在途剩余货值套数,
                        SUM(ISNULL(ld.停工缓建在途剩余货值金额, 0) + ISNULL(yt.停工缓建在途剩余货值金额, 0)) AS 停工缓建在途剩余货值金额,
                        SUM(ISNULL(ld.停工缓建在途剩余货值面积, 0) + ISNULL(yt.停工缓建在途剩余货值面积, 0)) AS 停工缓建在途剩余货值面积, 
                        SUM(ISNULL(ld.停工缓建在途剩余货值套数, 0) + ISNULL(yt.停工缓建在途剩余货值套数, 0)) AS 停工缓建在途剩余货值套数, 
                        SUM(ISNULL(ld.剩余可售货值金额, 0) + ISNULL(yt.剩余可售货值金额, 0)) AS 剩余可售货值金额 ,
                        SUM(ISNULL(ld.剩余可售货值面积, 0) + ISNULL(yt.剩余可售货值面积, 0)) AS 剩余可售货值面积 ,
                        SUM(ISNULL(ld.剩余可售货值套数, 0) + ISNULL(yt.剩余可售货值套数, 0)) AS 剩余可售货值套数 ,
                        SUM(ISNULL(ld.停工缓建剩余可售货值金额, 0) + ISNULL(yt.停工缓建剩余可售货值金额, 0)) AS 停工缓建剩余可售货值金额 ,
                        SUM(ISNULL(ld.停工缓建剩余可售货值面积, 0) + ISNULL(yt.停工缓建剩余可售货值面积, 0)) AS 停工缓建剩余可售货值面积 ,
                        SUM(ISNULL(ld.停工缓建剩余可售货值套数, 0) + ISNULL(yt.停工缓建剩余可售货值套数, 0)) AS 停工缓建剩余可售货值套数 ,
                        SUM(ISNULL(ld.工程达到可售未拿证货值金额, 0)
                            + ISNULL(yt.工程达到可售未拿证货值金额, 0)) AS 工程达到可售未拿证货值金额 ,
                        SUM(ISNULL(ld.工程达到可售未拿证货值面积, 0)
                            + ISNULL(yt.工程达到可售未拿证货值面积, 0)) AS 工程达到可售未拿证货值面积 ,
                        SUM(ISNULL(ld.工程达到可售未拿证货值套数 , 0)
                            + ISNULL(yt.工程达到可售未拿证货值套数 , 0)) AS 工程达到可售未拿证货值套数 ,
                        SUM(ISNULL(ld.停工缓建工程达到可售未拿证货值金额, 0)
                            + ISNULL(yt.停工缓建工程达到可售未拿证货值金额, 0)) AS 停工缓建工程达到可售未拿证货值金额 ,
                        SUM(ISNULL(ld.停工缓建工程达到可售未拿证货值面积, 0)
                            + ISNULL(yt.停工缓建工程达到可售未拿证货值面积, 0)) AS 停工缓建工程达到可售未拿证货值面积 ,
                        SUM(ISNULL(ld.停工缓建工程达到可售未拿证货值套数, 0)
                            + ISNULL(yt.停工缓建工程达到可售未拿证货值套数, 0)) AS 停工缓建工程达到可售未拿证货值套数 ,
                        SUM(ISNULL(ld.获证未推货值金额, 0) + ISNULL(yt.获证未推货值金额, 0)) AS 获证未推货值金额 ,
                        SUM(ISNULL(ld.获证未推货值面积, 0) + ISNULL(yt.获证未推货值面积, 0)) AS 获证未推货值面积 ,
                        SUM(ISNULL(ld.获证未推货值套数, 0) + ISNULL(yt.获证未推货值套数, 0)) AS 获证未推货值套数 ,
                        SUM(ISNULL(ld.停工缓建获证未推货值金额, 0) + ISNULL(yt.停工缓建获证未推货值金额, 0)) AS 停工缓建获证未推货值金额 ,
                        SUM(ISNULL(ld.停工缓建获证未推货值面积, 0) + ISNULL(yt.停工缓建获证未推货值面积, 0)) AS 停工缓建获证未推货值面积 ,
                        SUM(ISNULL(ld.停工缓建获证未推货值套数, 0) + ISNULL(yt.停工缓建获证未推货值套数, 0)) AS 停工缓建获证未推货值套数 ,
                        SUM(ISNULL(ld.获证未推产成品货值金额, 0) + ISNULL(yt.获证未推产成品货值金额,0)) AS 获证未推产成品货值金额 ,
                        SUM(ISNULL(ld.获证未推产成品货值金额含车位, 0) + ISNULL(yt.获证未推产成品货值金额含车位, 0)) AS 获证未推产成品货值金额含车位 ,
                        SUM(ISNULL(ld.获证未推准产成品货值金额含车位, 0) + ISNULL(yt.获证未推准产成品货值金额含车位,0)) AS 获证未推准产成品货值金额含车位 ,
                        SUM(ISNULL(ld.获证未推正常滚动货值金额, 0)
                            + ISNULL(yt.获证未推正常滚动货值金额, 0)) AS 获证未推正常滚动货值金额 ,
                        SUM(ISNULL(ld.获证未推车位货值金额, 0) + ISNULL(yt.获证未推车位货值金额, 0)) AS 获证未推车位货值金额 ,
                        SUM(ISNULL(ld.已推未售货值金额, 0) + ISNULL(yt.已推未售货值金额, 0)) AS 已推未售货值金额 ,
                        SUM(ISNULL(ld.已推未售货值面积, 0) + ISNULL(yt.已推未售货值面积, 0)) AS 已推未售货值面积 ,
                        SUM(ISNULL(ld.已推未售货值套数, 0) + ISNULL(yt.已推未售货值套数, 0)) AS 已推未售货值套数 ,
                        SUM(ISNULL(ld.停工缓建已推未售货值金额, 0) + ISNULL(yt.停工缓建已推未售货值金额, 0)) AS 停工缓建已推未售货值金额 ,
                        SUM(ISNULL(ld.停工缓建已推未售货值面积, 0) + ISNULL(yt.停工缓建已推未售货值面积, 0)) AS 停工缓建已推未售货值面积 ,
                        SUM(ISNULL(ld.停工缓建已推未售货值套数, 0) + ISNULL(yt.停工缓建已推未售货值套数, 0)) AS 停工缓建已推未售货值套数 ,
                        SUM(ISNULL(ld.已推未售产成品货值金额, 0) + ISNULL(yt.已推未售产成品货值金额,0)) AS 已推未售产成品货值金额 ,
                        SUM(ISNULL(ld.已推未售产成品货值金额含车位, 0) + ISNULL(yt.已推未售产成品货值金额含车位,0)) AS 已推未售产成品货值金额含车位 ,
                        SUM(ISNULL(ld.已推未售准产成品货值金额含车位, 0) + ISNULL(yt.已推未售准产成品货值金额含车位,0)) AS 已推未售准产成品货值金额含车位 ,
                        SUM(ISNULL(ld.已推未售难销货值金额, 0) + ISNULL(yt.已推未售难销货值金额, 0)) AS 已推未售难销货值金额 ,
                        SUM(ISNULL(ld.已推未售正常滚动货值金额, 0)
                            + ISNULL(yt.已推未售正常滚动货值金额, 0)) AS 已推未售正常滚动货值金额 ,
                        SUM(ISNULL(ld.已推未售车位货值金额, 0) + ISNULL(yt.已推未售车位货值金额, 0)) AS 已推未售车位货值金额 ,
                        SUM(ISNULL(ld.年初动态货值, 0)  + ISNULL(yt.年初动态货值, 0))  年初动态货值,
                        SUM(ISNULL(ld.年初动态货值面积, 0)  + ISNULL(yt.年初动态货值面积, 0))  年初动态货值面积,
                        SUM(ISNULL(ld.年初剩余货值, 0)  + ISNULL(yt.年初剩余货值, 0))  年初剩余货值,
                        SUM(ISNULL(ld.年初剩余货值面积, 0)  + ISNULL(yt.年初剩余货值面积, 0))  年初剩余货值面积,
                        sum(isnull(ld.年初剩余货值_年初清洗版,0)+ ISNULL(yt.年初剩余货值_年初清洗版, 0)) 年初剩余货值_年初清洗版,
                        sum(ISNULL(ld.年初剩余货值面积_年初清洗版, 0)+ ISNULL(yt.年初剩余货值面积_年初清洗版, 0))  年初剩余货值面积_年初清洗版,
                        sum(ISNULL(ld.年初取证未售货值_年初清洗版, 0)+ ISNULL(yt.年初取证未售货值_年初清洗版, 0)) 年初取证未售货值_年初清洗版,
                        sum(ISNULL(ld.年初取证未售面积_年初清洗版, 0)+ ISNULL(yt.年初取证未售面积_年初清洗版, 0)) 年初取证未售面积_年初清洗版, 
                        sum(ISNULL(ld.本年已售货值_截止上月底清洗版, 0)+ ISNULL(yt.本年已售货值_截止上月底清洗版, 0)) as 本年已售货值_截止上月底清洗版,
                        sum(ISNULL(ld.本年已售面积_截止上月底清洗版, 0)+ ISNULL(yt.本年已售面积_截止上月底清洗版, 0)) 本年已售面积_截止上月底清洗版,
                        sum(ISNULL(ld.本年取证剩余货值_截止上月底清洗版, 0)+ISNULL(yt.本年取证剩余货值_截止上月底清洗版, 0)) 本年取证剩余货值_截止上月底清洗版,
                        sum(ISNULL(ld.本年取证剩余面积_截止上月底清洗版, 0)+ISNULL(yt.本年取证剩余面积_截止上月底清洗版, 0)) 本年取证剩余面积_截止上月底清洗版,
                        SUM(ISNULL(ld.年初工程达到可售未拿证货值金额, 0)  + ISNULL(yt.年初工程达到可售未拿证货值金额, 0)) AS 年初工程达到可售未拿证货值金额 ,
                        SUM(ISNULL(ld.年初工程达到可售未拿证货值面积, 0)
                            + ISNULL(yt.年初工程达到可售未拿证货值面积, 0)) AS 年初工程达到可售未拿证货值面积 ,
                        SUM(ISNULL(ld.年初获证未推货值金额, 0) + ISNULL(yt.年初获证未推货值金额, 0)) AS 年初获证未推货值金额 , -- ISNULL(adjust.调整金额,0)) 
                        SUM(ISNULL(ld.年初获证未推货值面积, 0) + ISNULL(yt.年初获证未推货值面积, 0)) AS 年初获证未推货值面积 , -- ISNULL(adjust.调整面积,0)) 
                        SUM(ISNULL(ld.年初获证未推产成品货值金额, 0)+ ISNULL(yt.年初获证未推产成品货值金额, 0)) AS 年初获证未推产成品货值金额 ,
                        SUM(ISNULL(ld.年初获证未推产成品货值金额含车位, 0)+ ISNULL(yt.年初获证未推产成品货值金额含车位, 0)) AS 年初获证未推产成品货值金额含车位 ,
                        SUM(ISNULL(ld.年初获证未推准产成品货值金额含车位, 0)+ ISNULL(yt.年初获证未推准产成品货值金额含车位, 0)) AS 年初获证未推准产成品货值金额含车位 ,
                        SUM(ISNULL(ld.年初获证未推正常滚动货值金额, 0)
                            + ISNULL(yt.年初获证未推正常滚动货值金额, 0)) AS 年初获证未推正常滚动货值金额 , -- ISNULL(adjust.调整金额,0)
                        SUM(ISNULL(ld.年初获证未推车位货值金额, 0)
                            + ISNULL(yt.年初获证未推车位货值金额, 0)) AS 年初获证未推车位货值金额 ,
                        SUM(ISNULL(ld.年初已推未售货值金额, 0) + ISNULL(yt.年初已推未售货值金额, 0)) AS 年初已推未售货值金额 ,        --其中已推未售货值金额 （亿元）     
                        SUM(ISNULL(ld.年初已推未售货值面积, 0) + ISNULL(yt.年初已推未售货值面积, 0)) AS 年初已推未售货值面积 ,        --其中已推未售货值面积
                        SUM(ISNULL(ld.年初已推未售产成品货值金额, 0)+ ISNULL(yt.年初已推未售产成品货值金额, 0)) AS 年初已推未售产成品货值金额 ,
                        SUM(ISNULL(ld.年初已推未售产成品货值金额含车位, 0)+ ISNULL(yt.年初已推未售产成品货值金额含车位, 0)) AS 年初已推未售产成品货值金额含车位 ,
                        SUM(ISNULL(ld.年初已推未售准产成品货值金额含车位, 0)+ ISNULL(yt.年初已推未售准产成品货值金额含车位, 0)) AS 年初已推未售准产成品货值金额含车位 ,
                        SUM(ISNULL(ld.年初已推未售难销货值金额, 0)
                            + ISNULL(yt.年初已推未售难销货值金额, 0)) AS 年初已推未售难销货值金额 ,
                        SUM(ISNULL(ld.年初已推未售正常滚动货值金额, 0)
                            + ISNULL(yt.年初已推未售正常滚动货值金额, 0)) AS 年初已推未售正常滚动货值金额 ,
                        SUM(ISNULL(ld.年初已推未售车位货值金额, 0)
                            + ISNULL(yt.年初已推未售车位货值金额, 0)) AS 年初已推未售车位货值金额 ,
                        SUM(ISNULL(ld.本年新增货量, 0) + ISNULL(yt.本年新增货量金额, 0)) AS 本年新增货量 ,
                        --预估本年本月及剩余月份新增货值
                        SUM(isnull(ld.预估本年取证新增货值,0)+isnull(yt.预估本年取证新增货值,0)) as 预估本年取证新增货值,
                        sum(isnull(ld.预估本年取证新增面积,0)+isnull(yt.预估本年取证新增面积,0)) as 预估本年取证新增面积,
                        SUM(ISNULL(ld.Jan预计货量金额, 0) + ISNULL(yt.Jan预计货量金额, 0)) AS Jan预计货量金额 ,
                        SUM(ISNULL(ld.Jan实际货量金额, 0) + ISNULL(yt.Jan实际货量金额, 0)) AS Jan实际货量金额 ,
                        SUM(ISNULL(ld.Feb预计货量金额, 0) + ISNULL(yt.Feb预计货量金额, 0)) AS Feb预计货量金额 ,
                        SUM(ISNULL(ld.Feb实际货量金额, 0) + ISNULL(yt.Feb实际货量金额, 0)) AS Feb实际货量金额 ,
                        SUM(ISNULL(ld.Mar预计货量金额, 0) + ISNULL(yt.Mar预计货量金额, 0)) AS Mar预计货量金额 ,
                        SUM(ISNULL(ld.Mar实际货量金额, 0) + ISNULL(yt.Mar实际货量金额, 0)) AS Mar实际货量金额 ,
                        SUM(ISNULL(ld.Apr预计货量金额, 0) + ISNULL(yt.Apr预计货量金额, 0)) AS Apr预计货量金额 ,
                        SUM(ISNULL(ld.Apr实际货量金额, 0) + ISNULL(yt.Apr实际货量金额, 0)) AS Apr实际货量金额 ,
                        SUM(ISNULL(ld.May预计货量金额, 0) + ISNULL(yt.May预计货量金额, 0)) AS May预计货量金额 ,
                        SUM(ISNULL(ld.May实际货量金额, 0) + ISNULL(yt.May实际货量金额, 0)) AS May实际货量金额 ,
                        SUM(ISNULL(ld.Jun预计货量金额, 0) + ISNULL(yt.Jun预计货量金额, 0)) AS Jun预计货量金额 ,
                        SUM(ISNULL(ld.Jun实际货量金额, 0) + ISNULL(yt.Jun实际货量金额, 0)) AS Jun实际货量金额 ,
                        SUM(ISNULL(ld.July预计货量金额, 0) + ISNULL(yt.July预计货量金额, 0)) AS July预计货量金额 ,
                        SUM(ISNULL(ld.July实际货量金额, 0) + ISNULL(yt.July实际货量金额, 0)) AS July实际货量金额 ,
                        SUM(ISNULL(ld.Aug预计货量金额, 0) + ISNULL(yt.Aug预计货量金额, 0)) AS Aug预计货量金额 ,
                        SUM(ISNULL(ld.Aug实际货量金额, 0) + ISNULL(yt.Aug实际货量金额, 0)) AS Aug实际货量金额 ,
                        SUM(ISNULL(ld.Sep预计货量金额, 0) + ISNULL(yt.Sep预计货量金额, 0)) AS Sep预计货量金额 ,
                        SUM(ISNULL(ld.Sep实际货量金额, 0) + ISNULL(yt.Sep实际货量金额, 0)) AS Sep实际货量金额 ,
                        SUM(ISNULL(ld.Oct预计货量金额, 0) + ISNULL(yt.Oct预计货量金额, 0)) AS Oct预计货量金额 ,
                        SUM(ISNULL(ld.Oct实际货量金额, 0) + ISNULL(yt.Oct实际货量金额, 0)) AS Oct实际货量金额 ,
                        SUM(ISNULL(ld.Nov预计货量金额, 0) + ISNULL(yt.Nov预计货量金额, 0)) AS Nov预计货量金额 ,
                        SUM(ISNULL(ld.Nov实际货量金额, 0) + ISNULL(yt.Nov实际货量金额, 0)) AS Nov实际货量金额 ,
                        SUM(ISNULL(ld.Dec预计货量金额, 0) + ISNULL(yt.Dec预计货量金额, 0)) AS Dec预计货量金额 ,
                        SUM(ISNULL(ld.Dec实际货量金额, 0) + ISNULL(yt.Dec实际货量金额, 0)) AS Dec实际货量金额 ,
                        SUM(ISNULL(ld.本年可售货量金额, 0) + ISNULL(yt.本年可售货量金额, 0)) AS 本年可售货量金额 , --ISNULL(adjust.调整金额,0)
                        SUM(ISNULL(ld.本年可售货量面积, 0) + ISNULL(yt.本年可售货量面积, 0)) AS 本年可售货量面积 ,
                         --本年可售金额 - 本年销售金额
                        null 预计明年年初可售货量 ,--ISNULL(adjust.调整金额,0)
                        SUM(ISNULL(ld.本年可售货量金额, 0) - ISNULL(ld.今年车位可售金额, 0)
                            - CASE WHEN ISNULL(ld.Dec实际货量金额, 0) = 0
                                   THEN ISNULL(ld.Dec预计货量金额, 0)
                                   ELSE 0
                              END + ISNULL(yt.本年可售货量金额, 0)--ISNULL(adjust.调整金额,0)
                            - ISNULL(yt.今年车位可售金额, 0)
                            - CASE WHEN ISNULL(yt.Dec实际货量金额, 0) = 0
                                   THEN ISNULL(yt.Dec预计货量金额, 0)
                                   ELSE 0
                              END) 本年有效货量 ,
                        SUM(ISNULL(ld.明年Jan预计货量金额, 0) + ISNULL(yt.明年Jan预计货量金额,
                                                              0)) 明年Jan预计货量金额 ,
                        SUM(ISNULL(ld.明年Feb预计货量金额, 0) + ISNULL(yt.明年Feb预计货量金额,
                                                              0)) 明年Feb预计货量金额 ,
                        SUM(ISNULL(ld.明年Mar预计货量金额, 0) + ISNULL(yt.明年Mar预计货量金额,
                                                              0)) 明年Mar预计货量金额 ,
                        SUM(ISNULL(ld.明年Apr预计货量金额, 0) + ISNULL(yt.明年Apr预计货量金额,
                                                              0)) 明年Apr预计货量金额 ,
                        SUM(ISNULL(ld.明年May预计货量金额, 0) + ISNULL(yt.明年May预计货量金额,
                                                              0)) 明年May预计货量金额 ,
                        SUM(ISNULL(ld.明年Jun预计货量金额, 0) + ISNULL(yt.明年Jun预计货量金额,
                                                              0)) 明年Jun预计货量金额 ,
                        SUM(ISNULL(ld.明年July预计货量金额, 0)
                            + ISNULL(yt.明年July预计货量金额, 0)) 明年July预计货量金额 ,
                        SUM(ISNULL(ld.明年Aug预计货量金额, 0) + ISNULL(yt.明年Aug预计货量金额,
                                                              0)) 明年Aug预计货量金额 ,
                        SUM(ISNULL(ld.明年Sep预计货量金额, 0) + ISNULL(yt.明年Sep预计货量金额,
                                                              0)) 明年Sep预计货量金额 ,
                        SUM(ISNULL(ld.明年Oct预计货量金额, 0) + ISNULL(yt.明年Oct预计货量金额,
                                                              0)) 明年Oct预计货量金额 ,
                        SUM(ISNULL(ld.明年Nov预计货量金额, 0) + ISNULL(yt.明年Nov预计货量金额,
                                                              0)) 明年Nov预计货量金额 ,
                        SUM(ISNULL(ld.明年Dec预计货量金额, 0) + ISNULL(yt.明年Dec预计货量金额,
                                                              0)) 明年Dec预计货量金额 ,
                        SUM(ISNULL(ld.后年Jan预计货量金额, 0) + ISNULL(yt.后年Jan预计货量金额,
                                                              0)) 后年Jan预计货量金额 ,
                        SUM(ISNULL(ld.后年Feb预计货量金额, 0) + ISNULL(yt.后年Feb预计货量金额,
                                                              0)) 后年Feb预计货量金额 ,
                        SUM(ISNULL(ld.后年Mar预计货量金额, 0) + ISNULL(yt.后年Mar预计货量金额,
                                                              0)) 后年Mar预计货量金额 ,
                        SUM(ISNULL(ld.后年Apr预计货量金额, 0) + ISNULL(yt.后年Apr预计货量金额,
                                                              0)) 后年Apr预计货量金额 ,
                        SUM(ISNULL(ld.后年May预计货量金额, 0) + ISNULL(yt.后年May预计货量金额,
                                                              0)) 后年May预计货量金额 ,
                        SUM(ISNULL(ld.后年Jun预计货量金额, 0) + ISNULL(yt.后年Jun预计货量金额,
                                                              0)) 后年Jun预计货量金额 ,
                        SUM(ISNULL(ld.后年July预计货量金额, 0)
                            + ISNULL(yt.后年July预计货量金额, 0)) 后年July预计货量金额 ,
                        SUM(ISNULL(ld.后年Aug预计货量金额, 0) + ISNULL(yt.后年Aug预计货量金额,
                                                              0)) 后年Aug预计货量金额 ,
                        SUM(ISNULL(ld.后年Sep预计货量金额, 0) + ISNULL(yt.后年Sep预计货量金额,
                                                              0)) 后年Sep预计货量金额 ,
                        SUM(ISNULL(ld.后年Oct预计货量金额, 0) + ISNULL(yt.后年Oct预计货量金额,
                                                              0)) 后年Oct预计货量金额 ,
                        SUM(ISNULL(ld.后年Nov预计货量金额, 0) + ISNULL(yt.后年Nov预计货量金额,
                                                              0)) 后年Nov预计货量金额 ,
                        SUM(ISNULL(ld.后年Dec预计货量金额, 0) + ISNULL(yt.后年Dec预计货量金额,
                                                              0)) 后年Dec预计货量金额 ,
                        NULL 预计售价,
            SUM(ISNULL(ld.总建筑面积, 0) + ISNULL(yt.总建筑面积,0)) 总建筑面积,
            SUM(ISNULL(ld.地上建筑面积, 0) + ISNULL(yt.地上建筑面积,0)) 地上建筑面积,
            SUM(ISNULL(ld.地下建筑面积, 0) + ISNULL(yt.地下建筑面积, 0)) 地下建筑面积,
            SUM(ISNULL(ld.可售房源套数, 0) + ISNULL(yt.可售房源套数, 0)) 可售房源套数,
            bi2.组织架构父级ID,
            SUM(ISNULL(ld.计容面积, 0) + ISNULL(yt.计容面积,0)) 总建筑面积
                FROM    ydkb_BaseInfo bi2 
        --系统自动取数部分
                        LEFT JOIN ( SELECT  ld.ProjGUID ,
                                            ld.ProductType ,
                                            SUM(总货值金额) AS 总货值金额 ,
                                            SUM(总货值面积) AS 总货值面积 , 
                                            sum(总货值套数) as 总货值套数,
											SUM(已取证面积) AS 已取证面积 ,
                                            SUM(已售货量金额)+ISNULL(h.累计签约额,0) AS 已售货量金额 ,
                                            SUM(已售货量面积)+ISNULL(h.累计签约面积,0) AS 已售货量面积 ,
											SUM(已售货量套数)+ISNULL(h.累计签约套数,0) AS 已售货量套数 ,
											sum(isnull(ld.累计签约套数 ,  0))+ISNULL(h.累计签约套数,0) as    累计签约套数 ,  
											sum(isnull(ld.累计已推售面积 ,0)) as   累计已推售面积 ,
											sum(isnull(ld.累计已推售套数 ,0)) as   累计已推售套数 ,
											sum(isnull(ld.累计已推售货值 ,0)) as   累计已推售货值 ,
                                            sum(已开工货值) as 已开工货值,
											SUM(未销售部分货量)-ISNULL(h.累计签约额,0) AS 未销售部分货量 ,
                                            SUM(未销售部分可售面积)-ISNULL(h.累计签约面积,0) AS 未销售部分可售面积 ,
											SUM(未销售部分可售套数)-ISNULL(h.累计签约套数,0) AS 未销售部分可售套数 ,
                                            SUM(ISNULL(ld.停工缓建未销售部分货量, 0)) 停工缓建未销售部分货量,
                                            SUM(ISNULL(ld.停工缓建未销售部分可售面积, 0)) 停工缓建未销售部分可售面积,
                                            SUM(ISNULL(ld.停工缓建未销售部分可售套数, 0)) 停工缓建未销售部分可售套数,
											sum(剩余货值预估去化面积) as 剩余货值预估去化面积,
											sum(剩余货值预估去化金额) as 剩余货值预估去化金额,
                                            SUM(剩余货值预估去化面积_按月份差) 剩余货值预估去化面积_按月份差 ,
                                            SUM(剩余货值预估去化金额_按月份差) 剩余货值预估去化金额_按月份差 ,
											SUM(未销售部分货量_三年内不开工)-ISNULL(h.累计签约额,0) AS 未销售部分货量_三年内不开工 ,
                                            SUM(未销售部分可售面积_三年内不开工)-ISNULL(h.累计签约面积,0) AS 未销售部分可售面积_三年内不开工 ,
                                            SUM(未销售部分可售套数_三年内不开工)-ISNULL(h.累计签约套数,0) AS 未销售部分可售套数_三年内不开工 ,
                                            SUM(未开工剩余货值金额)-ISNULL(h.累计签约额,0) AS 未开工剩余货值金额 ,
                                            SUM(未开工剩余货值面积)-ISNULL(h.累计签约面积,0) AS 未开工剩余货值面积 ,
                                            SUM(未开工剩余货值套数)-ISNULL(h.累计签约套数,0) AS 未开工剩余货值套数 ,
											SUM(在途剩余货值金额)-ISNULL(h.累计签约额,0) AS 在途剩余货值金额 ,
                                            SUM(在途剩余货值面积)-ISNULL(h.累计签约面积,0) AS 在途剩余货值面积 ,
                                            SUM(在途剩余货值套数)-ISNULL(h.累计签约套数,0) AS 在途剩余货值套数 ,
                                            SUM(停工缓建在途剩余货值金额) AS 停工缓建在途剩余货值金额 ,
                                            SUM(停工缓建在途剩余货值面积) AS 停工缓建在途剩余货值面积 ,
                                            SUM(停工缓建在途剩余货值套数) AS 停工缓建在途剩余货值套数 ,
											SUM(剩余可售货值金额)-ISNULL(h.累计签约额,0) AS 剩余可售货值金额 ,
                                            SUM(剩余可售货值面积)-ISNULL(h.累计签约面积,0) AS 剩余可售货值面积 ,
                                            SUM(剩余可售货值套数) as 剩余可售货值套数,
                                            SUM(停工缓建剩余可售货值金额) AS 停工缓建剩余可售货值金额 ,
                                            SUM(停工缓建剩余可售货值面积) AS 停工缓建剩余可售货值面积 ,
                                            SUM(停工缓建剩余可售货值套数) AS 停工缓建剩余可售货值套数 ,
                                            SUM(工程达到可售未拿证货值金额) AS 工程达到可售未拿证货值金额 ,
                                            SUM(工程达到可售未拿证货值面积) AS 工程达到可售未拿证货值面积 ,
                                            SUM(工程达到可售未拿证货值套数) AS 工程达到可售未拿证货值套数 ,
                                            SUM(停工缓建工程达到可售未拿证货值金额) AS 停工缓建工程达到可售未拿证货值金额 ,
                                            SUM(停工缓建工程达到可售未拿证货值面积) AS 停工缓建工程达到可售未拿证货值面积 ,
                                            SUM(停工缓建工程达到可售未拿证货值套数) AS 停工缓建工程达到可售未拿证货值套数 ,
                                            SUM(获证未推货值金额)-ISNULL(h.累计签约额,0) AS 获证未推货值金额 ,
                                            SUM(获证未推货值面积)-ISNULL(h.累计签约面积,0)  AS 获证未推货值面积 ,
                                            SUM(获证未推货值套数)-ISNULL(h.累计签约套数,0)  AS 获证未推货值套数 ,
                                            SUM(停工缓建获证未推货值金额) AS 停工缓建获证未推货值金额 ,
                                            SUM(停工缓建获证未推货值面积)  AS 停工缓建获证未推货值面积 ,
                                            SUM(停工缓建获证未推货值套数)  AS 停工缓建获证未推货值套数 ,
                                            SUM(获证未推产成品货值金额) AS 获证未推产成品货值金额 ,
                                            SUM(获证未推产成品货值金额含车位) AS 获证未推产成品货值金额含车位 ,
                                            SUM(获证未推准产成品货值金额含车位) AS 获证未推准产成品货值金额含车位 ,
                                            SUM(获证未推正常滚动货值金额)-ISNULL(h.累计签约额,0) AS 获证未推正常滚动货值金额 ,
                                            SUM(获证未推车位货值金额) AS 获证未推车位货值金额 ,
                                            SUM(已推未售货值金额) AS 已推未售货值金额 ,
                                            SUM(已推未售货值面积) AS 已推未售货值面积 ,
                                            SUM(已推未售货值套数) AS 已推未售货值套数 ,
                                            SUM(停工缓建已推未售货值金额) AS 停工缓建已推未售货值金额 ,
                                            SUM(停工缓建已推未售货值面积) AS 停工缓建已推未售货值面积 ,
                                            SUM(停工缓建已推未售货值套数) AS 停工缓建已推未售货值套数 ,
                                            SUM(已推未售产成品货值金额) AS 已推未售产成品货值金额 ,
                                            SUM(已推未售产成品货值金额含车位) AS 已推未售产成品货值金额含车位 ,
                                            SUM(已推未售准产成品货值金额含车位) AS 已推未售准产成品货值金额含车位 ,
                                            SUM(已推未售难销货值金额) AS 已推未售难销货值金额 ,
                                            SUM(已推未售正常滚动货值金额) AS 已推未售正常滚动货值金额 ,
                                            SUM(已推未售车位货值金额) AS 已推未售车位货值金额 ,
                                            SUM(年初动态货值) 年初动态货值,
                                            SUM(年初动态货值面积) 年初动态货值面积,
                                            SUM(年初剩余货值) 年初剩余货值,
                                            SUM(年初剩余货值面积) 年初剩余货值面积,
                                            sum(年初剩余货值_年初清洗版) 年初剩余货值_年初清洗版,
                                            sum(年初剩余货值面积_年初清洗版)  年初剩余货值面积_年初清洗版,
                                            sum(年初取证未售货值_年初清洗版) 年初取证未售货值_年初清洗版,
                                            sum(年初取证未售面积_年初清洗版) 年初取证未售面积_年初清洗版,
                                            sum(本年已售货值_截止上月底清洗版) as 本年已售货值_截止上月底清洗版,
                                            sum(本年已售面积_截止上月底清洗版) 本年已售面积_截止上月底清洗版,
                                            sum(本年取证剩余货值_截止上月底清洗版) 本年取证剩余货值_截止上月底清洗版,
                                            sum(本年取证剩余面积_截止上月底清洗版) 本年取证剩余面积_截止上月底清洗版,
                                            SUM(年初工程达到可售未拿证货值金额) AS 年初工程达到可售未拿证货值金额 ,
                                            SUM(年初工程达到可售未拿证货值面积) AS 年初工程达到可售未拿证货值面积 ,
                                            SUM(年初获证未推货值金额) AS 年初获证未推货值金额 ,
                                            SUM(年初获证未推货值面积) AS 年初获证未推货值面积 ,
                                            SUM(年初获证未推产成品货值金额) AS 年初获证未推产成品货值金额 ,
                                            SUM(年初获证未推产成品货值金额含车位) AS 年初获证未推产成品货值金额含车位 ,
                                            SUM(年初获证未推准产成品货值金额含车位) AS 年初获证未推准产成品货值金额含车位 ,
                                            SUM(年初获证未推正常滚动货值金额) AS 年初获证未推正常滚动货值金额 ,
                                            SUM(年初获证未推车位货值金额) AS 年初获证未推车位货值金额 ,
                                            SUM(年初已推未售货值金额) AS 年初已推未售货值金额 ,        --其中已推未售货值金额 （亿元）
                                            SUM(年初已推未售货值面积) AS 年初已推未售货值面积 ,        --其中已推未售货值面积
                                            SUM(年初已推未售产成品货值金额) AS 年初已推未售产成品货值金额 ,
                                            SUM(年初已推未售产成品货值金额含车位) AS 年初已推未售产成品货值金额含车位 ,
                                            SUM(年初已推未售准产成品货值金额含车位) AS 年初已推未售准产成品货值金额含车位 ,
                                            SUM(年初已推未售难销货值金额) AS 年初已推未售难销货值金额 ,
                                            SUM(年初已推未售正常滚动货值金额) AS 年初已推未售正常滚动货值金额 ,
                                            SUM(年初已推未售车位货值金额) AS 年初已推未售车位货值金额 ,
                                            SUM(本年新增货量金额) AS 本年新增货量 ,
                                            --预估本年本月及剩余月份新增货值
                                            SUM(预估本年取证新增货值) as 预估本年取证新增货值,
                                            sum(预估本年取证新增面积) as 预估本年取证新增面积,
                                            SUM(Jan预计货量金额) AS Jan预计货量金额 ,
                                            SUM(Jan实际货量金额) AS Jan实际货量金额 ,
                                            SUM(Feb预计货量金额) AS Feb预计货量金额 ,
                                            SUM(Feb实际货量金额) AS Feb实际货量金额 ,
                                            SUM(Mar预计货量金额) AS Mar预计货量金额 ,
                                            SUM(Mar实际货量金额) AS Mar实际货量金额 ,
                                            SUM(Apr预计货量金额) AS Apr预计货量金额 ,
                                            SUM(Apr实际货量金额) AS Apr实际货量金额 ,
                                            SUM(May预计货量金额) AS May预计货量金额 ,
                                            SUM(May实际货量金额) AS May实际货量金额 ,
                                            SUM(Jun预计货量金额) AS Jun预计货量金额 ,
                                            SUM(Jun实际货量金额) AS Jun实际货量金额 ,
                                            SUM(July预计货量金额) AS July预计货量金额 ,
                                            SUM(July实际货量金额) AS July实际货量金额 ,
                                            SUM(Aug预计货量金额) AS Aug预计货量金额 ,
                                            SUM(Aug实际货量金额) AS Aug实际货量金额 ,
                                            SUM(Sep预计货量金额) AS Sep预计货量金额 ,
                                            SUM(Sep实际货量金额) AS Sep实际货量金额 ,
                                            SUM(Oct预计货量金额) AS Oct预计货量金额 ,
                                            SUM(Oct实际货量金额) AS Oct实际货量金额 ,
                                            SUM(Nov预计货量金额) AS Nov预计货量金额 ,
                                            SUM(Nov实际货量金额) AS Nov实际货量金额 ,
                                            SUM(Dec预计货量金额) AS Dec预计货量金额 ,
                                            SUM(Dec实际货量金额) AS Dec实际货量金额 ,
                                            SUM(本年可售货量金额) AS 本年可售货量金额 ,
                                            SUM(本年可售货量面积) as 本年可售货量面积,
                                            SUM(明年Jan预计货量金额) AS 明年Jan预计货量金额 ,
                                            SUM(明年Feb预计货量金额) AS 明年Feb预计货量金额 ,
                                            SUM(明年Mar预计货量金额) AS 明年Mar预计货量金额 ,
                                            SUM(明年Apr预计货量金额) AS 明年Apr预计货量金额 ,
                                            SUM(明年May预计货量金额) AS 明年May预计货量金额 ,
                                            SUM(明年Jun预计货量金额) AS 明年Jun预计货量金额 ,
                                            SUM(明年July预计货量金额) AS 明年July预计货量金额 ,
                                            SUM(明年Aug预计货量金额) AS 明年Aug预计货量金额 ,
                                            SUM(明年Sep预计货量金额) AS 明年Sep预计货量金额 ,
                                            SUM(明年Oct预计货量金额) AS 明年Oct预计货量金额 ,
                                            SUM(明年Nov预计货量金额) AS 明年Nov预计货量金额 ,
                                            SUM(明年Dec预计货量金额) AS 明年Dec预计货量金额 ,
                                            SUM(后年Jan预计货量金额) AS 后年Jan预计货量金额 ,
                                            SUM(后年Feb预计货量金额) AS 后年Feb预计货量金额 ,
                                            SUM(后年Mar预计货量金额) AS 后年Mar预计货量金额 ,
                                            SUM(后年Apr预计货量金额) AS 后年Apr预计货量金额 ,
                                            SUM(后年May预计货量金额) AS 后年May预计货量金额 ,
                                            SUM(后年Jun预计货量金额) AS 后年Jun预计货量金额 ,
                                            SUM(后年July预计货量金额) AS 后年July预计货量金额 ,
                                            SUM(后年Aug预计货量金额) AS 后年Aug预计货量金额 ,
                                            SUM(后年Sep预计货量金额) AS 后年Sep预计货量金额 ,
                                            SUM(后年Oct预计货量金额) AS 后年Oct预计货量金额 ,
                                            SUM(后年Nov预计货量金额) AS 后年Nov预计货量金额 ,
                                            SUM(后年Dec预计货量金额) AS 后年Dec预计货量金额 ,
                                            SUM(今年车位可售金额) AS 今年车位可售金额,
                                            SUM(ld.总建筑面积) AS 总建筑面积 ,
                                            SUM(ld.地上建筑面积) AS 地上建筑面积 ,
                                            SUM(ld.地下建筑面积) AS 地下建筑面积 ,
                                            SUM(ld.可售房源套数) AS 可售房源套数 ,
                      SUM(ld.计容面积) AS   计容面积
                                    FROM    #ldhz ld 
                  LEFT JOIN #hzyj h ON ld.ProjGUID = h.ProjGUID AND ld.ProductType = h.ProductType AND h.ProjGUID <> 'd07ccf43-cbc0-e811-80bf-e61f13c57837'
                                    GROUP BY ld.ProjGUID ,
                                             ld.ProductType,
                       ISNULL(h.累计签约额,0),
                       ISNULL(h.累计签约面积,0),
                       ISNULL(h.累计签约套数,0)
                                  ) ld ON ld.ProjGUID = bi2.组织架构父级ID
                                          AND ld.ProductType = bi2.组织架构名称
       --手工铺排部分 
                        LEFT JOIN #ythz yt ON yt.ProjGUID = bi2.组织架构父级ID
                                              AND yt.ProductType = bi2.组织架构名称 
                WHERE   bi2.组织架构类型 = 4 --AND  bi2.平台公司GUID IN (
       -- SELECT value FROM dbo.fn_Split2(@developmentguid,',')
      --  )
                GROUP BY bi2.组织架构父级ID ,
                        bi2.组织架构ID ,
                        bi2.组织架构名称 ,
                        bi2.组织架构编码 ,
                        bi2.组织架构类型;

    --循环插入项目，城市公司，平台公司的值   
        DECLARE @baseinfo INT;
        SET @baseinfo = 4; 

        WHILE ( @baseinfo > 1 )
            BEGIN 
        
                INSERT  INTO ydkb_dthz_wq_deal_salevalueinfo
                        ( 组织架构父级ID ,
                          组织架构ID ,
                          组织架构名称 ,
                          组织架构编码 ,
                          组织架构类型 ,
                          总货值金额 ,
                          总货值面积 ,
                          总货值套数,
                          已取证面积,
                          已售货量金额 ,
                          已售货量面积 ,
                          累计签约套数 , 
                          累计已推售面积 , 
                          累计已推售套数 , 
                          累计已推售货值 , 
                          已开工货值,
                          剩余货值金额 ,
                          剩余货值面积 ,
						  剩余货值套数,
                          停工缓建剩余货值金额,
                          停工缓建剩余货值面积,
                          停工缓建剩余货值套数,
                          剩余货值预估去化面积 ,
                          剩余货值预估去化金额 , 
                          剩余货值预估去化面积_按月份差 ,
                          剩余货值预估去化金额_按月份差 ,
                          剩余货值金额_三年内不开工 ,
                          剩余货值面积_三年内不开工 ,
                          剩余货值套数_三年内不开工 ,
                          未开工剩余货值金额,
                          未开工剩余货值面积,
                          未开工剩余货值套数,
                          在途剩余货值金额,
                          在途剩余货值面积,
                          在途剩余货值套数,
                          停工缓建在途剩余货值金额,
                          停工缓建在途剩余货值面积,
                          停工缓建在途剩余货值套数,
                          剩余可售货值金额 ,
                          剩余可售货值面积 ,
                          剩余可售货值套数,
                          停工缓建剩余可售货值金额 ,
                          停工缓建剩余可售货值面积 ,
                          停工缓建剩余可售货值套数 ,
                          工程达到可售未拿证货值金额 ,
                          工程达到可售未拿证货值面积 ,
                          工程达到可售未拿证货值套数 ,
                          停工缓建工程达到可售未拿证货值金额 ,
                          停工缓建工程达到可售未拿证货值面积 ,
                          停工缓建工程达到可售未拿证货值套数 ,
                          获证未推货值金额 ,
                          获证未推货值面积 ,
                          获证未推货值套数 ,
                          停工缓建获证未推货值金额 ,
                          停工缓建获证未推货值面积 ,
                          停工缓建获证未推货值套数 ,
                          获证未推产成品货值金额 ,
                          获证未推产成品货值金额含车位 ,
                          获证未推准产成品货值金额含车位 ,
                          获证未推正常滚动货值金额 ,
                          获证未推车位货值金额 ,
                          已推未售货值金额 ,
                          已推未售货值面积 ,
                          已推未售货值套数 ,
                          停工缓建已推未售货值金额 ,
                          停工缓建已推未售货值面积 ,
                          停工缓建已推未售货值套数 ,
                          已推未售产成品货值金额 ,
                          已推未售产成品货值金额含车位 ,
                          已推未售准产成品货值金额含车位 ,
                          已推未售难销货值金额 ,
                          已推未售正常滚动货值金额 ,
                          已推未售车位货值金额 ,
                          年初动态货值,
                          年初动态货值面积,
                          年初剩余货值,
                          年初剩余货值面积,
                          年初剩余货值_年初清洗版,
                          年初剩余货值面积_年初清洗版,
                          年初取证未售货值_年初清洗版,
                          年初取证未售面积_年初清洗版,
                          本年已售货值_截止上月底清洗版,
                          本年已售面积_截止上月底清洗版,
                          本年取证剩余货值_截止上月底清洗版,
                          本年取证剩余面积_截止上月底清洗版,
                          年初工程达到可售未拿证货值金额 ,
                          年初工程达到可售未拿证货值面积 ,
                          年初获证未推货值金额 ,
                          年初获证未推货值面积 ,
                          年初获证未推产成品货值金额 ,
                          年初获证未推产成品货值金额含车位 ,
                          年初获证未推准产成品货值金额含车位 ,
                          年初获证未推正常滚动货值金额 ,
                          年初获证未推车位货值金额 ,
                          年初已推未售货值金额 ,        --其中已推未售货值金额 （亿元）
                          年初已推未售货值面积 ,        --其中已推未售货值面积
                          年初已推未售产成品货值金额 ,
                          年初已推未售产成品货值金额含车位 ,
                          年初已推未售准产成品货值金额含车位 ,
                          年初已推未售难销货值金额 ,
                          年初已推未售正常滚动货值金额 ,
                          年初已推未售车位货值金额 ,
                          本年新增货量 ,
                          预估本年取证新增货值,
                          预估本年取证新增面积,
                          Jan预计货量金额 ,
                          Jan实际货量金额 ,
                          Feb预计货量金额 ,
                          Feb实际货量金额 ,
                          Mar预计货量金额 ,
                          Mar实际货量金额 ,
                          Apr预计货量金额 ,
                          Apr实际货量金额 ,
                          May预计货量金额 ,
                          May实际货量金额 ,
                          Jun预计货量金额 ,
                          Jun实际货量金额 ,
                          July预计货量金额 ,
                          July实际货量金额 ,
                          Aug预计货量金额 ,
                          Aug实际货量金额 ,
                          Sep预计货量金额 ,
                          Sep实际货量金额 ,
                          Oct预计货量金额 ,
                          Oct实际货量金额 ,
                          Nov预计货量金额 ,
                          Nov实际货量金额 ,
                          Dec预计货量金额 ,
                          Dec实际货量金额 ,
                          本年可售货量金额 ,
                          本年可售货量面积,
                          预计明年年初可售货量 ,
                          本年有效货量 ,
                          明年Jan预计货量金额 ,
                          明年Feb预计货量金额 ,
                          明年Mar预计货量金额 ,
                          明年Apr预计货量金额 ,
                          明年May预计货量金额 ,
                          明年Jun预计货量金额 ,
                          明年July预计货量金额 ,
                          明年Aug预计货量金额 ,
                          明年Sep预计货量金额 ,
                          明年Oct预计货量金额 ,
                          明年Nov预计货量金额 ,
                          明年Dec预计货量金额 ,
                          后年Jan预计货量金额 ,
                          后年Feb预计货量金额 ,
                          后年Mar预计货量金额 ,
                          后年Apr预计货量金额 ,
                          后年May预计货量金额 ,
                          后年Jun预计货量金额 ,
                          后年July预计货量金额 ,
                          后年Aug预计货量金额 ,
                          后年Sep预计货量金额 ,
                          后年Oct预计货量金额 ,
                          后年Nov预计货量金额 ,
                          后年Dec预计货量金额 ,
                          预计售价,
                          总建筑面积,
                          地上建筑面积,
                          地下建筑面积,
                          可售房源套数,
                          projguid,
                          计容面积
                        )
                        SELECT  bi.组织架构父级ID ,
                                bi.组织架构ID ,
                                bi.组织架构名称 ,
                                bi.组织架构编码 ,
                                bi.组织架构类型 ,
                                SUM(总货值金额) AS 总货值金额 ,
                                SUM(总货值面积) AS 总货值面积 , 
                                SUM(总货值套数) AS 总货值套数 , 
                                SUM(已取证面积) AS 已取证面积 ,
                                SUM(已售货量金额) AS 已售货量金额 ,
                                SUM(已售货量面积) AS 已售货量面积 ,
                                sum(累计签约套数) 累计签约套数 , 
                                sum(累计已推售面积) 累计已推售面积, 
                                sum(累计已推售套数) 累计已推售套数, 
                                sum(累计已推售货值) 累计已推售货值, 
                                sum(已开工货值) 已开工货值,
                                SUM(剩余货值金额) AS 剩余货值金额 ,
                                SUM(剩余货值面积) AS 剩余货值面积 ,
								SUM(剩余货值套数) AS 剩余货值套数 ,
                                SUM(停工缓建剩余货值金额) as 停工缓建剩余货值金额,
                                SUM(停工缓建剩余货值面积) as 停工缓建剩余货值面积,
                                SUM(停工缓建剩余货值套数) as 停工缓建剩余货值套数,
                                sum(剩余货值预估去化面积) as 剩余货值预估去化面积 ,
                                sum(剩余货值预估去化金额) as 剩余货值预估去化金额 ,
                                sum(剩余货值预估去化面积_按月份差) as 剩余货值预估去化面积_按月份差 ,
                                sum(剩余货值预估去化金额_按月份差) as 剩余货值预估去化金额_按月份差 ,
                                SUM(剩余货值金额_三年内不开工) AS 剩余货值金额三年内不开工 ,
                                SUM(剩余货值面积_三年内不开工) AS 剩余货值面积三年内不开工 ,
                                SUM(剩余货值套数_三年内不开工) AS 剩余货值套数三年内不开工 ,
                                SUM(未开工剩余货值金额) AS 未开工剩余货值金额 ,
                                SUM(未开工剩余货值面积) AS 未开工剩余货值面积 ,
                                SUM(未开工剩余货值套数) AS 未开工剩余货值套数 ,
                                SUM(在途剩余货值金额) as 在途剩余货值金额,
                                SUM(在途剩余货值面积) as 在途剩余货值面积,
                                SUM(在途剩余货值套数) as 在途剩余货值套数,
                                SUM(停工缓建在途剩余货值金额) as 停工缓建在途剩余货值金额,
                                SUM(停工缓建在途剩余货值面积) as 停工缓建在途剩余货值面积,
                                SUM(停工缓建在途剩余货值套数) as 停工缓建在途剩余货值套数,
                                SUM(剩余可售货值金额) AS 剩余可售货值金额 ,
                                SUM(剩余可售货值面积) AS 剩余可售货值面积 ,
                                SUM(剩余可售货值套数) AS 剩余可售货值套数 ,
                                SUM(停工缓建剩余可售货值金额) AS 停工缓建剩余可售货值金额 ,
                                SUM(停工缓建剩余可售货值面积) AS 停工缓建剩余可售货值面积 ,
                                SUM(停工缓建剩余可售货值套数) AS 停工缓建剩余可售货值套数 ,
                                SUM(工程达到可售未拿证货值金额) AS 工程达到可售未拿证货值金额 ,
                                SUM(工程达到可售未拿证货值面积) AS 工程达到可售未拿证货值面积 ,
                                SUM(工程达到可售未拿证货值套数) AS 工程达到可售未拿证货值套数 ,
                                SUM(停工缓建工程达到可售未拿证货值金额) AS 停工缓建工程达到可售未拿证货值金额 ,
                                SUM(停工缓建工程达到可售未拿证货值面积) AS 停工缓建工程达到可售未拿证货值面积 ,
                                SUM(停工缓建工程达到可售未拿证货值套数) AS 停工缓建工程达到可售未拿证货值套数 ,
                                SUM(获证未推货值金额) AS 获证未推货值金额 ,
                                SUM(获证未推货值面积) AS 获证未推货值面积 ,
                                SUM(获证未推货值套数) AS 获证未推货值套数 ,
                                SUM(停工缓建获证未推货值金额) AS 停工缓建获证未推货值金额 ,
                                SUM(停工缓建获证未推货值面积) AS 停工缓建获证未推货值面积 ,
                                SUM(停工缓建获证未推货值套数) AS 停工缓建获证未推货值套数 ,
                                SUM(获证未推产成品货值金额) AS 获证未推产成品货值金额 ,
                                SUM(获证未推产成品货值金额含车位) AS 获证未推产成品货值金额含车位 ,
                                SUM(获证未推准产成品货值金额含车位) AS 获证未推准产成品货值金额含车位 ,
                                SUM(获证未推正常滚动货值金额) AS 获证未推正常滚动货值金额 ,
                                SUM(获证未推车位货值金额) AS 获证未推车位货值金额 ,
                                SUM(已推未售货值金额) AS 已推未售货值金额 ,
                                SUM(已推未售货值面积) AS 已推未售货值面积 ,
                                SUM(已推未售货值套数) AS 已推未售货值套数 ,
                                SUM(停工缓建已推未售货值金额) AS 停工缓建已推未售货值金额 ,
                                SUM(停工缓建已推未售货值面积) AS 停工缓建已推未售货值面积 ,
                                SUM(停工缓建已推未售货值套数) AS 停工缓建已推未售货值套数 ,
                                SUM(已推未售产成品货值金额) AS 已推未售产成品货值金额 ,
                                SUM(已推未售产成品货值金额含车位) AS 已推未售产成品货值金额含车位 ,
                                SUM(已推未售准产成品货值金额含车位) AS 已推未售准产成品货值金额含车位 ,
                                SUM(已推未售难销货值金额) AS 已推未售难销货值金额 ,
                                SUM(已推未售正常滚动货值金额) AS 已推未售正常滚动货值金额 ,
                                SUM(已推未售车位货值金额) AS 已推未售车位货值金额 ,
                                SUM(年初动态货值) 年初动态货值,
                                SUM(年初动态货值面积) 年初动态货值面积,
                                SUM(年初剩余货值) 年初剩余货值,
                                SUM(年初剩余货值面积) 年初剩余货值面积,
                                sum(年初剩余货值_年初清洗版) 年初剩余货值_年初清洗版,
                                sum(年初剩余货值面积_年初清洗版)  年初剩余货值面积_年初清洗版,
                                sum(年初取证未售货值_年初清洗版) 年初取证未售货值_年初清洗版,
                                sum(年初取证未售面积_年初清洗版) 年初取证未售面积_年初清洗版,
                                sum(本年已售货值_截止上月底清洗版) as 本年已售货值_截止上月底清洗版,
                                sum(本年已售面积_截止上月底清洗版) 本年已售面积_截止上月底清洗版,
                                sum(本年取证剩余货值_截止上月底清洗版) 本年取证剩余货值_截止上月底清洗版,
                                sum(本年取证剩余面积_截止上月底清洗版) 本年取证剩余面积_截止上月底清洗版,
                                SUM(年初工程达到可售未拿证货值金额) AS 年初工程达到可售未拿证货值金额 ,
                                SUM(年初工程达到可售未拿证货值面积) AS 年初工程达到可售未拿证货值面积 ,
                                SUM(年初获证未推货值金额) AS 年初获证未推货值金额 ,
                                SUM(年初获证未推货值面积) AS 年初获证未推货值面积 ,
                                SUM(年初获证未推产成品货值金额) AS 年初获证未推产成品货值金额 ,
                                SUM(年初获证未推产成品货值金额含车位) AS 年初获证未推产成品货值金额含车位 ,
                                SUM(年初获证未推准产成品货值金额含车位) AS 年初获证未推准产成品货值金额含车位 ,
                                SUM(年初获证未推正常滚动货值金额) AS 年初获证未推正常滚动货值金额 ,
                                SUM(年初获证未推车位货值金额) AS 年初获证未推车位货值金额 ,
                                SUM(年初已推未售货值金额) AS 年初已推未售货值金额 ,        --其中已推未售货值金额 （亿元）
                                SUM(年初已推未售货值面积) AS 年初已推未售货值面积 ,        --其中已推未售货值面积
                                SUM(年初已推未售产成品货值金额) AS 年初已推未售产成品货值金额 ,
                                SUM(年初已推未售产成品货值金额含车位) AS 年初已推未售产成品货值金额含车位 ,
                                SUM(年初已推未售准产成品货值金额含车位) AS 年初已推未售准产成品货值金额含车位 ,
                                SUM(年初已推未售难销货值金额) AS 年初已推未售难销货值金额 ,
                                SUM(年初已推未售正常滚动货值金额) AS 年初已推未售正常滚动货值金额 ,
                                SUM(年初已推未售车位货值金额) AS 年初已推未售车位货值金额 ,
                                SUM(本年新增货量) AS 本年新增货量 , 
                                SUM(预估本年取证新增货值) as 预估本年取证新增货值,
                                sum(预估本年取证新增面积) as 预估本年取证新增面积,
                                SUM(Jan预计货量金额) AS Jan预计货量金额 ,
                                SUM(Jan实际货量金额) AS Jan实际货量金额 ,
                                SUM(Feb预计货量金额) AS Feb预计货量金额 ,
                                SUM(Feb实际货量金额) AS Feb实际货量金额 ,
                                SUM(Mar预计货量金额) AS Mar预计货量金额 ,
                                SUM(Mar实际货量金额) AS Mar实际货量金额 ,
                                SUM(Apr预计货量金额) AS Apr预计货量金额 ,
                                SUM(Apr实际货量金额) AS Apr实际货量金额 ,
                                SUM(May预计货量金额) AS May预计货量金额 ,
                                SUM(May实际货量金额) AS May实际货量金额 ,
                                SUM(Jun预计货量金额) AS Jun预计货量金额 ,
                                SUM(Jun实际货量金额) AS Jun实际货量金额 ,
                                SUM(July预计货量金额) AS July预计货量金额 ,
                                SUM(July实际货量金额) AS July实际货量金额 ,
                                SUM(Aug预计货量金额) AS Aug预计货量金额 ,
                                SUM(Aug实际货量金额) AS Aug实际货量金额 ,
                                SUM(Sep预计货量金额) AS Sep预计货量金额 ,
                                SUM(Sep实际货量金额) AS Sep实际货量金额 ,
                                SUM(Oct预计货量金额) AS Oct预计货量金额 ,
                                SUM(Oct实际货量金额) AS Oct实际货量金额 ,
                                SUM(Nov预计货量金额) AS Nov预计货量金额 ,
                                SUM(Nov实际货量金额) AS Nov实际货量金额 ,
                                SUM(Dec预计货量金额) AS Dec预计货量金额 ,
                                SUM(Dec实际货量金额) AS Dec实际货量金额 ,
                                SUM(本年可售货量金额) AS 本年可售货量金额 ,
                                SUM(本年可售货量面积) AS 本年可售货量面积 ,
                                SUM(预计明年年初可售货量) AS 预计明年年初可售货量 ,
                                SUM(本年有效货量) AS 本年有效货量 ,
                                SUM(明年Jan预计货量金额) AS 明年Jan预计货量金额 ,
                                SUM(明年Feb预计货量金额) AS 明年Feb预计货量金额 ,
                                SUM(明年Mar预计货量金额) AS 明年Mar预计货量金额 ,
                                SUM(明年Apr预计货量金额) AS 明年Apr预计货量金额 ,
                                SUM(明年May预计货量金额) AS 明年May预计货量金额 ,
                                SUM(明年Jun预计货量金额) AS 明年Jun预计货量金额 ,
                                SUM(明年July预计货量金额) AS 明年July预计货量金额 ,
                                SUM(明年Aug预计货量金额) AS 明年Aug预计货量金额 ,
                                SUM(明年Sep预计货量金额) AS 明年Sep预计货量金额 ,
                                SUM(明年Oct预计货量金额) AS 明年Oct预计货量金额 ,
                                SUM(明年Nov预计货量金额) AS 明年Nov预计货量金额 ,
                                SUM(明年Dec预计货量金额) AS 明年Dec预计货量金额 ,
                                SUM(后年Jan预计货量金额) AS 后年Jan预计货量金额 ,
                                SUM(后年Feb预计货量金额) AS 后年Feb预计货量金额 ,
                                SUM(后年Mar预计货量金额) AS 后年Mar预计货量金额 ,
                                SUM(后年Apr预计货量金额) AS 后年Apr预计货量金额 ,
                                SUM(后年May预计货量金额) AS 后年May预计货量金额 ,
                                SUM(后年Jun预计货量金额) AS 后年Jun预计货量金额 ,
                                SUM(后年July预计货量金额) AS 后年July预计货量金额 ,
                                SUM(后年Aug预计货量金额) AS 后年Aug预计货量金额 ,
                                SUM(后年Sep预计货量金额) AS 后年Sep预计货量金额 ,
                                SUM(后年Oct预计货量金额) AS 后年Oct预计货量金额 ,
                                SUM(后年Nov预计货量金额) AS 后年Nov预计货量金额 ,
                                SUM(后年Dec预计货量金额) AS 后年Dec预计货量金额 ,
                                NULL 预计售价,
                                SUM(总建筑面积) AS 总建筑面积,
                                SUM(地上建筑面积) AS 地上建筑面积,
                                SUM(地下建筑面积) AS 地下建筑面积,
                                SUM(可售房源套数) AS 可售房源套数,
                                CASE WHEN bi.组织架构类型  = 3 THEN b.projguid ELSE  NULL end projguid,
                                SUM(计容面积) AS 计容面积
                            FROM    ydkb_dthz_wq_deal_salevalueinfo b
                                    INNER JOIN ydkb_BaseInfo bi ON bi.组织架构ID = b.组织架构父级ID
                            WHERE   b.组织架构类型 = @baseinfo
                            GROUP BY bi.组织架构父级ID ,
                                    bi.组织架构ID ,
                                    bi.组织架构名称 ,
                                    bi.组织架构编码 ,
                                    bi.组织架构类型,
                                    CASE WHEN bi.组织架构类型  = 3 THEN b.projguid ELSE  NULL end;
      
                SET @baseinfo = @baseinfo - 1;

            END;     

     --更新项目层级的占地面积和容积率
     UPDATE hz SET 占地面积 = pj.TotalArea, 容积率 =VolumeRate from ydkb_dthz_wq_deal_salevalueinfo hz 
     INNER JOIN MyCost_Erp352.dbo.md_Project pj ON hz.组织架构ID = pj.ProjGUID 
     WHERE pj.IsActive = 1 
   
     SELECT * FROM dbo.ydkb_dthz_wq_deal_salevalueinfo
 
    --删除临时表
     DROP TABLE #ldhz,#hzyj,#p_lddb,#ythz,#jr;
    
    END;  