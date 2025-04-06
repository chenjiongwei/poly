--插入需要评估的项目分期
SELECT  
        bu.DevelopmentCompanyName,
        bu.DevelopmentCompanyGUID,
        mp.ProjGUID AS TopProjGUID ,
        mp.ProjCode AS TopTopProjGUID ,
        mp.ProjCode AS TopProjCode ,
        mp.ProjName AS TopProjName ,
        mp.SpreadName AS TopSpreadName ,
        mp.AcquisitionDate as AcquisitionDate,
        mp1.ProjGUID ,
        mp1.ProjCode ,
        mp1.ProjName ,
        mp1.SpreadName
INTO    #proj
FROM    erp25.dbo.mdm_Project mp with(nolock)
        LEFT JOIN erp25.dbo.mdm_Project mp1 with(nolock) ON mp.ProjGUID = mp1.ParentProjGUID
        inner join ERP25.dbo.p_DevelopmentCompany bu with(nolock) on bu.DevelopmentCompanyGUID = mp.DevelopmentCompanyGUID
where  bu.DevelopmentCompanyName in ('淮海公司','浙南公司','齐鲁公司','大连公司') and  mp.level =2
-- WHERE   mp.ProjGUID IN ( '4BA1C8D9-F10F-E911-80BF-E61F13C57837', '02CE6907-CD2D-4387-A810-0DA3FF0ACACA',
--                        'BBADA202-CB1A-4A20-8F22-FFF9EC399A50', 'A79AEFE3-8223-41AD-8B53-CBFD994ACBDA',
--                        'DD4D7608-A9F7-4CB4-8E26-23AE39EF1611', 'EBCE1211-CD0E-EB11-B398-F40270D39969',
--                        '1590B64A-1178-EB11-B398-F40270D39969', '0ADA93A5-F20F-E911-80BF-E61F13C57837',
--                        '81AEA2F0-3018-EB11-B398-F40270D39969', '7E7DA193-F20F-E911-80BF-E61F13C57837',
--                        'BD5F3657-6BB0-4786-A96D-008927784637', 'EF5A7E70-97D2-459F-9555-A65B6AC4E63F',
--                        '6DF9A29E-C38A-41AE-90E6-781C10EAB4DC', '7AA32C69-1315-EC11-B398-F40270D39969',
--                        'B5E63497-329B-484D-A95B-8D6CBBB13890', 'B803BD21-F20F-E911-80BF-E61F13C57837',
--                        'ADF3AF2D-F20F-E911-80BF-E61F13C57837', '79071E3A-B873-4DDE-96BF-D738470DE19D',
--                        'C1E6322F-CD0E-EB11-B398-F40270D39969', 'D5F9BB45-F20F-E911-80BF-E61F13C57837',
--                        '9642BA57-F20F-E911-80BF-E61F13C57837', '7264B169-F20F-E911-80BF-E61F13C57837',
--                        'E4845487-A1BA-451D-98FD-65CC61C742B4', '83AA5BB8-0F82-EB11-B398-F40270D39969',
--                        '283293FC-60B1-4966-861E-B4EE9344B196', 'D5FAEEF5-7A51-4D0B-9659-619F6CDD643F',
--                        '68998E4A-3BEE-4AD6-9B5A-EDD423A752D1' );

/*
评估工作量：涉及基础数据/投管系统、销售系统、客服系统、成本系统、进度系统、采招系统、费用系统、租赁系统、留存物业
*/

