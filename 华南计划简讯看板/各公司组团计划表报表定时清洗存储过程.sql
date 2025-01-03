TRUNCATE TABLE jd_PlanTaskExecuteObjectForReport;

SELECT p.projguid,
       p.buguid,
       p.ParentCode,
       pw.BuildGUID,
       pw.PreSaleProgress,
       pw.CheckStandard,
       pw.Name pwname,
       sw.Name swname,
       p.ProjShortName,
       IsFirstStart,
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '计划完成时间') AS '项目获取计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '预计完成时间') AS '项目获取预计完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '实际完成时间') AS '项目获取实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '工作项状态') AS '项目获取工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '延期天数') AS '项目获取延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '责任部门') AS '项目获取责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '定位报告', '计划完成时间') AS '定位报告计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '定位报告', '实际完成时间') AS '定位报告实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '定位报告', '工作项状态') AS '定位报告工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '定位报告', '延期天数') AS '定位报告延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '定位报告', '责任部门') AS '定位报告责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '修详规设计完成', '计划完成时间') AS '修详规设计完成计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '修详规设计完成', '实际完成时间') AS '修详规设计完成实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '修详规设计完成', '工作项状态') AS '修详规设计完成工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '修详规设计完成', '延期天数') AS '修详规设计完成延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '修详规设计完成', '责任部门') AS '修详规设计完成责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '修详规意见批复', '计划完成时间') AS '修详规意见批复计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '修详规意见批复', '实际完成时间') AS '修详规意见批复实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '修详规意见批复', '工作项状态') AS '修详规意见批复工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '修详规意见批复', '延期天数') AS '修详规意见批复延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '修详规意见批复', '责任部门') AS '修详规意见批复责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '售楼部、展示区正式开放', '计划完成时间') AS '售楼部展示区正式开放计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '售楼部、展示区正式开放', '实际完成时间') AS '售楼部展示区正式开放实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '售楼部、展示区正式开放', '工作项状态') AS '售楼部展示区正式开放工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '售楼部、展示区正式开放', '延期天数') AS '售楼部展示区正式开放延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '售楼部、展示区正式开放', '责任部门') AS '售楼部展示区正式开放责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '施工图审查备案完成', '计划完成时间') AS '施工图审查备案完成计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '施工图审查备案完成', '实际完成时间') AS '施工图审查备案完成实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '施工图审查备案完成', '工作项状态') AS '施工图审查备案完成工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '施工图审查备案完成', '延期天数') AS '施工图审查备案完成延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '施工图审查备案完成', '责任部门') AS '施工图审查备案完成责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '获取建规证', '计划完成时间') AS '获取建规证计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '获取建规证', '实际完成时间') AS '获取建规证实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '获取建规证', '工作项状态') AS '获取建规证工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '获取建规证', '延期天数') AS '获取建规证延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '获取建规证', '责任部门') AS '获取建规证责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '计划完成时间') AS '实际开工计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '预计完成时间') AS '实际开工预计完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '实际完成时间') AS '实际开工实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '工作项状态') AS '实际开工工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '延期天数') AS '实际开工延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '实际开工', '责任部门') AS '实际开工责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '正式开工', '计划完成时间') AS '正式开工计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '正式开工', '预计完成时间') AS '正式开工预计完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '正式开工', '实际完成时间') AS '正式开工实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '正式开工', '工作项状态') AS '正式开工工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '正式开工', '延期天数') AS '正式开工延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '正式开工', '责任部门') AS '正式开工责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '基坑开挖完成', '计划完成时间') AS '基坑开挖完成计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '基坑开挖完成', '实际完成时间') AS '基坑开挖完成实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '基坑开挖完成', '工作项状态') AS '基坑开挖完成工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '基坑开挖完成', '延期天数') AS '基坑开挖完成延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '基坑开挖完成', '责任部门') AS '基坑开挖完成责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '基础施工完成', '计划完成时间') AS '基础施工完成计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '基础施工完成', '实际完成时间') AS '基础施工完成实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '基础施工完成', '工作项状态') AS '基础施工完成工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '基础施工完成', '延期天数') AS '基础施工完成延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '基础施工完成', '责任部门') AS '基础施工完成责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '地下结构完成', '计划完成时间') AS '地下结构完成计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '地下结构完成', '预计完成时间') AS '地下结构完成预计完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '地下结构完成', '实际完成时间') AS '地下结构完成实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '地下结构完成', '工作项状态') AS '地下结构完成工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '地下结构完成', '延期天数') AS '地下结构完成延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '地下结构完成', '责任部门') AS '地下结构完成责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '达到预售形象', '计划完成时间') AS '达到预售形象计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '达到预售形象', '预计完成时间') AS '达到预售形象预计完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '达到预售形象', '实际完成时间') AS '达到预售形象实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '达到预售形象', '工作项状态') AS '达到预售形象工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '达到预售形象', '延期天数') AS '达到预售形象延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '达到预售形象', '责任部门') AS '达到预售形象责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '预售办理', '计划完成时间') AS '预售办理计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '预售办理', '预计完成时间') AS '预售办理预计完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '预售办理', '实际完成时间') AS '预售办理实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '预售办理', '工作项状态') AS '预售办理工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '预售办理', '延期天数') AS '预售办理延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '预售办理', '责任部门') AS '预售办理责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '计划完成时间') AS '开盘销售计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '预计完成时间') AS '开盘销售预计完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '实际完成时间') AS '开盘销售实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '工作项状态') AS '开盘销售工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '延期天数') AS '开盘销售延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '开盘销售', '责任部门') AS '开盘销售责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '主体结构封顶', '计划完成时间') AS '主体结构封顶计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '主体结构封顶', '预计完成时间') AS '主体结构封顶预计完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '主体结构封顶', '实际完成时间') AS '主体结构封顶实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '主体结构封顶', '工作项状态') AS '主体结构封顶工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '主体结构封顶', '延期天数') AS '主体结构封顶延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '主体结构封顶', '责任部门') AS '主体结构封顶责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '抹灰工程完成', '计划完成时间') AS '抹灰工程完成计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '抹灰工程完成', '实际完成时间') AS '抹灰工程完成实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '抹灰工程完成', '工作项状态') AS '抹灰工程完成工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '抹灰工程完成', '延期天数') AS '抹灰工程完成延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '抹灰工程完成', '责任部门') AS '抹灰工程完成责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '全部移交精装完成', '计划完成时间') AS '全部移交精装完成计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '全部移交精装完成', '实际完成时间') AS '全部移交精装完成实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '全部移交精装完成', '工作项状态') AS '全部移交精装完成工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '全部移交精装完成', '延期天数') AS '全部移交精装完成延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '全部移交精装完成', '责任部门') AS '全部移交精装完成责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '外墙装饰工程完成', '计划完成时间') AS '外墙装饰工程完成计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '外墙装饰工程完成', '实际完成时间') AS '外墙装饰工程完成实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '外墙装饰工程完成', '工作项状态') AS '外墙装饰工程完成工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '外墙装饰工程完成', '延期天数') AS '外墙装饰工程完成延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '外墙装饰工程完成', '责任部门') AS '外墙装饰工程完成责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '内部装修工程完成', '计划完成时间') AS '内部装修工程完成计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '内部装修工程完成', '实际完成时间') AS '内部装修工程完成实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '内部装修工程完成', '工作项状态') AS '内部装修工程完成工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '内部装修工程完成', '延期天数') AS '内部装修工程完成延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '内部装修工程完成', '责任部门') AS '内部装修工程完成责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '分户验收完成', '计划完成时间') AS '分户验收完成计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '分户验收完成', '实际完成时间') AS '分户验收完成实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '分户验收完成', '工作项状态') AS '分户验收完成工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '分户验收完成', '延期天数') AS '分户验收完成延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '分户验收完成', '责任部门') AS '分户验收完成责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '园林及配套工程完成', '计划完成时间') AS '园林及配套工程完成计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '园林及配套工程完成', '实际完成时间') AS '园林及配套工程完成实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '园林及配套工程完成', '工作项状态') AS '园林及配套工程完成工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '园林及配套工程完成', '延期天数') AS '园林及配套工程完成延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '园林及配套工程完成', '责任部门') AS '园林及配套工程完成责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '计划完成时间') AS '竣工备案计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '预计完成时间') AS '竣工备案预计完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '实际完成时间') AS '竣工备案实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '工作项状态') AS '竣工备案工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '延期天数') AS '竣工备案延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '责任部门') AS '竣工备案责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '交付准备', '计划完成时间') AS '交付准备计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '交付准备', '预计完成时间') AS '交付准备预计完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '交付准备', '实际完成时间') AS '交付准备实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '交付准备', '工作项状态') AS '交付准备工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '交付准备', '延期天数') AS '交付准备延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '交付准备', '责任部门') AS '交付准备责任部门',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '集中交付', '计划完成时间') AS '集中交付计划完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '集中交付', '预计完成时间') AS '集中交付预计完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '集中交付', '实际完成时间') AS '集中交付实际完成时间',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '集中交付', '工作项状态') AS '集中交付工作项状态',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '集中交付', '延期天数') AS '集中交付延期天数',
       dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '集中交付', '责任部门') AS '集中交付责任部门',
       CASE
           WHEN IsFirst = 1 THEN
                CASE
                    WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '正式开工', '计划完成时间') IS NOT NULL
                         AND dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '计划完成时间') IS NOT NULL THEN
                         DATEDIFF(
                                     DAY,
                                     dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '计划完成时间'),
                                     dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '正式开工', '计划完成时间')
                                 )
                END
       END AS '计划总报建时间',
       CASE
           WHEN IsFirst = 1 THEN
                CASE
                    WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '正式开工', '实际完成时间') IS NOT NULL
                         AND dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '实际完成时间') IS NOT NULL THEN
                         DATEDIFF(
                                     DAY,
                                     dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '实际完成时间'),
                                     dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '正式开工', '实际完成时间')
                                 )
                END
       END AS '实际总报建时间',
       CASE
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '正式开工', '计划完成时间') IS NOT NULL
                AND dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '计划完成时间') IS NOT NULL THEN
                DATEDIFF(
                            DAY,
                            dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '正式开工', '计划完成时间'),
                            dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '计划完成时间')
                        )
       END AS '计划总建设时间',
       CASE
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '正式开工', '实际完成时间') IS NOT NULL
                AND dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '实际完成时间') IS NOT NULL THEN
                DATEDIFF(
                            DAY,
                            dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '正式开工', '实际完成时间'),
                            dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '实际完成时间')
                        )
       END AS '实际总建设时间',
       CASE
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '计划完成时间') IS NOT NULL
                AND dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '计划完成时间') IS NOT NULL THEN
                DATEDIFF(
                            DAY,
                            dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '计划完成时间'),
                            dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '计划完成时间')
                        )
       END AS '计划总开发时间',
       CASE
           WHEN dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '实际完成时间') IS NOT NULL
                AND dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '实际完成时间') IS NOT NULL THEN
                DATEDIFF(
                            DAY,
                            dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '项目获取', '实际完成时间'),
                            dbo.fn_jd_PlanTaskExecuteObject(jp.ID, '竣工备案', '实际完成时间')
                        )
       END AS '实际总开发时间'
