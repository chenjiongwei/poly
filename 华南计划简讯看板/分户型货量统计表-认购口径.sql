-- declare @var_dev varchar(max) = 'AADC0FA7-9546-49C9-B64B-825056C828ED'
-- declare @sdate datetime= convert(varchar(10),dateadd(mm,-3,getdate()),120)
-- declare @edate datetime= convert(varchar(10),dateadd(mm,-1,getdate()),120)

-- 2025-08-13  增加字段： 已开工未售货值总计、在途货值合计、存货货值合计、累计去化金额、累计已实现销售净利润、累计已实现销售净利率
CREATE TABLE #ylgh
    (
        versionguid uniqueidentifier,
        OrgGuid uniqueidentifier,
        ProjGUID uniqueidentifier,
        平台公司 varchar(500),
        项目名 varchar(500),
        推广名 varchar(500),
        项目代码 varchar(500),
        投管代码 varchar(500),
        盈利规划上线方式 varchar(500),
        产品类型 varchar(500),
        产品名称 varchar(500),
        装修标准 varchar(500),
        商品类型 varchar(500),
        明源匹配主键 varchar(2000),
        业态组合键 varchar(2000),
        当期认购面积 decimal(18,8),
        当期认购金额 decimal(18,8),
        当期认购金额不含税 decimal(18,8),
        当期签约面积 decimal(18,8),
        当期签约金额 decimal(18,8),
        当期签约金额不含税 decimal(18,8),
        盈利规划营业成本单方 decimal(18,8),
        土地款_单方 decimal(18,8),
        除地外直投_单方 decimal(18,8),
        开发间接费单方 decimal(18,8),
        资本化利息单方 decimal(18,8),
        盈利规划股权溢价单方 decimal(18,8),
        盈利规划营销费用单方 decimal(18,8),
        盈利规划综合管理费单方协议口径 decimal(18,8),
        盈利规划税金及附加单方 decimal(18,8),
        盈利规划营业成本认购 decimal(18,8),
        盈利规划股权溢价认购 decimal(18,8),
        毛利认购 decimal(18,8),
        毛利率认购 decimal(18,8),
        盈利规划营销费用认购 decimal(18,8),
        盈利规划综合管理费认购 decimal(18,8),
        盈利规划税金及附加认购 decimal(18,8),
        税前利润认购 decimal(18,8),
        所得税认购 decimal(18,8),
        净利润认购 decimal(18,8),
        销售净利率认购 decimal(18,8),
        盈利规划营业成本签约 decimal(18,8),
        盈利规划股权溢价签约 decimal(18,8),
        毛利签约 decimal(18,8),
        毛利率签约 decimal(18,8),
        盈利规划营销费用签约 decimal(18,8),
        盈利规划综合管理费签约 decimal(18,8),
        盈利规划税金及附加签约 decimal(18,8),
        税前利润签约 decimal(18,8),
        所得税签约 decimal(18,8),
        净利润签约 decimal(18,8),
        销售净利率签约 decimal(18,8),
        当期认购套数 decimal(18,8),
        当期签约套数 decimal(18,8),
        当期产成品签约金额 decimal(18,8),
        当期产成品签约金额不含税 decimal(18,8),
        产成品净利润签约 decimal(18,8),
        产成品销售净利率签约 decimal(18,8)
    );

insert into  #ylgh
exec usp_s_M002项目业态级毛利净利表  @var_dev ,@sdate,@edate;

