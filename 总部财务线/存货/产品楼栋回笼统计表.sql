BEGIN
-- SET NOCOUNT ON;  -- 禁止显示受影响的行数信息
  declare @tqrq DATETIME = getdate();

-- 1 获取近6个月已回完款的房间
SELECT c.contractguid,
       c.tradeguid,
       c.roomguid,
	   r.roominfo,
       c.lastsaleguid,
       c.qsdate,
       c.jytotal,
       c.PayformName,
       pp.ProjGUID,
	   pp.SpreadName as ProjName,
       c.projguid as StageGUID,
	   concat(pp.SpreadName,'-',p.ProjShortName) as StageName,
	   b.BldGUID,
       b.bldName,
       fee.Amount as ysAmount,
       getin.RmbAmount as ssAmount,
       getin.GetDate,
       --concat(pr.ProductName,'-',pr.BusinessType,'-',pr.Standard) as ProductName
       CONCAT(md_productnamemodule.producttype,'-',md_room.productname,'-',md_room.businesstype,'-',case when md_room.zxbz ='' then pr.Standard else md_room.zxbz end) AS ProductName
INTO #con
FROM s_contract c
LEFT JOIN ep_room r ON c.roomguid = r.roomguid
left join p_Building b on r.BldGUID = b.BldGUID
left join p_project p on p.ProjGUID = c.ProjGUID
left join p_project pp on p.ParentCode = pp.ProjCode
inner join mdm_salebuild sb on sb.SaleBldGUID = b.BldGUID
inner join mdm_Product pr on pr.ProductGUID = sb.ProductGUID
LEFT JOIN (
   select tradeguid,sum(Amount) as Amount 
    from s_fee 
    where  ItemType in ('非贷款类房款','贷款类房款')
    group by tradeguid 
) fee on fee.tradeguid = c.tradeguid
LEFT JOIN (
    select saleguid,
        sum(RmbAmount) as RmbAmount,
        max(GetDate) as GetDate
    from s_getin  g
    where  ItemType in ('非贷款类房款','贷款类房款') 
        and g.status is null
    group by saleguid
) getin on getin.saleguid = c.tradeguid
LEFT JOIN MyCost_Erp352.DBO.md_room md_room ON md_room.roomguid = r.roomguid
left join (
    select md_productbuild.productbuildguid,
        md_productbuild.bldname as productbldname,
        md_gcbuild.bldname as projectbldname
    from MyCost_Erp352.DBO.md_productbuild
    inner join MyCost_Erp352.DBO.md_gcbuild on md_gcbuild.bldkeyguid = md_productbuild.bldkeyguid and md_gcbuild.isactive = 1
) bld on md_room.productbldguid = bld.productbuildguid
left join MyCost_Erp352.DBO.md_productnamemodule on md_productnamemodule.productnamecode = md_room.productnamecode
WHERE c.status = '激活' 
    -- and pp.projguid = @var_projguid	
    and fee.Amount <= getin.RmbAmount
    AND getin.GetDate >= DATEADD(MONTH, -6, @tqrq)
    AND getin.GetDate <= @tqrq;


--计算出各款项类型的占比 公积金、银行按揭
select 
    t.ProjGUID,
    t.StageGUID,
    t.ProductName,
	t.ItemName,
    t.months,
    t.rmbamount as rmbamount,
    cast(t.rmbamount * 1.0 / nullif(tt.total_amount,0) as decimal(18,8)) as 占比