INTO #t
FROM dbo.p_Project p
     INNER JOIN p_HkbBiddingSectionWork sw ON sw.ProjGUID = p.ProjGUID
     INNER JOIN p_HkbBiddingBuildingWork pw ON pw.BidGUID = sw.BidGUID
     INNER JOIN jd_ProjectPlanExecute jp ON jp.ObjectID = pw.BuildGUID
WHERE p.IfEnd = 1
      AND jp.PlanType = 103
      AND jp.IsExamin = 1;



SELECT DISTINCT
       bu.BUGUID,
       t.ProjGUID,
       p1.ProjGUID TopProjguid,
       t.BuildGUID Ztguid,
       bu.BUName AS '公司',
       ISNULL(mb1.ParamValue, mb.ParamValue) 一级城市公司, --加城市公司 add by z 20201228
       mb.ParamValue 二级城市公司,
       p3.ProjCode AS '投管项目编码',
       lb.LbProjectValue 投管代码,
       p3.ProjName AS '投管项目名称',
       p1.ProjName AS '一级项目名称',
       t.ProjShortName AS '项目分期',
       p3.XMHQFS AS '项目获取方式',
       t.swName AS '标段名称',
       t.pwName AS '计划组团名称',
       CASE
           WHEN cyj.TgType = '停工' THEN
                '停工'
           WHEN cyj.TgType = '缓建' THEN
                '缓建'
           ELSE '正常'
       END AS '是否停工',
       dww.productname AS '组团业态',
       dww.DownNum AS '地库总层数',
       dww.UpNum AS '单体楼层数',
       dww.zxbz AS '交付标准',
       t.CheckStandard 验收标准,
       wk.BuildArea AS '计划组团建筑面积',
       CASE
           WHEN IsFirstStart = 1 THEN
                '是'
           ELSE '否'
       END AS '是否为首开组团',
       '' AS '冬歇期',
       t.PreSaleProgress AS '预售形象',
       wk.buildingname AS '关联工程楼栋',
       项目获取计划完成时间,
       项目获取预计完成时间,
       项目获取实际完成时间,
       项目获取工作项状态,
       项目获取延期天数,
       项目获取责任部门,
       定位报告计划完成时间,
       定位报告实际完成时间,
       定位报告工作项状态,
       定位报告延期天数,
       定位报告责任部门,
       修详规设计完成计划完成时间,
       修详规设计完成实际完成时间,
       修详规设计完成工作项状态,
       修详规设计完成延期天数,
       修详规设计完成责任部门,
       修详规意见批复计划完成时间,
       修详规意见批复实际完成时间,
       修详规意见批复工作项状态,
       修详规意见批复延期天数,
       修详规意见批复责任部门,
       售楼部展示区正式开放计划完成时间,
       售楼部展示区正式开放实际完成时间,
       售楼部展示区正式开放工作项状态,
       售楼部展示区正式开放延期天数,
       售楼部展示区正式开放责任部门,
       施工图审查备案完成计划完成时间,
       施工图审查备案完成实际完成时间,
       施工图审查备案完成工作项状态,
       施工图审查备案完成延期天数,
       施工图审查备案完成责任部门,
       获取建规证计划完成时间,
       获取建规证实际完成时间,
       获取建规证工作项状态,
       获取建规证延期天数,
       获取建规证责任部门,
       正式开工计划完成时间,
       正式开工预计完成时间,
       正式开工实际完成时间,
       正式开工工作项状态,
       正式开工延期天数,
       正式开工责任部门,
       基坑开挖完成计划完成时间,
       基坑开挖完成实际完成时间,
       基坑开挖完成工作项状态,
       基坑开挖完成延期天数,
       基坑开挖完成责任部门,
       基础施工完成计划完成时间,
       基础施工完成实际完成时间,
       基础施工完成工作项状态,
       基础施工完成延期天数,
       基础施工完成责任部门,
       地下结构完成计划完成时间,
       地下结构完成预计完成时间,
       地下结构完成实际完成时间,
       地下结构完成工作项状态,
       地下结构完成延期天数,
       地下结构完成责任部门,
       达到预售形象计划完成时间,
       达到预售形象预计完成时间,
       达到预售形象实际完成时间,
       达到预售形象工作项状态,
       达到预售形象延期天数,
       达到预售形象责任部门,
       预售办理计划完成时间,
       预售办理预计完成时间,
       预售办理实际完成时间,
       预售办理工作项状态,
       预售办理延期天数,
       预售办理责任部门,
       开盘销售计划完成时间,
       开盘销售预计完成时间,
       开盘销售实际完成时间,
       开盘销售工作项状态,
       开盘销售延期天数,
       开盘销售责任部门,
       主体结构封顶计划完成时间,
       主体结构封顶预计完成时间,
       主体结构封顶实际完成时间,
       主体结构封顶工作项状态,
       主体结构封顶延期天数,
       主体结构封顶责任部门,
       抹灰工程完成计划完成时间,
       抹灰工程完成实际完成时间,
       抹灰工程完成工作项状态,
       抹灰工程完成延期天数,
       抹灰工程完成责任部门,
       全部移交精装完成计划完成时间,
       全部移交精装完成实际完成时间,
       全部移交精装完成工作项状态,
       全部移交精装完成延期天数,
       全部移交精装完成责任部门,
       外墙装饰工程完成计划完成时间,
       外墙装饰工程完成实际完成时间,
       外墙装饰工程完成工作项状态,
       外墙装饰工程完成延期天数,
       外墙装饰工程完成责任部门,
       内部装修工程完成计划完成时间,
       内部装修工程完成实际完成时间,
       内部装修工程完成工作项状态,
       内部装修工程完成延期天数,
       内部装修工程完成责任部门,
       分户验收完成计划完成时间,
       分户验收完成实际完成时间,
       分户验收完成工作项状态,
       分户验收完成延期天数,
       分户验收完成责任部门,
       园林及配套工程完成计划完成时间,
       园林及配套工程完成实际完成时间,
       园林及配套工程完成工作项状态,
       园林及配套工程完成延期天数,
       园林及配套工程完成责任部门,
       竣工备案计划完成时间,
       竣工备案预计完成时间,
       竣工备案实际完成时间,
       竣工备案工作项状态,
       竣工备案延期天数,
       竣工备案责任部门,
       集中交付计划完成时间,
       集中交付预计完成时间,
       集中交付实际完成时间,
       集中交付工作项状态,
       集中交付延期天数,
       集中交付责任部门,
       计划总报建时间,
       实际总报建时间,
       计划总建设时间,
       实际总建设时间,
       计划总开发时间,
       实际总开发时间,
       实际开工计划完成时间,
       实际开工预计完成时间,
       实际开工实际完成时间,
       实际开工工作项状态,
       实际开工延期天数,
       实际开工责任部门,
       交付准备计划完成时间,
       交付准备实际完成时间,
       交付准备工作项状态,
       交付准备延期天数,
       交付准备责任部门,
       wk.UpBuild AS '地上面积',
       wk.DownBuildArea AS '地下面积'
