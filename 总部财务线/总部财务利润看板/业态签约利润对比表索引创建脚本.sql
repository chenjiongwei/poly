USE [HighData_prod]
GO

/*
  业态签约利润对比表索引优化脚本
  
  索引优化目标：
  1. 提升查询性能 - 特别是针对存储过程中的查询和筛选操作
  2. 优化连接操作 - 针对与临时表的连接操作创建合适的索引
  3. 提升数据筛选效率 - 针对常用的筛选条件创建索引
  4. 创建覆盖索引 - 包含常用查询列的索引，避免回表操作
  
  注意事项：
  - 索引会占用额外的存储空间
  - 索引会影响数据修改操作的性能(INSERT/UPDATE/DELETE)
  - 请根据实际查询模式和数据量调整索引策略
*/

-- 1. 清洗时间索引 - 用于按时间筛选数据，如存储过程中的删除当天数据操作
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_业态签约利润对比表_清洗时间' AND object_id = OBJECT_ID('dbo.业态签约利润对比表'))
BEGIN
    CREATE INDEX IX_业态签约利润对比表_清洗时间 ON dbo.业态签约利润对比表(清洗时间)
    PRINT '创建索引：IX_业态签约利润对比表_清洗时间 完成'
END

-- 2. 项目GUID和明源匹配主键的组合索引 - 用于关联查询，如存储过程中的多表连接
-- 这是一个关键索引，用于优化与临时表的连接操作
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_业态签约利润对比表_项目GUID_明源匹配主键' AND object_id = OBJECT_ID('dbo.业态签约利润对比表'))
BEGIN
    CREATE INDEX IX_业态签约利润对比表_项目GUID_明源匹配主键 ON dbo.业态签约利润对比表(项目GUID, 明源匹配主键)
    PRINT '创建索引：IX_业态签约利润对比表_项目GUID_明源匹配主键 完成'
END

-- 3. 清洗版本索引 - 用于按版本筛选数据
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_业态签约利润对比表_清洗版本' AND object_id = OBJECT_ID('dbo.业态签约利润对比表'))
BEGIN
    CREATE INDEX IX_业态签约利润对比表_清洗版本 ON dbo.业态签约利润对比表(清洗版本)
    PRINT '创建索引：IX_业态签约利润对比表_清洗版本 完成'
END

-- 4. 公司索引 - 用于按公司筛选数据
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_业态签约利润对比表_公司' AND object_id = OBJECT_ID('dbo.业态签约利润对比表'))
BEGIN
    CREATE INDEX IX_业态签约利润对比表_公司 ON dbo.业态签约利润对比表(公司)
    PRINT '创建索引：IX_业态签约利润对比表_公司 完成'
END

-- 5. 产品类型索引 - 用于按产品类型筛选数据
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_业态签约利润对比表_产品类型' AND object_id = OBJECT_ID('dbo.业态签约利润对比表'))
BEGIN
    CREATE INDEX IX_业态签约利润对比表_产品类型 ON dbo.业态签约利润对比表(产品类型)
    PRINT '创建索引：IX_业态签约利润对比表_产品类型 完成'
END

-- 6. 投管代码索引 - 用于按投管代码筛选数据
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_业态签约利润对比表_投管代码' AND object_id = OBJECT_ID('dbo.业态签约利润对比表'))
BEGIN
    CREATE INDEX IX_业态签约利润对比表_投管代码 ON dbo.业态签约利润对比表(投管代码)
    PRINT '创建索引：IX_业态签约利润对比表_投管代码 完成'
END

-- 7. 业态组合键索引 - 用于按业态组合键筛选数据
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_业态签约利润对比表_业态组合键' AND object_id = OBJECT_ID('dbo.业态签约利润对比表'))
BEGIN
    CREATE INDEX IX_业态签约利润对比表_业态组合键 ON dbo.业态签约利润对比表(业态组合键)
    PRINT '创建索引：IX_业态签约利润对比表_业态组合键 完成'
END

