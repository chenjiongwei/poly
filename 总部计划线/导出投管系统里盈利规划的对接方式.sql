-- 导出投管系统里盈利规划系统的对接方式

CREATE TABLE #ProjectListSetFillMode (
    Level INT,
    TreeCode VARCHAR(500),
    ProjGUID VARCHAR(500),
    ProjCode VARCHAR(500), 
    SpreadName VARCHAR(500),
    ProjName VARCHAR(500),
    Ylghsxfs VARCHAR(500),
    PrentYlghsxfs VARCHAR(500),
    YXCpf VARCHAR(500),
    GCCpf VARCHAR(500),
    CBCpf VARCHAR(500),
    SignReturn VARCHAR(500),
    CostAndUnilateral VARCHAR(500),
    Schedule VARCHAR(500),
    FinancialCarryover VARCHAR(500),
    IsCbSysManualEntry VARCHAR(500),
    ProjBill VARCHAR(500)
)

-- 插入临时表
SELECT DISTINCT 
    dc.DevelopmentCompanyGUID,
    dc.DevelopmentCompanyName 
INTO #dc
FROM mdm_Project p
INNER JOIN p_DevelopmentCompany dc ON dc.DevelopmentCompanyGUID = p.DevelopmentCompanyGUID

SELECT 
    ROW_NUMBER() OVER(ORDER BY DevelopmentCompanyName) AS rn,
    * 
INTO #dc_temp 
FROM #dc

DECLARE @count INT = 0
SELECT @count = COUNT(1) FROM #dc_temp
DECLARE @i INT = 1
DECLARE @DevelopmentCompanyGUID VARCHAR(50)

WHILE @i <= @count
BEGIN
    SELECT @DevelopmentCompanyGUID = DevelopmentCompanyGUID 
    FROM #dc_temp 
    WHERE rn = @i
    
    INSERT INTO #ProjectListSetFillMode
    EXEC usp_mdm_ProjectListSetFillMode @DevelopmentCompanyGUID
      
    SET @i = @i + 1
END

SELECT  
    dc.DevelopmentCompanyGUID AS 平台公司GUID,
    dc.DevelopmentCompanyName AS 平台公司名称,
    p.ProjGUID AS 项目GUID,
    p.ProjCode AS 项目代码,
    p.SpreadName AS 推广名,
    p.ProjName AS 项目名称,
    flg.投管代码,
    mp.Ylghsxfs AS 盈利规划上线方式,
    p.YXCpf AS 营销操盘方,
    p.GCCpf AS 工程操盘方,
    p.CBCpf AS 成本操盘方,
    p.SignReturn AS 盈利规划系统签约回笼,
    p.CostAndUnilateral AS 盈利规划系统成本及单方,
    p.Schedule AS 盈利规划系统计划进度,
    p.FinancialCarryover AS 盈利规划系统财务结转,
    p.IsCbSysManualEntry AS 成本系统是否手工录入成本
FROM #ProjectListSetFillMode p
INNER JOIN mdm_Project mp ON p.ProjGUID = mp.ProjGUID
INNER JOIN p_DevelopmentCompany dc ON dc.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
LEFT JOIN vmdm_projectFlag flg ON flg.ProjGUID = p.ProjGUID
ORDER BY dc.DevelopmentCompanyName, p.ProjCode