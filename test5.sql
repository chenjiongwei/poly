select * from  jd_PlanTaskExecuteObjectForReport where  TopProjguid ='4F9D9863-B804-ED11-B39C-F40270D39969'

SELECT  BldKeyGUID AS BuildingGUID ,
        xmhqPlanDate = MAX(a.xmhqPlanDate) ,                                        --项目获取计划
        xmhqFactDate = MAX(a.xmhqFactDate) ,                                        --项目获取实际
        ExpectedxmhqDate = MAX(a.ExpectedxmhqDate) ,                                --项目获取预计
        SgzPlanDate = MAX(a.SgzPlanDate) ,
        SgzFactDate = MAX(a.SgzFactDate) ,
        ExpectedSgzDate = MAX(a.ExpectedSgzDate) ,
        PlanBeginDate = MAX(a.PlanBeginDate) ,
        FactBeginDate = MAX(a.FactBeginDate) ,
        ExpectedBeginDate = MAX(a.ExpectedBeginDate) ,
        NULL AS ExpectedNoPassport ,
        PlanNoPassport = MAX(a.PlanNoPassport) ,
        FactNoPassport = MAX(a.FactNoPassport) ,
        ExpectedNotOpen = MAX(a.ExpectedNotOpen) ,
        PlanNotOpen = MAX(a.PlanNotOpen) ,
        FactNotOpen = MAX(a.FactNotOpen) ,
        NULL AS ExpectedOpenDate ,
        NULL AS PlanOpenDate ,                                                      -- [开盘销售_Finish] 
        NULL AS FactOpenDate ,                                                      --[开盘销售_ActualFinish]
        PlanFinishDate = MAX(a.PlanFinishDate) ,
        FactFinishDate = MAX(a.FactFinishDate) ,
        ExpectedFinishDate = MAX(a.ExpectedFinishDate) ,
        JzjfDatePlan = MAX(a.JzjfDatePlan) ,
        JzjfDateActual = MAX(a.JzjfDateActual) ,
        ExpectedJzjfDate = MAX(ExpectedJzjfDate) ,
        CashFlowDatePlan = MAX(a.CashFlowDatePlan) ,
        CashFlowDateExpected = MAX(a.CashFlowDateExpected) ,                        --现金流回正日期-预计
        CashFlowDateActual = MAX(a.CashFlowDateActual) ,
        RecoveryInvestmentDatePlan = MAX(a.RecoveryInvestmentDatePlan) ,
        RecoveryInvestmentDateExpected = MAX(a.RecoveryInvestmentDateExpected) ,    --收回股东投资日期-预计
        RecoveryInvestmentDateActual = MAX(a.RecoveryInvestmentDateActual) ,
        dwbgPlanDate = MAX(a.dwbgPlanDate) ,                                        --定位报告计划
        dwbgFactDate = MAX(a.dwbgFactDate) ,                                        --定位报告实际
        dwbgExpectedDate = MAX(a.dwbgExpectedDate) ,                                --定位报告预计
        xxgsjPlanDate = MAX(a.xxgsjPlanDate) ,                                      --修详规设计完成计划
        xxgsjFactDate = MAX(a.xxgsjFactDate) ,                                      --修详规设计完成实际
        xxgsjExpectedDate = MAX(a.xxgsjExpectedDate) ,                              --修详规设计完成预计
        xxgyjpfPlanDate = MAX(a.xxgyjpfPlanDate) ,                                  --修详规意见批复计划
        xxgyjpfFactDate = MAX(a.xxgyjpfFactDate) ,                                  --修详规意见批复实际
        xxgyjpfExpectedDate = MAX(a.xxgyjpfExpectedDate) ,                          --修详规意见批复预计
        slbkfPlanDate = MAX(a.slbkfPlanDate) ,                                      --售楼部、展示区正式开放计划
        slbkfFactDate = MAX(a.slbkfFactDate) ,                                      --售楼部、展示区正式开放实际
        slbkfExpectedDate = MAX(a.slbkfExpectedDate) ,                              --售楼部、展示区正式开放预计
        sgtscbaPlanDate = MAX(sgtscbaPlanDate) ,                                    --施工图审查备案完成计划
        sgtscbaFactDate = MAX(sgtscbaFactDate) ,                                    --施工图审查备案完成实际
        sgtscbaExpectedDate = MAX(sgtscbaExpectedDate) ,                            --施工图审查备案完成预计
        hqjgzPlanDate = MAX(hqjgzPlanDate) ,                                        --获取建规证计划
        hqjgzFactDate = MAX(hqjgzFactDate) ,                                        --获取建规证实际
        hqjgzExpectedDate = MAX(hqjgzExpectedDate) ,                                --获取建规证预计
        jkkwPlanDate = MAX(jkkwPlanDate) ,                                          --基坑开挖完成计划
        jkkwFactDate = MAX(jkkwFactDate) ,                                          --基坑开挖完成实际
        jkkwExpectedDate = MAX(jkkwExpectedDate) ,                                  --基坑开挖完成预计
        jcsgPlanDate = MAX(jcsgPlanDate) ,                                          --基础施工完成计划
        jcsgFactDate = MAX(jcsgFactDate) ,                                          --基础施工完成实际
        jcsgExpectedDate = MAX(jcsgExpectedDate) ,                                  --基础施工完成预计
        dxjgPlanDate = MAX(dxjgPlanDate) ,                                          --地下结构完成计划
        dxjgFactDate = MAX(dxjgFactDate) ,                                          --地下结构完成实际
        dxjgExpectedDate = MAX(dxjgExpectedDate) ,                                  --地下结构完成预计
        mhgcPlanDate = MAX(mhgcPlanDate) ,                                          --抹灰工程完成计划
        mhgcFactDate = MAX(mhgcFactDate) ,                                          --抹灰工程完成实际
        mhgcExpectedDate = MAX(mhgcExpectedDate) ,                                  --抹灰工程完成预计
        wqzsgcPlanDate = MAX(wqzsgcPlanDate) ,                                      --外墙装饰工程完成计划
        wqzsgcFactDate = MAX(wqzsgcFactDate) ,                                      --外墙装饰工程完成实际
        wqzsgcExpectedDate = MAX(wqzsgcExpectedDate) ,                              --外墙装饰工程完成预计
        nbzxgcPlanDate = MAX(nbzxgcPlanDate) ,                                      --内部装修工程完成计划
        nbzxgcFactDate = MAX(nbzxgcFactDate) ,                                      --内部装修工程完成实际
        nbzxgcExpectedDate = MAX(nbzxgcExpectedDate) ,                              --内部装修工程完成预计
        fhysPlanDate = MAX(fhysPlanDate) ,                                          --分户验收完成计划
        fhysFactDate = MAX(fhysFactDate) ,                                          --分户验收完成实际
        fhysExpectedDate = MAX(fhysExpectedDate) ,                                  --分户验收完成预计
        ylptgcPlanDate = MAX(ylptgcPlanDate) ,                                      --园林及配套工程完成计划
        ylptgcFactDate = MAX(ylptgcFactDate) ,                                      --园林及配套工程完成实际
        ylptgcExpectedDate = MAX(ylptgcExpectedDate) ,                              --园林及配套工程完成预计
        ztjgfdPlanDate = MAX(ztjgfdPlanDate) ,                                      --主体结构封顶计划
        ztjgfdFactDate = MAX(ztjgfdFactDate) ,                                      --主体结构封顶实际
        ztjgfdExpectedDate = MAX(ztjgfdExpectedDate) ,                              --主体结构封顶预计
        a.isFirstBld
