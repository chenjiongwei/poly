

--逾期录入率红黑榜
-- 查询结果
SELECT *,
         /*
         入榜规则：年度有认购项目
        红榜评分规则：
        红榜 <=20%
        黑榜评分规则：
        黑榜 >20%
        */
        case when 总认购套数 > 0 and 逾期录入率 <=0.2 then 
           -- 红榜评分
            case 
                when  逾期录入率 <=0.2  and  逾期录入率 >0.05 then '及格'
                when  逾期录入率 <=0.05 and 逾期录入率> 0  then '良好'
                when  逾期录入率 <= 0 then '优秀'                      
            end 
         else  
            -- 黑榜评分
            case  
                when  逾期录入率 > 0.3 then '严重不及格'
                when  逾期录入率 > 0.2 and 逾期录入率 <=0.3  then '不及格'
            end 
         end    as 评分,
     case when  总认购套数 > 0  and  逾期录入率 <=0.2 then '红榜' else '黑榜' end 红黑榜       
into #ztfl
FROM (
    select 
        片区,
        组团,
        推广名,
        项目责任人,
        项目简称,
        sum(总认购套数) as 总认购套数,
        sum(逾期录入套数) as 逾期录入套数,
        case when sum(总认购套数) = 0 then 0 ELSE sum(逾期录入套数)/sum(总认购套数) end as 逾期录入率
    from data_wide_dws_s_nkfx
    where 年份 = year(getdate())
    group by 片区,
        组团,
        推广名,
        项目责任人,
        项目简称
    having sum(总认购套数) > 0
) t  

-- 排序
SELECT  
        t.*,
        CASE 
            WHEN 正序 = 1 THEN 1 
            WHEN 正序 = 2 THEN 2
            WHEN 正序 = 3 THEN 3
            WHEN 倒序 = 3 THEN 6
            WHEN 倒序 = 2 THEN 5
            WHEN 倒序 = 1 THEN 4
            WHEN 正序 > 3 THEN 正序 + 3  -- 首先是红榜前三，然后是黑榜后三，然后才正常排序
        END AS 排序,
        CASE 
            WHEN 倒序 = 1 THEN '倒数第一'
            WHEN 倒序 = 2 THEN '倒数第二'   
            WHEN 倒序 = 3 THEN '倒数第三' 
            ELSE CONVERT(VARCHAR(20), 正序) 
        END AS 序号
FROM (
    SELECT 
            *,
            rank() OVER(ORDER BY 红黑榜 DESC , 逾期录入率 ) AS 正序,
            rank() OVER(ORDER BY 红黑榜 ,逾期录入率 DESC ) AS 倒序
    FROM #ztfl 
) t
where 1=1
       and ((${var_biz} in ('全部区域','全部项目','全部组团')) --若前台选择“全部区域”、“全部项目”、“全部组团”，则按照公司来统计
       or (${var_biz} = t.片区) --前台选择了具体某个区域
       or (${var_biz} = t.组团) --前台选择了具体某个组团
       or (${var_biz}  = t.推广名)) --前台选择了具体某个项目 

DROP TABLE #ztfl;