SELECT  
        p.DevelopmentCompanyName,
        p.TopProjName ,
        p.ProjName ,
        p.AcquisitionDate,
        '是' AS 是否存在投管数据 ,
        '是' AS 是否存在基础数据 ,
        -- 成本系统
        CASE WHEN ( ISNULL(t1.costNum, 0) + ISNULL(t2.cbContractNum, 0) ) > 0
             THEN '是'
             ELSE '否'
        END AS '是否存在合同数据' ,
        ISNULL(t1.costNum, 0) AS '成本科目数量' ,
        ISNULL(t2.cbContractNum, 0) AS '成本合同数量' ,
        -- 费用系统
        CASE WHEN ( ISNULL(t3.fyContractNum, 0) ) > 0 THEN '是'
             ELSE '否'
        END AS '是否存在费用数据' ,
        ISNULL(t3.fyContractNum, 0) AS '费用合同数量' ,
        CASE WHEN ( ISNULL(t4.rmNum, 0) ) > 0 THEN '是'
             ELSE '否'
        END AS '是否存在销售数据' ,
        ISNULL(t4.rmNum, 0) AS '销售房间数量' ,
        -- 客服系统
        CASE WHEN ( ISNULL(t5.RecNum, 0) ) > 0 THEN '是'
             ELSE '否'
        END AS '是否存在客服数据' ,
        ISNULL(t5.RecNum, 0) AS '客服接待数量' ,
        -- 进度系统
        CASE WHEN ( ISNULL(t6.PlanNum, 0) ) > 0 THEN '是'
             ELSE '否'
        END AS '是否存在进度数据' ,
        ISNULL(t6.PlanNum, 0) AS '进度计划数量' ,
        -- 租赁系统
        CASE WHEN ( ISNULL(t7.zlRmNum, 0) ) > 0 THEN '是'
             ELSE '否'
        END AS '是否存在租赁数据' ,
        ISNULL(t7.zlRmNum, 0) AS '租赁房间数量' ,

        -- 材料系统
        case when isnull(t8.clApplyNum,0) > 0 then '是'
             else '否'
        end as '是否存在材料申请数据',
        isnull(t8.clApplyNum,0) as '材料申请数量',
        -- 留存物业系统
        CASE WHEN ( ISNULL(t9.lcRmNum, 0) ) > 0 THEN '是'
             ELSE '否'
        END AS '是否存在留存物业数据' ,
        ISNULL(t9.lcRmNum, 0) AS '留存物业房间数量' ,
        -- 采招系统
        CASE WHEN ( ISNULL(t11.cgplanNum, 0) + ISNULL(t10.cgNum, 0) ) > 0
             THEN '是'
             ELSE '否'
        END AS '是否存在招采数据' ,
        ISNULL(t10.cgNum, 0) AS '采招方案数量' ,
        ISNULL(t11.cgplanNum, 0) AS '采招计划数量'
INTO    #proj2
FROM    #proj p with(nolock) --基础数据全部要回退处理，投管系统 不用统计
        LEFT JOIN (
   --判断项目下是否有成本科目数据
                    SELECT  p.ProjGUID ,
                            COUNT(DISTINCT c.CostGUID) AS costNum
                    FROM    myCost_erp352.dbo.cb_Cost c with(nolock)
                            LEFT JOIN myCost_erp352.dbo.p_Project p with(nolock) ON c.ProjectCode = p.ProjCode
                                                              AND c.BUGUID = p.BUGUID
                    GROUP BY p.ProjGUID
                  ) t1 ON t1.ProjGUID = p.ProjGUID
        LEFT JOIN (
   --判断项目下是否有成本合同数据
                    SELECT  cp.ProjGUID ,
                            COUNT(DISTINCT c.ContractGUID) AS cbContractNum
                    FROM    myCost_erp352.dbo.cb_Contract c with(nolock)
                            LEFT JOIN myCost_erp352.dbo.cb_ContractProj cp with(nolock) ON cp.ContractGUID = c.ContractGUID
                    WHERE   ISNULL(c.IsFyControl, 0) = 0
                    GROUP BY cp.ProjGUID
                  ) t2 ON t2.ProjGUID = p.ProjGUID
    --判断是否存在费用合同数据
        LEFT JOIN ( SELECT  cp.ProjGUID ,
                            COUNT(DISTINCT c.ContractGUID) AS fyContractNum
                    FROM    myCost_erp352.dbo.cb_Contract c with(nolock)
                            LEFT JOIN myCost_erp352.dbo.cb_ContractProj cp with(nolock) ON cp.ContractGUID = c.ContractGUID
                    WHERE   ISNULL(c.IsFyControl, 0) = 1
                    GROUP BY cp.ProjGUID
                  ) t3 ON t3.ProjGUID = p.ProjGUID
     ---判断销售系统
        LEFT JOIN ( SELECT  ProjGUID ,
                            COUNT(DISTINCT RoomGUID) AS rmNum
                    FROM    erp25.dbo.p_room with(nolock)
                    WHERE   IsVirtualRoom = 0
                    GROUP BY ProjGUID
                  ) t4 ON t4.ProjGUID = p.ProjGUID
      --判断客服系统
        LEFT JOIN ( SELECT  k.ProjGUID ,
                            COUNT(DISTINCT k.ReceiveGUID) AS RecNum
                    FROM    erp25.dbo.k_Receive k with(nolock)
                    GROUP BY k.ProjGUID
                  ) t5 ON t5.ProjGUID = p.ProjGUID
      --判断进度系统
        LEFT JOIN ( SELECT  ProjGUID ,
                            COUNT(DISTINCT ID) AS PlanNum
                    FROM    myCost_erp352.dbo.jd_ProjectPlanExecute with(nolock)
                    GROUP BY ProjGUID
                  ) t6 ON t6.ProjGUID = p.ProjGUID
      --判断租赁系统
        LEFT JOIN ( SELECT  ProjGUID ,
                            COUNT(DISTINCT RoomGUID) AS zlRmNum
                    FROM    CRE_ERP_202_SYZL.dbo.p_Room with(nolock)
                    GROUP BY ProjGUID
                  ) t7 ON t7.ProjGUID = p.ProjGUID
         -- 判断材料系统
         left join (
             select  ProjGUID,
                  count(distinct ApplyGUID) as clApplyNum
              from  [172.16.4.131].dotnet_erp60.dbo.cl_Apply with(nolock)
             group by ProjGUID

         ) t8 on t8.ProjGUID = p.ProjGUID
        --LEFT JOIN ( SELECT  ProjGUID ,
        --                    COUNT(DISTINCT OrderGUID) AS zlRentNum
        --            FROM    CRE_ERP_202_SYZL.dbo.y_RentOrder with(nolock)
        --            GROUP BY ProjGUID
        --          ) t8 ON t8.ProjGUID = p.ProjGUID
        --判断留存物业系统
        LEFT JOIN ( SELECT  ProjGUID ,
                            COUNT(DISTINCT r.RoomGUID) AS lcRmNum
                    FROM    myCost_erp352.dbo.wy_Room r with(nolock)
                    GROUP BY r.ProjGUID
                  ) t9 ON t9.ProjGUID = p.ProjGUID
        --判断采招系统
        LEFT JOIN ( SELECT  v.Value AS ProjGUID ,
                            COUNT(DISTINCT CgSolutionGUID) AS cgNum
                    FROM    myCost_erp352.dbo.cg_CgSolution a with(nolock)
                            CROSS APPLY dbo.fn_Split2(a.ProjGUIDList, ';') v
                    GROUP BY v.Value
                  ) t10 ON CONVERT(VARCHAR(50), t10.ProjGUID) = CONVERT(VARCHAR(50), p.ProjGUID)
        LEFT JOIN ( SELECT  v.Value AS ProjGUID ,
                            COUNT(DISTINCT CgPlanGUID) AS cgplanNum
                    FROM    myCost_erp352.dbo.cg_CgPlan a with(nolock)
                            CROSS APPLY dbo.fn_Split2(a.ProjectGUIDList, ';') v
                    GROUP BY v.Value
                  ) t11 ON CONVERT(VARCHAR(50), t11.ProjGUID) = CONVERT(VARCHAR(50), p.ProjGUID)