FROM(SELECT CASE WHEN kn.KeyNodeName = '项目获取' THEN d.Finish END AS xmhqPlanDate ,
            CASE WHEN KeyNodeName = '项目获取' THEN d.ActualFinish END AS xmhqFactDate ,
            CASE WHEN KeyNodeName = '项目获取' THEN d.ExpectedFinishDate END AS ExpectedxmhqDate ,
            CASE WHEN KeyNodeName = '正式开工' THEN d.Finish END AS SgzPlanDate ,
            CASE WHEN KeyNodeName = '正式开工' THEN d.ActualFinish END AS SgzFactDate ,
            CASE WHEN KeyNodeName = '正式开工' THEN d.ExpectedFinishDate END AS ExpectedSgzDate ,
            CASE WHEN KeyNodeName = '实际开工' THEN d.Finish END AS PlanBeginDate ,
            CASE WHEN KeyNodeName = '实际开工' THEN d.ActualFinish END AS FactBeginDate ,
            CASE WHEN KeyNodeName = '实际开工' THEN d.ExpectedFinishDate END AS ExpectedBeginDate ,
            CASE WHEN KeyNodeName = '达到预售形象' THEN d.Finish END AS PlanNoPassport ,
            CASE WHEN KeyNodeName = '达到预售形象' THEN d.ActualFinish END AS FactNoPassport ,
            CASE WHEN KeyNodeName = '预售办理' THEN d.ExpectedFinishDate END AS ExpectedNotOpen ,
            CASE WHEN KeyNodeName = '预售办理' THEN d.Finish END AS PlanNotOpen ,
            CASE WHEN KeyNodeName = '预售办理' THEN d.ActualFinish END AS FactNotOpen ,
            CASE WHEN KeyNodeName = '竣工备案' THEN d.Finish END AS PlanFinishDate ,
            CASE WHEN KeyNodeName = '竣工备案' THEN d.ActualFinish END AS FactFinishDate ,
            CASE WHEN KeyNodeName = '竣工备案' THEN d.ExpectedFinishDate END AS ExpectedFinishDate ,
            CASE WHEN KeyNodeName = '集中交付' THEN d.Finish END AS JzjfDatePlan ,
            CASE WHEN KeyNodeName = '集中交付' THEN d.ActualFinish END AS JzjfDateActual ,
            CASE WHEN KeyNodeName = '集中交付' THEN d.ExpectedFinishDate END AS ExpectedJzjfDate ,
            CASE WHEN KeyNodeName = '现金流回正' THEN d.Finish END AS CashFlowDatePlan ,
            CASE WHEN KeyNodeName = '现金流回正' THEN d.ExpectedFinishDate END AS CashFlowDateExpected ,
            CASE WHEN KeyNodeName = '现金流回正' THEN d.ActualFinish END AS CashFlowDateActual ,
            CASE WHEN KeyNodeName = '收回股东投资' THEN d.Finish END AS RecoveryInvestmentDatePlan ,
            CASE WHEN KeyNodeName = '收回股东投资' THEN d.ExpectedFinishDate END AS RecoveryInvestmentDateExpected ,
            CASE WHEN KeyNodeName = '收回股东投资' THEN d.ActualFinish END AS RecoveryInvestmentDateActual ,
            CASE WHEN KeyNodeName = '定位报告' THEN d.Finish END AS dwbgPlanDate ,                          --定位报告计划
            CASE WHEN KeyNodeName = '定位报告' THEN d.ActualFinish END AS dwbgFactDate ,                    --定位报告实际
            CASE WHEN KeyNodeName = '定位报告' THEN d.ExpectedFinishDate END AS dwbgExpectedDate ,          --定位报告预计
            CASE WHEN KeyNodeName = '修详规设计完成' THEN d.Finish END AS xxgsjPlanDate ,                      --修详规设计完成计划
            CASE WHEN KeyNodeName = '修详规设计完成' THEN d.ActualFinish END AS xxgsjFactDate ,                --修详规设计完成实际
            CASE WHEN KeyNodeName = '修详规设计完成' THEN d.ExpectedFinishDate END AS xxgsjExpectedDate ,      --修详规设计完成预计
            CASE WHEN KeyNodeName = '修详规意见批复' THEN d.Finish END AS xxgyjpfPlanDate ,                    --修详规意见批复计划
            CASE WHEN KeyNodeName = '修详规意见批复' THEN d.ActualFinish END AS xxgyjpfFactDate ,              --修详规意见批复实际
            CASE WHEN KeyNodeName = '修详规意见批复' THEN d.ExpectedFinishDate END AS xxgyjpfExpectedDate ,    --修详规意见批复预计
            CASE WHEN KeyNodeName = '售楼部、展示区正式开放' THEN d.Finish END AS slbkfPlanDate ,                  --售楼部、展示区正式开放计划
            CASE WHEN KeyNodeName = '售楼部、展示区正式开放' THEN d.ActualFinish END AS slbkfFactDate ,            --售楼部、展示区正式开放实际
            CASE WHEN KeyNodeName = '售楼部、展示区正式开放' THEN d.ExpectedFinishDate END AS slbkfExpectedDate ,  --售楼部、展示区正式开放预计
            CASE WHEN KeyNodeName = '施工图审查备案完成' THEN d.Finish END AS sgtscbaPlanDate ,                  --施工图审查备案完成计划
            CASE WHEN KeyNodeName = '施工图审查备案完成' THEN d.ActualFinish END AS sgtscbaFactDate ,            --施工图审查备案完成实际
            CASE WHEN KeyNodeName = '施工图审查备案完成' THEN d.ExpectedFinishDate END AS sgtscbaExpectedDate ,  --施工图审查备案完成预计
            CASE WHEN KeyNodeName = '获取建规证' THEN d.Finish END AS hqjgzPlanDate ,                        --获取建规证计划
            CASE WHEN KeyNodeName = '获取建规证' THEN d.ActualFinish END AS hqjgzFactDate ,                  --获取建规证实际
            CASE WHEN KeyNodeName = '获取建规证' THEN d.ExpectedFinishDate END AS hqjgzExpectedDate ,        --获取建规证预计
            CASE WHEN KeyNodeName = '基坑开挖完成' THEN d.Finish END AS jkkwPlanDate ,                        --基坑开挖完成计划
            CASE WHEN KeyNodeName = '基坑开挖完成' THEN d.ActualFinish END AS jkkwFactDate ,                  --基坑开挖完成实际
            CASE WHEN KeyNodeName = '基坑开挖完成' THEN d.ExpectedFinishDate END AS jkkwExpectedDate ,        --基坑开挖完成预计
            CASE WHEN KeyNodeName = '基础施工完成' THEN d.Finish END AS jcsgPlanDate ,                        --基础施工完成计划
            CASE WHEN KeyNodeName = '基础施工完成' THEN d.ActualFinish END AS jcsgFactDate ,                  --基础施工完成实际
            CASE WHEN KeyNodeName = '基础施工完成' THEN d.ExpectedFinishDate END AS jcsgExpectedDate ,        --基础施工完成预计
            CASE WHEN KeyNodeName = '地下结构完成' THEN d.Finish END AS dxjgPlanDate ,                        --地下结构完成计划
            CASE WHEN KeyNodeName = '地下结构完成' THEN d.ActualFinish END AS dxjgFactDate ,                  --地下结构完成实际
            CASE WHEN KeyNodeName = '地下结构完成' THEN d.ExpectedFinishDate END AS dxjgExpectedDate ,        --地下结构完成预计
            CASE WHEN KeyNodeName = '抹灰工程完成' THEN d.Finish END AS mhgcPlanDate ,                        --抹灰工程完成计划
            CASE WHEN KeyNodeName = '抹灰工程完成' THEN d.ActualFinish END AS mhgcFactDate ,                  --抹灰工程完成实际
            CASE WHEN KeyNodeName = '抹灰工程完成' THEN d.ExpectedFinishDate END AS mhgcExpectedDate ,        --抹灰工程完成预计
            CASE WHEN KeyNodeName = '外墙装饰工程完成' THEN d.Finish END AS wqzsgcPlanDate ,                    --外墙装饰工程完成计划
            CASE WHEN KeyNodeName = '外墙装饰工程完成' THEN d.ActualFinish END AS wqzsgcFactDate ,              --外墙装饰工程完成实际
            CASE WHEN KeyNodeName = '外墙装饰工程完成' THEN d.ExpectedFinishDate END AS wqzsgcExpectedDate ,    --外墙装饰工程完成预计
            CASE WHEN KeyNodeName = '内部装修工程完成' THEN d.Finish END AS nbzxgcPlanDate ,                    --内部装修工程完成计划
            CASE WHEN KeyNodeName = '内部装修工程完成' THEN d.ActualFinish END AS nbzxgcFactDate ,              --内部装修工程完成实际
            CASE WHEN KeyNodeName = '内部装修工程完成' THEN d.ExpectedFinishDate END AS nbzxgcExpectedDate ,    --内部装修工程完成预计
            CASE WHEN KeyNodeName = '分户验收完成' THEN d.Finish END AS fhysPlanDate ,                        --分户验收完成计划
            CASE WHEN KeyNodeName = '分户验收完成' THEN d.ActualFinish END AS fhysFactDate ,                  --分户验收完成实际
            CASE WHEN KeyNodeName = '分户验收完成' THEN d.ExpectedFinishDate END AS fhysExpectedDate ,        --分户验收完成预计
            CASE WHEN KeyNodeName = '园林及配套工程完成' THEN d.Finish END AS ylptgcPlanDate ,                   --园林及配套工程完成计划
            CASE WHEN KeyNodeName = '园林及配套工程完成' THEN d.ActualFinish END AS ylptgcFactDate ,             --园林及配套工程完成实际
            CASE WHEN KeyNodeName = '园林及配套工程完成' THEN d.ExpectedFinishDate END AS ylptgcExpectedDate ,   --园林及配套工程完成预计
            CASE WHEN KeyNodeName = '主体结构封顶' THEN d.Finish END AS ztjgfdPlanDate ,                      --主体结构封顶计划
            CASE WHEN KeyNodeName = '主体结构封顶' THEN d.ActualFinish END AS ztjgfdFactDate ,                --主体结构封顶实际
            CASE WHEN KeyNodeName = '主体结构封顶' THEN d.ExpectedFinishDate END AS ztjgfdExpectedDate ,      --主体结构封顶预计
            p.IsFirstStart AS isFirstBld ,
            gc.BldKeyGUID
     FROM   jd_projectPlanExecute a
            INNER JOIN jd_projectPlanTaskExecute d ON a.id = d.planid
            INNER JOIN jd_keynode kn ON d.keynodeid = kn.keynodeGUID
            INNER JOIN p_BiddingBuilding p ON a.objectid = p.BuildGUID ---楼栋表
            INNER JOIN p_HkbBiddingBuilding2BuildingWork hkb ON p.BuildGUID = hkb.budguid
            INNER JOIN md_GCBuild gc ON hkb.buildingGUID = gc.bldGUID AND   gc.IsActive = 1 --注意版本
) a
GROUP BY BldKeyGUID ,
         a.isFirstBld
