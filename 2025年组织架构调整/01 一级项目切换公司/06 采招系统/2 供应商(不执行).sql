/*
将老公司的供应商的所属公司和服务范围插入到新公司
不用执行，待迁移后第二天从筑龙同步供应商数据
*/
USE MyCost_Erp352;
GO
BEGIN
    DECLARE @var_newbucode VARCHAR(50);
    DECLARE @var_newbuguid UNIQUEIDENTIFIER;
    DECLARE @var_oldbucode VARCHAR(50);
    DECLARE @var_oldbuguid UNIQUEIDENTIFIER;
    DECLARE @new_buname VARCHAR(500);
    DECLARE @old_buname VARCHAR(500);

    SELECT t.OldBuguid,
           NewBuguid,
           ROW_NUMBER() OVER (PARTITION BY 1 ORDER BY t.OldBuguid) num
    INTO #bu
    FROM
    (SELECT DISTINCT OldBuguid, NewBuguid FROM dqy_proj_20240613) t;

    --数据备份 
    SELECT *
    INTO cg_ProductServiceProperty_bak_20240613
    FROM cg_ProductServiceProperty;

    SELECT *
    INTO p_provider2unit_bak_20240613
    FROM p_Provider2Unit;

    SELECT *
    INTO p_provider2servicecompany_bak_20240613
    FROM p_Provider2ServiceCompany;

    --按照公司循环插入数据 
    DECLARE @i INT;

    SET @i = 1;

    DECLARE @num INT;

    SELECT @num = MAX(num)
    FROM #bu;

    WHILE (@i <= @num)
    BEGIN
        SELECT @var_newbuguid = NewBuguid,
               @var_oldbuguid = OldBuguid
        FROM dbo.#bu
        WHERE num = @i;

        SELECT @var_newbucode = HierarchyCode,
               @new_buname = BUName
        FROM dbo.myBusinessUnit
        WHERE IsEndCompany = 1
              AND BUGUID = @var_newbuguid;

        SELECT @var_oldbucode = HierarchyCode,
               @old_buname = BUName
        FROM dbo.myBusinessUnit
        WHERE IsEndCompany = 1
              AND BUGUID = @var_oldbuguid;

        PRINT '开始插入：' + @new_buname + '公司数据：\n';

        --插入
        INSERT INTO p_Provider2Unit
        (
            Provider2UnitGUID,
            ProviderGUID,
            BUCode,
            IsCreate,
            IsFromDs,
            DsCreateBUGUID
        )
        SELECT NEWID() AS Provider2UnitGUID,
               ProviderGUID,
               @var_newbucode AS bucode,
               0 AS iscreate,
               IsFromDs,
               DsCreateBUGUID
        FROM p_Provider2Unit
        WHERE bucode = @var_oldbucode
              AND ProviderGUID NOT IN
                  (
                      SELECT DISTINCT
                             ProviderGUID
                      FROM p_Provider2Unit
                      WHERE BUCode = @var_newbucode
                  );

        --============================================== 
        --插入
        INSERT INTO p_Provider2ServiceCompany
        (
            Provider2ServiceCompanyGUID,
            ProviderGUID,
            BUGUID,
            Provider2ServiceGUID,
            ProductTypeCode,
            CreateDate,
            CreatedBy,
            CreatedByGUID,
            ServiceCompanyGradeGUID,
            LandContractorGradeGUID,
            IsFromDs,
            DsCreateBUGUID,
            IsBlacklist
        )
        SELECT NEWID() AS Provider2ServiceCompanyGUID,
               ProviderGUID,
               @var_newbuguid AS BUGUID,
               Provider2ServiceGUID,
               ProductTypeCode,
               CreateDate,
               CreatedBy,
               CreatedByGUID,
               ServiceCompanyGradeGUID,
               LandContractorGradeGUID,
               IsFromDs,
               DsCreateBUGUID,
               IsBlacklist
        FROM p_Provider2ServiceCompany
        WHERE Provider2ServiceCompanyGUID NOT IN
              (
                  SELECT a.Provider2ServiceCompanyGUID
                  FROM p_Provider2ServiceCompany a
                      INNER JOIN
                      (SELECT * FROM p_Provider2ServiceCompany WHERE BUGUID = @var_newbuguid) t
                          ON a.ProviderGUID = t.ProviderGUID
                             AND a.ProductTypeCode = t.ProductTypeCode
                             AND a.Provider2ServiceGUID = t.Provider2ServiceGUID
                  WHERE a.BUGUID = @var_oldbuguid
              )
              AND BUGUID = @var_oldbuguid;

        --==============================================
        --插入
        INSERT INTO cg_ProductServiceProperty
        SELECT NEWID() AS productservicepropertyguid,
               Provider2ServiceGUID,
               ProviderGUID,
               ProductTypeName,
               @var_newbuguid AS BUGUID,
               @new_buname BUName,
               ProductLevel,
               BrandType,
               JCType,
               Remarks,
               IsFromDs,
               DsCreateBUGUID
        FROM
        (
            SELECT DISTINCT
                   a.Provider2ServiceGUID,
                   a.ProviderGUID,
                   a.ProductTypeName,
                   a.BUGUID,
                   a.BUName,
                   a.ProductLevel,
                   a.BrandType,
                   a.JCType,
                   a.Remarks,
                   a.IsFromDs,
                   a.DsCreateBUGUID
            FROM cg_ProductServiceProperty a
                LEFT JOIN
                (SELECT * FROM cg_ProductServiceProperty WHERE BUGUID = @var_newbuguid) b
                    ON a.Provider2ServiceGUID = b.Provider2ServiceGUID
                       AND a.ProviderGUID = b.ProviderGUID
            WHERE a.BUGUID = @var_oldbuguid
                  AND b.ProductServicePropertyGUID IS NULL
        ) t;

        PRINT '结束插入：' + @new_buname + '公司数据：';

        SET @i = @i + 1;
    END;
END;