SELECT   a.payformname AS '付款方式',
         buname AS '公司名称',
         p_project.projname AS '项目名称',
         roominfo AS '房间信息',
         bp.bproducttypename AS '产品类型',
         bd.bldname AS '楼栋名称',
         r.room AS '房间号',
         a.salestatus AS '销售状态',
         a.qsdate AS '签署日期',
         a.cstname AS '客户姓名',
         mdm_project.equityratio AS '项目权益比例',
         CASE 
           WHEN a.salestatus = '签约' THEN a.httype
           ELSE '定单'
         END AS '合同类型',
         Isnull(s_contract.contractno,o.potocolno) AS '交易编号',
         a.bldarea AS '建筑面积',
         a.jytotal AS '成交总价',
         (CASE 
            WHEN Isnull(my.itemtype,'') = '非贷款类房款'
                 AND a.salestatus = '签约'
                 AND a.status = '激活'
                 AND a.iszxkbrht = 0 THEN a.jytotal
            WHEN Isnull(my.itemtype,'') = '非贷款类房款'
                 AND a.salestatus = '签约'
                 AND a.status = '激活'
                 AND a.iszxkbrht = 1 THEN a.jytotal
            WHEN Isnull(my.itemtype,'') = '其它'
                 AND a.salestatus = '签约'
                 AND a.status = '激活'
                 AND a.iszxkbrht = 0 THEN a.jytotal
            WHEN Isnull(my.itemtype,'') = '其它'
                 AND a.salestatus = '签约'
                 AND a.status = '激活'
                 AND a.iszxkbrht = 1 THEN a.jytotal
            WHEN Isnull(my.itemtype,'') = ''
                 AND a.salestatus = '签约'
                 AND a.status = '激活' THEN a.jytotal
            ELSE 0
          END) AS '累计签约额',
         CASE 
           WHEN a.status = '激活' THEN a.zxtotal
           ELSE 0
         END AS '累计签约装修额',
         Isnull(CASE 
                  WHEN a.salestatus = '签约' THEN b.rmbamount
                  ELSE 0
                END,0) AS '签约累计回笼金额',
         Isnull(CASE 
                  WHEN a.salestatus = '签约' THEN b.rmbamount_1
                  ELSE 0
                END,0) AS '补差款累计回笼金额',
         Isnull(CASE 
                  WHEN a.salestatus = '认购' THEN b.rmbamount
                  ELSE 0
                END,0) AS '认购累计回笼金额',
         Isnull(CASE 
                  WHEN a.salestatus = '签约' THEN b.rmbamount_year
                  ELSE 0
                END,0) AS '签约本年回笼金额',
         Isnull(CASE 
                  WHEN a.salestatus = '签约' THEN b.year_1
                  ELSE 0
                END,0) AS '补差款本年回笼金额',
         Isnull(CASE 
                  WHEN a.salestatus = '认购' THEN b.rmbamount_year
                  ELSE 0
                END,0) AS '认购本年回笼金额',
         Isnull(CASE 
                  WHEN a.salestatus = '签约' THEN b.rmbamount_month
                  ELSE 0
                END,0) AS '签约本月回笼金额',
         Isnull(CASE 
                  WHEN a.salestatus = '签约' THEN b.month_1
                  ELSE 0
                END,0) AS '补差款本月回笼金额',
         Isnull(CASE 
                  WHEN a.salestatus = '认购' THEN b.rmbamount_month
                  ELSE 0
                END,0) AS '认购本月回笼金额',
         Isnull(CASE 
                  WHEN a.salestatus = '签约'
                       AND Datediff(mm,a.qsdate,:var_date) = 0 THEN b.rmbamount_month
                  ELSE 0
                END,0) AS '本月签约本月回笼',
         Isnull(CASE 
                  WHEN a.salestatus = '签约'
                       AND Datediff(mm,a.qsdate,:var_date) = 0 THEN b.rmbamount_month1
                  ELSE 0
                END,0) AS '本月签约本月非按揭回笼',
         Isnull(CASE 
                  WHEN a.salestatus = '签约'
                       AND Datediff(mm,a.qsdate,:var_date) = 0 THEN b.rmbamount_month2
                  ELSE 0
                END,0) AS '本月签约本月按揭回笼',
         Isnull(CASE 
                  WHEN a.salestatus = '签约' THEN c.rmbye_aj
                  ELSE 0
                END,0) AS '按揭待收款',
         Isnull(CASE 
                  WHEN a.salestatus = '签约' THEN c.rmbye_faj
                  ELSE 0
                END,0) AS '非按揭待收款',
         Isnull(CASE 
                  WHEN a.salestatus = '签约' THEN c.rmbye_aj
                  ELSE 0
                END,0) + Isnull(CASE 
                                  WHEN a.salestatus = '签约' THEN c.rmbye_faj
                                  ELSE 0
                                END,0) AS '正常待收款',
         Isnull(CASE 
                  WHEN a.salestatus = '签约' THEN rmbye1
                  ELSE 0
                END,0) AS '非按揭逾期待收款',
         Isnull(CASE 
                  WHEN a.salestatus = '签约' THEN rmbye2
                  ELSE 0
                END,0) AS '按揭逾期待收款',
         Isnull(CASE 
                  WHEN a.salestatus = '签约' THEN rmbye1 + rmbye2
                  ELSE 0
                END,0) AS '逾期合计',
         Isnull(CASE   WHEN a.salestatus = '签约' THEN rmbye_aj ELSE 0  END,0) 
         + Isnull(CASE WHEN a.salestatus = '签约' THEN rmbye_faj ELSE 0 END,0) 
         + Isnull(CASE WHEN a.salestatus = '签约' THEN rmbye1  ELSE 0 END,0) 
         + Isnull(CASE WHEN a.salestatus = '签约' THEN rmbye2 ELSE 0 END,0) AS '待收房款合计',
         Isnull(CASE 
                  WHEN a.salestatus = '签约' THEN e.rmbamount_bcye
                  ELSE 0
                END,0) AS '房款补差款',
         s_contract.ywy AS '代理公司',
         s_contract.zygw AS '置业顾问',
		   CASE
           WHEN s_contract.HtType = '临时合同' THEN
               '-'
           ELSE
               FORMAT(ISNULL(bbb.ModifyOn, s_contract.QSDate), 'yyyy-MM-dd')
       END '实际临转正日期',
      s_contract.yjlzzdate '预计临转正日期',
      sf.lastDate AS  '非贷款类房款最后付款日期',
      case when  isnull(ss.ssAmount,0) >= (isnull(a.jytotal,0) + isnull(e.rmbamount_bc,0)) then '是' else '否' end as '是否款清',
      case when  isnull(ss.ssAmount,0) >= (isnull(a.jytotal,0) + isnull(e.rmbamount_bc,0)) then ss_last.ssdate else null  end as '房款款清日期'