into #dk_rate
from (
    select 
        temp.ProjGUID,
        temp.StageGUID,
        temp.ProductName,
        temp.ItemName,
        temp.months,
        sum(temp.rmbamount) as rmbamount
    from (
        select 
            con.ProjGUID,
            con.StageGUID,
            con.ProductName,
            con.bldName,
            con.roomguid,
            con.RoomInfo,
            con.qsdate,
            g.getdate,
            g.rmbamount,
            g.ItemName,
            g.ItemType,
            CASE WHEN datediff(month,con.qsdate,g.getdate) < 0 THEN 0 ELSE datediff(month,con.qsdate,g.getdate) END as months
        from #con con 
        inner join s_getin g on con.tradeguid = g.saleguid and g.itemtype in ('非贷款类房款','贷款类房款')
        inner join dbo.s_Voucher v1 on v1.VouchGUID = g.VouchGUID
        where g.Status IS NULL
            and v1.VouchType ='收款单'
    ) temp
    group by temp.ProjGUID,
        temp.StageGUID,
        temp.ProductName,
        temp.ItemName,
        temp.months
) t
left join (
    select ProjGUID,StageGUID,ProductName,ItemName, sum(rmbamount) as total_amount
    from (
        select 
            con.ProjGUID,
            con.StageGUID,
            con.ProductName,
			g.ItemName,
            g.rmbamount
        from #con con 
        inner join s_getin g on con.tradeguid = g.saleguid and g.itemtype in ('非贷款类房款','贷款类房款')
    ) x
	group by ProjGUID,StageGUID,ProductName,ItemName
) tt on tt.ItemName = t.ItemName and tt.ProductName = t.ProductName and t.ProjGUID = tt.ProjGUID and t.StageGUID = tt.StageGUID
where t.ItemName in ('公积金','银行按揭')
order by t.ProductName,t.itemname,months asc;

--计算非贷款类 若月份为负数，则归类到第0月
select 
    t.ProjGUID,
    t.StageGUID,
    t.ProductName as ProductName,
    '非贷款类' AS ItemName,
    t.months,
    t.rmbamount as rmbamount,
    cast(t.rmbamount * 1.0 / nullif(tt.total_amount,0) as decimal(18,8)) as 占比
into #fdk_rate
from (
    select 
        temp.ProjGUID,
        temp.StageGUID,
        temp.productname,
        temp.months,
        sum(temp.rmbamount) as rmbamount
    from (
        select 
            con.ProjGUID,
            con.StageGUID,
            con.ProductName,
            con.BldName,
            con.roomguid,
            con.RoomInfo,
            con.qsdate,
            g.getdate,
            g.rmbamount,
            g.ItemName,
            g.ItemType,
            CASE WHEN datediff(month,con.qsdate,g.getdate) < 0 THEN 0 ELSE datediff(month,con.qsdate,g.getdate) END as months
        from #con con 
        inner join s_getin g on con.tradeguid = g.saleguid and g.itemtype in ('非贷款类房款')
        where g.Status IS NULL
    ) temp
    group by temp.ProjGUID,
        temp.StageGUID,
        temp.productname,
        temp.months
) t
left join (
    select ProjGUID,StageGUID,ProductName, sum(rmbamount) as total_amount
    from (
        select 
            con.ProjGUID,
            con.StageGUID,     
            con.ProductName,
			g.ItemName,
            g.rmbamount
        from #con con 
        inner join s_getin g on con.tradeguid = g.saleguid and g.itemtype in ('非贷款类房款')
    ) x
	group by ProjGUID,StageGUID,ProductName
) tt on  tt.ProductName = t.ProductName and tt.ProjGUID = t.ProjGUID and tt.StageGUID = t.StageGUID
order by t.ProductName;

--统计所有实收[正常房间]
SELECT 
       pp.ProjGUID,
	   pp.SpreadName as ProjName,
       c.projguid as StageGUID,
	   concat(pp.SpreadName,'-',p.ProjShortName) as StageName,
       b.BldGUID,
       b.BldName,
       pr.ProductGUID,
       --concat(pr.ProductName,'-',pr.BusinessType,'-',pr.Standard) as ProductName,
       CONCAT(md_productnamemodule.producttype,'-',md_room.productname,'-',md_room.businesstype,'-',case when md_room.zxbz ='' then pr.Standard else md_room.zxbz end) AS ProductName,
       year(getin.GetDate) as 回笼年,
       month(getin.GetDate) as 回笼月份,
       sum(getin.RmbAmount) as 回笼金额       