INTO #tr
FROM #t t
     LEFT JOIN dbo.p_Project p1 ON p1.ProjCode = t.ParentCode
     LEFT JOIN p_HkbProjectWork p2 ON p2.ProjGUID = p1.ProjGUID
     LEFT JOIN ERP25.dbo.mdm_Project p3 ON p3.ProjGUID = p2.RefernceProjectGUID
     LEFT JOIN ERP25.dbo.mdm_LbProject lb ON lb.projGUID = p3.ProjGUID
                                             AND lb.LbProject = 'tgid'
     LEFT JOIN ERP25.dbo.myBizParamOption mb ON p3.XMSSCSGSGUID = mb.ParamGUID
     LEFT JOIN ERP25.dbo.myBizParamOption mb1 ON mb.ParentCode = mb1.ParamCode
                                                 AND mb1.ParamName = 'mdm_XMSSCSGS'
                                                 AND mb.ScopeGUID = mb1.ScopeGUID
     LEFT JOIN
     (
         SELECT projGUID,
                MAX(LbProjectValue) AS LbProjectValue
         FROM ERP25..mdm_LbProject
         WHERE LbProject = 'sfnrtj'
         GROUP BY projGUID
     ) con ON con.projguid = t.ProjGUID
     INNER JOIN dbo.myBusinessUnit bu ON bu.BUGUID = t.BUGUID
     LEFT JOIN
     (
         SELECT DISTINCT
                d.ObjectID,
                tg.TgType
         FROM
         (
             SELECT ROW_NUMBER() OVER (PARTITION BY tg.PlanID ORDER BY ApplicationTime DESC) num,
                    tg.PlanID,
                    tg.Type TgType
             FROM MyCost_Erp352.dbo.jd_StopOrReturnWork tg
             WHERE tg.ApplyState = '已审核'
         ) tg
         LEFT JOIN MyCost_Erp352.dbo.jd_ProjectPlanTaskExecute f ON f.PlanID = tg.PlanID
                                                                    AND f.Level = '1'
         LEFT JOIN MyCost_Erp352.dbo.jd_ProjectPlanExecute d ON d.ID = f.PlanID
                                                                AND d.PlanType = '103'
         WHERE tg.num = 1
               AND d.ObjectID IS NOT NULL
     ) cyj ON cyj.ObjectID = t.BuildGUID
     LEFT JOIN
     (
         SELECT DISTINCT
                a.*,
                CASE
                    WHEN b.BuildGUID IS NULL THEN
                         '毛坯'
                    ELSE '装修'
                END zxbz,
                c.UpNum,
                d.DownNum
         FROM
         (
             SELECT pw.BuildGUID,
                    pw.BuildFullName,
                    pd.ProductName,
                    ROW_NUMBER() OVER (PARTITION BY pw.BuildGUID ORDER BY pb.BuildArea DESC) xh
             FROM
             (
                 SELECT *
                 FROM
                 (
                     SELECT VersionGUID,
                            ProjGUID,
                            InValidReason,
                            IsActive,
                            Level,
                            CreateDate,
                            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) rowno
                     FROM MyCost_Erp352..md_Project
                     WHERE md_Project.ApproveState = '已审核'
                           AND ISNULL(InValidReason, '') <> '补录'
                 ) t
                 WHERE t.rowno = 1
             ) a
             LEFT JOIN p_HkbBiddingSectionWork sw ON sw.projguid = a.projguid
             LEFT JOIN p_HkbBiddingBuildingWork pw ON pw.BidGUID = sw.BidGUID
             LEFT JOIN dbo.p_HkbBiddingBuilding2BuildingWork bw ON bw.BudGUID = pw.BuildGUID
             LEFT JOIN dbo.md_GCBuild gc ON gc.BldGUID = bw.BuildingGUID
                                            AND a.VersionGUID = gc.VersionGUID
             LEFT JOIN dbo.md_ProductBuild pb ON pb.BldGUID = gc.BldGUID
                                                 AND pb.VersionGUID = a.VersionGUID
             LEFT JOIN dbo.md_Product pd ON pd.ProductGUID = pb.ProductGUID
                                            AND pd.VersionGUID = a.VersionGUID
             WHERE a.Level = 3
         ) a
         LEFT JOIN
         (
             SELECT pw.BuildGUID
             FROM
             (
                 SELECT *
                 FROM
                 (
                     SELECT VersionGUID,
                            ProjGUID,
                            InValidReason,
                            IsActive,
                            Level,
                            CreateDate,
                            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) rowno
                     FROM MyCost_Erp352..md_Project
                     WHERE md_Project.ApproveState = '已审核'
                           AND ISNULL(InValidReason, '') <> '补录'
                 ) t
                 WHERE t.rowno = 1
             ) a
             LEFT JOIN p_HkbBiddingSectionWork sw ON sw.ProjGUID = a.projguid
             LEFT JOIN p_HkbBiddingBuildingWork pw ON pw.BidGUID = sw.BidGUID
             LEFT JOIN dbo.p_HkbBiddingBuilding2BuildingWork bw ON bw.BudGUID = pw.BuildGUID
             LEFT JOIN dbo.md_GCBuild gc ON gc.BldGUID = bw.BuildingGUID
                                            AND a.VersionGUID = gc.VersionGUID
             LEFT JOIN dbo.md_ProductBuild pb ON pb.BldGUID = gc.BldGUID
                                                 AND pb.VersionGUID = a.VersionGUID
             LEFT JOIN
             (
                 SELECT ProductBuildGUID,
                        a.VersionGUID,
                        ROW_NUMBER() OVER (PARTITION BY a.ProductBuildGUID ORDER BY CreateDate DESC) rowno,
                        CASE
                            WHEN pp.IsManualManageProductBld = 1 THEN
                                 a.IsSale
                            ELSE e.IsSale
                        END AS IsSale
                 FROM MyCost_Erp352..md_ProductBuild a
                      LEFT JOIN MyCost_Erp352..md_Product e ON e.ProductKeyGUID = a.ProductKeyGUID
                      LEFT JOIN MyCost_Erp352..md_Project b ON a.VersionGUID = b.VersionGUID
                      LEFT JOIN
                      (
                          SELECT ProjGUID,
                                 IsManualManageProductBld
                          FROM MyCost_Erp352..md_Project
                          WHERE Level = 2
                          GROUP BY ProjGUID,
                                   IsManualManageProductBld
                      ) pp ON pp.projguid = b.ParentProjGUID
             ) ww ON ww.ProductBuildGUID = pb.ProductBuildGUID
                     AND ww.VersionGUID = a.VersionGUID
             LEFT JOIN dbo.md_Product pd ON pd.ProductGUID = pb.ProductGUID
                                            AND pd.VersionGUID = a.VersionGUID
             WHERE a.Level = 3
                   AND pb.Zxbz = '装修'
                   AND ww.IsSale = '是'
         ) b ON a.BuildGUID = b.BuildGUID
         LEFT JOIN
         (
             SELECT pw.BuildGUID,
                    gc.UpNum,
                    ROW_NUMBER() OVER (PARTITION BY pw.BuildGUID ORDER BY gc.UpNum DESC) xh
             FROM
             (
                 SELECT *
                 FROM
                 (
                     SELECT VersionGUID,
                            ProjGUID,
                            InValidReason,
                            IsActive,
                            Level,
                            CreateDate,
                            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) rowno
                     FROM MyCost_Erp352..md_Project
                     WHERE md_Project.ApproveState = '已审核'
                           AND ISNULL(InValidReason, '') <> '补录'
                 ) t
                 WHERE t.rowno = 1
             ) a
             LEFT JOIN p_HkbBiddingSectionWork sw ON sw.projguid = a.projguid
             LEFT JOIN p_HkbBiddingBuildingWork pw ON pw.BidGUID = sw.BidGUID
             LEFT JOIN dbo.p_HkbBiddingBuilding2BuildingWork bw ON bw.BudGUID = pw.BuildGUID
             LEFT JOIN dbo.md_GCBuild gc ON gc.BldGUID = bw.BuildingGUID
                                            AND a.VersionGUID = gc.VersionGUID
             LEFT JOIN dbo.md_ProductBuild pb ON pb.BldGUID = gc.BldGUID
                                                 AND pb.VersionGUID = a.VersionGUID
             LEFT JOIN dbo.md_Product pd ON pd.ProductGUID = pb.ProductGUID
                                            AND pd.VersionGUID = a.VersionGUID
             WHERE a.Level = 3
         ) c ON c.BuildGUID = a.BuildGUID
         LEFT JOIN
         (
             SELECT pw.BuildGUID,
                    gc.DownNum,
                    ROW_NUMBER() OVER (PARTITION BY pw.BuildGUID ORDER BY gc.DownNum DESC) xh
             FROM
             (
                 SELECT *
                 FROM
                 (
                     SELECT VersionGUID,
                            ProjGUID,
                            InValidReason,
                            IsActive,
                            Level,
                            CreateDate,
                            ROW_NUMBER() OVER (PARTITION BY ProjGUID ORDER BY CreateDate DESC) rowno
                     FROM MyCost_Erp352..md_Project
                     WHERE md_Project.ApproveState = '已审核'
                           AND ISNULL(InValidReason, '') <> '补录'
                 ) t
                 WHERE t.rowno = 1
             ) a
             LEFT JOIN p_HkbBiddingSectionWork sw ON sw.projguid = a.projguid
             LEFT JOIN p_HkbBiddingBuildingWork pw ON pw.BidGUID = sw.BidGUID
             LEFT JOIN dbo.p_HkbBiddingBuilding2BuildingWork bw ON bw.BudGUID = pw.BuildGUID
             LEFT JOIN dbo.md_GCBuild gc ON gc.BldGUID = bw.BuildingGUID
                                            AND a.VersionGUID = gc.VersionGUID
             LEFT JOIN dbo.md_ProductBuild pb ON pb.BldGUID = gc.BldGUID
                                                 AND pb.VersionGUID = a.VersionGUID
             LEFT JOIN dbo.md_Product pd ON pd.ProductGUID = pb.ProductGUID
                                            AND pd.VersionGUID = a.VersionGUID
             WHERE a.Level = 3
                   AND pw.BuildGUID IS NOT NULL
         ) d ON d.BuildGUID = a.BuildGUID
                AND d.xh = '1'
         WHERE a.xh = 1
               AND c.xh = 1
               AND a.BuildGUID IS NOT NULL
     ) dww ON dww.BuildGUID = t.BuildGUID
     LEFT JOIN
     (
         SELECT a.BudGUID,
                SUM(ISNULL(gc.UpBuildArea, 0) + ISNULL(gc.DownBuildArea, 0)) AS BuildArea,
                SUM(ISNULL(gc.UpBuildArea, 0)) AS UpBuild,
                SUM(ISNULL(gc.DownBuildArea, 0)) AS DownBuildArea,
                (
                    SELECT STUFF(
                           (
                               SELECT ';' + BuildingName
                               FROM p_HkbBiddingBuilding2BuildingWork
                               WHERE a.BudGUID = p_HkbBiddingBuilding2BuildingWork.BudGUID
                               FOR XML PATH('')
                           ),
                           1,
                           1,
                           ''
                                )
                ) AS buildingname
         FROM dbo.p_HkbBiddingBuilding2BuildingWork a
              INNER JOIN ERP25.dbo.mdm_GCBuild gc ON gc.GCBldGUID = a.BuildingGUID
         GROUP BY a.BudGUID
     ) wk ON wk.BudGUID = t.BuildGUID