FROM     vs_trade a
         LEFT JOIN p_room r  ON a.roomguid = r.roomguid
         LEFT JOIN p_buildproducttype bp ON r.bproducttypecode = bp.bproducttypecode
         LEFT JOIN p_building bd ON a.bldguid = bd.bldguid
         LEFT JOIN mybusinessunit ON a.buguid = mybusinessunit.buguid
         LEFT JOIN p_project ON a.projguid = p_project.projguid
         LEFT JOIN p_project p1 ON p_project.parentcode = p1.projcode
         LEFT JOIN mdm_project  ON mdm_project.projguid = p1.projguid
         LEFT JOIN s_order o ON a.saleguid = o.orderguid AND o.status = '激活'
         LEFT JOIN s_contract  ON a.saleguid = s_contract.contractguid AND s_contract.status = '激活'
        LEFT JOIN
        (
            SELECT ROW_NUMBER() OVER (PARTITION BY SaleGUID ORDER BY ModifyOn DESC) num,
                  *
            FROM s_OCModifyLog
            WHERE ChangeFieldchn = '合同类型'
        ) bbb  ON s_contract.ContractGUID = bbb.SaleGUID    AND bbb.num = 1
         LEFT JOIN (SELECT   Max(selfcxflag) AS selfcxflag,
                             tradeguid
                    FROM     s_cwfx
                    WHERE    ysitemname = '房款补差款'
                    GROUP BY tradeguid) mm
           ON mm.tradeguid = a.tradeguid
         LEFT JOIN (SELECT   Max(itemtype) AS itemtype,
                             tradeguid
                    FROM     s_fee
                    WHERE    itemname IN ('装修款',
                                          '装修房款')
                    GROUP BY tradeguid) my
           ON my.tradeguid = a.tradeguid
         LEFT JOIN (SELECT   s_getin.saleguid,
                             Sum(CASE 
                                   WHEN itemname <> '房款补差款' THEN rmbamount
                                   ELSE 0
                                 END) AS rmbamount,
                             Sum(CASE 
                                   WHEN Year([GetDate]) = Year(:var_date)
                                        AND itemname <> '房款补差款'
                                        AND (v.ywtype <> '验证预收款'
                                              OR v.ywtype IS NULL ) THEN rmbamount
                                   WHEN Year([JfDate]) = Year(:var_date)
                                        AND itemname <> '房款补差款'
                                        AND v.ywtype = '验证预收款' THEN rmbamount
                                   ELSE 0
                                 END) AS rmbamount_year,
                             Sum(CASE 
                                   WHEN Datediff(mm,getdate,:var_date) = 0
                                        AND itemname <> '房款补差款'
                                        AND (v.ywtype <> '验证预收款'
                                              OR v.ywtype IS NULL ) THEN rmbamount
                                   WHEN Datediff(mm,jfdate,:var_date) = 0
                                        AND itemname <> '房款补差款'
                                        AND v.ywtype = '验证预收款' THEN rmbamount
                                   ELSE 0
                                 END) AS rmbamount_month,
                             Sum(CASE 
                                   WHEN itemtype = '非贷款类房款'
                                        AND Datediff(mm,getdate,:var_date) = 0
                                        AND itemname <> '房款补差款'
                                        AND (v.ywtype <> '验证预收款'
                                              OR v.ywtype IS NULL ) THEN rmbamount
                                   WHEN itemtype = '非贷款类房款'
                                        AND Datediff(mm,jfdate,:var_date) = 0
                                        AND itemname <> '房款补差款'
                                        AND v.ywtype = '验证预收款' THEN rmbamount
                                   ELSE 0
                                 END) AS rmbamount_month1,
                             Sum(CASE 
                                   WHEN itemtype = '贷款类房款'
                                        AND Datediff(mm,getdate,:var_date) = 0
                                        AND itemname <> '房款补差款'
                                        AND (v.ywtype <> '验证预收款'
                                              OR v.ywtype IS NULL ) THEN rmbamount
                                   WHEN itemtype = '非贷款类房款'
                                        AND Datediff(mm,jfdate,:var_date) = 0
                                        AND itemname <> '房款补差款'
                                        AND v.ywtype = '验证预收款' THEN rmbamount
                                   ELSE 0
                                 END) AS rmbamount_month2,
                             Sum(CASE 
                                   WHEN itemname LIKE '%补差款%' THEN rmbamount
                                   ELSE 0
                                 END) rmbamount_1,
                             Sum(CASE 
                                   WHEN itemname LIKE '%补差款%'
                                        AND Year([GetDate]) = Year(:var_date) THEN rmbamount
                                   ELSE 0
                                 END) AS year_1,
                             Sum(CASE 
                                   WHEN itemname LIKE '%补差款%'
                                        AND Datediff(mm,getdate,:var_date) = 0 THEN rmbamount
                                   ELSE 0
                                 END) AS month_1
                    FROM     s_getin
                             LEFT JOIN s_voucher v
                               ON s_getin.vouchguid = v.vouchguid
                    WHERE    (s_getin.itemtype LIKE '%房款%'
                               OR s_getin.itemname LIKE '%装修款%')
                             AND s_getin.status IS NULL 
                             AND getdate <= :var_date
                    GROUP BY s_getin.saleguid) b
           ON a.tradeguid = b.saleguid
         LEFT JOIN (SELECT   tradeguid,
                             Sum(rmbamount) ystotal,
                             Sum(CASE 
                                   WHEN itemtype = '非贷款类房款' THEN rmbamount
                                 END) ystotal_faj,
                             Sum(CASE 
                                   WHEN itemname LIKE '%补差款%' THEN rmbamount
                                   ELSE 0
                                 END) rmbamount_bc,
                             Sum(CASE 
                                   WHEN itemname LIKE '%补差款%' THEN s_fee.ye
                                   ELSE 0
                                 END) rmbamount_bcye
                    FROM     s_fee
                    WHERE    itemtype LIKE '%房款%'
                    GROUP BY tradeguid) e
           ON e.tradeguid = a.tradeguid
         LEFT JOIN (SELECT   s_cwfx.tradeguid,
                             Sum(CASE 
                                   WHEN ysitemname <> '房款补差款'
                                        AND selfcxflag = 0
                                        AND ysitemtype = '贷款类房款' THEN ysamount
                                   ELSE 0
                                 END) rmbye_aj,
                             Sum(CASE 
                                   WHEN ysitemname <> '房款补差款'
                                        AND selfcxflag = 0
                                        AND (ysitemtype = '非贷款类房款'
                                              OR ysitemname = '装修款') THEN ysamount
                                   ELSE 0
                                 END) rmbye_faj
                    FROM     s_cwfx
                             LEFT JOIN vs_trade d
                               ON s_cwfx.tradeguid = d.tradeguid
                    WHERE    d.status = '激活'
                             AND d.qsdate <= :var_date
                             AND d.projguid IN (:var_projGUID)
                             AND (ysitemtype IN ('贷款类房款',
                                                 '非贷款类房款')
                                   OR ysitemname = '装修款')
                             AND Isnull(ysdate,'2050-01-01') > :var_date
                             AND (ssdate > :var_date
                                   OR ssdate IS NULL )
                    GROUP BY s_cwfx.tradeguid) c  ON a.tradeguid = c.tradeguid
         left  join (
              select  s_cwfx.tradeguid, sum(isnull(GetAmount,0)) as ssAmount 
              from  s_cwfx
              LEFT JOIN vs_trade d ON s_cwfx.tradeguid = d.tradeguid
              WHERE    d.status = '激活'  
              AND d.projguid IN (:var_projGUID)
              AND (ysitemtype IN ('贷款类房款','非贷款类房款') OR ysitemname = '装修款')
              group by  s_cwfx.tradeguid 
         )  ss on ss.tradeguid = a.tradeguid
         outer apply (
            select  top 1 s_cwfx.tradeguid, s_cwfx.ssdate  
            from s_cwfx 
            LEFT JOIN vs_trade d ON s_cwfx.tradeguid = d.tradeguid
            WHERE  d.status = '激活'  
              AND d.projguid IN (:var_projGUID)
              AND (ysitemtype IN ('贷款类房款','非贷款类房款') OR ysitemname = '装修款')
              and  s_cwfx.tradeguid = a.tradeguid
            order by  ssdate desc
         ) ss_last
         LEFT JOIN (SELECT   s_cwfx.tradeguid,
                             Sum(CASE 
                                   WHEN ((ysitemtype = '非贷款类房款'
                                           OR ysitemname = '装修款')
                                         AND selfcxflag = 0
                                         AND ysdate <= :var_date
                                         AND ysitemname <> '房款补差款'
                                         AND (ssdate > :var_date
                                               OR ssdate IS NULL )) THEN ysamount
                                   ELSE 0
                                 END) rmbye1,
                             Sum(CASE 
                                   WHEN (ysitemtype = '贷款类房款'
                                         AND selfcxflag = 0
                                         AND ysdate <= :var_date
                                         AND (ssdate > :var_date
                                               OR ssdate IS NULL )) THEN ysamount
                                   ELSE 0
                                 END) rmbye2,
                             Sum(CASE 
                                   WHEN ysitemtype = '非贷款类房款'
                                        AND ysitemname <> '房款补差款'
                                        AND selfcxflag = 0 THEN ysamount
                                   ELSE 0
                                 END) ysamount,
                             Sum(CASE 
                                   WHEN (ssitemtype = '非贷款类房款'
                                          OR (ysitemtype IS NULL 
                                              AND ssitemtype IS NULL ))
                                        AND selfcxflag = 0 THEN getamount
                                   ELSE 0
                                 END) ssamount
                    FROM     s_cwfx
                             LEFT JOIN vs_trade d
                               ON s_cwfx.tradeguid = d.tradeguid
                    WHERE    d.status = '激活'
                             AND d.qsdate <= :var_date
                             AND d.projguid IN (:var_projGUID)
                    GROUP BY s_cwfx.tradeguid) d
           ON a.tradeguid = d.tradeguid
         LEFT JOIN s_salemodilog l
           ON a.saleguid = l.foresaleguid
              AND l.applytype IN ('退房',
                                  '挞定')
    LEFT JOIN
      (
          SELECT TradeGUID,
                 MAX(Sequence) AS Sequence
          FROM s_Fee
          WHERE ItemType IN ( '非贷款类房款' )
                AND (NOT ItemName LIKE '%补差%')
          GROUP BY TradeGUID) s
          ON s.TradeGUID = a.TradeGUID
      LEFT JOIN s_Fee AS sf  ON s.TradeGUID = sf.TradeGUID AND s.Sequence = sf.Sequence
WHERE    a.status = '激活'
         AND a.qsdate <= :var_date
         AND a.projguid IN (:var_projGUID)
ORDER BY buname,
         p_project.projname,
         roominfo;
