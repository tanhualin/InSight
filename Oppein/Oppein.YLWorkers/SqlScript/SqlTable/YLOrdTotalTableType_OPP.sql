/*
	遗留单汇总类型
*/

CREATE TYPE [dbo].[YLOrdTotalTableType_OPP] AS TABLE(
	[PageName] NVARCHAR(50) NOT NULL,
	[PlateCategory] NVARCHAR(50) NOT NULL,
	[TotalPrice] DECIMAL(18,2) NOT NULL,
	PRIMARY KEY([PageName],[PlateCategory])
)