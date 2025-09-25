-- HD 数据集统计
SELECT 
    b.CatalogName, 
    a.datasetname, 
    a.*
FROM 
    mdc_DataSet a
    LEFT JOIN [dbo].[mdc_DatasetCatalog] b 
        ON a.CatalogGUID = b.CatalogGUID
WHERE 
    a.SqlText LIKE '%增量%' 
    OR a.SqlText LIKE '%存量%'


-- 数见数据集