UNION ALL
SELECT  ProductBuildKeyGUID AS BuildingGUID ,
        xmhqPlanDate = MAX(xmhqPlanDate) ,                  --项目获取计划
        xmhqFactDate = MAX(xmhqFactDate) ,                  --项目获取实际
        ExpectedxmhqDate = MAX(ExpectedxmhqDate) ,          --项目获取预计
        NULL AS SgzPlanDate ,
        NULL AS SgzFactDate ,
        NULL ExpectedSgzDate ,
        NULL AS PlanBeginDate ,
        NULL AS FactBeginDate ,
        NULL AS ExpectedBeginDate ,
        ExpectedNoPassport = MAX(a.ExpectedNoPassport) ,
        PlanNoPassport = MAX(a.PlanNoPassport) ,
        FactNoPassport = MAX(a.FactNoPassport) ,
        ExpectedNotOpen = MAX(a.ExpectedNotOpen) ,
        PlanNotOpen = MAX(a.PlanNotOpen) ,
        FactNotOpen = MAX(a.FactNotOpen) ,
        ExpectedOpenDate = MAX(a.ExpectedOpenDate) ,
        PlanOpenDate = MAX(a.PlanOpenDate) ,
        FactOpenDate = MAX(a.FactOpenDate) ,
        NULL AS PlanFinishDate ,
        NULL AS FactFinishDate ,
        NULL AS ExpectedFinishDate ,
        NULL AS JzjfDatePlan ,
        NULL AS JzjfDateActual ,
        NULL AS ExpectedJzjfDate ,
        CashFlowDatePlan = MAX(a.CashFlowDatePlan) ,
        CashFlowDateExpected = MAX(a.CashFlowDateExpected) ,
        CashFlowDateActual = MAX(a.CashFlowDateActual) ,
        RecoveryInvestmentDatePlan = MAX(a.RecoveryInvestmentDatePlan) ,
        RecoveryInvestmentDateExpected = MAX(a.RecoveryInvestmentDateExpected) ,
        RecoveryInvestmentDateActual = MAX(a.RecoveryInvestmentDateActual) ,
        dwbgPlanDate = MAX(dwbgPlanDate) ,                  --定位报告计划
        dwbgFactDate = MAX(dwbgFactDate) ,                  --定位报告实际
        dwbgExpectedDate = MAX(dwbgExpectedDate) ,          --定位报告预计
        xxgsjPlanDate = MAX(xxgsjPlanDate) ,                --修详规设计完成计划
        xxgsjFactDate = MAX(xxgsjFactDate) ,                --修详规设计完成实际
        xxgsjExpectedDate = MAX(xxgsjExpectedDate) ,        --修详规设计完成预计
        xxgyjpfPlanDate = MAX(xxgyjpfPlanDate) ,            --修详规意见批复计划
        xxgyjpfFactDate = MAX(xxgyjpfFactDate) ,            --修详规意见批复实际
        xxgyjpfExpectedDate = MAX(xxgyjpfExpectedDate) ,    --修详规意见批复预计
        slbkfPlanDate = MAX(slbkfPlanDate) ,                --售楼部、展示区正式开放计划
        slbkfFactDate = MAX(slbkfFactDate) ,                --售楼部、展示区正式开放实际
        slbkfExpectedDate = MAX(slbkfExpectedDate) ,        --售楼部、展示区正式开放预计
        sgtscbaPlanDate = MAX(sgtscbaPlanDate) ,            --施工图审查备案完成计划
        sgtscbaFactDate = MAX(sgtscbaFactDate) ,            --施工图审查备案完成实际
        sgtscbaExpectedDate = MAX(sgtscbaExpectedDate) ,    --施工图审查备案完成预计
        hqjgzPlanDate = MAX(hqjgzPlanDate) ,                --获取建规证计划
        hqjgzFactDate = MAX(hqjgzFactDate) ,                --获取建规证实际
        hqjgzExpectedDate = MAX(hqjgzExpectedDate) ,        --获取建规证预计
        jkkwPlanDate = MAX(jkkwPlanDate) ,                  --基坑开挖完成计划
        jkkwFactDate = MAX(jkkwFactDate) ,                  --基坑开挖完成实际
        jkkwExpectedDate = MAX(jkkwExpectedDate) ,          --基坑开挖完成预计
        jcsgPlanDate = MAX(jcsgPlanDate) ,                  --基础施工完成计划
        jcsgFactDate = MAX(jcsgFactDate) ,                  --基础施工完成实际
        jcsgExpectedDate = MAX(jcsgExpectedDate) ,          --基础施工完成预计
        dxjgPlanDate = MAX(dxjgPlanDate) ,                  --地下结构完成计划
        dxjgFactDate = MAX(dxjgFactDate) ,                  --地下结构完成实际
        dxjgExpectedDate = MAX(dxjgExpectedDate) ,          --地下结构完成预计
        mhgcPlanDate = MAX(mhgcPlanDate) ,                  --抹灰工程完成计划
        mhgcFactDate = MAX(mhgcFactDate) ,                  --抹灰工程完成实际
        mhgcExpectedDate = MAX(mhgcExpectedDate) ,          --抹灰工程完成预计
        wqzsgcPlanDate = MAX(wqzsgcPlanDate) ,              --外墙装饰工程完成计划
        wqzsgcFactDate = MAX(wqzsgcFactDate) ,              --外墙装饰工程完成实际
        wqzsgcExpectedDate = MAX(wqzsgcExpectedDate) ,      --外墙装饰工程完成预计
        nbzxgcPlanDate = MAX(nbzxgcPlanDate) ,              --内部装修工程完成计划
        nbzxgcFactDate = MAX(nbzxgcFactDate) ,              --内部装修工程完成实际
        nbzxgcExpectedDate = MAX(nbzxgcExpectedDate) ,      --内部装修工程完成预计
        fhysPlanDate = MAX(fhysPlanDate) ,                  --分户验收完成计划
        fhysFactDate = MAX(fhysFactDate) ,                  --分户验收完成实际
        fhysExpectedDate = MAX(fhysExpectedDate) ,          --分户验收完成预计
        ylptgcPlanDate = MAX(ylptgcPlanDate) ,              --园林及配套工程完成计划
        ylptgcFactDate = MAX(ylptgcFactDate) ,              --园林及配套工程完成实际
        ylptgcExpectedDate = MAX(ylptgcExpectedDate) ,      --园林及配套工程完成预计
        ztjgfdPlanDate = MAX(ztjgfdPlanDate) ,              --主体结构封顶计划
        ztjgfdFactDate = MAX(ztjgfdFactDate) ,              --主体结构封顶实际
        ztjgfdExpectedDate = MAX(ztjgfdExpectedDate) ,      --主体结构封顶预计
        isFirstBld = MAX(ISNULL(isFirstBld, 0))
