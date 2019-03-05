
/****** Object:  UserDefinedTableType [dbo].[mOrdTableType_OPP]    Script Date: 2018/9/7 16:21:07 ******/
CREATE TYPE [dbo].[YLOrdTableType_OPP] AS TABLE(
	[itmID] [INT] NULL,
	[itmIDInstance] [SMALLINT] NULL,
	[olnID] [INT] NULL,
	[olnIDInstance] [SMALLINT] NULL,
	[actions] [TINYINT] NULL,
	[oriReqQty] [DECIMAL](18, 2) NULL,
	[itmDescription] [NVARCHAR](100) NULL,
	[dimCX] [DECIMAL](18, 2) NULL,
	[dimCY] [DECIMAL](18, 2) NULL,
	[dimCZ] [DECIMAL](18, 2) NULL,
	[dimFX] [DECIMAL](18, 2) NULL,
	[dimFY] [DECIMAL](18, 2) NULL,
	[dimFZ] [DECIMAL](18, 2) NULL,
	[itmfCode] [NVARCHAR](50) NULL,
	[corCode] [NVARCHAR](50) NULL,
	[topSurCode] [NVARCHAR](50) NULL,
	[edgeCode] [NVARCHAR](6) NULL,
	[info1] [NVARCHAR](50) NULL,
	[info2] [NVARCHAR](50) NULL,
	[info3] [NVARCHAR](50) NULL,
	[info4] [NVARCHAR](50) NULL,
	[info5] [NVARCHAR](50) NULL,
	[info6] [NVARCHAR](255) NULL,
	[info7] [NVARCHAR](50) NULL,
	[info8] [NVARCHAR](50) NULL,
	[info9] [NVARCHAR](50) NULL,
	[info10] [NVARCHAR](50) NULL,
	[info11] [NVARCHAR](50) NULL,
	[info12] [NVARCHAR](50) NULL,
	[info13] [NVARCHAR](50) NULL,
	[info14] [NVARCHAR](50) NULL,
	[info15] [NVARCHAR](50) NULL,
	[Factory] [NVARCHAR](50) NULL,
	[Duty] [NVARCHAR](50) NULL,
	[PlateCategory] [NVARCHAR](50) NULL,
	[LegacyPrice] [DECIMAL](18,2) NULL
)
GO


