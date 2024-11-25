
--关联条件添加一级产品业态   add jiangst 20220719
SELECT   pj.ProjGUID ,
         pj.TopProductTypeName AS topproductname ,
         pj.productname AS productname ,
         pj.BusinessType,	
         pj.Standard,
         --拿地未开工	合作业绩的剩余货值及立项定位版的货值算在未开工部分								 
         SUM(CASE WHEN nc.ProjGUID IS NOT NULL THEN ISNULL(ld.总货值套数, 0) - ( ISNULL(已售套数, 0) + ISNULL(hzxm.hzts, 0))
                  ELSE ISNULL(拿地未开工套数, 0)
             END) AS 拿地未开工套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NOT NULL THEN ISNULL(ld.总货值面积, 0) - ( ISNULL(已售面积, 0) + ISNULL(hzxm.hzmj, 0))
                  ELSE ISNULL(拿地未开工货量面积, 0) + ISNULL(lxdw.zksmj, 0)
             END) AS 拿地未开工货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NOT NULL THEN ISNULL(ld.总货值金额, 0) - ( ISNULL(已售金额, 0) + ISNULL(hzxm.hzje, 0))
                  ELSE ISNULL(ld.拿地未开工货值金额, 0) + ISNULL(lxdw.zhz, 0)
             END) AS 拿地未开工货值金额 ,
         --已开工未达预售								,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(开工未达预售套数, 0)ELSE 0 END) AS 开工未达预售套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(开工未达预售货量面积, 0)ELSE 0 END) AS 开工未达预售货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(开工未达预售货值金额, 0)ELSE 0 END) AS 开工未达预售货值金额 ,
		 SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_开工未达预售套数, 0)ELSE 0 END) AS 未完工_开工未达预售套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_开工未达预售货量面积, 0)ELSE 0 END) AS 未完工_开工未达预售货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_开工未达预售货值金额, 0)ELSE 0 END) AS 未完工_开工未达预售货值金额 ,
		 SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_开工未达预售套数, 0)ELSE 0 END) AS 已完工_开工未达预售套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_开工未达预售货量面积, 0)ELSE 0 END) AS 已完工_开工未达预售货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_开工未达预售货值金额, 0)ELSE 0 END) AS 已完工_开工未达预售货值金额 ,
         --达预售未取证							
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_达预售条件未取证套数, 0)ELSE 0 END) AS 未完工_达预售条件未取证套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_达预售条件未取证货量面积, 0)ELSE 0 END) AS 未完工_达预售条件未取证货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_达预售条件未取证货值金额, 0)ELSE 0 END) AS 未完工_达预售条件未取证货值金额 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_达预售条件未取证套数, 0)ELSE 0 END) AS 已完工_达预售条件未取证套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_达预售条件未取证货量面积, 0)ELSE 0 END) AS 已完工_达预售条件未取证货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_达预售条件未取证货值金额, 0)ELSE 0 END) AS 已完工_达预售条件未取证货值金额 ,
         --达预售未取证已推
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_达预售条件未取证已推套数, 0)ELSE 0 END) AS 未完工_达预售条件未取证已推套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_达预售条件未取证已推货量面积, 0)ELSE 0 END) AS 未完工_达预售条件未取证已推货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_达预售条件未取证已推货值金额, 0)ELSE 0 END) AS 未完工_达预售条件未取证已推货值金额 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_达预售条件未取证已推套数, 0)ELSE 0 END) AS 已完工_达预售条件未取证已推套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_达预售条件未取证已推货量面积, 0)ELSE 0 END) AS 已完工_达预售条件未取证已推货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_达预售条件未取证已推货值金额, 0)ELSE 0 END) AS 已完工_达预售条件未取证已推货值金额 ,

         --已取证未推	
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_获证未推套数, 0)ELSE 0 END) AS 未完工_获证未推套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_获证未推货量面积, 0)ELSE 0 END) AS 未完工_获证未推货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_获证未推货值金额, 0)ELSE 0 END) AS 未完工_获证未推货值金额 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_获证未推套数, 0)ELSE 0 END) AS 已完工_获证未推套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_获证未推货量面积, 0)ELSE 0 END) AS 已完工_获证未推货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_获证未推货值金额, 0)ELSE 0 END) AS 已完工_获证未推货值金额 ,
         --已推未售_是否完工			
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_已推未售套数, 0)ELSE 0 END) AS 未完工_已推未售套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_已推未售货量面积, 0)ELSE 0 END) AS 未完工_已推未售货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_已推未售货值金额, 0)ELSE 0 END) AS 未完工_已推未售货值金额 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_已推未售套数, 0)ELSE 0 END) AS 已完工_已推未售套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_已推未售货量面积, 0)ELSE 0 END) AS 已完工_已推未售货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_已推未售货值金额, 0)ELSE 0 END) AS 已完工_已推未售货值金额 ,

         --已推未售_是否取证		
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_已取证已推未售套数, 0)ELSE 0 END) AS 已完工_已取证已推未售套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_已取证已推未售货量面积, 0)ELSE 0 END) AS 已完工_已取证已推未售货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_已取证已推未售货值金额, 0)ELSE 0 END) AS 已完工_已取证已推未售货值金额 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_未取证已推未售套数, 0)ELSE 0 END) AS 已完工_未取证已推未售套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_未取证已推未售货量面积, 0)ELSE 0 END) AS 已完工_未取证已推未售货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(已完工_未取证已推未售货值金额, 0)ELSE 0 END) AS 已完工_未取证已推未售货值金额 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_已取证已推未售套数, 0)ELSE 0 END) AS 未完工_已取证已推未售套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_已取证已推未售货量面积, 0)ELSE 0 END) AS 未完工_已取证已推未售货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_已取证已推未售货值金额, 0)ELSE 0 END) AS 未完工_已取证已推未售货值金额 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_未取证已推未售套数, 0)ELSE 0 END) AS 未完工_未取证已推未售套数 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_未取证已推未售货量面积, 0)ELSE 0 END) AS 未完工_未取证已推未售货量面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未完工_未取证已推未售货值金额, 0)ELSE 0 END) AS 未完工_未取证已推未售货值金额 ,
         --剩余可售：达预售未取证+取证未推+已推未售
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN
                      ISNULL(未完工_达预售条件未取证货量面积, 0) + ISNULL(已完工_达预售条件未取证货量面积, 0) - ISNULL(未完工_达预售条件未取证已推货量面积, 0)
                      - ISNULL(已完工_达预售条件未取证已推货量面积, 0) + ISNULL(未完工_获证未推货量面积, 0) + ISNULL(已完工_获证未推货量面积, 0)
                      + ISNULL(未完工_已推未售货量面积, 0) + ISNULL(已完工_已推未售货量面积, 0)
                  ELSE 0
             END) AS 剩余可售货值面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN
                      ISNULL(未完工_达预售条件未取证货值金额, 0) + ISNULL(已完工_达预售条件未取证货值金额, 0) - ISNULL(未完工_达预售条件未取证已推货值金额, 0)
                      - ISNULL(已完工_达预售条件未取证已推货值金额, 0) + ISNULL(未完工_获证未推货值金额, 0) + ISNULL(已完工_获证未推货值金额, 0)
                      + ISNULL(未完工_已推未售货值金额, 0) + ISNULL(已完工_已推未售货值金额, 0)
                  ELSE 0
             END) AS 剩余可售货值金额 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN
                      ISNULL(未完工_达预售条件未取证套数, 0) + ISNULL(已完工_达预售条件未取证套数, 0) - ISNULL(未完工_达预售条件未取证已推套数, 0)
                      - ISNULL(已完工_达预售条件未取证已推套数, 0) + ISNULL(未完工_获证未推套数, 0) + ISNULL(已完工_获证未推套数, 0)
                      + ISNULL(未完工_已推未售套数, 0) + ISNULL(已完工_已推未售套数, 0)
                  ELSE 0
             END) AS 剩余可售套数 ,
		--未完工
		SUM(CASE WHEN nc.ProjGUID IS NULL THEN
                      ISNULL(未完工_达预售条件未取证货量面积, 0) - ISNULL(未完工_达预售条件未取证已推货量面积, 0)
                      + ISNULL(未完工_获证未推货量面积, 0)
                      + ISNULL(未完工_已推未售货量面积, 0)
                  ELSE 0
             END) AS 未完工_剩余可售货值面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN
                      ISNULL(未完工_达预售条件未取证货值金额, 0)  - ISNULL(未完工_达预售条件未取证已推货值金额, 0)
                      + ISNULL(未完工_获证未推货值金额, 0) 
                      + ISNULL(未完工_已推未售货值金额, 0) 
                  ELSE 0
             END) AS 未完工_剩余可售货值金额 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN
                      ISNULL(未完工_达预售条件未取证套数, 0)  - ISNULL(未完工_达预售条件未取证已推套数, 0)
                      + ISNULL(未完工_获证未推套数, 0) 
                      + ISNULL(未完工_已推未售套数, 0) 
                  ELSE 0
             END) AS 未完工_剩余可售套数 ,
		--已完工
		SUM(CASE WHEN nc.ProjGUID IS NULL THEN
                     ISNULL(已完工_达预售条件未取证货量面积, 0) 
                      - ISNULL(已完工_达预售条件未取证已推货量面积, 0) + ISNULL(已完工_获证未推货量面积, 0)
                      + ISNULL(已完工_已推未售货量面积, 0)
                  ELSE 0
             END) AS 已完工_剩余可售货值面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN
                       ISNULL(已完工_达预售条件未取证货值金额, 0) 
                      - ISNULL(已完工_达预售条件未取证已推货值金额, 0)  + ISNULL(已完工_获证未推货值金额, 0)
                      + ISNULL(已完工_已推未售货值金额, 0)
                  ELSE 0
             END) AS 已完工_剩余可售货值金额 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN
                      ISNULL(已完工_达预售条件未取证套数, 0) 
                      - ISNULL(已完工_达预售条件未取证已推套数, 0)  + ISNULL(已完工_获证未推套数, 0)
                      + ISNULL(已完工_已推未售套数, 0)
                  ELSE 0
             END) AS 已完工_剩余可售套数 ,


         --已售									
         SUM(ISNULL(已售面积, 0) + ISNULL(hzxm.hzmj, 0)) 已售面积 ,
         SUM(ISNULL(已售金额, 0) + ISNULL(hzxm.hzje, 0)) 已售金额 ,
         SUM(ISNULL(已售套数, 0) + ISNULL(hzxm.hzts, 0)) 已售套数 ,
         --未售						
         SUM(ISNULL(未售面积, 0) + ISNULL(lxdw.zksmj, 0) - ISNULL(hzxm.hzmj, 0)) AS 未售面积 ,
         SUM(ISNULL(未售货值, 0) + ISNULL(lxdw.zhz, 0) - ISNULL(hzxm.hzje, 0)) AS 未售货值 ,
         SUM(ISNULL(未售套数, 0) - ISNULL(hzxm.hzts, 0)) AS 未售套数 ,
         --未开工未售						
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未开工未售面积, 0) + ISNULL(lxdw.zksmj, 0) ELSE 0  END ) AS 未开工未售面积 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未开工未售货值, 0) + ISNULL(lxdw.zhz, 0) ELSE 0  END) AS 未开工未售货值 ,
         SUM(CASE WHEN nc.ProjGUID IS NULL THEN ISNULL(未开工未售套数, 0) ELSE 0  END) AS 未开工未售套数 ,
         --总货值									
         SUM(ISNULL(ld.总货值面积, 0) + ISNULL(lxdw.zksmj, 0)) AS 总货值面积 ,
         SUM(ISNULL(ld.总货值金额, 0) + ISNULL(lxdw.zhz, 0)) AS 总货值金额 ,
         SUM(ISNULL(ld.总货值套数, 0)) AS 总货值套数,

		 --提前销售
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN [未达预售条件未取证已推套数] ELSE 0  END) [未达预售条件未取证已推套数], 
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN [未达预售条件未取证已推货量面积] ELSE 0  END) [未达预售条件未取证已推货量面积], 
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN [未达预售条件未取证已推货值金额] ELSE 0  END) [未达预售条件未取证已推货值金额], 
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN [已完工_未达预售形象未取证已推货值] ELSE 0  END) [已完工_未达预售形象未取证已推货值], 
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN [已完工_未达预售形象未取证已推面积] ELSE 0  END) [已完工_未达预售形象未取证已推面积], 
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN [已完工_未达预售形象未取证已推套数] ELSE 0  END) [已完工_未达预售形象未取证已推套数], 
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN [未完工_未达预售形象未取证已推货值] ELSE 0  END) [未完工_未达预售形象未取证已推货值], 
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN [未完工_未达预售形象未取证已推面积] ELSE 0  END) [未完工_未达预售形象未取证已推面积], 
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN [未完工_未达预售形象未取证已推套数] ELSE 0  END) [未完工_未达预售形象未取证已推套数],

		 --产成品
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN isnull(产成品总货值面积,0) ELSE 0  END) 产成品总货值面积,
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN isnull(产成品总货值金额,0) ELSE 0  END) 产成品总货值金额,
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN isnull(产成品总货值套数,0) ELSE 0  END) 产成品总货值套数,
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN isnull(产成品已售面积 ,0 ) ELSE 0  END) 产成品已售面积 ,
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN isnull(产成品已售金额 ,0 ) ELSE 0  END) 产成品已售金额 ,
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN isnull(产成品已售套数 ,0 ) ELSE 0  END) 产成品已售套数 ,
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN isnull(产成品未售面积 ,0 ) ELSE 0  END) 产成品未售面积 ,
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN isnull(产成品未售货值 ,0 ) ELSE 0  END) 产成品未售货值 ,
		 sum(CASE WHEN nc.ProjGUID IS NULL THEN isnull(产成品未售套数 ,0) ELSE 0  END)  产成品未售套数 