--预处理面积段分类
select '住宅' as producttype,null productname, 80 beginarea, 100 endarea, 3 roomnum,'80-100' areatype, 0 as 是否大户型
into #areatype
union all 
select '住宅' as producttype,null productname, 100 beginarea, 130 endarea, 3 roomnum,'100-130' areatype, 0 as 是否大户型 
union all 
select '住宅' as producttype,null productname, 130 beginarea, 150 endarea, 4 roomnum,'130-150' areatype, 0 as 是否大户型
union all 
select '住宅' as producttype,null productname, 150 beginarea, 200 endarea, 4 roomnum,'150-200' areatype, 1 as 是否大户型
union all 
select '住宅' as producttype,null productname, 200 beginarea, 1000 endarea, 4 roomnum,'200以上' areatype, 1 as 是否大户型
union all 
select '企业会所' as producttype,null productname, 0 beginarea, 1000 endarea, 0 roomnum,'商办' areatype, 0 as 是否大户型
union all
select '写字楼' as producttype,null productname, 0 beginarea, 1000 endarea, 0 roomnum,'商办' areatype, 0 as 是否大户型
union all 
select '会所' as producttype,null productname, 0 beginarea, 1000 endarea, 0 roomnum,'商办' areatype, 0 as 是否大户型
union all 
select '商业' as producttype,'商铺' productname, 0 beginarea, 1000 endarea, 0 roomnum,'商办' areatype, 0 as 是否大户型
union all 
select '商业' as producttype,'临时售楼部' productname, 0 beginarea, 1000 endarea, 0 roomnum,'商办' areatype, 0 as 是否大户型
union all 
select '商业' as producttype,'集中商业' productname, 0 beginarea, 1000 endarea, 0 roomnum,'商办' areatype, 0 as 是否大户型
union all 
select '地下室/车库' as producttype,'人防车库' productname, 0 beginarea, 1000 endarea, 0 roomnum,'人防车位' areatype, 0 as 是否大户型
union all 
select '地下室/车库' as producttype,'人防车位' productname, 0 beginarea, 1000 endarea, 0 roomnum,'人防车位' areatype, 0 as 是否大户型
union all 
select '地下室/车库' as producttype,'地上车位' productname, 0 beginarea, 1000 endarea, 0 roomnum,'产权车位' areatype, 0 as 是否大户型
union all 
select '地下室/车库' as producttype,'地下储藏室' productname, 0 beginarea, 1000 endarea, 0 roomnum,'产权车位' areatype, 0 as 是否大户型
union all 
select '地下室/车库' as producttype,'机械停车位' productname, 0 beginarea, 1000 endarea, 0 roomnum,'产权车位' areatype, 0 as 是否大户型
union all 
select '地下室/车库' as producttype,'露天车位' productname, 0 beginarea, 1000 endarea, 0 roomnum,'产权车位' areatype, 0 as 是否大户型
union all 
select '地下室/车库' as producttype,'普通地下车库' productname, 0 beginarea, 1000 endarea, 0 roomnum,'产权车位' areatype, 0 as 是否大户型
union all 
select '地下室/车库' as producttype,'普通地下车位' productname, 0 beginarea, 1000 endarea, 0 roomnum,'产权车位' areatype, 0 as 是否大户型
union all 
select '地下室/车库' as producttype,'室内地上车库' productname, 0 beginarea, 1000 endarea, 0 roomnum,'产权车位' areatype, 0 as 是否大户型
union all 
select '地下室/车库' as producttype,'自行车库' productname, 0 beginarea, 1000 endarea, 0 roomnum,'产权车位' areatype, 0 as 是否大户型

--缓存需要统计的项目清单
select *
into #p
from vmdm_projectFlag pj WITH(NOLOCK)
where pj.DevelopmentCompanyGUID = @var_dev  
 