ORDER BY p.TopProjCode ,
        p.ProjCode; 
        
        
      
SELECT  * ,
        0.1 AS '基础数据调整工作量',
        0.1 AS '投管系工作量',
        (
            CASE WHEN 是否存在合同数据 = '是' THEN 0.15 ELSE 0 END + 
            CASE WHEN 是否存在费用数据 = '是' THEN 0.1 ELSE 0 END + 
            CASE WHEN 是否存在销售数据 = '是' THEN 0.1 ELSE 0 END + 
            CASE WHEN 是否存在客服数据 = '是' THEN 0.05 ELSE 0 END + 
            CASE WHEN 是否存在进度数据 = '是' THEN 0.05 ELSE 0 END + 
            CASE WHEN 是否存在租赁数据 = '是' THEN 0.05 ELSE 0 END +
            CASE WHEN 是否存在材料申请数据 = '是' THEN 0.05 ELSE 0 END +
            CASE WHEN 是否存在留存物业数据 = '是' THEN 0.05 ELSE 0 END + 
            CASE WHEN 是否存在招采数据 = '是' THEN 0.1 ELSE 0 END
        ) + 0.1 + 0.1 AS '工作量小计',
        ISNULL(成本合同数量, 0) + 
        ISNULL(费用合同数量, 0) + 
        ISNULL(销售房间数量, 0) + 
        ISNULL(客服接待数量, 0) + 
        ISNULL(进度计划数量, 0) + 
        ISNULL(租赁房间数量, 0) + 
        ISNULL(留存物业房间数量, 0) + 
        ISNULL(采招方案数量, 0) + 
        ISNULL(采招计划数量, 0) + 
        ISNULL(材料申请数量, 0) AS '业务记录数量小计'
FROM    #proj2 with(nolock);

        
DROP TABLE #proj;
DROP TABLE #proj2
