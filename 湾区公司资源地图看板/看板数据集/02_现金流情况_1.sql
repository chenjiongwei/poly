,
[统计维度],
[公司名称]      ,[城市]
      ,[片区]
      ,[镇街]
      ,[项目名称]
      ,[外键关联]
      ,[时间]
      ,convert(varchar(10),清洗时间,121) + [外键关联] + [时间] as [主键ID]
      ,case 
            when 时间 = '本月' then convert(varchar(10),清洗时间,121) + [外键关联] + '已实现' 
            when 时间 = '本年' then convert(varchar(10),清洗时间,121) + [外键关联] + '已实现' 
            else null 
       end as [父级层级]
      ,[经营性现金流]
      ,[现金流入]
      ,[现金流出]
      ,[地价]
      ,[直投]
      ,[费用]
      ,[税金]
      ,[贷款]
      ,[股东现金流]
      ,[营销费用]
      ,[财务费用]
      ,[管理费用]
FROM [dbo].[wqzydtBi_cashflowinfo]
WHERE (统计维度 <> '项目' AND 时间 NOT IN ('全盘', '未实现')) 
   OR 统计维度 = '项目'
   AND DATEDIFF(year, 清洗时间, GETDATE()) = 0