--获取统计时间段内的销售流速情况
SELECT  pp.projguid , 
        r.producttype ,
        r.ProductName , 
        r.bldarea , 
        CASE WHEN r.RoomStru LIKE '%一室%' OR r.RoomStru LIKE '%1室%' OR   r.RoomStru LIKE '%单室%' OR   r.RoomStru LIKE '%单房%' OR   r.RoomStru LIKE '%一房%' OR   r.RoomStru LIKE '%1房%' THEN 1
             WHEN r.RoomStru LIKE '%两房%' OR r.RoomStru LIKE '%两室%' OR   r.RoomStru LIKE '%二室%' OR   r.RoomStru LIKE '%2室%' OR   r.RoomStru LIKE '%双室%' OR   r.RoomStru LIKE '%二房%'
                  OR   r.RoomStru LIKE '%双房%' OR   r.RoomStru LIKE '%2房%' THEN 2
             WHEN r.RoomStru LIKE '%三室%' OR r.RoomStru LIKE '%3室%' OR   r.RoomStru LIKE '%三房%' OR   r.RoomStru LIKE '%3房%' THEN 3
             WHEN r.RoomStru LIKE '%四室%' OR r.RoomStru LIKE '%4室%' OR   r.RoomStru LIKE '%四房%' OR   r.RoomStru LIKE '%4房%' THEN 4
             WHEN r.RoomStru LIKE '%五室%' OR r.RoomStru LIKE '%5室%' OR   r.RoomStru LIKE '%五房%' OR   r.RoomStru LIKE '%5房%' THEN 5
             WHEN r.RoomStru LIKE '%六室%' OR r.RoomStru LIKE '%6室%' OR   r.RoomStru LIKE '%六房%' OR   r.RoomStru LIKE '%6房%' THEN 6
             WHEN r.RoomStru LIKE '%七室%' OR r.RoomStru LIKE '%7室%' OR   r.RoomStru LIKE '%七房%' OR   r.RoomStru LIKE '%7房%' THEN 7
             WHEN r.RoomStru LIKE '%八室%' OR r.RoomStru LIKE '%8室%' OR   r.RoomStru LIKE '%八房%' OR   r.RoomStru LIKE '%8房%' THEN 8
             WHEN r.RoomStru LIKE '%九室%' OR r.RoomStru LIKE '%9室%' OR   r.RoomStru LIKE '%九房%' OR   r.RoomStru LIKE '%9房%' THEN 9
             WHEN r.RoomStru LIKE '%十室%' OR r.RoomStru LIKE '%10室%' OR  r.RoomStru LIKE '%十房%' OR   r.RoomStru LIKE '%10房%' THEN 10
             ELSE -1
        END RoomNum ,    
        --认购情况
        SUM(CASE WHEN r.status in ('签约','认购') and so.qsdate between @sdate and @edate THEN isnull(sc.JyTotal,so.jytotal) ELSE 0 END) rgje ,
        SUM(CASE WHEN r.status in ('签约','认购') and so.qsdate between @sdate and @edate THEN r.bldarea ELSE 0 END) rgmj ,
        SUM(CASE WHEN r.status in ('签约','认购') and so.qsdate between @sdate and @edate THEN 1 ELSE 0 END) rgts , 
        SUM(case when r.thdate is null then 0 else 1 end) ljtsts, -- 累计推售套数
        SUM(case when r.status in ('签约','认购')   then 1 else 0 end) ljqhts,--累计去化套数
        sum(case when r.status in ('签约','认购')   then isnull(sc.JyTotal,so.jytotal) ELSE 0 END  ) as ljqhje, -- 累计去化金额
        datediff(dd,@sdate,@edate)+1  tj_day
INTO    #sale
FROM    ERP25.dbo.ep_room r WITH(NOLOCK)
        INNER JOIN p_Project p WITH(NOLOCK) ON r.projguid = p.projguid
        INNER JOIN p_Project pp WITH(NOLOCK) ON p.parentcode = pp.projcode
        inner join #p pj on pj.projguid = pp.projguid 	
        LEFT JOIN erp25.dbo.s_contract sc WITH(NOLOCK) ON sc.roomguid = r.roomguid AND  sc.status = '激活' AND r.status = '签约'
		LEFT JOIN erp25.dbo.s_order so WITH(NOLOCK) ON so.roomguid = r.roomguid AND so.OrderType='认购' and (so.Status = '激活' OR (so.Status = '关闭' AND so.CloseReason = '转签约' AND  so.TradeGUID = sc.TradeGUID and sc.contractguid is not null))  
