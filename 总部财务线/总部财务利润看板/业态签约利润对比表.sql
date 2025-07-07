with yt as (
    -- 开始计算业态层级的签约利润对比
    SELECT  
        a.清洗时间,
        a.清洗版本,
        a.公司,
        a.投管代码,
        a.项目GUID,
        a.项目,
        a.推广名,
        a.获取日期,
        a.我方股比,
        a.是否并表,
        a.合作方,
        a.是否风险合作方,
        a.地上总可售面积 /10000.0 as 地上总可售面积, -- 单位万平米
        a.项目地价 /100000000.0 as 项目地价, -- 单位亿元
        a.盈利规划上线方式,
        a.产品类型,
        a.产品名称,
        a.装修标准,
        a.商品类型,
        a.明源匹配主键,
        a.业态组合键,
        
        -- 立项利润
        a.立项货值 /100000000.0 as 立项货值, -- 单位亿元
        a.税后利润 /100000000.0 as 税后利润, -- 单位亿元
        a.销售净利率,

        -- 24年签约数据
        a.签约_24年签约,
        a.签约不含税_24年签约,
        a.签约面积_24年签约,
        a.净利润_24年签约,
        -- 如果并表方式为“我司并表”，则报表利润=净利润，否则用我方股比*净利润
        case when a.是否并表 = '我司并表' then a.净利润_24年签约 else isnull(a.我方股比,0)/100.0 * a.净利润_24年签约 end as 报表利润_24年签约,
        a.净利率_24年签约,
        a.签约均价_24年签约,
        a.营业成本单方_24年签约,
        a.营销费用单方_24年签约,
        a.管理费用单方_24年签约,
        a.税金单方_24年签约,
        -- 25年预算数据
        a.签约_25年预算,
        a.签约不含税_25年预算,
        a.签约面积_25年预算,
        a.净利润_25年预算,
        -- 如果并表方式为“我司并表”，则报表利润=净利润，否则用我方股比*净利润
        case when a.是否并表 = '我司并表' then a.净利润_25年预算 else isnull(a.我方股比,0)/100.0 * a.净利润_25年预算 end as 报表利润_25年预算,
        a.净利率_25年预算,
        a.签约均价_25年预算,
        a.营业成本单方_25年预算,
        a.营销费用单方_25年预算,
        a.管理费用单方_25年预算,
        a.税金单方_25年预算,
        -- 25年签约数据
        a.签约_25年签约,
        a.签约不含税_25年签约,
        a.签约面积_25年签约,
        a.净利润_25年签约,
        -- 如果并表方式为“我司并表”，则报表利润=净利润，否则用我方股比*净利润
        case when a.是否并表 = '我司并表' then a.净利润_25年签约 else isnull(a.我方股比,0)/100.0 * a.净利润_25年签约 end as 报表利润_25年签约,
        a.净利率_25年签约,
        a.签约均价_25年签约,
        a.营业成本单方_25年签约,
        a.营销费用单方_25年签约,
        a.管理费用单方_25年签约,
        a.税金单方_25年签约,
        -- 项目维度
        b.项目是否有利润预算,
        b.项目是否有24年利润,
        --较预算对比
        b.项目预算净利率,
        case when b.项目是否有利润预算 = '是' then isnull(a.净利率_25年签约, 0) - isnull(b.项目预算净利率, 0) end as 项目实际较预算偏差,
        -- 较24年对比
        b.项目24年净利率,
        case when b.项目是否有24年利润 = '是' then isnull(a.净利率_25年签约, 0) - isnull(b.项目24年净利率, 0) end as 项目实际较24年对比,
        -- 较立项对比
        b.项目立项净利率,
        isnull(a.净利率_25年签约, 0) - isnull(b.项目立项净利率, 0) as 项目实际较立项对比,

        -- 业态较预算对比
        a.净利率_25年预算 AS 业态预算净利率,
        case when isnull(a.净利率_25年预算,0)<> 0 then  isnull(a.净利率_25年签约,0)  - isnull(a.净利率_25年预算,0) end AS 业态实际较预算偏差,
        -- 较24年对比
        a.净利率_24年签约 AS 业态24年净利率,
        case when isnull(a.净利率_24年签约,0)<> 0 then  isnull(a.净利率_25年签约,0)  - isnull(a.净利率_24年签约,0) end as 业态实际较24年对比,

        --对比因素变化
        -- 判断是否有预算
        case when b.项目是否有利润预算 = '是' then 
           case when isnull(a.签约均价_25年预算, 0) =0 then 0
            else  (isnull(a.签约均价_25年签约, 0)  - isnull(a.签约均价_25年预算, 0)) / isnull(a.签约均价_25年预算, 0) end 
        else 
           case when isnull(a.签约均价_24年签约, 0) =0 then 0
             else  (isnull(a.签约均价_25年签约, 0)  - isnull(a.签约均价_24年签约, 0)) / isnull(a.签约均价_24年签约, 0) end 
        end  as 售价下降率, -- (25年实际签约均价-25年预算签约均价)/25年预算签约均价
        case when b.项目是否有利润预算 = '是' then 
            case when isnull(a.营业成本单方_25年预算, 0) =0 then 0
            else  (isnull(a.营业成本单方_25年签约, 0)  - isnull(a.营业成本单方_25年预算, 0)) / isnull(a.营业成本单方_25年预算, 0) end 
        else 
            case when isnull(a.营业成本单方_24年签约, 0) =0 then 0
            else  (isnull(a.营业成本单方_25年签约, 0)  - isnull(a.营业成本单方_24年签约, 0)) / isnull(a.营业成本单方_24年签约, 0) end 
        end  as 成本增加率,
        case when b.项目是否有利润预算 = '是' then 
            case when isnull(a.营销费用单方_25年预算, 0) =0 then 0
            else  (isnull(a.营销费用单方_25年签约, 0)  - isnull(a.营销费用单方_25年预算, 0)) / isnull(a.营销费用单方_25年预算, 0) end 
        else 
            case when isnull(a.营销费用单方_24年签约, 0) =0 then 0
            else  (isnull(a.营销费用单方_25年签约, 0)  - isnull(a.营销费用单方_24年签约, 0)) / isnull(a.营销费用单方_24年签约, 0) end 
        end  as 营销费用增加率,
        case when b.项目是否有利润预算 = '是' then 
            case when isnull(a.管理费用单方_25年预算, 0) =0 then 0
            else  (isnull(a.管理费用单方_25年签约, 0)  - isnull(a.管理费用单方_25年预算, 0)) / isnull(a.管理费用单方_25年预算, 0) end 
        else 
            case when isnull(a.管理费用单方_24年签约, 0) =0 then 0
            else  (isnull(a.管理费用单方_25年签约, 0)  - isnull(a.管理费用单方_24年签约, 0)) / isnull(a.管理费用单方_24年签约, 0) end 
        end  as 管理费用增加率,
        case when b.项目是否有利润预算 = '是' then 
            case when isnull(a.税金单方_25年预算, 0) =0 then 0
            else  (isnull(a.税金单方_25年签约, 0)  - isnull(a.税金单方_25年预算, 0)) / isnull(a.税金单方_25年预算, 0) end 
        else 
            case when isnull(a.税金单方_24年签约, 0) =0 then 0
            else  (isnull(a.税金单方_25年签约, 0)  - isnull(a.税金单方_24年签约, 0)) / isnull(a.税金单方_24年签约, 0) end 
        end  as 税金增加率,

        --偏差原因分类(较预算/24年对比)
    --    case when  a.签约均价_25年签约 <> 0  and a.签约均价_25年预算 <> 0  and a.签约面积_25年签约 <> 0
    --     then  (a.签约均价_25年签约 - isnull(a.签约均价_25年预算, a.签约均价_24年签约)) *  case when a.产品类型='地下室/车库' then a.签约面积_25年签约 /100000000.0 else a.签约面积_25年签约 /10000.0 end else 0 end   as 售价下降, --单位亿元
    --    case when a.营业成本单方_25年签约<> 0  and a.营业成本单方_25年预算 <> 0  and a.签约面积_25年签约 <> 0 
    --    then (a.营业成本单方_25年签约 - isnull(a.营业成本单方_25年预算, a.营业成本单方_24年签约)) *  case when a.产品类型='地下室/车库' then a.签约面积_25年签约 /100000000.0 else a.签约面积_25年签约 /10000.0 end else 0 end as 成本增加, --单位亿元
    --    case when a.营销费用单方_25年签约<> 0  and a.营销费用单方_25年预算 <> 0  and a.签约面积_25年签约 <> 0  
    --     then  (a.营销费用单方_25年签约 - isnull(a.营销费用单方_25年预算, a.营销费用单方_24年签约)) *  case when a.产品类型='地下室/车库' then a.签约面积_25年签约 /100000000.0 else a.签约面积_25年签约 /10000.0 end else 0 end as 营销费用增加, --单位亿元
    --    case when a.管理费用单方_25年签约<> 0  and a.管理费用单方_25年预算 <> 0  and a.签约面积_25年签约 <> 0  
    --     then (a.管理费用单方_25年签约 - isnull(a.管理费用单方_25年预算, a.管理费用单方_24年签约)) *  case when a.产品类型='地下室/车库' then a.签约面积_25年签约 /100000000.0 else a.签约面积_25年签约 /10000.0 end else 0 end as 管理费用增加, --单位亿元
    --    case when a.税金单方_25年签约<> 0  and a.税金单方_25年预算 <> 0  and a.签约面积_25年签约 <> 0  
    --     then (a.税金单方_25年签约 - isnull(a.税金单方_25年预算, a.税金单方_24年签约)) *  case when a.产品类型='地下室/车库' then a.签约面积_25年签约 /100000000.0 else a.签约面积_25年签约 /10000.0 end else 0 end as 税金增加, --单位亿元
    --     null as 其他,

       -- 判断是否有预算
       case when b.项目是否有利润预算 = '是' and a.签约均价_25年预算 <> 0 then 
            case when a.签约均价_25年签约 <> 0 and a.签约均价_25年预算 <> 0 and a.签约面积_25年签约 <> 0
                then (isnull(a.签约均价_25年签约, 0) - isnull(a.签约均价_25年预算, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0 
            end 
        -- 没有预算，取24年签约
        when b.项目是否有利润预算 = '否' and a.签约均价_24年签约 <> 0 then 
            case when a.签约均价_25年签约 <> 0 and a.签约均价_24年签约 <> 0 and a.签约面积_25年签约 <> 0
                then (isnull(a.签约均价_25年签约, 0) - isnull(a.签约均价_24年签约, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0 
            end 
        else 0
        end as 售价下降, --单位亿元
       
       case when b.项目是否有利润预算 = '是' and a.营业成本单方_25年预算 <> 0 then 
            case when a.营业成本单方_25年签约 <> 0 and a.营业成本单方_25年预算 <> 0 and a.签约面积_25年签约 <> 0 
                then (isnull(a.营业成本单方_25年签约, 0) - isnull(a.营业成本单方_25年预算, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0
            end
        when b.项目是否有利润预算 = '否' and a.营业成本单方_24年签约 <> 0 then 
            case when a.营业成本单方_25年签约 <> 0 and a.营业成本单方_24年签约 <> 0 and a.签约面积_25年签约 <> 0 
                then (isnull(a.营业成本单方_25年签约, 0) - isnull(a.营业成本单方_24年签约, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0
            end
        else 0
        end as 成本增加, --单位亿元
       
       case when b.项目是否有利润预算 = '是' and a.营销费用单方_25年预算 <> 0 then 
            case when a.营销费用单方_25年签约 <> 0 and a.营销费用单方_25年预算 <> 0 and a.签约面积_25年签约 <> 0  
                then (isnull(a.营销费用单方_25年签约, 0) - isnull(a.营销费用单方_25年预算, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0 
            end 
        when b.项目是否有利润预算 = '否' and a.营销费用单方_24年签约 <> 0 then 
            case when a.营销费用单方_25年签约 <> 0 and a.营销费用单方_24年签约 <> 0 and a.签约面积_25年签约 <> 0  
                then (isnull(a.营销费用单方_25年签约,0) - isnull(a.营销费用单方_24年签约,0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0
            end
        else 0
        end as 营销费用增加, --单位亿元

       case when b.项目是否有利润预算 = '是' and a.管理费用单方_25年预算 <> 0 then 
            case when a.管理费用单方_25年签约 <> 0 and a.管理费用单方_25年预算 <> 0 and a.签约面积_25年签约 <> 0  
                then (isnull(a.管理费用单方_25年签约, 0) - isnull(a.管理费用单方_25年预算, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0 
            end 
        when b.项目是否有利润预算 = '否' and a.管理费用单方_24年签约 <> 0 then 
            case when a.管理费用单方_25年签约 <> 0 and a.管理费用单方_24年签约 <> 0 and a.签约面积_25年签约 <> 0  
                then (isnull(a.管理费用单方_25年签约, 0) - isnull(a.管理费用单方_24年签约, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0
            end
        else 0
        end as 管理费用增加, --单位亿元
       
       case when b.项目是否有利润预算 = '是' and a.税金单方_25年预算 <> 0 then 
            case when a.税金单方_25年签约 <> 0 and a.税金单方_25年预算 <> 0 and a.签约面积_25年签约 <> 0  
                then (isnull(a.税金单方_25年签约, 0) - isnull(a.税金单方_25年预算, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0 
            end 
        when b.项目是否有利润预算 = '否' and a.税金单方_24年签约 <> 0 then 
            case when a.税金单方_25年签约 <> 0 and a.税金单方_24年签约 <> 0 and a.签约面积_25年签约 <> 0  
                then (isnull(a.税金单方_25年签约, 0) - isnull(a.税金单方_24年签约, 0)) * 
                    case 
                        when a.产品类型='地下室/车库' then a.签约面积_25年签约 / 100000000.0 
                        else a.签约面积_25年签约 / 10000.0 
                    end 
                else 0
            end
        else 0
        end as 税金增加, --单位亿元
        
       null as 其他,


        a.签约均价_25年签约 as 签约均价_本年,
        a.签约_本月实际,
        a.签约不含税_本月实际,
        a.签约面积_本月实际,
        a.签约均价_本月实际,
        a.认购_本月实际,
        a.认购不含税_本月实际,
        a.认购面积_本月实际,
        a.认购均价_本月实际,
        a.签约_上月实际,
        a.签约不含税_上月实际,
        a.签约面积_上月实际,
        a.签约均价_上月实际,
        a.认购_上月实际,
        a.认购不含税_上月实际,
        a.认购面积_上月实际,
        a.认购均价_上月实际,
        a.签约_上上月实际,
        a.签约不含税_上上月实际,
        a.签约面积_上上月实际,
        a.签约均价_上上月实际,
        
        --是否连续两个月对标数下降10个百分点
        a.净利润_本月实际,
        a.净利率_本月实际,
        a.净利润_上月实际,
        a.净利率_上月实际,
        a.净利润_上上月实际,
        a.净利率_上上月实际,

        -- 对标数 --（有预算取预算，没有预算取24年签约，没有24年签约取立项版）
        case when a.净利率_25年预算 is not null then a.净利率_25年预算
            when a.净利率_24年签约 is not null then a.净利率_24年签约
            when a.销售净利率 is not null then a.销售净利率
        end as 净利率_对标数
    FROM 业态签约利润对比表 a
    LEFT JOIN (
        SELECT  
            项目GUID,
            CASE WHEN SUM(净利润_25年预算) <> 0 THEN '是' ELSE '否' END AS 项目是否有利润预算,
            CASE WHEN SUM(净利润_24年签约) <> 0 THEN '是' ELSE '否' END AS 项目是否有24年利润,
            CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 项目预算净利率,
            -- CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END
            --     - CASE WHEN SUM(签约不含税_25年预算) = 0 THEN 0 ELSE SUM(净利润_25年预算) / SUM(签约不含税_25年预算) END AS 项目实际较预算偏差,
            
            CASE WHEN SUM(签约不含税_24年签约) = 0 THEN 0 ELSE SUM(净利润_24年签约) / SUM(签约不含税_24年签约) END AS 项目24年净利率,
            -- CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END 
            --     - CASE WHEN SUM(签约不含税_24年签约) = 0 THEN 0 ELSE SUM(净利润_24年签约) / SUM(签约不含税_24年签约) END AS 项目实际较24年对比,
            
            CASE WHEN SUM(立项货值) = 0 THEN 0 ELSE SUM(税后利润) / SUM(立项货值) END AS 项目立项净利率
            -- CASE WHEN SUM(签约不含税_25年签约) = 0 THEN 0 ELSE SUM(净利润_25年签约) / SUM(签约不含税_25年签约) END 
            --     - CASE WHEN SUM(立项货值) = 0 THEN 0 ELSE SUM(税后利润) / SUM(立项货值) END AS 项目实际较立项对比
        FROM 业态签约利润对比表  
        WHERE DATEDIFF(DAY, GETDATE(), 清洗时间) = 0
        GROUP BY 项目GUID
    ) b ON a.项目GUID = b.项目GUID -- AND a.业态组合键 = b.业态组合键
    inner join [172.16.4.141].erp25.dbo.vmdm_projectFlagnew c on a.项目GUID = c.projGUID
    WHERE DATEDIFF(DAY, GETDATE(), a.清洗时间) = 0 and isnull(c.是否纳入动态利润分析,'') <> '否'
)

-- 是否连续两个月对标数下降10个百分点
SELECT 
    a.*,
    CASE 
        WHEN (a.净利率_本月实际 - a.净利率_对标数 < -0.1) 
             AND (a.净利率_上月实际 - a.净利率_对标数 < -0.1) 
        THEN '是' 
        ELSE '否' 
    END AS 是否连续两个月对标数下降10个百分点
FROM 
    yt a
WHERE  1=1