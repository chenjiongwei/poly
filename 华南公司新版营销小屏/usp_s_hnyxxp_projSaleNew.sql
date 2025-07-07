USE [HighData_prod]
GO
/****** Object:  StoredProcedure [dbo].[usp_s_hnyxxp_projSaleNew]    Script Date: 2025/7/3 19:46:09 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO





/*
修复区域负责人和组团负责人为空的情况
select * from  data_tb_hn_yxpq 
select  营销片区,组团负责人 into #zt  from  data_tb_hn_yxpq where  isnull(组团负责人,'')<>'' 
select distinct 营销片区  from  data_tb_hn_yxpq
select  营销事业部,区域负责人 into #qy  from data_tb_hn_yxpq where isnull( 区域负责人,'') <>'' 
select distinct 营销事业部  from  data_tb_hn_yxpq
select * into data_tb_hn_yxpq_bak20240425 from  data_tb_hn_yxpq
update a 
set  a.组团负责人 =b.组团负责人
--select a.营销片区,a.组团负责人 
from 
data_tb_hn_yxpq a
inner join #zt b on a.营销片区 =b.营销片区
where  isnull(a.组团负责人,'') = ''
select 108-95

update  a
set  a.区域负责人 =b.区域负责人
--select  * 
from data_tb_hn_yxpq a
inner join #qy  b  on a.营销事业部 =b.营销事业部
where isnull(a.区域负责人,'') = ''
*/

/*
华南销售小屏-经营业绩 清洗存储过程
declare @var_date datetime  =getdate()
exec usp_s_hnyxxp_projSaleNew @var_date
*/

--declare @var_date datetime  =getdate()
--exec usp_s_hnyxxp_projSaleNew @var_date

/*
2024-05-16 调整：
1、现在已经在填报表里面加了非项目本年实际签约金额、非项目本月实际签约金额、非项目本年实际认购金额、非项目本月实际认购金额这四个指标了，要分别在项目、区域、组团层级减去这四部分业绩，但是公司层级的不变；

*/

ALTER PROC [dbo].[usp_s_hnyxxp_projSaleNew](@var_date DATETIME)
AS
    BEGIN
        --declare @var_date datetime  =getdate()
        DECLARE @szyxfzr VARCHAR(200);

  --      --检查填报表将责任人为空的数据补齐
		--字段去掉前后空格
			UPDATE  data_tb_hn_yxpq
			SET 营销片区 = TRIM(营销片区) ,
			营销事业部 = TRIM(营销事业部) ,
			数字营销部负责人 = TRIM(数字营销部负责人) ,
			组团负责人 = TRIM(组团负责人) ,
			项目负责人 = TRIM(项目负责人) ,
			项目简称 = TRIM(项目简称)
			FROM    data_tb_hn_yxpq;

        -- 营销片区 的名称补全到4位
		update a
		 set a.营销片区 = case when  len(营销片区)  <=3  then  营销片区+ '    ' else 营销片区 end  
		--select  case when  len(营销片区)  <=3  then  营销片区+' ' else 营销片区 end  
		from  data_tb_hn_yxpq  a



        --组团同组团负责人对照表
        SELECT  营销片区 ,
                组团负责人
        INTO    #zt
        FROM    data_tb_hn_yxpq
        WHERE   ISNULL(组团负责人, '') <> '';

        SELECT  @szyxfzr = 数字营销部负责人
        FROM    data_tb_hn_yxpq
        WHERE   ISNULL(数字营销部负责人, '') <> '';

        --区域同区域负责人对照表
        SELECT  营销事业部 ,
                区域负责人
        INTO    #qy
        FROM    data_tb_hn_yxpq
        WHERE   ISNULL(区域负责人, '') <> '';

        --修复数据组团责任人为空的
        UPDATE  a
        SET a.组团负责人 = b.组团负责人
        FROM    data_tb_hn_yxpq a
                INNER JOIN #zt b ON a.营销片区 = b.营销片区
        WHERE   ISNULL(a.组团负责人, '') = '';

        --修复数据区域负责人为空的
        UPDATE  a
        SET a.区域负责人 = b.区域负责人
        FROM    data_tb_hn_yxpq a
                INNER JOIN #qy b ON a.营销事业部 = b.营销事业部
        WHERE   ISNULL(a.区域负责人, '') = '';

        UPDATE  a
        SET a.数字营销部负责人 = @szyxfzr
        FROM    data_tb_hn_yxpq a
        WHERE   ISNULL(a.数字营销部负责人, '') = '';

        --DECLARE @var_date DATETIME ='2025-06-23'  
        DECLARE @bzSDate DATETIME = DATEADD(WEEK, DATEDIFF(WEEK, 0, CONVERT(DATETIME, @var_date, 120) - 1), 0); --本周一
        DECLARE @bzEDate DATETIME = DATEADD(DAY, 6, DATEADD(WEEK, DATEDIFF(WEEK, 0, CONVERT(DATETIME, @var_date, 120) - 1), 0));

        --获取华南公司的所有楼栋一级产品类型信息
        --获取华南公司的所有楼栋一级产品类型信息
        SELECT  ParentProjGUID ,
                p.ProjName AS ParentProjName ,
                TopProductTypeName ,
                TopProductTypeGUID ,
                -- 佛山市顺德区华侨中学扩建工程等7所学校代 代建项目特殊处理，归入到其它类，不要在新增量分类中出现
                MAX(CASE WHEN ISNULL(tb.营销事业部, '') = '其他' OR ISNULL(tb.营销片区, '') = '其他' THEN '其它'
                         ELSE CASE WHEN YEAR(p.BeginDate) > 2022 THEN '新增量' WHEN YEAR(p.BeginDate) = 2022 THEN '增量' ELSE '存量' END
                    END) AS 存量增量 ,
                DATEDIFF(DAY, DATEADD(yy, DATEDIFF(yy, 0, @var_date), 0), @var_date) * 1.00 / 365 本年时间分摊比 ,
                DATEDIFF(DAY, DATEADD(mm, DATEDIFF(mm, 0, @var_date), 0), @var_date) * 1.00 / 30 AS 本月时间分摊比
        INTO    #TopProduct
        FROM    data_wide_dws_mdm_Building bd
        INNER JOIN data_wide_dws_mdm_Project p ON bd.ParentProjGUID = p.ProjGUID AND   p.Level = 2
        LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
        WHERE   bd.BldType = '产品楼栋' AND bd.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
        GROUP BY ParentProjGUID ,
                 p.ProjName ,
                 TopProductTypeName ,
                 TopProductTypeGUID;

        --获取其他业绩签约金额，就是以客户提供的项目清单，其中特殊业绩房间认定日期在往年，但是签约日期在今年的房间	 
        CREATE TABLE [dbo].#qtyj ([项目推广名] [NVARCHAR](255) NULL ,
                                  [明源系统代码] [NVARCHAR](255) NULL ,
                                  [项目代码] [NVARCHAR](255) NULL ,
                                  [认定日期] DATETIME);

        INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        VALUES(N'佛山保利环球汇', N'0757046', N'2937', N'2020-8-31');

        INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        VALUES(N'佛山保利西山林语', N'0757056', N'2946', N'2022-5-27');

        INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        VALUES(N'佛山保利紫晨花园', N'0757059', N'2950', N'2022-6-28');

        INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        VALUES(N'佛山保利紫山国际', N'0757028', N'2920', N'2022-6-27');

        INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        VALUES(N'茂名保利大都会', N'HN0668001', N'5801', N'2021-12-28');

        INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        VALUES(N'茂名保利中环广场', N'0668005', N'5806', N'2021-4-26');
	    
		INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        VALUES(N'阳江保利海陵岛', N'yjKF002', N'1702', N'2021-5-24');
        --INSERT  [dbo].#qtyj([项目推广名], [明源系统代码], [项目代码], [认定日期])
        --VALUES(N'阳江保利海陵岛', N'0662002', N'1702', N'2021-5-24');



        --查询其他业绩的签约金额
        SELECT  p.projguid ,
                bld.TopProductTypeName ,

                SUM(CASE WHEN DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩本日认购金额 ,
                SUM(CASE WHEN DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩本日认购面积 ,
                SUM(CASE WHEN DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩本日认购套数 ,

                SUM(CASE WHEN DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩本周认购金额 ,
                SUM(CASE WHEN DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN r.CjBldArea ELSE 0 END)  AS 其他业绩本周认购面积 ,
		        SUM(CASE WHEN DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN 1 ELSE 0 END) AS 其他业绩本周认购套数 ,

                SUM(CASE WHEN DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩本月认购金额 ,
				SUM(CASE WHEN DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩本月认购面积 ,
                SUM(CASE WHEN DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩本月认购套数 ,

                SUM(CASE WHEN YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩本年认购金额 ,
                SUM(CASE WHEN YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩本年认购面积 ,
                SUM(CASE WHEN YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩本年认购套数 ,

                SUM(CASE WHEN r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩本年签约金额 ,
				 SUM(CASE WHEN r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩本年签约面积 ,
                SUM(CASE WHEN r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩本年签约套数 ,

                SUM(CASE WHEN r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩本月签约金额 ,
                SUM(CASE WHEN r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩本月签约面积,
                SUM(CASE WHEN r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩本月签约套数,

				-- 产成品
				SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩产成品本日认购金额 ,
			    SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩产成品本日认购面积 ,
                SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩产成品本日认购套数 ,

                SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩产成品本周认购金额 ,
       		    SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN r.CjBldArea ELSE 0 END) AS 其他业绩产成品本周认购面积 ,         
				SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN 1 ELSE 0 END) AS 其他业绩产成品本周认购套数 ,

                SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩产成品本月认购金额 ,
                SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩产成品本月认购面积 ,
                SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩产成品本月认购套数 ,
                
				SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩产成品本年认购金额 ,
                SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩产成品本年认购面积 ,
                SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩产成品本年认购套数 ,
                
				SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩产成品本年签约金额 ,
                SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩产成品本年签约面积 ,
                SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩产成品本年签约套数 ,
                
				SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩产成品本月签约金额 ,
                SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩产成品本月签约面积,
				SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩产成品本月签约套数,

                -- 准产成品 本年竣备以及本年预计竣备 PlanFinishDate
				SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩准产成品本日认购金额 ,
			    SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩准产成品本日认购面积 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩准产成品本日认购套数 ,

                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩准产成品本周认购金额 ,
       		    SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN r.CjBldArea ELSE 0 END) AS 其他业绩准产成品本周认购面积 ,         
				SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN 1 ELSE 0 END) AS 其他业绩准产成品本周认购套数 ,

                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩准产成品本月认购金额 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩准产成品本月认购面积 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩准产成品本月认购套数 ,
                
				SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩准产成品本年认购金额 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩准产成品本年认购面积 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩准产成品本年认购套数 ,
                
				SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩准产成品本年签约金额 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩准产成品本年签约面积 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩准产成品本年签约套数 ,
                
				SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩准产成品本月签约金额 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩准产成品本月签约面积,
				SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩准产成品本月签约套数,

                -- 大户型
				SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩大户型本日认购金额 ,
			    SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩大户型本日认购面积 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩大户型本日认购套数 ,

                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩大户型本周认购金额 ,
       		    SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN r.CjBldArea ELSE 0 END) AS 其他业绩大户型本周认购面积 ,         
				SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN 1 ELSE 0 END) AS 其他业绩大户型本周认购套数 ,

                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩大户型本月认购金额 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩大户型本月认购面积 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩大户型本月认购套数 ,
                
				SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩大户型本年认购金额 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩大户型本年认购面积 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩大户型本年认购套数 ,
                
				SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩大户型本年签约金额 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩大户型本年签约面积 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩大户型本年签约套数 ,
                
				SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩大户型本月签约金额 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩大户型本月签约面积,
				SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' AND   r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩大户型本月签约套数,

                -- 联动房
				SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩联动房本日认购金额 ,
			    SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩联动房本日认购面积 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩联动房本日认购套数 ,

                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩联动房本周认购金额 ,
       		    SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN r.CjBldArea ELSE 0 END) AS 其他业绩联动房本周认购面积 ,         
				SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN 1 ELSE 0 END) AS 其他业绩联动房本周认购套数 ,

                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩联动房本月认购金额 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩联动房本月认购面积 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩联动房本月认购套数 ,
                
				SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩联动房本年认购金额 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩联动房本年认购面积 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩联动房本年认购套数 ,
                
				SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩联动房本年签约金额 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjBldArea ELSE 0 END) AS 其他业绩联动房本年签约面积 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 其他业绩联动房本年签约套数 ,
                
				SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 其他业绩联动房本月签约金额 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN r.CjBldArea ELSE 0 END) AS 其他业绩联动房本月签约面积,
				SUM(CASE WHEN ldf.RoomGUID IS NOT NULL AND   r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 其他业绩联动房本月签约套数
        INTO    #qtqy
        FROM    data_wide_s_SpecialPerformance a
        INNER JOIN data_wide_s_RoomoVerride r ON a.RoomGUID = r.RoomGUID
        INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = r.BldGUID
        INNER JOIN data_wide_dws_mdm_Project p ON a.ParentProjGUID = p.ProjGUID AND p.Level = 2
        INNER JOIN #qtyj qt ON qt.明源系统代码 = p.ProjCode
        LEFT JOIN data_tb_hnyx_areasection mjd ON r.BldArea between mjd.开始面积 and mjd.截止面积 and mjd.业态 = bld.TopProductTypeName
        LEFT JOIN data_wide_s_LdfSaleDtl ldf on ldf.RoomGUID =r.RoomGUID
        WHERE   DATEDIFF(DAY, a.[StatisticalDate], qt.认定日期) = 0 AND r.Status IN ('认购', '签约')    -- AND YEAR(r.QsDate) = YEAR(@var_date)
        GROUP BY p.projguid ,
                 bld.TopProductTypeName;

        --获取各产品业态的签约金额
        SELECT  Sale.ParentProjGUID AS orgguid ,
                Sale.TopProductTypeName ,
                --获取本日签约情况
                SUM(CASE WHEN DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)ELSE 0 END) / 10000 AS 本日签约金额全口径 ,
				SUM(CASE WHEN DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)ELSE 0 END) AS 本日签约面积全口径,
                SUM(CASE WHEN DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)ELSE 0 END) 本日签约套数全口径 ,
                SUM(CASE WHEN DATEDIFF(DAY,pb.FactFinishDate,@var_date) > 0  AND  DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0    THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                         ELSE 0
                    END) / 10000 本日产成品签约金额全口径 ,
                SUM(CASE WHEN  DATEDIFF(DAY,pb.FactFinishDate,@var_date) > 0  AND  DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0 
				THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)ELSE 0 END) 本日产成品签约面积全口径 ,
                SUM(CASE WHEN  DATEDIFF(DAY,pb.FactFinishDate,@var_date) > 0  AND  DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0 
				THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)ELSE 0 END) 本日产成品签约套数全口径 ,

                SUM(CASE WHEN ((DATEDIFF(YEAR,pb.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,pb.PlanFinishDate,@var_date) = 0 and pb.factfinishdate is null)))  AND  DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0    THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                         ELSE 0
                    END) / 10000 本日准产成品签约金额全口径 ,
                SUM(CASE WHEN ((DATEDIFF(YEAR,pb.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,pb.PlanFinishDate,@var_date) = 0 and pb.factfinishdate is null)))  AND  DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0 
				THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)ELSE 0 END) 本日准产成品签约面积全口径 ,
                SUM(CASE WHEN ((DATEDIFF(YEAR,pb.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,pb.PlanFinishDate,@var_date) = 0 and pb.factfinishdate is null)))  AND  DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0 
				THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)ELSE 0 END) 本日准产成品签约套数全口径 ,

				--获取本周签约情况
                SUM(CASE WHEN (Sale.StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(Sale.StatisticalDate) = MONTH(@var_date)  THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)ELSE 0 END) / 10000 AS 本周签约金额全口径 ,
				SUM(CASE WHEN (Sale.StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(Sale.StatisticalDate) = MONTH(@var_date)  THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)ELSE 0 END) AS 本周签约面积全口径,
                SUM(CASE WHEN (Sale.StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(Sale.StatisticalDate) = MONTH(@var_date)  THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)ELSE 0 END) AS 本周签约套数全口径 ,
                --获取本年签约情况
                SUM(ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)) / 10000 AS 本年签约金额全口径 ,
                SUM(ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)) AS 本年签约面积全口径 ,
                SUM(ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)) AS 本年签约套数全口径 ,
                SUM(CASE WHEN  DATEDIFF(DAY,pb.FactFinishDate,@var_date) > 0  THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                         ELSE 0
                    END) / 10000 本年产成品签约金额全口径 ,
			    SUM(CASE WHEN DATEDIFF(DAY,pb.FactFinishDate,@var_date) > 0   THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0) ELSE  0 END  ) 本年产成品签约面积全口径 ,
                SUM(CASE WHEN DATEDIFF(DAY,pb.FactFinishDate,@var_date) > 0   THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0) ELSE  0 END  ) 本年产成品签约套数全口径 ,
                
                SUM(CASE WHEN  (DATEDIFF(YEAR,pb.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,pb.PlanFinishDate,@var_date) = 0 AND pb.FactFinishDate IS NULL))  THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                         ELSE 0
                    END) / 10000 本年准产成品签约金额全口径 ,
			    SUM(CASE WHEN (DATEDIFF(YEAR,pb.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,pb.PlanFinishDate,@var_date) = 0 AND pb.FactFinishDate IS NULL))   THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0) ELSE  0 END  ) 本年准产成品签约面积全口径 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,pb.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,pb.PlanFinishDate,@var_date) = 0 AND pb.FactFinishDate IS NULL))   THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0) ELSE  0 END  ) 本年准产成品签约套数全口径 ,
                --获取本月签约情况
                SUM(CASE WHEN DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)ELSE 0 END) / 10000.0 AS 本月签约金额全口径 ,
                SUM(CASE WHEN DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)ELSE 0 END) AS 本月签约面积全口径 ,
                SUM(CASE WHEN DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)ELSE 0 END) AS 本月签约套数全口径 ,
                SUM( CASE WHEN DATEDIFF(DAY,pb.FactFinishDate,@var_date) > 0  AND (DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0)  THEN
                         ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                     ELSE 0
                END) / 10000 本月产成品签约金额全口径,
				SUM(CASE WHEN  DATEDIFF(DAY,pb.FactFinishDate,@var_date) > 0  AND DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0  
				    THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)ELSE 0 END) AS 本月产成品签约面积全口径,
				SUM(CASE WHEN  DATEDIFF(DAY,pb.FactFinishDate,@var_date) > 0  AND DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0  
				    THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)ELSE 0 END) AS 本月产成品签约套数全口径,
                SUM( CASE WHEN ((DATEDIFF(YEAR,pb.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,pb.PlanFinishDate,@var_date) = 0 and pb.factfinishdate is null)))  AND (DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0)  THEN
                         ISNULL(Sale.CNetAmount, 0) + ISNULL(Sale.SpecialCNetAmount, 0)
                     ELSE 0
                END) / 10000 本月准产成品签约金额全口径,
				SUM(CASE WHEN  ((DATEDIFF(YEAR,pb.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,pb.PlanFinishDate,@var_date) = 0 and pb.factfinishdate is null)))  AND DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0  
				    THEN ISNULL(Sale.CNetArea, 0) + ISNULL(Sale.SpecialCNetArea, 0)ELSE 0 END) AS 本月准产成品签约面积全口径,
				SUM(CASE WHEN  ((DATEDIFF(YEAR,pb.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,pb.PlanFinishDate,@var_date) = 0 and pb.factfinishdate is null)))  AND DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0  
				    THEN ISNULL(Sale.CNetCount, 0) + ISNULL(Sale.SpecialCNetCount, 0)ELSE 0 END) AS 本月准产成品签约套数全口径 
        INTO    #projsale
        FROM    dbo.data_wide_dws_s_SalesPerf Sale
        INNER JOIN data_wide_dws_mdm_Project pj ON pj.ProjGUID = Sale.ParentProjGUID
        LEFT JOIN data_wide_dws_s_Dimension_Organization do ON do.OrgGUID = pj.XMSSCSGSGUID AND do.ParentOrganizationGUID = pj.BUGUID
        LEFT JOIN data_wide_dws_s_Dimension_Organization do1 ON do1.OrgGUID = do.ParentOrganizationGUID
        LEFT JOIN data_wide_dws_mdm_Building pb ON Sale.GCBldGUID = pb.BuildingGUID AND pb.BldType = '工程楼栋'
        WHERE   Sale.StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(@var_date)) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(@var_date)) + '-12-31'
        GROUP BY Sale.ParentProjGUID ,
                 Sale.TopProductTypeName;

        -- --获取各产品业态的签约金额【补充大户型和联动房的签约数据】
        SELECT  Sale.ParentProjGUID AS orgguid ,
                Sale.TopProductTypeName ,
                --获取大户型本日签约情况
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是'  and DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetAmount, 0) ELSE 0 END) / 10000 AS 本日大户型签约金额全口径 ,
				SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是'  and DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetArea, 0) ELSE 0 END) AS 本日大户型签约面积全口径,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是'  and DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetCount, 0) ELSE 0 END) 本日大户型签约套数全口径 ,
				
				--获取大户型本周签约情况
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是'  and (Sale.StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(Sale.StatisticalDate) = MONTH(@var_date)  THEN ISNULL(Sale.CNetAmount, 0) ELSE 0 END) / 10000 AS 本周大户型签约金额全口径 ,
				SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是'  and (Sale.StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(Sale.StatisticalDate) = MONTH(@var_date)  THEN ISNULL(Sale.CNetArea, 0) ELSE 0 END) AS 本周大户型签约面积全口径,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是'  and (Sale.StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(Sale.StatisticalDate) = MONTH(@var_date)  THEN ISNULL(Sale.CNetCount, 0) ELSE 0 END) AS 本周大户型签约套数全口径 ,
                
				--获取大户型本月签约情况
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是'  and DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetAmount, 0) ELSE 0 END) / 10000.0 AS 本月大户型签约金额全口径 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是'  and DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetArea, 0) ELSE 0 END) AS 本月大户型签约面积全口径 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是'  and DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetCount, 0) ELSE 0 END) AS 本月大户型签约套数全口径 ,

				--获取大户型本年签约情况
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是'  and DATEDIFF(yy, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetAmount, 0) ELSE 0 END) / 10000 AS 本年大户型签约金额全口径 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是'  and DATEDIFF(yy, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetArea, 0) ELSE 0 END) AS 本年大户型签约面积全口径 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是'  and DATEDIFF(yy, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetCount, 0) ELSE 0 END) AS 本年大户型签约套数全口径,
                
				--获取联动房本日签约情况
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetAmount, 0) ELSE 0 END) / 10000 AS 本日联动房签约金额全口径 ,
				SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetArea, 0) ELSE 0 END) AS 本日联动房签约面积全口径,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and DATEDIFF(DAY, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetCount, 0) ELSE 0 END) 本日联动房签约套数全口径 ,
				
				--获取联动房本周签约情况
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and (Sale.StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(Sale.StatisticalDate) = MONTH(@var_date)  THEN ISNULL(Sale.CNetAmount, 0) ELSE 0 END) / 10000 AS 本周联动房签约金额全口径 ,
				SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and (Sale.StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(Sale.StatisticalDate) = MONTH(@var_date)  THEN ISNULL(Sale.CNetArea, 0) ELSE 0 END) AS 本周联动房签约面积全口径,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and (Sale.StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(Sale.StatisticalDate) = MONTH(@var_date)  THEN ISNULL(Sale.CNetCount, 0) ELSE 0 END) AS 本周联动房签约套数全口径 ,
                
				--获取联动房本月签约情况
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetAmount, 0) ELSE 0 END) / 10000.0 AS 本月联动房签约金额全口径 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetArea, 0) ELSE 0 END) AS 本月联动房签约面积全口径 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and DATEDIFF(mm, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetCount, 0) ELSE 0 END) AS 本月联动房签约套数全口径 ,

				--获取联动房本年签约情况
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and DATEDIFF(yy, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetAmount, 0) ELSE 0 END) / 10000 AS 本年联动房签约金额全口径 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and DATEDIFF(yy, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetArea, 0) ELSE 0 END) AS 本年联动房签约面积全口径 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and DATEDIFF(yy, @var_date, Sale.StatisticalDate) = 0 THEN ISNULL(Sale.CNetCount, 0) ELSE 0 END) AS 本年联动房签约套数全口径
            INTO #projsale_ldf_dhx
			from (
                SELECT  p.ParentGUID as ParentProjGUID,
                    sb.TopProductTypeName,
                    r.RoomGUID,
                    CONVERT(NVARCHAR(10), isnull(r.TsRoomQSDate, shd.QsDate), 23) AS StatisticalDate,											--统计日期
                    SUM(CASE WHEN ((p.DiskFlag = '是' and r.specialFlag = '否') or ISNULL(sp.YJMode,sp1.YJMode)=1) AND shd.TradeType = '签约' THEN isnull(shd.BldArea,0) ELSE 0 END) as CNetArea, --签约面积
                    SUM(CASE WHEN ((p.DiskFlag = '是' and r.specialFlag = '否') or ISNULL(sp.YJMode,sp1.YJMode)=1) AND shd.TradeType = '签约' THEN isnull(shd.jyTotal,0) ELSE 0 END) as CNetAmount, --签约金额
                    SUM(CASE WHEN ((p.DiskFlag = '是' and r.specialFlag = '否') or ISNULL(sp.YJMode,sp1.YJMode)=1)  AND shd.TradeType = '签约' THEN isnull(shd.Ts,0) ELSE 0 END) as CNetCount 	--签约套数

                FROM    data_wide_s_SaleHsData shd with(nolock)
                inner join data_wide_s_RoomoVerride r with(nolock)  on r.RoomGUID = shd.RoomGUID
                inner join data_wide_dws_mdm_Project p with(nolock) on p.ProjGUID = shd.ProjGUID	
                inner join data_wide_dws_mdm_Building sb with(nolock) on sb.BuildingGUID = shd.BldGUID
                LEFT JOIN (SELECT roomguid,YJMode FROM dbo.data_wide_s_SpecialPerformance where YJMode=1 GROUP BY  roomguid,YJMode) sp ON sp.RoomGUID = r.RoomGUID
                LEFT JOIN (SELECT BldGUID,YJMode FROM dbo.data_wide_s_SpecialPerformance where YJMode=1 AND RoomGUID IS null GROUP BY  BldGUID,YJMode) sp1 ON sp1.BldGUID = r.BldGUID
                where shd.QsDate is not null 
                    and shd.buguid ='70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
                    and isnull(r.TsRoomQSDate, shd.QsDate) BETWEEN CONVERT(VARCHAR(4), YEAR(@var_date)) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(@var_date)) + '-12-31'
                GROUP BY  p.ParentGUID,sb.TopProductTypeName,r.RoomGUID,CONVERT(NVARCHAR(10), isnull(r.TsRoomQSDate, shd.QsDate), 23)
                UNION ALL 
                select p.ParentGUID as ParentProjGUID,
                        pb.TopProductTypeName,
                        a.RoomGUID,
                        CONVERT(NVARCHAR(10), a.StatisticalDate, 23) as StatisticalDate,
                        sum(case when a.YJMode<>1 then a.CCjArea else 0 end) as CCjArea,
                        sum(a.CCjAmount) as CCjAmount,
                        1 as SpecialType --房间维度取数                            
                from data_wide_s_SpecialPerformance a  with(nolock) 
                inner join data_wide_s_RoomoVerride r with(nolock)  on r.RoomGUID = a.RoomGUID
                inner join data_wide_dws_mdm_Project p with(nolock) on p.ProjGUID = r.ProjGUID	
                inner join data_wide_dws_mdm_Building pb on a.BldGUID = pb.BuildingGUID
                where isnull(a.TsyjType,'') NOT IN (SELECT TsyjTypeName FROM data_wide_s_TsyjType WHERE IsRelatedBuildingsRoom =0) and a.RoomGUID is not null and a.StatisticalDate is not null
                    and a.StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(@var_date)) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(@var_date)) + '-12-31'
                    and a.buguid ='70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
                group by p.ParentGUID,
                        pb.TopProductTypeName,
                        a.RoomGUID,
                        CONVERT(NVARCHAR(10), a.StatisticalDate, 23)
        ) sale
        INNER JOIN data_wide_s_RoomoVerride r  on r.RoomGUID = sale.RoomGUID
		INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = r.BldGUID
        LEFT JOIN data_tb_hnyx_areasection mjd ON r.BldArea between mjd.开始面积 and mjd.截止面积 and mjd.业态 = sale.TopProductTypeName
        LEFT JOIN data_wide_s_LdfSaleDtl ldf on ldf.RoomGUID = r.RoomGUID
		GROUP BY Sale.ParentProjGUID ,
                Sale.TopProductTypeName


        --获取各产品业态新货签约金额认购金额以及已认购未签约金额
        SELECT  pj.ProjGUID ,
                bld.TopProductTypeName ,
				-- 产成品 
				SUM(CASE WHEN r.specialFlag = '否' AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0 AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本日产成品认购金额 ,
 				SUM(CASE WHEN r.specialFlag = '否' AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0 AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END)  AS 本日产成品认购面积 ,               
				SUM(CASE WHEN r.specialFlag = '否' AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本日产成品认购套数 ,
                SUM(
                CASE WHEN r.specialFlag = '否'  AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0 AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN
                         r.CjRmbTotal + ISNULL(specialYj, 0)
                     ELSE 0
                END) / 10000.0 AS 本周产成品认购金额 ,
				SUM(CASE WHEN r.specialFlag = '否' AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本周产成品认购面积,
                SUM(CASE WHEN r.specialFlag = '否' AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本周产成品认购套数 ,

                SUM(CASE WHEN r.specialFlag = '否' AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本年产成品认购金额 ,
                SUM(CASE WHEN r.specialFlag = '否' AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本年产成品认购面积,
				SUM(CASE WHEN r.specialFlag = '否' AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本年产成品认购套数 ,

                SUM(CASE WHEN r.specialFlag = '否' AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本月产成品认购金额 ,
                SUM(CASE WHEN r.specialFlag = '否' AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本月产成品认购面积 ,
			    SUM(CASE WHEN r.specialFlag = '否' AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本月产成品认购套数 ,

                SUM(CASE WHEN r.specialFlag = '否' AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND   r.Status = '认购' AND r.specialFlag = '否' THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 累计产成品已认购未签约金额 ,
		        SUM(CASE WHEN r.specialFlag = '否' AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0 AND   r.Status = '认购' AND r.specialFlag = '否' THEN r.CjBldArea ELSE 0 END) AS 累计产成品已认购未签约面积,
                SUM(CASE WHEN r.specialFlag = '否' AND  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0 AND   r.Status = '认购' AND r.specialFlag = '否' THEN 1 ELSE 0 END) AS 累计产成品已认购未签约套数,

                -- 准产成品 
				SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本日准产成品认购金额 ,
 				SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END)  AS 本日准产成品认购面积 ,               
				SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本日准产成品认购套数 ,
                SUM(
                CASE WHEN r.specialFlag = '否'  AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN
                         r.CjRmbTotal + ISNULL(specialYj, 0)
                     ELSE 0
                END) / 10000.0 AS 本周准产成品认购金额 ,
				SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本周准产成品认购面积,
                SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本周准产成品认购套数 ,

                SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本年准产成品认购金额 ,
                SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本年准产成品认购面积,
				SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本年准产成品认购套数 ,

                SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本月准产成品认购金额 ,
                SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本月准产成品认购面积 ,
			    SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本月准产成品认购套数 ,

                SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND   r.Status = '认购' AND r.specialFlag = '否' THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 累计准产成品已认购未签约金额 ,
		        SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   r.Status = '认购' AND r.specialFlag = '否' THEN r.CjBldArea ELSE 0 END) AS 累计准产成品已认购未签约面积,
                SUM(CASE WHEN r.specialFlag = '否' AND  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   r.Status = '认购' AND r.specialFlag = '否' THEN 1 ELSE 0 END) AS 累计准产成品已认购未签约套数,
                
                SUM(CASE WHEN DATEDIFF(yy, r.FangPanTime, @var_date) = 0 AND r.Status = '签约' AND DATEDIFF(yy, r.QsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.00 AS 本年新货签约金额 ,
                SUM(CASE WHEN DATEDIFF(yy, r.FangPanTime, @var_date) > 0 AND r.Status = '签约' AND DATEDIFF(yy, r.QsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.00 AS 本年存货签约金额 ,
                SUM(CASE WHEN DATEDIFF(mm, r.FangPanTime, @var_date) = 0 AND r.Status = '签约' AND (DATEDIFF(mm, r.QsDate, @var_date) = 0) THEN r.CjRmbTotal ELSE 0 END) / 10000.00 AS 本月新货签约金额 ,
                SUM(CASE WHEN DATEDIFF(mm, r.FangPanTime, @var_date) > 0 AND r.Status = '签约' AND (DATEDIFF(mm, r.QsDate, @var_date) = 0) THEN r.CjRmbTotal ELSE 0 END) / 10000.00 AS 本月存货签约金额 ,

                SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本日认购金额 ,
                SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本日认购面积 ,
                SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本日认购套数 ,

                SUM(
                CASE WHEN r.specialFlag = '否' AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN
                         r.CjRmbTotal + ISNULL(specialYj, 0)
                     ELSE 0
                END) / 10000.0 AS 本周认购金额 ,
                SUM(CASE WHEN r.specialFlag = '否' AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN  r.CjBldArea ELSE 0 END) AS 本周认购面积 ,
				SUM(CASE WHEN r.specialFlag = '否' AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本周认购套数 ,

                SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本年认购金额 ,
				SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本年认购面积 ,
                SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本年认购套数 ,

                SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本月认购金额 ,
			    SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本月认购面积 ,
                SUM(CASE WHEN r.specialFlag = '否' AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本月认购套数 ,

                SUM(CASE WHEN r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 累计已认购未签约金额 ,
                SUM(CASE WHEN r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN r.CjBldArea ELSE 0 END) AS 累计已认购未签约面积 ,
                SUM(CASE WHEN r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN 1 ELSE 0 END) AS 累计已认购未签约套数 ,
                SUM(CASE WHEN r.specialFlag = '否' AND   r.Status = '认购' AND DATEDIFF(yy, @var_date, r.RgQsDate) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 本年已认购未签约金额 ,
                SUM(CASE WHEN r.specialFlag = '否' AND   r.Status = '认购' AND DATEDIFF(yy, @var_date, r.RgQsDate) = 0 THEN 1 ELSE 0 END) AS 本年已认购未签约套数 ,
                SUM(CASE WHEN r.specialFlag = '否' AND   r.Status = '认购' AND DATEDIFF(mm, @var_date, r.RgQsDate) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 本月已认购未签约金额 ,
                SUM(CASE WHEN r.specialFlag = '否' AND   r.Status = '认购' AND DATEDIFF(mm, @var_date, r.RgQsDate) = 0 THEN 1 ELSE 0 END) AS 本月已认购未签约套数,
                
                --大户型
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本日大户型认购金额 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本日大户型认购面积 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本日大户型认购套数 ,

                SUM(
                CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN
                         r.CjRmbTotal + ISNULL(specialYj, 0)
                     ELSE 0
                END) / 10000.0 AS 本周大户型认购金额 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN  r.CjBldArea ELSE 0 END) AS 本周大户型认购面积 ,
				SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本周大户型认购套数 ,

                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本年大户型认购金额 ,
				SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本年大户型认购面积 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本年大户型认购套数 ,

                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本月大户型认购金额 ,
			    SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本月大户型认购面积 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本月大户型认购套数 ,

                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 累计大户型已认购未签约金额 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN r.CjBldArea ELSE 0 END) AS 累计大户型已认购未签约面积 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN 1 ELSE 0 END) AS 累计大户型已认购未签约套数 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   r.Status = '认购' AND DATEDIFF(yy, @var_date, r.RgQsDate) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 本年大户型已认购未签约金额 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   r.Status = '认购' AND DATEDIFF(yy, @var_date, r.RgQsDate) = 0 THEN 1 ELSE 0 END) AS 本年大户型已认购未签约套数 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   r.Status = '认购' AND DATEDIFF(mm, @var_date, r.RgQsDate) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 本月大户型已认购未签约金额 ,
                SUM(CASE WHEN bld.TopProductTypeName IN ('高级住宅', '住宅', '别墅') and mjd.是否大户型 ='是' and r.specialFlag = '否' AND   r.Status = '认购' AND DATEDIFF(mm, @var_date, r.RgQsDate) = 0 THEN 1 ELSE 0 END) AS 本月大户型已认购未签约套数,
                
                --联动房
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本日联动房认购金额 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本日联动房认购面积 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   DATEDIFF(DAY, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本日联动房认购套数 ,

                SUM(
                CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN
                         r.CjRmbTotal + ISNULL(specialYj, 0)
                     ELSE 0
                END) / 10000.0 AS 本周联动房认购金额 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN  r.CjBldArea ELSE 0 END) AS 本周联动房认购面积 ,
				SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND  MONTH(r.RgQsDate) = MONTH(@var_date) AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本周联动房认购套数 ,

                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本年联动房认购金额 ,
				SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本年联动房认购面积 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   DATEDIFF(yy, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本年联动房认购套数 ,

                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjRmbTotal + ISNULL(specialYj, 0)ELSE 0 END) / 10000.0 AS 本月联动房认购金额 ,
			    SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN r.CjBldArea ELSE 0 END) AS 本月联动房认购面积 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   DATEDIFF(mm, @var_date, r.RgQsDate) = 0 AND r.Status IN ('签约', '认购') THEN 1 ELSE 0 END) AS 本月联动房认购套数 ,

                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 累计联动房已认购未签约金额 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN r.CjBldArea ELSE 0 END) AS 累计联动房已认购未签约面积 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN 1 ELSE 0 END) AS 累计联动房已认购未签约套数 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   r.Status = '认购' AND DATEDIFF(yy, @var_date, r.RgQsDate) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 本年联动房已认购未签约金额 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   r.Status = '认购' AND DATEDIFF(yy, @var_date, r.RgQsDate) = 0 THEN 1 ELSE 0 END) AS 本年联动房已认购未签约套数 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   r.Status = '认购' AND DATEDIFF(mm, @var_date, r.RgQsDate) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 本月联动房已认购未签约金额 ,
                SUM(CASE WHEN ldf.RoomGUID IS NOT NULL and r.specialFlag = '否' AND   r.Status = '认购' AND DATEDIFF(mm, @var_date, r.RgQsDate) = 0 THEN 1 ELSE 0 END) AS 本月联动房已认购未签约套数
        INTO    #rsale
        FROM    dbo.data_wide_s_RoomoVerride r
                INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = r.BldGUID
                INNER JOIN data_wide_dws_mdm_Project pj ON r.ParentProjGUID = pj.ProjGUID
                LEFT JOIN data_tb_hnyx_areasection mjd ON r.BldArea between mjd.开始面积 and mjd.截止面积 and mjd.业态 = bld.TopProductTypeName
                LEFT JOIN data_wide_s_LdfSaleDtl ldf on ldf.RoomGUID = r.RoomGUID
        WHERE   r.BUGUID = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
        GROUP BY pj.ProjGUID ,
                 bld.TopProductTypeName;

        --获取各产品业态的特殊业绩及合作项目的认购情况
        SELECT  pj.ProjGUID ,
                pt.TopProductTypeName ,
                SUM(ISNULL(hz.bnhzje, 0) + ISNULL(ts.bnhzje, 0)) AS 本年认购金额 ,
                SUM(ISNULL(hz.bnhzmj, 0) + ISNULL(ts.bnhzmj, 0)) AS 本年认购面积 ,
                SUM(ISNULL(hz.bnhzts, 0) + ISNULL(ts.bnhzts, 0)) AS 本年认购套数 ,

                SUM(ISNULL(hz.byhzje, 0) + ISNULL(ts.byhzje, 0)) AS 本月认购金额 ,
                SUM(ISNULL(hz.byhzmj, 0) + ISNULL(ts.byhzmj, 0)) AS 本月认购面积 ,          
				SUM(ISNULL(hz.byhzts, 0) + ISNULL(ts.byhzts, 0)) AS 本月认购套数 ,
                
				SUM(ISNULL(hz.bzhzje, 0) + ISNULL(ts.bzhzje, 0)) AS 本周认购金额 ,
				SUM(ISNULL(hz.bzhzmj, 0) + ISNULL(ts.bzhzmj, 0)) AS 本周认购面积 ,
                SUM(ISNULL(hz.bzhzts, 0) + ISNULL(ts.bzhzts, 0)) AS 本周认购套数 ,
                
				SUM(ISNULL(hz.brhzje, 0) + ISNULL(ts.brhzje, 0)) AS 本日认购金额 ,
				SUM(ISNULL(hz.brhzmj, 0) + ISNULL(ts.brhzmj, 0)) AS 本日认购面积 ,
                SUM(ISNULL(hz.brhzts, 0) + ISNULL(ts.brhzts, 0)) AS 本日认购套数,

                --产成品
				SUM(ISNULL(hz.bnccphzje, 0) + ISNULL(ts.bnccphzje, 0)) AS 本年产成品认购金额 ,
				SUM(ISNULL(hz.bnccphzmj, 0) + ISNULL(ts.bnccphzmj, 0)) AS 本年产成品认购面积 ,
                SUM(ISNULL(hz.bnccphzts, 0) + ISNULL(ts.bnccphzts, 0)) AS 本年产成品认购套数 ,

                SUM(ISNULL(hz.byccphzje, 0) + ISNULL(ts.byccphzje, 0)) AS 本月产成品认购金额 ,
                SUM(ISNULL(hz.byccphzmj, 0) + ISNULL(ts.byccphzmj, 0)) AS 本月产成品认购面积 ,              
				SUM(ISNULL(hz.byccphzts, 0) + ISNULL(ts.byccphzts, 0)) AS 本月产成品认购套数 ,
                
				SUM(ISNULL(hz.bzccphzje, 0) + ISNULL(ts.bzccphzje, 0)) AS 本周产成品认购金额 ,
     		    SUM(ISNULL(hz.bzccphzmj, 0) + ISNULL(ts.bzccphzmj, 0)) AS 本周产成品认购面积 ,           
				SUM(ISNULL(hz.bzccphzts, 0) + ISNULL(ts.bzccphzts, 0)) AS 本周产成品认购套数 ,

                SUM(ISNULL(hz.brccphzje, 0) + ISNULL(ts.brccphzje, 0)) AS 本日产成品认购金额 ,
                SUM(ISNULL(hz.brccphzmj, 0) + ISNULL(ts.brccphzmj, 0)) AS 本日产成品认购面积 ,
                SUM(ISNULL(hz.brccphzts, 0) + ISNULL(ts.brccphzts, 0)) AS 本日产成品认购套数 ,

                --准产成品
				SUM(ISNULL(hz.zbnccphzje, 0) + ISNULL(ts.zbnccphzje, 0)) AS 本年准产成品认购金额 ,
				SUM(ISNULL(hz.zbnccphzmj, 0) + ISNULL(ts.zbnccphzmj, 0)) AS 本年准产成品认购面积 ,
                SUM(ISNULL(hz.zbnccphzts, 0) + ISNULL(ts.zbnccphzts, 0)) AS 本年准产成品认购套数 ,

                SUM(ISNULL(hz.zbyccphzje, 0) + ISNULL(ts.zbyccphzje, 0)) AS 本月准产成品认购金额 ,
                SUM(ISNULL(hz.zbyccphzmj, 0) + ISNULL(ts.zbyccphzmj, 0)) AS 本月准产成品认购面积 ,              
				SUM(ISNULL(hz.zbyccphzts, 0) + ISNULL(ts.zbyccphzts, 0)) AS 本月准产成品认购套数 ,
                
				SUM(ISNULL(hz.zbzccphzje, 0) + ISNULL(ts.zbzccphzje, 0)) AS 本周准产成品认购金额 ,
     		    SUM(ISNULL(hz.zbzccphzmj, 0) + ISNULL(ts.zbzccphzmj, 0)) AS 本周准产成品认购面积 ,           
				SUM(ISNULL(hz.zbzccphzts, 0) + ISNULL(ts.zbzccphzts, 0)) AS 本周准产成品认购套数 ,

                SUM(ISNULL(hz.zbrccphzje, 0) + ISNULL(ts.zbrccphzje, 0)) AS 本日准产成品认购金额 ,
                SUM(ISNULL(hz.zbrccphzmj, 0) + ISNULL(ts.zbrccphzmj, 0)) AS 本日准产成品认购面积 ,
                SUM(ISNULL(hz.zbrccphzts, 0) + ISNULL(ts.zbrccphzts, 0)) AS 本日准产成品认购套数     
        INTO    #rg
        FROM    dbo.data_wide_dws_mdm_Project pj
        INNER JOIN #TopProduct pt ON pt.ParentProjGUID = pj.ProjGUID
        LEFT JOIN(SELECT    a.ProjGUID ,
                            ProductType AS TopProductTypeName ,
                            -- 产成品
                            SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  THEN   CCjTotal ELSE  0  END  ) AS bnccphzje ,                                                                                                                           --产成品本年认购金额
                            SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  THEN   CCjArea ELSE  0  END  ) AS  bnccphzmj ,
                            SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  THEN   CCjCount ELSE  0 END  ) AS  bnccphzts ,                                                                                                                           --产成品本年认购套数
                            SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND  MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjTotal ELSE 0 END) AS byccphzje ,                                                       --产成品本月认购金额
                            SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND  MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjArea ELSE 0 END) AS byccphzmj ,                                                        --产成品本月认购面积      
                            SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND  MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjCount ELSE 0 END) AS byccphzts ,                                                       --产成品本月认购套数
                            
                            SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0 AND  (StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjTotal ELSE 0 END) AS bzccphzje , --产成品本周认购金额
                            SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0 AND  (StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjArea ELSE 0 END) AS bzccphzmj , --产成品本周认购面积
                            SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0 AND  (StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjCount ELSE 0 END) AS bzccphzts , --产成品本周认购套数

                            SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0 AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjTotal ELSE 0 END) AS brccphzje ,                                                   --产成品本日认购金额
                            SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0 AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS brccphzmj ,                                                    --产成品本日认购面积 
                            SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0 AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS brccphzts ,     

                            -- 准产成品
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) THEN   CCjTotal ELSE  0  END  )AS zbnccphzje ,                                                                                                                           --产成品本年认购金额
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) THEN   CCjArea ELSE  0  END  ) AS zbnccphzmj ,
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) THEN   CCjCount ELSE  0 END  ) AS zbnccphzts ,                                                                                                                           --产成品本年认购套数
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjTotal ELSE 0 END) AS zbyccphzje ,                                                       --产成品本月认购金额
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjArea ELSE 0 END) AS  zbyccphzmj ,                                                        --产成品本月认购面积      
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjCount ELSE 0 END) AS zbyccphzts ,                                                       --产成品本月认购套数
                            
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  (StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjTotal ELSE 0 END) AS zbzccphzje , --产成品本周认购金额
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  (StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjArea ELSE 0 END) AS  zbzccphzmj , --产成品本周认购面积
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  (StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjCount ELSE 0 END) AS zbzccphzts , --产成品本周认购套数

                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjTotal ELSE 0 END) AS zbrccphzje ,                                                   --产成品本日认购金额
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS  zbrccphzmj ,                                                    --产成品本日认购面积 
                            SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS zbrccphzts ,  

                            SUM(CCjTotal) AS bnhzje ,                                                                                                                           -- 本年认购金额
                            SUM(CCjArea)  AS bnhzmj,                                                                                                                            -- 本年认购面积
                            SUM(CCjCount) AS bnhzts ,                                                                                                                           -- 本年认购套数

                            SUM(CASE WHEN MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjTotal ELSE 0 END) AS byhzje ,                                                       --本月认购金额
                            SUM(CASE WHEN MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjArea ELSE 0 END) AS byhzmj ,                                                        --本月认购面积
                            SUM(CASE WHEN MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjCount ELSE 0 END) AS byhzts ,                                                       --本月认购套数

                            SUM(CASE WHEN (StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjTotal ELSE 0 END) AS bzhzje , --本周认购金额
                            SUM(CASE WHEN (StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjArea ELSE 0 END) AS bzhzmj,   --本周认购面积 
                            SUM(CASE WHEN (StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(StatisticalDate) = MONTH(@var_date) THEN CCjCount ELSE 0 END) AS bzhzts , --本周认购套数
                            SUM(CASE WHEN DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjTotal ELSE 0 END) AS brhzje ,                                                   --本日认购金额
                            SUM(CASE WHEN DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjArea ELSE 0 END) AS brhzmj ,                                                    --本日认购面积
                            SUM(CASE WHEN DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN CCjCount ELSE 0 END) AS brhzts                                                     --本日认购套数
                    FROM  dbo.data_wide_s_NoControl a
                    INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = a.BldGUID 
                    WHERE StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(@var_date)) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(@var_date)) + '-12-31'
                    GROUP BY a.ProjGUID ,
                            ProductType) hz ON hz.ProjGUID = pj.ProjGUID AND pt.TopProductTypeName = hz.TopProductTypeName
        LEFT JOIN(
                    --如果特殊业绩类型为“代销车位”则业绩金额要双算
                    SELECT s.ParentProjGUID AS projguid ,
                        bld.TopProductTypeName ,
                        --产成品
                        SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND  ( DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 
                            OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) ) THEN CCjAmount ELSE 0 END) AS bnccphzje ,    --产成品本年认购金额
                        SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND  ( DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 
                            OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) ) THEN CCjArea ELSE 0 END) AS bnccphzmj ,    --产成品本年认购面积
                        SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND  ( DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 
                            OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) )  THEN CCjCount ELSE 0 END) AS bnccphzts ,     --产成品本年认购套数
                        -- 本年认购套数
                        SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND  ( DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 
                            OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) ) THEN CCjAmount ELSE 0 END) AS byccphzje ,  -- 产成品本月认购金额
                        SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND  ( DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 
                            OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) ) THEN CCjArea ELSE 0 END) AS byccphzmj ,    -- 产成品本月认购面积 
                        SUM(CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND  ( DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 
                            OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) ) THEN CCjCount ELSE 0 END) AS byccphzts ,   --产成品本月认购套数
                        SUM(
                        CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0 AND  ((StatisticalDate BETWEEN @bzSDate AND @bzEDate) 
                                        AND MONTH(StatisticalDate) = MONTH(@var_date))
                                        OR   ((r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND MONTH(r.RgQsDate) = MONTH(@var_date)) THEN CCjAmount
                                ELSE 0
                        END) AS bzccphzje ,                                                                                                                                                                    --产成品本周认购金额
                        SUM(
                        CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND  ((StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND MONTH(StatisticalDate) = MONTH(@var_date))
                                    OR   ((r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND MONTH(r.RgQsDate) = MONTH(@var_date)) THEN CCjArea
                                ELSE 0
                        END) AS bzccphzmj ,                                                                                                                                                                    --产成品本周认购面积 
                        SUM(
                        CASE WHEN DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND  ((StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND MONTH(StatisticalDate) = MONTH(@var_date))
                                    OR   ((r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND MONTH(r.RgQsDate) = MONTH(@var_date)) THEN CCjCount
                                ELSE 0
                        END) AS bzccphzts ,                                                                                                                                                                    --产成品本周认购套数

                        SUM(CASE WHEN  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND ( DATEDIFF(DAY, StatisticalDate, @var_date) = 0 
                        OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) ) THEN CCjAmount ELSE 0 END) AS brccphzje ,     --产成品本日认购金额
                        SUM(CASE WHEN  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0  AND ( DATEDIFF(DAY, StatisticalDate, @var_date) = 0 
                        OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) ) THEN CCjArea ELSE 0 END) AS brccphzmj ,       --产成品本日认购面积
                        SUM(CASE WHEN  DATEDIFF(DAY,bld.FactFinishDate,@var_date) > 0 AND ( DATEDIFF(DAY, StatisticalDate, @var_date) = 0 
                        OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) )  THEN CCjCount ELSE 0 END) AS brccphzts ,      --产成品本日认购套数
                        
                        --准产成品
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL) )  AND  ( DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 
                        OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) ) THEN CCjAmount ELSE 0 END) AS zbnccphzje ,    --准产成品本年认购金额
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND  ( DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 
                        OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) ) THEN CCjArea ELSE 0 END) AS zbnccphzmj ,    --准产成品本年认购面积
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND  ( DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 
                        OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) )  THEN CCjCount ELSE 0 END) AS zbnccphzts ,     --准产成品本年认购套数
                        -- 本年认购套数
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND  ( DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 
                        OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) ) THEN CCjAmount ELSE 0 END) AS zbyccphzje ,  -- 准产成品本月认购金额
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND  ( DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 
                        OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) ) THEN CCjArea ELSE 0 END) AS zbyccphzmj ,    -- 准产成品本月认购面积 
                        SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND  ( DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 
                        OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) ) THEN CCjCount ELSE 0 END) AS zbyccphzts ,   --准产成品本月认购套数
                        SUM(
                        CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  ((StatisticalDate BETWEEN @bzSDate AND @bzEDate) 
                                        AND MONTH(StatisticalDate) = MONTH(@var_date))
                                        OR   ((r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND MONTH(r.RgQsDate) = MONTH(@var_date)) THEN CCjAmount
                                ELSE 0
                        END) AS zbzccphzje ,                                                                                                                                                                    --准产成品本周认购金额
                        SUM(
                        CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND  ((StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND MONTH(StatisticalDate) = MONTH(@var_date))
                                    OR   ((r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND MONTH(r.RgQsDate) = MONTH(@var_date)) THEN CCjArea
                                ELSE 0
                        END) AS zbzccphzmj ,                                                                                                                                                                    --准产成品本周认购面积 
                        SUM(
                        CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND  ((StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND MONTH(StatisticalDate) = MONTH(@var_date))
                                    OR   ((r.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND MONTH(r.RgQsDate) = MONTH(@var_date)) THEN CCjCount
                                ELSE 0
                        END) AS zbzccphzts ,                                                                                                                                                                    --准产成品本周认购套数

                        SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND ( DATEDIFF(DAY, StatisticalDate, @var_date) = 0 
                        OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) ) THEN CCjAmount ELSE 0 END) AS zbrccphzje ,     --准产成品本日认购金额
                        SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL))  AND ( DATEDIFF(DAY, StatisticalDate, @var_date) = 0 
                        OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) ) THEN CCjArea ELSE 0 END) AS zbrccphzmj ,       --准产成品本日认购面积
                        SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND ( DATEDIFF(DAY, StatisticalDate, @var_date) = 0 
                        OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) )  THEN CCjCount ELSE 0 END) AS zbrccphzts ,      --准产成品本日认购套数

                        SUM(CASE WHEN DATEDIFF(YEAR, StatisticalDate, @var_date) = 0  THEN CCjAmount
                                    WHEN  (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) 
                                    THEN r.CjRmbTotal /10000.0 ELSE 0 END) AS bnhzje,    --本年认购金额
                        SUM(CASE WHEN DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 
                            OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) THEN CCjArea ELSE 0 END) AS bnhzmj ,  --本年认购面积
                        SUM(CASE WHEN DATEDIFF(YEAR, StatisticalDate, @var_date) = 0 
                            OR (s.TsyjType = '物业公司车位代销' AND   DATEDIFF(YEAR, StatisticalDate, @var_date) = 0) THEN CCjCount ELSE 0 END) AS bnhzts ,     --本年认购套数                                                                                                                          -- 本年认购套数
                        
                        SUM(CASE WHEN DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 THEN CCjAmount
                                    WHEN  (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH,StatisticalDate, @var_date) = 0) THEN r.CjRmbTotal /10000.0 ELSE 0 END) AS byhzje ,  -- 本月认购金额
                        SUM(CASE WHEN DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 
                            OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) THEN CCjArea ELSE 0 END) AS byhzmj ,  --本月认购面积
                        SUM(CASE WHEN DATEDIFF(MONTH, StatisticalDate, @var_date) = 0 
                            OR   (s.TsyjType = '物业公司车位代销' AND DATEDIFF(MONTH, StatisticalDate, @var_date) = 0) THEN CCjCount ELSE 0 END) AS byhzts ,   --本月认购套数

                        SUM(
                        CASE WHEN ((StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND MONTH(StatisticalDate) = MONTH(@var_date)) THEN CCjAmount
                                    WHEN  ( s.TsyjType = '物业公司车位代销' AND   (StatisticalDate BETWEEN @bzSDate AND @bzEDate) 
                                        AND MONTH(StatisticalDate) = MONTH(@var_date)) THEN r.CjRmbTotal /10000.0
                                ELSE 0
                        END) AS bzhzje ,                                                                                                                                                                    --本周认购金额
                        SUM(
                        CASE WHEN ((StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND MONTH(StatisticalDate) = MONTH(@var_date))
                                    OR   ( s.TsyjType = '物业公司车位代销' AND  (StatisticalDate BETWEEN @bzSDate AND @bzEDate) 
                                    AND MONTH(StatisticalDate) = MONTH(@var_date)) THEN CCjArea
                                ELSE 0
                        END) AS bzhzmj ,                                                                                                                                                                    --本周认购面积                             
                        SUM(
                        CASE WHEN ((StatisticalDate BETWEEN @bzSDate AND @bzEDate) AND MONTH(StatisticalDate) = MONTH(@var_date))
                                    OR   ( s.TsyjType = '物业公司车位代销' AND  (StatisticalDate BETWEEN @bzSDate AND @bzEDate) 
                                    AND MONTH(StatisticalDate) = MONTH(@var_date)) THEN CCjCount
                                ELSE 0
                        END) AS bzhzts ,                                                                                                                                                                    --本周认购套数

                        SUM(CASE WHEN DATEDIFF(DAY, StatisticalDate, @var_date) = 0 THEN  CCjAmount
                                WHEN  (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) 
                                THEN r.CjRmbTotal /10000.0 ELSE 0 END) AS brhzje ,        --本日认购金额
                        SUM(CASE WHEN DATEDIFF(DAY, StatisticalDate, @var_date) = 0 
                                OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) THEN CCjArea ELSE 0 END) AS brhzmj,   --本日认购面积
                        SUM(CASE WHEN DATEDIFF(DAY, StatisticalDate, @var_date) = 0 
                                OR (s.TsyjType = '物业公司车位代销' AND DATEDIFF(DAY, StatisticalDate, @var_date) = 0) THEN CCjCount ELSE 0 END) AS brhzts           --本日认购套数
                    FROM   dbo.data_wide_s_SpecialPerformance s
                        LEFT JOIN data_wide_s_RoomoVerride r ON s.roomguid = r.roomguid
                        INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = s.BldGUID
                    WHERE 1 = 1    --StatisticalDate BETWEEN CONVERT(VARCHAR(4), YEAR(@var_date)) + '-01-01' AND CONVERT(VARCHAR(4), YEAR(@var_date)) + '-12-31'
                    GROUP BY s.ParentProjGUID ,
                            bld.TopProductTypeName) ts ON ts.ProjGUID = pj.ProjGUID AND  pt.TopProductTypeName = ts.TopProductTypeName
        WHERE   pj.Level = 2
        GROUP BY pj.ProjGUID ,
                 pt.TopProductTypeName;

        --统计数字营销的销售数据
        SELECT  os.ParentProjGUID AS ProjGUID ,
                bld.TopProductTypeName ,
                SUM(CASE WHEN DATEDIFF(DAY, os.RgQsDate, @var_date) = 0 THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销本日认购金额 ,

                SUM(CASE WHEN DATEDIFF(DAY, os.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销本日认购套数 ,
                SUM(CASE WHEN (os.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(os.RgQsDate) = MONTH(@var_date) THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销本周认购金额 ,
                SUM(CASE WHEN (os.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(os.RgQsDate) = MONTH(@var_date) THEN 1 ELSE 0 END) AS 数字营销本周认购套数 ,


                SUM(CASE WHEN DATEDIFF(MONTH, os.RgQsDate, @var_date) = 0 THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销本月认购金额 ,
                SUM(CASE WHEN DATEDIFF(MONTH, os.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销本月认购套数 ,
                SUM(CASE WHEN DATEDIFF(DAY, os.QyQsDate, @var_date) = 0 THEN os.QyAmount ELSE 0 END) / 10000.0 AS 数字营销本日签约金额 ,
                SUM(CASE WHEN DATEDIFF(DAY, os.QyQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销本日签约套数 ,

				SUM(CASE WHEN (os.QyQsDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(os.QyQsDate) = MONTH(@var_date)  THEN os.QyAmount ELSE 0 END) / 10000.0 AS 数字营销本周签约金额 ,
                SUM(CASE WHEN (os.QyQsDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(os.QyQsDate) = MONTH(@var_date)  THEN 1 ELSE 0 END) AS 数字营销本周签约套数 ,
                SUM(CASE WHEN DATEDIFF(MONTH, os.QyQsDate, @var_date) = 0 THEN os.QyAmount ELSE 0 END) / 10000.0 AS 数字营销本月签约金额 ,
                SUM(CASE WHEN DATEDIFF(MONTH, os.QyQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销本月签约套数 ,
                SUM(CASE WHEN r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销已认购未签约金额 ,
                SUM(CASE WHEN r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN 1 ELSE 0 END) AS 数字营销已认购未签约套数 ,
                SUM(CASE WHEN DATEDIFF(YEAR, os.RgQsDate, @var_date) = 0 THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销本年认购金额 ,
                SUM(CASE WHEN DATEDIFF(YEAR, os.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销本年认购套数 ,
                SUM(CASE WHEN DATEDIFF(YEAR, os.QyQsDate, @var_date) = 0 THEN os.QyAmount ELSE 0 END) / 10000.0 AS 数字营销本年签约金额 ,
                SUM(CASE WHEN DATEDIFF(YEAR, os.QyQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销本年签约套数,

				--产成品
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND   DATEDIFF(DAY, os.RgQsDate, @var_date) = 0 THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销产成品本日认购金额 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(DAY, os.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销产成品本日认购套数 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  (os.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(os.RgQsDate) = MONTH(@var_date) THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销产成品本周认购金额 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  (os.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(os.RgQsDate) = MONTH(@var_date) THEN 1 ELSE 0 END) AS 数字营销产成品本周认购套数 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(MONTH, os.RgQsDate, @var_date) = 0 THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销产成品本月认购金额 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(MONTH, os.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销产成品本月认购套数 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(DAY, os.QyQsDate, @var_date) = 0 THEN os.QyAmount ELSE 0 END) / 10000.0 AS 数字营销产成品本日签约金额 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(DAY, os.QyQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销产成品本日签约套数 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(MONTH, os.QyQsDate, @var_date) = 0 THEN os.QyAmount ELSE 0 END) / 10000.0 AS 数字营销产成品本月签约金额 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(MONTH, os.QyQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销产成品本月签约套数 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销产成品已认购未签约金额 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN 1 ELSE 0 END) AS 数字营销产成品已认购未签约套数 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND   DATEDIFF(YEAR, os.RgQsDate, @var_date) = 0 THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销产成品本年认购金额 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(YEAR, os.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销产成品本年认购套数 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(YEAR, os.QyQsDate, @var_date) = 0 THEN os.QyAmount ELSE 0 END) / 10000.0 AS 数字营销产成品本年签约金额 ,
                SUM(CASE WHEN  YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(YEAR, os.QyQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销产成品本年签约套数,

                --准产成品
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(DAY, os.RgQsDate, @var_date) = 0 THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销准产成品本日认购金额 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(DAY, os.RgQsDate, @var_date) = 0 THEN r.BldArea ELSE 0 END)  AS 数字营销准产成品本日认购面积,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(DAY, os.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销准产成品本日认购套数 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  (os.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(os.RgQsDate) = MONTH(@var_date) THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销准产成品本周认购金额 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  (os.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(os.RgQsDate) = MONTH(@var_date) THEN r.BldArea ELSE 0 END) AS 数字营销准产成品本周认购面积,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  (os.RgQsDate BETWEEN @bzSDate AND @bzEDate) AND   MONTH(os.RgQsDate) = MONTH(@var_date) THEN 1 ELSE 0 END) AS 数字营销准产成品本周认购套数 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(MONTH, os.RgQsDate, @var_date) = 0 THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销准产成品本月认购金额 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(MONTH, os.RgQsDate, @var_date) = 0 THEN r.BldArea ELSE 0 END)  AS 数字营销准产成品本月认购面积,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(MONTH, os.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销准产成品本月认购套数 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(DAY, os.QyQsDate, @var_date) = 0 THEN os.QyAmount ELSE 0 END) / 10000.0 AS 数字营销准产成品本日签约金额 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(DAY, os.QyQsDate, @var_date) = 0 THEN r.BldArea ELSE 0 END) AS 数字营销准产成品本日签约面积,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(DAY, os.QyQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销准产成品本日签约套数 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(MONTH, os.QyQsDate, @var_date) = 0 THEN os.QyAmount ELSE 0 END) / 10000.0 AS 数字营销准产成品本月签约金额 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(MONTH, os.QyQsDate, @var_date) = 0 THEN r.BldArea ELSE 0 END) AS 数字营销准产成品本月签约面积,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(MONTH, os.QyQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销准产成品本月签约套数 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销准产成品已认购未签约金额 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN r.BldArea ELSE 0 END)  AS 数字营销准产成品已认购未签约面积,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  r.specialFlag = '否' AND   r.Status = '认购' AND r.specialFlag = '否' THEN 1 ELSE 0 END) AS 数字营销准产成品已认购未签约套数 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(YEAR, os.RgQsDate, @var_date) = 0 THEN os.RgAmount ELSE 0 END) / 10000.0 AS 数字营销准产成品本年认购金额 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(YEAR, os.RgQsDate, @var_date) = 0 THEN r.BldArea ELSE 0 END) AS 数字营销准产成品本年认购面积 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(YEAR, os.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销准产成品本年认购套数 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(YEAR, os.QyQsDate, @var_date) = 0 THEN os.QyAmount ELSE 0 END) / 10000.0 AS 数字营销准产成品本年签约金额 ,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(YEAR, os.QyQsDate, @var_date) = 0 THEN r.BldArea ELSE 0 END) AS 数字营销准产成品本年签约面积,
                SUM(CASE WHEN  (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(YEAR, os.QyQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销准产成品本年签约套数
        INTO    #szyx
        FROM    data_wide_s_OnlineSaleRoomDtl os
                INNER JOIN data_wide_s_RoomoVerride r ON os.roomguid = r.roomguid
                INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = os.SaleBldGUID
        WHERE   os.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
        GROUP BY os.ParentProjGUID ,
                 bld.TopProductTypeName;

        --获取数字营销的其他业绩数据
        SELECT  p.projguid ,
                bld.TopProductTypeName ,
                SUM(CASE WHEN DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩本日认购金额 ,
                SUM(CASE WHEN DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销其他业绩本日认购套数 ,
                SUM(CASE WHEN DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩本周认购金额 ,
                SUM(CASE WHEN DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN 1 ELSE 0 END) AS 数字营销其他业绩本周认购套数 ,
                SUM(CASE WHEN DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩本月认购金额 ,
                SUM(CASE WHEN DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销其他业绩本月认购套数 ,
                SUM(CASE WHEN YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩本年认购金额 ,
                SUM(CASE WHEN YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 数字营销其他业绩本年认购套数 ,
                SUM(CASE WHEN r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩本年签约金额 ,
                SUM(CASE WHEN r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 数字营销其他业绩本年签约套数 ,
                SUM(CASE WHEN r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩本月签约金额 ,
                SUM(CASE WHEN r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销其他业绩本月签约套数,
                -- 产成品
				SUM(CASE WHEN YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩产成品本日认购金额 ,
                SUM(CASE WHEN YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销其他业绩产成品本日认购套数 ,
                SUM(CASE WHEN YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩产成品本周认购金额 ,
                SUM(CASE WHEN YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN 1 ELSE 0 END) AS 数字营销其他业绩产成品本周认购套数 ,
                SUM(CASE WHEN YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩产成品本月认购金额 ,
                SUM(CASE WHEN YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销其他业绩产成品本月认购套数 ,
                SUM(CASE WHEN YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩产成品本年认购金额 ,
                SUM(CASE WHEN YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 数字营销其他业绩产成品本年认购套数 ,
                SUM(CASE WHEN YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩产成品本年签约金额 ,
                SUM(CASE WHEN YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 数字营销其他业绩产成品本年签约套数 ,
                SUM(CASE WHEN YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩产成品本月签约金额 ,
                SUM(CASE WHEN YEAR(bld.FactFinishDate) < CONVERT(VARCHAR(4), YEAR(@var_date)) AND  r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销其他业绩产成品本月签约套数,
                -- 准产成品
				SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩准产成品本日认购金额 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN r.BldArea ELSE 0 END) AS 数字营销其他业绩准产成品本日认购面积,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(DAY, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销其他业绩准产成品本日认购套数 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩准产成品本周认购金额 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN r.BldArea ELSE 0 END) AS 数字营销其他业绩准产成品本周认购面积,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND   DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 AND (r.RgQsDate BETWEEN @bzSDate AND @bzEDate) THEN 1 ELSE 0 END) AS 数字营销其他业绩准产成品本周认购套数 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩准产成品本月认购金额 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN r.BldArea ELSE 0 END) AS 数字营销其他业绩准产成品本月认购面积,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  DATEDIFF(MONTH, r.RgQsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销其他业绩准产成品本月认购套数 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩准产成品本年认购金额 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  YEAR(r.QsDate) = YEAR(@var_date) THEN r.BldArea ELSE 0 END)  AS 数字营销其他业绩准产成品本年认购面积 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 数字营销其他业绩准产成品本年认购套数 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩准产成品本年签约金额 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN r.BldArea ELSE 0 END) AS 数字营销其他业绩准产成品本年签约面积,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  r.Status = '签约' AND   YEAR(r.QsDate) = YEAR(@var_date) THEN 1 ELSE 0 END) AS 数字营销其他业绩准产成品本年签约套数 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩准产成品本月签约金额 ,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN r.CjRmbTotal ELSE 0 END) / 10000.0 AS 数字营销其他业绩准产成品本月签约面积,
                SUM(CASE WHEN (DATEDIFF(YEAR,bld.FactFinishDate,@var_date) = 0 OR (DATEDIFF(YEAR,bld.PlanFinishDate,@var_date) = 0 AND bld.FactFinishDate IS NULL)) AND  r.Status = '签约' AND   DATEDIFF(MONTH, r.QsDate, @var_date) = 0 THEN 1 ELSE 0 END) AS 数字营销其他业绩准产成品本月签约套数

        INTO    #szqtqy
        FROM    data_wide_s_SpecialPerformance a
                INNER JOIN data_wide_s_OnlineSaleRoomDtl os ON os.roomguid = a.roomguid
                INNER JOIN data_wide_s_RoomoVerride r ON a.RoomGUID = r.RoomGUID
                INNER JOIN data_wide_dws_mdm_Building bld ON bld.BuildingGUID = r.BldGUID
                INNER JOIN data_wide_dws_mdm_Project p ON a.ParentProjGUID = p.ProjGUID AND p.Level = 2
                INNER JOIN #qtyj qt ON qt.明源系统代码 = p.ProjCode
        WHERE   DATEDIFF(DAY, a.[StatisticalDate], qt.认定日期) = 0 AND r.Status IN ('认购', '签约')    -- AND YEAR(r.QsDate) = YEAR(@var_date)
        GROUP BY p.projguid ,
                 bld.TopProductTypeName;

        -- 获取数据最新更新日期时间
        DECLARE @DateText VARCHAR(50);
        SET @DateText = CONVERT(VARCHAR(19), @var_date, 121);
		--select @DateText = CONVERT(VARCHAR(19), LastCalcTime, 121) from mdc_table where  TableName ='data_wide_s_RoomoVerride'
        
        declare @wideTableDateText varchar(50)
        select @wideTableDateText = CONVERT(VARCHAR(19), LastCalcTime, 121) from mdc_table where  TableName ='data_wide_s_RoomoVerride'

        -- 保存到清洗表中
        -- 避免重复先删除当天的数据
        DELETE  FROM s_hnyxxp_projSaleNew WHERE DATEDIFF(DAY, 数据清洗日期, @var_date) = 0;

        -- 查询结果
        INSERT INTO s_hnyxxp_projSaleNew
        -- 区域层级-全部区域
		SELECT  @DateText AS 数据清洗日期 ,
				'营销大区' AS 层级 ,
				p.BUGUID AS 公司GUID ,
				tb.营销事业部 AS 区域 ,
				tb.营销片区 ,
				p.ProjGUID AS 项目GUID ,
				ISNULL(tb.推广名称, p.SpreadName) AS 项目名称 ,
				'全部区域' AS 层级名称 ,
				CASE WHEN ISNULL(tb.区域负责人, '') <> '' THEN tb.营销事业部 + '(' + ISNULL(tb.区域负责人, '') + ')' ELSE tb.营销事业部 END AS 层级名称显示 ,
																																--CASE WHEN isnull(tb.区域负责人,'')<> '' then    tb.营销事业部 +'('+isnull(tb.区域负责人,'') +')' 
																																--  else  tb.营销事业部 end   AS 层级名称 ,
				CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END AS 项目名称负责人 ,
				CASE WHEN pt.TopProductTypeName IN ('高级住宅', '住宅', '别墅') THEN '住宅'
					 WHEN pt.TopProductTypeName IN ('地下室/车库') THEN '车位'
					 WHEN pt.TopProductTypeName IN ('商业', '公寓', '写字楼', '酒店', '会所', '企业会所') THEN '商办'
					 ELSE '其他'
				END AS 业态 ,
				pt.TopProductTypeName AS 产品类型 ,
				pt.TopProductTypeGUID AS 产品类型GUID ,
				tb.城市 ,
				tb.公司 ,
				tb.投管编码 ,
				tb.项目负责人 ,
				p.BeginDate AS 项目获取日期 ,
				--pt.FactFinishDate AS  实际竣备日期,
				--CASE WHEN  YEAR(pt.FactFinishDate)  < YEAR(@var_date) THEN  '是' ELSE  '否' END  AS 是否产成品,
				pt.存量增量 ,
				ISNULL(rs.本日认购金额, 0) + ISNULL(rg.本日认购金额, 0) + ISNULL(qt.其他业绩本日认购金额, 0) AS 本日认购金额 ,                              -- 全口径
				ISNULL(rs.本日认购套数, 0) + ISNULL(rg.本日认购套数, 0) + ISNULL(qt.其他业绩本日认购套数, 0) AS 本日认购套数 ,
				ISNULL(s.本日签约金额全口径, 0) AS 本日签约金额 ,
				ISNULL(s.本日签约套数全口径, 0) AS 本日签约套数 ,
				ISNULL(rs.本周认购金额, 0) + ISNULL(rg.本周认购金额, 0) + ISNULL(qt.其他业绩本周认购金额, 0) AS 本周认购金额 ,
				ISNULL(rs.本周认购套数, 0) + ISNULL(rg.本周认购套数, 0) + ISNULL(qt.其他业绩本周认购套数, 0) AS 本周认购套数 ,
				rw.月度签约任务 AS 本月任务 ,
				ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0) + ISNULL(qt.其他业绩本月认购金额, 0) + ISNULL(rw.非项目本月实际认购金额, 0) AS 本月认购金额 ,
				ISNULL(rs.本月认购套数, 0) + ISNULL(rg.本月认购套数, 0) + ISNULL(qt.其他业绩本月认购套数, 0) AS 本月认购套数 ,
				ISNULL(qt.其他业绩本月认购金额, 0) AS 其他业绩本月认购金额 ,
				ISNULL(qt.其他业绩本月认购套数, 0) AS 其他业绩本月认购套数 ,
				CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0
					 ELSE (ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0) + ISNULL(qt.其他业绩本月认购金额, 0) + ISNULL(rw.非项目本月实际认购金额, 0)) / ISNULL(rw.月度签约任务, 0)
				END AS 本月认购完成率 ,
				ISNULL(本月签约金额全口径, 0) + ISNULL(rw.非项目本月实际签约金额, 0) AS 本月签约金额 ,
				ISNULL(本月签约套数全口径, 0) AS 本月签约套数 ,
				ISNULL(qt.其他业绩本月签约金额, 0) AS 其他业绩本月签约金额 ,                                                                        --以客户提供其他业绩认定的房间
				ISNULL(qt.其他业绩本月签约套数, 0) AS 其他业绩本月签约套数 ,
				CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE (ISNULL(本月签约金额全口径, 0) + ISNULL(rw.非项目本月实际签约金额, 0)) / ISNULL(rw.月度签约任务, 0)END AS 本月签约完成率 ,
				CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE (ISNULL(本月签约金额全口径, 0) + ISNULL(qt.其他业绩本月签约金额, 0) + ISNULL(rw.非项目本月实际签约金额, 0)) / ISNULL(rw.月度签约任务, 0)END AS 本月签约完成率_含其他业绩 ,
				ISNULL(rw.月度签约任务, 0) - (ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0) + ISNULL(rw.非项目本月实际认购金额, 0)) AS 本月认购金额缺口 ,  --本月任务*本月时间进度分摊比-本月认购金额
				ISNULL(rw.月度签约任务, 0) - (ISNULL(本月签约金额全口径, 0) + ISNULL(rw.非项目本月实际签约金额, 0)) AS 本月签约金额缺口 ,
				ISNULL(pt.本月时间分摊比, 0) AS 本月时间分摊比 ,
				ISNULL(rs.累计已认购未签约金额, 0) AS 已认购未签约金额 ,
				ISNULL(rs.累计已认购未签约套数, 0) AS 已认购未签约套数 ,
				ISNULL(rw.年度签约任务, 0) AS 本年任务 ,
				ISNULL(rs.本年认购金额, 0) + ISNULL(rg.本年认购金额, 0) + ISNULL(qt.其他业绩本年认购金额, 0) + ISNULL(rw.非项目本年实际认购金额, 0) AS 本年认购金额 ,
				ISNULL(rs.本年认购套数, 0) + ISNULL(rg.本年认购套数, 0) + ISNULL(qt.其他业绩本年认购套数, 0) AS 本年认购套数 ,
				ISNULL(s.本年签约金额全口径, 0) + ISNULL(rw.非项目本年实际签约金额, 0) AS 本年签约金额 ,
				ISNULL(s.本年签约套数全口径, 0) AS 本年签约套数 ,
				ISNULL(qt.其他业绩本年签约金额, 0) AS 其他业绩本年签约金额 ,
				ISNULL(qt.其他业绩本年签约套数, 0) AS 其他业绩本年签约套数 ,
				CASE WHEN ISNULL(rw.年度签约任务, 0) = 0 THEN 0 ELSE (ISNULL(s.本年签约金额全口径, 0) + ISNULL(rw.非项目本年实际签约金额, 0)) / ISNULL(rw.年度签约任务, 0)END AS 本年签约完成率 ,
				CASE WHEN ISNULL(rw.年度签约任务, 0) = 0 THEN 0 ELSE (ISNULL(s.本年签约金额全口径, 0) + ISNULL(qt.其他业绩本年签约金额, 0) + ISNULL(rw.非项目本年实际签约金额, 0)) / ISNULL(rw.年度签约任务, 0)END AS 本年签约完成率_含其他业绩 ,
				ISNULL(rw.年度签约任务, 0) - (ISNULL(rs.本年认购金额, 0) + ISNULL(rg.本年认购金额, 0) + ISNULL(rw.非项目本年实际认购金额, 0)) AS 本年认购金额缺口 ,
				ISNULL(rw.年度签约任务, 0) - (ISNULL(本年签约金额全口径, 0) + ISNULL(rw.非项目本年实际签约金额, 0)) AS 本年签约金额缺口 ,
				ISNULL(pt.本年时间分摊比, 0) AS 本年时间分摊比 ,
				ISNULL(rw.本年存量任务, 0) AS 本年存量任务 ,
				ISNULL(rw.本年增量任务, 0) AS 本年增量任务 ,
				ISNULL(rw.本年新增量任务, 0) AS 本年新增量任务 ,
				ISNULL(rw.本月存量任务, 0) AS 本月存量任务 ,
				ISNULL(rw.本月增量任务, 0) AS 本月增量任务 ,
				ISNULL(rw.本月新增量任务, 0) AS 本月新增量任务 ,
				-- 产成品 计算逻辑为现产成品
                -- 注意 数据库里存的 产成品月度任务 为现产成品任务
				ISNULL(rs.本日产成品认购金额, 0) + ISNULL(rg.本日产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本日认购金额, 0) AS 本日产成品认购金额 ,
				ISNULL(rs.本日产成品认购套数, 0) + ISNULL(rg.本日产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本日认购套数, 0) AS 本日产成品认购套数 ,
				ISNULL(s.本日产成品签约金额全口径, 0) AS 本日产成品签约金额 ,
				ISNULL(s.本日产成品签约套数全口径, 0) AS 本日产成品签约套数 ,
				ISNULL(rs.本周产成品认购金额, 0) + ISNULL(rg.本周产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本周认购金额, 0) AS 本周产成品认购金额 ,
				ISNULL(rs.本周产成品认购套数, 0) + ISNULL(rg.本周产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本周认购套数, 0) AS 本周产成品认购套数 ,
				rw.产成品月度任务 AS 本月产成品任务 ,
				ISNULL(rs.本月产成品认购金额, 0) + ISNULL(rg.本月产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本月认购金额, 0) AS 本月产成品认购金额 ,
				ISNULL(rs.本月产成品认购套数, 0) + ISNULL(rg.本月产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本月认购套数, 0) AS 本月产成品认购套数 ,
				ISNULL(qt.其他业绩产成品本月认购金额, 0) AS 其他业绩产成品本月认购金额 ,
				ISNULL(qt.其他业绩产成品本月认购套数, 0) AS 其他业绩产成品本月认购套数 ,
				CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE (ISNULL(rs.本月产成品认购金额, 0) + ISNULL(rg.本月产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本月认购金额, 0)) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品认购完成率 ,
				ISNULL(本月产成品签约金额全口径, 0) AS 本月产成品签约金额 ,
				ISNULL(本月产成品签约套数全口径, 0) AS 本月产成品签约套数 ,
				ISNULL(qt.其他业绩产成品本月签约金额, 0) AS 其他业绩产成品本月签约金额 ,
				ISNULL(qt.其他业绩产成品本月签约套数, 0) AS 其他业绩产成品本月签约套数 ,
				CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE ISNULL(本月产成品签约金额全口径, 0) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品签约完成率 ,
				CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE (ISNULL(本月产成品签约金额全口径, 0) + ISNULL(qt.其他业绩产成品本月签约金额, 0)) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品签约完成率_含其他业绩 ,
				ISNULL(rs.累计产成品已认购未签约金额, 0) AS 累计产成品已认购未签约金额 ,
				ISNULL(rs.累计产成品已认购未签约套数, 0) AS 累计产成品已认购未签约套数 ,
				ISNULL(rw.产成品年度任务, 0) AS 本年产成品任务 ,
				ISNULL(rs.本年产成品认购金额, 0) + ISNULL(rg.本年产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本年认购金额, 0) AS 本年产成品认购金额 ,
				ISNULL(rs.本年产成品认购套数, 0) + ISNULL(rg.本年产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本年认购套数, 0) AS 本年产成品认购套数 ,
				ISNULL(s.本年产成品签约金额全口径, 0) AS 本年产成品签约金额 ,
				ISNULL(s.本年产成品签约套数全口径, 0) AS 本年产成品签约套数 ,
				ISNULL(qt.其他业绩产成品本年签约金额, 0) AS 其他业绩产成品本年签约金额 ,
				ISNULL(qt.其他业绩产成品本年签约套数, 0) AS 其他业绩产成品本年签约套数 ,
				CASE WHEN ISNULL(rw.产成品年度任务, 0) = 0 THEN 0 ELSE ISNULL(s.本年产成品签约金额全口径, 0) / ISNULL(rw.产成品年度任务, 0)END AS 本年产成品签约完成率 ,
				CASE WHEN ISNULL(rw.产成品年度任务, 0) = 0 THEN 0 ELSE (ISNULL(s.本年产成品签约金额全口径, 0) + ISNULL(qt.其他业绩产成品本年签约金额, 0)) / ISNULL(rw.产成品年度任务, 0)END AS 本年产成品签约完成率_含其他业绩 ,
				
                ISNULL(rw.非项目本年实际签约金额, 0) AS 非项目本年实际签约金额 ,
				ISNULL(rw.非项目本月实际签约金额, 0) AS 非项目本月实际签约金额 ,
				ISNULL(rw.非项目本年实际认购金额, 0) AS 非项目本年实际认购金额 ,
				ISNULL(rw.非项目本月实际认购金额, 0) AS 非项目本月实际认购金额 ,
				-- 20240604 chenjw 新增面积类字段
			    ISNULL(rs.本日认购面积, 0) + ISNULL(rg.本日认购面积, 0) + ISNULL(qt.其他业绩本日认购金额, 0)  AS 本日认购面积 ,
				ISNULL(s.本日签约面积全口径,0)   AS 本日签约面积 ,
			    ISNULL(rs.本周认购面积,0) + ISNULL(rg.本周认购面积,0) + ISNULL(qt.其他业绩本周认购面积,0) AS 本周认购面积 ,
				ISNULL(s.本周签约套数全口径,0) AS 本周签约套数 ,
				ISNULL(s.本周签约面积全口径,0) AS 本周签约面积 ,
				ISNULL(s.本周签约金额全口径,0) AS 本周签约金额 ,
				ISNULL(rs.本月认购面积,0) + ISNULL(rg.本月认购面积,0) + ISNULL(qt.其他业绩本月认购面积,0) AS 本月认购面积 ,
				ISNULL(s.本月签约面积全口径, 0) AS 本月签约面积 ,
				ISNULL(qt.其他业绩本月认购面积,0) AS 其他业绩本月认购面积 ,
				ISNULL(qt.其他业绩本月签约面积,0) AS 其他业绩本月签约面积 ,
				ISNULL(rs.本月产成品认购面积, 0) + ISNULL(rg.本月产成品认购面积, 0) + ISNULL(qt.其他业绩产成品本月认购面积, 0) AS 本月产成品认购面积 ,
				ISNULL(s.本月产成品签约面积全口径,0)  AS 本月产成品签约面积 ,
				ISNULL(qt.其他业绩产成品本月签约面积,0)  AS 其他业绩产成品本月签约面积 ,
				ISNULL(rs.累计产成品已认购未签约面积,0) AS 已认购未签约签约面积 ,
				ISNULL(rs.本年认购面积, 0) + ISNULL(rg.本年认购面积, 0) + ISNULL(qt.其他业绩本年认购面积, 0) AS 本年认购面积 ,
				ISNULL(本年签约面积全口径, 0) AS 本年签约面积 ,
				ISNULL(qt.其他业绩本年认购套数,0) AS 其他业绩本年认购套数 ,
				ISNULL(qt.其他业绩本日认购面积,0) AS 其他业绩本年认购面积 ,
				ISNULL(qt.其他业绩本日认购金额,0) AS 其他业绩本年认购金额 ,

				ISNULL(qt.其他业绩本年签约面积,0) AS 其他业绩本年签约面积 ,
				ISNULL(rs.本年产成品认购面积, 0) + ISNULL(rg.本年产成品认购面积, 0) + ISNULL(qt.其他业绩产成品本年认购面积, 0) AS 本年产成品认购面积 ,
				ISNULL(s.本年产成品签约面积全口径,0) AS 本年产成品签约面积 ,
				ISNULL(qt.其他业绩产成品本年签约面积,0 ) AS 其他业绩产成品本年签约面积,
                @wideTableDateText  as 宽表最后清洗日期,

                --大户型
                ISNULL(rs.本日大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本日认购金额, 0) as 本日大户型认购金额,
                ISNULL(rs.本日大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本日认购面积, 0)  as 本日大户型认购面积,
                ISNULL(rs.本日大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本日认购套数, 0)  as 本日大户型认购套数,
                ISNULL(dhx.本日大户型签约金额全口径, 0)   as 本日大户型签约金额,
                ISNULL(dhx.本日大户型签约面积全口径, 0)  as 本日大户型签约面积,
                ISNULL(dhx.本日大户型签约套数全口径, 0)  as 本日大户型签约套数,

                ISNULL(rs.本周大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本周认购金额, 0) as 本周大户型认购金额,
                ISNULL(rs.本周大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本周认购面积, 0) as 本周大户型认购面积,
                ISNULL(rs.本周大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本周认购套数, 0) as 本周大户型认购套数,
                ISNULL(dhx.本周大户型签约金额全口径, 0) as 本周大户型签约金额,
                ISNULL(dhx.本周大户型签约面积全口径, 0) as 本周大户型签约面积,
                ISNULL(dhx.本周大户型签约套数全口径, 0) as 本周大户型签约套数,

                ISNULL(rs.本月大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本月认购金额, 0) as 本月大户型认购金额,
                ISNULL(rs.本月大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本月认购面积, 0) as 本月大户型认购面积,
                ISNULL(rs.本月大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本月认购套数, 0) as 本月大户型认购套数,
                ISNULL(dhx.本月大户型签约金额全口径,0) + ISNULL(qt.其他业绩大户型本月签约金额,0) as 本月大户型签约金额,
                ISNULL(dhx.本月大户型签约面积全口径,0) + ISNULL(qt.其他业绩大户型本月签约面积,0) as 本月大户型签约面积,
                ISNULL(dhx.本月大户型签约套数全口径,0) + ISNULL(qt.其他业绩大户型本月签约套数,0) as 本月大户型签约套数,

                ISNULL(rs.本年大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本年认购金额, 0) as 本年大户型认购金额,
                ISNULL(rs.本年大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本年认购面积, 0) as 本年大户型认购面积,
                ISNULL(rs.本年大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本年认购套数, 0) as 本年大户型认购套数,
                ISNULL(dhx.本年大户型签约金额全口径,0) + ISNULL(qt.其他业绩大户型本年签约金额,0) as 本年大户型签约金额,
                ISNULL(dhx.本年大户型签约面积全口径,0) + ISNULL(qt.其他业绩大户型本年签约面积,0) as 本年大户型签约面积,
                ISNULL(dhx.本年大户型签约套数全口径,0) + ISNULL(qt.其他业绩大户型本年签约套数,0) as 本年大户型签约套数,

                ISNULL(rs.累计大户型已认购未签约金额,0) as 累计大户型已认购未签约金额,
                ISNULL(rs.累计大户型已认购未签约面积,0) as 累计大户型已认购未签约面积,
                ISNULL(rs.累计大户型已认购未签约套数,0) as 累计大户型已认购未签约套数,
                ISNULL(rs.本年大户型已认购未签约金额,0) as 本年大户型已认购未签约金额,
                ISNULL(rs.本年大户型已认购未签约套数,0) as 本年大户型已认购未签约套数,
                ISNULL(rs.本月大户型已认购未签约金额,0) as 本月大户型已认购未签约金额,
                ISNULL(rs.本月大户型已认购未签约套数,0) as 本月大户型已认购未签约套数,

                --联动房
                ISNULL(rs.本日联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本日认购金额, 0) as 本日联动房认购金额,
                ISNULL(rs.本日联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本日认购面积, 0)  as 本日联动房认购面积,
                ISNULL(rs.本日联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本日认购套数, 0)  as 本日联动房认购套数,
                ISNULL(dhx.本日联动房签约金额全口径, 0)   as 本日联动房签约金额,
                ISNULL(dhx.本日联动房签约面积全口径, 0)  as 本日联动房签约面积,
                ISNULL(dhx.本日联动房签约套数全口径, 0)  as 本日联动房签约套数,

                ISNULL(rs.本周联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本周认购金额, 0) as 本周联动房认购金额,
                ISNULL(rs.本周联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本周认购面积, 0) as 本周联动房认购面积,
                ISNULL(rs.本周联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本周认购套数, 0) as 本周联动房认购套数,
                ISNULL(dhx.本周联动房签约金额全口径, 0) as 本周联动房签约金额,
                ISNULL(dhx.本周联动房签约面积全口径, 0) as 本周联动房签约面积,
                ISNULL(dhx.本周联动房签约套数全口径, 0) as 本周联动房签约套数,

                ISNULL(rs.本月联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本月认购金额, 0) as 本月联动房认购金额,
                ISNULL(rs.本月联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本月认购面积, 0) as 本月联动房认购面积,
                ISNULL(rs.本月联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本月认购套数, 0) as 本月联动房认购套数,
                ISNULL(dhx.本月联动房签约金额全口径,0) + ISNULL(qt.其他业绩联动房本月签约金额,0) as 本月联动房签约金额,
                ISNULL(dhx.本月联动房签约面积全口径,0) + ISNULL(qt.其他业绩联动房本月签约面积,0) as 本月联动房签约面积,
                ISNULL(dhx.本月联动房签约套数全口径,0) + ISNULL(qt.其他业绩联动房本月签约套数,0) as 本月联动房签约套数,

                ISNULL(rs.本年联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本年认购金额, 0) as 本年联动房认购金额,
                ISNULL(rs.本年联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本年认购面积, 0) as 本年联动房认购面积,
                ISNULL(rs.本年联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本年认购套数, 0) as 本年联动房认购套数,
                ISNULL(dhx.本年联动房签约金额全口径,0) + ISNULL(qt.其他业绩联动房本年签约金额,0) as 本年联动房签约金额,
                ISNULL(dhx.本年联动房签约面积全口径,0) + ISNULL(qt.其他业绩联动房本年签约面积,0) as 本年联动房签约面积,
                ISNULL(dhx.本年联动房签约套数全口径,0) + ISNULL(qt.其他业绩联动房本年签约套数,0) as 本年联动房签约套数,

                ISNULL(rs.累计联动房已认购未签约金额,0) AS 累计联动房已认购未签约金额,
                ISNULL(rs.累计联动房已认购未签约面积,0) AS 累计联动房已认购未签约面积,
                ISNULL(rs.累计联动房已认购未签约套数,0) AS 累计联动房已认购未签约套数,
                ISNULL(rs.本年联动房已认购未签约金额,0) AS 本年联动房已认购未签约金额,
                ISNULL(rs.本年联动房已认购未签约套数,0) AS 本年联动房已认购未签约套数,
                ISNULL(rs.本月联动房已认购未签约金额,0) AS 本月联动房已认购未签约金额,
                ISNULL(rs.本月联动房已认购未签约套数,0) AS 本月联动房已认购未签约套数,

                ISNULL(qt.其他业绩大户型本月签约金额,0) as 其他业绩大户型本月签约金额,
                ISNULL(qt.其他业绩大户型本月签约面积,0) as 其他业绩大户型本月签约面积,
                ISNULL(qt.其他业绩大户型本月签约套数,0) as 其他业绩大户型本月签约套数,
                ISNULL(qt.其他业绩大户型本年签约金额,0) as 其他业绩大户型本年签约金额,
                ISNULL(qt.其他业绩大户型本年签约面积,0) as 其他业绩大户型本年签约面积,
                ISNULL(qt.其他业绩大户型本年签约套数,0) as 其他业绩大户型本年签约套数,

                -- 准产成品
				ISNULL(rs.本日准产成品认购金额, 0) + ISNULL(rg.本日准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本日认购金额, 0) AS 本日准产成品认购金额,
                ISNULL(rs.本日准产成品认购面积, 0) + ISNULL(rg.本日准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本日认购面积, 0) AS 本日准产成品认购面积,
				ISNULL(rs.本日准产成品认购套数, 0) + ISNULL(rg.本日准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本日认购套数, 0) AS 本日准产成品认购套数 ,

				ISNULL(s.本日准产成品签约金额全口径, 0) AS 本日准产成品签约金额 ,
                ISNULL(s.本日准产成品签约面积全口径, 0) AS 本日准产成品签约面积 ,
				ISNULL(s.本日准产成品签约套数全口径, 0) AS 本日准产成品签约套数 ,

				ISNULL(rs.本周准产成品认购金额, 0) + ISNULL(rg.本周准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本周认购金额, 0) AS 本周准产成品认购金额 ,
                ISNULL(rs.本周准产成品认购面积, 0) + ISNULL(rg.本周准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本周认购面积, 0) AS 本周准产成品认购面积 ,
				ISNULL(rs.本周准产成品认购套数, 0) + ISNULL(rg.本周准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本周认购套数, 0) AS 本周准产成品认购套数 ,

				ISNULL(rs.本月准产成品认购金额, 0) + ISNULL(rg.本月准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本月认购金额, 0) AS 本月准产成品认购金额 ,
                ISNULL(rs.本月准产成品认购面积, 0) + ISNULL(rg.本月准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本月认购面积, 0) AS 本月准产成品认购面积 ,
				ISNULL(rs.本月准产成品认购套数, 0) + ISNULL(rg.本月准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本月认购套数, 0) AS 本月准产成品认购套数 ,

				ISNULL(qt.其他业绩准产成品本月认购金额, 0) AS 其他业绩准产成品本月认购金额 ,
                ISNULL(qt.其他业绩准产成品本月认购面积, 0) AS 其他业绩准产成品本月认购面积 ,
				ISNULL(qt.其他业绩准产成品本月认购套数, 0) AS 其他业绩准产成品本月认购套数 ,

				ISNULL(本月准产成品签约金额全口径, 0) AS 本月准产成品签约金额 ,
                ISNULL(本月准产成品签约面积全口径, 0) AS 本月准产成品签约面积 ,
				ISNULL(本月准产成品签约套数全口径, 0) AS 本月准产成品签约套数 ,

				ISNULL(qt.其他业绩准产成品本月签约金额, 0) AS 其他业绩准产成品本月签约金额 ,
                ISNULL(qt.其他业绩准产成品本月签约面积, 0) AS 其他业绩准产成品本月签约面积 ,
				ISNULL(qt.其他业绩准产成品本月签约套数, 0) AS 其他业绩准产成品本月签约套数 ,

				ISNULL(rs.累计准产成品已认购未签约金额, 0) AS 累计准产成品已认购未签约金额 ,
                ISNULL(rs.累计准产成品已认购未签约面积, 0) AS 累计准产成品已认购未签约面积 ,
				ISNULL(rs.累计准产成品已认购未签约套数, 0) AS 累计准产成品已认购未签约套数 ,

				ISNULL(rs.本年准产成品认购金额, 0) + ISNULL(rg.本年准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本年认购金额, 0) AS 本年准产成品认购金额 ,
                ISNULL(rs.本年准产成品认购面积, 0) + ISNULL(rg.本年准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本年认购面积, 0) AS 本年准产成品认购面积 ,
				ISNULL(rs.本年准产成品认购套数, 0) + ISNULL(rg.本年准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本年认购套数, 0) AS 本年准产成品认购套数 ,

				ISNULL(s.本年准产成品签约金额全口径, 0) AS 本年准产成品签约金额 ,
                ISNULL(s.本年准产成品签约面积全口径, 0) AS 本年准产成品签约面积 ,
				ISNULL(s.本年准产成品签约套数全口径, 0) AS 本年准产成品签约套数 ,

				ISNULL(qt.其他业绩准产成品本年签约金额, 0) AS 其他业绩准产成品本年签约金额 ,
                ISNULL(qt.其他业绩准产成品本年签约面积, 0) AS 其他业绩准产成品本年签约面积 ,                
				ISNULL(qt.其他业绩准产成品本年签约套数, 0) AS 其他业绩准产成品本年签约套数 ,

                --补充现产成品任务和大户型任务@20250630
                ISNULL(rw.准产成品月度任务, 0) AS 准产成品月度任务,
                ISNULL(rw.准产成品年度任务, 0) AS 准产成品年度任务,
                ISNULL(rw.大户型月度任务, 0)   AS 大户型月度任务,
                ISNULL(rw.大户型年度任务, 0)   AS 大户型年度任务

		FROM    data_wide_dws_mdm_Project p
				INNER JOIN #TopProduct pt ON pt.ParentProjGUID = p.ProjGUID
				LEFT JOIN data_tb_hnyx_jdfxtb rw ON rw.projguid = p.ProjGUID AND   rw.业态 = pt.TopProductTypeName
				LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
				LEFT JOIN #projsale s ON p.ProjGUID = s.orgguid AND pt.TopProductTypeName = s.TopProductTypeName
                LEFT JOIN #projsale_ldf_dhx dhx on p.ProjGUID = dhx.orgguid AND pt.TopProductTypeName = dhx.TopProductTypeName
				LEFT JOIN #rsale rs ON rs.ProjGUID = p.ProjGUID AND pt.TopProductTypeName = rs.TopProductTypeName
				LEFT JOIN #rg rg ON rg.ProjGUID = p.ProjGUID AND   pt.TopProductTypeName = rg.TopProductTypeName
				LEFT JOIN #qtqy qt ON qt.projguid = p.projguid AND pt.TopProductTypeName = qt.TopProductTypeName
		WHERE   Level = 2 AND   p.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
        UNION ALL
        -- 区域层级的平衡处理
		SELECT  @DateText AS 数据清洗日期 ,
                '营销大区' AS 层级 ,
                p.BUGUID AS 公司GUID ,
                tb.营销事业部 AS 区域 ,
                tb.营销片区 ,
                p.ProjGUID AS 项目GUID ,
                ISNULL(tb.推广名称, p.SpreadName) AS 项目名称 ,
                '全部区域' AS 层级名称 ,
                '平衡处理' AS 层级名称显示 ,
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END AS 项目名称负责人 ,
                CASE WHEN pt.TopProductTypeName IN ('高级住宅', '住宅', '别墅') THEN '住宅' 
				     WHEN pt.TopProductTypeName IN ('地下室/车库') THEN '车位' 
					 WHEN pt.TopProductTypeName IN ('商业','公寓','写字楼','酒店','会所','企业会所') THEN  '商办'
					 ELSE '其他' END AS 业态 ,
                pt.TopProductTypeName AS 产品类型 ,
                pt.TopProductTypeGUID AS 产品类型GUID ,
                tb.城市 ,
                tb.公司 ,
                tb.投管编码 ,
                tb.项目负责人 ,
                p.BeginDate AS 项目获取日期 ,
				--pt.FactFinishDate AS  实际竣备日期,
				--CASE WHEN  YEAR(pt.FactFinishDate)  < YEAR(@var_date) THEN  '是' ELSE  '否' END  AS 是否产成品,
                pt.存量增量 ,
                0 AS 本日认购金额 ,                          -- 全口径
                0 AS 本日认购套数 ,
                0 AS 本日签约金额 ,
                0 AS 本日签约套数 ,
                0 AS 本周认购金额 ,
                0 AS 本周认购套数 ,
                0 AS 本月任务 ,
                - ISNULL(rw.非项目本月实际认购金额,0 )  AS 本月认购金额 ,
                0 AS 本月认购套数 ,
				0 AS 其他业绩本月认购金额,
				0 AS 其他业绩本月认购套数,
                0 AS 本月认购完成率 ,
                - ISNULL(rw.非项目本月实际签约金额,0 )  AS 本月签约金额 ,
                0  AS 本月签约套数 ,
                0 AS 其他业绩本月签约金额 ,                                                                    --以客户提供其他业绩认定的房间
                0 AS 其他业绩本月签约套数 ,
                0 AS 本月签约完成率 ,
                0 AS 本月签约完成率_含其他业绩 ,
                0 AS 本月认购金额缺口 ,  --本月任务*本月时间进度分摊比-本月认购金额
                0 AS 本月签约金额缺口 ,
                0 AS 本月时间分摊比 ,
                0 AS 已认购未签约金额 ,
                0 AS 已认购未签约套数 ,
                0 AS 本年任务 ,
                - ISNULL(rw.非项目本年实际认购金额,0 ) AS 本年认购金额 ,
                0 AS 本年认购套数 ,
                - ISNULL(rw.非项目本年实际签约金额,0 ) AS 本年签约金额 ,
                0 AS 本年签约套数 ,
                0 AS 其他业绩本年签约金额 ,
                0 AS 其他业绩本年签约套数 ,
                0 AS 本年签约完成率 ,
                0 AS 本年签约完成率_含其他业绩 ,
                0 AS 本年认购金额缺口 ,
                0 AS 本年签约金额缺口 ,
                0 AS 本年时间分摊比 ,
                0 AS 本年存量任务 ,
                0 AS 本年增量任务 ,
                0 AS 本年新增量任务 ,
                0 AS 本月存量任务 ,
                0 AS 本月增量任务 ,
                0 本月新增量任务,
				-- 产成品
                0 AS 本日产成品认购金额 ,  
                0 AS 本日产成品认购套数 ,
                0 AS 本日产成品签约金额 ,
                0 AS 本日产成品签约套数 ,
                0 AS 本周产成品认购金额 ,
                0 AS 本周产成品认购套数 ,
                0 AS 本月产成品任务 ,
                0 AS 本月产成品认购金额 ,
                0 AS 本月产成品认购套数 ,
				0 AS 其他业绩产成品本月认购金额,
				0 AS 其他业绩产成品本月认购套数,
                0 AS 本月产成品认购完成率 ,
                0 AS 本月产成品签约金额 ,
                0 AS 本月产成品签约套数,
				0 AS 其他业绩产成品本月签约金额 ,                                                                   
                0 AS 其他业绩产成品本月签约套数 ,
                0 AS 本月产成品签约完成率 ,
                0 AS 本月产成品签约完成率_含其他业绩 ,
				0 AS 累计产成品已认购未签约金额 ,
                0 AS 累计产成品已认购未签约套数 ,

				0 AS  本年产成品任务,
                0 AS 本年产成品认购金额 ,
                0 AS 本年产成品认购套数 ,
                0 AS 本年产成品签约金额 ,
                0 AS 本年产成品签约套数 ,
                0 AS 其他业绩产成品本年签约金额 ,
                0 AS 其他业绩产成品本年签约套数 ,
                0 AS 本年产成品签约完成率 ,
                0 AS 本年产成品签约完成率_含其他业绩 , 
				0 as 非项目本年实际签约金额,
				0 as 非项目本月实际签约金额,
				0 as 非项目本年实际认购金额,
				0 as 非项目本月实际认购金额,

				-- 20240604 chenjw 新增面积类字段
				0 AS 本日认购面积 ,
				0 AS 本日签约面积 ,
				0 AS 本周认购面积 ,
				0 AS 本周签约套数 ,
				0 AS 本周签约面积 ,
				0 AS 本周签约金额 ,
				0 AS 本月认购面积 ,
				0 AS 本月签约面积 ,
				0 AS 其他业绩本月认购面积 ,
				0 AS 其他业绩本月签约面积 ,
				0 AS 本月产成品认购面积 ,
				0 AS 本月产成品签约面积 ,
				0 AS 其他业绩产成品本月签约面积 ,
				0 AS 已认购未签约签约面积 ,
				0 AS 本年认购面积 ,
				0 AS 本年签约面积 ,
				0 AS 其他业绩本年认购套数 ,
				0 AS 其他业绩本年认购面积 ,
				0 AS 其他业绩本年认购金额 ,
				0 AS 其他业绩本年签约面积 ,
				0 AS 本年产成品认购面积 ,
				0 AS 本年产成品签约面积 ,
				0 AS 其他业绩产成品本年签约面积,
                @wideTableDateText  as 宽表最后清洗日期,
                --大户型
                0 as 本日大户型认购金额,
                0 as 本日大户型认购面积,
                0 as 本日大户型认购套数,
                0 as 本日大户型签约金额,
                0 as 本日大户型签约面积,
                0 as 本日大户型签约套数,

                0 as 本周大户型认购金额,
                0 as 本周大户型认购面积,
                0 as 本周大户型认购套数,
                0 as 本周大户型签约金额,
                0 as 本周大户型签约面积,
                0 as 本周大户型签约套数,

                0 as 本月大户型认购金额,
                0 as 本月大户型认购面积,
                0 as 本月大户型认购套数,
                0 as 本月大户型签约金额,
                0 as 本月大户型签约面积,
                0 as 本月大户型签约套数,

                0 as 本年大户型认购金额,
                0 as 本年大户型认购面积,
                0 as 本年大户型认购套数,
                0 as 本年大户型签约金额,
                0 as 本年大户型签约面积,
                0 as 本年大户型签约套数,

                0 as 累计大户型已认购未签约金额,
                0 as 累计大户型已认购未签约面积,
                0 as 累计大户型已认购未签约套数,
                0 as 本年大户型已认购未签约金额,
                0 as 本年大户型已认购未签约套数,
                0 as 本月大户型已认购未签约金额,
                0 as 本月大户型已认购未签约套数,

                --联动房
                0 as 本日联动房认购金额,
                0 as 本日联动房认购面积,
                0 as 本日联动房认购套数,
                0 as 本日联动房签约金额,
                0 as 本日联动房签约面积,
                0 as 本日联动房签约套数,

                0 as 本周联动房认购金额,
                0 as 本周联动房认购面积,
                0 as 本周联动房认购套数,
                0 as 本周联动房签约金额,
                0 as 本周联动房签约面积,
                0 as 本周联动房签约套数,

                0 as 本月联动房认购金额,
                0 as 本月联动房认购面积,
                0 as 本月联动房认购套数,
                0 as 本月联动房签约金额,
                0 as 本月联动房签约面积,
                0 as 本月联动房签约套数,

                0 as 本年联动房认购金额,
                0 as 本年联动房认购面积,
                0 as 本年联动房认购套数,
                0 as 本年联动房签约金额,
                0 as 本年联动房签约面积,
                0 as 本年联动房签约套数,

                0 AS 累计联动房已认购未签约金额,
                0 AS 累计联动房已认购未签约面积,
                0 AS 累计联动房已认购未签约套数,
                0 AS 本年联动房已认购未签约金额,
                0 AS 本年联动房已认购未签约套数,
                0 AS 本月联动房已认购未签约金额,
                0 AS 本月联动房已认购未签约套数,

                0 as 其他业绩大户型本月签约金额,
                0 as 其他业绩大户型本月签约面积,
                0 as 其他业绩大户型本月签约套数,
                0 as 其他业绩大户型本年签约金额,
                0 as 其他业绩大户型本年签约面积,
                0 as 其他业绩大户型本年签约套数,

                --准产成品
                0 AS 本日准产成品认购金额,
                0 AS 本日准产成品认购面积,
                0 AS 本日准产成品认购套数,

                0 AS 本日准产成品签约金额 ,
                0 AS 本日准产成品签约面积 ,
                0 AS 本日准产成品签约套数 ,

                0 AS 本周准产成品认购金额 ,
                0 AS 本周准产成品认购面积 ,
                0 AS 本周准产成品认购套数 ,

                0 AS 本月准产成品认购金额 ,
                0 AS 本月准产成品认购面积 ,
                0 AS 本月准产成品认购套数 ,

                0 AS 其他业绩准产成品本月认购金额 ,
                0 AS 其他业绩准产成品本月认购面积 ,
                0 AS 其他业绩准产成品本月认购套数 ,

                0 AS 本月准产成品签约金额 ,
                0 AS 本月准产成品签约面积 ,
                0 AS 本月准产成品签约套数 ,

                0 AS 其他业绩准产成品本月签约金额 ,
                0 AS 其他业绩准产成品本月签约面积 ,
                0 AS 其他业绩准产成品本月签约套数 ,

                0 AS 累计准产成品已认购未签约金额 ,
                0 AS 累计准产成品已认购未签约面积 ,
                0 AS 累计准产成品已认购未签约套数 ,

                0 AS 本年准产成品认购金额 ,
                0 AS 本年准产成品认购面积 ,
                0 AS 本年准产成品认购套数 ,

                0 AS 本年准产成品签约金额 ,
                0 AS 本年准产成品签约面积 ,
                0 AS 本年准产成品签约套数 ,
                0 AS 其他业绩准产成品本年签约金额 ,
                0 AS 其他业绩准产成品本年签约面积 ,                
                0 AS 其他业绩准产成品本年签约套数 ,

                --补充现产成品任务和大户型任务@20250630
                0 AS 准产成品月度任务,
                0 AS 准产成品年度任务,
                0 AS 大户型月度任务,
                0 AS 大户型年度任务
        FROM    data_wide_dws_mdm_Project p
                INNER JOIN #TopProduct pt ON pt.ParentProjGUID = p.ProjGUID
                LEFT JOIN data_tb_hnyx_jdfxtb rw ON rw.projguid = p.ProjGUID AND   rw.业态 = pt.TopProductTypeName
                LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
                LEFT JOIN #projsale s ON p.ProjGUID = s.orgguid AND pt.TopProductTypeName = s.TopProductTypeName
                LEFT JOIN #projsale_ldf_dhx dhx on p.ProjGUID = dhx.orgguid AND pt.TopProductTypeName = dhx.TopProductTypeName
                LEFT JOIN #rsale rs ON rs.ProjGUID = p.ProjGUID AND pt.TopProductTypeName = rs.TopProductTypeName
                LEFT JOIN #rg rg ON rg.ProjGUID = p.ProjGUID AND   pt.TopProductTypeName = rg.TopProductTypeName
                LEFT JOIN #qtqy qt ON qt.projguid = p.projguid AND pt.TopProductTypeName = qt.TopProductTypeName
        WHERE   Level = 2 AND   p.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
	    UNION ALL
        -- 区域层级-各区域名称
        SELECT  @DateText AS 数据清洗日期 ,
                '营销大区' AS 层级 ,
                p.BUGUID AS 公司GUID ,
                tb.营销事业部 AS 区域 ,
                tb.营销片区 ,
                p.ProjGUID AS 项目GUID ,
                ISNULL(tb.推广名称, p.SpreadName) AS 项目名称 ,
                tb.营销事业部 AS 层级名称 ,
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END AS 层级名称显示 ,    --显示项目名称
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END AS 项目名称负责人 ,
                CASE WHEN pt.TopProductTypeName IN ('高级住宅', '住宅', '别墅') THEN '住宅' 
				     WHEN pt.TopProductTypeName IN ('地下室/车库') THEN '车位' 
					 WHEN pt.TopProductTypeName IN ('商业','公寓','写字楼','酒店','会所','企业会所') THEN  '商办'
					 ELSE '其他' END AS 业态 ,
                pt.TopProductTypeName AS 产品类型 ,
                pt.TopProductTypeGUID AS 产品类型GUID ,
                tb.城市 ,
                tb.公司 ,
                tb.投管编码 ,
                tb.项目负责人 ,
                p.BeginDate AS 项目获取日期 ,
                pt.存量增量 ,
                ISNULL(rs.本日认购金额, 0) + ISNULL(rg.本日认购金额, 0) + ISNULL(qt.其他业绩本日认购金额, 0) AS 本日认购金额 ,                                                                              -- 全口径
                ISNULL(rs.本日认购套数, 0) + ISNULL(rg.本日认购套数, 0) + ISNULL(qt.其他业绩本日认购套数, 0) AS 本日认购套数 ,
                ISNULL(s.本日签约金额全口径, 0) AS 本日签约金额 ,
                ISNULL(s.本日签约套数全口径, 0) AS 本日签约套数 ,
                ISNULL(rs.本周认购金额, 0) + ISNULL(rg.本周认购金额, 0) + ISNULL(qt.其他业绩本周认购金额, 0) AS 本周认购金额 ,
                ISNULL(rs.本周认购套数, 0) + ISNULL(rg.本周认购套数, 0) + ISNULL(qt.其他业绩本周认购套数, 0) AS 本周认购套数 ,
                rw.月度签约任务 AS 本月任务 ,
                ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0) + ISNULL(qt.其他业绩本月认购金额, 0) + ISNULL(rw.非项目本月实际认购金额,0)  AS 本月认购金额 ,
                ISNULL(rs.本月认购套数, 0) + ISNULL(rg.本月认购套数, 0) + ISNULL(qt.其他业绩本月认购套数, 0) AS 本月认购套数 ,
				ISNULL(qt.其他业绩本月认购金额, 0) AS 其他业绩本月认购金额,
				ISNULL(qt.其他业绩本月认购套数, 0) AS 其他业绩本月认购套数,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE (ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0)+ ISNULL(qt.其他业绩本月认购金额,0) + ISNULL(rw.非项目本月实际认购金额,0)) / ISNULL(rw.月度签约任务, 0)END AS 本月认购完成率 ,
                ISNULL(本月签约金额全口径, 0) + ISNULL(rw.非项目本月实际签约金额,0) AS 本月签约金额 ,
                ISNULL(本月签约套数全口径, 0) AS 本月签约套数 ,
                ISNULL(qt.其他业绩本月签约金额, 0) AS 其他业绩本月签约金额 ,                                                                    --以客户提供其他业绩认定的房间
                ISNULL(qt.其他业绩本月签约套数, 0) AS 其他业绩本月签约套数 ,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(本月签约金额全口径, 0) +ISNULL(rw.非项目本月实际签约金额,0) ) / ISNULL(rw.月度签约任务, 0)END AS 本月签约完成率 ,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE (ISNULL(本月签约金额全口径, 0) + ISNULL(qt.其他业绩本月签约金额, 0) +  ISNULL(rw.非项目本月实际签约金额,0) ) / ISNULL(rw.月度签约任务, 0)END AS 本月签约完成率_含其他业绩 ,
                ISNULL(rw.月度签约任务, 0)  - (ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0) + ISNULL(rw.非项目本月实际认购金额,0) )  AS 本月认购金额缺口 ,  --本月任务*本月时间进度分摊比-本月认购金额
                ISNULL(rw.月度签约任务, 0)  - (ISNULL(本月签约金额全口径, 0) + ISNULL(rw.非项目本月实际签约金额,0) ) AS 本月签约金额缺口 ,
                ISNULL(pt.本月时间分摊比, 0) AS 本月时间分摊比 ,
                ISNULL(rs.累计已认购未签约金额, 0) AS 已认购未签约金额 ,
                ISNULL(rs.累计已认购未签约套数, 0) AS 已认购未签约套数 ,
                ISNULL(rw.年度签约任务, 0) AS 本年任务 ,
                ISNULL(rs.本年认购金额, 0) + ISNULL(rg.本年认购金额, 0) + ISNULL(qt.其他业绩本年认购金额, 0) + ISNULL(rw.非项目本年实际认购金额,0) AS 本年认购金额 ,
                ISNULL(rs.本年认购套数, 0) + ISNULL(rg.本年认购套数, 0) + ISNULL(qt.其他业绩本年认购套数, 0) AS 本年认购套数 ,
                ISNULL(s.本年签约金额全口径, 0) + ISNULL(rw.非项目本年实际签约金额,0) AS 本年签约金额 ,
                ISNULL(s.本年签约套数全口径, 0) AS 本年签约套数 ,
                ISNULL(qt.其他业绩本年签约金额, 0) AS 其他业绩本年签约金额 ,
                ISNULL(qt.其他业绩本年签约套数, 0) AS 其他业绩本年签约套数 ,
                CASE WHEN ISNULL(rw.年度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(s.本年签约金额全口径, 0) +ISNULL(rw.非项目本年实际签约金额,0) )  / ISNULL(rw.年度签约任务, 0)END AS 本年签约完成率 ,
                CASE WHEN ISNULL(rw.年度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(s.本年签约金额全口径, 0) + ISNULL(qt.其他业绩本年签约金额, 0) +ISNULL(rw.非项目本年实际签约金额,0) ) / ISNULL(rw.年度签约任务, 0)END AS 本年签约完成率_含其他业绩 ,
                ISNULL(rw.年度签约任务, 0)  - (ISNULL(rs.本年认购金额, 0) + ISNULL(rg.本年认购金额, 0) +ISNULL(rw.非项目本年实际认购金额,0)) AS 本年认购金额缺口 ,
                ISNULL(rw.年度签约任务, 0)  - (ISNULL(本年签约金额全口径, 0) +ISNULL(rw.非项目本年实际签约金额,0) ) AS 本年签约金额缺口 ,
                ISNULL(pt.本年时间分摊比, 0) AS 本年时间分摊比 ,
                ISNULL(rw.本年存量任务, 0) AS 本年存量任务 ,
                ISNULL(rw.本年增量任务, 0) AS 本年增量任务 ,
                ISNULL(rw.本年新增量任务, 0) AS 本年新增量任务 ,
                ISNULL(rw.本月存量任务, 0) AS 本月存量任务 ,
                ISNULL(rw.本月增量任务, 0) AS 本月增量任务 ,
                ISNULL(rw.本月新增量任务, 0) AS 本月新增量任务,
				-- 产成品
                ISNULL(rs.本日产成品认购金额, 0) + ISNULL(rg.本日产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本日认购金额, 0) AS 本日产成品认购金额 ,  
                ISNULL(rs.本日产成品认购套数, 0) + ISNULL(rg.本日产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本日认购套数, 0) AS 本日产成品认购套数 ,
                ISNULL(s.本日产成品签约金额全口径, 0) AS 本日产成品签约金额 ,
                ISNULL(s.本日产成品签约套数全口径, 0) AS 本日产成品签约套数 ,
                ISNULL(rs.本周产成品认购金额, 0) + ISNULL(rg.本周产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本周认购金额, 0) AS 本周产成品认购金额 ,
                ISNULL(rs.本周产成品认购套数, 0) + ISNULL(rg.本周产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本周认购套数, 0) AS 本周产成品认购套数 ,
                rw.产成品月度任务 AS 本月产成品任务 ,
                ISNULL(rs.本月产成品认购金额, 0) + ISNULL(rg.本月产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本月认购金额, 0) AS 本月产成品认购金额 ,
                ISNULL(rs.本月产成品认购套数, 0) + ISNULL(rg.本月产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本月认购套数, 0) AS 本月产成品认购套数 ,
				ISNULL(qt.其他业绩产成品本月认购金额, 0) AS 其他业绩产成品本月认购金额,
				ISNULL(qt.其他业绩产成品本月认购套数, 0) AS 其他业绩产成品本月认购套数,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE (ISNULL(rs.本月产成品认购金额, 0) + ISNULL(rg.本月产成品认购金额, 0)+ ISNULL(qt.其他业绩产成品本月认购金额,0)) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品认购完成率 ,
                ISNULL(本月产成品签约金额全口径, 0) AS 本月产成品签约金额 ,
                ISNULL(本月产成品签约套数全口径, 0) AS 本月产成品签约套数,
				ISNULL(qt.其他业绩产成品本月签约金额, 0) AS 其他业绩产成品本月签约金额 ,                                                                   
                ISNULL(qt.其他业绩产成品本月签约套数, 0) AS 其他业绩产成品本月签约套数 ,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE ISNULL(本月产成品签约金额全口径, 0) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品签约完成率 ,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE (ISNULL(本月产成品签约金额全口径, 0) + ISNULL(qt.其他业绩产成品本月签约金额, 0)) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品签约完成率_含其他业绩 ,
				ISNULL(rs.累计产成品已认购未签约金额, 0) AS 累计产成品已认购未签约金额 ,
                ISNULL(rs.累计产成品已认购未签约套数, 0) AS 累计产成品已认购未签约套数 ,

				ISNULL(rw.产成品年度任务,0)  AS  本年产成品任务,
                ISNULL(rs.本年产成品认购金额, 0) + ISNULL(rg.本年产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本年认购金额, 0) AS 本年产成品认购金额 ,
                ISNULL(rs.本年产成品认购套数, 0) + ISNULL(rg.本年产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本年认购套数, 0) AS 本年产成品认购套数 ,
                ISNULL(s.本年产成品签约金额全口径, 0) AS 本年产成品签约金额 ,
                ISNULL(s.本年产成品签约套数全口径, 0) AS 本年产成品签约套数 ,
                ISNULL(qt.其他业绩产成品本年签约金额, 0) AS 其他业绩产成品本年签约金额 ,
                ISNULL(qt.其他业绩产成品本年签约套数, 0) AS 其他业绩产成品本年签约套数 ,
                CASE WHEN ISNULL(rw.产成品年度任务, 0) = 0 THEN 0 ELSE ISNULL(s.本年产成品签约金额全口径, 0) / ISNULL(rw.产成品年度任务, 0)END AS 本年产成品签约完成率 ,
                CASE WHEN ISNULL(rw.产成品年度任务, 0) = 0 THEN 0 ELSE (ISNULL(s.本年产成品签约金额全口径, 0) + ISNULL(qt.其他业绩产成品本年签约金额, 0)) / ISNULL(rw.产成品年度任务, 0)END AS 本年产成品签约完成率_含其他业绩 , 
				ISNULL(rw.非项目本年实际签约金额,0 ) AS 非项目本年实际签约金额,
				ISNULL(rw.非项目本月实际签约金额,0 ) AS 非项目本月实际签约金额,
				ISNULL(rw.非项目本年实际认购金额,0 ) AS 非项目本年实际认购金额,
				ISNULL(rw.非项目本月实际认购金额,0 ) AS 非项目本月实际认购金额,
				-- 20240604 chenjw 新增面积类字段
				0 AS 本日认购面积 ,
				0 AS 本日签约面积 ,
				0 AS 本周认购面积 ,
				0 AS 本周签约套数 ,
				0 AS 本周签约面积 ,
				0 AS 本周签约金额 ,
				0 AS 本月认购面积 ,
				0 AS 本月签约面积 ,
				0 AS 其他业绩本月认购面积 ,
				0 AS 其他业绩本月签约面积 ,
				0 AS 本月产成品认购面积 ,
				0 AS 本月产成品签约面积 ,
				0 AS 其他业绩产成品本月签约面积 ,
				0 AS 已认购未签约签约面积 ,
				0 AS 本年认购面积 ,
				0 AS 本年签约面积 ,
				0 AS 其他业绩本年认购套数 ,
				0 AS 其他业绩本年认购面积 ,
				0 AS 其他业绩本年认购金额 ,
				0 AS 其他业绩本年签约面积 ,
				0 AS 本年产成品认购面积 ,
				0 AS 本年产成品签约面积 ,
				0 AS 其他业绩产成品本年签约面积,
                @wideTableDateText  as 宽表最后清洗日期,
                --大户型
                ISNULL(rs.本日大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本日认购金额, 0) as 本日大户型认购金额,
                ISNULL(rs.本日大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本日认购面积, 0)  as 本日大户型认购面积,
                ISNULL(rs.本日大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本日认购套数, 0)  as 本日大户型认购套数,
                ISNULL(dhx.本日大户型签约金额全口径, 0)   as 本日大户型签约金额,
                ISNULL(dhx.本日大户型签约面积全口径, 0)  as 本日大户型签约面积,
                ISNULL(dhx.本日大户型签约套数全口径, 0)  as 本日大户型签约套数,

                ISNULL(rs.本周大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本周认购金额, 0) as 本周大户型认购金额,
                ISNULL(rs.本周大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本周认购面积, 0) as 本周大户型认购面积,
                ISNULL(rs.本周大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本周认购套数, 0) as 本周大户型认购套数,
                ISNULL(dhx.本周大户型签约金额全口径, 0) as 本周大户型签约金额,
                ISNULL(dhx.本周大户型签约面积全口径, 0) as 本周大户型签约面积,
                ISNULL(dhx.本周大户型签约套数全口径, 0) as 本周大户型签约套数,

                ISNULL(rs.本月大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本月认购金额, 0) as 本月大户型认购金额,
                ISNULL(rs.本月大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本月认购面积, 0) as 本月大户型认购面积,
                ISNULL(rs.本月大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本月认购套数, 0) as 本月大户型认购套数,
                ISNULL(dhx.本月大户型签约金额全口径,0) + ISNULL(qt.其他业绩大户型本月签约金额,0) as 本月大户型签约金额,
                ISNULL(dhx.本月大户型签约面积全口径,0) + ISNULL(qt.其他业绩大户型本月签约面积,0) as 本月大户型签约面积,
                ISNULL(dhx.本月大户型签约套数全口径,0) + ISNULL(qt.其他业绩大户型本月签约套数,0) as 本月大户型签约套数,

                ISNULL(rs.本年大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本年认购金额, 0) as 本年大户型认购金额,
                ISNULL(rs.本年大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本年认购面积, 0) as 本年大户型认购面积,
                ISNULL(rs.本年大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本年认购套数, 0) as 本年大户型认购套数,
                ISNULL(dhx.本年大户型签约金额全口径,0) + ISNULL(qt.其他业绩大户型本年签约金额,0) as 本年大户型签约金额,
                ISNULL(dhx.本年大户型签约面积全口径,0) + ISNULL(qt.其他业绩大户型本年签约面积,0) as 本年大户型签约面积,
                ISNULL(dhx.本年大户型签约套数全口径,0) + ISNULL(qt.其他业绩大户型本年签约套数,0) as 本年大户型签约套数,

                ISNULL(rs.累计大户型已认购未签约金额,0) as 累计大户型已认购未签约金额,
                ISNULL(rs.累计大户型已认购未签约面积,0) as 累计大户型已认购未签约面积,
                ISNULL(rs.累计大户型已认购未签约套数,0) as 累计大户型已认购未签约套数,
                ISNULL(rs.本年大户型已认购未签约金额,0) as 本年大户型已认购未签约金额,
                ISNULL(rs.本年大户型已认购未签约套数,0) as 本年大户型已认购未签约套数,
                ISNULL(rs.本月大户型已认购未签约金额,0) as 本月大户型已认购未签约金额,
                ISNULL(rs.本月大户型已认购未签约套数,0) as 本月大户型已认购未签约套数,

                --联动房
                ISNULL(rs.本日联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本日认购金额, 0) as 本日联动房认购金额,
                ISNULL(rs.本日联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本日认购面积, 0)  as 本日联动房认购面积,
                ISNULL(rs.本日联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本日认购套数, 0)  as 本日联动房认购套数,
                ISNULL(dhx.本日联动房签约金额全口径, 0)   as 本日联动房签约金额,
                ISNULL(dhx.本日联动房签约面积全口径, 0)  as 本日联动房签约面积,
                ISNULL(dhx.本日联动房签约套数全口径, 0)  as 本日联动房签约套数,

                ISNULL(rs.本周联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本周认购金额, 0) as 本周联动房认购金额,
                ISNULL(rs.本周联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本周认购面积, 0) as 本周联动房认购面积,
                ISNULL(rs.本周联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本周认购套数, 0) as 本周联动房认购套数,
                ISNULL(dhx.本周联动房签约金额全口径, 0) as 本周联动房签约金额,
                ISNULL(dhx.本周联动房签约面积全口径, 0) as 本周联动房签约面积,
                ISNULL(dhx.本周联动房签约套数全口径, 0) as 本周联动房签约套数,

                ISNULL(rs.本月联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本月认购金额, 0) as 本月联动房认购金额,
                ISNULL(rs.本月联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本月认购面积, 0) as 本月联动房认购面积,
                ISNULL(rs.本月联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本月认购套数, 0) as 本月联动房认购套数,
                ISNULL(dhx.本月联动房签约金额全口径,0) + ISNULL(qt.其他业绩联动房本月签约金额,0) as 本月联动房签约金额,
                ISNULL(dhx.本月联动房签约面积全口径,0) + ISNULL(qt.其他业绩联动房本月签约面积,0) as 本月联动房签约面积,
                ISNULL(dhx.本月联动房签约套数全口径,0) + ISNULL(qt.其他业绩联动房本月签约套数,0) as 本月联动房签约套数,

                ISNULL(rs.本年联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本年认购金额, 0) as 本年联动房认购金额,
                ISNULL(rs.本年联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本年认购面积, 0) as 本年联动房认购面积,
                ISNULL(rs.本年联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本年认购套数, 0) as 本年联动房认购套数,
                ISNULL(dhx.本年联动房签约金额全口径,0) + ISNULL(qt.其他业绩联动房本年签约金额,0) as 本年联动房签约金额,
                ISNULL(dhx.本年联动房签约面积全口径,0) + ISNULL(qt.其他业绩联动房本年签约面积,0) as 本年联动房签约面积,
                ISNULL(dhx.本年联动房签约套数全口径,0) + ISNULL(qt.其他业绩联动房本年签约套数,0) as 本年联动房签约套数,

                ISNULL(rs.累计联动房已认购未签约金额,0) AS 累计联动房已认购未签约金额,
                ISNULL(rs.累计联动房已认购未签约面积,0) AS 累计联动房已认购未签约面积,
                ISNULL(rs.累计联动房已认购未签约套数,0) AS 累计联动房已认购未签约套数,
                ISNULL(rs.本年联动房已认购未签约金额,0) AS 本年联动房已认购未签约金额,
                ISNULL(rs.本年联动房已认购未签约套数,0) AS 本年联动房已认购未签约套数,
                ISNULL(rs.本月联动房已认购未签约金额,0) AS 本月联动房已认购未签约金额,
                ISNULL(rs.本月联动房已认购未签约套数,0) AS 本月联动房已认购未签约套数,

                ISNULL(qt.其他业绩大户型本月签约金额,0) as 其他业绩大户型本月签约金额,
                ISNULL(qt.其他业绩大户型本月签约面积,0) as 其他业绩大户型本月签约面积,
                ISNULL(qt.其他业绩大户型本月签约套数,0) as 其他业绩大户型本月签约套数,
                ISNULL(qt.其他业绩大户型本年签约金额,0) as 其他业绩大户型本年签约金额,
                ISNULL(qt.其他业绩大户型本年签约面积,0) as 其他业绩大户型本年签约面积,
                ISNULL(qt.其他业绩大户型本年签约套数,0) as 其他业绩大户型本年签约套数,

                --准产成品
                ISNULL(rs.本日准产成品认购金额, 0) + ISNULL(rg.本日准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本日认购金额, 0) AS 本日准产成品认购金额,
                ISNULL(rs.本日准产成品认购面积, 0) + ISNULL(rg.本日准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本日认购面积, 0) AS 本日准产成品认购面积,
                ISNULL(rs.本日准产成品认购套数, 0) + ISNULL(rg.本日准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本日认购套数, 0) AS 本日准产成品认购套数 ,

                ISNULL(s.本日准产成品签约金额全口径, 0) AS 本日准产成品签约金额 ,
                ISNULL(s.本日准产成品签约面积全口径, 0) AS 本日准产成品签约面积 ,
                ISNULL(s.本日准产成品签约套数全口径, 0) AS 本日准产成品签约套数 ,

                ISNULL(rs.本周准产成品认购金额, 0) + ISNULL(rg.本周准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本周认购金额, 0) AS 本周准产成品认购金额 ,
                ISNULL(rs.本周准产成品认购面积, 0) + ISNULL(rg.本周准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本周认购面积, 0) AS 本周准产成品认购面积 ,
                ISNULL(rs.本周准产成品认购套数, 0) + ISNULL(rg.本周准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本周认购套数, 0) AS 本周准产成品认购套数 ,

                ISNULL(rs.本月准产成品认购金额, 0) + ISNULL(rg.本月准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本月认购金额, 0) AS 本月准产成品认购金额 ,
                ISNULL(rs.本月准产成品认购面积, 0) + ISNULL(rg.本月准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本月认购面积, 0) AS 本月准产成品认购面积 ,
                ISNULL(rs.本月准产成品认购套数, 0) + ISNULL(rg.本月准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本月认购套数, 0) AS 本月准产成品认购套数 ,

                ISNULL(qt.其他业绩准产成品本月认购金额, 0) AS 其他业绩准产成品本月认购金额 ,
                ISNULL(qt.其他业绩准产成品本月认购面积, 0) AS 其他业绩准产成品本月认购面积 ,
                ISNULL(qt.其他业绩准产成品本月认购套数, 0) AS 其他业绩准产成品本月认购套数 ,

                ISNULL(本月准产成品签约金额全口径, 0) AS 本月准产成品签约金额 ,
                ISNULL(本月准产成品签约面积全口径, 0) AS 本月准产成品签约面积 ,
                ISNULL(本月准产成品签约套数全口径, 0) AS 本月准产成品签约套数 ,

                ISNULL(qt.其他业绩准产成品本月签约金额, 0) AS 其他业绩准产成品本月签约金额 ,
                ISNULL(qt.其他业绩准产成品本月签约面积, 0) AS 其他业绩准产成品本月签约面积 ,
                ISNULL(qt.其他业绩准产成品本月签约套数, 0) AS 其他业绩准产成品本月签约套数 ,

                ISNULL(rs.累计准产成品已认购未签约金额, 0) AS 累计准产成品已认购未签约金额 ,
                ISNULL(rs.累计准产成品已认购未签约面积, 0) AS 累计准产成品已认购未签约面积 ,
                ISNULL(rs.累计准产成品已认购未签约套数, 0) AS 累计准产成品已认购未签约套数 ,

                ISNULL(rs.本年准产成品认购金额, 0) + ISNULL(rg.本年准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本年认购金额, 0) AS 本年准产成品认购金额 ,
                ISNULL(rs.本年准产成品认购面积, 0) + ISNULL(rg.本年准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本年认购面积, 0) AS 本年准产成品认购面积 ,
                ISNULL(rs.本年准产成品认购套数, 0) + ISNULL(rg.本年准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本年认购套数, 0) AS 本年准产成品认购套数 ,

                ISNULL(s.本年准产成品签约金额全口径, 0) AS 本年准产成品签约金额 ,
                ISNULL(s.本年准产成品签约面积全口径, 0) AS 本年准产成品签约面积 ,
                ISNULL(s.本年准产成品签约套数全口径, 0) AS 本年准产成品签约套数 ,
                ISNULL(qt.其他业绩准产成品本年签约金额, 0) AS 其他业绩准产成品本年签约金额 ,
                ISNULL(qt.其他业绩准产成品本年签约面积, 0) AS 其他业绩准产成品本年签约面积 ,                
                ISNULL(qt.其他业绩准产成品本年签约套数, 0) AS 其他业绩准产成品本年签约套数 ,

                --补充现产成品任务和大户型任务@20250630
                ISNULL(rw.准产成品月度任务, 0) AS 准产成品月度任务,
                ISNULL(rw.准产成品年度任务, 0) AS 准产成品年度任务,
                ISNULL(rw.大户型月度任务, 0)   AS 大户型月度任务,
                ISNULL(rw.大户型年度任务, 0)   AS 大户型年度任务
        FROM    data_wide_dws_mdm_Project p
                INNER JOIN #TopProduct pt ON pt.ParentProjGUID = p.ProjGUID
                LEFT JOIN data_tb_hnyx_jdfxtb rw ON rw.projguid = p.ProjGUID AND   rw.业态 = pt.TopProductTypeName
                LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
                LEFT JOIN #projsale s ON p.ProjGUID = s.orgguid AND pt.TopProductTypeName = s.TopProductTypeName
                LEFT JOIN #projsale_ldf_dhx dhx on p.ProjGUID = dhx.orgguid AND pt.TopProductTypeName = dhx.TopProductTypeName
                LEFT JOIN #rsale rs ON rs.ProjGUID = p.ProjGUID AND pt.TopProductTypeName = rs.TopProductTypeName
                LEFT JOIN #rg rg ON rg.ProjGUID = p.ProjGUID AND   pt.TopProductTypeName = rg.TopProductTypeName
                LEFT JOIN #qtqy qt ON qt.projguid = p.projguid AND pt.TopProductTypeName = qt.TopProductTypeName
        WHERE   Level = 2 AND   p.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
        UNION ALL
        -- 组团层级-全部组团
        SELECT  @DateText AS 数据清洗日期 ,
                '组团' AS 层级 ,
                p.BUGUID AS 公司GUID ,
                tb.营销事业部 AS 区域 ,
                tb.营销片区 ,
                p.ProjGUID AS 项目GUID ,
                ISNULL(tb.推广名称, p.SpreadName) AS 项目名称 ,
                '全部组团' AS 层级名称 ,
                CASE WHEN ISNULL(组团负责人, '') <> '' THEN tb.营销片区 + '(' + ISNULL(组团负责人, '') + ')' ELSE tb.营销片区 END AS 层级名称显示 ,
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END AS 项目名称负责人 ,
                CASE WHEN pt.TopProductTypeName IN ('高级住宅', '住宅', '别墅') THEN '住宅' 
				     WHEN pt.TopProductTypeName IN ('地下室/车库') THEN '车位' 
					 WHEN pt.TopProductTypeName IN ('商业','公寓','写字楼','酒店','会所','企业会所') THEN  '商办'
					 ELSE '其他' END AS 业态 ,
                pt.TopProductTypeName AS 产品类型 ,
                pt.TopProductTypeGUID AS 产品类型GUID ,
                tb.城市 ,
                tb.公司 ,
                tb.投管编码 ,
                tb.项目负责人 ,
                p.BeginDate AS 项目获取日期 ,
                pt.存量增量 ,
                ISNULL(rs.本日认购金额, 0) + ISNULL(rg.本日认购金额, 0) + ISNULL(qt.其他业绩本日认购金额, 0) AS 本日认购金额 ,                          -- 全口径
                ISNULL(rs.本日认购套数, 0) + ISNULL(rg.本日认购套数, 0) + ISNULL(qt.其他业绩本日认购套数, 0) AS 本日认购套数 ,
                ISNULL(s.本日签约金额全口径, 0) AS 本日签约金额 ,
                ISNULL(s.本日签约套数全口径, 0) AS 本日签约套数 ,
                ISNULL(rs.本周认购金额, 0) + ISNULL(rg.本周认购金额, 0) + ISNULL(qt.其他业绩本周认购金额, 0) AS 本周认购金额 ,
                ISNULL(rs.本周认购套数, 0) + ISNULL(rg.本周认购套数, 0) + ISNULL(qt.其他业绩本周认购套数, 0) AS 本周认购套数 ,
                rw.月度签约任务 AS 本月任务 ,
                ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0) + ISNULL(qt.其他业绩本月认购金额, 0) + ISNULL(rw.非项目本月实际认购金额,0)  AS 本月认购金额 ,
                ISNULL(rs.本月认购套数, 0) + ISNULL(rg.本月认购套数, 0) + ISNULL(qt.其他业绩本月认购套数, 0) AS 本月认购套数 ,
				ISNULL(qt.其他业绩本月认购金额, 0) AS 其他业绩本月认购金额,
				ISNULL(qt.其他业绩本月认购套数, 0) AS 其他业绩本月认购套数,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE (ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0)+ ISNULL(qt.其他业绩本月认购金额,0) + ISNULL(rw.非项目本月实际认购金额,0)) / ISNULL(rw.月度签约任务, 0)END AS 本月认购完成率 ,
                ISNULL(本月签约金额全口径, 0) + ISNULL(rw.非项目本月实际签约金额,0) AS 本月签约金额 ,
                ISNULL(本月签约套数全口径, 0) AS 本月签约套数 ,
                ISNULL(qt.其他业绩本月签约金额, 0) AS 其他业绩本月签约金额 ,                                                                    --以客户提供其他业绩认定的房间
                ISNULL(qt.其他业绩本月签约套数, 0) AS 其他业绩本月签约套数 ,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(本月签约金额全口径, 0) +ISNULL(rw.非项目本月实际签约金额,0) ) / ISNULL(rw.月度签约任务, 0)END AS 本月签约完成率 ,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE (ISNULL(本月签约金额全口径, 0) + ISNULL(qt.其他业绩本月签约金额, 0) +  ISNULL(rw.非项目本月实际签约金额,0) ) / ISNULL(rw.月度签约任务, 0)END AS 本月签约完成率_含其他业绩 ,
                ISNULL(rw.月度签约任务, 0)  - (ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0) + ISNULL(rw.非项目本月实际认购金额,0) )  AS 本月认购金额缺口 ,  --本月任务*本月时间进度分摊比-本月认购金额
                ISNULL(rw.月度签约任务, 0)  - (ISNULL(本月签约金额全口径, 0) + ISNULL(rw.非项目本月实际签约金额,0) ) AS 本月签约金额缺口 ,
                ISNULL(pt.本月时间分摊比, 0) AS 本月时间分摊比 ,
                ISNULL(rs.累计已认购未签约金额, 0) AS 已认购未签约金额 ,
                ISNULL(rs.累计已认购未签约套数, 0) AS 已认购未签约套数 ,
                ISNULL(rw.年度签约任务, 0) AS 本年任务 ,
                ISNULL(rs.本年认购金额, 0) + ISNULL(rg.本年认购金额, 0) + ISNULL(qt.其他业绩本年认购金额, 0) + ISNULL(rw.非项目本年实际认购金额,0) AS 本年认购金额 ,
                ISNULL(rs.本年认购套数, 0) + ISNULL(rg.本年认购套数, 0) + ISNULL(qt.其他业绩本年认购套数, 0) AS 本年认购套数 ,
                ISNULL(s.本年签约金额全口径, 0) + ISNULL(rw.非项目本年实际签约金额,0) AS 本年签约金额 ,
                ISNULL(s.本年签约套数全口径, 0) AS 本年签约套数 ,
                ISNULL(qt.其他业绩本年签约金额, 0) AS 其他业绩本年签约金额 ,
                ISNULL(qt.其他业绩本年签约套数, 0) AS 其他业绩本年签约套数 ,
                CASE WHEN ISNULL(rw.年度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(s.本年签约金额全口径, 0) +ISNULL(rw.非项目本年实际签约金额,0) )  / ISNULL(rw.年度签约任务, 0)END AS 本年签约完成率 ,
                CASE WHEN ISNULL(rw.年度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(s.本年签约金额全口径, 0) + ISNULL(qt.其他业绩本年签约金额, 0) +ISNULL(rw.非项目本年实际签约金额,0) ) / ISNULL(rw.年度签约任务, 0)END AS 本年签约完成率_含其他业绩 ,
                ISNULL(rw.年度签约任务, 0)  - (ISNULL(rs.本年认购金额, 0) + ISNULL(rg.本年认购金额, 0) +ISNULL(rw.非项目本年实际认购金额,0)) AS 本年认购金额缺口 ,
                ISNULL(rw.年度签约任务, 0)  - (ISNULL(本年签约金额全口径, 0) +ISNULL(rw.非项目本年实际签约金额,0) ) AS 本年签约金额缺口 ,
                ISNULL(pt.本年时间分摊比, 0) AS 本年时间分摊比 ,
                ISNULL(rw.本年存量任务, 0) AS 本年存量任务 ,
                ISNULL(rw.本年增量任务, 0) AS 本年增量任务 ,
                ISNULL(rw.本年新增量任务, 0) AS 本年新增量任务 ,
                ISNULL(rw.本月存量任务, 0) AS 本月存量任务 ,
                ISNULL(rw.本月增量任务, 0) AS 本月增量任务 ,
                ISNULL(rw.本月新增量任务, 0) AS 本月新增量任务,
				-- 产成品
                ISNULL(rs.本日产成品认购金额, 0) + ISNULL(rg.本日产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本日认购金额, 0) AS 本日产成品认购金额 ,  
                ISNULL(rs.本日产成品认购套数, 0) + ISNULL(rg.本日产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本日认购套数, 0) AS 本日产成品认购套数 ,
                ISNULL(s.本日产成品签约金额全口径, 0) AS 本日产成品签约金额 ,
                ISNULL(s.本日产成品签约套数全口径, 0) AS 本日产成品签约套数 ,
                ISNULL(rs.本周产成品认购金额, 0) + ISNULL(rg.本周产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本周认购金额, 0) AS 本周产成品认购金额 ,
                ISNULL(rs.本周产成品认购套数, 0) + ISNULL(rg.本周产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本周认购套数, 0) AS 本周产成品认购套数 ,
                rw.产成品月度任务 AS 本月产成品任务 ,
                ISNULL(rs.本月产成品认购金额, 0) + ISNULL(rg.本月产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本月认购金额, 0) AS 本月产成品认购金额 ,
                ISNULL(rs.本月产成品认购套数, 0) + ISNULL(rg.本月产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本月认购套数, 0) AS 本月产成品认购套数 ,
				ISNULL(qt.其他业绩产成品本月认购金额, 0) AS 其他业绩产成品本月认购金额,
				ISNULL(qt.其他业绩产成品本月认购套数, 0) AS 其他业绩产成品本月认购套数,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE (ISNULL(rs.本月产成品认购金额, 0) + ISNULL(rg.本月产成品认购金额, 0)+ ISNULL(qt.其他业绩产成品本月认购金额,0)) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品认购完成率 ,
                ISNULL(本月产成品签约金额全口径, 0) AS 本月产成品签约金额 ,
                ISNULL(本月产成品签约套数全口径, 0) AS 本月产成品签约套数,
				ISNULL(qt.其他业绩产成品本月签约金额, 0) AS 其他业绩产成品本月签约金额 ,                                                                   
                ISNULL(qt.其他业绩产成品本月签约套数, 0) AS 其他业绩产成品本月签约套数 ,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE ISNULL(本月产成品签约金额全口径, 0) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品签约完成率 ,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE (ISNULL(本月产成品签约金额全口径, 0) + ISNULL(qt.其他业绩产成品本月签约金额, 0)) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品签约完成率_含其他业绩 ,
				ISNULL(rs.累计产成品已认购未签约金额, 0) AS 累计产成品已认购未签约金额 ,
                ISNULL(rs.累计产成品已认购未签约套数, 0) AS 累计产成品已认购未签约套数 ,

				ISNULL(rw.产成品年度任务,0)  AS  本年产成品任务,
                ISNULL(rs.本年产成品认购金额, 0) + ISNULL(rg.本年产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本年认购金额, 0) AS 本年产成品认购金额 ,
                ISNULL(rs.本年产成品认购套数, 0) + ISNULL(rg.本年产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本年认购套数, 0) AS 本年产成品认购套数 ,
                ISNULL(s.本年产成品签约金额全口径, 0) AS 本年产成品签约金额 ,
                ISNULL(s.本年产成品签约套数全口径, 0) AS 本年产成品签约套数 ,
                ISNULL(qt.其他业绩产成品本年签约金额, 0) AS 其他业绩产成品本年签约金额 ,
                ISNULL(qt.其他业绩产成品本年签约套数, 0) AS 其他业绩产成品本年签约套数 ,
                CASE WHEN ISNULL(rw.产成品年度任务, 0) = 0 THEN 0 ELSE ISNULL(s.本年产成品签约金额全口径, 0) / ISNULL(rw.产成品年度任务, 0)END AS 本年产成品签约完成率 ,
                CASE WHEN ISNULL(rw.产成品年度任务, 0) = 0 THEN 0 ELSE (ISNULL(s.本年产成品签约金额全口径, 0) + ISNULL(qt.其他业绩产成品本年签约金额, 0)) / ISNULL(rw.产成品年度任务, 0)END AS 本年产成品签约完成率_含其他业绩 , 
				ISNULL(rw.非项目本年实际签约金额,0 ) AS 非项目本年实际签约金额,
				ISNULL(rw.非项目本月实际签约金额,0 ) AS 非项目本月实际签约金额,
				ISNULL(rw.非项目本年实际认购金额,0 ) AS 非项目本年实际认购金额,
				ISNULL(rw.非项目本月实际认购金额,0 ) AS 非项目本月实际认购金额,
				-- 20240604 chenjw 新增面积类字段
                ISNULL(rs.本日认购面积, 0) + ISNULL(rg.本日认购面积, 0) + ISNULL(qt.其他业绩本日认购金额, 0)  AS 本日认购面积 ,
				ISNULL(s.本日签约面积全口径,0)   AS 本日签约面积 ,
			    ISNULL(rs.本周认购面积,0) + ISNULL(rg.本周认购面积,0) + ISNULL(qt.其他业绩本周认购面积,0) AS 本周认购面积 ,
				ISNULL(s.本周签约套数全口径,0) AS 本周签约套数 ,
				ISNULL(s.本周签约面积全口径,0) AS 本周签约面积 ,
				ISNULL(s.本周签约金额全口径,0) AS 本周签约金额 ,
				ISNULL(rs.本月认购面积,0) + ISNULL(rg.本月认购面积,0) + ISNULL(qt.其他业绩本月认购面积,0) AS 本月认购面积 ,
				ISNULL(s.本月签约面积全口径, 0) AS 本月签约面积 ,
				ISNULL(qt.其他业绩本月认购面积,0) AS 其他业绩本月认购面积 ,
				ISNULL(qt.其他业绩本月签约面积,0) AS 其他业绩本月签约面积 ,
				ISNULL(rs.本月产成品认购面积, 0) + ISNULL(rg.本月产成品认购面积, 0) + ISNULL(qt.其他业绩产成品本月认购面积, 0) AS 本月产成品认购面积 ,
				ISNULL(s.本月产成品签约面积全口径,0)  AS 本月产成品签约面积 ,
				ISNULL(qt.其他业绩产成品本月签约面积,0)  AS 其他业绩产成品本月签约面积 ,
				ISNULL(rs.累计产成品已认购未签约面积,0) AS 已认购未签约签约面积 ,
				ISNULL(rs.本年认购面积, 0) + ISNULL(rg.本年认购面积, 0) + ISNULL(qt.其他业绩本年认购面积, 0) AS 本年认购面积 ,
				ISNULL(本年签约面积全口径, 0) AS 本年签约面积 ,
				ISNULL(qt.其他业绩本年认购套数,0) AS 其他业绩本年认购套数 ,
				ISNULL(qt.其他业绩本日认购面积,0) AS 其他业绩本年认购面积 ,
				ISNULL(qt.其他业绩本日认购金额,0) AS 其他业绩本年认购金额 ,

				ISNULL(qt.其他业绩本年签约面积,0) AS 其他业绩本年签约面积 ,
				ISNULL(rs.本年产成品认购面积, 0) + ISNULL(rg.本年产成品认购面积, 0) + ISNULL(qt.其他业绩产成品本年认购面积, 0) AS 本年产成品认购面积 ,
				ISNULL(s.本年产成品签约面积全口径,0) AS 本年产成品签约面积 ,
				ISNULL(qt.其他业绩产成品本年签约面积,0 ) AS 其他业绩产成品本年签约面积,
                @wideTableDateText  as 宽表最后清洗日期,
                --大户型
                ISNULL(rs.本日大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本日认购金额, 0) as 本日大户型认购金额,
                ISNULL(rs.本日大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本日认购面积, 0)  as 本日大户型认购面积,
                ISNULL(rs.本日大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本日认购套数, 0)  as 本日大户型认购套数,
                ISNULL(dhx.本日大户型签约金额全口径, 0)   as 本日大户型签约金额,
                ISNULL(dhx.本日大户型签约面积全口径, 0)  as 本日大户型签约面积,
                ISNULL(dhx.本日大户型签约套数全口径, 0)  as 本日大户型签约套数,

                ISNULL(rs.本周大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本周认购金额, 0) as 本周大户型认购金额,
                ISNULL(rs.本周大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本周认购面积, 0) as 本周大户型认购面积,
                ISNULL(rs.本周大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本周认购套数, 0) as 本周大户型认购套数,
                ISNULL(dhx.本周大户型签约金额全口径, 0) as 本周大户型签约金额,
                ISNULL(dhx.本周大户型签约面积全口径, 0) as 本周大户型签约面积,
                ISNULL(dhx.本周大户型签约套数全口径, 0) as 本周大户型签约套数,

                ISNULL(rs.本月大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本月认购金额, 0) as 本月大户型认购金额,
                ISNULL(rs.本月大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本月认购面积, 0) as 本月大户型认购面积,
                ISNULL(rs.本月大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本月认购套数, 0) as 本月大户型认购套数,
                ISNULL(dhx.本月大户型签约金额全口径,0) + ISNULL(qt.其他业绩大户型本月签约金额,0) as 本月大户型签约金额,
                ISNULL(dhx.本月大户型签约面积全口径,0) + ISNULL(qt.其他业绩大户型本月签约面积,0) as 本月大户型签约面积,
                ISNULL(dhx.本月大户型签约套数全口径,0) + ISNULL(qt.其他业绩大户型本月签约套数,0) as 本月大户型签约套数,

                ISNULL(rs.本年大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本年认购金额, 0) as 本年大户型认购金额,
                ISNULL(rs.本年大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本年认购面积, 0) as 本年大户型认购面积,
                ISNULL(rs.本年大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本年认购套数, 0) as 本年大户型认购套数,
                ISNULL(dhx.本年大户型签约金额全口径,0) + ISNULL(qt.其他业绩大户型本年签约金额,0) as 本年大户型签约金额,
                ISNULL(dhx.本年大户型签约面积全口径,0) + ISNULL(qt.其他业绩大户型本年签约面积,0) as 本年大户型签约面积,
                ISNULL(dhx.本年大户型签约套数全口径,0) + ISNULL(qt.其他业绩大户型本年签约套数,0) as 本年大户型签约套数,

                ISNULL(rs.累计大户型已认购未签约金额,0) as 累计大户型已认购未签约金额,
                ISNULL(rs.累计大户型已认购未签约面积,0) as 累计大户型已认购未签约面积,
                ISNULL(rs.累计大户型已认购未签约套数,0) as 累计大户型已认购未签约套数,
                ISNULL(rs.本年大户型已认购未签约金额,0) as 本年大户型已认购未签约金额,
                ISNULL(rs.本年大户型已认购未签约套数,0) as 本年大户型已认购未签约套数,
                ISNULL(rs.本月大户型已认购未签约金额,0) as 本月大户型已认购未签约金额,
                ISNULL(rs.本月大户型已认购未签约套数,0) as 本月大户型已认购未签约套数,

                --联动房
                ISNULL(rs.本日联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本日认购金额, 0) as 本日联动房认购金额,
                ISNULL(rs.本日联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本日认购面积, 0)  as 本日联动房认购面积,
                ISNULL(rs.本日联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本日认购套数, 0)  as 本日联动房认购套数,
                ISNULL(dhx.本日联动房签约金额全口径, 0)   as 本日联动房签约金额,
                ISNULL(dhx.本日联动房签约面积全口径, 0)  as 本日联动房签约面积,
                ISNULL(dhx.本日联动房签约套数全口径, 0)  as 本日联动房签约套数,

                ISNULL(rs.本周联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本周认购金额, 0) as 本周联动房认购金额,
                ISNULL(rs.本周联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本周认购面积, 0) as 本周联动房认购面积,
                ISNULL(rs.本周联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本周认购套数, 0) as 本周联动房认购套数,
                ISNULL(dhx.本周联动房签约金额全口径, 0) as 本周联动房签约金额,
                ISNULL(dhx.本周联动房签约面积全口径, 0) as 本周联动房签约面积,
                ISNULL(dhx.本周联动房签约套数全口径, 0) as 本周联动房签约套数,

                ISNULL(rs.本月联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本月认购金额, 0) as 本月联动房认购金额,
                ISNULL(rs.本月联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本月认购面积, 0) as 本月联动房认购面积,
                ISNULL(rs.本月联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本月认购套数, 0) as 本月联动房认购套数,
                ISNULL(dhx.本月联动房签约金额全口径,0) + ISNULL(qt.其他业绩联动房本月签约金额,0) as 本月联动房签约金额,
                ISNULL(dhx.本月联动房签约面积全口径,0) + ISNULL(qt.其他业绩联动房本月签约面积,0) as 本月联动房签约面积,
                ISNULL(dhx.本月联动房签约套数全口径,0) + ISNULL(qt.其他业绩联动房本月签约套数,0) as 本月联动房签约套数,

                ISNULL(rs.本年联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本年认购金额, 0) as 本年联动房认购金额,
                ISNULL(rs.本年联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本年认购面积, 0) as 本年联动房认购面积,
                ISNULL(rs.本年联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本年认购套数, 0) as 本年联动房认购套数,
                ISNULL(dhx.本年联动房签约金额全口径,0) + ISNULL(qt.其他业绩联动房本年签约金额,0) as 本年联动房签约金额,
                ISNULL(dhx.本年联动房签约面积全口径,0) + ISNULL(qt.其他业绩联动房本年签约面积,0) as 本年联动房签约面积,
                ISNULL(dhx.本年联动房签约套数全口径,0) + ISNULL(qt.其他业绩联动房本年签约套数,0) as 本年联动房签约套数,

                ISNULL(rs.累计联动房已认购未签约金额,0) AS 累计联动房已认购未签约金额,
                ISNULL(rs.累计联动房已认购未签约面积,0) AS 累计联动房已认购未签约面积,
                ISNULL(rs.累计联动房已认购未签约套数,0) AS 累计联动房已认购未签约套数,
                ISNULL(rs.本年联动房已认购未签约金额,0) AS 本年联动房已认购未签约金额,
                ISNULL(rs.本年联动房已认购未签约套数,0) AS 本年联动房已认购未签约套数,
                ISNULL(rs.本月联动房已认购未签约金额,0) AS 本月联动房已认购未签约金额,
                ISNULL(rs.本月联动房已认购未签约套数,0) AS 本月联动房已认购未签约套数,

                ISNULL(qt.其他业绩大户型本月签约金额,0) as 其他业绩大户型本月签约金额,
                ISNULL(qt.其他业绩大户型本月签约面积,0) as 其他业绩大户型本月签约面积,
                ISNULL(qt.其他业绩大户型本月签约套数,0) as 其他业绩大户型本月签约套数,
                ISNULL(qt.其他业绩大户型本年签约金额,0) as 其他业绩大户型本年签约金额,
                ISNULL(qt.其他业绩大户型本年签约面积,0) as 其他业绩大户型本年签约面积,
                ISNULL(qt.其他业绩大户型本年签约套数,0) as 其他业绩大户型本年签约套数,

                --准产成品
                ISNULL(rs.本日准产成品认购金额, 0) + ISNULL(rg.本日准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本日认购金额, 0) AS 本日准产成品认购金额,
                ISNULL(rs.本日准产成品认购面积, 0) + ISNULL(rg.本日准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本日认购面积, 0) AS 本日准产成品认购面积,
                ISNULL(rs.本日准产成品认购套数, 0) + ISNULL(rg.本日准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本日认购套数, 0) AS 本日准产成品认购套数 ,

                ISNULL(s.本日准产成品签约金额全口径, 0) AS 本日准产成品签约金额 ,
                ISNULL(s.本日准产成品签约面积全口径, 0) AS 本日准产成品签约面积 ,
                ISNULL(s.本日准产成品签约套数全口径, 0) AS 本日准产成品签约套数 ,

                ISNULL(rs.本周准产成品认购金额, 0) + ISNULL(rg.本周准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本周认购金额, 0) AS 本周准产成品认购金额 ,
                ISNULL(rs.本周准产成品认购面积, 0) + ISNULL(rg.本周准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本周认购面积, 0) AS 本周准产成品认购面积 ,
                ISNULL(rs.本周准产成品认购套数, 0) + ISNULL(rg.本周准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本周认购套数, 0) AS 本周准产成品认购套数 ,

                ISNULL(rs.本月准产成品认购金额, 0) + ISNULL(rg.本月准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本月认购金额, 0) AS 本月准产成品认购金额 ,
                ISNULL(rs.本月准产成品认购面积, 0) + ISNULL(rg.本月准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本月认购面积, 0) AS 本月准产成品认购面积 ,
                ISNULL(rs.本月准产成品认购套数, 0) + ISNULL(rg.本月准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本月认购套数, 0) AS 本月准产成品认购套数 ,

                ISNULL(qt.其他业绩准产成品本月认购金额, 0) AS 其他业绩准产成品本月认购金额 ,
                ISNULL(qt.其他业绩准产成品本月认购面积, 0) AS 其他业绩准产成品本月认购面积 ,
                ISNULL(qt.其他业绩准产成品本月认购套数, 0) AS 其他业绩准产成品本月认购套数 ,

                ISNULL(本月准产成品签约金额全口径, 0) AS 本月准产成品签约金额 ,
                ISNULL(本月准产成品签约面积全口径, 0) AS 本月准产成品签约面积 ,
                ISNULL(本月准产成品签约套数全口径, 0) AS 本月准产成品签约套数 ,

                ISNULL(qt.其他业绩准产成品本月签约金额, 0) AS 其他业绩准产成品本月签约金额 ,
                ISNULL(qt.其他业绩准产成品本月签约面积, 0) AS 其他业绩准产成品本月签约面积 ,
                ISNULL(qt.其他业绩准产成品本月签约套数, 0) AS 其他业绩准产成品本月签约套数 ,

                ISNULL(rs.累计准产成品已认购未签约金额, 0) AS 累计准产成品已认购未签约金额 ,
                ISNULL(rs.累计准产成品已认购未签约面积, 0) AS 累计准产成品已认购未签约面积 ,
                ISNULL(rs.累计准产成品已认购未签约套数, 0) AS 累计准产成品已认购未签约套数 ,

                ISNULL(rs.本年准产成品认购金额, 0) + ISNULL(rg.本年准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本年认购金额, 0) AS 本年准产成品认购金额 ,
                ISNULL(rs.本年准产成品认购面积, 0) + ISNULL(rg.本年准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本年认购面积, 0) AS 本年准产成品认购面积 ,
                ISNULL(rs.本年准产成品认购套数, 0) + ISNULL(rg.本年准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本年认购套数, 0) AS 本年准产成品认购套数 ,

                ISNULL(s.本年准产成品签约金额全口径, 0) AS 本年准产成品签约金额 ,
                ISNULL(s.本年准产成品签约面积全口径, 0) AS 本年准产成品签约面积 ,
                ISNULL(s.本年准产成品签约套数全口径, 0) AS 本年准产成品签约套数 ,
                ISNULL(qt.其他业绩准产成品本年签约金额, 0) AS 其他业绩准产成品本年签约金额 ,
                ISNULL(qt.其他业绩准产成品本年签约面积, 0) AS 其他业绩准产成品本年签约面积 ,                
                ISNULL(qt.其他业绩准产成品本年签约套数, 0) AS 其他业绩准产成品本年签约套数 ,

                --补充现产成品任务和大户型任务@20250630
                ISNULL(rw.准产成品月度任务, 0) AS 准产成品月度任务,
                ISNULL(rw.准产成品年度任务, 0) AS 准产成品年度任务,
                ISNULL(rw.大户型月度任务, 0)   AS 大户型月度任务,
                ISNULL(rw.大户型年度任务, 0)   AS 大户型年度任务
        FROM    data_wide_dws_mdm_Project p
                INNER JOIN #TopProduct pt ON pt.ParentProjGUID = p.ProjGUID
                LEFT JOIN data_tb_hnyx_jdfxtb rw ON rw.projguid = p.ProjGUID AND   rw.业态 = pt.TopProductTypeName
                LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
                LEFT JOIN #projsale s ON p.ProjGUID = s.orgguid AND pt.TopProductTypeName = s.TopProductTypeName
                LEFT JOIN #projsale_ldf_dhx dhx on p.ProjGUID = dhx.orgguid AND pt.TopProductTypeName = dhx.TopProductTypeName
                LEFT JOIN #rsale rs ON rs.ProjGUID = p.ProjGUID AND pt.TopProductTypeName = rs.TopProductTypeName
                LEFT JOIN #rg rg ON rg.ProjGUID = p.ProjGUID AND   pt.TopProductTypeName = rg.TopProductTypeName
                LEFT JOIN #qtqy qt ON qt.projguid = p.projguid AND pt.TopProductTypeName = qt.TopProductTypeName
        WHERE   Level = 2 AND   p.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
        UNION ALL
        -- 区域层级增加 数字营销
        SELECT  @DateText AS 数据清洗日期 ,
                '组团' AS 层级 ,
                p.BUGUID AS 公司GUID ,
                '数字营销' AS 区域 ,
                '数字营销' AS 营销片区 ,
                p.ProjGUID AS 项目GUID ,
                ISNULL(tb.推广名称, p.SpreadName) AS 项目名称 ,
                '全部组团' AS 层级名称 ,
                '数字营销' + '(' + @szyxfzr + ')' AS 层级名称显示 ,
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END AS 项目名称负责人 ,
                CASE WHEN pt.TopProductTypeName IN ('高级住宅', '住宅', '别墅') THEN '住宅' 
				     WHEN pt.TopProductTypeName IN ('地下室/车库') THEN '车位' 
					 WHEN pt.TopProductTypeName IN ('商业','公寓','写字楼','酒店','会所','企业会所') THEN  '商办'
					 ELSE '其他' END AS 业态 ,
                pt.TopProductTypeName AS 产品类型 ,
                pt.TopProductTypeGUID AS 产品类型GUID ,
                tb.城市 ,
                tb.公司 ,
                tb.投管编码 ,
                tb.项目负责人 ,
                p.BeginDate AS 项目获取日期 ,
                pt.存量增量 ,
                ISNULL(sz.数字营销本日认购金额, 0) + ISNULL(qt.数字营销其他业绩本日认购金额, 0) AS 本日认购金额 ,                                                         -- 全口径
                ISNULL(sz.数字营销本日认购套数, 0) + ISNULL(qt.数字营销其他业绩本日认购套数, 0) AS 本日认购套数 ,
                ISNULL(sz.数字营销本日签约金额, 0) AS 本日签约金额 ,
                ISNULL(sz.数字营销本日签约套数, 0) AS 本日签约套数 ,
                ISNULL(sz.数字营销本周认购金额, 0) + ISNULL(qt.数字营销其他业绩本周认购金额, 0) AS 本周认购金额 ,
                ISNULL(sz.数字营销本周认购套数, 0) + ISNULL(qt.数字营销其他业绩本周认购套数, 0) AS 本周认购套数 ,
                rw.数字营销月度任务 AS 本月任务 ,
                ISNULL(sz.数字营销本月认购金额, 0) + ISNULL(qt.数字营销其他业绩本月认购金额, 0) AS 本月认购金额 ,
                ISNULL(sz.数字营销本月认购套数, 0) + ISNULL(qt.数字营销其他业绩本月认购套数, 0) AS 本月认购套数 ,
			    ISNULL(qt.数字营销其他业绩本月认购金额, 0) AS 数字营销其他业绩本月认购金额,
				ISNULL(qt.数字营销其他业绩本月认购套数, 0) AS 数字营销其他业绩本月认购套数,
                CASE WHEN ISNULL(rw.数字营销月度任务, 0) = 0 THEN 0 ELSE (ISNULL(sz.数字营销本月认购金额, 0) + ISNULL(qt.数字营销其他业绩本月认购金额, 0)) / ISNULL(rw.数字营销月度任务, 0)END AS 本月认购完成率 ,
                ISNULL(sz.数字营销本月签约金额, 0) AS 本月签约金额 ,
                ISNULL(sz.数字营销本月签约套数, 0) AS 本月签约套数 ,
                ISNULL(qt.数字营销其他业绩本月签约金额, 0) AS 其他业绩本月签约金额 ,                                                                                --以客户提供其他业绩认定的房间
                ISNULL(qt.数字营销其他业绩本月签约套数, 0) AS 其他业绩本月签约套数 ,
                CASE WHEN ISNULL(rw.数字营销月度任务, 0) = 0 THEN 0 ELSE ISNULL(数字营销本月签约金额, 0) / ISNULL(rw.数字营销月度任务, 0)END AS 本月签约完成率 ,
                CASE WHEN ISNULL(rw.数字营销月度任务, 0) = 0 THEN 0 ELSE (ISNULL(数字营销本月签约金额, 0) + ISNULL(qt.数字营销其他业绩本月签约金额, 0)) / ISNULL(rw.数字营销月度任务, 0)END AS 本月签约完成率_含其他业绩 ,
                ISNULL(rw.数字营销月度任务, 0)  - (ISNULL(sz.数字营销本月认购金额, 0) + ISNULL(qt.数字营销其他业绩本月认购金额, 0)) AS 本月认购金额缺口 ,    --本月任务*本月时间进度分摊比-本月认购金额
                ISNULL(rw.数字营销月度任务, 0)  - ISNULL(数字营销本月签约金额, 0) AS 本月签约金额缺口 ,
                ISNULL(pt.本月时间分摊比, 0) AS 本月时间分摊比 ,
                ISNULL(sz.数字营销已认购未签约金额, 0) AS 已认购未签约金额 ,
                ISNULL(sz.数字营销已认购未签约套数, 0) AS 已认购未签约套数 ,
                ISNULL(rw.数字营销年度任务, 0) AS 本年任务 ,
                ISNULL(sz.数字营销本年认购金额, 0) + ISNULL(qt.数字营销其他业绩本年认购金额, 0) AS 本年认购金额 ,
                ISNULL(sz.数字营销本年认购套数, 0) + ISNULL(qt.数字营销其他业绩本年认购套数, 0) AS 本年认购套数 ,
                ISNULL(sz.数字营销本年签约金额, 0) AS 本年签约金额 ,
                ISNULL(sz.数字营销本年签约套数, 0) AS 本年签约套数 ,
                ISNULL(qt.数字营销其他业绩本年签约金额, 0) AS 其他业绩本年签约金额 ,
                ISNULL(qt.数字营销其他业绩本年签约套数, 0) AS 其他业绩本年签约套数 ,
                CASE WHEN ISNULL(rw.数字营销年度任务, 0) = 0 THEN 0 ELSE ISNULL(sz.数字营销本年签约金额, 0) / ISNULL(rw.数字营销年度任务, 0)END AS 本年签约完成率 ,
                CASE WHEN ISNULL(rw.数字营销年度任务, 0) = 0 THEN 0 ELSE (ISNULL(sz.数字营销本年签约金额, 0) + ISNULL(qt.数字营销其他业绩本年签约金额, 0)) / ISNULL(rw.数字营销年度任务, 0)END AS 本年签约完成率_含其他业绩 ,
                ISNULL(rw.数字营销年度任务, 0) - (ISNULL(sz.数字营销本年认购金额, 0) + ISNULL(qt.数字营销其他业绩本年认购金额, 0)) AS 本年认购金额缺口 ,
                ISNULL(rw.数字营销年度任务, 0) - ISNULL(sz.数字营销本年认购金额, 0) AS 本年签约金额缺口 ,
                ISNULL(pt.本年时间分摊比, 0) AS 本年时间分摊比 ,
                ISNULL(rw.本年存量任务, 0) AS 本年存量任务 ,
                ISNULL(rw.本年增量任务, 0) AS 本年增量任务 ,
                ISNULL(rw.本年新增量任务, 0) AS 本年新增量任务 ,
                ISNULL(rw.本月存量任务, 0) AS 本月存量任务 ,
                ISNULL(rw.本月增量任务, 0) AS 本月增量任务 ,
                ISNULL(rw.本月新增量任务, 0) AS 本月新增量任务,
				-- 产成品
				ISNULL(sz.数字营销产成品本日认购金额, 0) + ISNULL(qt.数字营销其他业绩产成品本日认购金额, 0) as 本日产成品认购金额  , 
				ISNULL(sz.数字营销产成品本日认购套数, 0) + ISNULL(qt.数字营销其他业绩产成品本日认购套数, 0)  as 本日产成品认购套数  ,
				ISNULL(sz.数字营销产成品本日签约金额, 0) as 本日产成品签约金额  ,
				ISNULL(sz.数字营销产成品本日签约套数, 0) as 本日产成品签约套数  ,
				ISNULL(sz.数字营销产成品本周认购金额, 0) + ISNULL(qt.数字营销其他业绩产成品本周认购金额, 0) as 本周产成品认购金额  ,
				ISNULL(sz.数字营销产成品本周认购套数, 0) + ISNULL(qt.数字营销其他业绩产成品本周认购套数, 0) as 本周产成品认购套数  ,
				ISNULL(产成品月度任务,0) as 本月产成品任务  ,
				ISNULL(sz.数字营销产成品本月认购金额, 0) + ISNULL(qt.数字营销其他业绩产成品本月认购金额, 0) as 本月产成品认购金额  ,
				ISNULL(sz.数字营销产成品本月认购套数, 0) + ISNULL(qt.数字营销其他业绩产成品本月认购套数, 0) as 本月产成品认购套数  ,
				ISNULL(qt.数字营销其他业绩产成品本月认购金额, 0) as 其他业绩产成品本月认购金额  ,
				ISNULL(qt.数字营销其他业绩产成品本月认购套数, 0) as 其他业绩产成品本月认购套数  ,
				NULL as 本月产成品认购完成率  , 
				ISNULL(sz.数字营销产成品本月签约金额, 0) as 本月产成品签约金额  ,
				ISNULL(sz.数字营销产成品本月签约套数, 0) as 本月产成品签约套数  ,
				ISNULL(qt.数字营销其他业绩产成品本月签约金额, 0) as 其他业绩产成品本月签约金额  ,  
				ISNULL(qt.数字营销其他业绩产成品本月签约套数, 0) as 其他业绩产成品本月签约套数  ,
				NULL as 本月产成品签约完成率  ,
				NULL as 本月产成品签约完成率_含其他业绩  ,
				ISNULL(sz.数字营销产成品已认购未签约金额, 0) as 累计产成品已认购未签约金额  ,
				ISNULL(sz.数字营销产成品已认购未签约套数, 0) as 累计产成品已认购未签约套数  ,
				ISNULL(rw.产成品年度任务,0) as 本年产成品任务  ,
				ISNULL(sz.数字营销产成品本年认购金额, 0) + ISNULL(qt.数字营销其他业绩产成品本年认购金额, 0) as 本年产成品认购金额  ,
				ISNULL(sz.数字营销产成品本年认购套数, 0) + ISNULL(qt.数字营销其他业绩产成品本年认购套数, 0) as 本年产成品认购套数  ,
				ISNULL(sz.数字营销产成品本年签约金额, 0) as 本年产成品签约金额  ,
				ISNULL(sz.数字营销产成品本年签约套数, 0) as 本年产成品签约套数  ,
				ISNULL(qt.数字营销其他业绩产成品本年签约金额, 0)  as 其他业绩产成品本年签约金额  ,
				ISNULL(qt.数字营销其他业绩产成品本年签约套数, 0)  as 其他业绩产成品本年签约套数  ,
				NULL as 本年产成品签约完成率  ,
				NULL as 本年产成品签约完成率_含其他业绩,
				null  AS 非项目本年实际签约金额,
				null  AS 非项目本月实际签约金额,
				null  AS 非项目本年实际认购金额,
				null  AS 非项目本月实际认购金额,
				-- 20240604 chenjw 新增面积类字段
				0 AS 本日认购面积 ,
				0 AS 本日签约面积 ,
				0 AS 本周认购面积 ,
				ISNULL(sz.数字营销本周签约套数,0) AS 本周签约套数 ,
				0 AS 本周签约面积 ,
				ISNULL(sz.数字营销本周签约金额,0) AS 本周签约金额 ,
				0 AS 本月认购面积 ,
				0 AS 本月签约面积 ,
				0 AS 其他业绩本月认购面积 ,
				0 AS 其他业绩本月签约面积 ,
				0 AS 本月产成品认购面积 ,
				0 AS 本月产成品签约面积 ,
				0 AS 其他业绩产成品本月签约面积 ,
				0 AS 已认购未签约签约面积 ,
				0 AS 本年认购面积 ,
				0 AS 本年签约面积 ,
				0 AS 其他业绩本年认购套数 ,
				0 AS 其他业绩本年认购面积 ,
				0 AS 其他业绩本年认购金额 ,
				0 AS 其他业绩本年签约面积 ,
				0 AS 本年产成品认购面积 ,
				0 AS 本年产成品签约面积 ,
				0 AS 其他业绩产成品本年签约面积,
                @wideTableDateText  as 宽表最后清洗日期, 
                --大户型
                0 as 本日大户型认购金额,
                0 as 本日大户型认购面积,
                0 as 本日大户型认购套数,
                0 as 本日大户型签约金额,
                0 as 本日大户型签约面积,
                0 as 本日大户型签约套数,

                0 as 本周大户型认购金额,
                0 as 本周大户型认购面积,
                0 as 本周大户型认购套数,
                0 as 本周大户型签约金额,
                0 as 本周大户型签约面积,
                0 as 本周大户型签约套数,

                0 as 本月大户型认购金额,
                0 as 本月大户型认购面积,
                0 as 本月大户型认购套数,
                0 as 本月大户型签约金额,
                0 as 本月大户型签约面积,
                0 as 本月大户型签约套数,

                0 as 本年大户型认购金额,
                0 as 本年大户型认购面积,
                0 as 本年大户型认购套数,
                0 as 本年大户型签约金额,
                0 as 本年大户型签约面积,
                0 as 本年大户型签约套数,

                0 as 累计大户型已认购未签约金额,
                0 as 累计大户型已认购未签约面积,
                0 as 累计大户型已认购未签约套数,
                0 as 本年大户型已认购未签约金额,
                0 as 本年大户型已认购未签约套数,
                0 as 本月大户型已认购未签约金额,
                0 as 本月大户型已认购未签约套数,

                --联动房
                0 as 本日联动房认购金额,
                0 as 本日联动房认购面积,
                0 as 本日联动房认购套数,
                0 as 本日联动房签约金额,
                0 as 本日联动房签约面积,
                0 as 本日联动房签约套数,

                0 as 本周联动房认购金额,
                0 as 本周联动房认购面积,
                0 as 本周联动房认购套数,
                0 as 本周联动房签约金额,
                0 as 本周联动房签约面积,
                0 as 本周联动房签约套数,

                0 as 本月联动房认购金额,
                0 as 本月联动房认购面积,
                0 as 本月联动房认购套数,
                0 as 本月联动房签约金额,
                0 as 本月联动房签约面积,
                0 as 本月联动房签约套数,

                0 as 本年联动房认购金额,
                0 as 本年联动房认购面积,
                0 as 本年联动房认购套数,
                0 as 本年联动房签约金额,
                0 as 本年联动房签约面积,
                0 as 本年联动房签约套数,

                0 AS 累计联动房已认购未签约金额,
                0 AS 累计联动房已认购未签约面积,
                0 AS 累计联动房已认购未签约套数,
                0 AS 本年联动房已认购未签约金额,
                0 AS 本年联动房已认购未签约套数,
                0 AS 本月联动房已认购未签约金额,
                0 AS 本月联动房已认购未签约套数,

                0 as 其他业绩大户型本月签约金额,
                0 as 其他业绩大户型本月签约面积,
                0 as 其他业绩大户型本月签约套数,
                0 as 其他业绩大户型本年签约金额,
                0 as 其他业绩大户型本年签约面积,
                0 as 其他业绩大户型本年签约套数,

                --准产成品
                ISNULL(sz.数字营销准产成品本日认购金额, 0) + ISNULL(qt.数字营销其他业绩准产成品本日认购金额, 0)  as 本日准产成品认购金额  , 
                ISNULL(sz.数字营销准产成品本日认购面积, 0) + ISNULL(qt.数字营销其他业绩准产成品本日认购面积, 0)  as 本日准产成品认购面积  ,
				ISNULL(sz.数字营销准产成品本日认购套数, 0) + ISNULL(qt.数字营销其他业绩准产成品本日认购套数, 0)  as 本日准产成品认购套数  ,

				ISNULL(sz.数字营销准产成品本日签约金额, 0) as 本日准产成品签约金额  ,
                ISNULL(sz.数字营销准产成品本日签约面积, 0) as 本日准产成品签约面积  ,
				ISNULL(sz.数字营销准产成品本日签约套数, 0) as 本日准产成品签约套数  ,

				ISNULL(sz.数字营销准产成品本周认购金额, 0) + ISNULL(qt.数字营销其他业绩准产成品本周认购金额, 0) as 本周准产成品认购金额  ,
                ISNULL(sz.数字营销准产成品本周认购面积, 0) + ISNULL(qt.数字营销其他业绩准产成品本周认购面积, 0) as 本周准产成品认购面积  ,
				ISNULL(sz.数字营销准产成品本周认购套数, 0) + ISNULL(qt.数字营销其他业绩准产成品本周认购套数, 0) as 本周准产成品认购套数  ,

				ISNULL(sz.数字营销准产成品本月认购金额, 0) + ISNULL(qt.数字营销其他业绩准产成品本月认购金额, 0) as 本月准产成品认购金额  ,
                ISNULL(sz.数字营销准产成品本月认购面积, 0) + ISNULL(qt.数字营销其他业绩准产成品本月认购面积, 0) as 本月准产成品认购面积  ,
				ISNULL(sz.数字营销准产成品本月认购套数, 0) + ISNULL(qt.数字营销其他业绩准产成品本月认购套数, 0) as 本月准产成品认购套数  ,

				ISNULL(qt.数字营销其他业绩准产成品本月认购金额, 0) as 其他业绩准产成品本月认购金额  ,
                ISNULL(qt.数字营销其他业绩准产成品本月认购面积, 0) as 其他业绩准产成品本月认购面积  ,
				ISNULL(qt.数字营销其他业绩准产成品本月认购套数, 0) as 其他业绩准产成品本月认购套数  ,

				ISNULL(sz.数字营销准产成品本月签约金额, 0) as 本月准产成品签约金额  ,
                ISNULL(sz.数字营销准产成品本月签约面积, 0) as 本月准产成品签约面积  ,
				ISNULL(sz.数字营销准产成品本月签约套数, 0) as 本月准产成品签约套数  ,

				ISNULL(qt.数字营销其他业绩准产成品本月签约金额, 0) as 其他业绩准产成品本月签约金额  ,  
                ISNULL(qt.数字营销其他业绩准产成品本月签约面积, 0) as 其他业绩准产成品本月签约面积  ,
				ISNULL(qt.数字营销其他业绩准产成品本月签约套数, 0) as 其他业绩准产成品本月签约套数  ,

				ISNULL(sz.数字营销准产成品已认购未签约金额, 0) as 累计准产成品已认购未签约金额  ,
                ISNULL(sz.数字营销准产成品已认购未签约面积, 0) as 累计准产成品已认购未签约面积  ,
				ISNULL(sz.数字营销准产成品已认购未签约套数, 0) as 累计准产成品已认购未签约套数  ,

				ISNULL(sz.数字营销准产成品本年认购金额, 0) + ISNULL(qt.数字营销其他业绩准产成品本年认购金额, 0) as 本年准产成品认购金额  ,
                ISNULL(sz.数字营销准产成品本年认购面积, 0) + ISNULL(qt.数字营销其他业绩准产成品本年认购面积, 0) as 本年准产成品认购面积  ,
				ISNULL(sz.数字营销准产成品本年认购套数, 0) + ISNULL(qt.数字营销其他业绩准产成品本年认购套数, 0) as 本年准产成品认购套数  ,

				ISNULL(sz.数字营销准产成品本年签约金额, 0) as 本年准产成品签约金额  ,
                ISNULL(sz.数字营销准产成品本年签约面积, 0) as 本年准产成品签约面积  ,
				ISNULL(sz.数字营销准产成品本年签约套数, 0) as 本年准产成品签约套数  ,

				ISNULL(qt.数字营销其他业绩准产成品本年签约金额, 0)  as 其他业绩准产成品本年签约金额  ,
                ISNULL(qt.数字营销其他业绩准产成品本年签约面积, 0)  as 其他业绩准产成品本年签约面积  ,
				ISNULL(qt.数字营销其他业绩准产成品本年签约套数, 0)  as 其他业绩准产成品本年签约套数  ,

                --补充现产成品任务和大户型任务@20250630
                ISNULL(rw.准产成品月度任务, 0) AS 准产成品月度任务,
                ISNULL(rw.准产成品年度任务, 0) AS 准产成品年度任务,
                0 AS 大户型月度任务,
                0 AS 大户型年度任务


        FROM    data_wide_dws_mdm_Project p
                INNER JOIN #TopProduct pt ON pt.ParentProjGUID = p.ProjGUID
                LEFT JOIN data_tb_hnyx_jdfxtb rw ON rw.projguid = p.ProjGUID AND   rw.业态 = pt.TopProductTypeName
                LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
                LEFT JOIN #szyx sz ON sz.ProjGUID = p.projguid AND pt.TopProductTypeName = sz.TopProductTypeName
                LEFT JOIN #szqtqy qt ON qt.projguid = p.projguid AND   pt.TopProductTypeName = qt.TopProductTypeName
        WHERE   Level = 2 AND   p.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
        UNION ALL
        -- 区域层级增加 数字营销和其他非项目扣减
        SELECT  @DateText AS 数据清洗日期 ,
                '组团' AS 层级 ,
                p.BUGUID AS 公司GUID ,
                '数字营销' AS 区域 ,
                '数字营销' AS 营销片区 ,
                p.ProjGUID AS 项目GUID ,
                ISNULL(tb.推广名称, p.SpreadName) AS 项目名称 ,
                '全部组团' AS 层级名称 ,
                '平衡处理' AS 层级名称显示 ,
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END AS 项目名称负责人 ,
                CASE WHEN pt.TopProductTypeName IN ('高级住宅', '住宅', '别墅') THEN '住宅' 
				     WHEN pt.TopProductTypeName IN ('地下室/车库') THEN '车位' 
					 WHEN pt.TopProductTypeName IN ('商业','公寓','写字楼','酒店','会所','企业会所') THEN  '商办'
					 ELSE '其他' END AS 业态 ,
                pt.TopProductTypeName AS 产品类型 ,
                pt.TopProductTypeGUID AS 产品类型GUID ,
                tb.城市 ,
                tb.公司 ,
                tb.投管编码 ,
                tb.项目负责人 ,
                p.BeginDate AS 项目获取日期 ,
                pt.存量增量 ,
                -(ISNULL(sz.数字营销本日认购金额, 0) + ISNULL(qt.数字营销其他业绩本日认购金额, 0)) AS 本日认购金额 ,                                                      -- 全口径
                -(ISNULL(sz.数字营销本日认购套数, 0) + ISNULL(qt.数字营销其他业绩本日认购套数, 0)) AS 本日认购套数 ,
                -ISNULL(sz.数字营销本日签约金额, 0) AS 本日签约金额 ,
                -ISNULL(sz.数字营销本日签约套数, 0) AS 本日签约套数 ,
                -(ISNULL(sz.数字营销本周认购金额, 0) + ISNULL(qt.数字营销其他业绩本周认购金额, 0)) AS 本周认购金额 ,
                -(ISNULL(sz.数字营销本周认购套数, 0) + ISNULL(qt.数字营销其他业绩本周认购套数, 0)) AS 本周认购套数 ,
                -ISNULL(rw.数字营销月度任务, 0) AS 本月任务 ,
                -(ISNULL(sz.数字营销本月认购金额, 0) + ISNULL(qt.数字营销其他业绩本月认购金额, 0)) - ISNULL(rw.非项目本月实际认购金额,0 ) AS 本月认购金额 ,
                -(ISNULL(sz.数字营销本月认购套数, 0) + ISNULL(qt.数字营销其他业绩本月认购套数, 0)) AS 本月认购套数 ,
				-ISNULL(qt.数字营销其他业绩本月认购金额, 0)  AS 数字营销其他业绩本月认购金额,
				-ISNULL(qt.数字营销其他业绩本月认购套数, 0) AS 数字营销其他业绩本月认购套数,
                -CASE WHEN ISNULL(rw.数字营销月度任务, 0) = 0 THEN 0 ELSE (ISNULL(sz.数字营销本月认购金额, 0) + ISNULL(qt.数字营销其他业绩本月认购金额, 0)) / ISNULL(rw.数字营销月度任务, 0)END AS 本月认购完成率 ,
                -ISNULL(sz.数字营销本月签约金额, 0) - ISNULL(rw.非项目本月实际签约金额,0 )  AS 本月签约金额 ,
                -ISNULL(sz.数字营销本月签约套数, 0) AS 本月签约套数 ,
                -ISNULL(qt.数字营销其他业绩本月签约金额, 0) AS 其他业绩本月签约金额 ,                                                                               --以客户提供其他业绩认定的房间
                -ISNULL(qt.数字营销其他业绩本月签约套数, 0) AS 其他业绩本月签约套数 ,
                -CASE WHEN ISNULL(rw.数字营销月度任务, 0) = 0 THEN 0 ELSE ISNULL(数字营销本月签约金额, 0) / ISNULL(rw.数字营销月度任务, 0)END AS 本月签约完成率 ,
                -CASE WHEN ISNULL(rw.数字营销月度任务, 0) = 0 THEN 0 ELSE (ISNULL(数字营销本月签约金额, 0) + ISNULL(qt.数字营销其他业绩本月签约金额, 0)) / ISNULL(rw.数字营销月度任务, 0)END AS 本月签约完成率_含其他业绩 ,
                -(ISNULL(rw.数字营销月度任务, 0)  - (ISNULL(sz.数字营销本月认购金额, 0) + ISNULL(qt.数字营销其他业绩本月认购金额, 0))) AS 本月认购金额缺口 , --本月任务*本月时间进度分摊比-本月认购金额
                -(ISNULL(rw.数字营销月度任务, 0)  - ISNULL(数字营销本月签约金额, 0)) AS 本月签约金额缺口 ,
                ISNULL(pt.本月时间分摊比, 0) AS 本月时间分摊比 ,
                -ISNULL(sz.数字营销已认购未签约金额, 0) AS 已认购未签约金额 ,
                -ISNULL(sz.数字营销已认购未签约套数, 0) AS 已认购未签约套数 ,
                -ISNULL(rw.数字营销年度任务, 0) AS 本年任务 ,
                -(ISNULL(sz.数字营销本年认购金额, 0) + ISNULL(qt.数字营销其他业绩本年认购金额, 0)) - ISNULL(rw.非项目本年实际认购金额,0 )  AS 本年认购金额 ,
                -(ISNULL(sz.数字营销本年认购套数, 0) + ISNULL(qt.数字营销其他业绩本年认购套数, 0)) AS 本年认购套数 ,
                -ISNULL(sz.数字营销本年签约金额, 0) - ISNULL(rw.非项目本年实际签约金额,0 ) AS 本年签约金额 ,
                -ISNULL(sz.数字营销本年签约套数, 0) AS 本年签约套数 ,
                -ISNULL(qt.数字营销其他业绩本年签约金额, 0) AS 其他业绩本年签约金额 ,
                -ISNULL(qt.数字营销其他业绩本年签约套数, 0) AS 其他业绩本年签约套数 ,
                -CASE WHEN ISNULL(rw.数字营销年度任务, 0) = 0 THEN 0 ELSE ISNULL(sz.数字营销本年签约金额, 0) / ISNULL(rw.数字营销年度任务, 0)END AS 本年签约完成率 ,
                -CASE WHEN ISNULL(rw.数字营销年度任务, 0) = 0 THEN 0 ELSE (ISNULL(sz.数字营销本年签约金额, 0) + ISNULL(qt.数字营销其他业绩本年签约金额, 0)) / ISNULL(rw.数字营销年度任务, 0)END AS 本年签约完成率_含其他业绩 ,
                -ISNULL(rw.数字营销年度任务, 0)  - (ISNULL(sz.数字营销本年认购金额, 0) + ISNULL(qt.数字营销其他业绩本年认购金额, 0)) AS 本年认购金额缺口 ,
                -(ISNULL(rw.数字营销年度任务, 0) - ISNULL(sz.数字营销本年认购金额, 0)) AS 本年签约金额缺口 ,
                ISNULL(pt.本年时间分摊比, 0) AS 本年时间分摊比 ,
                ISNULL(rw.本年存量任务, 0) AS 本年存量任务 ,
                ISNULL(rw.本年增量任务, 0) AS 本年增量任务 ,
                ISNULL(rw.本年新增量任务, 0) AS 本年新增量任务 ,
                ISNULL(rw.本月存量任务, 0) AS 本月存量任务 ,
                ISNULL(rw.本月增量任务, 0) AS 本月增量任务 ,
                ISNULL(rw.本月新增量任务, 0) AS 本月新增量任务,
			    -- 产成品
				-(ISNULL(sz.数字营销产成品本日认购金额, 0) + ISNULL(qt.数字营销其他业绩产成品本日认购金额, 0) ) as 本日产成品认购金额  , 
				-(ISNULL(sz.数字营销产成品本日认购套数, 0) + ISNULL(qt.数字营销其他业绩产成品本日认购套数, 0) ) as 本日产成品认购套数  ,
				-ISNULL(sz.数字营销产成品本日签约金额, 0) as 本日产成品签约金额  ,
				-ISNULL(sz.数字营销产成品本日签约套数, 0) as 本日产成品签约套数  ,
				-(ISNULL(sz.数字营销产成品本周认购金额, 0) + ISNULL(qt.数字营销其他业绩产成品本周认购金额, 0) ) AS 本周产成品认购金额  ,
				-(ISNULL(sz.数字营销产成品本周认购套数, 0) + ISNULL(qt.数字营销其他业绩产成品本周认购套数, 0) ) AS 本周产成品认购套数  ,
				-ISNULL(产成品月度任务,0) as 本月产成品任务  ,
				-(ISNULL(sz.数字营销产成品本月认购金额, 0) + ISNULL(qt.数字营销其他业绩产成品本月认购金额, 0) ) AS 本月产成品认购金额  ,
				-(ISNULL(sz.数字营销产成品本月认购套数, 0) + ISNULL(qt.数字营销其他业绩产成品本月认购套数, 0) ) as 本月产成品认购套数  ,
				-ISNULL(qt.数字营销其他业绩产成品本月认购金额, 0) as 其他业绩产成品本月认购金额  ,
				-ISNULL(qt.数字营销其他业绩产成品本月认购套数, 0) as 其他业绩产成品本月认购套数  ,
				NULL as 本月产成品认购完成率  , 
				-ISNULL(sz.数字营销产成品本月签约金额, 0) as 本月产成品签约金额  ,
				-ISNULL(sz.数字营销产成品本月签约套数, 0) as 本月产成品签约套数  ,
				-ISNULL(qt.数字营销其他业绩产成品本月签约金额, 0) as 其他业绩产成品本月签约金额  ,  
				-ISNULL(qt.数字营销其他业绩产成品本月签约套数, 0) as 其他业绩产成品本月签约套数  ,
				NULL as 本月产成品签约完成率  ,
				NULL as 本月产成品签约完成率_含其他业绩  ,
				-ISNULL(sz.数字营销产成品已认购未签约金额, 0) as 累计产成品已认购未签约金额  ,
				-ISNULL(sz.数字营销产成品已认购未签约套数, 0) as 累计产成品已认购未签约套数  ,
				-ISNULL(rw.产成品年度任务,0) as 本年产成品任务  ,
				-( ISNULL(sz.数字营销产成品本年认购金额, 0) + ISNULL(qt.数字营销其他业绩产成品本年认购金额, 0) )  as 本年产成品认购金额  ,
				-( ISNULL(sz.数字营销产成品本年认购套数, 0) + ISNULL(qt.数字营销其他业绩产成品本年认购套数, 0) ) as 本年产成品认购套数  ,
				-ISNULL(sz.数字营销产成品本年签约金额, 0) as 本年产成品签约金额  ,
				-ISNULL(sz.数字营销产成品本年签约套数, 0) as 本年产成品签约套数  ,
				-ISNULL(qt.数字营销其他业绩产成品本年签约金额, 0)  as 其他业绩产成品本年签约金额  ,
				-ISNULL(qt.数字营销其他业绩产成品本年签约套数, 0)  as 其他业绩产成品本年签约套数  ,
				NULL as 本年产成品签约完成率  ,
				NULL as 本年产成品签约完成率_含其他业绩,
				null  AS 非项目本年实际签约金额,
				null  AS 非项目本月实际签约金额,
				null  AS 非项目本年实际认购金额,
				null  AS 非项目本月实际认购金额,
				-- 20240604 chenjw 新增面积类字段
				0 AS 本日认购面积 ,
				0 AS 本日签约面积 ,
				0 AS 本周认购面积 ,
				-ISNULL(sz.数字营销本周签约套数,0) AS 本周签约套数 ,
				0 AS 本周签约面积 ,
				-ISNULL(sz.数字营销本周签约金额,0) AS 本周签约金额 ,
				0 AS 本月认购面积 ,
				0 AS 本月签约面积 ,
				0 AS 其他业绩本月认购面积 ,
				0 AS 其他业绩本月签约面积 ,
				0 AS 本月产成品认购面积 ,
				0 AS 本月产成品签约面积 ,
				0 AS 其他业绩产成品本月签约面积 ,
				0 AS 已认购未签约签约面积 ,
				0 AS 本年认购面积 ,
				0 AS 本年签约面积 ,
				0 AS 其他业绩本年认购套数 ,
				0 AS 其他业绩本年认购面积 ,
				0 AS 其他业绩本年认购金额 ,
				0 AS 其他业绩本年签约面积 ,
				0 AS 本年产成品认购面积 ,
				0 AS 本年产成品签约面积 ,
				0 AS 其他业绩产成品本年签约面积,
                @wideTableDateText  as 宽表最后清洗日期,
                --大户型
                0 as 本日大户型认购金额,
                0 as 本日大户型认购面积,
                0 as 本日大户型认购套数,
                0 as 本日大户型签约金额,
                0 as 本日大户型签约面积,
                0 as 本日大户型签约套数,

                0 as 本周大户型认购金额,
                0 as 本周大户型认购面积,
                0 as 本周大户型认购套数,
                0 as 本周大户型签约金额,
                0 as 本周大户型签约面积,
                0 as 本周大户型签约套数,

                0 as 本月大户型认购金额,
                0 as 本月大户型认购面积,
                0 as 本月大户型认购套数,
                0 as 本月大户型签约金额,
                0 as 本月大户型签约面积,
                0 as 本月大户型签约套数,

                0 as 本年大户型认购金额,
                0 as 本年大户型认购面积,
                0 as 本年大户型认购套数,
                0 as 本年大户型签约金额,
                0 as 本年大户型签约面积,
                0 as 本年大户型签约套数,

                0 as 累计大户型已认购未签约金额,
                0 as 累计大户型已认购未签约面积,
                0 as 累计大户型已认购未签约套数,
                0 as 本年大户型已认购未签约金额,
                0 as 本年大户型已认购未签约套数,
                0 as 本月大户型已认购未签约金额,
                0 as 本月大户型已认购未签约套数,

                --联动房
                0 as 本日联动房认购金额,
                0 as 本日联动房认购面积,
                0 as 本日联动房认购套数,
                0 as 本日联动房签约金额,
                0 as 本日联动房签约面积,
                0 as 本日联动房签约套数,

                0 as 本周联动房认购金额,
                0 as 本周联动房认购面积,
                0 as 本周联动房认购套数,
                0 as 本周联动房签约金额,
                0 as 本周联动房签约面积,
                0 as 本周联动房签约套数,

                0 as 本月联动房认购金额,
                0 as 本月联动房认购面积,
                0 as 本月联动房认购套数,
                0 as 本月联动房签约金额,
                0 as 本月联动房签约面积,
                0 as 本月联动房签约套数,

                0 as 本年联动房认购金额,
                0 as 本年联动房认购面积,
                0 as 本年联动房认购套数,
                0 as 本年联动房签约金额,
                0 as 本年联动房签约面积,
                0 as 本年联动房签约套数,

                0 AS 累计联动房已认购未签约金额,
                0 AS 累计联动房已认购未签约面积,
                0 AS 累计联动房已认购未签约套数,
                0 AS 本年联动房已认购未签约金额,
                0 AS 本年联动房已认购未签约套数,
                0 AS 本月联动房已认购未签约金额,
                0 AS 本月联动房已认购未签约套数,

                0 as 其他业绩大户型本月签约金额,
                0 as 其他业绩大户型本月签约面积,
                0 as 其他业绩大户型本月签约套数,
                0 as 其他业绩大户型本年签约金额,
                0 as 其他业绩大户型本年签约面积,
                0 as 其他业绩大户型本年签约套数,

                --准产成品
                -(ISNULL(sz.数字营销准产成品本日认购金额, 0) + ISNULL(qt.数字营销其他业绩准产成品本日认购金额, 0))  as 本日准产成品认购金额  , 
                -(ISNULL(sz.数字营销准产成品本日认购面积, 0) + ISNULL(qt.数字营销其他业绩准产成品本日认购面积, 0))  as 本日准产成品认购面积  ,
				-(ISNULL(sz.数字营销准产成品本日认购套数, 0) + ISNULL(qt.数字营销其他业绩准产成品本日认购套数, 0))  as 本日准产成品认购套数  ,

				-(ISNULL(sz.数字营销准产成品本日签约金额, 0)) as 本日准产成品签约金额  ,
                -(ISNULL(sz.数字营销准产成品本日签约面积, 0)) as 本日准产成品签约面积  ,
				-(ISNULL(sz.数字营销准产成品本日签约套数, 0)) as 本日准产成品签约套数  ,

				-(ISNULL(sz.数字营销准产成品本周认购金额, 0) + ISNULL(qt.数字营销其他业绩准产成品本周认购金额, 0)) as 本周准产成品认购金额  ,
                -(ISNULL(sz.数字营销准产成品本周认购面积, 0) + ISNULL(qt.数字营销其他业绩准产成品本周认购面积, 0)) as 本周准产成品认购面积  ,
				-(ISNULL(sz.数字营销准产成品本周认购套数, 0) + ISNULL(qt.数字营销其他业绩准产成品本周认购套数, 0)) as 本周准产成品认购套数  ,

				-(ISNULL(sz.数字营销准产成品本月认购金额, 0) + ISNULL(qt.数字营销其他业绩准产成品本月认购金额, 0)) as 本月准产成品认购金额  ,
                -(ISNULL(sz.数字营销准产成品本月认购面积, 0) + ISNULL(qt.数字营销其他业绩准产成品本月认购面积, 0)) as 本月准产成品认购面积  ,
				-(ISNULL(sz.数字营销准产成品本月认购套数, 0) + ISNULL(qt.数字营销其他业绩准产成品本月认购套数, 0)) as 本月准产成品认购套数  ,

				-(ISNULL(qt.数字营销其他业绩准产成品本月认购金额, 0)) as 其他业绩准产成品本月认购金额  ,
                -(ISNULL(qt.数字营销其他业绩准产成品本月认购面积, 0)) as 其他业绩准产成品本月认购面积  ,
				-(ISNULL(qt.数字营销其他业绩准产成品本月认购套数, 0)) as 其他业绩准产成品本月认购套数  ,

				-(ISNULL(sz.数字营销准产成品本月签约金额, 0)) as 本月准产成品签约金额  ,
                -(ISNULL(sz.数字营销准产成品本月签约面积, 0)) as 本月准产成品签约面积  ,
				-(ISNULL(sz.数字营销准产成品本月签约套数, 0)) as 本月准产成品签约套数  ,

				-(ISNULL(qt.数字营销其他业绩准产成品本月签约金额, 0)) as 其他业绩准产成品本月签约金额  ,  
                -(ISNULL(qt.数字营销其他业绩准产成品本月签约面积, 0)) as 其他业绩准产成品本月签约面积  ,
				-(ISNULL(qt.数字营销其他业绩准产成品本月签约套数, 0)) as 其他业绩准产成品本月签约套数  ,

				-(ISNULL(sz.数字营销准产成品已认购未签约金额, 0)) as 累计准产成品已认购未签约金额  ,
                -(ISNULL(sz.数字营销准产成品已认购未签约面积, 0)) as 累计准产成品已认购未签约面积  ,
				-(ISNULL(sz.数字营销准产成品已认购未签约套数, 0)) as 累计准产成品已认购未签约套数  ,

				-(ISNULL(sz.数字营销准产成品本年认购金额, 0) + ISNULL(qt.数字营销其他业绩准产成品本年认购金额, 0)) as 本年准产成品认购金额  ,
                -(ISNULL(sz.数字营销准产成品本年认购面积, 0) + ISNULL(qt.数字营销其他业绩准产成品本年认购面积, 0)) as 本年准产成品认购面积  ,
				-(ISNULL(sz.数字营销准产成品本年认购套数, 0) + ISNULL(qt.数字营销其他业绩准产成品本年认购套数, 0)) as 本年准产成品认购套数  ,

				-(ISNULL(sz.数字营销准产成品本年签约金额, 0)) as 本年准产成品签约金额  ,
                -(ISNULL(sz.数字营销准产成品本年签约面积, 0)) as 本年准产成品签约面积  ,
				-(ISNULL(sz.数字营销准产成品本年签约套数, 0)) as 本年准产成品签约套数  ,

				-(ISNULL(qt.数字营销其他业绩准产成品本年签约金额, 0))  as 其他业绩准产成品本年签约金额  ,
                -(ISNULL(qt.数字营销其他业绩准产成品本年签约面积, 0))  as 其他业绩准产成品本年签约面积  ,
				-(ISNULL(qt.数字营销其他业绩准产成品本年签约套数, 0))  as 其他业绩准产成品本年签约套数  ,

                --补充现产成品任务和大户型任务@20250630
                -ISNULL(rw.准产成品月度任务, 0) AS 准产成品月度任务,
                -ISNULL(rw.准产成品年度任务, 0) AS 准产成品年度任务,
                0 AS 大户型月度任务,
                0 AS 大户型年度任务


        FROM    data_wide_dws_mdm_Project p
                INNER JOIN #TopProduct pt ON pt.ParentProjGUID = p.ProjGUID
                LEFT JOIN data_tb_hnyx_jdfxtb rw ON rw.projguid = p.ProjGUID AND   rw.业态 = pt.TopProductTypeName
                LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
                LEFT JOIN #szyx sz ON sz.ProjGUID = p.projguid AND pt.TopProductTypeName = sz.TopProductTypeName
                LEFT JOIN #szqtqy qt ON qt.projguid = p.projguid AND   pt.TopProductTypeName = qt.TopProductTypeName
        WHERE   Level = 2 AND   p.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
        UNION ALL
        -- 组团层级-各区域名称
        SELECT  @DateText AS 数据清洗日期 ,
                '组团' AS 层级 ,
                p.BUGUID AS 公司GUID ,
                tb.营销事业部 AS 区域 ,
                tb.营销片区 ,
                p.ProjGUID AS 项目GUID ,
                ISNULL(tb.推广名称, p.SpreadName) AS 项目名称 ,
                tb.营销片区 AS 层级名称 ,
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END 层级名称显示 ,
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END AS 项目名称负责人 ,
                CASE WHEN pt.TopProductTypeName IN ('高级住宅', '住宅', '别墅') THEN '住宅' 
				     WHEN pt.TopProductTypeName IN ('地下室/车库') THEN '车位' 
					 WHEN pt.TopProductTypeName IN ('商业','公寓','写字楼','酒店','会所','企业会所') THEN  '商办'
					 ELSE '其他' END AS 业态 ,
                pt.TopProductTypeName AS 产品类型 ,
                pt.TopProductTypeGUID AS 产品类型GUID ,
                tb.城市 ,
                tb.公司 ,
                tb.投管编码 ,
                tb.项目负责人 ,
                p.BeginDate AS 项目获取日期 ,
                pt.存量增量 ,
                ISNULL(rs.本日认购金额, 0) + ISNULL(rg.本日认购金额, 0) + ISNULL(qt.其他业绩本日认购金额, 0) AS 本日认购金额 ,                          -- 全口径
                ISNULL(rs.本日认购套数, 0) + ISNULL(rg.本日认购套数, 0) + ISNULL(qt.其他业绩本日认购套数, 0) AS 本日认购套数 ,
                ISNULL(s.本日签约金额全口径, 0) AS 本日签约金额 ,
                ISNULL(s.本日签约套数全口径, 0) AS 本日签约套数 ,
                ISNULL(rs.本周认购金额, 0) + ISNULL(rg.本周认购金额, 0) + ISNULL(qt.其他业绩本周认购金额, 0) AS 本周认购金额 ,
                ISNULL(rs.本周认购套数, 0) + ISNULL(rg.本周认购套数, 0) + ISNULL(qt.其他业绩本周认购套数, 0) AS 本周认购套数 ,
                rw.月度签约任务 AS 本月任务 ,
                ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0) + ISNULL(qt.其他业绩本月认购金额, 0) + ISNULL(rw.非项目本月实际认购金额,0)  AS 本月认购金额 ,
                ISNULL(rs.本月认购套数, 0) + ISNULL(rg.本月认购套数, 0) + ISNULL(qt.其他业绩本月认购套数, 0) AS 本月认购套数 ,
				ISNULL(qt.其他业绩本月认购金额, 0) AS 其他业绩本月认购金额,
				ISNULL(qt.其他业绩本月认购套数, 0) AS 其他业绩本月认购套数,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE (ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0)+ ISNULL(qt.其他业绩本月认购金额,0) + ISNULL(rw.非项目本月实际认购金额,0)) / ISNULL(rw.月度签约任务, 0)END AS 本月认购完成率 ,
                ISNULL(本月签约金额全口径, 0) + ISNULL(rw.非项目本月实际签约金额,0) AS 本月签约金额 ,
                ISNULL(本月签约套数全口径, 0) AS 本月签约套数 ,
                ISNULL(qt.其他业绩本月签约金额, 0) AS 其他业绩本月签约金额 ,                                                                    --以客户提供其他业绩认定的房间
                ISNULL(qt.其他业绩本月签约套数, 0) AS 其他业绩本月签约套数 ,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(本月签约金额全口径, 0) +ISNULL(rw.非项目本月实际签约金额,0) ) / ISNULL(rw.月度签约任务, 0)END AS 本月签约完成率 ,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE (ISNULL(本月签约金额全口径, 0) + ISNULL(qt.其他业绩本月签约金额, 0) +  ISNULL(rw.非项目本月实际签约金额,0) ) / ISNULL(rw.月度签约任务, 0)END AS 本月签约完成率_含其他业绩 ,
                ISNULL(rw.月度签约任务, 0)  - (ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0) + ISNULL(rw.非项目本月实际认购金额,0) )  AS 本月认购金额缺口 ,  --本月任务*本月时间进度分摊比-本月认购金额
                ISNULL(rw.月度签约任务, 0)  - (ISNULL(本月签约金额全口径, 0) + ISNULL(rw.非项目本月实际签约金额,0) ) AS 本月签约金额缺口 ,
                ISNULL(pt.本月时间分摊比, 0) AS 本月时间分摊比 ,
                ISNULL(rs.累计已认购未签约金额, 0) AS 已认购未签约金额 ,
                ISNULL(rs.累计已认购未签约套数, 0) AS 已认购未签约套数 ,
                ISNULL(rw.年度签约任务, 0) AS 本年任务 ,
                ISNULL(rs.本年认购金额, 0) + ISNULL(rg.本年认购金额, 0) + ISNULL(qt.其他业绩本年认购金额, 0) + ISNULL(rw.非项目本年实际认购金额,0) AS 本年认购金额 ,
                ISNULL(rs.本年认购套数, 0) + ISNULL(rg.本年认购套数, 0) + ISNULL(qt.其他业绩本年认购套数, 0) AS 本年认购套数 ,
                ISNULL(s.本年签约金额全口径, 0) + ISNULL(rw.非项目本年实际签约金额,0) AS 本年签约金额 ,
                ISNULL(s.本年签约套数全口径, 0) AS 本年签约套数 ,
                ISNULL(qt.其他业绩本年签约金额, 0) AS 其他业绩本年签约金额 ,
                ISNULL(qt.其他业绩本年签约套数, 0) AS 其他业绩本年签约套数 ,
                CASE WHEN ISNULL(rw.年度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(s.本年签约金额全口径, 0) +ISNULL(rw.非项目本年实际签约金额,0) )  / ISNULL(rw.年度签约任务, 0)END AS 本年签约完成率 ,
                CASE WHEN ISNULL(rw.年度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(s.本年签约金额全口径, 0) + ISNULL(qt.其他业绩本年签约金额, 0) +ISNULL(rw.非项目本年实际签约金额,0) ) / ISNULL(rw.年度签约任务, 0)END AS 本年签约完成率_含其他业绩 ,
                ISNULL(rw.年度签约任务, 0)  - (ISNULL(rs.本年认购金额, 0) + ISNULL(rg.本年认购金额, 0) +ISNULL(rw.非项目本年实际认购金额,0)) AS 本年认购金额缺口 ,
                ISNULL(rw.年度签约任务, 0)  - (ISNULL(本年签约金额全口径, 0) +ISNULL(rw.非项目本年实际签约金额,0) ) AS 本年签约金额缺口 ,
                ISNULL(pt.本年时间分摊比, 0) AS 本年时间分摊比 ,
                ISNULL(rw.本年存量任务, 0) AS 本年存量任务 ,
                ISNULL(rw.本年增量任务, 0) AS 本年增量任务 ,
                ISNULL(rw.本年新增量任务, 0) AS 本年新增量任务 ,
                ISNULL(rw.本月存量任务, 0) AS 本月存量任务 ,
                ISNULL(rw.本月增量任务, 0) AS 本月增量任务 ,
                ISNULL(rw.本月新增量任务, 0) AS 本月新增量任务,
				-- 产成品
                ISNULL(rs.本日产成品认购金额, 0) + ISNULL(rg.本日产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本日认购金额, 0) AS 本日产成品认购金额 ,  
                ISNULL(rs.本日产成品认购套数, 0) + ISNULL(rg.本日产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本日认购套数, 0) AS 本日产成品认购套数 ,
                ISNULL(s.本日产成品签约金额全口径, 0) AS 本日产成品签约金额 ,
                ISNULL(s.本日产成品签约套数全口径, 0) AS 本日产成品签约套数 ,
                ISNULL(rs.本周产成品认购金额, 0) + ISNULL(rg.本周产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本周认购金额, 0) AS 本周产成品认购金额 ,
                ISNULL(rs.本周产成品认购套数, 0) + ISNULL(rg.本周产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本周认购套数, 0) AS 本周产成品认购套数 ,
                rw.产成品月度任务 AS 本月产成品任务 ,
                ISNULL(rs.本月产成品认购金额, 0) + ISNULL(rg.本月产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本月认购金额, 0) AS 本月产成品认购金额 ,
                ISNULL(rs.本月产成品认购套数, 0) + ISNULL(rg.本月产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本月认购套数, 0) AS 本月产成品认购套数 ,
				ISNULL(qt.其他业绩产成品本月认购金额, 0) AS 其他业绩产成品本月认购金额,
				ISNULL(qt.其他业绩产成品本月认购套数, 0) AS 其他业绩产成品本月认购套数,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE (ISNULL(rs.本月产成品认购金额, 0) + ISNULL(rg.本月产成品认购金额, 0)+ ISNULL(qt.其他业绩产成品本月认购金额,0)) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品认购完成率 ,
                ISNULL(本月产成品签约金额全口径, 0) AS 本月产成品签约金额 ,
                ISNULL(本月产成品签约套数全口径, 0) AS 本月产成品签约套数,
				ISNULL(qt.其他业绩产成品本月签约金额, 0) AS 其他业绩产成品本月签约金额 ,                                                                   
                ISNULL(qt.其他业绩产成品本月签约套数, 0) AS 其他业绩产成品本月签约套数 ,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE ISNULL(本月产成品签约金额全口径, 0) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品签约完成率 ,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE (ISNULL(本月产成品签约金额全口径, 0) + ISNULL(qt.其他业绩产成品本月签约金额, 0)) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品签约完成率_含其他业绩 ,
				ISNULL(rs.累计产成品已认购未签约金额, 0) AS 累计产成品已认购未签约金额 ,
                ISNULL(rs.累计产成品已认购未签约套数, 0) AS 累计产成品已认购未签约套数 ,

				ISNULL(rw.产成品年度任务,0)  AS  本年产成品任务,
                ISNULL(rs.本年产成品认购金额, 0) + ISNULL(rg.本年产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本年认购金额, 0) AS 本年产成品认购金额 ,
                ISNULL(rs.本年产成品认购套数, 0) + ISNULL(rg.本年产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本年认购套数, 0) AS 本年产成品认购套数 ,
                ISNULL(s.本年产成品签约金额全口径, 0) AS 本年产成品签约金额 ,
                ISNULL(s.本年产成品签约套数全口径, 0) AS 本年产成品签约套数 ,
                ISNULL(qt.其他业绩产成品本年签约金额, 0) AS 其他业绩产成品本年签约金额 ,
                ISNULL(qt.其他业绩产成品本年签约套数, 0) AS 其他业绩产成品本年签约套数 ,
                CASE WHEN ISNULL(rw.产成品年度任务, 0) = 0 THEN 0 ELSE ISNULL(s.本年产成品签约金额全口径, 0) / ISNULL(rw.产成品年度任务, 0)END AS 本年产成品签约完成率 ,
                CASE WHEN ISNULL(rw.产成品年度任务, 0) = 0 THEN 0 ELSE (ISNULL(s.本年产成品签约金额全口径, 0) + ISNULL(qt.其他业绩产成品本年签约金额, 0)) / ISNULL(rw.产成品年度任务, 0)END AS 本年产成品签约完成率_含其他业绩 , 
				ISNULL(rw.非项目本年实际签约金额,0 ) AS 非项目本年实际签约金额,
				ISNULL(rw.非项目本月实际签约金额,0 ) AS 非项目本月实际签约金额,
				ISNULL(rw.非项目本年实际认购金额,0 ) AS 非项目本年实际认购金额,
				ISNULL(rw.非项目本月实际认购金额,0 ) AS 非项目本月实际认购金额,
			    -- 20240604 chenjw 新增面积类字段
				0 AS 本日认购面积 ,
				0 AS 本日签约面积 ,
				0 AS 本周认购面积 ,
				0 AS 本周签约套数 ,
				0 AS 本周签约面积 ,
				0 AS 本周签约金额 ,
				0 AS 本月认购面积 ,
				0 AS 本月签约面积 ,
				0 AS 其他业绩本月认购面积 ,
				0 AS 其他业绩本月签约面积 ,
				0 AS 本月产成品认购面积 ,
				0 AS 本月产成品签约面积 ,
				0 AS 其他业绩产成品本月签约面积 ,
				0 AS 已认购未签约签约面积 ,
				0 AS 本年认购面积 ,
				0 AS 本年签约面积 ,
				0 AS 其他业绩本年认购套数 ,
				0 AS 其他业绩本年认购面积 ,
				0 AS 其他业绩本年认购金额 ,
				0 AS 其他业绩本年签约面积 ,
				0 AS 本年产成品认购面积 ,
				0 AS 本年产成品签约面积 ,
				0 AS 其他业绩产成品本年签约面积,
                @wideTableDateText  as 宽表最后清洗日期,
                --大户型
                ISNULL(rs.本日大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本日认购金额, 0) as 本日大户型认购金额,
                ISNULL(rs.本日大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本日认购面积, 0)  as 本日大户型认购面积,
                ISNULL(rs.本日大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本日认购套数, 0)  as 本日大户型认购套数,
                ISNULL(dhx.本日大户型签约金额全口径, 0)   as 本日大户型签约金额,
                ISNULL(dhx.本日大户型签约面积全口径, 0)  as 本日大户型签约面积,
                ISNULL(dhx.本日大户型签约套数全口径, 0)  as 本日大户型签约套数,

                ISNULL(rs.本周大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本周认购金额, 0) as 本周大户型认购金额,
                ISNULL(rs.本周大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本周认购面积, 0) as 本周大户型认购面积,
                ISNULL(rs.本周大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本周认购套数, 0) as 本周大户型认购套数,
                ISNULL(dhx.本周大户型签约金额全口径, 0) as 本周大户型签约金额,
                ISNULL(dhx.本周大户型签约面积全口径, 0) as 本周大户型签约面积,
                ISNULL(dhx.本周大户型签约套数全口径, 0) as 本周大户型签约套数,

                ISNULL(rs.本月大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本月认购金额, 0) as 本月大户型认购金额,
                ISNULL(rs.本月大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本月认购面积, 0) as 本月大户型认购面积,
                ISNULL(rs.本月大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本月认购套数, 0) as 本月大户型认购套数,
                ISNULL(dhx.本月大户型签约金额全口径,0) + ISNULL(qt.其他业绩大户型本月签约金额,0) as 本月大户型签约金额,
                ISNULL(dhx.本月大户型签约面积全口径,0) + ISNULL(qt.其他业绩大户型本月签约面积,0) as 本月大户型签约面积,
                ISNULL(dhx.本月大户型签约套数全口径,0) + ISNULL(qt.其他业绩大户型本月签约套数,0) as 本月大户型签约套数,

                ISNULL(rs.本年大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本年认购金额, 0) as 本年大户型认购金额,
                ISNULL(rs.本年大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本年认购面积, 0) as 本年大户型认购面积,
                ISNULL(rs.本年大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本年认购套数, 0) as 本年大户型认购套数,
                ISNULL(dhx.本年大户型签约金额全口径,0) + ISNULL(qt.其他业绩大户型本年签约金额,0) as 本年大户型签约金额,
                ISNULL(dhx.本年大户型签约面积全口径,0) + ISNULL(qt.其他业绩大户型本年签约面积,0) as 本年大户型签约面积,
                ISNULL(dhx.本年大户型签约套数全口径,0) + ISNULL(qt.其他业绩大户型本年签约套数,0) as 本年大户型签约套数,

                ISNULL(rs.累计大户型已认购未签约金额,0) as 累计大户型已认购未签约金额,
                ISNULL(rs.累计大户型已认购未签约面积,0) as 累计大户型已认购未签约面积,
                ISNULL(rs.累计大户型已认购未签约套数,0) as 累计大户型已认购未签约套数,
                ISNULL(rs.本年大户型已认购未签约金额,0) as 本年大户型已认购未签约金额,
                ISNULL(rs.本年大户型已认购未签约套数,0) as 本年大户型已认购未签约套数,
                ISNULL(rs.本月大户型已认购未签约金额,0) as 本月大户型已认购未签约金额,
                ISNULL(rs.本月大户型已认购未签约套数,0) as 本月大户型已认购未签约套数,

                --联动房
                ISNULL(rs.本日联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本日认购金额, 0) as 本日联动房认购金额,
                ISNULL(rs.本日联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本日认购面积, 0)  as 本日联动房认购面积,
                ISNULL(rs.本日联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本日认购套数, 0)  as 本日联动房认购套数,
                ISNULL(dhx.本日联动房签约金额全口径, 0)   as 本日联动房签约金额,
                ISNULL(dhx.本日联动房签约面积全口径, 0)  as 本日联动房签约面积,
                ISNULL(dhx.本日联动房签约套数全口径, 0)  as 本日联动房签约套数,

                ISNULL(rs.本周联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本周认购金额, 0) as 本周联动房认购金额,
                ISNULL(rs.本周联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本周认购面积, 0) as 本周联动房认购面积,
                ISNULL(rs.本周联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本周认购套数, 0) as 本周联动房认购套数,
                ISNULL(dhx.本周联动房签约金额全口径, 0) as 本周联动房签约金额,
                ISNULL(dhx.本周联动房签约面积全口径, 0) as 本周联动房签约面积,
                ISNULL(dhx.本周联动房签约套数全口径, 0) as 本周联动房签约套数,

                ISNULL(rs.本月联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本月认购金额, 0) as 本月联动房认购金额,
                ISNULL(rs.本月联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本月认购面积, 0) as 本月联动房认购面积,
                ISNULL(rs.本月联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本月认购套数, 0) as 本月联动房认购套数,
                ISNULL(dhx.本月联动房签约金额全口径,0) + ISNULL(qt.其他业绩联动房本月签约金额,0) as 本月联动房签约金额,
                ISNULL(dhx.本月联动房签约面积全口径,0) + ISNULL(qt.其他业绩联动房本月签约面积,0) as 本月联动房签约面积,
                ISNULL(dhx.本月联动房签约套数全口径,0) + ISNULL(qt.其他业绩联动房本月签约套数,0) as 本月联动房签约套数,

                ISNULL(rs.本年联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本年认购金额, 0) as 本年联动房认购金额,
                ISNULL(rs.本年联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本年认购面积, 0) as 本年联动房认购面积,
                ISNULL(rs.本年联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本年认购套数, 0) as 本年联动房认购套数,
                ISNULL(dhx.本年联动房签约金额全口径,0) + ISNULL(qt.其他业绩联动房本年签约金额,0) as 本年联动房签约金额,
                ISNULL(dhx.本年联动房签约面积全口径,0) + ISNULL(qt.其他业绩联动房本年签约面积,0) as 本年联动房签约面积,
                ISNULL(dhx.本年联动房签约套数全口径,0) + ISNULL(qt.其他业绩联动房本年签约套数,0) as 本年联动房签约套数,

                ISNULL(rs.累计联动房已认购未签约金额,0) AS 累计联动房已认购未签约金额,
                ISNULL(rs.累计联动房已认购未签约面积,0) AS 累计联动房已认购未签约面积,
                ISNULL(rs.累计联动房已认购未签约套数,0) AS 累计联动房已认购未签约套数,
                ISNULL(rs.本年联动房已认购未签约金额,0) AS 本年联动房已认购未签约金额,
                ISNULL(rs.本年联动房已认购未签约套数,0) AS 本年联动房已认购未签约套数,
                ISNULL(rs.本月联动房已认购未签约金额,0) AS 本月联动房已认购未签约金额,
                ISNULL(rs.本月联动房已认购未签约套数,0) AS 本月联动房已认购未签约套数,

                ISNULL(qt.其他业绩大户型本月签约金额,0) as 其他业绩大户型本月签约金额,
                ISNULL(qt.其他业绩大户型本月签约面积,0) as 其他业绩大户型本月签约面积,
                ISNULL(qt.其他业绩大户型本月签约套数,0) as 其他业绩大户型本月签约套数,
                ISNULL(qt.其他业绩大户型本年签约金额,0) as 其他业绩大户型本年签约金额,
                ISNULL(qt.其他业绩大户型本年签约面积,0) as 其他业绩大户型本年签约面积,
                ISNULL(qt.其他业绩大户型本年签约套数,0) as 其他业绩大户型本年签约套数,

                --准产成品
                ISNULL(rs.本日准产成品认购金额, 0) + ISNULL(rg.本日准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本日认购金额, 0) AS 本日准产成品认购金额,
                ISNULL(rs.本日准产成品认购面积, 0) + ISNULL(rg.本日准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本日认购面积, 0) AS 本日准产成品认购面积,
                ISNULL(rs.本日准产成品认购套数, 0) + ISNULL(rg.本日准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本日认购套数, 0) AS 本日准产成品认购套数 ,

                ISNULL(s.本日准产成品签约金额全口径, 0) AS 本日准产成品签约金额 ,
                ISNULL(s.本日准产成品签约面积全口径, 0) AS 本日准产成品签约面积 ,
                ISNULL(s.本日准产成品签约套数全口径, 0) AS 本日准产成品签约套数 ,

                ISNULL(rs.本周准产成品认购金额, 0) + ISNULL(rg.本周准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本周认购金额, 0) AS 本周准产成品认购金额 ,
                ISNULL(rs.本周准产成品认购面积, 0) + ISNULL(rg.本周准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本周认购面积, 0) AS 本周准产成品认购面积 ,
                ISNULL(rs.本周准产成品认购套数, 0) + ISNULL(rg.本周准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本周认购套数, 0) AS 本周准产成品认购套数 ,

                ISNULL(rs.本月准产成品认购金额, 0) + ISNULL(rg.本月准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本月认购金额, 0) AS 本月准产成品认购金额 ,
                ISNULL(rs.本月准产成品认购面积, 0) + ISNULL(rg.本月准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本月认购面积, 0) AS 本月准产成品认购面积 ,
                ISNULL(rs.本月准产成品认购套数, 0) + ISNULL(rg.本月准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本月认购套数, 0) AS 本月准产成品认购套数 ,

                ISNULL(qt.其他业绩准产成品本月认购金额, 0) AS 其他业绩准产成品本月认购金额 ,
                ISNULL(qt.其他业绩准产成品本月认购面积, 0) AS 其他业绩准产成品本月认购面积 ,
                ISNULL(qt.其他业绩准产成品本月认购套数, 0) AS 其他业绩准产成品本月认购套数 ,

                ISNULL(本月准产成品签约金额全口径, 0) AS 本月准产成品签约金额 ,
                ISNULL(本月准产成品签约面积全口径, 0) AS 本月准产成品签约面积 ,
                ISNULL(本月准产成品签约套数全口径, 0) AS 本月准产成品签约套数 ,

                ISNULL(qt.其他业绩准产成品本月签约金额, 0) AS 其他业绩准产成品本月签约金额 ,
                ISNULL(qt.其他业绩准产成品本月签约面积, 0) AS 其他业绩准产成品本月签约面积 ,
                ISNULL(qt.其他业绩准产成品本月签约套数, 0) AS 其他业绩准产成品本月签约套数 ,

                ISNULL(rs.累计准产成品已认购未签约金额, 0) AS 累计准产成品已认购未签约金额 ,
                ISNULL(rs.累计准产成品已认购未签约面积, 0) AS 累计准产成品已认购未签约面积 ,
                ISNULL(rs.累计准产成品已认购未签约套数, 0) AS 累计准产成品已认购未签约套数 ,

                ISNULL(rs.本年准产成品认购金额, 0) + ISNULL(rg.本年准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本年认购金额, 0) AS 本年准产成品认购金额 ,
                ISNULL(rs.本年准产成品认购面积, 0) + ISNULL(rg.本年准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本年认购面积, 0) AS 本年准产成品认购面积 ,
                ISNULL(rs.本年准产成品认购套数, 0) + ISNULL(rg.本年准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本年认购套数, 0) AS 本年准产成品认购套数 ,

                ISNULL(s.本年准产成品签约金额全口径, 0) AS 本年准产成品签约金额 ,
                ISNULL(s.本年准产成品签约面积全口径, 0) AS 本年准产成品签约面积 ,
                ISNULL(s.本年准产成品签约套数全口径, 0) AS 本年准产成品签约套数 ,
                ISNULL(qt.其他业绩准产成品本年签约金额, 0) AS 其他业绩准产成品本年签约金额 ,
                ISNULL(qt.其他业绩准产成品本年签约面积, 0) AS 其他业绩准产成品本年签约面积 ,                
                ISNULL(qt.其他业绩准产成品本年签约套数, 0) AS 其他业绩准产成品本年签约套数 ,

                --补充现产成品任务和大户型任务@20250630
                ISNULL(rw.准产成品月度任务, 0) AS 准产成品月度任务,
                ISNULL(rw.准产成品年度任务, 0) AS 准产成品年度任务,
                ISNULL(rw.大户型月度任务, 0)   AS 大户型月度任务,
                ISNULL(rw.大户型年度任务, 0)   AS 大户型年度任务
        FROM    data_wide_dws_mdm_Project p
                INNER JOIN #TopProduct pt ON pt.ParentProjGUID = p.ProjGUID
                LEFT JOIN data_tb_hnyx_jdfxtb rw ON rw.projguid = p.ProjGUID AND   rw.业态 = pt.TopProductTypeName
                LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
                LEFT JOIN #projsale s ON p.ProjGUID = s.orgguid AND pt.TopProductTypeName = s.TopProductTypeName
                LEFT JOIN #projsale_ldf_dhx dhx on p.ProjGUID = dhx.orgguid AND pt.TopProductTypeName = dhx.TopProductTypeName
                LEFT JOIN #rsale rs ON rs.ProjGUID = p.ProjGUID AND pt.TopProductTypeName = rs.TopProductTypeName
                LEFT JOIN #rg rg ON rg.ProjGUID = p.ProjGUID AND   pt.TopProductTypeName = rg.TopProductTypeName
                LEFT JOIN #qtqy qt ON qt.projguid = p.projguid AND pt.TopProductTypeName = qt.TopProductTypeName
        WHERE   Level = 2 AND   p.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
        UNION ALL
        -- 区域层级增加 数字营销的单独统计
        SELECT  @DateText AS 数据清洗日期 ,
                '组团' AS 层级 ,
                p.BUGUID AS 公司GUID ,
                '数字营销' AS 区域 ,
                '数字营销' AS 营销片区 ,
                p.ProjGUID AS 项目GUID ,
                ISNULL(tb.推广名称, p.SpreadName) AS 项目名称 ,
                '数字营销' AS 层级名称 ,
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END AS 层级名称显示 ,
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END AS 项目名称负责人 ,
                CASE WHEN pt.TopProductTypeName IN ('高级住宅', '住宅', '别墅') THEN '住宅' 
				     WHEN pt.TopProductTypeName IN ('地下室/车库') THEN '车位' 
					 WHEN pt.TopProductTypeName IN ('商业','公寓','写字楼','酒店','会所','企业会所') THEN  '商办'
					 ELSE '其他' END AS 业态 ,
                pt.TopProductTypeName AS 产品类型 ,
                pt.TopProductTypeGUID AS 产品类型GUID ,
                tb.城市 ,
                tb.公司 ,
                tb.投管编码 ,
                tb.项目负责人 ,
                p.BeginDate AS 项目获取日期 ,
                pt.存量增量 ,
                ISNULL(sz.数字营销本日认购金额, 0) + ISNULL(qt.数字营销其他业绩本日认购金额, 0) AS 本日认购金额 ,                                                         -- 全口径
                ISNULL(sz.数字营销本日认购套数, 0) + ISNULL(qt.数字营销其他业绩本日认购套数, 0) AS 本日认购套数 ,
                ISNULL(sz.数字营销本日签约金额, 0) AS 本日签约金额 ,
                ISNULL(sz.数字营销本日签约套数, 0) AS 本日签约套数 ,
                ISNULL(sz.数字营销本周认购金额, 0) + ISNULL(qt.数字营销其他业绩本周认购金额, 0) AS 本周认购金额 ,
                ISNULL(sz.数字营销本周认购套数, 0) + ISNULL(qt.数字营销其他业绩本周认购套数, 0) AS 本周认购套数 ,
                rw.数字营销月度任务 AS 本月任务 ,
                ISNULL(sz.数字营销本月认购金额, 0) + ISNULL(qt.数字营销其他业绩本月认购金额, 0) AS 本月认购金额 ,
                ISNULL(sz.数字营销本月认购套数, 0) + ISNULL(qt.数字营销其他业绩本月认购套数, 0) AS 本月认购套数 ,
				ISNULL(qt.数字营销其他业绩本月认购金额, 0) AS 数字营销其他业绩本月认购金额,
				ISNULL(qt.数字营销其他业绩本月认购套数, 0) AS 数字营销其他业绩本月认购套数,
                CASE WHEN ISNULL(rw.数字营销月度任务, 0) = 0 THEN 0 ELSE (ISNULL(sz.数字营销本月认购金额, 0) + ISNULL(qt.数字营销其他业绩本月认购金额, 0)) / ISNULL(rw.数字营销月度任务, 0)END AS 本月认购完成率 ,
                ISNULL(sz.数字营销本月签约金额, 0) AS 本月签约金额 ,
                ISNULL(sz.数字营销本月签约套数, 0) AS 本月签约套数 ,
                ISNULL(qt.数字营销其他业绩本月签约金额, 0) AS 其他业绩本月签约金额 ,                                                                                --以客户提供其他业绩认定的房间
                ISNULL(qt.数字营销其他业绩本月签约套数, 0) AS 其他业绩本月签约套数 ,
                CASE WHEN ISNULL(rw.数字营销月度任务, 0) = 0 THEN 0 ELSE ISNULL(数字营销本月签约金额, 0) / ISNULL(rw.数字营销月度任务, 0)END AS 本月签约完成率 ,
                CASE WHEN ISNULL(rw.数字营销月度任务, 0) = 0 THEN 0 ELSE (ISNULL(数字营销本月签约金额, 0) + ISNULL(qt.数字营销其他业绩本月签约金额, 0)) / ISNULL(rw.数字营销月度任务, 0)END AS 本月签约完成率_含其他业绩 ,
                ISNULL(rw.数字营销月度任务, 0)  - (ISNULL(sz.数字营销本月认购金额, 0) + ISNULL(qt.数字营销其他业绩本月认购金额, 0)) AS 本月认购金额缺口 ,    --本月任务*本月时间进度分摊比-本月认购金额
                ISNULL(rw.数字营销月度任务, 0)  - ISNULL(数字营销本月签约金额, 0) AS 本月签约金额缺口 ,
                ISNULL(pt.本月时间分摊比, 0) AS 本月时间分摊比 ,
                ISNULL(sz.数字营销已认购未签约金额, 0) AS 已认购未签约金额 ,
                ISNULL(sz.数字营销已认购未签约套数, 0) AS 已认购未签约套数 ,
                ISNULL(rw.数字营销年度任务, 0) AS 本年任务 ,
                ISNULL(sz.数字营销本年认购金额, 0) + ISNULL(qt.数字营销其他业绩本年认购金额, 0) AS 本年认购金额 ,
                ISNULL(sz.数字营销本年认购套数, 0) + ISNULL(qt.数字营销其他业绩本年认购套数, 0) AS 本年认购套数 ,
                ISNULL(sz.数字营销本年签约金额, 0) AS 本年签约金额 ,
                ISNULL(sz.数字营销本年签约套数, 0) AS 本年签约套数 ,
                ISNULL(qt.数字营销其他业绩本年签约金额, 0) AS 其他业绩本年签约金额 ,
                ISNULL(qt.数字营销其他业绩本年签约套数, 0) AS 其他业绩本年签约套数 ,
                CASE WHEN ISNULL(rw.数字营销年度任务, 0) = 0 THEN 0 ELSE ISNULL(sz.数字营销本年签约金额, 0) / ISNULL(rw.数字营销年度任务, 0)END AS 本年签约完成率 ,
                CASE WHEN ISNULL(rw.数字营销年度任务, 0) = 0 THEN 0 ELSE (ISNULL(sz.数字营销本年签约金额, 0) + ISNULL(qt.数字营销其他业绩本年签约金额, 0)) / ISNULL(rw.数字营销年度任务, 0)END AS 本年签约完成率_含其他业绩 ,
                ISNULL(rw.数字营销年度任务, 0)  - (ISNULL(sz.数字营销本年认购金额, 0) + ISNULL(qt.数字营销其他业绩本年认购金额, 0)) AS 本年认购金额缺口 ,
                ISNULL(rw.数字营销年度任务, 0)  - ISNULL(sz.数字营销本年认购金额, 0) AS 本年签约金额缺口 ,
                ISNULL(pt.本年时间分摊比, 0) AS 本年时间分摊比 ,
                ISNULL(rw.本年存量任务, 0) AS 本年存量任务 ,
                ISNULL(rw.本年增量任务, 0) AS 本年增量任务 ,
                ISNULL(rw.本年新增量任务, 0) AS 本年新增量任务 ,
                ISNULL(rw.本月存量任务, 0) AS 本月存量任务 ,
                ISNULL(rw.本月增量任务, 0) AS 本月增量任务 ,
                ISNULL(rw.本月新增量任务, 0) AS 本月新增量任务,
				-- 产成品
				ISNULL(sz.数字营销产成品本日认购金额, 0) + ISNULL(qt.数字营销其他业绩产成品本日认购金额, 0) as 本日产成品认购金额  , 
				ISNULL(sz.数字营销产成品本日认购套数, 0) + ISNULL(qt.数字营销其他业绩产成品本日认购套数, 0)  as 本日产成品认购套数  ,
				ISNULL(sz.数字营销产成品本日签约金额, 0) as 本日产成品签约金额  ,
				ISNULL(sz.数字营销产成品本日签约套数, 0) as 本日产成品签约套数  ,
				ISNULL(sz.数字营销产成品本周认购金额, 0) + ISNULL(qt.数字营销其他业绩产成品本周认购金额, 0) as 本周产成品认购金额  ,
				ISNULL(sz.数字营销产成品本周认购套数, 0) + ISNULL(qt.数字营销其他业绩产成品本周认购套数, 0) as 本周产成品认购套数  ,
				ISNULL(产成品月度任务,0) as 本月产成品任务  ,
				ISNULL(sz.数字营销产成品本月认购金额, 0) + ISNULL(qt.数字营销其他业绩产成品本月认购金额, 0) as 本月产成品认购金额  ,
				ISNULL(sz.数字营销产成品本月认购套数, 0) + ISNULL(qt.数字营销其他业绩产成品本月认购套数, 0) as 本月产成品认购套数  ,
				ISNULL(qt.数字营销其他业绩产成品本月认购金额, 0) as 其他业绩产成品本月认购金额  ,
				ISNULL(qt.数字营销其他业绩产成品本月认购套数, 0) as 其他业绩产成品本月认购套数  ,
				NULL as 本月产成品认购完成率  , 
				ISNULL(sz.数字营销产成品本月签约金额, 0) as 本月产成品签约金额  ,
				ISNULL(sz.数字营销产成品本月签约套数, 0) as 本月产成品签约套数  ,
				ISNULL(qt.数字营销其他业绩产成品本月签约金额, 0) as 其他业绩产成品本月签约金额  ,  
				ISNULL(qt.数字营销其他业绩产成品本月签约套数, 0) as 其他业绩产成品本月签约套数  ,
				NULL as 本月产成品签约完成率  ,
				NULL as 本月产成品签约完成率_含其他业绩  ,
				ISNULL(sz.数字营销产成品已认购未签约金额, 0) as 累计产成品已认购未签约金额  ,
				ISNULL(sz.数字营销产成品已认购未签约套数, 0) as 累计产成品已认购未签约套数  ,
				ISNULL(rw.产成品年度任务,0) as 本年产成品任务  ,
				ISNULL(sz.数字营销产成品本年认购金额, 0) + ISNULL(qt.数字营销其他业绩产成品本年认购金额, 0) as 本年产成品认购金额  ,
				ISNULL(sz.数字营销产成品本年认购套数, 0) + ISNULL(qt.数字营销其他业绩产成品本年认购套数, 0) as 本年产成品认购套数  ,
				ISNULL(sz.数字营销产成品本年签约金额, 0) as 本年产成品签约金额  ,
				ISNULL(sz.数字营销产成品本年签约套数, 0) as 本年产成品签约套数  ,
				ISNULL(qt.数字营销其他业绩产成品本年签约金额, 0)  as 其他业绩产成品本年签约金额  ,
				ISNULL(qt.数字营销其他业绩产成品本年签约套数, 0)  as 其他业绩产成品本年签约套数  ,
				NULL as 本年产成品签约完成率  ,
				NULL as 本年产成品签约完成率_含其他业绩,
				null  AS 非项目本年实际签约金额,
				null  AS 非项目本月实际签约金额,
				null  AS 非项目本年实际认购金额,
				null  AS 非项目本月实际认购金额,
		       -- 20240604 chenjw 新增面积类字段
				0 AS 本日认购面积 ,
				0 AS 本日签约面积 ,
				0 AS 本周认购面积 ,
				ISNULL(sz.数字营销本周签约套数,0) AS 本周签约套数 ,
				0 AS 本周签约面积 ,
				ISNULL(sz.数字营销本周签约金额,0) AS 本周签约金额 ,
				0 AS 本月认购面积 ,
				0 AS 本月签约面积 ,
				0 AS 其他业绩本月认购面积 ,
				0 AS 其他业绩本月签约面积 ,
				0 AS 本月产成品认购面积 ,
				0 AS 本月产成品签约面积 ,
				0 AS 其他业绩产成品本月签约面积 ,
				0 AS 已认购未签约签约面积 ,
				0 AS 本年认购面积 ,
				0 AS 本年签约面积 ,
				0 AS 其他业绩本年认购套数 ,
				0 AS 其他业绩本年认购面积 ,
				0 AS 其他业绩本年认购金额 ,
				0 AS 其他业绩本年签约面积 ,
				0 AS 本年产成品认购面积 ,
				0 AS 本年产成品签约面积 ,
				0 AS 其他业绩产成品本年签约面积,
                @wideTableDateText  as 宽表最后清洗日期 ,
                --大户型
                0 as 本日大户型认购金额,
                0 as 本日大户型认购面积,
                0 as 本日大户型认购套数,
                0 as 本日大户型签约金额,
                0 as 本日大户型签约面积,
                0 as 本日大户型签约套数,

                0 as 本周大户型认购金额,
                0 as 本周大户型认购面积,
                0 as 本周大户型认购套数,
                0 as 本周大户型签约金额,
                0 as 本周大户型签约面积,
                0 as 本周大户型签约套数,

                0 as 本月大户型认购金额,
                0 as 本月大户型认购面积,
                0 as 本月大户型认购套数,
                0 as 本月大户型签约金额,
                0 as 本月大户型签约面积,
                0 as 本月大户型签约套数,

                0 as 本年大户型认购金额,
                0 as 本年大户型认购面积,
                0 as 本年大户型认购套数,
                0 as 本年大户型签约金额,
                0 as 本年大户型签约面积,
                0 as 本年大户型签约套数,

                0 as 累计大户型已认购未签约金额,
                0 as 累计大户型已认购未签约面积,
                0 as 累计大户型已认购未签约套数,
                0 as 本年大户型已认购未签约金额,
                0 as 本年大户型已认购未签约套数,
                0 as 本月大户型已认购未签约金额,
                0 as 本月大户型已认购未签约套数,

                --联动房
                0 as 本日联动房认购金额,
                0 as 本日联动房认购面积,
                0 as 本日联动房认购套数,
                0 as 本日联动房签约金额,
                0 as 本日联动房签约面积,
                0 as 本日联动房签约套数,

                0 as 本周联动房认购金额,
                0 as 本周联动房认购面积,
                0 as 本周联动房认购套数,
                0 as 本周联动房签约金额,
                0 as 本周联动房签约面积,
                0 as 本周联动房签约套数,

                0 as 本月联动房认购金额,
                0 as 本月联动房认购面积,
                0 as 本月联动房认购套数,
                0 as 本月联动房签约金额,
                0 as 本月联动房签约面积,
                0 as 本月联动房签约套数,

                0 as 本年联动房认购金额,
                0 as 本年联动房认购面积,
                0 as 本年联动房认购套数,
                0 as 本年联动房签约金额,
                0 as 本年联动房签约面积,
                0 as 本年联动房签约套数,

                0 AS 累计联动房已认购未签约金额,
                0 AS 累计联动房已认购未签约面积,
                0 AS 累计联动房已认购未签约套数,
                0 AS 本年联动房已认购未签约金额,
                0 AS 本年联动房已认购未签约套数,
                0 AS 本月联动房已认购未签约金额,
                0 AS 本月联动房已认购未签约套数,

                0 as 其他业绩大户型本月签约金额,
                0 as 其他业绩大户型本月签约面积,
                0 as 其他业绩大户型本月签约套数,
                0 as 其他业绩大户型本年签约金额,
                0 as 其他业绩大户型本年签约面积,
                0 as 其他业绩大户型本年签约套数,

                --准产成品
                ISNULL(sz.数字营销准产成品本日认购金额, 0) + ISNULL(qt.数字营销其他业绩准产成品本日认购金额, 0)  as 本日准产成品认购金额  , 
                ISNULL(sz.数字营销准产成品本日认购面积, 0) + ISNULL(qt.数字营销其他业绩准产成品本日认购面积, 0)  as 本日准产成品认购面积  ,
				ISNULL(sz.数字营销准产成品本日认购套数, 0) + ISNULL(qt.数字营销其他业绩准产成品本日认购套数, 0)  as 本日准产成品认购套数  ,

				ISNULL(sz.数字营销准产成品本日签约金额, 0) as 本日准产成品签约金额  ,
                ISNULL(sz.数字营销准产成品本日签约面积, 0) as 本日准产成品签约面积  ,
				ISNULL(sz.数字营销准产成品本日签约套数, 0) as 本日准产成品签约套数  ,

				ISNULL(sz.数字营销准产成品本周认购金额, 0) + ISNULL(qt.数字营销其他业绩准产成品本周认购金额, 0) as 本周准产成品认购金额  ,
                ISNULL(sz.数字营销准产成品本周认购面积, 0) + ISNULL(qt.数字营销其他业绩准产成品本周认购面积, 0) as 本周准产成品认购面积  ,
				ISNULL(sz.数字营销准产成品本周认购套数, 0) + ISNULL(qt.数字营销其他业绩准产成品本周认购套数, 0) as 本周准产成品认购套数  ,

				ISNULL(sz.数字营销准产成品本月认购金额, 0) + ISNULL(qt.数字营销其他业绩准产成品本月认购金额, 0) as 本月准产成品认购金额  ,
                ISNULL(sz.数字营销准产成品本月认购面积, 0) + ISNULL(qt.数字营销其他业绩准产成品本月认购面积, 0) as 本月准产成品认购面积  ,
				ISNULL(sz.数字营销准产成品本月认购套数, 0) + ISNULL(qt.数字营销其他业绩准产成品本月认购套数, 0) as 本月准产成品认购套数  ,

				ISNULL(qt.数字营销其他业绩准产成品本月认购金额, 0) as 其他业绩准产成品本月认购金额  ,
                ISNULL(qt.数字营销其他业绩准产成品本月认购面积, 0) as 其他业绩准产成品本月认购面积  ,
				ISNULL(qt.数字营销其他业绩准产成品本月认购套数, 0) as 其他业绩准产成品本月认购套数  ,

				ISNULL(sz.数字营销准产成品本月签约金额, 0) as 本月准产成品签约金额  ,
                ISNULL(sz.数字营销准产成品本月签约面积, 0) as 本月准产成品签约面积  ,
				ISNULL(sz.数字营销准产成品本月签约套数, 0) as 本月准产成品签约套数  ,

				ISNULL(qt.数字营销其他业绩准产成品本月签约金额, 0) as 其他业绩准产成品本月签约金额  ,  
                ISNULL(qt.数字营销其他业绩准产成品本月签约面积, 0) as 其他业绩准产成品本月签约面积  ,
				ISNULL(qt.数字营销其他业绩准产成品本月签约套数, 0) as 其他业绩准产成品本月签约套数  ,

				ISNULL(sz.数字营销准产成品已认购未签约金额, 0) as 累计准产成品已认购未签约金额  ,
                ISNULL(sz.数字营销准产成品已认购未签约面积, 0) as 累计准产成品已认购未签约面积  ,
				ISNULL(sz.数字营销准产成品已认购未签约套数, 0) as 累计准产成品已认购未签约套数  ,

				ISNULL(sz.数字营销准产成品本年认购金额, 0) + ISNULL(qt.数字营销其他业绩准产成品本年认购金额, 0) as 本年准产成品认购金额  ,
                ISNULL(sz.数字营销准产成品本年认购面积, 0) + ISNULL(qt.数字营销其他业绩准产成品本年认购面积, 0) as 本年准产成品认购面积  ,
				ISNULL(sz.数字营销准产成品本年认购套数, 0) + ISNULL(qt.数字营销其他业绩准产成品本年认购套数, 0) as 本年准产成品认购套数  ,

				ISNULL(sz.数字营销准产成品本年签约金额, 0) as 本年准产成品签约金额  ,
                ISNULL(sz.数字营销准产成品本年签约面积, 0) as 本年准产成品签约面积  ,
				ISNULL(sz.数字营销准产成品本年签约套数, 0) as 本年准产成品签约套数  ,

				ISNULL(qt.数字营销其他业绩准产成品本年签约金额, 0)  as 其他业绩准产成品本年签约金额  ,
                ISNULL(qt.数字营销其他业绩准产成品本年签约面积, 0)  as 其他业绩准产成品本年签约面积  ,
				ISNULL(qt.数字营销其他业绩准产成品本年签约套数, 0)  as 其他业绩准产成品本年签约套数  ,

                --补充现产成品任务和大户型任务@20250630
                ISNULL(rw.准产成品月度任务, 0) AS 准产成品月度任务,
                ISNULL(rw.准产成品年度任务, 0) AS 准产成品年度任务,
                0 AS 大户型月度任务,
                0 AS 大户型年度任务
        FROM    data_wide_dws_mdm_Project p
                INNER JOIN #TopProduct pt ON pt.ParentProjGUID = p.ProjGUID
                LEFT JOIN data_tb_hnyx_jdfxtb rw ON rw.projguid = p.ProjGUID AND   rw.业态 = pt.TopProductTypeName
                LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
                LEFT JOIN #szyx sz ON sz.ProjGUID = p.projguid AND pt.TopProductTypeName = sz.TopProductTypeName
                LEFT JOIN #szqtqy qt ON qt.projguid = p.projguid AND   pt.TopProductTypeName = qt.TopProductTypeName
        WHERE   Level = 2 AND   p.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
       
	   -- 项目层级-全部项目
        UNION ALL
        SELECT  @DateText AS 数据清洗日期 ,
                '项目' AS 层级 ,
                p.BUGUID AS 公司GUID ,
                tb.营销事业部 AS 区域 ,
                tb.营销片区 ,
                p.ProjGUID AS 项目GUID ,
                ISNULL(tb.推广名称, p.SpreadName) AS 项目名称 ,
                '全部项目' AS 层级名称 ,
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END 层级名称显示 ,
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END AS 项目名称负责人 ,
                CASE WHEN pt.TopProductTypeName IN ('高级住宅', '住宅', '别墅') THEN '住宅' 
				     WHEN pt.TopProductTypeName IN ('地下室/车库') THEN '车位' 
					 WHEN pt.TopProductTypeName IN ('商业','公寓','写字楼','酒店','会所','企业会所') THEN  '商办'
					 ELSE '其他' END AS 业态 ,
                pt.TopProductTypeName AS 产品类型 ,
                pt.TopProductTypeGUID AS 产品类型GUID ,
                tb.城市 ,
                tb.公司 ,
                tb.投管编码 ,
                tb.项目负责人 ,
                p.BeginDate AS 项目获取日期 ,
                pt.存量增量 ,
                ISNULL(rs.本日认购金额, 0) + ISNULL(rg.本日认购金额, 0) + ISNULL(qt.其他业绩本日认购金额, 0) AS 本日认购金额 ,                          -- 全口径
                ISNULL(rs.本日认购套数, 0) + ISNULL(rg.本日认购套数, 0) + ISNULL(qt.其他业绩本日认购套数, 0) AS 本日认购套数 ,
                ISNULL(s.本日签约金额全口径, 0) AS 本日签约金额 ,
                ISNULL(s.本日签约套数全口径, 0) AS 本日签约套数 ,
                ISNULL(rs.本周认购金额, 0) + ISNULL(rg.本周认购金额, 0) + ISNULL(qt.其他业绩本周认购金额, 0) AS 本周认购金额 ,
                ISNULL(rs.本周认购套数, 0) + ISNULL(rg.本周认购套数, 0) + ISNULL(qt.其他业绩本周认购套数, 0) AS 本周认购套数 ,
                rw.月度签约任务 AS 本月任务 ,
                ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0) + ISNULL(qt.其他业绩本月认购金额, 0) + ISNULL(rw.非项目本月实际认购金额,0)  AS 本月认购金额 ,
                ISNULL(rs.本月认购套数, 0) + ISNULL(rg.本月认购套数, 0) + ISNULL(qt.其他业绩本月认购套数, 0) AS 本月认购套数 ,
				ISNULL(qt.其他业绩本月认购金额, 0) AS 其他业绩本月认购金额,
				ISNULL(qt.其他业绩本月认购套数, 0) AS 其他业绩本月认购套数,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE (ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0)+ ISNULL(qt.其他业绩本月认购金额,0) + ISNULL(rw.非项目本月实际认购金额,0)) / ISNULL(rw.月度签约任务, 0)END AS 本月认购完成率 ,
                ISNULL(本月签约金额全口径, 0) + ISNULL(rw.非项目本月实际签约金额,0) AS 本月签约金额 ,
                ISNULL(本月签约套数全口径, 0) AS 本月签约套数 ,
                ISNULL(qt.其他业绩本月签约金额, 0) AS 其他业绩本月签约金额 ,                                                                    --以客户提供其他业绩认定的房间
                ISNULL(qt.其他业绩本月签约套数, 0) AS 其他业绩本月签约套数 ,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(本月签约金额全口径, 0) +ISNULL(rw.非项目本月实际签约金额,0) ) / ISNULL(rw.月度签约任务, 0)END AS 本月签约完成率 ,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE (ISNULL(本月签约金额全口径, 0) + ISNULL(qt.其他业绩本月签约金额, 0) +  ISNULL(rw.非项目本月实际签约金额,0) ) / ISNULL(rw.月度签约任务, 0)END AS 本月签约完成率_含其他业绩 ,
                ISNULL(rw.月度签约任务, 0)  - (ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0) + ISNULL(rw.非项目本月实际认购金额,0) )  AS 本月认购金额缺口 ,  --本月任务*本月时间进度分摊比-本月认购金额
                ISNULL(rw.月度签约任务, 0)  - (ISNULL(本月签约金额全口径, 0) + ISNULL(rw.非项目本月实际签约金额,0) ) AS 本月签约金额缺口 ,
                ISNULL(pt.本月时间分摊比, 0) AS 本月时间分摊比 ,
                ISNULL(rs.累计已认购未签约金额, 0) AS 已认购未签约金额 ,
                ISNULL(rs.累计已认购未签约套数, 0) AS 已认购未签约套数 ,
                ISNULL(rw.年度签约任务, 0) AS 本年任务 ,
                ISNULL(rs.本年认购金额, 0) + ISNULL(rg.本年认购金额, 0) + ISNULL(qt.其他业绩本年认购金额, 0) + ISNULL(rw.非项目本年实际认购金额,0) AS 本年认购金额 ,
                ISNULL(rs.本年认购套数, 0) + ISNULL(rg.本年认购套数, 0) + ISNULL(qt.其他业绩本年认购套数, 0) AS 本年认购套数 ,
                ISNULL(s.本年签约金额全口径, 0) + ISNULL(rw.非项目本年实际签约金额,0) AS 本年签约金额 ,
                ISNULL(s.本年签约套数全口径, 0) AS 本年签约套数 ,
                ISNULL(qt.其他业绩本年签约金额, 0) AS 其他业绩本年签约金额 ,
                ISNULL(qt.其他业绩本年签约套数, 0) AS 其他业绩本年签约套数 ,
                CASE WHEN ISNULL(rw.年度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(s.本年签约金额全口径, 0) +ISNULL(rw.非项目本年实际签约金额,0) )  / ISNULL(rw.年度签约任务, 0)END AS 本年签约完成率 ,
                CASE WHEN ISNULL(rw.年度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(s.本年签约金额全口径, 0) + ISNULL(qt.其他业绩本年签约金额, 0) +ISNULL(rw.非项目本年实际签约金额,0) ) / ISNULL(rw.年度签约任务, 0)END AS 本年签约完成率_含其他业绩 ,
                ISNULL(rw.年度签约任务, 0)  - (ISNULL(rs.本年认购金额, 0) + ISNULL(rg.本年认购金额, 0) +ISNULL(rw.非项目本年实际认购金额,0)) AS 本年认购金额缺口 ,
                ISNULL(rw.年度签约任务, 0)  - (ISNULL(本年签约金额全口径, 0) +ISNULL(rw.非项目本年实际签约金额,0) ) AS 本年签约金额缺口 ,
                ISNULL(pt.本年时间分摊比, 0) AS 本年时间分摊比 ,
                ISNULL(rw.本年存量任务, 0) AS 本年存量任务 ,
                ISNULL(rw.本年增量任务, 0) AS 本年增量任务 ,
                ISNULL(rw.本年新增量任务, 0) AS 本年新增量任务 ,
                ISNULL(rw.本月存量任务, 0) AS 本月存量任务 ,
                ISNULL(rw.本月增量任务, 0) AS 本月增量任务 ,
                ISNULL(rw.本月新增量任务, 0) AS 本月新增量任务,
				-- 产成品
                ISNULL(rs.本日产成品认购金额, 0) + ISNULL(rg.本日产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本日认购金额, 0) AS 本日产成品认购金额 ,  
                ISNULL(rs.本日产成品认购套数, 0) + ISNULL(rg.本日产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本日认购套数, 0) AS 本日产成品认购套数 ,
                ISNULL(s.本日产成品签约金额全口径, 0) AS 本日产成品签约金额 ,
                ISNULL(s.本日产成品签约套数全口径, 0) AS 本日产成品签约套数 ,
                ISNULL(rs.本周产成品认购金额, 0) + ISNULL(rg.本周产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本周认购金额, 0) AS 本周产成品认购金额 ,
                ISNULL(rs.本周产成品认购套数, 0) + ISNULL(rg.本周产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本周认购套数, 0) AS 本周产成品认购套数 ,
                rw.产成品月度任务 AS 本月产成品任务 ,
                ISNULL(rs.本月产成品认购金额, 0) + ISNULL(rg.本月产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本月认购金额, 0) AS 本月产成品认购金额 ,
                ISNULL(rs.本月产成品认购套数, 0) + ISNULL(rg.本月产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本月认购套数, 0) AS 本月产成品认购套数 ,
				ISNULL(qt.其他业绩产成品本月认购金额, 0) AS 其他业绩产成品本月认购金额,
				ISNULL(qt.其他业绩产成品本月认购套数, 0) AS 其他业绩产成品本月认购套数,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE (ISNULL(rs.本月产成品认购金额, 0) + ISNULL(rg.本月产成品认购金额, 0)+ ISNULL(qt.其他业绩产成品本月认购金额,0)) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品认购完成率 ,
                ISNULL(本月产成品签约金额全口径, 0) AS 本月产成品签约金额 ,
                ISNULL(本月产成品签约套数全口径, 0) AS 本月产成品签约套数,
				ISNULL(qt.其他业绩产成品本月签约金额, 0) AS 其他业绩产成品本月签约金额 ,                                                                   
                ISNULL(qt.其他业绩产成品本月签约套数, 0) AS 其他业绩产成品本月签约套数 ,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE ISNULL(本月产成品签约金额全口径, 0) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品签约完成率 ,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE (ISNULL(本月产成品签约金额全口径, 0) + ISNULL(qt.其他业绩产成品本月签约金额, 0)) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品签约完成率_含其他业绩 ,
				ISNULL(rs.累计产成品已认购未签约金额, 0) AS 累计产成品已认购未签约金额 ,
                ISNULL(rs.累计产成品已认购未签约套数, 0) AS 累计产成品已认购未签约套数 ,

				ISNULL(rw.产成品年度任务,0)  AS  本年产成品任务,
                ISNULL(rs.本年产成品认购金额, 0) + ISNULL(rg.本年产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本年认购金额, 0) AS 本年产成品认购金额 ,
                ISNULL(rs.本年产成品认购套数, 0) + ISNULL(rg.本年产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本年认购套数, 0) AS 本年产成品认购套数 ,
                ISNULL(s.本年产成品签约金额全口径, 0) AS 本年产成品签约金额 ,
                ISNULL(s.本年产成品签约套数全口径, 0) AS 本年产成品签约套数 ,
                ISNULL(qt.其他业绩产成品本年签约金额, 0) AS 其他业绩产成品本年签约金额 ,
                ISNULL(qt.其他业绩产成品本年签约套数, 0) AS 其他业绩产成品本年签约套数 ,
                CASE WHEN ISNULL(rw.产成品年度任务, 0) = 0 THEN 0 ELSE ISNULL(s.本年产成品签约金额全口径, 0) / ISNULL(rw.产成品年度任务, 0)END AS 本年产成品签约完成率 ,
                CASE WHEN ISNULL(rw.产成品年度任务, 0) = 0 THEN 0 ELSE (ISNULL(s.本年产成品签约金额全口径, 0) + ISNULL(qt.其他业绩产成品本年签约金额, 0)) / ISNULL(rw.产成品年度任务, 0)END AS 本年产成品签约完成率_含其他业绩 , 
				ISNULL(rw.非项目本年实际签约金额,0 ) AS 非项目本年实际签约金额,
				ISNULL(rw.非项目本月实际签约金额,0 ) AS 非项目本月实际签约金额,
				ISNULL(rw.非项目本年实际认购金额,0 ) AS 非项目本年实际认购金额,
				ISNULL(rw.非项目本月实际认购金额,0 ) AS 非项目本月实际认购金额,
		        -- 20240604 chenjw 新增面积类字段
                ISNULL(rs.本日认购面积, 0) + ISNULL(rg.本日认购面积, 0) + ISNULL(qt.其他业绩本日认购金额, 0)  AS 本日认购面积 ,
				ISNULL(s.本日签约面积全口径,0)   AS 本日签约面积 ,
			    ISNULL(rs.本周认购面积,0) + ISNULL(rg.本周认购面积,0) + ISNULL(qt.其他业绩本周认购面积,0) AS 本周认购面积 ,
				ISNULL(s.本周签约套数全口径,0) AS 本周签约套数 ,
				ISNULL(s.本周签约面积全口径,0) AS 本周签约面积 ,
				ISNULL(s.本周签约金额全口径,0) AS 本周签约金额 ,
				ISNULL(rs.本月认购面积,0) + ISNULL(rg.本月认购面积,0) + ISNULL(qt.其他业绩本月认购面积,0) AS 本月认购面积 ,
				ISNULL(s.本月签约面积全口径, 0) AS 本月签约面积 ,
				ISNULL(qt.其他业绩本月认购面积,0) AS 其他业绩本月认购面积 ,
				ISNULL(qt.其他业绩本月签约面积,0) AS 其他业绩本月签约面积 ,
				ISNULL(rs.本月产成品认购面积, 0) + ISNULL(rg.本月产成品认购面积, 0) + ISNULL(qt.其他业绩产成品本月认购面积, 0) AS 本月产成品认购面积 ,
				ISNULL(s.本月产成品签约面积全口径,0)  AS 本月产成品签约面积 ,
				ISNULL(qt.其他业绩产成品本月签约面积,0)  AS 其他业绩产成品本月签约面积 ,
				ISNULL(rs.累计产成品已认购未签约面积,0) AS 已认购未签约签约面积 ,
				ISNULL(rs.本年认购面积, 0) + ISNULL(rg.本年认购面积, 0) + ISNULL(qt.其他业绩本年认购面积, 0) AS 本年认购面积 ,
				ISNULL(本年签约面积全口径, 0) AS 本年签约面积 ,
				ISNULL(qt.其他业绩本年认购套数,0) AS 其他业绩本年认购套数 ,
				ISNULL(qt.其他业绩本日认购面积,0) AS 其他业绩本年认购面积 ,
				ISNULL(qt.其他业绩本日认购金额,0) AS 其他业绩本年认购金额 ,

				ISNULL(qt.其他业绩本年签约面积,0) AS 其他业绩本年签约面积 ,
				ISNULL(rs.本年产成品认购面积, 0) + ISNULL(rg.本年产成品认购面积, 0) + ISNULL(qt.其他业绩产成品本年认购面积, 0) AS 本年产成品认购面积 ,
				ISNULL(s.本年产成品签约面积全口径,0) AS 本年产成品签约面积 ,
				ISNULL(qt.其他业绩产成品本年签约面积,0 ) AS 其他业绩产成品本年签约面积,
                @wideTableDateText  as 宽表最后清洗日期 ,
                --大户型
                ISNULL(rs.本日大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本日认购金额, 0) as 本日大户型认购金额,
                ISNULL(rs.本日大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本日认购面积, 0)  as 本日大户型认购面积,
                ISNULL(rs.本日大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本日认购套数, 0)  as 本日大户型认购套数,
                ISNULL(dhx.本日大户型签约金额全口径, 0)   as 本日大户型签约金额,
                ISNULL(dhx.本日大户型签约面积全口径, 0)  as 本日大户型签约面积,
                ISNULL(dhx.本日大户型签约套数全口径, 0)  as 本日大户型签约套数,

                ISNULL(rs.本周大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本周认购金额, 0) as 本周大户型认购金额,
                ISNULL(rs.本周大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本周认购面积, 0) as 本周大户型认购面积,
                ISNULL(rs.本周大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本周认购套数, 0) as 本周大户型认购套数,
                ISNULL(dhx.本周大户型签约金额全口径, 0) as 本周大户型签约金额,
                ISNULL(dhx.本周大户型签约面积全口径, 0) as 本周大户型签约面积,
                ISNULL(dhx.本周大户型签约套数全口径, 0) as 本周大户型签约套数,

                ISNULL(rs.本月大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本月认购金额, 0) as 本月大户型认购金额,
                ISNULL(rs.本月大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本月认购面积, 0) as 本月大户型认购面积,
                ISNULL(rs.本月大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本月认购套数, 0) as 本月大户型认购套数,
                ISNULL(dhx.本月大户型签约金额全口径,0) + ISNULL(qt.其他业绩大户型本月签约金额,0) as 本月大户型签约金额,
                ISNULL(dhx.本月大户型签约面积全口径,0) + ISNULL(qt.其他业绩大户型本月签约面积,0) as 本月大户型签约面积,
                ISNULL(dhx.本月大户型签约套数全口径,0) + ISNULL(qt.其他业绩大户型本月签约套数,0) as 本月大户型签约套数,

                ISNULL(rs.本年大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本年认购金额, 0) as 本年大户型认购金额,
                ISNULL(rs.本年大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本年认购面积, 0) as 本年大户型认购面积,
                ISNULL(rs.本年大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本年认购套数, 0) as 本年大户型认购套数,
                ISNULL(dhx.本年大户型签约金额全口径,0) + ISNULL(qt.其他业绩大户型本年签约金额,0) as 本年大户型签约金额,
                ISNULL(dhx.本年大户型签约面积全口径,0) + ISNULL(qt.其他业绩大户型本年签约面积,0) as 本年大户型签约面积,
                ISNULL(dhx.本年大户型签约套数全口径,0) + ISNULL(qt.其他业绩大户型本年签约套数,0) as 本年大户型签约套数,

                ISNULL(rs.累计大户型已认购未签约金额,0) as 累计大户型已认购未签约金额,
                ISNULL(rs.累计大户型已认购未签约面积,0) as 累计大户型已认购未签约面积,
                ISNULL(rs.累计大户型已认购未签约套数,0) as 累计大户型已认购未签约套数,
                ISNULL(rs.本年大户型已认购未签约金额,0) as 本年大户型已认购未签约金额,
                ISNULL(rs.本年大户型已认购未签约套数,0) as 本年大户型已认购未签约套数,
                ISNULL(rs.本月大户型已认购未签约金额,0) as 本月大户型已认购未签约金额,
                ISNULL(rs.本月大户型已认购未签约套数,0) as 本月大户型已认购未签约套数,

                --联动房
                ISNULL(rs.本日联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本日认购金额, 0) as 本日联动房认购金额,
                ISNULL(rs.本日联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本日认购面积, 0)  as 本日联动房认购面积,
                ISNULL(rs.本日联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本日认购套数, 0)  as 本日联动房认购套数,
                ISNULL(dhx.本日联动房签约金额全口径, 0)   as 本日联动房签约金额,
                ISNULL(dhx.本日联动房签约面积全口径, 0)  as 本日联动房签约面积,
                ISNULL(dhx.本日联动房签约套数全口径, 0)  as 本日联动房签约套数,

                ISNULL(rs.本周联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本周认购金额, 0) as 本周联动房认购金额,
                ISNULL(rs.本周联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本周认购面积, 0) as 本周联动房认购面积,
                ISNULL(rs.本周联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本周认购套数, 0) as 本周联动房认购套数,
                ISNULL(dhx.本周联动房签约金额全口径, 0) as 本周联动房签约金额,
                ISNULL(dhx.本周联动房签约面积全口径, 0) as 本周联动房签约面积,
                ISNULL(dhx.本周联动房签约套数全口径, 0) as 本周联动房签约套数,

                ISNULL(rs.本月联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本月认购金额, 0) as 本月联动房认购金额,
                ISNULL(rs.本月联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本月认购面积, 0) as 本月联动房认购面积,
                ISNULL(rs.本月联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本月认购套数, 0) as 本月联动房认购套数,
                ISNULL(dhx.本月联动房签约金额全口径,0) + ISNULL(qt.其他业绩联动房本月签约金额,0) as 本月联动房签约金额,
                ISNULL(dhx.本月联动房签约面积全口径,0) + ISNULL(qt.其他业绩联动房本月签约面积,0) as 本月联动房签约面积,
                ISNULL(dhx.本月联动房签约套数全口径,0) + ISNULL(qt.其他业绩联动房本月签约套数,0) as 本月联动房签约套数,

                ISNULL(rs.本年联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本年认购金额, 0) as 本年联动房认购金额,
                ISNULL(rs.本年联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本年认购面积, 0) as 本年联动房认购面积,
                ISNULL(rs.本年联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本年认购套数, 0) as 本年联动房认购套数,
                ISNULL(dhx.本年联动房签约金额全口径,0) + ISNULL(qt.其他业绩联动房本年签约金额,0) as 本年联动房签约金额,
                ISNULL(dhx.本年联动房签约面积全口径,0) + ISNULL(qt.其他业绩联动房本年签约面积,0) as 本年联动房签约面积,
                ISNULL(dhx.本年联动房签约套数全口径,0) + ISNULL(qt.其他业绩联动房本年签约套数,0) as 本年联动房签约套数,

                ISNULL(rs.累计联动房已认购未签约金额,0) AS 累计联动房已认购未签约金额,
                ISNULL(rs.累计联动房已认购未签约面积,0) AS 累计联动房已认购未签约面积,
                ISNULL(rs.累计联动房已认购未签约套数,0) AS 累计联动房已认购未签约套数,
                ISNULL(rs.本年联动房已认购未签约金额,0) AS 本年联动房已认购未签约金额,
                ISNULL(rs.本年联动房已认购未签约套数,0) AS 本年联动房已认购未签约套数,
                ISNULL(rs.本月联动房已认购未签约金额,0) AS 本月联动房已认购未签约金额,
                ISNULL(rs.本月联动房已认购未签约套数,0) AS 本月联动房已认购未签约套数,

                ISNULL(qt.其他业绩大户型本月签约金额,0) as 其他业绩大户型本月签约金额,
                ISNULL(qt.其他业绩大户型本月签约面积,0) as 其他业绩大户型本月签约面积,
                ISNULL(qt.其他业绩大户型本月签约套数,0) as 其他业绩大户型本月签约套数,
                ISNULL(qt.其他业绩大户型本年签约金额,0) as 其他业绩大户型本年签约金额,
                ISNULL(qt.其他业绩大户型本年签约面积,0) as 其他业绩大户型本年签约面积,
                ISNULL(qt.其他业绩大户型本年签约套数,0) as 其他业绩大户型本年签约套数,

                --准产成品
                ISNULL(rs.本日准产成品认购金额, 0) + ISNULL(rg.本日准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本日认购金额, 0) AS 本日准产成品认购金额,
                ISNULL(rs.本日准产成品认购面积, 0) + ISNULL(rg.本日准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本日认购面积, 0) AS 本日准产成品认购面积,
                ISNULL(rs.本日准产成品认购套数, 0) + ISNULL(rg.本日准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本日认购套数, 0) AS 本日准产成品认购套数 ,

                ISNULL(s.本日准产成品签约金额全口径, 0) AS 本日准产成品签约金额 ,
                ISNULL(s.本日准产成品签约面积全口径, 0) AS 本日准产成品签约面积 ,
                ISNULL(s.本日准产成品签约套数全口径, 0) AS 本日准产成品签约套数 ,

                ISNULL(rs.本周准产成品认购金额, 0) + ISNULL(rg.本周准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本周认购金额, 0) AS 本周准产成品认购金额 ,
                ISNULL(rs.本周准产成品认购面积, 0) + ISNULL(rg.本周准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本周认购面积, 0) AS 本周准产成品认购面积 ,
                ISNULL(rs.本周准产成品认购套数, 0) + ISNULL(rg.本周准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本周认购套数, 0) AS 本周准产成品认购套数 ,

                ISNULL(rs.本月准产成品认购金额, 0) + ISNULL(rg.本月准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本月认购金额, 0) AS 本月准产成品认购金额 ,
                ISNULL(rs.本月准产成品认购面积, 0) + ISNULL(rg.本月准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本月认购面积, 0) AS 本月准产成品认购面积 ,
                ISNULL(rs.本月准产成品认购套数, 0) + ISNULL(rg.本月准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本月认购套数, 0) AS 本月准产成品认购套数 ,

                ISNULL(qt.其他业绩准产成品本月认购金额, 0) AS 其他业绩准产成品本月认购金额 ,
                ISNULL(qt.其他业绩准产成品本月认购面积, 0) AS 其他业绩准产成品本月认购面积 ,
                ISNULL(qt.其他业绩准产成品本月认购套数, 0) AS 其他业绩准产成品本月认购套数 ,

                ISNULL(本月准产成品签约金额全口径, 0) AS 本月准产成品签约金额 ,
                ISNULL(本月准产成品签约面积全口径, 0) AS 本月准产成品签约面积 ,
                ISNULL(本月准产成品签约套数全口径, 0) AS 本月准产成品签约套数 ,

                ISNULL(qt.其他业绩准产成品本月签约金额, 0) AS 其他业绩准产成品本月签约金额 ,
                ISNULL(qt.其他业绩准产成品本月签约面积, 0) AS 其他业绩准产成品本月签约面积 ,
                ISNULL(qt.其他业绩准产成品本月签约套数, 0) AS 其他业绩准产成品本月签约套数 ,

                ISNULL(rs.累计准产成品已认购未签约金额, 0) AS 累计准产成品已认购未签约金额 ,
                ISNULL(rs.累计准产成品已认购未签约面积, 0) AS 累计准产成品已认购未签约面积 ,
                ISNULL(rs.累计准产成品已认购未签约套数, 0) AS 累计准产成品已认购未签约套数 ,

                ISNULL(rs.本年准产成品认购金额, 0) + ISNULL(rg.本年准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本年认购金额, 0) AS 本年准产成品认购金额 ,
                ISNULL(rs.本年准产成品认购面积, 0) + ISNULL(rg.本年准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本年认购面积, 0) AS 本年准产成品认购面积 ,
                ISNULL(rs.本年准产成品认购套数, 0) + ISNULL(rg.本年准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本年认购套数, 0) AS 本年准产成品认购套数 ,

                ISNULL(s.本年准产成品签约金额全口径, 0) AS 本年准产成品签约金额 ,
                ISNULL(s.本年准产成品签约面积全口径, 0) AS 本年准产成品签约面积 ,
                ISNULL(s.本年准产成品签约套数全口径, 0) AS 本年准产成品签约套数 ,
                ISNULL(qt.其他业绩准产成品本年签约金额, 0) AS 其他业绩准产成品本年签约金额 ,
                ISNULL(qt.其他业绩准产成品本年签约面积, 0) AS 其他业绩准产成品本年签约面积 ,                
                ISNULL(qt.其他业绩准产成品本年签约套数, 0) AS 其他业绩准产成品本年签约套数 ,

                --补充现产成品任务和大户型任务@20250630
                ISNULL(rw.准产成品月度任务, 0) AS 准产成品月度任务,
                ISNULL(rw.准产成品年度任务, 0) AS 准产成品年度任务,
                ISNULL(rw.大户型月度任务, 0)   AS 大户型月度任务,
                ISNULL(rw.大户型年度任务, 0)   AS 大户型年度任务
        FROM    data_wide_dws_mdm_Project p
                INNER JOIN #TopProduct pt ON pt.ParentProjGUID = p.ProjGUID
                LEFT JOIN data_tb_hnyx_jdfxtb rw ON rw.projguid = p.ProjGUID AND   rw.业态 = pt.TopProductTypeName
                LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
                LEFT JOIN #projsale s ON p.ProjGUID = s.orgguid AND pt.TopProductTypeName = s.TopProductTypeName
                LEFT JOIN #projsale_ldf_dhx dhx on p.ProjGUID = dhx.orgguid AND pt.TopProductTypeName = dhx.TopProductTypeName
                LEFT JOIN #rsale rs ON rs.ProjGUID = p.ProjGUID AND pt.TopProductTypeName = rs.TopProductTypeName
                LEFT JOIN #rg rg ON rg.ProjGUID = p.ProjGUID AND   pt.TopProductTypeName = rg.TopProductTypeName
                LEFT JOIN #qtqy qt ON qt.projguid = p.projguid AND pt.TopProductTypeName = qt.TopProductTypeName
        WHERE   Level = 2 AND   p.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF'
		 UNION ALL 
		-- 项目层级-平衡处理
        SELECT  @DateText AS 数据清洗日期 ,
                '项目' AS 层级 ,
                p.BUGUID AS 公司GUID ,
                tb.营销事业部 AS 区域 ,
                tb.营销片区 ,
                p.ProjGUID AS 项目GUID ,
                ISNULL(tb.推广名称, p.SpreadName) AS 项目名称 ,
                '全部项目' AS 层级名称 ,
                '平衡处理' 层级名称显示 ,
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END AS 项目名称负责人 ,
                CASE WHEN pt.TopProductTypeName IN ('高级住宅', '住宅', '别墅') THEN '住宅' 
				     WHEN pt.TopProductTypeName IN ('地下室/车库') THEN '车位' 
					 WHEN pt.TopProductTypeName IN ('商业','公寓','写字楼','酒店','会所','企业会所') THEN  '商办'
					 ELSE '其他' END AS 业态 ,
                pt.TopProductTypeName AS 产品类型 ,
                pt.TopProductTypeGUID AS 产品类型GUID ,
                tb.城市 ,
                tb.公司 ,
                tb.投管编码 ,
                tb.项目负责人 ,
                p.BeginDate AS 项目获取日期 ,
                pt.存量增量 ,
                0 AS 本日认购金额 ,                          -- 全口径
                0 AS 本日认购套数 ,
                0 AS 本日签约金额 ,
                0 AS 本日签约套数 ,
                0 AS 本周认购金额 ,
                0 AS 本周认购套数 ,
                0 AS 本月任务 ,
                - ISNULL(rw.非项目本月实际认购金额,0 )  AS 本月认购金额 ,
                0 AS 本月认购套数 ,
				0 AS 其他业绩本月认购金额,
				0 AS 其他业绩本月认购套数,
                0 AS 本月认购完成率 ,
                - ISNULL(rw.非项目本月实际签约金额,0 )  AS 本月签约金额 ,
                0  AS 本月签约套数 ,
                0 AS 其他业绩本月签约金额 ,                                                                    --以客户提供其他业绩认定的房间
                0 AS 其他业绩本月签约套数 ,
                0 AS 本月签约完成率 ,
                0 AS 本月签约完成率_含其他业绩 ,
                0 AS 本月认购金额缺口 ,  --本月任务*本月时间进度分摊比-本月认购金额
                0 AS 本月签约金额缺口 ,
                0 AS 本月时间分摊比 ,
                0 AS 已认购未签约金额 ,
                0 AS 已认购未签约套数 ,
                0 AS 本年任务 ,
                - ISNULL(rw.非项目本年实际认购金额,0 ) AS 本年认购金额 ,
                0 AS 本年认购套数 ,
                - ISNULL(rw.非项目本年实际签约金额,0 ) AS 本年签约金额 ,
                0 AS 本年签约套数 ,
                0 AS 其他业绩本年签约金额 ,
                0 AS 其他业绩本年签约套数 ,
                0 AS 本年签约完成率 ,
                0 AS 本年签约完成率_含其他业绩 ,
                0 AS 本年认购金额缺口 ,
                0 AS 本年签约金额缺口 ,
                0 AS 本年时间分摊比 ,
                0 AS 本年存量任务 ,
                0 AS 本年增量任务 ,
                0 AS 本年新增量任务 ,
                0 AS 本月存量任务 ,
                0 AS 本月增量任务 ,
                0 本月新增量任务,
				-- 产成品
                0 AS 本日产成品认购金额 ,  
                0 AS 本日产成品认购套数 ,
                0 AS 本日产成品签约金额 ,
                0 AS 本日产成品签约套数 ,
                0 AS 本周产成品认购金额 ,
                0 AS 本周产成品认购套数 ,
                0 AS 本月产成品任务 ,
                0 AS 本月产成品认购金额 ,
                0 AS 本月产成品认购套数 ,
				0 AS 其他业绩产成品本月认购金额,
				0 AS 其他业绩产成品本月认购套数,
                0 AS 本月产成品认购完成率 ,
                0 AS 本月产成品签约金额 ,
                0 AS 本月产成品签约套数,
				0 AS 其他业绩产成品本月签约金额 ,                                                                   
                0 AS 其他业绩产成品本月签约套数 ,
                0 AS 本月产成品签约完成率 ,
                0 AS 本月产成品签约完成率_含其他业绩 ,
				0 AS 累计产成品已认购未签约金额 ,
                0 AS 累计产成品已认购未签约套数 ,

				0 AS  本年产成品任务,
                0 AS 本年产成品认购金额 ,
                0 AS 本年产成品认购套数 ,
                0 AS 本年产成品签约金额 ,
                0 AS 本年产成品签约套数 ,
                0 AS 其他业绩产成品本年签约金额 ,
                0 AS 其他业绩产成品本年签约套数 ,
                0 AS 本年产成品签约完成率 ,
                0 AS 本年产成品签约完成率_含其他业绩 , 
				0 as 非项目本年实际签约金额,
				0 as 非项目本月实际签约金额,
				0 as 非项目本年实际认购金额,
				0 as 非项目本月实际认购金额,
			    -- 20240604 chenjw 新增面积类字段
				0 AS 本日认购面积 ,
				0 AS 本日签约面积 ,
				0 AS 本周认购面积 ,
				0 AS 本周签约套数 ,
				0 AS 本周签约面积 ,
				0 AS 本周签约金额 ,
				0 AS 本月认购面积 ,
				0 AS 本月签约面积 ,
				0 AS 其他业绩本月认购面积 ,
				0 AS 其他业绩本月签约面积 ,
				0 AS 本月产成品认购面积 ,
				0 AS 本月产成品签约面积 ,
				0 AS 其他业绩产成品本月签约面积 ,
				0 AS 已认购未签约签约面积 ,
				0 AS 本年认购面积 ,
				0 AS 本年签约面积 ,
				0 AS 其他业绩本年认购套数 ,
				0 AS 其他业绩本年认购面积 ,
				0 AS 其他业绩本年认购金额 ,
				0 AS 其他业绩本年签约面积 ,
				0 AS 本年产成品认购面积 ,
				0 AS 本年产成品签约面积 ,
				0 AS 其他业绩产成品本年签约面积,
                @wideTableDateText  as 宽表最后清洗日期 ,
                --大户型
                0 as 本日大户型认购金额,
                0 as 本日大户型认购面积,
                0 as 本日大户型认购套数,
                0 as 本日大户型签约金额,
                0 as 本日大户型签约面积,
                0 as 本日大户型签约套数,

                0 as 本周大户型认购金额,
                0 as 本周大户型认购面积,
                0 as 本周大户型认购套数,
                0 as 本周大户型签约金额,
                0 as 本周大户型签约面积,
                0 as 本周大户型签约套数,

                0 as 本月大户型认购金额,
                0 as 本月大户型认购面积,
                0 as 本月大户型认购套数,
                0 as 本月大户型签约金额,
                0 as 本月大户型签约面积,
                0 as 本月大户型签约套数,

                0 as 本年大户型认购金额,
                0 as 本年大户型认购面积,
                0 as 本年大户型认购套数,
                0 as 本年大户型签约金额,
                0 as 本年大户型签约面积,
                0 as 本年大户型签约套数,

                0 as 累计大户型已认购未签约金额,
                0 as 累计大户型已认购未签约面积,
                0 as 累计大户型已认购未签约套数,
                0 as 本年大户型已认购未签约金额,
                0 as 本年大户型已认购未签约套数,
                0 as 本月大户型已认购未签约金额,
                0 as 本月大户型已认购未签约套数,

                --联动房
                0 as 本日联动房认购金额,
                0 as 本日联动房认购面积,
                0 as 本日联动房认购套数,
                0 as 本日联动房签约金额,
                0 as 本日联动房签约面积,
                0 as 本日联动房签约套数,

                0 as 本周联动房认购金额,
                0 as 本周联动房认购面积,
                0 as 本周联动房认购套数,
                0 as 本周联动房签约金额,
                0 as 本周联动房签约面积,
                0 as 本周联动房签约套数,

                0 as 本月联动房认购金额,
                0 as 本月联动房认购面积,
                0 as 本月联动房认购套数,
                0 as 本月联动房签约金额,
                0 as 本月联动房签约面积,
                0 as 本月联动房签约套数,

                0 as 本年联动房认购金额,
                0 as 本年联动房认购面积,
                0 as 本年联动房认购套数,
                0 as 本年联动房签约金额,
                0 as 本年联动房签约面积,
                0 as 本年联动房签约套数,

                0 AS 累计联动房已认购未签约金额,
                0 AS 累计联动房已认购未签约面积,
                0 AS 累计联动房已认购未签约套数,
                0 AS 本年联动房已认购未签约金额,
                0 AS 本年联动房已认购未签约套数,
                0 AS 本月联动房已认购未签约金额,
                0 AS 本月联动房已认购未签约套数,

                0 as 其他业绩大户型本月签约金额,
                0 as 其他业绩大户型本月签约面积,
                0 as 其他业绩大户型本月签约套数,
                0 as 其他业绩大户型本年签约金额,
                0 as 其他业绩大户型本年签约面积,
                0 as 其他业绩大户型本年签约套数,

                --准产成品
                0 AS 本日准产成品认购金额,
                0 AS 本日准产成品认购面积,
                0 AS 本日准产成品认购套数,

                0 AS 本日准产成品签约金额 ,
                0 AS 本日准产成品签约面积 ,
                0 AS 本日准产成品签约套数 ,

                0 AS 本周准产成品认购金额 ,
                0 AS 本周准产成品认购面积 ,
                0 AS 本周准产成品认购套数 ,

                0 AS 本月准产成品认购金额 ,
                0 AS 本月准产成品认购面积 ,
                0 AS 本月准产成品认购套数 ,

                0 AS 其他业绩准产成品本月认购金额 ,
                0 AS 其他业绩准产成品本月认购面积 ,
                0 AS 其他业绩准产成品本月认购套数 ,

                0 AS 本月准产成品签约金额 ,
                0 AS 本月准产成品签约面积 ,
                0 AS 本月准产成品签约套数 ,

                0 AS 其他业绩准产成品本月签约金额 ,
                0 AS 其他业绩准产成品本月签约面积 ,
                0 AS 其他业绩准产成品本月签约套数 ,

                0 AS 累计准产成品已认购未签约金额 ,
                0 AS 累计准产成品已认购未签约面积 ,
                0 AS 累计准产成品已认购未签约套数 ,

                0 AS 本年准产成品认购金额 ,
                0 AS 本年准产成品认购面积 ,
                0 AS 本年准产成品认购套数 ,

                0 AS 本年准产成品签约金额 ,
                0 AS 本年准产成品签约面积 ,
                0 AS 本年准产成品签约套数 ,

                0 AS 其他业绩准产成品本年签约金额 ,
                0 AS 其他业绩准产成品本年签约面积 ,                
                0 AS 其他业绩准产成品本年签约套数 ,

                --补充现产成品任务和大户型任务@20250630
                0 AS 准产成品月度任务,
                0 AS 准产成品年度任务,
                0 AS 大户型月度任务,
                0 AS 大户型年度任务
        FROM    data_wide_dws_mdm_Project p
                INNER JOIN #TopProduct pt ON pt.ParentProjGUID = p.ProjGUID
                LEFT JOIN data_tb_hnyx_jdfxtb rw ON rw.projguid = p.ProjGUID AND   rw.业态 = pt.TopProductTypeName
                LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
                LEFT JOIN #projsale s ON p.ProjGUID = s.orgguid AND pt.TopProductTypeName = s.TopProductTypeName
                LEFT JOIN #projsale_ldf_dhx dhx on p.ProjGUID = dhx.orgguid AND pt.TopProductTypeName = dhx.TopProductTypeName
                LEFT JOIN #rsale rs ON rs.ProjGUID = p.ProjGUID AND pt.TopProductTypeName = rs.TopProductTypeName
                LEFT JOIN #rg rg ON rg.ProjGUID = p.ProjGUID AND   pt.TopProductTypeName = rg.TopProductTypeName
                LEFT JOIN #qtqy qt ON qt.projguid = p.projguid AND pt.TopProductTypeName = qt.TopProductTypeName
        WHERE   Level = 2 AND   p.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF' 
        -- 项目层级-各项目名称
        UNION ALL
        SELECT  @DateText AS 数据清洗日期 ,
                '项目' AS 层级 ,
                p.BUGUID AS 公司GUID ,
                tb.营销事业部 AS 区域 ,
                tb.营销片区 ,
                p.ProjGUID AS 项目GUID ,
                ISNULL(tb.推广名称, p.SpreadName) AS 项目名称 ,
                ISNULL(tb.推广名称, p.SpreadName) AS 层级名称 ,
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END 层级名称显示 ,
                CASE WHEN ISNULL(tb.项目负责人, '') <> '' THEN ISNULL(tb.项目简称, p.SpreadName) + '(' + ISNULL(tb.项目负责人, '') + ')' ELSE ISNULL(tb.项目简称, p.SpreadName)END AS 项目名称负责人 ,
                CASE WHEN pt.TopProductTypeName IN ('高级住宅', '住宅', '别墅') THEN '住宅' 
				     WHEN pt.TopProductTypeName IN ('地下室/车库') THEN '车位' 
					 WHEN pt.TopProductTypeName IN ('商业','公寓','写字楼','酒店','会所','企业会所') THEN  '商办'
					 ELSE '其他' END AS 业态 ,
                pt.TopProductTypeName AS 产品类型 ,
                pt.TopProductTypeGUID AS 产品类型GUID ,
                tb.城市 ,
                tb.公司 ,
                tb.投管编码 ,
                tb.项目负责人 ,
                p.BeginDate AS 项目获取日期 ,
                pt.存量增量 ,
                ISNULL(rs.本日认购金额, 0) + ISNULL(rg.本日认购金额, 0) + ISNULL(qt.其他业绩本日认购金额, 0) AS 本日认购金额 ,                          -- 全口径
                ISNULL(rs.本日认购套数, 0) + ISNULL(rg.本日认购套数, 0) + ISNULL(qt.其他业绩本日认购套数, 0) AS 本日认购套数 ,
                ISNULL(s.本日签约金额全口径, 0) AS 本日签约金额 ,
                ISNULL(s.本日签约套数全口径, 0) AS 本日签约套数 ,
                ISNULL(rs.本周认购金额, 0) + ISNULL(rg.本周认购金额, 0) + ISNULL(qt.其他业绩本周认购金额, 0) AS 本周认购金额 ,
                ISNULL(rs.本周认购套数, 0) + ISNULL(rg.本周认购套数, 0) + ISNULL(qt.其他业绩本周认购套数, 0) AS 本周认购套数 ,
                rw.月度签约任务 AS 本月任务 ,
               ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0) + ISNULL(qt.其他业绩本月认购金额, 0) + ISNULL(rw.非项目本月实际认购金额,0)  AS 本月认购金额 ,
                ISNULL(rs.本月认购套数, 0) + ISNULL(rg.本月认购套数, 0) + ISNULL(qt.其他业绩本月认购套数, 0) AS 本月认购套数 ,
				ISNULL(qt.其他业绩本月认购金额, 0) AS 其他业绩本月认购金额,
				ISNULL(qt.其他业绩本月认购套数, 0) AS 其他业绩本月认购套数,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE (ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0)+ ISNULL(qt.其他业绩本月认购金额,0) + ISNULL(rw.非项目本月实际认购金额,0)) / ISNULL(rw.月度签约任务, 0)END AS 本月认购完成率 ,
                ISNULL(本月签约金额全口径, 0) + ISNULL(rw.非项目本月实际签约金额,0) AS 本月签约金额 ,
                ISNULL(本月签约套数全口径, 0) AS 本月签约套数 ,
                ISNULL(qt.其他业绩本月签约金额, 0) AS 其他业绩本月签约金额 ,                                                                    --以客户提供其他业绩认定的房间
                ISNULL(qt.其他业绩本月签约套数, 0) AS 其他业绩本月签约套数 ,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(本月签约金额全口径, 0) +ISNULL(rw.非项目本月实际签约金额,0) ) / ISNULL(rw.月度签约任务, 0)END AS 本月签约完成率 ,
                CASE WHEN ISNULL(rw.月度签约任务, 0) = 0 THEN 0 ELSE (ISNULL(本月签约金额全口径, 0) + ISNULL(qt.其他业绩本月签约金额, 0) +  ISNULL(rw.非项目本月实际签约金额,0) ) / ISNULL(rw.月度签约任务, 0)END AS 本月签约完成率_含其他业绩 ,
                ISNULL(rw.月度签约任务, 0)  - (ISNULL(rs.本月认购金额, 0) + ISNULL(rg.本月认购金额, 0) + ISNULL(rw.非项目本月实际认购金额,0) )  AS 本月认购金额缺口 ,  --本月任务*本月时间进度分摊比-本月认购金额
                ISNULL(rw.月度签约任务, 0)  - (ISNULL(本月签约金额全口径, 0) + ISNULL(rw.非项目本月实际签约金额,0) ) AS 本月签约金额缺口 ,
                ISNULL(pt.本月时间分摊比, 0) AS 本月时间分摊比 ,
                ISNULL(rs.累计已认购未签约金额, 0) AS 已认购未签约金额 ,
                ISNULL(rs.累计已认购未签约套数, 0) AS 已认购未签约套数 ,
                ISNULL(rw.年度签约任务, 0) AS 本年任务 ,
                ISNULL(rs.本年认购金额, 0) + ISNULL(rg.本年认购金额, 0) + ISNULL(qt.其他业绩本年认购金额, 0) + ISNULL(rw.非项目本年实际认购金额,0) AS 本年认购金额 ,
                ISNULL(rs.本年认购套数, 0) + ISNULL(rg.本年认购套数, 0) + ISNULL(qt.其他业绩本年认购套数, 0) AS 本年认购套数 ,
                ISNULL(s.本年签约金额全口径, 0) + ISNULL(rw.非项目本年实际签约金额,0) AS 本年签约金额 ,
                ISNULL(s.本年签约套数全口径, 0) AS 本年签约套数 ,
                ISNULL(qt.其他业绩本年签约金额, 0) AS 其他业绩本年签约金额 ,
                ISNULL(qt.其他业绩本年签约套数, 0) AS 其他业绩本年签约套数 ,
                CASE WHEN ISNULL(rw.年度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(s.本年签约金额全口径, 0) +ISNULL(rw.非项目本年实际签约金额,0) )  / ISNULL(rw.年度签约任务, 0)END AS 本年签约完成率 ,
                CASE WHEN ISNULL(rw.年度签约任务, 0) = 0 THEN 0 ELSE ( ISNULL(s.本年签约金额全口径, 0) + ISNULL(qt.其他业绩本年签约金额, 0) +ISNULL(rw.非项目本年实际签约金额,0) ) / ISNULL(rw.年度签约任务, 0)END AS 本年签约完成率_含其他业绩 ,
                ISNULL(rw.年度签约任务, 0)  - (ISNULL(rs.本年认购金额, 0) + ISNULL(rg.本年认购金额, 0) +ISNULL(rw.非项目本年实际认购金额,0)) AS 本年认购金额缺口 ,
                ISNULL(rw.年度签约任务, 0)  - (ISNULL(本年签约金额全口径, 0) +ISNULL(rw.非项目本年实际签约金额,0) ) AS 本年签约金额缺口 ,
                ISNULL(pt.本年时间分摊比, 0) AS 本年时间分摊比 ,
                ISNULL(rw.本年存量任务, 0) AS 本年存量任务 ,
                ISNULL(rw.本年增量任务, 0) AS 本年增量任务 ,
                ISNULL(rw.本年新增量任务, 0) AS 本年新增量任务 ,
                ISNULL(rw.本月存量任务, 0) AS 本月存量任务 ,
                ISNULL(rw.本月增量任务, 0) AS 本月增量任务 ,
                ISNULL(rw.本月新增量任务, 0) AS 本月新增量任务,
				-- 产成品
                ISNULL(rs.本日产成品认购金额, 0) + ISNULL(rg.本日产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本日认购金额, 0) AS 本日产成品认购金额 ,  
                ISNULL(rs.本日产成品认购套数, 0) + ISNULL(rg.本日产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本日认购套数, 0) AS 本日产成品认购套数 ,
                ISNULL(s.本日产成品签约金额全口径, 0) AS 本日产成品签约金额 ,
                ISNULL(s.本日产成品签约套数全口径, 0) AS 本日产成品签约套数 ,
                ISNULL(rs.本周产成品认购金额, 0) + ISNULL(rg.本周产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本周认购金额, 0) AS 本周产成品认购金额 ,
                ISNULL(rs.本周产成品认购套数, 0) + ISNULL(rg.本周产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本周认购套数, 0) AS 本周产成品认购套数 ,
                rw.产成品月度任务 AS 本月产成品任务 ,
                ISNULL(rs.本月产成品认购金额, 0) + ISNULL(rg.本月产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本月认购金额, 0) AS 本月产成品认购金额 ,
                ISNULL(rs.本月产成品认购套数, 0) + ISNULL(rg.本月产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本月认购套数, 0) AS 本月产成品认购套数 ,
				ISNULL(qt.其他业绩产成品本月认购金额, 0) AS 其他业绩产成品本月认购金额,
				ISNULL(qt.其他业绩产成品本月认购套数, 0) AS 其他业绩产成品本月认购套数,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE (ISNULL(rs.本月产成品认购金额, 0) + ISNULL(rg.本月产成品认购金额, 0)+ ISNULL(qt.其他业绩产成品本月认购金额,0)) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品认购完成率 ,
                ISNULL(本月产成品签约金额全口径, 0) AS 本月产成品签约金额 ,
                ISNULL(本月产成品签约套数全口径, 0) AS 本月产成品签约套数,
				ISNULL(qt.其他业绩产成品本月签约金额, 0) AS 其他业绩产成品本月签约金额 ,                                                                   
                ISNULL(qt.其他业绩产成品本月签约套数, 0) AS 其他业绩产成品本月签约套数 ,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE ISNULL(本月产成品签约金额全口径, 0) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品签约完成率 ,
                CASE WHEN ISNULL(rw.产成品月度任务, 0) = 0 THEN 0 ELSE (ISNULL(本月产成品签约金额全口径, 0) + ISNULL(qt.其他业绩产成品本月签约金额, 0)) / ISNULL(rw.产成品月度任务, 0)END AS 本月产成品签约完成率_含其他业绩 ,
				ISNULL(rs.累计产成品已认购未签约金额, 0) AS 累计产成品已认购未签约金额 ,
                ISNULL(rs.累计产成品已认购未签约套数, 0) AS 累计产成品已认购未签约套数 ,

				ISNULL(rw.产成品年度任务,0)  AS  本年产成品任务,
                ISNULL(rs.本年产成品认购金额, 0) + ISNULL(rg.本年产成品认购金额, 0) + ISNULL(qt.其他业绩产成品本年认购金额, 0) AS 本年产成品认购金额 ,
                ISNULL(rs.本年产成品认购套数, 0) + ISNULL(rg.本年产成品认购套数, 0) + ISNULL(qt.其他业绩产成品本年认购套数, 0) AS 本年产成品认购套数 ,
                ISNULL(s.本年产成品签约金额全口径, 0) AS 本年产成品签约金额 ,
                ISNULL(s.本年产成品签约套数全口径, 0) AS 本年产成品签约套数 ,
                ISNULL(qt.其他业绩产成品本年签约金额, 0) AS 其他业绩产成品本年签约金额 ,
                ISNULL(qt.其他业绩产成品本年签约套数, 0) AS 其他业绩产成品本年签约套数 ,
                CASE WHEN ISNULL(rw.产成品年度任务, 0) = 0 THEN 0 ELSE ISNULL(s.本年产成品签约金额全口径, 0) / ISNULL(rw.产成品年度任务, 0)END AS 本年产成品签约完成率 ,
                CASE WHEN ISNULL(rw.产成品年度任务, 0) = 0 THEN 0 ELSE (ISNULL(s.本年产成品签约金额全口径, 0) + ISNULL(qt.其他业绩产成品本年签约金额, 0)) / ISNULL(rw.产成品年度任务, 0)END AS 本年产成品签约完成率_含其他业绩 , 
				ISNULL(rw.非项目本年实际签约金额,0 ) AS 非项目本年实际签约金额,
				ISNULL(rw.非项目本月实际签约金额,0 ) AS 非项目本月实际签约金额,
				ISNULL(rw.非项目本年实际认购金额,0 ) AS 非项目本年实际认购金额,
				ISNULL(rw.非项目本月实际认购金额,0 ) AS 非项目本月实际认购金额,
			    -- 20240604 chenjw 新增面积类字段
				0 AS 本日认购面积 ,
				0 AS 本日签约面积 ,
				0 AS 本周认购面积 ,
				0 AS 本周签约套数 ,
				0 AS 本周签约面积 ,
				0 AS 本周签约金额 ,
				0 AS 本月认购面积 ,
				0 AS 本月签约面积 ,
				0 AS 其他业绩本月认购面积 ,
				0 AS 其他业绩本月签约面积 ,
				0 AS 本月产成品认购面积 ,
				0 AS 本月产成品签约面积 ,
				0 AS 其他业绩产成品本月签约面积 ,
				0 AS 已认购未签约签约面积 ,
				0 AS 本年认购面积 ,
				0 AS 本年签约面积 ,
				0 AS 其他业绩本年认购套数 ,
				0 AS 其他业绩本年认购面积 ,
				0 AS 其他业绩本年认购金额 ,
				0 AS 其他业绩本年签约面积 ,
				0 AS 本年产成品认购面积 ,
				0 AS 本年产成品签约面积 ,
				0 AS 其他业绩产成品本年签约面积,
                @wideTableDateText  as 宽表最后清洗日期 ,
                --大户型
                ISNULL(rs.本日大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本日认购金额, 0) as 本日大户型认购金额,
                ISNULL(rs.本日大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本日认购面积, 0)  as 本日大户型认购面积,
                ISNULL(rs.本日大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本日认购套数, 0)  as 本日大户型认购套数,
                ISNULL(dhx.本日大户型签约金额全口径, 0)   as 本日大户型签约金额,
                ISNULL(dhx.本日大户型签约面积全口径, 0)  as 本日大户型签约面积,
                ISNULL(dhx.本日大户型签约套数全口径, 0)  as 本日大户型签约套数,

                ISNULL(rs.本周大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本周认购金额, 0) as 本周大户型认购金额,
                ISNULL(rs.本周大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本周认购面积, 0) as 本周大户型认购面积,
                ISNULL(rs.本周大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本周认购套数, 0) as 本周大户型认购套数,
                ISNULL(dhx.本周大户型签约金额全口径, 0) as 本周大户型签约金额,
                ISNULL(dhx.本周大户型签约面积全口径, 0) as 本周大户型签约面积,
                ISNULL(dhx.本周大户型签约套数全口径, 0) as 本周大户型签约套数,

                ISNULL(rs.本月大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本月认购金额, 0) as 本月大户型认购金额,
                ISNULL(rs.本月大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本月认购面积, 0) as 本月大户型认购面积,
                ISNULL(rs.本月大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本月认购套数, 0) as 本月大户型认购套数,
                ISNULL(dhx.本月大户型签约金额全口径,0) + ISNULL(qt.其他业绩大户型本月签约金额,0) as 本月大户型签约金额,
                ISNULL(dhx.本月大户型签约面积全口径,0) + ISNULL(qt.其他业绩大户型本月签约面积,0) as 本月大户型签约面积,
                ISNULL(dhx.本月大户型签约套数全口径,0) + ISNULL(qt.其他业绩大户型本月签约套数,0) as 本月大户型签约套数,

                ISNULL(rs.本年大户型认购金额, 0) + ISNULL(qt.其他业绩大户型本年认购金额, 0) as 本年大户型认购金额,
                ISNULL(rs.本年大户型认购面积, 0) + ISNULL(qt.其他业绩大户型本年认购面积, 0) as 本年大户型认购面积,
                ISNULL(rs.本年大户型认购套数, 0) + ISNULL(qt.其他业绩大户型本年认购套数, 0) as 本年大户型认购套数,
                ISNULL(dhx.本年大户型签约金额全口径,0) + ISNULL(qt.其他业绩大户型本年签约金额,0) as 本年大户型签约金额,
                ISNULL(dhx.本年大户型签约面积全口径,0) + ISNULL(qt.其他业绩大户型本年签约面积,0) as 本年大户型签约面积,
                ISNULL(dhx.本年大户型签约套数全口径,0) + ISNULL(qt.其他业绩大户型本年签约套数,0) as 本年大户型签约套数,

                ISNULL(rs.累计大户型已认购未签约金额,0) as 累计大户型已认购未签约金额,
                ISNULL(rs.累计大户型已认购未签约面积,0) as 累计大户型已认购未签约面积,
                ISNULL(rs.累计大户型已认购未签约套数,0) as 累计大户型已认购未签约套数,
                ISNULL(rs.本年大户型已认购未签约金额,0) as 本年大户型已认购未签约金额,
                ISNULL(rs.本年大户型已认购未签约套数,0) as 本年大户型已认购未签约套数,
                ISNULL(rs.本月大户型已认购未签约金额,0) as 本月大户型已认购未签约金额,
                ISNULL(rs.本月大户型已认购未签约套数,0) as 本月大户型已认购未签约套数,

                --联动房
                ISNULL(rs.本日联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本日认购金额, 0) as 本日联动房认购金额,
                ISNULL(rs.本日联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本日认购面积, 0)  as 本日联动房认购面积,
                ISNULL(rs.本日联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本日认购套数, 0)  as 本日联动房认购套数,
                ISNULL(dhx.本日联动房签约金额全口径, 0)   as 本日联动房签约金额,
                ISNULL(dhx.本日联动房签约面积全口径, 0)  as 本日联动房签约面积,
                ISNULL(dhx.本日联动房签约套数全口径, 0)  as 本日联动房签约套数,

                ISNULL(rs.本周联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本周认购金额, 0) as 本周联动房认购金额,
                ISNULL(rs.本周联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本周认购面积, 0) as 本周联动房认购面积,
                ISNULL(rs.本周联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本周认购套数, 0) as 本周联动房认购套数,
                ISNULL(dhx.本周联动房签约金额全口径, 0) as 本周联动房签约金额,
                ISNULL(dhx.本周联动房签约面积全口径, 0) as 本周联动房签约面积,
                ISNULL(dhx.本周联动房签约套数全口径, 0) as 本周联动房签约套数,

                ISNULL(rs.本月联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本月认购金额, 0) as 本月联动房认购金额,
                ISNULL(rs.本月联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本月认购面积, 0) as 本月联动房认购面积,
                ISNULL(rs.本月联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本月认购套数, 0) as 本月联动房认购套数,
                ISNULL(dhx.本月联动房签约金额全口径,0) + ISNULL(qt.其他业绩联动房本月签约金额,0) as 本月联动房签约金额,
                ISNULL(dhx.本月联动房签约面积全口径,0) + ISNULL(qt.其他业绩联动房本月签约面积,0) as 本月联动房签约面积,
                ISNULL(dhx.本月联动房签约套数全口径,0) + ISNULL(qt.其他业绩联动房本月签约套数,0) as 本月联动房签约套数,

                ISNULL(rs.本年联动房认购金额, 0) + ISNULL(qt.其他业绩联动房本年认购金额, 0) as 本年联动房认购金额,
                ISNULL(rs.本年联动房认购面积, 0) + ISNULL(qt.其他业绩联动房本年认购面积, 0) as 本年联动房认购面积,
                ISNULL(rs.本年联动房认购套数, 0) + ISNULL(qt.其他业绩联动房本年认购套数, 0) as 本年联动房认购套数,
                ISNULL(dhx.本年联动房签约金额全口径,0) + ISNULL(qt.其他业绩联动房本年签约金额,0) as 本年联动房签约金额,
                ISNULL(dhx.本年联动房签约面积全口径,0) + ISNULL(qt.其他业绩联动房本年签约面积,0) as 本年联动房签约面积,
                ISNULL(dhx.本年联动房签约套数全口径,0) + ISNULL(qt.其他业绩联动房本年签约套数,0) as 本年联动房签约套数,

                ISNULL(rs.累计联动房已认购未签约金额,0) AS 累计联动房已认购未签约金额,
                ISNULL(rs.累计联动房已认购未签约面积,0) AS 累计联动房已认购未签约面积,
                ISNULL(rs.累计联动房已认购未签约套数,0) AS 累计联动房已认购未签约套数,
                ISNULL(rs.本年联动房已认购未签约金额,0) AS 本年联动房已认购未签约金额,
                ISNULL(rs.本年联动房已认购未签约套数,0) AS 本年联动房已认购未签约套数,
                ISNULL(rs.本月联动房已认购未签约金额,0) AS 本月联动房已认购未签约金额,
                ISNULL(rs.本月联动房已认购未签约套数,0) AS 本月联动房已认购未签约套数,

                ISNULL(qt.其他业绩大户型本月签约金额,0) as 其他业绩大户型本月签约金额,
                ISNULL(qt.其他业绩大户型本月签约面积,0) as 其他业绩大户型本月签约面积,
                ISNULL(qt.其他业绩大户型本月签约套数,0) as 其他业绩大户型本月签约套数,
                ISNULL(qt.其他业绩大户型本年签约金额,0) as 其他业绩大户型本年签约金额,
                ISNULL(qt.其他业绩大户型本年签约面积,0) as 其他业绩大户型本年签约面积,
                ISNULL(qt.其他业绩大户型本年签约套数,0) as 其他业绩大户型本年签约套数,

                --准产成品
                ISNULL(rs.本日准产成品认购金额, 0) + ISNULL(rg.本日准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本日认购金额, 0) AS 本日准产成品认购金额,
                ISNULL(rs.本日准产成品认购面积, 0) + ISNULL(rg.本日准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本日认购面积, 0) AS 本日准产成品认购面积,
                ISNULL(rs.本日准产成品认购套数, 0) + ISNULL(rg.本日准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本日认购套数, 0) AS 本日准产成品认购套数 ,

                ISNULL(s.本日准产成品签约金额全口径, 0) AS 本日准产成品签约金额 ,
                ISNULL(s.本日准产成品签约面积全口径, 0) AS 本日准产成品签约面积 ,
                ISNULL(s.本日准产成品签约套数全口径, 0) AS 本日准产成品签约套数 ,

                ISNULL(rs.本周准产成品认购金额, 0) + ISNULL(rg.本周准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本周认购金额, 0) AS 本周准产成品认购金额 ,
                ISNULL(rs.本周准产成品认购面积, 0) + ISNULL(rg.本周准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本周认购面积, 0) AS 本周准产成品认购面积 ,
                ISNULL(rs.本周准产成品认购套数, 0) + ISNULL(rg.本周准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本周认购套数, 0) AS 本周准产成品认购套数 ,

                ISNULL(rs.本月准产成品认购金额, 0) + ISNULL(rg.本月准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本月认购金额, 0) AS 本月准产成品认购金额 ,
                ISNULL(rs.本月准产成品认购面积, 0) + ISNULL(rg.本月准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本月认购面积, 0) AS 本月准产成品认购面积 ,
                ISNULL(rs.本月准产成品认购套数, 0) + ISNULL(rg.本月准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本月认购套数, 0) AS 本月准产成品认购套数 ,

                ISNULL(qt.其他业绩准产成品本月认购金额, 0) AS 其他业绩准产成品本月认购金额 ,
                ISNULL(qt.其他业绩准产成品本月认购面积, 0) AS 其他业绩准产成品本月认购面积 ,
                ISNULL(qt.其他业绩准产成品本月认购套数, 0) AS 其他业绩准产成品本月认购套数 ,

                ISNULL(本月准产成品签约金额全口径, 0) AS 本月准产成品签约金额 ,
                ISNULL(本月准产成品签约面积全口径, 0) AS 本月准产成品签约面积 ,
                ISNULL(本月准产成品签约套数全口径, 0) AS 本月准产成品签约套数 ,

                ISNULL(qt.其他业绩准产成品本月签约金额, 0) AS 其他业绩准产成品本月签约金额 ,
                ISNULL(qt.其他业绩准产成品本月签约面积, 0) AS 其他业绩准产成品本月签约面积 ,
                ISNULL(qt.其他业绩准产成品本月签约套数, 0) AS 其他业绩准产成品本月签约套数 ,

                ISNULL(rs.累计准产成品已认购未签约金额, 0) AS 累计准产成品已认购未签约金额 ,
                ISNULL(rs.累计准产成品已认购未签约面积, 0) AS 累计准产成品已认购未签约面积 ,
                ISNULL(rs.累计准产成品已认购未签约套数, 0) AS 累计准产成品已认购未签约套数 ,

                ISNULL(rs.本年准产成品认购金额, 0) + ISNULL(rg.本年准产成品认购金额, 0) + ISNULL(qt.其他业绩准产成品本年认购金额, 0) AS 本年准产成品认购金额 ,
                ISNULL(rs.本年准产成品认购面积, 0) + ISNULL(rg.本年准产成品认购面积, 0) + ISNULL(qt.其他业绩准产成品本年认购面积, 0) AS 本年准产成品认购面积 ,
                ISNULL(rs.本年准产成品认购套数, 0) + ISNULL(rg.本年准产成品认购套数, 0) + ISNULL(qt.其他业绩准产成品本年认购套数, 0) AS 本年准产成品认购套数 ,

                ISNULL(s.本年准产成品签约金额全口径, 0) AS 本年准产成品签约金额 ,
                ISNULL(s.本年准产成品签约面积全口径, 0) AS 本年准产成品签约面积 ,
                ISNULL(s.本年准产成品签约套数全口径, 0) AS 本年准产成品签约套数 ,
                ISNULL(qt.其他业绩准产成品本年签约金额, 0) AS 其他业绩准产成品本年签约金额 ,
                ISNULL(qt.其他业绩准产成品本年签约面积, 0) AS 其他业绩准产成品本年签约面积 ,                
                ISNULL(qt.其他业绩准产成品本年签约套数, 0) AS 其他业绩准产成品本年签约套数 ,

                --补充现产成品任务和大户型任务@20250630
                ISNULL(rw.准产成品月度任务, 0) AS 准产成品月度任务,
                ISNULL(rw.准产成品年度任务, 0) AS 准产成品年度任务,
                ISNULL(rw.大户型月度任务, 0)   AS 大户型月度任务,
                ISNULL(rw.大户型年度任务, 0)   AS 大户型年度任务
        FROM    data_wide_dws_mdm_Project p
        INNER JOIN #TopProduct pt ON pt.ParentProjGUID = p.ProjGUID
        LEFT JOIN data_tb_hnyx_jdfxtb rw ON rw.projguid = p.ProjGUID AND   rw.业态 = pt.TopProductTypeName
        LEFT JOIN data_tb_hn_yxpq tb ON p.ProjGUID = tb.项目GUID
        LEFT JOIN #projsale s ON p.ProjGUID = s.orgguid AND pt.TopProductTypeName = s.TopProductTypeName
        LEFT JOIN #projsale_ldf_dhx dhx on p.ProjGUID = dhx.orgguid AND pt.TopProductTypeName = dhx.TopProductTypeName
        LEFT JOIN #rsale rs ON rs.ProjGUID = p.ProjGUID AND pt.TopProductTypeName = rs.TopProductTypeName
        LEFT JOIN #rg rg ON rg.ProjGUID = p.ProjGUID AND   pt.TopProductTypeName = rg.TopProductTypeName
        LEFT JOIN #qtqy qt ON qt.projguid = p.projguid AND pt.TopProductTypeName = qt.TopProductTypeName
        WHERE   Level = 2 AND   p.buguid = '70DD6DF4-47F7-46AF-B470-BC18EE57D8FF';

        --输出查询结果
        SELECT  * FROM  s_hnyxxp_projSaleNew WHERE  DATEDIFF(DAY, 数据清洗日期, @var_date) = 0;

        --删除临时表
        DROP TABLE #projsale,#projsale_ldf_dhx;
        DROP TABLE #rg;
        DROP TABLE #rsale;
        DROP TABLE #TopProduct;
        DROP TABLE #qtqy;
        DROP TABLE #qtyj;
    END;




