----------------数据准备----------------
--投管项目编码 ，改为销售项目编码
SELECT mp.ProjGUID, p.ProjCode,p.ParentCode, bu.BUCode+'.'+mp.ProjCode+'(s)' as NewProjCode
into #YJProj
FROM dbo.mdm_Project mp 
INNER JOIN dbo.p_Project p ON mp.ProjGUID=p.ProjGUID
INNER join myBusinessUnit bu on bu.BUGUID=p.BUGUID
left JOIN dbo.mdm_Project ppm ON cast (ppm.ProjGUID as varchar(50))=mp.PartnerGUID
WHERE p.ProjCode IN (
	'0048.002(s)','0048.006(s)','0048.KF001(s)'
)
ORDER BY mp.ProjCode

select * into  #Proj from (
	select ProjGUID,null as ParentProjGUID, ParentCode  as ParentCode ,ParentCode as newParentCode , ProjCode, NewProjCode from  #YJProj
	UNION all
	SELECT  p.projguid,mp.ParentProjGUID ,p.ParentCode, yj.NewProjCode as newParentCode ,p.ProjCode ,  yj.NewProjCode+'.'+p.ProjShortCode  as NewProjCode
	FROM dbo.p_Project p
	inner join mdm_Project mp on p.ProjGUID=mp.ProjGUID
	inner join #YJProj yj on yj.ProjGUID=mp.ParentProjGUID
	WHERE p.ParentCode IN (
	'0048.002(s)','0048.006(s)','0048.KF001(s)'
	) 
) aa


select  * INTO p_Project_bak20250425dz  from #Proj  order by NewProjCode

SELECT * FROM  #Proj


-------------------------------修复----------------------------
--更新项目表编码
PRINT '项目表'
SELECT a.ParentCode,b.NewParentCode,a.ProjCode,b.NewProjCode FROM  dbo.p_Project a
INNER JOIN #Proj b ON b.ProjGUID = a.ProjGUID

--备份
SELECT a.* INTO p_Project_bak20250425  FROM    dbo.p_Project a
INNER JOIN #Proj b ON b.ProjGUID = a.ProjGUID

UPDATE a SET a.ProjCode=b.NewProjCode,a.ParentCode=b.NewParentCode
FROM  dbo.p_Project a
INNER JOIN #Proj b ON b.ProjGUID = a.ProjGUID


update p set p.projshortcode =replace(p.projcode,p.parentcode+'.','' )
from  p_Project p
inner join p_Project_bak20250425dz dz on p.projguid =dz.projguid
where  dz.parentprojguid is null

update  p
 set p.UserProjShortCode =p.projshortcode
--select p.UserProjShortCode,p.projshortcode, p.projname, dz.*
from  p_Project p
inner join p_Project_bak20250425dz dz on p.projguid =dz.projguid
where  dz.parentprojguid is null

PRINT '项目表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


--更新楼栋表
PRINT '楼栋表';
SELECT  b.ProjGUID,a.ProjCode, b.ParentCode ,a.NewProjCode, REPLACE( b.ParentCode, a.ProjCode,a.NewProjCode)
FROM    #Proj a
INNER JOIN dbo.p_Building b ON a.ProjGUID = b.ProjGUID

--备份
SELECT b.* into p_Building_bak20250425
FROM    #Proj a
INNER JOIN dbo.p_Building b ON a.ProjGUID = b.ProjGUID

UPDATE  b
SET   b.ParentCode = REPLACE( b.ParentCode, a.ProjCode,a.NewProjCode)
FROM    #Proj a
INNER JOIN dbo.p_Building b ON a.ProjGUID = b.ProjGUID

PRINT '楼栋表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);


--更新房间表
PRINT '房间表';
select   b.RoomCode , REPLACE(b.RoomCode, REPLACE(a.ProjCode,'.','-'),REPLACE(a.NewProjCode,'.','-') )
FROM    #Proj a
INNER JOIN dbo.p_room b ON a.ProjGUID = b.ProjGUID
WHERE   1 = 1 

--备份
SELECT b.* INTO   p_room_bak20250425
FROM    #Proj a
INNER JOIN dbo.p_room b ON a.ProjGUID = b.ProjGUID
WHERE   1 = 1 

UPDATE b SET  b.RoomCode = REPLACE(b.RoomCode, REPLACE(a.ProjCode,'.','-'),REPLACE(a.NewProjCode,'.','-') )
FROM    #Proj a
INNER JOIN dbo.p_room b ON a.ProjGUID = b.ProjGUID
WHERE   1 = 1 

PRINT '房间表' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

--项目团队
--25
PRINT '项目团队';

SELECT d.ProjCode, a.HierarchyCode,'zb.'+ d.NewProjCode
FROM  myBusinessUnit a
INNER  JOIN  #Proj d ON d.ProjGUID = a.ProjGUID

--备份
SELECT a.*  INTO myBusinessUnit_bak20250525
FROM  myBusinessUnit a
INNER  JOIN  #Proj d ON d.ProjGUID = a.ProjGUID

--修复
UPDATE  a SET  a.HierarchyCode='zb.'+ d.NewProjCode
FROM  myBusinessUnit a
INNER  JOIN  #Proj d ON d.ProjGUID = a.ProjGUID




PRINT '项目团队' + CONVERT(NVARCHAR(20), @@ROWCOUNT);

PRINT '完成'


