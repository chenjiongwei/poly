-- =========================================
-- 将杓袁7号地（项目GUID: 0E63E1AD-4703-4A95-B661-9E8E415E041F）的销售机会，拆分到其他分期（二期、三期）
-- 并同步相关客户-机会关联数据，便于跟进销售线索
-- 二期 GUID: 75FF507F-46A0-4288-951B-4A02A48C7AD4
-- 三期 GUID: 7E9A29A0-2E74-4686-82D7-1F2E15262222
-- =========================================

-- 1. 备份原始表，便于数据可恢复
SELECT * INTO s_Opportunity_bak20251106 FROM s_Opportunity  where  projguid = '0E63E1AD-4703-4A95-B661-9E8E415E041F'          -- 销售机会表备份
SELECT * INTO s_Opp2Cst_bak20251106 FROM [s_Opp2Cst]                  -- 机会客户关系表备份

-- 2. 生成“二期”销售机会数据（来源为7号地，项目GUID替换成二期）
SELECT 
    NEWID() AS [OppGUID],                -- 为新销售机会生成全新GUID主键
    OppGUID as [OppGUID_bak],             -- 保留原销售机会GUID便于后续映射
    [BUGUID],
    '75FF507F-46A0-4288-951B-4A02A48C7AD4' AS [ProjGUID], -- 指定为二期项目
    [LeadGUID],
    [Topic],
    [OppSource],
    [Process],
    [EstRevenue],
    [Probability],
    [EstCloseDate],
    [Rating],
    [Status],
    [StatusReason],
    [CreatedOn],
    [CreatedBy],
    [ClosedOn],
    [Competitor],
    [CjTotal],
    [Description],
    [RoomGUID],
    [ModifyBy],
    [ModifyOn],
    [UserGUID],
    [Jzfx],
    [CognizeAve],
    [CreatedByGUID],
    [IsCreatorUse],
    [ywy],
    [DjDate],
    [TjrGUID],
    [scrm_timestamp_data],
    [YxFaFeeBig],
    [YxFaFeeSmall],
    [CstSource],
    [signguid],
    [OldOppGUID],
    [TempFlag],
    [CstSourceCode],
    [AgentfeeTypeCode],
    [FromSys]
INTO #s_Opportunity_2q
FROM s_Opportunity
WHERE [projguid] = '0E63E1AD-4703-4A95-B661-9E8E415E041F'            -- 仅处理7号地

-- 3. 生成“三期”销售机会数据（同理，项目GUID替换成三期）
SELECT 
    NEWID() AS [OppGUID],                -- 新销售机会生成全新GUID
    OppGUID as [OppGUID_bak],             -- 原机会GUID
    [BUGUID],
    '7E9A29A0-2E74-4686-82D7-1F2E15262222' AS [ProjGUID], -- 指定为三期项目
    [LeadGUID],
    [Topic],
    [OppSource],
    [Process],
    [EstRevenue],
    [Probability],
    [EstCloseDate],
    [Rating],
    [Status],
    [StatusReason],
    [CreatedOn],
    [CreatedBy],
    [ClosedOn],
    [Competitor],
    [CjTotal],
    [Description],
    [RoomGUID],
    [ModifyBy],
    [ModifyOn],
    [UserGUID],
    [Jzfx],
    [CognizeAve],
    [CreatedByGUID],
    [IsCreatorUse],
    [ywy],
    [DjDate],
    [TjrGUID],
    [scrm_timestamp_data],
    [YxFaFeeBig],
    [YxFaFeeSmall],
    [CstSource],
    [signguid],
    [OldOppGUID],
    [TempFlag],
    [CstSourceCode],
    [AgentfeeTypeCode],
    [FromSys]
INTO #s_Opportunity_3q
FROM s_Opportunity
WHERE [projguid] = '0E63E1AD-4703-4A95-B661-9E8E415E041F'            -- 仅处理7号地

-- 4. 生成“二期”销售机会客户关系表（将新旧机会关联）
SELECT 
      b.[OppGUID],                       -- 分期后的新机会GUID
      a.[CstGUID],                       -- 客户GUID
      a.[CstNum],                        -- 客户编号
      NEWID() AS [Opp2CstGUID],          -- 新中间表关系主键
      a.[signguid]
INTO #s_Opp2Cst_2q
FROM  [s_Opp2Cst] a
    INNER JOIN #s_Opportunity_2q b ON a.OppGUID = b.OppGUID_bak
WHERE EXISTS (
      SELECT 1 FROM s_Opportunity opp 
      WHERE opp.projguid = '0E63E1AD-4703-4A95-B661-9E8E415E041F' 
        AND opp.OppGUID = a.OppGUID
)

-- 5. 生成“三期”销售机会客户关系表
SELECT 
      b.[OppGUID],                       -- 三期新机会GUID
      a.[CstGUID],
      a.[CstNum],
      NEWID() AS [Opp2CstGUID],
      a.[signguid]
INTO #s_Opp2Cst_3q
FROM [s_Opp2Cst] a
    INNER JOIN #s_Opportunity_3q b ON a.OppGUID = b.OppGUID_bak