WHERE   r.IsVirtualRoom = 0 AND r.producttype IN ('住宅', '高级住宅', '企业会所', '公寓','商业','地下室/车库','写字楼','企业会所') 
group by pp.projguid , 
        r.producttype ,
        r.ProductName , 
        r.bldarea , 
        CASE WHEN r.RoomStru LIKE '%一室%' OR r.RoomStru LIKE '%1室%' OR   r.RoomStru LIKE '%单室%' OR   r.RoomStru LIKE '%单房%' OR   r.RoomStru LIKE '%一房%' OR   r.RoomStru LIKE '%1房%' THEN 1
             WHEN r.RoomStru LIKE '%两房%' OR r.RoomStru LIKE '%两室%' OR   r.RoomStru LIKE '%二室%' OR   r.RoomStru LIKE '%2室%' OR   r.RoomStru LIKE '%双室%' OR   r.RoomStru LIKE '%二房%'
                  OR   r.RoomStru LIKE '%双房%' OR   r.RoomStru LIKE '%2房%' THEN 2
             WHEN r.RoomStru LIKE '%三室%' OR r.RoomStru LIKE '%3室%' OR   r.RoomStru LIKE '%三房%' OR   r.RoomStru LIKE '%3房%' THEN 3
             WHEN r.RoomStru LIKE '%四室%' OR r.RoomStru LIKE '%4室%' OR   r.RoomStru LIKE '%四房%' OR   r.RoomStru LIKE '%4房%' THEN 4
             WHEN r.RoomStru LIKE '%五室%' OR r.RoomStru LIKE '%5室%' OR   r.RoomStru LIKE '%五房%' OR   r.RoomStru LIKE '%5房%' THEN 5
             WHEN r.RoomStru LIKE '%六室%' OR r.RoomStru LIKE '%6室%' OR   r.RoomStru LIKE '%六房%' OR   r.RoomStru LIKE '%6房%' THEN 6
             WHEN r.RoomStru LIKE '%七室%' OR r.RoomStru LIKE '%7室%' OR   r.RoomStru LIKE '%七房%' OR   r.RoomStru LIKE '%7房%' THEN 7
             WHEN r.RoomStru LIKE '%八室%' OR r.RoomStru LIKE '%8室%' OR   r.RoomStru LIKE '%八房%' OR   r.RoomStru LIKE '%8房%' THEN 8
             WHEN r.RoomStru LIKE '%九室%' OR r.RoomStru LIKE '%9室%' OR   r.RoomStru LIKE '%九房%' OR   r.RoomStru LIKE '%9房%' THEN 9
             WHEN r.RoomStru LIKE '%十室%' OR r.RoomStru LIKE '%10室%' OR  r.RoomStru LIKE '%十房%' OR   r.RoomStru LIKE '%10房%' THEN 10
             ELSE -1
        END;

--统计当前的货量情况 认购口径
select hx.projguid,
    pj.推广名 项目推广名,
	pj.投管代码 as 投管代码,
	pj.项目代码 as 明源代码,
    hx.producttype as 业态,
    t.areatype as 面积段分类,
    case when hx.producttype = '住宅' then convert(varchar(2),hx.roomnum)+'房' else null end 户数,
    sum(hx.ykgwsts_rg) 已开工未售套数合计,
    sum(hx.ykgwsmj_rg) 已开工未售建筑面积合计,
    sum(hx.ykgwshz_rg) 已开工未售货值合计,
    sum(case when hx.SJzskgdate is not null and hx.SjDdysxxDate is null then hx.symj_rg else 0 end) as 在途货量面积合计, --已开工未达预售形象
    sum(case when hx.SJzskgdate is not null and hx.SjDdysxxDate is null then hx.syhz_rg else 0 end)  as 在途货值合计, -- 需要改成认购口径
    sum(hx.ykgwsmj_rg - case when hx.SJzskgdate is not null and hx.SjDdysxxDate is null then hx.symj_rg else 0 end) 存货面积合计, --已开工未售建筑面积合计-在途货量面积合计
    sum(hx.ykgwshz_rg - case when hx.SJzskgdate is not null and hx.SjDdysxxDate is null then hx.syhz_rg else 0 end) 存货货值合计, --已开工未售货值合计-在途货值合计
    null as 在途货量达售时间
