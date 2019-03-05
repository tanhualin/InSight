
-- DROP TABLE [dbo].[CUS_YLOrdPlateCategory_OPP]

CREATE TABLE [dbo].[CUS_YLOrdPlateCategory_OPP]
(
	Idx INT IDENTITY(1,1)
	,PlateCategory NVARCHAR(50) NOT NULL
	,lblWidth TINYINT NOT NULL DEFAULT 60
	,lblBold BIT NOT NULL DEFAULT 1
	,tBoxWidth TINYINT NOT NULL DEFAULT 80
	,SortOrder TINYINT NOT NULL DEFAULT 0
	,CONSTRAINT PK_YLOrdPlateCategory_PlateCategory PRIMARY KEY NONCLUSTERED(PlateCategory)
	,CONSTRAINT IX_YLOrdPlateCategory_Idx UNIQUE CLUSTERED(Idx)	--聚集索引
)
EXEC sys.sp_addextendedproperty @name=N'VSI_GridEditable', @value=N'遗留单修改器板件类别表' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'CUS_YLOrdPlateCategory_OPP'
GO
INSERT INTO [dbo].[CUS_YLOrdPlateCategory_OPP](PlateCategory,SortOrder)
SELECT N'柜身',1
UNION ALL
SELECT N'柜配',2
UNION ALL
SELECT N'铝框门',3
UNION ALL
SELECT N'吸塑',4
UNION ALL
SELECT N'包覆',5
UNION ALL
SELECT N'实木',6
UNION ALL
SELECT N'烤漆',7
UNION ALL
SELECT N'台面',8

-- DROP TABLE [dbo].[CUS_YLOrdPagesTotalData_OPP]

CREATE TABLE [dbo].[CUS_YLOrdPagesTotalData_OPP]
(
	Idx INT IDENTITY(1,1)
	,OrdID INT NOT NULL
	,PageName NVARCHAR(50) NOT NULL
	,PlateCategory NVARCHAR(50) NOT NULL
	,TotalPrice DECIMAL(18,2) NOT NULL DEFAULT 0
	,CONSTRAINT PK_YLOrdPagesTotalData_OrdID_PageName_PlateCategory PRIMARY KEY(OrdID,PageName,PlateCategory)
	,CONSTRAINT IX_YLOrdPagesTotalData_Idx UNIQUE CLUSTERED(Idx)	--聚集索引
	,INDEX IX_YLOrdPagesTotalData_OrdID(OrdID)	--非聚集，不唯一索引
	,INDEX IX_YLOrdPagesTotalData_OrdID_PageName(OrdID,PageName)	--非聚集，不唯一索引
)

CREATE TABLE [dbo].[CUS_YLOrdPagesTotalDataLog_OPP]
(
	Idx INT IDENTITY(1,1)
	,OrdID INT NOT NULL
	,PageName NVARCHAR(50) NOT NULL
	,PlateCategory NVARCHAR(50) NOT NULL
	,TotalPrice DECIMAL(18,2) NOT NULL DEFAULT 0
	,createdOn DATETIME NOT NULL
	,createdBy nvarchar(50) NOT NULL
	,CONSTRAINT PK_YLOrdPagesTotalDataLog_Idx PRIMARY KEY(Idx)
	,INDEX IX_YLOrdPagesTotalDataLog_OrdID(OrdID)	--非聚集，不唯一索引
	,INDEX IX_YLOrdPagesTotalDataLog_OrdID_PageName(OrdID,PageName)	--非聚集，不唯一索引
	,INDEX IX_YLOrdPagesTotalDataLog_OrdID_PageName_PlateCategory(OrdID,PageName,PlateCategory)	--非聚集，不唯一索引
)

