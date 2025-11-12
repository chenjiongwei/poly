--==== 进度计划管理 与松宸沟通确认 客户针对新项目和分期自行维护计划（需要删除原杓袁7号地块下的楼栋计划）
DELETE pb
FROM p_BiddingBuilding pb      
inner JOIN p_BiddingSection pbb ON pb.BidGUID=pbb.BidGUID  
WHERE  EXISTS (SELECT 1 FROM #tmp_ProjectDZ dz WHERE dz.old_ProjGUID=pbb.ProjGUID);

DELETE p_BiddingSection 
WHERE  EXISTS (SELECT 1 FROM #tmp_ProjectDZ dz WHERE dz.old_ProjGUID=p_BiddingSection.ProjGUID);

DELETE dbo.jd_ProjectPlanCompile
WHERE  EXISTS (SELECT 1 FROM #tmp_ProjectDZ dz WHERE dz.old_ProjGUID=jd_ProjectPlanCompile.ProjGUID);