into #hl 
from [172.16.4.161].highdata_prod.dbo.data_wide_dws_s_HxAnalysis_Summary hx WITH(NOLOCK)
inner join p_lddb ld WITH(NOLOCK) on ld.salebldguid = hx.productbuildguid and datediff(dd,qxdate,getdate()) = 0
inner join #areatype t WITH(NOLOCK) on (hx.producttype = t.producttype and (isnull(t.productname,'') =ld.productname  or t.productname is null) )  and hx.bldarea >= t.beginarea and hx.bldarea<t.endarea
inner join #p pj WITH(NOLOCK) on pj.projguid = hx.projguid 
where hx.ykgwsts <> 0 
group by hx.projguid,
    pj.推广名 ,
	pj.投管代码,
	pj.项目代码,
    hx.producttype ,
    t.areatype ,
    case when hx.producttype = '住宅' then convert(varchar(2),hx.roomnum)+'房' else null end;

--汇总数据
with s as (
    select 
        s.projguid,
        s.ProductType, 
        t.areatype, 
        case when s.producttype = '住宅' then convert(varchar(2),s.roomnum)+'房' else null end 户数,
        case when s.producttype = '地下室/车库' and sum(rgts) <> 0 then sum(rgje)/sum(rgts) when sum(rgmj) = 0 then 0 else sum(rgje)/sum(rgmj) end 月均去化均价,
        case when tj_day = 0 then 0 else sum(rgmj)/tj_day*30 end 月均去化面积,
        case when tj_day = 0 then 0 else sum(rgts)*1.0/tj_day*30 end 月均去化套数,
        case when tj_day = 0 then 0 else sum(rgje)/tj_day*30 end 月均去化金额,
        sum(ljtsts) as 累计推售套数,
        sum(ljqhts) as 累计去化套数,
        sum(ljqhje) as 累计去化金额
    from #sale s WITH(NOLOCK)
    inner join #areatype t on (s.producttype = t.producttype and (isnull(t.productname,'') =s.productname  or t.productname is null) )  and s.bldarea >= t.beginarea and s.bldarea<t.endarea
	group by s.projguid,
	s.ProductType, 
    t.areatype, 
    case when s.producttype = '住宅' then convert(varchar(2),s.roomnum)+'房' else null end,
	tj_day
)
-- 查询结果
select *, 
   case when 税前利润 > 0 then 税前利润*0.75 else 税前利润 end  as 销售净利润, -- 签约口径
   case when isnull(累计去化金额,0)  =0 then  0 else 
      (case when 税前利润 > 0 then 税前利润*0.75 else 税前利润 end) /  isnull(累计去化金额,0) /1.09  end as  销售净利率-- 签约口径