WHERE EXISTS (
      SELECT 1 FROM s_Opportunity opp 
      WHERE opp.projguid = '0E63E1AD-4703-4A95-B661-9E8E415E041F'
       AND opp.OppGUID = a.OppGUID
)

-- 6. 将二期新销售机会插入到主表
INSERT INTO s_Opportunity (
      [OppGUID],
      [BUGUID],
      [ProjGUID],
      [LeadGUID],
      [Topic],
      [OppSource],
      [Process],
      [EstRevenue],
      [Probability],
      [EstCloseDate],
      [Rating],
      [Status],
      [StatusReason],
      [CreatedOn],
      [CreatedBy],
      [ClosedOn],
      [Competitor],
      [CjTotal],
      [Description],
      [RoomGUID],
      [ModifyBy],
      [ModifyOn],
      [UserGUID],
      [Jzfx],
      [CognizeAve],
      [CreatedByGUID],
      [IsCreatorUse],
      [ywy],
      [DjDate],
      [TjrGUID],
    --  [scrm_timestamp_data],
      [YxFaFeeBig],
      [YxFaFeeSmall],
      [CstSource],
      [signguid],
      [OldOppGUID],
      [TempFlag],
      [CstSourceCode],
      [AgentfeeTypeCode],
      [FromSys]
)
SELECT 
      [OppGUID],
      [BUGUID],
      [ProjGUID],
      [LeadGUID],
      [Topic],
      [OppSource],
      [Process],
      [EstRevenue],
      [Probability],
      [EstCloseDate],
      [Rating],
      [Status],
      [StatusReason],
      [CreatedOn],
      [CreatedBy],
      [ClosedOn],
      [Competitor],
      [CjTotal],
      [Description],
      [RoomGUID],
      [ModifyBy],
      [ModifyOn],
      [UserGUID],
      [Jzfx],
      [CognizeAve],
      [CreatedByGUID],
      [IsCreatorUse],
      [ywy],
      [DjDate],
      [TjrGUID],
     -- [scrm_timestamp_data],
      [YxFaFeeBig],
      [YxFaFeeSmall],
      [CstSource],
      [signguid],
      [OldOppGUID],
      [TempFlag],
      [CstSourceCode],
      [AgentfeeTypeCode],
      [FromSys]
FROM #s_Opportunity_2q

-- 7. 将三期新销售机会插入到主表
INSERT INTO s_Opportunity (
      [OppGUID],
      [BUGUID],
      [ProjGUID],
      [LeadGUID],
      [Topic],
      [OppSource],
      [Process],
      [EstRevenue],
      [Probability],
      [EstCloseDate],
      [Rating],
      [Status],
      [StatusReason],
      [CreatedOn],
      [CreatedBy],
      [ClosedOn],
      [Competitor],
      [CjTotal],
      [Description],
      [RoomGUID],
      [ModifyBy],
      [ModifyOn],
      [UserGUID],
      [Jzfx],
      [CognizeAve],
      [CreatedByGUID],
      [IsCreatorUse],
      [ywy],
      [DjDate],
      [TjrGUID],
      -- [scrm_timestamp_data],
      [YxFaFeeBig],
      [YxFaFeeSmall],
      [CstSource],
      [signguid],
      [OldOppGUID],
      [TempFlag],
      [CstSourceCode],
      [AgentfeeTypeCode],
      [FromSys]
)
SELECT 
      [OppGUID],
      [BUGUID],
      [ProjGUID],
      [LeadGUID],
      [Topic],
      [OppSource],
      [Process],
      [EstRevenue],
      [Probability],
      [EstCloseDate],
      [Rating],
      [Status],
      [StatusReason],
      [CreatedOn],
      [CreatedBy],
      [ClosedOn],
      [Competitor],
      [CjTotal],
      [Description],
      [RoomGUID],
      [ModifyBy],
      [ModifyOn],
      [UserGUID],
      [Jzfx],
      [CognizeAve],
      [CreatedByGUID],
      [IsCreatorUse],
      [ywy],
      [DjDate],
      [TjrGUID],
     --  [scrm_timestamp_data],
      [YxFaFeeBig],
      [YxFaFeeSmall],
      [CstSource],
      [signguid],
      [OldOppGUID],
      [TempFlag],
      [CstSourceCode],
      [AgentfeeTypeCode],
      [FromSys]
FROM #s_Opportunity_3q

-- 8. 插入“二期”新机会的客户关系
INSERT INTO [s_Opp2Cst] (
      [OppGUID],
      [CstGUID],
      [CstNum],
      [Opp2CstGUID],
      [signguid]
)
SELECT 
      [OppGUID],
      [CstGUID],
      [CstNum],
      [Opp2CstGUID],
      [signguid]
FROM #s_Opp2Cst_2q

-- 9. 插入“三期”新机会的客户关系
INSERT INTO [s_Opp2Cst] (
      [OppGUID],
      [CstGUID],
      [CstNum],
      [Opp2CstGUID],
      [signguid]
)
SELECT 
      [OppGUID],
      [CstGUID],
      [CstNum],
      [Opp2CstGUID],
      [signguid]
FROM #s_Opp2Cst_3q