INTO #getin
FROM s_contract c
LEFT JOIN ep_room r ON c.roomguid = r.roomguid
left join p_Building b on r.BldGUID = b.BldGUID
inner join mdm_salebuild sb on sb.SaleBldGUID = b.BldGUID
inner join mdm_Product pr on pr.ProductGUID = sb.ProductGUID
left join p_project p on p.ProjGUID = c.ProjGUID
left join p_project pp on p.ParentCode = pp.ProjCode
LEFT JOIN (
    select tradeguid,sum(Amount) as Amount 
    from s_fee 
    where  ItemType in ('非贷款类房款','贷款类房款')
    group by tradeguid 
) fee on fee.tradeguid = c.tradeguid
LEFT JOIN (
    select saleguid,
        sum(RmbAmount) as RmbAmount,
        max(GetDate) as GetDate
    from s_getin  g
    where  ItemType in ('非贷款类房款','贷款类房款') 
        and g.status is null
    group by saleguid
) getin on getin.saleguid = c.tradeguid
LEFT JOIN MyCost_Erp352.DBO.md_room md_room ON md_room.roomguid = r.roomguid
left join (
    select md_productbuild.productbuildguid,
        md_productbuild.bldname as productbldname,
        md_gcbuild.bldname as projectbldname
    from MyCost_Erp352.DBO.md_productbuild
    inner join MyCost_Erp352.DBO.md_gcbuild on md_gcbuild.bldkeyguid = md_productbuild.bldkeyguid and md_gcbuild.isactive = 1
) bld on md_room.productbldguid = bld.productbuildguid
left join MyCost_Erp352.DBO.md_productnamemodule on md_productnamemodule.productnamecode = md_room.productnamecode
WHERE c.status = '激活' 
  --  and pp.projguid = @var_projguid	
group by 
    pp.ProjGUID,
    pp.SpreadName,
    c.projguid,
    concat(pp.SpreadName,'-',p.ProjShortName),
    b.BldGUID,
    b.BldName,
    pr.ProductGUID,
    CONCAT(md_productnamemodule.producttype,'-',md_room.productname,'-',md_room.businesstype,'-',case when md_room.zxbz ='' then pr.Standard else md_room.zxbz end),
    --concat(pr.ProductName,'-',pr.BusinessType,'-',pr.Standard),
    year(getin.GetDate),
    month(getin.GetDate);

--统计所有实收[特殊业绩房间]
--数据存在部分遗漏，就是合作业绩没有归属到产品或楼栋或房间，如土地款、收购类项目已售业绩认定
SELECT  
       pp.ProjGUID,
	   pp.SpreadName as ProjName,
       p.projguid as StageGUID,
	   concat(pp.SpreadName,'-',p.ProjShortName) as StageName,
       bd.BldGUID,
       bd.BldName,
       pr.ProductGUID,
       CONCAT(pr.producttype,'-',pr.productname,'-',pr.businesstype,'-',pr.Standard) AS ProductName,
       --特殊业绩回笼
        yj.回笼年,
        yj.回笼月份,
        CASE WHEN ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(yj.huilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0)) END AS huilongjiner 
INTO    #ts
FROM    S_PerformanceAppraisalBuildings a
LEFT JOIN S_PerformanceAppraisal b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
LEFT JOIN (
        SELECT    v.SaleGUID ,
                YEAR(g.GetDate) as 回笼年,
                MONTH(g.GetDate) as 回笼月份,
                SUM(ISNULL(g.RmbAmount, 0)) AS huilongjiner
        FROM  dbo.s_Voucher v
        INNER JOIN dbo.s_Getin g ON g.VouchGUID = v.VouchGUID
        WHERE g.SaleType = '特殊业绩' AND (v.VouchStatus IS NULL OR  v.VouchStatus = '')
        GROUP BY v.SaleGUID,MONTH(g.GetDate),YEAR(g.GetDate)
) yj ON yj.SaleGUID = b.PerformanceAppraisalGUID
left join p_Building bd on a.BldGUID = bd.BldGUID
inner join mdm_salebuild sb on sb.SaleBldGUID = bd.BldGUID
inner join mdm_Product pr on pr.ProductGUID = sb.ProductGUID
left join p_project p on p.ProjGUID = bd.ProjGUID
left join p_project pp on p.ParentCode = pp.ProjCode
WHERE   b.AuditStatus = '已审核'
        AND b.YjType NOT IN ('经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)')
        -- AND pp.ProjGUID = @var_projguid
