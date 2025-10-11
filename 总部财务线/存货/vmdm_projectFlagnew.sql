USE [ERP25]
GO

/****** Object:  View [dbo].[vmdm_projectFlagnew]    Script Date: 2025/10/9 14:14:54 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

ALTER  VIEW [dbo].[vmdm_projectFlagnew]
AS
/*
每次取项目标签都很痛苦，所以写这个视图 直接取数
*/
WITH t
AS (
   SELECT a.projGUID,
          --a.LbProject,
          --a.LbProjectValue
          MAX(   CASE
                     WHEN LbProject = 'tgid' THEN
                          LbProjectValue
                     ELSE NULL
                 END
             ) tgid,
          MAX(   CASE
                     WHEN LbProject = 'sfzndxm' THEN
                          LbProjectValue
                     ELSE NULL
                 END
             ) sfzndxm,
          MAX(   CASE
                     WHEN LbProject = 'sfnrtj' THEN
                          LbProjectValue
                     ELSE NULL
                 END
             ) sfnrtj,
          MAX(   CASE
                     WHEN LbProject = 'cwsybl' THEN
                          LbProjectValue
                     ELSE NULL
                 END
             ) cwsybl,
          MAX(   CASE
                     WHEN LbProject = 'ylghsxfs' THEN
                          LbProjectValue
                     ELSE NULL
                 END
             ) ylghsxfs,
          MAX(   CASE
                     WHEN LbProject = 'sfqs' THEN
                          LbProjectValue
                     ELSE NULL
                 END
             ) sfqs,
          MAX(   CASE
                     WHEN LbProject = 'csnj' THEN
                          LbProjectValue
                     ELSE NULL
                 END
             ) csnj,
          MAX(   CASE
                     WHEN LbProject = 'bknj' THEN
                          LbProjectValue
                     ELSE NULL
                 END
             ) bknj,
          MAX(   CASE
                     WHEN LbProject = 'yxfxlx' THEN
                          LbProjectValue
                     ELSE NULL
                 END
             ) yxfxlx,
          MAX(   CASE
                     WHEN LbProject = 'bkfl' THEN
                          LbProjectValue
                     ELSE NULL
                 END
             ) bkfl,
          MAX(   CASE
                     WHEN LbProject = 'csfl' THEN
                          LbProjectValue
                     ELSE NULL
                 END
             ) csfl,
          MAX(   CASE
                     WHEN LbProject = 'xmwfl' THEN
                          LbProjectValue
                     ELSE NULL
                 END
             ) xmwfl,
          MAX(   CASE
                     WHEN LbProject = 'cslfh' THEN
                          LbProjectValue
                     ELSE NULL
                 END
             ) cslfh,
          MAX(   CASE
                     WHEN LbProject = 'sfnrdtlrfx' THEN
                          LbProjectValue
                     ELSE NULL
                 END
             ) sfnrdtlrfx -- 是否纳入动态利润分析
   FROM dbo.mdm_LbProject a
   GROUP BY a.projGUID)
   
SELECT p.ProjGUID,
       p.ImportSaleProjGUID,
       d.DevelopmentCompanyGUID,
       d.DevelopmentCompanyName 平台公司,
       p.SpreadName 推广名,
       p.ProjName 项目名,
       p.ProjCode 项目代码,
       b.tgid 投管代码,
       city.ParamValue 城市,
       city.ZTCategory 城市分类,
       p.XMHQFS 项目获取方式,
       p.AcquisitionDate 获取时间,
       CASE
           WHEN YEAR(p.AcquisitionDate) > 2022 THEN
                '新增量'
           WHEN YEAR(p.AcquisitionDate) = 2022 THEN
                '增量'
           ELSE '存量'
       END 存量增量,
       p.TradersWay 操盘方式,
       p.ManageModeName 管理方式,
       p.YXCpf 营销操盘方,
       p.GCCpf 工程操盘方,
       p.CBCpf 成本操盘方,
       p.JSCpf 技术操盘方,
       p.KFCpf 开发操盘方,
       p.WYCpf 物业操盘方,
       p.GQRatio 项目股权比例,
       p.TZRatio 项目出资比例,
       p.EquityRatio 项目权益比率,
       p.BbWay 并表方式,
       p.ProjStatus 项目状态,
       p.ConstructStatus 工程状态,
       p.SaleStatus 销售状态,
       p.PartnerName 合作方名称,
       b.sfzndxm 是否重难点项目,
       b.sfnrtj 是否纳入统计,
       b.cwsybl 财务收益比例,
       b.ylghsxfs 盈利规划上线方式,
       b.sfqs 是否清算,
       b.csnj 城市能级,
       b.bknj 板块能级,
       b.csnj + b.bknj 能级,
       b.yxfxlx 营销分析类型,
       b.bkfl 板块分类,
       b.csfl 标签城市分类,
       b.xmwfl 项目五分类,
       b.cslfh 城市六分化,
       b.sfnrdtlrfx 是否纳入动态利润分析,
       cc.ParamValue 项目组,
       c1.ParamValue 事业部,
       项目公司 = ISNULL(STUFF(
                     (
                         SELECT DISTINCT
                                ';' + bp.DevelopmentCompanyName
                         FROM dbo.mdm_Project ap
                              LEFT JOIN dbo.p_DevelopmentCompany bp ON bp.DevelopmentCompanyGUID = ap.ProjCompanyGUID
                         WHERE ap.ParentProjGUID = p.ProjGUID
                         FOR XML PATH('')
                     ),
                     1,
                     1,
                     ''
                          ),
                     e.DevelopmentCompanyName
                    ),
       CASE
           WHEN h.ProjGUID IS NOT NULL THEN
                '是'
           ELSE '否'
       END 是否录入合作业绩,
       p.bbf as 并表方
FROM mdm_Project p
     LEFT JOIN
     (
         SELECT ParamGUID,
                ParamCode,
                ParamValue,
                ZTCategory
         FROM myBizParamOption
         WHERE ParamName = 'td_City'
     ) city ON city.ParamGUID = p.CityGUID
     LEFT JOIN myBizParamOption mb ON p.XMSSCSGSGUID = mb.ParamGUID
     LEFT JOIN dbo.p_DevelopmentCompany d ON p.DevelopmentCompanyGUID = d.DevelopmentCompanyGUID
     LEFT JOIN dbo.p_DevelopmentCompany e ON e.DevelopmentCompanyGUID = p.ProjCompanyGUID
     LEFT JOIN t b ON p.ProjGUID = b.projGUID
     LEFT JOIN dbo.myBizParamOption cc ON cc.ParamGUID = p.XMSSCSGSGUID
     LEFT JOIN dbo.myBizParamOption c1 ON cc.ParamName = c1.ParamName
                                          AND cc.ParentCode = c1.ParamCode
                                          AND cc.ScopeGUID = c1.ScopeGUID
     LEFT JOIN
     (
         SELECT DISTINCT
                b.ProjGUID
         FROM s_YJRLProducteDetail a
              INNER JOIN s_YJRLProjSet b ON a.ProjSetGUID = b.ProjSetGUID
         WHERE a.Shenhe = '审核'
     ) h ON h.ProjGUID = p.ProjGUID
WHERE p.Level = 2;



GO