FROM(SELECT CASE WHEN KeyNodeName = '项目获取' THEN d.Finish END AS xmhqPlanDate ,
            CASE WHEN KeyNodeName = '项目获取' THEN d.ActualFinish END AS xmhqFactDate ,
            CASE WHEN KeyNodeName = '项目获取' THEN d.ExpectedFinishDate END AS ExpectedxmhqDate ,
            NULL AS ExpectedNoPassport ,
            NULL AS PlanNoPassport ,
            NULL AS FactNoPassport ,
            NULL AS ExpectedNotOpen ,
            NULL AS PlanNotOpen ,
            NULL AS FactNotOpen ,
            CASE WHEN KeyNodeName = '开盘销售' THEN d.ExpectedFinishDate END AS ExpectedOpenDate ,
            CASE WHEN KeyNodeName = '开盘销售' THEN d.Finish END AS PlanOpenDate ,
            CASE WHEN KeyNodeName = '开盘销售' THEN d.ActualFinish END AS FactOpenDate ,
            ProductBuild.ProductBuildKeyGUID ,
            CASE WHEN KeyNodeName = '现金流回正' THEN d.Finish END AS CashFlowDatePlan ,
            CASE WHEN KeyNodeName = '现金流回正' THEN d.ExpectedFinishDate END AS CashFlowDateExpected ,
            CASE WHEN KeyNodeName = '现金流回正' THEN d.ActualFinish END AS CashFlowDateActual ,
            CASE WHEN KeyNodeName = '收回股东投资' THEN d.Finish END AS RecoveryInvestmentDatePlan ,
            CASE WHEN KeyNodeName = '收回股东投资' THEN d.ExpectedFinishDate END AS RecoveryInvestmentDateExpected ,
            CASE WHEN KeyNodeName = '收回股东投资' THEN d.ActualFinish END AS RecoveryInvestmentDateActual ,
            CASE WHEN KeyNodeName = '定位报告' THEN d.Finish END AS dwbgPlanDate ,                          --定位报告计划
            CASE WHEN KeyNodeName = '定位报告' THEN d.ActualFinish END AS dwbgFactDate ,                    --定位报告实际
            CASE WHEN KeyNodeName = '定位报告' THEN d.ExpectedFinishDate END AS dwbgExpectedDate ,          --定位报告预计
            CASE WHEN KeyNodeName = '修详规设计完成' THEN d.Finish END AS xxgsjPlanDate ,                      --修详规设计完成计划
            CASE WHEN KeyNodeName = '修详规设计完成' THEN d.ActualFinish END AS xxgsjFactDate ,                --修详规设计完成实际
            CASE WHEN KeyNodeName = '修详规设计完成' THEN d.ExpectedFinishDate END AS xxgsjExpectedDate ,      --修详规设计完成预计
            CASE WHEN KeyNodeName = '修详规意见批复' THEN d.Finish END AS xxgyjpfPlanDate ,                    --修详规意见批复计划
            CASE WHEN KeyNodeName = '修详规意见批复' THEN d.ActualFinish END AS xxgyjpfFactDate ,              --修详规意见批复实际
            CASE WHEN KeyNodeName = '修详规意见批复' THEN d.ExpectedFinishDate END AS xxgyjpfExpectedDate ,    --修详规意见批复预计
            CASE WHEN KeyNodeName = '售楼部、展示区正式开放' THEN d.Finish END AS slbkfPlanDate ,                  --售楼部、展示区正式开放计划
            CASE WHEN KeyNodeName = '售楼部、展示区正式开放' THEN d.ActualFinish END AS slbkfFactDate ,            --售楼部、展示区正式开放实际
            CASE WHEN KeyNodeName = '售楼部、展示区正式开放' THEN d.ExpectedFinishDate END AS slbkfExpectedDate ,  --售楼部、展示区正式开放预计
            CASE WHEN KeyNodeName = '施工图审查备案完成' THEN d.Finish END AS sgtscbaPlanDate ,                  --施工图审查备案完成计划
            CASE WHEN KeyNodeName = '施工图审查备案完成' THEN d.ActualFinish END AS sgtscbaFactDate ,            --施工图审查备案完成实际
            CASE WHEN KeyNodeName = '施工图审查备案完成' THEN d.ExpectedFinishDate END AS sgtscbaExpectedDate ,  --施工图审查备案完成预计
            CASE WHEN KeyNodeName = '获取建规证' THEN d.Finish END AS hqjgzPlanDate ,                        --获取建规证计划
            CASE WHEN KeyNodeName = '获取建规证' THEN d.ActualFinish END AS hqjgzFactDate ,                  --获取建规证实际
            CASE WHEN KeyNodeName = '获取建规证' THEN d.ExpectedFinishDate END AS hqjgzExpectedDate ,        --获取建规证预计
            CASE WHEN KeyNodeName = '基坑开挖完成' THEN d.Finish END AS jkkwPlanDate ,                        --基坑开挖完成计划
            CASE WHEN KeyNodeName = '基坑开挖完成' THEN d.ActualFinish END AS jkkwFactDate ,                  --基坑开挖完成实际
            CASE WHEN KeyNodeName = '基坑开挖完成' THEN d.ExpectedFinishDate END AS jkkwExpectedDate ,        --基坑开挖完成预计
            CASE WHEN KeyNodeName = '基础施工完成' THEN d.Finish END AS jcsgPlanDate ,                        --基础施工完成计划
            CASE WHEN KeyNodeName = '基础施工完成' THEN d.ActualFinish END AS jcsgFactDate ,                  --基础施工完成实际
            CASE WHEN KeyNodeName = '基础施工完成' THEN d.ExpectedFinishDate END AS jcsgExpectedDate ,        --基础施工完成预计
            CASE WHEN KeyNodeName = '地下结构完成' THEN d.Finish END AS dxjgPlanDate ,                        --地下结构完成计划
            CASE WHEN KeyNodeName = '地下结构完成' THEN d.ActualFinish END AS dxjgFactDate ,                  --地下结构完成实际
            CASE WHEN KeyNodeName = '地下结构完成' THEN d.ExpectedFinishDate END AS dxjgExpectedDate ,        --地下结构完成预计
            CASE WHEN KeyNodeName = '抹灰工程完成' THEN d.Finish END AS mhgcPlanDate ,                        --抹灰工程完成计划
            CASE WHEN KeyNodeName = '抹灰工程完成' THEN d.ActualFinish END AS mhgcFactDate ,                  --抹灰工程完成实际
            CASE WHEN KeyNodeName = '抹灰工程完成' THEN d.ExpectedFinishDate END AS mhgcExpectedDate ,        --抹灰工程完成预计
            CASE WHEN KeyNodeName = '外墙装饰工程完成' THEN d.Finish END AS wqzsgcPlanDate ,                    --外墙装饰工程完成计划
            CASE WHEN KeyNodeName = '外墙装饰工程完成' THEN d.ActualFinish END AS wqzsgcFactDate ,              --外墙装饰工程完成实际
            CASE WHEN KeyNodeName = '外墙装饰工程完成' THEN d.ExpectedFinishDate END AS wqzsgcExpectedDate ,    --外墙装饰工程完成预计
            CASE WHEN KeyNodeName = '内部装修工程完成' THEN d.Finish END AS nbzxgcPlanDate ,                    --内部装修工程完成计划
            CASE WHEN KeyNodeName = '内部装修工程完成' THEN d.ActualFinish END AS nbzxgcFactDate ,              --内部装修工程完成实际
            CASE WHEN KeyNodeName = '内部装修工程完成' THEN d.ExpectedFinishDate END AS nbzxgcExpectedDate ,    --内部装修工程完成预计
            CASE WHEN KeyNodeName = '分户验收完成' THEN d.Finish END AS fhysPlanDate ,                        --分户验收完成计划
            CASE WHEN KeyNodeName = '分户验收完成' THEN d.ActualFinish END AS fhysFactDate ,                  --分户验收完成实际
            CASE WHEN KeyNodeName = '分户验收完成' THEN d.ExpectedFinishDate END AS fhysExpectedDate ,        --分户验收完成预计
            CASE WHEN KeyNodeName = '园林及配套工程完成' THEN d.Finish END AS ylptgcPlanDate ,                   --园林及配套工程完成计划
            CASE WHEN KeyNodeName = '园林及配套工程完成' THEN d.ActualFinish END AS ylptgcFactDate ,             --园林及配套工程完成实际
            CASE WHEN KeyNodeName = '园林及配套工程完成' THEN d.ExpectedFinishDate END AS ylptgcExpectedDate ,   --园林及配套工程完成预计
            CASE WHEN KeyNodeName = '主体结构封顶' THEN d.Finish END AS ztjgfdPlanDate ,                      --主体结构封顶计划
            CASE WHEN KeyNodeName = '主体结构封顶' THEN d.ActualFinish END AS ztjgfdFactDate ,                --主体结构封顶实际
            CASE WHEN KeyNodeName = '主体结构封顶' THEN d.ExpectedFinishDate END AS ztjgfdExpectedDate ,      --主体结构封顶预计
            p.IsFirstStart AS isFirstBld
     FROM   jd_projectPlanExecute a
            INNER JOIN jd_projectPlanTaskExecute d ON a.id = d.planid
            INNER JOIN jd_keynode kn ON d.keynodeid = kn.keynodeGUID
            INNER JOIN p_BiddingBuilding p ON a.objectid = p.BuildGUID ---楼栋表
            INNER JOIN p_HkbBiddingBuilding2BuildingWork hkb ON p.BuildGUID = hkb.budguid
            INNER JOIN md_ProductBuild ProductBuild ON hkb.buildingGUID = ProductBuild.BldGUID
            INNER JOIN(SELECT   *
                       FROM (SELECT ROW_NUMBER() OVER (PARTITION BY projguid ORDER BY CreateDate DESC) AS rowno ,
                                    *
                             FROM   md_Project
                             WHERE  isactive = 1) t
                       WHERE t.rowno = 1) temp ON ProductBuild.ProjGUID = temp.ProjGUID
     UNION ALL
     SELECT NULL AS xmhqPlanDate ,
            NULL AS xmhqFactDate ,
            NULL AS ExpectedxmhqDate ,
            CASE WHEN KeyNodeName = '达到预售形象' THEN d.ExpectedFinishDate END AS ExpectedNoPassport ,
            CASE WHEN KeyNodeName = '达到预售形象' THEN d.Finish END AS PlanNoPassport ,
            CASE WHEN KeyNodeName = '达到预售形象' THEN d.ActualFinish END AS FactNoPassport ,
            CASE WHEN KeyNodeName = '预售办理' THEN d.ExpectedFinishDate END AS ExpectedNotOpen ,
            CASE WHEN KeyNodeName = '预售办理' THEN d.Finish END AS PlanNotOpen ,
            CASE WHEN KeyNodeName = '预售办理' THEN d.ActualFinish END AS FactNotOpen ,
            NULL AS ExpectedOpenDate ,
            NULL AS PlanOpenDate ,
            NULL AS FactOpenDate ,
            ProductBuildKeyGUID ProductBuildKeyGUID ,
            NULL AS CashFlowDatePlan ,
            NULL AS CashFlowDateExpected ,
            NULL AS CashFlowDateActual ,
            NULL AS RecoveryInvestmentDatePlan ,
            NULL AS RecoveryInvestmentDateExpected ,
            NULL AS RecoveryInvestmentDateActual ,
            NULL AS dwbgPlanDate ,          --定位报告计划
            NULL AS dwbgFactDate ,          --定位报告实际
            NULL AS dwbgExpectedDate ,      --定位报告预计 
            NULL AS xxgsjPlanDate ,         --修详规设计完成计划
            NULL AS xxgsjFactDate ,         --修详规设计完成实际
            NULL AS xxgsjExpectedDate ,     --修详规设计完成预计 
            NULL AS xxgyjpfPlanDate ,       --修详规意见批复计划
            NULL AS xxgyjpfFactDate ,       --修详规意见批复实际
            NULL AS xxgyjpfExpectedDate ,   --修详规意见批复预计 
            NULL AS slbkfPlanDate ,         --售楼部、展示区正式开放计划
            NULL AS slbkfFactDate ,         --售楼部、展示区正式开放实际
            NULL AS slbkfExpectedDate ,     --售楼部、展示区正式开放预计 
            NULL AS sgtscbaPlanDate ,       --施工图审查备案完成计划
            NULL AS sgtscbaFactDate ,       --施工图审查备案完成实际
            NULL AS sgtscbaExpectedDate ,   --施工图审查备案完成预计 
            NULL AS hqjgzPlanDate ,         --获取建规证计划
            NULL AS hqjgzFactDate ,         --获取建规证实际
            NULL AS hqjgzExpectedDate ,     --获取建规证预计 
            NULL AS jkkwPlanDate ,          --基坑开挖完成计划
            NULL AS jkkwFactDate ,          --基坑开挖完成实际
            NULL AS jkkwExpectedDate ,      --基坑开挖完成预计
            NULL AS jcsgPlanDate ,          --基础施工完成计划
            NULL AS jcsgFactDate ,          --基础施工完成实际
            NULL AS jcsgExpectedDate ,      --基础施工完成预计
            NULL AS dxjgPlanDate ,          --地下结构完成计划
            NULL AS dxjgFactDate ,          --地下结构完成实际
            NULL AS dxjgExpectedDate ,      --地下结构完成预计
            NULL AS mhgcPlanDate ,          --抹灰工程完成计划
            NULL AS mhgcFactDate ,          --抹灰工程完成实际
            NULL AS mhgcExpectedDate ,      --抹灰工程完成预计
            NULL AS wqzsgcPlanDate ,        --外墙装饰工程完成计划
            NULL AS wqzsgcFactDate ,        --外墙装饰工程完成实际
            NULL AS wqzsgcExpectedDate ,    --外墙装饰工程完成预计
            NULL AS nbzxgcPlanDate ,        --内部装修工程完成计划
            NULL AS nbzxgcFactDate ,        --内部装修工程完成实际
            NULL AS nbzxgcExpectedDate ,    --内部装修工程完成预计
            NULL AS fhysPlanDate ,          --分户验收完成计划
            NULL AS fhysFactDate ,          --分户验收完成实际
            NULL AS fhysExpectedDate ,      --分户验收完成预计
            NULL AS ylptgcPlanDate ,        --园林及配套工程完成计划
            NULL AS ylptgcFactDate ,        --园林及配套工程完成实际
            NULL AS ylptgcExpectedDate ,    --园林及配套工程完成预计
            NULL AS ztjgfdPlanDate ,        --主体结构封顶计划
            NULL AS ztjgfdFactDate ,        --主体结构封顶实际
            NULL AS ztjgfdExpectedDate ,    --主体结构封顶预计
            NULL AS isFirstBld
     FROM   jd_projectPlanExecute a
            INNER JOIN jd_projectPlanTaskExecute d ON a.id = d.planid
            INNER JOIN jd_keynode kn ON d.keynodeid = kn.keynodeGUID
            INNER JOIN md_ProductBuild pb ON d.SaleBldGUID = pb.ProductBuildGUID) a
