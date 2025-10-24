USE CRE_ERP_202_SYZL
GO


/*注意:要替换 MyCost_Erp352 以及数据库连接地址库名!!!!!!!
-- 2025年组织架构调整，4家平台公司的项目及业务数据合并处理
1、浙南合并进浙江，
2、齐鲁合并进山东，
3、大连合并进辽宁，
4、淮海合并进江苏
*/

--IF OBJECT_ID(N'tempdb..#proj', N'U') IS NOT NULL
--BEGIN
--    --删除临时表
--    DROP TABLE #proj;
--    PRINT '删除成功';
--END;

--PRINT '创建#proj临时表'
--SELECT *
--INTO   #proj
--FROM
--       (   SELECT *
--           FROM   p_Project
--           WHERE  ProjGUID IN ( '254d511e-bb86-e911-80b7-0a94ef7517dd', 'ab36794e-bb86-e911-80b7-0a94ef7517dd' ,
--                                '229f3d42-bc86-e911-80b7-0a94ef7517dd' , 'f6413af2-085a-e711-80ba-e61f13c57837' ,
--                                'fdb2af4f-41b2-e711-80ba-e61f13c57837' , '48c7c742-6cb8-e711-80ba-e61f13c57837' ,
--                                '1e4bf602-1a5a-e711-80ba-e61f13c57837' , '0424d56e-1a5a-e711-80ba-e61f13c57837' ,
--                                '2f1dfa41-a28c-e711-80ba-e61f13c57837' , '78672c40-a38c-e711-80ba-e61f13c57837' ,
--                                '491e0390-979a-e711-80ba-e61f13c57837' , 'e5c9d3eb-f3b9-e711-80ba-e61f13c57837' ,
--                                '860fa412-f5b9-e711-80ba-e61f13c57837' )
--           UNION
--           SELECT p1.*
--           FROM   dbo.p_Project p1
--                  LEFT JOIN p_Project p2 ON p1.ParentCode = p2.ProjCode
--           WHERE  p2.ProjGUID IN ( '254d511e-bb86-e911-80b7-0a94ef7517dd', 'ab36794e-bb86-e911-80b7-0a94ef7517dd' ,
--                                   '229f3d42-bc86-e911-80b7-0a94ef7517dd' , 'f6413af2-085a-e711-80ba-e61f13c57837' ,
--                                   'fdb2af4f-41b2-e711-80ba-e61f13c57837' , '48c7c742-6cb8-e711-80ba-e61f13c57837' ,
--                                   '1e4bf602-1a5a-e711-80ba-e61f13c57837' , '0424d56e-1a5a-e711-80ba-e61f13c57837' ,
--                                   '2f1dfa41-a28c-e711-80ba-e61f13c57837' , '78672c40-a38c-e711-80ba-e61f13c57837' ,
--                                   '491e0390-979a-e711-80ba-e61f13c57837' , 'e5c9d3eb-f3b9-e711-80ba-e61f13c57837' ,
--                                   '860fa412-f5b9-e711-80ba-e61f13c57837' )) t;

--SELECT * FROM  #proj
--SELECT * FROM #proj;

--SELECT roomcode,* FROM p_room a
--INNER  JOIN  #proj p ON a.ProjGUID =p.ProjGUID
--SELECT *
--FROM   dbo.myBusinessUnit
--WHERE  IsEndCompany =1 AND  BUName IN ( '无锡公司', '江苏公司' );

