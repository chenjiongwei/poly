-- 备份数据表
DECLARE @mbBGUID VARCHAR(50) -- 迁入公司的BUGUID
SET @mbBGUID = '8A08A706-0273-48BA-A1D4-6AB783024D42'

-- 备份数据表
SELECT *
INTO    p_cwjkObject_New_New_bak20240423
FROM    p_cwjkObject_New_New

SELECT  a.ObjectCode,
        b.DeptCostGUID,
        mb.DeptCostGUID,
        a.*,
        b.Year
FROM    p_cwjkObject_New_New a
        INNER JOIN ys_DeptCost b ON a.ObjectCode = CONVERT(VARCHAR(40), b.DeptCostGUID)
        INNER JOIN ys_DeptCost mb ON mb.CostCode = b.CostCode
                                    AND mb.Year = b.Year
                                    AND mb.BUGUID = @mbBGUID
WHERE   a.Application = 'FYXT'
        AND b.DeptCostGUID <> mb.DeptCostGUID
        AND b.Year = 2025

-- 更新修复数据的范围
UPDATE  a
SET     a.ObjectCode = mb.DeptCostGUID
--SELECT a.ObjectCode,b.DeptCostGUID,mb.DeptCostGUID, *
FROM    p_cwjkObject_New_New a
        INNER JOIN ys_DeptCost b ON a.ObjectCode = CONVERT(VARCHAR(40), b.DeptCostGUID)
        INNER JOIN ys_DeptCost mb ON mb.CostCode = b.CostCode
                                    AND mb.Year = b.Year
                                    AND mb.BUGUID = @mbBGUID
WHERE   a.Application = 'FYXT'
        AND b.DeptCostGUID <> mb.DeptCostGUID
        AND b.Year = 2025