UNION
SELECT  pp.ProjGUID,
        pp.SpreadName as ProjName,
        p.projguid as StageGUID,
        concat(pp.SpreadName,'-',p.ProjShortName) as StageName,
        bd.BldGUID,
        bd.BldName,
        pr.ProductGUID,
        CONCAT(md_productnamemodule.producttype,'-',md_room.productname,'-',md_room.businesstype,'-',case when md_room.zxbz ='' then pr.Standard else md_room.zxbz end) AS ProductName,
        --特殊业绩回笼,关联房间回笼按照认定金额比例分摊
        t.回笼年,
        t.回笼月份,
        sum(CASE WHEN ISNULL(b.TotalAmount, 0) = 0 THEN 0 ELSE ISNULL(t.huilongjiner, 0) * (ISNULL(a.AmountDetermined, 0) * 1.00 / ISNULL(b.TotalAmount, 0)) END) AS huilongjiner
FROM    S_PerformanceAppraisalRoom a
LEFT JOIN S_PerformanceAppraisal b ON b.PerformanceAppraisalGUID = a.PerformanceAppraisalGUID
LEFT JOIN dbo.ep_room r on a.RoomGUID = r.RoomGUID
LEFT JOIN (
        SELECT    v.SaleGUID ,
                YEAR(g.GetDate) as 回笼年,
                MONTH(g.GetDate) as 回笼月份,
                SUM(ISNULL(g.RmbAmount, 0)) AS huilongjiner 
        FROM  dbo.s_Voucher v
            INNER JOIN dbo.s_Getin g ON g.VouchGUID = v.VouchGUID
        WHERE g.SaleType = '特殊业绩' AND (v.VouchStatus IS NULL OR  v.VouchStatus = '')
        GROUP BY v.SaleGUID,MONTH(g.GetDate),YEAR(g.GetDate)
) t ON t.SaleGUID = b.PerformanceAppraisalGUID
left join p_Building bd on r.BldGUID = bd.BldGUID
inner join mdm_salebuild sb on sb.SaleBldGUID = bd.BldGUID
inner join mdm_Product pr on pr.ProductGUID = sb.ProductGUID
left join p_project p on p.ProjGUID = bd.ProjGUID
left join p_project pp on p.ParentCode = pp.ProjCode
LEFT JOIN MyCost_Erp352.DBO.md_room md_room ON md_room.roomguid = r.roomguid
left join MyCost_Erp352.DBO.md_productnamemodule on md_productnamemodule.productnamecode = md_room.productnamecode
WHERE   b.AuditStatus = '已审核'
        --AND b.YjType<>'经营类'
        AND b.YjType NOT IN ('经营类(reits)', '经营类(溢价款)', '经营类(自持业绩认定)', '经营类(租金)')
        -- AND pp.ProjGUID = @var_projguid
GROUP BY pp.ProjGUID,
        pp.SpreadName ,
        p.projguid ,
        concat(pp.SpreadName,'-',p.ProjShortName) ,
        bd.BldGUID,
        bd.BldName,
        pr.ProductGUID,
        CONCAT(md_productnamemodule.producttype,'-',md_room.productname,'-',md_room.businesstype,'-',case when md_room.zxbz ='' then pr.Standard else md_room.zxbz end),
        t.回笼年,t.回笼月份;

--合作业绩房间
SELECT 
    p.ProjGUID,
    p.ProjName,
    a.ProjGUID as StageGUID,
    stage.ProjName as StageName,
    a.ProductGUID,
    concat(a.ProductType,'-',a.ProductName,'-',a.RoomType,'-',a.zxbz) as ProductName,
    hzyj.DateYear as 回笼年,
    hzyj.DateMonth as 回笼月份,
    sum(a.huilongjiner) as 回笼金额