from (
    select hl.projguid,
        hl.项目推广名,
        hl.投管代码,
        hl.明源代码,
        hl.业态,
        hl.面积段分类,
        hl.户数,
        hl.已开工未售套数合计,
        hl.已开工未售建筑面积合计,
        hl.已开工未售货值合计,

        hl.在途货量面积合计, --已开工未达预售形象
        hl.在途货值合计,

        hl.存货面积合计, --已开工未售建筑面积合计-在途货量面积合计
        hl.存货货值合计,
        hl.在途货量达售时间, --手填
        s.月均去化均价 近3月月均去化均价,
        s.月均去化面积 近3月月均去化面积,
        s.月均去化套数 近3月月均去化套数, 
        s.月均去化金额 近3月月均去化金额,
        case when s.月均去化面积 = 0 then 0 else hl.已开工未售建筑面积合计/s.月均去化面积 end 按任务达成的户型产销比, --已开工未售建筑面积合计/(第四季度去化目标分解（面积）/3)
        case when s.月均去化面积 = 0 then 0 else 存货面积合计/s.月均去化面积 end 达新增供货周期后的户型产销比, -- 存货-((本期合计去化目标分解/3)*7)+在途货值)/(本期合计去化目标分解/3)
        6*s.月均去化面积 -hl.已开工未售建筑面积合计 + 6*s.月均去化面积  [产销比达到6需新增供货] ,
        累计推售套数,
        累计去化套数,
        累计去化金额,
        -- 盈利规划成本单方
        ylgh.盈利规划营业成本单方,
        ylgh.盈利规划营销费用单方,
        ylgh.盈利规划综合管理费单方协议口径,
        ylgh.盈利规划税金及附加单方,   

        case when  isnull(s.月均去化均价,0) =0  then  0  else  isnull(累计去化金额,0) / isnull(s.月均去化均价,0) end  *   -- 反算销售面积
               ( isnull(s.月均去化均价,0)/1.09  -- 不含税销售均价
                - isnull(ylgh.盈利规划营业成本单方,0) 
                - isnull(ylgh.盈利规划营销费用单方,0) 
                - isnull(ylgh.盈利规划综合管理费单方协议口径,0) 
                - isnull(ylgh.盈利规划税金及附加单方,0) )  as  税前利润
    from #hl hl  WITH(NOLOCK)
    left join s  WITH(NOLOCK) on s.projguid = hl.projguid and hl.业态 = s.producttype and isnull(hl.面积段分类,'') = isnull(s.areatype,'') and isnull(hl.户数,'') = isnull(s.户数,'')
    left join (
            SELECT  
                projguid,
                产品类型,
                CASE WHEN SUM(CASE WHEN ISNULL(盈利规划营业成本单方,0) <> 0 THEN 1 ELSE 0 END) = 0 
                     THEN 0 
                     ELSE SUM(CASE WHEN ISNULL(盈利规划营业成本单方,0) <> 0 THEN 盈利规划营业成本单方 ELSE 0 END) / 
                          SUM(CASE WHEN ISNULL(盈利规划营业成本单方,0) <> 0 THEN 1 ELSE 0 END) 
                END AS 盈利规划营业成本单方,
                CASE WHEN SUM(CASE WHEN ISNULL(盈利规划营销费用单方,0) <> 0 THEN 1 ELSE 0 END) = 0 
                     THEN 0 
                     ELSE SUM(CASE WHEN ISNULL(盈利规划营销费用单方,0) <> 0 THEN 盈利规划营销费用单方 ELSE 0 END) / 
                          SUM(CASE WHEN ISNULL(盈利规划营销费用单方,0) <> 0 THEN 1 ELSE 0 END) 
                END AS 盈利规划营销费用单方,	
                CASE WHEN SUM(CASE WHEN ISNULL(盈利规划综合管理费单方协议口径,0) <> 0 THEN 1 ELSE 0 END) = 0 
                     THEN 0 
                     ELSE SUM(CASE WHEN ISNULL(盈利规划综合管理费单方协议口径,0) <> 0 THEN 盈利规划综合管理费单方协议口径 ELSE 0 END) / 
                          SUM(CASE WHEN ISNULL(盈利规划综合管理费单方协议口径,0) <> 0 THEN 1 ELSE 0 END) 
                END AS 盈利规划综合管理费单方协议口径,
                CASE WHEN SUM(CASE WHEN ISNULL(盈利规划税金及附加单方,0) <> 0 THEN 1 ELSE 0 END) = 0 
                     THEN 0 
                     ELSE SUM(CASE WHEN ISNULL(盈利规划税金及附加单方,0) <> 0 THEN 盈利规划税金及附加单方 ELSE 0 END) / 
                          SUM(CASE WHEN ISNULL(盈利规划税金及附加单方,0) <> 0 THEN 1 ELSE 0 END) 
                END AS 盈利规划税金及附加单方
            FROM   #ylgh  WITH(NOLOCK)
            GROUP BY projguid, 产品类型
        ) ylgh on ylgh.projguid = hl.projguid and hl.业态 = ylgh.产品类型
    -- order by hl.projguid, 
    --     hl.投管代码,
    --     hl.明源代码,
    --     hl.业态,
    --     hl.面积段分类,
    --     hl.户数
) lr
where  1=1
order by lr.projguid, 
lr.投管代码,
lr.明源代码,
lr.业态,
lr.面积段分类,
lr.户数

drop table #areatype,#hl,#p,#sale,#ylgh