WHERE ISNULL(con.LbProjectValue, '是') = '是';


INSERT INTO MyCost_Erp352.dbo.jd_PlanTaskExecuteObjectForReport
(
    buguid,
    公司,
    投管项目编码,
    投管代码,
    投管项目名称,
    一级项目名称,
    项目分期,
    项目获取方式,
    标段名称,
    计划组团名称,
    组团业态,
    地库总层数,
    单体楼层数,
    交付标准,
    验收标准,
    计划组团建筑面积,
    是否为首开组团,
    冬歇期,
    预售形象,
    关联工程楼栋,
    项目获取计划完成时间,
    项目获取预计完成时间,
    项目获取实际完成时间,
    项目获取工作项状态,
    项目获取延期天数,
    项目获取责任部门,
    定位报告计划完成时间,
    定位报告实际完成时间,
    定位报告工作项状态,
    定位报告延期天数,
    定位报告责任部门,
    修详规设计完成计划完成时间,
    修详规设计完成实际完成时间,
    修详规设计完成工作项状态,
    修详规设计完成延期天数,
    修详规设计完成责任部门,
    修详规意见批复计划完成时间,
    修详规意见批复实际完成时间,
    修详规意见批复工作项状态,
    修详规意见批复延期天数,
    修详规意见批复责任部门,
    售楼部展示区正式开放计划完成时间,
    售楼部展示区正式开放实际完成时间,
    售楼部展示区正式开放工作项状态,
    售楼部展示区正式开放延期天数,
    售楼部展示区正式开放责任部门,
    施工图审查备案完成计划完成时间,
    施工图审查备案完成实际完成时间,
    施工图审查备案完成工作项状态,
    施工图审查备案完成延期天数,
    施工图审查备案完成责任部门,
    获取建规证计划完成时间,
    获取建规证实际完成时间,
    获取建规证工作项状态,
    获取建规证延期天数,
    获取建规证责任部门,
    正式开工计划完成时间,
    正式开工预计完成时间,
    正式开工实际完成时间,
    正式开工工作项状态,
    正式开工延期天数,
    正式开工责任部门,
    基坑开挖完成计划完成时间,
    基坑开挖完成实际完成时间,
    基坑开挖完成工作项状态,
    基坑开挖完成延期天数,
    基坑开挖完成责任部门,
    基础施工完成计划完成时间,
    基础施工完成实际完成时间,
    基础施工完成工作项状态,
    基础施工完成延期天数,
    基础施工完成责任部门,
    地下结构完成计划完成时间,
    地下结构完成预计完成时间,
    地下结构完成实际完成时间,
    地下结构完成工作项状态,
    地下结构完成延期天数,
    地下结构完成责任部门,
    达到预售形象计划完成时间,
    达到预售形象预计完成时间,
    达到预售形象实际完成时间,
    达到预售形象工作项状态,
    达到预售形象延期天数,
    达到预售形象责任部门,
    预售办理计划完成时间,
    预售办理预计完成时间,
    预售办理实际完成时间,
    预售办理工作项状态,
    预售办理延期天数,
    预售办理责任部门,
    开盘销售计划完成时间,
    开盘销售预计完成时间,
    开盘销售实际完成时间,
    开盘销售工作项状态,
    开盘销售延期天数,
    开盘销售责任部门,
    主体结构封顶计划完成时间,
    主体结构封顶预计完成时间,
    主体结构封顶实际完成时间,
    主体结构封顶工作项状态,
    主体结构封顶延期天数,
    主体结构封顶责任部门,
    抹灰工程完成计划完成时间,
    抹灰工程完成实际完成时间,
    抹灰工程完成工作项状态,
    抹灰工程完成延期天数,
    抹灰工程完成责任部门,
    全部移交精装完成计划完成时间,
    全部移交精装完成实际完成时间,
    全部移交精装完成工作项状态,
    全部移交精装完成延期天数,
    全部移交精装完成责任部门,
    外墙装饰工程完成计划完成时间,
    外墙装饰工程完成实际完成时间,
    外墙装饰工程完成工作项状态,
    外墙装饰工程完成延期天数,
    外墙装饰工程完成责任部门,
    内部装修工程完成计划完成时间,
    内部装修工程完成实际完成时间,
    内部装修工程完成工作项状态,
    内部装修工程完成延期天数,
    内部装修工程完成责任部门,
    分户验收完成计划完成时间,
    分户验收完成实际完成时间,
    分户验收完成工作项状态,
    分户验收完成延期天数,
    分户验收完成责任部门,
    园林及配套工程完成计划完成时间,
    园林及配套工程完成实际完成时间,
    园林及配套工程完成工作项状态,
    园林及配套工程完成延期天数,
    园林及配套工程完成责任部门,
    竣工备案计划完成时间,
    竣工备案预计完成时间,
    竣工备案实际完成时间,
    竣工备案工作项状态,
    竣工备案延期天数,
    竣工备案责任部门,
    集中交付计划完成时间,
    集中交付预计完成时间,
    集中交付实际完成时间,
    集中交付工作项状态,
    集中交付延期天数,
    集中交付责任部门,
    计划总报建时间,
    实际总报建时间,
    计划总建设时间,
    实际总建设时间,
    计划总开发时间,
    实际总开发时间,
    实际开工计划完成时间,
    实际开工预计完成时间,
    实际开工实际完成时间,
    实际开工工作项状态,
    实际开工延期天数,
    实际开工责任部门,
    交付准备计划完成时间,
    交付准备实际完成时间,
    交付准备工作项状态,
    交付准备延期天数,
    交付准备责任部门,
    地上面积,
    地下面积,
    是否停工,
    projguid,
    TopProjguid,
    ztguid,
    一级城市公司,
    二级城市公司
)
SELECT DISTINCT
       buguid,
       公司,
       投管项目编码,
       投管代码,
       投管项目名称,
       一级项目名称,
       项目分期,
       项目获取方式,
       标段名称,
       计划组团名称,
       组团业态,
       地库总层数,
       单体楼层数,
       交付标准,
       验收标准,
       计划组团建筑面积,
       是否为首开组团,
       冬歇期,
       预售形象,
       关联工程楼栋,
       项目获取计划完成时间,
       项目获取预计完成时间,
       项目获取实际完成时间,
       项目获取工作项状态,
       项目获取延期天数,
       项目获取责任部门,
       定位报告计划完成时间,
       定位报告实际完成时间,
       定位报告工作项状态,
       定位报告延期天数,
       定位报告责任部门,
       修详规设计完成计划完成时间,
       修详规设计完成实际完成时间,
       修详规设计完成工作项状态,
       修详规设计完成延期天数,
       修详规设计完成责任部门,
       修详规意见批复计划完成时间,
       修详规意见批复实际完成时间,
       修详规意见批复工作项状态,
       修详规意见批复延期天数,
       修详规意见批复责任部门,
       售楼部展示区正式开放计划完成时间,
       售楼部展示区正式开放实际完成时间,
       售楼部展示区正式开放工作项状态,
       售楼部展示区正式开放延期天数,
       售楼部展示区正式开放责任部门,
       施工图审查备案完成计划完成时间,
       施工图审查备案完成实际完成时间,
       施工图审查备案完成工作项状态,
       施工图审查备案完成延期天数,
       施工图审查备案完成责任部门,
       获取建规证计划完成时间,
       获取建规证实际完成时间,
       获取建规证工作项状态,
       获取建规证延期天数,
       获取建规证责任部门,
       正式开工计划完成时间,
       正式开工预计完成时间,
       正式开工实际完成时间,
       正式开工工作项状态,
       正式开工延期天数,
       正式开工责任部门,
       基坑开挖完成计划完成时间,
       基坑开挖完成实际完成时间,
       基坑开挖完成工作项状态,
       基坑开挖完成延期天数,
       基坑开挖完成责任部门,
       基础施工完成计划完成时间,
       基础施工完成实际完成时间,
       基础施工完成工作项状态,
       基础施工完成延期天数,
       基础施工完成责任部门,
       地下结构完成计划完成时间,
       地下结构完成预计完成时间,
       地下结构完成实际完成时间,
       地下结构完成工作项状态,
       地下结构完成延期天数,
       地下结构完成责任部门,
       达到预售形象计划完成时间,
       达到预售形象预计完成时间,
       达到预售形象实际完成时间,
       达到预售形象工作项状态,
       达到预售形象延期天数,
       达到预售形象责任部门,
       预售办理计划完成时间,
       预售办理预计完成时间,
       预售办理实际完成时间,
       预售办理工作项状态,
       预售办理延期天数,
       预售办理责任部门,
       开盘销售计划完成时间,
       开盘销售预计完成时间,
       开盘销售实际完成时间,
       开盘销售工作项状态,
       开盘销售延期天数,
       开盘销售责任部门,
       主体结构封顶计划完成时间,
       主体结构封顶预计完成时间,
       主体结构封顶实际完成时间,
       主体结构封顶工作项状态,
       主体结构封顶延期天数,
       主体结构封顶责任部门,
       抹灰工程完成计划完成时间,
       抹灰工程完成实际完成时间,
       抹灰工程完成工作项状态,
       抹灰工程完成延期天数,
       抹灰工程完成责任部门,
       全部移交精装完成计划完成时间,
       全部移交精装完成实际完成时间,
       全部移交精装完成工作项状态,
       全部移交精装完成延期天数,
       全部移交精装完成责任部门,
       外墙装饰工程完成计划完成时间,
       外墙装饰工程完成实际完成时间,
       外墙装饰工程完成工作项状态,
       外墙装饰工程完成延期天数,
       外墙装饰工程完成责任部门,
       内部装修工程完成计划完成时间,
       内部装修工程完成实际完成时间,
       内部装修工程完成工作项状态,
       内部装修工程完成延期天数,
       内部装修工程完成责任部门,
       分户验收完成计划完成时间,
       分户验收完成实际完成时间,
       分户验收完成工作项状态,
       分户验收完成延期天数,
       分户验收完成责任部门,
       园林及配套工程完成计划完成时间,
       园林及配套工程完成实际完成时间,
       园林及配套工程完成工作项状态,
       园林及配套工程完成延期天数,
       园林及配套工程完成责任部门,
       竣工备案计划完成时间,
       竣工备案预计完成时间,
       竣工备案实际完成时间,
       竣工备案工作项状态,
       竣工备案延期天数,
       竣工备案责任部门,
       集中交付计划完成时间,
       集中交付预计完成时间,
       集中交付实际完成时间,
       集中交付工作项状态,
       集中交付延期天数,
       集中交付责任部门,
       计划总报建时间,
       实际总报建时间,
       计划总建设时间,
       实际总建设时间,
       计划总开发时间,
       实际总开发时间,
       实际开工计划完成时间,
       实际开工预计完成时间,
       实际开工实际完成时间,
       实际开工工作项状态,
       实际开工延期天数,
       实际开工责任部门,
       交付准备计划完成时间,
       交付准备实际完成时间,
       交付准备工作项状态,
       交付准备延期天数,
       交付准备责任部门,
       地上面积,
       地下面积,
       是否停工,
       projguid,
       TopProjguid,
       ztguid,
       一级城市公司,
       二级城市公司
FROM #tr;





DROP TABLE #t,
           #tr;