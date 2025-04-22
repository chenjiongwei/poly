--计划系统修数

--jd_ProjectPlanTemplate
-- 备份jd_ProjectPlanTemplate表
SELECT * INTO jd_ProjectPlanTemplate_20220225 FROM jd_ProjectPlanTemplate

-- 删除重复的jd_ProjectPlanTemplate记录
SELECT *
INTO delete_jd_ProjectPlanTemplate
FROM (
    SELECT *, 
    ROW_NUMBER() OVER (PARTITION BY name, code ORDER BY id) AS rn
    FROM jd_ProjectPlanTemplate
    WHERE buguid IN (
        SELECT newbuguid FROM dqy_proj_20250121
    )
) t
WHERE t.rn > 1

-- 从jd_ProjectPlanTemplate表中删除重复记录
DELETE FROM jd_ProjectPlanTemplate
WHERE id IN (
    SELECT id
    FROM (
        SELECT *, 
        ROW_NUMBER() OVER (PARTITION BY name, code ORDER BY id) AS rn
        FROM jd_ProjectPlanTemplate
        WHERE buguid IN (
            SELECT newbuguid FROM dqy_proj_20250121
        )
    ) t
    WHERE t.rn > 1
);

--jd_ProjectPlanTemplateTask
-- 删除与已删除的jd_ProjectPlanTemplate记录关联的jd_ProjectPlanTemplateTask记录
SELECT * 
INTO jd_ProjectPlanTemplateTask_delete
FROM jd_ProjectPlanTemplateTask
WHERE ProjectPlanTemplateID IN (
    SELECT id FROM delete_jd_ProjectPlanTemplate
)

-- 从jd_ProjectPlanTemplateTask表中删除与已删除的jd_ProjectPlanTemplate记录关联的记录
delete from jd_ProjectPlanTemplateTask where ProjectPlanTemplateID in (
select id from delete_jd_ProjectPlanTemplate
)

--jd_ProjectPlanExecute
-- 查找jd_ProjectPlanExecute表中TemplatePlanID与备份表jd_ProjectPlanExecute_bak_20220223不匹配的记录
SELECT DISTINCT a.id
FROM jd_ProjectPlanExecute a
INNER JOIN jd_ProjectPlanExecute_bak_20220223 b ON a.id = b.id
WHERE a.TemplatePlanID <> b.TemplatePlanID


-- 备份jd_ProjectPlanExecute表
SELECT * INTO jd_ProjectPlanExecute_20220225 FROM jd_ProjectPlanExecute


-- 更新jd_ProjectPlanExecute表中的TemplatePlanID为新的jd_ProjectPlanTemplate记录的ID
UPDATE jd_ProjectPlanExecute
SET TemplatePlanID = ne.id
FROM jd_ProjectPlanExecute jd
INNER JOIN delete_jd_ProjectPlanTemplate t ON jd.TemplatePlanID = t.id
INNER JOIN jd_ProjectPlanTemplate ne ON ne.name = t.name AND ne.buguid = jd.buguid
WHERE jd.id IN (
    SELECT DISTINCT a.id
    FROM jd_ProjectPlanExecute a
    INNER JOIN jd_ProjectPlanExecute_bak_20220223 b ON a.id = b.id
    WHERE a.TemplatePlanID <> b.TemplatePlanID
)

--jd_DeptExaminePeriod
-- 备份jd_DeptExaminePeriod表
SELECT * INTO jd_DeptExaminePeriod_20220225 FROM jd_DeptExaminePeriod

-- 删除重复的jd_DeptExaminePeriod记录
SELECT *
INTO delete_jd_DeptExaminePeriod
FROM (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY buguid, day ORDER BY id) AS rn
    FROM jd_DeptExaminePeriod
    WHERE buguid IN (
        SELECT newbuguid FROM dqy_proj_20250121
    )
) t
WHERE t.rn > 1

-- 显示jd_DeptExaminePeriod表中的所有记录
select * from jd_DeptExaminePeriod

-- 从jd_DeptExaminePeriod表中删除重复记录
DELETE FROM jd_DeptExaminePeriod
WHERE id IN (
    SELECT id
    FROM (
        SELECT *, ROW_NUMBER() OVER (PARTITION BY buguid, day ORDER BY id) AS rn
        FROM jd_DeptExaminePeriod
        WHERE buguid IN (
            SELECT newbuguid FROM dqy_proj_20250121
        )
    ) t
    WHERE t.rn > 1
);