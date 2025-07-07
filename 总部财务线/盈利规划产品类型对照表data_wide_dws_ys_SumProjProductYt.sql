select 
    t.*,
    pr.topproducttypename topproducttype,
    case 
        when producttype = '不区分业态' then ProductType 
        else ProductType + right(YtName, len(ytname) - CHARINDEX('_', YtName) + 1) 
    end ytname_my
from (
    select DISTINCT 
        resultTemp.ProjGUID,
        resultTemp.业态 YtName,
        case 
            when resultTemp.ProductType like '%别墅%' then replace(resultTemp.producttype, '别墅', '高级住宅')
            when resultTemp.producttype in ('独栋', '双拼', '联排', '叠拼') then resultTemp.producttype + '企业会所'
            when resultTemp.producttype = '其他' then '其他（地下）' 
            else resultTemp.ProductType 
        end ProductType,
		-- resultTemp.版本 as BusinessEdition,
        case 
            when ver.newest_version IS NOT null then 1 
            else 0 
        end as IsBase
    from (
        select DISTINCT 
            ProjGUID,
            版本,
            业态,
            case 
                when CHARINDEX('_', 业态) > 0 then SUBSTRING(业态, 0, CHARINDEX('_', 业态)) 
                else 业态 
            end as ProductType 
        from (
            select 
                upper([实体分期]) as ProjGUID,
                版本,
                业态  
            from data_wide_qt_F080004 
            group by 
                upper([实体分期]),
                版本,
                业态
        ) temp
    ) resultTemp 
    inner join (
        select 
            ROW_NUMBER() OVER (PARTITION BY f2.版本, f2.实体分期 ORDER BY f2.value_string DESC) rowno,
            f2.*
        from data_wide_qt_F200003 f2 
        INNER JOIN data_wide_qt_f400003年度版本实际数月份 f4 
            ON f4.版本 = f2.版本 
            AND f4.指标库明细说明 = '版本实际数月份' 
            and f2.轮循归档科目 = '归档源版本'
    ) f2 
        on upper(f2.[实体分期]) = resultTemp.ProjGUID 
        and (f2.value_string = resultTemp.版本 or f2.[版本] = resultTemp.版本)
    LEFT JOIN data_wide_qt_newest_version ver 
        ON f2.[版本] = ver.newest_version
    inner join data_wide_dws_ys_ProjGUID proj 
        on upper(f2.[实体分期]) = proj.YLGHProjGUID 
        and f2.rowno = 1  
        and proj.Level = 3 
        and proj.edition = f2.[版本] 
        and proj.BusinessEdition = f2.value_string 
    left join data_wide_dws_ys_ProjGUID pproj 
        on pproj.YLGHProjGUID = proj.YLGHParentGUID 
        and pproj.edition = proj.edition  
        and pproj.BusinessEdition = proj.BusinessEdition
) t
left join (
    select 
        producttypename, 
        topproducttypename 
    from data_wide_dws_mdm_product 
    group by 
        producttypename, 
        topproducttypename
) pr on pr.producttypename = t.producttype