FROM
         (   SELECT DISTINCT
                    ProjGUID ,
                    TopProductTypeName ,
                    ProductName,
                    BusinessType,	
                    Standard
             FROM
                    (   SELECT p.ProjGUID ,
                               pb.TopProductTypeName ,
                               pb.ProductTypeName ProductName,
                               BusinessType,	
                               Standard
                        FROM   dbo.data_wide_dws_mdm_Project p
                               INNER JOIN data_wide_dws_mdm_Product pb ON p.ProjGUID = pb.ProjectGuid
                        WHERE  Level = 2
                        UNION ALL
                        SELECT p.ParentGUID ,
                               pb.TopProductTypeName ,
                               pb.ProductTypeName ProductName,
                               BusinessType,	
                               Standard
                        FROM   dbo.data_wide_dws_mdm_Project p
                               INNER JOIN data_wide_dws_mdm_Product pb ON p.ProjGUID = pb.ProjectGuid
                        WHERE  Level = 3
                        UNION ALL
                        SELECT   ProjGUID ,
                                 ProductType ,
                                 ProductName,
                                 BusinessType,	
                                 Standard
                        FROM     dbo.data_wide_dws_s_p_lddbamj
                        WHERE    DATEDIFF(dd, QXDate, GETDATE()) = 0
                        GROUP BY ProjGUID ,
                                 ProductType ,
                                 ProductName,
								 BusinessType,	
                                 Standard
                        UNION ALL
                        SELECT   项目guid ,
                                 产品类型 ,
                                 产品名称,
                                 商品类型,
                                 装修标准
                        FROM     data_wide_dws_qt_LxDwTech_byyt
                        GROUP BY 项目guid ,
                                 产品类型 ,
                                 产品名称,
                                 商品类型,
                                 装修标准) t ) pj
         LEFT JOIN
         (   SELECT      ProjGUID ,topproductname,
                         productname ,
                         BusinessType,	
                         Standard,
                         SUM(拿地未开工套数) AS 拿地未开工套数 ,
                         SUM(拿地未开工货量面积) AS 拿地未开工货量面积 ,
                         SUM(拿地未开工货值金额) AS 拿地未开工货值金额 ,
                         SUM(开工未达预售套数) AS 开工未达预售套数 ,
                         SUM(开工未达预售货量面积) AS 开工未达预售货量面积 ,
                         SUM(开工未达预售货值金额) AS 开工未达预售货值金额 ,
						 --已完工
						 SUM(已完工_开工未达预售套数) AS 已完工_开工未达预售套数 ,
                         SUM(已完工_开工未达预售货量面积) AS 已完工_开工未达预售货量面积 ,
                         SUM(已完工_开工未达预售货值金额) AS 已完工_开工未达预售货值金额 ,
						 --未完工
						 SUM(未完工_开工未达预售套数) AS 未完工_开工未达预售套数 ,
                         SUM(未完工_开工未达预售货量面积) AS 未完工_开工未达预售货量面积 ,
                         SUM(未完工_开工未达预售货值金额) AS 未完工_开工未达预售货值金额 ,
                         SUM(未完工_达预售条件未取证套数) AS 未完工_达预售条件未取证套数 ,
                         SUM(未完工_达预售条件未取证货量面积) AS 未完工_达预售条件未取证货量面积 ,
                         SUM(未完工_达预售条件未取证货值金额) AS 未完工_达预售条件未取证货值金额 ,
                         SUM(已完工_达预售条件未取证套数) AS 已完工_达预售条件未取证套数 ,
                         SUM(已完工_达预售条件未取证货量面积) AS 已完工_达预售条件未取证货量面积 ,
                         SUM(已完工_达预售条件未取证货值金额) AS 已完工_达预售条件未取证货值金额 ,
                         SUM(未完工_获证未推套数) AS 未完工_获证未推套数 ,
                         SUM(未完工_获证未推货量面积) AS 未完工_获证未推货量面积 ,
                         SUM(未完工_获证未推货值金额) AS 未完工_获证未推货值金额 ,
                         SUM(已完工_获证未推套数) AS 已完工_获证未推套数 ,
                         SUM(已完工_获证未推货量面积) AS 已完工_获证未推货量面积 ,
                         SUM(已完工_获证未推货值金额) AS 已完工_获证未推货值金额 ,
                         SUM(未完工_已推未售套数) AS 未完工_已推未售套数 ,
                         SUM(未完工_已推未售货量面积) AS 未完工_已推未售货量面积 ,
                         SUM(未完工_已推未售货值金额) AS 未完工_已推未售货值金额 ,
                         SUM(已完工_已推未售套数) AS 已完工_已推未售套数 ,
                         SUM(已完工_已推未售货量面积) AS 已完工_已推未售货量面积 ,
                         SUM(已完工_已推未售货值金额) AS 已完工_已推未售货值金额 ,
                         SUM(已售面积) AS 已售面积 ,
                         SUM(已售金额) AS 已售金额 ,
                         SUM(已售套数) AS 已售套数 ,
                         SUM(未售面积) AS 未售面积 ,
                         SUM(未售货值) AS 未售货值 ,
                         SUM(未售套数) AS 未售套数 ,
                         SUM(未开工未售面积) AS 未开工未售面积 ,
                         SUM(未开工未售货值) AS 未开工未售货值 ,
                         SUM(未开工未售套数) AS 未开工未售套数 ,
                         SUM(总货值面积) AS 总货值面积 ,
                         SUM(总货值金额) 总货值金额 ,
                         SUM(总货值套数) AS 总货值套数 ,
                         SUM(已完工_已取证已推未售套数) AS 已完工_已取证已推未售套数 ,
                         SUM(已完工_已取证已推未售货量面积) AS 已完工_已取证已推未售货量面积 ,
                         SUM(已完工_已取证已推未售货值金额) AS 已完工_已取证已推未售货值金额 ,
                         SUM(已完工_未取证已推未售套数) AS 已完工_未取证已推未售套数 ,
                         SUM(已完工_未取证已推未售货量面积) AS 已完工_未取证已推未售货量面积 ,
                         SUM(已完工_未取证已推未售货值金额) AS 已完工_未取证已推未售货值金额 ,
                         SUM(未完工_已取证已推未售套数) AS 未完工_已取证已推未售套数 ,
                         SUM(未完工_已取证已推未售货量面积) AS 未完工_已取证已推未售货量面积 ,
                         SUM(未完工_已取证已推未售货值金额) AS 未完工_已取证已推未售货值金额 ,
                         SUM(未完工_未取证已推未售套数) AS 未完工_未取证已推未售套数 ,
                         SUM(未完工_未取证已推未售货量面积) AS 未完工_未取证已推未售货量面积 ,
                         SUM(未完工_未取证已推未售货值金额) AS 未完工_未取证已推未售货值金额 ,
                         SUM(未完工_达预售条件未取证已推套数) AS 未完工_达预售条件未取证已推套数 ,
                         SUM(未完工_达预售条件未取证已推货量面积) AS 未完工_达预售条件未取证已推货量面积 ,
                         SUM(未完工_达预售条件未取证已推货值金额) AS 未完工_达预售条件未取证已推货值金额 ,
                         SUM(已完工_达预售条件未取证已推套数) AS 已完工_达预售条件未取证已推套数 ,
                         SUM(已完工_达预售条件未取证已推货量面积) AS 已完工_达预售条件未取证已推货量面积 ,
                         SUM(已完工_达预售条件未取证已推货值金额) AS 已完工_达预售条件未取证已推货值金额,
						 --提前销售
						 sum([未达预售条件未取证已推套数]) [未达预售条件未取证已推套数], 
						 sum([未达预售条件未取证已推货量面积]) [未达预售条件未取证已推货量面积], 
						 sum([未达预售条件未取证已推货值金额]) [未达预售条件未取证已推货值金额], 
						 sum([已完工_未达预售形象未取证已推货值]) [已完工_未达预售形象未取证已推货值], 
						 sum([已完工_未达预售形象未取证已推面积]) [已完工_未达预售形象未取证已推面积], 
						 sum([已完工_未达预售形象未取证已推套数]) [已完工_未达预售形象未取证已推套数], 
						 sum([未完工_未达预售形象未取证已推货值]) [未完工_未达预售形象未取证已推货值], 
						 sum([未完工_未达预售形象未取证已推面积]) [未完工_未达预售形象未取证已推面积], 
						 sum([未完工_未达预售形象未取证已推套数]) [未完工_未达预售形象未取证已推套数],
						 SUM(case when factfinishDate is not null then 总货值面积 else 0 end) AS 产成品总货值面积 ,
                         SUM(case when factfinishDate is not null then 总货值金额 else 0 end) as 产成品总货值金额 ,
                         SUM(case when factfinishDate is not null then 总货值套数 else 0 end) AS 产成品总货值套数 ,
						 SUM(case when factfinishDate is not null then 已售面积   else 0 end) AS 产成品已售面积 ,
                         SUM(case when factfinishDate is not null then 已售金额   else 0 end) AS 产成品已售金额 ,
                         SUM(case when factfinishDate is not null then 已售套数   else 0 end) AS 产成品已售套数 ,
                         SUM(case when factfinishDate is not null then 未售面积   else 0 end) AS 产成品未售面积 ,
                         SUM(case when factfinishDate is not null then 未售货值   else 0 end) AS 产成品未售货值 ,
                         SUM(case when factfinishDate is not null then 未售套数   else 0 end) AS 产成品未售套数 
             FROM        dbo.data_wide_dws_jh_LdHzOverview a
             where  not EXISTS (
                    /*
                    2024-11-22 剩余货值剔除掉两个项目的部分楼栋的剩余货值
                    一个是4910项目的中地块、南地块、北地块三个地块的所有面积和货值
                    另外一个是4918项目的“南地块住宅5号楼、7号楼、8号楼”
                    */
                    SELECT BuildingGUID 
                    FROM data_wide_dws_jh_LdHzOverview a1
                    WHERE ProjGUID = 'BCF91594-0604-E911-80BF-E61F13C57837' 
                    AND (gcbldname LIKE '中地块%' 
                        OR gcbldname LIKE '南地块%'
                        OR gcbldname LIKE '北地块%')
                    AND a1.BuildingGUID = a.BuildingGUID
                    UNION ALL
                    SELECT BuildingGUID 
                    FROM data_wide_dws_jh_LdHzOverview a1
                    WHERE ProjGUID = '1A7402F0-816E-EA11-80B8-0A94EF7517DD'
                    AND (gcbldname LIKE '%南地块住宅5号楼%'
                        OR gcbldname LIKE '%南地块住宅7号楼%'
                        OR gcbldname LIKE '%南地块住宅8号楼%')
                    AND a1.BuildingGUID = a.BuildingGUID
                )
             GROUP    BY ProjGUID ,productname,topproductname,BusinessType,	
                                 Standard 
                                 
         ) ld ON pj.ProjGUID = ld.ProjGUID
                AND pj.productname = ld.productname
                and pj.TopProductTypeName=ld.topproductname
                and ld.BusinessType=pj.BusinessType
                and ld.Standard=pj.Standard
         LEFT JOIN
         (   SELECT      nc.ParentProjGUID AS ProjectGuid ,TopProductTypeName,
                         ProductTypeName ,
                         RoomType,	
                         zxbz,
                         SUM(nc.CCjTotal) * 10000 AS hzje ,
                         SUM(nc.CCjArea) AS hzmj ,
                         SUM(nc.CCjCount) AS hzts
             FROM        dbo.data_wide_s_NoControl nc
                         LEFT JOIN
                         (   SELECT    pj.ParentGUID AS ProjectGuid ,
                                       pb.ProductTypeGuid ,
                                       pb.ProductTypeName ,
                                       pb.TopProductTypeName
                             FROM      dbo.data_wide_s_Product pb
                                       INNER JOIN dbo.data_wide_dws_mdm_Project pj ON pb.ProjectGuid = pj.ProjGUID
                             GROUP  BY pj.ParentGUID ,
                                       pb.ProductTypeName ,
                                       pb.TopProductTypeName ,
                                       pb.ProductTypeGuid ) pb ON pb.ProductTypeGuid = nc.ProductTypeGUID
                                                                  AND nc.ProjGUID = pb.ProjectGuid
						  --只取业态级录入的特殊业绩 chenjw20220314 修改
					      WHERE nc.IfBuildingYJRL =0 
             GROUP    BY nc.ParentProjGUID ,
                         ProductTypeName,TopProductTypeName,RoomType,	
                         zxbz ) hzxm ON pj.ProjGUID = hzxm.ProjectGuid
                                                   AND pj.productname = hzxm.ProductTypeName
												   and hzxm.TopProductTypeName=pj.TopProductTypeName
                                                   and hzxm.RoomType=pj.BusinessType
                                                   and hzxm.zxbz=pj.Standard
         LEFT JOIN
         --优先取定位，定位没有再取立项数
        (
            select 项目guid,产品类型,产品名称,商品类型,装修标准,
            sum(case when 是否可售 = '是' and 是否自持='否' then case when 定位销售收入含税 = 0 then 立项现金流入含税 else 定位销售收入含税 end
                 else 0 end) as zhz,
            sum(case when 是否可售 = '是' and 是否自持='否' then case when 定位可售面积 = 0 then 立项可售面积 else 定位可售面积 end
                 else 0 end) as zksmj
            from data_wide_dws_qt_LxDwProfit_yt lxdw
            LEFT JOIN (select distinct ParentProjGUID from data_wide_dws_mdm_Building) pb ON pb.ParentProjGUID = lxdw.项目guid
            where  pb.ParentProjGUID IS NULL
            group by 项目guid,产品类型,产品名称,商品类型,装修标准)lxdw on  pj.ProjGUID = lxdw.项目guid
                                                   AND pj.productname = lxdw.产品名称
												   and lxdw.产品类型=pj.TopProductTypeName
                                                   and lxdw.商品类型=pj.BusinessType
                                                   and lxdw.装修标准=pj.Standard
        --  (   SELECT      lxdw.ProjGUID ,lxdw.YtName,
        --                  lxdw.productname ,
        --                  SUM(CASE WHEN lxdw.EditonType = '定位版'
        --                                AND lxdw.zhz <> 0 THEN lxdw.zhz
        --                           WHEN lxdw.EditonType = '立项版'
        --                                AND lxdw.zhz <> 0 THEN lxdw.zhz
        --                           ELSE 0
        --                      END) AS zhz ,
        --                  SUM(CASE WHEN lxdw.EditonType = '定位版'
        --                                AND lxdw.zksmj <> 0 THEN lxdw.zksmj
        --                           WHEN lxdw.EditonType = '立项版'
        --                                AND lxdw.zksmj <> 0 THEN lxdw.zksmj
        --                           ELSE 0
        --                      END) AS zksmj
        --      FROM        data_wide_dws_ys_SumOperatingProfitDataLXDWByYt lxdw
        --                  LEFT JOIN data_wide_dws_mdm_Building pb ON pb.ParentProjGUID = lxdw.ProjGUID
        --      WHERE       IsBase = 1
        --                  AND pb.ParentProjGUID IS NULL
        --      GROUP    BY lxdw.ProjGUID ,
        --                  lxdw.productname,lxdw.YtName ) lxdw ON lxdw.ProjGUID = pj.ProjGUID
                                                    -- AND lxdw.productname = pj.productname
													-- and lxdw.YtName=pj.TopProductTypeName
         LEFT JOIN ( SELECT ProjGUID FROM dbo.data_wide_s_NoControl where IfBuildingYJRL = 0  GROUP BY ProjGUID ) nc ON pj.ProjGUID = nc.ProjGUID		
GROUP BY pj.ProjGUID ,
         pj.TopProductTypeName ,
         pj.productname,
         pj.BusinessType,	
         pj.Standard
