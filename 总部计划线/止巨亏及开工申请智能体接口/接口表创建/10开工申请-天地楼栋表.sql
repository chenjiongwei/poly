

CREATE TABLE s_集团开工申请天地楼层智能体数据提取 (
    projguid UNIQUEIDENTIFIER,
    平台公司 VARCHAR(200),
    项目名称 VARCHAR(200),
    推广名称 VARCHAR(200),

    -- 已推未售
    已推住宅套数合计             DECIMAL(38, 10),
    已推住宅套数_其中非天地       DECIMAL(38, 10),
    已推住宅套数_其中天地         DECIMAL(38, 10),

    -- 已售
    已售住宅套数合计             DECIMAL(38, 10),
    已售住宅套数_其中非天地       DECIMAL(38, 10),
    已售住宅套数_其中天地         DECIMAL(38, 10),

    -- 去化率
    去化率合计                   DECIMAL(38, 10),
    非天地楼层去化率             DECIMAL(38, 10),
    天地楼层去化率               DECIMAL(38, 10),
    楼层去化极差                 DECIMAL(38, 10),

    -- 已售统计范围内
    已售住宅套数_统计范围内_合计         DECIMAL(38, 10),
    已售住宅套数_统计范围内_其中非天地   DECIMAL(38, 10),
    已售住宅套数_统计范围内_其中天地     DECIMAL(38, 10),

    -- 未售
    未售住宅情况_非天地套数       DECIMAL(38, 10),
    未售住宅情况_非天地面积       DECIMAL(38, 10),
    未售住宅情况_非天地金额       DECIMAL(38, 10),
    未售住宅情况_天地套数         DECIMAL(38, 10),
    未售住宅情况_天地面积         DECIMAL(38, 10),
    未售住宅情况_天地金额         DECIMAL(38, 10),

    是否楼层齐步走考核项目       VARCHAR(200),
    清洗日期                     DATETIME
);