into #hzyj
FROM dbo.s_YJRLProducteDescript a
LEFT JOIN vs_HzyjFinaceBase hzyj ON a.ProducteDetailGUID = hzyj.ProducteDetailGUID
LEFT JOIN
(
    SELECT *,
        CONVERT(DATETIME, b.DateYear + '-' + b.DateMonth + '-01') AS [BizDate]
    FROM dbo.s_YJRLProducteDetail b
    WHERE b.Shenhe = '审核'
) b ON b.ProducteDetailGUID = a.ProducteDetailGUID
LEFT JOIN dbo.s_YJRLProjSet c ON c.ProjSetGUID = b.ProjSetGUID
LEFT JOIN dbo.p_Project p ON p.ProjGUID = c.ProjGUID
LEFT JOIN dbo.p_Project stage ON stage.ProjGUID = a.ProjGUID
LEFT JOIN dbo.myBusinessUnit bu ON bu.BUGUID = c.BUGuid
WHERE b.Shenhe = '审核'
   -- AND p.ProjGUID = @var_projguid
group by p.ProjGUID,
    p.ProjName,
    a.ProjGUID,
    stage.ProjName,
    a.ProductGUID,
    concat(a.ProductType,'-',a.ProductName,'-',a.RoomType,'-',a.zxbz) ,
    hzyj.DateYear,
    hzyj.DateMonth


--获取存在应收的签约
SELECT c.contractguid,
       c.tradeguid,
       c.roomguid,
	   r.roominfo,
       c.lastsaleguid,
       c.qsdate,
       c.jytotal+ isnull(c.sjbctotal,0) as jytotal,
       c.PayformName,
	   pp.ProjGUID,
	   pp.SpreadName as ProjName,
       c.projguid as StageGUID,
	   concat(pp.SpreadName,'-',p.ProjShortName) as StageName,
	   b.BldGUID,
       b.bldName,
       fee.Amount as ysAmount,
       fee.FDK_YE as FDK_YE,
       fee.YHAJ_YE as YHAJ_YE,
       fee.GJJ_YE as GJJ_YE,
       getin.RmbAmount as ssAmount,
       getin.GetDate,
       pr.ProductGUID,
       --concat(pr.ProductName,'-',pr.BusinessType,'-',pr.Standard) as ProductName
       CONCAT(md_productnamemodule.producttype,'-',md_room.productname,'-',md_room.businesstype,'-',case when md_room.zxbz ='' then pr.Standard else md_room.zxbz end) AS ProductName
INTO #con_ys
FROM s_contract c
LEFT JOIN ep_room r ON c.roomguid = r.roomguid
left join p_Building b on r.BldGUID = b.BldGUID
inner join mdm_salebuild sb on sb.SaleBldGUID = b.BldGUID
inner join mdm_Product pr on pr.ProductGUID = sb.ProductGUID
left join p_project p on p.ProjGUID = c.ProjGUID
left join p_project pp on p.ParentCode = pp.ProjCode
LEFT JOIN (
   select tradeguid,
        sum(Amount) as Amount,
        sum(ISNULL(Ye, 0) - ISNULL(DsAmount, 0)) AS Ye,
        SUM(CASE WHEN  ItemType in ('非贷款类房款') THEN ISNULL(Ye, 0) - ISNULL(DsAmount, 0) ELSE 0 END) AS FDK_YE,
        SUM(CASE WHEN  ItemType in ('贷款类房款') AND ITEMNAME ='银行按揭' THEN ISNULL(Ye, 0) - ISNULL(DsAmount, 0) ELSE 0 END) AS YHAJ_YE,
        SUM(CASE WHEN  ItemType in ('贷款类房款') AND ITEMNAME ='公积金' THEN ISNULL(Ye, 0) - ISNULL(DsAmount, 0) ELSE 0 END) AS GJJ_YE
    from s_fee 
    where  ItemType in ('非贷款类房款','贷款类房款') 
    group by tradeguid 
) fee on fee.tradeguid = c.tradeguid
LEFT JOIN (
    select saleguid,
        sum(RmbAmount) as RmbAmount,
        max(GetDate) as GetDate
    from s_getin  g
    where  ItemType in ('非贷款类房款','贷款类房款') 
        and g.status is null
    group by saleguid
) getin on getin.saleguid = c.tradeguid
LEFT JOIN MyCost_Erp352.DBO.md_room md_room ON md_room.roomguid = r.roomguid
left join (
    select md_productbuild.productbuildguid,
        md_productbuild.bldname as productbldname,
        md_gcbuild.bldname as projectbldname
    from MyCost_Erp352.DBO.md_productbuild
    inner join MyCost_Erp352.DBO.md_gcbuild on md_gcbuild.bldkeyguid = md_productbuild.bldkeyguid and md_gcbuild.isactive = 1
) bld on md_room.productbldguid = bld.productbuildguid
left join MyCost_Erp352.DBO.md_productnamemodule on md_productnamemodule.productnamecode = md_room.productnamecode
WHERE c.status = '激活' 
   -- and pp.projguid = @var_projguid;


