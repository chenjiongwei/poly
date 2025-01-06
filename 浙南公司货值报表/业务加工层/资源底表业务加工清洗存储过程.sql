USE [ERP25]
GO
/****** Object:  StoredProcedure [dbo].[usp_ydkb_Clean_Date]    Script Date: 2025/1/6 11:04:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
---经营日报清洗作业

--每日清洗数据
--00清洗组织架构表
--01移动-总经理-经营业绩
--02移动-总经理-动态货值
--03移动-总经理-收回股东投资时间
--04移动-总经理-现金流回正
--05移动-总经理-利润
--06移动-总经理-产成品
--07移动-总经理-竣工交楼任务完成情况
--08移动-财务线看板-融资
--09移动-财务线看板-收入结转
--exec usp_ydkb_Clean_Date
ALTER PROC [dbo].[usp_ydkb_Clean_Date]
/* 经营日报清洗作业
chenjw 20190409
*/
AS
    BEGIN

	 declare @date datetime = getdate();
--每日清洗数据
--00清洗组织架构表
        EXEC usp_ydkb_BaseInfo; 
--0001清洗华南公司组织架构表
        EXEC usp_ydkb_BaseInfo_hn;
--01移动-总经理-经营业绩
        EXEC usp_ydkb_jyyj; 
--0101移动-总经理-经营业绩-华南公司
        EXEC usp_ydkb_jyyj_hn; 
--02移动-总经理-动态货值
        EXEC usp_ydkb_dthz; 
--02PC-湾区公司-动态货值
        EXEC usp_ydkb_dthz_wq; 
--02PC-湾区公司-动态货值
        --EXEC usp_ydkb_dthz_wq_deal; 
		exec [usp_ydkb_dthz_wq_deal_cbinfo];
		exec [usp_ydkb_dthz_wq_deal_lxdwinfo];
		exec [usp_ydkb_dthz_wq_deal_returninfo];
		exec [usp_ydkb_dthz_wq_deal_salevalueinfo];
		exec [usp_ydkb_dthz_wq_deal_schedule];
		exec [usp_ydkb_dthz_wq_deal_tradeinfo];
		exec usp_s_M002业态级净利汇总表_数仓用 @date;
--0201移动-总经理-动态货值
        EXEC usp_ydkb_dthz_hn; 
--03移动-总经理-收回股东投资时间
        EXEC usp_ydkb_gdtz;
--0301移动-总经理-收回股东投资时间
        EXEC usp_ydkb_gdtz_hn;
--04移动-总经理-现金流回正
        EXEC usp_ydkb_xjlhz;
--04移动-总经理-现金流回正
        EXEC usp_ydkb_xjlhz_hn;
--05移动-总经理-利润成本科目超支项目明细表
        EXEC usp_ydkb_lr_PorjCxCost; 
--05移动-总经理-利润成本科目超支项目明细表
        EXEC usp_ydkb_lr_PorjCxCost_hn; 
--05移动-总经理-利润
        EXEC usp_ydkb_lr;
--0501移动-总经理-利润
        EXEC usp_ydkb_lr_hn;
--06移动-总经理-产成品
        EXEC usp_ydkb_ccb;
--06移动-总经理-产成品
        EXEC usp_ydkb_ccb_hn;
--07移动-总经理-竣工交楼任务完成情况
        EXEC usp_ydkb_jgjl;
--0701移动-总经理-竣工交楼任务完成情况
        EXEC usp_ydkb_jgjl_hn;
--08移动-财务线看板-融资
        EXEC usp_ydkb_rzrw;        
--09移动-财务线看板-收入结转
        EXEC usp_ydkb_xssrjz;
----10移动-延期节点情况
		exec myCost_erp352.dbo. [usp_ydkb_delay_deptwork_hn] ;

    END; 