BEGIN
       DECLARE @var_oldbuguid UNIQUEIDENTIFIER;
       DECLARE @var_newbuguid UNIQUEIDENTIFIER;
       DECLARE @var_oldbucode VARCHAR(200);
       DECLARE @var_newbucode VARCHAR(200);
   
       -- 生成临时表
       SELECT t.*,
              bu.BUCode AS BUCodeold, -- 老公司编码
              bu1.BUCode AS BUCodeNew -- 新公司编码
       INTO   #dqy_proj
       FROM   MyCost_Erp352.dbo.dqy_proj_20250411 t
              INNER JOIN myBusinessUnit bu ON t.OldBuguid = bu.BUGUID
              INNER JOIN myBusinessUnit bu1 ON bu1.BUGUID = t.NewBuguid;

       -- 变量赋值
       SELECT @var_oldbuguid = oldbuguid,
              @var_newbuguid = newbuguid,
              @var_oldbucode = BUCodeold,
              @var_newbucode = BUCodeNew
       FROM   #dqy_proj;

       -- SET @var_oldbuguid = '8A08A706-0273-48BA-A1D4-6AB783024D42';
       -- SET @var_newbuguid = '82B9F9C5-9EF6-4878-B59B-5739213D1F3B';

       -- --赋值新老公司的bucode
       -- SELECT @var_oldbucode = BUCode FROM dbo.myBusinessUnit WHERE BUGUID = @var_oldbuguid;
       -- SELECT @var_newbucode = BUCode FROM dbo.myBusinessUnit WHERE BUGUID = @var_newbuguid;

       --公共数据表
       IF OBJECT_ID(N'p_room_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT r.*
              INTO   p_room_bak_20250411
              FROM   dbo.p_room r
                     INNER JOIN #dqy_proj t ON r.projguid = t.OldProjGuid
              -- WHERE  r.buguid <> t.newbuguid;
       END;

       UPDATE r
       SET    r.RoomCode = REPLACE(r.RoomCode, @var_oldbucode + '.', @var_newbucode + '.')
       FROM   p_room r
              INNER JOIN dbo.p_Project p ON p.ProjGUID = r.ProjGUID
              INNER JOIN #dqy_proj t ON r.projguid = t.OldProjGuid
       WHERE  p.ProjGUID IN (SELECT oldprojguid FROM #dqy_proj);

       PRINT '修改公共数据表p_room' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'p_RoomAdjustHistoryMx_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   p_RoomAdjustHistoryMx_bak_20250411
              FROM   dbo.p_RoomAdjustHistoryMx a
                     INNER JOIN dbo.p_room b ON a.RoomGUID = b.RoomGUID
                     INNER JOIN dbo.p_Project p ON p.ProjGUID = b.ProjGUID
              WHERE  p.ProjGUID IN (SELECT oldprojguid FROM #dqy_proj);
       END;

       UPDATE a
       SET    a.RoomCode = b.RoomCode
       FROM   dbo.p_RoomAdjustHistoryMx a
              INNER JOIN dbo.p_room b ON a.RoomGUID = b.RoomGUID
              INNER JOIN dbo.p_Project p ON p.ProjGUID = b.ProjGUID
       WHERE  p.ProjGUID IN (SELECT oldprojguid FROM #dqy_proj);

       PRINT '修改公共数据表p_RoomAdjustHistoryMx' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'p_Project_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   p_Project_bak_20250411
              FROM   dbo.p_Project a
              WHERE  a.ProjGUID IN (SELECT oldprojguid FROM #dqy_proj);
       END;
     
       UPDATE a
       SET    a.BUGUID = @var_newbuguid,
              a.ProjCode = REPLACE(a.ProjCode, @var_oldbucode, @var_newbucode),
              a.ParentCode = REPLACE(a.ParentCode, @var_oldbucode, @var_newbucode)
       FROM   dbo.p_Project a
       WHERE  a.ProjGUID IN (SELECT oldprojguid FROM #dqy_proj);

       PRINT '修改公共数据表p_Project' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'p_Building_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   p_Building_bak_20250411
              FROM   p_Building a
              WHERE  a.ProjGUID IN (SELECT oldprojguid FROM #dqy_proj);
       END;

       UPDATE a
       SET    a.BUGUID = @var_newbuguid,
              a.ParentCode = REPLACE(a.ParentCode, @var_oldbucode, @var_newbucode)
       FROM   p_Building a
       WHERE  a.ProjGUID IN (SELECT oldprojguid FROM #dqy_proj);

       PRINT '修改公共数据表p_Building' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       --  租赁业务表 修改  
       IF OBJECT_ID(N'y_RentAlterApply_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_RentAlterApply_bak_20250411
              FROM   y_RentAlterApply a
              WHERE  BUGUID = @var_oldbuguid and projguid in  ( SELECT oldprojguid FROM #dqy_proj )
       END;
     
       UPDATE y_RentAlterApply
       SET    BUGUID = @var_newbuguid
       WHERE  BUGUID = @var_oldbuguid and projguid in  ( SELECT oldprojguid FROM #dqy_proj )
       
       PRINT '修改y_RentAlterApply表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'y_IncomeMonthDetail_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_IncomeMonthDetail_bak_20250411
              FROM   y_IncomeMonthDetail a
              WHERE  BUGUID = @var_oldbuguid and projguid in  ( SELECT oldprojguid FROM #dqy_proj )
       END;

       UPDATE y_IncomeMonthDetail
       SET    BUGUID = @var_newbuguid
       WHERE  BUGUID = @var_oldbuguid and  projguid in  ( SELECT oldprojguid FROM #dqy_proj )

       PRINT '修改y_IncomeMonthDetail表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'y_IncomeMonthDetailTemp_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_IncomeMonthDetailTemp_bak_20250411
              FROM   y_IncomeMonthDetailTemp a
              WHERE  BUGUID = @var_oldbuguid and projguid in  ( SELECT oldprojguid FROM #dqy_proj )
       END;

       UPDATE y_IncomeMonthDetailTemp 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid and projguid in  ( SELECT oldprojguid FROM #dqy_proj )

       PRINT '修改y_IncomeMonthDetailTemp表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'y_IncomeMonthDetailTqjyTemp_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_IncomeMonthDetailTqjyTemp_bak_20250411
              FROM   y_IncomeMonthDetailTqjyTemp a
              WHERE  BUGUID = @var_oldbuguid and projguid in  ( SELECT oldprojguid FROM #dqy_proj )
       END;

       UPDATE y_IncomeMonthDetailTqjyTemp 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid and projguid in  ( SELECT oldprojguid FROM #dqy_proj )

       PRINT '修改y_IncomeMonthDetailTqjyTemp表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'y_Invoice_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_Invoice_bak_20250411
              FROM   y_Invoice a
              WHERE  BuGUID = @var_oldbuguid 
       END;

       UPDATE y_Invoice 
       SET    BuGUID = @var_newbuguid 
       WHERE  BuGUID = @var_oldbuguid;

       PRINT '修改y_Invoice表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'y_Agency2Unit_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_Agency2Unit_bak_20250411
              FROM   y_Agency2Unit a
              WHERE  BUGUID = @var_oldbuguid;
       END;

       UPDATE y_Agency2Unit 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid;

       PRINT '修改y_Agency2Unit表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'y_RentContract_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_RentContract_bak_20250411
              FROM   y_RentContract a
              WHERE  BUGUID = @var_oldbuguid and projguid in  ( SELECT oldprojguid FROM #dqy_proj )
       END;

       UPDATE y_RentContract 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid and projguid in  ( SELECT oldprojguid FROM #dqy_proj )

       PRINT '修改y_RentContract表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'y_RentOrder_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_RentOrder_bak_20250411
              FROM   y_RentOrder a
              WHERE  BUGUID = @var_oldbuguid and projguid in  ( SELECT oldprojguid FROM #dqy_proj )
       END;

       UPDATE y_RentOrder 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid and projguid in  ( SELECT oldprojguid FROM #dqy_proj )

       PRINT '修改y_RentOrder表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'y_RzBankCode_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_RzBankCode_bak_20250411
              FROM   y_RzBankCode a
              WHERE  BUGUID = @var_oldbuguid;
       END;

       UPDATE y_RzBankCode 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid;

       PRINT '修改y_RzBankCode表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       /* IF OBJECT_ID(N'y_CodeFormat_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_CodeFormat_bak_20250411
              FROM   y_CodeFormat a
              WHERE  BUGUID = @var_oldbuguid;
       END;

       UPDATE y_CodeFormat 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid;

       PRINT '修改y_CodeFormat表' + CONVERT(NVARCHAR(20), @@ROWCOUNT); */

       IF OBJECT_ID(N'y_FeeAdjustApply_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_FeeAdjustApply_bak_20250411
              FROM   y_FeeAdjustApply a
              WHERE  BUGUID = @var_oldbuguid and projguid in  ( SELECT oldprojguid FROM #dqy_proj )
       END;

       UPDATE y_FeeAdjustApply 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid and projguid in  ( SELECT oldprojguid FROM #dqy_proj )

       PRINT '修改y_FeeAdjustApply表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'y_FeeAdjustDetailIncome_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_FeeAdjustDetailIncome_bak_20250411
              FROM   y_FeeAdjustDetailIncome a
              inner join   y_FeeAdjustApply b on a.applyguid =b.applyguid 
              WHERE  a.BUGUID = @var_oldbuguid and b.projguid in  ( SELECT oldprojguid FROM #dqy_proj )
       END;

       UPDATE a 
       SET    a.BUGUID = @var_newbuguid 
              FROM   y_FeeAdjustDetailIncome a
              inner join   y_FeeAdjustApply b on a.applyguid =b.applyguid 
       WHERE  a.BUGUID = @var_oldbuguid and  b.projguid in  ( SELECT oldprojguid FROM #dqy_proj )

       PRINT '修改y_FeeAdjustDetailIncome表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'y_CstAttach_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_CstAttach_bak_20250411
              FROM   y_CstAttach a
              WHERE  BUGUID = @var_oldbuguid and   projguid in  ( SELECT oldprojguid FROM #dqy_proj )
       END;

       UPDATE y_CstAttach 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid and  projguid in  ( SELECT oldprojguid FROM #dqy_proj )

       PRINT '修改y_CstAttach表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       /*IF OBJECT_ID(N'y_YqGetZjLevel_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_YqGetZjLevel_bak_20250411
              FROM   y_YqGetZjLevel a
              WHERE  BUGUID = @var_oldbuguid;
       END;

       UPDATE y_YqGetZjLevel 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid;

       PRINT '修改y_YqGetZjLevel表' + CONVERT(NVARCHAR(20), @@ROWCOUNT); */

       IF OBJECT_ID(N'y_Discuss_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_Discuss_bak_20250411
              FROM   y_Discuss a
              WHERE  BUGUID = @var_oldbuguid and  projguid in  ( SELECT oldprojguid FROM #dqy_proj )
       END;

       UPDATE y_Discuss 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid and  projguid in  ( SELECT oldprojguid FROM #dqy_proj )

       PRINT '修改y_Discuss表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       

       IF OBJECT_ID(N'y_DiscussFollow_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_DiscussFollow_bak_20250411
              FROM   y_DiscussFollow a
              WHERE  BUGUID = @var_oldbuguid and  projguid in  ( SELECT oldprojguid FROM #dqy_proj )
       END;

       UPDATE y_DiscussFollow 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid and  projguid in  ( SELECT oldprojguid FROM #dqy_proj )

       PRINT '修改y_DiscussFollow表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'y_ZlzcEdition_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_ZlzcEdition_bak_20250411
              FROM   y_ZlzcEdition a 
              WHERE  BUGUID = @var_oldbuguid and  projguid in  ( SELECT oldprojguid FROM #dqy_proj )
       END;

       UPDATE y_ZlzcEdition 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid and  projguid in  ( SELECT oldprojguid FROM #dqy_proj )

       PRINT '修改y_ZlzcEdition表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'y_SfParameter_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_SfParameter_bak_20250411
              FROM   y_SfParameter a
              WHERE  BUGUID = @var_oldbuguid and  projguid in  ( SELECT oldprojguid FROM #dqy_proj )

       END;

       UPDATE y_SfParameter 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid and  projguid in  ( SELECT oldprojguid FROM #dqy_proj )


       PRINT '修改y_SfParameter表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'y_ContractType2Process_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_ContractType2Process_bak_20250411
              FROM   y_ContractType2Process a
              WHERE  BUGUID = @var_oldbuguid;
       END;

       UPDATE y_ContractType2Process 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid;

       PRINT '修改y_ContractType2Process表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

       IF OBJECT_ID(N'y_QuoteTakingSchemeSet_bak_20250411', N'U') IS NULL
       BEGIN
              SELECT a.*
              INTO   y_QuoteTakingSchemeSet_bak_20250411
              FROM   y_QuoteTakingSchemeSet a
              WHERE  BUGUID = @var_oldbuguid and  projguid in  ( SELECT oldprojguid FROM #dqy_proj )
       END;

       UPDATE y_QuoteTakingSchemeSet 
       SET    BUGUID = @var_newbuguid 
       WHERE  BUGUID = @var_oldbuguid and  projguid in  ( SELECT oldprojguid FROM #dqy_proj )

       PRINT '修改y_QuoteTakingSchemeSet表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);
END;