--应收 贷款类 公积金
SELECT 
    t.ProjGUID,
    t.ProjName,
    t.StageGUID,
    t.StageName,
    t.BldGUID,
    t.BldName,
    t.ProductGUID,
	t.ProductName,
    year(DATEADD(MONTH, rate.months, @tqrq)) as 回笼年,
    month(DATEADD(MONTH, rate.months, @tqrq)) as 回笼月份,
	t.fdkys * rate.占比*1.0000 as 贷款类_公积金已售未回金额
INTO #ys_dkl_gjj
FROM (
	SELECT 
        v.ProjGUID,
        v.ProjName,
        v.StageGUID,
        v.StageName,
        v.BldGUID,
        v.BldName,
        v.ProductGUID,
        v.ProductName,
        SUM(v.GJJ_YE) fdkys
	from #con_ys v 
	group by v.ProjGUID,
        v.ProjName,
        v.StageGUID,
        v.StageName,
        v.BldGUID,
        v.BldName,
        v.ProductGUID,
        v.ProductName
) t
LEFT JOIN #dk_rate rate on rate.ItemName ='公积金' and rate.ProductName = t.ProductName

-- 应收 贷款类 银行按揭
SELECT 
    t.ProjGUID,
    t.ProjName,
    t.StageGUID,
    t.StageName,
    t.BldGUID,
    t.BldName,
    t.ProductGUID,
	t.ProductName,
    year(DATEADD(MONTH, rate.months, @tqrq)) as 回笼年,
    month(DATEADD(MONTH, rate.months, @tqrq)) as 回笼月份,
	t.fdkys * rate.占比*1.0000 as 贷款类_按揭已售未回金额
INTO #ys_dkl_yhaj
FROM (
	SELECT 
        v.ProjGUID,
        v.ProjName,
        v.StageGUID,
        v.StageName,
        v.BldGUID,
        v.BldName,
        v.ProductGUID,
        v.ProductName,
        SUM(YHAJ_YE) fdkys
	FROM #con_ys v 
	group by v.ProjGUID,
        v.ProjName,
        v.StageGUID,
        v.StageName,
        v.BldGUID,
        v.BldName,
        v.ProductGUID,
        v.ProductName
) t
LEFT JOIN #dk_rate rate on rate.ItemName ='银行按揭' and rate.ProductName = t.ProductName

-- 应收 非贷款类 已售未回款金额
SELECT 
    v.ProjGUID,
    v.ProjName,
    v.StageGUID,
    v.StageName,
    v.BldGUID,
    v.BldName,
    v.ProductGUID,
    v.ProductName,
    year(s.lastDate) as 回笼年,
    month(s.lastDate) as 回笼月份,
    SUM(ISNULL(Ye, 0) - ISNULL(DsAmount, 0)) AS 非贷款类已售未回款金额