GROUP BY ProductBuildKeyGUID



 SELECT '' as rowid,
        1 as entity,
        a.ID,
        a.VersionName,
        a.VersionType,
        (CASE WHEN a.UpdateDate IS NULL THEN '' ELSE Convert(varchar(10), a.UpdateDate, 120) END) as UpdateDate,
        a.UpdateBy,
        a.ProjGUID,
        a.VersionID,
        b.ProcessGUID,
        case when c.ExaminID is not null then '是' else '否' end as IsExamin, 
        (CASE WHEN a.CreateDate IS NULL THEN '' ELSE Convert(varchar(10), a.CreateDate, 120) END) as CreateDate, 
        Content  
 FROM (  
    select id,
           versionname,
           '编制版' as versiontype,
           updatedate,
           updateby,
           projguid,
           approveflowid,
           null AS VersionID, 
           CreateDate = updatedate, 
           Content = '' 
    from jd_projectplancompile  
    union all   
    select id,
           versionname,
           '执行版' as versiontype,
           updatedate,
           updateby,
           projguid,
           approveflowid,
           id AS VersionID, 
           CreateDate = updatedate, 
           Content = '' 
    from jd_projectplanexecute  
    union all   
    select id,
           versionname,
           '历史版' as versiontype,
           updatedate,
           updateby,
           projguid,
           approveflowid,
           VersionID, 
           CreateDate, 
           Content 
    from jd_projectplanexecutehistory  
 ) a  
 Left Join myWorkflowProcessEntity b 
    ON a.ApproveFlowID = b.BusinessGUID 
    AND isnull(b.IsHistory,0) = 0 
    AND b.BusinessType='项目计划审批'  
 Left Join(    
    SELECT Top 1 ID as ExaminID, VersionID as ExaminVersionID 
    FROM( 
        SELECT ID,VersionID,UpdateDate,VersionName,ProjGUID 
        FROM jd_projectplanexecutehistory 
        WHERE IsExamin = 1 
        UNION ALL 
        SELECT ID,ID as VersionID,UpdateDate,VersionName,ProjGUID 
        FROM jd_ProjectPlanExecute 
        WHERE IsExamin = 1   
    )Examin 
    WHERE Examin.ProjGUID = '7eb7874d-7006-ed11-b39c-f40270d39969'  
    ORDER BY Examin.UpdateDate DESC,Examin.VersionName DESC
 )c on a.id = c.ExaminID and a.VersionID = c.ExaminVersionID  
 WHERE a.ID = 'ce22634f-151d-4ee9-99d0-70465026e3bb'  
 ORDER BY CASE a.VersionType 
             WHEN '编制版' THEN 1 
             WHEN '执行版' THEN 2 
             WHEN '历史版' THEN 3 
          END,
          a.CreateDate DESC