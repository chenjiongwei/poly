
	    -- 为查询添加合适的索引，优化查询性能
    -- 建议为表添加如下复合索引以高效支持查询条件（如有必要可调整字段顺序保证选择性）：
    -- CREATE NONCLUSTERED INDEX IX_s_集团开工申请楼栋明细表智能体数据提取_清洗日期_公司GUID_项目GUID_产品楼栋GUID
    -- ON s_集团开工申请楼栋明细表智能体数据提取 (清洗日期, 公司GUID, 项目GUID, 产品楼栋GUID);

    -- 查询本身无需更改，主要依赖索引优化
    SELECT *
    FROM s_集团开工申请楼栋明细表智能体数据提取 WITH (INDEX(IX_s_集团开工申请楼栋明细表智能体数据提取_清洗日期_公司GUID_项目GUID_产品楼栋GUID))
    WHERE 清洗日期 >= DATEADD(DAY, DATEDIFF(DAY, 0, @ChangeDate), 0)
      AND 清洗日期 <  DATEADD(DAY, DATEDIFF(DAY, 0, @ChangeDate) + 1, 0)
      AND (
            @DevelopmentCompanyGuid IS NULL
            OR 公司GUID IN (
                SELECT [Value] FROM dbo.fn_Split1(@DevelopmentCompanyGuid, ',')
            )
      )
      AND (
            @ProjGUID IS NULL
            OR 项目GUID IN (
                SELECT [Value] FROM dbo.fn_Split1(@ProjGUID, ',')
            )
      )
      AND (
            @BuildGUID IS NULL
            OR 产品楼栋GUID IN (
                SELECT [Value] FROM dbo.fn_Split1(@BuildGUID, ',')
            )
      )