-- 8. 复合索引 - 项目、产品类型、产品名称、装修标准、商品类型
-- 这个复合索引用于优化多条件筛选查询
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_业态签约利润对比表_项目产品组合' AND object_id = OBJECT_ID('dbo.业态签约利润对比表'))
BEGIN
    CREATE INDEX IX_业态签约利润对比表_项目产品组合 ON dbo.业态签约利润对比表(项目, 产品类型, 产品名称, 装修标准, 商品类型)
    PRINT '创建索引：IX_业态签约利润对比表_项目产品组合 完成'
END

-- 9. 包含筛选条件的索引
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_业态签约利润对比表_是否并表' AND object_id = OBJECT_ID('dbo.业态签约利润对比表'))
BEGIN
    CREATE INDEX IX_业态签约利润对比表_是否并表 ON dbo.业态签约利润对比表(是否并表)
    PRINT '创建索引：IX_业态签约利润对比表_是否并表 完成'
END

-- 10. 获取日期索引 - 用于按获取日期筛选数据
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_业态签约利润对比表_获取日期' AND object_id = OBJECT_ID('dbo.业态签约利润对比表'))
BEGIN
    CREATE INDEX IX_业态签约利润对比表_获取日期 ON dbo.业态签约利润对比表(获取日期)
    PRINT '创建索引：IX_业态签约利润对比表_获取日期 完成'
END

-- 11. 覆盖索引示例 - 包含了查询中常用的列，避免回表操作
-- 这个索引可以覆盖一些常见的查询，提高查询效率
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_业态签约利润对比表_覆盖索引' AND object_id = OBJECT_ID('dbo.业态签约利润对比表'))
BEGIN
    CREATE INDEX IX_业态签约利润对比表_覆盖索引 ON dbo.业态签约利润对比表(项目GUID, 明源匹配主键)
    INCLUDE (公司, 项目, 产品类型, 产品名称, 签约_25年签约, 签约不含税_25年签约, 净利润_25年签约, 净利率_25年签约)
    PRINT '创建索引：IX_业态签约利润对比表_覆盖索引 完成'
END

-- 12. 筛选索引 - 只为特定数据创建索引
-- 这个索引只包含"地下室/车库"产品类型的数据，可以提高针对该类型的查询效率
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_业态签约利润对比表_筛选索引_车库' AND object_id = OBJECT_ID('dbo.业态签约利润对比表'))
BEGIN
    CREATE INDEX IX_业态签约利润对比表_筛选索引_车库 ON dbo.业态签约利润对比表(产品类型, 签约均价_25年签约)
    WHERE 产品类型 = '地下室/车库'
    PRINT '创建索引：IX_业态签约利润对比表_筛选索引_车库 完成'
END

-- 查看索引创建情况
PRINT '所有索引创建完成，以下是当前表的索引列表：'
EXEC sp_helpindex 'dbo.业态签约利润对比表'

/*
  索引维护建议：
  
  1. 定期重建或重组索引以减少碎片化
     - 当索引碎片率 > 30% 时重建索引
     - 当索引碎片率在 5%-30% 之间时重组索引
  
  2. 监控索引使用情况
     - 使用 sys.dm_db_index_usage_stats 视图监控索引的使用情况
     - 删除长期不被使用的索引
  
  3. 定期更新统计信息
     - 使用 UPDATE STATISTICS 命令更新统计信息
  
  示例维护脚本:
  
  -- 检查索引碎片情况
  SELECT 
      OBJECT_NAME(ind.OBJECT_ID) AS TableName,
      ind.name AS IndexName,
      indexstats.index_type_desc AS IndexType,
      indexstats.avg_fragmentation_in_percent
  FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) indexstats
  INNER JOIN sys.indexes ind ON ind.object_id = indexstats.object_id
      AND ind.index_id = indexstats.index_id
  WHERE OBJECT_NAME(ind.OBJECT_ID) = '业态签约利润对比表'
  ORDER BY indexstats.avg_fragmentation_in_percent DESC;
*/ 