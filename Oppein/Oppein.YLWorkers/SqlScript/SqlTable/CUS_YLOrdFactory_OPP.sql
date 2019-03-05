CREATE TABLE [dbo].[CUS_YLOrdFactory_OPP]
(
	Idx INT IDENTITY(1,1)
	,Factory NVARCHAR(50)NOT NULL	--页签加工车间（订单加工车间值）
	,CONSTRAINT PK_YLOrdFactory_Factory PRIMARY KEY NONCLUSTERED(Factory)
)
EXEC sys.sp_addextendedproperty @name=N'VSI_GridEditable', @value=N'遗留单修改器加工车间列表' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'CUS_YLOrdFactory_OPP'
GO

--DROP TABLE [dbo].[CUS_YLOrdPageFactoryDefualt_OPP]

CREATE TABLE [dbo].[CUS_YLOrdPageFactoryDefualt_OPP]
(
	Idx INT IDENTITY(1,1)
	,Factory NVARCHAR(50)	NOT NULL	--页签加工车间（订单加工车间值）
	,PageName NVARCHAR(50)	NOT NULL	--页签
	,FactoryDefualt NVARCHAR(50)	NOT NULL	--页签默认加工车间
	,CONSTRAINT PK_YLOrdPageFactoryDefualt_PageName PRIMARY KEY NONCLUSTERED(Factory,PageName)
	,CONSTRAINT FK_YLOrdPageFactoryDefualt_PageName FOREIGN KEY(PageName) REFERENCES dbo.CUS_YLOrdPagesData_OPP(PageName)
	,CONSTRAINT FK_YLOrdPageFactoryDefualt_FactoryDefualt FOREIGN KEY(FactoryDefualt) REFERENCES dbo.CUS_YLOrdFactory_OPP(Factory)
	,CONSTRAINT IX_YLOrdPageFactoryDefualt_Idx UNIQUE CLUSTERED(Idx)
)
EXEC sys.sp_addextendedproperty @name=N'VSI_GridEditable', @value=N'遗留单修改器页签默认加工车间对应表' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'CUS_YLOrdPageFactoryDefualt_OPP'
GO

CREATE TABLE [dbo].[CUS_YLOrdPageFactory_OPP]
(
	Idx INT IDENTITY(1,1)
	,PageName NVARCHAR(50)	NOT NULL	--页签
	,Factory NVARCHAR(50)	NOT NULL	--页签加工车间
	,OrderSort TINYINT DEFAULT 0 NOT NULL	--显示排序号
	,CONSTRAINT PK_YLOrdPageFactory_PageName PRIMARY KEY NONCLUSTERED(PageName,Factory)
	,CONSTRAINT FK_YLOrdPageFactory_PageName FOREIGN KEY(PageName) REFERENCES dbo.CUS_YLOrdPagesData_OPP(PageName)
	,CONSTRAINT FK_YLOrdPageFactory_Factory FOREIGN KEY(Factory) REFERENCES dbo.CUS_YLOrdFactory_OPP(Factory)
	,CONSTRAINT IX_YLOrdPageFactory_Idx UNIQUE CLUSTERED(Idx)
)
EXEC sys.sp_addextendedproperty @name=N'VSI_GridEditable', @value=N'遗留单修改器页签显示加工车间列表' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'CUS_YLOrdPageFactory_OPP'
GO