INTO #ys_fdk
FROM s_fee s
INNER JOIN #con_ys v ON s.TradeGUID = v.tradeguid
WHERE s.ItemType IN ('非贷款类房款') 
GROUP BY v.ProjGUID,
        v.ProjName,
        v.StageGUID,
        v.StageName,
        v.BldGUID,
        v.BldName,
        v.ProductGUID,
        v.ProductName,
        year(s.lastDate),
        month(s.lastDate)

select 
    t.ProjGUID,
    t.ProjName,
    t.StageGUID,
    t.StageName,
    t.BldGUID,
    t.BldName,
    t.ProductGUID,
    replace(t.ProductName,'精装','装修') as ProductName,
    t.回笼年,
    t.回笼月份,
	concat(t.回笼年,'/',right('0' + cast(t.回笼月份 as varchar(2)),2)) as 年月,
    cast(sum(t.回笼金额) as decimal(18,6))  as 回笼金额,
    cast(sum(t.非贷款类已售未回款金额) as decimal(18,6))  as 非贷款类已售未回款金额,
    cast(sum(t.贷款类_公积金已售未回金额) as decimal(18,6))  as 贷款类_公积金已售未回金额,
    cast(sum(t.贷款类_按揭已售未回金额) as decimal(18,6))  as 贷款类_按揭已售未回金额,
    cast((sum(t.非贷款类已售未回款金额) + sum(t.贷款类_公积金已售未回金额) + sum(t.贷款类_按揭已售未回金额)) as decimal(18,4)) as 已售未回款金额
from (
    select ProjGUID,ProjName,StageGUID,StageName,BldGUID,BldName,ProductGUID,ProductName,回笼年,回笼月份,回笼金额,0 as 非贷款类已售未回款金额,0 as 贷款类_公积金已售未回金额,0 AS 贷款类_按揭已售未回金额
    from #getin --回笼金额
    union all 
    select ProjGUID,ProjName,StageGUID,StageName,BldGUID,BldName,ProductGUID,ProductName,回笼年,回笼月份,huilongjiner as 回笼金额,0 as 非贷款类已售未回款金额,0 as 贷款类_公积金已售未回金额,0 AS 贷款类_按揭已售未回金额
    from #ts
    union all 
    select ProjGUID,ProjName,StageGUID,StageName,null as BldGUID,null as BldName,ProductGUID,ProductName,回笼年,回笼月份,回笼金额,0 as 非贷款类已售未回款金额,0 as 贷款类_公积金已售未回金额,0 AS 贷款类_按揭已售未回金额
    from #hzyj
    union all 
    select ProjGUID,ProjName,StageGUID,StageName,BldGUID,BldName,ProductGUID,ProductName,回笼年,回笼月份,0 as 回笼金额,0 as 非贷款类已售未回款金额,贷款类_公积金已售未回金额,0 AS 贷款类_按揭已售未回金额
    from #ys_dkl_gjj --贷款类_公积金已售未回金额
    union all 
    select ProjGUID,ProjName,StageGUID,StageName,BldGUID,BldName,ProductGUID,ProductName,回笼年,回笼月份,0 as 回笼金额,0 as 非贷款类已售未回款金额,0 as 贷款类_公积金已售未回金额,贷款类_按揭已售未回金额 
    from #ys_dkl_yhaj --贷款类_按揭已售未回金额
    union all 
    select ProjGUID,ProjName,StageGUID,StageName,BldGUID,BldName,ProductGUID,ProductName,回笼年,回笼月份,0 as 回笼金额,非贷款类已售未回款金额,0 as 贷款类_公积金已售未回金额,0 AS 贷款类_按揭已售未回金额
    from #ys_fdk --非贷款类已售未回款金额
) t
group by t.ProjGUID,
    t.ProjName,
    t.StageGUID,
    t.StageName,
    t.BldGUID,
    t.BldName,
    t.ProductGUID,
    replace(t.ProductName,'精装','装修'),
    t.回笼年,
    t.回笼月份;

END