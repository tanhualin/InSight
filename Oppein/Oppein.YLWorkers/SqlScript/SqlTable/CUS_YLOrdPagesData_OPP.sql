-- DROP TABLE [dbo].[CUS_YLOrdPagesData_OPP]

CREATE TABLE [dbo].[CUS_YLOrdPagesData_OPP]
(
	Idx INT IDENTITY(1,1)
	,PageName NVARCHAR(50)
	,PageSort INT NOT NULL
	,PageStoredProcedure NVARCHAR(100) NOT NULL	--获取数据存储过程名
	,PageStoredProcedure_CAD  NVARCHAR(100) NOT NULL	--获取数据存储过程名
	,showPageStates INT NOT NULL
	,PlateCategory NVARCHAR(50) NOT NULL 
	,CONSTRAINT PK_YLOrdPagesData_PageName PRIMARY KEY NONCLUSTERED(PageName)
	,CONSTRAINT FK_YLOrdPagesData_PlateCategory FOREIGN KEY(PlateCategory) REFERENCES dbo.CUS_YLOrdPlateCategory_OPP(PlateCategory)
	,CONSTRAINT IX_YLOrdPagesData_Idx UNIQUE CLUSTERED(Idx)
)
EXEC sys.sp_addextendedproperty @name=N'VSI_GridEditable', @value=N'遗留单修改器页签表' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'CUS_YLOrdPagesData_OPP'
GO


--SELECT * FROM dbo.sheet1$ ORDER BY PageSort  