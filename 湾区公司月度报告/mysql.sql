-- 方法1: 使用UPDATE JOIN语法
UPDATE testtab a 
INNER JOIN testage b ON a.id = b.id
SET a.age = b.age;

-- 方法2: 使用子查询
UPDATE testtab 
SET age = (
    SELECT age 
    FROM testage 
    WHERE testage.id = testtab.id
);

-- 方法3: 使用INNER JOIN的另一种写法 
UPDATE testtab, testage 
SET testtab.age = testage.age
WHERE testtab.id = testage.id;



-- 关闭安全模式
SET SQL_SAFE_UPDATES = 0;

UPDATE x_st_leadopportunity a
INNER JOIN hisprotemp b ON a.leadopportunityguid = b.proguid
SET a.x_code = b.procode;

-- 完成后最好重新启用安全模式
SET SQL_SAFE_UPDATES = 1;

select  a.x_code , b.procode
from x_st_leadopportunity a
INNER JOIN hisprotemp b ON a.leadopportunityguid = b.proguid