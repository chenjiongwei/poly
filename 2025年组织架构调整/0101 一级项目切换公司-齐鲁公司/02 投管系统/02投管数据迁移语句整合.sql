USE ERP25
GO 
/*
-- 2025年组织架构调整，4家平台公司的项目及业务数据合并处理
1、浙南合并进浙江，
2、齐鲁合并进山东，
3、大连合并进辽宁，
4、淮海合并进江苏

*/
--exec [usp_Tg_UpdateTg_20250121] 
SET ANSI_NULLS ON;
GO

SET QUOTED_IDENTIFIER ON;
GO

-- alter PROC [dbo].[usp_Tg_UpdateTg_20250121]
-- AS
    /*
     修改投管系统项目所属平台公司信息
     */
    BEGIN


        SELECT  * INTO  #t FROM dqy_proj_20250411;

        PRINT '=====开始25迁移=====';

        IF OBJECT_ID(N'mdm_Project_bak_20250411', N'U') IS NULL
            SELECT  mp.*
            INTO    mdm_Project_bak_20250411
            FROM    mdm_Project mp
                    INNER JOIN #t t ON t.OldProjGUID = mp.ProjGUID OR  t.OldProjGUID = mp.ParentProjGUID;

        ---修改一级项目、分期所属平台公司GUID
        UPDATE  mp
        SET mp.DevelopmentCompanyGUID = t.NewDevelopmentCompanyGUID ,
            mp.OrgCompanyGUID = t.NewBuguid
        FROM    mdm_Project mp
                INNER JOIN #t t ON t.OldProjGUID = mp.ProjGUID OR  t.OldProjGUID = mp.ParentProjGUID
        WHERE   mp.DevelopmentCompanyGUID <> t.NewDevelopmentCompanyGUID;

        PRINT '项目表:mdm_Project' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'mdm_Project_Sync_bak_20250411', N'U') IS NULL
            SELECT  mp.*
            INTO    mdm_Project_Sync_bak_20250411
            FROM    mdm_Project_Sync mp
                    INNER JOIN #t t ON t.oldprojguid = mp.ProjGUID OR  t.oldprojguid = mp.ParentProjGUID;

        --修改mdm_Project_Sync表
        UPDATE  mdm_Project_Sync
        SET DevelopmentCompanyGUID = t.NewDevelopmentCompanyGUID
        FROM    mdm_Project_Sync mp
                INNER JOIN #t t ON t.oldprojguid = mp.ProjGUID OR  t.oldprojguid = mp.ParentProjGUID
        WHERE   mp.DevelopmentCompanyGUID <> t.NewDevelopmentCompanyGUID;

        PRINT '项目同步表:mdm_Project_Sync' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        --修改mdm_ProjLbEditApply 表 这个大概可以不迁移？
        --UPDATE a
        --SET    a.DevelopmentCompanyGUID = NewDevelopmentCompanyGUID
        --FROM   mdm_ProjLbEditApply a
        --       LEFT JOIN mdm_ProjLbEditApplyDtl b ON a.ProjLbEditApplyGUID = b.ProjLbEditApplyDtlGUID
        --       INNER JOIN #t t on b.projguid = t.oldprojguid
        --WHERE  a.DevelopmentCompanyGUID <> NewDevelopmentCompanyGUID;

        --备份表
        IF OBJECT_ID(N'mdm_BldAddType_bak_20250411', N'U') IS NULL
            SELECT  mp.*
            INTO    mdm_BldAddType_bak_20250411
            FROM    mdm_BldAddType mp
                    INNER JOIN #t t ON t.oldprojguid = mp.ProjGUID;

        --修改mdm_BldAddType表 
        UPDATE  mdm_BldAddType
        SET DevelopmentCompanyGUID = t.NewDevelopmentCompanyGUID
        FROM    mdm_BldAddType mp
                INNER JOIN #t t ON t.oldprojguid = mp.ProjGUID
        WHERE   mp.DevelopmentCompanyGUID <> t.NewDevelopmentCompanyGUID;

        PRINT 'mdm_BldAddType表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'mdm_GCBuildIndexSet_bak_20250411', N'U') IS NULL
            SELECT  mp.*
            INTO    mdm_GCBuildIndexSet_bak_20250411
            FROM    mdm_GCBuildIndexSet mp
                    INNER JOIN #t t ON t.oldprojguid = mp.ProjGUID;

        --修改mdm_GCBuildIndexSet
        UPDATE  mdm_GCBuildIndexSet
        SET DevelopmentCompanyGUID = NewDevelopmentCompanyGUID
        FROM    mdm_GCBuildIndexSet mp
                INNER JOIN #t t ON t.oldprojguid = mp.ProjGUID
        WHERE   mp.DevelopmentCompanyGUID <> t.NewDevelopmentCompanyGUID;

        PRINT 'mdm_GCBuildIndexSet表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'mdm_ProjCheckLevel_bak_20250411', N'U') IS NULL
            SELECT  mp.*
            INTO    mdm_ProjCheckLevel_bak_20250411
            FROM    mdm_ProjCheckLevel mp
                    INNER JOIN #t t ON t.OldProjGUID = mp.ProjGUID;

        --修改mdm_ProjCheckLevel
        UPDATE  mdm_ProjCheckLevel
        SET DevelopmentCompanyGUID = t.NewDevelopmentCompanyGUID
        FROM    mdm_ProjCheckLevel mp
                INNER JOIN #t t ON t.OldProjGUID = mp.ProjGUID
        WHERE   mp.DevelopmentCompanyGUID <> t.NewDevelopmentCompanyGUID;

        PRINT 'mdm_ProjCheckLevel表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        IF OBJECT_ID(N'p_LandInfo_bak_20250411', N'U') IS NULL
            SELECT  ld.*
            INTO    p_LandInfo_bak_20250411
            FROM    dbo.mdm_Project2Land a
                    INNER JOIN p_LandInfo ld ON ld.LandGUID = a.LandGUID
                    INNER JOIN mdm_Project mp ON a.ProjGUID = mp.ProjGUID
                    INNER JOIN #t t ON t.OldProjGUID = mp.ProjGUID OR  mp.ParentProjGUID = t.OldProjGUID;

        --刷新土地信息
        UPDATE  ld
        SET ld.CompanyGUID = mp.DevelopmentCompanyGUID
        FROM    dbo.mdm_Project2Land a
                INNER JOIN p_LandInfo ld ON ld.LandGUID = a.LandGUID
                INNER JOIN mdm_Project mp ON a.ProjGUID = mp.ProjGUID
                INNER JOIN #t t ON t.OldProjGUID = mp.ProjGUID OR  mp.ParentProjGUID = t.OldProjGUID
        WHERE   ld.CompanyGUID <> mp.DevelopmentCompanyGUID;

        PRINT '刷新土地信息p_LandInfo表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        /*	--刷新城市参数
			UPDATE  op
			SET op.CompanyGUID = NewDevelopmentCompanyGUID
			FROM    myBizParamOption op
			WHERE   op.ParamName = 'td_city' AND EXISTS (SELECT 1
															FROM   dbo.myBizParamOption a
																INNER JOIN mdm_Project mp ON mp.CityGUID = a.ParamGUID
																INNER JOIN dqy_proj_20250411 t ON t.OldProjGUID = mp.ProjGUID OR mp.ParentProjGUID = t.OldProjGUID
															WHERE  a.ParamName = 'td_city' AND (op.ParamCode = a.ParamCode OR  op.ParentCode = a.ParamCode));

			--插入城市公司
			INSERT INTO dbo.myBizParamOption(ParamName, ScopeGUID, ParamValue, ParamCode, ParentCode, ParamLevel, IfEnd, IfSys, ParamGUID, IsAjSk, IsQykxdc, TaxItemsDetailCode, IsCalcTax, CompanyGUID ,
												AreaInfo , IsLandCbDk, ReceiveTypeValue, myBizParamOptionGUID, IsYxfjxzf, ZTCategory)
			SELECT  TOP 1   ParamName ,
							NewDevelopmentCompanyGUID ,
							ParamValue ,
							ParamCode ,
							ParentCode ,
							ParamLevel ,
							IfEnd ,
							IfSys ,
							NEWID() ,
							IsAjSk ,
							IsQykxdc ,
							TaxItemsDetailCode ,
							IsCalcTax ,
							CompanyGUID ,
							AreaInfo ,
							IsLandCbDk ,
							ReceiveTypeValue ,
							NEWID() ,
							IsYxfjxzf ,
							ZTCategory
			FROM    dbo.myBizParamOption
			WHERE   ParamName = 'MDM_XMSSCSGS' AND  ParamValue = '无' AND NOT EXISTS (SELECT 1 FROM  myBizParamOption WHERE  ScopeGUID = NewDevelopmentCompanyGUID);
         */

        --把本次刷新的项目城市公司都刷新一遍
        UPDATE  mp
        SET mp.XMSSCSGSGUID = (SELECT   TOP 1   ParamGUID
                               FROM dbo.myBizParamOption
                               WHERE ParamName = 'MDM_XMSSCSGS' AND ScopeGUID = t.NewDevelopmentCompanyGUID)
        FROM    mdm_Project mp
                INNER JOIN #t t ON t.OldProjGUID = mp.ProjGUID OR  mp.ParentProjGUID = t.OldProjGUID
        WHERE   NOT EXISTS (SELECT  1
                            FROM    myBizParamOption op
                            WHERE   op.ParamGUID = mp.XMSSCSGSGUID AND  op.ScopeGUID = NewDevelopmentCompanyGUID);

        PRINT '把本次刷新的项目城市公司都刷新一遍' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        --刷新项目公司数据
        --备份
        IF OBJECT_ID(N'p_DevelopmentCompany_xm_bak_20250411', N'U') IS NULL
            SELECT  pdc.*
            INTO    p_DevelopmentCompany_xm_bak_20250411
            FROM    dbo.mdm_Project a
                    INNER JOIN #t t ON a.ProjGUID = t.OldProjGUID OR   a.ParentProjGUID = t.OldProjGUID
                    INNER JOIN dbo.p_DevelopmentCompany dc ON dc.DevelopmentCompanyGUID = a.DevelopmentCompanyGUID
                    INNER JOIN dbo.p_DevelopmentCompany pdc ON pdc.DevelopmentCompanyGUID = a.ProjCompanyGUID;

        --更新
        UPDATE  pdc
        SET pdc.ParentCompanyGUID = dc.DevelopmentCompanyGUID ,
            pdc.ParentCompanyName = dc.DevelopmentCompanyName
        FROM    dbo.mdm_Project a
                INNER JOIN #t t ON a.ProjGUID = t.OldProjGUID OR   a.ParentProjGUID = t.OldProjGUID
                INNER JOIN dbo.p_DevelopmentCompany dc ON dc.DevelopmentCompanyGUID = a.DevelopmentCompanyGUID
                INNER JOIN dbo.p_DevelopmentCompany pdc ON pdc.DevelopmentCompanyGUID = a.ProjCompanyGUID
        WHERE   dc.DevelopmentCompanyGUID = t.NewDevelopmentCompanyGUID;

        PRINT '刷新公司项目公司数据' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

        -- // 未关联项目的项目公司信息单独刷新
        -- 备份
        IF OBJECT_ID(N'p_DevelopmentCompany_bak_20250411', N'U') IS NULL
        BEGIN
            SELECT  dc.* 
            INTO    p_DevelopmentCompany_bak_20250411  
            FROM    p_DevelopmentCompany dc
                    INNER JOIN #t t ON t.OldDevelopmentCompanyGUID = dc.ParentCompanyGUID
            WHERE   dc.ParentCompanyGUID <> t.NewDevelopmentCompanyGUID


            UPDATE dc
            SET dc.ParentCompanyGUID = t.NewDevelopmentCompanyGUID
            FROM    p_DevelopmentCompany dc
                    INNER JOIN #t t ON t.OldDevelopmentCompanyGUID = dc.ParentCompanyGUID
            WHERE   dc.ParentCompanyGUID <> t.NewDevelopmentCompanyGUID;

            PRINT '刷新项目公司数据p_DevelopmentCompany' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
        END


        -- // 刷新项目公司的财务管理公司信息
        -- 备份
        IF OBJECT_ID(N'p_DevelopmentCompany_FinancialInfo_bak_20250411', N'U') IS NULL
            SELECT  fin.* 
            INTO    p_DevelopmentCompany_FinancialInfo_bak_20250411 
            FROM    p_DevelopmentCompany_FinancialInfo fin
                    INNER JOIN p_DevelopmentCompany dc ON fin.DevelopmentCompanyGUID = dc.DevelopmentCompanyGUID
            WHERE   fin.FinancialCompanyGUID <> dc.ParentCompanyGUID 
                    AND EXISTS (SELECT  1 FROM  #t  t WHERE  t.NewDevelopmentCompanyGUID = dc.ParentCompanyGUID);

        -- 更新
        UPDATE  fin 
        SET fin.FinancialCompanyGUID = dc.ParentCompanyGUID, 
            fin.FinancialCompany = dc.ParentCompanyName
        FROM    p_DevelopmentCompany_FinancialInfo fin
                INNER JOIN p_DevelopmentCompany dc ON fin.DevelopmentCompanyGUID = dc.DevelopmentCompanyGUID
        WHERE   fin.FinancialCompanyGUID <> dc.ParentCompanyGUID 
                AND EXISTS (SELECT  1 FROM  #t  t WHERE  t.NewDevelopmentCompanyGUID = dc.ParentCompanyGUID);

        PRINT '刷新项目公司的财务管理公司信息' + CONVERT(NVARCHAR(20), @@ROWCOUNT);



        --刷新合作方数据
        --缓存对应合作方公司数据
        -- 备份p_BelongCompany
        IF OBJECT_ID(N'p_BelongCompany_bak_20250411', N'U') IS NULL
            SELECT  a.* INTO    p_BelongCompany_bak_20250411 FROM   p_BelongCompany a;

        SELECT  mp.PartnerGUID ,
                mp.ProjGUID ,
                ROW_NUMBER() OVER (ORDER BY mp.ProjGUID) num
        INTO    #t1
        FROM    mdm_Project mp
                INNER JOIN #t t ON t.OldProjGUID = mp.ProjGUID OR  t.OldProjGUID = mp.ParentProjGUID;

        DECLARE @m INT = 1;
        DECLARE @n INT;

        SELECT  @n = COUNT(1)FROM   #t1;

        CREATE TABLE #part (PartnerGUID VARCHAR(MAX), ProjGUID VARCHAR(MAX));

        WHILE @m <= @n
            BEGIN
                INSERT INTO #part
                SELECT  Value ,
                        a.ProjGUID
                FROM    #t1 a
                        OUTER APPLY dbo.fn_Split2((SELECT   t1.PartnerGUID
                                                   FROM #t1 t1
                                                   WHERE   a.ProjGUID = t1.ProjGUID AND t1.num = @m), ';') AS b
                WHERE   Value <> '';

                SET @m = @m + 1;
            END;

        INSERT INTO dbo.p_BelongCompany(DevelopmentCompanyGUID, BelongCompanyGUID)
        SELECT  DISTINCT p.PartnerGUID ,
                         t.NewDevelopmentCompanyGUID
        FROM    #part p
                INNER JOIN #t t ON t.OldProjGUID = p.ProjGUID
        WHERE   NOT EXISTS (SELECT  1
                            FROM    p_BelongCompany b
                            WHERE   p.PartnerGUID = b.DevelopmentCompanyGUID AND b.BelongCompanyGUID = t.NewDevelopmentCompanyGUID);

        DROP TABLE #t1;
        DROP TABLE #part;

        PRINT '=====25迁移结束=====';

    END